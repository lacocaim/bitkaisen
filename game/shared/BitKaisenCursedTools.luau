-- ModuleScript: BitKaisenCursedTools
-- Purpose: Update 13 cursed tool definitions, ownership helpers, and inventory payloads.

local BitKaisenCursedTools = {}

BitKaisenCursedTools.RarityOrder = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
	SpecialGrade = 6,
	-- A tool the player made themselves sorts above the catalogue.
	Forged = 7,
}

BitKaisenCursedTools.Definitions = {
	{
		Id = "rusted_cursed_blade",
		Name = "Rusted Cursed Blade",
		Rarity = "Common",
		Type = "Weapon",
		Description = "A worn blade with faint cursed residue. Useful for early close-range fights.",
		EffectText = "+4 combat power while equipped.",
		Effects = { CombatPower = 4 },
		DropWeight = 34,
	},
	{
		Id = "sealed_protection_charm",
		Name = "Sealed Protection Charm",
		Rarity = "Common",
		Type = "Charm",
		Description = "A paper charm that dulls weak curse pressure during missions.",
		EffectText = "Slightly lowers mission danger while equipped.",
		Effects = { MissionRiskReduction = 3 },
		DropWeight = 30,
	},
	{
		Id = "barrier_tag",
		Name = "Barrier Tag",
		Rarity = "Uncommon",
		Type = "Defensive Tool",
		Description = "A prepared tag used by cautious sorcerers before dangerous encounters.",
		EffectText = "+6 defense power while equipped.",
		Effects = { DefensePower = 6 },
		DropWeight = 18,
	},
	{
		Id = "ce_amplifier_ring",
		Name = "CE Amplifier Ring",
		Rarity = "Rare",
		Type = "CE Amplifier",
		Description = "A metal ring that stabilizes cursed energy output during training and combat.",
		EffectText = "+6 combat power and +5% CE gain while equipped.",
		Effects = { CombatPower = 6, CEGainMult = 1.05 },
		DropWeight = 9,
	},
	{
		Id = "binding_chain_wrap",
		Name = "Binding Chain Wrap",
		Rarity = "Epic",
		Type = "Binding Tool",
		Description = "A reinforced chain wrap used to restrain cursed movement and hold ground in dangerous fights.",
		EffectText = "+8 combat power and +4 defense power while equipped.",
		Effects = { CombatPower = 8, DefensePower = 4 },
		DropWeight = 5,
	},
	{
		Id = "split_soul_dagger",
		Name = "Split-Soul Dagger",
		Rarity = "Legendary",
		Type = "Weapon",
		Description = "A dangerous blade said to cut deeper than the body when handled correctly.",
		EffectText = "+16 combat power while equipped.",
		Effects = { CombatPower = 16 },
		DropWeight = 2,
	},
	{
		Id = "clan_relic_core",
		Name = "Clan Relic Core",
		Rarity = "SpecialGrade",
		Type = "Clan Relic",
		Description = "A rare relic core that resonates with inherited cursed techniques and clan history.",
		EffectText = "+12 combat power, +8 defense power, and +8% CE gain while equipped.",
		Effects = { CombatPower = 12, DefensePower = 8, CEGainMult = 1.08 },
		DropWeight = 1,
	},
	{
		Id = "hand_sword",
		Name = "Hand Sword",
		Rarity = "Epic",
		Type = "Weapon",
		Description = "A blade condensed from pure cursed energy, manifested through the Miracle technique. Its edge does not distinguish between luck and fate.",
		EffectText = "+12 combat power while equipped.",
		Effects = { CombatPower = 12 },
		DropWeight = 0,
	},
	{
		Id = "contraband_curse_wire",
		Name = "Contraband Curse Wire",
		Rarity = "Common",
		Type = "Binding Tool",
		Description = "A curse-touched wire smuggled out of a sealed evidence locker. Jujutsu Society never logged its recovery.",
		EffectText = "+5 defense power while equipped.",
		Effects = { DefensePower = 5 },
		DropWeight = 0,
		BlackMarketPrice = 1200,
	},
	{
		Id = "stolen_grade3_talisman",
		Name = "Stolen Grade 3 Talisman",
		Rarity = "Uncommon",
		Type = "Charm",
		Description = "A registered exorcist's talisman, lifted before it could be filed with the Society archives.",
		EffectText = "Lowers mission danger while equipped.",
		Effects = { MissionRiskReduction = 6 },
		DropWeight = 0,
		BlackMarketPrice = 3000,
	},
	{
		Id = "black_market_switchblade",
		Name = "Black Market Switchblade",
		Rarity = "Rare",
		Type = "Weapon",
		Description = "A compact blade etched with unlicensed binding script. Popular among brokers who cannot risk a bulky weapon.",
		EffectText = "+9 combat power while equipped.",
		Effects = { CombatPower = 9 },
		DropWeight = 0,
		BlackMarketPrice = 7500,
	},
	{
		Id = "smuggled_binding_cuffs",
		Name = "Smuggled Binding Cuffs",
		Rarity = "Epic",
		Type = "Binding Tool",
		Description = "Restraint cuffs pulled from a raided smuggling ring, still humming with unstable cursed energy.",
		EffectText = "+6 combat power and +7 defense power while equipped.",
		Effects = { CombatPower = 6, DefensePower = 7 },
		DropWeight = 0,
		BlackMarketPrice = 16000,
	},
	{
		Id = "forgers_cursed_signet",
		Name = "Forger's Cursed Signet",
		Rarity = "Epic",
		Type = "CE Amplifier",
		Description = "A forger's signet ring used to counterfeit sorcerer credentials, now repurposed to stabilize cursed output.",
		EffectText = "+5 combat power and +6% CE gain while equipped.",
		Effects = { CombatPower = 5, CEGainMult = 1.06 },
		DropWeight = 0,
		BlackMarketPrice = 19000,
	},
	{
		Id = "underworld_grade1_fang",
		Name = "Underworld Grade 1 Fang",
		Rarity = "Legendary",
		Type = "Weapon",
		Description = "A Grade 1 sorcerer's tool that vanished from evidence storage and resurfaced on the black market years later.",
		EffectText = "+15 combat power and +3 defense power while equipped.",
		Effects = { CombatPower = 15, DefensePower = 3 },
		DropWeight = 0,
		BlackMarketPrice = 42000,
	},
}

local byId = {}
for _, tool in ipairs(BitKaisenCursedTools.Definitions) do
	byId[tool.Id] = tool
end
BitKaisenCursedTools.ById = byId

function BitKaisenCursedTools.GetToolCount()
	return #BitKaisenCursedTools.Definitions
end

function BitKaisenCursedTools.GetTool(toolId)
	return byId[tostring(toolId or "")]
end

function BitKaisenCursedTools.EnsureInventory(stats)
	if typeof(stats) ~= "table" then return {}, nil end
	if typeof(stats.CursedTools) ~= "table" then
		stats.CursedTools = {}
	end
	if stats.EquippedCursedToolId and not stats.CursedTools[stats.EquippedCursedToolId] then
		stats.EquippedCursedToolId = nil
	end
	return stats.CursedTools, stats.EquippedCursedToolId
end

function BitKaisenCursedTools.GetOwnedPayload(stats)
	local owned = BitKaisenCursedTools.EnsureInventory(stats)
	local payload = {}
	for toolId, item in pairs(owned) do
		-- ResolveTool rather than byId, so a tool the player forged shows up in their own
		-- inventory instead of being silently skipped.
		local def = BitKaisenCursedTools.ResolveTool(stats, toolId)
		if def then
			local nextGrade = def.Forged and BitKaisenCursedTools.GetNextForgeGrade(item.Uses) or nil
			table.insert(payload, {
				Id = def.Id,
				Name = def.Name,
				Rarity = def.Rarity,
				Type = def.Type,
				Description = def.Description,
				EffectText = def.EffectText,
				Equipped = BitKaisenCursedTools.IsEquipped(stats, def.Id),
				AcquiredFrom = item.AcquiredFrom or "Unknown",
				AcquiredYear = item.AcquiredYear,
				SellValue = BitKaisenCursedTools.GetSellValue(def),
				Affinity = def.Forged and 0 or math.clamp(tonumber(item.Affinity) or 0, 0, 100),
				Imbued = item.Imbued == true,
				ImbuedPower = tonumber(item.ImbuedPower) or 0,
				Forged = def.Forged == true,
				Grade = def.Grade,
				AffinityName = def.AffinityName,
				Uses = def.Uses,
				NextGrade = nextGrade and nextGrade.Grade or nil,
				UsesToNextGrade = nextGrade and math.max(0, nextGrade.Uses - (tonumber(item.Uses) or 0)) or nil,
			})
		end
	end
	table.sort(payload, function(a, b)
		local ar = BitKaisenCursedTools.RarityOrder[a.Rarity] or 0
		local br = BitKaisenCursedTools.RarityOrder[b.Rarity] or 0
		if ar ~= br then return ar > br end
		return tostring(a.Name) < tostring(b.Name)
	end)
	return payload
end

function BitKaisenCursedTools.GetCatalogPayload(stats)
	local owned = BitKaisenCursedTools.EnsureInventory(stats)
	local payload = {}
	for _, def in ipairs(BitKaisenCursedTools.Definitions) do
		table.insert(payload, {
			Id = def.Id,
			Name = def.Name,
			Rarity = def.Rarity,
			Type = def.Type,
			Description = def.Description,
			EffectText = def.EffectText,
			DropWeight = def.DropWeight,
			Owned = owned[def.Id] ~= nil,
		})
	end
	return payload
end

function BitKaisenCursedTools.GetBlackMarketCatalog(stats)
	local owned = BitKaisenCursedTools.EnsureInventory(stats)
	local payload = {}
	for _, def in ipairs(BitKaisenCursedTools.Definitions) do
		if tonumber(def.BlackMarketPrice) then
			table.insert(payload, {
				Id = def.Id,
				Name = def.Name,
				Rarity = def.Rarity,
				Type = def.Type,
				Description = def.Description,
				EffectText = def.EffectText,
				BlackMarketPrice = def.BlackMarketPrice,
				Owned = owned[def.Id] ~= nil,
			})
		end
	end
	return payload
end

function BitKaisenCursedTools.AddTool(stats, toolId, source, year)
	local def = BitKaisenCursedTools.GetTool(toolId)
	if not def then return nil, false end
	local owned = BitKaisenCursedTools.EnsureInventory(stats)
	if owned[def.Id] then
		return def, false
	end

	owned[def.Id] = {
		Id = def.Id,
		AcquiredFrom = source or "Unknown",
		AcquiredYear = year,
	}
	return def, true
end

function BitKaisenCursedTools.GrowAffinity(stats, toolId, amount)
	if not toolId then return end
	local owned = BitKaisenCursedTools.EnsureInventory(stats)
	local entry = owned[toolId]
	if not entry then return end
	entry.Affinity = math.clamp((tonumber(entry.Affinity) or 0) + (tonumber(amount) or 1), 0, 100)
end

function BitKaisenCursedTools.ImbueTool(stats, toolId)
	-- ResolveTool, not GetTool: a forged tool is not in the catalogue, so the catalogue
	-- lookup answered "that cursed tool does not exist" for a tool the player was holding.
	local def = BitKaisenCursedTools.ResolveTool(stats, toolId)
	if not def then
		return false, "That cursed tool does not exist."
	end
	local owned = BitKaisenCursedTools.EnsureInventory(stats)
	local entry = owned[toolId]
	if not entry then
		return false, "You do not own that cursed tool."
	end
	if entry.Imbued then
		return false, tostring(def.Name) .. " is already imbued."
	end
	if (tonumber(entry.Affinity) or 0) < 75 then
		return false, "Affinity with " .. tostring(def.Name) .. " is too low. You need at least 75%."
	end
	if (tonumber(stats.TechniqueMastery) or 0) < 60 then
		return false, "Your technique mastery is too low. You need at least 60 to imbue a cursed tool."
	end
	local ce = tonumber(stats.CursedEnergy) or 0
	local imbuedPower = math.max(2, math.floor(ce * 0.04))
	entry.Imbued = true
	entry.ImbuedPower = imbuedPower
	return true, "<font color='#f0b955'><b>[ CURSED TOOL ]</b></font> <b>" .. tostring(def.Name) .. "</b> has been imbued with your cursed energy. +" .. tostring(imbuedPower) .. " combat power."
end

function BitKaisenCursedTools.GetDuplicateReward(tool)
	local rarity = tostring(tool and tool.Rarity or "Common")
	local rank = BitKaisenCursedTools.RarityOrder[rarity] or 1
	return {
		Money = 120 * rank,
		CursedEnergy = math.max(1, 2 * rank),
	}
end

function BitKaisenCursedTools.GetSellValue(tool)
	if tonumber(tool and tool.BlackMarketPrice) then
		return math.floor(tool.BlackMarketPrice * 0.35)
	end
	return BitKaisenCursedTools.GetDuplicateReward(tool).Money
end

function BitKaisenCursedTools.SellTool(stats, toolId)
	local def = BitKaisenCursedTools.GetTool(toolId)
	local owned = BitKaisenCursedTools.EnsureInventory(stats)
	if not def or not owned[def.Id] then
		return false, 0, nil
	end

	local payout = BitKaisenCursedTools.GetSellValue(def)
	owned[def.Id] = nil
	if stats.EquippedCursedToolId == def.Id then
		stats.EquippedCursedToolId = nil
	end
	return true, payout, def
end

function BitKaisenCursedTools.EquipTool(stats, toolId)
	local owned = BitKaisenCursedTools.EnsureInventory(stats)
	local def = BitKaisenCursedTools.ResolveTool(stats, toolId)
	if not def or not owned[def.Id] then
		return false, "You do not own that cursed tool."
	end
	if BitKaisenCursedTools.IsEquipped(stats, def.Id) then
		return true, def
	end

	local limit = BitKaisenCursedTools.GetEquipLimit(stats)
	local current = BitKaisenCursedTools.GetEquippedIds(stats)
	if #current >= limit then
		return false, "You can carry " .. tostring(limit) .. " cursed tools at once. Put one away first."
	end

	if not stats.EquippedCursedToolId then
		stats.EquippedCursedToolId = def.Id
	else
		if typeof(stats.EquippedCursedToolIds) ~= "table" then
			stats.EquippedCursedToolIds = {}
		end
		table.insert(stats.EquippedCursedToolIds, def.Id)
	end
	return true, def
end

-- Passing no id puts everything away, which is what the old single-slot callers expect.
function BitKaisenCursedTools.UnequipTool(stats, toolId)
	if toolId == nil then
		stats.EquippedCursedToolId = nil
		stats.EquippedCursedToolIds = {}
		return true
	end

	local id = tostring(toolId)
	if typeof(stats.EquippedCursedToolIds) == "table" then
		for index = #stats.EquippedCursedToolIds, 1, -1 do
			if stats.EquippedCursedToolIds[index] == id then
				table.remove(stats.EquippedCursedToolIds, index)
			end
		end
	end
	if stats.EquippedCursedToolId == id then
		-- Promote one of the extras so the first slot never sits empty while others are held.
		local promoted = nil
		if typeof(stats.EquippedCursedToolIds) == "table" then
			promoted = table.remove(stats.EquippedCursedToolIds, 1)
		end
		stats.EquippedCursedToolId = promoted
	end
	return true
end

-- Sums every equipped tool rather than reading one. Multipliers multiply, everything else
-- adds, so two tools with the same affinity stack the way two of anything else would.
function BitKaisenCursedTools.GetEquippedEffects(stats)
	local combined, first = {}, nil
	for _, toolId in ipairs(BitKaisenCursedTools.GetEquippedIds(stats)) do
		local def = BitKaisenCursedTools.ResolveTool(stats, toolId)
		if def and typeof(def.Effects) == "table" then
			first = first or def
			for key, value in pairs(def.Effects) do
				local amount = tonumber(value)
				if amount then
					if key == "CEGainMult" then
						combined[key] = (tonumber(combined[key]) or 1) * amount
					else
						combined[key] = (tonumber(combined[key]) or 0) + amount
					end
				end
			end
		end
	end
	return combined, first
end

function BitKaisenCursedTools.ApplyCEGain(stats, baseAmount)
	local base = tonumber(baseAmount) or 0
	if base <= 0 then
		return base, 0, nil
	end

	local effects, def = BitKaisenCursedTools.GetEquippedEffects(stats)
	local mult = tonumber(effects.CEGainMult) or 1
	if mult <= 1 then
		return math.floor(base + 0.5), 0, def
	end

	local boosted = math.max(0, math.floor((base * mult) + 0.5))
	local bonus = math.max(0, boosted - math.floor(base + 0.5))
	return boosted, bonus, def
end

function BitKaisenCursedTools.GetCombatDropConfig(enemyPower)
	local power = tonumber(enemyPower) or 0
	local chance = math.clamp(8 + math.floor(power / 18), 8, 28)
	local maxRarity = power >= 180 and 6 or (power >= 120 and 5 or (power >= 80 and 4 or 3))
	return chance, maxRarity
end

function BitKaisenCursedTools.GetMissionDropConfig(missionGrade, combatResult)
	local grade = tostring(missionGrade or "")
	local chance = 4
	local maxRarity = 2

	if grade == "Special Grade" then
		chance = 24
		maxRarity = 6
	elseif grade == "Special Grade 1" then
		chance = 20
		maxRarity = 5
	elseif grade == "Grade 1" then
		chance = 16
		maxRarity = 5
	elseif grade == "Semi-Grade 1" then
		chance = 13
		maxRarity = 4
	elseif grade == "Grade 2" then
		chance = 10
		maxRarity = 4
	elseif grade == "Semi-Grade 2" then
		chance = 8
		maxRarity = 3
	elseif grade == "Grade 3" or grade == "Semi-Grade 3" then
		chance = 6
		maxRarity = 3
	end

	local margin = tonumber(combatResult and combatResult.Margin) or 0
	if margin >= 45 then
		chance += 4
	elseif margin <= -10 then
		chance = math.max(1, chance - 3)
	end

	return math.clamp(chance, 1, 30), maxRarity
end

function BitKaisenCursedTools.RollDrop(maxRarityRank)
	local maxRank = tonumber(maxRarityRank) or 6
	local pool = {}
	local total = 0
	for _, def in ipairs(BitKaisenCursedTools.Definitions) do
		local rarityRank = BitKaisenCursedTools.RarityOrder[def.Rarity] or 1
		if rarityRank <= maxRank then
			local weight = tonumber(def.DropWeight) or 0
			if weight > 0 then
				total += weight
				table.insert(pool, { Tool = def, Weight = weight })
			end
		end
	end
	if total <= 0 then return nil end
	local roll = math.random() * total
	local running = 0
	for _, entry in ipairs(pool) do
		running += entry.Weight
		if roll <= running then
			return entry.Tool
		end
	end
	return pool[#pool] and pool[#pool].Tool or nil
end

----------------------------------------------------------------
-- UPDATE 30: FORGING
--
-- Asked for by RUS_erious and marked Accepted by staff. The original suggestion has two
-- halves: forging your own tool, and replacing combat with a turn-based body-part system.
-- Only the forging half is here. The second half would throw away the combat rework that
-- shipped in Update 29, which is not a thing to do two days before an update log.
--
-- A forged tool is not in Definitions, so it cannot be found by the static byId lookup.
-- It carries its own definition inline on the inventory entry instead, and ResolveTool
-- checks both. Everything that used GetTool on an owned tool should use ResolveTool.
----------------------------------------------------------------

BitKaisenCursedTools.ToolTypes = {
	{ Id = "katana",  Name = "Katana",     Line = "A long edge. Cuts before it is seen.",        Power = 7, Defense = 1 },
	{ Id = "spear",   Name = "Spear",      Line = "Reach. It keeps the curse at arm's length.",  Power = 5, Defense = 4 },
	{ Id = "dagger",  Name = "Dagger",     Line = "Short and quick. Made for the opening.",      Power = 6, Defense = 0, CEGain = 0.05 },
	{ Id = "chain",   Name = "Chain Whip", Line = "Wraps, binds, and drags them back in.",       Power = 3, Defense = 6 },
}

-- The four affinities from the suggestion. In the turn-based combat RUS_erious described
-- these would be once-per-fight abilities. Combat here is not turn-based, so each one is
-- a standing effect that leans the same way the ability would have.
BitKaisenCursedTools.ToolAffinities = {
	{
		Id = "black_flames",
		Name = "Black Flames",
		Line = "It burns after the cut lands.",
		Effects = { CombatPower = 9 },
	},
	{
		Id = "lightning_control",
		Name = "Lightning Control",
		Line = "The strike arrives before the decision to move.",
		Effects = { CombatPower = 6, CEGainMult = 0.08 },
	},
	{
		Id = "barrier_bypass",
		Name = "Barrier Bypass",
		Line = "Walls are a suggestion.",
		Effects = { CombatPower = 4, MissionRiskReduction = 0.07 },
	},
	{
		Id = "technique_immunity",
		Name = "Technique Immunity",
		Line = "Their technique finds nothing to hold.",
		Effects = { DefensePower = 10 },
	},
}

-- Grade 4 is where every forged tool starts. Fighting with it grades it up, which is the
-- progression the suggestion asked for. The multiplier applies to the whole effect set,
-- so a Grade 1 tool is worth a little over twice what it was the day it was made.
BitKaisenCursedTools.ForgeGrades = {
	{ Grade = "Grade 4",       Uses = 0,  Multiplier = 1.0 },
	{ Grade = "Grade 3",       Uses = 5,  Multiplier = 1.35 },
	{ Grade = "Grade 2",       Uses = 14, Multiplier = 1.75 },
	{ Grade = "Grade 1",       Uses = 30, Multiplier = 2.2 },
	{ Grade = "Special Grade", Uses = 55, Multiplier = 2.8 },
}

BitKaisenCursedTools.ForgeCost = 14000
BitKaisenCursedTools.ForgeMinAge = 16
BitKaisenCursedTools.ForgeMinMastery = 25

local function findById(list, id)
	for _, entry in ipairs(list) do
		if entry.Id == tostring(id or "") then
			return entry
		end
	end
	return nil
end

function BitKaisenCursedTools.GetForgeGradeFor(uses: number?)
	local count = tonumber(uses) or 0
	local current = BitKaisenCursedTools.ForgeGrades[1]
	for _, step in ipairs(BitKaisenCursedTools.ForgeGrades) do
		if count >= step.Uses then
			current = step
		end
	end
	return current
end

function BitKaisenCursedTools.GetNextForgeGrade(uses: number?)
	local count = tonumber(uses) or 0
	for _, step in ipairs(BitKaisenCursedTools.ForgeGrades) do
		if count < step.Uses then
			return step
		end
	end
	return nil
end

-- Builds the definition a forged tool presents to the rest of the game. Same shape as an
-- entry in Definitions, so nothing downstream needs to know the difference.
local function buildForgedDefinition(entry)
	local typeDef = findById(BitKaisenCursedTools.ToolTypes, entry.ToolType) or BitKaisenCursedTools.ToolTypes[1]
	local affinity = findById(BitKaisenCursedTools.ToolAffinities, entry.AffinityId) or BitKaisenCursedTools.ToolAffinities[1]
	local grade = BitKaisenCursedTools.GetForgeGradeFor(entry.Uses)
	local mult = grade.Multiplier

	local effects = {
		CombatPower = math.floor(((typeDef.Power or 0) + (affinity.Effects.CombatPower or 0)) * mult + 0.5),
		DefensePower = math.floor(((typeDef.Defense or 0) + (affinity.Effects.DefensePower or 0)) * mult + 0.5),
	}
	local ceGain = (typeDef.CEGain or 0) + (affinity.Effects.CEGainMult or 0)
	if ceGain > 0 then
		effects.CEGainMult = 1 + (ceGain * mult)
	end
	local risk = affinity.Effects.MissionRiskReduction or 0
	if risk > 0 then
		effects.MissionRiskReduction = risk * mult
	end

	return {
		Id = entry.Id,
		Name = entry.Name,
		Rarity = "Forged",
		Type = typeDef.Name,
		Forged = true,
		ToolTypeId = typeDef.Id,
		AffinityId = affinity.Id,
		AffinityName = affinity.Name,
		Grade = grade.Grade,
		Uses = tonumber(entry.Uses) or 0,
		Description = typeDef.Line .. " " .. affinity.Line,
		EffectText = string.format(
			"%s, %s. +%d combat power, +%d defense while equipped.",
			grade.Grade, affinity.Name, effects.CombatPower, effects.DefensePower
		),
		Effects = effects,
	}
end

-- Definitions first, then the player's own forged tools. Use this anywhere a tool id can
-- have come from a player rather than from the catalogue.
function BitKaisenCursedTools.ResolveTool(stats, toolId)
	local def = BitKaisenCursedTools.GetTool(toolId)
	if def then
		return def
	end
	if typeof(stats) ~= "table" or typeof(stats.CursedTools) ~= "table" then
		return nil
	end
	local entry = stats.CursedTools[tostring(toolId or "")]
	if entry and entry.Forged then
		return buildForgedDefinition(entry)
	end
	return nil
end

function BitKaisenCursedTools.GetForgeOptions(stats)
	local types, affinities = {}, {}
	for _, t in ipairs(BitKaisenCursedTools.ToolTypes) do
		table.insert(types, { Id = t.Id, Name = t.Name, Line = t.Line })
	end
	for _, a in ipairs(BitKaisenCursedTools.ToolAffinities) do
		table.insert(affinities, { Id = a.Id, Name = a.Name, Line = a.Line })
	end
	local age = tonumber(stats and stats.Age) or 0
	local mastery = tonumber(stats and stats.TechniqueMastery) or 0
	local money = tonumber(stats and stats.Money) or 0
	local locked, reason = false, nil
	if age < BitKaisenCursedTools.ForgeMinAge then
		locked, reason = true, "Forging unlocks at age " .. tostring(BitKaisenCursedTools.ForgeMinAge) .. "."
	elseif mastery < BitKaisenCursedTools.ForgeMinMastery then
		locked, reason = true, "You need " .. tostring(BitKaisenCursedTools.ForgeMinMastery) .. " Technique Mastery to shape cursed energy into a tool."
	elseif money < BitKaisenCursedTools.ForgeCost then
		locked, reason = true, "Forging costs $" .. tostring(BitKaisenCursedTools.ForgeCost) .. "."
	end
	return {
		Types = types,
		Affinities = affinities,
		Cost = BitKaisenCursedTools.ForgeCost,
		Locked = locked,
		LockReason = reason,
	}
end

function BitKaisenCursedTools.ForgeTool(stats, name, toolTypeId, affinityId, year)
	if typeof(stats) ~= "table" then
		return nil, "No active life."
	end
	local options = BitKaisenCursedTools.GetForgeOptions(stats)
	if options.Locked then
		return nil, options.LockReason
	end
	local typeDef = findById(BitKaisenCursedTools.ToolTypes, toolTypeId)
	if not typeDef then
		return nil, "Choose a tool type."
	end
	local affinity = findById(BitKaisenCursedTools.ToolAffinities, affinityId)
	if not affinity then
		return nil, "Choose an affinity."
	end

	local cleanName = string.gsub(tostring(name or ""), "^%s+", "")
	cleanName = string.gsub(cleanName, "%s+$", "")
	if cleanName == "" then
		cleanName = typeDef.Name .. " of " .. affinity.Name
	end
	if #cleanName > 28 then
		cleanName = string.sub(cleanName, 1, 28)
	end

	local owned = BitKaisenCursedTools.EnsureInventory(stats)
	local id = string.format("forged_%d_%d", os.time(), math.random(1000, 9999))
	owned[id] = {
		Id = id,
		Forged = true,
		Name = cleanName,
		ToolType = typeDef.Id,
		AffinityId = affinity.Id,
		Uses = 0,
		AcquiredFrom = "Forged",
		AcquiredYear = year,
	}
	stats.Money = math.max(0, (tonumber(stats.Money) or 0) - BitKaisenCursedTools.ForgeCost)

	return buildForgedDefinition(owned[id]), nil
end

-- Called once per fight. Only forged tools track use, and only the ones actually equipped,
-- so a tool grades up because you fought with it and not because you owned it.
function BitKaisenCursedTools.RecordCombatUse(stats)
	local owned = BitKaisenCursedTools.EnsureInventory(stats)
	local graded = {}
	for _, toolId in ipairs(BitKaisenCursedTools.GetEquippedIds(stats)) do
		local entry = owned[toolId]
		if entry and entry.Forged then
			local before = BitKaisenCursedTools.GetForgeGradeFor(entry.Uses)
			entry.Uses = (tonumber(entry.Uses) or 0) + 1
			local after = BitKaisenCursedTools.GetForgeGradeFor(entry.Uses)
			if after.Grade ~= before.Grade then
				table.insert(graded, { Name = entry.Name, Grade = after.Grade })
			end
		end
	end
	return graded
end

----------------------------------------------------------------
-- UPDATE 30: MORE THAN ONE TOOL
--
-- The suggestion asks for two tools, and four under Heavenly Restriction, which fits: a
-- body with no cursed energy has nothing to spend on a technique and leans on steel.
--
-- EquippedCursedToolId stays as the first slot. Nine files and twenty four call sites read
-- it directly, and rewriting all of them the week of a release is how a release breaks.
-- The extra slots live alongside it and every reader of the old field keeps working.
----------------------------------------------------------------

function BitKaisenCursedTools.GetEquipLimit(stats)
	local technique = string.lower(tostring((stats and (stats.CursedTechnique or stats.InnateTechnique)) or ""))
	if string.find(technique, "heavenly restriction", 1, true) then
		return 4
	end
	return 2
end

function BitKaisenCursedTools.GetEquippedIds(stats)
	local owned = BitKaisenCursedTools.EnsureInventory(stats)
	local ids, seen = {}, {}
	if stats.EquippedCursedToolId and owned[stats.EquippedCursedToolId] then
		table.insert(ids, stats.EquippedCursedToolId)
		seen[stats.EquippedCursedToolId] = true
	end
	if typeof(stats.EquippedCursedToolIds) == "table" then
		for _, id in ipairs(stats.EquippedCursedToolIds) do
			if owned[id] and not seen[id] then
				table.insert(ids, id)
				seen[id] = true
			end
		end
	end
	return ids
end

function BitKaisenCursedTools.IsEquipped(stats, toolId)
	for _, id in ipairs(BitKaisenCursedTools.GetEquippedIds(stats)) do
		if id == toolId then
			return true
		end
	end
	return false
end

return BitKaisenCursedTools
