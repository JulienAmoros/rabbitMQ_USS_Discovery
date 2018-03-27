#!/usr/bin/env ruby
require 'bunny'
require_relative '../../bunny_factory'

include BunnyFactory
connection = BunnyFactory::get_basic_connection
connection.start

channel = connection.create_channel

queue = channel.queue('work', durable: true)

data = ARGV.empty? ? 'Hello World.' : ARGV.join(' ')

channel.default_exchange.publish(data , routing_key: queue.name)
puts " [x] Sent #{data}"

connection.close