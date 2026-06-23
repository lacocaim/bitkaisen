-- ModuleScript: BK_AchievementService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose:
--   Owns achievement definitions, achievement payloads, and claim rewards.
--   Split out of GameManager to reduce the main script size safely.

local BK_AchievementService = {}
local context = {}
local initialized = false

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

local function checkRateLimit(player, actionKey)
	if context.CheckRateLimit then
		return context.CheckRateLimit(player, actionKey)
	end
	return true
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

local function saveStats(player, reason)
	if context.SaveStats then
		return context.SaveStats(player, reason)
	end
end

local function getGradeValue(grade)
	if context.GetGradeValue then
		return context.GetGradeValue(grade)
	end
	return 0
end

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
	{
		Id = "secret_myth",
		Name = "The Myth",
		Description = "Be born into the Ryomen Clan. People said it never existed.",
		RewardText = "Starting cash: $10,000 once per account",
		IsUnlocked = function(stats)
			return stats.SecretAchievements and stats.SecretAchievements.Myth == true
		end,
		Grant = function(stats)
			return "The Ryomen myth reward is granted automatically at birth."
		end
	},
	{
		Id = "secret_pumpkin_king",
		Name = "All Hail to the Pumpkin Song",
		Description = "Be born into the Pumpkin King Clan with Pumpkin Control.",
		RewardText = "Starting cash: $25,000 once per account",
		IsUnlocked = function(stats)
			return stats.SecretAchievements and stats.SecretAchievements.PumpkinKing == true
		end,
		Grant = function(stats)
			return "The Pumpkin King reward is granted automatically at birth."
		end
	},
}

local function getAchievementDefinition(achievementId)
	for _, definition in ipairs(ACHIEVEMENT_DEFINITIONS) do
		if definition.Id == achievementId then
			return definition
		end
	end

	return nil
end

local function getAchievementPayload(player)
	local stats = getStats(player)

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

local function claimAchievementReward(player, achievementId)
	if typeof(achievementId) ~= "string" then
		return false, "Invalid achievement."
	end

	local stats = getStats(player)
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

function BK_AchievementService.GetPayload(player)
	return getAchievementPayload(player)
end

function BK_AchievementService.Claim(player, achievementId)
	return claimAchievementReward(player, achievementId)
end

function BK_AchievementService.Init(ctx)
	if not ctx or type(ctx.GetStats) ~= "function" then
		print("[BK_AchievementService] Waiting for live GameManager context.")
		return
	end

	if initialized then
		return
	end
	initialized = true
	context = ctx or {}

	local remotes = context.Remotes or {}
	local getAchievements = remotes.GetAchievements
	local claimAchievement = remotes.ClaimAchievement

	if getAchievements then
		getAchievements.OnServerInvoke = function(player)
			return getAchievementPayload(player)
		end
	end

	if claimAchievement then
		claimAchievement.OnServerEvent:Connect(function(player, achievementId)
			if not checkRateLimit(player, "ClaimAchievement") then
				return
			end

			local ok, errorMessage = claimAchievementReward(player, achievementId)

			if not ok then
				local stats = getStats(player)
				if stats then
					fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ ACHIEVEMENT ]</b></font> " .. tostring(errorMessage or "Could not claim achievement."))
				end
			end
		end)
	end

	print("[BK_AchievementService] Loaded real achievement logic.")
end

return BK_AchievementService
