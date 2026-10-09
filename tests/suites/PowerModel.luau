--!strict
--//Modules//--
local Harness = require("../Harness")
local PowerModel = require("../../src/server/Core/PowerModel")
local PowerConfig = require("../../src/server/Config/PowerConfig")

--//Functions//--
local function newModel()
	return PowerModel.new(PowerConfig)
end

local function run(model: any, seconds: number, dt: number?): { any }
	local step = dt or 0.1
	local events = {}
	local elapsed = 0
	while elapsed < seconds - 1e-9 do
		for _, event in model:step(step) do
			table.insert(events, event)
		end
		elapsed += step
	end
	return events
end

--//Logic//--
local suite = Harness.suite("PowerModel")

suite.test("baseline alone uses 38.4 units over the 480 second night", function()
	local model = newModel()
	run(model, 480)
	Harness.near(100 - model.power, 38.4, 0.05, "baseline consumption")
end)

suite.test("every device adds its configured drain", function()
	local model = newModel()
	Harness.near(model:drainRate(), 0.08, 1e-9, "baseline")
	model:setDevice("Tablet", true)
	Harness.near(model:drainRate(), 0.12, 1e-9, "tablet")
	model:setDevice("Light", true)
	Harness.near(model:drainRate(), 0.20, 1e-9, "light")
	model:setDevice("Door", true)
	Harness.near(model:drainRate(), 0.36, 1e-9, "door")
end)

suite.test("holding the door shut all night is unsustainable", function()
	local model = newModel()
	model:setDevice("Door", true)
	local events = run(model, 480)
	local outs = 0
	for _, event in events do
		if event.kind == "PowerOut" then
			outs += 1
		end
	end
	Harness.eq(outs, 1, "PowerOut events")
	Harness.eq(model.power, 0, "power floor")
	Harness.truthy(model.powerOut, "powerOut flag")
end)

suite.test("power runs out near 416.7 seconds with the door closed throughout", function()
	local model = newModel()
	model:setDevice("Door", true)
	local elapsed = 0
	while not model.powerOut and elapsed < 600 do
		model:step(0.1)
		elapsed += 0.1
	end
	Harness.near(elapsed, 100 / 0.24, 0.3, "time to zero")
end)

suite.test("thoughtful short use of every device stays practical", function()
	local model = newModel()
	model:setDevice("Door", true)
	run(model, 30)
	model:setDevice("Door", false)
	model:setDevice("Tablet", true)
	run(model, 60)
	model:setDevice("Tablet", false)
	model:setDevice("Light", true)
	run(model, 20)
	model:setDevice("Light", false)
	run(model, 480 - 110)
	Harness.truthy(model.power > 40, "power left after short uses: " .. model.power)
end)

suite.test("warning thresholds fire once each, in order", function()
	local model = newModel()
	model:setDevice("Door", true)
	model:setDevice("Light", true)
	model:setDevice("Tablet", true)
	local thresholds = {}
	for _, event in run(model, 400) do
		if event.kind == "Threshold" then
			table.insert(thresholds, event.threshold)
		end
	end
	Harness.eq(#thresholds, 2, "threshold count")
	Harness.eq(thresholds[1], 25, "first threshold")
	Harness.eq(thresholds[2], 10, "second threshold")
end)

suite.test("a single large step crossing both thresholds reports both", function()
	local model = newModel()
	model:setPower(30)
	model.fired = {}
	local events = model:setPower(5)
	Harness.eq(#events, 2, "events from one jump")
	Harness.eq(events[1].threshold, 25)
	Harness.eq(events[2].threshold, 10)
end)

suite.test("power is clamped to its valid range", function()
	local model = newModel()
	model:setPower(500)
	Harness.eq(model.power, 100, "upper clamp")
	model:setPower(-5)
	Harness.eq(model.power, 0, "lower clamp")
	Harness.truthy(model.powerOut, "power out after clamp to zero")
end)

suite.test("at zero power devices switch off and cannot be turned on", function()
	local model = newModel()
	model:setDevice("Door", true)
	model:setDevice("Light", true)
	model:setPower(0)
	Harness.falsy(model:isOn("Door"), "door released")
	Harness.falsy(model:isOn("Light"), "light off")
	Harness.falsy(model:setDevice("Door", true), "cannot re-enable the door")
	Harness.eq(model:drainRate(), 0, "no drain after power out")
end)

suite.test("unknown devices are rejected and repeats do not stack drain", function()
	local model = newModel()
	Harness.falsy(model:setDevice("Toaster", true), "unknown device")
	model:setDevice("Door", true)
	model:setDevice("Door", true)
	model:setDevice("Door", true)
	Harness.near(model:drainRate(), 0.24, 1e-9, "door counted once")
end)

suite.test("forcing power re-arms the warning thresholds", function()
	local model = newModel()
	Harness.eq(#model:setPower(24), 1, "first drop warns")
	Harness.eq(#model:setPower(24), 0, "no repeat while below")
	model:setPower(100)
	Harness.eq(#model:setPower(24), 1, "warns again after recovery")
end)
