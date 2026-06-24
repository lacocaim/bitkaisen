local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local function buildDomain(parent: Frame)
	local scroll, title = factory.createCardList(parent, "DOMAIN EXPANSION")

	local getDomain = remotes.getDomain()
	if not getDomain then
		factory.createMessageCard(scroll, "Domain system unavailable.")
		return
	end

	local ok, payload = pcall(function() return getDomain:InvokeServer() end)
	if not ok or typeof(payload) ~= "table" then
		factory.createMessageCard(scroll, "Failed to load domain data.")
		return
	end

	if not payload.HasDomain and not payload.CanLearn then
		factory.createMessageCard(scroll, "You haven't unlocked Domain Expansion yet.")
		return
	end

	local order = 1
	factory.createCard(scroll, order, {
		title = "Domain: " .. tostring(payload.DomainName or "Unknown"),
		subtitle = "Stability: " .. tostring(payload.Stability or 0) .. "% | Mastery: " .. tostring(payload.Mastery or 0) .. "%",
		body = tostring(payload.Description or ""),
		accentColor = theme.Purple,
	})
	order += 1

	if payload.CanTrain then
		factory.createCard(scroll, order, {
			title = "Train Domain",
			body = "Practice expanding your domain to increase stability and mastery.",
			actions = {
				{ label = "TRAIN", callback = function()
					local da = remotes.domainAction()
					if da then da:FireServer("train") end
				end },
			},
		})
		order += 1
	end

	if payload.CanStabilize then
		factory.createCard(scroll, order, {
			title = "Stabilize Domain",
			body = "Focus on reinforcing the barrier to prevent collapse.",
			actions = {
				{ label = "STABILIZE", callback = function()
					local da = remotes.domainAction()
					if da then da:FireServer("stabilize") end
				end },
			},
		})
		order += 1
	end

	if payload.Effects and typeof(payload.Effects) == "table" then
		local effectText = table.concat(payload.Effects, "\n")
		factory.createCard(scroll, order, {
			title = "Combat Effects",
			body = effectText,
			accentColor = theme.Gold,
		})
	end
end

local function init()
	OverlayPanel.registerPanelBuilder("domain", buildDomain)
end

return { init = init }
