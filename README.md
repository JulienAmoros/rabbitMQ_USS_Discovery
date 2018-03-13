# Welcome to USS_Discovery!
This project is an event generator based on Star Trek Universe. The purpose is generating events to study RabbitMQ functionnalities.

## Prerequisites
Install ruby 2.4.1.
Install RabbitMQ on your network or your computer (you can use docker image: https://hub.docker.com/_/rabbitmq/ ).
I recommend the management plugin system in order to be able to view through a webpage what's going on on your RabbitMQ instance.
```
docker run -d --hostname my-rabbit --name some-rabbit -p 8080:15672 rabbitmq:3-management
```
Login/password: guest/guest

Once installed, don't forget to modify client's host field ('hostname:' while instanciating bunny client)
with the IP of your RabbitMQ instance.

## Running the project
In folder USS_discovery, uss_discovery.rb is the event generator, external_USS_logging.rb is the general
logging system (just using queue), uss_recovery_stats.rb use the direct exchange (with temporary queue)
and uss_shield_status_logging.rb uses topic type exchange with temporary queue. Finally, earth_starbase.rb
is an example of client for Remote Procedure Call (see [RPC in ruby](https://www.rabbitmq.com/tutorials/tutorial-six-ruby.html))

## TLS support
In `docker/` folder, you'll find a custom Docker image builder for enabling TLS communication in RabbitMQ.