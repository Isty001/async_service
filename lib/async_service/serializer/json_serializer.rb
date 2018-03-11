require 'json'


module AsyncService
  class JsonSerializer

    def serialize(message)
      message.to_hash.to_json
    end

    def deserialize(raw)
      hash = JSON.parse(raw, {symbolize_names: true})
      Message.from_hash(hash)
    end
  end
end
