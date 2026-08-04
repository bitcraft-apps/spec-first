# Rate Limiter

Limits each API key to 100 requests a minute. A caller over the limit gets HTTP 429.

## Add it to an API

```typescript
import express from "express";
import { rateLimiterMiddleware } from "./rate-limiter-middleware.js";

const app = express();
app.use(rateLimiterMiddleware());
```

The middleware reads the `x-api-key` request header. Every key gets its own quota.

## Use the limiter directly

```typescript
import { RateLimiter } from "./rate-limiter.js";

const limiter = new RateLimiter();

if (!limiter.canRequest(apiKey)) {
  return reject();
}
```

## Configuration

| Option | Type | Default | Purpose |
|--------|------|---------|---------|
| `rate` | `number` | `100` | Requests each minute for one key |
| `capacity` | `number` | `100` | Burst size, the requests one key can send at once |

```typescript
rateLimiterMiddleware({ rate: 600, capacity: 50 });
```

The example allows 600 requests a minute, and 50 at one time.

A `rate` of 0 or less, or a `capacity` below 0, throws when the process starts.

## What the caller sees

Over the limit:

- Status `429`
- Header `Retry-After: 60`
- Body `{ "error": "Too Many Requests" }`

The quota returns as time passes, not all at once. At the default rate, one request becomes
available again every 0.6 seconds.

## What to expect

- A key with no requests for a minute has its full quota.
- A request with no `x-api-key` header shares one quota with every other such request.
- A restart gives every key a full quota. The state lives in memory only.
- Two processes each keep their own count, so the quota for one key doubles. Run one process,
  or move the state to a shared store.

## Run the tests

```bash
npm install
npm test
```
