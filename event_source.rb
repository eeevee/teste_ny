require 'socket'

class EventSource
	def initialize(port)
		@server = TCPSocket.open('localhost', port)		

		events = ["666|F|222|111\r\n", "1|U|222|111\r\n", "542532|B\r\n", "43|P|32|111\r\n", "634|S|111\r\n",
					"666|F|111|222\r\n", "1|U|111|222\r\n", "542532|B\r\n", "43|P|32|222\r\n", "634|S|222\r\n"]
		loop do
			event = events.sample
			puts "enviando evento " + event + "\r\n"
			@server.puts(event + "\r\n")
			sleep 2
		end
	end
end

source = EventSource.new(9090)