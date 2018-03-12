#!/usr/bin/env ruby
require 'bunny'

class FibonacciServer
  def initialize
    @connection = Bunny.new(hostname: '172.17.0.2')
    @connection.start
    @channel = @connection.create_channel
  end

  def start(queue_name)
    @queue = channel.queue(queue_name)
    @exchange = channel.default_exchange
    subscribe_to_queue
  end

  def stop
    channel.close
    connection.close
  end

  private

  attr_reader :channel, :exchange, :queue, :connection

  def subscribe_to_queue
    queue.subscribe(block: true) do |_delivery_info, properties, payload|
      puts " [x] Got request: Fibonnacci(#{payload})"
      result = fibonacci(payload.to_i)
      sleep 3

      exchange.publish(
          result.to_s,
          routing_key: properties.reply_to,
          correlation_id: properties.correlation_id
      )

      puts " [x] Answered to Fibonnacci(#{payload}) = #{result}"
    end
  end

  def fibonacci(value)
    return value if value.zero? || value == 1

    fibonacci(value - 1) + fibonacci(value - 2)
  end
end

begin
  server = FibonacciServer.new

  puts ' [x] Awaiting RPC requests'
  server.start('rpc_queue')
rescue Interrupt => _
  server.stop
end