--!strict
--//Types//--
export type WeightedEntry<T> = { value: T, weight: number }

export type Generator = {
	seed: number,
	state: number,
	next: (self: Generator) -> number,
	range: (self: Generator, min: number, max: number) -> number,
	integer: (self: Generator, min: number, max: number) -> number,
	pick: <T>(self: Generator, list: { T }) -> T,
	weighted: <T>(self: Generator, entries: { WeightedEntry<T> }) -> T,
}

--//State//--
local SeededRandom = {}
SeededRandom.__index = SeededRandom

--//Functions//--
function SeededRandom.new(seed: number): Generator
	local state = bit32.band(math.floor(seed), 0xFFFFFFFF)
	if state == 0 then
		state = 0x2545F491
	end
	local self = setmetatable({ seed = seed, state = state }, SeededRandom) :: any
	for _ = 1, 4 do
		self:next()
	end
	return self :: Generator
end

function SeededRandom.next(self: Generator): number
	local x = self.state
	x = bit32.bxor(x, bit32.lshift(x, 13))
	x = bit32.bxor(x, bit32.rshift(x, 17))
	x = bit32.bxor(x, bit32.lshift(x, 5))
	self.state = x
	return x / 4294967296
end

function SeededRandom.range(self: Generator, min: number, max: number): number
	return min + self:next() * (max - min)
end

function SeededRandom.integer(self: Generator, min: number, max: number): number
	return min + math.floor(self:next() * (max - min + 1))
end

function SeededRandom.pick<T>(self: Generator, list: { T }): T
	assert(#list > 0, "SeededRandom.pick on an empty list")
	return list[self:integer(1, #list)]
end

function SeededRandom.weighted<T>(self: Generator, entries: { WeightedEntry<T> }): T
	assert(#entries > 0, "SeededRandom.weighted on an empty list")
	local total = 0
	for _, entry in entries do
		total += entry.weight
	end
	local roll = self:next() * total
	local running = 0
	for _, entry in entries do
		running += entry.weight
		if roll < running then
			return entry.value
		end
	end
	return entries[#entries].value
end

--//Cleanup//--
return SeededRandom
