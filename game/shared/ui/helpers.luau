local theme = require("@ui/theme")

local helpers = {}

function helpers.formatMoneyAmount(value: number): string
	value = math.floor((tonumber(value) or 0) * 100 + 0.5) / 100
	if value % 1 == 0 then
		return tostring(math.floor(value))
	end
	return string.format("%.2f", value)
end

function helpers.getLineageText(stats: { [string]: any }?): string
	if not stats then return "Lineage: Unknown" end
	local origin = tostring(stats.Origin or stats.Clan or "Unknown")
	local familyName = tostring(stats.FamilyName or "Unknown")
	local familyType = tostring(stats.FamilyType or "Unknown")

	if origin == "Cursed Womb" then return "Origin: Cursed Womb" end
	if origin == "Zenin Clan" or origin == "Kamo Clan" or origin == "Gojo Clan" then
		return "Lineage: " .. origin
	end
	if familyName ~= "Unknown" and familyName ~= "None" then
		return "Lineage: " .. familyName .. " Family (" .. familyType .. ")"
	end
	return "Lineage: Unknown Family"
end

local MONTH_NAMES = {
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December",
}

local ERA_START_YEARS = {
	["Modern Era"] = 2000,
	["Edo Era"] = 1603,
	["Heian Era"] = 794,
	["Collapse Era"] = 2018,
}

local ERA_TIMELINE = {
	{ Name = "Heian Era", StartYear = 794 },
	{ Name = "Edo Era", StartYear = 1603 },
	{ Name = "Modern Era", StartYear = 2000 },
	{ Name = "Collapse Era", StartYear = 2018 },
}

function helpers.getEraStartYear(stats: { [string]: any }?): number
	if not stats then return ERA_START_YEARS["Modern Era"] end
	local birthYear = tonumber(stats.BirthYear)
	if birthYear then return birthYear end
	local birthPath = type(stats.BirthPath) == "table" and stats.BirthPath or nil
	local era = tostring(stats.Era or (birthPath and birthPath.Era) or "Modern Era")
	return ERA_START_YEARS[era] or ERA_START_YEARS["Modern Era"]
end

function helpers.getCurrentYear(stats: { [string]: any }?): number
	return helpers.getEraStartYear(stats) + (tonumber(stats and stats.Age) or 0)
end

function helpers.getEraForYear(year: number): string
	local numericYear = tonumber(year) or ERA_START_YEARS["Modern Era"]
	local currentEra = "Modern Era"
	for _, eraData in ipairs(ERA_TIMELINE) do
		if numericYear >= eraData.StartYear then
			currentEra = eraData.Name
		else
			break
		end
	end
	return currentEra
end

function helpers.getCurrentEraDisplay(stats: { [string]: any }?): string
	if not stats then return "Modern Era" end
	return tostring(stats.CurrentEra or stats.Era or helpers.getEraForYear(helpers.getCurrentYear(stats)))
end

function helpers.getCurrentMonthName(stats: { [string]: any }?): string
	local monthIndex = math.clamp(tonumber(stats and stats.CurrentMonth) or 1, 1, 12)
	return MONTH_NAMES[monthIndex] or "January"
end

function helpers.getAgeDisplay(stats: { [string]: any }?): string
	local age = tonumber(stats and stats.Age) or 0
	if age >= 16 then
		return tostring(age) .. "y \u{2022} " .. helpers.getCurrentMonthName(stats)
	end
	return tostring(age)
end

function helpers.getLogTimeKey(stats: { [string]: any }?): string
	local age = tonumber(stats and stats.Age) or 0
	local month = tonumber(stats and stats.CurrentMonth) or 1
	return tostring(age) .. ":" .. tostring(month)
end

function helpers.getLogTimeLabel(stats: { [string]: any }?): string
	local age = tonumber(stats and stats.Age) or 0
	return "<font color='#7a2a2a'><b>[ Age " .. tostring(age) .. " \u{2022} " .. helpers.getCurrentMonthName(stats) .. " " .. tostring(helpers.getCurrentYear(stats)) .. " \u{2022} " .. helpers.getCurrentEraDisplay(stats) .. " ]</b></font>"
end

function helpers.isProfileCurseLife(stats: { [string]: any }?): boolean
	if not stats then return false end
	local race = tostring(stats.Race or "")
	local origin = tostring(stats.Origin or "")
	return stats.IsCurse == true or race == "Cursed Spirit" or race == "Curse" or origin == "Vengeful Spirit Rebirth" or origin == "Cursed Rebirth"
end

function helpers.getRoutePathText(stats: { [string]: any }?): string
	if not stats then return "Unknown" end
	local gradeText = tostring(stats.Grade or "")
	if helpers.isProfileCurseLife(stats) then return "Cursed Spirit" end
	if stats.IsCurseUser == true or stats.CurseUser == true or stats.Path == "Curse User" or stats.SorcererPath == "Curse User" or string.sub(gradeText, 1, 11) == "Curse User" then
		return "Curse User"
	end
	if stats.IsJujutsuMentor == true then return "Jujutsu Mentor" end
	if stats.InJujutsuHigh == true then return "Jujutsu High Sorcerer" end
	if stats.GraduatedJujutsuHigh == true or stats.RegisteredSorcerer == true then return "Registered Sorcerer" end
	if string.find(gradeText, "Unregistered", 1, true) then return "Unregistered Sorcerer" end
	if tonumber(stats.CursedEnergy or 0) > 0 or tostring(stats.Technique or "") ~= "" then return "Awakened Civilian" end
	return "Civilian"
end

function helpers.getDisplayedAlignment(stats: { [string]: any }?): string
	local valid = {
		["Infamous Evil"] = true, ["Evil"] = true, ["Shady"] = true,
		["Neutral"] = true, ["Respected"] = true, ["Honored"] = true,
	}
	local alignment = tostring((stats and stats.Alignment) or "")
	if valid[alignment] then return alignment end
	local reputation = tonumber(stats and stats.Reputation) or 0
	local morality = tonumber(stats and stats.Morality) or 0
	local score = reputation + morality
	if score <= -75 then return "Infamous Evil"
	elseif score <= -35 then return "Evil"
	elseif score <= -10 then return "Shady"
	elseif score < 20 then return "Neutral"
	elseif score < 60 then return "Respected"
	end
	return "Honored"
end

function helpers.getProfileProgressText(stats: { [string]: any }?): string?
	if not stats then return nil end
	local route = helpers.getRoutePathText(stats)
	if route == "Cursed Spirit" then
		local territory = tostring(stats.CurseTerritory or "Unknown Territory")
		local status = tostring(stats.SocietyStatus or "Unregistered Cursed Spirit")
		local hunger = math.max(0, tonumber(stats.CurseHunger) or 0)
		local attention = math.max(0, tonumber(stats.SocietyAttention) or tonumber(stats.ExorcismRisk) or 0)
		return "Haunt: " .. territory .. " | " .. status .. " | Hunger " .. tostring(hunger) .. "% | Attention " .. tostring(attention) .. "%"
	end
	if route == "Curse User" then
		local current = math.max(0, tonumber(stats.CurseUserProgress) or 0)
		local gradeValue = 1
		local grade = tostring(stats.Grade or "")
		if string.find(grade, "Special Grade", 1, true) then gradeValue = 8
		elseif string.find(grade, "Grade 1", 1, true) then gradeValue = 7
		elseif string.find(grade, "Semi-Grade 1", 1, true) then gradeValue = 6
		elseif string.find(grade, "Grade 2", 1, true) then gradeValue = 5
		elseif string.find(grade, "Semi-Grade 2", 1, true) then gradeValue = 4
		elseif string.find(grade, "Grade 3", 1, true) then gradeValue = 3
		elseif string.find(grade, "Semi-Grade 3", 1, true) then gradeValue = 2
		end
		local requirement = 120 + (gradeValue * 35)
		return "Underground Progress: " .. tostring(current) .. "/" .. tostring(requirement)
	end
	if route == "Unregistered Sorcerer" then
		local current = math.max(0, tonumber(stats.UnregisteredProgress) or 0)
		local grade = tostring(stats.Grade or "")
		local requirement = 50
		if string.find(grade, "Grade 4", 1, true) then requirement = 35
		elseif string.find(grade, "Semi-Grade 3", 1, true) then requirement = 45
		elseif string.find(grade, "Grade 3", 1, true) then requirement = 60
		elseif string.find(grade, "Semi-Grade 2", 1, true) then requirement = 80
		elseif string.find(grade, "Grade 2", 1, true) then requirement = 105
		elseif string.find(grade, "Semi-Grade 1", 1, true) then requirement = 135
		elseif string.find(grade, "Grade 1", 1, true) then requirement = 175
		end
		return "Unregistered Progress: " .. tostring(current) .. "/" .. tostring(requirement)
	end
	return nil
end

function helpers.getRouteColor(stats: { [string]: any }?): Color3
	local route = helpers.getRoutePathText(stats)
	if route == "Cursed Spirit" then return theme.Purple
	elseif route == "Curse User" then return theme.Red
	elseif route == "Jujutsu Mentor" then return Color3.fromRGB(55, 180, 220)
	elseif route == "Jujutsu High Sorcerer" then return Color3.fromRGB(95, 165, 255)
	elseif route == "Registered Sorcerer" then return Color3.fromRGB(95, 165, 255)
	elseif route == "Unregistered Sorcerer" then return Color3.fromRGB(180, 120, 255)
	elseif route == "Awakened Civilian" then return Color3.fromRGB(180, 180, 190)
	end
	return Color3.fromRGB(130, 130, 140)
end

function helpers.getAlignmentColor(alignment: string): Color3
	if alignment == "Evil" or alignment == "Infamous Evil" then return theme.Red
	elseif alignment == "Shady" then return theme.Orange
	end
	return theme.Green
end

function helpers.getSchoolDisplay(stats: { [string]: any }?): string
	if not stats then return "None" end
	if stats.InJujutsuHigh then return "Jujutsu High" end
	if stats.IsJujutsuMentor then return "Jujutsu Mentor (" .. tostring(stats.MentorRank or "None") .. ")" end
	if stats.GraduatedJujutsuHigh then return "JJH Graduate" end
	if stats.GraduatedSchool then return "Graduated" end
	local stage = tostring(stats.SchoolStage or "None")
	if stage ~= "None" and stage ~= "Graduated" then
		local perf = math.floor(tonumber(stats.SchoolPerformance) or 50)
		local grade = tostring(stats.ReportCardGrade or "N/A")
		return stage .. " School | " .. grade .. " (" .. tostring(perf) .. "%)"
	end
	return "None"
end

return helpers
