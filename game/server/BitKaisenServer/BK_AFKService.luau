-- ModuleScript: BK_AFKService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose: Monetized AFK Stabilization idle earning loop.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BK_AFKService = {}

local TEST_PURCHASE_PLACE_IDS = {
	[104206065947170] = true,
}

local PAYOUT_PER_SECOND = 0.2
local PAYOUT_INTERVAL = 2

local function roundCurrency(value)
	return math.floor((tonumber(value) or 0) * 100 + 0.5) / 100
end
local MAX_SESSION_SECONDS = 60 * 60 * 2

local context = {}
local initialized = false
local sessions = {}
local getStateRemote
local actionRemote
local updateRemote

local function getRemote(name, className)
	local remote = ReplicatedStorage:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = ReplicatedStorage
	end
	return remote
end

local function isTestingPlace()
	return RunService:IsStudio() or TEST_PURCHASE_PLACE_IDS[game.PlaceId] == true
end

local function getStats(player)
	if context.GetStats then
		return context.GetStats(player)
	end
	return nil
end

local function ensureExtraStats(stats)
	if context.EnsureExtraStats then
		context.EnsureExtraStats(stats)
	end
	stats.AFKStabilizationUnlocked = stats.AFKStabilizationUnlocked == true
	stats.Money = roundCurrency(stats.Money)
	stats.AFKStabilizationEarned = math.max(0, roundCurrency(stats.AFKStabilizationEarned))
	stats.AFKStabilizationSessions = math.max(0, tonumber(stats.AFKStabilizationSessions) or 0)
end

local function fireLifeUpdate(player, stats, message)
	if context.FireLifeUpdate then
		context.FireLifeUpdate(player, stats, message)
	end
end

local function fireMajorPopup(player, title, body, highlight, footer)
	if context.FireMajorPopup then
		context.FireMajorPopup(player, title, body, highlight, footer)
	end
end

local function forceSaveStats(player, reason)
	if context.ForceSaveStats then
		context.ForceSaveStats(player, reason)
	end
end

local function getProductId()
	if context.GetAFKStabilizationProductId then
		return tonumber(context.GetAFKStabilizationProductId()) or 0
	end
	return 0
end

local function ensureGamePassUnlock(player, stats)
	if not player or not stats or stats.AFKStabilizationUnlocked == true or isTestingPlace() then return end
	local passId = getProductId()
	if passId <= 0 then return end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	if ok and owns then
		stats.AFKStabilizationUnlocked = true
		forceSaveStats(player, "afk_stabilization_gamepass_restore")
	end
end

local function publicState(player)
	local stats = getStats(player)
	if stats then ensureExtraStats(stats) end
	local session = sessions[player.UserId]
	return {
		Unlocked = stats and stats.AFKStabilizationUnlocked == true or false,
		Active = session and session.Active == true or false,
		TestingPlace = isTestingPlace(),
		ProductId = getProductId(),
		RatePerSecond = PAYOUT_PER_SECOND,
		EarnedTotal = stats and math.floor((tonumber(stats.AFKStabilizationEarned) or 0) * 100 + 0.5) / 100 or 0,
		SessionEarned = session and math.floor((tonumber(session.Earned) or 0) * 100 + 0.5) / 100 or 0,
		SessionSeconds = session and math.floor(os.clock() - session.StartedAt) or 0,
		MaxSessionSeconds = MAX_SESSION_SECONDS,
	}
end

local function sendState(player)
	if updateRemote then
		updateRemote:FireClient(player, publicState(player))
	end
end

local function settlePendingPayout(player, stats, session)
	if not stats or not session then return 0 end
	local now = os.clock()
	local elapsed = now - (session.LastPayoutAt or now)
	local payoutSeconds = math.floor(elapsed)
	local payout = roundCurrency(payoutSeconds * PAYOUT_PER_SECOND)
	if payout <= 0 then return 0 end

	stats.Money = roundCurrency((tonumber(stats.Money) or 0) + payout)
	stats.AFKStabilizationEarned = roundCurrency((tonumber(stats.AFKStabilizationEarned) or 0) + payout)
	session.Earned = roundCurrency((tonumber(session.Earned) or 0) + payout)
	session.LastPayoutAt = (session.LastPayoutAt or now) + payoutSeconds
	return payout
end

local function stopSession(player, reason)
	local session = sessions[player.UserId]
	if not session then return end
	sessions[player.UserId] = nil
	local stats = getStats(player)
	if stats then
		ensureExtraStats(stats)
		settlePendingPayout(player, stats, session)
		forceSaveStats(player, reason or "afk_stabilization_stop")
	end
	sendState(player)
end

local function startSession(player)
	local stats = getStats(player)
	if not stats then return false, "No active life." end
	ensureExtraStats(stats)
	if stats.AFKStabilizationUnlocked ~= true then
		return false, "AFK Stabilization is locked."
	end
	if stats.Alive == false then
		return false, "Start a living character first."
	end
	if sessions[player.UserId] and sessions[player.UserId].Active then
		return true
	end
	sessions[player.UserId] = {
		Active = true,
		StartedAt = os.clock(),
		LastPayoutAt = os.clock(),
		LastSaveAt = os.clock(),
		Earned = 0,
	}
	stats.AFKStabilizationSessions = (tonumber(stats.AFKStabilizationSessions) or 0) + 1
	fireLifeUpdate(player, stats, "<font color='#7ee787'><b>[ AFK STABILIZATION ]</b></font> Stabilization started. Idle earnings are now active.")
	sendState(player)
	return true
end

local function unlockForTesting(player)
	if not isTestingPlace() then return false end
	local stats = getStats(player)
	if not stats then return false end
	ensureExtraStats(stats)
	stats.AFKStabilizationUnlocked = true
	forceSaveStats(player, "afk_stabilization_test_unlock")
	fireMajorPopup(player, "AFK STABILIZATION", "Testing unlock applied.", "+$0.20/sec", "Use the AFK button to start earning.")
	sendState(player)
	return true
end

local function handleAction(player, action)
	action = tostring(action or "")
	if action == "start" then
		local ok, message = startSession(player)
		if not ok then
			local stats = getStats(player)
			if stats then
				fireLifeUpdate(player, stats, "<font color='#ffcd69'><b>[ AFK STABILIZATION ]</b></font> " .. tostring(message or "Could not start."))
			end
			sendState(player)
		end
	elseif action == "stop" then
		stopSession(player, "afk_stabilization_stop")
	elseif action == "test_unlock" then
		unlockForTesting(player)
	end
end

local function tickSessions()
	local now = os.clock()
	for userId, session in pairs(sessions) do
		local player = Players:GetPlayerByUserId(userId)
		local stats = player and getStats(player) or nil
		if not player or not stats or stats.Alive == false then
			if player then stopSession(player, "afk_stabilization_invalid") else sessions[userId] = nil end
		else
			ensureExtraStats(stats)
			local elapsed = now - session.LastPayoutAt
			local sessionSeconds = now - session.StartedAt
			if sessionSeconds >= MAX_SESSION_SECONDS then
				stopSession(player, "afk_stabilization_session_cap")
				fireLifeUpdate(player, stats, "<font color='#ffcd69'><b>[ AFK STABILIZATION ]</b></font> Session cap reached. Restart AFK mode to continue earning.")
			elseif elapsed >= PAYOUT_INTERVAL then
				local payoutSeconds = math.floor(elapsed)
				local payout = math.floor((payoutSeconds * PAYOUT_PER_SECOND) * 100 + 0.5) / 100
				if payout > 0 then
					stats.Money = roundCurrency((tonumber(stats.Money) or 0) + payout)
					stats.AFKStabilizationEarned = roundCurrency((tonumber(stats.AFKStabilizationEarned) or 0) + payout)
					session.Earned = roundCurrency((tonumber(session.Earned) or 0) + payout)
					session.LastPayoutAt = now
					sendState(player)
					if now - session.LastSaveAt >= 60 then
						session.LastSaveAt = now
						forceSaveStats(player, "afk_stabilization_tick")
					end
				end
			end
		end
	end
end

function BK_AFKService.Init(ctx)
	if initialized then return end
	initialized = true
	context = ctx or {}
	getStateRemote = getRemote("GetAFKStabilization", "RemoteFunction")
	actionRemote = getRemote("AFKStabilizationAction", "RemoteEvent")
	updateRemote = getRemote("AFKStabilizationUpdate", "RemoteEvent")
	getStateRemote.OnServerInvoke = function(player)
		return publicState(player)
	end
	actionRemote.OnServerEvent:Connect(handleAction)
	task.spawn(function()
		while initialized do
			tickSessions()
			task.wait(1)
		end
	end)
	if context.IS_DEBUG then print("[BK_AFKService] AFK Stabilization loaded.") end
end

function BK_AFKService.PlayerRemoving(player)
	stopSession(player, "afk_stabilization_leave")
end

return BK_AFKService
