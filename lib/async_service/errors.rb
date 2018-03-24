module AsyncService

  class MessageError < ArgumentError

    attr_reader :service_message

    def initialize(reason, service_message)
      super(reason)

      @service_message = service_message
    end
  end

  class UnknownParentError < MessageError

    def initialize(service_message)
      super("Unknown parent id '#{service_message.parent_id}'", service_message)
    end
  end

  class TargetNotAllowedError < ArgumentError

    attr_reader :target

    def initialize(target)
      @target = target

      super("Target '#{@target}' not allowed")
    end
  end
end