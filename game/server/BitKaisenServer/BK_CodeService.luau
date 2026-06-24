-- ModuleScript: BK_CodeService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose:
--   Owns code gate checks and code redemption rewards.
--   Split out of GameManager so code updates stop risking the whole life loop.

local BK_CodeService = {}
local context = {}
local initialized = false

local BITKAISEN_GROUP_ID = 212374896
local REQUIRE_GROUP_FOR_CODES = true
local REQUIRE_LIKE_CONFIRMATION_FOR_CODES = false

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

local function checkRateLimit(player, actionKey)
	if context.CheckRateLimit then
		return context.CheckRateLimit(player, actionKey)
	end
	return true
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

local function unlockExtraSaveSlots(player, stats)
	if context.UnlockExtraSaveSlots then
		return context.UnlockExtraSaveSlots(player, stats)
	end
end

local BitKaisenSaveSystem = {}

local CODE_ORDER = {
	"UPDATE16",
	"CONSOLESUPPORT",
	"NEWGUI",
	"SECRET",
}

local CODE_DEFINITIONS = {

	UPDATE16 = {
		Name = "Update16",
		Description = "Update 16 launch reward.",
		RewardText = "+$10,000",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 10000
			return "+$10,000 Money"
		end
	},

	CONSOLESUPPORT = {
		Name = "ConsoleSupport",
		Description = "Console support reward.",
		RewardText = "+75 CE",
		Grant = function(stats)
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 75
			return "+75 Cursed Energy"
		end
	},

	NEWGUI = {
		Name = "NewGUI",
		Description = "New GUI reward.",
		RewardText = "+$5,000",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 5000
			return "+$5,000 Money"
		end
	},

	SECRET = {
		Name = "Secret",
		Description = "Limited secret launch code.",
		RewardText = "+$25,000 | +250 CE",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 25000
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 250
			return "+$25,000 Money and +250 Cursed Energy"
		end
	},

	UPDATE62 = {
		Name = "UPDATE62",
		Description = "Update 6.2 quality update reward.",
		RewardText = "+$25,000 | +65 CE | +8 Mastery | +8 Rep | +3 Recommendations",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 25000
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 65
			stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + 8, 0, 100)
			stats.Reputation = (stats.Reputation or 0) + 8
			stats.TeacherRecommendations = (stats.TeacherRecommendations or 0) + 3
			stats.Happiness = math.clamp((stats.Happiness or 100) + 8, 0, 100)
			return "+$25,000 Money, +65 Cursed Energy, +8 Technique Mastery, +8 Reputation, +3 Teacher Recommendations, and +8 Happiness"
		end
	},

	VOWS = {
		Name = "VOWS",
		Description = "Binding Vows polish reward.",
		RewardText = "+50 CE | +6 Mastery | +5 Rep | +10 Happiness",
		Grant = function(stats)
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 50
			stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + 6, 0, 100)
			stats.Reputation = (stats.Reputation or 0) + 5
			stats.Happiness = math.clamp((stats.Happiness or 100) + 10, 0, 100)
			return "+50 Cursed Energy, +6 Technique Mastery, +5 Reputation, and +10 Happiness"
		end
	},

	SORRYBUGS = {
		Name = "SORRYBUGS",
		Description = "Bug fix apology reward.",
		RewardText = "+$30,000 | +40 CE | +15 Happiness | +8 Health",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 30000
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 40
			stats.Happiness = math.clamp((stats.Happiness or 100) + 15, 0, 100)
			stats.Health = math.clamp((stats.Health or 100) + 8, 0, 100)
			return "+$30,000 Money, +40 Cursed Energy, +15 Happiness, and +8 Health"
		end
	},

	SPADE = {
		Name = "SPADE",
		Description = "Special creator code reward.",
		RewardText = "+$50,000 | +50 CE | +10 Mastery | +10 Rep",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 50000
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 50
			stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + 10, 0, 100)
			stats.Reputation = (stats.Reputation or 0) + 10
			stats.Happiness = math.clamp((stats.Happiness or 100) + 10, 0, 100)
			return "+$50,000 Money, +50 Cursed Energy, +10 Technique Mastery, +10 Reputation, and +10 Happiness"
		end
	},

	UPDATE4 = {
		Name = "UPDATE4",
		Description = "Update 4 launch reward.",
		RewardText = "+$20,000 | +30 CE | +6 Mastery | +5 Rep",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 20000
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 30
			stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + 6, 0, 100)
			stats.Reputation = (stats.Reputation or 0) + 5
			return "+$20,000 Money, +30 Cursed Energy, +6 Technique Mastery, and +5 Reputation"
		end
	},

	DOJOEXPANSION = {
		Name = "DOJOEXPANSION",
		Description = "Grand Dojo expansion reward.",
		RewardText = "+$12,000 | +8 Rep | +5 Dojo Prestige",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 12000
			stats.Reputation = (stats.Reputation or 0) + 8
			stats.DojoPrestige = math.max(0, (stats.DojoPrestige or 0) + 5)
			stats.ClanReputation = math.max(0, (stats.ClanReputation or 0) + 4)
			stats.DojoReputation = math.max(0, (stats.DojoReputation or stats.ClanReputation or 0) + 4)
			return "+$12,000 Money, +8 Reputation, +5 Dojo Prestige, and +4 Clan Reputation"
		end
	},

	CURSEUSER = {
		Name = "CURSEUSER",
		Description = "Curse User route reward.",
		RewardText = "+$15,000 | +25 CE | +10 Resentment",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 15000
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 25
			stats.CursedResentment = math.clamp((stats.CursedResentment or 0) + 10, 0, 999)
			stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + 3, 0, 100)
			return "+$15,000 Money, +25 Cursed Energy, +10 Cursed Resentment, and +3 Technique Mastery"
		end
	},

	CURSEDSPIRIT = {
		Name = "CURSEDSPIRIT",
		Description = "Cursed Spirit content reward.",
		RewardText = "+40 CE | +15 Resentment | +5 Mastery",
		Grant = function(stats)
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 40
			stats.CursedResentment = math.clamp((stats.CursedResentment or 0) + 15, 0, 999)
			stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + 5, 0, 100)
			stats.Happiness = math.clamp((stats.Happiness or 100) + 4, 0, 100)
			return "+40 Cursed Energy, +15 Cursed Resentment, +5 Technique Mastery, and +4 Happiness"
		end
	},

	SORRY4DELAY = {
		Name = "SORRY4DELAY",
		Description = "Compensation for the Update 4 delay.",
		RewardText = "+$25,000 | +20 CE | +10 Happiness",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 25000
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 20
			stats.Happiness = math.clamp((stats.Happiness or 100) + 10, 0, 100)
			stats.Reputation = (stats.Reputation or 0) + 3
			return "+$25,000 Money, +20 Cursed Energy, +10 Happiness, and +3 Reputation"
		end
	},

	UPDATE3 = {
		Name = "UPDATE3",
		Description = "Update 3 launch reward.",
		RewardText = "+$15,000 | +25 CE | +5 Mastery | +5 Rep",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 15000
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 25
			stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + 5, 0, 100)
			stats.Reputation = (stats.Reputation or 0) + 5
			return "+$15,000 Money, +25 Cursed Energy, +5 Technique Mastery, and +5 Reputation"
		end
	},

	CURSES = {
		Name = "CURSES",
		Description = "Cursed Spirit route reward.",
		RewardText = "+$10,000 | +35 CE",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 10000
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 35
			return "+$10,000 Money and +35 Cursed Energy"
		end
	},

	DELAY = {
		Name = "DELAY",
		Description = "Delay compensation reward.",
		RewardText = "Free extra save slots",
		Grant = function(stats, player)
			stats.Codes = stats.Codes or {}
			stats.Codes.FreeSaveSlotsUnlocked = true
			stats.FreeSaveSlotsUnlocked = true
			if player and context.BitKaisenSaveSystem and type(context.BitKaisenSaveSystem.UnlockExtraSaveSlots) == "function" then
				pcall(function()
					context.BitKaisenSaveSystem.UnlockExtraSaveSlots(player)
				end)
			end
			return "Extra save slots unlocked"
		end
	},

	ALPHA35 = {
		Name = "ALPHA35",
		Description = "Alpha 3.5 update reward.",
		RewardText = "+$5,000 | +10 CE | +3 Rep",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 5000
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 10
			stats.Reputation = (stats.Reputation or 0) + 3
			return "+$5,000 Money, +10 Cursed Energy, and +3 Reputation"
		end
	},

	MOBILEFIX = {
		Name = "MOBILEFIX",
		Description = "Reward for the mobile bug fix update.",
		RewardText = "+$3,500 | +5 Smarts",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 3500
			stats.Smarts = math.clamp((stats.Smarts or 0) + 5, 0, 100)
			return "+$3,500 Money and +5 Smarts"
		end
	},

	SORRYMOBILE = {
		Name = "SORRYMOBILE",
		Description = "Compensation for mobile issues.",
		RewardText = "+$7,500 | +8 Happiness",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 7500
			stats.Happiness = math.clamp((stats.Happiness or 100) + 8, 0, 100)
			return "+$7,500 Money and +8 Happiness"
		end
	},

	TRAITS = {
		Name = "TRAITS",
		Description = "Traits update reward.",
		RewardText = "+12 CE | +4 Mastery",
		Grant = function(stats)
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 12
			stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + 4, 0, 100)
			return "+12 Cursed Energy and +4 Technique Mastery"
		end
	},

	FAMILYUPDATE = {
		Name = "FAMILYUPDATE",
		Description = "Family update reward.",
		RewardText = "+$4,000 | +6 Happiness | +2 Rep",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 4000
			stats.Happiness = math.clamp((stats.Happiness or 100) + 6, 0, 100)
			stats.Reputation = (stats.Reputation or 0) + 2
			return "+$4,000 Money, +6 Happiness, and +2 Reputation"
		end
	},
}

local function getActiveCodeCards(stats)
	local cards = {}
	stats = stats or {}
	stats.Codes = stats.Codes or {}
	stats.Codes.Redeemed = stats.Codes.Redeemed or {}

	for index, code in ipairs(CODE_ORDER) do
		local definition = CODE_DEFINITIONS[code]
		if definition then
			table.insert(cards, {
				Index = index,
				Code = code,
				Name = definition.Name or code,
				Description = definition.Description or "",
				RewardText = definition.RewardText or "",
				Redeemed = stats.Codes.Redeemed[code] == true,
			})
		end
	end

	return cards
end

local function normalizeRedeemCode(rawCode)
	local code = tostring(rawCode or "")
	code = code:gsub("%s+", "")
	code = code:gsub("[^%w_]", "")
	code = string.upper(code)
	return code
end

local function getRedeemedCodeCount(stats)
	ensureExtraStats(stats)

	local count = 0
	for _, redeemed in pairs(stats.Codes.Redeemed) do
		if redeemed == true then
			count += 1
		end
	end

	return count
end


local function getCodeGatePayload(player, clientConfirmedLike)
	local stats = getStats(player)
	if stats then
		ensureExtraStats(stats)
	end

	local groupConfigured = BITKAISEN_GROUP_ID and BITKAISEN_GROUP_ID > 0
	local groupOk = true
	local groupMessage = "Group requirement is disabled."
	local wasAlreadyVerified = stats and stats.Codes and stats.Codes.GroupVerified == true

	if REQUIRE_GROUP_FOR_CODES then
		if wasAlreadyVerified then
			groupOk = true
			groupMessage = "Group verified."
		elseif not groupConfigured then
			groupOk = false
			groupMessage = "Group ID is not set yet. Add your Roblox group ID in GameManager."
		else
			local ok, result = pcall(function()
				return player:IsInGroup(BITKAISEN_GROUP_ID)
			end)

			groupOk = ok and result == true

			if groupOk and stats and stats.Codes then
				stats.Codes.GroupVerified = true
				stats.CodeGroupVerified = true
				task.defer(function()
					pcall(function()
						saveStats(player)
					end)
				end)
			end

			groupMessage = groupOk and "Group verified." or "Join the Roblox group to unlock codes."
		end
	end

	local likeOk = true
	local likeMessage = "Like confirmation is disabled."

	if REQUIRE_LIKE_CONFIRMATION_FOR_CODES then
		likeOk = clientConfirmedLike == true
		likeMessage = likeOk and "Like confirmed." or "Like the game, then press I LIKED to unlock the code box."
	end

	return {
		CanUseCodes = groupOk and likeOk,
		ActiveCodes = getActiveCodeCards(stats),
		GroupRequired = REQUIRE_GROUP_FOR_CODES == true,
		LikeConfirmationRequired = REQUIRE_LIKE_CONFIRMATION_FOR_CODES == true,
		GroupConfigured = groupConfigured == true,
		GroupId = groupConfigured and BITKAISEN_GROUP_ID or 0,
		InGroup = groupOk == true,
		GroupJoined = groupOk == true,
		GroupVerified = groupOk == true,
		CodeGroupVerified = groupOk == true,
		PermanentVerified = groupOk == true,
		CanRedeem = groupOk and likeOk,
		CanUseCodes = groupOk and likeOk,
		LikeConfirmed = likeOk == true,
		GroupMessage = groupMessage,
		LikeMessage = likeMessage,
	}
end

local function redeemCodeForPlayer(player, rawCode, clientConfirmedLike)
	if not checkRateLimit(player, "RedeemCode") then
		return {
			Success = false,
			Message = "Slow down before redeeming another code.",
			RewardText = ""
		}
	end

	local stats = getStats(player)
	if not stats then
		return {
			Success = false,
			Message = "No life is loaded yet.",
			RewardText = ""
		}
	end

	ensureExtraStats(stats)

	local gate = getCodeGatePayload(player, clientConfirmedLike)
	if gate.CanUseCodes ~= true then
		local reason = gate.GroupMessage or gate.LikeMessage or "Codes are locked."
		if gate.InGroup == true and gate.LikeConfirmed ~= true then
			reason = gate.LikeMessage or reason
		end

		return {
			Success = false,
			Message = reason,
			RewardText = "",
			Gate = gate,
		}
	end

	local code = normalizeRedeemCode(rawCode)
	if code == "" then
		return {
			Success = false,
			Message = "Type a code first.",
			RewardText = ""
		}
	end

	local definition = CODE_DEFINITIONS[code]
	if not definition then
		return {
			Success = false,
			Message = "Invalid code.",
			RewardText = ""
		}
	end

	if stats.Codes.Redeemed[code] == true then
		return {
			Success = false,
			Message = "You already redeemed " .. code .. " on this life.",
			RewardText = definition.RewardText or ""
		}
	end

	stats.Codes.Redeemed[code] = true

	local rewardSummary = "Reward claimed."
	local ok, grantResult = pcall(function()
		return definition.Grant(stats, player)
	end)

	if ok and grantResult then
		rewardSummary = grantResult
	elseif not ok then
		warn("[GameManager] Code reward failed for " .. tostring(code) .. ": " .. tostring(grantResult))
		rewardSummary = "Reward failed to apply."
	end

	fireMajorPopup(
		player,
		"CODE REDEEMED",
		definition.Description or "Reward claimed.",
		code,
		rewardSummary
	)

	fireLifeUpdate(player, stats, "<font color='#f0b955'><b>[ CODE ]</b></font> " .. code .. " redeemed.\n" .. rewardSummary)
	saveStats(player)

	return {
		Success = true,
		Code = code,
		Message = code .. " redeemed.",
		RewardText = rewardSummary,
		RedeemedCount = getRedeemedCodeCount(stats)
	}
end


function BK_CodeService.GetGatePayload(player, clientConfirmedLike)
	return getCodeGatePayload(player, clientConfirmedLike == true)
end

function BK_CodeService.Redeem(player, rawCode, clientConfirmedLike)
	return redeemCodeForPlayer(player, rawCode, clientConfirmedLike == true)
end

function BK_CodeService.Init(ctx)
	if not ctx or type(ctx.GetStats) ~= "function" then
		print("[BK_CodeService] Waiting for live GameManager context.")
		return
	end

	if initialized then
		return
	end
	initialized = true
	context = ctx or {}

	local remotes = context.Remotes or {}
	local redeemCode = remotes.RedeemCode
	local getCodeGate = remotes.GetCodeGate

	if redeemCode then
		redeemCode.OnServerInvoke = function(player, rawCode, clientConfirmedLike)
			return redeemCodeForPlayer(player, rawCode, clientConfirmedLike == true)
		end
	end

	if getCodeGate then
		getCodeGate.OnServerInvoke = function(player, clientConfirmedLike)
			return getCodeGatePayload(player, clientConfirmedLike == true)
		end
	end

	if context.IS_DEBUG then print("[BK_CodeService] Loaded real code logic with Update 6.2 codes.") end
end

return BK_CodeService
