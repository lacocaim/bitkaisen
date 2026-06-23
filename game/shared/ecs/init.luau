local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Packages.Replecs)
require(ReplicatedStorage.components)

local world = require(ReplicatedStorage.ecs.world)
local replicator = require(ReplicatedStorage.ecs.replicator)
local scheduler = require(ReplicatedStorage.ecs.scheduler)
local startup = require(ReplicatedStorage.ecs.startup)

return {
	world = world,
	replicator = replicator,
	scheduler = scheduler,
	startup = startup,
}
