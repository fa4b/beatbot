ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup'

require 'dotenv/load' if File.exist?(File.expand_path('../.env', __dir__))