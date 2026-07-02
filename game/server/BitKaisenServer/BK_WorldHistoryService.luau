-- ModuleScript: BK_WorldHistoryService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose: Update 10 world events, notable NPC tracking, history, and title payloads.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BitKaisenCursedTools = require(ReplicatedStorage:WaitForChild("BitKaisenCursedTools"))
local BitKaisenLocale      = require(ReplicatedStorage:WaitForChild("locale"))

local BK_WorldHistoryService = {}

local context = {}

local FIRST_NAMES = {
	"Satoru", "Megumi", "Yuta", "Maki", "Kinji", "Kirara", "Noritoshi", "Kasumi", "Aoi", "Mai",
	"Riko", "Shoko", "Suguru", "Tengen", "Hana", "Yuji", "Nobara", "Tsumiki", "Junpei", "Kokichi",
}

local CLANS = { "Gojo", "Zenin", "Kamo", "Inumaki", "Itadori", "Kusakabe", "Nanami", "Todo", "Ieiri", "Fushiguro" }
local REGIONS = { "Kyoto", "Tokyo", "Sendai", "Osaka", "Nara", "Shibuya", "Yokohama", "Nagoya" }

local NOTABLE_PERSONALITIES = {
	"Quiet but observant — they notice everything and say very little.",
	"Blunt and hard to impress. Respect has to be earned from them, not given.",
	"Warm on the surface, but cautious about who they let close.",
	"Fiercely protective of the people they care about, even at cost to themselves.",
	"Ambitious and competitive. They measure themselves against the strongest.",
	"Calm under pressure in a way that makes others uneasy.",
	"Kind, but not naive. They have seen enough to know the difference.",
	"Secretive about their past. Ask the wrong question and they go quiet.",
	"Loyal once trust is earned — but that process is slow.",
	"Sharp-tongued but reliable when things go wrong.",
	"Soft-spoken until pressure hits. Then something shifts.",
	"Polite in a way that keeps score without showing it.",
	"Careless with danger but fiercely loyal to the people they choose.",
	"Obsessed with technique theory. They talk about cursed energy like it is a language.",
	"Cold at first. Protective later. The transition is worth waiting for.",
}

local NOTABLE_LORE_BY_TRAIT = {
	["Immense Cursed Energy"] = {
		"Their cursed energy output was detected at birth — a record for their clan.",
		"Even as a child, the air around them felt heavier than it should.",
		"The Jujutsu Society flagged their cursed energy readings before they learned to walk.",
	},
	["Heavenly Restriction"] = {
		"Born without a single trace of cursed energy — and stronger for it.",
		"Their body operates at a physical limit no sorcerer can reach. The trade-off was everything.",
		"What they lost in technique, they rebuilt in pure physical discipline.",
	},
	["Special Grade Potential"] = {
		"Every senior sorcerer who assessed them came back unsettled.",
		"Their potential was classified before they even entered training.",
		"They do not know what they are capable of yet. That is what makes them dangerous.",
	},
	["Cursed Lineage"] = {
		"A bloodline thought extinct reappeared in them. Older sorcerers got nervous.",
		"Their clan's forbidden technique resurfaced in them after generations of silence.",
		"They carry something that was supposed to be buried. No one knows if that is good or bad.",
	},
}

local BIRTH_TYPES = {
	{
		Kind = "Immense CE",
		Template = "A child with immense cursed energy was born into the %s Clan: %s.",
		Grade = "Potential Special Grade",
		Trait = "Immense Cursed Energy",
		Weight = 32,
	},
	{
		Kind = "Heavenly Restriction",
		Template = "A Heavenly Restriction user has been born into the %s Clan: %s.",
		Grade = "Unregistered Grade 1",
		Trait = "Heavenly Restriction",
		Weight = 26,
	},
	{
		Kind = "Potential Special Grade",
		Template = "A potential Special Grade sorcerer has been detected: %s of the %s Clan.",
		Grade = "Potential Special Grade",
		Trait = "Special Grade Potential",
		Weight = 24,
	},
	{
		Kind = "Cursed Lineage",
		Template = "A cursed lineage has reappeared after generations: %s of the %s Clan.",
		Grade = "Unregistered Semi-Grade 1",
		Trait = "Cursed Lineage",
		Weight = 18,
	},
}

local WORLD_EVENTS = {
	{
		Id = "curse_outbreak",
		Neutral = "A curse outbreak killed hundreds in %s.",
		Hero = "A curse outbreak could have killed hundreds in %s, but you stopped it.",
		Villain = "A curse outbreak tore through %s because of you.",
		Type = "Disaster",
	},
	{
		Id = "clan_war",
		Neutral = "A clan conflict escalated into open war near %s.",
		Hero = "A clan conflict near %s nearly became open war, but your intervention ended it.",
		Villain = "A clan conflict near %s became open war after your interference.",
		Type = "War",
	},
	{
		Id = "special_grade_confirmed",
		Neutral = "A Special Grade curse was confirmed in the %s region.",
		Hero = "A Special Grade curse was confirmed in %s, but your pressure forced it back into hiding.",
		Villain = "A Special Grade curse was confirmed in %s after your actions destabilized the region.",
		Type = "Threat",
	},
	{
		Id = "grade1_promotion",
		Neutral = "A sorcerer was promoted to Grade 1 after missions in %s.",
		Hero = "Your work in %s inspired a sorcerer promotion to Grade 1.",
		Villain = "A sorcerer was rushed to Grade 1 in %s to answer the fear surrounding you.",
		Type = "Promotion",
	},
	{
		Id = "major_death",
		Neutral = "A major figure died during a mission in %s.",
		Hero = "A major figure nearly died during a mission in %s, but you prevented the loss.",
		Villain = "A major figure died during a mission in %s, and your name was whispered afterward.",
		Type = "Death",
	},
}

local TITLE_DEFINITIONS = {
	{ Id = "grade_4", Name = "Grade 4 Sorcerer", Requirement = "Reach Grade 4 or higher.", Check = function(stats) return tostring(stats.Grade or "") ~= "Non-Sorcerer" end },
	{ Id = "rising_talent", Name = "Rising Talent", Requirement = "Win 10 missions without defeat.", Check = function(stats) return (tonumber(stats.MissionsCompleted) or 0) >= 10 and (tonumber(stats.MissionsFailed) or 0) <= 0 end },
	{ Id = "fearful_presence", Name = "Fearful Presence", Requirement = "Reach high Fear.", Check = function(stats) return (tonumber(stats.Fear) or 0) >= 75 end },
	{ Id = "clan_leader", Name = "Clan Leader", Requirement = "Own, found, or inherit a clan.", Check = function(stats) return stats.ClanFounded == true or tostring(stats.ClanLeadership or "None") ~= "None" end },
	{ Id = "tool_bearer", Name = "Cursed Tool Bearer", Requirement = "Own at least 1 cursed tool.", Check = function(stats) return typeof(stats.CursedTools) == "table" and next(stats.CursedTools) ~= nil end },
	{ Id = "relic_collector", Name = "Relic Collector", Requirement = "Own at least 3 cursed tools.", Check = function(stats) local count = 0; if typeof(stats.CursedTools) == "table" then for _ in pairs(stats.CursedTools) do count += 1 end end; return count >= 3 end },
	{ Id = "complete_arsenal", Name = "Complete Arsenal", Requirement = "Own every current cursed tool.", Check = function(stats) local count = 0; if typeof(stats.CursedTools) == "table" then for _ in pairs(stats.CursedTools) do count += 1 end end; return count >= BitKaisenCursedTools.GetToolCount() end },
	{ Id = "war_proven", Name = "War-Proven", Requirement = "Win your first Clan War.", Check = function(stats) return (tonumber(stats.ClanWarWins) or 0) >= 1 end },
	{ Id = "clan_conqueror", Name = "Clan Conqueror", Requirement = "Win 3 Clan Wars.", Check = function(stats) return (tonumber(stats.ClanWarWins) or 0) >= 3 end },
	{ Id = "unbroken_banner", Name = "Unbroken Banner", Requirement = "Win a Clan War without any Clan War defeats recorded.", Check = function(stats) return (tonumber(stats.ClanWarWins) or 0) >= 1 and (tonumber(stats.ClanWarLosses) or 0) <= 0 end },
	{ Id = "rival_maker", Name = "Rival Maker", Requirement = "Gain 3 rivals.", Check = function(stats) return typeof(stats.Rivals) == "table" and #stats.Rivals >= 3 end },
	{ Id = "untouchable", Name = "Untouchable", Requirement = "Defeat 5 rivals.", Check = function(stats) return (tonumber(stats.RivalsDefeated) or 0) >= 5 end },
	{ Id = "public_hero", Name = "Public Hero", Requirement = "Reach high Fame with low Wanted level.", Check = function(stats) return (tonumber(stats.Fame) or 0) >= 65 and (tonumber(stats.WantedLevel) or 0) <= 15 end },
	{ Id = "walking_disaster", Name = "Walking Disaster", Requirement = "Reach high Fear and Hunter Pressure.", Check = function(stats) return (tonumber(stats.Fear) or 0) >= 70 and (tonumber(stats.HunterPressure) or 0) >= 55 end },
	{ Id = "marked_sorcerer", Name = "Marked Sorcerer", Requirement = "Survive repeated rival or hunter pressure.", Check = function(stats) return (tonumber(stats.RivalEscapes) or 0) >= 3 or (tonumber(stats.HunterAmbushesSurvived) or 0) >= 3 end },
	{ Id = "enemy_of_society", Name = "Enemy of Jujutsu Society", Requirement = "Reach extreme Wanted level.", Check = function(stats) return (tonumber(stats.WantedLevel) or 0) >= 90 end },
	{ Id = "honored_one", Name = "Honored One", Requirement = "Reach top-tier stats and major feats.", Check = function(stats) return (tonumber(stats.CursedEnergy) or 0) >= 5000 and (tonumber(stats.TechniqueMastery) or 0) >= 95 and (tonumber(stats.Fame) or 0) >= 80 end },
}

local function tWorld(locale, key, params, fallback)
	return BitKaisenLocale.tOrFallback(locale, "world." .. key, params, fallback)
end

local function pick(list)
	return list[math.random(1, #list)]
end

local function weightedPick(list)
	local total = 0
	for _, item in ipairs(list) do total += tonumber(item.Weight) or 1 end
	local roll = math.random() * total
	local running = 0
	for _, item in ipairs(list) do
		running += tonumber(item.Weight) or 1
		if roll <= running then return item end
	end
	return list[#list]
end

local function getYear(stats)
	if typeof(stats) ~= "table" then
		return 2000
	end
	local currentYear = tonumber(stats.CurrentYear or stats.Year)
	if currentYear then
		return currentYear
	end
	local birthYear = tonumber(stats.BirthYear)
	if birthYear then
		return birthYear + (tonumber(stats.Age) or 0)
	end
	return 2000 + (tonumber(stats.Age) or 0)
end

local function trimList(list, maxCount)
	while #list > maxCount do
		table.remove(list, 1)
	end
end

function BK_WorldHistoryService.EnsureWorldState(stats)
	if not stats then return end
	if typeof(stats.WorldHistory) ~= "table" then stats.WorldHistory = {} end
	if typeof(stats.NotableSorcerers) ~= "table" then stats.NotableSorcerers = {} end
	if typeof(stats.UnlockedTitles) ~= "table" then stats.UnlockedTitles = {} end
	stats.WorldEventCount = math.max(0, tonumber(stats.WorldEventCount) or 0)
	stats.NotableBirthCount = math.max(0, tonumber(stats.NotableBirthCount) or 0)
end

function BK_WorldHistoryService.AddHistory(stats, entry)
	BK_WorldHistoryService.EnsureWorldState(stats)
	entry = entry or {}
	entry.Year = tonumber(entry.Year) or getYear(stats)
	entry.Age = tonumber(entry.Age) or tonumber(stats.Age) or 0
	entry.Text = tostring(entry.Text or "Unknown world event.")
	entry.Type = tostring(entry.Type or "World")
	table.insert(stats.WorldHistory, entry)
	trimList(stats.WorldHistory, 90)
	stats.WorldEventCount = math.max(0, tonumber(stats.WorldEventCount) or 0) + 1
	return entry
end

local function playerPower(stats)
	return (tonumber(stats.CursedEnergy) or 0) * 0.015 + (tonumber(stats.TechniqueMastery) or 0) + (tonumber(stats.Reputation) or 0) * 0.25 + (tonumber(stats.Fame) or 0) * 0.5
end

local function isVillainPath(stats)
	local path = string.lower(tostring(stats.LifePath or stats.SocietyStatus or ""))
	return path:find("rogue", 1, true) ~= nil or path:find("curse", 1, true) ~= nil or (tonumber(stats.Fear) or 0) >= 70 or (tonumber(stats.WantedLevel) or 0) >= 45
end

local function makeWorldEvent(stats, locale)
	local event = pick(WORLD_EVENTS)
	local region = pick(REGIONS)
	local text
	local outcome = "Neutral"
	if isVillainPath(stats) then
		text = tWorld(locale, event.Id .. "_villain", { region = region }, string.format(event.Villain, region))
		outcome = "Caused"
	elseif playerPower(stats) >= 95 then
		text = tWorld(locale, event.Id .. "_hero", { region = region }, string.format(event.Hero, region))
		outcome = "Prevented"
		stats.Fame = math.clamp((tonumber(stats.Fame) or 0) + math.random(1, 3), 0, 100)
	else
		text = tWorld(locale, event.Id .. "_neutral", { region = region }, string.format(event.Neutral, region))
	end
	return BK_WorldHistoryService.AddHistory(stats, {
		Type = event.Type,
		Text = text,
		Outcome = outcome,
		Region = region,
	})
end

local function makeNotableBirth(stats, forced, locale)
	if not forced and math.random(1, 100) > 28 then return nil end
	local birth = weightedPick(BIRTH_TYPES)
	local clan = pick(CLANS)
	local name = pick(FIRST_NAMES) .. " " .. clan
	local kindKeyMap = {
		["Immense CE"]             = "birth_immense_ce",
		["Heavenly Restriction"]   = "birth_heavenly_restriction",
		["Potential Special Grade"]= "birth_special_grade",
		["Cursed Lineage"]         = "birth_cursed_lineage",
	}
	local kindKey = kindKeyMap[birth.Kind] or ("birth_" .. birth.Kind:lower():gsub(" ", "_"))
	local englishFallback = birth.Kind == "Potential Special Grade"
		and string.format(birth.Template, name, clan)
		or  string.format(birth.Template, clan, name)
	local text = tWorld(locale, kindKey, { clan = clan, name = name }, englishFallback)
	local npc = {
		Id = "notable_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999)),
		Name = name,
		Clan = clan,
		Age = 0,
		Grade = birth.Grade,
		Trait = birth.Trait,
		Gender = math.random(2) == 1 and "Male" or "Female",
		Status = "Infant",
		Relationship = "World Figure",
		Progressing = true,
		CursedEnergy = birth.Kind == "Heavenly Restriction" and 0 or math.random(20, 85),
		TechniqueMastery = 0,
		Power = 0,
		BornYear = getYear(stats),
		PublicNote = text,
		Personality = pick(NOTABLE_PERSONALITIES),
		Background = pick(NOTABLE_LORE_BY_TRAIT[birth.Trait] or { "Their potential is still being understood." }),
		Romance = 0,
	}
	table.insert(stats.NotableSorcerers, npc)
	trimList(stats.NotableSorcerers, 40)
	stats.NotableBirthCount = math.max(0, tonumber(stats.NotableBirthCount) or 0) + 1
	stats.NotableVersion = (tonumber(stats.NotableVersion) or 0) + 1
	stats.RelationshipVersion = (tonumber(stats.RelationshipVersion) or 0) + 1
	BK_WorldHistoryService.AddHistory(stats, { Type = "Notable Birth", Text = text, RelatedName = name })
	return npc, text
end

local function ageNotables(stats)
	local changed = false
	for _, npc in ipairs(stats.NotableSorcerers or {}) do
		npc.Age = math.max(0, (tonumber(npc.Age) or 0) + 1)
		changed = true
		if npc.Age >= 18 and tostring(npc.Status or "") ~= "Active" then
			npc.Status = "Active"
		elseif npc.Age >= 12 and (tostring(npc.Status or "") == "Infant" or tostring(npc.Status or "") == "Child") then
			npc.Status = "Training"
		elseif npc.Age >= 3 and tostring(npc.Status or "") == "Infant" then
			npc.Status = "Child"
		end

		if npc.Progressing ~= false then
			local age = tonumber(npc.Age) or 0
			local ceGain = age < 6 and math.random(1, 4) or (age < 12 and math.random(3, 9) or math.random(6, 16))
			local masteryGain = age >= 8 and math.random(1, 4) or 0
			if tostring(npc.Trait or "") == "Immense Cursed Energy" or tostring(npc.Trait or "") == "Special Grade Potential" then
				ceGain += math.random(4, 12)
			end
			if tostring(npc.Trait or "") == "Heavenly Restriction" then
				ceGain = 0
				masteryGain = math.max(masteryGain, math.random(2, 5))
			end
			npc.CursedEnergy = math.max(0, (tonumber(npc.CursedEnergy) or 0) + ceGain)
			npc.TechniqueMastery = math.clamp((tonumber(npc.TechniqueMastery) or 0) + masteryGain, 0, 100)
			if math.random(1, 100) <= 18 then
				npc.Progress = math.clamp((tonumber(npc.Progress) or 0) + math.random(4, 12), 0, 100)
			end
			npc.Power = math.floor((tonumber(npc.CursedEnergy) or 0) * 0.015 + (tonumber(npc.TechniqueMastery) or 0) + (tonumber(npc.Progress) or 0) * 0.35)
		end
	end
	if changed then
		stats.NotableVersion = (tonumber(stats.NotableVersion) or 0) + 1
		stats.RelationshipVersion = (tonumber(stats.RelationshipVersion) or 0) + 1
	end
end

function BK_WorldHistoryService.AdvanceYear(player, stats)
	BK_WorldHistoryService.EnsureWorldState(stats)
	ageNotables(stats)
	local locale = BitKaisenLocale.getPlayerLocale(player.UserId)
	local worldEntry = makeWorldEvent(stats, locale)
	local _, birthText = makeNotableBirth(stats, #stats.NotableSorcerers == 0, locale)
	local eventHeader = tWorld(locale, "event_header", nil, "[ WORLD EVENT ]")
	local lines = { "\n<font color='#78beff'><b>" .. eventHeader .. "</b></font> " .. tostring(worldEntry.Text) }
	if birthText then
		local birthHeader = tWorld(locale, "birth_header", nil, "[ NOTABLE BIRTH ]")
		table.insert(lines, "<font color='#d9b45f'><b>" .. birthHeader .. "</b></font> " .. birthText)
	end
	return table.concat(lines, "\n")
end

function BK_WorldHistoryService.GetAffiliationNotables(stats)
	BK_WorldHistoryService.EnsureWorldState(stats)
	local list = {}
	for _, npc in ipairs(stats.NotableSorcerers or {}) do
		table.insert(list, {
			Id = npc.Id,
			Name = npc.Name,
			Role = "Notable Sorcerer",
			Age = npc.Age,
			Grade = npc.Grade,
			Gender = tostring(npc.Gender or "Unknown"),
			Status = tostring(npc.Status or "Tracked"),
			Relationship = tostring(npc.Relationship or "World Figure"),
			Progressing = npc.Progressing ~= false,
			CursedEnergy = tonumber(npc.CursedEnergy) or 0,
			TechniqueMastery = tonumber(npc.TechniqueMastery) or 0,
			Power = tonumber(npc.Power) or 0,
			Progress = tonumber(npc.Progress) or 0,
			Bond = tonumber(npc.Bond) or 0,
			Trust = tonumber(npc.Trust) or 0,
			Respect = math.clamp(tonumber(npc.Respect) or tonumber(npc.Progress) or 0, 0, 100),
			Fear = tonumber(npc.Fear) or 0,
			PublicNote = npc.PublicNote,
		})
	end
	return list
end

local function getStrongestSorcererName(stats)
	local playerAge = tonumber(stats.Age) or 0
	local playerCE = tonumber(stats.CursedEnergy) or 0
	local playerEligible = playerAge >= 12 and playerCE >= 100
	local strongestName = playerEligible and (stats.Name or stats.FullName or "Unknown") or "No dominant sorcerer yet"
	local strongestPower = playerEligible and playerPower(stats) or 0
	for _, npc in ipairs(stats.NotableSorcerers or {}) do
		local age = tonumber(npc.Age) or 0
		local ce = tonumber(npc.CursedEnergy) or 0
		local mastery = tonumber(npc.TechniqueMastery) or 0
		local progress = tonumber(npc.Progress) or 0
		local power = tonumber(npc.Power) or 0
		local technique = tostring(npc.CursedTechnique or npc.Technique or "None")
		local status = tostring(npc.Status or "")
		local eligible = age >= 12
			and status ~= "Infant"
			and (ce > 0 or mastery > 0 or power > 0 or progress > 0)
			and not (ce <= 0 and mastery <= 0 and power <= 0 and (technique == "None" or technique == ""))
		if eligible then
			local npcPower = power + ce * 0.015 + mastery + progress * 0.35
			if age < 16 then
				npcPower *= 0.45
			end
			if npcPower > strongestPower then
				strongestPower = npcPower
				strongestName = tostring(npc.Name or "Unknown Sorcerer")
			end
		end
	end
	return strongestName
end

function BK_WorldHistoryService.GetWorldHistoryPayload(stats)
	BK_WorldHistoryService.EnsureWorldState(stats)
	local cursedToolCount = 0
	if typeof(stats.CursedTools) == "table" then
		for _ in pairs(stats.CursedTools) do
			cursedToolCount += 1
		end
	end
	local equippedTool = BitKaisenCursedTools.GetTool(stats.EquippedCursedToolId)
	local clanWarState = typeof(stats.ClanWarState) == "table" and stats.ClanWarState or {}
	return {
		History = stats.WorldHistory,
		NotableSorcerers = stats.NotableSorcerers,
		Summary = {
			WorldEvents = stats.WorldEventCount or 0,
			NotableBirths = stats.NotableBirthCount or 0,
			Era = stats.CurrentEra or stats.Era or "Modern Era",
			StrongestSorcerer = getStrongestSorcererName(stats),
			CursedToolsOwned = cursedToolCount,
			EquippedCursedToolId = stats.EquippedCursedToolId,
			EquippedCursedToolName = equippedTool and equippedTool.Name or nil,
			ClanWarWins = math.max(0, tonumber(stats.ClanWarWins) or 0),
			ClanWarLosses = math.max(0, tonumber(stats.ClanWarLosses) or 0),
			ClanWarActive = clanWarState.Active == true,
			ClanWarRival = clanWarState.RivalClanName,
			ClanWarTension = clanWarState.Tension,
			Fame = math.clamp(tonumber(stats.Fame) or 0, 0, 100),
			Fear = math.clamp(tonumber(stats.Fear) or 0, 0, 100),
			WorldAttention = math.clamp(tonumber(stats.WorldAttention) or 0, 0, 100),
			WorldPressure = math.clamp(tonumber(stats.WorldPressure) or 0, 0, 100),
			SocietyInfluence = math.clamp(tonumber(stats.SocietyInfluence) or 0, 0, 100),
			WantedLevel = math.clamp(tonumber(stats.WantedLevel) or 0, 0, 100),
		},
	}
end

function BK_WorldHistoryService.GetTitlesPayload(stats)
	BK_WorldHistoryService.EnsureWorldState(stats)
	local unlocked = stats.UnlockedTitles
	local titles = {}
	for _, def in ipairs(TITLE_DEFINITIONS) do
		local isUnlocked = unlocked[def.Id] == true or def.Check(stats) == true
		if isUnlocked then unlocked[def.Id] = true end
		table.insert(titles, {
			Id = def.Id,
			Name = isUnlocked and def.Name or "???",
			RealName = def.Name,
			Unlocked = isUnlocked,
			Requirement = def.Requirement,
		})
	end
	return { Titles = titles }
end

function BK_WorldHistoryService.Init(ctx)
	context = ctx or {}
	if context.IS_DEBUG then print("[BK_WorldHistoryService] Update 10 world history loaded.") end
end

return BK_WorldHistoryService
