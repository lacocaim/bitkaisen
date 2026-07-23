-- ModuleScript: BK_DuelService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose:
--   Multiplayer Fase 6B/6C/6D: live turn-based PvP duels between two real
--   players of the same Public world. Deliberately separate from
--   BK_CombatService (the NPC combat engine stays untouched -- zero
--   regression risk); duels run on their own session type, their own
--   remotes, and their own panel (DuelPanel/MobileDuelPanel).
--
--   Fair-play guards (per the BitSeas-informed design doc):
--     * power-gap cap: no challenging someone 3x weaker/stronger
--     * one duel per pair of players per in-game year
--     * reward decay when repeatedly beating the same victim
--     * never lethal: duel HP is a COPY of Health -- real stats are never
--       touched by damage, only by rewards
--   Rematch ("Revancha"): losing grants a one-use rematch marker that
--   bypasses the once-per-year rule at 1.5x stakes.
--   PvP build (Fase 6D): stats.DuelSpec (Offensive/Defensive/Technical/
--   Spiritual), changeable once per in-game year, only affects duels.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BitKaisenCombat = require(ReplicatedStorage:WaitForChild("BitKaisenCombat"))
local BK_CombatService = require(script.Parent:WaitForChild("BK_CombatService"))
-- Fase 7: finished duels feed cell-war scoreboards + the Juramento de Era.
local BK_CellService = require(script.Parent:WaitForChild("BK_CellService"))

local BK_DuelService = {}

local TURN_SECONDS = 20
local INVITE_SECONDS = 30
local POWER_GAP_RATIO = 3
local TECHNIQUE_CE_COST = 18
local TECHNIQUE_CE_COST_TECHNICAL = 12
local BASE_REWARD_MONEY = 500
local REWARD_REPUTATION = 2
local REMATCH_STAKES = 1.5
local BLACK_FLASH_CHANCE = 0.06
local TEARDOWN_SECONDS = 8

local VALID_SPECS = {
	Offensive = true,
	Defensive = true,
	Technical = true,
	Spiritual = true,
}

local context = {}
local initialized = false
local duels = {}
local playerDuel = {}
local invites = {}
local duelCounter = 0

local getDuelStateRemote
local duelActionRemote
local duelStateUpdateRemote
local duelInviteRemote

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

local function isLivingPublicSoul(stats)
	return stats ~= nil and stats.WorldMode == "Public" and stats.Alive ~= false
end

local function currentYearOf(stats)
	return tonumber(stats.CurrentYear) or 0
end

----------------------------------------------------------------
-- Session helpers
----------------------------------------------------------------

local function buildSide(player, stats)
	return {
		UserId = player.UserId,
		Player = player,
		Name = tostring(stats.Name or player.Name),
		HP = math.clamp(math.floor(tonumber(stats.Health) or 100), 1, 100),
		MaxHP = 100,
		CE = math.max(0, math.floor(tonumber(stats.CursedEnergy) or 0)),
		MaxCE = math.max(20, math.floor(tonumber(stats.CursedEnergy) or 0)),
		Power = BitKaisenCombat.GetCombatPower(stats),
		Strength = tonumber(stats.Strength) or 0,
		Spec = VALID_SPECS[stats.DuelSpec] and stats.DuelSpec or "Offensive",
		Defending = false,
	}
end

local function sideOf(session, userId)
	if session.A.UserId == userId then
		return session.A, session.B
	end
	return session.B, session.A
end

local function addLog(session, text)
	table.insert(session.Log, 1, text)
	while #session.Log > 8 do
		table.remove(session.Log)
	end
end

local function publicState(session)
	local function sidePayload(side)
		return {
			UserId = side.UserId,
			Name = side.Name,
			HP = side.HP,
			MaxHP = side.MaxHP,
			CE = side.CE,
			Spec = side.Spec,
			Defending = side.Defending,
		}
	end
	return {
		DuelId = session.Id,
		Phase = session.Phase,
		Round = session.Round,
		TurnUserId = session.TurnUserId,
		TurnSecondsLeft = math.max(0, math.floor((session.TurnDeadline or 0) - os.clock())),
		A = sidePayload(session.A),
		B = sidePayload(session.B),
		Log = session.Log,
		Winner = session.WinnerUserId,
		StakesMultiplier = session.StakesMultiplier,
	}
end

local function broadcast(session)
	local state = publicState(session)
	for _, side in ipairs({ session.A, session.B }) do
		if side.Player and side.Player.Parent then
			duelStateUpdateRemote:FireClient(side.Player, state)
		end
	end
	for userId in pairs(session.Spectators) do
		local spectator = Players:GetPlayerByUserId(userId)
		if spectator then
			duelStateUpdateRemote:FireClient(spectator, state)
		else
			session.Spectators[userId] = nil
		end
	end
end

----------------------------------------------------------------
-- Duel resolution
----------------------------------------------------------------

local function rewardDecay(winnerStats, loserUserId)
	local winsVs = winnerStats.DuelWinsVs
	if typeof(winsVs) ~= "table" then
		return 1
	end
	local priorWins = tonumber(winsVs[tostring(loserUserId)]) or 0
	return 1 / (1 + priorWins)
end

local function finishDuel(session, winnerUserId, reason)
	if session.Phase == "finished" then
		return
	end
	session.Phase = "finished"
	session.WinnerUserId = winnerUserId
	session.TurnToken = (session.TurnToken or 0) + 1

	local winner, loser = sideOf(session, winnerUserId)
	addLog(session, "🏆 " .. winner.Name .. " wins the duel" .. (reason == "flee" and " -- " .. loser.Name .. " conceded." or (reason == "disconnect" and " -- " .. loser.Name .. " vanished." or "!")))

	local winnerStats = winner.Player and getStats(winner.Player) or nil
	local loserStats = loser.Player and getStats(loser.Player) or nil

	if winnerStats then
		local decay = rewardDecay(winnerStats, loser.UserId)
		local money = math.floor(BASE_REWARD_MONEY * (session.StakesMultiplier or 1) * decay)
		winnerStats.Money = (tonumber(winnerStats.Money) or 0) + money
		winnerStats.Reputation = (tonumber(winnerStats.Reputation) or 0) + REWARD_REPUTATION
		winnerStats.DuelWins = (tonumber(winnerStats.DuelWins) or 0) + 1
		winnerStats.DuelWinsVs = typeof(winnerStats.DuelWinsVs) == "table" and winnerStats.DuelWinsVs or {}
		winnerStats.DuelWinsVs[tostring(loser.UserId)] = (tonumber(winnerStats.DuelWinsVs[tostring(loser.UserId)]) or 0) + 1
		fireMajorPopup(winner.Player, "DUEL WON", "You defeated " .. loser.Name .. " in a live duel.", "+$" .. tostring(money) .. "  +" .. tostring(REWARD_REPUTATION) .. " Rep", "Reunión de Vidas", "success")
		fireLifeUpdate(winner.Player, winnerStats, "⚔ You won the duel against " .. loser.Name .. " (+$" .. tostring(money) .. ").")
		if context.ForceSaveStats then
			context.ForceSaveStats(winner.Player, "DuelWon")
		end
	end

	if loserStats then
		loserStats.DuelLosses = (tonumber(loserStats.DuelLosses) or 0) + 1
		-- Revancha: one-use marker that bypasses the once-per-year rule at
		-- higher stakes. Never lethal, never costs the loser anything else.
		loserStats.DuelRematch = typeof(loserStats.DuelRematch) == "table" and loserStats.DuelRematch or {}
		loserStats.DuelRematch[tostring(winner.UserId)] = true
		fireMajorPopup(loser.Player, "DUEL LOST", winner.Name .. " bested you this time. A Rematch marker is yours -- use it from the Lives tab.", "⚔ REVANCHA AVAILABLE", "Reunión de Vidas", "info")
		fireLifeUpdate(loser.Player, loserStats, "⚔ You lost the duel against " .. winner.Name .. ". Revancha available.")
		if context.ForceSaveStats then
			context.ForceSaveStats(loser.Player, "DuelLost")
		end
	end

	broadcast(session)

	-- Fase 7: war scoreboards + Juramento de Era (async -- DataStore write).
	task.spawn(function()
		BK_CellService.OnDuelResult(session.WorldId, winner.UserId, loser.UserId)
	end)

	task.delay(TEARDOWN_SECONDS, function()
		if duels[session.Id] == session then
			duels[session.Id] = nil
		end
		if playerDuel[session.A.UserId] == session.Id then
			playerDuel[session.A.UserId] = nil
		end
		if playerDuel[session.B.UserId] == session.Id then
			playerDuel[session.B.UserId] = nil
		end
	end)
end

local function computeAttackDamage(attacker, defender, isTechnique)
	local power = math.min(attacker.Power or 0, 260)
	local damage = 8 + power / 22 + (attacker.Strength or 0) * 0.06
	if isTechnique then
		damage = damage * 1.6
		if attacker.Spec == "Technical" then
			damage = damage * 1.2
		end
	end
	if attacker.Spec == "Offensive" then
		damage = damage * 1.15
	end
	if defender.Spec == "Defensive" then
		damage = damage * 0.85
	end
	damage = damage * (0.85 + math.random() * 0.3)
	local blackFlash = math.random() < BLACK_FLASH_CHANCE
	if blackFlash then
		damage = damage * 2
	end
	if defender.Defending then
		damage = damage * 0.5
	end
	return math.max(1, math.floor(damage)), blackFlash
end

local function startTurnClock(session)
	session.TurnToken = (session.TurnToken or 0) + 1
	local token = session.TurnToken
	session.TurnDeadline = os.clock() + TURN_SECONDS
	task.delay(TURN_SECONDS, function()
		if session.Phase == "active" and session.TurnToken == token then
			-- Turn clock expired: auto-defend so an AFK duelist stalls
			-- nothing and still regains a little CE.
			local current = sideOf(session, session.TurnUserId)
			current.Defending = true
			current.CE = math.min(current.MaxCE, current.CE + 6)
			addLog(session, "⏳ " .. current.Name .. " hesitated and guards up.")
			session.TurnUserId = (session.TurnUserId == session.A.UserId) and session.B.UserId or session.A.UserId
			session.Round += 1
			startTurnClock(session)
			broadcast(session)
		end
	end)
end

local function advanceTurn(session)
	session.TurnUserId = (session.TurnUserId == session.A.UserId) and session.B.UserId or session.A.UserId
	session.Round += 1
	-- Per-turn CE trickle so long duels don't dead-end (Spiritual spec
	-- regenerates faster -- its whole identity).
	local upNext = sideOf(session, session.TurnUserId)
	upNext.CE = math.min(upNext.MaxCE, upNext.CE + (upNext.Spec == "Spiritual" and 6 or 2))
	startTurnClock(session)
end

local function handleCombatAction(player, session, actionId)
	if session.Phase ~= "active" or session.TurnUserId ~= player.UserId then
		return
	end
	local me, foe = sideOf(session, player.UserId)

	if actionId == "attack" or actionId == "technique" then
		local isTechnique = actionId == "technique"
		if isTechnique then
			local cost = me.Spec == "Technical" and TECHNIQUE_CE_COST_TECHNICAL or TECHNIQUE_CE_COST
			if me.CE < cost then
				return
			end
			me.CE -= cost
		end
		me.Defending = false
		local damage, blackFlash = computeAttackDamage(me, foe, isTechnique)
		foe.Defending = false
		foe.HP = math.max(0, foe.HP - damage)
		if blackFlash then
			addLog(session, "⚡ BLACK FLASH! " .. me.Name .. " hits " .. foe.Name .. " for " .. damage .. "!")
		elseif isTechnique then
			addLog(session, "🌀 " .. me.Name .. "'s technique hits " .. foe.Name .. " for " .. damage .. ".")
		else
			addLog(session, "👊 " .. me.Name .. " strikes " .. foe.Name .. " for " .. damage .. ".")
		end
		if foe.HP <= 0 then
			finishDuel(session, me.UserId, "ko")
			return
		end
		advanceTurn(session)
		broadcast(session)
	elseif actionId == "defend" then
		me.Defending = true
		me.CE = math.min(me.MaxCE, me.CE + 6)
		addLog(session, "🛡 " .. me.Name .. " guards and gathers cursed energy.")
		advanceTurn(session)
		broadcast(session)
	elseif actionId == "flee" then
		finishDuel(session, foe.UserId, "flee")
	end
end

----------------------------------------------------------------
-- Invites
----------------------------------------------------------------

-- Validates a challenger/target pairing against every fair-play guard.
-- Returns ok, reason, isRematch.
local function validatePair(challenger, challengerStats, target, targetStats)
	if not isLivingPublicSoul(challengerStats) or not isLivingPublicSoul(targetStats) then
		return false, "Both lives must be alive in a Public world."
	end
	if challengerStats.PublicWorldId ~= targetStats.PublicWorldId then
		return false, "You are not in the same world."
	end
	if playerDuel[challenger.UserId] or playerDuel[target.UserId] then
		return false, "One of you is already dueling."
	end
	if BK_CombatService.HasActiveFight(challenger) or BK_CombatService.HasActiveFight(target) then
		return false, "One of you is in a fight right now."
	end

	local myPower = math.max(1, BitKaisenCombat.GetCombatPower(challengerStats))
	local theirPower = math.max(1, BitKaisenCombat.GetCombatPower(targetStats))
	local ratio = math.max(myPower, theirPower) / math.min(myPower, theirPower)

	local rematchMarks = typeof(challengerStats.DuelRematch) == "table" and challengerStats.DuelRematch or {}
	local isRematch = rematchMarks[tostring(target.UserId)] == true

	if ratio > POWER_GAP_RATIO and not isRematch then
		return false, "The power gap is too wide for a fair duel."
	end

	if not isRematch then
		local year = currentYearOf(challengerStats)
		local history = typeof(challengerStats.DuelPairYear) == "table" and challengerStats.DuelPairYear or {}
		if tonumber(history[tostring(target.UserId)]) == year then
			return false, "You two already dueled this year. Wait for the year to advance (or use a Rematch)."
		end
	end

	return true, nil, isRematch
end

local function handleInvite(player, data)
	local stats = getStats(player)
	local targetPlayer = Players:GetPlayerByUserId(tonumber(typeof(data) == "table" and data.TargetUserId or nil) or 0)
	if not stats or not targetPlayer or targetPlayer == player then
		return
	end
	local targetStats = getStats(targetPlayer)
	local ok, reason, isRematch = validatePair(player, stats, targetPlayer, targetStats)
	if not ok then
		fireLifeUpdate(player, stats, "⚔ Duel refused: " .. tostring(reason))
		return
	end

	invites[targetPlayer.UserId] = {
		FromUserId = player.UserId,
		ExpiresAt = os.time() + INVITE_SECONDS,
		IsRematch = isRematch,
	}
	duelInviteRemote:FireClient(targetPlayer, {
		FromUserId = player.UserId,
		FromName = tostring(stats.Name or player.Name),
		FromGrade = tostring(stats.Grade or "Non-Sorcerer"),
		IsRematch = isRematch,
		ExpiresAt = os.time() + INVITE_SECONDS,
	})
	fireLifeUpdate(player, stats, "⚔ Duel challenge sent to " .. tostring(targetStats.Name or targetPlayer.Name) .. (isRematch and " (REVANCHA)." or "."))

	task.delay(INVITE_SECONDS + 1, function()
		local invite = invites[targetPlayer.UserId]
		if invite and invite.FromUserId == player.UserId and os.time() >= invite.ExpiresAt then
			invites[targetPlayer.UserId] = nil
		end
	end)
end

local function startDuel(challenger, challengerStats, target, targetStats, isRematch)
	duelCounter += 1
	local session = {
		Id = "duel_" .. tostring(duelCounter),
		WorldId = challengerStats.PublicWorldId,
		A = buildSide(challenger, challengerStats),
		B = buildSide(target, targetStats),
		Round = 1,
		Log = {},
		Phase = "active",
		Spectators = {},
		StakesMultiplier = isRematch and REMATCH_STAKES or 1,
		TurnToken = 0,
	}
	session.TurnUserId = math.random(2) == 1 and session.A.UserId or session.B.UserId

	duels[session.Id] = session
	playerDuel[challenger.UserId] = session.Id
	playerDuel[target.UserId] = session.Id

	-- Burn the once-per-year slot (both sides) and the rematch marker.
	local year = currentYearOf(challengerStats)
	challengerStats.DuelPairYear = typeof(challengerStats.DuelPairYear) == "table" and challengerStats.DuelPairYear or {}
	challengerStats.DuelPairYear[tostring(target.UserId)] = year
	targetStats.DuelPairYear = typeof(targetStats.DuelPairYear) == "table" and targetStats.DuelPairYear or {}
	targetStats.DuelPairYear[tostring(challenger.UserId)] = year
	if isRematch and typeof(challengerStats.DuelRematch) == "table" then
		challengerStats.DuelRematch[tostring(target.UserId)] = nil
	end

	addLog(session, "⚔ The duel begins" .. (isRematch and " -- REVANCHA, stakes x" .. tostring(REMATCH_STAKES) .. "!" or "!"))
	startTurnClock(session)
	broadcast(session)
end

local function handleAccept(player)
	local invite = invites[player.UserId]
	if not invite or os.time() > invite.ExpiresAt then
		invites[player.UserId] = nil
		return
	end
	invites[player.UserId] = nil

	local challenger = Players:GetPlayerByUserId(invite.FromUserId)
	if not challenger then
		return
	end
	local challengerStats = getStats(challenger)
	local stats = getStats(player)
	-- Re-validate: things can change in 30 seconds (deaths, other duels...).
	local ok, reason = validatePair(challenger, challengerStats, player, stats)
	if not ok then
		fireLifeUpdate(player, stats, "⚔ Duel fell through: " .. tostring(reason))
		fireLifeUpdate(challenger, challengerStats, "⚔ Duel fell through: " .. tostring(reason))
		return
	end
	startDuel(challenger, challengerStats, player, stats, invite.IsRematch)
end

local function handleDecline(player)
	local invite = invites[player.UserId]
	invites[player.UserId] = nil
	if invite then
		local challenger = Players:GetPlayerByUserId(invite.FromUserId)
		if challenger then
			local challengerStats = getStats(challenger)
			if challengerStats then
				fireLifeUpdate(challenger, challengerStats, "⚔ Your duel challenge was declined.")
			end
		end
	end
end

----------------------------------------------------------------
-- Spectators (Fase 6C)
----------------------------------------------------------------

local function handleSpectate(player, data)
	local stats = getStats(player)
	local session = duels[typeof(data) == "table" and data.DuelId or nil]
	if not stats or not session or session.Phase ~= "active" then
		return
	end
	if not isLivingPublicSoul(stats) or stats.PublicWorldId ~= session.WorldId then
		return
	end
	if playerDuel[player.UserId] then
		return
	end
	session.Spectators[player.UserId] = true
	duelStateUpdateRemote:FireClient(player, publicState(session))
end

local function handleStopSpectate(player)
	for _, session in pairs(duels) do
		session.Spectators[player.UserId] = nil
	end
end

----------------------------------------------------------------
-- PvP spec (Fase 6D)
----------------------------------------------------------------

local function handleSetSpec(player, data)
	local stats = getStats(player)
	local spec = typeof(data) == "table" and tostring(data.Spec or "") or ""
	if not stats or not VALID_SPECS[spec] then
		return
	end
	local year = currentYearOf(stats)
	if stats.DuelSpec ~= nil and tonumber(stats.DuelSpecYear) == year and stats.DuelSpec ~= spec then
		fireLifeUpdate(player, stats, "⚔ You already re-planned your PvP build this year.")
		return
	end
	stats.DuelSpec = spec
	stats.DuelSpecYear = year
	fireLifeUpdate(player, stats, "⚔ PvP build set: " .. spec .. ".")
end

----------------------------------------------------------------
-- Public API + wiring
----------------------------------------------------------------

function BK_DuelService.IsDueling(player)
	return player ~= nil and playerDuel[player.UserId] ~= nil
end

-- Souls-tab payload: every active duel of a world, for WATCH buttons.
function BK_DuelService.GetActiveDuels(worldId)
	local list = {}
	for _, session in pairs(duels) do
		if session.Phase == "active" and session.WorldId == worldId then
			table.insert(list, {
				DuelId = session.Id,
				AName = session.A.Name,
				BName = session.B.Name,
				AUserId = session.A.UserId,
				BUserId = session.B.UserId,
				Round = session.Round,
			})
		end
	end
	return list
end

local function handleAction(player, actionId, data)
	if not checkRateLimit(player, "DuelAction") then
		return
	end

	if actionId == "invite" then
		handleInvite(player, data)
	elseif actionId == "accept" then
		handleAccept(player)
	elseif actionId == "decline" then
		handleDecline(player)
	elseif actionId == "spectate" then
		handleSpectate(player, data)
	elseif actionId == "stop_spectate" then
		handleStopSpectate(player)
	elseif actionId == "set_spec" then
		handleSetSpec(player, data)
	elseif actionId == "attack" or actionId == "technique" or actionId == "defend" or actionId == "flee" then
		local duelId = playerDuel[player.UserId]
		local session = duelId and duels[duelId]
		if session then
			handleCombatAction(player, session, actionId)
		end
	end
end

function BK_DuelService.Init(ctx)
	if initialized then return end
	initialized = true
	context = ctx or {}

	getDuelStateRemote = getRemote("GetDuelState", "RemoteFunction")
	duelActionRemote = getRemote("DuelAction", "RemoteEvent")
	duelStateUpdateRemote = getRemote("DuelStateUpdate", "RemoteEvent")
	duelInviteRemote = getRemote("DuelInvite", "RemoteEvent")

	getDuelStateRemote.OnServerInvoke = function(player)
		if not checkRateLimit(player, "GetDuelState") then
			return nil
		end
		local duelId = playerDuel[player.UserId]
		local session = duelId and duels[duelId]
		if session then
			return publicState(session)
		end
		return nil
	end

	duelActionRemote.OnServerEvent:Connect(handleAction)

	Players.PlayerRemoving:Connect(function(player)
		invites[player.UserId] = nil
		handleStopSpectate(player)
		local duelId = playerDuel[player.UserId]
		local session = duelId and duels[duelId]
		if session and session.Phase == "active" then
			local _, opponent = sideOf(session, player.UserId)
			finishDuel(session, opponent.UserId, "disconnect")
		end
	end)
end

return BK_DuelService
