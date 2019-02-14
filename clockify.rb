#frozen_string_literal: true

require 'rest-client'
require 'pry'
require 'time'
require 'yaml/store'
require 'abbrev'
require 'dotenv'

Dotenv.load("#{File.dirname(__FILE__)}/.env.local", "#{File.dirname(__FILE__)}/.env")

class Clockify
  API_KEY = ENV['API_KEY']
  WORKSPACE_ID = ENV['WORKSPACE_ID']
  URL_BASE = "https://api.clockify.me/api/workspaces/#{WORKSPACE_ID}"
  HEADERS = {
    'X-Api-Key' => API_KEY,
    'content-type' => 'application/json'
  }
  PROJECT_STORE = "projects.store"
  DEBUG = ENV.fetch('DEBUG', false)
  INLINE_TIMER = ENV.fetch('INLINE_TIMER', true)

  def start_timer(description, project = nil)
    uri = URL_BASE + '/timeEntries/'
    params = {start: Time.now.utc.iso8601, description: description, billable: true}
    params.merge!(projectId: find_project(project)) if project

    RestClient.post(uri, params.to_json, HEADERS)
    puts params if DEBUG
    if INLINE_TIMER
      buff = []
      starting = Time.now

      counter = Thread.new do
        while true
          print "\r #{description} | #{project} | #{Time.at(Time.now - starting).utc.strftime('%H:%M:%S')}"
          sleep(1)
        end
      end

      while buff.empty?
        buff << STDIN.read(1)
      end

      counter.kill
      stop_timer
    end
  rescue StandardError 
    binding.pry
    puts 'There was an error with starting your timer.'
  end

  def stop_timer
    uri = URL_BASE + '/timeEntries/endStarted'
    params = {end: Time.now.utc.iso8601}
    RestClient.put(uri, params.to_json, HEADERS)
  rescue StandardError
    binding.pry if DEBUG
    puts 'There was an error with stopping your timer.'
  end

  private

    def find_project(project)
      found_project = if File.exists?("#{File.dirname(__FILE__)}/#{PROJECT_STORE}")
        store = YAML::Store.new "#{File.dirname(__FILE__)}/#{PROJECT_STORE}"
        projects = store.transaction {|store| store["projects"] }
        abbrevs = store.transaction {|store| store["abbrevs"] } 
        projects[abbrevs[project]]
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
          name = project.dig("name")
          id = project.dig("id")
          next unless name && id
          [name, id]
        end.compact.to_h
      
      store = YAML::Store.new "#{File.dirname(__FILE__)}/#{PROJECT_STORE}"

      store.transaction do
        store["projects"] = projects
        store["abbrevs"] = projects.keys.abbrev
      end

      [projects, projects.keys.abbrev]
    end
  
end
