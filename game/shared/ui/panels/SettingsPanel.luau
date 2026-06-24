local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local uiState = require("@ui-state/uiState")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local create = vide.create
local player = Players.LocalPlayer

local VIP_SORCERER_PASS_ID = 1847855390
local EXTRA_SAVE_SLOTS_PASS_ID = 1850884816

local SHOP_PRODUCTS = {
	{ Name = "Starter Sorcerer Pack", Id = 3595826857, Type = "Product", Price = "R$", Description = "Boost your start" },
	{ Name = "Extra Save Slots", Id = 1850884816, Type = "GamePass", Price = "R$", Description = "Additional save slots" },
	{ Name = "2x Money", Id = 1849510820, Type = "GamePass", Price = "R$", Description = "Double money gains" },
	{ Name = "2x Progress", Id = 1849210885, Type = "GamePass", Price = "R$", Description = "Double progress speed" },
	{ Name = "Focused Training", Id = 3595838153, Type = "Product", Price = "R$", Description = "Intensive training session" },
	{ Name = "Recruit Reroll", Id = 3596045471, Type = "Product", Price = "R$", Description = "Reroll recruit candidates" },
	{ Name = "$5,000 Money", Id = 3596044734, Type = "Product", Price = "R$" },
	{ Name = "$25,000 Money", Id = 3595898637, Type = "Product", Price = "R$" },
	{ Name = "$100,000 Money", Id = 3596045207, Type = "Product", Price = "R$" },
}

local function buildSettings(parent: Frame)
	local scroll, title = factory.createCardList(parent, "MENU")

	local order = 1

	factory.createCard(scroll, order, {
		title = "Shop",
		subtitle = "Purchase gamepasses and products",
		accentColor = theme.Gold,
	})
	order += 1

	for _, product in SHOP_PRODUCTS do
		factory.createCard(scroll, order, {
			title = product.Name,
			body = product.Description or "",
			actions = {
				{ label = "BUY", callback = function()
					if product.Type == "GamePass" then
						pcall(function() MarketplaceService:PromptGamePassPurchase(player, product.Id) end)
					else
						pcall(function() MarketplaceService:PromptProductPurchase(player, product.Id) end)
					end
				end },
			},
		})
		order += 1
	end

	factory.createCard(scroll, order, {
		title = "Save Slots",
		subtitle = "Manage your save files",
		accentColor = theme.Blue,
		actions = {
			{ label = "LOAD", callback = function()
				local gs = remotes.getSaveSlots()
				if gs then
					local ok, slots = pcall(function() return gs:InvokeServer() end)
					if ok and typeof(slots) == "table" then
						for _, slot in slots do
							if slot.Active then continue end
						end
					end
				end
			end },
		},
	})
	order += 1

	factory.createCard(scroll, order, {
		title = "Redeem Code",
		subtitle = "Enter a code to claim rewards",
		accentColor = theme.Green,
		actions = {
			{ label = "REDEEM", callback = function() end },
		},
	})
	order += 1

	factory.createCard(scroll, order, {
		title = "Settings",
		subtitle = "Sound, music, and display options",
		accentColor = theme.SubText,
	})
end

local function init()
	OverlayPanel.registerPanelBuilder("settings", buildSettings)
end

return { init = init }
