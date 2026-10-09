--!strict
--//Modules//--
local Harness = require("../Harness")
local SeededRandom = require("../../src/shared/SeededRandom")

--//Logic//--
local suite = Harness.suite("SeededRandom")

suite.test("equal seeds give equal sequences", function()
	local a = SeededRandom.new(1234)
	local b = SeededRandom.new(1234)
	for _ = 1, 200 do
		Harness.eq(a:next(), b:next(), "sequence")
	end
end)

suite.test("different seeds diverge", function()
	local a = SeededRandom.new(1)
	local b = SeededRandom.new(2)
	local different = false
	for _ = 1, 10 do
		if a:next() ~= b:next() then
			different = true
		end
	end
	Harness.truthy(different, "seeds 1 and 2 matched for 10 draws")
end)

suite.test("next stays in [0, 1) and zero or negative seeds still vary", function()
	for _, seed in { 0, -7, 2 ^ 40 } do
		local rng = SeededRandom.new(seed)
		local seen: { [number]: boolean } = {}
		local distinct = 0
		for _ = 1, 500 do
			local value = rng:next()
			Harness.truthy(value >= 0 and value < 1, "range for seed " .. tostring(seed))
			if not seen[value] then
				seen[value] = true
				distinct += 1
			end
		end
		Harness.truthy(distinct > 450, "seed " .. tostring(seed) .. " produced a stuck sequence")
	end
end)

suite.test("integer is inclusive on both ends and range respects bounds", function()
	local rng = SeededRandom.new(99)
	local counts: { [number]: number } = {}
	for _ = 1, 3000 do
		local value = rng:integer(1, 6)
		counts[value] = (counts[value] or 0) + 1
		local ranged = rng:range(2.5, 4.5)
		Harness.truthy(ranged >= 2.5 and ranged < 4.5, "range bounds")
	end
	for face = 1, 6 do
		Harness.truthy((counts[face] or 0) > 350, "face " .. face .. " too rare")
	end
	Harness.eq(counts[0], nil, "below minimum")
	Harness.eq(counts[7], nil, "above maximum")
end)

suite.test("weighted selection follows the weights", function()
	local rng = SeededRandom.new(7)
	local heavy = 0
	local draws = 20000
	for _ = 1, draws do
		local pick = rng:weighted({ { value = "A", weight = 3 }, { value = "B", weight = 1 } })
		if pick == "A" then
			heavy += 1
		end
	end
	Harness.near(heavy / draws, 0.75, 0.02, "share of A")
end)

suite.test("pick returns members and empty lists error", function()
	local rng = SeededRandom.new(5)
	local list = { "x", "y", "z" }
	for _ = 1, 50 do
		Harness.truthy(table.find(list, rng:pick(list)) ~= nil, "member")
	end
	Harness.falsy((pcall(function()
		rng:pick({})
	end)), "empty pick should error")
end)
