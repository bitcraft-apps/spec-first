# Token-Bucket Rate Limiter — 100 requests per minute for each API key, one process

## Problem

The API accepts every request. One API key can send an unlimited number, which exhausts the
database connections and slows the service for everybody. The API needs a limit for each key,
and a clear answer when a caller passes it.

## Scope

### In

- `rate-limiter.ts` (~55 lines) — the limiter
  - `canRequest(apiKey: string): boolean` consumes one token, or returns false
  - `RateLimiterConfig`: `capacity` (burst, default 100), `rate` (per minute, default 100)
  - One bucket for each key, in memory, full at the first request
  - Refill from the elapsed time, read from `performance.now()`
  - Drop a bucket that nobody used for one hour
  - Throw at construction when `rate` is 0 or less, or `capacity` is below 0
- `rate-limiter-middleware.ts` (~15 lines) — reads `x-api-key`, answers 429 with `Retry-After: 60`
- `rate-limiter.test.ts` (~70 lines) — unit tests for all acceptance criteria

### Out

- State that survives a restart, or state shared between processes
- `X-RateLimit-*` headers, metrics and logs
- Per endpoint, per user or per customer limits
- A change to the rate while the process runs
- A computed `Retry-After` value, and a queue for blocked requests

## Acceptance Criteria

- [x] 100 requests with one key all succeed
- [x] Request 101 with the same key fails
- [x] The bucket refills after 60 seconds, and the next request succeeds
- [x] Two keys hold independent buckets
- [x] `capacity` sets the burst size, and the default is 100
- [x] A `rate` of 0 or less, or a `capacity` below 0, throws at construction
- [x] `capacity: 0` fails every request
- [x] The middleware answers 429 with `Retry-After: 60`, and calls `next` under the limit

## Risks

1. **A restart clears every bucket** — accepted. The window is 60 seconds.
2. **More than one process multiplies the quota** — out of scope. One process only.
3. **A clock that moves backward** — read `performance.now()`, which only moves forward.
4. **Memory growth from unused keys** — drop a bucket after one idle hour.
