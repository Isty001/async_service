## Async Service

This gem provides a very simple way to create asynchronous, independent microservices, using message queues.

### Install
```ruby
gem install async_service
```

### Usage

The API is simple. The `Listener` class has only three methods to handle messages.

`receive(&default_processor)`

The block passed to this method, will get all the *non response* `Message`

`dispatch(params, response_to, &processor)`

* `params` can be anything you wan to send.
* `response_to` is a message received you wan to send a response to, or a service queue name
* `processor` is an optional block, accepting the response `Message`. If you receive the response to the message, this block will be called

`dispatch_multi(params_map, &processor)`

Sometimes it's also necessary to dispatch mutiple messages and receive all of them to handle a task, but we want to do other things until then. This method can send many messages, and invoke the block when all of them are finished.

However, we not always expect to have a response to some of the messages. See the example below.

* `params_map` a map of requests
* `processor` optional block, accepting a map of responses


### Example

The default implementation uses Redis based queues, and JSON serialized messages.
Let's say we have two services called `user` and `group`.

The `group` service

```ruby
require 'async_service'
require 'redis'
require 'logger'


logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

redis = Redis.new
#allowd_targets if an array, target queue name will be checked if contained by this list
opts = {allowed_targets: [:user], logger: logger}

handler = AsyncService.create_redis_json_handler(:group, redis, opts)

params = {
    test_1: {target: :user, params: {action: 'start'}},
    test_2: {target: :user, params: {action: 'stop'}, no_response: true}
}
handler.dispatch_multi(params) do |responses|
  puts responses[:test_1].params
end

while true
  handler.receive do |req|
    # handle non response requests
  end
end
```

The `user` service:

```ruby
require 'async_service'
require 'redis'
require 'logger'

logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

redis = Redis.new
opts = {allowed_targets: [:group], logger: logger}

handler = AsyncService.create_redis_json_handler(:user, redis, opts)

while true
  handler.receive do |request|
    if 'start' == request.params[:action]
      # Do something, and send a response to the request
      handler.dispatch({started: true}, request)
    end
    if 'stop' == request.params[:action]
      # 
      handler.dispatch({stopped: true}, request)
    end
  end
end
```
