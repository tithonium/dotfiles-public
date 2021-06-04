#!/usr/bin/env ruby

ENV['LANG'] = 'en_US.UTF-8'

require 'time'

dark_mode = system('~/bin/is-dark-mode')
grey, black = dark_mode ? ['666666', 'ffffff'] : ['888888', '000000']

window_start = Time.now
soon_end = window_start + (15 * 60)
window_end = window_start + (15 * 60 * 60)

cmd = %Q[/usr/local/bin/icalBuddy -ec 'Contacts,Birthdays' -nc -eep notes,attendees,location,url -b '~~~~~' eventsFrom:#{window_start.to_s.inspect} to:#{window_end.to_s.inspect}]
# puts cmd
events = `#{cmd} 2>/dev/null`.force_encoding(Encoding::UTF_8).tr(%q[’], %q[']).split('~~~~~').reject(&:empty?)
# puts events.inspect
events = events.map{|l| l.split(/\n/)}.reject{|l| l.length < 2}
# puts events.inspect
events = events.each_with_object({}) do |ev, h|
  name = ev.first.strip.gsub('|', ':')
  time = ev.last.strip
  next unless time.include?(' at ')
  day, start_time = time.match(/(\S+) at (\d\d:\d\d)/)[1..2]
  time = Time.parse(start_time)
  time += 86400 if day == 'tomorrow'
  next if h[name]
  h[name] = time
end
# puts events.inspect

cmd = %Q[/usr/local/bin/icalBuddy -ec 'Contacts,Birthdays' -nc -eep attendees -b '~~~~~' eventsFrom:#{window_start.to_s.inspect} to:#{window_end.to_s.inspect}]
# puts cmd
event_urls = `#{cmd} 2>/dev/null`.force_encoding(Encoding::UTF_8).tr(%q[’], %q[']).split('~~~~~').reject(&:empty?)
# puts event_urls.inspect
event_urls = event_urls.each_with_object({}) do |event, h|
  title, details = event.split(/ *\n */, 2)
  title = title.strip.gsub('|', ':')

  urls = details.scan(%r{(https?://[^ \t"']+)}).flatten.map do |url|
    url.chomp! ; url.sub!(/\A</, '') ; url.sub!(/>\Z/, '')
    if url.include?('urldefense.proofpoint.com')
      url = url[%r{/url\?u=([^&]+)}, 1].gsub(/-([0-9A-F]{2})/){$1.hex.chr}.gsub('_', '/')
    end
    url
  end
  # STDERR.puts urls.inspect
  # STDERR.puts urls.grep(/meet.goo|webex/).inspect
  if urls.length > 0
    h[title] = urls.grep(/meet.goo|webex|zoom/).first || urls.first
  end
end
# puts event_urls.inspect

now_events, future_events = events.partition {|(_, v)| v <= soon_end }
# puts [now_events, future_events].inspect

if now_events.empty?
  puts "–🗓 | color=##{grey}"
else
  now_events.each do |event, time|
    time_til = time - window_start
    # puts [time, window_start, time_til].inspect
    icon = if time_til <= 30
      '🗓'
    elsif time_til < 5 * 60
      '🕚'
    elsif time_til < 10 * 60
      '🕙'
    else
      '🕘'
    end
    puts "#{event} #{icon} | color=##{black}"
  end
end

unless future_events.empty? && (now_events.map(&:first) & event_urls.keys).empty?
  puts "---"
  now_events.each do |event, time|
    next unless event_urls[event]
    time_til = time - window_start
    # puts [time, window_start, time_til].inspect
    icon = if time_til <= 30
      '🗓'
    elsif time_til < 5 * 60
      '🕚'
    elsif time_til < 10 * 60
      '🕙'
    else
      '🕘'
    end
    puts "#{event} #{icon} | color=##{black} href=#{event_urls[event]}"
  end
  future_events.each do |event, time|
    time_til = (time - window_start).to_i / (60 * 5) * 5
    time_til = if time_til > 60
      "%dh%dm" % time_til.divmod(60)
    else
      "#{time_til}min"
    end
    href = event_urls[event] ? "href=#{event_urls[event]}" : nil
    puts "#{event} @ #{time.strftime('%k:%M')} (~#{time_til}) | color=##{black} #{href}"
  end
end
puts "---"
puts "Refresh... | refresh=true"
