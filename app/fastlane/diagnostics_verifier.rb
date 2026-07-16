require "fileutils"
require "fcntl"
require "fiddle"

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

module NativeDiagnosticsFile
  LIBC = Fiddle.dlopen(nil)
  INTEGER = Fiddle::TYPE_INT
  POINTER = Fiddle::TYPE_VOIDP
  ERROR = Fiddle::Function.new(LIBC["__error"], [], POINTER)
  CLOSE = Fiddle::Function.new(LIBC["close"], [INTEGER], INTEGER)
  CLOSEDIR = Fiddle::Function.new(LIBC["closedir"], [POINTER], INTEGER)
  DUP = Fiddle::Function.new(LIBC["dup"], [INTEGER], INTEGER)
  FDOPENDIR = Fiddle::Function.new(LIBC["fdopendir"], [INTEGER], POINTER)
  OPENAT = Fiddle::Function.new(LIBC["openat"], [INTEGER, POINTER, INTEGER], INTEGER)
  READDIR = Fiddle::Function.new(LIBC["readdir"], [POINTER], POINTER)

  define_singleton_method(:__error) { ERROR.call }
  define_singleton_method(:close) { |descriptor| CLOSE.call(descriptor) }
  define_singleton_method(:closedir) { |directory| CLOSEDIR.call(directory) }
  define_singleton_method(:dup) { |descriptor| DUP.call(descriptor) }
  define_singleton_method(:fdopendir) { |descriptor| FDOPENDIR.call(descriptor) }
  define_singleton_method(:openat) { |directory, name, flags| OPENAT.call(directory, name, flags) }
  define_singleton_method(:readdir) { |directory| READDIR.call(directory) }
end

DIAGNOSTIC_OPEN_FLAGS = File::RDONLY | File::NOFOLLOW | Fcntl::O_NONBLOCK
DIAGNOSTIC_DIRENT_NAMLEN_OFFSET = 18
DIAGNOSTIC_DIRENT_NAME_OFFSET = 21

def diagnostics_native_error(message, errno)
  SystemCallError.new(message, errno)
end

def diagnostics_open_at(directory, name, display_path)
  descriptor = NativeDiagnosticsFile.openat(directory.fileno, name, DIAGNOSTIC_OPEN_FLAGS)
  if descriptor.negative?
    errno = Fiddle.last_error
    raise TestDiagnosticsError, "Symlink path rejected: #{display_path}" if errno == Errno::ELOOP::Errno

    raise diagnostics_native_error("Cannot open #{display_path}", errno)
  end

  IO.new(descriptor, "rb").tap { |file| file.close_on_exec = true }
end

def diagnostics_duplicate(file)
  descriptor = NativeDiagnosticsFile.dup(file.fileno)
  raise diagnostics_native_error("Cannot duplicate file descriptor", Fiddle.last_error) if descriptor.negative?

  IO.new(descriptor, "rb").tap { |copy| copy.close_on_exec = true }
end

def diagnostics_open_from(directory, components, base_path)
  current = diagnostics_duplicate(directory)
  components.each_with_index do |component, index|
    display_path = File.join(base_path, *components.take(index + 1))
    child = diagnostics_open_at(current, component, display_path)
    current.close
    current = child
    unless index == components.length - 1 || current.stat.directory?
      raise TestDiagnosticsError, "Non-directory path component rejected: #{display_path}"
    end
  end
  current
rescue
  current&.close unless current&.closed?
  raise
end

def diagnostics_open_anchored(path)
  expanded_path = File.expand_path(path)
  root = File.open(File::SEPARATOR, DIAGNOSTIC_OPEN_FLAGS)
  diagnostics_open_from(root, expanded_path.split(File::SEPARATOR).drop(1), File::SEPARATOR)
ensure
  root&.close unless root&.closed?
end

def diagnostics_directory_entries(directory, display_path)
  descriptor = NativeDiagnosticsFile.openat(directory.fileno, ".", DIAGNOSTIC_OPEN_FLAGS)
  raise diagnostics_native_error("Cannot enumerate #{display_path}", Fiddle.last_error) if descriptor.negative?

  stream = NativeDiagnosticsFile.fdopendir(descriptor)
  if stream.to_i.zero?
    errno = Fiddle.last_error
    NativeDiagnosticsFile.close(descriptor)
    raise diagnostics_native_error("Cannot enumerate #{display_path}", errno)
  end

  entries = []
  errno_pointer = NativeDiagnosticsFile.__error
  loop do
    errno_pointer[0, Fiddle::SIZEOF_INT] = [0].pack("i")
    entry = NativeDiagnosticsFile.readdir(stream)
    if entry.to_i.zero?
      errno = errno_pointer[0, Fiddle::SIZEOF_INT].unpack1("i")
      raise diagnostics_native_error("Cannot enumerate #{display_path}", errno) unless errno.zero?

      break
    end

    # Darwin's dirent keeps d_namlen at byte 18 and d_name at byte 21.
    length = entry[DIAGNOSTIC_DIRENT_NAMLEN_OFFSET, 2].unpack1("S")
    name = entry[DIAGNOSTIC_DIRENT_NAME_OFFSET, length]
    entries << name unless name == "." || name == ".."
  end
  entries.sort
ensure
  NativeDiagnosticsFile.closedir(stream) if stream && !stream.to_i.zero?
end

def collect_diagnostic_files(directory, display_path, relative_components, keep_open, files = [])
  diagnostics_directory_entries(directory, display_path).each do |name|
    child_path = File.join(display_path, name)
    child = diagnostics_open_at(directory, name, child_path)
    stat = child.stat
    components = relative_components + [name]
    if stat.directory?
      collect_diagnostic_files(child, child_path, components, keep_open, files)
    elsif stat.file?
      files << [child_path, components, keep_open ? child : nil, stat.dev, stat.ino]
      child = nil if keep_open
    else
      raise TestDiagnosticsError, "Non-regular diagnostic rejected: #{child_path}"
    end
  ensure
    child&.close unless child&.closed?
  end
  files
end

def same_diagnostic_file?(file, device, inode)
  stat = file.stat
  stat.dev == device && stat.ino == inode
end

def verify_diagnostic_boundary_unchanged(boundary_path, boundary)
  stat = boundary.stat
  reopened = diagnostics_open_anchored(boundary_path)
  unless same_diagnostic_file?(reopened, stat.dev, stat.ino)
    raise TestDiagnosticsError, "Diagnostic boundary changed during verification: #{boundary_path}"
  end
rescue SystemCallError, TestDiagnosticsError => error
  raise error if error.message.start_with?("Diagnostic boundary changed")

  raise TestDiagnosticsError, "Diagnostic boundary changed during verification: #{boundary_path} (#{error.message})"
ensure
  reopened&.close unless reopened&.closed?
end

def verify_diagnostic_path_unchanged(boundary, boundary_path, record)
  display_path, components, _file, device, inode = record
  reopened = diagnostics_open_from(boundary, components, boundary_path)
  unless same_diagnostic_file?(reopened, device, inode)
    raise TestDiagnosticsError, "Diagnostic path changed during verification: #{display_path}"
  end
rescue SystemCallError, TestDiagnosticsError => error
  raise error if error.message.start_with?("Diagnostic path changed")

  raise TestDiagnosticsError, "Diagnostic path changed during verification: #{display_path} (#{error.message})"
ensure
  reopened&.close unless reopened&.closed?
end

def verify_exported_test_diagnostics(raw_log_path, diagnostics_path)
  raw_components = File.expand_path(raw_log_path).split(File::SEPARATOR).drop(1)
  diagnostics_components = File.expand_path(diagnostics_path).split(File::SEPARATOR).drop(1)
  common_length = 0
  common_limit = [raw_components.length, diagnostics_components.length].min - 1
  while common_length < common_limit &&
        raw_components[common_length] == diagnostics_components[common_length]
    common_length += 1
  end
  boundary_path = File.join(File::SEPARATOR, *raw_components.take(common_length))
  raw_relative = raw_components.drop(common_length)
  diagnostics_relative = diagnostics_components.drop(common_length)

  boundary = diagnostics_open_anchored(boundary_path)
  raise TestDiagnosticsError, "Diagnostic boundary is not a directory: #{boundary_path}" unless boundary.stat.directory?

  begin
    raw_file = diagnostics_open_from(boundary, raw_relative, boundary_path)
  rescue Errno::ENOENT, Errno::ENOTDIR
    raw_file = nil
  end
  raise TestDiagnosticsError, "Raw xcodebuild log not found at #{raw_log_path}" unless raw_file&.stat&.file?

  begin
    diagnostics_directory = diagnostics_open_from(boundary, diagnostics_relative, boundary_path)
  rescue Errno::ENOENT, Errno::ENOTDIR
    diagnostics_directory = nil
  end
  unless diagnostics_directory&.stat&.directory?
    raise TestDiagnosticsError, "No exported diagnostics found in #{diagnostics_path}"
  end

  diagnostic_files = collect_diagnostic_files(
    diagnostics_directory,
    diagnostics_path,
    diagnostics_relative,
    true
  )
  raise TestDiagnosticsError, "No exported diagnostics found in #{diagnostics_path}" if diagnostic_files.empty?

  raw_stat = raw_file.stat
  raw_record = [raw_log_path, raw_relative, raw_file, raw_stat.dev, raw_stat.ino]
  verify_diagnostic_boundary_unchanged(boundary_path, boundary)
  ([raw_record] + diagnostic_files).each do |record|
    verify_diagnostic_path_unchanged(boundary, boundary_path, record)
  end

  prohibited_lines = []
  ([raw_record] + diagnostic_files.sort_by(&:first)).each do |path, _components, file, _device, _inode|
    contents = file.read
    $stdout.write(contents)
    $stdout.write("\n".b) unless contents.end_with?("\n".b)
    contents.each_line.with_index(1) do |line, line_number|
      prohibited_lines << [path, line_number, line] if line.match?(PROHIBITED_TEST_DIAGNOSTIC)
    end
  end

  rescanned_files = collect_diagnostic_files(
    diagnostics_directory,
    diagnostics_path,
    diagnostics_relative,
    false
  )
  initial_snapshot = diagnostic_files.map { |record| [record[1], record[3], record[4]] }
  final_snapshot = rescanned_files.map { |record| [record[1], record[3], record[4]] }
  raise TestDiagnosticsError, "Exported diagnostics changed during verification" unless initial_snapshot == final_snapshot

  verify_diagnostic_boundary_unchanged(boundary_path, boundary)
  ([raw_record] + diagnostic_files).each do |record|
    verify_diagnostic_path_unchanged(boundary, boundary_path, record)
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
ensure
  diagnostic_files&.each do |record|
    file = record[2]
    file&.close unless file&.closed?
  end
  raw_file&.close unless raw_file&.closed?
  diagnostics_directory&.close unless diagnostics_directory&.closed?
  boundary&.close unless boundary&.closed?
end

def diagnostics_verifier_self_check
  require "open3"
  require "rbconfig"
  require "socket"
  require "stringio"

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

  socket_path = File.join(diagnostics_path, "socket")
  socket = Dir.chdir(root) { UNIXServer.new(File.join("export", "socket")) }
  _stdout, stderr, status = run.call
  raise "non-regular diagnostic was accepted" if status.success?
  raise "non-regular rejection omitted path" unless stderr.include?(socket_path)
  puts "ok: non-regular diagnostic rejected, exit #{status.exitstatus}"
  socket.close
  socket = nil
  FileUtils.rm_f(socket_path)

  stdout, stderr, status = run.call
  raise "clean diagnostics were rejected: #{stderr}" unless status.success?
  raise "nested dot-path diagnostic was not emitted byte-for-byte" unless stdout.b.include?("hidden nested clean \xFF\n".b)
  puts "ok: clean nested/dot and invalid UTF-8 diagnostics exit 0"

  race_path = File.join(root, "race-boundary")
  parked_path = File.join(root, "race-boundary-parked")
  outside_directory = File.join(root, "race-outside")
  race_raw_path = File.join(race_path, "raw.log")
  race_diagnostics_path = File.join(race_path, "export")
  outside_sentinel = "warning: OUTSIDE_SENTINEL_CONTENT\n"
  FileUtils.mkdir_p(race_diagnostics_path)
  FileUtils.mkdir_p(File.join(outside_directory, "export"))
  File.binwrite(race_raw_path, "anchored raw clean\n")
  File.binwrite(File.join(race_diagnostics_path, "session.log"), "anchored export clean\n")
  File.binwrite(File.join(outside_directory, "raw.log"), outside_sentinel)
  File.binwrite(File.join(outside_directory, "export", "session.log"), outside_sentinel)

  captured_stdout = StringIO.new("".b)
  original_stdout = $stdout
  race_error = nil
  swapped = false
  trace = TracePoint.new(:call) do |event|
    next unless event.method_id == :collect_diagnostic_files

    trace.disable
    File.rename(race_path, parked_path)
    File.symlink(outside_directory, race_path)
    swapped = true
  end
  begin
    $stdout = captured_stdout
    trace.enable { verify_exported_test_diagnostics(race_raw_path, race_diagnostics_path) }
  rescue TestDiagnosticsError => error
    race_error = error
  ensure
    trace.disable
    $stdout = original_stdout
  end
  outside_read = captured_stdout.string.include?("OUTSIDE_SENTINEL_CONTENT")
  raise "ancestor swap did not run" unless swapped
  raise "ancestor swap was accepted" unless race_error
  raise "ancestor swap rejection was unclear" unless race_error.message.include?("Diagnostic boundary changed")
  raise "outside ancestor content was read" if outside_read
  puts "ok: ancestor directory swap rejected; ACCEPTED=false OUTSIDE_READ=false"

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
  socket&.close
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
