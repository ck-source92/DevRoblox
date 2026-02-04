local RobloxDataStoreService = {}
RobloxDataStoreService.__index = RobloxDataStoreService

function RobloxDataStoreService.new()
	local self = setmetatable({}, RobloxDataStoreService)

	self.DataStoreService = game:GetService("DataStoreService")
	self._dataStores = {}

	return self
end

function RobloxDataStoreService:GetDataStore(name: string)
	if not self._dataStores[name] then
		self._dataStores[name] = self.DataStoreService:GetDataStore(name)
	end
	return self._dataStores[name]
end

function RobloxDataStoreService:GetAsync(key: string)
	local success, result = pcall(function()
		local dataStore = self:GetDataStore("MainDataStore")
		return dataStore:GetAsync(key)
	end)

	return success and result or nil
end

function RobloxDataStoreService:SetAsync(key: string, value: any)
	local success, result = pcall(function()
		local dataStore = self:GetDataStore("MainDataStore")
		dataStore:SetAsync(key, value)
		return true
	end)

	return success
end

return RobloxDataStoreService
