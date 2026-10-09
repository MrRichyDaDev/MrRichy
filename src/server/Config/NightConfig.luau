--!strict
--//Config//--
local NightConfig = {
	tickSeconds = 0.1,
	hoursInShift = 6,
	startHourLabel = 12,
	doorCooldownSeconds = 0.6,
	lightCooldownSeconds = 0.3,
	light = {
		covers = { "APPROACH" },
		burnoutAfter = 8,
		lockoutSeconds = 6,
		recoverRate = 0.5,
	},
	nights = {
		[1] = {
			id = 1,
			title = "Orientation",
			durationSeconds = 480,
			startingSeconds = 4,
			watcherSeed = 1001,
			tutorial = true,
		},
	},
}

--//Cleanup//--
return NightConfig
