#!/usr/bin/env ruby
require 'bunny'

connection = Bunny.new(hostname: '172.17.0.2')
connection.start

channel = connection.create_channel

queue = channel.queue('hello')# , exclusive: true)

channel.default_exchange.publish('Hello World!', routing_key: queue.name)
puts " [x] Sent 'Hello World!'"

connection.close