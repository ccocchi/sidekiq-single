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

    def acquire_or_discard
      args    = item.key?("wrapped") ? item.dig("args", 0, "arguments") : item["args"]
      method  = item.delete("unique_args")
      ttl     = item["unique_for"]
      args    = Array(method.call(args)) if method
      digest  = item[DIGEST_KEY] = digest(args)

      if @pool.with { |conn| conn.call("SET", digest, item["jid"], "NX", "EX", ttl) }
        yield
      else
        handle_conflict
      end
    end

    def perform_and_release
      res = yield
      release
      res
    end

    def release
      @pool.with { |conn| conn.call("FCALL", "single_release_lock", 1, item["digest"], item["jid"]) }
    end

    private

    def digest(ary)
      sha256 = Digest::SHA256.new
      ary.each { |e| sha256 << e.to_s }
      sha256.hexdigest
    end

    def handle_conflict # noop
    end
  end
end
