namespace :bot do
  desc 'Start the Internet Time Discord bot'
  task start: :environment do
    Rails.logger.info('[bot:start] Booting Internet Time Bot...')
    BotRunner.new.run
  end
end


