require_relative "single/version"
require_relative "single/job"
require_relative "single/lock"
require_relative "single/middleware/client"
require_relative "single/middleware/server"
require_relative "single/reaper"

module Sidekiq
  module Single
    class InvalidConfiguration < StandardError; end

    def add_function_to_redis(conn)
      fn = File.read(File.expand_path("../single/lua/lock.lua", __FILE__))
      conn.call("FUNCTION LOAD REPLACE", fn)
    end
  end
end
