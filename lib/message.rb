require 'cinch'
require 'cinch/user'
require 'cinch/bot'

module Cinch
  class Message
    def reply(text, prefix = false)
      if @bot.has_mod? @channel.name
        text = text.to_s
        if @channel && prefix
          text = text.split("\n").map {|l| "#{user.nick}: #{l}"}.join("\n")
        end

        reply_target.send(text)
      else
        @bot.loggers.info "Can't reply in #{@channel.name} due to missing modstate."
      end
    end
  end

  class Bot < User
    attr_reader :modstate

    def initialize(&b)
      @loggers = LoggerList.new
      @loggers << Logger::FormattedLogger.new($stderr)

      @config           = Configuration::Bot.new
      @handlers         = HandlerList.new
      @semaphores_mutex = Mutex.new
      @semaphores       = Hash.new { |h, k| h[k] = Mutex.new }
      @callback         = Callback.new(self)
      @channels         = []
      @quitting         = false
      @modes            = []
      @modstate         = {}

      @user_list    = UserList.new(self)
      @channel_list = ChannelList.new(self)
      @plugins      = PluginList.new(self)

      @join_handler = nil
      @join_timer   = nil

      super(nil, self)
      instance_eval(&b) if block_given?
    end

    def add_mod(chan)
      @modstate[chan] = true
      return
    end

    def del_mod(chan)
      @modstate[chan] = false
      return
    end

    def has_mod?(chan)
      return @modstate[chan]
    end
  end
end
