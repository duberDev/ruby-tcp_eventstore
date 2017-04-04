require 'securerandom'

module TcpEventStore
  module UUID
    # @return [String] bytes
    def self.generate
      SecureRandom::uuid.split('-').pack('H*H*H*H*H*')
    end
  end
end