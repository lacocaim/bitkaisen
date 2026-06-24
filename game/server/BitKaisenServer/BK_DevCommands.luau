-- ModuleScript: BK_DevCommands
-- Location: ServerScriptService.BitKaisenServer
-- Purpose: Developer-only chat commands split out of GameManager.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local TextChatService = game:GetService("TextChatService")

local BK_DevCommands = {}

local context = {}
local initialized = false
local textChatCommandHooked = false
local recentDevMessages = {}

local function getStats(player)
	if context.GetStats then
		return context.GetStats(player)
	end
	return nil
end

local function isDev(player)
	if context.IsDev then
		return context.IsDev(player)
	end
	return false
end

local function ensureExtraStats(stats)
	if context.EnsureExtraStats then
		return context.EnsureExtraStats(stats)
	end
end

local function fireLifeUpdate(player, stats, message, forceResetLog)
	if context.FireLifeUpdate then
		return context.FireLifeUpdate(player, stats, message, forceResetLog)
	end
end

local function fireMajorPopup(player, title, body, highlight, footer)
	if context.FireMajorPopup then
		return context.FireMajorPopup(player, title, body, highlight, footer)
	end
end

local function saveStats(player, reason)
	if context.SaveStats then
		return context.SaveStats(player, reason)
	end
end

local function startNewLife(player)
	if context.StartNewLife then
		return context.StartNewLife(player)
	end
end

local function debugStartMinigame(player, key)
	if context.DebugStartMinigame then
		return context.DebugStartMinigame(player, key)
	end

	local serverFolder = ServerScriptService:FindFirstChild("BitKaisenServer")
	local activityModule = serverFolder and serverFolder:FindFirstChild("BK_ActivityService")
	if activityModule then
		local ok, service = pcall(function()
			return require(activityModule)
		end)
		if ok and service and service.DebugStartMinigame then
			return service.DebugStartMinigame(player, key)
		end
	end

	return false, "Activity service is not available."
end

local function loadOrStartLife(player)
	if context.LoadOrStartLife then
		return context.LoadOrStartLife(player)
	end
end

local function normalizeCursedSocietyState(stats)
	if context.NormalizeCursedSocietyState then
		return context.NormalizeCursedSocietyState(stats)
	end
end

local function refreshCurseRebirthEligibility(stats)
	if context.RefreshCurseRebirthEligibility then
		return context.RefreshCurseRebirthEligibility(stats)
	end
end

local function ensureCursedSpiritFlavor(stats)
	if context.EnsureCursedSpiritFlavor then
		return context.EnsureCursedSpiritFlavor(stats)
	end
end

local function isCurseLife(stats)
	if context.IsCurseLife then
		return context.IsCurseLife(stats)
	end
	return false
end

local function pickRandom(list)
	if context.PickRandom then
		return context.PickRandom(list)
	end
	return list[math.random(1, #list)]
end

local function generateDojoRecruitPool(stats)
	if context.GenerateDojoRecruitPool then
		return context.GenerateDojoRecruitPool(stats)
	end
end

local function rollCursedSpiritLifeEvent(player, stats)
	if context.RollCursedSpiritLifeEvent then
		return context.RollCursedSpiritLifeEvent(player, stats)
	end
	return nil
end

local function beginCurseSorcererAttack(player, stats, reason)
	if context.BeginCurseSorcererAttack then
		return context.BeginCurseSorcererAttack(player, stats, reason)
	end
	return false
end

local function startCombat(player, source, enemyConfig)
	if context.StartCombat then
		return context.StartCombat(player, source, enemyConfig)
	end

	local combatModule = script.Parent:FindFirstChild("BK_CombatService")
	if combatModule then
		local ok, service = pcall(function()
			return require(combatModule)
		end)
		if ok and service and service.StartCombat then
			return service.StartCombat(player, source, enemyConfig)
		end
	end

	return false, "Combat service is not available."
end

----------------------------------------------------------------
-- DEV COMMANDS
-- Chat commands for testing only.
-- Add your Roblox UserId to DEV_USER_IDS in GameManager.server.luau (not this file).
-- Usage examples:
--   !bk age 18
--   !bk race curse
--   !bk attack
----------------------------------------------------------------

local DEV_COMMAND_PREFIX = "!bk"

local function shouldHandleDevMessage(player, message)
	if not player then
		return false
	end

	local lowered = string.lower(tostring(message or ""))
	if string.sub(lowered, 1, #DEV_COMMAND_PREFIX) ~= DEV_COMMAND_PREFIX then
		return false
	end

	local now = os.clock()
	local key = tostring(player.UserId) .. ":" .. lowered
	if recentDevMessages[key] and now - recentDevMessages[key] < 0.2 then
		return false
	end
	recentDevMessages[key] = now
	return true
end

local TECHNIQUE_ALIASES = {
	["none"] = "None",
	["limitless"] = "Limitless",
	["ten"] = "Ten Shadows",
	["tenshadows"] = "Ten Shadows",
	["ten shadows"] = "Ten Shadows",
	["blood"] = "Blood Manipulation",
	["blood manipulation"] = "Blood Manipulation",
	["speech"] = "Cursed Speech",
	["cursed speech"] = "Cursed Speech",
	["boogie"] = "Boogie Woogie",
	["boogie woogie"] = "Boogie Woogie",
	["straw"] = "Straw Doll",
	["straw doll"] = "Straw Doll",
	["ratio"] = "Ratio Technique",
	["ratio technique"] = "Ratio Technique",
	["projection"] = "Projection Sorcery",
	["projection sorcery"] = "Projection Sorcery",
	["idle"] = "Idle Transfiguration",
	["idle transfiguration"] = "Idle Transfiguration",
	["shrine"] = "Shrine",
	["heavenly"] = "Heavenly Restriction",
	["heavenly restriction"] = "Heavenly Restriction",
	["disaster flames"] = "Disaster Flames",
	["flames"] = "Disaster Flames",
	["thread"] = "Thread Manipulation",
	["thread manipulation"] = "Thread Manipulation",
	["mirror"] = "Mirror Step",
	["mirror step"] = "Mirror Step",
	["grave"] = "Grave Bloom",
	["grave bloom"] = "Grave Bloom",
	["static"] = "Static Binding",
	["static binding"] = "Static Binding",
	["glass"] = "Glass Veil",
	["glass veil"] = "Glass Veil",
	["paper"] = "Paper Shikigami",
	["paper shikigami"] = "Paper Shikigami",
	["bone"] = "Bone Forge",
	["bone forge"] = "Bone Forge",
	["shadow stitch"] = "Shadow Stitch",
	["echo"] = "Echo Pulse",
	["echo pulse"] = "Echo Pulse",
	["crow"] = "Crow Funeral",
	["crow funeral"] = "Crow Funeral",
}

local GRADE_ALIASES = {
	["non"] = "Non-Sorcerer",
	["none"] = "Non-Sorcerer",
	["nonsorcerer"] = "Non-Sorcerer",
	["non-sorcerer"] = "Non-Sorcerer",
	["4"] = "Grade 4",
	["grade4"] = "Grade 4",
	["grade 4"] = "Grade 4",
	["sg3"] = "Semi-Grade 3",
	["semi3"] = "Semi-Grade 3",
	["semi grade 3"] = "Semi-Grade 3",
	["3"] = "Grade 3",
	["grade3"] = "Grade 3",
	["grade 3"] = "Grade 3",
	["sg2"] = "Semi-Grade 2",
	["semi2"] = "Semi-Grade 2",
	["semi grade 2"] = "Semi-Grade 2",
	["2"] = "Grade 2",
	["grade2"] = "Grade 2",
	["grade 2"] = "Grade 2",
	["sg1"] = "Semi-Grade 1",
	["semi1"] = "Semi-Grade 1",
	["semi grade 1"] = "Semi-Grade 1",
	["1"] = "Grade 1",
	["grade1"] = "Grade 1",
	["grade 1"] = "Grade 1",
	["special"] = "Special Grade",
	["specialgrade"] = "Special Grade",
	["special grade"] = "Special Grade",
}

local CURSE_GRADE_ALIASES = {
	["4"] = "Grade 4 Cursed Spirit",
	["grade4"] = "Grade 4 Cursed Spirit",
	["grade 4"] = "Grade 4 Cursed Spirit",
	["g4"] = "Grade 4 Cursed Spirit",
	["3"] = "Grade 3 Cursed Spirit",
	["grade3"] = "Grade 3 Cursed Spirit",
	["grade 3"] = "Grade 3 Cursed Spirit",
	["g3"] = "Grade 3 Cursed Spirit",
	["2"] = "Grade 2 Cursed Spirit",
	["grade2"] = "Grade 2 Cursed Spirit",
	["grade 2"] = "Grade 2 Cursed Spirit",
	["g2"] = "Grade 2 Cursed Spirit",
	["1"] = "Grade 1 Cursed Spirit",
	["grade1"] = "Grade 1 Cursed Spirit",
	["grade 1"] = "Grade 1 Cursed Spirit",
	["g1"] = "Grade 1 Cursed Spirit",
	["special"] = "Special Grade Cursed Spirit",
	["specialgrade"] = "Special Grade Cursed Spirit",
	["special grade"] = "Special Grade Cursed Spirit",
	["sg"] = "Special Grade Cursed Spirit",
	["disaster"] = "Disaster-Class Cursed Spirit",
	["disastercurse"] = "Disaster-Class Cursed Spirit",
	["disaster curse"] = "Disaster-Class Cursed Spirit",
}

local STATUS_ALIASES = {
	["civilian"] = "Civilian",
	["student"] = "Jujutsu Student",
	["jujutsu"] = "Jujutsu Student",
	["registered"] = "Registered Sorcerer",
	["reg"] = "Registered Sorcerer",
	["unregistered"] = "Unregistered Sorcerer",
	["unreg"] = "Unregistered Sorcerer",
	["curseuser"] = "Curse User",
	["curse user"] = "Curse User",
	["wanted"] = "Wanted Curse User",
	["curse"] = "Unregistered Cursed Spirit",
	["unregisteredcurse"] = "Unregistered Cursed Spirit",
	["unregistered curse"] = "Unregistered Cursed Spirit",
	["classifiedcurse"] = "Registered Cursed Spirit",
	["classified curse"] = "Registered Cursed Spirit",
	["registeredcurse"] = "Registered Cursed Spirit",
	["registered curse"] = "Registered Cursed Spirit",
	["dojo"] = "Dojo Head",
	["dojohead"] = "Dojo Head",
	["dojo head"] = "Dojo Head",
}

local DOJO_RANK_ALIASES = {
	["none"] = "No Dojo",
	["no"] = "No Dojo",
	["unknown"] = "Unknown Dojo",
	["local"] = "Local Dojo",
	["recognized"] = "Recognized Dojo",
	["respected"] = "Respected Dojo",
	["elite"] = "Elite Dojo",
	["legendary"] = "Legendary Dojo",
}

local function splitDevCommand(message)
	local args = {}
	for token in string.gmatch(tostring(message or ""), "%S+") do
		table.insert(args, token)
	end
	return args
end

local function devArgsToText(args, startIndex)
	local pieces = {}
	for index = startIndex or 1, #args do
		table.insert(pieces, tostring(args[index]))
	end
	return table.concat(pieces, " ")
end

local function normalizeDevKey(text)
	text = string.lower(tostring(text or ""))
	text = text:gsub("_", " ")
	text = text:gsub("%-", " ")
	text = text:gsub("%s+", " ")
	text = text:gsub("^%s+", ""):gsub("%s+$", "")
	return text
end

local function getDevNumber(value, fallback, minValue, maxValue)
	local number = tonumber(value)
	if number == nil then
		number = fallback or 0
	end

	if minValue ~= nil then
		number = math.max(minValue, number)
	end

	if maxValue ~= nil then
		number = math.min(maxValue, number)
	end

	return math.floor(number)
end

local function sendDevCommandMessage(player, stats, message, majorTitle)
	if not stats then
		return
	end

	ensureExtraStats(stats)
	fireLifeUpdate(player, stats, "<font color='#b27aff'><b>[ DEV ]</b></font> " .. tostring(message or "Command applied."))

	if majorTitle then
		fireMajorPopup(player, majorTitle, tostring(message or "Command applied."), "Developer Command", "This only works for DEV_USER_IDS.")
	end
end

local function setDevCurseRace(stats)
	stats.Race = "Cursed Spirit"
	stats.Origin = "Vengeful Spirit Rebirth"
	stats.OriginCategory = "Race"
	stats.FamilyType = "Cursed Spirit"
	stats.FamilyName = "Cursed Spirit"
	stats.Clan = "Cursed Spirit"
	stats.IsCurse = true
	stats.CurseType = tostring(stats.CurseType or "Cursed Spirit")
	if stats.CurseType == "None" then
		stats.CurseType = "Cursed Spirit"
	end
	stats.CurseGrade = tostring(stats.CurseGrade or "Unregistered Grade 3 Cursed Spirit")
	if stats.CurseGrade == "None" then
		stats.CurseGrade = "Unregistered Grade 3 Cursed Spirit"
	end
	stats.CurseClassified = false
	stats.CurseEvolution = tostring(stats.CurseEvolution or "Dormant")
	stats.SocietyStatus = "Unregistered Cursed Spirit"
	stats.RegisteredSorcerer = false
	stats.Alive = true
	ensureCursedSpiritFlavor(stats)
	normalizeCursedSocietyState(stats)
end

local function setDevHumanRace(stats)
	stats.Race = "Human"
	stats.OriginCategory = stats.OriginCategory == "Race" and "Family" or stats.OriginCategory
	if tostring(stats.Origin or "") == "Vengeful Spirit Rebirth" or tostring(stats.Origin or "") == "Cursed Spirit Rebirth" or tostring(stats.Origin or "") == "Cursed Rebirth" or tostring(stats.Origin or "") == "Curse" then
		stats.Origin = "Unknown Family"
	end
	if tostring(stats.FamilyType or "") == "Curse" or tostring(stats.FamilyType or "") == "Cursed Spirit" then
		stats.FamilyType = "Unknown"
	end
	if tostring(stats.Clan or "") == "Curse" then
		stats.Clan = stats.FamilyName or "Unknown"
	end
	stats.IsCurse = false
	stats.CurseType = "None"
	stats.CurseGrade = "None"
	stats.CurseEvolution = "None"
	stats.SocietyStatus = "Civilian"
	stats.RegisteredSorcerer = false
	normalizeCursedSocietyState(stats)
end

local function setDevGrade(stats, grade)
	stats.Grade = grade
	if grade ~= "Non-Sorcerer" then
		if stats.FamilyType == "Civilian" or stats.FamilyType == "Unknown" then
			stats.FamilyType = "Sorcerer"
		end
		if not isCurseLife(stats) and stats.SocietyStatus == "Civilian" then
			stats.SocietyStatus = stats.RegisteredSorcerer and "Registered Sorcerer" or "Unregistered Sorcerer"
		end
	else
		if not isCurseLife(stats) then
			stats.SocietyStatus = "Civilian"
			stats.RegisteredSorcerer = false
		end
	end
	normalizeCursedSocietyState(stats)
end

local function grantDevGrandDojo(stats)
	ensureExtraStats(stats)
	stats.Money = math.max(tonumber(stats.Money) or 0, 100000)
	stats.ClanFounded = true
	stats.PlayerClanName = stats.PlayerClanName or tostring(stats.FamilyName or "Dev")
	stats.DojoFounderName = stats.DojoFounderName or tostring(stats.Name or "Dev Founder")
	stats.DojoClanBaseName = stats.DojoClanBaseName or tostring(stats.FamilyName or "Dev")
	stats.DojoPendingLastNameChoice = false
	stats.DojoLevel = math.max(tonumber(stats.DojoLevel) or 1, 1)
	stats.DojoCondition = math.clamp(tonumber(stats.DojoCondition) or 100, 0, 100)
	stats.DojoPrestige = math.max(tonumber(stats.DojoPrestige) or 0, 25)
	stats.DojoReputation = math.max(tonumber(stats.DojoReputation) or 0, 25)
	stats.ClanReputation = math.max(tonumber(stats.ClanReputation) or 0, 25)
	stats.DojoRank = tostring(stats.DojoRank or "Local Dojo")
	stats.Assets = stats.Assets or {}

	local hasGrandDojo = false
	for _, asset in ipairs(stats.Assets) do
		if typeof(asset) == "table" and (asset.Id == "grand_dojo" or asset.BaseId == "grand_dojo") then
			hasGrandDojo = true
			break
		end
	end

	if not hasGrandDojo then
		table.insert(stats.Assets, {
			Id = "grand_dojo",
			BaseId = "grand_dojo",
			Name = "Grand Dojo",
			Type = "Property",
			Category = "Dojo",
			Rarity = "Legendary",
			Description = "Developer-granted Grand Dojo for testing.",
			EffectsText = "Dev command asset.",
			CanUse = false,
			Quantity = 1,
		})
	end

	if generateDojoRecruitPool then
		pcall(function()
			generateDojoRecruitPool(stats)
		end)
	end
	normalizeCursedSocietyState(stats)
end

local function addDevStudent(stats)
	ensureExtraStats(stats)
	stats.Relationships = stats.Relationships or {}
	stats.DojoStudents = stats.DojoStudents or {}

	local studentId = "dev_student_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
	local firstNames = { "Ren", "Akio", "Mizuki", "Kaito", "Yuna", "Daiki", "Hana", "Riku" }
	local familyNames = { "Kumiwado", "Mizukara", "Amahara", "Kurogiri", "Hoshinari" }
	local techniques = { "None", "Straw Doll", "Ratio Technique", "Cursed Speech", "Blood Manipulation", "Boogie Woogie", "Ten Shadows" }
	local name = firstNames[math.random(1, #firstNames)] .. " " .. familyNames[math.random(1, #familyNames)]

	local student = {
		Id = studentId,
		Name = name,
		Role = "Student",
		Age = math.random(14, 18),
		Gender = math.random(1, 2) == 1 and "Male" or "Female",
		Grade = "Grade 4",
		SorcererGrade = "Grade 4",
		CursedTechnique = techniques[math.random(1, #techniques)],
		CursedEnergy = math.random(25, 90),
		TechniqueMastery = math.random(0, 25),
		Bond = math.random(35, 65),
		Trust = math.random(25, 55),
		Respect = math.random(25, 55),
		Fear = 0,
		Romance = 0,
		Alive = true,
		Status = "Training",
		Personality = "A developer-created test student.",
		Background = name .. " joined your dojo through a dev command for testing.",
		DojoStudent = true,
		Potential = math.random(45, 90),
		Loyalty = math.random(35, 75),
		Discipline = math.random(35, 75),
		Progress = 0,
	}

	table.insert(stats.Relationships, student)
	table.insert(stats.DojoStudents, student)
	stats.ClanStudentCount = (tonumber(stats.ClanStudentCount) or 0) + 1
	stats.ClanStudentsRecruited = (tonumber(stats.ClanStudentsRecruited) or 0) + 1
	return name
end

local function getDevCommandHelpText()
	return table.concat({
		"Useful commands:",
		"!bk help",
		"!bk age 18 | !bk month 12 | !bk kill | !bk revive | !bk newlife",
		"!bk ce 500 | !bk mastery 80 | !bk money 999999 | !bk health 100 | !bk happy 100 | !bk smarts 80",
		"!bk tech limitless | !bk tech heavenly | !bk tech shrine | !bk tech none",
		"!bk grade grade1 | !bk grade special | !bk status registered | !bk wanted 5 | !bk rep -50 | !bk rec 10",
		"!bk race spirit | !bk race human | !bk resentment 200 | !bk cursegrade special | !bk cursegrade disaster | !bk threat 250 | !bk evolution 500 | !bk attack",
		"!bk fight | !bk testfight",
		"!bk hunger 80 | !bk territory school | !bk rumor mirror | !bk attention 50 | !bk curseevent",
		"!bk dojo | !bk dojorank elite | !bk dojorep 500 | !bk student",
		"!bk minigame blackflash | 21 | rct | finger | heirloom | burglary | raid",
	}, "\n")
end

local function runBitKaisenDevCommand(player, rawMessage)
	if not isDev(player) then
		return
	end

	local args = splitDevCommand(rawMessage)
	if #args < 2 then
		return
	end

	if string.lower(args[1]) ~= DEV_COMMAND_PREFIX then
		return
	end

	local command = string.lower(tostring(args[2] or ""))
	local stats = getStats(player)

	if command == "help" or command == "cmds" or command == "commands" then
		if stats then
			sendDevCommandMessage(player, stats, getDevCommandHelpText(), "BITKAISEN DEV COMMANDS")
		else
			fireMajorPopup(player, "BITKAISEN DEV COMMANDS", getDevCommandHelpText(), "Developer Commands", "No life loaded yet.")
		end
		return
	end

	if command == "newlife" or command == "new" then
		startNewLife(player)
		return
	end

	if not stats then
		fireMajorPopup(player, "DEV COMMAND FAILED", "No BitKaisen life is loaded yet.", "No Life", "Try again after your save finishes loading.")
		return
	end

	ensureExtraStats(stats)
	local value = args[3]
	local message = nil
	local shouldSave = true

	if command == "age" then
		stats.Age = getDevNumber(value, stats.Age or 0, 0, 999)
		stats.CurrentMonth = math.clamp(tonumber(stats.CurrentMonth) or 1, 1, 12)
		stats.MonthsIntoAge = math.clamp(tonumber(stats.MonthsIntoAge) or 0, 0, 11)
		message = "Age set to <b>" .. tostring(stats.Age) .. "</b>."

	elseif command == "month" then
		stats.CurrentMonth = getDevNumber(value, stats.CurrentMonth or 1, 1, 12)
		stats.MonthsIntoAge = stats.CurrentMonth - 1
		message = "Month set to <b>" .. tostring(stats.CurrentMonth) .. "</b>."

	elseif command == "kill" or command == "die" then
		stats.Alive = false
		stats.Health = 0
		stats.CauseOfDeath = devArgsToText(args, 3)
		if stats.CauseOfDeath == "" then
			stats.CauseOfDeath = "Developer command"
		end
		refreshCurseRebirthEligibility(stats)
		message = "Current life killed. Cause: <b>" .. tostring(stats.CauseOfDeath) .. "</b>."
		fireMajorPopup(player, "DEV DEATH", "The current life was ended by command.", tostring(stats.CauseOfDeath), "Death UI should open if your DeathUI script is active.")

	elseif command == "revive" then
		stats.Alive = true
		stats.Health = math.max(tonumber(stats.Health) or 0, 100)
		stats.CauseOfDeath = nil
		stats.CurseRebirthEligible = false
		message = "Current life revived."

	elseif command == "ce" or command == "cursedenergy" then
		stats.CursedEnergy = getDevNumber(value, stats.CursedEnergy or 0, 0, 999999999)
		message = "Cursed Energy set to <b>" .. tostring(stats.CursedEnergy) .. "</b>."

	elseif command == "mastery" or command == "tm" then
		stats.TechniqueMastery = getDevNumber(value, stats.TechniqueMastery or 0, 0, 100)
		message = "Technique Mastery set to <b>" .. tostring(stats.TechniqueMastery) .. "</b>."

	elseif command == "money" or command == "cash" then
		stats.Money = getDevNumber(value, stats.Money or 0, 0, 999999999)
		message = "Money set to <b>$" .. tostring(stats.Money) .. "</b>."

	elseif command == "health" or command == "hp" then
		stats.Health = getDevNumber(value, stats.Health or 100, 0, 100)
		if stats.Health > 0 then stats.Alive = true end
		message = "Health set to <b>" .. tostring(stats.Health) .. "</b>."

	elseif command == "happy" or command == "happiness" then
		stats.Happiness = getDevNumber(value, stats.Happiness or 100, 0, 100)
		message = "Happiness set to <b>" .. tostring(stats.Happiness) .. "</b>."

	elseif command == "smarts" or command == "smart" then
		stats.Smarts = getDevNumber(value, stats.Smarts or 0, 0, 100)
		message = "Smarts set to <b>" .. tostring(stats.Smarts) .. "</b>."

	elseif command == "rep" or command == "reputation" then
		stats.Reputation = getDevNumber(value, stats.Reputation or 0, -999999, 999999)
		message = "Reputation set to <b>" .. tostring(stats.Reputation) .. "</b>."

	elseif command == "fame" then
		stats.Fame = getDevNumber(value, stats.Fame or 0, 0, 100)
		message = "Fame set to <b>" .. tostring(stats.Fame) .. "</b>."

	elseif command == "fear" then
		stats.Fear = getDevNumber(value, stats.Fear or 0, 0, 100)
		message = "Fear set to <b>" .. tostring(stats.Fear) .. "</b>."

	elseif command == "support" or command == "publicsupport" then
		stats.PublicSupport = getDevNumber(value, stats.PublicSupport or 0, 0, 100)
		message = "Public Support set to <b>" .. tostring(stats.PublicSupport) .. "</b>."

	elseif command == "hunter" or command == "hunterpressure" then
		stats.HunterPressure = getDevNumber(value, stats.HunterPressure or 0, 0, 100)
		message = "Hunter Pressure set to <b>" .. tostring(stats.HunterPressure) .. "</b>."

	elseif command == "repcleanup" or command == "cleanup" then
		stats.HunterPressure = getDevNumber(value, 50, 0, 100)
		stats.WorldPressure = getDevNumber(args[4], 65, 0, 100)
		stats.CopycatIncidents = getDevNumber(args[5], 2, 0, 99)
		stats.PublicSupport = math.max(tonumber(stats.PublicSupport) or 0, 25)
		message = "Reputation cleanup setup: Hunter <b>" .. tostring(stats.HunterPressure) .. "</b>, World Pressure <b>" .. tostring(stats.WorldPressure) .. "</b>, Copycats <b>" .. tostring(stats.CopycatIncidents) .. "</b>."

	elseif command == "wanted" or command == "wantedlevel" then
		stats.WantedLevel = getDevNumber(value, stats.WantedLevel or 0, 0, 100)
		message = "Wanted Level set to <b>" .. tostring(stats.WantedLevel) .. "</b>."

	elseif command == "rec" or command == "recs" or command == "recommendations" then
		stats.Recommendations = getDevNumber(value, stats.Recommendations or 0, 0, 9999)
		stats.TeacherRecommendations = stats.Recommendations
		message = "Recommendations set to <b>" .. tostring(stats.Recommendations) .. "</b>."

	elseif command == "resentment" or command == "cr" then
		stats.CursedResentment = getDevNumber(value, stats.CursedResentment or 0, 0, 999)
		refreshCurseRebirthEligibility(stats)
		message = "Cursed Resentment set to <b>" .. tostring(stats.CursedResentment) .. "</b>."

	elseif command == "threat" or command == "cursethreat" then
		stats.CurseThreat = getDevNumber(value, stats.CurseThreat or 0, 0, 9999)
		message = "Curse Threat set to <b>" .. tostring(stats.CurseThreat) .. "</b>."

	elseif command == "evolution" or command == "evo" then
		stats.CurseEvolutionProgress = getDevNumber(value, stats.CurseEvolutionProgress or stats.CurseEvolution or 0, 0, 99999)
		stats.CurseEvolution = tostring(stats.CurseEvolutionProgress)
		message = "Curse Evolution Progress set to <b>" .. tostring(stats.CurseEvolutionProgress) .. "</b>."

	elseif command == "tech" or command == "technique" then
		local key = normalizeDevKey(devArgsToText(args, 3))
		local technique = TECHNIQUE_ALIASES[key] or devArgsToText(args, 3)
		if technique == "" then technique = "None" end
		stats.CursedTechnique = technique
		stats.TechniqueAwakened = technique ~= "None"
		if technique == "None" then
			stats.TechniqueMastery = 0
		else
			stats.TechniqueMastery = math.max(tonumber(stats.TechniqueMastery) or 0, 1)
		end
		message = "Technique set to <b>" .. tostring(stats.CursedTechnique) .. "</b>."

	elseif command == "grade" then
		local key = normalizeDevKey(devArgsToText(args, 3))
		local grade = GRADE_ALIASES[key] or devArgsToText(args, 3)
		if grade == "" then grade = "Grade 4" end
		setDevGrade(stats, grade)
		message = "Sorcerer grade set to <b>" .. tostring(stats.Grade) .. "</b>."

	elseif command == "cursegrade" or command == "cg" then
		local key = normalizeDevKey(devArgsToText(args, 3))
		local curseGrade = CURSE_GRADE_ALIASES[key] or devArgsToText(args, 3)
		if curseGrade == "" then curseGrade = "Grade 4 Cursed Spirit" end
		stats.CurseGrade = curseGrade
		if curseGrade == "Disaster-Class Cursed Spirit" or curseGrade == "Disaster Curse" then
			stats.CurseGrade = "Special Grade Cursed Spirit"
			stats.CurseThreatClass = "Disaster"
		end
		if not isCurseLife(stats) then
			setDevCurseRace(stats)
		end
		message = "Cursed Spirit classification set to <b>" .. tostring(stats.CurseGrade) .. "</b>. Threat Class: <b>" .. tostring(stats.CurseThreatClass or "None") .. "</b>."

	elseif command == "race" then
		local key = normalizeDevKey(devArgsToText(args, 3))
		if key == "curse" or key == "cursedspirit" or key == "cursed spirit" or key == "spirit" then
			setDevCurseRace(stats)
			message = "Race set to <b>Cursed Spirit</b>."
		elseif key == "human" or key == "normal" then
			setDevHumanRace(stats)
			message = "Race set to <b>Human</b>."
		else
			message = "Unknown race. Use <b>!bk race curse</b> or <b>!bk race human</b>."
			shouldSave = false
		end

	elseif command == "status" then
		local key = normalizeDevKey(devArgsToText(args, 3))
		local status = STATUS_ALIASES[key] or devArgsToText(args, 3)
		if status == "" then status = "Civilian" end
		stats.SocietyStatus = status
		stats.RegisteredSorcerer = status == "Registered Sorcerer" or status == "Jujutsu Student"
		if status == "Curse User" or status == "Wanted Curse User" then
			stats.CurseUser = true
			stats.RegisteredSorcerer = false
		end
		message = "Society Status set to <b>" .. tostring(stats.SocietyStatus) .. "</b>."

	elseif command == "hunger" or command == "cursehunger" then
		setDevCurseRace(stats)
		stats.CurseHunger = getDevNumber(value, stats.CurseHunger or 0, 0, 100)
		message = "Cursed Spirit Hunger set to <b>" .. tostring(stats.CurseHunger) .. "%</b>."

	elseif command == "attention" or command == "societyattention" then
		setDevCurseRace(stats)
		stats.SocietyAttention = getDevNumber(value, stats.SocietyAttention or 0, 0, 100)
		stats.ExorcismRisk = math.clamp(math.max(tonumber(stats.ExorcismRisk) or 0, math.floor(stats.SocietyAttention / 2)), 0, 100)
		message = "Society Attention set to <b>" .. tostring(stats.SocietyAttention) .. "%</b>."

	elseif command == "territory" or command == "haunt" then
		setDevCurseRace(stats)
		local key = normalizeDevKey(devArgsToText(args, 3))
		local chosen = devArgsToText(args, 3)
		if key == "" or key == "random" then
			chosen = pickRandom(context.CurseTerritories or { "Abandoned School", "Hospital Basement", "Old Apartment Complex", "Forest Shrine", "Sewer Tunnel" })
		elseif key == "school" then chosen = "Abandoned School"
		elseif key == "station" or key == "train" then chosen = "Last Train Station"
		elseif key == "hospital" then chosen = "Hospital Basement"
		elseif key == "apartment" then chosen = "Old Apartment Complex"
		elseif key == "shrine" then chosen = "Forest Shrine"
		elseif key == "sewer" then chosen = "Sewer Tunnel"
		end
		stats.CurseTerritory = chosen
		stats.CurseTerritoryControl = math.max(tonumber(stats.CurseTerritoryControl) or 0, 15)
		message = "Cursed Spirit territory set to <b>" .. tostring(stats.CurseTerritory) .. "</b>."

	elseif command == "rumor" or command == "title" then
		setDevCurseRace(stats)
		local chosen = devArgsToText(args, 3)
		if chosen == "" or normalizeDevKey(chosen) == "random" then
			chosen = pickRandom(context.CurseRumorTitles or { "Unnamed Curse", "Hallway Curse", "Mirror Curse", "Station Curse" })
		end
		stats.CurseRumor = chosen
		stats.CurseRumorSpread = math.max(tonumber(stats.CurseRumorSpread) or 0, 10)
		message = "Cursed Spirit rumor set to <b>" .. tostring(stats.CurseRumor) .. "</b>."

	elseif command == "curseevent" or command == "spiritlife" then
		setDevCurseRace(stats)
		local eventText = rollCursedSpiritLifeEvent(player, stats)
		if eventText == "" then
			eventText = "No cursed spirit event rolled."
		end
		message = eventText

	elseif command == "fight" or command == "testfight" or command == "combat" then
		local started, err = startCombat(player, "Developer Test Fight", {
			Name = "Developer Test Curse User",
			Kind = "Curse User",
			Grade = "Grade 2",
			PowerScale = 0.72,
			ComboMin = 1,
			ComboMax = 3,
		})
		if started then
			message = "Started an interactive combat test fight."
		else
			message = "Could not start combat: " .. tostring(err or "unknown error")
			shouldSave = false
		end

	elseif command == "attack" or command == "sorcererattack" then
		setDevCurseRace(stats)
		stats.SorcererAttackCooldown = 0
		local started = beginCurseSorcererAttack(player, stats, "Developer command forced a sorcerer attack.")
		if started then
			message = "Forced a sorcerer attack event."
		else
			message = "Could not start sorcerer attack. Check pending events or curse state."
		end

	elseif command == "dojo" then
		grantDevGrandDojo(stats)
		message = "Grand Dojo test setup granted."

	elseif command == "dojorank" then
		local key = normalizeDevKey(devArgsToText(args, 3))
		stats.DojoRank = DOJO_RANK_ALIASES[key] or devArgsToText(args, 3)
		if stats.DojoRank == "" then stats.DojoRank = "Local Dojo" end
		message = "Dojo Rank set to <b>" .. tostring(stats.DojoRank) .. "</b>."

	elseif command == "dojorep" or command == "dojoreputation" then
		stats.DojoReputation = getDevNumber(value, stats.DojoReputation or stats.ClanReputation or 0, 0, 999999)
		stats.ClanReputation = stats.DojoReputation
		message = "Dojo Reputation set to <b>" .. tostring(stats.DojoReputation) .. "</b>."

	elseif command == "dojodamage" or command == "dojo damage" then
		grantDevGrandDojo(stats)
		stats.DojoCondition = getDevNumber(value, 35, 0, 100)
		stats.DojoRecoveryDebt = math.max(tonumber(stats.DojoRecoveryDebt) or 0, getDevNumber(args[4], 3500, 0, 999999))
		stats.DojoRaidRisk = math.max(tonumber(stats.DojoRaidRisk) or 0, 45)
		message = "Dojo damage setup: condition <b>" .. tostring(stats.DojoCondition) .. "</b>, recovery debt <b>$" .. tostring(stats.DojoRecoveryDebt) .. "</b>."

	elseif command == "student" or command == "addstudent" then
		grantDevGrandDojo(stats)
		local studentName = addDevStudent(stats)
		message = "Added test student: <b>" .. tostring(studentName) .. "</b>."

	elseif command == "minigame" or command == "mg" or command == "blackflash" or command == "rct" or command == "finger" or command == "heirloom" or command == "burglary" or command == "raid" or command == "21" then
		local key = command
		if command == "minigame" or command == "mg" then
			key = devArgsToText(args, 3)
		end
		local started, detail = debugStartMinigame(player, key)
		if started then
			message = "Started minigame: <b>" .. tostring(detail or key) .. "</b>."
		else
			message = "Could not start minigame. " .. tostring(detail or "Unknown error.")
			shouldSave = false
		end

	else
		message = "Unknown command <b>" .. tostring(command) .. "</b>. Use <b>!bk help</b>."
		shouldSave = false
	end

	ensureExtraStats(stats)
	normalizeCursedSocietyState(stats)
	sendDevCommandMessage(player, stats, message)

	if shouldSave then
		saveStats(player, "DevCommand")
	end
end

local function hookTextChatCommand()
	if textChatCommandHooked then
		return
	end
	textChatCommandHooked = true

	local command = TextChatService:FindFirstChild("BitKaisenDevCommand")
	if not command then
		command = Instance.new("TextChatCommand")
		command.Name = "BitKaisenDevCommand"
		command.PrimaryAlias = DEV_COMMAND_PREFIX
		command.Parent = TextChatService
	end

	command.Triggered:Connect(function(originTextSource, unfilteredText)
		local userId = originTextSource and originTextSource.UserId
		local player = userId and Players:GetPlayerByUserId(userId)
		if not player then
			return
		end

		local message = tostring(unfilteredText or "")
		if string.sub(string.lower(message), 1, #DEV_COMMAND_PREFIX) ~= DEV_COMMAND_PREFIX then
			message = DEV_COMMAND_PREFIX .. " " .. message
		end

		if shouldHandleDevMessage(player, message) then
			runBitKaisenDevCommand(player, message)
		end
	end)
end

function BK_DevCommands.HookPlayer(player)
	if not player then
		return
	end

	hookTextChatCommand()

	if player:GetAttribute("BitKaisenDevCommandsHooked") then
		return
	end

	player:SetAttribute("BitKaisenDevCommandsHooked", true)

	player.Chatted:Connect(function(message)
		if shouldHandleDevMessage(player, message) then
			runBitKaisenDevCommand(player, message)
		end
	end)
end

function BK_DevCommands.Init(ctx)
	context = ctx or context or {}
	hookTextChatCommand()

	if not initialized then
		initialized = true
		if context and context.IS_DEBUG then print("[BK_DevCommands] Loaded.") end
	end
end

return BK_DevCommands

