module AsyncService

  class MessageError < ArgumentError
    attr_reader :message_id, :parent_id, :origin

    def initialize(message, reason)
      @message_id = message.id
      @parent_id = message.parent_id
      @origin = message.origin

      super(reason)
    end
  end

  class UnknownParentError < MessageError

    def initialize(message)
      super(message, "Unknown parent id '#{message.parent_id}'")
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