-- ModuleScript: BK_ClanWarService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose: Update 13 clan war foundation, persistent war state, and clan conflict actions.

local ServerScriptService = game:GetService("ServerScriptService")

local BK_WorldHistoryService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_WorldHistoryService"))

local BK_ClanWarService = {}

local context = {}

local RIVAL_CLANS = {
	"Gojo", "Zenin", "Kamo", "Inumaki", "Itadori", "Fushiguro", "Nanami", "Todo", "Ieiri", "Kusakabe",
	"Kumiwado", "Mizukara", "Amahara", "Tsukigane", "Kurogiri", "Hoshinari", "Yamashiro", "Shinkawa", "Morikage", "Fushidori",
}

local CLAN_WAR_YEAR_EVENTS = {
	{
		Id = "border_raid",
		Weight = 24,
		TensionDelta = 9,
		Text = "A border raid by the %s Clan injured minor allies and pushed both sides closer to open war.",
	},
	{
		Id = "intel_leak",
		Weight = 18,
		TensionDelta = 5,
		RepDelta = 1,
		Text = "Rumors leaked about %s Clan movements. Your clan used the information to prepare countermeasures.",
	},
	{
		Id = "failed_talks",
		Weight = 18,
		TensionDelta = 7,
		Text = "A private meeting with the %s Clan collapsed before any truce could form.",
	},
	{
		Id = "student_pressure",
		Weight = 14,
		TensionDelta = 4,
		PrestigeDelta = 1,
		Text = "Younger sorcerers trained harder after hearing stories about the %s Clan conflict.",
	},
	{
		Id = "quiet_truce",
		Weight = 16,
		TensionDelta = -10,
		RepDelta = 1,
		Text = "A quiet truce held for several weeks. The %s Clan stepped back, but nobody trusted the silence.",
	},
	{
		Id = "public_fear",
		Weight = 10,
		TensionDelta = 6,
		FearDelta = 2,
		Text = "Civilians started whispering about the %s Clan war. Fear around your name grew.",
	},
}

local ACTION_DEFINITIONS = {
	ClanWar_Defend = {
		Name = "Defend Territory",
		Description = "Protect your students and hold clan ground.",
		Risk = 22,
		Reward = "Clan reputation, dojo prestige, lower tension",
	},
	ClanWar_Strike = {
		Name = "Strike First",
		Description = "Hit the rival clan before they organize.",
		Risk = 42,
		Reward = "Big reputation/fear gain, chance to win a battle",
	},
	ClanWar_Negotiate = {
		Name = "Negotiate Truce",
		Description = "Use reputation and smarts to reduce the conflict.",
		Risk = 28,
		Reward = "Lower tension or peaceful win",
	},
	ClanWar_Betray = {
		Name = "Betrayal Play",
		Description = "Use underhanded pressure to profit from the conflict.",
		Risk = 48,
		Reward = "Money and fear, but reputation can suffer",
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

local function getPlayerClanName(stats)
	local playerClan = tostring(stats and stats.PlayerClanName or "")
	if playerClan ~= "" and playerClan ~= "nil" then
		return playerClan
	end

	local dojoClan = tostring(stats and stats.DojoClanBaseName or "")
	if dojoClan ~= "" and dojoClan ~= "nil" then
		return dojoClan
	end

	local familyName = tostring(stats and stats.FamilyName or "")
	if familyName ~= "" and familyName ~= "Unknown" and familyName ~= "nil" then
		return familyName
	end

	local clan = tostring(stats and stats.Clan or stats and stats.Origin or "")
	clan = clan:gsub(" Clan$", "")
	clan = clan:gsub(" Lineage$", "")
	if clan ~= "" and clan ~= "Minor Sorcerer Family" and clan ~= "Civilian Family" then
		return clan
	end

	return "Unnamed"
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

local function pickRival(playerClanName)
	local cleanPlayerClan = string.lower(tostring(playerClanName or ""))
	local options = {}

	for _, clanName in ipairs(RIVAL_CLANS) do
		if string.lower(clanName) ~= cleanPlayerClan then
			table.insert(options, clanName)
		end
	end

	if #options <= 0 then
		return "Zenin"
	end

	return options[math.random(1, #options)]
end

local function playerWarPower(stats)
	return math.floor(
		((tonumber(stats.CursedEnergy) or 0) * 0.014)
		+ ((tonumber(stats.TechniqueMastery) or 0) * 0.9)
		+ ((tonumber(stats.ClanReputation) or 0) * 0.45)
		+ ((tonumber(stats.DojoPrestige) or 0) * 0.35)
		+ ((tonumber(stats.Reputation) or 0) * 0.2)
		+ ((tonumber(stats.Fame) or 0) * 0.45)
		+ ((tonumber(stats.Fear) or 0) * 0.35)
	)
end

local function canHaveClanWar(stats)
	if not stats or stats.Alive == false then
		return false
	end

	if stats.ClanFounded == true then
		return true
	end

	if (tonumber(stats.ClanMembers) or 0) >= 3 then
		return true
	end

	if tostring(stats.PlayerClanName or "") ~= "" then
		return true
	end

	if (tonumber(stats.DojoPrestige) or 0) >= 20 and (tonumber(stats.ClanReputation) or 0) >= 15 then
		return true
	end

	return false
end

function BK_ClanWarService.EnsureClanWarState(stats)
	if not stats then return end
	if typeof(stats.ClanWarState) ~= "table" then stats.ClanWarState = {} end
	if typeof(stats.ClanWarHistory) ~= "table" then stats.ClanWarHistory = {} end
	stats.ClanWarWins = math.max(0, tonumber(stats.ClanWarWins) or 0)
	stats.ClanWarLosses = math.max(0, tonumber(stats.ClanWarLosses) or 0)
	stats.ClanWarActions = math.max(0, tonumber(stats.ClanWarActions) or 0)
	stats.ClanWarCooldown = math.max(0, tonumber(stats.ClanWarCooldown) or 0)

	local war = stats.ClanWarState
	war.Active = war.Active == true
	war.PlayerClanName = tostring(war.PlayerClanName or getPlayerClanName(stats))
	war.RivalClanName = tostring(war.RivalClanName or "None")
	war.Tension = math.clamp(tonumber(war.Tension) or 0, 0, 100)
	war.BattlesWon = math.max(0, tonumber(war.BattlesWon) or 0)
	war.BattlesLost = math.max(0, tonumber(war.BattlesLost) or 0)
	war.Phase = tostring(war.Phase or (war.Active and "Escalating" or "Quiet"))
	war.StartYear = tonumber(war.StartYear) or getYear(stats)
	war.LastActionYear = tonumber(war.LastActionYear) or 0
	war.Description = tostring(war.Description or "No active clan war.")
	war.CanAct = war.Active == true and (tonumber(stats.ClanWarCooldown) or 0) <= 0
end

local function addWarHistory(stats, text, result)
	BK_ClanWarService.EnsureClanWarState(stats)
	local entry = {
		Year = getYear(stats),
		Age = tonumber(stats.Age) or 0,
		Text = tostring(text),
		Result = tostring(result or "Progress"),
	}
	table.insert(stats.ClanWarHistory, entry)
	trimList(stats.ClanWarHistory, 35)
	return entry
end

local function addWorldHistory(stats, text, outcome)
	BK_WorldHistoryService.AddHistory(stats, {
		Type = "Clan War",
		Text = tostring(text),
		Outcome = tostring(outcome or "Progress"),
	})
end

function BK_ClanWarService.StartWar(stats, reason)
	if not stats or not canHaveClanWar(stats) then
		return false, "Clan war requires an established clan, dojo, or clan reputation."
	end

	BK_ClanWarService.EnsureClanWarState(stats)
	if stats.ClanWarState.Active == true then
		return false, "A clan war is already active."
	end
	if (tonumber(stats.ClanWarCooldown) or 0) > 0 then
		return false, "Your clan needs time to recover before provoking another war."
	end

	local playerClanName = getPlayerClanName(stats)
	local rivalClanName = pickRival(playerClanName)
	local tension = math.random(48, 72)

	stats.ClanWarState = {
		Active = true,
		PlayerClanName = playerClanName,
		RivalClanName = rivalClanName,
		Tension = tension,
		BattlesWon = 0,
		BattlesLost = 0,
		Phase = "Escalating",
		StartYear = getYear(stats),
		LastActionYear = 0,
		Description = "The " .. tostring(rivalClanName) .. " Clan has begun testing the borders of the " .. tostring(playerClanName) .. " Clan.",
		CanAct = true,
		Reason = tostring(reason or "Rival pressure"),
	}

	local text = "The " .. tostring(playerClanName) .. " Clan entered open conflict with the " .. tostring(rivalClanName) .. " Clan."
	addWarHistory(stats, text, "Started")
	addWorldHistory(stats, text, "Started")
	return true, text
end

local function finishWar(stats, outcome, text)
	BK_ClanWarService.EnsureClanWarState(stats)
	local war = stats.ClanWarState
	war.Active = false
	war.Phase = tostring(outcome or "Resolved")
	war.CanAct = false
	war.Description = tostring(text or "The clan war ended.")
	stats.ClanWarCooldown = 2

	if outcome == "Victory" then
		stats.ClanWarWins += 1
	elseif outcome == "Defeat" then
		stats.ClanWarLosses += 1
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

local function buildClanWarEnemy(stats, war, actionId)
	local power = playerWarPower(stats)
	local tension = tonumber(war.Tension) or 50
	local actionScale = actionId == "ClanWar_Defend" and 0.78 or (actionId == "ClanWar_Strike" and 0.9 or 0.96)
	local enemyPower = math.clamp(math.floor((power * actionScale) + (tension * 0.38) + math.random(-8, 16)), 28, 240)
	local enemyRole = actionId == "ClanWar_Defend" and "Raider" or (actionId == "ClanWar_Strike" and "Vanguard" or "Assassin")
	local comboMax = actionId == "ClanWar_Betray" and 3 or 2

	return {
		Name = tostring(war.RivalClanName or "Rival") .. " Clan " .. enemyRole,
		Kind = "Clan War Fighter",
		Grade = getEnemyGrade(enemyPower),
		Power = enemyPower,
		ComboMin = 1,
		ComboMax = comboMax,
		Metadata = {
			System = "ClanWar",
			ActionId = actionId,
			RivalClanName = tostring(war.RivalClanName or "Rival Clan"),
		},
	}
end

local function applyCombatOutcome(player, stats, actionId, winner)
	if not stats then return end
	BK_ClanWarService.EnsureClanWarState(stats)
	local war = stats.ClanWarState
	if war.Active ~= true then return end

	local message
	local result = "Combat"
	local tension = tonumber(war.Tension) or 50

	if winner == "player" then
		war.BattlesWon += 1
		local repGain = actionId == "ClanWar_Strike" and math.random(4, 8) or math.random(2, 5)
		local prestigeGain = actionId == "ClanWar_Defend" and math.random(3, 6) or math.random(1, 3)
		local fearGain = actionId == "ClanWar_Betray" and math.random(4, 8) or math.random(1, 3)
		war.Tension = math.clamp(tension - (actionId == "ClanWar_Defend" and math.random(10, 18) or math.random(5, 12)), 0, 100)
		stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) + repGain)
		stats.DojoPrestige = math.max(0, (tonumber(stats.DojoPrestige) or 0) + prestigeGain)
		stats.Fear = math.clamp((tonumber(stats.Fear) or 0) + fearGain, 0, 100)
		message = "Your clan won a direct battle against the " .. tostring(war.RivalClanName) .. " Clan. Clan reputation +" .. tostring(repGain) .. ", dojo prestige +" .. tostring(prestigeGain) .. "."
		result = "Battle Won"
	elseif winner == "fled" then
		war.BattlesLost += 1
		war.Tension = math.clamp(tension + math.random(6, 12), 0, 100)
		stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) - math.random(1, 3))
		message = "You escaped the clan war battle, but the " .. tostring(war.RivalClanName) .. " Clan claimed momentum."
		result = "Retreated"
	else
		war.BattlesLost += 1
		war.Tension = math.clamp(tension + math.random(10, 18), 0, 100)
		stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) - math.random(2, 5))
		message = "The " .. tostring(war.RivalClanName) .. " Clan won the battle and pushed your clan back."
		result = "Battle Lost"
	end

	if war.BattlesWon >= 3 or war.Tension <= 0 then
		finishWar(stats, "Victory", "The " .. tostring(war.PlayerClanName) .. " Clan defeated the " .. tostring(war.RivalClanName) .. " Clan through direct battles.")
		message ..= " The clan war ended in victory."
	elseif war.BattlesLost >= 3 or war.Tension >= 100 then
		finishWar(stats, "Defeat", "The " .. tostring(war.RivalClanName) .. " Clan defeated the " .. tostring(war.PlayerClanName) .. " Clan after repeated battles.")
		message ..= " The clan war ended in defeat."
	else
		war.Phase = war.Tension >= 75 and "Open War" or (war.Tension >= 40 and "Escalating" or "Truce Talks")
		war.Description = "Conflict with the " .. tostring(war.RivalClanName) .. " Clan continues. Tension: " .. tostring(war.Tension) .. "%"
		addWarHistory(stats, message, result)
	end

	if context.FireLifeUpdate then
		context.FireLifeUpdate(player, stats, "<font color='#ffcf57'><b>[ CLAN WAR ]</b></font> " .. message)
	end
end

local function startClanWarCombat(player, stats, actionId)
	if not context.StartCombat then
		return false, nil
	end

	BK_ClanWarService.EnsureClanWarState(stats)
	local war = stats.ClanWarState
	local enemyConfig = buildClanWarEnemy(stats, war, actionId)
	enemyConfig.OnFinish = function(fightPlayer, session, winner, reason, fightStats)
		applyCombatOutcome(fightPlayer, fightStats or stats, actionId, winner)
	end

	local started, err = context.StartCombat(player, "Clan War", enemyConfig)
	if not started then
		return false, err
	end

	local intro
	if actionId == "ClanWar_Defend" then
		intro = "The " .. tostring(war.RivalClanName) .. " Clan attacked your territory. Defend your clan in combat."
	elseif actionId == "ClanWar_Strike" then
		intro = "You launched a strike against the " .. tostring(war.RivalClanName) .. " Clan. Win the battle to seize momentum."
	else
		intro = "Your betrayal play drew out a dangerous " .. tostring(war.RivalClanName) .. " Clan fighter. Survive the backlash."
	end

	addWarHistory(stats, intro, "Combat Started")
	return true, intro
end

local function resolveAction(player, stats, actionId)
	BK_ClanWarService.EnsureClanWarState(stats)
	local war = stats.ClanWarState
	if war.Active ~= true then
		return false, "No active clan war."
	end
	if (tonumber(stats.ClanWarCooldown) or 0) > 0 then
		return false, "Your clan needs time to recover before another clan war move."
	end

	local action = ACTION_DEFINITIONS[actionId]
	if not action then
		return false, "Unknown clan war action."
	end

	local power = playerWarPower(stats)
	local tension = tonumber(war.Tension) or 50
	local roll = math.random(1, 100) + math.floor(power / 12)
	local difficulty = 38 + math.floor(tension / 3) + math.floor((tonumber(war.BattlesLost) or 0) * 8)
	local success = roll >= difficulty
	local message
	local result = "Progress"

	stats.ClanWarActions += 1
	war.LastActionYear = getYear(stats)

	if actionId == "ClanWar_Defend" or actionId == "ClanWar_Strike" or actionId == "ClanWar_Betray" then
		local started, combatMessage = startClanWarCombat(player, stats, actionId)
		if started then
			return true, combatMessage
		end
	end

	if actionId == "ClanWar_Defend" then
		if success then
			local repGain = math.random(3, 7)
			local prestigeGain = math.random(2, 5)
			war.BattlesWon += 1
			war.Tension = math.clamp(tension - math.random(8, 16), 0, 100)
			stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) + repGain)
			stats.DojoPrestige = math.max(0, (tonumber(stats.DojoPrestige) or 0) + prestigeGain)
			message = "Your clan held its ground against the " .. tostring(war.RivalClanName) .. " Clan. Clan reputation +" .. tostring(repGain) .. ", dojo prestige +" .. tostring(prestigeGain) .. "."
		else
			local damage = math.random(5, 13)
			war.BattlesLost += 1
			war.Tension = math.clamp(tension + math.random(6, 12), 0, 100)
			stats.Health = math.clamp((tonumber(stats.Health) or 100) - damage, 0, 100)
			message = "The defense cracked under pressure from the " .. tostring(war.RivalClanName) .. " Clan. Health -" .. tostring(damage) .. "."
			result = "Loss"
		end
	elseif actionId == "ClanWar_Strike" then
		if success then
			local repGain = math.random(5, 11)
			local fearGain = math.random(2, 6)
			war.BattlesWon += 1
			war.Tension = math.clamp(tension - math.random(3, 9), 0, 100)
			stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) + repGain)
			stats.Fear = math.clamp((tonumber(stats.Fear) or 0) + fearGain, 0, 100)
			message = "Your strike broke a rival operation. Clan reputation +" .. tostring(repGain) .. ", fear +" .. tostring(fearGain) .. "."
		else
			local damage = math.random(9, 20)
			war.BattlesLost += 1
			war.Tension = math.clamp(tension + math.random(10, 18), 0, 100)
			stats.Health = math.clamp((tonumber(stats.Health) or 100) - damage, 0, 100)
			stats.Reputation = math.max(0, (tonumber(stats.Reputation) or 0) - math.random(1, 4))
			message = "The rival clan read your strike and punished the advance. Health -" .. tostring(damage) .. "."
			result = "Loss"
		end
	elseif actionId == "ClanWar_Negotiate" then
		local socialPower = power + math.floor((tonumber(stats.Smarts) or 0) * 0.45) + math.floor((tonumber(stats.Reputation) or 0) * 0.3)
		success = (math.random(1, 100) + math.floor(socialPower / 14)) >= (35 + math.floor(tension / 4))
		if success then
			local tensionDrop = math.random(16, 30)
			war.Tension = math.clamp(tension - tensionDrop, 0, 100)
			stats.Reputation = (tonumber(stats.Reputation) or 0) + math.random(1, 4)
			message = "Your negotiation forced the " .. tostring(war.RivalClanName) .. " Clan to step back. Tension -" .. tostring(tensionDrop) .. "."
		else
			war.Tension = math.clamp(tension + math.random(4, 10), 0, 100)
			stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) - math.random(1, 3))
			message = "The talks failed, and the rival clan mistook restraint for weakness."
			result = "Loss"
		end
	elseif actionId == "ClanWar_Betray" then
		if success then
			local moneyGain = math.random(600, 1600)
			local fearGain = math.random(4, 9)
			war.BattlesWon += 1
			war.Tension = math.clamp(tension + math.random(4, 12), 0, 100)
			stats.Money = math.max(0, (tonumber(stats.Money) or 0) + moneyGain)
			stats.Fear = math.clamp((tonumber(stats.Fear) or 0) + fearGain, 0, 100)
			stats.Reputation = math.max(0, (tonumber(stats.Reputation) or 0) - math.random(2, 5))
			message = "Your betrayal play paid off. Money +$" .. tostring(moneyGain) .. ", fear +" .. tostring(fearGain) .. ", but your reputation suffered."
		else
			local damage = math.random(12, 24)
			war.BattlesLost += 1
			war.Tension = math.clamp(tension + math.random(12, 20), 0, 100)
			stats.Health = math.clamp((tonumber(stats.Health) or 100) - damage, 0, 100)
			stats.Reputation = math.max(0, (tonumber(stats.Reputation) or 0) - math.random(3, 8))
			message = "The betrayal was exposed. The rival clan retaliated immediately. Health -" .. tostring(damage) .. "."
			result = "Loss"
		end
	end

	if war.BattlesWon >= 3 or war.Tension <= 0 then
		finishWar(stats, "Victory", "The " .. tostring(war.PlayerClanName) .. " Clan forced the " .. tostring(war.RivalClanName) .. " Clan to withdraw from the conflict.")
		message ..= " The war ended in victory."
	elseif war.BattlesLost >= 3 or war.Tension >= 100 then
		finishWar(stats, "Defeat", "The " .. tostring(war.RivalClanName) .. " Clan overwhelmed the " .. tostring(war.PlayerClanName) .. " Clan in open conflict.")
		message ..= " The war ended in defeat."
	else
		war.Phase = war.Tension >= 75 and "Open War" or (war.Tension >= 40 and "Escalating" or "Truce Talks")
		war.Description = "Conflict with the " .. tostring(war.RivalClanName) .. " Clan continues. Tension: " .. tostring(war.Tension) .. "%"
		addWarHistory(stats, message, result)
	end

	return true, message
end

function BK_ClanWarService.ProcessAction(player, actionId)
	local stats = context.GetStats and context.GetStats(player)
	if not stats then return end
	if context.EnsureExtraStats then context.EnsureExtraStats(stats) end
	BK_ClanWarService.EnsureClanWarState(stats)

	local ok, message
	if actionId == "ClanWar_Start" then
		ok, message = BK_ClanWarService.StartWar(stats, "Player started clan war test")
	else
		ok, message = resolveAction(player, stats, tostring(actionId or ""))
	end

	if context.FireLifeUpdate then
		context.FireLifeUpdate(player, stats, "<font color='#ffcf57'><b>[ CLAN WAR ]</b></font> " .. tostring(message or "Clan war updated."))
	end
	if context.SaveStats then context.SaveStats(player, "ClanWar") end
	return ok, message
end

function BK_ClanWarService.AdvanceYear(player, stats)
	if not stats then return "" end
	BK_ClanWarService.EnsureClanWarState(stats)

	if stats.ClanWarCooldown and stats.ClanWarCooldown > 0 then
		stats.ClanWarCooldown = math.max(0, stats.ClanWarCooldown - 1)
	end

	local war = stats.ClanWarState
	if war.Active == true then
		local event = weightedPick(CLAN_WAR_YEAR_EVENTS) or CLAN_WAR_YEAR_EVENTS[1]
		local rivalName = tostring(war.RivalClanName or "Rival")
		local tensionDelta = tonumber(event.TensionDelta) or math.random(-5, 9)

		war.Tension = math.clamp((tonumber(war.Tension) or 50) + tensionDelta, 0, 100)
		war.Phase = war.Tension >= 75 and "Open War" or (war.Tension >= 40 and "Escalating" or "Truce Talks")
		war.CanAct = (tonumber(stats.ClanWarCooldown) or 0) <= 0
		war.Description = "Conflict with the " .. rivalName .. " Clan continues. Tension: " .. tostring(war.Tension) .. "%"

		stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) + (tonumber(event.RepDelta) or 0))
		stats.DojoPrestige = math.max(0, (tonumber(stats.DojoPrestige) or 0) + (tonumber(event.PrestigeDelta) or 0))
		stats.Fear = math.clamp((tonumber(stats.Fear) or 0) + (tonumber(event.FearDelta) or 0), 0, 100)

		local eventText = string.format(tostring(event.Text or "The %s Clan conflict shifted."), rivalName)
		addWarHistory(stats, eventText, war.Phase)
		return "\n<font color='#ffcf57'><b>[ CLAN WAR ]</b></font> " .. eventText .. " Tension: <b>" .. tostring(war.Tension) .. "%</b>."
	end

	if canHaveClanWar(stats) and (tonumber(stats.ClanWarCooldown) or 0) <= 0 then
		local pressure = math.floor(((tonumber(stats.ClanReputation) or 0) + (tonumber(stats.DojoPrestige) or 0) + (tonumber(stats.Fame) or 0) + (tonumber(stats.Fear) or 0)) / 8)
		if math.random(1, 100) <= math.clamp(4 + pressure, 4, 18) then
			local _, text = BK_ClanWarService.StartWar(stats, "Yearly rival pressure")
			return "\n<font color='#ffcf57'><b>[ CLAN WAR ]</b></font> " .. tostring(text)
		end
	end

	return ""
end

function BK_ClanWarService.GetClanWarPayload(player)
	local stats = context.GetStats and context.GetStats(player)
	if not stats then
		return { Eligible = false, Active = false, Actions = ACTION_DEFINITIONS, History = {} }
	end
	if context.EnsureExtraStats then context.EnsureExtraStats(stats) end
	BK_ClanWarService.EnsureClanWarState(stats)

	local war = stats.ClanWarState
	return {
		Eligible = canHaveClanWar(stats),
		Active = war.Active == true,
		PlayerClanName = war.PlayerClanName,
		RivalClanName = war.RivalClanName,
		Tension = war.Tension,
		Phase = war.Phase,
		BattlesWon = war.BattlesWon,
		BattlesLost = war.BattlesLost,
		CanAct = war.CanAct,
		Cooldown = stats.ClanWarCooldown,
		Description = war.Description,
		Power = playerWarPower(stats),
		Wins = stats.ClanWarWins,
		Losses = stats.ClanWarLosses,
		Actions = ACTION_DEFINITIONS,
		History = stats.ClanWarHistory,
	}
end

function BK_ClanWarService.Init(serviceContext)
	context = serviceContext or {}
	print("[BK_ClanWarService] Loaded clan war service.")
end

return BK_ClanWarService
