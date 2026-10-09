--!strict
--//Types//--
export type Event = { kind: string, [string]: any }

export type Config = {
	startPower: number,
	maxPower: number,
	baselineDrain: number,
	deviceDrain: { [string]: number },
	thresholds: { number },
}

export type Source = { id: string, rate: number }

export type Model = {
	config: Config,
	power: number,
	powerOut: boolean,
	devices: { [string]: boolean },
	fired: { [number]: boolean },
	thresholds: { number },
	setDevice: (self: Model, name: string, on: boolean) -> boolean,
	isOn: (self: Model, name: string) -> boolean,
	drainRate: (self: Model) -> number,
	sources: (self: Model) -> { Source },
	step: (self: Model, dt: number) -> { Event },
	setPower: (self: Model, value: number) -> { Event },
}

--//State//--
local PowerModel = {}
PowerModel.__index = PowerModel

--//Functions//--
local function applyPower(self: Model, value: number): { Event }
	local previous = self.power
	self.power = math.clamp(value, 0, self.config.maxPower)
	local events: { Event } = {}
	for _, threshold in self.thresholds do
		if previous > threshold and self.power <= threshold and not self.fired[threshold] then
			self.fired[threshold] = true
			table.insert(events, { kind = "Threshold", threshold = threshold })
		end
	end
	if self.power <= 0 and not self.powerOut then
		self.powerOut = true
		for name in self.devices do
			self.devices[name] = false
		end
		table.insert(events, { kind = "PowerOut" })
	end
	return events
end

function PowerModel.new(config: Config): Model
	local thresholds = table.clone(config.thresholds)
	table.sort(thresholds, function(a, b)
		return a > b
	end)
	local devices: { [string]: boolean } = {}
	for name in config.deviceDrain do
		devices[name] = false
	end
	local self = setmetatable({
		config = config,
		power = config.startPower,
		powerOut = false,
		devices = devices,
		fired = {},
		thresholds = thresholds,
	}, PowerModel) :: any
	return self :: Model
end

function PowerModel.setDevice(self: Model, name: string, on: boolean): boolean
	if self.config.deviceDrain[name] == nil then
		return false
	end
	if self.powerOut and on then
		return false
	end
	self.devices[name] = on
	return true
end

function PowerModel.isOn(self: Model, name: string): boolean
	return self.devices[name] == true
end

function PowerModel.sources(self: Model): { Source }
	local list: { Source } = {}
	if self.powerOut then
		return list
	end
	table.insert(list, { id = "Baseline", rate = self.config.baselineDrain })
	for name, drain in self.config.deviceDrain do
		if self.devices[name] then
			table.insert(list, { id = name, rate = drain })
		end
	end
	table.sort(list, function(a, b)
		return a.id < b.id
	end)
	return list
end

function PowerModel.drainRate(self: Model): number
	local total = 0
	for _, source in self:sources() do
		total += source.rate
	end
	return total
end

function PowerModel.step(self: Model, dt: number): { Event }
	if self.powerOut or dt <= 0 then
		return {}
	end
	return applyPower(self, self.power - self:drainRate() * dt)
end

function PowerModel.setPower(self: Model, value: number): { Event }
	for _, threshold in self.thresholds do
		if value > threshold then
			self.fired[threshold] = nil
		end
	end
	if value > 0 then
		self.powerOut = false
	end
	return applyPower(self, value)
end

--//Cleanup//--
return PowerModel
