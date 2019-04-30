# frozen_string_literal: true

require 'rest-client'
require 'time'
require 'yaml/store'
require 'abbrev'
require 'dotenv'
require 'pry'

Dotenv.load("#{File.dirname(__FILE__)}/.env.local", "#{File.dirname(__FILE__)}/.env")

class Clockify

  API_KEY = ENV['API_KEY']
  WORKSPACE_ID = ENV['WORKSPACE_ID']
  URL_BASE = "https://api.clockify.me/api/workspaces/#{WORKSPACE_ID}"
  HEADERS = {
    'X-Api-Key' => API_KEY,
    'content-type' => 'application/json'
  }.freeze
  PROJECT_STORE = 'projects.store'
  DEBUG = ENV.fetch('DEBUG', false)
  INLINE_TIMER = ENV.fetch('INLINE_TIMER', true)
  DEVICE_ID = ENV['DEVICE_ID']
  DEVICE_ACCESS_TOKEN = ENV['DEVICE_ACCESS_TOKEN']
  DEVICE_URL = "https://api.particle.io/v1/devices/#{DEVICE_ID}/toggle-led?access_token=#{DEVICE_ACCESS_TOKEN}"

  def start_timer(description, project = nil)
    uri = URL_BASE + '/timeEntries/'
    params = { start: Time.now.utc.iso8601, description: description, billable: true }
    params[:projectId] = find_project(project) if project

    RestClient.post(uri, params.to_json, HEADERS)
    switch_light('1')

    puts params if DEBUG

    output_timer(description, project) if INLINE_TIMER
  rescue StandardError => e
    binding.pry
    puts 'There was an error with starting your timer.'
  end

  def stop_timer
    uri = URL_BASE + '/timeEntries/endStarted'
    params = { end: Time.now.utc.iso8601 }
    RestClient.put(uri, params.to_json, HEADERS)
    switch_light('0')
  rescue StandardError => e
    binding.pry if DEBUG
    puts 'There was an error with stopping your timer.'
  end

  private

    def output_timer(description, project)
      buff = []
      starting = Time.now

      counter = Thread.new do
        loop do
          print "\r #{description} | #{project} | #{Time.at(Time.now - starting).utc.strftime('%H:%M:%S')}"
          sleep(1)
        end
      end

      buff << STDIN.read(1) while buff.empty?

      counter.kill
      stop_timer
    end

    def find_project(project)
      found_project = nil

      if File.exist?("#{File.dirname(__FILE__)}/#{PROJECT_STORE}")
        store = YAML::Store.new "#{File.dirname(__FILE__)}/#{PROJECT_STORE}"
        projects = store.transaction { |store| store['projects'] }
        abbrevs = store.transaction { |store| store['abbrevs'] }
        found_project = projects[abbrevs[project]]
      end

      puts "#{project} | #{found_project}" if DEBUG

      return found_project if found_project

      projects, abbrevs = get_projects
      projects[abbrevs[project]]
    end

    def get_projects
      uri = URL_BASE + '/projects/'
      response = RestClient.get(uri, HEADERS)
      projects = JSON.parse(response.body)

      projects = projects
        .compact
        .map do |project|
          name = project.dig('name')
          id = project.dig('id')
          next unless name && id

          [name, id]
        end.compact.to_h

      store = YAML::Store.new "#{File.dirname(__FILE__)}/#{PROJECT_STORE}"

      store.transaction do
        store['projects'] = projects
        store['abbrevs'] = projects.keys.abbrev
      end

      [projects, projects.keys.abbrev]
    end

    # 1 turns the light on, whereas 0 turns it off.
    def switch_light(switch_state)
      RestClient.post(DEVICE_URL, args: switch_state)
    rescue RestClient::BadRequest
    end

end
