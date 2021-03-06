#!/usr/bin/ruby

# Load '.'
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__))) unless $LOAD_PATH.include?(File.expand_path(File.dirname(__FILE__)))

# require Cinch IRCBot Framwork
require 'cinch'

# require activesupport for various Rails like magics
require 'active_support'

# add Inflector methods and overrides.
include ActiveSupport::Inflector

# require mongodb driver for working with various long term storage of data
require 'mongo'

# require tzinfo to deal with Locales
require 'tzinfo'

# load libs
Dir["./lib/*.rb"].each {|file| load file}

# load custom cinch plugins
Dir["./plugins/*.rb"].each {|file| load file}

$brain = Brain.new

$host_chans = []
$live_chans = []
$team_chans = []
$results = []

if !$brain.config
  $brain.setup
end

$mongo = Mongo::Client.new($brain.mongo["replSet"]["members"], :database => $brain.mongo["db"])
Mongo::Logger.logger.level = ::Logger::FATAL

channels = []
$brain.channels.each do |chan|
  channels.push "#" + chan["name"]
end

plugins = []
$brain.plugins.each do |plugin|
  plugins.push constantize(plugin)
end

$bot = Cinch::Bot.new do
  configure do |c|
    c.nick = $brain.bot["nick"]
    c.server = $brain.bot["server"]
    c.port = $brain.bot["port"]
    c.ssl.use = $brain.bot["ssl"]
    c.ssl.verify = $brain.bot["ssl_verify"]
    c.password = $brain.bot["password"]
    c.channels = channels
    c.caps = [:"twitch.tv/membership", :"twitch.tv/commands", :"twitch.tv/tags"]
    c.plugins.plugins = plugins
    c.shared[:cooldown] = { :config => { } }

  end

  on :connect do |m|
  end

  on :invite do |m|
    if permission_check(m, 20)
      $bot.join(m.channel)
      $brain.channels.push m.channel
    end
  end

  on :notice do |m|
    # implement now hosting handling here
    if !(/has gone offline. Exiting host mode./.match(m.message)).nil?
      $bot.warn "#{chan_to_user(m)} no longer hosting"
    end
  end

  on :hosttarget do |m|
    # implement hosttarget tracking and redirection here
    split_msg = m.message.split(" ")
    $bot.warn "channel: " + m.channel.to_s
    $bot.warn "target: " + split_msg[0]
    $bot.warn "viewers: " + split_msg[1]
  end

  on :join do |m|
    if m.user == $brain.bot["nick"]
      match_chan = false

      $brain.channels.each do |chan|
        if !(chan["name"] == m.channel.to_s)
          match_chan = true
        end
      end

      if !match_chan
        ch = {}
        ch["name"] = m.channel.to_s
        $brain.channels.push ch
        $brain.save
      end
    end

    collection = $mongo[:timers]
    channel = collection.find( {channel: m.channel.name} )
    channel.each do |timer|
      $bot.timers[timer['timer_ref']] = Timer(timer['periodicity']) { Channel(timer['channel']).send(timer['message']) }
    end
  end

end

$plugin_list = Cinch::PluginList.new $bot
$bot.start
