require 'date'
require 'bunny'
require 'concurrent'
require_relative 'utils'

$f_shield_state = 100

connection = Bunny.new(hostname: '172.17.0.2')
connection.start
$channel = connection.create_channel
# Creating permanent and exclusive queue for logs
$channel.queue('all_logs', durable: true)
# Creating Exchange for Severity Logs
$uss_broadcast_severity = $channel.direct('all_severity')
# Creating Exchange for label based selection
$uss_broadcast_topic = $channel.topic('all_types')

class Scheduler
  def initialize
    @scheduler = []
    @mutex = Mutex.new
  end

  def add(event)
    @mutex.synchronize do
      @scheduler << event
      @scheduler.sort! { |e1, e2| e1.time <=> e2.time}
    end
  end

  # return first event only if it happened
  def get_event
    @mutex.synchronize do
      @scheduler.shift if @scheduler.first.time < Time.now
    end
  end

  def empty?
    @scheduler.empty?
  end
end

class Event
  attr_reader :time, :message, :type

  def initialize(type, message, time)
    @type = type
    @message = message
    @time = time
  end

  def happens
    # Print event
    puts "[#{time}] #{get_color}#{get_severity.upcase}\e[0m - #{message}"
    log = Utils.generate_json(subject: message,
                              severity: get_severity.upcase,
                              timestamp: time.to_i)

    ### Part for rabbitMQ ###
    # Send permanent logging - default exchange is durable by default
    $channel.default_exchange.publish(log, routing_key: 'all_logs', persistent: true)

    # Send logs per severity to severity direct exchange
    $uss_broadcast_severity.publish(log, routing_key: get_severity)

    # Send logs per types to topic exchange
    $uss_broadcast_topic.publish(log, routing_key: type)

    # Subscribe to RPC queue
    subscribe_to_rpc_queue('uss_rpc')

    ### END part for rabbitMQ ###

    # Generate event
    generate_event
  end

  def generate_event
    if type == 'info.access' or type == 'starting'
      time = Time.new + Random.new.rand(1..5)
      characters = ['Captain Lorca', 'First Officer Burnham', 'Science Officer Saru', 'Chief Engineer Stamets', 'Cadet Tilly', 'Ambassador Sarek', 'Admiral Cornwell']
      rooms = ['Bridge', 'Personnal Quarter', 'Nursery', 'Laboratory', 'Technical Office', 'Dinner Room', 'Gym Room']

      character = characters[rand(characters.length)]
      room = rooms[rand(rooms.length)]

      $scheduler.add(Event.new('info.access', "#{character} has accessed #{room}", time))
    end

    if type.include? 'warning.defect' or type == 'starting'
      time = Time.new + Random.new.rand(6..15)

      type_names = ['Spore Drive System', 'Laser System', 'Deflector Shield System', 'Energy Storage system']
      type_labels = ['s_drive', 'laser', 'shield', 'energy']

      random = rand(type_names.length)
      type_name = type_names[random]
      type_label = type_labels[random]

      $scheduler.add(Event.new('warning.defect.' + type_label, "#{type_name} is disfunctionnal, sending repair drones.", time))
      $scheduler.add(Event.new('recovery.defect.' + type_label, "#{type_name} anomaly repaired.", time + Random.new.rand(2..5)))
    end

    if type == 'danger.enemy' or type == 'starting'
      time = Time.new + Random.new.rand(7..15)
      enemy_ships = ['Klingon', 'Romulan', 'Pirate']
      enemy_ship = enemy_ships[rand(enemy_ships.length)]
      $scheduler.add(Event.new('danger.enemy', "Ennemy ship (#{enemy_ship}) detected!", time))
      $scheduler.add(Event.new('danger.ennemy.engage', "#{enemy_ship} ship engaged.", time + 1))
      $scheduler.add(Event.new('info.start.shield', "Automatic shield startup.", time + 1))

      Random.new.rand(1..4).times do |i|
        $f_shield_state -= 20
        $scheduler.add(Event.new('warning.damage.shield', "Front shield state: #{$f_shield_state}%", time + i + 2))
      end

      $scheduler.add(Event.new('recovery.enemy', "#{enemy_ship} ship destroyed.", time + 6))

      $scheduler.add(Event.new('info', "Starting deflector shield's energy reload...", time + 6))
      unless $f_shield_state == 100
        steps = ((100 - $f_shield_state)/20)
        steps.times do |i|
          $f_shield_state += 20
          $scheduler.add(Event.new('info.repair.shield', "Front shield at #{$f_shield_state}%", time + i + 6))
        end
      $scheduler.add(Event.new('recovery.damage.shield', "Shields recovering over", time+ steps + 6))
      end
    end

    if type == 'black.jump.start' or type == 'starting'
      time = Time.new + Random.new.rand(30..32)

      $scheduler.add(Event.new('black.jump.start', 'Preparing Hyper Jump', time))
      $scheduler.add(Event.new('black.jump.over', 'Jumping over', Time.new + 1)) unless type == 'starting'
    end

    if type == 'destroy'
      $scheduler = []
    end
  end

  def get_color
    type = get_severity
    if type == 'info'
      "\e[34m"
    elsif type == 'warning'
      "\e[33m"
    elsif type == 'danger'
      "\e[91m"
    elsif type == 'black'
      "\e[90m"
    elsif type == 'recovery'
      "\e[32m"
    elsif type == 'starting' or type == 'destroy'
      "\e[35m"
    end
  end

  def get_severity
    type.split('.')[0]
  end

  def subscribe_to_rpc_queue(queue_name)
    # Creating queue for Remote Process Call
    @rpc_queue = $channel.queue(queue_name)

    # Subscribe to the queue
    @rpc_queue.subscribe(block: false) do |_delivery_info, properties, payload|
      # Add processing events to the scheduler
      $scheduler.add(Event.new('info.send.start', "Info Request #{payload} from #{properties.headers['origin']}", Time.new + 2))

      6.times do |i|
        $scheduler.add(Event.new('info.send.sending', "Sending #{payload} #{i*20}%", Time.new + i + 3))
      end

      $scheduler.add(Event.new('info.send.over', "Sent #{payload} to #{properties.headers['origin']}", Time.new + 8))

      # Simulate task processing
      task = Concurrent::TimerTask.new(execution_interval: 8, timeout_interval: 5) do
        $channel.default_exchange.publish(
            payload,
            routing_key: properties.reply_to,
            correlation_id: properties.correlation_id
        )
        task.shutdown
      end
      task.execute

    end
  end
end

$scheduler = Scheduler.new

$scheduler.add(Event.new('starting', 'CONNECTED TO USS-DISCOVERY EVENT LOG', Time.new))
# $scheduler.add(Event.new('destroy', 'USS_DISCOVERY SELF-ANIHILATION COMPLETED', Time.new + 60))


until $scheduler.empty?
  event = $scheduler.get_event
  unless event.nil?
    event.happens
  end
end

puts 'INFO - No system responding, USS-discovery is destroyed or universe doesn\'t exist anymore'
