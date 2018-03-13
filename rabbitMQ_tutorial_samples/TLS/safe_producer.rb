#!/usr/bin/env ruby
require 'bunny'

#gem install bunny --version ">= 2.6.4"

connection = Bunny.new(hostname: '172.17.0.2')
connection.start

channel = connection.create_channel

queue = channel.queue('hello')

channel.default_exchange.publish('Hello World!', routing_key: queue.name)
puts " [x] Sent 'Hello World!'"

connection.close