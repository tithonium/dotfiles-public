#!/usr/bin/env ruby

require 'tzinfo'
require 'date'

def hms(s)
  times = [
    [s.abs / 3600, :h],
    [(s.abs % 3600) / 60, :m],
    [s.abs % 60, :s]
  ]
  times.shift while times.length > 0 && times[0][0] == 0
  times.pop while times.length > 0 && times[-1][0] == 0
  return '±0' if times.length == 0
  times.unshift(s > 0 ? '+' : '-')
  times.flatten.join
end

base_timezone = 'America/Los_Angeles'
timezones = [
  # 'America/New_York',
  # 'Etc/GMT+12','Pacific/Tongatapu','Pacific/Midway',
  # 'America/Los_Angeles',
  'UTC',
]

base_tz = TZInfo::Timezone.get(base_timezone)
base_offset = base_tz.observed_utc_offset
timezones.each do |tzname|
  tz = TZInfo::Timezone.get(tzname)
  tzabbr = tz.period_for_utc(Time.now).abbreviation.to_s
  now = tz.now.to_datetime
  offset = tz.observed_utc_offset - base_offset
  puts "%3.3s %5.5s (%s)" % [tzabbr, now.strftime('%H:%M'), hms(offset)]
end
