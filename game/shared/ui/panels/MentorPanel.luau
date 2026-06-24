local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local function buildMentor(parent: Frame)
	local scroll, title = factory.createCardList(parent, "JUJUTSU MENTOR")

	local getMentor = remotes.getMentor()
	if not getMentor then
		factory.createMessageCard(scroll, "Mentor system unavailable.")
		return
	end

	local ok, payload = pcall(function() return getMentor:InvokeServer() end)
	if not ok or typeof(payload) ~= "table" then
		factory.createMessageCard(scroll, "Failed to load mentor data.")
		return
	end

	local order = 1

	if payload.IsMentor then
		factory.createCard(scroll, order, {
			title = "Active Mentor",
			subtitle = "Rank: " .. tostring(payload.Rank or "Apprentice Instructor"),
			body = "XP: " .. tostring(payload.XP or 0) .. " | Income: $" .. tostring(payload.Income or 0) .. " | Students: " .. tostring(payload.Students or 0),
			accentColor = Color3.fromRGB(55, 180, 220),
		})
	elseif payload.CanApply then
		factory.createCard(scroll, order, {
			title = "Apply to Become a Mentor",
			body = "Requirements: Graduated Jujutsu High, Age 20+, Grade 2+",
			accentColor = theme.Gold,
			actions = {
				{ label = "APPLY", callback = function()
					local ma = remotes.mentorAction()
					if ma then ma:FireServer("apply") end
				end },
			},
		})
	else
		factory.createCard(scroll, order, {
			title = "Mentor Path",
			body = tostring(payload.Reason or "You don't meet the requirements to become a Jujutsu Mentor yet."),
			accentColor = theme.Muted,
		})
	end
end

local function init()
	OverlayPanel.registerPanelBuilder("mentor", buildMentor)
end

return { init = init }
