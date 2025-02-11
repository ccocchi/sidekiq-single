module Sidekiq::Single
  module DefaultItem
    JID = "efe8cddac6a9b1b5a8ca006f"

    def setup
      super

      @item = { "jid" => JID, "unique_for" => 5, "args" => ["id", 1234] }
      @digest = "880f8927d939cbfb77797b055dadaf1d18abe5a8c7514e2cfcf79c2581924979"
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
