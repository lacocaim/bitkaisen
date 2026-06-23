local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local function useSpring(scope: Fusion.Scope, goal: Fusion.UsedAs<number>, speed: number?, dampingRatio: number?)
	return scope:Spring(goal, speed or 25, dampingRatio or 1)
end

return useSpring
