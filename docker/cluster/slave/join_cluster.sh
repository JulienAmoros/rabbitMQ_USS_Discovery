rabbitmq-server &
rabbitmqctl wait /var/lib/rabbitmq/mnesia/rabbit\@$(hostname).pid
rabbitmqctl stop_app
rabbitmqctl join_cluster rabbit@master-rabbit
rabbitmqctl start_app
#tail -f /var/log/rabbitmq/rabbit*.log
# Kind of shitty but works, please PR if you have anything better (container shuts down otherwise)
while true; do
sleep 10
done