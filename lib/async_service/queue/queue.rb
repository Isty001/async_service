require_relative '../null_logger'
require_relative '../errors'


module AsyncService

  class Queue

    def initialize(name, opts = {})
      @name = name
      @logger = opts.fetch(:logger, NullLogger.new)
      @allowed_targets = opts.fetch(:allowed_targets, nil)
    end

    def enqueue_to(target, message)
      if !@allowed_targets.nil? && !@allowed_targets.include?(target)
        raise TargetNotAllowedError.new(target)
      end
    end
  end
end
