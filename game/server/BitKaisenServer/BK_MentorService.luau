-- ModuleScript: BK_MentorService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose: Jujutsu Mentor career path for graduated registered sorcerers.

local BK_MentorService = {}
local context = {}

local MENTOR_RANKS = {
	{ Id = "Assistant Instructor", MinXP = 0,   Income = 3500  },
	{ Id = "Instructor",           MinXP = 80,  Income = 5500  },
	{ Id = "Senior Instructor",    MinXP = 200, Income = 8000  },
	{ Id = "Master Instructor",    MinXP = 400, Income = 12000 },
}

local GRADE_ORDER = {
	["Special Grade"] = 7, ["Grade 1"] = 6, ["Semi-Grade 1"] = 5,
	["Grade 2"] = 4, ["Semi-Grade 2"] = 3, ["Grade 3"] = 2, ["Grade 4"] = 1,
}

local function getStats(player)
	return context.GetStats and context.GetStats(player) or nil
end

local function fireLifeUpdate(player, stats, message)
	if context.FireLifeUpdate then
		context.FireLifeUpdate(player, stats, message)
	end
end

local function fireMajorPopup(player, title, subtitle, highlight, footer)
	if context.FireMajorPopup then
		context.FireMajorPopup(player, title, subtitle, highlight, footer)
	end
end

local function saveStats(player, reason)
	if context.SaveStats then
		context.SaveStats(player, reason)
	end
end

local function adjustWorldReputation(stats, fameDelta, fearDelta, pathDelta)
	if context.AdjustWorldReputation then
		return context.AdjustWorldReputation(stats, fameDelta, fearDelta, pathDelta) or ""
	end
	return ""
end

local function getGradeValue(gradeText)
	gradeText = tostring(gradeText or "")
	local stripped = gradeText:gsub("^Unregistered ", ""):gsub("^Curse User ", "")
	return GRADE_ORDER[stripped] or 0
end

local function ensureMentorState(stats)
	stats.IsJujutsuMentor = stats.IsJujutsuMentor == true
	stats.MentorRank = tostring(stats.MentorRank or "None")
	stats.MentorXP = math.max(0, tonumber(stats.MentorXP) or 0)
	stats.MentorIncome = math.max(0, tonumber(stats.MentorIncome) or 0)
	stats.StudentsMentored = math.max(0, tonumber(stats.StudentsMentored) or 0)
	stats.MentorApplicationCooldown = math.max(0, tonumber(stats.MentorApplicationCooldown) or 0)
end

local function getRankInfo(rankName)
	for _, rank in ipairs(MENTOR_RANKS) do
		if rank.Id == rankName then
			return rank
		end
	end
	return MENTOR_RANKS[1]
end

local function getNextRank(currentRank)
	for i, rank in ipairs(MENTOR_RANKS) do
		if rank.Id == currentRank and MENTOR_RANKS[i + 1] then
			return MENTOR_RANKS[i + 1]
		end
	end
	return nil
end

function BK_MentorService.CanApply(stats)
	if not stats then return false, "No stats." end
	if stats.Alive == false then return false, "Not alive." end
	if stats.IsJujutsuMentor == true then return false, "Already a mentor." end
	if stats.GraduatedJujutsuHigh ~= true then return false, "Must be a Jujutsu High graduate." end
	if (tonumber(stats.Age) or 0) < 20 then return false, "Must be at least 20." end
	if getGradeValue(stats.Grade) < 4 then return false, "Must be at least Grade 2." end
	if (tonumber(stats.MentorApplicationCooldown) or 0) > 0 then return false, "Already applied this year." end
	return true, nil
end

function BK_MentorService.Apply(player)
	local stats = getStats(player)
	if not stats then return end
	ensureMentorState(stats)

	local canApply, reason = BK_MentorService.CanApply(stats)
	if not canApply then
		fireLifeUpdate(player, stats, reason or "Cannot apply to become a mentor right now.")
		return
	end

	stats.MentorApplicationCooldown = 1

	local recommendations = math.max(0, tonumber(stats.TeacherRecommendations) or 0)
	local missions = math.max(0, tonumber(stats.MissionsCompleted) or 0)
	local gradeBonus = getGradeValue(stats.Grade) * 8
	local smartsBonus = math.floor((tonumber(stats.Smarts) or 0) * 0.3)
	local repBonus = math.floor((tonumber(stats.Reputation) or 0) * 0.5)
	local recBonus = recommendations * 4

	local score = gradeBonus + smartsBonus + repBonus + recBonus + math.floor(missions * 0.5) + math.random(1, 30)
	local threshold = 55

	if score >= threshold then
		stats.IsJujutsuMentor = true
		stats.MentorRank = "Assistant Instructor"
		stats.MentorXP = 0
		stats.MentorIncome = MENTOR_RANKS[1].Income
		stats.SocietyStatus = "Jujutsu Mentor"
		stats.LifePath = "Jujutsu Mentor"
		stats.Reputation = (tonumber(stats.Reputation) or 0) + 8

		local msg = "You were accepted as a <b>Jujutsu Mentor</b> at the rank of <b>Assistant Instructor</b>." .. adjustWorldReputation(stats, 2, 0, 3)
		fireLifeUpdate(player, stats, msg)

		fireMajorPopup(
			player,
			"JUJUTSU MENTOR",
			"Jujutsu High has recognized your skill and offered you a teaching position.",
			"Assistant Instructor",
			"Teach, supervise, and guide the next generation of sorcerers."
		)
	else
		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - 5, 0, 100)
		fireLifeUpdate(player, stats, "Your application to become a Jujutsu Mentor was <b>rejected</b>. Your skills or reputation weren't convincing enough yet.")
	end

	saveStats(player, "Mentor application")
end

function BK_MentorService.AdvanceYear(player, stats)
	if not stats or stats.Alive == false or stats.IsJujutsuMentor ~= true then
		return ""
	end

	ensureMentorState(stats)
	stats.MentorApplicationCooldown = 0

	local rankInfo = getRankInfo(stats.MentorRank)
	local yearlyPay = rankInfo.Income
	local xpGain = math.random(15, 30) + math.floor((tonumber(stats.Smarts) or 0) * 0.1)

	stats.Money = math.max(0, (tonumber(stats.Money) or 0) + yearlyPay)
	stats.MentorXP = (tonumber(stats.MentorXP) or 0) + xpGain
	stats.MentorIncome = yearlyPay
	stats.Reputation = (tonumber(stats.Reputation) or 0) + math.random(1, 3)
	stats.Recommendations = math.max(0, (tonumber(stats.Recommendations) or 0) + math.random(0, 1))

	local notes = { "<font color='#5fa5ff'><b>[ MENTOR ]</b></font> You earned <b>$" .. tostring(yearlyPay) .. "</b> as a <b>" .. tostring(stats.MentorRank) .. "</b>." }

	local nextRank = getNextRank(stats.MentorRank)
	if nextRank and stats.MentorXP >= nextRank.MinXP then
		stats.MentorRank = nextRank.Id
		stats.MentorIncome = nextRank.Income
		stats.Reputation = (tonumber(stats.Reputation) or 0) + 5
		table.insert(notes, "Promoted to <b>" .. nextRank.Id .. "</b>!")

		if context.FireMajorPopup then
			fireMajorPopup(
				player,
				"MENTOR PROMOTION",
				"Your dedication to teaching has been recognized.",
				nextRank.Id,
				"Income: $" .. tostring(nextRank.Income) .. "/year"
			)
		end
	end

	if math.random(1, 100) <= 40 then
		stats.StudentsMentored = (tonumber(stats.StudentsMentored) or 0) + 1
		table.insert(notes, "A new student was assigned to your care.")
	end

	return table.concat(notes, " ")
end

function BK_MentorService.GetPayload(player)
	local stats = getStats(player)
	if not stats or stats.Alive == false then
		return { IsMentor = false, Message = "No active life." }
	end

	ensureMentorState(stats)
	local canApply, applyReason = BK_MentorService.CanApply(stats)

	return {
		IsMentor = stats.IsJujutsuMentor == true,
		MentorRank = stats.MentorRank,
		MentorXP = stats.MentorXP,
		MentorIncome = stats.MentorIncome,
		StudentsMentored = stats.StudentsMentored,
		CanApply = canApply,
		ApplyReason = applyReason,
		NextRank = getNextRank(stats.MentorRank),
		Ranks = MENTOR_RANKS,
	}
end

function BK_MentorService.Init(ctx)
	context = ctx or {}
	if ctx and ctx.IS_DEBUG then print("[BK_MentorService] Loaded.") end
end

return BK_MentorService
