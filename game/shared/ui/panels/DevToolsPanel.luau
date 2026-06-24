local RunService = game:GetService("RunService")
local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local factory = require("@ui-panels/panelFactory")
local navRegistry = require("@ui-state/navRegistry")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local create = vide.create
local TEST_PLACE_ID = 104206065947170

local function buildDevTools(parent: Frame)
	local scroll, title = factory.createCardList(parent, "DEV TOOLS")

	local getDevTools = remotes.getDevTools()
	if not getDevTools then
		factory.createMessageCard(scroll, "Dev tools unavailable.")
		return
	end

	local ok, payload = pcall(function() return getDevTools:InvokeServer() end)
	if not ok or typeof(payload) ~= "table" or not payload.Allowed then
		factory.createMessageCard(scroll, "Dev tools not authorized.")
		return
	end

	local order = 1

	local statActions = { "Health", "Happiness", "Smarts", "Looks", "Strength", "CursedEnergy", "Money", "Reputation" }
	for _, stat in statActions do
		factory.createCard(scroll, order, {
			title = stat,
			actions = {
				{ label = "+10", callback = function()
					local dta = remotes.devToolsAction()
					if dta then dta:FireServer("stat_delta", stat, 10) end
				end },
				{ label = "-10", callback = function()
					local dta = remotes.devToolsAction()
					if dta then dta:FireServer("stat_delta", stat, -10) end
				end },
			},
		})
		order += 1
	end

	if payload.Clans and typeof(payload.Clans) == "table" then
		for _, clan in payload.Clans do
			factory.createCard(scroll, order, {
				title = "Set Clan: " .. tostring(clan),
				actions = {
					{ label = "SET", callback = function()
						local dta = remotes.devToolsAction()
						if dta then dta:FireServer("set_clan", clan) end
					end },
				},
			})
			order += 1
		end
	end
end

local function init()
	if game.PlaceId ~= TEST_PLACE_ID and not RunService:IsStudio() then
		return
	end

	navRegistry.register({ id = "devtools", label = "DEV", order = 99, color = theme.Bad })
	OverlayPanel.registerPanelBuilder("devtools", buildDevTools)
end

return { init = init }
