--!strict
-- Domain/Deliverable.luau
-- Pure logic for a deliverable's state (ownership, scoring).

local Deliverable = {}
Deliverable.__index = Deliverable

export type DeliverableState = {
	Owner: Player?,
	IsScored: boolean,
}

export type DeliverableImpl = {
	State: DeliverableState,
	AssignOwner: (self: DeliverableImpl, player: Player) -> boolean,
	ClearOwner: (self: DeliverableImpl) -> (),
	MarkAsScored: (self: DeliverableImpl) -> (),
}

function Deliverable.new(): DeliverableImpl
	local self = setmetatable({}, Deliverable)
	self.State = {
		Owner = nil,
		IsScored = false,
	}
	return (self :: any) :: DeliverableImpl
end

function Deliverable:AssignOwner(player: Player): boolean
	if self.State.IsScored then
		return false
	end
	if self.State.Owner and self.State.Owner ~= player then
		return false
	end

	self.State.Owner = player
	return true
end

function Deliverable:ClearOwner()
	self.State.Owner = nil
end

function Deliverable:MarkAsScored()
	self.State.IsScored = true
	self.State.Owner = nil -- Scored items become neutral/cleared
end

return Deliverable
