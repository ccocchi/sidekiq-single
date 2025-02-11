require "sidekiq"
require "sidekiq/single"
require "minitest/autorun"

require_relative "./support/default_item"
require_relative "./support/pooling"

Sidekiq.configure_client do |config|
  config.logger = nil
end
