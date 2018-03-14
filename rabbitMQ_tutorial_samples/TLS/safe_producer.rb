#!/usr/bin/env ruby
require 'bunny'
require_relative '../../bunny_factory'

include BunnyFactory

connection = BunnyFactory.get_encrypted_connection(vhost: 'secure_connection',
                                                   user: 'safe_producer',
                                                   pass: 'safe_producer')
connection.start

channel = connection.create_channel

queue = channel.queue('safe_test')

channel.default_exchange.publish('Hello World!', routing_key: queue.name)
puts " [x] Sent 'Hello World!'"

connection.close