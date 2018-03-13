#!/usr/bin/env ruby
require 'bunny'

connection = Bunny.new(hostname:  '172.18.1.2',
                       port: 5671,
                       tls: true,
                       tls_cert: '../../TLS/client1/cert.pem',
                       tls_key: '../../TLS/client1/key.pem',
                       tls_ca_certificates: ['../../TLS/cacert.pem'],
                       verify_peer: true)
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