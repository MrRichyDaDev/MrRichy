--!strict
--//Config//--
local WatcherConfig = {
	[1] = {
		graceSeconds = 40,
		moveIntervalMin = 14,
		moveIntervalMax = 22,
		cueLeadTime = 3.5,
		approachExtraMin = 1.5,
		approachExtraMax = 5,
		blockedWaitMin = 5,
		blockedWaitMax = 8,
		reactionWindow = 1.75,
		rushSpeedFactor = 0.6,
		scrapeInterval = 2.5,
		logLimit = 400,
	},
}

--//Cleanup//--
return WatcherConfig
