-- Mobile counterpart of GuideController.luau (PC). Same suggestion logic
-- (shared CATEGORIES table would be nice, but the two files' target
-- resolution differs enough -- see MobileFirstTimeGuidancePanel.luau's own
-- TARGET_PATH_MAP comment -- that duplicating the small category list here
-- keeps both files self-contained and easy to read).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FocusHighlight = require("@ui/FocusHighlight")
local SettingsPanel = require("@ui-panels/SettingsPanel")
local topbarIcons = require("@ui/topbarIcons")
local cooldownFlags = require("@ui-state/cooldownFlags")
local uiState = require("@ui-state/uiState")
local TimeSkipOfferPanel = require("@ui-panels/TimeSkipOfferPanel")

local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _g(key: string, fallback: string): string
	return BitKaisenLocale.tOrFallback(_L, "guidance." .. key, nil, fallback)
end

local MAIN_GUI_NAME = "MobileGui"
local GOLD = Color3.fromRGB(255, 207, 105)

-- Fixed priority order -- see GuideController.luau (PC) for why this
-- replaced the old "highest remaining fraction" pick. "rivals" isn't a
-- per-age counter (combat is reached through Rivals -> FIGHT), so it uses
-- hasContent (an Active entry in stats.Rivals) instead.
local CATEGORIES = {
	{ navId = "activities", statField = "ActivitiesDoneThisAge", max = 3, labelKey = "guide_activities", fallback = "Try an Activity" },
	{
		navId = "rivals",
		labelKey = "guide_rivals",
		fallback = "Face a Rival",
		hasContent = function(stats): boolean
			local rivals = stats.Rivals
			if typeof(rivals) ~= "table" then
				return false
			end
			for _, rival in ipairs(rivals) do
				if tostring(rival.Status or "Active") == "Active" then
					return true
				end
			end
			return false
		end,
	},
	{ navId = "missions", statField = "MissionAttemptsThisAge", max = 10, labelKey = "guide_missions", fallback = "Take a Mission" },
	{ navId = "relationships", statField = "RelationshipActionsThisAge", max = 3, labelKey = "guide_relationships", fallback = "Visit Someone" },
	{ navId = "domain", statField = "DomainTrainingThisAge", max = 3, labelKey = "guide_domain", fallback = "Train your Domain" },
}

-- Not a NavPanel category -- resolved against the mobile age button anchor
-- instead (see resolveNavButton's special-case below).
local AGE_UP = { navId = "ageUp", labelKey = "guide_age_up", fallback = "Press +AGE" }

local function categoryUsed(stats, cat): number
	if cat.statField then
		return tonumber(stats[cat.statField]) or 0
	end
	return 0
end

local function categoryHasRoom(stats, cat): boolean
	if cat.hasContent then
		return cat.hasContent(stats)
	end
	return categoryUsed(stats, cat) < (cat.max or math.huge)
end

-- Only the 4 per-age counters count as "touched" here -- Rivals is excluded
-- (see categoryUsed).
local function allCategoriesUntouched(stats): boolean
	for _, cat in ipairs(CATEGORIES) do
		if cat.statField and categoryUsed(stats, cat) > 0 then
			return false
		end
	end
	return true
end

-- See GuideController.luau (PC) for the full rationale: none of the
-- counter-based categories' "remaining" counters reliably reflect whether a
-- category has any real content available (a Missions board can be empty
-- for the player's rank while the attempt counter is still 0). Treating
-- "visited that panel at all this age" as equivalent to "tried it"
-- sidesteps needing new server work to expose real availability.
-- No "ignore visited, fall back to whichever has the most raw room" tier --
-- see GuideController.luau (PC) for why that kept getting stuck re-picking
-- Missions specifically (cap 10, far higher than the other categories' 3,
-- so it almost never read as "truly exhausted").
local function pickBasicSuggestion(stats, visitedThisAge: { [string]: boolean })
	for _, cat in ipairs(CATEGORIES) do
		if categoryUsed(stats, cat) == 0 and not visitedThisAge[cat.navId] and categoryHasRoom(stats, cat) then
			return cat
		end
	end
	return AGE_UP
end

-- See GuideController.luau (PC) for the full rationale. All 3 rules point at
-- the Settings gear icon (Shop lives there) and fire at most once per life.
local MONETIZATION_RULES = {
	{
		id = "GuideDangerTip",
		labelKey = "guide_danger_tip",
		fallback = "Shop -- Recovery",
		check = function(stats)
			local health = tonumber(stats.Health)
			return stats.Alive ~= false and health ~= nil and health <= 20
		end,
	},
	{
		id = "GuideBrokeTip",
		labelKey = "guide_broke_tip",
		fallback = "Shop -- Money",
		check = function(stats)
			local money = tonumber(stats.Money)
			return money ~= nil and money < 500
		end,
	},
	{
		id = "GuideLosingStreakTip",
		labelKey = "guide_losing_streak_tip",
		fallback = "Shop -- Recovery Kit",
		check = function(stats)
			local losses = tonumber(stats.CombatLosses) or 0
			local wins = tonumber(stats.CombatWins) or 0
			return losses >= 3 and losses > wins
		end,
	},
	{
		-- Fusion per Luisa: offer Time Skip either when the 4 categories are
		-- genuinely exhausted (rare) OR when the player has aged up 2 ages
		-- in a row without touching any of them at all -- a much stronger,
		-- more common "just wants to skip ahead in time" signal.
		id = "GuideTimeSkipTip",
		check = function(_stats, ctx)
			return ctx.ageExhausted or ctx.quickAgeUpStreak >= 2
		end,
	},
}

local function pickMonetizationSuggestion(stats, ctx)
	for _, rule in ipairs(MONETIZATION_RULES) do
		if not cooldownFlags.isOnCooldown(stats, rule.id) and rule.check(stats, ctx) then
			return rule
		end
	end
	return nil
end

-- See GuideController.luau (PC) for why this reads stats.Settings directly
-- instead of SettingsPanel.getGuideEnabled(): that cached value starts
-- pre-seeded with the default (true) and only corrects once the first real
-- sync arrives, so a handler racing ahead of that sync can show a highlight
-- despite the persisted setting truly being off.
local function isGuideEnabled(stats): boolean
	if typeof(stats.Settings) == "table" and stats.Settings.GuideEnabled ~= nil then
		return stats.Settings.GuideEnabled == true
	end
	return SettingsPanel.getGuideEnabled()
end

local function ageKey(stats)
	return tostring(stats.Age or stats.CurrentYear or 0) .. ":" .. tostring(stats.CurrentMonth or 0)
end

local function init(playerGui: Instance)
	local updateLifeEvent = ReplicatedStorage:WaitForChild("UpdateLifeEvent")

	local state = {
		Highlight = nil :: { destroy: () -> () }?,
		LastKey = nil :: string?,
		LastStats = nil :: any,
		VisitedThisAge = {} :: { [string]: boolean },
		QuickAgeUpStreak = 0,
	}

	local function clearHighlight()
		if state.Highlight then
			state.Highlight.destroy()
			state.Highlight = nil
		end
	end

	local function resolveNavButton(navId: string): GuiObject?
		local mainGui = playerGui:FindFirstChild(MAIN_GUI_NAME)
		local mainPanel = mainGui and mainGui:FindFirstChild("MainPanel")
		if not mainPanel then
			return nil
		end
		if navId == "ageUp" then
			-- See MobileFirstTimeGuidancePanel.luau's TARGET_PATH_MAP: the
			-- mobile +AGE button's root Frame is "AgeUpOuter", not "ActionRow".
			return mainPanel:FindFirstChild("AgeUpOuter", true) :: GuiObject?
		end
		-- Mobile nav buttons are named after the raw navRegistry id (no
		-- "Button" suffix), nested inside "NavAnchor" -- see mobileShell.luau.
		local btn = mainPanel:FindFirstChild(navId, true)
		return btn :: GuiObject?
	end

	local function refresh(stats)
		state.LastStats = stats
		clearHighlight()

		-- See GuideController.luau (PC): uiState.subscribe fires on ANY panel
		-- close (including Help & Guide itself) and calls refresh() directly,
		-- bypassing the isGuideEnabled check in updateLifeEvent -- guard here
		-- too so a disabled Guide can never be re-shown by that path.
		if not isGuideEnabled(stats) then
			return
		end

		local cat = pickBasicSuggestion(stats, state.VisitedThisAge)

		local rule = pickMonetizationSuggestion(stats, {
			ageExhausted = cat == AGE_UP,
			quickAgeUpStreak = state.QuickAgeUpStreak or 0,
		})
		if rule then
			-- See GuideController.luau (PC): shows the actual purchase
			-- options directly instead of pointing at the Settings icon.
			if rule.id == "GuideTimeSkipTip" then
				TimeSkipOfferPanel.show()
				cooldownFlags.markShown(stats, rule.id)
				return
			end
			local target = topbarIcons.getSettingsIconSpot()
			if target then
				state.Highlight = FocusHighlight.attach(target, {
					color = GOLD,
					corner = 8,
					label = _g(rule.labelKey, rule.fallback),
					belowPanels = true,
				})
				cooldownFlags.markShown(stats, rule.id)
				return
			end
			task.delay(1, function()
				if state.LastStats == stats then
					refresh(stats)
				end
			end)
			return
		end

		if not cat then
			return
		end

		local target = resolveNavButton(cat.navId)
		if not target then
			-- See GuideController.luau (PC): MainPanel/NavPanel might not
			-- exist yet on the very first event after (re)joining -- retry
			-- once instead of never showing again until some other event.
			task.delay(1, function()
				if state.LastStats == stats then
					refresh(stats)
				end
			end)
			return
		end

		state.Highlight = FocusHighlight.attach(target, {
			color = GOLD,
			corner = 8,
			label = _g(cat.labelKey, cat.fallback),
			belowPanels = true,
		})
	end

	updateLifeEvent.OnClientEvent:Connect(function(stats)
		if typeof(stats) ~= "table" then
			return
		end

		local previousStats = state.LastStats

		-- See GuideController.luau (PC): always keep this current so a
		-- panel-close reevaluation isn't replaying stale pre-action stats.
		state.LastStats = stats

		if stats.Alive == false or not isGuideEnabled(stats) then
			clearHighlight()
			state.LastKey = nil
			return
		end

		local key = ageKey(stats)
		if key ~= state.LastKey then
			state.VisitedThisAge = {}
			-- See GuideController.luau (PC): count consecutive ages aged
			-- through with zero engagement, for GuideTimeSkipTip.
			if previousStats and allCategoriesUntouched(previousStats) then
				state.QuickAgeUpStreak += 1
			else
				state.QuickAgeUpStreak = 0
			end
		end
		if key == state.LastKey and state.Highlight then
			return
		end
		state.LastKey = key
		refresh(stats)
	end)

	-- See GuideController.luau (PC): visibility itself is handled by
	-- belowPanels/DisplayOrder now, not by hiding/reshowing here.
	uiState.subscribe(function(route)
		if route == "" then
			if state.LastStats then
				refresh(state.LastStats)
			end
		else
			state.VisitedThisAge[route] = true
		end
	end)

	-- See GuideController.luau (PC): without this, an already-visible
	-- highlight lingered until the next UpdateLifeEvent instead of clearing
	-- the instant the player turns the Guide off.
	SettingsPanel.onGuideEnabledChanged(function(enabled)
		if not enabled then
			clearHighlight()
		end
	end)
end

return { init = init }
