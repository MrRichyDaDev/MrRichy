--!strict
local process = require("@lune/process")

--//Types//--
type TestCase = { name: string, fn: () -> () }
type Suite = { name: string, tests: { TestCase }, test: (name: string, fn: () -> ()) -> () }

--//State//--
local Harness = {}
local suites: { Suite } = {}

--//Functions//--
function Harness.suite(name: string): Suite
	local suite: Suite = { name = name, tests = {}, test = function() end }
	suite.test = function(testName: string, fn: () -> ())
		table.insert(suite.tests, { name = testName, fn = fn })
	end
	table.insert(suites, suite)
	return suite
end

function Harness.eq(actual: any, expected: any, message: string?)
	if actual ~= expected then
		error(string.format("%s: expected %s, got %s", message or "eq", tostring(expected), tostring(actual)), 2)
	end
end

function Harness.near(actual: number, expected: number, tolerance: number, message: string?)
	if math.abs(actual - expected) > tolerance then
		error(
			string.format(
				"%s: expected %s +/- %s, got %s",
				message or "near",
				tostring(expected),
				tostring(tolerance),
				tostring(actual)
			),
			2
		)
	end
end

function Harness.truthy(value: any, message: string?)
	if not value then
		error((message or "truthy") .. ": value was falsy", 2)
	end
end

function Harness.falsy(value: any, message: string?)
	if value then
		error((message or "falsy") .. ": value was truthy", 2)
	end
end

function Harness.contains(list: { string }, needle: string, message: string?)
	for _, item in list do
		if string.find(item, needle, 1, true) then
			return
		end
	end
	error(
		string.format("%s: no entry containing %q in [%s]", message or "contains", needle, table.concat(list, " | ")),
		2
	)
end

function Harness.run(): number
	local failures = 0
	local passed = 0
	for _, suite in suites do
		print(string.format("\n[%s]", suite.name))
		for _, case in suite.tests do
			local ok, err = xpcall(case.fn, function(message)
				return tostring(message) .. "\n" .. debug.traceback("", 2)
			end)
			if ok then
				passed += 1
				print("  ok   " .. case.name)
			else
				failures += 1
				print("  FAIL " .. case.name)
				print("       " .. string.gsub(tostring(err), "\n", "\n       "))
			end
		end
	end
	print(string.format("\n%d passed, %d failed", passed, failures))
	return failures
end

function Harness.exit(failures: number)
	process.exit(if failures == 0 then 0 else 1)
end

--//Cleanup//--
return Harness
