--[[
	Example: hydrate a Studio-authored UI template using Fusion 0.2.

	The template lives in Studio (e.g. StarterGui.HUD.HealthBar).
	This controller binds reactive state to it at runtime.

	Pattern:
		1. Get a reference to the UI template instance
		2. Create Fusion Value/Computed objects
		3. Hydrate the instance with reactive properties
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Value = Fusion.Value
local Computed = Fusion.Computed
local Hydrate = Fusion.Hydrate

local function init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local healthPct = Value(1)

	local hud = playerGui:WaitForChild("HUD", 10)
	if not hud then
		return
	end

	local fill = hud:FindFirstChild("HealthBar") and hud.HealthBar:FindFirstChild("Fill")
	if fill then
		Hydrate(fill) {
			Size = Computed(function()
				return UDim2.fromScale(healthPct:get(), 1)
			end),
			BackgroundColor3 = Computed(function()
				local pct = healthPct:get()
				return Color3.fromRGB(
					math.floor(255 * (1 - pct)),
					math.floor(255 * pct),
					0
				)
			end),
		}
	end
end

return {
	init = init,
}
