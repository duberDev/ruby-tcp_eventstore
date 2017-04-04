module TcpEventStore
  module Errors
    class Error < RuntimeError; end

    class NotAuthenticatedError < Error; end

    class CommandNotExpectedError < Error
      def initialize(expected, actual)
        super("Expected: #{expected}. Actual: #{actual}")
      end
    end

    class NoResultError < Error; end
  end
end
