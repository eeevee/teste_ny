require 'socket'

class Client
	def initialize(port, name)
		@name = name
		@followers = []
		puts "my name #{@name}"
		@server = TCPSocket.open('localhost', port)
		send_name
		wait_events
	end

	def send_name
		@server.puts(@name + "\r\n")
	end

	def wait_events
		while line = @server.gets
			puts "recebeu evento: #{line.chop}"
		end
	end
end
