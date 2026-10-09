--!strict
--//Config//--
local CameraConfig = {
	cameras = {
		{
			id = "CAM1",
			displayName = "Lobby",
			coverage = { "LOBBY" },
			position = { -18, 14.5, -52.5 },
			lookAt = { 6, 2, -72 },
		},
		{
			id = "CAM2",
			displayName = "Showroom",
			coverage = { "SHOWROOM" },
			position = { -58, 12.5, -52.5 },
			lookAt = { -36, 2, -72 },
		},
		{
			id = "CAM3",
			displayName = "Storage",
			coverage = { "STORAGE" },
			position = { -58, 12.5, -92.5 },
			lookAt = { -36, 1.5, -112 },
		},
		{
			id = "CAM4",
			displayName = "Service Hall",
			coverage = { "SERVICE_HALL" },
			position = { 18, 10, -85 },
			lookAt = { -30, 2.5, -85 },
		},
		{
			id = "CAM5",
			displayName = "Electrical Room",
			coverage = { "ELECTRICAL" },
			position = { 18, 10, -92.5 },
			lookAt = { -2, 1.5, -112 },
		},
		{
			id = "CAM6",
			displayName = "Office Approach",
			coverage = { "APPROACH" },
			position = { 0, 10, -48 },
			lookAt = { 0, 3, -12 },
		},
	},
	fieldOfView = 72,
}

--//Cleanup//--
return CameraConfig
