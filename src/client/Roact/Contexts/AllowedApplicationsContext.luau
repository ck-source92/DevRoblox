-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Roact = require(ReplicatedStorage.Packages.Roact)

-- Context
local AllowedApplicationsContext = Roact.createContext()

return AllowedApplicationsContext
