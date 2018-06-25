require 'rubygems'
require 'bundler/setup'
require 'mastodon'
require 'set'
require 'pp'
require 'yaml'
require 'pg'

# Initialize
def init
  # db initialize
  $today_teams = Hash.new()
  $today_deadlines = Hash.new()
  $admin = "obeliskgolem"
  $user_assets = "user_assets"
  $today_odds = "today_odds"
  $today_bets = "today_bets"
  $team_deadline = "team_deadline"

  puts "db connecting"
  $db_con = PG.connect :dbname => 'danreuk85bemam', :user => ENV['POSTGREDB_USER'], :password => ENV['POSTGREDB_PASSWD'], :port => '5432', :host => 'ec2-75-101-142-91.compute-1.amazonaws.com'
  puts "db connencted"

  # Mastodon initialize
  $config = YAML.load_file("config.yaml")

  config_url = $config["cmx_url"]
  config_token = $config["cmx_token"]

  # for test purpose, please enable following statements
  #config_url = $config["botsin_url"]
  #config_token = $config["botsin_token"]

  $toot_client = Mastodon::REST::Client.new(base_url: config_url, bearer_token: config_token)

  $streaming_client = Mastodon::Streaming::Client.new(base_url: config_url, bearer_token: config_token)

  #$time_start = 1528256052
end

# create user if new
def create_user_if_new (user)
  begin
    rs = $db_con.exec "SELECT * FROM #{$user_assets} WHERE username='#{user}'"

    if (rs.cmd_tuples == 0)   # if this is a new user
      rs = $db_con.exec "INSERT INTO #{$user_assets} VALUES('#{user}', 1000, 0)"
    end
  rescue PG::Error => e
    puts e.message 
  ensure
    rs.clear if rs
  end
end

# check user's assets
def check_assets (user)
  begin
    rs = $db_con.exec "SELECT asset FROM #{$user_assets} WHERE username='#{user}'"

    if (rs.cmd_tuples != 0)   # if the user exists
      return rs.getvalue(0, 0).to_f
    end
  rescue PG::Error => e
    puts e.message 
  ensure
    rs.clear if rs
  end
  return 0
end

# List all odds

def list_odds
  s = "队伍\t赔率\n"

  begin
    rs = $db_con.exec "SELECT * FROM #{$today_odds}"
    rs.each do |row|
      s = s + "#{row["team"]}\t#{row["odds"]}\n"
    end
  rescue PG::Error => e
    puts e.message 
  ensure
    rs.clear if rs
    return s
  end
end

# Read odds and deadlines

def read_odds_deadlines
  begin
    $today_teams.clear

    rs = $db_con.exec "SELECT * FROM #{$today_odds}"

    rs.each do |row|
      $today_teams[row["team"]] = row["odds"].to_f
    end
    puts $today_teams

    $today_deadlines.clear

    rs = $db_con.exec "SELECT * FROM #{$team_deadline}"

    rs.each do |row|
      $today_deadlines[row["team"]] = row["deadline"].to_f
    end
    puts $today_deadlines
  rescue PG::Error => e
    puts e.message 
  ensure
    rs.clear if rs
  end
end

# List all assets

def list_assets
  s = "用户\t赌资\t借款次数\n"
  begin
    rs = $db_con.exec "SELECT * FROM #{$user_assets}"
    rs.each do |row|
        s = s + "#{row["username"]}\t#{row["asset"]}\t#{row["borrow"]}\n"
    end
  rescue PG::Error => e
    puts e.message 
  ensure
    rs.clear if rs
    return s
  end
end

# update odds

def odds_update (team, odds)
  begin
    rs = $db_con.exec "UPDATE #{$today_odds} SET odds=#{odds} WHERE team='#{team}'"

    if (rs.cmd_tuples == 0)     # if the team is not added then insert it
      rs = $db_con.exec "INSERT INTO #{$today_odds} VALUES('#{team}', #{odds})"
    end
  rescue PG::Error => e
    puts e.message 
  ensure
    rs.clear if rs
  end
end

# update deadline

def deadline_update (team, deadline)
  begin
    rs = $db_con.exec "UPDATE #{$team_deadline} SET deadline='#{deadline}' WHERE team='#{team}'"

    if (rs.cmd_tuples == 0)     # if the team is not added then insert it
      rs = $db_con.exec "INSERT INTO #{$team_deadline} VALUES('#{team}', '#{deadline}')"
    end
  rescue PG::Error => e
    puts e.message 
  ensure
    rs.clear if rs
  end
end

# borrow from bot

def borrow (user)
  begin
    rs = $db_con.exec "SELECT asset, borrow FROM #{$user_assets} WHERE username='#{user}'"
    if (rs.cmd_tuples != 0)
      b_a = rs.getvalue(0, 0).to_f + 1000
      b_v = rs.getvalue(0, 1).to_i + 1
      rs = $db_con.exec "UPDATE #{$user_assets} SET asset=#{b_a}, borrow=#{b_v} WHERE username='#{user}'"
    end
  rescue PG::Error => e
    puts e.message 
  ensure
    rs.clear if rs
  end
end

# update bets

def bets_update (user, bets)
  begin
    rs = $db_con.exec "DELETE FROM #{$today_bets} WHERE username='#{user}'"

    bets.each do |bet_team, bet_money|
      rs = $db_con.exec "INSERT INTO #{$today_bets} VALUES('#{user}', '#{bet_team}', #{bet_money})"
    end
  rescue PG::Error => e
    puts e.message 
  ensure
    rs.clear if rs
  end 
end

# update assets

def assets_update
  begin
    rs = $db_con.exec "SELECT * FROM #{$user_assets}"

    rs.each_row do |row|

      asset = row[1].to_f

      ks = $db_con.exec "SELECT * FROM #{$today_bets} WHERE username='#{row[0]}'"
      ks.each_row do |bets|
        asset = asset + bets[2].to_f * ($today_teams[bets[1]].to_f - 1)
      end

      asset = asset - 100 * row[2].to_f

      ps = $db_con.exec "UPDATE #{$user_assets} SET asset=#{asset} WHERE username='#{row[0]}'"
    end
  rescue PG::Error => e
    puts e.message 
  ensure
    rs.clear if rs
  end 
end

# Reads from toot and manipulate

# bet france 10 denmark 50            -- bet on teams
# borrow                              -- borrow $1000 from bot at an interest rate of 100/day
# check                               -- check my own assets
# update                              -- ADMIN ONLY: calculate assets and toot, meanwhile clean all odds
# odds france 5.4 england 2.2         -- ADMIN ONLY: add today's odds, for convenience all use integers
# today                               -- ADMIN ONLY: toot today's odds and accept bets in X hours
# list                                -- ADMIN ONLY: print all users' assets

# Error Message: 今天没有XXX的比赛
# Error Message: 你的下注超过了本金 www
# Error Message: 现在不是出价时间段

def analyze_toot (id, user, command)
  create_user_if_new(user)

  args = command.split(" ")

  puts id
  puts user
  puts args

  time_now = Time.now

  case args[0]
  when "bet"
    i = 1
    total = 0
    bets = Hash.new()
    failed = false

    while (i<args.length)
      if ($today_teams.has_key?(args[i]))
        if (Time.now > $today_deadlines[args[i]])
          $toot_client.create_status("@#{user} 现在不是出价的时间段", id, nil, "direct")
        failed = true
        end

        bets[args[i]] = args[i+1].to_i
        total = total + args[i+1].to_i
        i = i+2
      else
        $toot_client.create_status("@#{user} 今天没有#{args[i]}的比赛\n", id, nil, "direct")
        failed = true
        break
      end
    end

    if (total > check_assets(user))
      $toot_client.create_status("@#{user} 你的下注超过了本金 www", id, nil, "direct")
      failed = true
    end


    if !failed
      bets_update(user, bets)
    end

  when "borrow"
    borrow(user)
    $toot_client.create_status("@#{user} 金钱是万能的：你借款 1000", id, nil, "direct")

  when "check"
    asset = check_assets(user)
    $toot_client.create_status("@#{user} 你的赌资： #{asset.to_s}", id, nil, "direct")

  when "update"
    if (user == $admin)
      assets_update
      reset($today_bets)
      reset($team_deadline)
      reset($today_odds)
      $today_teams.clear
      $today_deadlines.clear
    end

  when "odds"
    if (user == $admin)
      i = 1

      while (i<args.length)
        $today_teams[args[i]] = args[i+1].to_f
        odds_update(args[i], args[i+1])
        i = i+2
      end
    end
    
  when "today"
    if (user == $admin)
      s = list_odds
      $toot_client.create_status("#{s}", nil, nil, "public")
    end

  when "list"
    if (user == $admin)
      s = list_assets
      $toot_client.create_status("#{s}", nil, nil, "public")
    end

  when "deadline"
    temp_time = Time.now
    today = Time.new(temp_time.year, temp_time.month, temp_time.day, 12)
    if (user == $admin)
      i = 1

      while (i<args.length)
        $today_deadlines[args[i]] = today + args[i+1].to_i*3600
        deadline_update(args[i], (today + args[i+1].to_i*3600).to_s)
        i = i+2
      end

      puts $today_deadlines
    end
   end

end

def reset (dbname)
  begin
    rs = $db_con.exec "DELETE FROM #{dbname}"
  rescue PG::Error => e
    puts e.message 
  ensure
    rs.clear if rs
  end 
end

# Process Toots

def process_toots
  command_pattern = /bet (\S+\s+\d+\s*)+|borrow|check|update|odds (\S+\s+\d+(\.?\d*)\s*)+|today|list|deadline (\S+\s+\d+\s*)+/ 

  begin
    $streaming_client.stream("user") do |stream_toot|
      next if stream_toot.kind_of?(Mastodon::Streaming::DeletedStatus)
      next if stream_toot.kind_of?(Mastodon::Status)

      toot_user = stream_toot.status.account.username
      toot_command = stream_toot.status.content
      toot_id = stream_toot.status.id

      next if (toot_user == "botkun_001")

      x = command_pattern.match(toot_command)

      if x
        analyze_toot(toot_id, toot_user, x.to_s)
      end
    end
  rescue EOFError => e
    puts "\nretry..."
    retry
  ensure
    $db_con.close if $db_con
  end

end

init
read_odds_deadlines
process_toots
