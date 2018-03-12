#!/usr/bin/env ruby
require 'bunny'

connection = Bunny.new(hostname:  '172.17.0.2')
connection.start

channel = connection.create_channel
channel.prefetch(1)
queue = channel.queue('man_ack')

begin
  puts ' [*] Waiting for messages. To exit press CTRL+C'
  queue.subscribe(block: true, manual_ack: true) do |_delivery_info, _properties, body|
    puts " [x] Processing #{body} (#{_delivery_info.delivery_tag})"
    channel.reject(_delivery_info.delivery_tag, requeue: true)
    puts 'Job failed'
  end
rescue Interrupt => _
  connection.close

  exit(0)
end