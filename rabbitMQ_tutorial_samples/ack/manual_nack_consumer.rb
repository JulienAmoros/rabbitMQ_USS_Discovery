#!/usr/bin/env ruby
require 'bunny'
require_relative '../../bunny_factory'

include BunnyFactory
connection = BunnyFactory::get_basic_connection
connection.start

channel = connection.create_channel
channel.prefetch(1)
queue = channel.queue('man_ack')

begin
  puts ' [*] Waiting for messages. To exit press CTRL+C'
  queue.subscribe(block: true, manual_ack: true) do |_delivery_info, _properties, body|
    puts " [x] Processing #{body} (#{_delivery_info.delivery_tag})"
    channel.nack(_delivery_info.delivery_tag, false, true)
    puts 'Job failed'
  end
rescue Interrupt => _
  connection.close

  exit(0)
end