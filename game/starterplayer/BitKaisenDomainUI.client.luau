-- LocalScript: BitKaisenDomainUI
-- Location: StarterPlayerScripts
-- Purpose: Update 14 Domain Expansion tab and responsive progression panel.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getDomain = ReplicatedStorage:WaitForChild("GetDomain")
local domainAction = ReplicatedStorage:WaitForChild("DomainAction")

local gui = playerGui:WaitForChild("BitKaisenGui")
local mainPanel = gui:WaitForChild("MainPanel")
local navPanel = mainPanel:WaitForChild("NavPanel")

local COLORS = {
	Window = Color3.fromRGB(14, 13, 20),
	Card = Color3.fromRGB(23, 22, 33),
	Card2 = Color3.fromRGB(30, 28, 42),
	Stroke = Color3.fromRGB(76, 63, 106),
	Text = Color3.fromRGB(241, 238, 248),
	SubText = Color3.fromRGB(172, 166, 190),
	Gold = Color3.fromRGB(255, 207, 94),
	Purple = Color3.fromRGB(178, 123, 255),
	Blue = Color3.fromRGB(112, 184, 255),
	Green = Color3.fromRGB(122, 236, 165),
	Red = Color3.fromRGB(224, 80, 94),
}

local old = gui:FindFirstChild("DomainOverlay")
if old then old:Destroy() end

local function corner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = obj
end

local function stroke(obj, color)
	local s = Instance.new("UIStroke")
	s.Color = color or COLORS.Stroke
	s.Thickness = 1
	s.Transparency = 0.12
	s.Parent = obj
end

local overlay = Instance.new("Frame")
overlay.Name = "DomainOverlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.4
overlay.BorderSizePixel = 0
overlay.Visible = false
overlay.ZIndex = 720
overlay.Parent = gui

local window = Instance.new("Frame")
window.Name = "DomainWindow"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.fromScale(0.5, 0.52)
window.Size = UDim2.new(0.58, 0, 0.74, 0)
window.BackgroundColor3 = COLORS.Window
window.BorderSizePixel = 0
window.ZIndex = 721
window.Parent = overlay
corner(window, 10)
stroke(window)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 24, 0, 16)
title.Size = UDim2.new(1, -90, 0, 34)
title.Text = "DOMAIN EXPANSION"
title.TextColor3 = COLORS.Gold
title.TextSize = 22
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 722
title.Parent = window

local close = Instance.new("TextButton")
close.Position = UDim2.new(1, -58, 0, 16)
close.Size = UDim2.new(0, 38, 0, 34)
close.Text = "X"
close.TextColor3 = COLORS.Red
close.TextSize = 16
close.Font = Enum.Font.GothamBlack
close.BackgroundColor3 = Color3.fromRGB(35, 35, 46)
close.BorderSizePixel = 0
close.ZIndex = 723
close.Parent = window
corner(close, 8)
close.MouseButton1Click:Connect(function() overlay.Visible = false end)

overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		overlay.Visible = false
	end
end)
window.InputBegan:Connect(function() end)

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.new(0, 24, 0, 64)
scroll.Size = UDim2.new(1, -48, 1, -88)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = COLORS.Purple
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ZIndex = 722
scroll.Parent = window

local list = Instance.new("UIListLayout")
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, 10)
list.Parent = scroll

local function clear()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") and child ~= list then child:Destroy() end
	end
end

local function makeText(parent, value, size, color, y, bold)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 14, 0, y)
	label.Size = UDim2.new(1, -28, 0, 24)
	label.Text = tostring(value or "")
	label.TextColor3 = color or COLORS.Text
	label.TextSize = size or 12
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Font = bold and Enum.Font.GothamBlack or Enum.Font.GothamMedium
	label.ZIndex = parent.ZIndex + 1
	label.Parent = parent
	return label
end

local function card(height, color)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -8, 0, height or 90)
	frame.BackgroundColor3 = color or COLORS.Card
	frame.BorderSizePixel = 0
	frame.ZIndex = 722
	frame.Parent = scroll
	corner(frame, 8)
	stroke(frame)
	return frame
end

local function actionButton(parent, text, x, width, color, callback)
	local button = Instance.new("TextButton")
	button.Position = UDim2.new(0, x, 1, -48)
	button.Size = UDim2.new(0, width, 0, 36)
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = COLORS.Text
	button.TextSize = 12
	button.Font = Enum.Font.GothamBlack
	button.ZIndex = parent.ZIndex + 2
	button.Parent = parent
	corner(button, 8)
	button.MouseButton1Click:Connect(callback)
	return button
end

local lastPayload = nil
local function render()
	clear()
	local ok, data = pcall(function() return getDomain:InvokeServer() end)
	if not ok or typeof(data) ~= "table" then
		makeText(card(70), "Could not load domain data.", 13, COLORS.Red, 20, true)
		return
	end
	lastPayload = data
	local domain = data.Domain or {}
	local progress = tonumber(domain.Progress) or 0
	local top = card(160, COLORS.Card2)
	makeText(top, tostring(domain.Name or "Unknown Domain"), 20, COLORS.Gold, 14, true)
	makeText(top, "Stage: " .. tostring(domain.Stage or "Locked") .. " | Type: " .. tostring(domain.Type or "Personal Barrier"), 12, COLORS.Purple, 46, true)
	makeText(top, "Technique: " .. tostring(data.Technique or "None") .. " | Stability: " .. tostring(domain.Stability or 0) .. "% | Cost in combat: " .. tostring(domain.Cost or 0) .. " CE", 11, COLORS.SubText, 72, false)
	local barBg = Instance.new("Frame")
	barBg.Position = UDim2.new(0, 14, 0, 106)
	barBg.Size = UDim2.new(1, -28, 0, 14)
	barBg.BackgroundColor3 = Color3.fromRGB(43, 39, 54)
	barBg.BorderSizePixel = 0
	barBg.ZIndex = 724
	barBg.Parent = top
	corner(barBg, 999)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(math.clamp(progress / 100, 0, 1), 0, 1, 0)
	fill.BackgroundColor3 = COLORS.Purple
	fill.BorderSizePixel = 0
	fill.ZIndex = 725
	fill.Parent = barBg
	corner(fill, 999)
	makeText(top, tostring(progress) .. "/100 Domain Progress", 11, COLORS.Text, 126, true)

	local actions = card(116)
	local domainTrainingUsed = tonumber(data.DomainTrainingThisAge) or 0
	local domainTrainingMax = tonumber(data.DomainTrainingMax) or 3
	makeText(actions, "Domain Training", 15, COLORS.Text, 12, true)
	makeText(actions, tostring(data.TrainReason or "Shape your innate territory and raise Domain progress.") .. " (" .. tostring(domainTrainingUsed) .. "/" .. tostring(domainTrainingMax) .. " this age)", 11, data.CanTrain and COLORS.SubText or COLORS.Red, 40, false)
	actionButton(actions, "TRAIN", 14, 116, data.CanTrain and COLORS.Purple or Color3.fromRGB(60, 54, 72), function()
		domainAction:FireServer("train")
		task.delay(0.25, render)
	end)
	actionButton(actions, "STABILIZE $2500", 140, 156, COLORS.Blue, function()
		domainAction:FireServer("stabilize")
		task.delay(0.25, render)
	end)

	local info = card(136)
	makeText(info, "Combat Effects", 15, COLORS.Text, 12, true)
	makeText(info, "Incomplete Domain unlocks a high-cost combat finisher. Complete Domain hits harder and performs better during clashes.", 11, COLORS.SubText, 42, false)
	makeText(info, "Domain Clashes: " .. tostring(data.ClashesWon or 0) .. "W / " .. tostring(data.ClashesLost or 0) .. "L | Simple Domain Progress: " .. tostring(data.SimpleDomainProgress or 0) .. "%", 11, COLORS.Green, 86, true)

	local req = data.Requirements or {}
	local milestones = card(118)
	makeText(milestones, "Milestones", 15, COLORS.Text, 12, true)
	makeText(milestones, "Seed: " .. tostring(req.Seed or 20) .. " | Incomplete Domain: " .. tostring(req.Incomplete or 55) .. " | Full Domain Expansion: " .. tostring(req.Complete or 100), 12, COLORS.Gold, 42, true)
	makeText(milestones, "Progress comes from domain training, dangerous combat, near-death losses, and future Domain clashes.", 11, COLORS.SubText, 72, false)
end

local function openDomain()
	overlay.Visible = true
	render()
end

local function makeNavButton()
	local source = navPanel:FindFirstChild("TITLESButton") or navPanel:FindFirstChild("ACTIVITIESButton") or navPanel:FindFirstChildWhichIsA("TextButton")
	local button = navPanel:FindFirstChild("DOMAINButton")
	if not button then
		button = source and source:Clone() or Instance.new("TextButton")
		button.Name = "DOMAINButton"
		button.LayoutOrder = 7.8
		button.Parent = navPanel
	end
	button.Text = "DOMAIN"
	button.MouseButton1Click:Connect(openDomain)
end

local function resize()
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	if viewport.X < 900 or UserInputService.TouchEnabled then
		window.Size = UDim2.new(0.90, 0, 0.78, 0)
	else
		window.Size = UDim2.new(0.58, 0, 0.74, 0)
	end
end

makeNavButton()
resize()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
end

print("[BitKaisenDomainUI] Update 14 Domain UI loaded.")

