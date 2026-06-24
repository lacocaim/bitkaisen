local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local function buildAFK(parent: Frame)
	local scroll, title = factory.createCardList(parent, "AFK STABILIZATION")

	local getAFK = remotes.getAFKStabilization()
	if not getAFK then
		factory.createMessageCard(scroll, "AFK system unavailable.")
		return
	end

	local ok, payload = pcall(function() return getAFK:InvokeServer() end)
	if not ok or typeof(payload) ~= "table" then
		factory.createMessageCard(scroll, "Failed to load AFK data.")
		return
	end

	if not payload.Active then
		factory.createMessageCard(scroll, "AFK Stabilization is not active. Purchase the pass to enable it.")
		return
	end

	factory.createCard(scroll, 1, {
		title = "AFK Stabilization Active",
		subtitle = "Time: " .. tostring(payload.TimeRemaining or "N/A"),
		body = "Your character is being maintained while you're away.",
		accentColor = theme.Green,
		actions = payload.CanToggle and {
			{ label = "TOGGLE", callback = function()
				local afka = remotes.afkStabilizationAction()
				if afka then afka:FireServer("toggle") end
			end },
		} or nil,
	})
end

local function init()
	OverlayPanel.registerPanelBuilder("afk", buildAFK)
end

return { init = init }
