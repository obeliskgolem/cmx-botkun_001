# Introduction

This is a bot for collecting all the hashtags posted in cmx.im local timeline every 30 minutes.

# Usage

1. Clone this repo. Make sure you have Ruby Gem and Bundler installed

```
git clone https://github.com/obeliskgolem/cmx-botkun_001
gem install bundler
bundle install
```

2. Generate a bearer token for your application, then copy it and create a file named "config.yaml" with it. You can take "config.yaml.example" as a reference.

To generate bearer token, take a look at Reference #3.

```
mv config.yaml.example config.yaml
# manually config your config.yaml file with generated token
```

3. There is a bug in official Mastodon API and you should modify `streaming/response.rb` accordingly. See https://github.com/tootsuite/mastodon-api/issues/36 for details.

```
vim /Users/XXXXXX/.rbenv/versions/2.3.6/lib/ruby/gems/2.3.0/bundler/gems/mastodon-api-6557c5cc580f/lib/mastodon/streaming/response.rb
```

Replace the `on_body()` function with code

``` Ruby
      def on_body(data)
        @tokenizer.extract(data).each do |line|
          has_data = @match.match(line)
          next if has_data.nil?

          type = has_data[1]
          data = has_data[2]

          next if !(type == "update")         # added a check before parsing JSON

          @block.call(type, JSON.parse(data))
        end
      end
```

4. Executing the bot from CLI

```
ruby cmx-hashtag-collector.rb
```

It should be working.



# References

[Mastodon API in Ruby](https://github.com/tootsuite/mastodon-api)

[Streaming API code examples](https://github.com/takahashim/mastodon-book-sample)

[Making a Mastodon Bot in Ruby](http://benjbrandall.xyz/mastodon-bot-ruby/?i=3)
