-- Mobile counterpart of HelpGuidePanel.luau (PC). Groups the two onboarding-
-- adjacent but functionally separate systems (see plan "sorted-popping-haven"
-- / memory project-bitkaisen-tutorial-system):
--   1. "How To Play" -- replays the one-time onboarding tutorial on demand.
--   2. "Guide" -- toggles the persistent next-best-action hint (Fase 4).
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local mc = require("@ui/mobile/mobileComponents")
local MobileFirstTimeGuidancePanel = require("@ui/mobile/panels/MobileFirstTimeGuidancePanel")
local SettingsPanel = require("@ui-panels/SettingsPanel")

local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _g(key: string, fallback: string): string
	return BitKaisenLocale.tOrFallback(_L, "guidance." .. key, nil, fallback)
end

local theme = mc.theme
local bindTap = mc.bindTap

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui
local toggleKnob, togglePill

local function applyToggleVisual(enabled, instant)
	local knobGoal = enabled and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
	local colorGoal = enabled and theme.Green or theme.CardHover
	if instant then
		toggleKnob.Position = knobGoal
		togglePill.BackgroundColor3 = colorGoal
	else
		TweenService:Create(toggleKnob, TweenInfo.new(0.12), { Position = knobGoal }):Play()
		TweenService:Create(togglePill, TweenInfo.new(0.12), { BackgroundColor3 = colorGoal }):Play()
	end
end

local function doClose()
	gui.Enabled = false
end

local function doOpen()
	gui.Enabled = true
	applyToggleVisual(SettingsPanel.getGuideEnabled(), true)
end

local function openPanel()
	doOpen()
end

local function closePanel()
	doClose()
end

local function init()
	gui = Instance.new("ScreenGui")
	gui.Name = "BitKaisenMobileHelpGuideGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 635
	gui.Enabled = false
	gui.AutoLocalize = false
	gui.Parent = playerGui

	local sheet = mc.mobileSheet({
		name = "MobileHelpGuideSheet",
		parent = gui,
		title = _g("help_header_title", "Help & Guide"),
		onClose = doClose,
	})
	sheet.Visible = true

	local list = sheet:FindFirstChildWhichIsA("ScrollingFrame")

	local tutorialCard = mc.mobileCard({ parent = list, order = 1 })
	mc.mobileLabel({ parent = tutorialCard, text = _g("help_tutorial_title", "How To Play"), size = 16, font = Enum.Font.GothamBlack, order = 1 })
	mc.mobileLabel({
		parent = tutorialCard,
		text = _g("help_tutorial_body", "Replay the welcome walkthrough that points at each part of the dashboard."),
		size = 13,
		color = theme.SubText,
		order = 2,
	})
	mc.mobileButton({
		parent = tutorialCard,
		text = _g("help_tutorial_button", "VIEW TUTORIAL"),
		color = theme.Purple,
		order = 3,
		callback = function()
			doClose()
			MobileFirstTimeGuidancePanel.replay()
		end,
	})

	local guideCard = mc.mobileCard({ parent = list, order = 2 })
	mc.mobileLabel({ parent = guideCard, text = _g("help_guide_title", "Guide"), size = 16, font = Enum.Font.GothamBlack, order = 1 })
	mc.mobileLabel({
		parent = guideCard,
		text = _g("help_guide_body", "An indicator that suggests your next move: training, fighting, traveling..."),
		size = 13,
		color = theme.SubText,
		order = 2,
	})

	local toggleRow = Instance.new("Frame")
	toggleRow.Size = UDim2.new(1, 0, 0, 30)
	toggleRow.BackgroundTransparency = 1
	toggleRow.LayoutOrder = 3
	toggleRow.Parent = guideCard

	togglePill = Instance.new("TextButton")
	togglePill.Name = "GuideToggle"
	togglePill.Size = UDim2.fromOffset(42, 22)
	togglePill.Position = UDim2.new(0, 0, 0, 4)
	togglePill.BackgroundColor3 = theme.CardHover
	togglePill.BorderSizePixel = 0
	togglePill.Text = ""
	togglePill.AutoButtonColor = false
	togglePill.ZIndex = 5
	togglePill.Parent = toggleRow
	mc.corner(togglePill, 999)

	toggleKnob = Instance.new("Frame")
	toggleKnob.Name = "Knob"
	toggleKnob.AnchorPoint = Vector2.new(0, 0.5)
	toggleKnob.Position = UDim2.new(0, 3, 0.5, 0)
	toggleKnob.Size = UDim2.fromOffset(16, 16)
	toggleKnob.BackgroundColor3 = theme.Text
	toggleKnob.BorderSizePixel = 0
	toggleKnob.ZIndex = 6
	toggleKnob.Parent = togglePill
	mc.corner(toggleKnob, 999)

	bindTap(togglePill, function()
		local newValue = not SettingsPanel.getGuideEnabled()
		SettingsPanel.setGuideEnabled(newValue)
		applyToggleVisual(newValue)
	end)
end

return { init = init, open = openPanel, close = closePanel }
