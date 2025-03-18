# frozen_string_literal: true

require "digest"

module Sidekiq::Single
  class Lock
    DIGEST_KEY = "digest"

    attr_reader :item

    def initialize(item, pool = nil)
      @item = item
      @pool = pool || ::Sidekiq.redis_pool
    end

    def fastened?
      args   = item["args"]
      method = item["unique_args"]
      args   = Array(method.call(args)) if method
      digest = digest(args)

      @pool.with { |conn| conn.call("EXISTS", digest) } > 0
    end

    # Tries to acquire the lock. In case of success, executes the given block
    # otherwise calls the `handle_conflict` method which by default does
    # nothing.
    #
    def acquire_or_discard
      args    = item.key?("wrapped") ? item.dig("args", 0, "arguments") : item["args"]
      method  = item.delete("unique_args")
      args    = Array(method.call(args)) if method
      digest  = item[DIGEST_KEY] = digest(args)
      ttl     = calculate_ttl

      if @pool.with { |conn| conn.call("SET", digest, item["jid"], "NX", "EX", ttl) }
        yield
      else
        handle_conflict
      end
    end

    # Executes the given block and releases the lock.
    #
    # Lock is not release when underlying block raises, to ensure retries
    # are still done with the item locked. When all retries fail, or when
    # there's no retry at all, the lock is released by the `Reaper` added
    # as a death handler to Sidekiq.
    #
    # @return [Object] the given block's return value
    #
    def perform_and_release
      res = yield
      release
      res
    end

    # Releases the lock only if its value matches our job's id, to ensure
    # we're not releasing another job's lock.
    #
    def release
      @pool.with { |conn| conn.call("FCALL", "single_release_lock", 1, item["digest"], item["jid"]) }
    end

    private

    def digest(ary)
      sha256 = Digest::SHA256.new
      sha256 << item["class"]
      ary.each { |e| sha256 << e.to_s }
      sha256.hexdigest
    end

    def calculate_ttl
      ttl = item["unique_for"]
      if (at = item["at"])
        ttl = (ttl + (at - Time.now.to_f)).ceil
      end
      ttl
    end

    def handle_conflict # noop
    end
  end
end
