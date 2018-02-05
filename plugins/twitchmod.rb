class TwitchMod
  include Cinch::Plugin

  listen_to :channel, :method => :upsert_mod
  listen_to :userstate, :method => :bot_mod_state

  def setup(*)
    @collection = $mongo[:mods]
  end

  def upsert_mod(m)
    if m.tags["mod"].to_i === 1
      user = @collection.find(nick: m.user.name)
      if user.any?
        if !user.first[:channels].include? m.channel.name
          channels = user.first[:channels]
          channels.push m.channel.name

          @collection.find_one_and_replace(
          { :nick => m.user.name },
          { :nick => m.user.name,
            :channels => channels})
        end
      else
        @collection.insert_one(
        { :nick => m.user.name,
          :channels => [ m.channel.name ] })
      end
    else
      user = @collection.find(nick: m.user.name)
      if user.any?
        channels = user.first[:channels]
        if channels.include? m.channel.name
          channels.delete m.channel.name
          @collection.find_one_and_replace(
          { :nick => m.user.name },
          { :nick => m.user.name,
            :channels => channels})
        end
      end
    end
  end

  def bot_mod_state(m)
    if m.tags['mod'].to_i === 1
      $bot.add_mod m.channel.name
    else
      $bot.del_mod m.channel.name
    end
  end

end
