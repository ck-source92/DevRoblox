local RS = game:GetService("ReplicatedStorage")

local FormationSlot = require(RS.Shared.Classes.Soccer.FormationSlot)

local FormationFactory = {}

local FORMATION = {
	{ row = 1, cols = 4 }, -- defender
	{ row = 2, cols = 3 }, -- midfielder
	{ row = 3, cols = 3 }, -- forward
}

function FormationFactory.Generate(fieldStart, fieldEnd, fieldWidth)
	local fieldLength = fieldEnd - fieldStart
	local slots = {}
	local npcIndex = 1

	for _, line in ipairs(FORMATION) do
		local zDepth = fieldStart + (fieldLength * (line.row / 4))
		local spacing = fieldWidth / (line.cols + 1)

		for col = 1, line.cols do
			local xOffset = -fieldWidth / 2 + (spacing * col)
			local offset = Vector3.new(xOffset, 0, zDepth)

			slots[npcIndex] = FormationSlot.new(line.row, col, offset)
			npcIndex = npcIndex + 1
		end
	end

	return slots -- 10 slots total
end

return FormationFactory
