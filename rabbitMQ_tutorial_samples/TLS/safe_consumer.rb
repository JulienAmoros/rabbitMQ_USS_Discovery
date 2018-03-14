#!/usr/bin/env ruby
require 'bunny'
require_relative '../../bunny_factory'

include BunnyFactory

connection = BunnyFactory.get_encrypted_connection(vhost: 'secure_connection',
                                                   user: 'safe_consumer',
                                                   pass: 'safe_consumer')
connection.start

channel = connection.create_channel
queue = channel.queue('safe_test')

begin
  puts ' [*] Waiting for messages. To exit press CTRL+C'
  queue.subscribe(block: true) do |_delivery_info, _properties, body|
    puts " [x] Received #{body}"
  end
rescue Interrupt => _
  connection.close

  exit(0)
end