require 'cinch'
require 'active_support'
require 'json'
require 'net/http'
require 'uri'

class AutoBan
  include Cinch::Plugin
  include ActiveSupport::Inflector

  listen_to :channel,    :method => :lul
  listen_to :channel,    :method => :ban_link_bots
  listen_to :channel,    :method => :timeout_jackasses

  match /wbt.link/, use_prefix: false, method: :elena

  def lul(m)
    if m.user.name.downcase == "ElectricCraze".downcase
      m.reply ".timeout #{m.user.name} 600 LUL"
    end
  end

  def timeout_jackasses(m)
    if /just subscribed/i.match(m.message)
      if /ACTION/.match(m.message)
        m.reply ".timeout #{m.user.name} 600 Nice fake sub. Enjoy a 10 minute timeout. (fake sub)"
      end
    end

    if /imGlitch You have been permanently banned from this channel/i.match(m.message)
      m.reply ".timeout #{m.user.name} 600 Nice fake ban message. Enjoy a 10 minute timeout. (fake ban)"
    end

    if /You have been gifted a subscription/i.match(m.message)
      m.reply ".timeout #{m.user.name} 1 (fake)"
    end
  end

  def ban_link_bots(m)
    if /SEX/.match(m.message)
      if /wbt.link/.match(m.message)
        if /elena/.match(m.user.nick)
          m.reply ".ban #{m.user.nick}"
        end
      end
    end
    if /WTF/i.match(m.message)
      if /grill/i.match(m.message)
        if /screenshot/i.match(m.message)
          m.reply ".ban #{m.user.name} spambot signature match"
        end
      end
    end
    if /EleGiggle/.match(m.message)
      if /screenshot/i.match(m.message)
        m.reply ".ban #{m.user.name} spambot signature match"
      end
    end
    if /It's me Greg from high school/i.match(m.message)
      if /Remember that one time you/i.match(m.message)
        if /always did the craziest things/i.match(m.message)
          m.reply ".timeout #{m.user.name} 600 Anti-spam detection (spam|copy-pasta|explicit)"
        end
      end
    end
    if /imghdr\.com/i.match(m.message)
      m.reply ".ban #{m.user.name} spambot signature match"
    end
    if /imgart\.net/i.match(m.message)
      m.reply ".ban #{m.user.name} spambot signature match"
    end
    if /imagehostlng\.com/i.match(m.message)
      m.reply ".ban #{m.user.name} spambot signature match"
    end
  end


end
