#!/usr/bin/env ruby
require 'bunny'
require_relative '../../bunny_factory'

$i = 1

def sub_to_queue(rk)
  queue = $channel.queue(rk)
  queue.subscribe(block: false) do |_delivery_info, _properties, body|
    puts " [#{$i}] Queue with topic binding '#{rk}' received message with routing_key: #{body}"
    $i+=1
  end
end

include BunnyFactory
connection = BunnyFactory::get_basic_connection
connection.start

$channel = connection.create_channel

begin
  sub_to_queue('docker')
  sub_to_queue('docker.')
  sub_to_queue('.docker')
  sub_to_queue('.docker.')
  sub_to_queue('docker.#')
  sub_to_queue('#.docker')
  sub_to_queue('docker#')
  sub_to_queue('#docker')
  sub_to_queue('#.docker.#')
  sub_to_queue('#.docker.')
  # sub_to_queue('#')

  while true
  end
rescue Interrupt => _
  puts "\nCTRL+C received, closing program."
ensure
  connection.close
  exit(0)
end
