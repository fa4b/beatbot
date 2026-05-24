require 'date'

# Calculates the current Swatch Internet Time (BMT) locally.
#     fa4b - 2026-05-24
# I changed method so I can have decimal precision for the !beat command, and also provide a full data hash for the !worldtime command without needing to make multiple calls or calculations.
# I thought the API could give decimal precision but it seems to be an integer, so I implemented the decimal calculation locally based on the current time in BMT. 
# This way we can have more accurate beat times for the !beat command while still providing the full data for !worldtime without extra overhead.
# No external API call — derived from UTC+1 (Biel Mean Time).
#
# fetch_short  → beat string without decimals, e.g. "@583"       (used for bot presence)
# fetch        → beat string with decimals, e.g. "@583.42"       (used for !beat command)
# fetch_full   → { beat: "@583.42", date: "2026-05-24" }         (used for !worldtime command)

class BeatFetcher
  DECIMALS = 2 # Decimal precision for commands (0 = integer, 2 = BBB.DD, 4 = BBB.DDDD)

  def self.fetch
    new.fetch
  end

  def self.fetch_short
    new.fetch_short
  end

  def self.fetch_full
    new.fetch_full
  end

  def fetch
    format_beat(calculate_beats, decimals: DECIMALS)
  end

  def fetch_short
    format_beat(calculate_beats, decimals: 0)
  end

  def fetch_full
    now_bmt = bmt_now
    beats   = calculate_beats(now_bmt)
    {
      beat: format_beat(beats, decimals: DECIMALS),
      date: now_bmt.strftime('%Y-%m-%d')
    }
  end

  private

  def bmt_now
    Time.now.utc + 3600
  end

  def calculate_beats(now = bmt_now)
    total_seconds = now.hour * 3600 +
                    now.min  * 60   +
                    now.sec         +
                    now.subsec.to_f
    total_seconds / 86.4
  end

  def format_beat(beats, decimals: 2)
    if decimals > 0
      "@#{format("%0#{3 + 1 + decimals}.#{decimals}f", beats)}"
    else
      "@#{format('%03d', beats.floor)}"
    end
  end
end