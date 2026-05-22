require_relative 'boot'

require 'rails'
require 'active_support/railtie'

Bundler.require(*Rails.groups)

module InternetTimeBot
  class Application < Rails::Application
    config.load_defaults 7.1
   
    # No web server, no activerecord, no mailer, no cable
    config.eager_load = (ENV['RAILS_ENV'] == 'production')


    # Autoload app/services
    config.autoload_paths += [Rails.root.join('app', 'services')]
  end
end

