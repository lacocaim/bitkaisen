local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local function buildFreeRewards(parent: Frame)
	local scroll, title = factory.createCardList(parent, "FREE REWARDS")

	local getFreeReward = remotes.getFreeReward()
	if not getFreeReward then
		factory.createMessageCard(scroll, "Free rewards unavailable.")
		return
	end

	local ok, payload = pcall(function() return getFreeReward:InvokeServer() end)
	if not ok or typeof(payload) ~= "table" then
		factory.createMessageCard(scroll, "Failed to load free rewards.")
		return
	end

	if payload.CanClaim then
		factory.createCard(scroll, 1, {
			title = "Free Reward Available!",
			subtitle = tostring(payload.Description or "Claim your reward"),
			accentColor = theme.Gold,
			actions = {
				{ label = "CLAIM", callback = function()
					local cfr = remotes.claimFreeReward()
					if cfr then pcall(function() cfr:InvokeServer() end) end
				end },
			},
		})
	else
		factory.createCard(scroll, 1, {
			title = "No Rewards Available",
			body = "Check back later for free rewards!",
			accentColor = theme.Muted,
		})
	end
end

local function init()
	OverlayPanel.registerPanelBuilder("free_rewards", buildFreeRewards)
end

return { init = init }
