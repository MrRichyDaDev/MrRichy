--!strict
local Harness = require("./Harness")

require("./suites/SeededRandom")
require("./suites/RateLimiter")
require("./suites/PowerModel")
require("./suites/RouteGraph")
require("./suites/SurveillanceModel")
require("./suites/WatcherBrain")
require("./suites/NightStateMachine")
require("./suites/NightCore")

Harness.exit(Harness.run())
