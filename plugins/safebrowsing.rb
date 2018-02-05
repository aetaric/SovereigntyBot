require 'json'
require 'net/http'
require 'uri'
require 'open-uri'

class SafeBrowsing
  include Cinch::Plugin
  include ActiveSupport::Inflector

  listen_to :channel,    :method => :safebrowsing

  def safebrowsing(m)
    if /(http[s]?:\/\/\S+\.\S+)/.match(m.message)
      urls = m.message.scan(/(http[s]?:\/\/\S+\.\S+)/)
  
      url_list = []
  
      urls.each do |url|
        #URI.extract(url, ["http", "https"]) do |uri|
        #  begin
        #    io = open(uri)                    # open-uri follows server redirects
        #    final_url = io.base_uri.to_s            # Save the final url
        #    url_match = Regexp.new "#{final_uri}/?"
        #    if url !~ url_match
              u = {}
              u['url'] = url
              url_list.push u
        #    end
        #  rescue
        #    puts $!, $@
        #  end
        #end
      end
    
      body = {
        "client" => {
          "clientId" => "SovBot",
          "clientVersion" => "1.0.0"
        },
        "threatInfo" => {
          "threatTypes" => ["MALWARE", "SOCIAL_ENGINEERING"],
          "platformTypes" => ["WINDOWS"],
          "threatEntryTypes" => ["URL"],
          "threatEntries" => url_list
        }
      }
  
      uri = URI.parse("https://safebrowsing.googleapis.com/v4/threatMatches:find?key=#{$brain.google['api_key']}")
      request = Net::HTTP::Post.new(uri)
      request.content_type = "application/json"
      request.body = body.to_json
  
      req_options = {
        use_ssl: uri.scheme == "https",
      }
  
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
  
      json = JSON.load response.body
  
      if !json.empty?
        if !json['matches'].nil?
          types = []
          bad_urls = []
          
          json['matches'].each do |threats|
            types.push    threats['threatType']
            if !bad_urls.include? threats['threat']['url']
              bad_urls.push threats['threat']['url']
            end
          end
          
          m.reply ".timeout #{m.user.name} 1 (SafeBrowsing | #{types.join(" & ").gsub(/_/,' ')})"
          m.reply ".w #{m.user.name} Your link(s) #{bad_urls.join(" & ")} was/were removed from chat due to being listed in the google SafeBrowsing list as a malicious link of types #{types.join(" & ").gsub(/_/,' ')}"
        end
      end
    end
  end
end
