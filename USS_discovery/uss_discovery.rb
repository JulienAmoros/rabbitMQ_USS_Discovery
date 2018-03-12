require 'date'
require 'bunny'
require 'concurrent'
require_relative 'utils'

$scheduler = []
$f_shield_state = 100

connection = Bunny.new(hostname: '172.17.0.2')
connection.start
$channel = connection.create_channel
$uss_broadcast_severity = $channel.direct('all_severity')
$uss_broadcast_topic = $channel.topic('all_types')

mutex = Mutex.new

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
    # Creating permanent and exclusive queue for logs
    $channel.queue('all_logs', durable: true)
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

      $scheduler << Event.new('info.access', "#{character} has accessed #{room}", time)
    end

    if type.include? 'warning.defect' or type == 'starting'
      time = Time.new + Random.new.rand(6..15)

      type_names = ['Spore Drive System', 'Laser System', 'Deflector Shield System', 'Energy Storage system']
      type_labels = ['s_drive', 'laser', 'shield', 'energy']

      random = rand(type_names.length)
      type_name = type_names[random]
      type_label = type_labels[random]

      $scheduler << Event.new('warning.defect.' + type_label, "#{type_name} is disfunctionnal, sending repair drones.", time)
      $scheduler << Event.new('recovery.defect.' + type_label, "#{type_name} anomaly repaired.", time + Random.new.rand(2..5))
    end

    if type == 'danger.enemy' or type == 'starting'
      time = Time.new + Random.new.rand(7..15)
      enemy_ships = ['Klingon', 'Romulan', 'Pirate']
      enemy_ship = enemy_ships[rand(enemy_ships.length)]
      $scheduler << Event.new('danger.enemy', "Ennemy ship (#{enemy_ship}) detected!", time)
      $scheduler << Event.new('danger.ennemy.engage', "#{enemy_ship} ship engaged.", time + 1)
      $scheduler << Event.new('info.start.shield', "Automatic shield startup.", time + 1)

      Random.new.rand(1..4).times do |i|
        $f_shield_state -= 20
        $scheduler << Event.new('warning.damage.shield', "Front shield state: #{$f_shield_state}%", time + i + 2)
      end

      $scheduler << Event.new('recovery.enemy', "#{enemy_ship} ship destroyed.", time + 6)

      $scheduler << Event.new('info', "Starting deflector shield's energy reload...", time + 6)
      unless $f_shield_state == 100
        steps = ((100 - $f_shield_state)/20)
        steps.times do |i|
          $f_shield_state += 20
          $scheduler << Event.new('info.repair.shield', "Front shield at #{$f_shield_state}%", time + i + 6)
        end
      $scheduler << Event.new('recovery.damage.shield', "Shields recovering over", time+ steps + 6)
      end
    end

    if type == 'black.jump.start' or type == 'starting'
      time = Time.new + Random.new.rand(30..32)

      $scheduler << Event.new('black.jump.start', 'Preparing Hyper Jump', time)
      $scheduler << Event.new('black.jump.over', 'Jumping over', Time.new + 1) unless type == 'starting'
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
      # puts payload + ' time: ' + Time.new.to_s
      # Add processing events to the scheduler
        $scheduler << Event.new('info.send.start', "Info Request #{payload} from Earth #{}", Time.new + 2)

        6.times do |i|
          $scheduler << Event.new('info.send.sending', "Sending #{payload} #{i*20}%", Time.new + i + 3)
        end

        $scheduler << Event.new('info.send.over', "Sent #{payload} to Earth Starbase", Time.new + 8)

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


$scheduler << Event.new('starting', 'CONNECTED TO USS-DISCOVERY EVENT LOG', Time.new)
# $scheduler << Event.new('destroy', 'USS_DISCOVERY SELF-ANIHILATION COMPLETED', Time.new + 60)


until $scheduler.empty?
  $scheduler.sort! { |e1, e2| e1.time <=> e2.time}
  if $scheduler.first.time < Time.now
    $scheduler.first.happens
    $scheduler.shift
  end
end

puts 'INFO - No system responding, USS-discovery is destroyed or universe doesn\'t exist anymore'
