require 'date'
require 'bunny'

$scheduler = []
$jumping = false
$engaged = false
$f_shield_state = 100

connection = Bunny.new(hostname: '172.17.0.2')
connection.start
$channel = connection.create_channel
$uss_broadcast = $channel.direct('all')

class Event
  attr_reader :time, :message, :type

  def initialize(type, message, time)
    @type = type
    @message = message
    @time = time
  end

  def happens
    # Print event
    color = get_color
    puts "[#{time}] #{color}#{type.upcase}\e[0m - #{message}"
    log = "[#{time}] #{type.upcase} - #{message}"

    ### Part for rabbitMQ ###
    # Send permanent logging
    queue = $channel.queue('logs', durable: true)
    $channel.default_exchange.publish(log, routing_key: queue.name)

    $uss_broadcast.publish(log, routing_key: type)

    # Generate event
    generate_event
  end

  def generate_event
    if @type == 'info' or @type == 'starting'
      time = Time.new + Random.new.rand(1..5)
      characters = ['Captain Lorca', 'First Officer Burnham', 'Science Officer Saru', 'Chief Engineer Stamets', 'Cadet Tilly', 'Ambassador Sarek', 'Admiral Cornwell']
      rooms = ['Bridge', 'Personnal Quarter', 'Nursery', 'Laboratory', 'Technical Office', 'Dinner Room', 'Gym Room']

      character = characters[rand(characters.length)]
      room = rooms[rand(rooms.length)]

      $scheduler << Event.new('info', "#{character} has accessed #{room}", time)
    end

    if @type == 'warning' or @type == 'starting'
      time = Time.new + Random.new.rand(6..15)

      type = ['Spore Drive System', 'Laser System', 'Deflector Shield System', 'Energy Storage system']
      $system_problem = type[rand(type.length)]

      $scheduler << Event.new('warning', "#{$system_problem} is disfunctionnal, sending repair drones.", time)
      $scheduler << Event.new('recovery', "#{$system_problem} anomaly repaired.", time + Random.new.rand(2..5))
    end

    if @type == 'danger' or @type == 'starting'
      time = Time.new + Random.new.rand(7..15)
      unless $engaged
        enemy_ships = ['Klingon', 'Romulan', 'Pirate']
        $enemy_ship = enemy_ships[rand(enemy_ships.length)]
        $scheduler << Event.new('danger', "Ennemy ship (#{$enemy_ship}) detected!", time)
        $engaged = true
      else
        $scheduler << Event.new('danger', "#{$enemy_ship} ship engaged.", Time.new + 1)
        $scheduler << Event.new('info', "Automatic shield startup.", Time.new + 1)

        Random.new.rand(1..4).times do |i|
          $f_shield_state -= 20
          $scheduler << Event.new('warning', "Front shield state: #{$f_shield_state}%", Time.new + i)
        end

        $scheduler << Event.new('recovery', "#{$enemy_ship} ship destroyed.", Time.new + 4)
        $engaged = false
      end
    end

    if @type == 'black' or @type == 'starting'
      time = Time.new + Random.new.rand(30..32)

      if not $jumping
        $scheduler << Event.new('black', 'Preparing Hyper Jump', time)
      else
        $scheduler << Event.new('black', 'Jumping over', Time.new + 1)
      end
      $jumping = !$jumping
    end

    if @type == 'recovery'
      unless $f_shield_state == 100
        $scheduler << Event.new('info', "Starting deflector shield's energy reload...", Time.new)
        steps = ((100 - $f_shield_state)/20)
        steps.times do |i|
          $f_shield_state += 20
          $scheduler << Event.new('info', "Front shield at #{$f_shield_state}%", Time.new + i + 1)
        end
        $scheduler << Event.new('recovery', "Shields recovering over", Time.new + steps + 1)
      end
    end
  end

  def get_color
    if @type == 'info'
      "\e[34m"
    elsif @type == 'warning'
      "\e[33m"
    elsif @type == 'danger'
      "\e[91m"
    elsif @type == 'black'
      "\e[90m"
    elsif @type == 'recovery'
      "\e[32m"
    end
  end
end


$scheduler << Event.new('starting', 'CONNECTED TO USS-DISCOVERY EVENT LOG', Time.new)


until $scheduler.empty?
  $scheduler.sort! { |e1, e2| e1.time <=> e2.time}
  if $scheduler.first.time < Time.now
    $scheduler.first.happens
    $scheduler.shift
  end
end

puts 'INFO - No system responding, USS-discovery is destroyed or universe doesn\'t exist anymore'