require 'msgpack'


module AsyncService

  class Message

    attr_reader :id, :origin, :params, :created_at, :parent_id

    def initialize(id, origin, params, created_at, parent_id = nil)
      @id = id
      @origin = origin
      @params = params
      @created_at = created_at
      @parent_id = parent_id
    end

    def to_hash
      {
          id: @id,
          origin: @origin,
          params: @params,
          created_at: @created_at,
          parent_id: @parent_id
      }
    end

    def self.from_hash(hash)
      new(
          hash[:id],
          hash[:origin],
          hash[:params],
          hash[:created_at],
          hash[:parent_id]
      )
    end
  end
end
