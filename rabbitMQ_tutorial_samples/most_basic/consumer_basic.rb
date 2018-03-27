#!/usr/bin/env ruby
require 'bunny'

connection = Bunny.new(hostname: '172.18.1.2')
connection.start

channel = connection.create_channel # get a channel to communicate

queue = channel.queue('hello') # get or create queue

begin
  puts ' [*] Waiting for messages. To exit press CTRL+C'
  queue.subscribe(block: true) do |_delivery_info, _properties, body| # start listening
    # Do this when a message is received
    puts " [x] Received #{body}"
  end
rescue Interrupt => _
  puts "\nCTRL+C received, closing program."
ensure
  connection.close
  exit(0)
end
