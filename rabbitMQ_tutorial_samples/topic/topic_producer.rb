#!/usr/bin/env ruby
require 'bunny'
require_relative '../../bunny_factory'

def declare_queue(rk)
  queue = $channel.queue(rk)
  queue.bind($exchange, routing_key: rk) # ignored if queue already bind like this
end

def send_message(rk)
  $exchange.publish(rk, routing_key: rk)
end

include BunnyFactory
connection = BunnyFactory::get_basic_connection
connection.start

$channel = connection.create_channel

$exchange = $channel.topic('test_topic')


declare_queue('docker')
declare_queue('docker.')
declare_queue('.docker')
declare_queue('.docker.')
declare_queue('docker#')
declare_queue('#docker')
declare_queue('#docker#')
declare_queue('docker.#')
declare_queue('#.docker')
declare_queue('#.docker.#')
declare_queue('#.docker.')
# declare_queue('#')

send_message('docker')
send_message('docker.')
send_message('.docker')
send_message('.docker.')
send_message('docker#')
send_message('#docker')
send_message('#docker#')
send_message('docker.#')
send_message('#.docker')
send_message('#.docker.#')
send_message('word.docker')
send_message('docker.word')
send_message('word.docker.word')

connection.close