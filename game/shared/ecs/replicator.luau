local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replecs = require(ReplicatedStorage.Packages.Replecs)
local world = require(ReplicatedStorage.ecs.world)

return replecs.create(world)
