local Players = game:GetService("Players")

local transaction = require("./accountService/transaction")
local migrations = require("./accountService/migrations")

local store = require("./accountService/store")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local charm = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("charm"))
local delta_compress = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("delta-compress"))
local server_blink = require(ServerScriptService:WaitForChild("server-blink"))

local objects = require(ReplicatedStorage:WaitForChild("global"):WaitForChild("utils"):WaitForChild("objects"))
local observers = require(ReplicatedStorage:WaitForChild("global"):WaitForChild("utils"):WaitForChild("observers"))

local schema = require("./accountService/schema")

export type Account = schema.Account
local readyForReplication: { [Player]: boolean } = {}

local function mutateData(mutate: (acc: Account) -> Account?)
	local evaluating = transaction.getEvaluating()
	assert(evaluating, "Attempt to mutate outside a player transaction")
	if transaction.isAborted() then
		return
	end
	local result = mutate(evaluating.uncommittedAccount)
	if result then
		local ok, matchInfo = schema.accountSchema:matches(result)
		if not ok then
			error(matchInfo)
		end
		evaluating.uncommittedAccount = result
	end
end

local function getAccount(): Account
	local evaluating = transaction.getEvaluating()
	assert(evaluating, "Attempt to get account outside a player transaction")
	return evaluating.uncommittedAccount
end

local function getPlayer(): Player
	local evaluating = transaction.getEvaluating()
	assert(evaluating, "Attempt to get player outside a transaction")
	return evaluating.player
end

local function getAccountFor(player: Player): Account?
	if store.get()[tostring(player.UserId)] then
		return store.get()[tostring(player.UserId)].account
	end
	return nil
end

local function replicate(to: Player, old: Account, new: Account)
	if not readyForReplication[to] then
		return
	end
	local diff = delta_compress.diffImmutable(old, new)
	if diff then
		server_blink.account.sync.fire(to, diff)
	end
end

local function playerAdded(player: Player)
	local profile = store.playerStore:StartSessionAsync(`player_{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	local scope
	if profile ~= nil then
		profile:AddUserId(player.UserId)

		profile.OnSessionEnd:Connect(function()
			store.profiles[player] = nil
			if scope then
				scope()
			end
			store.set(function(state)
				return objects.delete(state, tostring(player.UserId))
			end)
			player:Kick("Profile session ended - Please rejoin")
		end)

		if player.Parent == Players then
			migrations.migrateFields(player, profile)
			store.profiles[player] = profile
			store.set(function(state)
				return objects.set(state, tostring(player.UserId), objects.deepClone(profile.Data))
			end)
			scope = charm.effectScope(function()
				local playerComputed = charm.computed(function()
					return getAccountFor(player)
				end)
				charm.onCleanup(charm.listen(playerComputed, function(new, old)
					if new then
						profile.Data.account = objects.deepClone(new)
						replicate(player, old, new)
					end
				end))
			end)
		else
			profile:EndSession()
		end
	else
		player:Kick("Couldn't load data profile")
	end
	return function()
		if profile:IsActive() then
			profile:EndSession()
		end
		if readyForReplication[player] then
			readyForReplication[player] = nil
		end
	end
end
local function init()
	if _G.__AccountServiceInitialized then
		return
	end
	_G.__AccountServiceInitialized = true

	migrations.validateMigrations()

	observers.observePlayers(function(player: Player)
		return playerAdded(player)
	end)

	server_blink.account.ready.on(function(player)
		if not readyForReplication[player] then
			readyForReplication[player] = true
			local acc = getAccountFor(player)
			if acc then
				server_blink.account.sync.fire(player, acc)
			end
		end
	end)
end

return {
	init = init,
	playerStore = store.playerStore,
	profiles = store.profiles,
	get = store.get,

	getAccountFor = getAccountFor,
	mutateData = mutateData,
	getAccount = getAccount,
	getPlayer = getPlayer,

	abort = transaction.abort,
	transaction = transaction.transaction,
	onSuccess = transaction.onSuccess,
	onAbort = transaction.onAbort,
}
