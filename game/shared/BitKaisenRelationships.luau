-- ModuleScript: BitKaisenRelationships
-- Location: ReplicatedStorage
-- Purpose:
-- Full relationship system with legacy/save support.
-- Handles family roles, romance, kids, deaths/memories, and now legacy-inherited
-- roles (Late Mother, Late Father, Surviving Parent).

local BitKaisenRelationships = {}

local function markRelationshipsDirty(stats)
	if typeof(stats) == "table" then
		stats.RelationshipVersion = (tonumber(stats.RelationshipVersion) or 0) + 1
	end
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BitKaisenTraits = require(ReplicatedStorage:WaitForChild("BitKaisenTraits"))
local BitKaisenStats = require(ReplicatedStorage:WaitForChild("BitKaisenStats"))

local MAX_ACTIVE_RELATIONSHIPS = 40

BitKaisenRelationships.FirstNames = {
	"Ren", "Akio", "Daiki", "Haruto", "Kaito", "Riku", "Sora", "Toma", "Yuto", "Itsuki",
	"Shin", "Rei", "Kazue", "Niko", "Tatsu", "Hiro", "Masaru", "Ryo", "Kenshi", "Kei",
	"Mizuki", "Airi", "Hana", "Yuna", "Kira", "Emi", "Saki", "Rina", "Aya", "Mei",
	"Kana", "Aiko", "Reina", "Mira", "Yuki", "Amane", "Koharu", "Akira", "Hikari", "Natsuki",
	"Kaede", "Saya", "Mina", "Yua", "Shiori", "Miyu", "Asahi", "Rikka", "Kanna", "Tomoe",
	"Seiji", "Naoto", "Kiyoshi", "Hinata", "Arata", "Yori", "Taiga", "Nori", "Isamu", "Fuyu"
}

BitKaisenRelationships.MaleFirstNames = {
	"Ren", "Akio", "Daiki", "Haruto", "Kaito", "Riku", "Sora", "Toma", "Yuto", "Itsuki",
	"Shin", "Rei", "Niko", "Tatsu", "Hiro", "Masaru", "Ryo", "Kenshi", "Kei", "Seiji",
	"Naoto", "Kiyoshi", "Hinata", "Arata", "Yori", "Taiga", "Nori", "Isamu", "Fuyu"
}

BitKaisenRelationships.FemaleFirstNames = {
	"Mizuki", "Airi", "Hana", "Yuna", "Kira", "Emi", "Saki", "Rina", "Aya", "Mei",
	"Kana", "Aiko", "Reina", "Mira", "Yuki", "Amane", "Koharu", "Akira", "Hikari", "Natsuki",
	"Kaede", "Saya", "Mina", "Yua", "Shiori", "Miyu", "Asahi", "Rikka", "Kanna", "Tomoe"
}

BitKaisenRelationships.FamilyNames = {
	"Kumiwado", "Mizukara", "Amahara", "Tsukigane", "Kurogiri", "Hoshinari", "Yamashiro", "Shinkawa", "Morikage", "Fushidori",
	"Kazehara", "Midorikawa", "Arakane", "Sakuraba", "Onikawa", "Higashino", "Kurosawa", "Tachibara", "Murasaki", "Yorimune",
	"Kaneshima", "Hakamori", "Tengawa", "Shirogane", "Akatsuba", "Yuzanami", "Kisaragi", "Mikazuchi", "Reikado", "Asamura"
}

local PERSONALITIES = {
	"Quiet but observant",
	"Blunt and hard to impress",
	"Warm but cautious",
	"Protective and stubborn",
	"Ambitious and competitive",
	"Calm under pressure",
	"Kind, but not naive",
	"Secretive about their past",
	"Loyal once trust is earned",
	"Sharp-tongued but reliable",
	"Soft-spoken until pressure hits",
	"Polite, but keeps score",
	"Careless with danger but loyal to friends",
	"Studious and obsessed with technique theory",
	"Cold at first, protective later",
	"Ambitious enough to become a problem",
	"Easygoing until curses are involved"
}

local TECHNIQUES = {
	"None",
	"Straw Doll",
	"Ratio Technique",
	"Boogie Woogie",
	"Cursed Speech",
	"Thread Manipulation",
	"Mirror Step",
	"Grave Bloom",
	"Static Binding",
	"Paper Shikigami",
	"Bone Forge",
	"Shadow Stitch",
	"Echo Pulse",
	"Threaded Verdict",
	"Mirror Garden",
	"Static Execution",
	"Grave Lantern",
	"Ashen Step",
	"Blood Tax",
	"Cursed Pulse Radar",
	"Vow Chain",
	"Shatter Palm"
}

local function cleanLineageText(text)
	text = tostring(text or "")
	text = string.gsub(text, "^%s+", "")
	text = string.gsub(text, "%s+$", "")
	return text
end

local function isRealTechnique(technique)
	technique = cleanLineageText(technique)
	return technique ~= "" and technique ~= "None" and technique ~= "Six Eyes"
end

local function findOriginDataForStats(stats)
	if typeof(stats) ~= "table" or typeof(BitKaisenStats.Origins) ~= "table" then
		return nil
	end

	local candidates = {
		cleanLineageText(stats.Origin),
		cleanLineageText(stats.Clan),
		cleanLineageText(stats.PlayerClanName),
		cleanLineageText(stats.FamilyName),
	}

	for _, originData in ipairs(BitKaisenStats.Origins) do
		local names = {
			cleanLineageText(originData.Id),
			cleanLineageText(originData.DisplayName),
			cleanLineageText(originData.FamilyName),
		}

		for _, candidate in ipairs(candidates) do
			if candidate ~= "" then
				for _, name in ipairs(names) do
					if candidate == name then
						return originData
					end
				end
			end
		end
	end

	return nil
end

local function sourceHasTrait(sourceStats, traitId)
	if typeof(sourceStats) ~= "table" or type(sourceStats.Traits) ~= "table" then
		return false
	end

	traitId = string.lower(tostring(traitId or ""))
	for _, ownedId in ipairs(sourceStats.Traits) do
		if string.lower(tostring(ownedId or "")) == traitId then
			return true
		end
	end

	return false
end

local function sourceHasTechnique(sourceStats, technique)
	if typeof(sourceStats) ~= "table" or not isRealTechnique(technique) then
		return false
	end

	for _, field in ipairs({ "CursedTechnique", "InnateTechnique", "PlayerClanInnateTechnique", "ClanInnateTechnique", "BloodlineTechnique" }) do
		if cleanLineageText(sourceStats[field]) == technique then
			return true
		end
	end

	return false
end

local function calculateInheritedCEBaseline(parentStats, coParentStats)
	local parentCE = math.max(0, tonumber(parentStats and parentStats.CursedEnergy) or 0)
	local coParentCE = math.max(0, tonumber(coParentStats and coParentStats.CursedEnergy) or 0)
	local strongerParentCE = math.max(parentCE, coParentCE)
	local averageParentCE = coParentCE > 0 and math.floor((parentCE + coParentCE) / 2) or parentCE
	local bloodline = math.clamp(tonumber(parentStats and parentStats.BloodlineStrength) or 0, 0, 100)
	local clanBonus = (parentStats and (parentStats.ClanFounded == true or tostring(parentStats.PlayerClanName or "") ~= "")) and math.random(8, 18) or 0
	local inheritedFloor = math.floor(averageParentCE * 0.22) + math.floor(strongerParentCE * 0.08) + math.floor(bloodline * 0.25) + clanBonus
	return math.clamp(inheritedFloor + math.random(5, 28), 5, 450)
end

local function applyInheritedClanPotential(parentStats, childStats, coParentStats)
	local originData = findOriginDataForStats(parentStats) or findOriginDataForStats(coParentStats)
	if typeof(childStats) ~= "table" then
		return
	end

	local ceBaseline = calculateInheritedCEBaseline(parentStats, coParentStats)
	childStats.CEBaseline = math.max(tonumber(childStats.CEBaseline) or 0, ceBaseline)
	childStats.CursedEnergy = math.max(tonumber(childStats.CursedEnergy) or 0, childStats.CEBaseline)
	childStats.InheritanceProfile = childStats.InheritanceProfile or {}
	childStats.InheritanceProfile.CEBaseline = childStats.CEBaseline
	childStats.InheritanceProfile.ParentCE = math.max(0, tonumber(parentStats and parentStats.CursedEnergy) or 0)
	childStats.InheritanceProfile.CoParentCE = math.max(0, tonumber(coParentStats and coParentStats.CursedEnergy) or 0)

	if typeof(originData) ~= "table" then
		return
	end

	childStats.Origin = originData.DisplayName or originData.Id or childStats.Origin
	childStats.Clan = originData.DisplayName or childStats.Clan
	childStats.FamilyName = originData.FamilyName or childStats.FamilyName
	childStats.PlayerClanName = originData.FamilyName or childStats.PlayerClanName
	childStats.FamilyType = parentStats and parentStats.FamilyType or childStats.FamilyType
	childStats.BloodlineStrength = math.max(0, tonumber(parentStats and parentStats.BloodlineStrength) or 0)

	local bloodlineStrength = math.clamp(tonumber(childStats.BloodlineStrength) or 0, 0, 100)
	local inheritChance = 35 + math.floor(bloodlineStrength * 0.25)
	if parentStats and parentStats.FamilyType == "Sorcerer" then
		inheritChance += 10
	end
	if coParentStats and (findOriginDataForStats(coParentStats) == originData) then
		inheritChance += 10
	end
	inheritChance = math.clamp(inheritChance, 15, 85)

	local inheritedTechnique = nil
	local parentTechnique = cleanLineageText(parentStats and (parentStats.PlayerClanInnateTechnique or parentStats.ClanInnateTechnique or parentStats.BloodlineTechnique or parentStats.InnateTechnique or parentStats.CursedTechnique))
	if math.random(1, 100) <= inheritChance then
		if isRealTechnique(parentTechnique) and sourceHasTechnique(parentStats, parentTechnique) then
			inheritedTechnique = parentTechnique
		else
			inheritedTechnique = BitKaisenStats.RollInnateTechniqueForOrigin(originData)
		end
	end

	if inheritedTechnique == "Six Eyes" then
		inheritedTechnique = "Limitless"
		childStats.SixEyesBornTraitPending = true
	end

	if isRealTechnique(inheritedTechnique) then
		childStats.InnateTechnique = inheritedTechnique
		childStats.PlayerClanInnateTechnique = inheritedTechnique
		childStats.ClanInnateTechnique = inheritedTechnique
		childStats.BloodlineTechnique = inheritedTechnique
		childStats.InheritedTechnique = inheritedTechnique
		childStats.TechniqueType = "Innate"
		childStats.TechniqueKnown = true
		childStats.TechniqueUsable = false
		childStats.TechniqueAwakened = false
		childStats.InnateDormant = true
	end

	local isGojoLine = childStats.FamilyName == "Gojo" or childStats.PlayerClanName == "Gojo" or childStats.Origin == "Gojo Clan" or childStats.Origin == "Sugawara Lineage"
	if isGojoLine then
		if cleanLineageText(childStats.InnateTechnique) == "" or childStats.InnateTechnique == "None" then
			if math.random(1, 100) <= inheritChance then
				childStats.InnateTechnique = "Limitless"
				childStats.PlayerClanInnateTechnique = "Limitless"
				childStats.ClanInnateTechnique = "Limitless"
				childStats.BloodlineTechnique = "Limitless"
				childStats.InheritedTechnique = "Limitless"
				childStats.TechniqueType = "Innate"
				childStats.TechniqueKnown = true
				childStats.TechniqueUsable = false
				childStats.TechniqueAwakened = false
				childStats.InnateDormant = true
			end
		end

		local sixEyesChance = 6 + math.floor(bloodlineStrength * 0.08)
		if cleanLineageText(childStats.InnateTechnique) == "Limitless" then
			sixEyesChance += 5
		end
		if sourceHasTrait(parentStats, "six_eyes") or sourceHasTrait(coParentStats, "six_eyes") then
			sixEyesChance += 12
		end
		if math.random(1, 100) <= math.clamp(sixEyesChance, 3, 35) then
			childStats.SixEyesBornTraitPending = true
		end
	end
end

local function addGuaranteedLegacyTraits(ownerStats, relationship)
	if typeof(ownerStats) ~= "table" or typeof(relationship) ~= "table" then
		return
	end
	local settings = typeof(ownerStats.GodModeSettings) == "table" and ownerStats.GodModeSettings or {}
	if settings.GuaranteedLegacyTraits ~= true and ownerStats.GodModeGuaranteedLegacyTraits ~= true then
		return
	end
	if relationship.Role ~= "Child" then
		return
	end

	local rarityRank = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Secret = 6 }
	local parentTraits = {}
	if typeof(ownerStats.Traits) == "table" then
		for _, traitId in ipairs(ownerStats.Traits) do
			local trait = BitKaisenTraits.GetTrait(traitId)
			if trait then
				table.insert(parentTraits, trait)
			end
		end
	end
	table.sort(parentTraits, function(a, b)
		local rankA = rarityRank[a.Rarity] or 0
		local rankB = rarityRank[b.Rarity] or 0
		if rankA ~= rankB then
			return rankA > rankB
		end
		local impactA = 0
		local impactB = 0
		for _, value in pairs(a.Modifiers or {}) do if type(value) == "number" then impactA += math.abs(value - 1) end end
		for _, value in pairs(b.Modifiers or {}) do if type(value) == "number" then impactB += math.abs(value - 1) end end
		return impactA > impactB
	end)

	relationship.Traits = typeof(relationship.Traits) == "table" and relationship.Traits or {}
	for index = 1, math.min(2, #parentTraits) do
		local trait = parentTraits[index]
		local exists = false
		for _, owned in ipairs(relationship.Traits) do
			local ownedTrait = BitKaisenTraits.GetTrait(owned)
			if ownedTrait and ownedTrait.Id == trait.Id then
				exists = true
				break
			end
		end
		if not exists then
			table.insert(relationship.Traits, trait.Id)
		end
	end
end

local function ensureRelationshipTraits(ownerStats, relationship, rollOptions)
	if not relationship then
		return
	end

	if type(relationship.Traits) ~= "table" or #relationship.Traits <= 0 then
		if relationship.Role == "Child" and ownerStats then
			local coParent = nil
			if type(ownerStats.Relationships) == "table" then
				for _, possible in ipairs(ownerStats.Relationships) do
					if possible and (possible.Role == "Spouse" or possible.Role == "Partner" or possible.Name == relationship.CoParentName or possible.Name == relationship.OtherParentName) then
						coParent = possible
						break
					end
				end
			end

			relationship.Traits = BitKaisenTraits.RollInheritedTraits(ownerStats, relationship, coParent)
		else
			local count = math.random(1, 100) <= 22 and 2 or 1
			relationship.Traits = BitKaisenTraits.RollTraits(relationship, count, rollOptions)
		end
	end

	addGuaranteedLegacyTraits(ownerStats, relationship)
	BitKaisenTraits.EnsureTraits(relationship)
	BitKaisenTraits.ApplyStartingBonuses(relationship)
	relationship.TraitSummary = BitKaisenTraits.GetTraitDisplay(relationship)
end

local FAMILY_ROLES = {
	Mother = true,
	Father = true,
	Caretaker = true,
	Sibling = true,
	Child = true,
	Ward = true,
	Student = true,
	["Late Mother"] = true,
	["Late Father"] = true
}

local ROMANCE_ALLOWED_ROLES = {
	Friend = true,
	["Best Friend"] = true,
	Classmate = true,
	["Mission Partner"] = true,
	Partner = true,
	Spouse = true,
	["Notable Sorcerer"] = true
}

local function pickRandom(list)
	return list[math.random(1, #list)]
end

local function clampPercent(value)
	return math.clamp(value or 0, 0, 100)
end

local function makeId(role)
	return string.lower(tostring(role or "relationship")):gsub("%s+", "_") .. "_" .. tostring(math.random(100000, 999999))
end

local function rollGender()
	return math.random(1, 2) == 1 and "Male" or "Female"
end

local function inferGenderFromRole(role)
	role = tostring(role or "")

	if role == "Mother" or role == "Late Mother" then
		return "Female"
	elseif role == "Father" or role == "Late Father" then
		return "Male"
	end

	return nil
end

local function normalizeGender(gender, role)
	if gender == "Female" or gender == "Male" then
		return gender
	end

	local forcedGender = inferGenderFromRole(role)
	if forcedGender then
		return forcedGender
	end

	return rollGender()
end

local function makeName(familyName, gender)
	gender = gender == "Female" and "Female" or "Male"
	local firstNamePool = gender == "Female" and BitKaisenRelationships.FemaleFirstNames or BitKaisenRelationships.MaleFirstNames
	local firstName = pickRandom(firstNamePool)

	if familyName and familyName ~= "None" and familyName ~= "Unknown" then
		return firstName .. " " .. familyName
	end

	return firstName .. " " .. pickRandom(BitKaisenRelationships.FamilyNames)
end

local function sanitizeRomance(relationship)
	if not relationship then
		return
	end

	local role = tostring(relationship.Role or "")

	if FAMILY_ROLES[role] or role == "Teacher" or role == "Rival" or role == "Observer" then
		relationship.Romance = 0
		return
	end

	if not ROMANCE_ALLOWED_ROLES[role] then
		relationship.Romance = 0
		return
	end

	relationship.Romance = clampPercent(relationship.Romance or 0)
end

local ROMANCE_ROLES = {
	Partner = true,
	Spouse = true,
	["Ex-Spouse"] = true,
}

local function stableRelationshipOffset(relationship)
	local text = tostring(relationship and (relationship.Id or relationship.Name or relationship.Role) or "")
	local total = 0
	for index = 1, #text do
		total += string.byte(text, index) * index
	end
	return (total % 6) - 2
end

local function reconcileRelationshipTimeline(stats, relationship)
	if typeof(stats) ~= "table" or typeof(relationship) ~= "table" then
		return
	end

	-- Dead relationships are frozen at their DeathAge (see markRelationshipMurdered
	-- in BK_RelationshipService.luau) -- recalculating their Age from the current
	-- player age here would make a stored corpse (e.g. a Brain Transplant host)
	-- keep "aging" every time the relationship list is touched, even though it's
	-- no longer alive to age.
	if relationship.Alive == false then
		return
	end

	local playerAge = math.max(0, tonumber(stats.Age) or 0)
	local role = tostring(relationship.Role or "")
	local yearsKnown = math.max(0, tonumber(relationship.YearsKnown) or 0)
	local metAtAge = tonumber(relationship.MetAtAge)
	local ageAtMet = tonumber(relationship.AgeAtMet)

	if role == "Mother" or role == "Father" then
		yearsKnown = math.max(yearsKnown, playerAge)
		relationship.MetAtAge = 0
		ageAtMet = math.max(18, ageAtMet or ((tonumber(relationship.Age) or playerAge + 25) - playerAge))
		relationship.AgeAtMet = ageAtMet
		relationship.Age = math.max(18, ageAtMet + playerAge)
	elseif role == "Sibling" then
		yearsKnown = math.max(yearsKnown, playerAge)
		relationship.MetAtAge = 0
		-- AgeAtMet es la edad del hermano cuando el jugador nació (puede ser negativa si es menor)
		if ageAtMet == nil then
			local currentAge = tonumber(relationship.Age) or 0
			ageAtMet = currentAge - playerAge
			relationship.AgeAtMet = ageAtMet
		end
		relationship.Age = math.max(0, ageAtMet + playerAge)
	elseif role == "Caretaker" then
		yearsKnown = math.max(yearsKnown, playerAge)
		relationship.MetAtAge = 0
		ageAtMet = math.max(16, ageAtMet or ((tonumber(relationship.Age) or playerAge + 20) - playerAge))
		relationship.AgeAtMet = ageAtMet
		relationship.Age = math.max(16, ageAtMet + playerAge)
	elseif metAtAge and metAtAge <= playerAge then
		local elapsedSinceMet = playerAge - metAtAge
		if elapsedSinceMet > 1 then
			yearsKnown = math.max(yearsKnown, elapsedSinceMet)
			if ageAtMet and relationship.Age ~= nil then
				relationship.Age = math.max(0, ageAtMet + elapsedSinceMet)
			end
		end
	elseif ROMANCE_ROLES[role] and playerAge >= 16 and yearsKnown <= 1 then
		-- Old saves did not always store when romance started. Use age 16 as a safe lower-bound repair
		-- because romantic progression is mostly unlocked in the teen/adult relationship flow.
		yearsKnown = math.max(yearsKnown, playerAge - 16)
		relationship.MetAtAge = math.min(playerAge, 16)
	end

	if ROMANCE_ROLES[role] and playerAge >= 16 then
		local currentAge = tonumber(relationship.Age) or 0
		local repairedPeerAge = math.max(16, playerAge + stableRelationshipOffset(relationship))
		local impliedAgeAtMet = currentAge - yearsKnown
		-- Only treat a low impliedAgeAtMet as corrupt data when AgeAtMet was never recorded
		-- (old saves). A legitimate, fully-tracked relationship met in childhood also implies
		-- a low AgeAtMet and must not be snapped to playerAge.
		-- Note: relationships already corrupted by older builds of this block are not repaired
		-- retroactively — their original AgeAtMet was overwritten and is unrecoverable. This guard
		-- only prevents new corruption going forward.
		local timelineMissing = ageAtMet == nil
		if currentAge < 16 or (timelineMissing and yearsKnown > 1 and impliedAgeAtMet < 16) then
			relationship.Age = repairedPeerAge
			relationship.AgeAtMet = math.max(16, relationship.Age - yearsKnown)
		elseif relationship.AgeAtMet == nil and yearsKnown > 1 then
			relationship.AgeAtMet = impliedAgeAtMet
		end
	end

	if role == "Partner" then
		local datingStartedAge = tonumber(relationship.DatingStartedAge)
		local elapsedSinceDating = 0
		if datingStartedAge and datingStartedAge <= playerAge then
			elapsedSinceDating = playerAge - datingStartedAge
		elseif playerAge >= 16 then
			elapsedSinceDating = math.max(yearsKnown, (metAtAge and metAtAge <= playerAge) and (playerAge - metAtAge) or 0)
		end

		if elapsedSinceDating > 0 then
			local repairedYearsDating = math.max(tonumber(relationship.YearsDating) or 0, elapsedSinceDating)
			relationship.YearsDating = repairedYearsDating
			relationship.DatingStartedAge = datingStartedAge or math.max(0, playerAge - repairedYearsDating)
		end
	elseif role == "Spouse" then
		local marriedAtAge = tonumber(relationship.MarriedAtAge)
		if marriedAtAge and marriedAtAge <= playerAge then
			relationship.YearsMarried = math.max(tonumber(relationship.YearsMarried) or 0, playerAge - marriedAtAge)
		end
	end

	relationship.YearsKnown = yearsKnown
end

function BitKaisenRelationships.ReconcileRelationshipTimeline(stats, relationship)
	reconcileRelationshipTimeline(stats, relationship)
end

local function assignProfileDefaults(relationship)
	relationship.Gender = normalizeGender(relationship.Gender, relationship.Role)
	relationship.Age = relationship.Age or math.random(14, 45)
	relationship.Grade = relationship.Grade or "Non-Sorcerer"
	relationship.CursedEnergy = relationship.CursedEnergy or math.random(0, 30)
	relationship.CursedTechnique = relationship.CursedTechnique or "None"
	relationship.Personality = relationship.Personality or pickRandom(PERSONALITIES)
	relationship.Background = relationship.Background or nil
end

function BitKaisenRelationships.CreateRelationship(role, name, status, bond, trust, respect, fear, romance, gender)
	gender = normalizeGender(gender, role)

	local relationship = {
		Id = makeId(role),
		Name = name or makeName(nil, gender),
		Gender = gender,
		Role = role or "Acquaintance",
		Status = status or "Neutral",

		Bond = clampPercent(bond or math.random(35, 75)),
		Trust = clampPercent(trust or math.random(30, 70)),
		Respect = clampPercent(respect or math.random(25, 70)),
		Fear = clampPercent(fear or 0),
		Romance = clampPercent(romance or 0),

		Alive = true,
		DeathCause = nil,
		DeathText = nil,

		YearsKnown = 0,
		YearsDating = 0,
		YearsMarried = 0,

		Age = nil,
		Grade = nil,
		CursedEnergy = nil,
		CursedTechnique = nil,
		Personality = nil,
		Background = nil,
		CanInheritTechnique = nil,
		IsChild = false
	}

	assignProfileDefaults(relationship)
	ensureRelationshipTraits(nil, relationship)
	sanitizeRomance(relationship)
	return relationship
end

function BitKaisenRelationships.EnsureRelationships(stats)
	if not stats then
		return
	end

	stats.Relationships = stats.Relationships or {}
	stats.RelationshipHistory = stats.RelationshipHistory or {}

	for _, relationship in ipairs(stats.Relationships) do
		relationship.Id = relationship.Id or makeId(relationship.Role or "Relationship")
		relationship.Role = relationship.Role or "Acquaintance"
		relationship.Gender = normalizeGender(relationship.Gender, relationship.Role)
		relationship.Name = relationship.Name or makeName(stats.FamilyName, relationship.Gender)
		relationship.Status = relationship.Status or "Neutral"

		relationship.Bond = clampPercent(relationship.Bond or 50)
		relationship.Trust = clampPercent(relationship.Trust or 50)
		relationship.Respect = clampPercent(relationship.Respect or 30)
		relationship.Fear = clampPercent(relationship.Fear or 0)

		if relationship.Alive == nil then
			relationship.Alive = true
		end

		relationship.YearsKnown = relationship.YearsKnown or 0
		relationship.YearsDating = relationship.YearsDating or 0
		relationship.YearsMarried = relationship.YearsMarried or 0
		relationship.YearsDivorced = relationship.YearsDivorced or 0
		relationship.IsChild = relationship.IsChild or relationship.Role == "Child"
		reconcileRelationshipTimeline(stats, relationship)

		assignProfileDefaults(relationship)
		ensureRelationshipTraits(stats, relationship)

		if relationship.Role == "Mother" or relationship.Role == "Father" or relationship.Role == "Caretaker" then
			reconcileRelationshipTimeline(stats, relationship)
			relationship.Grade = relationship.Grade or "Non-Sorcerer"
		elseif relationship.Role == "Teacher" then
			relationship.Age = math.max(relationship.Age or 25, 25)
			relationship.Grade = relationship.Grade ~= "Non-Sorcerer" and relationship.Grade or pickRandom({ "Grade 2", "Semi-Grade 1", "Grade 1" })
			relationship.CursedEnergy = math.max(relationship.CursedEnergy or 0, math.random(60, 140))
		elseif relationship.Role == "Child" then
			relationship.Age = relationship.Age or 0
			-- Self-heal existing saves where YearsKnown drifted from Age (see
			-- AdvanceRelationshipYears) instead of waiting for the next age-up.
			relationship.YearsKnown = relationship.Age
			relationship.IsChild = true
			relationship.CursedEnergy = relationship.CursedEnergy or math.random(1, 45)
			relationship.CursedTechnique = relationship.CursedTechnique or "None"
			relationship.OtherParentName = relationship.OtherParentName or relationship.CoParentName or relationship.SecondParentName or "Unknown"
			relationship.CoParentName = relationship.CoParentName or relationship.OtherParentName or "Unknown"
			relationship.Custody = relationship.Custody or "With You"
			relationship.CustodyParentName = relationship.CustodyParentName or "You"
			relationship.LastCustodyChangeAge = relationship.LastCustodyChangeAge or 0
			relationship.CustodyHistory = relationship.CustodyHistory or {}
			if relationship.CanInheritTechnique == nil then
				relationship.CanInheritTechnique = true
			end
		elseif relationship.Role == "Ward" then
			relationship.Age = relationship.Age or math.random(1, 5)
			relationship.IsWard = true
			relationship.Romance = 0
			relationship.CursedEnergy = relationship.CursedEnergy or math.random(1, 35)
			relationship.CursedTechnique = relationship.CursedTechnique or "None"
			if relationship.CanInheritTechnique == nil then
				relationship.CanInheritTechnique = true
			end
		elseif relationship.Role == "Student" then
			relationship.Romance = 0
			relationship.IsClanStudent = relationship.IsClanStudent or false
			relationship.CursedEnergy = relationship.CursedEnergy or math.random(5, 70)
			relationship.CursedTechnique = relationship.CursedTechnique or "None"
		end

		sanitizeRomance(relationship)
	end
end

local function killRelationship(relationship, cause, text)
	if not relationship or relationship.Alive == false then
		return false
	end

	relationship.Alive = false
	relationship.DeathCause = cause or "Unknown circumstances"
	relationship.DeathText = text or (relationship.Name .. " died.")
	relationship.Romance = relationship.Role == "Spouse" and relationship.Romance or 0
	return true
end

local NPC_TRAIT_RARITY_VALUE = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
}

local NPC_GRADE_THRESHOLDS = {
	{ Grade = "Special Grade", CE = 1000, MinTraitRarity = "Rare" },
	{ Grade = "Grade 1", CE = 1200, MinTraitRarity = "Uncommon" },
	{ Grade = "Semi-Grade 1", CE = 1000 },
	{ Grade = "Grade 2", CE = 800 },
	{ Grade = "Semi-Grade 2", CE = 650 },
	{ Grade = "Grade 3", CE = 450 },
	{ Grade = "Grade 4", CE = 200 },
}

local function relationshipHasTraitRarityAtLeast(relationship, minimumRarity)
	local needed = NPC_TRAIT_RARITY_VALUE[minimumRarity] or 0
	if needed <= 0 then
		return true
	end

	for _, traitId in ipairs(typeof(relationship and relationship.Traits) == "table" and relationship.Traits or {}) do
		local trait = BitKaisenTraits.GetTrait(traitId)
		if trait and (NPC_TRAIT_RARITY_VALUE[trait.Rarity] or 0) >= needed then
			return true
		end
	end

	return false
end

local function getNPCGradeForProgression(relationship)
	local ce = tonumber(relationship and relationship.CursedEnergy) or 0
	for _, threshold in ipairs(NPC_GRADE_THRESHOLDS) do
		if ce >= threshold.CE and relationshipHasTraitRarityAtLeast(relationship, threshold.MinTraitRarity) then
			return threshold.Grade
		end
	end
	return "Non-Sorcerer"
end

local function isSorcererLikeRelationship(relationship)
	local role = tostring(relationship and relationship.Role or "")
	local path = tostring(relationship and relationship.WorldPath or "")
	local grade = tostring(relationship and relationship.Grade or "")
	return path == "Sorcerer"
		or path == "Rogue Sorcerer"
		or path == "Teacher"
		or role == "Teacher"
		or role == "Student"
		or role == "Rival"
		or role == "Classmate"
		or grade ~= "" and grade ~= "Non-Sorcerer"
end

local function ensureIndependentPartner(relationship)
	if not relationship then
		return "their partner"
	end

	if not relationship.IndependentPartnerName or relationship.IndependentPartnerName == "" then
		local partnerGender = relationship.Gender == "Male" and "Female" or "Male"
		relationship.IndependentPartnerName = makeName(nil, partnerGender)
	end

	return tostring(relationship.IndependentPartnerName)
end

local function addIndependentChild(stats, relationship)
	if not relationship then
		return nil
	end

	local gender = rollGender()
	local inheritedFamily = tostring(relationship.Name or ""):match("%s([^%s]+)$") or stats.FamilyName
	local child = {
		Name = makeName(inheritedFamily, gender),
		Gender = gender,
		Age = 0,
		CursedEnergy = math.clamp(math.floor(((tonumber(relationship.CursedEnergy) or 0) * 0.18) + math.random(1, 28)), 1, 260),
		CursedTechnique = math.random(1, 100) <= 18 and tostring(relationship.CursedTechnique or "None") or "None",
		BornYear = tonumber(stats and stats.Year) or nil,
	}

	relationship.IndependentChildren = relationship.IndependentChildren or {}
	table.insert(relationship.IndependentChildren, child)
	relationship.IndependentChildCount = #relationship.IndependentChildren
	relationship.HasIndependentChild = true
	relationship.FamilyStatus = "Has a family"
	return child
end

local function getLivingWorldDeathText(relationship, path)
	local name = tostring(relationship and relationship.Name or "Someone")
	local grade = tostring(relationship and relationship.Grade or "Non-Sorcerer")
	path = tostring(path or relationship and relationship.WorldPath or "")

	if path == "Rogue Sorcerer" then
		return "Rogue sorcerer conflict", name .. " died permanently after a rogue sorcerer conflict turned lethal."
	elseif path == "Teacher" then
		return "Student protection mission", name .. " died permanently protecting students during a curse incident."
	elseif path == "Sorcerer" and (grade == "Grade 1" or grade == "Special Grade") then
		return "High-risk mission", name .. " died permanently on a high-risk assignment that society tried to keep quiet."
	elseif path == "Sorcerer" then
		return "Mission incident", name .. " died permanently during a cursed spirit mission."
	elseif path == "Curse" then
		return "Exorcised", name .. " was exorcised and vanished from the living world."
	end

	return "Living-world incident", name .. " died permanently during a dangerous living-world incident."
end

local function rollNPCWorldPath(relationship)
	local role = tostring(relationship.Role or "")
	local age = tonumber(relationship.Age) or 0
	local ce = tonumber(relationship.CursedEnergy) or 0

	if relationship.WorldPath and relationship.WorldPath ~= "" then
		return false
	end

	if relationship.IsCurse == true or tostring(relationship.Race or "") == "Cursed Spirit" then
		relationship.WorldPath = "Curse"
		relationship.Occupation = relationship.Occupation or "Cursed Spirit"
		return true
	end

	if role == "Teacher" then
		relationship.WorldPath = "Teacher"
		relationship.Occupation = "Jujutsu Teacher"
		return true
	end

	if age < 14 and role ~= "Student" and role ~= "Classmate" then
		return false
	end

	if role == "Rival" and math.random(1, 100) <= 28 then
		relationship.WorldPath = "Rogue Sorcerer"
		relationship.Occupation = "Rogue Sorcerer"
		return true
	end

	if role == "Child" and age >= 12 and ce >= 120 then
		relationship.WorldPath = "Sorcerer"
		relationship.Occupation = "Clan Heir"
		relationship.FamilyCareer = "Clan Heir"
		relationship.CanJoinDojo = true
		relationship.CanJoinClan = true
		return true
	end

	if ce >= 200 or role == "Student" or role == "Classmate" then
		relationship.WorldPath = "Sorcerer"
		relationship.Occupation = role == "Student" and "Jujutsu Student" or "Sorcerer"
		return true
	end

	if age >= 18 then
		relationship.WorldPath = "Civilian"
		relationship.Occupation = relationship.Occupation or pickRandom({ "Office Worker", "Shop Staff", "Paramedic", "Teacher", "Mechanic", "Courier", "Cook", "Security Guard" })
		return true
	end

	return false
end

local function advanceLivingWorldRelationship(stats, relationship, messages)
	if not relationship or relationship.Alive == false then
		return false
	end

	local changed = rollNPCWorldPath(relationship)
	local age = tonumber(relationship.Age) or 0
	local oldGrade = tostring(relationship.Grade or "Non-Sorcerer")
	local path = tostring(relationship.WorldPath or "")
	local sorcererLike = isSorcererLikeRelationship(relationship)
	local role = tostring(relationship.Role or "")

	if role == "Child" then
		relationship.CEBaseline = math.max(tonumber(relationship.CEBaseline) or 0, tonumber(relationship.CursedEnergy) or 0)
		relationship.CanJoinDojo = relationship.CanJoinDojo ~= false
		relationship.CanJoinClan = relationship.CanJoinClan ~= false
		relationship.DojoEligible = relationship.CanJoinDojo == true and age >= 8
		relationship.ClanEligible = relationship.CanJoinClan == true
		if age >= 16 and tostring(relationship.FamilyCareer or "Undecided") == "Undecided" then
			relationship.FamilyCareer = sorcererLike and "Sorcerer Candidate" or pickRandom({ "Student", "Civilian Apprentice", "Family Support" })
			changed = true
		end
	end

	if sorcererLike then
		local ceGain = math.random(6, 18)
		if path == "Teacher" then
			ceGain += math.random(4, 12)
		elseif path == "Rogue Sorcerer" then
			ceGain += math.random(2, 10)
		elseif role == "Student" or role == "Child" then
			ceGain += math.random(4, 8)
		end

		relationship.CursedEnergy = math.clamp((tonumber(relationship.CursedEnergy) or 0) + ceGain, 0, 3000)
		relationship.TechniqueMastery = math.clamp((tonumber(relationship.TechniqueMastery) or 0) + math.random(1, 5), 0, 100)
		changed = true

		if tostring(relationship.CursedTechnique or "None") == "None" and relationship.CursedEnergy >= 450 and math.random(1, 100) <= 16 then
			local technique = pickRandom(TECHNIQUES)
			if technique ~= "None" then
				relationship.CursedTechnique = technique
				table.insert(messages, relationship.Name .. " awakened " .. technique .. " while growing outside your direct control.")
			end
		end
	end

	local newGrade = getNPCGradeForProgression(relationship)
	if newGrade ~= "Non-Sorcerer" and newGrade ~= oldGrade then
		relationship.Grade = newGrade
		relationship.Status = tostring(relationship.Status or "") ~= "" and relationship.Status or newGrade
		if role == "Child" then
			relationship.FamilyCareer = "Sorcerer Candidate"
			relationship.DojoEligible = relationship.CanJoinDojo ~= false
			relationship.ClanEligible = relationship.CanJoinClan ~= false
		end
		table.insert(messages, relationship.Name .. " rose to " .. newGrade .. " through their own progression.")
		changed = true
	end

	if path == "Sorcerer" and age >= 24 and relationship.Grade == "Grade 1" and math.random(1, 100) <= 7 then
		relationship.WorldPath = "Teacher"
		relationship.Occupation = "Jujutsu Teacher"
		relationship.Role = relationship.Role == "Friend" and "Teacher" or relationship.Role
		table.insert(messages, relationship.Name .. " accepted a teaching role in the jujutsu world.")
		changed = true
	elseif path == "Sorcerer" and math.random(1, 100) <= 3 then
		relationship.WorldPath = "Rogue Sorcerer"
		relationship.Occupation = "Rogue Sorcerer"
		table.insert(messages, relationship.Name .. " drifted away from Jujutsu High and became a rogue sorcerer.")
		changed = true
	end

	if age >= 20 and relationship.MarriedIndependently ~= true and relationship.Role ~= "Spouse" and relationship.Role ~= "Partner" and math.random(1, 100) <= 4 then
		local partnerName = ensureIndependentPartner(relationship)
		relationship.MarriedIndependently = true
		relationship.FamilyStatus = "Married independently"
		table.insert(messages, relationship.Name .. " married " .. partnerName .. " and started building a life of their own.")
		changed = true
	elseif relationship.MarriedIndependently == true and math.random(1, 100) <= 3 then
		local child = addIndependentChild(stats, relationship)
		if child then
			table.insert(messages, relationship.Name .. " and " .. ensureIndependentPartner(relationship) .. " had a child named " .. child.Name .. ".")
			changed = true
		end
	end

	if path == "Civilian" and age >= 22 and math.random(1, 100) <= 5 then
		local oldOccupation = tostring(relationship.Occupation or "Civilian")
		relationship.Occupation = pickRandom({ "Clinic Director", "Shop Owner", "Senior Teacher", "Rescue Worker", "Security Lead", "Local Official", "Researcher" })
		relationship.FamilyCareer = relationship.Occupation
		if relationship.Occupation ~= oldOccupation then
			table.insert(messages, relationship.Name .. " advanced their civilian career and became a " .. relationship.Occupation .. ".")
			changed = true
		end
	end

	local eventDeathChance = 0
	if path == "Rogue Sorcerer" then
		eventDeathChance = 3
	elseif path == "Teacher" or path == "Sorcerer" then
		eventDeathChance = 2
	elseif path == "Curse" then
		eventDeathChance = 1
	end

	if eventDeathChance > 0 and math.random(1, 100) <= eventDeathChance then
		local cause, text = getLivingWorldDeathText(relationship, path)
		if killRelationship(relationship, cause, text) then
			table.insert(messages, text)
			changed = true
		end
	end

	return changed
end

function BitKaisenRelationships.AdvanceRelationshipYears(stats)
	BitKaisenRelationships.EnsureRelationships(stats)

	local playerAge = math.max(0, tonumber(stats.Age) or 0)
	local lastAdvancedAtAge = tonumber(stats.LastRelationshipAdvancePlayerAge)
	local currentMonth = tonumber(stats.CurrentMonth) or 1
	local monthsIntoAge = tonumber(stats.MonthsIntoAge) or 0

	if lastAdvancedAtAge == playerAge then
		return nil
	end

	-- GameManager advances relationship years before incrementing the player's age,
	-- then can roll a relationship age event after the age flips to January. That
	-- follow-up belongs to the same year, so stamp it without aging NPCs again.
	if lastAdvancedAtAge and playerAge == lastAdvancedAtAge + 1 and currentMonth == 1 and monthsIntoAge == 0 then
		stats.LastRelationshipAdvancePlayerAge = playerAge
		return nil
	end

	stats.LastRelationshipAdvancePlayerAge = playerAge

	local messages = {}
	local changed = false

	for _, relationship in ipairs(stats.Relationships) do
		if relationship.Alive ~= false then
			changed = true
			relationship.YearsKnown = (relationship.YearsKnown or 0) + 1

			if relationship.Age ~= nil then
				relationship.Age += 1
			end

			-- A child has been known for exactly as long as they've been alive.
			-- YearsKnown/Age can drift apart (e.g. a Brain Transplant jump in the
			-- player's own Age doesn't touch a child's Age, which is tracked from
			-- birth, but YearsKnown above still increments every real year) --
			-- force the invariant here instead of chasing every divergence path.
			if relationship.Role == "Child" and relationship.Age ~= nil then
				relationship.YearsKnown = relationship.Age
			end

			if relationship.Role == "Partner" then
				relationship.YearsDating = (relationship.YearsDating or 0) + 1
			end

			if relationship.Role == "Spouse" then
				relationship.YearsMarried = (relationship.YearsMarried or 0) + 1
			end

			if relationship.Role == "Ex-Spouse" then
				relationship.YearsDivorced = (relationship.YearsDivorced or 0) + 1
				relationship.Romance = 0
			end

			if relationship.Role == "Child" then
				relationship.IsChild = true
				relationship.Romance = 0

				if (relationship.Age or 0) >= 18 and relationship.Custody ~= "Independent" then
					relationship.Custody = "Independent"
					relationship.CustodyParentName = nil
					relationship.LastCustodyChangeAge = stats.Age or relationship.Age or 18
					relationship.CustodyHistory = relationship.CustodyHistory or {}
					table.insert(relationship.CustodyHistory, relationship.Name .. " became an adult and no longer needs custody arrangements.")
				end
			end

			sanitizeRomance(relationship)
			if advanceLivingWorldRelationship(stats, relationship, messages) then
				changed = true
			end

			local deathChance = 0
			local age = relationship.Age or 0
			local role = relationship.Role
			local relOrigin = tostring(relationship.Origin or relationship.Clan or "")
			local relRace = tostring(relationship.Race or "")
			local relCurseType = tostring(relationship.CurseType or "")
			local relFamilyType = tostring(relationship.FamilyType or "")
			local isCursedSpiritRelationship = relationship.IsCurse == true
				or relRace == "Cursed Spirit"
				or relRace == "Curse"
				or string.find(relOrigin, "Cursed Spirit", 1, true) ~= nil
				or string.find(relOrigin, "Curse", 1, true) ~= nil
				or string.find(relCurseType, "Cursed Spirit", 1, true) ~= nil
				or relCurseType == "Curse"
				or relFamilyType == "Cursed Spirit"
				or relFamilyType == "Curse"

			if age >= 75 and not isCursedSpiritRelationship then
				deathChance += math.clamp(age - 74, 1, 18)
			end

			if role == "Teacher" or role == "Mission Partner" then
				deathChance += 1
			elseif role == "Rival" then
				deathChance += 1
			end

			if role == "Child" and age < 18 then
				deathChance = 0
			end

			if deathChance > 0 and math.random(1, 100) <= deathChance then
				local cause = "Natural causes"
				local text = relationship.Name .. " passed away."

				if role == "Teacher" or role == "Mission Partner" or role == "Rival" then
					cause = "Curse incident"
					text = relationship.Name .. " died during a curse-related incident."
				elseif age >= 75 and not isCursedSpiritRelationship then
					cause = "Old age"
					text = relationship.Name .. " passed away after living a long life."
				end

				if killRelationship(relationship, cause, text) then
					changed = true
					table.insert(messages, text)
				end
			end
		end
	end

	if changed then
		markRelationshipsDirty(stats)
	end

	if #messages > 0 then
		return table.concat(messages, "\n")
	end

	return nil
end

local function isProtectedRelationshipForCap(relationship)
	local role = tostring(relationship and relationship.Role or "")
	local protectedRoles = {
		Mother = true,
		Father = true,
		Caretaker = true,
		Child = true,
		Ward = true,
		Spouse = true,
		Partner = true,
		Teacher = true,
		Student = true,
		["Best Friend"] = true,
	}

	return protectedRoles[role] == true or relationship.Alive == false
end

function BitKaisenRelationships.PruneRelationships(stats, maxActive)
	BitKaisenRelationships.EnsureRelationships(stats)
	maxActive = tonumber(maxActive) or MAX_ACTIVE_RELATIONSHIPS

	local activeCount = 0
	local candidates = {}

	for index, relationship in ipairs(stats.Relationships) do
		if relationship.Alive ~= false then
			activeCount += 1
			if not isProtectedRelationshipForCap(relationship) then
				local strength = (tonumber(relationship.Bond) or 0) + (tonumber(relationship.Trust) or 0) + (tonumber(relationship.Respect) or 0)
				local known = tonumber(relationship.YearsKnown) or 0
				table.insert(candidates, {
					Index = index,
					Score = strength + (known * 4),
				})
			end
		end
	end

	if activeCount <= maxActive or #candidates <= 0 then
		return 0
	end

	table.sort(candidates, function(a, b)
		if a.Score == b.Score then
			return a.Index > b.Index
		end
		return a.Score < b.Score
	end)

	local removeCount = math.min(activeCount - maxActive, #candidates)
	local removeIndexes = {}
	for i = 1, removeCount do
		removeIndexes[candidates[i].Index] = true
	end

	local filtered = {}
	for index, relationship in ipairs(stats.Relationships) do
		if not removeIndexes[index] then
			table.insert(filtered, relationship)
		end
	end

	stats.Relationships = filtered
	markRelationshipsDirty(stats)
	return removeCount
end

function BitKaisenRelationships.AddRelationship(stats, relationship)
	BitKaisenRelationships.EnsureRelationships(stats)
	relationship.Gender = normalizeGender(relationship.Gender, relationship.Role)
	assignProfileDefaults(relationship)
	if relationship.MetAtAge == nil then
		relationship.MetAtAge = math.max(0, tonumber(stats.Age) or 0)
	end
	if relationship.AgeAtMet == nil and relationship.Age ~= nil then
		relationship.AgeAtMet = math.max(0, tonumber(relationship.Age) or 0)
	end
	reconcileRelationshipTimeline(stats, relationship)
	sanitizeRomance(relationship)
	table.insert(stats.Relationships, relationship)
	BitKaisenRelationships.PruneRelationships(stats)
	markRelationshipsDirty(stats)
	return relationship
end

function BitKaisenRelationships.HasRole(stats, role)
	BitKaisenRelationships.EnsureRelationships(stats)

	for _, relationship in ipairs(stats.Relationships) do
		if relationship.Role == role and relationship.Alive ~= false then
			return true
		end
	end

	return false
end

function BitKaisenRelationships.GetByRole(stats, role)
	BitKaisenRelationships.EnsureRelationships(stats)

	local matches = {}

	for _, relationship in ipairs(stats.Relationships) do
		if relationship.Role == role and relationship.Alive ~= false then
			table.insert(matches, relationship)
		end
	end

	if #matches <= 0 then
		return nil
	end

	return matches[math.random(1, #matches)]
end

function BitKaisenRelationships.GetSpouse(stats)
	return BitKaisenRelationships.GetByRole(stats, "Spouse")
end

function BitKaisenRelationships.GetPartner(stats)
	return BitKaisenRelationships.GetByRole(stats, "Partner")
end

function BitKaisenRelationships.HasChild(stats)
	return BitKaisenRelationships.HasRole(stats, "Child")
end

local function getBirthPathValue(stats, key, fallback)
	if typeof(stats) ~= "table" then
		return fallback
	end

	if typeof(stats.BirthPath) == "table" and stats.BirthPath[key] ~= nil then
		return stats.BirthPath[key]
	end

	if stats[key] ~= nil then
		return stats[key]
	end

	return fallback
end

local function getStartingUpbringing(stats)
	return tostring(getBirthPathValue(stats, "Upbringing", "Normal Household"))
end

local function getStartingOrigin(stats)
	return tostring(stats and (stats.Origin or stats.Clan) or "Minor Sorcerer Family")
end

local function shouldSuppressBirthParents(stats)
	local upbringing = getStartingUpbringing(stats)
	local origin = getStartingOrigin(stats)
	local originCategory = tostring(stats and stats.OriginCategory or "")
	local familyType = tostring(stats and stats.FamilyType or "")
	local race = tostring(stats and stats.Race or "")
	local curseType = tostring(stats and stats.CurseType or "")

	if origin == "Cursed Womb"
		or origin == "Vengeful Spirit Rebirth"
		or origin == "Cursed Spirit Rebirth"
		or origin == "Cursed Rebirth"
		or origin == "Cursed Spirit"
		or origin == "Curse"
		or race == "Cursed Spirit"
		or race == "Curse"
		or curseType == "Cursed Womb"
		or curseType == "Cursed Spirit"
		or curseType == "Vengeful Cursed Spirit"
		or curseType == "Fear-Born Cursed Spirit"
		or curseType == "Death-Bound Cursed Spirit"
		or familyType == "Cursed Spirit"
		or familyType == "Curse"
		or (originCategory == "Race" and (origin == "Cursed Spirit" or origin == "Curse")) then
		return true
	end

	if upbringing == "Orphanage" or upbringing == "Street Kid" or upbringing == "Shrine Raised" then
		return true
	end

	return false
end

local function shouldHaveStartingCaretaker(stats)
	local upbringing = getStartingUpbringing(stats)
	local origin = getStartingOrigin(stats)
	local curseType = tostring(stats and stats.CurseType or "")

	if origin == "Cursed Womb" or curseType == "Cursed Womb" then
		return true
	end

	if upbringing == "Orphanage" or upbringing == "Shrine Raised" then
		return true
	end

	-- Street Kid should not receive normal parents. A rare low-trust caretaker/contact
	-- keeps the relationships page from feeling empty without implying a stable home.
	if upbringing == "Street Kid" then
		return math.random(1, 100) <= 35
	end

	return false
end

local function getCaretakerProfile(stats)
	local upbringing = getStartingUpbringing(stats)
	local origin = getStartingOrigin(stats)
	local curseType = tostring(stats and stats.CurseType or "")

	if origin == "Cursed Womb" or curseType == "Cursed Womb" then
		return {
			Status = "Nervous Guardian",
			BondMin = 35,
			BondMax = 60,
			TrustMin = 20,
			TrustMax = 50,
			RespectMin = 15,
			RespectMax = 45,
			FearMin = 25,
			FearMax = 65,
			AgeMin = 25,
			AgeMax = 50,
			Background = "They found you before the jujutsu world fully understood what you were."
		}
	end

	if upbringing == "Orphanage" then
		return {
			Status = "Orphanage Caretaker",
			BondMin = 30,
			BondMax = 65,
			TrustMin = 25,
			TrustMax = 60,
			RespectMin = 20,
			RespectMax = 55,
			FearMin = 0,
			FearMax = 18,
			AgeMin = 28,
			AgeMax = 58,
			Background = "They helped raise you at the orphanage. They are not your parent, but they shaped your early life."
		}
	end

	if upbringing == "Street Kid" then
		return {
			Status = "Street Contact",
			BondMin = 12,
			BondMax = 38,
			TrustMin = 8,
			TrustMax = 32,
			RespectMin = 15,
			RespectMax = 45,
			FearMin = 0,
			FearMax = 25,
			AgeMin = 18,
			AgeMax = 45,
			Background = "They looked out for you sometimes, but the streets raised you more than any household did."
		}
	end

	if upbringing == "Shrine Raised" then
		return {
			Status = "Shrine Guardian",
			BondMin = 28,
			BondMax = 62,
			TrustMin = 22,
			TrustMax = 58,
			RespectMin = 35,
			RespectMax = 80,
			FearMin = 0,
			FearMax = 22,
			AgeMin = 30,
			AgeMax = 68,
			Background = "They watched over the shrine that raised you. Your childhood was ritual, silence, and old rules."
		}
	end

	return {
		Status = "Caretaker",
		BondMin = 30,
		BondMax = 60,
		TrustMin = 25,
		TrustMax = 55,
		RespectMin = 20,
		RespectMax = 55,
		FearMin = 0,
		FearMax = 15,
		AgeMin = 25,
		AgeMax = 55,
		Background = "They were responsible for you during your early life."
	}
end

local function hasAliveRole(stats, role)
	if typeof(stats) ~= "table" or typeof(stats.Relationships) ~= "table" then
		return false
	end

	for _, relationship in ipairs(stats.Relationships) do
		if relationship and relationship.Role == role and relationship.Alive ~= false then
			return true
		end
	end

	return false
end

local function removeStartingParentRolesForUpbringing(stats)
	if typeof(stats) ~= "table" or typeof(stats.Relationships) ~= "table" then
		return
	end

	if not shouldSuppressBirthParents(stats) then
		return
	end

	local filtered = {}

	for _, relationship in ipairs(stats.Relationships) do
		local role = tostring(relationship and relationship.Role or "")

		if role ~= "Mother" and role ~= "Father" then
			table.insert(filtered, relationship)
		end
	end

	stats.Relationships = filtered
end

local function addStartingCaretakerIfNeeded(stats)
	if typeof(stats) ~= "table" then
		return nil
	end

	if hasAliveRole(stats, "Caretaker") then
		return nil
	end

	if not shouldHaveStartingCaretaker(stats) then
		return nil
	end

	local profile = getCaretakerProfile(stats)
	local caretakerGender = rollGender()
	local caretaker = BitKaisenRelationships.CreateRelationship(
		"Caretaker",
		makeName(nil, caretakerGender),
		profile.Status or "Caretaker",
		math.random(profile.BondMin or 30, profile.BondMax or 60),
		math.random(profile.TrustMin or 20, profile.TrustMax or 55),
		math.random(profile.RespectMin or 15, profile.RespectMax or 55),
		math.random(profile.FearMin or 0, profile.FearMax or 20),
		0,
		caretakerGender
	)

	caretaker.Age = math.random(profile.AgeMin or 25, profile.AgeMax or 55)
	caretaker.Background = profile.Background or "They were responsible for you during your early life."
	caretaker.Romance = 0

	return BitKaisenRelationships.AddRelationship(stats, caretaker)
end

local SIBLING_BACKGROUNDS = {
	"Grew up in the same house, watching the same family pressure shape both of you.",
	"Was always one step ahead growing up, for better or worse.",
	"Shared a room with you for years before either of you understood what your family really was.",
	"Knows the family history almost as well as you do, just from a different angle.",
	"Was the one who taught you most of what you knew before anyone official did.",
}

local function addStartingSiblings(stats, familyName)
	if math.random(1, 100) > 40 then
		return
	end

	local siblingCount = math.random(1, 100) <= 20 and 2 or 1

	for _ = 1, siblingCount do
		local siblingGender = rollGender()
		local sibling = BitKaisenRelationships.CreateRelationship(
			"Sibling",
			makeName(familyName, siblingGender),
			"Sibling",
			math.random(40, 80),
			math.random(35, 75),
			math.random(20, 60),
			0,
			0,
			siblingGender
		)

		sibling.Gender = siblingGender
		-- 90% chance of an older sibling (1-14 yrs), 10% chance of a twin (age 0).
		sibling.Age = math.random(1, 100) <= 10 and 0 or math.random(1, 14)
		sibling.Background = pickRandom(SIBLING_BACKGROUNDS)
		sibling.YearsKnown = 0
		ensureRelationshipTraits(stats, sibling)

		BitKaisenRelationships.AddRelationship(stats, sibling)
	end
end

function BitKaisenRelationships.GenerateStartingRelationships(stats)
	BitKaisenRelationships.EnsureRelationships(stats)

	removeStartingParentRolesForUpbringing(stats)

	if #stats.Relationships > 0 then
		addStartingCaretakerIfNeeded(stats)
		return
	end

	local familyName = stats.FamilyName

	if shouldSuppressBirthParents(stats) then
		addStartingCaretakerIfNeeded(stats)
		return
	end

	addStartingSiblings(stats, familyName)

	local mother = BitKaisenRelationships.CreateRelationship(
		"Mother",
		makeName(familyName, "Female"),
		"Family",
		math.random(45, 80),
		math.random(35, 75),
		math.random(20, 60),
		0,
		0,
		"Female"
	)
	mother.Gender = "Female"
	mother.Age = math.random(24, 34)
	mother.Background = "She is tied to your earliest memories and the family you were born into."
	BitKaisenRelationships.AddRelationship(stats, mother)

	local father = BitKaisenRelationships.CreateRelationship(
		"Father",
		makeName(familyName, "Male"),
		"Family",
		math.random(40, 78),
		math.random(30, 72),
		math.random(25, 65),
		0,
		0,
		"Male"
	)
	father.Gender = "Male"
	father.Age = math.random(26, 38)
	father.Background = "He carries part of the pressure and history connected to your family name."
	BitKaisenRelationships.AddRelationship(stats, father)
end

function BitKaisenRelationships.AddTeacher(stats)
	BitKaisenRelationships.EnsureRelationships(stats)

	local teacher = BitKaisenRelationships.CreateRelationship(
		"Teacher",
		makeName(nil, rollGender()),
		"Jujutsu High Instructor",
		math.random(25, 55),
		math.random(25, 60),
		math.random(55, 90),
		math.random(5, 25),
		0
	)

	teacher.Gender = teacher.Gender or rollGender()
	teacher.Age = math.random(27, 55)
	teacher.Grade = pickRandom({ "Grade 2", "Semi-Grade 1", "Grade 1" })
	teacher.CursedEnergy = math.random(70, 180)
	teacher.CursedTechnique = pickRandom(TECHNIQUES)
	if teacher.CursedTechnique == "None" then
		teacher.CursedTechnique = "Barrier Specialist"
	end
	teacher.Background = "They were assigned to watch your growth inside the jujutsu world."
	ensureRelationshipTraits(stats, teacher)

	return BitKaisenRelationships.AddRelationship(stats, teacher)
end

function BitKaisenRelationships.AddFriend(stats)
	BitKaisenRelationships.EnsureRelationships(stats)

	local role = "Friend"

	if stats.InJujutsuHigh and math.random(1, 100) <= 55 then
		role = "Classmate"
	end

	local friend = BitKaisenRelationships.CreateRelationship(
		role,
		makeName(nil, rollGender()),
		role == "Classmate" and "Jujutsu High Student" or "Friend",
		math.random(45, 75),
		math.random(35, 70),
		math.random(25, 65),
		math.random(0, 20),
		0
	)

	friend.Gender = friend.Gender or rollGender()
	friend.Age = math.max(6, (stats.Age or 12) + math.random(-2, 3))

	if role == "Classmate" then
		friend.Grade = pickRandom({ "Grade 4", "Semi-Grade 3", "Grade 3" })
		friend.CursedEnergy = math.random(25, 80)
		friend.CursedTechnique = pickRandom(TECHNIQUES)
	end

	ensureRelationshipTraits(stats, friend)
	return BitKaisenRelationships.AddRelationship(stats, friend)
end

function BitKaisenRelationships.AddRival(stats)
	BitKaisenRelationships.EnsureRelationships(stats)

	if BitKaisenRelationships.HasRole(stats, "Rival") and math.random(1, 100) <= 60 then
		return nil
	end

	local rival = BitKaisenRelationships.CreateRelationship(
		"Rival",
		makeName(nil, rollGender()),
		"Competitive Rival",
		math.random(10, 40),
		math.random(5, 35),
		math.random(45, 85),
		math.random(0, 25),
		0
	)

	rival.Gender = rival.Gender or rollGender()
	rival.Age = math.max(10, (stats.Age or 15) + math.random(-2, 4))
	rival.Grade = pickRandom({ "Grade 4", "Semi-Grade 3", "Grade 3", "Semi-Grade 2" })
	rival.CursedEnergy = math.random(35, 110)
	rival.CursedTechnique = pickRandom(TECHNIQUES)
	rival.Background = "They see your growth as a challenge to their own reputation."
	ensureRelationshipTraits(stats, rival)

	return BitKaisenRelationships.AddRelationship(stats, rival)
end

function BitKaisenRelationships.AddChild(stats, childName, otherParentName)
	BitKaisenRelationships.EnsureRelationships(stats)

	local familyName = stats.FamilyName or "Unknown"
	local childGender = rollGender()
	local name = childName or makeName(familyName, childGender)

	local child = BitKaisenRelationships.CreateRelationship(
		"Child",
		name,
		"Family",
		math.random(55, 80),
		math.random(45, 70),
		math.random(5, 20),
		0,
		0,
		childGender
	)

	child.Gender = childGender
	child.Age = 0
	child.IsChild = true
	child.Romance = 0
	child.Grade = "Non-Sorcerer"
	child.CursedEnergy = math.random(1, 45)
	child.CursedTechnique = "None"
	child.CanInheritTechnique = true
	child.OtherParentName = otherParentName or "Unknown"
	child.CoParentName = otherParentName or "Unknown"
	child.Custody = "With You"
	child.CustodyParentName = stats.Name or "You"
	child.CanJoinDojo = true
	child.CanJoinClan = true
	child.DojoEligible = true
	child.ClanEligible = true
	child.FamilyCareer = "Undecided"
	child.IndependentProgression = true
	child.LastCustodyChangeAge = stats.Age or 0
	child.CustodyHistory = {
		"Born into your household."
	}
	child.Background = "They are part of your legacy. Their path has not fully formed yet."

	local coParent = BitKaisenRelationships.GetSpouse(stats) or BitKaisenRelationships.GetPartner(stats)
	child.PlayerParentName = stats.Name or stats.FullName or "You"
	child.PlayerParentGender = tostring(stats.Gender or "Unknown")
	child.OtherParentGender = coParent and tostring(coParent.Gender or "Unknown") or "Unknown"
	child.CoParentGender = child.OtherParentGender
	applyInheritedClanPotential(stats, child, coParent)
	child.Traits = BitKaisenTraits.RollInheritedTraits(stats, child, coParent)
	child.TraitPoolInherited = true
	child.InheritanceProfile = child.InheritanceProfile or {}
	child.InheritanceProfile.TraitCount = typeof(child.Traits) == "table" and #child.Traits or 0
	child.InheritanceProfile.Technique = tostring(child.InheritedTechnique or child.InnateTechnique or "None")
	BitKaisenTraits.ApplyStartingBonuses(child)
	child.TraitSummary = BitKaisenTraits.GetTraitDisplay(child)

	if not isRealTechnique(child.InheritedTechnique) and stats.CursedTechnique and stats.CursedTechnique ~= "None" then
		local inheritChance = 20

		if stats.FamilyType == "Sorcerer" then
			inheritChance += 10
		end

		if math.random(1, 100) <= inheritChance then
			child.CursedTechnique = stats.CursedTechnique
			child.InheritedTechnique = stats.CursedTechnique
			child.CursedEnergy += math.random(10, 25)
		end
	end

	return BitKaisenRelationships.AddRelationship(stats, child)
end


function BitKaisenRelationships.GetChildren(stats)
	BitKaisenRelationships.EnsureRelationships(stats)

	local children = {}
	for _, relationship in ipairs(stats.Relationships) do
		if relationship.Role == "Child" and relationship.Alive ~= false then
			table.insert(children, relationship)
		end
	end

	return children
end

function BitKaisenRelationships.ApplyDivorceCustody(stats, exSpouse)
	BitKaisenRelationships.EnsureRelationships(stats)

	local result = {
		Total = 0,
		WithYou = 0,
		Shared = 0,
		WithEx = 0,
		Independent = 0,
		Lines = {}
	}

	if not exSpouse then
		return result
	end

	local exName = tostring(exSpouse.Name or "your ex-spouse")
	local exTrust = tonumber(exSpouse.Trust) or 0
	local exBond = tonumber(exSpouse.Bond) or 0
	local exRespect = tonumber(exSpouse.Respect) or 0
	local exFear = tonumber(exSpouse.Fear) or 0

	for _, child in ipairs(BitKaisenRelationships.GetChildren(stats)) do
		result.Total += 1

		child.OtherParentName = child.OtherParentName or exName
		child.CoParentName = exName
		child.CustodyHistory = child.CustodyHistory or {}
		child.LastCustodyChangeAge = stats.Age or child.Age or 0

		local age = tonumber(child.Age) or 0
		local custody = "Shared"

		if age >= 18 then
			custody = "Independent"
		elseif exFear >= 65 or exTrust <= 25 then
			custody = "With You"
		else
			local roll = math.random(1, 100)
			local sharedChance = 35 + math.floor(exTrust / 5) + math.floor(exBond / 8)
			local exChance = 15 + math.floor(exRespect / 8)

			if exTrust < 45 then
				sharedChance -= 12
				exChance -= 8
			end

			sharedChance = math.clamp(sharedChance, 15, 65)
			exChance = math.clamp(exChance, 5, 35)

			if roll <= sharedChance then
				custody = "Shared"
			elseif roll <= sharedChance + exChance then
				custody = "With Ex-Spouse"
			else
				custody = "With You"
			end
		end

		child.Custody = custody

		if custody == "Shared" then
			child.CustodyParentName = "Shared between you and " .. exName
			result.Shared += 1
			table.insert(result.Lines, child.Name .. ": shared custody")
		elseif custody == "With Ex-Spouse" then
			child.CustodyParentName = exName
			result.WithEx += 1
			table.insert(result.Lines, child.Name .. ": living with " .. exName)
		elseif custody == "Independent" then
			child.CustodyParentName = nil
			result.Independent += 1
			table.insert(result.Lines, child.Name .. ": independent adult")
		else
			child.CustodyParentName = stats.Name or "You"
			result.WithYou += 1
			table.insert(result.Lines, child.Name .. ": living with you")
		end

		table.insert(child.CustodyHistory, "After the divorce, custody became: " .. custody .. ".")
	end

	return result
end

function BitKaisenRelationships.RebalanceCustody(stats, exSpouse)
	BitKaisenRelationships.EnsureRelationships(stats)

	local result = {
		Changed = false,
		Message = "There were no custody arrangements to discuss."
	}

	if not exSpouse then
		return result
	end

	local exName = tostring(exSpouse.Name or "your ex-spouse")
	local children = BitKaisenRelationships.GetChildren(stats)
	local candidates = {}

	for _, child in ipairs(children) do
		if (child.Age or 0) < 18 and child.Alive ~= false then
			table.insert(candidates, child)
		end
	end

	if #candidates <= 0 then
		result.Message = "There are no younger children with custody arrangements to discuss."
		return result
	end

	local child = candidates[math.random(1, #candidates)]
	local currentCustody = tostring(child.Custody or "With You")
	local chance = 30 + math.floor((exSpouse.Trust or 0) / 4) + math.floor((exSpouse.Bond or 0) / 6)
	chance = math.clamp(chance, 20, 75)

	if math.random(1, 100) <= chance then
		if currentCustody == "With Ex-Spouse" then
			child.Custody = "Shared"
			child.CustodyParentName = "Shared between you and " .. exName
			result.Message = "You and " .. exName .. " agreed to move " .. child.Name .. " into shared custody."
		elseif currentCustody == "Shared" then
			child.Custody = "With You"
			child.CustodyParentName = stats.Name or "You"
			result.Message = "You and " .. exName .. " adjusted custody. " .. child.Name .. " now mainly stays with you."
		else
			child.Custody = "Shared"
			child.CustodyParentName = "Shared between you and " .. exName
			result.Message = "You and " .. exName .. " agreed to share custody of " .. child.Name .. "."
		end

		child.LastCustodyChangeAge = stats.Age or child.Age or 0
		child.CustodyHistory = child.CustodyHistory or {}
		table.insert(child.CustodyHistory, "Custody was renegotiated: " .. child.Custody .. ".")
		result.Changed = true
	else
		result.Message = "You tried to discuss custody with " .. exName .. ", but the conversation went nowhere."
	end

	return result
end

function BitKaisenRelationships.AdjustRelationship(relationship, changes)
	if not relationship or not changes then
		return
	end

	relationship.Bond = clampPercent((relationship.Bond or 0) + (changes.Bond or 0))
	relationship.Trust = clampPercent((relationship.Trust or 0) + (changes.Trust or 0))
	relationship.Respect = clampPercent((relationship.Respect or 0) + (changes.Respect or 0))
	relationship.Fear = clampPercent((relationship.Fear or 0) + (changes.Fear or 0))

	if ROMANCE_ALLOWED_ROLES[relationship.Role] then
		relationship.Romance = clampPercent((relationship.Romance or 0) + (changes.Romance or 0))
	else
		relationship.Romance = 0
	end

	sanitizeRomance(relationship)

	if relationship.Bond >= 85 and relationship.Role == "Friend" then
		relationship.Role = "Best Friend"
		relationship.Status = "Best Friend"
	end
end

function BitKaisenRelationships.GetRandomRelationship(stats)
	BitKaisenRelationships.EnsureRelationships(stats)

	local valid = {}

	for _, relationship in ipairs(stats.Relationships) do
		if relationship.Alive ~= false then
			table.insert(valid, relationship)
		end
	end

	if #valid <= 0 then
		return nil
	end

	return valid[math.random(1, #valid)]
end

function BitKaisenRelationships.HandleFamilyActivity(stats)
	BitKaisenRelationships.EnsureRelationships(stats)

	local familyRoles = {
		Mother = true,
		Father = true,
		Sibling = true,
		Caretaker = true,
		Child = true,
		Spouse = true
	}

	local candidates = {}

	for _, relationship in ipairs(stats.Relationships) do
		if relationship.Alive ~= false and familyRoles[relationship.Role] then
			table.insert(candidates, relationship)
		end
	end

	if #candidates <= 0 then
		return "You spent time with your family."
	end

	local chosen = candidates[math.random(1, #candidates)]

	BitKaisenRelationships.AdjustRelationship(chosen, {
		Bond = math.random(4, 9),
		Trust = math.random(2, 6)
	})

	return "You spent time with " .. chosen.Name .. "."
end

function BitKaisenRelationships.HandleSocialize(stats)
	BitKaisenRelationships.EnsureRelationships(stats)

	if stats.InJujutsuHigh and math.random(1, 100) <= 18 then
		local rival = BitKaisenRelationships.AddRival(stats)

		if rival then
			return rival.Name .. " started treating you like a rival after training.", {
				Title = "NEW RIVAL",
				Body = "Someone has started measuring their growth against yours.",
				Highlight = rival.Name,
				Footer = "Rivals can affect your reputation and future events."
			}
		end
	end

	if math.random(1, 100) <= 55 or not BitKaisenRelationships.HasRole(stats, "Friend") then
		local friend = BitKaisenRelationships.AddFriend(stats)

		return "You became friends with " .. friend.Name .. ".", {
			Title = "NEW FRIEND",
			Body = "You made a new connection.",
			Highlight = friend.Name,
			Footer = "This person has been added to your Relationships page."
		}
	end

	local existing = BitKaisenRelationships.GetRandomRelationship(stats)

	if existing then
		BitKaisenRelationships.AdjustRelationship(existing, {
			Bond = math.random(2, 7),
			Trust = math.random(1, 5)
		})

		return "You spent time with " .. existing.Name .. ".", nil
	end

	return "You spent time around people.", nil
end

function BitKaisenRelationships.RollAgeEvent(stats)
	BitKaisenRelationships.EnsureRelationships(stats)

	local age = stats.Age or 0

	if age < 6 then
		return nil, nil
	end

	local yearlyDeathText = BitKaisenRelationships.AdvanceRelationshipYears(stats)
	if yearlyDeathText then
		return yearlyDeathText, {
			Title = "RELATIONSHIP MEMORY",
			Body = "Someone connected to your life passed away.",
			Highlight = "Memory Added",
			Footer = "They remain in your Relationships page under memories."
		}
	end

	local roll = math.random(1, 100)

	if stats.InJujutsuHigh and roll <= 12 then
		local rival = BitKaisenRelationships.AddRival(stats)

		if rival then
			return rival.Name .. " challenged your reputation during training.", {
				Title = "NEW RIVAL",
				Body = "A new rivalry has started.",
				Highlight = rival.Name,
				Footer = "Rivals can become allies, enemies, or long-term competition."
			}
		end
	end

	if roll <= 30 then
		local friend = BitKaisenRelationships.AddFriend(stats)

		return "You became closer with " .. friend.Name .. ".", {
			Title = "NEW RELATIONSHIP",
			Body = "Someone new entered your life.",
			Highlight = friend.Name,
			Footer = "This relationship has been added to your Relationships page."
		}
	end

	local existing = BitKaisenRelationships.GetRandomRelationship(stats)

	if existing and roll <= 55 then
		local positive = math.random(1, 100) <= 70

		if positive then
			BitKaisenRelationships.AdjustRelationship(existing, {
				Bond = math.random(2, 8),
				Trust = math.random(1, 5),
				Respect = math.random(0, 4)
			})

			return "Your bond with " .. existing.Name .. " grew stronger.", nil
		else
			BitKaisenRelationships.AdjustRelationship(existing, {
				Bond = -math.random(2, 8),
				Trust = -math.random(1, 5),
				Respect = -math.random(0, 3)
			})

			return "You had tension with " .. existing.Name .. ".", nil
		end
	end

	return nil, nil
end

local RELATIONSHIP_DISPLAY_FIELDS = {
	"Id",
	"Name",
	"Role",
	"Status",
	"Alive",
	"Age",
	"DisplayAge",
	"EstimatedAge",
	"Gender",
	"Grade",
	"SorcererGrade",
	"CursedEnergy",
	"CursedTechnique",
	"Trait",
	"TraitSummary",
	"Personality",
	"Background",
	"Bond",
	"Trust",
	"Respect",
	"Romance",
	"Fear",
	"YearsKnown",
	"YearsDating",
	"YearsMarried",
	"YearsDivorced",
	"Custody",
	"CustodyParentName",
	"DeathCause",
	"DeathText",
}

local function copyRelationshipDisplayRecord(relationship)
	local copy = {}

	for _, field in ipairs(RELATIONSHIP_DISPLAY_FIELDS) do
		local value = relationship[field]
		if value ~= nil then
			copy[field] = value
		end
	end

	if typeof(relationship.Traits) == "table" then
		copy.Traits = {}
		for index, trait in ipairs(relationship.Traits) do
			if index > 8 then
				break
			end
			copy.Traits[index] = trait
		end
	end

	return copy
end

function BitKaisenRelationships.GetDisplayList(stats)
	BitKaisenRelationships.EnsureRelationships(stats)

	local list = {}

	for _, relationship in ipairs(stats.Relationships) do
		reconcileRelationshipTimeline(stats, relationship)
		sanitizeRomance(relationship)
		table.insert(list, copyRelationshipDisplayRecord(relationship))
	end

	table.sort(list, function(a, b)
		local order = {
			Mother = 1,
			Father = 2,
			Caretaker = 3,
			Sibling = 4,
			Spouse = 5,
			Partner = 6,
			["Ex-Spouse"] = 7,
			Child = 8,
			["Late Mother"] = 8,
			["Late Father"] = 8,
			Teacher = 9,
			["Best Friend"] = 10,
			Friend = 11,
			Classmate = 12,
			Rival = 13,
			["Mission Partner"] = 14,
			Observer = 15
		}

		if (a.Alive == false) ~= (b.Alive == false) then
			return a.Alive ~= false
		end

		return (order[a.Role] or 99) < (order[b.Role] or 99)
	end)

	return list
end

function BitKaisenRelationships.SanitizeOnLoad(stats)
	if not stats then
		return
	end

	stats.Relationships = stats.Relationships or {}
	stats.RelationshipHistory = stats.RelationshipHistory or {}

	for _, relationship in ipairs(stats.Relationships) do
		relationship.Id = relationship.Id or makeId(relationship.Role or "Relationship")
		relationship.Role = relationship.Role or "Acquaintance"
		relationship.Gender = normalizeGender(relationship.Gender, relationship.Role)
		relationship.Name = relationship.Name or makeName(stats.FamilyName, relationship.Gender)
		relationship.Status = relationship.Status or "Neutral"

		relationship.Bond = clampPercent(relationship.Bond or 50)
		relationship.Trust = clampPercent(relationship.Trust or 50)
		relationship.Respect = clampPercent(relationship.Respect or 30)
		relationship.Fear = clampPercent(relationship.Fear or 0)
		relationship.Romance = clampPercent(relationship.Romance or 0)

		if relationship.Alive == nil then
			relationship.Alive = true
		end

		relationship.YearsKnown = relationship.YearsKnown or 0
		relationship.YearsDating = relationship.YearsDating or 0
		relationship.YearsMarried = relationship.YearsMarried or 0
		relationship.YearsDivorced = relationship.YearsDivorced or 0
		relationship.IsChild = relationship.IsChild or relationship.Role == "Child"
		if relationship.Role == "Child" then
			relationship.OtherParentName = relationship.OtherParentName or relationship.CoParentName or relationship.SecondParentName or "Unknown"
			relationship.CoParentName = relationship.CoParentName or relationship.OtherParentName or "Unknown"
			relationship.Custody = relationship.Custody or "With You"
			relationship.CustodyParentName = relationship.CustodyParentName or "You"
			relationship.LastCustodyChangeAge = relationship.LastCustodyChangeAge or 0
			relationship.CustodyHistory = relationship.CustodyHistory or {}
		end

		relationship.Age = relationship.Age or 0
		relationship.Grade = relationship.Grade or "Non-Sorcerer"
		relationship.CursedEnergy = relationship.CursedEnergy or 0
		relationship.CursedTechnique = relationship.CursedTechnique or "None"
		relationship.Personality = relationship.Personality or "No clear personality read yet."

		sanitizeRomance(relationship)
	end
end

return BitKaisenRelationships

