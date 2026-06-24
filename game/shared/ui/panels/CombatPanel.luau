local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local create = vide.create
local source = vide.source

local combatActive = source(false)

local function buildCombat(parent: Frame)
	local scroll, title = factory.createCardList(parent, "COMBAT")

	local getCombat = remotes.getCombatState()
	if not getCombat then
		factory.createMessageCard(scroll, "Combat system unavailable.")
		return
	end

	local ok, payload = pcall(function() return getCombat:InvokeServer() end)
	if not ok or typeof(payload) ~= "table" then
		factory.createMessageCard(scroll, "No active combat.")
		return
	end

	if not payload.InCombat then
		factory.createMessageCard(scroll, "You are not in combat.")
		return
	end

	local order = 1
	factory.createCard(scroll, order, {
		title = "Opponent: " .. tostring(payload.OpponentName or "Unknown"),
		subtitle = "HP: " .. tostring(payload.PlayerHP or 0) .. " vs " .. tostring(payload.OpponentHP or 0),
		accentColor = theme.Bad,
	})
	order += 1

	local actions = payload.Actions or { "Attack", "Defend", "Technique", "Flee" }
	for _, action in actions do
		factory.createCard(scroll, order, {
			title = tostring(action),
			actions = {
				{ label = "USE", callback = function()
					local ca = remotes.combatAction()
					if ca then ca:FireServer(action) end
				end },
			},
		})
		order += 1
	end
end

local function init()
	OverlayPanel.registerPanelBuilder("combat", buildCombat)

	local combatUpdate = remotes.get("CombatStateUpdate")
	if combatUpdate then
		combatUpdate.OnClientEvent:Connect(function(data)
			if typeof(data) == "table" and data.InCombat then
				combatActive(true)
			end
		end)
	end
end

return { init = init }
