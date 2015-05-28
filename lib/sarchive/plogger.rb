require 'logger'
require 'fileutils'

class PLogger

  def initialize(log_path, err_log_path)
    FileUtils.mkdir_p(File::dirname(log_path))
    FileUtils.mkdir_p(File::dirname(err_log_path))

    @stdout = Logger.new STDOUT
    @stderr = Logger.new STDERR
    @log    = Logger.new(log_path, 'monthly')
    @elog   = Logger.new(err_log_path, 'monthly')
  end

  %w(debug info warn).each do |level|
    define_method(level) do |*args|
      [@stdout, @log].all? do |output|
        output.send level, *args
      end
    end
  end

  %w(error fatal).each do |level|
    define_method(level) do |*args|
      [@stderr, @log, @elog].all? do |output|
        output.send level, *args
      end
    end
  end
end