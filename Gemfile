source "https://rubygems.org"

gem "rails", "~> 8.0.2"
gem "sqlite3", ">= 2.1"
gem "puma", ">= 5.0"

gem "ferrum"
gem "ferrum_pdf"

gem "vite_rails"

gem "rswag-api"
gem "rswag-ui"

gem "alba"

gem "aws-sdk-s3", require: false

gem "solid_queue"

gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  gem "rubocop"
  gem "rubocop-rails-omakase", require: false

  gem "rswag-specs"
  gem "rspec-rails"

  gem "shoulda-matchers"

  gem "factory_bot_rails"
  gem "faker"
end
