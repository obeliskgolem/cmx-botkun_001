require 'rubygems'
require 'bundler/setup'
require 'mastodon'
require 'rss'
require 'set'
require 'pp'
require 'yaml'
require 'phantomjs'

def init
  $config = YAML.load_file("config.yaml")

  config_url = $config["cmx_url"]
  config_token = $config["cmx_token"]

  # for test purpose, please enable following statements
  #config_url = $config["botsin_url"]
  #config_token = $config["botsin_token"]

  $toot_client = Mastodon::REST::Client.new(base_url: config_url, bearer_token: config_token)

  $streaming_client = Mastodon::Streaming::Client.new(base_url: config_url, bearer_token: config_token)

  puts "Client Initialized"

#  $toot_client.create_status("暗中上线 :2010:\n", nil, nil, "private")
end



def cmx_collector
  begin
    s = Set.new() # for hashtags
    t = Set.new() # for emotions

    reg1 = /class=\"mention hashtag\" rel=\"tag\">#<span>(.*?)<\/span>/
    reg2 = /\B(:\w+?:)/

    initial_toot = ""
    spoiler_warning_hashtag = "cmx每日话题收集 :2010:\n"
    spoiler_warning_emotion = "cmx每日心情 :2010:\n"
    toot = initial_toot

    time1 = Time.new  # used for toot time interval
    time2 = Time.new  # time.now
    time3 = Time.new  # used for daily hashtag clear
    time4 = Time.new  # used for daily emotion clear

    $streaming_client.stream("public/local") do |stream_toot|
      next if stream_toot.kind_of?(Mastodon::Streaming::DeletedStatus)
      next if stream_toot.kind_of?(Mastodon::Notification)
      puts stream_toot.account.username

      next if (stream_toot.account.username == "botkun_001")

      puts stream_toot.content

      x = reg1.match(stream_toot.content)
      while x
        y = x.post_match
        x.captures.each{ |hashtag| s.add(hashtag.upcase) }
        x = reg1.match(y)
      end

      x = reg2.match(stream_toot.content + stream_toot.spoiler_text)
      while x
        y = x.post_match
        x.captures.each{ |emotions| t.add(emotions) }
        x = reg2.match(y)
      end

      time2 = Time.now

      if (time2-time1>$config["toot_freq"])   # if 2 hours (by default) have passed
        toot = initial_toot

        s.each do |hashtag|
          toot = toot +  "##{hashtag}\n"
        end

        if s.empty?
          $toot_client.create_status("没有收集到hashtag :0240:\n", nil, nil, "unlisted")
        else
          $toot_client.create_status_with_spoiler(toot, spoiler_warning_hashtag, nil, nil, "unlisted")
        end

        time1 = time2

        if (time2-time3>$config["hashtag_clear_freq"])    # if a day (by default) has passed
          s.clear
          time3 = time2
        end
      end

      if (time2-time4>$config["emotion_freq"])   # if 2 hours (by default) have passed
          toot = initial_toot

          t.each do |emotion|
            toot = toot +  " #{emotion}"
          end

          if t.empty?
            $toot_client.create_status("今日无心情 :0240:\n", nil, nil, "unlisted")
          else
            $toot_client.create_status_with_spoiler(toot, spoiler_warning_emotion, nil, nil, "unlisted")
          end

          time4 = time2
          t.clear
      end
    end
  rescue EOFError => e
    puts "\nretry..."
    retry
  end
end

def cmx_crosswords_guardian
  count_time = Time.now

  while true
    if (Time.now - count_time > $config["crosswords_freq"])
      count_crosswords = (((Time.now - $config["crosswords_base_time"]).to_i) / 86400) + $config["crosswords_base_count"]

      source_dest = "https://www.theguardian.com/crosswords/quick/" + count_crosswords.to_s + "/print"
      puts source_dest

      Phantomjs.run("./crosswords.js", "#{source_dest}")
      uploaded_png = $toot_client.upload_media('./guardian-today.png')

      puts "tooting crosswords puzzle"

      $toot_client.create_status("#填字游戏\n\n" + source_dest, nil, [uploaded_png.id], "public")


      count_time = Time.now
    end

    sleep($config["crosswords_freq"])
  end
end

def cmx_crosswords_chinese
  count_time = Time.now

  while true
    if (Time.now - count_time > $config["crosswords_freq"])
      count_crosswords = (((Time.now - $config["crosswords_base_time"]).to_i) / 86400) + $config["crosswords_base_count"]

      Phantomjs.run("./crosswords.js")
      uploaded_png = $toot_client.upload_media('./capture.png')

      puts "tooting crosswords puzzle"

      $toot_client.create_status("#每日填字游戏\n\n" + source_dest, nil, [uploaded_png.id], "public")

      count_time = Time.now
    end

    sleep($config["crosswords_freq"])
  end
end

init()

t1 = Thread.new{cmx_collector()}
t2 = Thread.new{cmx_crosswords_chinese()}
t1.join()
t2.join()
