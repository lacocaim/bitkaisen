-- ModuleScript: BK_MissionService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose:
--   Phase 7 GameManager split.
--   Owns mission board payload + mission starting logic.
--   Mission choice resolution and core reward math still stay bridged through GameManager for safety.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BitKaisenMissions = require(ReplicatedStorage:WaitForChild("BitKaisenMissions"))
local BitKaisenSituations = require(ReplicatedStorage:WaitForChild("BitKaisenSituations"))

local BK_MissionService = {}
local context = {}

local function getStats(player)
	if context.GetStats then
		return context.GetStats(player)
	end
	return nil
end

local function ensureExtraStats(stats)
	if context.EnsureExtraStats then
		return context.EnsureExtraStats(stats)
	end
end

local function fireLifeUpdate(player, stats, message, forceResetLog)
	if context.FireLifeUpdate then
		return context.FireLifeUpdate(player, stats, message, forceResetLog)
	end
end

local function isCurseUser(stats)
	if context.IsCurseUser then
		return context.IsCurseUser(stats)
	end
	return false
end

local function isOfficialJujutsuSorcerer(stats)
	if context.IsOfficialJujutsuSorcerer then
		return context.IsOfficialJujutsuSorcerer(stats)
	end
	return false
end

local function getOfficialGradeName(grade)
	if context.GetOfficialGradeName then
		return context.GetOfficialGradeName(grade)
	end
	return tostring(grade or "Non-Sorcerer")
end

local function processCurseUserMission(player, stats, missionId)
	if context.ProcessCurseUserMission then
		return context.ProcessCurseUserMission(player, stats, missionId)
	end
end

local function generateCurseUserMissionBoard(stats)
	if context.GenerateCurseUserMissionBoard then
		return context.GenerateCurseUserMissionBoard(stats)
	end
	return {}
end

local function resolveMission(player, stats, missionData, choiceOption)
	if context.ResolveMission then
		return context.ResolveMission(player, stats, missionData, choiceOption)
	end
end

local MISSION_ATTEMPT_CAP_PER_AGE = 10

local function getPendingMissions()
	context.PendingMissions = context.PendingMissions or {}
	return context.PendingMissions
end

local function refreshMissionAttemptWindow(stats)
	local age = math.max(0, tonumber(stats and stats.Age) or 0)
	if tonumber(stats.MissionAttemptsWindowAge) ~= age then
		stats.MissionAttemptsWindowAge = age
		stats.MissionAttemptsThisAge = 0
	end
	stats.MissionAttemptsThisAge = math.max(0, tonumber(stats.MissionAttemptsThisAge) or 0)
end

local function canUseMissionAttempt(player, stats)
	refreshMissionAttemptWindow(stats)
	if (tonumber(stats.MissionAttemptsThisAge) or 0) >= MISSION_ATTEMPT_CAP_PER_AGE then
		fireLifeUpdate(player, stats, "You already handled 10 mission/special mission attempts this age. Age up before taking more.")
		return false
	end
	return true
end

local function consumeMissionAttempt(stats)
	refreshMissionAttemptWindow(stats)
	stats.MissionAttemptsThisAge = math.min(MISSION_ATTEMPT_CAP_PER_AGE, (tonumber(stats.MissionAttemptsThisAge) or 0) + 1)
end


local function getCurrentEra(stats)
	local birthPath = typeof(stats and stats.BirthPath) == "table" and stats.BirthPath or nil
	return tostring(stats and (stats.CurrentEra or stats.Era) or (birthPath and birthPath.Era) or "")
end

local function isHeianEra(stats)
	return getCurrentEra(stats) == "Heian Era"
end

local function isRogueSorcerer(stats)
	return tostring(stats and stats.LifePath or "") == "Rogue Sorcerer"
		or tostring(stats and stats.SocietyStatus or "") == "Rogue Sorcerer"
		or tostring(stats and stats.Affiliation or "") == "Rogue"
end

local function withRogueMissionAccess(stats, callback)
	if not isRogueSorcerer(stats) or isCurseUser(stats) then
		return callback()
	end

	local oldIsCurseUser = stats.IsCurseUser
	local oldCurseUser = stats.CurseUser
	local oldPath = stats.Path
	local oldSorcererPath = stats.SorcererPath
	local oldAlignment = stats.Alignment

	stats.IsCurseUser = true
	stats.CurseUser = true
	stats.Path = "Curse User"
	stats.SorcererPath = "Curse User"
	stats.Alignment = "Curse User"

	local ok, result = pcall(callback)

	stats.IsCurseUser = oldIsCurseUser
	stats.CurseUser = oldCurseUser
	stats.Path = oldPath
	stats.SorcererPath = oldSorcererPath
	stats.Alignment = oldAlignment

	if not ok then
		error(result)
	end

	return result
end


local function showMissionSituation(player, payload)
	local remote = context.ShowMissionSituation
	if remote and remote.FireClient then
		remote:FireClient(player, payload)
	end
end

function BK_MissionService.GetMissionBoardPayload(player)
	local stats = getStats(player)

	if not stats or not stats.Alive then
		return {}
	end

	ensureExtraStats(stats)

	if isCurseUser(stats) or isRogueSorcerer(stats) then
		return withRogueMissionAccess(stats, function()
			return generateCurseUserMissionBoard(stats)
		end)
	end

	if isHeianEra(stats) then
		return BitKaisenMissions.GenerateHeianMissionBoard(stats)
	end

	if (stats.Age or 0) < 16 then
		return {}
	end

	if not isOfficialJujutsuSorcerer(stats) then
		return {}
	end

	return BitKaisenMissions.GenerateMissionBoard(getOfficialGradeName(stats.Grade))
end

function BK_MissionService.ProcessMission(player, missionId)
	local stats = getStats(player)

	if not stats or not stats.Alive then
		return
	end

	ensureExtraStats(stats)

	if isCurseUser(stats) or isRogueSorcerer(stats) then
		if typeof(missionId) ~= "string" then
			return
		end
		if not canUseMissionAttempt(player, stats) then
			return
		end
		consumeMissionAttempt(stats)
		withRogueMissionAccess(stats, function()
			processCurseUserMission(player, stats, missionId)
		end)
		return
	end

	if typeof(missionId) ~= "string" then
		return
	end

	local missionData = BitKaisenMissions.GetMissionById(missionId)

	if not missionData then
		fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ SYSTEM ]</b></font> Invalid mission.")
		return
	end

	if isHeianEra(stats) then
		if not BitKaisenMissions.IsHeianMission(missionData) then
			fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ LOCKED ]</b></font> This is not a Heian Era commission.")
			return
		end

		if (stats.Age or 0) < 10 then
			fireLifeUpdate(player, stats, "You are too young to accept dangerous Heian Era commissions.")
			return
		end

		if not BitKaisenMissions.CanAttemptHeianMission(stats, missionData) then
			fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ LOCKED ]</b></font> Your cursed energy, mastery, and reputation are not enough for this Heian commission.")
			return
		end
	else
		if (stats.Age or 0) < 16 then
			fireLifeUpdate(player, stats, "You are too young to take official missions. You need to be at least 16.")
			return
		end

		if not isOfficialJujutsuSorcerer(stats) then
			fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ LOCKED ]</b></font> Curse missions are only available after you are registered through Jujutsu High. Current status: <b>" .. tostring(stats.Grade or "Unregistered") .. "</b>.")
			return
		end

		if BitKaisenMissions.IsHeianMission(missionData) then
			fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ LOCKED ]</b></font> That commission belongs to the Heian Era.")
			return
		end

		if not BitKaisenMissions.CanAttemptMission(getOfficialGradeName(stats.Grade), missionData.Grade) then
			fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ LOCKED ]</b></font> You are not qualified for this mission.")
			return
		end
	end

	local pendingMissions = getPendingMissions()
	if pendingMissions[player.UserId] then
		fireLifeUpdate(player, stats, "You are still handling a previous situation.")
		return
	end

	if not canUseMissionAttempt(player, stats) then
		return
	end
	consumeMissionAttempt(stats)

	local situation = BitKaisenSituations.RollSituation(stats, missionData)

	if not situation then
		resolveMission(player, stats, missionData, nil)
		return
	end

	local availableOptions = BitKaisenSituations.GetOptionsForPlayer(situation, stats)

	if #availableOptions < 2 then
		resolveMission(player, stats, missionData, nil)
		return
	end

	local optionDisplay = {}

	for i, option in ipairs(availableOptions) do
		table.insert(optionDisplay, {
			Index = i,
			Text = option.Text
		})
	end

	pendingMissions[player.UserId] = {
		missionId = missionId,
		situationId = situation.Id,
		availableOptions = availableOptions
	}

	showMissionSituation(player, {
		MissionTitle = missionData.Title,
		Title = situation.Title,
		Body = situation.Body,
		Options = optionDisplay
	})
end

function BK_MissionService.Init(ctx)
	context = ctx or {}
	print("[BK_MissionService] Loaded Phase 7 mission handling with Heian Era commissions.")
end

return BK_MissionService
