local vide = require("@packages/vide")
local theme = require("@ui/theme")
local playerState = require("@ui-state/playerState")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local create = vide.create

local MASTERY_STAGES = {
	{ Name = "Dormant", Min = 0, Color = theme.Muted },
	{ Name = "Awakening", Min = 10, Color = theme.Blue },
	{ Name = "Developing", Min = 25, Color = theme.Green },
	{ Name = "Proficient", Min = 45, Color = theme.Gold },
	{ Name = "Advanced", Min = 65, Color = theme.Orange },
	{ Name = "Mastered", Min = 85, Color = theme.Purple },
	{ Name = "Perfected", Min = 100, Color = Color3.fromRGB(255, 120, 160) },
}

local function getCurrentStage(mastery: number)
	local current = MASTERY_STAGES[1]
	for _, stage in MASTERY_STAGES do
		if mastery >= stage.Min then current = stage end
	end
	return current
end

local function buildTechniqueMastery(parent: Frame)
	local scroll, title = factory.createCardList(parent, "TECHNIQUE MASTERY")

	local stats = playerState.stats()
	if not stats then
		factory.createMessageCard(scroll, "No character data loaded.")
		return
	end

	local technique = tostring(stats.CursedTechnique or "None")
	local mastery = math.clamp(tonumber(stats.TechniqueMastery) or 0, 0, 100)
	local stage = getCurrentStage(mastery)

	factory.createCard(scroll, 1, {
		title = technique,
		subtitle = "Stage: " .. stage.Name .. " (" .. tostring(mastery) .. "%)",
		accentColor = stage.Color,
	})

	local order = 2
	for i, s in MASTERY_STAGES do
		local reached = mastery >= s.Min
		factory.createCard(scroll, order, {
			title = (reached and "\u{2713} " or "\u{25CB} ") .. s.Name,
			subtitle = "Requires: " .. tostring(s.Min) .. "% mastery",
			accentColor = reached and s.Color or theme.Muted,
		})
		order += 1
	end

	local branch = tostring(stats.TechniqueBranch or "None")
	local evoStage = tostring(stats.TechniqueEvolutionStage or "Dormant")
	factory.createCard(scroll, order, {
		title = "Evolution",
		body = "Stage: " .. evoStage .. " | Branch: " .. branch,
		accentColor = theme.Purple,
	})
end

local function init()
	OverlayPanel.registerPanelBuilder("technique_mastery", buildTechniqueMastery)
end

return { init = init }
