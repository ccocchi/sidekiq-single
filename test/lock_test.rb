# frozen_string_literal: true

require "test_helper"
require "connection_pool"

module Sidekiq::Single
  class LockTest < Minitest::Test
    @@pool = Sidekiq.redis_pool

    JID = "efe8cddac6a9b1b5a8ca006f"

    def setup
      @item = { "jid" => JID, "unique_for" => 5, "args" => ["id", 1234] }
      @lock = Lock.new(@item, @@pool)
      @digest = "880f8927d939cbfb77797b055dadaf1d18abe5a8c7514e2cfcf79c2581924979"
    end

    def teardown
      @@pool.with { |conn| conn.call("FLUSHDB") }
    end

    private def with_lock(value: JID)
      @item["digest"] = @digest
      @@pool.with { |conn| conn.call("SET", @digest, value) }

      yield
    end

    private def assert_locked
      assert_equal 1, @@pool.with { |conn| conn.call("EXISTS", @digest) }
    end

    private def refute_locked
      assert_equal 0, @@pool.with { |conn| conn.call("EXISTS", @digest) }
    end

    def test_acquiring_lock
      res = @lock.acquire_or_discard { true }

      assert res
      assert_equal @digest, @item["digest"]
      assert_equal JID, @@pool.with { |conn| conn.call("GET", @digest) }
    end

    def test_failing_to_acquire
      @@pool.with { |conn| conn.call("SET", @digest, JID) }

      res = @lock.acquire_or_discard { true }

      assert_nil res
    end

    def test_acquiring_lock_with_custom_args_method
      @item["unique_args"] = ->(args) { args.reverse }
      digest = "79bdcbab15c785bcaed3d5de5f97a6d97283ad4b0d70bb08ef5e079459521c9d"

      res = @lock.acquire_or_discard { true }

      assert res
      assert_equal digest, @item["digest"]
      assert_equal JID, @@pool.with { |conn| conn.call("GET", digest) }
    end

    def test_acquiring_lock_with_wrapped_item
      @item["wrapped"] = "SomeClass"
      @item["args"] = [{ "arguments" => @item.delete("args")}]

      res = @lock.acquire_or_discard { true }

      assert res
      assert_equal @digest, @item["digest"]
      assert_equal JID, @@pool.with { |conn| conn.call("GET", @digest) }
    end

    def test_is_fastened
      refute @lock.fastened?

      @@pool.with { |conn| conn.call("SET", @digest, JID) }
      assert @lock.fastened?
    end

    def test_releasing_lock
      res = with_lock { @lock.release }

      assert_equal 1, res
      refute_locked
    end

    def test_releasing_old_lock
      res = with_lock(value: "another_JID") { @lock.release }

      assert_equal 0, res
      assert_locked
    end

    def test_performing_job_and_releasing_lock
      res = with_lock do
        @lock.perform_and_release { "return_value" }
      end

      assert_equal "return_value", res
      refute_locked
    end

    def test_raising_during_perform_does_not_release_lock
      err = Class.new(StandardError)

      begin
        with_lock do
          @lock.perform_and_release { raise err }
        end
      rescue err => _
        assert_locked
      end
    end

    def test_reaping
      res = with_lock { Reaper.new.call(@item) }

      assert_equal 1, res
      refute_locked
    end

    def test_reaping_a_non_unique_job
      res = Reaper.new.call(@item)
      assert_nil res
    end
  end
end
