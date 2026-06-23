local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ECS = require(ReplicatedStorage.ecs)
local remotes = require(ReplicatedStorage.remotes)

local startup = ECS.startup
local replicator = ECS.replicator

replicator.client:init()

local systems = {
	ReplicatedStorage.systems,
}

startup(systems)

remotes.RequestSnapshot.Send(nil)
