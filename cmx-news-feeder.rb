require 'rubygems'
require 'bundler/setup'
require 'mastodon'
require 'rss'
require 'set'
require 'pp'
require 'yaml'

config = YAML.new("config.yaml")

client = Mastodon::REST::Client.new(base_url: config["cmx_url"], bearer_token: config["cmx_token"])

puts "Hello World!"
toot = ""


#rss = RSS::Parser.parse('http://www.ftchinese.com/rss/news', false)
#rss.items.each do |item|
#  toot = toot + "#{item.title}\n"
#end

puts toot
# client.create_status(toot)

#timeline_toots = Mastodon::REST::Timelines.new()

s = Set.new()

timeline_toots = client.public_timeline(max: 10)

reg1 = /class=\"mention hashtag\" rel=\"tag\">#<span>(.*?)<\/span>/

timeline_toots.each do |item|
# puts "#{item.content}"
  x = reg1.match(item.content)
  while x
    y = x.post_match
    x.captures.each{ |hashtag| s.add(hashtag) }
    x = reg1.match(y)
  end
end

s.each do |hashtag|
  puts "##{hashtag}"
end
