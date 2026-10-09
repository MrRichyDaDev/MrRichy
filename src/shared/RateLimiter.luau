--!strict
--//Types//--
type Bucket = { tokens: number, lastRefill: number }

export type Limiter = {
	clock: () -> number,
	buckets: { [string]: Bucket },
	consume: (self: Limiter, key: string, burst: number, refillPerSecond: number) -> boolean,
	reset: (self: Limiter, key: string) -> (),
	clear: (self: Limiter) -> (),
}

--//State//--
local RateLimiter = {}
RateLimiter.__index = RateLimiter

--//Functions//--
function RateLimiter.new(clock: () -> number): Limiter
	return setmetatable({ clock = clock, buckets = {} }, RateLimiter) :: any
end

function RateLimiter.consume(self: Limiter, key: string, burst: number, refillPerSecond: number): boolean
	local now = self.clock()
	local bucket = self.buckets[key]
	if not bucket then
		bucket = { tokens = burst, lastRefill = now }
		self.buckets[key] = bucket
	end
	local elapsed = math.max(0, now - bucket.lastRefill)
	bucket.tokens = math.min(burst, bucket.tokens + elapsed * refillPerSecond)
	bucket.lastRefill = now
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

function RateLimiter.reset(self: Limiter, key: string)
	self.buckets[key] = nil
end

function RateLimiter.clear(self: Limiter)
	table.clear(self.buckets)
end

--//Cleanup//--
return RateLimiter
