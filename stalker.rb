#!/usr/bin/env ruby

require 'faraday'
require 'nokogiri'
require 'pushover'
require 'json'
require 'yaml'
require 'tempfile'

class Stalker
  def initialize(config_file)
    config = YAML.load_file(config_file)
    @steam_id = config['steam_id']
    @watched_games = config['watched_games']
    Pushover.configure do |push_config|
      push_config.user  = config['pushover_user']
      push_config.token = config['pushover_token']
    end
    load_last_seen
  end

  def load_last_seen
    @last_seen = JSON.load(File.read("last_seen.json"))
  rescue Errno::ENOENT
    @last_seen = {}
  end

  def save_last_seen
    Tempfile.open(["last_seen", ".json"], Dir.getwd) do |fh|
      fh.puts(@last_seen.to_json)
      fh.close
      File.rename(fh.path, "last_seen.json")
    end
  end

  def get_friends_page
    response = Faraday.get(url = "https://steamcommunity.com/id/#{@steam_id}/friends/")
    if response.status != 200
      File.write("failed.html", response.body) rescue nil
      raise "Request to #{url.inspect} failed: #{response.status}"
    end
    return response.body
  end

  def friends_list
    doc = Nokogiri::HTML(get_friends_page)
    friends = {}

    doc.xpath('//div[@class="friendBlockContent"]').each do |friend_elem|
      name = friend_elem.children.first.to_s.strip
      friends[name] =
        if game_elem = friend_elem.xpath('.//span[@class="linkFriend_in-game"]/br/following::text()[1]').first
          friends[name] = game_elem.to_s.strip
        else
          nil
        end
    end

    return friends
  end

  def comma_list(items)
    if items.count == 1
      return items.first
    elsif items.count == 2
      return items.join(" and ")
    else
      return items[0..-2].join(", ") + ", and " + items.last
    end
  end

  def is_or_are(list)
    if list.count > 1
      return "are"
    else
      return "is"
    end
  end

  def stalk
    playing = Hash.new { |h, k| h[k] = [] }
    total = 0
    notify = false

    friends_list.each do |friend, game|
      already_seen = (@last_seen[friend] == game)

      if @watched_games.include?(game)
        playing[game] << friend
        total += 1
        notify = true unless already_seen
      end

      unless already_seen
        if game
          puts "#{friend} is now playing #{game}."
        else
          last = @last_seen[friend]
          puts "#{friend} has stopped playing #{last}."
        end
        @last_seen[friend] = game
      end
    end

    lines = playing.map do |game, friends|
      [comma_list(friends), is_or_are(friends), "playing", game].join(" ") + "."
    end

    save_last_seen

    if notify
      games = playing.keys
      Pushover.notification(title: "#{total} playing #{comma_list(games)}", message: lines.join("\n"))
      puts "Sent notification."
    end
  end
end

delay = ARGV.first.to_i
stalker = Stalker.new("config.yml")
if delay > 0
  loop do
    stalker.stalk
    $stdout.flush
    sleep delay
  end
else
  stalker.stalk
end
