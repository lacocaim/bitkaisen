-- Fase 4 (Guía persistente): suggests the "next best action" by looking at
-- how many actions of each category the player has left this age, and
-- highlighting the corresponding NavPanel button with FocusHighlight. Gated
-- entirely by the GuideEnabled setting (see SettingsPanel.getGuideEnabled).
--
-- Counters already arrive in the same `stats` payload FirstTimeGuidancePanel
-- listens to via UpdateLifeEvent -- no new server work needed (confirmed by
-- reading BK_ActivityService/BK_MissionService/BK_RelationshipService/
-- BitKaisenDomains): ActivitiesDoneThisAge (max 3), MissionAttemptsThisAge
-- (max 10), RelationshipActionsThisAge (max 3), DomainTrainingThisAge (max 3).
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

local MAIN_GUI_NAME = "BitKaisenGui"
local GOLD = Color3.fromRGB(255, 207, 105)

-- Fixed priority order (not "highest remaining fraction" -- that produced a
-- stat readout like "Training -- 3 sessions left" instead of an actual next
-- step, per Luisa's feedback). Mirrors a normal early-game loop: try an
-- Activity, face a Rival if one's active, take a Mission, see a
-- Relationship, then Domain training -- whichever is the first one the
-- player still has room for this age. Combat itself isn't a NavPanel
-- category (it's reached through Rivals -> FIGHT), so "rivals" uses
-- hasContent (stats.Rivals has an Active entry) instead of a per-age
-- counter -- rivals aren't a "this age" resource like the other 4.
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

-- Not a NavPanel category -- resolved against ActionRow instead (see
-- resolveNavButton's special-case below).
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

-- Only the 4 per-age counters count as "touched" here -- Rivals has no
-- per-age usage concept (see categoryUsed), so it's excluded.
local function allCategoriesUntouched(stats): boolean
	for _, cat in ipairs(CATEGORIES) do
		if cat.statField and categoryUsed(stats, cat) > 0 then
			return false
		end
	end
	return true
end

-- Whether "used > 0" actually means a category had real content -- e.g. a
-- Missions board can be empty for the player's rank while
-- MissionAttemptsThisAge is still 0 -- isn't something the client can know
-- without new server work (checked: none of the 4 counter-based categories'
-- "remaining" counters reflect real availability today). Simpler fix per
-- Luisa: treat the player having VISITED that category's panel at all this
-- age as equivalent to having tried it, regardless of whether the counter
-- moved -- if they opened Missions and found nothing to take, that's still
-- "handled" for guidance purposes, so move on rather than pointing at it
-- again.
local function pickBasicSuggestion(stats, visitedThisAge: { [string]: boolean })
	-- A single pass through the list above: a category not touched AND not
	-- visited at all yet this age. No "ignore visited and fall back to
	-- whichever has the most raw room left" tier anymore -- that fallback
	-- (removed) kept re-selecting Missions specifically once every other
	-- category had been visited, because its cap (10) is so much higher
	-- than the others (3) that it almost never reads as "truly exhausted",
	-- making it look permanently stuck no matter what the player actually
	-- did elsewhere. Reaching every category's real numeric cap in a single
	-- age is also unrealistic, so requiring that before suggesting +AGE
	-- meant +AGE almost never came up either. Once everything's been
	-- touched OR visited, the next step is +AGE -- not re-nagging about
	-- whichever category happens to have the biggest counter.
	for _, cat in ipairs(CATEGORIES) do
		if categoryUsed(stats, cat) == 0 and not visitedThisAge[cat.navId] and categoryHasRoom(stats, cat) then
			return cat
		end
	end
	return AGE_UP
end

-- Subtle monetization nudges (see plan "sorted-popping-haven" Fase 6): each
-- rule is gated by a cooldown (cooldownFlags.luau, 12 ages/6 years) rather
-- than a permanent one-shot -- these 4 situations (low health, broke,
-- losing streak, wants to skip time) can all genuinely recur more than once
-- in the same life, so a single "no thanks" (or just missing it once)
-- shouldn't silence it forever. Checked in priority order before the
-- regular activity suggestion. All of them point at the Settings gear icon
-- (Shop lives there) since none of these have a NavPanel button of their
-- own -- except GuideTimeSkipTip, which opens its own offer modal directly.
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
		-- genuinely exhausted (rare -- see pickBasicSuggestion) OR when the
		-- player just aged up without touching ANY of them at all -- a
		-- common signal that they just want to skip ahead in time, which is
		-- literally what this product does. Was >= 2 ages in a row; dropped
		-- to >= 1 because an engaged player (the one actually likely to
		-- spend) almost never hits a 2-in-a-row streak, which left this
		-- firing for barely anyone (confirmed against real sales data: all 3
		-- Time Skip tiers combined were under 1% of dev product revenue).
		-- The 6-year cooldown in cooldownFlags still stops it from
		-- repeating on the same player too often.
		id = "GuideTimeSkipTip",
		check = function(_stats, ctx)
			return ctx.ageExhausted or ctx.quickAgeUpStreak >= 1
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

-- SettingsPanel's own cached GuideEnabled starts pre-seeded with
-- DEFAULT_SETTINGS (true) at module load and only gets corrected once the
-- first UpdateLifeEvent with real stats.Settings arrives. If THIS handler's
-- very first call races ahead of that sync, SettingsPanel.getGuideEnabled()
-- can read the stale default instead of a truly-off persisted setting,
-- showing a highlight that then never re-evaluates until the next real
-- age-up (confirmed: toggling the setting on then off "fixed" it, because
-- that's what forced a fresh evaluation after the sync had caught up).
-- Reading straight off THIS event's own stats.Settings sidesteps the race
-- entirely, since it can't be stale relative to itself.
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
			return mainPanel:FindFirstChild("ActionRow") :: GuiObject?
		end
		local navPanel = mainPanel:FindFirstChild("NavPanel")
		local btn = navPanel and navPanel:FindFirstChild(navId .. "Button")
		return btn :: GuiObject?
	end

	local function refresh(stats)
		state.LastStats = stats
		clearHighlight()

		-- Callers other than updateLifeEvent (e.g. uiState.subscribe firing on
		-- ANY panel close, including Help & Guide itself) call refresh()
		-- directly without checking the toggle first -- guard here too so a
		-- disabled Guide can never be re-shown by one of those paths.
		if not isGuideEnabled(stats) then
			return
		end

		local cat = pickBasicSuggestion(stats, state.VisitedThisAge)

		local rule = pickMonetizationSuggestion(stats, {
			ageExhausted = cat == AGE_UP,
			quickAgeUpStreak = state.QuickAgeUpStreak or 0,
		})
		if rule then
			-- Per Luisa: don't just point at the Settings icon and make the
			-- player dig for the product themselves -- show the actual
			-- purchase options directly (like BitSeas does), same idea as
			-- the "Keep the Guide on?" opt-in modal.
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
			-- MainPanel/NavPanel might not exist yet the instant the very
			-- first UpdateLifeEvent arrives after (re)joining -- with no
			-- retry, that single failed lookup meant the Guide never showed
			-- again until some other real stat change happened to fire a
			-- fresh event. One retry a second later is enough to catch a
			-- boot race without polling forever; bails out if newer stats
			-- have already superseded this call.
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

		-- Always keep this current, even below when the ageKey dedup skips a
		-- full refresh() -- otherwise closing a panel re-shows whatever was
		-- true BEFORE the action the player just took inside it (confirmed:
		-- doing one Activity didn't change the age, so the dedup skipped
		-- refresh() entirely, and closing the panel replayed the stale
		-- pre-Activity suggestion instead of picking up the new category).
		state.LastStats = stats

		if stats.Alive == false or not isGuideEnabled(stats) then
			clearHighlight()
			state.LastKey = nil
			return
		end

		local key = ageKey(stats)
		if key ~= state.LastKey then
			state.VisitedThisAge = {}
			-- Did the age we're LEAVING have zero engagement with any of the
			-- 4 categories -- i.e. did the player just mash +AGE without
			-- doing anything? That's the "wants to skip ahead" signal (see
			-- GuideTimeSkipTip). previousStats is nil on the very first
			-- event, which this also correctly skips.
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

	-- Marks a category "visited" for this age as soon as its panel opens --
	-- see pickBasicSuggestion's comment: opening Missions and finding
	-- nothing to take still counts as handled, so the Guide moves on rather
	-- than pointing at the same empty category again. (Visibility itself is
	-- handled by belowPanels/DisplayOrder above, not by hiding/reshowing
	-- here -- re-running refresh() on close just picks up any stats that
	-- changed while that panel was open, e.g. finishing an Activity.)
	uiState.subscribe(function(route)
		if route == "" then
			if state.LastStats then
				refresh(state.LastStats)
			end
		else
			state.VisitedThisAge[route] = true
		end
	end)

	-- Toggling the Guide off in Settings (or from the tutorial's opt-in modal)
	-- only stops NEW highlights from appearing -- without this, one already on
	-- screen lingered until the next UpdateLifeEvent instead of disappearing
	-- the instant the player turns the Guide off.
	SettingsPanel.onGuideEnabledChanged(function(enabled)
		if not enabled then
			clearHighlight()
		end
	end)
end

return { init = init }
