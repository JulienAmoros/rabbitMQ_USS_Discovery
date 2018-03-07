#!/usr/bin/env ruby
require 'bunny'

connection = Bunny.new(hostname:  '172.17.0.2')
connection.start

channel = connection.create_channel
queue = channel.queue('logs', durable: true)

log_file = open('USS_logs.log', 'a')

begin
  puts ' [*] Waiting for messages from USS. To exit press CTRL+C'
  queue.subscribe(block: true) do |_delivery_info, _properties, body|
    p body
    log_file << "#{body}\n"
  end
rescue Interrupt => _
  connection.close
  log_file.close
  exit(0)
end