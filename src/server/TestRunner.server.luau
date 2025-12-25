--!strict
-- TestRunner.server.luau
-- A simple standalone test runner to execute .spec modules.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local function getSpecs(root: Instance): { ModuleScript }
	local specs = {}
	for _, desc in ipairs(root:GetDescendants()) do
		if desc:IsA("ModuleScript") and desc.Name:match("%.spec$") then
			table.insert(specs, desc)
		end
	end
	return specs
end

-- Mini Test Framework
local function runSpec(module: ModuleScript)
	print("Running " .. module.Name .. "...")

	local env = getfenv()
	local currentDescribe = ""

	local passed = 0
	local failed = 0

	local function describe(desc, func)
		currentDescribe = desc
		-- print("  " .. desc)
		func()
	end

	local function it(desc, func)
		local success, err = pcall(func)
		if success then
			-- print("    [PASS] " .. desc)
			passed += 1
		else
			warn("    [FAIL] " .. desc .. " (" .. currentDescribe .. ")")
			warn("      " .. tostring(err))
			failed += 1
		end
	end

	local function expect(value)
		return {
			to = {
				equal = function(other)
					if value ~= other then
						error(string.format("Expected %s to equal %s", tostring(value), tostring(other)), 2)
					end
				end,
				be = {
					ok = function()
						if not value then
							error(string.format("Expected %s to be ok (truthy)", tostring(value)), 2)
						end
					end,
				},
			},
		}
	end

	-- Inject globals (Quick & Dirty for this runner)
	local fn = require(module)
	local testEnv = setmetatable({
		describe = describe,
		it = it,
		expect = expect,
	}, { __index = env })

	setfenv(fn, testEnv)

	-- Execute
	pcall(fn)

	print(string.format("  Result: %d passed, %d failed", passed, failed))
end

-- Main
task.delay(1, function()
	print("----- STARTING TESTS -----")
	local specs = getSpecs(ReplicatedStorage)

	for _, spec in ipairs(specs) do
		runSpec(spec)
	end
	print("----- FINISHED TESTS -----")
end)
