# EventStore Ruby TCP Client

## Status

Alpha (DO NOT USE IN PRODUCTION)

## License

MIT. See [LICENSE](https://github.com/jdextraze/ruby-tcp_eventstore/blob/master/LICENSE).

## Requirements

- Docker (docker-compose for test)
  
## WIP

The following operations work but their API will definitely change:

- Append to stream
- Read stream events forward
- Subscribe to stream
- Unsubscribe from stream

## Simple test

In repository root path

```bash
docker-compose up -d
ruby -Ilib test.rb
```

## TODO

- Client heartbeat
- Operations retry and error handling
- Intermediate DTO
- Async / Sync
- Operations
  - Delete stream
  - Start transaction
  - Continue transaction
  - Read one event
  - Read stream events backward
  - Read all events forward
  - Read all events backward
  - Subscribe to stream from
  - Subscribe to all
  - Connect to persistent subscription
  - Subscribe to all from
  - Update persistent subscription
  - Create persistent subscription
  - Delete persistent subscription
  - Set stream metadata
  - Get stream metadata
- Set system settings
- Connection status callback
- Tests
- Script to generate protobuf message

## Note on protobuf

- Require version 3+
- Converted ClientMessageDtos.proto from proto2 to proto3 by removing
  - optional
  - required
  - default
