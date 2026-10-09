--!strict
--//Config//--
local RouteConfig = {
	start = "STORAGE",
	approach = "APPROACH",
	door = "OFFICE_DOOR",
	retreat = "LOBBY",
	nodes = {
		{ id = "STORAGE" },
		{ id = "ELECTRICAL" },
		{ id = "SERVICE_HALL" },
		{ id = "SHOWROOM" },
		{ id = "LOBBY" },
		{ id = "APPROACH" },
		{ id = "OFFICE_DOOR" },
	},
	edges = {
		{ from = "STORAGE", to = "SERVICE_HALL", travel = 5.8, weight = 3 },
		{ from = "STORAGE", to = "ELECTRICAL", travel = 7.0, weight = 2 },
		{ from = "ELECTRICAL", to = "SERVICE_HALL", travel = 6.2, weight = 1 },
		{ from = "SERVICE_HALL", to = "SHOWROOM", travel = 6.0, weight = 2 },
		{ from = "SERVICE_HALL", to = "LOBBY", travel = 6.0, weight = 2 },
		{ from = "SHOWROOM", to = "LOBBY", travel = 6.2, weight = 1 },
		{ from = "LOBBY", to = "APPROACH", travel = 5.4, weight = 1 },
		{ from = "APPROACH", to = "OFFICE_DOOR", travel = 2.6, weight = 1 },
	},
	positions = {
		STORAGE = { -42, -106 },
		ELECTRICAL = { 4, -108 },
		SERVICE_HALL = { -20, -85 },
		SHOWROOM = { -40, -65 },
		LOBBY = { 0, -65 },
		APPROACH = { 0, -30 },
		OFFICE_DOOR = { 0, -13 },
	},
	paths = {
		["STORAGE>SERVICE_HALL"] = { { -40, -91 }, { -40, -89 } },
		["STORAGE>ELECTRICAL"] = { { -22, -107.5 }, { -18, -107.5 } },
		["ELECTRICAL>SERVICE_HALL"] = { { 0, -91 }, { 0, -89 } },
		["SERVICE_HALL>SHOWROOM"] = { { -40, -84 }, { -40, -78 } },
		["SERVICE_HALL>LOBBY"] = { { 0, -84 }, { 0, -78 } },
		["SHOWROOM>LOBBY"] = { { -22, -65 }, { -18, -65 } },
		["LOBBY>APPROACH"] = { { 0, -51 }, { 0, -48 } },
		["APPROACH>OFFICE_DOOR"] = {},
	},
}

--//Cleanup//--
return RouteConfig
