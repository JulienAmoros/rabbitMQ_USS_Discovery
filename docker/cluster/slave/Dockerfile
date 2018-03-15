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
# Copy startup script
COPY join_cluster.sh /join_cluster.sh
RUN chmod +x /join_cluster.sh

COPY erlang.cookie /var/lib/rabbitmq/.erlang.cookie
RUN chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie \
&& chmod 400 /var/lib/rabbitmq/.erlang.cookie

CMD /join_cluster.sh