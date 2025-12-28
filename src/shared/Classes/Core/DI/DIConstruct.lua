local DIConstruct = {}
DIConstruct.__index = DIConstruct

function DIConstruct.new()
	local self = setmetatable({}, DIConstruct)

	self._instances = {}
	self._factories = {}

	return self
end

function DIConstruct:Register(interface, implementation, isSingleton: boolean?)
	self._factories[interface] = {
		implementation = implementation,
		isSingleton = isSingleton or false,
	}
end

function DIConstruct:Resolve(interface, ...)
	local factory = self._factories[interface]
	if not factory then
		error("No registration found for : ", interface)
	end

	if factory.isSingleton then
		if not self._instances[interface] then
			self._instances[interface] = factory.implementation.new(...)
		end
		return self._instances[interface]
	else
		return factory.implementation.new(...)
	end
end

return DIConstruct
