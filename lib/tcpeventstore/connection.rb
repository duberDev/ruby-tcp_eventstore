require 'socket'
require 'logger'

module TcpEventStore
  class Connection
    # @param [String] host
    # @param [Fixnum] port
    # @param [Logger] logger
    def initialize(host, port, logger: nil)
      @host = host
      @port = port
      @mutex = Mutex.new
      @callbacks = {}
      if logger.nil?
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::ERROR
      else
        @logger = logger
      end
    end

    def connect
      log(Logger::INFO) { "Connecting to #{@host}:#{@port}" }

      begin
        @socket = TCPSocket.new(@host, @port)
        @connected = true
      rescue => err
        log(Logger::ERROR) { err.to_s }
      end

      reader
      @socket.nil?
    end

    # @param [String] stream
    # @param [Fixnum] expected_version
    # @param [Array<EventData>] events
    # @param [Proc] block
    # @return [NilClass, Protobuf::WriteEventsCompleted]
    def append_to_stream(stream, expected_version, events, &block)
      dto = Protobuf::WriteEvents.new
      dto.event_stream_id = stream
      dto.expected_version = expected_version
      events.each do |event|
        new_event = Protobuf::NewEvent.new
        new_event.event_id = event.id
        new_event.event_type = event.type
        new_event.data_content_type = event.is_json ? 1 : 0
        new_event.metadata_content_type = 0
        new_event.data = event.data.encode('ASCII-8BIT')
        new_event.metadata = event.metadata.encode('ASCII-8BIT')
        dto.events.push(new_event)
      end
      dto.require_master = false

      send_command(Data::TcpCommand::WRITE_EVENTS, dto, block)
    end

    # @param [String] stream
    # @param [Integer] start
    # @param [Integer] max
    # @param [Proc] block
    # @return [Nil, Protobuf::ReadStreamEventsCompleted]
    def read_stream_events_forward(stream, start, max, &block)
      dto = Protobuf::ReadStreamEvents.new
      dto.event_stream_id = stream
      dto.from_event_number = start
      dto.max_count = max
      dto.resolve_link_tos = false
      dto.require_master = false

      send_command(Data::TcpCommand::READ_STREAM_EVENTS_FORWARD, dto, block)
    end

    # @param [String] stream
    # @param [Proc] block
    # @return [String] Correlation id bytes (used to unsubscribe)
    def subscribe_to_stream(stream, &block)
      raise 'Block is required' unless block_given?

      dto = Protobuf::SubscribeToStream.new
      dto.event_stream_id = stream
      dto.resolve_link_tos = false

      correlation_id = UUID::generate

      send_command(Data::TcpCommand::SUBSCRIBE_TO_STREAM, dto, block, correlation_id)

      correlation_id
    end

    # @param [String] correlation_id
    # @return [NilClass]
    def unsubscribe_from_stream(correlation_id)
      dto = Protobuf::UnsubscribeFromStream.new

      send_command(Data::TcpCommand::UNSUBSCRIBE_FROM_STREAM, dto, @callbacks[correlation_id], correlation_id)
    end

    private

    # @param [Fixnum] cmd
    # @param [Object] proto
    # @param [Proc] callback
    # @return [Object] Nil or response dto
    def send_command(cmd, proto, callback, correlation_id = nil)
      if correlation_id.nil?
        correlation_id = UUID::generate
      end

      q = nil
      if callback.nil?
        q = Queue.new
        @callbacks[correlation_id] = lambda { |r| q.push r }
      else
        @callbacks[correlation_id] = callback
      end

      send_packet(Data::TcpPacket.new(cmd, 0, correlation_id, nil, nil, proto.to_proto))

      return nil if q.nil?
      q.pop
    end

    def reader
      @reader = Thread.new do
        loop do
          begin
            data = @socket.recv_nonblock(4096)
            on_data(data)
          rescue IO::WaitReadable
            IO::select([@socket], [@socket])
            retry
          rescue => err
            log(Logger::INFO) { 'Connection lost: ' + err.to_s }
            break
          end
        end

        until @connected
          sleep(3)
          connect
        end
      end
    end

    # @param [String] data
    def on_data(data)
      unless @leftover.nil? || @leftover.length == 0
        data = @leftover << data
      end

      if data.length < 4
        @leftover = data
        return
      end

      content_length = data[0, 4].unpack('V')[0]
      packet_size = content_length + 4
      if data.length == packet_size
        process(Data::TcpPacket.from_bytes(data[4..-1]))
      elsif data.length > packet_size
        on_data(data[0..packet_size])
        on_data(data[packet_size..-1])
      else
        @leftover = data
      end
    end

    # @param [TcpPacket] packet
    def process(packet)
      log(Logger::DEBUG) {
        'Received command: ' + packet.command.to_s +
            ' | Correlation Id: ' + packet.correlation_id.bytes.to_s
      }

      callback = @callbacks[packet.correlation_id]
      case packet.command
        when Data::TcpCommand::HEARTBEAT_REQUEST_COMMAND then
          send_packet(Data::TcpPacket.new(Data::TcpCommand::HEARTBEAT_RESPONSE_COMMAND,
                                    0, packet.correlation_id, nil, nil, ''))
        when Data::TcpCommand::WRITE_EVENTS_COMPLETED then
          callback.call(Protobuf::WriteEventsCompleted.decode(packet.payload))
          @callbacks.delete(packet.correlation_id)
        when Data::TcpCommand::READ_STREAM_EVENTS_FORWARD_COMPLETED then
          callback.call(Protobuf::ReadStreamEventsCompleted.decode(packet.payload))
          @callbacks.delete(packet.correlation_id)
        when Data::TcpCommand::SUBSCRIPTION_CONFIRMATION then
          callback.call(Protobuf::SubscriptionConfirmation.decode(packet.payload))
        when Data::TcpCommand::STREAM_EVENT_APPEARED then
          callback.call(Protobuf::StreamEventAppeared.decode(packet.payload))
        when Data::TcpCommand::SUBSCRIPTION_DROPPED then
          callback.call(Protobuf::SubscriptionDropped.decode(packet.payload))
          @callbacks.delete(packet.correlation_id)
        when Data::TcpCommand::BAD_REQUEST then
          callback.call('BadRequest')
          @callbacks.delete(packet.correlation_id)
        else
          log(Logger::INFO) { 'Not supported' }
      end
    end

    def send_packet(packet)
      log(Logger::DEBUG) {
        'Sending command: ' + packet.command.to_s +
            ' | Correlation Id: ' + packet.correlation_id.bytes.to_s
      }

      data = [packet.size].pack('V') + packet.bytes
      begin
        @socket.write_nonblock(data)
      rescue IO::WaitWritable, Errno::EINTR
        IO.select([@socket], [@socket])
        retry
      rescue => err
        log(Logger::ERROR) { err.to_s }
      end
    end

    # @param [Fixnum] severity
    # @param [Proc] block
    def log(severity, &block)
      @logger.add(severity, nil, 'TcpEventStore') { block.call }
    end
  end
end