require "open3"
require "pathname"
require "rexml/document"
require "xcodeproj" unless defined?(Xcodeproj)

class ContractError < StandardError
end

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
  paths.grep(path_pattern) + contents.filter_map { |path, text| path if text.match?(metadata_pattern) }
end

def assert_regression_fixtures
  unless missing_memberships(["app/Product/New.swift"], []).any?
    raise ContractError, "missing-membership regression fixture was accepted"
  end
  unless ui_recurrences(["app/FixtureUITests/Test.swift"], {}).any?
    raise ContractError, "UI-test recurrence regression fixture was accepted"
  end
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

  expected_targets.each do |target_name, directory|
    target = project.targets.find { |candidate| candidate.name == target_name }
    raise ContractError, "missing target #{target_name}" unless target

    tracked = tracked_files(root, "#{directory}/*.swift", "#{directory}/**/*.swift")
    members = target_source_paths(target, root).grep(/\.swift\z/)
    missing = missing_memberships(tracked, members)
    extra = members - tracked
    raise ContractError, "#{target_name} misses tracked Swift files: #{missing.join(", ")}" if missing.any?
    raise ContractError, "#{target_name} contains untracked Swift files: #{extra.join(", ")}" if extra.any?
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
  puts "Xcode contracts: tracked membership complete; UI-test recurrence fixtures rejected"
end

if $PROGRAM_NAME == __FILE__
  begin
    verify_repository(File.expand_path("../..", __dir__))
  rescue StandardError => error
    warn "error: Xcode contract verification failed: #{error.message}"
    exit 1
  end
end
