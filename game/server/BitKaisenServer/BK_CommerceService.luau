-- ModuleScript: BK_CommerceService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose:
--   Owns BitKaisen developer products, gamepass purchase callbacks, and purchase reward grants.
--   Update 5:
--     - Added monetization products:
--       * Cursed Technique Reroll
--       * Clan Reroll
--       * Trait Reroll
--       * Full Reroll
--       * Mastery Boost 15 Min
--       * CE Boost 15 Min
--       * Elite Sorcerer Pack
--   Update 6:
--     - Registered 5 new gamepasses (Lucky Sorcerer, Training Prodigy, Mission Investor,
--       Legacy Blessing, Dojo Expansion). IDs are placeholders (0) near the top until you set real IDs.
--       Their gameplay effects are applied in GameManager. Purchase confirmation popups are here.
--       Placeholder ID 0 can never be purchased, so the new branches stay inert until real IDs are set.
--   Hotfix:
--     - Clan Reroll / Full Reroll can no longer mutate Cursed Spirit lives into invalid human/cursed lineage states.
--     - Paid clan rerolls exclude Race origins, Cursed Womb, and cursed/race-type origins.
--   Notes:
--     - Old product prices/IDs preserved.
--     - No aging/save/relationship rewrites.
--     - Boost products apply an immediate reward AND store boost timers for GameManager/UI support.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local giftMailboxStore = DataStoreService:GetDataStore("BK_GiftMailbox")

local BitKaisenStats = require(ReplicatedStorage:WaitForChild("BitKaisenStats"))
local BitKaisenTraits = require(ReplicatedStorage:WaitForChild("BitKaisenTraits"))
local BitKaisenTechniqueEvolution = require(ReplicatedStorage:WaitForChild("BitKaisenTechniqueEvolution"))
local BitKaisenCursedTools = require(ReplicatedStorage:WaitForChild("BitKaisenCursedTools"))
local BK_JobService = require(script.Parent:WaitForChild("BK_JobService"))

local BK_CommerceService = {}
local context = {}

----------------------------------------------------------------
-- GAMEPASS IDS
----------------------------------------------------------------
local VIP_SORCERER_PASS_ID = 1847855390
local EXTRA_SAVE_SLOTS_PASS_ID = 1850884816
local DOUBLE_MONEY_PASS_ID = 1849510820
local DOUBLE_TRAINING_PASS_ID = 1849210885 -- Displayed as 2x Progress in the shop.
local LUCKY_BIRTH_PASS_ID = 1859848647
local EXTRA_DOJO_STUDENTS_PASS_ID = 1862959768
local GOD_MODE_PASS_ID = 1861509054
local GO_ROGUE_PASS_ID = 1887460270

----------------------------------------------------------------
-- UPDATE 6 GAMEPASS IDS
-- >>> REPLACE THE 0s WITH YOUR REAL GAMEPASS IDS FROM THE CREATOR DASHBOARD <
-- These must match the IDs used in BitKaisenSettingsMenu and GameManager.
-- While an ID is 0, ownership checks and purchase popups are safely skipped.
----------------------------------------------------------------
local LUCKY_SORCERER_PASS_ID = 1863476467
local TRAINING_PRODIGY_PASS_ID = 1863314699
local MISSION_INVESTOR_PASS_ID = 1863458434
local LEGACY_BLESSING_PASS_ID = 1865683126
local DOJO_EXPANSION_PASS_ID = 0
local FOCUSED_TRAINING_PASS_ID = 1847591321

----------------------------------------------------------------
-- EXISTING DEVELOPER PRODUCT IDS
----------------------------------------------------------------
local STARTER_SORCERER_PACK_PRODUCT_ID = 3595826857
local FOCUSED_TRAINING_PRODUCT_ID = 3595838153
local MONEY_5000_PRODUCT_ID = 3596044734
local MONEY_25000_PRODUCT_ID = 3595898637
local MONEY_100000_PRODUCT_ID = 3596045207
local RECRUIT_REROLL_PRODUCT_ID = 3596045471
local RECOMMENDATION_LETTER_PRODUCT_ID = 3600600214
local EMERGENCY_TREATMENT_PRODUCT_ID = 3600600619

----------------------------------------------------------------
-- UPDATE 5 DEVELOPER PRODUCT IDS
----------------------------------------------------------------
local CT_REROLL_PRODUCT_ID = 3601369202
local CLAN_REROLL_PRODUCT_ID = 3601369293
local TRAIT_REROLL_PRODUCT_ID = 3601369404
local FULL_POWER_REROLL_PRODUCT_ID = 3601369468
local MASTERY_BOOST_15_PRODUCT_ID = 3601369579
local CE_BOOST_15_PRODUCT_ID = 3601369642
local ELITE_SORCERER_PACK_PRODUCT_ID = 3601369769
local RCT_REVIVE_PRODUCT_ID = 3601401158
local DOJO_FUNDING_PACK_PRODUCT_ID = 3603671641
-- Placeholder IDs. Replace with real Developer Product IDs before release.
local CT_EVOLUTION_ACCELERATOR_PRODUCT_ID = 3603684614
local BLACK_FLASH_DRILL_PACK_PRODUCT_ID = 3603684671
-- Developer Products for gifting gamepass-style entitlements.
local GIFT_GO_ROGUE_PRODUCT_ID = 3604042615
local GIFT_GOD_MODE_PRODUCT_ID = 3606084567
local GIFT_AFK_STABILIZATION_PRODUCT_ID = 3606084638
local TEST_GIFT_PRODUCT_ID = 3606089240
-- Developer Product for resetting an active combat fight.
local RESET_FIGHT_PRODUCT_ID = 3604877974
-- Domain Encore: one extra Domain use for the current fight only.
local DOMAIN_ENCORE_PRODUCT_ID = 3609182085
-- Bounty Clear: resets Wanted Level back to 0.
local BOUNTY_CLEAR_PRODUCT_ID = 3609194803
-- Gamepass for the one-time AFK Stabilization unlock.
local AFK_STABILIZATION_GAMEPASS_ID = 1879156343
local AFK_STABILIZATION_PRODUCT_ID = AFK_STABILIZATION_GAMEPASS_ID
local BINDING_VOW_SPECIALIST_PASS_ID = 1863380690

-- Update 13 developer products. Fill these with real Developer Product IDs after creating them in Roblox.
local CLAN_WAR_MEDIATION_PRODUCT_ID = 3605163954
local CURSED_TOOL_SALVAGE_KIT_PRODUCT_ID = 3605164055
local COMBAT_RECOVERY_KIT_PRODUCT_ID = 3605164164

-- Summer Update: Time Skip developer products.
-- >>> REPLACE 0s WITH REAL DEVELOPER PRODUCT IDs FROM THE CREATOR DASHBOARD <<<
local TIME_SKIP_5_PRODUCT_ID  = 3607128993  -- R$75  — Skip 5 years
local TIME_SKIP_10_PRODUCT_ID = 3607129012  -- R$149 — Skip 10 years
local TIME_SKIP_25_PRODUCT_ID = 3607129036  -- R$299 — Skip 25 years

local RCT_REVIVE_MAX_PER_LIFE = 2

----------------------------------------------------------------
-- INTERNAL STATE
----------------------------------------------------------------
local initialized = false
local pendingGifts = {}
local giftInitiateCooldowns = {}

local GIFT_INITIATE_COOLDOWN_SECONDS = 2

local TEST_PURCHASE_PLACE_IDS = {
	[104206065947170] = true,
}

local function isTestPurchasePlace()
	return TEST_PURCHASE_PLACE_IDS[game.PlaceId] == true
end


----------------------------------------------------------------
-- CONTEXT BRIDGES
----------------------------------------------------------------
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

local function fireMajorPopup(player, title, body, highlight, footer)
	if context.FireMajorPopup then
		return context.FireMajorPopup(player, title, body, highlight, footer)
	end
end

local function forceSaveStats(player, reason)
	if context.ForceSaveStats then
		return context.ForceSaveStats(player, reason)
	end
end

local function ownsDoubleMoneyPass(player)
	if context.OwnsDoubleMoneyPass then
		return context.OwnsDoubleMoneyPass(player)
	end
	return false
end

local function ownsDoubleTrainingPass(player)
	if context.OwnsDoubleTrainingPass then
		return context.OwnsDoubleTrainingPass(player)
	end
	return false
end

local function clearVIPCache(player)
	if context.ClearVIPCache then
		return context.ClearVIPCache(player)
	end
end

local function syncMonetizationEntitlements(player, stats)
	if context.SyncMonetizationEntitlements then
		return context.SyncMonetizationEntitlements(player, stats)
	end
end

local function generateDojoRecruitPool(stats)
	if context.GenerateDojoRecruitPool then
		return context.GenerateDojoRecruitPool(stats)
	end
end

local function ownsAssetById(stats, assetId)
	if context.OwnsAssetById then
		return context.OwnsAssetById(stats, assetId)
	end

	for _, asset in ipairs(stats and stats.Assets or {}) do
		if typeof(asset) == "table" then
			if asset.Id == assetId or asset.BaseId == assetId then
				return true
			end
		elseif asset == assetId then
			return true
		end
	end

	return false
end

----------------------------------------------------------------
-- PRODUCT DEFINITIONS
----------------------------------------------------------------
local DEVELOPER_PRODUCTS = {
	[STARTER_SORCERER_PACK_PRODUCT_ID] = {
		Id = "starter_pack",
		Name = "Starter Sorcerer Pack",
	},

	[FOCUSED_TRAINING_PRODUCT_ID] = {
		Id = "focused_training",
		Name = "Focused Training Session",
	},

	[MONEY_5000_PRODUCT_ID] = {
		Id = "money_pack",
		Name = "$5,000 Money",
		Amount = 5000,
	},

	[MONEY_25000_PRODUCT_ID] = {
		Id = "money_pack",
		Name = "$25,000 Money",
		Amount = 25000,
	},

	[MONEY_100000_PRODUCT_ID] = {
		Id = "money_pack",
		Name = "$100,000 Money",
		Amount = 100000,
	},

	[RECRUIT_REROLL_PRODUCT_ID] = {
		Id = "recruit_reroll",
		Name = "Recruit Reroll",
	},

	[RECOMMENDATION_LETTER_PRODUCT_ID] = {
		Id = "recommendation_letter",
		Name = "Recommendation Letter",
	},

	[EMERGENCY_TREATMENT_PRODUCT_ID] = {
		Id = "emergency_treatment",
		Name = "Emergency Treatment",
	},

	----------------------------------------------------------------
	-- UPDATE 5 PRODUCTS
	----------------------------------------------------------------
	[CT_REROLL_PRODUCT_ID] = {
		Id = "ct_reroll",
		Name = "Cursed Technique Reroll",
	},

	[CLAN_REROLL_PRODUCT_ID] = {
		Id = "clan_reroll",
		Name = "Clan Reroll",
	},

	[TRAIT_REROLL_PRODUCT_ID] = {
		Id = "trait_reroll",
		Name = "Trait Reroll",
	},

	[FULL_POWER_REROLL_PRODUCT_ID] = {
		Id = "full_power_reroll",
		Name = "Full Reroll",
	},

	[MASTERY_BOOST_15_PRODUCT_ID] = {
		Id = "mastery_boost_15",
		Name = "Mastery Boost 15 Min",
	},

	[CE_BOOST_15_PRODUCT_ID] = {
		Id = "ce_boost_15",
		Name = "CE Boost 15 Min",
	},

	[ELITE_SORCERER_PACK_PRODUCT_ID] = {
		Id = "elite_sorcerer_pack",
		Name = "Elite Sorcerer Pack",
	},

	[RCT_REVIVE_PRODUCT_ID] = {
		Id = "rct_revive",
		Name = "RCT Revive",
	},

	[DOJO_FUNDING_PACK_PRODUCT_ID] = {
		Id = "dojo_funding_pack",
		Name = "Dojo Funding Pack",
	},

	[CT_EVOLUTION_ACCELERATOR_PRODUCT_ID] = {
		Id = "ct_evolution_accelerator",
		Name = "CT Evolution Accelerator",
	},

	[BLACK_FLASH_DRILL_PACK_PRODUCT_ID] = {
		Id = "black_flash_drill_pack",
		Name = "Black Flash Drill Pack",
	},

	[GIFT_GO_ROGUE_PRODUCT_ID] = {
		Id = "gift_gamepass",
		Name = "Gift Go Rogue",
		GiftPassKey = "GoRogue",
		GiftLabel = "Go Rogue",
	},

	[GIFT_GOD_MODE_PRODUCT_ID] = {
		Id = "gift_gamepass",
		Name = "Gift God Mode",
		GiftPassKey = "GodMode",
		GiftLabel = "God Mode",
	},

	[GIFT_AFK_STABILIZATION_PRODUCT_ID] = {
		Id = "gift_gamepass",
		Name = "Gift AFK Stabilization",
		GiftPassKey = "AFKStabilization",
		GiftLabel = "AFK Stabilization",
	},

	[TEST_GIFT_PRODUCT_ID] = {
		Id = "gift_gamepass",
		Name = "Test Gift",
		GiftPassKey = "TestGift",
		GiftLabel = "Test Gift",
		TestOnly = true,
	},

	[RESET_FIGHT_PRODUCT_ID] = {
		Id = "reset_combat_fight",
		Name = "Reset Fight",
	},

	[DOMAIN_ENCORE_PRODUCT_ID] = {
		Id = "domain_encore",
		Name = "Domain Encore",
	},

	[BOUNTY_CLEAR_PRODUCT_ID] = {
		Id = "bounty_clear",
		Name = "Bounty Clear",
	},

	[AFK_STABILIZATION_PRODUCT_ID] = {
		Id = "afk_stabilization_unlock",
		Name = "AFK Stabilization",
	},

	[CLAN_WAR_MEDIATION_PRODUCT_ID] = {
		Id = "clan_war_mediation",
		Name = "Clan War Mediation",
	},

	[CURSED_TOOL_SALVAGE_KIT_PRODUCT_ID] = {
		Id = "cursed_tool_salvage_kit",
		Name = "Cursed Tool Salvage Kit",
	},

	[COMBAT_RECOVERY_KIT_PRODUCT_ID] = {
		Id = "combat_recovery_kit",
		Name = "Combat Recovery Kit",
	},

	[TIME_SKIP_5_PRODUCT_ID] = {
		Id = "time_skip_5",
		Name = "Time Skip +5 Years",
		Years = 5,
	},

	[TIME_SKIP_10_PRODUCT_ID] = {
		Id = "time_skip_10",
		Name = "Time Skip +10 Years",
		Years = 10,
	},

	[TIME_SKIP_25_PRODUCT_ID] = {
		Id = "time_skip_25",
		Name = "Time Skip +25 Years",
		Years = 25,
	},
}

DEVELOPER_PRODUCTS[0] = nil

----------------------------------------------------------------
-- GENERAL HELPERS
----------------------------------------------------------------
local function formatMoney(amount)
	amount = math.floor(tonumber(amount) or 0)

	local text = tostring(amount)
	local result = text

	while true do
		local formatted, count = string.gsub(result, "^(-?%d+)(%d%d%d)", "%1,%2")
		result = formatted
		if count == 0 then
			break
		end
	end

	return "$" .. result
end

local function getCurrentUnixTime()
	return os.time()
end

local function getTechniqueName(stats)
	if not stats then
		return "None"
	end

	local cursedTechnique = tostring(stats.CursedTechnique or "None")
	local innateTechnique = tostring(stats.InnateTechnique or "None")

	if cursedTechnique ~= "None" then
		return cursedTechnique
	end

	if innateTechnique ~= "None" then
		return innateTechnique
	end

	return "None"
end

local function shouldTechniqueBeUsableNow(stats)
	if not stats then
		return false
	end

	local age = tonumber(stats.Age) or 0

	return stats.TechniqueUsable == true
		or stats.TechniqueAwakened == true
		or age >= 8
end

local function getOriginDataByName(originName)
	originName = tostring(originName or "")

	if originName == "" then
		return nil
	end

	for _, originData in ipairs(BitKaisenStats.Origins or {}) do
		if tostring(originData.DisplayName or "") == originName
			or tostring(originData.Id or "") == originName
			or tostring(originData.FamilyName or "") == originName then
			return originData
		end
	end

	return nil
end

local function getCurrentOriginData(stats)
	if not stats then
		return nil
	end

	local originData = getOriginDataByName(stats.Origin)
	if originData then
		return originData
	end

	originData = getOriginDataByName(stats.Clan)
	if originData then
		return originData
	end

	originData = getOriginDataByName(stats.FamilyName)
	if originData then
		return originData
	end

	return nil
end

local function isForbiddenPaidRerollOrigin(originData)
	if typeof(originData) ~= "table" then
		return true
	end

	local id = string.lower(tostring(originData.Id or ""))
	local displayName = string.lower(tostring(originData.DisplayName or ""))
	local category = string.lower(tostring(originData.Category or ""))
	local familyType = string.lower(tostring(originData.FamilyType or ""))
	local familyName = string.lower(tostring(originData.FamilyName or ""))

	if category == "race" then
		return true
	end

	if familyType == "race" then
		return true
	end

	if string.find(id, "curse") ~= nil
		or string.find(id, "cursed") ~= nil
		or string.find(id, "womb") ~= nil then
		return true
	end

	if string.find(displayName, "curse") ~= nil
		or string.find(displayName, "cursed") ~= nil
		or string.find(displayName, "womb") ~= nil then
		return true
	end

	if string.find(familyName, "curse") ~= nil
		or string.find(familyName, "cursed") ~= nil
		or string.find(familyName, "womb") ~= nil then
		return true
	end

	return false
end

local function rollPaidHumanOrigin()
	local origins = BitKaisenStats.Origins or {}
	local validOrigins = {}

	for _, originData in ipairs(origins) do
		if typeof(originData) == "table" and not isForbiddenPaidRerollOrigin(originData) then
			table.insert(validOrigins, originData)
		end
	end

	if #validOrigins <= 0 then
		return BitKaisenStats.RollOrigin()
	end

	local totalWeight = 0
	for _, originData in ipairs(validOrigins) do
		totalWeight += tonumber(originData.Chance or originData.Weight or 1) or 1
	end

	if totalWeight <= 0 then
		return validOrigins[math.random(1, #validOrigins)]
	end

	local roll = math.random() * totalWeight
	local current = 0

	for _, originData in ipairs(validOrigins) do
		current += tonumber(originData.Chance or originData.Weight or 1) or 1
		if roll <= current then
			return originData
		end
	end

	return validOrigins[#validOrigins]
end

local function isCursedSpiritLife(stats)
	if not stats then
		return false
	end

	local race = string.lower(tostring(stats.Race or ""))
	local path = string.lower(tostring(stats.Path or ""))
	local familyType = string.lower(tostring(stats.FamilyType or ""))
	local origin = string.lower(tostring(stats.Origin or ""))
	local clan = string.lower(tostring(stats.Clan or ""))
	local curseType = string.lower(tostring(stats.CurseType or ""))
	local societyStatus = string.lower(tostring(stats.SocietyStatus or ""))

	return stats.IsCurse == true
		or race == "cursed spirit"
		or race == "curse"
		or path == "cursed spirit"
		or familyType == "cursed spirit"
		or familyType == "curse"
		or string.find(origin, "cursed spirit") ~= nil
		or string.find(origin, "curse") ~= nil
		or string.find(clan, "cursed spirit") ~= nil
		or string.find(clan, "curse") ~= nil
		or string.find(curseType, "cursed") ~= nil
		or string.find(curseType, "curse") ~= nil
		or string.find(societyStatus, "cursed spirit") ~= nil
end

local function rollOpenTechnique(stats)
	local originName = "Minor Sorcerer Family"

	if stats then
		originName = tostring(stats.Origin or stats.Clan or "Minor Sorcerer Family")
	end

	if BitKaisenStats.RollTechnique then
		return BitKaisenStats.RollTechnique(originName, {
			IncludeClanLocked = false,
		})
	end

	return "Cursed Energy Discharge"
end

local function rollTechniqueForCurrentOrigin(stats)
	local originData = getCurrentOriginData(stats)

	if originData then
		local innate = BitKaisenStats.RollInnateTechniqueForOrigin(originData)

		if innate and tostring(innate) ~= "None" then
			return tostring(innate), "Innate"
		end
	end

	return rollOpenTechnique(stats), "Normal"
end

local function applyTechniqueToStats(stats, techniqueName, techniqueType, forceUsable)
	if not stats then
		return
	end

	techniqueName = tostring(techniqueName or "Cursed Energy Discharge")
	techniqueType = tostring(techniqueType or "Normal")

	local usableNow = forceUsable == true or shouldTechniqueBeUsableNow(stats)

	stats.TechniqueMastery = math.clamp(tonumber(stats.TechniqueMastery) or 0, 0, 100)

	if techniqueType == "Innate" then
		stats.InnateTechnique = techniqueName
		stats.TechniqueType = "Innate"
		stats.TechniqueKnown = true

		if usableNow then
			stats.CursedTechnique = techniqueName
			stats.TechniqueUsable = true
			stats.TechniqueAwakened = true
			stats.InnateDormant = false
			stats.TechniqueMastery = math.max(stats.TechniqueMastery, math.random(2, 8))
		else
			stats.CursedTechnique = "None"
			stats.TechniqueUsable = false
			stats.TechniqueAwakened = false
			stats.InnateDormant = true
			stats.TechniqueMastery = 0
		end
	else
		stats.CursedTechnique = techniqueName
		stats.InnateTechnique = "None"
		stats.TechniqueType = "Normal"
		stats.TechniqueKnown = true
		stats.TechniqueUsable = true
		stats.TechniqueAwakened = true
		stats.InnateDormant = false
		stats.TechniqueMastery = math.max(stats.TechniqueMastery, math.random(1, 8))
	end

	if tostring(stats.Grade or "Non-Sorcerer") == "Non-Sorcerer" and usableNow then
		stats.Grade = "Grade 4"
	end
end

local function applyOriginToStats(stats, originData)
	if not stats or typeof(originData) ~= "table" then
		return nil
	end

	local oldFirstName = tostring(stats.FirstName or "")
	local oldGender = stats.Gender == "Female" and "Female" or "Male"

	local identity = nil
	if BitKaisenStats.GenerateRandomIdentity then
		identity = BitKaisenStats.GenerateRandomIdentity(originData, oldGender)
	end

	if typeof(identity) ~= "table" then
		identity = {
			FirstName = oldFirstName ~= "" and oldFirstName or "Unknown",
			FamilyName = originData.FamilyName or "Unknown",
			FamilyType = originData.FamilyType or "Unknown",
		}
	end

	local firstName = oldFirstName
	if firstName == "" or firstName == "Unknown" then
		firstName = tostring(identity.FirstName or "Unknown")
	end

	local familyName = tostring(identity.FamilyName or originData.FamilyName or "Unknown")
	local familyType = tostring(identity.FamilyType or originData.FamilyType or "Unknown")
	local displayName = tostring(originData.DisplayName or "Unknown Family")

	stats.FirstName = firstName
	stats.FamilyName = familyName
	stats.FamilyType = familyType
	stats.Gender = oldGender

	if familyName ~= "None" and familyName ~= "Unknown" then
		stats.Name = firstName .. " " .. familyName
	else
		stats.Name = firstName
	end

	stats.Clan = displayName
	stats.Origin = displayName
	stats.OriginCategory = tostring(originData.Category or "Family")

	if originData.Category == "Race" then
		stats.Race = displayName
	elseif tostring(stats.Race or "") == "Cursed Spirit" or tostring(stats.Race or "") == "Curse" then
		stats.Race = stats.Race
	else
		stats.Race = stats.Race or "Human"
	end

	local bonusCE = tonumber(originData.BonusCE) or 0
	local bonusSmarts = tonumber(originData.BonusSmarts) or 0

	stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + math.floor(bonusCE * 0.35))
	stats.Smarts = math.clamp((tonumber(stats.Smarts) or 0) + math.floor(bonusSmarts * 0.35), 0, 100)

	return {
		DisplayName = displayName,
		FamilyName = familyName,
		FamilyType = familyType,
		OriginCategory = tostring(originData.Category or "Family"),
	}
end

local function rollTraitsForStats(stats, guaranteedCount)
	if not stats then
		return {}
	end

	local oldTraitCount = 0
	if type(stats.Traits) == "table" then
		oldTraitCount = #stats.Traits
	end

	local count = tonumber(guaranteedCount) or oldTraitCount
	if count <= 0 then
		if BitKaisenTraits.RollTraitCount then
			count = BitKaisenTraits.RollTraitCount(stats)
		else
			count = 2
		end
	end

	count = math.clamp(count, 1, 4)

	local rolled = {}
	if BitKaisenTraits.RollTraits then
		rolled = BitKaisenTraits.RollTraits(stats, count)
	elseif BitKaisenTraits.RollBirthTraits then
		rolled = BitKaisenTraits.RollBirthTraits(stats)
	else
		rolled = {}
	end

	stats.Traits = rolled
	stats.TraitsRolled = true

	if BitKaisenTraits.EnsureTraits then
		BitKaisenTraits.EnsureTraits(stats)
	end

	return rolled
end

local function getTraitSummary(stats)
	if not stats then
		return "None"
	end

	if BitKaisenTraits.GetTraitDisplay then
		local display = BitKaisenTraits.GetTraitDisplay(stats)
		if display and tostring(display) ~= "" then
			return tostring(display)
		end
	end

	if type(stats.Traits) ~= "table" or #stats.Traits <= 0 then
		return "None"
	end

	return table.concat(stats.Traits, ", ")
end

local function addTimedBoost(stats, boostKey, durationSeconds, multiplier)
	if not stats then
		return 0
	end

	durationSeconds = math.max(1, tonumber(durationSeconds) or 900)
	multiplier = math.max(1, tonumber(multiplier) or 2)

	stats.PremiumBoosts = stats.PremiumBoosts or {}

	local now = getCurrentUnixTime()
	local currentUntil = tonumber(stats.PremiumBoosts[boostKey .. "Until"]) or 0
	local startFrom = math.max(now, currentUntil)
	local newUntil = startFrom + durationSeconds

	stats.PremiumBoosts[boostKey .. "Until"] = newUntil
	stats.PremiumBoosts[boostKey .. "Multiplier"] = multiplier

	stats[boostKey .. "BoostUntil"] = newUntil
	stats[boostKey .. "BoostMultiplier"] = multiplier

	return newUntil
end

local function getRemainingBoostSeconds(stats, boostKey)
	if not stats then
		return 0
	end

	local now = getCurrentUnixTime()
	local premiumBoosts = stats.PremiumBoosts or {}
	local untilTime = tonumber(premiumBoosts[boostKey .. "Until"]) or tonumber(stats[boostKey .. "BoostUntil"]) or 0

	return math.max(0, untilTime - now)
end

----------------------------------------------------------------
-- EXISTING GRANTS
----------------------------------------------------------------
local function getTrainingRewardByGrade(stats)
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
		["Special Grade"] = { CE = 110, Mastery = 10, Reputation = 7 },
	}

	return rewardsByGrade[grade] or { CE = 30, Mastery = 3, Reputation = 1 }
end

local function grantStarterSorcererPack(player, stats)
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

local function grantFocusedTraining(player, stats)
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

local function grantMoneyPack(player, stats, amount)
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

local function grantRecruitReroll(player, stats)
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

local function grantRecommendationLetter(player, stats)
	ensureExtraStats(stats)

	stats.TeacherRecommendations = (tonumber(stats.TeacherRecommendations) or 0) + 1
	stats.Recommendations = math.max(tonumber(stats.Recommendations) or 0, tonumber(stats.TeacherRecommendations) or 0)
	stats.RecommendationProgress = (tonumber(stats.RecommendationProgress) or 0) + 1

	fireMajorPopup(
		player,
		"RECOMMENDATION LETTER",
		"A formal recommendation was added to your promotion record.",
		"+1 Recommendation",
		"Use recommendations to push toward higher sorcerer grades."
	)

	fireLifeUpdate(player, stats, "<font color='#ffcd69'><b>[ PURCHASE ]</b></font> +1 Teacher Recommendation added to your record.")
end

local function grantEmergencyTreatment(player, stats)
	ensureExtraStats(stats)

	if stats.Alive == false then
		stats.EmergencyTreatmentTokens = (tonumber(stats.EmergencyTreatmentTokens) or 0) + 1
		fireMajorPopup(
			player,
			"TREATMENT SAVED",
			"This life is already over, so the treatment was saved as a token.",
			"+1 Treatment Token",
			"Use it on a living life later when treatment support is expanded."
		)
		fireLifeUpdate(player, stats, "<font color='#78f0a0'><b>[ PURCHASE ]</b></font> Emergency Treatment saved because this life is already over.")
		return
	end

	local oldHealth = tonumber(stats.Health) or 0
	stats.Health = 100
	stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) + 8, 0, 100)

	fireMajorPopup(
		player,
		"EMERGENCY TREATMENT",
		"Your body was patched up and stabilized.",
		"Health Restored",
		"Health: " .. tostring(oldHealth) .. " -> 100"
	)

	fireLifeUpdate(player, stats, "<font color='#78f0a0'><b>[ PURCHASE ]</b></font> Emergency Treatment restored your Health to <b>100</b>.")
end

----------------------------------------------------------------
-- UPDATE 5 GRANTS
----------------------------------------------------------------
local function grantCursedTechniqueReroll(player, stats, silent)
	ensureExtraStats(stats)

	local oldTechnique = getTechniqueName(stats)
	local newTechnique, techniqueType = rollTechniqueForCurrentOrigin(stats)

	if not newTechnique or tostring(newTechnique) == "None" then
		newTechnique = rollOpenTechnique(stats)
		techniqueType = "Normal"
	end

	applyTechniqueToStats(stats, newTechnique, techniqueType, true)

	stats.Purchases = stats.Purchases or {}
	stats.Purchases.CursedTechniqueRerolls = (tonumber(stats.Purchases.CursedTechniqueRerolls) or 0) + 1

	if not silent then
		fireMajorPopup(
			player,
			"TECHNIQUE REROLLED",
			"Your cursed technique changed.",
			tostring(oldTechnique) .. " -> " .. tostring(newTechnique),
			"Type: " .. tostring(techniqueType)
		)

		fireLifeUpdate(
			player,
			stats,
			"<font color='#b27aff'><b>[ REROLL ]</b></font> Cursed Technique rerolled.\n"
				.. "<b>Old:</b> " .. tostring(oldTechnique)
				.. "\n<b>New:</b> " .. tostring(newTechnique)
				.. "\n<b>Type:</b> " .. tostring(techniqueType)
		)
	end

	return newTechnique, techniqueType, oldTechnique
end

local function grantClanReroll(player, stats, silent)
	ensureExtraStats(stats)

	local oldOrigin = tostring(stats.Origin or stats.Clan or "Unknown")
	local oldFamilyName = tostring(stats.FamilyName or "Unknown")

	if isCursedSpiritLife(stats) then
		stats.ClanRerollTokens = (tonumber(stats.ClanRerollTokens) or 0) + 1

		if not silent then
			fireMajorPopup(
				player,
				"CLAN REROLL SAVED",
				"Cursed Spirits cannot reroll into human clans.",
				"+1 Clan Reroll Token",
				"Use this on a human life instead."
			)

			fireLifeUpdate(player, stats, "<font color='#ffcd69'><b>[ REROLL ]</b></font> Clan Reroll saved as a token because Cursed Spirit lives cannot reroll human clan origins.")
		end

		return tostring(stats.Origin or stats.Clan or "Cursed Spirit"), tostring(stats.FamilyName or "None"), oldOrigin, oldFamilyName
	end

	local originData = rollPaidHumanOrigin()
	local applied = applyOriginToStats(stats, originData)

	local newOrigin = applied and applied.DisplayName or tostring(stats.Origin or stats.Clan or "Unknown")
	local newFamilyName = applied and applied.FamilyName or tostring(stats.FamilyName or "Unknown")

	local newInnate = BitKaisenStats.RollInnateTechniqueForOrigin(originData)
	if newInnate and tostring(newInnate) ~= "None" then
		applyTechniqueToStats(stats, newInnate, "Innate", shouldTechniqueBeUsableNow(stats))
	else
		stats.InnateTechnique = "None"
		if tostring(stats.CursedTechnique or "None") == "None" then
			applyTechniqueToStats(stats, rollOpenTechnique(stats), "Normal", shouldTechniqueBeUsableNow(stats))
		end
	end

	stats.Purchases = stats.Purchases or {}
	stats.Purchases.ClanRerolls = (tonumber(stats.Purchases.ClanRerolls) or 0) + 1

	if not silent then
		fireMajorPopup(
			player,
			"CLAN REROLLED",
			"Your birth origin shifted.",
			tostring(oldOrigin) .. " -> " .. tostring(newOrigin),
			"Family: " .. tostring(oldFamilyName) .. " -> " .. tostring(newFamilyName)
		)

		local message = "<font color='#ffcd69'><b>[ REROLL ]</b></font> Clan / Origin rerolled."
		message = message .. "\n<b>Old Origin:</b> " .. tostring(oldOrigin)
		message = message .. "\n<b>New Origin:</b> " .. tostring(newOrigin)
		message = message .. "\n<b>Family Name:</b> " .. tostring(newFamilyName)

		local currentTechnique = getTechniqueName(stats)
		if currentTechnique ~= "None" then
			message = message .. "\n<b>Technique:</b> " .. tostring(currentTechnique)
		end

		fireLifeUpdate(player, stats, message)
	end

	return newOrigin, newFamilyName, oldOrigin, oldFamilyName
end

local function grantTraitReroll(player, stats, silent)
	ensureExtraStats(stats)

	if BitKaisenTraits.EnsureTraits then
		BitKaisenTraits.EnsureTraits(stats)
	end

	local oldTraits = getTraitSummary(stats)
	local oldCount = 0

	if type(stats.Traits) == "table" then
		oldCount = #stats.Traits
	end

	local newTraits = rollTraitsForStats(stats, math.max(1, oldCount))
	local newTraitSummary = getTraitSummary(stats)

	stats.Purchases = stats.Purchases or {}
	stats.Purchases.TraitRerolls = (tonumber(stats.Purchases.TraitRerolls) or 0) + 1

	if not silent then
		fireMajorPopup(
			player,
			"TRAITS REROLLED",
			"Your life traits changed.",
			newTraitSummary,
			"Traits influence growth, risk, relationships, and progression."
		)

		fireLifeUpdate(
			player,
			stats,
			"<font color='#b27aff'><b>[ REROLL ]</b></font> Traits rerolled."
				.. "\n<b>Old:</b> " .. tostring(oldTraits)
				.. "\n<b>New:</b> " .. tostring(newTraitSummary)
		)
	end

	return newTraits, oldTraits, newTraitSummary
end

local function grantFullPowerReroll(player, stats)
	ensureExtraStats(stats)

	local oldOrigin = tostring(stats.Origin or stats.Clan or "Unknown")
	local oldTechnique = getTechniqueName(stats)
	local oldTraits = getTraitSummary(stats)

	local newOrigin = nil
	local newTechnique = nil
	local newTechniqueType = nil
	local newTraitsSummary = nil

	if isCursedSpiritLife(stats) then
		stats.ClanRerollTokens = (tonumber(stats.ClanRerollTokens) or 0) + 1
		newOrigin = tostring(stats.Origin or stats.Clan or "Cursed Spirit")
	else
		newOrigin = grantClanReroll(player, stats, true)
	end

	newTechnique, newTechniqueType = grantCursedTechniqueReroll(player, stats, true)
	_, _, newTraitsSummary = grantTraitReroll(player, stats, true)

	stats.Purchases = stats.Purchases or {}
	stats.Purchases.FullPowerRerolls = (tonumber(stats.Purchases.FullPowerRerolls) or 0) + 1

	if isCursedSpiritLife(stats) then
		fireMajorPopup(
			player,
			"FULL REROLL COMPLETE",
			"Your cursed technique and traits were rerolled. Clan reroll was saved because this is a Cursed Spirit life.",
			tostring(newTechnique),
			"+1 Clan Reroll Token"
		)
	else
		fireMajorPopup(
			player,
			"FULL REROLL COMPLETE",
			"Your clan, cursed technique, and traits were rerolled.",
			tostring(newOrigin) .. " | " .. tostring(newTechnique),
			"Traits: " .. tostring(newTraitsSummary)
		)
	end

	local message = "<font color='#ffcd69'><b>[ FULL REROLL ]</b></font> Full power reroll completed."
	message = message .. "\n<b>Old Origin:</b> " .. tostring(oldOrigin)
	message = message .. "\n<b>New Origin:</b> " .. tostring(stats.Origin or stats.Clan or "Unknown")

	if isCursedSpiritLife(stats) then
		message = message .. "\n<b>Clan Reroll:</b> Saved as +1 token because Cursed Spirits cannot reroll into human clans."
	end

	message = message .. "\n<b>Old Technique:</b> " .. tostring(oldTechnique)
	message = message .. "\n<b>New Technique:</b> " .. tostring(newTechnique) .. " (" .. tostring(newTechniqueType) .. ")"
	message = message .. "\n<b>Old Traits:</b> " .. tostring(oldTraits)
	message = message .. "\n<b>New Traits:</b> " .. tostring(newTraitsSummary)

	fireLifeUpdate(player, stats, message)
end

local function grantMasteryBoost15(player, stats, silent)
	ensureExtraStats(stats)

	local durationSeconds = 15 * 60
	local newUntil = addTimedBoost(stats, "Mastery", durationSeconds, 2)

	local immediateMasteryGain = 8
	if ownsDoubleTrainingPass(player) then
		immediateMasteryGain *= 2
	end

	local hadTechnique = tostring(stats.CursedTechnique or "None") ~= "None"
	if hadTechnique then
		stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + immediateMasteryGain, 0, 100)
	else
		immediateMasteryGain = 0
	end

	stats.Purchases = stats.Purchases or {}
	stats.Purchases.MasteryBoosts = (tonumber(stats.Purchases.MasteryBoosts) or 0) + 1

	if not silent then
		fireMajorPopup(
			player,
			"MASTERY BOOST ACTIVE",
			"Your mastery boost is active for 15 minutes.",
			"2x Mastery",
			immediateMasteryGain > 0 and ("Immediate +" .. tostring(immediateMasteryGain) .. " Technique Mastery") or "Awaken a technique to benefit from mastery gains."
		)

		local message = "<font color='#78beff'><b>[ BOOST ]</b></font> 2x Mastery Boost active for <b>15 minutes</b>."
		if immediateMasteryGain > 0 then
			message = message .. "\n+" .. tostring(immediateMasteryGain) .. " Technique Mastery added instantly."
		end
		message = message .. "\nBoost expires at Unix time: " .. tostring(newUntil)

		fireLifeUpdate(player, stats, message)
	end

	return newUntil
end

local function grantCEBoost15(player, stats, silent)
	ensureExtraStats(stats)

	local durationSeconds = 15 * 60
	local newUntil = addTimedBoost(stats, "CE", durationSeconds, 2)

	local immediateCEGain = 75
	if ownsDoubleTrainingPass(player) then
		immediateCEGain *= 2
	end

	stats.CursedEnergy = (tonumber(stats.CursedEnergy) or 0) + immediateCEGain

	stats.Purchases = stats.Purchases or {}
	stats.Purchases.CEBoosts = (tonumber(stats.Purchases.CEBoosts) or 0) + 1
	stats.CEAddiction = math.clamp((tonumber(stats.CEAddiction) or 0) + 12, 0, 100)

	if not silent then
		fireMajorPopup(
			player,
			"CE BOOST ACTIVE",
			"Your cursed energy boost is active for 15 minutes.",
			"2x CE Growth",
			"Immediate +" .. tostring(immediateCEGain) .. " Cursed Energy"
		)

		local message = "<font color='#78beff'><b>[ BOOST ]</b></font> 2x Cursed Energy Boost active for <b>15 minutes</b>."
		message = message .. "\n+" .. tostring(immediateCEGain) .. " Cursed Energy added instantly."
		message = message .. "\nBoost expires at Unix time: " .. tostring(newUntil)

		fireLifeUpdate(player, stats, message)
	end

	return newUntil
end

local function grantDojoFundingPack(player, stats)
	ensureExtraStats(stats)

	local moneyGain = 25000
	local reputationGain = 25
	local conditionGain = 25
	local hasGrandDojo = stats.ClanFounded == true and ownsAssetById(stats, "grand_dojo")

	if ownsDoubleMoneyPass(player) then
		moneyGain *= 2
	end

	stats.Money = (tonumber(stats.Money) or 0) + moneyGain
	stats.RecruitRerollTokens = (tonumber(stats.RecruitRerollTokens) or 0) + 1

	if hasGrandDojo then
		stats.DojoReputation = math.max(0, (tonumber(stats.DojoReputation) or tonumber(stats.ClanReputation) or 0) + reputationGain)
		stats.ClanReputation = math.max(tonumber(stats.ClanReputation) or 0, stats.DojoReputation)
		stats.DojoCondition = math.clamp((tonumber(stats.DojoCondition) or 100) + conditionGain, 0, 100)
		stats.DojoCapacityBonus = (tonumber(stats.DojoCapacityBonus) or 0) + 1

		if type(stats.DojoRecruitPool) ~= "table" or #stats.DojoRecruitPool <= 0 then
			generateDojoRecruitPool(stats)
		end
	else
		stats.DojoFundingVouchers = (tonumber(stats.DojoFundingVouchers) or 0) + 1
	end

	stats.Purchases = stats.Purchases or {}
	stats.Purchases.DojoFundingPacks = (tonumber(stats.Purchases.DojoFundingPacks) or 0) + 1

	if hasGrandDojo then
		fireMajorPopup(
			player,
			"DOJO FUNDED",
			"Your clan dojo received new resources and recruitment support.",
			formatMoney(moneyGain) .. " | +" .. tostring(reputationGain) .. " Dojo Rep",
			"+1 Recruit Reroll | +1 Student Capacity"
		)

		fireLifeUpdate(player, stats, "<font color='#ffcd69'><b>[ DOJO FUNDING ]</b></font> Dojo Funding Pack redeemed.\n+" .. formatMoney(moneyGain) .. " Money\n+" .. tostring(reputationGain) .. " Dojo Reputation\n+" .. tostring(conditionGain) .. "% Dojo Condition\n+1 Recruit Reroll\n+1 Student Capacity")
	else
		fireMajorPopup(
			player,
			"DOJO FUNDING SAVED",
			"You do not own a clan Grand Dojo yet, so the funding support was saved.",
			formatMoney(moneyGain) .. " | +1 Voucher",
			"Buy or found a Grand Dojo to use the support later."
		)

		fireLifeUpdate(player, stats, "<font color='#ffcd69'><b>[ DOJO FUNDING ]</b></font> Dojo Funding Pack redeemed.\n+" .. formatMoney(moneyGain) .. " Money\n+1 Recruit Reroll\n+1 Dojo Funding Voucher saved until you own a clan Grand Dojo.")
	end
end

local function grantCTEvolutionAccelerator(player, stats)
	ensureExtraStats(stats)

	if tostring(stats.CursedTechnique or "None") == "None" then
		stats.CTEvolutionAcceleratorTokens = (tonumber(stats.CTEvolutionAcceleratorTokens) or 0) + 1
		fireLifeUpdate(player, stats, "<font color='#b27aff'><b>[ CT ACCELERATOR ]</b></font> No awakened cursed technique was found, so the accelerator was saved as a token for this life.")
		return
	end

	local masteryGain = 10
	if ownsDoubleTrainingPass(player) then
		masteryGain *= 2
	end

	stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + masteryGain, 0, 100)
	local pressureMessage = BitKaisenTechniqueEvolution.AddPressure(stats, 25, "CT Evolution Accelerator")
	stats.Purchases = stats.Purchases or {}
	stats.Purchases.CTEvolutionAccelerators = (tonumber(stats.Purchases.CTEvolutionAccelerators) or 0) + 1

	fireMajorPopup(player, "CT ACCELERATOR", "Your cursed technique was pushed through focused pressure.", "+25 Evolution", "+" .. tostring(masteryGain) .. " Mastery")
	fireLifeUpdate(player, stats, "<font color='#b27aff'><b>[ CT ACCELERATOR ]</b></font> Technique Mastery <b>+" .. tostring(masteryGain) .. "%</b>." .. pressureMessage)
end

local function grantBlackFlashDrillPack(player, stats)
	ensureExtraStats(stats)

	local tokenGain = 3
	local ceGain = 40
	local masteryGain = tostring(stats.CursedTechnique or "None") ~= "None" and 4 or 0
	if ownsDoubleTrainingPass(player) then
		ceGain *= 2
		masteryGain *= 2
	end

	stats.BlackFlashDrillTokens = (tonumber(stats.BlackFlashDrillTokens) or 0) + tokenGain
	stats.CursedEnergy = (tonumber(stats.CursedEnergy) or 0) + ceGain
	stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + masteryGain, 0, 100)
	stats.Purchases = stats.Purchases or {}
	stats.Purchases.BlackFlashDrillPacks = (tonumber(stats.Purchases.BlackFlashDrillPacks) or 0) + 1

	local pressureMessage = masteryGain > 0 and BitKaisenTechniqueEvolution.AddPressure(stats, 6, "Black Flash Drill Pack") or ""
	fireMajorPopup(player, "BLACK FLASH DRILLS", "Extra Black Flash training support was added.", "+3 Drill Tokens", "+" .. tostring(ceGain) .. " CE")
	fireLifeUpdate(player, stats, "<font color='#b27aff'><b>[ BLACK FLASH DRILLS ]</b></font> +" .. tostring(tokenGain) .. " drill tokens, CE <b>+" .. tostring(ceGain) .. "</b>" .. (masteryGain > 0 and (", Mastery <b>+" .. tostring(masteryGain) .. "%</b>") or "") .. "." .. pressureMessage)
end

local function grantEliteSorcererPack(player, stats)
	ensureExtraStats(stats)

	local moneyGain = 50000
	local ceGain = 125
	local masteryGain = 15

	if ownsDoubleMoneyPass(player) then
		moneyGain *= 2
	end

	if ownsDoubleTrainingPass(player) then
		ceGain *= 2
		masteryGain *= 2
	end

	stats.Money = (tonumber(stats.Money) or 0) + moneyGain
	stats.CursedEnergy = (tonumber(stats.CursedEnergy) or 0) + ceGain

	local oldOrigin = tostring(stats.Origin or stats.Clan or "Unknown")
	local oldTechnique = getTechniqueName(stats)
	local oldTraits = getTraitSummary(stats)

	local newOrigin = nil
	local newTechnique = nil
	local newTechniqueType = nil
	local newTraitsSummary = nil

	if isCursedSpiritLife(stats) then
		stats.ClanRerollTokens = (tonumber(stats.ClanRerollTokens) or 0) + 1
		newOrigin = tostring(stats.Origin or stats.Clan or "Cursed Spirit")
	else
		newOrigin = grantClanReroll(player, stats, true)
	end

	newTechnique, newTechniqueType = grantCursedTechniqueReroll(player, stats, true)
	_, _, newTraitsSummary = grantTraitReroll(player, stats, true)

	if tostring(stats.CursedTechnique or "None") ~= "None" then
		stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + masteryGain, 0, 100)
	else
		masteryGain = 0
	end

	stats.TeacherRecommendations = (tonumber(stats.TeacherRecommendations) or 0) + 2
	stats.Recommendations = math.max(tonumber(stats.Recommendations) or 0, tonumber(stats.TeacherRecommendations) or 0)
	stats.RecommendationProgress = (tonumber(stats.RecommendationProgress) or 0) + 2

	grantMasteryBoost15(player, stats, true)
	grantCEBoost15(player, stats, true)

	stats.Purchases = stats.Purchases or {}
	stats.Purchases.EliteSorcererPacks = (tonumber(stats.Purchases.EliteSorcererPacks) or 0) + 1

	if isCursedSpiritLife(stats) then
		fireMajorPopup(
			player,
			"ELITE SORCERER PACK",
			"Your elite pack rewards were applied. Clan reroll was saved because this is a Cursed Spirit life.",
			formatMoney(moneyGain) .. " | +" .. tostring(ceGain) .. " CE",
			"+1 Clan Reroll Token"
		)
	else
		fireMajorPopup(
			player,
			"ELITE SORCERER PACK",
			"Your elite pack rewards were applied.",
			formatMoney(moneyGain) .. " | +" .. tostring(ceGain) .. " CE",
			"Rerolled clan, technique, and traits."
		)
	end

	local message = "<font color='#ffcd69'><b>[ ELITE PACK ]</b></font> Elite Sorcerer Pack redeemed."
	message = message .. "\n+" .. formatMoney(moneyGain) .. " Money"
	message = message .. "\n+" .. tostring(ceGain) .. " Cursed Energy"
	message = message .. "\n+2 Teacher Recommendations"

	if masteryGain > 0 then
		message = message .. "\n+" .. tostring(masteryGain) .. " Technique Mastery"
	end

	message = message .. "\n<b>Old Origin:</b> " .. tostring(oldOrigin)
	message = message .. "\n<b>New Origin:</b> " .. tostring(newOrigin or stats.Origin or stats.Clan or "Unknown")

	if isCursedSpiritLife(stats) then
		message = message .. "\n<b>Clan Reroll:</b> Saved as +1 token because Cursed Spirits cannot reroll into human clans."
	end

	message = message .. "\n<b>Old Technique:</b> " .. tostring(oldTechnique)
	message = message .. "\n<b>New Technique:</b> " .. tostring(newTechnique) .. " (" .. tostring(newTechniqueType) .. ")"
	message = message .. "\n<b>Old Traits:</b> " .. tostring(oldTraits)
	message = message .. "\n<b>New Traits:</b> " .. tostring(newTraitsSummary)
	message = message .. "\n2x Mastery Boost active for 15 minutes."
	message = message .. "\n2x CE Boost active for 15 minutes."

	fireLifeUpdate(player, stats, message)
end

----------------------------------------------------------------
-- MAIN PRODUCT DISPATCH
----------------------------------------------------------------

local function isOldAgeDeath(stats)
	if not stats then
		return false
	end

	local cause = string.lower(tostring(stats.CauseOfDeath or ""))

	return string.find(cause, "old age") ~= nil
		or string.find(cause, "final year") ~= nil
		or string.find(cause, "age") ~= nil and tonumber(stats.Age) and tonumber(stats.Age) >= 80
end

local function grantRCTRevive(player, stats)
	if not player or not stats then
		return false
	end

	ensureExtraStats(stats)

	local currentRCTRevives = math.max(0, tonumber(stats.RCTRevives) or 0)
	if currentRCTRevives >= RCT_REVIVE_MAX_PER_LIFE then
		fireMajorPopup(
			player,
			"RCT REVIVE",
			"Your body has already survived through RCT twice in this life.",
			"Limit reached",
			"RCT Revive can only be used twice per life."
		)
		fireLifeUpdate(player, stats, "<font color='#a782ff'><b>[ RCT REVIVE ]</b></font> Your body has already endured two RCT revivals in this life. You cannot force another revival.")
		return true
	end

	if stats.Alive ~= false then
		fireMajorPopup(
			player,
			"RCT REVIVE",
			"Your life is not currently at death's edge.",
			"No death detected",
			"RCT Revive is meant to be used from the death screen."
		)
		fireLifeUpdate(player, stats, "<font color='#a782ff'><b>[ RCT REVIVE ]</b></font> No death state was detected, so your life continued unchanged.")
		return true
	end

	local oldCause = tostring(stats.CauseOfDeath or "Unknown")
	local oldAgeDeath = isOldAgeDeath(stats)

	stats.Alive = true
	stats.CauseOfDeath = nil
	stats.LastCauseOfDeath = oldCause
	stats.RCTRevives = currentRCTRevives + 1
	stats.LastRCTReviveAt = getCurrentUnixTime()

	local message = ""

	if oldAgeDeath then
		local extraYears = math.random(10, 75)

		stats.RCTOldAgeYearsRemaining = math.max(0, tonumber(stats.RCTOldAgeYearsRemaining) or 0) + extraYears
		stats.LastRCTOldAgeExtensionYears = extraYears
		stats.Health = math.max(tonumber(stats.Health) or 0, 45)
		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) + 5, 0, 100)
		stats.CursedEnergy = (tonumber(stats.CursedEnergy) or 0) + 5

		message =
			"<font color='#a782ff'><b>[ RCT REVIVE ]</b></font> " ..
			"At the edge of old age, reversed cursed energy surged through your failing body. " ..
			"Your lifespan was extended by <b>" .. tostring(extraYears) .. "</b> years. " ..
			"You woke up breathing again, but your body still remembers how close it came."

		fireMajorPopup(
			player,
			"RCT REVIVE",
			"Reversed cursed energy forced your aging body to stabilize.",
			"+" .. tostring(extraYears) .. " years",
			"Health restored to 45. Your life continues."
		)
	else
		stats.Health = math.max(tonumber(stats.Health) or 0, 35)
		stats.CursedEnergy = (tonumber(stats.CursedEnergy) or 0) + 10
		stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + 2, 0, 100)
		stats.Reputation = (tonumber(stats.Reputation) or 0) + 3
		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - 5, 0, 100)
		stats.RCTSecondChances = math.max(0, tonumber(stats.RCTSecondChances) or 0) + 1

		message =
			"<font color='#a782ff'><b>[ RCT REVIVE ]</b></font> " ..
			"At the boundary of death, you forced reversed cursed energy through your body. " ..
			"You survived, barely, and your cursed energy sharpened from the experience. " ..
			"Health restored to <b>35</b>. CE <b>+10</b>, Mastery <b>+2</b>, Reputation <b>+3</b>."

		fireMajorPopup(
			player,
			"RCT REVIVE",
			"You forced reversed cursed energy through your body at death's edge.",
			"Second Chance",
			"Health restored to 35. CE +10, Mastery +2, Reputation +3."
		)
	end

	fireLifeUpdate(player, stats, message)
	return true
end


local function grantAFKStabilization(player, stats)
	ensureExtraStats(stats)
	stats.AFKStabilizationUnlocked = true
	stats.AFKStabilizationSessions = math.max(0, tonumber(stats.AFKStabilizationSessions) or 0)
	stats.AFKStabilizationEarned = math.max(0, tonumber(stats.AFKStabilizationEarned) or 0)
	fireMajorPopup(player, "AFK STABILIZATION", "Your idle stabilization channel is now unlocked.", "+$0.20/sec", "Use the AFK button to begin earning while idle.")
	fireLifeUpdate(player, stats, "<font color='#7ee787'><b>[ AFK STABILIZATION ]</b></font> Purchased. You can now activate AFK Stabilization to earn <b>$0.20/sec</b> while idle.")
end

local function grantClanWarMediation(player, stats)
	ensureExtraStats(stats)
	local war = typeof(stats.ClanWarState) == "table" and stats.ClanWarState or {}
	stats.ClanWarState = war
	stats.Purchases = stats.Purchases or {}
	stats.Purchases.ClanWarMediations = (tonumber(stats.Purchases.ClanWarMediations) or 0) + 1

	if war.Active == true then
		local oldTension = math.clamp(tonumber(war.Tension) or 0, 0, 100)
		local newTension = math.clamp(oldTension - 25, 0, 100)
		war.Tension = newTension
		war.Phase = newTension >= 75 and "Open War" or (newTension >= 40 and "Escalating" or "Truce Talks")
		war.Description = "Mediation bought your clan time against the " .. tostring(war.RivalClanName or "rival") .. " Clan. Tension: " .. tostring(newTension) .. "%"
		stats.ClanWarCooldown = 0
		stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) + 2)
		if typeof(stats.ClanWarHistory) ~= "table" then stats.ClanWarHistory = {} end
		table.insert(stats.ClanWarHistory, {
			Year = tonumber(stats.Year) or (2000 + (tonumber(stats.Age) or 0)),
			Age = tonumber(stats.Age) or 0,
			Text = "A paid mediator lowered tension with the " .. tostring(war.RivalClanName or "rival") .. " Clan.",
			Result = "Mediation",
		})
		fireMajorPopup(player, "CLAN WAR MEDIATION", "A mediator bought your clan breathing room.", "Tension -" .. tostring(oldTension - newTension), "+2 Clan Reputation")
		fireLifeUpdate(player, stats, "<font color='#ffcf57'><b>[ CLAN WAR MEDIATION ]</b></font> Tension reduced from <b>" .. tostring(oldTension) .. "%</b> to <b>" .. tostring(newTension) .. "%</b>. Clan Reputation <b>+2</b>.")
	else
		stats.ClanWarMediationCredits = (tonumber(stats.ClanWarMediationCredits) or 0) + 1
		fireMajorPopup(player, "MEDIATION CREDIT SAVED", "No active Clan War was found, so this mediation was saved.", "+1 Credit", "Use it during a future Clan War.")
		fireLifeUpdate(player, stats, "<font color='#ffcf57'><b>[ CLAN WAR MEDIATION ]</b></font> No active Clan War. Saved <b>+1 mediation credit</b> for this life.")
	end
end

local function grantCursedToolSalvageKit(player, stats)
	ensureExtraStats(stats)
	local tool = BitKaisenCursedTools.RollDrop(4)
	if not tool then return end
	local _, added = BitKaisenCursedTools.AddTool(stats, tool.Id, "Cursed Tool Salvage Kit", tonumber(stats.Year) or os.date("!*t").year)
	stats.Purchases = stats.Purchases or {}
	stats.Purchases.CursedToolSalvageKits = (tonumber(stats.Purchases.CursedToolSalvageKits) or 0) + 1

	if added then
		fireMajorPopup(player, "SALVAGE KIT", "You recovered a cursed tool from sealed scrap.", tostring(tool.Name), tostring(tool.Rarity))
		fireLifeUpdate(player, stats, "<font color='#f0b955'><b>[ SALVAGE KIT ]</b></font> Recovered <b>" .. tostring(tool.Name) .. "</b> (" .. tostring(tool.Rarity) .. ").")
	else
		local reward = BitKaisenCursedTools.GetDuplicateReward(tool)
		stats.Money = (tonumber(stats.Money) or 0) + reward.Money
		stats.CursedEnergy = (tonumber(stats.CursedEnergy) or 0) + reward.CursedEnergy
		fireMajorPopup(player, "SALVAGE CONVERTED", "You already owned that cursed tool, so it became resources.", "+$" .. tostring(reward.Money), "+" .. tostring(reward.CursedEnergy) .. " CE")
		fireLifeUpdate(player, stats, "<font color='#f0b955'><b>[ SALVAGE KIT ]</b></font> Duplicate <b>" .. tostring(tool.Name) .. "</b> converted into <b>+$" .. tostring(reward.Money) .. "</b> and <b>+" .. tostring(reward.CursedEnergy) .. " CE</b>.")
	end
end

local function grantBountyClear(player, stats)
	ensureExtraStats(stats)
	local oldWanted = tonumber(stats.WantedLevel) or 0
	stats.WantedLevel = 0
	stats.Purchases = stats.Purchases or {}
	stats.Purchases.BountyClears = (tonumber(stats.Purchases.BountyClears) or 0) + 1
	fireMajorPopup(player, "BOUNTY CLEARED", "Your trail went cold. The hunters lost your scent.", "Wanted Level", "0")
	fireLifeUpdate(player, stats, "<font color='#7ee787'><b>[ BOUNTY CLEAR ]</b></font> Your Wanted Level dropped from <b>" .. tostring(math.floor(oldWanted)) .. "</b> to <b>0</b>.")
end

local function grantCombatRecoveryKit(player, stats)
	ensureExtraStats(stats)
	local oldHealth = tonumber(stats.Health) or 100
	local oldCE = tonumber(stats.CursedEnergy) or 0
	stats.Health = math.clamp(oldHealth + 40, 1, 100)
	stats.CursedEnergy = oldCE + 30
	stats.CombatRecoveryKitsUsed = (tonumber(stats.CombatRecoveryKitsUsed) or 0) + 1
	stats.Purchases = stats.Purchases or {}
	stats.Purchases.CombatRecoveryKits = (tonumber(stats.Purchases.CombatRecoveryKits) or 0) + 1
	fireMajorPopup(player, "COMBAT RECOVERY", "You stabilized after recent combat strain.", "Health +" .. tostring(math.floor(stats.Health - oldHealth)), "+30 CE")
	fireLifeUpdate(player, stats, "<font color='#7ee787'><b>[ COMBAT RECOVERY ]</b></font> Health restored by <b>" .. tostring(math.floor(stats.Health - oldHealth)) .. "</b> and Cursed Energy <b>+30</b>.")
end

local function grantGiftedGamePass(player, stats, productInfo, productId)
	local buyerId = player.UserId
	local gift = pendingGifts[buyerId]

	if not gift or gift.expectedProductId ~= productId then
		warn("[BK_CommerceService] Gift receipt with no matching pending gift. buyerId=" .. tostring(buyerId) .. " productId=" .. tostring(productId))
		return true
	end

	local recipientId = gift.recipientId
	local giftLabel = tostring(productInfo.GiftLabel or productInfo.Name or "Gift")
	local senderName = tostring(player and player.Name or "another player")
	local recipientName = gift.recipientName or tostring(recipientId)

	local targetPlayer = Players:GetPlayerByUserId(recipientId)
	if targetPlayer then
		local saveSystem = context.BitKaisenSaveSystem
		if saveSystem and type(saveSystem.GrantGiftedGamePassByUserId) == "function" then
			local grantOk = saveSystem.GrantGiftedGamePassByUserId(recipientId, productInfo.GiftPassKey)
			if grantOk == true then
				local targetStats = getStats(targetPlayer)
				if targetStats then
					targetStats.GiftedGamePasses = typeof(targetStats.GiftedGamePasses) == "table" and targetStats.GiftedGamePasses or {}
					targetStats.GiftedGamePasses[productInfo.GiftPassKey] = true
					if productInfo.GiftPassKey == "GodMode" then
						targetStats.HasGodModePass = true
					elseif productInfo.GiftPassKey == "GoRogue" then
						targetStats.HasGoRoguePass = true
					elseif productInfo.GiftPassKey == "AFKStabilization" then
						targetStats.AFKStabilizationUnlocked = true
					end
					forceSaveStats(targetPlayer, "GiftedGamePass")
					fireMajorPopup(targetPlayer, "GIFT RECEIVED", "A gift was added to your account.", giftLabel, "From: " .. senderName, "Success")
					fireLifeUpdate(targetPlayer, targetStats, "<font color='#63e787'><b>[ GIFT ]</b></font> You received <b>" .. giftLabel .. "</b> from <b>" .. senderName .. "</b>.")
				end
				pendingGifts[buyerId] = nil
				fireMajorPopup(player, "GIFT SENT", "Your gift was delivered to " .. recipientName .. ".", giftLabel, "Recipient: " .. recipientName, "Success")
				fireLifeUpdate(player, stats, "<font color='#ffcd69'><b>[ GIFT ]</b></font> Gifted <b>" .. giftLabel .. "</b> to <b>" .. recipientName .. "</b>.")
				return true
			end
		end
	end

	local mailboxOk, mailboxErr = pcall(function()
		local mailboxKey = "gifts_" .. tostring(recipientId)
		giftMailboxStore:UpdateAsync(mailboxKey, function(old)
			old = if typeof(old) == "table" then old else {}
			table.insert(old, {
				passKey = productInfo.GiftPassKey,
				passLabel = giftLabel,
				fromName = senderName,
				fromId = buyerId,
				timestamp = os.time(),
			})
			return old
		end)
	end)

	if not mailboxOk then
		warn("[BK_CommerceService] Gift mailbox write failed: " .. tostring(mailboxErr))
		return false
	end

	pendingGifts[buyerId] = nil
	fireMajorPopup(player, "GIFT SENT", recipientName .. " will receive this gift when they next log in.", giftLabel, "Recipient: " .. recipientName, "Success")
	fireLifeUpdate(player, stats, "<font color='#ffcd69'><b>[ GIFT ]</b></font> Gifted <b>" .. giftLabel .. "</b> to <b>" .. recipientName .. "</b>. They'll receive it on next login.")
	return true
end

local TIME_SKIP_MAX_AGE = 79 -- natural old age death starts at 80; block skipping into it

local function grantTimeSkip(player, stats, years)
	if not player or not stats then return false end
	ensureExtraStats(stats)

	if stats.Alive == false then
		fireMajorPopup(player, "TIME SKIP", "You cannot skip time while dead.", "No active life", "Start a new life first.")
		return true
	end

	local race = tostring(stats.Race or "")
	local curseType = tostring(stats.CurseType or "")
	local isCurse = stats.IsCurse == true
		or race == "Cursed Spirit" or race == "Curse"
		or curseType ~= "" and curseType ~= "None"
	if isCurse then
		fireMajorPopup(player, "TIME SKIP", "Cursed Spirits are not bound by human time.", "Cannot use on curse life", "Time Skip only works on human lives.")
		return true
	end

	local currentAge = math.floor(tonumber(stats.Age) or 0)
	if currentAge >= TIME_SKIP_MAX_AGE then
		fireMajorPopup(player, "TIME SKIP", "You are already approaching the end of your natural lifespan.", "Too old to skip", "Time Skip cannot be used past age " .. TIME_SKIP_MAX_AGE .. ".")
		return true
	end

	local yearsToSkip = math.min(years, TIME_SKIP_MAX_AGE - currentAge)
	stats.Age = currentAge + yearsToSkip
	stats.TimeSkipsUsed = (tonumber(stats.TimeSkipsUsed) or 0) + 1

	fireMajorPopup(
		player,
		"TIME SKIP",
		"The years blur past like pages in a book.",
		"+" .. yearsToSkip .. " Years",
		"You are now age " .. tostring(stats.Age) .. "."
	)
	fireLifeUpdate(player, stats, "<font color='#b388ff'><b>[ TIME SKIP ]</b></font> <b>+" .. yearsToSkip .. " years</b> — you are now age <b>" .. tostring(stats.Age) .. "</b>.")
	return true
end

local function grantDeveloperProduct(player, productId)
	local stats = getStats(player)

	if not stats then
		return false
	end

	local productInfo = DEVELOPER_PRODUCTS[productId]

	if productInfo and productInfo.TestOnly == true and not isTestPurchasePlace() then
		warn("[BK_CommerceService] Rejected test-only product outside test place: " .. tostring(productId))
		return false
	end

	if not productInfo then
		warn("[BK_CommerceService] Unknown developer product id: " .. tostring(productId))
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

	elseif productInfo.Id == "recommendation_letter" then
		grantRecommendationLetter(player, stats)

	elseif productInfo.Id == "emergency_treatment" then
		grantEmergencyTreatment(player, stats)

	elseif productInfo.Id == "ct_reroll" then
		grantCursedTechniqueReroll(player, stats)

	elseif productInfo.Id == "clan_reroll" then
		grantClanReroll(player, stats)

	elseif productInfo.Id == "trait_reroll" then
		grantTraitReroll(player, stats)

	elseif productInfo.Id == "full_power_reroll" then
		grantFullPowerReroll(player, stats)

	elseif productInfo.Id == "mastery_boost_15" then
		grantMasteryBoost15(player, stats)

	elseif productInfo.Id == "ce_boost_15" then
		grantCEBoost15(player, stats)
	elseif productInfo.Id == "dojo_funding_pack" then
		grantDojoFundingPack(player, stats)

	elseif productInfo.Id == "ct_evolution_accelerator" then
		grantCTEvolutionAccelerator(player, stats)

	elseif productInfo.Id == "black_flash_drill_pack" then
		grantBlackFlashDrillPack(player, stats)

	elseif productInfo.Id == "gift_gamepass" then
		return grantGiftedGamePass(player, stats, productInfo, productId)

	elseif productInfo.Id == "reset_combat_fight" then
		if context.ResetCombatFight then
			context.ResetCombatFight(player, "developer product")
		end

	elseif productInfo.Id == "domain_encore" then
		if context.GrantDomainEncore then
			context.GrantDomainEncore(player)
		end

	elseif productInfo.Id == "afk_stabilization_unlock" then
		grantAFKStabilization(player, stats)

	elseif productInfo.Id == "clan_war_mediation" then
		grantClanWarMediation(player, stats)

	elseif productInfo.Id == "cursed_tool_salvage_kit" then
		grantCursedToolSalvageKit(player, stats)

	elseif productInfo.Id == "combat_recovery_kit" then
		grantCombatRecoveryKit(player, stats)

	elseif productInfo.Id == "bounty_clear" then
		grantBountyClear(player, stats)

	elseif productInfo.Id == "time_skip_5" then
		grantTimeSkip(player, stats, 5)

	elseif productInfo.Id == "time_skip_10" then
		grantTimeSkip(player, stats, 10)

	elseif productInfo.Id == "time_skip_25" then
		grantTimeSkip(player, stats, 25)

	elseif productInfo.Id == "elite_sorcerer_pack" then
		grantEliteSorcererPack(player, stats)

	elseif productInfo.Id == "rct_revive" then
		grantRCTRevive(player, stats)

	else
		warn("[BK_CommerceService] Unhandled developer product id key: " .. tostring(productInfo.Id))
		return false
	end

	forceSaveStats(player, "DeveloperProduct")
	return true
end

function BK_CommerceService.GrantDeveloperProduct(player, productId)
	return grantDeveloperProduct(player, productId)
end

function BK_CommerceService.GetDeveloperProducts()
	return DEVELOPER_PRODUCTS
end

function BK_CommerceService.GetGoRogueProductId()
	return 0
end

function BK_CommerceService.InitiateGift(player, productId, recipientUsername, promptGiftPurchaseRemote)
	if not player then return end
	productId = tonumber(productId) or 0
	if type(recipientUsername) ~= "string" or recipientUsername == "" then return end

	local productInfo = DEVELOPER_PRODUCTS[productId]
	if not productInfo or productInfo.Id ~= "gift_gamepass" then return end
	if productInfo.TestOnly == true and not isTestPurchasePlace() then return end

	local now = os.clock()
	local lastAttempt = giftInitiateCooldowns[player.UserId] or 0
	if now - lastAttempt < GIFT_INITIATE_COOLDOWN_SECONDS then return end
	giftInitiateCooldowns[player.UserId] = now

	local recipientUserId
	local ok, err = pcall(function()
		recipientUserId = Players:GetUserIdFromNameAsync(recipientUsername)
	end)
	if not ok or not recipientUserId then
		fireMajorPopup(player, "GIFT ERROR", "Could not find a Roblox user named '" .. tostring(recipientUsername) .. "'.", "", "", "Error")
		return
	end
	if recipientUserId == player.UserId then
		fireMajorPopup(player, "GIFT ERROR", "You can't gift yourself.", "", "", "Error")
		return
	end

	pendingGifts[player.UserId] = {
		recipientId = recipientUserId,
		recipientName = recipientUsername,
		expectedProductId = productId,
		createdAt = os.clock(),
	}

	promptGiftPurchaseRemote:FireClient(player, productId)
end

function BK_CommerceService.GetResetFightProductId()
	return RESET_FIGHT_PRODUCT_ID
end

function BK_CommerceService.GetDomainEncoreProductId()
	return DOMAIN_ENCORE_PRODUCT_ID
end

function BK_CommerceService.GetAFKStabilizationProductId()
	return AFK_STABILIZATION_PRODUCT_ID
end

function BK_CommerceService.GetRemainingBoostSeconds(player, boostKey)
	local stats = getStats(player)
	return getRemainingBoostSeconds(stats, boostKey)
end

----------------------------------------------------------------
-- INIT
----------------------------------------------------------------
function BK_CommerceService.Init(ctx)
	if not ctx or type(ctx.GetStats) ~= "function" then
		if game:GetService("RunService"):IsStudio() then print("[BK_CommerceService] Waiting for live GameManager context.") end
		return
	end

	if initialized then
		return
	end

	initialized = true
	context = ctx or {}

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local productId = tonumber(receiptInfo.ProductId)

		if not productId or not DEVELOPER_PRODUCTS[productId] then
			warn("[BK_CommerceService] Receipt received for unknown product id: " .. tostring(receiptInfo.ProductId))
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local ok, result = pcall(function()
			return grantDeveloperProduct(player, productId)
		end)

		if ok and result == true then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		warn("[BK_CommerceService] Could not grant product " .. tostring(productId) .. ": " .. tostring(result))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, purchasedPassId, wasPurchased)
		if purchasedPassId ~= VIP_SORCERER_PASS_ID
			and purchasedPassId ~= EXTRA_SAVE_SLOTS_PASS_ID
			and purchasedPassId ~= DOUBLE_MONEY_PASS_ID
			and purchasedPassId ~= DOUBLE_TRAINING_PASS_ID
			and purchasedPassId ~= LUCKY_BIRTH_PASS_ID
			and purchasedPassId ~= EXTRA_DOJO_STUDENTS_PASS_ID
			and purchasedPassId ~= LUCKY_SORCERER_PASS_ID
			and purchasedPassId ~= TRAINING_PRODIGY_PASS_ID
			and purchasedPassId ~= MISSION_INVESTOR_PASS_ID
			and purchasedPassId ~= LEGACY_BLESSING_PASS_ID
			and purchasedPassId ~= DOJO_EXPANSION_PASS_ID
			and purchasedPassId ~= AFK_STABILIZATION_GAMEPASS_ID
			and purchasedPassId ~= GOD_MODE_PASS_ID
			and purchasedPassId ~= GO_ROGUE_PASS_ID
			and purchasedPassId ~= BINDING_VOW_SPECIALIST_PASS_ID then
			return
		end

		clearVIPCache(player)

		local stats = getStats(player)
		if not stats then
			return
		end

		syncMonetizationEntitlements(player, stats)

		if wasPurchased then
			if purchasedPassId == VIP_SORCERER_PASS_ID then
				fireMajorPopup(player, "VIP UNLOCKED", "Your VIP Sorcerer Pass is active.", "VIP Sorcerer", "2x daily login, 1.5x money, 1.5x training, 2x mastery, exclusive title, and extra save slots.")
				fireLifeUpdate(player, stats, "<font color='#ffcd69'><b>[ VIP ]</b></font> VIP Sorcerer Pass active. 2x daily login, 1.5x money, 1.5x training, 2x mastery.")

			elseif purchasedPassId == EXTRA_SAVE_SLOTS_PASS_ID then
				fireMajorPopup(player, "SAVE SLOTS UNLOCKED", "Extra save slots are now unlocked.", "Slots 1-3", "Open Menu > Save Slots to create or load another life.")
				fireLifeUpdate(player, stats, "<font color='#ffcd69'><b>[ SAVE SLOTS ]</b></font> Extra save slots unlocked.")

			elseif purchasedPassId == DOUBLE_MONEY_PASS_ID then
				fireMajorPopup(player, "2X MONEY ACTIVE", "Money product rewards are now doubled.", "2x Money", "Future money purchases will pay out double.")
				fireLifeUpdate(player, stats, "<font color='#78f0a0'><b>[ GAMEPASS ]</b></font> 2x Money active.")

			elseif purchasedPassId == DOUBLE_TRAINING_PASS_ID then
				fireMajorPopup(player, "2X PROGRESS ACTIVE", "Supported progression rewards are now doubled.", "2x Progress", "Future supported training/progression rewards will be stronger.")
				fireLifeUpdate(player, stats, "<font color='#78beff'><b>[ GAMEPASS ]</b></font> 2x Progress active.")

			elseif purchasedPassId == LUCKY_BIRTH_PASS_ID then
				fireMajorPopup(player, "LUCKY BIRTH ACTIVE", "Future new lives will roll improved birth outcomes.", "Lucky Birth", "Start a new life to feel this pass.")
				fireLifeUpdate(player, stats, "<font color='#ffcd69'><b>[ GAMEPASS ]</b></font> Lucky Birth active for future lives.")

			elseif purchasedPassId == EXTRA_DOJO_STUDENTS_PASS_ID then
				fireMajorPopup(player, "DOJO CAPACITY BOOST", "Your Grand Dojo can now hold more students.", "+3 Students", "Open Assets > Dojo to see the new capacity.")
				fireLifeUpdate(player, stats, "<font color='#ffcd69'><b>[ GAMEPASS ]</b></font> Extra Dojo Students active. Capacity increased by <b>+3</b>.")

				----------------------------------------------------------------
				-- UPDATE 6 GAMEPASS PURCHASE POPUPS
				-- Effects themselves are applied in GameManager. These branches
				-- only fire once you set a real (non-zero) ID for each pass.
				----------------------------------------------------------------
			elseif purchasedPassId == LUCKY_SORCERER_PASS_ID then
				fireMajorPopup(player, "LUCKY SORCERER ACTIVE", "Your luck-based outcomes are improved.", "Lucky Sorcerer", "Future new lives roll improved clan/origin luck.")
				fireLifeUpdate(player, stats, "<font color='#ffcd69'><b>[ GAMEPASS ]</b></font> Lucky Sorcerer active. Future lives roll improved clan/origin luck.")

			elseif purchasedPassId == TRAINING_PRODIGY_PASS_ID then
				fireMajorPopup(player, "TRAINING PRODIGY ACTIVE", "Your training gains are boosted.", "Training Prodigy", "Supported Cursed Energy and Technique Mastery gains are stronger.")
				fireLifeUpdate(player, stats, "<font color='#78beff'><b>[ GAMEPASS ]</b></font> Training Prodigy active. Supported CE and Mastery training gains are boosted.")

			elseif purchasedPassId == MISSION_INVESTOR_PASS_ID then
				fireMajorPopup(player, "MISSION INVESTOR ACTIVE", "Your mission cash rewards are boosted.", "Mission Investor", "Standard mission money payouts are increased.")
				fireLifeUpdate(player, stats, "<font color='#78f0a0'><b>[ GAMEPASS ]</b></font> Mission Investor active. Standard mission money rewards are boosted.")

			elseif purchasedPassId == LEGACY_BLESSING_PASS_ID then
				fireMajorPopup(player, "LEGACY BLESSING ACTIVE", "Your bloodline carries more weight.", "Legacy Blessing", "Future heirs start stronger through your family line.")
				fireLifeUpdate(player, stats, "<font color='#ffcd69'><b>[ GAMEPASS ]</b></font> Legacy Blessing active. Future heirs start with stronger family progression.")

			elseif purchasedPassId == DOJO_EXPANSION_PASS_ID then
				fireMajorPopup(player, "DOJO EXPANSION ACTIVE", "Your dojo recruiting options expanded.", "Dojo Expansion", "You can recruit more starter students at your Grand Dojo.")
				fireLifeUpdate(player, stats, "<font color='#ffcd69'><b>[ GAMEPASS ]</b></font> Dojo Expansion active. Your dojo starter recruit options increased.")
			elseif purchasedPassId == AFK_STABILIZATION_GAMEPASS_ID then
				grantAFKStabilization(player, stats)

			elseif purchasedPassId == GOD_MODE_PASS_ID then
				fireMajorPopup(player, "GOD MODE UNLOCKED", "Trait edits, clan rerolls, start boosts, and reset life are now available.", "God Mode", "Open God Mode to start customizing.")
				fireLifeUpdate(player, stats, "<font color='#ffcd69'><b>[ GOD MODE ]</b></font> God Mode unlocked.")

			elseif purchasedPassId == GO_ROGUE_PASS_ID then
				fireMajorPopup(player, "GO ROGUE UNLOCKED", "You can now become a Rogue Sorcerer.", "Go Rogue", "Open Jobs to see the rogue path.")
				fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ GO ROGUE ]</b></font> Go Rogue unlocked.")

			elseif purchasedPassId == BINDING_VOW_SPECIALIST_PASS_ID then
				fireMajorPopup(player, "BINDING VOW SPECIALIST ACTIVE", "Hold 5 custom vows. Negative effects reduced by 25%.", "Vow Specialist", "Your custom vow limit is now 5 per life, and sacrifice costs are reduced.")
				fireLifeUpdate(player, stats, "<font color='#b388ff'><b>[ GAMEPASS ]</b></font> Binding Vow Specialist active. Custom vow limit raised to 5, negative effects reduced by 25%.")
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(leavingPlayer)
		local uid = leavingPlayer.UserId
		local gift = pendingGifts[uid]
		if gift then
			warn("[BK_CommerceService] Buyer left with pending gift. buyerId=" .. tostring(uid) .. " recipientId=" .. tostring(gift.recipientId) .. " productId=" .. tostring(gift.expectedProductId))
		end
		pendingGifts[uid] = nil
		giftInitiateCooldowns[uid] = nil
	end)

	if context.IS_DEBUG then print("[BK_CommerceService] Loaded Update 6 commerce logic (RCT Revive max 2 per life, 5 new gamepasses registered).") end
end

function BK_CommerceService.ClaimGiftMailbox(player)
	if not player then return end
	local userId = player.UserId
	local mailboxKey = "gifts_" .. tostring(userId)

	local gifts
	local readOk, readErr = pcall(function()
		gifts = giftMailboxStore:GetAsync(mailboxKey)
	end)
	if not readOk then
		warn("[BK_CommerceService] Gift mailbox read failed for " .. tostring(userId) .. ": " .. tostring(readErr))
		return
	end
	if typeof(gifts) ~= "table" or #gifts == 0 then return end

	local removeOk, removeErr = pcall(function()
		giftMailboxStore:RemoveAsync(mailboxKey)
	end)
	if not removeOk then
		warn("[BK_CommerceService] Gift mailbox clear failed for " .. tostring(userId) .. ": " .. tostring(removeErr))
	end

	local saveSystem = context.BitKaisenSaveSystem
	local stats = getStats(player)
	if not stats then return end

	for _, giftEntry in ipairs(gifts) do
		local passKey = tostring(giftEntry.passKey or "")
		local passLabel = tostring(giftEntry.passLabel or giftEntry.passKey or "Gift")
		local fromName = tostring(giftEntry.fromName or "another player")
		if passKey ~= "" then
			if saveSystem and type(saveSystem.GrantGiftedGamePassByUserId) == "function" then
				saveSystem.GrantGiftedGamePassByUserId(userId, passKey)
			end
			stats.GiftedGamePasses = typeof(stats.GiftedGamePasses) == "table" and stats.GiftedGamePasses or {}
			stats.GiftedGamePasses[passKey] = true
			if passKey == "GodMode" then
				stats.HasGodModePass = true
			elseif passKey == "GoRogue" then
				stats.HasGoRoguePass = true
			elseif passKey == "AFKStabilization" then
				stats.AFKStabilizationUnlocked = true
			end
			fireMajorPopup(player, "GIFT RECEIVED", "A gift was added to your account.", passLabel, "From: " .. fromName, "Success")
			fireLifeUpdate(player, stats, "<font color='#63e787'><b>[ GIFT ]</b></font> You received <b>" .. passLabel .. "</b> from <b>" .. fromName .. "</b>.")
		end
	end

	if context.ForceSaveStats then
		context.ForceSaveStats(player, "GiftMailboxClaim")
	else
		forceSaveStats(player, "GiftMailboxClaim")
	end
end

return BK_CommerceService
