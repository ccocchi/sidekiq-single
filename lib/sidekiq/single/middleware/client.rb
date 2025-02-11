# frozen_string_literal: true

module Sidekiq::Single
  class ClientMiddleware
    include ::Sidekiq::ClientMiddleware

    def call(_, item, _, redis_pool, &)
      if item.key?("unique_for")
        Lock.new(item, redis_pool).acquire_or_discard(&)
      else
        yield
      end
    end
  end
end
