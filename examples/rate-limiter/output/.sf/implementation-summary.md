# Implementation Summary: Token-Bucket Rate Limiter

## Files Created

- `rate-limiter.ts` — `RateLimiter` class and the `RateLimiterConfig` interface
- `rate-limiter-middleware.ts` — `rateLimiterMiddleware`, Express-style
- `rate-limiter.test.ts` — 11 vitest tests, all acceptance criteria and three edge cases
- `tsconfig.json` — strict mode, no emit
- `package.json` — `npm test` runs vitest, `npm run typecheck` runs tsc

No existing patterns found - used minimal approach. The project held only `package.json`,
so the code follows the TypeScript and vitest defaults.

## Acceptance Criteria Status

- [x] 100 requests with one key all succeed
- [x] Request 101 with the same key fails
- [x] The bucket refills after 60 seconds, and the next request succeeds
- [x] Two keys hold independent buckets
- [x] `capacity` sets the burst size, and the default is 100
- [x] A `rate` of 0 or less, or a `capacity` below 0, throws at construction
- [x] `capacity: 0` fails every request
- [x] The middleware answers 429 with `Retry-After: 60`, and calls `next` under the limit

## Design Decisions

- A bucket holds the token count and one timestamp, which serves the refill and the eviction
- `performance.now()` gives the time, so a wall clock change cannot remove tokens
- `canRequest` drops the idle buckets, so the limiter needs no timer and no cleanup call
- A partial token blocks the request. The check is `tokens < 1`, not `tokens <= 0`.
- The middleware types name only the three response methods it calls, so it needs no Express
- `Retry-After` is the fixed string `60`. A computed value is out of scope.
