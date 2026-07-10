-- ModuleScript: BK_ActivityService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose:
--   Phase 6 GameManager split.
--   Owns activity list payloads and activity action handling that used to live directly inside GameManager.
--   Server protocol is unchanged: GetActivityList still returns the same list and DoActivity still calls the same action path.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BitKaisenActivities = require(ReplicatedStorage:WaitForChild("BitKaisenActivities"))
local BK_CultService = require(ServerScriptService:WaitForChild("BitKaisenServer"):WaitForChild("BK_CultService"))
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local BitKaisenRelationships = require(ReplicatedStorage:WaitForChild("BitKaisenRelationships"))
local BitKaisenAssets = require(ReplicatedStorage:WaitForChild("BitKaisenAssets"))
local BitKaisenTraits = require(ReplicatedStorage:WaitForChild("BitKaisenTraits"))
local BitKaisenTechniqueEvolution = require(ReplicatedStorage:WaitForChild("BitKaisenTechniqueEvolution"))
local BitKaisenCurseEvolution = require(ReplicatedStorage:WaitForChild("BitKaisenCurseEvolution"))
local BitKaisenCombat = require(ReplicatedStorage:WaitForChild("BitKaisenCombat"))
local BitKaisenStats = require(ReplicatedStorage:WaitForChild("BitKaisenStats"))

local BK_ActivityService = {}
local context = {}

-- Short alias so each logMessage line stays readable
local function tAct(player, key, params, fallback)
	local locale = BitKaisenLocale.getPlayerLocale(player.UserId)
	return BitKaisenLocale.tOrFallback(locale, "activities." .. key, params, fallback)
end
local minigameSessions = {}
local completeMinigameConnection = nil

local function getStats(player)
	if context.GetStats then
		return context.GetStats(player)
	end
	return nil
end

local function ensureExtraStats(stats)
	if context.EnsureExtraStats then
		return context.EnsureExtraStats(stats)
	end
end

local function isDev(player)
	if context.IsDev then
		return context.IsDev(player)
	end
	return false
end

local function fireLifeUpdate(player, stats, message, forceResetLog)
	if context.FireLifeUpdate then
		return context.FireLifeUpdate(player, stats, message, forceResetLog)
	end
end

local function adjustWorldReputation(stats, fameDelta, fearDelta, pathDelta)
	if context.AdjustWorldReputation then
		return context.AdjustWorldReputation(stats, fameDelta, fearDelta, pathDelta)
	end
	return ""
end

local function fireMajorPopup(player, title, body, highlight, footer)
	if context.FireMajorPopup then
		return context.FireMajorPopup(player, title, body, highlight, footer)
	end
end

local function fireRelationshipPopup(player, popupData)
	if context.FireRelationshipPopup then
		return context.FireRelationshipPopup(player, popupData)
	end
end

local function saveStats(player, reason)
	if context.SaveStats then
		return context.SaveStats(player, reason)
	end
end

local function applyMiracleSave(stats, player)
	if (tonumber(stats.Health) or 100) > 0 then return false end
	local charges = tonumber(stats.MiracleCharges) or 0
	if tostring(stats.CursedTechnique) ~= "Miracle" or charges <= 0 then return false end
	stats.MiracleCharges = charges - 1
	stats.Health = 1
	local remaining = tonumber(stats.MiracleCharges) or 0
	fireLifeUpdate(player, stats, remaining > 0
		and ("<font color='#c8a4ff'><b>[ MIRACLE ]</b></font> A miracle rewrote your fate. Marks remaining: <b>" .. remaining .. "</b>.")
		or "<font color='#c8a4ff'><b>[ MIRACLE ]</b></font> Your last miracle saved you. Your marks have disappeared — you are now completely vulnerable.")
	return true
end

local function forceAwaken(player, stats, reason)
	if context.ForceAwaken then
		return context.ForceAwaken(player, stats, reason)
	end
	return tostring(stats and stats.CursedTechnique or "None")
end

local function captureTraitBuffSnapshot(stats, relationship)
	if context.CaptureTraitBuffSnapshot then
		return context.CaptureTraitBuffSnapshot(stats, relationship)
	end
	return {}
end

local function applyTraitBuffsFromSnapshot(stats, before, actionContext, relationship)
	if context.ApplyTraitBuffsFromSnapshot then
		return context.ApplyTraitBuffsFromSnapshot(stats, before, actionContext, relationship)
	end
	return ""
end

local function ownsTrainingProdigyPass(player)
	if context.OwnsTrainingProdigyPass then
		return context.OwnsTrainingProdigyPass(player)
	end
	return false
end

local function ownsFocusedTrainingPass(player)
	if context.OwnsFocusedTrainingPass then
		return context.OwnsFocusedTrainingPass(player)
	end
	return false
end

local function ownsDoubleTrainingPass(player)
	if context.OwnsDoubleTrainingPass then
		return context.OwnsDoubleTrainingPass(player)
	end
	return false
end

local function ownsVIPPass(player)
	if context.OwnsVIPPass then
		return context.OwnsVIPPass(player)
	end
	return false
end

local function getDojoFocusLabel(stats)
	if context.GetDojoFocusLabel then
		return context.GetDojoFocusLabel(stats)
	end
	return "Balanced"
end

local function maybeTeacherRecommendation(player, stats, logMessage)
	if context.MaybeTeacherRecommendation then
		return context.MaybeTeacherRecommendation(player, stats, logMessage)
	end
	return logMessage
end

local function checkPromotionAndPopup(player, stats, logMessage)
	if context.CheckPromotionAndPopup then
		return context.CheckPromotionAndPopup(player, stats, logMessage)
	end
	return logMessage
end

local function isCurseLife(stats)
	if context.IsCurseLife then
		return context.IsCurseLife(stats)
	end
	return false
end

local function canUseCurseActivity(stats)
	if isCurseLife(stats) then
		return true
	end

	local origin = tostring(stats and (stats.Origin or stats.Clan) or "")
	local curseType = tostring(stats and stats.CurseType or "")
	return origin == "Cursed Womb" or curseType == "Cursed Womb" or curseType == "Death Painting"
end

local function addCurseEvolutionProgress(stats, amount, source)
	local result = BitKaisenCurseEvolution.AddProgress(stats, amount, source)
	return result.Message or ""
end

local function isCurseUser(stats)
	if context.IsCurseUser then
		return context.IsCurseUser(stats)
	end
	return false
end

local function isUnregisteredSorcerer(stats)
	if context.IsUnregisteredSorcerer then
		return context.IsUnregisteredSorcerer(stats)
	end
	return false
end

local function enrollInJujutsuHigh(player, stats)
	if not stats then return "", false end
	local getEstimatedUnregisteredGrade = context.GetEstimatedUnregisteredGrade
	local adjustWorldReputation = context.AdjustWorldReputation
	local fireMajorPopup = context.FireMajorPopup

	local officialGrade = getEstimatedUnregisteredGrade and getEstimatedUnregisteredGrade(stats) or tostring(stats.Grade or "Grade 4")

	stats.InJujutsuHigh = true
	stats.RegisteredSorcerer = true
	stats.Grade = officialGrade
	stats.OfficialGrade = officialGrade
	stats.UnregisteredGrade = nil
	stats.UnregisteredProgress = 0
	stats.UnregisteredGradeUps = 0
	stats.Reputation = (tonumber(stats.Reputation) or 0) + 10
	stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) + 12, 0, 100)
	stats.Affiliation = "Jujutsu High"
	stats.AffiliationRank = "Student"
	stats.AffiliationReputation = math.clamp((tonumber(stats.AffiliationReputation) or 0) + 10, 0, 100)
	stats.LifePath = "Jujutsu High"

	local repText = ""
	if adjustWorldReputation then
		repText = adjustWorldReputation(stats, 3, 0, 4) or ""
	end

	local logMsg = "You were accepted into Jujutsu High and officially registered as <b>" .. tostring(officialGrade) .. "</b>." .. repText

	local teacher = BitKaisenRelationships.AddTeacher(stats)

	if fireMajorPopup then
		fireMajorPopup(
			player,
			"JUJUTSU HIGH ACCEPTANCE",
			"Your application was reviewed by the jujutsu world.",
			"Accepted",
			"Your unregistered grade became official."
		)
	end

	if teacher then
		logMsg = logMsg .. "\n" .. teacher.Name .. " was assigned as one of your instructors."
		if fireMajorPopup then
			fireMajorPopup(
				player,
				"TEACHER ASSIGNED",
				"Someone at Jujutsu High will be watching your progress.",
				teacher.Name,
				"Teachers can submit promotion recommendations."
			)
		end
	end

	return logMsg, true
end

BK_ActivityService.EnrollInJujutsuHigh = enrollInJujutsuHigh

local DOJO_RAID_VARIANTS = {
	{
		Id = "Rival Clan Raid",
		Title = "RIVAL CLAN RAID",
		Lead = "A rival clan moved on your dojo to break your house's reputation.",
		ThreatBonus = 8,
		Success = "The rival clan withdrew after your defense embarrassed their strike team.",
		Failure = "The rival clan damaged your dojo banners, records, and public standing.",
		RiskFail = 14,
		ConditionDamage = 18,
		ReputationLoss = 10,
		LegacyLoss = 8,
		ClanLoss = 8,
		ProtectionDamage = 2,
	},
	{
		Id = "Curse User Raid",
		Title = "CURSE USER RAID",
		Lead = "Curse users targeted your dojo for stored tools and students with potential.",
		ThreatBonus = 12,
		Success = "You drove the curse users out before they could mark the grounds.",
		Failure = "The curse users escaped with tools, blood samples, and dangerous rumors.",
		RiskFail = 18,
		ConditionDamage = 14,
		ReputationLoss = 6,
		LegacyLoss = 5,
		WantedGain = 3,
		FearGain = 3,
		ProtectionDamage = 1,
	},
	{
		Id = "Student Abduction Attempt",
		Title = "STUDENT ABDUCTION",
		Lead = "The attackers tried to take one of your students alive.",
		ThreatBonus = 15,
		Success = "Your evacuation plan held and every student escaped the trap.",
		Failure = "Students were injured during the failed evacuation, shaking trust in your dojo.",
		RiskFail = 16,
		ConditionDamage = 10,
		ReputationLoss = 8,
		LegacyLoss = 7,
		StudentInjury = 1,
		ProtectionDamage = 3,
	},
	{
		Id = "Cursed Tool Theft",
		Title = "CURSED TOOL THEFT",
		Lead = "A quiet raid team slipped in to steal cursed tools and succession records.",
		ThreatBonus = 4,
		Success = "You caught the thieves in the inner storehouse and turned the trap on them.",
		Failure = "The thieves escaped with supplies and forced an expensive recovery.",
		RiskFail = 10,
		ConditionDamage = 12,
		ReputationLoss = 4,
		LegacyLoss = 4,
		MoneyLoss = 1800,
		SupplyLoss = 1,
		ProtectionDamage = 1,
	},
}

local function chooseDojoRaidVariant(stats)
	local risk = tonumber(stats.DojoRaidRisk) or 0
	if (tonumber(stats.ClanRivalries) or 0) > 0 and math.random(1, 100) <= 35 then
		return DOJO_RAID_VARIANTS[1]
	end
	if risk >= 70 and math.random(1, 100) <= 30 then
		return DOJO_RAID_VARIANTS[3]
	end
	return DOJO_RAID_VARIANTS[math.random(1, #DOJO_RAID_VARIANTS)]
end

local function getDojoRaidVariantById(id)
	id = tostring(id or "")
	for _, variant in ipairs(DOJO_RAID_VARIANTS) do
		if variant.Id == id then
			return variant
		end
	end
	return DOJO_RAID_VARIANTS[1]
end

local TOURNAMENT_FIRST_NAMES = {
	"Ryo", "Mira", "Tsubaki", "Kazuki", "Noa", "Haruto", "Aoi", "Ren", "Sora", "Natsuki", "Hana", "Daichi"
}

local TOURNAMENT_FAMILY_NAMES = {
	"Kurogane", "Fushidori", "Yamashiro", "Mizuno", "Arakawa", "Tsukigane", "Shirogami", "Hoshino"
}

local TOURNAMENT_ARCHETYPES = {
	{ Title = "Clan Fighter", Power = 145, Fame = 1, Fear = 1 },
	{ Title = "Rogue Sorcerer", Power = 165, Fame = 0, Fear = 3 },
	{ Title = "Jujutsu Dropout", Power = 135, Fame = 1, Fear = 2 },
	{ Title = "Cursed Tool Specialist", Power = 155, Fame = 1, Fear = 1 },
	{ Title = "Domain Trainee", Power = 185, Fame = 2, Fear = 2 },
	{ Title = "Heian Style Brawler", Power = 205, Fame = 2, Fear = 4 },
}

local function makeTournamentOpponent(round, stats)
	local archetype = TOURNAMENT_ARCHETYPES[math.random(1, #TOURNAMENT_ARCHETYPES)]
	local worldPressure = tonumber(stats.WorldPressure) or 0
	local reputationPressure = math.floor(((tonumber(stats.Fame) or 0) + (tonumber(stats.Fear) or 0)) / 12)
	local roundPressure = (round - 1) * math.random(26, 42)
	local name = TOURNAMENT_FIRST_NAMES[math.random(1, #TOURNAMENT_FIRST_NAMES)] .. " " .. TOURNAMENT_FAMILY_NAMES[math.random(1, #TOURNAMENT_FAMILY_NAMES)]

	return {
		Name = name,
		Title = archetype.Title,
		Power = archetype.Power + roundPressure + math.random(-18, 28) + reputationPressure + math.floor(worldPressure / 8),
		Fame = archetype.Fame,
		Fear = archetype.Fear,
	}
end

local function runUndergroundTournament(stats)
	local playerPower = BitKaisenCombat.GetCombatPower(stats, { PowerBonus = math.random(-12, 20) })
	local wins = 0
	local opponents = {}

	for round = 1, 3 do
		local opponent = makeTournamentOpponent(round, stats)
		table.insert(opponents, opponent)
		local roundPower = playerPower + math.random(-35, 35) + (wins * 8)
		if roundPower >= opponent.Power then
			wins += 1
		else
			break
		end
	end

	return wins, opponents, math.floor(playerPower)
end

local function isOfficialJujutsuSorcerer(stats)
	if context.IsOfficialJujutsuSorcerer then
		return context.IsOfficialJujutsuSorcerer(stats)
	end
	return false
end

local function getEstimatedUnregisteredGrade(stats)
	if context.GetEstimatedUnregisteredGrade then
		return context.GetEstimatedUnregisteredGrade(stats)
	end
	return "Non-Sorcerer"
end

local function ensureSorcererRegistrationState(stats)
	if context.EnsureSorcererRegistrationState then
		return context.EnsureSorcererRegistrationState(stats)
	end
end

local function ensureCursedSpiritFlavor(stats)
	if context.EnsureCursedSpiritFlavor then
		return context.EnsureCursedSpiritFlavor(stats)
	end
end

local function addCurseHunger(stats, amount)
	if context.AddCurseHunger then
		return context.AddCurseHunger(stats, amount)
	end
end

local function reduceCurseHunger(stats, amount)
	if context.ReduceCurseHunger then
		return context.ReduceCurseHunger(stats, amount)
	end
end

local function addSocietyAttention(stats, amount)
	if context.AddSocietyAttention then
		return context.AddSocietyAttention(stats, amount)
	end
end

local function applyCursedSpiritActivityFlavor(stats, actionId)
	if context.ApplyCursedSpiritActivityFlavor then
		return context.ApplyCursedSpiritActivityFlavor(stats, actionId)
	end
	return "Your cursed spirit instincts shifted."
end

local function beginCurseSorcererAttack(player, stats, reason)
	if context.BeginCurseSorcererAttack then
		return context.BeginCurseSorcererAttack(player, stats, reason)
	end
	return false
end

local function countClanStudents(stats)
	if context.CountClanStudents then
		return context.CountClanStudents(stats)
	end
	return 0
end

local function adjustDojoCondition(stats, amount)
	if context.AdjustDojoCondition then
		return context.AdjustDojoCondition(stats, amount)
	end
end


local TEN_SHADOWS_SHIKIGAMI = {
	"Divine Dogs",
	"Nue",
	"Toad",
	"Great Serpent",
	"Max Elephant",
	"Rabbit Escape",
	"Round Deer",
	"Piercing Ox",
	"Tiger Funeral",
	"Mahoraga",
}

local function hasTechniqueText(stats, fragment)
	local technique = string.lower(tostring(stats and stats.CursedTechnique or stats and stats.InnateTechnique or ""))
	return string.find(technique, string.lower(fragment), 1, true) ~= nil
end

local function progressTechniqueAllies(stats)
	if hasTechniqueText(stats, "cursed spirit manipulation") then
		local gain = math.random(1, 2)
		stats.StoredCurses = math.clamp((tonumber(stats.StoredCurses) or 0) + gain, 0, 25)
		stats.StoredCursePower = math.clamp((tonumber(stats.StoredCursePower) or 0) + math.random(10, 28) * gain, 0, 500)
		return "\n<font color='#9b6dff'><b>[ CSM ]</b></font> You bound <b>" .. tostring(gain) .. "</b> curse" .. (gain == 1 and "" or "s") .. " for later combat. Stored curses: <b>" .. tostring(stats.StoredCurses) .. "</b>."
	elseif hasTechniqueText(stats, "ten shadows") then
		stats.TamedShikigamiNames = typeof(stats.TamedShikigamiNames) == "table" and stats.TamedShikigamiNames or {}
		local current = math.clamp(tonumber(stats.TamedShikigami) or #stats.TamedShikigamiNames, 0, #TEN_SHADOWS_SHIKIGAMI)
		if current >= #TEN_SHADOWS_SHIKIGAMI then
			return "\n<font color='#6d8cff'><b>[ TEN SHADOWS ]</b></font> Every shikigami is already tamed."
		end
		local chance = math.clamp(30 + math.floor((tonumber(stats.TechniqueMastery) or 0) / 2), 30, 88)
		if math.random(1, 100) <= chance then
			current += 1
			local name = TEN_SHADOWS_SHIKIGAMI[current]
			stats.TamedShikigami = current
			table.insert(stats.TamedShikigamiNames, name)
			return "\n<font color='#6d8cff'><b>[ TEN SHADOWS ]</b></font> You defeated and tamed <b>" .. name .. "</b>. Tamed shikigami: <b>" .. tostring(current) .. "/" .. tostring(#TEN_SHADOWS_SHIKIGAMI) .. "</b>."
		end
		return "\n<font color='#6d8cff'><b>[ TEN SHADOWS ]</b></font> You challenged a shikigami, but it resisted your control."
	end
	return ""
end

local ASSISTANT_NAMES = {
	"Akari Mizuno",
	"Ren Kisaragi",
	"Mika Hoshino",
	"Toma Inoue",
	"Yui Fushida",
	"Kaito Nanase",
}

local function rollAssistantName()
	return ASSISTANT_NAMES[math.random(1, #ASSISTANT_NAMES)]
end

local function makeMinigameToken(player)
	return tostring(player.UserId) .. ":" .. tostring(os.clock()) .. ":" .. tostring(math.random(100000, 999999))
end

local function getStartMinigameRemote()
	return ReplicatedStorage:FindFirstChild("StartMinigame")
end

local function beginBlackFlashMinigame(player, stats)
	local remote = getStartMinigameRemote()
	if not remote or not remote:IsA("RemoteEvent") then
		return false
	end

	local token = makeMinigameToken(player)
	local target = math.random(42, 72) / 100
	local duration = 1.45
	local expiresAt = os.clock() + 8

	minigameSessions[player.UserId] = {
		Token = token,
		Type = "BlackFlashTiming",
		StartedAt = os.clock(),
		ExpiresAt = expiresAt,
		Target = target,
		Duration = duration,
	}

	remote:FireClient(player, {
		Token = token,
		Type = "BlackFlashTiming",
		Title = "Black Flash Training",
		Body = "Stop the strike as the cursed energy crosses the impact point.",
		Target = target,
		Duration = duration,
		ExpiresAt = expiresAt,
	})

	fireLifeUpdate(player, stats, "<font color='#b27aff'><b>[ MINIGAME ]</b></font> Black Flash timing started. Hit the impact window to finish the training.")
	return true
end

local BLACKJACK_WAGER = 100
local BLACKJACK_RANKS = { "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K" }

local function drawBlackjackCard()
	return BLACKJACK_RANKS[math.random(1, #BLACKJACK_RANKS)]
end

local function blackjackCardValue(card)
	if card == "A" then return 11 end
	if card == "J" or card == "Q" or card == "K" then return 10 end
	return tonumber(card) or 0
end

local function blackjackTotal(cards)
	local total = 0
	local aces = 0
	for _, card in ipairs(cards or {}) do
		if card == "A" then aces += 1 end
		total += blackjackCardValue(card)
	end
	while total > 21 and aces > 0 do
		total -= 10
		aces -= 1
	end
	return total
end

local function blackjackCardsText(cards)
	return table.concat(cards or {}, "  ")
end

local function getBlackjackRemote()
	return getStartMinigameRemote()
end

local function sendBlackjackPayload(player, session, status, done, revealDealer)
	local remote = getBlackjackRemote()
	if not remote or not remote:IsA("RemoteEvent") then
		return false
	end
	local dealerCards = session.DealerCards or {}
	local dealerText = revealDealer and (blackjackCardsText(dealerCards) .. "  (" .. tostring(blackjackTotal(dealerCards)) .. ")") or (tostring(dealerCards[1] or "?") .. "  ?")
	local playerCards = session.PlayerCards or {}
	remote:FireClient(player, {
		Type = "Blackjack",
		Token = session.Token,
		Wager = session.Wager or BLACKJACK_WAGER,
		PlayerText = blackjackCardsText(playerCards) .. "  (" .. tostring(blackjackTotal(playerCards)) .. ")",
		DealerText = dealerText,
		Status = status,
		Done = done == true,
	})
	return true
end

local function finishBlackjack(player, stats, session, outcome, payout, status)
	minigameSessions[player.UserId] = nil
	payout = tonumber(payout) or 0
	if payout > 0 then
		stats.Money = math.max(0, (tonumber(stats.Money) or 0) + payout)
	end
	local net = payout - (tonumber(session.Wager) or BLACKJACK_WAGER)
	stats.BlackjackHands = (tonumber(stats.BlackjackHands) or 0) + 1
	if outcome == "win" or outcome == "blackjack" then
		stats.BlackjackWins = (tonumber(stats.BlackjackWins) or 0) + 1
		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) + math.random(2, 6), 0, 100)
	elseif outcome == "loss" or outcome == "bust" or outcome == "forfeit" then
		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - math.random(1, 5), 0, 100)
	end

	local moneyText = net >= 0 and ("+$" .. tostring(net)) or ("-$" .. tostring(math.abs(net)))
	local logMessage = "<font color='#55c78a'><b>[ 21 CARD GAME ]</b></font> " .. tostring(status) .. " Net <b>" .. moneyText .. "</b>."
	sendBlackjackPayload(player, session, tostring(status) .. " Net " .. moneyText .. ".", true, true)
	fireLifeUpdate(player, stats, logMessage)
	saveStats(player, "blackjack minigame")
end

local function beginBlackjackMinigame(player, stats)
	local remote = getBlackjackRemote()
	if not remote or not remote:IsA("RemoteEvent") then
		return false
	end
	if (tonumber(stats.Money) or 0) < BLACKJACK_WAGER then
		return false, "You need at least $" .. tostring(BLACKJACK_WAGER) .. " to sit at the 21 Card Game table."
	end

	stats.Money = math.max(0, (tonumber(stats.Money) or 0) - BLACKJACK_WAGER)
	local token = makeMinigameToken(player)
	local session = {
		Token = token,
		Type = "Blackjack",
		StartedAt = os.clock(),
		ExpiresAt = os.clock() + 120,
		Wager = BLACKJACK_WAGER,
		PlayerCards = { drawBlackjackCard(), drawBlackjackCard() },
		DealerCards = { drawBlackjackCard(), drawBlackjackCard() },
	}
	minigameSessions[player.UserId] = session

	local playerTotal = blackjackTotal(session.PlayerCards)
	local dealerTotal = blackjackTotal(session.DealerCards)
	if playerTotal == 21 then
		local payout = dealerTotal == 21 and BLACKJACK_WAGER or math.floor(BLACKJACK_WAGER * 2.5)
		finishBlackjack(player, stats, session, dealerTotal == 21 and "push" or "blackjack", payout, dealerTotal == 21 and "Both hands opened on 21. Push." or "Natural blackjack.")
		return true
	end

	sendBlackjackPayload(player, session, "Wager placed. Hit or stand.", false, false)
	return true
end

local function resolveBlackjackMinigame(player, token, action)
	local stats = getStats(player)
	local session = minigameSessions[player.UserId]
	if not stats or not stats.Alive or not session then
		return
	end
	if tostring(session.Token) ~= tostring(token) or session.Type ~= "Blackjack" then
		return
	end
	if os.clock() > (tonumber(session.ExpiresAt) or 0) then
		finishBlackjack(player, stats, session, "forfeit", 0, "You left the table too long and forfeited the hand.")
		return
	end

	action = string.lower(tostring(action or ""))
	if action == "forfeit" then
		finishBlackjack(player, stats, session, "forfeit", 0, "You left the 21 Card Game table.")
		return
	elseif action == "hit" then
		table.insert(session.PlayerCards, drawBlackjackCard())
		local total = blackjackTotal(session.PlayerCards)
		if total > 21 then
			finishBlackjack(player, stats, session, "bust", 0, "You busted with " .. tostring(total) .. ".")
		else
			sendBlackjackPayload(player, session, "You drew a card. Hit or stand.", false, false)
		end
		return
	elseif action ~= "stand" then
		return
	end

	while blackjackTotal(session.DealerCards) < 17 do
		table.insert(session.DealerCards, drawBlackjackCard())
	end
	local playerTotal = blackjackTotal(session.PlayerCards)
	local dealerTotal = blackjackTotal(session.DealerCards)
	if dealerTotal > 21 then
		finishBlackjack(player, stats, session, "win", BLACKJACK_WAGER * 2, "Dealer busted at " .. tostring(dealerTotal) .. ".")
	elseif playerTotal > dealerTotal then
		finishBlackjack(player, stats, session, "win", BLACKJACK_WAGER * 2, "You beat the dealer, " .. tostring(playerTotal) .. " to " .. tostring(dealerTotal) .. ".")
	elseif playerTotal == dealerTotal then
		finishBlackjack(player, stats, session, "push", BLACKJACK_WAGER, "Push at " .. tostring(playerTotal) .. ".")
	else
		finishBlackjack(player, stats, session, "loss", 0, "Dealer won, " .. tostring(dealerTotal) .. " to " .. tostring(playerTotal) .. ".")
	end
end

local function makeRCTSequence(length)
	local sequence = {}
	for _ = 1, length do
		table.insert(sequence, math.random(1, 4))
	end
	return sequence
end

local function sequenceToText(sequence)
	local out = {}
	for _, value in ipairs(sequence or {}) do table.insert(out, tostring(value)) end
	return table.concat(out, ",")
end

local function beginRCTMemoryMinigame(player, stats)
	local remote = getStartMinigameRemote()
	if not remote or not remote:IsA("RemoteEvent") then return false end
	local token = makeMinigameToken(player)
	local length = (tonumber(stats.RCTProgress) or 0) >= 2 and 6 or 5
	local sequence = makeRCTSequence(length)
	minigameSessions[player.UserId] = {
		Token = token,
		Type = "RCTMemory",
		StartedAt = os.clock(),
		ExpiresAt = os.clock() + 90,
		Sequence = sequence,
	}
	remote:FireClient(player, { Type = "RCTMemory", Token = token, Sequence = sequence })
	fireLifeUpdate(player, stats, "<font color='#7fcfe0'><b>[ RCT ]</b></font> Reverse cursed technique memory drill started. Repeat the sequence exactly.")
	return true
end

local function resolveRCTMemoryMinigame(player, token, result)
	local stats = getStats(player)
	local session = minigameSessions[player.UserId]
	if not stats or not stats.Alive or not session then return end
	if tostring(session.Token) ~= tostring(token) or session.Type ~= "RCTMemory" then return end
	minigameSessions[player.UserId] = nil
	local expected = sequenceToText(session.Sequence)
	local submitted = tostring(result or "")
	if submitted == expected and os.clock() <= (tonumber(session.ExpiresAt) or 0) then
		stats.HasRCT = true
		stats.RCTMastery = math.clamp((tonumber(stats.RCTMastery) or 0) + math.random(18, 28), 0, 100)
		stats.RCTProgress = math.clamp((tonumber(stats.RCTProgress) or 0) + 3, 0, 10)
		stats.Health = math.clamp((tonumber(stats.Health) or 100) + math.random(8, 18), 0, 100)
		stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) - math.random(8, 16))
		fireMajorPopup(player, "RCT UNLOCKED", "You reversed cursed energy through your body.", "Reverse Cursed Technique", "RCT healing is now available in combat systems.")
		fireLifeUpdate(player, stats, "<font color='#7fcfe0'><b>[ RCT ]</b></font> You completed the memory drill and unlocked <b>Reverse Cursed Technique</b>. RCT Mastery increased.")
	else
		stats.RCTProgress = math.clamp((tonumber(stats.RCTProgress) or 0) + 1, 0, 10)
		stats.Health = math.clamp((tonumber(stats.Health) or 100) - math.random(4, 10), 0, 100)
		stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) - math.random(4, 10))
		fireLifeUpdate(player, stats, "<font color='#7fcfe0'><b>[ RCT ]</b></font> The sequence slipped. You gained RCT progress, but the failed reversal strained your body.")
	end
	if stats.Health <= 0 and not applyMiracleSave(stats, player) then stats.Alive = false end
	saveStats(player, "rct memory minigame")
end

local function beginCursedFingerHunt(player, stats)
	if stats.CursedFingerHuntBlockedThisAge == true then
		fireLifeUpdate(player, stats, "<font color='#d6455d'><b>[ CURSED FINGER ]</b></font> The trail is too unstable after your last failed hunt. Age up before hunting fingers again.")
		return false
	end
	local remote = getStartMinigameRemote()
	if not remote or not remote:IsA("RemoteEvent") then
		return false
	end
	local token = makeMinigameToken(player)
	minigameSessions[player.UserId] = {
		Token = token,
		Type = "CursedFingerHunt",
		StartedAt = os.clock(),
		ExpiresAt = os.clock() + 120,
		Goal = 5,
	}
	remote:FireClient(player, { Type = "CursedFingerHunt", Token = token, Size = 6, Goal = 5 })
	fireLifeUpdate(player, stats, "<font color='#d6455d'><b>[ CURSED FINGER ]</b></font> A sealed finger trail appeared. Collect the cursed traces before they vanish.")
	return true
end

local function resolveCursedFingerHunt(player, token, result)
	local stats = getStats(player)
	local session = minigameSessions[player.UserId]
	if not stats or not stats.Alive or not session then return end
	if tostring(session.Token) ~= tostring(token) or session.Type ~= "CursedFingerHunt" then return end
	minigameSessions[player.UserId] = nil
	local rawResult = tostring(result or "")
	local forcedCaughtValue = rawResult:match("^caught:(%-?%d+)")
	local forcedCaught = forcedCaughtValue ~= nil
	local collected = math.clamp(tonumber(forcedCaughtValue or rawResult) or 0, 0, tonumber(session.Goal) or 5)
	if os.clock() > (tonumber(session.ExpiresAt) or 0) then collected = math.max(0, collected - 2) end
	local goal = tonumber(session.Goal) or 5
	local caughtByCurse = forcedCaught or (collected < goal and math.random(1, 100) <= math.clamp(35 + ((goal - collected) * 12), 35, 85))
	if caughtByCurse and context.StartCombat then
		fireLifeUpdate(player, stats, "<font color='#d6455d'><b>[ CURSED FINGER ]</b></font> A curse caught your trail while you hunted fingers. Win the fight to keep the traces you found.")
		local pendingCollected = collected
		local started = context.StartCombat(player, "Cursed Finger Hunt", {
			Name = "Finger Trail Curse",
			Kind = "Curse Obstacle",
			Grade = pendingCollected >= 3 and "Grade 2" or "Grade 3",
			PowerScale = 0.72 + (pendingCollected * 0.04),
			ComboMin = 1,
			ComboMax = 2,
			OnFinish = function(_, _, winner, _, finishStats)
				if winner == "player" then
					finishStats.CursedFingers = math.clamp((tonumber(finishStats.CursedFingers) or 0) + pendingCollected, 0, 20)
					finishStats.CursedEnergy = math.max(0, (tonumber(finishStats.CursedEnergy) or 0) + pendingCollected * math.random(2, 4))
					finishStats.CursedResentment = math.clamp((tonumber(finishStats.CursedResentment) or 0) + pendingCollected, 0, 100)
					fireLifeUpdate(player, finishStats, "<font color='#d6455d'><b>[ CURSED FINGER ]</b></font> You defeated the curse and kept <b>" .. tostring(pendingCollected) .. "</b> finger trace" .. (pendingCollected == 1 and "" or "s") .. ".")
				else
					finishStats.CursedFingerHuntBlockedThisAge = true
					fireLifeUpdate(player, finishStats, "<font color='#d6455d'><b>[ CURSED FINGER ]</b></font> The curse scattered the trail. You cannot hunt fingers again until your next activity reset.")
				end
			end,
		})
		if started then
			saveStats(player, "cursed finger hunt combat")
			return
		end
	end
	stats.CursedFingers = math.clamp((tonumber(stats.CursedFingers) or 0) + collected, 0, 20)
	stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + collected * math.random(2, 4))
	stats.CursedResentment = math.clamp((tonumber(stats.CursedResentment) or 0) + collected, 0, 100)
	local logMessage = "<font color='#d6455d'><b>[ CURSED FINGER ]</b></font> You collected <b>" .. tostring(collected) .. "</b> cursed finger trace" .. (collected == 1 and "" or "s") .. ". Total fingers: <b>" .. tostring(stats.CursedFingers) .. "/20</b>."
	if (tonumber(stats.CursedFingers) or 0) >= 20 then
		logMessage ..= "\nYou have enough fingers to either consume them or seek a vessel."
	end
	fireLifeUpdate(player, stats, logMessage)
	saveStats(player, "cursed finger hunt")
end

local function ownsActivityAsset(stats, assetId)
	for _, asset in ipairs(stats and stats.Assets or {}) do
		if asset and asset.Id == assetId then
			return true
		end
	end
	return false
end

local function beginHeirloomMinigame(player, stats)
	local remote = getStartMinigameRemote()
	if not remote or not remote:IsA("RemoteEvent") then
		return false
	end
	local token = makeMinigameToken(player)
	minigameSessions[player.UserId] = {
		Token = token,
		Type = "Heirloom",
		StartedAt = os.clock(),
		ExpiresAt = os.clock() + 90,
		Target = math.random(1, 9),
	}
	remote:FireClient(player, {
		Type = "Heirloom",
		Token = token,
		Target = minigameSessions[player.UserId].Target,
		Guesses = 3,
	})
	fireLifeUpdate(player, stats, "<font color='#d2a45f'><b>[ HEIRLOOM ]</b></font> You started searching old family storage. Pick carefully.")
	return true
end

local function resolveHeirloomMinigame(player, token, result)
	local stats = getStats(player)
	local session = minigameSessions[player.UserId]
	if not stats or not stats.Alive or not session then
		return
	end
	if tostring(session.Token) ~= tostring(token) or session.Type ~= "Heirloom" then
		return
	end
	minigameSessions[player.UserId] = nil
	result = string.lower(tostring(result or "miss"))
	local logMessage
	if result == "success" and os.clock() <= (tonumber(session.ExpiresAt) or 0) then
		stats.HeirloomsFound = (tonumber(stats.HeirloomsFound) or 0) + 1
		stats.Assets = stats.Assets or {}
		if not ownsActivityAsset(stats, "family_scroll") then
			local asset = BitKaisenAssets.GetAssetById("family_scroll")
			if asset then
				table.insert(stats.Assets, BitKaisenAssets.MakeOwnedAsset(asset))
			end
			logMessage = "<font color='#d2a45f'><b>[ HEIRLOOM ]</b></font> You found an <b>Inherited Family Scroll</b> tucked behind old storage boxes. It was added to Assets."
		else
			local cash = math.random(180, 420)
			stats.Money = math.max(0, (tonumber(stats.Money) or 0) + cash)
			stats.Smarts = math.clamp((tonumber(stats.Smarts) or 0) + math.random(2, 5), 0, 100)
			stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + math.random(2, 5))
			logMessage = "<font color='#d2a45f'><b>[ HEIRLOOM ]</b></font> You found old family keepsakes and sold the duplicates. Money <b>+$" .. tostring(cash) .. "</b>."
		end
		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) + math.random(2, 6), 0, 100)
	else
		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - math.random(1, 3), 0, 100)
		stats.Smarts = math.clamp((tonumber(stats.Smarts) or 0) + 1, 0, 100)
		logMessage = "<font color='#d2a45f'><b>[ HEIRLOOM ]</b></font> You searched the old boxes but only found dust, receipts, and a little family history."
	end
	fireLifeUpdate(player, stats, logMessage)
	saveStats(player, "heirloom minigame")
end

local function burglarySameCell(a, b)
	return a and b and tonumber(a.X) == tonumber(b.X) and tonumber(a.Y) == tonumber(b.Y)
end

local function burglaryCellKey(cell)
	return tostring(cell.X) .. ":" .. tostring(cell.Y)
end

local function burglaryHasGuard(guards, cell)
	for _, guard in ipairs(guards or {}) do
		if burglarySameCell(guard, cell) then
			return true
		end
	end
	return false
end

local function burglaryCanReach(size, startCell, goalCell, guards)
	if burglaryHasGuard(guards, startCell) or burglaryHasGuard(guards, goalCell) then
		return false
	end
	local queue = { startCell }
	local visited = { [burglaryCellKey(startCell)] = true }
	local head = 1
	local directions = {
		{ X = 1, Y = 0 },
		{ X = -1, Y = 0 },
		{ X = 0, Y = 1 },
		{ X = 0, Y = -1 },
	}
	while head <= #queue do
		local cell = queue[head]
		head += 1
		if burglarySameCell(cell, goalCell) then
			return true
		end
		for _, direction in ipairs(directions) do
			local nextCell = { X = cell.X + direction.X, Y = cell.Y + direction.Y }
			local nextKey = burglaryCellKey(nextCell)
			if nextCell.X >= 1 and nextCell.X <= size and nextCell.Y >= 1 and nextCell.Y <= size and not visited[nextKey] and not burglaryHasGuard(guards, nextCell) then
				visited[nextKey] = true
				table.insert(queue, nextCell)
			end
		end
	end
	return false
end

local function makeBurglaryBoard(includeExtraGuard)
	local size = 5
	local startCell = { X = 1, Y = size }
	local exitCell = { X = size, Y = 1 }
	local guards = {
		{ X = 2, Y = 2 },
		{ X = 4, Y = 3 },
		{ X = 3, Y = 5 },
	}
	if includeExtraGuard then
		table.insert(guards, { X = 5, Y = 4 })
	end
	local candidates = {}
	for y = 2, 4 do
		for x = 2, 4 do
			local candidate = { X = x, Y = y }
			if not burglarySameCell(candidate, startCell) and not burglarySameCell(candidate, exitCell) and not burglaryHasGuard(guards, candidate) and burglaryCanReach(size, startCell, candidate, guards) and burglaryCanReach(size, candidate, exitCell, guards) then
				table.insert(candidates, candidate)
			end
		end
	end
	local lootCell = #candidates > 0 and candidates[math.random(1, #candidates)] or { X = 3, Y = 3 }
	return {
		Size = size,
		Loot = lootCell,
		Exit = exitCell,
		Guards = guards,
	}
end

local function beginBurglaryMinigame(player, stats)
	local remote = getStartMinigameRemote()
	if not remote or not remote:IsA("RemoteEvent") then
		return false
	end
	local token = makeMinigameToken(player)
	local reward = math.random(220, 720) + math.floor((tonumber(stats.Smarts) or 0) * 3)
	local session = {
		Token = token,
		Type = "Burglary",
		StartedAt = os.clock(),
		ExpiresAt = os.clock() + 120,
		Reward = reward,
	}
	minigameSessions[player.UserId] = session
	local board = makeBurglaryBoard(false)
	remote:FireClient(player, {
		Type = "Burglary",
		Token = token,
		Size = board.Size,
		Loot = board.Loot,
		Exit = board.Exit,
		Guards = board.Guards,
	})
	fireLifeUpdate(player, stats, "<font color='#c28a4d'><b>[ BURGLARY ]</b></font> Burglary started. Grab the loot and reach the exit without touching a guard.")
	return true
end

local function beginDojoRaidDefenseMinigame(player, stats)
	local remote = getStartMinigameRemote()
	if not remote or not remote:IsA("RemoteEvent") then
		return false
	end
	local token = makeMinigameToken(player)
	local variant = chooseDojoRaidVariant(stats)
	local threat = math.clamp(35 + math.floor((tonumber(stats.DojoRaidRisk) or 0) * 0.5) + math.random(0, 20) + (tonumber(variant.ThreatBonus) or 0), 35, 99)
	stats.LastDojoRaidType = tostring(variant.Id)
	stats.LastDojoRaidOutcome = "In Progress"
	minigameSessions[player.UserId] = {
		Token = token,
		Type = "DojoRaidDefense",
		StartedAt = os.clock(),
		ExpiresAt = os.clock() + 120,
		Threat = threat,
		RaidVariant = variant.Id,
	}
	local board = makeBurglaryBoard(threat >= 80)
	remote:FireClient(player, {
		Type = "Burglary",
		Token = token,
		Size = board.Size,
		Loot = board.Loot,
		Exit = board.Exit,
		Guards = board.Guards,
	})
	fireLifeUpdate(player, stats, "<font color='#e25565'><b>[ " .. tostring(variant.Title) .. " ]</b></font> " .. tostring(variant.Lead) .. " Find the weak point, secure the exit, and prevent collapse damage. Threat <b>" .. tostring(threat) .. "</b>.")
	return true
end

local function resolveDojoRaidDefenseMinigame(player, token, result)
	local stats = getStats(player)
	local session = minigameSessions[player.UserId]
	if not stats or not stats.Alive or not session then return end
	if tostring(session.Token) ~= tostring(token) or session.Type ~= "DojoRaidDefense" then return end
	minigameSessions[player.UserId] = nil
	result = string.lower(tostring(result or "caught"))
	local variant = getDojoRaidVariantById(session.RaidVariant)
	local logMessage
	if result == "success" and os.clock() <= (tonumber(session.ExpiresAt) or 0) then
		local legacyGain = math.random(4, 9)
		local protectionGain = math.random(1, 3)
		stats.DojoRaidsDefended = math.max(0, tonumber(stats.DojoRaidsDefended) or 0) + 1
		stats.LastDojoRaidOutcome = "Defended: " .. tostring(variant.Id)
		stats.DojoRaidRisk = math.clamp((tonumber(stats.DojoRaidRisk) or 0) - math.random(14, 28), 0, 100)
		stats.DojoLegacy = math.clamp((tonumber(stats.DojoLegacy) or 0) + legacyGain, 0, 100)
		stats.DojoProtectionBonus = math.clamp((tonumber(stats.DojoProtectionBonus) or 0) + protectionGain, 0, 35)
		stats.DojoReputation = math.max(0, (tonumber(stats.DojoReputation) or 0) + math.random(5, 12))
		stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) + math.random(2, 7))
		stats.ClanPoliticalPower = math.clamp((tonumber(stats.ClanPoliticalPower) or 0) + math.random(1, 4), 0, 100)
		logMessage = "<font color='#55c78a'><b>[ DOJO RAID DEFENDED ]</b></font> " .. tostring(variant.Success) .. " Dojo Legacy <b>+" .. tostring(legacyGain) .. "</b>, Protection <b>+" .. tostring(protectionGain) .. "</b>, raid risk reduced."
	else
		local damage = math.random(8, 16) + (tonumber(variant.ConditionDamage) or 12)
		local legacyLoss = math.random(2, 6) + (tonumber(variant.LegacyLoss) or 4)
		local repLoss = math.random(2, 6) + (tonumber(variant.ReputationLoss) or 4)
		local riskGain = math.random(4, 10) + (tonumber(variant.RiskFail) or 8)
		stats.DojoRaidsFailed = math.max(0, tonumber(stats.DojoRaidsFailed) or 0) + 1
		stats.DojoRaidDamageTaken = math.max(0, tonumber(stats.DojoRaidDamageTaken) or 0) + damage
		stats.LastDojoRaidOutcome = "Failed: " .. tostring(variant.Id)
		stats.DojoRaidRisk = math.clamp((tonumber(stats.DojoRaidRisk) or 0) + riskGain, 0, 100)
		stats.DojoLegacy = math.clamp((tonumber(stats.DojoLegacy) or 0) - legacyLoss, 0, 100)
		stats.DojoReputation = math.max(0, (tonumber(stats.DojoReputation) or 0) - repLoss)
		stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) - (tonumber(variant.ClanLoss) or math.random(1, 4)))
		stats.DojoCondition = math.clamp((tonumber(stats.DojoCondition) or 100) - damage, 0, 100)
		stats.DojoProtectionBonus = math.clamp((tonumber(stats.DojoProtectionBonus) or 0) - (tonumber(variant.ProtectionDamage) or 1), 0, 35)
		stats.Health = math.clamp((tonumber(stats.Health) or 100) - math.random(3, 12), 0, 100)
		if variant.StudentInjury then
			stats.DojoRaidStudentsInjured = math.max(0, tonumber(stats.DojoRaidStudentsInjured) or 0) + tonumber(variant.StudentInjury)
		end
		if variant.SupplyLoss then
			stats.DojoRaidSuppliesLost = math.max(0, tonumber(stats.DojoRaidSuppliesLost) or 0) + tonumber(variant.SupplyLoss)
		end
		if variant.MoneyLoss then
			local loss = math.min(tonumber(stats.Money) or 0, tonumber(variant.MoneyLoss) or 0)
			stats.Money = math.max(0, (tonumber(stats.Money) or 0) - loss)
		end
		if variant.WantedGain then
			stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + tonumber(variant.WantedGain), 0, 100)
		end
		if variant.FearGain then
			stats.Fear = math.clamp((tonumber(stats.Fear) or 0) + tonumber(variant.FearGain), 0, 100)
		end
		stats.DojoRecoveryDebt = math.max(0, tonumber(stats.DojoRecoveryDebt) or 0) + math.floor(damage * 85)
		logMessage = "<font color='#e25565'><b>[ DOJO RAID DAMAGE ]</b></font> " .. tostring(variant.Failure) .. " Dojo condition <b>-" .. tostring(damage) .. "</b>, recovery debt <b>+$" .. tostring(math.floor(damage * 85)) .. "</b>, raid risk rose."
		if (tonumber(stats.DojoCondition) or 100) <= 0 then
			stats.DojoRank = "Collapsed Dojo"
			stats.DojoRecoveryDebt = math.max(tonumber(stats.DojoRecoveryDebt) or 0, 7500)
			logMessage ..= "\nYour dojo collapsed under the raid pressure and will need rebuilding."
		end
	end
	fireLifeUpdate(player, stats, logMessage)
	saveStats(player, "dojo raid defense")
end

local function resolveBurglaryMinigame(player, token, result)
	local stats = getStats(player)
	local session = minigameSessions[player.UserId]
	if not stats or not stats.Alive or not session then
		return
	end
	if tostring(session.Token) ~= tostring(token) or session.Type ~= "Burglary" then
		return
	end
	minigameSessions[player.UserId] = nil
	result = string.lower(tostring(result or "caught"))
	local logMessage
	if result == "fled" then
		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - 1, 0, 100)
		logMessage = "<font color='#c28a4d'><b>[ BURGLARY ]</b></font> You abandoned the job before taking anything. No loot, no fine."
	elseif result == "success" and os.clock() <= (tonumber(session.ExpiresAt) or 0) then
		local reward = tonumber(session.Reward) or math.random(200, 500)
		stats.Money = math.max(0, (tonumber(stats.Money) or 0) + reward)
		stats.Smarts = math.clamp((tonumber(stats.Smarts) or 0) + math.random(1, 3), 0, 100)
		stats.BurglariesCompleted = (tonumber(stats.BurglariesCompleted) or 0) + 1
		stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + math.random(1, 2), 0, 100)
		logMessage = "<font color='#c28a4d'><b>[ BURGLARY ]</b></font> You escaped with stolen valuables. Money <b>+$" .. tostring(reward) .. "</b>. Wanted Level rose slightly."
	else
		local fine = math.random(90, 220)
		stats.Money = math.max(0, (tonumber(stats.Money) or 0) - fine)
		stats.Health = math.clamp((tonumber(stats.Health) or 100) - math.random(4, 12), 0, 100)
		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - math.random(3, 8), 0, 100)
		stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + math.random(3, 6), 0, 100)
		stats.Reputation = math.clamp((tonumber(stats.Reputation) or 0) - math.random(2, 5), -100, 100)
		logMessage = "<font color='#c28a4d'><b>[ BURGLARY ]</b></font> You were caught during the job. Money <b>-$" .. tostring(fine) .. "</b>, and your Wanted Level increased."
	end
	if stats.Health <= 0 and not applyMiracleSave(stats, player) then
		stats.Alive = false
		logMessage ..= "\nYou did not survive the escape."
	end
	fireLifeUpdate(player, stats, logMessage)
	saveStats(player, "burglary minigame")
end

local function resolveBlackFlashMinigame(player, token, accuracy)
	local stats = getStats(player)
	local session = minigameSessions[player.UserId]

	if not stats or not stats.Alive or not session then
		return
	end
	if tostring(session.Token) ~= tostring(token) or session.Type ~= "BlackFlashTiming" then
		return
	end

	minigameSessions[player.UserId] = nil

	local now = os.clock()
	if now > (tonumber(session.ExpiresAt) or 0) then
		stats.Health = math.clamp((stats.Health or 100) - math.random(6, 12), 0, 100)
		fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ MINIGAME ]</b></font> Your Black Flash timing expired. Health took a small hit from the failed drill.")
		saveStats(player, "expired minigame")
		return
	end

	accuracy = math.clamp(tonumber(accuracy) or 0, 0, 1)
	local quality = "Miss"
	local ceGain = math.random(4, 9)
	local masteryGain = 0
	local repGain = 0
	local healthCost = math.random(8, 18)
	local happinessGain = 0
	local popup = false

	if accuracy >= 0.94 then
		quality = "Black Flash"
		ceGain = math.random(34, 56)
		masteryGain = math.random(5, 9)
		repGain = math.random(12, 22)
		healthCost = 0
		happinessGain = 12
		popup = true
	elseif accuracy >= 0.78 then
		quality = "Perfect Impact"
		ceGain = math.random(18, 30)
		masteryGain = math.random(3, 6)
		repGain = math.random(4, 9)
		healthCost = math.random(0, 5)
		happinessGain = 5
	elseif accuracy >= 0.52 then
		quality = "Clean Hit"
		ceGain = math.random(9, 17)
		masteryGain = math.random(1, 3)
		healthCost = math.random(3, 9)
	else
		quality = "Mistimed"
	end

	stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + ceGain)
	stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + masteryGain, 0, 100)
	stats.Reputation = math.max(0, (tonumber(stats.Reputation) or 0) + repGain)
	stats.Health = math.clamp((tonumber(stats.Health) or 100) - healthCost, 0, 100)
	stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) + happinessGain, 0, 100)

	local logMessage = "<font color='#b27aff'><b>[ MINIGAME ]</b></font> Black Flash Training: <b>" .. quality .. "</b>. CE <b>+" .. tostring(ceGain) .. "</b>"
	if masteryGain > 0 then logMessage ..= " • Mastery <b>+" .. tostring(masteryGain) .. "%</b>" end
	if repGain > 0 then logMessage ..= " • Reputation <b>+" .. tostring(repGain) .. "</b>" end
	if healthCost > 0 then logMessage ..= " • Health <b>-" .. tostring(healthCost) .. "</b>" end
	logMessage ..= "."
	if masteryGain > 0 then
		logMessage ..= BitKaisenTechniqueEvolution.AddPressure(stats, math.max(1, math.floor(masteryGain * (accuracy >= 0.94 and 2 or 1))), "Black Flash timing")
	end

	if stats.Health <= 0 and not applyMiracleSave(stats, player) then
		stats.Alive = false
		logMessage ..= "\nYour body could not handle the failed timing drill."
	end

	logMessage = maybeTeacherRecommendation(player, stats, logMessage)
	logMessage = checkPromotionAndPopup(player, stats, logMessage)

	if popup then
		fireMajorPopup(player, "BLACK FLASH", "For one instant, cursed energy and impact became the same moment.", "Black Flash", "Your body remembered the timing.")
	end

	fireLifeUpdate(player, stats, logMessage)
	saveStats(player, "black flash minigame")
end

local IDLE_TRAIT_POOL = { "calm", "disciplined", "patient", "competitive", "protective", "curious" }

local function hasTraitId(stats, traitId)
	for _, trait in ipairs(stats and stats.Traits or {}) do
		local id = typeof(trait) == "table" and trait.Id or trait
		if tostring(id) == tostring(traitId) then
			return true
		end
	end
	return false
end

local function getTechniqueBranchName(stats, nextStage)
	local technique = string.lower(tostring(stats and stats.CursedTechnique or stats and stats.InnateTechnique or ""))
	local stage = tostring(nextStage or "Refined Form")
	if string.find(technique, "shrine", 1, true) then
		if stage == "Refined Form" then return "Heian Shrine" end
		if stage == "Extension Technique" then return "Ten Shadows Shrine" end
		if stage == "Maximum Technique" or stage == "Domain Seed" then return "World Cutting Shrine" end
	elseif string.find(technique, "divergent", 1, true) then
		if stage == "Refined Form" then return "Soul Striking" end
		if stage == "Extension Technique" then return "Safety Shrine" end
		if stage == "Maximum Technique" then return "Master of Black Sparks" end
		if stage == "Domain Seed" then return "Blood Brother" end
	elseif string.find(technique, "idle", 1, true) or string.find(technique, "transfiguration", 1, true) then
		if stage == "Refined Form" then return "Trait Sculpting" end
		if stage == "Extension Technique" then return "Soul Rewrite" end
		if stage == "Maximum Technique" or stage == "Domain Seed" then return "Perfect Idle Transfiguration" end
	end
	return stage
end

local STUDENT_GRADE_ORDER = {
	"Non-Sorcerer",
	"Grade 4",
	"Semi-Grade 3",
	"Grade 3",
	"Semi-Grade 2",
	"Grade 2",
	"Semi-Grade 1",
	"Grade 1",
	"Special Grade"
}

local STUDENT_GRADE_INDEX = {}
for index, grade in ipairs(STUDENT_GRADE_ORDER) do
	STUDENT_GRADE_INDEX[grade] = index
end

local function ownsAssetById(stats, assetId)
	for _, asset in ipairs(stats and stats.Assets or {}) do
		if typeof(asset) == "table" then
			if asset.Id == assetId or asset.BaseId == assetId then
				return true
			end
		elseif asset == assetId then
			return true
		end
	end
	return false
end

local function getTotalMonths(stats)
	local age = tonumber(stats and stats.Age) or 0
	local month = math.clamp(tonumber(stats and stats.CurrentMonth) or 1, 1, 12)
	return (age * 12) + (month - 1)
end

local function getStudentPatrolUsedThisWindow(stats)
	local window = math.floor(getTotalMonths(stats) / 6)
	if tonumber(stats.StudentPatrolWindow) ~= window then
		stats.StudentPatrolWindow = window
		stats.StudentPatrolUsed = 0
	end
	return tonumber(stats.StudentPatrolUsed) or 0
end


----------------------------------------------------------------
-- ERA ACTIVITY FILTERS
----------------------------------------------------------------
-- Heian lives should not see modern school / hospital / official Jujutsu High
-- activities. ProcessActivity also blocks these actionIds server-side so a
-- client cannot still fire the remote manually.

local HEIAN_BLOCKED_ACTIVITY_IDS = {
	apply_jujutsu_high = true,
	basic_school_study = true,
	school_attend_class = true,
	school_study_exams = true,
	school_join_club = true,
	school_skip = true,
	doctor = true,

	join_other_dojo = true,
	train_at_joined_dojo = true,
	dojo_assignment = true,
	leave_joined_dojo = true,

	patrol_city = true,
	mission_review = true,
}

local function getCurrentEra(stats)
	if typeof(stats) ~= "table" then
		return "Modern Era"
	end

	local birthPath = typeof(stats.BirthPath) == "table" and stats.BirthPath or nil

	return tostring(
		stats.CurrentEra
			or stats.Era
			or stats.BirthEra
			or (birthPath and birthPath.Era)
			or "Modern Era"
	)
end

local function isHeianEra(stats)
	return getCurrentEra(stats) == "Heian Era"
end

local function getEraBlockedActivityReason(stats, activityId)
	activityId = tostring(activityId or "")

	if isHeianEra(stats) and HEIAN_BLOCKED_ACTIVITY_IDS[activityId] == true then
		return "That modern activity does not exist in the Heian Era. Sorcerers in this age rely on clans, temples, masters, private training, reputation, and cursed commissions."
	end

	return nil
end

local function hasBrainTransplant(stats)
	local technique = tostring(stats and stats.CursedTechnique or "None")
	local innate = tostring(stats and stats.InnateTechnique or "None")
	return technique == "Brain Transplant" or innate == "Brain Transplant"
end

local function shouldShowActivityForPlayer(player, stats, activity)
	if not activity or not activity.Id then
		return false
	end

	if not isDev(player) and string.match(tostring(activity.Id), "^dev_") then
		return false
	end

	if activity.Id == "create_death_painting" and not (tostring(stats and stats.Clan or "") == "Kenjaku Clan" and hasBrainTransplant(stats)) then
		return false
	end

	if activity.Id == "cast_culling_games" and not (tostring(stats and stats.Clan or "") == "Kenjaku Clan" and hasBrainTransplant(stats)) then
		return false
	end

	if getEraBlockedActivityReason(stats, activity.Id) then
		return false
	end

	return true
end


local JOINABLE_DOJOS = {
	{ Name = "Tokyo Shadow Dojo", Focus = "Balanced", Rank = "Local Dojo" },
	{ Name = "Kyoto Barrier Dojo", Focus = "Theory", Rank = "Recognized Dojo" },
	{ Name = "Sendai Combat Hall", Focus = "Combat", Rank = "Respected Dojo" },
	{ Name = "Osaka Cursed Tool School", Focus = "Discipline", Rank = "Recognized Dojo" },
	{ Name = "Nagoya Quiet Shrine Dojo", Focus = "Loyalty", Rank = "Local Dojo" },
	{ Name = "Fukuoka Exorcist Hall", Focus = "Combat", Rank = "Elite Dojo" },
}

local function ensureJoinedDojoState(stats)
	if not stats then
		return
	end

	if typeof(stats.JoinedDojo) ~= "table" then
		stats.JoinedDojo = nil
		stats.JoinedDojoName = stats.JoinedDojoName or nil
		stats.JoinedDojoFocus = stats.JoinedDojoFocus or nil
		stats.JoinedDojoRank = stats.JoinedDojoRank or nil
		stats.JoinedDojoTrust = math.clamp(tonumber(stats.JoinedDojoTrust) or 0, 0, 100)
		stats.JoinedDojoProgress = math.max(0, tonumber(stats.JoinedDojoProgress) or 0)
		stats.JoinedDojoAssignments = math.max(0, tonumber(stats.JoinedDojoAssignments) or 0)
		return
	end

	stats.JoinedDojo.Name = tostring(stats.JoinedDojo.Name or stats.JoinedDojoName or "Unknown Dojo")
	stats.JoinedDojo.Focus = tostring(stats.JoinedDojo.Focus or stats.JoinedDojoFocus or "Balanced")
	stats.JoinedDojo.Rank = tostring(stats.JoinedDojo.Rank or stats.JoinedDojoRank or "Local Dojo")
	stats.JoinedDojo.Trust = math.clamp(tonumber(stats.JoinedDojo.Trust) or tonumber(stats.JoinedDojoTrust) or 0, 0, 100)
	stats.JoinedDojo.Progress = math.max(0, tonumber(stats.JoinedDojo.Progress) or tonumber(stats.JoinedDojoProgress) or 0)
	stats.JoinedDojo.Assignments = math.max(0, tonumber(stats.JoinedDojo.Assignments) or tonumber(stats.JoinedDojoAssignments) or 0)

	stats.JoinedDojoName = stats.JoinedDojo.Name
	stats.JoinedDojoFocus = stats.JoinedDojo.Focus
	stats.JoinedDojoRank = stats.JoinedDojo.Rank
	stats.JoinedDojoTrust = stats.JoinedDojo.Trust
	stats.JoinedDojoProgress = stats.JoinedDojo.Progress
	stats.JoinedDojoAssignments = stats.JoinedDojo.Assignments
end

local function getJoinedDojo(stats)
	ensureJoinedDojoState(stats)
	if typeof(stats.JoinedDojo) == "table" then
		return stats.JoinedDojo
	end
	return nil
end

local function setJoinedDojo(stats, dojo)
	if not stats then
		return
	end

	stats.JoinedDojo = dojo
	if dojo then
		stats.JoinedDojoName = dojo.Name
		stats.JoinedDojoFocus = dojo.Focus
		stats.JoinedDojoRank = dojo.Rank
		stats.JoinedDojoTrust = dojo.Trust or 0
		stats.JoinedDojoProgress = dojo.Progress or 0
		stats.JoinedDojoAssignments = dojo.Assignments or 0
	else
		stats.JoinedDojoName = nil
		stats.JoinedDojoFocus = nil
		stats.JoinedDojoRank = nil
		stats.JoinedDojoTrust = 0
		stats.JoinedDojoProgress = 0
		stats.JoinedDojoAssignments = 0
	end
end

local function pickJoinableDojo(stats)
	local pool = JOINABLE_DOJOS
	local pick = pool[math.random(1, #pool)]
	local trust = math.random(8, 18)
	local progress = math.random(0, 6)

	if (tonumber(stats and stats.CursedEnergy) or 0) >= 100 then
		trust += 4
	end
	if (tonumber(stats and stats.TechniqueMastery) or 0) >= 25 then
		trust += 4
	end
	if tostring(stats and stats.Grade or "") ~= "Non-Sorcerer" then
		trust += 3
	end

	return {
		Name = pick.Name,
		Focus = pick.Focus,
		Rank = pick.Rank,
		Trust = math.clamp(trust, 0, 100),
		Progress = progress,
		Assignments = 0,
		JoinedAge = tonumber(stats and stats.Age) or 0,
	}
end

local function getDojoStudentList(stats)
	local list = {}
	for _, relationship in ipairs(stats and stats.Relationships or {}) do
		if relationship and relationship.Alive ~= false and (relationship.Role == "Student" or relationship.Role == "Ward") then
			table.insert(list, relationship)
		end
	end
	return list
end

local function getPotentialScore(student)
	local potential = tostring(student and student.DojoPotential or "Average")
	if potential == "Hidden" then return 6 end
	if potential == "Special" then return 6 end
	if potential == "Rare" then return 5 end
	if potential == "High" then return 4 end
	if potential == "Average" then return 3 end
	if potential == "Low" then return 2 end
	return 3
end

local function getGradeIndex(grade)
	return STUDENT_GRADE_INDEX[tostring(grade or "Non-Sorcerer")] or 1
end

local function getNextGrade(grade)
	local current = getGradeIndex(grade)
	return STUDENT_GRADE_ORDER[math.clamp(current + 1, 1, #STUDENT_GRADE_ORDER)]
end

local function getStudentPower(student)
	local gradePower = (getGradeIndex(student.Grade) - 1) * 20
	local ce = tonumber(student.CursedEnergy) or 0
	local mastery = tonumber(student.TechniqueMastery) or 0
	local potential = getPotentialScore(student) * 5
	local techniqueBonus = tostring(student.CursedTechnique or "None") ~= "None" and 18 or 0
	return gradePower + math.floor(ce * 0.55) + math.floor(mastery * 1.4) + potential + techniqueBonus
end

local function trainStudent(student, focus, intensity)
	intensity = tonumber(intensity) or 1
	local potential = getPotentialScore(student)
	local ceGain = math.random(2, 6) + math.floor(potential / 2) + math.floor(intensity)
	local masteryGain = math.random(0, 2) + math.floor(potential / 3)
	local progressGain = math.random(4, 10) + potential + math.floor(intensity * 2)

	if tostring(student.CursedTechnique or "None") == "None" then
		masteryGain = 0
		if math.random(1, 100) <= 3 + potential then
			student.CursedTechnique = "Unrefined Technique"
			masteryGain = 1
		end
	end

	if focus == "Combat" then
		ceGain += math.random(2, 5)
		progressGain += math.random(2, 5)
	elseif focus == "Theory" then
		masteryGain += math.random(1, 3)
	elseif focus == "Discipline" then
		progressGain += math.random(2, 4)
	elseif focus == "Loyalty" then
		student.Trust = math.clamp((tonumber(student.Trust) or 0) + math.random(1, 4), 0, 100)
		student.Bond = math.clamp((tonumber(student.Bond) or 0) + math.random(1, 4), 0, 100)
	end

	student.CursedEnergy = math.max(0, (tonumber(student.CursedEnergy) or 0) + ceGain)
	student.TechniqueMastery = math.clamp((tonumber(student.TechniqueMastery) or 0) + masteryGain, 0, 100)
	student.DojoProgress = math.max(0, (tonumber(student.DojoProgress) or 0) + progressGain)
	student.Respect = math.clamp((tonumber(student.Respect) or 0) + math.random(1, 4), 0, 100)

	local promoted = false
	local gradeIndex = getGradeIndex(student.Grade)
	local needed = 45 + (gradeIndex * 18)
	local power = getStudentPower(student)

	if gradeIndex < #STUDENT_GRADE_ORDER and student.DojoProgress >= needed and power >= needed then
		local promoteChance = math.clamp(20 + (potential * 8) + math.floor(power / 20), 10, 80)
		if math.random(1, 100) <= promoteChance then
			student.Grade = getNextGrade(student.Grade)
			student.DojoProgress = math.max(0, math.floor(student.DojoProgress * 0.25))
			promoted = true
		end
	end

	return {
		CEGain = ceGain,
		MasteryGain = masteryGain,
		ProgressGain = progressGain,
		Promoted = promoted,
	}
end

local function update16Gain(stats, minValue, maxValue, visibleStat)
	local amount = math.random(minValue, maxValue)
	if (tonumber(stats and stats.Age) or 0) < 16 then
		amount = math.floor(amount * 0.65 + 0.5)
	end
	if visibleStat == true then
		amount = math.floor(amount * 0.70 + 0.5)
	end
	if amount <= 0 then
		return 0
	end
	return math.max(1, amount)
end

local function processActivity(player, activityId)
	local stats = getStats(player)

	if not stats or not stats.Alive then
		return
	end

	ensureExtraStats(stats)

	if typeof(activityId) ~= "string" then
		return
	end

	local activity = BitKaisenActivities.GetActivityById(activityId)

	if not activity then
		fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ SYSTEM ]</b></font> Invalid activity.")
		return
	end

	local canDo, reason = BitKaisenActivities.CanDoActivity(stats, activity)

	if not canDo then
		fireLifeUpdate(player, stats, tostring(reason or "You cannot do this activity."))
		return
	end

	local eraBlockReason = getEraBlockedActivityReason(stats, activityId)
	if eraBlockReason then
		fireLifeUpdate(player, stats, eraBlockReason)
		return
	end

	if activityId ~= "dev_awaken" and stats.ActivitiesDoneThisAge >= 3 then
		fireLifeUpdate(player, stats, "You already did too many activities this year. Age up first.")
		return
	end

	local logMessage = ""

	if activityId == "dev_awaken" then
		if not isDev(player) then
			fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ SYSTEM ]</b></font> Invalid activity.")
			return
		end

		local technique = forceAwaken(player, stats, "A test command forced your cursed technique to awaken.")
		technique = tostring(technique or stats.CursedTechnique or "Unknown Technique")

		logMessage = "Your cursed technique awakened through testing. You awakened <b>" .. technique .. "</b>."
		fireLifeUpdate(player, stats, logMessage)
		saveStats(player, "dev awaken")
		return
	end

	local usedBlackFlashDrillToken = false
	if activityId == "black_flash_training" and (tonumber(stats.BlackFlashDrillTokens) or 0) > 0 then
		stats.BlackFlashDrillTokens = math.max(0, (tonumber(stats.BlackFlashDrillTokens) or 0) - 1)
		usedBlackFlashDrillToken = true
	else
		stats.ActivitiesDoneThisAge += 1
	end
	local traitBefore = captureTraitBuffSnapshot(stats)

	if activityId == "play_outside" then
		stats.Happiness = math.clamp((stats.Happiness or 100) + update16Gain(stats, 3, 8, true), 0, 100)
		stats.Health = math.clamp((stats.Health or 100) + update16Gain(stats, 0, 3, true), 0, 100)
		logMessage = tAct(player, "play_outside", nil, "You spent time playing outside and enjoying a normal childhood moment.")

	elseif activityId == "spend_time_family" then
		stats.Happiness = math.clamp((stats.Happiness or 100) + update16Gain(stats, 3, 9, true), 0, 100)
		logMessage = BitKaisenRelationships.HandleFamilyActivity(stats)

	elseif activityId == "watch_shadows" then
		stats.CursedEnergy += update16Gain(stats, 1, 4, false)
		stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(0, 3), 0, 100)
		logMessage = tAct(player, "watch_shadows", nil, "You watched the strange shapes that moved where no one else looked.")

	elseif activityId == "ask_about_curses" then
		stats.Smarts = math.clamp((stats.Smarts or 0) + update16Gain(stats, 2, 5, true), 0, 100)
		logMessage = tAct(player, "ask_about_curses", nil, "You asked questions about curses and the strange things around you.")

	elseif activityId == "basic_school_study" then
		stats.Smarts = math.clamp((stats.Smarts or 0) + update16Gain(stats, 3, 7, true), 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(0, 3), 0, 100)
		logMessage = tAct(player, "basic_school_study", nil, "You focused on schoolwork and improved your general knowledge.")

	elseif activityId == "school_attend_class" then
		stats.SchoolPerformance = math.clamp((tonumber(stats.SchoolPerformance) or 50) + math.random(3, 7), 0, 100)
		stats.SchoolAttendance = math.clamp((tonumber(stats.SchoolAttendance) or 100) + math.random(2, 5), 0, 100)
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(1, 3), 0, 100)
		logMessage = tAct(player, "school_attend_class", nil, "You attended class and paid attention. Your grades improved.")

	elseif activityId == "school_study_exams" then
		stats.SchoolPerformance = math.clamp((tonumber(stats.SchoolPerformance) or 50) + math.random(8, 15), 0, 100)
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(2, 5), 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(3, 8), 0, 100)
		logMessage = tAct(player, "school_study_exams", nil, "You crammed for exams. Your test scores jumped, but you felt drained.")

	elseif activityId == "school_join_club" then
		local clubOptions = { "Kendo Club", "Science Club", "Art Club", "Athletics Club", "Cooking Club", "Drama Club", "Student Council", "Library Committee" }
		local pick = clubOptions[math.random(1, #clubOptions)]
		stats.SchoolClub = pick
		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(3, 8), 0, 100)
		stats.SchoolAttendance = math.clamp((tonumber(stats.SchoolAttendance) or 100) + math.random(2, 4), 0, 100)
		stats.SchoolPerformance = math.clamp((tonumber(stats.SchoolPerformance) or 50) + math.random(1, 3), 0, 100)
		logMessage = tAct(player, "school_join_club", { club = pick }, "You joined " .. pick .. "! School feels more fun now.")

	elseif activityId == "school_skip" then
		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(3, 8), 0, 100)
		stats.SchoolAttendance = math.clamp((tonumber(stats.SchoolAttendance) or 100) - math.random(8, 15), 0, 100)
		stats.SchoolPerformance = math.clamp((tonumber(stats.SchoolPerformance) or 50) - math.random(3, 7), 0, 100)
		logMessage = tAct(player, "school_skip", nil, "You skipped school. It felt good, but your grades took a hit.")

	elseif activityId == "mentor_teach_class" then
		local xpGain = math.random(8, 16) + math.floor((tonumber(stats.Smarts) or 0) * 0.08)
		stats.MentorXP = math.max(0, (tonumber(stats.MentorXP) or 0) + xpGain)
		stats.Reputation = (tonumber(stats.Reputation) or 0) + math.random(1, 3)
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(0, 2), 0, 100)
		local pay = math.random(500, 1200)
		stats.Money = math.max(0, (tonumber(stats.Money) or 0) + pay)
		logMessage = tAct(player, "mentor_teach_class", { xp = xpGain, pay = pay }, "You taught a class on cursed energy fundamentals. Mentor XP <b>+" .. tostring(xpGain) .. "</b>, earned <b>$" .. tostring(pay) .. "</b>.")

	elseif activityId == "mentor_supervise_mission" then
		local xpGain = math.random(12, 25)
		local ceGain = math.random(3, 8)
		local damage = math.random(2, 8)
		stats.MentorXP = math.max(0, (tonumber(stats.MentorXP) or 0) + xpGain)
		stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + ceGain)
		stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
		stats.StudentsMentored = math.max(0, (tonumber(stats.StudentsMentored) or 0) + 1)
		stats.Reputation = (tonumber(stats.Reputation) or 0) + math.random(2, 5)
		logMessage = tAct(player, "mentor_supervise", { xp = xpGain, ce = ceGain, dmg = damage }, "You supervised students on a real mission. Mentor XP <b>+" .. tostring(xpGain) .. "</b>, CE <b>+" .. tostring(ceGain) .. "</b>, Health <b>-" .. tostring(damage) .. "</b>.")

	elseif activityId == "mentor_grade_students" then
		local xpGain = math.random(6, 12)
		stats.MentorXP = math.max(0, (tonumber(stats.MentorXP) or 0) + xpGain)
		stats.Recommendations = math.max(0, (tonumber(stats.Recommendations) or 0) + math.random(0, 1))
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(0, 1), 0, 100)
		logMessage = tAct(player, "mentor_grade", { xp = xpGain }, "You evaluated student progress and filed reports. Mentor XP <b>+" .. tostring(xpGain) .. "</b>.")

	elseif activityId == "mentor_prodigy" then
		local xpGain = math.random(18, 35)
		local ceGain = math.random(5, 12)
		local repGain = math.random(3, 8)
		stats.MentorXP = math.max(0, (tonumber(stats.MentorXP) or 0) + xpGain)
		stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + ceGain)
		stats.Reputation = (tonumber(stats.Reputation) or 0) + repGain
		stats.StudentsMentored = math.max(0, (tonumber(stats.StudentsMentored) or 0) + 1)
		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(2, 6), 0, 100)
		logMessage = tAct(player, "mentor_prodigy", { xp = xpGain, ce = ceGain, rep = repGain }, "You personally mentored a prodigious student. Mentor XP <b>+" .. tostring(xpGain) .. "</b>, CE <b>+" .. tostring(ceGain) .. "</b>, Reputation <b>+" .. tostring(repGain) .. "</b>.")

	elseif activityId == "train_ce" then
		local assetBonuses = BitKaisenAssets.GetPassiveBonuses(stats)
		local bonus = assetBonuses.CursedEnergyTrainingBonus or 0
		local prodigyMult = ownsTrainingProdigyPass(player) and 1.5 or 1
		local focusedMult = ownsFocusedTrainingPass(player) and 1.25 or 1
		local doubleMult = ownsDoubleTrainingPass(player) and 2 or 1
		local vipMult = ownsVIPPass(player) and 1.5 or 1
		local ceMult = prodigyMult * focusedMult * doubleMult * vipMult
		stats.CursedEnergy += math.floor((update16Gain(stats, 5, 14, false) + bonus) * ceMult)
		stats.Health = math.clamp((stats.Health or 100) - math.random(2, 8), 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(0, 4), 0, 100)

		if stats.ClanFounded then
			stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + 1)
		end

		if bonus > 0 then
			logMessage = tAct(player, "train_ce_bonus", nil, "You trained your cursed energy using the resources you own.")
		else
			logMessage = tAct(player, "train_ce", nil, "You trained your cursed energy.")
		end

	elseif activityId == "physical_conditioning" then
		stats.PhysicalConditioningThisAge = math.clamp(tonumber(stats.PhysicalConditioningThisAge) or 0, 0, 3)
		if stats.PhysicalConditioningThisAge >= 3 then
			fireLifeUpdate(player, stats, tAct(player, "physical_conditioning_limit", nil, "You have already completed 3 physical conditioning sessions this age. Age up before pushing your body again."))
			return false
		end
		local assetBonuses = BitKaisenAssets.GetPassiveBonuses(stats)
		local strengthBonus = tonumber(assetBonuses.StrengthTrainingBonus) or 0
		local passiveMult = 1 + ((tonumber(assetBonuses.StrengthPassiveGainPercent) or 0) / 100)
		local prodigyMult = ownsTrainingProdigyPass(player) and 1.5 or 1
		local doubleMult = ownsDoubleTrainingPass(player) and 2 or 1
		local vipMult = ownsVIPPass(player) and 1.5 or 1
		local gain = math.max(1, math.floor((update16Gain(stats, 5, 12, false) + strengthBonus) * passiveMult * prodigyMult * doubleMult * vipMult + 0.5))
		stats.PhysicalConditioningThisAge += 1
		stats.Strength = math.clamp((tonumber(stats.Strength) or 0) + gain, 0, 100)
		local speedGain = math.max(0, math.floor(gain * 0.5))
		local durabilityGain = math.max(0, math.floor(gain * 0.5))
		stats.Speed = math.clamp((tonumber(stats.Speed) or 0) + speedGain, 0, 100)
		stats.Durability = math.clamp((tonumber(stats.Durability) or 0) + durabilityGain, 0, 100)
		stats.Health = math.clamp((stats.Health or 100) - math.random(1, 5), 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(0, 3), 0, 100)
		logMessage = tAct(player, "physical_conditioning", { str = gain, spd = speedGain, dur = durabilityGain }, "You pushed your body through physical conditioning. Strength +" .. tostring(gain) .. ", Speed +" .. tostring(speedGain) .. ", Durability +" .. tostring(durabilityGain) .. ".")

	elseif activityId == "surgery" then
		stats.SurgeryThisAge = math.clamp(tonumber(stats.SurgeryThisAge) or 0, 0, 1)
		if stats.SurgeryThisAge >= 1 then
			fireLifeUpdate(player, stats, tAct(player, "surgery_limit", nil, "You already had cosmetic work done this age. Age up before going under the knife again."))
			return false
		end
		local surgeryCost = 3500
		if (tonumber(stats.Money) or 0) < surgeryCost then
			fireLifeUpdate(player, stats, tAct(player, "surgery_no_money", { cost = surgeryCost }, "Cosmetic surgery costs $" .. tostring(surgeryCost) .. "."))
			return false
		end
		stats.Money -= surgeryCost
		stats.SurgeryThisAge += 1
		local looksGain = math.random(4, 10)
		stats.Looks = math.clamp((tonumber(stats.Looks) or 50) + looksGain, 0, 100)
		stats.Health = math.clamp((stats.Health or 100) - math.random(1, 4), 0, 100)
		logMessage = tAct(player, "surgery_result", { gain = looksGain }, "You paid for cosmetic surgery. Looks +" .. tostring(looksGain) .. ".")

	elseif activityId == "create_death_painting" then
		if not (tostring(stats.Clan or "") == "Kenjaku Clan" and hasBrainTransplant(stats)) then
			fireLifeUpdate(player, stats, tAct(player, "death_painting_gate", nil, "Only Kenjaku Clan sorcerers with Brain Transplant can create Death Paintings."))
			return false
		end
		stats.DeathPaintings = typeof(stats.DeathPaintings) == "table" and stats.DeathPaintings or {}
		if #stats.DeathPaintings >= 5 then
			fireLifeUpdate(player, stats, tAct(player, "death_painting_limit", nil, "You have already created all 5 Death Paintings your body can sustain."))
			return false
		end
		local paintingCost = 250
		if (tonumber(stats.CursedEnergy) or 0) < paintingCost then
			fireLifeUpdate(player, stats, tAct(player, "death_painting_no_ce", { cost = paintingCost }, "Creating a Death Painting costs " .. tostring(paintingCost) .. " cursed energy."))
			return false
		end
		stats.CursedEnergy -= paintingCost
		local power = math.clamp(math.random(40, 70) + math.floor((tonumber(stats.CursedEnergy) or 0) / 200), 0, 100)
		local paintingId = "death_painting_" .. tostring(math.random(100000, 999999))
		local paintingName = "Death Painting " .. tostring(#stats.DeathPaintings + 1)
		table.insert(stats.DeathPaintings, {
			Id = paintingId,
			Name = paintingName,
			Power = power,
			CreatedAtAge = tonumber(stats.Age) or 0,
			LastUsedAge = nil,
		})
		logMessage = tAct(player, "death_painting_result", { name = paintingName }, "You poured cursed energy into a womb of your own making. <b>" .. paintingName .. "</b> now exists, ready to answer your call in battle.")
		fireMajorPopup(player, "DEATH PAINTING BORN", "A new cursed existence took shape.", paintingName, "You can invoke it once per age during combat.")

	elseif activityId == "cast_culling_games" then
		if not (tostring(stats.Clan or "") == "Kenjaku Clan" and hasBrainTransplant(stats)) then
			fireLifeUpdate(player, stats, tAct(player, "culling_games_gate", nil, "Only Kenjaku Clan sorcerers with Brain Transplant can cast the Culling Games."))
			return false
		end
		if stats.CullingGamesCast == true then
			fireLifeUpdate(player, stats, tAct(player, "culling_games_repeat", nil, "You have already cast the Culling Games once. There is no repeating it."))
			return false
		end
		stats.CullingGameRecruits = typeof(stats.CullingGameRecruits) == "table" and stats.CullingGameRecruits or {}
		stats.DeathPaintings = typeof(stats.DeathPaintings) == "table" and stats.DeathPaintings or {}
		if #stats.CullingGameRecruits < 3 then
			fireLifeUpdate(player, stats, tAct(player, "culling_games_need_recruits", nil, "You need at least 3 people bound to the Culling Games before casting it."))
			return false
		end
		if #stats.DeathPaintings < 1 then
			fireLifeUpdate(player, stats, tAct(player, "culling_games_need_painting", nil, "You need at least 1 Death Painting to anchor the Culling Games."))
			return false
		end

		local totalPower = #stats.CullingGameRecruits * 30
		for _, painting in ipairs(stats.DeathPaintings) do
			totalPower += tonumber(painting.Power) or 0
		end
		totalPower += math.floor((tonumber(stats.CursedEnergy) or 0) / 50)

		stats.CullingGamesCast = true
		local roll = totalPower + math.random(-30, 30)
		local success = roll >= 300

		if success then
			stats.Fame = math.clamp((tonumber(stats.Fame) or 0) + 25, 0, 100)
			stats.Fear = math.clamp((tonumber(stats.Fear) or 0) + 30, 0, 100)
			stats.Reputation = (tonumber(stats.Reputation) or 0) + 20
			stats.CursedEnergy = (tonumber(stats.CursedEnergy) or 0) + 100
			logMessage = tAct(player, "culling_games_success", nil, "The Culling Games tore through the world under your design. Your name is now spoken with dread. Fame, Fear, and Reputation surged, and a burst of cursed energy settled into you.")
			fireMajorPopup(player, "CULLING GAMES CAST", "A game of death began at your command.", "Feared Architect", "Fame, Fear, and Reputation rose sharply.")
		else
			stats.Fear = math.clamp((tonumber(stats.Fear) or 0) + 10, 0, 100)
			stats.Reputation = (tonumber(stats.Reputation) or 0) - 10
			logMessage = tAct(player, "culling_games_failure", nil, "The Culling Games slipped out of your control almost as soon as they began. Other sorcerers moved fast to contain the fallout, and your reputation took the hit.")
			fireMajorPopup(player, "CULLING GAMES BACKFIRED", "The game spiraled before you could shape it.", "Contained", "Reputation dropped, but the world still fears what you attempted.")
		end

	elseif activityId == "study_theory" then
		stats.Smarts = math.clamp((stats.Smarts or 0) + update16Gain(stats, 3, 8, true), 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(1, 5), 0, 100)
		logMessage = tAct(player, "study_theory", nil, "You studied jujutsu theory.")

	elseif activityId == "expand_curse_knowledge" then
		stats.Smarts = math.clamp((stats.Smarts or 0) + update16Gain(stats, 5, 10, true), 0, 100)
		stats.CursedEnergy += update16Gain(stats, 2, 6, false)
		stats.Reputation += math.random(0, 2)
		logMessage = tAct(player, "expand_curse_knowledge", nil, "You expanded your knowledge on curses, studying how they form, hunt, and hide from normal people.")

	elseif activityId == "meditate" then
		stats.Happiness = math.clamp((stats.Happiness or 100) + update16Gain(stats, 4, 10, true), 0, 100)
		stats.CursedEnergy += update16Gain(stats, 1, 5, false)
		logMessage = tAct(player, "meditate", nil, "You meditated and stabilized your energy.")

	elseif activityId == "rest" then
		local assetBonuses = BitKaisenAssets.GetPassiveBonuses(stats)
		local bonus = assetBonuses.HealthRecoveryBonus or 0

		stats.Health = math.clamp((stats.Health or 100) + update16Gain(stats, 8, 18, true) + bonus, 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) + update16Gain(stats, 2, 8, true), 0, 100)

		if bonus > 0 then
			logMessage = tAct(player, "rest_bonus", nil, "You rested in a safer space and recovered.")
		else
			logMessage = tAct(player, "rest", nil, "You rested and recovered.")
		end

	elseif activityId == "doctor" then
		local cost = 120

		if stats.Money < cost then
			stats.ActivitiesDoneThisAge -= 1
			fireLifeUpdate(player, stats, tAct(player, "doctor_no_money", { cost = cost }, "A doctor visit costs $" .. cost .. "."))
			return
		end

		stats.Money -= cost
		stats.Health = math.clamp((stats.Health or 100) + math.random(22, 40), 0, 100)
		logMessage = tAct(player, "doctor", nil, "You visited a doctor and recovered.")

	elseif activityId == "socialize" then
		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(6, 14), 0, 100)

		if stats.InJujutsuHigh then
			stats.Reputation += math.random(1, 4)
		end

		local relationshipMessage, popupData = BitKaisenRelationships.HandleSocialize(stats)
		logMessage = relationshipMessage or tAct(player, "socialize", nil, "You spent time with people.")
		fireRelationshipPopup(player, popupData)



	elseif activityId == "join_other_dojo" then
		ensureJoinedDojoState(stats)

		if isCurseLife(stats) then
			logMessage = tAct(player, "join_dojo_curse_life", nil, "A human dojo would not accept you as you are now. You watched from outside while their barriers rejected your cursed presence.")
		elseif isCurseUser(stats) then
			logMessage = tAct(player, "join_dojo_curse_user", nil, "Most official dojos will not risk housing a known Curse User. You need underground contacts, not a public dojo.")
		elseif getJoinedDojo(stats) then
			local dojo = getJoinedDojo(stats)
			logMessage = tAct(player, "join_dojo_already", { dojo = dojo.Name }, "You are already training with <b>" .. tostring(dojo.Name) .. "</b>.")
		elseif stats.ClanFounded == true and ownsAssetById(stats, "grand_dojo") then
			logMessage = tAct(player, "join_dojo_grand", nil, "You already founded your own Grand Dojo. Other instructors treat you like a peer instead of a student.")
		else
			local dojo = pickJoinableDojo(stats)
			setJoinedDojo(stats, dojo)

			stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(3, 7), 0, 100)
			stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(1, 3), 0, 100)
			stats.CursedEnergy = (stats.CursedEnergy or 0) + math.random(2, 5)

			if stats.InJujutsuHigh ~= true and tostring(stats.SocietyStatus or "") ~= "Jujutsu Student" then
				stats.SocietyStatus = "Dojo Affiliated Sorcerer"
			end

			logMessage = tAct(player, "join_dojo_success", { name = dojo.Name, focus = dojo.Focus, rank = dojo.Rank },
				"You applied to <b>" .. tostring(dojo.Name) .. "</b> and were accepted as an outside student." ..
				"\nFocus: <b>" .. tostring(dojo.Focus) .. "</b> | Rank: <b>" .. tostring(dojo.Rank) .. "</b>." ..
				"\nYou now have access to dojo training and small dojo assignments.")
		end

	elseif activityId == "train_at_joined_dojo" then
		local dojo = getJoinedDojo(stats)

		if not dojo then
			logMessage = tAct(player, "train_dojo_none", nil, "You are not part of another dojo yet. Use <b>Join Another Dojo</b> first.")
		else
			local ceGain = math.random(3, 7)
			local masteryGain = math.random(1, 3)
			local smartsGain = math.random(0, 2)
			local trustGain = math.random(2, 5)
			local progressGain = math.random(4, 9)

			if dojo.Focus == "Combat" then
				ceGain += 2
				masteryGain += 1
			elseif dojo.Focus == "Theory" then
				smartsGain += 2
			elseif dojo.Focus == "Discipline" then
				progressGain += 2
			elseif dojo.Focus == "Loyalty" then
				trustGain += 2
			end

			stats.CursedEnergy = (stats.CursedEnergy or 0) + ceGain
			stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + masteryGain, 0, 100)
			stats.Smarts = math.clamp((stats.Smarts or 0) + smartsGain, 0, 100)
			stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(0, 3), 0, 100)
			dojo.Trust = math.clamp((dojo.Trust or 0) + trustGain, 0, 100)
			dojo.Progress = math.max(0, (dojo.Progress or 0) + progressGain)
			setJoinedDojo(stats, dojo)

			logMessage = tAct(player, "train_dojo", { dojo = dojo.Name, progress = dojo.Progress or 0, trust = dojo.Trust or 0 },
				"You trained at <b>" .. tostring(dojo.Name) .. "</b>. The instructors pushed your cursed energy control and corrected your bad habits." ..
				"\nDojo Progress: <b>" .. tostring(dojo.Progress or 0) .. "</b> | Dojo Trust: <b>" .. tostring(dojo.Trust or 0) .. "/100</b>.")
		end

	elseif activityId == "dojo_assignment" then
		local dojo = getJoinedDojo(stats)

		if not dojo then
			logMessage = tAct(player, "dojo_assign_none", nil, "No dojo trusts you with assignments yet. Join another dojo first.")
		else
			local roll = math.random(1, 100)
			local rewardMoney = math.random(80, 220)
			local repGain = math.random(1, 4)
			local progressGain = math.random(5, 12)
			local trustGain = math.random(3, 7)
			local damage = 0

			if dojo.Rank == "Elite Dojo" then
				rewardMoney += 120
				repGain += 2
			elseif dojo.Rank == "Respected Dojo" then
				rewardMoney += 70
				repGain += 1
			end

			if roll <= 18 then
				damage = math.random(4, 12)
				stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
				logMessage = tAct(player, "dojo_assign_hurt", { dojo = dojo.Name }, "Your dojo sent you on a small assignment for <b>" .. tostring(dojo.Name) .. "</b>. You completed it, but got hurt covering for another student.")
			else
				logMessage = tAct(player, "dojo_assign_clean", { dojo = dojo.Name }, "Your dojo sent you on a small assignment for <b>" .. tostring(dojo.Name) .. "</b>. You handled it cleanly and earned more trust.")
			end

			stats.Money = math.max(0, (stats.Money or 0) + rewardMoney)
			stats.Reputation = (stats.Reputation or 0) + repGain
			stats.CursedEnergy = (stats.CursedEnergy or 0) + math.random(1, 4)
			dojo.Trust = math.clamp((dojo.Trust or 0) + trustGain, 0, 100)
			dojo.Progress = math.max(0, (dojo.Progress or 0) + progressGain)
			dojo.Assignments = math.max(0, (dojo.Assignments or 0) + 1)
			setJoinedDojo(stats, dojo)

			logMessage ..= tAct(player, "dojo_assign_earned", { money = rewardMoney }, "\nEarned <b>$" .. tostring(rewardMoney) .. "</b>, reputation, and dojo progress.")
			if damage > 0 then
				logMessage ..= tAct(player, "dojo_assign_health", { dmg = damage }, "\nHealth -" .. tostring(damage) .. ".")
			end
		end

	elseif activityId == "leave_joined_dojo" then
		local dojo = getJoinedDojo(stats)

		if not dojo then
			logMessage = tAct(player, "leave_dojo_none", nil, "You are not currently joined to another dojo.")
		else
			local oldName = tostring(dojo.Name or "your dojo")
			local oldTrust = tonumber(dojo.Trust) or 0
			setJoinedDojo(stats, nil)

			stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(0, 4), 0, 100)
			if oldTrust >= 50 then
				stats.Reputation = (stats.Reputation or 0) + 1
			end

			logMessage = tAct(player, "leave_dojo", { dojo = oldName }, "You left <b>" .. oldName .. "</b> and returned to independent training.")
			if oldTrust >= 50 then
				logMessage ..= tAct(player, "leave_dojo_respect", nil, "\nBecause you left respectfully, some instructors still speak well of you.")
			end
		end

	elseif activityId == "curse_user_black_market" then
		if not isCurseUser(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only Curse Users can use black market contacts.")
			return
		end

		local pay = math.random(250, 850)
		local ceGain = math.random(3, 10)
		stats.Money += pay
		stats.CursedEnergy += ceGain
		stats.CursedResentment = math.clamp((tonumber(stats.CursedResentment) or 0) + math.random(3, 9), 0, 999)
		stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + math.random(1, 3), 0, 100)
		stats.Reputation = (tonumber(stats.Reputation) or 0) - math.random(2, 7)
		stats.SocietyStatus = (stats.WantedLevel or 0) >= 8 and "Wanted Curse User" or "Underground Curse User"
		logMessage = tAct(player, "curse_user_bm", { pay = pay }, "You met a black market curse broker and accepted information Jujutsu Society would never approve. You earned <b>$" .. tostring(pay) .. "</b>, but your wanted level rose.")

	elseif activityId == "curse_user_hide_society" then
		if not isCurseUser(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only Curse Users need to hide from Jujutsu Society this way.")
			return
		end

		local wantedDrop = math.random(1, 4)
		local resentmentGain = math.random(1, 4)
		stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) - wantedDrop, 0, 100)
		stats.CursedResentment = math.clamp((tonumber(stats.CursedResentment) or 0) + resentmentGain, 0, 999)
		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - math.random(0, 4), 0, 100)
		stats.SocietyStatus = (stats.WantedLevel or 0) >= 8 and "Wanted Curse User" or "Hidden Curse User"
		logMessage = tAct(player, "curse_user_hide", { drop = wantedDrop }, "You erased tracks, avoided scouts, and let the underground go quiet around you. Wanted Level <b>-" .. tostring(wantedDrop) .. "</b>.")

	elseif activityId == "curse_user_illegal_job" then
		if not isCurseUser(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only Curse Users can take illegal curse jobs.")
			return
		end

		local pay = math.random(600, 1900)
		local ceGain = math.random(8, 20)
		local masteryGain = tostring(stats.CursedTechnique or "None") ~= "None" and math.random(1, 4) or 0
		local injury = math.random(0, 18)
		stats.Money += pay
		stats.CursedEnergy += ceGain
		stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + masteryGain, 0, 100)
		stats.Health = math.clamp((tonumber(stats.Health) or 100) - injury, 0, 100)
		stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + math.random(2, 6), 0, 100)
		stats.CursedResentment = math.clamp((tonumber(stats.CursedResentment) or 0) + math.random(5, 14), 0, 999)
		stats.Reputation = (tonumber(stats.Reputation) or 0) - math.random(5, 12)
		stats.SocietyStatus = "Wanted Curse User"
		logMessage = tAct(player, "curse_user_illegal", { pay = pay, ce = ceGain }, "You completed an illegal curse job. The payout was real, but so was the heat. Earned <b>$" .. tostring(pay) .. "</b>, CE <b>+" .. tostring(ceGain) .. "</b>.")
		if injury > 0 then
			logMessage ..= tAct(player, "curse_user_illegal_dmg", { dmg = injury }, " Health <b>-" .. tostring(injury) .. "</b>.")
		end

	elseif activityId == "curse_user_secret_training" then
		if not isCurseUser(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only Curse Users can use this secret training route.")
			return
		end

		local ceGain = math.random(12, 28)
		local masteryGain = tostring(stats.CursedTechnique or "None") ~= "None" and math.random(2, 6) or 0
		stats.CursedEnergy += ceGain
		stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + masteryGain, 0, 100)
		stats.Health = math.clamp((tonumber(stats.Health) or 100) - math.random(2, 10), 0, 100)
		stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + math.random(0, 2), 0, 100)
		stats.CursedResentment = math.clamp((tonumber(stats.CursedResentment) or 0) + math.random(2, 8), 0, 999)
		stats.PrivateTrainingSessions = (tonumber(stats.PrivateTrainingSessions) or 0) + 1
		stats.SocietyStatus = (stats.WantedLevel or 0) >= 8 and "Wanted Curse User" or "Rogue Sorcerer"
		logMessage = tAct(player, "curse_user_secret", { ce = ceGain, mastery = masteryGain }, "You trained where no teacher could stop you. CE <b>+" .. tostring(ceGain) .. "</b>, Technique Mastery <b>+" .. tostring(masteryGain) .. "%</b>.")

	elseif activityId == "curse_user_threaten_informant" then
		if not isCurseUser(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only Curse Users can threaten informants this way.")
			return
		end

		local pay = math.random(120, 520)
		stats.Money += pay
		stats.Smarts = math.clamp((tonumber(stats.Smarts) or 0) + math.random(1, 4), 0, 100)
		stats.CursedResentment = math.clamp((tonumber(stats.CursedResentment) or 0) + math.random(4, 10), 0, 999)
		stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + math.random(1, 5), 0, 100)
		stats.Reputation = (tonumber(stats.Reputation) or 0) - math.random(4, 10)
		logMessage = tAct(player, "curse_user_threaten", nil, "You leaned on an informant until they gave up a useful lead. You gained money and information, but your name became uglier underground.")

	elseif activityId == "dojo_send_students_patrol" then
		if stats.ClanFounded ~= true or not ownsAssetById(stats, "grand_dojo") then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need a founded clan and Grand Dojo before sending students on patrol.")
			return
		end

		local usedThisWindow = getStudentPatrolUsedThisWindow(stats)
		if usedThisWindow >= 1 then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You already sent dojo students on patrol this 6-month period. Age up 6 months before sending another patrol.")
			return
		end

		local students = getDojoStudentList(stats)
		if #students <= 0 then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need dojo students before sending patrols.")
			return
		end

		stats.StudentPatrolUsed = usedThisWindow + 1
		stats.StudentMissionCooldown = math.max(tonumber(stats.StudentMissionCooldown) or 0, 1)

		local totalPower = 0
		local promotedNames = {}
		for _, student in ipairs(students) do
			totalPower += getStudentPower(student)
			local result = trainStudent(student, getDojoFocusLabel(stats), 0.75)
			if result.Promoted then
				table.insert(promotedNames, student.Name .. " reached " .. tostring(student.Grade))
			end
		end

		local successChance = math.clamp(35 + math.floor(totalPower / math.max(1, #students * 8)) + ((tonumber(stats.DojoLevel) or 1) * 4), 20, 92)
		local earned = math.random(120, 320) + math.floor(totalPower / 9)
		stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) + math.random(2, 6))
		stats.DojoPrestige = math.max(0, (tonumber(stats.DojoPrestige) or 0) + math.random(1, 4))
		if math.random(1, 100) <= successChance then
			stats.Money += earned
			stats.Reputation = (tonumber(stats.Reputation) or 0) + math.random(1, 4)
			logMessage = tAct(player, "dojo_patrol_success", { money = earned }, "Your students handled a minor patrol and brought credit back to the Grand Dojo. Earned <b>$" .. tostring(earned) .. "</b>.")
		else
			adjustDojoCondition(stats, -math.random(3, 8))
			stats.Reputation = (tonumber(stats.Reputation) or 0) - math.random(0, 2)
			logMessage = tAct(player, "dojo_patrol_fail", nil, "Your student patrol got messy. They survived and learned, but the dojo took reputation pressure and needed repairs.")
		end
		if #promotedNames > 0 then
			logMessage ..= "\n<b>Promotion:</b> " .. table.concat(promotedNames, "; ") .. "."
		end

	elseif activityId == "dojo_grade_review" then
		if stats.ClanFounded ~= true or not ownsAssetById(stats, "grand_dojo") then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need a founded clan and Grand Dojo before reviewing student grades.")
			return
		end

		local students = getDojoStudentList(stats)
		if #students <= 0 then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need dojo students before reviewing grades.")
			return
		end

		local promotedNames = {}
		local totalProgress = 0
		for _, student in ipairs(students) do
			local result = trainStudent(student, "Theory", 1)
			totalProgress += result.ProgressGain
			if result.Promoted then
				table.insert(promotedNames, student.Name .. " reached " .. tostring(student.Grade))
			end
		end
		stats.ClanTrainingSessions = (tonumber(stats.ClanTrainingSessions) or 0) + 1
		stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) + math.random(3, 7))
		stats.DojoPrestige = math.max(0, (tonumber(stats.DojoPrestige) or 0) + math.random(2, 6))
		logMessage = tAct(player, "dojo_grade_review", { progress = totalProgress }, "You reviewed student grades, corrected training plans, and logged <b>+" .. tostring(totalProgress) .. "</b> total student progress.")
		if #promotedNames > 0 then
			logMessage ..= "\n<b>Promotion:</b> " .. table.concat(promotedNames, "; ") .. "."
		end

	elseif activityId == "dojo_pair_sparring" then
		if stats.ClanFounded ~= true or not ownsAssetById(stats, "grand_dojo") then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need a founded clan and Grand Dojo before running student sparring.")
			return
		end

		local students = getDojoStudentList(stats)
		if #students <= 0 then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need dojo students before running sparring pairs.")
			return
		end

		local promotedNames = {}
		local strongest = nil
		local strongestPower = -1
		for _, student in ipairs(students) do
			local result = trainStudent(student, "Combat", 1.35)
			local power = getStudentPower(student)
			if power > strongestPower then
				strongest = student
				strongestPower = power
			end
			if result.Promoted then
				table.insert(promotedNames, student.Name .. " reached " .. tostring(student.Grade))
			end
		end
		adjustDojoCondition(stats, -math.random(4, 10))
		stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) + math.random(2, 6))
		stats.DojoPrestige = math.max(0, (tonumber(stats.DojoPrestige) or 0) + math.random(3, 8))
		logMessage = tAct(player, "dojo_sparring", nil, "You paired students for hard sparring. Grade, CE, cursed technique, and potential all affected who improved fastest.")
		if strongest then
			logMessage ..= tAct(player, "dojo_sparring_top", { name = strongest.Name, grade = strongest.Grade or "Non-Sorcerer" }, "\nTop student today: <b>" .. tostring(strongest.Name) .. "</b> (" .. tostring(strongest.Grade or "Non-Sorcerer") .. ").")
		end
		if #promotedNames > 0 then
			logMessage ..= "\n<b>Promotion:</b> " .. table.concat(promotedNames, "; ") .. "."
		end

	elseif activityId == "curse_stalk_haunt" then
		if not canUseCurseActivity(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only cursed spirit lives can stalk a haunt this way.")
			return
		end

		ensureCursedSpiritFlavor(stats)
		local threatGain = math.random(2, 7)
		local evolutionNote = addCurseEvolutionProgress(stats, math.random(2, 6), "Stalking your haunt")
		stats.CurseThreat = math.max(0, (tonumber(stats.CurseThreat) or 0) + threatGain)
		stats.CurseRumorSpread = math.max(0, (tonumber(stats.CurseRumorSpread) or 0) + math.random(4, 12))
		stats.CurseTerritoryControl = math.clamp((tonumber(stats.CurseTerritoryControl) or 0) + math.random(3, 9), 0, 100)
		addSocietyAttention(stats, math.random(0, 4))
		logMessage = "You stalked your haunt until people felt your presence even without seeing you. Threat <b>+" .. tostring(threatGain) .. "</b>." .. adjustWorldReputation(stats, 0, math.random(2, 4), 1) .. evolutionNote

	elseif activityId == "curse_confuse_trackers" then
		if not canUseCurseActivity(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only cursed spirit lives can confuse trackers this way.")
			return
		end

		local riskDrop = math.random(4, 12)
		local attentionDrop = math.random(4, 10)
		stats.ExorcismRisk = math.clamp((tonumber(stats.ExorcismRisk) or 0) - riskDrop, 0, 100)
		stats.SocietyAttention = math.clamp((tonumber(stats.SocietyAttention) or 0) - attentionDrop, 0, 100)
		addCurseHunger(stats, math.random(3, 9))
		logMessage = "You scattered false cursed energy traces. Exorcism Risk <b>-" .. tostring(riskDrop) .. "%</b>, Society Attention <b>-" .. tostring(attentionDrop) .. "%</b>." .. adjustWorldReputation(stats, 0, -1, 1)

	elseif activityId == "curse_force_evolution" then
		if not canUseCurseActivity(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only cursed spirit lives can force evolution.")
			return
		end

		local evoGain = math.random(10, 24)
		local damage = math.random(6, 22)
		local evolutionNote = addCurseEvolutionProgress(stats, evoGain, "Forced evolution")
		stats.CursedEnergy += math.random(8, 18)
		stats.CurseThreat = math.max(0, (tonumber(stats.CurseThreat) or 0) + math.random(2, 6))
		stats.Health = math.clamp((tonumber(stats.Health) or 100) - damage, 0, 100)
		addSocietyAttention(stats, math.random(2, 7))
		logMessage = tAct(player, "curse_force_evo", { evo = evoGain, dmg = damage }, "You forced your cursed body toward its next shape. Evolution Progress <b>+" .. tostring(evoGain) .. "</b>, Health <b>-" .. tostring(damage) .. "</b>.") .. evolutionNote

	elseif activityId == "curse_devour_remnant" then
		if not canUseCurseActivity(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only cursed spirit lives can devour remnants this way.")
			return
		end

		local ceGain = math.random(16, 36)
		local evoGain = math.random(5, 15)
		local backlash = math.random(1, 100) <= 24
		stats.CursedEnergy += ceGain
		local evolutionNote = addCurseEvolutionProgress(stats, evoGain, "Devouring cursed remnants")
		reduceCurseHunger(stats, math.random(8, 18))
		if backlash then
			stats.Health = math.clamp((tonumber(stats.Health) or 100) - math.random(6, 18), 0, 100)
			addSocietyAttention(stats, math.random(4, 10))
		end
		logMessage = tAct(player, "curse_devour", { ce = ceGain, evo = evoGain }, "You devoured unstable cursed remnants. CE <b>+" .. tostring(ceGain) .. "</b>, Evolution Progress <b>+" .. tostring(evoGain) .. "</b>.")
		if backlash then
			logMessage ..= tAct(player, "curse_devour_backlash", nil, " The remnant fought back inside your cursed body.")
		end
		logMessage ..= evolutionNote

	elseif activityId == "curse_absorb_fear" then
		if not canUseCurseActivity(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only cursed spirit lives can absorb fear this way.")
			return
		end

		local ceGain = math.random(10, 24)
		local threatGain = math.random(2, 6)
		local hungerDrop = math.random(8, 18)
		ensureCursedSpiritFlavor(stats)
		stats.CursedEnergy += ceGain
		stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + threatGain)
		stats.CurseFearLevel = math.max(0, (stats.CurseFearLevel or 0) + math.random(3, 8))
		local evolutionNote = addCurseEvolutionProgress(stats, math.random(1, 5), "Absorbing fear")
		reduceCurseHunger(stats, hungerDrop)
		stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) + math.random(0, 3), 0, 100)
		logMessage = applyCursedSpiritActivityFlavor(stats, "absorb_fear")
		logMessage ..= "\nGained <b>+" .. tostring(ceGain) .. " CE</b>, <b>+" .. tostring(threatGain) .. " Threat</b>. Hunger <b>-" .. tostring(hungerDrop) .. "%</b>." .. evolutionNote

	elseif activityId == "curse_hide_presence" then
		if not canUseCurseActivity(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only cursed spirit lives need to hide cursed presence this way.")
			return
		end

		local riskDrop = math.random(6, 16)
		local attentionDrop = math.random(3, 9)
		local hungerGain = math.random(4, 10)
		ensureCursedSpiritFlavor(stats)
		stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) - riskDrop, 0, 100)
		stats.SocietyAttention = math.clamp((stats.SocietyAttention or 0) - attentionDrop, 0, 100)
		stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) - math.random(0, 3))
		stats.SorcererAttackCooldown = math.max(tonumber(stats.SorcererAttackCooldown) or 0, 2)
		addCurseHunger(stats, hungerGain)
		stats.CursedEnergy += math.random(1, 5)
		logMessage = applyCursedSpiritActivityFlavor(stats, "hide")
		logMessage ..= "\nExorcism Risk <b>-" .. tostring(riskDrop) .. "%</b>. Society Attention <b>-" .. tostring(attentionDrop) .. "%</b>. Hunger <b>+" .. tostring(hungerGain) .. "%</b>."

	elseif activityId == "curse_hunt_remnants" then
		if not canUseCurseActivity(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only cursed spirit lives can hunt curse remnants this way.")
			return
		end

		local ceGain = math.random(12, 28)
		local damage = math.random(0, 12)
		local evolutionGain = math.random(6, 14)
		local hungerDrop = math.random(5, 14)
		ensureCursedSpiritFlavor(stats)
		stats.CursedEnergy += ceGain
		stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
		stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + math.random(2, 7))
		local evolutionNote = addCurseEvolutionProgress(stats, evolutionGain, "Hunting curse remnants")
		stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) + math.random(1, 5), 0, 100)
		reduceCurseHunger(stats, hungerDrop)
		logMessage = applyCursedSpiritActivityFlavor(stats, "remnants")
		logMessage ..= "\nGained <b>+" .. tostring(ceGain) .. " CE</b>, <b>+" .. tostring(evolutionGain) .. " Evolution Progress</b>. Hunger <b>-" .. tostring(hungerDrop) .. "%</b>." .. evolutionNote
		if damage > 0 then
			logMessage ..= "\nThe hunt damaged your cursed body. Health <b>-" .. tostring(damage) .. "</b>."
		end

	elseif activityId == "curse_lure_sorcerer" then
		if not canUseCurseActivity(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only curse lives can lure sorcerers this way.")
			return
		end

		stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + math.random(4, 9))
		stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) + math.random(5, 12), 0, 100)
		stats.SorcererAttackCooldown = 0
		if beginCurseSorcererAttack(player, stats, "You deliberately exposed your cursed energy and dared the jujutsu world to answer.") then
			logMessage = tAct(player, "curse_lure_hit", nil, "You exposed your cursed energy on purpose. A sorcerer answered the challenge.")
		else
			logMessage = tAct(player, "curse_lure_miss", nil, "You exposed your cursed energy, but no sorcerer reached you this time. Your threat still rose.")
		end

	elseif activityId == "curse_claim_territory" then
		if not canUseCurseActivity(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only cursed spirit lives can claim territory this way.")
			return
		end

		ensureCursedSpiritFlavor(stats)
		local oldTerritory = tostring(stats.CurseTerritory or "your old haunt")
		local damage = math.random(0, 10)
		stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
		stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + math.random(2, 8))
		stats.ExorcismRisk = math.clamp((stats.ExorcismRisk or 0) + math.random(2, 7), 0, 100)
		addCurseHunger(stats, math.random(4, 12))
		logMessage = applyCursedSpiritActivityFlavor(stats, "territory")
		logMessage ..= "\nOld Territory: <b>" .. oldTerritory .. "</b>."
		if damage > 0 then
			logMessage ..= " Health <b>-" .. tostring(damage) .. "</b>."
		end

	elseif activityId == "curse_spread_rumor" then
		if not canUseCurseActivity(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only cursed spirit lives can spread a rumor this way.")
			return
		end

		ensureCursedSpiritFlavor(stats)
		local threatGain = math.random(3, 9)
		local evoGain = math.random(2, 8)
		stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + threatGain)
		local evolutionNote = addCurseEvolutionProgress(stats, evoGain, "Spreading your rumor")
		stats.CurseFearLevel = math.max(0, (stats.CurseFearLevel or 0) + math.random(4, 12))
		addCurseHunger(stats, math.random(2, 7))
		addSocietyAttention(stats, math.random(1, 6))
		logMessage = applyCursedSpiritActivityFlavor(stats, "rumor")
		logMessage ..= "\nThreat <b>+" .. tostring(threatGain) .. "</b>. Evolution Progress <b>+" .. tostring(evoGain) .. "</b>." .. evolutionNote

	elseif activityId == "curse_feed_negative_emotion" then
		if not canUseCurseActivity(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only cursed spirit lives can feed on negative emotion this way.")
			return
		end

		ensureCursedSpiritFlavor(stats)
		local ceGain = math.random(14, 32)
		local hungerDrop = math.random(15, 30)
		local attentionGain = math.random(0, 8)
		stats.CursedEnergy += ceGain
		local evolutionNote = addCurseEvolutionProgress(stats, math.random(3, 9), "Feeding on negative emotion")
		stats.CurseThreat = math.max(0, (stats.CurseThreat or 0) + math.random(1, 5))
		reduceCurseHunger(stats, hungerDrop)
		addSocietyAttention(stats, attentionGain)
		logMessage = applyCursedSpiritActivityFlavor(stats, "feed_negative")
		logMessage ..= "\nGained <b>+" .. tostring(ceGain) .. " CE</b>. Hunger <b>-" .. tostring(hungerDrop) .. "%</b>." .. evolutionNote

	elseif activityId == "practice_technique" then
		local technique = tostring(stats.CursedTechnique or "None")

		if technique == "None" then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need to awaken a cursed technique before you can practice it.")
			return
		end

		local assetBonuses = BitKaisenAssets.GetPassiveBonuses(stats)
		local trainingBonus = assetBonuses.CursedEnergyTrainingBonus or 0

		local masteryGain = math.random(2, 5)

		if stats.InJujutsuHigh then
			masteryGain += 1
		end

		if (stats.Smarts or 0) >= 60 then
			masteryGain += 1
		end

		if trainingBonus >= 8 then
			masteryGain += 2
		elseif trainingBonus >= 4 then
			masteryGain += 1
		end

		local prodigyMult = ownsTrainingProdigyPass(player) and 1.5 or 1
		local doubleMult = ownsDoubleTrainingPass(player) and 2 or 1
		local vipMasteryMult = ownsVIPPass(player) and 2 or 1
		local techMult = prodigyMult * doubleMult * vipMasteryMult
		masteryGain = math.floor(masteryGain * techMult)

		local oldMastery = stats.TechniqueMastery or 0
		stats.TechniqueMastery = math.clamp(oldMastery + masteryGain, 0, 100)

		stats.CursedEnergy += math.floor((math.random(5, 12) + math.floor(trainingBonus / 2)) * techMult)
		stats.Reputation += math.random(1, 3)
		stats.Health = math.clamp((stats.Health or 100) - math.random(1, 4), 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(0, 3), 0, 100)

		logMessage = tAct(player, "practice_technique", { technique = technique, gain = stats.TechniqueMastery - oldMastery },
			"You practiced <b>" .. technique .. "</b> and improved your cursed technique control." ..
			"\nTechnique Mastery increased by <b>" .. tostring(stats.TechniqueMastery - oldMastery) .. "%</b>.")
		logMessage ..= BitKaisenTechniqueEvolution.AddPressure(stats, math.random(3, 7), "technique practice")
		logMessage ..= progressTechniqueAllies(stats)

		if stats.TechniqueMastery >= 25 and oldMastery < 25 then
			logMessage ..= tAct(player, "practice_technique_refined", nil, "\nYour technique reached <b>Refined Control</b>.")

			fireMajorPopup(
				player,
				"TECHNIQUE MASTERY",
				"Your cursed technique became more reliable.",
				"Refined Control",
				"Technique Mastery now gives stronger mission value."
			)
		elseif stats.TechniqueMastery >= 50 and oldMastery < 50 then
			logMessage ..= tAct(player, "practice_technique_advanced", nil, "\nYour technique reached <b>Advanced Application</b>.")

			fireMajorPopup(
				player,
				"TECHNIQUE MASTERY",
				"Your cursed technique is becoming part of your identity.",
				"Advanced Application",
				"Future technique choices can use this milestone."
			)
		elseif stats.TechniqueMastery >= 75 and oldMastery < 75 then
			logMessage ..= tAct(player, "practice_technique_elite", nil, "\nYour technique reached <b>Elite Mastery</b>.")

			fireMajorPopup(
				player,
				"TECHNIQUE MASTERY",
				"Your control is now dangerous even by sorcerer standards.",
				"Elite Mastery",
				"Rare mastery events can be added later."
			)
		elseif stats.TechniqueMastery >= 95 and oldMastery < 95 then
			logMessage ..= tAct(player, "practice_technique_complete", nil, "\nYour technique reached <b>Complete Mastery</b>.")

			fireMajorPopup(
				player,
				"TECHNIQUE MASTERY",
				"You are approaching the peak of your innate technique.",
				"Complete Mastery",
				"Domain Expansion can be built on this later."
			)
		end

	elseif activityId == "apply_jujutsu_high" then
		ensureSorcererRegistrationState(stats)

		if isCurseLife(stats) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			stats.InJujutsuHigh = false
			stats.RegisteredSorcerer = false
			fireLifeUpdate(player, stats, "Cursed spirit lives cannot enroll in Jujutsu High.")
			return
		end

		local birthPath = typeof(stats.BirthPath) == "table" and stats.BirthPath or nil
		local currentEra = tostring(stats.CurrentEra or stats.Era or (birthPath and birthPath.Era) or "")

		if currentEra == "Heian Era" then
			stats.Happiness = math.clamp((stats.Happiness or 100) - 2, 0, 100)
			logMessage = "You searched for Jujutsu High, but that institution does not exist in the Heian Era. Sorcerers in this age survive through clans, temples, masters, and raw reputation."

			fireMajorPopup(
				player,
				"NO JUJUTSU HIGH",
				"Jujutsu High has not been founded in this era.",
				"Heian Era",
				"Seek power through clans, training, missions, and reputation instead."
			)
		elseif stats.InJujutsuHigh == true then
			logMessage = "You are already registered through Jujutsu High."
		elseif isCurseUser(stats) then
			stats.Happiness = math.clamp((stats.Happiness or 100) - 4, 0, 100)
			logMessage = "Jujutsu High rejected your application because you have already been branded as a curse user."

			fireMajorPopup(
				player,
				"JUJUTSU HIGH REJECTION",
				"Your application was reviewed by the jujutsu world.",
				"Curse User",
				"Your path has already moved outside official registration."
			)
		elseif (stats.Age or 0) < 13 then
			stats.Happiness = math.clamp((stats.Happiness or 100) - 3, 0, 100)
			logMessage = "Jujutsu High rejected your application because you are still too young to be evaluated seriously."

			fireMajorPopup(
				player,
				"JUJUTSU HIGH REJECTION",
				"Your application was reviewed by the jujutsu world.",
				"Too Young",
				"Try again when you are older."
			)
		elseif not isUnregisteredSorcerer(stats) then
			stats.Happiness = math.clamp((stats.Happiness or 100) - 5, 0, 100)
			logMessage = "Jujutsu High rejected your application because your cursed energy has not been recognized yet. You need to awaken or show enough cursed energy to be given an unregistered grade first."

			fireMajorPopup(
				player,
				"JUJUTSU HIGH REJECTION",
				"Your application was reviewed by the jujutsu world.",
				"Rejected",
				"You need an unregistered sorcerer grade before official registration."
			)
		else
			local acceptancePower = (stats.CursedEnergy or 0) + ((stats.Smarts or 0) * 0.8) + ((stats.Reputation or 0) * 2) + math.random(1, 45)

			if stats.FamilyType == "Sorcerer" then
				acceptancePower += 20
			elseif stats.FamilyType == "Unknown" then
				acceptancePower += 10
			elseif stats.FamilyType == "Fallen" then
				acceptancePower += 12
			elseif stats.Origin == "Cursed Womb" then
				acceptancePower += 15
			end

			if acceptancePower >= 55 then
				local enrollMsg = enrollInJujutsuHigh(player, stats)
				logMessage = enrollMsg
			else
				stats.Happiness = math.clamp((stats.Happiness or 100) - 10, 0, 100)
				logMessage = "Jujutsu High rejected your application. Your unregistered grade was noted, but your cursed energy control was not convincing enough yet."

				fireMajorPopup(
					player,
					"JUJUTSU HIGH REJECTION",
					"Your application was reviewed by the jujutsu world.",
					"Rejected",
					"Train harder and improve your cursed energy."
				)
			end
		end

	elseif activityId == "jujutsu_affiliation_duty" then
		if stats.InJujutsuHigh ~= true then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need to be registered through Jujutsu High before taking official duties.")
			return
		end

		local dutyRoll = math.random(1, 3)
		local affGain = math.random(4, 9)
		local repGain = math.random(1, 3)
		local ceGain = math.random(3, 9)
		stats.Affiliation = "Jujutsu High"
		stats.AffiliationRank = tostring(stats.AffiliationRank or "Student")
		stats.AffiliationDuties = math.max(0, (tonumber(stats.AffiliationDuties) or 0) + 1)
		stats.AffiliationReputation = math.clamp((tonumber(stats.AffiliationReputation) or 0) + affGain, 0, 100)
		stats.CursedEnergy += ceGain
		stats.Reputation += repGain
		stats.TeacherRecommendations = math.max(0, (tonumber(stats.TeacherRecommendations) or 0) + math.random(0, 1))
		if dutyRoll == 1 then
			stats.Health = math.clamp((stats.Health or 100) - math.random(1, 5), 0, 100)
			logMessage = tAct(player, "jh_duty_field", nil, "You handled a field report for Jujutsu High and cleaned up a minor curse trail.")
		elseif dutyRoll == 2 then
			stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(1, 3), 0, 100)
			logMessage = tAct(player, "jh_duty_files", nil, "You assisted with case files and learned how higher-ups classify incidents.")
		else
			stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(1, 4), 0, 100)
			logMessage = tAct(player, "jh_duty_escort", nil, "You escorted a junior sorcerer through a controlled assignment.")
		end
		logMessage ..= tAct(player, "jh_duty_stats", { aff = affGain, ce = ceGain }, "\nAffiliation Reputation <b>+" .. tostring(affGain) .. "</b>, CE <b>+" .. tostring(ceGain) .. "</b>.") .. adjustWorldReputation(stats, 1, 0, 2)
		if stats.AffiliationReputation >= 70 then
			stats.AffiliationRank = "Trusted Operative"
		elseif stats.AffiliationReputation >= 35 then
			stats.AffiliationRank = "Field Asset"
		else
			stats.AffiliationRank = "Student"
		end

	elseif activityId == "request_assistant" then
		if stats.InJujutsuHigh ~= true then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need a Jujutsu High affiliation before requesting an assistant.")
			return
		end
		if stats.AssistantName then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You already have an assigned assistant.")
			return
		end
		local standing = (tonumber(stats.AffiliationReputation) or 0) + math.floor((tonumber(stats.MissionsCompleted) or 0) * 2) + math.floor((tonumber(stats.Fame) or 0) / 2)
		if standing < 18 then
			stats.Happiness = math.clamp((stats.Happiness or 100) - 3, 0, 100)
			logMessage = tAct(player, "jh_assistant_denied", nil, "Jujutsu High denied your assistant request. You need more affiliation standing or completed missions first.")
		else
			stats.AssistantName = rollAssistantName()
			stats.AssistantTrust = math.random(18, 32)
			stats.AssistantSkill = math.random(12, 28)
			stats.AffiliationReputation = math.clamp((tonumber(stats.AffiliationReputation) or 0) + 3, 0, 100)
			logMessage = tAct(player, "jh_assistant_assigned", { name = stats.AssistantName }, "Jujutsu High assigned <b>" .. tostring(stats.AssistantName) .. "</b> as your field assistant.")
			fireMajorPopup(player, "ASSISTANT ASSIGNED", "Your affiliation approved support staff.", tostring(stats.AssistantName), "Train together to improve mission support and technique growth.")
		end

	elseif activityId == "train_with_assistant" then
		if not stats.AssistantName then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need an assigned assistant before training together.")
			return
		end
		local trustGain = math.random(3, 8)
		local skillGain = math.random(2, 7)
		local masteryGain = math.random(2, 5) + math.floor((tonumber(stats.AssistantSkill) or 0) / 25)
		stats.AssistantTrust = math.clamp((tonumber(stats.AssistantTrust) or 0) + trustGain, 0, 100)
		stats.AssistantSkill = math.clamp((tonumber(stats.AssistantSkill) or 0) + skillGain, 0, 100)
		stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + masteryGain, 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(0, 3), 0, 100)
		logMessage = tAct(player, "jh_train_assistant", { name = stats.AssistantName, trust = trustGain, skill = skillGain, mastery = masteryGain }, "You trained with <b>" .. tostring(stats.AssistantName) .. "</b>. Assistant Trust <b>+" .. tostring(trustGain) .. "</b>, Assistant Skill <b>+" .. tostring(skillGain) .. "</b>, Technique Mastery <b>+" .. tostring(masteryGain) .. "%</b>.")

	elseif activityId == "evolve_technique" then
		local technique = tostring(stats.CursedTechnique or "None")
		if technique == "None" then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need an awakened technique before evolving it.")
			return
		end
		local mastery = tonumber(stats.TechniqueMastery) or 0
		local oldStage = tostring(stats.TechniqueEvolutionStage or "Dormant")
		local newStage = nil
		local needed = 25
		if oldStage == "Dormant" then
			needed = 25
			newStage = "Refined Form"
		elseif oldStage == "Refined Form" then
			needed = 50
			newStage = "Extension Technique"
		elseif oldStage == "Extension Technique" then
			needed = 75
			newStage = "Maximum Technique"
		elseif oldStage == "Maximum Technique" then
			needed = 95
			newStage = "Domain Seed"
		end
		if not newStage or mastery < needed then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Your technique is not ready for its next evolution yet.")
			return
		end
		local strain = math.random(3, 10)
		local branchName = BitKaisenTechniqueEvolution.GetBranchName(stats, newStage)
		stats.TechniqueEvolutionProgress = math.max(tonumber(stats.TechniqueEvolutionProgress) or 0, needed)
		local advanced = BitKaisenTechniqueEvolution.TryAdvance(stats)
		if not advanced then
			stats.TechniqueEvolutionStage = newStage
			stats.TechniqueEvolutionProgress = math.clamp(needed, 0, 100)
			stats.TechniqueBranch = branchName
		end
		stats.CursedEnergy += math.random(8, 18)
		stats.Health = math.clamp((stats.Health or 100) - strain, 0, 100)
		stats.Reputation += math.random(2, 5)
		logMessage = tAct(player, "jh_evolve", { technique = technique, from = oldStage, to = branchName, dmg = strain }, "You evolved <b>" .. technique .. "</b> from <b>" .. oldStage .. "</b> into <b>" .. branchName .. "</b>. Health <b>-" .. tostring(strain) .. "</b>.") .. adjustWorldReputation(stats, 2, math.random(0, 2), 3)
		fireMajorPopup(player, "TECHNIQUE EVOLUTION", "Your innate technique reached a new application.", branchName, "Further evolution unlocks at higher mastery thresholds.")

	elseif activityId == "body_hop" then
		local technique = tostring(stats.CursedTechnique or stats.InnateTechnique or "")
		local techLower = string.lower(technique)
		if not (string.find(techLower, "brain", 1, true) or string.find(techLower, "transplant", 1, true)) then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Only Brain Transplant users can body hop.")
			return
		end
		local stage = tostring(stats.TechniqueEvolutionStage or "Dormant")
		if stage ~= "Extension Technique" and stage ~= "Maximum Technique" and stage ~= "Domain Seed" and stage ~= "Complete Domain" then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Evolve Brain Transplant to its Body Hopping stage first.")
			return
		end

		local oldName = tostring(stats.Name or "Unknown")
		local oldAge = tonumber(stats.Age) or 0

		local originData = nil
		for _, origin in ipairs(BitKaisenStats.Origins or {}) do
			if origin.DisplayName == stats.Clan or origin.DisplayName == stats.Origin then
				originData = origin
				break
			end
		end

		local gender = tostring(stats.Gender or "Unknown")
		local identity = BitKaisenStats.GenerateRandomIdentity(originData, gender)
		stats.PreviousLifeName = oldName
		stats.FirstName = identity.FirstName
		stats.FamilyName = identity.FamilyName
		stats.Name = identity.FullName
		stats.Gender = identity.Gender

		local currentYear = (tonumber(stats.BirthYear) or 0) + (tonumber(stats.Age) or 0)
		local newAge = math.random(16, 20)
		stats.Age = newAge
		stats.BirthYear = currentYear - newAge
		stats.MonthsIntoAge = 0
		stats.CurrentMonth = 1
		stats.ActivitiesDoneThisAge = 0
		stats.Health = 100
		stats.Happiness = math.clamp(math.random(70, 90), 0, 100)

		stats.RCTOldAgeYearsRemaining = 0
		stats.RCTRevivesThisLife = 0

		stats.InJujutsuHigh = false
		stats.JujutsuHighYear = 0
		stats.JujutsuHighPopularity = 0

		stats.JobTitle = "Unemployed"
		stats.JobLevel = 0
		stats.JobExperience = 0
		stats.JobYearsWorked = 0
		stats.JobSalary = 0
		stats.JobApplicationsThisYear = 0

		stats.BodyHopsUsed = (tonumber(stats.BodyHopsUsed) or 0) + 1

		logMessage = tAct(player, "body_hop", { old_name = oldName, old_age = oldAge, new_name = stats.Name, new_age = stats.Age, hops = stats.BodyHopsUsed },
			"<font color='#b27aff'><b>[ BODY HOP ]</b></font> You abandoned <b>" .. oldName .. "</b> (age " .. tostring(oldAge) .. ") and transplanted your brain into a new host." ..
			"\nNew identity: <b>" .. tostring(stats.Name) .. "</b>, age <b>" .. tostring(stats.Age) .. "</b>." ..
			"\nYour cursed energy, technique mastery, and knowledge carried over." ..
			"\nTotal body hops: <b>" .. tostring(stats.BodyHopsUsed) .. "</b>.")

		fireMajorPopup(player, "BODY HOP", "Your brain found a new host.", tostring(stats.Name) .. ", Age " .. tostring(stats.Age), "CE, technique, mastery, and smarts preserved. Body hops: " .. tostring(stats.BodyHopsUsed))

	elseif activityId == "jujutsu_school_event" then
		if stats.InJujutsuHigh ~= true then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need to be enrolled in Jujutsu High to attend school events.")
			return
		end
		local popGain = math.random(5, 12)
		local affGain = math.random(2, 6)
		stats.JujutsuHighPopularity = math.clamp((tonumber(stats.JujutsuHighPopularity) or 0) + popGain, 0, 100)
		stats.AffiliationReputation = math.clamp((tonumber(stats.AffiliationReputation) or 0) + affGain, 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(2, 6), 0, 100)
		logMessage = tAct(player, "jh_school_event", { pop = popGain, aff = affGain }, "You attended a Jujutsu High event and spent time with peers. Popularity <b>+" .. tostring(popGain) .. "</b>, Affiliation Reputation <b>+" .. tostring(affGain) .. "</b>.")

	elseif activityId == "goodwill_event" then
		if stats.InJujutsuHigh ~= true then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need to be enrolled in Jujutsu High for the Goodwill Event.")
			return
		end
		local power = (tonumber(stats.CursedEnergy) or 0) + ((tonumber(stats.TechniqueMastery) or 0) * 1.4) + ((tonumber(stats.Smarts) or 0) * 0.5) + math.random(1, 80)
		local win = power >= 115
		local injury = math.random(4, win and 12 or 24)
		stats.Health = math.clamp((stats.Health or 100) - injury, 0, 100)
		stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + math.random(3, 8), 0, 100)
		stats.CursedEnergy += math.random(8, 18)
		if win then
			stats.GoodwillWins = math.max(0, (tonumber(stats.GoodwillWins) or 0) + 1)
			stats.JujutsuHighPopularity = math.clamp((tonumber(stats.JujutsuHighPopularity) or 0) + math.random(10, 18), 0, 100)
			stats.AffiliationReputation = math.clamp((tonumber(stats.AffiliationReputation) or 0) + math.random(8, 14), 0, 100)
			logMessage = tAct(player, "goodwill_win", { dmg = injury }, "You fought in the Goodwill Event and helped your school win. Health <b>-" .. tostring(injury) .. "</b>.") .. adjustWorldReputation(stats, 4, 2, 4)
			fireMajorPopup(player, "GOODWILL EVENT", "Your school won the exchange contest.", "Victory", "Popularity and affiliation standing increased.")
		else
			stats.JujutsuHighPopularity = math.clamp((tonumber(stats.JujutsuHighPopularity) or 0) + math.random(2, 6), 0, 100)
			logMessage = tAct(player, "goodwill_lose", { dmg = injury }, "You fought in the Goodwill Event but your school lost the exchange. Health <b>-" .. tostring(injury) .. "</b>.") .. adjustWorldReputation(stats, 1, 1, 1)
		end

	elseif activityId == "underground_tournament" then
		if (stats.Age or 0) < 16 or tostring(stats.Grade or "Non-Sorcerer") == "Non-Sorcerer" then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need to be an adult sorcerer before entering underground tournaments.")
			return
		end

		local wins, opponents, playerPower = runUndergroundTournament(stats)
		local finalOpponent = opponents[math.max(1, math.min(#opponents, wins + 1))]
		local cash = ({ 300, 900, 2200, 5200 })[wins + 1] or 300
		local ceGain = math.random(4, 8) + (wins * math.random(3, 7))
		local masteryGain = math.random(1, 3) + wins
		local injury = math.random(4, 12 + (3 - wins) * 6)
		local resultTitle = wins >= 3 and "Champion" or (wins == 2 and "Finalist" or (wins == 1 and "Semifinalist" or "Eliminated"))
		local opponentText = finalOpponent and (finalOpponent.Name .. " (" .. finalOpponent.Title .. ")") or "the bracket"

		stats.TournamentRuns = math.max(0, (tonumber(stats.TournamentRuns) or 0) + 1)
		stats.TournamentBestStreak = math.max(tonumber(stats.TournamentBestStreak) or 0, wins)
		if wins >= 3 then
			stats.TournamentsWon = math.max(0, (tonumber(stats.TournamentsWon) or 0) + 1)
		end

		stats.Money = math.max(0, (tonumber(stats.Money) or 0) + cash)
		stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + ceGain)
		stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + masteryGain, 0, 100)
		stats.Health = math.clamp((tonumber(stats.Health) or 100) - injury, 0, 100)
		stats.Reputation = (tonumber(stats.Reputation) or 0) + math.max(1, wins * 3)

		local repNote = adjustWorldReputation(stats, wins + (wins >= 3 and 3 or 0), math.max(1, wins), wins + 1)
		logMessage = tAct(player, "tournament", { result = resultTitle, opponent = opponentText, power = playerPower, money = cash, ce = ceGain, mastery = masteryGain, dmg = injury },
			"You entered an underground tournament and finished as <b>" .. resultTitle .. "</b>. Last bracket pressure: <b>" .. opponentText .. "</b>. Power read: <b>" .. tostring(playerPower) .. "</b>. Money <b>+$" .. tostring(cash) .. "</b>, CE <b>+" .. tostring(ceGain) .. "</b>, Technique Mastery <b>+" .. tostring(masteryGain) .. "%</b>, Health <b>-" .. tostring(injury) .. "</b>.") .. repNote

		if wins >= 3 then
			fireMajorPopup(player, "TOURNAMENT CHAMPION", "You cleared the underground bracket.", "Champion", "Your name spread through unofficial sorcerer circles.")
		elseif wins == 0 then
			fireMajorPopup(player, "TOURNAMENT LOSS", "The bracket exposed a gap in your current combat level.", "Eliminated", "Train before trying another run.")
		end

	elseif activityId == "bulk_train_ce" then
		local sessions = 5
		local ceGain = math.random(18, 34)
		local healthCost = math.random(7, 16)
		stats.CursedEnergy += ceGain
		stats.Health = math.clamp((stats.Health or 100) - healthCost, 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(1, 5), 0, 100)
		logMessage = tAct(player, "bulk_train_ce", { sessions = sessions, ce = ceGain, dmg = healthCost }, "You compressed <b>" .. tostring(sessions) .. "</b> cursed-energy sessions into one block. CE <b>+" .. tostring(ceGain) .. "</b>, Health <b>-" .. tostring(healthCost) .. "</b>.")

	elseif activityId == "bulk_practice_technique" then
		local technique = tostring(stats.CursedTechnique or "None")
		if technique == "None" then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need an awakened cursed technique before bulk practice.")
			return
		end
		local masteryGain = math.random(10, 20)
		local ceGain = math.random(10, 22)
		local healthCost = math.random(8, 18)
		stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + masteryGain, 0, 100)
		stats.CursedEnergy += ceGain
		stats.Health = math.clamp((stats.Health or 100) - healthCost, 0, 100)
		logMessage = tAct(player, "bulk_practice", { technique = technique, mastery = masteryGain, ce = ceGain, dmg = healthCost }, "You bulk-practiced <b>" .. technique .. "</b>. Technique Mastery <b>+" .. tostring(masteryGain) .. "%</b>, CE <b>+" .. tostring(ceGain) .. "</b>, Health <b>-" .. tostring(healthCost) .. "</b>.")

	elseif activityId == "bulk_mission_sweep" then
		local missions = 3
		local completed = 0
		local failed = 0
		local damage = 0
		for _ = 1, missions do
			local chance = math.clamp(45 + math.floor((tonumber(stats.CursedEnergy) or 0) / 8) + math.floor((tonumber(stats.TechniqueMastery) or 0) / 8) + math.floor((tonumber(stats.Smarts) or 0) / 12), 25, 90)
			if math.random(1, 100) <= chance then
				completed += 1
			else
				failed += 1
				damage += math.random(4, 12)
			end
		end
		stats.MissionsCompleted = math.max(0, (tonumber(stats.MissionsCompleted) or 0) + completed)
		stats.MissionsFailed = math.max(0, (tonumber(stats.MissionsFailed) or 0) + failed)
		stats.CursedEnergy += completed * math.random(4, 8)
		stats.Money += completed * math.random(180, 420)
		stats.Reputation += completed * math.random(1, 3)
		stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
		logMessage = tAct(player, "bulk_mission", { completed = completed, failed = failed }, "You ran a bulk mission sweep: <b>" .. tostring(completed) .. "</b> cleared, <b>" .. tostring(failed) .. "</b> failed.")
		if damage > 0 then
			logMessage ..= tAct(player, "bulk_mission_injury", { dmg = damage }, " Health <b>-" .. tostring(damage) .. "</b>.")
		end
		logMessage ..= adjustWorldReputation(stats, completed, failed, completed)

	elseif activityId == "premium_select_clan" then
		local cost = 5000
		if (tonumber(stats.Money) or 0) < cost then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need $" .. tostring(cost) .. " to roll a featured clan.")
			return
		end
		local featuredPool = {
			{ Clan = "Inumaki Clan", Family = "Inumaki", CE = 14, Weight = 25 },
			{ Clan = "Kamo Clan", Family = "Kamo", CE = 16, Weight = 22 },
			{ Clan = "Zenin Clan", Family = "Zenin", CE = 18, Weight = 18 },
			{ Clan = "Fushiguro Lineage", Family = "Fushiguro", CE = 18, Weight = 14 },
			{ Clan = "Itadori Lineage", Family = "Itadori", CE = 18, Weight = 12 },
			{ Clan = "Gojo Clan", Family = "Gojo", CE = 26, Weight = 5 },
			{ Clan = "Ryomen Clan", Family = "Ryomen", CE = 30, Weight = 2 },
		}
		local totalWeight = 0
		for _, entry in ipairs(featuredPool) do totalWeight += entry.Weight end
		local roll = math.random() * totalWeight
		local running = 0
		local selected = featuredPool[1]
		for _, entry in ipairs(featuredPool) do
			running += entry.Weight
			if roll <= running then selected = entry break end
		end
		stats.Money -= cost
		stats.UnlockedPremiumClans = stats.UnlockedPremiumClans or {}
		stats.UnlockedPremiumClans[selected.Clan] = true
		stats.Clan = selected.Clan
		stats.Origin = selected.Clan
		stats.FamilyName = selected.Family
		stats.FamilyType = "Sorcerer"
		stats.CursedEnergy += selected.CE
		logMessage = tAct(player, "premium_clan", { clan = selected.Clan, ce = selected.CE }, "You rolled a featured clan path: <b>" .. selected.Clan .. "</b>. CE <b>+" .. tostring(selected.CE) .. "</b>.")

	elseif activityId == "premium_select_ct" then
		local cost = 7500
		if (tonumber(stats.Money) or 0) < cost or tostring(stats.CursedTechnique or "None") ~= "None" then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need $" .. tostring(cost) .. " and no awakened cursed technique to select a featured CT.")
			return
		end
		stats.Money -= cost
		stats.UnlockedPremiumTechniques = stats.UnlockedPremiumTechniques or {}
		stats.UnlockedPremiumTechniques.Shrine = true
		stats.CursedTechnique = "Shrine"
		stats.InnateTechnique = "Shrine"
		stats.TechniqueKnown = true
		stats.TechniqueUsable = true
		stats.TechniqueAwakened = true
		stats.TechniqueMastery = math.max(tonumber(stats.TechniqueMastery) or 0, 10)
		logMessage = tAct(player, "premium_ct", nil, "You selected a featured cursed technique: <b>Shrine</b>.")
		fireMajorPopup(player, "FEATURED TECHNIQUE", "A premium technique path was selected.", "Shrine", "Technique evolution can now follow the Shrine line.")

	elseif activityId == "era_lore_encounter" then
		local era = tostring(stats.CurrentEra or stats.Era or "Modern Era")
		stats.EraLoreDiscoveries = math.max(0, tonumber(stats.EraLoreDiscoveries) or 0) + 1

		if era == "Heian Era" then
			stats.HeianEraEncounters = math.max(0, tonumber(stats.HeianEraEncounters) or 0) + 1
			local roll = math.random(1, 100)
			local damage = math.random(10, 26)
			stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
			if roll <= 35 then
				local ceGain = math.random(18, 34)
				local fearGain = math.random(4, 9)
				stats.LastEraLoreOutcome = "Heian Clan War"
				stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + ceGain)
				stats.ClanReputation = math.clamp((tonumber(stats.ClanReputation) or 0) + math.random(3, 8), 0, 100)
				stats.Fear = math.clamp((tonumber(stats.Fear) or 0) + fearGain, 0, 100)
				logMessage = "A Heian clan war swallowed the road. You survived by force. CE <b>+" .. tostring(ceGain) .. "</b>, Fear <b>+" .. tostring(fearGain) .. "</b>, Health <b>-" .. tostring(damage) .. "</b>." .. adjustWorldReputation(stats, 2, 4, 4)
			elseif roll <= 70 then
				local masteryGain = math.random(4, 9)
				stats.LastEraLoreOutcome = "Heian Onmyoji Lesson"
				stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + masteryGain, 0, 100)
				stats.Smarts = math.clamp((tonumber(stats.Smarts) or 0) + math.random(2, 5), 0, 100)
				logMessage = "A Heian onmyoji forced you through a brutal lesson. Technique Mastery <b>+" .. tostring(masteryGain) .. "</b>, Health <b>-" .. tostring(damage) .. "</b>." .. adjustWorldReputation(stats, 1, 2, 3)
			else
				stats.LastEraLoreOutcome = "Heian Named Curse"
				stats.SpecialGradeThreatsSurvived = math.max(0, tonumber(stats.SpecialGradeThreatsSurvived) or 0) + 1
				stats.WorldPressure = math.clamp((tonumber(stats.WorldPressure) or 0) + math.random(4, 10), 0, 100)
				stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + math.random(10, 22))
				logMessage = "A named Heian curse noticed you and left a mark on the era. Special threats survived <b>+1</b>, Health <b>-" .. tostring(damage) .. "</b>." .. adjustWorldReputation(stats, 2, 5, 5)
				fireMajorPopup(player, "HEIAN CALAMITY", "A named curse remembered your face.", "Survived", "World pressure and fear around you increased.")
			end
		elseif era == "Edo Era" then
			stats.EdoEraEncounters = math.max(0, tonumber(stats.EdoEraEncounters) or 0) + 1
			local roll = math.random(1, 100)
			local damage = math.random(6, 18)
			stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
			if roll <= 45 then
				local masteryGain = math.random(5, 11)
				stats.LastEraLoreOutcome = "Edo Lightning Duel"
				stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + masteryGain, 0, 100)
				stats.Reputation = (tonumber(stats.Reputation) or 0) + math.random(2, 5)
				logMessage = "An Edo lightning-fast challenger demanded a duel. Technique Mastery <b>+" .. tostring(masteryGain) .. "</b>, Health <b>-" .. tostring(damage) .. "</b>." .. adjustWorldReputation(stats, 2, 2, 3)
			elseif roll <= 78 then
				stats.LastEraLoreOutcome = "Edo Wandering Dojo"
				stats.DojoReputation = math.max(0, (tonumber(stats.DojoReputation) or 0) + math.random(3, 8))
				stats.DojoLegacy = math.clamp((tonumber(stats.DojoLegacy) or 0) + math.random(2, 5), 0, 100)
				logMessage = "A wandering Edo dojo tested your discipline. Dojo Reputation and Legacy increased. Health <b>-" .. tostring(damage) .. "</b>." .. adjustWorldReputation(stats, 1, 1, 2)
			else
				local anchorGain = math.random(5, 12)
				stats.LastEraLoreOutcome = "Edo Cursed Relic"
				stats.CursedObjectAnchorProgress = math.clamp((tonumber(stats.CursedObjectAnchorProgress) or 0) + anchorGain, 0, 100)
				stats.Smarts = math.clamp((tonumber(stats.Smarts) or 0) + math.random(1, 4), 0, 100)
				logMessage = "You found an Edo cursed relic sealed under old rites. Cursed Object Anchor Progress <b>+" .. tostring(anchorGain) .. "</b>, Health <b>-" .. tostring(damage) .. "</b>."
			end
		else
			stats.ModernEraEncounters = math.max(0, tonumber(stats.ModernEraEncounters) or 0) + 1
			local roll = math.random(1, 100)
			if roll <= 40 then
				stats.LastEraLoreOutcome = "Modern Sealed Game Rumor"
				stats.Smarts = math.clamp((tonumber(stats.Smarts) or 0) + math.random(3, 7), 0, 100)
				stats.CursedObjectAnchorProgress = math.clamp((tonumber(stats.CursedObjectAnchorProgress) or 0) + math.random(3, 8), 0, 100)
				logMessage = "A modern schemer offered information about sealed games and old contracts. Smarts and cursed object progress increased."
			elseif roll <= 75 then
				stats.LastEraLoreOutcome = "Modern Rogue Network"
				stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + math.random(2, 6), 0, 100)
				stats.Money = math.max(0, (tonumber(stats.Money) or 0) + math.random(300, 900))
				logMessage = "A modern rogue network paid for information, but your name moved through unsafe channels. Money increased, Wanted Level rose."
			else
				stats.LastEraLoreOutcome = "Modern Society Leak"
				stats.SocietyRecognition = math.max(0, (tonumber(stats.SocietyRecognition) or 0) + math.random(2, 7))
				stats.WorldAttention = math.clamp((tonumber(stats.WorldAttention) or 0) + math.random(2, 6), 0, 100)
				logMessage = "A leak from jujutsu society revealed hidden politics. Society Recognition and World Attention increased."
			end
		end

	elseif activityId == "star_plasma_guard" then
		local vesselName = "Star Plasma Vessel"
		local power = (tonumber(stats.CursedEnergy) or 0) + ((tonumber(stats.TechniqueMastery) or 0) * 1.5) + ((tonumber(stats.Smarts) or 0) * 0.7) + math.random(1, 90)
		local success = power >= 130
		local damage = math.random(8, success and 18 or 34)
		stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
		stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + math.random(3, 8), 0, 100)
		stats.CursedEnergy += math.random(8, 20)
		if success then
			stats.Reputation += math.random(6, 12)
			stats.Fame = math.clamp((tonumber(stats.Fame) or 0) + math.random(4, 9), 0, 100)
			stats.AffiliationReputation = math.clamp((tonumber(stats.AffiliationReputation) or 0) + math.random(4, 10), 0, 100)
			logMessage = "You protected the <b>" .. vesselName .. "</b> through the escort arc. The job left scars, but your name spread. Health <b>-" .. tostring(damage) .. "</b>." .. adjustWorldReputation(stats, 5, 2, 4)
			fireMajorPopup(player, "STAR PLASMA GUARD", "The vessel survived the escort.", "Protected", "Your reputation rose sharply.")
		else
			stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(8, 18), 0, 100)
			stats.Fear = math.clamp((tonumber(stats.Fear) or 0) + math.random(3, 8), 0, 100)
			logMessage = "The <b>" .. vesselName .. "</b> escort collapsed under pressure. You survived the ambush, but the failure followed you. Health <b>-" .. tostring(damage) .. "</b>." .. adjustWorldReputation(stats, 1, 4, 1)
		end

	elseif activityId == "assassination_attempt" then
		local bountyPressure = (tonumber(stats.Fame) or 0) + (tonumber(stats.Fear) or 0) + math.floor((tonumber(stats.Reputation) or 0) / 2)
		local power = (tonumber(stats.CursedEnergy) or 0) + (tonumber(stats.TechniqueMastery) or 0) + math.random(1, 90)
		local survivedCleanly = power >= 70 + math.floor(bountyPressure / 2)
		local damage = math.random(survivedCleanly and 3 or 12, survivedCleanly and 14 or 35)
		stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
		stats.CursedEnergy += math.random(4, 14)
		if survivedCleanly then
			stats.Fear = math.clamp((tonumber(stats.Fear) or 0) + math.random(3, 7), 0, 100)
			stats.Money += math.random(300, 900)
			logMessage = "An assassin came for your head. You turned the ambush around and collected what they carried. Health <b>-" .. tostring(damage) .. "</b>." .. adjustWorldReputation(stats, 2, 4, 2)
		else
			stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(4, 10), 0, 100)
			logMessage = "An assassin nearly ended your run. You escaped, but the wound and the warning were real. Health <b>-" .. tostring(damage) .. "</b>." .. adjustWorldReputation(stats, 1, 2, 1)
		end

	elseif activityId == "assistant_manage_dojo" then
		if not stats.AssistantName then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need an assigned assistant first.")
			return
		end
		local adminGain = math.random(3, 8)
		local trustGain = math.random(2, 6)
		stats.AssistantTrust = math.clamp((tonumber(stats.AssistantTrust) or 0) + trustGain, 0, 100)
		stats.AssistantSkill = math.clamp((tonumber(stats.AssistantSkill) or 0) + math.random(1, 4), 0, 100)
		stats.AffiliationReputation = math.clamp((tonumber(stats.AffiliationReputation) or 0) + math.random(1, 4), 0, 100)
		if stats.ClanFounded == true then
			stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) + adminGain)
			stats.DojoPrestige = math.max(0, (tonumber(stats.DojoPrestige) or 0) + math.random(1, 4))
		end
		logMessage = "<b>" .. tostring(stats.AssistantName) .. "</b> handled clan and dojo administration. Assistant Trust <b>+" .. tostring(trustGain) .. "</b>." .. (stats.ClanFounded == true and " Clan reputation <b>+" .. tostring(adminGain) .. "</b>." or "")

	elseif activityId == "assistant_train_npcs" then
		if not stats.AssistantName then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need an assigned assistant first.")
			return
		end
		local trained = 0
		local progressGain = math.random(4, 10)
		for _, relationship in ipairs(stats.Relationships or {}) do
			if relationship and relationship.Alive ~= false and (relationship.Role == "Student" or relationship.Role == "Ward" or relationship.Role == "Child") then
				trained += 1
				relationship.DojoProgress = math.max(0, (tonumber(relationship.DojoProgress) or 0) + progressGain)
				relationship.CursedEnergy = math.max(0, (tonumber(relationship.CursedEnergy) or 0) + math.random(1, 4))
				relationship.Respect = math.clamp((tonumber(relationship.Respect) or 0) + math.random(1, 3), 0, 100)
				if tostring(relationship.CursedTechnique or "None") ~= "None" then
					relationship.TechniqueMastery = math.clamp((tonumber(relationship.TechniqueMastery) or 0) + math.random(0, 2), 0, 100)
				end
			end
		end
		stats.AssistantSkill = math.clamp((tonumber(stats.AssistantSkill) or 0) + math.random(3, 7), 0, 100)
		stats.AssistantTrust = math.clamp((tonumber(stats.AssistantTrust) or 0) + math.random(1, 4), 0, 100)
		logMessage = "<b>" .. tostring(stats.AssistantName) .. "</b> trained <b>" .. tostring(trained) .. "</b> connected NPC(s). Student progress <b>+" .. tostring(progressGain) .. "</b>."

	elseif activityId == "assistant_field_support" then
		if not stats.AssistantName then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need an assigned assistant first.")
			return
		end
		local support = math.floor((tonumber(stats.AssistantSkill) or 0) / 8) + math.random(4, 12)
		local damage = math.max(0, math.random(6, 18) - math.floor(support / 4))
		stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
		stats.MissionsCompleted = math.max(0, (tonumber(stats.MissionsCompleted) or 0) + 1)
		stats.Money += math.random(220, 650)
		stats.Reputation += math.random(1, 4)
		stats.AssistantTrust = math.clamp((tonumber(stats.AssistantTrust) or 0) + math.random(3, 8), 0, 100)
		stats.AssistantSkill = math.clamp((tonumber(stats.AssistantSkill) or 0) + math.random(2, 6), 0, 100)
		logMessage = "<b>" .. tostring(stats.AssistantName) .. "</b> accompanied you on a field assignment and covered the gaps. Mission completed. Health <b>-" .. tostring(damage) .. "</b>." .. adjustWorldReputation(stats, 1, 0, 1)

	elseif activityId == "fame_public_audience" then
		local fame = tonumber(stats.Fame) or 0
		local support = math.clamp(tonumber(stats.PublicSupport) or 0, 0, 100)
		local moneyGain = math.random(120, 420) + math.floor(fame * 8) + math.floor(support * 5)
		local repGain = math.random(2, 6) + math.floor(fame / 20) + math.floor(support / 25)
		local supportGain = math.random(3, 7) + math.floor(fame / 25)
		stats.Money += moneyGain
		stats.Reputation += repGain
		stats.PublicSupport = math.clamp(support + supportGain, 0, 100)
		stats.AffiliationReputation = math.clamp((tonumber(stats.AffiliationReputation) or 0) + math.random(1, 4), 0, 100)
		stats.JujutsuHighPopularity = math.clamp((tonumber(stats.JujutsuHighPopularity) or 0) + math.random(1, 5), 0, 100)
		local supportText = " Public Support <b>+" .. tostring(supportGain) .. "</b>."
		if stats.PublicSupport >= 25 then
			local supportSpent = math.min(stats.PublicSupport, math.random(4, 9))
			stats.PublicSupport = math.max(0, stats.PublicSupport - supportSpent)
			stats.HunterPressure = math.clamp((tonumber(stats.HunterPressure) or 0) - math.floor(supportSpent * 1.5), 0, 100)
			stats.WorldPressure = math.clamp((tonumber(stats.WorldPressure) or 0) - math.floor(supportSpent * 0.8), 0, 100)
			supportText ..= " Supporters quietly disrupted hunter attention. Hunter Pressure <b>-" .. tostring(math.floor(supportSpent * 1.5)) .. "</b>."
		end
		logMessage = "Your name carried weight before you even entered the room. NPCs offered help, money, and safer access. Money <b>+$" .. tostring(moneyGain) .. "</b>, Reputation <b>+" .. tostring(repGain) .. "</b>." .. supportText

	elseif activityId == "fear_intimidate_network" then
		local fear = tonumber(stats.Fear) or 0
		local hunterPressure = math.clamp(tonumber(stats.HunterPressure) or 0, 0, 100)
		local cash = math.random(80, 260) + math.floor(fear * 5)
		local hunterRisk = math.clamp(8 + math.floor(fear / 3) + math.floor(hunterPressure / 4), 8, 70)
		stats.Money += cash
		stats.Fear = math.clamp(fear + math.random(1, 4), 0, 100)
		stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + math.random(0, 3), 0, 100)
		if math.random(1, 100) <= hunterRisk then
			local damage = math.random(5, 18)
			local pressureGain = math.random(2, 6)
			stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
			stats.HunterPressure = math.clamp(hunterPressure + pressureGain, 0, 100)
			logMessage = "People moved because they feared you, but the pressure attracted a hostile hunter. Money <b>+$" .. tostring(cash) .. "</b>, Health <b>-" .. tostring(damage) .. "</b>, Hunter Pressure <b>+" .. tostring(pressureGain) .. "</b>." .. adjustWorldReputation(stats, 0, 3, 1)
		else
			local pressureDrop = math.random(2, 5) + math.floor(fear / 30)
			stats.HunterPressure = math.clamp(hunterPressure - pressureDrop, 0, 100)
			logMessage = "Your fear network worked. NPCs backed down, enemies hesitated, and hunter informants went quiet. Money <b>+$" .. tostring(cash) .. "</b>, Hunter Pressure <b>-" .. tostring(pressureDrop) .. "</b>." .. adjustWorldReputation(stats, 0, 2, 1)
		end

	elseif activityId == "society_influence_push" then
		local missionScore = math.max(0, tonumber(stats.MissionsCompleted) or 0)
		local fame = tonumber(stats.Fame) or 0
		local affiliation = tonumber(stats.AffiliationReputation) or 0
		local currentInfluence = tonumber(stats.SocietyInfluence) or 0
		local councilSeats = math.max(0, tonumber(stats.CouncilSeats) or 0)
		local influenceGain = math.clamp(math.random(3, 7) + math.floor(fame / 25) + math.floor(affiliation / 30) + math.floor(missionScore / 18) + councilSeats, 3, 17)
		local recognitionGain = math.random(3, 8) + math.floor(councilSeats / 2)
		stats.CouncilCampaigns = math.max(0, tonumber(stats.CouncilCampaigns) or 0) + 1
		stats.SocietyInfluence = math.clamp(currentInfluence + influenceGain, 0, 100)
		stats.SocietyRecognition = math.max(0, (tonumber(stats.SocietyRecognition) or 0) + recognitionGain)
		stats.AffiliationReputation = math.clamp((tonumber(stats.AffiliationReputation) or 0) + math.random(1, 4), 0, 100)

		local outcomeText = ""
		local seatChance = math.clamp(math.floor((stats.SocietyInfluence - 45) * 0.7) + math.floor(fame / 8) + math.floor(affiliation / 10) + math.floor(missionScore / 12) + (councilSeats * 6), 0, 82)
		local policyChance = math.clamp(math.floor((stats.SocietyInfluence - 25) * 0.65) + math.floor(affiliation / 12) + (councilSeats * 8), 0, 78)

		if stats.SocietyInfluence >= 60 and councilSeats < 3 and math.random(1, 100) <= seatChance then
			stats.CouncilSeats = councilSeats + 1
			stats.LastSocietyOutcome = "Council Seat Won"
			stats.SocietyPolicyWins = math.max(0, tonumber(stats.SocietyPolicyWins) or 0) + 1
			stats.WorldPressure = math.clamp((tonumber(stats.WorldPressure) or 0) - math.random(2, 6), 0, 100)
			outcomeText = " You won a council seat. Council Seats <b>+1</b>, and society pressure eased."
			fireMajorPopup(player, "COUNCIL SEAT", "Your influence reached the inner table of Jujutsu Society.", "Seat Won", "Council seats improve future society and clan politics outcomes.")
		elseif stats.SocietyInfluence >= 35 and math.random(1, 100) <= policyChance then
			stats.SocietyPolicyWins = math.max(0, tonumber(stats.SocietyPolicyWins) or 0) + 1
			stats.LastSocietyOutcome = "Policy Win"
			stats.WorldPressure = math.clamp((tonumber(stats.WorldPressure) or 0) - math.random(1, 4), 0, 100)
			stats.JujutsuHighPopularity = math.clamp((tonumber(stats.JujutsuHighPopularity) or 0) + math.random(2, 5), 0, 100)
			outcomeText = " Your proposal shifted a minor policy. Policy Wins <b>+1</b>, and society pressure eased."
		else
			stats.LastSocietyOutcome = "Influence Built"
			outcomeText = " Your name circulated through higher channels."
		end

		if stats.CouncilSeats >= 3 then
			stats.SocietyRank = "Council Authority"
		elseif stats.SocietyInfluence >= 75 then
			stats.SocietyRank = "Council Voice"
		elseif stats.SocietyInfluence >= 50 then
			stats.SocietyRank = "Senior Contact"
		elseif stats.SocietyInfluence >= 25 then
			stats.SocietyRank = "Recognized Operative"
		else
			stats.SocietyRank = "Known Sorcerer"
		end
		logMessage = "You used your public name and mission record to influence Jujutsu Society. Society Influence <b>+" .. tostring(influenceGain) .. "</b>, Recognition <b>+" .. tostring(recognitionGain) .. "</b>. Rank: <b>" .. tostring(stats.SocietyRank) .. "</b>." .. outcomeText .. adjustWorldReputation(stats, 2, 0, 2)
		if stats.LastSocietyOutcome ~= "Council Seat Won" then
			fireMajorPopup(player, "SOCIETY INFLUENCE", "Your standing inside Jujutsu Society increased.", tostring(stats.SocietyRank), "Higher influence can unlock policy wins and council seats.")
		end

	elseif activityId == "clan_leadership_council" then
		local influence = tonumber(stats.SocietyInfluence) or 0
		local clanRep = tonumber(stats.ClanReputation) or tonumber(stats.FamilyReputation) or 0
		local powerGain = math.clamp(math.random(4, 9) + math.floor(influence / 25) + math.floor(clanRep / 25), 4, 16)
		stats.ClanPoliticalPower = math.clamp((tonumber(stats.ClanPoliticalPower) or 0) + powerGain, 0, 100)
		stats.FamilyReputation = math.max(0, (tonumber(stats.FamilyReputation) or 0) + math.random(2, 6))
		stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) + math.random(1, 5))
		if stats.ClanPoliticalPower >= 70 then
			stats.ClanLeadership = "Clan Head"
		elseif stats.ClanPoliticalPower >= 40 then
			stats.ClanLeadership = "Council Elder"
		else
			stats.ClanLeadership = "Faction Leader"
		end
		stats.ClanMergeRequestsSent = math.max(0, tonumber(stats.ClanMergeRequestsSent) or 0) + 1
		logMessage = "You attended a clan leadership council and pushed your family's position. Clan Political Power <b>+" .. tostring(powerGain) .. "</b>. Leadership: <b>" .. tostring(stats.ClanLeadership) .. "</b>."
		fireMajorPopup(player, "CLAN POLITICS", "Your family gained more weight in sorcerer politics.", tostring(stats.ClanLeadership), "Future clan merge and leadership systems can build from this power.")

	elseif activityId == "dojo_legacy_ceremony" then
		local studentCount = 0
		local strongestStudent
		local strongestScore = -1
		for _, relationship in ipairs(stats.Relationships or {}) do
			if relationship and relationship.Alive ~= false and (relationship.Role == "Student" or relationship.Role == "Ward") then
				studentCount += 1
				local studentScore = (tonumber(relationship.CursedEnergy) or 0) + ((tonumber(relationship.TechniqueMastery) or 0) * 2) + (tonumber(relationship.Trust) or 0)
				if studentScore > strongestScore then
					strongestScore = studentScore
					strongestStudent = relationship
				end
			end
		end

		local ceremonyCount = math.max(0, tonumber(stats.DojoLegacyCeremonies) or 0) + 1
		local legacyGain = math.clamp(math.random(5, 11) + math.floor(studentCount / 2) + math.floor((tonumber(stats.DojoReputation) or 0) / 25) + math.floor(ceremonyCount / 3), 5, 22)
		local protectionGain = math.clamp(math.floor(legacyGain / 4) + math.floor(studentCount / 3), 1, 8)
		stats.DojoLegacyCeremonies = ceremonyCount
		stats.LastDojoLegacyAge = tonumber(stats.Age) or 0
		stats.DojoLegacy = math.clamp((tonumber(stats.DojoLegacy) or 0) + legacyGain, 0, 100)
		stats.DojoProtectionBonus = math.clamp((tonumber(stats.DojoProtectionBonus) or 0) + protectionGain, 0, 35)
		stats.DojoReputation = math.max(0, (tonumber(stats.DojoReputation) or 0) + math.random(3, 8))
		stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) + math.random(2, 6))

		if stats.DojoLegacy >= 85 then
			stats.DojoRank = "Legendary Legacy Dojo"
			stats.DojoLegacyTier = "Legendary"
		elseif stats.DojoLegacy >= 60 then
			stats.DojoRank = "Legacy Dojo"
			stats.DojoLegacyTier = "Established"
		elseif stats.DojoLegacy >= 30 then
			stats.DojoRank = "Respected Dojo"
			stats.DojoLegacyTier = "Recognized"
		else
			stats.DojoRank = "Growing Dojo"
			stats.DojoLegacyTier = "Growing"
		end

		local successorNamed = false
		if strongestStudent and math.random(1, 100) <= math.clamp(35 + studentCount * 8 + math.floor((tonumber(stats.DojoLegacy) or 0) / 3), 35, 95) then
			strongestStudent.LegacySuccessor = true
			strongestStudent.DojoSuccessor = true
			strongestStudent.Trust = math.clamp((tonumber(strongestStudent.Trust) or 0) + math.random(4, 9), 0, 100)
			stats.DojoSuccessors = math.max(0, tonumber(stats.DojoSuccessors) or 0) + 1
			stats.DojoNamedSuccessors = math.max(0, tonumber(stats.DojoNamedSuccessors) or 0) + 1
			successorNamed = true
		end

		local successorText = successorNamed and (" Named successor: <b>" .. tostring(strongestStudent.Name or "Student") .. "</b>.") or " No successor was ready yet."
		logMessage = "You held a dojo legacy ceremony for your students. Dojo Legacy <b>+" .. tostring(legacyGain) .. "</b>, Protection <b>+" .. tostring(protectionGain) .. "</b>. Tier: <b>" .. tostring(stats.DojoLegacyTier) .. "</b>." .. successorText
		fireMajorPopup(player, "DOJO LEGACY", "Your teachings became part of a longer tradition.", tostring(stats.DojoRank), "Legacy tier, protection, and successor records now persist.")

	elseif activityId == "clan_merge_request" then
		local dojoRep = tonumber(stats.DojoReputation) or 0
		local clanRep = tonumber(stats.ClanReputation) or 0
		local political = tonumber(stats.ClanPoliticalPower) or 0
		local influence = tonumber(stats.SocietyInfluence) or 0
		local fame = tonumber(stats.Fame) or 0
		local fear = tonumber(stats.Fear) or 0
		local allianceScore = math.clamp(10 + math.floor(dojoRep * 0.28) + math.floor(clanRep * 0.22) + math.floor(political * 0.35) + math.floor(influence * 0.18) + math.floor(fame * 0.08) - math.floor(fear * 0.06), 5, 95)
		local roll = math.random(1, 100)
		stats.ClanMergeRequestsSent = math.max(0, tonumber(stats.ClanMergeRequestsSent) or 0) + 1

		if roll <= math.floor(allianceScore * 0.45) then
			stats.ClanMergeAccepted = true
			stats.LastClanMergeOutcome = "Alliance"
			stats.ClanMergeAlliances = math.max(0, tonumber(stats.ClanMergeAlliances) or 0) + 1
			stats.ClanPoliticalPower = math.clamp((tonumber(stats.ClanPoliticalPower) or 0) + math.random(8, 15), 0, 100)
			stats.DojoReputation = math.max(0, (tonumber(stats.DojoReputation) or 0) + math.random(5, 10))
			stats.ClanReputation = math.clamp((tonumber(stats.ClanReputation) or 0) + math.random(4, 9), 0, 100)
			stats.FamilyReputation = math.clamp((tonumber(stats.FamilyReputation) or 0) + math.random(3, 7), 0, 100)
			stats.DojoRaidRisk = math.clamp((tonumber(stats.DojoRaidRisk) or 0) - math.random(6, 14), 0, 100)
			logMessage = "Your clan merge request became a full alliance. Alliances <b>+1</b>, Clan Political Power rose sharply, and your dojo gained stronger raid protection."
			fireMajorPopup(player, "CLAN ALLIANCE FORMED", "Another clan tied its future to your house.", "Alliance Formed", "Clan politics, reputation, and dojo protection increased.")
		elseif roll <= allianceScore then
			stats.ClanMergeAccepted = true
			stats.LastClanMergeOutcome = "Conditional Pact"
			stats.ClanMergePacts = math.max(0, tonumber(stats.ClanMergePacts) or 0) + 1
			stats.ClanPoliticalPower = math.clamp((tonumber(stats.ClanPoliticalPower) or 0) + math.random(4, 8), 0, 100)
			stats.DojoReputation = math.max(0, (tonumber(stats.DojoReputation) or 0) + math.random(2, 5))
			stats.ClanReputation = math.clamp((tonumber(stats.ClanReputation) or 0) + math.random(2, 4), 0, 100)
			stats.DojoRaidRisk = math.clamp((tonumber(stats.DojoRaidRisk) or 0) - math.random(2, 6), 0, 100)
			logMessage = "Your clan merge request was accepted as a conditional pact. Pact count <b>+1</b>, Clan Political Power rose, and raid risk eased slightly."
			fireMajorPopup(player, "CLAN PACT SIGNED", "The other clan agreed to cooperate, but expects proof before a full alliance.", "Conditional Pact", "Keep building clan and dojo reputation to turn pacts into power.")
		elseif roll <= allianceScore + 18 then
			stats.ClanMergeAccepted = false
			stats.LastClanMergeOutcome = "Respectful Rejection"
			stats.ClanMergeRejections = math.max(0, tonumber(stats.ClanMergeRejections) or 0) + 1
			stats.ClanPoliticalPower = math.clamp((tonumber(stats.ClanPoliticalPower) or 0) + math.random(2, 5), 0, 100)
			stats.ClanReputation = math.clamp((tonumber(stats.ClanReputation) or 0) + math.random(1, 3), 0, 100)
			stats.DojoRaidRisk = math.clamp((tonumber(stats.DojoRaidRisk) or 0) + math.random(0, 3), 0, 100)
			logMessage = "Your clan merge request was respectfully rejected. Rejections <b>+1</b>, but the talks still improved your political experience."
		else
			stats.ClanMergeAccepted = false
			stats.LastClanMergeOutcome = "Rivalry"
			stats.ClanMergeRejections = math.max(0, tonumber(stats.ClanMergeRejections) or 0) + 1
			stats.ClanRivalries = math.max(0, tonumber(stats.ClanRivalries) or 0) + 1
			stats.ClanPoliticalPower = math.clamp((tonumber(stats.ClanPoliticalPower) or 0) + math.random(1, 3), 0, 100)
			stats.DojoRaidRisk = math.clamp((tonumber(stats.DojoRaidRisk) or 0) + math.random(8, 18), 0, 100)
			stats.Reputation = math.max(0, (tonumber(stats.Reputation) or 0) - math.random(1, 4))
			local repNote = adjustWorldReputation(stats, 0, 2, 2)
			logMessage = "Your clan merge request insulted the other house. Rivalries <b>+1</b>, raid risk rose, and your reputation took a hit." .. repNote
			fireMajorPopup(player, "CLAN RIVALRY", "The negotiation collapsed into a political feud.", "Rival House", "Your dojo is more likely to be targeted by raids.")
		end

	elseif activityId == "dojo_raid_defense" then
		local legacyProtection = math.clamp(tonumber(stats.DojoProtectionBonus) or 0, 0, 35)
		local raidPressure = math.max(1, math.random(8, 18) - math.floor(legacyProtection / 3))
		stats.DojoRaidRisk = math.clamp((tonumber(stats.DojoRaidRisk) or 0) + raidPressure, 0, 100)
		if beginDojoRaidDefenseMinigame(player, stats) then
			saveStats(player, "dojo raid defense started")
			return
		end
		stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
		fireLifeUpdate(player, stats, "The dojo raid defense drill is not available right now.")
		return

	elseif activityId == "dojo_recovery_work" then
		local condition = math.clamp(tonumber(stats.DojoCondition) or 100, 0, 100)
		local debt = math.max(0, tonumber(stats.DojoRecoveryDebt) or 0)
		if condition >= 100 and debt <= 0 and tostring(stats.DojoRank or "") ~= "Collapsed Dojo" then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Your dojo does not need recovery work right now.")
			return
		end

		local cash = math.max(0, tonumber(stats.Money) or 0)
		local investment = math.min(cash, math.max(450, math.floor(debt * 0.45)))
		local conditionGain = math.random(10, 18) + math.floor(investment / 650) + math.floor((tonumber(stats.DojoProtectionBonus) or 0) / 8)
		local debtPaid = math.min(debt, investment + math.random(350, 900) + math.floor((tonumber(stats.DojoReputation) or 0) * 8))
		stats.Money = math.max(0, cash - investment)
		stats.DojoRecoveryDebt = math.max(0, debt - debtPaid)
		stats.DojoCondition = math.clamp(condition + conditionGain, 0, 100)
		stats.DojoRaidRisk = math.clamp((tonumber(stats.DojoRaidRisk) or 0) - math.random(4, 10), 0, 100)
		stats.DojoReputation = math.max(0, (tonumber(stats.DojoReputation) or 0) + math.random(1, 4))
		stats.DojoProtectionBonus = math.clamp((tonumber(stats.DojoProtectionBonus) or 0) + math.random(0, 2), 0, 35)
		stats.DojoRecoveryProjects = math.max(0, tonumber(stats.DojoRecoveryProjects) or 0) + 1

		local restoredText = ""
		if tostring(stats.DojoRank or "") == "Collapsed Dojo" and (tonumber(stats.DojoCondition) or 0) >= 45 then
			stats.DojoRank = (tonumber(stats.DojoLegacy) or 0) >= 30 and "Respected Dojo" or "Growing Dojo"
			restoredText = " The dojo reopened as a <b>" .. tostring(stats.DojoRank) .. "</b>."
		end

		logMessage = "You organized recovery work after raid damage. Dojo Condition <b>+" .. tostring(conditionGain) .. "</b>, Recovery Debt <b>-" .. tostring(debtPaid) .. "</b>, Raid Risk reduced." .. restoredText
		fireMajorPopup(player, "DOJO RECOVERY", "Your dojo stabilized after the raid damage.", "Recovery Work", "Debt, condition, and raid risk improved.")

	elseif activityId == "rogue_student_incident" then
		local candidates = {}
		for _, relationship in ipairs(stats.Relationships or {}) do
			if relationship and relationship.Alive ~= false and (relationship.Role == "Student" or relationship.Role == "Ward" or relationship.IsClanStudent == true) then
				table.insert(candidates, relationship)
			end
		end
		if #candidates <= 0 then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You do not have any students to confront.")
			return
		end
		local student = candidates[math.random(1, #candidates)]
		local loyalty = math.floor(((tonumber(student.Bond) or 0) + (tonumber(student.Trust) or 0) + (tonumber(student.Respect) or 0)) / 3)
		local chance = math.clamp(55 + math.floor(loyalty / 3) + math.floor((tonumber(stats.DojoLegacy) or 0) / 4), 35, 92)
		stats.RogueStudentIncidents = math.max(0, tonumber(stats.RogueStudentIncidents) or 0) + 1
		if math.random(1, 100) <= chance then
			student.Trust = math.clamp((tonumber(student.Trust) or 0) + math.random(4, 10), 0, 100)
			student.Respect = math.clamp((tonumber(student.Respect) or 0) + math.random(3, 8), 0, 100)
			student.WorldPath = student.WorldPath == "Rogue Sorcerer" and "Sorcerer" or student.WorldPath
			student.Occupation = student.WorldPath == "Sorcerer" and "Dojo Student" or student.Occupation
			stats.DojoLegacy = math.clamp((tonumber(stats.DojoLegacy) or 0) + math.random(2, 6), 0, 100)
			logMessage = "You confronted <b>" .. tostring(student.Name or "a student") .. "</b> before they went rogue. Their trust and respect improved."
		else
			student.WorldPath = "Rogue Sorcerer"
			student.Occupation = "Rogue Sorcerer"
			student.Role = student.Role == "Ward" and "Rival" or student.Role
			student.Trust = math.clamp((tonumber(student.Trust) or 0) - math.random(8, 18), 0, 100)
			student.Fear = math.clamp((tonumber(student.Fear) or 0) + math.random(8, 18), 0, 100)
			stats.DojoRaidRisk = math.clamp((tonumber(stats.DojoRaidRisk) or 0) + math.random(8, 18), 0, 100)
			stats.Health = math.clamp((tonumber(stats.Health) or 100) - math.random(4, 14), 0, 100)
			logMessage = "<b>" .. tostring(student.Name or "A student") .. "</b> rejected your authority and went rogue. They may become a future threat to your dojo."
		end

	elseif activityId == "world_reputation_cleanup" then
		local hunterPressure = math.clamp(tonumber(stats.HunterPressure) or 0, 0, 100)
		local worldPressure = math.clamp(tonumber(stats.WorldPressure) or 0, 0, 100)
		local copycats = math.max(0, tonumber(stats.CopycatIncidents) or 0)
		if hunterPressure < 10 and worldPressure < 35 and copycats <= 0 then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Your public reputation is stable right now.")
			return
		end

		local support = math.clamp(tonumber(stats.PublicSupport) or 0, 0, 100)
		local smarts = math.clamp(tonumber(stats.Smarts) or 0, 0, 100)
		local fame = math.clamp(tonumber(stats.Fame) or 0, 0, 100)
		local cash = math.max(0, tonumber(stats.Money) or 0)
		local spend = math.min(cash, math.random(250, 850) + math.floor(worldPressure * 8))
		local supportSpent = math.min(support, math.random(3, 9) + math.floor(fame / 25))
		local cleanupPower = math.random(5, 11) + math.floor(smarts / 18) + math.floor(fame / 25) + math.floor(supportSpent / 2)
		local hunterDrop = math.min(hunterPressure, cleanupPower + math.random(1, 5))
		local worldDrop = math.min(worldPressure, math.max(1, math.floor(cleanupPower * 0.75)))
		local copycatDrop = copycats > 0 and math.min(copycats, math.random(1, math.max(1, math.min(3, copycats)))) or 0

		stats.Money = math.max(0, cash - spend)
		stats.PublicSupport = math.max(0, support - supportSpent)
		stats.HunterPressure = math.clamp(hunterPressure - hunterDrop, 0, 100)
		stats.WorldPressure = math.clamp(worldPressure - worldDrop, 0, 100)
		stats.CopycatIncidents = math.max(0, copycats - copycatDrop)
		stats.ReputationCleanups = math.max(0, tonumber(stats.ReputationCleanups) or 0) + 1
		stats.LastWorldReputationEvent = "Reputation Cleanup"

		local copycatText = copycatDrop > 0 and (", Copycats <b>-" .. tostring(copycatDrop) .. "</b>") or ""
		logMessage = "You cleaned up public fallout with contacts, support, and careful messaging. Hunter Pressure <b>-" .. tostring(hunterDrop) .. "</b>, World Pressure <b>-" .. tostring(worldDrop) .. "</b>" .. copycatText .. ". Cost <b>$" .. tostring(spend) .. "</b>, Public Support spent <b>" .. tostring(supportSpent) .. "</b>."

	elseif activityId == "heian_blood_moon" then
		local damage = math.random(14, 36)
		local ceGain = math.random(18, 42)
		stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
		stats.CursedEnergy += ceGain
		stats.Fear = math.clamp((tonumber(stats.Fear) or 0) + math.random(5, 12), 0, 100)
		stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) + math.random(2, 8))
		logMessage = "The Heian Blood Moon turned the night into open clan war and curse slaughter. CE <b>+" .. tostring(ceGain) .. "</b>, Health <b>-" .. tostring(damage) .. "</b>." .. adjustWorldReputation(stats, 3, 6, 4)
		fireMajorPopup(player, "HEIAN BLOOD MOON", "Historical eras now push harder danger and bigger power swings.", "Survived", "Fear and cursed energy surged.")

	elseif activityId == "edo_lightning_duel" then
		local damage = math.random(10, 28)
		local masteryGain = math.random(6, 14)
		stats.Health = math.clamp((stats.Health or 100) - damage, 0, 100)
		stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + masteryGain, 0, 100)
		stats.CursedEnergy += math.random(8, 20)
		logMessage = "A Kashimo-like Edo challenger forced a brutal duel. Technique Mastery <b>+" .. tostring(masteryGain) .. "%</b>, Health <b>-" .. tostring(damage) .. "</b>." .. adjustWorldReputation(stats, 3, 3, 3)
		fireMajorPopup(player, "EDO LIGHTNING DUEL", "The Edo era struck like a storm.", "Duel Survived", "Technique mastery rose from pressure.")

	elseif activityId == "stabilize_cursed_object_anchor" then
		local progress = tonumber(stats.CursedObjectAnchorProgress) or 0
		if progress < 25 then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need more cursed object residue before stabilizing an anchor.")
			return
		end
		local consume = math.random(18, 32)
		local anchorGain = progress >= 75 and 2 or 1
		stats.CursedObjectAnchorProgress = math.clamp(progress - consume, 0, 100)
		stats.CursedObjectAnchors = math.max(0, (tonumber(stats.CursedObjectAnchors) or 0) + anchorGain)
		stats.CursedResentment = math.clamp((tonumber(stats.CursedResentment) or 0) + math.random(4, 10), 0, 100)
		stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + math.random(5, 14))
		if tostring(stats.ReincarnationAnchor or "None") == "None" then
			stats.ReincarnationAnchor = "Cursed Object"
		end
		logMessage = "You stabilized cursed-object residue into <b>" .. tostring(anchorGain) .. "</b> anchor" .. (anchorGain == 1 and "" or "s") .. ". Reincarnation Anchor: <b>" .. tostring(stats.ReincarnationAnchor) .. "</b>."
		fireMajorPopup(player, "CURSED OBJECT ANCHOR", "A cursed object now remembers part of your cursed energy.", tostring(stats.CursedObjectAnchors) .. " Anchor(s)", "Anchors can support future reincarnation and sealed-object systems.")

	elseif activityId == "idle_add_trait" then
		if tostring(stats.CursedTechnique or stats.InnateTechnique or "None") ~= "Idle Transfiguration" then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need Idle Transfiguration to shape traits.")
			return
		end
		stats.Traits = typeof(stats.Traits) == "table" and stats.Traits or {}
		local added = nil
		for _, traitId in ipairs(IDLE_TRAIT_POOL) do
			if not hasTraitId(stats, traitId) then
				local trait = BitKaisenTraits.GetTrait(traitId)
				if trait then
					table.insert(stats.Traits, trait.Id)
					added = trait.Name or trait.Id
					break
				end
			end
		end
		if not added then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "Your soul shape already contains the safe traits this method can add.")
			return
		end
		local strain = math.random(10, 22)
		stats.Health = math.clamp((stats.Health or 100) - strain, 0, 100)
		stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + math.random(1, 4), 0, 100)
		logMessage = "You used Idle Transfiguration to add the trait <b>" .. tostring(added) .. "</b>. Health <b>-" .. tostring(strain) .. "</b>." .. adjustWorldReputation(stats, 1, 4, 2)
		fireMajorPopup(player, "IDLE TRANSFIGURATION", "You changed the shape of your own soul.", tostring(added), "A trait was added.")

	elseif activityId == "idle_remove_trait" then
		if tostring(stats.CursedTechnique or stats.InnateTechnique or "None") ~= "Idle Transfiguration" then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need Idle Transfiguration to remove traits.")
			return
		end
		stats.Traits = typeof(stats.Traits) == "table" and stats.Traits or {}
		local removed = nil
		for index = #stats.Traits, 1, -1 do
			local traitId = typeof(stats.Traits[index]) == "table" and stats.Traits[index].Id or stats.Traits[index]
			if tostring(traitId) ~= "six_eyes" then
				local trait = BitKaisenTraits.GetTrait(traitId)
				removed = trait and (trait.Name or trait.Id) or tostring(traitId)
				table.remove(stats.Traits, index)
				break
			end
		end
		if not removed then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "There was no removable trait to cut away.")
			return
		end
		local strain = math.random(14, 28)
		stats.Health = math.clamp((stats.Health or 100) - strain, 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(5, 12), 0, 100)
		logMessage = "You used Idle Transfiguration to remove <b>" .. tostring(removed) .. "</b>. Health <b>-" .. tostring(strain) .. "</b>." .. adjustWorldReputation(stats, 0, 5, 2)
		fireMajorPopup(player, "IDLE TRANSFIGURATION", "You cut away part of your soul shape.", tostring(removed), "A trait was removed.")

	elseif activityId == "rct_memory_training" then
		if stats.HasRCT == true then
			stats.RCTMastery = math.clamp((tonumber(stats.RCTMastery) or 0) + math.random(3, 7), 0, 100)
			stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) - math.random(3, 8))
			fireLifeUpdate(player, stats, "<font color='#7fcfe0'><b>[ RCT ]</b></font> You refined your reverse cursed technique. RCT Mastery increased.")
			saveStats(player, "rct practice")
			return
		end
		if beginRCTMemoryMinigame(player, stats) then
			saveStats(player, "rct memory minigame started")
			return
		end
		stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
		fireLifeUpdate(player, stats, "The RCT memory drill is not available right now.")
		return

	elseif activityId == "cursed_finger_hunt" then
		if beginCursedFingerHunt(player, stats) then
			saveStats(player, "cursed finger hunt started")
			return
		end
		stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
		fireLifeUpdate(player, stats, "The cursed finger hunt is not available right now.")
		return

	elseif activityId == "consume_cursed_fingers" then
		if (tonumber(stats.CursedFingers) or 0) < 20 then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need <b>20 cursed fingers</b> before consuming them.")
			return
		end
		stats.CursedFingers = 0
		local roll = math.random(1, 100)
		if roll <= 20 then
			stats.Health = 0
			if not applyMiracleSave(stats, player) then
				stats.Alive = false
				fireLifeUpdate(player, stats, "<font color='#d6455d'><b>[ SUKUNA ]</b></font> You consumed the fingers. The curse overwhelmed your body and killed you.")
			end
		elseif roll <= 65 then
			stats.Origin = "Ryomen Clan"
			stats.Clan = "Ryomen Clan"
			stats.FamilyName = "Ryomen"
			if not stats.CursedTechnique or stats.CursedTechnique == "" or stats.CursedTechnique == "None" then
				stats.CursedTechnique = "Shrine"
				stats.InnateTechnique = "Shrine"
			else
				stats.InnateTechnique = stats.CursedTechnique
			end
			stats.TechniqueKnown = true
			stats.TechniqueUsable = true
			stats.TechniqueAwakened = true
			stats.CursedEnergy = math.max(200, (tonumber(stats.CursedEnergy) or 0) + 120)
			stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + 18, 0, 100)
			stats.Fear = math.clamp((tonumber(stats.Fear) or 0) + 30, 0, 100)
			stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + 12, 0, 100)
			local ctName = tostring(stats.CursedTechnique or "Shrine")
			fireMajorPopup(player, "SUKUNA AWAKENED", "The fingers answered from inside your body.", ctName, "Your life changed violently.")
			fireLifeUpdate(player, stats, "<font color='#d6455d'><b>[ SUKUNA ]</b></font> You survived the fingers. Sukuna incarnated but your cursed technique remained your own.")
		else
			stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + 60)
			stats.Health = math.clamp((tonumber(stats.Health) or 100) - 35, 1, 100)
			stats.CursedResentment = math.clamp((tonumber(stats.CursedResentment) or 0) + 20, 0, 100)
			fireLifeUpdate(player, stats, "<font color='#d6455d'><b>[ SUKUNA ]</b></font> You survived consuming the fingers, but Sukuna did not fully incarnate. Your body barely held together.")
		end
		saveStats(player, "consumed cursed fingers")
		return

	elseif activityId == "sukuna_vessel_ritual" then
		if (tonumber(stats.CursedFingers) or 0) < 20 then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need <b>20 cursed fingers</b> before searching for a vessel.")
			return
		end
		stats.CursedFingers = 0
		local chance = math.clamp(35 + math.floor((tonumber(stats.CursedEnergy) or 0) / 8) + math.floor((tonumber(stats.TechniqueMastery) or 0) / 4), 35, 88)
		if math.random(1, 100) <= chance then
			stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + 85)
			stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + 10, 0, 100)
			stats.Reputation = math.max(0, (tonumber(stats.Reputation) or 0) + 18)
			stats.SukunaVesselsDefeated = (tonumber(stats.SukunaVesselsDefeated) or 0) + 1
			fireMajorPopup(player, "VESSEL DEFEATED", "You survived the King of Curses' vessel trial.", "Sukuna", "The fingers were destroyed.")
			fireLifeUpdate(player, stats, "<font color='#d6455d'><b>[ SUKUNA ]</b></font> You found a vessel and defeated it. CE and mastery increased heavily.")
		else
			stats.Health = math.clamp((tonumber(stats.Health) or 100) - math.random(35, 70), 0, 100)
			stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + 8, 0, 100)
			if stats.Health <= 0 and not applyMiracleSave(stats, player) then stats.Alive = false end
			fireLifeUpdate(player, stats, "<font color='#d6455d'><b>[ SUKUNA ]</b></font> The vessel nearly tore you apart." .. (stats.Alive and " You escaped wounded." or " You died in the fight."))
		end
		saveStats(player, "sukuna vessel ritual")
		return

	elseif activityId == "heirloom_search" then
		if beginHeirloomMinigame(player, stats) then
			saveStats(player, "heirloom minigame started")
			return
		end
		stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
		fireLifeUpdate(player, stats, "The heirloom search is not available right now.")
		return

	elseif activityId == "burglary_job" then
		if beginBurglaryMinigame(player, stats) then
			saveStats(player, "burglary minigame started")
			return
		end
		stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
		fireLifeUpdate(player, stats, "The burglary minigame is not available right now.")
		return

	elseif activityId == "blackjack_table" then
		local started, reason = beginBlackjackMinigame(player, stats)
		if started then
			saveStats(player, "blackjack minigame started")
			return
		end
		stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
		fireLifeUpdate(player, stats, tostring(reason or "The 21 Card Game table is not available right now."))
		return

	elseif activityId == "black_flash_training" then
		if usedBlackFlashDrillToken then
			stats.LastBlackFlashDrillTokenUsed = os.time()
		end
		if beginBlackFlashMinigame(player, stats) then
			saveStats(player, "black flash minigame started")
			return
		end

		stats.Health = math.clamp((stats.Health or 100) - math.random(8, 16), 0, 100)
		stats.CursedEnergy += math.random(5, 12)
		logMessage = "Black Flash training could not open the timing drill, so you ran a rough fallback session."

	elseif activityId == "mission_review" then
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(3, 7), 0, 100)
		stats.Reputation += math.random(1, 4)
		logMessage = "You reviewed past mission records and noticed mistakes that most students would have missed."

	elseif activityId == "mentor_younger_sorcerers" then
		stats.Reputation += math.random(4, 10)
		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(2, 7), 0, 100)
		logMessage = "You mentored younger sorcerers and helped them understand the dangers of cursed energy."

	elseif activityId == "retirement_reflection" then
		local firstRetirement = stats.RetiredFromSorcery ~= true
		local stabilityGain = math.random(5, 12)
		stats.RetiredFromSorcery = true
		stats.RetirementAge = (tonumber(stats.RetirementAge) and tonumber(stats.RetirementAge) >= 0) and tonumber(stats.RetirementAge) or (tonumber(stats.Age) or 0)
		stats.RetirementRoute = "Civilian Survival"
		stats.LifePath = "Civilian"
		stats.SocietyStatus = "Retired Civilian"
		stats.InJujutsuHigh = false
		stats.RegisteredSorcerer = false
		stats.Affiliation = "Unaffiliated"
		stats.AffiliationRank = "Retired"
		stats.CivilianStability = math.clamp((tonumber(stats.CivilianStability) or 0) + stabilityGain, 0, 100)
		stats.WorldPressure = math.clamp((tonumber(stats.WorldPressure) or 0) - math.random(3, 8), 0, 100)
		stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) - math.random(1, 4), 0, 100)
		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(5, 14), 0, 100)
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(1, 4), 0, 100)
		logMessage = firstRetirement and "You stepped away from sorcerer society and chose a civilian survival route. Civilian Stability <b>+" .. tostring(stabilityGain) .. "</b>. Jobs will be easier to settle into, and society pressure eased." or "You recommitted to civilian life and kept distance from curse work. Civilian Stability <b>+" .. tostring(stabilityGain) .. "</b>."
		fireMajorPopup(player, "CIVILIAN ROUTE", "You retired from active sorcerer society.", "Civilian Survival", "Jobs, stability, and lower society pressure now matter more.")

	elseif activityId == "barrier_drills" then
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(4, 9), 0, 100)
		stats.CursedEnergy += math.random(3, 8)
		stats.Reputation += math.random(0, 2)
		logMessage = "You practiced barrier drills, curtain response, and veil reading until the shapes started making sense."

	elseif activityId == "patrol_city" then
		local reward = math.random(45, 130)
		stats.Money += reward
		stats.Reputation += math.random(1, 4)
		stats.CursedEnergy += math.random(2, 7)

		if math.random(1, 100) <= 20 then
			stats.Health = math.clamp((stats.Health or 100) - math.random(3, 10), 0, 100)
			logMessage = "You patrolled the city and handled a weak curse trace, but it still managed to wear you down. You earned $" .. tostring(reward) .. "."
		else
			logMessage = "You patrolled the city and cleared minor curse traces before they became real incidents. You earned $" .. tostring(reward) .. "."
		end

	elseif activityId == "cursed_tool_practice" then
		local assetBonuses = BitKaisenAssets.GetPassiveBonuses(stats)
		local missionBonus = assetBonuses.MissionPowerBonus or 0

		stats.CursedEnergy += math.random(2, 6)
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(1, 4), 0, 100)
		stats.Reputation += math.random(1, 3)

		if missionBonus > 0 then
			logMessage = "You practiced cursed tool control using your own equipment. Your mission instincts sharpened."
		else
			logMessage = "You practiced cursed tool control with basic equipment. It was rough, but useful."
		end

	elseif activityId == "student_training_review" then
		if not stats.ClanFounded then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need to found a clan before reviewing student training.")
			return
		end

		local studentCount = countClanStudents(stats)
		if studentCount <= 0 then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need recruited students before you can review their training.")
			return
		end

		stats.ClanTrainingSessions = (stats.ClanTrainingSessions or 0) + 1
		stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + math.random(2, 6))
		stats.Reputation += math.random(1, 4)
		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(1, 4), 0, 100)

		for _, relationship in ipairs(stats.Relationships or {}) do
			if relationship.Alive ~= false and relationship.Role == "Student" then
				BitKaisenRelationships.AdjustRelationship(relationship, {
					Bond = math.random(1, 3),
					Trust = math.random(1, 3),
					Respect = math.random(2, 5)
				})
			end
		end

		logMessage = "You reviewed your students' training and corrected sloppy cursed energy habits. Your dojo's reputation improved."

	elseif activityId == "clan_admin" then
		if not stats.ClanFounded then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, "You need to found a clan before managing clan affairs.")
			return
		end

		local adminRoll = math.random(1, 100)
		stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + math.random(1, 5))
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(1, 4), 0, 100)

		if adminRoll <= 20 then
			adjustDojoCondition(stats, -math.random(2, 7))
			logMessage = "You handled clan affairs, but an argument between students damaged the dojo's condition."
		else
			stats.Money += math.random(100, 350)
			logMessage = "You handled clan records, payments, and student issues. The clan felt more stable."
		end

	elseif activityId == "domain_foundation_study" then
		local oldMastery = stats.TechniqueMastery or 0
		local gain = math.random(2, 6)

		if (stats.Smarts or 0) >= 70 then
			gain += 2
		end

		stats.TechniqueMastery = math.clamp(oldMastery + gain, 0, 100)
		stats.CursedEnergy += math.random(6, 14)
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(3, 7), 0, 100)
		stats.Health = math.clamp((stats.Health or 100) - math.random(2, 7), 0, 100)

		logMessage = "You studied domain foundations and tried to understand how your innate technique would shape a territory."
		logMessage = logMessage .. "\nTechnique Mastery increased by <b>" .. tostring(stats.TechniqueMastery - oldMastery) .. "%</b>."

		if stats.TechniqueMastery >= 80 and oldMastery < 80 then
			fireMajorPopup(
				player,
				"DOMAIN FOUNDATION",
				"Your understanding of your cursed technique started approaching domain-level theory.",
				"Domain Foundation",
				"You are not there yet, but the shape is starting to exist."
			)
		end

	elseif activityId == "binding_vow_research" then
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(4, 10), 0, 100)
		stats.CursedEnergy += math.random(2, 8)

		if math.random(1, 100) <= 15 then
			stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(4, 9), 0, 100)
			logMessage = "You researched binding vows and realized how dangerous forced restrictions can become."
		else
			stats.Reputation += math.random(0, 3)
			logMessage = "You researched binding vows and learned how sorcerers trade freedom for power."
		end

	elseif activityId == "cult_found" or activityId == "cult_recruit_initiate" or activityId == "cult_binding_ritual"
		or activityId == "cult_collect_tribute" or activityId == "cult_expand_territory" or activityId == "cult_curse_fusion"
		or activityId == "cult_supply_run" or activityId == "cult_review_members" then
		local ok, message = BK_CultService.ProcessActivity(player, stats, activityId)
		if not ok then
			stats.ActivitiesDoneThisAge = math.max(0, (stats.ActivitiesDoneThisAge or 1) - 1)
			fireLifeUpdate(player, stats, message)
			return
		end
		logMessage = message

	end

	logMessage = logMessage .. applyTraitBuffsFromSnapshot(stats, traitBefore, "Activity")
	logMessage = maybeTeacherRecommendation(player, stats, logMessage)
	logMessage = checkPromotionAndPopup(player, stats, logMessage)

	if stats.Health <= 0 and not applyMiracleSave(stats, player) then
		stats.Alive = false
		logMessage = logMessage .. "\nYour body could not handle the strain."
	end

	fireLifeUpdate(player, stats, logMessage)
	saveStats(player)
end

function BK_ActivityService.DebugStartMinigame(player, key)
	local stats = getStats(player)
	if not player or not stats or stats.Alive == false then
		return false, "No alive BitKaisen life is loaded."
	end

	ensureExtraStats(stats)
	key = string.lower(tostring(key or ""))
	key = key:gsub("_", " "):gsub("%-", " "):gsub("%s+", " ")
	key = key:gsub("^%s+", ""):gsub("%s+$", "")

	if key == "blackflash" or key == "black flash" or key == "bf" then
		return beginBlackFlashMinigame(player, stats), "Black Flash"
	elseif key == "21" or key == "21 card" or key == "21 card game" or key == "blackjack" or key == "cards" then
		stats.Money = math.max(tonumber(stats.Money) or 0, BLACKJACK_WAGER)
		local started, reason = beginBlackjackMinigame(player, stats)
		return started, reason or "21 Card Game"
	elseif key == "rct" or key == "rct memory" or key == "rct drill" then
		stats.CursedEnergy = math.max(tonumber(stats.CursedEnergy) or 0, 60)
		return beginRCTMemoryMinigame(player, stats), "RCT Memory Drill"
	elseif key == "finger" or key == "fingers" or key == "cursed finger" or key == "cursed fingers" then
		return beginCursedFingerHunt(player, stats), "Cursed Finger Hunt"
	elseif key == "heirloom" or key == "family" or key == "scroll" then
		return beginHeirloomMinigame(player, stats), "Heirloom Search"
	elseif key == "burglary" or key == "burglar" or key == "robbery" then
		return beginBurglaryMinigame(player, stats), "Burglary Job"
	elseif key == "raid" or key == "dojo raid" or key == "dojo raid defense" or key == "raid defense" then
		stats.DojoRaidRisk = math.max(tonumber(stats.DojoRaidRisk) or 0, 55)
		return beginDojoRaidDefenseMinigame(player, stats), "Dojo Raid Defense"
	end

	return false, "Unknown minigame. Use: blackflash, 21, rct, finger, heirloom, burglary, raid."
end

function BK_ActivityService.GetActivityListPayload(player)
	local stats = getStats(player)

	if not stats or not stats.Alive then
		return {}
	end

	ensureExtraStats(stats)

	local list = BitKaisenActivities.GenerateCategorizedActivityList(stats)
	local filtered = {}

	for _, activity in ipairs(list) do
		if shouldShowActivityForPlayer(player, stats, activity) then
			table.insert(filtered, activity)
		end
	end

	local locale = BitKaisenLocale.getPlayerLocale(player.UserId)
	if locale ~= "en" then
		for _, entry in ipairs(filtered) do
			local id = entry.Id or ""
			entry.Title = BitKaisenLocale.tOrFallback(locale, "activity_cards." .. id .. ".title", nil, entry.Title)
			entry.Description = BitKaisenLocale.tOrFallback(locale, "activity_cards." .. id .. ".desc", nil, entry.Description)
			if entry.LockedReason then
				entry.LockedReason = BitKaisenLocale.tOrFallback(locale, "activity_cards." .. id .. ".locked", nil, entry.LockedReason)
			end
		end
	end

	return filtered
end

function BK_ActivityService.ProcessActivity(player, activityId)
	return processActivity(player, activityId)
end

function BK_ActivityService.Init(ctx)
	context = ctx or {}

	local completeMinigame = ReplicatedStorage:FindFirstChild("CompleteMinigame")
	if completeMinigame and completeMinigame:IsA("RemoteEvent") and not completeMinigameConnection then
		completeMinigameConnection = completeMinigame.OnServerEvent:Connect(function(player, token, accuracy, action)
			local session = minigameSessions[player.UserId]
			if session and session.Type == "Blackjack" then
				resolveBlackjackMinigame(player, token, action or accuracy)
			elseif session and session.Type == "Burglary" then
				resolveBurglaryMinigame(player, token, action or accuracy)
			elseif session and session.Type == "DojoRaidDefense" then
				resolveDojoRaidDefenseMinigame(player, token, action or accuracy)
			elseif session and session.Type == "Heirloom" then
				resolveHeirloomMinigame(player, token, action or accuracy)
			elseif session and session.Type == "CursedFingerHunt" then
				resolveCursedFingerHunt(player, token, action or accuracy)
			elseif session and session.Type == "RCTMemory" then
				resolveRCTMemoryMinigame(player, token, action or accuracy)
			else
				resolveBlackFlashMinigame(player, token, accuracy)
			end
		end)
	end

	if context.IS_DEBUG then print("[BK_ActivityService] Phase 6 activity handling loaded with full Heian modern-activity lock.") end
end

return BK_ActivityService

