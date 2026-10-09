--!strict
--//Modules//--
local Harness = require("../Harness")
local RateLimiter = require("../../src/shared/RateLimiter")

--//Logic//--
local suite = Harness.suite("RateLimiter")

local function newLimiter()
	local now = 0
	local limiter = RateLimiter.new(function()
		return now
	end)
	return limiter, function(seconds: number)
		now += seconds
	end
end

suite.test("burst is allowed then denied", function()
	local limiter = newLimiter()
	for i = 1, 3 do
		Harness.truthy(limiter:consume("p1:camera", 3, 1), "token " .. i)
	end
	Harness.falsy(limiter:consume("p1:camera", 3, 1), "fourth request")
end)

suite.test("tokens refill with time and never exceed the burst", function()
	local limiter, advance = newLimiter()
	for _ = 1, 3 do
		limiter:consume("k", 3, 2)
	end
	advance(1)
	Harness.truthy(limiter:consume("k", 3, 2), "refilled one")
	Harness.truthy(limiter:consume("k", 3, 2), "refilled two")
	Harness.falsy(limiter:consume("k", 3, 2), "only two refilled")
	advance(1000)
	local allowed = 0
	for _ = 1, 10 do
		if limiter:consume("k", 3, 2) then
			allowed += 1
		end
	end
	Harness.eq(allowed, 3, "burst cap after long idle")
end)

suite.test("keys are independent and reset restores the burst", function()
	local limiter = newLimiter()
	for _ = 1, 2 do
		limiter:consume("a", 2, 0)
	end
	Harness.falsy(limiter:consume("a", 2, 0), "a exhausted")
	Harness.truthy(limiter:consume("b", 2, 0), "b untouched")
	limiter:reset("a")
	Harness.truthy(limiter:consume("a", 2, 0), "a after reset")
end)
