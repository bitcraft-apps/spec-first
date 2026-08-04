# Rate Limiter — Technical Docs

## Configuration

```typescript
interface RateLimiterConfig {
  capacity?: number; // burst size, the most tokens a bucket holds. Default 100.
  rate?: number;     // tokens added each minute. Default 100.
}
```

The constructor throws when `rate` is 0 or less, or when `capacity` is below 0. The error
arrives at start, not under load.

## `RateLimiter`

```typescript
import { RateLimiter } from "./rate-limiter.js";

const limiter = new RateLimiter({ capacity: 100, rate: 100 });
limiter.canRequest("key-a"); // true | false
```

`canRequest(apiKey)` consumes one token and returns true. It returns false when the bucket
holds less than one token.

- A key the limiter has not seen starts with a full bucket.
- The bucket refills from the time that passed, at `rate` tokens each minute.
- The token count never passes `capacity`.
- The limiter drops a bucket that nobody touched for one hour, on the next call.

## `rateLimiterMiddleware`

```typescript
import { rateLimiterMiddleware } from "./rate-limiter-middleware.js";

app.use(rateLimiterMiddleware({ capacity: 100, rate: 100 }));
```

Reads the caller from the `x-api-key` header. A request with no header uses the key
`"anonymous"`, which every such request shares.

**Under the limit**: calls `next()`.

**Over the limit**: sends status `429`, header `Retry-After: 60`, and the body
`{ "error": "Too Many Requests" }`.

The module declares only the three response methods it calls, so it needs no Express types.
Any framework with `status`, `set` and `json` works.

## Test it

`canRequest` reads `performance.now()`, which vitest fake timers control:

```typescript
vi.useFakeTimers();
vi.advanceTimersByTime(60_000); // one refill window
```

## Constraints

- One process. Each process holds its own buckets, so two processes double the quota.
- In memory. A restart gives every key a full bucket.
- `capacity: 0` is valid configuration, and it blocks every request.
- No `X-RateLimit-*` headers, and no per endpoint limits.
