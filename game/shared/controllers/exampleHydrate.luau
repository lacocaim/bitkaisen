--[[
	Example of how to hydrate a Studio-authored UI template using Fusion.

	The template lives in Studio (e.g. StarterGui.HUD.HealthBar).
	This controller binds reactive state to it at runtime.

	Usage pattern:
		1. Get a reference to the UI template instance
		2. Create a Fusion scope
		3. Hydrate the instance with reactive properties
		4. Clean up the scope on teardown
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local function init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local scope = Fusion:scoped()

	local healthPct = scope:Value(1)

	-- Hydrate a Studio template: bind reactive state to its properties
	-- The template "HUD.HealthBar.Fill" must exist in Studio's StarterGui
	local hud = playerGui:WaitForChild("HUD", 10)
	if not hud then
		return
	end

	local fill = hud:FindFirstChild("HealthBar") and hud.HealthBar:FindFirstChild("Fill")
	if fill then
		scope:Hydrate(fill) {
			Size = scope:Computed(function(use)
				return UDim2.fromScale(use(healthPct), 1)
			end),
			BackgroundColor3 = scope:Computed(function(use)
				local pct = use(healthPct)
				return Color3.fromRGB(
					math.floor(255 * (1 - pct)),
					math.floor(255 * pct),
					0
				)
			end),
		}
	end

	return function()
		Fusion.doCleanup(scope)
	end
end

return {
	init = init,
}
