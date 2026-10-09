--!strict
--//Types//--
export type NodeDef = { id: string }
export type EdgeDef = { from: string, to: string, travel: number, weight: number }

export type Definition = {
	start: string,
	approach: string,
	door: string,
	retreat: string,
	nodes: { NodeDef },
	edges: { EdgeDef },
}

export type Graph = {
	definition: Definition,
	nodeSet: { [string]: boolean },
	outgoing: { [string]: { EdgeDef } },
	incoming: { [string]: { EdgeDef } },
	forward: (self: Graph, nodeId: string) -> { EdgeDef },
	hop: (self: Graph, a: string, b: string) -> EdgeDef?,
	path: (self: Graph, from: string, to: string, reverse: boolean) -> { string }?,
	pathTravel: (self: Graph, path: { string }) -> number,
}

--//State//--
local RouteGraph = {}
RouteGraph.__index = RouteGraph

--//Functions//--
local function index(definition: Definition)
	local nodeSet: { [string]: boolean } = {}
	local outgoing: { [string]: { EdgeDef } } = {}
	local incoming: { [string]: { EdgeDef } } = {}
	for _, node in definition.nodes do
		nodeSet[node.id] = true
		outgoing[node.id] = {}
		incoming[node.id] = {}
	end
	for _, edge in definition.edges do
		if nodeSet[edge.from] and nodeSet[edge.to] then
			table.insert(outgoing[edge.from], edge)
			table.insert(incoming[edge.to], edge)
		end
	end
	return nodeSet, outgoing, incoming
end

local function reachable(
	start: string,
	adjacency: { [string]: { EdgeDef } },
	follow: (EdgeDef) -> string
): { [string]: boolean }
	local seen: { [string]: boolean } = { [start] = true }
	local queue = { start }
	local head = 1
	while head <= #queue do
		local current = queue[head]
		head += 1
		for _, edge in adjacency[current] or {} do
			local nextId = follow(edge)
			if not seen[nextId] then
				seen[nextId] = true
				table.insert(queue, nextId)
			end
		end
	end
	return seen
end

function RouteGraph.validate(definition: Definition): { string }
	local errors: { string } = {}
	local seenIds: { [string]: boolean } = {}
	for _, node in definition.nodes do
		if type(node.id) ~= "string" or node.id == "" then
			table.insert(errors, "node with empty id")
		elseif seenIds[node.id] then
			table.insert(errors, "duplicate node " .. node.id)
		end
		seenIds[node.id] = true
	end
	for _, role in { "start", "approach", "door", "retreat" } do
		local nodeId = (definition :: any)[role]
		if not seenIds[nodeId] then
			table.insert(errors, "role " .. role .. " names missing node " .. tostring(nodeId))
		end
	end
	for _, edge in definition.edges do
		if not seenIds[edge.from] or not seenIds[edge.to] then
			table.insert(
				errors,
				"edge " .. tostring(edge.from) .. ">" .. tostring(edge.to) .. " references a missing node"
			)
		elseif edge.from == edge.to then
			table.insert(errors, "self loop on " .. edge.from)
		end
		if type(edge.travel) ~= "number" or edge.travel ~= edge.travel or edge.travel <= 0 then
			table.insert(
				errors,
				"edge " .. tostring(edge.from) .. ">" .. tostring(edge.to) .. " needs a positive travel time"
			)
		end
		if type(edge.weight) ~= "number" or edge.weight ~= edge.weight or edge.weight <= 0 then
			table.insert(
				errors,
				"edge " .. tostring(edge.from) .. ">" .. tostring(edge.to) .. " needs a positive weight"
			)
		end
	end
	if #errors > 0 then
		return errors
	end

	local _, outgoing, incoming = index(definition)
	local fromStart = reachable(definition.start, outgoing, function(edge)
		return edge.to
	end)
	for _, node in definition.nodes do
		if not fromStart[node.id] then
			table.insert(errors, "node " .. node.id .. " is unreachable from start")
		end
	end
	local toDoor = reachable(definition.door, incoming, function(edge)
		return edge.from
	end)
	for _, node in definition.nodes do
		if not toDoor[node.id] then
			table.insert(errors, "node " .. node.id .. " cannot reach the door")
		end
	end
	if #outgoing[definition.door] > 0 then
		table.insert(errors, "door node must be terminal")
	end
	for _, edge in incoming[definition.door] do
		if edge.from ~= definition.approach then
			table.insert(errors, "door may only be entered from the approach node, found " .. edge.from)
		end
	end
	local approachOut = outgoing[definition.approach]
	if #approachOut ~= 1 or approachOut[1].to ~= definition.door then
		table.insert(errors, "approach node must lead only to the door")
	end
	if not toDoor[definition.retreat] or not fromStart[definition.retreat] then
		table.insert(errors, "retreat node is not on a route to the door")
	end
	return errors
end

function RouteGraph.new(definition: Definition): Graph
	local errors = RouteGraph.validate(definition)
	if #errors > 0 then
		error("invalid route graph: " .. table.concat(errors, "; "))
	end
	local nodeSet, outgoing, incoming = index(definition)
	return setmetatable({
		definition = definition,
		nodeSet = nodeSet,
		outgoing = outgoing,
		incoming = incoming,
	}, RouteGraph) :: any
end

function RouteGraph.forward(self: Graph, nodeId: string): { EdgeDef }
	return self.outgoing[nodeId] or {}
end

function RouteGraph.hop(self: Graph, a: string, b: string): EdgeDef?
	for _, edge in self.outgoing[a] or {} do
		if edge.to == b then
			return edge
		end
	end
	for _, edge in self.outgoing[b] or {} do
		if edge.to == a then
			return edge
		end
	end
	return nil
end

function RouteGraph.path(self: Graph, from: string, to: string, reverse: boolean): { string }?
	if not self.nodeSet[from] or not self.nodeSet[to] then
		return nil
	end
	local parents: { [string]: string } = {}
	local seen: { [string]: boolean } = { [from] = true }
	local queue = { from }
	local head = 1
	while head <= #queue do
		local current = queue[head]
		head += 1
		if current == to then
			break
		end
		local edges = if reverse then self.incoming[current] else self.outgoing[current]
		for _, edge in edges do
			local nextId = if reverse then edge.from else edge.to
			if not seen[nextId] then
				seen[nextId] = true
				parents[nextId] = current
				table.insert(queue, nextId)
			end
		end
	end
	if not seen[to] then
		return nil
	end
	local result = { to }
	local cursor = to
	while cursor ~= from do
		cursor = parents[cursor]
		table.insert(result, 1, cursor)
	end
	return result
end

function RouteGraph.pathTravel(self: Graph, path: { string }): number
	local total = 0
	for i = 1, #path - 1 do
		local edge = self:hop(path[i], path[i + 1])
		if edge then
			total += edge.travel
		end
	end
	return total
end

--//Cleanup//--
return RouteGraph
