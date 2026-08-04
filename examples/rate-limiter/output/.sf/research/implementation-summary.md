# Implementation Summary

## Files
- `rate-limiter.ts` (49 lines) — one class, one exported interface, one module constant
- `rate-limiter-middleware.ts` (24 lines) — one factory function, two local interfaces
- `rate-limiter.test.ts` (138 lines) — 11 vitest tests in two suites, with fake timers
- `tsconfig.json` (12 lines) — strict mode, `ES2020`, no emit
- `package.json` — `npm test` runs vitest, `npm run typecheck` runs tsc

## Public API

**Class `RateLimiter`**
- `constructor(config?: RateLimiterConfig)` — throws when `rate <= 0` or `capacity < 0`
- `canRequest(apiKey: string): boolean` — consumes one token, or returns false

**Interface `RateLimiterConfig`**
- `capacity?: number` — burst size, default 100
- `rate?: number` — tokens each minute, default 100

**Function `rateLimiterMiddleware(config?: RateLimiterConfig)`**
- Returns `(req, res, next) => void`
- Reads the key from the `x-api-key` header, and uses `"anonymous"` when it is absent
- Under the limit: calls `next()`
- Over the limit: `res.status(429).set("Retry-After", "60").json({ error: "Too Many Requests" })`

## Design Decisions
- A `Map` from key to `{ tokens, updated }`. One timestamp serves refill and eviction.
- `performance.now()` for the time, so a wall clock change cannot remove tokens
- `canRequest` drops idle buckets, so the module needs no timer
- `tokens < 1` blocks the request, because a partial token cannot pay for one call
- The middleware declares only the response methods it calls, so it needs no Express types

## Test Coverage
All 8 acceptance criteria have tests. Three more cover the idle hour eviction, a missing
`x-api-key` header, and `capacity: 0` after a refill window.
