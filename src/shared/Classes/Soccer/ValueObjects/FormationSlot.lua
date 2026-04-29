local FormationSlot = {}
FormationSlot.__index = FormationSlot

function FormationSlot.new(row, col, offset)
	return setmetatable({
		row = row, -- 1=defender, 2=mid, 3=forward
		col = col, -- posisi horizontal
		offset = offset, -- Vector3 offset dari center
	}, FormationSlot)
end

return FormationSlot
