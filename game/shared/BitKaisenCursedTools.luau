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
	local owned, equippedId = BitKaisenCursedTools.EnsureInventory(stats)
	local payload = {}
	for toolId, item in pairs(owned) do
		local def = byId[toolId]
		if def then
			table.insert(payload, {
				Id = def.Id,
				Name = def.Name,
				Rarity = def.Rarity,
				Type = def.Type,
				Description = def.Description,
				EffectText = def.EffectText,
				Equipped = equippedId == def.Id,
				AcquiredFrom = item.AcquiredFrom or "Unknown",
				AcquiredYear = item.AcquiredYear,
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

function BitKaisenCursedTools.GetDuplicateReward(tool)
	local rarity = tostring(tool and tool.Rarity or "Common")
	local rank = BitKaisenCursedTools.RarityOrder[rarity] or 1
	return {
		Money = 120 * rank,
		CursedEnergy = math.max(1, 2 * rank),
	}
end

function BitKaisenCursedTools.EquipTool(stats, toolId)
	local def = BitKaisenCursedTools.GetTool(toolId)
	local owned = BitKaisenCursedTools.EnsureInventory(stats)
	if not def or not owned[def.Id] then
		return false, "You do not own that cursed tool."
	end
	stats.EquippedCursedToolId = def.Id
	return true, def
end

function BitKaisenCursedTools.UnequipTool(stats)
	stats.EquippedCursedToolId = nil
	return true
end

function BitKaisenCursedTools.GetEquippedEffects(stats)
	local _, equippedId = BitKaisenCursedTools.EnsureInventory(stats)
	local def = BitKaisenCursedTools.GetTool(equippedId)
	if not def or typeof(def.Effects) ~= "table" then
		return {}, nil
	end
	return def.Effects, def
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

return BitKaisenCursedTools
