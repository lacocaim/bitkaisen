local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local uiState = require("@ui-state/uiState")
local responsiveScale = require("@ui/responsiveScale")
local BitKaisenCultData = require(ReplicatedStorage:WaitForChild("BitKaisenCultData"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function clampPercent(value)
	return math.clamp(math.floor(tonumber(value) or 0), 0, 100)
end

local getCult = ReplicatedStorage:WaitForChild("GetCult")
local cultAction = ReplicatedStorage:WaitForChild("CultAction")

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
	Gold        = Color3.fromRGB(200, 170, 90),
	Red         = Color3.fromRGB(210, 70, 80),
	Bad         = Color3.fromRGB(230, 75, 90),
	Button      = Color3.fromRGB(31, 31, 42),
	ButtonHover = Color3.fromRGB(44, 44, 58),
	Accent      = Color3.fromRGB(140, 20, 30),
	AccentStroke = Color3.fromRGB(170, 40, 50),
}

local ROLE_COLORS = {
	CultInitiate = Color3.fromRGB(190, 190, 205),
	CultDisciple = Color3.fromRGB(200, 170, 90),
	CultLieutenant = Color3.fromRGB(200, 70, 80),
}

local function roleColor(role)
	return ROLE_COLORS[tostring(role or "")] or Color3.fromRGB(190, 190, 205)
end

local FOCUS_NAMES = { "Fear", "Ritual", "Conversion" }

local ACTION_ORDER = {
	"Cult_RecruitInitiate",
	"Cult_BindingRitual",
	"Cult_CollectTribute",
	"Cult_ExpandTerritory",
	"Cult_ReviewMembers",
	"Cult_SupplyRun",
	"Cult_CurseFusion",
}

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------
local busy = false
local isOpen = false
local currentTab = "Overview"
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
gui.Name = "BitKaisenCultGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 629
gui.Enabled = false
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "CultOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.Visible = false
overlay.ZIndex = 620
overlay.Parent = gui

local window = Instance.new("Frame")
window.Name = "CultWindow"
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
title.Text = "CULT SANCTUM"
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
subtitle.Text = "Manage your cursed organization."
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

local cultNameLabel = Instance.new("TextLabel")
cultNameLabel.Size = UDim2.new(0.6, 0, 0, 22)
cultNameLabel.Position = UDim2.new(0, 29, 0, 76)
cultNameLabel.BackgroundTransparency = 1
cultNameLabel.TextColor3 = COLORS.Gold
cultNameLabel.TextSize = 13
cultNameLabel.Font = Enum.Font.GothamBlack
cultNameLabel.TextXAlignment = Enum.TextXAlignment.Left
cultNameLabel.Text = "Unnamed Cult"
cultNameLabel.ZIndex = 622
cultNameLabel.Parent = window

local rankLabel = Instance.new("TextLabel")
rankLabel.Size = UDim2.new(0.3, 0, 0, 22)
rankLabel.Position = UDim2.new(0.65, 0, 0, 76)
rankLabel.BackgroundTransparency = 1
rankLabel.TextColor3 = COLORS.Bad
rankLabel.TextSize = 13
rankLabel.Font = Enum.Font.GothamBlack
rankLabel.TextXAlignment = Enum.TextXAlignment.Right
rankLabel.Text = "No Cult"
rankLabel.ZIndex = 622
rankLabel.Parent = window

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
tabHolder.Name = "CultTabs"
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
local TAB_NAMES = { "Overview", "Members", "Actions", "History" }
local TAB_LABELS = { Overview = "Overview", Members = "Members", Actions = "Actions", History = "History" }

local function makeTab(name, order)
	local b = Instance.new("TextButton")
	b.Name = name .. "Tab"
	b.Size = UDim2.new(0.25, -6, 1, 0)
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
scroll.Name = "CultScroll"
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

local function makeStatBar(parent, labelText, value, color, y)
	local clamped = clampPercent(value)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 74, 0, 18)
	label.Position = UDim2.new(0, 18, 0, y)
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.TextSize = 12
	label.Font = Enum.Font.GothamBlack
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = labelText
	label.ZIndex = 625
	label.Parent = parent

	local back = Instance.new("Frame")
	back.Size = UDim2.new(1, -180, 0, 8)
	back.Position = UDim2.new(0, 108, 0, y + 5)
	back.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	back.BorderSizePixel = 0
	back.ZIndex = 625
	back.Parent = parent
	addCorner(back, 999)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(clamped / 100, 0, 1, 0)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.ZIndex = 626
	fill.Parent = back
	addCorner(fill, 999)

	local percent = Instance.new("TextLabel")
	percent.Size = UDim2.new(0, 44, 0, 18)
	percent.Position = UDim2.new(1, -64, 0, y)
	percent.BackgroundTransparency = 1
	percent.TextColor3 = Color3.fromRGB(170, 170, 185)
	percent.TextSize = 11
	percent.Font = Enum.Font.GothamBold
	percent.TextXAlignment = Enum.TextXAlignment.Right
	percent.Text = tostring(clamped) .. "%"
	percent.ZIndex = 625
	percent.Parent = parent
end

----------------------------------------------------------------
-- SERVER ACTION FIRER
----------------------------------------------------------------
local function fireCultAction(actionId, targetId)
	if busy then
		setActionStatus("Please wait...", COLORS.Gold)
		return
	end

	busy = true
	setActionStatus("Processing...", COLORS.Gold)
	cultAction:FireServer(actionId, targetId)

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
-- TAB CONTENT: OVERVIEW
----------------------------------------------------------------
local function buildOverviewTab(data)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -10, 0, 168)
	card.BackgroundColor3 = COLORS.Card
	card.BorderSizePixel = 0
	card.ZIndex = 624
	card.Parent = scroll
	addCorner(card, 8)
	addStroke(card, COLORS.Stroke, 1)

	local rankText = Instance.new("TextLabel")
	rankText.Size = UDim2.new(1, -36, 0, 22)
	rankText.Position = UDim2.new(0, 18, 0, 12)
	rankText.BackgroundTransparency = 1
	rankText.TextColor3 = COLORS.Text
	rankText.TextSize = 16
	rankText.Font = Enum.Font.GothamBlack
	rankText.TextXAlignment = Enum.TextXAlignment.Left
	rankText.Text = tostring(data.Rank or "No Cult") .. "  •  Infamy " .. tostring(data.Infamy or 0)
	rankText.ZIndex = 625
	rankText.Parent = card

	local statsText = Instance.new("TextLabel")
	statsText.Size = UDim2.new(1, -36, 0, 20)
	statsText.Position = UDim2.new(0, 18, 0, 38)
	statsText.BackgroundTransparency = 1
	statsText.TextColor3 = COLORS.SubText
	statsText.TextSize = 12
	statsText.Font = Enum.Font.GothamBold
	statsText.TextXAlignment = Enum.TextXAlignment.Left
	statsText.Text = "Members "
		.. tostring(data.Members or 0)
		.. "  •  Treasury $"
		.. tostring(data.Treasury or 0)
		.. "  •  Territory "
		.. tostring(data.Territory or "None")
	statsText.ZIndex = 625
	statsText.Parent = card

	makeStatBar(card, "Loyalty", data.Loyalty, COLORS.Green, 66)
	makeStatBar(card, "Territory", data.TerritoryControl, COLORS.Gold, 92)

	local focusLabel = Instance.new("TextLabel")
	focusLabel.Size = UDim2.new(0, 100, 0, 18)
	focusLabel.Position = UDim2.new(0, 18, 0, 124)
	focusLabel.BackgroundTransparency = 1
	focusLabel.TextColor3 = COLORS.SubText
	focusLabel.TextSize = 11
	focusLabel.Font = Enum.Font.GothamBold
	focusLabel.TextXAlignment = Enum.TextXAlignment.Left
	focusLabel.Text = "FOCUS:"
	focusLabel.ZIndex = 625
	focusLabel.Parent = card

	for i, focusName in ipairs(FOCUS_NAMES) do
		local isActive = data.Focus == focusName
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 110, 0, 28)
		btn.Position = UDim2.new(0, 108 + (i - 1) * 118, 0, 120)
		btn.BackgroundColor3 = isActive and COLORS.Accent or COLORS.Button
		btn.BorderSizePixel = 0
		btn.TextColor3 = isActive and COLORS.Text or COLORS.SubText
		btn.TextSize = 12
		btn.Font = Enum.Font.GothamBlack
		btn.Text = string.upper(focusName)
		btn.AutoButtonColor = false
		btn.ZIndex = 625
		btn.Parent = card
		addCorner(btn, 7)
		addStroke(btn, Color3.fromRGB(48, 48, 64), 1)
		if not isActive then
			setButtonTween(btn, COLORS.ButtonHover)
			btn.MouseButton1Click:Connect(function()
				fireCultAction("Cult_SetFocus", focusName)
			end)
		end
	end
end

----------------------------------------------------------------
-- TAB CONTENT: MEMBERS
----------------------------------------------------------------
local function makeMemberCard(member)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -10, 0, 128)
	card.BackgroundColor3 = COLORS.Card
	card.BorderSizePixel = 0
	card.ZIndex = 624
	card.Parent = scroll
	addCorner(card, 8)
	addStroke(card, COLORS.Stroke, 1)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -160, 0, 24)
	nameLabel.Position = UDim2.new(0, 18, 0, 12)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = tostring(member.Name or "Unknown")
	nameLabel.ZIndex = 625
	nameLabel.Parent = card

	local roleLabel = Instance.new("TextLabel")
	roleLabel.Size = UDim2.new(0, 140, 0, 22)
	roleLabel.Position = UDim2.new(1, -158, 0, 14)
	roleLabel.BackgroundTransparency = 1
	roleLabel.TextColor3 = roleColor(member.Role)
	roleLabel.TextSize = 13
	roleLabel.Font = Enum.Font.GothamBlack
	roleLabel.TextXAlignment = Enum.TextXAlignment.Right
	roleLabel.Text = tostring(member.Role or "Unknown")
	roleLabel.ZIndex = 625
	roleLabel.Parent = card

	makeStatBar(card, "Devotion", member.Devotion, Color3.fromRGB(200, 90, 200), 44)
	makeStatBar(card, "Trust", member.Trust, Color3.fromRGB(90, 170, 230), 68)
	makeStatBar(card, "Fear", member.Fear, Color3.fromRGB(210, 90, 90), 92)

	return card
end

local function buildMembersTab(data)
	local roster = data.Roster or {}
	if #roster <= 0 then
		makeEmptyCard("Your cult has no members yet. Recruit initiates from Activities.")
		return
	end

	for _, member in ipairs(roster) do
		makeMemberCard(member)
	end
end

----------------------------------------------------------------
-- TAB CONTENT: ACTIONS
----------------------------------------------------------------
local function buildActionsTab(data)
	local actions = data.Actions or {}
	local rankIndex = BitKaisenCultData.GetRankIndex(data.Rank)

	for _, actionId in ipairs(ACTION_ORDER) do
		local def = actions[actionId]
		if def then
			local enabled = true
			local lockedReason = nil
			if def.MinRank then
				local minRankIndex = BitKaisenCultData.GetRankIndex(def.MinRank)
				if rankIndex < minRankIndex then
					enabled = false
					lockedReason = "Requires: " .. tostring(def.MinRank)
				end
			end

			local card = Instance.new("Frame")
			card.Size = UDim2.new(1, -10, 0, 100)
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
			nameLabel.TextSize = 16
			nameLabel.Font = Enum.Font.GothamBlack
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Text = tostring(def.Name or actionId)
			nameLabel.ZIndex = 625
			nameLabel.Parent = card

			local descLabel = Instance.new("TextLabel")
			descLabel.Size = UDim2.new(1, -170, 0, 48)
			descLabel.Position = UDim2.new(0, 18, 0, 42)
			descLabel.BackgroundTransparency = 1
			descLabel.TextColor3 = Color3.fromRGB(185, 185, 195)
			descLabel.TextSize = 12
			descLabel.Font = Enum.Font.GothamMedium
			descLabel.TextWrapped = true
			descLabel.TextXAlignment = Enum.TextXAlignment.Left
			descLabel.TextYAlignment = Enum.TextYAlignment.Top
			descLabel.Text = lockedReason or tostring(def.Description or "")
			descLabel.TextColor3 = lockedReason and COLORS.Bad or Color3.fromRGB(185, 185, 195)
			descLabel.ZIndex = 625
			descLabel.Parent = card

			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(0, 122, 0, 38)
			btn.Position = UDim2.new(1, -140, 0.5, -19)
			btn.BackgroundColor3 = enabled and COLORS.Accent or COLORS.Button
			btn.BorderSizePixel = 0
			btn.TextColor3 = enabled and COLORS.Text or COLORS.Muted
			btn.TextSize = 12
			btn.Font = Enum.Font.GothamBlack
			btn.Text = enabled and "DO IT" or "LOCKED"
			btn.AutoButtonColor = false
			btn.ZIndex = 626
			btn.Parent = card
			addCorner(btn, 7)
			addStroke(btn, Color3.fromRGB(60, 60, 75), 1)
			if enabled then
				setButtonTween(btn, lighten(COLORS.Accent, 20))
				btn.MouseButton1Click:Connect(function()
					fireCultAction(actionId)
				end)
			end
		end
	end
end

----------------------------------------------------------------
-- TAB CONTENT: HISTORY
----------------------------------------------------------------
local function buildHistoryTab(data)
	local history = data.History or {}
	if #history <= 0 then
		makeEmptyCard("Your cult has no recorded history yet.")
		return
	end

	for i = #history, 1, -1 do
		local entry = history[i]
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, -10, 0, 0)
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.BackgroundColor3 = COLORS.Card
		card.BorderSizePixel = 0
		card.ZIndex = 624
		card.Parent = scroll
		addCorner(card, 8)
		addStroke(card, COLORS.Stroke, 1)

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -36, 0, 0)
		label.Position = UDim2.new(0, 18, 0, 12)
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.BackgroundTransparency = 1
		label.TextColor3 = COLORS.SubText
		label.TextSize = 13
		label.Font = Enum.Font.GothamMedium
		label.TextWrapped = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.RichText = true
		label.Text = "<b>Year " .. tostring(entry.Year or 0) .. ":</b> " .. tostring(entry.Text or "")
		label.ZIndex = 625
		label.Parent = card

		local pad = Instance.new("UIPadding")
		pad.PaddingBottom = UDim.new(0, 12)
		pad.Parent = card
	end
end

----------------------------------------------------------------
-- MAIN REFRESH
----------------------------------------------------------------
refresh = function()
	local ok, data = pcall(function()
		return getCult:InvokeServer()
	end)

	clearCards()

	if not ok then
		warn("[CultPanel] Failed to load cult:", data)
		makeEmptyCard("Could not load the cult. Try again later.")
		return
	end

	currentData = data or {}

	cultNameLabel.Text = tostring(currentData.CultName or "Unnamed Cult")
	rankLabel.Text = tostring(currentData.Rank or "No Cult")

	if currentTab == "Overview" then
		buildOverviewTab(currentData)
	elseif currentTab == "Members" then
		buildMembersTab(currentData)
	elseif currentTab == "Actions" then
		buildActionsTab(currentData)
	elseif currentTab == "History" then
		buildHistoryTab(currentData)
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

cultAction.OnClientEvent:Connect(function()
	if isOpen then refresh() end
end)

----------------------------------------------------------------
-- INIT
----------------------------------------------------------------
local function init()
	uiState.subscribe(function(route)
		if route == "cult" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
