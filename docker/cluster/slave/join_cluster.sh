rabbitmq-server &
rabbitmqctl wait /var/lib/rabbitmq/mnesia/rabbit\@$(hostname).pid
rabbitmqctl stop_app
rabbitmqctl join_cluster rabbit@master-rabbit
rabbitmqctl start_app
#tail -f /some/log/file.log
tail -f /dev/null