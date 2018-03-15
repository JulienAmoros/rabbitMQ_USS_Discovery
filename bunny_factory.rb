module BunnyFactory
  $rabbitmq_ip = '172.18.1.2'
  $rabbitmq_ssl_port = 5671
  $root_dir = __dir__[0..__dir__.index('rabbitMQ_test')-1]

  def get_basic_connection(**args)
    args[:hostname] ||= $rabbitmq_ip
    Bunny.new(**args)
  end

  def get_encrypted_connection(**args)
    args[:hostname] ||= $rabbitmq_ip
    args[:port] ||= $rabbitmq_ssl_port
    Bunny.new(tls: true,
              tls_cert: $root_dir + 'rabbitMQ_test/TLS/client1/cert.pem',
              tls_key: $root_dir + 'rabbitMQ_test/TLS/client1/key.pem',
              tls_ca_certificates: [$root_dir + 'rabbitMQ_test/TLS/cacert.pem'],
              verify_peer: true,
              **args)
  end
end