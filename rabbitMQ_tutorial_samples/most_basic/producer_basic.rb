#!/usr/bin/env ruby
require 'bunny'

connection = Bunny.new(hostname: '172.18.1.2')
connection.start

channel = connection.create_channel

queue = channel.queue('hello') # Get or create the queue

default_exchange = channel.default_exchange # get the default exchange

default_exchange.publish('Hello World!',
                 routing_key: queue.name) # publish message

puts " [x] Sent 'Hello World!'"

connection.close
