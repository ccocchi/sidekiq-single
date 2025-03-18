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
  end
end
