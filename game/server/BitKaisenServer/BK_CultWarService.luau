-- ModuleScript: BK_CultWarService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose: Cursed Cult war foundation, persistent war state, and cult conflict actions.
-- Dark mirror of BK_ClanWarService, adapted to Cult stats (CultInfamy/CultTerritoryControl/CultLoyalty).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BitKaisenCultData = require(ReplicatedStorage:WaitForChild("BitKaisenCultData"))
local BK_WorldHistoryService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_WorldHistoryService"))

local BK_CultWarService = {}

local context = {}

local RIVAL_CULTS = {
	"Hollow Choir Splinter", "Withering Hand Remnant", "Sable Vein Offshoot", "Ash Covenant Rival",
	"Nightbound Dissidents", "Gravebound Usurpers", "Famished Chorus Breakaway", "Widow's Lantern Rival",
	"Unspoken Order Fringe", "Grave-Salt Congregation", "Bone Orchard Sect", "Weeping Idol Circle",
	"Crimson Thread Cabal", "Marrow Choir", "Silt Tongue Sect",
	"Jujutsu Society Task Force", "Jujutsu Society Task Force", "Jujutsu Society Task Force",
}

local CULT_WAR_YEAR_EVENTS = {
	{
		Id = "shadow_raid",
		Weight = 24,
		TensionDelta = 9,
		Text = "A shadow raid by the %s tested your cult's wards and pushed both sides toward open conflict.",
	},
	{
		Id = "informant_leak",
		Weight = 18,
		TensionDelta = 5,
		InfamyDelta = 1,
		Text = "Whispers leaked about %s movements. Your cult used the tip to prepare countermeasures.",
	},
	{
		Id = "failed_parley",
		Weight = 18,
		TensionDelta = 7,
		Text = "A secret parley with the %s collapsed before any truce could take shape.",
	},
	{
		Id = "recruit_pressure",
		Weight = 14,
		TensionDelta = 4,
		InfamyDelta = 1,
		Text = "Initiates trained harder after hearing rumors about the conflict with the %s.",
	},
	{
		Id = "quiet_lull",
		Weight = 16,
		TensionDelta = -10,
		InfamyDelta = 1,
		Text = "A quiet lull held for several weeks. The %s pulled back, but nobody trusted the silence.",
	},
	{
		Id = "public_terror",
		Weight = 10,
		TensionDelta = 6,
		FearDelta = 2,
		Text = "Civilians started whispering about the war with the %s. Fear around your cult's name grew.",
	},
}

local ACTION_DEFINITIONS = {
	CultWar_Defend = {
		Name = "Defend Sanctum",
		Description = "Protect your members and hold cult ground.",
		Risk = 22,
		Reward = "Cult infamy, territory control, lower tension",
	},
	CultWar_Strike = {
		Name = "Strike First",
		Description = "Hit the rival cult before they organize.",
		Risk = 42,
		Reward = "Big infamy/fear gain, chance to win a battle",
	},
	CultWar_Negotiate = {
		Name = "Negotiate Truce",
		Description = "Use leverage and smarts to reduce the conflict.",
		Risk = 28,
		Reward = "Lower tension or peaceful win",
	},
	CultWar_Betray = {
		Name = "Betrayal Play",
		Description = "Use underhanded pressure to profit from the conflict.",
		Risk = 48,
		Reward = "Money and fear, but loyalty can suffer",
	},
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

local function getPlayerCultName(stats)
	local cultName = tostring(stats and stats.PlayerCultName or "")
	if cultName ~= "" and cultName ~= "nil" then
		return cultName
	end
	return "Unnamed Cult"
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

local function pickRival(playerCultName)
	local cleanPlayerCult = string.lower(tostring(playerCultName or ""))
	local options = {}

	for _, cultName in ipairs(RIVAL_CULTS) do
		if string.lower(cultName) ~= cleanPlayerCult then
			table.insert(options, cultName)
		end
	end

	if #options <= 0 then
		return "Jujutsu Society Task Force"
	end

	return options[math.random(1, #options)]
end

local function playerWarPower(stats)
	return math.floor(
		((tonumber(stats.CursedEnergy) or 0) * 0.014)
		+ ((tonumber(stats.TechniqueMastery) or 0) * 0.9)
		+ ((tonumber(stats.CultInfamy) or 0) * 0.45)
		+ ((tonumber(stats.CultTerritoryControl) or 0) * 0.35)
		+ ((tonumber(stats.Reputation) or 0) * 0.2)
		+ ((tonumber(stats.Fame) or 0) * 0.45)
		+ ((tonumber(stats.Fear) or 0) * 0.35)
	)
end

local function canHaveCultWar(stats)
	if not stats or stats.Alive == false then
		return false
	end

	if stats.CultFounded == true then
		return true
	end

	if (tonumber(stats.CultMembers) or 0) >= 3 then
		return true
	end

	if (tonumber(stats.CultInfamy) or 0) >= 15 then
		return true
	end

	return false
end

function BK_CultWarService.EnsureCultWarState(stats)
	if not stats then return end
	if typeof(stats.CultWarState) ~= "table" then stats.CultWarState = {} end
	if typeof(stats.CultWarHistory) ~= "table" then stats.CultWarHistory = {} end
	stats.CultWarWins = math.max(0, tonumber(stats.CultWarWins) or 0)
	stats.CultWarLosses = math.max(0, tonumber(stats.CultWarLosses) or 0)
	stats.CultWarActions = math.max(0, tonumber(stats.CultWarActions) or 0)
	stats.CultWarCooldown = math.max(0, tonumber(stats.CultWarCooldown) or 0)

	local war = stats.CultWarState
	war.Active = war.Active == true
	war.PlayerCultName = tostring(war.PlayerCultName or getPlayerCultName(stats))
	war.RivalCultName = tostring(war.RivalCultName or "None")
	war.Tension = math.clamp(tonumber(war.Tension) or 0, 0, 100)
	war.BattlesWon = math.max(0, tonumber(war.BattlesWon) or 0)
	war.BattlesLost = math.max(0, tonumber(war.BattlesLost) or 0)
	war.Phase = tostring(war.Phase or (war.Active and "Escalating" or "Quiet"))
	war.StartYear = tonumber(war.StartYear) or getYear(stats)
	war.LastActionYear = tonumber(war.LastActionYear) or 0
	war.Description = tostring(war.Description or "No active cult war.")
	war.CanAct = war.Active == true and (tonumber(stats.CultWarCooldown) or 0) <= 0
end

local function addWarHistory(stats, text, result)
	BK_CultWarService.EnsureCultWarState(stats)
	local entry = {
		Year = getYear(stats),
		Age = tonumber(stats.Age) or 0,
		Text = tostring(text),
		Result = tostring(result or "Progress"),
	}
	table.insert(stats.CultWarHistory, entry)
	trimList(stats.CultWarHistory, 35)
	return entry
end

local function addWorldHistory(stats, text, outcome)
	BK_WorldHistoryService.AddHistory(stats, {
		Type = "Cult War",
		Text = tostring(text),
		Outcome = tostring(outcome or "Progress"),
	})
end

function BK_CultWarService.StartWar(stats, reason)
	if not stats or not canHaveCultWar(stats) then
		return false, "Cult war requires a founded cult, enough members, or enough infamy."
	end

	BK_CultWarService.EnsureCultWarState(stats)
	if stats.CultWarState.Active == true then
		return false, "A cult war is already active."
	end
	if (tonumber(stats.CultWarCooldown) or 0) > 0 then
		return false, "Your cult needs time to recover before provoking another war."
	end

	local playerCultName = getPlayerCultName(stats)
	local rivalCultName = pickRival(playerCultName)
	local tension = math.random(48, 72)

	stats.CultWarState = {
		Active = true,
		PlayerCultName = playerCultName,
		RivalCultName = rivalCultName,
		Tension = tension,
		BattlesWon = 0,
		BattlesLost = 0,
		Phase = "Escalating",
		StartYear = getYear(stats),
		LastActionYear = 0,
		Description = "The " .. tostring(rivalCultName) .. " has begun testing the borders of " .. tostring(playerCultName) .. ".",
		CanAct = true,
		Reason = tostring(reason or "Rival pressure"),
	}

	local text = tostring(playerCultName) .. " entered open conflict with the " .. tostring(rivalCultName) .. "."
	addWarHistory(stats, text, "Started")
	addWorldHistory(stats, text, "Started")
	return true, text
end

local function finishWar(stats, outcome, text)
	BK_CultWarService.EnsureCultWarState(stats)
	local war = stats.CultWarState
	war.Active = false
	war.Phase = tostring(outcome or "Resolved")
	war.CanAct = false
	war.Description = tostring(text or "The cult war ended.")
	stats.CultWarCooldown = 2

	if outcome == "Victory" then
		stats.CultWarWins += 1
	elseif outcome == "Defeat" then
		stats.CultWarLosses += 1
	end

	addWarHistory(stats, war.Description, outcome)
	addWorldHistory(stats, war.Description, outcome)
end

local function getEnemyGrade(power)
	power = tonumber(power) or 0
	if power >= 170 then return "Special Grade" end
	if power >= 115 then return "Grade 1" end
	if power >= 75 then return "Grade 2" end
	return "Grade 3"
end

local function buildCultWarEnemy(stats, war, actionId)
	local power = playerWarPower(stats)
	local tension = tonumber(war.Tension) or 50
	local actionScale = actionId == "CultWar_Defend" and 0.78 or (actionId == "CultWar_Strike" and 0.9 or 0.96)
	local enemyPower = math.clamp(math.floor((power * actionScale) + (tension * 0.38) + math.random(-8, 16)), 28, 240)
	local enemyRole = actionId == "CultWar_Defend" and "Raider" or (actionId == "CultWar_Strike" and "Vanguard" or "Enforcer")
	local comboMax = actionId == "CultWar_Betray" and 3 or 2

	return {
		Name = tostring(war.RivalCultName or "Rival Cult") .. " " .. enemyRole,
		Kind = "Cult War Fighter",
		Grade = getEnemyGrade(enemyPower),
		Power = enemyPower,
		ComboMin = 1,
		ComboMax = comboMax,
		Metadata = {
			System = "CultWar",
			ActionId = actionId,
			RivalCultName = tostring(war.RivalCultName or "Rival Cult"),
		},
	}
end

local function applyCombatOutcome(player, stats, actionId, winner)
	if not stats then return end
	BK_CultWarService.EnsureCultWarState(stats)
	local war = stats.CultWarState
	if war.Active ~= true then return end

	local message
	local result = "Combat"
	local tension = tonumber(war.Tension) or 50

	if winner == "player" then
		war.BattlesWon += 1
		local infamyGain = actionId == "CultWar_Strike" and math.random(4, 8) or math.random(2, 5)
		local territoryGain = actionId == "CultWar_Defend" and math.random(3, 6) or math.random(1, 3)
		local fearGain = actionId == "CultWar_Betray" and math.random(4, 8) or math.random(1, 3)
		war.Tension = math.clamp(tension - (actionId == "CultWar_Defend" and math.random(10, 18) or math.random(5, 12)), 0, 100)
		stats.CultInfamy = math.max(0, (tonumber(stats.CultInfamy) or 0) + infamyGain)
		stats.CultTerritoryControl = math.clamp((tonumber(stats.CultTerritoryControl) or 0) + territoryGain, 0, 100)
		stats.Fear = math.clamp((tonumber(stats.Fear) or 0) + fearGain, 0, 100)
		stats.CultRank = BitKaisenCultData.GetRankForInfamy(stats.CultInfamy)
		message = "Your cult won a direct battle against the " .. tostring(war.RivalCultName) .. ". Cult infamy +" .. tostring(infamyGain) .. ", territory control +" .. tostring(territoryGain) .. "."
		result = "Battle Won"
	elseif winner == "fled" then
		war.BattlesLost += 1
		war.Tension = math.clamp(tension + math.random(6, 12), 0, 100)
		stats.CultLoyalty = math.clamp((tonumber(stats.CultLoyalty) or 100) - math.random(1, 3), 0, 100)
		message = "You escaped the cult war battle, but the " .. tostring(war.RivalCultName) .. " claimed momentum."
		result = "Retreated"
	else
		war.BattlesLost += 1
		war.Tension = math.clamp(tension + math.random(10, 18), 0, 100)
		stats.CultLoyalty = math.clamp((tonumber(stats.CultLoyalty) or 100) - math.random(2, 5), 0, 100)
		message = "The " .. tostring(war.RivalCultName) .. " won the battle and pushed your cult back."
		result = "Battle Lost"
	end

	if war.BattlesWon >= 3 or war.Tension <= 0 then
		finishWar(stats, "Victory", tostring(war.PlayerCultName) .. " defeated the " .. tostring(war.RivalCultName) .. " through direct battles.")
		message ..= " The cult war ended in victory."
	elseif war.BattlesLost >= 3 or war.Tension >= 100 then
		finishWar(stats, "Defeat", tostring(war.RivalCultName) .. " defeated " .. tostring(war.PlayerCultName) .. " after repeated battles.")
		message ..= " The cult war ended in defeat."
	else
		war.Phase = war.Tension >= 75 and "Open War" or (war.Tension >= 40 and "Escalating" or "Truce Talks")
		war.Description = "Conflict with the " .. tostring(war.RivalCultName) .. " continues. Tension: " .. tostring(war.Tension) .. "%"
		addWarHistory(stats, message, result)
	end

	if context.FireLifeUpdate then
		context.FireLifeUpdate(player, stats, "<font color='#8a1f1f'><b>[ CULT WAR ]</b></font> " .. message)
	end
end

local function startCultWarCombat(player, stats, actionId)
	if not context.StartCombat then
		return false, nil
	end

	BK_CultWarService.EnsureCultWarState(stats)
	local war = stats.CultWarState
	local enemyConfig = buildCultWarEnemy(stats, war, actionId)
	enemyConfig.OnFinish = function(fightPlayer, session, winner, reason, fightStats)
		applyCombatOutcome(fightPlayer, fightStats or stats, actionId, winner)
	end

	local started, err = context.StartCombat(player, "Cult War", enemyConfig)
	if not started then
		return false, err
	end

	local intro
	if actionId == "CultWar_Defend" then
		intro = "The " .. tostring(war.RivalCultName) .. " ambushed your sanctum. Defend your cult in combat."
	elseif actionId == "CultWar_Strike" then
		intro = "You struck first against the " .. tostring(war.RivalCultName) .. ". Win the battle to seize momentum."
	else
		intro = "Your betrayal play drew out a dangerous enforcer from the " .. tostring(war.RivalCultName) .. ". Survive the backlash."
	end

	addWarHistory(stats, intro, "Combat Started")
	return true, intro
end

local function resolveAction(player, stats, actionId)
	BK_CultWarService.EnsureCultWarState(stats)
	local war = stats.CultWarState
	if war.Active ~= true then
		return false, "No active cult war."
	end
	if (tonumber(stats.CultWarCooldown) or 0) > 0 then
		return false, "Your cult needs time to recover before another cult war move."
	end

	local action = ACTION_DEFINITIONS[actionId]
	if not action then
		return false, "Unknown cult war action."
	end

	local power = playerWarPower(stats)
	local tension = tonumber(war.Tension) or 50
	local roll = math.random(1, 100) + math.floor(power / 12)
	local difficulty = 38 + math.floor(tension / 3) + math.floor((tonumber(war.BattlesLost) or 0) * 8)
	local success = roll >= difficulty
	local message
	local result = "Progress"

	stats.CultWarActions += 1
	war.LastActionYear = getYear(stats)

	if actionId == "CultWar_Defend" or actionId == "CultWar_Strike" or actionId == "CultWar_Betray" then
		local started, combatMessage = startCultWarCombat(player, stats, actionId)
		if started then
			return true, combatMessage
		end
	end

	if actionId == "CultWar_Defend" then
		if success then
			local infamyGain = math.random(3, 7)
			local territoryGain = math.random(2, 5)
			war.BattlesWon += 1
			war.Tension = math.clamp(tension - math.random(8, 16), 0, 100)
			stats.CultInfamy = math.max(0, (tonumber(stats.CultInfamy) or 0) + infamyGain)
			stats.CultTerritoryControl = math.clamp((tonumber(stats.CultTerritoryControl) or 0) + territoryGain, 0, 100)
			message = "Your cult held its ground against the " .. tostring(war.RivalCultName) .. ". Cult infamy +" .. tostring(infamyGain) .. ", territory control +" .. tostring(territoryGain) .. "."
		else
			local damage = math.random(5, 13)
			war.BattlesLost += 1
			war.Tension = math.clamp(tension + math.random(6, 12), 0, 100)
			stats.Health = math.clamp((tonumber(stats.Health) or 100) - damage, 0, 100)
			message = "The defense cracked under pressure from the " .. tostring(war.RivalCultName) .. ". Health -" .. tostring(damage) .. "."
			result = "Loss"
		end
	elseif actionId == "CultWar_Strike" then
		if success then
			local infamyGain = math.random(5, 11)
			local fearGain = math.random(2, 6)
			war.BattlesWon += 1
			war.Tension = math.clamp(tension - math.random(3, 9), 0, 100)
			stats.CultInfamy = math.max(0, (tonumber(stats.CultInfamy) or 0) + infamyGain)
			stats.Fear = math.clamp((tonumber(stats.Fear) or 0) + fearGain, 0, 100)
			message = "Your strike broke a rival operation. Cult infamy +" .. tostring(infamyGain) .. ", fear +" .. tostring(fearGain) .. "."
		else
			local damage = math.random(9, 20)
			war.BattlesLost += 1
			war.Tension = math.clamp(tension + math.random(10, 18), 0, 100)
			stats.Health = math.clamp((tonumber(stats.Health) or 100) - damage, 0, 100)
			stats.Reputation = math.max(0, (tonumber(stats.Reputation) or 0) - math.random(1, 4))
			message = "The rival cult read your strike and punished the advance. Health -" .. tostring(damage) .. "."
			result = "Loss"
		end
	elseif actionId == "CultWar_Negotiate" then
		local socialPower = power + math.floor((tonumber(stats.Smarts) or 0) * 0.45) + math.floor((tonumber(stats.Reputation) or 0) * 0.3)
		success = (math.random(1, 100) + math.floor(socialPower / 14)) >= (35 + math.floor(tension / 4))
		if success then
			local tensionDrop = math.random(16, 30)
			war.Tension = math.clamp(tension - tensionDrop, 0, 100)
			stats.Reputation = (tonumber(stats.Reputation) or 0) + math.random(1, 4)
			message = "Your negotiation forced the " .. tostring(war.RivalCultName) .. " to step back. Tension -" .. tostring(tensionDrop) .. "."
		else
			war.Tension = math.clamp(tension + math.random(4, 10), 0, 100)
			stats.CultInfamy = math.max(0, (tonumber(stats.CultInfamy) or 0) - math.random(1, 3))
			message = "The talks failed, and the rival cult mistook restraint for weakness."
			result = "Loss"
		end
	elseif actionId == "CultWar_Betray" then
		if success then
			local moneyGain = math.random(600, 1600)
			local fearGain = math.random(4, 9)
			war.BattlesWon += 1
			war.Tension = math.clamp(tension + math.random(4, 12), 0, 100)
			stats.Money = math.max(0, (tonumber(stats.Money) or 0) + moneyGain)
			stats.Fear = math.clamp((tonumber(stats.Fear) or 0) + fearGain, 0, 100)
			stats.CultLoyalty = math.clamp((tonumber(stats.CultLoyalty) or 100) - math.random(2, 5), 0, 100)
			message = "Your betrayal play paid off. Money +$" .. tostring(moneyGain) .. ", fear +" .. tostring(fearGain) .. ", but your cult's loyalty suffered."
		else
			local damage = math.random(12, 24)
			war.BattlesLost += 1
			war.Tension = math.clamp(tension + math.random(12, 20), 0, 100)
			stats.Health = math.clamp((tonumber(stats.Health) or 100) - damage, 0, 100)
			stats.CultLoyalty = math.clamp((tonumber(stats.CultLoyalty) or 100) - math.random(3, 8), 0, 100)
			message = "The betrayal was exposed. The rival cult retaliated immediately. Health -" .. tostring(damage) .. "."
			result = "Loss"
		end
	end

	if war.BattlesWon >= 3 or war.Tension <= 0 then
		finishWar(stats, "Victory", tostring(war.PlayerCultName) .. " forced the " .. tostring(war.RivalCultName) .. " to withdraw from the conflict.")
		message ..= " The war ended in victory."
	elseif war.BattlesLost >= 3 or war.Tension >= 100 then
		finishWar(stats, "Defeat", tostring(war.RivalCultName) .. " overwhelmed " .. tostring(war.PlayerCultName) .. " in open conflict.")
		message ..= " The war ended in defeat."
	else
		war.Phase = war.Tension >= 75 and "Open War" or (war.Tension >= 40 and "Escalating" or "Truce Talks")
		war.Description = "Conflict with the " .. tostring(war.RivalCultName) .. " continues. Tension: " .. tostring(war.Tension) .. "%"
		addWarHistory(stats, message, result)
	end

	return true, message
end

function BK_CultWarService.ProcessAction(player, actionId)
	local stats = context.GetStats and context.GetStats(player)
	if not stats then return end
	if context.EnsureExtraStats then context.EnsureExtraStats(stats) end
	BK_CultWarService.EnsureCultWarState(stats)

	local ok, message
	if actionId == "CultWar_Start" then
		ok, message = BK_CultWarService.StartWar(stats, "Player started cult war")
	else
		ok, message = resolveAction(player, stats, tostring(actionId or ""))
	end

	if context.FireLifeUpdate then
		context.FireLifeUpdate(player, stats, "<font color='#8a1f1f'><b>[ CULT WAR ]</b></font> " .. tostring(message or "Cult war updated."))
	end
	if context.SaveStats then context.SaveStats(player, "CultWar") end
	return ok, message
end

function BK_CultWarService.AdvanceYear(player, stats)
	if not stats then return "" end
	BK_CultWarService.EnsureCultWarState(stats)

	if stats.CultWarCooldown and stats.CultWarCooldown > 0 then
		stats.CultWarCooldown = math.max(0, stats.CultWarCooldown - 1)
	end

	local war = stats.CultWarState
	if war.Active == true then
		local event = weightedPick(CULT_WAR_YEAR_EVENTS) or CULT_WAR_YEAR_EVENTS[1]
		local rivalName = tostring(war.RivalCultName or "Rival Cult")
		local tensionDelta = tonumber(event.TensionDelta) or math.random(-5, 9)

		war.Tension = math.clamp((tonumber(war.Tension) or 50) + tensionDelta, 0, 100)
		war.Phase = war.Tension >= 75 and "Open War" or (war.Tension >= 40 and "Escalating" or "Truce Talks")
		war.CanAct = (tonumber(stats.CultWarCooldown) or 0) <= 0
		war.Description = "Conflict with the " .. rivalName .. " continues. Tension: " .. tostring(war.Tension) .. "%"

		stats.CultInfamy = math.max(0, (tonumber(stats.CultInfamy) or 0) + (tonumber(event.InfamyDelta) or 0))
		stats.CultRank = BitKaisenCultData.GetRankForInfamy(stats.CultInfamy)
		stats.Fear = math.clamp((tonumber(stats.Fear) or 0) + (tonumber(event.FearDelta) or 0), 0, 100)

		local eventText = string.format(tostring(event.Text or "The %s conflict shifted."), rivalName)
		addWarHistory(stats, eventText, war.Phase)
		return "\n<font color='#8a1f1f'><b>[ CULT WAR ]</b></font> " .. eventText .. " Tension: <b>" .. tostring(war.Tension) .. "%</b>."
	end

	if canHaveCultWar(stats) and (tonumber(stats.CultWarCooldown) or 0) <= 0 then
		local pressure = math.floor(((tonumber(stats.CultInfamy) or 0) + (tonumber(stats.CultTerritoryControl) or 0) + (tonumber(stats.Fame) or 0) + (tonumber(stats.Fear) or 0)) / 8)
		if math.random(1, 100) <= math.clamp(4 + pressure, 4, 18) then
			local _, text = BK_CultWarService.StartWar(stats, "Yearly rival pressure")
			return "\n<font color='#8a1f1f'><b>[ CULT WAR ]</b></font> " .. tostring(text)
		end
	end

	return ""
end

function BK_CultWarService.GetCultWarPayload(player)
	local stats = context.GetStats and context.GetStats(player)
	if not stats then
		return { Eligible = false, Active = false, Actions = ACTION_DEFINITIONS, History = {} }
	end
	if context.EnsureExtraStats then context.EnsureExtraStats(stats) end
	BK_CultWarService.EnsureCultWarState(stats)

	local war = stats.CultWarState
	return {
		Eligible = canHaveCultWar(stats),
		Active = war.Active == true,
		PlayerCultName = war.PlayerCultName,
		RivalCultName = war.RivalCultName,
		Tension = war.Tension,
		Phase = war.Phase,
		BattlesWon = war.BattlesWon,
		BattlesLost = war.BattlesLost,
		CanAct = war.CanAct,
		Cooldown = stats.CultWarCooldown,
		Description = war.Description,
		Power = playerWarPower(stats),
		Wins = stats.CultWarWins,
		Losses = stats.CultWarLosses,
		Actions = ACTION_DEFINITIONS,
		History = stats.CultWarHistory,
	}
end

function BK_CultWarService.Init(serviceContext)
	context = serviceContext or {}
	if context.IS_DEBUG then print("[BK_CultWarService] Loaded cult war service.") end
end

return BK_CultWarService
