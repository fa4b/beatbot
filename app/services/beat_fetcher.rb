require 'faraday'
require 'json'
require 'zlib'

# Fetches the current Swatch Internet Time (BMT) from the public API with retry logic.
# Implements exponential backoff for rate-limit handling (429, 503).
# Returns the beat string (e.g. "@ 583") or an error message if the API call fails.

class BeatFetcher
  API_URL = 'https://aisenseapi.com/services/v1/swatchinternettime'.freeze
  MAX_RETRIES = 3
  INITIAL_BACKOFF = 1
  MAX_BACKOFF = 16

  def initialize
    @connection = nil
  end

  def self.fetch
    new.fetch
  end

  def self.fetch_full
    new.fetch_full
  end

  def fetch
    result = fetch_full
    result&.fetch(:beat)
  end

  def fetch_full
    attempt = 0
    backoff = INITIAL_BACKOFF

    loop do
      attempt += 1
      response = connection.get(API_URL)

      if response.success?
        body = response.body.dup.force_encoding('BINARY')
        body = decompress_if_gzipped(body)
        body = body.strip
        Rails.logger.info("[BeatFetcher] Response body: #{body.inspect}")
        data = JSON.parse(body)
        return validate_and_extract(data)
      elsif response.status == 429 || response.status == 503
        if attempt < MAX_RETRIES
          Rails.logger.warn("[BeatFetcher] Rate limited (status #{response.status}). Retrying in #{backoff}s (attempt #{attempt}/#{MAX_RETRIES})")
          sleep backoff
          backoff = [backoff * 2, MAX_BACKOFF].min
          next
        else
          Rails.logger.error("[BeatFetcher] Rate limited and max retries exceeded")
          return nil
        end
      else
        Rails.logger.error("[BeatFetcher] API call failed with status #{response.status}")
        return nil
      end
    end
  rescue JSON::ParserError => e
    Rails.logger.error("[BeatFetcher] JSON parse error: #{e.message}")
    nil
  rescue StandardError => e
    Rails.logger.error("[BeatFetcher] Exception: #{e.class} - #{e.message}")
    nil
  end

  private

  def validate_and_extract(data)
    unless data.is_a?(Hash)
      Rails.logger.error("[BeatFetcher] Invalid API response: expected Hash, got #{data.class}")
      return nil
    end

    beat = data['beat']
    date = data['date']

    if beat.nil? || date.nil?
      Rails.logger.error("[BeatFetcher] Missing required fields in API response: beat=#{beat.inspect}, date=#{date.inspect}")
      return nil
    end

    { beat: beat, date: date }
  end

  def connection
    @connection ||= build_connection
  end

  def build_connection
    Faraday.new do |f|
      f.options.timeout = 10
      f.options.open_timeout = 5
      f.headers['User-Agent'] = 'InternetTimeBot/1.0'
      f.headers['Accept'] = 'application/json'
      f.headers['Accept-Encoding'] = 'identity'
    end
  end

  def decompress_if_gzipped(body)
    if body.start_with?("\x1F\x8B".force_encoding('BINARY'))
      Zlib::GzipReader.new(StringIO.new(body)).read.encode('UTF-8', invalid: :replace, undef: :replace)
    else
      body.encode('UTF-8', invalid: :replace, undef: :replace)
    end
  end
end