# Remote Procedure call
# Earth starbase wants sometimes ask specific operations to its ships (get datas, execute procedures...)

require 'bunny'
require 'thread'
require_relative '../bunny_factory'

include BunnyFactory

class RPCClient
  attr_accessor :call_id, :response, :lock, :condition, :connection,
                :channel, :server_queue_name, :reply_queue, :exchange

  def initialize(server_queue_name, origin)
    @connection = BunnyFactory::get_basic_connection
    @connection.start

    @channel = connection.create_channel
    @exchange = channel.default_exchange
    @server_queue_name = server_queue_name

    @origin = origin

    setup_reply_queue
  end

  def call(procedure)
    @call_id = generate_uuid

    exchange.publish(procedure,
                     routing_key: server_queue_name,
                     correlation_id: call_id,
                     reply_to: reply_queue.name,
                     headers: {origin: @origin})

    # wait for the signal to continue the execution
    lock.synchronize { condition.wait(lock) }

    response
  end

  def stop
    channel.close
    connection.close
  end

  private

  def setup_reply_queue
    @lock = Mutex.new
    @condition = ConditionVariable.new
    that = self
    @reply_queue = channel.queue('', exclusive: true)

    reply_queue.subscribe do |_delivery_info, properties, payload|
      if properties[:correlation_id] == that.call_id
        that.response = payload

        # sends the signal to continue the execution of #call
        that.lock.synchronize { that.condition.signal }
      end
    end
  end

  def generate_uuid
    # very naive but good enough for code examples
    "#{rand}#{rand}#{rand}"
  end
end

client = RPCClient.new('uss_rpc', 'Earth Starbase')

ask_for = 'science_data'

puts " [x] Requesting #{ask_for}"
response = client.call(ask_for)

puts " [.] #{response} received!"