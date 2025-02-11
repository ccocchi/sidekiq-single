# frozen_string_literal: true

require_relative "lib/sidekiq/single/version"

Gem::Specification.new do |spec|
  spec.name          = "sidekiq-single"
  spec.version       = Sidekiq::Single::VERSION
  spec.authors       = ["ccocchi"]
  spec.email         = ["cocchi.c@gmail.com"]

  spec.summary       = "Simple unique jobs for Sidekiq and single Redis instance"
  spec.homepage      = "https://www.github.com/ccocchi/sidekiq-single"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"]          = spec.homepage
  spec.metadata["source_code_uri"]       = "#{spec.homepage}/tree/v#{spec.version}"
  spec.metadata["bug_tracker_uri"]       = "#{spec.homepage}/issues"
  spec.metadata["changelog_uri"]         = "#{spec.homepage}/blob/v#{spec.version}/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.start_with?("test/") }
  end

  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 3.3.1"

  spec.add_development_dependency "bundler", "~> 2.5.6"
  spec.add_development_dependency "rake", "~> 13.2"
  spec.add_development_dependency "minitest", ">= 5", "< 6"

  spec.add_dependency "sidekiq", ">= 7", "< 8"
end
