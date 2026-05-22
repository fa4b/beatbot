# Beatbot — Swatch Internet Time

  
## Origin of Swatch Internet Time
  
Decimal time has a long history from Ancient Egypt until today. Check wikipedia for more information: https://en.wikipedia.org/wiki/Decimal_time

### French Revolution

Decimal time was officially introduced during the French Revolution. Jean-Charles de Borda made a proposal for decimal time on 5 November 1792. The National Convention issued a decree on 5 October 1793, to which the underlined words were added on 24 November 1793 (4 Frimaire of the Year II):

> VIII. Each month is divided into three equal parts, of ten days each, which are called décades...
> 
> XI. The day, from midnight to midnight, is divided into ten parts __or hours__, each part into ten others, so on until the smallest measurable portion of the duration. __The hundredth part of the hour is called decimal minute; the hundredth part of the minute is called decimal second.__ [...]
> 
> Thus, midnight was called *dix heures* ("ten hours"), noon was called *cinq heures* ("five hours"), etc.

### Swatch Internet Time 

Swatch Internet Time was introduced in 1998 by the Swiss company Swatch.

It was designed as an attempt to standardize time globally for the Internet era.
Instead of relying on traditional time zones, it proposes a single global time reference based on a fixed meridian:

- Biel (Bienne), Switzerland
- CET (UTC+1 reference, without sub-zone distinctions)

The goal was to remove the fragmentation caused by time zones in digital communication.

## Core principle

The day is divided into 1000 equal units called **beats**:

- 1 day = 1000 beats
- 1 beat = 1/1000 of a day
- 1 beat ≈ 86.4 seconds
- notation ranges from `@000` to `@999`

Examples:

- `@000` = midnight in Biel
- `@500` = midpoint of the day
- `@999` = end of the day

## Purpose and interest

Swatch Internet Time was not intended to replace civil time systems, but to provide a unified reference for:

- international coordination over the Internet
- eliminating time zone conversions in communication
- simplifying synchronous digital interactions

Its adoption remained limited, but it is still referenced in experimental and conceptual computing contexts.

## Commands 

List of commands available to users as of today 2026-05-22: 

- `!beat` — Get the current Swatch Internet Time (BMT) beat.
- `!time` — Local time + timezone of the host machine.
- `!worldtime` — Beat + local time + UTC as an embed message.


## Role of this bot

This bot implements Swatch Internet Time API and calculation:

- provide a time representation independent of local time zones
- experiment with a universal time format in Discord environments
- offer a compact notation for fast communication (`@XXX` format)
- the project is based on https://github.com/iijj22gg/Internet-Time-Display with the addition of an API giving the beat time with calculations in case of an issue
- https://aisense.no/free-public-api-swatchinternettime-api-endpoint
- https://github.com/ERnsTL/awesome-internettime (more tools linked to Swatch Internet Time)
  
## Calculation

The computation is based on UTC time converted to CET reference:

```
beats = floor((hours * 3600 + minutes * 60 + seconds) / 86.4)
```

