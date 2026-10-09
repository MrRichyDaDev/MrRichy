--!strict
--//Config//--
local PowerConfig = {
	startPower = 100,
	maxPower = 100,
	baselineDrain = 0.08,
	deviceDrain = {
		Tablet = 0.04,
		Door = 0.16,
		Light = 0.08,
	},
	thresholds = { 25, 10 },
}

--//Cleanup//--
return PowerConfig
