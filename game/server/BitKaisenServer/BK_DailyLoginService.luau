-- ModuleScript: BK_DailyLoginService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose:
--   Server-authoritative Daily Login reward logic for BitKaisen.
--
-- Required remotes from BK_Remotes:
--   GetDailyLogin   RemoteFunction
--   ClaimDailyLogin RemoteEvent
--
-- Update:
--   Daily login claim state is now ACCOUNT-WIDE through BitKaisenSaveSystem profile data.
--   This prevents players from claiming again after becoming a Vengeful Curse / Cursed Spirit,
--   starting a new life, or switching slots.
--
-- Notes:
--   - Uses UTC date keys so all servers agree on the same day.
--   - Source of truth is profile.AccountDailyLogin when BitKaisenSaveSystem supports it.
--   - Mirrors data into stats.DailyLogin only for UI/debug/backwards compatibility.
--   - Does not touch missions, relationships, save slots, vows, legacy flow, or UI.

local BK_DailyLoginService = {}

local context = {}
local initialized = false
local claimBusyByUserId = {}
local dailyCacheByUserId = {}

----------------------------------------------------------------
-- CONTEXT BRIDGES
----------------------------------------------------------------

local function getStats(player)
	if context.GetStats then
		return context.GetStats(player)
	end

	return nil
end

local function getSaveSystem()
	return context.BitKaisenSaveSystem
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

local function saveStats(player, reason)
	if context.SaveStats then
		return context.SaveStats(player, reason)
	end
end

local function forceSaveStats(player, reason)
	if context.ForceSaveStats then
		return context.ForceSaveStats(player, reason)
	end

	return saveStats(player, reason)
end

local function checkRateLimit(player, actionKey)
	if context.CheckRateLimit then
		return context.CheckRateLimit(player, actionKey)
	end

	return true
end

----------------------------------------------------------------
-- SMALL TABLE HELPERS
----------------------------------------------------------------

local function shallowCopyTable(source)
	local copy = {}

	if typeof(source) ~= "table" then
		return copy
	end

	for key, value in pairs(source) do
		copy[key] = value
	end

	return copy
end

----------------------------------------------------------------
-- DAILY REWARDS
----------------------------------------------------------------

local DAILY_REWARDS = {
	{
		Day = 1,
		Name = "Starter Funds",
		Short = "+$2,500",
		Grant = function(stats)
			stats.Money = math.max(0, (tonumber(stats.Money) or 0) + 2500)
			return "+$2,500 Money"
		end,
	},

	{
		Day = 2,
		Name = "Cursed Energy",
		Short = "+15 CE",
		Grant = function(stats)
			stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + 15)
			return "+15 Cursed Energy"
		end,
	},

	{
		Day = 3,
		Name = "Technique Practice",
		Short = "+3 Mastery",
		Grant = function(stats)
			stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + 3, 0, 100)
			return "+3 Technique Mastery"
		end,
	},

	{
		Day = 4,
		Name = "Field Reputation",
		Short = "+4 Rep",
		Grant = function(stats)
			stats.Reputation = (tonumber(stats.Reputation) or 0) + 4
			return "+4 Reputation"
		end,
	},

	{
		Day = 5,
		Name = "Teacher Notice",
		Short = "+1 Rec",
		Grant = function(stats)
			stats.TeacherRecommendations = math.max(0, (tonumber(stats.TeacherRecommendations) or 0) + 1)
			stats.Recommendations = math.max(0, (tonumber(stats.Recommendations) or 0) + 1)
			return "+1 Teacher Recommendation"
		end,
	},

	{
		Day = 6,
		Name = "Training Cache",
		Short = "+$7,500 | +25 CE",
		Grant = function(stats)
			stats.Money = math.max(0, (tonumber(stats.Money) or 0) + 7500)
			stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + 25)
			return "+$7,500 Money and +25 Cursed Energy"
		end,
	},

	{
		Day = 7,
		Name = "Weekly Blessing",
		Short = "+$15K | +45 CE | +5 Mastery",
		Grant = function(stats)
			stats.Money = math.max(0, (tonumber(stats.Money) or 0) + 15000)
			stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + 45)
			stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + 5, 0, 100)
			stats.Reputation = (tonumber(stats.Reputation) or 0) + 6
			return "+$15,000 Money, +45 Cursed Energy, +5 Technique Mastery, and +6 Reputation"
		end,
	},
}

----------------------------------------------------------------
-- DATE HELPERS
----------------------------------------------------------------

local function getUTCDateTable(timestamp)
	return os.date("!*t", timestamp or os.time())
end

local function getDateKey(timestamp)
	local t = getUTCDateTable(timestamp)

	return string.format(
		"%04d-%02d-%02d",
		t.year or 1970,
		t.month or 1,
		t.day or 1
	)
end

local function getDayNumber(timestamp)
	local t = getUTCDateTable(timestamp)

	local utcMidnightTimestamp = os.time({
		year = t.year,
		month = t.month,
		day = t.day,
		hour = 0,
		min = 0,
		sec = 0,
		isdst = false,
	})

	return math.floor(utcMidnightTimestamp / 86400)
end

local function isYesterday(lastTimestamp, nowTimestamp)
	if not lastTimestamp or tonumber(lastTimestamp) == nil then
		return false
	end

	local lastDay = getDayNumber(tonumber(lastTimestamp))
	local nowDay = getDayNumber(nowTimestamp or os.time())

	return (nowDay - lastDay) == 1
end

----------------------------------------------------------------
-- DATA DEFAULTS / ACCOUNT STORAGE
----------------------------------------------------------------

local function normalizeDailyLoginTable(daily)
	daily = typeof(daily) == "table" and daily or {}

	daily.LastClaimDate = tostring(daily.LastClaimDate or "")
	daily.LastClaimTimestamp = tonumber(daily.LastClaimTimestamp) or 0
	daily.Streak = math.max(0, tonumber(daily.Streak) or 0)
	daily.BestStreak = math.max(daily.Streak, tonumber(daily.BestStreak) or 0)
	daily.TotalClaims = math.max(0, tonumber(daily.TotalClaims) or 0)

	return daily
end

local function loadAccountDailyLogin(player, stats)
	if not player then
		return normalizeDailyLoginTable(stats and stats.DailyLogin or {})
	end

	if dailyCacheByUserId[player.UserId] then
		local cached = normalizeDailyLoginTable(dailyCacheByUserId[player.UserId])
		if stats then
			stats.DailyLogin = cached
		end
		return cached
	end

	local daily = nil
	local saveSystem = getSaveSystem()

	if saveSystem and type(saveSystem.GetAccountDailyLogin) == "function" then
		local ok, result = pcall(function()
			return saveSystem.GetAccountDailyLogin(player)
		end)

		if ok and typeof(result) == "table" then
			daily = result
		elseif not ok then
			warn("[BK_DailyLoginService] Failed to load account daily data for " .. tostring(player.Name) .. ": " .. tostring(result))
		end
	end

	if typeof(daily) ~= "table" then
		daily = stats and stats.DailyLogin or {}
	end

	daily = normalizeDailyLoginTable(shallowCopyTable(daily))
	dailyCacheByUserId[player.UserId] = daily

	if stats then
		stats.DailyLogin = daily
	end

	return daily
end

local function saveAccountDailyLogin(player, stats, daily)
	if not player then
		return false
	end

	daily = normalizeDailyLoginTable(daily)
	dailyCacheByUserId[player.UserId] = daily

	if stats then
		stats.DailyLogin = daily
	end

	local saveSystem = getSaveSystem()
	if saveSystem and type(saveSystem.SetAccountDailyLogin) == "function" then
		local ok, result = pcall(function()
			return saveSystem.SetAccountDailyLogin(player, daily)
		end)

		if ok then
			return result == true
		end

		warn("[BK_DailyLoginService] Failed to save account daily data for " .. tostring(player.Name) .. ": " .. tostring(result))
	end

	return false
end

local function getRewardForStreak(streakNumber)
	local safeStreak = math.max(1, tonumber(streakNumber) or 1)
	local index = ((safeStreak - 1) % #DAILY_REWARDS) + 1

	return DAILY_REWARDS[index]
end

local function getRewardsPayload()
	local list = {}

	for index, reward in ipairs(DAILY_REWARDS) do
		list[index] = {
			Day = reward.Day or index,
			Name = reward.Name or ("Day " .. tostring(index)),
			Short = reward.Short or "Reward",
		}
	end

	return list
end

local function buildDailyPayload(player)
	local stats = getStats(player)

	if stats then
		ensureExtraStats(stats)
	end

	local daily = loadAccountDailyLogin(player, stats)
	local now = os.time()
	local todayKey = getDateKey(now)

	local alreadyClaimedToday = daily.LastClaimDate == todayKey
	local nextStreak

	if alreadyClaimedToday then
		nextStreak = math.max(1, daily.Streak)
	else
		if isYesterday(daily.LastClaimTimestamp, now) then
			nextStreak = math.max(1, daily.Streak + 1)
		else
			nextStreak = 1
		end
	end

	local nextReward = getRewardForStreak(nextStreak)

	return {
		CanClaim = not alreadyClaimedToday and stats ~= nil,
		Message = stats == nil and "No life is loaded yet." or (alreadyClaimedToday and "Already claimed today." or "Ready to claim."),
		Streak = daily.Streak,
		BestStreak = daily.BestStreak,
		TotalClaims = daily.TotalClaims,
		NextStreak = nextStreak,
		NextReward = {
			Day = nextReward.Day,
			Name = nextReward.Name,
			Short = nextReward.Short,
		},
		Rewards = getRewardsPayload(),
		LastClaimDate = daily.LastClaimDate,
	}
end

----------------------------------------------------------------
-- CLAIM LOGIC
----------------------------------------------------------------

local function claimDailyReward(player)
	if not player then
		return {
			Success = false,
			Message = "Invalid player.",
			Data = nil,
		}
	end

	if claimBusyByUserId[player.UserId] == true then
		return {
			Success = false,
			Message = "Claim already processing.",
			Data = buildDailyPayload(player),
		}
	end

	if not checkRateLimit(player, "ClaimDailyLogin") then
		return {
			Success = false,
			Message = "Slow down before claiming again.",
			Data = buildDailyPayload(player),
		}
	end

	claimBusyByUserId[player.UserId] = true

	local stats = getStats(player)

	if not stats then
		claimBusyByUserId[player.UserId] = nil

		return {
			Success = false,
			Message = "No life is loaded yet.",
			Data = nil,
		}
	end

	ensureExtraStats(stats)

	local daily = loadAccountDailyLogin(player, stats)
	local now = os.time()
	local todayKey = getDateKey(now)

	if daily.LastClaimDate == todayKey then
		claimBusyByUserId[player.UserId] = nil

		return {
			Success = false,
			Message = "Already claimed today.",
			Data = buildDailyPayload(player),
		}
	end

	local nextStreak

	if isYesterday(daily.LastClaimTimestamp, now) then
		nextStreak = math.max(1, daily.Streak + 1)
	else
		nextStreak = 1
	end

	local reward = getRewardForStreak(nextStreak)
	local rewardSummary = "Reward claimed."

	daily.LastClaimDate = todayKey
	daily.LastClaimTimestamp = now
	daily.Streak = nextStreak
	daily.BestStreak = math.max(tonumber(daily.BestStreak) or 0, nextStreak)
	daily.TotalClaims = math.max(0, (tonumber(daily.TotalClaims) or 0) + 1)
	dailyCacheByUserId[player.UserId] = daily
	stats.DailyLogin = daily

	local accountSaveOk = saveAccountDailyLogin(player, stats, daily)
	if not accountSaveOk then
		warn("[BK_DailyLoginService] Account daily save did not confirm for " .. tostring(player.Name) .. ". Session cache still blocks duplicate claims until server shutdown.")
	end

	local ok, result = pcall(function()
		return reward.Grant(stats)
	end)

	if ok and result then
		rewardSummary = result
	elseif not ok then
		warn("[BK_DailyLoginService] Reward grant failed for " .. tostring(player.Name) .. ": " .. tostring(result))
		rewardSummary = "Reward failed to apply, but the daily claim was recorded."
	end

	fireMajorPopup(
		player,
		"DAILY LOGIN",
		"You claimed your daily login reward.",
		"Day " .. tostring(((nextStreak - 1) % #DAILY_REWARDS) + 1),
		rewardSummary
	)

	fireLifeUpdate(
		player,
		stats,
		"<font color='#ffcd69'><b>[ DAILY ]</b></font> Daily login reward claimed.\n" .. tostring(rewardSummary)
	)

	forceSaveStats(player, "DailyLoginClaim")

	local payload = buildDailyPayload(player)

	claimBusyByUserId[player.UserId] = nil

	return {
		Success = true,
		Message = "Daily reward claimed.",
		RewardText = rewardSummary,
		Data = payload,
	}
end

----------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------

function BK_DailyLoginService.GetPayload(player)
	return buildDailyPayload(player)
end

function BK_DailyLoginService.Claim(player)
	return claimDailyReward(player)
end

function BK_DailyLoginService.ClearSessionCache(playerOrUserId)
	local userId = playerOrUserId

	if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
		userId = playerOrUserId.UserId
	end

	if userId then
		dailyCacheByUserId[userId] = nil
		claimBusyByUserId[userId] = nil
	end
end

function BK_DailyLoginService.Init(ctx)
	if initialized then
		return
	end

	context = ctx or {}

	if not context.GetStats then
		warn("[BK_DailyLoginService] Missing context.GetStats. Daily login server logic did not start.")
		return
	end

	local remotes = context.Remotes or {}
	local getDailyLogin = remotes.GetDailyLogin
	local claimDailyLogin = remotes.ClaimDailyLogin

	if not getDailyLogin then
		warn("[BK_DailyLoginService] Missing GetDailyLogin remote.")
		return
	end

	if not claimDailyLogin then
		warn("[BK_DailyLoginService] Missing ClaimDailyLogin remote.")
		return
	end

	initialized = true

	getDailyLogin.OnServerInvoke = function(player)
		return buildDailyPayload(player)
	end

	claimDailyLogin.OnServerEvent:Connect(function(player)
		local result = claimDailyReward(player)
		claimDailyLogin:FireClient(player, result)
	end)

	print("[BK_DailyLoginService] Loaded server daily login rewards with account-wide claim state.")
end

return BK_DailyLoginService
