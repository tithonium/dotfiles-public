#!/usr/bin/env ruby

# <bitbar.title>TravisCI Check</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>Martin Tithonium</bitbar.author>
# <bitbar.author.github>tithonium</bitbar.author.github>
# <bitbar.desc>This plugin displays the build status of repositories listed on TravisCI.</bitbar.desc>
# <bitbar.image>https://cloud.githubusercontent.com/assets/53064/12126193/a775fada-b3bd-11e5-9ae2-091c9c38b1da.png</bitbar.image>
# <bitbar.dependencies>ruby</bitbar.dependencies>

# Martin Tithonium
# github.com/tithonium
# Derived from a similar script by Chris Tomkins-Tinch (github.com/tomkinsc)

# version history
# 1.0
#   rewrite from python into ruby

# Dependencies:
#   travis API key

require 'json'
require 'uri'
require 'net/http'
require 'pathname'
require 'openssl'

# You need to set your TRAVIS_KEY to an API key for travis.
# -- Please note that this IS NOT the 'Token' listed on the Travis CI website
# -- Again, this is NOT the token on https://travis-ci.com/profile/your-name
# The easiest way to get this key is to use the official travis client
# (`gem install travis`), and run `travis token` or `travis token --pro`.
TRAVIS_KEY = 'XXXXXXXXXXXXXXXXXXXXXXXX'

# If you don't want to check all repos, then specify the ones you do wish to
# check here, and this plugin will only get the details of these repos.
# If you do not specify the `repos_to_check` option - it will fetch all repos
# available in your account.
# If you do not include the 'branches' key, then only the master branch
# will be checked.
repos_to_check = [
  { name: 'user/repo',                  branches: ['master'] },
  { name: 'user2/repo2',                branches: ['master'] },
]
WORKSPACE = Pathname.new(ENV['HOME']) + 'workspace'

# You may need to change the TRAVIS_URL if you're using travis enterprise or
# private travis. For private travis, change the .org to .com
TRAVIS_URL = 'https://api.travis-ci.com/'

# ======================================

SYMBOLS = {
  passed: '✔︎',
  created: '⟳',
  failed: '✘',
  errored: '⚠',
  started: '⟳',
  cancelled: ' ⃠',
}
COLORS = {
  passed: :green,
  created: :orange,
  failed: :red,
  errored: :orange,
  started: :orange,
  cancelled: :grey,
}
NO_SYMBOL = '❂'

def request(uri)
  uri = URI(TRAVIS_URL + uri)
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = 'token ' + TRAVIS_KEY
  req['Accept'] = 'application/vnd.travis-ci.3+json'
  res = Net::HTTP.start(uri.hostname, uri.port, {use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE}) do |http|
    http.request(req)
  end
  
  if res.is_a? Net::HTTPRedirection
    return request(res['location'].sub(TRAVIS_URL, ''))
  end
  JSON.load(res.body)
end

def get_all_repos_for_account
  url = 'repos?repository.active=true&sort_by=name&limit=200'
  repos = request(url)
  [].tap do |all_repos|
    repos['repositories'].compact.select{|r| r['slug']}.each do |repo|
      all_repos << { name: repo['slug'] }
    end
  end
end

def current_branch_in(repo)
  dir = WORKSPACE + repo
  dir = WORKSPACE + repo.sub(%r![^/]+/!, '') unless dir.exist?
  return nil unless dir.exist?
  branch = `cd #{dir} ; git status --porcelain -s -b | head -1 | ~/bin/delim -d='[ \.]+' -f=2`.chomp
  return nil if branch == 'working'
  branch
end

def local_branches_in(repo)
  dir = WORKSPACE + repo
  dir = WORKSPACE + repo.sub(%r![^/]+/!, '') unless dir.exist?
  return nil unless dir.exist?
  branches = `cd #{dir} ; git branch --list -vv`.split(/\n/).map do |line|
    m = line.match(/\A. (\S+) *\S+ \[(\S+)\]/)
    next unless m
    local, remote = m[1..2]
    remote.sub(/\Aorigin\//, '')
  end.compact.uniq - ['master']
end

def update_statuses(repos)
  output = []
  fail_count = 0

  output << "%s | color=green" % SYMBOLS[:passed]
  output << '---'

  repos.each do |repo|
    branch_list = repo[:branches] || ['master']
    # cb = current_branch_in(repo[:name])
    # branch_list |= [cb] if cb
    branch_list |= local_branches_in(repo[:name])
    branch_list.each do |branch_name|
      url = 'repo/' + URI.encode_www_form_component(repo[:name]) + '/builds?limit=1&branch.name=' + URI.encode_www_form_component(branch_name) + '&event_type=push'
      build = request(url)
      next if build['builds'].nil? || build['builds'].empty?
      build = build['builds'][0]
      color = COLORS[build['state'].to_sym] ? ('color=%s' % COLORS[build['state'].to_sym]) : ''
      symbol = SYMBOLS[build['state'].to_sym] or NO_SYMBOL
      href = 'href=https://travis-ci.com/%s/builds/%s' % [repo[:name], build['id']]
      output_msg = '%s %s (%s) %s' % [symbol, repo[:name], branch_name, build['state']]
      output << '%s | %s %s' % [output_msg, href, color]
      fail_count += 1 if build['state'] !~ /\A(passed|started|created)\Z/
    end
  end
  
  output[0] = ' %s%s | color=red' % [SYMBOLS[:failed], fail_count] if fail_count > 0

  puts output.join("\n")
end

begin
  update_statuses(repos_to_check)
rescue => ex
  puts "travis-check error"
  puts "---"
  puts "#{ex.class.name}: #{ex.message}"
  puts ex.backtrace[0..10].join("\n")
end

puts "---"
puts "Refresh... | refresh=true"
