import { RateLimiter, type RateLimiterConfig } from "./rate-limiter.js";

interface Request {
  headers: Record<string, string | undefined>;
}

interface Response {
  status(code: number): Response;
  set(header: string, value: string): Response;
  json(body: unknown): void;
}

/** Express-style middleware that answers 429 when the caller passes the limit. */
export function rateLimiterMiddleware(config?: RateLimiterConfig) {
  const limiter = new RateLimiter(config);
  return (req: Request, res: Response, next: () => void): void => {
    const apiKey = req.headers["x-api-key"] ?? "anonymous";
    if (limiter.canRequest(apiKey)) {
      next();
      return;
    }
    res.status(429).set("Retry-After", "60").json({ error: "Too Many Requests" });
  };
}
