local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Spring = Fusion.Spring

local function useSpring(goal, speed: number?, dampingRatio: number?)
	return Spring(goal, speed or 25, dampingRatio or 1)
end

return useSpring
