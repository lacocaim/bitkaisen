local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local function buildGodMode(parent: Frame)
	local scroll, title = factory.createCardList(parent, "GOD MODE")

	local getGodMode = remotes.getGodMode()
	if not getGodMode then
		factory.createMessageCard(scroll, "God Mode system unavailable.")
		return
	end

	local ok, payload = pcall(function() return getGodMode:InvokeServer() end)
	if not ok or typeof(payload) ~= "table" then
		factory.createMessageCard(scroll, "Failed to load God Mode data.")
		return
	end

	if not payload.Active then
		factory.createMessageCard(scroll, "God Mode is not active. Purchase the God Mode pass to enable it.")
		return
	end

	local order = 1
	local controls = payload.Controls or {}
	for _, ctrl in controls do
		factory.createCard(scroll, order, {
			title = tostring(ctrl.Name or "Control"),
			subtitle = "Current: " .. tostring(ctrl.Value or "Off"),
			actions = {
				{ label = "TOGGLE", callback = function()
					local gma = remotes.godModeAction()
					if gma then gma:FireServer("toggle", ctrl.Id) end
				end },
			},
		})
		order += 1
	end

	if order == 1 then
		factory.createCard(scroll, 1, {
			title = "God Mode Active",
			subtitle = "All controls at maximum power",
			accentColor = theme.Gold,
		})
	end
end

local function init()
	OverlayPanel.registerPanelBuilder("god_mode", buildGodMode)
end

return { init = init }
