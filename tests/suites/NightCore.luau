--!strict
--//Modules//--
local Harness = require("../Harness")
local Fixture = require("../Fixture")
local NightCore = require("../../src/server/Core/NightCore")
local CameraConfig = require("../../src/config/CameraConfig")

--//Functions//--
local function powerDrop(core: any, rec: any, seconds: number): number
	local before = core.power.power
	rec:advance(seconds)
	return before - core.power.power
end

local function signature(events: { any }): string
	local parts = {}
	for _, event in events do
		table.insert(
			parts,
			table.concat({
				string.format("%.1f", event.t or 0),
				event.kind,
				tostring(event.reason or event.cue or event.phase or event.id or event.result or ""),
				tostring(event.node or event.to or ""),
			}, ":")
		)
	end
	return table.concat(parts, "|")
end

local function loseByIdling(core: any, rec: any)
	local lost = rec:runUntil(function()
		return core:phase() == "Lost"
	end, 450)
	Harness.truthy(lost, "an idle player should lose")
end

--//Logic//--
local suite = Harness.suite("NightCore")

suite.test("the shipped configuration validates and broken ones are caught", function()
	Harness.eq(#NightCore.validate(Fixture.deps, Fixture.settings()), 0, "shipped config")
	local cases: { { string | ((any) -> ()) } } = {
		{
			"reactionWindow",
			function(s)
				s.watcher.reactionWindow = 0.5
			end,
		},
		{
			"cueLeadTime",
			function(s)
				s.watcher.cueLeadTime = 2
			end,
		},
		{
			"covers unknown node",
			function(s)
				s.light.covers = { "MOON" }
			end,
		},
		{
			"CAM6 covers no route node",
			function(s)
				s.cameras[6].coverage = {}
			end,
		},
		{
			"threshold",
			function(s)
				s.power.thresholds = { 0 }
			end,
		},
		{
			"tickSeconds",
			function(s)
				s.timing.tickSeconds = 1
			end,
		},
		{
			"missing drain for Door",
			function(s)
				s.power.deviceDrain.Door = nil
			end,
		},
	}
	for _, case in cases do
		local errors = NightCore.validate(Fixture.deps, Fixture.settings(case[2] :: any))
		Harness.contains(errors, case[1] :: string, "expected a validation error")
	end
end)

suite.test("a night starts clean, introduces itself, and rejects input until it is active", function()
	local core = NightCore.new(Fixture.deps, Fixture.settings())
	Harness.eq(core:phase(), "Waiting")
	local waitingOk, waitingReason = core:requestDoor(true)
	Harness.falsy(waitingOk)
	Harness.eq(waitingReason, "not_active")
	Harness.truthy(core:start())
	Harness.falsy(core:start(), "cannot start twice")
	Harness.eq(core:phase(), "Starting")
	local rec = Fixture.record(core)
	for _, request in
		{
			function()
				return core:requestMonitor(true)
			end,
			function()
				return core:requestDoor(true)
			end,
			function()
				return core:requestLight(true)
			end,
			function()
				return core:requestCamera("CAM1")
			end,
		}
	do
		local ok, reason = request()
		Harness.falsy(ok)
		Harness.eq(reason, "not_active")
	end
	rec:advance(3.8)
	Harness.eq(core:phase(), "Starting")
	rec:advance(0.5)
	Harness.eq(core:phase(), "Active")
	local phases = {}
	for _, event in rec.events do
		if event.kind == "Phase" then
			table.insert(phases, event.phase)
		end
	end
	Harness.eq(table.concat(phases, ">"), "Starting>Active")
end)

suite.test("all six camera feeds select, observe their own room and report their status", function()
	local core, rec = Fixture.activeCore()
	Harness.truthy(core:requestMonitor(true))
	for _, camera in CameraConfig.cameras do
		rec:advance(0.2)
		local ok = core:requestCamera(camera.id)
		Harness.truthy(ok, camera.id .. " select")
		rec:advance(0.45)
		local snapshot = core:snapshot()
		Harness.eq(snapshot.selectedCamera, camera.id)
		Harness.eq(snapshot.feeds[camera.id], "ok")
		local observed = core.surveillance:observedNodes(core.elapsed)
		for _, node in camera.coverage do
			Harness.truthy(observed[node], camera.id .. " should observe " .. node)
		end
		local count = 0
		for _ in observed do
			count += 1
		end
		Harness.eq(count, #camera.coverage, camera.id .. " observes only its own coverage")
	end
end)

suite.test("the door costs exactly its configured power and duplicate requests cost nothing", function()
	local core, rec = Fixture.activeCore()
	Harness.near(powerDrop(core, rec, 10), 0.8, 0.03, "baseline per 10s")
	Harness.truthy(core:requestDoor(true))
	local ok, reason = core:requestDoor(true)
	Harness.truthy(ok)
	Harness.eq(reason, "unchanged")
	Harness.near(powerDrop(core, rec, 10), 2.4, 0.05, "baseline plus door per 10s")
	Harness.eq(rec:count("DoorChanged"), 1, "a duplicate request must not announce a change")
	Harness.near(core.power:drainRate(), 0.24, 1e-9, "drain with the door shut")
end)

suite.test("the door has a cooldown and the tablet and light cost what they should", function()
	local core, rec = Fixture.activeCore()
	Harness.truthy(core:requestDoor(true))
	local ok, reason = core:requestDoor(false)
	Harness.falsy(ok)
	Harness.eq(reason, "cooldown")
	rec:advance(0.7)
	Harness.truthy(core:requestDoor(false))
	Harness.truthy(core:requestMonitor(true))
	Harness.near(powerDrop(core, rec, 10), 1.2, 0.05, "tablet per 10s")
	Harness.truthy(core:requestMonitor(false))
	Harness.truthy(core:requestLight(true))
	Harness.near(powerDrop(core, rec, 10), 1.6, 0.05, "light per 10s")
end)

suite.test("the door and light need free hands while the monitor is open", function()
	local core, rec = Fixture.activeCore()
	core:requestMonitor(true)
	local doorOk, doorReason = core:requestDoor(true)
	Harness.falsy(doorOk)
	Harness.eq(doorReason, "hands_busy")
	local lightOk, lightReason = core:requestLight(true)
	Harness.falsy(lightOk)
	Harness.eq(lightReason, "hands_busy")
	core:requestMonitor(false)
	rec:advance(0.1)
	Harness.truthy(core:requestDoor(true))
end)

suite.test("toggling the monitor rapidly keeps the tablet drain in step", function()
	local core, rec = Fixture.activeCore()
	for i = 1, 300 do
		core:requestMonitor(i % 2 == 1)
		core:requestMonitor(i % 3 ~= 0)
		rec:advance(0.03)
		Harness.eq(core.power:isOn("Tablet"), core.surveillance.monitorOpen, "tablet drain matches monitor at " .. i)
	end
end)

suite.test("invalid requests are refused cleanly in every phase", function()
	local core, rec = Fixture.activeCore()
	for _, bad in { 5, "yes", {}, false } do
		if type(bad) ~= "boolean" then
			Harness.eq(select(2, core:requestDoor(bad)), "bad_type")
			Harness.eq(select(2, core:requestLight(bad)), "bad_type")
			Harness.eq(select(2, core:requestMonitor(bad)), "bad_type")
		end
		Harness.falsy((core:requestCamera(bad)))
	end
	Harness.eq(select(2, core:requestDoor(nil)), "bad_type")
	Harness.eq(select(2, core:requestMonitor(nil)), "bad_type")
	Harness.falsy((core:requestCamera(nil)))
	Harness.falsy((core:requestCamera("CAM99")))
	rec:advance(0.1)
	core:abort("menu")
	Harness.eq(select(2, core:requestDoor(true)), "not_active")
	Harness.eq(select(2, core:requestCamera("CAM1")), "not_active")
end)

suite.test("zero power releases the door, kills the light and monitor, and refuses new power use", function()
	local core, rec = Fixture.activeCore()
	core:requestDoor(true)
	rec:advance(1)
	core:debugSetPower(0)
	rec:advance(0.2)
	local snapshot = core:snapshot()
	Harness.truthy(snapshot.powerOut)
	Harness.falsy(snapshot.doorClosed, "door released")
	Harness.falsy(snapshot.lightOn)
	Harness.falsy(snapshot.monitorOpen)
	Harness.eq(snapshot.objective, "power_out")
	Harness.eq(rec:count("PowerOut"), 1)
	Harness.truthy(rec:find("DoorChanged", function(e)
		return e.reason == "power_out"
	end) ~= nil, "door change announced")
	Harness.eq(select(2, core:requestDoor(true)), "no_power")
	Harness.eq(select(2, core:requestLight(true)), "no_power")
	Harness.eq(select(2, core:requestMonitor(true)), "offline")
	Harness.eq(select(2, core:requestDoor(false)), "unchanged")
end)

suite.test("power failing with the monitor and light on closes both and announces it", function()
	local core, rec = Fixture.activeCore()
	core:requestLight(true)
	rec:advance(0.2)
	core:requestMonitor(true)
	core:debugSetPower(0)
	rec:advance(0.2)
	Harness.truthy(rec:find("MonitorChanged", function(e)
		return e.reason == "power_out" and e.open == false
	end) ~= nil, "monitor closed by power_out")
	Harness.truthy(rec:find("LightChanged", function(e)
		return e.reason == "power_out"
	end) ~= nil, "light switched off by power_out")
end)

suite.test("power out is a loss from the Watcher unless the shift ends first", function()
	local losing, losingRec = Fixture.activeCore()
	losing:debugSetElapsed(200)
	losing:debugSetPower(0)
	Harness.truthy(
		losingRec:runUntil(function()
			return losing:phase() == "Lost"
		end, 80),
		"rush should end in a loss"
	)
	local outcome = losingRec:find("Outcome")
	Harness.eq(outcome.reason, "power_out")
	Harness.eq(losingRec:count("Outcome"), 1)

	local surviving, survivingRec = Fixture.activeCore()
	surviving:debugSetElapsed(470)
	surviving:debugSetPower(0)
	survivingRec:runUntil(function()
		return surviving:phase() ~= "Active"
	end, 30)
	Harness.eq(surviving:phase(), "Won", "the dawn arrives before the rush does")
	Harness.eq(survivingRec:find("Outcome").reason, "shift_complete")
end)

suite.test("victory is emitted once and a retry starts a clean run", function()
	local core, rec = Fixture.activeCore()
	core:requestDoor(true)
	core:debugSetElapsed(479.5)
	rec:advance(2)
	Harness.eq(core:phase(), "Won")
	rec:advance(100)
	Harness.eq(rec:count("Outcome"), 1, "single outcome")
	Harness.eq(core:snapshot().objective, "won")
	Harness.eq(select(2, core:requestDoor(false)), "not_active")
	local oldRun = core:runId()
	Harness.truthy(core:retry())
	Harness.eq(core:runId(), oldRun + 1)
	Harness.falsy(core.machine:isCurrent(oldRun), "old run is stale")
	local snapshot = core:snapshot()
	Harness.eq(snapshot.phase, "Starting")
	Harness.eq(snapshot.elapsed, 0)
	Harness.eq(snapshot.power, 100)
	Harness.falsy(snapshot.doorClosed)
	Harness.falsy(snapshot.lightOn)
	Harness.falsy(snapshot.monitorOpen)
	Harness.eq(snapshot.selectedCamera, "")
	Harness.falsy(snapshot.doorSensor)
	Harness.eq(core.brain.state, "Dormant")
	Harness.eq(core.brain.node, "STORAGE")
	rec:advance(5)
	Harness.eq(core:phase(), "Active")
end)

suite.test("losing then retrying works repeatedly with a fresh Watcher each time", function()
	local core, rec = Fixture.activeCore()
	loseByIdling(core, rec)
	Harness.eq(rec:find("Outcome").reason, "watcher_attack")
	Harness.eq(core:snapshot().objective, "lost")
	for attempt = 1, 3 do
		Harness.truthy(core:retry(), "retry " .. attempt)
		rec:advance(5)
		Harness.eq(core:phase(), "Active")
		Harness.eq(core:snapshot().power > 99, true, "fresh power on attempt " .. attempt)
		Harness.eq(core.brain.state, "Dormant")
		loseByIdling(core, rec)
	end
	Harness.eq(rec:count("Outcome"), 4, "one outcome per run")
	local runs: { [number]: boolean } = {}
	for _, event in rec.events do
		if event.kind == "Outcome" then
			Harness.falsy(runs[event.runId], "duplicate outcome for run " .. event.runId)
			runs[event.runId] = true
		end
	end
end)

suite.test("aborting to the menu returns to Waiting and a new start works", function()
	local core, rec = Fixture.activeCore()
	core:requestMonitor(true)
	rec:advance(1)
	core:abort("menu")
	Harness.eq(core:phase(), "Waiting")
	local old = core:runId()
	Harness.truthy(core:start())
	Harness.eq(core:runId(), old + 1)
	Harness.falsy(core:snapshot().monitorOpen)
end)

suite.test("the inspection light freezes the final approach, then overheats and locks out", function()
	local core, rec = Fixture.activeCore()
	local reached = rec:runUntil(function()
		return core.brain.node == "APPROACH" and core.brain.transit == nil and core.brain.state == "Approaching"
	end, 300)
	Harness.truthy(reached, "the Watcher should reach the approach")
	Harness.truthy(core:requestLight(true))
	rec:advance(2)
	Harness.eq(core.brain.state, "Observed", "lit approach is observed")
	rec:advance(core.settings.light.burnoutAfter)
	Harness.truthy(rec:find("LightChanged", function(e)
		return e.reason == "overheat"
	end) ~= nil, "overheat announced")
	local ok, reason = core:requestLight(true)
	Harness.falsy(ok)
	Harness.eq(reason, "overheated")
	Harness.truthy(core:snapshot().lightLocked)
	rec:advance(core.settings.light.lockoutSeconds + 0.2)
	Harness.truthy(core:requestLight(true), "usable again after the lockout")
end)

suite.test("staring at the Watcher jams the feed but not during the grace period", function()
	local core, rec = Fixture.activeCore()
	core:requestMonitor(true)
	core:requestCamera("CAM3")
	rec:advance(core.settings.watcher.graceSeconds - 1)
	Harness.eq(rec:count("FeedJammed"), 0, "no strain while it is dormant")
	Harness.truthy(
		rec:runUntil(function()
			return rec:count("FeedJammed") >= 1
		end, 40),
		"feed should jam"
	)
	Harness.eq(rec:find("FeedJammed").cameraId, "CAM3")
	Harness.eq(core:snapshot().feeds.CAM3, "jammed")
	rec:advance(core.settings.surveillance.jamDuration + 0.2)
	Harness.eq(core:snapshot().feeds.CAM3, "ok", "feed recovers")
end)

suite.test("the door sensor lights only while it waits outside", function()
	local core, rec = Fixture.activeCore()
	core:requestDoor(true)
	local arrived = rec:runUntil(function()
		return core:snapshot().doorSensor
	end, 300)
	Harness.truthy(arrived, "sensor should light")
	Harness.eq(core.brain.node, "OFFICE_DOOR")
	local left = rec:runUntil(function()
		return not core:snapshot().doorSensor
	end, 40)
	Harness.truthy(left, "sensor should clear after it retreats")
end)

suite.test("tutorial hints and power warnings each fire once", function()
	local core, rec = Fixture.activeCore()
	core:requestDoor(true)
	core:debugSetPower(30)
	rec:advance(1)
	core:debugSetPower(24)
	rec:advance(1)
	core:debugSetPower(5)
	rec:advance(60)
	local warnings = {}
	local hints: { [string]: number } = {}
	for _, event in rec.events do
		if event.kind == "PowerWarning" then
			table.insert(warnings, event.threshold)
		elseif event.kind == "Hint" then
			hints[event.id] = (hints[event.id] or 0) + 1
		end
	end
	Harness.eq(table.concat(warnings, ","), "25,10")
	for id, count in hints do
		Harness.eq(count, 1, "hint " .. id)
	end
	Harness.eq(hints.monitor, 1)
end)

suite.test("equal seeds replay identically and different seeds differ", function()
	local function play(seed: number): string
		local core, rec = Fixture.activeCore(nil, seed)
		loseByIdling(core, rec)
		return signature(rec.events)
	end
	Harness.eq(play(31), play(31), "replay")
	local seen: { [string]: boolean } = {}
	for seed = 1, 10 do
		seen[play(seed)] = true
	end
	local distinct = 0
	for _ in seen do
		distinct += 1
	end
	Harness.truthy(distinct >= 5, "only " .. distinct .. " distinct nights from 10 seeds")
end)

suite.test("debug speed scales time and a server hitch cannot skip the simulation", function()
	local fast, fastRec = Fixture.activeCore()
	fast:setSpeed(10)
	fastRec:advance(9)
	Harness.near(fast.elapsed, 90, 0.5, "elapsed at x10")
	local core = Fixture.activeCore()
	core:step(100)
	Harness.truthy(core.elapsed <= 5.1, "a hitch advances at most 5 seconds, got " .. core.elapsed)
	core:step(0 / 0)
	core:step(-5)
	Harness.truthy(core.elapsed <= 5.1, "bad dt ignored")
end)
