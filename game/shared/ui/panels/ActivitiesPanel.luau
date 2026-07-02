local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local uiState = require("@ui-state/uiState")
local responsiveScale = require("@ui/responsiveScale")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getActivityList = ReplicatedStorage:WaitForChild("GetActivityList")
local updateLifeEvent = ReplicatedStorage:WaitForChild("UpdateLifeEvent")

local THEME = {
	Bg = Color3.fromRGB(8, 8, 13),
	Panel = Color3.fromRGB(15, 15, 23),
	Panel2 = Color3.fromRGB(20, 20, 30),
	Card = Color3.fromRGB(20, 20, 29),
	Stroke = Color3.fromRGB(58, 52, 76),
	Text = Color3.fromRGB(242, 240, 250),
	SubText = Color3.fromRGB(168, 164, 186),
	Muted = Color3.fromRGB(105, 105, 125),
	Bad = Color3.fromRGB(230, 75, 90),
	Red = Color3.fromRGB(145, 32, 45),
	RedDark = Color3.fromRGB(82, 20, 28),
	Purple = Color3.fromRGB(178, 120, 255),
}

local CATEGORY_COLORS = {
	Life = Color3.fromRGB(120, 160, 120),
	School = Color3.fromRGB(55, 100, 170),
	Training = Color3.fromRGB(180, 130, 50),
	["Jujutsu High"] = Color3.fromRGB(95, 165, 255),
	Mentor = Color3.fromRGB(55, 180, 220),
	Missions = Color3.fromRGB(200, 80, 80),
	["Dojo/Clan"] = Color3.fromRGB(120, 70, 120),
	Social = Color3.fromRGB(140, 140, 180),
	Minigames = Color3.fromRGB(200, 160, 60),
	["Curse Spirit"] = Color3.fromRGB(178, 120, 255),
	["Curse User"] = Color3.fromRGB(220, 60, 75),
	Underworld = Color3.fromRGB(120, 45, 130),
	Era = Color3.fromRGB(100, 140, 90),
	Premium = Color3.fromRGB(255, 204, 102),
}

local CATEGORY_ORDER_CLIENT = {
	"Life", "School", "Training", "Jujutsu High", "Mentor",
	"Missions", "Dojo/Clan", "Social", "Minigames",
	"Curse Spirit", "Underworld", "Curse User", "Era", "Premium",
}

local RAIL_W = 130

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenActivitiesGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 620
gui.Enabled = false
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "ActivitiesOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.35
overlay.ZIndex = 620
overlay.Parent = gui

local window = Instance.new("Frame")
window.Name = "ActivitiesWindow"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.BackgroundColor3 = THEME.Panel
window.BorderSizePixel = 0
window.ZIndex = 621
window.Parent = overlay

local windowCorner = Instance.new("UICorner")
windowCorner.CornerRadius = UDim.new(0, 10)
windowCorner.Parent = window

local windowStroke = Instance.new("UIStroke")
windowStroke.Color = THEME.Stroke
windowStroke.Thickness = 1
windowStroke.Parent = window

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Text = "ACTIVITIES"
title.TextColor3 = THEME.Text
title.Font = Enum.Font.GothamBlack
title.TextSize = 23
title.TextXAlignment = Enum.TextXAlignment.Left
title.Size = UDim2.new(1, -90, 0, 30)
title.Position = UDim2.new(0, 24, 0, 18)
title.ZIndex = 622
title.Parent = window

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.BackgroundColor3 = Color3.fromRGB(34, 35, 48)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = THEME.Bad
closeButton.Font = Enum.Font.GothamBlack
closeButton.TextSize = 19
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -56, 0, 16)
closeButton.ZIndex = 623
closeButton.Parent = window
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 8)

-- Category sidebar rail
local categoryRail = Instance.new("ScrollingFrame")
categoryRail.Name = "CategoryRail"
categoryRail.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
categoryRail.BackgroundTransparency = 0.3
categoryRail.BorderSizePixel = 0
categoryRail.ScrollBarThickness = 3
categoryRail.ScrollBarImageColor3 = Color3.fromRGB(80, 70, 100)
categoryRail.AutomaticCanvasSize = Enum.AutomaticSize.Y
categoryRail.CanvasSize = UDim2.new(0, 0, 0, 0)
categoryRail.ScrollingDirection = Enum.ScrollingDirection.Y
categoryRail.Size = UDim2.new(0, RAIL_W, 1, -78)
categoryRail.Position = UDim2.new(0, 10, 0, 60)
categoryRail.ZIndex = 622
categoryRail.Parent = window
Instance.new("UICorner", categoryRail).CornerRadius = UDim.new(0, 8)

local railLayout = Instance.new("UIListLayout")
railLayout.SortOrder = Enum.SortOrder.LayoutOrder
railLayout.Padding = UDim.new(0, 4)
railLayout.Parent = categoryRail

local railPadding = Instance.new("UIPadding")
railPadding.PaddingTop = UDim.new(0, 6)
railPadding.PaddingBottom = UDim.new(0, 6)
railPadding.PaddingLeft = UDim.new(0, 4)
railPadding.PaddingRight = UDim.new(0, 4)
railPadding.Parent = categoryRail

-- Activity scroll area
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "ActivityScroll"
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarImageColor3 = THEME.Purple
scroll.ScrollBarThickness = 5
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.ScrollingEnabled = true
scroll.Active = true
scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
scroll.Size = UDim2.new(1, -RAIL_W - 46, 1, -78)
scroll.Position = UDim2.new(0, RAIL_W + 18, 0, 60)
scroll.ZIndex = 622
scroll.Parent = window

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingTop = UDim.new(0, 10)
scrollPadding.PaddingBottom = UDim.new(0, 10)
scrollPadding.Parent = scroll

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Padding = UDim.new(0, 10)
scrollLayout.Parent = scroll

scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 20)
end)

local isOpen = false
local categoryButtons = {}

local function viewport()
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local function mobile()
	local v = viewport()
	return UserInputService.TouchEnabled or v.X < 900
end

responsiveScale.attach(window, 1114, 799)

local function clearCards()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
end

local function clearRailButtons()
	for _, btn in ipairs(categoryButtons) do
		if btn and btn.Parent then btn:Destroy() end
	end
	categoryButtons = {}
end

local function createMessageCard(text, color)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -10, 0, 112)
	card.BackgroundColor3 = THEME.Panel2
	card.BorderSizePixel = 0
	card.ZIndex = 623
	card.Parent = scroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
	local msgStroke = Instance.new("UIStroke")
	msgStroke.Color = THEME.Stroke
	msgStroke.Thickness = 1
	msgStroke.Parent = card

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -40, 1, 0)
	label.Position = UDim2.new(0, 20, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = color or THEME.SubText
	label.TextSize = 15
	label.Font = Enum.Font.GothamBold
	label.TextWrapped = true
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Text = text
	label.ZIndex = 624
	label.Parent = card
end

local function createActivityCard(activityData)
	local isMobile = mobile()
	local canDo = activityData.CanDo == true
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -10, 0, isMobile and 152 or 172)
	card.BackgroundColor3 = canDo and THEME.Panel2 or Color3.fromRGB(18, 16, 20)
	card.BorderSizePixel = 0
	card.ZIndex = 623
	card.Parent = scroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = canDo and THEME.Stroke or Color3.fromRGB(70, 35, 42)
	cardStroke.Thickness = 1
	cardStroke.Parent = card

	local accentColor = canDo and (activityData.ButtonColor or THEME.Red) or THEME.Muted
	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(0, 5, 1, -22)
	accent.Position = UDim2.new(0, 12, 0, 11)
	accent.BackgroundColor3 = accentColor
	accent.BackgroundTransparency = canDo and 0 or 0.35
	accent.BorderSizePixel = 0
	accent.ZIndex = 624
	accent.Parent = card
	Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 999)

	local cardTitle = Instance.new("TextLabel")
	cardTitle.Size = UDim2.new(1, -56, 0, 30)
	cardTitle.Position = UDim2.new(0, 28, 0, 14)
	cardTitle.BackgroundTransparency = 1
	cardTitle.TextColor3 = canDo and THEME.Text or THEME.Muted
	cardTitle.TextSize = isMobile and 15 or 18
	cardTitle.Font = Enum.Font.GothamBlack
	cardTitle.TextXAlignment = Enum.TextXAlignment.Left
	cardTitle.Text = tostring(activityData.Title or "Unknown Activity")
	cardTitle.ZIndex = 624
	cardTitle.Parent = card

	local tag = Instance.new("TextLabel")
	tag.Size = UDim2.new(1, -56, 0, 18)
	tag.Position = UDim2.new(0, 28, 0, 43)
	tag.BackgroundTransparency = 1
	tag.TextColor3 = canDo and accentColor or THEME.Bad
	tag.TextSize = 11
	tag.Font = Enum.Font.GothamBlack
	tag.TextXAlignment = Enum.TextXAlignment.Left
	tag.Text = canDo and "AVAILABLE" or "LOCKED"
	tag.ZIndex = 624
	tag.Parent = card

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -56, 0, 56)
	desc.Position = UDim2.new(0, 28, 0, 64)
	desc.BackgroundTransparency = 1
	desc.TextColor3 = canDo and THEME.SubText or Color3.fromRGB(140, 90, 100)
	desc.TextSize = 12
	desc.Font = Enum.Font.GothamMedium
	desc.TextWrapped = true
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.Text = canDo and tostring(activityData.Description or "") or tostring(activityData.LockedReason or "Locked.")
	desc.ZIndex = 624
	desc.Parent = card

	local doBtn = Instance.new("TextButton")
	doBtn.Size = UDim2.new(0, isMobile and 110 or 132, 0, 36)
	doBtn.Position = UDim2.new(1, isMobile and -124 or -150, 1, -46)
	doBtn.BackgroundColor3 = canDo and THEME.RedDark or Color3.fromRGB(38, 38, 46)
	doBtn.TextColor3 = canDo and THEME.Text or THEME.Muted
	doBtn.TextSize = 13
	doBtn.Font = Enum.Font.GothamBlack
	doBtn.Text = canDo and "DO" or "LOCKED"
	doBtn.AutoButtonColor = false
	doBtn.BorderSizePixel = 0
	doBtn.ZIndex = 624
	doBtn.Parent = card
	Instance.new("UICorner", doBtn).CornerRadius = UDim.new(0, 8)
	local doBtnStroke = Instance.new("UIStroke")
	doBtnStroke.Color = canDo and THEME.Red or THEME.Stroke
	doBtnStroke.Thickness = 1
	doBtnStroke.Parent = doBtn

	if canDo then
		doBtn.MouseEnter:Connect(function()
			TweenService:Create(doBtn, TweenInfo.new(0.12), { BackgroundColor3 = THEME.Red }):Play()
		end)
		doBtn.MouseLeave:Connect(function()
			TweenService:Create(doBtn, TweenInfo.new(0.12), { BackgroundColor3 = THEME.RedDark }):Play()
		end)
	end

	doBtn.MouseButton1Click:Connect(function()
		if not activityData.CanDo then return end
		if not activityData.Id then return end
		if activityData.OpensPanel then
			uiState.navigate(activityData.OpensPanel)
			return
		end
		updateLifeEvent:FireServer("DoActivity", activityData.Id)
		uiState.closeRoute()
	end)

	return card
end

local function refresh()
	clearCards()
	clearRailButtons()
	createMessageCard("Loading activities...", Color3.fromRGB(180, 180, 190))

	local success, activities = pcall(function()
		return getActivityList:InvokeServer()
	end)

	clearCards()

	if not success then
		warn("[ActivitiesPanel] Failed to get activities:", activities)
		createMessageCard("Could not load activities.\nCheck server output.", Color3.fromRGB(220, 90, 90))
		return
	end
	if not activities or #activities <= 0 then
		createMessageCard("No activities available.", Color3.fromRGB(180, 180, 190))
		return
	end

	local grouped = {}
	local presentCategories = {}
	for _, activityData in ipairs(activities) do
		local cat = activityData.Category or "Life"
		if not grouped[cat] then
			grouped[cat] = {}
			table.insert(presentCategories, cat)
		end
		table.insert(grouped[cat], activityData)
	end

	local orderedCats = {}
	for _, cat in ipairs(CATEGORY_ORDER_CLIENT) do
		if grouped[cat] then
			table.insert(orderedCats, cat)
		end
	end
	for _, cat in ipairs(presentCategories) do
		local found = false
		for _, c in ipairs(orderedCats) do
			if c == cat then found = true break end
		end
		if not found then
			table.insert(orderedCats, cat)
		end
	end

	local headerFrames = {}
	local layoutOrder = 0

	for _, cat in ipairs(orderedCats) do
		local catColor = CATEGORY_COLORS[cat] or Color3.fromRGB(160, 160, 180)

		local header = Instance.new("Frame")
		header.Name = "CategoryHeader_" .. cat
		header.Size = UDim2.new(1, -10, 0, 28)
		header.BackgroundColor3 = catColor
		header.BackgroundTransparency = 0.8
		header.BorderSizePixel = 0
		header.LayoutOrder = layoutOrder
		header.ZIndex = 623
		header.Parent = scroll
		Instance.new("UICorner", header).CornerRadius = UDim.new(0, 6)

		local headerLabel = Instance.new("TextLabel")
		headerLabel.Size = UDim2.new(1, -12, 1, 0)
		headerLabel.Position = UDim2.new(0, 6, 0, 0)
		headerLabel.BackgroundTransparency = 1
		headerLabel.Font = Enum.Font.GothamBlack
		headerLabel.TextSize = 13
		headerLabel.TextColor3 = catColor
		headerLabel.TextXAlignment = Enum.TextXAlignment.Left
		headerLabel.Text = string.upper(cat)
		headerLabel.ZIndex = 624
		headerLabel.Parent = header

		headerFrames[cat] = header
		layoutOrder += 1

		for _, activityData in ipairs(grouped[cat]) do
			local card = createActivityCard(activityData)
			if card then
				card.LayoutOrder = layoutOrder
				card.Name = "Activity_" .. activityData.Id
			end
			layoutOrder += 1
		end
	end

	for railOrder, cat in ipairs(orderedCats) do
		local catColor = CATEGORY_COLORS[cat] or Color3.fromRGB(160, 160, 180)
		local btn = Instance.new("TextButton")
		btn.Name = "CatBtn_" .. cat
		btn.Size = UDim2.new(1, 0, 0, 28)
		btn.BackgroundColor3 = catColor
		btn.BackgroundTransparency = 0.7
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 11
		btn.TextColor3 = Color3.fromRGB(230, 230, 240)
		btn.Text = cat
		btn.LayoutOrder = railOrder
		btn.ZIndex = 623
		btn.AutoButtonColor = true
		btn.BorderSizePixel = 0
		btn.Parent = categoryRail
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

		btn.MouseButton1Click:Connect(function()
			local headerFrame = headerFrames[cat]
			if headerFrame then
				local yOffset = headerFrame.AbsolutePosition.Y - scroll.AbsolutePosition.Y + scroll.CanvasPosition.Y
				scroll.CanvasPosition = Vector2.new(0, math.max(0, yOffset - 4))
			end
		end)

		table.insert(categoryButtons, btn)
	end
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
		if route == "activities" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
