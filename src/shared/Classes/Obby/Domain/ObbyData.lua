local ObbyState = {
	VISIBLE = "Visible",
	INVISIBLE = "Invisible",
}

local ObbyType = {
	STATIC = 1,
	MOVING = 2,
	SEQUENCE = 3,

	LASER_HORIZONTAL = 4,
	LASER_VERTICAL = 5,
}

return {
	ObbyState = ObbyState,
	ObbyType = ObbyType,
}
