local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Planck = require(ReplicatedStorage.Packages.Planck)
local world = require(ReplicatedStorage.ecs.world)
local components = require(ReplicatedStorage.components)

return {
	system = function()
		-- Placeholder: clean up entities marked for deletion
	end,
	phase = Planck.Phases.Cleanup,
}
