-- ModuleScript: BK_SoulsService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose:
--   Multiplayer Fase 6 ("Reunión de Vidas"): real-player interaction inside
--   a Public world. GetSouls lists every soul present on this world's server
--   (with Fase 4's real per-world servers, everyone connected here IS this
--   world); SoulAction handles the light social actions (send a signal,
--   gift money). Heavier interactions -- live duels -- live in
--   BK_DuelService (Fase 6B), which this service only points at.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- One-way dependencies: Souls lists the world's active duels (WATCH
-- buttons), each soul's dueling status, and Fase 7's cells/Tronos; neither
-- service requires us back.
local BK_DuelService = require(script.Parent:WaitForChild("BK_DuelService"))
local BK_CellService = require(script.Parent:WaitForChild("BK_CellService"))

local BK_SoulsService = {}

local GIFT_MONEY_MAX = 100000

local context = {}
local initialized = false
local getSoulsRemote
local soulActionRemote

local function getRemote(name, className)
	local remote = ReplicatedStorage:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = ReplicatedStorage
	end
	return remote
end

local function getStats(player)
	if context.GetStats then
		return context.GetStats(player)
	end
	return nil
end

local function fireLifeUpdate(player, stats, message)
	if context.FireLifeUpdate then
		context.FireLifeUpdate(player, stats, message)
	end
end

local function fireMajorPopup(player, title, body, highlight, footer, style)
	if context.FireMajorPopup then
		context.FireMajorPopup(player, title, body, highlight, footer, style)
	end
end

local function checkRateLimit(player, key)
	if context.CheckRateLimit then
		return context.CheckRateLimit(player, key)
	end
	return true
end

local function isPublicSoul(stats, worldId)
	return stats ~= nil
		and stats.WorldMode == "Public"
		and stats.PublicWorldId == worldId
		and stats.Alive ~= false
end

local function buildSoulEntry(soulPlayer, stats, requesterUserId)
	return {
		UserId = soulPlayer.UserId,
		PlayerName = soulPlayer.Name,
		Name = tostring(stats.Name or "Unknown"),
		IsYou = soulPlayer.UserId == requesterUserId,
		Age = tonumber(stats.Age) or 0,
		Grade = tostring(stats.Grade or "Non-Sorcerer"),
		LifePath = tostring(stats.LifePath or "Undecided"),
		Clan = tostring(stats.Clan or ""),
		CursedEnergy = math.floor(tonumber(stats.CursedEnergy) or 0),
		Reputation = math.floor(tonumber(stats.Reputation) or 0),
		WantedLevel = math.floor(tonumber(stats.WantedLevel) or 0),
		Fame = math.floor(tonumber(stats.Fame) or 0),
		CombatWins = tonumber(stats.CombatWins) or 0,
		CombatLosses = tonumber(stats.CombatLosses) or 0,
	}
end

-- Fase 7 "Los Tronos": the world's elite council -- the 4 connected souls
-- with the most Fame (Reputation as tiebreak), strongest first.
local function buildThrones(souls)
	local ranked = table.clone(souls)
	table.sort(ranked, function(a, b)
		if a.Fame ~= b.Fame then
			return a.Fame > b.Fame
		end
		return a.Reputation > b.Reputation
	end)
	local thrones = {}
	for i = 1, math.min(4, #ranked) do
		table.insert(thrones, {
			UserId = ranked[i].UserId,
			Name = ranked[i].Name,
			Fame = ranked[i].Fame,
			IsSovereignSeat = i == 1,
		})
	end
	return thrones
end

local function buildSoulsPayload(player)
	local stats = getStats(player)
	if not stats or stats.WorldMode ~= "Public" then
		return { IsPublic = false, Souls = {} }
	end

	local worldId = stats.PublicWorldId
	-- Fase 7: one DataStore read covers everything cell-related (your cell,
	-- the cell list, territories, invites, and every soul's cell tag).
	local cellData = BK_CellService.GetCellsPayload(worldId, player.UserId)
	local souls = {}
	for _, soulPlayer in ipairs(Players:GetPlayers()) do
		local soulStats = getStats(soulPlayer)
		if isPublicSoul(soulStats, worldId) then
			local entry = buildSoulEntry(soulPlayer, soulStats, player.UserId)
			entry.InDuel = BK_DuelService.IsDueling(soulPlayer)
			-- Revancha marker: can the requester rematch this soul?
			local rematchMarks = typeof(stats.DuelRematch) == "table" and stats.DuelRematch or {}
			entry.RematchAvailable = rematchMarks[tostring(soulPlayer.UserId)] == true
			entry.CellName = (cellData.MembersIndex or {})[tostring(soulPlayer.UserId)]
			-- Fase 8: keep the chat cell tag fresh for rejoining members
			-- (SetAttribute no-ops when unchanged).
			soulPlayer:SetAttribute("BKChatCell", entry.CellName)
			table.insert(souls, entry)
		end
	end

	table.sort(souls, function(a, b)
		if a.IsYou ~= b.IsYou then
			return a.IsYou
		end
		return a.CursedEnergy > b.CursedEnergy
	end)

	return {
		IsPublic = true,
		Souls = souls,
		ActiveDuels = BK_DuelService.GetActiveDuels(worldId),
		YourSpec = stats.DuelSpec,
		YourSpecLocked = stats.DuelSpec ~= nil and tonumber(stats.DuelSpecYear) == (tonumber(stats.CurrentYear) or 0),
		CellData = cellData,
		Thrones = buildThrones(souls),
	}
end

-- Resolves and validates the target of a soul-to-soul action: both sides
-- must be living Public souls of the SAME world, and you can't target
-- yourself. Returns targetPlayer, targetStats, ownStats (or nil + reason).
local function resolveTarget(player, targetUserId)
	local stats = getStats(player)
	if not stats or stats.WorldMode ~= "Public" or stats.Alive == false then
		return nil
	end

	local targetPlayer = Players:GetPlayerByUserId(tonumber(targetUserId) or 0)
	if not targetPlayer or targetPlayer == player then
		return nil
	end

	local targetStats = getStats(targetPlayer)
	if not isPublicSoul(targetStats, stats.PublicWorldId) then
		return nil
	end

	return targetPlayer, targetStats, stats
end

local function handleSignal(player, targetPlayer, targetStats, stats)
	local senderName = tostring(stats.Name or player.Name)
	fireMajorPopup(
		targetPlayer,
		"SIGNAL RECEIVED",
		senderName .. " sends you a greeting across the world.",
		"📡 " .. senderName,
		"Reunión de Vidas",
		"info"
	)
	fireLifeUpdate(targetPlayer, targetStats, "📡 " .. senderName .. " sent you a signal.")
	fireLifeUpdate(player, stats, "📡 You sent a signal to " .. tostring(targetStats.Name or targetPlayer.Name) .. ".")
end

local function handleGiftMoney(player, targetPlayer, targetStats, stats, data)
	local amount = math.floor(tonumber(typeof(data) == "table" and data.Amount or nil) or 0)
	amount = math.clamp(amount, 0, GIFT_MONEY_MAX)
	if amount <= 0 then
		return
	end

	local money = tonumber(stats.Money) or 0
	if money < amount then
		fireLifeUpdate(player, stats, "You don't have $" .. tostring(amount) .. " to gift.")
		return
	end

	local senderName = tostring(stats.Name or player.Name)
	local targetName = tostring(targetStats.Name or targetPlayer.Name)

	stats.Money = money - amount
	targetStats.Money = (tonumber(targetStats.Money) or 0) + amount

	fireMajorPopup(
		targetPlayer,
		"A GIFT ARRIVES",
		senderName .. " sent you money.",
		"+$" .. tostring(amount),
		"Reunión de Vidas",
		"success"
	)
	fireLifeUpdate(targetPlayer, targetStats, "🎁 " .. senderName .. " gifted you $" .. tostring(amount) .. ".")
	fireLifeUpdate(player, stats, "🎁 You gifted $" .. tostring(amount) .. " to " .. targetName .. ".")

	-- Money moved between two accounts -- persist both sides right away so a
	-- crash can't duplicate or vanish the transfer.
	if context.ForceSaveStats then
		context.ForceSaveStats(player, "SoulGiftSent")
		context.ForceSaveStats(targetPlayer, "SoulGiftReceived")
	end
end

local function handleAction(player, targetUserId, actionId, data)
	if not checkRateLimit(player, "SoulAction") then
		return
	end

	local targetPlayer, targetStats, stats = resolveTarget(player, targetUserId)
	if not targetPlayer then
		return
	end

	if actionId == "signal" then
		handleSignal(player, targetPlayer, targetStats, stats)
	elseif actionId == "gift_money" then
		handleGiftMoney(player, targetPlayer, targetStats, stats, data)
	end
end

function BK_SoulsService.Init(ctx)
	if initialized then return end
	initialized = true
	context = ctx or {}

	getSoulsRemote = getRemote("GetSouls", "RemoteFunction")
	soulActionRemote = getRemote("SoulAction", "RemoteEvent")

	getSoulsRemote.OnServerInvoke = function(player)
		if not checkRateLimit(player, "GetSouls") then
			return { IsPublic = false, Souls = {} }
		end
		return buildSoulsPayload(player)
	end

	soulActionRemote.OnServerEvent:Connect(handleAction)

	-- Fase 8: arrival announcements -- when a soul finishes loading into a
	-- Public world, every other soul present hears about it. The delay
	-- gives loadOrStartLife time to resolve the newcomer's mode/stats.
	Players.PlayerAdded:Connect(function(newPlayer)
		task.delay(8, function()
			if not newPlayer.Parent then
				return
			end
			local newStats = getStats(newPlayer)
			if not isPublicSoul(newStats, newStats and newStats.PublicWorldId) then
				return
			end
			local arrivalName = tostring(newStats.Name or newPlayer.Name)
			for _, soulPlayer in ipairs(Players:GetPlayers()) do
				if soulPlayer ~= newPlayer then
					local soulStats = getStats(soulPlayer)
					if isPublicSoul(soulStats, newStats.PublicWorldId) then
						fireLifeUpdate(soulPlayer, soulStats, "🌍 " .. arrivalName .. " has arrived in this world.")
					end
				end
			end
		end)
	end)
end

return BK_SoulsService
