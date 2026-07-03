local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local uiState = require("@ui-state/uiState")
local responsiveScale = require("@ui/responsiveScale")
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _bm(key, fallback) return BitKaisenLocale.tOrFallback(_L, "black_market." .. key, nil, fallback) end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function formatMoneyAmount(value)
	value = math.floor((tonumber(value) or 0) * 100 + 0.5) / 100
	if value % 1 == 0 then
		return tostring(math.floor(value))
	end
	return string.format("%.2f", value)
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

local getBlackMarket = ReplicatedStorage:WaitForChild("GetBlackMarket")
local blackMarketAction = ReplicatedStorage:WaitForChild("BlackMarketAction")

----------------------------------------------------------------
-- THEME
----------------------------------------------------------------
local COLORS = {
	Window      = Color3.fromRGB(15, 15, 22),
	Card        = Color3.fromRGB(22, 22, 30),
	CardHover   = Color3.fromRGB(28, 28, 38),
	Stroke      = Color3.fromRGB(48, 48, 64),
	Text        = Color3.fromRGB(235, 235, 245),
	SubText     = Color3.fromRGB(165, 165, 185),
	Muted       = Color3.fromRGB(110, 110, 130),
	Green       = Color3.fromRGB(120, 240, 160),
	Gold        = Color3.fromRGB(255, 200, 90),
	Red         = Color3.fromRGB(210, 70, 80),
	Bad         = Color3.fromRGB(230, 75, 90),
	Button      = Color3.fromRGB(31, 31, 42),
	ButtonHover = Color3.fromRGB(44, 44, 58),
	Accent      = Color3.fromRGB(90, 40, 100),
	AccentStroke = Color3.fromRGB(120, 45, 130),
}

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------
local busy = false
local isOpen = false
local currentTab = "BuyTools"
local currentData = nil

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

local function lighten(c, amount)
	return Color3.fromRGB(
		math.clamp(c.R * 255 + amount, 0, 255),
		math.clamp(c.G * 255 + amount, 0, 255),
		math.clamp(c.B * 255 + amount, 0, 255)
	)
end

local function setButtonTween(button, hoverColor)
	local baseColor = button.BackgroundColor3
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = hoverColor }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = baseColor }):Play()
	end)
end

----------------------------------------------------------------
-- SCREENGUI
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenBlackMarketGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 623
gui.Enabled = false
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "BlackMarketOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.Visible = false
overlay.ZIndex = 620
overlay.Parent = gui

local window = Instance.new("Frame")
window.Name = "BlackMarketWindow"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.BackgroundColor3 = COLORS.Window
window.BackgroundTransparency = 1
window.BorderSizePixel = 0
window.Visible = false
window.ZIndex = 621
window.Parent = overlay
addCorner(window, 12)
addStroke(window, COLORS.AccentStroke, 1)

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -100, 0, 38)
title.Position = UDim2.new(0, 28, 0, 16)
title.BackgroundTransparency = 1
title.TextColor3 = COLORS.Text
title.TextSize = 24
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = _bm("title", "BLACK MARKET")
title.ZIndex = 622
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
subtitle.Text = _bm("subtitle", "Buy and sell illegal cursed tools and contraband curse items.")
subtitle.ZIndex = 622
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
closeButton.ZIndex = 623
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
moneyLabel.Text = _bm("money_label", "Money: $") .. "0"
moneyLabel.ZIndex = 622
moneyLabel.Parent = window

local wantedLabel = Instance.new("TextLabel")
wantedLabel.Size = UDim2.new(0.46, 0, 0, 22)
wantedLabel.Position = UDim2.new(0.49, 0, 0, 76)
wantedLabel.BackgroundTransparency = 1
wantedLabel.TextColor3 = COLORS.Bad
wantedLabel.TextSize = 13
wantedLabel.Font = Enum.Font.GothamBlack
wantedLabel.TextXAlignment = Enum.TextXAlignment.Right
wantedLabel.Text = _bm("wanted_label", "Wanted Level: ") .. "0"
wantedLabel.ZIndex = 622
wantedLabel.Parent = window

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
actionStatusLabel.ZIndex = 622
actionStatusLabel.Parent = window

local function setActionStatus(text, color)
	actionStatusLabel.Text = text or ""
	actionStatusLabel.TextColor3 = color or COLORS.Muted
end

----------------------------------------------------------------
-- TABS
----------------------------------------------------------------
local tabHolder = Instance.new("Frame")
tabHolder.Name = "BlackMarketTabs"
tabHolder.Size = UDim2.new(1, -56, 0, 36)
tabHolder.Position = UDim2.new(0, 28, 0, 106)
tabHolder.BackgroundTransparency = 1
tabHolder.ZIndex = 622
tabHolder.Parent = window

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 8)
tabLayout.Parent = tabHolder

local tabs = {}
local TAB_NAMES = { "BuyTools", "BuyItems", "SellTools" }
local TAB_LABELS = { BuyTools = _bm("tab_buy_tools","BUY TOOLS"), BuyItems = _bm("tab_buy_items","BUY ITEMS"), SellTools = _bm("tab_sell_tools","SELL TOOLS") }

local function makeTab(name, order)
	local b = Instance.new("TextButton")
	b.Name = name .. "Tab"
	b.Size = UDim2.new(0.333, -6, 1, 0)
	b.BackgroundColor3 = COLORS.Button
	b.BorderSizePixel = 0
	b.TextColor3 = COLORS.SubText
	b.TextSize = 13
	b.Font = Enum.Font.GothamBlack
	b.Text = string.upper(TAB_LABELS[name])
	b.AutoButtonColor = false
	b.LayoutOrder = order
	b.ZIndex = 623
	b.Parent = tabHolder
	addCorner(b, 7)
	addStroke(b, Color3.fromRGB(48, 48, 64), 1)
	setButtonTween(b, COLORS.ButtonHover)
	tabs[name] = b
	return b
end

for i, name in ipairs(TAB_NAMES) do
	makeTab(name, i)
end

local refresh

local function setTab(tabName)
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

for name, b in pairs(tabs) do
	b.MouseButton1Click:Connect(function()
		setTab(name)
		refresh()
	end)
end

----------------------------------------------------------------
-- SCROLL AREA
----------------------------------------------------------------
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "BlackMarketScroll"
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
scroll.ZIndex = 622
scroll.Parent = window

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Padding = UDim.new(0, 10)
scrollLayout.Parent = scroll

scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 16)
end)

responsiveScale.attach(window, 1152, 800)

local function clearCards()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

----------------------------------------------------------------
-- CARD BUILDERS
----------------------------------------------------------------
local function makeEmptyCard(text)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -10, 0, 90)
	card.BackgroundColor3 = COLORS.Card
	card.BorderSizePixel = 0
	card.ZIndex = 624
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
	label.ZIndex = 625
	label.Parent = card
end

local function makeGoodsCard(name, priceText, priceColor, tagText, desc, buttonText, buttonColor, buttonEnabled, callback)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -10, 0, 132)
	card.BackgroundColor3 = COLORS.Card
	card.BorderSizePixel = 0
	card.ZIndex = 624
	card.Parent = scroll
	addCorner(card, 8)
	addStroke(card, COLORS.Stroke, 1)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -170, 0, 24)
	nameLabel.Position = UDim2.new(0, 18, 0, 14)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextSize = 17
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = tostring(name)
	nameLabel.ZIndex = 625
	nameLabel.Parent = card

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0, 140, 0, 22)
	priceLabel.Position = UDim2.new(1, -158, 0, 16)
	priceLabel.BackgroundTransparency = 1
	priceLabel.TextColor3 = priceColor or COLORS.Green
	priceLabel.TextSize = 13
	priceLabel.Font = Enum.Font.GothamBlack
	priceLabel.TextXAlignment = Enum.TextXAlignment.Right
	priceLabel.Text = priceText
	priceLabel.ZIndex = 625
	priceLabel.Parent = card

	local tagLabel = Instance.new("TextLabel")
	tagLabel.Size = UDim2.new(1, -178, 0, 18)
	tagLabel.Position = UDim2.new(0, 18, 0, 42)
	tagLabel.BackgroundTransparency = 1
	tagLabel.TextColor3 = COLORS.Gold
	tagLabel.TextSize = 12
	tagLabel.Font = Enum.Font.GothamBlack
	tagLabel.TextXAlignment = Enum.TextXAlignment.Left
	tagLabel.Text = tagText or ""
	tagLabel.ZIndex = 625
	tagLabel.Parent = card

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
	descLabel.Text = tostring(desc or "")
	descLabel.ZIndex = 625
	descLabel.Parent = card

	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 122, 0, 38)
	b.Position = UDim2.new(1, -140, 0.5, -19)
	b.BackgroundColor3 = buttonEnabled and buttonColor or COLORS.Button
	b.BorderSizePixel = 0
	b.TextColor3 = buttonEnabled and COLORS.Text or COLORS.Muted
	b.TextSize = 12
	b.Font = Enum.Font.GothamBlack
	b.Text = buttonText
	b.AutoButtonColor = false
	b.ZIndex = 626
	b.Parent = card
	addCorner(b, 7)
	addStroke(b, Color3.fromRGB(60, 60, 75), 1)
	if buttonEnabled then
		setButtonTween(b, lighten(buttonColor, 20))
		b.MouseButton1Click:Connect(callback)
	end

	return card
end

----------------------------------------------------------------
-- SERVER ACTION FIRER
----------------------------------------------------------------
local function fireBlackMarketAction(actionId, targetId)
	if busy then
		setActionStatus("Please wait...", COLORS.Gold)
		return
	end

	busy = true
	setActionStatus("Processing...", COLORS.Gold)
	blackMarketAction:FireServer(actionId, targetId)

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
-- TAB CONTENT
----------------------------------------------------------------
local function buildBuyToolsTab(data)
	local catalog = data.ToolCatalog or {}
	if #catalog <= 0 then
		makeEmptyCard("No exclusive cursed tools are available right now.")
		return
	end

	for _, tool in ipairs(catalog) do
		local color = rarityColor(tool.Rarity)
		makeGoodsCard(
			tool.Name or "Unknown Tool",
			"$" .. tostring(tool.BlackMarketPrice or 0),
			COLORS.Green,
			tostring(tool.Rarity or "Common") .. " • " .. tostring(tool.Type or "Cursed Tool"),
			tostring(tool.EffectText or tool.Description or ""),
			tool.Owned and "OWNED" or "BUY",
			color,
			not tool.Owned,
			function()
				fireBlackMarketAction("BuyTool", tool.Id)
			end
		)
	end
end

local function buildBuyItemsTab(data)
	local catalog = data.ItemCatalog or {}
	if #catalog <= 0 then
		makeEmptyCard("No illegal items are available right now.")
		return
	end

	for _, item in ipairs(catalog) do
		makeGoodsCard(
			item.Name or "Unknown Item",
			"$" .. tostring(item.Price or 0),
			COLORS.Green,
			_bm("tag_illegal", "Illegal Item • Single Use"),
			tostring(item.Description or ""),
			_bm("btn_buy_use", "BUY & USE"),
			COLORS.Accent,
			true,
			function()
				fireBlackMarketAction("BuyItem", item.Id)
			end
		)
	end
end

local function buildSellToolsTab(data)
	local owned = data.OwnedTools or {}
	if #owned <= 0 then
		makeEmptyCard("You do not own any cursed tools to sell.")
		return
	end

	for _, tool in ipairs(owned) do
		makeGoodsCard(
			tostring(tool.Name or "Cursed Tool") .. (tool.Equipped and "  [EQUIPPED]" or ""),
			"$" .. tostring(tool.SellValue or 0),
			COLORS.Gold,
			tostring(tool.Rarity or "Common") .. " • " .. tostring(tool.Type or "Tool"),
			tostring(tool.EffectText or tool.Description or ""),
			_bm("btn_sell", "SELL"),
			COLORS.Bad,
			true,
			function()
				fireBlackMarketAction("SellTool", tool.Id)
			end
		)
	end
end

----------------------------------------------------------------
-- MAIN REFRESH
----------------------------------------------------------------
refresh = function()
	local ok, data = pcall(function()
		return getBlackMarket:InvokeServer()
	end)

	clearCards()

	if not ok then
		warn("[BlackMarketPanel] Failed to load black market:", data)
		makeEmptyCard("Could not load the black market. Try again later.")
		return
	end

	currentData = data or {}

	moneyLabel.Text = _bm("money_label", "Money: $") .. formatMoneyAmount(currentData.Money or 0)
	wantedLabel.Text = _bm("wanted_label", "Wanted Level: ") .. tostring(currentData.WantedLevel or 0)

	if currentTab == "BuyTools" then
		buildBuyToolsTab(currentData)
	elseif currentTab == "BuyItems" then
		buildBuyItemsTab(currentData)
	elseif currentTab == "SellTools" then
		buildSellToolsTab(currentData)
	end
end

----------------------------------------------------------------
-- OPEN / CLOSE
----------------------------------------------------------------
local function openPanel()
	if isOpen or busy then return end
	busy = true
	isOpen = true
	setTab(currentTab)
	refresh()

	gui.Enabled = true
	overlay.Visible = true
	window.Visible = true
	overlay.BackgroundTransparency = 1
	window.BackgroundTransparency = 1
	window.Position = UDim2.new(0.5, 0, 0.55, 0)

	TweenService:Create(overlay, TweenInfo.new(0.22), { BackgroundTransparency = 0.45 }):Play()
	TweenService:Create(window, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}):Play()

	task.delay(0.25, function() busy = false end)
end

local function closePanel()
	if not isOpen then
		gui.Enabled = false
		return
	end
	busy = true
	isOpen = false

	TweenService:Create(overlay, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(window, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.55, 0),
	}):Play()

	task.delay(0.19, function()
		if not isOpen then
			overlay.Visible = false
			window.Visible = false
			gui.Enabled = false
		end
		busy = false
	end)
end

----------------------------------------------------------------
-- WIRING
----------------------------------------------------------------
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

blackMarketAction.OnClientEvent:Connect(function()
	if isOpen then refresh() end
end)

----------------------------------------------------------------
-- INIT
----------------------------------------------------------------
local function init()
	uiState.subscribe(function(route)
		if route == "blackmarket" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
