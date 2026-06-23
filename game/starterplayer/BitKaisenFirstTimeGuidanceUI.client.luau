-- LocalScript: BitKaisenFirstTimeGuidanceUI
-- Location: StarterPlayerScripts
-- Purpose:
--   Safe, non-blocking first-time guidance UI.
--
-- This replaces the clamped/highlight tutorial version.
-- It intentionally does NOT:
--   - draw highlight boxes over the main UI
--   - constantly tween/pulse every frame
--   - cover the nav buttons
--   - sit over character customization
--   - block clicks outside of the small tutorial card
--
-- Requires:
--   ReplicatedStorage.UpdateLifeEvent
-- Optional:
--   ReplicatedStorage.MarkTutorialSeen

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local updateLifeEvent = ReplicatedStorage:WaitForChild("UpdateLifeEvent")
local markTutorialSeen = ReplicatedStorage:FindFirstChild("MarkTutorialSeen")

local GUI_NAME = "BitKaisenFirstTimeGuidanceUI"
local MAIN_GUI_NAME = "BitKaisenGui"

local old = playerGui:FindFirstChild(GUI_NAME)
if old then
	old:Destroy()
end

local THEME = {
	Panel = Color3.fromRGB(14, 14, 21),
	Panel2 = Color3.fromRGB(22, 22, 32),
	Stroke = Color3.fromRGB(60, 54, 82),
	StrokeSoft = Color3.fromRGB(40, 38, 54),
	Text = Color3.fromRGB(245, 243, 252),
	SubText = Color3.fromRGB(185, 180, 205),
	Gold = Color3.fromRGB(255, 207, 105),
	Purple = Color3.fromRGB(172, 120, 255),
	RedDark = Color3.fromRGB(78, 18, 29),
	Button = Color3.fromRGB(38, 34, 52),
	ButtonHover = Color3.fromRGB(53, 48, 72),
}

local STEPS = {
	{
		Title = "Welcome to BitKaisen",
		Body = "Age up, make choices, and build your cursed legacy.",
		Button = "NEXT",
	},
	{
		Title = "Use + AGE",
		Body = "Aging moves your life forward. Some years are quiet, while others trigger events, missions, or relationships.",
		Button = "NEXT",
	},
	{
		Title = "Check Your Profile",
		Body = "Your right-side profile shows rank, technique, traits, cursed energy, money, reputation, and progress.",
		Button = "NEXT",
	},
	{
		Title = "Use The Menus",
		Body = "Missions, activities, assets, and relationships are your main ways to progress.",
		Button = "DONE",
	},
}

local state = {
	Stats = nil,
	StepIndex = 0,
	Finished = false,
	Showing = false,
	Started = false,
	MarkedServer = false,
}

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or THEME.Stroke
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local function tween(instance, duration, props)
	local tw = TweenService:Create(instance, TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function getViewport()
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local function isSmallScreen()
	local viewport = getViewport()
	return viewport.X < 900 or viewport.Y < 560 or UserInputService.TouchEnabled
end

local function tutorialAlreadySeen(stats)
	if typeof(stats) ~= "table" then
		return false
	end

	if stats.BitKaisenFirstTimeGuidanceSeen == true or stats.FirstTimeGuidanceSeen == true then
		return true
	end

	local flags = stats.TutorialFlags
	if typeof(flags) == "table" then
		return flags.BitKaisenFirstTimeGuidanceSeen == true or flags.FirstTimeGuidanceSeen == true
	end

	return false
end

local function isCustomizationOpen()
	local standalone = playerGui:FindFirstChild("BitKaisenCharacterCustomizationGui")
	if standalone and standalone.Enabled ~= false then
		local overlay = standalone:FindFirstChild("CharacterCustomizationOverlay", true)
		if overlay and overlay:IsA("GuiObject") and overlay.Visible then
			return true
		end
	end

	local mainGui = playerGui:FindFirstChild(MAIN_GUI_NAME)
	if mainGui then
		local overlay = mainGui:FindFirstChild("CharacterCustomizationOverlay", true)
		if overlay and overlay:IsA("GuiObject") and overlay.Visible then
			return true
		end
	end

	return false
end

local function markSeen()
	if state.MarkedServer then
		return
	end

	state.MarkedServer = true

	if markTutorialSeen and markTutorialSeen:IsA("RemoteEvent") then
		markTutorialSeen:FireServer("BitKaisenFirstTimeGuidance")
	end
end

local guideGui = Instance.new("ScreenGui")
guideGui.Name = GUI_NAME
guideGui.ResetOnSpawn = false
guideGui.IgnoreGuiInset = true
guideGui.DisplayOrder = 900
guideGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
guideGui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.BackgroundTransparency = 1
root.BorderSizePixel = 0
root.Size = UDim2.fromScale(1, 1)
root.Position = UDim2.fromScale(0, 0)
root.Active = false
root.ZIndex = 900
root.Parent = guideGui

local card = Instance.new("Frame")
card.Name = "GuidanceCard"
card.AnchorPoint = Vector2.new(0.5, 1)
card.BackgroundColor3 = THEME.Panel
card.BackgroundTransparency = 1
card.BorderSizePixel = 0
card.Visible = false
card.Active = true
card.ZIndex = 901
card.Parent = root
addCorner(card, 12)
addStroke(card, THEME.Stroke, 2, 0.08)

local accent = Instance.new("Frame")
accent.Name = "Accent"
accent.BackgroundColor3 = THEME.Purple
accent.BackgroundTransparency = 1
accent.BorderSizePixel = 0
accent.Size = UDim2.new(0, 5, 1, -18)
accent.Position = UDim2.new(0, 12, 0, 9)
accent.ZIndex = 902
accent.Parent = card
addCorner(accent, 6)

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.BackgroundTransparency = 1
titleLabel.BorderSizePixel = 0
titleLabel.Text = ""
titleLabel.TextColor3 = THEME.Text
titleLabel.TextTransparency = 1
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextYAlignment = Enum.TextYAlignment.Top
titleLabel.TextWrapped = true
titleLabel.ZIndex = 903
titleLabel.Parent = card

local bodyLabel = Instance.new("TextLabel")
bodyLabel.Name = "Body"
bodyLabel.BackgroundTransparency = 1
bodyLabel.BorderSizePixel = 0
bodyLabel.Text = ""
bodyLabel.TextColor3 = THEME.SubText
bodyLabel.TextTransparency = 1
bodyLabel.TextSize = 11
bodyLabel.Font = Enum.Font.GothamMedium
bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
bodyLabel.TextYAlignment = Enum.TextYAlignment.Top
bodyLabel.TextWrapped = true
bodyLabel.ZIndex = 903
bodyLabel.Parent = card

local function makeButton(name, text, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.BackgroundColor3 = color or THEME.Button
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.Text = text or "OK"
	button.TextColor3 = THEME.Text
	button.TextTransparency = 1
	button.TextSize = 11
	button.Font = Enum.Font.GothamBlack
	button.AutoButtonColor = false
	button.Active = true
	button.ZIndex = 904
	button.Parent = card
	addCorner(button, 8)
	addStroke(button, THEME.StrokeSoft, 1, 0)

	local base = button.BackgroundColor3

	button.MouseEnter:Connect(function()
		if button.Active then
			tween(button, 0.1, { BackgroundColor3 = THEME.ButtonHover })
		end
	end)

	button.MouseLeave:Connect(function()
		tween(button, 0.1, { BackgroundColor3 = base })
	end)

	return button
end

local skipButton = makeButton("SkipButton", "SKIP", THEME.RedDark)
local nextButton = makeButton("NextButton", "NEXT", THEME.Purple)

local function layout()
	local viewport = getViewport()
	local small = isSmallScreen()

	local width = small and math.clamp(viewport.X - 28, 280, 390) or 420
	local height = small and 106 or 116

	card.Size = UDim2.new(0, width, 0, height)
	card.Position = UDim2.new(0.5, 0, 1, small and -78 or -92)

	titleLabel.TextSize = small and 14 or 16
	titleLabel.Position = UDim2.new(0, 28, 0, 10)
	titleLabel.Size = UDim2.new(1, -44, 0, 20)

	bodyLabel.TextSize = small and 10 or 11
	bodyLabel.Position = UDim2.new(0, 28, 0, 34)
	bodyLabel.Size = UDim2.new(1, -44, 0, 40)

	skipButton.Size = UDim2.new(0, small and 66 or 78, 0, small and 27 or 30)
	skipButton.Position = UDim2.new(0, 28, 1, small and -36 or -40)
	skipButton.TextSize = small and 10 or 11

	nextButton.Size = UDim2.new(0, small and 88 or 104, 0, small and 27 or 30)
	nextButton.Position = UDim2.new(1, small and -100 or -116, 1, small and -36 or -40)
	nextButton.TextSize = small and 10 or 11
end

local function setStep(index)
	local step = STEPS[index]
	if not step then
		state.Finished = true
		state.Showing = false
		markSeen()

		tween(card, 0.12, { BackgroundTransparency = 1 })
		tween(accent, 0.1, { BackgroundTransparency = 1 })
		tween(titleLabel, 0.1, { TextTransparency = 1 })
		tween(bodyLabel, 0.1, { TextTransparency = 1 })
		tween(skipButton, 0.1, { BackgroundTransparency = 1, TextTransparency = 1 })
		tween(nextButton, 0.1, { BackgroundTransparency = 1, TextTransparency = 1 })

		task.delay(0.15, function()
			card.Visible = false
			guideGui.Enabled = false
		end)

		return
	end

	state.StepIndex = index
	state.Showing = true

	titleLabel.Text = step.Title
	bodyLabel.Text = step.Body
	nextButton.Text = step.Button or "NEXT"

	layout()

	card.Visible = true
	card.BackgroundTransparency = 1
	accent.BackgroundTransparency = 1
	titleLabel.TextTransparency = 1
	bodyLabel.TextTransparency = 1
	skipButton.BackgroundTransparency = 1
	skipButton.TextTransparency = 1
	nextButton.BackgroundTransparency = 1
	nextButton.TextTransparency = 1

	tween(card, 0.16, { BackgroundTransparency = 0 })
	tween(accent, 0.12, { BackgroundTransparency = 0 })
	tween(titleLabel, 0.12, { TextTransparency = 0 })
	tween(bodyLabel, 0.12, { TextTransparency = 0 })
	tween(skipButton, 0.12, { BackgroundTransparency = 0, TextTransparency = 0 })
	tween(nextButton, 0.12, { BackgroundTransparency = 0, TextTransparency = 0 })
end

local function startTutorial()
	if state.Finished or state.Started then
		return
	end

	state.Started = true

	task.spawn(function()
		local startedAt = os.clock()

		while os.clock() - startedAt < 8 do
			if state.Finished then
				return
			end

			if not isCustomizationOpen() then
				break
			end

			task.wait(0.25)
		end

		if state.Finished or isCustomizationOpen() then
			-- Do not force it over customization. Try again after a short delay.
			state.Started = false
			task.delay(2, startTutorial)
			return
		end

		setStep(1)
	end)
end

skipButton.MouseButton1Click:Connect(function()
	state.Finished = true
	markSeen()
	setStep(#STEPS + 1)
end)

nextButton.MouseButton1Click:Connect(function()
	setStep(state.StepIndex + 1)
end)

updateLifeEvent.OnClientEvent:Connect(function(stats)
	state.Stats = stats

	if typeof(stats) ~= "table" then
		return
	end

	if stats.Alive == false then
		card.Visible = false
		state.Showing = false
		return
	end

	if tutorialAlreadySeen(stats) then
		state.Finished = true
		state.MarkedServer = true
		card.Visible = false
		guideGui.Enabled = false
		return
	end

	if not state.Started and not state.Finished then
		task.delay(0.9, function()
			if state.Stats and state.Stats.Alive ~= false and not state.Finished then
				startTutorial()
			end
		end)
	end
end)

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	task.wait()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
	end
	layout()
end)

layout()

print("[BitKaisenFirstTimeGuidanceUI] Loaded safe non-blocking guidance UI.")

