export type OutfitEntity = {
	Id: number,
	Name: string,
	DisplayName: string,
	Variant: string?,
	Price: number,
}

local OutfitEntity = {}
OutfitEntity.__index = OutfitEntity

function OutfitEntity.new(data: OutfitEntity)
	local self = setmetatable({}, OutfitEntity)

	self.itemId = data.Id
	self.name = data.Name
	self.displayName = data.DisplayName
	self.variant = data.Variant
	self.price = data.Price

	return self
end

return OutfitEntity
