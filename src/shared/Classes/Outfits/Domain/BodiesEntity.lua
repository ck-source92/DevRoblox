export type BodyEntity = {
	Id: number,
	Name: string,
	DisplayName: string,
}

local BodyEntity = {}
BodyEntity.__index = BodyEntity

function BodyEntity.new(data: BodyEntity)
	local self = setmetatable({}, BodyEntity)

	self.itemId = data.Id
	self.name = data.Name
	self.displayName = data.DisplayName

	return self
end

return BodyEntity
