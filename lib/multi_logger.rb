# MultiLogger - A logger that outputs to multiple destinations
class MultiLogger
  def initialize(loggers)
    @loggers = loggers
  end

  def add(severity, message = nil, progname = nil, &block)
    @loggers.each { |logger| logger.add(severity, message, progname, &block) }
  end

  def debug(message = nil, progname = nil, &block)
    @loggers.each { |logger| logger.debug(message, &block) }
  end

  def info(message = nil, progname = nil, &block)
    @loggers.each { |logger| logger.info(message, &block) }
  end

  def warn(message = nil, progname = nil, &block)
    @loggers.each { |logger| logger.warn(message, &block) }
  end

  def error(message = nil, progname = nil, &block)
    @loggers.each { |logger| logger.error(message, &block) }
  end

  def fatal(message = nil, progname = nil, &block)
    @loggers.each { |logger| logger.fatal(message, &block) }
  end

  def unknown(message = nil, progname = nil, &block)
    @loggers.each { |logger| logger.unknown(message, &block) }
  end

  def level
    @loggers.first&.level
  end

  def level=(level)
    @loggers.each { |logger| logger.level = level }
  end

  def close
    @loggers.each { |logger| logger.close }
  end
end
