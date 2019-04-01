require_relative 'clockify'

args = ARGV[0, 2]

Clockify.new.start_timer(*args)
