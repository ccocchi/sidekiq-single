require "connection_pool"

module Sidekiq::Single
  module Pooling
    class ObservablePool
      attr_reader :calls_count

      def initialize(pool)
        @calls_count = 0
        @pool = pool
      end

      def with(&)
        @calls_count += 1
        @pool.with(&)
      end

      def reset
        @calls_count = 0
        @pool.with { |conn| conn.call("FLUSHDB") }
      end
    end

    @@pool = ObservablePool.new(ConnectionPool.new(size: 1) { RedisClient.new })

    def teardown
      super
      @@pool.reset
    end

    private def pool
      @@pool
    end

    private def assert_redis_calls_count(expected)
      assert_equal expected, @@pool.calls_count, "number of redis calls mismatch"
    end
  end
end
