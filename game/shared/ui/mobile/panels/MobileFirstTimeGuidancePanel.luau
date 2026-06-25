local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local mc = require("@ui/mobile/mobileComponents")

local theme = mc.theme
local bindTap = mc.bindTap
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local MAIN_GUI_NAME = "BitKaisenGui"

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
		Body = "Your profile shows rank, technique, traits, cursed energy, money, reputation, and progress.",
		Button = "NEXT",
	},
	{
		Title = "Use The Menus",
		Body = "Missions, activities, assets, and relationships are your main ways to progress.",
		Button = "DONE",
	},
}

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

local function init()
	local updateLifeEvent = ReplicatedStorage:WaitForChild("UpdateLifeEvent")
	local markTutorialSeen = ReplicatedStorage:FindFirstChild("MarkTutorialSeen")

	local state = {
		Stats = nil,
		StepIndex = 0,
		Finished = false,
		Showing = false,
		Started = false,
		MarkedServer = false,
	}

	local function isCustomizationOpen()
		local standalone = playerGui:FindFirstChild("BitKaisenCharacterCustomizationGui")
		if standalone and standalone.Enabled ~= false then
			local overlayFrame = standalone:FindFirstChild("CharacterCustomizationOverlay", true)
			if overlayFrame and overlayFrame:IsA("GuiObject") and overlayFrame.Visible then
				return true
			end
		end

		local mainGui = playerGui:FindFirstChild(MAIN_GUI_NAME)
		if mainGui then
			local overlayFrame = mainGui:FindFirstChild("CharacterCustomizationOverlay", true)
			if overlayFrame and overlayFrame:IsA("GuiObject") and overlayFrame.Visible then
				return true
			end
		end

		return false
	end

	local function markSeen()
		if state.MarkedServer then return end
		state.MarkedServer = true
		if markTutorialSeen and markTutorialSeen:IsA("RemoteEvent") then
			markTutorialSeen:FireServer("BitKaisenFirstTimeGuidance")
		end
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "BitKaisenMobileFirstTimeGuidanceGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 680
	gui.Enabled = false
	gui.Parent = playerGui

	local card = Instance.new("Frame")
	card.Name = "GuidanceCard"
	card.AnchorPoint = Vector2.new(0.5, 1)
	card.Position = UDim2.new(0.5, 0, 1, -24)
	card.Size = UDim2.new(1, -24, 0, 150)
	card.BackgroundColor3 = theme.Panel
	card.BorderSizePixel = 0
	card.Visible = false
	-- Active=false so the hint card never intercepts taps meant for the +AGE /
	-- nav buttons it sits over. Its own Skip/Next buttons stay interactive.
	card.Active = false
	card.ClipsDescendants = true
	card.Parent = gui
	mc.corner(card, 14)
	mc.stroke(card, theme.Stroke)

	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(0, 4, 1, -20)
	accent.Position = UDim2.new(0, 12, 0, 10)
	accent.BackgroundColor3 = theme.Purple
	accent.BackgroundTransparency = 1
	accent.BorderSizePixel = 0
	accent.Parent = card
	mc.corner(accent, 4)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Position = UDim2.new(0, 26, 0, 14)
	titleLabel.Size = UDim2.new(1, -40, 0, 22)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = theme.Text
	titleLabel.TextTransparency = 1
	titleLabel.TextSize = 16
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextWrapped = true
	titleLabel.Text = ""
	titleLabel.Parent = card

	local bodyLabel = Instance.new("TextLabel")
	bodyLabel.Position = UDim2.new(0, 26, 0, 40)
	bodyLabel.Size = UDim2.new(1, -40, 0, 50)
	bodyLabel.BackgroundTransparency = 1
	bodyLabel.TextColor3 = theme.SubText
	bodyLabel.TextTransparency = 1
	bodyLabel.TextSize = 13
	bodyLabel.Font = Enum.Font.GothamMedium
	bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
	bodyLabel.TextYAlignment = Enum.TextYAlignment.Top
	bodyLabel.TextWrapped = true
	bodyLabel.Text = ""
	bodyLabel.Parent = card

	local skipButton = Instance.new("TextButton")
	skipButton.Position = UDim2.new(0, 14, 1, -52)
	skipButton.Size = UDim2.new(0, 90, 0, 40)
	skipButton.BackgroundColor3 = theme.Red
	skipButton.BackgroundTransparency = 1
	skipButton.BorderSizePixel = 0
	skipButton.Text = "SKIP"
	skipButton.TextColor3 = theme.Text
	skipButton.TextTransparency = 1
	skipButton.TextSize = 14
	skipButton.Font = Enum.Font.GothamBlack
	skipButton.AutoButtonColor = false
	skipButton.Parent = card
	mc.corner(skipButton, 10)

	local nextButton = Instance.new("TextButton")
	nextButton.AnchorPoint = Vector2.new(1, 0)
	nextButton.Position = UDim2.new(1, -14, 1, -52)
	nextButton.Size = UDim2.new(0, 120, 0, 40)
	nextButton.BackgroundColor3 = theme.Purple
	nextButton.BackgroundTransparency = 1
	nextButton.BorderSizePixel = 0
	nextButton.Text = "NEXT"
	nextButton.TextColor3 = theme.Text
	nextButton.TextTransparency = 1
	nextButton.TextSize = 14
	nextButton.Font = Enum.Font.GothamBlack
	nextButton.AutoButtonColor = false
	nextButton.Parent = card
	mc.corner(nextButton, 10)

	local function setStep(index)
		local step = STEPS[index]
		if not step then
			state.Finished = true
			state.Showing = false
			markSeen()

			TweenService:Create(card, TWEEN_FAST, { BackgroundTransparency = 1 }):Play()
			TweenService:Create(accent, TWEEN_FAST, { BackgroundTransparency = 1 }):Play()
			TweenService:Create(titleLabel, TWEEN_FAST, { TextTransparency = 1 }):Play()
			TweenService:Create(bodyLabel, TWEEN_FAST, { TextTransparency = 1 }):Play()
			TweenService:Create(skipButton, TWEEN_FAST, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
			TweenService:Create(nextButton, TWEEN_FAST, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()

			task.delay(0.16, function()
				card.Visible = false
				gui.Enabled = false
			end)
			return
		end

		state.StepIndex = index
		state.Showing = true

		titleLabel.Text = step.Title
		bodyLabel.Text = step.Body
		nextButton.Text = step.Button or "NEXT"

		gui.Enabled = true
		card.Visible = true
		card.BackgroundTransparency = 1
		accent.BackgroundTransparency = 1
		titleLabel.TextTransparency = 1
		bodyLabel.TextTransparency = 1
		skipButton.BackgroundTransparency = 1
		skipButton.TextTransparency = 1
		nextButton.BackgroundTransparency = 1
		nextButton.TextTransparency = 1

		TweenService:Create(card, TWEEN_FAST, { BackgroundTransparency = 0 }):Play()
		TweenService:Create(accent, TWEEN_FAST, { BackgroundTransparency = 0 }):Play()
		TweenService:Create(titleLabel, TWEEN_FAST, { TextTransparency = 0 }):Play()
		TweenService:Create(bodyLabel, TWEEN_FAST, { TextTransparency = 0 }):Play()
		TweenService:Create(skipButton, TWEEN_FAST, { BackgroundTransparency = 0, TextTransparency = 0 }):Play()
		TweenService:Create(nextButton, TWEEN_FAST, { BackgroundTransparency = 0, TextTransparency = 0 }):Play()
	end

	local startTutorial
	startTutorial = function()
		if state.Finished or state.Started then return end
		state.Started = true

		task.spawn(function()
			local startedAt = os.clock()

			while os.clock() - startedAt < 8 do
				if state.Finished then return end
				if not isCustomizationOpen() then break end
				task.wait(0.25)
			end

			if state.Finished or isCustomizationOpen() then
				state.Started = false
				task.delay(2, startTutorial)
				return
			end

			setStep(1)
		end)
	end

	bindTap(skipButton, function()
		state.Finished = true
		markSeen()
		setStep(#STEPS + 1)
	end)

	bindTap(nextButton, function()
		setStep(state.StepIndex + 1)
	end)

	updateLifeEvent.OnClientEvent:Connect(function(stats)
		state.Stats = stats

		if typeof(stats) ~= "table" then return end

		if stats.Alive == false then
			card.Visible = false
			state.Showing = false
			return
		end

		if tutorialAlreadySeen(stats) then
			state.Finished = true
			state.MarkedServer = true
			card.Visible = false
			gui.Enabled = false
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
end

return { init = init }
