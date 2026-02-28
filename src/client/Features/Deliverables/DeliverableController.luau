--!strict
-- Features/Deliverables/DeliverableController.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local DeliverableController = Knit.CreateController({
	Name = "DeliverableController",
})

function DeliverableController:KnitStart()
	print("[DeliverableController] Started")
end

return DeliverableController
