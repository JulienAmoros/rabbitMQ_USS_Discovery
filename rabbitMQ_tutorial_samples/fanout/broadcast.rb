#!/usr/bin/env ruby
require 'bunny'
require_relative '../../bunny_factory'

include BunnyFactory
connection = BunnyFactory::get_basic_connection
connection.start

channel = connection.create_channel
exchange = channel.fanout('logs')

message = ARGV.empty? ? 'Hello World!' : ARGV.join(' ')

exchange.publish(message)

puts " [x] Sent #{message}"

connection.close

