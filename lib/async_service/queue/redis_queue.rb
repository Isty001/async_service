require_relative 'queue'


module AsyncService

  class RedisQueue < Queue

    # @param [Redis] redis
    def initialize(name, processing_list, redis, opts = {})
      super(name, opts)

      @processing_list = processing_list
      @redis = redis
    end

    def dequeue
      stuck_message = @redis.rpop(@processing_list)

      unless stuck_message.nil?
        @logger.info("Dequeue message from '#{@processing_list}' processing list")
        return stuck_message
      end

      @redis.brpoplpush(@name, @processing_list)
    end

    def cleanup(message)
      @redis.lrem(@processing_list, -1, message)
    end

    def enqueue_to(target, message)
      super(target.to_sym, message)

      @redis.lpush(target, message)
    end
  end
end
