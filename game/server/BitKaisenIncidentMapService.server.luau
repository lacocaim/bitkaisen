-- Script: BitKaisenIncidentMapService
-- Location: ServerScriptService
-- Purpose:
--   Modular server service for the Incident Map.
--   Creates its own remotes and uses a tiny GameManager bridge instead of stacking map logic into GameManager.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local BitKaisenIncidentMap = require(ReplicatedStorage:WaitForChild("BitKaisenIncidentMap"))
local BitKaisenCurseEvolution = require(ReplicatedStorage:WaitForChild("BitKaisenCurseEvolution"))

local function ensureRemote(name, className)
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing then
		return existing
	end
	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

local getIncidentMap = ensureRemote("GetIncidentMap", "RemoteFunction")
local incidentMapAction = ensureRemote("IncidentMapAction", "RemoteEvent")

local bridgeFolder = ServerStorage:WaitForChild("BitKaisenRuntimeBridge")
local bridgeGetStats = bridgeFolder:WaitForChild("GetStats")
local bridgeRefreshPlayer = bridgeFolder:WaitForChild("RefreshPlayer")
local bridgeSavePlayer = bridgeFolder:WaitForChild("SavePlayer")

local actionCooldowns = {}
local ACTION_COOLDOWN_SECONDS = 0.45

local function clamp(value, minValue, maxValue)
	return math.clamp(tonumber(value) or 0, minValue or 0, maxValue or 100)
end

local function getStats(player)
	local ok, stats = pcall(function()
		return bridgeGetStats:Invoke(player)
	end)
	if ok and typeof(stats) == "table" then
		return stats
	end
	return nil
end

local function refresh(player, message)
	pcall(function()
		bridgeRefreshPlayer:Invoke(player, message or "", false)
	end)
end

local function save(player)
	pcall(function()
		bridgeSavePlayer:Invoke(player, "IncidentMap", false)
	end)
end

local function canUseAction(player)
	local now = os.clock()
	local last = actionCooldowns[player.UserId] or 0
	if (now - last) < ACTION_COOLDOWN_SECONDS then
		return false
	end
	actionCooldowns[player.UserId] = now
	return true
end

local function getLocationState(stats, locationId)
	local map = BitKaisenIncidentMap.EnsureMapState(stats)
	if not map then return nil, nil end
	local def = BitKaisenIncidentMap.GetLocationDefinition(locationId)
	if not def then return nil, nil end
	return def, map.Locations[locationId]
end

local function addLogPrefix(prefix, body)
	return "<font color='#b27aff'><b>[ " .. tostring(prefix) .. " ]</b></font> " .. tostring(body or "")
end

local function getPower(stats)
	local ce = tonumber(stats.CursedEnergy) or 0
	local mastery = tonumber(stats.TechniqueMastery) or 0
	local smarts = tonumber(stats.Smarts) or 0
	local health = tonumber(stats.Health) or 100
	local rep = tonumber(stats.Reputation) or 0
	return math.floor((ce * 0.22) + (mastery * 1.2) + (smarts * 0.35) + (health * 0.25) + math.max(0, rep * 0.15) + math.random(10, 45))
end

local function getCursePower(stats)
	local ce = tonumber(stats.CursedEnergy) or 0
	local mastery = tonumber(stats.TechniqueMastery) or 0
	local health = tonumber(stats.Health) or 100
	local threat = tonumber(stats.CurseThreat) or 0
	local manifestation = tonumber(stats.ManifestationProgress) or 0
	return math.floor((ce * 0.25) + (mastery * 1.1) + (health * 0.25) + (threat * 0.6) + (manifestation * 0.5) + math.random(15, 55))
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

	return "\n<font color='#e53935'><b>[ JUJUTSU SOCIETY FILE OPENED ]</b></font> After the death of an investigator near <b>" .. tostring(location.Name) .. "</b>, Jujutsu Society confirmed your existence. Classification: <b>" .. tostring(stats.CurseGrade) .. "</b>."
end

local function applySorcererAction(player, stats, def, state, actionId)
	local message = ""

	if actionId == "investigate" then
		local found = math.random(1, 100) <= (45 + math.floor((tonumber(stats.Smarts) or 0) / 3))
		stats.Smarts = clamp((stats.Smarts or 0) + math.random(1, 3), 0, 100)
		state.SocietyAttention = clamp(state.SocietyAttention + math.random(4, 9), 0, 100)
		if found then
			stats.Reputation = (tonumber(stats.Reputation) or 0) + 2
			state.CursedResidue = clamp(state.CursedResidue - math.random(4, 8), 0, 100)
			message = "You investigated <b>" .. def.Name .. "</b> and found real cursed residue near the rumor site. (+Smarts, +Reputation)"
		else
			message = "You investigated <b>" .. def.Name .. "</b>, but the trail went cold. Society attention still rose around the location."
		end

	elseif actionId == "search_residue" then
		local gain = math.random(5, 14)
		stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + gain)
		stats.TechniqueMastery = clamp((stats.TechniqueMastery or 0) + math.random(0, 2), 0, 100)
		state.CursedResidue = clamp(state.CursedResidue - math.random(3, 7), 0, 100)
		message = "You studied cursed residue at <b>" .. def.Name .. "</b>. The trace sharpened your control. (+" .. tostring(gain) .. " CE)"

	elseif actionId == "exorcise_threat" then
		local playerPower = getPower(stats)
		local threatPower = (tonumber(state.Threat) or 0) * 2 + (tonumber(state.CursedResidue) or 0) + math.random(20, 80)
		if playerPower >= threatPower then
			local ceGain = math.random(10, 24)
			stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + ceGain)
			stats.Reputation = (tonumber(stats.Reputation) or 0) + math.random(4, 9)
			stats.Recommendations = math.max(0, tonumber(stats.Recommendations) or 0) + (math.random(1, 100) <= 20 and 1 or 0)
			state.Threat = clamp(state.Threat - math.random(18, 32), 0, 100)
			state.Fear = clamp(state.Fear - math.random(8, 18), 0, 100)
			state.ActiveIncident = state.Threat >= 35
			message = "You exorcised the threat at <b>" .. def.Name .. "</b>. Civilians stopped whispering about it for now. (+CE, +Reputation)"
		else
			local damage = math.random(8, 22)
			stats.Health = clamp((stats.Health or 100) - damage, 0, 100)
			state.Threat = clamp(state.Threat + math.random(4, 10), 0, 100)
			state.Fear = clamp(state.Fear + math.random(5, 12), 0, 100)
			message = "The threat at <b>" .. def.Name .. "</b> was worse than expected. You survived, but the rumor grew louder. (-" .. tostring(damage) .. " Health)"
		end

	elseif actionId == "protect_civilians" then
		stats.Reputation = (tonumber(stats.Reputation) or 0) + math.random(2, 6)
		stats.Happiness = clamp((stats.Happiness or 50) + math.random(1, 4), 0, 100)
		state.Fear = clamp(state.Fear - math.random(5, 12), 0, 100)
		state.SocietyAttention = clamp(state.SocietyAttention + math.random(2, 5), 0, 100)
		message = "You protected civilians around <b>" .. def.Name .. "</b>. People still felt watched, but fewer were hurt. (+Reputation)"
	else
		return false, "That Incident Map action is not available."
	end

	state.LastResult = message:gsub("<.->", "")
	return true, addLogPrefix("INCIDENT MAP", message)
end

local function applyCursedSpiritAction(player, stats, def, state, actionId)
	local message = ""

	if actionId == "claim_haunt" then
		state.ControlledBy = "You"
		state.Control = clamp(state.Control + math.random(10, 20), 0, 100)
		state.Fear = clamp(state.Fear + math.random(4, 10), 0, 100)
		state.SocietyAttention = clamp(state.SocietyAttention + math.random(2, 7), 0, 100)
		stats.CurseTerritory = def.Name
		stats.TerritoryControl = clamp((stats.TerritoryControl or 0) + math.random(3, 8), 0, 100)
		message = "You pressed your presence into <b>" .. def.Name .. "</b>. The location started to feel like your haunt."

	elseif actionId == "feed_fear" then
		local gain = math.random(10, 24) + math.floor((tonumber(state.Fear) or 0) / 10)
		stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + gain)
		stats.CurseHunger = clamp((stats.CurseHunger or 50) - math.random(12, 24), 0, 100)
		stats.CurseThreat = math.max(0, (tonumber(stats.CurseThreat) or 0) + math.random(2, 6))
		local evolutionResult = BitKaisenCurseEvolution.AddProgress(stats, math.random(3, 9), "Feeding from an Incident Map haunt")
		state.Fear = clamp(state.Fear + math.random(3, 8), 0, 100)
		state.SocietyAttention = clamp(state.SocietyAttention + math.random(3, 9), 0, 100)
		message = "You fed from the fear around <b>" .. def.Name .. "</b>. The emotion was thin, but enough to strengthen your cursed body. (+" .. tostring(gain) .. " CE)" .. tostring(evolutionResult.Message or "")

	elseif actionId == "spread_rumor" then
		local rumor = BitKaisenIncidentMap.GetRandomRumor(def)
		state.Rumor = rumor
		stats.CurseRumor = rumor
		stats.RumorSpread = math.max(0, (tonumber(stats.RumorSpread) or 0) + math.random(8, 18))
		stats.CurseThreat = math.max(0, (tonumber(stats.CurseThreat) or 0) + math.random(4, 10))
		state.Fear = clamp(state.Fear + math.random(8, 16), 0, 100)
		state.SocietyAttention = clamp(state.SocietyAttention + math.random(5, 12), 0, 100)
		message = "A new rumor spread through <b>" .. def.Name .. "</b>: <b>" .. rumor .. "</b>. Humans gave your shape a name."

	elseif actionId == "hide_residue" then
		local reduction = math.random(8, 18) + math.floor((tonumber(stats.TechniqueMastery) or 0) / 12)
		state.CursedResidue = clamp(state.CursedResidue - reduction, 0, 100)
		state.SocietyAttention = clamp(state.SocietyAttention - math.random(6, 14), 0, 100)
		stats.ExorcismRisk = clamp((stats.ExorcismRisk or 0) - math.random(5, 13), 0, 100)
		stats.HuntersEscaped = math.max(0, (tonumber(stats.HuntersEscaped) or 0) + 1)
		message = "You folded your cursed energy into the walls of <b>" .. def.Name .. "</b>. Investigators lost the trail. (-Exorcism Risk)"

	elseif actionId == "move_territory" then
		stats.CurseTerritory = def.Name
		stats.TerritoryControl = clamp(math.max(10, state.Control), 0, 100)
		state.ControlledBy = "You"
		state.Control = clamp(state.Control + math.random(6, 14), 0, 100)
		message = "You abandoned your old haunt and settled into <b>" .. def.Name .. "</b>. This place now carries your presence."

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
			local evolutionResult = BitKaisenCurseEvolution.AddProgress(stats, math.random(10, 22), "Ambushing an investigator")
			state.Fear = clamp(state.Fear + math.random(10, 20), 0, 100)
			message = "You ambushed the investigator at <b>" .. def.Name .. "</b>. Their fear fed your cursed body. (+" .. tostring(gain) .. " CE)" .. tostring(evolutionResult.Message or "") .. openCurseFileIfNeeded(stats, def)
		else
			local damage = math.random(15, 35)
			stats.Health = clamp((stats.Health or 100) - damage, 0, 100)
			stats.HuntersEscaped = math.max(0, (tonumber(stats.HuntersEscaped) or 0) + 1)
			message = "You tried to ambush the investigator at <b>" .. def.Name .. "</b>, but they survived and escaped with proof of your existence. (-" .. tostring(damage) .. " Health)"
			if stats.CurseClassified ~= true and math.random(1, 100) <= 35 then
				stats.CurseClassified = true
				stats.SocietyStatus = "Tracked Cursed Spirit"
				message ..= "\n<font color='#e53935'><b>[ TRACKED ]</b></font> Jujutsu Society did not fully classify you yet, but your file is no longer empty."
			end
		end
	else
		return false, "That Incident Map action is not available."
	end

	state.LastResult = message:gsub("<.->", "")
	return true, addLogPrefix("INCIDENT MAP", message)
end

getIncidentMap.OnServerInvoke = function(player)
	local stats = getStats(player)
	if not stats then
		return {
			Error = "Your life data is not loaded yet.",
			Locations = {},
			Actions = {},
		}
	end

	local payload = BitKaisenIncidentMap.BuildPayload(stats)
	save(player)
	return payload
end

incidentMapAction.OnServerEvent:Connect(function(player, locationId, actionId)
	if not canUseAction(player) then
		return
	end

	local stats = getStats(player)
	if not stats then
		return
	end

	locationId = tostring(locationId or "")
	actionId = tostring(actionId or "")

	local def, state = getLocationState(stats, locationId)
	if not def or not state then
		refresh(player, addLogPrefix("INCIDENT MAP", "That location is no longer available."))
		return
	end

	local isCursedSpirit = BitKaisenIncidentMap.IsCursedSpirit(stats)
	local ok, message
	if isCursedSpirit then
		ok, message = applyCursedSpiritAction(player, stats, def, state, actionId)
	else
		ok, message = applySorcererAction(player, stats, def, state, actionId)
	end

	BitKaisenIncidentMap.EnsureMapState(stats)
	if ok then
		stats.IncidentMap.ActionsTaken = math.max(0, tonumber(stats.IncidentMap.ActionsTaken) or 0) + 1
	end

	refresh(player, message or addLogPrefix("INCIDENT MAP", "Nothing happened."))
	save(player)
end)

Players.PlayerRemoving:Connect(function(player)
	actionCooldowns[player.UserId] = nil
end)

print("[BitKaisenIncidentMapService] Loaded.")
