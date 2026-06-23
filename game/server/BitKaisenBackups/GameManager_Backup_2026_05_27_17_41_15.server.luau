-- Script: GameManager
-- Location: ServerScriptService
-- NOTE:
--   This version is register-limit safe.
--   Some top-level helper functions are intentionally non-local because Roblox/Luau
--   was refusing to compile the mega GameManager with "Out of local registers".
--   Do not blindly convert them back to local unless GameManager is split into modules.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

function ensureRemote(name, className)
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing then
		return existing
	end

	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

local updateLifeEvent = ensureRemote("UpdateLifeEvent", "RemoteEvent")
local showMajorPopup = ensureRemote("ShowMajorPopup", "RemoteEvent")
local showMissionSituation = ensureRemote("ShowMissionSituation", "RemoteEvent")
local missionChoice = ensureRemote("MissionChoice", "RemoteEvent")
local clearPendingMission = ensureRemote("ClearPendingMission", "RemoteEvent")
local getMissionBoard = ensureRemote("GetMissionBoard", "RemoteFunction")
local getActivityList = ensureRemote("GetActivityList", "RemoteFunction")
local getRelationships = ensureRemote("GetRelationships", "RemoteFunction")
local relationshipAction = ensureRemote("RelationshipAction", "RemoteEvent")
local getAssets = ensureRemote("GetAssets", "RemoteFunction")
local assetAction = ensureRemote("AssetAction", "RemoteEvent")
local getSuccessorOptions = ensureRemote("GetSuccessorOptions", "RemoteFunction")
local chooseSuccessor = ensureRemote("ChooseSuccessor", "RemoteEvent")
local updateSettingsEvent = ensureRemote("UpdateSettingsEvent", "RemoteEvent")

local getSaveSlots = ensureRemote("GetSaveSlots", "RemoteFunction")
local selectSaveSlot = ensureRemote("SelectSaveSlot", "RemoteEvent")
local createSaveSlot = ensureRemote("CreateSaveSlot", "RemoteEvent")
local deleteSaveSlot = ensureRemote("DeleteSaveSlot", "RemoteEvent")

local getAchievements = ensureRemote("GetAchievements", "RemoteFunction")
local claimAchievement = ensureRemote("ClaimAchievement", "RemoteEvent")
local redeemCode = ensureRemote("RedeemCode", "RemoteFunction")
local getCodeGate = ensureRemote("GetCodeGate", "RemoteFunction")
local getBindingVows = ensureRemote("GetBindingVows", "RemoteFunction")
local bindingVowAction = ensureRemote("BindingVowAction", "RemoteEvent")

local BitKaisenStats = require(ReplicatedStorage:WaitForChild("BitKaisenStats"))
local BitKaisenMissions = require(ReplicatedStorage:WaitForChild("BitKaisenMissions"))
local BitKaisenActivities = require(ReplicatedStorage:WaitForChild("BitKaisenActivities"))
local BitKaisenLifeEvents = require(ReplicatedStorage:WaitForChild("BitKaisenLifeEvents"))
local BitKaisenRelationships = require(ReplicatedStorage:WaitForChild("BitKaisenRelationships"))
local BitKaisenTraits = require(ReplicatedStorage:WaitForChild("BitKaisenTraits"))
local BitKaisenAssets = require(ReplicatedStorage:WaitForChild("BitKaisenAssets"))
local BitKaisenSituations = require(ReplicatedStorage:WaitForChild("BitKaisenSituations"))
local BitKaisenLegacy = require(ReplicatedStorage:WaitForChild("BitKaisenLegacy"))
local BitKaisenSaveSystem = require(ServerStorage:WaitForChild("BitKaisenSaveSystem"))

-- Put your own Roblox UserId(s) here. Anyone in this table can use dev_awaken
-- and will see hidden dev activities.
local DEV_USER_IDS = {
	[3575148423] = true,
}

local AUTOSAVE_INTERVAL = 120

-- Release-safe save throttling.
-- Most game actions should call saveStats(player), which schedules ONE save instead of writing immediately.
-- Only hard boundaries should call forceSaveStats(player): leaving, shutdown, slot switching, and purchases.
local SAVE_DEBOUNCE_SECONDS = 25
local SAVE_FORCE_MIN_GAP_SECONDS = 6

-- Replace these IDs with your real Roblox monetization IDs.
-- VIP_SORCERER_PASS_ID must be a GAME PASS ID.
-- The product IDs below must be DEVELOPER PRODUCT IDs.
local VIP_SORCERER_PASS_ID = 1847855390
local EXTRA_SAVE_SLOTS_PASS_ID = 1850884816
local DOUBLE_MONEY_PASS_ID = 1849510820
local DOUBLE_TRAINING_PASS_ID = 1849210885

local STARTER_SORCERER_PACK_PRODUCT_ID = 3595826857
local FOCUSED_TRAINING_PRODUCT_ID = 3595838153
local MONEY_5000_PRODUCT_ID = 3596044734
local MONEY_25000_PRODUCT_ID = 3595898637
local MONEY_100000_PRODUCT_ID = 3596045207
local RECRUIT_REROLL_PRODUCT_ID = 3596045471

-- Codes gate. Set BITKAISEN_GROUP_ID to your Roblox group ID before release.
-- Roblox does not expose a trustworthy per-player "liked the game" check to server scripts,
-- so likes are handled through a client confirmation gate while group membership is verified server-side.
local BITKAISEN_GROUP_ID = 212374896
local REQUIRE_GROUP_FOR_CODES = true
local REQUIRE_LIKE_CONFIRMATION_FOR_CODES = true


local VIP_CACHE_SECONDS = 60
local vipOwnershipCache = {}
local extraSaveSlotsOwnershipCache = {}
local doubleMoneyOwnershipCache = {}
local doubleTrainingOwnershipCache = {}

local RATE_LIMITS = {
	AgeUp = 0.4,
	DoMission = 0.6,
	DoActivity = 0.4,
	MissionChoice = 0.3,
	RelationshipAction = 0.75,
	AssetAction = 0.3,
	StartNewLife = 1.5,
	StartAsSuccessor = 1.5,
	UpdateSettings = 0.1,
	SelectSaveSlot = 1.0,
	CreateSaveSlot = 1.5,
	DeleteSaveSlot = 1.5,
	ClaimAchievement = 0.75,
	RedeemCode = 1.0,
	BindingVowAction = 0.75
}

function isDev(player)
	return DEV_USER_IDS[player.UserId] == true
end

local playerLives = {}
local pendingMissions = {}
local pendingLegacy = {}
local autosaveLoops = {}
local lastActionTimes = {}

local dirtySavePlayers = {}
local scheduledSavePlayers = {}
local activeSavePlayers = {}
local lastSaveTimes = {}

function checkCachedGamePassOwnership(player, passId, cacheTable, label)
	if not player then
		return false
	end

	if not passId or passId <= 0 then
		return false
	end

	local cached = cacheTable[player.UserId]
	local now = os.clock()

	if cached and (now - cached.CheckedAt) < VIP_CACHE_SECONDS then
		return cached.Owned == true
	end

	local ok, ownsPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)

	if not ok then
		warn("[GameManager] Could not check " .. tostring(label or "gamepass") .. " for " .. tostring(player.Name) .. ": " .. tostring(ownsPass))
		return cached and cached.Owned == true or false
	end

	cacheTable[player.UserId] = {
		Owned = ownsPass == true,
		CheckedAt = now
	}

	return ownsPass == true
end

function ownsVIPSorcererPass(player)
	return checkCachedGamePassOwnership(player, VIP_SORCERER_PASS_ID, vipOwnershipCache, "VIP Sorcerer Pass")
end

function ownsExtraSaveSlotsPass(player)
	return checkCachedGamePassOwnership(player, EXTRA_SAVE_SLOTS_PASS_ID, extraSaveSlotsOwnershipCache, "Extra Save Slots")
end

function ownsDoubleMoneyPass(player)
	return checkCachedGamePassOwnership(player, DOUBLE_MONEY_PASS_ID, doubleMoneyOwnershipCache, "2x Money")
end

function ownsDoubleTrainingPass(player)
	return checkCachedGamePassOwnership(player, DOUBLE_TRAINING_PASS_ID, doubleTrainingOwnershipCache, "2x Training")
end

function ownsSaveSlotAccess(player)
	return ownsVIPSorcererPass(player) or ownsExtraSaveSlotsPass(player)
end

function clearVIPCache(player)
	if player then
		vipOwnershipCache[player.UserId] = nil
		extraSaveSlotsOwnershipCache[player.UserId] = nil
		doubleMoneyOwnershipCache[player.UserId] = nil
		doubleTrainingOwnershipCache[player.UserId] = nil
	end
end

function pickRandom(list)
	return list[math.random(1, #list)]
end

function checkRateLimit(player, actionKey)
	if not player then
		return false
	end

	local userId = player.UserId
	local now = os.clock()
	local cooldown = RATE_LIMITS[actionKey] or 0.3

	lastActionTimes[userId] = lastActionTimes[userId] or {}

	local last = lastActionTimes[userId][actionKey] or 0

	if (now - last) < cooldown then
		return false
	end

	lastActionTimes[userId][actionKey] = now
	return true
end

function fireLifeUpdate(player, stats, message, forceResetLog)
	updateLifeEvent:FireClient(player, stats, message, forceResetLog == true)
end

function fireMajorPopup(player, title, body, highlight, footer)
	showMajorPopup:FireClient(player, {
		Title = title or "EVENT",
		Body = body or "",
		Highlight = highlight or "",
		Footer = footer or ""
	})
end

function fireRelationshipPopup(player, popupData)
	if not popupData then
		return
	end

	fireMajorPopup(
		player,
		popupData.Title,
		popupData.Body,
		popupData.Highlight,
		popupData.Footer
	)
end


function captureTraitBuffSnapshot(stats, relationship)
	return {
		CursedEnergy = tonumber(stats and stats.CursedEnergy) or 0,
		TechniqueMastery = tonumber(stats and stats.TechniqueMastery) or 0,
		Smarts = tonumber(stats and stats.Smarts) or 0,
		Money = tonumber(stats and stats.Money) or 0,
		Reputation = tonumber(stats and stats.Reputation) or 0,
		Health = tonumber(stats and stats.Health) or 0,
		Happiness = tonumber(stats and stats.Happiness) or 0,
		Relationship = relationship and {
			Bond = tonumber(relationship.Bond) or 0,
			Trust = tonumber(relationship.Trust) or 0,
			Respect = tonumber(relationship.Respect) or 0,
			Romance = tonumber(relationship.Romance) or 0,
			Fear = tonumber(relationship.Fear) or 0,
			Role = tostring(relationship.Role or "")
		} or nil
	}
end

function applyPositiveMult(currentValue, oldValue, mult, minValue, maxValue)
	currentValue = tonumber(currentValue) or 0
	oldValue = tonumber(oldValue) or 0
	mult = tonumber(mult) or 1

	local gain = currentValue - oldValue
	if gain <= 0 or mult == 1 then
		return currentValue, 0
	end

	local extra = math.floor((gain * (mult - 1)) + 0.5)
	if extra == 0 and mult > 1 then
		extra = 1
	end

	local result = currentValue + extra
	if minValue ~= nil and maxValue ~= nil then
		result = math.clamp(result, minValue, maxValue)
	end

	return result, result - currentValue
end

function applyLossMult(currentValue, oldValue, mult, minValue, maxValue)
	currentValue = tonumber(currentValue) or 0
	oldValue = tonumber(oldValue) or 0
	mult = tonumber(mult) or 1

	local loss = oldValue - currentValue
	if loss <= 0 or mult == 1 then
		return currentValue, 0
	end

	local newLoss = math.max(0, math.floor((loss * mult) + 0.5))
	local result = oldValue - newLoss
	if minValue ~= nil and maxValue ~= nil then
		result = math.clamp(result, minValue, maxValue)
	end

	return result, result - currentValue
end

function applyTraitBuffsFromSnapshot(stats, before, context, relationship)
	if not stats or not before then
		return ""
	end

	ensureTraitState(stats)

	local totalExtra = 0
	local ceMult = BitKaisenTraits.GetModifier(stats, "CEGainMult", 1)
	local masteryMult = BitKaisenTraits.GetModifier(stats, "MasteryGainMult", 1)
	local smartsMult = BitKaisenTraits.GetModifier(stats, "SmartsGainMult", 1)
	local moneyMult = BitKaisenTraits.GetModifier(stats, "MoneyGainMult", 1)
	local gradeMult = BitKaisenTraits.GetModifier(stats, "GradeProgressMult", 1)
	local combatMult = BitKaisenTraits.GetModifier(stats, "CombatGainMult", 1)
	local happinessLossMult = BitKaisenTraits.GetModifier(stats, "HappinessLossMult", 1)
	local riskMult = BitKaisenTraits.GetModifier(stats, "RiskMult", 1)

	if context == "Activity" or context == "Mission" then
		local extra
		local finalCEMult = ceMult
		local finalMasteryMult = masteryMult
		local finalGradeMult = gradeMult

		if context == "Mission" then
			finalCEMult *= combatMult
			finalMasteryMult *= combatMult
			finalGradeMult *= combatMult
		end

		stats.CursedEnergy, extra = applyPositiveMult(stats.CursedEnergy, before.CursedEnergy, finalCEMult, 0, nil)
		totalExtra += math.abs(extra)
		stats.TechniqueMastery, extra = applyPositiveMult(stats.TechniqueMastery, before.TechniqueMastery, finalMasteryMult, 0, 100)
		totalExtra += math.abs(extra)
		stats.Smarts, extra = applyPositiveMult(stats.Smarts, before.Smarts, smartsMult, 0, 100)
		totalExtra += math.abs(extra)
		stats.Money, extra = applyPositiveMult(stats.Money, before.Money, moneyMult, 0, nil)
		totalExtra += math.abs(extra)
		stats.Reputation, extra = applyPositiveMult(stats.Reputation, before.Reputation, finalGradeMult, nil, nil)
		totalExtra += math.abs(extra)
		stats.Happiness, extra = applyLossMult(stats.Happiness, before.Happiness, happinessLossMult, 0, 100)
		totalExtra += math.abs(extra)
		stats.Health, extra = applyLossMult(stats.Health, before.Health, riskMult, 0, 100)
		totalExtra += math.abs(extra)
	end

	if context == "Relationship" and relationship and before.Relationship then
		local role = tostring(relationship.Role or before.Relationship.Role or "")
		BitKaisenTraits.EnsureTraits(relationship)

		local relMult = BitKaisenTraits.GetModifier(stats, "RelationshipGainMult", 1) * BitKaisenTraits.GetModifier(relationship, "RelationshipGainMult", 1)
		local romanceMult = BitKaisenTraits.GetModifier(stats, "RomanceGainMult", 1) * BitKaisenTraits.GetModifier(relationship, "RomanceGainMult", 1)
		local familyMult = BitKaisenTraits.GetModifier(stats, "FamilyGainMult", 1) * BitKaisenTraits.GetModifier(relationship, "FamilyGainMult", 1)
		local kidMult = BitKaisenTraits.GetModifier(stats, "KidBondGainMult", 1) * BitKaisenTraits.GetModifier(relationship, "KidBondGainMult", 1)

		if role == "Mother" or role == "Father" or role == "Sibling" or role == "Caretaker" or role == "Spouse" or role == "Child" or role == "Ward" then
			relMult *= familyMult
		end
		if role == "Child" or role == "Ward" then
			relMult *= kidMult
		end

		local extra
		relationship.Bond, extra = applyPositiveMult(relationship.Bond, before.Relationship.Bond, relMult, 0, 100)
		totalExtra += math.abs(extra)
		relationship.Trust, extra = applyPositiveMult(relationship.Trust, before.Relationship.Trust, relMult, 0, 100)
		totalExtra += math.abs(extra)
		relationship.Respect, extra = applyPositiveMult(relationship.Respect, before.Relationship.Respect, relMult, 0, 100)
		totalExtra += math.abs(extra)
		relationship.Romance, extra = applyPositiveMult(relationship.Romance, before.Relationship.Romance, romanceMult, 0, 100)
		totalExtra += math.abs(extra)
	end

	stats.TraitSummary = BitKaisenTraits.GetTraitDisplay(stats)

	if totalExtra > 0 then
		return "\n<font color='#b27aff'><b>[ TRAITS ]</b></font> Your traits influenced the outcome."
	end

	return ""
end


local GRADE_VALUES = {
	["Non-Sorcerer"] = 0,
	["Grade 4"] = 1,
	["Semi-Grade 3"] = 2,
	["Grade 3"] = 3,
	["Semi-Grade 2"] = 4,
	["Grade 2"] = 5,
	["Semi-Grade 1"] = 6,
	["Grade 1"] = 7,
	["Special Grade"] = 8,
	["Special Grade 1"] = 8
}

function stripUnregisteredGradePrefix(grade)
	local gradeText = tostring(grade or "Non-Sorcerer")

	if string.sub(gradeText, 1, 13) == "Unregistered " then
		return string.sub(gradeText, 14)
	end

	if string.sub(gradeText, 1, 11) == "Curse User " then
		return string.sub(gradeText, 12)
	end

	return gradeText
end

function getGradeValue(grade)
	return GRADE_VALUES[stripUnregisteredGradePrefix(grade)] or 0
end

function getOfficialGradeName(grade)
	local officialGrade = stripUnregisteredGradePrefix(grade)
	if getGradeValue(officialGrade) <= 0 then
		return "Non-Sorcerer"
	end
	return officialGrade
end


-- Phase 2A.5b balance: players were being branded as curse users way too fast.
-- A normal unregistered sorcerer should have time to apply to Jujutsu High.
-- Curse User is now a harder outlaw route, not the default result of two private grade-ups.
local CURSE_USER_BRAND_GRADEUPS_REQUIRED = 4
local CURSE_USER_BRAND_WANTED_LEVEL_REQUIRED = 2
local CURSE_USER_BRAND_REPUTATION_REQUIRED = -25
local CURSE_USER_BRAND_RESSENTMENT_REQUIRED = 90

function getCurseUserBrandPressure(stats)
	if not stats then
		return 0
	end

	local pressure = 0
	local wantedLevel = tonumber(stats.WantedLevel) or 0
	local reputation = tonumber(stats.Reputation) or 0
	local resentment = tonumber(stats.CursedResentment) or 0
	local gradeValue = getGradeValue(stats.Grade)

	if wantedLevel >= CURSE_USER_BRAND_WANTED_LEVEL_REQUIRED then
		pressure += 1
	end

	if reputation <= CURSE_USER_BRAND_REPUTATION_REQUIRED then
		pressure += 1
	end

	if resentment >= CURSE_USER_BRAND_RESSENTMENT_REQUIRED then
		pressure += 1
	end

	-- If someone is already unregistered Grade 1 / Special Grade, society gets nervous even without crimes.
	if gradeValue >= getGradeValue("Grade 1") then
		pressure += 1
	end

	return pressure
end

function shouldBrandAsCurseUser(stats)
	if not stats then
		return false
	end

	if stats.InJujutsuHigh == true or stats.RegisteredSorcerer == true then
		return false
	end

	if isCurseUser(stats) then
		return true
	end

	local gradeUps = tonumber(stats.UnregisteredGradeUps) or 0
	local pressure = getCurseUserBrandPressure(stats)

	-- Main rule: 4 unregistered grade-ups AND at least one real danger marker.
	if gradeUps >= CURSE_USER_BRAND_GRADEUPS_REQUIRED and pressure >= 1 then
		return true
	end

	-- Emergency rule: extremely wanted outlaws can be branded earlier.
	if gradeUps >= 2 and (tonumber(stats.WantedLevel) or 0) >= 5 then
		return true
	end

	return false
end

function getCurseUserRiskText(stats)
	local gradeUps = tonumber(stats and stats.UnregisteredGradeUps) or 0
	local pressure = getCurseUserBrandPressure(stats)
	return tostring(gradeUps) .. "/" .. tostring(CURSE_USER_BRAND_GRADEUPS_REQUIRED) .. " unregistered advances, danger markers " .. tostring(pressure) .. "/1"
end

function getEstimatedUnregisteredGrade(stats)
	if not stats then
		return "Non-Sorcerer"
	end

	local current = getOfficialGradeName(stats.Grade)
	if current ~= "Non-Sorcerer" then
		return current
	end

	local cursedEnergy = tonumber(stats.CursedEnergy) or 0
	local mastery = tonumber(stats.TechniqueMastery) or 0
	local reputation = tonumber(stats.Reputation) or 0
	local smarts = tonumber(stats.Smarts) or 0
	local hasAnyTechnique = tostring(stats.CursedTechnique or "None") ~= "None"
		or tostring(stats.InnateTechnique or "None") ~= "None"
		or stats.TechniqueKnown == true
		or stats.TechniqueAwakened == true
		or stats.TechniqueUsable == true

	if not hasAnyTechnique and cursedEnergy < 35 then
		return "Non-Sorcerer"
	end

	local score = cursedEnergy + (mastery * 3) + (reputation * 2) + math.floor(smarts * 0.5)
	if stats.HeavenlyRestricted == true then
		score += 35
	end

	if score >= 380 then return "Special Grade" end
	if score >= 300 then return "Grade 1" end
	if score >= 240 then return "Semi-Grade 1" end
	if score >= 180 then return "Grade 2" end
	if score >= 125 then return "Semi-Grade 2" end
	if score >= 80 then return "Grade 3" end
	if score >= 50 then return "Semi-Grade 3" end
	return "Grade 4"
end

function isOfficialJujutsuSorcerer(stats)
	if not stats then
		return false
	end
	local gradeText = tostring(stats.Grade or "Non-Sorcerer")
	return stats.InJujutsuHigh == true
		and getGradeValue(gradeText) > 0
		and string.sub(gradeText, 1, 13) ~= "Unregistered "
end

function isCurseUser(stats)
	if not stats then
		return false
	end

	return stats.IsCurseUser == true
		or stats.CurseUser == true
		or stats.Path == "Curse User"
		or stats.SorcererPath == "Curse User"
		or stats.Alignment == "Curse User"
end

function isUnregisteredSorcerer(stats)
	if not stats then
		return false
	end

	if isCurseUser(stats) then
		return false
	end

	return stats.InJujutsuHigh ~= true and getGradeValue(stats.Grade) > 0
end

function makeCurseUser(stats, grade)
	if not stats then
		return
	end

	local curseUserGrade = getOfficialGradeName(grade or stats.Grade)

	if curseUserGrade == "Non-Sorcerer" then
		curseUserGrade = getEstimatedUnregisteredGrade(stats)
	end

	if curseUserGrade == "Non-Sorcerer" then
		curseUserGrade = "Grade 4"
	end

	stats.IsCurseUser = true
	stats.CurseUser = true
	stats.Path = "Curse User"
	stats.SorcererPath = "Curse User"
	stats.Alignment = "Curse User"

	stats.InJujutsuHigh = false
	stats.RegisteredSorcerer = false
	stats.OfficialGrade = "Curse User"
	stats.UnregisteredGrade = curseUserGrade
	stats.Grade = "Curse User " .. curseUserGrade

	stats.Reputation = (tonumber(stats.Reputation or 0) + 8)
	stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - 6, 0, 100)
end

function ensureSorcererRegistrationState(stats)
	if not stats then
		return
	end

	if isCurseUser(stats) then
		local curseUserGrade = getOfficialGradeName(stats.Grade)

		if curseUserGrade == "Non-Sorcerer" then
			curseUserGrade = getOfficialGradeName(stats.UnregisteredGrade)
		end

		if curseUserGrade == "Non-Sorcerer" then
			curseUserGrade = getEstimatedUnregisteredGrade(stats)
		end

		if curseUserGrade == "Non-Sorcerer" then
			curseUserGrade = "Grade 4"
		end

		stats.IsCurseUser = true
		stats.CurseUser = true
		stats.Path = "Curse User"
		stats.SorcererPath = "Curse User"
		stats.Alignment = "Curse User"

		stats.InJujutsuHigh = false
		stats.RegisteredSorcerer = false
		stats.Grade = "Curse User " .. curseUserGrade
		stats.OfficialGrade = "Curse User"
		stats.UnregisteredGrade = curseUserGrade
		return
	end

	stats.InJujutsuHigh = stats.InJujutsuHigh == true
	stats.RegisteredSorcerer = stats.InJujutsuHigh == true

	if stats.InJujutsuHigh then
		local official = getOfficialGradeName(stats.Grade)
		if official == "Non-Sorcerer" then
			official = getEstimatedUnregisteredGrade(stats)
		end
		stats.Grade = official
		stats.OfficialGrade = official
		stats.UnregisteredGrade = nil
	else
		local estimated = getEstimatedUnregisteredGrade(stats)
		if estimated ~= "Non-Sorcerer" then
			stats.Grade = "Unregistered " .. estimated
			stats.UnregisteredGrade = estimated
			stats.OfficialGrade = "Unregistered"
		else
			stats.Grade = "Non-Sorcerer"
			stats.UnregisteredGrade = nil
			stats.OfficialGrade = "Unregistered"
		end
	end
end


function hasStartedPersonalFamily(stats)
	if not stats or type(stats.Relationships) ~= "table" then
		return false
	end

	for _, relationship in ipairs(stats.Relationships) do
		if relationship and relationship.Alive ~= false then
			local role = tostring(relationship.Role or "")
			if role == "Spouse" or role == "Child" then
				return true
			end
		end
	end

	return false
end

function syncFamilyStatus(stats)
	if not stats then
		return
	end

	stats.FamilyType = stats.FamilyType or "Unknown"
	stats.HasStartedFamily = hasStartedPersonalFamily(stats)

	if stats.ClanFounded == true or tostring(stats.PlayerClanName or "") ~= "" then
		stats.FamilyType = "Sorcerer Clan"
		stats.OriginCategory = stats.OriginCategory or "Clan"
		stats.Clan = stats.PlayerClanName or stats.Clan or stats.Origin or "Player Clan"
		return
	end

	if stats.HasStartedFamily == true then
		if stats.FamilyType == "Civilian" then
			local grade = tostring(stats.Grade or "Non-Sorcerer")
			if grade ~= "Non-Sorcerer" or stats.InJujutsuHigh == true or (tonumber(stats.CursedEnergy) or 0) >= 50 then
				stats.FamilyType = "Sorcerer Household"
			else
				stats.FamilyType = "Household"
			end
		end
		return
	end

	if stats.FamilyType == "Civilian" then
		local grade = tostring(stats.Grade or "Non-Sorcerer")
		if grade ~= "Non-Sorcerer" or stats.InJujutsuHigh == true then
			stats.FamilyType = "Sorcerer"
		end
	end
end

function isCurseLife(stats)
	if BitKaisenStats.IsCurseLife then
		return BitKaisenStats.IsCurseLife(stats)
	end

	local origin = tostring(stats and (stats.Origin or stats.Clan) or "")
	local originCategory = tostring(stats and stats.OriginCategory or "")
	local familyType = tostring(stats and stats.FamilyType or "")
	local race = tostring(stats and stats.Race or "")
	local curseType = tostring(stats and stats.CurseType or "")

	-- Phase 2B: canon labels. Old saves with Race = "Curse" still work,
	-- but new cursed lives display as Race = "Cursed Spirit".
	return stats and (
		stats.IsCurse == true
			or race == "Cursed Spirit"
			or race == "Curse"
			or origin == "Vengeful Spirit Rebirth"
			or origin == "Cursed Spirit Rebirth"
			or origin == "Cursed Rebirth"
			or origin == "Curse"
			or origin == "Cursed Spirit"
			or (originCategory == "Race" and (origin == "Cursed Spirit" or origin == "Curse" or familyType == "Cursed Spirit" or familyType == "Curse"))
			or curseType == "Vengeful Cursed Spirit"
			or curseType == "Fear-Born Cursed Spirit"
			or curseType == "Death-Bound Cursed Spirit"
			or curseType == "Cursed Womb"
			or curseType == "Cursed Spirit"
			or curseType == "Disaster-Class Cursed Spirit"
			-- legacy labels
			or curseType == "Vengeful Curse"
			or curseType == "Fearborn Curse"
			or curseType == "Deathbound Curse"
			or curseType == "Grudge Womb"
			or curseType == "Natural Curse"
			or curseType == "Disaster Curse"
	) or false
end

function normalizeCursedSocietyState(stats)
	if not stats then
		return
	end

	if BitKaisenStats.NormalizeCursedSocietyStats then
		BitKaisenStats.NormalizeCursedSocietyStats(stats)
	else
		local curseLife = isCurseLife(stats)
		stats.IsCurse = curseLife
		stats.CurseType = tostring(stats.CurseType or (curseLife and "Cursed Spirit" or "None"))
		stats.CurseGrade = tostring(stats.CurseGrade or (curseLife and "Unregistered Grade 3 Cursed Spirit" or "None"))
		stats.CurseThreat = math.max(0, tonumber(stats.CurseThreat) or 0)
		stats.CurseThreatClass = tostring(stats.CurseThreatClass or (curseLife and "Local" or "None"))
		if curseLife and stats.CurseThreatClass == "None" then stats.CurseThreatClass = "Local" end
		normalizeCurseGradeAndThreatClass(stats)
		stats.CurseEvolution = tostring(stats.CurseEvolution or (curseLife and "Dormant" or "None"))
		stats.SorcererAttackCooldown = math.max(0, tonumber(stats.SorcererAttackCooldown) or 0)
		stats.SorcerersKilled = math.max(0, tonumber(stats.SorcerersKilled) or 0)
		stats.CurseClassified = stats.CurseClassified == true
		stats.ExorcismRisk = math.clamp(tonumber(stats.ExorcismRisk) or 0, 0, 100)
		stats.TimesExorcised = math.max(0, tonumber(stats.TimesExorcised) or 0)
		stats.SocietyStatus = tostring(stats.SocietyStatus or (curseLife and "Unregistered Cursed Spirit" or "Civilian"))
		stats.RegisteredSorcerer = stats.RegisteredSorcerer == true
		stats.Recommendations = math.max(0, tonumber(stats.Recommendations) or tonumber(stats.TeacherRecommendations) or 0)
		stats.RecommendationProgress = math.max(0, tonumber(stats.RecommendationProgress) or 0)
		stats.PromotionDifficulty = math.max(0.25, tonumber(stats.PromotionDifficulty) or 1)
		stats.WantedLevel = math.clamp(tonumber(stats.WantedLevel) or 0, 0, 100)
		stats.SocietyRecognition = math.max(0, tonumber(stats.SocietyRecognition) or 0)
		stats.DojoReputation = math.max(0, tonumber(stats.DojoReputation) or tonumber(stats.ClanReputation) or 0)
		stats.DojoRank = tostring(stats.DojoRank or "No Dojo")
		stats.DojoIncome = math.max(0, tonumber(stats.DojoIncome) or 0)
		stats.StudentMissionCooldown = math.max(0, tonumber(stats.StudentMissionCooldown) or 0)
		stats.FamilyReputation = math.max(0, tonumber(stats.FamilyReputation) or 0)
		stats.BloodlineStrength = math.clamp(tonumber(stats.BloodlineStrength) or 0, 0, 100)
		stats.DeathPaintingLineage = stats.DeathPaintingLineage == true
	end

	if isCurseLife(stats) then
		stats.Alive = stats.Alive ~= false
		stats.RegisteredSorcerer = false
		if tostring(stats.SocietyStatus or "") == "Registered Cursed Spirit" or tostring(stats.SocietyStatus or "") == "Tracked Cursed Spirit" or tostring(stats.SocietyStatus or "") == "Disaster Threat" then
			stats.CurseClassified = true
		end
		if stats.CurseType == "None" then stats.CurseType = "Cursed Spirit" end
		stats.CurseClassified = stats.CurseClassified == true
		if stats.CurseGrade == "None" then stats.CurseGrade = "Unregistered Grade 3 Cursed Spirit" end
		normalizeCurseGradeAndThreatClass(stats)
		if stats.SocietyStatus == "Civilian" or stats.SocietyStatus == "Registered Sorcerer" or stats.SocietyStatus == "Jujutsu Student" then
			stats.SocietyStatus = "Unregistered Cursed Spirit"
		end
	elseif stats.InJujutsuHigh == true then
		stats.SocietyStatus = "Jujutsu Student"
		stats.RegisteredSorcerer = true
	elseif tostring(stats.Grade or "Non-Sorcerer") ~= "Non-Sorcerer" then
		stats.SocietyStatus = stats.RegisteredSorcerer and "Registered Sorcerer" or "Unregistered Sorcerer"
	end

	if stats.ClanFounded == true or tonumber(stats.DojoPrestige) and tonumber(stats.DojoPrestige) > 0 then
		local rep = math.max(0, tonumber(stats.DojoReputation) or tonumber(stats.ClanReputation) or 0)
		if rep >= 250 then
			stats.DojoRank = "Legendary Dojo"
		elseif rep >= 120 then
			stats.DojoRank = "Elite Dojo"
		elseif rep >= 60 then
			stats.DojoRank = "Respected Dojo"
		elseif rep >= 25 then
			stats.DojoRank = "Recognized Dojo"
		elseif rep > 0 then
			stats.DojoRank = "Local Dojo"
		else
			stats.DojoRank = "Unknown Dojo"
		end
	end
end

function ensureTraitState(stats)
	if not stats then
		return
	end

	BitKaisenTraits.EnsureTraits(stats)

	if stats.TraitsRolled ~= true and (not stats.Traits or #stats.Traits <= 0) then
		stats.Traits = BitKaisenTraits.RollBirthTraits(stats)
		BitKaisenTraits.ApplyStartingBonuses(stats)
		stats.TraitsRolled = true
	else
		stats.TraitSummary = BitKaisenTraits.GetTraitDisplay(stats)
	end
end

function ensureExtraStats(stats)
	stats.Name = stats.Name or "Unknown"
	stats.FirstName = stats.FirstName or "Unknown"
	stats.FamilyName = stats.FamilyName or "Unknown"
	stats.FamilyType = stats.FamilyType or "Unknown"
	stats.Gender = stats.Gender == "Female" and "Female" or (stats.Gender == "Male" and "Male" or "Unknown")

	stats.CurrentMonth = math.clamp(tonumber(stats.CurrentMonth) or 1, 1, 12)
	stats.MonthsIntoAge = math.clamp(tonumber(stats.MonthsIntoAge) or 0, 0, 11)

	stats.Money = stats.Money or 0
	stats.Reputation = stats.Reputation or 0
	stats.TeacherRecommendations = stats.TeacherRecommendations or 0
	stats.MissionsCompleted = stats.MissionsCompleted or 0
	stats.MissionsFailed = stats.MissionsFailed or 0
	stats.TechniqueMastery = math.clamp(stats.TechniqueMastery or 0, 0, 100)
	stats.InnateTechnique = stats.InnateTechnique or "None"
	stats.TechniqueType = stats.TechniqueType or "None"
	stats.TechniqueKnown = stats.TechniqueKnown == true
	stats.TechniqueUsable = stats.TechniqueUsable == true
	stats.TechniqueAwakened = stats.TechniqueAwakened == true
	stats.InnateDormant = stats.InnateDormant == true
	stats.PlayerClanInnateTechnique = stats.PlayerClanInnateTechnique or "None"
	stats.Assets = stats.Assets or {}
	stats.UnregisteredProgress = math.max(0, tonumber(stats.UnregisteredProgress) or 0)
	stats.UnregisteredGradeUps = math.max(0, tonumber(stats.UnregisteredGradeUps) or 0)
	stats.PrivateTrainingSessions = math.max(0, tonumber(stats.PrivateTrainingSessions) or 0)
	stats.UnregisteredIncidents = math.max(0, tonumber(stats.UnregisteredIncidents) or 0)
	stats.CurseUserProgress = math.max(0, tonumber(stats.CurseUserProgress) or 0)
	stats.CursedResentment = math.max(0, tonumber(stats.CursedResentment) or 0)
	stats.CurseRebirthEligible = stats.CurseRebirthEligible == true
	stats.CurseRebirthCount = math.max(0, tonumber(stats.CurseRebirthCount) or 0)
	ensureCursedSpiritFlavor(stats)
	stats.PreviousLifeName = stats.PreviousLifeName
	stats.PreviousLifeCauseOfDeath = stats.PreviousLifeCauseOfDeath
	stats.Morality = math.clamp(tonumber(stats.Morality) or 0, -100, 100)
	stats.Alignment = getMoralAlignment(stats)


	stats.ClanFounded = stats.ClanFounded or false
	stats.PlayerClanName = stats.PlayerClanName or nil
	stats.ClanMembers = stats.ClanMembers or 0
	stats.ClanReputation = stats.ClanReputation or 0
	stats.ClanStudentsRecruited = stats.ClanStudentsRecruited or 0
	stats.ClanTrainingSessions = stats.ClanTrainingSessions or 0

	stats.DojoLevel = math.clamp(tonumber(stats.DojoLevel) or 1, 1, 5)
	stats.DojoCondition = math.clamp(tonumber(stats.DojoCondition) or 100, 0, 100)
	stats.DojoPrestige = math.max(0, tonumber(stats.DojoPrestige) or 0)
	stats.DojoFocus = tostring(stats.DojoFocus or "Balanced")
	if stats.DojoFocus ~= "Balanced" and stats.DojoFocus ~= "Combat" and stats.DojoFocus ~= "Discipline" and stats.DojoFocus ~= "Theory" and stats.DojoFocus ~= "Loyalty" then
		stats.DojoFocus = "Balanced"
	end
	stats.DojoSparringEvents = math.max(0, tonumber(stats.DojoSparringEvents) or 0)
	stats.WardsRescued = math.max(0, tonumber(stats.WardsRescued) or 0)
	stats.DojoFounderName = stats.DojoFounderName or stats.Name or "Unknown"
	stats.DojoClanBaseName = stats.DojoClanBaseName or nil
	stats.DojoNameConfirmed = stats.DojoNameConfirmed == true
	stats.DojoPendingLastNameChoice = stats.DojoPendingLastNameChoice == true
	stats.DojoRecruitPool = stats.DojoRecruitPool or {}
	stats.DojoStarterRecruitLimit = math.max(1, tonumber(stats.DojoStarterRecruitLimit) or 3)
	stats.DojoStarterRecruitsUsed = math.max(0, tonumber(stats.DojoStarterRecruitsUsed) or 0)
	stats.WardsAdopted = math.max(0, tonumber(stats.WardsAdopted) or 0)
	stats.RecruitRerollTokens = math.max(0, tonumber(stats.RecruitRerollTokens) or 0)

	stats.InJujutsuHigh = stats.InJujutsuHigh or false
	stats.ActivitiesDoneThisAge = stats.ActivitiesDoneThisAge or 0
	stats.RelationshipActionsThisAge = stats.RelationshipActionsThisAge or 0
	stats.RecentLifeEvents = stats.RecentLifeEvents or {}
	stats.RecentQuietTexts = stats.RecentQuietTexts or {}

	stats.Origin = stats.Origin or stats.Clan or "Minor Sorcerer Family"
	stats.OriginCategory = stats.OriginCategory or "Family"

	normalizeCursedSocietyState(stats)

	stats.Generation = stats.Generation or 1
	stats.LegacyHistory = stats.LegacyHistory or {}

	-- MetaProgress is preserved into future lives on the same save/bloodline.
	-- Keep this small and plain so it does not interfere with save slots, codes, gamepasses, or old systems.
	stats.MetaProgress = stats.MetaProgress or {}
	stats.MetaProgress.HeavenlyRestrictionBoost = stats.MetaProgress.HeavenlyRestrictionBoost == true

	stats.HigherUps = stats.HigherUps or {}
	stats.HigherUps.InvitationTriggered = stats.HigherUps.InvitationTriggered == true
	stats.HigherUps.InvitationAccepted = stats.HigherUps.InvitationAccepted == true
	stats.HigherUps.InvitationDeclined = stats.HigherUps.InvitationDeclined == true
	stats.HigherUps.MissionChainUnlocked = stats.HigherUps.MissionChainUnlocked == true
	stats.HigherUps.CurrentMission = math.clamp(tonumber(stats.HigherUps.CurrentMission) or 0, 0, 5)
	stats.HigherUps.VesselEscortCompleted = stats.HigherUps.VesselEscortCompleted == true
	stats.HigherUps.HeavenlyRestrictedAchievement = stats.HigherUps.HeavenlyRestrictedAchievement == true
	stats.HigherUps.VesselTrust = math.clamp(tonumber(stats.HigherUps.VesselTrust) or 0, -100, 100)
	stats.HigherUps.VesselEscortCompanionName = stats.HigherUps.VesselEscortCompanionName or nil

	stats.HeavenlyRestricted = stats.HeavenlyRestricted == true

	stats.Achievements = stats.Achievements or {}
	stats.Achievements.Claimed = stats.Achievements.Claimed or {}

	stats.Codes = stats.Codes or {}
	stats.Codes.Redeemed = stats.Codes.Redeemed or {}

	-- Purchase flags for one-time per-life products.
	-- Developer products can technically be bought repeatedly by Roblox,
	-- so anything meant to behave like a one-time pack must be blocked by our own save data too.
	stats.Purchases = stats.Purchases or {}
	stats.Purchases.StarterSorcererPackClaimed = stats.Purchases.StarterSorcererPackClaimed == true

	stats.Settings = stats.Settings or {}

	local defaultSettings = {
		MusicVolume = 1,
		SFXVolume = 1,

		MuteMusic = false,
		MuteSFX = false,

		FastText = false,
		HighContrastText = false,
		ReducedMotion = false,
		ScreenShake = true
	}

	for settingName, defaultValue in pairs(defaultSettings) do
		if stats.Settings[settingName] == nil then
			stats.Settings[settingName] = defaultValue
		end
	end

	stats.Settings.MusicVolume = math.clamp(tonumber(stats.Settings.MusicVolume) or 1, 0, 1)
	stats.Settings.SFXVolume = math.clamp(tonumber(stats.Settings.SFXVolume) or 1, 0, 1)

	stats.Settings.MuteMusic = stats.Settings.MuteMusic == true
	stats.Settings.MuteSFX = stats.Settings.MuteSFX == true

	stats.Settings.FastText = stats.Settings.FastText == true
	stats.Settings.HighContrastText = stats.Settings.HighContrastText == true
	stats.Settings.ReducedMotion = stats.Settings.ReducedMotion == true
	stats.Settings.ScreenShake = stats.Settings.ScreenShake ~= false

	BitKaisenTraits.EnsureTraits(stats)
	ensureSorcererRegistrationState(stats)
	BitKaisenRelationships.EnsureRelationships(stats)
	ensureTraitState(stats)
	syncFamilyStatus(stats)
end

local saveStats

-- getGradeValue is defined near the top with unregistered-grade support.

local ACHIEVEMENT_DEFINITIONS = {
	{
		Id = "awakened_technique",
		Name = "Awakened Technique",
		Description = "Unlock your cursed technique for the first time.",
		RewardText = "+$1,500 | +10 CE",
		IsUnlocked = function(stats)
			return stats.CursedTechnique ~= nil and stats.CursedTechnique ~= "None"
		end,
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 1500
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 10
			return "+$1,500 Money and +10 Cursed Energy"
		end
	},
	{
		Id = "first_mission",
		Name = "First Mission",
		Description = "Complete your first official curse mission.",
		RewardText = "+$2,000 | +2 Rep",
		IsUnlocked = function(stats)
			return (stats.MissionsCompleted or 0) >= 1
		end,
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 2000
			stats.Reputation = (stats.Reputation or 0) + 2
			return "+$2,000 Money and +2 Reputation"
		end
	},
	{
		Id = "five_missions",
		Name = "Reliable Sorcerer",
		Description = "Complete 5 missions in one life.",
		RewardText = "+$5,000 | +5 Rep",
		IsUnlocked = function(stats)
			return (stats.MissionsCompleted or 0) >= 5
		end,
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 5000
			stats.Reputation = (stats.Reputation or 0) + 5
			return "+$5,000 Money and +5 Reputation"
		end
	},
	{
		Id = "jujutsu_high",
		Name = "Jujutsu High Student",
		Description = "Enter Jujutsu High.",
		RewardText = "+1 Recommendation | +5 Smarts",
		IsUnlocked = function(stats)
			return stats.InJujutsuHigh == true
		end,
		Grant = function(stats)
			stats.TeacherRecommendations = (stats.TeacherRecommendations or 0) + 1
			stats.Smarts = math.clamp((stats.Smarts or 0) + 5, 0, 100)
			return "+1 Teacher Recommendation and +5 Smarts"
		end
	},
	{
		Id = "ce_100",
		Name = "Cursed Energy Reserve",
		Description = "Reach 100 cursed energy.",
		RewardText = "+25 CE",
		IsUnlocked = function(stats)
			return (stats.CursedEnergy or 0) >= 100
		end,
		Grant = function(stats)
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 25
			return "+25 Cursed Energy"
		end
	},
	{
		Id = "mastery_25",
		Name = "Technique Control",
		Description = "Reach 25 technique mastery.",
		RewardText = "+5 Mastery | +5 CE",
		IsUnlocked = function(stats)
			return (stats.TechniqueMastery or 0) >= 25
		end,
		Grant = function(stats)
			stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + 5, 0, 100)
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 5
			return "+5 Technique Mastery and +5 Cursed Energy"
		end
	},
	{
		Id = "grade_2",
		Name = "Grade 2 Sorcerer",
		Description = "Reach Grade 2 or higher.",
		RewardText = "+$7,500 | +1 Recommendation",
		IsUnlocked = function(stats)
			return getGradeValue(stats.Grade) >= getGradeValue("Grade 2")
		end,
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 7500
			stats.TeacherRecommendations = (stats.TeacherRecommendations or 0) + 1
			return "+$7,500 Money and +1 Teacher Recommendation"
		end
	},
	{
		Id = "clan_founder",
		Name = "Clan Founder",
		Description = "Buy a Grand Dojo and start your own clan.",
		RewardText = "+$10,000 | +10 Clan Rep",
		IsUnlocked = function(stats)
			return stats.ClanFounded == true
		end,
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 10000
			stats.ClanReputation = (stats.ClanReputation or 0) + 10
			stats.ClanMembers = math.max(1, stats.ClanMembers or 1)
			return "+$10,000 Money and +10 Clan Reputation"
		end
	},
	{
		Id = "legacy_continued",
		Name = "Legacy Continued",
		Description = "Continue as a successor after death.",
		RewardText = "+$5,000 | +20 CE",
		IsUnlocked = function(stats)
			return (stats.Generation or 1) >= 2
		end,
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 5000
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 20
			return "+$5,000 Money and +20 Cursed Energy"
		end
	},
	{
		Id = "money_25000",
		Name = "Stacked Funds",
		Description = "Hold $25,000 in one life.",
		RewardText = "+$3,000 | +2 Rep",
		IsUnlocked = function(stats)
			return (stats.Money or 0) >= 25000
		end,
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 3000
			stats.Reputation = (stats.Reputation or 0) + 2
			return "+$3,000 Money and +2 Reputation"
		end
	},
	{
		Id = "age_40",
		Name = "Seasoned Survivor",
		Description = "Reach age 40 in one life.",
		RewardText = "+10 Health | +10 Happiness",
		IsUnlocked = function(stats)
			return (stats.Age or 0) >= 40
		end,
		Grant = function(stats)
			stats.Health = math.clamp((stats.Health or 100) + 10, 0, 100)
			stats.Happiness = math.clamp((stats.Happiness or 100) + 10, 0, 100)
			return "+10 Health and +10 Happiness"
		end
	},
	{
		Id = "special_grade",
		Name = "Special Grade",
		Description = "Reach Special Grade.",
		RewardText = "+$25,000 | +50 CE | +10 Rep",
		IsUnlocked = function(stats)
			return tostring(stats.Grade or "") == "Special Grade"
		end,
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 25000
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 50
			stats.Reputation = (stats.Reputation or 0) + 10
			return "+$25,000 Money, +50 Cursed Energy, and +10 Reputation"
		end
	},
	{
		Id = "heavenly_restricted",
		Name = "Heavenly Restricted",
		Description = "Defeat the Heavenly Restricted assassin during the Vessel Escort assignment.",
		RewardText = "Future lives: higher Heavenly Restriction chance",
		IsUnlocked = function(stats)
			return stats.HigherUps and stats.HigherUps.HeavenlyRestrictedAchievement == true
		end,
		Grant = function(stats)
			stats.MetaProgress = stats.MetaProgress or {}
			stats.MetaProgress.HeavenlyRestrictionBoost = true
			return "Future lives now have a higher chance to be born with Heavenly Restriction"
		end
	},
}

function getAchievementDefinition(achievementId)
	for _, definition in ipairs(ACHIEVEMENT_DEFINITIONS) do
		if definition.Id == achievementId then
			return definition
		end
	end

	return nil
end

function getAchievementPayload(player)
	local stats = playerLives[player.UserId]

	if not stats then
		return {
			Achievements = {},
			ClaimedCount = 0,
			UnlockedCount = 0,
			TotalCount = #ACHIEVEMENT_DEFINITIONS
		}
	end

	ensureExtraStats(stats)

	local claimed = stats.Achievements.Claimed
	local list = {}
	local claimedCount = 0
	local unlockedCount = 0

	for _, definition in ipairs(ACHIEVEMENT_DEFINITIONS) do
		local isClaimed = claimed[definition.Id] == true
		local isUnlocked = false

		local ok, result = pcall(function()
			return definition.IsUnlocked(stats)
		end)

		if ok and result == true then
			isUnlocked = true
			unlockedCount += 1
		end

		if isClaimed then
			claimedCount += 1
		end

		table.insert(list, {
			Id = definition.Id,
			Name = definition.Name,
			Description = definition.Description,
			RewardText = definition.RewardText,
			Unlocked = isUnlocked,
			Claimed = isClaimed,
		})
	end

	return {
		Achievements = list,
		ClaimedCount = claimedCount,
		UnlockedCount = unlockedCount,
		TotalCount = #ACHIEVEMENT_DEFINITIONS
	}
end

function claimAchievementReward(player, achievementId)
	if typeof(achievementId) ~= "string" then
		return false, "Invalid achievement."
	end

	local stats = playerLives[player.UserId]
	if not stats then
		return false, "No life loaded."
	end

	ensureExtraStats(stats)

	local definition = getAchievementDefinition(achievementId)
	if not definition then
		return false, "Unknown achievement."
	end

	if stats.Achievements.Claimed[achievementId] == true then
		return false, "Achievement already claimed."
	end

	local ok, unlocked = pcall(function()
		return definition.IsUnlocked(stats)
	end)

	if not ok or unlocked ~= true then
		return false, "Achievement is still locked."
	end

	stats.Achievements.Claimed[achievementId] = true

	local rewardSummary = "Reward claimed."
	local grantOk, grantResult = pcall(function()
		return definition.Grant(stats)
	end)

	if grantOk and grantResult then
		rewardSummary = grantResult
	elseif not grantOk then
		warn("[GameManager] Achievement reward failed for " .. tostring(achievementId) .. ": " .. tostring(grantResult))
	end

	local message = "<font color='#f0b955'><b>[ ACHIEVEMENT ]</b></font> " .. definition.Name .. " claimed.\n" .. rewardSummary

	fireMajorPopup(
		player,
		"ACHIEVEMENT CLAIMED",
		definition.Description,
		definition.Name,
		rewardSummary
	)

	fireLifeUpdate(player, stats, message)
	saveStats(player)

	return true, rewardSummary
end

function getRelationshipById(stats, relationshipId)
	ensureExtraStats(stats)

	for _, relationship in ipairs(stats.Relationships) do
		if relationship.Id == relationshipId and relationship.Alive ~= false then
			return relationship
		end
	end

	return nil
end

function getBestParentOrCaretaker(stats)
	ensureExtraStats(stats)

	local best = nil
	local bestScore = -1

	for _, relationship in ipairs(stats.Relationships) do
		if relationship.Alive ~= false then
			local role = relationship.Role

			if role == "Mother" or role == "Father" or role == "Caretaker" then
				local score = (relationship.Bond or 0) + (relationship.Trust or 0)

				if score > bestScore then
					best = relationship
					bestScore = score
				end
			end
		end
	end

	return best
end

function ownsAssetById(stats, assetId)
	ensureExtraStats(stats)

	for _, asset in ipairs(stats.Assets) do
		if asset.Id == assetId then
			return true, asset
		end
	end

	return false, nil
end

function countClanStudents(stats)
	ensureExtraStats(stats)

	local count = 0
	for _, relationship in ipairs(stats.Relationships or {}) do
		if relationship.Alive ~= false and relationship.Role == "Student" then
			count += 1
		end
	end

	return count
end

function countDojoStudentsAndWards(stats)
	ensureExtraStats(stats)

	local count = 0
	for _, relationship in ipairs(stats.Relationships or {}) do
		if relationship.Alive ~= false and (relationship.Role == "Student" or relationship.Role == "Ward") then
			count += 1
		end
	end

	return count
end

function getDojoStudentCapacity(stats)
	ensureExtraStats(stats)
	local level = math.clamp(tonumber(stats.DojoLevel) or 1, 1, 5)
	local baseCapacity = 3 + ((level - 1) * 2)
	local reputationBonus = math.clamp(math.floor((stats.ClanReputation or 0) / 35), 0, 4)
	return baseCapacity + reputationBonus
end

function getDojoUpgradeCost(stats)
	ensureExtraStats(stats)
	local level = math.clamp(tonumber(stats.DojoLevel) or 1, 1, 5)
	local costs = {
		[1] = 15000,
		[2] = 35000,
		[3] = 75000,
		[4] = 150000,
	}

	return costs[level]
end

function getDojoMaintainCost(stats)
	ensureExtraStats(stats)
	local missingCondition = 100 - (stats.DojoCondition or 100)
	local level = math.clamp(tonumber(stats.DojoLevel) or 1, 1, 5)
	return math.max(500, math.floor(missingCondition * 75 * level))
end

function getDojoFocusLabel(stats)
	ensureExtraStats(stats)
	return tostring(stats.DojoFocus or "Balanced")
end

function adjustDojoCondition(stats, amount)
	ensureExtraStats(stats)
	stats.DojoCondition = math.clamp((stats.DojoCondition or 100) + amount, 0, 100)
end

local JAPAN_STUDENT_LOCATIONS = {
	"Tokyo, Japan", "Kyoto, Japan", "Osaka, Japan", "Yokohama, Japan", "Nagoya, Japan", "Sapporo, Japan",
	"Fukuoka, Japan", "Kobe, Japan", "Nara, Japan", "Sendai, Japan", "Hiroshima, Japan", "Kawasaki, Japan"
}

local FOREIGN_STUDENT_LOCATIONS = {
	"Seoul, South Korea", "Busan, South Korea", "Beijing, China", "Shanghai, China", "Taipei, Taiwan",
	"Manila, Philippines", "New York, United States", "Los Angeles, United States", "London, United Kingdom",
	"Paris, France", "São Paulo, Brazil", "Mexico City, Mexico"
}

local PREVIOUS_SCHOOLS = {
	"Tokyo Jujutsu Technical School",
	"Kyoto Jujutsu Technical School",
	"Sendai Cursed Arts Prep",
	"Osaka Barrier Studies Program",
	"Yokohama Spiritual Safety Academy",
	"Private Sorcerer Tutoring",
	"Civilian Middle School",
	"Foreign Exchange Sorcery Program",
	"No Formal Jujutsu School"
}

local STUDENT_BACKGROUNDS = {
	"A disciplined student who wants structure more than praise.",
	"A talented but cautious sorcerer who does not trust new clans quickly.",
	"A quiet recruit with unstable cursed energy and strong survival instincts.",
	"A former school prospect who left after a curse incident went badly.",
	"A foreign student trying to find a clan that will actually train them.",
	"A sharp learner with good instincts but weak emotional control.",
	"A stubborn candidate who only respects results.",
	"A calm student with a strong sense of duty and a complicated family record.",
	"A low-profile recruit with more potential than their grade suggests.",
	"A student who has bounced between mentors and wants a permanent place."
}

local MALE_RECRUIT_NAMES = { "Kazuto", "Ren", "Akio", "Haruto", "Kaito", "Riku", "Daichi", "Yuto", "Seiji", "Naoto", "Kenshi", "Toma" }
local FEMALE_RECRUIT_NAMES = { "Aoi", "Yuna", "Hana", "Mei", "Rina", "Saki", "Mika", "Reina", "Akari", "Shiori", "Kanna", "Aya" }
local RECRUIT_FAMILY_NAMES = { "Kumiwado", "Mizukara", "Amahara", "Tsukigane", "Kurogiri", "Hoshinari", "Yamashiro", "Shinkawa", "Morikage", "Fushidori", "Kazehara", "Sakuraba", "Kurosawa", "Tachibana" }

function normalizeClanName(rawName, fallbackFamilyName)
	local text = tostring(rawName or "")
	text = text:gsub("<", ""):gsub(">", "")
	text = text:gsub("[^%w%s%-']", "")
	text = text:gsub("^%s+", ""):gsub("%s+$", "")
	text = text:gsub("%s+", " ")

	if text == "" then
		text = tostring(fallbackFamilyName or "Unnamed")
	end

	local baseName = text:gsub("%s+[Cc][Ll][Aa][Nn]$", "")
	baseName = baseName:gsub("^%s+", ""):gsub("%s+$", "")

	if baseName == "" then
		baseName = tostring(fallbackFamilyName or "Unnamed")
	end

	return baseName .. " Clan", baseName
end

function makeRecruitCandidate(stats, index)
	ensureExtraStats(stats)

	local gender = math.random(1, 2) == 1 and "Male" or "Female"
	local firstName = gender == "Female" and pickRandom(FEMALE_RECRUIT_NAMES) or pickRandom(MALE_RECRUIT_NAMES)
	local familyName = pickRandom(RECRUIT_FAMILY_NAMES)
	local age = math.random(13, 22)
	local grade = pickRandom({ "Non-Sorcerer", "Grade 4", "Grade 4", "Semi-Grade 3", "Grade 3", "Grade 3", "Semi-Grade 2", "Grade 2" })
	local foreign = math.random(1, 100) <= 15
	local location = foreign and pickRandom(FOREIGN_STUDENT_LOCATIONS) or pickRandom(JAPAN_STUDENT_LOCATIONS)
	local school = foreign and "Foreign Exchange Sorcery Program" or pickRandom(PREVIOUS_SCHOOLS)
	local fatherStatus = pickRandom({ "Alive", "Alive", "Unknown", "Deceased" })
	local motherStatus = pickRandom({ "Alive", "Alive", "Unknown", "Deceased" })
	local potential = pickRandom({ "Average", "Average", "High", "High", "Rare", "Hidden" })
	local technique = math.random(1, 100) <= 38 and BitKaisenStats.RollTechnique(stats.Origin or stats.Clan or "Minor Sorcerer Family") or "None"
	local ce = math.random(18, 90)

	if grade == "Grade 2" then
		ce = math.random(85, 150)
	elseif grade == "Semi-Grade 2" then
		ce = math.random(65, 115)
	elseif grade == "Grade 3" then
		ce = math.random(45, 95)
	elseif grade == "Semi-Grade 3" then
		ce = math.random(30, 70)
	elseif grade == "Grade 4" then
		ce = math.random(18, 55)
	end

	local background = pickRandom(STUDENT_BACKGROUNDS)

	return {
		Id = "candidate_" .. tostring(os.time()) .. "_" .. tostring(index) .. "_" .. tostring(math.random(1000, 9999)),
		Name = firstName .. " " .. familyName,
		FirstName = firstName,
		FamilyName = familyName,
		Gender = gender,
		Age = age,
		Grade = grade,
		CursedEnergy = ce,
		CursedTechnique = technique,
		OriginLocation = location,
		PreviousSchool = school,
		FatherStatus = fatherStatus,
		MotherStatus = motherStatus,
		Personality = pickRandom({
			"Disciplined but hard to reach.",
			"Quiet, watchful, and slow to trust.",
			"Confident, direct, and competitive.",
			"Polite, but hiding a lot of pressure.",
			"Raw talent with poor control.",
			"Careful, analytical, and serious about training."
		}),
		Background = background,
		DojoPotential = potential,
		QuestionAnswers = {
			WhyJoin = "I want a place that actually trains me instead of treating me like a number.",
			OldSchool = school == "No Formal Jujutsu School" and "I did not have a real school. I learned from scraps, rumors, and surviving." or ("I came from " .. school .. ", but I need a different path."),
			Goal = "I want to become strong enough that nobody can decide my future for me."
		}
	}
end

function generateDojoRecruitPool(stats)
	ensureExtraStats(stats)
	stats.DojoRecruitPool = {}

	for index = 1, 10 do
		table.insert(stats.DojoRecruitPool, makeRecruitCandidate(stats, index))
	end
end

function findRecruitCandidate(stats, candidateId)
	ensureExtraStats(stats)

	for index, candidate in ipairs(stats.DojoRecruitPool or {}) do
		if candidate.Id == candidateId then
			return candidate, index
		end
	end

	return nil, nil
end

function removeRecruitCandidate(stats, candidateId)
	local _, index = findRecruitCandidate(stats, candidateId)

	if index then
		table.remove(stats.DojoRecruitPool, index)
	end
end

function getDojoStudentsForPayload(stats)
	ensureExtraStats(stats)
	local list = {}

	for _, relationship in ipairs(stats.Relationships or {}) do
		if relationship.Alive ~= false and (relationship.Role == "Student" or relationship.Role == "Ward") then
			table.insert(list, {
				Id = relationship.Id,
				Name = relationship.Name,
				Role = relationship.Role,
				Gender = relationship.Gender or "Unknown",
				Age = relationship.Age or 0,
				Grade = relationship.Grade or "Non-Sorcerer",
				CursedEnergy = relationship.CursedEnergy or 0,
				CursedTechnique = relationship.CursedTechnique or "None",
				DojoPotential = relationship.DojoPotential or "Unknown",
				OriginLocation = relationship.OriginLocation or "Unknown",
				PreviousSchool = relationship.PreviousSchool or "Unknown",
				Background = relationship.Background or "No record yet.",
			})
		end
	end

	return list
end

function recruitCandidateIntoDojo(stats, candidate)
	ensureExtraStats(stats)

	local student = BitKaisenRelationships.CreateRelationship(
		"Student",
		candidate.Name,
		"Clan Student",
		math.random(30, 55),
		math.random(20, 50),
		math.random(25, 65),
		0,
		0,
		candidate.Gender
	)

	student.FirstName = candidate.FirstName
	student.FamilyName = candidate.FamilyName
	student.Gender = candidate.Gender
	student.Age = candidate.Age
	student.Grade = candidate.Grade
	student.CursedEnergy = candidate.CursedEnergy
	student.CursedTechnique = candidate.CursedTechnique
	student.Personality = candidate.Personality
	student.Background = candidate.Background
	student.DojoPotential = candidate.DojoPotential
	student.OriginLocation = candidate.OriginLocation
	student.PreviousSchool = candidate.PreviousSchool
	student.FatherStatus = candidate.FatherStatus
	student.MotherStatus = candidate.MotherStatus
	student.Romance = 0
	student.IsClanStudent = true
	student.JoinedFromRecruitPool = true

	return BitKaisenRelationships.AddRelationship(stats, student)
end

function createClanStudent(stats)
	ensureExtraStats(stats)

	local student = BitKaisenRelationships.CreateRelationship(
		"Student",
		nil,
		"Clan Student",
		math.random(35, 65),
		math.random(25, 55),
		math.random(30, 70),
		0,
		0
	)

	student.Gender = math.random(1, 2) == 1 and "Male" or "Female"
	student.Age = math.random(13, 24)
	student.Grade = pickRandom({ "Non-Sorcerer", "Grade 4", "Grade 4", "Semi-Grade 3", "Grade 3" })
	student.CursedEnergy = math.random(12, 75)
	student.CursedTechnique = math.random(1, 100) <= 35 and BitKaisenStats.RollTechnique(stats.Origin or stats.Clan or "Minor Sorcerer Family") or "None"
	student.Personality = student.Personality or "Eager to prove themselves under your clan."
	student.Background = "They joined the " .. tostring(stats.PlayerClanName or "clan") .. " to train at your Grand Dojo and grow as a sorcerer."
	student.Romance = 0
	student.IsClanStudent = true
	student.DojoPotential = student.DojoPotential or pickRandom({ "Low", "Average", "Average", "High", "Rare" })
	student.Background = student.Background or ("They joined the " .. tostring(stats.PlayerClanName or "clan") .. " to train at your Grand Dojo and grow as a sorcerer.")

	return BitKaisenRelationships.AddRelationship(stats, student)
end

function createRescuedWard(stats, sourceText)
	ensureExtraStats(stats)

	local gender = math.random(1, 2) == 1 and "Male" or "Female"
	local ward = BitKaisenRelationships.CreateRelationship(
		"Ward",
		nil,
		"Rescued Ward",
		math.random(28, 48),
		math.random(18, 42),
		math.random(6, 20),
		math.random(0, 8),
		0,
		gender
	)

	ward.Age = math.random(1, 5)
	ward.Grade = "Non-Sorcerer"
	ward.CursedEnergy = math.random(2, 28)
	ward.CursedTechnique = "None"
	ward.Personality = pickRandom({
		"Quiet and cautious around strangers",
		"Easily startled but naturally observant",
		"Small, stubborn, and strangely fearless",
		"Clings to routine after surviving something awful",
		"Soft-spoken, but their cursed energy reacts strongly under stress"
	})
	ward.Background = sourceText or "You found them during a curse incident and became responsible for their future."
	ward.Romance = 0
	ward.IsWard = true
	ward.CanInheritTechnique = true
	ward.DojoPotential = pickRandom({ "Hidden", "Hidden", "Average", "High", "Rare" })
	ward.RescueAge = stats.Age or 0

	stats.WardsRescued = (stats.WardsRescued or 0) + 1
	stats.ClanMembers = math.max(stats.ClanMembers or 0, countDojoStudentsAndWards(stats) + 1)

	return BitKaisenRelationships.AddRelationship(stats, ward)
end

function getOrphanRescueChance(stats, missionData)
	ensureExtraStats(stats)

	local chance = tonumber(missionData.OrphanRescueChance) or 0

	if chance <= 0 then
		local grade = tostring(missionData.Grade or "")
		if grade == "Grade 4" then
			chance = 3
		elseif grade == "Semi-Grade 3" or grade == "Grade 3" then
			chance = 5
		elseif grade == "Semi-Grade 2" or grade == "Grade 2" then
			chance = 7
		else
			chance = 4
		end
	end

	if stats.ClanFounded then
		chance += 3
	end

	if ownsAssetById(stats, "grand_dojo") then
		chance += 2
	end

	if (stats.Reputation or 0) >= 50 then
		chance += 2
	end

	return math.clamp(chance, 0, 14)
end

function beginOrphanRescueSituation(player, stats, missionData)
	if not player or not stats or stats.Alive == false then
		return false
	end

	ensureExtraStats(stats)

	if (stats.Age or 0) < 16 then
		return false
	end

	local capacity = getDojoStudentCapacity(stats)
	local current = countDojoStudentsAndWards(stats)
	local canTakeIn = stats.ClanFounded == true and ownsAssetById(stats, "grand_dojo") and current < capacity

	local options = {
		{ Index = 1, Text = canTakeIn and "Take them in as your ward" or "Take them in anyway", RescueChoice = "take_in" },
		{ Index = 2, Text = "Bring them to Jujutsu High", RescueChoice = "jujutsu_high" },
		{ Index = 3, Text = "Find them a civilian foster home", RescueChoice = "foster_home" },
		{ Index = 4, Text = "Leave it to the authorities", RescueChoice = "authorities" }
	}

	pendingMissions[player.UserId] = {
		Type = "OrphanRescue",
		missionId = missionData.Id,
		availableOptions = options
	}

	showMissionSituation:FireClient(player, {
		MissionTitle = missionData.Title,
		Title = "A Child in the Curse Site",
		Body = "After the curse fades, you hear a small noise from the wreckage. A very young orphan is hiding nearby, barely old enough to understand what happened. Their cursed energy is unstable, but real.",
		Options = options
	})

	return true
end

function resolveOrphanRescueChoice(player, stats, missionData, choice)
	ensureExtraStats(stats)

	local rescueChoice = choice and choice.RescueChoice or "authorities"
	local message = ""

	if rescueChoice == "take_in" then
		local capacity = getDojoStudentCapacity(stats)
		local current = countDojoStudentsAndWards(stats)
		local hasDojo = ownsAssetById(stats, "grand_dojo")

		if not stats.ClanFounded or not hasDojo then
			stats.Happiness = math.clamp((stats.Happiness or 100) - 3, 0, 100)
			stats.Reputation = (stats.Reputation or 0 + 1)
			message = "You wanted to take the child in, but without a founded clan and Grand Dojo, you could not give them a stable place to train. Jujutsu High took custody instead."
		else
			if current >= capacity then
				stats.Happiness = math.clamp((stats.Happiness or 100) - 2, 0, 100)
				stats.Reputation = (stats.Reputation or 0 + 2)
				message = "Your dojo was already at capacity, so you arranged for the child to be protected through Jujutsu High instead."
			else
				local ward = createRescuedWard(stats, "You rescued them after " .. tostring(missionData.Title or "a curse mission") .. " and chose to raise them under your protection.")
				stats.Happiness = math.clamp((stats.Happiness or 100) + 8, 0, 100)
				stats.Reputation = (stats.Reputation or 0 + 4)
				stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + 3)
				stats.ClanMembers = math.max(stats.ClanMembers or 0, countDojoStudentsAndWards(stats) + 1)

				message = "You took in <b>" .. ward.Name .. "</b> as your ward. They were added to your Relationships page and can grow through your dojo over time."

				fireMajorPopup(
					player,
					"WARD RESCUED",
					"You saved a young orphan from the curse site and chose to raise them under your protection.",
					ward.Name,
					"They can become a student as they grow."
				)
			end
		end
	elseif rescueChoice == "jujutsu_high" then
		stats.Reputation = (stats.Reputation or 0 + 5)
		stats.TeacherRecommendations = (stats.TeacherRecommendations or 0) + (math.random(1, 100) <= 35 and 1 or 0)
		stats.Happiness = math.clamp((stats.Happiness or 100) + 3, 0, 100)
		message = "You brought the orphan to Jujutsu High. The staff recognized your judgement and the child was placed under protection."
	elseif rescueChoice == "foster_home" then
		stats.Reputation = (stats.Reputation or 0 + 2)
		stats.Happiness = math.clamp((stats.Happiness or 100) + 5, 0, 100)
		message = "You found the child a civilian foster home far from curses. It was not flashy, but it gave them a safer life."
	else
		stats.Happiness = math.clamp((stats.Happiness or 100) - 4, 0, 100)
		message = "You left the situation to the authorities. The mission ended cleanly, but the choice stayed with you."
	end

	fireLifeUpdate(player, stats, "<font color='#f0b955'><b>[ RESCUE ]</b></font> " .. message)
	saveStats(player)
end


function getBirthOriginMessage(stats)
	local origin = stats.Origin or stats.Clan or "Minor Sorcerer Family"
	local familyName = stats.FamilyName or "Unknown"
	local familyType = stats.FamilyType or "Unknown"

	if origin == "Cursed Womb" then
		return "<font color='#a782ff'><b>[ ORIGIN ]</b></font> You were born as a Cursed Womb."
	end

	if origin == "Zenin Clan" or origin == "Kamo Clan" or origin == "Gojo Clan" then
		return "<font color='#a782ff'><b>[ CLAN ]</b></font> You were born into the " .. origin .. "."
	end

	if familyType == "Sorcerer" then
		return "<font color='#a782ff'><b>[ FAMILY ]</b></font> You were born into the " .. familyName .. " Family, a sorcerer family."
	end

	if familyType == "Fallen" then
		return "<font color='#a782ff'><b>[ FAMILY ]</b></font> You were born into the " .. familyName .. " Family, a fallen sorcerer family."
	end

	if familyType == "Unknown" then
		return "<font color='#a782ff'><b>[ FAMILY ]</b></font> You were born into the " .. familyName .. " Family, a family with an unknown history."
	end

	return "<font color='#a782ff'><b>[ ORIGIN ]</b></font> Your origin is unknown."
end

function performActualSave(player, reason)
	if not player then
		return false
	end

	local userId = player.UserId
	local stats = playerLives[userId]

	if not stats then
		return false
	end

	if activeSavePlayers[userId] then
		dirtySavePlayers[userId] = true
		return false
	end

	activeSavePlayers[userId] = true
	dirtySavePlayers[userId] = nil

	local ok, result = pcall(function()
		BitKaisenSaveSystem.Save(player, stats)
	end)

	lastSaveTimes[userId] = os.clock()
	activeSavePlayers[userId] = nil

	if not ok then
		warn("[GameManager] Save failed for " .. tostring(player.Name) .. " (" .. tostring(reason or "unknown") .. "): " .. tostring(result))
		dirtySavePlayers[userId] = true
		return false
	end

	return true
end

function saveStats(player, reason)
	if not player then
		return
	end

	local userId = player.UserId
	local stats = playerLives[userId]

	if not stats then
		return
	end

	dirtySavePlayers[userId] = true

	if scheduledSavePlayers[userId] then
		return
	end

	scheduledSavePlayers[userId] = true

	task.delay(SAVE_DEBOUNCE_SECONDS, function()
		scheduledSavePlayers[userId] = nil

		if not player or not player.Parent then
			return
		end

		if dirtySavePlayers[userId] then
			performActualSave(player, reason or "debounced")
		end
	end)
end

function forceSaveStats(player, reason)
	if not player then
		return false
	end

	local userId = player.UserId
	local stats = playerLives[userId]

	if not stats then
		return false
	end

	local now = os.clock()
	local lastSave = lastSaveTimes[userId] or 0

	if activeSavePlayers[userId] then
		dirtySavePlayers[userId] = true
		return false
	end

	-- If a force save is requested immediately after another real save, avoid hammering the same key.
	-- PlayerRemoving and BindToClose still attempt a final save because those happen after gameplay has ended.
	if reason ~= "PlayerRemoving" and reason ~= "BindToClose" and (now - lastSave) < SAVE_FORCE_MIN_GAP_SECONDS then
		saveStats(player, reason or "force-cooldown")
		return false
	end

	scheduledSavePlayers[userId] = nil
	return performActualSave(player, reason or "force")
end

function startAutosaveLoop(player)
	if autosaveLoops[player.UserId] then
		return
	end

	autosaveLoops[player.UserId] = task.spawn(function()
		while player and player.Parent and playerLives[player.UserId] do
			task.wait(AUTOSAVE_INTERVAL)

			if not player or not player.Parent then
				break
			end

			if playerLives[player.UserId] then
				saveStats(player)
			end
		end

		autosaveLoops[player.UserId] = nil
	end)
end

function addCursedResentment(stats, amount)
	if not stats then
		return 0
	end

	amount = tonumber(amount) or 0
	if amount <= 0 then
		stats.CursedResentment = math.max(0, tonumber(stats.CursedResentment) or 0)
		return stats.CursedResentment
	end

	stats.CursedResentment = math.clamp((tonumber(stats.CursedResentment) or 0) + amount, 0, 999)
	return stats.CursedResentment
end

function getCurseRebirthScore(stats)
	if not stats then
		return 0
	end

	local score = 0
	score += math.floor((tonumber(stats.CursedEnergy) or 0) * 0.65)
	score += math.floor((tonumber(stats.TechniqueMastery) or 0) * 3)
	score += math.floor(math.max(0, tonumber(stats.CursedResentment) or 0) * 1.25)
	score += math.floor(math.max(0, tonumber(stats.WantedLevel) or 0) * 30)
	score += math.floor(math.max(0, -(tonumber(stats.Reputation) or 0)) * 1.5)
	score += math.floor(math.max(0, tonumber(stats.ExorcismRisk) or 0) * 1.5)

	local grade = getGradeValue(stats.Grade)
	score += grade * 35

	if isCurseUser(stats) then
		score += 80
	end

	if tostring(stats.CauseOfDeath or "") ~= "" then
		local cause = string.lower(tostring(stats.CauseOfDeath or ""))
		if string.find(cause, "curse", 1, true) or string.find(cause, "sorcerer", 1, true) or string.find(cause, "mission", 1, true) or string.find(cause, "exorc", 1, true) then
			score += 60
		end
	end

	return math.max(0, math.floor(score))
end

function getCurseGradeFromRebirthScore(score)
	score = tonumber(score) or 0
	if score >= 550 then
		return "Special Grade Cursed Spirit"
	elseif score >= 350 then
		return "Grade 1 Cursed Spirit"
	elseif score >= 200 then
		return "Grade 2 Cursed Spirit"
	elseif score >= 100 then
		return "Grade 3 Cursed Spirit"
	end
	return "Grade 4 Cursed Spirit"
end

function getCurseSubtypeFromPreviousLife(stats)
	if not stats then
		return "Cursed Spirit"
	end

	local cause = string.lower(tostring(stats.CauseOfDeath or ""))
	local wanted = tonumber(stats.WantedLevel) or 0
	local reputation = tonumber(stats.Reputation) or 0
	local familyRep = tonumber(stats.FamilyReputation) or tonumber(stats.ClanReputation) or 0

	if wanted >= 3 or reputation <= -25 then
		return "Fear-Born Cursed Spirit"
	end

	if string.find(cause, "mission", 1, true) or string.find(cause, "battle", 1, true) or string.find(cause, "sorcerer", 1, true) then
		return "Death-Bound Cursed Spirit"
	end

	if familyRep >= 40 or tonumber(stats.BloodlineStrength) and tonumber(stats.BloodlineStrength) >= 45 then
		return "Cursed Womb"
	end

	if isCurseUser(stats) or (tonumber(stats.CursedResentment) or 0) >= 150 then
		return "Vengeful Cursed Spirit"
	end

	return "Cursed Spirit"
end

function canBecomeVengefulSpirit(stats)
	if not stats then
		return false
	end

	if stats.Alive ~= false then
		return false
	end

	if isCurseLife(stats) then
		return false
	end

	return (tonumber(stats.CursedResentment) or 0) >= 100
end

function refreshCurseRebirthEligibility(stats)
	if not stats then
		return false
	end

	stats.CurseRebirthEligible = canBecomeVengefulSpirit(stats)
	return stats.CurseRebirthEligible
end

function startAsCurseRebirth(player)
	local oldStats = playerLives[player.UserId]
	if not oldStats then
		return false, "No dead life found."
	end

	ensureExtraStats(oldStats)
	refreshCurseRebirthEligibility(oldStats)

	if not canBecomeVengefulSpirit(oldStats) then
		return false, "This life did not leave enough cursed resentment behind."
	end

	local preservedSettings = oldStats.Settings
	local preservedMetaProgress = oldStats.MetaProgress
	local oldName = tostring(oldStats.Name or "Unknown")
	local oldTechnique = tostring(oldStats.CursedTechnique or "None")
	local score = getCurseRebirthScore(oldStats)
	local subtype = getCurseSubtypeFromPreviousLife(oldStats)
	local curseGrade = getStartingUnregisteredCurseGradeFromRebirthScore(score)

	pendingMissions[player.UserId] = nil
	pendingLegacy[player.UserId] = nil

	local newStats = BitKaisenStats.GetDefaultStats()
	ensureExtraStats(newStats)

	if preservedSettings then
		newStats.Settings = preservedSettings
	end

	if preservedMetaProgress then
		newStats.MetaProgress = preservedMetaProgress
	end

	local curseNamePrefix = "Curse"
	if subtype == "Vengeful Cursed Spirit" then curseNamePrefix = "Vengeful Spirit" end
	if subtype == "Fear-Born Cursed Spirit" then curseNamePrefix = "Fear-Born Cursed Spirit" end
	if subtype == "Death-Bound Cursed Spirit" then curseNamePrefix = "Death-Bound Cursed Spirit" end
	if subtype == "Cursed Womb" then curseNamePrefix = "Cursed Womb" end

	newStats.Race = "Cursed Spirit"
	newStats.Name = curseNamePrefix .. " of " .. oldName
	newStats.FirstName = curseNamePrefix
	newStats.FamilyName = "Cursed Spirit"
	newStats.FamilyType = "Cursed Spirit"
	newStats.Gender = "Unknown"
	newStats.Clan = "Cursed Spirit"
	newStats.Origin = "Vengeful Spirit Rebirth"
	newStats.OriginCategory = "Race"
	newStats.IsCurse = true
	newStats.CurseType = subtype
	newStats.CurseGrade = curseGrade
	newStats.CurseClassified = false
	newStats.CurseEvolution = "Dormant"
	newStats.CurseEvolutionProgress = math.clamp(math.floor((tonumber(oldStats.CursedResentment) or 0) / 4), 0, 80)
	newStats.CurseThreat = math.clamp(math.floor(score / 18), 5, 80)
	newStats.ExorcismRisk = math.clamp(10 + math.floor((tonumber(oldStats.WantedLevel) or 0) * 8), 0, 65)
	newStats.SorcererAttackCooldown = 2
	newStats.SocietyStatus = "Unregistered Cursed Spirit"
	newStats.RegisteredSorcerer = false
	newStats.CursedResentment = math.clamp(math.floor((tonumber(oldStats.CursedResentment) or 0) * 0.55), 25, 250)
	newStats.CurseRebirthCount = (tonumber(oldStats.CurseRebirthCount) or 0) + 1
	newStats.PreviousLifeName = oldName
	newStats.PreviousLifeCauseOfDeath = tostring(oldStats.CauseOfDeath or "Unknown")
	newStats.CurseTerritory = pickRandom(CURSE_TERRITORIES)
	newStats.CurseRumor = pickRandom(CURSE_RUMOR_TITLES)
	newStats.CurseHunger = math.random(35, 60)
	newStats.SocietyAttention = math.clamp(newStats.ExorcismRisk or 10, 0, 100)
	newStats.CurseFearLevel = math.max(5, math.floor((tonumber(newStats.CurseThreat) or 0) / 2))
	newStats.CurseTerritoryControl = math.random(10, 25)
	newStats.CurseRumorSpread = math.random(0, 12)
	newStats.CiviliansTerrified = 0
	newStats.HuntersEscaped = 0

	newStats.Age = 0
	newStats.Health = 100
	newStats.Happiness = 0
	newStats.Money = 0
	newStats.Reputation = math.min(0, tonumber(oldStats.Reputation) or 0)
	newStats.Smarts = math.clamp(math.floor((tonumber(oldStats.Smarts) or 50) * 0.45), 5, 70)
	newStats.CursedEnergy = math.max(35, math.floor((tonumber(oldStats.CursedEnergy) or 0) * 0.45) + math.floor(score / 8))

	if oldTechnique ~= "None" then
		newStats.CursedTechnique = oldTechnique
		newStats.InnateTechnique = oldTechnique
		newStats.TechniqueKnown = true
		newStats.TechniqueUsable = true
		newStats.TechniqueAwakened = true
		newStats.InnateDormant = false
		newStats.TechniqueMastery = math.clamp(math.floor((tonumber(oldStats.TechniqueMastery) or 0) * 0.35), 5, 50)
	else
		newStats.CursedTechnique = "None"
		newStats.TechniqueMastery = 0
	end

	newStats.Traits = BitKaisenTraits.RollBirthTraits(newStats)
	BitKaisenTraits.ApplyStartingBonuses(newStats)
	newStats.TraitsRolled = true
	newStats.Relationships = {}
	newStats.RelationshipHistory = oldStats.RelationshipHistory or {}
	newStats.LegacyHistory = oldStats.LegacyHistory or {}

	normalizeCursedSocietyState(newStats)
	playerLives[player.UserId] = newStats

	local message = "<font color='#b27aff'><b>[ CURSE REBIRTH ]</b></font> Your body died, but your cursed energy refused to disappear."
	message ..= "\nYou returned as a <b>" .. tostring(subtype) .. "</b>."
	message ..= "\nRace: <b>Curse</b> | Grade: <b>" .. tostring(curseGrade) .. "</b> | Threat: <b>" .. tostring(newStats.CurseThreat or 0) .. "</b>."
	message ..= "\nPrevious Life: <b>" .. oldName .. "</b>."
	if oldTechnique ~= "None" then
		message ..= "\nYour old cursed technique echoed into your new form: <b>" .. oldTechnique .. "</b>."
	end
	message ..= "\nCurses do not die from old age, but sorcerers will hunt you if your threat spreads."

	fireLifeUpdate(player, newStats, message, true)
	forceSaveStats(player, "curse rebirth")
	return true
end

function startNewLife(player)
	local oldStats = playerLives[player.UserId]
	local preservedSettings = nil
	local preservedMetaProgress = nil

	if oldStats and oldStats.Settings then
		preservedSettings = oldStats.Settings
	end

	if oldStats and oldStats.MetaProgress then
		preservedMetaProgress = oldStats.MetaProgress
	end

	pendingMissions[player.UserId] = nil
	pendingLegacy[player.UserId] = nil

	local newStats = BitKaisenStats.GetDefaultStats()
	ensureExtraStats(newStats)

	if preservedSettings then
		newStats.Settings = preservedSettings
	end

	if preservedMetaProgress then
		newStats.MetaProgress = preservedMetaProgress
	end

	local rolledOrigin = BitKaisenStats.RollOrigin()
	local rolledGender = math.random(1, 2) == 1 and "Male" or "Female"
	local identity = BitKaisenStats.GenerateRandomIdentity(rolledOrigin, rolledGender)

	newStats.Name = identity.FullName
	newStats.FirstName = identity.FirstName
	newStats.FamilyName = identity.FamilyName
	newStats.FamilyType = identity.FamilyType
	newStats.Gender = identity.Gender or rolledGender

	newStats.Clan = rolledOrigin.DisplayName
	newStats.Origin = rolledOrigin.DisplayName
	newStats.OriginCategory = rolledOrigin.Category

	newStats.CursedEnergy += rolledOrigin.BonusCE
	newStats.Smarts = math.clamp(newStats.Smarts + rolledOrigin.BonusSmarts, 1, 100)

	BitKaisenStats.ApplyBirthTechnique(newStats, rolledOrigin)
	normalizeCursedSocietyState(newStats)
	ensureSorcererRegistrationState(newStats)

	local heavenlyRestrictionChance = newStats.MetaProgress and newStats.MetaProgress.HeavenlyRestrictionBoost and 15 or 3
	if math.random(1, 100) <= heavenlyRestrictionChance then
		newStats.HeavenlyRestricted = true
		newStats.Health = math.clamp((newStats.Health or 100) + 8, 0, 100)
		newStats.Smarts = math.clamp((newStats.Smarts or 0) + 4, 0, 100)
		newStats.Reputation = math.max(0, (newStats.Reputation or 0) + 1)
	end

	newStats.Traits = BitKaisenTraits.RollBirthTraits(newStats)
	BitKaisenTraits.ApplyStartingBonuses(newStats)
	newStats.TraitsRolled = true
	syncFamilyStatus(newStats)
	ensureSorcererRegistrationState(newStats)

	BitKaisenRelationships.GenerateStartingRelationships(newStats)

	playerLives[player.UserId] = newStats

	local birthMessage = "You were born with no recognized sorcerer grade."
	birthMessage = birthMessage .. "\n" .. getBirthOriginMessage(newStats)
	if isCurseLife(newStats) then
		birthMessage = birthMessage .. "\n<font color='#b27aff'><b>[ CURSE LIFE ]</b></font> You are not bound by normal human aging. Sorcerers may eventually come for you, but old age will not."
		birthMessage = birthMessage .. "\nEstimated Classification: <b>" .. tostring(newStats.CurseGrade or "Unregistered Grade 3 Cursed Spirit") .. "</b> | Threat: <b>" .. tostring(newStats.CurseThreat or 0) .. "</b>."
	end
	birthMessage = birthMessage .. "\nYour name is <b>" .. newStats.Name .. "</b>."
	birthMessage = birthMessage .. "\nGender: <b>" .. tostring(newStats.Gender or "Unknown") .. "</b>."
	birthMessage = birthMessage .. "\n" .. BitKaisenTraits.BuildBirthMessage(newStats)

	if tostring(newStats.InnateTechnique or "None") ~= "None" then
		birthMessage = birthMessage .. "\nYou were born with the dormant innate technique <b>" .. tostring(newStats.InnateTechnique) .. "</b>. It should become usable around age 10-11."
	end

	if newStats.HeavenlyRestricted then
		birthMessage = birthMessage .. "\n<font color='#f0b955'><b>[ HEAVENLY RESTRICTION ]</b></font> Your body was born different. Your physical instincts are sharper than most sorcerers your age."
	end

	fireLifeUpdate(player, newStats, birthMessage, true)
	saveStats(player)
end

function startAsSuccessor(player, successorId)
	local parentStats = playerLives[player.UserId]

	if not parentStats then
		return false, "No previous life data found."
	end

	if parentStats.Alive ~= false then
		return false, "Your previous life is still ongoing."
	end

	local preservedSettings = parentStats.Settings

	local newStats, errorMessage = BitKaisenLegacy.BuildSuccessorStats(parentStats, successorId, BitKaisenStats, BitKaisenRelationships)

	if not newStats then
		return false, errorMessage or "Could not create successor."
	end

	ensureExtraStats(newStats)
	local inheritedInnate, inheritedTechnique = BitKaisenStats.ApplyInheritedTechniqueFromParent(newStats, parentStats)
	if inheritedInnate then
		newStats.LegacyHistory = newStats.LegacyHistory or {}
		table.insert(newStats.LegacyHistory, "Inherited " .. tostring(inheritedTechnique) .. " as a dormant clan innate technique.")
	end
	if preservedSettings then
		newStats.Settings = preservedSettings
	end

	if parentStats.MetaProgress then
		newStats.MetaProgress = parentStats.MetaProgress
	end

	pendingMissions[player.UserId] = nil
	pendingLegacy[player.UserId] = nil

	playerLives[player.UserId] = newStats

	local introMessage = BitKaisenLegacy.BuildIntroMessage(newStats, parentStats)

	fireLifeUpdate(player, newStats, introMessage, true)

	fireMajorPopup(
		player,
		"LEGACY CONTINUES",
		"A new generation of the " .. tostring(newStats.FamilyName or "Unknown") .. " Family begins.",
		newStats.Name,
		"Generation " .. tostring(newStats.Generation or 2) .. " of your bloodline."
	)

	saveStats(player)
	return true, nil
end

function loadOrStartLife(player)
	local loaded = BitKaisenSaveSystem.Load(player, ownsSaveSlotAccess(player))

	if loaded then
		ensureExtraStats(loaded)
		BitKaisenRelationships.SanitizeOnLoad(loaded)
		BitKaisenAssets.SanitizeOnLoad(loaded)

		playerLives[player.UserId] = loaded

		local welcomeMessage = "<font color='#a782ff'><b>[ SAVE LOADED ]</b></font> Welcome back, <b>" .. tostring(loaded.Name or "Unknown") .. "</b>."

		if loaded.Generation and loaded.Generation > 1 then
			welcomeMessage = welcomeMessage .. "\nGeneration " .. tostring(loaded.Generation) .. " of the " .. tostring(loaded.FamilyName or "Unknown") .. " bloodline."
		end

		welcomeMessage = welcomeMessage .. "\nResuming at age " .. tostring(loaded.Age or 0) .. "."

		fireLifeUpdate(player, loaded, welcomeMessage, true)
	else
		startNewLife(player)
	end

	startAutosaveLoop(player)
end

function getSaveSlotPayload(player)
	local hasVIP = ownsVIPSorcererPass(player)
	local hasExtraSaveSlots = ownsExtraSaveSlotsPass(player)
	local hasSaveSlotsAccess = hasVIP or hasExtraSaveSlots
	local payload = BitKaisenSaveSystem.GetSlots(player, hasSaveSlotsAccess)
	payload.HasVIP = hasVIP
	payload.HasExtraSaveSlots = hasExtraSaveSlots
	payload.HasSaveSlotsAccess = hasSaveSlotsAccess
	payload.VIPGamePassId = VIP_SORCERER_PASS_ID
	payload.ExtraSaveSlotsGamePassId = EXTRA_SAVE_SLOTS_PASS_ID
	payload.FreeSlotCount = 1
	return payload
end

function clearPendingPlayerState(player)
	pendingMissions[player.UserId] = nil
	pendingLegacy[player.UserId] = nil
end

function switchToSaveSlot(player, slotId)
	if not checkRateLimit(player, "SelectSaveSlot") then
		return
	end

	slotId = tonumber(slotId)

	if not slotId then
		return
	end

	local currentStats = playerLives[player.UserId]
	if currentStats then
		forceSaveStats(player, "BeforeSelectSaveSlot")
	end

	local ok, errorMessage = BitKaisenSaveSystem.SelectSlot(player, slotId, ownsSaveSlotAccess(player))

	if not ok then
		if currentStats then
			fireLifeUpdate(player, currentStats, "<font color='#e53935'><b>[ SAVE SLOT ]</b></font> " .. tostring(errorMessage or "Could not switch slots."))
		end

		return
	end

	local loaded = BitKaisenSaveSystem.LoadSlot(player, slotId)

	if not loaded then
		if currentStats then
			fireLifeUpdate(player, currentStats, "<font color='#e53935'><b>[ SAVE SLOT ]</b></font> Could not load that slot.")
		end

		return
	end

	clearPendingPlayerState(player)

	ensureExtraStats(loaded)
	BitKaisenRelationships.SanitizeOnLoad(loaded)
	BitKaisenAssets.SanitizeOnLoad(loaded)

	playerLives[player.UserId] = loaded

	local message = "<font color='#a782ff'><b>[ SAVE SLOT ]</b></font> Loaded Slot " .. tostring(slotId) .. "."
	message = message .. "\nWelcome back, <b>" .. tostring(loaded.Name or "Unknown") .. "</b>."
	message = message .. "\nAge " .. tostring(loaded.Age or 0) .. " | " .. tostring(loaded.Grade or "Unknown") .. "."

	fireLifeUpdate(player, loaded, message, true)
end

function createSaveSlotLife(player, slotId)
	if not checkRateLimit(player, "CreateSaveSlot") then
		return
	end

	slotId = tonumber(slotId)

	if not slotId then
		return
	end

	local payload = getSaveSlotPayload(player)
	local slot = payload and payload.Slots and payload.Slots[slotId]

	if not slot then
		local stats = playerLives[player.UserId]
		if stats then
			fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ SAVE SLOT ]</b></font> Invalid slot.")
		end
		return
	end

	if slot.Locked then
		local stats = playerLives[player.UserId]
		if stats then
			fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ SAVE SLOT ]</b></font> That slot is locked.")
		end
		return
	end

	if slot.Exists == true then
		local stats = playerLives[player.UserId]
		if stats then
			fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ SAVE SLOT ]</b></font> That slot already has a life.")
		end
		return
	end

	local currentStats = playerLives[player.UserId]
	if currentStats then
		forceSaveStats(player, "BeforeCreateSaveSlot")
	end

	BitKaisenSaveSystem.SetSelectedSlot(player, slotId, ownsSaveSlotAccess(player))
	clearPendingPlayerState(player)
	startNewLife(player)

	local newStats = playerLives[player.UserId]
	if newStats then
		newStats.__SlotId = slotId
		forceSaveStats(player, "CreateSaveSlot")
		fireMajorPopup(
			player,
			"SAVE SLOT CREATED",
			"A new life has started in Slot " .. tostring(slotId) .. ".",
			tostring(newStats.Name or "Unknown"),
			"Your other slots are still saved."
		)
	end
end

function deleteSaveSlotLife(player, slotId)
	if not checkRateLimit(player, "DeleteSaveSlot") then
		return
	end

	slotId = tonumber(slotId)

	if not slotId then
		return
	end

	local currentStats = playerLives[player.UserId]
	local currentSlot = currentStats and tonumber(currentStats.__SlotId)

	if currentStats and currentSlot ~= slotId then
		forceSaveStats(player, "BeforeDeleteSaveSlot")
	end

	local ok, errorMessage = BitKaisenSaveSystem.DeleteSlot(player, slotId, ownsSaveSlotAccess(player))

	if not ok then
		if currentStats then
			fireLifeUpdate(player, currentStats, "<font color='#e53935'><b>[ SAVE SLOT ]</b></font> " .. tostring(errorMessage or "Could not delete slot."))
		end

		return
	end

	clearPendingPlayerState(player)

	local selectedSlot = BitKaisenSaveSystem.GetSelectedSlot(player)
	local loaded = BitKaisenSaveSystem.LoadSlot(player, selectedSlot)

	if loaded then
		ensureExtraStats(loaded)
		BitKaisenRelationships.SanitizeOnLoad(loaded)
		BitKaisenAssets.SanitizeOnLoad(loaded)

		playerLives[player.UserId] = loaded

		fireLifeUpdate(
			player,
			loaded,
			"<font color='#a782ff'><b>[ SAVE SLOT ]</b></font> Deleted Slot " .. tostring(slotId) .. ".\nLoaded Slot " .. tostring(selectedSlot) .. ".",
			true
		)

		saveStats(player)
	else
		playerLives[player.UserId] = nil
		BitKaisenSaveSystem.SetSelectedSlot(player, selectedSlot, ownsSaveSlotAccess(player))
		startNewLife(player)

		local newStats = playerLives[player.UserId]
		if newStats then
			fireLifeUpdate(
				player,
				newStats,
				"<font color='#a782ff'><b>[ SAVE SLOT ]</b></font> Deleted Slot " .. tostring(slotId) .. ".\nA fresh life was created because no other slots existed.",
				true
			)
		end
	end
end


function forceAwaken(player, stats, reasonText)
	if not stats or stats.CursedTechnique ~= "None" then
		return nil
	end

	local awakened, technique = BitKaisenStats.AwakenNormalTechnique(stats)
	if not awakened then
		return nil
	end

	fireMajorPopup(
		player,
		"CURSED TECHNIQUE AWAKENED",
		reasonText or "Your cursed energy finally took shape.",
		technique,
		"The world of curses can no longer ignore you."
	)

	return technique
end

function calculatePlayerPower(stats)
	local power = 0

	power += (stats.CursedEnergy or 0) * 0.85
	power += (stats.Smarts or 0) * 0.45
	power += math.random(1, 25)

	if stats.HeavenlyRestricted then
		power += 35
	end

	if stats.CursedTechnique and stats.CursedTechnique ~= "None" then
		power += 35
		power += (stats.TechniqueMastery or 0) * 0.55
	end

	if stats.InJujutsuHigh then
		power += 15
	end

	local origin = stats.Origin or stats.Clan or "Minor Sorcerer Family"

	if origin == "Gojo Clan" then
		power += 20
	elseif origin == "Zenin Clan" then
		power += 12
	elseif origin == "Kamo Clan" then
		power += 12
	elseif origin == "Cursed Womb" then
		power += 18
	elseif origin == "Branch Sorcerer Family" then
		power += 10
	elseif origin == "Unknown Family" then
		power += 8
	elseif origin == "Fallen Sorcerer Family" then
		power += 7
	elseif origin == "Minor Sorcerer Family" then
		power += 6
	end


	if ownsAssetById(stats, "grand_dojo") then
		local decay = stats.ClanFounded and math.random(2, 5) or math.random(1, 3)
		adjustDojoCondition(stats, -decay)

		if stats.ClanFounded then
			local wardProgressMessages = {}

			for _, relationship in ipairs(stats.Relationships or {}) do
				if relationship.Alive ~= false and relationship.Role == "Ward" then
					relationship.Bond = math.clamp((relationship.Bond or 0) + math.random(1, 3), 0, 100)
					relationship.Trust = math.clamp((relationship.Trust or 0) + math.random(1, 3), 0, 100)
					relationship.CursedEnergy = math.max(0, (relationship.CursedEnergy or 0) + math.random(1, 5) + math.floor((stats.DojoLevel or 1) / 2))

					if (relationship.Age or 0) >= 8 and (relationship.CursedEnergy or 0) >= 35 then
						relationship.Role = "Student"
						relationship.Status = "Dojo Student"
						relationship.IsClanStudent = true
						relationship.Background = tostring(relationship.Background or "") .. " They eventually became an official student of your dojo."
						table.insert(wardProgressMessages, relationship.Name .. " became an official dojo student.")
					end
				elseif relationship.Alive ~= false and relationship.Role == "Student" and relationship.IsClanStudent then
					relationship.CursedEnergy = math.max(0, (relationship.CursedEnergy or 0) + math.random(1, 4))
					if relationship.Grade == "Non-Sorcerer" and (relationship.CursedEnergy or 0) >= 35 and math.random(1, 100) <= 20 then
						relationship.Grade = "Grade 4"
						table.insert(wardProgressMessages, relationship.Name .. " was recognized as Grade 4.")
					end
				end
			end

			-- Dojo student progress messages are handled by age-up logs, not mission power calculation.
			-- calculatePlayerPower can run during missions, so it must not concatenate to logMessage here.
			if #wardProgressMessages > 0 then
				-- intentionally no-op
			end
		end
	end

	local assetBonuses = BitKaisenAssets.GetPassiveBonuses(stats)
	power += assetBonuses.MissionPowerBonus or 0
	power += assetBonuses.ReputationBonus or 0

	if stats.ClanFounded then
		power += math.floor((stats.ClanReputation or 0) / 2)
	end

	local smartsMultiplier = 1 + ((stats.Smarts or 0) / 250)
	power = power * smartsMultiplier

	return power
end

function getLifeEventRollChance(stats)
	-- BitLife-style pacing: childhood should still feel alive.
	-- Before this patch, kids could get mostly quiet-year text because real events were only appended sometimes.
	local age = tonumber(stats and stats.Age) or 0

	if age <= 3 then
		return 70
	elseif age <= 7 then
		return 90
	elseif age <= 12 then
		return 95
	elseif age <= 19 then
		return 95
	end

	return 88
end





function hasTechnique(stats)
	if not stats then
		return false
	end

	local cursedTechnique = tostring(stats.CursedTechnique or "None")
	local innateTechnique = tostring(stats.InnateTechnique or "None")

	return cursedTechnique ~= "None" or innateTechnique ~= "None" or stats.TechniqueKnown == true or stats.TechniqueAwakened == true or stats.TechniqueUsable == true
end

function isSorcerer(stats)
	return isOfficialJujutsuSorcerer(stats)
end


----------------------------------------------------------------
-- BINDING VOW SYSTEM
-- Vows are handled by a real menu/button, not random life scenarios.
----------------------------------------------------------------

do

	local BINDING_VOWS = {
		{
			Id = "vow_of_pain",
			Name = "Vow of Pain",
			RequirementText = "Age 16+ and at least some cursed energy.",
			Description = "You accept harsher physical backlash in exchange for sharper cursed energy growth.",
			CostText = "-10 Health now. Future overuse should be treated as more dangerous.",
			BonusText = "+14 Cursed Energy and +3 Technique Mastery now.",
			MinAge = 16,
			RequiresCursedEnergy = 25,
			Effects = { Health = -10, CursedEnergy = 14, TechniqueMastery = 3 }
		},
		{
			Id = "vow_of_silence",
			Name = "Vow of Silence",
			RequirementText = "Age 16+ and an awakened or known technique.",
			Description = "You restrict how openly you speak about your technique to sharpen focus and control.",
			CostText = "-6 Happiness now. Your social life becomes colder.",
			BonusText = "+5 Technique Mastery and +3 Smarts now.",
			MinAge = 16,
			RequiresTechnique = true,
			Effects = { Happiness = -6, TechniqueMastery = 5, Smarts = 3 }
		},
		{
			Id = "vow_of_poverty",
			Name = "Vow of Poverty",
			RequirementText = "Age 16+.",
			Description = "You limit your attachment to money and comfort to deepen discipline.",
			CostText = "Lose 35% of current money.",
			BonusText = "+10 Cursed Energy, +4 Smarts, and +2 Reputation now.",
			MinAge = 16,
			Effects = { CursedEnergy = 10, Smarts = 4, Reputation = 2 },
			MoneyPercentCost = 0.35
		},
		{
			Id = "vow_of_risk",
			Name = "Vow of Risk",
			RequirementText = "Age 16+ and Sorcerer status.",
			Description = "You accept worse consequences when you fail in exchange for sharper battle growth.",
			CostText = "-8 Happiness and -5 Health now.",
			BonusText = "+8 Cursed Energy, +3 Reputation, and +2 Technique Mastery now.",
			MinAge = 16,
			RequiresSorcerer = true,
			Effects = { Happiness = -8, Health = -5, CursedEnergy = 8, Reputation = 3, TechniqueMastery = 2 }
		},
		{
			Id = "vow_of_restraint",
			Name = "Vow of Restraint",
			RequirementText = "Age 16+ and a cursed technique.",
			Description = "You hold your technique back unless it truly matters, forcing cleaner control.",
			CostText = "-4 Happiness and -4 Reputation now.",
			BonusText = "+7 Technique Mastery and +4 Smarts now.",
			MinAge = 16,
			RequiresTechnique = true,
			Effects = { Happiness = -4, Reputation = -4, TechniqueMastery = 7, Smarts = 4 }
		},
		{
			Id = "vow_of_bloodline",
			Name = "Vow of Bloodline",
			RequirementText = "Age 20+.",
			Description = "You bind part of your life to your future legacy, strengthening the idea of inheritance.",
			CostText = "-12 Health and -8 Happiness now.",
			BonusText = "+8 Reputation, +6 Cursed Energy, and +3 Clan Reputation now.",
			MinAge = 20,
			Effects = { Health = -12, Happiness = -8, Reputation = 8, CursedEnergy = 6, ClanReputation = 3 }
		}
	}

	function getBindingVowById(vowId)
		for _, vow in ipairs(BINDING_VOWS) do
			if vow.Id == vowId then
				return vow
			end
		end

		return nil
	end

	function normalizeActiveVows(stats)
		stats.ActiveVows = stats.ActiveVows or {}

		local normalized = {}
		local seen = {}

		for _, vowValue in ipairs(stats.ActiveVows) do
			local vowId = nil

			if typeof(vowValue) == "table" then
				vowId = vowValue.Id
			else
				vowId = tostring(vowValue)
			end

			-- Migration support for the two old scenario-based vow names.
			if vowId == "Vow of Pain" then
				vowId = "vow_of_pain"
			elseif vowId == "Vow of Silence" then
				vowId = "vow_of_silence"
			end

			if vowId and not seen[vowId] then
				seen[vowId] = true
				table.insert(normalized, vowId)
			end
		end

		stats.ActiveVows = normalized
		return normalized
	end

	function playerHasBindingVow(stats, vowId)
		local activeVows = normalizeActiveVows(stats)

		for _, activeVowId in ipairs(activeVows) do
			if activeVowId == vowId then
				return true
			end
		end

		return false
	end

	function canMakeBindingVow(stats, vow)
		if not stats or not vow then
			return false, "Missing vow data."
		end

		local age = tonumber(stats.Age) or 0

		if vow.MinAge and age < vow.MinAge then
			return false, "You are too young for this vow."
		end

		if vow.RequiresTechnique and not hasTechnique(stats) then
			return false, "You need a cursed technique first."
		end

		if vow.RequiresSorcerer and not isSorcerer(stats) then
			return false, "You need sorcerer status first."
		end

		if vow.RequiresCursedEnergy and (tonumber(stats.CursedEnergy) or 0) < vow.RequiresCursedEnergy then
			return false, "Your cursed energy is too low."
		end

		if playerHasBindingVow(stats, vow.Id) then
			return false, "You already made this vow."
		end

		return true, "Available"
	end

	function applyBindingVowEffects(stats, vow)
		local effects = vow.Effects or {}

		if vow.MoneyPercentCost then
			local currentMoney = math.max(0, tonumber(stats.Money) or 0)
			stats.Money = math.max(0, currentMoney - math.floor(currentMoney * vow.MoneyPercentCost))
		end

		if effects.Health then
			stats.Health = math.clamp((tonumber(stats.Health) or 100) + effects.Health, 0, 100)
		end

		if effects.Happiness then
			stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) + effects.Happiness, 0, 100)
		end

		if effects.Smarts then
			stats.Smarts = math.clamp((tonumber(stats.Smarts) or 0) + effects.Smarts, 0, 100)
		end

		if effects.CursedEnergy then
			stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + effects.CursedEnergy)
		end

		if effects.TechniqueMastery then
			stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + effects.TechniqueMastery, 0, 100)
		end

		if effects.Reputation then
			stats.Reputation = (tonumber(stats.Reputation) or 0) + effects.Reputation
		end

		if effects.ClanReputation then
			stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) + effects.ClanReputation)
		end
	end

	function buildBindingVowPayload(stats)
		ensureExtraStats(stats)
		normalizeActiveVows(stats)

		local payload = {
			ActiveVows = stats.ActiveVows,
			Vows = {}
		}

		for _, vow in ipairs(BINDING_VOWS) do
			local canMake, reason = canMakeBindingVow(stats, vow)

			table.insert(payload.Vows, {
				Id = vow.Id,
				Name = vow.Name,
				Description = vow.Description,
				RequirementText = vow.RequirementText,
				CostText = vow.CostText,
				BonusText = vow.BonusText,
				Owned = playerHasBindingVow(stats, vow.Id),
				CanMake = canMake,
				Reason = reason
			})
		end

		return payload
	end

	function makeBindingVow(player, vowId)
		local stats = playerLives[player.UserId]

		if not stats or not stats.Alive then
			return false, "You do not have an active life."
		end

		ensureExtraStats(stats)

		local vow = getBindingVowById(vowId)
		if not vow then
			return false, "Unknown Binding Vow."
		end

		local canMake, reason = canMakeBindingVow(stats, vow)
		if not canMake then
			return false, reason
		end

		applyBindingVowEffects(stats, vow)

		stats.ActiveVows = normalizeActiveVows(stats)
		table.insert(stats.ActiveVows, vow.Id)

		stats.BindingVowHistory = stats.BindingVowHistory or {}
		table.insert(stats.BindingVowHistory, {
			Id = vow.Id,
			Name = vow.Name,
			Age = stats.Age,
			Month = stats.CurrentMonth
		})

		local logMessage = "<font color='#ffcd69'><b>[ BINDING VOW ]</b></font> You made the <b>" .. vow.Name .. "</b>. " .. vow.CostText .. " " .. vow.BonusText
		fireLifeUpdate(player, stats, logMessage)

		saveStats(player)

		return true, "You made the " .. vow.Name .. "."
	end



	getBindingVows.OnServerInvoke = function(player)
		local stats = playerLives[player.UserId]

		if not stats then
			return {
				ActiveVows = {},
				Vows = {}
			}
		end

		return buildBindingVowPayload(stats)
	end

	bindingVowAction.OnServerEvent:Connect(function(player, actionId, vowId)
		if not checkRateLimit(player, "BindingVowAction") then
			return
		end

		if actionId ~= "MakeVow" then
			return
		end

		if typeof(vowId) ~= "string" then
			return
		end

		local ok, message = makeBindingVow(player, vowId)

		bindingVowAction:FireClient(player, {
			Success = ok == true,
			Message = message or "",
			Data = playerLives[player.UserId] and buildBindingVowPayload(playerLives[player.UserId]) or nil
		})
	end)

end

----------------------------------------------------------------
-- BITLIFE-STYLE RANDOM LIFE SCENARIOS
-- These use ShowMissionSituation so the player gets actual choices,
-- not just a one-button MajorPopup.
----------------------------------------------------------------

local RANDOM_LIFE_SCENARIOS = {
	{
		Id = "child_shadow_corner_choice",
		Title = "Something in the Corner",
		Body = "Late at night, you wake up and see something crouched in the corner of your room. It is not moving, but you know it is looking at you.",
		MinAge = 4,
		MaxAge = 10,
		Weight = 10,
		Options = {
			{ Text = "Hide under the blanket", Description = "You hid until morning. Nothing touched you, but you remembered the shape for years.", Effects = { Happiness = -4, CursedEnergy = 1 } },
			{ Text = "Call for family", Description = "Someone came running. The thing was gone, but your family believed you more than they admitted.", Effects = { Happiness = 2, Smarts = 1 } },
			{ Text = "Stare back at it", Description = "You stared until it crawled away. Something in your cursed energy stirred for the first time.", Effects = { Happiness = -3, CursedEnergy = 5, Smarts = 1 } },
		}
	},
	{
		Id = "child_school_ceiling",
		Title = "The Ceiling Thing",
		Body = "During class, something thin and twisted crawls across the ceiling. Nobody else reacts. It pauses directly above your desk.",
		MinAge = 6,
		MaxAge = 12,
		Weight = 10,
		Options = {
			{ Text = "Ignore it", Description = "You forced yourself to look down. The rest of class felt endless, but you did not panic.", Effects = { Smarts = 2, Happiness = -2 } },
			{ Text = "Tell the teacher", Description = "The teacher thought you were trying to interrupt class. You got embarrassed, but at least the thing left.", Effects = { Happiness = -3, Smarts = 1 } },
			{ Text = "Track where it goes", Description = "You watched it crawl into the vents and learned that curses like places people fear quietly.", Effects = { Smarts = 4, CursedEnergy = 2, Happiness = -2 } },
		}
	},
	{
		Id = "child_strange_shrine",
		Title = "Old Roadside Shrine",
		Body = "On the way home, you find a small roadside shrine covered in old paper charms. One charm falls as you pass by.",
		MinAge = 5,
		MaxAge = 13,
		Weight = 8,
		Options = {
			{ Text = "Put the charm back", Description = "You placed it back carefully. The air felt lighter afterward.", Effects = { Happiness = 2, CursedEnergy = 2 } },
			{ Text = "Take it home", Description = "You kept the charm. That night, your dreams were filled with whispering voices.", Effects = { CursedEnergy = 6, Happiness = -5 } },
			{ Text = "Run away", Description = "You ran and did not look back. Sometimes being careful is the smartest answer.", Effects = { Smarts = 3, Happiness = -1 } },
		}
	},
	{
		Id = "child_family_truth",
		Title = "Family Secret",
		Body = "You overhear adults in your family arguing about whether you are ready to know the truth about curses.",
		MinAge = 7,
		MaxAge = 14,
		Weight = 9,
		Options = {
			{ Text = "Keep listening", Description = "You stayed quiet and learned more than they wanted you to know.", Effects = { Smarts = 5, Happiness = -2 } },
			{ Text = "Walk in and ask", Description = "The room went silent. They gave you a careful answer, but not the whole truth.", Effects = { Smarts = 3, Happiness = 1 } },
			{ Text = "Pretend you heard nothing", Description = "You pretended not to know. The secret stayed heavy in the house.", Effects = { Happiness = -1, Smarts = 1 } },
		}
	},
	{
		Id = "child_bully_and_curse",
		Title = "The Bully's Shadow",
		Body = "A kid who bothers you at school has a small curse clinging to their back. They do not know it is there.",
		MinAge = 8,
		MaxAge = 14,
		Weight = 8,
		Options = {
			{ Text = "Warn them", Description = "They laughed at you, but the curse loosened when they became scared.", Effects = { Happiness = -1, Reputation = 1, CursedEnergy = 2 } },
			{ Text = "Say nothing", Description = "You left it alone. The curse disappeared days later, but you wondered what happened.", Effects = { Smarts = 1, Happiness = -3 } },
			{ Text = "Scare the curse away", Description = "You focused on the curse until it noticed you. It fled, and the bully avoided you after that.", Effects = { CursedEnergy = 5, Reputation = 2, Happiness = 1 } },
		}
	},
	{
		Id = "teen_first_mission_offer",
		Title = "Unofficial Errand",
		Body = "An older sorcerer offers you a small unofficial errand: check a building with weak cursed energy and report back.",
		MinAge = 13,
		MaxAge = 18,
		Weight = 8,
		RequiresSorcerer = true,
		Options = {
			{ Text = "Accept", Description = "You checked the building and came back shaken but useful. The sorcerer respected your nerve.", Effects = { Reputation = 3, CursedEnergy = 3, Health = -2 } },
			{ Text = "Refuse", Description = "You refused the errand. It was probably smarter, but you hated feeling untested.", Effects = { Smarts = 2, Happiness = -1 } },
			{ Text = "Ask for details first", Description = "You asked enough questions to realize the errand was riskier than they said.", Effects = { Smarts = 5, Reputation = 1 } },
		}
	},
	{
		Id = "teen_technique_pressure",
		Title = "Pressure Test",
		Body = "Someone pressures you to show your cursed technique in front of others. Everyone is watching.",
		MinAge = 10,
		MaxAge = 19,
		Weight = 7,
		RequiresTechnique = true,
		Options = {
			{ Text = "Show a little", Description = "You revealed just enough to shut them up without exposing everything.", Effects = { Reputation = 3, TechniqueMastery = 2, CursedEnergy = -3 } },
			{ Text = "Refuse", Description = "You refused to perform on command. Some people called it fear. Others called it control.", Effects = { Smarts = 3, Happiness = -1 } },
			{ Text = "Overdo it", Description = "You showed too much and felt your control slip. People were impressed, but your body paid for it.", Effects = { Reputation = 5, Health = -6, TechniqueMastery = 1 } },
		}
	},
	{
		Id = "teen_rival_insult",
		Title = "A Rival's Mouth",
		Body = "A rival insults your family name and calls your cursed energy unimpressive.",
		MinAge = 12,
		MaxAge = 22,
		Weight = 8,
		Options = {
			{ Text = "Ignore them", Description = "You walked away. It bothered you less than they wanted it to.", Effects = { Smarts = 2, Happiness = 1 } },
			{ Text = "Talk back", Description = "You answered cleanly and made them look childish. People noticed.", Effects = { Reputation = 3, Happiness = 1 } },
			{ Text = "Challenge them", Description = "You challenged them to spar. Win or lose, they learned you were not soft.", Effects = { Reputation = 4, Health = -3, CursedEnergy = 2 } },
		}
	},
	{
		Id = "teen_black_flash_rumor",
		Title = "Black Flash Rumor",
		Body = "You hear older students talking about Black Flash. One says chasing it is stupid. Another says it changes everything.",
		MinAge = 14,
		MaxAge = 22,
		Weight = 5,
		RequiresSorcerer = true,
		Options = {
			{ Text = "Study the theory", Description = "You studied timing and cursed energy delay. It was hard, but useful.", Effects = { Smarts = 4, CursedEnergy = 2 } },
			{ Text = "Try to force it", Description = "You tried to force the timing and hurt yourself. At least you learned why people warn against it.", Effects = { Health = -8, CursedEnergy = 5, Happiness = -2 } },
			{ Text = "Ask a teacher", Description = "A teacher explained that Black Flash is not a button. That answer annoyed you because it was true.", Effects = { Smarts = 5, Happiness = -1 } },
		}
	},
	{
		Id = "adult_cursed_object_deal",
		Title = "Back-Alley Cursed Object",
		Body = "A shady seller offers you a wrapped cursed object for cheap. The energy coming from it is real.",
		MinAge = 16,
		MaxAge = 70,
		Weight = 5,
		RequiresSorcerer = true,
		Options = {
			{ Text = "Buy it", Description = "You bought it. The object was dangerous, but studying it taught you something.", Effects = { Money = -500, Smarts = 4, CursedEnergy = 5, Happiness = -2 } },
			{ Text = "Report the seller", Description = "You reported the seller and gained a little credibility for not being reckless.", Effects = { Reputation = 4, Smarts = 2 } },
			{ Text = "Walk away", Description = "You walked away. Some deals are bait with a price tag.", Effects = { Smarts = 2, Happiness = 1 } },
		}
	},
	{
		Id = "adult_civilian_cameras",
		Title = "Phones Are Recording",
		Body = "A curse incident happens in public. Civilians are recording, and your face might be in the footage.",
		MinAge = 16,
		MaxAge = 80,
		Weight = 6,
		RequiresSorcerer = true,
		Options = {
			{ Text = "Destroy the phones", Description = "You destroyed the recordings. The cleanup worked, but people complained loudly.", Effects = { Reputation = -2, Happiness = -1 } },
			{ Text = "Hide your face", Description = "You focused on staying unseen while handling the problem. It was not clean, but it worked.", Effects = { Smarts = 3, Reputation = 1 } },
			{ Text = "Finish fast", Description = "You ignored the cameras and ended the incident quickly. The footage became rumor before officials buried it.", Effects = { Reputation = 4, CursedEnergy = -4 } },
		}
	},
	{
		Id = "dojo_student_conflict",
		Title = "Student Conflict",
		Body = "Two dojo students argue during training. One claims the other is too weak to carry your clan name.",
		MinAge = 25,
		MaxAge = 120,
		Weight = 6,
		RequiresDojo = true,
		Options = {
			{ Text = "Discipline both", Description = "You disciplined both students and reminded the dojo that arrogance is not strength.", Effects = { ClanReputation = 2, DojoPrestige = 1 } },
			{ Text = "Let them spar", Description = "You let them settle it with supervision. They learned, but the room got damaged.", Effects = { ClanReputation = 3, DojoCondition = -6, Happiness = -1 } },
			{ Text = "Speak privately", Description = "You handled the conflict quietly and earned respect for not making a show of it.", Effects = { Smarts = 3, ClanReputation = 1, Happiness = 1 } },
		}
	},
	{
		Id = "elder_successor_question",
		Title = "Question of Legacy",
		Body = "A younger sorcerer asks what kind of person should carry your teachings after you are gone.",
		MinAge = 45,
		MaxAge = 120,
		Weight = 5,
		Options = {
			{ Text = "Say the strongest", Description = "You told them strength is the only language the cursed world respects.", Effects = { Reputation = 3, Happiness = -1 } },
			{ Text = "Say the kindest", Description = "You told them power without humanity only creates another curse.", Effects = { Happiness = 3, Reputation = 1 } },
			{ Text = "Say the one who survives", Description = "You told them survival is the first lesson and the last test.", Effects = { Smarts = 4, Reputation = 2 } },
		}
	},
}


----------------------------------------------------------------
-- UNREGISTERED / CIVILIAN / PRIVATE SCENARIO EXPANSION
-- These are allowed before Jujutsu High because they are not official missions.
-- They give age 13-25 way more variety without letting random people act like registered sorcerers.
----------------------------------------------------------------

function registerUnregisteredLifeScenarios()
	local UNREGISTERED_SCENARIOS = {
		{
			Id = "unregistered_school_rumor",
			Title = "School Rumor",
			Body = "People at school start whispering about you after something strange happened nearby.",
			MinAge = 13,
			MaxAge = 20,
			Weight = 9,
			Options = {
				{ Text = "Deny it", Description = "You denied everything cleanly. Most people moved on.", Effects = { Happiness = 1, Smarts = 2 } },
				{ Text = "Stay quiet", Description = "You stayed quiet, which somehow made the rumor stronger.", Effects = { Happiness = -2, Reputation = 1 } },
				{ Text = "Scare them off", Description = "You made it clear they should stop talking. It worked, but people watched you more carefully.", Effects = { Reputation = 2, Happiness = -1 } },
			}
		},
		{
			Id = "unregistered_private_training",
			Title = "Private Training Spot",
			Body = "You find a quiet place where nobody can interrupt your cursed energy practice.",
			MinAge = 10,
			MaxAge = 28,
			Weight = 10,
			Options = {
				{ Text = "Train control", Description = "You focused on control instead of power. The progress was small but real.", Effects = { CursedEnergy = 3, Smarts = 2, TechniqueMastery = 1 } },
				{ Text = "Push output", Description = "You pushed your cursed energy harder than usual and left exhausted.", Effects = { CursedEnergy = 5, Health = -3 } },
				{ Text = "Practice safely", Description = "You kept the session basic and avoided drawing attention.", Effects = { Smarts = 3, Happiness = 1 } },
			}
		},
		{
			Id = "unregistered_family_warning",
			Title = "Family Warning",
			Body = "Someone in your family warns you not to show your cursed energy in public.",
			MinAge = 8,
			MaxAge = 25,
			Weight = 8,
			Options = {
				{ Text = "Listen", Description = "You listened. They sounded paranoid, but they were probably right.", Effects = { Smarts = 3, Happiness = 1 } },
				{ Text = "Argue", Description = "You argued with them and made the house tense for a while.", Effects = { Happiness = -3, CursedEnergy = 1 } },
				{ Text = "Ask why", Description = "You asked why, and they gave you a half-answer about old sorcerer politics.", Effects = { Smarts = 4, Happiness = -1 } },
			}
		},
		{
			Id = "unregistered_back_alley_sense",
			Title = "Back Alley Pressure",
			Body = "While walking home, you feel cursed energy leaking from a narrow alley.",
			MinAge = 10,
			MaxAge = 30,
			Weight = 8,
			Options = {
				{ Text = "Keep walking", Description = "You kept walking. Curiosity is not worth dying over.", Effects = { Smarts = 2, Happiness = 1 } },
				{ Text = "Peek inside", Description = "You peeked inside and saw a weak curse crawl deeper into the dark.", Effects = { CursedEnergy = 2, Happiness = -2 } },
				{ Text = "Mark the spot", Description = "You marked the location mentally in case it mattered later.", Effects = { Smarts = 3, Reputation = 1 } },
			}
		},
		{
			Id = "unregistered_old_shrine",
			Title = "Old Shrine",
			Body = "An old shrine near your neighborhood feels different today. The air around it is heavy.",
			MinAge = 8,
			MaxAge = 35,
			Weight = 8,
			Options = {
				{ Text = "Pay respects", Description = "You paid respects and the pressure softened slightly.", Effects = { Happiness = 2, CursedEnergy = 1 } },
				{ Text = "Study the feeling", Description = "You studied the feeling and noticed how the cursed energy moved.", Effects = { Smarts = 4, CursedEnergy = 2 } },
				{ Text = "Leave fast", Description = "You left fast. Whatever was there did not follow.", Effects = { Happiness = 1, Smarts = 1 } },
			}
		},
		{
			Id = "unregistered_classmate_questions",
			Title = "Too Many Questions",
			Body = "A classmate keeps asking why weird things happen around you.",
			MinAge = 12,
			MaxAge = 20,
			Weight = 8,
			Options = {
				{ Text = "Laugh it off", Description = "You laughed it off and changed the subject.", Effects = { Happiness = 1, Smarts = 2 } },
				{ Text = "Tell a fake story", Description = "You made up a story convincing enough to shut them up.", Effects = { Smarts = 3 } },
				{ Text = "Get annoyed", Description = "You got annoyed. They stopped asking, but now they think you are hiding something.", Effects = { Reputation = 1, Happiness = -2 } },
			}
		},
		{
			Id = "unregistered_technique_slip",
			Title = "Technique Slip",
			Body = "Your cursed technique almost shows itself while you are around normal people.",
			MinAge = 10,
			MaxAge = 28,
			Weight = 7,
			RequiresTechnique = true,
			Options = {
				{ Text = "Suppress it", Description = "You suppressed it just in time. Nobody noticed.", Effects = { TechniqueMastery = 2, Smarts = 2, Happiness = -1 } },
				{ Text = "Leave quickly", Description = "You left before anything worse could happen.", Effects = { Happiness = -1, Smarts = 2 } },
				{ Text = "Pretend it was nothing", Description = "You played it off. A few people looked confused, but it passed.", Effects = { Reputation = 1, Smarts = 1 } },
			}
		},
		{
			Id = "unregistered_dream_training",
			Title = "Dream Training",
			Body = "You dream about using cursed energy in a place that does not feel fully real.",
			MinAge = 6,
			MaxAge = 30,
			Weight = 7,
			Options = {
				{ Text = "Remember the pattern", Description = "You woke up remembering a strange cursed energy pattern.", Effects = { Smarts = 3, CursedEnergy = 2 } },
				{ Text = "Force yourself awake", Description = "You forced yourself awake before the dream got worse.", Effects = { Happiness = -1, Health = 1 } },
				{ Text = "Follow the dream", Description = "You followed the dream and woke up exhausted but sharper.", Effects = { CursedEnergy = 4, Health = -2 } },
			}
		},
		{
			Id = "unregistered_neighbor_problem",
			Title = "Neighbor's Complaint",
			Body = "A neighbor complains about hearing scratching at night. You can feel cursed energy around their door.",
			MinAge = 12,
			MaxAge = 35,
			Weight = 7,
			Options = {
				{ Text = "Tell them to leave", Description = "You warned them to stay somewhere else for the night.", Effects = { Reputation = 1, Happiness = 1 } },
				{ Text = "Check the door", Description = "You checked the door and found claw marks that faded when touched.", Effects = { Smarts = 3, Happiness = -1 } },
				{ Text = "Ignore it", Description = "You ignored it. The scratching stopped eventually, but you felt bad.", Effects = { Happiness = -3 } },
			}
		},
		{
			Id = "unregistered_public_bus",
			Title = "Bus Ride",
			Body = "On a bus ride, everyone suddenly gets quiet at the same time. You sense cursed energy near the back seat.",
			MinAge = 12,
			MaxAge = 35,
			Weight = 7,
			Options = {
				{ Text = "Change seats", Description = "You changed seats and kept watching. The pressure faded after a few stops.", Effects = { Smarts = 2, Happiness = 1 } },
				{ Text = "Get off early", Description = "You got off early. Something watched from the back window as the bus left.", Effects = { Happiness = -1, Smarts = 2 } },
				{ Text = "Stare back", Description = "You stared back until the cursed energy shifted away from you.", Effects = { CursedEnergy = 2, Reputation = 1 } },
			}
		},
		{
			Id = "unregistered_exam_day",
			Title = "Exam Day",
			Body = "You have an important exam, but cursed energy keeps distracting you during the test.",
			MinAge = 12,
			MaxAge = 20,
			Weight = 8,
			Options = {
				{ Text = "Focus hard", Description = "You forced yourself to focus and finished the exam properly.", Effects = { Smarts = 4, Happiness = 1 } },
				{ Text = "Rush it", Description = "You rushed the exam just to leave the room faster.", Effects = { Smarts = -1, Happiness = -1, CursedEnergy = 1 } },
				{ Text = "Track the energy", Description = "You tracked the cursed energy instead of the questions. Not great academically, useful spiritually.", Effects = { CursedEnergy = 3, Smarts = 1 } },
			}
		},
		{
			Id = "unregistered_after_school_rain",
			Title = "After-School Rain",
			Body = "Rain starts falling after school, but only around the path you usually take home.",
			MinAge = 12,
			MaxAge = 22,
			Weight = 7,
			Options = {
				{ Text = "Take another route", Description = "You took another route and avoided whatever was waiting.", Effects = { Smarts = 3, Happiness = 1 } },
				{ Text = "Walk through it", Description = "You walked through it and felt cursed energy cling to your clothes.", Effects = { CursedEnergy = 3, Health = -2, Happiness = -1 } },
				{ Text = "Wait it out", Description = "You waited until the strange rain stopped.", Effects = { Happiness = 1, Smarts = 1 } },
			}
		},
		{
			Id = "unregistered_teacher_notice",
			Title = "Teacher Notices",
			Body = "A teacher notices you reacting to things nobody else can see.",
			MinAge = 8,
			MaxAge = 20,
			Weight = 7,
			Options = {
				{ Text = "Act normal", Description = "You acted normal well enough to avoid questions.", Effects = { Smarts = 2, Happiness = 1 } },
				{ Text = "Say you're tired", Description = "You blamed it on being tired. It worked, barely.", Effects = { Happiness = -1 } },
				{ Text = "Ask to leave", Description = "You asked to leave before you lost control of your expression.", Effects = { Happiness = -2, CursedEnergy = 1 } },
			}
		},
		{
			Id = "unregistered_family_document",
			Title = "Old Family Document",
			Body = "You find an old document with your family name and a few references to cursed energy.",
			MinAge = 10,
			MaxAge = 30,
			Weight = 6,
			Options = {
				{ Text = "Read it fully", Description = "You read it carefully and learned more about your family's history.", Effects = { Smarts = 5, Happiness = -1 } },
				{ Text = "Hide it", Description = "You hid it before anyone knew you found it.", Effects = { Smarts = 2, Happiness = -1 } },
				{ Text = "Ask about it", Description = "You asked about it and immediately made the room uncomfortable.", Effects = { Smarts = 3, Happiness = -2 } },
			}
		},
		{
			Id = "unregistered_minor_bully",
			Title = "Someone Tests You",
			Body = "Someone at school tries to embarrass you in front of other people.",
			MinAge = 10,
			MaxAge = 20,
			Weight = 8,
			Options = {
				{ Text = "Ignore them", Description = "You ignored them. It looked boring, which made them look worse.", Effects = { Happiness = 1, Smarts = 2 } },
				{ Text = "Answer sharply", Description = "You answered cleanly and made them look childish. People noticed.", Effects = { Reputation = 2, Happiness = 1 } },
				{ Text = "Threaten them quietly", Description = "You said just enough to shut them up without exposing anything.", Effects = { Reputation = 2, Happiness = -1 } },
			}
		},
		{
			Id = "unregistered_small_job",
			Title = "Small Job",
			Body = "You get offered a small normal job that has nothing to do with curses.",
			MinAge = 15,
			MaxAge = 30,
			Weight = 7,
			Options = {
				{ Text = "Take it", Description = "You took the job and earned some money.", Effects = { Money = 350, Happiness = 1 } },
				{ Text = "Decline", Description = "You declined. You had enough weird things to deal with.", Effects = { Happiness = 1 } },
				{ Text = "Use it as cover", Description = "You used the job as cover for why you were out late.", Effects = { Money = 200, Smarts = 2 } },
			}
		},
		{
			Id = "unregistered_technique_notes",
			Title = "Technique Notes",
			Body = "You start writing private notes about how your cursed technique behaves.",
			MinAge = 10,
			MaxAge = 35,
			Weight = 7,
			RequiresTechnique = true,
			Options = {
				{ Text = "Organize them", Description = "You organized the notes and understood your technique better.", Effects = { Smarts = 4, TechniqueMastery = 2 } },
				{ Text = "Burn them", Description = "You burned the notes so nobody could find them.", Effects = { Happiness = -1, Smarts = 1 } },
				{ Text = "Keep testing", Description = "You kept testing your limits and made progress.", Effects = { CursedEnergy = 3, TechniqueMastery = 2, Health = -1 } },
			}
		},
		{
			Id = "unregistered_private_spar",
			Title = "Private Spar",
			Body = "Someone your age challenges you to a private spar away from adults.",
			MinAge = 12,
			MaxAge = 25,
			Weight = 7,
			Options = {
				{ Text = "Accept", Description = "You accepted and learned from the pressure.", Effects = { CursedEnergy = 3, Health = -2, Reputation = 2 } },
				{ Text = "Refuse", Description = "You refused. Not every challenge deserves your time.", Effects = { Smarts = 2, Happiness = 1 } },
				{ Text = "Set rules", Description = "You set rules first. It kept the spar from getting stupid.", Effects = { Smarts = 3, Reputation = 1 } },
			}
		},
		{
			Id = "unregistered_eavesdrop",
			Title = "Overheard Conversation",
			Body = "You overhear two adults talking about unregistered sorcerers being watched.",
			MinAge = 12,
			MaxAge = 30,
			Weight = 6,
			Options = {
				{ Text = "Keep listening", Description = "You kept listening and learned just enough to get nervous.", Effects = { Smarts = 4, Happiness = -2 } },
				{ Text = "Leave", Description = "You left before they noticed you.", Effects = { Smarts = 1, Happiness = 1 } },
				{ Text = "Interrupt", Description = "You interrupted and they immediately stopped talking.", Effects = { Reputation = 1, Happiness = -1 } },
			}
		},
		{
			Id = "unregistered_control_failure",
			Title = "Control Failure",
			Body = "Your cursed energy spikes while you are stressed, and something nearby breaks.",
			MinAge = 10,
			MaxAge = 28,
			Weight = 6,
			Options = {
				{ Text = "Hide the damage", Description = "You hid the damage before anyone could connect it to you.", Effects = { Smarts = 3, Money = -100 } },
				{ Text = "Confess", Description = "You confessed to breaking it without explaining the real reason.", Effects = { Happiness = -1, Money = -150 } },
				{ Text = "Study what happened", Description = "You studied the accident and learned from it.", Effects = { CursedEnergy = 3, Smarts = 2, TechniqueMastery = 1 } },
			}
		},
		{
			Id = "unregistered_library_book",
			Title = "Wrong Book",
			Body = "At a library, a book about old folklore opens to a page describing something you have actually seen.",
			MinAge = 10,
			MaxAge = 35,
			Weight = 6,
			Options = {
				{ Text = "Read more", Description = "You read more and found useful hints hidden in superstition.", Effects = { Smarts = 5 } },
				{ Text = "Borrow it", Description = "You borrowed the book and studied it quietly.", Effects = { Smarts = 3, Happiness = 1 } },
				{ Text = "Leave it", Description = "You left it alone. Some knowledge feels like bait.", Effects = { Happiness = 1, Smarts = 1 } },
			}
		},
		{
			Id = "unregistered_childhood_friend",
			Title = "Old Friend",
			Body = "An old friend says you feel different now and asks if something happened.",
			MinAge = 13,
			MaxAge = 28,
			Weight = 6,
			Options = {
				{ Text = "Tell half the truth", Description = "You told half the truth. It was enough to keep the friendship alive.", Effects = { Happiness = 3, Smarts = 1 } },
				{ Text = "Lie", Description = "You lied smoothly, which somehow made you feel worse.", Effects = { Happiness = -2 } },
				{ Text = "Change the subject", Description = "You changed the subject and both of you pretended not to notice.", Effects = { Happiness = -1, Smarts = 1 } },
			}
		},
	}

	for _, scenario in ipairs(UNREGISTERED_SCENARIOS) do
		table.insert(RANDOM_LIFE_SCENARIOS, scenario)
	end
end

registerUnregisteredLifeScenarios()



----------------------------------------------------------------
-- CURSE USER SCENARIOS
----------------------------------------------------------------

function registerCurseUserLifeScenarios()
	local CURSE_USER_SCENARIOS = {
		{
			Id = "curse_user_shadow_offer",
			Title = "Shadow Offer",
			Body = "A shady contact says someone wants to pay for information about cursed objects.",
			MinAge = 13,
			MaxAge = 90,
			Weight = 8,
			RequiresCurseUser = true,
			Options = {
				{ Text = "Hear them out", Description = "You listened and learned how ugly the underground market really is.", Effects = { Money = 500, Smarts = 3, Reputation = 2 } },
				{ Text = "Refuse", Description = "You refused, but the offer proved people know what you are becoming.", Effects = { Happiness = -1, Smarts = 1 } },
				{ Text = "Use them", Description = "You gave them just enough to get paid without giving away your real hand.", Effects = { Money = 900, Smarts = 2, Happiness = -2 } },
			}
		},
		{
			Id = "curse_user_hidden_training",
			Title = "Hidden Training",
			Body = "You train somewhere isolated so no officials can track your cursed energy.",
			MinAge = 13,
			MaxAge = 90,
			Weight = 10,
			RequiresCurseUser = true,
			Options = {
				{ Text = "Train output", Description = "You pushed your cursed energy output higher and ignored the risk.", Effects = { CursedEnergy = 8, Health = -4 } },
				{ Text = "Train control", Description = "You refined your control quietly.", Effects = { Smarts = 3, TechniqueMastery = 3 } },
				{ Text = "Mask your energy", Description = "You practiced hiding your cursed energy from detection.", Effects = { Smarts = 5, Reputation = 1 } },
			}
		},
		{
			Id = "curse_user_blacklisted",
			Title = "Blacklisted Name",
			Body = "You hear that your name is being passed around as someone officials should watch.",
			MinAge = 13,
			MaxAge = 90,
			Weight = 7,
			RequiresCurseUser = true,
			Options = {
				{ Text = "Lay low", Description = "You stayed quiet and avoided unnecessary attention.", Effects = { Smarts = 3, Happiness = -1 } },
				{ Text = "Embrace it", Description = "You let the reputation grow. Fear can be useful.", Effects = { Reputation = 5, Happiness = -2 } },
				{ Text = "Spread confusion", Description = "You made sure the stories about you contradicted each other.", Effects = { Smarts = 5, Money = -100 } },
			}
		},
	}

	for _, scenario in ipairs(CURSE_USER_SCENARIOS) do
		table.insert(RANDOM_LIFE_SCENARIOS, scenario)
	end
end

registerCurseUserLifeScenarios()



----------------------------------------------------------------
-- UPDATE POLISH: RARE ROUTE SCENARIOS
----------------------------------------------------------------

function registerUpdatePolishRareScenarios()
	local RARE_UPDATE_SCENARIOS = {
		{
			Id = "rare_jh_scout_notice",
			Title = "Scout's Glance",
			Body = "A stranger in a clean uniform watches you for a little too long after your cursed energy leaks.",
			MinAge = 12,
			MaxAge = 28,
			Weight = 3,
			Options = {
				{ Text = "Ignore them", Description = "You ignored the stranger and kept moving before they could approach.", Effects = { Smarts = 2, Happiness = 1 } },
				{ Text = "Ask what they want", Description = "You confronted them directly. They only smiled and told you to consider Jujutsu High.", Effects = { Reputation = 1, Smarts = 3, UnregisteredProgress = 8 } },
				{ Text = "Hide your energy", Description = "You forced your cursed energy down and escaped their attention.", Effects = { Smarts = 4, TechniqueMastery = 1, Happiness = -1 } },
			}
		},
		{
			Id = "rare_cursed_object_reacts",
			Title = "Object Reaction",
			Body = "A small cursed object reacts when you pass by, vibrating like it recognizes your cursed energy.",
			MinAge = 10,
			MaxAge = 40,
			Weight = 3,
			Options = {
				{ Text = "Step away", Description = "You stepped away before the object could pull more cursed energy from you.", Effects = { Smarts = 2, Happiness = 1 } },
				{ Text = "Study it", Description = "You studied the reaction and learned something about how cursed objects respond to output.", Effects = { Smarts = 5, CursedEnergy = 2, UnregisteredProgress = 10 } },
				{ Text = "Touch it", Description = "You touched it and felt a sharp surge run through your body.", Effects = { CursedEnergy = 5, Health = -4, TechniqueMastery = 1, UnregisteredProgress = 12 } },
			}
		},
		{
			Id = "rare_warning_about_curse_user",
			Title = "A Warning",
			Body = "Someone who knows too much warns you that growing stronger outside the system has consequences.",
			MinAge = 13,
			MaxAge = 35,
			Weight = 4,
			Options = {
				{ Text = "Listen carefully", Description = "You listened. They warned you that a second unregistered grade-up could mark you as a curse user.", Effects = { Smarts = 5, Happiness = -1 } },
				{ Text = "Brush it off", Description = "You brushed the warning off, but the words stayed in your head.", Effects = { Happiness = -1, Reputation = 1 } },
				{ Text = "Ask about Jujutsu High", Description = "You asked about registration and learned why some people choose the official path.", Effects = { Smarts = 4, Reputation = 1 } },
			}
		},
		{
			Id = "rare_technique_pressure_evolution",
			Title = "Pressure Shift",
			Body = "Under pressure, your cursed technique behaves slightly differently than it did before.",
			MinAge = 12,
			MaxAge = 45,
			Weight = 3,
			RequiresTechnique = true,
			Options = {
				{ Text = "Control it", Description = "You controlled the shift before it became dangerous.", Effects = { TechniqueMastery = 4, Smarts = 2, UnregisteredProgress = 12 } },
				{ Text = "Push further", Description = "You pushed the change and learned something useful, but your body paid for it.", Effects = { TechniqueMastery = 6, CursedEnergy = 3, Health = -5, UnregisteredProgress = 16 } },
				{ Text = "Stop immediately", Description = "You stopped before the shift could spiral out of control.", Effects = { Smarts = 3, Happiness = 1 } },
			}
		},
		{
			Id = "rare_curse_user_recognition",
			Title = "Recognition",
			Body = "A curse user recognizes your potential and tells you the official system is not the only path.",
			MinAge = 13,
			MaxAge = 45,
			Weight = 3,
			Options = {
				{ Text = "Hear them out", Description = "You listened long enough to understand how the underground thinks.", Effects = { Smarts = 4, Reputation = -1, UnregisteredProgress = 10, Morality = -1 } },
				{ Text = "Reject them", Description = "You rejected their offer before they could pull you deeper in.", Effects = { Reputation = 2, Happiness = 2, Morality = 2 } },
				{ Text = "Take the contact", Description = "You took their contact information. It felt useful, and that made it worse.", Effects = { Smarts = 3, Reputation = -2, UnregisteredProgress = 12, Morality = -3 } },
			}
		},
	}

	for _, scenario in ipairs(RARE_UPDATE_SCENARIOS) do
		table.insert(RANDOM_LIFE_SCENARIOS, scenario)
	end
end

registerUpdatePolishRareScenarios()


function getRandomLifeScenarioChance(stats)
	local age = tonumber(stats and stats.Age) or 0

	if age <= 3 then
		return 30
	elseif age <= 7 then
		return 75
	elseif age <= 12 then
		return 82
	elseif age <= 19 then
		return 70
	elseif age <= 40 then
		return 58
	end

	return 48
end

function scenarioRequirementMet(stats, scenario)
	if not stats or not scenario then
		return false
	end

	local age = tonumber(stats.Age) or 0
	if scenario.MinAge and age < scenario.MinAge then return false end
	if scenario.MaxAge and age > scenario.MaxAge then return false end

	local technique = tostring(stats.CursedTechnique or "None")
	local hasTechnique = technique ~= "None" or tostring(stats.InnateTechnique or "None") ~= "None"
	local isSorcerer = isOfficialJujutsuSorcerer(stats)
	local hasDojo = stats.ClanFounded == true or (tonumber(stats.DojoPrestige) or 0) > 0 or (tonumber(stats.ClanStudentsRecruited) or 0) > 0

	if scenario.RequiresTechnique and not hasTechnique then return false end
	if scenario.RequiresSorcerer and not isSorcerer then return false end
	if scenario.RequiresCurseUser and not isCurseUser(stats) then return false end
	if scenario.RequiresDojo and not hasDojo then return false end

	-- Safety lock:
	-- Adult/teen "official jujutsu world" scenarios should not appear while the player is just unregistered.
	-- Childhood curse-sighting events are still allowed, but mission/public-exorcism/sorcerer-duty scenarios are blocked.
	local scenarioText = string.lower(
		tostring(scenario.Id or "") .. " " ..
			tostring(scenario.Title or "") .. " " ..
			tostring(scenario.Body or "")
	)

	local looksOfficialJujutsuScenario =
		string.find(scenarioText, "mission", 1, true) ~= nil
		or string.find(scenarioText, "sorcerer", 1, true) ~= nil
		or string.find(scenarioText, "jujutsu", 1, true) ~= nil
		or string.find(scenarioText, "black flash", 1, true) ~= nil
		or string.find(scenarioText, "curse incident", 1, true) ~= nil
		or string.find(scenarioText, "civilians are recording", 1, true) ~= nil
		or string.find(scenarioText, "public", 1, true) ~= nil and string.find(scenarioText, "curse", 1, true) ~= nil

	if age >= 13 and looksOfficialJujutsuScenario and not isSorcerer then
		return false
	end

	return true
end

function recentlyUsedLifeScenario(stats, scenarioId)
	if not stats or typeof(stats.RecentLifeScenarios) ~= "table" then
		return false
	end

	for _, recentId in ipairs(stats.RecentLifeScenarios) do
		if recentId == scenarioId then
			return true
		end
	end

	return false
end

function rememberLifeScenario(stats, scenarioId)
	if not stats or not scenarioId then
		return
	end

	stats.RecentLifeScenarios = stats.RecentLifeScenarios or {}
	table.insert(stats.RecentLifeScenarios, 1, scenarioId)

	while #stats.RecentLifeScenarios > 50 do
		table.remove(stats.RecentLifeScenarios)
	end
end

function rollRandomLifeScenario(stats, ignoreRecent)
	local possible = {}
	local totalWeight = 0

	for _, scenario in ipairs(RANDOM_LIFE_SCENARIOS) do
		if scenarioRequirementMet(stats, scenario) then
			if ignoreRecent or not recentlyUsedLifeScenario(stats, scenario.Id) then
				local weight = math.max(1, tonumber(scenario.Weight) or 5)
				totalWeight += weight
				table.insert(possible, { Data = scenario, Weight = weight })
			end
		end
	end

	if #possible <= 0 and not ignoreRecent then
		return rollRandomLifeScenario(stats, true)
	end

	if #possible <= 0 then
		return nil
	end

	local roll = math.random(1, totalWeight)
	local running = 0

	for _, entry in ipairs(possible) do
		running += entry.Weight
		if roll <= running then
			return entry.Data
		end
	end

	return possible[#possible].Data
end

function buildScenarioOptions(scenario)
	local options = {}

	for index, option in ipairs(scenario.Options or {}) do
		local optionCopy = {}
		for key, value in pairs(option) do
			optionCopy[key] = value
		end
		optionCopy.Index = index
		table.insert(options, optionCopy)
	end

	return options
end

function tryStartRandomLifeScenario(player, stats, forceScenario)
	if not player or not stats then
		return false
	end

	if pendingMissions[player.UserId] then
		return false
	end

	local chance = getRandomLifeScenarioChance(stats)
	if forceScenario ~= true and math.random(1, 100) > chance then
		return false
	end

	local scenario = rollRandomLifeScenario(stats, false)
	if not scenario then
		return false
	end

	local options = buildScenarioOptions(scenario)
	if #options < 2 then
		return false
	end

	pendingMissions[player.UserId] = {
		Type = "RandomLifeScenario",
		Scenario = scenario,
		availableOptions = options,
		CreatedAt = os.clock()
	}

	rememberLifeScenario(stats, scenario.Id)

	showMissionSituation:FireClient(player, {
		Type = "RandomLifeScenario",
		Title = scenario.Title or "Life Scenario",
		MissionTitle = scenario.Title or "Life Scenario",
		Body = scenario.Body or "You need to make a choice.",
		Options = options
	})

	return true
end

function applyRandomLifeScenarioEffects(stats, effects)
	if not stats or typeof(effects) ~= "table" then
		return
	end

	if effects.Health then stats.Health = math.clamp((tonumber(stats.Health) or 100) + effects.Health, 0, 100) end
	if effects.Happiness then stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) + effects.Happiness, 0, 100) end
	if effects.Smarts then stats.Smarts = math.clamp((tonumber(stats.Smarts) or 0) + effects.Smarts, 0, 100) end
	if effects.CursedEnergy then stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + effects.CursedEnergy) end
	if effects.Money then stats.Money = math.max(0, (tonumber(stats.Money) or 0) + effects.Money) end
	if effects.Reputation then stats.Reputation = (tonumber(stats.Reputation) or 0) + effects.Reputation end
	if effects.TechniqueMastery then stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + effects.TechniqueMastery, 0, 100) end
	if effects.ClanReputation then stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) + effects.ClanReputation) end
	if effects.DojoPrestige then stats.DojoPrestige = math.max(0, (tonumber(stats.DojoPrestige) or 0) + effects.DojoPrestige) end
	if effects.DojoCondition then stats.DojoCondition = math.clamp((tonumber(stats.DojoCondition) or 100) + effects.DojoCondition, 0, 100) end
	if effects.Morality then
		applyMorality(stats, effects.Morality)
	end

	stats.Alignment = getMoralAlignment(stats)

end

function resolveRandomLifeScenarioChoice(player, stats, scenario, option)
	if not player or not stats or not scenario or not option then
		return
	end

	ensureExtraStats(stats)
	applyRandomLifeScenarioEffects(stats, option.Effects)

	if option.AddVow then
		stats.ActiveVows = stats.ActiveVows or {}
		local alreadyHasVow = false
		for _, vowName in ipairs(stats.ActiveVows) do
			if vowName == option.AddVow then
				alreadyHasVow = true
				break
			end
		end
		if not alreadyHasVow then
			table.insert(stats.ActiveVows, option.AddVow)
		end
	end

	local resultText = tostring(option.Description or "You made your choice.")
	local logMessage = "<font color='#b27aff'><b>[ SCENARIO ]</b></font> " .. resultText

	local unregisteredScenarioProgress = getUnregisteredProgressGainFromEffects(option.Effects)
	if scenario and scenario.Id and string.find(tostring(scenario.Id), "unregistered", 1, true) then
		unregisteredScenarioProgress += 6
	end

	logMessage = awardUnregisteredProgress(player, stats, unregisteredScenarioProgress, "Risky unregistered experience", logMessage)

	if option.AddVow then
		logMessage ..= " <font color='#ffcd69'><b>Binding Vow gained: " .. tostring(option.AddVow) .. ".</b></font>"
	end

	fireLifeUpdate(player, stats, logMessage)

	-- Do NOT fire a second "CHOICE MADE" popup here.
	-- The player already made a choice in the scenario window; the result belongs in the life log.
	saveStats(player)
end

function addRandomLifeEvent(player, stats, currentMessage, forceEvent)
	if not stats then
		return currentMessage
	end

	-- BitLife-style rule:
	-- Visible life events should be SCENARIOS with choices, not boring one-button popups.
	-- Passive LifeEvents V2 entries are still allowed to enrich the life log,
	-- but they should NOT fire ShowMajorPopup.
	local shouldTryScenario = forceEvent == true

	if not shouldTryScenario then
		local rollChance = getLifeEventRollChance(stats)
		shouldTryScenario = math.random(1, 100) <= rollChance
	end

	if shouldTryScenario then
		-- Force scenario attempt once the event roll succeeds.
		-- This avoids the old behavior where a scenario failed its own chance
		-- and then fell back into a one-button LIFE EVENT popup.
		if tryStartRandomLifeScenario(player, stats, true) then
			return currentMessage
		end
	end

	-- Fallback: passive log flavor only.
	-- No popup here. If the player sees a big event window, it should have choices.
	local eventData = BitKaisenLifeEvents.RollEvent(stats)

	if not eventData then
		return currentMessage
	end

	local eventMessage = BitKaisenLifeEvents.ApplyEvent(stats, eventData)

	if not eventMessage or eventMessage == "" then
		return currentMessage
	end

	local combinedMessage = eventMessage
	local passiveProgress = getUnregisteredProgressGainFromEffects(eventData.Effects)

	if eventData.Category == "Technique" or eventData.Category == "Training" or eventData.Category == "Curse" or eventData.Category == "Rare" then
		passiveProgress += 4
	end

	combinedMessage = awardUnregisteredProgress(player, stats, passiveProgress, "Unregistered life experience", combinedMessage)

	if currentMessage and currentMessage ~= "" then
		return currentMessage .. "\n" .. combinedMessage
	end

	return combinedMessage
end

function addRelationshipAgeEvent(player, stats, currentMessage)
	if math.random(1, 100) > 35 then
		return currentMessage
	end

	local relationshipMessage, popupData = BitKaisenRelationships.RollAgeEvent(stats)

	if not relationshipMessage then
		return currentMessage
	end

	fireRelationshipPopup(player, popupData)

	if currentMessage and currentMessage ~= "" then
		return currentMessage .. "\n" .. relationshipMessage
	end

	return relationshipMessage
end

function maybeTeacherRecommendation(player, stats, logMessage)
	if not stats.InJujutsuHigh then
		return logMessage
	end

	if stats.Age < 16 then
		return logMessage
	end

	local chance = 8

	if stats.Reputation >= 20 then
		chance += 4
	end

	if stats.MissionsCompleted >= 3 then
		chance += 4
	end

	if stats.CursedEnergy >= 90 then
		chance += 3
	end

	if stats.ClanFounded then
		chance += 3
	end

	if math.random(1, 100) <= chance then
		stats.TeacherRecommendations += 1

		logMessage = logMessage .. "\nOne of your teachers submitted a recommendation for your promotion review."

		fireMajorPopup(
			player,
			"TEACHER RECOMMENDATION",
			"One of your instructors reviewed your progress and submitted a recommendation.",
			"Recommendation Added",
			"Teacher recommendations can help you advance through semi-grades."
		)
	end

	return logMessage
end



----------------------------------------------------------------
-- CURSE USER MISSIONS + MORALITY
----------------------------------------------------------------

CURSE_USER_MISSIONS = {}

function registerCurseUserMissions()
	local missions = {
		{
			Id = "curse_user_information_broker",
			Title = "Sell Information",
			Grade = "Curse User Grade 4",
			Difficulty = 28,
			RewardCE = 8,
			RewardMoney = 450,
			RewardRep = -3,
			DmgPenalty = 8,
			Body = "A shady broker wants information about a minor cursed object route.",
			Choices = {
				{ Text = "Sell the information", Description = "You sold the information and kept your name out of it.", Effects = { Money = 550, Reputation = -3, CursedEnergy = 2, CurseUserProgress = 8 }, Morality = -4 },
				{ Text = "Sell fake information", Description = "You sold fake information and left the broker chasing ghosts.", Effects = { Money = 300, Smarts = 3, Reputation = -1, CurseUserProgress = 5 }, Morality = -1 },
				{ Text = "Refuse the job", Description = "You refused the job. Even curse users can have lines.", Effects = { Happiness = 1, Reputation = 1 }, Morality = 2 },
			}
		},
		{
			Id = "curse_user_hidden_cache",
			Title = "Hidden Cache",
			Grade = "Curse User Grade 4",
			Difficulty = 32,
			RewardCE = 10,
			RewardMoney = 350,
			RewardRep = -2,
			DmgPenalty = 10,
			Body = "You hear about a hidden cache of minor cursed objects nobody is guarding.",
			Choices = {
				{ Text = "Take everything", Description = "You took the cache before anyone else could reach it.", Effects = { Money = 700, CursedEnergy = 4, Reputation = -4, CurseUserProgress = 10 }, Morality = -5 },
				{ Text = "Take one object", Description = "You only took one object and left the rest alone.", Effects = { Money = 250, CursedEnergy = 3, Reputation = -1, CurseUserProgress = 6 }, Morality = -1 },
				{ Text = "Destroy the cache", Description = "You destroyed the cache so nobody could use it.", Effects = { Reputation = 2, Happiness = 2, CursedEnergy = -2 }, Morality = 3 },
			}
		},
		{
			Id = "curse_user_intimidation",
			Title = "Intimidation Job",
			Grade = "Curse User Grade 3",
			Difficulty = 45,
			RewardCE = 14,
			RewardMoney = 800,
			RewardRep = -5,
			DmgPenalty = 14,
			Body = "Someone offers payment if you scare off a rival contact without involving officials.",
			Choices = {
				{ Text = "Intimidate them", Description = "You made the warning clear enough that they will remember it.", Effects = { Money = 850, Reputation = -5, CurseUserProgress = 12 }, Morality = -6 },
				{ Text = "Warn them quietly", Description = "You gave a quiet warning instead of making a spectacle.", Effects = { Money = 450, Smarts = 3, Reputation = -2, CurseUserProgress = 8 }, Morality = -2 },
				{ Text = "Expose the client", Description = "You exposed the person who hired you and ruined their plan.", Effects = { Reputation = 3, Happiness = 2, Money = -100 }, Morality = 4 },
			}
		},
		{
			Id = "curse_user_cursed_tool_theft",
			Title = "Cursed Tool Theft",
			Grade = "Curse User Grade 3",
			Difficulty = 55,
			RewardCE = 18,
			RewardMoney = 1200,
			RewardRep = -6,
			DmgPenalty = 18,
			Body = "A low-security storage room contains a cursed tool that could sell for a lot.",
			Choices = {
				{ Text = "Steal it", Description = "You stole the cursed tool and disappeared before the alarm spread.", Effects = { Money = 1400, Reputation = -7, CursedEnergy = 4, CurseUserProgress = 14 }, Morality = -8 },
				{ Text = "Copy the records", Description = "You copied the storage records instead. Less profit, less heat.", Effects = { Money = 500, Smarts = 5, Reputation = -2, CurseUserProgress = 8 }, Morality = -2 },
				{ Text = "Tip off Jujutsu High", Description = "You anonymously warned Jujutsu High about the weak storage.", Effects = { Reputation = 2, Happiness = 1 }, Morality = 4 },
			}
		},
		{
			Id = "curse_user_grudge_request",
			Title = "Grudge Request",
			Grade = "Curse User Grade 2",
			Difficulty = 70,
			RewardCE = 24,
			RewardMoney = 1800,
			RewardRep = -9,
			DmgPenalty = 22,
			Body = "A client wants you to ruin someone's career through cursed energy pressure and rumors.",
			Choices = {
				{ Text = "Take the request", Description = "You accepted the request and left the target's reputation damaged.", Effects = { Money = 1900, Reputation = -10, CurseUserProgress = 18, Happiness = -2 }, Morality = -10 },
				{ Text = "Scam the client", Description = "You took partial payment and gave the client nothing useful.", Effects = { Money = 800, Smarts = 4, Reputation = -4, CurseUserProgress = 10 }, Morality = -3 },
				{ Text = "Warn the target", Description = "You warned the target and earned a little respect from yourself.", Effects = { Reputation = 4, Happiness = 3, Money = -150 }, Morality = 5 },
			}
		},
		{
			Id = "curse_user_underworld_duel",
			Title = "Underworld Duel",
			Grade = "Curse User Grade 2",
			Difficulty = 82,
			RewardCE = 30,
			RewardMoney = 2200,
			RewardRep = -7,
			DmgPenalty = 28,
			Body = "Another curse user challenges you for status in the underground.",
			Choices = {
				{ Text = "Accept the duel", Description = "You accepted and proved your strength where officials were not watching.", Effects = { Money = 1200, CursedEnergy = 8, Reputation = -6, Health = -8, CurseUserProgress = 20 }, Morality = -4 },
				{ Text = "Set a trap", Description = "You won before the duel really started. Dirty, but effective.", Effects = { Money = 1600, Smarts = 5, Reputation = -9, CurseUserProgress = 22 }, Morality = -8 },
				{ Text = "Refuse publicly", Description = "You refused and called the duel pointless. Some mocked you, others respected the control.", Effects = { Reputation = 1, Smarts = 4, Happiness = 1 }, Morality = 2 },
			}
		},
		{
			Id = "curse_user_special_contract",
			Title = "Special Contract",
			Grade = "Curse User Grade 1",
			Difficulty = 105,
			RewardCE = 40,
			RewardMoney = 3500,
			RewardRep = -14,
			DmgPenalty = 34,
			Body = "A dangerous client offers a serious contract. The payment is huge, but the request is ugly.",
			Choices = {
				{ Text = "Accept the contract", Description = "You accepted the contract and crossed a line people do not forget.", Effects = { Money = 4000, Reputation = -15, CursedEnergy = 8, Happiness = -6, CurseUserProgress = 28 }, Morality = -14 },
				{ Text = "Negotiate limits", Description = "You negotiated strict limits and took a cleaner version of the job.", Effects = { Money = 1800, Reputation = -5, Smarts = 5, CurseUserProgress = 14 }, Morality = -3 },
				{ Text = "Leak the contract", Description = "You leaked the contract details and caused chaos for the client.", Effects = { Reputation = 5, Happiness = 2, Money = -300 }, Morality = 6 },
			}
		},
		{
			Id = "curse_user_black_market_auction",
			Title = "Black Market Auction",
			Grade = "Curse User Grade 4",
			Difficulty = 36,
			RewardCE = 12,
			RewardMoney = 700,
			RewardRep = -4,
			DmgPenalty = 12,
			Body = "An underground auction is selling cursed scraps, fake tools, and one item that feels dangerously real.",
			Choices = {
				{ Text = "Bid aggressively", Description = "You forced the auction your way and walked out with the cursed item.", Effects = { Money = -500, CursedEnergy = 6, Reputation = -4, CurseUserProgress = 12 }, Morality = -4 },
				{ Text = "Watch quietly", Description = "You studied the buyers and learned who moves cursed objects in the area.", Effects = { Smarts = 5, Reputation = -1, CurseUserProgress = 7 }, Morality = -1 },
				{ Text = "Sabotage the sale", Description = "You disrupted the auction enough that the cursed item vanished from the market.", Effects = { Reputation = 2, Happiness = 2, Money = -150 }, Morality = 4 },
			}
		},
		{
			Id = "curse_user_false_report",
			Title = "False Report",
			Grade = "Curse User Grade 4",
			Difficulty = 34,
			RewardCE = 10,
			RewardMoney = 600,
			RewardRep = -3,
			DmgPenalty = 10,
			Body = "Someone asks you to plant a false curse report to distract official sorcerers.",
			Choices = {
				{ Text = "Plant the report", Description = "You planted the false report and pulled attention away from the real target.", Effects = { Money = 650, Smarts = 3, Reputation = -4, CurseUserProgress = 10 }, Morality = -5 },
				{ Text = "Make it harmless", Description = "You planted a weaker report that wasted time but avoided serious damage.", Effects = { Money = 350, Reputation = -1, Smarts = 4, CurseUserProgress = 6 }, Morality = -1 },
				{ Text = "Send a warning", Description = "You tipped someone off that the report was fake.", Effects = { Reputation = 2, Happiness = 2 }, Morality = 3 },
			}
		},
		{
			Id = "curse_user_underground_contact",
			Title = "Underground Contact",
			Grade = "Curse User Grade 3",
			Difficulty = 50,
			RewardCE = 16,
			RewardMoney = 950,
			RewardRep = -5,
			DmgPenalty = 16,
			Body = "A new underground contact wants proof that you are useful before sharing better work.",
			Choices = {
				{ Text = "Prove yourself", Description = "You handled their request and earned a place in their network.", Effects = { Money = 1000, Reputation = -5, Smarts = 2, CurseUserProgress = 14 }, Morality = -5 },
				{ Text = "Manipulate them", Description = "You made them think you were more connected than you really are.", Effects = { Money = 600, Smarts = 6, Reputation = -2, CurseUserProgress = 10 }, Morality = -2 },
				{ Text = "Reject the network", Description = "You refused to get tied to someone else's chain.", Effects = { Happiness = 2, Reputation = 1, Smarts = 2 }, Morality = 2 },
			}
		},
		{
			Id = "curse_user_cursed_object_delivery",
			Title = "Cursed Object Delivery",
			Grade = "Curse User Grade 3",
			Difficulty = 58,
			RewardCE = 20,
			RewardMoney = 1300,
			RewardRep = -6,
			DmgPenalty = 18,
			Body = "You are offered money to deliver a sealed cursed object without asking who receives it.",
			Choices = {
				{ Text = "Deliver it", Description = "You delivered the object and did not ask questions.", Effects = { Money = 1350, Reputation = -6, CurseUserProgress = 16 }, Morality = -7 },
				{ Text = "Inspect it first", Description = "You inspected the object and learned enough to protect yourself during delivery.", Effects = { Money = 850, CursedEnergy = 4, Smarts = 4, Reputation = -3, CurseUserProgress = 12 }, Morality = -3 },
				{ Text = "Break the seal", Description = "You broke the seal and destroyed what was inside before delivery.", Effects = { Health = -4, CursedEnergy = 3, Reputation = 3, Happiness = 1 }, Morality = 4 },
			}
		},
		{
			Id = "curse_user_secret_duel",
			Title = "Secret Duel",
			Grade = "Curse User Grade 2",
			Difficulty = 78,
			RewardCE = 28,
			RewardMoney = 2000,
			RewardRep = -8,
			DmgPenalty = 26,
			Body = "A curse user challenges you in a sealed-off place where nobody official will interfere.",
			Choices = {
				{ Text = "Fight directly", Description = "You fought directly and won enough respect to make people whisper your name.", Effects = { Money = 1600, CursedEnergy = 7, Health = -7, Reputation = -6, CurseUserProgress = 20 }, Morality = -4 },
				{ Text = "Fight dirty", Description = "You won with traps, pressure, and no wasted pride.", Effects = { Money = 2200, Smarts = 5, Reputation = -10, CurseUserProgress = 24 }, Morality = -9 },
				{ Text = "Walk away", Description = "You walked away before the duel became someone else's entertainment.", Effects = { Happiness = 2, Smarts = 3, Reputation = 1 }, Morality = 2 },
			}
		}
	}

	for _, mission in ipairs(missions) do
		local rep = tonumber(mission.RewardRep) or 0
		local repText = "Rep +" .. tostring(rep)

		if rep < 0 then
			repText = "Rep " .. tostring(rep)
		end

		mission.RewardText = mission.RewardText or (
			"Choice rewards • $" ..
				tostring(mission.RewardMoney or 0) ..
				" • CE +" ..
				tostring(mission.RewardCE or 0) ..
				" • " ..
				repText ..
				" • Underground Progress"
		)

		table.insert(CURSE_USER_MISSIONS, mission)
	end
end

registerCurseUserMissions()

function getMoralAlignment(stats)
	local reputation = tonumber(stats and stats.Reputation) or 0
	local morality = tonumber(stats and stats.Morality) or 0
	local score = reputation + morality

	if score <= -75 then
		return "Infamous Evil"
	elseif score <= -35 then
		return "Evil"
	elseif score <= -10 then
		return "Shady"
	elseif score < 20 then
		return "Neutral"
	elseif score < 60 then
		return "Respected"
	end

	return "Honored"
end

function applyMorality(stats, amount)
	if not stats then
		return
	end

	stats.Morality = math.clamp((tonumber(stats.Morality) or 0) + (tonumber(amount) or 0), -100, 100)
	stats.Alignment = getMoralAlignment(stats)
end

function getCurseUserMissionById(missionId)
	for _, mission in ipairs(CURSE_USER_MISSIONS) do
		if mission.Id == missionId then
			return mission
		end
	end

	return nil
end

function canAttemptCurseUserMission(stats, mission)
	if not stats or not mission then
		return false
	end

	if not isCurseUser(stats) then
		return false
	end

	return getGradeValue(stats.Grade) >= getGradeValue(mission.Grade)
end

function generateCurseUserMissionBoard(stats)
	local board = {}

	if not isCurseUser(stats) then
		return board
	end

	for _, mission in ipairs(CURSE_USER_MISSIONS) do
		if canAttemptCurseUserMission(stats, mission) then
			table.insert(board, mission)
		end
	end

	while #board > 4 do
		table.remove(board, math.random(1, #board))
	end

	return board
end

function grantCurseUserProgress(player, stats, amount, logMessage)
	if not stats or not isCurseUser(stats) then
		return logMessage
	end

	local gain = math.max(0, math.floor(tonumber(amount) or 0))
	if gain <= 0 then
		return logMessage
	end

	stats.CurseUserProgress = math.max(0, tonumber(stats.CurseUserProgress) or 0) + gain

	local requirement = 120 + (getGradeValue(stats.Grade) * 35)

	logMessage = appendLine(
		logMessage,
		"<font color='#e53935'><b>[ CURSE USER ]</b></font> Underground progress +" .. tostring(gain) .. " (" .. tostring(stats.CurseUserProgress) .. "/" .. tostring(requirement) .. ")."
	)

	while stats.CurseUserProgress >= requirement do
		stats.CurseUserProgress -= requirement

		local nextGrade = getNextUnregisteredGrade(stats.Grade)
		makeCurseUser(stats, nextGrade)

		logMessage = appendLine(logMessage, "Your underground reputation and strength grew. You advanced to <b>" .. tostring(stats.Grade) .. "</b>.")

		fireMajorPopup(
			player,
			"CURSE USER GRADE UP",
			"Your name spread through darker circles.",
			tostring(stats.Grade),
			"Your curse user grade increased."
		)

		requirement = 120 + (getGradeValue(stats.Grade) * 35)

		if getOfficialGradeName(stats.Grade) == "Special Grade" then
			break
		end
	end

	return logMessage
end

function processCurseUserMission(player, stats, missionId)
	if not stats then
		return
	end

	if not isCurseUser(stats) then
		fireLifeUpdate(player, stats, "Only curse users can take curse user missions.")
		return
	end

	local mission = getCurseUserMissionById(missionId)

	if not mission then
		fireLifeUpdate(player, stats, "That curse user mission no longer exists.")
		return
	end

	if not canAttemptCurseUserMission(stats, mission) then
		fireLifeUpdate(player, stats, "You are not strong enough for that curse user mission yet.")
		return
	end

	local fullChoices = mission.Choices or {}
	local displayOptions = {}

	for index, choice in ipairs(fullChoices) do
		table.insert(displayOptions, {
			Index = index,
			index = index,
			OptionIndex = index,
			Text = tostring(choice.Text or ("Option " .. tostring(index))),
			Description = tostring(choice.Description or "")
		})
	end

	pendingMissions[player.UserId] = {
		Type = "CurseUser",
		Mission = mission,
		availableOptions = fullChoices,
		CreatedAt = os.clock()
	}

	showMissionSituation:FireClient(player, {
		MissionTitle = "CURSE USER MISSION",
		Title = mission.Title,
		Body = mission.Body,
		Options = displayOptions,
		Source = "CurseUserMission"
	})
end


local UNREGISTERED_GRADE_ORDER = {
	"Grade 4",
	"Semi-Grade 3",
	"Grade 3",
	"Semi-Grade 2",
	"Grade 2",
	"Semi-Grade 1",
	"Grade 1",
	"Special Grade"
}

local UNREGISTERED_PROGRESS_REQUIREMENTS = {
	["Grade 4"] = 35,
	["Semi-Grade 3"] = 45,
	["Grade 3"] = 60,
	["Semi-Grade 2"] = 80,
	["Grade 2"] = 105,
	["Semi-Grade 1"] = 135,
	["Grade 1"] = 175,
	["Special Grade"] = 999999
}

function getUnregisteredGradeIndex(grade)
	local cleanGrade = getOfficialGradeName(grade)

	for index, gradeName in ipairs(UNREGISTERED_GRADE_ORDER) do
		if gradeName == cleanGrade then
			return index
		end
	end

	return 0
end

function getNextUnregisteredGrade(grade)
	local index = getUnregisteredGradeIndex(grade)

	if index <= 0 then
		return "Grade 4"
	end

	if index >= #UNREGISTERED_GRADE_ORDER then
		return UNREGISTERED_GRADE_ORDER[#UNREGISTERED_GRADE_ORDER]
	end

	return UNREGISTERED_GRADE_ORDER[index + 1]
end

function getUnregisteredProgressRequirement(stats)
	local currentGrade = getOfficialGradeName(stats and stats.Grade or "Non-Sorcerer")

	if currentGrade == "Non-Sorcerer" then
		currentGrade = getEstimatedUnregisteredGrade(stats)
	end

	return UNREGISTERED_PROGRESS_REQUIREMENTS[currentGrade] or 50
end

function getUnregisteredProgressGainFromEffects(effects)
	if typeof(effects) ~= "table" then
		return 0
	end

	local gain = 0

	gain += math.max(0, tonumber(effects.CursedEnergy) or 0)
	gain += math.max(0, tonumber(effects.TechniqueMastery) or 0) * 5
	gain += math.max(0, tonumber(effects.Smarts) or 0)
	gain += math.max(0, tonumber(effects.Reputation) or 0) * 2

	if (tonumber(effects.Health) or 0) < 0 then
		gain += math.min(10, math.abs(tonumber(effects.Health) or 0))
	end

	if (tonumber(effects.Happiness) or 0) < 0 then
		gain += math.min(5, math.abs(tonumber(effects.Happiness) or 0))
	end

	return math.floor(gain)
end

function completeUnregisteredGradeUp(player, stats, newGrade, logMessage)
	if not stats then
		return logMessage or ""
	end

	local cleanGrade = getOfficialGradeName(newGrade)

	if cleanGrade == "Non-Sorcerer" then
		cleanGrade = getNextUnregisteredGrade(stats.Grade)
	end

	stats.UnregisteredGradeUps = math.max(0, tonumber(stats.UnregisteredGradeUps) or 0) + 1
	stats.UnregisteredProgress = 0

	if shouldBrandAsCurseUser(stats) then
		makeCurseUser(stats, cleanGrade)
		stats.CurseUserBrandReason = "Unregistered outlaw pressure"

		logMessage = appendLine(
			logMessage,
			"Your unregistered power and public danger finally crossed the line. The jujutsu world stopped seeing you as a future student and branded you as a curse user."
		)

		fireMajorPopup(
			player,
			"CURSE USER PATH",
			"Your unregistered growth, danger markers, and lack of official oversight finally became too much for the jujutsu world to ignore.",
			tostring(stats.Grade),
			"You are now a curse user."
		)

		return logMessage
	end

	stats.Grade = "Unregistered " .. cleanGrade
	stats.UnregisteredGrade = cleanGrade
	stats.OfficialGrade = "Unregistered"

	logMessage = appendLine(
		logMessage,
		"Your unregistered strength was recognized. You rose to <b>Unregistered " .. tostring(cleanGrade) .. "</b>. If you grade up again before registering, you may be branded a curse user."
	)

	fireMajorPopup(
		player,
		"UNREGISTERED GRADE UP",
		"Your strength advanced outside the official jujutsu system.",
		"Unregistered " .. tostring(cleanGrade),
		"Curse user branding now needs repeated growth plus danger markers."
	)

	return logMessage
end

function awardUnregisteredProgress(player, stats, amount, reason, logMessage)
	if not stats or amount == nil then
		return logMessage or ""
	end

	if stats.InJujutsuHigh == true or isOfficialJujutsuSorcerer(stats) or isCurseUser(stats) then
		return logMessage or ""
	end

	ensureSorcererRegistrationState(stats)

	if not isUnregisteredSorcerer(stats) then
		return logMessage or ""
	end

	local gain = math.max(0, math.floor(tonumber(amount) or 0))

	if gain <= 0 then
		return logMessage or ""
	end

	stats.UnregisteredProgress = math.max(0, tonumber(stats.UnregisteredProgress) or 0) + gain

	local requirement = getUnregisteredProgressRequirement(stats)
	local reasonText = tostring(reason or "private growth")

	logMessage = appendLine(
		logMessage,
		"<font color='#b27aff'><b>[ UNREGISTERED ]</b></font> " .. reasonText .. " +" .. tostring(gain) .. " progress (" .. tostring(stats.UnregisteredProgress) .. "/" .. tostring(requirement) .. ")."
	)

	while stats.UnregisteredProgress >= requirement and not stats.InJujutsuHigh and not isCurseUser(stats) do
		stats.UnregisteredProgress -= requirement
		local nextGrade = getNextUnregisteredGrade(stats.Grade)
		logMessage = completeUnregisteredGradeUp(player, stats, nextGrade, logMessage)

		if isCurseUser(stats) then
			break
		end

		requirement = getUnregisteredProgressRequirement(stats)
	end

	return logMessage
end

function getUnregisteredActivityProgress(activityId, stats)
	if not stats or stats.InJujutsuHigh == true or isCurseUser(stats) then
		return 0, nil
	end

	local progressByActivity = {
		watch_shadows = 6,
		ask_about_curses = 5,
		train_ce = 10,
		study_theory = 6,
		expand_curse_knowledge = 8,
		meditate = 5,
		practice_technique = 14,
		black_flash_training = 18,
		physical_conditioning = 5,
		barrier_drills = 9,
		binding_vow_research = 12,
		domain_foundation_study = 16,
	}

	local progress = progressByActivity[activityId] or 0

	if activityId == "train_ce" then
		stats.PrivateTrainingSessions = math.max(0, tonumber(stats.PrivateTrainingSessions) or 0) + 1
	end

	if progress <= 0 then
		return 0, nil
	end

	return progress, "Private growth from " .. tostring(activityId):gsub("_", " ")
end


function checkPromotionAndPopup(player, stats, logMessage)
	if not stats then
		return logMessage
	end

	local wasOfficial = isOfficialJujutsuSorcerer(stats)
	local wasUnregistered = isUnregisteredSorcerer(stats)
	local wasCurseUser = isCurseUser(stats)

	-- Unregistered sorcerers do not use official mission/promotion grading.
	-- Their growth comes from UnregisteredProgress, private training, scenarios, and risky choices.
	if wasUnregistered and not wasOfficial and not wasCurseUser then
		return logMessage
	end

	local promotion = BitKaisenStats.CheckPromotion(stats)

	if promotion then
		local promotedGrade = getOfficialGradeName(promotion)

		if promotedGrade == "Non-Sorcerer" then
			promotedGrade = getEstimatedUnregisteredGrade(stats)
		end

		if wasCurseUser or isCurseUser(stats) then
			makeCurseUser(stats, promotedGrade)

			logMessage = logMessage .. "\nYour strength grew outside the official system. You are now recognized in darker circles as a " .. tostring(stats.Grade) .. "."

			fireMajorPopup(
				player,
				"CURSE USER GROWTH",
				"Your power advanced without registration. The official jujutsu world is no longer the path judging you.",
				tostring(stats.Grade),
				"You are progressing as a curse user."
			)

			return logMessage
		end

		if wasUnregistered and not wasOfficial and stats.InJujutsuHigh ~= true then
			stats.UnregisteredGradeUps = math.max(0, tonumber(stats.UnregisteredGradeUps) or 0) + 1

			if shouldBrandAsCurseUser(stats) then
				makeCurseUser(stats, promotedGrade)
				stats.CurseUserBrandReason = "Unregistered outlaw pressure"

				logMessage = logMessage .. "\nYour unregistered power and public danger finally crossed the line. The jujutsu world stopped seeing you as a future student and branded you as a curse user."

				fireMajorPopup(
					player,
					"CURSE USER PATH",
					"Your unregistered growth, danger markers, and lack of official oversight finally became too much for the jujutsu world to ignore.",
					tostring(stats.Grade),
					"You are now a curse user."
				)

				return logMessage
			end

			stats.Grade = "Unregistered " .. promotedGrade
			stats.UnregisteredGrade = promotedGrade
			stats.OfficialGrade = "Unregistered"

			logMessage = logMessage .. "\nYour unregistered strength was recognized. You rose to <b>Unregistered " .. tostring(promotedGrade) .. "</b>. Curse user branding now requires repeated unregistered growth plus real danger markers. Current risk: " .. getCurseUserRiskText(stats) .. "."

			fireMajorPopup(
				player,
				"UNREGISTERED GRADE UP",
				"Your strength advanced outside the official jujutsu system, but you are not automatically a curse user anymore.",
				"Unregistered " .. tostring(promotedGrade),
				"Apply to Jujutsu High or keep growing privately. Curse user branding now needs repeated growth plus danger markers."
			)

			return logMessage
		end

		ensureSorcererRegistrationState(stats)

		logMessage = logMessage .. "\nYour growth was officially recognized. You were promoted to " .. promotion .. "."

		fireMajorPopup(
			player,
			"PROMOTION",
			"Your growth in the jujutsu world has been recognized.",
			promotion,
			"Your new grade has been added to your record."
		)
	end

	return logMessage
end


local MONTH_NAMES = {
	"January",
	"February",
	"March",
	"April",
	"May",
	"June",
	"July",
	"August",
	"September",
	"October",
	"November",
	"December",
}

function getCurrentYear(stats)
	return 2000 + (tonumber(stats and stats.Age) or 0)
end

function getCurrentMonthName(stats)
	local monthIndex = math.clamp(tonumber(stats and stats.CurrentMonth) or 1, 1, 12)
	return MONTH_NAMES[monthIndex] or "January"
end

function getTimeStampText(stats)
	return getCurrentMonthName(stats) .. " " .. tostring(getCurrentYear(stats))
end

function normalizeSixMonthDate(stats)
	ensureExtraStats(stats)

	-- Phase 2A.5: resentment is the hidden unlock meter for Curse rebirth.
	-- It rises slowly from miserable/cursed lives, then spikes on cursed deaths.
	if not isCurseLife(stats) then
		if (tonumber(stats.Happiness) or 100) <= 25 then
			addCursedResentment(stats, math.random(1, 3))
		end
		if isCurseUser(stats) then
			addCursedResentment(stats, 1)
		end
		if (tonumber(stats.WantedLevel) or 0) >= 3 then
			addCursedResentment(stats, math.random(1, 2))
		end
	end

	local currentAge = tonumber(stats.Age) or 0

	if currentAge < 16 then
		stats.CurrentMonth = 1
		stats.MonthsIntoAge = 0
		return 1, 0
	end

	local currentMonth = math.clamp(tonumber(stats.CurrentMonth) or 1, 1, 12)
	local monthsIntoAge = tonumber(stats.MonthsIntoAge)

	-- Release-stability fix:
	-- Old saves/builds sometimes had Age 16+ at July with MonthsIntoAge still 0.
	-- That made the next +AGE bounce back to January without turning 17.
	-- For the new six-month system, the only valid states are:
	--   January = 0 months into current age
	--   July    = 6 months into current age
	if currentMonth >= 7 then
		currentMonth = 7
		monthsIntoAge = 6
	else
		currentMonth = 1
		monthsIntoAge = 0
	end

	stats.CurrentMonth = currentMonth
	stats.MonthsIntoAge = monthsIntoAge

	return currentMonth, monthsIntoAge
end


function applyEncounterEffects(stats, effects)
	if typeof(effects) ~= "table" then
		return
	end

	if effects.Health then
		stats.Health = math.clamp((stats.Health or 100) + effects.Health, 0, 100)
	end

	if effects.Happiness then
		stats.Happiness = math.clamp((stats.Happiness or 100) + effects.Happiness, 0, 100)
	end

	if effects.Smarts then
		stats.Smarts = math.clamp((stats.Smarts or 0) + effects.Smarts, 0, 100)
	end

	if effects.CursedEnergy then
		stats.CursedEnergy = math.max(0, (stats.CursedEnergy or 0) + effects.CursedEnergy)
	end

	if effects.Money then
		stats.Money = math.max(0, (stats.Money or 0) + effects.Money)
	end

	if effects.Reputation then
		stats.Reputation = (stats.Reputation or 0) + effects.Reputation
	end

	if effects.TeacherRecommendations then
		stats.TeacherRecommendations = math.max(0, (stats.TeacherRecommendations or 0) + effects.TeacherRecommendations)
	end

	if effects.TechniqueMastery then
		stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + effects.TechniqueMastery, 0, 100)
	end

	if effects.ClanReputation then
		stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + effects.ClanReputation)
	end
	if effects.Morality then
		applyMorality(stats, effects.Morality)
	end

	stats.Alignment = getMoralAlignment(stats)

end


function makeMysteryInventoryItem(itemData, stats)
	itemData = itemData or {}
	local idBase = tostring(itemData.Id or itemData.Name or "mystery_item")
	idBase = idBase:gsub("%s+", "_"):gsub("[^%w_]", ""):lower()

	return {
		Id = idBase .. "_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999)),
		BaseId = idBase,
		Name = tostring(itemData.Name or "Unknown Cursed Object"),
		Type = tostring(itemData.Type or "Mysterious Item"),
		Category = tostring(itemData.Category or "Event Item"),
		Rarity = tostring(itemData.Rarity or "Uncommon"),
		Description = tostring(itemData.Description or "A strange item obtained during a life event."),
		AcquiredFrom = tostring(itemData.AcquiredFrom or "Monthly Life Event"),
		AcquiredAge = stats and stats.Age or 0,
		AcquiredMonth = stats and stats.CurrentMonth or 1,
		CanUse = itemData.CanUse == true,
		EventItem = true,
		Quantity = tonumber(itemData.Quantity) or 1,
	}
end

function addMysteryInventoryItem(stats, itemData)
	if typeof(stats) ~= "table" then
		return nil
	end

	stats.Assets = stats.Assets or {}

	local ownedItem = makeMysteryInventoryItem(itemData, stats)
	table.insert(stats.Assets, ownedItem)
	return ownedItem
end

function getEncounterOutcomeText(option, stats)
	if typeof(option) ~= "table" then
		return "The moment passed without changing much."
	end

	if typeof(option.Outcomes) == "table" and #option.Outcomes > 0 then
		return pickRandom(option.Outcomes)
	end

	return tostring(option.Result or "The moment passed without changing much.")
end

local MONTHLY_LIFE_ENCOUNTERS = {
	{
		Id = "senior_sorcerer_questions",
		Title = "Senior Sorcerer",
		Body = "A senior sorcerer approached you after noticing your cursed energy. Their tone was calm, but it felt like a test.",
		Options = {
			{
				Text = "Answer honestly about your grade",
				Effects = { Reputation = 2, Smarts = 1 },
				Outcomes = {
					"You told them your real grade. They nodded once and told you not to rush your promotion.",
					"You answered honestly. They respected the lack of fake confidence more than the grade itself.",
					"You gave them your grade and waited. They said honesty keeps sorcerers alive longer than pride."
				}
			},
			{
				Text = "Ask them how to survive harder missions",
				Effects = { Smarts = 3, CursedEnergy = 1 },
				Outcomes = {
					"They gave you blunt advice about retreating before pride gets you killed.",
					"They explained how experienced sorcerers read a curse before committing to a fight.",
					"They taught you a small breathing habit that helped settle your cursed energy."
				}
			},
			{
				Text = "Act tougher than you are",
				Chance = 35,
				SuccessEffects = { Reputation = 4 },
				FailEffects = { Reputation = -3, Happiness = -2 },
				SuccessText = "You played it cool. Somehow, they bought it and told someone else you had nerve.",
				FailText = "They saw through the act immediately. The silence afterward was worse than getting yelled at."
			}
		}
	},
	{
		Id = "robbed_by_sorcerer",
		Title = "Wrong Alley",
		Body = "A desperate curse user cut you off in a side street and demanded your money. Their cursed energy was weak, but their hands were shaking.",
		Options = {
			{
				Text = "Hand over some money",
				Effects = { Money = -250, Happiness = -1 },
				Outcomes = {
					"You gave them enough to leave. It stung, but the street stayed quiet.",
					"You lost some money, but avoided turning a stupid robbery into a real fight."
				}
			},
			{
				Text = "Chase them down",
				Chance = 50,
				SuccessEffects = { Money = 450, Reputation = 2 },
				FailEffects = { Health = -8, Money = -150, Happiness = -2 },
				SuccessText = "You caught them before they reached the next block and recovered more money than you lost.",
				FailText = "You chased them into a bad angle. They got away, and you took a hit for no reason."
			},
			{
				Text = "Scare them with cursed energy",
				Effects = { CursedEnergy = -2, Reputation = 1 },
				Outcomes = {
					"You let your cursed energy flare. They backed off before either of you had to commit.",
					"Your pressure was enough. They dropped the act and ran."
				}
			}
		}
	},
	{
		Id = "homeless_riddle",
		Title = "Riddle Under the Overpass",
		Body = "A homeless man waved you over and asked a strange riddle: 'I follow you under light, vanish in darkness, and never speak. What am I?'",
		Options = {
			{
				Text = "Answer: A shadow",
				Effects = { Smarts = 2, Money = 300 },
				Outcomes = {
					"He smiled like he already knew you would get it right, then handed you folded cash.",
					"You answered correctly. He laughed, called you sharp, and gave you money he swore he did not need."
				}
			},
			{
				Text = "Answer: A curse",
				Effects = { Smarts = 1, Happiness = -1 },
				Outcomes = {
					"He said that was wrong, but not stupid. The answer sat with you longer than expected.",
					"He shook his head, then told you sorcerers see curses in everything. He was not entirely wrong."
				}
			},
			{
				Text = "Ignore him",
				Effects = { Happiness = -1 },
				Outcomes = {
					"You kept walking. For some reason, the question followed you anyway.",
					"You ignored him, but his voice stayed in your head for the rest of the walk."
				}
			}
		}
	},
	{
		Id = "teacher_pop_quiz",
		Title = "Sudden Question",
		Body = "A Jujutsu High instructor stopped you in the hallway and asked how you would handle a curse stronger than the report claimed.",
		RequiresSchool = true,
		Options = {
			{
				Text = "Retreat and report the grade change",
				Effects = { Smarts = 2, Reputation = 1 },
				Outcomes = {
					"They looked satisfied. Correct reports save more lives than ego does.",
					"They said that answer was boring, which usually means correct."
				}
			},
			{
				Text = "Fight and prove yourself",
				Chance = 30,
				SuccessEffects = { Reputation = 3, CursedEnergy = 2 },
				FailEffects = { Smarts = -1, Happiness = -2 },
				SuccessText = "They liked the confidence, but warned you not to confuse courage with math.",
				FailText = "They shut that answer down fast. Apparently confidence is not a strategy."
			},
			{
				Text = "Ask what information the report left out",
				Effects = { Smarts = 3 },
				Outcomes = {
					"They smiled for half a second. You asked the question they wanted to hear.",
					"They told you that smart sorcerers interrogate the briefing before the curse."
				}
			}
		}
	},
	{
		Id = "dojo_parent_visit",
		Title = "A Parent Visits the Dojo",
		Body = "A nervous parent visited your dojo and asked if your clan could teach their child without turning them into a weapon.",
		RequiresClan = true,
		Options = {
			{
				Text = "Promise discipline before power",
				Effects = { ClanReputation = 2, Reputation = 1 },
				Outcomes = {
					"They left calmer than they arrived. Word of your dojo's discipline spread a little.",
					"Your answer made the dojo sound like a place with standards, not just ambition."
				}
			},
			{
				Text = "Tell them strength is all that matters",
				Effects = { ClanReputation = -1, Reputation = -1 },
				Outcomes = {
					"They left quickly. The dojo felt colder after that conversation.",
					"The answer sounded strong, but it did not make the parent trust you."
				}
			},
			{
				Text = "Offer a trial lesson",
				Chance = 55,
				SuccessEffects = { ClanReputation = 3, Money = 500 },
				FailEffects = { Happiness = -1 },
				SuccessText = "The trial lesson went well. The parent donated money and promised to return.",
				FailText = "The child panicked during the lesson. Nobody got hurt, but the visit ended awkwardly."
			}
		}
	},
	{
		Id = "cursed_object_vendor",
		Title = "Backstreet Vendor",
		Body = "A backstreet vendor claimed to have a cursed object wrapped in cloth. They offered it to you before saying the price.",
		Options = {
			{
				Text = "Buy it for study",
				Effects = { Money = -600, Smarts = 2, CursedEnergy = 2 },
				ItemReward = {
					Id = "cloth_wrapped_cursed_object",
					Name = "Cloth-Wrapped Cursed Object",
					Type = "Cursed Object",
					Rarity = "Rare",
					Description = "A weak but unusual cursed object bought from a backstreet vendor. It hums faintly when your cursed energy rises.",
					AcquiredFrom = "Backstreet Vendor"
				},
				Outcomes = {
					"The object was weak, but studying it taught you something useful. You stored the cloth-wrapped cursed object in your inventory.",
					"It was overpriced, but the residue inside gave you a better read on cursed objects. You kept the strange object in your inventory."
				}
			},
			{
				Text = "Threaten to report them",
				Chance = 45,
				SuccessEffects = { Reputation = 2, Money = 200 },
				FailEffects = { Reputation = -1, Happiness = -2 },
				SuccessText = "They folded fast and paid you to forget the stall existed.",
				FailText = "They laughed and vanished into the crowd. You looked dramatic for nothing."
			},
			{
				Text = "Walk away",
				Effects = { Smarts = 1 },
				Outcomes = {
					"You walked away. Not every strange offer needs to become your problem.",
					"You left it alone and felt smarter for not touching cursed junk from a stranger."
				}
			}
		}
	}
}

function getAvailableMonthlyEncounters(stats)
	local available = {}

	for _, encounter in ipairs(MONTHLY_LIFE_ENCOUNTERS) do
		local ok = true

		if encounter.RequiresSchool and stats.InJujutsuHigh ~= true then
			ok = false
		end

		if encounter.RequiresClan and stats.ClanFounded ~= true then
			ok = false
		end

		if ok then
			table.insert(available, encounter)
		end
	end

	return available
end

function beginMonthlyLifeEncounter(player, stats)
	if not player or not stats or stats.Alive == false then
		return false
	end

	if pendingMissions[player.UserId] then
		return false
	end

	local available = getAvailableMonthlyEncounters(stats)
	if #available <= 0 then
		return false
	end

	local encounter = pickRandom(available)
	local optionDisplay = {}

	for index, option in ipairs(encounter.Options or {}) do
		table.insert(optionDisplay, {
			Index = index,
			Text = option.Text
		})
	end

	if #optionDisplay <= 0 then
		return false
	end

	pendingMissions[player.UserId] = {
		Type = "LifeEncounter",
		Encounter = encounter,
		availableOptions = encounter.Options
	}

	showMissionSituation:FireClient(player, {
		MissionTitle = "Life Event",
		Title = encounter.Title,
		Body = encounter.Body,
		Options = optionDisplay
	})

	return true
end

local maybeBeginHigherUpsInvitation

function resolveMonthlyLifeEncounter(player, stats, encounter, option)
	ensureExtraStats(stats)

	local resultText = nil

	local gainedItem = nil

	if option.Chance then
		local chance = tonumber(option.Chance) or 50

		if stats.CursedTechnique ~= "None" then
			chance += 5
		end

		if (stats.Smarts or 0) >= 70 then
			chance += 8
		elseif (stats.Smarts or 0) <= 25 then
			chance -= 5
		end

		if (stats.Grade or "Non-Sorcerer") ~= "Non-Sorcerer" then
			chance += 5
		end

		chance = math.clamp(chance, 5, 95)

		if math.random(1, 100) <= chance then
			applyEncounterEffects(stats, option.SuccessEffects)
			if option.SuccessItemReward then
				gainedItem = addMysteryInventoryItem(stats, option.SuccessItemReward)
			end
			resultText = option.SuccessText or getEncounterOutcomeText(option, stats)
		else
			applyEncounterEffects(stats, option.FailEffects)
			if option.FailItemReward then
				gainedItem = addMysteryInventoryItem(stats, option.FailItemReward)
			end
			resultText = option.FailText or getEncounterOutcomeText(option, stats)
		end
	else
		applyEncounterEffects(stats, option.Effects)
		if option.ItemReward then
			gainedItem = addMysteryInventoryItem(stats, option.ItemReward)
		end
		resultText = getEncounterOutcomeText(option, stats)
	end

	if gainedItem then
		resultText = tostring(resultText or "") .. "\n<font color='#f0b955'><b>Inventory:</b></font> " .. tostring(gainedItem.Name or "Mysterious Item") .. " was added to your owned assets."
	end

	local title = encounter and encounter.Title or "Life Event"
	local message = "<font color='#78beff'><b>[ " .. string.upper(title) .. " ]</b></font> " .. tostring(resultText or "The situation ended quietly.")

	maybeBeginHigherUpsInvitation(player, stats)

	fireLifeUpdate(player, stats, message)
	saveStats(player)
end


function getSixMonthPassiveEventText(stats)
	ensureExtraStats(stats)

	local events = {}
	local monthName = getCurrentMonthName(stats)
	local technique = tostring(stats.CursedTechnique or "None")
	local innate = tostring(stats.InnateTechnique or "None")
	local grade = tostring(stats.Grade or "Non-Sorcerer")
	local clanName = tostring(stats.PlayerClanName or stats.Clan or stats.Origin or "your family")

	table.insert(events, "You spent the last six months keeping your cursed energy under control.")
	table.insert(events, "A small curse report crossed your desk, but it was cleared before you arrived.")
	table.insert(events, "You heard rumors about a stronger curse moving through the city.")
	table.insert(events, "Your name came up briefly in a Jujutsu High hallway conversation.")
	table.insert(events, "You noticed your reflexes getting sharper during routine drills.")
	table.insert(events, "A senior sorcerer warned you not to trust clean mission reports.")
	table.insert(events, "You passed a quiet evening reviewing old curse case notes.")
	table.insert(events, "Someone recognized you from a previous mission and quickly looked away.")

	if stats.InJujutsuHigh then
		table.insert(events, "Classes at Jujutsu High kept you busy between training and field reports.")
		table.insert(events, "A teacher watched your training for a few seconds longer than usual.")
		table.insert(events, "You caught younger students whispering about your latest mission.")
	end

	if grade ~= "Non-Sorcerer" then
		table.insert(events, "Your " .. grade .. " paperwork followed you longer than the mission did.")
		table.insert(events, "A low-level curse sighting reminded you that even easy jobs can go bad.")
	end

	if technique ~= "None" then
		table.insert(events, "You practiced small applications of " .. technique .. " where nobody could interrupt you.")
		table.insert(events, "Your control over " .. technique .. " felt steadier than it did half a year ago.")
	elseif innate ~= "None" and stats.TechniqueUsable ~= true then
		table.insert(events, "Your dormant innate technique stayed quiet, but you could still feel it under the surface.")
	end

	if stats.ClanFounded then
		table.insert(events, "The " .. clanName .. " dojo stayed active after sunset.")
		table.insert(events, "One of your students repeated your advice like it was clan doctrine.")
		table.insert(events, "A visitor asked whether the " .. clanName .. " clan was accepting new students.")
	end

	if (stats.MissionsCompleted or 0) > 0 then
		table.insert(events, "Your last mission report was still being talked about by the higher-ups.")
		table.insert(events, "A window-rattling curse rumor made the season feel less quiet than it looked.")
	end

	if (stats.Money or 0) < 1000 then
		table.insert(events, "Money felt tight this season, even by sorcerer standards.")
	elseif (stats.Money or 0) >= 25000 then
		table.insert(events, "Your savings gave you room to think bigger than survival.")
	end

	if (stats.Health or 100) < 35 then
		table.insert(events, "Your body reminded you that recovery is not optional.")
	end

	if (stats.Happiness or 100) < 35 then
		table.insert(events, "The last few months felt heavier than usual, but you kept moving.")
	end

	return events[math.random(1, #events)]
end

function findHigherUpsMissionCompanion(stats)
	ensureExtraStats(stats)

	local best = nil
	local bestScore = -1
	local bannedRoles = {
		Mother = true,
		Father = true,
		Caretaker = true,
		Ward = true,
	}

	for _, relationship in ipairs(stats.Relationships or {}) do
		if relationship.Alive ~= false and not bannedRoles[tostring(relationship.Role or "")] then
			local respect = tonumber(relationship.Respect) or 0
			if respect >= 80 then
				local score = respect + (tonumber(relationship.Trust) or 0) + (tonumber(relationship.Bond) or 0)
				if score > bestScore then
					best = relationship
					bestScore = score
				end
			end
		end
	end

	return best
end

function maybeBeginHigherUpsInvitation(player, stats)
	if not player or not stats or stats.Alive == false then
		return false
	end

	ensureExtraStats(stats)

	if pendingMissions[player.UserId] then
		return false
	end

	if stats.HigherUps.InvitationTriggered then
		return false
	end

	if (stats.Reputation or 0) < 250 then
		return false
	end

	if getGradeValue(stats.Grade) < getGradeValue("Semi-Grade 1") then
		return false
	end

	stats.HigherUps.InvitationTriggered = true

	local options = {
		{ Index = 1, Text = "Accept the meeting", HigherUpsChoice = "accept_meeting" },
		{ Index = 2, Text = "Ignore the summons", HigherUpsChoice = "ignore_meeting" },
	}

	pendingMissions[player.UserId] = {
		Type = "HigherUpsInvite",
		availableOptions = options,
	}

	showMissionSituation:FireClient(player, {
		MissionTitle = "Higher-Ups Summons",
		Title = "A Sealed Letter",
		Body = "Your reputation has reached the jujutsu higher-ups. A sealed letter arrives with your name written in black ink. Inside, you are invited to a private meeting about a classified escort mission.",
		Options = options,
	})

	return true
end

function beginHigherUpsMissionOffer(player, stats)
	ensureExtraStats(stats)

	local options = {
		{ Index = 1, Text = "Accept Vessel Escort", HigherUpsChoice = "accept_vessel_escort" },
		{ Index = 2, Text = "Refuse the mission", HigherUpsChoice = "refuse_vessel_escort" },
	}

	pendingMissions[player.UserId] = {
		Type = "HigherUpsMissionOffer",
		availableOptions = options,
	}

	showMissionSituation:FireClient(player, {
		MissionTitle = "Higher-Up Mission 1/5",
		Title = "Vessel Escort",
		Body = "The higher-ups explain the assignment: a rare vessel tied to an unstable barrier ritual must be protected until transfer. Several curse users want the vessel taken before the ritual can happen.",
		Options = options,
	})
end

function beginVesselEscortDialogue(player, stats)
	ensureExtraStats(stats)

	local companion = findHigherUpsMissionCompanion(stats)
	local companionLine = "No one stepped forward. You accepted the escort alone."

	if companion then
		stats.HigherUps.VesselEscortCompanionName = companion.Name
		companionLine = tostring(companion.Name) .. " insisted on joining you for the escort mission."
	else
		stats.HigherUps.VesselEscortCompanionName = nil
	end

	local options = {
		{ Index = 1, Text = "Then survive first. Decide later.", VesselChoice = "survive_first", Effects = { VesselTrust = 2, Smarts = 1 } },
		{ Index = 2, Text = "I'll protect you. That's the mission.", VesselChoice = "protect_you", Effects = { VesselTrust = 4, Happiness = 1 } },
		{ Index = 3, Text = "People like us don't get normal lives.", VesselChoice = "no_normal", Effects = { VesselTrust = -1, Reputation = 1 } },
		{ Index = 4, Text = "Say nothing.", VesselChoice = "silence", Effects = { VesselTrust = -2, Smarts = 1 } },
	}

	pendingMissions[player.UserId] = {
		Type = "VesselEscortDialogue",
		availableOptions = options,
	}

	showMissionSituation:FireClient(player, {
		MissionTitle = "Higher-Up Mission 1/5",
		Title = "The Vessel",
		Body = companionLine .. "\n\nThe vessel sits beside you in the back of the car, staring at the passing city lights.\n\n\"I don't even know if I want this life.\"",
		Options = options,
	})
end

function resolveHigherUpsInvitationChoice(player, stats, option)
	ensureExtraStats(stats)

	if option and option.HigherUpsChoice == "accept_meeting" then
		stats.HigherUps.InvitationAccepted = true
		stats.HigherUps.MissionChainUnlocked = true
		stats.HigherUps.CurrentMission = math.max(1, tonumber(stats.HigherUps.CurrentMission) or 0)

		fireLifeUpdate(player, stats, "<font color='#f0b955'><b>[ HIGHER-UPS ]</b></font> You accepted the private meeting. The room was quiet, sealed, and colder than it needed to be.")
		saveStats(player)
		beginHigherUpsMissionOffer(player, stats)
		return
	end

	stats.HigherUps.InvitationDeclined = true
	stats.Reputation = (stats.Reputation or 0 - 3)

	fireLifeUpdate(player, stats, "<font color='#f0b955'><b>[ HIGHER-UPS ]</b></font> You ignored the summons. The higher-ups did not chase you, but your name became quieter in certain rooms. (-3 Reputation)")
	saveStats(player)
end

function resolveHigherUpsMissionOffer(player, stats, option)
	ensureExtraStats(stats)

	if option and option.HigherUpsChoice == "accept_vessel_escort" then
		stats.HigherUps.MissionChainUnlocked = true
		stats.HigherUps.CurrentMission = math.max(1, tonumber(stats.HigherUps.CurrentMission) or 0)
		fireLifeUpdate(player, stats, "<font color='#78beff'><b>[ VESSEL ESCORT ]</b></font> You accepted Higher-Up Mission 1/5. The vessel was placed under your protection before sunset.")
		saveStats(player)
		beginVesselEscortDialogue(player, stats)
		return
	end

	stats.HigherUps.MissionChainUnlocked = true
	stats.HigherUps.CurrentMission = math.max(1, tonumber(stats.HigherUps.CurrentMission) or 0)
	stats.Reputation = (stats.Reputation or 0 - 5)

	fireLifeUpdate(player, stats, "<font color='#78beff'><b>[ VESSEL ESCORT ]</b></font> You refused the escort assignment. The higher-ups marked you as unreliable for classified work. (-5 Reputation)")
	saveStats(player)
end

function resolveVesselEscortDialogue(player, stats, option)
	ensureExtraStats(stats)

	local effects = option and option.Effects or {}
	local vesselTrustGain = tonumber(effects.VesselTrust) or 0
	stats.HigherUps.VesselTrust = math.clamp((stats.HigherUps.VesselTrust or 0) + vesselTrustGain, -100, 100)

	applyEncounterEffects(stats, effects)

	local companionBonus = 0
	local companionName = stats.HigherUps.VesselEscortCompanionName
	if companionName and companionName ~= "" then
		companionBonus = 45
	end

	local vesselTrustBonus = math.max(0, stats.HigherUps.VesselTrust or 0) * 2
	local gradeBonus = getGradeValue(stats.Grade) * 18
	local playerPower = calculatePlayerPower(stats) + gradeBonus + companionBonus + vesselTrustBonus + math.random(15, 60)
	local bossPower = 235 + math.random(0, 70)

	local opening = "The escort route collapsed into chaos. Curse users attacked in waves, but most of them were only desperate. The final attacker was different: a silent assassin with no cursed energy presence, only speed, pressure, and killing intent."

	local resultText = ""
	if playerPower >= bossPower then
		stats.HigherUps.VesselEscortCompleted = true
		stats.HigherUps.HeavenlyRestrictedAchievement = true
		stats.MetaProgress = stats.MetaProgress or {}
		stats.MetaProgress.HeavenlyRestrictionBoost = true
		stats.Reputation = (stats.Reputation or 0 + 18)
		stats.Money = math.max(0, (stats.Money or 0) + 15000)
		stats.TeacherRecommendations = (stats.TeacherRecommendations or 0) + 1
		stats.Happiness = math.clamp((stats.Happiness or 100) + 5, 0, 100)

		resultText = opening .. "\n\nYou defeated the assassin and completed the escort. The higher-ups called it acceptable. That was probably the closest thing to praise they had.\n\n<font color='#f0b955'><b>[ ACHIEVEMENT UNLOCKED ]</b></font> Heavenly Restricted\n<font color='#f0b955'><b>[ LEGACY EFFECT ]</b></font> Future lives now have a higher chance to be born with Heavenly Restriction.\nRewards: +$15,000, +18 Reputation, +1 Teacher Recommendation."

		fireMajorPopup(
			player,
			"ACHIEVEMENT UNLOCKED",
			"You defeated the Heavenly Restricted assassin during the Vessel Escort assignment.",
			"Heavenly Restricted",
			"Future lives have a higher Heavenly Restriction chance."
		)
	else
		stats.Health = math.clamp((stats.Health or 100) - math.random(12, 24), 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) - 8, 0, 100)
		stats.Reputation = (stats.Reputation or 0 - 8)
		stats.MissionsFailed = (stats.MissionsFailed or 0) + 1

		resultText = opening .. "\n\nThe assassin broke through your guard. You survived, but the escort collapsed and the higher-ups lost confidence in you.\nPenalties: -8 Reputation, Health damage, +1 Mission Failed."

		if stats.Health <= 0 then
			stats.Alive = false
			resultText = resultText .. "\nYour body gave out after the mission." 
		end
	end

	fireLifeUpdate(player, stats, "<font color='#78beff'><b>[ HIGHER-UP MISSION 1/5 ]</b></font> " .. resultText)
	saveStats(player)
end


function clearExpiredPendingMission(player, stats)
	if not player then
		return false
	end

	local pending = pendingMissions[player.UserId]

	if not pending then
		return false
	end

	local createdAt = tonumber(pending.CreatedAt) or os.clock()
	local age = os.clock() - createdAt

	if age < 0 then
		return false
	end

	pendingMissions[player.UserId] = nil

	if stats then
		fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ SYSTEM ]</b></font> A stuck mission choice was cleared. You can age again.")
	end

	return true
end


----------------------------------------------------------------
-- PHASE 2A: CURSE LIFE - SORCERER ATTACKS
----------------------------------------------------------------

function stripUnregisteredCurseGradePrefix(grade)
	grade = tostring(grade or "Grade 4 Cursed Spirit")
	if string.sub(grade, 1, #"Unregistered ") == "Unregistered " then
		return string.sub(grade, #"Unregistered " + 1)
	end
	if string.sub(grade, 1, #"Estimated ") == "Estimated " then
		return string.sub(grade, #"Estimated " + 1)
	end
	return grade
end

function makeUnregisteredCurseGrade(grade)
	grade = stripUnregisteredCurseGradePrefix(grade)
	if grade == "None" or grade == "" then
		grade = "Grade 3 Cursed Spirit"
	end
	if grade == "Disaster-Class Cursed Spirit" or grade == "Disaster Curse" then
		grade = "Special Grade Cursed Spirit"
	end
	return "Unregistered " .. grade
end

function makeOfficialCurseGrade(grade)
	grade = stripUnregisteredCurseGradePrefix(grade)
	if grade == "None" or grade == "" then
		grade = "Grade 3 Cursed Spirit"
	end
	if grade == "Disaster-Class Cursed Spirit" or grade == "Disaster Curse" then
		grade = "Special Grade Cursed Spirit"
	end
	return grade
end

function normalizeCurseGradeAndThreatClass(stats)
	if not stats then return end
	local grade = tostring(stats.CurseGrade or "None")
	local threatClass = tostring(stats.CurseThreatClass or "None")

	local oldToNew = {
		["Grade 4 Curse"] = "Grade 4 Cursed Spirit",
		["Grade 3 Curse"] = "Grade 3 Cursed Spirit",
		["Grade 2 Curse"] = "Grade 2 Cursed Spirit",
		["Grade 1 Curse"] = "Grade 1 Cursed Spirit",
		["Special Grade Curse"] = "Special Grade Cursed Spirit",
		["Unregistered Grade 4 Curse"] = "Unregistered Grade 4 Cursed Spirit",
		["Unregistered Grade 3 Curse"] = "Unregistered Grade 3 Cursed Spirit",
		["Unregistered Grade 2 Curse"] = "Unregistered Grade 2 Cursed Spirit",
		["Unregistered Grade 1 Curse"] = "Unregistered Grade 1 Cursed Spirit",
		["Unregistered Special Grade Curse"] = "Unregistered Special Grade Cursed Spirit",
	}

	if oldToNew[grade] then
		grade = oldToNew[grade]
	end

	if grade == "Disaster Curse" or grade == "Disaster-Class Cursed Spirit" or grade == "Unregistered Disaster-Class Cursed Spirit" then
		grade = "Special Grade Cursed Spirit"
		threatClass = "Disaster"
	end

	local isUnregisteredGrade = string.sub(grade, 1, #"Unregistered ") == "Unregistered "
	local officialGrade = makeOfficialCurseGrade(grade)

	if stats.CurseClassified == true then
		grade = officialGrade
	else
		if grade == "None" or grade == "" or not isUnregisteredGrade then
			grade = makeUnregisteredCurseGrade(officialGrade)
		end
	end

	stats.CurseGrade = grade
	stats.CurseThreatClass = threatClass
end


local CURSE_TERRITORIES = {
	"Abandoned School",
	"Last Train Station",
	"Hospital Basement",
	"Old Apartment Complex",
	"Forest Shrine",
	"Construction Site",
	"Sewer Tunnel",
	"Rural Village",
	"Closed Mall",
	"Apartment Stairwell",
	"Burned-Out Theater",
	"Underpass"
}

local CURSE_RUMOR_TITLES = {
	"The Mirror Thing",
	"The Station Voice",
	"The Basement Curse",
	"The Red Hallway",
	"The Thing Behind You",
	"The Shrine Hunger",
	"The Stairwell Knock",
	"The Train Shadow",
	"The Hospital Whisper",
	"The Underpass Face",
	"The Hallway That Breathes",
	"The Thing in the Walls"
}

local HUNTER_FIRST_NAMES = {
	"Ren", "Akio", "Daiki", "Kaito", "Riku", "Toma", "Yuto", "Shin", "Kei", "Hana",
	"Yuna", "Emi", "Mei", "Aiko", "Reina", "Mira", "Yuki", "Natsuki", "Kaede", "Tomoe"
}

local HUNTER_FAMILY_NAMES = {
	"Tachibana", "Morikage", "Kurosawa", "Amahara", "Shinkawa", "Yamashiro", "Kisaragi", "Tengawa", "Higashino", "Kaneshima"
}

function getRandomHunterName()
	return pickRandom(HUNTER_FIRST_NAMES) .. " " .. pickRandom(HUNTER_FAMILY_NAMES)
end

function ensureCursedSpiritFlavor(stats)
	if not stats then
		return
	end

	local curseLife = isCurseLife(stats)

	if curseLife then
		if not stats.CurseTerritory or tostring(stats.CurseTerritory) == "" or tostring(stats.CurseTerritory) == "None" then
			stats.CurseTerritory = pickRandom(CURSE_TERRITORIES)
		end
		if not stats.CurseRumor or tostring(stats.CurseRumor) == "" or tostring(stats.CurseRumor) == "None" then
			stats.CurseRumor = pickRandom(CURSE_RUMOR_TITLES)
		end
		stats.CurseHunger = math.clamp(tonumber(stats.CurseHunger) or 35, 0, 100)
		stats.SocietyAttention = math.clamp(tonumber(stats.SocietyAttention) or tonumber(stats.ExorcismRisk) or 0, 0, 100)
		stats.CurseFearLevel = math.clamp(tonumber(stats.CurseFearLevel) or math.floor((tonumber(stats.CurseThreat) or 0) / 2), 0, 9999)
		stats.CurseTerritoryControl = math.clamp(tonumber(stats.CurseTerritoryControl) or 10, 0, 100)
		stats.CurseRumorSpread = math.clamp(tonumber(stats.CurseRumorSpread) or 0, 0, 100)
		stats.CiviliansTerrified = math.max(0, tonumber(stats.CiviliansTerrified) or 0)
		stats.HuntersEscaped = math.max(0, tonumber(stats.HuntersEscaped) or 0)
	else
		stats.CurseHunger = math.clamp(tonumber(stats.CurseHunger) or 0, 0, 100)
		stats.SocietyAttention = math.clamp(tonumber(stats.SocietyAttention) or 0, 0, 100)
		stats.CurseFearLevel = math.max(0, tonumber(stats.CurseFearLevel) or 0)
		stats.CurseTerritoryControl = math.clamp(tonumber(stats.CurseTerritoryControl) or 0, 0, 100)
		stats.CurseRumorSpread = math.clamp(tonumber(stats.CurseRumorSpread) or 0, 0, 100)
		stats.CiviliansTerrified = math.max(0, tonumber(stats.CiviliansTerrified) or 0)
		stats.HuntersEscaped = math.max(0, tonumber(stats.HuntersEscaped) or 0)
		stats.CurseTerritory = stats.CurseTerritory or "None"
		stats.CurseRumor = stats.CurseRumor or "None"
	end
end

function addCurseHunger(stats, amount)
	ensureCursedSpiritFlavor(stats)
	stats.CurseHunger = math.clamp((tonumber(stats.CurseHunger) or 0) + (tonumber(amount) or 0), 0, 100)
	return stats.CurseHunger
end

function reduceCurseHunger(stats, amount)
	return addCurseHunger(stats, -(tonumber(amount) or 0))
end

function addSocietyAttention(stats, amount)
	ensureCursedSpiritFlavor(stats)
	local gain = tonumber(amount) or 0
	stats.SocietyAttention = math.clamp((tonumber(stats.SocietyAttention) or 0) + gain, 0, 100)
	if gain > 0 then
		stats.ExorcismRisk = math.clamp((tonumber(stats.ExorcismRisk) or 0) + math.floor(gain / 3), 0, 100)
	end
	return stats.SocietyAttention
end

function getCurseHungerText(stats)
	local hunger = tonumber(stats and stats.CurseHunger) or 0
	if hunger >= 85 then return "Starving"
	elseif hunger >= 65 then return "Hungry"
	elseif hunger >= 35 then return "Restless"
	elseif hunger >= 15 then return "Stable" end
	return "Sated"
end

function applyCursedSpiritActivityFlavor(stats, activityKey)
	ensureCursedSpiritFlavor(stats)

	local territory = tostring(stats.CurseTerritory or "your territory")
	local rumor = tostring(stats.CurseRumor or "the curse")
	local roll = math.random(1, 100)

	if activityKey == "absorb_fear" then
		if roll <= 25 then
			stats.CurseRumorSpread = math.clamp((stats.CurseRumorSpread or 0) + math.random(4, 9), 0, 100)
			stats.CiviliansTerrified = (stats.CiviliansTerrified or 0) + math.random(2, 8)
			return "A rumor about <b>" .. rumor .. "</b> spread around <b>" .. territory .. "</b>. The fear tasted stronger than usual."
		elseif roll <= 50 then
			addSocietyAttention(stats, math.random(2, 5))
			return "Someone recorded strange audio near <b>" .. territory .. "</b>. The clip spread online before vanishing."
		elseif roll <= 75 then
			stats.CurseTerritoryControl = math.clamp((stats.CurseTerritoryControl or 0) + math.random(2, 5), 0, 100)
			return "The walls of <b>" .. territory .. "</b> felt more like part of your body."
		end
		return "The fear was weak, but it still fed the shape of your cursed body."
	elseif activityKey == "hide" then
		if roll <= 35 then
			stats.CurseTerritoryControl = math.clamp((stats.CurseTerritoryControl or 0) + math.random(1, 4), 0, 100)
			return "You folded yourself into <b>" .. territory .. "</b> so cleanly that even the air forgot you were there."
		elseif roll <= 65 then
			return "A barrier reader passed near <b>" .. territory .. "</b>, but they only found a cold trace."
		end
		addSocietyAttention(stats, 1)
		return "You hid most of your cursed energy, but a small residue still leaked into the area."
	elseif activityKey == "remnants" then
		if roll <= 30 then
			stats.CurseEvolutionProgress = math.max(0, (stats.CurseEvolutionProgress or 0) + math.random(3, 7))
			return "You devoured a weaker curse hiding in <b>" .. territory .. "</b>. Its final panic strengthened your form."
		elseif roll <= 60 then
			stats.CurseFearLevel = math.max(0, (stats.CurseFearLevel or 0) + math.random(2, 6))
			return "Other small curses started avoiding your territory. That silence made you feel larger."
		end
		return "The remnants fought back long enough to make the hunt messy."
	elseif activityKey == "territory" then
		stats.CurseTerritory = pickRandom(CURSE_TERRITORIES)
		stats.CurseTerritoryControl = math.random(12, 28)
		stats.CurseRumor = pickRandom(CURSE_RUMOR_TITLES)
		return "You abandoned your old haunt and claimed <b>" .. tostring(stats.CurseTerritory) .. "</b>. Locals have started calling you <b>" .. tostring(stats.CurseRumor) .. "</b>."
	elseif activityKey == "rumor" then
		if roll <= 20 then
			stats.CurseRumor = pickRandom(CURSE_RUMOR_TITLES)
			stats.CurseRumorSpread = math.clamp((stats.CurseRumorSpread or 0) + math.random(12, 22), 0, 100)
			return "Your rumor changed shape. People now whisper about <b>" .. tostring(stats.CurseRumor) .. "</b>."
		elseif roll <= 65 then
			stats.CurseRumorSpread = math.clamp((stats.CurseRumorSpread or 0) + math.random(8, 18), 0, 100)
			return "The story of <b>" .. rumor .. "</b> spread through school hallways and late-night group chats."
		end
		addSocietyAttention(stats, math.random(2, 6))
		return "The rumor spread too cleanly. Jujutsu Society noticed the pattern."
	elseif activityKey == "feed_negative" then
		if roll <= 30 then
			return "You fed from a grieving crowd without showing yourself. Nobody knew why the air felt heavier."
		elseif roll <= 65 then
			stats.CiviliansTerrified = (stats.CiviliansTerrified or 0) + math.random(1, 5)
			return "A few people saw your outline for half a second. Their fear followed you home."
		end
		addSocietyAttention(stats, math.random(3, 7))
		return "You overfed and left cursed residue behind. Someone will notice."
	end

	return "Your cursed spirit life shifted quietly."
end

function rollCursedSpiritLifeEvent(player, stats)
	if not isCurseLife(stats) or stats.Alive == false then
		return ""
	end

	ensureCursedSpiritFlavor(stats)

	local territory = tostring(stats.CurseTerritory or "your territory")
	local rumor = tostring(stats.CurseRumor or "the local curse")
	local hunger = tonumber(stats.CurseHunger) or 0
	local roll = math.random(1, 100)
	local message = ""

	if hunger >= 80 and roll <= 45 then
		local ceGain = math.random(8, 18)
		local threatGain = math.random(3, 8)
		stats.CursedEnergy += ceGain
		stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + threatGain)
		stats.CurseEvolutionProgress = math.max(0, (stats.CurseEvolutionProgress or 0) + math.random(2, 6))
		reduceCurseHunger(stats, math.random(18, 32))
		addSocietyAttention(stats, math.random(3, 8))
		stats.CiviliansTerrified = (stats.CiviliansTerrified or 0) + math.random(3, 9)
		message = "<font color='#b27aff'><b>[ HUNGER ]</b></font> Your cursed body starved until restraint broke. You fed from a cluster of fear near <b>" .. territory .. "</b>."
		message ..= "\nGained <b>+" .. tostring(ceGain) .. " CE</b>, <b>+" .. tostring(threatGain) .. " Threat</b>. Hunger fell to <b>" .. tostring(stats.CurseHunger) .. "%</b>."
	elseif roll <= 20 then
		local spread = math.random(6, 14)
		stats.CurseRumorSpread = math.clamp((stats.CurseRumorSpread or 0) + spread, 0, 100)
		stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + math.random(1, 4))
		stats.CurseFearLevel = math.max(0, (stats.CurseFearLevel or 0) + math.random(3, 8))
		message = "<font color='#b27aff'><b>[ RUMOR ]</b></font> Students started daring each other to search for <b>" .. rumor .. "</b> near <b>" .. territory .. "</b>."
		message ..= "\nYour name spread without you needing to move. Rumor Spread <b>+" .. tostring(spread) .. "%</b>."
	elseif roll <= 38 then
		local riskDrop = math.random(2, 7)
		stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) - riskDrop, 0, 100)
		stats.SocietyAttention = math.clamp((stats.SocietyAttention or 0) - math.random(1, 4), 0, 100)
		message = "<font color='#7aa2ff'><b>[ TERRITORY ]</b></font> Rain washed over <b>" .. territory .. "</b>, hiding your residue from patrols."
		message ..= "\nExorcism Risk <b>-" .. tostring(riskDrop) .. "%</b>."
	elseif roll <= 55 then
		local controlGain = math.random(3, 9)
		stats.CurseTerritoryControl = math.clamp((stats.CurseTerritoryControl or 0) + controlGain, 0, 100)
		stats.CurseEvolutionProgress = math.max(0, (stats.CurseEvolutionProgress or 0) + math.random(1, 4))
		message = "<font color='#b27aff'><b>[ HAUNT ]</b></font> Your presence sank deeper into <b>" .. territory .. "</b>. Doors opened wrong. Lights flickered before anyone touched them."
		message ..= "\nTerritory Control <b>+" .. tostring(controlGain) .. "%</b>."
	elseif roll <= 72 then
		local rivalDamage = math.random(0, 10)
		local ceGain = math.random(5, 14)
		stats.CursedEnergy += ceGain
		stats.Health = math.clamp((stats.Health or 100) - rivalDamage, 0, 100)
		stats.CurseEvolutionProgress = math.max(0, (stats.CurseEvolutionProgress or 0) + math.random(2, 7))
		message = "<font color='#e53935'><b>[ INTRUDER ]</b></font> A weaker cursed spirit wandered into <b>" .. territory .. "</b>. You consumed what was left of it."
		message ..= "\nGained <b>+" .. tostring(ceGain) .. " CE</b>."
		if rivalDamage > 0 then
			message ..= " Health <b>-" .. tostring(rivalDamage) .. "</b>."
		end
	elseif roll <= 88 then
		local attention = math.random(4, 10)
		addSocietyAttention(stats, attention)
		message = "<font color='#e53935'><b>[ INVESTIGATION ]</b></font> An assistant manager photographed residue near <b>" .. territory .. "</b>."
		message ..= "\nSociety Attention <b>+" .. tostring(attention) .. "%</b>."
	else
		local oldTerritory = territory
		stats.CurseTerritory = pickRandom(CURSE_TERRITORIES)
		stats.CurseTerritoryControl = math.random(8, 20)
		stats.CurseRumor = pickRandom(CURSE_RUMOR_TITLES)
		stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) - math.random(1, 5))
		message = "<font color='#b27aff'><b>[ NEW HAUNT ]</b></font> Pressure forced you away from <b>" .. oldTerritory .. "</b>. You settled inside <b>" .. tostring(stats.CurseTerritory) .. "</b>."
		message ..= "\nThe locals have started calling you <b>" .. tostring(stats.CurseRumor) .. "</b>."
	end

	return message
end

local CURSE_GRADE_VALUES = {
	["Grade 4 Cursed Spirit"] = 1,
	["Grade 4 Curse"] = 1,
	["Grade 3 Cursed Spirit"] = 2,
	["Grade 3 Curse"] = 2,
	["Grade 2 Cursed Spirit"] = 3,
	["Grade 2 Curse"] = 3,
	["Grade 1 Cursed Spirit"] = 4,
	["Grade 1 Curse"] = 4,
	["Special Grade Cursed Spirit"] = 5,
	["Special Grade Curse"] = 5,
	["Disaster-Class Cursed Spirit"] = 5,
	["Disaster Curse"] = 5,
}

local CURSE_GRADE_BONUSES = {
	["Grade 4 Cursed Spirit"] = 35,
	["Grade 4 Curse"] = 35,
	["Grade 3 Cursed Spirit"] = 65,
	["Grade 3 Curse"] = 65,
	["Grade 2 Cursed Spirit"] = 105,
	["Grade 2 Curse"] = 105,
	["Grade 1 Cursed Spirit"] = 165,
	["Grade 1 Curse"] = 165,
	["Special Grade Cursed Spirit"] = 260,
	["Special Grade Curse"] = 260,
	["Disaster-Class Cursed Spirit"] = 260,
	["Disaster Curse"] = 260,
}

local SORCERER_ATTACK_BONUSES = {
	["Grade 4"] = 40,
	["Semi-Grade 3"] = 55,
	["Grade 3"] = 70,
	["Semi-Grade 2"] = 90,
	["Grade 2"] = 110,
	["Semi-Grade 1"] = 140,
	["Grade 1"] = 170,
	["Special Grade 1"] = 230,
	["Special Grade"] = 280,
}

local SORCERER_ATTACK_GRADE_LIST = {
	"Grade 4",
	"Semi-Grade 3",
	"Grade 3",
	"Semi-Grade 2",
	"Grade 2",
	"Semi-Grade 1",
	"Grade 1",
	"Special Grade",
}

function getCurseGradeValue(curseGrade)
	local grade = makeOfficialCurseGrade(curseGrade)
	return CURSE_GRADE_VALUES[grade] or CURSE_GRADE_VALUES[tostring(curseGrade or "Grade 4 Cursed Spirit")] or 1
end

function getCurseGradeBonus(curseGrade)
	local grade = makeOfficialCurseGrade(curseGrade)
	return CURSE_GRADE_BONUSES[grade] or CURSE_GRADE_BONUSES[tostring(curseGrade or "Grade 4 Cursed Spirit")] or 35
end

function getSorcererAttackBonus(sorcererGrade)
	return SORCERER_ATTACK_BONUSES[tostring(sorcererGrade or "Grade 4")] or 40
end

function getSorcererGradeForCurseAttack(stats)
	normalizeCursedSocietyState(stats)

	local threat = tonumber(stats.CurseThreat) or 0
	local risk = tonumber(stats.ExorcismRisk) or 0
	local curseGradeValue = getCurseGradeValue(stats.CurseGrade)
	local pressure = threat + risk + (curseGradeValue * 12) + math.random(1, 40)

	if pressure >= 135 and math.random(1, 100) <= 12 then
		return "Special Grade"
	elseif pressure >= 115 then
		return "Grade 1"
	elseif pressure >= 90 then
		return pickRandom({ "Semi-Grade 1", "Grade 1" })
	elseif pressure >= 70 then
		return pickRandom({ "Grade 2", "Semi-Grade 1" })
	elseif pressure >= 45 then
		return pickRandom({ "Grade 3", "Semi-Grade 2", "Grade 2" })
	elseif pressure >= 25 then
		return pickRandom({ "Semi-Grade 3", "Grade 3" })
	end

	return pickRandom({ "Grade 4", "Semi-Grade 3" })
end

function calculateCurseAttackPower(stats)
	normalizeCursedSocietyState(stats)

	local power = 0
	power += (tonumber(stats.CursedEnergy) or 0) * 0.35
	power += (tonumber(stats.TechniqueMastery) or 0) * 1.5
	power += getCurseGradeBonus(stats.CurseGrade)
	power += (tonumber(stats.CurseThreat) or 0) * 0.8
	power += (tonumber(stats.Health) or 100) * 0.5
	power += math.random(1, 45)

	local evolution = tostring(stats.CurseEvolution or "Dormant")
	if evolution == "Evolving" then
		power += 20
	elseif evolution == "Matured" then
		power += 40
	elseif evolution == "Disaster Seed" then
		power += 70
	elseif evolution == "Disaster" then
		power += 110
	end

	if tostring(stats.CursedTechnique or "None") ~= "None" then
		power += 25
	end

	return power
end

function calculateSorcererAttackPower(sorcererGrade, eventDifficulty)
	local power = getSorcererAttackBonus(sorcererGrade)
	power += tonumber(eventDifficulty) or 0
	power += math.random(1, 55)
	return power
end

function getCurseAttackChance(stats)
	if not isCurseLife(stats) or stats.Alive == false then
		return 0
	end

	if (tonumber(stats.Age) or 0) < 8 then
		return 0
	end

	if (tonumber(stats.SorcererAttackCooldown) or 0) > 0 then
		return 0
	end

	local chance = 8
	chance += math.clamp(math.floor((tonumber(stats.CurseThreat) or 0) / 8), 0, 12)
	chance += math.clamp(math.floor((tonumber(stats.ExorcismRisk) or 0) / 10), 0, 10)
	chance += math.clamp(getCurseGradeValue(stats.CurseGrade) - 1, 0, 5)

	if tostring(stats.SocietyStatus or "") == "Known Curse" then
		chance += 5
	elseif tostring(stats.SocietyStatus or "") == "Disaster Threat" then
		chance += 10
	end

	return math.clamp(chance, 0, 38)
end

function beginCurseSorcererAttack(player, stats, reasonText)
	if not player or not stats or stats.Alive == false then
		return false
	end

	if pendingMissions[player.UserId] then
		return false
	end

	if not isCurseLife(stats) then
		return false
	end

	normalizeCursedSocietyState(stats)

	local sorcererGrade = getSorcererGradeForCurseAttack(stats)
	local eventDifficulty = math.random(0, 25) + math.floor((tonumber(stats.ExorcismRisk) or 0) / 4)
	local hunterName = getRandomHunterName()
	local territory = tostring(stats.CurseTerritory or "your territory")
	local rumor = tostring(stats.CurseRumor or "your rumor")

	local options = {
		{ Index = 1, Text = "Fight them head-on", CurseAttackChoice = "fight" },
		{ Index = 2, Text = "Hide your cursed energy", CurseAttackChoice = "hide" },
		{ Index = 3, Text = "Ambush them first", CurseAttackChoice = "ambush" },
		{ Index = 4, Text = "Flee the area", CurseAttackChoice = "flee" },
	}

	pendingMissions[player.UserId] = {
		Type = "CurseSorcererAttack",
		SorcererGrade = sorcererGrade,
		EventDifficulty = eventDifficulty,
		ReasonText = reasonText or "A sorcerer tracked your cursed energy.",
		HunterName = hunterName,
		Territory = territory,
		Rumor = rumor,
		availableOptions = options,
	}

	local bodyText = tostring(reasonText or "A sorcerer has followed your cursed energy trail.")
	bodyText ..= "\n\n<b>" .. hunterName .. "</b>, a <b>" .. sorcererGrade .. "</b> sorcerer, entered <b>" .. territory .. "</b>."
	bodyText ..= " They knew the rumor: <b>" .. rumor .. "</b>."
	bodyText ..= "\nThey are here to exorcise you before the story spreads further."

	showMissionSituation:FireClient(player, {
		MissionTitle = "Cursed Spirit Life",
		Title = sorcererGrade .. " Sorcerer Hunt",
		Body = bodyText,
		Options = options,
	})

	return true
end

function maybeBeginCurseSorcererAttack(player, stats, reasonText, forceRoll)
	if not player or not stats or stats.Alive == false then
		return false
	end

	if not isCurseLife(stats) then
		return false
	end

	if pendingMissions[player.UserId] then
		return false
	end

	local chance = getCurseAttackChance(stats)
	if forceRoll == true or (chance > 0 and math.random(1, 100) <= chance) then
		return beginCurseSorcererAttack(player, stats, reasonText)
	end

	return false
end

function formatCurseAttackResultPrefix(sorcererGrade, hunterName, territory, rumor)
	local name = tostring(hunterName or "A sorcerer")
	local place = tostring(territory or "your territory")
	local title = tostring(rumor or "your rumor")
	return "<font color='#e53935'><b>[ SORCERER HUNT ]</b></font> <b>" .. name .. "</b>, a <b>" .. tostring(sorcererGrade or "sorcerer") .. "</b> sorcerer, tracked <b>" .. title .. "</b> to <b>" .. place .. "</b>."
end

function registerCursedSpiritAfterKill(stats, killedBefore, sorcererGrade, hunterName)
	if not stats then return "" end
	local killedAfter = tonumber(stats.SorcerersKilled) or 0
	if stats.CurseClassified == true or killedAfter <= math.max(0, tonumber(killedBefore) or 0) then
		return ""
	end

	stats.CurseClassified = true
	stats.CurseGrade = makeOfficialCurseGrade(stats.CurseGrade)
	stats.SocietyStatus = "Registered Cursed Spirit"
	stats.SocietyAttention = math.clamp((tonumber(stats.SocietyAttention) or 0) + 18, 0, 100)
	stats.CurseThreat = math.max(0, (tonumber(stats.CurseThreat) or 0) + 10)

	return "\n<font color='#b27aff'><b>[ JUJUTSU SOCIETY FILE OPENED ]</b></font> After <b>" .. tostring(hunterName or "a field sorcerer") .. "</b> died, Jujutsu Society confirmed your existence. You are now classified as a <b>" .. tostring(stats.CurseGrade) .. "</b>."
end

function updateCurseStatusAfterAttack(stats)
	normalizeCursedSocietyState(stats)

	local threat = tonumber(stats.CurseThreat) or 0
	local killed = tonumber(stats.SorcerersKilled) or 0

	if stats.CurseClassified ~= true then
		stats.SocietyStatus = "Unregistered Cursed Spirit"
		stats.CurseGrade = makeUnregisteredCurseGrade(stats.CurseGrade)
		return
	end

	stats.CurseGrade = makeOfficialCurseGrade(stats.CurseGrade)
	if threat >= 150 or tostring(stats.CurseThreatClass or "") == "Disaster" then
		stats.SocietyStatus = "Disaster Threat"
	elseif threat >= 75 or killed >= 5 then
		stats.SocietyStatus = "Registered Cursed Spirit"
	elseif threat >= 30 or killed >= 1 then
		stats.SocietyStatus = "Tracked Cursed Spirit"
	else
		stats.SocietyStatus = "Registered Cursed Spirit"
	end
end

function resolveCurseSorcererAttackChoice(player, stats, pending, option)
	if not stats or stats.Alive == false then
		return
	end

	normalizeCursedSocietyState(stats)

	local choice = tostring(option and option.CurseAttackChoice or "fight")
	local sorcererGrade = tostring(pending and pending.SorcererGrade or "Grade 4")
	local eventDifficulty = tonumber(pending and pending.EventDifficulty) or 0
	local cursePower = calculateCurseAttackPower(stats)
	local sorcererPower = calculateSorcererAttackPower(sorcererGrade, eventDifficulty)
	local hunterName = tostring(pending and pending.HunterName or "A sorcerer")
	local territory = tostring(pending and pending.Territory or stats.CurseTerritory or "your territory")
	local rumor = tostring(pending and pending.Rumor or stats.CurseRumor or "your rumor")
	local result = formatCurseAttackResultPrefix(sorcererGrade, hunterName, territory, rumor)
	local killedBefore = tonumber(stats.SorcerersKilled) or 0

	if choice == "fight" then
		local gap = cursePower - sorcererPower
		stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) + math.random(4, 10), 0, 100)
		stats.SorcererAttackCooldown = math.random(2, 4)

		if gap >= 55 then
			local ceGain = math.random(18, 34)
			local threatGain = math.random(8, 16)
			stats.CursedEnergy += ceGain
			stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + threatGain)
			stats.SorcerersKilled = (stats.SorcerersKilled or 0) + 1
			stats.CurseEvolutionProgress = math.max(0, (stats.CurseEvolutionProgress or 0) + math.random(8, 14))
			reduceCurseHunger(stats, math.random(10, 22))
			result ..= "\nYou fought them directly and overwhelmed them. Your threat level rose."
			result ..= "\nRewards: <b>+" .. tostring(ceGain) .. " CE</b> • <b>+" .. tostring(threatGain) .. " Threat</b> • Sorcerers Killed: <b>" .. tostring(stats.SorcerersKilled) .. "</b>."
		elseif gap >= 10 then
			local ceGain = math.random(10, 22)
			local threatGain = math.random(5, 10)
			local damage = math.random(8, 18)
			stats.CursedEnergy += ceGain
			stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + threatGain)
			stats.SorcerersKilled = (stats.SorcerersKilled or 0) + 1
			stats.CurseEvolutionProgress = math.max(0, (stats.CurseEvolutionProgress or 0) + math.random(5, 10))
			reduceCurseHunger(stats, math.random(8, 16))
			stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
			result ..= "\nYou won, but the sorcerer forced a real fight before falling."
			result ..= "\nRewards: <b>+" .. tostring(ceGain) .. " CE</b> • <b>+" .. tostring(threatGain) .. " Threat</b> • Health <b>-" .. tostring(damage) .. "</b>."
		elseif gap >= -25 then
			local damage = math.random(14, 28)
			stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
			stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + math.random(3, 8))
			stats.HuntersEscaped = (tonumber(stats.HuntersEscaped) or 0) + 1
			result ..= "\nThe fight tore through " .. territory .. ", but neither side finished it cleanly. " .. hunterName .. " survived and reported your existence."
			result ..= "\nResult: Health <b>-" .. tostring(damage) .. "</b> • Exorcism Risk increased."
		elseif gap >= -70 then
			local damage = math.random(25, 45)
			stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
			stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) + math.random(8, 16), 0, 100)
			result ..= "\nThe sorcerer nearly exorcised you. You survived, but your cursed body was pushed close to collapse."
			result ..= "\nResult: Health <b>-" .. tostring(damage) .. "</b> • Exorcism Risk increased sharply."
		else
			stats.Health = 0
			stats.Alive = false
			stats.TimesExorcised = (stats.TimesExorcised or 0) + 1
			stats.CauseOfDeath = "Exorcised by a " .. sorcererGrade .. " sorcerer"
			result ..= "\nThe sorcerer completed the exorcism. Your cursed existence ended."
		end

	elseif choice == "hide" then
		local hidePower = (tonumber(stats.Smarts) or 0) + ((tonumber(stats.TechniqueMastery) or 0) * 0.8) + math.random(1, 70)
		local detectionPower = getSorcererAttackBonus(sorcererGrade) * 0.45 + eventDifficulty + math.random(1, 55)
		stats.SorcererAttackCooldown = math.random(1, 3)

		if hidePower >= detectionPower then
			local riskDrop = math.random(4, 10)
			stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) - riskDrop, 0, 100)
			stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) - math.random(0, 3))
			result ..= "\nYou suppressed your cursed energy until the sorcerer lost the trail."
			result ..= "\nResult: Exorcism Risk <b>-" .. tostring(riskDrop) .. "</b>."
		else
			local damage = math.random(6, 18)
			stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
			stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) + math.random(2, 6), 0, 100)
			result ..= "\nYou tried to hide, but the sorcerer still found your trail. You escaped after taking damage."
			result ..= "\nResult: Health <b>-" .. tostring(damage) .. "</b>."
		end

	elseif choice == "ambush" then
		local ambushPower = cursePower + ((tonumber(stats.Smarts) or 0) * 0.35) + math.random(-10, 30)
		local gap = ambushPower - sorcererPower
		stats.SorcererAttackCooldown = math.random(2, 4)
		stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) + math.random(3, 8), 0, 100)

		if gap >= 35 then
			local ceGain = math.random(16, 30)
			local threatGain = math.random(10, 18)
			stats.CursedEnergy += ceGain
			stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + threatGain)
			stats.SorcerersKilled = (stats.SorcerersKilled or 0) + 1
			stats.CurseEvolutionProgress = math.max(0, (stats.CurseEvolutionProgress or 0) + math.random(8, 15))
			result ..= "\nYou struck first and ended the hunt before the sorcerer could control the fight."
			result ..= "\nRewards: <b>+" .. tostring(ceGain) .. " CE</b> • <b>+" .. tostring(threatGain) .. " Threat</b>."
		elseif gap >= -20 then
			local damage = math.random(10, 24)
			local threatGain = math.random(4, 9)
			stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
			stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + threatGain)
			result ..= "\nYour ambush disrupted the sorcerer, but they survived long enough to wound you before retreating."
			result ..= "\nResult: Health <b>-" .. tostring(damage) .. "</b> • Threat <b>+" .. tostring(threatGain) .. "</b>."
		else
			local damage = math.random(22, 40)
			stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
			stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) + math.random(8, 14), 0, 100)
			result ..= "\nThe ambush failed. The sorcerer read the attack and forced you to flee."
			result ..= "\nResult: Health <b>-" .. tostring(damage) .. "</b>."
		end

	elseif choice == "flee" then
		local damage = math.random(0, 10)
		local threatDrop = math.random(2, 7)
		stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
		stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) - threatDrop)
		stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) + math.random(1, 4), 0, 100)
		stats.SorcererAttackCooldown = math.random(1, 2)
		result ..= "\nYou fled before the sorcerer could pin you down. You survived, but your presence looked weaker."
		result ..= "\nResult: Threat <b>-" .. tostring(threatDrop) .. "</b>"
		if damage > 0 then
			result ..= " • Health <b>-" .. tostring(damage) .. "</b>"
		end
		result ..= "."
	end

	if stats.Health <= 0 and stats.Alive ~= false then
		stats.Alive = false
		stats.CauseOfDeath = "Exorcised after a sorcerer attack"
		if not isCurseLife(stats) then
			addCursedResentment(stats, 35)
			refreshCurseRebirthEligibility(stats)
		end
		result ..= "\nYour cursed body gave out."
	end

	local classificationMessage = registerCursedSpiritAfterKill(stats, killedBefore, sorcererGrade, hunterName)
	updateCurseStatusAfterAttack(stats)
	if classificationMessage ~= "" then
		result ..= classificationMessage
	end
	result ..= "\nCurse Status: <b>" .. tostring(stats.SocietyStatus or "Unregistered Cursed Spirit") .. "</b> | Classification: <b>" .. tostring(stats.CurseGrade or "Unregistered Grade 3 Cursed Spirit") .. "</b> | Threat: <b>" .. tostring(stats.CurseThreat or 0) .. "</b> | Exorcism Risk: <b>" .. tostring(stats.ExorcismRisk or 0) .. "%</b>."

	fireLifeUpdate(player, stats, result)
	saveStats(player, "curse sorcerer attack")
end

function ageUp(player)
	local stats = playerLives[player.UserId]

	if not stats or not stats.Alive then
		return
	end

	normalizeCursedSocietyState(stats)

	-- Do not let the player advance time while a mission/event choice is open.
	-- This fixes double-aging and year/month desync during random life encounters.
	if pendingMissions[player.UserId] then
		-- RELEASE HOTFIX:
		-- Never hard-freeze aging because of a stuck hidden/mobile mission/event popup.
		-- If a choice is pending when Age is clicked, clear it and continue aging.
		pendingMissions[player.UserId] = nil
		fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ SYSTEM ]</b></font> A stuck mission/event choice was cleared automatically. Aging continued.")
	end

	ensureExtraStats(stats)

	-- Phase 2A.5: resentment is the hidden unlock meter for Curse rebirth.
	-- It rises slowly from miserable/cursed lives, then spikes on cursed deaths.
	if not isCurseLife(stats) then
		if (tonumber(stats.Happiness) or 100) <= 25 then
			addCursedResentment(stats, math.random(1, 3))
		end
		if isCurseUser(stats) then
			addCursedResentment(stats, 1)
		end
		if (tonumber(stats.WantedLevel) or 0) >= 3 then
			addCursedResentment(stats, math.random(1, 2))
		end
	end

	local currentAge = tonumber(stats.Age) or 0
	local isSixMonthTick = currentAge >= 16

	if isSixMonthTick then
		-- Age 16+ advances in clean six-month chunks:
		-- Age 16 January 2016 -> Age 16 July 2016 -> Age 17 January 2017.
		local currentMonth, monthsIntoAge = normalizeSixMonthDate(stats)

		local completedFullYear = false

		if currentMonth == 1 then
			currentMonth = 7
			monthsIntoAge = 6
		else
			currentMonth = 1
			monthsIntoAge = 0
			completedFullYear = true
		end

		stats.MonthsIntoAge = monthsIntoAge
		stats.CurrentMonth = currentMonth
		stats.ActivitiesDoneThisAge = 0
		stats.RelationshipActionsThisAge = 0

		local logMessage = getSixMonthPassiveEventText(stats)
		-- Age 16+ uses six-month ticks, so give those ticks a real V2 event often too.
		-- This keeps adult/teen gameplay from feeling like filler text between full birthdays.
		logMessage = addRandomLifeEvent(player, stats, logMessage, math.random(1, 100) <= 75)

		stats.Health = math.clamp((stats.Health or 100) + math.random(-1, 2), 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(-1, 2), 0, 100)

		local sixMonthNotes = {}

		if stats.Grade ~= "Non-Sorcerer" then
			local ceGain = math.random(1, 3)
			stats.CursedEnergy += ceGain
			table.insert(sixMonthNotes, "+" .. tostring(ceGain) .. " CE")
		end

		if isCurseLife(stats) then
			ensureCursedSpiritFlavor(stats)
			local threatGain = math.random(0, 2)
			local curseCEGain = math.random(2, 5)
			local hungerGain = math.random(4, 9)
			stats.CursedEnergy += curseCEGain
			stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + threatGain)
			stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) + math.random(0, 1), 0, 100)
			stats.SorcererAttackCooldown = math.max(0, (stats.SorcererAttackCooldown or 0) - 1)
			addCurseHunger(stats, hungerGain)
			table.insert(sixMonthNotes, "+" .. tostring(curseCEGain) .. " Curse CE")
			table.insert(sixMonthNotes, "+" .. tostring(hungerGain) .. " Hunger")
			if threatGain > 0 then
				table.insert(sixMonthNotes, "+" .. tostring(threatGain) .. " Threat")
			end
		end

		if stats.InJujutsuHigh and stats.Age >= 16 and stats.Age <= 22 then
			local smartGain = math.random(0, 1)
			if smartGain > 0 then
				stats.Smarts = math.clamp((stats.Smarts or 0) + smartGain, 0, 100)
				table.insert(sixMonthNotes, "+" .. tostring(smartGain) .. " Smarts")
			end
		end

		if stats.ClanFounded then
			stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + 1)
			table.insert(sixMonthNotes, "+1 Clan Reputation")
		end

		if #sixMonthNotes > 0 then
			logMessage = logMessage .. "\n<b>Six-month progress:</b> " .. table.concat(sixMonthNotes, ", ") .. "."
		end

		if completedFullYear then
			BitKaisenRelationships.AdvanceRelationshipYears(stats)

			stats.Age += 1
			stats.CurrentMonth = 1
			stats.MonthsIntoAge = 0
			stats.ActivitiesDoneThisAge = 0
			stats.RelationshipActionsThisAge = 0

			stats.Health = math.clamp((stats.Health or 100) + math.random(-5, 4), 0, 100)
			stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(-4, 4), 0, 100)

			logMessage = logMessage .. "\nThe calendar turned to <b>" .. getTimeStampText(stats) .. "</b>. You are now <b>" .. tostring(stats.Age) .. "</b>."

			local awakened, technique, awakenType = BitKaisenStats.TryAwaken(stats)

			if awakened and technique then
				if awakenType == "Innate" then
					logMessage = logMessage .. "\nYour inherited technique finally stopped sleeping. <b>" .. technique .. "</b> became usable."
					fireMajorPopup(
						player,
						"INNATE TECHNIQUE AWAKENED",
						"At age " .. tostring(stats.Age) .. ", the technique you were born with finally answered you.",
						technique,
						"Innate techniques are inherited at birth, but usually become usable around age 10-11."
					)
				else
					logMessage = logMessage .. "\nYour cursed energy finally took shape. You awakened <b>" .. technique .. "</b>."
					fireMajorPopup(
						player,
						"CURSED TECHNIQUE AWAKENED",
						"At age " .. tostring(stats.Age) .. ", your cursed energy sparked into a technique.",
						technique,
						"Normal techniques can awaken around ages 8, 10, or 13."
					)
				end
			end

			if stats.Age >= 16 and stats.Grade ~= "Non-Sorcerer" then
				stats.CursedEnergy += math.random(1, 5)
			end

			if stats.InJujutsuHigh and stats.Age >= 16 and stats.Age <= 22 then
				stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(0, 2), 0, 100)
			end

			if stats.ClanFounded then
				stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + math.random(0, 2))

				local studentCount = countClanStudents(stats)
				local recruitChance = 12 + math.clamp(math.floor((stats.ClanReputation or 0) / 8), 0, 18)

				if studentCount <= 0 then
					recruitChance += 12
				end

				if math.random(1, 100) <= recruitChance then
					local student = createClanStudent(stats)
					stats.ClanStudentsRecruited = (stats.ClanStudentsRecruited or 0) + 1
					stats.ClanMembers = math.max(1, (stats.ClanMembers or 1) + 1)
					stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + math.random(1, 4))
					logMessage = logMessage .. "\n" .. student.Name .. " asked to train under the <b>" .. tostring(stats.PlayerClanName or "clan") .. "</b> and joined as a student."
				end
			end

			local assetBonuses = BitKaisenAssets.GetPassiveBonuses(stats)

			if assetBonuses.HealthRecoveryBonus and assetBonuses.HealthRecoveryBonus > 0 then
				stats.Health = math.clamp((stats.Health or 100) + assetBonuses.HealthRecoveryBonus, 0, 100)
			end

			logMessage = addRandomLifeEvent(player, stats, logMessage)
			logMessage = addRelationshipAgeEvent(player, stats, logMessage)
			logMessage = maybeTeacherRecommendation(player, stats, logMessage)
			logMessage = checkPromotionAndPopup(player, stats, logMessage)

			if isCurseLife(stats) then
				ensureCursedSpiritFlavor(stats)
				stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + math.random(0, 3))
				stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) + math.random(0, 2), 0, 100)
				logMessage = logMessage .. "\nYour cursed presence lingered through another year. Threat: <b>" .. tostring(stats.CurseThreat or 0) .. "</b> | Hunger: <b>" .. tostring(stats.CurseHunger or 0) .. "% (" .. getCurseHungerText(stats) .. ")</b>."
				if math.random(1, 100) <= 65 then
					local curseEventText = rollCursedSpiritLifeEvent(player, stats)
					if curseEventText ~= "" then
						logMessage = logMessage .. "\n" .. curseEventText
					end
				end
				if maybeBeginCurseSorcererAttack(player, stats, "Your cursed presence lingered long enough for a sorcerer to lock onto your trail.") then
					logMessage = logMessage .. "\n<font color='#e53935'><b>[ WARNING ]</b></font> A sorcerer has tracked your cursed energy. Choose how to respond."
				end
			end

			if stats.Age >= 80 and not isCurseLife(stats) then
				local deathRoll = math.random(1, 100)

				if deathRoll <= stats.Age - 79 then
					stats.Alive = false
					stats.CauseOfDeath = "Old age"
					refreshCurseRebirthEligibility(stats)
					logMessage = logMessage .. "\nYour life reached its final year."
				end
			end
		end

		if stats.Health <= 0 then
			stats.Alive = false
			stats.CauseOfDeath = stats.CauseOfDeath or "Body gave out"
			if not isCurseLife(stats) then
				addCursedResentment(stats, 20)
				refreshCurseRebirthEligibility(stats)
			end
			logMessage = logMessage .. "\nYour body gave out."
		end

		local higherUpsStarted = maybeBeginHigherUpsInvitation(player, stats)
		local curseAttackStarted = false
		if stats.Alive ~= false and not higherUpsStarted then
			curseAttackStarted = maybeBeginCurseSorcererAttack(player, stats, "Your cursed energy trail pulled a sorcerer toward your hiding place.")
		end
		local shouldRollLifeEncounter = stats.Alive ~= false and not higherUpsStarted and not curseAttackStarted and math.random(1, 100) <= 35
		if shouldRollLifeEncounter then
			beginMonthlyLifeEncounter(player, stats)
		end

		fireLifeUpdate(player, stats, logMessage)
		saveStats(player)
		return
	end

	-- Childhood / early teen years still advance by full years.
	BitKaisenRelationships.AdvanceRelationshipYears(stats)

	stats.Age += 1
	stats.CurrentMonth = 1
	stats.MonthsIntoAge = 0
	stats.ActivitiesDoneThisAge = 0
	stats.RelationshipActionsThisAge = 0

	stats.Health = math.clamp((stats.Health or 100) + math.random(-5, 4), 0, 100)
	stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(-4, 4), 0, 100)

	local logMessage = BitKaisenLifeEvents.GetQuietYearText(stats)

	local awakened, technique, awakenType = BitKaisenStats.TryAwaken(stats)

	if awakened and technique then
		if awakenType == "Innate" then
			logMessage = "Your inherited technique finally stopped sleeping. <b>" .. technique .. "</b> became usable."
			fireMajorPopup(
				player,
				"INNATE TECHNIQUE AWAKENED",
				"At age " .. tostring(stats.Age) .. ", the technique you were born with finally answered you.",
				technique,
				"Innate techniques are inherited at birth, but usually become usable around age 10-11."
			)
		else
			logMessage = "Your cursed energy finally took shape. You awakened <b>" .. technique .. "</b>."
			fireMajorPopup(
				player,
				"CURSED TECHNIQUE AWAKENED",
				"At age " .. tostring(stats.Age) .. ", your cursed energy sparked into a technique.",
				technique,
				"Normal techniques can awaken around ages 8, 10, or 13."
			)
		end
	elseif stats.Age == 8 and tostring(stats.InnateTechnique or "None") == "None" and tostring(stats.CursedTechnique or "None") == "None" then
		logMessage = "Your cursed energy stirred for the first time, but no technique fully manifested."
	elseif stats.Age == 10 and tostring(stats.CursedTechnique or "None") == "None" then
		if tostring(stats.InnateTechnique or "None") ~= "None" then
			logMessage = "Your innate technique pressed against the surface, but it did not fully answer yet."
		else
			logMessage = "Your cursed energy grew unstable for a moment, but no technique manifested."
		end
	end

	if stats.Age >= 13 and stats.CursedTechnique ~= "None" and not stats.InJujutsuHigh then
		if math.random(1, 100) <= 15 then
			logMessage = "A jujutsu recruiter noticed your cursed energy. You can apply to Jujutsu High when you are old enough."
		end
	end

	if stats.Age >= 16 and stats.Grade ~= "Non-Sorcerer" then
		stats.CursedEnergy += math.random(1, 5)
	end

	if stats.InJujutsuHigh and stats.Age >= 16 and stats.Age <= 22 then
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(0, 2), 0, 100)
	end

	if stats.ClanFounded then
		stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + math.random(0, 2))

		local studentCount = countClanStudents(stats)
		local recruitChance = 12 + math.clamp(math.floor((stats.ClanReputation or 0) / 8), 0, 18)

		if studentCount <= 0 then
			recruitChance += 12
		end

		if math.random(1, 100) <= recruitChance then
			local student = createClanStudent(stats)
			stats.ClanStudentsRecruited = (stats.ClanStudentsRecruited or 0) + 1
			stats.ClanMembers = math.max(1, (stats.ClanMembers or 1) + 1)
			stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + math.random(1, 4))
			logMessage = logMessage .. "\n" .. student.Name .. " asked to train under the <b>" .. tostring(stats.PlayerClanName or "clan") .. "</b> and joined as a student."
		end
	end

	local assetBonuses = BitKaisenAssets.GetPassiveBonuses(stats)

	if assetBonuses.HealthRecoveryBonus and assetBonuses.HealthRecoveryBonus > 0 then
		stats.Health = math.clamp((stats.Health or 100) + assetBonuses.HealthRecoveryBonus, 0, 100)
	end

	local forceScenarioThisAge = false

	if stats.Age <= 3 then
		forceScenarioThisAge = math.random(1, 100) <= 45
	elseif stats.Age <= 7 then
		forceScenarioThisAge = math.random(1, 100) <= 85
	elseif stats.Age <= 12 then
		forceScenarioThisAge = math.random(1, 100) <= 90
	elseif stats.Age <= 15 then
		forceScenarioThisAge = math.random(1, 100) <= 80
	end

	logMessage = addRandomLifeEvent(player, stats, logMessage, forceScenarioThisAge)
	logMessage = addRelationshipAgeEvent(player, stats, logMessage)
	local unregisteredActivityProgress, unregisteredActivityReason = getUnregisteredActivityProgress(activityId, stats)
	logMessage = awardUnregisteredProgress(player, stats, unregisteredActivityProgress, unregisteredActivityReason, logMessage)

	logMessage = maybeTeacherRecommendation(player, stats, logMessage)
	logMessage = checkPromotionAndPopup(player, stats, logMessage)

	if isCurseLife(stats) then
		ensureCursedSpiritFlavor(stats)
		stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + math.random(0, 3))
		stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) + math.random(0, 2), 0, 100)
		addCurseHunger(stats, math.random(6, 12))
		logMessage = logMessage .. "\nYour cursed presence grew quietly. Threat: <b>" .. tostring(stats.CurseThreat or 0) .. "</b> | Hunger: <b>" .. tostring(stats.CurseHunger or 0) .. "%</b>."
		if math.random(1, 100) <= 65 then
			local curseEventText = rollCursedSpiritLifeEvent(player, stats)
			if curseEventText ~= "" then
				logMessage = logMessage .. "\n" .. curseEventText
			end
		end
		if maybeBeginCurseSorcererAttack(player, stats, "Your cursed energy became noticeable enough for a sorcerer to investigate.") then
			logMessage = logMessage .. "\n<font color='#e53935'><b>[ WARNING ]</b></font> A sorcerer has tracked your cursed energy. Choose how to respond."
		end
	end

	if stats.Age >= 80 and not isCurseLife(stats) then
		local deathRoll = math.random(1, 100)

		if deathRoll <= stats.Age - 79 then
			stats.Alive = false
			logMessage = logMessage .. "\nYour life reached its final year."
		end
	end

	if stats.Health <= 0 then
		stats.Alive = false
		stats.CauseOfDeath = stats.CauseOfDeath or "Body gave out"
		if not isCurseLife(stats) then
			addCursedResentment(stats, 20)
			refreshCurseRebirthEligibility(stats)
		end
		logMessage = logMessage .. "\nYour body gave out."
	end

	maybeBeginHigherUpsInvitation(player, stats)

	fireLifeUpdate(player, stats, logMessage)
	saveStats(player)
end

function applyChoiceEffects(stats, choiceOption)
	if not choiceOption or not choiceOption.Effects then
		return
	end

	local effects = choiceOption.Effects

	if effects.Health then
		stats.Health = math.clamp((stats.Health or 100) + effects.Health, 0, 100)
	end

	if effects.Happiness then
		stats.Happiness = math.clamp((stats.Happiness or 100) + effects.Happiness, 0, 100)
	end

	if effects.Smarts then
		stats.Smarts = math.clamp((stats.Smarts or 0) + effects.Smarts, 0, 100)
	end

	if effects.CursedEnergy then
		stats.CursedEnergy = math.max(0, (stats.CursedEnergy or 0) + effects.CursedEnergy)
	end

	if effects.Money then
		stats.Money = math.max(0, (stats.Money or 0) + effects.Money)
	end

	if effects.Reputation then
		stats.Reputation = (stats.Reputation or 0) + effects.Reputation
	end

	if effects.TechniqueMastery then
		stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + effects.TechniqueMastery, 0, 100)
	end
	if effects.Morality then
		applyMorality(stats, effects.Morality)
	end

	stats.Alignment = getMoralAlignment(stats)

end

function resolveMission(player, stats, missionData, choiceOption)
	local logMessage = ""
	local powerBonus = 0
	local forceSuccess = false
	local forceFail = false
	local traitBefore = captureTraitBuffSnapshot(stats)

	if choiceOption then
		powerBonus = choiceOption.PowerBonus or 0
		forceSuccess = choiceOption.ForceSuccess == true
		forceFail = choiceOption.ForceFail == true

		applyChoiceEffects(stats, choiceOption)
		if choiceOption then
			applyMorality(stats, choiceOption.Morality or 0)
		end

		if choiceOption.Description then
			logMessage = choiceOption.Description
		end

		if stats.Health <= 0 then
			stats.Alive = false
			stats.MissionsFailed += 1
			logMessage = logMessage .. "\nYou died on the mission."
			fireLifeUpdate(player, stats, logMessage)
			saveStats(player)
			return
		end
	end

	local success

	if forceSuccess then
		success = true
	elseif forceFail then
		success = false
	else
		local playerPower = calculatePlayerPower(stats) + powerBonus + BitKaisenTraits.GetModifier(stats, "MissionSuccessBonus", 0)
		success = playerPower >= missionData.Difficulty
	end

	if success then
		local smartBonus = 1 + ((stats.Smarts or 0) / 300)

		stats.CursedEnergy += missionData.RewardCE
		stats.Money += math.floor((missionData.RewardMoney or 0) * smartBonus)
		stats.Reputation += math.floor((missionData.RewardRep or 0) * smartBonus)
		stats.MissionsCompleted += 1
		stats.Happiness = math.clamp((stats.Happiness or 100) + 8, 0, 100)

		if stats.ClanFounded then
			stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + math.random(1, 3))
		end

		if logMessage ~= "" then
			logMessage = logMessage .. "\n"
		end

		logMessage = logMessage .. "You completed <b>" .. missionData.Title .. "</b> and exorcised the curse."

		if missionData.RewardMoney and missionData.RewardMoney > 0 then
			logMessage = logMessage .. "\nYou were paid for the assignment."
		end

		if (stats.Smarts or 0) >= 70 then
			logMessage = logMessage .. "\nYour detailed mission report impressed the higher-ups."
		end

		if stats.InJujutsuHigh and math.random(1, 100) <= 18 then
			local partner = BitKaisenRelationships.AddFriend(stats)
			partner.Role = "Mission Partner"
			partner.Status = "Mission Partner"

			logMessage = logMessage .. "\nYou worked well with " .. partner.Name .. " during the assignment."

			fireMajorPopup(
				player,
				"MISSION PARTNER",
				"You worked with another sorcerer during your assignment.",
				partner.Name,
				"They have been added to your Relationships page."
			)
		end

		logMessage = maybeTeacherRecommendation(player, stats, logMessage)
		logMessage = checkPromotionAndPopup(player, stats, logMessage)
	else
		local damageReduction = math.floor((stats.Smarts or 0) / 5)
		local actualDamage = math.max(2, (missionData.DmgPenalty or 0) - damageReduction)

		stats.Health = math.clamp((stats.Health or 100) - actualDamage, 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) - 15, 0, 100)
		stats.MissionsFailed += 1

		if logMessage ~= "" then
			logMessage = logMessage .. "\n"
		end

		logMessage = logMessage .. "You failed <b>" .. missionData.Title .. "</b>."

		if damageReduction >= 10 then
			logMessage = logMessage .. "\nYour sharp thinking kept you from taking the full hit."
		end

		local relationship = BitKaisenRelationships.GetRandomRelationship(stats)
		if relationship and math.random(1, 100) <= 25 then
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Bond = -math.random(3, 8),
				Trust = -math.random(2, 6)
			})

			logMessage = logMessage .. "\n" .. relationship.Name .. " was worried about what happened."
		end

		if stats.Health <= 0 then
			stats.Alive = false
			logMessage = logMessage .. "\nYou were killed in action."
		end
	end

	logMessage = logMessage .. applyTraitBuffsFromSnapshot(stats, traitBefore, "Mission")
	maybeBeginHigherUpsInvitation(player, stats)

	fireLifeUpdate(player, stats, logMessage)
	saveStats(player)

	if success and stats.Alive ~= false then
		local rescueChance = getOrphanRescueChance(stats, missionData)
		if rescueChance > 0 and math.random(1, 100) <= rescueChance then
			task.delay(0.45, function()
				if player and player.Parent and playerLives[player.UserId] == stats and not pendingMissions[player.UserId] then
					beginOrphanRescueSituation(player, stats, missionData)
				end
			end)
		end
	end
end


clearPendingMission.OnServerEvent:Connect(function(player)
	local stats = playerLives[player.UserId]

	pendingMissions[player.UserId] = nil

	if stats then
		fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ SYSTEM ]</b></font> Cleared a stuck mission/event choice. You can age again.")
	end
end)


function processMission(player, missionId)
	local stats = playerLives[player.UserId]

	if not stats or not stats.Alive then
		return
	end

	ensureExtraStats(stats)

	if isCurseUser(stats) then
		if typeof(missionId) ~= "string" then
			return
		end

		processCurseUserMission(player, stats, missionId)
		return
	end

	if (stats.Age or 0) < 16 then
		fireLifeUpdate(player, stats, "You are too young to take official missions. You need to be at least 16.")
		return
	end

	if not isOfficialJujutsuSorcerer(stats) then
		fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ LOCKED ]</b></font> Curse missions are only available after you are registered through Jujutsu High. Current status: <b>" .. tostring(stats.Grade or "Unregistered") .. "</b>.")
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

	if not BitKaisenMissions.CanAttemptMission(getOfficialGradeName(stats.Grade), missionData.Grade) then
		fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ LOCKED ]</b></font> You are not qualified for this mission.")
		return
	end

	if pendingMissions[player.UserId] then
		fireLifeUpdate(player, stats, "You are still handling a previous situation.")
		return
	end

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

	showMissionSituation:FireClient(player, {
		MissionTitle = missionData.Title,
		Title = situation.Title,
		Body = situation.Body,
		Options = optionDisplay
	})
end

function processActivity(player, activityId)
	local stats = playerLives[player.UserId]

	if not stats or not stats.Alive then
		return
	end

	ensureExtraStats(stats)

	if typeof(activityId) ~= "string" then
		return
	end

	local activity = BitKaisenActivities.GetActivityById(activityId)

	if not activity then
		fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ SYSTEM ]</b></font> Invalid activity.")
		return
	end

	local canDo, reason = BitKaisenActivities.CanDoActivity(stats, activity)

	if not canDo then
		fireLifeUpdate(player, stats, tostring(reason or "You cannot do this activity."))
		return
	end

	if activityId ~= "dev_awaken" and stats.ActivitiesDoneThisAge >= 3 then
		fireLifeUpdate(player, stats, "You already did too many activities this year. Age up first.")
		return
	end

	local logMessage = ""

	if activityId == "dev_awaken" then
		if not isDev(player) then
			fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ SYSTEM ]</b></font> Invalid activity.")
			return
		end

		local technique = forceAwaken(player, stats, "A test command forced your cursed technique to awaken.")
		logMessage = "Your cursed technique awakened through testing. You awakened <b>" .. technique .. "</b>."
		fireLifeUpdate(player, stats, logMessage)
		saveStats(player)
		return
	end

	stats.ActivitiesDoneThisAge += 1
	local traitBefore = captureTraitBuffSnapshot(stats)

	if activityId == "play_outside" then
		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(3, 8), 0, 100)
		stats.Health = math.clamp((stats.Health or 100) + math.random(0, 3), 0, 100)
		logMessage = "You spent time playing outside and enjoying a normal childhood moment."

	elseif activityId == "spend_time_family" then
		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(3, 9), 0, 100)
		logMessage = BitKaisenRelationships.HandleFamilyActivity(stats)

	elseif activityId == "watch_shadows" then
		stats.CursedEnergy += math.random(1, 4)
		stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(0, 3), 0, 100)
		logMessage = "You watched the strange shapes that moved where no one else looked."

	elseif activityId == "ask_about_curses" then
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(2, 5), 0, 100)
		logMessage = "You asked questions about curses and the strange things around you."

	elseif activityId == "basic_school_study" then
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(3, 7), 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(0, 3), 0, 100)
		logMessage = "You focused on schoolwork and improved your general knowledge."

	elseif activityId == "train_ce" then
		local assetBonuses = BitKaisenAssets.GetPassiveBonuses(stats)
		local bonus = assetBonuses.CursedEnergyTrainingBonus or 0

		stats.CursedEnergy += math.random(5, 14) + bonus
		stats.Health = math.clamp((stats.Health or 100) - math.random(2, 8), 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(0, 4), 0, 100)

		if stats.ClanFounded then
			stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + 1)
		end

		if bonus > 0 then
			logMessage = "You trained your cursed energy using the resources you own."
		else
			logMessage = "You trained your cursed energy."
		end

	elseif activityId == "study_theory" then
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(3, 8), 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(1, 5), 0, 100)
		logMessage = "You studied jujutsu theory."

	elseif activityId == "expand_curse_knowledge" then
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(5, 10), 0, 100)
		stats.CursedEnergy += math.random(2, 6)
		stats.Reputation += math.random(0, 2)
		logMessage = "You expanded your knowledge on curses, studying how they form, hunt, and hide from normal people."

	elseif activityId == "meditate" then
		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(4, 10), 0, 100)
		stats.CursedEnergy += math.random(1, 5)
		logMessage = "You meditated and stabilized your energy."

	elseif activityId == "rest" then
		local assetBonuses = BitKaisenAssets.GetPassiveBonuses(stats)
		local bonus = assetBonuses.HealthRecoveryBonus or 0

		stats.Health = math.clamp((stats.Health or 100) + math.random(8, 18) + bonus, 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(2, 8), 0, 100)

		if bonus > 0 then
			logMessage = "You rested in a safer space and recovered."
		else
			logMessage = "You rested and recovered."
		end

	elseif activityId == "doctor" then
		local cost = 120

		if stats.Money < cost then
			stats.ActivitiesDoneThisAge -= 1
			fireLifeUpdate(player, stats, "A doctor visit costs $" .. cost .. ".")
			return
		end

		stats.Money -= cost
		stats.Health = math.clamp((stats.Health or 100) + math.random(22, 40), 0, 100)
		logMessage = "You visited a doctor and recovered."

	elseif activityId == "socialize" then
		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(6, 14), 0, 100)

		if stats.InJujutsuHigh then
			stats.Reputation += math.random(1, 4)
		end

		local relationshipMessage, popupData = BitKaisenRelationships.HandleSocialize(stats)
		logMessage = relationshipMessage or "You spent time with people."
		fireRelationshipPopup(player, popupData)

	elseif activityId == "curse_absorb_fear" then
		if not isCurseLife(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only cursed spirit lives can absorb fear this way.")
			return
		end

		local ceGain = math.random(10, 24)
		local threatGain = math.random(2, 6)
		local hungerDrop = math.random(8, 18)
		ensureCursedSpiritFlavor(stats)
		stats.CursedEnergy += ceGain
		stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + threatGain)
		stats.CurseFearLevel = math.max(0, (stats.CurseFearLevel or 0) + math.random(3, 8))
		stats.CurseEvolutionProgress = math.max(0, (stats.CurseEvolutionProgress or 0) + math.random(1, 5))
		reduceCurseHunger(stats, hungerDrop)
		stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) + math.random(0, 3), 0, 100)
		logMessage = applyCursedSpiritActivityFlavor(stats, "absorb_fear")
		logMessage ..= "\nGained <b>+" .. tostring(ceGain) .. " CE</b>, <b>+" .. tostring(threatGain) .. " Threat</b>. Hunger <b>-" .. tostring(hungerDrop) .. "%</b>."

	elseif activityId == "curse_hide_presence" then
		if not isCurseLife(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only cursed spirit lives need to hide cursed presence this way.")
			return
		end

		local riskDrop = math.random(6, 16)
		local attentionDrop = math.random(3, 9)
		local hungerGain = math.random(4, 10)
		ensureCursedSpiritFlavor(stats)
		stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) - riskDrop, 0, 100)
		stats.SocietyAttention = math.clamp((stats.SocietyAttention or 0) - attentionDrop, 0, 100)
		stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) - math.random(0, 3))
		stats.SorcererAttackCooldown = math.max(tonumber(stats.SorcererAttackCooldown) or 0, 2)
		addCurseHunger(stats, hungerGain)
		stats.CursedEnergy += math.random(1, 5)
		logMessage = applyCursedSpiritActivityFlavor(stats, "hide")
		logMessage ..= "\nExorcism Risk <b>-" .. tostring(riskDrop) .. "%</b>. Society Attention <b>-" .. tostring(attentionDrop) .. "%</b>. Hunger <b>+" .. tostring(hungerGain) .. "%</b>."

	elseif activityId == "curse_hunt_remnants" then
		if not isCurseLife(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only cursed spirit lives can hunt curse remnants this way.")
			return
		end

		local ceGain = math.random(12, 28)
		local damage = math.random(0, 12)
		local evolutionGain = math.random(6, 14)
		local hungerDrop = math.random(5, 14)
		ensureCursedSpiritFlavor(stats)
		stats.CursedEnergy += ceGain
		stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
		stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + math.random(2, 7))
		stats.CurseEvolutionProgress = math.max(0, (stats.CurseEvolutionProgress or 0) + evolutionGain)
		stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) + math.random(1, 5), 0, 100)
		reduceCurseHunger(stats, hungerDrop)
		logMessage = applyCursedSpiritActivityFlavor(stats, "remnants")
		logMessage ..= "\nGained <b>+" .. tostring(ceGain) .. " CE</b>, <b>+" .. tostring(evolutionGain) .. " Evolution Progress</b>. Hunger <b>-" .. tostring(hungerDrop) .. "%</b>."
		if damage > 0 then
			logMessage ..= "\nThe hunt damaged your cursed body. Health <b>-" .. tostring(damage) .. "</b>."
		end

	elseif activityId == "curse_lure_sorcerer" then
		if not isCurseLife(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only curse lives can lure sorcerers this way.")
			return
		end

		stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + math.random(4, 9))
		stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) + math.random(5, 12), 0, 100)
		stats.SorcererAttackCooldown = 0
		if beginCurseSorcererAttack(player, stats, "You deliberately exposed your cursed energy and dared the jujutsu world to answer.") then
			logMessage = "You exposed your cursed energy on purpose. A sorcerer answered the challenge."
		else
			logMessage = "You exposed your cursed energy, but no sorcerer reached you this time. Your threat still rose."
		end

	elseif activityId == "curse_claim_territory" then
		if not isCurseLife(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only cursed spirit lives can claim territory this way.")
			return
		end

		ensureCursedSpiritFlavor(stats)
		local oldTerritory = tostring(stats.CurseTerritory or "your old haunt")
		local damage = math.random(0, 10)
		stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
		stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + math.random(2, 8))
		stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) + math.random(2, 7), 0, 100)
		addCurseHunger(stats, math.random(4, 12))
		logMessage = applyCursedSpiritActivityFlavor(stats, "territory")
		logMessage ..= "\nOld Territory: <b>" .. oldTerritory .. "</b>."
		if damage > 0 then
			logMessage ..= " Health <b>-" .. tostring(damage) .. "</b>."
		end

	elseif activityId == "curse_spread_rumor" then
		if not isCurseLife(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only cursed spirit lives can spread a rumor this way.")
			return
		end

		ensureCursedSpiritFlavor(stats)
		local threatGain = math.random(3, 9)
		local evoGain = math.random(2, 8)
		stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + threatGain)
		stats.CurseEvolutionProgress = math.max(0, (stats.CurseEvolutionProgress or 0) + evoGain)
		stats.CurseFearLevel = math.max(0, (stats.CurseFearLevel or 0) + math.random(4, 12))
		addCurseHunger(stats, math.random(2, 7))
		addSocietyAttention(stats, math.random(1, 6))
		logMessage = applyCursedSpiritActivityFlavor(stats, "rumor")
		logMessage ..= "\nThreat <b>+" .. tostring(threatGain) .. "</b>. Evolution Progress <b>+" .. tostring(evoGain) .. "</b>."

	elseif activityId == "curse_feed_negative_emotion" then
		if not isCurseLife(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only cursed spirit lives can feed on negative emotion this way.")
			return
		end

		ensureCursedSpiritFlavor(stats)
		local ceGain = math.random(14, 32)
		local hungerDrop = math.random(15, 30)
		local attentionGain = math.random(0, 8)
		stats.CursedEnergy += ceGain
		stats.CurseEvolutionProgress = math.max(0, (stats.CurseEvolutionProgress or 0) + math.random(3, 9))
		stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + math.random(1, 5))
		reduceCurseHunger(stats, hungerDrop)
		addSocietyAttention(stats, attentionGain)
		logMessage = applyCursedSpiritActivityFlavor(stats, "feed_negative")
		logMessage ..= "\nGained <b>+" .. tostring(ceGain) .. " CE</b>. Hunger <b>-" .. tostring(hungerDrop) .. "%</b>."

	elseif activityId == "practice_technique" then
		local technique = tostring(stats.CursedTechnique or "None")

		if technique == "None" then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need to awaken a cursed technique before you can practice it.")
			return
		end

		local assetBonuses = BitKaisenAssets.GetPassiveBonuses(stats)
		local trainingBonus = assetBonuses.CursedEnergyTrainingBonus or 0

		local masteryGain = math.random(2, 5)

		if stats.InJujutsuHigh then
			masteryGain += 1
		end

		if (stats.Smarts or 0) >= 60 then
			masteryGain += 1
		end

		if trainingBonus >= 8 then
			masteryGain += 2
		elseif trainingBonus >= 4 then
			masteryGain += 1
		end

		local oldMastery = stats.TechniqueMastery or 0
		stats.TechniqueMastery = math.clamp(oldMastery + masteryGain, 0, 100)

		stats.CursedEnergy += math.random(5, 12) + math.floor(trainingBonus / 2)
		stats.Reputation += math.random(1, 3)
		stats.Health = math.clamp((stats.Health or 100) - math.random(1, 4), 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(0, 3), 0, 100)

		logMessage =
			"You practiced <b>" .. technique .. "</b> and improved your cursed technique control." ..
			"\nTechnique Mastery increased by <b>" .. tostring(stats.TechniqueMastery - oldMastery) .. "%</b>."

		if stats.TechniqueMastery >= 25 and oldMastery < 25 then
			logMessage = logMessage .. "\nYour technique reached <b>Refined Control</b>."

			fireMajorPopup(
				player,
				"TECHNIQUE MASTERY",
				"Your cursed technique became more reliable.",
				"Refined Control",
				"Technique Mastery now gives stronger mission value."
			)
		elseif stats.TechniqueMastery >= 50 and oldMastery < 50 then
			logMessage = logMessage .. "\nYour technique reached <b>Advanced Application</b>."

			fireMajorPopup(
				player,
				"TECHNIQUE MASTERY",
				"Your cursed technique is becoming part of your identity.",
				"Advanced Application",
				"Future technique choices can use this milestone."
			)
		elseif stats.TechniqueMastery >= 75 and oldMastery < 75 then
			logMessage = logMessage .. "\nYour technique reached <b>Elite Mastery</b>."

			fireMajorPopup(
				player,
				"TECHNIQUE MASTERY",
				"Your control is now dangerous even by sorcerer standards.",
				"Elite Mastery",
				"Rare mastery events can be added later."
			)
		elseif stats.TechniqueMastery >= 95 and oldMastery < 95 then
			logMessage = logMessage .. "\nYour technique reached <b>Complete Mastery</b>."

			fireMajorPopup(
				player,
				"TECHNIQUE MASTERY",
				"You are approaching the peak of your innate technique.",
				"Complete Mastery",
				"Domain Expansion can be built on this later."
			)
		end

	elseif activityId == "apply_jujutsu_high" then
		ensureSorcererRegistrationState(stats)

		if stats.InJujutsuHigh == true then
			logMessage = "You are already registered through Jujutsu High."
		elseif isCurseUser(stats) then
			stats.Happiness = math.clamp((stats.Happiness or 100) - 4, 0, 100)
			logMessage = "Jujutsu High rejected your application because you have already been branded as a curse user."

			fireMajorPopup(
				player,
				"JUJUTSU HIGH REJECTION",
				"Your application was reviewed by the jujutsu world.",
				"Curse User",
				"Your path has already moved outside official registration."
			)
		elseif (stats.Age or 0) < 13 then
			stats.Happiness = math.clamp((stats.Happiness or 100) - 3, 0, 100)
			logMessage = "Jujutsu High rejected your application because you are still too young to be evaluated seriously."

			fireMajorPopup(
				player,
				"JUJUTSU HIGH REJECTION",
				"Your application was reviewed by the jujutsu world.",
				"Too Young",
				"Try again when you are older."
			)
		elseif not isUnregisteredSorcerer(stats) then
			stats.Happiness = math.clamp((stats.Happiness or 100) - 5, 0, 100)
			logMessage = "Jujutsu High rejected your application because your cursed energy has not been recognized yet. You need to awaken or show enough cursed energy to be given an unregistered grade first."

			fireMajorPopup(
				player,
				"JUJUTSU HIGH REJECTION",
				"Your application was reviewed by the jujutsu world.",
				"Rejected",
				"You need an unregistered sorcerer grade before official registration."
			)
		else
			local acceptancePower = (stats.CursedEnergy or 0) + ((stats.Smarts or 0) * 0.8) + ((stats.Reputation or 0) * 2) + math.random(1, 45)

			if stats.FamilyType == "Sorcerer" then
				acceptancePower += 20
			elseif stats.FamilyType == "Unknown" then
				acceptancePower += 10
			elseif stats.FamilyType == "Fallen" then
				acceptancePower += 12
			elseif stats.Origin == "Cursed Womb" then
				acceptancePower += 15
			end

			if acceptancePower >= 55 then
				local officialGrade = getEstimatedUnregisteredGrade(stats)

				stats.InJujutsuHigh = true
				stats.RegisteredSorcerer = true
				stats.Grade = officialGrade
				stats.OfficialGrade = officialGrade
				stats.UnregisteredGrade = nil
				stats.UnregisteredProgress = 0
				stats.UnregisteredGradeUps = 0

				stats.Reputation += 10
				stats.Happiness = math.clamp((stats.Happiness or 100) + 12, 0, 100)
				logMessage = "You were accepted into Jujutsu High and officially registered as <b>" .. tostring(officialGrade) .. "</b>."

				local teacher = BitKaisenRelationships.AddTeacher(stats)

				fireMajorPopup(
					player,
					"JUJUTSU HIGH ACCEPTANCE",
					"Your application was reviewed by the jujutsu world.",
					"Accepted",
					"Your unregistered grade became official."
				)

				if teacher then
					logMessage = logMessage .. "\n" .. teacher.Name .. " was assigned as one of your instructors."

					fireMajorPopup(
						player,
						"TEACHER ASSIGNED",
						"Someone at Jujutsu High will be watching your progress.",
						teacher.Name,
						"Teachers can submit promotion recommendations."
					)
				end
			else
				stats.Happiness = math.clamp((stats.Happiness or 100) - 10, 0, 100)
				logMessage = "Jujutsu High rejected your application. Your unregistered grade was noted, but your cursed energy control was not convincing enough yet."

				fireMajorPopup(
					player,
					"JUJUTSU HIGH REJECTION",
					"Your application was reviewed by the jujutsu world.",
					"Rejected",
					"Train harder and improve your cursed energy."
				)
			end
		end

	elseif activityId == "black_flash_training" then
		if math.random(1, 100) <= 20 then
			stats.CursedEnergy += math.random(25, 45)
			stats.Reputation += math.random(10, 20)
			stats.Happiness = math.clamp((stats.Happiness or 100) + 10, 0, 100)

			logMessage = "For a split second, your cursed energy aligned perfectly with your movement."

			fireMajorPopup(
				player,
				"BLACK FLASH",
				"For one instant, your cursed energy aligned perfectly with your strike.",
				"Black Flash",
				"You will remember that feeling."
			)
		else
			stats.Health = math.clamp((stats.Health or 100) - math.random(10, 25), 0, 100)
			stats.CursedEnergy += math.random(5, 12)
			logMessage = "Your timing was off during Black Flash training."
		end

	elseif activityId == "mission_review" then
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(3, 7), 0, 100)
		stats.Reputation += math.random(1, 4)
		logMessage = "You reviewed past mission records and noticed mistakes that most students would have missed."

	elseif activityId == "mentor_younger_sorcerers" then
		stats.Reputation += math.random(4, 10)
		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(2, 7), 0, 100)
		logMessage = "You mentored younger sorcerers and helped them understand the dangers of cursed energy."

	elseif activityId == "retirement_reflection" then
		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(3, 12), 0, 100)
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(1, 4), 0, 100)
		logMessage = "You reflected on your life, the curses you survived, and the people who shaped you."
	elseif activityId == "physical_conditioning" then
		stats.Health = math.clamp((stats.Health or 100) + math.random(5, 12), 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(0, 3), 0, 100)
		stats.CursedEnergy += math.random(1, 4)
		logMessage = "You trained your body until your muscles burned. Your body felt more ready for curse work."

	elseif activityId == "barrier_drills" then
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(4, 9), 0, 100)
		stats.CursedEnergy += math.random(3, 8)
		stats.Reputation += math.random(0, 2)
		logMessage = "You practiced barrier drills, curtain response, and veil reading until the shapes started making sense."

	elseif activityId == "patrol_city" then
		local reward = math.random(45, 130)
		stats.Money += reward
		stats.Reputation += math.random(1, 4)
		stats.CursedEnergy += math.random(2, 7)

		if math.random(1, 100) <= 20 then
			stats.Health = math.clamp((stats.Health or 100) - math.random(3, 10), 0, 100)
			logMessage = "You patrolled the city and handled a weak curse trace, but it still managed to wear you down. You earned $" .. tostring(reward) .. "."
		else
			logMessage = "You patrolled the city and cleared minor curse traces before they became real incidents. You earned $" .. tostring(reward) .. "."
		end

	elseif activityId == "cursed_tool_practice" then
		local assetBonuses = BitKaisenAssets.GetPassiveBonuses(stats)
		local missionBonus = assetBonuses.MissionPowerBonus or 0

		stats.CursedEnergy += math.random(2, 6)
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(1, 4), 0, 100)
		stats.Reputation += math.random(1, 3)

		if missionBonus > 0 then
			logMessage = "You practiced cursed tool control using your own equipment. Your mission instincts sharpened."
		else
			logMessage = "You practiced cursed tool control with basic equipment. It was rough, but useful."
		end

	elseif activityId == "student_training_review" then
		if not stats.ClanFounded then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need to found a clan before reviewing student training.")
			return
		end

		local studentCount = countClanStudents(stats)
		if studentCount <= 0 then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need recruited students before you can review their training.")
			return
		end

		stats.ClanTrainingSessions = (stats.ClanTrainingSessions or 0) + 1
		stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + math.random(2, 6))
		stats.Reputation += math.random(1, 4)
		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(1, 4), 0, 100)

		for _, relationship in ipairs(stats.Relationships or {}) do
			if relationship.Alive ~= false and relationship.Role == "Student" then
				BitKaisenRelationships.AdjustRelationship(relationship, {
					Bond = math.random(1, 3),
					Trust = math.random(1, 3),
					Respect = math.random(2, 5)
				})
			end
		end

		logMessage = "You reviewed your students' training and corrected sloppy cursed energy habits. Your dojo's reputation improved."

	elseif activityId == "clan_admin" then
		if not stats.ClanFounded then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need to found a clan before managing clan affairs.")
			return
		end

		local adminRoll = math.random(1, 100)
		stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + math.random(1, 5))
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(1, 4), 0, 100)

		if adminRoll <= 20 then
			adjustDojoCondition(stats, -math.random(2, 7))
			logMessage = "You handled clan affairs, but an argument between students damaged the dojo's condition."
		else
			stats.Money += math.random(100, 350)
			logMessage = "You handled clan records, payments, and student issues. The clan felt more stable."
		end

	elseif activityId == "domain_foundation_study" then
		local oldMastery = stats.TechniqueMastery or 0
		local gain = math.random(2, 6)

		if (stats.Smarts or 0) >= 70 then
			gain += 2
		end

		stats.TechniqueMastery = math.clamp(oldMastery + gain, 0, 100)
		stats.CursedEnergy += math.random(6, 14)
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(3, 7), 0, 100)
		stats.Health = math.clamp((stats.Health or 100) - math.random(2, 7), 0, 100)

		logMessage = "You studied domain foundations and tried to understand how your innate technique would shape a territory."
		logMessage = logMessage .. "\nTechnique Mastery increased by <b>" .. tostring(stats.TechniqueMastery - oldMastery) .. "%</b>."

		if stats.TechniqueMastery >= 80 and oldMastery < 80 then
			fireMajorPopup(
				player,
				"DOMAIN FOUNDATION",
				"Your understanding of your cursed technique started approaching domain-level theory.",
				"Domain Foundation",
				"You are not there yet, but the shape is starting to exist."
			)
		end

	elseif activityId == "binding_vow_research" then
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(4, 10), 0, 100)
		stats.CursedEnergy += math.random(2, 8)

		if math.random(1, 100) <= 15 then
			stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(4, 9), 0, 100)
			logMessage = "You researched binding vows and realized how dangerous forced restrictions can become."
		else
			stats.Reputation += math.random(0, 3)
			logMessage = "You researched binding vows and learned how sorcerers trade freedom for power."
		end

	end

	logMessage = logMessage .. applyTraitBuffsFromSnapshot(stats, traitBefore, "Activity")
	logMessage = maybeTeacherRecommendation(player, stats, logMessage)
	logMessage = checkPromotionAndPopup(player, stats, logMessage)

	if stats.Health <= 0 then
		stats.Alive = false
		logMessage = logMessage .. "\nYour body could not handle the strain."
	end

	fireLifeUpdate(player, stats, logMessage)
	saveStats(player)
end

function getAdviceTopic(stats, relationship)
	local topics = {
		"cursed energy control",
		"how to stay calm around curses",
		"the strange things you keep sensing",
		"how to survive in the jujutsu world",
		"your future as a sorcerer"
	}

	if stats.CursedTechnique and stats.CursedTechnique ~= "None" then
		table.insert(topics, "your cursed technique")
		table.insert(topics, tostring(stats.CursedTechnique))
	end

	if relationship.Role == "Teacher" then
		table.insert(topics, "promotion reviews")
		table.insert(topics, "mission discipline")
	end

	if relationship.Role == "Mother" or relationship.Role == "Father" or relationship.Role == "Caretaker" then
		table.insert(topics, "your family history")
	end

	return pickRandom(topics)
end


local FREE_RELATIONSHIP_ACTIONS = {
	divorce = true
}

local FAMILY_RELATIONSHIP_ROLES = {
	Mother = true,
	Father = true,
	Caretaker = true,
	Sibling = true,
	Child = true,
}

local ROMANCE_ALLOWED_RELATIONSHIP_ROLES = {
	Friend = true,
	["Best Friend"] = true,
	Classmate = true,
	["Mission Partner"] = true,
}

function appendLine(baseText, extraText)
	if not extraText or extraText == "" then
		return baseText or ""
	end

	if baseText and baseText ~= "" then
		return baseText .. "\n" .. extraText
	end

	return extraText
end

function isFamilyRelationshipRole(role)
	return FAMILY_RELATIONSHIP_ROLES[tostring(role or "")] == true
end

function canGainRomanceFromGift(relationship)
	local role = tostring(relationship.Role or "")

	if role == "Partner" or role == "Spouse" then
		return true
	end

	if ROMANCE_ALLOWED_RELATIONSHIP_ROLES[role] and (relationship.Romance or 0) > 0 then
		return true
	end

	return false
end

function applyRelationshipMilestones(player, stats, relationship)
	local role = tostring(relationship.Role or "")
	local message = ""

	if relationship.Alive == false then
		return message
	end

	if role == "Classmate" and (relationship.Bond or 0) >= 60 and (relationship.Trust or 0) >= 45 then
		relationship.Role = "Friend"
		relationship.Status = "Friend"
		message = appendLine(message, relationship.Name .. " became more than just a classmate. They are now your friend.")

		fireMajorPopup(
			player,
			"FRIENDSHIP FORMED",
			relationship.Name .. " started trusting you outside of school life.",
			relationship.Name,
			"They are now listed as a friend."
		)
	elseif role == "Friend" and (relationship.Bond or 0) >= 80 and (relationship.Trust or 0) >= 65 then
		relationship.Role = "Best Friend"
		relationship.Status = "Best Friend"
		message = appendLine(message, relationship.Name .. " became one of the closest people in your life.")

		fireMajorPopup(
			player,
			"BEST FRIEND",
			"Your connection with " .. relationship.Name .. " reached a new level.",
			relationship.Name,
			"They are now your best friend."
		)
	elseif role == "Rival" and (relationship.Respect or 0) >= 90 and (relationship.Trust or 0) >= 45 then
		relationship.Role = "Mission Partner"
		relationship.Status = "Trusted Rival"
		message = appendLine(message, relationship.Name .. " stopped treating you like an enemy and started treating you like someone worth fighting beside.")

		fireMajorPopup(
			player,
			"RIVALRY EVOLVED",
			relationship.Name .. " finally acknowledged your growth.",
			"Mission Partner",
			"They can now stand beside you during dangerous work."
		)
	end

	return message
end

function processRelationshipAction(player, relationshipId, actionId)
	local stats = playerLives[player.UserId]

	if not stats or not stats.Alive then
		return
	end

	ensureExtraStats(stats)

	if typeof(relationshipId) ~= "string" or typeof(actionId) ~= "string" then
		return
	end

	local relationship = getRelationshipById(stats, relationshipId)

	if not relationship then
		fireLifeUpdate(player, stats, "That relationship could not be found.")
		return
	end

	local freeRelationshipAction = FREE_RELATIONSHIP_ACTIONS[actionId] == true
	stats.RelationshipActionsThisAge = stats.RelationshipActionsThisAge or 0

	if stats.RelationshipActionsThisAge >= 3 and not freeRelationshipAction then
		fireLifeUpdate(player, stats, "You already used all 3 relationship actions this year. Age up first.")
		return
	end

	local logMessage = ""
	local relationshipActionCostsTurn = not freeRelationshipAction
	local traitBefore = captureTraitBuffSnapshot(stats, relationship)

	if actionId == "talk" then
		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(1, 4),
			Trust = math.random(1, 3)
		})

		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(1, 3), 0, 100)

		local talkLines = {
			"You talked with " .. relationship.Name .. " about the strange direction your life has been taking.",
			relationship.Name .. " listened while you spoke about the pressure building around you.",
			"You had a quiet conversation with " .. relationship.Name .. " about curses, family, and the future.",
			"You and " .. relationship.Name .. " talked for a while. It helped more than you expected."
		}

		logMessage = pickRandom(talkLines)

	elseif actionId == "spend_time" then
		stats.ActivitiesDoneThisAge += 1

		local romanceGain = 0

		if relationship.Role == "Partner" or relationship.Role == "Spouse" then
			romanceGain = math.random(2, 5)
		end

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(4, 9),
			Trust = math.random(2, 5),
			Romance = romanceGain
		})

		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(4, 10), 0, 100)

		local spendLines = {
			"You spent the day with " .. relationship.Name .. ", keeping your mind away from curses for once.",
			relationship.Name .. " stayed with you for most of the day, and things felt normal for a while.",
			"You spent time with " .. relationship.Name .. ". The bond between you felt a little stronger afterward.",
			"You and " .. relationship.Name .. " passed the time together, talking about nothing and everything."
		}

		logMessage = pickRandom(spendLines)

	elseif actionId == "flirt" then
		if (stats.Age or 0) < 13 then
			fireLifeUpdate(player, stats, "You are too young for that.")
			return
		end

		local allowedRoles = {
			Friend = true,
			["Best Friend"] = true,
			Classmate = true,
			["Mission Partner"] = true
		}

		if not allowedRoles[relationship.Role] then
			fireLifeUpdate(player, stats, "That relationship cannot become romantic.")
			return
		end

		stats.ActivitiesDoneThisAge += 1

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Romance = math.random(10, 20),
			Bond = math.random(2, 5),
			Trust = math.random(0, 3)
		})

		local flirtLines = {
			"You flirted with " .. relationship.Name .. ". They seemed to notice.",
			"You tried flirting with " .. relationship.Name .. ", and the moment actually landed.",
			"You and " .. relationship.Name .. " shared a moment that felt different from usual.",
			"You flirted with " .. relationship.Name .. ". The tension between you shifted slightly."
		}

		logMessage = pickRandom(flirtLines)

	elseif actionId == "ask_out" then
		if (stats.Age or 0) < 13 then
			fireLifeUpdate(player, stats, "You are too young for that.")
			return
		end

		local allowedRoles = {
			Friend = true,
			["Best Friend"] = true,
			Classmate = true,
			["Mission Partner"] = true
		}

		if not allowedRoles[relationship.Role] then
			fireLifeUpdate(player, stats, "That relationship cannot become romantic.")
			return
		end

		if (relationship.Bond or 0) < 40 or (relationship.Trust or 0) < 25 or (relationship.Romance or 0) < 30 then
			fireLifeUpdate(player, stats, "You thought about asking " .. relationship.Name .. " out, but the relationship was not there yet.")
			return
		end

		stats.ActivitiesDoneThisAge += 1

		local chance = 20
		chance += math.floor((relationship.Bond or 0) / 4)
		chance += math.floor((relationship.Trust or 0) / 5)
		chance += math.floor((relationship.Romance or 0) / 3)
		chance += math.floor((BitKaisenTraits.GetModifier(stats, "RomanceGainMult", 1) - 1) * 20)
		chance += math.floor((BitKaisenTraits.GetModifier(relationship, "RomanceGainMult", 1) - 1) * 20)

		chance = math.clamp(chance, 15, 92)

		if math.random(1, 100) <= chance then
			relationship.Role = "Partner"
			relationship.Status = "Dating"
			relationship.YearsDating = 0

			BitKaisenRelationships.AdjustRelationship(relationship, {
				Bond = math.random(6, 12),
				Trust = math.random(4, 8),
				Romance = math.random(12, 24)
			})

			stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(8, 16), 0, 100)

			logMessage = "You asked " .. relationship.Name .. " out. They said yes, and the two of you started dating."

			fireMajorPopup(
				player,
				"RELATIONSHIP STARTED",
				"You asked someone important out.",
				relationship.Name,
				"They are now your partner."
			)
		else
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Bond = -math.random(2, 6),
				Trust = -math.random(1, 4),
				Romance = -math.random(4, 10)
			})

			stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(4, 10), 0, 100)

			logMessage = "You asked " .. relationship.Name .. " out, but they did not feel the same way."
		end

	elseif actionId == "train_together" then
		if (stats.Age or 0) < 8 then
			fireLifeUpdate(player, stats, "You are too young to train with someone.")
			return
		end

		stats.ActivitiesDoneThisAge += 1

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(2, 6),
			Respect = math.random(3, 8)
		})

		stats.CursedEnergy += math.random(4, 12)
		stats.Health = math.clamp((stats.Health or 100) - math.random(1, 5), 0, 100)

		local trainLines = {
			"You trained with " .. relationship.Name .. ", pushing your cursed energy until your body started to ache.",
			relationship.Name .. " helped you sharpen your cursed energy control during training.",
			"You and " .. relationship.Name .. " trained together. It was rough, but neither of you backed down.",
			"Training with " .. relationship.Name .. " forced you to control your cursed energy under pressure."
		}

		logMessage = pickRandom(trainLines)

	elseif actionId == "ask_advice" then
		stats.ActivitiesDoneThisAge += 1

		local adviceBonus = math.random(2, 6)

		if relationship.Role == "Teacher" or relationship.Role == "Father" or relationship.Role == "Mother" or relationship.Role == "Caretaker" then
			adviceBonus += 3
		end

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Trust = math.random(1, 4),
			Respect = math.random(1, 4)
		})

		stats.Smarts = math.clamp((stats.Smarts or 0) + adviceBonus, 0, 100)

		local topic = getAdviceTopic(stats, relationship)

		local adviceLines = {
			"You asked " .. relationship.Name .. " for advice about " .. topic .. ".",
			relationship.Name .. " gave you advice about " .. topic .. ", and it stayed with you.",
			"You went to " .. relationship.Name .. " for guidance on " .. topic .. ".",
			relationship.Name .. " helped you understand more about " .. topic .. "."
		}

		logMessage = pickRandom(adviceLines)

	elseif actionId == "check_in" then
		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(1, 3),
			Trust = math.random(2, 5),
			Fear = -math.random(0, 2)
		})

		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(1, 4), 0, 100)

		local checkLines = {
			"You checked in on " .. relationship.Name .. " instead of only showing up when you needed something.",
			relationship.Name .. " seemed surprised that you asked how they were doing.",
			"You took a moment to check on " .. relationship.Name .. ". It made the connection feel less one-sided.",
			"You and " .. relationship.Name .. " had a short, honest check-in. Nothing dramatic, but it mattered."
		}

		logMessage = pickRandom(checkLines)

	elseif actionId == "deep_talk" then
		if (relationship.Bond or 0) < 20 and (relationship.Trust or 0) < 15 then
			fireLifeUpdate(player, stats, relationship.Name .. " was not ready for that kind of conversation yet.")
			return
		end

		stats.ActivitiesDoneThisAge += 1

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(4, 9),
			Trust = math.random(5, 11),
			Respect = math.random(1, 4),
			Fear = -math.random(0, 3)
		})

		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(2, 7), 0, 100)

		local deepLines = {
			"You had a real conversation with " .. relationship.Name .. " about fear, pressure, and the jujutsu world.",
			"You and " .. relationship.Name .. " talked past the usual small talk. The trust between you shifted.",
			relationship.Name .. " opened up more than usual, and you actually listened.",
			"You spoke with " .. relationship.Name .. " about the kind of person you are becoming."
		}

		logMessage = pickRandom(deepLines)

	elseif actionId == "give_gift" then
		local giftCost = 1000

		if relationship.Role == "Partner" or relationship.Role == "Spouse" then
			giftCost = 2500
		elseif relationship.Role == "Child" then
			giftCost = 750
		elseif relationship.Role == "Teacher" then
			giftCost = 1500
		end

		if (stats.Money or 0) < giftCost then
			fireLifeUpdate(player, stats, "You need $" .. tostring(giftCost) .. " to buy a meaningful gift for " .. relationship.Name .. ".")
			return
		end

		stats.Money -= giftCost

		local romanceGain = 0
		if canGainRomanceFromGift(relationship) then
			romanceGain = math.random(2, 6)
		end

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(4, 9),
			Trust = math.random(1, 4),
			Romance = romanceGain
		})

		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(1, 5), 0, 100)

		local giftLines = {
			"You bought a gift for " .. relationship.Name .. ". It was not flashy, but it showed you were paying attention.",
			relationship.Name .. " accepted your gift and seemed to understand the thought behind it.",
			"You spent $" .. tostring(giftCost) .. " on something for " .. relationship.Name .. ". The gesture landed well.",
			"You gave " .. relationship.Name .. " something useful instead of just saying you cared."
		}

		logMessage = pickRandom(giftLines)

	elseif actionId == "study_together" then
		if (stats.Age or 0) < 8 then
			fireLifeUpdate(player, stats, "You are too young to study seriously with someone.")
			return
		end

		stats.ActivitiesDoneThisAge += 1

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(2, 5),
			Trust = math.random(2, 5),
			Respect = math.random(2, 6)
		})

		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(2, 6), 0, 100)

		if stats.CursedTechnique and stats.CursedTechnique ~= "None" then
			stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + math.random(0, 2), 0, 100)
		end

		logMessage = "You studied with " .. relationship.Name .. ", comparing notes on curses, missions, and bad habits you needed to fix."

	elseif actionId == "spar" then
		if (stats.Age or 0) < 10 then
			fireLifeUpdate(player, stats, "You are too young to spar seriously.")
			return
		end

		if relationship.Role == "Mother" or relationship.Role == "Father" or relationship.Role == "Caretaker" or relationship.Role == "Child" then
			fireLifeUpdate(player, stats, "That is not the kind of relationship you should spar with.")
			return
		end

		stats.ActivitiesDoneThisAge += 1

		local cleanSession = math.random(1, 100) <= math.clamp((stats.Smarts or 0) + (relationship.Respect or 0), 15, 90)

		stats.CursedEnergy += math.random(4, 11)
		stats.Health = math.clamp((stats.Health or 100) - math.random(1, cleanSession and 4 or 9), 0, 100)

		if stats.CursedTechnique and stats.CursedTechnique ~= "None" then
			stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + math.random(1, 3), 0, 100)
		end

		if relationship.CursedEnergy then
			relationship.CursedEnergy = (relationship.CursedEnergy or 0) + math.random(1, 5)
		end

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(1, 5),
			Respect = math.random(4, 9),
			Fear = cleanSession and 0 or math.random(1, 3)
		})

		if cleanSession then
			logMessage = "You sparred with " .. relationship.Name .. ". The session was rough, but controlled enough to build real respect."
		else
			logMessage = "You sparred with " .. relationship.Name .. ", but the session got messy and left both of you tense."
		end

	elseif actionId == "apologize" then
		local sincereChance = 35 + math.floor((stats.Smarts or 0) / 3) + math.floor((relationship.Bond or 0) / 6)
		sincereChance = math.clamp(sincereChance, 20, 85)

		if math.random(1, 100) <= sincereChance then
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Bond = math.random(1, 4),
				Trust = math.random(4, 9),
				Respect = math.random(0, 3),
				Fear = -math.random(0, 2)
			})

			logMessage = "You apologized to " .. relationship.Name .. " without trying to win the conversation. The trust between you recovered a little."
		else
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Trust = -math.random(1, 4),
				Respect = -math.random(0, 2)
			})

			logMessage = "You tried apologizing to " .. relationship.Name .. ", but it sounded forced and made things awkward."
		end

	elseif actionId == "family_time" then
		if not isFamilyRelationshipRole(relationship.Role) then
			fireLifeUpdate(player, stats, "That action is only for family relationships.")
			return
		end

		stats.ActivitiesDoneThisAge += 1

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(5, 11),
			Trust = math.random(3, 8),
			Fear = -math.random(0, 3)
		})

		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(4, 10), 0, 100)

		logMessage = "You spent real family time with " .. relationship.Name .. ", away from missions, grades, and cursed energy."

	elseif actionId == "mentor_session" then
		if relationship.Role ~= "Teacher" then
			fireLifeUpdate(player, stats, "Only teachers can run a mentor session.")
			return
		end

		if not stats.InJujutsuHigh then
			fireLifeUpdate(player, stats, "You need to be enrolled in Jujutsu High first.")
			return
		end

		stats.ActivitiesDoneThisAge += 1

		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(2, 5), 0, 100)
		stats.CursedEnergy += math.random(5, 12)

		if stats.CursedTechnique and stats.CursedTechnique ~= "None" then
			stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + math.random(2, 5), 0, 100)
		end

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Trust = math.random(2, 5),
			Respect = math.random(4, 9)
		})

		if math.random(1, 100) <= 12 + math.floor((relationship.Respect or 0) / 10) then
			stats.TeacherRecommendations += 1
			logMessage = relationship.Name .. " ran a mentor session with you and later added a quiet recommendation to your record."
		else
			logMessage = relationship.Name .. " ran a mentor session with you, correcting the flaws in your cursed energy control."
		end

	elseif actionId == "pair_mission" then
		if (stats.Age or 0) < 16 then
			fireLifeUpdate(player, stats, "You need to be at least 16 to take a paired mission.")
			return
		end

		local allowedPairRoles = {
			Friend = true,
			["Best Friend"] = true,
			Classmate = true,
			["Mission Partner"] = true,
			Rival = true,
		}

		if not allowedPairRoles[relationship.Role] then
			fireLifeUpdate(player, stats, "That person is not suited for a paired mission.")
			return
		end

		stats.ActivitiesDoneThisAge += 1

		local missionPower = calculatePlayerPower(stats) + ((relationship.CursedEnergy or 0) * 0.4) + ((relationship.Respect or 0) * 0.5)
		local difficulty = math.random(70, 160)

		if missionPower >= difficulty then
			stats.Money += math.random(1200, 3500)
			stats.Reputation += math.random(3, 9)
			stats.MissionsCompleted += 1

			BitKaisenRelationships.AdjustRelationship(relationship, {
				Bond = math.random(3, 8),
				Trust = math.random(3, 8),
				Respect = math.random(4, 10),
				Fear = -math.random(0, 2)
			})

			logMessage = "You took a paired mission with " .. relationship.Name .. ". The job went clean, and the two of you came back with more respect for each other."
		else
			stats.Health = math.clamp((stats.Health or 100) - math.random(8, 18), 0, 100)
			stats.Reputation = (stats.Reputation or 0 - math.random(0, 3))
			stats.MissionsFailed += 1

			BitKaisenRelationships.AdjustRelationship(relationship, {
				Bond = math.random(0, 3),
				Trust = -math.random(1, 5),
				Respect = math.random(1, 4),
				Fear = math.random(1, 5)
			})

			logMessage = "You took a paired mission with " .. relationship.Name .. ", but the job turned ugly and exposed problems in your teamwork."
		end

	elseif actionId == "ask_recommendation" then
		if relationship.Role ~= "Teacher" then
			fireLifeUpdate(player, stats, "Only teachers can submit promotion recommendations.")
			return
		end

		if not stats.InJujutsuHigh then
			fireLifeUpdate(player, stats, "You need to be enrolled in Jujutsu High first.")
			return
		end

		stats.ActivitiesDoneThisAge += 1

		local chance = 20
		chance += math.floor((relationship.Respect or 0) / 4)
		chance += math.floor((relationship.Trust or 0) / 6)

		if stats.Reputation >= 20 then
			chance += 10
		end

		if stats.ClanFounded then
			chance += 5
		end

		if math.random(1, 100) <= chance then
			stats.TeacherRecommendations += 1

			BitKaisenRelationships.AdjustRelationship(relationship, {
				Trust = math.random(1, 3),
				Respect = math.random(2, 5)
			})

			logMessage = relationship.Name .. " reviewed your recent progress and submitted a recommendation for your promotion review."

			fireMajorPopup(
				player,
				"TEACHER RECOMMENDATION",
				relationship.Name .. " reviewed your progress and submitted a recommendation.",
				"Recommendation Added",
				"Recommendations help you advance through semi-grades."
			)
		else
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Respect = math.random(1, 3),
				Trust = -math.random(1, 3)
			})

			logMessage = relationship.Name .. " refused to recommend you yet, saying your record still needed more proof."
		end

	elseif actionId == "compliment" then
		local romanceGain = 0

		if relationship.Role == "Partner" or relationship.Role == "Spouse" then
			romanceGain = math.random(3, 8)
		end

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(2, 5),
			Trust = math.random(1, 3),
			Romance = romanceGain
		})

		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(1, 4), 0, 100)

		local complimentLines = {
			"You complimented " .. relationship.Name .. " on how they handled themselves lately.",
			"You said something kind to " .. relationship.Name .. ", and they seemed to appreciate it.",
			"You gave " .. relationship.Name .. " a genuine compliment instead of brushing the moment off.",
			relationship.Name .. " looked caught off guard when you complimented them, but they smiled anyway."
		}

		logMessage = pickRandom(complimentLines)

	elseif actionId == "argue" then
		stats.ActivitiesDoneThisAge += 1

		local wonArgument = math.random(1, 100) <= ((stats.Smarts or 0) + 20)

		if wonArgument then
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Bond = -math.random(2, 6),
				Respect = math.random(2, 6),
				Trust = -math.random(1, 4)
			})

			local winLines = {
				"You argued with " .. relationship.Name .. " about your choices, but they respected that you stood your ground.",
				"You and " .. relationship.Name .. " clashed over your path, but your point landed.",
				"Your argument with " .. relationship.Name .. " got heated, but they could not ignore what you said."
			}

			logMessage = pickRandom(winLines)
		else
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Bond = -math.random(4, 10),
				Trust = -math.random(2, 6),
				Respect = -math.random(1, 4)
			})

			stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(2, 6), 0, 100)

			local loseLines = {
				"You argued with " .. relationship.Name .. ", and the conversation ended badly.",
				"You and " .. relationship.Name .. " fought over something that clearly mattered to both of you.",
				"Your argument with " .. relationship.Name .. " left the relationship colder than before."
			}

			logMessage = pickRandom(loseLines)
		end

	elseif actionId == "propose" then
		if (stats.Age or 0) < 18 then
			fireLifeUpdate(player, stats, "You need to be at least 18 to propose.")
			return
		end

		if relationship.Role ~= "Partner" then
			fireLifeUpdate(player, stats, "You can only propose to your partner.")
			return
		end

		local ownsRing = ownsAssetById(stats, "wedding_ring")

		if not ownsRing then
			fireLifeUpdate(player, stats, "You need a <b>Wedding Ring</b> before you can propose.")
			return
		end

		local marriageReqMult = BitKaisenTraits.GetModifier(stats, "MarriageReqMult", 1) * BitKaisenTraits.GetModifier(relationship, "MarriageReqMult", 1)
		local neededDatingYears = math.max(1, math.floor((3 * marriageReqMult) + 0.5))
		local neededBond = math.clamp(math.floor((85 * marriageReqMult) + 0.5), 55, 95)
		local neededTrust = math.clamp(math.floor((80 * marriageReqMult) + 0.5), 50, 95)
		local neededRomance = math.clamp(math.floor((80 * marriageReqMult) + 0.5), 50, 95)

		if (relationship.YearsDating or 0) < neededDatingYears then
			fireLifeUpdate(player, stats, "You thought about proposing to " .. relationship.Name .. ", but the relationship had not been serious long enough yet. Date for at least " .. tostring(neededDatingYears) .. " year" .. (neededDatingYears == 1 and "" or "s") .. " first.")
			return
		end

		if (relationship.Bond or 0) < neededBond or (relationship.Trust or 0) < neededTrust or (relationship.Romance or 0) < neededRomance then
			fireLifeUpdate(player, stats, "You thought about proposing to " .. relationship.Name .. ", but the relationship was not strong enough yet. Aim for " .. tostring(neededBond) .. " Bond, " .. tostring(neededTrust) .. " Trust, and " .. tostring(neededRomance) .. " Romance.")
			return
		end

		relationship.Role = "Spouse"
		relationship.Status = "Married"
		relationship.YearsMarried = 0
		relationship.Romance = 100
		relationship.Bond = 100
		relationship.Trust = 100

		stats.Happiness = math.clamp((stats.Happiness or 100) + 20, 0, 100)

		logMessage = "You proposed to " .. relationship.Name .. " with a wedding ring. After everything you survived together, they accepted."

		fireMajorPopup(
			player,
			"MARRIAGE",
			"Your relationship reached a new stage.",
			relationship.Name,
			"They are now your spouse."
		)

	elseif actionId == "start_family" then
		if (stats.Age or 0) < 18 then
			fireLifeUpdate(player, stats, "You need to be at least 18 to start a family.")
			return
		end

		if relationship.Role ~= "Spouse" then
			fireLifeUpdate(player, stats, "You need to be married before starting a family.")
			return
		end

		if (relationship.Bond or 0) < 70 or (relationship.Trust or 0) < 70 or (relationship.Romance or 0) < 70 then
			fireLifeUpdate(player, stats, "You and " .. relationship.Name .. " talked about starting a family, but the relationship needed more stability first. Aim for 70 Bond, 70 Trust, and 70 Romance.")
			return
		end

		local chance = 35
		chance += math.floor((relationship.Romance or 0) / 4)
		chance += math.floor((relationship.Bond or 0) / 7)
		chance += math.floor((stats.Happiness or 0) / 9)
		chance += math.floor((BitKaisenTraits.GetModifier(stats, "FamilyGainMult", 1) - 1) * 25)
		chance += math.floor((BitKaisenTraits.GetModifier(relationship, "FamilyGainMult", 1) - 1) * 25)
		chance = math.clamp(chance, 25, 95)

		if math.random(1, 100) <= chance then
			local child = BitKaisenRelationships.AddChild(stats, nil, relationship.Name)

			BitKaisenRelationships.AdjustRelationship(relationship, {
				Bond = math.random(3, 8),
				Trust = math.random(2, 6),
				Romance = math.random(1, 4)
			})

			stats.Happiness = math.clamp((stats.Happiness or 100) + 18, 0, 100)

			logMessage = "You and " .. relationship.Name .. " decided to start a family. Later that year, you welcomed a child named " .. child.Name .. "."

			fireMajorPopup(
				player,
				"CHILD BORN",
				"Your family grew.",
				child.Name,
				"They have been added to your Relationships page."
			)
		else
			stats.Happiness = math.clamp((stats.Happiness or 100) - 3, 0, 100)
			logMessage = "You and " .. relationship.Name .. " talked about starting a family, but the timing did not feel right yet."
		end

	elseif actionId == "divorce" then
		if relationship.Role ~= "Spouse" then
			fireLifeUpdate(player, stats, "You can only divorce your current spouse.")
			return
		end

		if pendingMissions[player.UserId] then
			fireLifeUpdate(player, stats, "You cannot divorce during an active mission/event. Finish the situation first.")
			return
		end

		local oldName = relationship.Name or "your spouse"
		local yearsMarried = tonumber(relationship.YearsMarried) or 0

		relationship.WasSpouse = true
		relationship.Divorced = true
		relationship.Role = "Ex-Spouse"
		relationship.Status = "Divorced"
		relationship.Romance = 0
		relationship.Trust = math.clamp((relationship.Trust or 0) - 45, 0, 100)
		relationship.Bond = math.clamp((relationship.Bond or 0) - 30, 0, 100)
		relationship.Respect = math.clamp((relationship.Respect or 0) - 15, 0, 100)
		relationship.YearsDating = relationship.YearsDating or 0
		relationship.YearsMarried = yearsMarried
		relationship.YearsDivorced = 0

		local custodyResult = BitKaisenRelationships.ApplyDivorceCustody(stats, relationship)

		stats.Happiness = math.clamp((stats.Happiness or 100) - 12, 0, 100)

		local custodySummary = ""
		if custodyResult and (custodyResult.Total or 0) > 0 then
			custodySummary = " Custody was decided for " .. tostring(custodyResult.Total) .. " child" .. ((custodyResult.Total == 1) and "" or "ren") .. ": " .. table.concat(custodyResult.Lines or {}, "; ") .. "."
		end

		logMessage = "You divorced " .. oldName .. ". The marriage ended, but any children remain part of your family legacy." .. custodySummary

		fireMajorPopup(
			player,
			"DIVORCE",
			(custodyResult and (custodyResult.Total or 0) > 0) and "The marriage ended and custody was arranged." or "The marriage ended.",
			oldName,
			(custodyResult and (custodyResult.Total or 0) > 0) and "Check your children's info cards for custody." or "They are now listed as your ex-spouse."
		)

	elseif actionId == "adopt_child" then
		if (stats.Age or 0) < 21 then
			fireLifeUpdate(player, stats, "You need to be at least 21 to adopt a child.")
			return
		end

		if relationship.Role ~= "Spouse" then
			fireLifeUpdate(player, stats, "You need to be married before adopting a child.")
			return
		end

		local adoptionCost = 10000

		if (stats.Money or 0) < adoptionCost then
			fireLifeUpdate(player, stats, "Adoption costs $" .. tostring(adoptionCost) .. ".")
			return
		end

		if (stats.Health or 0) < 40 or (stats.Happiness or 0) < 40 then
			fireLifeUpdate(player, stats, "You were not in a stable enough place to adopt yet.")
			return
		end

		stats.Money -= adoptionCost

		local child = BitKaisenRelationships.AddChild(stats, nil, relationship.Name)

		stats.Happiness = math.clamp((stats.Happiness or 100) + 16, 0, 100)

		logMessage = "You and " .. relationship.Name .. " adopted a child named " .. child.Name .. " and brought them into your family."

		fireMajorPopup(
			player,
			"ADOPTION",
			"Your family grew through adoption.",
			child.Name,
			"They have been added to your Relationships page."
		)

	elseif actionId == "discuss_custody" then
		if relationship.Role ~= "Ex-Spouse" then
			fireLifeUpdate(player, stats, "You can only discuss custody with an ex-spouse.")
			return
		end

		local result = BitKaisenRelationships.RebalanceCustody(stats, relationship)

		if result and result.Changed then
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Trust = math.random(2, 5),
				Respect = math.random(1, 4)
			})
			stats.Happiness = math.clamp((stats.Happiness or 100) + 2, 0, 100)
		else
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Trust = -math.random(1, 4),
				Respect = -math.random(0, 3)
			})
			stats.Happiness = math.clamp((stats.Happiness or 100) - 2, 0, 100)
		end

		logMessage = result and result.Message or "You tried to discuss custody, but nothing changed."

	elseif actionId == "custody_visit" then
		if relationship.Role ~= "Child" then
			fireLifeUpdate(player, stats, "You can only schedule custody visits with your child.")
			return
		end

		if (relationship.Age or 0) >= 18 or relationship.Custody == "Independent" then
			fireLifeUpdate(player, stats, relationship.Name .. " is an adult now and does not need custody visits.")
			return
		end

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(3, 7),
			Trust = math.random(2, 5),
			Respect = math.random(0, 3)
		})

		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(1, 4), 0, 100)

		local custody = tostring(relationship.Custody or "With You")
		if custody == "With Ex-Spouse" then
			logMessage = "You arranged a custody visit with " .. relationship.Name .. ". They mostly live with " .. tostring(relationship.CustodyParentName or relationship.OtherParentName or "your ex-spouse") .. ", but you stayed present."
		elseif custody == "Shared" then
			logMessage = "You spent your shared custody time with " .. relationship.Name .. "."
		else
			logMessage = "You spent extra time with " .. relationship.Name .. " and made sure the divorce did not make them feel abandoned."
		end

	elseif actionId == "teach_child" then
		if relationship.Role ~= "Child" then
			fireLifeUpdate(player, stats, "You can only teach your child with this action.")
			return
		end

		stats.ActivitiesDoneThisAge += 1

		relationship.CursedEnergy = (relationship.CursedEnergy or 0) + math.random(1, 5)

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(3, 7),
			Trust = math.random(2, 6),
			Respect = math.random(1, 4)
		})

		logMessage = "You taught " .. relationship.Name .. " about curses, family history, and how dangerous the jujutsu world can be."

	elseif actionId == "protect_child" then
		if relationship.Role ~= "Child" then
			fireLifeUpdate(player, stats, "You can only protect your child with this action.")
			return
		end

		stats.ActivitiesDoneThisAge += 1

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(4, 8),
			Trust = math.random(4, 8),
			Fear = -math.random(1, 4)
		})

		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(2, 6), 0, 100)

		logMessage = "You spent time protecting " .. relationship.Name .. " from the darker parts of the cursed world."

	elseif actionId == "train_child" then
		if relationship.Role ~= "Child" then
			fireLifeUpdate(player, stats, "You can only train your child with this action.")
			return
		end

		if (relationship.Age or 0) < 8 then
			fireLifeUpdate(player, stats, relationship.Name .. " is too young to train cursed energy.")
			return
		end

		stats.ActivitiesDoneThisAge += 1

		relationship.CursedEnergy = (relationship.CursedEnergy or 0) + math.random(4, 10)

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(2, 6),
			Respect = math.random(3, 8),
			Fear = math.random(0, 2)
		})

		logMessage = "You trained " .. relationship.Name .. " in cursed energy control, making sure they understood the danger before the power."

	elseif actionId == "challenge" then
		if relationship.Role ~= "Rival" then
			fireLifeUpdate(player, stats, "You can only challenge a rival.")
			return
		end

		if (stats.Age or 0) < 12 then
			fireLifeUpdate(player, stats, "You are too young to issue a serious challenge.")
			return
		end

		stats.ActivitiesDoneThisAge += 1

		local winChance = 25 + math.floor((stats.CursedEnergy or 0) / 8) + math.floor((stats.TechniqueMastery or 0) / 6) + math.floor((stats.Smarts or 0) / 10)
		winChance = math.clamp(winChance, 20, 85)

		if math.random(1, 100) <= winChance then
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Respect = math.random(8, 14),
				Trust = math.random(2, 5),
				Bond = math.random(1, 4)
			})

			stats.CursedEnergy += math.random(5, 12)
			stats.Reputation += math.random(1, 3)
			stats.Health = math.clamp((stats.Health or 100) - math.random(2, 7), 0, 100)

			logMessage = "You challenged " .. relationship.Name .. " directly and proved you were not someone they could ignore."
		else
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Respect = math.random(2, 6),
				Trust = -math.random(1, 4),
				Fear = math.random(1, 4)
			})

			stats.Health = math.clamp((stats.Health or 100) - math.random(8, 18), 0, 100)
			stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(2, 6), 0, 100)

			logMessage = "You challenged " .. relationship.Name .. ", but the clash exposed the gap between confidence and control."
		end

	elseif actionId == "acknowledge" then
		if relationship.Role ~= "Rival" then
			fireLifeUpdate(player, stats, "That action only makes sense with a rival.")
			return
		end

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Trust = math.random(4, 8),
			Respect = math.random(3, 7),
			Bond = math.random(0, 3),
			Fear = -math.random(0, 2)
		})

		logMessage = "You acknowledged " .. relationship.Name .. " as a real rival instead of treating them like noise. The respect between you shifted."

	elseif actionId == "encourage_child" then
		if relationship.Role ~= "Child" and relationship.Role ~= "Student" then
			fireLifeUpdate(player, stats, "You can only encourage a child or student with this action.")
			return
		end

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(3, 7),
			Trust = math.random(3, 7),
			Respect = math.random(1, 4),
			Fear = -math.random(0, 3)
		})

		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(1, 4), 0, 100)
		logMessage = "You encouraged " .. relationship.Name .. " instead of forcing growth. It helped them feel seen."

	else
		fireLifeUpdate(player, stats, "Invalid relationship action.")
		return
	end

	if relationshipActionCostsTurn then
		stats.RelationshipActionsThisAge = math.clamp((stats.RelationshipActionsThisAge or 0) + 1, 0, 3)
	end

	if actionId == "train_together" or actionId == "spar" or actionId == "study_together" or actionId == "ask_advice" then
		logMessage = awardUnregisteredProgress(player, stats, math.random(4, 10), "Private growth through relationships", logMessage)
	end

	logMessage = checkPromotionAndPopup(player, stats, logMessage)
	logMessage = appendLine(logMessage, applyRelationshipMilestones(player, stats, relationship))

	if stats.Health <= 0 then
		stats.Alive = false
		logMessage = logMessage .. "\nYour body could not handle the strain."
	end

	logMessage = logMessage .. applyTraitBuffsFromSnapshot(stats, traitBefore, "Relationship", relationship)
	syncFamilyStatus(stats)
	fireLifeUpdate(player, stats, logMessage)
	saveStats(player)
end

function processAssetAction(player, actionId, assetId)
	local stats = playerLives[player.UserId]

	if not stats or not stats.Alive then
		return
	end

	ensureExtraStats(stats)

	if typeof(actionId) ~= "string" or typeof(assetId) ~= "string" then
		return
	end

	local asset = BitKaisenAssets.GetAssetById(assetId)

	if not asset then
		fireLifeUpdate(player, stats, "That asset could not be found.")
		return
	end

	local function ownsAsset()
		for _, ownedAsset in ipairs(stats.Assets) do
			if ownedAsset.Id == assetId then
				return true, ownedAsset
			end
		end

		return false, nil
	end

	if actionId == "AskParent" then
		if (stats.Age or 0) >= 16 then
			fireLifeUpdate(player, stats, "You are old enough to buy assets yourself now.")
			return
		end

		local alreadyOwned = ownsAsset()

		if alreadyOwned then
			fireLifeUpdate(player, stats, "You already own <b>" .. asset.Name .. "</b>.")
			return
		end

		local parent = getBestParentOrCaretaker(stats)

		if not parent then
			fireLifeUpdate(player, stats, "You asked for <b>" .. asset.Name .. "</b>, but there was no parent or caretaker to ask.")
			return
		end

		local chance = 25
		chance += math.floor((parent.Bond or 0) / 4)
		chance += math.floor((parent.Trust or 0) / 5)
		chance -= math.floor((asset.Price or 0) / 600)

		chance = math.clamp(chance, 5, 85)

		if math.random(1, 100) <= chance then
			table.insert(stats.Assets, BitKaisenAssets.MakeOwnedAsset(asset))

			BitKaisenRelationships.AdjustRelationship(parent, {
				Bond = math.random(1, 4),
				Trust = math.random(1, 3)
			})

			fireLifeUpdate(
				player,
				stats,
				"You asked " .. parent.Name .. " for <b>" .. asset.Name .. "</b>. After thinking about it, they agreed to get it for you."
			)
		else
			BitKaisenRelationships.AdjustRelationship(parent, {
				Bond = -math.random(1, 3),
				Trust = -math.random(0, 2)
			})

			fireLifeUpdate(
				player,
				stats,
				"You asked " .. parent.Name .. " for <b>" .. asset.Name .. "</b>, but they said no."
			)
		end

	elseif actionId == "Buy" then
		if (stats.Age or 0) < 16 then
			fireLifeUpdate(player, stats, "You are too young to buy assets yourself. Ask a parent or caretaker instead.")
			return
		end

		local alreadyOwned = ownsAsset()

		if alreadyOwned then
			fireLifeUpdate(player, stats, "You already own <b>" .. asset.Name .. "</b>.")
			return
		end

		if (stats.Money or 0) < asset.Price then
			fireLifeUpdate(player, stats, "You do not have enough money to buy <b>" .. asset.Name .. "</b>.")
			return
		end

		stats.Money -= asset.Price
		table.insert(stats.Assets, BitKaisenAssets.MakeOwnedAsset(asset))

		fireLifeUpdate(player, stats, "You bought <b>" .. asset.Name .. "</b> with your own money.")

	elseif actionId == "FoundClan" or string.sub(actionId, 1, 16) == "ConfirmClanName|" then
		if assetId ~= "grand_dojo" then
			fireLifeUpdate(player, stats, "You need a <b>Grand Dojo</b> to found a clan.")
			return
		end

		local owned, ownedAsset = ownsAsset()

		if not owned or not ownedAsset then
			fireLifeUpdate(player, stats, "You need to own a <b>Grand Dojo</b> before founding a clan.")
			return
		end

		if stats.ClanFounded then
			fireLifeUpdate(player, stats, "You already founded the <b>" .. tostring(stats.PlayerClanName or "Unnamed Clan") .. "</b>.")
			return
		end

		if (stats.Age or 0) < 25 then
			fireLifeUpdate(player, stats, "You need to be at least 25 before people will take your clan seriously.")
			return
		end

		local rawClanName = nil
		if string.sub(actionId, 1, 16) == "ConfirmClanName|" then
			rawClanName = string.sub(actionId, 17)
		end

		local clanName, clanBaseName = normalizeClanName(rawClanName or stats.FamilyName or stats.FirstName or "Unnamed", stats.FamilyName or stats.FirstName or "Unnamed")

		stats.ClanFounded = true
		stats.PlayerClanName = clanName
		stats.DojoClanBaseName = clanBaseName
		stats.FamilyType = "Sorcerer Clan"
		stats.OriginCategory = "Clan"
		stats.Clan = clanName
		stats.DojoFounderName = stats.Name or "Unknown"
		stats.DojoNameConfirmed = true
		stats.DojoPendingLastNameChoice = true
		stats.ClanMembers = math.max(1, stats.ClanMembers or 1)
		stats.ClanReputation = math.max(10, stats.ClanReputation or 0)
		stats.ClanStudentsRecruited = stats.ClanStudentsRecruited or 0
		stats.ClanTrainingSessions = stats.ClanTrainingSessions or 0
		stats.DojoLevel = math.max(1, stats.DojoLevel or 1)
		stats.DojoCondition = math.max(70, stats.DojoCondition or 100)
		stats.DojoPrestige = math.max(10, stats.DojoPrestige or 0)
		stats.DojoFocus = stats.DojoFocus or "Balanced"
		stats.DojoStarterRecruitLimit = stats.DojoStarterRecruitLimit or 3
		stats.DojoStarterRecruitsUsed = stats.DojoStarterRecruitsUsed or 0
		stats.Reputation = (stats.Reputation or 0) + 25
		stats.Happiness = math.clamp((stats.Happiness or 100) + 12, 0, 100)

		if #stats.DojoRecruitPool <= 0 then
			generateDojoRecruitPool(stats)
		end

		fireMajorPopup(
			player,
			"CLAN FOUNDED",
			"Your Grand Dojo became the foundation of a new sorcerer clan.",
			stats.PlayerClanName,
			"Choose whether your family name changes, then recruit your first students."
		)

		fireLifeUpdate(
			player,
			stats,
			"You founded the <b>" .. stats.PlayerClanName .. "</b>. The first recruit list has opened at your Grand Dojo."
		)
		saveStats(player)
		return

	elseif actionId == "ChangePlayerLastName" then
		if assetId ~= "grand_dojo" then
			return
		end

		if not stats.ClanFounded then
			fireLifeUpdate(player, stats, "Found your clan first.")
			return
		end

		local baseName = stats.DojoClanBaseName or tostring(stats.PlayerClanName or ""):gsub("%s+[Cc][Ll][Aa][Nn]$", "")
		baseName = tostring(baseName or ""):gsub("^%s+", ""):gsub("%s+$", "")

		if baseName == "" then
			baseName = stats.FamilyName or "Unknown"
		end

		stats.FamilyName = baseName
		stats.FamilyType = "Sorcerer Clan"
		stats.Name = tostring(stats.FirstName or "Unknown") .. " " .. baseName
		stats.DojoFounderName = stats.Name
		stats.DojoPendingLastNameChoice = false

		fireLifeUpdate(player, stats, "You changed your family name to <b>" .. baseName .. "</b> to match the <b>" .. tostring(stats.PlayerClanName or "clan") .. "</b>.")
		saveStats(player)
		return

	elseif actionId == "KeepPlayerLastName" then
		if assetId ~= "grand_dojo" then
			return
		end

		stats.DojoPendingLastNameChoice = false
		fireLifeUpdate(player, stats, "You kept your current family name while leading the <b>" .. tostring(stats.PlayerClanName or "clan") .. "</b>.")
		saveStats(player)
		return

	elseif actionId == "GenerateRecruitPool" then
		if assetId ~= "grand_dojo" then
			return
		end

		local owned = ownsAsset()
		if not owned or not stats.ClanFounded then
			fireLifeUpdate(player, stats, "You need a founded clan and Grand Dojo before opening recruitment.")
			return
		end

		generateDojoRecruitPool(stats)
		fireLifeUpdate(player, stats, "A new list of <b>10 student candidates</b> arrived at your Grand Dojo.")
		saveStats(player)
		return

	elseif string.sub(actionId, 1, 17) == "RecruitCandidate|" then
		if assetId ~= "grand_dojo" then
			return
		end

		local owned = ownsAsset()
		if not owned or not stats.ClanFounded then
			fireLifeUpdate(player, stats, "You need a founded clan and Grand Dojo before recruiting students.")
			return
		end

		local currentStudents = countDojoStudentsAndWards(stats)
		local capacity = getDojoStudentCapacity(stats)
		if currentStudents >= capacity then
			fireLifeUpdate(player, stats, "Your Grand Dojo is at capacity. Upgrade later before taking in more students.")
			return
		end

		local limit = stats.DojoStarterRecruitLimit or 3
		if (stats.DojoStarterRecruitsUsed or 0) >= limit then
			fireLifeUpdate(player, stats, "You already used all <b>" .. tostring(limit) .. "</b> starting recruit slots.")
			return
		end

		local candidateId = string.sub(actionId, 18)
		local candidate = findRecruitCandidate(stats, candidateId)
		if not candidate then
			fireLifeUpdate(player, stats, "That recruit candidate is no longer available.")
			return
		end

		local student = recruitCandidateIntoDojo(stats, candidate)
		removeRecruitCandidate(stats, candidateId)

		stats.DojoStarterRecruitsUsed = (stats.DojoStarterRecruitsUsed or 0) + 1
		if (stats.DojoStarterRecruitsUsed or 0) >= (stats.DojoStarterRecruitLimit or 3) then
			stats.DojoRecruitPool = {}
		end
		stats.ClanStudentsRecruited = (stats.ClanStudentsRecruited or 0) + 1
		stats.ClanMembers = math.max(1, (stats.ClanMembers or 1) + 1)
		stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + math.random(3, 7))
		stats.DojoPrestige = math.max(0, (stats.DojoPrestige or 0) + math.random(2, 5))
		stats.Reputation = (stats.Reputation or 0 + math.random(1, 3))

		fireMajorPopup(
			player,
			"STUDENT RECRUITED",
			student.Name .. " accepted your offer and joined the dojo.",
			student.Grade or "Student",
			"Starting recruit slots used: " .. tostring(stats.DojoStarterRecruitsUsed) .. " / " .. tostring(limit)
		)

		fireLifeUpdate(player, stats, "<b>" .. student.Name .. "</b> joined the <b>" .. tostring(stats.PlayerClanName or "clan") .. "</b> as a dojo student.")
		saveStats(player)
		return

	elseif actionId == "RecruitStudent" then
		if assetId ~= "grand_dojo" then
			fireLifeUpdate(player, stats, "You need a <b>Grand Dojo</b> to recruit clan students.")
			return
		end

		local owned = ownsAsset()

		if not owned then
			fireLifeUpdate(player, stats, "You need to own a <b>Grand Dojo</b> before recruiting students.")
			return
		end

		if not stats.ClanFounded then
			fireLifeUpdate(player, stats, "Found your clan first, then students can start joining your dojo.")
			return
		end

		local currentStudents = countDojoStudentsAndWards(stats)
		local capacity = getDojoStudentCapacity(stats)

		if currentStudents >= capacity then
			fireLifeUpdate(player, stats, "Your Grand Dojo is at capacity. Upgrade the dojo or raise clan reputation before taking in more students.")
			return
		end

		local conditionPenalty = math.floor((100 - (stats.DojoCondition or 100)) / 5)
		local chance = 35 + ((stats.DojoLevel or 1) * 5) + math.clamp(math.floor((stats.DojoPrestige or 0) / 3), 0, 20) + math.clamp(math.floor((stats.ClanReputation or 0) / 3), 0, 25) + math.clamp(math.floor((stats.Reputation or 0) / 10), 0, 10) - conditionPenalty

		if math.random(1, 100) <= chance then
			local student = createClanStudent(stats)
			stats.ClanStudentsRecruited = (stats.ClanStudentsRecruited or 0) + 1
			stats.ClanMembers = math.max(1, (stats.ClanMembers or 1) + 1)
			stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + math.random(2, 6))
			stats.DojoPrestige = math.max(0, (stats.DojoPrestige or 0) + math.random(1, 3))
			adjustDojoCondition(stats, -math.random(1, 3))
			stats.Reputation = (stats.Reputation or 0 + math.random(1, 3))

			fireMajorPopup(
				player,
				"NEW STUDENT",
				"A young sorcerer joined your Grand Dojo.",
				student.Name,
				"They were added to your Relationships page as a Student."
			)

			fireLifeUpdate(player, stats, student.Name .. " joined the <b>" .. tostring(stats.PlayerClanName or "clan") .. "</b> as a student.")
		else
			stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + 1)
			adjustDojoCondition(stats, -1)
			fireLifeUpdate(player, stats, "You opened recruitment at your Grand Dojo, but no serious student committed this year. Your clan still gained a little attention.")
		end

	elseif actionId == "TrainStudents" then
		if assetId ~= "grand_dojo" then
			fireLifeUpdate(player, stats, "You need a <b>Grand Dojo</b> to train students.")
			return
		end

		local owned = ownsAsset()

		if not owned then
			fireLifeUpdate(player, stats, "You need to own a <b>Grand Dojo</b> before training students.")
			return
		end

		if not stats.ClanFounded then
			fireLifeUpdate(player, stats, "Found your clan before running official student training.")
			return
		end

		local trained = 0
		for _, relationship in ipairs(stats.Relationships or {}) do
			if relationship.Alive ~= false and relationship.Role == "Student" then
				trained += 1
				local focus = getDojoFocusLabel(stats)
				local bondGain = math.random(1, 4)
				local trustGain = math.random(1, 3)
				local respectGain = math.random(2, 6)
				local ceGain = math.random(2, 8) + math.floor((stats.DojoLevel or 1) / 2)

				if focus == "Combat" then
					respectGain += math.random(2, 5)
					ceGain += math.random(3, 8)
				elseif focus == "Discipline" then
					respectGain += math.random(2, 4)
					trustGain += math.random(1, 3)
				elseif focus == "Theory" then
					ceGain += math.random(1, 4)
					relationship.TechniqueMastery = math.clamp((relationship.TechniqueMastery or 0) + math.random(1, 4), 0, 100)
				elseif focus == "Loyalty" then
					bondGain += math.random(2, 5)
					trustGain += math.random(1, 3)
				end

				BitKaisenRelationships.AdjustRelationship(relationship, {
					Bond = bondGain,
					Trust = trustGain,
					Respect = respectGain
				})

				relationship.CursedEnergy = math.max(0, (relationship.CursedEnergy or 0) + ceGain)

				if relationship.Grade == "Non-Sorcerer" and relationship.CursedEnergy >= 35 and math.random(1, 100) <= 35 then
					relationship.Grade = "Grade 4"
				end
			end
		end

		if trained <= 0 then
			fireLifeUpdate(player, stats, "You need students before holding a clan training session.")
			return
		end

		stats.ClanTrainingSessions = (stats.ClanTrainingSessions or 0) + 1
		stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + math.random(1, 4) + math.floor(trained / 2))
		stats.DojoPrestige = math.max(0, (stats.DojoPrestige or 0) + math.random(1, 3) + math.floor(trained / 3))
		adjustDojoCondition(stats, -math.random(2, 5))
		stats.Reputation = (stats.Reputation or 0 + math.random(1, 2))
		stats.CursedEnergy = math.max(0, (stats.CursedEnergy or 0) + math.random(1, 4))

		fireLifeUpdate(player, stats, "You ran a <b>" .. getDojoFocusLabel(stats) .. "</b> training session for <b>" .. tostring(trained) .. "</b> dojo student(s). The <b>" .. tostring(stats.PlayerClanName or "clan") .. "</b> gained reputation.")


	elseif actionId == "UpgradeDojo" then
		if assetId ~= "grand_dojo" then
			fireLifeUpdate(player, stats, "You need a <b>Grand Dojo</b> to upgrade the dojo.")
			return
		end

		local owned = ownsAsset()
		if not owned then
			fireLifeUpdate(player, stats, "You need to own a <b>Grand Dojo</b> before upgrading it.")
			return
		end

		if not stats.ClanFounded then
			fireLifeUpdate(player, stats, "Found your clan before expanding the dojo.")
			return
		end

		local cost = getDojoUpgradeCost(stats)
		if not cost then
			fireLifeUpdate(player, stats, "Your Grand Dojo is already at the maximum level.")
			return
		end

		if (stats.Money or 0) < cost then
			fireLifeUpdate(player, stats, "You need <b>$" .. tostring(cost) .. "</b> to upgrade the Grand Dojo.")
			return
		end

		stats.Money -= cost
		stats.DojoLevel = math.clamp((stats.DojoLevel or 1) + 1, 1, 5)
		stats.DojoCondition = math.clamp((stats.DojoCondition or 100) + 18, 0, 100)
		stats.DojoPrestige = math.max(0, (stats.DojoPrestige or 0) + 12)
		stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + 8)

		fireMajorPopup(
			player,
			"DOJO UPGRADED",
			"Your Grand Dojo expanded and attracted more attention.",
			"Level " .. tostring(stats.DojoLevel),
			"Capacity is now " .. tostring(getDojoStudentCapacity(stats)) .. "."
		)

		fireLifeUpdate(player, stats, "You upgraded the <b>Grand Dojo</b> to Level <b>" .. tostring(stats.DojoLevel) .. "</b>.")

	elseif actionId == "MaintainDojo" then
		if assetId ~= "grand_dojo" then
			return
		end

		local owned = ownsAsset()
		if not owned then
			fireLifeUpdate(player, stats, "You need to own a <b>Grand Dojo</b> first.")
			return
		end

		local cost = getDojoMaintainCost(stats)
		if (stats.DojoCondition or 100) >= 100 then
			fireLifeUpdate(player, stats, "The Grand Dojo is already in perfect condition.")
			return
		end

		if (stats.Money or 0) < cost then
			fireLifeUpdate(player, stats, "You need <b>$" .. tostring(cost) .. "</b> to fully maintain the Grand Dojo.")
			return
		end

		stats.Money -= cost
		stats.DojoCondition = 100
		stats.DojoPrestige = math.max(0, (stats.DojoPrestige or 0) + 2)

		fireLifeUpdate(player, stats, "You repaired and cleaned the <b>Grand Dojo</b>. Its condition returned to <b>100%</b>.")

	elseif string.sub(actionId, 1, 9) == "SetFocus_" then
		if assetId ~= "grand_dojo" then
			return
		end

		local owned = ownsAsset()
		if not owned then
			fireLifeUpdate(player, stats, "You need to own a <b>Grand Dojo</b> first.")
			return
		end

		local focus = string.sub(actionId, 10)
		local validFocus = {
			Balanced = true,
			Combat = true,
			Discipline = true,
			Theory = true,
			Loyalty = true,
		}

		if not validFocus[focus] then
			return
		end

		stats.DojoFocus = focus
		fireLifeUpdate(player, stats, "Your Grand Dojo training focus is now <b>" .. focus .. "</b>.")

	elseif actionId == "HostSparringEvent" then
		if assetId ~= "grand_dojo" then
			return
		end

		local owned = ownsAsset()
		if not owned then
			fireLifeUpdate(player, stats, "You need to own a <b>Grand Dojo</b> first.")
			return
		end

		if not stats.ClanFounded then
			fireLifeUpdate(player, stats, "Found your clan before hosting dojo events.")
			return
		end

		if (stats.DojoLevel or 1) < 2 then
			fireLifeUpdate(player, stats, "Upgrade the Grand Dojo to Level 2 before hosting sparring events.")
			return
		end

		local students = countDojoStudentsAndWards(stats)
		if students <= 0 then
			fireLifeUpdate(player, stats, "You need students or wards before hosting a sparring event.")
			return
		end

		local eventCost = 2500 + ((stats.DojoLevel or 1) * 750)
		if (stats.Money or 0) < eventCost then
			fireLifeUpdate(player, stats, "You need <b>$" .. tostring(eventCost) .. "</b> to host a sparring event.")
			return
		end

		stats.Money -= eventCost
		stats.DojoSparringEvents = (stats.DojoSparringEvents or 0) + 1
		local successChance = 45 + ((stats.DojoLevel or 1) * 8) + math.clamp(math.floor((stats.DojoCondition or 100) / 5), 0, 20) + math.clamp(math.floor((stats.DojoPrestige or 0) / 5), 0, 20)
		successChance = math.clamp(successChance, 25, 92)

		if math.random(1, 100) <= successChance then
			stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + math.random(6, 12))
			stats.DojoPrestige = math.max(0, (stats.DojoPrestige or 0) + math.random(5, 10))
			stats.Reputation = (stats.Reputation or 0 + math.random(2, 5))
			adjustDojoCondition(stats, -math.random(4, 8))
			fireLifeUpdate(player, stats, "Your dojo hosted a strong sparring event. The <b>" .. tostring(stats.PlayerClanName or "clan") .. "</b> gained prestige and reputation.")
		else
			stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) - math.random(1, 4))
			adjustDojoCondition(stats, -math.random(8, 14))
			fireLifeUpdate(player, stats, "The sparring event was messy. Nobody was seriously hurt, but the dojo lost condition and some reputation.")
		end

	elseif actionId == "Use" then
		local owned, ownedAsset = ownsAsset()

		if not owned or not ownedAsset then
			fireLifeUpdate(player, stats, "You do not own <b>" .. asset.Name .. "</b>.")
			return
		end

		if not ownedAsset.CanUse then
			fireLifeUpdate(player, stats, "<b>" .. ownedAsset.Name .. "</b> is a passive asset.")
			return
		end

		if ownedAsset.Uses and ownedAsset.Uses <= 0 then
			fireLifeUpdate(player, stats, "<b>" .. ownedAsset.Name .. "</b> has already been used.")
			return
		end

		ownedAsset.Uses = math.max(0, (ownedAsset.Uses or 1) - 1)

		local effects = ownedAsset.UseEffects or {}

		if effects.Health then
			stats.Health = math.clamp((stats.Health or 100) + effects.Health, 0, 100)
		end

		if effects.Happiness then
			stats.Happiness = math.clamp((stats.Happiness or 100) + effects.Happiness, 0, 100)
		end

		if effects.Smarts then
			stats.Smarts = math.clamp((stats.Smarts or 0) + effects.Smarts, 0, 100)
		end

		if effects.CursedEnergy then
			stats.CursedEnergy = math.max(0, (stats.CursedEnergy or 0) + effects.CursedEnergy)
		end

		if effects.Money then
			stats.Money = math.max(0, (stats.Money or 0) + effects.Money)
		end

		if effects.Reputation then
			stats.Reputation = (stats.Reputation or 0) + effects.Reputation
		end

		fireLifeUpdate(player, stats, ownedAsset.UseText or ("You used <b>" .. ownedAsset.Name .. "</b>."))
	end

	saveStats(player)
end

getMissionBoard.OnServerInvoke = function(player)
	local stats = playerLives[player.UserId]

	if not stats or not stats.Alive then
		return {}
	end

	ensureExtraStats(stats)

	if isCurseUser(stats) then
		return generateCurseUserMissionBoard(stats)
	end

	if (stats.Age or 0) < 16 then
		return {}
	end

	if not isOfficialJujutsuSorcerer(stats) then
		return {}
	end

	return BitKaisenMissions.GenerateMissionBoard(getOfficialGradeName(stats.Grade))
end

getActivityList.OnServerInvoke = function(player)
	local stats = playerLives[player.UserId]

	if not stats or not stats.Alive then
		return {}
	end

	ensureExtraStats(stats)

	local list = BitKaisenActivities.GenerateActivityList(stats)

	if not isDev(player) then
		local filtered = {}

		for _, activity in ipairs(list) do
			if not string.match(activity.Id, "^dev_") then
				table.insert(filtered, activity)
			end
		end

		return filtered
	end

	return list
end

getRelationships.OnServerInvoke = function(player)
	local stats = playerLives[player.UserId]

	if not stats or not stats.Alive then
		return {}
	end

	ensureExtraStats(stats)

	return BitKaisenRelationships.GetDisplayList(stats)
end

function getOwnedAssetsPayload(stats)
	ensureExtraStats(stats)

	local owned = BitKaisenAssets.GetOwnedList(stats)
	local seen = {}

	for _, asset in ipairs(owned or {}) do
		if typeof(asset) == "table" and asset.Id then
			seen[tostring(asset.Id)] = true
		end
	end

	for _, asset in ipairs(stats.Assets or {}) do
		if typeof(asset) == "table" and asset.EventItem == true then
			local assetId = tostring(asset.Id or asset.BaseId or asset.Name or "event_item")

			if seen[assetId] ~= true then
				seen[assetId] = true

				table.insert(owned, {
					Id = assetId,
					BaseId = asset.BaseId,
					Name = tostring(asset.Name or "Unknown Cursed Object"),
					Type = tostring(asset.Type or "Mysterious Item"),
					Category = tostring(asset.Category or "Event Item"),
					Rarity = tostring(asset.Rarity or "Uncommon"),
					Description = tostring(asset.Description or "A strange item obtained during a life event."),
					EffectsText = tostring(asset.EffectsText or "Event Item • Acquired at age " .. tostring(asset.AcquiredAge or "?")),
					CanUse = asset.CanUse == true,
					Uses = asset.Uses,
					Quantity = tonumber(asset.Quantity) or 1,
					EventItem = true,
					AcquiredFrom = asset.AcquiredFrom,
					AcquiredAge = asset.AcquiredAge,
					AcquiredMonth = asset.AcquiredMonth,
				})
			end
		end
	end

	return owned
end

getAssets.OnServerInvoke = function(player)
	local stats = playerLives[player.UserId]

	if not stats or not stats.Alive then
		return {
			Age = 0,
			Money = 0,
			ClanFounded = false,
			PlayerClanName = nil,
			ClanMembers = 0,
			ClanReputation = 0,
			ClanStudentCount = 0,
			ClanStudentsRecruited = 0,
			ClanTrainingSessions = 0,
			HasGrandDojo = false,
			DojoLevel = 1,
			DojoCondition = 100,
			DojoPrestige = 0,
			DojoFocus = "Balanced",
			DojoCapacity = 3,
			DojoMaintainCost = 0,
			DojoUpgradeCost = nil,
			WardsRescued = 0,
			FamilyName = "Unknown",
			FirstName = "Unknown",
			DojoFounderName = "Unknown",
			DojoClanBaseName = nil,
			DojoPendingLastNameChoice = false,
			DojoStarterRecruitLimit = 3,
			DojoStarterRecruitsUsed = 0,
			DojoRecruitPool = {},
			DojoStudents = {},
			HasVIP = false,
			VIPGamePassId = VIP_SORCERER_PASS_ID,
			Owned = {},
			Shop = {}
		}
	end

	ensureExtraStats(stats)

	local hasGrandDojo = ownsAssetById(stats, "grand_dojo")

	return {
		Age = stats.Age or 0,
		CurrentMonth = stats.CurrentMonth or 1,
		MonthsIntoAge = stats.MonthsIntoAge or 0,
		CurrentYear = getCurrentYear(stats),
		Money = stats.Money or 0,
		ClanFounded = stats.ClanFounded == true,
		PlayerClanName = stats.PlayerClanName,
		ClanMembers = stats.ClanMembers or 0,
		ClanReputation = stats.ClanReputation or 0,
		ClanStudentCount = countDojoStudentsAndWards(stats),
		ClanStudentsRecruited = stats.ClanStudentsRecruited or 0,
		ClanTrainingSessions = stats.ClanTrainingSessions or 0,
		HasGrandDojo = hasGrandDojo == true,
		DojoLevel = stats.DojoLevel or 1,
		DojoCondition = stats.DojoCondition or 100,
		DojoPrestige = stats.DojoPrestige or 0,
		DojoFocus = stats.DojoFocus or "Balanced",
		DojoCapacity = getDojoStudentCapacity(stats),
		DojoMaintainCost = getDojoMaintainCost(stats),
		DojoUpgradeCost = getDojoUpgradeCost(stats),
		DojoSparringEvents = stats.DojoSparringEvents or 0,
		WardsRescued = stats.WardsRescued or 0,
		FamilyName = stats.FamilyName or "Unknown",
		FirstName = stats.FirstName or "Unknown",
		DojoFounderName = stats.DojoFounderName or stats.Name or "Unknown",
		DojoClanBaseName = stats.DojoClanBaseName,
		DojoPendingLastNameChoice = stats.DojoPendingLastNameChoice == true,
		DojoStarterRecruitLimit = stats.DojoStarterRecruitLimit or 3,
		DojoStarterRecruitsUsed = stats.DojoStarterRecruitsUsed or 0,
		DojoRecruitPool = stats.DojoRecruitPool or {},
		DojoStudents = getDojoStudentsForPayload(stats),
		HasVIP = ownsVIPSorcererPass(player),
		HasExtraSaveSlots = ownsExtraSaveSlotsPass(player),
		HasSaveSlotsAccess = ownsSaveSlotAccess(player),
		VIPGamePassId = VIP_SORCERER_PASS_ID,
		ExtraSaveSlotsGamePassId = EXTRA_SAVE_SLOTS_PASS_ID,
		DoubleMoneyGamePassId = DOUBLE_MONEY_PASS_ID,
		DoubleTrainingGamePassId = DOUBLE_TRAINING_PASS_ID,
		Owned = getOwnedAssetsPayload(stats),
		Shop = BitKaisenAssets.GetShopList(stats)
	}
end

getSuccessorOptions.OnServerInvoke = function(player)
	local stats = playerLives[player.UserId]

	if not stats then
		return {}
	end

	if stats.Alive ~= false then
		return {}
	end

	return BitKaisenLegacy.GetEligibleSuccessors(stats)
end

updateLifeEvent.OnServerEvent:Connect(function(player, action, data)
	if action == "StartNewLife" then
		if not checkRateLimit(player, "StartNewLife") then
			return
		end

		startNewLife(player)
		return
	end

	if action == "BecomeVengefulSpirit" then
		if not checkRateLimit(player, "StartNewLife") then
			return
		end

		local ok, errorMessage = startAsCurseRebirth(player)
		if not ok then
			local stats = playerLives[player.UserId]
			if stats then
				fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ SYSTEM ]</b></font> " .. tostring(errorMessage or "Could not reincarnate as a curse."))
			end
		end
		return
	end

	if action == "AgeUp" then
		if not checkRateLimit(player, "AgeUp") then
			return
		end

		-- HOTFIX: Clear stuck pending choices before aging, no matter where they came from.
		pendingMissions[player.UserId] = nil

		ageUp(player)
	elseif action == "DoMission" then
		if not checkRateLimit(player, "DoMission") then
			return
		end

		processMission(player, data)
	elseif action == "DoActivity" then
		if not checkRateLimit(player, "DoActivity") then
			return
		end

		processActivity(player, data)
	end
end)


missionChoice.OnServerEvent:Connect(function(player, optionIndex)
	if not checkRateLimit(player, "MissionChoice") then
		return
	end

	local userId = player.UserId
	local pending = pendingMissions[userId]
	local stats = playerLives[userId]

	if not pending then
		if stats then
			fireLifeUpdate(player, stats, "<font color='#999999'><b>[ SYSTEM ]</b></font> No pending mission choice was found.")
		end
		return
	end

	if not stats or not stats.Alive then
		pendingMissions[userId] = nil
		return
	end

	local parsedIndex = tonumber(optionIndex)

	if not parsedIndex then
		pendingMissions[userId] = nil
		fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ SYSTEM ]</b></font> Mission choice failed because the client sent an invalid option. The pending mission was cleared so aging will not freeze.")
		return
	end

	parsedIndex = math.floor(parsedIndex)

	local availableOptions = pending.availableOptions or pending.Options or {}
	local option = availableOptions[parsedIndex]

	pendingMissions[userId] = nil

	if not option then
		fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ SYSTEM ]</b></font> Mission choice expired or had an invalid option. The pending mission was cleared so aging will not freeze.")
		return
	end

	ensureExtraStats(stats)

	if pending.Type == "CurseUser" then
		local mission = pending.Mission

		applyChoiceEffects(stats, option)
		applyMorality(stats, option.Morality or 0)

		stats.MissionsCompleted = (stats.MissionsCompleted or 0) + 1

		local progressGain = tonumber((option.Effects or {}).CurseUserProgress) or tonumber(mission and mission.RewardCE) or 8
		local effects = option.Effects or {}
		local rewardParts = {}

		if effects.Money and effects.Money ~= 0 then
			table.insert(rewardParts, "$" .. tostring(effects.Money))
		end

		if effects.CursedEnergy and effects.CursedEnergy ~= 0 then
			table.insert(rewardParts, "CE " .. ((effects.CursedEnergy > 0 and "+") or "") .. tostring(effects.CursedEnergy))
		end

		if effects.TechniqueMastery and effects.TechniqueMastery ~= 0 then
			table.insert(rewardParts, "Mastery " .. ((effects.TechniqueMastery > 0 and "+") or "") .. tostring(effects.TechniqueMastery))
		end

		if effects.Smarts and effects.Smarts ~= 0 then
			table.insert(rewardParts, "Smarts " .. ((effects.Smarts > 0 and "+") or "") .. tostring(effects.Smarts))
		end

		if effects.Reputation and effects.Reputation ~= 0 then
			table.insert(rewardParts, "Rep " .. ((effects.Reputation > 0 and "+") or "") .. tostring(effects.Reputation))
		end

		if effects.Happiness and effects.Happiness ~= 0 then
			table.insert(rewardParts, "Happiness " .. ((effects.Happiness > 0 and "+") or "") .. tostring(effects.Happiness))
		end

		if effects.Health and effects.Health ~= 0 then
			table.insert(rewardParts, "Health " .. ((effects.Health > 0 and "+") or "") .. tostring(effects.Health))
		end

		if progressGain and progressGain > 0 then
			table.insert(rewardParts, "Underground Progress +" .. tostring(progressGain))
		end

		local rewardSummary = "Rewards: " .. table.concat(rewardParts, " • ")
		if #rewardParts <= 0 then
			rewardSummary = "Rewards: None"
		end

		local logMessage = "<font color='#e53935'><b>[ CURSE USER MISSION ]</b></font> " .. tostring(option.Description or "You completed the job.")
		logMessage = appendLine(logMessage, rewardSummary)
		logMessage = grantCurseUserProgress(player, stats, progressGain, logMessage)
		logMessage = appendLine(logMessage, "Alignment: <b>" .. tostring(stats.Alignment or getMoralAlignment(stats)) .. "</b> | Reputation: <b>" .. tostring(stats.Reputation or 0) .. "</b>.")

		fireLifeUpdate(player, stats, logMessage)
		saveStats(player, "curse user mission")
		return
	end

	if pending.Type == "CurseSorcererAttack" then
		resolveCurseSorcererAttackChoice(player, stats, pending, option)
		return
	end

	if pending.Type == "RandomLifeScenario" then
		resolveRandomLifeScenarioChoice(player, stats, pending.Scenario or pending, option)
		return
	end

	if pending.Type == "LifeEncounter" then
		resolveMonthlyLifeEncounter(player, stats, pending.Encounter, option)
		return
	end

	if pending.Type == "HigherUpsInvite" then
		resolveHigherUpsInvitationChoice(player, stats, option)
		return
	end

	if pending.Type == "HigherUpsMissionOffer" then
		resolveHigherUpsMissionOffer(player, stats, option)
		return
	end

	if pending.Type == "VesselEscortDialogue" then
		resolveVesselEscortDialogue(player, stats, option)
		return
	end

	local missionData = nil

	if pending.missionId then
		missionData = BitKaisenMissions.GetMissionById(pending.missionId)
	end

	if not missionData and pending.Mission then
		missionData = pending.Mission
	end

	if not missionData then
		fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ SYSTEM ]</b></font> Mission data was missing, so the pending mission was cleared.")
		return
	end

	if pending.Type == "OrphanRescue" then
		resolveOrphanRescueChoice(player, stats, missionData, option)
		return
	end

	resolveMission(player, stats, missionData, option)
end)

relationshipAction.OnServerEvent:Connect(function(player, relationshipId, actionId)
	if not checkRateLimit(player, "RelationshipAction") then
		return
	end

	processRelationshipAction(player, relationshipId, actionId)

	-- Tell relationship UI to refresh after the server finishes the action.
	relationshipAction:FireClient(player)
end)

assetAction.OnServerEvent:Connect(function(player, actionId, assetId)
	if not checkRateLimit(player, "AssetAction") then
		return
	end

	processAssetAction(player, actionId, assetId)

	-- Tell asset UI listeners to refresh after the server finishes the action.
	assetAction:FireClient(player)
end)

chooseSuccessor.OnServerEvent:Connect(function(player, successorId)
	if not checkRateLimit(player, "StartAsSuccessor") then
		return
	end

	if typeof(successorId) ~= "string" then
		return
	end

	local ok, errorMessage = startAsSuccessor(player, successorId)

	if not ok then
		local stats = playerLives[player.UserId]
		if stats then
			fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ SYSTEM ]</b></font> " .. tostring(errorMessage or "Could not start as successor."))
		end
	end
end)



local DEVELOPER_PRODUCTS = {
	[STARTER_SORCERER_PACK_PRODUCT_ID] = {
		Id = "starter_pack",
		Name = "Starter Sorcerer Pack"
	},
	[FOCUSED_TRAINING_PRODUCT_ID] = {
		Id = "focused_training",
		Name = "Focused Training Session"
	},
	[MONEY_5000_PRODUCT_ID] = {
		Id = "money_pack",
		Name = "$5,000 Money",
		Amount = 5000
	},
	[MONEY_25000_PRODUCT_ID] = {
		Id = "money_pack",
		Name = "$25,000 Money",
		Amount = 25000
	},
	[MONEY_100000_PRODUCT_ID] = {
		Id = "money_pack",
		Name = "$100,000 Money",
		Amount = 100000
	},
	[RECRUIT_REROLL_PRODUCT_ID] = {
		Id = "recruit_reroll",
		Name = "Recruit Reroll"
	}
}

DEVELOPER_PRODUCTS[0] = nil

function getTrainingRewardByGrade(stats)
	local grade = tostring(stats.Grade or "Non-Sorcerer")

	local rewardsByGrade = {
		["Non-Sorcerer"] = { CE = 18, Mastery = 0, Reputation = 0 },
		["Grade 4"] = { CE = 24, Mastery = 2, Reputation = 1 },
		["Semi-Grade 3"] = { CE = 30, Mastery = 3, Reputation = 1 },
		["Grade 3"] = { CE = 36, Mastery = 4, Reputation = 2 },
		["Semi-Grade 2"] = { CE = 45, Mastery = 5, Reputation = 2 },
		["Grade 2"] = { CE = 55, Mastery = 6, Reputation = 3 },
		["Semi-Grade 1"] = { CE = 68, Mastery = 7, Reputation = 4 },
		["Grade 1"] = { CE = 82, Mastery = 8, Reputation = 5 },
		["Special Grade"] = { CE = 110, Mastery = 10, Reputation = 7 }
	}

	return rewardsByGrade[grade] or { CE = 30, Mastery = 3, Reputation = 1 }
end

function grantStarterSorcererPack(player, stats)
	ensureExtraStats(stats)

	stats.Purchases = stats.Purchases or {}
	if stats.Purchases.StarterSorcererPackClaimed == true then
		fireMajorPopup(
			player,
			"STARTER PACK ALREADY CLAIMED",
			"This current life has already claimed the Starter Sorcerer Pack.",
			"One Claim Per Life",
			"Create or load another save slot if you want a fresh starter pack claim."
		)

		fireLifeUpdate(player, stats, "<font color='#ffcd69'><b>[ PURCHASE ]</b></font> Starter Sorcerer Pack was already claimed for this life, so no duplicate reward was added.")
		return true
	end

	stats.Purchases.StarterSorcererPackClaimed = true

	local ceGain = 35
	local moneyGain = 5000
	local smartsGain = 5
	local masteryGain = 0

	stats.Money = (stats.Money or 0) + moneyGain
	stats.CursedEnergy = (stats.CursedEnergy or 0) + ceGain
	stats.Smarts = math.clamp((stats.Smarts or 0) + smartsGain, 0, 100)

	if stats.CursedTechnique and stats.CursedTechnique ~= "None" then
		masteryGain = 3
		stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + masteryGain, 0, 100)
	end

	local message = "<font color='#ffcd69'><b>[ PURCHASE ]</b></font> Starter Sorcerer Pack redeemed."
	message = message .. "\n+$" .. tostring(moneyGain) .. " Money"
	message = message .. "\n+" .. tostring(ceGain) .. " Cursed Energy"
	message = message .. "\n+" .. tostring(smartsGain) .. " Smarts"

	if masteryGain > 0 then
		message = message .. "\n+" .. tostring(masteryGain) .. " Technique Mastery"
	end

	fireMajorPopup(
		player,
		"STARTER PACK REDEEMED",
		"Your starter resources were added to this life.",
		"+$" .. tostring(moneyGain) .. " | +" .. tostring(ceGain) .. " CE",
		"Open your profile to see the updated stats."
	)

	fireLifeUpdate(player, stats, message)
	return true
end

function grantFocusedTraining(player, stats)
	ensureExtraStats(stats)

	local reward = getTrainingRewardByGrade(stats)
	local ceGain = reward.CE or 30
	local masteryGain = reward.Mastery or 0
	local reputationGain = reward.Reputation or 0
	local recommendationGain = 0

	if ownsDoubleTrainingPass(player) then
		ceGain *= 2
		masteryGain *= 2
		reputationGain *= 2
	end

	stats.CursedEnergy = (stats.CursedEnergy or 0) + ceGain
	stats.Reputation = (stats.Reputation or 0) + reputationGain

	if stats.CursedTechnique and stats.CursedTechnique ~= "None" then
		stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + masteryGain, 0, 100)
	else
		masteryGain = 0
	end

	if stats.InJujutsuHigh and math.random(1, 100) <= 12 then
		recommendationGain = 1
		stats.TeacherRecommendations = (stats.TeacherRecommendations or 0) + 1
	end

	local message = "<font color='#78beff'><b>[ PURCHASE ]</b></font> Focused Training Session completed."
	message = message .. "\n+" .. tostring(ceGain) .. " Cursed Energy"

	if masteryGain > 0 then
		message = message .. "\n+" .. tostring(masteryGain) .. " Technique Mastery"
	end

	if reputationGain > 0 then
		message = message .. "\n+" .. tostring(reputationGain) .. " Reputation"
	end

	if recommendationGain > 0 then
		message = message .. "\nA teacher noticed your discipline and submitted a recommendation."
	end

	fireMajorPopup(
		player,
		"FOCUSED TRAINING",
		"Your training session sharpened your cursed energy control.",
		"+" .. tostring(ceGain) .. " CE",
		masteryGain > 0 and ("+" .. tostring(masteryGain) .. " Technique Mastery") or "Keep aging to awaken your cursed technique."
	)

	fireLifeUpdate(player, stats, message)
end

function grantMoneyPack(player, stats, amount)
	ensureExtraStats(stats)

	local moneyGain = math.max(0, tonumber(amount) or 25000)
	if ownsDoubleMoneyPass(player) then
		moneyGain *= 2
	end

	stats.Money = (stats.Money or 0) + moneyGain

	fireMajorPopup(
		player,
		"MONEY PACK REDEEMED",
		"Funds were added to your current life.",
		"+$" .. tostring(moneyGain),
		"Use it for assets, dojo progress, and clan growth."
	)

	fireLifeUpdate(player, stats, "<font color='#78f0a0'><b>[ PURCHASE ]</b></font> +$" .. tostring(moneyGain) .. " Money added.")
end

function grantRecruitReroll(player, stats)
	ensureExtraStats(stats)

	if stats.ClanFounded == true then
		generateDojoRecruitPool(stats)

		fireMajorPopup(
			player,
			"RECRUIT BOARD REROLLED",
			"A new set of 10 student candidates arrived at your Grand Dojo.",
			"10 Candidates",
			"Open Assets > Dojo > Recruit to review them."
		)

		fireLifeUpdate(player, stats, "<font color='#78beff'><b>[ PURCHASE ]</b></font> Recruit board rerolled. A fresh list of <b>10 student candidates</b> is ready.")
	else
		stats.RecruitRerollTokens = (stats.RecruitRerollTokens or 0) + 1

		fireMajorPopup(
			player,
			"RECRUIT REROLL SAVED",
			"You do not have a founded clan yet, so this reroll was saved as a token.",
			"+1 Reroll Token",
			"Found a clan later to use recruit rerolls."
		)

		fireLifeUpdate(player, stats, "<font color='#78beff'><b>[ PURCHASE ]</b></font> +1 Recruit Reroll Token saved for a future clan.")
	end
end

function grantDeveloperProduct(player, productId)
	local stats = playerLives[player.UserId]

	if not stats then
		return false
	end

	local productInfo = DEVELOPER_PRODUCTS[productId]

	if not productInfo then
		warn("[GameManager] Unknown developer product id: " .. tostring(productId))
		return false
	end

	if productInfo.Id == "starter_pack" then
		grantStarterSorcererPack(player, stats)
	elseif productInfo.Id == "focused_training" then
		grantFocusedTraining(player, stats)
	elseif productInfo.Id == "money_pack" then
		grantMoneyPack(player, stats, productInfo.Amount)
	elseif productInfo.Id == "recruit_reroll" then
		grantRecruitReroll(player, stats)
	else
		warn("[GameManager] Unhandled developer product id key: " .. tostring(productInfo.Id))
		return false
	end

	forceSaveStats(player, "DeveloperProduct")
	return true
end

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productId = tonumber(receiptInfo.ProductId)

	if not productId or not DEVELOPER_PRODUCTS[productId] then
		warn("[GameManager] Receipt received for unknown product id: " .. tostring(receiptInfo.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, result = pcall(function()
		return grantDeveloperProduct(player, productId)
	end)

	if ok and result == true then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	warn("[GameManager] Could not grant product " .. tostring(productId) .. ": " .. tostring(result))
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, purchasedPassId, wasPurchased)
	if purchasedPassId ~= VIP_SORCERER_PASS_ID
		and purchasedPassId ~= EXTRA_SAVE_SLOTS_PASS_ID
		and purchasedPassId ~= DOUBLE_MONEY_PASS_ID
		and purchasedPassId ~= DOUBLE_TRAINING_PASS_ID then
		return
	end

	clearVIPCache(player)

	local stats = playerLives[player.UserId]
	if not stats then
		return
	end

	if wasPurchased then
		if purchasedPassId == VIP_SORCERER_PASS_ID then
			fireMajorPopup(player, "VIP UNLOCKED", "Your VIP Sorcerer Pass is active.", "VIP Sorcerer", "VIP perks are now available on this account.")
			fireLifeUpdate(player, stats, "<font color='#ffcd69'><b>[ VIP ]</b></font> VIP Sorcerer Pass active.")
		elseif purchasedPassId == EXTRA_SAVE_SLOTS_PASS_ID then
			fireMajorPopup(player, "SAVE SLOTS UNLOCKED", "Extra save slots are now unlocked.", "Slots 1-3", "Open Menu > Save Slots to create or load another life.")
			fireLifeUpdate(player, stats, "<font color='#ffcd69'><b>[ SAVE SLOTS ]</b></font> Extra save slots unlocked.")
		elseif purchasedPassId == DOUBLE_MONEY_PASS_ID then
			fireMajorPopup(player, "2X MONEY ACTIVE", "Money product rewards are now doubled.", "2x Money", "Future money purchases will pay out double.")
			fireLifeUpdate(player, stats, "<font color='#78f0a0'><b>[ GAMEPASS ]</b></font> 2x Money active.")
		elseif purchasedPassId == DOUBLE_TRAINING_PASS_ID then
			fireMajorPopup(player, "2X TRAINING ACTIVE", "Focused Training rewards are now doubled.", "2x Training", "Future focused training purchases will give stronger rewards.")
			fireLifeUpdate(player, stats, "<font color='#78beff'><b>[ GAMEPASS ]</b></font> 2x Training active.")
		end
	end
end)


local CODE_ORDER = {
	"ALPHA35",
	"MOBILEFIX",
	"SORRYMOBILE",
	"TRAITS",
	"FAMILYUPDATE",
}

local CODE_DEFINITIONS = {
	ALPHA35 = {
		Name = "ALPHA35",
		Description = "Alpha 3.5 update reward.",
		RewardText = "+$5,000 | +10 CE | +3 Rep",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 5000
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 10
			stats.Reputation = (stats.Reputation or 0) + 3
			return "+$5,000 Money, +10 Cursed Energy, and +3 Reputation"
		end
	},

	MOBILEFIX = {
		Name = "MOBILEFIX",
		Description = "Reward for the mobile bug fix update.",
		RewardText = "+$3,500 | +5 Smarts",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 3500
			stats.Smarts = math.clamp((stats.Smarts or 0) + 5, 0, 100)
			return "+$3,500 Money and +5 Smarts"
		end
	},

	SORRYMOBILE = {
		Name = "SORRYMOBILE",
		Description = "Compensation for mobile issues.",
		RewardText = "+$7,500 | +8 Happiness",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 7500
			stats.Happiness = math.clamp((stats.Happiness or 100) + 8, 0, 100)
			return "+$7,500 Money and +8 Happiness"
		end
	},

	TRAITS = {
		Name = "TRAITS",
		Description = "Traits update reward.",
		RewardText = "+12 CE | +4 Mastery",
		Grant = function(stats)
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 12
			stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + 4, 0, 100)
			return "+12 Cursed Energy and +4 Technique Mastery"
		end
	},

	FAMILYUPDATE = {
		Name = "FAMILYUPDATE",
		Description = "Family update reward.",
		RewardText = "+$4,000 | +6 Happiness | +2 Rep",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 4000
			stats.Happiness = math.clamp((stats.Happiness or 100) + 6, 0, 100)
			stats.Reputation = (stats.Reputation or 0) + 2
			return "+$4,000 Money, +6 Happiness, and +2 Reputation"
		end
	},
}

function getActiveCodeCards(stats)
	local cards = {}
	stats = stats or {}
	stats.Codes = stats.Codes or {}
	stats.Codes.Redeemed = stats.Codes.Redeemed or {}

	for index, code in ipairs(CODE_ORDER) do
		local definition = CODE_DEFINITIONS[code]
		if definition then
			table.insert(cards, {
				Index = index,
				Code = code,
				Name = definition.Name or code,
				Description = definition.Description or "",
				RewardText = definition.RewardText or "",
				Redeemed = stats.Codes.Redeemed[code] == true,
			})
		end
	end

	return cards
end

function normalizeRedeemCode(rawCode)
	local code = tostring(rawCode or "")
	code = code:gsub("%s+", "")
	code = code:gsub("[^%w_]", "")
	code = string.upper(code)
	return code
end

function getRedeemedCodeCount(stats)
	ensureExtraStats(stats)

	local count = 0
	for _, redeemed in pairs(stats.Codes.Redeemed) do
		if redeemed == true then
			count += 1
		end
	end

	return count
end


function getCodeGatePayload(player, clientConfirmedLike)
	local groupConfigured = BITKAISEN_GROUP_ID and BITKAISEN_GROUP_ID > 0
	local groupOk = true
	local groupMessage = "Group requirement is disabled."

	if REQUIRE_GROUP_FOR_CODES then
		if not groupConfigured then
			groupOk = false
			groupMessage = "Group ID is not set yet. Add your Roblox group ID in GameManager."
		else
			local ok, result = pcall(function()
				return player:IsInGroup(BITKAISEN_GROUP_ID)
			end)

			groupOk = ok and result == true
			groupMessage = groupOk and "Group joined." or "Join the Roblox group to unlock codes."
		end
	end

	local likeOk = true
	local likeMessage = "Like confirmation is disabled."

	if REQUIRE_LIKE_CONFIRMATION_FOR_CODES then
		likeOk = clientConfirmedLike == true
		likeMessage = likeOk and "Like confirmed." or "Like the game, then press I LIKED to unlock the code box."
	end

	return {
		CanUseCodes = groupOk and likeOk,
		ActiveCodes = getActiveCodeCards(playerLives[player.UserId]),
		GroupRequired = REQUIRE_GROUP_FOR_CODES == true,
		LikeConfirmationRequired = REQUIRE_LIKE_CONFIRMATION_FOR_CODES == true,
		GroupConfigured = groupConfigured == true,
		GroupId = groupConfigured and BITKAISEN_GROUP_ID or 0,
		InGroup = groupOk == true,
		LikeConfirmed = likeOk == true,
		GroupMessage = groupMessage,
		LikeMessage = likeMessage,
	}
end

function redeemCodeForPlayer(player, rawCode, clientConfirmedLike)
	if not checkRateLimit(player, "RedeemCode") then
		return {
			Success = false,
			Message = "Slow down before redeeming another code.",
			RewardText = ""
		}
	end

	local stats = playerLives[player.UserId]
	if not stats then
		return {
			Success = false,
			Message = "No life is loaded yet.",
			RewardText = ""
		}
	end

	ensureExtraStats(stats)

	local gate = getCodeGatePayload(player, clientConfirmedLike)
	if gate.CanUseCodes ~= true then
		local reason = gate.GroupMessage or gate.LikeMessage or "Codes are locked."
		if gate.InGroup == true and gate.LikeConfirmed ~= true then
			reason = gate.LikeMessage or reason
		end

		return {
			Success = false,
			Message = reason,
			RewardText = "",
			Gate = gate,
		}
	end

	local code = normalizeRedeemCode(rawCode)
	if code == "" then
		return {
			Success = false,
			Message = "Type a code first.",
			RewardText = ""
		}
	end

	local definition = CODE_DEFINITIONS[code]
	if not definition then
		return {
			Success = false,
			Message = "Invalid code.",
			RewardText = ""
		}
	end

	if stats.Codes.Redeemed[code] == true then
		return {
			Success = false,
			Message = "You already redeemed " .. code .. " on this life.",
			RewardText = definition.RewardText or ""
		}
	end

	stats.Codes.Redeemed[code] = true

	local rewardSummary = "Reward claimed."
	local ok, grantResult = pcall(function()
		return definition.Grant(stats)
	end)

	if ok and grantResult then
		rewardSummary = grantResult
	elseif not ok then
		warn("[GameManager] Code reward failed for " .. tostring(code) .. ": " .. tostring(grantResult))
		rewardSummary = "Reward failed to apply."
	end

	fireMajorPopup(
		player,
		"CODE REDEEMED",
		definition.Description or "Reward claimed.",
		code,
		rewardSummary
	)

	fireLifeUpdate(player, stats, "<font color='#f0b955'><b>[ CODE ]</b></font> " .. code .. " redeemed.\n" .. rewardSummary)
	saveStats(player)

	return {
		Success = true,
		Code = code,
		Message = code .. " redeemed.",
		RewardText = rewardSummary,
		RedeemedCount = getRedeemedCodeCount(stats)
	}
end

redeemCode.OnServerInvoke = function(player, rawCode, clientConfirmedLike)
	return redeemCodeForPlayer(player, rawCode, clientConfirmedLike == true)
end

getCodeGate.OnServerInvoke = function(player, clientConfirmedLike)
	return getCodeGatePayload(player, clientConfirmedLike == true)
end

getAchievements.OnServerInvoke = function(player)
	return getAchievementPayload(player)
end

claimAchievement.OnServerEvent:Connect(function(player, achievementId)
	if not checkRateLimit(player, "ClaimAchievement") then
		return
	end

	local ok, errorMessage = claimAchievementReward(player, achievementId)

	if not ok then
		local stats = playerLives[player.UserId]
		if stats then
			fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ ACHIEVEMENT ]</b></font> " .. tostring(errorMessage or "Could not claim achievement."))
		end
	end
end)

getSaveSlots.OnServerInvoke = function(player)
	return getSaveSlotPayload(player)
end

selectSaveSlot.OnServerEvent:Connect(function(player, slotId)
	switchToSaveSlot(player, slotId)
end)

createSaveSlot.OnServerEvent:Connect(function(player, slotId)
	createSaveSlotLife(player, slotId)
end)

deleteSaveSlot.OnServerEvent:Connect(function(player, slotId)
	deleteSaveSlotLife(player, slotId)
end)

local ALLOWED_SETTINGS = {
	MusicVolume = "number",
	SFXVolume = "number",

	MuteMusic = "boolean",
	MuteSFX = "boolean",

	FastText = "boolean",
	HighContrastText = "boolean",
	ReducedMotion = "boolean",
	ScreenShake = "boolean"
}

updateSettingsEvent.OnServerEvent:Connect(function(player, settingName, value)
	if not checkRateLimit(player, "UpdateSettings") then
		return
	end

	if typeof(settingName) ~= "string" then
		return
	end

	local expectedType = ALLOWED_SETTINGS[settingName]
	if not expectedType then
		return
	end

	local stats = playerLives[player.UserId]
	if not stats then
		return
	end

	ensureExtraStats(stats)

	if expectedType == "number" then
		value = math.clamp(tonumber(value) or 0, 0, 1)
	elseif expectedType == "boolean" then
		value = value == true
	else
		return
	end

	stats.Settings[settingName] = value
	saveStats(player, "SettingsChanged")
	fireLifeUpdate(player, stats, nil)
end)

----------------------------------------------------------------
-- DEV COMMANDS
-- Chat commands for testing only.
-- Add your Roblox UserId to DEV_USER_IDS near the top of this script.
-- Usage examples:
--   !bk age 18
--   !bk race curse
--   !bk attack
----------------------------------------------------------------

local DEV_COMMAND_PREFIX = "!bk"

local TECHNIQUE_ALIASES = {
	["none"] = "None",
	["limitless"] = "Limitless",
	["ten"] = "Ten Shadows",
	["tenshadows"] = "Ten Shadows",
	["ten shadows"] = "Ten Shadows",
	["blood"] = "Blood Manipulation",
	["blood manipulation"] = "Blood Manipulation",
	["speech"] = "Cursed Speech",
	["cursed speech"] = "Cursed Speech",
	["boogie"] = "Boogie Woogie",
	["boogie woogie"] = "Boogie Woogie",
	["straw"] = "Straw Doll",
	["straw doll"] = "Straw Doll",
	["ratio"] = "Ratio Technique",
	["ratio technique"] = "Ratio Technique",
	["projection"] = "Projection Sorcery",
	["projection sorcery"] = "Projection Sorcery",
	["idle"] = "Idle Transfiguration",
	["idle transfiguration"] = "Idle Transfiguration",
	["shrine"] = "Shrine",
	["heavenly"] = "Heavenly Restriction",
	["heavenly restriction"] = "Heavenly Restriction",
	["disaster flames"] = "Disaster Flames",
	["flames"] = "Disaster Flames",
	["thread"] = "Thread Manipulation",
	["thread manipulation"] = "Thread Manipulation",
	["mirror"] = "Mirror Step",
	["mirror step"] = "Mirror Step",
	["grave"] = "Grave Bloom",
	["grave bloom"] = "Grave Bloom",
	["static"] = "Static Binding",
	["static binding"] = "Static Binding",
	["glass"] = "Glass Veil",
	["glass veil"] = "Glass Veil",
	["paper"] = "Paper Shikigami",
	["paper shikigami"] = "Paper Shikigami",
	["bone"] = "Bone Forge",
	["bone forge"] = "Bone Forge",
	["shadow stitch"] = "Shadow Stitch",
	["echo"] = "Echo Pulse",
	["echo pulse"] = "Echo Pulse",
	["crow"] = "Crow Funeral",
	["crow funeral"] = "Crow Funeral",
}

local GRADE_ALIASES = {
	["non"] = "Non-Sorcerer",
	["none"] = "Non-Sorcerer",
	["nonsorcerer"] = "Non-Sorcerer",
	["non-sorcerer"] = "Non-Sorcerer",
	["4"] = "Grade 4",
	["grade4"] = "Grade 4",
	["grade 4"] = "Grade 4",
	["sg3"] = "Semi-Grade 3",
	["semi3"] = "Semi-Grade 3",
	["semi grade 3"] = "Semi-Grade 3",
	["3"] = "Grade 3",
	["grade3"] = "Grade 3",
	["grade 3"] = "Grade 3",
	["sg2"] = "Semi-Grade 2",
	["semi2"] = "Semi-Grade 2",
	["semi grade 2"] = "Semi-Grade 2",
	["2"] = "Grade 2",
	["grade2"] = "Grade 2",
	["grade 2"] = "Grade 2",
	["sg1"] = "Semi-Grade 1",
	["semi1"] = "Semi-Grade 1",
	["semi grade 1"] = "Semi-Grade 1",
	["1"] = "Grade 1",
	["grade1"] = "Grade 1",
	["grade 1"] = "Grade 1",
	["special"] = "Special Grade",
	["specialgrade"] = "Special Grade",
	["special grade"] = "Special Grade",
}

local CURSE_GRADE_ALIASES = {
	["4"] = "Grade 4 Cursed Spirit",
	["grade4"] = "Grade 4 Cursed Spirit",
	["grade 4"] = "Grade 4 Cursed Spirit",
	["g4"] = "Grade 4 Cursed Spirit",
	["3"] = "Grade 3 Cursed Spirit",
	["grade3"] = "Grade 3 Cursed Spirit",
	["grade 3"] = "Grade 3 Cursed Spirit",
	["g3"] = "Grade 3 Cursed Spirit",
	["2"] = "Grade 2 Cursed Spirit",
	["grade2"] = "Grade 2 Cursed Spirit",
	["grade 2"] = "Grade 2 Cursed Spirit",
	["g2"] = "Grade 2 Cursed Spirit",
	["1"] = "Grade 1 Cursed Spirit",
	["grade1"] = "Grade 1 Cursed Spirit",
	["grade 1"] = "Grade 1 Cursed Spirit",
	["g1"] = "Grade 1 Cursed Spirit",
	["special"] = "Special Grade Cursed Spirit",
	["specialgrade"] = "Special Grade Cursed Spirit",
	["special grade"] = "Special Grade Cursed Spirit",
	["sg"] = "Special Grade Cursed Spirit",
	["disaster"] = "Disaster-Class Cursed Spirit",
	["disastercurse"] = "Disaster-Class Cursed Spirit",
	["disaster curse"] = "Disaster-Class Cursed Spirit",
}

local STATUS_ALIASES = {
	["civilian"] = "Civilian",
	["student"] = "Jujutsu Student",
	["jujutsu"] = "Jujutsu Student",
	["registered"] = "Registered Sorcerer",
	["reg"] = "Registered Sorcerer",
	["unregistered"] = "Unregistered Sorcerer",
	["unreg"] = "Unregistered Sorcerer",
	["curseuser"] = "Curse User",
	["curse user"] = "Curse User",
	["wanted"] = "Wanted Curse User",
	["curse"] = "Unregistered Cursed Spirit",
	["unregisteredcurse"] = "Unregistered Cursed Spirit",
	["unregistered curse"] = "Unregistered Cursed Spirit",
	["classifiedcurse"] = "Registered Cursed Spirit",
	["classified curse"] = "Registered Cursed Spirit",
	["registeredcurse"] = "Registered Cursed Spirit",
	["registered curse"] = "Registered Cursed Spirit",
	["dojo"] = "Dojo Head",
	["dojohead"] = "Dojo Head",
	["dojo head"] = "Dojo Head",
}

local DOJO_RANK_ALIASES = {
	["none"] = "No Dojo",
	["no"] = "No Dojo",
	["unknown"] = "Unknown Dojo",
	["local"] = "Local Dojo",
	["recognized"] = "Recognized Dojo",
	["respected"] = "Respected Dojo",
	["elite"] = "Elite Dojo",
	["legendary"] = "Legendary Dojo",
}

function splitDevCommand(message)
	local args = {}
	for token in string.gmatch(tostring(message or ""), "%S+") do
		table.insert(args, token)
	end
	return args
end

function devArgsToText(args, startIndex)
	local pieces = {}
	for index = startIndex or 1, #args do
		table.insert(pieces, tostring(args[index]))
	end
	return table.concat(pieces, " ")
end

function normalizeDevKey(text)
	text = string.lower(tostring(text or ""))
	text = text:gsub("_", " ")
	text = text:gsub("%-", " ")
	text = text:gsub("%s+", " ")
	text = text:gsub("^%s+", ""):gsub("%s+$", "")
	return text
end

function getDevNumber(value, fallback, minValue, maxValue)
	local number = tonumber(value)
	if number == nil then
		number = fallback or 0
	end

	if minValue ~= nil then
		number = math.max(minValue, number)
	end

	if maxValue ~= nil then
		number = math.min(maxValue, number)
	end

	return math.floor(number)
end

function sendDevCommandMessage(player, stats, message, majorTitle)
	if not stats then
		return
	end

	ensureExtraStats(stats)
	fireLifeUpdate(player, stats, "<font color='#b27aff'><b>[ DEV ]</b></font> " .. tostring(message or "Command applied."))

	if majorTitle then
		fireMajorPopup(player, majorTitle, tostring(message or "Command applied."), "Developer Command", "This only works for DEV_USER_IDS.")
	end
end

function setDevCurseRace(stats)
	stats.Race = "Cursed Spirit"
	stats.Origin = "Vengeful Spirit Rebirth"
	stats.OriginCategory = "Race"
	stats.FamilyType = "Cursed Spirit"
	stats.FamilyName = "Cursed Spirit"
	stats.Clan = "Cursed Spirit"
	stats.IsCurse = true
	stats.CurseType = tostring(stats.CurseType or "Cursed Spirit")
	if stats.CurseType == "None" then
		stats.CurseType = "Cursed Spirit"
	end
	stats.CurseGrade = tostring(stats.CurseGrade or "Unregistered Grade 3 Cursed Spirit")
	if stats.CurseGrade == "None" then
		stats.CurseGrade = "Unregistered Grade 3 Cursed Spirit"
	end
	stats.CurseClassified = false
	stats.CurseEvolution = tostring(stats.CurseEvolution or "Dormant")
	stats.SocietyStatus = "Unregistered Cursed Spirit"
	stats.RegisteredSorcerer = false
	stats.Alive = true
	ensureCursedSpiritFlavor(stats)
	normalizeCursedSocietyState(stats)
end

function setDevHumanRace(stats)
	stats.Race = "Human"
	stats.OriginCategory = stats.OriginCategory == "Race" and "Family" or stats.OriginCategory
	if tostring(stats.Origin or "") == "Vengeful Spirit Rebirth" or tostring(stats.Origin or "") == "Cursed Spirit Rebirth" or tostring(stats.Origin or "") == "Cursed Rebirth" or tostring(stats.Origin or "") == "Curse" then
		stats.Origin = "Unknown Family"
	end
	if tostring(stats.FamilyType or "") == "Curse" or tostring(stats.FamilyType or "") == "Cursed Spirit" then
		stats.FamilyType = "Unknown"
	end
	if tostring(stats.Clan or "") == "Curse" then
		stats.Clan = stats.FamilyName or "Unknown"
	end
	stats.IsCurse = false
	stats.CurseType = "None"
	stats.CurseGrade = "None"
	stats.CurseEvolution = "None"
	stats.SocietyStatus = "Civilian"
	stats.RegisteredSorcerer = false
	normalizeCursedSocietyState(stats)
end

function setDevGrade(stats, grade)
	stats.Grade = grade
	if grade ~= "Non-Sorcerer" then
		if stats.FamilyType == "Civilian" or stats.FamilyType == "Unknown" then
			stats.FamilyType = "Sorcerer"
		end
		if not isCurseLife(stats) and stats.SocietyStatus == "Civilian" then
			stats.SocietyStatus = stats.RegisteredSorcerer and "Registered Sorcerer" or "Unregistered Sorcerer"
		end
	else
		if not isCurseLife(stats) then
			stats.SocietyStatus = "Civilian"
			stats.RegisteredSorcerer = false
		end
	end
	normalizeCursedSocietyState(stats)
end

function grantDevGrandDojo(stats)
	ensureExtraStats(stats)
	stats.Money = math.max(tonumber(stats.Money) or 0, 100000)
	stats.ClanFounded = true
	stats.PlayerClanName = stats.PlayerClanName or tostring(stats.FamilyName or "Dev")
	stats.DojoFounderName = stats.DojoFounderName or tostring(stats.Name or "Dev Founder")
	stats.DojoClanBaseName = stats.DojoClanBaseName or tostring(stats.FamilyName or "Dev")
	stats.DojoPendingLastNameChoice = false
	stats.DojoLevel = math.max(tonumber(stats.DojoLevel) or 1, 1)
	stats.DojoCondition = math.clamp(tonumber(stats.DojoCondition) or 100, 0, 100)
	stats.DojoPrestige = math.max(tonumber(stats.DojoPrestige) or 0, 25)
	stats.DojoReputation = math.max(tonumber(stats.DojoReputation) or 0, 25)
	stats.ClanReputation = math.max(tonumber(stats.ClanReputation) or 0, 25)
	stats.DojoRank = tostring(stats.DojoRank or "Local Dojo")
	stats.Assets = stats.Assets or {}

	local hasGrandDojo = false
	for _, asset in ipairs(stats.Assets) do
		if typeof(asset) == "table" and (asset.Id == "grand_dojo" or asset.BaseId == "grand_dojo") then
			hasGrandDojo = true
			break
		end
	end

	if not hasGrandDojo then
		table.insert(stats.Assets, {
			Id = "grand_dojo",
			BaseId = "grand_dojo",
			Name = "Grand Dojo",
			Type = "Property",
			Category = "Dojo",
			Rarity = "Legendary",
			Description = "Developer-granted Grand Dojo for testing.",
			EffectsText = "Dev command asset.",
			CanUse = false,
			Quantity = 1,
		})
	end

	if generateDojoRecruitPool then
		pcall(function()
			generateDojoRecruitPool(stats)
		end)
	end
	normalizeCursedSocietyState(stats)
end

function addDevStudent(stats)
	ensureExtraStats(stats)
	stats.Relationships = stats.Relationships or {}
	stats.DojoStudents = stats.DojoStudents or {}

	local studentId = "dev_student_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
	local firstNames = { "Ren", "Akio", "Mizuki", "Kaito", "Yuna", "Daiki", "Hana", "Riku" }
	local familyNames = { "Kumiwado", "Mizukara", "Amahara", "Kurogiri", "Hoshinari" }
	local techniques = { "None", "Straw Doll", "Ratio Technique", "Cursed Speech", "Blood Manipulation", "Boogie Woogie", "Ten Shadows" }
	local name = firstNames[math.random(1, #firstNames)] .. " " .. familyNames[math.random(1, #familyNames)]

	local student = {
		Id = studentId,
		Name = name,
		Role = "Student",
		Age = math.random(14, 18),
		Gender = math.random(1, 2) == 1 and "Male" or "Female",
		Grade = "Grade 4",
		SorcererGrade = "Grade 4",
		CursedTechnique = techniques[math.random(1, #techniques)],
		CursedEnergy = math.random(25, 90),
		TechniqueMastery = math.random(0, 25),
		Bond = math.random(35, 65),
		Trust = math.random(25, 55),
		Respect = math.random(25, 55),
		Fear = 0,
		Romance = 0,
		Alive = true,
		Status = "Training",
		Personality = "A developer-created test student.",
		Background = name .. " joined your dojo through a dev command for testing.",
		DojoStudent = true,
		Potential = math.random(45, 90),
		Loyalty = math.random(35, 75),
		Discipline = math.random(35, 75),
		Progress = 0,
	}

	table.insert(stats.Relationships, student)
	table.insert(stats.DojoStudents, student)
	stats.ClanStudentCount = (tonumber(stats.ClanStudentCount) or 0) + 1
	stats.ClanStudentsRecruited = (tonumber(stats.ClanStudentsRecruited) or 0) + 1
	return name
end

function getDevCommandHelpText()
	return table.concat({
		"Useful commands:",
		"!bk help",
		"!bk age 18 | !bk month 12 | !bk kill | !bk revive | !bk newlife",
		"!bk ce 500 | !bk mastery 80 | !bk money 999999 | !bk health 100 | !bk happy 100 | !bk smarts 80",
		"!bk tech limitless | !bk tech heavenly | !bk tech shrine | !bk tech none",
		"!bk grade grade1 | !bk grade special | !bk status registered | !bk wanted 5 | !bk rep -50 | !bk rec 10",
		"!bk race spirit | !bk race human | !bk resentment 200 | !bk cursegrade special | !bk cursegrade disaster | !bk threat 250 | !bk evolution 500 | !bk attack",
		"!bk hunger 80 | !bk territory school | !bk rumor mirror | !bk attention 50 | !bk curseevent",
		"!bk dojo | !bk dojorank elite | !bk dojorep 500 | !bk student",
	}, "\n")
end

function runBitKaisenDevCommand(player, rawMessage)
	if not isDev(player) then
		return
	end

	local args = splitDevCommand(rawMessage)
	if #args < 2 then
		return
	end

	if string.lower(args[1]) ~= DEV_COMMAND_PREFIX then
		return
	end

	local command = string.lower(tostring(args[2] or ""))
	local stats = playerLives[player.UserId]

	if command == "help" or command == "cmds" or command == "commands" then
		if stats then
			sendDevCommandMessage(player, stats, getDevCommandHelpText(), "BITKAISEN DEV COMMANDS")
		else
			fireMajorPopup(player, "BITKAISEN DEV COMMANDS", getDevCommandHelpText(), "Developer Commands", "No life loaded yet.")
		end
		return
	end

	if command == "newlife" or command == "new" then
		startNewLife(player)
		return
	end

	if not stats then
		fireMajorPopup(player, "DEV COMMAND FAILED", "No BitKaisen life is loaded yet.", "No Life", "Try again after your save finishes loading.")
		return
	end

	ensureExtraStats(stats)
	local value = args[3]
	local message = nil
	local shouldSave = true

	if command == "age" then
		stats.Age = getDevNumber(value, stats.Age or 0, 0, 999)
		stats.CurrentMonth = math.clamp(tonumber(stats.CurrentMonth) or 1, 1, 12)
		stats.MonthsIntoAge = math.clamp(tonumber(stats.MonthsIntoAge) or 0, 0, 11)
		message = "Age set to <b>" .. tostring(stats.Age) .. "</b>."

	elseif command == "month" then
		stats.CurrentMonth = getDevNumber(value, stats.CurrentMonth or 1, 1, 12)
		stats.MonthsIntoAge = stats.CurrentMonth - 1
		message = "Month set to <b>" .. tostring(stats.CurrentMonth) .. "</b>."

	elseif command == "kill" or command == "die" then
		stats.Alive = false
		stats.Health = 0
		stats.CauseOfDeath = devArgsToText(args, 3)
		if stats.CauseOfDeath == "" then
			stats.CauseOfDeath = "Developer command"
		end
		refreshCurseRebirthEligibility(stats)
		message = "Current life killed. Cause: <b>" .. tostring(stats.CauseOfDeath) .. "</b>."
		fireMajorPopup(player, "DEV DEATH", "The current life was ended by command.", tostring(stats.CauseOfDeath), "Death UI should open if your DeathUI script is active.")

	elseif command == "revive" then
		stats.Alive = true
		stats.Health = math.max(tonumber(stats.Health) or 0, 100)
		stats.CauseOfDeath = nil
		stats.CurseRebirthEligible = false
		message = "Current life revived."

	elseif command == "ce" or command == "cursedenergy" then
		stats.CursedEnergy = getDevNumber(value, stats.CursedEnergy or 0, 0, 999999999)
		message = "Cursed Energy set to <b>" .. tostring(stats.CursedEnergy) .. "</b>."

	elseif command == "mastery" or command == "tm" then
		stats.TechniqueMastery = getDevNumber(value, stats.TechniqueMastery or 0, 0, 100)
		message = "Technique Mastery set to <b>" .. tostring(stats.TechniqueMastery) .. "</b>."

	elseif command == "money" or command == "cash" then
		stats.Money = getDevNumber(value, stats.Money or 0, 0, 999999999)
		message = "Money set to <b>$" .. tostring(stats.Money) .. "</b>."

	elseif command == "health" or command == "hp" then
		stats.Health = getDevNumber(value, stats.Health or 100, 0, 100)
		if stats.Health > 0 then stats.Alive = true end
		message = "Health set to <b>" .. tostring(stats.Health) .. "</b>."

	elseif command == "happy" or command == "happiness" then
		stats.Happiness = getDevNumber(value, stats.Happiness or 100, 0, 100)
		message = "Happiness set to <b>" .. tostring(stats.Happiness) .. "</b>."

	elseif command == "smarts" or command == "smart" then
		stats.Smarts = getDevNumber(value, stats.Smarts or 0, 0, 100)
		message = "Smarts set to <b>" .. tostring(stats.Smarts) .. "</b>."

	elseif command == "rep" or command == "reputation" then
		stats.Reputation = getDevNumber(value, stats.Reputation or 0, -999999, 999999)
		message = "Reputation set to <b>" .. tostring(stats.Reputation) .. "</b>."

	elseif command == "wanted" or command == "wantedlevel" then
		stats.WantedLevel = getDevNumber(value, stats.WantedLevel or 0, 0, 100)
		message = "Wanted Level set to <b>" .. tostring(stats.WantedLevel) .. "</b>."

	elseif command == "rec" or command == "recs" or command == "recommendations" then
		stats.Recommendations = getDevNumber(value, stats.Recommendations or 0, 0, 9999)
		stats.TeacherRecommendations = stats.Recommendations
		message = "Recommendations set to <b>" .. tostring(stats.Recommendations) .. "</b>."

	elseif command == "resentment" or command == "cr" then
		stats.CursedResentment = getDevNumber(value, stats.CursedResentment or 0, 0, 999)
		refreshCurseRebirthEligibility(stats)
		message = "Cursed Resentment set to <b>" .. tostring(stats.CursedResentment) .. "</b>."

	elseif command == "threat" or command == "cursethreat" then
		stats.CurseThreat = getDevNumber(value, stats.CurseThreat or 0, 0, 9999)
		message = "Curse Threat set to <b>" .. tostring(stats.CurseThreat) .. "</b>."

	elseif command == "evolution" or command == "evo" then
		stats.CurseEvolutionProgress = getDevNumber(value, stats.CurseEvolutionProgress or stats.CurseEvolution or 0, 0, 99999)
		stats.CurseEvolution = tostring(stats.CurseEvolutionProgress)
		message = "Curse Evolution Progress set to <b>" .. tostring(stats.CurseEvolutionProgress) .. "</b>."

	elseif command == "tech" or command == "technique" then
		local key = normalizeDevKey(devArgsToText(args, 3))
		local technique = TECHNIQUE_ALIASES[key] or devArgsToText(args, 3)
		if technique == "" then technique = "None" end
		stats.CursedTechnique = technique
		stats.TechniqueAwakened = technique ~= "None"
		if technique == "None" then
			stats.TechniqueMastery = 0
		else
			stats.TechniqueMastery = math.max(tonumber(stats.TechniqueMastery) or 0, 1)
		end
		message = "Technique set to <b>" .. tostring(stats.CursedTechnique) .. "</b>."

	elseif command == "grade" then
		local key = normalizeDevKey(devArgsToText(args, 3))
		local grade = GRADE_ALIASES[key] or devArgsToText(args, 3)
		if grade == "" then grade = "Grade 4" end
		setDevGrade(stats, grade)
		message = "Sorcerer grade set to <b>" .. tostring(stats.Grade) .. "</b>."

	elseif command == "cursegrade" or command == "cg" then
		local key = normalizeDevKey(devArgsToText(args, 3))
		local curseGrade = CURSE_GRADE_ALIASES[key] or devArgsToText(args, 3)
		if curseGrade == "" then curseGrade = "Grade 4 Cursed Spirit" end
		stats.CurseGrade = curseGrade
		if curseGrade == "Disaster-Class Cursed Spirit" or curseGrade == "Disaster Curse" then
			stats.CurseGrade = "Special Grade Cursed Spirit"
			stats.CurseThreatClass = "Disaster"
		end
		if not isCurseLife(stats) then
			setDevCurseRace(stats)
		end
		message = "Cursed Spirit classification set to <b>" .. tostring(stats.CurseGrade) .. "</b>. Threat Class: <b>" .. tostring(stats.CurseThreatClass or "None") .. "</b>."

	elseif command == "race" then
		local key = normalizeDevKey(devArgsToText(args, 3))
		if key == "curse" or key == "cursedspirit" or key == "cursed spirit" or key == "spirit" then
			setDevCurseRace(stats)
			message = "Race set to <b>Cursed Spirit</b>."
		elseif key == "human" or key == "normal" then
			setDevHumanRace(stats)
			message = "Race set to <b>Human</b>."
		else
			message = "Unknown race. Use <b>!bk race curse</b> or <b>!bk race human</b>."
			shouldSave = false
		end

	elseif command == "status" then
		local key = normalizeDevKey(devArgsToText(args, 3))
		local status = STATUS_ALIASES[key] or devArgsToText(args, 3)
		if status == "" then status = "Civilian" end
		stats.SocietyStatus = status
		stats.RegisteredSorcerer = status == "Registered Sorcerer" or status == "Jujutsu Student"
		if status == "Curse User" or status == "Wanted Curse User" then
			stats.CurseUser = true
			stats.RegisteredSorcerer = false
		end
		message = "Society Status set to <b>" .. tostring(stats.SocietyStatus) .. "</b>."

	elseif command == "hunger" or command == "cursehunger" then
		setDevCurseRace(stats)
		stats.CurseHunger = getDevNumber(value, stats.CurseHunger or 0, 0, 100)
		message = "Cursed Spirit Hunger set to <b>" .. tostring(stats.CurseHunger) .. "%</b>."

	elseif command == "attention" or command == "societyattention" then
		setDevCurseRace(stats)
		stats.SocietyAttention = getDevNumber(value, stats.SocietyAttention or 0, 0, 100)
		stats.ExorcismRisk = math.clamp(math.max(tonumber(stats.ExorcismRisk) or 0, math.floor(stats.SocietyAttention / 2)), 0, 100)
		message = "Society Attention set to <b>" .. tostring(stats.SocietyAttention) .. "%</b>."

	elseif command == "territory" or command == "haunt" then
		setDevCurseRace(stats)
		local key = normalizeDevKey(devArgsToText(args, 3))
		local chosen = devArgsToText(args, 3)
		if key == "" or key == "random" then
			chosen = pickRandom(CURSE_TERRITORIES)
		elseif key == "school" then chosen = "Abandoned School"
		elseif key == "station" or key == "train" then chosen = "Last Train Station"
		elseif key == "hospital" then chosen = "Hospital Basement"
		elseif key == "apartment" then chosen = "Old Apartment Complex"
		elseif key == "shrine" then chosen = "Forest Shrine"
		elseif key == "sewer" then chosen = "Sewer Tunnel"
		end
		stats.CurseTerritory = chosen
		stats.CurseTerritoryControl = math.max(tonumber(stats.CurseTerritoryControl) or 0, 15)
		message = "Cursed Spirit territory set to <b>" .. tostring(stats.CurseTerritory) .. "</b>."

	elseif command == "rumor" or command == "title" then
		setDevCurseRace(stats)
		local chosen = devArgsToText(args, 3)
		if chosen == "" or normalizeDevKey(chosen) == "random" then
			chosen = pickRandom(CURSE_RUMOR_TITLES)
		end
		stats.CurseRumor = chosen
		stats.CurseRumorSpread = math.max(tonumber(stats.CurseRumorSpread) or 0, 10)
		message = "Cursed Spirit rumor set to <b>" .. tostring(stats.CurseRumor) .. "</b>."

	elseif command == "curseevent" or command == "spiritlife" then
		setDevCurseRace(stats)
		local eventText = rollCursedSpiritLifeEvent(player, stats)
		if eventText == "" then
			eventText = "No cursed spirit event rolled."
		end
		message = eventText

	elseif command == "attack" or command == "sorcererattack" then
		setDevCurseRace(stats)
		stats.SorcererAttackCooldown = 0
		local started = beginCurseSorcererAttack(player, stats, "Developer command forced a sorcerer attack.")
		if started then
			message = "Forced a sorcerer attack event."
		else
			message = "Could not start sorcerer attack. Check pending events or curse state."
		end

	elseif command == "dojo" then
		grantDevGrandDojo(stats)
		message = "Grand Dojo test setup granted."

	elseif command == "dojorank" then
		local key = normalizeDevKey(devArgsToText(args, 3))
		stats.DojoRank = DOJO_RANK_ALIASES[key] or devArgsToText(args, 3)
		if stats.DojoRank == "" then stats.DojoRank = "Local Dojo" end
		message = "Dojo Rank set to <b>" .. tostring(stats.DojoRank) .. "</b>."

	elseif command == "dojorep" or command == "dojoreputation" then
		stats.DojoReputation = getDevNumber(value, stats.DojoReputation or stats.ClanReputation or 0, 0, 999999)
		stats.ClanReputation = stats.DojoReputation
		message = "Dojo Reputation set to <b>" .. tostring(stats.DojoReputation) .. "</b>."

	elseif command == "student" or command == "addstudent" then
		grantDevGrandDojo(stats)
		local studentName = addDevStudent(stats)
		message = "Added test student: <b>" .. tostring(studentName) .. "</b>."

	else
		message = "Unknown command <b>" .. tostring(command) .. "</b>. Use <b>!bk help</b>."
		shouldSave = false
	end

	ensureExtraStats(stats)
	normalizeCursedSocietyState(stats)
	sendDevCommandMessage(player, stats, message)

	if shouldSave then
		saveStats(player, "DevCommand")
	end
end

function hookDevCommandsForPlayer(player)
	player.Chatted:Connect(function(message)
		local lowered = string.lower(tostring(message or ""))
		if string.sub(lowered, 1, #DEV_COMMAND_PREFIX) == DEV_COMMAND_PREFIX then
			runBitKaisenDevCommand(player, message)
		end
	end)
end



----------------------------------------------------------------
-- BitKaisen Runtime Bridge
-- Purpose:
--   Lets modular server systems read/update the current life without
--   dumping their logic into GameManager.
--   Used by: BitKaisenIncidentMapService and future modular services.
----------------------------------------------------------------
function setupBitKaisenRuntimeBridge()
	local folder = ServerStorage:FindFirstChild("BitKaisenRuntimeBridge")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "BitKaisenRuntimeBridge"
		folder.Parent = ServerStorage
	end

	local function getBindable(name)
		local existing = folder:FindFirstChild(name)
		if existing and existing:IsA("BindableFunction") then
			return existing
		end
		if existing then
			existing:Destroy()
		end
		local bindable = Instance.new("BindableFunction")
		bindable.Name = name
		bindable.Parent = folder
		return bindable
	end

	local getStatsBindable = getBindable("GetStats")
	local refreshPlayerBindable = getBindable("RefreshPlayer")
	local savePlayerBindable = getBindable("SavePlayer")
	local applyStatChangesBindable = getBindable("ApplyStatChanges")

	getStatsBindable.OnInvoke = function(player)
		if not player then
			return nil
		end
		return playerLives[player.UserId]
	end

	refreshPlayerBindable.OnInvoke = function(player, message, forceResetLog)
		if not player then
			return false
		end
		local stats = playerLives[player.UserId]
		if not stats then
			return false
		end
		ensureExtraStats(stats)
		normalizeCursedSocietyState(stats)
		fireLifeUpdate(player, stats, tostring(message or ""), forceResetLog == true)
		return true
	end

	savePlayerBindable.OnInvoke = function(player, reason, force)
		if not player then
			return false
		end
		if force == true then
			return forceSaveStats(player, tostring(reason or "RuntimeBridge"))
		end
		saveStats(player, tostring(reason or "RuntimeBridge"))
		return true
	end

	applyStatChangesBindable.OnInvoke = function(player, changes, message, saveAfter)
		if not player then
			return false
		end
		local stats = playerLives[player.UserId]
		if not stats or typeof(changes) ~= "table" then
			return false
		end

		for key, change in pairs(changes) do
			if typeof(key) == "string" then
				if typeof(change) == "table" then
					local mode = tostring(change.Mode or "Set")
					local value = change.Value
					if mode == "Add" then
						stats[key] = (tonumber(stats[key]) or 0) + (tonumber(value) or 0)
					elseif mode == "ClampAdd" then
						local minValue = tonumber(change.Min) or 0
						local maxValue = tonumber(change.Max) or 100
						stats[key] = math.clamp((tonumber(stats[key]) or 0) + (tonumber(value) or 0), minValue, maxValue)
					else
						stats[key] = value
					end
				else
					stats[key] = change
				end
			end
		end

		ensureExtraStats(stats)
		normalizeCursedSocietyState(stats)
		fireLifeUpdate(player, stats, tostring(message or ""), false)

		if saveAfter ~= false then
			saveStats(player, "RuntimeBridgeApply")
		end

		return true
	end

	print("[GameManager] BitKaisenRuntimeBridge ready.")
end

setupBitKaisenRuntimeBridge()

Players.PlayerAdded:Connect(function(player)
	hookDevCommandsForPlayer(player)
	loadOrStartLife(player)
end)

Players.PlayerRemoving:Connect(function(player)
	forceSaveStats(player, "PlayerRemoving")
	BitKaisenSaveSystem.ReleaseSession(player.UserId)

	if autosaveLoops[player.UserId] then
		autosaveLoops[player.UserId] = nil
	end

	playerLives[player.UserId] = nil
	pendingMissions[player.UserId] = nil
	pendingLegacy[player.UserId] = nil
	lastActionTimes[player.UserId] = nil
	dirtySavePlayers[player.UserId] = nil
	scheduledSavePlayers[player.UserId] = nil
	activeSavePlayers[player.UserId] = nil
	lastSaveTimes[player.UserId] = nil
	vipOwnershipCache[player.UserId] = nil
	extraSaveSlotsOwnershipCache[player.UserId] = nil
	doubleMoneyOwnershipCache[player.UserId] = nil
	doubleTrainingOwnershipCache[player.UserId] = nil
end)

game:BindToClose(function()
	if RunService:IsStudio() then
		task.wait(1)
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		forceSaveStats(player, "BindToClose")
	end
end)
