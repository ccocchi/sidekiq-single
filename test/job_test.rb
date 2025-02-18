# frozen_string_literal: true

require "test_helper"

module Sidekiq::Single
  class JobTest < Minitest::Test
    include Pooling

    class DummyJob
      include Sidekiq::Job
      include Sidekiq::Single::Job
    end

    def test_settings_options
      minutes = Class.new do
        def to_i
          10
        end
      end

      meth = ->(args) { args }
      DummyJob.single_options unique_for: minutes.new, unique_args: meth

      opts = DummyJob.get_sidekiq_options

      assert_equal 10, opts["unique_for"]
      assert_equal meth, opts["unique_args"]
    end

    def test_options_validation
      assert_raises(InvalidConfiguration) do
        DummyJob.single_options unique_for: nil
      end
    end

    def test_is_performing
      DummyJob.single_options unique_for: 10, unique_args: Proc.new(&:itself)
      digest = "880f8927d939cbfb77797b055dadaf1d18abe5a8c7514e2cfcf79c2581924979"

      refute DummyJob.performing?("id", 1234)

      @@pool.with { |conn| conn.call("SET", digest, "foo") }
      assert DummyJob.performing?("id", 1234)
    end
  end
end
