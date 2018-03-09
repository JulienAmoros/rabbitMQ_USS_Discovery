#!/usr/bin/env ruby
require 'bunny'
require_relative 'utils'

connection = Bunny.new(hostname:  '172.17.0.2')
connection.start

channel = connection.create_channel
exchange = channel.topic('all_types')
queue = channel.queue('', auto_delete: true)

queue.bind(exchange, routing_key: '#.shield')


begin
  puts ' [*] Waiting for messages from USS. To exit press CTRL+C'
  queue.subscribe(block: true) do |_delivery_info, _properties, body|
    puts Utils.generate_log(body)
    # Make some statistics
  end
rescue Interrupt => _
  connection.close

  exit(0)
end
