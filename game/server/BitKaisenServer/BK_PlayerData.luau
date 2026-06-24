-- ModuleScript: BK_PlayerData
-- Location: ServerScriptService.BitKaisenServer
-- Purpose:
--   Future home for playerLives, save/load, autosave, selected slots, and session data.
--   This module is intentionally small right now.
--
-- Important:
--   GameManager currently stores playerLives by UserId, not by Player instance.
--   This module follows that same rule so future modular splits do not desync state.

local BK_PlayerData = {}

BK_PlayerData.PlayerLives = {}
BK_PlayerData.PendingMissions = {}
BK_PlayerData.PendingLegacy = {}

local function getKey(playerOrUserId)
	if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
		return playerOrUserId.UserId
	end

	return playerOrUserId
end

function BK_PlayerData.Init()
	if game:GetService("RunService"):IsStudio() then print("[BK_PlayerData] Loaded.") end
end

function BK_PlayerData.GetStats(playerOrUserId)
	local key = getKey(playerOrUserId)
	if key == nil then
		return nil
	end

	return BK_PlayerData.PlayerLives[key]
end

function BK_PlayerData.SetStats(playerOrUserId, stats)
	local key = getKey(playerOrUserId)
	if key == nil then
		return nil
	end

	BK_PlayerData.PlayerLives[key] = stats
	return stats
end

function BK_PlayerData.GetPendingMission(playerOrUserId)
	local key = getKey(playerOrUserId)
	if key == nil then
		return nil
	end

	return BK_PlayerData.PendingMissions[key]
end

function BK_PlayerData.SetPendingMission(playerOrUserId, missionData)
	local key = getKey(playerOrUserId)
	if key == nil then
		return nil
	end

	BK_PlayerData.PendingMissions[key] = missionData
	return missionData
end

function BK_PlayerData.ClearPendingMission(playerOrUserId)
	local key = getKey(playerOrUserId)
	if key == nil then
		return
	end

	BK_PlayerData.PendingMissions[key] = nil
end

function BK_PlayerData.GetPendingLegacy(playerOrUserId)
	local key = getKey(playerOrUserId)
	if key == nil then
		return nil
	end

	return BK_PlayerData.PendingLegacy[key]
end

function BK_PlayerData.SetPendingLegacy(playerOrUserId, legacyData)
	local key = getKey(playerOrUserId)
	if key == nil then
		return nil
	end

	BK_PlayerData.PendingLegacy[key] = legacyData
	return legacyData
end

function BK_PlayerData.ClearPendingLegacy(playerOrUserId)
	local key = getKey(playerOrUserId)
	if key == nil then
		return
	end

	BK_PlayerData.PendingLegacy[key] = nil
end

function BK_PlayerData.Clear(playerOrUserId)
	local key = getKey(playerOrUserId)
	if key == nil then
		return
	end

	BK_PlayerData.PlayerLives[key] = nil
	BK_PlayerData.PendingMissions[key] = nil
	BK_PlayerData.PendingLegacy[key] = nil
end

return BK_PlayerData
