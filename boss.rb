#!/usr/bin/env ruby
require 'bunny'

connection = Bunny.new(hostname: '172.17.0.2')
connection.start

channel = connection.create_channel

queue = channel.queue('work', durable: true)

# data = '{param1: "arg1", param2: "arg2"}'
data = ARGV.empty? ? 'Hello World!' : ARGV.join(' ')

channel.default_exchange.publish(data , routing_key: queue.name, persistent: true)
puts " [x] Sent #{data}"

connection.close