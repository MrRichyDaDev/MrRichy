--!strict
--//Types//--
export type Record = { runId: number, from: string, to: string, reason: string, at: number }

export type Machine = {
	phase: string,
	runId: number,
	history: { Record },
	canTransition: (self: Machine, to: string) -> boolean,
	transition: (self: Machine, to: string, reason: string, at: number) -> boolean,
	isCurrent: (self: Machine, runId: number) -> boolean,
}

--//Config//--
local ALLOWED: { [string]: { [string]: boolean } } = {
	Waiting = { Starting = true },
	Starting = { Active = true, Resetting = true },
	Active = { Won = true, Lost = true, Resetting = true },
	Won = { Resetting = true },
	Lost = { Resetting = true },
	Resetting = { Waiting = true, Starting = true },
}

--//State//--
local NightStateMachine = {}
NightStateMachine.__index = NightStateMachine

--//Functions//--
function NightStateMachine.new(): Machine
	return setmetatable({ phase = "Waiting", runId = 0, history = {} }, NightStateMachine) :: any
end

function NightStateMachine.canTransition(self: Machine, to: string): boolean
	local row = ALLOWED[self.phase]
	return row ~= nil and row[to] == true
end

function NightStateMachine.transition(self: Machine, to: string, reason: string, at: number): boolean
	if not self:canTransition(to) then
		return false
	end
	local from = self.phase
	if to == "Starting" then
		self.runId += 1
	end
	self.phase = to
	table.insert(self.history, { runId = self.runId, from = from, to = to, reason = reason, at = at })
	return true
end

function NightStateMachine.isCurrent(self: Machine, runId: number): boolean
	return runId == self.runId and self.phase ~= "Waiting" and self.phase ~= "Resetting"
end

--//Cleanup//--
return NightStateMachine
