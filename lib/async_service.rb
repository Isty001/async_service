require_relative 'async_service/listener'
require_relative 'async_service/serializer/json_serializer'
require_relative 'async_service/queue/redis_queue'
require_relative 'async_service/message/message'


module AsyncService
  VERSION = '0.0.0'

  def self.create_redis_json_handler(name, redis, opts = {})
    queue = RedisQueue.new(name, "#{name}.processing", redis, opts)
    serializer = JsonSerializer.new

    Listener.new(name, queue, serializer, opts)
  end
end
