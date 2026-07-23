require "json"

repo_root = File.expand_path(__dir__)
changed_files = (
  git.added_files +
  git.modified_files +
  git.deleted_files +
  git.renamed_files.flat_map { |rename| [rename[:before], rename[:after]] }
).compact.uniq
updated_files = (
  git.added_files +
  git.modified_files +
  git.renamed_files.map { |rename| rename[:after] }
).compact.uniq

app_icon_manifest = "app/KnittingGaugeReconciler/Assets.xcassets/AppIcon.appiconset/Contents.json"
begin
  icon_contents = JSON.parse(File.read(File.join(repo_root, app_icon_manifest)))
  missing_icons = icon_contents.fetch("images", []).filter_map do |image|
    filename = image["filename"]
    next if filename.nil? || filename.empty?

    icon_path = File.join(File.dirname(app_icon_manifest), filename)
    icon_path unless File.file?(File.join(repo_root, icon_path))
  end

  warn("App icon manifest references missing files: #{missing_icons.join(", ")}") unless missing_icons.empty?
rescue Errno::ENOENT
  warn("App icon manifest is missing: #{app_icon_manifest}")
rescue JSON::ParserError => error
  warn("App icon manifest is invalid JSON: #{error.message}")
end

production_swift_changed = changed_files.any? do |path|
  path.start_with?("app/KnittingGaugeReconciler/") && path.end_with?(".swift")
end
swift_tests_updated = updated_files.any? do |path|
  path.end_with?(".swift") && path.split("/").any? { |component| component.end_with?("Tests") }
end

if production_swift_changed && !swift_tests_updated
  warn("Production Swift changed without a corresponding Swift test change.")
end

scene_storage_literals = lambda do |line|
  direct_literals = line.scan(/@SceneStorage\s*\(\s*"((?:\\.|[^"])*)"/).flatten
  named_key_literals = line.scan(/\b(?:static\s+)?let\s+\w*Key\s*=\s*"((?:\\.|[^"])*)"/).flatten
  direct_literals + named_key_literals
end

deleted_scene_storage_literals = []
added_scene_storage_literals = []

changed_files.grep(/\.swift\z/).each do |path|
  patch = git.diff_for_file(path)&.patch.to_s
  patch.each_line do |line|
    if line.start_with?("-") && !line.start_with?("---")
      deleted_scene_storage_literals.concat(scene_storage_literals.call(line[1..]))
    elsif line.start_with?("+") && !line.start_with?("+++")
      added_scene_storage_literals.concat(scene_storage_literals.call(line[1..]))
    end
  end
end

removed_scene_storage_literals =
  deleted_scene_storage_literals.uniq - added_scene_storage_literals.uniq
unless removed_scene_storage_literals.empty?
  warn(
    "SceneStorage key literals were removed or changed: " \
    "#{removed_scene_storage_literals.map(&:inspect).join(", ")}. " \
    "Changing these keys can discard in-progress scene state."
  )
end

shared_layout_files = %w[
  GaugeMeasurementPair.swift
  GaugeStepperField.swift
  GaugeInputsCard.swift
  PatternInstructionsCard.swift
  AdjustmentRow.swift
  RequiredAdjustmentsCard.swift
]
shared_layout_changed = changed_files.any? do |path|
  shared_layout_files.include?(File.basename(path))
end
regression_guardrail_updated = updated_files.any? do |path|
  File.basename(path) == "RegressionGuardrailTests.swift"
end

if shared_layout_changed && !regression_guardrail_updated
  warn("Shared layout changed without updating RegressionGuardrailTests.swift.")
end

message("Danger checks are advisory and do not block merging.")
