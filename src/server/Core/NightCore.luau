--!strict
--//Types//--
export type Event = { kind: string, [string]: any }

export type Deps = {
	PowerModel: any,
	SurveillanceModel: any,
	WatcherBrain: any,
	RouteGraph: any,
	SeededRandom: any,
	NightStateMachine: any,
}

export type LightSettings = { covers: { string }, burnoutAfter: number, lockoutSeconds: number, recoverRate: number }

export type Settings = {
	night: {
		id: number,
		title: string,
		durationSeconds: number,
		startingSeconds: number,
		watcherSeed: number,
		tutorial: boolean,
	},
	timing: { tickSeconds: number, hoursInShift: number, doorCooldownSeconds: number, lightCooldownSeconds: number },
	light: LightSettings,
	power: any,
	surveillance: any,
	watcher: any,
	route: any,
	cameras: { any },
}

export type Snapshot = {
	runId: number,
	phase: string,
	elapsed: number,
	duration: number,
	hourIndex: number,
	power: number,
	drainRate: number,
	sources: { string },
	doorClosed: boolean,
	lightOn: boolean,
	lightLocked: boolean,
	monitorOpen: boolean,
	selectedCamera: string,
	feeds: { [string]: string },
	doorSensor: boolean,
	powerOut: boolean,
	objective: string,
}

export type Core = {
	deps: Deps,
	settings: Settings,
	graph: any,
	machine: any,
	power: any,
	surveillance: any,
	brain: any,
	elapsed: number,
	simTime: number,
	startingTimer: number,
	accumulator: number,
	speed: number,
	doorClosed: boolean,
	lightOn: boolean,
	doorLockedUntil: number,
	lightLockedUntil: number,
	lightStrain: number,
	hintsFired: { [string]: boolean },
	queue: { Event },
	outcome: { result: string, reason: string }?,
	lastSeed: number,
	start: (self: Core, seed: number?) -> boolean,
	retry: (self: Core, seed: number?) -> boolean,
	abort: (self: Core, reason: string) -> (),
	step: (self: Core, dt: number) -> (),
	requestMonitor: (self: Core, open: any) -> (boolean, string),
	requestCamera: (self: Core, id: any) -> (boolean, string),
	requestDoor: (self: Core, closed: any) -> (boolean, string),
	requestLight: (self: Core, on: any) -> (boolean, string),
	snapshot: (self: Core) -> Snapshot,
	drainEvents: (self: Core) -> { Event },
	phase: (self: Core) -> string,
	runId: (self: Core) -> number,
	setSpeed: (self: Core, speed: number) -> (),
	debugSetPower: (self: Core, value: number) -> (),
	debugSetElapsed: (self: Core, seconds: number) -> (),
}

--//Config//--
local MAX_TICKS_PER_STEP = 50

local HINT_TEXT_KEYS = {
	monitor = true,
	watcher_awake = true,
	observed = true,
	servo = true,
	door_sensor = true,
	retreat = true,
	power_low = true,
}

--//State//--
local NightCore = {}
NightCore.__index = NightCore

--//Validation//--
local function positive(value: any): boolean
	return type(value) == "number" and value == value and value > 0 and value < math.huge
end

--//Functions//--
local function push(self: Core, event: Event)
	table.insert(self.queue, event)
end

local function hint(self: Core, id: string)
	if not self.settings.night.tutorial or not HINT_TEXT_KEYS[id] or self.hintsFired[id] then
		return
	end
	self.hintsFired[id] = true
	push(self, { kind = "Hint", id = id })
end

local function enter(self: Core, phase: string, reason: string): boolean
	local changed = self.machine:transition(phase, reason, self.simTime)
	if changed then
		push(self, { kind = "Phase", phase = phase, runId = self.machine.runId, reason = reason })
	end
	return changed
end

local function closeMonitor(self: Core, reason: string)
	if self.surveillance.monitorOpen then
		self.surveillance.monitorOpen = false
		self.power:setDevice("Tablet", false)
		push(self, { kind = "MonitorChanged", open = false, reason = reason })
	end
end

local function build(self: Core, seed: number)
	local deps = self.deps
	local settings = self.settings
	self.lastSeed = seed
	self.graph = deps.RouteGraph.new(settings.route)
	self.power = deps.PowerModel.new(settings.power)
	self.surveillance = deps.SurveillanceModel.new(settings.surveillance, settings.cameras)
	self.brain = deps.WatcherBrain.new(settings.watcher, self.graph, deps.SeededRandom.new(seed))
	self.elapsed = 0
	self.startingTimer = 0
	self.accumulator = 0
	self.doorClosed = false
	self.lightOn = false
	self.doorLockedUntil = -math.huge
	self.lightLockedUntil = -math.huge
	self.lightStrain = 0
	self.hintsFired = {}
	self.outcome = nil
end

local function teardown(self: Core)
	self.accumulator = 0
	self.outcome = nil
end

local function finish(self: Core, result: string, reason: string)
	if not enter(self, result, reason) then
		return
	end
	self.outcome = { result = result, reason = reason }
	closeMonitor(self, "outcome")
	push(self, { kind = "Outcome", result = result, reason = reason, runId = self.machine.runId })
end

local function handlePowerEvents(self: Core, events: { Event })
	for _, event in events do
		if event.kind == "Threshold" then
			push(self, { kind = "PowerWarning", threshold = event.threshold })
			if event.threshold >= 25 then
				hint(self, "power_low")
			end
		elseif event.kind == "PowerOut" then
			if self.doorClosed then
				self.doorClosed = false
				push(self, { kind = "DoorChanged", closed = false, reason = "power_out" })
			end
			if self.lightOn then
				self.lightOn = false
				push(self, { kind = "LightChanged", on = false, reason = "power_out" })
			end
			closeMonitor(self, "power_out")
			self.surveillance:setOffline(true)
			push(self, { kind = "PowerOut" })
		end
	end
end

local function handleBrainEvents(self: Core, events: { Event })
	for _, event in events do
		if event.kind == "Transition" then
			push(self, {
				kind = "WatcherTransition",
				from = event.from,
				to = event.to,
				reason = event.reason,
				node = event.node,
			})
			if event.reason == "grace_elapsed" then
				hint(self, "watcher_awake")
			elseif event.to == "Observed" then
				hint(self, "observed")
			elseif event.to == "DoorBlocked" then
				hint(self, "door_sensor")
			elseif event.to == "Retreating" then
				hint(self, "retreat")
			end
		elseif event.kind == "Cue" then
			push(self, { kind = "Cue", cue = event.cue, node = event.node })
			if event.cue == "servo_approach" then
				hint(self, "servo")
			end
		elseif event.kind == "MoveStarted" then
			push(self, { kind = "WatcherMove", from = event.from, to = event.to, duration = event.duration })
		elseif event.kind == "Rush" then
			push(self, { kind = "Cue", cue = "power_out_rush", node = self.brain.node })
		elseif event.kind == "Killed" then
			finish(self, "Lost", event.reason)
		end
	end
end

local function updateLight(self: Core, tick: number)
	local light = self.settings.light
	local brain = self.brain
	local covered = false
	for _, nodeId in light.covers do
		if brain.transit == nil and brain.node == nodeId then
			covered = true
		end
	end
	if self.lightOn and covered then
		self.lightStrain += tick
		if self.lightStrain >= light.burnoutAfter then
			self.lightStrain = 0
			self.lightOn = false
			self.power:setDevice("Light", false)
			self.lightLockedUntil = self.elapsed + light.lockoutSeconds
			push(self, { kind = "LightChanged", on = false, reason = "overheat" })
		end
	else
		self.lightStrain = math.max(0, self.lightStrain - tick * light.recoverRate)
	end
end

local function observedNodes(self: Core): { [string]: boolean }
	local nodes = self.surveillance:observedNodes(self.elapsed)
	if self.lightOn then
		for _, nodeId in self.settings.light.covers do
			nodes[nodeId] = true
		end
	end
	return nodes
end

local function tickOnce(self: Core, tick: number)
	self.simTime += tick
	local phase = self.machine.phase
	if phase == "Starting" then
		self.startingTimer += tick
		if self.startingTimer >= self.settings.night.startingSeconds then
			enter(self, "Active", "intro_complete")
		end
		return
	end
	if phase ~= "Active" then
		return
	end

	self.elapsed += tick
	if self.elapsed >= 5 then
		hint(self, "monitor")
	end

	handlePowerEvents(self, self.power:step(tick))

	local brain = self.brain
	local targetNode = if brain.transit == nil then brain.node else nil
	for _, event in self.surveillance:step(tick, self.elapsed, targetNode) do
		if event.kind == "FeedJammed" then
			push(self, { kind = "FeedJammed", cameraId = event.cameraId, duration = event.duration })
		end
	end
	updateLight(self, tick)

	handleBrainEvents(
		self,
		brain:step(tick, {
			observedNodes = observedNodes(self),
			doorClosed = self.doorClosed,
			powerOut = self.power.powerOut,
		})
	)

	if self.machine.phase == "Active" and self.elapsed >= self.settings.night.durationSeconds then
		finish(self, "Won", "shift_complete")
	end
end

function NightCore.new(deps: Deps, settings: Settings): Core
	local self = setmetatable({
		deps = deps,
		settings = settings,
		machine = deps.NightStateMachine.new(),
		simTime = 0,
		speed = 1,
		queue = {},
		lastSeed = 0,
	}, NightCore) :: any
	build(self, settings.night.watcherSeed)
	return self :: Core
end

function NightCore.compose(configs: any, nightIndex: number): Settings
	local night = configs.NightConfig.nights[nightIndex]
	assert(night ~= nil, "no night configured for index " .. tostring(nightIndex))
	local watcher = configs.WatcherConfig[nightIndex]
	assert(watcher ~= nil, "no watcher configuration for night " .. tostring(nightIndex))
	return {
		night = night,
		timing = configs.NightConfig,
		light = configs.NightConfig.light,
		power = configs.PowerConfig,
		surveillance = configs.SurveillanceConfig,
		watcher = watcher,
		route = configs.RouteConfig,
		cameras = configs.CameraConfig.cameras,
	}
end

function NightCore.validate(deps: Deps, settings: Settings): { string }
	local errors: { string } = {}
	for _, message in deps.RouteGraph.validate(settings.route) do
		table.insert(errors, "route: " .. message)
	end
	local nodeIds: { string } = {}
	local mustCover: { string } = {}
	for _, node in settings.route.nodes do
		table.insert(nodeIds, node.id)
		if node.id ~= settings.route.door then
			table.insert(mustCover, node.id)
		end
	end
	for _, message in deps.SurveillanceModel.validateCameras(settings.cameras, nodeIds, mustCover) do
		table.insert(errors, "cameras: " .. message)
	end
	local night = settings.night
	if not positive(night.durationSeconds) then
		table.insert(errors, "night: durationSeconds must be positive")
	end
	if type(night.startingSeconds) ~= "number" or night.startingSeconds < 0 then
		table.insert(errors, "night: startingSeconds must not be negative")
	end
	if not positive(settings.timing.tickSeconds) or settings.timing.tickSeconds > 0.25 then
		table.insert(errors, "timing: tickSeconds must be in (0, 0.25]")
	end
	local power = settings.power
	if not positive(power.startPower) or power.startPower > power.maxPower then
		table.insert(errors, "power: startPower must be positive and not above maxPower")
	end
	for _, device in { "Tablet", "Door", "Light" } do
		if type(power.deviceDrain[device]) ~= "number" or power.deviceDrain[device] < 0 then
			table.insert(errors, "power: missing drain for " .. device)
		end
	end
	for _, threshold in power.thresholds do
		if threshold <= 0 or threshold >= power.maxPower then
			table.insert(errors, "power: threshold " .. tostring(threshold) .. " is out of range")
		end
	end
	local watcher = settings.watcher
	if watcher.reactionWindow < 1 then
		table.insert(errors, "watcher: reactionWindow below 1s is not fair to react to")
	end
	if watcher.cueLeadTime < 3 then
		table.insert(errors, "watcher: cueLeadTime below 3s gives too little warning")
	end
	if watcher.moveIntervalMin > watcher.moveIntervalMax or watcher.blockedWaitMin > watcher.blockedWaitMax then
		table.insert(errors, "watcher: minimum interval exceeds maximum")
	end
	local nodeSet: { [string]: boolean } = {}
	for _, nodeId in nodeIds do
		nodeSet[nodeId] = true
	end
	for _, nodeId in settings.light.covers do
		if not nodeSet[nodeId] then
			table.insert(errors, "light: covers unknown node " .. tostring(nodeId))
		end
	end
	return errors
end

--//Logic//--
function NightCore.start(self: Core, seed: number?): boolean
	if self.machine.phase ~= "Waiting" and self.machine.phase ~= "Resetting" then
		return false
	end
	local nextSeed = seed or (self.settings.night.watcherSeed + (self.machine.runId + 1) * 7919)
	build(self, nextSeed)
	return enter(self, "Starting", "start_requested")
end

function NightCore.retry(self: Core, seed: number?): boolean
	local phase = self.machine.phase
	if phase == "Waiting" then
		return self:start(seed)
	end
	if phase == "Resetting" then
		return self:start(seed)
	end
	if not enter(self, "Resetting", "retry_requested") then
		return false
	end
	teardown(self)
	return self:start(seed)
end

function NightCore.abort(self: Core, reason: string)
	if self.machine.phase == "Waiting" then
		return
	end
	if self.machine.phase ~= "Resetting" and not enter(self, "Resetting", reason) then
		return
	end
	teardown(self)
	enter(self, "Waiting", reason)
end

function NightCore.step(self: Core, dt: number)
	if type(dt) ~= "number" or dt ~= dt or dt <= 0 then
		return
	end
	local tick = self.settings.timing.tickSeconds
	self.accumulator += dt * self.speed
	local ticks = 0
	while self.accumulator >= tick do
		self.accumulator -= tick
		ticks += 1
		tickOnce(self, tick)
		if ticks >= MAX_TICKS_PER_STEP then
			self.accumulator = 0
			break
		end
	end
end

function NightCore.requestMonitor(self: Core, open: any): (boolean, string)
	if self.machine.phase ~= "Active" then
		return false, "not_active"
	end
	if type(open) ~= "boolean" then
		return false, "bad_type"
	end
	local ok, reason = self.surveillance:setMonitor(open, self.elapsed)
	if ok and reason == "ok" then
		self.power:setDevice("Tablet", open)
		push(self, { kind = "MonitorChanged", open = open, reason = "player" })
	end
	return ok, reason
end

function NightCore.requestCamera(self: Core, id: any): (boolean, string)
	if self.machine.phase ~= "Active" then
		return false, "not_active"
	end
	local ok, reason = self.surveillance:selectCamera(id, self.elapsed)
	if ok and reason == "ok" then
		push(self, { kind = "CameraChanged", cameraId = id })
	end
	return ok, reason
end

function NightCore.requestDoor(self: Core, closed: any): (boolean, string)
	if self.machine.phase ~= "Active" then
		return false, "not_active"
	end
	if type(closed) ~= "boolean" then
		return false, "bad_type"
	end
	if self.power.powerOut then
		if closed then
			return false, "no_power"
		end
		return true, "unchanged"
	end
	if closed == self.doorClosed then
		return true, "unchanged"
	end
	if self.surveillance.monitorOpen then
		return false, "hands_busy"
	end
	if self.elapsed < self.doorLockedUntil then
		return false, "cooldown"
	end
	self.doorClosed = closed
	self.power:setDevice("Door", closed)
	self.doorLockedUntil = self.elapsed + self.settings.timing.doorCooldownSeconds
	push(self, { kind = "DoorChanged", closed = closed, reason = "player" })
	return true, "ok"
end

function NightCore.requestLight(self: Core, on: any): (boolean, string)
	if self.machine.phase ~= "Active" then
		return false, "not_active"
	end
	if type(on) ~= "boolean" then
		return false, "bad_type"
	end
	if self.power.powerOut then
		if on then
			return false, "no_power"
		end
		return true, "unchanged"
	end
	if on == self.lightOn then
		return true, "unchanged"
	end
	if self.surveillance.monitorOpen then
		return false, "hands_busy"
	end
	if on and self.elapsed < self.lightLockedUntil then
		return false, "overheated"
	end
	self.lightOn = on
	self.power:setDevice("Light", on)
	push(self, { kind = "LightChanged", on = on, reason = "player" })
	return true, "ok"
end

function NightCore.snapshot(self: Core): Snapshot
	local settings = self.settings
	local surveillance = self.surveillance
	local feeds: { [string]: string } = {}
	for _, id in surveillance.order do
		feeds[id] = surveillance:feedStatus(id, self.elapsed)
	end
	local sources: { string } = {}
	for _, source in self.power:sources() do
		table.insert(sources, source.id)
	end
	local brain = self.brain
	local doorState = brain.state == "DoorBlocked" or brain.state == "Attacking"
	local phase = self.machine.phase
	local objective = "survive"
	if phase == "Starting" then
		objective = "starting"
	elseif self.power.powerOut and phase == "Active" then
		objective = "power_out"
	elseif phase == "Won" then
		objective = "won"
	elseif phase == "Lost" then
		objective = "lost"
	end
	local duration = settings.night.durationSeconds
	return {
		runId = self.machine.runId,
		phase = phase,
		elapsed = self.elapsed,
		duration = duration,
		hourIndex = math.min(
			settings.timing.hoursInShift,
			math.floor(self.elapsed / duration * settings.timing.hoursInShift)
		),
		power = self.power.power,
		drainRate = self.power:drainRate(),
		sources = sources,
		doorClosed = self.doorClosed,
		lightOn = self.lightOn,
		lightLocked = self.elapsed < self.lightLockedUntil,
		monitorOpen = surveillance.monitorOpen,
		selectedCamera = surveillance.selected or "",
		feeds = feeds,
		doorSensor = brain.transit == nil and doorState,
		powerOut = self.power.powerOut,
		objective = objective,
	}
end

function NightCore.drainEvents(self: Core): { Event }
	local events = self.queue
	self.queue = {}
	return events
end

function NightCore.phase(self: Core): string
	return self.machine.phase
end

function NightCore.runId(self: Core): number
	return self.machine.runId
end

function NightCore.setSpeed(self: Core, speed: number)
	self.speed = math.clamp(speed, 0.1, 50)
end

function NightCore.debugSetPower(self: Core, value: number)
	handlePowerEvents(self, self.power:setPower(value))
end

function NightCore.debugSetElapsed(self: Core, seconds: number)
	self.elapsed = math.clamp(seconds, 0, self.settings.night.durationSeconds)
end

--//Cleanup//--
return NightCore
