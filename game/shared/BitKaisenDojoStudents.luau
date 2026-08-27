-- ModuleScript: BitKaisenDojoStudents
-- Location: ReplicatedStorage
-- Purpose:
--   Single source of truth for dojo student grades, power and promotion.
--
--   Before this module the grade table, the power formula, the potential score and the
--   promotion rule were copy-pasted into BK_DojoService, BK_ActivityService and
--   BK_AssetService. BK_DojoService's copy only fed the UI ("Ready for Special Grade"),
--   while the copies that actually promoted lived elsewhere and rolled a dice, so a
--   student could sit at 253/189 with a full gold bar forever. Everything now goes
--   through TryPromote, and the display and the promotion read the same numbers.

local BitKaisenDojoStudents = {}

BitKaisenDojoStudents.GradeOrder = {
	"Non-Sorcerer",
	"Grade 4",
	"Semi-Grade 3",
	"Grade 3",
	"Semi-Grade 2",
	"Grade 2",
	"Semi-Grade 1",
	"Grade 1",
	"Special Grade",
}

local GRADE_INDEX = {}
for index, grade in ipairs(BitKaisenDojoStudents.GradeOrder) do
	GRADE_INDEX[grade] = index
end

-- Cursed energy a Non-Sorcerer student needs before they are recognised as Grade 4.
BitKaisenDojoStudents.NonSorcererCENeeded = 35

function BitKaisenDojoStudents.GetPotentialScore(student)
	local potential = tostring(student and student.DojoPotential or "Average")
	if potential == "Hidden" then return 6 end
	if potential == "Special" then return 6 end
	if potential == "Rare" then return 5 end
	if potential == "High" then return 4 end
	if potential == "Average" then return 3 end
	if potential == "Low" then return 2 end
	return 3
end

function BitKaisenDojoStudents.GetGradeIndex(grade)
	return GRADE_INDEX[tostring(grade or "Non-Sorcerer")] or 1
end

function BitKaisenDojoStudents.GetNextGrade(grade)
	local index = BitKaisenDojoStudents.GetGradeIndex(grade)
	return BitKaisenDojoStudents.GradeOrder[math.clamp(index + 1, 1, #BitKaisenDojoStudents.GradeOrder)]
end

function BitKaisenDojoStudents.GetPower(student)
	student = student or {}
	local gradePower = (BitKaisenDojoStudents.GetGradeIndex(student.Grade) - 1) * 20
	local ce = tonumber(student.CursedEnergy) or 0
	local mastery = tonumber(student.TechniqueMastery) or 0
	local potential = BitKaisenDojoStudents.GetPotentialScore(student) * 5
	local techniqueBonus = tostring(student.CursedTechnique or "None") ~= "None" and 18 or 0
	return gradePower + math.floor(ce * 0.55) + math.floor(mastery * 1.4) + potential + techniqueBonus
end

-- Progress the student needs at their current grade. Kept as a function so the UI and
-- the promotion can never drift apart again.
function BitKaisenDojoStudents.GetNeeded(grade)
	return 45 + (BitKaisenDojoStudents.GetGradeIndex(grade) * 18)
end

function BitKaisenDojoStudents.GetPromotionInfo(student)
	local grade = tostring(student and student.Grade or "Non-Sorcerer")
	local gradeIndex = BitKaisenDojoStudents.GetGradeIndex(grade)
	local progress = math.max(0, tonumber(student and student.DojoProgress) or 0)
	local power = BitKaisenDojoStudents.GetPower(student)

	if gradeIndex >= #BitKaisenDojoStudents.GradeOrder then
		return {
			NextGrade = "Max",
			Progress = progress,
			Needed = 0,
			Power = power,
			Ready = false,
			Text = "Peak grade reached",
		}
	end

	if grade == "Non-Sorcerer" then
		local needed = BitKaisenDojoStudents.NonSorcererCENeeded
		local ce = math.max(0, tonumber(student and student.CursedEnergy) or 0)
		return {
			NextGrade = "Grade 4",
			Progress = math.min(needed, ce),
			Needed = needed,
			Power = power,
			Ready = ce >= needed,
			Text = "Needs CE " .. tostring(needed) .. " for Grade 4",
		}
	end

	local needed = BitKaisenDojoStudents.GetNeeded(grade)
	return {
		NextGrade = BitKaisenDojoStudents.GetNextGrade(grade),
		Progress = progress,
		Needed = needed,
		Power = power,
		Ready = progress >= needed and power >= needed,
		Text = "Needs " .. tostring(needed) .. " progress and power",
	}
end

-- Promotes the student by exactly one grade when the promotion bar is genuinely full,
-- and does nothing otherwise. Deterministic on purpose: the card already tells the
-- player "Ready for <grade>", so a dice roll behind that label reads as a broken game.
-- Returns promoted:boolean, newGrade:string?
function BitKaisenDojoStudents.TryPromote(student)
	if type(student) ~= "table" then return false, nil end

	local info = BitKaisenDojoStudents.GetPromotionInfo(student)
	if not info.Ready then return false, nil end

	if tostring(student.Grade or "Non-Sorcerer") == "Non-Sorcerer" then
		student.Grade = "Grade 4"
		return true, student.Grade
	end

	student.Grade = BitKaisenDojoStudents.GetNextGrade(student.Grade)
	student.DojoProgress = math.max(0, math.floor((tonumber(student.DojoProgress) or 0) * 0.25))
	return true, student.Grade
end

-- Runs TryPromote over every living student/ward in a stats table. Used by the progress
-- sources that used to add DojoProgress and then never check anything (rival dojo
-- challenge, dojo events, assistant training).
-- Returns a list of "<name> reached <grade>" strings, ready to append to a log line.
function BitKaisenDojoStudents.PromoteReadyStudents(stats, roleFilter)
	local promoted = {}
	for _, relationship in ipairs(stats and stats.Relationships or {}) do
		local role = tostring(relationship and relationship.Role or "")
		-- Written out rather than the and/or idiom on purpose: with no roleFilter and a
		-- non-student role, `roleFilter == nil and <false>` is false, so the idiom falls
		-- through to calling roleFilter, which is nil. Any relationship that is not a
		-- Student or Ward - a parent, a friend, a rival - crashed the sweep.
		local matches
		if roleFilter == nil then
			matches = role == "Student" or role == "Ward"
		else
			matches = roleFilter(relationship) == true
		end
		if relationship and relationship.Alive ~= false and matches then
			local didPromote, newGrade = BitKaisenDojoStudents.TryPromote(relationship)
			if didPromote then
				table.insert(promoted, tostring(relationship.Name) .. " reached " .. tostring(newGrade))
			end
		end
	end
	return promoted
end

return BitKaisenDojoStudents
