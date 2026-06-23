-- ModuleScript: BitKaisenDomains
-- Location: ReplicatedStorage
-- Purpose: Update 14 domain expansion definitions, progression, and combat helpers.

local BitKaisenDomains = {}

local DOMAIN_BY_TECHNIQUE = {
	["Limitless"] = { Name = "Unlimited Void", Type = "Information Overload", Color = "Blue", ClashBonus = 18 },
	["Shrine"] = { Name = "Malevolent Shrine", Type = "Open Barrier Slashing", Color = "Red", ClashBonus = 20 },
	["Ten Shadows"] = { Name = "Chimera Shadow Garden", Type = "Shadow Flood", Color = "Purple", ClashBonus = 16 },
	["Idle Transfiguration"] = { Name = "Self-Embodiment of Perfection", Type = "Soul Shape", Color = "Purple", ClashBonus = 18 },
	["Copy"] = { Name = "Manifested Love Domain", Type = "Copied Arsenal", Color = "Pink", ClashBonus = 17 },
	["Rika Manifestation"] = { Name = "Manifested Love Domain", Type = "Bound Spirit", Color = "Pink", ClashBonus = 17 },
	["Blood Manipulation"] = { Name = "Crimson Binding Domain", Type = "Blood Seal", Color = "Red", ClashBonus = 13 },
	["Cursed Speech"] = { Name = "Commanding Silence", Type = "Vocal Binding", Color = "Blue", ClashBonus = 12 },
	["Boogie Woogie"] = { Name = "Resonant Switchyard", Type = "Spatial Rhythm", Color = "Green", ClashBonus = 11 },
	["Ratio Technique"] = { Name = "Seven-to-Three Court", Type = "Critical Geometry", Color = "Gold", ClashBonus = 11 },
	["Construction"] = { Name = "Perfected Forge", Type = "Materialization", Color = "Gold", ClashBonus = 12 },
	["Cursed Spirit Manipulation"] = { Name = "Parade of Bound Curses", Type = "Curse Swarm", Color = "Purple", ClashBonus = 16 },
	["Puppet Manipulation"] = { Name = "Mechanical Marionette Theater", Type = "Puppet Field", Color = "Blue", ClashBonus = 12 },
	["Projection Sorcery"] = { Name = "Framed Motion Palace", Type = "Frame Lock", Color = "Blue", ClashBonus = 13 },
	["Heavenly Restriction"] = { Name = "Empty Barrier", Type = "Anti-Domain Body", Color = "Green", ClashBonus = 10, AntiDomain = true },
	["Simple Domain"] = { Name = "Simple Domain", Type = "Anti-Domain Counter", Color = "Blue", ClashBonus = 8, AntiDomain = true },
}

local DEFAULT_DOMAIN = { Name = "Innate Territory", Type = "Personal Barrier", Color = "Gold", ClashBonus = 8 }

local STAGE_REQUIREMENTS = {
	Seed = 20,
	Incomplete = 55,
	Complete = 100,
}

local function techniqueName(stats)
	local technique = tostring(stats and stats.CursedTechnique or "None")
	if technique == "None" or technique == "" then
		technique = tostring(stats and stats.InnateTechnique or "None")
	end
	return technique
end

local function getDomainDefinition(stats)
	local technique = techniqueName(stats)
	local data = DOMAIN_BY_TECHNIQUE[technique] or DEFAULT_DOMAIN
	return {
		Technique = technique,
		Name = data.Name,
		Type = data.Type,
		Color = data.Color,
		ClashBonus = data.ClashBonus or 0,
		AntiDomain = data.AntiDomain == true,
	}
end

function BitKaisenDomains.Ensure(stats)
	if typeof(stats) ~= "table" then return end
	local definition = getDomainDefinition(stats)
	stats.DomainName = tostring(stats.DomainName or definition.Name)
	stats.DomainType = tostring(stats.DomainType or definition.Type)
	stats.DomainProgress = math.clamp(tonumber(stats.DomainProgress) or 0, 0, 100)
	stats.DomainStage = tostring(stats.DomainStage or "Locked")
	stats.DomainAwakened = stats.DomainAwakened == true
	stats.DomainUsesThisLife = math.max(0, tonumber(stats.DomainUsesThisLife) or 0)
	stats.DomainTrainingThisAge = math.clamp(tonumber(stats.DomainTrainingThisAge) or 0, 0, 3)
	stats.DomainClashesWon = math.max(0, tonumber(stats.DomainClashesWon) or 0)
	stats.DomainClashesLost = math.max(0, tonumber(stats.DomainClashesLost) or 0)
	stats.SimpleDomainProgress = math.clamp(tonumber(stats.SimpleDomainProgress) or 0, 0, 100)
	stats.DomainStability = math.clamp(tonumber(stats.DomainStability) or 35, 0, 100)
	if stats.DomainAwakened or stats.DomainProgress >= STAGE_REQUIREMENTS.Complete then
		stats.DomainStage = "Complete"
		stats.DomainAwakened = true
	elseif stats.DomainProgress >= STAGE_REQUIREMENTS.Incomplete then
		stats.DomainStage = "Incomplete"
	elseif stats.DomainProgress >= STAGE_REQUIREMENTS.Seed then
		stats.DomainStage = "Seed"
	else
		stats.DomainStage = "Locked"
	end
	stats.DomainName = definition.Name
	stats.DomainType = definition.Type
end

function BitKaisenDomains.GetDefinition(stats)
	return getDomainDefinition(stats)
end

function BitKaisenDomains.GetStageRequirements()
	return STAGE_REQUIREMENTS
end

function BitKaisenDomains.GetProgressGain(stats, reason)
	local mastery = tonumber(stats and stats.TechniqueMastery) or 0
	local ce = tonumber(stats and stats.CursedEnergy) or 0
	local base = 1
	if reason == "combat_win" then base = 4 elseif reason == "combat_loss" then base = 3 elseif reason == "training" then base = 5 elseif reason == "clash" then base = 6 end
	base += math.floor(mastery / 35)
	base += math.floor(ce / 900)
	return math.clamp(base, 1, 12)
end

function BitKaisenDomains.AddProgress(stats, amount, reason)
	if typeof(stats) ~= "table" then return "" end
	BitKaisenDomains.Ensure(stats)
	local before = tonumber(stats.DomainProgress) or 0
	amount = math.max(0, tonumber(amount) or 0)
	if amount <= 0 then return "" end
	stats.DomainProgress = math.clamp(before + amount, 0, 100)
	BitKaisenDomains.Ensure(stats)
	local text = "\n<font color='#b78cff'><b>[ DOMAIN ]</b></font> Domain progress <b>+" .. tostring(math.floor(amount)) .. "</b> (" .. tostring(math.floor(stats.DomainProgress)) .. "/100)."
	if before < STAGE_REQUIREMENTS.Seed and stats.DomainProgress >= STAGE_REQUIREMENTS.Seed then
		text ..= " A domain seed formed inside your innate technique."
	elseif before < STAGE_REQUIREMENTS.Incomplete and stats.DomainProgress >= STAGE_REQUIREMENTS.Incomplete then
		text ..= " You can now manifest an incomplete domain."
	elseif before < STAGE_REQUIREMENTS.Complete and stats.DomainProgress >= STAGE_REQUIREMENTS.Complete then
		stats.DomainAwakened = true
		stats.DomainStage = "Complete"
		text ..= " Your Domain Expansion awakened: <b>" .. tostring(stats.DomainName) .. "</b>."
	end
	return text
end

function BitKaisenDomains.CanTrain(stats)
	if typeof(stats) ~= "table" then return false, "No active life." end
	BitKaisenDomains.Ensure(stats)
	if stats.Alive == false then return false, "Your life has ended." end
	if tostring(techniqueName(stats)) == "None" and stats.HeavenlyRestricted ~= true then
		return false, "Awaken a cursed technique first."
	end
	if (tonumber(stats.DomainTrainingThisAge) or 0) >= 3 then
		return false, "You already trained your domain 3 times this age. Age up to train again."
	end
	if (tonumber(stats.CursedEnergy) or 0) < 80 and stats.HeavenlyRestricted ~= true then
		return false, "You need at least 80 CE to begin domain training."
	end
	return true, nil
end

function BitKaisenDomains.Train(stats)
	local ok, reason = BitKaisenDomains.CanTrain(stats)
	if not ok then return false, reason end
	local ceCost = math.min(math.max(8, math.floor((tonumber(stats.CursedEnergy) or 0) * 0.05)), 45)
	if stats.HeavenlyRestricted == true then ceCost = 0 end
	stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) - ceCost)
	stats.DomainTrainingThisAge = math.clamp((tonumber(stats.DomainTrainingThisAge) or 0) + 1, 0, 3)
	stats.DomainStability = math.clamp((tonumber(stats.DomainStability) or 35) + math.random(1, 4), 0, 100)
	local gain = BitKaisenDomains.GetProgressGain(stats, "training") + math.random(0, 3)
	local text = "You spent the session shaping your innate territory."
	if ceCost > 0 then text ..= " CE <b>-" .. tostring(ceCost) .. "</b>." end
	text ..= BitKaisenDomains.AddProgress(stats, gain, "training")
	return true, text
end

function BitKaisenDomains.GetCombatPayload(stats)
	BitKaisenDomains.Ensure(stats)
	local definition = getDomainDefinition(stats)
	local stage = tostring(stats.DomainStage or "Locked")
	local unlocked = stage == "Incomplete" or stage == "Complete"
	local cost = stage == "Complete" and 120 or 75
	return {
		Name = stats.DomainName or definition.Name,
		Stage = stage,
		Progress = math.floor(tonumber(stats.DomainProgress) or 0),
		Unlocked = unlocked,
		Cost = cost,
		Stability = math.floor(tonumber(stats.DomainStability) or 0),
		ClashBonus = definition.ClashBonus or 0,
		AntiDomain = definition.AntiDomain == true,
	}
end

function BitKaisenDomains.GetPayload(stats)
	BitKaisenDomains.Ensure(stats)
	local combat = BitKaisenDomains.GetCombatPayload(stats)
	return {
		Domain = combat,
		Technique = techniqueName(stats),
		CanTrain = select(1, BitKaisenDomains.CanTrain(stats)),
		TrainReason = select(2, BitKaisenDomains.CanTrain(stats)),
		DomainTrainingThisAge = math.clamp(tonumber(stats.DomainTrainingThisAge) or 0, 0, 3),
		DomainTrainingMax = 3,
		SimpleDomainProgress = math.floor(tonumber(stats.SimpleDomainProgress) or 0),
		ClashesWon = tonumber(stats.DomainClashesWon) or 0,
		ClashesLost = tonumber(stats.DomainClashesLost) or 0,
		Requirements = STAGE_REQUIREMENTS,
	}
end

return BitKaisenDomains
