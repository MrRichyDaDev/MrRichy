--!strict
--//Modules//--
local SeededRandom = require("../src/shared/SeededRandom")
local PowerModel = require("../src/server/Core/PowerModel")
local RouteGraph = require("../src/server/Core/RouteGraph")
local SurveillanceModel = require("../src/server/Core/SurveillanceModel")
local WatcherBrain = require("../src/server/Core/WatcherBrain")
local NightStateMachine = require("../src/server/Core/NightStateMachine")
local NightCore = require("../src/server/Core/NightCore")
local NightConfig = require("../src/server/Config/NightConfig")
local PowerConfig = require("../src/server/Config/PowerConfig")
local SurveillanceConfig = require("../src/server/Config/SurveillanceConfig")
local WatcherConfig = require("../src/server/Config/WatcherConfig")
local RouteConfig = require("../src/server/Config/RouteConfig")
local CameraConfig = require("../src/config/CameraConfig")

--//Types//--
export type Recorder = {
	core: any,
	events: { any },
	advance: (self: Recorder, seconds: number, dt: number?) -> (),
	runUntil: (self: Recorder, predicate: () -> boolean, maxSeconds: number, dt: number?) -> boolean,
	find: (self: Recorder, kind: string, predicate: ((any) -> boolean)?) -> any?,
	count: (self: Recorder, kind: string) -> number,
}

--//State//--
local Fixture = {}

Fixture.deps = {
	PowerModel = PowerModel,
	SurveillanceModel = SurveillanceModel,
	WatcherBrain = WatcherBrain,
	RouteGraph = RouteGraph,
	SeededRandom = SeededRandom,
	NightStateMachine = NightStateMachine,
}

Fixture.configs = {
	NightConfig = NightConfig,
	PowerConfig = PowerConfig,
	SurveillanceConfig = SurveillanceConfig,
	WatcherConfig = WatcherConfig,
	RouteConfig = RouteConfig,
	CameraConfig = CameraConfig,
}

--//Functions//--
local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, inner in value do
		copy[key] = deepCopy(inner)
	end
	return copy
end

function Fixture.copy(value: any): any
	return deepCopy(value)
end

function Fixture.settings(mutate: ((any) -> ())?): any
	local settings = NightCore.compose(deepCopy(Fixture.configs), 1)
	if mutate then
		mutate(settings)
	end
	return settings
end

function Fixture.record(core: any): Recorder
	local recorder: any = { core = core, events = {} }
	function recorder.advance(self: any, seconds: number, dt: number?)
		local step = dt or 0.05
		local elapsed = 0
		while elapsed < seconds - 1e-9 do
			core:step(step)
			elapsed += step
			for _, event in core:drainEvents() do
				event.t = core.elapsed
				table.insert(self.events, event)
			end
		end
	end
	function recorder.runUntil(self: any, predicate: () -> boolean, maxSeconds: number, dt: number?): boolean
		local step = dt or 0.05
		local elapsed = 0
		while elapsed < maxSeconds do
			if predicate() then
				return true
			end
			core:step(step)
			elapsed += step
			for _, event in core:drainEvents() do
				event.t = core.elapsed
				table.insert(self.events, event)
			end
		end
		return predicate()
	end
	function recorder.find(self: any, kind: string, predicate: ((any) -> boolean)?): any?
		for _, event in self.events do
			if event.kind == kind and (predicate == nil or predicate(event)) then
				return event
			end
		end
		return nil
	end
	function recorder.count(self: any, kind: string): number
		local total = 0
		for _, event in self.events do
			if event.kind == kind then
				total += 1
			end
		end
		return total
	end
	return recorder :: Recorder
end

function Fixture.newCore(mutate: ((any) -> ())?, seed: number?): (any, Recorder)
	local core = NightCore.new(Fixture.deps, Fixture.settings(mutate))
	core:start(seed)
	local recorder = Fixture.record(core)
	return core, recorder
end

function Fixture.activeCore(mutate: ((any) -> ())?, seed: number?): (any, Recorder)
	local core, recorder = Fixture.newCore(mutate, seed)
	recorder:runUntil(function()
		return core:phase() == "Active"
	end, 30)
	return core, recorder
end

function Fixture.newBrain(seed: number, mutate: ((any) -> ())?): any
	local config = deepCopy(WatcherConfig[1])
	if mutate then
		mutate(config)
	end
	local graph = RouteGraph.new(deepCopy(RouteConfig))
	return WatcherBrain.new(config, graph, SeededRandom.new(seed))
end

--//Cleanup//--
return Fixture
