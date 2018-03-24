require 'async_service'
require 'redis'
require 'logger'


logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG
redis = Redis.new
opts = {allowed_targets: [:user], logger: logger}

handler = AsyncService.create_redis_json_handler(:group, redis, opts)


params = {
    test_1: {target: :user, params: {action: 'start'}, no_response: true},
    test_2: {target: :user, params: {action: 'stop'}}
}
handler.dispatch_multi(params) do |responses|
  puts responses
  # puts responses[:test_2].params
end

while true
  begin
    handler.receive do |req|
      # puts req.params
    end
  rescue AsyncService::MessageError => e
    puts e.service_message
  end
end