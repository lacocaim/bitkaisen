-- Small modal opened from the "?" topbar icon (see topbarIcons.luau). Groups
-- the two onboarding-adjacent but functionally separate systems (see plan
-- "sorted-popping-haven" / memory project-bitkaisen-tutorial-system):
--   1. "How To Play" -- replays the one-time onboarding tutorial on demand.
--   2. "Guide" -- toggles the persistent next-best-action hint (Fase 4).
-- They are NOT the same feature; this panel just gives both a home since the
-- topbar was already crowded with per-system icons.
--
-- Styled to match the existing GodModePanel.luau convention (flat panel,
-- title top-left, "X" close top-right, card sections in a scrolling list)
-- instead of a one-off "classified dossier" look -- per Luisa's explicit
-- request to keep this panel visually consistent with the other feature
-- panels rather than introducing a third style.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local responsiveScale = require("@ui/responsiveScale")

local FirstTimeGuidancePanel = require("@ui-panels/FirstTimeGuidancePanel")
local SettingsPanel = require("@ui-panels/SettingsPanel")

local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _g(key: string, fallback: string): string
	return BitKaisenLocale.tOrFallback(_L, "guidance." .. key, nil, fallback)
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUI_NAME = "BitKaisenHelpGuideGui"

local THEME = {
	Bg = Color3.fromRGB(13, 13, 20),
	Panel = Color3.fromRGB(19, 19, 29),
	Panel2 = Color3.fromRGB(28, 28, 40),
	CardStroke = Color3.fromRGB(52, 48, 72),
	Stroke = Color3.fromRGB(116, 84, 165),
	Gold = Color3.fromRGB(255, 212, 94),
	Purple = Color3.fromRGB(156, 96, 246),
	Green = Color3.fromRGB(105, 220, 143),
	Red = Color3.fromRGB(235, 82, 104),
	Text = Color3.fromRGB(245, 241, 255),
	Muted = Color3.fromRGB(176, 169, 195),
	ToggleOff = Color3.fromRGB(50, 46, 64),
}

local state = { IsOpen = false }

local existing = playerGui:FindFirstChild(GUI_NAME)
if existing then existing:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 635
screenGui.Enabled = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.AutoLocalize = false
screenGui.Parent = playerGui

local function tween(instance, duration, props)
	local tw = TweenService:Create(instance, TweenInfo.new(duration or 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.Size = UDim2.fromScale(1, 1)
overlay.Visible = false
overlay.Active = true
overlay.Parent = screenGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.BackgroundColor3 = THEME.Bg
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = overlay
responsiveScale.attach(panel, 460, 320)

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = THEME.Stroke
panelStroke.Thickness = 1
panelStroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(18, 14)
title.Size = UDim2.new(1, -70, 0, 30)
title.Text = _g("help_header_title", "Help & Guide")
title.TextColor3 = THEME.Gold
title.Font = Enum.Font.GothamBlack
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -16, 0, 14)
closeButton.Size = UDim2.fromOffset(36, 32)
closeButton.BackgroundColor3 = THEME.Panel2
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = THEME.Red
closeButton.Font = Enum.Font.GothamBlack
closeButton.TextSize = 16
closeButton.AutoButtonColor = true
closeButton.Parent = panel
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 8)

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Scroll"
scroll.Position = UDim2.fromOffset(18, 56)
scroll.Size = UDim2.new(1, -36, 1, -74)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scroll

local function makeCard(height: number)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, height)
	card.BackgroundColor3 = THEME.Panel
	card.BorderSizePixel = 0
	card.Parent = scroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME.CardStroke
	stroke.Thickness = 1
	stroke.Parent = card
	return card
end

local function makeLabel(parent, text, y, height, color, size, bold)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(14, y)
	label.Size = UDim2.new(1, -28, 0, height)
	label.Text = text
	label.TextColor3 = color or THEME.Text
	label.Font = bold and Enum.Font.GothamBlack or Enum.Font.GothamBold
	label.TextSize = size or 13
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Parent = parent
	return label
end

----------------------------------------------------------------
-- Tutorial card
----------------------------------------------------------------
local tutorialCard = makeCard(112)
makeLabel(tutorialCard, _g("help_tutorial_title", "How To Play"), 12, 20, THEME.Gold, 16, true)
makeLabel(tutorialCard, _g("help_tutorial_body", "Replay the welcome walkthrough that points at each part of the dashboard."), 36, 40, THEME.Muted, 12, false)

local tutorialButton = Instance.new("TextButton")
tutorialButton.Name = "ReplayTutorial"
tutorialButton.Position = UDim2.fromOffset(14, 78)
tutorialButton.Size = UDim2.fromOffset(160, 22)
tutorialButton.BackgroundColor3 = THEME.Purple
tutorialButton.BorderSizePixel = 0
tutorialButton.Text = _g("help_tutorial_button", "VIEW TUTORIAL")
tutorialButton.TextColor3 = THEME.Text
tutorialButton.Font = Enum.Font.GothamBlack
tutorialButton.TextSize = 11
tutorialButton.AutoButtonColor = true
tutorialButton.Parent = tutorialCard
Instance.new("UICorner", tutorialButton).CornerRadius = UDim.new(0, 7)

----------------------------------------------------------------
-- Guide card
----------------------------------------------------------------
local guideCard = makeCard(112)
makeLabel(guideCard, _g("help_guide_title", "Persistent Hint"), 12, 20, THEME.Gold, 16, true)
makeLabel(guideCard, _g("help_guide_body", "An indicator that suggests your next move: training, fighting, traveling..."), 36, 40, THEME.Muted, 12, false)

local togglePill = Instance.new("TextButton")
togglePill.Name = "GuideToggle"
togglePill.Position = UDim2.fromOffset(14, 78)
togglePill.Size = UDim2.fromOffset(42, 22)
togglePill.BackgroundColor3 = THEME.ToggleOff
togglePill.BorderSizePixel = 0
togglePill.Text = ""
togglePill.AutoButtonColor = false
togglePill.Parent = guideCard
Instance.new("UICorner", togglePill).CornerRadius = UDim.new(1, 0)

local toggleKnob = Instance.new("Frame")
toggleKnob.Name = "Knob"
toggleKnob.AnchorPoint = Vector2.new(0, 0.5)
toggleKnob.Position = UDim2.new(0, 3, 0.5, 0)
toggleKnob.Size = UDim2.fromOffset(16, 16)
toggleKnob.BackgroundColor3 = THEME.Text
toggleKnob.BorderSizePixel = 0
toggleKnob.Parent = togglePill
Instance.new("UICorner", toggleKnob).CornerRadius = UDim.new(1, 0)

local function applyToggleVisual(enabled, instant)
	local knobGoal = enabled and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
	local colorGoal = enabled and THEME.Green or THEME.ToggleOff
	if instant then
		toggleKnob.Position = knobGoal
		togglePill.BackgroundColor3 = colorGoal
	else
		tween(toggleKnob, 0.12, { Position = knobGoal })
		tween(togglePill, 0.12, { BackgroundColor3 = colorGoal })
	end
end

togglePill.MouseButton1Click:Connect(function()
	local newValue = not SettingsPanel.getGuideEnabled()
	SettingsPanel.setGuideEnabled(newValue)
	applyToggleVisual(newValue)
end)

local function close()
	if not state.IsOpen then return end
	state.IsOpen = false
	overlay.Visible = false
	screenGui.Enabled = false
end

local function open()
	if state.IsOpen then return end
	state.IsOpen = true
	applyToggleVisual(SettingsPanel.getGuideEnabled(), true)
	screenGui.Enabled = true
	overlay.Visible = true
end

tutorialButton.Activated:Connect(function()
	close()
	FirstTimeGuidancePanel.replay()
end)

closeButton.Activated:Connect(close)

overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local pos = panel.AbsolutePosition
		local size = panel.AbsoluteSize
		local mouse = input.Position
		local inside = mouse.X >= pos.X and mouse.X <= pos.X + size.X and mouse.Y >= pos.Y and mouse.Y <= pos.Y + size.Y
		if not inside then
			close()
		end
	end
end)

local function init() end

return { init = init, open = open, close = close }
