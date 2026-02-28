--[[
    LogLevel.lua
    Data Class: Defines log severity levels
]]

local LogLevel = {
	DEBUG = 1,
	INFO = 2,
	WARN = 3,
	ERROR = 4,
	FATAL = 5,
}

LogLevel.Names = {
	[LogLevel.DEBUG] = "DEBUG",
	[LogLevel.INFO] = "INFO",
	[LogLevel.WARN] = "WARN",
	[LogLevel.ERROR] = "ERROR",
	[LogLevel.FATAL] = "FATAL",
}

LogLevel.Colors = {
	[LogLevel.DEBUG] = Color3.fromRGB(150, 150, 150),
	[LogLevel.INFO] = Color3.fromRGB(100, 200, 255),
	[LogLevel.WARN] = Color3.fromRGB(255, 200, 0),
	[LogLevel.ERROR] = Color3.fromRGB(255, 100, 100),
	[LogLevel.FATAL] = Color3.fromRGB(200, 0, 0),
}

return LogLevel
