#!/usr/bin/env ruby
require 'bunny'
require_relative '../../bunny_factory'

include BunnyFactory
connection = BunnyFactory::get_basic_connection
connection.start

channel = connection.create_channel
queue = channel.queue('work', durable: true)
channel.prefetch(1)

puts ' [*] Waiting for messages. To exit press CTRL+C'

begin
  queue.subscribe(block: true) do |delivery_info, _properties, body|
    puts " [x] Received #{body}"
    # imitate some work
    sleep body.count('.').to_i
    puts " [x] Done #{body}"
    channel.ack(delivery_info.delivery_tag)
  end
rescue Interrupt =>
  connection.close
end
