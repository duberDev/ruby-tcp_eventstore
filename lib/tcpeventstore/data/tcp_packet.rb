module TcpEventStore
  module Data
    class TcpPacket
      CONTENT_LENGTH_SIZE = 4
      COMMAND_POS = 0
      AUTH_FLAG_POS = 1
      CORRELATION_ID_POS = 2
      PAYLOAD_POS = 18

      attr_reader :command, :correlation_id, :payload

      # @param [Fixnum] command
      # @param [Fixnum] auth_flag
      # @param [String] correlation_id
      # @param [String] username
      # @param [String] password
      # @param [String] payload
      def initialize(command, auth_flag, correlation_id, username, password, payload)
        @command = command
        @auth_flag = auth_flag
        @correlation_id = correlation_id
        @username = username # TODO handle username
        @password = password # TODO handle password
        @payload = payload
      end

      # @param [String] bytes
      # @return [TcpPacket,NilClass]
      def self.from_bytes(bytes)
        return nil unless bytes.length >= PAYLOAD_POS
        self.new(bytes[COMMAND_POS].ord, bytes[AUTH_FLAG_POS].ord, bytes[CORRELATION_ID_POS, 16],
                 nil, nil, bytes[PAYLOAD_POS..-1])
      end

      # @return [String]
      def bytes
        bytes = Array.new
        bytes.push(@command)
        bytes.push(@auth_flag)
        bytes.push(@correlation_id.bytes)
        bytes.push(@payload.bytes)
        bytes.flatten!.pack('c*')
      end

      def size
        @payload.length + PAYLOAD_POS
      end
    end
  end
end
