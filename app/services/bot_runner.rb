require 'discordrb'
require 'discordrb/commands/command_bot'

# Start the Discord Bot with prefix commands and a background thread that polls the beat.
# Updates the bot's presence every BEAT_UPDATE_INTERVAL seconds.
#
# Commands available to users:
# !beat      - Get the current Swatch Internet Time (BMT) beat with decimals (BBB.DD).
# !time      - Local time + timezone of the host machine.
# !worldtime - Beat + local time + UTC as an embed message.

class BotRunner
  ACTIVITY_TYPE    = 3
  COMMAND_COOLDOWN = 2

  def initialize
    @token = ENV.fetch('DISCORD_TOKEN', nil)
    raise "DISCORD_TOKEN environment variable is not set or is empty" if @token.nil? || @token.strip.empty?

    @prefix          = ENV.fetch('DISCORD_PREFIX', '!')
    @interval        = ENV.fetch('BEAT_UPDATE_INTERVAL', 60).to_i
    @user_cooldowns  = {}
    @polling_thread  = nil

    begin
      @bot = Discordrb::Commands::CommandBot.new(
        token:   @token,
        prefix:  @prefix,
        intents: %i[servers server_messages]
      )
    rescue Discordrb::Errors::InvalidToken => e
      raise "Invalid DISCORD_TOKEN: #{e.message}"
    rescue StandardError => e
      raise "Failed to initialize Discord bot: #{e.message}"
    end
  end

  def run
    register_ready_handler
    register_commands
    setup_shutdown_handler
    @bot.run
  end

  private

  def register_ready_handler
    @bot.ready do
      Rails.logger.info("[BotRunner] Connected as #{@bot.profile.username}")
      start_polling_thread
    end
  end

  def start_polling_thread
    @polling_thread = Thread.new do
      Rails.logger.info('[BotRunner] Starting beat polling thread')
      loop do
        begin
          update_presence(BeatFetcher.fetch_short)
        rescue StandardError => e
          Rails.logger.error("[BotRunner] Error in polling thread: #{e.class} - #{e.message}")
          Rails.logger.debug(e.backtrace.join("\n")) if Rails.logger.debug?
        end
        sleep @interval
      end
    rescue StandardError => e
      Rails.logger.fatal("[BotRunner] FATAL: Polling thread crashed: #{e.class} - #{e.message}")
      Rails.logger.debug(e.backtrace.join("\n")) if Rails.logger.debug?
    end
  end

  def setup_shutdown_handler
    trap('TERM') { shutdown_gracefully }
    trap('INT')  { shutdown_gracefully }
  end

  def shutdown_gracefully
    Rails.logger.info('[BotRunner] Shutdown signal received, stopping bot gracefully...')
    @bot.stop
  end

  def update_presence(beat)
    unless beat
      Rails.logger.warn('[BotRunner] Beat calculation returned nil - skipping update')
      return
    end

    @bot.update_status('online', beat, nil, 0, false, ACTIVITY_TYPE)
    Rails.logger.info("[BotRunner] Updated presence to: #{beat}")
  rescue StandardError => e
    Rails.logger.error("[BotRunner] Failed to update presence: #{e.class} - #{e.message}")
  end

  def register_commands
    register_beat_command
    register_time_command
    register_worldtime_command
  end

  def register_beat_command
    @bot.command(:beat, description: 'Current Swatch Internet Beat time (BMT)') do |event|
      unless valid_event?(event)
        event.respond("Error: Unable to process command")
        next
      end

      if rate_limited?(event.author.id)
        event.respond("Please wait before using this command again.")
        next
      end

      beat = BeatFetcher.fetch
      if beat
        event.respond("Current beat: #{beat}")
      else
        event.respond("Sorry, I couldn't calculate the current beat.")
      end
    end
  end

  def register_time_command
    @bot.command(:time, description: 'Local time and timezone of the bot host.') do |event|
      unless valid_event?(event)
        event.respond("Error: Unable to process command")
        next
      end

      if rate_limited?(event.author.id)
        event.respond("Please wait before using this command again.")
        next
      end

      now      = Time.now
      timezone = now.zone || 'Unknown'
      event.respond("Local time: **#{now.strftime('%Y-%m-%d %H:%M:%S')}** (#{timezone})")
    end
  end

  def register_worldtime_command
    @bot.command(:worldtime, description: 'Current beat, local time, and UTC as an embed message.') do |event|
      unless valid_event?(event)
        event.respond("Error: Unable to process command")
        next
      end

      if rate_limited?(event.author.id)
        event.respond("Please wait before using this command again.")
        next
      end

      data     = BeatFetcher.fetch_full
      now      = Time.now
      utc      = Time.now.utc
      timezone = now.zone || 'Unknown'

      embed       = Discordrb::Webhooks::Embed.new
      embed.title = 'World Time'
      embed.color = 0x5865F2

      if data
        embed.add_field(name: 'Internet Beat', value: "**#{data[:beat]}**", inline: true)
        embed.add_field(name: 'Date (BMT)',     value: data[:date],          inline: true)
      else
        embed.add_field(name: 'Internet Beat', value: 'Unavailable', inline: true)
      end

      embed.add_field(name: "\u200B", value: "\u200B", inline: false)

      embed.add_field(name: 'Local Time', value: "#{now.strftime('%H:%M:%S')} (#{timezone})", inline: true)
      embed.add_field(name: 'UTC',        value: utc.strftime('%H:%M:%S'),                    inline: true)

      embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: '1 beat = 86.4 seconds — no time zones')

      event.respond('', nil, embed)
    end
  end

  def valid_event?(event)
    event&.author&.id.present?
  end

  def rate_limited?(user_id)
    current_time = Time.now.to_i
    last_used    = @user_cooldowns[user_id]

    if last_used.nil? || (current_time - last_used) >= COMMAND_COOLDOWN
      @user_cooldowns[user_id] = current_time
      return false
    end

    true
  end
end