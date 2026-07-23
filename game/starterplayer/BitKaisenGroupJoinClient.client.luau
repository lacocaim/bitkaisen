-- LocalScript: BitKaisenGroupJoinClient
-- Location: StarterPlayerScripts
-- Purpose:
--   Receives the server's prompt signal, shows the native group join dialog,
--   and fires back to the server to claim the reward on success.

local GroupService = game:GetService("GroupService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GROUP_ID = 212374896

local promptGroupJoin    = ReplicatedStorage:WaitForChild("PromptGroupJoin", 10)
local claimGroupJoinReward = ReplicatedStorage:WaitForChild("ClaimGroupJoinReward", 10)

if not promptGroupJoin or not claimGroupJoinReward then
	warn("[BitKaisenGroupJoinClient] Remotes not found - group join feature skipped.")
	return
end

promptGroupJoin.OnClientEvent:Connect(function()
	task.spawn(function()
		local ok, result = pcall(function()
			return GroupService:PromptJoinAsync(GROUP_ID)
		end)

		if not ok then
			warn("[BitKaisenGroupJoinClient] PromptJoinAsync failed: " .. tostring(result))
			return
		end

		if result == Enum.GroupMembershipStatus.Joined then
			claimGroupJoinReward:FireServer("Joined")
		elseif result == Enum.GroupMembershipStatus.AlreadyMember then
			claimGroupJoinReward:FireServer("AlreadyMember")
		end
	end)
end)
