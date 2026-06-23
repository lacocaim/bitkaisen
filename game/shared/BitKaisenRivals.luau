-- ModuleScript: BitKaisenRivals
-- Location: ReplicatedStorage
-- Purpose: Update 15 rival, reputation path, and hunter pressure rules.

local BitKaisenRivals = {}

local FIRST_NAMES = {
	"Ren", "Akito", "Mika", "Sena", "Haru", "Raito", "Nari", "Toma", "Yui", "Kaito",
	"Ichika", "Rei", "Asahi", "Noa", "Shin", "Aya", "Kou", "Mei", "Riku", "Sora",
}

local FAMILY_NAMES = {
	"Kusakabe", "Nanami", "Ieiri", "Todo", "Inumaki", "Kamo", "Zenin", "Fushiguro", "Yamashiro", "Mizukara",
	"Tsukigane", "Kurogiri", "Amahara", "Hoshinari", "Shinkawa", "Morikage",
}

local TECHNIQUES = {
	"Cursed Speech", "Blood Manipulation", "Projection Sorcery", "Ratio Technique", "Boogie Woogie", "Simple Domain",
	"Tool Manipulation", "Barrier Technique", "Shadow Thread", "Frost Burial", "Mirror Curse", "Storm Vessel",
}

local REASONS = {
	Hero = { "jealous of your public support", "believes your fame is unearned", "wants to prove they are the stronger protector" },
	Villain = { "was assigned to hunt you", "lost someone during your rise", "wants the bounty on your name" },
	Clan = { "was humiliated by your clan", "wants revenge for a clan war loss", "claims your bloodline insulted theirs" },
	Curse = { "feeds on the fear surrounding your name", "wants to replace you as the local disaster", "was drawn by your cursed pressure" },
	School = { "sees you as their Jujutsu High measuring stick", "lost a mission ranking to you", "wants your teacher's attention" },
}

local PATHS = {
	{ Id = "PublicHero", Name = "Public Hero", Condition = function(stats)
		return (tonumber(stats.Fame) or 0) >= 55 and (tonumber(stats.WantedLevel) or 0) <= 15
	end },
	{ Id = "HonoredSorcerer", Name = "Honored Sorcerer", Condition = function(stats)
		return (tonumber(stats.Reputation) or 0) >= 60 and tostring(stats.Grade or "") ~= "Non-Sorcerer" and (tonumber(stats.WantedLevel) or 0) <= 25
	end },
	{ Id = "ClanChampion", Name = "Clan Champion", Condition = function(stats)
		return (tonumber(stats.ClanWarWins) or 0) >= 2 or (tonumber(stats.FamilyReputation) or 0) >= 45 or (tonumber(stats.ClanReputation) or 0) >= 45
	end },
	{ Id = "InfamousCriminal", Name = "Infamous Criminal", Condition = function(stats)
		return (tonumber(stats.WantedLevel) or 0) >= 55 and (tonumber(stats.Fear) or 0) >= 25
	end },
	{ Id = "RogueCurseUser", Name = "Rogue Curse User", Condition = function(stats)
		local path = tostring(stats.Path or stats.LifePath or "")
		return string.find(string.lower(path), "rogue", 1, true) ~= nil or (tonumber(stats.WantedLevel) or 0) >= 35
	end },
	{ Id = "FearedCurse", Name = "Feared Curse", Condition = function(stats)
		return stats.IsCurse == true or tostring(stats.Race or "") == "Cursed Spirit" or (tonumber(stats.CurseThreat) or 0) >= 45
	end },
	{ Id = "HiddenMonster", Name = "Hidden Monster", Condition = function(stats)
		return (tonumber(stats.Fear) or 0) >= 45 and (tonumber(stats.Fame) or 0) < 20
	end },
}

local function clamp(value, minValue, maxValue)
	return math.clamp(tonumber(value) or minValue, minValue, maxValue)
end

local function nowYear(stats)
	return tonumber(stats and (stats.Year or stats.CurrentYear or stats.StartYear)) or (2000 + (tonumber(stats and stats.Age) or 0))
end

local function makeId(prefix)
	return prefix .. "_" .. tostring(os.clock()):gsub("%.", "") .. "_" .. tostring(math.random(1000, 9999))
end

local function getPower(stats)
	local ce = tonumber(stats and stats.CursedEnergy) or 0
	local mastery = tonumber(stats and stats.TechniqueMastery) or 0
	local reputation = math.max(0, tonumber(stats and stats.Reputation) or 0)
	local gradeBonus = tostring(stats and stats.Grade or "Non-Sorcerer") ~= "Non-Sorcerer" and 25 or 0
	return math.max(20, math.floor((ce * 0.04) + mastery + reputation * 0.25 + gradeBonus + (tonumber(stats and stats.Fear) or 0) * 0.2))
end

local function getGradeFromPower(power)
	power = tonumber(power) or 0
	if power >= 180 then return "Special Grade" end
	if power >= 115 then return "Grade 1" end
	if power >= 75 then return "Grade 2" end
	if power >= 45 then return "Grade 3" end
	return "Grade 4"
end

function BitKaisenRivals.Ensure(stats)
	if typeof(stats) ~= "table" then return end
	if typeof(stats.Rivals) ~= "table" then stats.Rivals = {} end
	if typeof(stats.RivalHistory) ~= "table" then stats.RivalHistory = {} end
	if typeof(stats.ReputationIntelRevealed) ~= "table" then stats.ReputationIntelRevealed = {} end
	stats.RivalEncounters = math.max(0, tonumber(stats.RivalEncounters) or 0)
	stats.RivalsDefeated = math.max(0, tonumber(stats.RivalsDefeated) or 0)
	stats.RivalLosses = math.max(0, tonumber(stats.RivalLosses) or 0)
	stats.RivalEscapes = math.max(0, tonumber(stats.RivalEscapes) or 0)
	stats.RivalCooldown = math.max(0, tonumber(stats.RivalCooldown) or 0)
	stats.HunterPressure = clamp(stats.HunterPressure, 0, 100)
	stats.PublicSupport = clamp(stats.PublicSupport, 0, 100)
	stats.ReputationPath = tostring(stats.ReputationPath or "Unknown")
	stats.ReputationPathScore = clamp(stats.ReputationPathScore, 0, 100)
	stats.HunterAmbushesSurvived = math.max(0, tonumber(stats.HunterAmbushesSurvived) or 0)
end

function BitKaisenRivals.GetReputationPath(stats)
	for _, path in ipairs(PATHS) do
		if path.Condition(stats) then
			return path.Id, path.Name
		end
	end
	return "Unknown", "Unknown"
end

function BitKaisenRivals.UpdateReputationPath(stats)
	BitKaisenRivals.Ensure(stats)
	local pathId, pathName = BitKaisenRivals.GetReputationPath(stats)
	stats.ReputationPath = pathName
	stats.ReputationPathId = pathId
	stats.ReputationPathScore = clamp(((tonumber(stats.Fame) or 0) + (tonumber(stats.Fear) or 0) + math.max(0, tonumber(stats.Reputation) or 0) + (tonumber(stats.WantedLevel) or 0)) / 3, 0, 100)
	return pathId, pathName
end

local function chooseArchetype(stats)
	local _, pathName = BitKaisenRivals.GetReputationPath(stats)
	if stats.IsCurse == true or pathName == "Feared Curse" then return "Curse" end
	if pathName == "Infamous Criminal" or pathName == "Rogue Curse User" or (tonumber(stats.WantedLevel) or 0) >= 35 then return "Villain" end
	if pathName == "Clan Champion" or (tonumber(stats.ClanWarWins) or 0) > 0 then return "Clan" end
	if stats.InJujutsuHigh == true then return "School" end
	return "Hero"
end

function BitKaisenRivals.CreateRival(stats, archetype)
	BitKaisenRivals.Ensure(stats)
	archetype = archetype or chooseArchetype(stats)
	local first = FIRST_NAMES[math.random(1, #FIRST_NAMES)]
	local family = FAMILY_NAMES[math.random(1, #FAMILY_NAMES)]
	local playerPower = getPower(stats)
	local power = math.max(25, math.floor(playerPower * math.random(78, 118) / 100) + math.random(0, 22))
	local rival = {
		Id = makeId("rival"),
		Name = first .. " " .. family,
		Age = math.max(12, (tonumber(stats.Age) or 16) + math.random(-3, 5)),
		Grade = getGradeFromPower(power),
		Clan = family .. " Clan",
		Technique = TECHNIQUES[math.random(1, #TECHNIQUES)],
		Archetype = archetype,
		Reason = (REASONS[archetype] or REASONS.Hero)[math.random(1, #(REASONS[archetype] or REASONS.Hero))],
		Status = "Active",
		Threat = math.clamp(power, 10, 260),
		Wins = 0,
		Losses = 0,
		LastEncounter = "None",
		Relationship = archetype == "School" and "Competitive Rival" or (archetype == "Clan" and "Clan Rival" or "Enemy"),
		CreatedYear = nowYear(stats),
		Revealed = false,
	}
	table.insert(stats.Rivals, rival)
	return rival
end

function BitKaisenRivals.GetActiveRivals(stats)
	BitKaisenRivals.Ensure(stats)
	local active = {}
	for _, rival in ipairs(stats.Rivals) do
		if typeof(rival) == "table" and tostring(rival.Status or "Active") == "Active" then
			table.insert(active, rival)
		end
	end
	return active
end

function BitKaisenRivals.GetEncounterChance(stats)
	BitKaisenRivals.Ensure(stats)
	if stats.Alive == false then return 0 end
	if (tonumber(stats.Age) or 0) < 10 then return 0 end
	if (tonumber(stats.RivalCooldown) or 0) > 0 then return 0 end
	local chance = 8
	chance += math.floor((tonumber(stats.Fame) or 0) / 12)
	chance += math.floor((tonumber(stats.Fear) or 0) / 10)
	chance += math.floor((tonumber(stats.WantedLevel) or 0) / 9)
	chance += math.floor((tonumber(stats.HunterPressure) or 0) / 10)
	chance += math.min(8, #BitKaisenRivals.GetActiveRivals(stats) * 2)
	return math.clamp(chance, 0, 42)
end

function BitKaisenRivals.RollYearlyEncounter(stats)
	BitKaisenRivals.Ensure(stats)
	if (tonumber(stats.RivalCooldown) or 0) > 0 then
		stats.RivalCooldown = math.max(0, (tonumber(stats.RivalCooldown) or 0) - 1)
		return nil
	end
	local chance = BitKaisenRivals.GetEncounterChance(stats)
	if chance <= 0 or math.random(1, 100) > chance then
		return nil
	end
	local active = BitKaisenRivals.GetActiveRivals(stats)
	local rival = active[math.random(1, math.max(1, #active))]
	if not rival then
		rival = BitKaisenRivals.CreateRival(stats)
	end
	stats.RivalCooldown = 1
	return rival
end

function BitKaisenRivals.ApplyReputationDrift(stats)
	BitKaisenRivals.Ensure(stats)
	local wanted = tonumber(stats.WantedLevel) or 0
	local fear = tonumber(stats.Fear) or 0
	local fame = tonumber(stats.Fame) or 0
	if wanted >= 25 or fear >= 35 then
		stats.HunterPressure = math.clamp((tonumber(stats.HunterPressure) or 0) + math.random(1, 4), 0, 100)
	end
	if fame >= 35 and wanted <= 20 then
		stats.PublicSupport = math.clamp((tonumber(stats.PublicSupport) or 0) + math.random(1, 3), 0, 100)
	end
	return BitKaisenRivals.UpdateReputationPath(stats)
end

function BitKaisenRivals.RecordHistory(stats, text)
	BitKaisenRivals.Ensure(stats)
	local entry = "Year " .. tostring(nowYear(stats)) .. ": " .. tostring(text)
	table.insert(stats.RivalHistory, 1, entry)
	while #stats.RivalHistory > 24 do table.remove(stats.RivalHistory) end
	if typeof(stats.WorldHistory) == "table" then
		table.insert(stats.WorldHistory, 1, {
			Type = "Rival",
			Text = entry,
			Year = nowYear(stats),
			Age = tonumber(stats.Age) or 0,
		})
		while #stats.WorldHistory > 80 do table.remove(stats.WorldHistory) end
	end
	return entry
end

function BitKaisenRivals.ResolveAction(stats, rivalId, action)
	BitKaisenRivals.Ensure(stats)
	local rival = nil
	for _, candidate in ipairs(stats.Rivals) do
		if tostring(candidate.Id) == tostring(rivalId) then rival = candidate break end
	end
	if not rival then return false, "Rival not found." end
	action = tostring(action or "")
	if action ~= "intel" and tostring(rival.Status or "Active") ~= "Active" then
		return false, tostring(rival.Name or "This rival") .. " is no longer an active rivalry."
	end
	stats.RivalEncounters += 1
	rival.LastEncounter = action
	if action == "talk_down" then
		local chance = 35 + math.floor((tonumber(stats.Smarts) or 0) / 4) + math.floor((tonumber(stats.PublicSupport) or 0) / 5)
		if math.random(1, 100) <= math.clamp(chance, 15, 82) then
			rival.Status = "Resolved"
			stats.PublicSupport = math.clamp((tonumber(stats.PublicSupport) or 0) + 4, 0, 100)
			BitKaisenRivals.RecordHistory(stats, "You talked down " .. rival.Name .. ", ending the rivalry without bloodshed.")
			return true, "You talked down " .. rival.Name .. ". Public support increased."
		end
		stats.HunterPressure = math.clamp((tonumber(stats.HunterPressure) or 0) + 2, 0, 100)
		return true, rival.Name .. " rejected your words. Their hostility hardened."
	elseif action == "humiliate" then
		rival.Losses = (tonumber(rival.Losses) or 0) + 1
		rival.Status = "Humiliated"
		stats.Fame = math.clamp((tonumber(stats.Fame) or 0) + 3, 0, 100)
		stats.Fear = math.clamp((tonumber(stats.Fear) or 0) + 2, 0, 100)
		BitKaisenRivals.RecordHistory(stats, "You humiliated " .. rival.Name .. ", making the rivalry public.")
		return true, "You humiliated " .. rival.Name .. ". Fame and fear rose."
	elseif action == "spare" then
		rival.Status = "Resolved"
		stats.Reputation = (tonumber(stats.Reputation) or 0) + 2
		stats.PublicSupport = math.clamp((tonumber(stats.PublicSupport) or 0) + 3, 0, 100)
		BitKaisenRivals.RecordHistory(stats, "You spared " .. rival.Name .. ", ending the rivalry with restraint.")
		return true, "You spared " .. rival.Name .. ". Your restraint became part of your reputation."
	elseif action == "escape" then
		stats.RivalEscapes += 1
		stats.HunterPressure = math.clamp((tonumber(stats.HunterPressure) or 0) + 1, 0, 100)
		return true, "You escaped " .. rival.Name .. " for now."
	elseif action == "intel" then
		rival.Revealed = true
		stats.ReputationIntelRevealed[rival.Id] = true
		return true, "Intel revealed for " .. rival.Name .. ": " .. tostring(rival.Technique) .. ", " .. tostring(rival.Grade) .. ", threat " .. tostring(rival.Threat) .. "."
	end
	return false, "Unknown rival action."
end

function BitKaisenRivals.RecordCombatResult(stats, rivalId, winner)
	BitKaisenRivals.Ensure(stats)
	for _, rival in ipairs(stats.Rivals) do
		if tostring(rival.Id) == tostring(rivalId) then
			if winner == "player" then
				rival.Losses = (tonumber(rival.Losses) or 0) + 1
				rival.Status = "Defeated"
				stats.RivalsDefeated += 1
				stats.Fame = math.clamp((tonumber(stats.Fame) or 0) + 4, 0, 100)
				stats.Fear = math.clamp((tonumber(stats.Fear) or 0) + 2, 0, 100)
				BitKaisenRivals.RecordHistory(stats, "You defeated rival " .. rival.Name .. ".")
			elseif winner == "enemy" then
				rival.Wins = (tonumber(rival.Wins) or 0) + 1
				stats.RivalLosses += 1
				stats.HunterPressure = math.clamp((tonumber(stats.HunterPressure) or 0) + 3, 0, 100)
				BitKaisenRivals.RecordHistory(stats, rival.Name .. " defeated you and became more dangerous.")
			elseif winner == "fled" then
				stats.RivalEscapes += 1
			end
			return rival
		end
	end
	return nil
end

function BitKaisenRivals.GetPayload(stats)
	BitKaisenRivals.Ensure(stats)
	local _, pathName = BitKaisenRivals.UpdateReputationPath(stats)
	local list = {}
	for _, rival in ipairs(stats.Rivals) do
		if typeof(rival) == "table" then
			table.insert(list, {
				Id = rival.Id,
				Name = rival.Name,
				Age = rival.Age,
				Grade = rival.Grade,
				Clan = rival.Clan,
				Technique = (rival.Revealed or (stats.ReputationIntelRevealed and stats.ReputationIntelRevealed[rival.Id])) and rival.Technique or "Unknown",
				Reason = rival.Reason,
				Status = rival.Status,
				Threat = rival.Threat,
				Relationship = rival.Relationship,
				Wins = rival.Wins or 0,
				Losses = rival.Losses or 0,
				LastEncounter = rival.LastEncounter or "None",
				Revealed = rival.Revealed == true,
			})
		end
	end
	return {
		ReputationPath = pathName,
		ReputationPathScore = math.floor(tonumber(stats.ReputationPathScore) or 0),
		Fame = math.floor(tonumber(stats.Fame) or 0),
		Fear = math.floor(tonumber(stats.Fear) or 0),
		WantedLevel = math.floor(tonumber(stats.WantedLevel) or 0),
		HunterPressure = math.floor(tonumber(stats.HunterPressure) or 0),
		PublicSupport = math.floor(tonumber(stats.PublicSupport) or 0),
		Rivals = list,
		History = stats.RivalHistory,
		Stats = {
			Encounters = stats.RivalEncounters,
			Defeated = stats.RivalsDefeated,
			Losses = stats.RivalLosses,
			Escapes = stats.RivalEscapes,
		},
	}
end

return BitKaisenRivals
