require 'json'
require 'net/http'
require 'uri'

class StrawPoll
  include Cinch::Plugin
  include ActiveSupport::Inflector
  
  match /createstrawpoll\s(.+)/i, method: :new_poll
  match /endstrawpoll\s(\d+)/i, method: :end_poll

  def new_poll(m, options)
    opts_array = options.split "|"
    data = {
      "title" => opts_array.shift,
      "options" => opts_array,
      "captcha" => true
    }

    uri = URI.parse("https://www.strawpoll.me/api/v2/polls")
    request = Net::HTTP::Post.new(uri)
    request.body = data.to_json

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    if response.code.to_s == "200"
      response_json = JSON.load response.body
      id = response_json['id']
      m.reply "Strawpoll created! https://strawpoll.me/#{id}/ End the poll with !endstrawpoll #{id}"
      puts "Strawpoll created! https://strawpoll.me/#{id}/ End the poll with !endstrawpoll #{id}"
    end
  end

  def end_poll(m, poll_id)
    uri = URI.parse("https://www.strawpoll.me/api/v2/polls/#{poll_id}")
    response = Net::HTTP.get_response(uri)

    if response.code.to_s == "200"
      json_response = JSON.load response.body

      map = {}
      json_response['options'].each_with_index do |option, index|
        map[option] = json_response['votes'][index]
      end

      response_str = ""
      map.keys.each do |key|
        if response_str.empty?
          response_str += "#{key}: #{map[key]}"
        else
          response_str += ", #{key}: #{map[key]}"
        end
      end

      m.reply "Poll has ended. Votes will not be tracked beyond this point. Results:"
      m.reply "#{response_str}"
    end
  end

end
