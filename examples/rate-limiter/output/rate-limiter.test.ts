import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { RateLimiter } from "./rate-limiter.js";
import { rateLimiterMiddleware } from "./rate-limiter-middleware.js";

/** Consume every token in the bucket for the key. */
function drain(limiter: RateLimiter, apiKey: string, count = 100) {
  for (let i = 0; i < count; i += 1) limiter.canRequest(apiKey);
}

/** A response that records what the middleware sent. */
function fakeResponse() {
  const sent = { status: 0, headers: {} as Record<string, string>, body: undefined as unknown };
  const res = {
    status(code: number) {
      sent.status = code;
      return res;
    },
    set(header: string, value: string) {
      sent.headers[header] = value;
      return res;
    },
    json(body: unknown) {
      sent.body = body;
    },
  };
  return { res, sent };
}

describe("RateLimiter", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("allows 100 requests for one key", () => {
    const limiter = new RateLimiter();
    for (let i = 0; i < 100; i += 1) {
      expect(limiter.canRequest("key-a")).toBe(true);
    }
  });

  it("rejects request 101 for the same key", () => {
    const limiter = new RateLimiter();
    drain(limiter, "key-a");
    expect(limiter.canRequest("key-a")).toBe(false);
  });

  it("refills the bucket after 60 seconds", () => {
    const limiter = new RateLimiter();
    drain(limiter, "key-a");
    expect(limiter.canRequest("key-a")).toBe(false);
    vi.advanceTimersByTime(60_000);
    expect(limiter.canRequest("key-a")).toBe(true);
  });

  it("keeps one bucket for each key", () => {
    const limiter = new RateLimiter();
    drain(limiter, "key-a");
    expect(limiter.canRequest("key-a")).toBe(false);
    expect(limiter.canRequest("key-b")).toBe(true);
  });

  it("takes the burst size from capacity", () => {
    const limiter = new RateLimiter({ capacity: 5 });
    drain(limiter, "key-a", 5);
    expect(limiter.canRequest("key-a")).toBe(false);
  });

  it("rejects every request when capacity is 0", () => {
    const limiter = new RateLimiter({ capacity: 0 });
    expect(limiter.canRequest("key-a")).toBe(false);
    vi.advanceTimersByTime(60_000);
    expect(limiter.canRequest("key-a")).toBe(false);
  });

  it("throws on invalid configuration", () => {
    expect(() => new RateLimiter({ rate: 0 })).toThrow();
    expect(() => new RateLimiter({ rate: -1 })).toThrow();
    expect(() => new RateLimiter({ capacity: -1 })).toThrow();
  });

  it("drops a bucket after one idle hour", () => {
    const limiter = new RateLimiter();
    drain(limiter, "key-a");
    vi.advanceTimersByTime(60 * 60 * 1000 + 1);
    // The bucket is gone, so the key starts again with a full one.
    for (let i = 0; i < 100; i += 1) {
      expect(limiter.canRequest("key-a")).toBe(true);
    }
  });
});

describe("rateLimiterMiddleware", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("calls next under the limit", () => {
    const middleware = rateLimiterMiddleware();
    const next = vi.fn();
    const { res, sent } = fakeResponse();
    middleware({ headers: { "x-api-key": "key-a" } }, res, next);
    expect(next).toHaveBeenCalledOnce();
    expect(sent.status).toBe(0);
  });

  it("answers 429 with Retry-After over the limit", () => {
    const middleware = rateLimiterMiddleware({ capacity: 1 });
    const next = vi.fn();
    const request = { headers: { "x-api-key": "key-a" } };
    middleware(request, fakeResponse().res, next);

    const { res, sent } = fakeResponse();
    middleware(request, res, next);
    expect(next).toHaveBeenCalledOnce();
    expect(sent.status).toBe(429);
    expect(sent.headers["Retry-After"]).toBe("60");
    expect(sent.body).toEqual({ error: "Too Many Requests" });
  });

  it("uses one shared key when the header is absent", () => {
    const middleware = rateLimiterMiddleware({ capacity: 1 });
    const next = vi.fn();
    middleware({ headers: {} }, fakeResponse().res, next);

    const { res, sent } = fakeResponse();
    middleware({ headers: {} }, res, next);
    expect(sent.status).toBe(429);
  });
});
