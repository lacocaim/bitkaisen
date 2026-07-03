-- ModuleScript: BK_CultService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose:
--   Owns the Cursed Cult system: founding, initiate recruitment, rituals,
--   tribute, territory, curse fusion, and the yearly loyalty/betrayal tick.
--   This is the dark mirror of BK_DojoService (legitimate clan/dojo).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BitKaisenCultData = require(ReplicatedStorage:WaitForChild("BitKaisenCultData"))
local BitKaisenRelationships = require(ReplicatedStorage:WaitForChild("BitKaisenRelationships"))
local BK_CurseService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_CurseService"))

local BK_CultService = {}
local context = {}

local FOUND_COST = 8000
local MIN_FOUND_AGE = 16
local MIN_FOUND_WANTED = 3
local BETRAYAL_LOYALTY_THRESHOLD = 25
local BETRAYAL_CHANCE_PERCENT = 35

local WANTED_GAIN = {
	found = { 3, 6 },
	recruit = { 1, 3 },
	ritual = { 1, 3 },
	tribute = { 2, 5 },
	territory = { 3, 7 },
	fusion = { 6, 12 },
	supply = { 2, 5 },
}

local function getYear(stats)
	if context.GetCurrentYear then
		local ok, year = pcall(context.GetCurrentYear, stats)
		if ok and tonumber(year) then
			return tonumber(year)
		end
	end
	return tonumber(stats and stats.Year) or (2000 + (tonumber(stats and stats.Age) or 0))
end

local function trimList(list, maxCount)
	while #list > maxCount do
		table.remove(list, 1)
	end
end

local function weightedPick(list)
	local totalWeight = 0
	for _, item in ipairs(list) do
		totalWeight += math.max(0, tonumber(item.Weight) or 0)
	end

	if totalWeight <= 0 then
		return list[1]
	end

	local roll = math.random() * totalWeight
	local cursor = 0
	for _, item in ipairs(list) do
		cursor += math.max(0, tonumber(item.Weight) or 0)
		if roll <= cursor then
			return item
		end
	end

	return list[#list]
end

local function addCultHistory(stats, text)
	local entry = {
		Year = getYear(stats),
		Age = tonumber(stats.Age) or 0,
		Text = tostring(text),
	}
	table.insert(stats.CultHistory, entry)
	trimList(stats.CultHistory, 35)
	return entry
end

local function raiseWantedLevel(stats, actionKind)
	local range = WANTED_GAIN[actionKind] or { 1, 3 }
	local gain = math.random(range[1], range[2])
	stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + gain, 0, 100)
end

local function getCultMembers(stats)
	local members = {}
	for _, relationship in ipairs(stats.Relationships or {}) do
		if relationship.Alive ~= false
			and (relationship.Role == "CultInitiate" or relationship.Role == "CultDisciple" or relationship.Role == "CultLieutenant") then
			table.insert(members, relationship)
		end
	end
	return members
end

local function countCultMembers(stats)
	return #getCultMembers(stats)
end

function BK_CultService.EnsureCultState(stats)
	if not stats then return end

	stats.CultFounded = stats.CultFounded == true
	stats.CultInfamy = math.max(0, tonumber(stats.CultInfamy) or 0)
	stats.CultRank = BitKaisenCultData.GetRankForInfamy(stats.CultInfamy)
	stats.CultMembers = countCultMembers(stats)
	stats.CultTreasury = math.max(0, tonumber(stats.CultTreasury) or 0)
	stats.CultLoyalty = math.clamp(tonumber(stats.CultLoyalty) or 100, 0, 100)
	stats.CultTerritory = tostring(stats.CultTerritory or "None")
	stats.CultTerritoryControl = math.clamp(tonumber(stats.CultTerritoryControl) or 0, 0, 100)
	stats.CultFocus = tostring(stats.CultFocus or "Fear")
	if typeof(stats.CultRecruitPool) ~= "table" then stats.CultRecruitPool = {} end
	stats.CultActions = math.max(0, tonumber(stats.CultActions) or 0)
	stats.CultCooldown = math.max(0, tonumber(stats.CultCooldown) or 0)
	if typeof(stats.CultHistory) ~= "table" then stats.CultHistory = {} end
	stats.CultSupplyDiscount = math.clamp(tonumber(stats.CultSupplyDiscount) or 0, 0, 60)
end

function BK_CultService.IsEligibleToFound(stats)
	if not stats or stats.Alive == false then
		return false
	end
	if stats.CultFounded == true or stats.ClanFounded == true then
		return false
	end
	return BK_CurseService.IsCurseUser(stats) or BK_CurseService.IsUnregisteredSorcerer(stats)
end

function BK_CultService.FoundCult(stats)
	BK_CultService.EnsureCultState(stats)

	if stats.CultFounded == true then
		return false, "You already lead a cursed organization."
	end
	if stats.ClanFounded == true then
		return false, "You cannot found a cult while leading a legitimate clan. Choose a side."
	end
	if not (BK_CurseService.IsCurseUser(stats) or BK_CurseService.IsUnregisteredSorcerer(stats)) then
		return false, "Only Curse Users or rogue sorcerers can found a cursed cult."
	end
	if (tonumber(stats.Age) or 0) < MIN_FOUND_AGE then
		return false, "You are too young to found a cult."
	end
	if (tonumber(stats.WantedLevel) or 0) < MIN_FOUND_WANTED then
		return false, "You need a bigger criminal reputation before anyone will follow you into a cult."
	end
	if (tonumber(stats.Money) or 0) < FOUND_COST then
		return false, "You need at least $" .. tostring(FOUND_COST) .. " to found a cult."
	end

	stats.Money -= FOUND_COST
	stats.CultFounded = true
	stats.PlayerCultName = BitKaisenCultData.PickCultName()
	stats.CultInfamy = 1
	stats.CultRank = BitKaisenCultData.GetRankForInfamy(stats.CultInfamy)
	stats.CultTreasury = 0
	stats.CultLoyalty = 100
	stats.CultTerritory = "None"
	stats.CultTerritoryControl = 0
	stats.CultMembers = 0

	raiseWantedLevel(stats, "found")
	local message = "You gathered your first followers and founded <b>" .. tostring(stats.PlayerCultName) .. "</b>. The Jujutsu Society does not know yet, but they will."
	addCultHistory(stats, message)
	return true, message
end

function BK_CultService.RecruitInitiate(stats)
	BK_CultService.EnsureCultState(stats)
	if stats.CultFounded ~= true then
		return false, "You need to found a cult first."
	end

	local candidate = BitKaisenCultData.GenerateInitiateCandidate()
	if stats.CultFocus == "Conversion" then
		candidate.Devotion = math.clamp(math.floor(candidate.Devotion * 1.5), 0, 100)
	end
	local relationship = BitKaisenRelationships.CreateRelationship(
		"CultInitiate",
		candidate.Name,
		"Neutral",
		candidate.Devotion,
		math.random(10, 30),
		math.random(10, 30),
		math.random(10, 40),
		0,
		candidate.Gender
	)
	relationship.Personality = candidate.Personality
	relationship.Background = candidate.Background
	relationship.Devotion = candidate.Devotion
	relationship.IsCultMember = true
	BitKaisenRelationships.AddRelationship(stats, relationship)

	stats.CultMembers = countCultMembers(stats)
	stats.CultInfamy = math.max(0, (tonumber(stats.CultInfamy) or 0) + math.random(1, 3))
	stats.CultRank = BitKaisenCultData.GetRankForInfamy(stats.CultInfamy)
	raiseWantedLevel(stats, "recruit")
	if stats.CultFocus == "Conversion" then
		stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) - 1, 0, 100)
	end

	local message = "<b>" .. tostring(candidate.Name) .. "</b> joined your cult as an Initiate. " .. tostring(candidate.Background)
	addCultHistory(stats, message)
	return true, message
end

function BK_CultService.BindingRitual(stats)
	BK_CultService.EnsureCultState(stats)
	if stats.CultFounded ~= true then
		return false, "You need to found a cult first."
	end

	local members = getCultMembers(stats)
	if #members <= 0 then
		return false, "You have no cult members to bind closer."
	end

	local target = members[math.random(1, #members)]
	local devotionGain = math.random(8, 18)
	target.Devotion = math.clamp((tonumber(target.Devotion) or 30) + devotionGain, 0, 100)
	target.Fear = math.clamp((tonumber(target.Fear) or 0) + math.random(2, 6), 0, 100)

	local message = "You performed a binding ritual on <b>" .. tostring(target.Name) .. "</b>. Devotion +" .. tostring(devotionGain) .. "."

	local backlashChance = stats.CultFocus == "Ritual" and 10 or 20
	if math.random(1, 100) <= backlashChance then
		local ceCost = math.random(4, 12)
		stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) - ceCost)
		stats.Health = math.clamp((tonumber(stats.Health) or 100) - math.random(2, 8), 0, 100)
		message = message .. " The ritual backlashed, costing you cursed energy and a little blood."
	else
		stats.CultLoyalty = math.clamp((tonumber(stats.CultLoyalty) or 100) + math.random(1, 4), 0, 100)
	end

	raiseWantedLevel(stats, "ritual")
	addCultHistory(stats, message)
	return true, message
end

function BK_CultService.CollectTribute(stats)
	BK_CultService.EnsureCultState(stats)
	if stats.CultFounded ~= true then
		return false, "You need to found a cult first."
	end

	local memberCount = math.max(0, tonumber(stats.CultMembers) or 0)
	if memberCount <= 0 then
		return false, "You have no members to collect tribute from."
	end

	local income = math.random(40, 120) * memberCount
	if stats.CultFocus == "Fear" then
		income = math.floor(income * 1.2)
	end
	stats.CultTreasury = (tonumber(stats.CultTreasury) or 0) + income
	local loyaltyLoss = math.random(3, 9)
	stats.CultLoyalty = math.clamp((tonumber(stats.CultLoyalty) or 100) - loyaltyLoss, 0, 100)

	raiseWantedLevel(stats, "tribute")
	local message = "You collected tribute from the membership. Treasury +$" .. tostring(income) .. ", but Loyalty fell by " .. tostring(loyaltyLoss) .. "."
	addCultHistory(stats, message)
	return true, message
end

function BK_CultService.ExpandTerritory(stats)
	BK_CultService.EnsureCultState(stats)
	if stats.CultFounded ~= true then
		return false, "You need to found a cult first."
	end

	local controlGain = math.random(6, 16)
	if stats.CultFocus == "Fear" then
		controlGain = math.floor(controlGain * 1.25)
	end
	stats.CultTerritoryControl = math.clamp((tonumber(stats.CultTerritoryControl) or 0) + controlGain, 0, 100)

	local message
	if stats.CultTerritoryControl >= 100 or tostring(stats.CultTerritory or "None") == "None" then
		local territories = BK_CurseService.CurseTerritories or {}
		local newTerritory = #territories > 0 and territories[math.random(1, #territories)] or "Unclaimed Ground"
		stats.CultTerritory = newTerritory
		stats.CultTerritoryControl = math.random(20, 40)
		message = "Your cult claimed new ground: <b>" .. tostring(newTerritory) .. "</b>."
	else
		message = "Your cult tightened its grip on <b>" .. tostring(stats.CultTerritory) .. "</b>. Territory Control +" .. tostring(controlGain) .. "."
	end

	stats.CultInfamy = math.max(0, (tonumber(stats.CultInfamy) or 0) + math.random(1, 4))
	stats.CultRank = BitKaisenCultData.GetRankForInfamy(stats.CultInfamy)
	raiseWantedLevel(stats, "territory")
	addCultHistory(stats, message)
	return true, message
end

function BK_CultService.CurseFusion(stats)
	BK_CultService.EnsureCultState(stats)
	if stats.CultFounded ~= true then
		return false, "You need to found a cult first."
	end

	local currentRankIndex = BitKaisenCultData.GetRankIndex(stats.CultRank)
	local minRankIndex = BitKaisenCultData.GetRankIndex("Black Rope Sect")
	if currentRankIndex < minRankIndex then
		return false, "Your cult needs to reach Black Rope Sect standing before it can perform a curse fusion."
	end

	local candidates = {}
	for _, relationship in ipairs(getCultMembers(stats)) do
		if relationship.Role == "CultInitiate" then
			table.insert(candidates, relationship)
		end
	end

	if #candidates <= 0 then
		return false, "You have no low-ranking initiates to fuse. Recruit more first."
	end

	local target = candidates[math.random(1, #candidates)]
	target.Alive = false
	target.DeathCause = "Consumed in a curse fusion ritual"
	target.DeathText = tostring(target.Name) .. " was consumed by the cult's founder in a curse fusion ritual."

	local ceGain = math.random(25, 60)
	stats.CursedEnergy = (tonumber(stats.CursedEnergy) or 0) + ceGain
	stats.CursedResentment = math.clamp((tonumber(stats.CursedResentment) or 0) + math.random(15, 30), 0, 999)
	stats.CultLoyalty = math.clamp((tonumber(stats.CultLoyalty) or 100) - math.random(10, 20), 0, 100)
	stats.CultMembers = countCultMembers(stats)

	raiseWantedLevel(stats, "fusion")
	local message = "<font color='#8a1f1f'><b>[ CURSE FUSION ]</b></font> You consumed <b>" .. tostring(target.Name) .. "</b> in a dark ritual. Cursed Energy +" .. tostring(ceGain) .. ". There is no undoing this."
	addCultHistory(stats, message)
	return true, message
end

function BK_CultService.SupplyRun(stats)
	BK_CultService.EnsureCultState(stats)
	if stats.CultFounded ~= true then
		return false, "You need to found a cult first."
	end

	local treasury = tonumber(stats.CultTreasury) or 0
	if treasury < 200 then
		return false, "Your cult treasury is too empty for a supply run."
	end

	local spendPercent = math.random(40, 70)
	local spent = math.floor(treasury * spendPercent / 100)
	stats.CultTreasury = math.max(0, treasury - spent)
	stats.CultSupplyDiscount = math.clamp((tonumber(stats.CultSupplyDiscount) or 0) + math.random(15, 30), 0, 60)

	raiseWantedLevel(stats, "supply")
	local message = "Your cult funneled <b>$" .. tostring(spent) .. "</b> from the treasury into black market contacts. Black market prices are discounted for a while."
	addCultHistory(stats, message)
	return true, message
end

local VALID_FOCUS = { Fear = true, Ritual = true, Conversion = true }

function BK_CultService.SetFocus(stats, focus)
	BK_CultService.EnsureCultState(stats)
	if stats.CultFounded ~= true then
		return false, "You need to found a cult first."
	end
	focus = tostring(focus or "")
	if not VALID_FOCUS[focus] then
		return false, "Unknown cult focus."
	end

	stats.CultFocus = focus
	local message = "Your cult's focus shifted to <b>" .. focus .. "</b>."
	addCultHistory(stats, message)
	return true, message
end

local LIEUTENANT_CAP_BY_RANK = {
	["No Cult"] = 0,
	["Whispering Circle"] = 0,
	["Hollow Congregation"] = 1,
	["Black Rope Sect"] = 2,
	["Vengeful Order"] = 3,
	["Disaster Cult"] = 5,
}

local function countLieutenants(stats)
	local count = 0
	for _, relationship in ipairs(getCultMembers(stats)) do
		if relationship.Role == "CultLieutenant" then
			count += 1
		end
	end
	return count
end

function BK_CultService.ReviewMembers(stats)
	BK_CultService.EnsureCultState(stats)
	if stats.CultFounded ~= true then
		return false, "You need to found a cult first."
	end

	local ritualFocus = stats.CultFocus == "Ritual"
	local devotionThreshold = ritualFocus and 47 or 55
	local trustThreshold = ritualFocus and 34 or 40
	local lieutenantDevotionThreshold = ritualFocus and 68 or 80
	local lieutenantTrustThreshold = ritualFocus and 51 or 60
	local lieutenantFearThreshold = ritualFocus and 26 or 30

	local promotions = {}
	local lieutenantCap = LIEUTENANT_CAP_BY_RANK[stats.CultRank] or 0
	local currentLieutenants = countLieutenants(stats)

	for _, relationship in ipairs(getCultMembers(stats)) do
		if relationship.Role == "CultInitiate"
			and (tonumber(relationship.Devotion) or 0) >= devotionThreshold
			and (tonumber(relationship.Trust) or 0) >= trustThreshold then
			relationship.Role = "CultDisciple"
			table.insert(promotions, tostring(relationship.Name) .. " rose to Disciple.")
		elseif relationship.Role == "CultDisciple"
			and (tonumber(relationship.Devotion) or 0) >= lieutenantDevotionThreshold
			and (tonumber(relationship.Trust) or 0) >= lieutenantTrustThreshold
			and (tonumber(relationship.Fear) or 0) >= lieutenantFearThreshold
			and currentLieutenants < lieutenantCap then
			relationship.Role = "CultLieutenant"
			currentLieutenants += 1
			table.insert(promotions, tostring(relationship.Name) .. " was named Lieutenant.")
		end
	end

	if #promotions <= 0 then
		return false, "No members qualified for promotion this review."
	end

	local message = "<b>[ CULT REVIEW ]</b> " .. table.concat(promotions, " ")
	addCultHistory(stats, message)
	return true, message
end

function BK_CultService.ProcessActivity(player, stats, activityId)
	BK_CultService.EnsureCultState(stats)
	stats.CultActions = (tonumber(stats.CultActions) or 0) + 1

	if activityId == "cult_found" then
		return BK_CultService.FoundCult(stats)
	elseif activityId == "cult_recruit_initiate" then
		return BK_CultService.RecruitInitiate(stats)
	elseif activityId == "cult_binding_ritual" then
		return BK_CultService.BindingRitual(stats)
	elseif activityId == "cult_collect_tribute" then
		return BK_CultService.CollectTribute(stats)
	elseif activityId == "cult_expand_territory" then
		return BK_CultService.ExpandTerritory(stats)
	elseif activityId == "cult_curse_fusion" then
		return BK_CultService.CurseFusion(stats)
	elseif activityId == "cult_supply_run" then
		return BK_CultService.SupplyRun(stats)
	elseif activityId == "cult_review_members" then
		return BK_CultService.ReviewMembers(stats)
	end

	return false, "Unknown cult activity."
end

function BK_CultService.AdvanceYear(player, stats)
	if not stats then return "" end
	BK_CultService.EnsureCultState(stats)

	if stats.CultCooldown and stats.CultCooldown > 0 then
		stats.CultCooldown = math.max(0, stats.CultCooldown - 1)
	end

	if stats.CultSupplyDiscount and stats.CultSupplyDiscount > 0 then
		stats.CultSupplyDiscount = math.max(0, stats.CultSupplyDiscount - 10)
	end

	if stats.CultFounded ~= true then
		return ""
	end

	if (tonumber(stats.CultLoyalty) or 100) < BETRAYAL_LOYALTY_THRESHOLD and math.random(1, 100) <= BETRAYAL_CHANCE_PERCENT then
		local event = weightedPick(BitKaisenCultData.BETRAYAL_EVENTS)
		local message = tostring(event and event.Text or "Your cult suffered an internal betrayal.")

		if event and event.Id == "treasury_theft" then
			local loss = math.floor((tonumber(stats.CultTreasury) or 0) * math.random(20, 45) / 100)
			stats.CultTreasury = math.max(0, (tonumber(stats.CultTreasury) or 0) - loss)
			message = message .. " Treasury -$" .. tostring(loss) .. "."
		elseif event and event.Id == "mass_desertion" then
			local members = getCultMembers(stats)
			local toRemove = math.min(#members, math.random(1, 3))
			for i = 1, toRemove do
				local victim = members[i]
				if victim then
					victim.Alive = false
					victim.DeathCause = "Left the cult"
					victim.DeathText = tostring(victim.Name) .. " abandoned the cult."
				end
			end
			stats.CultMembers = countCultMembers(stats)
		elseif event and event.Id == "informant_leak" then
			stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + math.random(8, 15), 0, 100)
		end

		stats.CultLoyalty = math.clamp((tonumber(stats.CultLoyalty) or 0) + math.random(5, 15), 0, 100)
		addCultHistory(stats, message)
		return "\n<font color='#8a1f1f'><b>[ CULT ]</b></font> " .. message
	end

	return ""
end

local function buildCultRoster(stats)
	local roster = {}
	for index, relationship in ipairs(getCultMembers(stats)) do
		table.insert(roster, {
			Id = relationship.Id or ("cult_member_" .. tostring(index)),
			Name = relationship.Name,
			Role = relationship.Role,
			Devotion = relationship.Devotion,
			Trust = relationship.Trust,
			Fear = relationship.Fear,
			Personality = relationship.Personality,
			Background = relationship.Background,
		})
	end
	return roster
end

function BK_CultService.GetCultPayload(player)
	local stats = context.GetStats and context.GetStats(player)
	if not stats then
		return { Founded = false }
	end
	if context.EnsureExtraStats then context.EnsureExtraStats(stats) end
	BK_CultService.EnsureCultState(stats)

	return {
		Founded = stats.CultFounded == true,
		Eligible = BK_CultService.IsEligibleToFound(stats),
		CultName = stats.PlayerCultName,
		Infamy = stats.CultInfamy,
		Rank = stats.CultRank,
		Members = stats.CultMembers,
		Treasury = stats.CultTreasury,
		Loyalty = stats.CultLoyalty,
		Territory = stats.CultTerritory,
		TerritoryControl = stats.CultTerritoryControl,
		Focus = stats.CultFocus,
		Actions = BitKaisenCultData.ACTION_DEFINITIONS,
		History = stats.CultHistory,
		Roster = buildCultRoster(stats),
	}
end

local ACTIVITY_BY_ACTION_ID = {
	Cult_Found = "cult_found",
	Cult_RecruitInitiate = "cult_recruit_initiate",
	Cult_BindingRitual = "cult_binding_ritual",
	Cult_CollectTribute = "cult_collect_tribute",
	Cult_ExpandTerritory = "cult_expand_territory",
	Cult_CurseFusion = "cult_curse_fusion",
	Cult_SupplyRun = "cult_supply_run",
	Cult_ReviewMembers = "cult_review_members",
}

function BK_CultService.ProcessCultAction(player, actionId, targetId)
	local stats = context.GetStats and context.GetStats(player)
	if not stats or not stats.Alive then
		return
	end
	if context.EnsureExtraStats then context.EnsureExtraStats(stats) end

	if actionId == "Cult_SetFocus" then
		local ok, message = BK_CultService.SetFocus(stats, targetId)
		if context.FireLifeUpdate then
			context.FireLifeUpdate(player, stats, "<font color='#8a1f1f'><b>[ CULT ]</b></font> " .. tostring(message or "Cult updated."))
		end
		if ok and context.SaveStats then
			context.SaveStats(player, "Cult")
		end
		return
	end

	local activityId = ACTIVITY_BY_ACTION_ID[actionId]
	if not activityId then
		if context.FireLifeUpdate then
			context.FireLifeUpdate(player, stats, "Unknown cult action.")
		end
		return
	end

	local ok, message = BK_CultService.ProcessActivity(player, stats, activityId)
	if context.FireLifeUpdate then
		context.FireLifeUpdate(player, stats, "<font color='#8a1f1f'><b>[ CULT ]</b></font> " .. tostring(message or "Cult updated."))
	end
	if ok and context.SaveStats then
		context.SaveStats(player, "Cult")
	end
end

function BK_CultService.Init(ctx)
	context = ctx or {}
end

return BK_CultService
