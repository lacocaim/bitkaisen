-- ModuleScript: BK_CurseService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose:
--   Phase 8 GameManager split.
--   Owns curse user / cursed spirit helper logic and sorcerer attack handling.
--   This module is intentionally context-driven so the live GameManager still owns player state and saves.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BitKaisenStats = require(ReplicatedStorage:WaitForChild("BitKaisenStats"))
local BitKaisenCurseEvolution = require(ReplicatedStorage:WaitForChild("BitKaisenCurseEvolution"))

local BK_CurseService = {}
local context = {}

local pendingMissions = {}
local showMissionSituation = nil

local function pickRandom(list)
	if context.PickRandom then
		return context.PickRandom(list)
	end
	return list[math.random(1, #list)]
end

local function fireLifeUpdate(player, stats, message, forceResetLog)
	if context.FireLifeUpdate then
		return context.FireLifeUpdate(player, stats, message, forceResetLog)
	end
end

local function addCurseEvolutionProgress(stats, amount, source)
	local result = BitKaisenCurseEvolution.AddProgress(stats, amount, source)
	return result.Message or ""
end

local function saveStats(player, reason)
	if context.SaveStats then
		return context.SaveStats(player, reason)
	end
end


----------------------------------------------------------------
-- Grade helpers kept local to CurseService.
-- GameManager still has wrappers, but this module cannot call them as globals.
----------------------------------------------------------------
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
	["Special Grade 1"] = 8,
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

local addCurseHunger, addCursedResentment, addSocietyAttention, applyCursedSpiritActivityFlavor, beginCurseSorcererAttack, calculateCurseAttackPower, calculateSorcererAttackPower, canBecomeVengefulSpirit, ensureCursedSpiritFlavor, ensureSorcererRegistrationState, formatCurseAttackResultPrefix, getCurseAttackChance, getCurseGradeBonus, getCurseGradeFromRebirthScore, getCurseGradeValue, getCurseHungerText, getCurseRebirthScore, getCurseSubtypeFromPreviousLife, getCurseUserBrandPressure, getCurseUserRiskText, getEstimatedUnregisteredGrade, getRandomCurseRumorTitle, getRandomCurseTerritory, getRandomHunterName, getSorcererAttackBonus, getSorcererGradeForCurseAttack, getStartingUnregisteredCurseGradeFromRebirthScore, isCurseLife, isCurseUser, isOfficialJujutsuSorcerer, isUnregisteredSorcerer, makeCurseUser, makeOfficialCurseGrade, makeUnregisteredCurseGrade, maybeBeginCurseSorcererAttack, normalizeCurseGradeAndThreatClass, normalizeCursedSocietyState, reduceCurseHunger, refreshCurseRebirthEligibility, registerCursedSpiritAfterKill, resolveCurseSorcererAttackChoice, rollCursedSpiritLifeEvent, shouldBrandAsCurseUser, stripUnregisteredCurseGradePrefix, updateCurseStatusAfterAttack


----------------------------------------------------------------
-- Extracted from GameManager: curse_user_state
----------------------------------------------------------------
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


----------------------------------------------------------------
-- Extracted from GameManager: curse_life_normalize
----------------------------------------------------------------
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

----------------------------------------------------------------
-- Extracted from GameManager: curse_rebirth_helpers
----------------------------------------------------------------
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
	score += math.floor(math.max(0, tonumber(stats.CursedObjectAnchors) or 0) * 95)
	score += math.floor(math.max(0, tonumber(stats.CursedObjectAnchorProgress) or 0) * 1.2)

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
		or (tonumber(stats.CursedObjectAnchors) or 0) >= 1
		or tostring(stats.ReincarnationAnchor or "None") ~= "None"
end

function refreshCurseRebirthEligibility(stats)
	if not stats then
		return false
	end

	stats.CurseRebirthEligible = canBecomeVengefulSpirit(stats)
	return stats.CurseRebirthEligible
end

----------------------------------------------------------------
-- Extracted from GameManager: curse_spirit_attack
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
		BitKaisenCurseEvolution.Normalize(stats)
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
	elseif evolution == "Disaster" or evolution == "Disaster Curse" then
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
	if threat >= 150 or tostring(stats.CurseThreatClass or "") == "Disaster" or tostring(stats.CurseEvolution or "") == "Disaster Curse" then
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
			local evolutionNote = addCurseEvolutionProgress(stats, math.random(8, 14), "Overwhelming a sorcerer")
			reduceCurseHunger(stats, math.random(10, 22))
			result ..= "\nYou fought them directly and overwhelmed them. Your threat level rose." .. evolutionNote
			result ..= "\nRewards: <b>+" .. tostring(ceGain) .. " CE</b> • <b>+" .. tostring(threatGain) .. " Threat</b> • Sorcerers Killed: <b>" .. tostring(stats.SorcerersKilled) .. "</b>."
		elseif gap >= 10 then
			local ceGain = math.random(10, 22)
			local threatGain = math.random(5, 10)
			local damage = math.random(8, 18)
			stats.CursedEnergy += ceGain
			stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + threatGain)
			stats.SorcerersKilled = (stats.SorcerersKilled or 0) + 1
			local evolutionNote = addCurseEvolutionProgress(stats, math.random(5, 10), "Surviving a sorcerer duel")
			reduceCurseHunger(stats, math.random(8, 16))
			stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
			result ..= "\nYou won, but the sorcerer forced a real fight before falling." .. evolutionNote
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
			local evolutionNote = addCurseEvolutionProgress(stats, math.random(8, 15), "Ambushing a sorcerer")
			result ..= "\nYou struck first and ended the hunt before the sorcerer could control the fight." .. evolutionNote
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

function getStartingUnregisteredCurseGradeFromRebirthScore(score)
	return makeUnregisteredCurseGrade(getCurseGradeFromRebirthScore(score))
end

function getRandomCurseTerritory()
	return pickRandom(CURSE_TERRITORIES)
end

function getRandomCurseRumorTitle()
	return pickRandom(CURSE_RUMOR_TITLES)
end


BK_CurseService.GetCurseUserBrandPressure = getCurseUserBrandPressure
BK_CurseService.ShouldBrandAsCurseUser = shouldBrandAsCurseUser
BK_CurseService.GetCurseUserRiskText = getCurseUserRiskText
BK_CurseService.GetEstimatedUnregisteredGrade = getEstimatedUnregisteredGrade
BK_CurseService.IsOfficialJujutsuSorcerer = isOfficialJujutsuSorcerer
BK_CurseService.IsCurseUser = isCurseUser
BK_CurseService.IsUnregisteredSorcerer = isUnregisteredSorcerer
BK_CurseService.MakeCurseUser = makeCurseUser
BK_CurseService.EnsureSorcererRegistrationState = ensureSorcererRegistrationState

BK_CurseService.IsCurseLife = isCurseLife
BK_CurseService.NormalizeCursedSocietyState = normalizeCursedSocietyState

BK_CurseService.AddCursedResentment = addCursedResentment
BK_CurseService.GetCurseRebirthScore = getCurseRebirthScore
BK_CurseService.GetCurseGradeFromRebirthScore = getCurseGradeFromRebirthScore
BK_CurseService.GetCurseSubtypeFromPreviousLife = getCurseSubtypeFromPreviousLife
BK_CurseService.CanBecomeVengefulSpirit = canBecomeVengefulSpirit
BK_CurseService.RefreshCurseRebirthEligibility = refreshCurseRebirthEligibility
BK_CurseService.GetStartingUnregisteredCurseGradeFromRebirthScore = getStartingUnregisteredCurseGradeFromRebirthScore

BK_CurseService.StripUnregisteredCurseGradePrefix = stripUnregisteredCurseGradePrefix
BK_CurseService.MakeUnregisteredCurseGrade = makeUnregisteredCurseGrade
BK_CurseService.MakeOfficialCurseGrade = makeOfficialCurseGrade
BK_CurseService.NormalizeCurseGradeAndThreatClass = normalizeCurseGradeAndThreatClass

BK_CurseService.GetRandomHunterName = getRandomHunterName
BK_CurseService.EnsureCursedSpiritFlavor = ensureCursedSpiritFlavor
BK_CurseService.AddCurseHunger = addCurseHunger
BK_CurseService.ReduceCurseHunger = reduceCurseHunger
BK_CurseService.AddSocietyAttention = addSocietyAttention
BK_CurseService.GetCurseHungerText = getCurseHungerText
BK_CurseService.ApplyCursedSpiritActivityFlavor = applyCursedSpiritActivityFlavor
BK_CurseService.RollCursedSpiritLifeEvent = rollCursedSpiritLifeEvent
BK_CurseService.GetCurseGradeValue = getCurseGradeValue
BK_CurseService.GetCurseGradeBonus = getCurseGradeBonus
BK_CurseService.GetSorcererAttackBonus = getSorcererAttackBonus
BK_CurseService.GetSorcererGradeForCurseAttack = getSorcererGradeForCurseAttack
BK_CurseService.CalculateCurseAttackPower = calculateCurseAttackPower
BK_CurseService.CalculateSorcererAttackPower = calculateSorcererAttackPower
BK_CurseService.GetCurseAttackChance = getCurseAttackChance
BK_CurseService.BeginCurseSorcererAttack = beginCurseSorcererAttack
BK_CurseService.MaybeBeginCurseSorcererAttack = maybeBeginCurseSorcererAttack
BK_CurseService.FormatCurseAttackResultPrefix = formatCurseAttackResultPrefix
BK_CurseService.RegisterCursedSpiritAfterKill = registerCursedSpiritAfterKill
BK_CurseService.UpdateCurseStatusAfterAttack = updateCurseStatusAfterAttack
BK_CurseService.ResolveCurseSorcererAttackChoice = resolveCurseSorcererAttackChoice

BK_CurseService.GetRandomCurseTerritory = getRandomCurseTerritory
BK_CurseService.GetRandomCurseRumorTitle = getRandomCurseRumorTitle
BK_CurseService.CurseTerritories = CURSE_TERRITORIES
BK_CurseService.CurseRumorTitles = CURSE_RUMOR_TITLES

function BK_CurseService.Init(ctx)
	context = ctx or {}
	pendingMissions = context.PendingMissions or pendingMissions or {}
	showMissionSituation = context.ShowMissionSituation or showMissionSituation
	if context and context.IS_DEBUG then print("[BK_CurseService] Loaded Phase 8 curse helpers.") end
end

return BK_CurseService

