--[[
    ILogWritter.lua
    Interface: Defines the contract for log writers
]]

export type ILogWriter = {
	Write: (self: ILogWriter, logEntry: any) -> (),
	Flush: (self: ILogWriter) -> (),
	Close: (self: ILogWriter) -> (),
}

return {}
