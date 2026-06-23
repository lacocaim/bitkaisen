-- LocalScript: BitKaisenAssetsUI
-- Location: StarterPlayerScripts
-- Update 4.1: Added dojo limit feedback labels and curse rebirth help text.
-- Fixed curly-quote parse error in dojoSummaryBlock moodCard labels.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function formatMoneyAmount(value)
	value = math.floor((tonumber(value) or 0) * 100 + 0.5) / 100
	if value % 1 == 0 then
		return tostring(math.floor(value))
	end
	return string.format("%.2f", value)
end

local getAssets = ReplicatedStorage:WaitForChild("GetAssets")
local assetAction = ReplicatedStorage:WaitForChild("AssetAction")

local bitKaisenGui = playerGui:WaitForChild("BitKaisenGui")
local mainPanel = bitKaisenGui:WaitForChild("MainPanel")
local navPanel = mainPanel:WaitForChild("NavPanel")
local assetsButton = navPanel:FindFirstChild("ASSETSButton") or bitKaisenGui:FindFirstChild("ASSETSButton", true) or playerGui:FindFirstChild("ASSETSButton", true)
local assetsLookupStarted = os.clock()
while not assetsButton and os.clock() - assetsLookupStarted < 10 do
	task.wait(0.1)
	assetsButton = navPanel:FindFirstChild("ASSETSButton") or bitKaisenGui:FindFirstChild("ASSETSButton", true) or playerGui:FindFirstChild("ASSETSButton", true)
end
if not assetsButton then
	warn("[BitKaisenAssetsUI] ASSETSButton could not be found; assets menu will stay closed until the nav loads.")
end
local missionsButton = navPanel:FindFirstChild("MISSIONSButton")
local activitiesButton = navPanel:FindFirstChild("ACTIVITIESButton")
local relationshipsButton = navPanel:FindFirstChild("RELATIONSHIPSButton")

local existingOverlay = bitKaisenGui:FindFirstChild("AssetsOverlay")
if existingOverlay then existingOverlay:Destroy() end

----------------------------------------------------------------
-- THEME
----------------------------------------------------------------
local COLORS = {
	Window      = Color3.fromRGB(15, 15, 22),
	Card        = Color3.fromRGB(22, 22, 30),
	CardDark    = Color3.fromRGB(16, 16, 23),
	CardHover   = Color3.fromRGB(28, 28, 38),
	Stroke      = Color3.fromRGB(48, 48, 64),
	StrokeSoft  = Color3.fromRGB(38, 38, 52),
	Track       = Color3.fromRGB(28, 28, 38),
	RedStroke   = Color3.fromRGB(95, 30, 42),
	GoldStroke  = Color3.fromRGB(120, 95, 35),
	Text        = Color3.fromRGB(235, 235, 245),
	SubText     = Color3.fromRGB(165, 165, 185),
	Muted       = Color3.fromRGB(110, 110, 130),
	Green       = Color3.fromRGB(120, 240, 160),
	Blue        = Color3.fromRGB(120, 190, 255),
	Purple      = Color3.fromRGB(180, 130, 255),
	Gold        = Color3.fromRGB(255, 200, 90),
	Red         = Color3.fromRGB(210, 70, 80),
	Button      = Color3.fromRGB(31, 31, 42),
	ButtonHover = Color3.fromRGB(44, 44, 58),
	Accent      = Color3.fromRGB(100, 30, 30),
	Modal       = Color3.fromRGB(18, 18, 26),
}

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------
local busy = false
local isOpen = false
local currentTab = "Owned"
local currentData = nil
local dojoSubPage = "Overview"
local preserveScrollOnNextRefresh = false
local resetScrollOnNextRefresh = false

local openCandidateId = nil
local recruitConfirmId = nil
local questionCandidateId = nil
local questionAnswerByCandidateId = {}

local refreshAssets
local buildJoinedDojoMenu

----------------------------------------------------------------
-- UTIL
----------------------------------------------------------------
local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

local function addPadding(parent, top, right, bottom, left)
	local p = Instance.new("UIPadding")
	p.PaddingTop    = UDim.new(0, top    or 0)
	p.PaddingRight  = UDim.new(0, right  or 0)
	p.PaddingBottom = UDim.new(0, bottom or 0)
	p.PaddingLeft   = UDim.new(0, left   or 0)
	p.Parent = parent
	return p
end

local function setButtonTween(button, hoverColor)
	local baseColor = button.BackgroundColor3
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = hoverColor}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = baseColor}):Play()
	end)
end

local function rarityColor(rarity)
	if rarity == "Common"    then return Color3.fromRGB(180, 180, 190) end
	if rarity == "Uncommon"  then return Color3.fromRGB(120, 240, 160) end
	if rarity == "Rare"      then return Color3.fromRGB(120, 190, 255) end
	if rarity == "Epic"      then return Color3.fromRGB(190, 130, 255) end
	if rarity == "Legendary" then return Color3.fromRGB(255, 200, 90)  end
	if rarity == "SpecialGrade" or rarity == "Mythic" then return Color3.fromRGB(255, 90, 125) end
	return Color3.fromRGB(180, 180, 190)
end

local function rarityDisplayName(rarity)
	local value = tostring(rarity or "Common")
	local map = {
		Common = "Grade 4",
		Uncommon = "Grade 3",
		Rare = "Grade 2",
		Epic = "Semi-Grade 1",
		Legendary = "Grade 1",
		Mythic = "Special Grade",
		SpecialGrade = "Special Grade",
	}
	return map[value] or value
end

local function lighten(c, amount)
	return Color3.fromRGB(
		math.clamp(c.R * 255 + amount, 0, 255),
		math.clamp(c.G * 255 + amount, 0, 255),
		math.clamp(c.B * 255 + amount, 0, 255)
	)
end

local function recruitFitColor(tier)
	if tier == "Elite" then return COLORS.Gold end
	if tier == "Strong" then return COLORS.Green end
	if tier == "Risky" then return COLORS.Red end
	return COLORS.Blue
end

local function sanitizeActionText(text)
	text = tostring(text or "")
	text = text:gsub("|", "")
	text = text:gsub("<", ""):gsub(">", "")
	text = text:gsub("^%s+", ""):gsub("%s+$", "")
	return text
end

-- Update 4.1: builds limit-aware description text for dojo action cards.
-- Fully backward compatible: if the server does not yet send limit fields, falls back to baseDesc.
local function buildDojoLimitText(baseDesc, usesLeft, limit, actionLabel)
	if usesLeft == nil or limit == nil then
		return baseDesc
	end
	usesLeft = tonumber(usesLeft) or 0
	limit    = tonumber(limit)    or 0
	if usesLeft <= 0 then
		return baseDesc .. "\n<b>" .. actionLabel .. ": 0/" .. tostring(limit) .. " uses left this 6 months. Age up 6 months to use again.</b>"
	end
	return baseDesc .. "\n" .. actionLabel .. ": " .. tostring(usesLeft) .. "/" .. tostring(limit) .. " uses left this 6 months."
end

----------------------------------------------------------------
-- ROOT WINDOW
----------------------------------------------------------------
local overlay = Instance.new("Frame")
overlay.Name = "AssetsOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.Visible = false
overlay.ZIndex = 350
overlay.Parent = bitKaisenGui

local window = Instance.new("Frame")
window.Name = "AssetsWindow"
window.Size = UDim2.new(0.60, 0, 0.80, 0)
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.new(0.5, 0, 0.55, 0)
window.BackgroundColor3 = COLORS.Window
window.BackgroundTransparency = 1
window.BorderSizePixel = 0
window.Visible = false
window.ZIndex = 351
window.Parent = overlay
addCorner(window, 12)
addStroke(window, COLORS.RedStroke, 1)

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -100, 0, 38)
title.Position = UDim2.new(0, 28, 0, 16)
title.BackgroundTransparency = 1
title.TextColor3 = COLORS.Text
title.TextSize = 24
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "ASSETS"
title.ZIndex = 352
title.Parent = window

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.new(1, -100, 0, 18)
subtitle.Position = UDim2.new(0, 29, 0, 52)
subtitle.BackgroundTransparency = 1
subtitle.TextColor3 = COLORS.SubText
subtitle.TextSize = 12
subtitle.Font = Enum.Font.GothamBold
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Text = "Buy assets, use items, manage your dojo, and grow your clan."
subtitle.ZIndex = 352
subtitle.Parent = window

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -54, 0, 16)
closeButton.BackgroundColor3 = COLORS.Button
closeButton.BorderSizePixel = 0
closeButton.TextColor3 = COLORS.Red
closeButton.TextSize = 20
closeButton.Font = Enum.Font.GothamBlack
closeButton.Text = "X"
closeButton.AutoButtonColor = false
closeButton.ZIndex = 353
closeButton.Parent = window
addCorner(closeButton, 8)
addStroke(closeButton, Color3.fromRGB(55, 55, 72), 1)
setButtonTween(closeButton, COLORS.ButtonHover)

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Size = UDim2.new(0.42, 0, 0, 22)
moneyLabel.Position = UDim2.new(0, 29, 0, 76)
moneyLabel.BackgroundTransparency = 1
moneyLabel.TextColor3 = COLORS.Green
moneyLabel.TextSize = 13
moneyLabel.Font = Enum.Font.GothamBlack
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.Text = "Money: $0"
moneyLabel.ZIndex = 352
moneyLabel.Parent = window

local clanLabel = Instance.new("TextLabel")
clanLabel.Size = UDim2.new(0.46, 0, 0, 22)
clanLabel.Position = UDim2.new(0.49, 0, 0, 76)
clanLabel.BackgroundTransparency = 1
clanLabel.TextColor3 = COLORS.Gold
clanLabel.TextSize = 13
clanLabel.Font = Enum.Font.GothamBlack
clanLabel.TextXAlignment = Enum.TextXAlignment.Right
clanLabel.Text = ""
clanLabel.ZIndex = 352
clanLabel.Parent = window

local actionStatusLabel = Instance.new("TextLabel")
actionStatusLabel.Name = "ActionStatusLabel"
actionStatusLabel.Size = UDim2.new(1, -56, 0, 18)
actionStatusLabel.Position = UDim2.new(0, 28, 0, 96)
actionStatusLabel.BackgroundTransparency = 1
actionStatusLabel.TextColor3 = COLORS.Muted
actionStatusLabel.TextSize = 11
actionStatusLabel.Font = Enum.Font.GothamBold
actionStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
actionStatusLabel.Text = ""
actionStatusLabel.ZIndex = 352
actionStatusLabel.Parent = window

local function setActionStatus(text, color)
	actionStatusLabel.Text = text or ""
	actionStatusLabel.TextColor3 = color or COLORS.Muted
end

----------------------------------------------------------------
-- TABS
----------------------------------------------------------------
local tabHolder = Instance.new("Frame")
tabHolder.Name = "AssetTabs"
tabHolder.Size = UDim2.new(1, -56, 0, 36)
tabHolder.Position = UDim2.new(0, 28, 0, 106)
tabHolder.BackgroundTransparency = 1
tabHolder.ZIndex = 352
tabHolder.Parent = window

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 8)
tabLayout.Parent = tabHolder

local tabs = {}
local function makeTab(name, order)
	local b = Instance.new("TextButton")
	b.Name = name .. "Tab"
	b.Size = UDim2.new(0.333, -6, 1, 0)
	b.BackgroundColor3 = COLORS.Button
	b.BorderSizePixel = 0
	b.TextColor3 = COLORS.SubText
	b.TextSize = 13
	b.Font = Enum.Font.GothamBlack
	b.Text = string.upper(name)
	b.AutoButtonColor = false
	b.LayoutOrder = order
	b.ZIndex = 353
	b.Parent = tabHolder
	addCorner(b, 7)
	addStroke(b, Color3.fromRGB(48, 48, 64), 1)
	setButtonTween(b, COLORS.ButtonHover)
	tabs[name] = b
	return b
end

makeTab("Owned", 1)
makeTab("Shop",  2)
makeTab("Dojo",  3)

local function restoreAssetTabs()
	for _, name in ipairs({ "Owned", "Shop", "Dojo" }) do
		local tabButton = tabs[name]
		if tabButton then
			tabButton.Parent = tabHolder
			tabButton.Visible = true
			tabButton:SetAttribute("BKTopBarDuplicateHidden", nil)
			tabButton.Size = UDim2.new(0.333, -6, 1, 0)
			tabButton.Text = string.upper(name)
		end
	end
end

restoreAssetTabs()

----------------------------------------------------------------
-- SCROLL AREA
----------------------------------------------------------------
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "AssetsScroll"
scroll.Size = UDim2.new(1, -56, 1, -160)
scroll.Position = UDim2.new(0, 28, 0, 152)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = Color3.fromRGB(85, 85, 110)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.ScrollingEnabled = true
scroll.Active = true
scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
scroll.ZIndex = 352
scroll.Parent = window

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 10)
layout.Parent = scroll

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
end)

local function applyAssetsResponsiveLayout()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local isMobile = viewport.X < 900

	if isMobile then
		window.Size = UDim2.new(0.90, 0, 0.78, 0)
		window.Position = UDim2.new(0.5, 0, 0.49, 0)
		title.TextSize = 18
		subtitle.TextSize = 9
		subtitle.TextWrapped = true
		closeButton.Size = UDim2.new(0, 34, 0, 34)
		closeButton.Position = UDim2.new(1, -42, 0, 10)
		closeButton.TextSize = 16
		tabHolder.Size = UDim2.new(1, -28, 0, 32)
		tabHolder.Position = UDim2.new(0, 14, 0, 100)
		scroll.Size = UDim2.new(1, -28, 1, -146)
		scroll.Position = UDim2.new(0, 14, 0, 138)
		moneyLabel.Position = UDim2.new(0, 16, 0, 70)
		moneyLabel.TextSize = 11
		clanLabel.Position = UDim2.new(0.43, 0, 0, 70)
		clanLabel.TextSize = 10
		actionStatusLabel.Size = UDim2.new(1, -28, 0, 16)
		actionStatusLabel.Position = UDim2.new(0, 14, 0, 88)
		actionStatusLabel.TextSize = 9
		for _, tabButton in pairs(tabs) do
			tabButton.TextSize = 10
		end
	else
		window.Size = UDim2.new(0.60, 0, 0.80, 0)
		window.Position = UDim2.new(0.5, 0, 0.55, 0)
		title.TextSize = 24
		subtitle.TextSize = 12
		closeButton.Size = UDim2.new(0, 40, 0, 40)
		closeButton.Position = UDim2.new(1, -54, 0, 16)
		closeButton.TextSize = 20
		tabHolder.Size = UDim2.new(1, -56, 0, 36)
		tabHolder.Position = UDim2.new(0, 28, 0, 106)
		scroll.Size = UDim2.new(1, -56, 1, -160)
		scroll.Position = UDim2.new(0, 28, 0, 152)
		moneyLabel.Position = UDim2.new(0, 29, 0, 76)
		moneyLabel.TextSize = 13
		clanLabel.Position = UDim2.new(0.49, 0, 0, 76)
		clanLabel.TextSize = 13
		actionStatusLabel.Size = UDim2.new(1, -56, 0, 18)
		actionStatusLabel.Position = UDim2.new(0, 28, 0, 96)
		actionStatusLabel.TextSize = 11
		for _, tabButton in pairs(tabs) do
			tabButton.TextSize = 13
		end
	end
end

restoreAssetTabs()
applyAssetsResponsiveLayout()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyAssetsResponsiveLayout)
end

local function clearCards()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

local function setTab(tabName)
	restoreAssetTabs()
	if currentTab ~= tabName then
		resetScrollOnNextRefresh = true
	end
	currentTab = tabName
	for name, b in pairs(tabs) do
		if name == currentTab then
			b.BackgroundColor3 = COLORS.Accent
			b.TextColor3 = COLORS.Text
		else
			b.BackgroundColor3 = COLORS.Button
			b.TextColor3 = COLORS.SubText
		end
	end
end

----------------------------------------------------------------
-- CARD BUILDERS
----------------------------------------------------------------
local function makeEmptyCard(text)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -10, 0, 110)
	card.BackgroundColor3 = COLORS.Card
	card.BorderSizePixel = 0
	card.ZIndex = 354
	card.Parent = scroll
	addCorner(card, 8)
	addStroke(card, COLORS.Stroke, 1)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -40, 1, 0)
	label.Position = UDim2.new(0, 20, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = COLORS.SubText
	label.TextSize = 15
	label.Font = Enum.Font.GothamBold
	label.TextWrapped = true
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Text = text
	label.ZIndex = 355
	label.Parent = card
end

local function makeHeader(text)
	local h = Instance.new("TextLabel")
	h.Size = UDim2.new(1, -10, 0, 24)
	h.BackgroundTransparency = 1
	h.TextColor3 = COLORS.SubText
	h.TextSize = 13
	h.Font = Enum.Font.GothamBlack
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.Text = string.upper(text)
	h.ZIndex = 354
	h.Parent = scroll
	return h
end

local function makeCard(height)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -10, 0, height or 160)
	card.BackgroundColor3 = COLORS.Card
	card.BorderSizePixel = 0
	card.ZIndex = 354
	card.Parent = scroll
	addCorner(card, 10)
	addStroke(card, COLORS.Stroke, 1)
	return card
end

local function makeLabel(parent, text, size, color, position, dimensions, bold)
	local l = Instance.new("TextLabel")
	l.Size = dimensions or UDim2.new(1, -40, 0, 24)
	l.Position = position or UDim2.new(0, 20, 0, 12)
	l.BackgroundTransparency = 1
	l.TextColor3 = color or COLORS.Text
	l.TextSize = size or 14
	l.Font = bold and Enum.Font.GothamBlack or Enum.Font.GothamMedium
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Top
	l.TextWrapped = true
	l.RichText = true
	l.Text = text or ""
	l.ZIndex = 355
	l.Parent = parent
	return l
end

local function makeButton(parent, text, color, x, y, width, height, callback)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, width or 122, 0, height or 32)
	b.Position = UDim2.new(0, x, 0, y)
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.TextColor3 = COLORS.Text
	b.TextSize = 12
	b.Font = Enum.Font.GothamBlack
	b.Text = text
	b.AutoButtonColor = false
	b.ZIndex = 356
	b.Parent = parent
	addCorner(b, 7)
	addStroke(b, Color3.fromRGB(60, 60, 75), 1)
	setButtonTween(b, lighten(color, 20))
	if callback then
		b.MouseButton1Click:Connect(callback)
	end
	return b
end

----------------------------------------------------------------
-- SERVER ACTION FIRER
----------------------------------------------------------------
local function fireAssetAction(actionId, assetId)
	if busy then
		setActionStatus("Please wait...", COLORS.Gold)
		return
	end

	busy = true
	preserveScrollOnNextRefresh = true
	setActionStatus("Processing action...", COLORS.Gold)
	assetAction:FireServer(actionId, assetId)

	task.delay(0.35, function()
		busy = false
		if isOpen then
			setActionStatus("Updated.", COLORS.Green)
			task.delay(1.25, function()
				if isOpen and actionStatusLabel.Text == "Updated." then
					setActionStatus("")
				end
			end)
		end
	end)
end

----------------------------------------------------------------
-- EXAMINE MODAL
----------------------------------------------------------------
local examineDim = Instance.new("Frame")
examineDim.Name = "ExamineDim"
examineDim.Size = UDim2.new(1, 0, 1, 0)
examineDim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
examineDim.BackgroundTransparency = 0.5
examineDim.Visible = false
examineDim.ZIndex = 380
examineDim.Parent = overlay

local examineCard = Instance.new("Frame")
examineCard.Name = "ExamineCard"
examineCard.Size = UDim2.new(0, 460, 0, 420)
examineCard.AnchorPoint = Vector2.new(0.5, 0.5)
examineCard.Position = UDim2.new(0.5, 0, 0.5, 0)
examineCard.BackgroundColor3 = COLORS.Modal
examineCard.BorderSizePixel = 0
examineCard.ZIndex = 381
examineCard.Parent = examineDim
addCorner(examineCard, 12)
addStroke(examineCard, COLORS.GoldStroke, 1)

local examineClose = Instance.new("TextButton")
examineClose.Size = UDim2.new(0, 32, 0, 32)
examineClose.Position = UDim2.new(1, -42, 0, 10)
examineClose.BackgroundColor3 = COLORS.Button
examineClose.BorderSizePixel = 0
examineClose.TextColor3 = COLORS.Red
examineClose.TextSize = 16
examineClose.Font = Enum.Font.GothamBlack
examineClose.Text = "X"
examineClose.AutoButtonColor = false
examineClose.ZIndex = 383
examineClose.Parent = examineCard
addCorner(examineClose, 6)
addStroke(examineClose, COLORS.Stroke, 1)
setButtonTween(examineClose, COLORS.ButtonHover)

local examineName = Instance.new("TextLabel")
examineName.Size = UDim2.new(1, -90, 0, 30)
examineName.Position = UDim2.new(0, 20, 0, 14)
examineName.BackgroundTransparency = 1
examineName.TextColor3 = COLORS.Gold
examineName.TextSize = 22
examineName.Font = Enum.Font.GothamBlack
examineName.TextXAlignment = Enum.TextXAlignment.Left
examineName.Text = ""
examineName.ZIndex = 382
examineName.Parent = examineCard

local examineSub = Instance.new("TextLabel")
examineSub.Size = UDim2.new(1, -40, 0, 18)
examineSub.Position = UDim2.new(0, 20, 0, 46)
examineSub.BackgroundTransparency = 1
examineSub.TextColor3 = COLORS.SubText
examineSub.TextSize = 13
examineSub.Font = Enum.Font.GothamBold
examineSub.TextXAlignment = Enum.TextXAlignment.Left
examineSub.Text = ""
examineSub.ZIndex = 382
examineSub.Parent = examineCard

local examineDivider = Instance.new("Frame")
examineDivider.Size = UDim2.new(1, -40, 0, 1)
examineDivider.Position = UDim2.new(0, 20, 0, 74)
examineDivider.BackgroundColor3 = COLORS.Stroke
examineDivider.BorderSizePixel = 0
examineDivider.ZIndex = 382
examineDivider.Parent = examineCard

local examineBody = Instance.new("TextLabel")
examineBody.Size = UDim2.new(1, -40, 0, 200)
examineBody.Position = UDim2.new(0, 20, 0, 86)
examineBody.BackgroundTransparency = 1
examineBody.TextColor3 = COLORS.Text
examineBody.TextSize = 13
examineBody.Font = Enum.Font.GothamMedium
examineBody.TextXAlignment = Enum.TextXAlignment.Left
examineBody.TextYAlignment = Enum.TextYAlignment.Top
examineBody.TextWrapped = true
examineBody.RichText = true
examineBody.Text = ""
examineBody.ZIndex = 382
examineBody.Parent = examineCard

local examineBgHeader = Instance.new("TextLabel")
examineBgHeader.Size = UDim2.new(1, -40, 0, 18)
examineBgHeader.Position = UDim2.new(0, 20, 0, 294)
examineBgHeader.BackgroundTransparency = 1
examineBgHeader.TextColor3 = COLORS.Gold
examineBgHeader.TextSize = 12
examineBgHeader.Font = Enum.Font.GothamBlack
examineBgHeader.TextXAlignment = Enum.TextXAlignment.Left
examineBgHeader.Text = "BACKGROUND"
examineBgHeader.ZIndex = 382
examineBgHeader.Parent = examineCard

local examineBg = Instance.new("TextLabel")
examineBg.Size = UDim2.new(1, -40, 0, 70)
examineBg.Position = UDim2.new(0, 20, 0, 316)
examineBg.BackgroundTransparency = 1
examineBg.TextColor3 = COLORS.SubText
examineBg.TextSize = 12
examineBg.Font = Enum.Font.GothamMedium
examineBg.TextXAlignment = Enum.TextXAlignment.Left
examineBg.TextYAlignment = Enum.TextYAlignment.Top
examineBg.TextWrapped = true
examineBg.Text = ""
examineBg.ZIndex = 382
examineBg.Parent = examineCard

local function hideExamine()
	examineDim.Visible = false
end

examineClose.MouseButton1Click:Connect(hideExamine)
examineDim.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local pos = input.Position
		local absPos = examineCard.AbsolutePosition
		local absSize = examineCard.AbsoluteSize
		local insideX = pos.X >= absPos.X and pos.X <= absPos.X + absSize.X
		local insideY = pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y
		if not (insideX and insideY) then
			hideExamine()
		end
	end
end)

local function applyExamineResponsiveLayout()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local isMobile = viewport.X < 900
	local isSmallMobile = viewport.X < 520

	if isMobile then
		examineCard.Size = UDim2.new(0.88, 0, 0.68, 0)
		examineCard.Position = UDim2.new(0.5, 0, 0.48, 0)
		examineClose.Size = UDim2.new(0, 30, 0, 30)
		examineClose.Position = UDim2.new(1, -38, 0, 8)
		examineClose.TextSize = 14
		examineName.Size = UDim2.new(1, -64, 0, 24)
		examineName.Position = UDim2.new(0, 14, 0, 12)
		examineName.TextSize = isSmallMobile and 16 or 18
		examineSub.Size = UDim2.new(1, -28, 0, 18)
		examineSub.Position = UDim2.new(0, 14, 0, 38)
		examineSub.TextSize = 10
		examineDivider.Size = UDim2.new(1, -28, 0, 1)
		examineDivider.Position = UDim2.new(0, 14, 0, 62)
		examineBody.Size = UDim2.new(1, -28, 0, isSmallMobile and 118 or 138)
		examineBody.Position = UDim2.new(0, 14, 0, 74)
		examineBody.TextSize = isSmallMobile and 10 or 11
		examineBgHeader.Size = UDim2.new(1, -28, 0, 16)
		examineBgHeader.Position = UDim2.new(0, 14, 0, isSmallMobile and 198 or 220)
		examineBgHeader.TextSize = 10
		examineBg.Size = UDim2.new(1, -28, 1, isSmallMobile and -220 or -242)
		examineBg.Position = UDim2.new(0, 14, 0, isSmallMobile and 216 or 238)
		examineBg.TextSize = isSmallMobile and 10 or 11
	else
		examineCard.Size = UDim2.new(0, 460, 0, 420)
		examineCard.Position = UDim2.new(0.5, 0, 0.5, 0)
		examineClose.Size = UDim2.new(0, 32, 0, 32)
		examineClose.Position = UDim2.new(1, -42, 0, 10)
		examineClose.TextSize = 16
		examineName.Size = UDim2.new(1, -90, 0, 30)
		examineName.Position = UDim2.new(0, 20, 0, 14)
		examineName.TextSize = 22
		examineSub.Size = UDim2.new(1, -40, 0, 18)
		examineSub.Position = UDim2.new(0, 20, 0, 46)
		examineSub.TextSize = 13
		examineDivider.Size = UDim2.new(1, -40, 0, 1)
		examineDivider.Position = UDim2.new(0, 20, 0, 74)
		examineBody.Size = UDim2.new(1, -40, 0, 200)
		examineBody.Position = UDim2.new(0, 20, 0, 86)
		examineBody.TextSize = 13
		examineBgHeader.Size = UDim2.new(1, -40, 0, 18)
		examineBgHeader.Position = UDim2.new(0, 20, 0, 294)
		examineBgHeader.TextSize = 12
		examineBg.Size = UDim2.new(1, -40, 0, 70)
		examineBg.Position = UDim2.new(0, 20, 0, 316)
		examineBg.TextSize = 12
	end
end

applyExamineResponsiveLayout()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyExamineResponsiveLayout)
end

local function showExamine(candidate)
	local name      = tostring(candidate.Name or "Unknown")
	local grade     = tostring(candidate.Grade or "Non-Sorcerer")
	local age       = tostring(candidate.Age or 0)
	local gender    = tostring(candidate.Gender or "Unknown")
	local origin    = tostring(candidate.OriginLocation or "Unknown")
	local school    = tostring(candidate.PreviousSchool or "Unknown")
	local father    = tostring(candidate.FatherStatus or "Unknown")
	local mother    = tostring(candidate.MotherStatus or "Unknown")
	local technique = tostring(candidate.CursedTechnique or "None")
	local ce        = tostring(candidate.CursedEnergy or 0)
	local potential = tostring(candidate.DojoPotential or "Unknown")
	local background = tostring(candidate.Background or "No detailed profile available.")

	applyExamineResponsiveLayout()
	examineName.Text = name
	examineSub.Text  = grade .. "  •  Age " .. age .. "  •  " .. gender
	examineBody.Text =
		"<b>Hometown:</b> " .. origin ..
		"\n<b>Previous School:</b> " .. school ..
		"\n<b>Father:</b> " .. father .. "    <b>Mother:</b> " .. mother ..
		"\n<b>Cursed Technique:</b> " .. technique ..
		"\n<b>Cursed Energy:</b> " .. ce ..
		"\n<b>Potential:</b> " .. potential
	examineBg.Text = background
	examineDim.Visible = true
end

----------------------------------------------------------------
-- DOJO HELPERS
----------------------------------------------------------------
local function formatPercent(value)
	return tostring(math.clamp(math.floor((tonumber(value) or 0) + 0.5), 0, 100)) .. "%"
end

local function makeStatPill(parent, labelText, valueText, color, x, y, width)
	local pill = Instance.new("Frame")
	pill.Size = UDim2.new(0, width or 150, 0, 46)
	pill.Position = UDim2.new(0, x, 0, y)
	pill.BackgroundColor3 = COLORS.CardDark
	pill.BorderSizePixel = 0
	pill.ZIndex = 356
	pill.Parent = parent
	addCorner(pill, 10)
	addStroke(pill, COLORS.StrokeSoft, 1)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -16, 0, 16)
	lbl.Position = UDim2.new(0, 8, 0, 7)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = COLORS.Muted
	lbl.TextSize = 10
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextWrapped = true
	lbl.Text = string.upper(tostring(labelText or "STAT"))
	lbl.ZIndex = 357
	lbl.Parent = pill

	local val = Instance.new("TextLabel")
	val.Size = UDim2.new(1, -16, 0, 20)
	val.Position = UDim2.new(0, 8, 0, 22)
	val.BackgroundTransparency = 1
	val.TextColor3 = color or COLORS.Text
	val.TextSize = 15
	val.Font = Enum.Font.GothamBlack
	val.TextXAlignment = Enum.TextXAlignment.Left
	val.TextWrapped = true
	val.Text = tostring(valueText or "0")
	val.ZIndex = 357
	val.Parent = pill

	return pill
end

local function makeRightButton(parent, text, color, y, callback)
	local button = makeButton(parent, text, color, 0, y, 142, 34, callback)
	button.Position = UDim2.new(1, -162, 0, y)
	return button
end

local function getDojoRankInfo(data)
	local rep = tonumber(data.ClanReputation) or 0
	if rep < 25  then return "Minor Dojo",       rep,       25  end
	if rep < 75  then return "Rising Clan",       rep - 25,  50  end
	if rep < 150 then return "Recognized House",  rep - 75,  75  end
	if rep < 300 then return "Great Clan",        rep - 150, 150 end
	return "Legendary Clan", 300, 300
end

local function getDojoMoodText(data)
	local condition = tonumber(data.DojoCondition) or 100
	local rep       = tonumber(data.ClanReputation) or 0
	local students  = tonumber(data.ClanStudentCount) or 0
	if condition < 35 then return "The training hall feels neglected. Students notice every cracked board and cold silence." end
	if condition < 70 then return "The dojo is functional, but wear is starting to show around the training floor." end
	if students <= 0  then return "The hall is clean, quiet, and waiting for the first students to carry your name." end
	if rep < 25       then return "The dojo is still unknown, but the first students are beginning to respect your structure." end
	if rep < 75       then return "Word is spreading. Prospects are starting to recognize your clan banner." end
	return "The dojo feels alive. Students train harder because your clan name actually means something now."
end

local function getProfileInitials(profile)
	local name   = tostring(profile.Name or "??")
	local first  = name:match("(%S+)") or "?"
	local second = name:match("%S+%s+(%S+)") or ""
	local a = string.sub(first, 1, 1)
	local b = second ~= "" and string.sub(second, 1, 1) or ""
	return string.upper(a .. b)
end

local function getProfileTraits(profile)
	local traits      = {}
	local potential   = tostring(profile.DojoPotential or "Unknown")
	local technique   = tostring(profile.CursedTechnique or "None")
	local origin      = tostring(profile.OriginLocation or "")
	local personality = string.lower(tostring(profile.Personality or ""))
	local background  = string.lower(tostring(profile.Background or ""))
	local ce          = tonumber(profile.CursedEnergy) or 0

	if potential == "Rare" or potential == "Hidden" then table.insert(traits, "Hidden Talent")
	elseif potential == "High" then table.insert(traits, "Fast Learner") end
	if technique ~= "None" then table.insert(traits, "Technique User") end
	if ce >= 120 then table.insert(traits, "High CE")
	elseif ce <= 35 then table.insert(traits, "Low Reserve") end
	if not string.find(origin, "Japan") and origin ~= "" and origin ~= "Unknown" then
		table.insert(traits, "Foreign Prospect")
	end
	if string.find(personality, "discipline") or string.find(background, "disciplined") then
		table.insert(traits, "Disciplined")
	elseif string.find(personality, "competitive") or string.find(background, "stubborn") then
		table.insert(traits, "Competitive")
	elseif string.find(personality, "quiet") or string.find(background, "quiet") then
		table.insert(traits, "Quiet")
	elseif string.find(background, "unstable") then
		table.insert(traits, "Unstable CE")
	end
	if #traits <= 0 then table.insert(traits, "Developing") end
	while #traits > 3 do table.remove(traits) end
	return traits
end

local function getProfileSeed(profile)
	local source = tostring((profile and (profile.Id or profile.Name or profile.FirstName)) or "Unknown")
	local total = 0
	for index = 1, #source do
		total += string.byte(source, index) * index
	end
	local age = tonumber(profile and profile.Age) or 0
	local ce  = tonumber(profile and profile.CursedEnergy) or 0
	return total + (age * 17) + (ce * 3)
end

local function pickProfileLine(profile, lines)
	if not lines or #lines <= 0 then return "" end
	local seed  = getProfileSeed(profile)
	local index = (seed % #lines) + 1
	return lines[index]
end

local function getStudentFlavorLine(student)
	local grade     = tostring(student.Grade or "Non-Sorcerer")
	local potential = tostring(student.DojoPotential or "Unknown")
	local technique = tostring(student.CursedTechnique or "None")
	local ce        = tonumber(student.CursedEnergy) or 0
	local origin    = tostring(student.OriginLocation or "Unknown")

	local lines = {
		"Shows up early, studies the room first, then trains without needing attention.",
		"Learns faster when sessions are structured and expectations are clear.",
		"Responds well to pressure, but sloppy coaching will make them plateau.",
		"Has decent instincts, but still needs a real mentor to sharpen them.",
		"Works best when paired with stronger students who can force adaptation.",
		"Carries themself like they have something to prove every session.",
		"Listens more than they speak, which makes their progress easy to miss.",
		"Needs consistency. Random training will waste most of their potential.",
	}
	if potential == "Hidden" or potential == "Rare" then
		table.insert(lines, "There is something buried under the surface. Do not train them like a normal recruit.")
	elseif potential == "High" then
		table.insert(lines, "They pick up corrections quickly. A focused schedule could make them a centerpiece student.")
	end
	if technique ~= "None" then
		table.insert(lines, "Their technique needs controlled repetition before it becomes reliable in real missions.")
	end
	if ce >= 120 then
		table.insert(lines, "Their cursed energy reserve is high enough to build the dojo's reputation around them.")
	elseif ce <= 35 then
		table.insert(lines, "Their reserve is weak right now, so fundamentals matter more than flashy drills.")
	end
	if not string.find(origin, "Japan") and origin ~= "Unknown" then
		table.insert(lines, "They are still adapting to Japan's jujutsu culture, so loyalty has to be earned slowly.")
	end
	if grade == "Grade 2" or grade == "Semi-Grade 2" then
		table.insert(lines, "Already capable enough to represent the clan, but bad habits will get expensive later.")
	elseif grade == "Non-Sorcerer" or grade == "Grade 4" then
		table.insert(lines, "Still rough. The upside is that your dojo can shape their habits from the ground up.")
	end
	return pickProfileLine(student, lines)
end

local function getStudentPlanLine(student)
	local focus     = currentData and tostring(currentData.DojoFocus or "Balanced") or "Balanced"
	local potential = tostring(student.DojoPotential or "Unknown")
	local technique = tostring(student.CursedTechnique or "None")
	local ce        = tonumber(student.CursedEnergy) or 0

	if focus == "Combat"     then return "Best next step: sparring rounds, curse-pressure drills, and controlled fatigue training." end
	if focus == "Discipline" then return "Best next step: routine, rules, and repeated basics until their floor gets higher." end
	if focus == "Theory" then
		if technique ~= "None" then return "Best next step: technique theory, timing drills, and cursed energy control." end
		return "Best next step: cursed energy theory before trying to force a technique out of nothing."
	end
	if focus == "Loyalty" then return "Best next step: personal mentorship, trust-building, and clan identity work." end
	if potential == "Hidden" or potential == "Rare" then
		return "Best next step: balanced training until their actual specialty becomes obvious."
	end
	if ce < 40 then return "Best next step: cursed energy fundamentals before mission pressure." end
	return "Best next step: balanced sessions with one hard sparring day and one theory day."
end

local function getCandidateRead(candidate)
	local potential = tostring(candidate.DojoPotential or "Unknown")
	local technique = tostring(candidate.CursedTechnique or "None")
	local school    = tostring(candidate.PreviousSchool or "Unknown")
	local ce        = tonumber(candidate.CursedEnergy) or 0
	local origin    = tostring(candidate.OriginLocation or "Unknown")

	local lines = {
		"Recruit read: stable enough to train, but you need to see how they react under structure.",
		"Recruit read: good body language, but they are clearly measuring whether your clan is worth trusting.",
		"Recruit read: not the loudest candidate, but there is useful discipline under the surface.",
		"Recruit read: could become reliable if the dojo gives them a clear role early.",
		"Recruit read: has the attitude of someone who will either grow fast or clash with weak leadership.",
		"Recruit read: they need a place that turns pressure into routine, not chaos.",
	}
	if potential == "Hidden" or potential == "Rare" then
		table.insert(lines, "Recruit read: risky pick, but their ceiling is higher than the file makes it look.")
	elseif potential == "High" then
		table.insert(lines, "Recruit read: strong candidate. They could become one of the dojo's early pillars.")
	end
	if technique ~= "None" then
		table.insert(lines, "Recruit read: already has a technique, so your dojo can focus on control instead of awakening.")
	end
	if ce >= 100 then
		table.insert(lines, "Recruit read: strong reserve. Other students will notice them immediately.")
	elseif ce <= 35 then
		table.insert(lines, "Recruit read: weak reserve, but low reserves sometimes hide better fundamentals.")
	end
	if school == "No Formal Jujutsu School" then
		table.insert(lines, "Recruit read: unpolished. That can be ugly, but it also means fewer bad habits to undo.")
	elseif string.find(school, "Kyoto") then
		table.insert(lines, "Recruit read: Kyoto training shows. Expect discipline, pride, and possible stubbornness.")
	elseif string.find(school, "Tokyo") then
		table.insert(lines, "Recruit read: Tokyo experience gives them confidence, but they may question your methods first.")
	end
	if not string.find(origin, "Japan") and origin ~= "Unknown" then
		table.insert(lines, "Recruit read: foreign prospect. Their loyalty will depend on whether the clan makes space for them.")
	end
	return pickProfileLine(candidate, lines)
end

local function getCandidateQuestionAnswer(candidate, questionKey)
	local answers   = candidate.QuestionAnswers or {}
	if questionKey == "WhyJoin"  and answers.WhyJoin  then return answers.WhyJoin  end
	if questionKey == "OldSchool" and answers.OldSchool then return answers.OldSchool end
	if questionKey == "Goal"     and answers.Goal     then return answers.Goal     end

	local school    = tostring(candidate.PreviousSchool or "my old school")
	local potential = tostring(candidate.DojoPotential or "Unknown")
	local technique = tostring(candidate.CursedTechnique or "None")

	if questionKey == "WhyJoin" then
		return pickProfileLine(candidate, {
			"I want a clan that actually teaches instead of collecting names.",
			"I need structure. Wandering between weak mentors is wasting my time.",
			"Your dojo is new, so I might actually have a chance to matter here.",
			"I am looking for a place where results matter more than bloodline politics.",
		})
	elseif questionKey == "OldSchool" then
		return pickProfileLine(candidate, {
			"I came from " .. school .. ", but I need a cleaner path now.",
			"My last school taught me basics. It did not give me a future.",
			"I learned enough to survive, not enough to lead.",
			"I left because nobody there knew what to do with my growth.",
		})
	end

	if technique ~= "None" then
		return "I want to master " .. technique .. " well enough that it becomes my weapon, not my weakness."
	end
	if potential == "Hidden" or potential == "Rare" then
		return "I want to find out what I actually am before someone else decides it for me."
	end
	return pickProfileLine(candidate, {
		"I want to earn a grade that nobody can call a mistake.",
		"I want to become reliable enough to stand in front, not behind.",
		"I want my name attached to something stronger than survival.",
		"I want to prove I can grow without being carried by a famous clan.",
	})
end

local function makeInitialBadge(parent, profile, x, y, color)
	local badge = Instance.new("Frame")
	badge.Size = UDim2.new(0, 52, 0, 52)
	badge.Position = UDim2.new(0, x, 0, y)
	badge.BackgroundColor3 = color or COLORS.Accent
	badge.BorderSizePixel = 0
	badge.ZIndex = 356
	badge.Parent = parent
	addCorner(badge, 16)
	addStroke(badge, COLORS.GoldStroke, 1)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = COLORS.Text
	lbl.TextSize = 18
	lbl.Font = Enum.Font.GothamBlack
	lbl.Text = getProfileInitials(profile)
	lbl.ZIndex = 357
	lbl.Parent = badge
	return badge
end

local function makeTraitPills(parent, traits, x, y)
	for index, trait in ipairs(traits or {}) do
		local pill = Instance.new("TextLabel")
		pill.Size = UDim2.new(0, 112, 0, 22)
		pill.Position = UDim2.new(0, x + ((index - 1) * 120), 0, y)
		pill.BackgroundColor3 = COLORS.CardDark
		pill.BorderSizePixel = 0
		pill.TextColor3 = index == 1 and COLORS.Gold or COLORS.SubText
		pill.TextSize = 10
		pill.Font = Enum.Font.GothamBlack
		pill.Text = string.upper(tostring(trait))
		pill.ZIndex = 356
		pill.Parent = parent
		addCorner(pill, 999)
		addStroke(pill, COLORS.StrokeSoft, 1)
	end
end

local function makeProgressBar(parent, x, y, width, labelText, current, maxValue, color)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, width, 0, 18)
	lbl.Position = UDim2.new(0, x, 0, y)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = COLORS.SubText
	lbl.TextSize = 11
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = string.upper(labelText)
	lbl.ZIndex = 356
	lbl.Parent = parent

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(0, width, 0, 10)
	bg.Position = UDim2.new(0, x, 0, y + 22)
	bg.BackgroundColor3 = COLORS.CardDark
	bg.BorderSizePixel = 0
	bg.ZIndex = 356
	bg.Parent = parent
	addCorner(bg, 999)

	local ratio = 0
	if tonumber(maxValue) and maxValue > 0 then
		ratio = math.clamp((tonumber(current) or 0) / maxValue, 0, 1)
	end

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(ratio, 0, 1, 0)
	fill.BackgroundColor3 = color or COLORS.Gold
	fill.BorderSizePixel = 0
	fill.ZIndex = 357
	fill.Parent = bg
	addCorner(fill, 999)

	local val = Instance.new("TextLabel")
	val.Size = UDim2.new(0, width, 0, 18)
	val.Position = UDim2.new(0, x, 0, y + 36)
	val.BackgroundTransparency = 1
	val.TextColor3 = color or COLORS.Gold
	val.TextSize = 11
	val.Font = Enum.Font.GothamBlack
	val.TextXAlignment = Enum.TextXAlignment.Left
	val.Text = tostring(math.floor(tonumber(current) or 0)) .. " / " .. tostring(math.floor(tonumber(maxValue) or 0))
	val.ZIndex = 356
	val.Parent = parent
end

local function buildDojoActivityFeed(data)
	makeHeader("Recent Clan Activity")

	local card     = makeCard(154)
	addStroke(card, COLORS.StrokeSoft, 1)

	local students = data.DojoStudents or {}
	local rep      = tonumber(data.ClanReputation) or 0
	local focus    = tostring(data.DojoFocus or "Balanced")
	local lines    = {}

	if #students > 0 then
		for index = 1, math.min(#students, 3) do
			local student = students[index]
			local name    = tostring(student.Name or "A student")
			table.insert(lines, name .. ": " .. getStudentFlavorLine(student))
		end
	else
		table.insert(lines, "A recruit from Kyoto asked about your clan's training style.")
		table.insert(lines, "The hall is quiet enough that every footstep echoes off the floorboards.")
	end

	if     focus == "Combat"     then table.insert(lines, "Combat focus is making sessions harsher, but the serious students respect it.")
	elseif focus == "Theory"     then table.insert(lines, "Theory focus has students comparing cursed energy notes after training.")
	elseif focus == "Loyalty"    then table.insert(lines, "Loyalty focus is making the dojo feel more like a real house than a rented hall.")
	elseif focus == "Discipline" then table.insert(lines, "Discipline focus has cleaned up the training floor and the students' habits.")
	else                              table.insert(lines, "Balanced focus keeps the dojo steady while your clan identity forms.")
	end

	if rep >= 75 then
		table.insert(lines, "Other families are starting to treat the " .. tostring(data.PlayerClanName or "clan") .. " like a real house.")
	elseif rep >= 25 then
		table.insert(lines, "Local families have started mentioning the " .. tostring(data.PlayerClanName or "clan") .. ".")
	else
		table.insert(lines, "Clan reputation is still forming. Every recruit and training session matters.")
	end

	while #lines > 4 do table.remove(lines) end

	makeLabel(card,
		"• " .. table.concat(lines, "\n• "),
		12, COLORS.SubText,
		UDim2.new(0, 20, 0, 18), UDim2.new(1, -40, 0, 118), false)
end

local function setDojoPage(page)
	if dojoSubPage ~= page then resetScrollOnNextRefresh = true end
	dojoSubPage = page
	openCandidateId = nil
	recruitConfirmId = nil
	questionCandidateId = nil
	preserveScrollOnNextRefresh = true
	refreshAssets()
end

local function dojoSummaryBlock(data)
	local rankName, rankProgress, rankNeed = getDojoRankInfo(data)
	local camera   = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local isMobile = viewport.X < 900

	local cardHeight = isMobile and 285 or 310
	local card = makeCard(cardHeight)
	card.ClipsDescendants = true
	addStroke(card, COLORS.GoldStroke, 1)

	if isMobile then
		local banner = Instance.new("Frame")
		banner.Size = UDim2.new(1, -24, 0, 82)
		banner.Position = UDim2.new(0, 12, 0, 12)
		banner.BackgroundColor3 = COLORS.CardDark
		banner.BorderSizePixel = 0
		banner.ZIndex = 355
		banner.ClipsDescendants = true
		banner.Parent = card
		addCorner(banner, 12)
		addStroke(banner, COLORS.GoldStroke, 1)

		local clanName = tostring(data.PlayerClanName or "Unnamed Clan")
		makeLabel(banner, clanName, 16, COLORS.Text,
			UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 0, 24), true)
		makeLabel(banner, "Founder: " .. tostring(data.DojoFounderName or data.Name or "Unknown"), 9, COLORS.Gold,
			UDim2.new(0, 12, 0, 34), UDim2.new(1, -24, 0, 16), true)

		local rankBadge = Instance.new("TextLabel")
		rankBadge.Size = UDim2.new(1, -24, 0, 24)
		rankBadge.Position = UDim2.new(0, 12, 0, 54)
		rankBadge.BackgroundColor3 = COLORS.Accent
		rankBadge.BorderSizePixel = 0
		rankBadge.TextColor3 = COLORS.Text
		rankBadge.TextSize = 9
		rankBadge.Font = Enum.Font.GothamBlack
		rankBadge.TextWrapped = true
		rankBadge.Text = string.upper(rankName)
		rankBadge.ZIndex = 356
		rankBadge.Parent = banner
		addCorner(rankBadge, 999)
		addStroke(rankBadge, COLORS.StrokeSoft, 1)

		makeProgressBar(card, 12, 102, math.max(120, math.floor((card.AbsoluteSize.X > 0 and card.AbsoluteSize.X or 250) - 24)), "Clan Reputation", rankProgress, rankNeed, COLORS.Gold)

		local studentsText = tostring(data.ClanStudentCount or 0) .. " / " .. tostring(data.DojoCapacity or 3)
		makeStatPill(card, "Students", studentsText,              COLORS.Blue,   12,  152, 78)
		makeStatPill(card, "Level",    tostring(data.DojoLevel or 1), COLORS.Purple, 96,  152, 62)
		makeStatPill(card, "Cond.",    formatPercent(data.DojoCondition or 100), COLORS.Green, 164, 152, 78)

		local moodCard = Instance.new("Frame")
		moodCard.Size = UDim2.new(1, -24, 0, 70)
		moodCard.Position = UDim2.new(0, 12, 0, 206)
		moodCard.BackgroundColor3 = COLORS.CardDark
		moodCard.BorderSizePixel = 0
		moodCard.ZIndex = 355
		moodCard.ClipsDescendants = true
		moodCard.Parent = card
		addCorner(moodCard, 10)
		addStroke(moodCard, COLORS.StrokeSoft, 1)

		makeLabel(moodCard, "Dojo Atmosphere", 10, COLORS.Gold,
			UDim2.new(0, 10, 0, 7), UDim2.new(1, -20, 0, 14), true)
		-- Fixed: straight ASCII quotes instead of curly Unicode quotes
		makeLabel(moodCard, '"' .. getDojoMoodText(data) .. '"', 9, COLORS.SubText,
			UDim2.new(0, 10, 0, 23), UDim2.new(1, -20, 0, 28), false)
		makeLabel(moodCard, "Focus: " .. tostring(data.DojoFocus or "Balanced") .. "  •  Rerolls: " .. tostring(data.RecruitRerollTokens or 0),
			8, COLORS.Muted,
			UDim2.new(0, 10, 0, 52), UDim2.new(1, -20, 0, 12), false)
		return
	end

	-- Desktop path
	local banner = Instance.new("Frame")
	banner.Size = UDim2.new(1, -40, 0, 74)
	banner.Position = UDim2.new(0, 20, 0, 16)
	banner.BackgroundColor3 = COLORS.CardDark
	banner.BorderSizePixel = 0
	banner.ZIndex = 355
	banner.Parent = card
	addCorner(banner, 14)
	addStroke(banner, COLORS.GoldStroke, 1)

	makeLabel(banner, tostring(data.PlayerClanName or "Unnamed Clan"), 24, COLORS.Text,
		UDim2.new(0, 18, 0, 10), UDim2.new(1, -210, 0, 30), true)
	makeLabel(banner, rankName .. "  •  Founder: " .. tostring(data.DojoFounderName or data.Name or "Unknown"), 12, COLORS.Gold,
		UDim2.new(0, 18, 0, 43), UDim2.new(1, -210, 0, 18), true)

	local rankBadge = Instance.new("TextLabel")
	rankBadge.Size = UDim2.new(0, 170, 0, 34)
	rankBadge.Position = UDim2.new(1, -188, 0, 20)
	rankBadge.BackgroundColor3 = COLORS.Accent
	rankBadge.BorderSizePixel = 0
	rankBadge.TextColor3 = COLORS.Text
	rankBadge.TextSize = 12
	rankBadge.Font = Enum.Font.GothamBlack
	rankBadge.Text = string.upper(rankName)
	rankBadge.ZIndex = 356
	rankBadge.Parent = banner
	addCorner(rankBadge, 999)
	addStroke(rankBadge, COLORS.StrokeSoft, 1)

	makeProgressBar(card, 20, 102, 260, "Clan Reputation", rankProgress, rankNeed, COLORS.Gold)

	local studentsText = tostring(data.ClanStudentCount or 0) .. " / " .. tostring(data.DojoCapacity or 3)
	makeStatPill(card, "Students",  studentsText,                    COLORS.Blue,   300, 100, 120)
	makeStatPill(card, "Level",     tostring(data.DojoLevel or 1),   COLORS.Purple, 430, 100, 90)
	makeStatPill(card, "Condition", formatPercent(data.DojoCondition or 100), COLORS.Green, 530, 100, 115)

	local moodCard = Instance.new("Frame")
	moodCard.Size = UDim2.new(1, -220, 0, 66)
	moodCard.Position = UDim2.new(0, 20, 0, 166)
	moodCard.BackgroundColor3 = COLORS.CardDark
	moodCard.BorderSizePixel = 0
	moodCard.ZIndex = 355
	moodCard.Parent = card
	addCorner(moodCard, 12)
	addStroke(moodCard, COLORS.StrokeSoft, 1)

	makeLabel(moodCard, "Dojo Atmosphere", 12, COLORS.Gold,
		UDim2.new(0, 14, 0, 8), UDim2.new(1, -28, 0, 18), true)
	-- Fixed: straight ASCII quotes instead of curly Unicode quotes
	makeLabel(moodCard, '"' .. getDojoMoodText(data) .. '"', 12, COLORS.SubText,
		UDim2.new(0, 14, 0, 29), UDim2.new(1, -28, 0, 30), false)

	makeLabel(card, "Focus: " .. tostring(data.DojoFocus or "Balanced") .. "  •  Rerolls: " .. tostring(data.RecruitRerollTokens or 0),
		12, COLORS.Muted,
		UDim2.new(0, 20, 0, 246), UDim2.new(1, -220, 0, 18), false)
end

local function buildDojoBackCard(labelText)
	local card = makeCard(70)
	card.BackgroundColor3 = COLORS.CardDark
	for _, c in ipairs(card:GetChildren()) do
		if c:IsA("UIStroke") then c:Destroy() end
	end
	addStroke(card, COLORS.StrokeSoft, 1)
	makeLabel(card, labelText or "Return to the main dojo action board.", 13, COLORS.SubText,
		UDim2.new(0, 20, 0, 20), UDim2.new(1, -190, 0, 28), false)
	makeRightButton(card, "BACK", COLORS.Button, 18, function()
		setDojoPage("Overview")
	end)
end

local function openJoinedDojoPageDirect()
	dojoSubPage = "JoinedDojo"
	openCandidateId = nil
	recruitConfirmId = nil
	questionCandidateId = nil
	resetScrollOnNextRefresh = true
	preserveScrollOnNextRefresh = true
	clearCards()
	buildJoinedDojoMenu(currentData or {})
	task.defer(function()
		task.wait()
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
		scroll.CanvasPosition = Vector2.new(0, 0)
	end)
end

-- Update 4.1 (Item 5): added curse rebirth help text when no dojo is active.
local function buildOutsideDojoCard(data)
	local joinedName = tostring(data.JoinedDojoName or "")
	local pending    = data.DojoApplicationPending == true
	local pathLabel  = tostring(data.RacePathLabel or "Civilian")
	local camera     = workspace.CurrentCamera
	local viewport   = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local isMobile   = viewport.X < 900
	local cardHeight = joinedName ~= "" and (isMobile and 188 or 154) or (isMobile and 214 or 146)

	local card = makeCard(cardHeight)
	addStroke(card, joinedName ~= "" and COLORS.GoldStroke or COLORS.StrokeSoft, joinedName ~= "" and 2 or 1)

	if joinedName ~= "" then
		makeLabel(card, "Joined Dojo", 17, COLORS.Gold,
			UDim2.new(0, 20, 0, 16), isMobile and UDim2.new(1, -40, 0, 24) or UDim2.new(1, -190, 0, 24), true)
		makeLabel(card,
			"You train at <b>" .. joinedName .. "</b>. Sensei: <b>" .. tostring(data.JoinedDojoSenseiName or "Unknown") .. "</b> - " .. tostring(data.JoinedDojoSenseiGrade or "Grade 1") .. ".",
			12, COLORS.SubText,
			UDim2.new(0, 20, 0, 46), isMobile and UDim2.new(1, -40, 0, 58) or UDim2.new(1, -190, 0, 58), false)
		makeLabel(card, "Click OPEN to manage training, assignments, advice, or leaving this dojo.", 11, COLORS.Muted,
			UDim2.new(0, 20, 0, 108), isMobile and UDim2.new(1, -40, 0, 24) or UDim2.new(1, -190, 0, 24), false)
		local openY = isMobile and 140 or 56
		if isMobile then
			makeButton(card, "OPEN", COLORS.Gold, 20, openY, 142, 34, function()
				openJoinedDojoPageDirect()
			end)
		else
			makeRightButton(card, "OPEN", COLORS.Gold, openY, function()
				openJoinedDojoPageDirect()
			end)
		end
	elseif pending then
		local appName = tostring(data.DojoApplicationName or (data.DojoApplication and data.DojoApplication.Name) or "a dojo")
		makeLabel(card, "Application Pending", 17, COLORS.Text,
			UDim2.new(0, 20, 0, 16), isMobile and UDim2.new(1, -40, 0, 24) or UDim2.new(1, -190, 0, 24), true)
		makeLabel(card,
			"You applied to <b>" .. appName .. "</b>. The result arrives after six months. Acceptance chance: <b>" .. tostring(data.DojoApplicationChance or "?") .. "%</b>.",
			12, COLORS.SubText,
			UDim2.new(0, 20, 0, 46), isMobile and UDim2.new(1, -40, 0, 58) or UDim2.new(1, -190, 0, 58), false)
		makeLabel(card, "Age once after the timer reaches 0 to receive the result popup.", 11, COLORS.Muted,
			UDim2.new(0, 20, 0, 108), isMobile and UDim2.new(1, -40, 0, 24) or UDim2.new(1, -190, 0, 24), false)
		if isMobile then
			makeButton(card, "PENDING", COLORS.Button, 20, 140, 142, 34, nil)
		else
			makeRightButton(card, "PENDING", COLORS.Button, 56, nil)
		end
	else
		makeLabel(card, "Apply for Dojo", 17, COLORS.Text,
			UDim2.new(0, 20, 0, 16), isMobile and UDim2.new(1, -40, 0, 24) or UDim2.new(1, -190, 0, 24), true)
		makeLabel(card,
			"Apply to an outside dojo as a <b>" .. pathLabel .. "</b>. After six months, you either get accepted or rejected. Your sensei can be a Jujutsu High teacher, a senior sorcerer, or sometimes your father.",
			12, COLORS.SubText,
			UDim2.new(0, 20, 0, 46), isMobile and UDim2.new(1, -40, 0, 86) or UDim2.new(1, -190, 0, 58), false)
		-- Update 4.1: curse rebirth help text
		makeLabel(card,
			"<font color='#b27aff'>Cursed Spirit rebirth requires enough Cursed Resentment before death.</font>",
			10, COLORS.Muted,
			UDim2.new(0, 20, 0, isMobile and 134 or 108), isMobile and UDim2.new(1, -40, 0, 24) or UDim2.new(1, -190, 0, 18), false)
		if isMobile then
			makeButton(card, "APPLY", COLORS.Green, 20, 168, 142, 34, function()
				fireAssetAction("ApplyForOutsideDojo", "grand_dojo")
			end)
		else
			makeRightButton(card, "APPLY", COLORS.Green, 56, function()
				fireAssetAction("ApplyForOutsideDojo", "grand_dojo")
			end)
		end
	end
end

-- Update 4.1 (Item 3): dojo limit feedback on the three action cards.
buildJoinedDojoMenu = function(data)
	makeHeader("Joined Dojo")
	buildDojoBackCard("Back to the Grand Dojo action board.")

	local joinedName = tostring(data.JoinedDojoName or "")
	if joinedName == "" then
		local card = makeCard(126)
		makeLabel(card, "No joined dojo yet.", 18, COLORS.Text,
			UDim2.new(0, 20, 0, 18), UDim2.new(1, -190, 0, 26), true)
		makeLabel(card, "Apply first. After six months, the dojo will accept or reject your application.", 12, COLORS.SubText,
			UDim2.new(0, 20, 0, 52), UDim2.new(1, -190, 0, 38), false)
		makeRightButton(card, "APPLY", COLORS.Green, 42, function()
			fireAssetAction("ApplyForOutsideDojo", "grand_dojo")
		end)
		return
	end

	local trust       = tonumber(data.JoinedDojoTrust) or 0
	local progress    = tonumber(data.JoinedDojoProgress) or 0
	local assignments = tonumber(data.JoinedDojoAssignments) or 0

	local summary = makeCard(236)
	addStroke(summary, COLORS.GoldStroke, 1)
	makeLabel(summary, joinedName, 21, COLORS.Text,
		UDim2.new(0, 20, 0, 16), UDim2.new(1, -40, 0, 30), true)
	makeLabel(summary,
		"<b>Rank:</b> " .. tostring(data.JoinedDojoRank or "Local Dojo") ..
			"\n<b>Focus:</b> " .. tostring(data.JoinedDojoFocus or "Balanced") ..
			"\n<b>Sensei:</b> " .. tostring(data.JoinedDojoSenseiName or "Unknown") .. " • " .. tostring(data.JoinedDojoSenseiGrade or "Grade 1") .. " • Age " .. tostring(data.JoinedDojoSenseiAge or "?") ..
			"\n<b>Sensei Source:</b> " .. tostring(data.JoinedDojoSenseiRelation or "Outside Sensei"),
		12, COLORS.SubText,
		UDim2.new(0, 20, 0, 54), UDim2.new(1, -40, 0, 92), false)
	makeProgressBar(summary, 20,  154, 240, "Dojo Trust",     trust,          100, COLORS.Green)
	makeProgressBar(summary, 286, 154, 240, "Dojo Progress",  progress % 100, 100, COLORS.Gold)

	-- Train card with limit feedback
	local trainCard = makeCard(118)
	makeLabel(trainCard, "Train With Sensei", 18, COLORS.Text,
		UDim2.new(0, 20, 0, 16), UDim2.new(1, -190, 0, 26), true)
	makeLabel(trainCard,
		buildDojoLimitText(
			"Gain CE, mastery, trust, and dojo progress. Focus changes the reward spread.",
			data.JoinedDojoTrainUsesLeft, data.JoinedDojoTrainLimit,
			"Sensei training left this 6 months"
		),
		12, COLORS.SubText,
		UDim2.new(0, 20, 0, 50), UDim2.new(1, -190, 0, 40), false)
	makeRightButton(trainCard, "TRAIN", COLORS.Purple, 42, function()
		fireAssetAction("TrainAtJoinedDojo", "grand_dojo")
	end)

	-- Assignment card with limit feedback
	local assignmentCard = makeCard(118)
	makeLabel(assignmentCard, "Dojo Assignment", 18, COLORS.Text,
		UDim2.new(0, 20, 0, 16), UDim2.new(1, -190, 0, 26), true)
	makeLabel(assignmentCard,
		buildDojoLimitText(
			"Complete work for your dojo. Assignments completed: " .. tostring(assignments) .. ". Rewards money, reputation, trust, and progress.",
			data.JoinedDojoAssignmentUsesLeft, data.JoinedDojoAssignmentLimit,
			"Dojo assignments left this 6 months"
		),
		12, COLORS.SubText,
		UDim2.new(0, 20, 0, 50), UDim2.new(1, -190, 0, 40), false)
	makeRightButton(assignmentCard, "START", COLORS.Blue, 42, function()
		fireAssetAction("JoinedDojoAssignment", "grand_dojo")
	end)

	-- Ask Sensei card with limit feedback
	local senseiCard = makeCard(118)
	makeLabel(senseiCard, "Ask Sensei", 18, COLORS.Text,
		UDim2.new(0, 20, 0, 16), UDim2.new(1, -190, 0, 26), true)
	makeLabel(senseiCard,
		buildDojoLimitText(
			"Ask for personal advice. If your sensei is your father or Jujutsu High teacher, the advice has different flavor.",
			data.JoinedDojoSenseiUsesLeft, data.JoinedDojoSenseiLimit,
			"Sensei advice left this 6 months"
		),
		12, COLORS.SubText,
		UDim2.new(0, 20, 0, 50), UDim2.new(1, -190, 0, 40), false)
	makeRightButton(senseiCard, "ASK", COLORS.Gold, 42, function()
		fireAssetAction("AskJoinedSensei", "grand_dojo")
	end)

	local leaveCard = makeCard(102)
	makeLabel(leaveCard, "Leave Dojo", 17, COLORS.Text,
		UDim2.new(0, 20, 0, 16), UDim2.new(1, -190, 0, 24), true)
	makeLabel(leaveCard, "Leave this outside dojo. Your own founded clan/Grand Dojo stays separate.", 12, COLORS.SubText,
		UDim2.new(0, 20, 0, 46), UDim2.new(1, -190, 0, 34), false)
	makeRightButton(leaveCard, "LEAVE", COLORS.Red, 32, function()
		fireAssetAction("LeaveJoinedDojo", "grand_dojo")
	end)
end

local function buildDojoHomeCards(data)
	makeHeader("Dojo Action Board")
	buildOutsideDojoCard(data)

	local recruitCard = makeCard(116)
	makeLabel(recruitCard, "Recruit Students", 17, COLORS.Text,
		UDim2.new(0, 20, 0, 16), UDim2.new(1, -190, 0, 24), true)
	makeLabel(recruitCard, "Open the recruit board. Question, examine, or recruit candidates from their cards.",
		12, COLORS.SubText, UDim2.new(0, 20, 0, 46), UDim2.new(1, -190, 0, 48), false)
	makeRightButton(recruitCard, "OPEN", COLORS.Green, 40, function() setDojoPage("Recruit") end)

	local studentCard = makeCard(116)
	makeLabel(studentCard, "Manage Students", 17, COLORS.Text,
		UDim2.new(0, 20, 0, 16), UDim2.new(1, -190, 0, 24), true)
	makeLabel(studentCard, "Open student management. View your students, their traits, grade, CE, technique, and potential.",
		12, COLORS.SubText, UDim2.new(0, 20, 0, 46), UDim2.new(1, -190, 0, 48), false)
	makeRightButton(studentCard, "OPEN", COLORS.Blue, 40, function() setDojoPage("Students") end)

	local rankName = tostring(data.ClanRankName or select(1, getDojoRankInfo(data)))
	local repToNext = tonumber(data.ClanReputationToNext) or 0
	local bonusStudents = tonumber(data.ClanReputationBonusStudents) or 0
	local repCard = makeCard(118)
	addStroke(repCard, COLORS.GoldStroke, 1)
	makeLabel(repCard, "Reputation Benefits", 17, COLORS.Gold,
		UDim2.new(0, 20, 0, 14), UDim2.new(1, -190, 0, 24), true)
	makeLabel(repCard, rankName .. "  •  +" .. tostring(bonusStudents) .. " student slots from reputation",
		12, COLORS.Text, UDim2.new(0, 20, 0, 42), UDim2.new(1, -190, 0, 20), true)
	local repText = tostring(data.ClanReputationBenefit or "Build reputation through training, events, and rival challenges.")
	if repToNext > 0 then
		repText = repText .. " Next rank in " .. tostring(repToNext) .. " rep."
	else
		repText = repText .. " Max rank reached."
	end
	makeLabel(repCard, repText, 12, COLORS.SubText,
		UDim2.new(0, 20, 0, 66), UDim2.new(1, -190, 0, 36), false)
	makeRightButton(repCard, "RANK", COLORS.Gold, 42, nil)

	local standingCard = makeCard(112)
	addStroke(standingCard, COLORS.StrokeSoft, 1)
	makeLabel(standingCard, "Competitive Standing", 17, COLORS.Text,
		UDim2.new(0, 20, 0, 14), UDim2.new(1, -190, 0, 24), true)
	makeLabel(standingCard, tostring(data.ClanCompetitiveTier or "Local") .. "  •  Score " .. tostring(data.ClanCompetitiveScore or 0) .. "  •  " .. tostring(data.ClanCompetitionRecord or "0W-0L"),
		12, COLORS.Gold, UDim2.new(0, 20, 0, 42), UDim2.new(1, -190, 0, 20), true)
	makeLabel(standingCard, "Built from clan reputation, dojo prestige, students, events, and rival results.",
		12, COLORS.SubText, UDim2.new(0, 20, 0, 66), UDim2.new(1, -190, 0, 28), false)
	makeRightButton(standingCard, "SCORE", COLORS.Button, 38, nil)

	local trainCard = makeCard(116)
	makeLabel(trainCard, "Train Dojo", 17, COLORS.Text,
		UDim2.new(0, 20, 0, 16), UDim2.new(1, -190, 0, 24), true)
	makeLabel(trainCard, "Open training. Set focus and run sessions for loyalty, cursed energy, and reputation.",
		12, COLORS.SubText, UDim2.new(0, 20, 0, 46), UDim2.new(1, -190, 0, 48), false)
	makeRightButton(trainCard, "OPEN", COLORS.Purple, 40, function() setDojoPage("Training") end)

	local eventAvailable = data.DojoEventAvailable == true
	local eventCooldown = tonumber(data.DojoEventCooldownMonths) or 0
	local eventCard = makeCard(124)
	addStroke(eventCard, eventAvailable and COLORS.GoldStroke or COLORS.StrokeSoft, eventAvailable and 2 or 1)
	makeLabel(eventCard, "Dojo Event", 17, eventAvailable and COLORS.Gold or COLORS.Text,
		UDim2.new(0, 20, 0, 14), UDim2.new(1, -190, 0, 24), true)
	makeLabel(eventCard, tostring(data.DojoEventTitle or "Open Training Day"), 13, COLORS.Text,
		UDim2.new(0, 20, 0, 40), UDim2.new(1, -190, 0, 20), true)
	local eventText = tostring(data.DojoEventDescription or "Host a small clan event for reputation and student progress.")
	if not eventAvailable then
		if (tonumber(data.ClanStudentCount) or 0) <= 0 then
			eventText = eventText .. " Recruit students first."
		elseif eventCooldown > 0 then
			eventText = eventText .. " Next event in " .. tostring(eventCooldown) .. " month(s)."
		else
			eventText = eventText .. " Not available yet."
		end
	end
	makeLabel(eventCard, eventText, 12, COLORS.SubText,
		UDim2.new(0, 20, 0, 64), UDim2.new(1, -190, 0, 42), false)
	local eventButton = makeRightButton(eventCard, eventAvailable and tostring(data.DojoEventButton or "HOST") or "WAIT", eventAvailable and COLORS.Gold or COLORS.Button, 44, function()
		if eventAvailable then fireAssetAction("ResolveDojoEvent", "grand_dojo") end
	end)
	if not eventAvailable then
		eventButton.Active = false
		eventButton.TextColor3 = COLORS.SubText
	end

	local rivalAvailable = data.RivalChallengeAvailable == true
	local rivalCooldown = tonumber(data.RivalChallengeCooldownMonths) or 0
	local rivalCard = makeCard(124)
	addStroke(rivalCard, rivalAvailable and COLORS.RedStroke or COLORS.StrokeSoft, rivalAvailable and 2 or 1)
	makeLabel(rivalCard, "Rival Dojo", 17, rivalAvailable and COLORS.Red or COLORS.Text,
		UDim2.new(0, 20, 0, 14), UDim2.new(1, -190, 0, 24), true)
	makeLabel(rivalCard, tostring(data.RivalDojoName or "Unknown Rival"), 13, COLORS.Text,
		UDim2.new(0, 20, 0, 40), UDim2.new(1, -190, 0, 20), true)
	local rivalText = "Focus: " .. tostring(data.RivalDojoFocus or "Balanced") .. "  •  Rep: " .. tostring(data.RivalDojoReputation or 0)
	if not rivalAvailable then
		if (tonumber(data.ClanStudentCount) or 0) <= 0 then
			rivalText = rivalText .. ". Recruit students first."
		elseif rivalCooldown > 0 then
			rivalText = rivalText .. ". Next challenge in " .. tostring(rivalCooldown) .. " month(s)."
		else
			rivalText = rivalText .. ". Not available yet."
		end
	end
	makeLabel(rivalCard, rivalText, 12, COLORS.SubText,
		UDim2.new(0, 20, 0, 64), UDim2.new(1, -190, 0, 42), false)
	local rivalButton = makeRightButton(rivalCard, rivalAvailable and "CHALLENGE" or "WAIT", rivalAvailable and COLORS.Red or COLORS.Button, 44, function()
		if rivalAvailable then fireAssetAction("ChallengeRivalDojo", "grand_dojo") end
	end)
	if not rivalAvailable then
		rivalButton.Active = false
		rivalButton.TextColor3 = COLORS.SubText
	end

	local condition  = tonumber(data.DojoCondition) or 100
	local repairCost = tonumber(data.DojoMaintainCost) or 0
	local repairCard = makeCard(116)
	makeLabel(repairCard, "Repair / Maintain Dojo", 17, COLORS.Text,
		UDim2.new(0, 20, 0, 16), UDim2.new(1, -190, 0, 24), true)
	makeLabel(repairCard,
		"Condition: " .. formatPercent(condition) .. "  •  Cost: $" .. tostring(repairCost) .. ". Keeps students from being punished by a broken hall.",
		12, COLORS.SubText, UDim2.new(0, 20, 0, 46), UDim2.new(1, -190, 0, 48), false)
	makeRightButton(repairCard, condition >= 100 and "FULL" or "REPAIR", condition >= 100 and COLORS.Button or COLORS.Gold, 40, function()
		if condition < 100 then fireAssetAction("MaintainDojo", "grand_dojo") end
	end)
end

local function buildCandidateCard(index, candidate, limit, used)
	local isConfirm  = recruitConfirmId == candidate.Id
	local isQuestion = questionCandidateId == candidate.Id
	local height = 248
	if isConfirm  then height = 320
	elseif isQuestion then height = 348 end

	local traits      = getProfileTraits(candidate)
	local gradeText   = tostring(candidate.Grade or "Non-Sorcerer")
	local potentialText = tostring(candidate.DojoPotential or "Unknown")
	local fitTier = tostring(candidate.RecruitFitTier or "Steady")
	local fitLabel = tostring(candidate.RecruitFitLabel or "Steady Fit")
	local fitScore = tonumber(candidate.RecruitFitScore) or 0
	local fitNote = tostring(candidate.RecruitFitNote or "Compare grade, CE, CT, and potential.")
	local fitColor = recruitFitColor(fitTier)

	local card       = makeCard(height)
	addStroke(card, fitTier == "Elite" and COLORS.Gold or COLORS.StrokeSoft, fitTier == "Elite" and 2 or 1)

	makeInitialBadge(card, candidate, 20, 18, COLORS.Accent)
	makeLabel(card, tostring(index) .. ". " .. tostring(candidate.Name or "Unknown"), 18, COLORS.Text,
		UDim2.new(0, 88, 0, 16), UDim2.new(1, -278, 0, 26), true)
	makeLabel(card, gradeText .. "  •  Age " .. tostring(candidate.Age or 0) .. "  •  " .. tostring(candidate.OriginLocation or "Unknown"),
		12, COLORS.Gold, UDim2.new(0, 88, 0, 43), UDim2.new(1, -278, 0, 18), true)
	makeTraitPills(card, traits, 88, 70)
	makeLabel(card, "Previous School: " .. tostring(candidate.PreviousSchool or "Unknown"),
		12, COLORS.SubText, UDim2.new(0, 20, 0, 104), UDim2.new(1, -210, 0, 18), false)
	makeLabel(card, "Potential: " .. potentialText .. "  •  CE: " .. tostring(candidate.CursedEnergy or 0) .. "  •  CT: " .. tostring(candidate.CursedTechnique or "None"),
		12, COLORS.Muted, UDim2.new(0, 20, 0, 128), UDim2.new(1, -210, 0, 18), false)
	makeLabel(card, fitLabel .. "  •  " .. tostring(fitScore) .. "/100  •  " .. fitNote,
		12, fitColor, UDim2.new(0, 20, 0, 152), UDim2.new(1, -210, 0, 18), true)
	makeLabel(card, getCandidateRead(candidate),
		12, COLORS.SubText, UDim2.new(0, 20, 0, 174), UDim2.new(1, -210, 0, 34), false)
	makeLabel(card, "Background: " .. tostring(candidate.Background or "No detailed background available."),
		11, COLORS.Muted, UDim2.new(0, 20, 0, 208), UDim2.new(1, -210, 0, 28), false)

	makeButton(card, "QUESTION", COLORS.Purple, 0, 28, 142, 32, function()
		preserveScrollOnNextRefresh = true
		questionCandidateId = candidate.Id
		recruitConfirmId = nil
		questionAnswerByCandidateId[candidate.Id] = getCandidateQuestionAnswer(candidate, "WhyJoin")
		refreshAssets()
	end).Position = UDim2.new(1, -162, 0, 28)

	makeButton(card, "EXAMINE", COLORS.Blue, 0, 70, 142, 32, function()
		showExamine(candidate)
	end).Position = UDim2.new(1, -162, 0, 70)

	makeButton(card, "RECRUIT", COLORS.Green, 0, 112, 142, 32, function()
		preserveScrollOnNextRefresh = true
		recruitConfirmId = candidate.Id
		questionCandidateId = nil
		refreshAssets()
	end).Position = UDim2.new(1, -162, 0, 112)

	if isConfirm then
		makeLabel(card, "Recruit " .. tostring(candidate.Name or "this student") .. "?", 15, COLORS.Gold,
			UDim2.new(0, 20, 0, 242), UDim2.new(1, -40, 0, 22), true)
		makeLabel(card, "This uses 1 starter slot. Current progress: " .. tostring(used) .. " / " .. tostring(limit) .. ".",
			12, COLORS.SubText, UDim2.new(0, 20, 0, 266), UDim2.new(1, -40, 0, 18), false)
		makeButton(card, "YES", COLORS.Green, 20, 290, 110, 28, function()
			preserveScrollOnNextRefresh = true
			fireAssetAction("RecruitCandidate|" .. tostring(candidate.Id), "grand_dojo")
			recruitConfirmId = nil
			questionCandidateId = nil
		end)
		makeButton(card, "NO", COLORS.Red, 142, 290, 110, 28, function()
			preserveScrollOnNextRefresh = true
			recruitConfirmId = nil
			refreshAssets()
		end)
	elseif isQuestion then
		local current = questionAnswerByCandidateId[candidate.Id] or getCandidateQuestionAnswer(candidate, "WhyJoin")
		makeLabel(card, "Question", 13, COLORS.Gold,
			UDim2.new(0, 20, 0, 242), UDim2.new(1, -40, 0, 18), true)
		makeButton(card, "WHY JOIN?",  COLORS.Button, 20,  266, 120, 28, function()
			preserveScrollOnNextRefresh = true
			questionAnswerByCandidateId[candidate.Id] = getCandidateQuestionAnswer(candidate, "WhyJoin")
			refreshAssets()
		end)
		makeButton(card, "OLD SCHOOL", COLORS.Button, 152, 266, 120, 28, function()
			preserveScrollOnNextRefresh = true
			questionAnswerByCandidateId[candidate.Id] = getCandidateQuestionAnswer(candidate, "OldSchool")
			refreshAssets()
		end)
		makeButton(card, "GOAL",       COLORS.Button, 284, 266, 100, 28, function()
			preserveScrollOnNextRefresh = true
			questionAnswerByCandidateId[candidate.Id] = getCandidateQuestionAnswer(candidate, "Goal")
			refreshAssets()
		end)
		makeLabel(card, '"' .. tostring(current) .. '"', 13, COLORS.Text,
			UDim2.new(0, 20, 0, 304), UDim2.new(1, -40, 0, 36), false)
	end
end

local function buildStudentCard(index, student)
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local mobile = viewport.X < 900
	local portrait = mobile and viewport.Y > viewport.X
	local card = makeCard(portrait and 386 or (mobile and 336 or 286))
	addStroke(card, student.PromotionReady == true and COLORS.Gold or COLORS.StrokeSoft, student.PromotionReady == true and 2 or 1)

	local traits     = getProfileTraits(student)
	local flavorLine = getStudentFlavorLine(student)
	local planLine   = getStudentPlanLine(student)
	local promotionProgress = math.max(0, tonumber(student.PromotionProgress) or tonumber(student.DojoProgress) or 0)
	local promotionNeeded = math.max(0, tonumber(student.PromotionNeeded) or 0)
	local promotionRatio = promotionNeeded > 0 and math.clamp(promotionProgress / promotionNeeded, 0, 1) or 1
	local nextGrade = tostring(student.NextGrade or "promotion")
	local promotionText = student.PromotionReady == true and ("Ready for " .. nextGrade) or tostring(student.PromotionText or "Training builds promotion progress")
	local promotionCountText = promotionNeeded > 0 and (tostring(math.floor(promotionProgress)) .. " / " .. tostring(promotionNeeded)) or "MAX"
	local textRightPad = mobile and 28 or 278
	local bodyRightPad = mobile and 40 or 210

	makeInitialBadge(card, student, 20, 18, COLORS.Blue)
	local badge = card:FindFirstChild("InitialBadge")
	if badge and portrait then
		badge.Size = UDim2.new(0, 54, 0, 54)
	end
	local title = makeLabel(card, tostring(index) .. ". " .. tostring(student.Name or "Unknown"), mobile and 15 or 18, COLORS.Text,
		UDim2.new(0, portrait and 86 or 88, 0, 16), UDim2.new(1, -textRightPad, 0, 24), true)
	title.TextWrapped = false
	title.TextTruncate = Enum.TextTruncate.AtEnd
	makeLabel(card, tostring(student.Grade or "Non-Sorcerer") .. "  |  Age " .. tostring(student.Age or 0) .. "  |  " .. tostring(student.Role or "Student"),
		mobile and 10 or 12, COLORS.Gold, UDim2.new(0, portrait and 86 or 88, 0, 43), UDim2.new(1, -textRightPad, 0, 18), true)
	makeTraitPills(card, traits, portrait and 20 or 88, portrait and 82 or 70)
	makeLabel(card, "CE: " .. tostring(student.CursedEnergy or 0) .. "  |  Potential: " .. tostring(student.DojoPotential or "Unknown"),
		mobile and 10 or 12, COLORS.SubText, UDim2.new(0, 20, 0, portrait and 132 or 106), UDim2.new(1, -bodyRightPad, 0, 18), false)
	makeLabel(card, "Technique: " .. tostring(student.CursedTechnique or "None"),
		mobile and 10 or 12, COLORS.Muted, UDim2.new(0, 20, 0, portrait and 154 or 130), UDim2.new(1, -bodyRightPad, 0, 18), false)
	makeLabel(card, "From: " .. tostring(student.OriginLocation or "Unknown") .. "  |  School: " .. tostring(student.PreviousSchool or "Unknown"),
		mobile and 10 or 12, COLORS.SubText, UDim2.new(0, 20, 0, portrait and 176 or 154), UDim2.new(1, -bodyRightPad, 0, portrait and 34 or 26), false)

	local promoCard = Instance.new("Frame")
	promoCard.Size = UDim2.new(1, -bodyRightPad, 0, 42)
	promoCard.Position = UDim2.new(0, 20, 0, portrait and 218 or 184)
	promoCard.BackgroundColor3 = COLORS.CardDark
	promoCard.BorderSizePixel = 0
	promoCard.ZIndex = 355
	promoCard.Parent = card
	addCorner(promoCard, 10)
	addStroke(promoCard, student.PromotionReady == true and COLORS.Gold or COLORS.StrokeSoft, 1)
	makeLabel(promoCard, promotionText, 11, student.PromotionReady == true and COLORS.Gold or COLORS.SubText,
		UDim2.new(0, 12, 0, 5), UDim2.new(1, -104, 0, 14), true)
	local promoTrack = Instance.new("Frame")
	promoTrack.Size = UDim2.new(1, -24, 0, 8)
	promoTrack.Position = UDim2.new(0, 12, 0, 25)
	promoTrack.BackgroundColor3 = COLORS.Track
	promoTrack.BorderSizePixel = 0
	promoTrack.ZIndex = 356
	promoTrack.Parent = promoCard
	addCorner(promoTrack, 6)
	local promoFill = Instance.new("Frame")
	promoFill.Size = UDim2.new(promotionRatio, 0, 1, 0)
	promoFill.BackgroundColor3 = student.PromotionReady == true and COLORS.Gold or COLORS.Green
	promoFill.BorderSizePixel = 0
	promoFill.ZIndex = 357
	promoFill.Parent = promoTrack
	addCorner(promoFill, 6)
	makeLabel(promoCard, promotionCountText, 10, COLORS.Text,
		UDim2.new(1, -104, 0, 5), UDim2.new(0, 92, 0, 14), true).TextXAlignment = Enum.TextXAlignment.Right

	local readCard = Instance.new("Frame")
	readCard.Size = UDim2.new(1, -bodyRightPad, 0, portrait and 58 or 42)
	readCard.Position = UDim2.new(0, 20, 0, portrait and 270 or 234)
	readCard.BackgroundColor3 = COLORS.CardDark
	readCard.BorderSizePixel = 0
	readCard.ZIndex = 355
	readCard.Parent = card
	addCorner(readCard, 10)
	addStroke(readCard, COLORS.StrokeSoft, 1)
	makeLabel(readCard, "Student Read", 10, COLORS.Gold,
		UDim2.new(0, 12, 0, 6), UDim2.new(1, -24, 0, 14), true)
	makeLabel(readCard, flavorLine .. " " .. planLine,
		mobile and 10 or 11, COLORS.SubText, UDim2.new(0, 12, 0, 21), UDim2.new(1, -24, 0, portrait and 30 or 17), false)

	if mobile then
		local buttonY = portrait and 342 or 290
		local trainButton = makeButton(card, "TRAIN", COLORS.Purple, 0, buttonY, 96, 32, function() setDojoPage("Training") end)
		trainButton.Size = UDim2.new(0.29, 0, 0, 32)
		trainButton.Position = UDim2.new(0.06, 0, 0, buttonY)
		local profileButton = makeButton(card, "PROFILE", COLORS.Blue, 0, buttonY, 96, 32, function() showExamine(student) end)
		profileButton.Size = UDim2.new(0.29, 0, 0, 32)
		profileButton.Position = UDim2.new(0.355, 0, 0, buttonY)
		local missionButton = makeButton(card, "MISSION", COLORS.Button, 0, buttonY, 96, 32, function()
			preserveScrollOnNextRefresh = true
			fireAssetAction("TrainStudents", "grand_dojo")
		end)
		missionButton.Size = UDim2.new(0.29, 0, 0, 32)
		missionButton.Position = UDim2.new(0.65, 0, 0, buttonY)
	else
		makeButton(card, "TRAIN", COLORS.Purple, 0, 28, 142, 32, function() setDojoPage("Training") end).Position = UDim2.new(1, -162, 0, 28)
		makeButton(card, "PROFILE", COLORS.Blue, 0, 70, 142, 32, function() showExamine(student) end).Position = UDim2.new(1, -162, 0, 70)
		makeButton(card, "MISSION", COLORS.Button, 0, 112, 142, 32, function()
			preserveScrollOnNextRefresh = true
			fireAssetAction("TrainStudents", "grand_dojo")
		end).Position = UDim2.new(1, -162, 0, 112)
	end
end

----------------------------------------------------------------
-- MAIN REFRESH
----------------------------------------------------------------
refreshAssets = function()
	local restorePos    = scroll.CanvasPosition
	local shouldReset   = resetScrollOnNextRefresh == true
	local shouldPreserve = not shouldReset
	preserveScrollOnNextRefresh = false
	resetScrollOnNextRefresh    = false

	local ok, data = pcall(function() return getAssets:InvokeServer() end)
	clearCards()

	if not ok then
		warn("[BitKaisenAssetsUI] Failed to load assets:", data)
		makeEmptyCard("Could not load assets. Check GetAssets server function.")
		return
	end

	currentData = data or {}
	moneyLabel.Text = "Money: $" .. formatMoneyAmount(currentData.Money or 0)
	if (tonumber(currentData.Age) or 0) < 16 and currentData.ParentAssetRequestLimit then
		local requestLimit = tonumber(currentData.ParentAssetRequestLimit) or 0
		local requestsUsed = tonumber(currentData.ParentAssetRequestsUsed) or 0
		local giftLimit = tonumber(currentData.ParentAssetGiftLimit) or 0
		local giftsReceived = tonumber(currentData.ParentAssetGiftsReceived) or 0
		setActionStatus("Parent asks left: " .. tostring(math.max(0, requestLimit - requestsUsed)) .. " | Gifts left: " .. tostring(math.max(0, giftLimit - giftsReceived)), COLORS.Gold)
	elseif actionStatusLabel.Text ~= "Processing action..." then
		setActionStatus("")
	end

	local renderedAssetCards = 0
	local function yieldForLargeAssetLists()
		renderedAssetCards += 1
		if renderedAssetCards % 8 == 0 then
			scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 48)
			task.wait()
		end
	end

	if currentData.ClanFounded then
		clanLabel.Text = "Clan: " .. tostring(currentData.PlayerClanName or "Founded")
	else
		clanLabel.Text = currentData.HasGrandDojo and "Grand Dojo owned" or ""
	end

	-------------------------------------------------- OWNED
	if currentTab == "Owned" then
		makeHeader("Owned Assets")
		local owned = currentData.Owned or {}
		if #owned <= 0 then
			makeEmptyCard("You do not own any assets yet.")
		else
			for _, asset in ipairs(owned) do
				local card = Instance.new("Frame")
				card.Size = UDim2.new(1, -10, 0, 132)
				card.BackgroundColor3 = COLORS.Card
				card.BorderSizePixel = 0
				card.ZIndex = 354
				card.Parent = scroll
				addCorner(card, 8)
				addStroke(card, COLORS.Stroke, 1)

				local color = rarityColor(asset.Rarity)

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = UDim2.new(1, -170, 0, 24)
				nameLabel.Position = UDim2.new(0, 18, 0, 14)
				nameLabel.BackgroundTransparency = 1
				nameLabel.TextColor3 = COLORS.Text
				nameLabel.TextSize = 17
				nameLabel.Font = Enum.Font.GothamBlack
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.Text = tostring(asset.Name or "Unknown Asset")
				nameLabel.ZIndex = 355
				nameLabel.Parent = card

				local rarityLabel = Instance.new("TextLabel")
				rarityLabel.Size = UDim2.new(0, 130, 0, 22)
				rarityLabel.Position = UDim2.new(1, -150, 0, 16)
				rarityLabel.BackgroundTransparency = 1
				rarityLabel.TextColor3 = color
				rarityLabel.TextSize = 13
				rarityLabel.Font = Enum.Font.GothamBlack
				rarityLabel.TextXAlignment = Enum.TextXAlignment.Right
				rarityLabel.Text = tostring(asset.Rarity or "Common")
				rarityLabel.ZIndex = 355
				rarityLabel.Parent = card

				local descLabel = Instance.new("TextLabel")
				descLabel.Size = UDim2.new(1, -178, 0, 50)
				descLabel.Position = UDim2.new(0, 18, 0, 48)
				descLabel.BackgroundTransparency = 1
				descLabel.TextColor3 = Color3.fromRGB(185, 185, 195)
				descLabel.TextSize = 12
				descLabel.Font = Enum.Font.GothamMedium
				descLabel.TextWrapped = true
				descLabel.TextXAlignment = Enum.TextXAlignment.Left
				descLabel.TextYAlignment = Enum.TextYAlignment.Top
				descLabel.Text = tostring(asset.Description or "")
				descLabel.ZIndex = 355
				descLabel.Parent = card

				local effectsLabel = Instance.new("TextLabel")
				effectsLabel.Size = UDim2.new(1, -178, 0, 20)
				effectsLabel.Position = UDim2.new(0, 18, 0, 102)
				effectsLabel.BackgroundTransparency = 1
				effectsLabel.TextColor3 = color
				effectsLabel.TextSize = 12
				effectsLabel.Font = Enum.Font.GothamBlack
				effectsLabel.TextXAlignment = Enum.TextXAlignment.Left
				effectsLabel.Text = tostring(asset.EffectsText or "")
				effectsLabel.ZIndex = 355
				effectsLabel.Parent = card

				if asset.Id == "grand_dojo" and not currentData.ClanFounded then
					local b = Instance.new("TextButton")
					b.Size = UDim2.new(0, 122, 0, 38)
					b.Position = UDim2.new(1, -140, 0.5, -19)
					b.BackgroundColor3 = Color3.fromRGB(150, 100, 35)
					b.BorderSizePixel = 0
					b.TextColor3 = COLORS.Text
					b.TextSize = 12
					b.Font = Enum.Font.GothamBlack
					b.Text = "OPEN DOJO"
					b.AutoButtonColor = false
					b.ZIndex = 356
					b.Parent = card
					addCorner(b, 7)
					addStroke(b, Color3.fromRGB(60, 60, 75), 1)
					setButtonTween(b, lighten(Color3.fromRGB(150, 100, 35), 20))
					b.MouseButton1Click:Connect(function()
						setTab("Dojo")
						refreshAssets()
					end)
				elseif asset.CanUse and (asset.Uses == nil or asset.Uses > 0) then
					local b = Instance.new("TextButton")
					b.Size = UDim2.new(0, 122, 0, 38)
					b.Position = UDim2.new(1, -140, 0.5, -19)
					b.BackgroundColor3 = Color3.fromRGB(85, 45, 130)
					b.BorderSizePixel = 0
					b.TextColor3 = COLORS.Text
					b.TextSize = 12
					b.Font = Enum.Font.GothamBlack
					b.Text = "USE"
					b.AutoButtonColor = false
					b.ZIndex = 356
					b.Parent = card
					addCorner(b, 7)
					addStroke(b, Color3.fromRGB(60, 60, 75), 1)
					setButtonTween(b, lighten(Color3.fromRGB(85, 45, 130), 20))
					b.MouseButton1Click:Connect(function()
						fireAssetAction("Use", asset.Id)
					end)
				else
					local b = Instance.new("TextButton")
					b.Size = UDim2.new(0, 122, 0, 38)
					b.Position = UDim2.new(1, -140, 0.5, -19)
					b.BackgroundColor3 = COLORS.Button
					b.BorderSizePixel = 0
					b.TextColor3 = COLORS.SubText
					b.TextSize = 12
					b.Font = Enum.Font.GothamBlack
					b.Text = asset.CanUse and "USED" or "PASSIVE"
					b.AutoButtonColor = false
					b.Active = false
					b.ZIndex = 356
					b.Parent = card
					addCorner(b, 7)
					addStroke(b, Color3.fromRGB(60, 60, 75), 1)
				end
				yieldForLargeAssetLists()
			end
		end

		makeHeader("Cursed Tools")
		local cursedTools = currentData.CursedTools or {}
		local toolViewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		local compactToolCards = toolViewport.X < 760
		if #cursedTools <= 0 then
			makeEmptyCard("No cursed tools owned yet. Defeat stronger enemies and clear rare events to find cursed tools.")
		else
			for _, tool in ipairs(cursedTools) do
				local card = Instance.new("Frame")
				card.Size = UDim2.new(1, -10, 0, compactToolCards and 172 or 136)
				card.BackgroundColor3 = COLORS.Card
				card.BorderSizePixel = 0
				card.ZIndex = 354
				card.Parent = scroll
				addCorner(card, 8)
				addStroke(card, tool.Equipped and COLORS.Gold or COLORS.Stroke, tool.Equipped and 2 or 1)

				local color = rarityColor(tool.Rarity)
				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = compactToolCards and UDim2.new(1, -36, 0, 24) or UDim2.new(1, -178, 0, 24)
				nameLabel.Position = UDim2.new(0, 18, 0, 14)
				nameLabel.BackgroundTransparency = 1
				nameLabel.TextColor3 = COLORS.Text
				nameLabel.TextSize = 17
				nameLabel.Font = Enum.Font.GothamBlack
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
				nameLabel.Text = tostring(tool.Name or "Cursed Tool") .. (tool.Equipped and "  [EQUIPPED]" or "")
				nameLabel.ZIndex = 355
				nameLabel.Parent = card

				local rarityLabel = Instance.new("TextLabel")
				rarityLabel.Size = compactToolCards and UDim2.new(1, -36, 0, 20) or UDim2.new(0, 140, 0, 22)
				rarityLabel.Position = compactToolCards and UDim2.new(0, 18, 0, 38) or UDim2.new(1, -158, 0, 16)
				rarityLabel.BackgroundTransparency = 1
				rarityLabel.TextColor3 = color
				rarityLabel.TextSize = 12
				rarityLabel.Font = Enum.Font.GothamBlack
				rarityLabel.TextXAlignment = compactToolCards and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
				rarityLabel.TextTruncate = Enum.TextTruncate.AtEnd
				rarityLabel.Text = tostring(tool.Rarity or "Common")
				rarityLabel.ZIndex = 355
				rarityLabel.Parent = card

				local descLabel = Instance.new("TextLabel")
				descLabel.Size = compactToolCards and UDim2.new(1, -36, 0, 44) or UDim2.new(1, -178, 0, 44)
				descLabel.Position = compactToolCards and UDim2.new(0, 18, 0, 62) or UDim2.new(0, 18, 0, 46)
				descLabel.BackgroundTransparency = 1
				descLabel.TextColor3 = COLORS.SubText
				descLabel.TextSize = 12
				descLabel.Font = Enum.Font.GothamMedium
				descLabel.TextWrapped = true
				descLabel.TextXAlignment = Enum.TextXAlignment.Left
				descLabel.TextYAlignment = Enum.TextYAlignment.Top
				descLabel.Text = tostring(tool.Description or "")
				descLabel.ZIndex = 355
				descLabel.Parent = card

				local effectLabel = Instance.new("TextLabel")
				effectLabel.Size = compactToolCards and UDim2.new(1, -36, 0, 32) or UDim2.new(1, -178, 0, 34)
				effectLabel.Position = compactToolCards and UDim2.new(0, 18, 0, 108) or UDim2.new(0, 18, 0, 96)
				effectLabel.BackgroundTransparency = 1
				effectLabel.TextColor3 = color
				effectLabel.TextSize = 12
				effectLabel.Font = Enum.Font.GothamBlack
				effectLabel.TextWrapped = true
				effectLabel.TextXAlignment = Enum.TextXAlignment.Left
				effectLabel.Text = tostring(tool.EffectText or "")
				effectLabel.ZIndex = 355
				effectLabel.Parent = card

				local b = Instance.new("TextButton")
				b.Size = compactToolCards and UDim2.new(1, -36, 0, 28) or UDim2.new(0, 122, 0, 38)
				b.Position = compactToolCards and UDim2.new(0, 18, 1, -38) or UDim2.new(1, -140, 0.5, -19)
				b.BackgroundColor3 = tool.Equipped and COLORS.Red or COLORS.Purple
				b.BorderSizePixel = 0
				b.TextColor3 = COLORS.Text
				b.TextSize = 12
				b.Font = Enum.Font.GothamBlack
				b.Text = tool.Equipped and "UNEQUIP" or "EQUIP"
				b.AutoButtonColor = false
				b.ZIndex = 356
				b.Parent = card
				addCorner(b, 7)
				addStroke(b, Color3.fromRGB(60, 60, 75), 1)
				setButtonTween(b, lighten(b.BackgroundColor3, 20))
				b.MouseButton1Click:Connect(function()
					fireAssetAction(tool.Equipped and "UnequipCursedTool" or "EquipCursedTool", tool.Id)
				end)
				yieldForLargeAssetLists()
			end
		end

		makeHeader("Cursed Tool Catalog")
		local catalog = currentData.CursedToolCatalog or {}
		if #catalog <= 0 then
			makeEmptyCard("Cursed tool catalog data is not available yet.")
		else
			for _, tool in ipairs(catalog) do
				local color = rarityColor(tool.Rarity)
				local card = Instance.new("Frame")
				card.Size = UDim2.new(1, -10, 0, compactToolCards and 138 or 118)
				card.BackgroundColor3 = tool.Owned and COLORS.Card or Color3.fromRGB(18, 18, 24)
				card.BorderSizePixel = 0
				card.ZIndex = 354
				card.Parent = scroll
				addCorner(card, 8)
				addStroke(card, tool.Owned and color or COLORS.Stroke, tool.Owned and 2 or 1)

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = compactToolCards and UDim2.new(1, -36, 0, 24) or UDim2.new(1, -178, 0, 24)
				nameLabel.Position = UDim2.new(0, 18, 0, 12)
				nameLabel.BackgroundTransparency = 1
				nameLabel.TextColor3 = tool.Owned and COLORS.Text or COLORS.SubText
				nameLabel.TextSize = 16
				nameLabel.Font = Enum.Font.GothamBlack
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
				nameLabel.Text = tostring(tool.Name or "Cursed Tool")
				nameLabel.ZIndex = 355
				nameLabel.Parent = card

				local statusLabel = Instance.new("TextLabel")
				statusLabel.Size = compactToolCards and UDim2.new(1, -36, 0, 18) or UDim2.new(0, 150, 0, 22)
				statusLabel.Position = compactToolCards and UDim2.new(0, 18, 0, 36) or UDim2.new(1, -168, 0, 14)
				statusLabel.BackgroundTransparency = 1
				statusLabel.TextColor3 = tool.Owned and COLORS.Green or COLORS.SubText
				statusLabel.TextSize = 12
				statusLabel.Font = Enum.Font.GothamBlack
				statusLabel.TextXAlignment = compactToolCards and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
				statusLabel.Text = tool.Owned and "OWNED" or "LOCKED"
				statusLabel.ZIndex = 355
				statusLabel.Parent = card

				local rarityLabel = Instance.new("TextLabel")
				rarityLabel.Size = UDim2.new(1, -36, 0, 20)
				rarityLabel.Position = compactToolCards and UDim2.new(0, 18, 0, 58) or UDim2.new(0, 18, 0, 38)
				rarityLabel.BackgroundTransparency = 1
				rarityLabel.TextColor3 = color
				rarityLabel.TextSize = 12
				rarityLabel.Font = Enum.Font.GothamBlack
				rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
				rarityLabel.TextTruncate = Enum.TextTruncate.AtEnd
				rarityLabel.Text = tostring(tool.Rarity or "Common") .. " • " .. tostring(tool.Type or "Tool") .. " • Drop weight " .. tostring(tool.DropWeight or "?")
				rarityLabel.ZIndex = 355
				rarityLabel.Parent = card

				local effectLabel = Instance.new("TextLabel")
				effectLabel.Size = UDim2.new(1, -36, 0, 44)
				effectLabel.Position = compactToolCards and UDim2.new(0, 18, 0, 84) or UDim2.new(0, 18, 0, 64)
				effectLabel.BackgroundTransparency = 1
				effectLabel.TextColor3 = tool.Owned and COLORS.Text or COLORS.SubText
				effectLabel.TextSize = 12
				effectLabel.Font = Enum.Font.GothamMedium
				effectLabel.TextWrapped = true
				effectLabel.TextXAlignment = Enum.TextXAlignment.Left
				effectLabel.TextYAlignment = Enum.TextYAlignment.Top
				effectLabel.Text = tostring(tool.EffectText or tool.Description or "")
				effectLabel.ZIndex = 355
				effectLabel.Parent = card
				yieldForLargeAssetLists()
			end
		end
	end

	-------------------------------------------------- SHOP
	if currentTab == "Shop" then
		makeHeader("Shop")
		local shop = currentData.Shop or {}
		if #shop <= 0 then
			makeEmptyCard("The shop has no available assets.")
		else
			local bulkCard = makeCard(104)
			makeLabel(bulkCard, "Bulk Asset Purchase", 16, COLORS.Text, UDim2.new(0, 18, 0, 14), UDim2.new(1, -178, 0, 24), true)
			makeLabel(bulkCard, "Buy up to 5 cheapest affordable unowned assets at once. Grand Dojo is excluded so clan progression stays intentional.", 12, COLORS.SubText, UDim2.new(0, 18, 0, 42), UDim2.new(1, -190, 0, 46), false)
			local playerAge = tonumber(currentData.Age) or 0
			local bulkButton = makeButton(bulkCard, playerAge < 16 and "AGE 16+" or "BULK BUY", playerAge < 16 and COLORS.Button or COLORS.Green, 0, 0, 132, 38, function()
				if playerAge >= 16 then
					preserveScrollOnNextRefresh = true
					fireAssetAction("BulkBuyAffordable", "sealed_charm")
				end
			end)
			bulkButton.Position = UDim2.new(1, -150, 0.5, -19)
			for _, asset in ipairs(shop) do
				local card = Instance.new("Frame")
				card.Size = UDim2.new(1, -10, 0, 132)
				card.BackgroundColor3 = COLORS.Card
				card.BorderSizePixel = 0
				card.ZIndex = 354
				card.Parent = scroll
				addCorner(card, 8)
				addStroke(card, COLORS.Stroke, 1)

				local color = rarityColor(asset.Rarity)

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = UDim2.new(1, -170, 0, 24)
				nameLabel.Position = UDim2.new(0, 18, 0, 14)
				nameLabel.BackgroundTransparency = 1
				nameLabel.TextColor3 = COLORS.Text
				nameLabel.TextSize = 17
				nameLabel.Font = Enum.Font.GothamBlack
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.Text = tostring(asset.Name or "Unknown Asset")
				nameLabel.ZIndex = 355
				nameLabel.Parent = card

				local priceLabel = Instance.new("TextLabel")
				priceLabel.Size = UDim2.new(0, 140, 0, 22)
				priceLabel.Position = UDim2.new(1, -158, 0, 16)
				priceLabel.BackgroundTransparency = 1
				priceLabel.TextColor3 = COLORS.Green
				priceLabel.TextSize = 13
				priceLabel.Font = Enum.Font.GothamBlack
				priceLabel.TextXAlignment = Enum.TextXAlignment.Right
				priceLabel.Text = "$" .. tostring(asset.Price or 0)
				priceLabel.ZIndex = 355
				priceLabel.Parent = card

				local typeLabel = Instance.new("TextLabel")
				typeLabel.Size = UDim2.new(1, -178, 0, 18)
				typeLabel.Position = UDim2.new(0, 18, 0, 42)
				typeLabel.BackgroundTransparency = 1
				typeLabel.TextColor3 = color
				typeLabel.TextSize = 12
				typeLabel.Font = Enum.Font.GothamBlack
				typeLabel.TextXAlignment = Enum.TextXAlignment.Left
				typeLabel.Text = tostring(asset.Rarity or "Common") .. " • " .. tostring(asset.Type or "Asset")
				typeLabel.ZIndex = 355
				typeLabel.Parent = card

				local descLabel = Instance.new("TextLabel")
				descLabel.Size = UDim2.new(1, -178, 0, 42)
				descLabel.Position = UDim2.new(0, 18, 0, 64)
				descLabel.BackgroundTransparency = 1
				descLabel.TextColor3 = Color3.fromRGB(185, 185, 195)
				descLabel.TextSize = 12
				descLabel.Font = Enum.Font.GothamMedium
				descLabel.TextWrapped = true
				descLabel.TextXAlignment = Enum.TextXAlignment.Left
				descLabel.TextYAlignment = Enum.TextYAlignment.Top
				descLabel.Text = tostring(asset.Description or "")
				descLabel.ZIndex = 355
				descLabel.Parent = card

				local playerAge = tonumber(currentData.Age) or 0
				local buyText   = playerAge < 16 and "ASK PARENT" or "BUY"
				local actionId  = playerAge < 16 and "AskParent"  or "Buy"

				local b = Instance.new("TextButton")
				b.Size = UDim2.new(0, 122, 0, 38)
				b.Position = UDim2.new(1, -140, 0.5, -19)
				b.BackgroundColor3 = COLORS.Accent
				b.BorderSizePixel = 0
				b.TextColor3 = COLORS.Text
				b.TextSize = 12
				b.Font = Enum.Font.GothamBlack
				b.Text = buyText
				b.AutoButtonColor = false
				b.ZIndex = 356
				b.Parent = card
				addCorner(b, 7)
				addStroke(b, Color3.fromRGB(60, 60, 75), 1)
				setButtonTween(b, lighten(COLORS.Accent, 20))
				b.MouseButton1Click:Connect(function()
					fireAssetAction(actionId, asset.Id)
				end)
				yieldForLargeAssetLists()
			end
		end
	end

	-------------------------------------------------- DOJO
	if currentTab == "Dojo" then
		if dojoSubPage == "JoinedDojo" then
			buildJoinedDojoMenu(currentData)
		else
			makeHeader("Grand Dojo")

			if not currentData.HasGrandDojo then
				local card = makeCard(190)
				addStroke(card, COLORS.GoldStroke, 1)
				makeLabel(card, "No Grand Dojo Owned", 21, COLORS.Text,
					UDim2.new(0, 20, 0, 18), UDim2.new(1, -40, 0, 30), true)
				makeLabel(card,
					"Buy the Grand Dojo from the shop for $25,000 to found a clan, recruit students, and build your own sorcerer school.",
					13, COLORS.SubText, UDim2.new(0, 20, 0, 58), UDim2.new(1, -200, 0, 74), false)
				makeRightButton(card, "GO SHOP", COLORS.Gold, 76, function()
					setTab("Shop")
					refreshAssets()
				end)
				buildOutsideDojoCard(currentData)

			elseif not currentData.ClanFounded then
				local card = makeCard(260)
				addStroke(card, COLORS.GoldStroke, 1)
				makeLabel(card, "Clan Name Setup", 21, COLORS.Text,
					UDim2.new(0, 20, 0, 18), UDim2.new(1, -40, 0, 30), true)
				makeLabel(card, "Current Name: " .. tostring(currentData.FamilyName or "Unnamed") .. " Clan", 13, COLORS.Gold,
					UDim2.new(0, 20, 0, 54), UDim2.new(1, -40, 0, 20), true)

				local tb = Instance.new("TextBox")
				tb.Size = UDim2.new(1, -40, 0, 44)
				tb.Position = UDim2.new(0, 20, 0, 86)
				tb.BackgroundColor3 = COLORS.CardDark
				tb.BorderSizePixel = 0
				tb.TextColor3 = COLORS.Text
				tb.PlaceholderColor3 = COLORS.Muted
				tb.TextSize = 16
				tb.Font = Enum.Font.GothamBlack
				tb.TextXAlignment = Enum.TextXAlignment.Left
				tb.ClearTextOnFocus = false
				tb.Text = tostring(currentData.FamilyName or "Unnamed") .. " Clan"
				tb.ZIndex = 356
				tb.Parent = card
				addCorner(tb, 10)
				addStroke(tb, COLORS.Stroke, 1)
				addPadding(tb, 0, 12, 0, 12)

				makeLabel(card,
					"Confirm the clan name first. After that, the game will ask if you want your player's last name to match the clan.",
					12, COLORS.SubText, UDim2.new(0, 20, 0, 144), UDim2.new(1, -40, 0, 42), false)
				makeButton(card, "CONFIRM CLAN", COLORS.Gold, 20, 204, 180, 38, function()
					local clanName = sanitizeActionText(tb.Text)
					if clanName == "" then
						clanName = tostring(currentData.FamilyName or "Unnamed") .. " Clan"
					end
					fireAssetAction("ConfirmClanName|" .. clanName, "grand_dojo")
					dojoSubPage = "Recruit"
				end)

			elseif currentData.DojoPendingLastNameChoice then
				local card = makeCard(220)
				addStroke(card, COLORS.GoldStroke, 1)
				makeLabel(card, "Change Last Name?", 21, COLORS.Text,
					UDim2.new(0, 20, 0, 18), UDim2.new(1, -40, 0, 30), true)
				makeLabel(card,
					"Your clan is <b>" .. tostring(currentData.PlayerClanName or "Unnamed Clan") .. "</b>. Do you want your player's family name to match it?",
					13, COLORS.SubText, UDim2.new(0, 20, 0, 58), UDim2.new(1, -40, 0, 72), false)
				makeButton(card, "YES, CHANGE IT", COLORS.Green, 20,  154, 160, 38, function()
					fireAssetAction("ChangePlayerLastName", "grand_dojo")
				end)
				makeButton(card, "NO, KEEP MINE",  COLORS.Red,   192, 154, 160, 38, function()
					fireAssetAction("KeepPlayerLastName", "grand_dojo")
				end)

			else
				dojoSummaryBlock(currentData)

				if dojoSubPage == "Overview" then
					local upgradeCost = tonumber(currentData.DojoUpgradeCost)
					local upgradeCard = makeCard(122)
					addStroke(upgradeCard, COLORS.StrokeSoft, 1)
					makeLabel(upgradeCard, "Upgrade Grand Dojo", 18, COLORS.Text,
						UDim2.new(0, 20, 0, 16), UDim2.new(1, -210, 0, 26), true)
					local upgradeText = upgradeCost and ("Spend $" .. tostring(upgradeCost) .. " to raise the dojo level, condition, prestige, reputation, and student capacity.") or "Your Grand Dojo is already at the maximum level."
					makeLabel(upgradeCard, upgradeText, 12, COLORS.SubText,
						UDim2.new(0, 20, 0, 50), UDim2.new(1, -210, 0, 44), false)
					makeRightButton(upgradeCard, upgradeCost and "UPGRADE" or "MAX", upgradeCost and COLORS.Gold or COLORS.Button, 42, function()
						if upgradeCost then
							fireAssetAction("UpgradeDojo", "grand_dojo")
						end
					end)
					buildDojoHomeCards(currentData)
					buildDojoActivityFeed(currentData)

				elseif dojoSubPage == "Students" then
					makeHeader("Students")
					buildDojoBackCard("Back to Dojo Actions. Use the action board to switch between Manage, Recruit, and Train.")
					local students = currentData.DojoStudents or {}
					if #students <= 0 then
						local card = makeCard(138)
						makeLabel(card, "No students yet.", 18, COLORS.Text,
							UDim2.new(0, 20, 0, 18), UDim2.new(1, -190, 0, 26), true)
						makeLabel(card, "Recruit up to 3 starting students from the recruit board first.",
							13, COLORS.SubText, UDim2.new(0, 20, 0, 52), UDim2.new(1, -190, 0, 48), false)
						makeRightButton(card, "RECRUIT", COLORS.Green, 48, function() setDojoPage("Recruit") end)
					else
						for index, student in ipairs(students) do
							buildStudentCard(index, student)
						end
					end

				elseif dojoSubPage == "Recruit" then
					makeHeader("Recruit Students")
					buildDojoBackCard("Back to Dojo Actions. Recruitment stays separate so the page does not trap you here.")
					local used       = tonumber(currentData.DojoStarterRecruitsUsed) or 0
					local limit      = tonumber(currentData.DojoStarterRecruitLimit) or 3
					local candidates = currentData.DojoRecruitPool or {}

					local intro = makeCard(112)
					makeLabel(intro, "Choose " .. tostring(limit) .. " out of 10 candidates", 18, COLORS.Text,
						UDim2.new(0, 20, 0, 16), UDim2.new(1, -220, 0, 26), true)
					makeLabel(intro, "No dropdowns. Just question, examine, or recruit from the card.", 12, COLORS.SubText,
						UDim2.new(0, 20, 0, 48), UDim2.new(1, -220, 0, 38), false)
					makeRightButton(intro, tostring(used) .. " / " .. tostring(limit), COLORS.Button, 38, nil)

					if used >= limit then
						local done = makeCard(110)
						makeLabel(done, "Starting recruitment complete.", 17, COLORS.Gold,
							UDim2.new(0, 20, 0, 18), UDim2.new(1, -40, 0, 24), true)
						makeLabel(done, "You used all your starter slots. Future dojo upgrades can unlock more recruitment later.",
							12, COLORS.SubText, UDim2.new(0, 20, 0, 52), UDim2.new(1, -40, 0, 42), false)
					elseif #candidates <= 0 then
						local empty = makeCard(146)
						makeLabel(empty, "No recruit list yet.", 17, COLORS.Text,
							UDim2.new(0, 20, 0, 18), UDim2.new(1, -190, 0, 26), true)
						makeLabel(empty, "Generate 10 possible students for your Grand Dojo.", 12, COLORS.SubText,
							UDim2.new(0, 20, 0, 52), UDim2.new(1, -190, 0, 38), false)
						makeRightButton(empty, "GENERATE", COLORS.Gold, 52, function()
							fireAssetAction("GenerateRecruitPool", "grand_dojo")
						end)
					else
						local featured = candidates[1]
						if featured then
							makeHeader("Featured Candidate")
							local featureCard = makeCard(132)
							addStroke(featureCard, COLORS.GoldStroke, 1)
							makeInitialBadge(featureCard, featured, 20, 18, COLORS.Gold)
							makeLabel(featureCard, tostring(featured.Name or "Unknown"), 20, COLORS.Text,
								UDim2.new(0, 88, 0, 16), UDim2.new(1, -250, 0, 28), true)
							makeLabel(featureCard,
								tostring(featured.Grade or "Non-Sorcerer") .. "  •  " .. tostring(featured.DojoPotential or "Unknown") .. " Potential",
								12, COLORS.Gold, UDim2.new(0, 88, 0, 48), UDim2.new(1, -250, 0, 18), true)
							makeTraitPills(featureCard, getProfileTraits(featured), 88, 76)
							makeRightButton(featureCard, "VIEW BELOW", COLORS.Gold, 48, nil)
						end
						makeHeader("Candidate Board")
						for index, candidate in ipairs(candidates) do
							buildCandidateCard(index, candidate, limit, used)
						end
					end

				elseif dojoSubPage == "Training" then
					makeHeader("Training")
					buildDojoBackCard("Back to Dojo Actions. Training is no longer the only visible navigation path.")
					local focusOptions = {
						{ "Balanced",    "Even growth across bond, trust, respect, and cursed energy.",        COLORS.Button },
						{ "Combat",      "More cursed energy and grade growth, with harder sessions.",         COLORS.Red    },
						{ "Discipline",  "More respect and trust through strict structure.",                   COLORS.Gold   },
						{ "Theory",      "Better cursed energy control and technique growth.",                 COLORS.Purple },
						{ "Loyalty",     "More bond, trust, and clan reputation.",                             COLORS.Green  },
					}

					for _, focusData in ipairs(focusOptions) do
						local focusName = focusData[1]
						local selected  = tostring(currentData.DojoFocus or "Balanced") == focusName
						local card = makeCard(94)
						for _, c in ipairs(card:GetChildren()) do
							if c:IsA("UIStroke") then c:Destroy() end
						end
						addStroke(card, selected and COLORS.Gold or COLORS.Stroke, selected and 2 or 1)
						makeLabel(card, focusName, 17, selected and COLORS.Gold or COLORS.Text,
							UDim2.new(0, 20, 0, 14), UDim2.new(1, -190, 0, 24), true)
						makeLabel(card, focusData[2], 12, COLORS.SubText,
							UDim2.new(0, 20, 0, 44), UDim2.new(1, -190, 0, 34), false)
						makeRightButton(card, selected and "ACTIVE" or "SELECT", focusData[3], 30, function()
							if not selected then
								fireAssetAction("SetFocus_" .. focusName, "grand_dojo")
							end
						end)
					end

					local trainCard = makeCard(118)
					makeLabel(trainCard, "Run Training Session", 18, COLORS.Text,
						UDim2.new(0, 20, 0, 16), UDim2.new(1, -190, 0, 26), true)
					makeLabel(trainCard,
						"Preview: +student growth, +clan reputation, possible CE/mastery gains. Cost: dojo condition and time.",
						12, COLORS.SubText, UDim2.new(0, 20, 0, 50), UDim2.new(1, -190, 0, 40), false)
					makeRightButton(trainCard, "TRAIN", COLORS.Purple, 42, function()
						fireAssetAction("TrainStudents", "grand_dojo")
					end)

				elseif dojoSubPage == "JoinedDojo" then
					buildJoinedDojoMenu(currentData)

				elseif dojoSubPage == "Settings" then
					makeHeader("Clan Settings")
					buildDojoBackCard("Back to Dojo Actions.")
					local card = makeCard(158)
					makeLabel(card, "Clan Identity", 18, COLORS.Text,
						UDim2.new(0, 20, 0, 16), UDim2.new(1, -40, 0, 26), true)
					makeLabel(card,
						"<b>Clan:</b> " .. tostring(currentData.PlayerClanName or "Unknown") ..
							"\n<b>Founder:</b> " .. tostring(currentData.DojoFounderName or "Unknown") ..
							"\n<b>Family Name:</b> " .. tostring(currentData.FamilyName or "Unknown") ..
							"\n<b>Focus:</b> " .. tostring(currentData.DojoFocus or "Balanced"),
						12, COLORS.SubText, UDim2.new(0, 20, 0, 50), UDim2.new(1, -40, 0, 90), false)
				end
			end
		end
	end

	task.defer(function()
		task.wait()
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
		if shouldPreserve then
			local maxY = math.max(0, layout.AbsoluteContentSize.Y - scroll.AbsoluteWindowSize.Y + 16)
			scroll.CanvasPosition = Vector2.new(restorePos.X, math.clamp(restorePos.Y, 0, maxY))
		else
			scroll.CanvasPosition = Vector2.new(0, 0)
		end
	end)
end

----------------------------------------------------------------
-- HIDE OTHER MENUS
----------------------------------------------------------------
local function hideOtherMenusForAssets()
	local coreOverlay = bitKaisenGui:FindFirstChild("OverlayPanel")
	if coreOverlay then
		coreOverlay.Visible = false
		local missionWindow      = coreOverlay:FindFirstChild("MissionWindow")
		local activityWindow     = coreOverlay:FindFirstChild("ActivityWindow")
		local settingsWindow     = coreOverlay:FindFirstChild("SettingsWindow")
		if missionWindow  then missionWindow.Visible  = false end
		if activityWindow then activityWindow.Visible = false end
		if settingsWindow then settingsWindow.Visible = false end
	end

	local relationshipsOverlay = bitKaisenGui:FindFirstChild("RelationshipsOverlay")
	if relationshipsOverlay then
		relationshipsOverlay.Visible = false
		local relationshipsWindow = relationshipsOverlay:FindFirstChild("RelationshipsWindow")
		if relationshipsWindow then relationshipsWindow.Visible = false end
	end
end

local function closeWindowInstant()
	if not isOpen and not overlay.Visible then return end
	hideExamine()
	isOpen = false
	busy   = false
	overlay.Visible = false
	window.Visible  = false
end

----------------------------------------------------------------
-- OPEN / CLOSE
----------------------------------------------------------------
local function openWindow()
	if isOpen or busy then return end
	hideOtherMenusForAssets()
	busy   = true
	isOpen = true
	setTab(currentTab)
	refreshAssets()

	restoreAssetTabs()
	overlay.Visible = true
	window.Visible  = true
	overlay.BackgroundTransparency = 1
	window.BackgroundTransparency  = 1
	window.Position = UDim2.new(0.5, 0, 0.55, 0)

	TweenService:Create(overlay, TweenInfo.new(0.22), {BackgroundTransparency = 0.45}):Play()
	TweenService:Create(window, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0)
	}):Play()

	task.delay(0.25, function() busy = false end)
end

local function closeWindow()
	if not isOpen or busy then return end
	hideExamine()
	busy   = true
	isOpen = false

	TweenService:Create(overlay, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
	TweenService:Create(window, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.55, 0)
	}):Play()

	task.delay(0.19, function()
		if not isOpen then
			overlay.Visible = false
			window.Visible  = false
		end
		busy = false
	end)
end

----------------------------------------------------------------
-- WIRING
----------------------------------------------------------------
tabs.Owned.MouseButton1Click:Connect(function() setTab("Owned"); refreshAssets() end)
tabs.Shop.MouseButton1Click:Connect(function()  setTab("Shop");  refreshAssets() end)
tabs.Dojo.MouseButton1Click:Connect(function()  setTab("Dojo");  refreshAssets() end)

local function closeAssetsBeforeOtherMenu()
	closeWindowInstant()
end

if missionsButton      then missionsButton.MouseButton1Click:Connect(closeAssetsBeforeOtherMenu)      end
if activitiesButton    then activitiesButton.MouseButton1Click:Connect(closeAssetsBeforeOtherMenu)    end
if relationshipsButton then relationshipsButton.MouseButton1Click:Connect(closeAssetsBeforeOtherMenu) end

task.defer(function()
	local menuButton = mainPanel:FindFirstChild("MainMenuButton")
	if menuButton then
		menuButton.MouseButton1Click:Connect(closeAssetsBeforeOtherMenu)
	end
end)

navPanel.ChildAdded:Connect(function(child)
	if child.Name == "RELATIONSHIPSButton" then
		relationshipsButton = child
		child.MouseButton1Click:Connect(closeAssetsBeforeOtherMenu)
	end
end)

if assetsButton then
	assetsButton.MouseButton1Click:Connect(openWindow)
end
closeButton.MouseButton1Click:Connect(closeWindow)

assetAction.OnClientEvent:Connect(function()
	preserveScrollOnNextRefresh = true
	if isOpen then refreshAssets() end
end)
