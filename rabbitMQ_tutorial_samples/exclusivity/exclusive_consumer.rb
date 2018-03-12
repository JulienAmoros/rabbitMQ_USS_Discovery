#!/usr/bin/env ruby
require 'bunny'

connection = Bunny.new(hostname:  '172.17.0.2')
connection.start

channel = connection.create_channel
queue = channel.queue('hello')# , exclusive: true)

begin
  puts ' [*] Waiting for messages. To exit press CTRL+C'
  queue.subscribe(block: true, exclusive: true) do |_delivery_info, _properties, body|
    puts " [x] Received #{body}"
  end
rescue Interrupt => _
  connection.close

  exit(0)
end