module TcpEventStore
  class EventData
    attr_reader :id, :type, :is_json, :data, :metadata

    # @param [String] id
    # @param [String] type
    # @param [TrueClass,FalseClass] is_json
    # @param [String] data
    # @param [String] metadata
    def initialize(id, type, is_json, data, metadata)
      @id = id
      @type = type
      @is_json = is_json
      @data = data
      @metadata = metadata
    end
  end
end
