-- LocalScript: BitKaisenMobileOrientationLock
-- Mobile orientation is intentionally unlocked so players can use portrait or landscape.

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function allowDeviceOrientation()
	pcall(function()
		StarterGui.ScreenOrientation = Enum.ScreenOrientation.Sensor
	end)
	pcall(function()
		playerGui.ScreenOrientation = Enum.ScreenOrientation.Sensor
	end)
end

allowDeviceOrientation()
