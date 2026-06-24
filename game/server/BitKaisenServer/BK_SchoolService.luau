-- ModuleScript: BK_SchoolService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose: Civilian school progression (Elementary / Middle / High), performance drift,
--          report-card generation, and graduation at age 16.

local BK_SchoolService = {}
local context = {}

local STAGE_BANDS = {
	{ Stage = "Elementary", MinAge = 6, MaxAge = 10 },
	{ Stage = "Middle",     MinAge = 11, MaxAge = 13 },
	{ Stage = "High",       MinAge = 14, MaxAge = 15 },
}

local GRADE_THRESHOLDS = {
	{ Min = 90, Letter = "A+" },
	{ Min = 80, Letter = "A"  },
	{ Min = 70, Letter = "B"  },
	{ Min = 60, Letter = "C"  },
	{ Min = 50, Letter = "D"  },
	{ Min = 0,  Letter = "F"  },
}

local CLUB_OPTIONS = {
	"None", "Kendo Club", "Science Club", "Art Club", "Athletics Club",
	"Cooking Club", "Drama Club", "Student Council", "Library Committee",
}

function BK_SchoolService.GetStageForAge(age: number): string
	age = tonumber(age) or 0
	for _, band in ipairs(STAGE_BANDS) do
		if age >= band.MinAge and age <= band.MaxAge then
			return band.Stage
		end
	end
	if age >= 16 then
		return "Graduated"
	end
	return "None"
end

function BK_SchoolService.ComputeLetterGrade(performance: number, attendance: number): string
	local combined = (performance * 0.7) + (attendance * 0.3)
	for _, entry in ipairs(GRADE_THRESHOLDS) do
		if combined >= entry.Min then
			return entry.Letter
		end
	end
	return "F"
end

function BK_SchoolService.YearlyDrift(stats)
	if not stats then return end
	local smarts = math.clamp(tonumber(stats.Smarts) or 50, 0, 100)

	local smartsBonus = (smarts - 50) * 0.15
	local perfDrift = math.random(-8, 5) + smartsBonus
	stats.SchoolPerformance = math.clamp((tonumber(stats.SchoolPerformance) or 50) + perfDrift, 0, 100)

	local attendDrift = math.random(-5, 2)
	stats.SchoolAttendance = math.clamp((tonumber(stats.SchoolAttendance) or 100) + attendDrift, 0, 100)

	stats.ReportCardGrade = BK_SchoolService.ComputeLetterGrade(stats.SchoolPerformance, stats.SchoolAttendance)
end

function BK_SchoolService.AdvanceSchoolYear(stats)
	if not stats then return "" end
	local age = tonumber(stats.Age) or 0

	if stats.GraduatedSchool == true then
		return ""
	end

	local newStage = BK_SchoolService.GetStageForAge(age)
	local oldStage = tostring(stats.SchoolStage or "None")
	local log = ""

	if newStage == "None" then
		stats.SchoolStage = "None"
		return ""
	end

	if newStage == "Graduated" then
		return ""
	end

	if oldStage == "None" and newStage == "Elementary" then
		stats.SchoolStage = "Elementary"
		stats.SchoolPerformance = math.clamp(50 + math.random(-10, 10) + ((tonumber(stats.Smarts) or 50) - 50) * 0.2, 0, 100)
		stats.SchoolAttendance = math.clamp(90 + math.random(-5, 5), 0, 100)
		log = log .. "Started elementary school. "
	elseif newStage ~= oldStage then
		stats.SchoolStage = newStage
		log = log .. "Advanced to " .. string.lower(newStage) .. " school. "
	end

	BK_SchoolService.YearlyDrift(stats)
	stats.ReportCardGrade = BK_SchoolService.ComputeLetterGrade(stats.SchoolPerformance, stats.SchoolAttendance)
	return log
end

function BK_SchoolService.BuildReportCard(stats)
	local perf = math.floor(tonumber(stats.SchoolPerformance) or 50)
	local attend = math.floor(tonumber(stats.SchoolAttendance) or 100)
	local letter = BK_SchoolService.ComputeLetterGrade(perf, attend)
	local club = tostring(stats.SchoolClub or "None")

	return {
		Performance = perf,
		Attendance = attend,
		Grade = letter,
		Club = club,
		Stage = tostring(stats.SchoolStage or "Unknown"),
	}
end

function BK_SchoolService.Graduate(stats)
	if not stats then return "" end
	stats.GraduatedSchool = true
	stats.SchoolStage = "Graduated"

	local reportCard = BK_SchoolService.BuildReportCard(stats)
	stats.ReportCardGrade = reportCard.Grade

	local log = "Graduated from high school with a " .. reportCard.Grade .. " average. "

	local perf = reportCard.Performance
	if perf >= 85 then
		local bonus = math.random(3, 6)
		stats.Smarts = math.clamp((tonumber(stats.Smarts) or 50) + bonus, 0, 100)
		stats.Reputation = (tonumber(stats.Reputation) or 0) + 5
		log = log .. "Honor student! (+Smarts, +Reputation) "
	elseif perf >= 70 then
		local bonus = math.random(1, 3)
		stats.Smarts = math.clamp((tonumber(stats.Smarts) or 50) + bonus, 0, 100)
		log = log .. "Solid academic record. (+Smarts) "
	elseif perf < 40 then
		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - math.random(3, 8), 0, 100)
		log = log .. "Barely passed. (-Happiness) "
	end

	return log, reportCard
end

function BK_SchoolService.GetClubOptions()
	return CLUB_OPTIONS
end

function BK_SchoolService.JoinClub(stats, clubName)
	if not stats then return "" end
	local valid = false
	for _, c in ipairs(CLUB_OPTIONS) do
		if c == clubName then
			valid = true
			break
		end
	end
	if not valid then return "Invalid club." end
	stats.SchoolClub = clubName
	if clubName == "None" then
		return "Left school club."
	end
	return "Joined " .. clubName .. "."
end

function BK_SchoolService.Init(ctx)
	context = ctx
	if ctx and ctx.IS_DEBUG then print("[BK_SchoolService] Loaded.") end
end

return BK_SchoolService
