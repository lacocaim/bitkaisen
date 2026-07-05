-- Mobile counterpart of GuideController.luau (PC). Same suggestion logic
-- (shared CATEGORIES table would be nice, but the two files' target
-- resolution differs enough -- see MobileFirstTimeGuidancePanel.luau's own
-- TARGET_PATH_MAP comment -- that duplicating the small category list here
-- keeps both files self-contained and easy to read).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FocusHighlight = require("@ui/FocusHighlight")
local SettingsPanel = require("@ui-panels/SettingsPanel")

local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _g(key: string, fallback: string): string
	return BitKaisenLocale.tOrFallback(_L, "guidance." .. key, nil, fallback)
end

local MAIN_GUI_NAME = "MobileGui"
local GOLD = Color3.fromRGB(255, 207, 105)

local CATEGORIES = {
	{ navId = "activities", statField = "ActivitiesDoneThisAge", max = 3, labelKey = "guide_activities", fallback = "Training -- %d sessions left" },
	{ navId = "missions", statField = "MissionAttemptsThisAge", max = 10, labelKey = "guide_missions", fallback = "Missions -- %d open" },
	{ navId = "relationships", statField = "RelationshipActionsThisAge", max = 3, labelKey = "guide_relationships", fallback = "Relationships -- %d chances left" },
	{ navId = "domain", statField = "DomainTrainingThisAge", max = 3, labelKey = "guide_domain", fallback = "Domain Training -- %d sessions left" },
}

local function pickSuggestion(stats)
	local best, bestFraction, bestRemaining = nil, -1, 0
	for _, cat in ipairs(CATEGORIES) do
		local used = tonumber(stats[cat.statField]) or 0
		local remaining = math.max(0, cat.max - used)
		local fraction = remaining / cat.max
		if remaining > 0 and fraction > bestFraction then
			best, bestFraction, bestRemaining = cat, fraction, remaining
		end
	end
	if not best then
		return nil, 0
	end
	return best, bestRemaining
end

local function ageKey(stats)
	return tostring(stats.Age or stats.CurrentYear or 0) .. ":" .. tostring(stats.CurrentMonth or 0)
end

local function init(playerGui: Instance)
	local updateLifeEvent = ReplicatedStorage:WaitForChild("UpdateLifeEvent")

	local state = {
		Highlight = nil :: { destroy: () -> () }?,
		LastKey = nil :: string?,
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
		-- Mobile nav buttons are named after the raw navRegistry id (no
		-- "Button" suffix), nested inside "NavAnchor" -- see mobileShell.luau.
		local btn = mainPanel and mainPanel:FindFirstChild(navId, true)
		return btn :: GuiObject?
	end

	local function refresh(stats)
		local cat, remaining = pickSuggestion(stats)
		clearHighlight()
		if not cat then
			return
		end

		local target = resolveNavButton(cat.navId)
		if not target then
			return
		end

		local text = string.format(_g(cat.labelKey, cat.fallback), remaining)
		state.Highlight = FocusHighlight.attach(target, {
			color = GOLD,
			corner = 8,
			label = text,
		})
	end

	updateLifeEvent.OnClientEvent:Connect(function(stats)
		if typeof(stats) ~= "table" then
			return
		end

		if stats.Alive == false or not SettingsPanel.getGuideEnabled() then
			clearHighlight()
			state.LastKey = nil
			return
		end

		local key = ageKey(stats)
		if key == state.LastKey and state.Highlight then
			return
		end
		state.LastKey = key
		refresh(stats)
	end)
end

return { init = init }
