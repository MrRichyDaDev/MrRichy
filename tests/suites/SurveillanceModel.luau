--!strict
--//Modules//--
local Harness = require("../Harness")
local SurveillanceModel = require("../../src/server/Core/SurveillanceModel")
local SurveillanceConfig = require("../../src/server/Config/SurveillanceConfig")
local CameraConfig = require("../../src/config/CameraConfig")
local RouteConfig = require("../../src/server/Config/RouteConfig")

--//Functions//--
local function copy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, inner in value do
		result[key] = copy(inner)
	end
	return result
end

local function nodeIds(): { string }
	local ids = {}
	for _, node in RouteConfig.nodes do
		table.insert(ids, node.id)
	end
	return ids
end

local function mustCover(): { string }
	local ids = {}
	for _, node in RouteConfig.nodes do
		if node.id ~= RouteConfig.door then
			table.insert(ids, node.id)
		end
	end
	return ids
end

local function camerasAfter(mutate: (any) -> ()): { string }
	local cameras = copy(CameraConfig.cameras)
	mutate(cameras)
	return SurveillanceModel.validateCameras(cameras, nodeIds(), mustCover())
end

local function newModel()
	return SurveillanceModel.new(SurveillanceConfig, CameraConfig.cameras)
end

--//Logic//--
local suite = Harness.suite("SurveillanceModel")

suite.test("the shipped camera registry is valid and covers every room", function()
	local errors = SurveillanceModel.validateCameras(CameraConfig.cameras, nodeIds(), mustCover())
	Harness.eq(#errors, 0, table.concat(errors, "; "))
	Harness.eq(#CameraConfig.cameras, 6, "six cameras")
end)

suite.test("registry problems are reported", function()
	Harness.contains(
		camerasAfter(function(c)
			c[2].id = "CAM1"
		end),
		"duplicate camera CAM1"
	)
	Harness.contains(
		camerasAfter(function(c)
			c[1].coverage = { "MOON" }
		end),
		"unknown node MOON"
	)
	Harness.contains(
		camerasAfter(function(c)
			c[6].coverage = {}
		end),
		"CAM6 covers no route node"
	)
	Harness.contains(
		camerasAfter(function(c)
			c[3].position = { 0, 0 / 0, 0 }
		end),
		"invalid world position"
	)
	Harness.contains(
		camerasAfter(function(c)
			c[5].displayName = ""
		end),
		"no display name"
	)
	Harness.contains(
		camerasAfter(function(c)
			c[4].coverage = { "LOBBY" }
		end),
		"no camera covers SERVICE_HALL"
	)
end)

suite.test("observation needs an open monitor and the selection dwell", function()
	local model = newModel()
	Harness.eq(next(model:observedNodes(0)), nil, "closed monitor observes nothing")
	Harness.truthy(model:setMonitor(true, 10))
	Harness.eq(next(model:observedNodes(10.1)), nil, "inside the dwell")
	Harness.truthy(model:observedNodes(10.4)["LOBBY"], "after the dwell")
	Harness.truthy(model:selectCamera("CAM6", 11))
	Harness.eq(next(model:observedNodes(11.2)), nil, "dwell restarts on a new camera")
	Harness.truthy(model:observedNodes(11.4)["APPROACH"], "new camera observed")
end)

suite.test("invalid camera requests are rejected without erroring", function()
	local model = newModel()
	local _, closedReason = model:selectCamera("CAM1", 0)
	Harness.eq(closedReason, "monitor_closed")
	model:setMonitor(true, 0)
	for _, bad in { 5, true, {}, string.rep("x", 100) } do
		local ok, reason = model:selectCamera(bad, 1)
		Harness.falsy(ok, "rejected " .. typeof(bad))
		Harness.eq(reason, "bad_type")
	end
	for _, unknown in { "", "CAM99", "cam1" } do
		local ok, reason = model:selectCamera(unknown, 1)
		Harness.falsy(ok, "rejected " .. unknown)
		Harness.eq(reason, "unknown_camera")
	end
	local ok, reason = model:selectCamera(nil, 1)
	Harness.falsy(ok)
	Harness.eq(reason, "bad_type")
end)

suite.test("switching too quickly is refused and reselecting does not reset the dwell", function()
	local model = newModel()
	model:setMonitor(true, 0)
	Harness.truthy(model:selectCamera("CAM2", 1.0))
	local ok, reason = model:selectCamera("CAM3", 1.05)
	Harness.falsy(ok)
	Harness.eq(reason, "too_fast")
	Harness.truthy(model:selectCamera("CAM3", 1.2))
	local _, again = model:selectCamera("CAM3", 1.5)
	Harness.eq(again, "unchanged")
	Harness.truthy(model:observedNodes(1.6)["STORAGE"], "dwell kept after a no-op reselect")
end)

suite.test("watching the Watcher too long jams the feed, which then recovers", function()
	local model = newModel()
	model:setMonitor(true, 0)
	model:selectCamera("CAM1", 0.2)
	local now = 1
	local jammedAt: number? = nil
	while now < 30 and jammedAt == nil do
		for _, event in model:step(0.1, now, "LOBBY") do
			if event.kind == "FeedJammed" then
				jammedAt = now
			end
		end
		now += 0.1
	end
	Harness.truthy(jammedAt ~= nil, "feed never jammed")
	Harness.near((jammedAt :: number) - 1, SurveillanceConfig.observeLimit, 0.3, "time to jam")
	Harness.eq(model:feedStatus("CAM1", now), "jammed")
	Harness.eq(next(model:observedNodes(now)), nil, "a jammed feed observes nothing")
	Harness.eq(model:feedStatus("CAM1", now + SurveillanceConfig.jamDuration + 0.1), "ok")
	Harness.truthy(model:observedNodes(now + SurveillanceConfig.jamDuration + 0.1)["LOBBY"], "observation resumes")
end)

suite.test("short glances never jam the feed but sustained watching eventually does", function()
	local function jamsFor(watchSeconds: number, awaySeconds: number, cycles: number): number
		local model = newModel()
		model:setMonitor(true, 0)
		model:selectCamera("CAM1", 0.2)
		local now = 1
		local jams = 0
		for _ = 1, cycles do
			for _ = 1, math.floor(watchSeconds * 10) do
				jams += #model:step(0.1, now, "LOBBY")
				now += 0.1
			end
			for _ = 1, math.floor(awaySeconds * 10) do
				model:step(0.1, now, "STORAGE")
				now += 0.1
			end
		end
		return jams
	end
	Harness.eq(jamsFor(4, 8, 12), 0, "four seconds on, eight off")
	Harness.truthy(jamsFor(6, 6, 12) >= 1, "six seconds on, six off should jam")
	Harness.truthy(jamsFor(30, 0, 1) >= 2, "constant staring jams repeatedly")
end)

suite.test("going offline closes the monitor and blocks reopening", function()
	local model = newModel()
	model:setMonitor(true, 0)
	model:setOffline(true)
	Harness.falsy(model.monitorOpen, "monitor closed")
	local ok, reason = model:setMonitor(true, 1)
	Harness.falsy(ok)
	Harness.eq(reason, "offline")
	Harness.eq(model:feedStatus("CAM2", 1), "offline")
	local _, typeReason = model:setMonitor("yes" :: any, 1)
	Harness.eq(typeReason, "bad_type")
end)
