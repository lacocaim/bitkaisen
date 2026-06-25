local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local experienceMode = require("@ui-state/experienceMode")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local mode = experienceMode.waitForResolution()

if mode == "Mobile" then
	pcall(function()
		StarterGui.ScreenOrientation = Enum.ScreenOrientation.Portrait
	end)
	pcall(function()
		playerGui.ScreenOrientation = Enum.ScreenOrientation.Portrait
	end)
else
	pcall(function()
		StarterGui.ScreenOrientation = Enum.ScreenOrientation.Sensor
	end)
	pcall(function()
		playerGui.ScreenOrientation = Enum.ScreenOrientation.Sensor
	end)
end
