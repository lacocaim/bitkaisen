local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local playerState = require("@ui-state/playerState")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local create = vide.create

local function buildCharacterCustomization(parent: Frame)
	local scroll, title = factory.createCardList(parent, "CHARACTER CREATION")

	local submitRemote = remotes.submitCharacterCustomization()
	if not submitRemote then
		factory.createMessageCard(scroll, "Character customization unavailable.")
		return
	end

	local order = 1
	factory.createCard(scroll, order, {
		title = "Create Your Character",
		body = "Customize your appearance and begin your journey in the Jujutsu world.",
		accentColor = theme.Gold,
		actions = {
			{ label = "SUBMIT", callback = function()
				local ok, result = pcall(function()
					return submitRemote:InvokeServer({})
				end)
			end },
		},
	})
end

local function init()
	OverlayPanel.registerPanelBuilder("character_customization", buildCharacterCustomization)
end

return { init = init }
