-- ModuleScript: BK_BlackMarketService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose:
--   Owns the Black Market payload + buy/sell action handling: exclusive cursed
--   tools, illegal consumable items, and selling back owned cursed tools.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BitKaisenCursedTools = require(ReplicatedStorage:WaitForChild("BitKaisenCursedTools"))
local BitKaisenBlackMarketItems = require(ReplicatedStorage:WaitForChild("BitKaisenBlackMarketItems"))

local BK_BlackMarketService = {}
local context = {}

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

local function fireLifeUpdate(player, stats, message, forceResetLog)
	if context.FireLifeUpdate then
		return context.FireLifeUpdate(player, stats, message, forceResetLog)
	end
end

local function saveStats(player, reason)
	if context.SaveStats then
		return context.SaveStats(player, reason)
	end
end

local WANTED_GAIN = {
	buy_tool = { 2, 5 },
	sell_tool = { 2, 5 },
	buy_item = { 1, 3 },
}

local function raiseWantedLevel(stats, actionKind)
	local range = WANTED_GAIN[actionKind] or { 1, 3 }
	local gain = math.random(range[1], range[2])
	stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + gain, 0, 100)
end

local function getBlackMarketPayload(player)
	local stats = getStats(player)
	if not stats or not stats.Alive then
		return {}
	end
	ensureExtraStats(stats)

	return {
		Money = stats.Money or 0,
		WantedLevel = stats.WantedLevel or 0,
		ToolCatalog = BitKaisenCursedTools.GetBlackMarketCatalog(stats),
		OwnedTools = BitKaisenCursedTools.GetOwnedPayload(stats),
		ItemCatalog = BitKaisenBlackMarketItems.GetCatalogPayload(),
	}
end

local function processBlackMarketAction(player, actionId, targetId)
	local stats = getStats(player)
	if not stats or not stats.Alive then
		return
	end
	ensureExtraStats(stats)

	if (stats.Age or 0) < 16 then
		fireLifeUpdate(player, stats, "You are too young to deal with the black market.")
		return
	end

	if actionId == "BuyTool" then
		local def = BitKaisenCursedTools.GetTool(targetId)
		if not def or not tonumber(def.BlackMarketPrice) then
			fireLifeUpdate(player, stats, "That tool is not sold on the black market.")
			return
		end

		local owned = BitKaisenCursedTools.EnsureInventory(stats)
		if owned[def.Id] then
			fireLifeUpdate(player, stats, "You already own <b>" .. tostring(def.Name) .. "</b>.")
			return
		end

		local discount = math.clamp(tonumber(stats.CultSupplyDiscount) or 0, 0, 60)
		local finalPrice = math.floor(def.BlackMarketPrice * (100 - discount) / 100)

		if (stats.Money or 0) < finalPrice then
			fireLifeUpdate(player, stats, "You do not have enough money for <b>" .. tostring(def.Name) .. "</b>.")
			return
		end

		stats.Money -= finalPrice
		local currentYear = context.GetCurrentYear and context.GetCurrentYear(stats) or (2000 + (tonumber(stats.Age) or 0))
		BitKaisenCursedTools.AddTool(stats, def.Id, "Black Market", currentYear)
		raiseWantedLevel(stats, "buy_tool")
		fireLifeUpdate(player, stats, "<font color='#f0b955'><b>[ BLACK MARKET ]</b></font> Bought <b>" .. tostring(def.Name) .. "</b> for <b>$" .. tostring(finalPrice) .. "</b>. Wanted Level rose.")
		saveStats(player, "black market buy tool")

	elseif actionId == "SellTool" then
		local sold, payout, def = BitKaisenCursedTools.SellTool(stats, targetId)
		if not sold then
			fireLifeUpdate(player, stats, "You do not own that cursed tool.")
			return
		end

		stats.Money = (stats.Money or 0) + payout
		raiseWantedLevel(stats, "sell_tool")
		fireLifeUpdate(player, stats, "<font color='#f0b955'><b>[ BLACK MARKET ]</b></font> Sold <b>" .. tostring(def.Name) .. "</b> for <b>$" .. tostring(payout) .. "</b>. Wanted Level rose.")
		saveStats(player, "black market sell tool")

	elseif actionId == "BuyItem" then
		local item = BitKaisenBlackMarketItems.GetItem(targetId)
		if not item then
			fireLifeUpdate(player, stats, "That item could not be found.")
			return
		end

		local discount = math.clamp(tonumber(stats.CultSupplyDiscount) or 0, 0, 60)
		local finalPrice = math.floor(item.Price * (100 - discount) / 100)

		if (stats.Money or 0) < finalPrice then
			fireLifeUpdate(player, stats, "You do not have enough money for <b>" .. tostring(item.Name) .. "</b>.")
			return
		end

		stats.Money -= finalPrice

		local effects = item.UseEffects or {}
		if effects.Health then
			stats.Health = math.clamp((stats.Health or 100) + effects.Health, 0, 100)
		end
		if effects.Happiness then
			stats.Happiness = math.clamp((stats.Happiness or 100) + effects.Happiness, 0, 100)
		end
		if effects.CursedEnergy then
			stats.CursedEnergy = math.max(0, (stats.CursedEnergy or 0) + effects.CursedEnergy)
		end
		if effects.Reputation then
			stats.Reputation = (stats.Reputation or 0) + effects.Reputation
		end

		raiseWantedLevel(stats, "buy_item")

		local message = "<font color='#f0b955'><b>[ BLACK MARKET ]</b></font> " .. tostring(item.UseText or ("You bought and used " .. item.Name .. "."))

		if stats.Health <= 0 then
			stats.Alive = false
			stats.CauseOfDeath = stats.CauseOfDeath or ("Died from " .. tostring(item.Name))
			message = message .. "\nYour body could not take it. You died."
		end

		fireLifeUpdate(player, stats, message)
		saveStats(player, "black market buy item")
	end
end

BK_BlackMarketService.GetBlackMarketPayload = getBlackMarketPayload
BK_BlackMarketService.ProcessBlackMarketAction = processBlackMarketAction

function BK_BlackMarketService.Init(ctx)
	context = ctx or {}
end

return BK_BlackMarketService
