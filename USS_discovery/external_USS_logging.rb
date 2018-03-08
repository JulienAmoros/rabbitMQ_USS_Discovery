#!/usr/bin/env ruby
require 'bunny'

connection = Bunny.new(hostname:  '172.17.0.2')
connection.start

channel = connection.create_channel
queue = channel.queue('all_logs', durable: true, exclusive: true)

log_file = open('USS_logs.log', 'a')

timer = Time.now + 5

begin
  puts ' [*] Waiting for messages from USS. To exit press CTRL+C'
  queue.subscribe(block: true) do |_delivery_info, _properties, body|
    p body
    log_file << "#{body}\n"

    if Time.now < timer
      timer = timer = Time.now + 5
      log_file.flush
    end
  end
rescue Interrupt => _
  connection.close
  log_file.close
  exit(0)
end