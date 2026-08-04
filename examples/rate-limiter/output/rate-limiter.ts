export interface RateLimiterConfig {
  /** Burst size, the most tokens a bucket holds. Default 100. */
  capacity?: number;
  /** Tokens added each minute. Default 100. */
  rate?: number;
}

interface Bucket {
  tokens: number;
  updated: number;
}

/** Drop a bucket that nobody used for this long. */
const IDLE_LIMIT_MS = 60 * 60 * 1000;

export class RateLimiter {
  private readonly buckets = new Map<string, Bucket>();
  private readonly capacity: number;
  private readonly rate: number;

  constructor({ capacity = 100, rate = 100 }: RateLimiterConfig = {}) {
    if (rate <= 0) throw new Error("rate must be greater than 0");
    if (capacity < 0) throw new Error("capacity must be 0 or more");
    this.capacity = capacity;
    this.rate = rate;
  }

  /** Consume one token for the key. Returns false when the bucket is empty. */
  canRequest(apiKey: string): boolean {
    const now = performance.now();
    this.dropIdleBuckets(now);

    const bucket = this.buckets.get(apiKey) ?? { tokens: this.capacity, updated: now };
    const minutes = (now - bucket.updated) / 60_000;
    bucket.tokens = Math.min(this.capacity, bucket.tokens + minutes * this.rate);
    bucket.updated = now;
    this.buckets.set(apiKey, bucket);

    if (bucket.tokens < 1) return false;
    bucket.tokens -= 1;
    return true;
  }

  private dropIdleBuckets(now: number): void {
    for (const [key, bucket] of this.buckets) {
      if (now - bucket.updated > IDLE_LIMIT_MS) this.buckets.delete(key);
    }
  }
}
