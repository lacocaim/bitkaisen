--!strict
-- Unit tests for ReplicatedStorage.BitKaisenDojoStudents.
-- Pure Luau, no Roblox APIs, so it runs outside Studio:
--     zune run tests/dojo_students.test.luau
--
-- Covers the bug this module was written for: a Grade 1 student sitting at
-- 253/189 with a full gold bar that never ranked up.

local Dojo = require("../game/shared/BitKaisenDojoStudents")

local failures = 0
local checks = 0

local function check(name: string, condition: boolean, detail: string?)
	checks += 1
	if condition then
		print("  ok   " .. name)
	else
		failures += 1
		print("  FAIL " .. name .. (detail and ("  -> " .. detail) or ""))
	end
end

local function equals(name: string, actual: any, expected: any)
	check(name, actual == expected, "got " .. tostring(actual) .. ", expected " .. tostring(expected))
end

-- The student from the bug report, exactly as the card showed her.
local function mika()
	return {
		Name = "Mika Sakuraba",
		Role = "Student",
		Alive = true,
		Grade = "Grade 1",
		Age = 23,
		CursedEnergy = 130,
		TechniqueMastery = 40,
		CursedTechnique = "Hairpin Technique",
		DojoPotential = "Hidden",
		DojoProgress = 253,
	}
end

print("\nGRADE LADDER")
equals("Non-Sorcerer is index 1", Dojo.GetGradeIndex("Non-Sorcerer"), 1)
equals("Grade 1 is index 8", Dojo.GetGradeIndex("Grade 1"), 8)
equals("Special Grade is index 9", Dojo.GetGradeIndex("Special Grade"), 9)
equals("ladder has 9 grades", #Dojo.GradeOrder, 9)
equals("Grade 1 is followed by Special Grade", Dojo.GetNextGrade("Grade 1"), "Special Grade")
equals("Special Grade has no next grade", Dojo.GetNextGrade("Special Grade"), "Special Grade")
equals("an unknown grade falls back to index 1", Dojo.GetGradeIndex("Nonsense"), 1)
equals("a nil grade falls back to index 1", Dojo.GetGradeIndex(nil), 1)

print("\nREQUIREMENT MATCHES THE CARD IN THE BUG REPORT")
equals("Grade 1 needs 189", Dojo.GetNeeded("Grade 1"), 189)
equals("Grade 4 needs 81", Dojo.GetNeeded("Grade 4"), 81)

print("\nPOWER")
local power = Dojo.GetPower(mika())
check("Mika's power clears the 189 requirement", power >= 189, "power = " .. tostring(power))
check("power survives an empty table", Dojo.GetPower({}) >= 0)
check("power survives nil", Dojo.GetPower(nil) >= 0)
check(
	"a technique user out-powers an identical student without one",
	Dojo.GetPower(mika()) > Dojo.GetPower({
		Grade = "Grade 1", CursedEnergy = 130, TechniqueMastery = 40,
		CursedTechnique = "None", DojoPotential = "Hidden",
	})
)

print("\nTHE REPORTED BUG")
local info = Dojo.GetPromotionInfo(mika())
equals("the card reads Ready for Special Grade", info.NextGrade, "Special Grade")
equals("the card shows 253", info.Progress, 253)
equals("the card shows /189", info.Needed, 189)
equals("the card says Ready", info.Ready, true)

local student = mika()
local promoted, newGrade = Dojo.TryPromote(student)
equals("a full bar promotes", promoted, true)
equals("she reaches Special Grade", newGrade, "Special Grade")
equals("her grade actually changed", student.Grade, "Special Grade")
equals("progress resets to 25%", student.DojoProgress, 63)

print("\nPROMOTION IS DETERMINISTIC, NOT A DICE ROLL")
-- The old code rolled at most 78%. Twenty ready students must all promote.
local allPromoted = true
for _ = 1, 20 do
	local s = mika()
	if not Dojo.TryPromote(s) then allPromoted = false end
end
check("20 out of 20 ready students promoted", allPromoted)

print("\nA STUDENT WHO IS NOT READY DOES NOT MOVE")
local notEnoughProgress = mika()
notEnoughProgress.DojoProgress = 188
equals("188/189 is not ready", Dojo.GetPromotionInfo(notEnoughProgress).Ready, false)
equals("188/189 does not promote", Dojo.TryPromote(notEnoughProgress), false)
equals("the grade is untouched", notEnoughProgress.Grade, "Grade 1")
equals("the progress is untouched", notEnoughProgress.DojoProgress, 188)

local notEnoughPower = mika()
notEnoughPower.CursedEnergy = 0
notEnoughPower.TechniqueMastery = 0
notEnoughPower.CursedTechnique = "None"
notEnoughPower.DojoPotential = "Low"
equals("enough progress but not enough power is not ready", Dojo.GetPromotionInfo(notEnoughPower).Ready, false)
equals("and it does not promote", Dojo.TryPromote(notEnoughPower), false)

print("\nNON-SORCERER GATE IS CE, NOT PROGRESS")
local civilian = { Grade = "Non-Sorcerer", CursedEnergy = 34, DojoProgress = 9999, DojoPotential = "Average" }
local civInfo = Dojo.GetPromotionInfo(civilian)
equals("the bar reads out of 35", civInfo.Needed, 35)
equals("the bar is capped at 35, not 9999", civInfo.Progress, 34)
equals("CE 34 is not ready", civInfo.Ready, false)
equals("CE 34 does not promote", Dojo.TryPromote(civilian), false)

civilian.CursedEnergy = 35
equals("CE 35 promotes", Dojo.TryPromote(civilian), true)
equals("to Grade 4", civilian.Grade, "Grade 4")

print("\nPEAK GRADE")
local peak = mika()
peak.Grade = "Special Grade"
local peakInfo = Dojo.GetPromotionInfo(peak)
equals("Special Grade reports Max", peakInfo.NextGrade, "Max")
equals("Special Grade is never ready", peakInfo.Ready, false)
equals("Special Grade never promotes", Dojo.TryPromote(peak), false)
equals("and stays Special Grade", peak.Grade, "Special Grade")

print("\nONE GRADE PER CALL")
local chainer = mika()
chainer.DojoProgress = 99999
Dojo.TryPromote(chainer)
equals("a huge bar still only moves one grade", chainer.Grade, "Special Grade")

print("\nBAD INPUT")
equals("nil does not promote", Dojo.TryPromote(nil), false)
equals("a string does not promote", Dojo.TryPromote("not a student"), false)
equals("an empty table does not promote", Dojo.TryPromote({}), false)

print("\nSWEEPING A STATS TABLE")
local stats = {
	Relationships = {
		mika(),
		{ Name = "Ready Ward", Role = "Ward", Alive = true, Grade = "Grade 2",
		  CursedEnergy = 120, TechniqueMastery = 60, CursedTechnique = "Shadow",
		  DojoPotential = "Rare", DojoProgress = 500 },
		{ Name = "Dead Student", Role = "Student", Alive = false, Grade = "Grade 1",
		  CursedEnergy = 130, TechniqueMastery = 40, CursedTechnique = "Hairpin",
		  DojoPotential = "Hidden", DojoProgress = 253 },
		{ Name = "Rival", Role = "Rival", Alive = true, Grade = "Grade 1",
		  CursedEnergy = 130, TechniqueMastery = 40, CursedTechnique = "Hairpin",
		  DojoPotential = "Hidden", DojoProgress = 253 },
		{ Name = "Slacker", Role = "Student", Alive = true, Grade = "Grade 3",
		  CursedEnergy = 10, TechniqueMastery = 0, CursedTechnique = "None",
		  DojoPotential = "Low", DojoProgress = 4 },
	},
}
local names = Dojo.PromoteReadyStudents(stats)
equals("only the two ready living students/wards promoted", #names, 2)
check("the log line names the student and the grade", string.find(names[1], "Mika Sakuraba") ~= nil and string.find(names[1], "Special Grade") ~= nil, names[1])
equals("the dead student was skipped", stats.Relationships[3].Grade, "Grade 1")
equals("the rival was skipped", stats.Relationships[4].Grade, "Grade 1")
equals("the slacker was skipped", stats.Relationships[5].Grade, "Grade 3")

equals("a second sweep promotes nobody", #Dojo.PromoteReadyStudents(stats), 0)
equals("an empty stats table is safe", #Dojo.PromoteReadyStudents({}), 0)
equals("a nil stats table is safe", #Dojo.PromoteReadyStudents(nil), 0)

local childStats = {
	Relationships = {
		{ Name = "Kid", Role = "Child", Alive = true, Grade = "Grade 1",
		  CursedEnergy = 130, TechniqueMastery = 40, CursedTechnique = "Hairpin",
		  DojoPotential = "Hidden", DojoProgress = 253 },
	},
}
equals("the default filter skips children", #Dojo.PromoteReadyStudents(childStats), 0)
equals("a custom filter can include them", #Dojo.PromoteReadyStudents(childStats, function(r)
	return tostring(r and r.Role) == "Child"
end), 1)

print("\n" .. string.rep("-", 46))
if failures == 0 then
	print(tostring(checks) .. " checks, all passed")
else
	print(tostring(checks) .. " checks, " .. tostring(failures) .. " FAILED")
	error("dojo_students tests failed", 0)
end
