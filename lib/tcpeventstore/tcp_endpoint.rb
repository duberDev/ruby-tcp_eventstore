module TcpEventStore
  class TcpEndpoint
    attr_reader :address, :port

    def initialize(address, port)
      @address = address
      @port = port
    end
  end
end
