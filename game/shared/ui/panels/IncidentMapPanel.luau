local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local create = vide.create

local function buildIncidentMap(parent: Frame)
	local scroll, title = factory.createCardList(parent, "INCIDENT MAP")

	local getMap = remotes.get("GetIncidentMap")
	if not getMap then
		factory.createMessageCard(scroll, "Incident Map unavailable.")
		return
	end

	local ok, payload = pcall(function() return getMap:InvokeServer() end)
	if not ok or typeof(payload) ~= "table" then
		factory.createMessageCard(scroll, "Failed to load incident map.")
		return
	end

	local incidents = payload.Incidents
	if not incidents or #incidents == 0 then
		factory.createMessageCard(scroll, "No active incidents detected.")
		return
	end

	for i, inc in ipairs(incidents) do
		local dangColor = if inc.Danger == "High" then theme.Bad
			elseif inc.Danger == "Medium" then theme.Gold
			else theme.Green

		factory.createCard(scroll, i, {
			title = tostring(inc.Name or "Unknown Incident"),
			subtitle = "Danger: " .. tostring(inc.Danger or "Unknown"),
			body = tostring(inc.Description or ""),
			accentColor = dangColor,
			actions = inc.CanRespond and {
				{ label = "RESPOND", callback = function()
					local ia = remotes.get("IncidentMapAction")
					if ia then ia:FireServer("respond", inc.Id) end
				end },
			} or nil,
		})
	end
end

local function init()
	OverlayPanel.registerPanelBuilder("incident_map", buildIncidentMap)
end

return { init = init }
