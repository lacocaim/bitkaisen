-- ModuleScript: BK_ChallengeService
-- Location: ServerScriptService.BitKaisenServer

local BK_ChallengeService = {}

local CHALLENGE_POOL = {
	-- Age / Life
	{ Id = "reach_age_50",     Title = "Half a Century",         Desc = "Reach age 50 in a single life.",                  Category = "Life",      Goal = "Age 50",       Reward = "500 XP" },
	{ Id = "reach_age_80",     Title = "Elder Wisdom",           Desc = "Reach age 80 in a single life.",                  Category = "Life",      Goal = "Age 80",       Reward = "800 XP" },
	{ Id = "die_of_old_age",   Title = "Natural Causes",         Desc = "Die of old age (not combat or curse).",            Category = "Life",      Goal = "Natural death",Reward = "600 XP" },
	{ Id = "born_cursed",      Title = "Cursed From Birth",      Desc = "Start a life as a Cursed Spirit.",                 Category = "Life",      Goal = "Be a curse",   Reward = "400 XP" },
	{ Id = "new_life_3x",      Title = "Fresh Start",            Desc = "Begin 3 new lives.",                               Category = "Life",      Goal = "3 new lives",  Reward = "300 XP" },

	-- Combat
	{ Id = "win_5_battles",    Title = "Fighter",                Desc = "Win 5 combat encounters.",                         Category = "Combat",    Goal = "5 victories",  Reward = "700 XP" },
	{ Id = "survive_combat",   Title = "Close Call",             Desc = "Survive a combat encounter below 20% health.",     Category = "Combat",    Goal = "1 survival",   Reward = "500 XP" },
	{ Id = "defeat_rival",     Title = "Nemesis Slain",          Desc = "Defeat a rival in combat.",                        Category = "Combat",    Goal = "1 rival kill", Reward = "900 XP" },
	{ Id = "use_domain",       Title = "Infinite Void",          Desc = "Use a Domain Expansion in combat.",                Category = "Combat",    Goal = "1 domain use", Reward = "800 XP" },

	-- Relationships
	{ Id = "max_bond",         Title = "Unbreakable Bond",       Desc = "Reach max bond with any relationship.",            Category = "Social",    Goal = "Bond 100",     Reward = "600 XP" },
	{ Id = "5_relationships",  Title = "Well Connected",         Desc = "Have 5 active relationships at the same time.",    Category = "Social",    Goal = "5 contacts",   Reward = "400 XP" },
	{ Id = "mentor_someone",   Title = "Pass It On",             Desc = "Mentor another sorcerer.",                         Category = "Social",    Goal = "1 student",    Reward = "500 XP" },

	-- Missions
	{ Id = "complete_5",       Title = "Steady Work",            Desc = "Complete 5 missions in a single life.",            Category = "Missions",  Goal = "5 missions",   Reward = "600 XP" },
	{ Id = "a_rank_mission",   Title = "Elite Grade",            Desc = "Complete an A-Rank mission.",                      Category = "Missions",  Goal = "1 A-Rank",     Reward = "800 XP" },
	{ Id = "special_grade",    Title = "Special Grade Threat",   Desc = "Complete a Special Grade mission.",                Category = "Missions",  Goal = "1 S-Grade",    Reward = "1200 XP"},

	-- Fame / Fear
	{ Id = "fame_50",          Title = "Local Legend",           Desc = "Reach 50 Fame.",                                   Category = "Influence", Goal = "Fame 50",      Reward = "500 XP" },
	{ Id = "fear_50",          Title = "Feared Name",            Desc = "Reach 50 Fear.",                                   Category = "Influence", Goal = "Fear 50",      Reward = "500 XP" },
	{ Id = "wanted_level",     Title = "Wanted",                 Desc = "Reach Wanted Level 3 or higher.",                  Category = "Influence", Goal = "Wanted ≥ 3",   Reward = "700 XP" },

	-- Assets / Money
	{ Id = "earn_100k",        Title = "Six Figures",            Desc = "Earn ¥100,000 across all sources in one life.",    Category = "Assets",    Goal = "¥100,000",     Reward = "400 XP" },
	{ Id = "buy_dojo",         Title = "Property Owner",         Desc = "Purchase a Dojo.",                                 Category = "Assets",    Goal = "Own a dojo",   Reward = "500 XP" },

	-- Affiliations
	{ Id = "join_jjk",         Title = "Jujutsu Society",        Desc = "Join the Jujutsu High affiliation.",               Category = "Affiliation", Goal = "Join JJH",   Reward = "300 XP" },
	{ Id = "reach_rank_2",     Title = "Rising Through Ranks",   Desc = "Reach Grade 2 Sorcerer rank.",                     Category = "Affiliation", Goal = "Grade 2",    Reward = "500 XP" },

	-- Binding Vows
	{ Id = "make_vow",         Title = "Oath Keeper",            Desc = "Forge a Binding Vow.",                             Category = "Vows",      Goal = "1 vow",        Reward = "600 XP" },
}

local CHALLENGES_PER_WEEK = 6

-- ── Week helpers ─────────────────────────────────────────────────────────────
local function getISOWeek()
	local day = math.floor(os.time() / 86400)
	local weekday = (day + 3) % 7
	return math.floor((day - weekday + 10) / 7)
end

-- Cache so shuffle only runs once per week, not on every CheckStats call
local _cachedWeek = -1
local _cachedChallenges = {}
local _cachedActiveIds = {}

local function getWeeklyChallenges()
	local week = getISOWeek()
	if week == _cachedWeek then return _cachedChallenges end

	local poolSize = #CHALLENGE_POOL
	local seed = week * 2654435761
	local indices = {}
	for i = 1, poolSize do indices[i] = i end
	for i = poolSize, 2, -1 do
		seed = (seed * 1664525 + 1013904223) % (2 ^ 32)
		local j = (seed % i) + 1
		indices[i], indices[j] = indices[j], indices[i]
	end
	local picked = {}
	local activeIds = {}
	for i = 1, math.min(CHALLENGES_PER_WEEK, poolSize) do
		local ch = CHALLENGE_POOL[indices[i]]
		table.insert(picked, ch)
		activeIds[ch.Id] = true
	end

	_cachedWeek = week
	_cachedChallenges = picked
	_cachedActiveIds = activeIds
	return picked
end

local function isActiveId(id)
	getWeeklyChallenges() -- ensure cache is warm
	return _cachedActiveIds[id] == true
end

local function secondsUntilReset()
	local now = os.time()
	local day = math.floor(now / 86400)
	local weekday = (day + 3) % 7
	local daysLeft = (7 - weekday) % 7
	if daysLeft == 0 then daysLeft = 7 end
	local nextMonday = (day + daysLeft) * 86400
	return nextMonday - now
end

-- ── Per-player completion tracking (in-memory, resets with server) ───────────
-- completedMap[userId][weekNum][challengeId] = true
local completedMap = {}
-- progressMap[userId] = { BattlesWon = 0, NewLives = 0, ... }
local progressMap = {}

local function getCompleted(userId)
	local week = getISOWeek()
	completedMap[userId] = completedMap[userId] or {}
	completedMap[userId][week] = completedMap[userId][week] or {}
	return completedMap[userId][week]
end

local function getProgress(userId)
	progressMap[userId] = progressMap[userId] or { BattlesWon = 0, NewLives = 0 }
	return progressMap[userId]
end

-- Build a lookup for O(1) access by Id
local _poolById = {}
for _, ch in ipairs(CHALLENGE_POOL) do
	_poolById[ch.Id] = ch
end

-- Returns the challenge table only if it's in this week's active pool and not yet done
local function markComplete(userId, id)
	local done = getCompleted(userId)
	if done[id] then return nil end
	if not isActiveId(id) then return nil end
	local ch = _poolById[id]
	if not ch then return nil end
	done[id] = true
	return ch
end

-- ── Stat-based condition checker ─────────────────────────────────────────────
-- Called every time stats change. Returns list of newly completed challenges.
function BK_ChallengeService.CheckStats(player, stats)
	if not stats then return {} end
	local userId = player.UserId
	local newly = {}

	local function check(id, condition)
		if condition then
			local ch = markComplete(userId, id)
			if ch then table.insert(newly, ch) end
		end
	end

	local age = tonumber(stats.Age) or 0
	local fame = tonumber(stats.Fame) or 0
	local fear = tonumber(stats.Fear) or 0
	local wanted = tonumber(stats.WantedLevel) or 0
	local missions = tonumber(stats.MissionsCompleted) or 0
	local money = tonumber(stats.Money) or 0
	local grade = tostring(stats.Grade or "")
	local causeRaw = string.lower(tostring(stats.CauseOfDeath or ""))

	check("reach_age_50", age >= 50)
	check("reach_age_80", age >= 80)
	check("fame_50",      fame >= 50)
	check("fear_50",      fear >= 50)
	check("wanted_level", wanted >= 3)
	check("complete_5",   missions >= 5)
	check("earn_100k",    money >= 100000)
	check("join_jjk",     stats.InJujutsuHigh == true)
	check("reach_rank_2", grade:find("Grade 2") ~= nil or grade:find("Grade 1") ~= nil or grade:find("Special Grade") ~= nil)
	check("born_cursed",  stats.IsCursedSpirit == true or grade:find("Cursed Spirit") ~= nil)

	-- Death checks — only fire when Alive is false
	if stats.Alive == false then
		local isOldAge = causeRaw:find("old age") ~= nil or causeRaw:find("old") ~= nil and causeRaw:find("age") ~= nil
		check("die_of_old_age", isOldAge)
	end

	-- Relationship bond check
	if stats.Relationships then
		for _, rel in pairs(stats.Relationships) do
			if type(rel) == "table" and (tonumber(rel.Bond) or 0) >= 100 then
				check("max_bond", true)
				break
			end
		end
		local count = 0
		for _ in pairs(stats.Relationships) do count += 1 end
		check("5_relationships", count >= 5)
	end

	-- Binding vow check
	if stats.BindingVows then
		local vowCount = 0
		for _ in pairs(stats.BindingVows) do vowCount += 1 end
		check("make_vow", vowCount >= 1)
	end

	return newly
end

-- ── Event-based checker ───────────────────────────────────────────────────────
-- eventType: "combat_win", "combat_survive_low_hp", "rival_killed",
--            "domain_used", "new_life", "mission_complete", "mentor", "dojo_bought"
function BK_ChallengeService.OnEvent(player, eventType, data)
	local userId = player.UserId
	local prog = getProgress(userId)
	local newly = {}

	local function check(id, condition)
		if condition then
			local ch = markComplete(userId, id)
			if ch then table.insert(newly, ch) end
		end
	end

	if eventType == "combat_win" then
		prog.BattlesWon = (prog.BattlesWon or 0) + 1
		check("win_5_battles", prog.BattlesWon >= 5)

	elseif eventType == "combat_survive_low_hp" then
		check("survive_combat", true)

	elseif eventType == "rival_killed" then
		check("defeat_rival", true)

	elseif eventType == "domain_used" then
		check("use_domain", true)

	elseif eventType == "new_life" then
		prog.NewLives = (prog.NewLives or 0) + 1
		check("new_life_3x", prog.NewLives >= 3)

	elseif eventType == "mission_complete" then
		local rank = tostring((data and data.rank) or "")
		check("a_rank_mission",  rank == "A" or rank == "Special")
		check("special_grade",   rank == "Special")

	elseif eventType == "mentor" then
		check("mentor_someone", true)

	elseif eventType == "dojo_bought" then
		check("buy_dojo", true)
	end

	return newly
end

-- Reset per-life counters when a player starts a new life
-- Returns list of newly completed challenges (e.g. new_life_3x)
function BK_ChallengeService.OnNewLife(player)
	local userId = player.UserId
	local prog = getProgress(userId)
	prog.BattlesWon = 0
	-- NewLives is cumulative for the week, don't reset it
	return BK_ChallengeService.OnEvent(player, "new_life", {})
end

-- ── Public API ───────────────────────────────────────────────────────────────
function BK_ChallengeService.GetCompletedIds(player)
	return getCompleted(player.UserId)
end

function BK_ChallengeService.GetChallengesPayload(player)
	local challenges = getWeeklyChallenges()
	local timeLeft = secondsUntilReset()
	local completedIds = getCompleted(player.UserId)

	return {
		Challenges = challenges,
		ResetsIn = timeLeft,
		CompletedIds = completedIds,
	}
end

return BK_ChallengeService
