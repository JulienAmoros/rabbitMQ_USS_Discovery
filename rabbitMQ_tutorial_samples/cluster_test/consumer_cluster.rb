#!/usr/bin/env ruby
require 'bunny'
require_relative '../../bunny_factory'

include BunnyFactory
connection = BunnyFactory::get_basic_connection(hostname: '172.18.1.3')

connection.start

channel = connection.create_channel
queue = channel.queue('hello')

begin
  puts ' [*] Waiting for messages. To exit press CTRL+C'
  queue.subscribe(block: true) do |_delivery_info, _properties, body|
    puts " [x] Received #{body}"
  end
rescue Interrupt => _
  connection.close

  exit(0)
end