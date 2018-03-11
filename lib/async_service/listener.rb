require_relative 'message/message'
require_relative 'message/message_factory'
require_relative 'null_logger'
require_relative 'errors'


module AsyncService

  class Listener

    def initialize(name, queue, serializer, opts = {})
      @name = name
      @queue = queue
      @serializer = serializer
      @msg_factory = opts.fetch(:message_factory, MessageFactory.new)
      @logger = opts.fetch(:logger, NullLogger.new)
      @response_processors = {}
      @multi_message_processors = []
    end

    def dispatch(params, response_to, &processor)

      if response_to.is_a?(Message)
        target = response_to.origin
        parent_id = response_to.id
      else
        target = response_to.to_sym
        parent_id = nil
      end

      message = create_message(params, parent_id)

      if processor
        @response_processors[message.id] = processor
      end

      @logger.debug("Dispatching message '#{message.id}' to target:'#{target}' parent:'#{message.parent_id}'")
      @queue.enqueue_to(target, @serializer.serialize(message))
    end

    def dispatch_multi(params_map, &processor)
      messages = {}

      params_map.each do |name, msg_def|
        msg = create_message(msg_def[:params])
        messages[name] = msg.id
        target = msg_def[:target]

        @logger.debug("Dispatching multi message '#{msg.id}' to target:'#{target}'")
        @queue.enqueue_to(target, @serializer.serialize(msg))
      end

      @multi_message_processors << {messages: messages, processor: processor}
    end

    def receive(&default_processor)
      raw = @queue.dequeue
      message = @serializer.deserialize(raw)
      @logger.debug("Received message '#{message.id}' from target:'#{message.origin}' parent:'#{message.parent_id}'")

      if message.parent_id
        process_response(message)
      else
        default_processor.call(message)
      end

      @queue.cleanup(raw)
    end

    private
    def process_response(message)
      parent_id = message.parent_id

      if @response_processors.key?(parent_id)
        @response_processors[parent_id].call(message)
        @response_processors.delete(parent_id)
      else
        process_multi_response(message)
      end
    end

    def process_multi_response(message)
      found = @multi_message_processors.detect do |in_progress|
        in_progress[:messages].has_value?(message.parent_id)
      end

      unless found
        raise UnknownParentError.new(message)
      end

      name = found[:messages].key(message.parent_id)
      found[:messages][name] = message
      finished = found[:messages].all? do |_, msg|
        msg.is_a?(Message)
      end

      if finished
        @multi_message_processors.delete(found)

        if found.key?(:processor)
          found[:processor].call(found[:messages])
        end
      end
    end

    def create_message(params, parent_id = nil)
      @msg_factory.create_new(@name, params, parent_id)
    end
  end
end
