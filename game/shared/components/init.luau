local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jecs = require(ReplicatedStorage.Packages.Jecs)
local world = require(ReplicatedStorage.ecs.world)
local types = require(ReplicatedStorage.types)

local components = {
	Health = world:component() :: types.Id<types.HealthData>,
	AttackStats = world:component() :: types.Id<types.AttackStatsData>,
	PathFollower = world:component() :: types.Id<types.PathFollowerData>,
	EnemyStats = world:component() :: types.Id<types.EnemyStatsData>,
	DisplayInfo = world:component() :: types.Id<types.DisplayInfoData>,
	Model = world:component() :: types.Id<Model>,
	Owner = world:component() :: types.Id<Player>,
}

return components
