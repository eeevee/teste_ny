require 'socket'

class Server
  def initialize(client_port, event_source_port)
    @started_receive = false
    @total = 0
    @time_start = Time.now
    @events = []
    @clients = {}
    @followers = {}
    t2 = Thread.new{@source_server = TCPServer.open(event_source_port)}
    t1 = Thread.new {@client_server = TCPServer.open(client_port)}
    t1.join
    t1.join
  end

  def run
    t1 = Thread.new {
      loop do
        source = @source_server.accept
        while line = source.gets
          @started_receive = true
          event_received = line.chomp
          #puts "recebeu evento: " + event_received
          buffer_events event_received
        end
      end
    }

    t2 = Thread.new {
      loop do
        Thread.start(@client_server.accept) do |client|
          nickname = client.gets.chomp
          if not @clients.key?(nickname)
            @clients[nickname] = client
            #puts nickname + " entrou na sala"
          end
        end   
      end
    }

    t3 = Thread.new {
      loop do
        Thread.start(get_elapsed_time_since_last_notification(Time.now)) do |diff|
          if diff > 1 and @started_receive
            @started_receive = false
            @events = @events - [nil]
            @i = 1
            puts @events.to_s
            @events.each do |event|
              parse_and_send_event event
              sleep(1)
            end
          end
        end
      end
    }
    t1.join
    t2.join
    t3.join
  end

  def get_elapsed_time_since_last_notification time_finish
    if @started_receive
      sleep 1
      (time_finish - @time_start) * 1000
    end
  end

  def buffer_events event
    event_parsed = event.split('|')
    @events[event_parsed[0].to_i] = event
    @time_start = Time.now
  end

  def parse_and_send_event event
    event_parsed = event.split('|')
    puts "colocando na roda evento #{event_parsed[0]} : #{event}"
    case event_parsed[1]
    when "B"
      @clients.each do |key, client|
        #puts "#broadcast para #{key} : #{event}"
        send_event "#{event_parsed[0]}|" + event_parsed[1], key
      end
    when "P"
      #puts "#{event_parsed[2]} esta falando pvt com #{event_parsed[3]} : #{event}"
      send_event "#{event_parsed[0]}|" + event_parsed[1], event_parsed[3]
    when "F"
      add_client_follower(event_parsed[2], event_parsed[3])
      send_event("#{event_parsed[0]}|" + event_parsed[1], event_parsed[3])
    when "U"
      remove_client_follower event_parsed[2], event_parsed[3]
    when "S"
        notify_client_followers event_parsed[2], "#{event_parsed[0]}|" + event_parsed[1]
    end
  end

  def add_client_follower client, follower
    if not @followers.key?(client)
      @followers[client] = []
    end
    if not @followers[client].include?(follower.to_s) 
      @followers[client] << follower.to_s
    end
  end

  def remove_client_follower client, follower
    if @followers.key?(client)
      if @followers[client].include?(follower) 
        @followers[client].delete(follower)
        #puts "#{follower} deixou de seguir #{client} : #{event}"
      end
    end
  end

  def notify_client_followers client, event
    if @followers.key?(client)
      @followers[client].each do |f|
        @clients[f].puts(event + "\r\n")
        #puts "#{f} esta recebendo modificacao de status de #{client} : #{event}"
      end
    end
  end

  def send_event event, client_name
    if @clients.key?(client_name)
      @clients[client_name].puts(event + "\r\n")
    end
  end
end



server = Server.new(9099, 9090)
server.run