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

```
mv config.yaml.example config.yaml
# manually config your config.yaml file with generated token
```

3. There is a bug in official Mastodon API so I forked tootsuite/mastodon-api and manually fixed it. Fetch my libraby instead until the bug is fixed in official repo.

**See https://github.com/tootsuite/mastodon-api/issues/36 for details.**

```
# vim Gemfile
gem 'mastodon-api', :git => "https://github.com/obeliskgolem/mastodon-api-1.git"
```

My manual fix is nothing else, just replacing the `on_body()` function with following code

``` Ruby
      def on_body(data)
        @tokenizer.extract(data).each do |line|
          has_data = @match.match(line)
          next if has_data.nil?

          type = has_data[1]
          data = has_data[2]

          next if !(type == "update")         # check if streaming content have body to parse, Streaming::Response may be 'delete' events that lacks data and will cause JSON::ParseError

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
