-- ModuleScript: BitKaisenCurseEvolution
-- Location: ReplicatedStorage
-- Purpose:
--   Shared cursed spirit evolution thresholds, threat classes, and mutation rewards.

local BitKaisenCurseEvolution = {}

local STAGES = {
	{ Name = "Dormant", Requirement = 0, ThreatClass = "Local", Grade = "Unregistered Grade 4 Cursed Spirit" },
	{ Name = "Evolving", Requirement = 35, ThreatClass = "Local", Grade = "Unregistered Grade 3 Cursed Spirit" },
	{ Name = "Matured", Requirement = 80, ThreatClass = "Regional", Grade = "Unregistered Grade 2 Cursed Spirit" },
	{ Name = "Disaster Seed", Requirement = 135, ThreatClass = "National", Grade = "Unregistered Grade 1 Cursed Spirit" },
	{ Name = "Disaster Curse", Requirement = 220, ThreatClass = "Disaster", Grade = "Special Grade Cursed Spirit" },
}

local MUTATIONS = {
	Evolving = {
		Id = "fear_aura",
		Name = "Fear Aura",
		Message = "Fear started gathering around your shape before humans could explain why.",
		Apply = function(stats)
			stats.CurseFearLevel = math.max(0, (tonumber(stats.CurseFearLevel) or 0) + 8)
		end,
	},
	Matured = {
		Id = "territory_anchor",
		Name = "Territory Anchor",
		Message = "Your haunt began holding your cursed residue even after you left.",
		Apply = function(stats)
			stats.CurseTerritoryControl = math.clamp((tonumber(stats.CurseTerritoryControl) or 0) + 10, 0, 100)
			stats.ExorcismRisk = math.clamp((tonumber(stats.ExorcismRisk) or 0) - 4, 0, 100)
		end,
	},
	["Disaster Seed"] = {
		Id = "predatory_form",
		Name = "Predatory Form",
		Message = "Your cursed body settled into a shape built for hunting sorcerers.",
		Apply = function(stats)
			stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + 18)
			stats.CurseThreat = math.max(0, (tonumber(stats.CurseThreat) or 0) + 10)
		end,
	},
	["Disaster Curse"] = {
		Id = "calamity_presence",
		Name = "Calamity Presence",
		Message = "Your existence became a city-level warning in the jujutsu world.",
		Apply = function(stats)
			stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + 30)
			stats.CurseFearLevel = math.max(0, (tonumber(stats.CurseFearLevel) or 0) + 18)
			stats.ExorcismRisk = math.clamp((tonumber(stats.ExorcismRisk) or 0) + 8, 0, 100)
		end,
	},
}

local function isCurseLife(stats)
	if typeof(stats) ~= "table" then
		return false
	end

	local race = tostring(stats.Race or "")
	local origin = tostring(stats.Origin or stats.Clan or "")
	local originCategory = tostring(stats.OriginCategory or "")
	local familyType = tostring(stats.FamilyType or "")
	local curseType = tostring(stats.CurseType or "")

	return stats.IsCurse == true
		or race == "Cursed Spirit"
		or race == "Curse"
		or origin == "Vengeful Spirit Rebirth"
		or origin == "Cursed Spirit Rebirth"
		or origin == "Cursed Rebirth"
		or origin == "Curse"
		or origin == "Cursed Spirit"
		or (originCategory == "Race" and (origin == "Cursed Spirit" or origin == "Curse" or familyType == "Cursed Spirit" or familyType == "Curse"))
		or curseType == "Vengeful Cursed Spirit"
end

local function ensureMutationTable(stats)
	if typeof(stats.CurseMutations) ~= "table" then
		stats.CurseMutations = {}
	end
	return stats.CurseMutations
end

local function hasMutation(stats, mutationId)
	for _, mutation in ipairs(ensureMutationTable(stats)) do
		if tostring(mutation.Id or mutation.Name or "") == mutationId then
			return true
		end
	end
	return false
end

local function getStageIndex(stageName)
	local clean = tostring(stageName or "Dormant")
	for index, stage in ipairs(STAGES) do
		if stage.Name == clean then
			return index
		end
	end
	return 1
end

function BitKaisenCurseEvolution.GetStage(stats)
	local progress = math.max(0, tonumber(stats and stats.CurseEvolutionProgress) or 0)
	local stage = STAGES[1]

	for _, candidate in ipairs(STAGES) do
		if progress >= candidate.Requirement then
			stage = candidate
		else
			break
		end
	end

	return stage
end

function BitKaisenCurseEvolution.GetNextRequirement(stats)
	local current = BitKaisenCurseEvolution.GetStage(stats)
	local index = getStageIndex(current.Name)
	local nextStage = STAGES[index + 1]
	return nextStage and nextStage.Requirement or current.Requirement
end

function BitKaisenCurseEvolution.Normalize(stats)
	if typeof(stats) ~= "table" then
		return nil
	end

	if not isCurseLife(stats) then
		stats.CurseThreatClass = tostring(stats.CurseThreatClass or "None")
		if stats.CurseEvolution == nil then
			stats.CurseEvolution = "None"
		end
		return nil
	end

	if tonumber(stats.CurseEvolution) ~= nil and (tonumber(stats.CurseEvolutionProgress) or 0) <= 0 then
		stats.CurseEvolutionProgress = tonumber(stats.CurseEvolution) or 0
	end

	stats.CurseEvolutionProgress = math.max(0, tonumber(stats.CurseEvolutionProgress) or 0)
	stats.CurseThreat = math.max(0, tonumber(stats.CurseThreat) or 0)

	local stage = BitKaisenCurseEvolution.GetStage(stats)
	stats.CurseEvolution = stage.Name
	stats.CurseThreatClass = stage.ThreatClass
	stats.CurseGrade = stage.Grade
	return stage
end

function BitKaisenCurseEvolution.ApplyMutation(stats, stage)
	if typeof(stats) ~= "table" or typeof(stage) ~= "table" then
		return nil
	end

	local mutation = MUTATIONS[stage.Name]
	if not mutation or hasMutation(stats, mutation.Id) then
		return nil
	end

	table.insert(ensureMutationTable(stats), {
		Id = mutation.Id,
		Name = mutation.Name,
		Stage = stage.Name,
		Age = tonumber(stats.Age) or 0,
	})

	if mutation.Apply then
		mutation.Apply(stats)
	end

	stats.CurseMutationCount = math.max(0, tonumber(stats.CurseMutationCount) or 0) + 1
	stats.CurseLatestMutation = mutation.Name
	return mutation
end

function BitKaisenCurseEvolution.AddProgress(stats, amount, source)
	if typeof(stats) ~= "table" or not isCurseLife(stats) then
		return { Gain = 0, StageChanged = false, Message = "" }
	end

	BitKaisenCurseEvolution.Normalize(stats)

	local oldStage = BitKaisenCurseEvolution.GetStage(stats)
	local gain = math.max(0, math.floor(tonumber(amount) or 0))
	if gain <= 0 then
		return { Gain = 0, Stage = oldStage, StageChanged = false, Message = "" }
	end

	stats.CurseEvolutionProgress = math.max(0, (tonumber(stats.CurseEvolutionProgress) or 0) + gain)
	local newStage = BitKaisenCurseEvolution.Normalize(stats)
	local result = {
		Gain = gain,
		Stage = newStage,
		OldStage = oldStage,
		StageChanged = newStage and oldStage and newStage.Name ~= oldStage.Name,
		Source = tostring(source or "cursed growth"),
		Message = "",
	}

	if result.StageChanged then
		local mutation = BitKaisenCurseEvolution.ApplyMutation(stats, newStage)
		result.Mutation = mutation
		result.Message = "\n<font color='#d65bff'><b>[ CURSE EVOLUTION ]</b></font> " .. result.Source .. " pushed you into <b>" .. tostring(newStage.Name) .. "</b>. Threat Class: <b>" .. tostring(newStage.ThreatClass) .. "</b>."
		if mutation then
			result.Message ..= "\nMutation unlocked: <b>" .. tostring(mutation.Name) .. "</b>. " .. tostring(mutation.Message)
		end
	end

	return result
end

function BitKaisenCurseEvolution.GetCombatBonus(stats)
	local stage = BitKaisenCurseEvolution.GetStage(stats)
	local index = getStageIndex(stage.Name)
	return math.max(0, index - 1) * 12
end

BitKaisenCurseEvolution.Stages = STAGES
return BitKaisenCurseEvolution
