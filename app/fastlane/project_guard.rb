require "fileutils"
require "json"
require "open3"
require "pathname"
require "rexml/document"

module ProjectGuard
  module_function

  ROOT = File.expand_path("../..", __dir__)
  PROJECT = File.join(ROOT, "app/app.xcodeproj")
  FORBIDDEN = /(?:XCUITests|[A-Za-z0-9_]*UITests|com\.apple\.product-type\.bundle\.ui-testing)/i

  def tracked
    output, status = Open3.capture2e("git", "-C", ROOT, "ls-files")
    raise "git ls-files failed: #{output}" unless status.success?
    output.lines.map(&:strip)
  end

  def verify!(project_path: PROJECT, root: ROOT, files: tracked, metadata: nil)
    project = Xcodeproj::Project.open(project_path)
    swift = files.grep(%r{\Aapp/(?:KnittingGaugeReconciler|KnittingGaugeReconcilerTests)/.*\.swift\z})
    { "app/KnittingGaugeReconciler/" => "KnittingGaugeReconciler",
      "app/KnittingGaugeReconcilerTests/" => "KnittingGaugeReconcilerTests" }.each do |prefix, name|
      target = project.targets.find { |item| item.name == name } or raise "missing target #{name}"
      members = target.source_build_phase.files_references.map do |reference|
        Pathname(reference.real_path).relative_path_from(Pathname(root)).to_s
      end
      missing = swift.select { |path| path.start_with?(prefix) } - members
      raise "#{name} missing source membership: #{missing.join(", ")}" unless missing.empty?
    end

    raw = File.read(File.join(project_path, "project.pbxproj"))
    raise "UI-test metadata remains in complete PBX object graph" if raw.match?(FORBIDDEN)
    project.objects.each do |object|
      values = %i[name path product_type].filter_map { |key| object.public_send(key) if object.respond_to?(key) }
      raise "UI-test PBX object remains: #{object.uuid}" if values.any? { |value| value.to_s.match?(FORBIDDEN) }
    end

    metadata ||= files.select { |path| path.end_with?(".xcscheme", ".xctestplan") }.map { |path| File.join(ROOT, path) }
    metadata.each do |path|
      content = File.read(path)
      path.end_with?(".xcscheme") ? REXML::Document.new(content) : JSON.parse(content)
      raise "UI-test selection remains in #{path}" if content.match?(FORBIDDEN)
    rescue REXML::ParseException, JSON::ParserError => error
      raise "cannot parse #{path}: #{error.message}"
    end

    files.grep(%r{\A(?:app/(?:build\.sh|fastlane/(?:Fastfile|Appfile))|\.github/workflows/.*|\.gitlab-ci\.yml)\z})
      .map { |path| File.join(ROOT, path) }.each do |path|
      raise "UI-test Fastlane/CI selection remains in #{path}" if File.read(path).match?(FORBIDDEN)
    end
    paths = files.grep(%r{(?:^|/)(?:XCUITests|[^/]*UITests)(?:/|$)})
    raise "tracked UI-test source remains: #{paths.join(", ")}" unless paths.empty?
    true
  rescue StandardError => error
    raise "project guard failed closed: #{error.message}"
  end

  def self_test!
    scratch = File.join(ROOT, "app/.build/project-guard-self-test")
    FileUtils.rm_rf(scratch)
    FileUtils.mkdir_p(File.join(scratch, "app"))
    copy = File.join(scratch, "app/app.xcodeproj")
    files = tracked
    metadata = files.select { |path| path.end_with?(".xcscheme", ".xctestplan") }.map { |path| File.join(ROOT, path) }
    begin
      ui_name = "KnittingGaugeReconciler" + "UI" + "Tests"
      FileUtils.cp_r(PROJECT, copy)
      project = Xcodeproj::Project.open(copy)
      project.targets.find { |target| target.name == "KnittingGaugeReconcilerTests" }
        .source_build_phase.files.first.remove_from_project
      project.save
      reject!("missing target membership") { verify!(project_path: copy, root: scratch, files: files, metadata: metadata) }

      FileUtils.rm_rf(copy); FileUtils.cp_r(PROJECT, copy)
      scheme = File.join(scratch, "second.xcscheme")
      FileUtils.cp(metadata.find { |path| path.end_with?(".xcscheme") }, scheme)
      File.write(scheme, File.read(scheme).sub("KnittingGaugeReconcilerTests", ui_name))
      reject!("second-scheme UI target") { verify!(project_path: copy, root: scratch, files: files, metadata: metadata + [scheme]) }

      plan = File.join(scratch, "recurrence.xctestplan")
      File.write(plan, JSON.generate("testTargets" => [{ "target" => { "name" => ui_name } }]))
      reject!("UI-test test plan") { verify!(project_path: copy, root: scratch, files: files, metadata: metadata + [plan]) }

      inject(copy, "PBXFileReference",
             "DEADBEEFDEADBEEFDEADBEEF /* #{ui_name}.xctest */ = {isa = PBXFileReference; path = #{ui_name}.xctest; sourceTree = BUILT_PRODUCTS_DIR; };")
      reject!("orphan UI-test PBX product") { verify!(project_path: copy, root: scratch, files: files, metadata: metadata) }

      FileUtils.rm_rf(copy); FileUtils.cp_r(PROJECT, copy)
      inject(copy, "PBXGroup",
             "FEEDFACEFEEDFACEFEEDFACE /* #{ui_name} */ = {isa = PBXGroup; children = (); path = #{ui_name}; sourceTree = \"<group>\"; };")
      reject!("orphan UI-test PBX group") { verify!(project_path: copy, root: scratch, files: files, metadata: metadata) }
    ensure
      FileUtils.rm_rf(scratch)
    end
  end

  def inject(project, section, object)
    path = File.join(project, "project.pbxproj")
    marker = "/* End #{section} section */"
    content = File.read(path)
    raise "missing #{section}" unless content.include?(marker)
    File.write(path, content.sub(marker, "\t\t#{object}\n#{marker}"))
  end

  def reject!(name)
    yield
    raise "self-test accepted #{name}"
  rescue RuntimeError => error
    raise if error.message.start_with?("self-test accepted")
    puts "project guard self-test rejected: #{name}"
  end
end
