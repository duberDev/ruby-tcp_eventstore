require 'tcpeventstore'

log = Logger.new(STDOUT)
log.level = Logger::DEBUG
log.progname = 'test'

es = TcpEventStore::Connection.new('192.168.99.100', 1113, logger: log)
es.connect

correlation_id = es.subscribe_to_stream('test') { |x| p x.inspect }

evt = TcpEventStore::EventData.new(TcpEventStore::UUID::generate, 'Test', true, '{}', '')
p es.append_to_stream('test', TcpEventStore::ExpectedVersion::ANY, [evt])

for _ in 0..30
  evt = TcpEventStore::EventData.new(TcpEventStore::UUID::generate, 'Test', true, '{}', '')
  es.append_to_stream('test', TcpEventStore::ExpectedVersion::ANY, [evt]) { |x| p x.inspect }
  sleep 1
end

p es.unsubscribe_from_stream(correlation_id) { |x| p x.inspect }
