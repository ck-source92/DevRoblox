local ObbyRepository = {}
ObbyRepository.__index = ObbyRepository

function ObbyRepository.new()
	local self = setmetatable({}, ObbyRepository)
	self._obstacles = {}
	return self
end

function ObbyRepository:GetById(id: string)
	return self._obstacles[id]
end

function ObbyRepository:GetAll()
	local allObstacles = {}
	for id, obstacle in pairs(self._obstacles) do
		table.insert(allObstacles, obstacle)
	end
	return allObstacles
end

function ObbyRepository:Save(obstacle)
	self._obstacles[obstacle.Id] = obstacle
	return true
end

function ObbyRepository:Delete(id: string)
	self._obstacles[id] = nil
	return true
end

return ObbyRepository
