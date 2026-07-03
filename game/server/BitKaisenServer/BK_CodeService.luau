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
	"OPCODE",
	"BLACKMARKET",
	"HIDDENVEIL",
}

local CODE_DEFINITIONS = {

	OPCODE = {
		Name = "OPCode",
		Description = "Summer PT3 drops. The cursed world shifts again.",
		RewardText = "+$15,000 | +80 CE | +10 Mastery | +5 Rep",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 15000
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 80
			stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + 10, 0, 100)
			stats.Reputation = (stats.Reputation or 0) + 5
			return "+$15,000 Money, +80 Cursed Energy, +10 Technique Mastery, and +5 Reputation"
		end
	},

	BLACKMARKET = {
		Name = "BlackMarket",
		Description = "The underground stirs. Not everything is sold in the open.",
		RewardText = "+$25,000 | +5 Strength | +5 Smarts",
		Grant = function(stats)
			stats.Money = (stats.Money or 0) + 25000
			stats.Strength = math.clamp((stats.Strength or 0) + 5, 0, 100)
			stats.Smarts = math.clamp((stats.Smarts or 0) + 5, 0, 100)
			return "+$25,000 Money, +5 Strength, and +5 Smarts"
		end
	},

	HIDDENVEIL = {
		Name = "HiddenVeil",
		Description = "Some techniques were never meant to be found.",
		RewardText = "+60 CE | +8 Mastery | +10 Fear",
		Grant = function(stats)
			stats.CursedEnergy = (stats.CursedEnergy or 0) + 60
			stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + 8, 0, 100)
			stats.Fear = math.clamp((stats.Fear or 0) + 10, 0, 100)
			return "+60 Cursed Energy, +8 Technique Mastery, and +10 Fear"
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
		if game:GetService("RunService"):IsStudio() then print("[BK_CodeService] Waiting for live GameManager context.") end
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

	if context.IS_DEBUG then print("[BK_CodeService] Loaded real code logic with Update 18 codes.") end
end

return BK_CodeService
