local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local function buildClanWar(parent: Frame)
	local scroll, title = factory.createCardList(parent, "CLAN WAR")

	local getClanWar = remotes.getClanWar()
	if not getClanWar then
		factory.createMessageCard(scroll, "Clan War system unavailable.")
		return
	end

	local ok, payload = pcall(function() return getClanWar:InvokeServer() end)
	if not ok or typeof(payload) ~= "table" then
		factory.createMessageCard(scroll, "Failed to load clan war data.")
		return
	end

	local order = 1

	if payload.Status then
		factory.createCard(scroll, order, {
			title = "War Status: " .. tostring(payload.Status),
			subtitle = payload.Opponent and ("Against: " .. tostring(payload.Opponent)) or nil,
			body = payload.Score and ("Score: " .. tostring(payload.Score)) or nil,
			accentColor = theme.Bad,
		})
		order += 1
	end

	local actions = payload.Actions or {}
	for _, action in actions do
		factory.createCard(scroll, order, {
			title = tostring(action.Name or "Action"),
			body = tostring(action.Description or ""),
			actions = {
				{ label = "DO", callback = function()
					local cwa = remotes.clanWarAction()
					if cwa then cwa:FireServer(action.Id) end
				end },
			},
		})
		order += 1
	end

	if order == 1 then
		factory.createMessageCard(scroll, "No active clan war.")
	end
end

local function init()
	OverlayPanel.registerPanelBuilder("clan_war", buildClanWar)
end

return { init = init }
