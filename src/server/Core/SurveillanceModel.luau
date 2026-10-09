--!strict
--//Types//--
export type CameraDef = {
	id: string,
	displayName: string,
	coverage: { string },
	position: { number }?,
	lookAt: { number }?,
}

export type Config = {
	selectionDwell: number,
	minSwitchInterval: number,
	observeLimit: number,
	observeDecay: number,
	jamDuration: number,
}

export type Event = { kind: string, [string]: any }

export type Model = {
	config: Config,
	cameras: { [string]: CameraDef },
	order: { string },
	monitorOpen: boolean,
	selected: string?,
	selectedAt: number,
	lastSwitchAt: number,
	jammedUntil: { [string]: number },
	offline: boolean,
	strain: number,
	setMonitor: (self: Model, open: boolean, now: number) -> (boolean, string),
	selectCamera: (self: Model, id: any, now: number) -> (boolean, string),
	feedStatus: (self: Model, id: string, now: number) -> string,
	observedNodes: (self: Model, now: number) -> { [string]: boolean },
	step: (self: Model, dt: number, now: number, targetNode: string?) -> { Event },
	jam: (self: Model, id: string, now: number, duration: number) -> (),
	setOffline: (self: Model, offline: boolean) -> (),
}

--//State//--
local SurveillanceModel = {}
SurveillanceModel.__index = SurveillanceModel

--//Validation//--
local function isFiniteNumber(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function validVector(value: any): boolean
	if type(value) ~= "table" or #value ~= 3 then
		return false
	end
	for i = 1, 3 do
		if not isFiniteNumber(value[i]) then
			return false
		end
	end
	return true
end

function SurveillanceModel.validateCameras(
	cameras: { CameraDef },
	nodeIds: { string },
	mustCover: { string }
): { string }
	local errors: { string } = {}
	local nodeSet: { [string]: boolean } = {}
	for _, nodeId in nodeIds do
		nodeSet[nodeId] = true
	end
	local seen: { [string]: boolean } = {}
	local covered: { [string]: boolean } = {}
	for _, camera in cameras do
		if type(camera.id) ~= "string" or camera.id == "" then
			table.insert(errors, "camera with empty id")
			continue
		end
		if seen[camera.id] then
			table.insert(errors, "duplicate camera " .. camera.id)
		end
		seen[camera.id] = true
		if type(camera.displayName) ~= "string" or camera.displayName == "" then
			table.insert(errors, camera.id .. " has no display name")
		end
		if type(camera.coverage) ~= "table" or #camera.coverage == 0 then
			table.insert(errors, camera.id .. " covers no route node")
		else
			for _, nodeId in camera.coverage do
				if not nodeSet[nodeId] then
					table.insert(errors, camera.id .. " covers unknown node " .. tostring(nodeId))
				end
				covered[nodeId] = true
			end
		end
		if camera.position ~= nil and not validVector(camera.position) then
			table.insert(errors, camera.id .. " has an invalid world position")
		end
		if camera.lookAt ~= nil and not validVector(camera.lookAt) then
			table.insert(errors, camera.id .. " has an invalid look target")
		end
	end
	for _, nodeId in mustCover do
		if not covered[nodeId] then
			table.insert(errors, "no camera covers " .. nodeId)
		end
	end
	return errors
end

--//Functions//--
function SurveillanceModel.new(config: Config, cameras: { CameraDef }): Model
	local byId: { [string]: CameraDef } = {}
	local order: { string } = {}
	for _, camera in cameras do
		byId[camera.id] = camera
		table.insert(order, camera.id)
	end
	return setmetatable({
		config = config,
		cameras = byId,
		order = order,
		monitorOpen = false,
		selected = nil,
		selectedAt = 0,
		lastSwitchAt = -math.huge,
		jammedUntil = {},
		offline = false,
		strain = 0,
	}, SurveillanceModel) :: any
end

function SurveillanceModel.setMonitor(self: Model, open: boolean, now: number): (boolean, string)
	if type(open) ~= "boolean" then
		return false, "bad_type"
	end
	if open == self.monitorOpen then
		return true, "unchanged"
	end
	if open then
		if self.offline then
			return false, "offline"
		end
		self.monitorOpen = true
		if self.selected == nil then
			self.selected = self.order[1]
		end
		self.selectedAt = now
		return true, "ok"
	end
	self.monitorOpen = false
	return true, "ok"
end

function SurveillanceModel.selectCamera(self: Model, id: any, now: number): (boolean, string)
	if type(id) ~= "string" or #id > 16 then
		return false, "bad_type"
	end
	if self.cameras[id] == nil then
		return false, "unknown_camera"
	end
	if not self.monitorOpen then
		return false, "monitor_closed"
	end
	if self.selected == id then
		return true, "unchanged"
	end
	if now - self.lastSwitchAt < self.config.minSwitchInterval then
		return false, "too_fast"
	end
	self.selected = id
	self.selectedAt = now
	self.lastSwitchAt = now
	return true, "ok"
end

function SurveillanceModel.feedStatus(self: Model, id: string, now: number): string
	if self.offline then
		return "offline"
	end
	if (self.jammedUntil[id] or -math.huge) > now then
		return "jammed"
	end
	return "ok"
end

function SurveillanceModel.observedNodes(self: Model, now: number): { [string]: boolean }
	local nodes: { [string]: boolean } = {}
	local selected = self.selected
	if not self.monitorOpen or selected == nil then
		return nodes
	end
	if now - self.selectedAt < self.config.selectionDwell then
		return nodes
	end
	if self:feedStatus(selected, now) ~= "ok" then
		return nodes
	end
	for _, nodeId in self.cameras[selected].coverage do
		nodes[nodeId] = true
	end
	return nodes
end

function SurveillanceModel.jam(self: Model, id: string, now: number, duration: number)
	self.jammedUntil[id] = now + duration
end

function SurveillanceModel.setOffline(self: Model, offline: boolean)
	self.offline = offline
	if offline then
		self.monitorOpen = false
	end
end

function SurveillanceModel.step(self: Model, dt: number, now: number, targetNode: string?): { Event }
	local events: { Event } = {}
	local selected = self.selected
	local watched = targetNode ~= nil and self:observedNodes(now)[targetNode] == true
	if watched and selected ~= nil then
		self.strain += dt
		if self.strain >= self.config.observeLimit then
			self.strain = 0
			self:jam(selected, now, self.config.jamDuration)
			table.insert(events, { kind = "FeedJammed", cameraId = selected, duration = self.config.jamDuration })
		end
	else
		self.strain = math.max(0, self.strain - dt * self.config.observeDecay)
	end
	return events
end

--//Cleanup//--
return SurveillanceModel
