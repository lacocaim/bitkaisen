-- LocalScript: BitKaisenMissionSituationUI
-- Location: StarterPlayerScripts
-- Purpose:
--   Muted, cleaner BitKaisen event popup.
--   - less bright overall
--   - no pointless left bar on option buttons
--   - no glowing/neon text
--   - same server behavior

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local showMissionSituation = ReplicatedStorage:WaitForChild("ShowMissionSituation")
local missionChoice = ReplicatedStorage:WaitForChild("MissionChoice")
local clearPendingMission = ReplicatedStorage:FindFirstChild("ClearPendingMission")

local existing = playerGui:FindFirstChild("BitKaisenMissionSituationGui")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenMissionSituationGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 650
gui.Parent = playerGui

local THEME = {
	Panel = Color3.fromRGB(13, 13, 19),
	Panel2 = Color3.fromRGB(18, 18, 27),
	Panel3 = Color3.fromRGB(22, 22, 33),
	Stroke = Color3.fromRGB(42, 42, 58),
	StrokeSoft = Color3.fromRGB(31, 31, 43),

	RedDark = Color3.fromRGB(55, 14, 21),
	RedMid = Color3.fromRGB(76, 23, 33),
	RedSoft = Color3.fromRGB(108, 42, 56),
	RedAccent = Color3.fromRGB(150, 48, 66),

	Purple = Color3.fromRGB(165, 118, 240),
	PurpleSoft = Color3.fromRGB(96, 67, 142),
	Gold = Color3.fromRGB(225, 190, 110),

	Text = Color3.fromRGB(240, 240, 246),
	SubText = Color3.fromRGB(186, 186, 202),
	Muted = Color3.fromRGB(116, 116, 134),
	Bad = Color3.fromRGB(220, 78, 92),
}

local currentOpen = false
local clickBusy = false
local currentOptions = {}
local lastPayload = nil

local function playSFX(name)
	if _G.BitKaisenPlaySFX then
		pcall(function()
			_G.BitKaisenPlaySFX(name)
		end)
	end
end

local function tween(instance, duration, props)
	local t = TweenService:Create(instance, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local function addPadding(parent, left, right, top, bottom)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, left or 0)
	padding.PaddingRight = UDim.new(0, right or 0)
	padding.PaddingTop = UDim.new(0, top or 0)
	padding.PaddingBottom = UDim.new(0, bottom or 0)
	padding.Parent = parent
	return padding
end

local function setGradient(parent, colorA, colorB, rotation)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("UIGradient") then
			child:Destroy()
		end
	end
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, colorA),
		ColorSequenceKeypoint.new(1, colorB),
	})
	gradient.Rotation = rotation or 90
	gradient.Parent = parent
	return gradient
end

local function getViewport()
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local function isMobile()
	return getViewport().X < 900
end

local function isSmallMobile()
	return getViewport().X < 540
end

local function cleanText(value, fallback)
	if typeof(value) == "table" then
		value = fallback
	end
	local text = tostring(value or fallback or "")
	text = text:gsub("<br%s*/?>", "\n")
	text = text:gsub("^%s*table:%s*0x[%da-fA-F]+%s*$", tostring(fallback or ""))
	return text
end

local function upperContains(text, pattern)
	return string.find(string.upper(tostring(text or "")), string.upper(pattern), 1, true) ~= nil
end

local function detectStyle(payload)
	payload = payload or {}
	local raw = table.concat({
		tostring(payload.Type or ""),
		tostring(payload.MissionTitle or ""),
		tostring(payload.Title or ""),
		tostring(payload.Body or ""),
	}, " ")

	if upperContains(raw, "CURSED SPIRIT") or upperContains(raw, "CURSE") or upperContains(raw, "HAUNT") or upperContains(raw, "HUNGER") or upperContains(raw, "RUMOR") then
		return {
			Badge = "CURSED SPIRIT EVENT",
			Tag = "HAUNT",
			Accent = THEME.Purple,
			HeaderA = Color3.fromRGB(26, 15, 27),
			HeaderB = Color3.fromRGB(62, 18, 28),
			Button = Color3.fromRGB(71, 30, 45),
			ButtonHover = Color3.fromRGB(87, 37, 55),
			ButtonStroke = Color3.fromRGB(102, 71, 152),
		}
	end

	if upperContains(raw, "JUJUTSU SOCIETY") or upperContains(raw, "CLASSIFICATION") or upperContains(raw, "NOTICE") or upperContains(raw, "REGISTERED") then
		return {
			Badge = "JUJUTSU SOCIETY",
			Tag = "NOTICE",
			Accent = THEME.Gold,
			HeaderA = Color3.fromRGB(36, 25, 16),
			HeaderB = Color3.fromRGB(74, 34, 24),
			Button = Color3.fromRGB(73, 55, 28),
			ButtonHover = Color3.fromRGB(88, 66, 34),
			ButtonStroke = Color3.fromRGB(130, 101, 52),
		}
	end

	return {
		Badge = upperContains(raw, "MISSION") and "MISSION EVENT" or "LIFE EVENT",
		Tag = "CHOICE",
		Accent = THEME.RedAccent,
		HeaderA = Color3.fromRGB(28, 16, 21),
		HeaderB = Color3.fromRGB(72, 20, 29),
		Button = Color3.fromRGB(78, 31, 43),
		ButtonHover = Color3.fromRGB(95, 37, 51),
		ButtonStroke = Color3.fromRGB(126, 47, 61),
	}
end

local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.Visible = false
overlay.Active = true
overlay.ZIndex = 650
overlay.Parent = gui

local window = Instance.new("Frame")
window.Name = "EventCard"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.new(0.5, 0, 0.52, 0)
window.Size = UDim2.new(0, 420, 0, 430)
window.BackgroundColor3 = THEME.Panel
window.BorderSizePixel = 0
window.ClipsDescendants = true
window.ZIndex = 651
window.Parent = overlay
addCorner(window, 14)
local windowStroke = addStroke(window, THEME.Stroke, 1, 0.18)
setGradient(window, Color3.fromRGB(14, 14, 21), Color3.fromRGB(8, 8, 12), 90)

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.BackgroundColor3 = THEME.RedDark
topBar.BorderSizePixel = 0
topBar.ZIndex = 653
topBar.Parent = window
setGradient(topBar, Color3.fromRGB(28, 16, 21), Color3.fromRGB(72, 20, 29), 0)

local topLine = Instance.new("Frame")
topLine.Size = UDim2.new(1, 0, 0, 1)
topLine.Position = UDim2.new(0, 0, 1, -1)
topLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
topLine.BackgroundTransparency = 0.93
topLine.BorderSizePixel = 0
topLine.ZIndex = 654
topLine.Parent = topBar

local badgeLabel = Instance.new("TextLabel")
badgeLabel.Position = UDim2.new(0, 16, 0, 8)
badgeLabel.Size = UDim2.new(0.6, 0, 0, 16)
badgeLabel.BackgroundTransparency = 1
badgeLabel.TextColor3 = THEME.Text
badgeLabel.TextSize = 11
badgeLabel.Font = Enum.Font.GothamBlack
badgeLabel.TextXAlignment = Enum.TextXAlignment.Left
badgeLabel.Text = "LIFE EVENT"
badgeLabel.ZIndex = 654
badgeLabel.Parent = topBar

local subBadgeLabel = Instance.new("TextLabel")
subBadgeLabel.Position = UDim2.new(0, 16, 0, 24)
subBadgeLabel.Size = UDim2.new(0.6, 0, 0, 14)
subBadgeLabel.BackgroundTransparency = 1
subBadgeLabel.TextColor3 = THEME.SubText
subBadgeLabel.TextSize = 9
subBadgeLabel.Font = Enum.Font.GothamBold
subBadgeLabel.TextXAlignment = Enum.TextXAlignment.Left
subBadgeLabel.Text = "Situation"
subBadgeLabel.ZIndex = 654
subBadgeLabel.Parent = topBar

local tagPill = Instance.new("Frame")
tagPill.AnchorPoint = Vector2.new(1, 0.5)
tagPill.Position = UDim2.new(1, -46, 0.5, 0)
tagPill.Size = UDim2.new(0, 74, 0, 24)
tagPill.BackgroundColor3 = Color3.fromRGB(18, 18, 27)
tagPill.BorderSizePixel = 0
tagPill.ZIndex = 654
tagPill.Parent = topBar
addCorner(tagPill, 8)
addStroke(tagPill, Color3.fromRGB(255,255,255), 1, 0.94)

local tagLabel = Instance.new("TextLabel")
tagLabel.Size = UDim2.new(1, 0, 1, 0)
tagLabel.BackgroundTransparency = 1
tagLabel.TextColor3 = THEME.Text
tagLabel.TextSize = 10
tagLabel.Font = Enum.Font.GothamBlack
tagLabel.Text = "CHOICE"
tagLabel.ZIndex = 655
tagLabel.Parent = tagPill

local closeButton = Instance.new("TextButton")
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Position = UDim2.new(1, -10, 0.5, 0)
closeButton.Size = UDim2.new(0, 24, 0, 24)
closeButton.BackgroundColor3 = Color3.fromRGB(18, 18, 27)
closeButton.BorderSizePixel = 0
closeButton.TextColor3 = THEME.Bad
closeButton.TextSize = 12
closeButton.Font = Enum.Font.GothamBlack
closeButton.Text = "X"
closeButton.AutoButtonColor = false
closeButton.ZIndex = 655
closeButton.Parent = topBar
addCorner(closeButton, 8)
addStroke(closeButton, Color3.fromRGB(255,255,255), 1, 0.94)

local contentScroll = Instance.new("ScrollingFrame")
contentScroll.Position = UDim2.new(0, 0, 0, 50)
contentScroll.Size = UDim2.new(1, 0, 1, -50)
contentScroll.BackgroundTransparency = 1
contentScroll.BorderSizePixel = 0
contentScroll.ScrollBarThickness = 3
contentScroll.ScrollBarImageColor3 = THEME.RedSoft
contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
contentScroll.ZIndex = 652
contentScroll.Parent = window

local contentPadding = addPadding(contentScroll, 20, 20, 16, 16)
local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 10)
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
contentLayout.Parent = contentScroll
contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 30)
end)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = THEME.Text
titleLabel.TextSize = 20
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextWrapped = true
titleLabel.Text = "Situation"
titleLabel.LayoutOrder = 1
titleLabel.ZIndex = 653
titleLabel.Parent = contentScroll

local accentLine = Instance.new("Frame")
accentLine.Size = UDim2.new(0.42, 0, 0, 2)
accentLine.BackgroundColor3 = THEME.RedAccent
accentLine.BorderSizePixel = 0
accentLine.LayoutOrder = 2
accentLine.ZIndex = 653
accentLine.Parent = contentScroll

local bodyBox = Instance.new("Frame")
bodyBox.Size = UDim2.new(1, 0, 0, 78)
bodyBox.BackgroundColor3 = THEME.Panel2
bodyBox.BorderSizePixel = 0
bodyBox.LayoutOrder = 3
bodyBox.ZIndex = 653
bodyBox.Parent = contentScroll
addCorner(bodyBox, 10)
addStroke(bodyBox, THEME.StrokeSoft, 1, 0)

local bodyText = Instance.new("TextLabel")
bodyText.Size = UDim2.new(1, -24, 0, 0)
bodyText.Position = UDim2.new(0, 12, 0, 12)
bodyText.AutomaticSize = Enum.AutomaticSize.Y
bodyText.BackgroundTransparency = 1
bodyText.TextColor3 = Color3.fromRGB(228, 228, 238)
bodyText.TextSize = 14
bodyText.Font = Enum.Font.GothamMedium
bodyText.TextWrapped = true
bodyText.TextXAlignment = Enum.TextXAlignment.Center
bodyText.TextYAlignment = Enum.TextYAlignment.Top
bodyText.Text = "Choose how to respond."
bodyText.ZIndex = 654
bodyText.Parent = bodyBox

local questionLabel = Instance.new("TextLabel")
questionLabel.Size = UDim2.new(1, 0, 0, 20)
questionLabel.BackgroundTransparency = 1
questionLabel.TextColor3 = THEME.Text
questionLabel.TextSize = 15
questionLabel.Font = Enum.Font.GothamBlack
questionLabel.Text = "What will you do?"
questionLabel.LayoutOrder = 4
questionLabel.ZIndex = 653
questionLabel.Parent = contentScroll

local optionsHolder = Instance.new("Frame")
optionsHolder.Size = UDim2.new(1, 0, 0, 0)
optionsHolder.AutomaticSize = Enum.AutomaticSize.Y
optionsHolder.BackgroundTransparency = 1
optionsHolder.LayoutOrder = 5
optionsHolder.ZIndex = 653
optionsHolder.Parent = contentScroll

local optionsLayout = Instance.new("UIListLayout")
optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
optionsLayout.Padding = UDim.new(0, 8)
optionsLayout.Parent = optionsHolder

local fateButton = Instance.new("TextButton")
fateButton.Size = UDim2.new(1, -42, 0, 22)
fateButton.BackgroundTransparency = 1
fateButton.BorderSizePixel = 0
fateButton.TextColor3 = THEME.RedAccent
fateButton.TextSize = 12
fateButton.Font = Enum.Font.GothamBold
fateButton.Text = "Let fate decide"
fateButton.AutoButtonColor = false
fateButton.LayoutOrder = 6
fateButton.ZIndex = 653
fateButton.Parent = contentScroll

local footerLabel = Instance.new("TextLabel")
footerLabel.Size = UDim2.new(1, -10, 0, 14)
footerLabel.BackgroundTransparency = 1
footerLabel.TextColor3 = THEME.Muted
footerLabel.TextSize = 9
footerLabel.Font = Enum.Font.GothamBold
footerLabel.Text = ""
footerLabel.LayoutOrder = 7
footerLabel.ZIndex = 653
footerLabel.Parent = contentScroll

local function updateBodyHeight()
	task.defer(function()
		bodyBox.Size = UDim2.new(1, 0, 0, math.max(72, bodyText.TextBounds.Y + 26))
	end)
end
bodyText:GetPropertyChangedSignal("TextBounds"):Connect(updateBodyHeight)

local function applyResponsiveLayout()
	local mobile = isMobile()
	local small = isSmallMobile()

	if small then
		window.Size = UDim2.new(0.88, 0, 0.62, 0)
		topBar.Size = UDim2.new(1, 0, 0, 48)
		contentScroll.Position = UDim2.new(0,0,0,48)
		contentScroll.Size = UDim2.new(1,0,1,-48)
		badgeLabel.TextSize = 10
		subBadgeLabel.TextSize = 8
		tagPill.Size = UDim2.new(0, 66, 0, 22)
		tagLabel.TextSize = 9
		closeButton.Size = UDim2.new(0,22,0,22)
		contentPadding.PaddingLeft = UDim.new(0,14)
		contentPadding.PaddingRight = UDim.new(0,14)
		contentPadding.PaddingTop = UDim.new(0,14)
		contentPadding.PaddingBottom = UDim.new(0,14)
		titleLabel.TextSize = 17
		bodyText.TextSize = 13
		questionLabel.TextSize = 13
		fateButton.TextSize = 11
	elseif mobile then
		window.Size = UDim2.new(0.76, 0, 0.60, 0)
		topBar.Size = UDim2.new(1, 0, 0, 50)
		contentScroll.Position = UDim2.new(0,0,0,50)
		contentScroll.Size = UDim2.new(1,0,1,-50)
		badgeLabel.TextSize = 10
		subBadgeLabel.TextSize = 8
		tagPill.Size = UDim2.new(0, 70, 0, 24)
		tagLabel.TextSize = 10
		closeButton.Size = UDim2.new(0,24,0,24)
		contentPadding.PaddingLeft = UDim.new(0,18)
		contentPadding.PaddingRight = UDim.new(0,18)
		contentPadding.PaddingTop = UDim.new(0,16)
		contentPadding.PaddingBottom = UDim.new(0,16)
		titleLabel.TextSize = 18
		bodyText.TextSize = 13
		questionLabel.TextSize = 14
		fateButton.TextSize = 11
	else
		window.Size = UDim2.new(0, 420, 0, 430)
		topBar.Size = UDim2.new(1, 0, 0, 50)
		contentScroll.Position = UDim2.new(0,0,0,50)
		contentScroll.Size = UDim2.new(1,0,1,-50)
		badgeLabel.TextSize = 11
		subBadgeLabel.TextSize = 9
		tagPill.Size = UDim2.new(0, 74, 0, 24)
		tagLabel.TextSize = 10
		closeButton.Size = UDim2.new(0,24,0,24)
		contentPadding.PaddingLeft = UDim.new(0,20)
		contentPadding.PaddingRight = UDim.new(0,20)
		contentPadding.PaddingTop = UDim.new(0,16)
		contentPadding.PaddingBottom = UDim.new(0,16)
		titleLabel.TextSize = 20
		bodyText.TextSize = 14
		questionLabel.TextSize = 15
		fateButton.TextSize = 12
	end
	updateBodyHeight()
end

local function clearOptions()
	for _, child in ipairs(optionsHolder:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function closeWindow(sendClear)
	if not currentOpen then
		overlay.Visible = false
		return
	end
	currentOpen = false
	clickBusy = false
	if sendClear == true and clearPendingMission then
		clearPendingMission:FireServer()
	end
	tween(window, 0.13, {Position = UDim2.new(0.5, 0, 0.55, 0), BackgroundTransparency = 1})
	tween(overlay, 0.13, {BackgroundTransparency = 1})
	task.delay(0.15, function()
		if not currentOpen then
			overlay.Visible = false
			window.Position = UDim2.new(0.5, 0, 0.52, 0)
			window.BackgroundTransparency = 0
		end
	end)
end

local function chooseOption(optionData, index)
	if clickBusy or not currentOpen then return end
	clickBusy = true
	playSFX("ChoiceSelect")
	local optionIndex = tonumber(optionData and optionData.Index) or index
	closeWindow(false)
	missionChoice:FireServer(optionIndex)
end

local function makeOptionButton(optionData, index, style)
	local button = Instance.new("TextButton")
	button.Name = "Choice" .. tostring(index)
	button.Size = UDim2.new(1, 0, 0, isSmallMobile() and 38 or 42)
	button.BackgroundColor3 = style.Button
	button.BorderSizePixel = 0
	button.TextColor3 = THEME.Text
	button.TextSize = isSmallMobile() and 13 or 14
	button.Font = Enum.Font.GothamBold
	button.TextWrapped = true
	button.TextXAlignment = Enum.TextXAlignment.Center
	button.TextYAlignment = Enum.TextYAlignment.Center
	button.TextStrokeTransparency = 1
	button.Text = cleanText(optionData and optionData.Text, "Option " .. tostring(index))
	button.AutoButtonColor = false
	button.LayoutOrder = index
	button.ZIndex = 654
	button.Parent = optionsHolder
	addCorner(button, 9)
	local stroke = addStroke(button, style.ButtonStroke, 1, 0.15)

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 7)
	padding.PaddingBottom = UDim.new(0, 7)
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = button

	button.MouseEnter:Connect(function()
		tween(button, 0.12, {BackgroundColor3 = style.ButtonHover})
		tween(stroke, 0.12, {Transparency = 0.04})
	end)
	button.MouseLeave:Connect(function()
		tween(button, 0.12, {BackgroundColor3 = style.Button})
		tween(stroke, 0.12, {Transparency = 0.15})
	end)
	button.MouseButton1Down:Connect(function()
		tween(button, 0.06, {BackgroundColor3 = THEME.Panel3})
	end)
	button.MouseButton1Click:Connect(function()
		chooseOption(optionData, index)
	end)
end

local function pickRandomOption()
	if clickBusy or not currentOpen or #currentOptions <= 0 then return end
	local randomIndex = math.random(1, #currentOptions)
	chooseOption(currentOptions[randomIndex], randomIndex)
end

local function openWindow(data)
	data = data or {}
	lastPayload = data
	clearOptions()
	applyResponsiveLayout()

	local style = detectStyle(data)
	local missionTitle = cleanText(data.MissionTitle or data.Type or "Situation", "Situation")
	local title = cleanText(data.Title or data.MissionTitle or "Situation", "Situation")
	local body = cleanText(data.Body or "Choose how to respond.", "Choose how to respond.")

	currentOptions = data.Options
	if typeof(currentOptions) ~= "table" or #currentOptions <= 0 then
		currentOptions = {{Index = 1, Text = "Continue"}}
	end

	setGradient(topBar, style.HeaderA, style.HeaderB, 0)
	windowStroke.Color = style.ButtonStroke
	badgeLabel.Text = style.Badge
	subBadgeLabel.Text = missionTitle
	tagLabel.Text = style.Tag
	accentLine.BackgroundColor3 = style.Accent
	fateButton.TextColor3 = style.Accent
	titleLabel.Text = title
	bodyText.Text = body
	updateBodyHeight()

	local extraFooter = ""
	if data.Footer and tostring(data.Footer) ~= "" then
		extraFooter = tostring(data.Footer)
	elseif data.Highlight and tostring(data.Highlight) ~= "" then
		extraFooter = tostring(data.Highlight)
	end
	footerLabel.Text = extraFooter

	for index, optionData in ipairs(currentOptions) do
		makeOptionButton(optionData, index, style)
	end

	fateButton.Visible = #currentOptions >= 2
	contentScroll.CanvasPosition = Vector2.new(0,0)
	overlay.Visible = true
	overlay.BackgroundTransparency = 1
	window.BackgroundTransparency = 1
	window.Position = UDim2.new(0.5, 0, 0.56, 0)
	currentOpen = true
	clickBusy = false
	playSFX("PopupOpen")
	tween(overlay, 0.16, {BackgroundTransparency = 0.38})
	tween(window, 0.18, {BackgroundTransparency = 0, Position = UDim2.new(0.5, 0, isMobile() and 0.5 or 0.52, 0)})
end

closeButton.MouseEnter:Connect(function()
	tween(closeButton, 0.12, {BackgroundColor3 = Color3.fromRGB(35, 20, 27)})
end)
closeButton.MouseLeave:Connect(function()
	tween(closeButton, 0.12, {BackgroundColor3 = Color3.fromRGB(18, 18, 27)})
end)
closeButton.MouseButton1Click:Connect(function()
	playSFX("ChoiceSelect")
	closeWindow(true)
end)

fateButton.MouseEnter:Connect(function()
	tween(fateButton, 0.12, {TextColor3 = THEME.Text})
end)
fateButton.MouseLeave:Connect(function()
	local style = detectStyle(lastPayload or {})
	tween(fateButton, 0.12, {TextColor3 = style.Accent})
end)
fateButton.MouseButton1Click:Connect(pickRandomOption)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Escape and currentOpen then
		closeWindow(true)
	end
end)

showMissionSituation.OnClientEvent:Connect(openWindow)

applyResponsiveLayout()

local function hookCamera()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			applyResponsiveLayout()
		end)
	end
end
hookCamera()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	task.wait()
	hookCamera()
	applyResponsiveLayout()
end)

print("[BitKaisenMissionSituationUI] Loaded muted clean popup UI.")

