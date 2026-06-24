-- ModuleScript: BK_AssetService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose:
--   Phase 4 GameManager split.
--   Owns asset payload + asset action handling that used to live directly inside GameManager.
--   This module intentionally delegates core save/player/stat helpers through context so old systems stay preserved.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BitKaisenAssets = require(ReplicatedStorage:WaitForChild("BitKaisenAssets"))
local BitKaisenCursedTools = require(ReplicatedStorage:WaitForChild("BitKaisenCursedTools"))
local BitKaisenRelationships = require(ReplicatedStorage:WaitForChild("BitKaisenRelationships"))

local BK_AssetService = {}
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

local function syncMonetizationEntitlements(player, stats)
	if context.SyncMonetizationEntitlements then
		return context.SyncMonetizationEntitlements(player, stats)
	end
end

local function getBestParentOrCaretaker(stats)
	if context.GetBestParentOrCaretaker then
		return context.GetBestParentOrCaretaker(stats)
	end
	return nil
end

local function getCurrentYear(stats)
	if context.GetCurrentYear then
		return context.GetCurrentYear(stats)
	end
	return 2000 + (tonumber(stats and stats.Age) or 0)
end

local function ownsVIPSorcererPass(player)
	return context.OwnsVIPSorcererPass and context.OwnsVIPSorcererPass(player) or false
end

local function ownsExtraSaveSlotsPass(player)
	return context.OwnsExtraSaveSlotsPass and context.OwnsExtraSaveSlotsPass(player) or false
end

local function ownsSaveSlotAccess(player)
	return context.OwnsSaveSlotAccess and context.OwnsSaveSlotAccess(player) or false
end

local function ownsAssetById(stats, assetId)
	return context.OwnsAssetById and context.OwnsAssetById(stats, assetId) or false, nil
end

local function countDojoStudentsAndWards(stats)
	return context.CountDojoStudentsAndWards and context.CountDojoStudentsAndWards(stats) or 0
end

local function getDojoStudentCapacity(stats)
	return context.GetDojoStudentCapacity and context.GetDojoStudentCapacity(stats) or 3
end

local function getDojoUpgradeCost(stats)
	return context.GetDojoUpgradeCost and context.GetDojoUpgradeCost(stats) or nil
end

local function getDojoMaintainCost(stats)
	return context.GetDojoMaintainCost and context.GetDojoMaintainCost(stats) or 0
end

local function getDojoFocusLabel(stats)
	return context.GetDojoFocusLabel and context.GetDojoFocusLabel(stats) or "Balanced"
end

local function adjustDojoCondition(stats, amount)
	if context.AdjustDojoCondition then
		return context.AdjustDojoCondition(stats, amount)
	end
end

local function normalizeClanName(rawName, fallbackFamilyName)
	if context.NormalizeClanName then
		return context.NormalizeClanName(rawName, fallbackFamilyName)
	end
	local baseName = tostring(rawName or fallbackFamilyName or "Unnamed")
	return baseName .. " Clan", baseName
end

local function generateDojoRecruitPool(stats)
	if context.GenerateDojoRecruitPool then
		return context.GenerateDojoRecruitPool(stats)
	end
end

local function findRecruitCandidate(stats, candidateId)
	return context.FindRecruitCandidate and context.FindRecruitCandidate(stats, candidateId) or nil
end

local function removeRecruitCandidate(stats, candidateId)
	if context.RemoveRecruitCandidate then
		return context.RemoveRecruitCandidate(stats, candidateId)
	end
end

local function recruitCandidateIntoDojo(stats, candidate)
	return context.RecruitCandidateIntoDojo and context.RecruitCandidateIntoDojo(stats, candidate) or nil
end

local function createClanStudent(stats)
	return context.CreateClanStudent and context.CreateClanStudent(stats) or nil
end

local function getDojoStudentsForPayload(stats)
	return context.GetDojoStudentsForPayload and context.GetDojoStudentsForPayload(stats) or {}
end

local function getPassIds()
	return context.PassIds or {}
end

local function clearDojoParticipation(stats)
	stats.ClanFounded = false
	stats.PlayerClanName = nil
	stats.DojoRank = "No Dojo"
	stats.DojoReputation = 0
	stats.DojoApplicationPending = false
	stats.DojoApplication = nil
	stats.DojoApplicationName = nil
	stats.DojoApplicationFocus = nil
	stats.DojoApplicationRank = nil
	stats.DojoApplicationChance = nil
	stats.DojoApplicationSubmittedAtTotalMonths = nil
	stats.DojoApplicationDecisionAtTotalMonths = nil
	stats.DojoApplicationSenseiName = nil
	stats.DojoApplicationSenseiAge = nil
	stats.DojoApplicationSenseiGrade = nil
	stats.DojoApplicationSenseiRelation = nil
	stats.JoinedDojoName = nil
	stats.JoinedDojoFocus = nil
	stats.JoinedDojoRank = nil
	stats.JoinedDojoTrust = nil
	stats.JoinedDojoProgress = nil
	stats.JoinedDojoAssignments = nil
	stats.JoinedDojoSenseiName = nil
	stats.JoinedDojoSenseiGrade = nil
	stats.JoinedDojoSenseiAge = nil
	stats.JoinedDojoSenseiRelation = nil
	stats.JoinedDojoSenseiTrainingWindow = nil
	stats.JoinedDojoSenseiTrainingUsed = nil
	stats.JoinedDojoAssignmentWindow = nil
	stats.JoinedDojoAssignmentUsed = nil
	stats.JoinedDojoSenseiAdviceWindow = nil
	stats.JoinedDojoSenseiAdviceUsed = nil
end

local function isDojoAction(actionId, assetId)
	local action = tostring(actionId or "")
	return tostring(assetId or "") == "grand_dojo"
		or action == "ApplyForOutsideDojo"
		or action == "TrainAtJoinedDojo"
		or action == "JoinedDojoAssignment"
		or action == "AskJoinedSensei"
		or action == "LeaveJoinedDojo"
		or action == "CancelDojoApplication"
		or string.sub(action, 1, 16) == "ConfirmClanName|"
		or string.sub(action, 1, 17) == "RecruitCandidate|"
		or string.sub(action, 1, 9) == "SetFocus_"
end


local function isCurseUser(stats)
	return context.IsCurseUser and context.IsCurseUser(stats) or false
end

local function isCurseLife(stats)
	return context.IsCurseLife and context.IsCurseLife(stats) or false
end

local function getGradeValue(grade)
	if context.GetGradeValue then
		return context.GetGradeValue(grade)
	end
	local gradeText = tostring(grade or "Non-Sorcerer")
	if string.sub(gradeText, 1, 13) == "Unregistered " then
		gradeText = string.sub(gradeText, 14)
	elseif string.sub(gradeText, 1, 11) == "Curse User " then
		gradeText = string.sub(gradeText, 12)
	end
	local values = {
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
	return values[gradeText] or 0
end




----------------------------------------------------------------
-- OUTSIDE DOJO APPLICATIONS
----------------------------------------------------------------
local NORMAL_DOJO_POOL = {
	{ Name = "Tokyo Shadow Dojo", Focus = "Combat", Rank = "Respected Dojo" },
	{ Name = "Kyoto Barrier Dojo", Focus = "Theory", Rank = "Elite Dojo" },
	{ Name = "Sendai Combat Hall", Focus = "Combat", Rank = "Local Dojo" },
	{ Name = "Osaka Cursed Tool School", Focus = "Discipline", Rank = "Recognized Dojo" },
	{ Name = "Nagoya Quiet Shrine Dojo", Focus = "Balanced", Rank = "Respected Dojo" },
	{ Name = "Fukuoka Exorcist Hall", Focus = "Discipline", Rank = "Elite Dojo" },
}

local CURSE_USER_DOJO_POOL = {
	{ Name = "Shinjuku Back-Alley Dojo", Focus = "Combat", Rank = "Underground Dojo" },
	{ Name = "Osaka Black Rope Hall", Focus = "Discipline", Rank = "Underground Dojo" },
	{ Name = "Kawasaki Rogue Circle", Focus = "Balanced", Rank = "Hidden Dojo" },
	{ Name = "Nara Forbidden Technique Room", Focus = "Theory", Rank = "Hidden Dojo" },
}

local CURSE_SPIRIT_DOJO_POOL = {
	{ Name = "Abandoned Shrine Territory", Focus = "Combat", Rank = "Cursed Territory" },
	{ Name = "Subway Curse Nest", Focus = "Balanced", Rank = "Cursed Territory" },
	{ Name = "Mountain Grudge Den", Focus = "Discipline", Rank = "Cursed Territory" },
}

local SENSEI_FIRST_NAMES = { "Kazuma", "Rei", "Naoya", "Shiori", "Daigo", "Ren", "Maki", "Tsubasa", "Kiyoshi", "Hana", "Goro", "Aki" }
local SENSEI_FAMILY_NAMES = { "Takeda", "Inoue", "Arakawa", "Mizuno", "Kanzaki", "Fushida", "Moriyama", "Kisaragi", "Amamiya", "Kurosawa" }
local SENSEI_GRADES = { "Grade 1", "Grade 1", "Semi-Grade 1", "Special Grade", "Special Grade 1" }
local JOINED_DOJO_TRAIN_LIMIT = 3
local JOINED_DOJO_ASSIGNMENT_LIMIT = 2
local JOINED_DOJO_SENSEI_ADVICE_LIMIT = 1

local function getTotalMonths(stats)
	local age = tonumber(stats and stats.Age) or 0
	local month = math.clamp(tonumber(stats and stats.CurrentMonth) or 1, 1, 12)
	return (age * 12) + (month - 1)
end

local function getDojoTrainingWindow(stats)
	return math.floor(getTotalMonths(stats) / 6)
end

local function getDojoTrainingUsedThisWindow(stats)
	local window = getDojoTrainingWindow(stats)
	if tonumber(stats.DojoTrainingWindow) ~= window then
		stats.DojoTrainingWindow = window
		stats.DojoTrainingUsed = 0
	end
	return tonumber(stats.DojoTrainingUsed) or 0
end

local FAMILY_BUDGET_TIERS = {
	Struggling = { Min = 900, Max = 2500 },
	Modest = { Min = 1800, Max = 4500 },
	Comfortable = { Min = 3500, Max = 8500 },
	Sorcerer = { Min = 6000, Max = 14000 },
	Clan = { Min = 10000, Max = 26000 },
}

local function countLivingParentsOrCaretakers(stats)
	local count = 0
	for _, relationship in ipairs(stats and stats.Relationships or {}) do
		if relationship and relationship.Alive ~= false then
			local role = relationship.Role
			if role == "Mother" or role == "Father" or role == "Caretaker" then
				count += 1
			end
		end
	end
	return count
end

local function chooseFamilyBudgetTier(stats)
	local familyType = tostring(stats and stats.FamilyType or "")
	local origin = tostring(stats and stats.OriginCategory or "")
	local clan = tostring(stats and stats.Clan or "")
	local foundedClanName = tostring(stats and stats.PlayerClanName or "")
	local grade = getGradeValue(stats and stats.Grade)
	local guardians = countLivingParentsOrCaretakers(stats)

	local foundedClan = stats and stats.ClanFounded == true
	if foundedClan or string.find(familyType, "Clan") or origin == "Clan" or foundedClanName ~= "" or string.find(clan, " Clan") then
		return "Clan"
	end
	if string.find(familyType, "Sorcerer") or string.find(origin, "Sorcerer") or grade >= 3 then
		return "Sorcerer"
	end
	if guardians <= 0 then
		return "Struggling"
	end
	if guardians == 1 then
		return math.random(1, 100) <= 25 and "Comfortable" or "Modest"
	end
	return math.random(1, 100) <= 18 and "Comfortable" or "Modest"
end

local function ensureFamilyBudget(stats)
	local age = math.max(0, tonumber(stats and stats.Age) or 0)
	if not stats then
		return { Tier = "Modest", Annual = 0, Remaining = 0, Age = age }
	end

	local tier = tostring(stats.FamilyBudgetTier or "")
	if FAMILY_BUDGET_TIERS[tier] == nil then
		tier = chooseFamilyBudgetTier(stats)
		stats.FamilyBudgetTier = tier
	end

	local bounds = FAMILY_BUDGET_TIERS[tier] or FAMILY_BUDGET_TIERS.Modest
	local annual = tonumber(stats.FamilyAnnualBudget)
	if annual == nil or annual <= 0 then
		annual = math.random(bounds.Min, bounds.Max)
		stats.FamilyAnnualBudget = annual
	end

	if tonumber(stats.FamilyBudgetAge) ~= age or tonumber(stats.FamilyBudgetRemaining) == nil then
		stats.FamilyBudgetAge = age
		stats.FamilyBudgetRemaining = annual
	end

	stats.FamilyBudgetRemaining = math.clamp(tonumber(stats.FamilyBudgetRemaining) or 0, 0, annual)
	return {
		Tier = tier,
		Annual = annual,
		Remaining = stats.FamilyBudgetRemaining,
		Age = age,
	}
end

local PARENT_ASSET_REQUEST_LIMIT_PER_YEAR = 3
local PARENT_ASSET_GIFT_LIMIT_PER_YEAR = 1

local function ensureParentAssetRequestState(stats)
	local age = math.max(0, tonumber(stats and stats.Age) or 0)
	if tonumber(stats.ParentAssetRequestAge) ~= age then
		stats.ParentAssetRequestAge = age
		stats.ParentAssetRequestsUsed = 0
		stats.ParentAssetGiftsReceived = 0
	end
	stats.ParentAssetRequestsUsed = math.max(0, tonumber(stats.ParentAssetRequestsUsed) or 0)
	stats.ParentAssetGiftsReceived = math.max(0, tonumber(stats.ParentAssetGiftsReceived) or 0)
	return stats.ParentAssetRequestsUsed, stats.ParentAssetGiftsReceived
end

local function getRacePathLabel(stats)
	if isCurseLife(stats) then
		return "Cursed Spirit"
	end
	if isCurseUser(stats) then
		return "Curse User"
	end
	if stats and stats.InJujutsuHigh == true then
		return "Jujutsu Student"
	end
	if stats and getGradeValue(stats.Grade) > 0 then
		return "Unregistered Sorcerer"
	end
	return "Civilian"
end

local function getClanReputationInfo(stats)
	local rep = math.max(0, tonumber(stats and stats.ClanReputation) or 0)
	local rankName = "Minor Dojo"
	local nextAt = 25
	local benefit = "Starter reputation. Recruit and train students to be noticed."

	if rep >= 300 then
		rankName = "Legendary Clan"
		nextAt = nil
		benefit = "Maximum rank. Your clan name carries national weight."
	elseif rep >= 150 then
		rankName = "Great Clan"
		nextAt = 300
		benefit = "High reputation. Rival wins and events matter more socially."
	elseif rep >= 75 then
		rankName = "Recognized House"
		nextAt = 150
		benefit = "Recognized reputation. Better student capacity from clan name."
	elseif rep >= 25 then
		rankName = "Rising Clan"
		nextAt = 75
		benefit = "Growing reputation. More prospects take your dojo seriously."
	end

	local bonusStudents = math.clamp(math.floor(rep / 35), 0, 4)
	local toNext = nextAt and math.max(0, nextAt - rep) or 0
	return {
		RankName = rankName,
		NextAt = nextAt,
		ToNext = toNext,
		Benefit = benefit,
		BonusStudents = bonusStudents,
	}
end

local function getClanCompetitiveInfo(stats)
	local rep = math.max(0, tonumber(stats and stats.ClanReputation) or 0)
	local prestige = math.max(0, tonumber(stats and stats.DojoPrestige) or 0)
	local level = math.clamp(tonumber(stats and stats.DojoLevel) or 1, 1, 5)
	local students = countDojoStudentsAndWards(stats or {})
	local rivalWins = math.max(0, tonumber(stats and stats.RivalDojoLosses) or 0)
	local rivalLosses = math.max(0, tonumber(stats and stats.RivalDojoWins) or 0)
	local events = math.max(0, tonumber(stats and stats.DojoEventsHosted) or 0)
	local score = math.max(0, math.floor(rep + prestige + (level * 25) + (students * 12) + (rivalWins * 20) + (events * 8) - (rivalLosses * 8)))
	local tier = "Local"
	if score >= 650 then
		tier = "National"
	elseif score >= 360 then
		tier = "Regional"
	elseif score >= 160 then
		tier = "District"
	end
	return {
		Score = score,
		Tier = tier,
		Record = tostring(rivalWins) .. "W-" .. tostring(rivalLosses) .. "L",
	}
end

local DOJO_EVENT_COOLDOWN_MONTHS = 6
local DOJO_EVENT_POOL = {
	{
		Title = "Open Training Day",
		Kind = "Training",
		Desc = "Invite locals to watch your students train.",
		Button = "HOST",
	},
	{
		Title = "Regional Sparring Invite",
		Kind = "Sparring",
		Desc = "A nearby dojo sends fighters for controlled bouts.",
		Button = "ACCEPT",
	},
	{
		Title = "Mentor Review",
		Kind = "Review",
		Desc = "Senior sorcerers inspect your students and methods.",
		Button = "PREPARE",
	},
	{
		Title = "Community Protection Drill",
		Kind = "Protection",
		Desc = "Run a public safety drill around the dojo grounds.",
		Button = "RUN DRILL",
	},
}

local function getCurrentDojoEvent(stats)
	local total = getTotalMonths(stats)
	return DOJO_EVENT_POOL[(total % #DOJO_EVENT_POOL) + 1]
end

local function getDojoEventState(stats)
	local total = getTotalMonths(stats)
	local last = tonumber(stats and stats.LastDojoEventTotalMonths)
	if last and last > total then
		-- Legacy inheritance can preserve the parent's age-relative cooldown stamp.
		-- Clear future stamps so heirs do not wait hundreds of months.
		last = nil
		if stats then
			stats.LastDojoEventTotalMonths = nil
		end
	end
	local remaining = 0
	if last then
		remaining = math.max(0, (last + DOJO_EVENT_COOLDOWN_MONTHS) - total)
	end
	local event = getCurrentDojoEvent(stats)
	return {
		Available = remaining <= 0,
		CooldownMonths = remaining,
		Title = event.Title,
		Desc = event.Desc,
		Button = event.Button,
		Kind = event.Kind,
	}
end

local RIVAL_CHALLENGE_COOLDOWN_MONTHS = 6
local RIVAL_DOJO_NAMES = {
	"Kurokawa Combat Hall",
	"Hoshinari Barrier School",
	"Mizukara Discipline House",
	"Amahara Cursed Arts Dojo",
	"Tachibana Exorcist Hall",
}
local RIVAL_DOJO_FOCUS = { "Combat", "Theory", "Discipline", "Balanced" }

local function pickRivalDojoName(previousName, stats)
	local startIndex = ((getTotalMonths(stats) + math.random(1, #RIVAL_DOJO_NAMES)) % #RIVAL_DOJO_NAMES) + 1
	for offset = 0, #RIVAL_DOJO_NAMES - 1 do
		local index = ((startIndex + offset - 1) % #RIVAL_DOJO_NAMES) + 1
		local candidate = RIVAL_DOJO_NAMES[index]
		if candidate ~= previousName then
			return candidate
		end
	end
	return RIVAL_DOJO_NAMES[1]
end

local function ensureRivalDojo(stats)
	stats.RivalDojoName = tostring(stats.RivalDojoName or "")
	if stats.RivalDojoName == "" then
		stats.RivalDojoName = pickRivalDojoName(nil, stats)
		stats.RivalDojoFocus = RIVAL_DOJO_FOCUS[math.random(1, #RIVAL_DOJO_FOCUS)]
		stats.RivalDojoReputation = math.max(15, (tonumber(stats.ClanReputation) or 0) + math.random(8, 34))
		stats.RivalDojoWins = 0
		stats.RivalDojoLosses = 0
	end
	stats.RivalDojoFocus = tostring(stats.RivalDojoFocus or "Balanced")
	stats.RivalDojoReputation = math.max(0, tonumber(stats.RivalDojoReputation) or 25)
	stats.RivalDojoWins = math.max(0, tonumber(stats.RivalDojoWins) or 0)
	stats.RivalDojoLosses = math.max(0, tonumber(stats.RivalDojoLosses) or 0)
end

local function replaceDefeatedRivalDojo(stats)
	local previousName = tostring(stats.RivalDojoName or "")
	stats.RivalDojoName = pickRivalDojoName(previousName, stats)
	stats.RivalDojoFocus = RIVAL_DOJO_FOCUS[math.random(1, #RIVAL_DOJO_FOCUS)]
	stats.RivalDojoReputation = math.max(18, (tonumber(stats.ClanReputation) or 0) + math.random(10, 38))
	stats.RivalDojoWins = 0
	stats.RivalDojoLosses = 0
	return previousName, stats.RivalDojoName
end

local function getRivalChallengeState(stats)
	ensureRivalDojo(stats)
	local total = getTotalMonths(stats)
	local last = tonumber(stats.LastRivalDojoChallengeTotalMonths)
	if last and last > total then
		last = nil
		stats.LastRivalDojoChallengeTotalMonths = nil
	end
	local remaining = 0
	if last then
		remaining = math.max(0, (last + RIVAL_CHALLENGE_COOLDOWN_MONTHS) - total)
	end
	return {
		Available = remaining <= 0,
		CooldownMonths = remaining,
	}
end

local function findRelationshipByRole(stats, roleName)
	for _, relationship in ipairs(stats.Relationships or {}) do
		if relationship and relationship.Alive ~= false and tostring(relationship.Role or "") == roleName then
			return relationship
		end
	end
	return nil
end

local function findJujutsuTeacher(stats)
	local best = nil
	local bestScore = -1
	for _, relationship in ipairs(stats.Relationships or {}) do
		if relationship and relationship.Alive ~= false then
			local role = string.lower(tostring(relationship.Role or ""))
			local name = string.lower(tostring(relationship.Name or ""))
			if string.find(role, "teacher", 1, true) or string.find(role, "sensei", 1, true) or string.find(name, "sensei", 1, true) then
				local score = (tonumber(relationship.Respect) or 0) + (tonumber(relationship.Trust) or 0) + (tonumber(relationship.Bond) or 0)
				if score > bestScore then
					best = relationship
					bestScore = score
				end
			end
		end
	end
	return best
end

local function makeRandomSensei(stats, forcedRelation)
	local first = SENSEI_FIRST_NAMES[math.random(1, #SENSEI_FIRST_NAMES)]
	local family = SENSEI_FAMILY_NAMES[math.random(1, #SENSEI_FAMILY_NAMES)]
	local grade = SENSEI_GRADES[math.random(1, #SENSEI_GRADES)]
	return {
		Name = first .. " " .. family,
		Age = math.random(26, 58),
		Grade = grade,
		Relation = forcedRelation or "Outside Sensei",
	}
end

local function chooseApplicationSensei(stats)
	-- Small chance your father becomes the dojo sensei if he is alive. If the save does not store his grade/age,
	-- we safely promote the generated display profile so the sensei still meets the Grade 2+ / 25+ rule.
	local father = findRelationshipByRole(stats, "Father")
	if father and math.random(1, 100) <= 18 then
		return {
			Name = tostring(father.Name or ((stats.FamilyName or "Unknown") .. " Father")),
			Age = math.max(26, tonumber(father.Age) or math.random(31, 52)),
			Grade = getGradeValue(father.Grade) > getGradeValue("Grade 2") and tostring(father.Grade) or "Grade 1",
			Relation = "Father",
		}
	end

	if stats.InJujutsuHigh == true and math.random(1, 100) <= 55 then
		local teacher = findJujutsuTeacher(stats)
		if teacher then
			return {
				Name = tostring(teacher.Name or "Your Jujutsu High Teacher"),
				Age = math.max(26, tonumber(teacher.Age) or math.random(28, 54)),
				Grade = getGradeValue(teacher.Grade) > getGradeValue("Grade 2") and tostring(teacher.Grade) or "Grade 1",
				Relation = "Jujutsu High Teacher",
			}
		end
		local generated = makeRandomSensei(stats, "Jujutsu High Teacher")
		generated.Name = generated.Name .. " Sensei"
		return generated
	end

	return makeRandomSensei(stats, "Outside Sensei")
end

local function chooseApplicationDojo(stats)
	local pool = NORMAL_DOJO_POOL
	if isCurseLife(stats) then
		pool = CURSE_SPIRIT_DOJO_POOL
	elseif isCurseUser(stats) then
		pool = CURSE_USER_DOJO_POOL
	end
	local picked = pool[math.random(1, #pool)]
	return {
		Name = picked.Name,
		Focus = picked.Focus,
		Rank = picked.Rank,
		Path = getRacePathLabel(stats),
	}
end

local function getDojoApplicationChance(stats, application)
	local chance = 38
	chance += math.clamp(math.floor((tonumber(stats.CursedEnergy) or 0) / 8), 0, 16)
	chance += math.clamp(math.floor((tonumber(stats.TechniqueMastery) or 0) / 7), 0, 14)
	chance += math.clamp(math.floor((tonumber(stats.Reputation) or 0) / 8), -12, 16)
	chance += math.clamp(getGradeValue(stats.Grade) * 3, 0, 20)
	chance += math.clamp(math.floor((tonumber(stats.Smarts) or 0) / 12), 0, 8)

	if stats.InJujutsuHigh == true then
		chance += 10
	end
	if tostring(application.Path or "") == "Curse User" then
		chance += math.clamp(math.floor((tonumber(stats.WantedLevel) or 0) / 2), 0, 8)
		chance += math.clamp(math.floor((tonumber(stats.CursedResentment) or 0) / 15), 0, 10)
	end
	if tostring(application.Path or "") == "Cursed Spirit" then
		chance += math.clamp(math.floor((tonumber(stats.CurseThreat) or 0) / 4), 0, 16)
		chance -= 10
	end

	return math.clamp(chance, 12, 88)
end

local function beginOutsideDojoApplication(player, stats)
	-- Release hotfix: do not hard-block young characters here.
	-- If the player can see the button, the click should always visibly respond.
	-- Younger characters simply have a lower natural acceptance chance from their lower stats.
	if stats.DojoApplicationPending == true then
		fireLifeUpdate(player, stats, "You already have a dojo application pending. Wait for the result after six months.")
		return
	end

	if tostring(stats.JoinedDojoName or "") ~= "" then
		fireLifeUpdate(player, stats, "You are already training with <b>" .. tostring(stats.JoinedDojoName) .. "</b>.")
		return
	end

	local application = chooseApplicationDojo(stats)
	local sensei = chooseApplicationSensei(stats)
	local chance = getDojoApplicationChance(stats, application)

	application.SenseiName = sensei.Name
	application.SenseiAge = sensei.Age
	application.SenseiGrade = sensei.Grade
	application.SenseiRelation = sensei.Relation
	application.Chance = chance
	application.SubmittedAtTotalMonths = getTotalMonths(stats)
	application.DecisionAtTotalMonths = getTotalMonths(stats) + 6

	stats.DojoApplicationPending = true
	stats.DojoApplication = application
	stats.DojoApplicationName = application.Name
	stats.DojoApplicationFocus = application.Focus
	stats.DojoApplicationRank = application.Rank
	stats.DojoApplicationChance = chance
	stats.DojoApplicationSubmittedAtTotalMonths = application.SubmittedAtTotalMonths
	stats.DojoApplicationDecisionAtTotalMonths = application.DecisionAtTotalMonths
	stats.DojoApplicationSenseiName = sensei.Name
	stats.DojoApplicationSenseiAge = sensei.Age
	stats.DojoApplicationSenseiGrade = sensei.Grade
	stats.DojoApplicationSenseiRelation = sensei.Relation

	fireMajorPopup(
		player,
		"DOJO APPLICATION SENT",
		"You applied to " .. application.Name .. ". Their answer will arrive after six months.",
		application.Name,
		"Possible sensei: " .. sensei.Name .. " • " .. sensei.Grade
	)

	fireLifeUpdate(player, stats, "<font color='#f0b955'><b>[ DOJO APPLICATION ]</b></font> You applied to <b>" .. application.Name .. "</b>. You will be accepted or rejected after <b>6 months</b>. Estimated acceptance chance: <b>" .. tostring(chance) .. "%</b>.")
	saveStats(player, "outside dojo application")
end

local function getJoinedDojoTrainingWindow(stats)
	local age = tonumber(stats and stats.Age) or 0
	local monthsIntoAge = tonumber(stats and stats.MonthsIntoAge)
	local currentMonth = tonumber(stats and stats.CurrentMonth)

	local half = 1
	if monthsIntoAge ~= nil then
		half = monthsIntoAge >= 6 and 2 or 1
	elseif currentMonth ~= nil then
		half = currentMonth >= 7 and 2 or 1
	end

	return tostring(age) .. ":" .. tostring(half)
end

local function getJoinedDojoSenseiTrainCount(stats)
	local window = getJoinedDojoTrainingWindow(stats)
	if stats.JoinedDojoSenseiTrainingWindow ~= window then
		stats.JoinedDojoSenseiTrainingWindow = window
		stats.JoinedDojoSenseiTrainingUsed = 0
	end
	return tonumber(stats.JoinedDojoSenseiTrainingUsed) or 0, window
end

local function getJoinedDojoAssignmentCount(stats)
	local window = getJoinedDojoTrainingWindow(stats)
	if stats.JoinedDojoAssignmentWindow ~= window then
		stats.JoinedDojoAssignmentWindow = window
		stats.JoinedDojoAssignmentUsed = 0
	end
	return tonumber(stats.JoinedDojoAssignmentUsed) or 0, window
end

local function getJoinedDojoSenseiAdviceCount(stats)
	local window = getJoinedDojoTrainingWindow(stats)
	if stats.JoinedDojoSenseiAdviceWindow ~= window then
		stats.JoinedDojoSenseiAdviceWindow = window
		stats.JoinedDojoSenseiAdviceUsed = 0
	end
	return tonumber(stats.JoinedDojoSenseiAdviceUsed) or 0, window
end

local function trainAtJoinedDojo(player, stats)
	if tostring(stats.JoinedDojoName or "") == "" then
		fireLifeUpdate(player, stats, "You are not part of an outside dojo yet. Apply first.")
		return
	end

	local usedThisWindow = getJoinedDojoSenseiTrainCount(stats)
	local maxTrainPerWindow = JOINED_DOJO_TRAIN_LIMIT

	if usedThisWindow >= maxTrainPerWindow then
		fireLifeUpdate(player, stats, "You already trained with <b>" .. tostring(stats.JoinedDojoSenseiName or "your sensei") .. "</b> <b>" .. tostring(maxTrainPerWindow) .. " times</b> this 6-month period. Age up 6 months before training with your sensei again.")
		return
	end

	stats.JoinedDojoSenseiTrainingUsed = usedThisWindow + 1

	local focus = tostring(stats.JoinedDojoFocus or "Balanced")
	local ceGain = math.random(2, 5)
	local masteryGain = math.random(1, 4)
	local smartsGain = math.random(0, 2)
	local trustGain = math.random(2, 5)
	local progressGain = math.random(5, 11)

	if focus == "Combat" then
		ceGain += 2
		masteryGain += 1
	elseif focus == "Theory" then
		smartsGain += 2
		masteryGain += 1
	elseif focus == "Discipline" then
		trustGain += 2
	elseif focus == "Balanced" then
		progressGain += 2
	end

	stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + ceGain)
	stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + masteryGain, 0, 100)
	stats.Smarts = math.clamp((tonumber(stats.Smarts) or 0) + smartsGain, 0, 100)
	stats.JoinedDojoTrust = math.clamp((tonumber(stats.JoinedDojoTrust) or 0) + trustGain, 0, 100)
	stats.JoinedDojoProgress = math.max(0, (tonumber(stats.JoinedDojoProgress) or 0) + progressGain)
	stats.ActivitiesDoneThisAge = (tonumber(stats.ActivitiesDoneThisAge) or 0) + 1

	local remaining = math.max(0, maxTrainPerWindow - (tonumber(stats.JoinedDojoSenseiTrainingUsed) or 0))
	fireLifeUpdate(player, stats, "You trained at <b>" .. tostring(stats.JoinedDojoName) .. "</b> under <b>" .. tostring(stats.JoinedDojoSenseiName or "your sensei") .. "</b>. +" .. tostring(ceGain) .. " CE, +" .. tostring(masteryGain) .. " Mastery, +" .. tostring(trustGain) .. " Dojo Trust, +" .. tostring(progressGain) .. " Dojo Progress. <b>Sensei training left this 6 months:</b> " .. tostring(remaining) .. ".")
	saveStats(player, "joined dojo training")
end

local function runJoinedDojoAssignment(player, stats)
	if tostring(stats.JoinedDojoName or "") == "" then
		fireLifeUpdate(player, stats, "You are not part of an outside dojo yet. Apply first.")
		return
	end

	local usedThisWindow = getJoinedDojoAssignmentCount(stats)
	if usedThisWindow >= JOINED_DOJO_ASSIGNMENT_LIMIT then
		fireLifeUpdate(player, stats, "You already completed <b>" .. tostring(JOINED_DOJO_ASSIGNMENT_LIMIT) .. "</b> dojo assignments this 6-month period. Age up 6 months before taking more assignments.")
		return
	end

	stats.JoinedDojoAssignmentUsed = usedThisWindow + 1

	local risk = 18 + math.clamp(getGradeValue(stats.Grade) * -1, -8, 0)
	local moneyGain = math.random(90, 240)
	local repGain = math.random(1, 4)
	local progressGain = math.random(4, 10)
	local trustGain = math.random(1, 4)
	local injuryText = ""

	if isCurseUser(stats) then
		moneyGain += math.random(80, 180)
		repGain = -math.random(1, 4)
		stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + math.random(1, 3), 0, 100)
		stats.CursedResentment = math.max(0, (tonumber(stats.CursedResentment) or 0) + math.random(1, 4))
	end

	if math.random(1, 100) <= risk then
		local damage = math.random(3, 10)
		stats.Health = math.clamp((tonumber(stats.Health) or 100) - damage, 0, 100)
		injuryText = " You took <b>" .. tostring(damage) .. "%</b> damage."
	end

	stats.Money = math.max(0, (tonumber(stats.Money) or 0) + moneyGain)
	stats.Reputation = (tonumber(stats.Reputation) or 0) + repGain
	stats.JoinedDojoAssignments = (tonumber(stats.JoinedDojoAssignments) or 0) + 1
	stats.JoinedDojoTrust = math.clamp((tonumber(stats.JoinedDojoTrust) or 0) + trustGain, 0, 100)
	stats.JoinedDojoProgress = math.max(0, (tonumber(stats.JoinedDojoProgress) or 0) + progressGain)

	local remaining = math.max(0, JOINED_DOJO_ASSIGNMENT_LIMIT - (tonumber(stats.JoinedDojoAssignmentUsed) or 0))
	fireLifeUpdate(player, stats, "<b>" .. tostring(stats.JoinedDojoName) .. "</b> gave you a field assignment. +$" .. tostring(moneyGain) .. ", " .. (repGain >= 0 and "+" or "") .. tostring(repGain) .. " Reputation, +" .. tostring(progressGain) .. " Dojo Progress." .. injuryText .. " <b>Assignments left this 6 months:</b> " .. tostring(remaining) .. ".")
	saveStats(player, "joined dojo assignment")
end

local function askJoinedSenseiAdvice(player, stats)
	if tostring(stats.JoinedDojoName or "") == "" then
		fireLifeUpdate(player, stats, "You are not part of an outside dojo yet. Apply first.")
		return
	end

	local usedThisWindow = getJoinedDojoSenseiAdviceCount(stats)
	if usedThisWindow >= JOINED_DOJO_SENSEI_ADVICE_LIMIT then
		fireLifeUpdate(player, stats, "You already asked <b>" .. tostring(stats.JoinedDojoSenseiName or "your sensei") .. "</b> for direct advice this 6-month period. Age up 6 months before asking again.")
		return
	end

	stats.JoinedDojoSenseiAdviceUsed = usedThisWindow + 1

	local sensei = tostring(stats.JoinedDojoSenseiName or "your sensei")
	local relation = tostring(stats.JoinedDojoSenseiRelation or "Sensei")
	local line = ""
	if relation == "Father" then
		line = sensei .. " trained you harder than the others because you are family."
		stats.JoinedDojoTrust = math.clamp((tonumber(stats.JoinedDojoTrust) or 0) + 5, 0, 100)
		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) + 2, 0, 100)
	elseif relation == "Jujutsu High Teacher" then
		line = sensei .. " connected your school lessons to real combat experience."
		stats.Smarts = math.clamp((tonumber(stats.Smarts) or 0) + 2, 0, 100)
		stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + 1, 0, 100)
	else
		line = sensei .. " gave you a practical correction after watching your stance."
		stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + 2)
		stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + 1, 0, 100)
	end

	fireLifeUpdate(player, stats, "<font color='#f0b955'><b>[ SENSEI ]</b></font> " .. line .. " <b>Sensei advice left this 6 months:</b> 0.")
	saveStats(player, "joined dojo sensei advice")
end

local STUDENT_GRADE_ORDER = {
	"Non-Sorcerer",
	"Grade 4",
	"Semi-Grade 3",
	"Grade 3",
	"Semi-Grade 2",
	"Grade 2",
	"Semi-Grade 1",
	"Grade 1",
	"Special Grade"
}

local STUDENT_GRADE_INDEX = {}
for index, grade in ipairs(STUDENT_GRADE_ORDER) do
	STUDENT_GRADE_INDEX[grade] = index
end

local function getStudentPotentialScore(student)
	local potential = tostring(student and student.DojoPotential or "Average")
	if potential == "Hidden" then return 6 end
	if potential == "Special" then return 6 end
	if potential == "Rare" then return 5 end
	if potential == "High" then return 4 end
	if potential == "Average" then return 3 end
	if potential == "Low" then return 2 end
	return 3
end

local function getStudentGradeIndex(grade)
	return STUDENT_GRADE_INDEX[tostring(grade or "Non-Sorcerer")] or 1
end

local function getNextStudentGrade(grade)
	local index = getStudentGradeIndex(grade)
	return STUDENT_GRADE_ORDER[math.clamp(index + 1, 1, #STUDENT_GRADE_ORDER)]
end

local function getStudentPower(student)
	local gradePower = (getStudentGradeIndex(student.Grade) - 1) * 20
	local ce = tonumber(student.CursedEnergy) or 0
	local mastery = tonumber(student.TechniqueMastery) or 0
	local potential = getStudentPotentialScore(student) * 5
	local techniqueBonus = tostring(student.CursedTechnique or "None") ~= "None" and 18 or 0
	return gradePower + math.floor(ce * 0.55) + math.floor(mastery * 1.4) + potential + techniqueBonus
end

local function processAssetAction(player, actionId, assetId)
	local stats = getStats(player)

	if not stats or not stats.Alive then
		return
	end

	ensureExtraStats(stats)

	if typeof(actionId) ~= "string" or typeof(assetId) ~= "string" then
		return
	end

	if actionId == "EquipCursedTool" then
		local ok, result = BitKaisenCursedTools.EquipTool(stats, assetId)
		if ok then
			fireLifeUpdate(player, stats, "<font color='#f0b955'><b>[ CURSED TOOL ]</b></font> Equipped <b>" .. tostring(result.Name) .. "</b>.")
			saveStats(player, "equip cursed tool")
		else
			fireLifeUpdate(player, stats, tostring(result or "Could not equip that cursed tool."))
		end
		return
	elseif actionId == "UnequipCursedTool" then
		BitKaisenCursedTools.UnequipTool(stats)
		fireLifeUpdate(player, stats, "<font color='#f0b955'><b>[ CURSED TOOL ]</b></font> Cursed tool unequipped.")
		saveStats(player, "unequip cursed tool")
		return
	end

	if isCurseLife(stats) and isDojoAction(actionId, assetId) then
		clearDojoParticipation(stats)
		fireLifeUpdate(player, stats, "Cursed spirit lives cannot join, found, or manage human dojos.")
		saveStats(player, "blocked cursed spirit dojo action")
		return
	end

	-- Outside dojo actions are not tied to owning/buying the Grand Dojo asset.
	-- They must run before asset lookup, otherwise older asset lists that do not expose
	-- an id named "grand_dojo" make the button feel like it does nothing.
	if actionId == "ApplyForOutsideDojo" then
		beginOutsideDojoApplication(player, stats)
		return
	elseif actionId == "TrainAtJoinedDojo" then
		trainAtJoinedDojo(player, stats)
		return
	elseif actionId == "JoinedDojoAssignment" then
		runJoinedDojoAssignment(player, stats)
		return
	elseif actionId == "AskJoinedSensei" then
		askJoinedSenseiAdvice(player, stats)
		return
	elseif actionId == "LeaveJoinedDojo" then
		if tostring(stats.JoinedDojoName or "") == "" then
			fireLifeUpdate(player, stats, "You are not part of an outside dojo.")
		else
			local oldDojo = tostring(stats.JoinedDojoName)
			stats.JoinedDojoName = nil
			stats.JoinedDojoFocus = nil
			stats.JoinedDojoRank = nil
			stats.JoinedDojoTrust = nil
			stats.JoinedDojoProgress = nil
			stats.JoinedDojoAssignments = nil
			stats.JoinedDojoSenseiName = nil
			stats.JoinedDojoSenseiGrade = nil
			stats.JoinedDojoSenseiAge = nil
			stats.JoinedDojoSenseiRelation = nil
			stats.JoinedDojoSenseiTrainingWindow = nil
			stats.JoinedDojoSenseiTrainingUsed = nil
			stats.JoinedDojoAssignmentWindow = nil
			stats.JoinedDojoAssignmentUsed = nil
			stats.JoinedDojoSenseiAdviceWindow = nil
			stats.JoinedDojoSenseiAdviceUsed = nil
			fireLifeUpdate(player, stats, "You left <b>" .. oldDojo .. "</b>. You can apply to another dojo later.")
		end
		saveStats(player, "outside dojo leave")
		return
	elseif actionId == "CancelDojoApplication" then
		if stats.DojoApplicationPending == true then
			local oldDojo = tostring(stats.DojoApplicationName or (stats.DojoApplication and stats.DojoApplication.Name) or "the dojo")
			stats.DojoApplicationPending = false
			stats.DojoApplication = nil
			stats.DojoApplicationName = nil
			stats.DojoApplicationFocus = nil
			stats.DojoApplicationRank = nil
			stats.DojoApplicationChance = nil
			stats.DojoApplicationSubmittedAtTotalMonths = nil
			stats.DojoApplicationDecisionAtTotalMonths = nil
			stats.DojoApplicationSenseiName = nil
			stats.DojoApplicationSenseiAge = nil
			stats.DojoApplicationSenseiGrade = nil
			stats.DojoApplicationSenseiRelation = nil
			fireLifeUpdate(player, stats, "You cancelled your application to <b>" .. oldDojo .. "</b>.")
		else
			fireLifeUpdate(player, stats, "You do not have a dojo application pending.")
		end
		saveStats(player, "outside dojo application cancel")
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


	if actionId == "ApplyForOutsideDojo" then
		beginOutsideDojoApplication(player, stats)

	elseif actionId == "TrainAtJoinedDojo" then
		trainAtJoinedDojo(player, stats)

	elseif actionId == "JoinedDojoAssignment" then
		runJoinedDojoAssignment(player, stats)

	elseif actionId == "AskJoinedSensei" then
		askJoinedSenseiAdvice(player, stats)

	elseif actionId == "LeaveJoinedDojo" then
		if tostring(stats.JoinedDojoName or "") == "" then
			fireLifeUpdate(player, stats, "You are not part of an outside dojo.")
		else
			local oldDojo = tostring(stats.JoinedDojoName)
			stats.JoinedDojoName = nil
			stats.JoinedDojoFocus = nil
			stats.JoinedDojoRank = nil
			stats.JoinedDojoTrust = nil
			stats.JoinedDojoProgress = nil
			stats.JoinedDojoAssignments = nil
			stats.JoinedDojoSenseiName = nil
			stats.JoinedDojoSenseiGrade = nil
			stats.JoinedDojoSenseiAge = nil
			stats.JoinedDojoSenseiRelation = nil
			stats.JoinedDojoSenseiTrainingWindow = nil
			stats.JoinedDojoSenseiTrainingUsed = nil
			stats.JoinedDojoAssignmentWindow = nil
			stats.JoinedDojoAssignmentUsed = nil
			stats.JoinedDojoSenseiAdviceWindow = nil
			stats.JoinedDojoSenseiAdviceUsed = nil
			fireLifeUpdate(player, stats, "You left <b>" .. oldDojo .. "</b>. You can apply to another dojo later.")
		end

	elseif actionId == "CancelDojoApplication" then
		if stats.DojoApplicationPending == true then
			local oldDojo = tostring(stats.DojoApplicationName or (stats.DojoApplication and stats.DojoApplication.Name) or "the dojo")
			stats.DojoApplicationPending = false
			stats.DojoApplication = nil
			stats.DojoApplicationName = nil
			stats.DojoApplicationFocus = nil
			stats.DojoApplicationRank = nil
			stats.DojoApplicationChance = nil
			stats.DojoApplicationSubmittedAtTotalMonths = nil
			stats.DojoApplicationDecisionAtTotalMonths = nil
			stats.DojoApplicationSenseiName = nil
			stats.DojoApplicationSenseiAge = nil
			stats.DojoApplicationSenseiGrade = nil
			stats.DojoApplicationSenseiRelation = nil
			fireLifeUpdate(player, stats, "You cancelled your application to <b>" .. oldDojo .. "</b>.")
		else
			fireLifeUpdate(player, stats, "You do not have a pending dojo application.")
		end

	elseif actionId == "AskParent" then
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

		local requestsUsed, giftsReceived = ensureParentAssetRequestState(stats)
		if requestsUsed >= PARENT_ASSET_REQUEST_LIMIT_PER_YEAR then
			fireLifeUpdate(player, stats, "You already asked your parent or caretaker for <b>" .. tostring(PARENT_ASSET_REQUEST_LIMIT_PER_YEAR) .. "</b> asset(s) this year. Age up before asking again.")
			return
		end
		if giftsReceived >= PARENT_ASSET_GIFT_LIMIT_PER_YEAR then
			fireLifeUpdate(player, stats, parent.Name .. " already bought you an asset this year. Age up before asking for another.")
			return
		end

		local budget = ensureFamilyBudget(stats)
		local price = tonumber(asset.Price) or 0
		if price > budget.Remaining then
			fireLifeUpdate(player, stats, parent.Name .. " cannot spend another <b>$" .. tostring(price) .. "</b> on assets this year. Family budget left: <b>$" .. tostring(budget.Remaining) .. "</b>.")
			return
		end

		stats.ParentAssetRequestsUsed = requestsUsed + 1

		local chance = 25
		chance += math.floor((parent.Bond or 0) / 4)
		chance += math.floor((parent.Trust or 0) / 5)
		chance -= math.floor((asset.Price or 0) / 600)

		chance = math.clamp(chance, 5, 85)

		if math.random(1, 100) <= chance then
			stats.FamilyBudgetRemaining = math.max(0, (tonumber(stats.FamilyBudgetRemaining) or 0) - (tonumber(asset.Price) or 0))
			stats.ParentAssetGiftsReceived = (tonumber(stats.ParentAssetGiftsReceived) or 0) + 1
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

	elseif actionId == "BulkBuyAffordable" then
		if (stats.Age or 0) < 16 then
			fireLifeUpdate(player, stats, "You are too young to bulk buy assets yourself. Ask a parent or caretaker for individual items instead.")
			return
		end

		local ownedById = {}
		for _, ownedAsset in ipairs(stats.Assets or {}) do
			if ownedAsset and ownedAsset.Id then
				ownedById[ownedAsset.Id] = true
			end
		end

		local candidates = {}
		for _, candidate in ipairs(BitKaisenAssets.Database or {}) do
			if candidate and candidate.Id and not ownedById[candidate.Id] and candidate.Id ~= "grand_dojo" then
				table.insert(candidates, candidate)
			end
		end
		table.sort(candidates, function(a, b)
			return (tonumber(a.Price) or 0) < (tonumber(b.Price) or 0)
		end)

		local boughtNames = {}
		local spent = 0
		local limit = 5
		for _, candidate in ipairs(candidates) do
			local price = tonumber(candidate.Price) or 0
			if #boughtNames >= limit then
				break
			end
			if price > 0 and (tonumber(stats.Money) or 0) >= price then
				stats.Money -= price
				spent += price
				table.insert(stats.Assets, BitKaisenAssets.MakeOwnedAsset(candidate))
				table.insert(boughtNames, tostring(candidate.Name or candidate.Id))
			end
		end

		if #boughtNames <= 0 then
			fireLifeUpdate(player, stats, "No affordable unowned assets were available for bulk purchase.")
		else
			fireLifeUpdate(player, stats, "Bulk purchased <b>" .. tostring(#boughtNames) .. "</b> asset(s) for <b>$" .. tostring(spent) .. "</b>: " .. table.concat(boughtNames, ", ") .. ".")
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
		if not student then
			fireLifeUpdate(player, stats, "Your Grand Dojo is at capacity. Upgrade later before taking in more students.")
			return
		end
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
			if not student then
				fireLifeUpdate(player, stats, "Your Grand Dojo is at capacity. Upgrade the dojo or raise clan reputation before taking in more students.")
				return
			end
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

		local condition = tonumber(stats.DojoCondition) or 100
		if condition <= 10 then
			fireLifeUpdate(player, stats, "Your Grand Dojo condition is too low for student training. Maintain the dojo first.")
			return
		end

		local usedThisWindow = getDojoTrainingUsedThisWindow(stats)
		if usedThisWindow >= 1 then
			fireLifeUpdate(player, stats, "You already ran a clan student training session this 6-month period. Age up 6 months before training them again.")
			return
		end
		stats.DojoTrainingUsed = usedThisWindow + 1

		local trained = 0
		local promoted = {}
		local focus = getDojoFocusLabel(stats)
		local totalCE = 0
		local totalMastery = 0
		local totalProgress = 0

		for _, relationship in ipairs(stats.Relationships or {}) do
			if relationship.Alive ~= false and relationship.Role == "Student" then
				trained += 1
				local potentialScore = getStudentPotentialScore(relationship)
				local gradeIndex = getStudentGradeIndex(relationship.Grade)
				local bondGain = math.random(1, 4)
				local trustGain = math.random(1, 3)
				local respectGain = math.random(2, 6)
				local ceGain = math.random(3, 9) + math.floor((stats.DojoLevel or 1) / 2) + math.floor(potentialScore / 2)
				local masteryGain = tostring(relationship.CursedTechnique or "None") ~= "None" and math.random(0, 2) + math.floor(potentialScore / 3) or 0
				local progressGain = math.random(5, 12) + potentialScore + math.floor((stats.DojoLevel or 1) / 2)

				if focus == "Combat" then
					respectGain += math.random(2, 5)
					ceGain += math.random(3, 8)
					progressGain += math.random(3, 6)
				elseif focus == "Discipline" then
					respectGain += math.random(2, 4)
					trustGain += math.random(1, 3)
					progressGain += math.random(2, 5)
				elseif focus == "Theory" then
					ceGain += math.random(1, 4)
					masteryGain += math.random(1, 4)
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
				relationship.TechniqueMastery = math.clamp((relationship.TechniqueMastery or 0) + masteryGain, 0, 100)
				relationship.DojoProgress = math.max(0, (relationship.DojoProgress or 0) + progressGain)
				totalCE += ceGain
				totalMastery += masteryGain
				totalProgress += progressGain

				if relationship.Grade == "Non-Sorcerer" and relationship.CursedEnergy >= 35 and math.random(1, 100) <= 35 + (potentialScore * 5) then
					relationship.Grade = "Grade 4"
					table.insert(promoted, tostring(relationship.Name) .. " reached Grade 4")
				else
					local needed = 45 + (gradeIndex * 18)
					if gradeIndex < #STUDENT_GRADE_ORDER and (relationship.DojoProgress or 0) >= needed and getStudentPower(relationship) >= needed then
						local chance = math.clamp(20 + (potentialScore * 8) + math.floor(getStudentPower(relationship) / 24), 10, 78)
						if math.random(1, 100) <= chance then
							relationship.Grade = getNextStudentGrade(relationship.Grade)
							relationship.DojoProgress = math.max(0, math.floor((relationship.DojoProgress or 0) * 0.25))
							table.insert(promoted, tostring(relationship.Name) .. " reached " .. tostring(relationship.Grade))
						end
					end
				end
			end
		end

		if trained <= 0 then
			stats.DojoTrainingUsed = math.max(0, (tonumber(stats.DojoTrainingUsed) or 1) - 1)
			fireLifeUpdate(player, stats, "You need students before holding a clan training session.")
			return
		end

		stats.ClanTrainingSessions = (stats.ClanTrainingSessions or 0) + 1
		stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + math.random(2, 6) + math.floor(trained / 2))
		stats.DojoPrestige = math.max(0, (stats.DojoPrestige or 0) + math.random(2, 5) + math.floor(trained / 3))
		adjustDojoCondition(stats, -math.random(4, 8))
		stats.Reputation = (stats.Reputation or 0) + math.random(1, 3)
		stats.CursedEnergy = math.max(0, (stats.CursedEnergy or 0) + math.random(1, 4))

		local message = "You ran a <b>" .. focus .. "</b> training session for <b>" .. tostring(trained) .. "</b> dojo student(s)."
		message ..= "\nStudent gains: <b>+" .. tostring(totalCE) .. " total CE</b>, <b>+" .. tostring(totalMastery) .. "% total mastery</b>, <b>+" .. tostring(totalProgress) .. " progress</b>."
		if #promoted > 0 then
			message ..= "\n<b>Promotion:</b> " .. table.concat(promoted, "; ") .. "."
		end
		fireLifeUpdate(player, stats, message)


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
			stats.Reputation = (stats.Reputation or 0) + math.random(2, 5)
			adjustDojoCondition(stats, -math.random(4, 8))
			fireLifeUpdate(player, stats, "Your dojo hosted a strong sparring event. The <b>" .. tostring(stats.PlayerClanName or "clan") .. "</b> gained prestige and reputation.")
		else
			stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) - math.random(1, 4))
			adjustDojoCondition(stats, -math.random(8, 14))
			fireLifeUpdate(player, stats, "The sparring event was messy. Nobody was seriously hurt, but the dojo lost condition and some reputation.")
		end

	elseif actionId == "ChallengeRivalDojo" then
		if assetId ~= "grand_dojo" then
			return
		end

		local owned = ownsAsset()
		if not owned then
			fireLifeUpdate(player, stats, "You need to own a <b>Grand Dojo</b> first.")
			return
		end

		if not stats.ClanFounded then
			fireLifeUpdate(player, stats, "Found your clan before challenging rival dojos.")
			return
		end

		local students = countDojoStudentsAndWards(stats)
		if students <= 0 then
			fireLifeUpdate(player, stats, "You need students or wards before challenging a rival dojo.")
			return
		end

		local challengeState = getRivalChallengeState(stats)
		if not challengeState.Available then
			fireLifeUpdate(player, stats, "Your students need <b>" .. tostring(challengeState.CooldownMonths) .. "</b> more month(s) before another rival challenge.")
			return
		end

		stats.LastRivalDojoChallengeTotalMonths = getTotalMonths(stats)
		local ownScore = (tonumber(stats.ClanReputation) or 0) + (tonumber(stats.DojoPrestige) or 0) + (students * 8) + ((tonumber(stats.DojoCondition) or 100) / 2)
		local rivalScore = (tonumber(stats.RivalDojoReputation) or 25) + math.random(15, 55)
		local win = ownScore + math.random(1, 45) >= rivalScore
		local progressGain = math.random(2, 6)

		for _, relationship in ipairs(stats.Relationships or {}) do
			if relationship and relationship.Alive ~= false and (relationship.Role == "Student" or relationship.Role == "Ward") then
				relationship.DojoProgress = math.max(0, (tonumber(relationship.DojoProgress) or 0) + progressGain)
			end
		end

		if win then
			local repGain = math.random(5, 11)
			local prestigeGain = math.random(4, 9)
			local defeatedName = tostring(stats.RivalDojoName or "Unknown Rival")
			stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) + repGain)
			stats.DojoPrestige = math.max(0, (tonumber(stats.DojoPrestige) or 0) + prestigeGain)
			stats.RivalDojoLosses = (tonumber(stats.RivalDojoLosses) or 0) + 1
			stats.RivalDojoReputation = math.max(0, (tonumber(stats.RivalDojoReputation) or 0) - math.random(1, 4))
			local rivalDefeated = stats.RivalDojoReputation <= 0
			local newRivalName = nil
			if rivalDefeated then
				local _previousRivalName
				_previousRivalName, newRivalName = replaceDefeatedRivalDojo(stats)
			end
			adjustDojoCondition(stats, -math.random(4, 9))
			local rivalMessage = "Your students defeated <b>" .. defeatedName .. "</b>. Clan reputation <b>+" .. tostring(repGain) .. "</b>, dojo prestige <b>+" .. tostring(prestigeGain) .. "</b>."
			if rivalDefeated then
				rivalMessage ..= "\n<b>" .. defeatedName .. "</b> collapsed as a rival. <b>" .. tostring(newRivalName) .. "</b> has started watching your clan."
			end
			fireLifeUpdate(player, stats, rivalMessage)
		else
			local repLoss = math.random(1, 4)
			stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) - repLoss)
			stats.RivalDojoWins = (tonumber(stats.RivalDojoWins) or 0) + 1
			stats.RivalDojoReputation = math.max(0, (tonumber(stats.RivalDojoReputation) or 0) + math.random(2, 6))
			adjustDojoCondition(stats, -math.random(6, 12))
			fireLifeUpdate(player, stats, "<b>" .. tostring(stats.RivalDojoName) .. "</b> outperformed your students. Clan reputation <b>-" .. tostring(repLoss) .. "</b>, but students gained <b>+" .. tostring(progressGain) .. "</b> progress from the loss.")
		end

	elseif actionId == "ResolveDojoEvent" then
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

		local students = countDojoStudentsAndWards(stats)
		if students <= 0 then
			fireLifeUpdate(player, stats, "You need students or wards before hosting dojo events.")
			return
		end

		local eventState = getDojoEventState(stats)
		if not eventState.Available then
			fireLifeUpdate(player, stats, "The dojo needs <b>" .. tostring(eventState.CooldownMonths) .. "</b> more month(s) before the next event.")
			return
		end

		stats.LastDojoEventTotalMonths = getTotalMonths(stats)
		stats.LastDojoEventName = eventState.Title
		stats.DojoEventsHosted = (stats.DojoEventsHosted or 0) + 1

		local reputationGain = math.random(3, 7)
		local prestigeGain = math.random(2, 6)
		local conditionLoss = math.random(3, 7)
		local studentProgress = math.random(2, 5)

		if eventState.Kind == "Sparring" then
			reputationGain += math.random(2, 5)
			prestigeGain += math.random(2, 4)
			conditionLoss += math.random(2, 5)
		elseif eventState.Kind == "Review" then
			prestigeGain += math.random(3, 6)
			studentProgress += 1
		elseif eventState.Kind == "Protection" then
			reputationGain += math.random(3, 6)
			stats.Reputation = (stats.Reputation or 0) + math.random(1, 3)
		end

		for _, relationship in ipairs(stats.Relationships or {}) do
			if relationship and relationship.Alive ~= false and (relationship.Role == "Student" or relationship.Role == "Ward") then
				relationship.DojoProgress = math.max(0, (tonumber(relationship.DojoProgress) or 0) + studentProgress)
				if eventState.Kind == "Review" and tostring(relationship.CursedTechnique or "None") ~= "None" then
					relationship.TechniqueMastery = math.clamp((tonumber(relationship.TechniqueMastery) or 0) + 1, 0, 100)
				end
			end
		end

		stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + reputationGain)
		stats.DojoPrestige = math.max(0, (stats.DojoPrestige or 0) + prestigeGain)
		adjustDojoCondition(stats, -conditionLoss)

		fireLifeUpdate(player, stats, "<b>" .. tostring(eventState.Title) .. "</b> finished. Clan reputation <b>+" .. tostring(reputationGain) .. "</b>, dojo prestige <b>+" .. tostring(prestigeGain) .. "</b>, student progress <b>+" .. tostring(studentProgress) .. "</b>.")

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

		if effects.Strength then
			stats.Strength = math.max(0, (tonumber(stats.Strength) or 0) + effects.Strength)
		end

		if effects.Looks then
			stats.Looks = math.clamp((tonumber(stats.Looks) or 50) + effects.Looks, 0, 100)
		end

		if effects.CursedObjectAnchorProgress then
			stats.CursedObjectAnchorProgress = math.clamp((tonumber(stats.CursedObjectAnchorProgress) or 0) + effects.CursedObjectAnchorProgress, 0, 100)
		end

		if effects.CursedObjectAnchors then
			stats.CursedObjectAnchors = math.max(0, (tonumber(stats.CursedObjectAnchors) or 0) + effects.CursedObjectAnchors)
		end

		if effects.ReincarnationAnchor then
			stats.ReincarnationAnchor = tostring(effects.ReincarnationAnchor)
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

local function getOwnedAssetsPayload(stats)
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


local function getAssetsPayload(player)
	local stats = getStats(player)

	if not stats or not stats.Alive then
		return {
			Age = 0,
			Money = 0,
			ClanFounded = false,
			PlayerClanName = nil,
			ClanMembers = 0,
			ClanReputation = 0,
			ClanRankName = "Minor Dojo",
			ClanRankNextAt = 25,
			ClanReputationToNext = 25,
			ClanReputationBenefit = "Starter reputation. Recruit and train students to be noticed.",
			ClanReputationBonusStudents = 0,
			ClanCompetitiveScore = 0,
			ClanCompetitiveTier = "Local",
			ClanCompetitionRecord = "0W-0L",
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
			DojoApplicationPending = false,
			DojoApplication = nil,
			JoinedDojoName = nil,
			JoinedDojoFocus = nil,
			JoinedDojoRank = nil,
			JoinedDojoTrust = 0,
			JoinedDojoProgress = 0,
			JoinedDojoAssignments = 0,
			JoinedDojoSenseiName = nil,
			JoinedDojoSenseiGrade = nil,
			JoinedDojoSenseiAge = nil,
			JoinedDojoSenseiRelation = nil,
			JoinedDojoSenseiTrainingWindow = nil,
			JoinedDojoSenseiTrainingUsed = 0,
			JoinedDojoSenseiTrainingLimit = JOINED_DOJO_TRAIN_LIMIT,
			JoinedDojoTrainUsesLeft = JOINED_DOJO_TRAIN_LIMIT,
			JoinedDojoTrainLimit = JOINED_DOJO_TRAIN_LIMIT,
			JoinedDojoAssignmentWindow = nil,
			JoinedDojoAssignmentUsed = 0,
			JoinedDojoAssignmentUsesLeft = JOINED_DOJO_ASSIGNMENT_LIMIT,
			JoinedDojoAssignmentLimit = JOINED_DOJO_ASSIGNMENT_LIMIT,
			JoinedDojoSenseiAdviceWindow = nil,
			JoinedDojoSenseiAdviceUsed = 0,
			JoinedDojoSenseiUsesLeft = JOINED_DOJO_SENSEI_ADVICE_LIMIT,
			JoinedDojoSenseiLimit = JOINED_DOJO_SENSEI_ADVICE_LIMIT,
			RacePathLabel = "Civilian",
			HasVIP = false,
			VIPGamePassId = (getPassIds().VIP_SORCERER_PASS_ID or 0),
			Owned = {},
			Shop = {},
			CursedTools = {},
			CursedToolCatalog = {},
			EquippedCursedToolId = nil,
		} 
	end

	ensureExtraStats(stats)
	syncMonetizationEntitlements(player, stats)

	local hasGrandDojo = ownsAssetById(stats, "grand_dojo")
	local clanRepInfo = getClanReputationInfo(stats)
	local clanCompetitiveInfo = getClanCompetitiveInfo(stats)
	local dojoEventState = getDojoEventState(stats)
	local rivalChallengeState = getRivalChallengeState(stats)
	local joinedDojoTrainUsed = getJoinedDojoSenseiTrainCount(stats)
	local joinedDojoAssignmentUsed = getJoinedDojoAssignmentCount(stats)
	local joinedDojoSenseiAdviceUsed = getJoinedDojoSenseiAdviceCount(stats)

	return {
		Age = stats.Age or 0,
		CurrentMonth = stats.CurrentMonth or 1,
		MonthsIntoAge = stats.MonthsIntoAge or 0,
		CurrentYear = getCurrentYear(stats),
		Money = stats.Money or 0,
		FamilyBudgetTier = (stats.Age or 0) < 16 and ensureFamilyBudget(stats).Tier or stats.FamilyBudgetTier,
		FamilyAnnualBudget = (stats.Age or 0) < 16 and stats.FamilyAnnualBudget or nil,
		FamilyBudgetRemaining = (stats.Age or 0) < 16 and stats.FamilyBudgetRemaining or nil,
		ParentAssetRequestLimit = (stats.Age or 0) < 16 and PARENT_ASSET_REQUEST_LIMIT_PER_YEAR or nil,
		ParentAssetRequestsUsed = (stats.Age or 0) < 16 and select(1, ensureParentAssetRequestState(stats)) or nil,
		ParentAssetGiftLimit = (stats.Age or 0) < 16 and PARENT_ASSET_GIFT_LIMIT_PER_YEAR or nil,
		ParentAssetGiftsReceived = (stats.Age or 0) < 16 and select(2, ensureParentAssetRequestState(stats)) or nil,
		ClanFounded = stats.ClanFounded == true,
		PlayerClanName = stats.PlayerClanName,
		ClanMembers = stats.ClanMembers or 0,
		ClanReputation = stats.ClanReputation or 0,
		ClanRankName = clanRepInfo.RankName,
		ClanRankNextAt = clanRepInfo.NextAt,
		ClanReputationToNext = clanRepInfo.ToNext,
		ClanReputationBenefit = clanRepInfo.Benefit,
		ClanReputationBonusStudents = clanRepInfo.BonusStudents,
		ClanCompetitiveScore = clanCompetitiveInfo.Score,
		ClanCompetitiveTier = clanCompetitiveInfo.Tier,
		ClanCompetitionRecord = clanCompetitiveInfo.Record,
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
		DojoEventsHosted = stats.DojoEventsHosted or 0,
		LastDojoEventName = stats.LastDojoEventName,
		DojoEventAvailable = dojoEventState.Available == true and hasGrandDojo == true and stats.ClanFounded == true and countDojoStudentsAndWards(stats) > 0,
		DojoEventCooldownMonths = dojoEventState.CooldownMonths,
		DojoEventTitle = dojoEventState.Title,
		DojoEventDescription = dojoEventState.Desc,
		DojoEventButton = dojoEventState.Button,
		RivalDojoName = stats.RivalDojoName,
		RivalDojoFocus = stats.RivalDojoFocus,
		RivalDojoReputation = stats.RivalDojoReputation or 0,
		RivalDojoWins = stats.RivalDojoWins or 0,
		RivalDojoLosses = stats.RivalDojoLosses or 0,
		RivalChallengeAvailable = rivalChallengeState.Available == true and hasGrandDojo == true and stats.ClanFounded == true and countDojoStudentsAndWards(stats) > 0,
		RivalChallengeCooldownMonths = rivalChallengeState.CooldownMonths,
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
		DojoApplicationPending = stats.DojoApplicationPending == true,
		DojoApplication = stats.DojoApplication,
		DojoApplicationName = stats.DojoApplicationName,
		DojoApplicationFocus = stats.DojoApplicationFocus,
		DojoApplicationRank = stats.DojoApplicationRank,
		DojoApplicationChance = stats.DojoApplicationChance,
		DojoApplicationSubmittedAtTotalMonths = stats.DojoApplicationSubmittedAtTotalMonths,
		DojoApplicationDecisionAtTotalMonths = stats.DojoApplicationDecisionAtTotalMonths,
		DojoApplicationSenseiName = stats.DojoApplicationSenseiName,
		DojoApplicationSenseiAge = stats.DojoApplicationSenseiAge,
		DojoApplicationSenseiGrade = stats.DojoApplicationSenseiGrade,
		DojoApplicationSenseiRelation = stats.DojoApplicationSenseiRelation,
		JoinedDojoName = stats.JoinedDojoName,
		JoinedDojoFocus = stats.JoinedDojoFocus,
		JoinedDojoRank = stats.JoinedDojoRank,
		JoinedDojoTrust = stats.JoinedDojoTrust or 0,
		JoinedDojoProgress = stats.JoinedDojoProgress or 0,
		JoinedDojoAssignments = stats.JoinedDojoAssignments or 0,
		JoinedDojoJoinedAtAge = stats.JoinedDojoJoinedAtAge,
		JoinedDojoJoinedAtMonth = stats.JoinedDojoJoinedAtMonth,
		JoinedDojoSenseiName = stats.JoinedDojoSenseiName,
		JoinedDojoSenseiAge = stats.JoinedDojoSenseiAge,
		JoinedDojoSenseiGrade = stats.JoinedDojoSenseiGrade,
		JoinedDojoSenseiRelation = stats.JoinedDojoSenseiRelation,
		JoinedDojoSenseiTrainingWindow = stats.JoinedDojoSenseiTrainingWindow,
		JoinedDojoSenseiTrainingUsed = stats.JoinedDojoSenseiTrainingUsed or 0,
		JoinedDojoSenseiTrainingLimit = JOINED_DOJO_TRAIN_LIMIT,
		JoinedDojoTrainUsesLeft = math.max(0, JOINED_DOJO_TRAIN_LIMIT - joinedDojoTrainUsed),
		JoinedDojoTrainLimit = JOINED_DOJO_TRAIN_LIMIT,
		JoinedDojoAssignmentWindow = stats.JoinedDojoAssignmentWindow,
		JoinedDojoAssignmentUsed = stats.JoinedDojoAssignmentUsed or 0,
		JoinedDojoAssignmentUsesLeft = math.max(0, JOINED_DOJO_ASSIGNMENT_LIMIT - joinedDojoAssignmentUsed),
		JoinedDojoAssignmentLimit = JOINED_DOJO_ASSIGNMENT_LIMIT,
		JoinedDojoSenseiAdviceWindow = stats.JoinedDojoSenseiAdviceWindow,
		JoinedDojoSenseiAdviceUsed = stats.JoinedDojoSenseiAdviceUsed or 0,
		JoinedDojoSenseiUsesLeft = math.max(0, JOINED_DOJO_SENSEI_ADVICE_LIMIT - joinedDojoSenseiAdviceUsed),
		JoinedDojoSenseiLimit = JOINED_DOJO_SENSEI_ADVICE_LIMIT,
		RacePathLabel = getRacePathLabel(stats),
		HasVIP = ownsVIPSorcererPass(player),
		HasExtraSaveSlots = ownsExtraSaveSlotsPass(player),
		HasSaveSlotsAccess = ownsSaveSlotAccess(player),
		VIPGamePassId = (getPassIds().VIP_SORCERER_PASS_ID or 0),
		ExtraSaveSlotsGamePassId = (getPassIds().EXTRA_SAVE_SLOTS_PASS_ID or 0),
		DoubleMoneyGamePassId = (getPassIds().DOUBLE_MONEY_PASS_ID or 0),
		DoubleTrainingGamePassId = (getPassIds().DOUBLE_TRAINING_PASS_ID or 0),
		LuckyBirthGamePassId = (getPassIds().LUCKY_BIRTH_PASS_ID or 0),
		ExtraDojoStudentsGamePassId = (getPassIds().EXTRA_DOJO_STUDENTS_PASS_ID or 0),
		HasLuckyBirth = stats.HasLuckyBirthPass == true,
		HasExtraDojoStudents = stats.HasExtraDojoStudentsPass == true,
		Owned = getOwnedAssetsPayload(stats),
		Shop = BitKaisenAssets.GetShopList(stats),
		CursedTools = BitKaisenCursedTools.GetOwnedPayload(stats),
		CursedToolCatalog = BitKaisenCursedTools.GetCatalogPayload(stats),
		EquippedCursedToolId = stats.EquippedCursedToolId,
	}
end


BK_AssetService.ProcessAssetAction = processAssetAction
BK_AssetService.GetOwnedAssetsPayload = getOwnedAssetsPayload
BK_AssetService.GetAssetsPayload = getAssetsPayload

function BK_AssetService.Init(ctx)
	context = ctx or {}
	if context.IS_DEBUG then print("[BK_AssetService] Phase 4 asset handling loaded.") end
end

return BK_AssetService

