#!/usr/bin/ruby

require 'shellwords'

dark_mode = system('~/bin/is-dark-mode')

this_host = `hostname -s`.chomp
$refresh_cmd = " && bitbar-refresh #{File.basename(__FILE__)} && exit"

unless `grep nameserver /etc/resolv.conf 2>&1` =~ /\S/
  puts "🚫"
  puts "---"
  puts "Not connected. Try again? | refresh=true"
  exit
end

hosts = [nil, 'host1', 'host2']

def bbbash(cmd)
  cmd = cmd.split
  cmd << $refresh_cmd
  cmd.each_with_index.map{|a,i|
    "param%d=\"%s\"" % [i, a]
  }.join(' ').sub(/param0=/,'bash=')
end

results = hosts.map do |accessor|
  hostname = (accessor || this_host).capitalize
  cmd = [
    '/opt/homebrew/bin/brew update > /dev/null 2>&1',
    '/opt/homebrew/bin/brew list --pinned',
    'echo ---',
    '/opt/homebrew/bin/brew outdated --verbose',
  ].join(' && ')
  cmd = "/Users/martian/bin/machines/#{accessor} #{Shellwords.escape(cmd)} 2>/dev/null" if accessor
  output = `#{cmd}`
  success = $?.success?
  [
    accessor,
    hostname,
    if success
      pinned, outdated = output.split(/(?:\r?\n)?---\r?\n/).map{|s| s.split(/\r?\n/) }
      pinned ||= [] ; outdated ||= []
      outdated.delete_if{|row| pinned.include? row.split(/\s+/,2)[0] }
      outdated
    else
      []
    end,
    success ? :success : :error
  ]
end

if results.map(&:last).uniq == [:error]
  puts "↑‼️ | color=red"
  puts "---"
end

total_count = results.select{|r| r.last == :success}.inject(0){|s,(a,h,o,v)| s + o.size }

if total_count > 0
  puts "↑ #{results.map{|x|x[2].size}.join("+")} | dropdown=false"
  puts "---"
  if hosts.count > 1
    puts %Q[Upgrade all | color=#444444 size=16 #{bbbash("on-all-macs brew-upclean")}]
  end
  results.each do |accessor, hostname, list, state|
    # next if state == :error || list == []
    if hosts.count > 1
      puts "---"
      cmd = bbbash([accessor, 'brew-upclean'].compact.join(' '))
      puts %Q[#{hostname} | color=##{dark_mode ? '5555ff' : '000088'} size=15 #{cmd}]
    else
      cmd = bbbash('brew-upclean')
      puts %Q[Upgrade all | color=##{dark_mode ? '5555ff' : '000088'} size=15 #{cmd}]
    end
    list.each do |row|
      app, _ = row.split(/\s+/, 2)
      cmd = bbbash([accessor, "brew upgrade #{app}"].compact.join(' '))
      # cmd = "/opt/homebrew/bin/brew upgrade #{app}"
      puts %Q[#{row} | color=#888888 #{cmd}]
    end
  end
else
  puts "⭕️ | dropdown=false"
end

puts "---"
puts "Refresh... | refresh=true"
