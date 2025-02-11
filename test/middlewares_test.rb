# frozen_string_literal: true

require "test_helper"

module Sidekiq::Single
  class MiddlewaresTest < Minitest::Test
    include Pooling
    include DefaultItem

    def test_client_middleware_acquiring_lock
      client = ClientMiddleware.new
      res = client.call(nil, @item, "queue", @@pool) { "return_value" }

      assert_equal "return_value", res
      assert_item_locked
    end

    def test_client_middleware_failing_to_acquire_lock
      client = ClientMiddleware.new

      res = with_item_locked do
        client.call(nil, @item, "queue", @@pool) { "return_value" }
      end

      assert_nil res
      assert_item_locked
    end

    def test_client_middleware_only_yielding
      @item.delete("unique_for")

      client = ClientMiddleware.new
      res = client.call(nil, @item, "queue", @@pool) { "return_value" }

      assert_equal "return_value", res
      assert_redis_calls_count 0
    end

    def test_server_middleware_releasing_lock
      server = ServerMiddleware.new
      res = server.call(nil, @item, "queue") { "return_value" }

      assert_equal "return_value", res
      refute_item_locked
    end

    def test_server_middleware_only_yielding
      @item.delete("unique_for")

      server = ServerMiddleware.new
      res = server.call(nil, @item, "queue") { "return_value" }

      assert_equal "return_value", res
      assert_redis_calls_count 0
    end
  end
end
