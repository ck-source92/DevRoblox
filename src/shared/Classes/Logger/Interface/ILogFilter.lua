--[[
    ILogFilter.lua
    Interface: Defines contract for log filters
    Follows Interface Segregation Principle
]]

export type ILogFilter = {
	ShouldLog: (self: ILogFilter, logEntry: any) -> boolean,
}

return {}
