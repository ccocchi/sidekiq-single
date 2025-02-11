module Sidekiq::Single
  class ServerMiddleware
    include ::Sidekiq::ServerMiddleware

    def call(_, item, _, &)
      if item.key?(Lock::DIGEST_KEY)
        Lock.new(item).perform_and_release(&)
      else
        yield
      end
    end
  end
end
