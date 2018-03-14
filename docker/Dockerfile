FROM rabbitmq:3-management

RUN mkdir /etc/ssl/private
# Copy rmq conf
COPY rabbitmq.conf /etc/rabbitmq/rabbitmq.conf
# Copy rmq cacert
COPY cacert.pem /etc/ssl/certs/rmq-cacert.pem
# Copy rmq server cert
COPY cert.pem /etc/ssl/certs/rmq-cert.pem
# Copy rmq key
COPY key.pem /etc/ssl/private/rmq-key.pem
# Copy Broker definition
COPY ./broker_definition.json /etc/rabbitmq/broker_definition.json