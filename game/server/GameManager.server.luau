-- Script: GameManager
-- Location: ServerScriptService
-- NOTE:
--   This version is register-limit safe.
--   Some top-level helper functions are intentionally non-local because Roblox/Luau
--   was refusing to compile the mega GameManager with "Out of local registers".
--   Do not blindly convert them back to local unless GameManager is split into modules.

if _G.__GameManagerLoaded then
	warn("[GameManager] Duplicate detected â€” skipping. Delete the old Studio copy.")
	return
end
_G.__GameManagerLoaded = true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local Chat = game:GetService("Chat")
local TextService = game:GetService("TextService")

-- Remotes are now owned by BK_Remotes so UI remotes still exist even if another system breaks.
local ServerScriptService = game:GetService("ServerScriptService")
local BK_Remotes = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_Remotes"))
local BK_CommerceService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_CommerceService"))
local BK_CodeService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_CodeService"))
local BK_AchievementService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_AchievementService"))
local BK_DevCommands = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_DevCommands"))
local BK_DojoService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_DojoService"))
local BK_AssetService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_AssetService"))
BK_BlackMarketService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_BlackMarketService"))
BK_CultService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_CultService"))
local BK_RelationshipService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_RelationshipService"))
local BK_ActivityService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_ActivityService"))
local BK_MissionService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_MissionService"))
local BK_DailyLoginService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_DailyLoginService"))
local BK_JobService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_JobService"))
local BK_CombatService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_CombatService"))
local BK_AFKService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_AFKService"))
local BK_ClanWarService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_ClanWarService"))
BK_CultWarService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_CultWarService"))
local BK_DomainService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_DomainService"))
local BK_GodModeService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_GodModeService"))
local BK_RivalService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_RivalService"))
local BK_SchoolService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_SchoolService"))
local BK_MentorService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_MentorService"))
BK_WorldHistoryService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_WorldHistoryService"))
local BK_ChallengeService
do
	local ok, result = pcall(function()
		BK_ChallengeService = require(ServerScriptService:WaitForChild("BitKaisenServer", 5):WaitForChild("BK_ChallengeService", 5))
	end)
	if not ok then warn("[GameManager] BK_ChallengeService failed to load: " .. tostring(result)) end
end
BK_Remotes.Init()

local updateLifeEvent = BK_Remotes.Get("UpdateLifeEvent")
local showMajorPopup = BK_Remotes.Get("ShowMajorPopup")
local challengeCompleted = BK_Remotes.Get("ChallengeCompleted")
local showMissionSituation = BK_Remotes.Get("ShowMissionSituation")
local missionChoice = BK_Remotes.Get("MissionChoice")
local clearPendingMission = BK_Remotes.Get("ClearPendingMission")
local getMissionBoard = BK_Remotes.Get("GetMissionBoard")
local getActivityList = BK_Remotes.Get("GetActivityList")
local getJobs = BK_Remotes.Get("GetJobs")
local jobAction = BK_Remotes.Get("JobAction")
local testPurchase = BK_Remotes.Get("TestPurchase")
local getRelationships = BK_Remotes.Get("GetRelationships")
local relationshipAction = BK_Remotes.Get("RelationshipAction")
getWorldHistory = BK_Remotes.Get("GetWorldHistory")
getTitles = BK_Remotes.Get("GetTitles")
getDevTools = BK_Remotes.Get("GetDevTools")
devToolsAction = BK_Remotes.Get("DevToolsAction")
local getAssets = BK_Remotes.Get("GetAssets")
local assetAction = BK_Remotes.Get("AssetAction")
getBlackMarket = BK_Remotes.Get("GetBlackMarket")
blackMarketAction = BK_Remotes.Get("BlackMarketAction")
getCult = BK_Remotes.Get("GetCult")
cultAction = BK_Remotes.Get("CultAction")
local getClanWar = BK_Remotes.Get("GetClanWar")
local clanWarAction = BK_Remotes.Get("ClanWarAction")
getCultWar = BK_Remotes.Get("GetCultWar")
cultWarAction = BK_Remotes.Get("CultWarAction")
local getDomain = BK_Remotes.Get("GetDomain")
local domainAction = BK_Remotes.Get("DomainAction")
local getGodMode = BK_Remotes.Get("GetGodMode")
local godModeAction = BK_Remotes.Get("GodModeAction")
local getRivals = BK_Remotes.Get("GetRivals")
local rivalAction = BK_Remotes.Get("RivalAction")
local getSuccessorOptions = BK_Remotes.Get("GetSuccessorOptions")
local chooseSuccessor = BK_Remotes.Get("ChooseSuccessor")
local updateSettingsEvent = BK_Remotes.Get("UpdateSettingsEvent")
local getMentor = BK_Remotes.Get("GetMentor")
local mentorAction = BK_Remotes.Get("MentorAction")

local getSaveSlots = BK_Remotes.Get("GetSaveSlots")
local selectSaveSlot = BK_Remotes.Get("SelectSaveSlot")
local createSaveSlot = BK_Remotes.Get("CreateSaveSlot")
local deleteSaveSlot = BK_Remotes.Get("DeleteSaveSlot")

local getAchievements = BK_Remotes.Get("GetAchievements")
local claimAchievement = BK_Remotes.Get("ClaimAchievement")
local redeemCode = BK_Remotes.Get("RedeemCode")
local getCodeGate = BK_Remotes.Get("GetCodeGate")
local getBindingVows = BK_Remotes.Get("GetBindingVows")
local bindingVowAction = BK_Remotes.Get("BindingVowAction")
local getCombatState = BK_Remotes.Get("GetCombatState")
local combatAction = BK_Remotes.Get("CombatAction")
local combatStateUpdate = BK_Remotes.Get("CombatStateUpdate")
local combatMinigameResult = BK_Remotes.Get("CombatMinigameResult")
local submitCharacterCustomization = BK_Remotes.Get("SubmitCharacterCustomization")
local initiateGift = BK_Remotes.Get("InitiateGift")
local promptGiftPurchase = BK_Remotes.Get("PromptGiftPurchase")

local showGroupJoinPrompt = BK_Remotes.Get("PromptGroupJoin")
local claimGroupJoinReward = BK_Remotes.Get("ClaimGroupJoinReward")
local getDailyLogin = BK_Remotes.Get("GetDailyLogin")
local claimDailyLogin = BK_Remotes.Get("ClaimDailyLogin")
local getFreeReward = BK_Remotes.Get("GetFreeReward")
local claimFreeReward = BK_Remotes.Get("ClaimFreeReward")
local getAFKStabilization = BK_Remotes.Get("GetAFKStabilization")
local afkStabilizationAction = BK_Remotes.Get("AFKStabilizationAction")
local afkStabilizationUpdate = BK_Remotes.Get("AFKStabilizationUpdate")

local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local BitKaisenStats = require(ReplicatedStorage:WaitForChild("BitKaisenStats"))
local BitKaisenMissions = require(ReplicatedStorage:WaitForChild("BitKaisenMissions"))
local BitKaisenActivities = require(ReplicatedStorage:WaitForChild("BitKaisenActivities"))
local BitKaisenLifeEvents = require(ReplicatedStorage:WaitForChild("BitKaisenLifeEvents"))
local BitKaisenRelationships = require(ReplicatedStorage:WaitForChild("BitKaisenRelationships"))
local BitKaisenTraits = require(ReplicatedStorage:WaitForChild("BitKaisenTraits"))
local BitKaisenCombat = require(ReplicatedStorage:WaitForChild("BitKaisenCombat"))
local BitKaisenCursedTools = require(ReplicatedStorage:WaitForChild("BitKaisenCursedTools"))
local BitKaisenTechniqueEvolution = require(ReplicatedStorage:WaitForChild("BitKaisenTechniqueEvolution"))
local BitKaisenAssets = require(ReplicatedStorage:WaitForChild("BitKaisenAssets"))
local BitKaisenSituations = require(ReplicatedStorage:WaitForChild("BitKaisenSituations"))
local BitKaisenLegacy = require(ReplicatedStorage:WaitForChild("BitKaisenLegacy"))
local BitKaisenSaveSystem = require(ServerScriptService:WaitForChild("BitKaisenSaveSystem"))
if BK_ChallengeService then
	BK_ChallengeService.Init(BitKaisenSaveSystem)
end

-- Put your own Roblox UserId(s) here. Anyone in this table can use dev_awaken
-- and will see hidden dev activities.
local DEV_USER_IDS = {
	[3575148423] = true,
}

local IS_DEBUG = RunService:IsStudio() or game.PlaceId == 104206065947170

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
local DOUBLE_TRAINING_PASS_ID = 1849210885 -- Displayed as 2x Progress in the shop.
local LUCKY_BIRTH_PASS_ID = 1859848647
local EXTRA_DOJO_STUDENTS_PASS_ID = 1862959768
local GOD_MODE_PASS_ID = 1861509054 -- God Mode gamepass ID.
local GO_ROGUE_PASS_ID = 1887460270 -- Go Rogue gamepass ID.

local NEW_PASS_IDS = {
	LuckySorcerer = 1863476467,
	TrainingProdigy = 1863314699,
	MissionInvestor = 1863458434,
	LegacyBlessing = 1865683126,
	DojoExpansion = 0,
	FocusedTraining = 1847591321,
	AFKPass = 1879156343,
	BindingVowSpecialist = 1863380690,
	PremiumOrigins = 1902804677,
	HighSociety = 1903626636,
}
local STARTER_SORCERER_PACK_PRODUCT_ID = 3595826857
local FOCUSED_TRAINING_PRODUCT_ID = 3595838153
local MONEY_5000_PRODUCT_ID = 3596044734
local MONEY_25000_PRODUCT_ID = 3595898637
local MONEY_100000_PRODUCT_ID = 3596045207
local RECRUIT_REROLL_PRODUCT_ID = 3596045471
local RECOMMENDATION_LETTER_PRODUCT_ID = 3600600214
local EMERGENCY_TREATMENT_PRODUCT_ID = 3600600619
local RCT_REVIVE_PRODUCT_ID = 3601401158
local RCT_REVIVE_MAX_PER_LIFE = 2

local TEST_PURCHASE_PLACE_IDS = {
	[104206065947170] = true,
}

-- Codes gate. Set BITKAISEN_GROUP_ID to your Roblox group ID before release.
-- Roblox does not expose a trustworthy per-player "liked the game" check to server scripts,
-- so likes are handled through a client confirmation gate while group membership is verified server-side.
local BITKAISEN_GROUP_ID = 212374896
local REQUIRE_GROUP_FOR_CODES = true
local REQUIRE_LIKE_CONFIRMATION_FOR_CODES = false


local VIP_CACHE_SECONDS = 60
local ownershipCaches = {
	vip = {},
	extraSaveSlots = {},
	doubleMoney = {},
	doubleTraining = {},
	luckyBirth = {},
	extraDojoStudents = {},
	godMode = {},
	goRogue = {},
	luckySorcerer = {},
	trainingProdigy = {},
	missionInvestor = {},
	legacyBlessing = {},
	dojoExpansion = {},
	focusedTraining = {},
	afkPass = {},
	bindingVowSpecialist = {},
	premiumOrigins = {},
	highSociety = {},
}

local RATE_LIMITS = {
	AgeUp = 0.4,
	DoMission = 0.6,
	DoActivity = 0.4,
	JobAction = 0.75,
	MissionChoice = 0.3,
	RelationshipAction = 0.75,
	AssetAction = 0.3,
	BlackMarketAction = 0.3,
	StartNewLife = 1.5,
	StartAsSuccessor = 1.5,
	UpdateSettings = 0.1,
	SelectSaveSlot = 1.0,
	CreateSaveSlot = 1.5,
	DeleteSaveSlot = 1.5,
	ClaimAchievement = 0.75,
	RedeemCode = 1.0,
	BindingVowAction = 0.75,
	ClaimDailyLogin = 0.8,
	ClaimFreeReward = 1.0,
	SubmitCharacterCustomization = 0.75,
	TestPurchase = 0.5,
	GodModeAction = 0.5,
	RivalAction = 0.5,
	DevToolsAction = 0.2
}

function isDev(player)
	if RunService:IsStudio() then
		return true
	end

	return DEV_USER_IDS[player.UserId] == true
end

local function isTestPurchasePlace()
	return TEST_PURCHASE_PLACE_IDS[game.PlaceId] == true or RunService:IsStudio()
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

	if isTestPurchasePlace() then
		return true
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

-- Beach Hero pass whitelist: players granted gamepasses as a reward.
-- Keys: "GodMode", "VIPSorcerer", "GoRogue"
local BEACH_HERO_PASS_GRANTS = {
	[145218871]  = { GodMode = true },
	[3479043803] = { GodMode = true },
	[1275830197] = { GodMode = true },
	[2008496335] = { GodMode = true },
	[1929493558] = { GodMode = true },
	[608763527]  = { VIPSorcerer = true },
	[1627859294] = { GodMode = true },
	[1512595364] = { GodMode = true },
	[1503974726] = { VIPSorcerer = true },
	[4273304767] = { GodMode = true },
	[1867124983] = { GodMode = true },
	[4764036688] = { GodMode = true },
	[1496288282] = { GodMode = true },
	[791696256]  = { GodMode = true },
	[3658030995] = { GodMode = true },
	[5853645353] = { GodMode = true },
	[323759528]  = { GodMode = true },
	[4003067801] = { TrainingProdigy = true },
	[3440214369] = { GoRogue = true },
	[344370600]  = { GodMode = true },
	[1555021957] = { GodMode = true },
	[365094364]  = { GodMode = true },
	[117645658]  = { VIPSorcerer = true },
	[464955055]  = { GodMode = true },
	[2022874552] = { GodMode = true },
	[574558655]  = { GodMode = true },
	[975810733]  = { GoRogue = true },
	[3557377006] = { GodMode = true },
	[185882594]  = { GodMode = true },
	[4997992042] = { GodMode = true },
	[881138538]  = { GodMode = true },
	[2817583841] = { VIPSorcerer = true },
	[1655026669] = { GodMode = true },
	[1529151802] = { GodMode = true },
}

local function beachHeroHasPass(player, passKey)
	if not player then return false end
	local grants = BEACH_HERO_PASS_GRANTS[player.UserId]
	return grants ~= nil and grants[passKey] == true
end

function ownsVIPSorcererPass(player)
	return checkCachedGamePassOwnership(player, VIP_SORCERER_PASS_ID, ownershipCaches.vip, "VIP Sorcerer Pass")
		or beachHeroHasPass(player, "VIPSorcerer")
end

function ownsExtraSaveSlotsPass(player)
	return checkCachedGamePassOwnership(player, EXTRA_SAVE_SLOTS_PASS_ID, ownershipCaches.extraSaveSlots, "Extra Save Slots")
end

function ownsDoubleMoneyPass(player)
	return checkCachedGamePassOwnership(player, DOUBLE_MONEY_PASS_ID, ownershipCaches.doubleMoney, "2x Money")
end

function ownsDoubleTrainingPass(player)
	return checkCachedGamePassOwnership(player, DOUBLE_TRAINING_PASS_ID, ownershipCaches.doubleTraining, "2x Progress")
end

function ownsLuckyBirthPass(player)
	return checkCachedGamePassOwnership(player, LUCKY_BIRTH_PASS_ID, ownershipCaches.luckyBirth, "Lucky Birth")
end

function ownsLuckySorcererPass(player)
	return checkCachedGamePassOwnership(player, NEW_PASS_IDS.LuckySorcerer, ownershipCaches.luckySorcerer, "Lucky Sorcerer")
end

function ownsTrainingProdigyPass(player)
	return checkCachedGamePassOwnership(player, NEW_PASS_IDS.TrainingProdigy, ownershipCaches.trainingProdigy, "Training Prodigy")
		or beachHeroHasPass(player, "TrainingProdigy")
end

function ownsMissionInvestorPass(player)
	return checkCachedGamePassOwnership(player, NEW_PASS_IDS.MissionInvestor, ownershipCaches.missionInvestor, "Mission Investor")
end

function ownsLegacyBlessingPass(player)
	return checkCachedGamePassOwnership(player, NEW_PASS_IDS.LegacyBlessing, ownershipCaches.legacyBlessing, "Legacy Blessing")
end

function ownsDojoExpansionPass(player)
	return checkCachedGamePassOwnership(player, NEW_PASS_IDS.DojoExpansion, ownershipCaches.dojoExpansion, "Dojo Expansion")
end

function ownsFocusedTrainingPass(player)
	return checkCachedGamePassOwnership(player, NEW_PASS_IDS.FocusedTraining, ownershipCaches.focusedTraining, "Focused Training")
end

function ownsAFKPass(player)
	return checkCachedGamePassOwnership(player, NEW_PASS_IDS.AFKPass, ownershipCaches.afkPass, "AFK Pass")
end

function ownsBindingVowSpecialistPass(player)
	return checkCachedGamePassOwnership(player, NEW_PASS_IDS.BindingVowSpecialist, ownershipCaches.bindingVowSpecialist, "Binding Vow Specialist")
end

function ownsPremiumOriginsPass(player)
	return checkCachedGamePassOwnership(player, NEW_PASS_IDS.PremiumOrigins, ownershipCaches.premiumOrigins, "Premium Origins")
end

function ownsHighSocietyPass(player)
	return checkCachedGamePassOwnership(player, NEW_PASS_IDS.HighSociety, ownershipCaches.highSociety, "High Society")
end

function ownsExtraDojoStudentsPass(player)
	return checkCachedGamePassOwnership(player, EXTRA_DOJO_STUDENTS_PASS_ID, ownershipCaches.extraDojoStudents, "Extra Dojo Students")
end

function hasGiftedGamePass(player, passKey)
	if not player then
		return false
	end
	passKey = tostring(passKey or "")
	local stats = playerLives[player.UserId]
	if typeof(stats) == "table" and typeof(stats.GiftedGamePasses) == "table" and stats.GiftedGamePasses[passKey] == true then
		return true
	end
	if not BitKaisenSaveSystem or type(BitKaisenSaveSystem.HasGiftedGamePass) ~= "function" then
		return false
	end
	local ok, result = pcall(function()
		return BitKaisenSaveSystem.HasGiftedGamePass(player, passKey)
	end)
	return ok and result == true
end

function ownsGodModePass(player)
	return checkCachedGamePassOwnership(player, GOD_MODE_PASS_ID, ownershipCaches.godMode, "God Mode")
		or hasGiftedGamePass(player, "GodMode")
		or beachHeroHasPass(player, "GodMode")
end

function ownsGoRoguePass(player)
	return checkCachedGamePassOwnership(player, GO_ROGUE_PASS_ID, ownershipCaches.goRogue, "Go Rogue")
		or hasGiftedGamePass(player, "GoRogue")
		or beachHeroHasPass(player, "GoRogue")
end

function syncMonetizationEntitlements(player, stats)
	if not player or not stats then
		return
	end

	stats.HasLuckyBirthPass = ownsLuckyBirthPass(player)
	stats.HasExtraDojoStudentsPass = ownsExtraDojoStudentsPass(player)
	stats.HasDoubleProgressPass = ownsDoubleTrainingPass(player)
	stats.HasDoubleYenPass = ownsDoubleMoneyPass(player)
	stats.HasVIPPass = ownsVIPSorcererPass(player)
	stats.HasGodModePass = ownsGodModePass(player)
	stats.HasGoRoguePass = ownsGoRoguePass(player)
	stats.HasLuckySorcererPass = ownsLuckySorcererPass(player)
	stats.HasBindingVowSpecialistPass = ownsBindingVowSpecialistPass(player)
	stats.HasLegacyBlessingPass = ownsLegacyBlessingPass(player)
	stats.HasDojoExpansionPass = ownsDojoExpansionPass(player)
	stats.HasPremiumOriginsPass = ownsPremiumOriginsPass(player)
	stats.HasHighSocietyPass = ownsHighSocietyPass(player)
	if ownsVIPSorcererPass(player) then
		stats.VIPTitle = "VIP Sorcerer"
	end
	if hasGiftedGamePass(player, "AFKStabilization") then
		stats.AFKStabilizationUnlocked = true
	end
end

local function applyLuckySorcererBirthBoost(player, stats)
	if not ownsLuckySorcererPass(player) then return end
	stats.Smarts = math.min(100, math.floor((stats.Smarts or 50) * 1.15))
	stats.Health = math.min(100, math.floor((stats.Health or 100) * 1.15))
	stats.Happiness = math.min(100, math.floor((stats.Happiness or 100) * 1.15))
	stats.Looks = math.min(100, math.floor((stats.Looks or 50) * 1.15))
	stats.Strength = math.max(5, math.floor((stats.Strength or 0) * 1.15))
end

local function applyLegacyBlessingBoost(player, stats)
	if not ownsLegacyBlessingPass(player) then return end
	local gen = math.max(1, tonumber(stats.Generation) or 1)
	local scaledBonus = math.clamp(gen - 1, 0, 5)
	stats.CursedEnergy = (tonumber(stats.CursedEnergy) or 0) + (25 * scaledBonus)
	stats.Strength = math.min(100, (tonumber(stats.Strength) or 0) + (3 * scaledBonus))
	stats.Smarts = math.min(100, (tonumber(stats.Smarts) or 0) + (2 * scaledBonus))
	stats.Health = math.min(100, (tonumber(stats.Health) or 0) + (3 * scaledBonus))
	stats.Reputation = (tonumber(stats.Reputation) or 0) + (2 * scaledBonus)
end


function getBirthOriginScore(originData)
	if typeof(originData) ~= "table" then
		return 0
	end

	local score = 0
	local category = tostring(originData.Category or "")
	local familyType = tostring(originData.FamilyType or "")

	if category == "Race" then
		score += 55
	elseif category == "Lineage" then
		score += 45
	elseif category == "Clan" then
		score += 38
	elseif familyType == "Sorcerer" then
		score += 24
	elseif familyType == "Fallen" then
		score += 20
	elseif familyType == "Unknown" then
		score += 14
	elseif familyType == "Civilian" then
		score += 5
	end

	score += math.floor((tonumber(originData.BonusCE) or 0) * 0.8)
	score += math.floor((tonumber(originData.BonusSmarts) or 0) * 0.35)

	if typeof(originData.InnatePool) == "table" and #originData.InnatePool > 0 then
		score += 12
	end

	return score
end

function rollBirthOriginForPlayer(player)
	-- Premium Origins guarantees a canon clan/lineage (Gojo, Zenin, Itadori...)
	-- instead of the full pool where those sit at under 1% chance each. Still
	-- random WHICH one, and carries the exact same bonuses anyone who rolled
	-- it naturally gets -- see BitKaisenStats.RollPremiumOrigin for the guardrail.
	if ownsPremiumOriginsPass(player) then
		return BitKaisenStats.RollPremiumOrigin()
	end

	local bestOrigin = BitKaisenStats.RollOrigin()

	if not ownsLuckyBirthPass(player) then
		return bestOrigin
	end

	-- Lucky Birth rolls extra birth chances and keeps the strongest result.
	-- 25% luck boost: 4 extra rolls (total 5) for clan/origin selection.
	for _ = 1, 4 do
		local candidate = BitKaisenStats.RollOrigin()
		if getBirthOriginScore(candidate) > getBirthOriginScore(bestOrigin) then
			bestOrigin = candidate
		end
	end

	return bestOrigin
end

function applyLuckyBirthBonuses(player, stats)
	if not player or not stats or not ownsLuckyBirthPass(player) then
		return false
	end

	stats.HasLuckyBirthPass = true
	stats.LuckyBirthActive = true
	stats.CursedEnergy = (tonumber(stats.CursedEnergy) or 0) + 10
	stats.Smarts = math.clamp((tonumber(stats.Smarts) or 0) + 3, 0, 100)
	stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) + 3, 0, 100)

	return true
end

function ownsSaveSlotAccess(player)
	if ownsVIPSorcererPass(player) or ownsExtraSaveSlotsPass(player) then
		return true
	end

	if player and BitKaisenSaveSystem and type(BitKaisenSaveSystem.HasExtraSaveSlotsUnlocked) == "function" then
		local ok, unlocked = pcall(function()
			return BitKaisenSaveSystem.HasExtraSaveSlotsUnlocked(player)
		end)
		if ok and unlocked == true then
			return true
		end
	end

	if player then
		local stats = playerLives[player.UserId]
		if stats and (stats.FreeSaveSlotsUnlocked == true or (stats.Codes and stats.Codes.FreeSaveSlotsUnlocked == true)) then
			return true
		end
	end

	return false
end

function clearVIPCache(player)
	if player then
		ownershipCaches.vip[player.UserId] = nil
		ownershipCaches.extraSaveSlots[player.UserId] = nil
		ownershipCaches.doubleMoney[player.UserId] = nil
		ownershipCaches.doubleTraining[player.UserId] = nil
		ownershipCaches.luckyBirth[player.UserId] = nil
		ownershipCaches.extraDojoStudents[player.UserId] = nil
		ownershipCaches.godMode[player.UserId] = nil
		ownershipCaches.bindingVowSpecialist[player.UserId] = nil
	end
end


-- Release hotfix: these must exist before startAsCurseRebirth is defined.
-- The detailed curse module also defines local copies later, but the rebirth function
-- is earlier in this mega-script and otherwise reads nil globals.
CURSE_TERRITORIES = CURSE_TERRITORIES or {
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

CURSE_RUMOR_TITLES = CURSE_RUMOR_TITLES or {
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

function pickRandom(list)
	if typeof(list) ~= "table" or #list <= 0 then
		warn("[GameManager] pickRandom received an empty/nil list. Returning fallback value.")
		return "Unknown"
	end

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

local _lastChallengeCheck = {}

local function tSys(player, key, params, fallback)
	local locale = BitKaisenLocale.getPlayerLocale(player.UserId)
	return BitKaisenLocale.tOrFallback(locale, "system." .. key, params, fallback)
end


function fireLifeUpdate(player, stats, message, forceResetLog, isRejoin)
	updateLifeEvent:FireClient(player, stats, message, forceResetLog == true)
	if not BK_ChallengeService or not stats then return end

	local isNewLife = forceResetLog == true and not isRejoin
	local now = os.clock()
	local lastCheck = _lastChallengeCheck[player.UserId] or 0

	-- Only run stat checks every 3 seconds, but always run on new life
	if not isNewLife and not isRejoin and (now - lastCheck) < 3 then return end
	-- Loaded stats are not stat changes — InitPlayer already restored the done map
	if isRejoin then return end
	_lastChallengeCheck[player.UserId] = now

	local allNewly = {}
	if isNewLife then
		local ok, lifeNewly = pcall(BK_ChallengeService.OnNewLife, player)
		if ok and lifeNewly then
			for _, ch in ipairs(lifeNewly) do table.insert(allNewly, ch) end
		end
	end
	local ok2, statNewly = pcall(BK_ChallengeService.CheckStats, player, stats)
	if ok2 and statNewly then
		for _, ch in ipairs(statNewly) do table.insert(allNewly, ch) end
	end
	for _, ch in ipairs(allNewly) do
		fireMajorPopup(player, "CHALLENGE COMPLETE!", ch.Desc, ch.Title, "+" .. ch.Reward, "success")
		challengeCompleted:FireClient(player, ch.Id)
	end
end

function fireMajorPopup(player, title, body, highlight, footer, tone)
	showMajorPopup:FireClient(player, {
		Title = title or "EVENT",
		Body = body or "",
		Highlight = highlight or "",
		Footer = footer or "",
		Tone = tone or ""
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

local getKarmaRiskMod -- forward declaration; defined below after isCurseUser

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
	local riskMult = BitKaisenTraits.GetModifier(stats, "RiskMult", 1) * getKarmaRiskMod(stats)

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

	if not hasAnyTechnique and cursedEnergy < 200 then
		return "Non-Sorcerer"
	end

	local supportScore = (mastery * 2) + math.max(0, reputation) + math.floor(smarts * 0.25)
	local effectiveCE = cursedEnergy + math.floor(supportScore * 0.25)
	if stats.HeavenlyRestricted == true then
		effectiveCE += 120
	end

	if effectiveCE >= 1200 then return "Grade 1" end
	if effectiveCE >= 1000 then return "Semi-Grade 1" end
	if effectiveCE >= 800 then return "Grade 2" end
	if effectiveCE >= 650 then return "Semi-Grade 2" end
	if effectiveCE >= 450 then return "Grade 3" end
	if effectiveCE >= 200 then return "Grade 4" end
	return "Non-Sorcerer"
end

function isOfficialJujutsuSorcerer(stats)
	if not stats then
		return false
	end
	local gradeText = tostring(stats.Grade or "Non-Sorcerer")
	local isRegistered = stats.InJujutsuHigh == true
		or stats.RegisteredSorcerer == true
		or stats.GraduatedJujutsuHigh == true
		or stats.IsJujutsuMentor == true
	return isRegistered
		and getGradeValue(gradeText) > 0
		and string.sub(gradeText, 1, 13) ~= "Unregistered "
end

local function adjustKarma(stats, amount)
	if not stats then return end
	stats.HiddenKarma = math.clamp((tonumber(stats.HiddenKarma) or 0) + amount, -100, 100)
end

getKarmaRiskMod = function(stats)
	local k = tonumber(stats and stats.HiddenKarma) or 0
	return 1 - (k / 100) * 0.15 + (k < 0 and (-k / 100) * 0.05 or 0)
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

	if isCurseLife(stats) then
		stats.InJujutsuHigh = false
		stats.RegisteredSorcerer = false
		stats.Affiliation = "Unaffiliated"
		stats.AffiliationRank = "None"
		stats.ClanFounded = false
		stats.PlayerClanName = nil
		stats.DojoRank = "No Dojo"
		stats.DojoReputation = 0
		stats.JoinedDojoName = nil
		stats.DojoApplicationPending = false
		stats.DojoApplication = nil
		stats.DojoApplicationName = nil
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
	stats.GraduatedJujutsuHigh = stats.GraduatedJujutsuHigh == true
	stats.IsJujutsuMentor = stats.IsJujutsuMentor == true

	local isOfficiallyRegistered = stats.InJujutsuHigh or stats.GraduatedJujutsuHigh or stats.IsJujutsuMentor
	stats.RegisteredSorcerer = isOfficiallyRegistered

	if isOfficiallyRegistered then
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

function getNaturalOldAgeDeathChance(age)
	age = tonumber(age) or 0
	if age < 80 then
		return 0
	end

	-- Starts noticeable at 80 and reaches guaranteed mortality by 112.
	-- This prevents human lives from feeling accidentally immortal while still allowing rare long lives.
	return math.clamp(5 + ((age - 80) * 3), 5, 100)
end

function applyOldAgeMortality(stats)
	if not stats or stats.Alive == false or isCurseLife(stats) then
		return ""
	end

	local age = tonumber(stats.Age) or 0
	if age < 80 then
		return ""
	end

	local rctYearsRemaining = math.max(0, tonumber(stats.RCTOldAgeYearsRemaining) or 0)
	if rctYearsRemaining > 0 then
		stats.RCTOldAgeYearsRemaining = math.max(0, rctYearsRemaining - 1)
		return "\n<font color='#a782ff'><b>[ RCT ]</b></font> Your RCT-extended body held on for another year. Extra years remaining: <b>" .. tostring(stats.RCTOldAgeYearsRemaining) .. "</b>."
	end

	local deathChance = getNaturalOldAgeDeathChance(age)
	if math.random(1, 100) <= deathChance then
		local charges = tonumber(stats.MiracleCharges) or 0
		if tostring(stats.CursedTechnique) == "Miracle" and charges > 0 then
			stats.MiracleCharges = charges - 1
			local remaining = tonumber(stats.MiracleCharges) or 0
			return "\n<font color='#c8a4ff'><b>[ MIRACLE ]</b></font> Death came for you, but a miracle held it back. Marks remaining: <b>" .. remaining .. "</b>."
				.. (remaining == 0 and " Your marks are gone — you are now completely vulnerable." or "")
		end
		stats.Alive = false
		stats.CauseOfDeath = "Old age"
		refreshCurseRebirthEligibility(stats)
		return "\nYour life reached its final year."
	end

	return "\n<font color='#b8b8c8'><b>[ AGE ]</b></font> Your body felt the weight of age, but you endured another year. Old-age risk: <b>" .. tostring(deathChance) .. "%</b>."
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
		stats.CursedFingers = math.clamp(tonumber(stats.CursedFingers) or 0, 0, 20)
		stats.CursedObjectAnchors = math.max(0, tonumber(stats.CursedObjectAnchors) or 0)
		stats.CursedObjectAnchorProgress = math.clamp(tonumber(stats.CursedObjectAnchorProgress) or 0, 0, 100)
		stats.ReincarnationAnchor = tostring(stats.ReincarnationAnchor or "None")
		stats.SocietyRecognition = math.max(0, tonumber(stats.SocietyRecognition) or 0)
		stats.SocietyInfluence = math.clamp(tonumber(stats.SocietyInfluence) or math.floor((stats.SocietyRecognition + (tonumber(stats.Fame) or 0) + (tonumber(stats.AffiliationReputation) or 0)) / 3), 0, 100)
		stats.SocietyRank = tostring(stats.SocietyRank or "None")
		stats.CouncilSeats = math.max(0, tonumber(stats.CouncilSeats) or 0)
		stats.CouncilCampaigns = math.max(0, tonumber(stats.CouncilCampaigns) or 0)
		stats.SocietyPolicyWins = math.max(0, tonumber(stats.SocietyPolicyWins) or 0)
		stats.LastSocietyOutcome = tostring(stats.LastSocietyOutcome or "None")
		stats.DojoReputation = math.max(0, tonumber(stats.DojoReputation) or tonumber(stats.ClanReputation) or 0)
		stats.DojoRank = tostring(stats.DojoRank or "No Dojo")
		stats.DojoIncome = math.max(0, tonumber(stats.DojoIncome) or 0)
		stats.DojoLegacy = math.clamp(tonumber(stats.DojoLegacy) or math.floor((stats.DojoReputation + (tonumber(stats.ClanReputation) or 0)) / 3), 0, 100)
		stats.DojoLegacyTier = tostring(stats.DojoLegacyTier or "None")
		stats.DojoSuccessors = math.max(0, tonumber(stats.DojoSuccessors) or 0)
		stats.DojoNamedSuccessors = math.max(0, tonumber(stats.DojoNamedSuccessors) or 0)
		stats.DojoLegacyCeremonies = math.max(0, tonumber(stats.DojoLegacyCeremonies) or 0)
		stats.ChildrenInductedIntoDojo = math.max(0, tonumber(stats.ChildrenInductedIntoDojo) or 0)
		stats.DojoProtectionBonus = math.clamp(tonumber(stats.DojoProtectionBonus) or 0, 0, 35)
		stats.LastDojoLegacyAge = tonumber(stats.LastDojoLegacyAge) or -1
		stats.StudentMissionCooldown = math.max(0, tonumber(stats.StudentMissionCooldown) or 0)
		stats.FamilyReputation = math.max(0, tonumber(stats.FamilyReputation) or 0)
		stats.ClanLeadership = tostring(stats.ClanLeadership or "None")
		stats.ClanPoliticalPower = math.clamp(tonumber(stats.ClanPoliticalPower) or math.floor((stats.FamilyReputation + (tonumber(stats.ClanReputation) or 0)) / 3), 0, 100)
		stats.ClanMergeRequestsSent = math.max(0, tonumber(stats.ClanMergeRequestsSent) or 0)
		stats.ClanMergeAlliances = math.max(0, tonumber(stats.ClanMergeAlliances) or 0)
		stats.ClanMergePacts = math.max(0, tonumber(stats.ClanMergePacts) or 0)
		stats.ClanMergeRejections = math.max(0, tonumber(stats.ClanMergeRejections) or 0)
		stats.ClanRivalries = math.max(0, tonumber(stats.ClanRivalries) or 0)
		stats.ClanMergeAccepted = stats.ClanMergeAccepted == true
		stats.LastClanMergeOutcome = tostring(stats.LastClanMergeOutcome or "None")
		stats.DojoRaidRisk = math.clamp(tonumber(stats.DojoRaidRisk) or 0, 0, 100)
		stats.DojoRaidsDefended = math.max(0, tonumber(stats.DojoRaidsDefended) or 0)
		stats.DojoRaidsFailed = math.max(0, tonumber(stats.DojoRaidsFailed) or 0)
		stats.DojoRaidDamageTaken = math.max(0, tonumber(stats.DojoRaidDamageTaken) or 0)
		stats.DojoRaidStudentsInjured = math.max(0, tonumber(stats.DojoRaidStudentsInjured) or 0)
		stats.DojoRaidSuppliesLost = math.max(0, tonumber(stats.DojoRaidSuppliesLost) or 0)
		stats.DojoRecoveryDebt = math.max(0, tonumber(stats.DojoRecoveryDebt) or 0)
		stats.DojoRecoveryProjects = math.max(0, tonumber(stats.DojoRecoveryProjects) or 0)
		stats.LastDojoRaidType = tostring(stats.LastDojoRaidType or "None")
		stats.LastDojoRaidOutcome = tostring(stats.LastDojoRaidOutcome or "None")
		stats.RogueStudentIncidents = math.max(0, tonumber(stats.RogueStudentIncidents) or 0)
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
	elseif tostring(stats.LifePath or "") == "Rogue Sorcerer" or tostring(stats.SocietyStatus or "") == "Rogue Sorcerer" then
		stats.LifePath = "Rogue Sorcerer"
		stats.SocietyStatus = "Rogue Sorcerer"
		stats.RegisteredSorcerer = false
	elseif stats.IsJujutsuMentor == true then
		stats.SocietyStatus = "Jujutsu Mentor"
		stats.RegisteredSorcerer = true
	elseif stats.InJujutsuHigh == true then
		stats.SocietyStatus = "Jujutsu Student"
		stats.RegisteredSorcerer = true
	elseif stats.GraduatedJujutsuHigh == true then
		stats.SocietyStatus = "Registered Sorcerer"
		stats.RegisteredSorcerer = true
	elseif tostring(stats.Grade or "Non-Sorcerer") ~= "Non-Sorcerer" then
		stats.SocietyStatus = stats.RegisteredSorcerer and "Registered Sorcerer" or "Unregistered Sorcerer"
	end

	stats.HeianEraEncounters = math.max(0, tonumber(stats.HeianEraEncounters) or 0)
	stats.EdoEraEncounters = math.max(0, tonumber(stats.EdoEraEncounters) or 0)
	stats.ModernEraEncounters = math.max(0, tonumber(stats.ModernEraEncounters) or 0)
	stats.EraLoreDiscoveries = math.max(0, tonumber(stats.EraLoreDiscoveries) or 0)
	stats.SpecialGradeThreatsSurvived = math.max(0, tonumber(stats.SpecialGradeThreatsSurvived) or 0)
	stats.LastEraLoreOutcome = tostring(stats.LastEraLoreOutcome or "None")
	stats.Fame = math.clamp(tonumber(stats.Fame) or math.floor((tonumber(stats.Reputation) or 0) * 0.25), 0, 100)
	stats.Fear = math.clamp(tonumber(stats.Fear) or math.floor((tonumber(stats.WantedLevel) or 0) * 0.5), 0, 100)
	stats.WorldAttention = math.clamp(tonumber(stats.WorldAttention) or math.floor(((tonumber(stats.Fame) or 0) + (tonumber(stats.Fear) or 0)) / 2), 0, 100)
	stats.WorldPressure = math.clamp(tonumber(stats.WorldPressure) or math.floor(((tonumber(stats.Fear) or 0) * 0.65) + ((tonumber(stats.WantedLevel) or 0) * 2)), 0, 100)
	stats.WorldReputationTier = getWorldReputationTier and getWorldReputationTier(stats) or tostring(stats.WorldReputationTier or "Unknown")
	stats.PublicSupport = math.clamp(tonumber(stats.PublicSupport) or 0, 0, 100)
	stats.HunterPressure = math.clamp(tonumber(stats.HunterPressure) or 0, 0, 100)
	stats.CopycatIncidents = math.max(0, tonumber(stats.CopycatIncidents) or 0)
	stats.WorldReputationEvents = math.max(0, tonumber(stats.WorldReputationEvents) or 0)
	stats.ReputationCleanups = math.max(0, tonumber(stats.ReputationCleanups) or 0)
	stats.LastWorldReputationEvent = tostring(stats.LastWorldReputationEvent or "None")
	stats.PathReputation = math.clamp(tonumber(stats.PathReputation) or 0, 0, 100)
	stats.LifePath = tostring(stats.LifePath or "Undecided")
	stats.RetiredFromSorcery = stats.RetiredFromSorcery == true
	stats.RetirementAge = tonumber(stats.RetirementAge) or -1
	stats.RetirementYears = math.max(0, tonumber(stats.RetirementYears) or 0)
	stats.CivilianStability = math.clamp(tonumber(stats.CivilianStability) or 0, 0, 100)
	stats.RetirementRoute = tostring(stats.RetirementRoute or "None")
	stats.Affiliation = tostring(stats.Affiliation or (stats.InJujutsuHigh and "Jujutsu High" or "Unaffiliated"))
	stats.AffiliationRank = tostring(stats.AffiliationRank or (stats.InJujutsuHigh and "Student" or "None"))
	stats.AffiliationReputation = math.clamp(tonumber(stats.AffiliationReputation) or 0, 0, 100)
	stats.AffiliationDuties = math.max(0, tonumber(stats.AffiliationDuties) or 0)
	stats.JujutsuHighPopularity = math.clamp(tonumber(stats.JujutsuHighPopularity) or 0, 0, 100)
	stats.GoodwillWins = math.max(0, tonumber(stats.GoodwillWins) or 0)
	stats.TournamentRuns = math.max(0, tonumber(stats.TournamentRuns) or 0)
	stats.TournamentBestStreak = math.clamp(tonumber(stats.TournamentBestStreak) or 0, 0, 3)
	stats.TournamentsWon = math.max(0, tonumber(stats.TournamentsWon) or 0)
	stats.AssistantName = stats.AssistantName
	stats.AssistantTrust = math.clamp(tonumber(stats.AssistantTrust) or 0, 0, 100)
	stats.AssistantSkill = math.clamp(tonumber(stats.AssistantSkill) or 0, 0, 100)
	stats.TechniqueEvolutionStage = tostring(stats.TechniqueEvolutionStage or "Dormant")
	stats.TechniqueEvolutionProgress = math.clamp(tonumber(stats.TechniqueEvolutionProgress) or 0, 0, 100)
	stats.TechniqueBranch = tostring(stats.TechniqueBranch or "None")
	stats.TechniqueUsageCount = math.max(0, tonumber(stats.TechniqueUsageCount) or 0)
	stats.TechniqueMissionUses = math.max(0, tonumber(stats.TechniqueMissionUses) or 0)
	if typeof(stats.UnlockedExtensions) ~= "table" then stats.UnlockedExtensions = {} end
	if typeof(stats.SecretAchievements) ~= "table" then stats.SecretAchievements = {} end
	if typeof(stats.UnlockedPremiumClans) ~= "table" then stats.UnlockedPremiumClans = {} end
	if typeof(stats.UnlockedPremiumTechniques) ~= "table" then stats.UnlockedPremiumTechniques = {} end
	if typeof(stats.WorldHistory) ~= "table" then stats.WorldHistory = {} end
	if typeof(stats.NotableSorcerers) ~= "table" then stats.NotableSorcerers = {} end
	if typeof(stats.UnlockedTitles) ~= "table" then stats.UnlockedTitles = {} end
	if typeof(stats.CursedTools) ~= "table" then stats.CursedTools = {} end
	if stats.EquippedCursedToolId and not stats.CursedTools[stats.EquippedCursedToolId] then stats.EquippedCursedToolId = nil end
	if typeof(stats.ClanWarState) ~= "table" then stats.ClanWarState = {} end
	if typeof(stats.ClanWarHistory) ~= "table" then stats.ClanWarHistory = {} end
	stats.ClanWarWins = math.max(0, tonumber(stats.ClanWarWins) or 0)
	stats.ClanWarLosses = math.max(0, tonumber(stats.ClanWarLosses) or 0)
	stats.ClanWarActions = math.max(0, tonumber(stats.ClanWarActions) or 0)
	stats.ClanWarCooldown = math.max(0, tonumber(stats.ClanWarCooldown) or 0)

	if isCurseLife(stats) then
		stats.LifePath = "Cursed Spirit"
	elseif isCurseUser(stats) then
		stats.LifePath = "Curse User"
	elseif tostring(stats.LifePath or "") == "Rogue Sorcerer" or tostring(stats.SocietyStatus or "") == "Rogue Sorcerer" then
		stats.LifePath = "Rogue Sorcerer"
	elseif stats.ClanFounded == true then
		stats.LifePath = "Clan Founder"
	elseif stats.InJujutsuHigh == true then
		stats.LifePath = "Jujutsu High"
		stats.Affiliation = "Jujutsu High"
		if stats.AffiliationRank == "None" then
			stats.AffiliationRank = "Student"
		end
	elseif tostring(stats.Grade or "Non-Sorcerer") ~= "Non-Sorcerer" and stats.RegisteredSorcerer ~= true then
		stats.LifePath = "Unregistered Sorcerer"
	elseif stats.LifePath == "" then
		stats.LifePath = "Undecided"
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

function getWorldReputationTier(stats)
	local fame = tonumber(stats and stats.Fame) or 0
	local fear = tonumber(stats and stats.Fear) or 0
	local attention = tonumber(stats and stats.WorldAttention) or math.floor((fame + fear) / 2)
	local pressure = tonumber(stats and stats.WorldPressure) or fear
	local score = fame + fear + math.floor(attention * 0.5)

	if pressure >= 90 or (fear >= 80 and score >= 135) then
		return "Global Calamity"
	elseif fame >= 80 and fear >= 55 then
		return "Living Legend"
	elseif fear >= 65 and fear >= fame + 15 then
		return "Feared Threat"
	elseif fame >= 65 and fame >= fear + 15 then
		return "Public Legend"
	elseif score >= 115 then
		return "World Known"
	elseif score >= 70 then
		return "Regional Name"
	elseif score >= 30 then
		return "Local Rumor"
	end

	return "Unknown"
end

function refreshWorldReputationState(stats)
	if typeof(stats) ~= "table" then
		return "Unknown"
	end

	local fame = math.clamp(tonumber(stats.Fame) or 0, 0, 100)
	local fear = math.clamp(tonumber(stats.Fear) or 0, 0, 100)
	local wanted = math.max(0, tonumber(stats.WantedLevel) or 0)
	local path = math.clamp(tonumber(stats.PathReputation) or 0, 0, 100)
	local influence = math.clamp(tonumber(stats.SocietyInfluence) or 0, 0, 100)
	local curseThreat = math.max(0, tonumber(stats.CurseThreat) or 0)

	stats.Fame = fame
	stats.Fear = fear
	stats.WorldAttention = math.clamp(math.floor(((fame + fear) * 0.45) + (path * 0.2) + (influence * 0.2)), 0, 100)
	stats.WorldPressure = math.clamp(math.floor((fear * 0.7) + (wanted * 3) + (curseThreat * 0.15)), 0, 100)
	stats.WorldReputationTier = getWorldReputationTier(stats)
	return stats.WorldReputationTier
end

function adjustWorldReputation(stats, fameDelta, fearDelta, pathDelta)
	if typeof(stats) ~= "table" then
		return ""
	end

	normalizeCursedSocietyState(stats)
	local oldFame = tonumber(stats.Fame) or 0
	local oldFear = tonumber(stats.Fear) or 0
	local oldPath = tonumber(stats.PathReputation) or 0
	local oldTier = tostring(stats.WorldReputationTier or "Unknown")
	stats.Fame = math.clamp(oldFame + (tonumber(fameDelta) or 0), 0, 100)
	stats.Fear = math.clamp(oldFear + (tonumber(fearDelta) or 0), 0, 100)
	stats.PathReputation = math.clamp(oldPath + (tonumber(pathDelta) or 0), 0, 100)
	local newTier = refreshWorldReputationState(stats)

	local notes = {}
	if stats.Fame ~= oldFame then
		table.insert(notes, "Fame " .. (stats.Fame > oldFame and "+" or "") .. tostring(stats.Fame - oldFame))
	end
	if stats.Fear ~= oldFear then
		table.insert(notes, "Fear " .. (stats.Fear > oldFear and "+" or "") .. tostring(stats.Fear - oldFear))
	end
	if stats.PathReputation ~= oldPath then
		table.insert(notes, "Path " .. (stats.PathReputation > oldPath and "+" or "") .. tostring(stats.PathReputation - oldPath))
	end
	if newTier ~= oldTier then
		table.insert(notes, "World Tier: " .. tostring(newTier))
	end

	if #notes <= 0 then
		return ""
	end
	return "\n<font color='#f0b955'><b>[ REPUTATION ]</b></font> " .. table.concat(notes, " | ") .. "."
end

function applyYearlyWorldReputation(stats)
	if typeof(stats) ~= "table" then
		return ""
	end

	local oldTier = tostring(stats.WorldReputationTier or "Unknown")
	local fame = tonumber(stats.Fame) or 0
	local fear = tonumber(stats.Fear) or 0
	local wanted = tonumber(stats.WantedLevel) or 0
	local attention = tonumber(stats.WorldAttention) or 0

	if fame + fear >= 35 then
		stats.WorldAttention = math.clamp(attention + math.random(0, 2), 0, 100)
	elseif attention > 0 then
		stats.WorldAttention = math.max(0, attention - 1)
	end

	if fear >= 45 or wanted >= 3 then
		stats.WorldPressure = math.clamp((tonumber(stats.WorldPressure) or 0) + math.random(0, 2), 0, 100)
	elseif (tonumber(stats.WorldPressure) or 0) > 0 then
		stats.WorldPressure = math.max(0, (tonumber(stats.WorldPressure) or 0) - 1)
	end

	local newTier = refreshWorldReputationState(stats)
	local notes = {}
	if newTier ~= oldTier then
		table.insert(notes, "your name is now considered <b>" .. tostring(newTier) .. "</b>")
	end

	local age = tonumber(stats.Age) or 0
	local pressure = tonumber(stats.WorldPressure) or 0
	local publicSupport = tonumber(stats.PublicSupport) or 0
	local hunterPressure = tonumber(stats.HunterPressure) or 0
	local copycats = math.max(0, tonumber(stats.CopycatIncidents) or 0)

	if publicSupport > 0 and fame < 45 and math.random(1, 100) <= 35 then
		local supportFade = math.min(publicSupport, math.random(1, 3))
		stats.PublicSupport = math.max(0, publicSupport - supportFade)
		publicSupport = stats.PublicSupport
		if supportFade > 0 then
			table.insert(notes, "some public support cooled as your name left headlines")
		end
	end

	if hunterPressure > 0 and fear < 45 and wanted < 3 and pressure < 55 then
		local hunterDrop = math.min(hunterPressure, math.random(1, 3))
		stats.HunterPressure = math.max(0, hunterPressure - hunterDrop)
		hunterPressure = stats.HunterPressure
		if hunterDrop > 0 then
			table.insert(notes, "hunter attention cooled slightly")
		end
	end

	if copycats > 0 and pressure < 50 and math.random(1, 100) <= 30 then
		stats.CopycatIncidents = math.max(0, copycats - 1)
		copycats = stats.CopycatIncidents
		table.insert(notes, "one copycat rumor faded from public attention")
	end

	if age >= 16 then
		if (tonumber(stats.WorldAttention) or 0) >= 55 and math.random(1, 100) <= 25 then
			stats.SocietyRecognition = math.clamp((tonumber(stats.SocietyRecognition) or 0) + 1, 0, 100)
			table.insert(notes, "Jujutsu society keeps records of your public presence")
		end

		if pressure >= 65 and math.random(1, 100) <= 20 then
			stats.CursedResentment = math.clamp((tonumber(stats.CursedResentment) or 0) + 1, 0, 100)
			table.insert(notes, "hostile attention tightens around your cursed energy")
		end

		local incidentChance = 0
		if newTier == "Public Legend" then
			incidentChance = 22
		elseif newTier == "Feared Threat" then
			incidentChance = 28
		elseif newTier == "Living Legend" then
			incidentChance = 34
		elseif newTier == "Global Calamity" then
			incidentChance = 45
		elseif newTier == "World Known" then
			incidentChance = 16
		elseif newTier == "Regional Name" then
			incidentChance = 8
		end

		if incidentChance > 0 and math.random(1, 100) <= incidentChance then
			stats.WorldReputationEvents = math.max(0, tonumber(stats.WorldReputationEvents) or 0) + 1
			if newTier == "Public Legend" then
				local supportGain = math.random(3, 8)
				stats.PublicSupport = math.clamp(publicSupport + supportGain, 0, 100)
				stats.Money = math.max(0, (tonumber(stats.Money) or 0) + math.random(400, 1200))
				stats.SocietyRecognition = math.clamp((tonumber(stats.SocietyRecognition) or 0) + math.random(1, 3), 0, 100)
				stats.LastWorldReputationEvent = "Public Support"
				table.insert(notes, "supporters sent tips, money, and protection offers")
			elseif newTier == "Feared Threat" then
				local hunterGain = math.random(4, 10)
				stats.HunterPressure = math.clamp(hunterPressure + hunterGain, 0, 100)
				stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + math.random(1, 3), 0, 100)
				stats.ExorcismRisk = math.clamp((tonumber(stats.ExorcismRisk) or 0) + math.random(2, 6), 0, 100)
				stats.LastWorldReputationEvent = "Hunter Pressure"
				table.insert(notes, "hunter networks traded your name and raised pressure around you")
			elseif newTier == "Living Legend" then
				if math.random(1, 100) <= 55 then
					stats.PublicSupport = math.clamp(publicSupport + math.random(2, 6), 0, 100)
					stats.SocietyInfluence = math.clamp((tonumber(stats.SocietyInfluence) or 0) + math.random(1, 3), 0, 100)
					stats.LastWorldReputationEvent = "Legendary Patronage"
					table.insert(notes, "patrons and society contacts leaned toward your legend")
				else
					stats.CopycatIncidents = math.max(0, tonumber(stats.CopycatIncidents) or 0) + 1
					stats.WorldPressure = math.clamp(pressure + math.random(2, 5), 0, 100)
					stats.LastWorldReputationEvent = "Copycat Incident"
					table.insert(notes, "copycats used your name and made the world less stable")
				end
			elseif newTier == "Global Calamity" then
				stats.HunterPressure = math.clamp(hunterPressure + math.random(6, 12), 0, 100)
				stats.WorldPressure = math.clamp(pressure + math.random(4, 9), 0, 100)
				stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + math.random(2, 5), 0, 100)
				stats.CursedResentment = math.clamp((tonumber(stats.CursedResentment) or 0) + math.random(1, 4), 0, 100)
				stats.LastWorldReputationEvent = "Global Suppression Order"
				table.insert(notes, "a suppression order moved through society channels")
			elseif fame >= fear then
				stats.PublicSupport = math.clamp(publicSupport + math.random(1, 4), 0, 100)
				stats.LastWorldReputationEvent = "Local Support"
				table.insert(notes, "local civilians quietly supported your work")
			else
				stats.HunterPressure = math.clamp(hunterPressure + math.random(1, 4), 0, 100)
				stats.LastWorldReputationEvent = "Local Suspicion"
				table.insert(notes, "local watchers began tracking your movements")
			end
		end
	end

	refreshWorldReputationState(stats)
	if #notes <= 0 then
		return ""
	end

	return "\n<font color='#f0b955'><b>[ WORLD ]</b></font> " .. table.concat(notes, "; ") .. "."
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


----------------------------------------------------------------
-- CHARACTER CUSTOMIZATION FOUNDATION
----------------------------------------------------------------
-- These are intentionally top-level/non-local because this GameManager is already
-- register-limit sensitive. Keep this system compact and server-authoritative.
--
-- Update 6.1:
--   Page 1 = Identity / appearance.
--   Page 2 = Birth path choices.
--   The client can show multiple pages, but the server only saves after the final submit.

CHARACTER_CUSTOMIZATION_OPTIONS = {
	Gender = { "Male", "Female" },

	HairColor = {
		"Black", "Brown", "Dark Brown", "Blonde", "White", "Silver",
		"Red", "Blue-Black", "Ash Gray", "Pink", "Purple", "Green", "Blue", "Orange"
	},

	EyeColor = {
		"Brown", "Black", "Blue", "Green", "Gray", "Gold",
		"Violet", "Red", "Hazel", "Silver"
	},

	SkinTone = {
		"Pale", "Fair", "Light Tan", "Tan", "Brown", "Dark"
	},

	Height = {
		"Short", "Below Average", "Average", "Above Average", "Tall"
	},

	Build = {
		"Slim", "Lean", "Average", "Athletic", "Muscular"
	},

	Feature = {
		"None", "Sharp Eyes", "Tired Eyes", "Beauty Mark", "Scar Under Eye",
		"Burn Mark", "Cold Expression", "Gentle Expression", "Resting Scowl"
	},

	AuraColor = {
		"Blue", "Red", "Purple", "Black", "White", "Gold", "Green", "Silver",
		"Cyan", "Crimson", "Indigo", "Violet", "Ash Gray", "Pale Blue",
		"Deep Red", "Emerald", "Rose", "Amber"
	},

	OriginLocation = {
		"Tokyo", "Kyoto", "Osaka", "Sendai", "Yokohama", "Sapporo",
		"Nagoya", "Fukuoka", "Kobe", "Nara", "Okinawa",
		"Shibuya", "Shinjuku", "Roppongi", "Akihabara", "Ikebukuro",
		"Ueno", "Kamakura", "Yokosuka", "Chiba", "Saitama",
		"Kawasaki", "Hiroshima", "Nagasaki", "Kumamoto", "Kagoshima",
		"Kanazawa", "Niigata", "Nagano", "Hakone", "Aomori",
		"Kurashiki", "Matsuyama", "Miyazaki", "Beppu", "Tsukuba",
		"Ise", "Koyasan", "Hokkaido Countryside", "Kyoto Outskirts",
		"Tokyo Outskirts", "Unnamed Rural Village"
	},

	Era = {
		"Modern Era", "Edo Era", "Heian Era", "Collapse Era"
	},

	Upbringing = {
		"Normal Household", "Sorcerer Household", "Strict Clan Home", "Orphaned",
		"Shrine Raised", "Street Kid", "Rural Family", "Hidden Bloodline"
	},

	EarlyCurseExposure = {
		"Low", "Moderate", "High", "Traumatic"
	},

	Temperament = {
		"Calm", "Ambitious", "Reckless", "Kind", "Cold", "Proud",
		"Curious", "Stoic"
	},

	LifeGoal = {
		"Peace", "Power", "Family", "Revenge", "Recognition", "Freedom",
		"Mastery", "Control"
	}
}

CHARACTER_CUSTOMIZATION_DEFAULTS = {
	HairColor = "Black",
	EyeColor = "Brown",
	SkinTone = "Fair",
	Height = "Average",
	Build = "Lean",
	Feature = "None",
	AuraColor = "Blue",
	OriginLocation = "Tokyo"
}

CHARACTER_BIRTH_PATH_DEFAULTS = {
	Era = "Modern Era",
	Upbringing = "Normal Household",
	EarlyCurseExposure = "Moderate",
	Temperament = "Calm",
	LifeGoal = "Power",
	BirthYear = ""
}

-- Update 6: Era year anchors.
-- Age 0 starts at the first year of the selected era, then normal aging adds years from there.
-- Modern intentionally stays at 2000 to preserve the original BitKaisen timeline behavior.
CHARACTER_ERA_START_YEARS = {
	["Modern Era"] = 2000,
	["Edo Era"] = 1603,
	["Heian Era"] = 794,
	["Collapse Era"] = 2018,
}

-- Update 6: live era timeline.
-- BirthEra is the era the life started in.
-- CurrentEra is the era the character is currently living through.
-- Era is kept as the current active era for old UI/modules that read stats.Era.
CHARACTER_ERA_TIMELINE = {
	{ Name = "Heian Era", StartYear = 794 },
	{ Name = "Edo Era", StartYear = 1603 },
	{ Name = "Modern Era", StartYear = 2000 },
	{ Name = "Collapse Era", StartYear = 2018 },
}

CHARACTER_GOD_MODE_BIRTH_PATH_FIELDS = {
	EarlyCurseExposure = true,
	Temperament = true,
	LifeGoal = true,
	BirthYear = true
}

function getEraStartYearFromName(eraName)
	local era = tostring(eraName or "Modern Era")
	return CHARACTER_ERA_START_YEARS[era] or CHARACTER_ERA_START_YEARS["Modern Era"] or 2000
end

function getEraForYear(year)
	local numericYear = tonumber(year) or CHARACTER_ERA_START_YEARS["Modern Era"] or 2000
	local currentEra = "Modern Era"

	for _, eraData in ipairs(CHARACTER_ERA_TIMELINE) do
		if numericYear >= eraData.StartYear then
			currentEra = eraData.Name
		else
			break
		end
	end

	return currentEra
end

function getEraTransitionFlavor(previousEra, newEra)
	previousEra = tostring(previousEra or "Unknown Era")
	newEra = tostring(newEra or "Modern Era")

	if previousEra == "Heian Era" and newEra == "Edo Era" then
		return "The violent golden age of jujutsu faded into clan rule, secrecy, and political survival."
	elseif previousEra == "Edo Era" and newEra == "Modern Era" then
		return "The old houses survived into a world of schools, records, missions, and hidden bureaucracy."
	elseif previousEra == "Modern Era" and newEra == "Collapse Era" then
		return "Cursed energy began spilling into ordinary society. Even civilians started noticing what should have stayed hidden."
	elseif newEra == "Collapse Era" then
		return "The world shifted into a cursed collapse where old rules stopped protecting anyone."
	end

	return "History moved forward, and the rules of the cursed world changed around you."
end

function registerEraTransition(stats)
	if typeof(stats) ~= "table" then
		return ""
	end

	local year = getCurrentYear(stats)
	local newEra = getEraForYear(year)
	local previousEra = tostring(stats.CurrentEra or stats.Era or newEra)

	if previousEra == newEra then
		stats.CurrentEra = newEra
		stats.Era = newEra
		return ""
	end

	stats.PreviousEra = previousEra
	stats.CurrentEra = newEra
	stats.Era = newEra
	stats.EraTransitions = math.max(0, tonumber(stats.EraTransitions) or 0) + 1
	stats.EraHistory = typeof(stats.EraHistory) == "table" and stats.EraHistory or {}

	table.insert(stats.EraHistory, {
		From = previousEra,
		To = newEra,
		Year = year,
		Age = tonumber(stats.Age) or 0,
		Month = tonumber(stats.CurrentMonth) or 1,
	})

	return "<font color='#ffcd69'><b>[ ERA SHIFT ]</b></font> The year is now <b>" .. tostring(year) .. "</b>. Your life has crossed from <b>" .. previousEra .. "</b> into the <b>" .. newEra .. "</b>. " .. getEraTransitionFlavor(previousEra, newEra)
end

function ensureEraYearState(stats, forceResetBirthYear)
	if typeof(stats) ~= "table" then
		return
	end

	local birthPath = typeof(stats.BirthPath) == "table" and stats.BirthPath or nil
	local legacyBirthYear = tonumber(stats.BirthYear)
	if stats.LegacyTimelineLocked == true and legacyBirthYear ~= nil then
		stats.BirthYear = legacyBirthYear
		stats.EraStartYear = legacyBirthYear
		stats.CurrentYear = legacyBirthYear + (tonumber(stats.Age) or 0)

		local activeEra = getEraForYear(stats.CurrentYear)
		stats.CurrentEra = activeEra
		stats.Era = activeEra
		stats.BirthEra = tostring(stats.BirthEra or activeEra)
		if birthPath then
			birthPath.Era = stats.BirthEra
		end
		stats.EraHistory = typeof(stats.EraHistory) == "table" and stats.EraHistory or {}
		stats.EraTransitions = math.max(0, tonumber(stats.EraTransitions) or 0)
		return
	end

	local birthEra = tostring(stats.BirthEra or (birthPath and birthPath.Era) or stats.Era or "Modern Era")

	if not characterCustomizationValueAllowed("Era", birthEra) then
		birthEra = "Modern Era"
	end

	stats.BirthEra = birthEra
	stats.EraStartYear = getEraStartYearFromName(birthEra)

	local currentBirthYear = tonumber(stats.BirthYear)
	if forceResetBirthYear == true or currentBirthYear == nil then
		stats.BirthYear = stats.EraStartYear
	else
		stats.BirthYear = currentBirthYear
	end

	stats.CurrentYear = stats.BirthYear + (tonumber(stats.Age) or 0)

	local activeEra = getEraForYear(stats.CurrentYear)
	stats.CurrentEra = tostring(stats.CurrentEra or activeEra)

	-- On old saves, the stored current era may be stale. Sync silently on load.
	-- Actual player-facing transition logs are handled by registerEraTransition during aging.
	if stats.CurrentEra ~= activeEra then
		stats.CurrentEra = activeEra
	end

	stats.Era = stats.CurrentEra
	stats.EraHistory = typeof(stats.EraHistory) == "table" and stats.EraHistory or {}
	stats.EraTransitions = math.max(0, tonumber(stats.EraTransitions) or 0)
end
function characterCustomizationValueAllowed(key, value)
	local list = CHARACTER_CUSTOMIZATION_OPTIONS[key]
	if typeof(list) ~= "table" then
		return false
	end

	for _, option in ipairs(list) do
		if option == value then
			return true
		end
	end

	return false
end

function sanitizeCharacterName(rawName)
	local text = tostring(rawName or "")
	text = text:gsub("<[^>]->", "")
	text = text:gsub("[\n\r\t]", " ")
	text = text:gsub("[^%a%-']", "")
	text = text:gsub("^%s+", "")
	text = text:gsub("%s+$", "")

	if #text > 16 then
		text = string.sub(text, 1, 16)
	end

	if text == "" or text == "Unknown" then
		text = "Ren"
	end

	local first = string.sub(text, 1, 1)
	local rest = string.sub(text, 2)

	return string.upper(first) .. string.lower(rest)
end

local function normalizeNameForModeration(rawText)
	local text = tostring(rawText or "")
	text = string.lower(text)
	text = text:gsub("<[^>]->", "")
	text = text:gsub("[\n\r\t]", " ")
	text = text:gsub("[^%a]", "")
	return text
end

local function buildBlockedWord(byteList)
	local chars = {}

	for _, byteValue in ipairs(byteList) do
		table.insert(chars, string.char(byteValue))
	end

	return table.concat(chars)
end

local HARD_BLOCKED_NAME_WORDS = {
	-- Common racial slur variants. Stored as byte codes so the source does not visibly print the slurs.
	buildBlockedWord({110, 105, 103, 103, 101, 114}),
	buildBlockedWord({110, 105, 103, 103, 97}),
	buildBlockedWord({110, 105, 103, 108, 101, 116}),
}

local HARD_BLOCKED_EXACT_NAME_WORDS = {
	-- Short profanity should be exact-match only so normal names are not caught by substrings.
	buildBlockedWord({97, 115, 115}),
	buildBlockedWord({102, 117, 99, 107}),
	buildBlockedWord({115, 104, 105, 116}),
	buildBlockedWord({98, 105, 116, 99, 104}),
	buildBlockedWord({99, 117, 110, 116}),
	buildBlockedWord({100, 105, 99, 107}),
	buildBlockedWord({99, 111, 99, 107}),
	buildBlockedWord({112, 117, 115, 115, 121}),
	buildBlockedWord({119, 104, 111, 114, 101}),
	buildBlockedWord({115, 108, 117, 116}),
	-- Common leetspeak/spaced variants collapse during normalization.
	buildBlockedWord({102, 117, 99, 107, 101, 114}),
	buildBlockedWord({97, 115, 115, 104, 111, 108, 101}),
	buildBlockedWord({109, 111, 116, 104, 101, 114, 102, 117, 99, 107, 101, 114}),
}

local HARD_BLOCKED_SUBSTRING_NAME_WORDS = {
	-- Longer composites collapse during normalization, including spaced/punctuated variants.
	buildBlockedWord({102, 117, 99, 107}),
}

local CHARACTER_NAME_FILTER_FALLBACKS = {
	"Ren", "Akio", "Kaito", "Riku", "Sora", "Yuto", "Shin", "Rei",
	"Mizuki", "Airi", "Hana", "Yuna", "Emi", "Saki", "Rina", "Mei",
}

local function getSafeFallbackFirstName(rawText)
	local compact = normalizeNameForModeration(rawText)
	local index = (#compact % #CHARACTER_NAME_FILTER_FALLBACKS) + 1
	return CHARACTER_NAME_FILTER_FALLBACKS[index] or "Ren"
end

local function isHardBlockedCharacterName(rawText)
	local compact = normalizeNameForModeration(rawText)

	if compact == "" then
		return false
	end

	for _, blockedWord in ipairs(HARD_BLOCKED_EXACT_NAME_WORDS) do
		if blockedWord ~= "" and compact == blockedWord then
			return true
		end
	end

	for _, blockedWord in ipairs(HARD_BLOCKED_SUBSTRING_NAME_WORDS) do
		if blockedWord ~= "" and string.find(compact, blockedWord, 1, true) then
			return true
		end
	end

	for _, blockedWord in ipairs(HARD_BLOCKED_NAME_WORDS) do
		if blockedWord ~= "" and string.find(compact, blockedWord, 1, true) then
			return true
		end
	end

	return false
end

function filterCharacterFirstName(player, rawName)
	local rawText = tostring(rawName or "")
	rawText = rawText:gsub("<[^>]->", "")
	rawText = rawText:gsub("[\n\r\t]", " ")
	rawText = rawText:gsub("^%s+", "")
	rawText = rawText:gsub("%s+$", "")

	if rawText == "" then
		return false, nil, "Enter a first name."
	end

	if #rawText > 24 then
		return false, nil, "Name is too long."
	end

	if rawText:find("%d") then
		return false, nil, "Names cannot contain numbers."
	end

	-- Do this BEFORE sanitizing and BEFORE Roblox filtering.
	-- Roblox filtering can miss things in Studio, so the server hard-blocks obvious bad names too.
	if isHardBlockedCharacterName(rawText) then
		return false, nil, "That name is not allowed."
	end

	local sanitized = sanitizeCharacterName(rawText)

	if sanitized == "" or sanitized == "Unknown" or #sanitized < 2 then
		return false, nil, "Enter a valid first name."
	end

	if isHardBlockedCharacterName(sanitized) then
		return false, nil, "That name is not allowed."
	end

	local function filterForBroadcast(textToFilter)
		local ok, filtered = pcall(function()
			local filterResult = TextService:FilterStringAsync(textToFilter, player.UserId)
			return filterResult:GetNonChatStringForBroadcastAsync()
		end)

		if not ok then
			ok, filtered = pcall(function()
				return Chat:FilterStringForBroadcast(textToFilter, player)
			end)
		end

		if not ok then
			warn("[GameManager] Character name filter failed:", filtered)
			return nil
		end

		filtered = tostring(filtered or "")
		filtered = filtered:gsub("<[^>]->", "")
		filtered = filtered:gsub("[\n\r\t]", " ")
		filtered = filtered:gsub("^%s+", "")
		filtered = filtered:gsub("%s+$", "")

		return filtered
	end

	local rawFiltered = filterForBroadcast(rawText)
	if not rawFiltered or rawFiltered == "" or string.find(rawFiltered, "#") or isHardBlockedCharacterName(rawFiltered) then
		return true, getSafeFallbackFirstName(rawText), "Roblox name filtering rejected that name, so a safe default name was used."
	end

	local cleanFiltered = filterForBroadcast(sanitized)
	if not cleanFiltered or cleanFiltered == "" or string.find(cleanFiltered, "#") or isHardBlockedCharacterName(cleanFiltered) then
		return true, getSafeFallbackFirstName(rawText), "Roblox name filtering rejected that name, so a safe default name was used."
	end

	local finalName = sanitizeCharacterName(cleanFiltered)

	if finalName == "" or finalName == "Unknown" or #finalName < 2 then
		return false, nil, "That name was blocked by Roblox filtering."
	end

	if isHardBlockedCharacterName(finalName) then
		return false, nil, "That name is not allowed."
	end

	return true, sanitized
end

function ensureCharacterAppearance(stats)
	if typeof(stats) ~= "table" then
		return
	end

	stats.Appearance = typeof(stats.Appearance) == "table" and stats.Appearance or {}

	for key, defaultValue in pairs(CHARACTER_CUSTOMIZATION_DEFAULTS) do
		local value = tostring(stats.Appearance[key] or stats[key] or defaultValue)

		if not characterCustomizationValueAllowed(key, value) then
			value = defaultValue
		end

		stats.Appearance[key] = value
	end

	stats.BirthPath = typeof(stats.BirthPath) == "table" and stats.BirthPath or {}

	for key, defaultValue in pairs(CHARACTER_BIRTH_PATH_DEFAULTS) do
		local value = tostring(stats.BirthPath[key] or stats[key] or defaultValue)

		if key == "BirthYear" then
			local birthYear = tonumber(value)
			value = birthYear and tostring(math.clamp(math.floor(birthYear), 900, 2200)) or ""
		elseif not characterCustomizationValueAllowed(key, value) then
			value = defaultValue
		end

		stats.BirthPath[key] = value
	end
	if stats.BirthPath.BirthYear ~= "" then
		stats.BirthPath.Era = getEraForYear(tonumber(stats.BirthPath.BirthYear))
	end

	-- Keep top-level mirrors for simple UI / future systems without breaking existing saves.
	stats.Era = stats.BirthPath.Era
	stats.Upbringing = stats.BirthPath.Upbringing
	stats.EarlyCurseExposure = stats.BirthPath.EarlyCurseExposure
	stats.Temperament = stats.BirthPath.Temperament
	stats.LifeGoal = stats.BirthPath.LifeGoal
	ensureEraYearState(stats, false)

	-- Do not force Cursed Spirit / legacy "Unknown" genders into Male/Female.
	-- The customization popup itself only submits Male/Female, but load defaults should preserve old special cases.
	local gender = tostring(stats.Gender or "Unknown")
	if gender ~= "Male" and gender ~= "Female" and gender ~= "Unknown" then
		gender = "Unknown"
	end
	stats.Gender = gender

	if not stats.FirstName or tostring(stats.FirstName) == "" then
		stats.FirstName = "Ren"
	end

	stats.CharacterCustomized = stats.CharacterCustomized == true
end

local function applyUpbringingStartModifiers(stats)
	if typeof(stats) ~= "table" or stats.UpbringingModifiersApplied == true then
		return
	end
	stats.UpbringingModifiersApplied = true
	local upbringing = tostring(stats.Upbringing or (stats.BirthPath and stats.BirthPath.Upbringing) or "Normal Household")
	if upbringing == "Clan Household" then
		stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + 8)
		stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + 2, 0, 100)
		stats.Reputation = (tonumber(stats.Reputation) or 0) + 3
	elseif upbringing == "Orphanage" then
		stats.Smarts = math.clamp((tonumber(stats.Smarts) or 0) + 4, 0, 100)
		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - 5, 0, 100)
		stats.Strength = math.max(0, (tonumber(stats.Strength) or 0) + 4)
	elseif upbringing == "Street Kid" then
		stats.Strength = math.max(0, (tonumber(stats.Strength) or 0) + 10)
		stats.Smarts = math.clamp((tonumber(stats.Smarts) or 0) + 2, 0, 100)
		stats.Health = math.clamp((tonumber(stats.Health) or 100) - 4, 0, 100)
	elseif upbringing == "Shrine Raised" then
		stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + 6)
		stats.Smarts = math.clamp((tonumber(stats.Smarts) or 0) + 4, 0, 100)
		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - 2, 0, 100)
	else
		stats.Looks = math.clamp((tonumber(stats.Looks) or 50) + 2, 0, 100)
		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) + 2, 0, 100)
	end
end

function applyCharacterCustomization(player, payload)
	if not player then
		return { Success = false, Message = "No player." }
	end

	if not checkRateLimit(player, "SubmitCharacterCustomization") then
		return { Success = false, Message = "Slow down." }
	end

	local stats = playerLives[player.UserId]
	if not stats or stats.Alive == false then
		return { Success = false, Message = "No active life." }
	end

	local hadLegacyTimeline = stats.LegacyTimelineLocked == true

	if typeof(payload) ~= "table" then
		return { Success = false, Message = "Invalid data." }
	end

	local nameOk, firstName, nameError = filterCharacterFirstName(player, payload.FirstName)
	if not nameOk then
		return { Success = false, Message = nameError or "Name blocked." }
	end

	local gender = tostring(payload.Gender or stats.Gender or "Male")
	if not characterCustomizationValueAllowed("Gender", gender) then
		gender = "Male"
	end

	local incomingAppearance = typeof(payload.Appearance) == "table" and payload.Appearance or {}
	local appearance = {}

	for key, defaultValue in pairs(CHARACTER_CUSTOMIZATION_DEFAULTS) do
		local value = tostring(incomingAppearance[key] or defaultValue)

		if not characterCustomizationValueAllowed(key, value) then
			value = defaultValue
		end

		appearance[key] = value
	end

	local incomingBirthPath = typeof(payload.BirthPath) == "table" and payload.BirthPath or {}
	local birthPath = {}
	local hasGodMode = ownsGodModePass(player)
	stats.HasGodModePass = hasGodMode == true

	for key, defaultValue in pairs(CHARACTER_BIRTH_PATH_DEFAULTS) do
		local value = tostring(incomingBirthPath[key] or defaultValue)

		if key == "BirthYear" then
			if hasGodMode == true then
				local birthYear = tonumber(value)
				value = birthYear and tostring(math.clamp(math.floor(birthYear), 900, 2200)) or ""
			else
				value = ""
			end
		elseif not characterCustomizationValueAllowed(key, value) then
			value = defaultValue
		end

		if CHARACTER_GOD_MODE_BIRTH_PATH_FIELDS[key] == true and hasGodMode ~= true then
			value = defaultValue
		end

		birthPath[key] = value
	end
	if birthPath.BirthYear ~= "" then
		birthPath.Era = getEraForYear(tonumber(birthPath.BirthYear))
	end

	stats.FirstName = firstName
	stats.Gender = gender
	stats.Appearance = appearance
	stats.BirthPath = birthPath
	stats.CharacterCustomized = true

	-- Top-level mirrors for future event filters / UI without forcing other systems to dig into BirthPath.
	stats.BirthEra = birthPath.Era
	stats.Era = birthPath.Era
	stats.CurrentEra = birthPath.Era
	stats.Upbringing = birthPath.Upbringing
	stats.EarlyCurseExposure = birthPath.EarlyCurseExposure
	stats.Temperament = birthPath.Temperament
	stats.LifeGoal = birthPath.LifeGoal
	if birthPath.BirthYear ~= "" then
		stats.BirthYear = tonumber(birthPath.BirthYear)
		stats.EraStartYear = stats.BirthYear
		stats.LegacyTimelineLocked = true
	else
		-- Heirs arrive here with LegacyTimelineLocked already set by preserveLegacyTimeline
		-- (BitKaisenLegacy.luau). Without an explicit custom BirthYear, keep that lock so
		-- ensureEraYearState doesn't force-reset the inherited timeline back to era start.
		stats.LegacyTimelineLocked = hadLegacyTimeline
	end
	stats.UpbringingModifiersApplied = false
	applyUpbringingStartModifiers(stats)
	ensureEraYearState(stats, true)

	local familyName = tostring(stats.FamilyName or "")
	if familyName ~= "" and familyName ~= "Unknown" and familyName ~= "None" then
		stats.Name = firstName .. " " .. familyName
	else
		stats.Name = firstName
	end

	fireLifeUpdate(
		player,
		stats,
		"<font color='#b27aff'><b>[ CHARACTER ]</b></font> Your birth profile has been set: <b>" .. tostring(stats.Name) .. "</b>. Era: <b>" .. tostring(birthPath.Era) .. "</b>. Start Year: <b>" .. tostring(stats.BirthYear or getEraStartYearFromName(birthPath.Era)) .. "</b>.",
		false
	)

	-- saveStats is declared later as a local in this mega-script, so this early helper
	-- must use the global forceSaveStats boundary save instead of calling a nil global saveStats.
	if type(forceSaveStats) == "function" then
		forceSaveStats(player, "CharacterCustomization")
	end

	return { Success = true, Stats = stats }
end

function ensureExtraStats(stats)
	stats.Name = stats.Name or "Unknown"
	stats.FirstName = stats.FirstName or "Unknown"
	stats.FamilyName = stats.FamilyName or "Unknown"
	stats.FamilyType = stats.FamilyType or "Unknown"
	stats.Gender = stats.Gender == "Female" and "Female" or (stats.Gender == "Male" and "Male" or "Unknown")

	stats.CurrentMonth = math.clamp(tonumber(stats.CurrentMonth) or 1, 1, 12)
	stats.MonthsIntoAge = math.clamp(tonumber(stats.MonthsIntoAge) or 0, 0, 11)
	ensureEraYearState(stats, false)

	stats.Speed = math.max(0, math.min(100, tonumber(stats.Speed) or 0))
	stats.Durability = math.max(0, math.min(100, tonumber(stats.Durability) or 0))
	stats.Damage = math.max(0, math.min(100, tonumber(stats.Damage) or 0))
	stats.CEEfficiency = math.max(0, math.min(100, tonumber(stats.CEEfficiency) or 0))
	stats.Money = math.floor((tonumber(stats.Money) or 0) * 100 + 0.5) / 100
	stats.AFKStabilizationUnlocked = stats.AFKStabilizationUnlocked == true
	stats.AFKStabilizationEarned = math.max(0, math.floor((tonumber(stats.AFKStabilizationEarned) or 0) * 100 + 0.5) / 100)
	stats.AFKStabilizationSessions = math.max(0, tonumber(stats.AFKStabilizationSessions) or 0)
	stats.Reputation = stats.Reputation or 0
	stats.TeacherRecommendations = stats.TeacherRecommendations or 0
	stats.MissionsCompleted = stats.MissionsCompleted or 0
	stats.MissionsFailed = stats.MissionsFailed or 0
	stats.TechniqueMastery = math.clamp(stats.TechniqueMastery or 0, 0, 100)
	stats.RCTRevives = math.max(0, tonumber(stats.RCTRevives) or 0)
	stats.RCTReviveMaxPerLife = RCT_REVIVE_MAX_PER_LIFE
	stats.RCTSecondChances = math.max(0, tonumber(stats.RCTSecondChances) or 0)
	stats.RCTOldAgeYearsRemaining = math.max(0, tonumber(stats.RCTOldAgeYearsRemaining) or 0)
	stats.LastRCTOldAgeExtensionYears = math.max(0, tonumber(stats.LastRCTOldAgeExtensionYears) or 0)
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
	stats.CEAddiction = math.clamp(tonumber(stats.CEAddiction) or 0, 0, 100)
	stats.HiddenKarma = math.clamp(tonumber(stats.HiddenKarma) or 0, -100, 100)
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
	stats.MetaProgress.GroupJoinRewardClaimed = stats.MetaProgress.GroupJoinRewardClaimed == true
	stats.MetaProgress.FreeMasteryBoostClaimed = stats.MetaProgress.FreeMasteryBoostClaimed == true

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
	stats.Codes.GroupVerified = stats.Codes.GroupVerified == true
	stats.CodeGroupVerified = stats.CodeGroupVerified == true or stats.Codes.GroupVerified == true

	-- Purchase flags for one-time per-life products.
	-- Developer products can technically be bought repeatedly by Roblox,
	-- so anything meant to behave like a one-time pack must be blocked by our own save data too.
	stats.Purchases = stats.Purchases or {}
	stats.Purchases.StarterSorcererPackClaimed = stats.Purchases.StarterSorcererPackClaimed == true
	stats.Purchases.GroupJoinRewardClaimed = stats.Purchases.GroupJoinRewardClaimed == true or stats.MetaProgress.GroupJoinRewardClaimed == true

	if stats.Purchases.GroupJoinRewardClaimed == true then
		stats.MetaProgress.GroupJoinRewardClaimed = true
	end

	stats.Settings = stats.Settings or {}

	local defaultSettings = {
		MusicVolume = 1,
		SFXVolume = 1,

		MuteMusic = false,
		MuteSFX = false,

		FastText = false,
		HighContrastText = false,
		ReducedMotion = false,
		ScreenShake = true,
		SkipCombatSkillChecks = false,
		UIMode = "",
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
	stats.Settings.SkipCombatSkillChecks = stats.Settings.SkipCombatSkillChecks == true

	if stats.Settings.UIMode ~= "Computer" and stats.Settings.UIMode ~= "Mobile" and stats.Settings.UIMode ~= "" then
		stats.Settings.UIMode = ""
	end

	local age = tonumber(stats.Age) or 0
	if stats.SchoolStage == nil then
		if age >= 16 then
			stats.SchoolStage = "Graduated"
			stats.GraduatedSchool = true
		elseif age >= 14 then
			stats.SchoolStage = "High"
		elseif age >= 11 then
			stats.SchoolStage = "Middle"
		elseif age >= 6 then
			stats.SchoolStage = "Elementary"
		else
			stats.SchoolStage = "None"
		end
	end
	stats.SchoolPerformance = math.clamp(tonumber(stats.SchoolPerformance) or 50, 0, 100)
	stats.SchoolAttendance = math.clamp(tonumber(stats.SchoolAttendance) or 100, 0, 100)
	stats.ReportCardGrade = tostring(stats.ReportCardGrade or "N/A")
	stats.GraduatedSchool = stats.GraduatedSchool == true
	stats.SchoolClub = tostring(stats.SchoolClub or "None")

	stats.GraduatedJujutsuHigh = stats.GraduatedJujutsuHigh == true
	stats.IsJujutsuMentor = stats.IsJujutsuMentor == true
	stats.MentorRank = tostring(stats.MentorRank or "None")
	stats.MentorXP = math.max(0, tonumber(stats.MentorXP) or 0)
	stats.MentorIncome = math.max(0, tonumber(stats.MentorIncome) or 0)
	stats.StudentsMentored = math.max(0, tonumber(stats.StudentsMentored) or 0)
	stats.MentorApplicationCooldown = math.max(0, tonumber(stats.MentorApplicationCooldown) or 0)

	ensureCharacterAppearance(stats)
	BitKaisenTraits.EnsureTraits(stats)
	ensureSorcererRegistrationState(stats)
	BitKaisenRelationships.EnsureRelationships(stats)
	ensureTraitState(stats)
	syncFamilyStatus(stats)
end

local saveStats

local SECRET_BIRTH_EASTER_EGGS = {
	{
		Id = "pumpkin_king",
		UnlockKey = "SecretAchievement_PumpkinKing",
		RewardKey = "SecretReward_PumpkinKingCash",
		AchievementId = "PumpkinKing",
		Chance = 4000,
		RewardMoney = 25000,
		Origin = {
			Id = "pumpkin_king_clan",
			DisplayName = "Pumpkin King Clan",
			Category = "Clan",
			FamilyType = "Sorcerer",
			FamilyName = "Pumpkin",
			BonusCE = 32,
			BonusSmarts = 8,
			InnatePool = { { Name = "Pumpkin Control", Weight = 100 } },
		},
		Title = "PUMPKIN KING",
		Message = "All hail to the pumpkin song. +$25000.",
	},
	{
		Id = "ryomen_myth",
		UnlockKey = "SecretAchievement_RyomenMyth",
		RewardKey = "SecretReward_RyomenMythCash",
		AchievementId = "Myth",
		Chance = 2000,
		RewardMoney = 10000,
		Origin = {
			Id = "ryomen_clan",
			DisplayName = "Ryomen Clan",
			Category = "Clan",
			FamilyType = "Sorcerer",
			FamilyName = "Ryomen",
			BonusCE = 36,
			BonusSmarts = 6,
			InnatePool = { { Name = "Shrine", Weight = 100 } },
		},
		Title = "MYTH",
		Message = "People said it never existed. +$10000.",
	},
}

local function hasAccountReward(player, rewardKey)
	if not player or not BitKaisenSaveSystem or type(BitKaisenSaveSystem.HasAccountRewardClaimed) ~= "function" then
		return false
	end
	local ok, claimed = pcall(function()
		return BitKaisenSaveSystem.HasAccountRewardClaimed(player, rewardKey)
	end)
	return ok and claimed == true
end

local function markAccountReward(player, rewardKey)
	if not player or not BitKaisenSaveSystem or type(BitKaisenSaveSystem.MarkAccountRewardClaimed) ~= "function" then
		return false
	end
	local ok = pcall(function()
		BitKaisenSaveSystem.MarkAccountRewardClaimed(player, rewardKey)
	end)
	return ok
end

local function applySecretOrigin(stats, originData)
	if not stats or not originData then
		return
	end

	local familyName = tostring(originData.FamilyName or originData.DisplayName or stats.FamilyName or "Unknown")
	stats.Clan = tostring(originData.DisplayName or stats.Clan or "Unknown")
	stats.Origin = stats.Clan
	stats.OriginCategory = tostring(originData.Category or "Clan")
	stats.FamilyName = familyName
	stats.FamilyType = tostring(originData.FamilyType or "Sorcerer")
	stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + (tonumber(originData.BonusCE) or 0))
	stats.Smarts = math.clamp((tonumber(stats.Smarts) or 0) + (tonumber(originData.BonusSmarts) or 0), 1, 100)
	if tostring(stats.FirstName or "") ~= "" and familyName ~= "None" and familyName ~= "Unknown" then
		stats.FullName = tostring(stats.FirstName) .. " " .. familyName
		stats.Name = stats.FullName
	end

	stats.CursedTechnique = "None"
	stats.InnateTechnique = "None"
	stats.TechniqueType = "None"
	stats.TechniqueKnown = false
	stats.TechniqueUsable = false
	stats.TechniqueAwakened = false
	stats.InnateDormant = false
	BitKaisenStats.ApplyBirthTechnique(stats, originData)
end

function applySecretBirthEasterEggs(player, stats)
	if not stats then
		return stats
	end

	stats.SecretAchievements = typeof(stats.SecretAchievements) == "table" and stats.SecretAchievements or {}
	for _, egg in ipairs(SECRET_BIRTH_EASTER_EGGS) do
		if hasAccountReward(player, egg.UnlockKey) then
			stats.SecretAchievements[egg.AchievementId] = true
		end
	end

	for _, egg in ipairs(SECRET_BIRTH_EASTER_EGGS) do
		if math.random(1, egg.Chance) == 1 then
			applySecretOrigin(stats, egg.Origin)
			stats.SecretAchievements[egg.AchievementId] = true
			stats.SecretBirthEasterEggId = egg.Id
			stats.SecretBirthEasterEggTitle = egg.Title
			stats.SecretBirthEasterEggMessage = egg.Message
			markAccountReward(player, egg.UnlockKey)

			if not hasAccountReward(player, egg.RewardKey) then
				stats.Money = (tonumber(stats.Money) or 0) + egg.RewardMoney
				markAccountReward(player, egg.RewardKey)
				stats.SecretBirthCashGranted = egg.RewardMoney
			else
				stats.SecretBirthCashGranted = 0
			end
			return stats
		end
	end

	return stats
end

-- getGradeValue is defined near the top with unregistered-grade support.

-- Achievement logic moved to BK_AchievementService in Phase 1 split.
function getAchievementPayload(player)
	return BK_AchievementService.GetPayload(player)
end

function claimAchievementReward(player, achievementId)
	return BK_AchievementService.Claim(player, achievementId)
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

----------------------------------------------------------------
-- DOJO / ASSET HELPERS
-- Heavy dojo helper logic moved to BK_DojoService in Phase 3 split.
----------------------------------------------------------------

function ownsAssetById(stats, assetId)
	return BK_DojoService.OwnsAssetById(stats, assetId)
end

function countClanStudents(stats)
	return BK_DojoService.CountClanStudents(stats)
end

function countDojoStudentsAndWards(stats)
	return BK_DojoService.CountDojoStudentsAndWards(stats)
end

function getDojoStudentCapacity(stats)
	return BK_DojoService.GetDojoStudentCapacity(stats)
end

function getDojoUpgradeCost(stats)
	return BK_DojoService.GetDojoUpgradeCost(stats)
end

function getDojoMaintainCost(stats)
	return BK_DojoService.GetDojoMaintainCost(stats)
end

function getDojoFocusLabel(stats)
	return BK_DojoService.GetDojoFocusLabel(stats)
end

function adjustDojoCondition(stats, amount)
	return BK_DojoService.AdjustDojoCondition(stats, amount)
end

function normalizeClanName(rawName, fallbackFamilyName)
	return BK_DojoService.NormalizeClanName(rawName, fallbackFamilyName)
end

function makeRecruitCandidate(stats, index)
	return BK_DojoService.MakeRecruitCandidate(stats, index)
end

function generateDojoRecruitPool(stats)
	return BK_DojoService.GenerateDojoRecruitPool(stats)
end

function findRecruitCandidate(stats, candidateId)
	return BK_DojoService.FindRecruitCandidate(stats, candidateId)
end

function removeRecruitCandidate(stats, candidateId)
	return BK_DojoService.RemoveRecruitCandidate(stats, candidateId)
end

function getDojoStudentsForPayload(stats)
	return BK_DojoService.GetDojoStudentsForPayload(stats)
end

function recruitCandidateIntoDojo(stats, candidate)
	return BK_DojoService.RecruitCandidateIntoDojo(stats, candidate)
end

function createClanStudent(stats)
	return BK_DojoService.CreateClanStudent(stats)
end

function createRescuedWard(stats, sourceText)
	return BK_DojoService.CreateRescuedWard(stats, sourceText)
end

function getOrphanRescueChance(stats, missionData)
	return BK_DojoService.GetOrphanRescueChance(stats, missionData)
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
	if reason ~= "PlayerRemoving" and reason ~= "BindToClose" and reason ~= "CharacterCustomization" and (now - lastSave) < SAVE_FORCE_MIN_GAP_SECONDS then
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

function addCEAddiction(stats, amount)
	if not stats then
		return 0
	end

	amount = tonumber(amount) or 0
	stats.CEAddiction = math.clamp((tonumber(stats.CEAddiction) or 0) + amount, 0, 100)
	return stats.CEAddiction
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

-- Hotfix: startAsCurseRebirth calls this helper before the later curse-grade
-- helper section is reached by line number, so keep a small direct wrapper here.
function getStartingUnregisteredCurseGradeFromRebirthScore(score)
	local grade = getCurseGradeFromRebirthScore(score)
	grade = tostring(grade or "Grade 4 Cursed Spirit")

	if string.sub(grade, 1, #"Unregistered ") == "Unregistered " then
		return grade
	end

	if grade == "Disaster-Class Cursed Spirit" or grade == "Disaster Curse" then
		grade = "Special Grade Cursed Spirit"
	end

	return "Unregistered " .. grade
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

function canReincarnateFromCursedAnchor(stats)
	if typeof(stats) ~= "table" or stats.Alive ~= false then
		return false
	end
	local ce = tonumber(stats.CursedEnergy) or 0
	local anchors = tonumber(stats.CursedObjectAnchors) or 0
	local anchorProgress = tonumber(stats.CursedObjectAnchorProgress) or 0
	return ce >= 120 and (anchors >= 1 or anchorProgress >= 75)
end

function startAsReincarnation(player)
	local oldStats = playerLives[player.UserId]
	if not canReincarnateFromCursedAnchor(oldStats) then
		return false, "Reincarnation requires at least 120 CE and a cursed-object anchor or 75 anchor progress."
	end
	local preserved = {
		CursedEnergy = math.max(0, math.floor((tonumber(oldStats.CursedEnergy) or 0) * 0.65)),
		CursedTechnique = oldStats.CursedTechnique,
		InnateTechnique = oldStats.InnateTechnique,
		Clan = oldStats.Clan,
		Origin = oldStats.Origin,
		FamilyName = oldStats.FamilyName,
		FamilyType = oldStats.FamilyType,
		PlayerClanName = oldStats.PlayerClanName,
		PlayerClanInnateTechnique = oldStats.PlayerClanInnateTechnique,
		ClanInnateTechnique = oldStats.ClanInnateTechnique,
	}
	startNewLife(player)
	local newStats = playerLives[player.UserId]
	if not newStats then
		return false, "Could not create reincarnated life."
	end
	newStats.CursedEnergy = preserved.CursedEnergy
	newStats.CursedTechnique = preserved.CursedTechnique or newStats.CursedTechnique
	newStats.InnateTechnique = preserved.InnateTechnique or newStats.InnateTechnique
	newStats.Clan = preserved.Clan or newStats.Clan
	newStats.Origin = preserved.Origin or newStats.Origin
	newStats.FamilyName = preserved.FamilyName or newStats.FamilyName
	newStats.FamilyType = preserved.FamilyType or newStats.FamilyType
	newStats.PlayerClanName = preserved.PlayerClanName or newStats.PlayerClanName
	newStats.PlayerClanInnateTechnique = preserved.PlayerClanInnateTechnique or newStats.PlayerClanInnateTechnique
	newStats.ClanInnateTechnique = preserved.ClanInnateTechnique or newStats.ClanInnateTechnique
	newStats.Reincarnated = true
	newStats.ReincarnationAnchor = "Cursed Object"
	newStats.CursedObjectAnchors = 0
	newStats.CursedObjectAnchorProgress = 0
	fireLifeUpdate(player, newStats, "<font color='#a782ff'><b>[ REINCARNATION ]</b></font> Your cursed-object anchor pulled your soul into a new life. CE, clan, and technique persisted.", true)
	saveStats(player, "reincarnation")
	return true
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

function startAsCurseRebirth(player)
	local oldStats = playerLives[player.UserId]
	if not oldStats then
		return false, "No dead life found."
	end

	ensureExtraStats(oldStats)
	refreshCurseRebirthEligibility(oldStats)

	if not canBecomeVengefulSpirit(oldStats) then
		return false, "This life did not leave enough cursed resentment or cursed-object anchors behind."
	end

	local anchorCount = math.max(0, tonumber(oldStats.CursedObjectAnchors) or 0)
	local anchorProgress = math.clamp(tonumber(oldStats.CursedObjectAnchorProgress) or 0, 0, 100)
	local anchorType = tostring(oldStats.ReincarnationAnchor or "None")
	local hasObjectAnchor = anchorCount > 0 or anchorType ~= "None"
	local preservedSettings = oldStats.Settings
	local preservedMetaProgress = oldStats.MetaProgress
	local preservedGodModeSettings = BK_GodModeService.CloneSettings(oldStats)
	local oldName = tostring(oldStats.Name or "Unknown")
	local oldTechnique = tostring(oldStats.CursedTechnique or "None")
	local score = getCurseRebirthScore(oldStats)
	local subtype = getCurseSubtypeFromPreviousLife(oldStats)
	local curseGrade = getStartingUnregisteredCurseGradeFromRebirthScore(score)

	pendingMissions[player.UserId] = nil
	pendingLegacy[player.UserId] = nil
	if BK_CombatService.ClearCurrentFight then
		BK_CombatService.ClearCurrentFight(player, "curse rebirth")
	end

	local newStats = BitKaisenStats.GetDefaultStats()
	ensureExtraStats(newStats)
	newStats.CharacterCustomized = true
	ensureCharacterAppearance(newStats)
	syncMonetizationEntitlements(player, newStats)
	applyLuckySorcererBirthBoost(player, newStats)
	applyLegacyBlessingBoost(player, newStats)

	if preservedSettings then
		newStats.Settings = preservedSettings
	end

	if preservedMetaProgress then
		newStats.MetaProgress = preservedMetaProgress
	end

	if preservedGodModeSettings then
		newStats.GodModeSettings = preservedGodModeSettings
		newStats.GodModeStartBoostChoice = preservedGodModeSettings.StartBoost
		newStats.GodModeGuaranteedLegacyTraits = preservedGodModeSettings.GuaranteedLegacyTraits == true
	end
	BK_GodModeService.EnsureSettings(newStats)

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
	newStats.CurseEvolutionProgress = math.clamp(math.floor((tonumber(oldStats.CursedResentment) or 0) / 4) + (anchorCount * 8), 0, 90)
	newStats.CurseThreat = math.clamp(math.floor(score / 18) + (anchorCount * 3), 5, 90)
	newStats.ExorcismRisk = math.clamp(10 + math.floor((tonumber(oldStats.WantedLevel) or 0) * 8), 0, 65)
	newStats.SorcererAttackCooldown = 2
	newStats.SocietyStatus = "Unregistered Cursed Spirit"
	newStats.RegisteredSorcerer = false
	newStats.CursedResentment = math.clamp(math.floor((tonumber(oldStats.CursedResentment) or 0) * 0.55) + (anchorCount * 12), 25, 250)
	newStats.CurseRebirthCount = (tonumber(oldStats.CurseRebirthCount) or 0) + 1
	newStats.CursedObjectAnchors = math.max(0, anchorCount - 1)
	newStats.CursedObjectAnchorProgress = math.clamp(math.floor(anchorProgress * 0.35), 0, 100)
	newStats.ReincarnationAnchor = hasObjectAnchor and anchorType or "None"
	newStats.ObjectReincarnationEcho = hasObjectAnchor == true
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
	newStats.CursedEnergy = math.max(35, math.floor((tonumber(oldStats.CursedEnergy) or 0) * (hasObjectAnchor and 0.55 or 0.45)) + math.floor(score / 8) + (anchorCount * 18))

	if oldTechnique ~= "None" then
		newStats.CursedTechnique = oldTechnique
		newStats.InnateTechnique = oldTechnique
		newStats.TechniqueKnown = true
		newStats.TechniqueUsable = true
		newStats.TechniqueAwakened = true
		newStats.InnateDormant = false
		newStats.TechniqueMastery = math.clamp(math.floor((tonumber(oldStats.TechniqueMastery) or 0) * (hasObjectAnchor and 0.45 or 0.35)) + (anchorCount * 3), 5, hasObjectAnchor and 65 or 50)
	else
		newStats.CursedTechnique = "None"
		newStats.TechniqueMastery = 0
	end

	local preservedTraits = {}
	if typeof(oldStats.Traits) == "table" then
		for index, trait in ipairs(oldStats.Traits) do
			preservedTraits[index] = trait
		end
	end

	if #preservedTraits > 0 then
		newStats.Traits = preservedTraits
	else
		newStats.Traits = BitKaisenTraits.RollBirthTraits(newStats)
	end
	BitKaisenTraits.ApplyStartingBonuses(newStats)
	newStats.TraitsRolled = true
	local curseStartBoostMessage = BK_GodModeService.ApplyStartBoost(newStats)

	local priorChildren = {}
	for _, rel in ipairs(oldStats.Relationships or {}) do
		if rel.Role == "Child" and rel.Alive ~= false then
			local copy = {}
			for k, v in pairs(rel) do
				copy[k] = v
			end
			table.insert(priorChildren, copy)
		end
	end
	newStats.PriorLifeChildren = priorChildren
	newStats.Relationships = {}
	newStats.RelationshipHistory = oldStats.RelationshipHistory or {}
	newStats.LegacyHistory = oldStats.LegacyHistory or {}

	normalizeCursedSocietyState(newStats)
	playerLives[player.UserId] = newStats

	local message = "<font color='#b27aff'><b>[ CURSE REBIRTH ]</b></font> Your body died, but your cursed energy refused to disappear."
	message ..= "\nYou returned as a <b>" .. tostring(subtype) .. "</b>."
	message ..= "\nRace: <b>Curse</b> | Grade: <b>" .. tostring(curseGrade) .. "</b> | Threat: <b>" .. tostring(newStats.CurseThreat or 0) .. "</b>."
	message ..= "\nPrevious Life: <b>" .. oldName .. "</b>."
	if hasObjectAnchor then
		message ..= "\nA cursed object anchor carried part of your old self forward. Remaining Anchors: <b>" .. tostring(newStats.CursedObjectAnchors or 0) .. "</b>."
	end
	if oldTechnique ~= "None" then
		message ..= "\nYour old cursed technique echoed into your new form: <b>" .. oldTechnique .. "</b>."
	end
	if curseStartBoostMessage ~= "" then
		message ..= "\n" .. curseStartBoostMessage
	end
	message ..= "\nCurses do not die from old age, but sorcerers will hunt you if your threat spreads."

	fireLifeUpdate(player, newStats, message, true)
	forceSaveStats(player, "curse rebirth")
	return true
end

local function getLifeRibbon(stats)
	local age = tonumber(stats.Age) or 0
	local grade = tostring(stats.Grade or "")
	local rep = tonumber(stats.Reputation) or 0
	local missions = tonumber(stats.MissionsCompleted) or 0
	local isCU = stats.IsCurseUser == true or stats.Path == "Curse User" or stats.Alignment == "Curse User"
	local isCL = tostring(stats.World or "") == "Cursed Spirit" or tostring(stats.Lineage or ""):find("Cursed")
	local hasDomain = stats.DomainExpansion and stats.DomainExpansion ~= "None" and stats.DomainExpansion ~= ""
	local hasRCT = stats.RCT == true or stats.HasRCT == true
	local generation = tonumber(stats.Generation) or 1
	if grade == "Special Grade" and hasDomain and age >= 50 then return "LEGEND OF THE CURSED WORLD"
	elseif grade == "Special Grade" and hasDomain then return "SPECIAL GRADE SORCERER"
	elseif isCU and grade == "Special Grade" then return "CURSE USER KING"
	elseif isCU and rep < -50 then return "FEARED CURSE USER"
	elseif isCU then return "CURSE USER"
	elseif isCL then return "CURSED SPIRIT"
	elseif hasRCT and hasDomain then return "ELITE JUJUTSU SORCERER"
	elseif hasDomain then return "DOMAIN USER"
	elseif hasRCT then return "RCT PRACTITIONER"
	elseif stats.ClanFounded == true then return "CLAN FOUNDER"
	elseif generation >= 5 then return "DEEP BLOODLINE"
	elseif missions >= 100 then return "VETERAN SORCERER"
	elseif grade == "Grade 1" or grade == "Semi-Grade 1" then return "GRADE 1 SORCERER"
	elseif age >= 80 then return "LONG LIFE"
	elseif age <= 18 then return "LIFE CUT SHORT"
	elseif rep >= 100 then return "CELEBRATED SORCERER"
	else return "ORDINARY LIFE" end
end

function startNewLife(player)
	local oldStats = playerLives[player.UserId]
	local preservedSettings = nil
	local preservedMetaProgress = nil
	local preservedGodModeSettings = nil

	if oldStats and oldStats.Settings then
		preservedSettings = oldStats.Settings
	end

	if oldStats then
		preservedGodModeSettings = BK_GodModeService.CloneSettings(oldStats)
	end

	if oldStats and oldStats.MetaProgress then
		preservedMetaProgress = oldStats.MetaProgress
	end

	-- Save past life snapshot (max 10)
	if oldStats and (tonumber(oldStats.Age) or 0) >= 1 then
		preservedMetaProgress = preservedMetaProgress or {}
		preservedMetaProgress.PastLives = preservedMetaProgress.PastLives or {}
		local snapshot = {
			Name = tostring(oldStats.Name or "Unknown"),
			Clan = tostring(oldStats.Clan or oldStats.FamilyName or ""),
			Age = tonumber(oldStats.Age) or 0,
			Grade = tostring(oldStats.Grade or "Unranked"),
			Technique = tostring(oldStats.CursedTechnique or "None"),
			Missions = tonumber(oldStats.MissionsCompleted) or 0,
			Reputation = tonumber(oldStats.Reputation) or 0,
			Ribbon = getLifeRibbon(oldStats),
			Generation = tonumber(oldStats.Generation) or 1,
			Timestamp = os.time(),
		}
		table.insert(preservedMetaProgress.PastLives, 1, snapshot)
		if #preservedMetaProgress.PastLives > 10 then
			table.remove(preservedMetaProgress.PastLives, 11)
		end
	end

	pendingMissions[player.UserId] = nil
	pendingLegacy[player.UserId] = nil
	if BK_CombatService.ClearCurrentFight then
		BK_CombatService.ClearCurrentFight(player, "new life")
	end

	local newStats = BitKaisenStats.GetDefaultStats()
	ensureExtraStats(newStats)
	syncMonetizationEntitlements(player, newStats)
	applyLuckySorcererBirthBoost(player, newStats)
	applyLegacyBlessingBoost(player, newStats)

	if preservedSettings then
		newStats.Settings = preservedSettings
	end

	if preservedMetaProgress then
		newStats.MetaProgress = preservedMetaProgress
	end

	if preservedGodModeSettings then
		newStats.GodModeSettings = preservedGodModeSettings
		newStats.GodModeStartBoostChoice = preservedGodModeSettings.StartBoost
		newStats.GodModeGuaranteedLegacyTraits = preservedGodModeSettings.GuaranteedLegacyTraits == true
	end
	BK_GodModeService.EnsureSettings(newStats)

	local rolledOrigin = rollBirthOriginForPlayer(player)
	local rolledGender = math.random(1, 2) == 1 and "Male" or "Female"
	local identity = BitKaisenStats.GenerateRandomIdentity(rolledOrigin, rolledGender)

	newStats.Name = identity.FullName
	newStats.FirstName = identity.FirstName
	newStats.FamilyName = identity.FamilyName
	newStats.FamilyType = identity.FamilyType
	newStats.Gender = identity.Gender or rolledGender
	newStats.CharacterCustomized = false
	ensureCharacterAppearance(newStats)

	newStats.Clan = rolledOrigin.DisplayName
	newStats.Origin = rolledOrigin.DisplayName
	newStats.OriginCategory = rolledOrigin.Category

	newStats.CursedEnergy += rolledOrigin.BonusCE
	newStats.Smarts = math.clamp(newStats.Smarts + rolledOrigin.BonusSmarts, 1, 100)

	BitKaisenStats.ApplyBirthTechnique(newStats, rolledOrigin, ownsLuckyBirthPass(player))
	applySecretBirthEasterEggs(player, newStats)
	applyLuckyBirthBonuses(player, newStats)

	-- Premium Origins heirloom: a family keepsake, always Common/Uncommon by
	-- design (see the pitch to Luisa) -- flavor and a real collectible, never
	-- a top-tier tool, so it never becomes a power shortcut.
	if ownsPremiumOriginsPass(player) then
		newStats.HasPremiumOrigin = true
		local heirloomPool = { "rusted_cursed_blade", "sealed_protection_charm", "barrier_tag" }
		local heirloomId = heirloomPool[math.random(1, #heirloomPool)]
		BitKaisenCursedTools.AddTool(newStats, heirloomId, "Family Heirloom", getCurrentYear(newStats))
	end

	normalizeCursedSocietyState(newStats)
	ensureSorcererRegistrationState(newStats)

	local heavenlyRestrictionChance = newStats.MetaProgress and newStats.MetaProgress.HeavenlyRestrictionBoost and 15 or 3
	if math.random(1, 100) <= heavenlyRestrictionChance then
		newStats.HeavenlyRestricted = true
		newStats.Health = math.clamp((newStats.Health or 100) + 8, 0, 100)
		newStats.Smarts = math.clamp((newStats.Smarts or 0) + 4, 0, 100)
		newStats.Reputation = math.max(0, (newStats.Reputation or 0) + 1)
	end

	newStats.Traits = BitKaisenTraits.RollBirthTraits(newStats, ownsLuckyBirthPass(player))
	BitKaisenTraits.ApplyStartingBonuses(newStats)
	newStats.TraitsRolled = true
	local godModeStartBoostMessage = BK_GodModeService.ApplyStartBoost(newStats)
	syncFamilyStatus(newStats)
	ensureSorcererRegistrationState(newStats)

	BitKaisenRelationships.GenerateStartingRelationships(newStats)

	playerLives[player.UserId] = newStats

	local birthMessage = "You were born with no recognized sorcerer grade."
	birthMessage = birthMessage .. "\n" .. getBirthOriginMessage(newStats)
	if newStats.LuckyBirthActive == true then
		birthMessage = birthMessage .. "\n<font color='#ffcd69'><b>[ LUCKY BIRTH ]</b></font> Your birth luck improved your starting path and early potential."
	end
	if tostring(newStats.SecretBirthEasterEggMessage or "") ~= "" then
		birthMessage = birthMessage .. "\n<font color='#ffcd69'><b>[ " .. tostring(newStats.SecretBirthEasterEggTitle or "SECRET") .. " ]</b></font> " .. tostring(newStats.SecretBirthEasterEggMessage)
	end
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
	if godModeStartBoostMessage ~= "" then
		birthMessage = birthMessage .. "\n" .. godModeStartBoostMessage
	end

	fireLifeUpdate(player, newStats, birthMessage, true)
	saveStats(player)
end

function startAsSuccessor(player, successorId, options)
	local parentStats = playerLives[player.UserId]
	options = typeof(options) == "table" and options or {}
	local liveTakeover = options.LiveTakeover == true

	if not parentStats then
		return false, "No previous life data found."
	end

	if parentStats.Alive ~= false and not liveTakeover then
		return false, "Your previous life is still ongoing."
	end

	if liveTakeover then
		if parentStats.Alive == false then
			return false, "Use the normal successor option after death."
		end
		if ownsGodModePass(player) ~= true then
			return false, "God Mode is required to take over a child before death."
		end
		if pendingMissions[player.UserId] then
			return false, "Finish the current mission/event before taking over a child."
		end
	end

	local preservedSettings = parentStats.Settings
	local preservedGodModeSettings = BK_GodModeService.CloneSettings(parentStats)

	local newStats, errorMessage = BitKaisenLegacy.BuildSuccessorStats(parentStats, successorId, BitKaisenStats, BitKaisenRelationships, { LiveTakeover = liveTakeover })

	if not newStats then
		return false, errorMessage or "Could not create successor."
	end

	ensureExtraStats(newStats)
	newStats.CharacterCustomized = false
	newStats.LiveSuccessorTakeover = liveTakeover == true
	newStats.TakenOverFromLivingParentName = liveTakeover and tostring(parentStats.Name or "Unknown") or nil
	ensureCharacterAppearance(newStats)
	syncMonetizationEntitlements(player, newStats)
	applyLegacyBlessingBoost(player, newStats)
	local inheritedInnate, inheritedTechnique = BitKaisenStats.ApplyInheritedTechniqueFromParent(newStats, parentStats)
	if inheritedInnate then
		newStats.LegacyHistory = newStats.LegacyHistory or {}
		table.insert(newStats.LegacyHistory, "Inherited " .. tostring(inheritedTechnique) .. " as a dormant clan innate technique.")
	end
	if preservedSettings then
		newStats.Settings = preservedSettings
	end

	if preservedGodModeSettings then
		newStats.GodModeSettings = preservedGodModeSettings
		newStats.GodModeStartBoostChoice = preservedGodModeSettings.StartBoost
		newStats.GodModeGuaranteedLegacyTraits = preservedGodModeSettings.GuaranteedLegacyTraits == true
	end
	BK_GodModeService.EnsureSettings(newStats)
	local legacyTraitApplied, legacyTraitMessage = BK_GodModeService.ApplyGuaranteedLegacyTraits(parentStats, newStats)
	local successorStartBoostMessage = BK_GodModeService.ApplyStartBoost(newStats)

	if parentStats.MetaProgress then
		newStats.MetaProgress = parentStats.MetaProgress
	end

	-- Inheritance: assets, money, reputation (only on death, not live takeover)
	local inheritanceLog = {}
	local parentAssets = (not liveTakeover) and (typeof(parentStats.Assets) == "table" and parentStats.Assets or {}) or {}
	local inheritedAssets = {}
	for _, asset in ipairs(parentAssets) do
		local baseId = tostring(asset.BaseId or asset.Id or "")
		if baseId == "" then continue end
		local assetDef = BitKaisenAssets.GetAssetById(baseId)
		local assetType = tostring(asset.Type or (assetDef and assetDef.Type) or "")
		if assetType == "Cursed Tool" or assetType == "Property" then
			local assetName = tostring(asset.Name or (assetDef and assetDef.Name) or baseId)
			table.insert(inheritedAssets, { Type = assetType, Name = assetName, Original = asset })
		end
	end
	if #inheritedAssets > 0 then
		newStats.Assets = newStats.Assets or {}
		local names = {}
		for _, a in ipairs(inheritedAssets) do
			local copy = {}
			for k, v in pairs(a.Original) do copy[k] = v end
			table.insert(newStats.Assets, copy)
			table.insert(names, a.Name)
		end
		table.insert(inheritanceLog, "Inherited " .. tostring(#inheritedAssets) .. " asset(s) from your parent: " .. table.concat(names, ", ") .. ".")
	end

	local parentMoney = (not liveTakeover) and (tonumber(parentStats.Money) or 0) or 0
	if parentMoney > 0 then
		local inherited = math.floor(parentMoney * 0.25)
		newStats.Money = (tonumber(newStats.Money) or 0) + inherited
		table.insert(inheritanceLog, "Inherited ¥" .. tostring(inherited) .. " (25% of parent's estate).")
	end

	local parentRep = (not liveTakeover) and (tonumber(parentStats.Reputation) or 0) or 0
	if parentRep >= 20 then
		local repBonus = math.floor(math.clamp(parentRep * 0.15, 3, 20))
		newStats.Reputation = math.clamp((tonumber(newStats.Reputation) or 0) + repBonus, 0, 100)
		table.insert(inheritanceLog, "The " .. tostring(parentStats.FamilyName or "family") .. " name carries weight. Reputation +" .. tostring(repBonus) .. ".")
	end

	if #inheritanceLog > 0 then
		newStats.LegacyHistory = newStats.LegacyHistory or {}
		for _, line in ipairs(inheritanceLog) do
			table.insert(newStats.LegacyHistory, line)
		end
		-- Build popup lines
		local popupLines = {}
		if #inheritedAssets > 0 then
			local names = {}
			for _, a in ipairs(inheritedAssets) do table.insert(names, a.Name) end
			table.insert(popupLines, "Assets: " .. table.concat(names, ", "))
		end
		local parentMoneyCopy = (not liveTakeover) and (tonumber(parentStats.Money) or 0) or 0
		if parentMoneyCopy > 0 then
			table.insert(popupLines, "Money: ¥" .. tostring(math.floor(parentMoneyCopy * 0.25)))
		end
		if parentRep >= 20 then
			table.insert(popupLines, "Family rep bonus: +" .. tostring(math.floor(math.clamp(parentRep * 0.15, 3, 20))))
		end
		fireMajorPopup(
			player,
			"INHERITANCE",
			"Your parent left behind more than memories.",
			table.concat(popupLines, " · "),
			tostring(parentStats.Name or "Your parent") .. "'s legacy lives on.",
			"success"
		)
	end

	pendingMissions[player.UserId] = nil
	pendingLegacy[player.UserId] = nil
	if BK_CombatService.ClearCurrentFight then
		BK_CombatService.ClearCurrentFight(player, "successor life")
	end

	playerLives[player.UserId] = newStats

	local introMessage = BitKaisenLegacy.BuildIntroMessage(newStats, parentStats)
	if legacyTraitApplied and legacyTraitMessage ~= "" then
		introMessage = introMessage .. "\n" .. legacyTraitMessage
	end
	if successorStartBoostMessage ~= "" then
		introMessage = introMessage .. "\n" .. successorStartBoostMessage
	end
	if #inheritanceLog > 0 then
		introMessage = introMessage .. "\n<font color='#f0c060'><b>[ INHERITANCE ]</b></font> " .. table.concat(inheritanceLog, "\n")
	end

	fireLifeUpdate(player, newStats, introMessage, true)

	fireMajorPopup(
		player,
		liveTakeover and "GOD MODE SUCCESSOR" or "LEGACY CONTINUES",
		liveTakeover and ("You took over your child while " .. tostring(parentStats.Name or "your previous life") .. " remains a living parent.") or ("A new generation of the " .. tostring(newStats.FamilyName or "Unknown") .. " Family begins."),
		newStats.Name,
		"Generation " .. tostring(newStats.Generation or 2) .. " of your bloodline."
	)

	saveStats(player)
	return true, nil
end

local GROUP_JOIN_REWARD_MONEY = 10000
local GROUP_JOIN_REWARD_REPUTATION = 15
local GROUP_JOIN_REWARD_HEALTH = 25

local function hasClaimedGroupJoinReward(playerOrStats, maybeStats)
	local player = nil
	local stats = maybeStats

	if typeof(playerOrStats) == "Instance" and playerOrStats:IsA("Player") then
		player = playerOrStats
	else
		stats = playerOrStats
	end

	if player and BitKaisenSaveSystem and type(BitKaisenSaveSystem.HasGroupJoinRewardClaimed) == "function" then
		local ok, claimed = pcall(function()
			return BitKaisenSaveSystem.HasGroupJoinRewardClaimed(player)
		end)

		if ok and claimed == true then
			if stats then
				stats.MetaProgress = stats.MetaProgress or {}
				stats.Purchases = stats.Purchases or {}
				stats.MetaProgress.GroupJoinRewardClaimed = true
				stats.Purchases.GroupJoinRewardClaimed = true
			end

			return true
		end	
	end

	if not stats then
		return true
	end

	ensureExtraStats(stats)

	return (stats.Purchases and stats.Purchases.GroupJoinRewardClaimed == true)
		or (stats.MetaProgress and stats.MetaProgress.GroupJoinRewardClaimed == true)
end

local function markGroupJoinRewardClaimed(playerOrStats, maybeStats)
	local player = nil
	local stats = maybeStats

	if typeof(playerOrStats) == "Instance" and playerOrStats:IsA("Player") then
		player = playerOrStats
	else
		stats = playerOrStats
	end

	if stats then
		stats.MetaProgress = stats.MetaProgress or {}
		stats.Purchases = stats.Purchases or {}
		stats.MetaProgress.GroupJoinRewardClaimed = true
		stats.Purchases.GroupJoinRewardClaimed = true
	end

	if player and BitKaisenSaveSystem and type(BitKaisenSaveSystem.MarkGroupJoinRewardClaimed) == "function" then
		local ok, err = pcall(function()
			return BitKaisenSaveSystem.MarkGroupJoinRewardClaimed(player)
		end)

		if not ok then
			warn("[GameManager] Failed to save account-wide group reward flag for " .. tostring(player.Name) .. ": " .. tostring(err))
		end
	end
end

function grantGroupJoinReward(player, stats)
	if not stats then return end
	if hasClaimedGroupJoinReward(player, stats) then return end

	markGroupJoinRewardClaimed(player, stats)

	stats.Money = math.max(0, (stats.Money or 0) + GROUP_JOIN_REWARD_MONEY)
	stats.Reputation = (stats.Reputation or 0) + GROUP_JOIN_REWARD_REPUTATION
	stats.Health = math.clamp((stats.Health or 100) + GROUP_JOIN_REWARD_HEALTH, 0, 100)

	fireMajorPopup(
		player,
		"GROUP REWARD",
		"Thank you for being part of the BitKaisen community.",
		"+$10,000 • +15 Reputation • +25 Health",
		"This is a one-time reward. Rejoining will not grant it again."
	)

	fireLifeUpdate(
		player,
		stats,
		"<font color='#ffcd69'><b>[ GROUP REWARD ]</b></font> Thanks for joining the BitKaisen group! Rewards: <b>+$10,000</b>, <b>+15 Reputation</b>, <b>+25 Health</b>. This reward can only be claimed once."
	)

	forceSaveStats(player, "GroupJoinReward")
end

local FREE_REWARD_BOOST_SECONDS = 5 * 60
local FREE_REWARD_BOOST_MULTIPLIER = 2

function isPlayerInBitKaisenGroup(player)
	if not player then
		return false
	end

	local ok, inGroup = pcall(function()
		return player:IsInGroup(BITKAISEN_GROUP_ID)
	end)

	if ok then
		return inGroup == true
	end

	local okGroups, groups = pcall(function()
		return game:GetService("GroupService"):GetGroupsAsync(player.UserId)
	end)

	if okGroups and typeof(groups) == "table" then
		for _, groupInfo in ipairs(groups) do
			if groupInfo.Id == BITKAISEN_GROUP_ID then
				return true
			end
		end
	end

	return false
end

function getFreeRewardPayload(player)
	local stats = player and playerLives[player.UserId] or nil
	if stats then
		ensureExtraStats(stats)
	end

	local premiumBoosts = stats and stats.PremiumBoosts or {}
	local masteryUntil = tonumber(premiumBoosts and premiumBoosts.MasteryUntil) or tonumber(stats and stats.MasteryBoostUntil) or 0

	return {
		GroupId = BITKAISEN_GROUP_ID,
		RewardTitle = "FREE x2 Technique Mastery Boost",
		RewardDurationText = "For 5 Minutes",
		Claimed = stats and stats.MetaProgress and stats.MetaProgress.FreeMasteryBoostClaimed == true or false,
		GroupVerified = isPlayerInBitKaisenGroup(player),
		RemainingBoostSeconds = math.max(0, masteryUntil - os.time()),
	}
end

function claimFreeMasteryReward(player, clientConfirmedLike)
	if not player then
		return { Success = false, Message = "No player." }
	end

	if not checkRateLimit(player, "ClaimFreeReward") then
		return { Success = false, Message = "Slow down." }
	end

	local stats = playerLives[player.UserId]
	if not stats or stats.Alive == false then
		return { Success = false, Message = "No active life." }
	end

	ensureExtraStats(stats)

	if stats.MetaProgress.FreeMasteryBoostClaimed == true then
		return { Success = false, Message = "You already claimed this free reward.", Payload = getFreeRewardPayload(player) }
	end

	if clientConfirmedLike ~= true then
		return { Success = false, Message = "Like the game first, then press the LIKE step.", Payload = getFreeRewardPayload(player) }
	end

	if not isPlayerInBitKaisenGroup(player) then
		return { Success = false, Message = "Join the BitKaisen group first.", Payload = getFreeRewardPayload(player) }
	end

	stats.MetaProgress.FreeMasteryBoostClaimed = true
	stats.FreeRewards = stats.FreeRewards or {}
	stats.FreeRewards.MasteryBoostClaimed = true
	stats.FreeRewards.MasteryBoostClaimedAt = os.time()

	stats.PremiumBoosts = stats.PremiumBoosts or {}
	local currentUntil = tonumber(stats.PremiumBoosts.MasteryUntil) or tonumber(stats.MasteryBoostUntil) or 0
	local newUntil = math.max(os.time(), currentUntil) + FREE_REWARD_BOOST_SECONDS

	stats.PremiumBoosts.MasteryUntil = newUntil
	stats.PremiumBoosts.MasteryMultiplier = FREE_REWARD_BOOST_MULTIPLIER
	stats.MasteryBoostUntil = newUntil
	stats.MasteryBoostMultiplier = FREE_REWARD_BOOST_MULTIPLIER

	fireMajorPopup(
		player,
		"FREE REWARD CLAIMED",
		"Your free Technique Mastery boost is now active.",
		"x2 Mastery for 5 Minutes",
		"Thank you for supporting BitKaisen."
	)

	fireLifeUpdate(
		player,
		stats,
		"<font color='#78beff'><b>[ FREE REWARD ]</b></font> x2 Technique Mastery Boost active for <b>5 minutes</b>."
	)

	forceSaveStats(player, "FreeMasteryReward")

	return { Success = true, Message = "Free x2 Technique Mastery Boost active for 5 minutes.", Payload = getFreeRewardPayload(player), Stats = stats }
end

function checkAndPromptGroupJoin(player, stats)
	if not player or not stats then return end
	if hasClaimedGroupJoinReward(player, stats) then return end

	local ok, inGroup = pcall(function()
		return player:IsInGroup(BITKAISEN_GROUP_ID)
	end)

	if ok and inGroup then
		grantGroupJoinReward(player, stats)
		return
	end

	task.delay(3.5, function()
		if not player or not player.Parent then return end
		local current = playerLives[player.UserId]
		if not current then return end
		if hasClaimedGroupJoinReward(player, current) then return end
		showGroupJoinPrompt:FireClient(player)
	end)
end

function loadOrStartLife(player)
	local loaded = BitKaisenSaveSystem.Load(player, ownsSaveSlotAccess(player))

	if loaded then
		ensureExtraStats(loaded)
		syncMonetizationEntitlements(player, loaded)
		BitKaisenRelationships.SanitizeOnLoad(loaded)
		BitKaisenAssets.SanitizeOnLoad(loaded)
		if BK_ChallengeService then
			BK_ChallengeService.InitPlayer(player)
		end

		playerLives[player.UserId] = loaded

		local welcomeMessage = tSys(player, "save_loaded", { name = loaded.Name or "Unknown" },
			"<font color='#a782ff'><b>[ SAVE LOADED ]</b></font> Welcome back, <b>" .. tostring(loaded.Name or "Unknown") .. "</b>.")

		if loaded.Generation and loaded.Generation > 1 then
			welcomeMessage = welcomeMessage .. tSys(player, "save_loaded_gen", { gen = loaded.Generation, family = loaded.FamilyName or "Unknown" },
				"\nGeneration " .. tostring(loaded.Generation) .. " of the " .. tostring(loaded.FamilyName or "Unknown") .. " bloodline.")
		end

		welcomeMessage = welcomeMessage .. tSys(player, "save_loaded_age", { age = loaded.Age or 0 },
			"\nResuming at age " .. tostring(loaded.Age or 0) .. ".")

		fireLifeUpdate(player, loaded, welcomeMessage, true, true)
	else
		startNewLife(player)
	end

	startAutosaveLoop(player)
	checkAndPromptGroupJoin(player, playerLives[player.UserId])
end

function getSaveSlotPayload(player)
	local hasVIP = ownsVIPSorcererPass(player)
	local hasExtraSaveSlots = ownsExtraSaveSlotsPass(player)
	local hasFreeCodeSlots = false
	if BitKaisenSaveSystem and type(BitKaisenSaveSystem.HasExtraSaveSlotsUnlocked) == "function" then
		hasFreeCodeSlots = BitKaisenSaveSystem.HasExtraSaveSlotsUnlocked(player) == true
	else
		local stats = playerLives[player.UserId]
		hasFreeCodeSlots = stats and (stats.FreeSaveSlotsUnlocked == true or (stats.Codes and stats.Codes.FreeSaveSlotsUnlocked == true)) or false
	end
	local hasSaveSlotsAccess = hasVIP or hasExtraSaveSlots or hasFreeCodeSlots
	local payload = BitKaisenSaveSystem.GetSlots(player, hasSaveSlotsAccess)
	payload.HasVIP = hasVIP
	payload.HasExtraSaveSlots = hasExtraSaveSlots
	payload.HasFreeCodeSlots = hasFreeCodeSlots
	payload.HasSaveSlotsAccess = hasSaveSlotsAccess
	payload.VIPGamePassId = VIP_SORCERER_PASS_ID
	payload.ExtraSaveSlotsGamePassId = EXTRA_SAVE_SLOTS_PASS_ID
	payload.FreeSlotCount = 1
	return payload
end

function clearPendingPlayerState(player)
	pendingMissions[player.UserId] = nil
	pendingLegacy[player.UserId] = nil
	if BK_CombatService.ClearCurrentFight then
		BK_CombatService.ClearCurrentFight(player, "clear pending state")
	end
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
		syncMonetizationEntitlements(player, loaded)
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
			RequirementText = "Age 16+ and 25+ Cursed Energy.",
			Description = "You accept physical backlash so your cursed energy output spikes harder in dangerous fights.",
			CostText = "-15 Health now. Your body carries the strain of this vow.",
			BonusText = "+45 Cursed Energy, +8 Technique Mastery, and +6 Reputation now.",
			MinAge = 16,
			RequiresCursedEnergy = 25,
			Effects = { Health = -15, CursedEnergy = 45, TechniqueMastery = 8, Reputation = 6 },
			BreakCostText = "Breaking this vow causes cursed backlash: -20 Health, -20 Cursed Energy, -6 Technique Mastery, and -12 Reputation.",
			BreakEffects = { Health = -20, CursedEnergy = -20, TechniqueMastery = -6, Reputation = -12 }
		},
		{
			Id = "vow_of_silence",
			Name = "Vow of Silence",
			RequirementText = "Age 16+ and a cursed technique.",
			Description = "You refuse to explain your technique openly, forcing sharper control through secrecy.",
			CostText = "-10 Happiness now. Social bonds become colder.",
			BonusText = "+14 Technique Mastery, +8 Smarts, and +10 Cursed Energy now.",
			MinAge = 16,
			RequiresTechnique = true,
			Effects = { Happiness = -10, TechniqueMastery = 14, Smarts = 8, CursedEnergy = 10 },
			BreakCostText = "Breaking this vow exposes your carelessness: -18 Happiness, -8 Smarts, -8 Technique Mastery, and -8 Reputation.",
			BreakEffects = { Happiness = -18, Smarts = -8, TechniqueMastery = -8, Reputation = -8 }
		},
		{
			Id = "vow_of_poverty",
			Name = "Vow of Poverty",
			RequirementText = "Age 16+.",
			Description = "You cut your attachment to comfort and money, turning discipline into cursed growth.",
			CostText = "Lose 50% of current money.",
			BonusText = "+35 Cursed Energy, +10 Smarts, and +6 Reputation now.",
			MinAge = 16,
			Effects = { CursedEnergy = 35, Smarts = 10, Reputation = 6 },
			MoneyPercentCost = 0.50,
			BreakCostText = "Breaking this vow drags you back into attachment: lose 25% of current money, -25 Cursed Energy, -8 Smarts, and -8 Reputation.",
			BreakEffects = { CursedEnergy = -25, Smarts = -8, Reputation = -8 },
			BreakMoneyPercentCost = 0.25
		},
		{
			Id = "vow_of_risk",
			Name = "Vow of Risk",
			RequirementText = "Age 16+ and Sorcerer status.",
			Description = "You accept harsher consequences for failure in exchange for faster battle growth.",
			CostText = "-12 Happiness and -8 Health now.",
			BonusText = "+32 Cursed Energy, +9 Reputation, +7 Technique Mastery, and +2 Recommendations now.",
			MinAge = 16,
			RequiresSorcerer = true,
			Effects = { Happiness = -12, Health = -8, CursedEnergy = 32, Reputation = 9, TechniqueMastery = 7, TeacherRecommendations = 2 },
			BreakCostText = "Breaking this vow marks you as unreliable: -15 Health, -18 Reputation, -6 Technique Mastery, and -2 Recommendations.",
			BreakEffects = { Health = -15, Reputation = -18, TechniqueMastery = -6, TeacherRecommendations = -2 }
		},
		{
			Id = "vow_of_restraint",
			Name = "Vow of Restraint",
			RequirementText = "Age 16+ and a cursed technique.",
			Description = "You limit careless technique use, building cleaner control every time you hold back.",
			CostText = "-8 Happiness and -8 Reputation now.",
			BonusText = "+18 Technique Mastery, +10 Smarts, and +14 Cursed Energy now.",
			MinAge = 16,
			RequiresTechnique = true,
			Effects = { Happiness = -8, Reputation = -8, TechniqueMastery = 18, Smarts = 10, CursedEnergy = 14 },
			BreakCostText = "Breaking this vow ruins your control: -15 Technique Mastery, -10 Smarts, -10 Cursed Energy, and -10 Reputation.",
			BreakEffects = { TechniqueMastery = -15, Smarts = -10, CursedEnergy = -10, Reputation = -10 }
		},
		{
			Id = "vow_of_bloodline",
			Name = "Vow of Bloodline",
			RequirementText = "Age 20+.",
			Description = "You bind part of your life to your future legacy, making your name carry more weight.",
			CostText = "-18 Health and -12 Happiness now.",
			BonusText = "+18 Reputation, +28 Cursed Energy, +10 Clan Reputation, and +2 Recommendations now.",
			MinAge = 20,
			Effects = { Health = -18, Happiness = -12, Reputation = 18, CursedEnergy = 28, ClanReputation = 10, TeacherRecommendations = 2 },
			BreakCostText = "Breaking this vow damages your legacy: -25 Reputation, -15 Clan Reputation, -20 Cursed Energy, and -2 Recommendations.",
			BreakEffects = { Reputation = -25, ClanReputation = -15, CursedEnergy = -20, TeacherRecommendations = -2 }
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

	function normalizeBrokenBindingVows(stats)
		stats.BrokenBindingVows = stats.BrokenBindingVows or {}

		local normalized = {}
		local seen = {}

		for _, vowValue in ipairs(stats.BrokenBindingVows) do
			local vowId = nil

			if typeof(vowValue) == "table" then
				vowId = vowValue.Id
			else
				vowId = tostring(vowValue)
			end

			if vowId and vowId ~= "" and not seen[vowId] then
				seen[vowId] = true
				table.insert(normalized, vowId)
			end
		end

		stats.BrokenBindingVows = normalized
		return normalized
	end

	function playerBrokeBindingVow(stats, vowId)
		local brokenVows = normalizeBrokenBindingVows(stats)

		for _, brokenVowId in ipairs(brokenVows) do
			if brokenVowId == vowId then
				return true
			end
		end

		return false
	end

	function removeActiveBindingVow(stats, vowId)
		local activeVows = normalizeActiveVows(stats)
		local filtered = {}

		for _, activeVowId in ipairs(activeVows) do
			if activeVowId ~= vowId then
				table.insert(filtered, activeVowId)
			end
		end

		stats.ActiveVows = filtered
		return filtered
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

		if playerBrokeBindingVow(stats, vow.Id) then
			return false, "You broke this vow once. It cannot be remade in this life."
		end

		if playerHasBindingVow(stats, vow.Id) then
			return false, "You already made this vow."
		end

		return true, "Available"
	end

	function applyBindingVowEffects(stats, vow, player)
		local effects = vow.Effects or {}
		local negReduction = (player and ownsBindingVowSpecialistPass(player)) and 0.75 or 1

		if vow.MoneyPercentCost then
			local currentMoney = math.max(0, tonumber(stats.Money) or 0)
			stats.Money = math.max(0, currentMoney - math.floor(currentMoney * vow.MoneyPercentCost * negReduction))
		end

		if effects.Health then
			local val = effects.Health
			stats.Health = math.clamp((tonumber(stats.Health) or 100) + (val < 0 and math.floor(val * negReduction) or val), 0, 100)
		end

		if effects.Happiness then
			local val = effects.Happiness
			stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) + (val < 0 and math.floor(val * negReduction) or val), 0, 100)
		end

		if effects.Smarts then
			local val = effects.Smarts
			stats.Smarts = math.clamp((tonumber(stats.Smarts) or 0) + (val < 0 and math.floor(val * negReduction) or val), 0, 100)
		end

		if effects.CursedEnergy then
			local val = effects.CursedEnergy
			stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + (val < 0 and math.floor(val * negReduction) or val))
		end

		if effects.TechniqueMastery then
			local val = effects.TechniqueMastery
			stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + (val < 0 and math.floor(val * negReduction) or val), 0, 100)
		end

		if effects.Reputation then
			local val = effects.Reputation
			stats.Reputation = (tonumber(stats.Reputation) or 0) + (val < 0 and math.floor(val * negReduction) or val)
		end

		if effects.ClanReputation then
			local val = effects.ClanReputation
			stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) + (val < 0 and math.floor(val * negReduction) or val))
		end

		if effects.TeacherRecommendations then
			local val = effects.TeacherRecommendations
			stats.TeacherRecommendations = math.max(0, (tonumber(stats.TeacherRecommendations) or 0) + (val < 0 and math.floor(val * negReduction) or val))
		end
	end


	----------------------------------------------------------------
	-- CUSTOM BINDING VOW CONTRACTS
	-- Self-imposed vows built from a signed contract-style menu.
	----------------------------------------------------------------

	local CUSTOM_VOW_SEVERITIES = {
		{
			Id = "minor",
			Name = "Minor",
			Power = 1,
			RequirementText = "Age 16+.",
			BacklashMultiplier = 1
		},
		{
			Id = "serious",
			Name = "Serious",
			Power = 2,
			RequirementText = "Age 16+ and 35+ Cursed Energy.",
			BacklashMultiplier = 2
		},
		{
			Id = "deathly",
			Name = "Deathly",
			Power = 3,
			RequirementText = "Age 18+ and 75+ Cursed Energy.",
			BacklashMultiplier = 3
		}
	}

	local CUSTOM_VOW_SACRIFICES = {
		{
			Id = "body",
			Name = "Body",
			Line = "I offer my body to the vow.",
			BuildCostText = function(power)
				return "-" .. tostring(8 * power) .. " Health now"
			end,
			Apply = function(stats, power)
				stats.Health = math.clamp((tonumber(stats.Health) or 100) - (8 * power), 0, 100)
			end,
			BreakText = function(power)
				return "-" .. tostring(8 * power) .. " Health backlash"
			end,
			Break = function(stats, power)
				stats.Health = math.clamp((tonumber(stats.Health) or 100) - (8 * power), 0, 100)
			end
		},
		{
			Id = "joy",
			Name = "Joy",
			Line = "I offer my peace of mind to the vow.",
			BuildCostText = function(power)
				return "-" .. tostring(10 * power) .. " Happiness now"
			end,
			Apply = function(stats, power)
				stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - (10 * power), 0, 100)
			end,
			BreakText = function(power)
				return "-" .. tostring(8 * power) .. " Happiness backlash"
			end,
			Break = function(stats, power)
				stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - (8 * power), 0, 100)
			end
		},
		{
			Id = "wealth",
			Name = "Wealth",
			Line = "I offer my attachment to wealth to the vow.",
			BuildCostText = function(power)
				return "Lose " .. tostring(15 * power) .. "% of current money"
			end,
			Apply = function(stats, power)
				local money = math.max(0, tonumber(stats.Money) or 0)
				stats.Money = math.max(0, money - math.floor(money * (0.15 * power)))
			end,
			BreakText = function(power)
				return "Lose " .. tostring(10 * power) .. "% of current money as backlash"
			end,
			Break = function(stats, power)
				local money = math.max(0, tonumber(stats.Money) or 0)
				stats.Money = math.max(0, money - math.floor(money * (0.10 * power)))
			end
		},
		{
			Id = "name",
			Name = "Name",
			Line = "I offer my public standing to the vow.",
			BuildCostText = function(power)
				return "-" .. tostring(7 * power) .. " Reputation now"
			end,
			Apply = function(stats, power)
				stats.Reputation = (tonumber(stats.Reputation) or 0) - (7 * power)
			end,
			BreakText = function(power)
				return "-" .. tostring(10 * power) .. " Reputation backlash"
			end,
			Break = function(stats, power)
				stats.Reputation = (tonumber(stats.Reputation) or 0) - (10 * power)
			end
		},
		{
			Id = "control",
			Name = "Control",
			Line = "I offer part of my refined control to the vow.",
			BuildCostText = function(power)
				return "-" .. tostring(4 * power) .. " Technique Mastery now"
			end,
			Apply = function(stats, power)
				stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) - (4 * power), 0, 100)
			end,
			BreakText = function(power)
				return "-" .. tostring(5 * power) .. " Technique Mastery backlash"
			end,
			Break = function(stats, power)
				stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) - (5 * power), 0, 100)
			end
		},
		{
			Id = "reserves",
			Name = "Reserves",
			Line = "I offer stored cursed energy to the vow.",
			BuildCostText = function(power)
				return "-" .. tostring(18 * power) .. " Cursed Energy now"
			end,
			Apply = function(stats, power)
				stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) - (18 * power))
			end,
			BreakText = function(power)
				return "-" .. tostring(15 * power) .. " Cursed Energy backlash"
			end,
			Break = function(stats, power)
				stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) - (15 * power))
			end
		}
	}

	local CUSTOM_VOW_REWARDS = {
		{
			Id = "cursed_energy",
			Name = "Cursed Energy",
			Line = "In return, my cursed energy shall deepen.",
			BuildGainText = function(power)
				return "+" .. tostring(28 * power) .. " Cursed Energy now"
			end,
			Apply = function(stats, power)
				stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + (28 * power))
			end,
			BreakText = function(power)
				return "-" .. tostring(18 * power) .. " Cursed Energy"
			end,
			Break = function(stats, power)
				stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) - (18 * power))
			end
		},
		{
			Id = "mastery",
			Name = "Technique Mastery",
			Line = "In return, my technique shall sharpen.",
			BuildGainText = function(power)
				return "+" .. tostring(7 * power) .. " Technique Mastery now"
			end,
			Apply = function(stats, power)
				stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + (7 * power), 0, 100)
			end,
			BreakText = function(power)
				return "-" .. tostring(5 * power) .. " Technique Mastery"
			end,
			Break = function(stats, power)
				stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) - (5 * power), 0, 100)
			end
		},
		{
			Id = "recognition",
			Name = "Reputation",
			Line = "In return, my deeds shall be recognized.",
			BuildGainText = function(power)
				return "+" .. tostring(10 * power) .. " Reputation now"
			end,
			Apply = function(stats, power)
				stats.Reputation = (tonumber(stats.Reputation) or 0) + (10 * power)
			end,
			BreakText = function(power)
				return "-" .. tostring(8 * power) .. " Reputation"
			end,
			Break = function(stats, power)
				stats.Reputation = (tonumber(stats.Reputation) or 0) - (8 * power)
			end
		},
		{
			Id = "recommendations",
			Name = "Recommendations",
			Line = "In return, higher-ups shall notice my value.",
			BuildGainText = function(power)
				return "+" .. tostring(1 * power) .. " Teacher Recommendations now"
			end,
			Apply = function(stats, power)
				stats.TeacherRecommendations = math.max(0, (tonumber(stats.TeacherRecommendations) or 0) + power)
			end,
			BreakText = function(power)
				return "-" .. tostring(1 * power) .. " Teacher Recommendations"
			end,
			Break = function(stats, power)
				stats.TeacherRecommendations = math.max(0, (tonumber(stats.TeacherRecommendations) or 0) - power)
			end
		},
		{
			Id = "clan",
			Name = "Clan Reputation",
			Line = "In return, my family name shall carry more weight.",
			BuildGainText = function(power)
				return "+" .. tostring(8 * power) .. " Clan Reputation now"
			end,
			Apply = function(stats, power)
				stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) + (8 * power))
			end,
			BreakText = function(power)
				return "-" .. tostring(7 * power) .. " Clan Reputation"
			end,
			Break = function(stats, power)
				stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) - (7 * power))
			end
		}
	}

	local function getCustomOption(list, id)
		for _, option in ipairs(list) do
			if option.Id == id then
				return option
			end
		end

		return nil
	end

	local function normalizeCustomBindingVows(stats)
		stats.CustomBindingVows = stats.CustomBindingVows or {}

		for _, vow in ipairs(stats.CustomBindingVows) do
			vow.Id = tostring(vow.Id or ("custom_" .. tostring(math.random(100000, 999999))))
			vow.Name = tostring(vow.Name or "Custom Binding Vow")
			vow.Status = tostring(vow.Status or "Active")
			vow.Power = tonumber(vow.Power) or 1
			vow.Age = tonumber(vow.Age) or tonumber(stats.Age) or 0
		end

		return stats.CustomBindingVows
	end

	local function activeCustomVowCount(stats)
		local count = 0
		for _, vow in ipairs(normalizeCustomBindingVows(stats)) do
			if vow.Status == "Active" then
				count += 1
			end
		end

		return count
	end

	local function buildCustomContractPreview(sacrifice, reward, severity)
		local power = tonumber(severity.Power) or 1
		local name = severity.Name .. " Vow of " .. reward.Name

		return {
			Name = name,
			Description = sacrifice.Line .. " " .. reward.Line,
			RequirementText = severity.RequirementText,
			CostText = sacrifice.BuildCostText(power),
			BonusText = reward.BuildGainText(power),
			BreakCostText = "Breaking this signed vow causes backlash: " .. sacrifice.BreakText(power) .. ", " .. reward.BreakText(power) .. ", and -" .. tostring(8 * power) .. " Reputation."
		}
	end

	local function buildCustomOptionPayload()
		local sacrifices = {}
		local rewards = {}
		local severities = {}

		for _, option in ipairs(CUSTOM_VOW_SACRIFICES) do
			table.insert(sacrifices, {
				Id = option.Id,
				Name = option.Name,
				Line = option.Line
			})
		end

		for _, option in ipairs(CUSTOM_VOW_REWARDS) do
			table.insert(rewards, {
				Id = option.Id,
				Name = option.Name,
				Line = option.Line
			})
		end

		for _, option in ipairs(CUSTOM_VOW_SEVERITIES) do
			table.insert(severities, {
				Id = option.Id,
				Name = option.Name,
				RequirementText = option.RequirementText
			})
		end

		return {
			Sacrifices = sacrifices,
			Rewards = rewards,
			Severities = severities
		}
	end

	local function canMakeCustomBindingVow(player, stats, sacrifice, reward, severity)
		if not stats or stats.Alive == false then
			return false, "You do not have an active life."
		end

		local matchingRewardBySacrifice = {
			control = "mastery",
			name = "recognition",
			reserves = "cursed_energy"
		}

		if matchingRewardBySacrifice[sacrifice.Id] == reward.Id then
			return false, "A custom vow cannot sacrifice and reward the same stat."
		end

		local age = tonumber(stats.Age) or 0
		local ce = tonumber(stats.CursedEnergy) or 0

		if age < 16 then
			return false, "Custom vows unlock at age 16."
		end

		if severity.Id == "serious" and ce < 35 then
			return false, "Serious custom vows require 35+ Cursed Energy."
		end

		if severity.Id == "deathly" then
			if age < 18 then
				return false, "Deathly custom vows require age 18+."
			end

			if ce < 75 then
				return false, "Deathly custom vows require 75+ Cursed Energy."
			end
		end

		local vowLimit = ownsBindingVowSpecialistPass(player) and 5 or 3
		if activeCustomVowCount(stats) >= vowLimit then
			return false, "You can only hold " .. tostring(vowLimit) .. " custom vows in one life."
		end

		if sacrifice.Id == "reserves" and ce < (18 * severity.Power) then
			return false, "You do not have enough Cursed Energy to offer."
		end

		return true, "Available"
	end

	local function makeCustomBindingVow(player, contract)
		local stats = playerLives[player.UserId]

		if typeof(contract) ~= "table" then
			return false, "Invalid contract."
		end

		if not stats or not stats.Alive then
			return false, "You do not have an active life."
		end

		ensureExtraStats(stats)
		normalizeCustomBindingVows(stats)

		local sacrifice = getCustomOption(CUSTOM_VOW_SACRIFICES, tostring(contract.SacrificeId or ""))
		local reward = getCustomOption(CUSTOM_VOW_REWARDS, tostring(contract.RewardId or ""))
		local severity = getCustomOption(CUSTOM_VOW_SEVERITIES, tostring(contract.SeverityId or ""))

		if not sacrifice then
			return false, "Choose a valid sacrifice."
		end

		if not reward then
			return false, "Choose a valid reward."
		end

		if not severity then
			return false, "Choose a valid vow strength."
		end

		local canMake, reason = canMakeCustomBindingVow(player, stats, sacrifice, reward, severity)
		if not canMake then
			return false, reason
		end

		local power = tonumber(severity.Power) or 1
		local sacrificePower = ownsBindingVowSpecialistPass(player) and (power * 0.75) or power
		local preview = buildCustomContractPreview(sacrifice, reward, severity)
		local customId = "custom_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))

		sacrifice.Apply(stats, sacrificePower)
		reward.Apply(stats, power)

		local customVow = {
			Id = customId,
			Name = preview.Name,
			Description = preview.Description,
			RequirementText = preview.RequirementText,
			CostText = preview.CostText,
			BonusText = preview.BonusText,
			BreakCostText = preview.BreakCostText,
			SacrificeId = sacrifice.Id,
			RewardId = reward.Id,
			SeverityId = severity.Id,
			Power = power,
			Status = "Active",
			Age = stats.Age,
			Month = stats.CurrentMonth
		}

		table.insert(stats.CustomBindingVows, customVow)

		stats.BindingVowHistory = stats.BindingVowHistory or {}
		table.insert(stats.BindingVowHistory, {
			Id = customVow.Id,
			Name = customVow.Name,
			Custom = true,
			Age = stats.Age,
			Month = stats.CurrentMonth
		})

		local logMessage = tSys(player, "vow_signed", { name = customVow.Name, cost = customVow.CostText, bonus = customVow.BonusText },
			"<font color='#ffcd69'><b>[ SIGNED VOW ]</b></font> You signed the <b>" .. customVow.Name .. "</b>. " .. customVow.CostText .. ". " .. customVow.BonusText .. ".")
		fireLifeUpdate(player, stats, logMessage)

		saveStats(player)

		return true, "You signed the " .. customVow.Name .. "."
	end

	local function breakCustomBindingVow(player, customVowId)
		local stats = playerLives[player.UserId]

		if not stats or not stats.Alive then
			return false, "You do not have an active life."
		end

		ensureExtraStats(stats)
		local customVows = normalizeCustomBindingVows(stats)
		local target = nil

		for _, vow in ipairs(customVows) do
			if vow.Id == customVowId then
				target = vow
				break
			end
		end

		if not target then
			return false, "Unknown custom vow."
		end

		if target.Status ~= "Active" then
			return false, "This custom vow is not active."
		end

		local sacrifice = getCustomOption(CUSTOM_VOW_SACRIFICES, tostring(target.SacrificeId or ""))
		local reward = getCustomOption(CUSTOM_VOW_REWARDS, tostring(target.RewardId or ""))
		local power = tonumber(target.Power) or 1

		if sacrifice then
			sacrifice.Break(stats, power)
		end

		if reward then
			reward.Break(stats, power)
		end

		stats.Reputation = (tonumber(stats.Reputation) or 0) - (8 * power)

		target.Status = "Broken"
		target.BrokenAge = stats.Age
		target.BrokenMonth = stats.CurrentMonth

		stats.BindingVowBreakHistory = stats.BindingVowBreakHistory or {}
		table.insert(stats.BindingVowBreakHistory, {
			Id = target.Id,
			Name = target.Name,
			Custom = true,
			Age = stats.Age,
			Month = stats.CurrentMonth
		})

		local breakText = tostring(target.BreakCostText or "The vow backlash damages your cursed energy.")
		local logMessage = tSys(player, "vow_broken_contract", { name = target.Name, text = breakText },
			"<font color='#e64e5f'><b>[ BROKEN CONTRACT ]</b></font> You broke the <b>" .. tostring(target.Name) .. "</b>. " .. breakText)
		fireLifeUpdate(player, stats, logMessage)

		saveStats(player)

		return true, "You broke the " .. tostring(target.Name) .. "."
	end


	function buildBindingVowPayload(stats)
		ensureExtraStats(stats)
		normalizeActiveVows(stats)

		normalizeBrokenBindingVows(stats)

		normalizeCustomBindingVows(stats)

		local payload = {
			ActiveVows = stats.ActiveVows,
			BrokenBindingVows = stats.BrokenBindingVows,
			CustomVows = {},
			CustomOptions = buildCustomOptionPayload(),
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
				BreakCostText = vow.BreakCostText or "Breaking this vow causes cursed backlash.",
				Owned = playerHasBindingVow(stats, vow.Id),
				Broken = playerBrokeBindingVow(stats, vow.Id),
				CanBreak = playerHasBindingVow(stats, vow.Id),
				CanMake = canMake,
				Reason = reason
			})
		end

		for _, customVow in ipairs(stats.CustomBindingVows or {}) do
			table.insert(payload.CustomVows, {
				Id = customVow.Id,
				Name = customVow.Name,
				Description = customVow.Description,
				RequirementText = customVow.RequirementText,
				CostText = customVow.CostText,
				BonusText = customVow.BonusText,
				BreakCostText = customVow.BreakCostText,
				Owned = customVow.Status == "Active",
				Broken = customVow.Status == "Broken",
				CanBreak = customVow.Status == "Active",
				CanMake = false,
				Reason = customVow.Status == "Broken" and "This signed vow has already been broken." or "Signed custom vow."
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

		applyBindingVowEffects(stats, vow, player)

		stats.ActiveVows = normalizeActiveVows(stats)
		table.insert(stats.ActiveVows, vow.Id)

		stats.BindingVowHistory = stats.BindingVowHistory or {}
		table.insert(stats.BindingVowHistory, {
			Id = vow.Id,
			Name = vow.Name,
			Age = stats.Age,
			Month = stats.CurrentMonth
		})

		local logMessage = tSys(player, "vow_made", { name = vow.Name, cost = vow.CostText, bonus = vow.BonusText },
			"<font color='#ffcd69'><b>[ BINDING VOW ]</b></font> You made the <b>" .. vow.Name .. "</b>. " .. vow.CostText .. " " .. vow.BonusText)
		fireLifeUpdate(player, stats, logMessage)

		saveStats(player)

		return true, "You made the " .. vow.Name .. "."
	end


	function applyBrokenBindingVowEffects(stats, vow)
		local effects = vow.BreakEffects or {}

		if vow.BreakMoneyPercentCost then
			local currentMoney = math.max(0, tonumber(stats.Money) or 0)
			stats.Money = math.max(0, currentMoney - math.floor(currentMoney * vow.BreakMoneyPercentCost))
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

		if effects.TechniqueMastery and hasTechnique(stats) then
			stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + effects.TechniqueMastery, 0, 100)
		end

		if effects.Reputation then
			stats.Reputation = (tonumber(stats.Reputation) or 0) + effects.Reputation
		end

		if effects.ClanReputation then
			stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) + effects.ClanReputation)
		end

		if effects.TeacherRecommendations then
			stats.TeacherRecommendations = math.max(0, (tonumber(stats.TeacherRecommendations) or 0) + effects.TeacherRecommendations)
		end
	end

	function breakBindingVow(player, vowId)
		local stats = playerLives[player.UserId]

		if not stats or not stats.Alive then
			return false, "You do not have an active life."
		end

		ensureExtraStats(stats)
		normalizeActiveVows(stats)
		normalizeBrokenBindingVows(stats)

		local vow = getBindingVowById(vowId)
		if not vow then
			return false, "Unknown Binding Vow."
		end

		if not playerHasBindingVow(stats, vow.Id) then
			return false, "You have not made this vow."
		end

		removeActiveBindingVow(stats, vow.Id)
		applyBrokenBindingVowEffects(stats, vow)

		if not playerBrokeBindingVow(stats, vow.Id) then
			table.insert(stats.BrokenBindingVows, vow.Id)
		end

		stats.BindingVowBreakHistory = stats.BindingVowBreakHistory or {}
		table.insert(stats.BindingVowBreakHistory, {
			Id = vow.Id,
			Name = vow.Name,
			Age = stats.Age,
			Month = stats.CurrentMonth
		})

		local breakText = tostring(vow.BreakCostText or "The vow backlash damages your cursed energy.")
		local logMessage = tSys(player, "vow_broken", { name = vow.Name, text = breakText },
			"<font color='#e64e5f'><b>[ BROKEN VOW ]</b></font> You broke the <b>" .. tostring(vow.Name) .. "</b>. " .. breakText)
		fireLifeUpdate(player, stats, logMessage)

		saveStats(player)

		return true, "You broke the " .. tostring(vow.Name) .. "."
	end



	getBindingVows.OnServerInvoke = function(player)
		local stats = playerLives[player.UserId]

		if not stats then
			return {
				ActiveVows = {},
				BrokenBindingVows = {},
				CustomVows = {},
				CustomOptions = buildCustomOptionPayload(),
				Vows = {}
			}
		end

		return buildBindingVowPayload(stats)
	end

	bindingVowAction.OnServerEvent:Connect(function(player, actionId, vowPayload)
		if not checkRateLimit(player, "BindingVowAction") then
			return
		end

		if actionId ~= "MakeVow" and actionId ~= "BreakVow" and actionId ~= "MakeCustomVow" and actionId ~= "BreakCustomVow" then
			return
		end

		local ok, message

		if actionId == "MakeCustomVow" then
			ok, message = makeCustomBindingVow(player, vowPayload)
		elseif actionId == "BreakCustomVow" then
			if typeof(vowPayload) ~= "string" then
				return
			end
			ok, message = breakCustomBindingVow(player, vowPayload)
		elseif actionId == "BreakVow" then
			if typeof(vowPayload) ~= "string" then
				return
			end
			ok, message = breakBindingVow(player, vowPayload)
		else
			if typeof(vowPayload) ~= "string" then
				return
			end
			ok, message = makeBindingVow(player, vowPayload)
		end

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
		Title = "Witnesses Gather",
		Body = "A curse incident happens in public. Civilians are watching too closely, and your face might become part of the story.",
		MinAge = 16,
		MaxAge = 80,
		Weight = 6,
		RequiresSorcerer = true,
		Options = {
			{ Text = "Scatter the witnesses", Description = "You forced the crowd away. The cleanup worked, but people complained loudly.", Effects = { Reputation = -2, Happiness = -1 } },
			{ Text = "Hide your face", Description = "You focused on staying unseen while handling the problem. It was not clean, but it worked.", Effects = { Smarts = 3, Reputation = 1 } },
			{ Text = "Finish fast", Description = "You ignored the witnesses and ended the incident quickly. The story became rumor before officials buried it.", Effects = { Reputation = 4, CursedEnergy = -4 } },
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
		Id = "world_special_grade_outbreak",
		Title = "Special Grade Outbreak",
		Body = "A special grade curse outbreak tears through a nearby district. If containment fails, the whole region may fall under cursed energy.",
		MinAge = 16,
		MaxAge = 90,
		Weight = 2,
		RequiresSorcerer = true,
		Options = {
			{ Text = "Join containment", Chance = 55, SuccessText = "You helped seal the outbreak before it spread. Survivors started repeating your name.", FailText = "Containment collapsed. The last thing you heard was the city going quiet under cursed energy.", SuccessEffects = { Reputation = 10, CursedEnergy = 8, TechniqueMastery = 3, Health = -8, Fame = 6 }, FailEffects = { Kill = true, DeathReason = "Killed during a special grade curse outbreak", DeathMessage = "A special grade curse outbreak consumed the district. The world felt colder after you failed the stat check." } },
			{ Text = "Evacuate civilians", Description = "You focused on saving people instead of winning the fight. The outbreak scarred the region, but many survived.", Effects = { Reputation = 6, Health = -5, Happiness = -4, Fame = 4 } },
			{ Text = "Retreat and report", Description = "You retreated before the curse identified you. Officials disliked it, but your warning helped prepare the next team.", Effects = { Smarts = 5, Reputation = -2, Happiness = -2 } },
		}
	},
	{
		Id = "high_rep_assassination_attempt",
		Title = "Assassination Attempt",
		Body = "Your reputation has made you a target. A hired sorcerer waits near your route home, hiding their cursed energy until the last second.",
		MinAge = 16,
		MaxAge = 95,
		Weight = 3,
		MinReputation = 80,
		Options = {
			{ Text = "Counterattack", Chance = 60, SuccessText = "You read the ambush and broke their timing. The attempt only made your name louder.", FailText = "The ambush landed before you could fully react. You survived, barely.", SuccessEffects = { Reputation = 8, CursedEnergy = 4, Fame = 4 }, FailEffects = { Health = -24, Happiness = -6 } },
			{ Text = "Escape through a crowd", Description = "You used the city around you and disappeared before the second strike.", Effects = { Smarts = 5, Reputation = 1, Happiness = -2 } },
			{ Text = "Track the client", Description = "You followed the money instead of the blade. Someone powerful now knows you are looking back.", Effects = { Smarts = 4, Reputation = 4, Fear = 3 } },
		}
	},
	{
		Id = "low_rep_hunter_ambush",
		Title = "Hunter Ambush",
		Body = "Your reputation has fallen low enough that hunters stop asking questions. A small team corners you and calls it justice.",
		MinAge = 16,
		MaxAge = 95,
		Weight = 3,
		MaxReputation = -40,
		Options = {
			{ Text = "Fight dirty", Chance = 50, SuccessText = "You survived by making the fight ugly. The rumor will not make you look better.", FailText = "The hunters overwhelmed you and left you broken in the street.", SuccessEffects = { CursedEnergy = 5, Fear = 5, Reputation = -4, Health = -8 }, FailEffects = { Health = -35, Happiness = -8 } },
			{ Text = "Surrender the truth", Description = "You explained enough to stop the execution. It cost pride, but you walked away.", Effects = { Reputation = 4, Happiness = -4 } },
			{ Text = "Vanish", Description = "You escaped before the formation closed. People will call that guilt, but breathing matters first.", Effects = { Smarts = 5, Reputation = -2, Fear = 2 } },
		}
	},
	{
		Id = "rogue_sorcerer_encounter",
		Title = "Rogue Sorcerer Encounter",
		Body = "A rogue sorcerer recognizes the way you move and offers a private exchange: information, favors, or a duel away from witnesses.",
		MinAge = 15,
		MaxAge = 90,
		Weight = 5,
		RequiresSorcerer = true,
		Options = {
			{ Text = "Trade information", Description = "The exchange was tense, but useful. You learned how rogues avoid official tracking.", Effects = { Smarts = 5, Reputation = -1 } },
			{ Text = "Accept the duel", Chance = 55, SuccessText = "You won the private duel and left with sharper instincts.", FailText = "The rogue outplayed you and walked away laughing.", SuccessEffects = { CursedEnergy = 6, TechniqueMastery = 3, Reputation = 3 }, FailEffects = { Health = -18, Happiness = -4 } },
			{ Text = "Report them", Description = "You reported the rogue trail. Officials appreciated it, but the underworld noticed your choice.", Effects = { Reputation = 5, Fear = 2 } },
		}
	},
	{
		Id = "cursed_object_discovery_choice",
		Title = "Cursed Object Discovery",
		Body = "You uncover a sealed cursed object that pulses when your hand gets close. It feels valuable, dangerous, and strangely patient.",
		MinAge = 10,
		MaxAge = 90,
		Weight = 4,
		Options = {
			{ Text = "Seal it properly", Description = "You reinforced the seal and avoided a disaster. The restraint taught you more than touching it would have.", Effects = { Smarts = 5, Reputation = 2, CursedObjectAnchorProgress = 10 } },
			{ Text = "Study it", Chance = 65, SuccessText = "You studied the object without waking it. Its residue improved your cursed energy control.", FailText = "The seal bit into your hand and left your body shaking.", SuccessEffects = { CursedEnergy = 8, TechniqueMastery = 2, Smarts = 3, CursedObjectAnchorProgress = 18 }, FailEffects = { Health = -16, Happiness = -5, CursedEnergy = 3, CursedObjectAnchorProgress = 8 } },
			{ Text = "Sell it", Description = "You sold the object before it became your problem. The money helped, but the decision felt dirty.", Effects = { Money = 2500, Reputation = -3, Happiness = -2, CursedObjectAnchorProgress = 3 } },
		}
	},
	{
		Id = "randomized_sorcerer_tournament",
		Title = "Underground Tournament",
		Body = "A small tournament invites sorcerers, rogues, and clan fighters under fake names. Nobody promises the fights will stay friendly.",
		MinAge = 15,
		MaxAge = 70,
		Weight = 4,
		RequiresSorcerer = true,
		Options = {
			{ Text = "Enter openly", Chance = 58, SuccessText = "You climbed through the bracket and left with new respect.", FailText = "You lost hard, but the fight exposed what you need to fix.", SuccessEffects = { Reputation = 8, Money = 1500, CursedEnergy = 5, Fame = 3 }, FailEffects = { Health = -15, CursedEnergy = 2, Happiness = -3 } },
			{ Text = "Enter under an alias", Description = "You fought carefully and kept your real name out of the bracket.", Effects = { Smarts = 4, CursedEnergy = 3, Money = 800 } },
			{ Text = "Scout opponents", Description = "You watched the bracket instead of joining. The styles you saw may matter later.", Effects = { Smarts = 6, TechniqueMastery = 1 } },
		}
	},
	{
		Id = "heian_blood_decree",
		Title = "Heian Blood Decree",
		Body = "A Heian-era lord demands proof that nearby sorcerers are loyal enough to be useful and dangerous enough to be feared.",
		MinAge = 14,
		MaxAge = 80,
		Weight = 4,
		RequiredEra = "Heian Era",
		Options = {
			{ Text = "Display power", Description = "Your display unsettled the court and earned grim approval.", Effects = { Reputation = 5, CursedEnergy = -4, Fear = 5 } },
			{ Text = "Speak carefully", Description = "You survived the room with measured words instead of wasted energy.", Effects = { Smarts = 5, Reputation = 2 } },
			{ Text = "Refuse the decree", Description = "You refused to be weighed like a weapon. The court remembered the insult.", Effects = { Reputation = -4, Happiness = 2, Fear = 2 } },
		}
	},
	{
		Id = "edo_hidden_registry",
		Title = "Edo Hidden Registry",
		Body = "A secret Edo record lists sorcerers who should be watched, hired, or erased. Your name appears in fresh ink.",
		MinAge = 14,
		MaxAge = 80,
		Weight = 4,
		RequiredEra = "Edo Era",
		Options = {
			{ Text = "Alter the record", Chance = 55, SuccessText = "You changed enough details to blur your trail.", FailText = "The registry keeper noticed the tampering and marked you as a risk.", SuccessEffects = { Smarts = 5, Reputation = 1 }, FailEffects = { Reputation = -4, Fear = 3 } },
			{ Text = "Copy the names", Description = "You copied other names from the registry. Information is its own weapon.", Effects = { Smarts = 6, Happiness = -1 } },
			{ Text = "Burn the page", Description = "You burned your page and turned suspicion into a larger mystery.", Effects = { Reputation = -2, Fear = 4, Happiness = 1 } },
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

function registerRogueSorcererLifeScenarios()
	local ROGUE_SCENARIOS = {
		{
			Id = "rogue_hidden_contract",
			Title = "Hidden Contract",
			Body = "An underground client offered payment for clearing a curse before Jujutsu High could claim the report.",
			MinAge = 13,
			MaxAge = 90,
			Weight = 10,
			RequiresRogueSorcerer = true,
			Options = {
				{ Text = "Take the contract", Description = "You completed the job quietly and took the money.", Effects = { Money = 900, CursedEnergy = 8, Reputation = -2 } },
				{ Text = "Refuse it", Description = "You refused the work and kept your trail quieter.", Effects = { Happiness = 1, Smarts = 2 } },
				{ Text = "Steal the intel", Description = "You took the information without taking the client seriously.", Effects = { Smarts = 4, WantedLevel = 1 } },
			}
		},
		{
			Id = "rogue_hunter_trace",
			Title = "Hunter Trace",
			Body = "Someone from Jujutsu society found signs of your cursed energy near an old mission site.",
			MinAge = 13,
			MaxAge = 90,
			Weight = 8,
			RequiresRogueSorcerer = true,
			Options = {
				{ Text = "Erase the trail", Description = "You spent the night covering your tracks.", Effects = { Smarts = 3, CursedEnergy = -4 } },
				{ Text = "Set a trap", Description = "You left a false lead for whoever was tracking you.", Effects = { TechniqueMastery = 3, WantedLevel = 1 } },
				{ Text = "Keep moving", Description = "You abandoned the area before anyone could corner you.", Effects = { Happiness = -2, Health = 2 } },
			}
		},
		{
			Id = "rogue_sorcerer_duel",
			Title = "Rogue Duel",
			Body = "Another rogue sorcerer challenged your reputation in a place where no teacher could interfere.",
			MinAge = 14,
			MaxAge = 90,
			Weight = 7,
			RequiresRogueSorcerer = true,
			Options = {
				{ Text = "Accept the duel", Description = "The fight sharpened your instincts, but the attention was dangerous.", Effects = { CursedEnergy = 10, TechniqueMastery = 4, Health = -8, WantedLevel = 1 } },
				{ Text = "Walk away", Description = "You refused to let pride choose your next injury.", Effects = { Smarts = 3, Reputation = -1 } },
				{ Text = "Ambush first", Description = "You ended the challenge before it became fair.", Effects = { CursedEnergy = 6, Reputation = -5, WantedLevel = 2 } },
			}
		},
	}

	for _, scenario in ipairs(ROGUE_SCENARIOS) do
		table.insert(RANDOM_LIFE_SCENARIOS, scenario)
	end
end

registerRogueSorcererLifeScenarios()



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

local function registerWorldReputationScenarios()
	local scenarios = {
		{
			Id = "world_public_curse_rescue",
			Title = "Public Curse Incident",
			Body = "A weak curse broke loose near civilians. People were watching, and so was someone from the jujutsu world.",
			MinAge = 12,
			Weight = 5,
			Options = {
				{ Text = "Protect the civilians first", Description = "You kept civilians safe before chasing the curse. The story spread in a cleaner way than most incidents do.", Effects = { Fame = 3, Reputation = 2, PathReputation = 2, Health = -2 } },
				{ Text = "Exorcise it fast", Description = "You ended the curse quickly. People remembered the pressure more than the details.", Effects = { Fame = 1, Fear = 2, CursedEnergy = 2, PathReputation = 1 } },
				{ Text = "Leave before anyone asks questions", Description = "You vanished before officials arrived. Fewer people knew your face, but rumors still formed.", Effects = { Smarts = 2, Fear = 1 } },
			}
		},
		{
			Id = "world_underground_offer",
			Title = "Underground Offer",
			Body = "A curse user sent word through back channels: your name has started moving in the underground.",
			MinAge = 14,
			Weight = 4,
			Options = {
				{ Text = "Refuse openly", Description = "You refused loudly enough that the message would travel back.", Effects = { Fame = 1, Fear = 1, Morality = 2, PathReputation = 1 } },
				{ Text = "Hear the offer", Description = "You listened and learned how reputation moves outside official records.", Effects = { Smarts = 3, Fear = 1, PathReputation = 2, Morality = -1 } },
				{ Text = "Use them for information", Description = "You took what they knew without promising loyalty. That kind of move gets remembered.", Effects = { Smarts = 2, Fame = 1, Fear = 2, Morality = -2, PathReputation = 2 } },
			}
		},
		{
			Id = "world_curse_rumor",
			Title = "Rumor With Your Name",
			Body = "A rumor spread that your cursed energy was seen at the center of a dangerous incident.",
			MinAge = 12,
			Weight = 4,
			Options = {
				{ Text = "Correct the story", Description = "You corrected the rumor before it got too ugly.", Effects = { Fame = 1, Fear = -1, Smarts = 1 } },
				{ Text = "Let the rumor grow", Description = "You let people believe the worst. Some doors close when people fear you, but others open.", Effects = { Fear = 3, PathReputation = 1, Morality = -1 } },
				{ Text = "Ask who started it", Description = "You traced the rumor back far enough to learn who benefits when your name spreads.", Effects = { Smarts = 3, Fame = 1 } },
			}
		},
	}

	for _, scenario in ipairs(scenarios) do
		table.insert(RANDOM_LIFE_SCENARIOS, scenario)
	end
end

registerWorldReputationScenarios()


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

	local isRogueSorcerer = tostring(stats.LifePath or "") == "Rogue Sorcerer" or tostring(stats.SocietyStatus or "") == "Rogue Sorcerer"
	if scenario.RequiresTechnique and not hasTechnique then return false end
	if scenario.RequiresSorcerer and not isSorcerer then return false end
	if scenario.RequiresCurseUser and not isCurseUser(stats) then return false end
	if scenario.RequiresRogueSorcerer and not isRogueSorcerer then return false end
	if scenario.MinReputation and (tonumber(stats.Reputation) or 0) < scenario.MinReputation then return false end
	if scenario.MaxReputation and (tonumber(stats.Reputation) or 0) > scenario.MaxReputation then return false end
	if scenario.RequiredEra then
		local eraText = tostring(stats.Era or stats.BirthEra or (stats.BirthPath and stats.BirthPath.Era) or "")
		if eraText ~= tostring(scenario.RequiredEra) then return false end
	end
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
		or string.find(scenarioText, "civilians are watching too closely", 1, true) ~= nil
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

local function getCurseExposureWeightBonus(stats, scenario)
	local exposure = tostring(stats and stats.EarlyCurseExposure or "Moderate")
	local exposureBonus = ({ Low = 0, Moderate = 2, High = 5, Extreme = 8 })[exposure] or 2
	if exposureBonus <= 0 or typeof(scenario) ~= "table" then
		return 0
	end
	local text = string.lower(table.concat({ tostring(scenario.Id or ""), tostring(scenario.Title or ""), tostring(scenario.Body or "") }, " "))
	if text:find("curse", 1, true) or text:find("cursed", 1, true) or text:find("finger", 1, true) or text:find("object", 1, true) or text:find("spirit", 1, true) then
		return exposureBonus
	end
	return 0
end

function rollRandomLifeScenario(stats, ignoreRecent)
	local possible = {}
	local totalWeight = 0

	for _, scenario in ipairs(RANDOM_LIFE_SCENARIOS) do
		if scenarioRequirementMet(stats, scenario) then
			if ignoreRecent or not recentlyUsedLifeScenario(stats, scenario.Id) then
				local weight = math.max(1, tonumber(scenario.Weight) or 5) + getCurseExposureWeightBonus(stats, scenario)
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

	local displayScenario = scenario
	local _sLang = BitKaisenLocale.getScenarioLocale(BitKaisenLocale.getPlayerLocale(player.UserId), scenario.Id)
	if _sLang then
		displayScenario = {}
		for k, v in pairs(scenario) do displayScenario[k] = v end
		if _sLang.title then displayScenario.Title = _sLang.title end
		if _sLang.body  then displayScenario.Body  = _sLang.body  end
		if _sLang.options and scenario.Options then
			local _opts = {}
			for i, opt in ipairs(scenario.Options) do
				local _topt = _sLang.options[i] or {}
				local _o = {}
				for k, v in pairs(opt) do _o[k] = v end
				if _topt.text then _o.Text = _topt.text end
				_opts[i] = _o
			end
			displayScenario.Options = _opts
		end
	end
	local displayOptions = buildScenarioOptions(displayScenario)

	showMissionSituation:FireClient(player, {
		Type = "RandomLifeScenario",
		Title = displayScenario.Title or "Life Scenario",
		MissionTitle = displayScenario.Title or "Life Scenario",
		Body = displayScenario.Body or "You need to make a choice.",
		Options = displayOptions
	})

	return true
end

function applyRandomLifeScenarioEffects(stats, effects)
	if not stats or typeof(effects) ~= "table" then
		return
	end

	if effects.Health then
		stats.Health = math.clamp((tonumber(stats.Health) or 100) + effects.Health, 0, 100)
		if (tonumber(stats.Age) or 0) <= 12 and effects.Health < 0 and math.random(1, 100) <= 15 then
			local extraDamage = math.random(8, 18)
			stats.Health = math.clamp((tonumber(stats.Health) or 100) - extraDamage, 0, 100)
			stats.ChildhoodDangerEvents = math.max(0, tonumber(stats.ChildhoodDangerEvents) or 0) + 1
			if stats.Health <= 0 then
				stats.Alive = false
				stats.CauseOfDeath = "A childhood curse incident became fatal."
			end
		end
	end
	if effects.Happiness then stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) + effects.Happiness, 0, 100) end
	if effects.Smarts then stats.Smarts = math.clamp((tonumber(stats.Smarts) or 0) + effects.Smarts, 0, 100) end
	if effects.CursedEnergy then stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + effects.CursedEnergy) end
	if effects.Strength then stats.Strength = math.clamp((tonumber(stats.Strength) or 0) + effects.Strength, 0, 100) end
	if effects.Looks then stats.Looks = math.clamp((tonumber(stats.Looks) or 50) + effects.Looks, 0, 100) end
	if effects.CursedObjectAnchorProgress then stats.CursedObjectAnchorProgress = math.clamp((tonumber(stats.CursedObjectAnchorProgress) or 0) + effects.CursedObjectAnchorProgress, 0, 100) end
	if effects.CursedObjectAnchors then stats.CursedObjectAnchors = math.max(0, (tonumber(stats.CursedObjectAnchors) or 0) + effects.CursedObjectAnchors) end
	if effects.ReincarnationAnchor then stats.ReincarnationAnchor = tostring(effects.ReincarnationAnchor) end
	if effects.Money then stats.Money = math.max(0, (tonumber(stats.Money) or 0) + effects.Money) end
	if effects.Reputation then stats.Reputation = (tonumber(stats.Reputation) or 0) + effects.Reputation end
	if effects.TechniqueMastery and hasTechnique(stats) then stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + effects.TechniqueMastery, 0, 100) end
	if effects.ClanReputation then stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) + effects.ClanReputation) end
	if effects.DojoPrestige then stats.DojoPrestige = math.max(0, (tonumber(stats.DojoPrestige) or 0) + effects.DojoPrestige) end
	if effects.DojoCondition then stats.DojoCondition = math.clamp((tonumber(stats.DojoCondition) or 100) + effects.DojoCondition, 0, 100) end
	if effects.Morality then
		applyMorality(stats, effects.Morality)
	end

	if effects.Kill then
		stats.Alive = false
		stats.Health = 0
		stats.DeathReason = tostring(effects.DeathReason or "Killed during a life event")
		stats.DeathMessage = tostring(effects.DeathMessage or stats.DeathReason)
		stats.CauseOfDeath = stats.CauseOfDeath or stats.DeathReason
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

	local resultText = option.Description or "You made your choice."
	local _oLang = BitKaisenLocale.getScenarioLocale(BitKaisenLocale.getPlayerLocale(player.UserId), scenario.Id)
	if _oLang and _oLang.options and option.Index then
		local _otopt = _oLang.options[option.Index]
		if _otopt and _otopt.desc then resultText = _otopt.desc end
	end
	resultText = tostring(resultText)
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

	-- Swap the English text for a translation before ApplyEvent builds the log message
	local locale = BitKaisenLocale.getPlayerLocale(player.UserId)
	if locale ~= "en" and eventData.TextIndex then
		local translated = BitKaisenLocale.tEvent(locale, eventData.Id, eventData.TextIndex)
		if translated then
			eventData.Text = translated
		end
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
			tSys(player, "unreg_curse_user", nil, "Your unregistered power and public danger finally crossed the line. The jujutsu world stopped seeing you as a future student and branded you as a curse user.")
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
		tSys(player, "unreg_grade_up", { grade = cleanGrade }, "Your unregistered strength was recognized. You rose to <b>Unregistered " .. tostring(cleanGrade) .. "</b>. If you grade up again before registering, you may be branded a curse user.")
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
		tSys(player, "unreg_progress", { reason = reasonText, gain = gain, progress = stats.UnregisteredProgress, requirement = requirement },
			"<font color='#b27aff'><b>[ UNREGISTERED ]</b></font> " .. reasonText .. " +" .. tostring(gain) .. " progress (" .. tostring(stats.UnregisteredProgress) .. "/" .. tostring(requirement) .. ").")
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
	if typeof(stats) ~= "table" then
		return 2000
	end

	local birthYear = tonumber(stats.BirthYear)
	if birthYear == nil then
		local birthPath = typeof(stats.BirthPath) == "table" and stats.BirthPath or nil
		birthYear = getEraStartYearFromName(stats.BirthEra or (birthPath and birthPath.Era) or stats.Era or "Modern Era")
		stats.BirthYear = birthYear
	end

	local year = birthYear + (tonumber(stats.Age) or 0)
	stats.CurrentYear = year
	return year
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

	if stats.HasRCT == true and (tonumber(stats.Health) or 100) > 0 and (tonumber(stats.Health) or 100) < 100 then
		local rctRegen = 3 + math.floor((tonumber(stats.RCTMastery) or 0) / 20)
		stats.Health = math.clamp((tonumber(stats.Health) or 100) + rctRegen, 0, 100)
	end

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

	if effects.TechniqueMastery and hasTechnique(stats) then
		stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + effects.TechniqueMastery, 0, 100)
	end

	if effects.ClanReputation then
		stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + effects.ClanReputation)
	end
	if effects.Fame or effects.Fear or effects.PathReputation then
		adjustWorldReputation(stats, effects.Fame or 0, effects.Fear or 0, effects.PathReputation or 0)
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
		adjustKarma(stats, -2)

		resultText = opening .. "\n\nThe assassin broke through your guard. You survived, but the escort collapsed and the higher-ups lost confidence in you.\nPenalties: -8 Reputation, Health damage, +1 Mission Failed."

		if stats.Health <= 0 then
			stats.Alive = false
			stats.CauseOfDeath = stats.CauseOfDeath or "Killed during a mission"
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

	if choice == "fight" or choice == "ambush" then
		BK_CombatService.StartCombat(player, "Sorcerer Attack", {
			Name = hunterName,
			Kind = "Sorcerer Hunter",
			Grade = sorcererGrade,
			Power = sorcererPower,
			ComboMin = choice == "ambush" and 1 or 1,
			ComboMax = choice == "ambush" and 2 or 3,
		})
		return
	end

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



----------------------------------------------------------------
-- OUTSIDE DOJO APPLICATION RESOLUTION
----------------------------------------------------------------
function getOutsideDojoTotalMonths(stats)
	local age = tonumber(stats and stats.Age) or 0
	local month = math.clamp(tonumber(stats and stats.CurrentMonth) or 1, 1, 12)
	return (age * 12) + (month - 1)
end

function resolvePendingOutsideDojoApplication(player, stats)
	if not stats or stats.DojoApplicationPending ~= true then
		return ""
	end

	local decisionAt = tonumber(stats.DojoApplicationDecisionAtTotalMonths) or 0
	if decisionAt <= 0 then
		stats.DojoApplicationDecisionAtTotalMonths = getOutsideDojoTotalMonths(stats) + 6
		return ""
	end

	if getOutsideDojoTotalMonths(stats) < decisionAt then
		return ""
	end

	local application = stats.DojoApplication or {}
	local dojoName = tostring(application.Name or stats.DojoApplicationName or "Unnamed Dojo")
	local dojoFocus = tostring(application.Focus or stats.DojoApplicationFocus or "Balanced")
	local dojoRank = tostring(application.Rank or stats.DojoApplicationRank or "Local Dojo")
	local senseiName = tostring(application.SenseiName or stats.DojoApplicationSenseiName or "A senior sorcerer")
	local senseiGrade = tostring(application.SenseiGrade or stats.DojoApplicationSenseiGrade or "Grade 1")
	local senseiAge = tonumber(application.SenseiAge or stats.DojoApplicationSenseiAge) or math.random(26, 54)
	local senseiRelation = tostring(application.SenseiRelation or stats.DojoApplicationSenseiRelation or "Sensei")
	local chance = math.clamp(tonumber(stats.DojoApplicationChance) or tonumber(application.Chance) or 55, 5, 95)

	local accepted = math.random(1, 100) <= chance

	stats.DojoApplicationPending = false
	stats.DojoApplicationDecisionAtTotalMonths = nil
	stats.DojoApplicationSubmittedAtTotalMonths = nil
	stats.DojoApplicationChance = nil
	stats.DojoApplicationName = nil
	stats.DojoApplicationFocus = nil
	stats.DojoApplicationRank = nil
	stats.DojoApplicationSenseiName = nil
	stats.DojoApplicationSenseiGrade = nil
	stats.DojoApplicationSenseiAge = nil
	stats.DojoApplicationSenseiRelation = nil
	stats.DojoApplication = nil

	if accepted then
		stats.JoinedDojoName = dojoName
		stats.JoinedDojoFocus = dojoFocus
		stats.JoinedDojoRank = dojoRank
		stats.JoinedDojoTrust = math.max(5, tonumber(stats.JoinedDojoTrust) or math.random(8, 18))
		stats.JoinedDojoProgress = math.max(0, tonumber(stats.JoinedDojoProgress) or 0)
		stats.JoinedDojoAssignments = tonumber(stats.JoinedDojoAssignments) or 0
		stats.JoinedDojoJoinedAtAge = tonumber(stats.Age) or 0
		stats.JoinedDojoJoinedAtMonth = tonumber(stats.CurrentMonth) or 1
		stats.JoinedDojoSenseiName = senseiName
		stats.JoinedDojoSenseiGrade = senseiGrade
		stats.JoinedDojoSenseiAge = senseiAge
		stats.JoinedDojoSenseiRelation = senseiRelation
		stats.JoinedDojoSenseiTrainingWindow = nil
		stats.JoinedDojoSenseiTrainingUsed = 0
		stats.JoinedDojoAssignmentWindow = nil
		stats.JoinedDojoAssignmentUsed = 0
		stats.JoinedDojoSenseiAdviceWindow = nil
		stats.JoinedDojoSenseiAdviceUsed = 0

		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) + 5, 0, 100)
		stats.Smarts = math.clamp((tonumber(stats.Smarts) or 0) + 1, 0, 100)

		fireMajorPopup(
			player,
			"DOJO ACCEPTED",
			"Six months after applying, your letter finally came back. You were accepted into " .. dojoName .. ".",
			dojoName,
			"Sensei: " .. senseiName .. " • " .. senseiGrade
		)

		return "<font color='#7ee787'><b>[ DOJO ACCEPTED ]</b></font> You were accepted into <b>" .. dojoName .. "</b>. Your sensei is <b>" .. senseiName .. "</b> (" .. senseiGrade .. ", age " .. tostring(senseiAge) .. "). Open the Grand Dojo menu to train with your new dojo."
	end

	stats.LastDojoRejectionAge = tonumber(stats.Age) or 0
	stats.LastDojoRejectionMonth = tonumber(stats.CurrentMonth) or 1
	stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - 4, 0, 100)

	fireMajorPopup(
		player,
		"DOJO REJECTED",
		"Six months after applying, " .. dojoName .. " sent a rejection notice. Your current profile was not enough for their standards.",
		dojoName,
		"Train more, build reputation, then apply again."
	)

	return "<font color='#e53935'><b>[ DOJO REJECTED ]</b></font> <b>" .. dojoName .. "</b> rejected your application. Improve your grade, cursed energy, reputation, or technique mastery before trying again."
end

local function advanceOutsideDojoSenseiAges(stats, years)
	if typeof(stats) ~= "table" then
		return
	end

	years = tonumber(years) or 0
	if years <= 0 then
		return
	end

	if tostring(stats.JoinedDojoName or "") ~= "" and tonumber(stats.JoinedDojoSenseiAge) then
		stats.JoinedDojoSenseiAge = math.max(18, (tonumber(stats.JoinedDojoSenseiAge) or 18) + years)
	end

	if stats.DojoApplicationPending == true and tonumber(stats.DojoApplicationSenseiAge) then
		stats.DojoApplicationSenseiAge = math.max(18, (tonumber(stats.DojoApplicationSenseiAge) or 18) + years)
	end
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

	-- CE Addiction: heavy reliance on CE Boosts builds dependency. High dependency
	-- causes withdrawal symptoms (Health/Happiness loss) if it isn't fed regularly,
	-- and decays slowly on its own otherwise.
	do
		local addiction = tonumber(stats.CEAddiction) or 0
		if addiction >= 60 and math.random(1, 100) <= 35 then
			local healthLoss = math.random(2, 6)
			local happinessLoss = math.random(4, 10)
			stats.Health = math.clamp((tonumber(stats.Health) or 100) - healthLoss, 0, 100)
			stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - happinessLoss, 0, 100)
			fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ WITHDRAWAL ]</b></font> Your body craves cursed energy. Without a fix, your hands shake and your focus slips. <b>Health -" .. tostring(healthLoss) .. "</b>, <b>Happiness -" .. tostring(happinessLoss) .. "</b>.")
			addCEAddiction(stats, -3)
		else
			addCEAddiction(stats, -2)
		end
	end

	-- Hidden karma drift each age tick
	do
		local rep = tonumber(stats.Reputation) or 0
		local happiness = tonumber(stats.Happiness) or 100
		if isCurseUser(stats) then
			adjustKarma(stats, -1)
		elseif isCurseLife(stats) then
			adjustKarma(stats, -1)
		elseif rep >= 50 then
			adjustKarma(stats, 1)
		elseif rep < -20 then
			adjustKarma(stats, -1)
		end
		if happiness >= 80 then
			adjustKarma(stats, 1)
		elseif happiness <= 20 then
			adjustKarma(stats, -1)
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
		stats.DomainTrainingThisAge = 0
		stats.MissionAttemptsThisAge = 0
		stats.PhysicalConditioningThisAge = 0
		stats.CursedFingerHuntBlockedThisAge = false
		stats.MissionAttemptsWindowAge = math.max(0, tonumber(stats.Age) or 0)

		advanceOutsideDojoSenseiAges(stats, 0.5)
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

		local dojoApplicationText = resolvePendingOutsideDojoApplication(player, stats)
		if dojoApplicationText ~= "" then
			logMessage = logMessage .. "\n" .. dojoApplicationText
		end

		if completedFullYear then
			BitKaisenRelationships.AdvanceRelationshipYears(stats)

			stats.Age += 1
			stats.CurrentMonth = 1
			stats.MonthsIntoAge = 0
			stats.ActivitiesDoneThisAge = 0
			stats.RelationshipActionsThisAge = 0
			stats.DomainTrainingThisAge = 0
			stats.MissionAttemptsThisAge = 0
			stats.PhysicalConditioningThisAge = 0
			stats.CursedFingerHuntBlockedThisAge = false
			stats.MissionAttemptsWindowAge = math.max(0, tonumber(stats.Age) or 0)

			stats.Health = math.clamp((stats.Health or 100) + math.random(-5, 4), 0, 100)
			stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(-4, 4), 0, 100)

			logMessage = logMessage .. "\nThe calendar turned to <b>" .. getTimeStampText(stats) .. "</b>. You are now <b>" .. tostring(stats.Age) .. "</b>."

			local rivalYearText = BK_RivalService.OnAgeUp(player, stats)
		if rivalYearText ~= "" then
			logMessage = logMessage .. "\n" .. rivalYearText
		end

		local eraTransitionText = registerEraTransition(stats)
			if eraTransitionText ~= "" then
				logMessage = logMessage .. "\n" .. eraTransitionText
				fireMajorPopup(
					player,
					"ERA SHIFT",
					"Your life has lasted long enough for history itself to change around you.",
					tostring(stats.PreviousEra or "Unknown Era") .. " â†’ " .. tostring(stats.CurrentEra or stats.Era or "Modern Era"),
					"Era shifts can change future event flavor, society pressure, and long-term cursed history."
				)
			end

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
				if technique == "Miracle" then
					local tool, added = BitKaisenCursedTools.AddTool(stats, "hand_sword", "Miracle Technique", getCurrentYear(stats))
					if added and tool then
						logMessage = logMessage .. "\n<font color='#f0b955'><b>[ CURSED TOOL ]</b></font> The technique manifested a weapon: <b>Hand Sword</b>."
					end
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

			logMessage = logMessage .. BK_WorldHistoryService.AdvanceYear(player, stats)
			logMessage = logMessage .. BK_ClanWarService.AdvanceYear(player, stats)
			logMessage = logMessage .. BK_CultService.AdvanceYear(player, stats)
			logMessage = logMessage .. BK_CultWarService.AdvanceYear(player, stats)
			logMessage = addRandomLifeEvent(player, stats, logMessage)
			logMessage = addRelationshipAgeEvent(player, stats, logMessage)
			logMessage = maybeTeacherRecommendation(player, stats, logMessage)
			logMessage = checkPromotionAndPopup(player, stats, logMessage)

			if stats.InJujutsuHigh == true and (tonumber(stats.Age) or 0) >= 20 then
				stats.InJujutsuHigh = false
				stats.GraduatedJujutsuHigh = true
				stats.RegisteredSorcerer = true
				stats.SocietyStatus = "Registered Sorcerer"
				if tostring(stats.Affiliation or "") == "Jujutsu High" then
					stats.AffiliationRank = "Graduate"
				end
				logMessage = logMessage .. tSys(player, "jh_graduation", { grade = stats.Grade or "Sorcerer" }, "\nYou graduated from Jujutsu High as an official <b>" .. tostring(stats.Grade or "Sorcerer") .. "</b>.")
				fireMajorPopup(
					player,
					"JUJUTSU HIGH GRADUATION",
					"After years of study and missions, you have graduated.",
					tostring(stats.Grade or "Sorcerer") .. " | Recommendations: " .. tostring(stats.TeacherRecommendations or 0),
					"You are now a fully registered adult sorcerer."
				)
			end

			if stats.IsJujutsuMentor == true then
				local mentorLog = BK_MentorService.AdvanceYear(player, stats)
				if mentorLog ~= "" then
					logMessage = logMessage .. "\n" .. mentorLog
				end
			end

			if isCurseLife(stats) then
				ensureCursedSpiritFlavor(stats)
				stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + math.random(0, 3))
				stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) + math.random(0, 2), 0, 100)
				logMessage = logMessage .. tSys(player, "curse_year_linger", { threat = stats.CurseThreat or 0, hunger = stats.CurseHunger or 0, hunger_text = getCurseHungerText(stats) }, "\nYour cursed presence lingered through another year. Threat: <b>" .. tostring(stats.CurseThreat or 0) .. "</b> | Hunger: <b>" .. tostring(stats.CurseHunger or 0) .. "% (" .. getCurseHungerText(stats) .. ")</b>.")
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

			logMessage = logMessage .. applyOldAgeMortality(stats)
		end

		if stats.Health <= 0 then
			stats.Alive = false
			stats.CauseOfDeath = stats.CauseOfDeath or "Body gave out"
			if not isCurseLife(stats) then
				addCursedResentment(stats, 20)
				refreshCurseRebirthEligibility(stats)
			end
			logMessage = logMessage .. tSys(player, "body_gave_out", nil, "\nYour body gave out.")
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
	advanceOutsideDojoSenseiAges(stats, 1)
	BitKaisenRelationships.AdvanceRelationshipYears(stats)

	stats.Age += 1
	stats.CurrentMonth = 1
	stats.MonthsIntoAge = 0
	stats.ActivitiesDoneThisAge = 0
	stats.RelationshipActionsThisAge = 0
	stats.DomainTrainingThisAge = 0
	stats.MissionAttemptsThisAge = 0
	stats.PhysicalConditioningThisAge = 0
	stats.CursedFingerHuntBlockedThisAge = false
	stats.MissionAttemptsWindowAge = math.max(0, tonumber(stats.Age) or 0)

	stats.Health = math.clamp((stats.Health or 100) + math.random(-5, 4), 0, 100)
	stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(-4, 4), 0, 100)

	local logMessage = BitKaisenLifeEvents.GetQuietYearText(stats)
	-- Swap for translated quiet text if the player's locale has one
	do
		local locale = BitKaisenLocale.getPlayerLocale(player.UserId)
		if locale ~= "en" then
			local pool = BitKaisenLocale.getQuietYearTexts(locale)
			if pool and #pool > 0 then
				stats.RecentQuietTextsLocale = stats.RecentQuietTextsLocale or {}
				local recent = stats.RecentQuietTextsLocale
				local available = {}
				for i, text in ipairs(pool) do
					local used = false
					for _, r in ipairs(recent) do if r == i then used = true; break end end
					if not used then table.insert(available, { idx = i, text = text }) end
				end
				if #available == 0 then
					available = {}
					for i, text in ipairs(pool) do table.insert(available, { idx = i, text = text }) end
					stats.RecentQuietTextsLocale = {}
				end
				local pick = available[math.random(1, #available)]
				logMessage = pick.text
				table.insert(stats.RecentQuietTextsLocale, 1, pick.idx)
				while #stats.RecentQuietTextsLocale > 5 do table.remove(stats.RecentQuietTextsLocale) end
			end
		end
	end
	logMessage = logMessage .. BK_JobService.AdvanceYear(player, stats)
	logMessage = logMessage .. BK_WorldHistoryService.AdvanceYear(player, stats)
	logMessage = logMessage .. BK_ClanWarService.AdvanceYear(player, stats)
	logMessage = logMessage .. BK_CultService.AdvanceYear(player, stats)
	logMessage = logMessage .. BK_CultWarService.AdvanceYear(player, stats)
	logMessage = logMessage .. applyYearlyWorldReputation(stats)

	local schoolText = BK_SchoolService.AdvanceSchoolYear(stats)
	if schoolText ~= "" then
		logMessage = logMessage .. "\n" .. schoolText
	end

	if stats.Age == 16 and stats.GraduatedSchool ~= true then
		local gradLog, reportCard = BK_SchoolService.Graduate(stats)
		if gradLog ~= "" then
			logMessage = logMessage .. "\n" .. gradLog
		end
		if reportCard then
			fireMajorPopup(
				player,
				"SCHOOL GRADUATION",
				"You graduated from high school at age 16.",
				"Final Grade: " .. tostring(reportCard.Grade) .. " | Performance: " .. tostring(reportCard.Performance) .. "% | Attendance: " .. tostring(reportCard.Attendance) .. "%",
				reportCard.Club ~= "None" and ("Club: " .. tostring(reportCard.Club)) or "You didn't join any clubs."
			)
		end

		local hasAwakened = (stats.CursedTechnique and stats.CursedTechnique ~= "None") or (stats.TechniqueAwakened == true)
		local isUnreg = isUnregisteredSorcerer(stats)
		local hasGoRogue = ownsGoRoguePass(player) or stats.HasGoRoguePass == true
		local era = tostring(stats.Era or "Modern Era")
		local jjhEraAllowed = era == "Modern Era" or era == "Collapse Era"
		if (hasAwakened or isUnreg) and not isCurseLife(stats) and not isCurseUser(stats) and not stats.InJujutsuHigh and not hasGoRogue and jjhEraAllowed then
			local enrollMsg, enrolled = BK_ActivityService.EnrollInJujutsuHigh(player, stats)
			if enrolled then
				logMessage = logMessage .. "\n" .. "Your cursed energy caught the attention of recruiters at graduation. " .. enrollMsg
			end
		end
	end

	local rivalYearText = BK_RivalService.OnAgeUp(player, stats)
	if rivalYearText ~= "" then
		logMessage = logMessage .. "\n" .. rivalYearText
	end

	local eraTransitionText = registerEraTransition(stats)
	if eraTransitionText ~= "" then
		logMessage = logMessage .. "\n" .. eraTransitionText
		fireMajorPopup(
			player,
			"ERA SHIFT",
			"Your life has lasted long enough for history itself to change around you.",
			tostring(stats.PreviousEra or "Unknown Era") .. " â†’ " .. tostring(stats.CurrentEra or stats.Era or "Modern Era"),
			"Era shifts can change future event flavor, society pressure, and long-term cursed history."
		)
	end

	local awakened, technique, awakenType = BitKaisenStats.TryAwaken(stats)

	if awakened and technique then
		if awakenType == "Innate" then
			logMessage = tSys(player, "awaken_innate", { technique = technique }, "Your inherited technique finally stopped sleeping. <b>" .. technique .. "</b> became usable.")
			fireMajorPopup(
				player,
				"INNATE TECHNIQUE AWAKENED",
				"At age " .. tostring(stats.Age) .. ", the technique you were born with finally answered you.",
				technique,
				"Innate techniques are inherited at birth, but usually become usable around age 10-11."
			)
		else
			logMessage = tSys(player, "awaken_cursed", { technique = technique }, "Your cursed energy finally took shape. You awakened <b>" .. technique .. "</b>.")
			fireMajorPopup(
				player,
				"CURSED TECHNIQUE AWAKENED",
				"At age " .. tostring(stats.Age) .. ", your cursed energy sparked into a technique.",
				technique,
				"Normal techniques can awaken around ages 8, 10, or 13."
			)
		end
		if technique == "Miracle" then
			local tool, added = BitKaisenCursedTools.AddTool(stats, "hand_sword", "Miracle Technique", getCurrentYear(stats))
			if added and tool then
				logMessage = logMessage .. "\n<font color='#f0b955'><b>[ CURSED TOOL ]</b></font> The technique manifested a weapon: <b>Hand Sword</b>."
			end
		end
	elseif stats.Age == 8 and tostring(stats.InnateTechnique or "None") == "None" and tostring(stats.CursedTechnique or "None") == "None" then
		logMessage = tSys(player, "awaken_stir", nil, "Your cursed energy stirred for the first time, but no technique fully manifested.")
	elseif stats.Age == 10 and tostring(stats.CursedTechnique or "None") == "None" then
		if tostring(stats.InnateTechnique or "None") ~= "None" then
			logMessage = tSys(player, "awaken_surface", nil, "Your innate technique pressed against the surface, but it did not fully answer yet.")
		else
			logMessage = tSys(player, "awaken_unstable", nil, "Your cursed energy grew unstable for a moment, but no technique manifested.")
		end
	end

	if stats.Age >= 13 and stats.CursedTechnique ~= "None" and not isOfficialJujutsuSorcerer(stats) and not isCurseLife(stats) and not isCurseUser(stats) then
		if math.random(1, 100) <= 15 then
			logMessage = tSys(player, "recruiter_notice", nil, "A jujutsu recruiter noticed your cursed energy. You can apply to Jujutsu High when you are old enough.")
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
	local unregisteredActivityProgress, unregisteredActivityReason = getUnregisteredActivityProgress(nil, stats)
	logMessage = awardUnregisteredProgress(player, stats, unregisteredActivityProgress, unregisteredActivityReason, logMessage)

	logMessage = maybeTeacherRecommendation(player, stats, logMessage)
	logMessage = checkPromotionAndPopup(player, stats, logMessage)

	if isCurseLife(stats) then
		ensureCursedSpiritFlavor(stats)
		stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + math.random(0, 3))
		stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) + math.random(0, 2), 0, 100)
		addCurseHunger(stats, math.random(6, 12))
		logMessage = logMessage .. tSys(player, "curse_year", { threat = stats.CurseThreat or 0, hunger = stats.CurseHunger or 0 }, "\nYour cursed presence grew quietly. Threat: <b>" .. tostring(stats.CurseThreat or 0) .. "</b> | Hunger: <b>" .. tostring(stats.CurseHunger or 0) .. "%</b>.")
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

	logMessage = logMessage .. applyOldAgeMortality(stats)

	if stats.Health <= 0 then
		stats.Alive = false
		stats.CauseOfDeath = stats.CauseOfDeath or "Body gave out"
		if not isCurseLife(stats) then
			addCursedResentment(stats, 20)
			refreshCurseRebirthEligibility(stats)
		end
		logMessage = logMessage .. tSys(player, "body_gave_out", nil, "\nYour body gave out.")
	end

	local dojoApplicationText = resolvePendingOutsideDojoApplication(player, stats)
	if dojoApplicationText ~= "" then
		logMessage = logMessage .. "\n" .. dojoApplicationText
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

	if effects.TechniqueMastery and hasTechnique(stats) then
		stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + effects.TechniqueMastery, 0, 100)
	end
	if effects.Fame or effects.Fear or effects.PathReputation then
		adjustWorldReputation(stats, effects.Fame or 0, effects.Fear or 0, effects.PathReputation or 0)
	end
	if effects.Morality then
		applyMorality(stats, effects.Morality)
	end

	stats.Alignment = getMoralAlignment(stats)

end

function getMissionCursedToolDropConfig(missionData, combatResult)
	return BitKaisenCursedTools.GetMissionDropConfig(missionData and missionData.Grade, combatResult)
end

function startInteractiveMissionCombat(player, stats, missionData, choiceOption)
	if not player or not stats or stats.Alive == false or typeof(missionData) ~= "table" then
		return false
	end
	choiceOption = choiceOption or {}
	if choiceOption.SkipInteractiveCombat == true or choiceOption.ForceSuccess == true or choiceOption.ForceFail == true then
		return false
	end

	local missionTitle = tostring(missionData.Title or "Mission Encounter")
	local missionGrade = tostring(missionData.Grade or getOfficialGradeName(stats.Grade))
	local enemyPower = math.max(24, tonumber(missionData.Difficulty) or BitKaisenCombat.GetEnemyPower(missionData, { Volatility = 8 }))
	local enemyName = tostring(missionData.EnemyName or missionData.TargetName or missionData.CurseName or (missionTitle .. " Curse"))
	local enemyKind = string.find(string.lower(enemyName), "user", 1, true) and "Curse User" or "Cursed Spirit"
	local optionDescription = tostring(choiceOption.Description or "")

	local started = BK_CombatService.StartCombat(player, "Mission: " .. missionTitle, {
		Name = enemyName,
		Grade = missionGrade,
		Kind = enemyKind,
		Power = enemyPower,
		PowerScale = 0.9,
		ComboMin = 1,
		ComboMax = math.clamp(math.floor(enemyPower / 75) + 1, 1, 3),
		Metadata = {
			MissionId = missionData.Id,
			MissionTitle = missionTitle,
		},
		OnFinish = function(finishedPlayer, session, winner, reason, finishedStats)
			local callbackStats = finishedStats or stats
			if not finishedPlayer or not callbackStats or playerLives[finishedPlayer.UserId] ~= callbackStats then
				return
			end
			local callbackOption = {}
			for key, value in pairs(choiceOption) do
				callbackOption[key] = value
			end
			callbackOption.SkipInteractiveCombat = true
			callbackOption.Description = optionDescription ~= "" and optionDescription or ("The fight decided <b>" .. missionTitle .. "</b>.")
			if winner == "player" then
				callbackOption.ForceSuccess = true
			else
				callbackOption.ForceFail = true
				callbackOption.CombatResolved = true
				if winner == "fled" then
					callbackOption.Description = "You escaped the fight, but the mission target got away."
				elseif reason and tostring(reason) ~= "" then
					callbackOption.Description = "The combat ended badly: " .. tostring(reason)
				end
			end
			resolveMission(finishedPlayer, callbackStats, missionData, callbackOption)
		end,
	})

	if started then
		fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ COMBAT ]</b></font> " .. enemyName .. " blocks <b>" .. missionTitle .. "</b>. Win the fight to complete the mission.")
		return true
	end
	return false
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
			stats.CauseOfDeath = stats.CauseOfDeath or "Died on a mission"
			stats.MissionsFailed += 1
			adjustKarma(stats, -3)
			logMessage = logMessage .. "\nYou died on the mission."
			fireLifeUpdate(player, stats, logMessage)
			saveStats(player)
			return
		end
	end

	if startInteractiveMissionCombat(player, stats, missionData, choiceOption) then
		saveStats(player, "mission_combat_started")
		return
	end

	local combatResult = nil
	local success

	if forceSuccess then
		success = true
		combatResult = BitKaisenCombat.ResolveMissionCombat(stats, missionData, { PowerBonus = powerBonus + 999 })
		combatResult.Success = true
		combatResult.Outcome = "Forced Success"
		combatResult.HealthDamage = 0
		combatResult.Summary = "Combat: <b>Forced Success</b>. Your choice controlled the fight before it could turn."
	elseif forceFail then
		success = false
		combatResult = BitKaisenCombat.ResolveMissionCombat(stats, missionData, { PowerBonus = powerBonus - 999 })
		combatResult.Success = false
		combatResult.Outcome = "Forced Failure"
		combatResult.Summary = "Combat: <b>Forced Failure</b>. Your choice put the mission beyond recovery."
	else
		combatResult = BitKaisenCombat.ResolveMissionCombat(stats, missionData, { PowerBonus = powerBonus })
		success = combatResult.Success == true
	end

	if success then
		local smartBonus = 1 + ((stats.Smarts or 0) / 300)
		local missionInvestorMult = ownsMissionInvestorPass(player) and 1.5 or 1
		local doubleMoneyMult = ownsDoubleMoneyPass(player) and 2 or 1
		local vipMoneyMult = ownsVIPSorcererPass(player) and 1.5 or 1

		local baseMissionCE = (missionData.RewardCE or 0) + (combatResult.CursedEnergyBonus or 0)
		local missionCEGain, missionCEBonus, missionCETool = BitKaisenCursedTools.ApplyCEGain(stats, baseMissionCE * missionInvestorMult)
		stats.CursedEnergy += missionCEGain
		stats.Money += math.floor((missionData.RewardMoney or 0) * smartBonus * ((combatResult and combatResult.RewardMoneyMult) or 1) * missionInvestorMult * doubleMoneyMult * vipMoneyMult)
		stats.Reputation += math.floor((missionData.RewardRep or 0) * smartBonus * ((combatResult and combatResult.RewardRepMult) or 1) * missionInvestorMult)
		stats.MissionsCompleted += 1
		if BK_ChallengeService then
			local function fireChallengeEvent(evType, evData)
				local ok, newly = pcall(BK_ChallengeService.OnEvent, player, evType, evData or {})
				if ok and newly then
					for _, ch in ipairs(newly) do
						fireMajorPopup(player, "CHALLENGE COMPLETE!", ch.Desc, ch.Title, "+" .. ch.Reward, "success")
						challengeCompleted:FireClient(player, ch.Id)
					end
				end
			end
			fireChallengeEvent("combat_win", {})
			local healthAfter = tonumber(stats.Health) or 100
			if healthAfter < 20 then
				fireChallengeEvent("combat_survive_low_hp", {})
			end
			local mGrade = tostring(missionData and missionData.Grade or "")
			if mGrade:find("Special") then
				fireChallengeEvent("mission_complete", { rank = "Special" })
			elseif mGrade == "Grade 1" or mGrade:find("Grade 1") then
				fireChallengeEvent("mission_complete", { rank = "A" })
			end
		end
		stats.Happiness = math.clamp((stats.Happiness or 100) + 8, 0, 100)
		stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + (combatResult.MasteryGain or 0), 0, 100)
		if (combatResult.HealthDamage or 0) > 0 then
			stats.Health = math.clamp((stats.Health or 100) - combatResult.HealthDamage, 0, 100)
		end

		if stats.ClanFounded then
			stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + math.random(1, 3))
		end
		local missionRepNote = adjustWorldReputation(stats, math.random(1, 3), math.random(0, 1), 1)

		if logMessage ~= "" then
			logMessage = logMessage .. "\n"
		end

		logMessage = logMessage .. "You completed <b>" .. missionData.Title .. "</b> and exorcised the curse."
		if combatResult and combatResult.Summary then
			logMessage = logMessage .. "\n" .. combatResult.Summary
		end
		if combatResult then
			local pressureGain = math.clamp(math.floor(math.abs(tonumber(combatResult.Margin) or 0) / 18) + 2, 2, 10)
			logMessage = logMessage .. BitKaisenTechniqueEvolution.AddPressure(stats, pressureGain, "mission failure pressure")
		end
		if combatResult then
			local pressureGain = math.clamp(math.floor(math.abs(tonumber(combatResult.Margin) or 0) / 20) + ((combatResult.MasteryGain or 0) > 0 and 2 or 0), 1, 8)
			logMessage = logMessage .. BitKaisenTechniqueEvolution.AddPressure(stats, pressureGain, "mission combat")
		end
		if missionCEBonus and missionCEBonus > 0 then
			logMessage ..= "\n<font color='#f0b955'><b>[ CURSED TOOL ]</b></font> " .. tostring(missionCETool and missionCETool.Name or "Your equipped cursed tool") .. " stabilized the mission reward: <b>+" .. tostring(missionCEBonus) .. " bonus CE</b>."
		end
		local toolDropChance, maxToolRarity = getMissionCursedToolDropConfig(missionData, combatResult)
		if math.random(1, 100) <= toolDropChance then
			local droppedTool = BitKaisenCursedTools.RollDrop(maxToolRarity)
			if droppedTool then
				local _, added = BitKaisenCursedTools.AddTool(stats, droppedTool.Id, tostring(missionData.Title or "Mission"), getCurrentYear(stats))
				if added then
					logMessage ..= "\n<font color='#f0b955'><b>[ CURSED TOOL FOUND ]</b></font> You recovered <b>" .. tostring(droppedTool.Name) .. "</b> after the mission."
				else
					local duplicateReward = BitKaisenCursedTools.GetDuplicateReward(droppedTool)
					stats.Money = (tonumber(stats.Money) or 0) + duplicateReward.Money
					stats.CursedEnergy = (tonumber(stats.CursedEnergy) or 0) + duplicateReward.CursedEnergy
					logMessage ..= "\n<font color='#f0b955'><b>[ CURSED TOOL DUPLICATE ]</b></font> You already owned <b>" .. tostring(droppedTool.Name) .. "</b>, so it converted into <b>+$" .. tostring(duplicateReward.Money) .. "</b> and <b>+" .. tostring(duplicateReward.CursedEnergy) .. " CE</b>."
				end
			end
		end

		local techniqueText = string.lower(tostring(stats.CursedTechnique or stats.InnateTechnique or ""))
		if string.find(techniqueText, "cursed spirit manipulation", 1, true) then
			local captureGain = missionData.Grade == "Special Grade" and 3 or (missionData.Grade == "Grade 1" and 2 or 1)
			stats.StoredCurses = math.clamp((tonumber(stats.StoredCurses) or 0) + captureGain, 0, 25)
			stats.StoredCursePower = math.clamp((tonumber(stats.StoredCursePower) or 0) + math.random(18, 40) * captureGain, 0, 500)
			logMessage ..= "\n<font color='#9b6dff'><b>[ CSM ]</b></font> You absorbed the defeated curse into your arsenal. Stored curses: <b>" .. tostring(stats.StoredCurses) .. "</b>."
		end

		if missionData.RewardMoney and missionData.RewardMoney > 0 then
			logMessage = logMessage .. "\nYou were paid for the assignment."
		end

		if (stats.Smarts or 0) >= 70 then
			logMessage = logMessage .. "\nYour detailed mission report impressed the higher-ups."
		end
		if missionRepNote ~= "" then
			logMessage = logMessage .. missionRepNote
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
		local actualDamage = combatResult and combatResult.HealthDamage or math.max(2, (missionData.DmgPenalty or 0) - math.floor((stats.Smarts or 0) / 5))
		if choiceOption and choiceOption.CombatResolved == true then
			actualDamage = 0
		end
		local equippedEffects, equippedTool = BitKaisenCursedTools.GetEquippedEffects(stats)
		local damageReduction = math.clamp(tonumber(equippedEffects.MissionRiskReduction) or 0, 0, math.max(0, actualDamage - 1))
		if damageReduction > 0 then
			actualDamage = math.max(1, actualDamage - damageReduction)
		end

		stats.Health = math.clamp((stats.Health or 100) - actualDamage, 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) - 15, 0, 100)
		stats.MissionsFailed += 1
		adjustKarma(stats, -2)
		stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + ((combatResult and combatResult.MasteryGain) or 0), 0, 100)
		local missionFailRepNote = adjustWorldReputation(stats, 0, math.random(0, 2), 0)

		if logMessage ~= "" then
			logMessage = logMessage .. "\n"
		end

		logMessage = logMessage .. "You failed <b>" .. missionData.Title .. "</b>."
		if combatResult and combatResult.Summary then
			logMessage = logMessage .. "\n" .. combatResult.Summary
		end
		if damageReduction > 0 then
			logMessage ..= "\n<font color='#f0b955'><b>[ CURSED TOOL ]</b></font> " .. tostring(equippedTool and equippedTool.Name or "Your equipped cursed tool") .. " reduced mission damage by <b>" .. tostring(damageReduction) .. "</b>."
		end

		if (stats.Smarts or 0) >= 70 then
			logMessage = logMessage .. "\nYour sharp thinking kept you from taking the full hit."
		end
		if missionFailRepNote ~= "" then
			logMessage = logMessage .. missionFailRepNote
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
			stats.CauseOfDeath = stats.CauseOfDeath or "Killed in action"
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
	return BK_MissionService.ProcessMission(player, missionId)
end

----------------------------------------------------------------
-- ACTIVITY HELPERS / ACTIONS
-- Heavy activity action handling moved to BK_ActivityService in Phase 6 split.
----------------------------------------------------------------

function processActivity(player, activityId)
	return BK_ActivityService.ProcessActivity(player, activityId)
end

----------------------------------------------------------------
-- RELATIONSHIP HELPERS / ACTIONS
-- Heavy relationship action handling moved to BK_RelationshipService in Phase 5 split.
----------------------------------------------------------------

function appendLine(baseText, extraText)
	if not extraText or extraText == "" then
		return baseText or ""
	end

	if baseText and baseText ~= "" then
		return baseText .. "\n" .. extraText
	end

	return extraText
end

function processRelationshipAction(player, relationshipId, actionId, data)
	return BK_RelationshipService.ProcessRelationshipAction(player, relationshipId, actionId, data)
end

----------------------------------------------------------------
-- ASSET / DOJO ACTIONS
-- Heavy asset + dojo action handling moved to BK_AssetService in Phase 4 split.
----------------------------------------------------------------

function processAssetAction(player, actionId, assetId)
	return BK_AssetService.ProcessAssetAction(player, actionId, assetId)
end

getMissionBoard.OnServerInvoke = function(player)
	return BK_MissionService.GetMissionBoardPayload(player)
end

getActivityList.OnServerInvoke = function(player)
	return BK_ActivityService.GetActivityListPayload(player)
end

getDomain.OnServerInvoke = function(player)
	return BK_DomainService.GetPayload(player)
end

domainAction.OnServerEvent:Connect(function(player, actionId)
	if not checkRateLimit(player, "DomainAction") then
		return
	end
	BK_DomainService.ProcessAction(player, actionId)
end)

getGodMode.OnServerInvoke = function(player)
	ownershipCaches.godMode[player.UserId] = nil
	return BK_GodModeService.GetPayload(player)
end

godModeAction.OnServerEvent:Connect(function(player, actionId, data)
	if not checkRateLimit(player, "GodModeAction") then
		return
	end
	local stats = playerLives[player.UserId]
	if not stats then
		return
	end
	ensureExtraStats(stats)
	if ownsGodModePass(player) ~= true then
		fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ GOD MODE ]</b></font> Unlock God Mode to use these controls.")
		return
	end
	if tostring(actionId or "") == "reset_life" then
		startNewLife(player)
		return
	end
	BK_GodModeService.ProcessAction(player, actionId, data)
end)

getRivals.OnServerInvoke = function(player)
	return BK_RivalService.GetPayload(player)
end

rivalAction.OnServerEvent:Connect(function(player, actionId, data)
	if not checkRateLimit(player, "RivalAction") then
		return
	end
	BK_RivalService.ProcessAction(player, actionId, data)
end)

getJobs.OnServerInvoke = function(player)
	local payload = BK_JobService.GetJobsPayload(player)
	payload.GoRogueProductId = BK_CommerceService.GetGoRogueProductId()
	payload.GoRoguePassId = GO_ROGUE_PASS_ID
	payload.HasGoRoguePass = ownsGoRoguePass(player)
	return payload
end

getRelationships.OnServerInvoke = function(player)
	return BK_RelationshipService.GetRelationshipsPayload(player)
end

getWorldHistory.OnServerInvoke = function(player)
	local stats = playerLives[player.UserId]
	if not stats then return { History = {}, NotableSorcerers = {}, Summary = {} } end
	return BK_WorldHistoryService.GetWorldHistoryPayload(stats)
end

getTitles.OnServerInvoke = function(player)
	local stats = playerLives[player.UserId]
	if not stats then return { Titles = {} } end
	return BK_WorldHistoryService.GetTitlesPayload(stats)
end

local getPastLives = BK_Remotes.Get("GetPastLives")
getPastLives.OnServerInvoke = function(player)
	local stats = playerLives[player.UserId]
	if not stats or not stats.MetaProgress then return { PastLives = {} } end
	return { PastLives = stats.MetaProgress.PastLives or {} }
end

local getChallenges = BK_Remotes.Get("GetChallenges")
getChallenges.OnServerInvoke = function(player)
	if not BK_ChallengeService then return { Challenges = {}, ResetsIn = 0 } end
	return BK_ChallengeService.GetChallengesPayload(player)
end

local function canUseDevTools(player)
	return TEST_PURCHASE_PLACE_IDS[game.PlaceId] == true or isDev(player)
end

getDevTools.OnServerInvoke = function(player)
	if not canUseDevTools(player) then return { Allowed = false } end
	local traits = {}
	for _, trait in ipairs(BitKaisenTraits.Definitions or {}) do
		table.insert(traits, { Id = trait.Id, Name = trait.Name, Rarity = trait.Rarity })
		if #traits >= 120 then break end
	end
	return {
		Allowed = true,
		Clans = { "Gojo", "Zenin", "Kamo", "Inumaki", "Itadori", "Fushiguro", "Nanami", "Todo", "Ieiri", "Kusakabe" },
		Traits = traits,
		CursedTools = BitKaisenCursedTools.GetCatalogPayload({ CursedTools = {} }),
	}
end

devToolsAction.OnServerEvent:Connect(function(player, actionId, data)
	if not checkRateLimit(player, "DevToolsAction") or not canUseDevTools(player) then return end
	local stats = playerLives[player.UserId]
	if not stats then return end
	ensureExtraStats(stats)
	data = typeof(data) == "table" and data or {}
	if actionId == "set_clan" then
		local clan = tostring(data.Clan or "")
		if clan ~= "" then
			stats.FamilyName = clan
			stats.PlayerClanName = clan
			stats.Clan = clan .. " Clan"
			stats.Origin = clan .. " Clan"
			fireLifeUpdate(player, stats, "<font color='#78beff'><b>[ DEV ]</b></font> Clan set to <b>" .. clan .. "</b>.")
		end
	elseif actionId == "stat_delta" then
		local map = { CE = "CursedEnergy", Reputation = "Reputation", Fame = "Fame", Fear = "Fear", Missions = "MissionsCompleted" }
		local field = map[tostring(data.Stat or "")]
		local amount = tonumber(data.Amount) or 0
		if field then
			stats[field] = math.max(0, (tonumber(stats[field]) or 0) + amount)
			fireLifeUpdate(player, stats, "<font color='#78beff'><b>[ DEV ]</b></font> " .. field .. " changed by " .. tostring(amount) .. ".")
		end
	elseif actionId == "add_trait" then
		local traitId = tostring(data.TraitId or "")
		if traitId ~= "" then
			stats.Traits = typeof(stats.Traits) == "table" and stats.Traits or {}
			local exists = false
			for _, owned in ipairs(stats.Traits) do if tostring(owned) == traitId then exists = true end end
			if not exists then table.insert(stats.Traits, traitId) end
			stats.TraitSummary = BitKaisenTraits.GetTraitDisplay(stats)
			fireLifeUpdate(player, stats, "<font color='#78beff'><b>[ DEV ]</b></font> Trait added: <b>" .. traitId .. "</b>.")
		end
	elseif actionId == "remove_trait" then
		local traitId = tostring(data.TraitId or "")
		stats.Traits = typeof(stats.Traits) == "table" and stats.Traits or {}
		for index = #stats.Traits, 1, -1 do
			if tostring(stats.Traits[index]) == traitId then table.remove(stats.Traits, index) end
		end
		stats.TraitSummary = BitKaisenTraits.GetTraitDisplay(stats)
		fireLifeUpdate(player, stats, "<font color='#78beff'><b>[ DEV ]</b></font> Trait removed: <b>" .. traitId .. "</b>.")
	elseif actionId == "grant_cursed_tool" then
		local toolId = tostring(data.ToolId or "")
		local tool = BitKaisenCursedTools.AddTool(stats, toolId, "Developer Tools", getCurrentYear(stats))
		if tool then
			if data.Equip == true then
				BitKaisenCursedTools.EquipTool(stats, tool.Id)
			end
			fireLifeUpdate(player, stats, "<font color='#78beff'><b>[ DEV ]</b></font> Granted cursed tool: <b>" .. tostring(tool.Name) .. "</b>" .. (data.Equip == true and " and equipped it." or "."))
		end
	elseif actionId == "grant_all_cursed_tools" then
		local count = 0
		for _, tool in ipairs(BitKaisenCursedTools.Definitions or {}) do
			if BitKaisenCursedTools.AddTool(stats, tool.Id, "Developer Tools", getCurrentYear(stats)) then
				count += 1
			end
		end
		fireLifeUpdate(player, stats, "<font color='#78beff'><b>[ DEV ]</b></font> Granted <b>" .. tostring(count) .. "</b> cursed tools.")
	elseif actionId == "dev_start_clan_war" then
		stats.ClanFounded = true
		if tostring(stats.PlayerClanName or "") == "" then
			stats.PlayerClanName = tostring(stats.FamilyName or "Developer")
		end
		stats.ClanMembers = math.max(tonumber(stats.ClanMembers) or 0, 4)
		stats.ClanReputation = math.max(tonumber(stats.ClanReputation) or 0, 20)
		local ok, message = BK_ClanWarService.StartWar(stats, "Developer Tools")
		fireLifeUpdate(player, stats, "<font color='#78beff'><b>[ DEV ]</b></font> " .. tostring(message or (ok and "Clan war started." or "Could not start clan war.")))
	elseif actionId == "dev_clear_clan_war" then
		stats.ClanWarState = {}
		stats.ClanWarCooldown = 0
		BK_ClanWarService.EnsureClanWarState(stats)
		fireLifeUpdate(player, stats, "<font color='#78beff'><b>[ DEV ]</b></font> Clan war state cleared.")
	elseif actionId == "dev_finish_clan_war" then
		BK_ClanWarService.EnsureClanWarState(stats)
		local result = tostring(data.Result or "Victory")
		local war = stats.ClanWarState
		war.Active = false
		war.Phase = result
		war.CanAct = false
		war.Description = "Developer tools marked this clan war as " .. string.lower(result) .. "."
		stats.ClanWarCooldown = 0
		if result == "Victory" then
			stats.ClanWarWins = math.max(0, tonumber(stats.ClanWarWins) or 0) + 1
		elseif result == "Defeat" then
			stats.ClanWarLosses = math.max(0, tonumber(stats.ClanWarLosses) or 0) + 1
		end
		fireLifeUpdate(player, stats, "<font color='#78beff'><b>[ DEV ]</b></font> Clan war marked as <b>" .. result .. "</b>.")
	end
	saveStats(player, "DevTools")
end)

-- Asset payload handling moved to BK_AssetService in Phase 4 split.
function getOwnedAssetsPayload(stats)
	return BK_AssetService.GetOwnedAssetsPayload(stats)
end

getAssets.OnServerInvoke = function(player)
	return BK_AssetService.GetAssetsPayload(player)
end

getBlackMarket.OnServerInvoke = function(player)
	return BK_BlackMarketService.GetBlackMarketPayload(player)
end

getCult.OnServerInvoke = function(player)
	return BK_CultService.GetCultPayload(player)
end

getClanWar.OnServerInvoke = function(player)
	return BK_ClanWarService.GetClanWarPayload(player)
end

getCultWar.OnServerInvoke = function(player)
	return BK_CultWarService.GetCultWarPayload(player)
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

	if action == "Reincarnate" then
		if not checkRateLimit(player, "StartNewLife") then
			return
		end

		local ok, errorMessage = startAsReincarnation(player)
		if not ok then
			local stats = playerLives[player.UserId]
			if stats then
				fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ SYSTEM ]</b></font> " .. tostring(errorMessage or "Could not reincarnate."))
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
		adjustKarma(stats, isCurseUser(stats) and -1 or 2)

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


if submitCharacterCustomization then
	submitCharacterCustomization.OnServerInvoke = function(player, payload)
		return applyCharacterCustomization(player, payload)
	end
end

relationshipAction.OnServerEvent:Connect(function(player, relationshipId, actionId, data)
	if not checkRateLimit(player, "RelationshipAction") then
		return
	end

	if actionId == "take_over_child" then
		if typeof(relationshipId) ~= "string" then
			return
		end

		local ok, errorMessage = startAsSuccessor(player, relationshipId, { LiveTakeover = true })
		if not ok then
			local stats = playerLives[player.UserId]
			if stats then
				fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ GOD MODE ]</b></font> " .. tostring(errorMessage or "Could not take over this child."))
			end
		else
			relationshipAction:FireClient(player)
		end
		return
	end

	processRelationshipAction(player, relationshipId, actionId, data)

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

blackMarketAction.OnServerEvent:Connect(function(player, actionId, targetId)
	if not checkRateLimit(player, "BlackMarketAction") then
		return
	end

	BK_BlackMarketService.ProcessBlackMarketAction(player, actionId, targetId)

	-- Tell black market UI listeners to refresh after the server finishes the action.
	blackMarketAction:FireClient(player)
end)

cultAction.OnServerEvent:Connect(function(player, actionId, targetId)
	if not checkRateLimit(player, "CultAction") then
		return
	end

	BK_CultService.ProcessCultAction(player, actionId, targetId)

	-- Tell cult UI listeners to refresh after the server finishes the action.
	cultAction:FireClient(player)
end)

clanWarAction.OnServerEvent:Connect(function(player, actionId)
	if not checkRateLimit(player, "ClanWarAction") then
		return
	end

	BK_ClanWarService.ProcessAction(player, actionId)
	clanWarAction:FireClient(player)
end)

cultWarAction.OnServerEvent:Connect(function(player, actionId)
	if not checkRateLimit(player, "CultWarAction") then
		return
	end

	BK_CultWarService.ProcessAction(player, actionId)
	cultWarAction:FireClient(player)
end)

testPurchase.OnServerEvent:Connect(function(player, purchaseKind, purchaseId)
	if not checkRateLimit(player, "TestPurchase") then
		return
	end
	if not isTestPurchasePlace() then
		warn("[TestPurchase] Rejected outside test place for " .. tostring(player and player.Name))
		return
	end

	local stats = playerLives[player.UserId]
	if not stats then
		return
	end

	purchaseKind = tostring(purchaseKind or "")
	purchaseId = tonumber(purchaseId) or 0
	if purchaseId <= 0 then
		fireLifeUpdate(player, stats, "This test purchase needs a configured Roblox product or gamepass ID first.")
		return
	end

	if purchaseKind == "DeveloperProduct" or purchaseKind == "Product" then
		local ok = BK_CommerceService.GrantDeveloperProduct(player, purchaseId)
		if ok then
			fireLifeUpdate(player, stats, "<font color='#78beff'><b>[ TEST PURCHASE ]</b></font> Developer product granted without Robux in this testing place.")
		end
	elseif purchaseKind == "GamePass" then
		syncMonetizationEntitlements(player, stats)
		forceSaveStats(player, "TestGamePass")
		fireLifeUpdate(player, stats, "<font color='#78beff'><b>[ TEST PURCHASE ]</b></font> Gamepass entitlement simulated in this testing place.")
	else
		warn("[TestPurchase] Unknown purchase kind: " .. tostring(purchaseKind))
	end
end)

jobAction.OnServerEvent:Connect(function(player, actionId, jobId)
	if not checkRateLimit(player, "JobAction") then
		return
	end

	if actionId == "apply" then
		BK_JobService.ApplyForJob(player, jobId)
		jobAction:FireClient(player)
	elseif actionId == "go_rogue" then
		local stats = playerLives[player.UserId]
		if isTestPurchasePlace() or ownsGoRoguePass(player) then
			BK_JobService.GoRogue(player)
		elseif stats then
			fireLifeUpdate(player, stats, "Go Rogue requires the Go Rogue gamepass from the Jobs menu.")
		end
		jobAction:FireClient(player)
	elseif actionId == "rogue_black_market" or actionId == "rogue_hide_trail" or actionId == "rogue_contract" then
		BK_JobService.PerformRogueAction(player, actionId)
		jobAction:FireClient(player)
	end
end)

getMentor.OnServerInvoke = function(player)
	return BK_MentorService.GetPayload(player)
end

mentorAction.OnServerEvent:Connect(function(player, actionId)
	if not checkRateLimit(player, "MentorAction") then
		return
	end

	if actionId == "apply" then
		BK_MentorService.Apply(player)
	end
	mentorAction:FireClient(player)
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



-- Developer product and gamepass receipt logic moved to BK_CommerceService in Phase 1 split.
function grantDeveloperProduct(player, productId)
	return BK_CommerceService.GrantDeveloperProduct(player, productId)
end

-- Code redemption logic moved to BK_CodeService in Phase 1 split.
function getCodeGatePayload(player, clientConfirmedLike)
	return BK_CodeService.GetGatePayload(player, clientConfirmedLike == true)
end

function redeemCodeForPlayer(player, rawCode, clientConfirmedLike)
	return BK_CodeService.Redeem(player, rawCode, clientConfirmedLike == true)
end

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

claimGroupJoinReward.OnServerEvent:Connect(function(player, membershipStatus)
	local stats = playerLives[player.UserId]
	if not stats or stats.Alive == false then return end
	if hasClaimedGroupJoinReward(player, stats) then return end

	local verified = false

	local ok, groups = pcall(function()
		return game:GetService("GroupService"):GetGroupsAsync(player.UserId)
	end)

	if ok and typeof(groups) == "table" then
		for _, groupInfo in ipairs(groups) do
			if groupInfo.Id == BITKAISEN_GROUP_ID then
				verified = true
				break
			end
		end
	else
		local ok2, inGroup = pcall(function()
			return player:IsInGroup(BITKAISEN_GROUP_ID)
		end)
		verified = ok2 and inGroup == true
	end

	if not verified and membershipStatus == "AlreadyMember" then
		verified = true
	end

	if not verified then
		warn("[GameManager] Group join reward denied for " .. tostring(player.Name) .. " â€” not in group.")
		return
	end

	grantGroupJoinReward(player, stats)
end)

getFreeReward.OnServerInvoke = function(player)
	return getFreeRewardPayload(player)
end

claimFreeReward.OnServerInvoke = function(player, clientConfirmedLike)
	return claimFreeMasteryReward(player, clientConfirmedLike == true)
end

ALLOWED_SETTINGS = {
	MusicVolume = "number",
	SFXVolume = "number",

	MuteMusic = "boolean",
	MuteSFX = "boolean",

	FastText = "boolean",
	HighContrastText = "boolean",
	ReducedMotion = "boolean",
	ScreenShake = "boolean",
	SkipCombatSkillChecks = "boolean",
	UIMode = "string",
	GuideEnabled = "boolean",
}

ALLOWED_STRING_VALUES = {
	UIMode = { Computer = true, Mobile = true },
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
	elseif expectedType == "string" then
		if typeof(value) ~= "string" then return end
		local whitelist = ALLOWED_STRING_VALUES[settingName]
		if whitelist and not whitelist[value] then return end
	else
		return
	end

	stats.Settings[settingName] = value
	saveStats(player, "SettingsChanged")
	fireLifeUpdate(player, stats, nil)
end)

BK_Remotes.Get("MarkTutorialSeen").OnServerEvent:Connect(function(player, tutorialName, ageValue)
	if not checkRateLimit(player, "MarkTutorialSeen") then
		return
	end

	if typeof(tutorialName) ~= "string" or tutorialName == "" then
		return
	end

	local stats = playerLives[player.UserId]
	if not stats then
		return
	end

	ensureExtraStats(stats)

	stats.TutorialFlags = stats.TutorialFlags or {}
	stats.TutorialFlags[tutorialName .. "Seen"] = true
	-- Optional: cooldown-based nudges (see cooldownFlags.luau) pass the
	-- current age-unit count here instead of relying on the permanent
	-- "Seen" boolean above, so they can fire again later in the same life
	-- if the same real situation recurs, rather than being a one-shot
	-- forever (that didn't make sense for things like "you're broke" or
	-- "you keep aging without doing anything" -- those can genuinely
	-- happen more than once per life).
	if typeof(ageValue) == "number" then
		stats.TutorialFlags[tutorialName .. "LastAge"] = ageValue
	end
	saveStats(player, "TutorialSeen")
	fireLifeUpdate(player, stats, nil)
end)

----------------------------------------------------------------
-- DEV COMMANDS
-- Developer chat command logic moved to BK_DevCommands in Phase 2 split.
----------------------------------------------------------------

BitKaisenServiceContext = {
	Remotes = {
		RedeemCode = redeemCode,
		GetCodeGate = getCodeGate,
		GetAchievements = getAchievements,
		ClaimAchievement = claimAchievement,
		GetDailyLogin = getDailyLogin,
		ClaimDailyLogin = claimDailyLogin,
	},

	BitKaisenSaveSystem = BitKaisenSaveSystem,

	GetStats = function(player)
		return playerLives[player.UserId]
	end,

	EnsureExtraStats = ensureExtraStats,
	CheckRateLimit = checkRateLimit,
	FireLifeUpdate = fireLifeUpdate,
	FireMajorPopup = fireMajorPopup,
	OnChallengeEvent = function(player, evType, data)
		if not BK_ChallengeService then return end
		local ok, newly = pcall(BK_ChallengeService.OnEvent, player, evType, data or {})
		if ok and newly then
			for _, ch in ipairs(newly) do
				fireMajorPopup(player, "CHALLENGE COMPLETE!", ch.Desc, ch.Title, "+" .. ch.Reward, "success")
				challengeCompleted:FireClient(player, ch.Id)
			end
		end
	end,
	CaptureTraitBuffSnapshot = captureTraitBuffSnapshot,
	ApplyTraitBuffsFromSnapshot = applyTraitBuffsFromSnapshot,
	AwardUnregisteredProgress = awardUnregisteredProgress,
	CheckPromotionAndPopup = checkPromotionAndPopup,
	SyncFamilyStatus = syncFamilyStatus,
	CalculatePlayerPower = calculatePlayerPower,
	SaveStats = saveStats,
	ForceSaveStats = forceSaveStats,
	ResetCombatFight = function(player, reason)
		return BK_CombatService.ResetCurrentFight(player, reason)
	end,
	GetResetFightProductId = function()
		return BK_CommerceService.GetResetFightProductId()
	end,
	GetAFKStabilizationProductId = function()
		return BK_CommerceService.GetAFKStabilizationProductId()
	end,
	StartCombat = function(player, source, enemyConfig)
		return BK_CombatService.StartCombat(player, source, enemyConfig)
	end,
	HasActiveFight = function(player)
		return BK_CombatService.HasActiveFight(player)
	end,
	GetGradeValue = getGradeValue,
	IsDev = isDev,
	ForceAwaken = forceAwaken,
	MaybeTeacherRecommendation = maybeTeacherRecommendation,
	IsCurseUser = isCurseUser,
	IsUnregisteredSorcerer = isUnregisteredSorcerer,
	IsOfficialJujutsuSorcerer = isOfficialJujutsuSorcerer,
	GetEstimatedUnregisteredGrade = getEstimatedUnregisteredGrade,
	EnsureSorcererRegistrationState = ensureSorcererRegistrationState,
	FireRelationshipPopup = fireRelationshipPopup,
	StartNewLife = startNewLife,
	LoadOrStartLife = loadOrStartLife,
	NormalizeCursedSocietyState = normalizeCursedSocietyState,
	AdjustWorldReputation = adjustWorldReputation,
	RefreshCurseRebirthEligibility = refreshCurseRebirthEligibility,
	EnsureCursedSpiritFlavor = ensureCursedSpiritFlavor,
	IsCurseLife = isCurseLife,
	AddCurseHunger = addCurseHunger,
	ReduceCurseHunger = reduceCurseHunger,
	AddSocietyAttention = addSocietyAttention,
	ApplyCursedSpiritActivityFlavor = applyCursedSpiritActivityFlavor,
	PickRandom = pickRandom,
	RollCursedSpiritLifeEvent = rollCursedSpiritLifeEvent,
	BeginCurseSorcererAttack = beginCurseSorcererAttack,
	CurseTerritories = CURSE_TERRITORIES,
	CurseRumorTitles = CURSE_RUMOR_TITLES,

	OwnsDoubleMoneyPass = ownsDoubleMoneyPass,
	OwnsDoubleTrainingPass = ownsDoubleTrainingPass,
	OwnsMissionInvestorPass = ownsMissionInvestorPass,
	OwnsLuckySorcererPass = ownsLuckySorcererPass,
	OwnsTrainingProdigyPass = ownsTrainingProdigyPass,
	OwnsLegacyBlessingPass = ownsLegacyBlessingPass,
	OwnsDojoExpansionPass = ownsDojoExpansionPass,
	OwnsFocusedTrainingPass = ownsFocusedTrainingPass,
	OwnsAFKPass = ownsAFKPass,
	OwnsVIPPass = ownsVIPSorcererPass,
	OwnsBindingVowSpecialistPass = ownsBindingVowSpecialistPass,
	OwnsPremiumOriginsPass = ownsPremiumOriginsPass,
	OwnsHighSocietyPass = ownsHighSocietyPass,
	ClearVIPCache = clearVIPCache,
	SyncMonetizationEntitlements = syncMonetizationEntitlements,
	GenerateDojoRecruitPool = generateDojoRecruitPool,
	CountClanStudents = countClanStudents,

	ResolveMission = resolveMission,
	ProcessCurseUserMission = processCurseUserMission,
	GenerateCurseUserMissionBoard = generateCurseUserMissionBoard,
	GetOfficialGradeName = getOfficialGradeName,
	PendingMissions = pendingMissions,
	ShowMissionSituation = showMissionSituation,

	GetBestParentOrCaretaker = getBestParentOrCaretaker,
	GetCurrentYear = getCurrentYear,
	OwnsVIPSorcererPass = ownsVIPSorcererPass,
	OwnsExtraSaveSlotsPass = ownsExtraSaveSlotsPass,
	OwnsGodModePass = ownsGodModePass,
	OwnsSaveSlotAccess = ownsSaveSlotAccess,

	OwnsAssetById = ownsAssetById,
	CountDojoStudentsAndWards = countDojoStudentsAndWards,
	GetDojoStudentCapacity = getDojoStudentCapacity,
	GetDojoUpgradeCost = getDojoUpgradeCost,
	GetDojoMaintainCost = getDojoMaintainCost,
	GetDojoFocusLabel = getDojoFocusLabel,
	AdjustDojoCondition = adjustDojoCondition,
	NormalizeClanName = normalizeClanName,
	FindRecruitCandidate = findRecruitCandidate,
	RemoveRecruitCandidate = removeRecruitCandidate,
	RecruitCandidateIntoDojo = recruitCandidateIntoDojo,
	CreateClanStudent = createClanStudent,
	GetDojoStudentsForPayload = getDojoStudentsForPayload,

	PassIds = {
		VIP_SORCERER_PASS_ID = VIP_SORCERER_PASS_ID,
		EXTRA_SAVE_SLOTS_PASS_ID = EXTRA_SAVE_SLOTS_PASS_ID,
		DOUBLE_MONEY_PASS_ID = DOUBLE_MONEY_PASS_ID,
		DOUBLE_TRAINING_PASS_ID = DOUBLE_TRAINING_PASS_ID,
		LUCKY_BIRTH_PASS_ID = LUCKY_BIRTH_PASS_ID,
		EXTRA_DOJO_STUDENTS_PASS_ID = EXTRA_DOJO_STUDENTS_PASS_ID,
		GOD_MODE_PASS_ID = GOD_MODE_PASS_ID,
		GO_ROGUE_PASS_ID = GO_ROGUE_PASS_ID,
	},

	IS_DEBUG = IS_DEBUG,
}

BK_CommerceService.Init(BitKaisenServiceContext)
BK_CombatService.Init(BitKaisenServiceContext)
BK_AFKService.Init(BitKaisenServiceContext)
BitKaisenSaveSystem.Init()

BK_CodeService.Init(BitKaisenServiceContext)
BK_AchievementService.Init(BitKaisenServiceContext)
BK_DojoService.Init(BitKaisenServiceContext)
BK_AssetService.Init(BitKaisenServiceContext)
BK_BlackMarketService.Init(BitKaisenServiceContext)
BK_CultService.Init(BitKaisenServiceContext)
BK_ClanWarService.Init(BitKaisenServiceContext)
BK_CultWarService.Init(BitKaisenServiceContext)
BK_DomainService.Init(BitKaisenServiceContext)
BK_GodModeService.Init(BitKaisenServiceContext)
BK_RivalService.Init(BitKaisenServiceContext)
BK_MissionService.Init(BitKaisenServiceContext)
BK_DailyLoginService.Init(BitKaisenServiceContext)
BK_JobService.Init(BitKaisenServiceContext)
BK_SchoolService.Init(BitKaisenServiceContext)
BK_MentorService.Init(BitKaisenServiceContext)
BK_WorldHistoryService.Init(BitKaisenServiceContext)
BK_ActivityService.Init(BitKaisenServiceContext)
BK_RelationshipService.Init(BitKaisenServiceContext)
BK_DevCommands.Init(BitKaisenServiceContext)

initiateGift.OnServerEvent:Connect(function(player, productId, recipientUsername)
	BK_CommerceService.InitiateGift(player, productId, recipientUsername, promptGiftPurchase)
end)

Players.PlayerAdded:Connect(function(player)
	BK_DevCommands.HookPlayer(player)
	-- Grab locale early so translations are ready before any text fires
	task.defer(function()
		local ok, localeId = pcall(function()
			return player.LocaleId
		end)
		if ok and localeId then
			BitKaisenLocale.setPlayerLocale(player.UserId, localeId)
		end
	end)
	loadOrStartLife(player)
	task.defer(function()
		BK_CommerceService.ClaimGiftMailbox(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	BK_AFKService.PlayerRemoving(player)
	BK_RivalService.ClearPlayer(player)
	forceSaveStats(player, "PlayerRemoving")
	BitKaisenLocale.clearPlayer(player.UserId)
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
	ownershipCaches.vip[player.UserId] = nil
	ownershipCaches.extraSaveSlots[player.UserId] = nil
	ownershipCaches.doubleMoney[player.UserId] = nil
	ownershipCaches.doubleTraining[player.UserId] = nil
	ownershipCaches.luckyBirth[player.UserId] = nil
	ownershipCaches.extraDojoStudents[player.UserId] = nil
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

if IS_DEBUG then
	print("[GameManager] Loaded modular BitKaisen GameManager with hard-blocked and Chat-filtered customization names.")
end
