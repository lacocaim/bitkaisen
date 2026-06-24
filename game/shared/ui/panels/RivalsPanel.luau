local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local function buildRivals(parent: Frame)
	local scroll, title = factory.createCardList(parent, "RIVALS & REPUTATION")

	local getRivals = remotes.getRivals()
	if not getRivals then
		factory.createMessageCard(scroll, "Rival system unavailable.")
		return
	end

	local ok, payload = pcall(function() return getRivals:InvokeServer() end)
	if not ok or typeof(payload) ~= "table" then
		factory.createMessageCard(scroll, "Failed to load rivals.")
		return
	end

	local order = 1

	if payload.Summary and typeof(payload.Summary) == "table" then
		local s = payload.Summary
		factory.createCard(scroll, order, {
			title = "Reputation Summary",
			body = "Wins: " .. tostring(s.Wins or 0) .. " | Losses: " .. tostring(s.Losses or 0) .. " | Intimidation: " .. tostring(s.Intimidation or 0),
			accentColor = theme.Gold,
		})
		order += 1
	end

	if payload.PendingEncounter and typeof(payload.PendingEncounter) == "table" then
		local enc = payload.PendingEncounter
		factory.createCard(scroll, order, {
			title = "ENCOUNTER: " .. tostring(enc.Name or "Unknown"),
			subtitle = tostring(enc.Description or "A rival has appeared!"),
			accentColor = theme.Bad,
			actions = {
				{ label = "FIGHT", callback = function()
					local ra = remotes.rivalAction()
					if ra then ra:FireServer("fight", enc.Id) end
				end },
				{ label = "ESCAPE", callback = function()
					local ra = remotes.rivalAction()
					if ra then ra:FireServer("escape", enc.Id) end
				end },
			},
		})
		order += 1
	end

	local rivals = payload.Rivals or {}
	for _, rival in rivals do
		factory.createCard(scroll, order, {
			title = tostring(rival.Name or "Unknown Rival"),
			subtitle = "Grade: " .. tostring(rival.Grade or "?") .. " | Threat: " .. tostring(rival.Threat or 0),
			body = "Encounters: " .. tostring(rival.Encounters or 0) .. " | Outcome: " .. tostring(rival.LastOutcome or "None"),
			actions = {
				{ label = "INTEL", callback = function()
					local ra = remotes.rivalAction()
					if ra then ra:FireServer("intel", rival.Id) end
				end },
			},
		})
		order += 1
	end

	if payload.History and typeof(payload.History) == "table" and #payload.History > 0 then
		factory.createCard(scroll, order, {
			title = "Battle History",
			body = table.concat(payload.History, "\n"),
			accentColor = theme.SubText,
		})
	end
end

local function init()
	OverlayPanel.registerPanelBuilder("rivals", buildRivals)
end

return { init = init }
