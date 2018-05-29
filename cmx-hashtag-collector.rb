require 'rubygems'
require 'bundler/setup'
require 'mastodon'
require 'rss'
require 'set'
require 'pp'
require 'yaml'

config = YAML.load_file("config.yaml")

config_url = config["cmx_url"]
config_token = config["cmx_token"]

# for test purpose, please enable following statements
# config_url = config["botsin_url"]
# config_token = config["botsin_token"]

toot_client = Mastodon::REST::Client.new(base_url: config_url, bearer_token: config_token)

streaming_client = Mastodon::Streaming::Client.new(base_url: config_url, bearer_token: config_token)

puts "Client Initialized"

toot_client.create_status("cmxBot君，重启一下 :0140:\n")

toot = "cmx每日话题收集 :2010:\n"

s = Set.new()

reg1 = /class=\"mention hashtag\" rel=\"tag\">#<span>(.*?)<\/span>/

time1 = Time.new  # used for toot time interval
time2 = Time.new  # time.now
time3 = Time.new  # used for daily clear

puts "Service started at " + time1.inspect

begin
  streaming_client.stream("public/local") do |stream_toot|
    next if stream_toot.kind_of?(Mastodon::Streaming::DeletedStatus)
    next if stream_toot.kind_of?(Mastodon::Notification)
    puts stream_toot.account.username

    next if (stream_toot.account.username == "botkun_001")

    puts stream_toot.content

    x = reg1.match(stream_toot.content)
    while x
      y = x.post_match
      x.captures.each{ |hashtag| s.add(hashtag) }
      x = reg1.match(y)
    end

    time2 = Time.now

    if (time2-time1>1800)   # if 30 minutes have passed
      s.each do |hashtag|
        toot = toot + "##{hashtag}\n"
      end

      if s.empty?
        toot_client.create_status("没有收集到hashtag :0240:\n")
      else
        toot_client.create_status(toot)
      end

      time1 = time2

      if (time2-time3>86400)    # if a day has passed
        s.clear
        toot = "cmx每日话题收集 :2010:\n\n"
        time3 = time2
      end
    end
  end
rescue EOFError => e
  puts "\nretry..."
  retry
end
