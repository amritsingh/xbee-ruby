=begin

This file is part of the xbee-ruby gem.

Copyright 2013-2014 Dirk Grappendorf, www.grappendorf.net

Licensed under the The MIT License (MIT)

=end

require 'xbee-ruby/packet'

module XBeeRuby

	class XBee

		# Either specify the port and serial parameters
		#
		#   xbee = XBeeRuby::Xbee.new port: '/dev/ttyUSB0', rate: 9600
		#
		# or pass in a SerialPort like object
		#
		#   xbee = XBeeRuby::XBee.new serial: some_serial_mockup_for_testing
		#
		def initialize port: '/dev/ttyUSB0', rate: 9600, serial: nil, data_bits: 8, stop_bits: 1, parity: SerialPort::NONE, flow_control: SerialPort::NONE, api_mode: Packet::API_MODE_2
			@port = port
			@rate = rate
			@data_bits = data_bits
			@stop_bits = stop_bits
			@parity = parity
			@flow_control = flow_control
			@serial = serial
			@api_mode = api_mode
			@connected = false
			@logger = nil
		end

		def open
			@serial ||= SerialPort.new @port, @rate, @data_bits, @stop_bits, @parity
			@serial.flow_control = @flow_control
			Packet.set_api_mode @api_mode
			@serial_input = Enumerator.new { |y| loop do
				y.yield @serial.readbyte
			end }
			@connected = true
		end

		def close
			@serial.close if @serial
			@connected = false
		end

		def connected?
			@connected
		end

		alias :open? :connected?

		def write_packet packet
			@serial.write packet.bytes_escaped.pack('C*').force_encoding('ascii')
			@serial.flush
		end

		def write_request request
			write_packet request.packet
			log { "Packet sent: #{request.packet.bytes.map { |b| b.to_s(16) }.join(',')}" }
		end

		def read_packet
			Packet.from_byte_enum(@serial_input).tap do |packet|
				log { "Packet received: #{packet.bytes.map { |b| b.to_s(16) }.join(',')}" }
			end
		end

		def read_response
			Response.from_packet read_packet
		end

		def serial= io
			@serial = io
		end

		def logger= logger
			@logger = logger
		end

		def log
			@logger.call yield if @logger
		end
	end

end
