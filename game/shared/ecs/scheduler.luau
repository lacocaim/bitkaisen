local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Planck = require(ReplicatedStorage.Packages.Planck)
local PlanckRunService = require(ReplicatedStorage.Packages.PlanckRunService)
local PlanckJabby = require(ReplicatedStorage.Packages.PlanckJabby)

local Scheduler = Planck.Scheduler

local world = require(ReplicatedStorage.ecs.world)

local jabbyPlugin = PlanckJabby.new()
local runServicePlugin = PlanckRunService.Plugin.new()

local scheduler = Scheduler.new(world):addPlugin(jabbyPlugin):addPlugin(runServicePlugin)

return scheduler
