-- ModuleScript: BK_GodModeService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose: Server-owned God Mode buffs and premium life controls.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BitKaisenStats = require(ReplicatedStorage:WaitForChild("BitKaisenStats"))
local BitKaisenTraits = require(ReplicatedStorage:WaitForChild("BitKaisenTraits"))

local BK_GodModeService = {}
local context = {}

local MAX_TRAIT_ADDS = 2
local MAX_TRAIT_REMOVES = 2
local MAX_CLAN_REROLLS = 3

local RARITY_RANK = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
	Secret = 6,
}

local VALID_START_BOOSTS = {
	None = true,
	CE = true,
	Stats = true,
	Luck = true,
}

local function cloneShallow(source)
	local copy = {}
	if typeof(source) == "table" then
		for key, value in pairs(source) do
			copy[key] = value
		end
	end
	return copy
end

function BK_GodModeService.EnsureSettings(stats)
	if typeof(stats) ~= "table" then
		return {}
	end

	stats.GodModeSettings = typeof(stats.GodModeSettings) == "table" and stats.GodModeSettings or {}
	local settings = stats.GodModeSettings

	settings.StartBoost = tostring(settings.StartBoost or stats.GodModeStartBoostChoice or "None")
	if not VALID_START_BOOSTS[settings.StartBoost] then
		settings.StartBoost = "None"
	end

	settings.GuaranteedLegacyTraits = settings.GuaranteedLegacyTraits == true or stats.GodModeGuaranteedLegacyTraits == true
	stats.GodModeGuaranteedLegacyTraits = settings.GuaranteedLegacyTraits
	stats.GodModeStartBoostChoice = settings.StartBoost
	stats.GodModeTraitAddsUsed = math.clamp(tonumber(stats.GodModeTraitAddsUsed) or 0, 0, MAX_TRAIT_ADDS)
	stats.GodModeTraitRemovesUsed = math.clamp(tonumber(stats.GodModeTraitRemovesUsed) or 0, 0, MAX_TRAIT_REMOVES)
	stats.GodModeClanRerollsUsed = math.clamp(tonumber(stats.GodModeClanRerollsUsed) or 0, 0, MAX_CLAN_REROLLS)
	stats.GodModeStartBoostApplied = stats.GodModeStartBoostApplied == true
	stats.GodModeLuckBoost = settings.StartBoost == "Luck" and stats.GodModeStartBoostApplied == true

	return settings
end

function BK_GodModeService.CloneSettings(stats)
	if typeof(stats) ~= "table" then
		return nil
	end
	return cloneShallow(BK_GodModeService.EnsureSettings(stats))
end

local function ownsGodMode(player)
	if context.OwnsGodModePass then
		return context.OwnsGodModePass(player) == true
	end
	return false
end

local function getStats(player)
	if context.GetStats then
		return context.GetStats(player)
	end
	return nil
end

local function notify(player, stats, text)
	if context.FireLifeUpdate then
		context.FireLifeUpdate(player, stats, text)
	end
end

local function save(player, reason)
	if context.SaveStats then
		context.SaveStats(player, reason or "GodMode")
	end
end

local function getTraitList(stats)
	local owned = {}
	if typeof(stats) == "table" and typeof(stats.Traits) == "table" then
		for _, traitId in ipairs(stats.Traits) do
			local trait = BitKaisenTraits.GetTrait(traitId)
			if trait then
				table.insert(owned, {
					Id = trait.Id,
					Name = trait.Name,
					Rarity = trait.Rarity,
					Description = trait.Description,
				})
			end
		end
	end
	return owned
end

local SPECIAL_ORIGINS = {
	{
		Id = "ryomen_clan",
		DisplayName = "Ryomen Clan",
		Category = "Clan",
		FamilyType = "Sorcerer",
		FamilyName = "Ryomen",
		BonusCE = 36,
		BonusSmarts = 6,
		InnatePool = { { Name = "Shrine", Weight = 100 } },
	},
}

local function getClanOptionsPayload()
	local list = {}
	for _, origin in ipairs(BitKaisenStats.Origins or {}) do
		if typeof(origin) == "table" and tonumber(origin.Chance) and tonumber(origin.Chance) > 0 then
			table.insert(list, {
				Name = tostring(origin.DisplayName or origin.FamilyName or "Unknown"),
				FamilyName = tostring(origin.FamilyName or origin.DisplayName or "Unknown"),
				Category = tostring(origin.Category or "Clan"),
				Chance = tonumber(origin.Chance) or 0,
			})
		end
	end
	for _, origin in ipairs(SPECIAL_ORIGINS) do
		table.insert(list, {
			Name = tostring(origin.DisplayName or origin.FamilyName or "Unknown"),
			FamilyName = tostring(origin.FamilyName or origin.DisplayName or "Unknown"),
			Category = tostring(origin.Category or "Special"),
			Chance = 0,
		})
	end
	table.sort(list, function(a, b)
		if a.Chance ~= b.Chance then return a.Chance < b.Chance end
		return a.Name < b.Name
	end)
	return list
end

local function findOriginByName(name)
	local needle = string.lower(tostring(name or ""))
	if needle == "" then return nil end
	local allSources = { BitKaisenStats.Origins or {}, SPECIAL_ORIGINS }
	for _, sourceList in ipairs(allSources) do
		for _, origin in ipairs(sourceList) do
			local displayName = string.lower(tostring(origin.DisplayName or ""))
			local familyName = string.lower(tostring(origin.FamilyName or ""))
			if displayName == needle or familyName == needle then
				return origin
			end
		end
	end
	for _, sourceList in ipairs(allSources) do
		for _, origin in ipairs(sourceList) do
			local displayName = string.lower(tostring(origin.DisplayName or ""))
			local familyName = string.lower(tostring(origin.FamilyName or ""))
			if displayName:find(needle, 1, true) or familyName:find(needle, 1, true) then
				return origin
			end
		end
	end
	return nil
end

local function getAllTraitsPayload()
	local list = {}
	for _, trait in ipairs(BitKaisenTraits.Definitions or {}) do
		table.insert(list, {
			Id = trait.Id,
			Name = trait.Name,
			Rarity = trait.Rarity,
			Category = trait.Category,
			Description = trait.Description,
		})
	end
	table.sort(list, function(a, b)
		local rankA = RARITY_RANK[a.Rarity] or 0
		local rankB = RARITY_RANK[b.Rarity] or 0
		if rankA ~= rankB then
			return rankA > rankB
		end
		return tostring(a.Name) < tostring(b.Name)
	end)
	return list
end

function BK_GodModeService.GetPayload(player)
	local stats = getStats(player)
	if not stats then
		return { Owned = false, Error = "No life loaded." }
	end

	local settings = BK_GodModeService.EnsureSettings(stats)
	return {
		Owned = ownsGodMode(player),
		PassId = context.PassIds and context.PassIds.GOD_MODE_PASS_ID or 0,
		PriceNote = "Raise the live God Mode price by +200-400 Robux in Creator Dashboard.",
		Settings = cloneShallow(settings),
		TraitAddsUsed = stats.GodModeTraitAddsUsed,
		TraitAddsMax = MAX_TRAIT_ADDS,
		TraitRemovesUsed = stats.GodModeTraitRemovesUsed,
		TraitRemovesMax = MAX_TRAIT_REMOVES,
		ClanRerollsUsed = stats.GodModeClanRerollsUsed,
		ClanRerollsMax = MAX_CLAN_REROLLS,
		CurrentClan = tostring(stats.Clan or stats.Origin or "Unknown"),
		ClanOptions = getClanOptionsPayload(),
		CurrentTraits = getTraitList(stats),
		Traits = getAllTraitsPayload(),
		StartBoostApplied = stats.GodModeStartBoostApplied == true,
	}
end

local function updateTraitSummary(stats)
	BitKaisenTraits.EnsureTraits(stats)
	stats.TraitSummary = BitKaisenTraits.GetTraitDisplay(stats)
end

local function addTrait(stats, trait)
	stats.Traits = typeof(stats.Traits) == "table" and stats.Traits or {}
	for _, owned in ipairs(stats.Traits) do
		local ownedTrait = BitKaisenTraits.GetTrait(owned)
		if ownedTrait and ownedTrait.Id == trait.Id then
			return false, "You already have that trait."
		end
	end
	table.insert(stats.Traits, trait.Id)
	updateTraitSummary(stats)
	return true
end

local function removeTrait(stats, trait)
	stats.Traits = typeof(stats.Traits) == "table" and stats.Traits or {}
	for index = #stats.Traits, 1, -1 do
		local ownedTrait = BitKaisenTraits.GetTrait(stats.Traits[index])
		if ownedTrait and ownedTrait.Id == trait.Id then
			table.remove(stats.Traits, index)
			updateTraitSummary(stats)
			return true
		end
	end
	return false, "That trait is not on this life."
end

local function pickRerollOrigin(usedCount)
	local pool = {}
	local total = 0
	for _, origin in ipairs(BitKaisenStats.Origins or {}) do
		local chance = tonumber(origin.Chance) or 0
		if chance > 0 then
			local adjusted = chance
			if chance <= 1 then
				adjusted *= math.max(0.45, 1 - (usedCount * 0.18))
			elseif chance <= 2 then
				adjusted *= math.max(0.55, 1 - (usedCount * 0.12))
			elseif chance <= 3 then
				adjusted *= math.max(0.65, 1 - (usedCount * 0.08))
			end
			total += adjusted
			table.insert(pool, { Origin = origin, Weight = adjusted })
		end
	end
	if total <= 0 or #pool <= 0 then
		return BitKaisenStats.RollClan()
	end
	local roll = math.random() * total
	local cursor = 0
	for _, entry in ipairs(pool) do
		cursor += entry.Weight
		if roll <= cursor then
			return entry.Origin
		end
	end
	return pool[#pool].Origin
end

local function applyOriginReroll(stats, origin)
	if typeof(origin) ~= "table" then
		return false, "Could not roll a valid clan."
	end

	local firstName = tostring(stats.FirstName or "Unknown")
	local gender = tostring(stats.Gender or "Unknown")
	local identity = BitKaisenStats.GenerateRandomIdentity(origin, gender)
	stats.FamilyName = identity.FamilyName or origin.FamilyName or stats.FamilyName
	stats.FamilyType = identity.FamilyType or origin.FamilyType or stats.FamilyType
	stats.Gender = identity.Gender or stats.Gender
	stats.Name = firstName .. " " .. tostring(stats.FamilyName or "Unknown")
	stats.Clan = origin.DisplayName or stats.Clan
	stats.Origin = origin.DisplayName or stats.Origin
	stats.OriginCategory = origin.Category or stats.OriginCategory
	stats.PlayerClanName = origin.FamilyName or stats.FamilyName

	stats.CursedTechnique = "None"
	stats.InnateTechnique = "None"
	stats.PlayerClanInnateTechnique = "None"
	stats.ClanInnateTechnique = nil
	stats.BloodlineTechnique = nil
	stats.InheritedTechnique = nil
	stats.TechniqueKnown = false
	stats.TechniqueUsable = false
	stats.TechniqueAwakened = false
	stats.InnateDormant = false
	BitKaisenStats.ApplyBirthTechnique(stats, origin)

	local age = tonumber(stats.Age) or 0
	local usableNow = age >= 8
	if usableNow and tostring(stats.InnateTechnique or "None") ~= "None" then
		stats.CursedTechnique = stats.InnateTechnique
		stats.TechniqueUsable = true
		stats.TechniqueAwakened = true
		stats.InnateDormant = false
		stats.TechniqueMastery = math.max(tonumber(stats.TechniqueMastery) or 0, math.random(2, 8))
	elseif usableNow and tostring(stats.CursedTechnique or "None") == "None" then
		-- The rerolled clan has no innate technique (e.g. a Minor Sorcerer Family) --
		-- grant a normal one instead of leaving the character with none at all,
		-- matching the paid Clan Reroll's fallback in BK_CommerceService.grantClanReroll.
		local normalTechnique = BitKaisenStats.RollTechnique and BitKaisenStats.RollTechnique(tostring(stats.Origin or stats.Clan or ""), { IncludeClanLocked = false }) or "Cursed Energy Discharge"
		stats.CursedTechnique = normalTechnique
		stats.TechniqueType = "Normal"
		stats.TechniqueKnown = true
		stats.TechniqueUsable = true
		stats.TechniqueAwakened = true
		stats.InnateDormant = false
		stats.TechniqueMastery = math.max(tonumber(stats.TechniqueMastery) or 0, math.random(1, 8))
	end

	if usableNow and tostring(stats.Grade or "Non-Sorcerer") == "Non-Sorcerer" and tostring(stats.CursedTechnique or "None") ~= "None" then
		stats.Grade = "Grade 4"
	end

	return true
end

function BK_GodModeService.ApplyStartBoost(stats)
	if typeof(stats) ~= "table" then
		return ""
	end
	local settings = BK_GodModeService.EnsureSettings(stats)
	local choice = tostring(settings.StartBoost or "None")
	if choice == "None" or stats.GodModeStartBoostApplied == true then
		return ""
	end

	stats.GodModeStartBoostApplied = true
	stats.GodModeStartBoostChoice = choice

	if choice == "CE" then
		local gain = math.random(18, 28)
		stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + gain)
		return "<font color='#a782ff'><b>[ GOD MODE ]</b></font> Start Boost granted <b>+" .. tostring(gain) .. " CE</b>."
	elseif choice == "Stats" then
		local gain = math.random(4, 7)
		stats.Health = math.clamp((tonumber(stats.Health) or 100) + gain, 0, 100)
		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) + gain, 0, 100)
		stats.Smarts = math.clamp((tonumber(stats.Smarts) or 0) + gain, 0, 100)
		return "<font color='#a782ff'><b>[ GOD MODE ]</b></font> Start Boost granted <b>+" .. tostring(gain) .. "</b> to core stats."
	elseif choice == "Luck" then
		stats.GodModeLuckBoost = true
		stats.EventLuckBonus = math.max(tonumber(stats.EventLuckBonus) or 0, 8)
		return "<font color='#a782ff'><b>[ GOD MODE ]</b></font> Start Boost activated better event luck for this life."
	end

	return ""
end

local function traitImpact(trait)
	local score = (RARITY_RANK[trait.Rarity] or 0) * 1000
	if typeof(trait.Modifiers) == "table" then
		for _, value in pairs(trait.Modifiers) do
			if type(value) == "number" then
				if value >= 1 then
					score += math.floor((value - 1) * 100)
				else
					score += math.floor((1 - value) * 50)
				end
			end
		end
	end
	return score
end

function BK_GodModeService.GetStrongestTraitIds(stats, limit)
	local traits = {}
	if typeof(stats) == "table" and typeof(stats.Traits) == "table" then
		for _, traitId in ipairs(stats.Traits) do
			local trait = BitKaisenTraits.GetTrait(traitId)
			if trait then
				table.insert(traits, trait)
			end
		end
	end
	table.sort(traits, function(a, b)
		local impactA = traitImpact(a)
		local impactB = traitImpact(b)
		if impactA ~= impactB then
			return impactA > impactB
		end
		return tostring(a.Name) < tostring(b.Name)
	end)
	local ids = {}
	for index = 1, math.min(tonumber(limit) or 2, #traits) do
		table.insert(ids, traits[index].Id)
	end
	return ids
end

function BK_GodModeService.ApplyGuaranteedLegacyTraits(parentStats, childStats)
	if typeof(parentStats) ~= "table" or typeof(childStats) ~= "table" then
		return false, ""
	end
	local settings = BK_GodModeService.EnsureSettings(parentStats)
	if settings.GuaranteedLegacyTraits ~= true then
		return false, ""
	end

	childStats.Traits = typeof(childStats.Traits) == "table" and childStats.Traits or {}
	local addedNames = {}
	for _, traitId in ipairs(BK_GodModeService.GetStrongestTraitIds(parentStats, 2)) do
		local trait = BitKaisenTraits.GetTrait(traitId)
		if trait then
			local already = false
			for _, owned in ipairs(childStats.Traits) do
				local ownedTrait = BitKaisenTraits.GetTrait(owned)
				if ownedTrait and ownedTrait.Id == trait.Id then
					already = true
					break
				end
			end
			if not already then
				table.insert(childStats.Traits, trait.Id)
			end
			table.insert(addedNames, trait.Name)
		end
	end
	updateTraitSummary(childStats)

	if #addedNames > 0 then
		return true, "<font color='#a782ff'><b>[ GOD MODE ]</b></font> Guaranteed Legacy Traits passed down: <b>" .. table.concat(addedNames, ", ") .. "</b>."
	end
	return false, ""
end

function BK_GodModeService.ProcessAction(player, actionId, data)
	local stats = getStats(player)
	if not stats then
		return false, "No life loaded."
	end
	BK_GodModeService.EnsureSettings(stats)

	if ownsGodMode(player) ~= true then
		notify(player, stats, "<font color='#e53935'><b>[ GOD MODE ]</b></font> Unlock God Mode to use these controls.")
		return false, "God Mode required."
	end

	data = typeof(data) == "table" and data or {}
	actionId = tostring(actionId or "")

	if actionId == "set_start_boost" then
		local choice = tostring(data.Choice or "None")
		if not VALID_START_BOOSTS[choice] then choice = "None" end
		stats.GodModeSettings.StartBoost = choice
		stats.GodModeStartBoostChoice = choice
		notify(player, stats, "<font color='#a782ff'><b>[ GOD MODE ]</b></font> Start Boost set to <b>" .. choice .. "</b>. It applies at the start of a fresh life.")
		save(player, "GodModeStartBoost")
		return true
	elseif actionId == "toggle_legacy_traits" then
		local enabled = data.Enabled == true
		stats.GodModeSettings.GuaranteedLegacyTraits = enabled
		stats.GodModeGuaranteedLegacyTraits = enabled
		notify(player, stats, "<font color='#a782ff'><b>[ GOD MODE ]</b></font> Guaranteed Legacy Traits <b>" .. (enabled and "enabled" or "disabled") .. "</b>.")
		save(player, "GodModeLegacyTraits")
		return true
	elseif actionId == "add_trait" then
		if stats.GodModeTraitAddsUsed >= MAX_TRAIT_ADDS then
			notify(player, stats, "<font color='#e53935'><b>[ GOD MODE ]</b></font> Trait add limit reached for this character.")
			return false, "Trait add limit reached."
		end
		local trait = BitKaisenTraits.GetTrait(data.TraitId or data.TraitName)
		if not trait then
			notify(player, stats, "<font color='#e53935'><b>[ GOD MODE ]</b></font> Trait not found.")
			return false, "Trait not found."
		end
		local ok, errorMessage = addTrait(stats, trait)
		if not ok then
			notify(player, stats, "<font color='#e53935'><b>[ GOD MODE ]</b></font> " .. tostring(errorMessage))
			return false, errorMessage
		end
		stats.GodModeTraitAddsUsed += 1
		notify(player, stats, "<font color='#a782ff'><b>[ GOD MODE ]</b></font> Added trait <b>" .. trait.Name .. "</b> (" .. tostring(stats.GodModeTraitAddsUsed) .. "/" .. tostring(MAX_TRAIT_ADDS) .. ").")
		save(player, "GodModeAddTrait")
		return true
	elseif actionId == "remove_trait" then
		if stats.GodModeTraitRemovesUsed >= MAX_TRAIT_REMOVES then
			notify(player, stats, "<font color='#e53935'><b>[ GOD MODE ]</b></font> Trait remove limit reached for this character.")
			return false, "Trait remove limit reached."
		end
		local trait = BitKaisenTraits.GetTrait(data.TraitId or data.TraitName)
		if not trait then
			notify(player, stats, "<font color='#e53935'><b>[ GOD MODE ]</b></font> Trait not found.")
			return false, "Trait not found."
		end
		local ok, errorMessage = removeTrait(stats, trait)
		if not ok then
			notify(player, stats, "<font color='#e53935'><b>[ GOD MODE ]</b></font> " .. tostring(errorMessage))
			return false, errorMessage
		end
		stats.GodModeTraitRemovesUsed += 1
		notify(player, stats, "<font color='#a782ff'><b>[ GOD MODE ]</b></font> Removed trait <b>" .. trait.Name .. "</b> (" .. tostring(stats.GodModeTraitRemovesUsed) .. "/" .. tostring(MAX_TRAIT_REMOVES) .. ").")
		save(player, "GodModeRemoveTrait")
		return true
	elseif actionId == "select_clan" then
		local origin = findOriginByName(data.ClanName or data.Clan)
		local ok, errorMessage = applyOriginReroll(stats, origin)
		if not ok then
			notify(player, stats, "<font color='#e53935'><b>[ GOD MODE ]</b></font> " .. tostring(errorMessage or "Clan not found."))
			return false, errorMessage or "Clan not found."
		end
		notify(player, stats, "<font color='#a782ff'><b>[ GOD MODE ]</b></font> Clan selected: <b>" .. tostring(stats.Clan or "Unknown") .. "</b>.")
		save(player, "GodModeSelectClan")
		return true
	elseif actionId == "reroll_clan" then
		if stats.GodModeClanRerollsUsed >= MAX_CLAN_REROLLS then
			notify(player, stats, "<font color='#e53935'><b>[ GOD MODE ]</b></font> Clan reroll limit reached for this character.")
			return false, "Clan reroll limit reached."
		end
		local usedBefore = stats.GodModeClanRerollsUsed
		local origin = pickRerollOrigin(usedBefore)
		local ok, errorMessage = applyOriginReroll(stats, origin)
		if not ok then
			notify(player, stats, "<font color='#e53935'><b>[ GOD MODE ]</b></font> " .. tostring(errorMessage))
			return false, errorMessage
		end
		stats.GodModeClanRerollsUsed += 1
		notify(player, stats, "<font color='#a782ff'><b>[ GOD MODE ]</b></font> Clan rerolled into <b>" .. tostring(stats.Clan or "Unknown") .. "</b> (" .. tostring(stats.GodModeClanRerollsUsed) .. "/" .. tostring(MAX_CLAN_REROLLS) .. "). Rare odds are slightly lower after each reroll.")
		save(player, "GodModeClanReroll")
		return true
	end

	return false, "Unknown God Mode action."
end

function BK_GodModeService.Init(ctx)
	context = ctx or {}
end

return BK_GodModeService
