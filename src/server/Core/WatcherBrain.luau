--!strict
--//Types//--
export type Event = { kind: string, [string]: any }

export type Config = {
	graceSeconds: number,
	moveIntervalMin: number,
	moveIntervalMax: number,
	cueLeadTime: number,
	approachExtraMin: number,
	approachExtraMax: number,
	blockedWaitMin: number,
	blockedWaitMax: number,
	reactionWindow: number,
	rushSpeedFactor: number,
	scrapeInterval: number,
	logLimit: number,
}

export type Inputs = {
	observedNodes: { [string]: boolean },
	doorClosed: boolean,
	powerOut: boolean,
}

export type Transit = { from: string, to: string, elapsed: number, duration: number }
export type LogEntry = { t: number, from: string, to: string, reason: string, node: string }

export type Snapshot = {
	state: string,
	node: string,
	transit: { from: string, to: string, alpha: number }?,
	lunge: number,
	killed: boolean,
}

type Graph = {
	definition: { start: string, approach: string, door: string, retreat: string },
	forward: (self: any, nodeId: string) -> { { from: string, to: string, travel: number, weight: number } },
	hop: (self: any, a: string, b: string) -> { travel: number }?,
	path: (self: any, from: string, to: string, reverse: boolean) -> { string }?,
}

type Rng = {
	range: (self: any, min: number, max: number) -> number,
	weighted: <T>(self: any, entries: { { value: T, weight: number } }) -> T,
}

export type Brain = {
	config: Config,
	graph: Graph,
	rng: Rng,
	state: string,
	node: string,
	transit: Transit?,
	clock: number,
	waitTimer: number,
	waitTarget: number,
	approachTimer: number,
	approachTarget: number,
	blockedTimer: number,
	blockedTarget: number,
	attackTimer: number,
	scrapeTimer: number,
	resume: string,
	path: { string },
	rushing: boolean,
	killed: boolean,
	killReason: string?,
	log: { LogEntry },
	step: (self: Brain, dt: number, inputs: Inputs) -> { Event },
	snapshot: (self: Brain) -> Snapshot,
}

--//State//--
local WatcherBrain = {}
WatcherBrain.__index = WatcherBrain

--//Functions//--
local function setState(self: Brain, to: string, reason: string, events: { Event })
	if self.state == to then
		return
	end
	local from = self.state
	self.state = to
	table.insert(self.log, { t = self.clock, from = from, to = to, reason = reason, node = self.node })
	if #self.log > self.config.logLimit then
		table.remove(self.log, 1)
	end
	table.insert(events, { kind = "Transition", from = from, to = to, reason = reason, node = self.node })
end

local function cue(events: { Event }, name: string, node: string)
	table.insert(events, { kind = "Cue", cue = name, node = node })
end

local function interval(self: Brain): number
	return self.rng:range(self.config.moveIntervalMin, self.config.moveIntervalMax)
end

local function startMove(self: Brain, toNode: string, scale: number, events: { Event })
	local edge = self.graph:hop(self.node, toNode)
	if not edge then
		error("no route hop " .. self.node .. " to " .. toNode)
	end
	local duration = edge.travel * scale
	self.transit = { from = self.node, to = toNode, elapsed = 0, duration = duration }
	table.insert(events, { kind = "MoveStarted", from = self.node, to = toNode, duration = duration })
	cue(events, "step", self.node)
end

local function chooseNext(self: Brain): string
	local edges = self.graph:forward(self.node)
	if #edges == 1 then
		return edges[1].to
	end
	local entries = {}
	for _, edge in edges do
		table.insert(entries, { value = edge.to, weight = edge.weight })
	end
	return self.rng:weighted(entries)
end

local function enterAttacking(self: Brain, reason: string, events: { Event })
	self.attackTimer = 0
	setState(self, "Attacking", reason, events)
	cue(events, "lunge", self.node)
end

local function followPath(self: Brain, scale: number, events: { Event }): boolean
	if #self.path == 0 then
		return false
	end
	local nextNode = table.remove(self.path, 1) :: string
	startMove(self, nextNode, scale, events)
	return true
end

local function arriveAtDoor(self: Brain, inputs: Inputs, events: { Event })
	self.blockedTimer = 0
	if self.rushing or not inputs.doorClosed then
		enterAttacking(self, if self.rushing then "power_out_arrival" else "door_open_on_arrival", events)
		return
	end
	self.blockedTarget = self.rng:range(self.config.blockedWaitMin, self.config.blockedWaitMax)
	self.scrapeTimer = 0
	setState(self, "DoorBlocked", "door_closed_on_arrival", events)
	cue(events, "door_scrape", self.node)
end

local function onArrive(self: Brain, inputs: Inputs, events: { Event })
	local definition = self.graph.definition
	if self.node == definition.approach and self.state ~= "Retreating" then
		cue(events, "servo_approach", self.node)
	end
	local scale = if self.rushing then self.config.rushSpeedFactor else 1
	if followPath(self, scale, events) then
		return
	end
	if self.node == definition.door then
		arriveAtDoor(self, inputs, events)
	elseif self.state == "Retreating" then
		self.waitTimer = 0
		self.waitTarget = interval(self)
		setState(self, "Traversing", "retreat_complete", events)
	elseif self.node == definition.approach then
		self.approachTimer = 0
		self.approachTarget = self.config.cueLeadTime
			+ self.rng:range(self.config.approachExtraMin, self.config.approachExtraMax)
		setState(self, "Approaching", "reached_approach", events)
	else
		self.waitTimer = 0
		self.waitTarget = interval(self)
	end
end

local function planRush(self: Brain, events: { Event })
	local door = self.graph.definition.door
	local route = self.graph:path(self.node, door, false)
	self.path = {}
	if route then
		for i = 2, #route do
			table.insert(self.path, route[i])
		end
	end
	if self.state ~= "Approaching" then
		setState(self, "Approaching", "power_out_rush", events)
	end
	followPath(self, self.config.rushSpeedFactor, events)
end

local function advanceTransit(self: Brain, dt: number, events: { Event }): boolean
	local transit = self.transit
	if not transit then
		return false
	end
	transit.elapsed += dt
	if transit.elapsed < transit.duration then
		return false
	end
	self.node = transit.to
	self.transit = nil
	table.insert(events, { kind = "MoveEnded", node = self.node })
	return true
end

function WatcherBrain.new(config: Config, graph: Graph, rng: Rng): Brain
	return setmetatable({
		config = config,
		graph = graph,
		rng = rng,
		state = "Dormant",
		node = graph.definition.start,
		transit = nil,
		clock = 0,
		waitTimer = 0,
		waitTarget = 0,
		approachTimer = 0,
		approachTarget = 0,
		blockedTimer = 0,
		blockedTarget = 0,
		attackTimer = 0,
		scrapeTimer = 0,
		resume = "Traversing",
		path = {},
		rushing = false,
		killed = false,
		killReason = nil,
		log = {},
	}, WatcherBrain) :: any
end

--//Logic//--
function WatcherBrain.step(self: Brain, dt: number, inputs: Inputs): { Event }
	local events: { Event } = {}
	if self.killed or dt <= 0 then
		return events
	end
	self.clock += dt
	local definition = self.graph.definition

	if inputs.powerOut and not self.rushing then
		self.rushing = true
		table.insert(events, { kind = "Rush" })
	end

	if self.transit then
		if advanceTransit(self, dt, events) then
			onArrive(self, inputs, events)
		end
		return events
	end

	if self.rushing and self.state ~= "Attacking" then
		if self.node == definition.door then
			arriveAtDoor(self, inputs, events)
		else
			planRush(self, events)
		end
		return events
	end

	local state = self.state
	if state == "Dormant" then
		if self.clock >= self.config.graceSeconds then
			self.waitTimer = 0
			self.waitTarget = interval(self)
			setState(self, "Traversing", "grace_elapsed", events)
		end
	elseif state == "Traversing" then
		if inputs.observedNodes[self.node] then
			self.resume = "Traversing"
			setState(self, "Observed", "observed_by_camera", events)
		else
			self.waitTimer += dt
			if self.waitTimer >= self.waitTarget then
				startMove(self, chooseNext(self), 1, events)
			end
		end
	elseif state == "Approaching" then
		if inputs.observedNodes[self.node] then
			self.resume = "Approaching"
			setState(self, "Observed", "observed_by_camera", events)
		else
			self.approachTimer += dt
			if self.approachTimer >= self.approachTarget then
				startMove(self, definition.door, 1, events)
			end
		end
	elseif state == "Observed" then
		if not inputs.observedNodes[self.node] then
			setState(self, self.resume, "observation_lost", events)
		end
	elseif state == "DoorBlocked" then
		if not inputs.doorClosed then
			enterAttacking(self, "door_opened", events)
		else
			self.blockedTimer += dt
			self.scrapeTimer += dt
			if self.scrapeTimer >= self.config.scrapeInterval then
				self.scrapeTimer = 0
				cue(events, "door_scrape", self.node)
			end
			if self.blockedTimer >= self.blockedTarget then
				local route = self.graph:path(self.node, definition.retreat, true)
				self.path = {}
				if route then
					for i = 2, #route do
						table.insert(self.path, route[i])
					end
				end
				setState(self, "Retreating", "blocked_timeout", events)
				if not followPath(self, 1, events) then
					self.node = definition.retreat
					self.waitTimer = 0
					self.waitTarget = interval(self)
					setState(self, "Traversing", "retreat_complete", events)
				end
			end
		end
	elseif state == "Attacking" then
		self.attackTimer += dt
		if inputs.doorClosed and not self.rushing then
			self.blockedTimer = 0
			self.blockedTarget = self.rng:range(self.config.blockedWaitMin, self.config.blockedWaitMax)
			setState(self, "DoorBlocked", "door_closed_in_time", events)
		elseif self.attackTimer >= self.config.reactionWindow then
			self.killed = true
			self.killReason = if self.rushing then "power_out" else "watcher_attack"
			table.insert(events, { kind = "Killed", reason = self.killReason })
		end
	elseif state == "Retreating" then
		self.waitTimer = 0
		self.waitTarget = interval(self)
		setState(self, "Traversing", "retreat_complete", events)
	end
	return events
end

function WatcherBrain.snapshot(self: Brain): Snapshot
	local transit = self.transit
	local alpha = 0
	local transitView = nil
	if transit then
		alpha = math.clamp(transit.elapsed / transit.duration, 0, 1)
		transitView = { from = transit.from, to = transit.to, alpha = alpha }
	end
	local lunge = 0
	if self.state == "Attacking" then
		lunge = math.clamp(self.attackTimer / self.config.reactionWindow, 0, 1)
	end
	return {
		state = self.state,
		node = self.node,
		transit = transitView,
		lunge = lunge,
		killed = self.killed,
	}
end

--//Cleanup//--
return WatcherBrain
