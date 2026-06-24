local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local function buildDailyLogin(parent: Frame)
	local scroll, title = factory.createCardList(parent, "DAILY LOGIN REWARDS")

	local getDailyLogin = remotes.getDailyLogin()
	if not getDailyLogin then
		factory.createMessageCard(scroll, "Daily login system unavailable.")
		return
	end

	local ok, payload = pcall(function() return getDailyLogin:InvokeServer() end)
	if not ok or typeof(payload) ~= "table" then
		factory.createMessageCard(scroll, "Failed to load daily login data.")
		return
	end

	local streak = tonumber(payload.Streak) or 0
	local canClaim = payload.CanClaim == true
	local rewards = payload.Rewards or {}
	local order = 1

	factory.createCard(scroll, order, {
		title = "Login Streak: " .. tostring(streak) .. " day" .. (streak ~= 1 and "s" or ""),
		accentColor = theme.Gold,
		actions = canClaim and {
			{ label = "CLAIM", callback = function()
				local cd = remotes.claimDailyLogin()
				if cd then cd:FireServer() end
			end },
		} or nil,
	})
	order += 1

	for i, reward in rewards do
		local claimed = reward.Claimed == true
		factory.createCard(scroll, order, {
			title = "Day " .. tostring(i),
			subtitle = tostring(reward.Description or reward.Name or "Reward"),
			accentColor = claimed and theme.Green or (i == streak + 1 and canClaim and theme.Gold or theme.Muted),
		})
		order += 1
	end
end

local function init()
	OverlayPanel.registerPanelBuilder("daily_login", buildDailyLogin)
end

return { init = init }
