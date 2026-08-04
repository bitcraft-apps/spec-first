# Acceptance Criteria: Token-Bucket Rate Limiter

## Must Pass

1. **The limit holds for one key**
   - 100 calls to `canRequest("key-a")` → every call returns true
   - Call 101 → returns false

2. **Tokens refill from the time that passed**
   - Empty the bucket, then advance the clock 60 seconds
   - The next call returns true

3. **Keys do not share a bucket**
   - Empty the bucket for `key-a`
   - `canRequest("key-b")` returns true

4. **`capacity` sets the burst size**
   - `new RateLimiter({ capacity: 5 })` → 5 calls pass, call 6 fails
   - The default capacity is 100

5. **Invalid configuration throws**
   - `rate` of 0 or less → throws at construction
   - `capacity` below 0 → throws at construction

6. **The middleware answers 429**
   - Empty the bucket, then send one more request
   - Status 429, header `Retry-After: 60`, and `next` is not called
   - A request under the limit calls `next` and sends no status

## Edge Cases (Must Not Fail)

- `capacity: 0` → every call fails, because the bucket holds no token
- A request with no key header → the limiter uses one shared key
- A key that nobody uses for one hour → the limiter drops the bucket

## Definition of Done

All 6 "Must Pass" criteria pass in `rate-limiter.test.ts`. Fake timers move the clock.
