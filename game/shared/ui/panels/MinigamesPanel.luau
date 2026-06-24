local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local function buildMinigames(parent: Frame)
	local scroll, title = factory.createCardList(parent, "MINIGAMES")
	factory.createMessageCard(scroll, "Minigames appear during missions and training.\nComplete them for bonus rewards!")
end

local function init()
	OverlayPanel.registerPanelBuilder("minigames", buildMinigames)
end

return { init = init }
