-- ModuleScript: BitKaisenCombat
-- Location: ReplicatedStorage
-- Purpose: Shared combat math for missions, duels, curse attacks, and future combat content.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BitKaisenCombat = {}
local BitKaisenTraits = require(ReplicatedStorage:WaitForChild("BitKaisenTraits"))
local BitKaisenAssets = require(ReplicatedStorage:WaitForChild("BitKaisenAssets"))
local BitKaisenCursedTools = require(ReplicatedStorage:WaitForChild("BitKaisenCursedTools"))
local BitKaisenTechniqueEffects = require(ReplicatedStorage:WaitForChild("BitKaisenTechniqueEffects"))

local GRADE_POWER = {
	["Non-Sorcerer"] = 0,
	["Grade 4"] = 16,
	["Semi-Grade 3"] = 26,
	["Grade 3"] = 38,
	["Semi-Grade 2"] = 54,
	["Grade 2"] = 72,
	["Semi-Grade 1"] = 92,
	["Grade 1"] = 116,
	["Special Grade 1"] = 146,
	["Special Grade"] = 190,
}

local ORIGIN_POWER = {
	["Gojo Clan"] = 22,
	["Kenjaku Clan"] = 19,
	["Pumpkin King Clan"] = 18,
	["Ryomen Clan"] = 20,
	["Zenin Clan"] = 16,
	["Kamo Clan"] = 15,
	["Sugawara Lineage"] = 18,
	["Fushiguro Lineage"] = 14,
	["Okkotsu Lineage"] = 18,
	["Itadori Lineage"] = 14,
	["Cursed Womb"] = 18,
	["Branch Sorcerer Family"] = 10,
	["Unknown Family"] = 8,
	["Fallen Sorcerer Family"] = 7,
	["Minor Sorcerer Family"] = 6,
}

local TECHNIQUE_POWER = {
	["Limitless"] = 38,
	["Ten Shadows"] = 36,
	["Copy"] = 34,
	["Rika Manifestation"] = 34,
	["Shrine"] = 34,
	["Brain Transplant"] = 33,
	["Pumpkin Control"] = 30,
	["Cursed Spirit Manipulation"] = 32,
	["Idle Transfiguration"] = 32,
	["Mythical Beast Amber"] = 32,
	["Puppet Manipulation"] = 30,
	["Mechamaru"] = 30,
	["Heavenly Restriction"] = 30,
	["Private Pure Love Train"] = 30,
	["Deadly Sentencing"] = 30,
	["Projection Sorcery"] = 28,
	["Blood Manipulation"] = 26,
	["Cursed Speech"] = 25,
	["Boogie Woogie"] = 24,
	["Ratio Technique"] = 24,
	["Construction"] = 22,
	["Tool Manipulation"] = 20,
	["Simple Domain"] = 16,
}

local function cleanGrade(grade)
	grade = tostring(grade or "Non-Sorcerer")
	if string.sub(grade, 1, 13) == "Unregistered " then
		grade = string.sub(grade, 14)
	elseif string.sub(grade, 1, 11) == "Curse User" then
		grade = string.gsub(grade, "^Curse User%s+", "")
	end
	return grade
end

local function getTechnique(stats)
	local technique = tostring(stats and stats.CursedTechnique or "None")
	if technique == "None" or technique == "" then
		technique = tostring(stats and stats.InnateTechnique or "None")
	end
	return technique
end

local function getAssetBonuses(stats)
	local ok, bonuses = pcall(function()
		return BitKaisenAssets.GetPassiveBonuses(stats)
	end)
	return ok and bonuses or {}
end

function BitKaisenCombat.GetCombatPower(stats, options)
	options = options or {}
	if typeof(stats) ~= "table" then
		return 0
	end

	local cursedEnergy = tonumber(stats.CursedEnergy) or 0
	local smarts = tonumber(stats.Smarts) or 0
	local mastery = tonumber(stats.TechniqueMastery) or 0
	local strength = tonumber(stats.Strength) or 0
	local health = tonumber(stats.Health) or 100
	local reputation = tonumber(stats.Reputation) or 0
	local grade = cleanGrade(stats.Grade)
	local technique = getTechnique(stats)
	local origin = tostring(stats.Origin or stats.Clan or "Minor Sorcerer Family")

	local power = 0
	power += cursedEnergy * 0.78
	power += smarts * 0.34
	power += strength * 0.42
	power += math.max(0, health) * 0.18
	power += math.max(0, reputation) * 0.12
	power += GRADE_POWER[grade] or 0
	power += ORIGIN_POWER[origin] or 0

	if stats.HeavenlyRestricted == true then
		power += 36
	end

	if technique ~= "None" and technique ~= "" then
		power += TECHNIQUE_POWER[technique] or 20
		power += mastery * 0.72
	end

	if stats.InJujutsuHigh == true or stats.RegisteredSorcerer == true then
		power += 12
	end

	if stats.ClanFounded == true then
		power += math.floor((tonumber(stats.ClanReputation) or 0) * 0.35)
	end

	local assetBonuses = getAssetBonuses(stats)
	power += tonumber(assetBonuses.MissionPowerBonus) or 0
	power += math.floor((tonumber(assetBonuses.ReputationBonus) or 0) * 0.5)

	local equippedTool = BitKaisenCursedTools.GetTool(stats.EquippedCursedToolId)
	if equippedTool and equippedTool.Effects then
		power += tonumber(equippedTool.Effects.CombatPower) or 0
		power += tonumber(equippedTool.Effects.DefensePower) or 0
	end

	local techniqueLower = string.lower(tostring(technique or ""))
	if string.find(techniqueLower, "cursed spirit manipulation", 1, true) then
		power += math.min(50, (tonumber(stats.StoredCurses) or 0) * 4 + math.floor((tonumber(stats.StoredCursePower) or 0) / 25))
	elseif string.find(techniqueLower, "ten shadows", 1, true) then
		power += math.min(46, (tonumber(stats.TamedShikigami) or 0) * 5)
	end

	local techniqueModifiers = BitKaisenTechniqueEffects.GetCombatModifiers(stats)
	power += techniqueModifiers.PowerBonus or 0
	power *= BitKaisenTraits.GetModifier(stats, "CombatGainMult", 1)
	power += BitKaisenTraits.GetModifier(stats, "MissionSuccessBonus", 0)
	power += tonumber(options.PowerBonus) or 0

	return math.max(0, math.floor(power + 0.5))
end

function BitKaisenCombat.GetEnemyPower(missionData, options)
	options = options or {}
	missionData = missionData or {}

	local difficulty = tonumber(missionData.Difficulty) or 20
	local volatility = tonumber(options.Volatility) or 18
	local roll = math.random(-volatility, volatility)
	return math.max(1, difficulty + roll)
end

function BitKaisenCombat.ResolveMissionCombat(stats, missionData, options)
	options = options or {}
	missionData = missionData or {}

	local playerBase = BitKaisenCombat.GetCombatPower(stats, options)
	local playerRoll = math.random(8, 34)
	local enemyPower = BitKaisenCombat.GetEnemyPower(missionData, options)
	local playerPower = playerBase + playerRoll
	local margin = playerPower - enemyPower
	local success = margin >= -6

	local outcome = "Narrow Loss"
	if margin >= 70 then
		outcome = "Overwhelming Win"
	elseif margin >= 35 then
		outcome = "Clean Win"
	elseif margin >= 8 then
		outcome = "Costly Win"
	elseif margin >= -6 then
		outcome = "Barely Won"
	elseif margin <= -55 then
		outcome = "Crushed"
	elseif margin <= -25 then
		outcome = "Bad Loss"
	end

	local techniqueModifiers = BitKaisenTechniqueEffects.GetCombatModifiers(stats)
	local riskMult = BitKaisenTraits.GetModifier(stats, "RiskMult", 1)
	local baseDamage = tonumber(missionData.DmgPenalty) or math.max(8, math.floor(enemyPower * 0.25))
	local smartsReduction = math.floor((tonumber(stats and stats.Smarts) or 0) / 7)
	local damage = 0

	if success then
		if margin < 8 then
			damage = math.max(2, math.floor((baseDamage * 0.45 * riskMult) - smartsReduction))
		elseif margin < 35 then
			damage = math.max(0, math.floor((baseDamage * 0.22 * riskMult) - smartsReduction))
		end
	else
		damage = math.max(4, math.floor((baseDamage * (margin <= -55 and 1.18 or 0.88) * riskMult) - smartsReduction))
	end

	damage = math.max(0, math.floor((damage * (techniqueModifiers.DamageTakenMult or 1)) + 0.5))

	local masteryGain = 0
	if tostring(stats and stats.CursedTechnique or "None") ~= "None" then
		masteryGain = success and math.random(1, 3) or math.random(0, 2)
		masteryGain += techniqueModifiers.MasteryGainBonus or 0
	end

	local ceBonus = success and math.max(0, math.floor(((tonumber(missionData.RewardCE) or 0) * 0.08) * (techniqueModifiers.CursedEnergyRewardMult or 1))) or 0
	local summary = "Combat: <b>" .. outcome .. "</b> (Power " .. tostring(playerPower) .. " vs Threat " .. tostring(enemyPower) .. ")."
	if damage > 0 then
		summary ..= " Health <b>-" .. tostring(damage) .. "</b>."
	end
	if masteryGain > 0 then
		summary ..= " Mastery <b>+" .. tostring(masteryGain) .. "</b>."
	end
	if techniqueModifiers.Note and techniqueModifiers.Note ~= "" then
		summary ..= " " .. techniqueModifiers.Note
	end

	return {
		Success = success,
		Outcome = outcome,
		PlayerPower = playerPower,
		EnemyPower = enemyPower,
		Margin = margin,
		HealthDamage = damage,
		MasteryGain = masteryGain,
		CursedEnergyBonus = ceBonus,
		RewardMoneyMult = techniqueModifiers.MoneyRewardMult or 1,
		RewardRepMult = techniqueModifiers.ReputationRewardMult or 1,
		TechniqueDamageMult = techniqueModifiers.DamageTakenMult or 1,
		Summary = summary,
	}
end

return BitKaisenCombat
