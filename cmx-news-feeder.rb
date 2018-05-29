require 'rubygems'
require 'bundler/setup'
require 'mastodon'
require 'rss'
require 'set'

client = Mastodon::REST::Client.new(base_url: "https://cmx.im", bearer_token: "8bde56b7aa0e84fae2c66a27c6974bd0f64c95b3a565ae1ed0720ebadebfe1a3")

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
