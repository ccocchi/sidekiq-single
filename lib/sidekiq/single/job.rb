# frozen_string_literal: true

module Sidekiq::Single
  module Job
    def self.included(job)
      job.extend(ClassMethods)
    end

    module ClassMethods
      def single_options(opts)
        opts = opts.transform_keys(&:to_s)
        opts["unique_for"] = opts["unique_for"]&.to_i

        raise InvalidConfiguration if opts["unique_for"].nil?

        sidekiq_options(opts)
      end

      def performing?(*args)
        meth = get_sidekiq_options["unique_args"]
        item = { "args" => args, "unique_args" => meth, "class" => name }

        Lock.new(item).fastened?
      end
    end
  end
end
