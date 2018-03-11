require 'test_init'


class ListenerTest < Minitest::Test

  def test_receive_default
    serializer = AsyncService::JsonSerializer.new
    opts = {message_factory: MiniTest::Mock.new}

    expected = create_message('id', 'test', {id: 10})
    raw = serializer.serialize(expected)

    queue = MiniTest::Mock.new
    queue.expect(:dequeue, raw)
    queue.expect(:cleanup, nil, [raw])

    insurance = create_insurance

    handler = AsyncService::Listener.new('test', queue, serializer, opts)

    handler.receive do |actual|
      insurance.do_something
      assert_equal(expected.id, actual.id)
      assert_equal(expected.created_at, actual.created_at)
    end

    queue.verify
    insurance.verify
  end

  def test_receive_response
    serializer = AsyncService::JsonSerializer.new

    initial = create_message('initial', 'test', {id: 100})
    response = create_message('response', 'other_service', {ok: true}, 'initial')

    opts = {message_factory: mock_factory(initial)}

    initial_raw = serializer.serialize(initial)
    response_raw = serializer.serialize(response)

    queue = MiniTest::Mock.new
    queue.expect(:enqueue_to, nil, [:other_service, initial_raw])
    queue.expect(:dequeue, response_raw)
    queue.expect(:cleanup, nil, [response_raw])

    insurance = create_insurance

    handler = AsyncService::Listener.new('test', queue, serializer, opts)
    handler.dispatch(initial.params, :other_service) do |resp|
      insurance.do_something

      assert_equal(initial.id, resp.parent_id)
      assert_equal({ok: true}, resp.params)
      assert_equal('other_service', resp.origin)
    end

    handler.receive

    queue.verify
    insurance.verify
  end

  def test_receive_multi_response
    serializer = AsyncService::JsonSerializer.new

    param_map = {
        register: {target: :player, params: {id: 100}},
        groupAdd: {target: :group, params: {groupId: 1, playerId: 100}},
        move: {target: :player, params: {x: 100, y: 200}}
    }

    factory, messages = mock_multi_factory(param_map)
    queue = mock_multi_queue(serializer, messages)
    opts = {message_factory: factory}

    insurance = create_insurance

    handler = AsyncService::Listener.new('test', queue, serializer, opts)
    handler.dispatch_multi(param_map) do |responses|
      insurance.do_something

      assert_equal(param_map.keys, responses.keys)

      responses.each_value do |resp|
        assert_equal({ok: true}, resp.params)
      end
    end

    handler.receive
    handler.receive
    handler.receive

    queue.verify
    insurance.verify
  end

  private
  def mock_factory(msg)

    factory = MiniTest::Mock.new
    factory.expect(:create_new, msg, ['test', msg.params, msg.parent_id])
    factory
  end

  def create_message(id, origin, params, parent_id = nil)
    AsyncService::Message.new(id, origin, params, Time.now.to_i, parent_id)
  end

  def create_insurance
    insurance = MiniTest::Mock.new
    insurance.expect(:do_something, nil)
    insurance
  end

  def mock_multi_factory(param_map)
    factory = MiniTest::Mock.new

    messages = param_map.map do |_, msg_def|
      msg = AsyncService::Message.new(SecureRandom.uuid, 'test', msg_def[:params], 'now')
      factory.expect(:create_new, msg, ['test', msg_def[:params], nil])

      msg
    end

    [factory, messages]
  end

  def mock_multi_queue(serializer, messages)
    queue = MiniTest::Mock.new

    expected_targets = [:player, :group, :player]

    messages.each_with_index do |msg, i|
      queue.expect(:enqueue_to, nil, [expected_targets[i], serializer.serialize(msg)])

      resp = AsyncService::Message.new(i + 10, expected_targets[i], {ok: true}, 'now', msg.id)
      resp_raw = serializer.serialize(resp)
      queue.expect(:dequeue, resp_raw)
      queue.expect(:cleanup, nil, [resp_raw])
    end

    queue
  end
end
