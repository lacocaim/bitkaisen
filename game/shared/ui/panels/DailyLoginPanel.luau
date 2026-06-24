local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local getDailyLogin = ReplicatedStorage:WaitForChild("GetDailyLogin", 20)
local claimDailyLogin = ReplicatedStorage:WaitForChild("ClaimDailyLogin", 20)
local updateLifeEvent = ReplicatedStorage:WaitForChild("UpdateLifeEvent", 20)

if not getDailyLogin or not claimDailyLogin then
	warn("[DailyLoginPanel] Daily login remotes missing. UI skipped.")
	return { init = function() end }
end

local GUI_NAME = "BitKaisenDailyLoginGui"
local BASE_WINDOW_WIDTH = 640
local BASE_WINDOW_HEIGHT = 500
local MOBILE_WINDOW_MARGIN_X = 28
local MOBILE_WINDOW_MARGIN_Y = 70

local THEME = {
	Bg = Color3.fromRGB(0, 0, 0),
	Window = Color3.fromRGB(13, 13, 20),
	Panel = Color3.fromRGB(18, 18, 28),
	Panel2 = Color3.fromRGB(24, 24, 36),
	Panel3 = Color3.fromRGB(31, 29, 46),
	Stroke = Color3.fromRGB(68, 58, 92),
	StrokeSoft = Color3.fromRGB(42, 40, 58),
	Text = Color3.fromRGB(245, 243, 252),
	SubText = Color3.fromRGB(184, 178, 202),
	Muted = Color3.fromRGB(120, 114, 136),
	Gold = Color3.fromRGB(255, 207, 105),
	Purple = Color3.fromRGB(172, 120, 255),
	Green = Color3.fromRGB(116, 226, 153),
	Red = Color3.fromRGB(145, 32, 45),
	RedDark = Color3.fromRGB(78, 18, 29),
	Button = Color3.fromRGB(38, 34, 52),
	ButtonHover = Color3.fromRGB(52, 47, 70),
	ButtonDisabled = Color3.fromRGB(35, 35, 45),
}

local state = {
	Data = nil,
	Open = false,
	Busy = false,
	HasAutoOpened = false,
	LastStats = nil,
}

local existing = playerGui:FindFirstChild(GUI_NAME)
if existing then existing:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 635
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = false
screenGui.Parent = playerGui

local function getParentZ(parent, fallback)
	if parent and parent:IsA("GuiObject") then
		return parent.ZIndex
	end
	return fallback or 1
end

local function getViewport()
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local function isSmallScreen()
	local viewport = getViewport()
	return viewport.X < 820 or viewport.Y < 560 or UserInputService.TouchEnabled
end

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

local function tween(instance, duration, properties)
	local t = TweenService:Create(
		instance,
		TweenInfo.new(duration or 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		properties
	)
	t:Play()
	return t
end

local function makeText(parent, name, text, size, color, bold)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = text or ""
	label.TextColor3 = color or THEME.Text
	label.TextSize = size or 14
	label.Font = bold and Enum.Font.GothamBlack or Enum.Font.GothamMedium
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.RichText = true
	label.ZIndex = getParentZ(parent, 1) + 2
	label.Parent = parent
	return label
end

local function makeButton(parent, name, text, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.BackgroundColor3 = color or THEME.Button
	button.BorderSizePixel = 0
	button.Text = text or "OK"
	button.TextColor3 = THEME.Text
	button.TextSize = 12
	button.Font = Enum.Font.GothamBlack
	button.AutoButtonColor = false
	button.Active = true
	button.ZIndex = getParentZ(parent, 1) + 3
	button.Parent = parent
	addCorner(button, 9)
	addStroke(button, THEME.StrokeSoft, 1, 0)

	local baseColor = button.BackgroundColor3
	button.MouseEnter:Connect(function()
		if button.Active then
			tween(button, 0.1, { BackgroundColor3 = THEME.ButtonHover })
		end
	end)
	button.MouseLeave:Connect(function()
		tween(button, 0.1, { BackgroundColor3 = baseColor })
	end)
	return button
end

local function formatRewardShort(reward)
	if typeof(reward) ~= "table" then
		return "Reward"
	end
	return tostring(reward.Short or reward.Name or "Reward")
end

local function fetchDailyLogin()
	local ok, result = pcall(function()
		return getDailyLogin:InvokeServer()
	end)
	if ok and typeof(result) == "table" then
		state.Data = result
		return result
	end
	warn("[DailyLoginPanel] GetDailyLogin failed:", result)
	return nil
end

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.Position = UDim2.fromScale(0, 0)
overlay.BackgroundColor3 = THEME.Bg
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.Visible = false
overlay.Active = true
overlay.ZIndex = 1210
overlay.Parent = screenGui

local window = Instance.new("Frame")
window.Name = "DailyLoginWindow"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.new(0.5, 0, 0.5, 0)
window.Size = UDim2.fromOffset(BASE_WINDOW_WIDTH, BASE_WINDOW_HEIGHT)
window.BackgroundColor3 = THEME.Window
window.BackgroundTransparency = 1
window.BorderSizePixel = 0
window.Visible = false
window.ZIndex = 1211
window.Parent = overlay
addCorner(window, 14)
addStroke(window, THEME.Gold, 2, 0.08)

local windowScale = Instance.new("UIScale")
windowScale.Name = "ResponsiveScale"
windowScale.Scale = 1
windowScale.Parent = window

local title = makeText(window, "Title", "DAILY LOGIN", 22, THEME.Text, true)
title.Size = UDim2.new(1, -90, 0, 30)
title.Position = UDim2.new(0, 22, 0, 18)

local subtitle = makeText(window, "Subtitle", "Return each day for a small boost. Streak rewards cycle every 7 days.", 11, THEME.SubText, false)
subtitle.Size = UDim2.new(1, -120, 0, 20)
subtitle.Position = UDim2.new(0, 22, 0, 50)

local closeButton = makeButton(window, "CloseButton", "X", THEME.RedDark)
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Size = UDim2.new(0, 34, 0, 34)
closeButton.Position = UDim2.new(1, -18, 0, 18)

local statusCard = Instance.new("Frame")
statusCard.Name = "StatusCard"
statusCard.Size = UDim2.new(1, -44, 0, 88)
statusCard.Position = UDim2.new(0, 22, 0, 84)
statusCard.BackgroundColor3 = THEME.Panel
statusCard.BorderSizePixel = 0
statusCard.ZIndex = window.ZIndex + 1
statusCard.Parent = window
addCorner(statusCard, 11)
addStroke(statusCard, THEME.StrokeSoft, 1, 0)

local streakLabel = makeText(statusCard, "StreakLabel", "Streak: 0", 16, THEME.Gold, true)
streakLabel.Size = UDim2.new(0.5, -18, 0, 24)
streakLabel.Position = UDim2.new(0, 16, 0, 13)

local bestLabel = makeText(statusCard, "BestLabel", "Best: 0", 12, THEME.SubText, true)
bestLabel.Size = UDim2.new(0.5, -18, 0, 20)
bestLabel.Position = UDim2.new(0, 16, 0, 41)

local todayLabel = makeText(statusCard, "TodayLabel", "Today's reward: loading...", 13, THEME.Text, true)
todayLabel.Size = UDim2.new(0.5, -18, 0, 24)
todayLabel.Position = UDim2.new(0.5, 2, 0, 13)
todayLabel.TextXAlignment = Enum.TextXAlignment.Left

local statusLabel = makeText(statusCard, "StatusLabel", "", 11, THEME.SubText, false)
statusLabel.Size = UDim2.new(0.5, -18, 0, 34)
statusLabel.Position = UDim2.new(0.5, 2, 0, 41)

local rewardsFrame = Instance.new("Frame")
rewardsFrame.Name = "RewardsFrame"
rewardsFrame.Size = UDim2.new(1, -44, 0, 214)
rewardsFrame.Position = UDim2.new(0, 22, 0, 186)
rewardsFrame.BackgroundTransparency = 1
rewardsFrame.BorderSizePixel = 0
rewardsFrame.ZIndex = window.ZIndex + 1
rewardsFrame.Parent = window

local grid = Instance.new("UIGridLayout")
grid.CellPadding = UDim2.new(0, 8, 0, 8)
grid.CellSize = UDim2.new(0, 136, 0, 96)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = rewardsFrame

local rewardCards = {}

local function makeRewardCard(index)
	local card = Instance.new("Frame")
	card.Name = "Day" .. tostring(index)
	card.BackgroundColor3 = THEME.Panel
	card.BorderSizePixel = 0
	card.ZIndex = rewardsFrame.ZIndex + 1
	card.LayoutOrder = index
	card.Parent = rewardsFrame
	addCorner(card, 10)

	local stroke = addStroke(card, THEME.StrokeSoft, 1, 0)

	local day = makeText(card, "Day", "DAY " .. tostring(index), 11, THEME.Gold, true)
	day.Size = UDim2.new(1, -16, 0, 16)
	day.Position = UDim2.new(0, 8, 0, 8)
	day.TextXAlignment = Enum.TextXAlignment.Center

	local name = makeText(card, "Name", "Reward", 11, THEME.Text, true)
	name.Size = UDim2.new(1, -16, 0, 28)
	name.Position = UDim2.new(0, 8, 0, 30)
	name.TextXAlignment = Enum.TextXAlignment.Center
	name.TextYAlignment = Enum.TextYAlignment.Center

	local short = makeText(card, "Short", "+???", 11, THEME.Green, true)
	short.Size = UDim2.new(1, -16, 0, 20)
	short.Position = UDim2.new(0, 8, 0, 65)
	short.TextXAlignment = Enum.TextXAlignment.Center

	rewardCards[index] = {
		Card = card,
		Stroke = stroke,
		Day = day,
		Name = name,
		Short = short,
	}
end

for i = 1, 7 do
	makeRewardCard(i)
end

local footer = Instance.new("Frame")
footer.Name = "Footer"
footer.Size = UDim2.new(1, -44, 0, 64)
footer.Position = UDim2.new(0, 22, 1, -82)
footer.BackgroundColor3 = THEME.Panel
footer.BorderSizePixel = 0
footer.ZIndex = window.ZIndex + 1
footer.Parent = window
addCorner(footer, 11)
addStroke(footer, THEME.StrokeSoft, 1, 0)

local footerText = makeText(footer, "FooterText", "", 11, THEME.SubText, true)
footerText.Size = UDim2.new(1, -190, 1, -18)
footerText.Position = UDim2.new(0, 14, 0, 10)
footerText.TextYAlignment = Enum.TextYAlignment.Center

local claimButton = makeButton(footer, "ClaimButton", "CLAIM", THEME.Purple)
claimButton.AnchorPoint = Vector2.new(1, 0.5)
claimButton.Size = UDim2.new(0, 150, 0, 38)
claimButton.Position = UDim2.new(1, -14, 0.5, 0)

local function applyLayout()
	local viewport = getViewport()
	local scaleX = (viewport.X - MOBILE_WINDOW_MARGIN_X) / BASE_WINDOW_WIDTH
	local scaleY = (viewport.Y - MOBILE_WINDOW_MARGIN_Y) / BASE_WINDOW_HEIGHT
	local responsiveScale = math.clamp(math.min(scaleX, scaleY, 1), 0.38, 1)

	window.Size = UDim2.fromOffset(BASE_WINDOW_WIDTH, BASE_WINDOW_HEIGHT)
	window.Position = UDim2.new(0.5, 0, 0.5, 0)
	windowScale.Scale = responsiveScale
	grid.CellSize = UDim2.new(0, 136, 0, 96)
	grid.CellPadding = UDim2.new(0, 8, 0, 8)
end

local function setClaimButton(canClaim)
	if state.Busy then
		claimButton.Text = "CLAIMING..."
		claimButton.Active = false
		claimButton.BackgroundColor3 = THEME.ButtonDisabled
		claimButton.TextColor3 = THEME.Muted
		return
	end
	if canClaim then
		claimButton.Text = "CLAIM"
		claimButton.Active = true
		claimButton.BackgroundColor3 = THEME.Purple
		claimButton.TextColor3 = THEME.Text
	else
		claimButton.Text = "CLAIMED"
		claimButton.Active = false
		claimButton.BackgroundColor3 = THEME.ButtonDisabled
		claimButton.TextColor3 = THEME.Muted
	end
end

local function render(data)
	data = data or state.Data
	if typeof(data) ~= "table" then
		return
	end
	state.Data = data

	local canClaim = data.CanClaim == true
	local streak = tonumber(data.Streak) or 0
	local bestStreak = tonumber(data.BestStreak) or 0
	local totalClaims = tonumber(data.TotalClaims) or 0
	local nextStreak = tonumber(data.NextStreak) or math.max(1, streak)
	local nextReward = data.NextReward

	streakLabel.Text = "Streak: " .. tostring(streak)
	bestLabel.Text = "Best: " .. tostring(bestStreak) .. "  •  Claims: " .. tostring(totalClaims)
	todayLabel.Text = "Today's reward: " .. formatRewardShort(nextReward)

	if canClaim then
		statusLabel.Text = "Ready to claim Day " .. tostring(((nextStreak - 1) % 7) + 1) .. "."
		footerText.Text = "Claim now to continue your daily streak. Missing a day resets the streak."
	else
		statusLabel.Text = "Already claimed today. Come back tomorrow."
		footerText.Text = "Daily reward claimed. Your next reward will be available tomorrow."
	end

	local rewards = typeof(data.Rewards) == "table" and data.Rewards or {}
	local activeDay = ((math.max(1, nextStreak) - 1) % 7) + 1

	for i = 1, 7 do
		local reward = rewards[i]
		local refs = rewardCards[i]
		if refs then
			refs.Day.Text = "DAY " .. tostring(i)
			refs.Name.Text = reward and tostring(reward.Name or "Reward") or "Reward"
			refs.Short.Text = reward and tostring(reward.Short or "+???") or "+???"

			if i == activeDay and canClaim then
				refs.Card.BackgroundColor3 = Color3.fromRGB(31, 25, 44)
				refs.Stroke.Color = THEME.Gold
				refs.Stroke.Thickness = 2
				refs.Stroke.Transparency = 0.05
			elseif i == activeDay then
				refs.Card.BackgroundColor3 = Color3.fromRGB(26, 25, 34)
				refs.Stroke.Color = THEME.Purple
				refs.Stroke.Thickness = 1
				refs.Stroke.Transparency = 0.15
			else
				refs.Card.BackgroundColor3 = THEME.Panel
				refs.Stroke.Color = THEME.StrokeSoft
				refs.Stroke.Thickness = 1
				refs.Stroke.Transparency = 0
			end
		end
	end

	setClaimButton(canClaim)
end

local function openWindow(autoOpen)
	if state.Open then return end
	applyLayout()
	local data = fetchDailyLogin()
	render(data)

	state.Open = true
	screenGui.Enabled = true
	overlay.Visible = true
	window.Visible = true
	overlay.BackgroundTransparency = 1
	window.BackgroundTransparency = 1
	window.Position = UDim2.new(0.5, 0, 0.52, 0)

	tween(overlay, 0.16, { BackgroundTransparency = autoOpen and 0.46 or 0.38 })
	tween(window, 0.2, { BackgroundTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 0) })
end

local function closeWindow()
	if not state.Open then return end
	state.Open = false
	tween(overlay, 0.14, { BackgroundTransparency = 1 })
	tween(window, 0.14, { BackgroundTransparency = 1 })
	task.delay(0.16, function()
		if not state.Open then
			overlay.Visible = false
			window.Visible = false
			screenGui.Enabled = false
		end
	end)
end

closeButton.MouseButton1Click:Connect(closeWindow)

overlay.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local mousePosition = UserInputService:GetMouseLocation()
	local pos = window.AbsolutePosition
	local size = window.AbsoluteSize
	local inside = mousePosition.X >= pos.X and mousePosition.X <= pos.X + size.X
		and mousePosition.Y >= pos.Y and mousePosition.Y <= pos.Y + size.Y
	if not inside then
		closeWindow()
	end
end)

claimButton.MouseButton1Click:Connect(function()
	if state.Busy then return end
	if not state.Data or state.Data.CanClaim ~= true then return end
	state.Busy = true
	setClaimButton(false)
	claimDailyLogin:FireServer()
end)

claimDailyLogin.OnClientEvent:Connect(function(result)
	state.Busy = false
	if typeof(result) == "table" and typeof(result.Data) == "table" then
		state.Data = result.Data
		render(result.Data)
	else
		local data = fetchDailyLogin()
		render(data)
	end
end)

local function startupCheck(delayTime)
	task.delay(delayTime or 1, function()
		if not screenGui.Parent then return end
		local data = fetchDailyLogin()
		render(data)
		if data and data.CanClaim == true and not state.HasAutoOpened and not state.Open then
			state.HasAutoOpened = true
			openWindow(true)
		end
	end)
end

if updateLifeEvent then
	updateLifeEvent.OnClientEvent:Connect(function(stats)
		state.LastStats = stats
		if typeof(stats) ~= "table" or stats.Alive == false then
			return
		end
		startupCheck(0.75)
	end)
end

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyLayout)
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	task.wait()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyLayout)
	end
	applyLayout()
end)

applyLayout()
startupCheck(1.25)
startupCheck(2.75)

local function init()
	-- Daily login auto-opens via remote events; no route subscription needed.
end

return { init = init }
