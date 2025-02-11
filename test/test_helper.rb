require "sidekiq"
require "sidekiq/single"
require "minitest/autorun"

Sidekiq.configure_client do |config|
  config.logger = nil
end
