local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local factory = require("@ui-panels/panelFactory")
local navRegistry = require("@ui-state/navRegistry")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local function buildHistory(parent: Frame)
	local scroll, title = factory.createCardList(parent, "WORLD HISTORY")

	local getWorldHistory = remotes.getWorldHistory()
	if not getWorldHistory then
		factory.createMessageCard(scroll, "History unavailable.")
		return
	end

	local ok, payload = pcall(function() return getWorldHistory:InvokeServer() end)
	if not ok or typeof(payload) ~= "table" then
		factory.createMessageCard(scroll, "Failed to load world history.")
		return
	end

	local events = payload.Events or payload
	if typeof(events) ~= "table" or #events == 0 then
		factory.createMessageCard(scroll, "No historical events recorded yet.")
		return
	end

	if payload.Summary then
		factory.createCard(scroll, 0, {
			title = "Summary",
			body = tostring(payload.Summary),
			accentColor = theme.Gold,
		})
	end

	for i, event in events do
		factory.createCard(scroll, i, {
			title = tostring(event.Year or "") .. " - " .. tostring(event.Title or "Event"),
			body = tostring(event.Description or ""),
			accentColor = theme.Blue,
		})
	end
end

local function init()
	OverlayPanel.registerPanelBuilder("history", buildHistory)
end

return { init = init }
