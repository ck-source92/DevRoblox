-- TestRunner.server.lua
-- This script runs all unit tests using TestEZ
-- Runs independently without starting game services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for packages to load
if not ReplicatedStorage:FindFirstChild("Packages") then
	warn("[TestRunner] Packages folder not found!")
	return
end

local TestEZ = require(ReplicatedStorage.Packages.TestEZ)

local separator = string.rep("=", 50)

print(separator)
print("Starting TestEZ Test Runner...")
print(separator)

-- Run all tests in the Shared folder (will find all .spec.lua files)
local success, results = pcall(function()
	return TestEZ.TestBootstrap:run({
		ReplicatedStorage.Shared,
	})
end)

if not success then
	warn(separator)
	warn("✗ TEST RUNNER ERROR!")
	warn("Error: " .. tostring(results))
	warn(separator)
	return
end

-- Print results
print("\n" .. separator)
if results.failureCount == 0 then
	print("✓ ALL TESTS PASSED!")
	print(
		string.format(
			"Passed: %d | Failed: %d | Skipped: %d",
			results.successCount,
			results.failureCount,
			results.skippedCount
		)
	)
else
	warn("✗ TESTS FAILED!")
	warn(
		string.format(
			"Passed: %d | Failed: %d | Skipped: %d",
			results.successCount,
			results.failureCount,
			results.skippedCount
		)
	)
end
print(separator)
