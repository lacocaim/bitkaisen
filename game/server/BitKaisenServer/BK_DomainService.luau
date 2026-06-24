-- ModuleScript: BK_DomainService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose: Update 14 domain expansion progression, payloads, and server actions.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BitKaisenDomains = require(ReplicatedStorage:WaitForChild("BitKaisenDomains"))

local BK_DomainService = {}
local context = {}

local function getStats(player)
	return context.GetStats and context.GetStats(player) or nil
end

local function ensureExtraStats(stats)
	if context.EnsureExtraStats then
		context.EnsureExtraStats(stats)
	end
	BitKaisenDomains.Ensure(stats)
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

function BK_DomainService.GetPayload(player)
	local stats = getStats(player)
	if not stats then
		return { Domain = { Stage = "Locked", Progress = 0, Name = "Unknown Domain" }, CanTrain = false, TrainReason = "No active life." }
	end
	ensureExtraStats(stats)
	return BitKaisenDomains.GetPayload(stats)
end

function BK_DomainService.AddCombatProgress(player, stats, reason, amount)
	stats = stats or getStats(player)
	if not stats then return "" end
	ensureExtraStats(stats)
	amount = tonumber(amount) or BitKaisenDomains.GetProgressGain(stats, reason)
	local text = BitKaisenDomains.AddProgress(stats, amount, reason)
	if text ~= "" and stats.DomainAwakened == true and stats.DomainAwakeningAnnounced ~= true then
		stats.DomainAwakeningAnnounced = true
		fireMajorPopup(player, "DOMAIN AWAKENED", "Your innate territory finally took shape.", tostring(stats.DomainName or "Domain Expansion"), "A Domain can now be used in combat when you have enough CE.")
	end
	return text
end

function BK_DomainService.ProcessAction(player, actionId)
	local stats = getStats(player)
	if not stats or stats.Alive == false then
		return
	end
	ensureExtraStats(stats)
	actionId = tostring(actionId or "")

	if actionId == "train" then
		local ok, message = BitKaisenDomains.Train(stats)
		if not ok then
			fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ DOMAIN ]</b></font> " .. tostring(message or "You cannot train your domain right now."))
			return
		end
		fireLifeUpdate(player, stats, "<font color='#b78cff'><b>[ DOMAIN TRAINING ]</b></font> " .. tostring(message))
		forceSaveStats(player, "domain_train")
	elseif actionId == "stabilize" then
		local cost = 2500
		if (tonumber(stats.Money) or 0) < cost then
			fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ DOMAIN ]</b></font> Barrier stabilization costs $" .. tostring(cost) .. ".")
			return
		end
		stats.Money = math.max(0, (tonumber(stats.Money) or 0) - cost)
		stats.DomainStability = math.clamp((tonumber(stats.DomainStability) or 35) + math.random(8, 14), 0, 100)
		local gainText = BitKaisenDomains.AddProgress(stats, math.random(2, 5), "stabilize")
		fireLifeUpdate(player, stats, "<font color='#b78cff'><b>[ BARRIER STABILIZED ]</b></font> You paid a barrier specialist to stabilize your innate territory. Stability is now <b>" .. tostring(math.floor(stats.DomainStability)) .. "%</b>." .. gainText)
		forceSaveStats(player, "domain_stabilize")
	end
end

function BK_DomainService.Init(ctx)
	context = ctx or {}
	if context.IS_DEBUG then print("[BK_DomainService] Update 14 domain expansion service loaded.") end
end

return BK_DomainService
