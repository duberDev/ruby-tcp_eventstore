module TcpEventStore
  module Helper
    def self.eat_error(&blk)
      begin
        return blk.call
      rescue
        return nil
      end
    end
  end
end
