#!/usr/bin/env ruby
require 'bunny'

connection = Bunny.new(hostname:  '172.17.0.2')
connection.start

channel = connection.create_channel
exchange = channel.fanout('logs')

message = ARGV.empty? ? 'Hello World!' : ARGV.join(' ')

exchange.publish(message)

puts " [x] Sent #{message}"

connection.close

