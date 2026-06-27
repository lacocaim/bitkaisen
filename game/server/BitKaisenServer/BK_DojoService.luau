-- ModuleScript: BK_DojoService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose:
--   Phase 3 GameManager split.
--   Owns dojo / clan student helper logic that used to live directly inside GameManager.
--   This module is intentionally data-safe: it only mutates the stats table it is given.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BitKaisenStats = require(ReplicatedStorage:WaitForChild("BitKaisenStats"))
local BitKaisenRelationships = require(ReplicatedStorage:WaitForChild("BitKaisenRelationships"))

local BK_DojoService = {}
local context = {}

local function ensureExtraStats(stats)
	if context.EnsureExtraStats then
		return context.EnsureExtraStats(stats)
	end
end

local function pickRandom(list)
	if context.PickRandom then
		return context.PickRandom(list)
	end
	return list[math.random(1, #list)]
end

local function ownsAssetById(stats, assetId)
	ensureExtraStats(stats)

	for _, asset in ipairs(stats.Assets) do
		if asset.Id == assetId then
			return true, asset
		end
	end

	return false, nil
end

local function countClanStudents(stats)
	ensureExtraStats(stats)

	local count = 0
	for _, relationship in ipairs(stats.Relationships or {}) do
		if relationship.Alive ~= false and relationship.Role == "Student" then
			count += 1
		end
	end

	return count
end

local function countDojoStudentsAndWards(stats)
	ensureExtraStats(stats)

	local count = 0
	for _, relationship in ipairs(stats.Relationships or {}) do
		if relationship.Alive ~= false and (relationship.Role == "Student" or relationship.Role == "Ward" or relationship.DojoStudent == true) then
			count += 1
		end
	end

	return count
end

local function getDojoStudentCapacity(stats)
	ensureExtraStats(stats)
	local level = math.clamp(tonumber(stats.DojoLevel) or 1, 1, 5)
	local baseCapacity = 3 + ((level - 1) * 2)
	local reputationBonus = math.clamp(math.floor((stats.ClanReputation or 0) / 35), 0, 4)
	local passBonus = stats.HasExtraDojoStudentsPass == true and 3 or 0
	local expansionBonus = stats.HasDojoExpansionPass == true and 2 or 0
	return baseCapacity + reputationBonus + passBonus + expansionBonus
end

local function getDojoUpgradeCost(stats)
	ensureExtraStats(stats)
	local level = math.clamp(tonumber(stats.DojoLevel) or 1, 1, 5)
	local costs = {
		[1] = 15000,
		[2] = 35000,
		[3] = 75000,
		[4] = 150000,
	}

	return costs[level]
end

local function getDojoMaintainCost(stats)
	ensureExtraStats(stats)
	local missingCondition = 100 - (stats.DojoCondition or 100)
	local level = math.clamp(tonumber(stats.DojoLevel) or 1, 1, 5)
	return math.max(500, math.floor(missingCondition * 75 * level))
end

local function getDojoFocusLabel(stats)
	ensureExtraStats(stats)
	return tostring(stats.DojoFocus or "Balanced")
end

local function adjustDojoCondition(stats, amount)
	ensureExtraStats(stats)
	stats.DojoCondition = math.clamp((stats.DojoCondition or 100) + amount, 0, 100)
end

local JAPAN_STUDENT_LOCATIONS = {
	"Tokyo, Japan", "Kyoto, Japan", "Osaka, Japan", "Yokohama, Japan", "Nagoya, Japan", "Sapporo, Japan",
	"Fukuoka, Japan", "Kobe, Japan", "Nara, Japan", "Sendai, Japan", "Hiroshima, Japan", "Kawasaki, Japan"
}

local FOREIGN_STUDENT_LOCATIONS = {
	"Seoul, South Korea", "Busan, South Korea", "Beijing, China", "Shanghai, China", "Taipei, Taiwan",
	"Manila, Philippines", "New York, United States", "Los Angeles, United States", "London, United Kingdom",
	"Paris, France", "São Paulo, Brazil", "Mexico City, Mexico"
}

local PREVIOUS_SCHOOLS = {
	"Tokyo Jujutsu Technical School",
	"Kyoto Jujutsu Technical School",
	"Sendai Cursed Arts Prep",
	"Osaka Barrier Studies Program",
	"Yokohama Spiritual Safety Academy",
	"Private Sorcerer Tutoring",
	"Civilian Middle School",
	"Foreign Exchange Sorcery Program",
	"No Formal Jujutsu School"
}

local STUDENT_BACKGROUNDS = {
	"A disciplined student who wants structure more than praise.",
	"A talented but cautious sorcerer who does not trust new clans quickly.",
	"A quiet recruit with unstable cursed energy and strong survival instincts.",
	"A former school prospect who left after a curse incident went badly.",
	"A foreign student trying to find a clan that will actually train them.",
	"A sharp learner with good instincts but weak emotional control.",
	"A stubborn candidate who only respects results.",
	"A calm student with a strong sense of duty and a complicated family record.",
	"A low-profile recruit with more potential than their grade suggests.",
	"A student who has bounced between mentors and wants a permanent place."
}

local MALE_RECRUIT_NAMES = { "Kazuto", "Ren", "Akio", "Haruto", "Kaito", "Riku", "Daichi", "Yuto", "Seiji", "Naoto", "Kenshi", "Toma" }
local FEMALE_RECRUIT_NAMES = { "Aoi", "Yuna", "Hana", "Mei", "Rina", "Saki", "Mika", "Reina", "Akari", "Shiori", "Kanna", "Aya" }
local RECRUIT_FAMILY_NAMES = { "Kumiwado", "Mizukara", "Amahara", "Tsukigane", "Kurogiri", "Hoshinari", "Yamashiro", "Shinkawa", "Morikage", "Fushidori", "Kazehara", "Sakuraba", "Kurosawa", "Tachibana" }

local function normalizeClanName(rawName, fallbackFamilyName)
	local text = tostring(rawName or "")
	text = text:gsub("<", ""):gsub(">", "")
	text = text:gsub("[^%w%s%-']", "")
	text = text:gsub("^%s+", ""):gsub("%s+$", "")
	text = text:gsub("%s+", " ")

	if text == "" then
		text = tostring(fallbackFamilyName or "Unnamed")
	end

	local baseName = text:gsub("%s+[Cc][Ll][Aa][Nn]$", "")
	baseName = baseName:gsub("^%s+", ""):gsub("%s+$", "")

	if baseName == "" then
		baseName = tostring(fallbackFamilyName or "Unnamed")
	end

	return baseName .. " Clan", baseName
end

local RECRUIT_POTENTIAL_SCORE = {
	Low = 10,
	Average = 20,
	High = 32,
	Rare = 42,
	Hidden = 46,
	Special = 50,
}

local RECRUIT_GRADE_SCORE = {
	["Non-Sorcerer"] = 4,
	["Grade 4"] = 10,
	["Semi-Grade 3"] = 16,
	["Grade 3"] = 22,
	["Semi-Grade 2"] = 30,
	["Grade 2"] = 36,
	["Semi-Grade 1"] = 44,
	["Grade 1"] = 52,
	["Special Grade"] = 62,
}

local function getRecruitEvaluation(candidate)
	local potential = tostring(candidate.DojoPotential or "Average")
	local grade = tostring(candidate.Grade or "Non-Sorcerer")
	local ce = tonumber(candidate.CursedEnergy) or 0
	local mastery = tonumber(candidate.TechniqueMastery) or 0
	local age = tonumber(candidate.Age) or 18
	local hasTechnique = tostring(candidate.CursedTechnique or "None") ~= "None"

	local score = (RECRUIT_POTENTIAL_SCORE[potential] or 20) + (RECRUIT_GRADE_SCORE[grade] or 4)
	score += math.clamp(math.floor(ce / 5), 0, 26)
	score += math.clamp(math.floor(mastery / 3), 0, 10)
	if hasTechnique then score += 8 end
	if age <= 15 then score += 6 elseif age <= 18 then score += 3 elseif age >= 22 then score -= 4 end
	score = math.clamp(score, 1, 100)

	local tier = "Steady"
	local label = "Steady Fit"
	local note = "Reliable candidate."
	if score >= 82 then
		tier = "Elite"
		label = "Elite Fit"
		note = "Rare ceiling."
	elseif score >= 64 then
		tier = "Strong"
		label = "Strong Fit"
		note = "Clear growth value."
	elseif score < 42 then
		tier = "Risky"
		label = "Risky Fit"
		note = "Needs fundamentals."
	end

	if potential == "Hidden" or potential == "Special" then
		note = "High ceiling."
	elseif not hasTechnique and ce >= 70 then
		note = "Strong CE, no CT yet."
	elseif grade == "Non-Sorcerer" then
		note = "Long-term project."
	end

	return score, tier, label, note
end

local function makeRecruitCandidate(stats, index)
	ensureExtraStats(stats)

	local gender = math.random(1, 2) == 1 and "Male" or "Female"
	local firstName = gender == "Female" and pickRandom(FEMALE_RECRUIT_NAMES) or pickRandom(MALE_RECRUIT_NAMES)
	local familyName = pickRandom(RECRUIT_FAMILY_NAMES)
	local age = math.random(13, 22)
	local grade = pickRandom({ "Non-Sorcerer", "Grade 4", "Grade 4", "Semi-Grade 3", "Grade 3", "Grade 3", "Semi-Grade 2", "Grade 2", "Grade 2", "Semi-Grade 1", "Grade 1" })
	local foreign = math.random(1, 100) <= 15
	local location = foreign and pickRandom(FOREIGN_STUDENT_LOCATIONS) or pickRandom(JAPAN_STUDENT_LOCATIONS)
	local school = foreign and "Foreign Exchange Sorcery Program" or pickRandom(PREVIOUS_SCHOOLS)
	local fatherStatus = pickRandom({ "Alive", "Alive", "Unknown", "Deceased" })
	local motherStatus = pickRandom({ "Alive", "Alive", "Unknown", "Deceased" })
	local potential = pickRandom({ "Low", "Average", "Average", "Average", "High", "High", "Rare", "Hidden", "Special" })
	local techniqueChance = grade == "Grade 1" and 86 or (grade == "Semi-Grade 1" and 76 or (grade == "Grade 2" and 62 or 44))
	local technique = math.random(1, 100) <= techniqueChance and BitKaisenStats.RollTechnique(stats.Origin or stats.Clan or "Minor Sorcerer Family") or "None"
	local ce = math.random(18, 90)

	if grade == "Grade 2" then
		ce = math.random(85, 150)
	elseif grade == "Semi-Grade 2" then
		ce = math.random(65, 115)
	elseif grade == "Grade 3" then
		ce = math.random(45, 95)
	elseif grade == "Semi-Grade 3" then
		ce = math.random(30, 70)
	elseif grade == "Grade 4" then
		ce = math.random(18, 55)
	end

	local background = pickRandom(STUDENT_BACKGROUNDS)
	local candidateDraft = {
		Age = age,
		Grade = grade,
		CursedEnergy = ce,
		CursedTechnique = technique,
		DojoPotential = potential,
		TechniqueMastery = technique ~= "None" and math.random(3, 28) or 0,
	}
	local recruitScore, recruitTier, recruitLabel, recruitNote = getRecruitEvaluation(candidateDraft)

	return {
		Id = "candidate_" .. tostring(os.time()) .. "_" .. tostring(index) .. "_" .. tostring(math.random(1000, 9999)),
		Name = firstName .. " " .. familyName,
		FirstName = firstName,
		FamilyName = familyName,
		Gender = gender,
		Age = age,
		Grade = grade,
		CursedEnergy = ce,
		CursedTechnique = technique,
		OriginLocation = location,
		PreviousSchool = school,
		FatherStatus = fatherStatus,
		MotherStatus = motherStatus,
		Personality = pickRandom({
			"Disciplined but hard to reach.",
			"Quiet, watchful, and slow to trust.",
			"Confident, direct, and competitive.",
			"Polite, but hiding a lot of pressure.",
			"Raw talent with poor control.",
			"Careful, analytical, and serious about training."
		}),
		Background = background,
		DojoPotential = potential,
		TechniqueMastery = candidateDraft.TechniqueMastery,
		RecruitFitScore = recruitScore,
		RecruitFitTier = recruitTier,
		RecruitFitLabel = recruitLabel,
		RecruitFitNote = recruitNote,
		DojoProgress = math.random(0, 20),
		GrowthStyle = pickRandom({
			"Fast learner",
			"Needs discipline",
			"Combat instinct",
			"Theory minded",
			"Slow burn",
			"Pressure awakens them"
		}),
		QuestionAnswers = {
			WhyJoin = "I want a place that actually trains me instead of treating me like a number.",
			OldSchool = school == "No Formal Jujutsu School" and "I did not have a real school. I learned from scraps, rumors, and surviving." or ("I came from " .. school .. ", but I need a different path."),
			Goal = "I want to become strong enough that nobody can decide my future for me."
		}
	}
end

local function generateDojoRecruitPool(stats)
	ensureExtraStats(stats)
	stats.DojoRecruitPool = {}

	local poolSize = if stats.HasDojoExpansionPass == true then 15 else 10
	for index = 1, poolSize do
		table.insert(stats.DojoRecruitPool, makeRecruitCandidate(stats, index))
	end
end

local function findRecruitCandidate(stats, candidateId)
	ensureExtraStats(stats)

	for index, candidate in ipairs(stats.DojoRecruitPool or {}) do
		if candidate.Id == candidateId then
			return candidate, index
		end
	end

	return nil, nil
end

local function removeRecruitCandidate(stats, candidateId)
	local _, index = findRecruitCandidate(stats, candidateId)

	if index then
		table.remove(stats.DojoRecruitPool, index)
	end
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
	"Special Grade",
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

local function getStudentPromotionInfo(student)
	local grade = tostring(student and student.Grade or "Non-Sorcerer")
	local gradeIndex = getStudentGradeIndex(grade)
	local progress = math.max(0, tonumber(student and student.DojoProgress) or 0)
	local power = getStudentPower(student or {})

	if gradeIndex >= #STUDENT_GRADE_ORDER then
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
		local needed = 35
		local ce = math.max(0, tonumber(student and student.CursedEnergy) or 0)
		return {
			NextGrade = "Grade 4",
			Progress = math.min(needed, ce),
			Needed = needed,
			Power = power,
			Ready = ce >= needed,
			Text = "Needs CE 35 for Grade 4",
		}
	end

	local needed = 45 + (gradeIndex * 18)
	return {
		NextGrade = getNextStudentGrade(grade),
		Progress = progress,
		Needed = needed,
		Power = power,
		Ready = progress >= needed and power >= needed,
		Text = "Needs " .. tostring(needed) .. " progress and power",
	}
end

local function getDojoStudentsForPayload(stats)
	ensureExtraStats(stats)
	local list = {}

	for _, relationship in ipairs(stats.Relationships or {}) do
		if relationship.Alive ~= false and (relationship.Role == "Student" or relationship.Role == "Ward" or relationship.DojoStudent == true) then
			local promotion = getStudentPromotionInfo(relationship)
			table.insert(list, {
				Id = relationship.Id,
				Name = relationship.Name,
				Role = relationship.Role,
				Gender = relationship.Gender or "Unknown",
				Age = relationship.Age or 0,
				Grade = relationship.Grade or "Non-Sorcerer",
				CursedEnergy = relationship.CursedEnergy or 0,
				CursedTechnique = relationship.CursedTechnique or "None",
				DojoPotential = relationship.DojoPotential or "Unknown",
				TechniqueMastery = relationship.TechniqueMastery or 0,
				DojoProgress = relationship.DojoProgress or 0,
				DojoPower = promotion.Power,
				NextGrade = promotion.NextGrade,
				PromotionProgress = promotion.Progress,
				PromotionNeeded = promotion.Needed,
				PromotionReady = promotion.Ready,
				PromotionText = promotion.Text,
				GrowthStyle = relationship.GrowthStyle or "Unknown",
				OriginLocation = relationship.OriginLocation or "Unknown",
				PreviousSchool = relationship.PreviousSchool or "Unknown",
				Background = relationship.Background or "No record yet.",
			})
		end
	end

	return list
end

local function recruitCandidateIntoDojo(stats, candidate)
	ensureExtraStats(stats)

	if countDojoStudentsAndWards(stats) >= getDojoStudentCapacity(stats) then
		return nil
	end

	local student = BitKaisenRelationships.CreateRelationship(
		"Student",
		candidate.Name,
		"Clan Student",
		math.random(30, 55),
		math.random(20, 50),
		math.random(25, 65),
		0,
		0,
		candidate.Gender
	)

	student.FirstName = candidate.FirstName
	student.FamilyName = candidate.FamilyName
	student.Gender = candidate.Gender
	student.Age = candidate.Age
	student.Grade = candidate.Grade
	student.CursedEnergy = candidate.CursedEnergy
	student.CursedTechnique = candidate.CursedTechnique
	student.Personality = candidate.Personality
	student.Background = candidate.Background
	student.DojoPotential = candidate.DojoPotential
	student.TechniqueMastery = candidate.TechniqueMastery or 0
	student.DojoProgress = candidate.DojoProgress or 0
	student.GrowthStyle = candidate.GrowthStyle or "Unknown"
	student.OriginLocation = candidate.OriginLocation
	student.PreviousSchool = candidate.PreviousSchool
	student.FatherStatus = candidate.FatherStatus
	student.MotherStatus = candidate.MotherStatus
	student.Romance = 0
	student.IsClanStudent = true
	student.JoinedFromRecruitPool = true

	return BitKaisenRelationships.AddRelationship(stats, student)
end

local function createClanStudent(stats)
	ensureExtraStats(stats)

	if countDojoStudentsAndWards(stats) >= getDojoStudentCapacity(stats) then
		return nil
	end

	local student = BitKaisenRelationships.CreateRelationship(
		"Student",
		nil,
		"Clan Student",
		math.random(35, 65),
		math.random(25, 55),
		math.random(30, 70),
		0,
		0
	)

	student.Gender = math.random(1, 2) == 1 and "Male" or "Female"
	student.Age = math.random(13, 24)
	student.Grade = pickRandom({ "Non-Sorcerer", "Grade 4", "Grade 4", "Semi-Grade 3", "Grade 3", "Semi-Grade 2", "Grade 2" })
	student.CursedEnergy = math.random(12, 75)
	student.CursedTechnique = math.random(1, 100) <= 35 and BitKaisenStats.RollTechnique(stats.Origin or stats.Clan or "Minor Sorcerer Family") or "None"
	student.Personality = student.Personality or "Eager to prove themselves under your clan."
	student.Background = "They joined the " .. tostring(stats.PlayerClanName or "clan") .. " to train at your Grand Dojo and grow as a sorcerer."
	student.Romance = 0
	student.IsClanStudent = true
	student.DojoPotential = student.DojoPotential or pickRandom({ "Low", "Average", "Average", "High", "Rare", "Hidden" })
	student.TechniqueMastery = student.CursedTechnique ~= "None" and math.random(0, 16) or 0
	student.DojoProgress = math.random(0, 12)
	student.GrowthStyle = pickRandom({ "Fast learner", "Needs discipline", "Combat instinct", "Theory minded", "Slow burn" })
	student.Background = student.Background or ("They joined the " .. tostring(stats.PlayerClanName or "clan") .. " to train at your Grand Dojo and grow as a sorcerer.")

	return BitKaisenRelationships.AddRelationship(stats, student)
end

local function createRescuedWard(stats, sourceText)
	ensureExtraStats(stats)

	local gender = math.random(1, 2) == 1 and "Male" or "Female"
	local ward = BitKaisenRelationships.CreateRelationship(
		"Ward",
		nil,
		"Rescued Ward",
		math.random(28, 48),
		math.random(18, 42),
		math.random(6, 20),
		math.random(0, 8),
		0,
		gender
	)

	ward.Age = math.random(1, 5)
	ward.Grade = "Non-Sorcerer"
	ward.CursedEnergy = math.random(2, 28)
	ward.CursedTechnique = "None"
	ward.Personality = pickRandom({
		"Quiet and cautious around strangers",
		"Easily startled but naturally observant",
		"Small, stubborn, and strangely fearless",
		"Clings to routine after surviving something awful",
		"Soft-spoken, but their cursed energy reacts strongly under stress"
	})
	ward.Background = sourceText or "You found them during a curse incident and became responsible for their future."
	ward.Romance = 0
	ward.IsWard = true
	ward.CanInheritTechnique = true
	ward.DojoPotential = pickRandom({ "Hidden", "Hidden", "Average", "High", "Rare" })
	ward.RescueAge = stats.Age or 0

	stats.WardsRescued = (stats.WardsRescued or 0) + 1
	stats.ClanMembers = math.max(stats.ClanMembers or 0, countDojoStudentsAndWards(stats) + 1)

	return BitKaisenRelationships.AddRelationship(stats, ward)
end

local function getOrphanRescueChance(stats, missionData)
	ensureExtraStats(stats)

	local chance = tonumber(missionData.OrphanRescueChance) or 0

	if chance <= 0 then
		local grade = tostring(missionData.Grade or "")
		if grade == "Grade 4" then
			chance = 3
		elseif grade == "Semi-Grade 3" or grade == "Grade 3" then
			chance = 5
		elseif grade == "Semi-Grade 2" or grade == "Grade 2" then
			chance = 7
		else
			chance = 4
		end
	end

	if stats.ClanFounded then
		chance += 3
	end

	if ownsAssetById(stats, "grand_dojo") then
		chance += 2
	end

	if (stats.Reputation or 0) >= 50 then
		chance += 2
	end

	return math.clamp(chance, 0, 14)
end


BK_DojoService.OwnsAssetById = ownsAssetById
BK_DojoService.CountClanStudents = countClanStudents
BK_DojoService.CountDojoStudentsAndWards = countDojoStudentsAndWards
BK_DojoService.GetDojoStudentCapacity = getDojoStudentCapacity
BK_DojoService.GetDojoUpgradeCost = getDojoUpgradeCost
BK_DojoService.GetDojoMaintainCost = getDojoMaintainCost
BK_DojoService.GetDojoFocusLabel = getDojoFocusLabel
BK_DojoService.AdjustDojoCondition = adjustDojoCondition
BK_DojoService.NormalizeClanName = normalizeClanName
BK_DojoService.MakeRecruitCandidate = makeRecruitCandidate
BK_DojoService.GenerateDojoRecruitPool = generateDojoRecruitPool
BK_DojoService.FindRecruitCandidate = findRecruitCandidate
BK_DojoService.RemoveRecruitCandidate = removeRecruitCandidate
BK_DojoService.GetDojoStudentsForPayload = getDojoStudentsForPayload
BK_DojoService.RecruitCandidateIntoDojo = recruitCandidateIntoDojo
BK_DojoService.CreateClanStudent = createClanStudent
BK_DojoService.CreateRescuedWard = createRescuedWard
BK_DojoService.GetOrphanRescueChance = getOrphanRescueChance

function BK_DojoService.Init(ctx)
	context = ctx or {}
	if context.IS_DEBUG then print("[BK_DojoService] Loaded Phase 3 dojo helpers.") end
end

return BK_DojoService
