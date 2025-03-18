# frozen_string_literal: true

module Sidekiq::Single
  module DefaultItem
    JID = "efe8cddac6a9b1b5a8ca006f"

    def setup
      super

      @item = { "jid" => JID, "unique_for" => 5, "args" => ["id", 1234], "class" => "SomeJob" }
      @digest = "d2f3fafe495e984694afeb3d08407620320ff285d24158867f730fa2228146bd"
    end

    private def with_item_locked(value: JID)
      @item["digest"] = @digest
      pool.with { |conn| conn.call("SET", @digest, value) }

      yield
    end

    private def assert_item_locked
      assert_equal 1, pool.with { |conn| conn.call("EXISTS", @digest) }, "item is not locked"
    end

    private def refute_item_locked
      assert_equal 0, pool.with { |conn| conn.call("EXISTS", @digest) }, "item is locked"
    end
  end
end
