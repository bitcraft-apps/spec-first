# Token-Bucket Rate Limiter Risks

## Blockers

### 1. A Restart Clears Every Bucket
**Risk**: The limiter holds the buckets in memory. A restart gives every key a full bucket.
**Impact**: A caller at the limit gets a new quota when the process restarts.
**Solution**: Accept it for the MVP, because the state is small and the window is 60 seconds.
Document the behavior.

### 2. More Than One Process Multiplies The Quota
**Risk**: Each process holds its own buckets. Four processes allow 400 requests per minute
for one key.
**Impact**: The per-key guarantee fails behind a load balancer.
**Solution**: Out of scope. The MVP is one process. A shared limit needs an external store.

### 3. A Clock That Moves Backward
**Risk**: A wall clock can move backward. A negative time delta removes tokens, or adds them.
**Impact**: The limiter blocks a caller who is under the limit.
**Solution**: Read `performance.now()`, which only moves forward.

## Edge Cases

### 1. The First Request For A Key
**Risk**: The bucket for a new key does not exist.
**Solution**: Create it with a full bucket, at the time of the first request.

### 2. Memory Growth From Keys Nobody Uses
**Risk**: One bucket stays in memory for every key the limiter ever saw.
**Impact**: Memory grows without a limit, for example after a scan for valid keys.
**Solution**: Drop a bucket that nobody touched for one hour.

### 3. A Capacity Of Zero
**Risk**: `capacity: 0` holds no token, so the refill has nothing to fill.
**Solution**: Valid configuration. Every request fails. State it in the docs.

### 4. Invalid Configuration
**Risk**: A rate of 0 divides the refill by nothing. A capacity below 0 blocks every request.
**Solution**: Throw at construction, so the error arrives at start, not under load.

### 5. A Client That Retries At Once
**Risk**: A 429 with no guidance invites an immediate retry, which adds load.
**Solution**: Send `Retry-After: 60`. A computed value is out of scope.

## Assumptions to Validate

- **One process?** The MVP assumes one.
- **Who owns the keys?** Another component. The limiter only reads the key.

## Simple MVP Approach

- A `Map` from key to bucket, with the token count and two timestamps
- `performance.now()` for the time, and a refill from the elapsed minutes
- Eviction inside `canRequest`, so the limiter needs no timer
- Validation in the constructor
- Middleware that reads `x-api-key`, and answers 429 with `Retry-After: 60`
