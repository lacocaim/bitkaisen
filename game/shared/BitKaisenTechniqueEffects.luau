-- ModuleScript: BitKaisenTechniqueEffects
-- Location: ReplicatedStorage
-- Purpose: Technique-specific combat and mission modifiers.

local BitKaisenTechniqueEffects = {}

local PROFILES = {
	["limitless"] = {
		PowerBonus = 18,
		DamageTakenMult = 0.72,
		CursedEnergyRewardMult = 1.08,
		MasteryGainBonus = 1,
		Note = "Limitless kept the worst pressure away from you."
	},
	["ten shadows"] = {
		PowerBonus = 16,
		DamageTakenMult = 0.88,
		ReputationRewardMult = 1.06,
		MasteryGainBonus = 1,
		Note = "Your shikigami split the enemy's attention."
	},
	["blood manipulation"] = {
		PowerBonus = 12,
		DamageTakenMult = 0.92,
		CursedEnergyRewardMult = 1.05,
		MasteryGainBonus = 1,
		Note = "Blood control turned injury risk into pressure."
	},
	["cursed speech"] = {
		PowerBonus = 10,
		DamageTakenMult = 0.86,
		ReputationRewardMult = 1.04,
		Note = "A cursed command interrupted the enemy's rhythm."
	},
	["boogie woogie"] = {
		PowerBonus = 12,
		DamageTakenMult = 0.82,
		MasteryGainBonus = 1,
		Note = "Boogie Woogie turned positioning into a weapon."
	},
	["ratio technique"] = {
		PowerBonus = 11,
		DamageTakenMult = 0.94,
		MoneyRewardMult = 1.06,
		ReputationRewardMult = 1.04,
		Note = "Ratio Technique found the cleanest breaking point."
	},
	["projection sorcery"] = {
		PowerBonus = 14,
		DamageTakenMult = 0.84,
		MasteryGainBonus = 1,
		Note = "Projection frames let you move before the hit fully formed."
	},
	["copy"] = {
		PowerBonus = 13,
		DamageTakenMult = 0.90,
		CursedEnergyRewardMult = 1.06,
		MasteryGainBonus = 1,
		Note = "Copy gave you a flexible answer to the situation."
	},
	["rika manifestation"] = {
		PowerBonus = 18,
		DamageTakenMult = 0.86,
		ReputationRewardMult = 1.08,
		Note = "Rika's presence overwhelmed the field."
	},
	["shrine"] = {
		PowerBonus = 17,
		DamageTakenMult = 0.96,
		CursedEnergyRewardMult = 1.08,
		ReputationRewardMult = 1.06,
		Note = "Shrine converted output into clean destruction."
	},
	["brain transplant"] = {
		PowerBonus = 16,
		DamageTakenMult = 0.92,
		CursedEnergyRewardMult = 1.08,
		MasteryGainBonus = 1,
		Note = "Brain Transplant let old experience pilot a stolen body."
	},
	["pumpkin control"] = {
		PowerBonus = 14,
		DamageTakenMult = 0.87,
		CursedEnergyRewardMult = 1.06,
		MoneyRewardMult = 1.05,
		MasteryGainBonus = 1,
		Note = "Pumpkin Control flooded the field with heavy seasonal constructs."
	},
	["idle transfiguration"] = {
		PowerBonus = 15,
		DamageTakenMult = 0.91,
		CursedEnergyRewardMult = 1.06,
		ReputationRewardMult = 1.08,
		Note = "Idle Transfiguration made the enemy fear being touched."
	},
	["cursed spirit manipulation"] = {
		PowerBonus = 14,
		DamageTakenMult = 0.89,
		CursedEnergyRewardMult = 1.07,
		Note = "A controlled curse changed the shape of the fight."
	},
	["construction"] = {
		PowerBonus = 9,
		DamageTakenMult = 0.90,
		MoneyRewardMult = 1.04,
		Note = "Constructed tools covered the dangerous gap."
	},
	["tool manipulation"] = {
		PowerBonus = 10,
		DamageTakenMult = 0.88,
		Note = "Cursed tools moved exactly where they were needed."
	},
	["simple domain"] = {
		PowerBonus = 8,
		DamageTakenMult = 0.78,
		Note = "Simple Domain anchored your defense."
	},
	["heavenly restriction"] = {
		PowerBonus = 18,
		DamageTakenMult = 0.82,
		MasteryGainBonus = 1,
		Note = "Your body handled the exchange with unnatural precision."
	},
}

local BRANCH_BONUSES = {
	["Refined Form"] = { PowerBonus = 4, DamageTakenMult = 0.98 },
	["Extension Technique"] = { PowerBonus = 8, DamageTakenMult = 0.96, MasteryGainBonus = 1 },
	["Maximum Technique"] = { PowerBonus = 14, DamageTakenMult = 0.94, CursedEnergyRewardMult = 1.04, MasteryGainBonus = 1 },
	["Domain Seed"] = { PowerBonus = 20, DamageTakenMult = 0.90, CursedEnergyRewardMult = 1.08, ReputationRewardMult = 1.05, MasteryGainBonus = 2 },

	["Heian Shrine"] = { PowerBonus = 18, DamageTakenMult = 0.95, CursedEnergyRewardMult = 1.07, ReputationRewardMult = 1.05, Note = "Heian Shrine made every cut cleaner and harder to survive." },
	["Cleave/Dismantle Control"] = { PowerBonus = 22, DamageTakenMult = 0.93, CursedEnergyRewardMult = 1.09, ReputationRewardMult = 1.06, MasteryGainBonus = 1, Note = "Cleave and Dismantle adapted to the target instead of wasting output." },
	["World Cutting Shrine"] = { PowerBonus = 34, DamageTakenMult = 0.88, CursedEnergyRewardMult = 1.14, ReputationRewardMult = 1.12, MasteryGainBonus = 2, Note = "World Cutting Shrine made distance feel irrelevant." },
	["Blue Precision"] = { PowerBonus = 16, DamageTakenMult = 0.70, CursedEnergyRewardMult = 1.08, MasteryGainBonus = 1, Note = "Blue Precision controlled space before the enemy could commit." },
	["Red Reversal"] = { PowerBonus = 22, DamageTakenMult = 0.68, CursedEnergyRewardMult = 1.11, ReputationRewardMult = 1.05, MasteryGainBonus = 1, Note = "Red Reversal punished anything that pushed too close." },
	["Shikigami Flow"] = { PowerBonus = 16, DamageTakenMult = 0.84, ReputationRewardMult = 1.05, MasteryGainBonus = 1, Note = "Shikigami Flow kept your summons moving as one body." },
	["Shadow Storage"] = { PowerBonus = 20, DamageTakenMult = 0.80, MoneyRewardMult = 1.05, MasteryGainBonus = 1, Note = "Shadow Storage hid the right answer until the enemy overextended." },
	["Chimera Shadow Garden Seed"] = { PowerBonus = 30, DamageTakenMult = 0.76, CursedEnergyRewardMult = 1.10, ReputationRewardMult = 1.08, MasteryGainBonus = 2, Note = "A domain seed let shadows turn the field against the target." },
	["Flowing Red Scale"] = { PowerBonus = 14, DamageTakenMult = 0.90, CursedEnergyRewardMult = 1.06, MasteryGainBonus = 1, Note = "Flowing Red Scale sharpened your body under pressure." },
	["Piercing Blood"] = { PowerBonus = 20, DamageTakenMult = 0.88, CursedEnergyRewardMult = 1.08, ReputationRewardMult = 1.04, MasteryGainBonus = 1, Note = "Piercing Blood turned one clean line into a fight-ending threat." },
	["Convergence Mastery"] = { PowerBonus = 27, DamageTakenMult = 0.84, CursedEnergyRewardMult = 1.12, MasteryGainBonus = 2, Note = "Convergence Mastery kept blood pressure ready for the next kill shot." },
	["Command Restraint"] = { PowerBonus = 13, DamageTakenMult = 0.82, ReputationRewardMult = 1.04, Note = "Command Restraint reduced backlash while keeping orders sharp." },
	["Layered Command"] = { PowerBonus = 19, DamageTakenMult = 0.80, ReputationRewardMult = 1.06, MasteryGainBonus = 1, Note = "Layered Command stacked small orders into one decisive opening." },
	["Absolute Order"] = { PowerBonus = 28, DamageTakenMult = 0.76, CursedEnergyRewardMult = 1.08, ReputationRewardMult = 1.10, MasteryGainBonus = 2, Note = "Absolute Order made hesitation dangerous for everyone else." },
	["Copied Reflex"] = { PowerBonus = 15, DamageTakenMult = 0.88, CursedEnergyRewardMult = 1.07, MasteryGainBonus = 1, Note = "Copied Reflex borrowed the right response at the right time." },
	["Awakened Copy"] = { PowerBonus = 24, DamageTakenMult = 0.86, CursedEnergyRewardMult = 1.10, MasteryGainBonus = 2, Note = "Awakened Copy answered the fight without a time limit." },
	["Boundless Copy"] = { PowerBonus = 30, DamageTakenMult = 0.82, CursedEnergyRewardMult = 1.14, ReputationRewardMult = 1.08, MasteryGainBonus = 3, Note = "Boundless Copy turned every technique you understood into an option." },
	["Seven-Three Read"] = { PowerBonus = 13, DamageTakenMult = 0.92, MoneyRewardMult = 1.06, ReputationRewardMult = 1.04, Note = "Seven-Three Read found the first weak line." },
	["Collapse Point"] = { PowerBonus = 19, DamageTakenMult = 0.90, MoneyRewardMult = 1.08, ReputationRewardMult = 1.06, MasteryGainBonus = 1, Note = "Collapse Point made precision hit harder than raw output." },
	["Overtime Rupture"] = { PowerBonus = 28, DamageTakenMult = 0.86, MoneyRewardMult = 1.12, ReputationRewardMult = 1.08, MasteryGainBonus = 2, Note = "Overtime Rupture turned discipline into brutal efficiency." },
	["Rhythm Swap"] = { PowerBonus = 14, DamageTakenMult = 0.78, MasteryGainBonus = 1, Note = "Rhythm Swap made positioning impossible to trust." },
	["False Clap"] = { PowerBonus = 20, DamageTakenMult = 0.76, ReputationRewardMult = 1.05, MasteryGainBonus = 1, Note = "False Clap broke enemy reactions before the swap happened." },
	["Unbroken Beat"] = { PowerBonus = 28, DamageTakenMult = 0.72, ReputationRewardMult = 1.08, MasteryGainBonus = 2, Note = "Unbroken Beat kept the field dancing to your rhythm." },
	["Frame Discipline"] = { PowerBonus = 15, DamageTakenMult = 0.80, MasteryGainBonus = 1, Note = "Frame Discipline made every movement obey the count." },
	["Frame Trap"] = { PowerBonus = 21, DamageTakenMult = 0.78, ReputationRewardMult = 1.05, MasteryGainBonus = 1, Note = "Frame Trap punished anyone who moved off timing." },
	["Twenty-Four Frame Kill"] = { PowerBonus = 30, DamageTakenMult = 0.74, CursedEnergyRewardMult = 1.08, ReputationRewardMult = 1.08, MasteryGainBonus = 2, Note = "Twenty-Four Frame Kill made speed feel prewritten." },
	["Soul Striking"] = { PowerBonus = 14, DamageTakenMult = 0.90, CursedEnergyRewardMult = 1.05, MasteryGainBonus = 1, Note = "Soul Striking made each hit linger after impact." },
	["Delayed Impact"] = { PowerBonus = 19, DamageTakenMult = 0.88, CursedEnergyRewardMult = 1.07, MasteryGainBonus = 1, Note = "Delayed Impact doubled the moment the enemy thought was over." },
	["Master of Black Sparks"] = { PowerBonus = 29, DamageTakenMult = 0.84, CursedEnergyRewardMult = 1.12, ReputationRewardMult = 1.08, MasteryGainBonus = 2, Note = "Black sparks answered whenever your timing sharpened." },
	["Trait Sculpting"] = { PowerBonus = 16, DamageTakenMult = 0.90, CursedEnergyRewardMult = 1.08, ReputationRewardMult = 1.06, Note = "Trait Sculpting made the body a battlefield." },
	["Soul Rewrite"] = { PowerBonus = 23, DamageTakenMult = 0.88, CursedEnergyRewardMult = 1.12, ReputationRewardMult = 1.10, MasteryGainBonus = 1, Note = "Soul Rewrite made contact feel like a sentence." },
	["Perfect Idle Transfiguration"] = { PowerBonus = 32, DamageTakenMult = 0.84, CursedEnergyRewardMult = 1.16, ReputationRewardMult = 1.14, MasteryGainBonus = 2, Note = "Perfect Idle Transfiguration made shape itself negotiable." },
	["Shikigami: Fully Tamed"] = { PowerBonus = 26, DamageTakenMult = 0.80, ReputationRewardMult = 1.08, MasteryGainBonus = 2, Note = "Fully tamed shikigami covered every blind spot." },
	["Shinjuku Limitless"] = { PowerBonus = 28, DamageTakenMult = 0.66, CursedEnergyRewardMult = 1.10, MasteryGainBonus = 2, Note = "Shinjuku Limitless compressed space into overwhelming pressure." },
	["Hollow Nuke"] = { PowerBonus = 36, DamageTakenMult = 0.62, CursedEnergyRewardMult = 1.16, ReputationRewardMult = 1.12, MasteryGainBonus = 3, Note = "Hollow Nuke erased the safest path through the battlefield." },
	["Puppet Relay"] = { PowerBonus = 15, DamageTakenMult = 0.86, CursedEnergyRewardMult = 1.05, MasteryGainBonus = 1, Note = "Puppet Relay let distant tools take the first risk." },
	["Remote Corps"] = { PowerBonus = 22, DamageTakenMult = 0.82, CursedEnergyRewardMult = 1.08, MoneyRewardMult = 1.05, MasteryGainBonus = 1, Note = "Remote Corps turned backup bodies into pressure." },
	["Ultimate Mechamaru"] = { PowerBonus = 28, DamageTakenMult = 0.78, CursedEnergyRewardMult = 1.08, MasteryGainBonus = 2, Note = "Ultimate Mechamaru converted distance and stored output into a giant weapon." },
	["Mechamaru Fortress Seed"] = { PowerBonus = 32, DamageTakenMult = 0.74, CursedEnergyRewardMult = 1.12, MoneyRewardMult = 1.08, MasteryGainBonus = 2, Note = "Mechamaru Fortress Seed made the battlefield feel engineered." },
	["Zero CE Footwork"] = { PowerBonus = 17, DamageTakenMult = 0.78, ReputationRewardMult = 1.04, MasteryGainBonus = 1, Note = "Zero CE Footwork erased the warning signs enemies expected." },
	["Body Beyond Curses"] = { PowerBonus = 24, DamageTakenMult = 0.72, ReputationRewardMult = 1.06, MasteryGainBonus = 1, Note = "Body Beyond Curses carried you through pressure cursed energy could not solve." },
	["Awakened Heavenly Restriction"] = { PowerBonus = 30, DamageTakenMult = 0.70, ReputationRewardMult = 1.06, MasteryGainBonus = 2, Note = "Awakened Heavenly Restriction moved beyond normal cursed perception." },
	["Invisible Body Domain Seed"] = { PowerBonus = 34, DamageTakenMult = 0.66, ReputationRewardMult = 1.10, MasteryGainBonus = 2, Note = "Invisible Body Domain Seed made absence itself a weapon." },
	["Host Memory"] = { PowerBonus = 16, DamageTakenMult = 0.90, CursedEnergyRewardMult = 1.07, MasteryGainBonus = 1, Note = "Host Memory brought old instincts into the current body." },
	["Body Hopping"] = { PowerBonus = 23, DamageTakenMult = 0.86, CursedEnergyRewardMult = 1.10, ReputationRewardMult = 1.06, MasteryGainBonus = 1, Note = "Body Hopping made survival feel planned in advance." },
	["Ancient Schemer"] = { PowerBonus = 30, DamageTakenMult = 0.82, CursedEnergyRewardMult = 1.14, ReputationRewardMult = 1.10, MasteryGainBonus = 2, Note = "Ancient Schemer stacked centuries of bad ideas into one fight." },
	["Womb of Schemes Seed"] = { PowerBonus = 35, DamageTakenMult = 0.78, CursedEnergyRewardMult = 1.16, ReputationRewardMult = 1.12, MasteryGainBonus = 2, Note = "Womb of Schemes Seed made every choice feel already compromised." },
	["Harvest Guard"] = { PowerBonus = 15, DamageTakenMult = 0.84, CursedEnergyRewardMult = 1.05, MoneyRewardMult = 1.04, Note = "Harvest Guard let constructs take the ugly hits." },
	["Patch Swarm"] = { PowerBonus = 22, DamageTakenMult = 0.80, CursedEnergyRewardMult = 1.08, MoneyRewardMult = 1.06, MasteryGainBonus = 1, Note = "Patch Swarm filled the field until there was no clean route left." },
	["Pumpkin King Parade"] = { PowerBonus = 29, DamageTakenMult = 0.76, CursedEnergyRewardMult = 1.12, MoneyRewardMult = 1.08, ReputationRewardMult = 1.06, MasteryGainBonus = 2, Note = "Pumpkin King Parade made the battlefield crowded and loud." },
	["Midnight Patch Domain Seed"] = { PowerBonus = 34, DamageTakenMult = 0.72, CursedEnergyRewardMult = 1.15, MoneyRewardMult = 1.10, ReputationRewardMult = 1.08, MasteryGainBonus = 2, Note = "Midnight Patch Domain Seed turned every shadow into harvest ground." },
}

local function normalize(text)
	text = string.lower(tostring(text or ""))
	text = text:gsub("%s+", " ")
	text = text:gsub("^%s+", "")
	text = text:gsub("%s+$", "")
	return text
end

local function getTechnique(stats)
	local technique = tostring(stats and stats.CursedTechnique or "None")
	if technique == "None" or technique == "" then
		technique = tostring(stats and stats.InnateTechnique or "None")
	end
	return technique
end

local function merge(into, data)
	if not data then return into end
	into.PowerBonus += tonumber(data.PowerBonus) or 0
	into.DamageTakenMult *= tonumber(data.DamageTakenMult) or 1
	into.CursedEnergyRewardMult *= tonumber(data.CursedEnergyRewardMult) or 1
	into.MoneyRewardMult *= tonumber(data.MoneyRewardMult) or 1
	into.ReputationRewardMult *= tonumber(data.ReputationRewardMult) or 1
	into.MasteryGainBonus += tonumber(data.MasteryGainBonus) or 0
	if data.Note and data.Note ~= "" then
		into.Note = data.Note
	end
	return into
end

function BitKaisenTechniqueEffects.GetCombatModifiers(stats)
	local modifiers = {
		PowerBonus = 0,
		DamageTakenMult = 1,
		CursedEnergyRewardMult = 1,
		MoneyRewardMult = 1,
		ReputationRewardMult = 1,
		MasteryGainBonus = 0,
		Note = "",
	}

	local profile = PROFILES[normalize(getTechnique(stats))]
	merge(modifiers, profile)
	merge(modifiers, BRANCH_BONUSES[tostring(stats and stats.TechniqueEvolutionStage or "")])
	merge(modifiers, BRANCH_BONUSES[tostring(stats and stats.TechniqueBranch or "")])

	local unlockedExtensionCount = 0
	if typeof(stats and stats.UnlockedExtensions) == "table" then
		for _, extensionName in ipairs(stats.UnlockedExtensions) do
			if tostring(extensionName or "") ~= "" then
				unlockedExtensionCount += 1
				merge(modifiers, BRANCH_BONUSES[tostring(extensionName)])
			end
		end
	end
	if unlockedExtensionCount > 0 then
		modifiers.PowerBonus += math.min(12, unlockedExtensionCount * 3)
		modifiers.DamageTakenMult *= math.clamp(1 - (unlockedExtensionCount * 0.015), 0.92, 1)
		modifiers.MasteryGainBonus += math.min(3, math.floor((unlockedExtensionCount + 1) / 2))
		if modifiers.Note == "" then
			modifiers.Note = "Unlocked extension techniques shaped your combat rhythm."
		end
	end

	local techniqueText = string.lower(tostring(getTechnique(stats)))
	if string.find(techniqueText, "cursed spirit manipulation", 1, true) then
		local stored = math.clamp(tonumber(stats and stats.StoredCurses) or 0, 0, 25)
		local storedPower = math.clamp(tonumber(stats and stats.StoredCursePower) or 0, 0, 500)
		if stored > 0 then
			modifiers.PowerBonus += math.min(36, stored * 3 + math.floor(storedPower / 35))
			modifiers.DamageTakenMult *= math.clamp(1 - stored * 0.012, 0.78, 1)
			modifiers.Note = "Stored curses joined your side of the fight."
		end
	elseif string.find(techniqueText, "ten shadows", 1, true) then
		local tamed = math.clamp(tonumber(stats and stats.TamedShikigami) or 0, 0, 10)
		if tamed > 0 then
			modifiers.PowerBonus += tamed * 4
			modifiers.DamageTakenMult *= math.clamp(1 - tamed * 0.015, 0.75, 1)
			modifiers.Note = "Tamed shikigami fought beside you."
		end
	end

	local mastery = tonumber(stats and stats.TechniqueMastery) or 0
	if mastery >= 95 then
		modifiers.PowerBonus += 10
		modifiers.DamageTakenMult *= 0.94
	elseif mastery >= 75 then
		modifiers.PowerBonus += 6
	elseif mastery >= 50 then
		modifiers.PowerBonus += 3
	end

	modifiers.DamageTakenMult = math.clamp(modifiers.DamageTakenMult, 0.55, 1.35)
	return modifiers
end

function BitKaisenTechniqueEffects.GetTechniqueNote(stats)
	return BitKaisenTechniqueEffects.GetCombatModifiers(stats).Note or ""
end

return BitKaisenTechniqueEffects
