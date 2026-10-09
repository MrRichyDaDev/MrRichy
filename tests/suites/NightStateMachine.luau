--!strict
--//Modules//--
local Harness = require("../Harness")
local NightStateMachine = require("../../src/server/Core/NightStateMachine")

--//Config//--
local PHASES = { "Waiting", "Starting", "Active", "Won", "Lost", "Resetting" }

local EXPECTED: { [string]: { string } } = {
	Waiting = { "Starting" },
	Starting = { "Active", "Resetting" },
	Active = { "Won", "Lost", "Resetting" },
	Won = { "Resetting" },
	Lost = { "Resetting" },
	Resetting = { "Waiting", "Starting" },
}

--//Logic//--
local suite = Harness.suite("NightStateMachine")

suite.test("the allowed transitions are exactly the documented ones", function()
	for _, from in PHASES do
		for _, to in PHASES do
			local machine = NightStateMachine.new()
			machine.phase = from
			local expected = table.find(EXPECTED[from], to) ~= nil
			Harness.eq(machine:canTransition(to), expected, from .. " to " .. to)
		end
	end
end)

suite.test("a normal run walks Waiting to Won and records every step", function()
	local machine = NightStateMachine.new()
	Harness.eq(machine.runId, 0)
	Harness.truthy(machine:transition("Starting", "start", 0))
	Harness.eq(machine.runId, 1)
	Harness.truthy(machine:transition("Active", "intro", 4))
	Harness.truthy(machine:transition("Won", "shift_complete", 484))
	Harness.eq(#machine.history, 3)
	Harness.eq(machine.history[3].reason, "shift_complete")
	Harness.eq(machine.history[3].runId, 1)
end)

suite.test("an outcome can be reached only once per run", function()
	local machine = NightStateMachine.new()
	machine:transition("Starting", "start", 0)
	machine:transition("Active", "intro", 1)
	Harness.truthy(machine:transition("Won", "shift_complete", 2))
	Harness.falsy(machine:transition("Won", "again", 3), "second win")
	Harness.falsy(machine:transition("Lost", "late loss", 3), "loss after win")
	Harness.falsy(machine:transition("Active", "revive", 3), "back to Active")
end)

suite.test("a retry makes a new run and old run ids go stale", function()
	local machine = NightStateMachine.new()
	machine:transition("Starting", "start", 0)
	machine:transition("Active", "intro", 1)
	machine:transition("Lost", "watcher_attack", 2)
	local oldRun = machine.runId
	Harness.truthy(machine:isCurrent(oldRun), "current until reset")
	machine:transition("Resetting", "retry", 3)
	Harness.falsy(machine:isCurrent(oldRun), "stale while resetting")
	machine:transition("Starting", "start", 4)
	Harness.eq(machine.runId, oldRun + 1)
	Harness.falsy(machine:isCurrent(oldRun), "stale after the new run starts")
	Harness.truthy(machine:isCurrent(oldRun + 1), "new run is current")
end)

suite.test("Waiting is never a current run", function()
	local machine = NightStateMachine.new()
	Harness.falsy(machine:isCurrent(0))
	Harness.falsy(machine:isCurrent(1))
end)
