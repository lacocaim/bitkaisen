local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local objects = require(ReplicatedStorage:WaitForChild("global"):WaitForChild("utils"):WaitForChild("objects"))
local schema = require("../accountService/schema")
local store = require("../accountService/store")
local charm = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("charm"))

local transacting: {
	aborted: boolean,
	onSuccess: { () -> () },
	onAbort: { () -> () },
}?
type Eval = {
	player: Player,
	uncommittedAccount: schema.Account,
}
local evaluating: Eval? = nil

local function playerLoaded(player: Player)
	return Players:GetPlayerByUserId(player.UserId)
		and charm.untracked(store.get)[tostring(player.UserId)]
		and store.profiles[player]
		and store.profiles[player]:IsActive()
end

local function assertPlayerLoaded(player: Player)
	assert(playerLoaded(player), "Player not loaded")
end

local function isTransacting()
	return transacting
end
local function getEvaluating(): Eval?
	return evaluating
end

local function isAborted()
	return if transacting then transacting.aborted else false
end

local function abort()
	local evaluating = getEvaluating()
	assert(evaluating, "Attempt to abort outside a player transaction")
	evaluating.errorHandler()
end

local function onSuccess(cb: () -> ())
	if transacting then
		table.insert(transacting.onSuccess, cb)
	end
end

local function onAbort(cb: () -> ())
	if transacting then
		if transacting.aborted then
			cb()
		else
			table.insert(transacting.onAbort, cb)
		end
	end
end

local function transaction(registerTransactions: schema.Transaction)
	if isTransacting() then
		error("Nested transactions")
	end

	local oldState = charm.untracked(store.get)
	local possibleTransactions = {}

	transacting = {
		aborted = false,
		onSuccess = {},
		onAbort = {},
	}
	local function criticalAbort(err: string)
		transacting = nil
		evaluating = nil
		warn(err)
	end
	local allPlayersRegistered = true
	local function tx(player: Player, fn: () -> ())
		if not player or not fn then
			warn("TRANSACTION COULDN'T START: Invalid arguments")
			allPlayersRegistered = false
			return
		end
		if not playerLoaded(player) then
			allPlayersRegistered = false
			return
		end
		if not possibleTransactions[player] then
			possibleTransactions[player] = fn
		else
			warn("TRANSACTION COULDN'T START: Double player transactions found for " .. player.Name)
			allPlayersRegistered = false
		end
	end
	local function handler()
		if transacting and not transacting.aborted then
			transacting.aborted = true
			for _, cb in transacting.onAbort do
				cb()
			end
		end
	end

	local ok, result = pcall(function()
		registerTransactions(tx)
		if not allPlayersRegistered then
			handler()
			return false
		end
		local possibleCommits = {}
		for player, plrTx in possibleTransactions do
			assertPlayerLoaded(player)
			evaluating = {
				player = player,
				uncommittedAccount = oldState[tostring(player.UserId)].account,
				errorHandler = handler,
			}
			local ok, result: string = pcall(plrTx)
			if not ok then
				handler()
				warn("TRANSACTION COULDN'T COMMIT: " .. result .. "\n" .. debug.traceback())
				return false
			end
			if transacting and transacting.aborted then
				return false
			end
			if evaluating then
				possibleCommits[player] = evaluating.uncommittedAccount
			end
		end
		if next(possibleCommits) then
			local newState = table.clone(oldState)
			for player, commit in possibleCommits do
				newState[tostring(player.UserId)] = objects.set(newState[tostring(player.UserId)], "account", commit)
			end
			store.set(newState)
		end
		return true
	end)
	if not ok then
		criticalAbort("ERROR DURING TRANSACTION:\n" .. result)
	else
		if transacting and result == true then
			for _, cb in transacting.onSuccess do
				cb()
			end
		end

		transacting = nil
		evaluating = nil
	end
end

return {
	transaction = transaction,
	isTransacting = isTransacting,
	getEvaluating = getEvaluating,

	isAborted = isAborted,

	onSuccess = onSuccess,
	onAbort = onAbort,
	abort = abort,
}
