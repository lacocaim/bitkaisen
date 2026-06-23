-- ModuleScript: BK_RivalService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose: Update 15 server-owned rival/reputation actions and encounters.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local BitKaisenRivals = require(ReplicatedStorage:WaitForChild("BitKaisenRivals"))

local BK_RivalService = {}
local context = {}
local pendingEncounters = {}

local TEST_PLACE_IDS = {
	[104206065947170] = true,
}

local function getStats(player)
	return context.GetStats and context.GetStats(player) or nil
end

local function ensure(stats)
	if context.EnsureExtraStats then context.EnsureExtraStats(stats) end
	BitKaisenRivals.Ensure(stats)
end

local function fireLifeUpdate(player, stats, message)
	if context.FireLifeUpdate then context.FireLifeUpdate(player, stats, message) end
end

local function fireMajorPopup(player, title, body, highlight, footer)
	if context.FireMajorPopup then context.FireMajorPopup(player, title, body, highlight, footer) end
end

local function saveStats(player, reason)
	if context.SaveStats then context.SaveStats(player, reason or "Rivals") end
end

local function canUseDebug(player)
	if context.IsDev and context.IsDev(player) then return true end
	if context.IsTestingPlace and context.IsTestingPlace() then return true end
	return RunService:IsStudio() or TEST_PLACE_IDS[game.PlaceId] == true
end

local function findRival(stats, rivalId)
	BitKaisenRivals.Ensure(stats)
	for _, rival in ipairs(stats.Rivals) do
		if tostring(rival.Id) == tostring(rivalId) then
			return rival
		end
	end
	return nil
end

local function getRivalDecisionKey(stats, rivalId, actionId)
	local age = tonumber(stats and stats.Age) or 0
	return tostring(age) .. ":" .. tostring(rivalId) .. ":" .. tostring(actionId)
end

local function hasUsedRivalDecision(stats, rivalId, actionId)
	stats.RivalDecisionsThisAge = typeof(stats.RivalDecisionsThisAge) == "table" and stats.RivalDecisionsThisAge or {}
	return stats.RivalDecisionsThisAge[getRivalDecisionKey(stats, rivalId, actionId)] == true
end

local function markRivalDecision(stats, rivalId, actionId)
	stats.RivalDecisionsThisAge = typeof(stats.RivalDecisionsThisAge) == "table" and stats.RivalDecisionsThisAge or {}
	stats.RivalDecisionsThisAge[getRivalDecisionKey(stats, rivalId, actionId)] = true
end

local function setPending(player, rival, source)
	if not player or not rival then return end
	pendingEncounters[player.UserId] = {
		RivalId = rival.Id,
		Source = tostring(source or "Yearly Encounter"),
		CreatedAt = os.clock(),
	}
end

local function getPendingPayload(player, stats)
	local pending = player and pendingEncounters[player.UserId]
	if not pending then return nil end
	local rival = findRival(stats, pending.RivalId)
	if not rival or tostring(rival.Status or "Active") ~= "Active" then
		pendingEncounters[player.UserId] = nil
		return nil
	end
	return {
		RivalId = rival.Id,
		Source = pending.Source,
		Name = rival.Name,
		Grade = rival.Grade,
		Age = rival.Age,
		Clan = rival.Clan,
		Technique = rival.Revealed and rival.Technique or "Unknown",
		Reason = rival.Reason,
		Threat = rival.Threat,
		Relationship = rival.Relationship,
	}
end

function BK_RivalService.GetPayload(player)
	local stats = getStats(player)
	if not stats then return { Rivals = {}, History = {}, PendingEncounter = nil, Debug = canUseDebug(player) } end
	ensure(stats)
	local payload = BitKaisenRivals.GetPayload(stats)
	payload.PendingEncounter = getPendingPayload(player, stats)
	payload.Debug = canUseDebug(player)
	return payload
end

function BK_RivalService.OnAgeUp(player, stats)
	if not player or not stats or stats.Alive == false then return "" end
	ensure(stats)
	local _, pathName = BitKaisenRivals.ApplyReputationDrift(stats)
	local rival = BitKaisenRivals.RollYearlyEncounter(stats)
	local text = ""
	if rival then
		setPending(player, rival, "Yearly Reputation Pressure")
		stats.RivalEncounters = math.max(0, tonumber(stats.RivalEncounters) or 0) + 1
		text = "<font color='#ff8c69'><b>[ RIVAL ]</b></font> <b>" .. tostring(rival.Name) .. "</b> stepped into your path. They are " .. tostring(rival.Reason or "watching your rise") .. ". Open <b>Rivals</b> to respond."
		fireMajorPopup(player, "RIVAL ENCOUNTER", tostring(rival.Name) .. " has challenged your era.", tostring(rival.Grade or "Unknown Grade"), tostring(rival.Reason or "A rivalry begins."))
	else
		local activeCount = #BitKaisenRivals.GetActiveRivals(stats)
		if activeCount > 0 and math.random(1, 100) <= 20 then
			text = "<font color='#ff8c69'><b>[ RIVAL PRESSURE ]</b></font> Your reputation as <b>" .. tostring(pathName) .. "</b> kept your rivals watching from a distance."
		end
	end
	if text ~= "" then saveStats(player, "RivalAgeUp") end
	return text
end

function BK_RivalService.ProcessAction(player, actionId, data)
	local stats = getStats(player)
	if not stats or stats.Alive == false then return false, "No active life." end
	ensure(stats)
	data = typeof(data) == "table" and data or {}
	actionId = tostring(actionId or "")

	if actionId == "generate_test_rival" then
		if not canUseDebug(player) then return false, "Debug rival generation is not available here." end
		local rival = BitKaisenRivals.CreateRival(stats)
		setPending(player, rival, "Manual Challenge")
		fireLifeUpdate(player, stats, "<font color='#ff8c69'><b>[ RIVAL ]</b></font> A new rival appeared: <b>" .. rival.Name .. "</b>.")
		saveStats(player, "RivalGenerated")
		return true
	end

	local rivalId = tostring(data.RivalId or (pendingEncounters[player.UserId] and pendingEncounters[player.UserId].RivalId) or "")
	local rival = findRival(stats, rivalId)
	if not rival then return false, "Rival not found." end

	if actionId == "fight" then
		if tostring(rival.Status or "Active") ~= "Active" then
			fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ RIVAL ]</b></font> " .. tostring(rival.Name or "This rival") .. " is no longer an active rivalry.")
			return false, "Rival is no longer active."
		end
		pendingEncounters[player.UserId] = nil
		local enemyConfig = {
			Name = rival.Name,
			Grade = rival.Grade,
			Kind = "Rival",
			Power = math.max(30, tonumber(rival.Threat) or 45),
			PowerScale = 1,
			Metadata = { RivalId = rival.Id },
			OnFinish = function(fightPlayer, session, winner, reason, fightStats)
				BitKaisenRivals.RecordCombatResult(fightStats or stats, rival.Id, winner)
			end,
		}
		local ok, message = context.StartCombat and context.StartCombat(player, "Rival Encounter", enemyConfig)
		if not ok then
			fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ RIVAL ]</b></font> " .. tostring(message or "Could not start rival combat."))
			return false, message
		end
		fireLifeUpdate(player, stats, "<font color='#ff8c69'><b>[ RIVAL ]</b></font> You engaged <b>" .. tostring(rival.Name) .. "</b> in combat.")
		return true
	elseif actionId == "talk_down" or actionId == "humiliate" or actionId == "spare" or actionId == "escape" or actionId == "intel" then
		if (actionId == "humiliate" or actionId == "spare") and hasUsedRivalDecision(stats, rival.Id, actionId) then
			local message = "You already used that decisive rival action this age. Age up before trying it again."
			fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ RIVAL ]</b></font> " .. message)
			return false, message
		end
		local ok, message = BitKaisenRivals.ResolveAction(stats, rival.Id, actionId)
		if ok then
			if actionId == "humiliate" or actionId == "spare" then
				markRivalDecision(stats, rival.Id, actionId)
			end
			if actionId ~= "intel" then pendingEncounters[player.UserId] = nil end
			fireLifeUpdate(player, stats, "<font color='#ff8c69'><b>[ RIVAL ]</b></font> " .. tostring(message))
			saveStats(player, "RivalAction")
		else
			fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ RIVAL ]</b></font> " .. tostring(message))
		end
		return ok, message
	end

	return false, "Unknown rival action."
end

function BK_RivalService.ClearPlayer(player)
	if player then pendingEncounters[player.UserId] = nil end
end

function BK_RivalService.Init(ctx)
	context = ctx or {}
	print("[BK_RivalService] Update 15 rival reputation service loaded.")
end

return BK_RivalService
