require 'securerandom'


module AsyncService

  class MessageFactory

    def create_new(origin, params, parent_id = nil)
      Message.new(
          SecureRandom.uuid,
          origin,
          params,
          Time.now.to_i,
          parent_id
      )
    end
  end
end
