# Artifacts Summary

**Project**: Token-Bucket Rate Limiter — 100 requests per minute for each API key, one process

## Requirements
- Token-bucket algorithm, one bucket for each API key
- 100 requests per minute, the default rate
- Configurable burst capacity, the size of the bucket
- HTTP 429 with `Retry-After: 60` when the bucket is empty
- `canRequest(apiKey: string): boolean` as the one entry point
- Refill from the elapsed time, read from `performance.now()`
- Drop a bucket that nobody used for one hour
- Throw at construction on invalid configuration

## Acceptance Criteria (All Passed)
1. 100 requests with one key all succeed
2. Request 101 with the same key fails
3. The bucket refills after 60 seconds, and the next request succeeds
4. Two keys hold independent buckets
5. `capacity` sets the burst size, and the default is 100
6. A `rate` of 0 or less, or a `capacity` below 0, throws at construction
7. `capacity: 0` fails every request
8. The middleware answers 429 with `Retry-After: 60`, and calls `next` under the limit

## Scope Boundaries
- **In**: the limiter, the middleware, unit tests, configurable capacity and rate
- **Out**: persistence, shared state between processes, `X-RateLimit-*` headers,
  per endpoint limits, a change to the rate at run time, a computed `Retry-After`

## Risks
1. A restart clears every bucket → accepted, the window is 60 seconds
2. More than one process multiplies the quota → out of scope, one process
3. A clock that moves backward → `performance.now()` only moves forward
4. Memory growth from unused keys → drop a bucket after one idle hour
