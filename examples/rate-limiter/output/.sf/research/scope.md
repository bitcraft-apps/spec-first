# MVP Scope: Token-Bucket Rate Limiter

## In Scope

### Core Functionality
- Token-bucket algorithm, one bucket for each API key
- 100 requests per minute, the default rate
- Configurable burst capacity, the size of the bucket
- HTTP 429 when the bucket is empty
- In-memory state, one process

### Required Interface
- `canRequest(apiKey: string): boolean` consumes one token, or returns false
- `RateLimiterConfig` with `capacity` and `rate`, both optional
- Middleware that reads the key from a request header

### Minimum Viable Behavior
- A new key starts with a full bucket
- Tokens refill from the time that passed, not from a timer
- The limiter drops keys that nobody used for one hour
- Invalid configuration throws at construction

## Out of Scope (Future Considerations)

### Storage
- Persistence across a restart
- Shared state between processes or hosts
- An external store such as Redis

### Observability
- Metrics, logs or audit records
- `X-RateLimit-*` response headers
- A count of the requests the limiter blocked

### Advanced Limits
- Per endpoint or per user limits
- A different limit for each customer
- A sliding window
- A queue for the requests the limiter blocked

### Configuration
- A change to the rate while the process runs
- A custom limit for one key
- A computed `Retry-After` value

## Acceptance Criteria

1. 100 requests with one key succeed
2. Request 101 with the same key fails
3. Tokens refill after 60 seconds
4. Two keys hold independent buckets
5. `capacity` sets the burst size
6. Invalid configuration throws

## Non-Functional

- Size: ~55 lines for the limiter, ~15 for the middleware, ~70 for the tests
- TypeScript, strict mode, no runtime dependency
- Tests run with vitest
