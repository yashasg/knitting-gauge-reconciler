require "json"
require "open3"
require "pathname"
require "rexml/document"
require "xcodeproj" unless defined?(Xcodeproj)

class ContractError < StandardError
end

MAX_COVERAGE_COUNT = 9_223_372_036_854_775_807
PRODUCTION_COVERAGE_TARGET = "KnittingGaugeReconciler.app"

def tracked_files(root, *paths)
  output, error, status = Open3.capture3("git", "-C", root, "ls-files", "-z", "--", *paths)
  raise ContractError, "git ls-files failed: #{error}" unless status.success?

  output.split("\0").reject(&:empty?)
end

def missing_memberships(files, members)
  files - members
end

def ui_recurrences(paths, contents)
  path_pattern = %r{(^|/)(XCUITests|[^/]*UITests)(/|$)}
  metadata_pattern = /com\.apple\.product-type\.bundle\.ui-testing|\bXCUITest|\b[A-Za-z0-9_]*UITests\b/
  paths.grep(path_pattern) + contents.each_with_object([]) do |(path, text), matches|
    matches << path if text.match?(metadata_pattern)
  end
end

def normalized_coverage_path(path, root)
  unless path.instance_of?(String) && !path.empty?
    raise ContractError, "coverage file path must be a nonempty string"
  end

  root_path = Pathname(File.expand_path(root)).cleanpath
  path = root_path.join(path) unless Pathname(path).absolute?
  relative = Pathname(path).cleanpath.relative_path_from(root_path).to_s
  if relative == ".." || relative.start_with?("../")
    raise ContractError, "coverage file path escapes repository: #{path}"
  end

  relative
rescue ArgumentError
  raise ContractError, "coverage file path cannot be normalized: #{path}"
end

def coverage_count(record, key, context)
  raise ContractError, "#{context} is missing #{key}" unless record.key?(key)

  value = record[key]
  unless value.instance_of?(Integer)
    raise ContractError, "#{context} #{key} must be an integer"
  end
  unless value.between?(0, MAX_COVERAGE_COUNT)
    raise ContractError, "#{context} #{key} is outside signed 64-bit range"
  end

  value
end

def checked_coverage_sum(values, label)
  values.reduce(0) do |sum, value|
    if value > MAX_COVERAGE_COUNT - sum
      raise ContractError, "#{label} sum exceeds signed 64-bit range"
    end

    sum + value
  end
end

def validate_coverage_report(report, root, expected_paths)
  unless report.instance_of?(Hash) && report["targets"].instance_of?(Array)
    raise ContractError, "coverage report root must contain a targets array"
  end
  unless expected_paths.instance_of?(Array) && expected_paths.any?
    raise ContractError, "expected production source inventory must be a nonempty array"
  end

  expected = expected_paths.map { |path| normalized_coverage_path(path, root) }
  unless expected == expected.sort && expected.uniq == expected
    raise ContractError, "expected production source inventory must be sorted and unique"
  end

  report["targets"].each_with_index do |target, index|
    unless target.instance_of?(Hash) &&
           target["name"].instance_of?(String) &&
           !target["name"].empty?
      raise ContractError, "coverage target #{index} has an unexpected schema"
    end
  end
  targets = report["targets"].select { |target| target["name"] == PRODUCTION_COVERAGE_TARGET }
  unless targets.length == 1
    raise ContractError, "expected exactly one #{PRODUCTION_COVERAGE_TARGET} coverage target, found #{targets.length}"
  end

  target = targets.first
  unless target["files"].instance_of?(Array)
    raise ContractError, "#{PRODUCTION_COVERAGE_TARGET} files must be an array"
  end

  target_covered = coverage_count(target, "coveredLines", PRODUCTION_COVERAGE_TARGET)
  target_executable = coverage_count(target, "executableLines", PRODUCTION_COVERAGE_TARGET)
  if target_covered > target_executable
    raise ContractError, "#{PRODUCTION_COVERAGE_TARGET} coveredLines exceeds executableLines"
  end

  records = {}
  target["files"].each_with_index do |file, index|
    raise ContractError, "coverage file #{index} has an unexpected schema" unless file.instance_of?(Hash)

    path = normalized_coverage_path(file["path"], root)
    raise ContractError, "duplicate coverage file: #{path}" if records.key?(path)

    covered = coverage_count(file, "coveredLines", path)
    executable = coverage_count(file, "executableLines", path)
    raise ContractError, "#{path} coveredLines exceeds executableLines" if covered > executable

    records[path] = [covered, executable]
  end

  missing = expected - records.keys
  extra = records.keys - expected
  raise ContractError, "missing coverage files: #{missing.join(", ")}" if missing.any?
  raise ContractError, "unexpected coverage files: #{extra.join(", ")}" if extra.any?

  covered_sum = checked_coverage_sum(expected.map { |path| records.fetch(path)[0] }, "coveredLines")
  executable_sum = checked_coverage_sum(expected.map { |path| records.fetch(path)[1] }, "executableLines")
  failures = []
  unless target_covered == covered_sum && target_executable == executable_sum
    failures << "#{PRODUCTION_COVERAGE_TARGET} counts do not match production file sums"
  end
  if target_covered != target_executable
    failures << "target #{PRODUCTION_COVERAGE_TARGET} has #{target_executable - target_covered} uncovered production lines"
  end
  expected.each do |path|
    covered, executable = records.fetch(path)
    failures << "#{path} has #{executable - covered} uncovered production lines" if covered != executable
  end
  raise ContractError, failures.join("; ") if failures.any?

  true
end

def validate_coverage_json(json, root, expected_paths)
  raise ContractError, "xccov returned a blank report" if json.to_s.strip.empty?

  validate_coverage_report(JSON.parse(json), root, expected_paths)
rescue JSON::ParserError => error
  raise ContractError, "xccov report is not valid JSON: #{error.message}"
end

def verify_coverage(result_bundle_path, root, expected_paths, runner: Open3.method(:capture3))
  output, error, status = runner.call(
    "xcrun",
    "xccov",
    "view",
    "--report",
    "--json",
    result_bundle_path
  )
  unless status.success?
    detail = error.to_s.strip
    raise ContractError, ["xccov failed", detail].reject(&:empty?).join(": ")
  end

  validate_coverage_json(output, root, expected_paths)
  puts "Coverage contracts: #{PRODUCTION_COVERAGE_TARGET} and #{expected_paths.length} production files are fully covered"
end

def expect_contract_rejection(name, pattern)
  yield
rescue ContractError => error
  unless error.message.match?(pattern)
    raise ContractError, "#{name} regression fixture failed for the wrong reason: #{error.message}"
  end
else
  raise ContractError, "#{name} regression fixture was accepted"
end

def assert_coverage_regression_fixtures
  root = "/coverage-fixture"
  expected = [
    "app/KnittingGaugeReconciler/A.swift",
    "app/KnittingGaugeReconciler/B.swift",
  ]
  valid = {
    "targets" => [{
      "name" => PRODUCTION_COVERAGE_TARGET,
      "coveredLines" => 3,
      "executableLines" => 3,
      "files" => [
        {
          "path" => File.join(root, expected[0]),
          "coveredLines" => 1,
          "executableLines" => 1,
        },
        {
          "path" => File.join(root, expected[1]),
          "coveredLines" => 2,
          "executableLines" => 2,
        },
      ],
    }],
  }
  valid_json = JSON.generate(valid)
  validate_coverage_json(valid_json, root, expected)
  copy = lambda { JSON.parse(valid_json) }
  changed = lambda do |&mutation|
    report = copy.call
    mutation.call(report)
    JSON.generate(report)
  end
  target = lambda { |report| report["targets"][0] }
  file = lambda { |report| target.call(report)["files"][0] }

  reports = [
    ["blank report", /blank report/, " \n"],
    ["malformed JSON", /not valid JSON/, "{"],
    ["non-finite JSON", /not valid JSON/, valid_json.sub('"coveredLines":3', '"coveredLines":NaN')],
    ["infinite JSON", /not valid JSON/, valid_json.sub('"coveredLines":3', '"coveredLines":Infinity')],
    ["root schema", /root must contain a targets array/, JSON.generate([])],
    ["missing targets", /root must contain a targets array/, JSON.generate({})],
    ["target schema", /coverage target 0 has an unexpected schema/, JSON.generate("targets" => [nil])],
    ["missing target", /exactly one/, changed.call { |report| target.call(report)["name"] = "Other.app" }],
    ["duplicate target", /exactly one/, changed.call { |report| report["targets"] << target.call(report).dup }],
    ["missing files array", /files must be an array/, changed.call { |report| target.call(report).delete("files") }],
    ["file schema", /coverage file 0 has an unexpected schema/, changed.call { |report| target.call(report)["files"][0] = nil }],
    ["missing file path", /path must be a nonempty string/, changed.call { |report| file.call(report).delete("path") }],
    ["escaping file path", /escapes repository/, changed.call { |report| file.call(report)["path"] = "/outside/A.swift" }],
    ["missing file", /missing coverage files/, changed.call { |report| target.call(report)["files"].pop }],
    ["duplicate file", /duplicate coverage file/, changed.call { |report| target.call(report)["files"] << file.call(report).dup }],
    ["extra file", /unexpected coverage files/, changed.call do |report|
      target.call(report)["files"] << {
        "path" => File.join(root, "app/KnittingGaugeReconciler/Extra.swift"),
        "coveredLines" => 0,
        "executableLines" => 0,
      }
    end],
    ["missing covered count", /missing coveredLines/, changed.call { |report| file.call(report).delete("coveredLines") }],
    ["missing executable count", /missing executableLines/, changed.call { |report| file.call(report).delete("executableLines") }],
    ["string count", /must be an integer/, changed.call { |report| file.call(report)["coveredLines"] = "1" }],
    ["null count", /must be an integer/, changed.call { |report| file.call(report)["coveredLines"] = nil }],
    ["boolean count", /must be an integer/, changed.call { |report| file.call(report)["coveredLines"] = true }],
    ["floating count", /must be an integer/, changed.call { |report| file.call(report)["coveredLines"] = 1.0 }],
    ["negative count", /outside signed 64-bit range/, changed.call { |report| file.call(report)["coveredLines"] = -1 }],
    ["out-of-range count", /outside signed 64-bit range/, changed.call do |report|
      file.call(report)["executableLines"] = MAX_COVERAGE_COUNT + 1
    end],
    ["target covered overflow", /coveredLines exceeds executableLines/, changed.call do |report|
      target.call(report)["coveredLines"] = 4
    end],
    ["file covered overflow", /coveredLines exceeds executableLines/, changed.call do |report|
      file.call(report)["coveredLines"] = 2
    end],
    ["sum overflow", /sum exceeds signed 64-bit range/, changed.call do |report|
      target.call(report)["coveredLines"] = MAX_COVERAGE_COUNT
      target.call(report)["executableLines"] = MAX_COVERAGE_COUNT
      target.call(report)["files"].each do |record|
        record["coveredLines"] = MAX_COVERAGE_COUNT
        record["executableLines"] = MAX_COVERAGE_COUNT
      end
    end],
    ["covered aggregate mismatch", /counts do not match production file sums/, changed.call do |report|
      target.call(report)["coveredLines"] = 2
    end],
    ["executable aggregate mismatch", /counts do not match production file sums/, changed.call do |report|
      target.call(report)["executableLines"] = 4
    end],
    ["target uncovered", /target .* has 1 uncovered production lines/, changed.call do |report|
      target.call(report)["coveredLines"] = 2
    end],
    ["file uncovered", /A\.swift has 1 uncovered production lines/, changed.call do |report|
      file.call(report)["coveredLines"] = 0
    end],
    ["consistent uncovered", /target .*A\.swift has 1 uncovered production lines/, changed.call do |report|
      target.call(report)["coveredLines"] = 2
      file.call(report)["coveredLines"] = 0
    end],
  ]
  success_status = Struct.new(:success?).new(true)
  reports.each do |name, pattern, json|
    expect_contract_rejection(name, pattern) do
      verify_coverage(
        "fixture.xcresult",
        root,
        expected,
        runner: lambda { |*| [json, "", success_status] }
      )
    end
  end

  failed_status = Struct.new(:success?).new(false)
  expect_contract_rejection("command failure", /xccov failed: fixture failure/) do
    verify_coverage(
      "fixture.xcresult",
      root,
      expected,
      runner: lambda { |*| ["", "fixture failure", failed_status] }
    )
  end
end

def assert_regression_fixtures
  unless missing_memberships(["app/Product/New.swift"], []).any?
    raise ContractError, "missing-membership regression fixture was accepted"
  end
  unless ui_recurrences(["app/FixtureUITests/Test.swift"], {}).any?
    raise ContractError, "UI-test recurrence regression fixture was accepted"
  end
  assert_coverage_regression_fixtures
end

def target_source_paths(target, root)
  target.source_build_phase.files_references.map do |reference|
    Pathname(reference.real_path.to_s).relative_path_from(Pathname(root)).to_s
  rescue ArgumentError
    raise ContractError, "source path escapes repository: #{reference.real_path}"
  end
end

def verify_scheme(root)
  schemes = Dir.glob(File.join(root, "app/app.xcodeproj/xcshareddata/xcschemes/*.xcscheme"))
  raise ContractError, "expected one shared scheme, found #{schemes.length}" unless schemes.length == 1

  document = REXML::Document.new(File.read(schemes.first))
  names = []
  REXML::XPath.each(document, "//BuildableReference") do |reference|
    name = reference.attributes["BlueprintName"]
    raise ContractError, "scheme BuildableReference has no BlueprintName" if name.to_s.empty?

    names << name
  end
  allowed = ["KnittingGaugeReconciler", "KnittingGaugeReconcilerTests"]
  unexpected = names.uniq - allowed
  raise ContractError, "scheme references unexpected targets: #{unexpected.join(", ")}" if unexpected.any?
  unless names.include?("KnittingGaugeReconciler") && names.include?("KnittingGaugeReconcilerTests")
    raise ContractError, "scheme omits the app or ordinary test target"
  end
end

def verify_fastlane_selection(root)
  fastfile = File.read(File.join(root, "app/fastlane/Fastfile"))
  expected = 'only_testing: ["KnittingGaugeReconcilerTests"]'
  raise ContractError, "Fastlane must select only KnittingGaugeReconcilerTests" unless fastfile.include?(expected)
end

def verify_repository(root)
  assert_regression_fixtures
  project = Xcodeproj::Project.open(File.join(root, "app/app.xcodeproj"))
  expected_targets = {
    "KnittingGaugeReconciler" => "app/KnittingGaugeReconciler",
    "KnittingGaugeReconcilerTests" => "app/KnittingGaugeReconcilerTests",
  }
  actual_names = project.targets.map(&:name)
  unless actual_names.sort == expected_targets.keys.sort
    raise ContractError, "unexpected Xcode targets: #{actual_names.join(", ")}"
  end

  inventory = {}
  expected_targets.each do |target_name, directory|
    target = project.targets.find { |candidate| candidate.name == target_name }
    raise ContractError, "missing target #{target_name}" unless target

    tracked = tracked_files(root, "#{directory}/*.swift", "#{directory}/**/*.swift").sort
    members = target_source_paths(target, root).grep(/\.swift\z/)
    missing = missing_memberships(tracked, members)
    extra = members - tracked
    raise ContractError, "#{target_name} misses tracked Swift files: #{missing.join(", ")}" if missing.any?
    raise ContractError, "#{target_name} contains untracked Swift files: #{extra.join(", ")}" if extra.any?

    inventory[target_name] = tracked
  end

  all_tracked = tracked_files(root)
  scan_paths = tracked_files(
    root,
    "app/app.xcodeproj",
    "app/fastlane",
    ".github",
    ".gitlab-ci.yml"
  )
  contents = scan_paths.to_h { |path| [path, File.binread(File.join(root, path))] }
  recurrence = ui_recurrences(all_tracked, contents).uniq
  raise ContractError, "UI-test recurrence detected: #{recurrence.join(", ")}" if recurrence.any?

  project.targets.each do |target|
    if target.product_type == "com.apple.product-type.bundle.ui-testing"
      raise ContractError, "UI-testing product type detected"
    end
  end
  verify_scheme(root)
  verify_fastlane_selection(root)
  puts "Xcode contracts: tracked membership complete; UI-test and coverage regression fixtures passed"
  inventory
end

if $PROGRAM_NAME == __FILE__
  begin
    root = File.expand_path(ARGV[1] || "../..", __dir__)
    inventory = verify_repository(root)
    if ARGV[0]
      verify_coverage(
        File.expand_path(ARGV[0]),
        root,
        inventory.fetch("KnittingGaugeReconciler")
      )
    end
  rescue StandardError => error
    warn "error: Xcode contract verification failed: #{error.message}"
    exit 1
  end
end
