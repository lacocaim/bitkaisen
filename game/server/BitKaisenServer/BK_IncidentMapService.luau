local ReplicatedStorage = game:GetService("ReplicatedStorage")

local incidentMapModule =
	assert(ReplicatedStorage:WaitForChild("BitKaisenIncidentMap", 10), "BitKaisenIncidentMap module missing")
local BitKaisenIncidentMap = require(incidentMapModule)
local BitKaisenCurseEvolution = require(ReplicatedStorage:WaitForChild("BitKaisenCurseEvolution"))
local BK_Remotes = require(script.Parent:WaitForChild("BK_Remotes"))

local BK_IncidentMapService = {}

local context = {}
local initialized = false

local function clamp(value, minValue, maxValue)
	return math.clamp(tonumber(value) or 0, minValue or 0, maxValue or 100)
end

local function getStats(player)
	if context.GetStats then
		return context.GetStats(player)
	end
	return nil
end

local function refresh(player, stats, message)
	if context.FireLifeUpdate then
		context.FireLifeUpdate(player, stats, message or "", false)
	end
end

local function save(player)
	if context.SaveStats then
		context.SaveStats(player, "IncidentMap")
	end
end

local function checkRateLimit(player, key)
	if context.CheckRateLimit then
		return context.CheckRateLimit(player, key)
	end
	return true
end

local function getLocationState(stats, locationId)
	local map = BitKaisenIncidentMap.EnsureMapState(stats)
	if not map then
		return nil, nil
	end
	local definition = BitKaisenIncidentMap.GetLocationDefinition(locationId)
	if not definition then
		return nil, nil
	end
	return definition, map.Locations[locationId]
end

local function addLogPrefix(prefix, body)
	return "<font color='#b27aff'><b>[ " .. tostring(prefix) .. " ]</b></font> " .. tostring(body or "")
end

local function resolveFatalDamage(stats, message)
	if (tonumber(stats.Health) or 100) > 0 then
		return message
	end

	local miracleCharges = tonumber(stats.MiracleCharges) or 0
	if tostring(stats.CursedTechnique) == "Miracle" and miracleCharges > 0 then
		stats.MiracleCharges = miracleCharges - 1
		stats.Health = 1
		return message
			.. "\n<font color='#c8a4ff'><b>[ MIRACLE ]</b></font> A miracle rewrote your fate. Marks remaining: <b>"
			.. tostring(stats.MiracleCharges)
			.. "</b>."
	end

	stats.Alive = false
	return message .. "\nYour body did not survive the incident."
end

local function getPower(stats)
	local cursedEnergy = tonumber(stats.CursedEnergy) or 0
	local mastery = tonumber(stats.TechniqueMastery) or 0
	local smarts = tonumber(stats.Smarts) or 0
	local health = tonumber(stats.Health) or 100
	local reputation = tonumber(stats.Reputation) or 0
	return math.floor(
		(cursedEnergy * 0.22)
			+ (mastery * 1.2)
			+ (smarts * 0.35)
			+ (health * 0.25)
			+ math.max(0, reputation * 0.15)
			+ math.random(10, 45)
	)
end

local function getCursePower(stats)
	local cursedEnergy = tonumber(stats.CursedEnergy) or 0
	local mastery = tonumber(stats.TechniqueMastery) or 0
	local health = tonumber(stats.Health) or 100
	local threat = tonumber(stats.CurseThreat) or 0
	local evolution = tonumber(stats.CurseEvolutionProgress) or 0
	return math.floor(
		(cursedEnergy * 0.25)
			+ (mastery * 1.1)
			+ (health * 0.25)
			+ (threat * 0.6)
			+ (evolution * 0.5)
			+ math.random(15, 55)
	)
end

local function openCurseFileIfNeeded(stats, location)
	if stats.CurseClassified == true then
		return ""
	end

	stats.CurseClassified = true
	stats.SocietyStatus = "Registered Cursed Spirit"

	local grade = tostring(stats.CurseGrade or "Unregistered Grade 3 Cursed Spirit")
	grade = grade:gsub("Unregistered ", "")
	if not string.find(grade, "Cursed Spirit", 1, true) then
		grade = "Grade 3 Cursed Spirit"
	end
	stats.CurseGrade = grade

	return "\n<font color='#e53935'><b>[ JUJUTSU SOCIETY FILE OPENED ]</b></font> After the death of an investigator near <b>"
		.. tostring(location.Name)
		.. "</b>, Jujutsu Society confirmed your existence. Classification: <b>"
		.. tostring(stats.CurseGrade)
		.. "</b>."
end

local function applySorcererAction(stats, definition, state, actionId)
	local message = ""

	if actionId == "investigate" then
		local found = math.random(1, 100) <= (45 + math.floor((tonumber(stats.Smarts) or 0) / 3))
		stats.Smarts = clamp((stats.Smarts or 0) + math.random(1, 3), 0, 100)
		state.SocietyAttention = clamp(state.SocietyAttention + math.random(4, 9), 0, 100)
		if found then
			stats.Reputation = (tonumber(stats.Reputation) or 0) + 2
			state.CursedResidue = clamp(state.CursedResidue - math.random(4, 8), 0, 100)
			message = "You investigated <b>"
				.. definition.Name
				.. "</b> and found real cursed residue near the rumor site. (+Smarts, +Reputation)"
		else
			message = "You investigated <b>"
				.. definition.Name
				.. "</b>, but the trail went cold. Society attention still rose around the location."
		end
	elseif actionId == "search_residue" then
		local gain = math.random(5, 14)
		stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + gain)
		stats.TechniqueMastery = clamp((stats.TechniqueMastery or 0) + math.random(0, 2), 0, 100)
		state.CursedResidue = clamp(state.CursedResidue - math.random(3, 7), 0, 100)
		message = "You studied cursed residue at <b>"
			.. definition.Name
			.. "</b>. The trace sharpened your control. (+"
			.. tostring(gain)
			.. " CE)"
	elseif actionId == "exorcise_threat" then
		local playerPower = getPower(stats)
		stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) - 10)
		local threatPower = (tonumber(state.Threat) or 0) * 2
			+ (tonumber(state.CursedResidue) or 0)
			+ math.random(20, 80)
		if playerPower >= threatPower then
			local cursedEnergyGain = math.random(10, 24)
			stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + cursedEnergyGain)
			stats.Reputation = (tonumber(stats.Reputation) or 0) + math.random(4, 9)
			stats.Recommendations = math.max(0, tonumber(stats.Recommendations) or 0)
				+ (math.random(1, 100) <= 20 and 1 or 0)
			state.Threat = clamp(state.Threat - math.random(18, 32), 0, 100)
			state.Fear = clamp(state.Fear - math.random(8, 18), 0, 100)
			state.ActiveIncident = state.Threat >= 35
			message = "You exorcised the threat at <b>"
				.. definition.Name
				.. "</b>. Civilians stopped whispering about it for now. (10 CE spent, +CE, +Reputation)"
		else
			local damage = math.random(8, 22)
			stats.Health = clamp((stats.Health or 100) - damage, 0, 100)
			state.Threat = clamp(state.Threat + math.random(4, 10), 0, 100)
			state.Fear = clamp(state.Fear + math.random(5, 12), 0, 100)
			message = "The threat at <b>"
				.. definition.Name
				.. "</b> was worse than expected. You survived, but the rumor grew louder. (-"
				.. tostring(damage)
				.. " Health, 10 CE spent)"
		end
	elseif actionId == "protect_civilians" then
		stats.Reputation = (tonumber(stats.Reputation) or 0) + math.random(2, 6)
		stats.Happiness = clamp((stats.Happiness or 50) + math.random(1, 4), 0, 100)
		state.Fear = clamp(state.Fear - math.random(5, 12), 0, 100)
		state.SocietyAttention = clamp(state.SocietyAttention + math.random(2, 5), 0, 100)
		message = "You protected civilians around <b>"
			.. definition.Name
			.. "</b>. People still felt watched, but fewer were hurt. (+Reputation)"
	else
		return false, "That Incident Map action is not available."
	end

	state.LastResult = message:gsub("<.->", "")
	return true, addLogPrefix("INCIDENT MAP", message)
end

local function applyCursedSpiritAction(stats, definition, state, actionId)
	local message = ""

	if actionId == "claim_haunt" then
		state.ControlledBy = "You"
		state.Control = clamp(state.Control + math.random(10, 20), 0, 100)
		state.Fear = clamp(state.Fear + math.random(4, 10), 0, 100)
		state.SocietyAttention = clamp(state.SocietyAttention + math.random(2, 7), 0, 100)
		stats.CurseTerritory = definition.Name
		stats.CurseTerritoryControl = clamp(
			(stats.CurseTerritoryControl or 0) + math.random(3, 8),
			0,
			100
		)
		message = "You pressed your presence into <b>"
			.. definition.Name
			.. "</b>. The location started to feel like your haunt."
	elseif actionId == "feed_fear" then
		local gain = math.random(10, 24) + math.floor((tonumber(state.Fear) or 0) / 10)
		stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + gain)
		stats.CurseHunger = clamp((stats.CurseHunger or 50) - math.random(12, 24), 0, 100)
		stats.CurseThreat = math.max(0, (tonumber(stats.CurseThreat) or 0) + math.random(2, 6))
		local evolutionResult =
			BitKaisenCurseEvolution.AddProgress(stats, math.random(3, 9), "Feeding from an Incident Map haunt")
		state.Fear = clamp(state.Fear + math.random(3, 8), 0, 100)
		state.SocietyAttention = clamp(state.SocietyAttention + math.random(3, 9), 0, 100)
		message = "You fed from the fear around <b>"
			.. definition.Name
			.. "</b>. The emotion was thin, but enough to strengthen your cursed body. (+"
			.. tostring(gain)
			.. " CE)"
			.. tostring(evolutionResult.Message or "")
	elseif actionId == "spread_rumor" then
		local rumor = BitKaisenIncidentMap.GetRandomRumor(definition)
		state.Rumor = rumor
		stats.CurseRumor = rumor
		stats.CurseRumorSpread = math.max(0, (tonumber(stats.CurseRumorSpread) or 0) + math.random(8, 18))
		stats.CurseThreat = math.max(0, (tonumber(stats.CurseThreat) or 0) + math.random(4, 10))
		state.Fear = clamp(state.Fear + math.random(8, 16), 0, 100)
		state.SocietyAttention = clamp(state.SocietyAttention + math.random(5, 12), 0, 100)
		message = "A new rumor spread through <b>"
			.. definition.Name
			.. "</b>: <b>"
			.. rumor
			.. "</b>. Humans gave your shape a name."
	elseif actionId == "hide_residue" then
		local reduction = math.random(8, 18) + math.floor((tonumber(stats.TechniqueMastery) or 0) / 12)
		state.CursedResidue = clamp(state.CursedResidue - reduction, 0, 100)
		state.SocietyAttention = clamp(state.SocietyAttention - math.random(6, 14), 0, 100)
		stats.ExorcismRisk = clamp((stats.ExorcismRisk or 0) - math.random(5, 13), 0, 100)
		stats.HuntersEscaped = math.max(0, (tonumber(stats.HuntersEscaped) or 0) + 1)
		message = "You folded your cursed energy into the walls of <b>"
			.. definition.Name
			.. "</b>. Investigators lost the trail. (-Exorcism Risk)"
	elseif actionId == "move_territory" then
		stats.CurseTerritory = definition.Name
		stats.CurseTerritoryControl = clamp(math.max(10, state.Control), 0, 100)
		state.ControlledBy = "You"
		state.Control = clamp(state.Control + math.random(6, 14), 0, 100)
		message = "You abandoned your old haunt and settled into <b>"
			.. definition.Name
			.. "</b>. This place now carries your presence."
	elseif actionId == "ambush_investigator" then
		local cursePower = getCursePower(stats)
		local investigatorPower = 80 + (tonumber(state.SocietyAttention) or 0) + math.random(20, 120)
		state.SocietyAttention = clamp(state.SocietyAttention + math.random(8, 18), 0, 100)
		stats.ExorcismRisk = clamp((stats.ExorcismRisk or 0) + math.random(8, 18), 0, 100)

		if cursePower >= investigatorPower then
			local gain = math.random(18, 38)
			stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + gain)
			stats.SorcerersKilled = math.max(0, (tonumber(stats.SorcerersKilled) or 0) + 1)
			stats.CurseThreat = math.max(0, (tonumber(stats.CurseThreat) or 0) + math.random(12, 24))
			local evolutionResult =
				BitKaisenCurseEvolution.AddProgress(stats, math.random(10, 22), "Ambushing an investigator")
			state.Fear = clamp(state.Fear + math.random(10, 20), 0, 100)
			message = "You ambushed the investigator at <b>"
				.. definition.Name
				.. "</b>. Their fear fed your cursed body. (+"
				.. tostring(gain)
				.. " CE)"
				.. tostring(evolutionResult.Message or "")
				.. openCurseFileIfNeeded(stats, definition)
		else
			local damage = math.random(15, 35)
			stats.Health = clamp((stats.Health or 100) - damage, 0, 100)
			stats.HuntersEscaped = math.max(0, (tonumber(stats.HuntersEscaped) or 0) + 1)
			message = "You tried to ambush the investigator at <b>"
				.. definition.Name
				.. "</b>, but they survived and escaped with proof of your existence. (-"
				.. tostring(damage)
				.. " Health)"
			if stats.CurseClassified ~= true and math.random(1, 100) <= 35 then
				stats.CurseClassified = true
				stats.SocietyStatus = "Tracked Cursed Spirit"
				message ..= "\n<font color='#e53935'><b>[ TRACKED ]</b></font> Jujutsu Society did not fully classify you yet, but your file is no longer empty."
			end
		end
	else
		return false, "That Incident Map action is not available."
	end

	state.ActiveIncident = state.Threat >= 35
	state.LastResult = message:gsub("<.->", "")
	return true, addLogPrefix("INCIDENT MAP", message)
end

local function buildPayload(player)
	local stats = getStats(player)
	if not stats then
		return {
			Error = "Your life data is not loaded yet.",
			Locations = {},
			Actions = {},
		}
	end
	if stats.Alive == false then
		return {
			Error = "The Incident Map is unavailable after death.",
			Locations = {},
			Actions = {},
		}
	end

	return BitKaisenIncidentMap.BuildPayload(stats)
end

local function handleAction(player, locationId, actionId)
	if not checkRateLimit(player, "IncidentMapAction") then
		return
	end

	local stats = getStats(player)
	if not stats or stats.Alive == false then
		return
	end

	locationId = tostring(locationId or "")
	actionId = tostring(actionId or "")

	local definition, state = getLocationState(stats, locationId)
	if not definition or not state then
		refresh(player, stats, addLogPrefix("INCIDENT MAP", "That location is no longer available."))
		return
	end

	local available, unavailableReason = BitKaisenIncidentMap.IsActionAvailable(stats, actionId)
	if not available then
		refresh(player, stats, addLogPrefix("INCIDENT MAP", unavailableReason))
		return
	end

	local ok, message
	if BitKaisenIncidentMap.IsCursedSpirit(stats) then
		ok, message = applyCursedSpiritAction(stats, definition, state, actionId)
	else
		ok, message = applySorcererAction(stats, definition, state, actionId)
	end

	if ok then
		message = resolveFatalDamage(stats, message)
	end
	state.ActiveIncident = (tonumber(state.Threat) or 0) >= 35

	local map = BitKaisenIncidentMap.EnsureMapState(stats)
	if ok and map then
		map.ActionsTaken = math.max(0, tonumber(map.ActionsTaken) or 0) + 1
	end

	refresh(player, stats, message or addLogPrefix("INCIDENT MAP", "Nothing happened."))
	if ok then
		save(player)
	end
end

function BK_IncidentMapService.Init(ctx)
	if initialized then
		return
	end
	initialized = true
	context = ctx or {}

	local getIncidentMap = BK_Remotes.Get("GetIncidentMap")
	local incidentMapAction = BK_Remotes.Get("IncidentMapAction")

	getIncidentMap.OnServerInvoke = function(player)
		if not checkRateLimit(player, "GetIncidentMap") then
			return {
				Error = "Please wait before refreshing the Incident Map.",
				Locations = {},
				Actions = {},
			}
		end
		return buildPayload(player)
	end

	incidentMapAction.OnServerEvent:Connect(handleAction)

	if context.IS_DEBUG then
		print("[BK_IncidentMapService] Loaded.")
	end
end

return BK_IncidentMapService
