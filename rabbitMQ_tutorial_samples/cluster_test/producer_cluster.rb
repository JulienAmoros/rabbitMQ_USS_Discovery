#!/usr/bin/env ruby
require 'bunny'
require_relative '../../bunny_factory'

include BunnyFactory
connection = BunnyFactory::get_basic_connection(hostname: '172.18.1.3')
connection.start

channel = connection.create_channel

queue = channel.queue('hello')

channel.default_exchange.publish('Hello World!', routing_key: queue.name)
puts " [x] Sent 'Hello World!'"

connection.close