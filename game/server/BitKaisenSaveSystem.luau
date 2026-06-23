-- ModuleScript: BitKaisenSaveSystem
-- Location: ServerStorage
-- Purpose:
-- Slot-enabled DataStore system for BitKaisen.
-- Supports:
-- 1 main profile key per player
-- 3 life save slots per player
-- legacy migration from the old one-save key
-- retry-protected load/save
-- safe save sanitizing
-- shutdown save support

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BitKaisenSaveSystem = {}

local DATASTORE_NAME = "BitkaizenSave_v2_Slots"
local LEGACY_DATASTORE_NAME = "BitkaizenSave_v1"

local PROFILE_VERSION = 2
local DATA_VERSION = 2

local DEFAULT_SLOT_COUNT = 3
local MAX_RETRIES = 4
local RETRY_BASE_DELAY = 1
local USE_DATASTORE_IN_STUDIO = false
local warnedStudioDataStoreDisabled = false

local saveStore = DataStoreService:GetDataStore(DATASTORE_NAME)
local legacyStore = DataStoreService:GetDataStore(LEGACY_DATASTORE_NAME)

local activeSessions = {}

local function isStudio()
	return RunService:IsStudio()
end

local function shouldUseDataStore()
	if not isStudio() then
		return true
	end
	return USE_DATASTORE_IN_STUDIO == true
end

local function warnStudioDataStoreDisabled()
	if warnedStudioDataStoreDisabled then
		return
	end
	warnedStudioDataStoreDisabled = true
	warn("[BitKaisenSaveSystem] Studio DataStore calls are disabled for local testing. Using temporary fallback saves. Set USE_DATASTORE_IN_STUDIO = true to test API Services.")
end

local function buildLegacyKey(userId)
	return "Player_" .. tostring(userId)
end

local function buildProfileKey(userId)
	return "Player_" .. tostring(userId) .. "_Profile"
end

local ACCOUNT_REWARD_GROUP_JOIN = "GroupJoinRewardClaimed"
local ACCOUNT_DAILY_LOGIN_KEY = "DailyLogin"

local function buildSlotKey(userId, slotId)
	return "Player_" .. tostring(userId) .. "_Slot_" .. tostring(slotId)
end

local function safeCall(fn, ...)
	local args = { ... }
	local attempt = 0
	local lastError

	while attempt < MAX_RETRIES do
		attempt += 1

		local ok, result = pcall(fn, table.unpack(args))

		if ok then
			return true, result
		end

		lastError = result
		warn("[BitKaisenSaveSystem] Attempt " .. tostring(attempt) .. " failed: " .. tostring(result))

		if attempt < MAX_RETRIES then
			task.wait(RETRY_BASE_DELAY * (2 ^ (attempt - 1)))
		end
	end

	return false, lastError
end

local function copyClean(value, depth)
	depth = depth or 0

	if depth > 8 then
		return nil
	end

	local valueType = typeof(value)

	if valueType == "function" or valueType == "Instance" or valueType == "RBXScriptConnection" or valueType == "userdata" then
		return nil
	end

	if valueType ~= "table" then
		return value
	end

	local clean = {}

	for key, nestedValue in pairs(value) do
		local cleanKey = copyClean(key, depth + 1)
		local cleanValue = copyClean(nestedValue, depth + 1)

		if cleanKey ~= nil and cleanValue ~= nil then
			clean[cleanKey] = cleanValue
		end
	end

	return clean
end

local function sanitizeForSave(stats, slotId)
	if typeof(stats) ~= "table" then
		return nil
	end

	local cleanCopy = copyClean(stats, 0)

	if typeof(cleanCopy) ~= "table" then
		return nil
	end

	cleanCopy.__SlotId = nil
	cleanCopy.__SelectedSlot = nil
	cleanCopy.DataVersion = DATA_VERSION
	cleanCopy.SlotId = slotId
	cleanCopy.LastSaved = os.time()

	return cleanCopy
end

local function applyLoadDefaults(stats)
	if typeof(stats) ~= "table" then
		return nil
	end

	stats.DataVersion = stats.DataVersion or DATA_VERSION

	stats.Name = stats.Name or "Unknown"
	stats.FirstName = stats.FirstName or "Unknown"
	stats.FamilyName = stats.FamilyName or "Unknown"
	stats.FamilyType = stats.FamilyType or "Unknown"
	stats.Gender = stats.Gender == "Female" and "Female" or (stats.Gender == "Male" and "Male" or "Unknown")

	stats.Age = stats.Age or 0
	stats.CurrentMonth = math.clamp(tonumber(stats.CurrentMonth) or 1, 1, 12)
	stats.MonthsIntoAge = math.clamp(tonumber(stats.MonthsIntoAge) or 0, 0, 11)
	stats.Health = stats.Health or 100
	stats.Happiness = stats.Happiness or 100
	stats.Smarts = stats.Smarts or 50

	stats.CursedEnergy = stats.CursedEnergy or 0
	stats.Grade = stats.Grade or "Non-Sorcerer"
	stats.Clan = stats.Clan or "Minor Sorcerer Family"
	stats.Origin = stats.Origin or stats.Clan or "Minor Sorcerer Family"
	stats.OriginCategory = stats.OriginCategory or "Family"

	stats.CursedTechnique = stats.CursedTechnique or "None"
	stats.TechniqueMastery = stats.TechniqueMastery or 0
	stats.InnateTechnique = stats.InnateTechnique or "None"
	stats.TechniqueType = stats.TechniqueType or "None"
	stats.TechniqueKnown = stats.TechniqueKnown == true
	stats.TechniqueUsable = stats.TechniqueUsable == true
	stats.TechniqueAwakened = stats.TechniqueAwakened == true
	stats.InnateDormant = stats.InnateDormant == true
	stats.PlayerClanInnateTechnique = stats.PlayerClanInnateTechnique or "None"

	-- Phase 1/2A.5: Cursed Society + Curse Rebirth foundation defaults.
	local origin = tostring(stats.Origin or stats.Clan or "")
	local originCategory = tostring(stats.OriginCategory or "")
	local familyType = tostring(stats.FamilyType or "")
	local race = tostring(stats.Race or "")
	local savedCurseType = tostring(stats.CurseType or "")
	local isCurseLife = stats.IsCurse == true
		or race == "Cursed Spirit"
		or race == "Curse"
		or origin == "Vengeful Spirit Rebirth"
		or origin == "Cursed Spirit Rebirth"
		or origin == "Cursed Rebirth"
		or origin == "Cursed Spirit"
		or origin == "Curse"
		or (originCategory == "Race" and (origin == "Cursed Spirit" or origin == "Curse" or familyType == "Cursed Spirit" or familyType == "Curse"))
		or savedCurseType == "Vengeful Cursed Spirit"
		or savedCurseType == "Fear-Born Cursed Spirit"
		or savedCurseType == "Death-Bound Cursed Spirit"
		or savedCurseType == "Cursed Womb"
		or savedCurseType == "Cursed Spirit"
		or savedCurseType == "Disaster-Class Cursed Spirit"
		-- legacy labels
		or savedCurseType == "Vengeful Curse"
		or savedCurseType == "Fearborn Curse"
		or savedCurseType == "Deathbound Curse"
		or savedCurseType == "Grudge Womb"
		or savedCurseType == "Natural Curse"
		or savedCurseType == "Disaster Curse"
	stats.IsCurse = isCurseLife
	stats.CurseType = tostring(stats.CurseType or (isCurseLife and "Cursed Spirit" or "None"))
	if isCurseLife and stats.CurseType == "None" then stats.CurseType = "Cursed Spirit" end
	stats.CurseGrade = tostring(stats.CurseGrade or (isCurseLife and "Unregistered Grade 3 Cursed Spirit" or "None"))
	stats.CurseClassified = stats.CurseClassified == true
	if isCurseLife and stats.CurseGrade == "None" then stats.CurseGrade = "Unregistered Grade 3 Cursed Spirit" end
	stats.CurseThreat = math.max(0, tonumber(stats.CurseThreat) or 0)
	stats.CurseThreatClass = tostring(stats.CurseThreatClass or (isCurseLife and "Local" or "None"))
	if isCurseLife and stats.CurseThreatClass == "None" then stats.CurseThreatClass = "Local" end
	if tostring(stats.CurseGrade or "") == "Disaster-Class Cursed Spirit" or tostring(stats.CurseGrade or "") == "Unregistered Disaster-Class Cursed Spirit" then
		stats.CurseGrade = stats.CurseClassified and "Special Grade Cursed Spirit" or "Unregistered Special Grade Cursed Spirit"
		stats.CurseThreatClass = "Disaster"
	end
	if isCurseLife and stats.CurseClassified ~= true and string.sub(tostring(stats.CurseGrade or ""), 1, 13) ~= "Unregistered " then
		stats.CurseGrade = "Unregistered " .. tostring(stats.CurseGrade or "Grade 3 Cursed Spirit")
	end
	if isCurseLife and stats.CurseClassified == true and string.sub(tostring(stats.CurseGrade or ""), 1, 13) == "Unregistered " then
		stats.CurseGrade = string.sub(tostring(stats.CurseGrade), 14)
	end
	stats.CurseEvolution = tostring(stats.CurseEvolution or (isCurseLife and "Dormant" or "None"))
	if isCurseLife and stats.CurseEvolution == "None" then stats.CurseEvolution = "Dormant" end
	stats.CurseEvolutionProgress = math.max(0, tonumber(stats.CurseEvolutionProgress) or 0)
	if typeof(stats.CurseMutations) ~= "table" then stats.CurseMutations = {} end
	stats.CurseMutationCount = math.max(0, tonumber(stats.CurseMutationCount) or #stats.CurseMutations)
	stats.CurseLatestMutation = tostring(stats.CurseLatestMutation or "None")
	stats.CurseHunger = math.clamp(tonumber(stats.CurseHunger) or (isCurseLife and 35 or 0), 0, 100)
	stats.CurseTerritory = tostring(stats.CurseTerritory or (isCurseLife and "Abandoned School" or "None"))
	stats.CurseRumor = tostring(stats.CurseRumor or (isCurseLife and "The Mirror Thing" or "None"))
	stats.SocietyAttention = math.clamp(tonumber(stats.SocietyAttention) or tonumber(stats.ExorcismRisk) or 0, 0, 100)
	stats.CurseFearLevel = math.max(0, tonumber(stats.CurseFearLevel) or 0)
	stats.CurseTerritoryControl = math.clamp(tonumber(stats.CurseTerritoryControl) or (isCurseLife and 10 or 0), 0, 100)
	stats.CurseRumorSpread = math.clamp(tonumber(stats.CurseRumorSpread) or 0, 0, 100)
	stats.CiviliansTerrified = math.max(0, tonumber(stats.CiviliansTerrified) or 0)
	stats.HuntersEscaped = math.max(0, tonumber(stats.HuntersEscaped) or 0)
	stats.CursedResentment = math.max(0, tonumber(stats.CursedResentment) or 0)
	stats.CurseRebirthEligible = stats.CurseRebirthEligible == true
	stats.CurseRebirthCount = math.max(0, tonumber(stats.CurseRebirthCount) or 0)
	stats.PreviousLifeName = stats.PreviousLifeName
	stats.PreviousLifeCauseOfDeath = stats.PreviousLifeCauseOfDeath
	stats.SorcererAttackCooldown = math.max(0, tonumber(stats.SorcererAttackCooldown) or 0)
	stats.SorcerersKilled = math.max(0, tonumber(stats.SorcerersKilled) or 0)
	stats.ExorcismRisk = math.clamp(tonumber(stats.ExorcismRisk) or 0, 0, 100)
	stats.TimesExorcised = math.max(0, tonumber(stats.TimesExorcised) or 0)

	stats.SocietyStatus = tostring(stats.SocietyStatus or (isCurseLife and "Unregistered Cursed Spirit" or "Civilian"))
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
	stats.WorldReputationTier = tostring(stats.WorldReputationTier or "Unknown")
	stats.PublicSupport = math.clamp(tonumber(stats.PublicSupport) or 0, 0, 100)
	stats.HunterPressure = math.clamp(tonumber(stats.HunterPressure) or 0, 0, 100)
	stats.CopycatIncidents = math.max(0, tonumber(stats.CopycatIncidents) or 0)
	stats.WorldReputationEvents = math.max(0, tonumber(stats.WorldReputationEvents) or 0)
	stats.ReputationCleanups = math.max(0, tonumber(stats.ReputationCleanups) or 0)
	stats.LastWorldReputationEvent = tostring(stats.LastWorldReputationEvent or "None")
	stats.LifePath = tostring(stats.LifePath or "Undecided")
	stats.PathReputation = math.clamp(tonumber(stats.PathReputation) or 0, 0, 100)
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

	stats.Money = math.floor((tonumber(stats.Money) or 0) * 100 + 0.5) / 100
	stats.AFKStabilizationUnlocked = stats.AFKStabilizationUnlocked == true
	stats.AFKStabilizationEarned = math.max(0, math.floor((tonumber(stats.AFKStabilizationEarned) or 0) * 100 + 0.5) / 100)
	stats.AFKStabilizationSessions = math.max(0, tonumber(stats.AFKStabilizationSessions) or 0)
	stats.Reputation = stats.Reputation or 0
	stats.TeacherRecommendations = stats.TeacherRecommendations or 0
	stats.MissionsCompleted = stats.MissionsCompleted or 0
	stats.MissionsFailed = stats.MissionsFailed or 0

	stats.InJujutsuHigh = stats.InJujutsuHigh or false
	stats.ActivitiesDoneThisAge = stats.ActivitiesDoneThisAge or 0
	stats.RelationshipActionsThisAge = stats.RelationshipActionsThisAge or 0
	stats.RecentLifeEvents = stats.RecentLifeEvents or {}
	stats.RecentQuietTexts = stats.RecentQuietTexts or {}

	stats.Assets = stats.Assets or {}
	stats.Relationships = stats.Relationships or {}
	stats.RelationshipHistory = stats.RelationshipHistory or {}

	stats.ClanFounded = stats.ClanFounded or false
	stats.PlayerClanName = stats.PlayerClanName
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
	stats.WardsAdopted = math.max(0, tonumber(stats.WardsAdopted) or 0)
	stats.RecruitRerollTokens = math.max(0, tonumber(stats.RecruitRerollTokens) or 0)
	stats.DojoFounderName = stats.DojoFounderName or stats.Name or "Unknown"
	stats.DojoClanBaseName = stats.DojoClanBaseName or nil
	stats.DojoNameConfirmed = stats.DojoNameConfirmed == true
	stats.DojoPendingLastNameChoice = stats.DojoPendingLastNameChoice == true
	stats.DojoRecruitPool = stats.DojoRecruitPool or {}
	stats.DojoStarterRecruitLimit = math.max(1, tonumber(stats.DojoStarterRecruitLimit) or 3)
	stats.DojoStarterRecruitsUsed = math.max(0, tonumber(stats.DojoStarterRecruitsUsed) or 0)

	stats.LegacyHistory = stats.LegacyHistory or {}
	stats.Generation = stats.Generation or 1

	stats.Achievements = stats.Achievements or {}
	stats.Achievements.Claimed = stats.Achievements.Claimed or {}

	stats.Codes = stats.Codes or {}
	stats.Codes.Redeemed = stats.Codes.Redeemed or {}

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
		ScreenShake = true,
		SkipCombatSkillChecks = false
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

	if stats.Alive == nil then
		stats.Alive = true
	end

	return stats
end

local function makeEmptySlot(slotId)
	return {
		SlotId = slotId,
		Exists = false,
		Locked = false,
		Name = "Empty Slot",
		Age = 0,
		CurrentMonth = 1,
		MonthsIntoAge = 0,
		Grade = "None",
		Generation = 1,
		FirstName = "Unknown",
		FamilyName = "Unknown",
		Origin = "Unknown",
		Clan = "Unknown",
		Gender = "Unknown",
		CursedTechnique = "None",
		LastPlayed = 0,
		LastSaved = 0
	}
end

local function buildSummary(stats, slotId)
	local summary = makeEmptySlot(slotId)

	if typeof(stats) ~= "table" then
		return summary
	end

	summary.Exists = true
	local firstName = tostring(stats.FirstName or "")
	local familyName = tostring(stats.FamilyName or "")

	if firstName ~= "" and firstName ~= "Unknown" and familyName ~= "" and familyName ~= "Unknown" and familyName ~= "None" then
		summary.Name = firstName .. " " .. familyName
	else
		summary.Name = tostring(stats.Name or "Unknown")
	end

	summary.Age = tonumber(stats.Age) or 0
	summary.CurrentMonth = math.clamp(tonumber(stats.CurrentMonth) or 1, 1, 12)
	summary.MonthsIntoAge = math.clamp(tonumber(stats.MonthsIntoAge) or 0, 0, 11)
	summary.Grade = tostring(stats.Grade or "Unknown")
	summary.Generation = tonumber(stats.Generation) or 1
	summary.FirstName = firstName ~= "" and firstName or "Unknown"
	summary.FamilyName = familyName ~= "" and familyName or "Unknown"
	summary.Origin = tostring(stats.Origin or stats.Clan or "Unknown")
	summary.Clan = tostring(stats.Clan or stats.Origin or "Unknown")
	summary.Gender = tostring(stats.Gender or "Unknown")
	summary.CursedTechnique = tostring(stats.CursedTechnique or "None")
	summary.Alive = stats.Alive ~= false
	summary.LastPlayed = os.time()
	summary.LastSaved = os.time()

	return summary
end

local function createDefaultProfile()
	local profile = {
		ProfileVersion = PROFILE_VERSION,
		SelectedSlot = 1,
		SlotCount = DEFAULT_SLOT_COUNT,
		ExtraSaveSlotsUnlocked = false,
		GiftedGamePasses = {},
		AccountRewards = {},
		AccountDailyLogin = {},
		Slots = {},
		CreatedAt = os.time(),
		UpdatedAt = os.time()
	}

	for slotId = 1, DEFAULT_SLOT_COUNT do
		profile.Slots[slotId] = makeEmptySlot(slotId)
	end

	return profile
end

local function normalizeProfile(profile)
	if typeof(profile) ~= "table" then
		profile = createDefaultProfile()
	end

	profile.ProfileVersion = profile.ProfileVersion or PROFILE_VERSION
	profile.SelectedSlot = math.clamp(tonumber(profile.SelectedSlot) or 1, 1, DEFAULT_SLOT_COUNT)
	profile.SlotCount = DEFAULT_SLOT_COUNT
	profile.ExtraSaveSlotsUnlocked = profile.ExtraSaveSlotsUnlocked == true
	profile.GiftedGamePasses = typeof(profile.GiftedGamePasses) == "table" and profile.GiftedGamePasses or {}
	profile.AccountRewards = typeof(profile.AccountRewards) == "table" and profile.AccountRewards or {}
	profile.AccountRewards[ACCOUNT_REWARD_GROUP_JOIN] = profile.AccountRewards[ACCOUNT_REWARD_GROUP_JOIN] == true
	profile.AccountDailyLogin = typeof(profile.AccountDailyLogin) == "table" and profile.AccountDailyLogin or {}
	profile.Slots = profile.Slots or {}

	for slotId = 1, DEFAULT_SLOT_COUNT do
		if typeof(profile.Slots[slotId]) ~= "table" then
			profile.Slots[slotId] = makeEmptySlot(slotId)
		else
			profile.Slots[slotId].SlotId = slotId
			profile.Slots[slotId].Exists = profile.Slots[slotId].Exists == true
			profile.Slots[slotId].Locked = profile.Slots[slotId].Locked == true
			profile.Slots[slotId].Name = tostring(profile.Slots[slotId].Name or (profile.Slots[slotId].Exists and "Unknown" or "Empty Slot"))
			profile.Slots[slotId].Age = tonumber(profile.Slots[slotId].Age) or 0
			profile.Slots[slotId].CurrentMonth = math.clamp(tonumber(profile.Slots[slotId].CurrentMonth) or 1, 1, 12)
			profile.Slots[slotId].MonthsIntoAge = math.clamp(tonumber(profile.Slots[slotId].MonthsIntoAge) or 0, 0, 11)
			profile.Slots[slotId].Grade = tostring(profile.Slots[slotId].Grade or "None")
			profile.Slots[slotId].Generation = tonumber(profile.Slots[slotId].Generation) or 1
			profile.Slots[slotId].FirstName = tostring(profile.Slots[slotId].FirstName or "Unknown")
			profile.Slots[slotId].FamilyName = tostring(profile.Slots[slotId].FamilyName or "Unknown")
			profile.Slots[slotId].Origin = tostring(profile.Slots[slotId].Origin or profile.Slots[slotId].Clan or "Unknown")
			profile.Slots[slotId].Clan = tostring(profile.Slots[slotId].Clan or profile.Slots[slotId].Origin or "Unknown")
			profile.Slots[slotId].CursedTechnique = tostring(profile.Slots[slotId].CursedTechnique or "None")
			profile.Slots[slotId].LastPlayed = tonumber(profile.Slots[slotId].LastPlayed) or 0
			profile.Slots[slotId].LastSaved = tonumber(profile.Slots[slotId].LastSaved) or 0
		end
	end

	profile.UpdatedAt = os.time()

	return profile
end

local function applyVIPLocksToProfile(profile, hasVIP)
	profile = normalizeProfile(profile)
	local hasSlotAccess = hasVIP == true or profile.ExtraSaveSlotsUnlocked == true

	for slotId = 1, DEFAULT_SLOT_COUNT do
		local slot = profile.Slots[slotId]
		if slot then
			slot.Locked = (slotId > 1 and not hasSlotAccess)
		end
	end

	if profile.SelectedSlot > 1 and not hasSlotAccess then
		profile.SelectedSlot = 1
	end

	return profile
end

local function saveProfileByUserId(userId, profile)
	profile = normalizeProfile(profile)
	profile.UpdatedAt = os.time()

	if not shouldUseDataStore() then
		warnStudioDataStoreDisabled()
		return true
	end

	local key = buildProfileKey(userId)

	local ok, err = safeCall(function()
		saveStore:SetAsync(key, profile)
		return true
	end)

	if not ok then
		warn("[BitKaisenSaveSystem] Profile save failed for " .. tostring(userId) .. ": " .. tostring(err))
		return false
	end

	return true
end

local function loadProfileByUserId(userId)
	if not shouldUseDataStore() then
		warnStudioDataStoreDisabled()
		return createDefaultProfile()
	end

	local key = buildProfileKey(userId)

	local ok, result = safeCall(function()
		return saveStore:GetAsync(key)
	end)

	if not ok then
		warn("[BitKaisenSaveSystem] Profile load failed for " .. tostring(userId) .. ". Using fallback profile.")
		return createDefaultProfile()
	end

	local profile = normalizeProfile(result)

	return profile
end

local function loadSlotDataByUserId(userId, slotId)
	slotId = math.clamp(tonumber(slotId) or 1, 1, DEFAULT_SLOT_COUNT)

	if not shouldUseDataStore() then
		warnStudioDataStoreDisabled()
		return nil
	end

	local key = buildSlotKey(userId, slotId)

	local ok, result = safeCall(function()
		return saveStore:GetAsync(key)
	end)

	if not ok then
		warn("[BitKaisenSaveSystem] Slot load failed for " .. tostring(userId) .. " slot " .. tostring(slotId) .. ".")
		return nil
	end

	if result == nil and slotId == 1 then
		local legacyKey = buildLegacyKey(userId)

		local legacyOk, legacyResult = safeCall(function()
			return legacyStore:GetAsync(legacyKey)
		end)

		if legacyOk and typeof(legacyResult) == "table" then
			warn("[BitKaisenSaveSystem] Migrating legacy save for " .. tostring(userId) .. " into Slot 1.")
			return legacyResult, true
		end
	end

	if typeof(result) ~= "table" then
		return nil
	end

	return result, false
end

local function saveSlotDataByUserId(userId, slotId, stats)
	slotId = math.clamp(tonumber(slotId) or 1, 1, DEFAULT_SLOT_COUNT)

	if not shouldUseDataStore() then
		warnStudioDataStoreDisabled()
		return true
	end

	local cleanData = sanitizeForSave(stats, slotId)

	if not cleanData then
		warn("[BitKaisenSaveSystem] Save aborted for " .. tostring(userId) .. " slot " .. tostring(slotId) .. " (invalid stats).")
		return false
	end

	local slotKey = buildSlotKey(userId, slotId)

	local ok, err = safeCall(function()
		saveStore:SetAsync(slotKey, cleanData)
		return true
	end)

	if not ok then
		warn("[BitKaisenSaveSystem] Slot save failed for " .. tostring(userId) .. " slot " .. tostring(slotId) .. ": " .. tostring(err))
		return false
	end

	local profile = loadProfileByUserId(userId)
	profile.Slots[slotId] = buildSummary(cleanData, slotId)
	profile.SelectedSlot = slotId
	saveProfileByUserId(userId, profile)

	return true
end

function BitKaisenSaveSystem.GetSlotCount()
	return DEFAULT_SLOT_COUNT
end

function BitKaisenSaveSystem.GetSelectedSlot(player)
	if not player then
		return 1
	end

	local session = activeSessions[player.UserId]
	if session and session.SelectedSlot then
		return session.SelectedSlot
	end

	local profile = loadProfileByUserId(player.UserId)
	return profile.SelectedSlot or 1
end

function BitKaisenSaveSystem.GetSlots(player, hasVIP)
	if not player then
		return {
			SelectedSlot = 1,
			SlotCount = DEFAULT_SLOT_COUNT,
			Slots = {}
		}
	end

	local profile = applyVIPLocksToProfile(loadProfileByUserId(player.UserId), hasVIP)

	activeSessions[player.UserId] = activeSessions[player.UserId] or {
		StartedAt = os.time(),
		JobId = game.JobId
	}

	activeSessions[player.UserId].SelectedSlot = profile.SelectedSlot or 1

	return {
		SelectedSlot = profile.SelectedSlot or 1,
		SlotCount = DEFAULT_SLOT_COUNT,
		ExtraSaveSlotsUnlocked = profile.ExtraSaveSlotsUnlocked == true,
		Slots = profile.Slots
	}
end

function BitKaisenSaveSystem.SelectSlot(player, slotId, hasVIP)
	if not player or not player.Parent then
		return false, "Player not found."
	end

	slotId = math.clamp(tonumber(slotId) or 1, 1, DEFAULT_SLOT_COUNT)

	local profile = applyVIPLocksToProfile(loadProfileByUserId(player.UserId), hasVIP)
	local slotSummary = profile.Slots[slotId]

	if not slotSummary or slotSummary.Locked then
		return false, "That slot is locked."
	end

	if slotSummary.Exists ~= true then
		return false, "That slot is empty."
	end

	profile.SelectedSlot = slotId
	saveProfileByUserId(player.UserId, profile)

	activeSessions[player.UserId] = activeSessions[player.UserId] or {
		StartedAt = os.time(),
		JobId = game.JobId
	}

	activeSessions[player.UserId].SelectedSlot = slotId

	return true, nil
end

function BitKaisenSaveSystem.SetSelectedSlot(player, slotId, hasVIP)
	if not player or not player.Parent then
		return false, "Player not found."
	end

	slotId = math.clamp(tonumber(slotId) or 1, 1, DEFAULT_SLOT_COUNT)

	local profile = applyVIPLocksToProfile(loadProfileByUserId(player.UserId), hasVIP)

	if profile.Slots[slotId] and profile.Slots[slotId].Locked then
		return false, "That slot is locked."
	end

	profile.SelectedSlot = slotId
	saveProfileByUserId(player.UserId, profile)

	activeSessions[player.UserId] = activeSessions[player.UserId] or {
		StartedAt = os.time(),
		JobId = game.JobId
	}

	activeSessions[player.UserId].SelectedSlot = slotId

	return true, nil
end

function BitKaisenSaveSystem.LoadSlot(player, slotId)
	if not player or not player.Parent then
		return nil
	end

	slotId = math.clamp(tonumber(slotId) or 1, 1, DEFAULT_SLOT_COUNT)

	if isStudio() and not shouldUseDataStore() then
		warnStudioDataStoreDisabled()
	end

	local result, migratedLegacy = loadSlotDataByUserId(player.UserId, slotId)

	if typeof(result) ~= "table" then
		return nil
	end

	local stats = applyLoadDefaults(result)

	if not stats then	
		return nil
	end

	stats.__SlotId = slotId

	activeSessions[player.UserId] = activeSessions[player.UserId] or {
		StartedAt = os.time(),
		JobId = game.JobId
	}

	activeSessions[player.UserId].SelectedSlot = slotId

	if migratedLegacy then
		saveSlotDataByUserId(player.UserId, slotId, stats)
	end

	return stats
end

function BitKaisenSaveSystem.Load(player, hasVIP)
	if not player or not player.Parent then
		return nil
	end

	local profile = applyVIPLocksToProfile(loadProfileByUserId(player.UserId), hasVIP)
	local selectedSlot = profile.SelectedSlot or 1

	activeSessions[player.UserId] = {
		StartedAt = os.time(),
		JobId = game.JobId,
		SelectedSlot = selectedSlot
	}

	local loaded = BitKaisenSaveSystem.LoadSlot(player, selectedSlot)

	if not loaded then
		return nil
	end

	return loaded
end

function BitKaisenSaveSystem.Save(player, stats, slotId)
	if not player then
		return false
	end

	if typeof(stats) ~= "table" then
		return false
	end

	local resolvedSlot = tonumber(slotId) or tonumber(stats.__SlotId)

	if not resolvedSlot then
		local session = activeSessions[player.UserId]
		resolvedSlot = session and session.SelectedSlot or nil
	end

	if not resolvedSlot then
		local profile = loadProfileByUserId(player.UserId)
		resolvedSlot = profile.SelectedSlot or 1
	end

	resolvedSlot = math.clamp(tonumber(resolvedSlot) or 1, 1, DEFAULT_SLOT_COUNT)
	stats.__SlotId = resolvedSlot

	return saveSlotDataByUserId(player.UserId, resolvedSlot, stats)
end

function BitKaisenSaveSystem.CreateSlot(player, slotId, stats, hasVIP)
	if not player or not player.Parent then
		return false, "Player not found."
	end

	slotId = math.clamp(tonumber(slotId) or 1, 1, DEFAULT_SLOT_COUNT)

	local profile = applyVIPLocksToProfile(loadProfileByUserId(player.UserId), hasVIP)
	local slotSummary = profile.Slots[slotId]

	if not slotSummary then
		return false, "Invalid slot."
	end

	if slotSummary.Locked then
		return false, "That slot is locked."
	end

	if slotSummary.Exists == true then
		return false, "That slot already has a life."
	end

	if typeof(stats) ~= "table" then
		return false, "Missing life data."
	end

	stats.__SlotId = slotId

	local saved = saveSlotDataByUserId(player.UserId, slotId, stats)

	if not saved then
		return false, "Could not save the new slot."
	end

	profile = loadProfileByUserId(player.UserId)
	profile.SelectedSlot = slotId
	saveProfileByUserId(player.UserId, profile)

	activeSessions[player.UserId] = activeSessions[player.UserId] or {
		StartedAt = os.time(),
		JobId = game.JobId
	}

	activeSessions[player.UserId].SelectedSlot = slotId

	return true, nil
end

function BitKaisenSaveSystem.DeleteSlot(player, slotId, hasVIP)
	if not player or not player.Parent then
		return false, "Player not found."
	end

	slotId = math.clamp(tonumber(slotId) or 1, 1, DEFAULT_SLOT_COUNT)

	local profile = applyVIPLocksToProfile(loadProfileByUserId(player.UserId), hasVIP)
	local slotSummary = profile.Slots[slotId]

	if not slotSummary then
		return false, "Invalid slot."
	end

	if slotSummary.Locked then
		return false, "That slot is locked."
	end

	local slotKey = buildSlotKey(player.UserId, slotId)

	local ok, err = safeCall(function()
		saveStore:RemoveAsync(slotKey)
		return true
	end)

	if not ok then
		warn("[BitKaisenSaveSystem] Delete slot failed for " .. tostring(player.UserId) .. " slot " .. tostring(slotId) .. ": " .. tostring(err))
		return false, "Could not delete slot."
	end

	profile.Slots[slotId] = makeEmptySlot(slotId)

	if profile.SelectedSlot == slotId then
		local nextSlot = nil

		for candidateSlot = 1, DEFAULT_SLOT_COUNT do
			if profile.Slots[candidateSlot] and profile.Slots[candidateSlot].Exists == true then
				nextSlot = candidateSlot
				break
			end
		end

		profile.SelectedSlot = nextSlot or 1
	end

	saveProfileByUserId(player.UserId, profile)

	activeSessions[player.UserId] = activeSessions[player.UserId] or {
		StartedAt = os.time(),
		JobId = game.JobId
	}

	activeSessions[player.UserId].SelectedSlot = profile.SelectedSlot

	return true, nil
end

function BitKaisenSaveSystem.HasAccountRewardClaimed(player, rewardKey)
	if not player or rewardKey == nil then
		return false
	end

	local profile = loadProfileByUserId(player.UserId)
	profile.AccountRewards = typeof(profile.AccountRewards) == "table" and profile.AccountRewards or {}

	return profile.AccountRewards[tostring(rewardKey)] == true
end

function BitKaisenSaveSystem.MarkAccountRewardClaimed(player, rewardKey)
	if not player or rewardKey == nil then
		return false
	end

	local profile = loadProfileByUserId(player.UserId)
	profile.AccountRewards = typeof(profile.AccountRewards) == "table" and profile.AccountRewards or {}
	profile.AccountRewards[tostring(rewardKey)] = true

	return saveProfileByUserId(player.UserId, profile)
end

function BitKaisenSaveSystem.HasGroupJoinRewardClaimed(player)
	return BitKaisenSaveSystem.HasAccountRewardClaimed(player, ACCOUNT_REWARD_GROUP_JOIN)
end

function BitKaisenSaveSystem.MarkGroupJoinRewardClaimed(player)
	return BitKaisenSaveSystem.MarkAccountRewardClaimed(player, ACCOUNT_REWARD_GROUP_JOIN)
end

function BitKaisenSaveSystem.GetAccountDailyLogin(player)
	if not player then
		return {}
	end

	local profile = loadProfileByUserId(player.UserId)
	profile.AccountDailyLogin = typeof(profile.AccountDailyLogin) == "table" and profile.AccountDailyLogin or {}

	return copyClean(profile.AccountDailyLogin, 0) or {}
end

function BitKaisenSaveSystem.SetAccountDailyLogin(player, dailyData)
	if not player then
		return false
	end

	local profile = loadProfileByUserId(player.UserId)
	profile.AccountDailyLogin = typeof(dailyData) == "table" and (copyClean(dailyData, 0) or {}) or {}

	return saveProfileByUserId(player.UserId, profile)
end

function BitKaisenSaveSystem.ClearAccountDailyLogin(player)
	if not player then
		return false
	end

	local profile = loadProfileByUserId(player.UserId)
	profile.AccountDailyLogin = {}

	return saveProfileByUserId(player.UserId, profile)
end

function BitKaisenSaveSystem.ReleaseSession(userId)
	activeSessions[userId] = nil
end

function BitKaisenSaveSystem.IsSessionActive(userId)
	return activeSessions[userId] ~= nil
end

function BitKaisenSaveSystem.UnlockExtraSaveSlots(player)
	if not player then
		return false
	end

	local profile = loadProfileByUserId(player.UserId)
	profile.ExtraSaveSlotsUnlocked = true
	return saveProfileByUserId(player.UserId, profile)
end

function BitKaisenSaveSystem.HasExtraSaveSlotsUnlocked(player)
	if not player then
		return false
	end

	local profile = loadProfileByUserId(player.UserId)
	return profile.ExtraSaveSlotsUnlocked == true
end

function BitKaisenSaveSystem.GrantGiftedGamePassByUserId(userId, passKey)
	userId = tonumber(userId)
	passKey = tostring(passKey or "")
	if not userId or userId <= 0 or passKey == "" then
		return false
	end

	local profile = loadProfileByUserId(userId)
	profile.GiftedGamePasses = typeof(profile.GiftedGamePasses) == "table" and profile.GiftedGamePasses or {}
	profile.GiftedGamePasses[passKey] = true
	profile.UpdatedAt = os.time()
	return saveProfileByUserId(userId, profile)
end

function BitKaisenSaveSystem.HasGiftedGamePass(player, passKey)
	if not player then
		return false
	end
	passKey = tostring(passKey or "")
	if passKey == "" then
		return false
	end

	local profile = loadProfileByUserId(player.UserId)
	profile.GiftedGamePasses = typeof(profile.GiftedGamePasses) == "table" and profile.GiftedGamePasses or {}
	return profile.GiftedGamePasses[passKey] == true
end

function BitKaisenSaveSystem.GetGiftedGamePasses(player)
	if not player then
		return {}
	end

	local profile = loadProfileByUserId(player.UserId)
	profile.GiftedGamePasses = typeof(profile.GiftedGamePasses) == "table" and profile.GiftedGamePasses or {}
	local copy = {}
	for key, value in pairs(profile.GiftedGamePasses) do
		if value == true then
			copy[tostring(key)] = true
		end
	end
	return copy
end

function BitKaisenSaveSystem.SaveAllPlayers(playerLives)
	local saving = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local stats = playerLives[player.UserId]

		if stats then
			table.insert(saving, coroutine.create(function()
				BitKaisenSaveSystem.Save(player, stats)
				BitKaisenSaveSystem.ReleaseSession(player.UserId)
			end))
		end
	end

	for _, co in ipairs(saving) do
		coroutine.resume(co)
	end

	local allDone = false
	local startTime = os.clock()

	while not allDone and (os.clock() - startTime) < 25 do
		allDone = true

		for _, co in ipairs(saving) do
			if coroutine.status(co) ~= "dead" then
				allDone = false
				break
			end
		end

		if not allDone then
			task.wait(0.2)
		end
	end
end

return BitKaisenSaveSystem

