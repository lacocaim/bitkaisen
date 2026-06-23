-- LocalScript: BitKaisenMissionUnstuckClient
-- Location: StarterPlayerScripts
-- Purpose:
--   Safety net for mission/event soft-locks.
--   Press U while testing to clear a stuck mission/event pending state.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local clearPendingMission = ReplicatedStorage:WaitForChild("ClearPendingMission")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.U then
		clearPendingMission:FireServer()
	end
end)
