require "fileutils"
require "find"

PROHIBITED_TEST_DIAGNOSTIC = /
  IOHID |
  IOSurface |
  IOCreatePlugInInterfaceForService |
  \bplugin\b.*\b(?:cannot|error|fail(?:ed|ure)?)\b |
  \b(?:cannot|error|fail(?:ed|ure)?)\b.*\bplugin\b |
  \bfopen\b.*\b(?:cannot|error|fail(?:ed|ure)?)\b |
  ^\d{4}-\d{2}-\d{2}.*\b(?:error|fail(?:ed|ure)?)\b |
  \bwarning: |
  \[!\] |
  \badvisory\b |
  \bfound\s+[1-9][0-9]*\s+violations?\b |
  \bfalling\s+back\b |
  \bfallback\b.*\b(?:error|fail(?:ed|ure)?)\b |
  \b(?:error|fail(?:ed|ure)?)\b.*\bfallback\b |
  \bbootstrap\w*\b.*\b(?:error|fail(?:ed|ure)?|killed)\b |
  \b(?:error|fail(?:ed|ure)?|killed)\b.*\bbootstrap\w*\b |
  \b(?:killed|terminated)\b.*\bsignal\b |
  \bsignal\s+(?:kill|term|[0-9]+)\b |
  \bsig(?:kill|term|abrt|segv)\b |
  \b(?:crashed|crash\s+report\s+found|unexpectedly\s+exited|exited\s+unexpectedly|unexpected\s+exit)\b
/inx

class TestDiagnosticsError < StandardError
end

def lstat_without_symlinks(path)
  current = File::SEPARATOR
  stat = File.lstat(current)
  File.expand_path(path).split(File::SEPARATOR).drop(1).each do |component|
    current = File.join(current, component)
    stat = File.lstat(current)
    raise TestDiagnosticsError, "Symlink path rejected: #{current}" if stat.symlink?
  end
  stat
rescue Errno::ENOENT, Errno::ENOTDIR
  nil
rescue SystemCallError => error
  raise TestDiagnosticsError, "Cannot inspect path #{current}: #{error.message}"
end

def verify_exported_test_diagnostics(raw_log_path, diagnostics_path)
  raw_stat = lstat_without_symlinks(raw_log_path)
  raise TestDiagnosticsError, "Raw xcodebuild log not found at #{raw_log_path}" unless raw_stat&.file?

  diagnostic_paths = []
  if lstat_without_symlinks(diagnostics_path)&.directory?
    Find.find(diagnostics_path) do |path|
      stat = File.lstat(path)
      raise TestDiagnosticsError, "Symlink path rejected: #{path}" if stat.symlink?
      diagnostic_paths << path if stat.file?
    end
  end
  raise TestDiagnosticsError, "No exported diagnostics found in #{diagnostics_path}" if diagnostic_paths.empty?

  prohibited_lines = []
  ([raw_log_path] + diagnostic_paths.sort).each do |path|
    raise TestDiagnosticsError, "Diagnostic file is no longer regular: #{path}" unless lstat_without_symlinks(path)&.file?
    contents = File.open(path, File::RDONLY | File::NOFOLLOW) { |file| file.binmode.read }
    $stdout.write(contents)
    $stdout.write("\n".b) unless contents.end_with?("\n".b)
    contents.each_line.with_index(1) do |line, line_number|
      prohibited_lines << [path, line_number, line] if line.match?(PROHIBITED_TEST_DIAGNOSTIC)
    end
  end

  return if prohibited_lines.empty?

  prohibited_lines.each do |path, line_number, line|
    $stderr.write(path.b)
    $stderr.write(":#{line_number}:".b)
    $stderr.write(line)
    $stderr.write("\n".b) unless line.end_with?("\n".b)
  end
  raise TestDiagnosticsError, "Prohibited Xcode/test-runner diagnostics detected"
rescue SystemCallError => error
  raise TestDiagnosticsError, "Cannot read diagnostics: #{error.message}"
end

def diagnostics_verifier_self_check
  require "open3"
  require "rbconfig"

  root = File.expand_path("../.build/diagnostics-verifier-self-check-#{Process.pid}", __dir__)
  verifier_path = File.join(root, "diagnostics_verifier.rb")
  raw_log_path = File.join(root, "raw.log")
  diagnostics_path = File.join(root, "export")
  testmanagerd_path = File.join(diagnostics_path, "testmanagerd.log")
  hidden_path = File.join(diagnostics_path, "nested", ".private", "session.log")

  run = lambda do
    Open3.capture3(RbConfig.ruby, verifier_path, raw_log_path, diagnostics_path)
  end

  FileUtils.rm_rf(root)
  FileUtils.mkdir_p(File.dirname(hidden_path))
  FileUtils.cp(File.expand_path(__FILE__), verifier_path)
  File.binwrite(raw_log_path, "raw log clean\n")
  File.binwrite(File.join(diagnostics_path, "StandardOutputAndStandardError.txt"), "runner clean\n")
  File.binwrite(hidden_path, "hidden nested clean \xFF\n")
  File.binwrite(testmanagerd_path, "fopen simulator service error\n")

  stdout, stderr, status = run.call
  expected_rejection = "#{testmanagerd_path}:1:fopen simulator service error"
  raise "prohibited sibling diagnostic was accepted" if status.success?
  raise "rejection omitted source path and line" unless stderr.include?(expected_rejection)
  puts "ok: prohibited sibling exit #{status.exitstatus}, #{testmanagerd_path}:1"

  File.binwrite(testmanagerd_path, "testmanagerd clean\n")
  outside_path = File.join(root, "outside.log")
  linked_path = File.join(diagnostics_path, "linked.log")
  File.binwrite(outside_path, "warning: outside content must not be scanned\n")
  File.symlink(outside_path, linked_path)
  stdout, stderr, status = run.call
  raise "symlinked diagnostic was accepted" if status.success?
  raise "symlink rejection omitted path" unless stderr.include?("Symlink path rejected: #{linked_path}")
  raise "outside symlink content was scanned" if stdout.include?("outside content")
  puts "ok: outside-file symlink rejected without scanning target, exit #{status.exitstatus}"
  FileUtils.rm_f(linked_path)

  stdout, stderr, status = run.call
  raise "clean diagnostics were rejected: #{stderr}" unless status.success?
  raise "nested dot-path diagnostic was not emitted byte-for-byte" unless stdout.b.include?("hidden nested clean \xFF\n".b)
  puts "ok: clean nested/dot and invalid UTF-8 diagnostics exit 0"

  FileUtils.rm_rf(diagnostics_path)
  FileUtils.mkdir_p(diagnostics_path)
  _stdout, stderr, status = run.call
  raise "empty diagnostics export was accepted" if status.success?
  raise "empty-export rejection was unclear" unless stderr.include?("No exported diagnostics found")
  puts "ok: empty export exit #{status.exitstatus}"

  File.binwrite(File.join(diagnostics_path, "session.log"), "session clean\n")
  FileUtils.rm_f(raw_log_path)
  _stdout, stderr, status = run.call
  raise "missing raw log was accepted" if status.success?
  raise "missing-log rejection was unclear" unless stderr.include?("Raw xcodebuild log not found")
  puts "ok: missing raw log exit #{status.exitstatus}"
ensure
  FileUtils.rm_rf(root) if root
end

if $PROGRAM_NAME == __FILE__
  if ARGV == ["--self-check"]
    diagnostics_verifier_self_check
  elsif ARGV.length == 2
    begin
      verify_exported_test_diagnostics(*ARGV)
    rescue TestDiagnosticsError => error
      warn error.message
      exit 1
    end
  else
    warn "Usage: ruby #{__FILE__} --self-check | RAW_LOG DIAGNOSTICS_DIRECTORY"
    exit 64
  end
end
