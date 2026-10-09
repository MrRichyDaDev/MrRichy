--!strict
--//Modules//--
local Harness = require("../Harness")
local Fixture = require("../Fixture")
local RouteConfig = require("../../src/server/Config/RouteConfig")
local WatcherConfig = require("../../src/server/Config/WatcherConfig")

--//Types//--
type Inputs = { observedNodes: { [string]: boolean }, doorClosed: boolean, powerOut: boolean }
type Provider = (brain: any) -> Inputs

--//Config//--
local CONFIG = WatcherConfig[1]
local STEP = 0.05

--//Functions//--
local function inputs(doorClosed: boolean, observed: { [string]: boolean }?, powerOut: boolean?): Inputs
	return { observedNodes = observed or {}, doorClosed = doorClosed, powerOut = powerOut or false }
end

local function run(brain: any, seconds: number, provider: Provider): { any }
	local events = {}
	local elapsed = 0
	while elapsed < seconds - 1e-9 do
		for _, event in brain:step(STEP, provider(brain)) do
			event.t = brain.clock
			table.insert(events, event)
		end
		elapsed += STEP
	end
	return events
end

local function first(events: { any }, kind: string, predicate: ((any) -> boolean)?): any?
	for _, event in events do
		if event.kind == kind and (predicate == nil or predicate(event)) then
			return event
		end
	end
	return nil
end

local function transition(events: { any }, to: string, reason: string?): any?
	return first(events, "Transition", function(event)
		return event.to == to and (reason == nil or event.reason == reason)
	end)
end

local function allOpen(): Provider
	return function()
		return inputs(false)
	end
end

local function allClosed(): Provider
	return function()
		return inputs(true)
	end
end

--//Logic//--
local suite = Harness.suite("WatcherBrain")

suite.test("stays dormant through the grace period and then starts moving", function()
	local brain = Fixture.newBrain(11)
	local early = run(brain, CONFIG.graceSeconds - 0.5, allOpen())
	Harness.eq(brain.state, "Dormant")
	Harness.eq(brain.node, "STORAGE")
	Harness.eq(first(early, "MoveStarted"), nil, "no movement during grace")
	local later = run(brain, 1, allOpen())
	Harness.truthy(transition(later, "Traversing", "grace_elapsed") ~= nil, "grace transition")
end)

suite.test("moves only along real route edges and never skips a node", function()
	for seed = 1, 50 do
		local brain = Fixture.newBrain(seed)
		local events = run(brain, 700, allClosed())
		local location = "STORAGE"
		for _, event in events do
			if event.kind == "MoveStarted" then
				Harness.eq(event.from, location, "seed " .. seed .. " move origin")
				Harness.truthy(
					brain.graph:hop(event.from, event.to) ~= nil,
					"seed " .. seed .. " no edge " .. event.from .. ">" .. event.to
				)
			elseif event.kind == "MoveEnded" then
				location = event.node
			end
		end
	end
end)

suite.test("never teleports: the node changes only when a move finishes", function()
	for seed = 1, 20 do
		local brain = Fixture.newBrain(seed)
		local previous = brain.node
		for _ = 1, 14000 do
			local events = brain:step(STEP, inputs(true))
			local ended = first(events, "MoveEnded") ~= nil
			if brain.node ~= previous then
				Harness.truthy(ended, "seed " .. seed .. " node jumped " .. previous .. " to " .. brain.node)
			end
			for _, event in events do
				if event.kind == "MoveStarted" then
					local edge = brain.graph:hop(event.from, event.to)
					Harness.near(event.duration, edge.travel, 1e-9, "move duration")
				end
			end
			previous = brain.node
		end
	end
end)

suite.test("a watched Watcher holds still and resumes when released", function()
	local brain = Fixture.newBrain(21)
	run(brain, CONFIG.graceSeconds + 1, allClosed())
	local watched = { STORAGE = true }
	local held = run(brain, 200, function()
		return inputs(true, watched)
	end)
	Harness.eq(brain.state, "Observed")
	Harness.eq(brain.node, "STORAGE")
	Harness.eq(first(held, "MoveStarted"), nil, "no movement while watched")
	local released = run(brain, CONFIG.moveIntervalMax + 1, allClosed())
	Harness.truthy(transition(released, "Traversing", "observation_lost") ~= nil, "observation_lost transition")
	Harness.truthy(first(released, "MoveStarted") ~= nil, "moves again after release")
end)

suite.test("watching the final approach freezes it and keeps its progress", function()
	local brain = Fixture.newBrain(33)
	local watching = false
	local provider: Provider = function(b)
		if b.state == "Approaching" and b.transit == nil then
			watching = true
		end
		if watching then
			return inputs(true, { APPROACH = true })
		end
		return inputs(true)
	end
	local frozen = false
	for _ = 1, 20000 do
		brain:step(STEP, provider(brain))
		if brain.state == "Observed" then
			frozen = true
			break
		end
	end
	Harness.truthy(frozen, "never reached the approach")
	Harness.eq(brain.node, "APPROACH")
	local progress = brain.approachTimer
	local held = run(brain, 30, provider)
	Harness.eq(brain.approachTimer, progress, "approach timer frozen while watched")
	Harness.eq(first(held, "MoveStarted"), nil, "no movement while watched")
	watching = false
	local released = run(brain, 0.2, provider)
	Harness.truthy(transition(released, "Approaching", "observation_lost") ~= nil, "resumes Approaching")
end)

suite.test("the approach always gives a warning cue and enough time to react", function()
	local minimumGap = math.huge
	for seed = 1, 100 do
		local brain = Fixture.newBrain(seed)
		local events = run(brain, 600, allOpen())
		local cue = first(events, "Cue", function(event)
			return event.cue == "servo_approach"
		end)
		local arrival = first(events, "MoveEnded", function(event)
			return event.node == "OFFICE_DOOR"
		end)
		local killed = first(events, "Killed")
		Harness.truthy(cue ~= nil and arrival ~= nil and killed ~= nil, "seed " .. seed .. " never completed an attack")
		minimumGap = math.min(minimumGap, killed.t - cue.t)
		Harness.truthy(
			arrival.t - cue.t >= CONFIG.cueLeadTime + 2.6 - 0.1,
			"seed " .. seed .. " arrived too soon after the cue"
		)
	end
	Harness.truthy(
		minimumGap >= CONFIG.cueLeadTime + 2.6 + CONFIG.reactionWindow - 0.1,
		"shortest cue to attack was " .. minimumGap
	)
end)

suite.test("a closed door blocks it, then it retreats along the way it came and returns", function()
	local brain = Fixture.newBrain(5)
	local events = run(brain, 400, allClosed())
	Harness.eq(first(events, "Killed"), nil, "door held shut should never lose")
	local blocked = transition(events, "DoorBlocked", "door_closed_on_arrival")
	local retreating = transition(events, "Retreating", "blocked_timeout")
	local finished = transition(events, "Traversing", "retreat_complete")
	Harness.truthy(blocked ~= nil and retreating ~= nil and finished ~= nil, "full block and retreat cycle")
	local wait = retreating.t - blocked.t
	Harness.truthy(
		wait >= CONFIG.blockedWaitMin - 0.1 and wait <= CONFIG.blockedWaitMax + 0.1,
		"blocked wait was " .. wait
	)
	local retreatMoves = {}
	for _, event in events do
		if event.kind == "MoveStarted" and event.t >= retreating.t - 0.01 and event.t <= finished.t then
			table.insert(retreatMoves, event.from .. ">" .. event.to)
		end
	end
	Harness.eq(table.concat(retreatMoves, ","), "OFFICE_DOOR>APPROACH,APPROACH>LOBBY", "retreat path")
	for _, event in events do
		if event.kind == "Cue" and event.cue == "servo_approach" then
			Harness.falsy(event.t > retreating.t and event.t < finished.t, "servo cue fired during retreat")
		end
	end
	local arrivals = 0
	for _, event in events do
		if event.kind == "Transition" and event.to == "DoorBlocked" then
			arrivals += 1
		end
	end
	Harness.truthy(arrivals >= 2, "it should come back after retreating, saw " .. arrivals)
end)

suite.test("an open door on arrival is lethal only after the reaction window", function()
	local brain = Fixture.newBrain(8)
	local events = run(brain, 400, allOpen())
	local attacking = transition(events, "Attacking", "door_open_on_arrival")
	local killed = first(events, "Killed")
	Harness.truthy(attacking ~= nil and killed ~= nil, "attack sequence")
	Harness.eq(killed.reason, "watcher_attack")
	local window = killed.t - attacking.t
	Harness.truthy(
		window >= CONFIG.reactionWindow - 0.01 and window <= CONFIG.reactionWindow + 0.1,
		"window was " .. window
	)
end)

suite.test("closing the door inside the reaction window saves the player", function()
	local latched = false
	local brain = Fixture.newBrain(8)
	local events = run(brain, 400, function(b)
		if b.state == "Attacking" and b.attackTimer >= 1.0 then
			latched = true
		end
		return inputs(latched)
	end)
	Harness.truthy(transition(events, "Attacking", "door_open_on_arrival") ~= nil, "attack began")
	Harness.truthy(transition(events, "DoorBlocked", "door_closed_in_time") ~= nil, "saved by the door")
	Harness.eq(first(events, "Killed"), nil, "no kill")
end)

suite.test("opening the door while it waits outside triggers the attack", function()
	local brain = Fixture.newBrain(14)
	local opened = false
	local events = run(brain, 400, function(b)
		if b.state == "DoorBlocked" and b.blockedTimer >= 2 then
			opened = true
		end
		return inputs(not opened)
	end)
	Harness.truthy(transition(events, "Attacking", "door_opened") ~= nil, "door_opened attack")
	Harness.truthy(first(events, "Killed") ~= nil, "kill after the reaction window")
end)

suite.test("power out sends it straight to the door from any node", function()
	for _, node in RouteConfig.nodes do
		local brain = Fixture.newBrain(3)
		brain.node = node.id
		local events = run(brain, 120, function()
			return inputs(false, nil, true)
		end)
		local killed = first(events, "Killed")
		Harness.truthy(killed ~= nil, node.id .. " never reached the door")
		Harness.eq(killed.reason, "power_out", node.id .. " cause")
		for _, event in events do
			if event.kind == "MoveStarted" then
				local edge = brain.graph:hop(event.from, event.to)
				Harness.near(event.duration, edge.travel * CONFIG.rushSpeedFactor, 1e-9, node.id .. " rush speed")
			end
		end
		local route = brain.graph:path(node.id, "OFFICE_DOOR", false)
		local limit = brain.graph:pathTravel(route :: { string }) * CONFIG.rushSpeedFactor + CONFIG.reactionWindow + 0.5
		Harness.truthy(killed.t <= limit, node.id .. " took " .. killed.t .. " of " .. limit)
	end
end)

suite.test("power out in the middle of a move still ends at the door", function()
	local brain = Fixture.newBrain(4)
	local out = false
	local events = run(brain, 300, function(b)
		if b.transit ~= nil and b.state == "Traversing" then
			out = true
		end
		return inputs(false, nil, out)
	end)
	Harness.truthy(out, "never found a move to interrupt")
	local killed = first(events, "Killed")
	Harness.truthy(killed ~= nil, "no kill")
	Harness.eq(killed.reason, "power_out")
end)

suite.test("every transition records a reason and the log matches the events", function()
	local brain = Fixture.newBrain(9)
	local events = run(brain, 300, function(b)
		return inputs(b.node == "OFFICE_DOOR" or b.node == "APPROACH")
	end)
	local transitions = 0
	for _, event in events do
		if event.kind == "Transition" then
			transitions += 1
			Harness.truthy(type(event.reason) == "string" and event.reason ~= "", "empty reason")
			Harness.truthy(event.from ~= event.to, "no-op transition")
		end
	end
	Harness.eq(#brain.log, transitions, "log length")
	for _, entry in brain.log do
		Harness.truthy(entry.reason ~= "", "log reason")
	end
end)

suite.test("equal seeds replay identically and different seeds differ", function()
	local function signature(seed: number): string
		local brain = Fixture.newBrain(seed)
		run(brain, 300, function(b)
			return inputs(b.node == "OFFICE_DOOR" or b.node == "APPROACH")
		end)
		local parts = {}
		for _, entry in brain.log do
			table.insert(parts, string.format("%.2f:%s>%s:%s", entry.t, entry.from, entry.to, entry.reason))
		end
		return table.concat(parts, "|")
	end
	Harness.eq(signature(77), signature(77), "replay")
	local distinct: { [string]: boolean } = {}
	for seed = 1, 20 do
		distinct[signature(seed)] = true
	end
	local count = 0
	for _ in distinct do
		count += 1
	end
	Harness.truthy(count >= 10, "only " .. count .. " distinct runs from 20 seeds")
end)

suite.test("a kill is terminal", function()
	local brain = Fixture.newBrain(8)
	run(brain, 400, allOpen())
	Harness.truthy(brain.killed, "killed")
	local state = brain.state
	Harness.eq(#brain:step(STEP, inputs(true)), 0, "no events after the kill")
	Harness.eq(brain.state, state)
end)

suite.test("snapshots expose smooth movement and attack progress", function()
	local brain = Fixture.newBrain(8)
	local lastAlpha = -1
	local sawTransit = false
	local lungeMax = 0
	for _ = 1, 8000 do
		brain:step(STEP, inputs(false))
		local snapshot = brain:snapshot()
		if snapshot.transit then
			sawTransit = true
			Harness.truthy(snapshot.transit.alpha >= 0 and snapshot.transit.alpha <= 1, "alpha range")
			if snapshot.transit.from == "STORAGE" then
				Harness.truthy(
					snapshot.transit.alpha >= lastAlpha - 1e-9 or lastAlpha > 0.95,
					"alpha should not go backwards"
				)
			end
			lastAlpha = snapshot.transit.alpha
		end
		lungeMax = math.max(lungeMax, snapshot.lunge)
	end
	Harness.truthy(sawTransit, "no transit snapshot")
	Harness.truthy(lungeMax > 0.9, "lunge never progressed: " .. lungeMax)
end)
