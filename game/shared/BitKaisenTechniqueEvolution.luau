-- ModuleScript: BitKaisenTechniqueEvolution
-- Location: ReplicatedStorage
-- Purpose: Shared cursed technique stage, branch, and evolution pressure logic.

local BitKaisenTechniqueEvolution = {}

local STAGES = {
	{ Id = "Dormant", Next = "Refined Form", Requirement = 25, Trait = "technique_refined" },
	{ Id = "Refined Form", Next = "Extension Technique", Requirement = 50, Trait = "extension_savant" },
	{ Id = "Extension Technique", Next = "Maximum Technique", Requirement = 75, Trait = "maximum_pressure" },
	{ Id = "Maximum Technique", Next = "Domain Seed", Requirement = 95, Trait = "domain_seed" },
}

local STAGE_BY_ID = {}
for _, stage in ipairs(STAGES) do
	STAGE_BY_ID[stage.Id] = stage
end

local function hasTechnique(stats)
	local technique = tostring(stats and stats.CursedTechnique or "None")
	if technique ~= "None" and technique ~= "" then
		return true
	end
	technique = tostring(stats and stats.InnateTechnique or "None")
	return technique ~= "None" and technique ~= ""
end

local function getTechniqueText(stats)
	local technique = tostring(stats and stats.CursedTechnique or "None")
	if technique == "None" or technique == "" then
		technique = tostring(stats and stats.InnateTechnique or "None")
	end
	return string.lower(technique)
end

local function addTrait(stats, traitId)
	if not stats or not traitId then
		return false
	end
	stats.Traits = typeof(stats.Traits) == "table" and stats.Traits or {}
	for _, owned in ipairs(stats.Traits) do
		local id = typeof(owned) == "table" and owned.Id or owned
		if tostring(id) == tostring(traitId) then
			return false
		end
	end
	table.insert(stats.Traits, traitId)
	return true
end

local function hasUnlockedExtension(stats, extensionName)
	if typeof(stats.UnlockedExtensions) ~= "table" then
		return false
	end
	for _, owned in ipairs(stats.UnlockedExtensions) do
		if tostring(owned) == tostring(extensionName) then
			return true
		end
	end
	return false
end

local function unlockExtension(stats, extensionName)
	if not stats or not extensionName or extensionName == "" or extensionName == "None" then
		return false
	end
	stats.UnlockedExtensions = typeof(stats.UnlockedExtensions) == "table" and stats.UnlockedExtensions or {}
	if hasUnlockedExtension(stats, extensionName) then
		return false
	end
	table.insert(stats.UnlockedExtensions, extensionName)
	return true
end

local function getUsageUnlockCandidate(stats)
	local stage = tostring(stats and stats.TechniqueEvolutionStage or "Dormant")
	if stage == "Dormant" then
		return nil
	end
	return BitKaisenTechniqueEvolution.GetBranchName(stats, stage)
end

local function recordTechniqueUsage(stats, amount, source)
	if not stats or not hasTechnique(stats) then
		return ""
	end

	amount = math.max(1, math.floor(tonumber(amount) or 1))
	stats.TechniqueUsageCount = math.max(0, tonumber(stats.TechniqueUsageCount) or 0) + amount
	local sourceText = string.lower(tostring(source or ""))
	local isMissionUse = string.find(sourceText, "mission", 1, true) ~= nil or string.find(sourceText, "combat", 1, true) ~= nil
	if isMissionUse then
		stats.TechniqueMissionUses = math.max(0, tonumber(stats.TechniqueMissionUses) or 0) + 1
	end

	local mastery = tonumber(stats.TechniqueMastery) or 0
	local missionUses = tonumber(stats.TechniqueMissionUses) or 0
	local totalUses = tonumber(stats.TechniqueUsageCount) or 0
	local candidate = getUsageUnlockCandidate(stats)
	local missionRequirementMet = missionUses >= 3 or (isMissionUse and missionUses >= 2 and mastery >= 65)
	local totalRequirementMet = totalUses >= 8 or (totalUses >= 5 and mastery >= 75)
	if candidate and mastery >= 50 and (missionRequirementMet or totalRequirementMet) and unlockExtension(stats, candidate) then
		return "\n<font color='#b27aff'><b>[ EXTENSION UNLOCKED ]</b></font> Repeated usage unlocked <b>" .. tostring(candidate) .. "</b>."
	end

	return ""
end

function BitKaisenTechniqueEvolution.GetNextStage(currentStage)
	local data = STAGE_BY_ID[tostring(currentStage or "Dormant")]
	return data and data.Next or nil
end

function BitKaisenTechniqueEvolution.GetRequirement(currentStage)
	local data = STAGE_BY_ID[tostring(currentStage or "Dormant")]
	return data and data.Requirement or nil
end

function BitKaisenTechniqueEvolution.GetBranchName(stats, nextStage)
	local technique = getTechniqueText(stats)
	local stage = tostring(nextStage or "Refined Form")

	if string.find(technique, "shrine", 1, true) then
		if stage == "Refined Form" then return "Heian Shrine" end
		if stage == "Extension Technique" then return "Cleave/Dismantle Control" end
		if stage == "Maximum Technique" or stage == "Domain Seed" then return "World Cutting Shrine" end
	elseif string.find(technique, "limitless", 1, true) then
		if stage == "Refined Form" then return "Blue Precision" end
		if stage == "Extension Technique" then return "Red Reversal" end
		if stage == "Maximum Technique" then return "Shinjuku Limitless" end
		if stage == "Domain Seed" then return "Hollow Nuke" end
	elseif string.find(technique, "ten shadows", 1, true) then
		if stage == "Refined Form" then return "Shikigami Flow" end
		if stage == "Extension Technique" then return "Shadow Storage" end
		if stage == "Maximum Technique" then return "Shikigami: Fully Tamed" end
		if stage == "Domain Seed" then return "Chimera Shadow Garden Seed" end
	elseif string.find(technique, "blood", 1, true) then
		if stage == "Refined Form" then return "Flowing Red Scale" end
		if stage == "Extension Technique" then return "Piercing Blood" end
		if stage == "Maximum Technique" or stage == "Domain Seed" then return "Convergence Mastery" end
	elseif string.find(technique, "speech", 1, true) then
		if stage == "Refined Form" then return "Command Restraint" end
		if stage == "Extension Technique" then return "Layered Command" end
		if stage == "Maximum Technique" or stage == "Domain Seed" then return "Absolute Order" end
	elseif string.find(technique, "copy", 1, true) or string.find(technique, "rika", 1, true) then
		if stage == "Refined Form" then return "Copied Reflex" end
		if stage == "Extension Technique" then return "Linked Arsenal" end
		if stage == "Maximum Technique" then return "Awakened Copy" end
		if stage == "Domain Seed" then return "Boundless Copy" end
	elseif string.find(technique, "ratio", 1, true) then
		if stage == "Refined Form" then return "Seven-Three Read" end
		if stage == "Extension Technique" then return "Collapse Point" end
		if stage == "Maximum Technique" or stage == "Domain Seed" then return "Overtime Rupture" end
	elseif string.find(technique, "boogie", 1, true) then
		if stage == "Refined Form" then return "Rhythm Swap" end
		if stage == "Extension Technique" then return "False Clap" end
		if stage == "Maximum Technique" or stage == "Domain Seed" then return "Unbroken Beat" end
	elseif string.find(technique, "projection", 1, true) then
		if stage == "Refined Form" then return "Frame Discipline" end
		if stage == "Extension Technique" then return "Frame Trap" end
		if stage == "Maximum Technique" or stage == "Domain Seed" then return "Twenty-Four Frame Kill" end
	elseif string.find(technique, "divergent", 1, true) or string.find(technique, "soul striking", 1, true) then
		if stage == "Refined Form" then return "Soul Striking" end
		if stage == "Extension Technique" then return "Delayed Impact" end
		if stage == "Maximum Technique" then return "Master of Black Sparks" end
		if stage == "Domain Seed" then return "Blood Brother" end
	elseif string.find(technique, "idle", 1, true) or string.find(technique, "transfiguration", 1, true) then
		if stage == "Refined Form" then return "Trait Sculpting" end
		if stage == "Extension Technique" then return "Soul Rewrite" end
		if stage == "Maximum Technique" or stage == "Domain Seed" then return "Perfect Idle Transfiguration" end
	elseif string.find(technique, "mechamaru", 1, true) or string.find(technique, "puppet", 1, true) then
		if stage == "Refined Form" then return "Puppet Relay" end
		if stage == "Extension Technique" then return "Remote Corps" end
		if stage == "Maximum Technique" then return "Ultimate Mechamaru" end
		if stage == "Domain Seed" then return "Mechamaru Fortress Seed" end
	elseif string.find(technique, "heavenly restriction", 1, true) then
		if stage == "Refined Form" then return "Zero CE Footwork" end
		if stage == "Extension Technique" then return "Body Beyond Curses" end
		if stage == "Maximum Technique" then return "Awakened Heavenly Restriction" end
		if stage == "Domain Seed" then return "Invisible Body Domain Seed" end
	elseif string.find(technique, "brain", 1, true) or string.find(technique, "transplant", 1, true) then
		if stage == "Refined Form" then return "Host Memory" end
		if stage == "Extension Technique" then return "Body Hopping" end
		if stage == "Maximum Technique" then return "Ancient Schemer" end
		if stage == "Domain Seed" then return "Womb of Schemes Seed" end
	elseif string.find(technique, "pumpkin", 1, true) then
		if stage == "Refined Form" then return "Harvest Guard" end
		if stage == "Extension Technique" then return "Patch Swarm" end
		if stage == "Maximum Technique" then return "Pumpkin King Parade" end
		if stage == "Domain Seed" then return "Midnight Patch Domain Seed" end
	end

	return stage
end

function BitKaisenTechniqueEvolution.TryAdvance(stats)
	if not stats or not hasTechnique(stats) then
		return false, ""
	end

	local currentStage = tostring(stats.TechniqueEvolutionStage or "Dormant")
	local data = STAGE_BY_ID[currentStage]
	if not data then
		return false, ""
	end

	local mastery = tonumber(stats.TechniqueMastery) or 0
	local progress = tonumber(stats.TechniqueEvolutionProgress) or 0
	if mastery < data.Requirement or progress < data.Requirement then
		return false, ""
	end

	local branchName = BitKaisenTechniqueEvolution.GetBranchName(stats, data.Next)
	stats.TechniqueEvolutionStage = data.Next
	stats.TechniqueEvolutionProgress = math.clamp(data.Requirement, 0, 100)
	stats.TechniqueBranch = branchName
	addTrait(stats, data.Trait)
	unlockExtension(stats, branchName)

	return true, "\n<font color='#b27aff'><b>[ TECHNIQUE EVOLUTION ]</b></font> Your technique advanced into <b>" .. branchName .. "</b>."
end

function BitKaisenTechniqueEvolution.AddPressure(stats, amount, source)
	if not stats or not hasTechnique(stats) then
		return ""
	end

	local currentStage = tostring(stats.TechniqueEvolutionStage or "Dormant")
	local requirement = BitKaisenTechniqueEvolution.GetRequirement(currentStage)
	if not requirement then
		return ""
	end

	amount = math.max(0, math.floor(tonumber(amount) or 0))
	if amount <= 0 then
		return ""
	end

	local usageMessage = recordTechniqueUsage(stats, math.max(1, math.floor(amount / 2)), source)
	local before = math.clamp(tonumber(stats.TechniqueEvolutionProgress) or 0, 0, 100)
	stats.TechniqueEvolutionProgress = math.clamp(before + amount, 0, 100)

	local message = "\n<font color='#b27aff'><b>[ CT PRESSURE ]</b></font> Evolution progress <b>+" .. tostring(stats.TechniqueEvolutionProgress - before) .. "</b>"
	if source and source ~= "" then
		message ..= " from " .. tostring(source)
	end
	message ..= " (" .. tostring(stats.TechniqueEvolutionProgress) .. "/" .. tostring(requirement) .. ")."

	local advanced, advanceMessage = BitKaisenTechniqueEvolution.TryAdvance(stats)
	if advanced then
		message ..= advanceMessage
	end
	message ..= usageMessage

	return message
end

return BitKaisenTechniqueEvolution
