-- DEBUG ONLY: runs only in Studio
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local Players = game:GetService("Players")
print("[DEBUG SETUP] Loaded.")

local function setupPlayer(player)
	task.wait(6)
	print("[DEBUG SETUP] Ready for " .. player.Name)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, p in Players:GetPlayers() do
	task.spawn(setupPlayer, p)
end
