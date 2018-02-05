class GlobalBans
  include Cinch::Plugin
  
  match /addban ([a-zA-Z0-9\w\W ]*)/, method: :add_ban
  match /deleteban ([a-zA-Z0-9\w\W ]*)/, method: :delete_ban

  def setup(*)
    @collection = $mongo[:banlist]
  end

  def add_ban(m,user)
    if m.channel.name == "#sovereigntybot"
      if mod?(m)
        @collection.insert_one({ :user => user, :ban_issuer => m.user.name })
        $team_chans.each do |chan|
          Channel(chan).send ".ban #{user}"
          sleep 1
        end  
      end
    end
  end

  def delete_ban(m,user)
    if m.channel.name == "#sovereigntybot"
      if mod?(m)
        @collection.insert_one({ :user => user })
        $team_chans.each do |chan|
          Channel(chan).send ".unban #{user}"
          sleep 1
        end  
      end
    end
  end
end
