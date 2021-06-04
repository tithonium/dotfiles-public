%w[
  irb/completion
  irb/ext/save-history
  pp
].each{|r| require r rescue nil }

IRB.conf[:PROMPT_MODE] = :SIMPLE if IRB.conf[:PROMPT_MODE] == :DEFAULT
IRB.conf[:SAVE_HISTORY] = 100000
IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb_history"
# IRB.conf[:AUTO_INDENT] = true

# # %w[
# #   rubygems
# #   copyrb
# # ].each do |lib|
# #   require lib rescue nil
# # end

# begin
#   require 'yaml'
#   def y(o)
#     puts YAML.dump(o)
#   end
# rescue Exception
# end

begin
  require 'wirb'
  Wirb.start
rescue Exception
end

class Object
  def textmate(method_name)
    file, line = method(method_name).source_location
    `mate '#{file}' -l #{line}`
  end
end

def debundle
  # Break out of the Bundler jail
  # from https://github.com/ConradIrwin/pry-debundle/blob/master/lib/pry-debundle.rb
  if defined? Bundler
    Gem.post_reset_hooks.reject! { |hook| hook.source_location.first =~ %r{/bundler/} }
    Gem::Specification.reset
    load 'rubygems/custom_require.rb'
  end
end

# if defined?(ActiveRecord::Base)
#   # ActiveRecord::Base.logger = Logger.new(STDOUT)
#   ActiveRecord::Base.instance_eval do
#     alias :[] :find
#   end
#   # unless ActiveRecord::Base.respond_to?(:connection_type)
#   #   ActiveRecord::Base.class_eval do
#   #     def self.connection_type
#   #       @@connectionType ||= ActiveRecord::Base.connection.class.to_s.downcase.sub(/.+::(.+?)\d+adapter$/, '\1').to_sym
#   #     end
#   #     def connection_type; self.class.connection_type; end
#   #   end
#   # end
#   # ActiveRecord::Base.class_eval do
#   #   def self.any
#   #     self.first(:order => (self.connection_type == :sqlite ? "random()" : "rand()"))
#   #   end
#   #   def next
#   #     self.class.first(:conditions=>['id>?',self.id],:order=>"id")
#   #   end
#   #   def previous
#   #     self.class.last(:conditions=>['id<?',self.id],:order=>"id")
#   #   end
#   # end
# end

def pbcopy(&block) ; str = yield ; IO.popen('pbcopy', 'w') { |f| f << str } ; str ; end

def pbpaste
  `pbpaste`
end
