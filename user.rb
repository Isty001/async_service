require 'async_service'
require 'redis'
require 'logger'


logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG
redis = Redis.new
opts = {allowed_targets: [:group], logger: logger}

handler = AsyncService.create_redis_json_handler(:user, redis, opts)


while true
  handler.receive do |req|
    if 'start' == req.params[:action]
      handler.dispatch({started: true}, req)
    end
    if 'stop' == req.params[:action]
      #
    end
  end
end