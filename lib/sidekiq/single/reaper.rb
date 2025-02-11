module Sidekiq::Single
  class Reaper
    def call(item, *)
      if item.key?(Lock::DIGEST_KEY)
        Lock.new(item).release
      end
    end
  end
end
