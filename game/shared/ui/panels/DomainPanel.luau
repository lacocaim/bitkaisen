local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local uiState = require("@ui-state/uiState")
local responsiveScale = require("@ui/responsiveScale")
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _dom(key, fallback) return BitKaisenLocale.tOrFallback(_L, "ui." .. key, nil, fallback) end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getDomain = ReplicatedStorage:WaitForChild("GetDomain")
local domainAction = ReplicatedStorage:WaitForChild("DomainAction")

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

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenDomainGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 624
gui.Enabled = false
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "DomainOverlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.4
overlay.BorderSizePixel = 0
overlay.ZIndex = 624
overlay.Parent = gui

local window = Instance.new("Frame")
window.Name = "DomainWindow"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.fromScale(0.5, 0.52)
window.Size = UDim2.new(0.58, 0, 0.74, 0)
window.BackgroundColor3 = COLORS.Window
window.BorderSizePixel = 0
window.ZIndex = 625
window.Parent = overlay

local function makeCorner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = obj
end

local function makeStroke(obj, color)
	local s = Instance.new("UIStroke")
	s.Color = color or COLORS.Stroke
	s.Thickness = 1
	s.Transparency = 0.12
	s.Parent = obj
end

makeCorner(window, 10)
makeStroke(window)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 24, 0, 16)
title.Size = UDim2.new(1, -90, 0, 34)
title.Text = _dom("nav_domain", "DOMAIN EXPANSION")
title.TextColor3 = COLORS.Gold
title.TextSize = 22
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 626
title.Parent = window

local closeButton = Instance.new("TextButton")
closeButton.Position = UDim2.new(1, -58, 0, 16)
closeButton.Size = UDim2.new(0, 38, 0, 34)
closeButton.Text = "X"
closeButton.TextColor3 = COLORS.Red
closeButton.TextSize = 16
closeButton.Font = Enum.Font.GothamBlack
closeButton.BackgroundColor3 = Color3.fromRGB(35, 35, 46)
closeButton.BorderSizePixel = 0
closeButton.ZIndex = 627
closeButton.Parent = window
makeCorner(closeButton, 8)

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.new(0, 24, 0, 64)
scroll.Size = UDim2.new(1, -48, 1, -88)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = COLORS.Purple
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ZIndex = 626
scroll.Parent = window

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = scroll

local isOpen = false

responsiveScale.attach(window, 1114, 799)

local function clear()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") and child ~= listLayout then child:Destroy() end
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
	frame.ZIndex = 626
	frame.Parent = scroll
	makeCorner(frame, 8)
	makeStroke(frame)
	return frame
end

local function actionButton(parent, text, x, width, color, callback)
	local btn = Instance.new("TextButton")
	btn.Position = UDim2.new(0, x, 1, -48)
	btn.Size = UDim2.new(0, width, 0, 36)
	btn.BackgroundColor3 = color
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = COLORS.Text
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamBlack
	btn.ZIndex = parent.ZIndex + 2
	btn.Parent = parent
	makeCorner(btn, 8)
	btn.MouseButton1Click:Connect(callback)
	return btn
end

local function refresh()
	clear()
	local ok, data = pcall(function() return getDomain:InvokeServer() end)
	if not ok or typeof(data) ~= "table" then
		makeText(card(70), "Could not load domain data.", 13, COLORS.Red, 20, true)
		return
	end

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
	barBg.ZIndex = 628
	barBg.Parent = top
	makeCorner(barBg, 999)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(math.clamp(progress / 100, 0, 1), 0, 1, 0)
	fill.BackgroundColor3 = COLORS.Purple
	fill.BorderSizePixel = 0
	fill.ZIndex = 629
	fill.Parent = barBg
	makeCorner(fill, 999)

	makeText(top, tostring(progress) .. "/100 Domain Progress", 11, COLORS.Text, 126, true)

	local actions = card(116)
	local domainTrainingUsed = tonumber(data.DomainTrainingThisAge) or 0
	local domainTrainingMax = tonumber(data.DomainTrainingMax) or 3
	makeText(actions, "Domain Training", 15, COLORS.Text, 12, true)
	makeText(actions, tostring(data.TrainReason or "Shape your innate territory and raise Domain progress.") .. " (" .. tostring(domainTrainingUsed) .. "/" .. tostring(domainTrainingMax) .. " this age)", 11, data.CanTrain and COLORS.SubText or COLORS.Red, 40, false)
	actionButton(actions, "TRAIN", 14, 116, data.CanTrain and COLORS.Purple or Color3.fromRGB(60, 54, 72), function()
		domainAction:FireServer("train")
		task.delay(0.25, function() if isOpen then refresh() end end)
	end)
	actionButton(actions, "STABILIZE $2500", 140, 156, COLORS.Blue, function()
		domainAction:FireServer("stabilize")
		task.delay(0.25, function() if isOpen then refresh() end end)
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

local function openPanel()
	isOpen = true
	gui.Enabled = true
	refresh()
end

local function closePanel()
	isOpen = false
	gui.Enabled = false
end

closeButton.MouseButton1Click:Connect(function()
	uiState.closeRoute()
end)

overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if input.Position then
			local absPos = window.AbsolutePosition
			local absSize = window.AbsoluteSize
			local x, y = input.Position.X, input.Position.Y
			if x < absPos.X or x > absPos.X + absSize.X or y < absPos.Y or y > absPos.Y + absSize.Y then
				uiState.closeRoute()
			end
		end
	end
end)

local function init()
	uiState.subscribe(function(route)
		if route == "domain" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
