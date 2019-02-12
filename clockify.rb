require 'rest-client'
require 'pry'
require 'time'

class Clockify
  API_KEY = ''.freeze
  WORKSPACE_ID = ''.freeze
  URL_BASE = "https://api.clockify.me/api/workspaces/#{WORKSPACE_ID}".freeze
  HEADERS = {
    'X-Api-Key' => API_KEY,
    'content-type' => 'application/json'
  }
  
  def start_timer(description)
    uri = URL_BASE + '/timeEntries/'
    params = {start: Time.now.utc.iso8601, description: description}

    request = RestClient.post(uri, params.to_json, HEADERS)

  rescue StandardError => e
    binding.pry
  end

  def stop_timer
    uri = URL_BASE + '/timeEntries/endStarted'
    params = {end: Time.now.utc.iso8601}
    request = RestClient.put(uri, params.to_json, HEADERS)
  rescue StandardError => e
    binding.pry
  end
  
end