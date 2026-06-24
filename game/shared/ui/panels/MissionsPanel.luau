local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local uiState = require("@ui-state/uiState")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local create = vide.create

local GRADE_COLORS = {
	["S"] = theme.Gold,
	["A"] = theme.Purple,
	["B"] = theme.Blue,
	["C"] = theme.Green,
	["D"] = theme.SubText,
}

local function buildMissions(parent: Frame)
	local scroll, title = factory.createCardList(parent, "AVAILABLE MISSIONS")

	local getMissionBoard = remotes.getMissionBoard()
	if not getMissionBoard then
		factory.createMessageCard(scroll, "Mission system unavailable.")
		return
	end

	local ok, missions = pcall(function() return getMissionBoard:InvokeServer() end)
	if not ok or typeof(missions) ~= "table" then
		factory.createMessageCard(scroll, "Failed to load missions.")
		return
	end

	if #missions == 0 then
		factory.createMessageCard(scroll, "No missions available right now.")
		return
	end

	for i, mission in missions do
		local riskGrade = tostring(mission.RiskGrade or "C")
		local accentColor = GRADE_COLORS[riskGrade] or theme.SubText

		factory.createCard(scroll, i, {
			title = tostring(mission.Name or "Unknown Mission"),
			subtitle = "Risk: " .. riskGrade .. " Grade",
			body = tostring(mission.Reward or ""),
			accentColor = accentColor,
			actions = {
				{
					label = "ACCEPT",
					callback = function()
						local ule = remotes.updateLifeEvent()
						if ule then ule:FireServer("DoMission", mission.Id) end
						uiState.closeRoute()
					end,
				},
			},
		})
	end
end

local function init()
	OverlayPanel.registerPanelBuilder("missions", buildMissions)
end

return { init = init }
