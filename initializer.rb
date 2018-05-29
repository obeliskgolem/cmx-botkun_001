require 'rubygems'
require 'bundler/setup'
require 'mastodon'
require 'rss'
require 'set'

client = Mastodon::REST::Client.new(base_url: "https://cmx.im")
app = client.create_app("cmx每日话题收集", "", "read write")

puts app.client_id
puts app.client_secret
