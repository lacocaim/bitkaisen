-- ModuleScript: BitKaisenLegacy
-- Location: ReplicatedStorage
-- Purpose:
-- Handles successor inheritance when a player dies and chooses to play as their child.
--
-- Update:
--   Heir data is now deterministic.
--   Choosing a successor uses the child's already-saved CE, CT, mastery, grade, gender, traits,
--   and relationship profile instead of rerolling passdown at death.
--
-- The child inherits:
--   - Family name
--   - The child's already-rolled cursed technique / innate technique
--   - The child's already-rolled cursed energy
--   - The child's already-rolled traits
--   - Assets the parent owned
--   - Clan membership and founder lineage if the parent founded one
--   - Money inheritance
--   - Reputation echo
-- The dead parent appears in the new life's Relationships as "Late Mother" or "Late Father"
-- with the parent's final profile preserved as a memory.

local BitKaisenLegacy = {}

local INHERIT_MONEY_PERCENT = 0.4
local INHERIT_REPUTATION_PERCENT = 0.15
local INHERIT_REPUTATION_CAP = 25
local DEFAULT_HEIR_MIN_CE_WITH_TECHNIQUE = 30

local function clampStat(value, min, max)
	return math.clamp(value or 0, min or 0, max or 100)
end

local function deepCopyTable(source)
	if typeof(source) ~= "table" then
		return source
	end

	local copy = {}

	for key, value in pairs(source) do
		if typeof(value) == "table" then
			copy[key] = deepCopyTable(value)
		else
			copy[key] = value
		end
	end

	return copy
end

local function normalizeTechniqueName(value)
	local text = tostring(value or "None")
	if text == "" or text == "nil" or text == "Unknown" then
		return "None"
	end
	return text
end

local function hasTechnique(value)
	local text = normalizeTechniqueName(value)
	return text ~= "None"
end

local function getBestKnownTechnique(data)
	if typeof(data) ~= "table" then
		return "None"
	end

	local fields = {
		"CursedTechnique",
		"InnateTechnique",
		"PlayerClanInnateTechnique",
		"ClanInnateTechnique",
		"InheritedTechnique",
		"BloodlineTechnique",
	}

	for _, field in ipairs(fields) do
		local technique = normalizeTechniqueName(data[field])
		if technique ~= "None" then
			return technique
		end
	end

	return "None"
end

local function splitFirstName(fullName)
	local text = tostring(fullName or "")
	text = text:gsub("^%s+", "")
	text = text:gsub("%s+$", "")

	if text == "" then
		return "Unknown"
	end

	local pieces = string.split(text, " ")
	return pieces[1] or text
end

local function resolveLateParentRole(parentStats)
	local gender = tostring(parentStats and parentStats.Gender or "")

	if gender == "Female" then
		return "Late Mother"
	end

	if gender == "Male" then
		return "Late Father"
	end

	return math.random(1, 2) == 1 and "Late Mother" or "Late Father"
end

local function resolveLivingParentRole(parentStats)
	local gender = tostring(parentStats and parentStats.Gender or "")

	if gender == "Female" then
		return "Mother"
	end

	if gender == "Male" then
		return "Father"
	end

	return math.random(1, 2) == 1 and "Mother" or "Father"
end

local function getOppositeParentRole(parentRole)
	if parentRole == "Late Mother" or parentRole == "Mother" then
		return "Father"
	end

	return "Mother"
end

local function getCurrentYearFromStats(stats)
	if typeof(stats) ~= "table" then
		return 2000
	end

	local currentYear = tonumber(stats.CurrentYear)
	if currentYear then
		return currentYear
	end

	local birthYear = tonumber(stats.BirthYear)
	if birthYear then
		return birthYear + (tonumber(stats.Age) or 0)
	end

	local eraStart = tonumber(stats.EraStartYear) or 2000
	return eraStart + (tonumber(stats.Age) or 0)
end

local function preserveLegacyTimeline(newStats, parentStats, chosenChild)
	local inheritedCurrentYear = getCurrentYearFromStats(parentStats)
	local heirAge = math.max(0, tonumber(newStats.Age) or tonumber(chosenChild and chosenChild.Age) or 0)
	local inheritedCurrentEra = tostring(parentStats.CurrentEra or parentStats.Era or "Modern Era")

	local inheritedBirthYear = inheritedCurrentYear - heirAge
	newStats.CurrentYear = inheritedCurrentYear
	newStats.BirthYear = inheritedBirthYear
	-- Character customization currently force-resets BirthYear from EraStartYear.
	-- For heirs, EraStartYear must therefore represent the heir's actual birth year,
	-- not the historical era's first year, or identity selection snaps them to 2000/era start.
	newStats.EraStartYear = inheritedBirthYear
	newStats.CurrentEra = inheritedCurrentEra
	newStats.Era = inheritedCurrentEra
	newStats.BirthEra = inheritedCurrentEra
	newStats.BirthPath = typeof(newStats.BirthPath) == "table" and newStats.BirthPath or {}
	newStats.BirthPath.Era = inheritedCurrentEra
	newStats.LegacyTimelineLocked = true
	newStats.LegacyInheritedYear = inheritedCurrentYear
end

local CLAN_DOJO_PRESERVED_FIELDS = {
	"ClanFounded",
	"PlayerClanName",
	"ClanMembers",
	"ClanReputation",
	"ClanStudentsRecruited",
	"ClanTrainingSessions",
	"DojoLevel",
	"DojoCondition",
	"DojoPrestige",
	"DojoFocus",
	"DojoSparringEvents",
	"DojoEventsHosted",
	"LastDojoEventName",
	"RivalDojoName",
	"RivalDojoFocus",
	"RivalDojoReputation",
	"RivalDojoWins",
	"RivalDojoLosses",
	"DojoFounderName",
	"DojoClanBaseName",
	"DojoNameConfirmed",
	"DojoPendingLastNameChoice",
	"DojoRecruitPool",
	"DojoStarterRecruitLimit",
	"DojoStarterRecruitsUsed",
}

local function preserveClanDojoState(newStats, parentStats)
	for _, field in ipairs(CLAN_DOJO_PRESERVED_FIELDS) do
		if parentStats[field] ~= nil then
			newStats[field] = deepCopyTable(parentStats[field])
		end
	end

	if parentStats.ClanFounded == true then
		newStats.ClanFounded = true
		newStats.PlayerClanName = parentStats.PlayerClanName
		newStats.ClanMembers = parentStats.ClanMembers or 1
		newStats.ClanReputation = parentStats.ClanReputation or 0
		newStats.DojoFounderName = parentStats.DojoFounderName or parentStats.ClanFounderName or parentStats.Name or "Unknown"
		newStats.ClanFounderName = parentStats.ClanFounderName or newStats.DojoFounderName
	end
end

local function shouldCarryLegacyRelationship(relationship, successorId)
	local role = tostring(relationship and relationship.Role or "")
	if relationship.Id == successorId then
		return false
	end

	return role == "Student"
		or role == "Ward"
		or relationship.IsClanStudent == true
		or relationship.IsWard == true
end

local function applyTechniqueMirrors(stats, technique)
	technique = normalizeTechniqueName(technique)

	stats.CursedTechnique = technique

	if technique ~= "None" then
		stats.InnateTechnique = normalizeTechniqueName(stats.InnateTechnique)
		if stats.InnateTechnique == "None" then
			stats.InnateTechnique = technique
		end

		stats.TechniqueKnown = true
		stats.TechniqueUsable = true
		stats.TechniqueAwakened = true
		stats.InnateDormant = false
		stats.TechniqueType = tostring(stats.TechniqueType or "Inherited")
	else
		stats.InnateTechnique = normalizeTechniqueName(stats.InnateTechnique)
		stats.TechniqueKnown = stats.TechniqueKnown == true
		stats.TechniqueUsable = stats.TechniqueUsable == true
		stats.TechniqueAwakened = stats.TechniqueAwakened == true
		stats.InnateDormant = stats.InnateDormant == true
		stats.TechniqueType = tostring(stats.TechniqueType or "None")
	end
end

-- Same CE ceilings CheckPromotion (BitKaisenStats.luau) uses per grade to gate
-- promotion, reused here as a sanity cap on inherited CE. train_child (see
-- BK_RelationshipService.luau) already limits training to 3 uses/age, but a
-- child can be trained across many ages before a takeover -- without this cap
-- that legitimately-earned CE could still dwarf what a starting character of
-- the same grade should have.
local CHILD_CE_CAP_BY_GRADE = {
	["Non-Sorcerer"] = 100,
	["Grade 4"] = 450,
	["Semi-Grade 3"] = 450,
	["Grade 3"] = 650,
	["Semi-Grade 2"] = 800,
	["Grade 2"] = 1000,
	["Semi-Grade 1"] = 1200,
	["Grade 1"] = 1000,
	["Special Grade"] = 1500,
	["Special Grade 1"] = 1500,
}

local function applyChildProfileToStats(newStats, parentStats, chosenChild)
	if not newStats or not chosenChild then
		return
	end

	local childTechnique = getBestKnownTechnique(chosenChild)
	local childMastery = math.clamp(tonumber(chosenChild.TechniqueMastery) or 0, 0, 100)
	local childCECap = CHILD_CE_CAP_BY_GRADE[tostring(chosenChild.Grade or "Non-Sorcerer")] or 450
	local childCE = math.min(childCECap, math.max(0, tonumber(chosenChild.CursedEnergy) or 0))

	newStats.FirstName = splitFirstName(chosenChild.Name)
	newStats.Gender = tostring(chosenChild.Gender or newStats.Gender or "Unknown")
	newStats.Age = math.max(0, tonumber(chosenChild.Age) or 0)

	if chosenChild.CurrentMonth then
		newStats.CurrentMonth = math.clamp(tonumber(chosenChild.CurrentMonth) or 1, 1, 12)
	end

	if chosenChild.MonthsIntoAge then
		newStats.MonthsIntoAge = math.clamp(tonumber(chosenChild.MonthsIntoAge) or 0, 0, 11)
	end

	newStats.CEBaseline = math.min(childCECap, math.max(0, tonumber(chosenChild.CEBaseline) or childCE))
	newStats.CursedEnergy = math.max(childCE, newStats.CEBaseline)
	newStats.TechniqueMastery = childMastery
	newStats.Grade = tostring(chosenChild.Grade or newStats.Grade or "Non-Sorcerer")
	newStats.InheritanceProfile = deepCopyTable(chosenChild.InheritanceProfile or {})
	newStats.CanJoinDojo = chosenChild.CanJoinDojo == true
	newStats.CanJoinClan = chosenChild.CanJoinClan == true
	newStats.DojoEligible = chosenChild.DojoEligible == true
	newStats.ClanEligible = chosenChild.ClanEligible == true
	newStats.FamilyCareer = tostring(chosenChild.FamilyCareer or "Undecided")

	newStats.InnateTechnique = normalizeTechniqueName(chosenChild.InnateTechnique)
	newStats.PlayerClanInnateTechnique = normalizeTechniqueName(chosenChild.PlayerClanInnateTechnique or parentStats.PlayerClanInnateTechnique)
	newStats.ClanInnateTechnique = normalizeTechniqueName(chosenChild.ClanInnateTechnique or parentStats.ClanInnateTechnique)
	newStats.InheritedTechnique = normalizeTechniqueName(chosenChild.InheritedTechnique or childTechnique)
	newStats.BloodlineTechnique = normalizeTechniqueName(chosenChild.BloodlineTechnique or parentStats.BloodlineTechnique)
	newStats.TechniqueType = tostring(chosenChild.TechniqueType or (childTechnique ~= "None" and "Inherited" or "None"))

	applyTechniqueMirrors(newStats, childTechnique)

	if childTechnique ~= "None" then
		newStats.CursedEnergy = math.max(newStats.CursedEnergy or 0, DEFAULT_HEIR_MIN_CE_WITH_TECHNIQUE)
		if tostring(newStats.Grade or "Non-Sorcerer") == "Non-Sorcerer" then
			newStats.Grade = "Grade 4"
		end
	end

	if typeof(chosenChild.Traits) == "table" then
		newStats.Traits = deepCopyTable(chosenChild.Traits)
		newStats.TraitsRolled = true
	end

	if chosenChild.TraitSummary then
		newStats.TraitSummary = chosenChild.TraitSummary
	end

	if chosenChild.Appearance then
		newStats.Appearance = deepCopyTable(chosenChild.Appearance)
	end

	if chosenChild.BirthPath then
		newStats.BirthPath = deepCopyTable(chosenChild.BirthPath)
	end
end

function BitKaisenLegacy.GetEligibleSuccessors(parentStats)
	local eligible = {}

	if not parentStats then
		return eligible
	end

	local seenIds = {}
	local sources = { parentStats.Relationships or {} }
	if typeof(parentStats.PriorLifeChildren) == "table" then
		table.insert(sources, parentStats.PriorLifeChildren)
	end

	for _, sourceList in ipairs(sources) do
		for _, relationship in ipairs(sourceList) do
			if relationship.Role == "Child" and relationship.Alive ~= false and not seenIds[relationship.Id] then
				seenIds[relationship.Id] = true
				local technique = getBestKnownTechnique(relationship)

				table.insert(eligible, {
					Id = relationship.Id,
					Name = relationship.Name,
					Age = relationship.Age or 0,
					Gender = relationship.Gender or "Unknown",
					Grade = relationship.Grade or "Non-Sorcerer",
					CursedEnergy = relationship.CursedEnergy or 0,
					CEBaseline = relationship.CEBaseline or relationship.CursedEnergy or 0,
					CursedTechnique = technique,
					InnateTechnique = relationship.InnateTechnique or "None",
					PlayerClanInnateTechnique = relationship.PlayerClanInnateTechnique or "None",
					TechniqueMastery = relationship.TechniqueMastery or 0,
					Traits = deepCopyTable(relationship.Traits or {}),
					InheritanceProfile = deepCopyTable(relationship.InheritanceProfile or {}),
					CanJoinDojo = relationship.CanJoinDojo == true,
					CanJoinClan = relationship.CanJoinClan == true,
					DojoEligible = relationship.DojoEligible == true,
					ClanEligible = relationship.ClanEligible == true,
					FamilyCareer = relationship.FamilyCareer or "Undecided",
					HasInheritedTechnique = technique ~= "None"
				})
			end
		end
	end

	return eligible
end

function BitKaisenLegacy.HasEligibleSuccessor(parentStats)
	local successors = BitKaisenLegacy.GetEligibleSuccessors(parentStats)
	return #successors > 0
end

function BitKaisenLegacy.BuildSuccessorStats(parentStats, successorId, BitKaisenStats, BitKaisenRelationships, options)
	if not parentStats or not BitKaisenStats or not BitKaisenRelationships then
		return nil, "Missing required modules."
	end

	options = typeof(options) == "table" and options or {}
	local liveTakeover = options.LiveTakeover == true

	local chosenChild = nil

	for _, relationship in ipairs(parentStats.Relationships or {}) do
		if relationship.Id == successorId and relationship.Role == "Child" and relationship.Alive ~= false then
			chosenChild = relationship
			break
		end
	end

	if not chosenChild then
		return nil, "Chosen child is no longer available."
	end

	local newStats = BitKaisenStats.GetDefaultStats()

	newStats.Generation = (tonumber(parentStats.Generation) or 1) + 1
	newStats.LegacyHistory = deepCopyTable(parentStats.LegacyHistory or {})

	table.insert(newStats.LegacyHistory, {
		Name = parentStats.Name,
		FamilyName = parentStats.FamilyName,
		Generation = parentStats.Generation or 1,
		Age = parentStats.Age or 0,
		Grade = parentStats.Grade or "Non-Sorcerer",
		CursedTechnique = getBestKnownTechnique(parentStats),
		TechniqueMastery = parentStats.TechniqueMastery or 0,
		MissionsCompleted = parentStats.MissionsCompleted or 0,
		Reputation = parentStats.Reputation or 0,
		ClanFounded = parentStats.ClanFounded == true,
		ClanName = parentStats.PlayerClanName,
		ClanReputation = parentStats.ClanReputation or 0
	})

	local familyName = tostring(parentStats.FamilyName or "Unknown")
	newStats.FamilyName = familyName
	newStats.Name = splitFirstName(chosenChild.Name) .. " " .. familyName

	newStats.FamilyType = parentStats.ClanFounded == true and "Sorcerer Clan" or (parentStats.FamilyType or "Sorcerer")
	newStats.Clan = parentStats.Clan or "Minor Sorcerer Family"
	newStats.Origin = parentStats.Origin or parentStats.Clan or "Minor Sorcerer Family"
	newStats.OriginCategory = parentStats.OriginCategory or "Family"

	newStats.BirthEra = parentStats.BirthEra
	newStats.EraStartYear = parentStats.EraStartYear
	newStats.CurrentEra = parentStats.CurrentEra or parentStats.Era
	newStats.Era = parentStats.CurrentEra or parentStats.Era

	applyChildProfileToStats(newStats, parentStats, chosenChild)
	preserveLegacyTimeline(newStats, parentStats, chosenChild)

	-- Keep the child's name locked to the inherited family name after profile application.
	newStats.FamilyName = familyName
	newStats.Name = tostring(newStats.FirstName or splitFirstName(chosenChild.Name)) .. " " .. familyName

	local inheritedMoney = math.floor((tonumber(parentStats.Money) or 0) * INHERIT_MONEY_PERCENT)
	newStats.Money = inheritedMoney

	local inheritedReputation = math.floor((tonumber(parentStats.Reputation) or 0) * INHERIT_REPUTATION_PERCENT)
	newStats.Reputation = math.min(inheritedReputation, INHERIT_REPUTATION_CAP)

	newStats.Assets = deepCopyTable(parentStats.Assets or {})
	preserveClanDojoState(newStats, parentStats)

	if parentStats.ClanFounded then
		newStats.PlayerClanInnateTechnique = normalizeTechniqueName(parentStats.PlayerClanInnateTechnique or newStats.PlayerClanInnateTechnique)
		newStats.ClanInnateTechnique = normalizeTechniqueName(parentStats.ClanInnateTechnique or newStats.ClanInnateTechnique)
	end

	newStats.Relationships = {}
	newStats.RelationshipHistory = {}
	newStats.RecentLifeEvents = {}
	newStats.RecentQuietTexts = {}
	newStats.ActivitiesDoneThisAge = 0
	newStats.RelationshipActionsThisAge = 0
	newStats.Alive = true

	local parentRole = liveTakeover and resolveLivingParentRole(parentStats) or resolveLateParentRole(parentStats)

	local memorialParent = {
		Id = (liveTakeover and "living_parent_" or "late_parent_") .. tostring(math.random(100000, 999999)),
		Name = parentStats.Name or "Unknown",
		Gender = parentStats.Gender or ((parentRole == "Late Mother" or parentRole == "Mother") and "Female" or "Male"),
		Role = parentRole,
		Status = liveTakeover and "Parent" or "Deceased Parent",
		Bond = 90,
		Trust = 90,
		Respect = 95,
		Fear = 0,
		Romance = 0,
		Alive = liveTakeover and true or false,
		DeathCause = liveTakeover and nil or "Previous life",
		DeathText = liveTakeover and nil or (tostring(parentStats.Name or "Unknown") .. " was the previous holder of the " .. familyName .. " name."),
		YearsKnown = tonumber(newStats.Age) or 0,
		YearsDating = 0,
		YearsMarried = 0,
		Age = parentStats.Age or 0,
		Grade = parentStats.Grade or "Non-Sorcerer",
		CursedEnergy = parentStats.CursedEnergy or 0,
		CursedTechnique = getBestKnownTechnique(parentStats),
		TechniqueMastery = parentStats.TechniqueMastery or 0,
		Traits = deepCopyTable(parentStats.Traits or {}),
		TraitSummary = parentStats.TraitSummary,
		Personality = "Carried the weight of the " .. familyName .. " family before you.",
		Background = liveTakeover and ("They passed the focus of the " .. familyName .. " family to you while still alive.") or ("They lived for " .. tostring(parentStats.Age or 0) .. " years, reached " .. tostring(parentStats.Grade or "Non-Sorcerer") .. ", and left this life behind for you to continue."),
		IsChild = false
	}

	table.insert(newStats.Relationships, memorialParent)

	for _, oldRelationship in ipairs(parentStats.Relationships or {}) do
		if oldRelationship.Role == "Spouse" and oldRelationship.Alive ~= false then
			local survivingParent = deepCopyTable(oldRelationship)
			local preservedGender = survivingParent.Gender
			survivingParent.Id = "surviving_parent_" .. tostring(math.random(100000, 999999))
			survivingParent.Role = resolveLivingParentRole(survivingParent)
			survivingParent.Gender = preservedGender or survivingParent.Gender
			survivingParent.Status = "Surviving Parent"
			survivingParent.Romance = 0
			survivingParent.Bond = clampStat(survivingParent.Bond or 60, 40, 100)
			survivingParent.Trust = clampStat(survivingParent.Trust or 60, 40, 100)
			local heirAge = math.max(0, tonumber(newStats.Age) or 0)
			local parentCurrentAge = math.max(18, tonumber(survivingParent.Age) or (heirAge + 25))
			local parentAgeAtBirth = math.max(18, parentCurrentAge - heirAge)
			survivingParent.AgeAtMet = parentAgeAtBirth
			survivingParent.MetAtAge = 0
			survivingParent.YearsKnown = heirAge
			survivingParent.YearsDating = 0
			survivingParent.YearsMarried = 0
			survivingParent.Age = parentAgeAtBirth + heirAge
			survivingParent.IsChild = false

			table.insert(newStats.Relationships, survivingParent)
			break
		end
	end

	for _, oldRelationship in ipairs(parentStats.Relationships or {}) do
		if oldRelationship.Role == "Child" and oldRelationship.Alive ~= false and oldRelationship.Id ~= successorId then
			local sibling = deepCopyTable(oldRelationship)
			sibling.Id = "sibling_" .. tostring(math.random(100000, 999999))
			sibling.Role = "Sibling"
			sibling.Status = "Sibling"
			sibling.Romance = 0
			sibling.YearsKnown = 0
			sibling.YearsDating = 0
			sibling.YearsMarried = 0
			sibling.IsChild = false

			table.insert(newStats.Relationships, sibling)
		end
	end

	for _, oldRelationship in ipairs(parentStats.Relationships or {}) do
		if shouldCarryLegacyRelationship(oldRelationship, successorId) then
			local carried = deepCopyTable(oldRelationship)
			carried.Id = "legacy_" .. tostring(oldRelationship.Id or carried.Role or "relationship") .. "_" .. tostring(math.random(100000, 999999))
			carried.Status = tostring(carried.Status or carried.Role or "Clan Connection")
			carried.Romance = 0
			carried.Fear = carried.Fear or 0
			carried.YearsKnown = carried.YearsKnown or 0
			carried.YearsDating = 0
			carried.YearsMarried = 0
			carried.YearsDivorced = 0
			carried.LegacyCarriedRelationship = true
			table.insert(newStats.Relationships, carried)
		end
	end

	BitKaisenRelationships.EnsureRelationships(newStats)

	return newStats, nil
end

function BitKaisenLegacy.BuildIntroMessage(newStats, parentStats)
	if not newStats or not parentStats then
		return "A new generation begins."
	end

	local message = "<font color='#a782ff'><b>[ LEGACY ]</b></font> A new generation of the <b>" .. tostring(newStats.FamilyName or "Unknown") .. " Family</b> begins."
	message = message .. "\nYou are <b>" .. tostring(newStats.Name) .. "</b>, child of <b>" .. tostring(parentStats.Name or "Unknown") .. "</b>."

	local inheritedTechnique = getBestKnownTechnique(newStats)
	if inheritedTechnique ~= "None" then
		message = message .. "\nYou continue with <b>" .. tostring(inheritedTechnique) .. "</b> and starting mastery of " .. tostring(newStats.TechniqueMastery or 0) .. "%."
	end

	if newStats.ClanFounded then
		message = message .. "\nYou inherited leadership of the <b>" .. tostring(newStats.PlayerClanName or "Unnamed Clan") .. "</b>."
	end

	if (newStats.Money or 0) > 0 then
		message = message .. "\nThe estate left you $" .. tostring(newStats.Money) .. "."
	end

	if #(newStats.Assets or {}) > 0 then
		message = message .. "\nYou inherited " .. tostring(#newStats.Assets) .. " of your parent's assets."
	end

	if typeof(newStats.Traits) == "table" and #newStats.Traits > 0 then
		message = message .. "\nYour heir's traits carried over from their existing profile."
	end

	if newStats.LiveSuccessorTakeover == true then
		message = message .. "\n<font color='#f0b955'><b>[ GOD MODE ]</b></font> Your previous life continues as a living parent while you take over this child."
	end

	message = message .. "\nThis is Generation <b>" .. tostring(newStats.Generation or 2) .. "</b> of your bloodline."

	return message
end

return BitKaisenLegacy
