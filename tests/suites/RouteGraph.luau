--!strict
--//Modules//--
local Harness = require("../Harness")
local RouteGraph = require("../../src/server/Core/RouteGraph")
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

local function errorsFor(mutate: (any) -> ()): { string }
	local definition = copy(RouteConfig)
	mutate(definition)
	return RouteGraph.validate(definition)
end

local function polylineLength(from: string, to: string): number
	local points = { RouteConfig.positions[from] }
	for _, point in RouteConfig.paths[from .. ">" .. to] do
		table.insert(points, point)
	end
	table.insert(points, RouteConfig.positions[to])
	local total = 0
	for i = 1, #points - 1 do
		local dx = points[i + 1][1] - points[i][1]
		local dz = points[i + 1][2] - points[i][2]
		total += math.sqrt(dx * dx + dz * dz)
	end
	return total
end

--//Logic//--
local suite = Harness.suite("RouteGraph")

suite.test("the shipped route is valid", function()
	local errors = RouteGraph.validate(RouteConfig)
	Harness.eq(#errors, 0, table.concat(errors, "; "))
end)

suite.test("forward edges and paths match the design", function()
	local graph = RouteGraph.new(RouteConfig)
	local targets = {}
	for _, edge in graph:forward("STORAGE") do
		table.insert(targets, edge.to)
	end
	table.sort(targets)
	Harness.eq(table.concat(targets, ","), "ELECTRICAL,SERVICE_HALL", "storage exits")
	local shortest = graph:path("STORAGE", "OFFICE_DOOR", false)
	Harness.eq(table.concat(shortest :: { string }, ">"), "STORAGE>SERVICE_HALL>LOBBY>APPROACH>OFFICE_DOOR")
	Harness.near(graph:pathTravel(shortest :: { string }), 19.8, 1e-9, "shortest route travel time")
	local back = graph:path("OFFICE_DOOR", "LOBBY", true)
	Harness.eq(table.concat(back :: { string }, ">"), "OFFICE_DOOR>APPROACH>LOBBY", "retreat path")
	Harness.truthy(graph:hop("APPROACH", "LOBBY") ~= nil, "hop works against edge direction")
	Harness.eq(graph:path("OFFICE_DOOR", "STORAGE", false), nil, "no forward path out of the door")
end)

suite.test("every edge moves at a believable walking speed", function()
	for _, edge in RouteConfig.edges do
		local speed = polylineLength(edge.from, edge.to) / edge.travel
		Harness.truthy(
			speed >= 4 and speed <= 9,
			string.format("%s>%s implies %.1f studs/s", edge.from, edge.to, speed)
		)
	end
end)

suite.test("a missing node reference is rejected", function()
	Harness.contains(
		errorsFor(function(d)
			table.insert(d.edges, { from = "LOBBY", to = "NOWHERE", travel = 1, weight = 1 })
		end),
		"missing node"
	)
end)

suite.test("duplicate node ids are rejected", function()
	Harness.contains(
		errorsFor(function(d)
			table.insert(d.nodes, { id = "LOBBY" })
		end),
		"duplicate node"
	)
end)

suite.test("a dead end that cannot reach the door is rejected", function()
	local errors = errorsFor(function(d)
		table.insert(d.nodes, { id = "DEAD_END" })
		table.insert(d.edges, { from = "SERVICE_HALL", to = "DEAD_END", travel = 3, weight = 1 })
	end)
	Harness.contains(errors, "DEAD_END cannot reach the door")
end)

suite.test("an unreachable node is rejected", function()
	local errors = errorsFor(function(d)
		table.insert(d.nodes, { id = "ISLAND" })
		table.insert(d.edges, { from = "ISLAND", to = "LOBBY", travel = 3, weight = 1 })
	end)
	Harness.contains(errors, "ISLAND is unreachable")
end)

suite.test("a door with exits or a side entrance is rejected", function()
	Harness.contains(
		errorsFor(function(d)
			table.insert(d.edges, { from = "OFFICE_DOOR", to = "LOBBY", travel = 3, weight = 1 })
		end),
		"door node must be terminal"
	)
	Harness.contains(
		errorsFor(function(d)
			table.insert(d.edges, { from = "LOBBY", to = "OFFICE_DOOR", travel = 3, weight = 1 })
		end),
		"door may only be entered from the approach node"
	)
end)

suite.test("an approach node with extra exits is rejected", function()
	Harness.contains(
		errorsFor(function(d)
			table.insert(d.edges, { from = "APPROACH", to = "LOBBY", travel = 3, weight = 1 })
		end),
		"approach node must lead only to the door"
	)
end)

suite.test("bad travel times, weights and roles are rejected", function()
	Harness.contains(
		errorsFor(function(d)
			d.edges[1].travel = 0
		end),
		"positive travel time"
	)
	Harness.contains(
		errorsFor(function(d)
			d.edges[1].weight = 0 / 0
		end),
		"positive weight"
	)
	Harness.contains(
		errorsFor(function(d)
			d.retreat = "MOON"
		end),
		"role retreat"
	)
end)

suite.test("building an invalid graph raises", function()
	local definition = copy(RouteConfig)
	definition.start = "MOON"
	Harness.falsy((pcall(RouteGraph.new, definition)), "RouteGraph.new should raise")
end)
