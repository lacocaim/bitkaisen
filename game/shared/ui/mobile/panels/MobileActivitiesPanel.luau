local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local uiState = require("@ui-state/uiState")
local mc = require("@ui/mobile/mobileComponents")

local theme = mc.theme
local corner = mc.corner
local stroke = mc.stroke
local bindTap = mc.bindTap
local mobileCard = mc.mobileCard
local mobileLabel = mc.mobileLabel
local mobileButton = mc.mobileButton
local mobileHeader = mc.mobileHeader

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getActivityList = ReplicatedStorage:WaitForChild("GetActivityList")
local updateLifeEvent = ReplicatedStorage:WaitForChild("UpdateLifeEvent")

local TWEEN_QUICK = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

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

local CATEGORY_ORDER = {
	"All", "Life", "School", "Training", "Jujutsu High", "Mentor",
	"Missions", "Dojo/Clan", "Social", "Minigames",
	"Curse Spirit", "Underworld", "Curse User", "Era", "Premium",
}

-- ScreenGui

local gui = Instance.new("ScreenGui")
gui.Name = "MobileActivitiesGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 621
gui.Enabled = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- Root sheet (full-screen)

local sheet = Instance.new("Frame")
sheet.Name = "Sheet"
sheet.Size = UDim2.fromScale(1, 1)
sheet.BackgroundColor3 = theme.Bg
sheet.BorderSizePixel = 0
sheet.Parent = gui

-- Header

mobileHeader(sheet, "ACTIVITIES", function()
	uiState.closeRoute()
end)

-- Category filter bar (horizontal pills)

local PILL_BAR_HEIGHT = 40
local PILL_HEIGHT = 32

local pillBar = Instance.new("ScrollingFrame")
pillBar.Name = "CategoryBar"
pillBar.Size = UDim2.new(1, 0, 0, PILL_BAR_HEIGHT)
pillBar.Position = UDim2.new(0, 0, 0, 50)
pillBar.BackgroundTransparency = 1
pillBar.BorderSizePixel = 0
pillBar.ScrollBarThickness = 0
pillBar.CanvasSize = UDim2.new(0, 0, 0, PILL_BAR_HEIGHT)
pillBar.AutomaticCanvasSize = Enum.AutomaticSize.X
pillBar.ScrollingDirection = Enum.ScrollingDirection.X
pillBar.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
pillBar.Parent = sheet

local pillLayout = Instance.new("UIListLayout")
pillLayout.FillDirection = Enum.FillDirection.Horizontal
pillLayout.SortOrder = Enum.SortOrder.LayoutOrder
pillLayout.Padding = UDim.new(0, 6)
pillLayout.VerticalAlignment = Enum.VerticalAlignment.Center
pillLayout.Parent = pillBar

local pillPadding = Instance.new("UIPadding")
pillPadding.PaddingLeft = UDim.new(0, 10)
pillPadding.PaddingRight = UDim.new(0, 10)
pillPadding.Parent = pillBar

-- Activity scroll area

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "ActivityScroll"
scroll.Size = UDim2.new(1, 0, 1, -(50 + PILL_BAR_HEIGHT + 4))
scroll.Position = UDim2.new(0, 0, 0, 50 + PILL_BAR_HEIGHT + 4)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = theme.Stroke
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
scroll.Parent = sheet

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Padding = UDim.new(0, 8)
scrollLayout.Parent = scroll

local scrollPad = Instance.new("UIPadding")
scrollPad.PaddingTop = UDim.new(0, 6)
scrollPad.PaddingBottom = UDim.new(0, 20)
scrollPad.PaddingLeft = UDim.new(0, 10)
scrollPad.PaddingRight = UDim.new(0, 10)
scrollPad.Parent = scroll

-- State

local selectedCategory = "All"
local pillButtons: { [string]: TextButton } = {}
local activityCache: { any }? = nil

-- Helpers

local function clearScroll()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
end

local function updatePillHighlight()
	for cat, btn in pairs(pillButtons) do
		local active = cat == selectedCategory
		local catColor = CATEGORY_COLORS[cat] or theme.Purple
		TweenService:Create(btn, TWEEN_QUICK, {
			BackgroundColor3 = active and catColor or theme.Card,
			BackgroundTransparency = if active then 0.15 else 0,
		}):Play()
		btn.TextColor3 = active and theme.Text or theme.SubText
	end
end

local function createCategoryHeader(cat: string, order: number)
	local catColor = CATEGORY_COLORS[cat] or Color3.fromRGB(160, 160, 180)

	local header = Instance.new("Frame")
	header.Name = "Header_" .. cat
	header.Size = UDim2.new(1, 0, 0, 28)
	header.BackgroundColor3 = catColor
	header.BackgroundTransparency = 0.82
	header.BorderSizePixel = 0
	header.LayoutOrder = order
	header.Parent = scroll
	corner(header, 6)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -12, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 13
	label.TextColor3 = catColor
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = string.upper(cat)
	label.Parent = header
end

local function createActivityCard(activityData: any, order: number)
	local canDo = activityData.CanDo == true
	local catColor = CATEGORY_COLORS[activityData.Category] or theme.Purple

	local card = mobileCard({
		parent = scroll,
		color = canDo and theme.Card or Color3.fromRGB(16, 14, 18),
		accentColor = canDo and theme.Stroke or Color3.fromRGB(70, 35, 42),
		order = order,
	})

	-- Title
	mobileLabel({
		parent = card,
		text = tostring(activityData.Title or "Unknown Activity"),
		size = 16,
		color = canDo and theme.Text or theme.Muted,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	-- Status tag
	mobileLabel({
		parent = card,
		text = canDo and "AVAILABLE" or "LOCKED",
		size = 11,
		color = canDo and catColor or theme.Bad,
		font = Enum.Font.GothamBlack,
		order = 2,
	})

	-- Description / locked reason
	mobileLabel({
		parent = card,
		text = canDo and tostring(activityData.Description or "") or tostring(activityData.LockedReason or "Locked."),
		size = 13,
		color = canDo and theme.SubText or Color3.fromRGB(140, 90, 100),
		font = Enum.Font.GothamMedium,
		order = 3,
		wrap = true,
	})

	-- DO / LOCKED button
	mobileButton({
		parent = card,
		text = canDo and "DO ACTIVITY" or "LOCKED",
		size = UDim2.new(1, 0, 0, 46),
		position = UDim2.new(0, 0, 0, 0),
		color = canDo and theme.Red or Color3.fromRGB(32, 32, 40),
		textColor = canDo and theme.Text or theme.Muted,
		textSize = 15,
		order = 4,
		callback = function()
			if not canDo then return end
			if not activityData.Id then return end
			if activityData.OpensPanel then
				uiState.navigate(activityData.OpensPanel)
				return
			end
			updateLifeEvent:FireServer("DoActivity", activityData.Id)
			uiState.closeRoute()
		end,
	})

	if canDo then
		stroke(card, catColor, 1)
	end
end

local function createMessageCard(text: string, color: Color3?)
	local card = mobileCard({
		parent = scroll,
		order = 0,
	})
	mobileLabel({
		parent = card,
		text = text,
		size = 14,
		color = color or theme.SubText,
		font = Enum.Font.GothamBold,
		order = 1,
	})
end

local function renderActivities(activities: { any })
	clearScroll()

	if not activities or #activities == 0 then
		createMessageCard("No activities available.", theme.SubText)
		return
	end

	-- Group by category
	local grouped: { [string]: { any } } = {}
	local presentCategories: { string } = {}
	for _, data in ipairs(activities) do
		local cat = data.Category or "Life"
		if selectedCategory ~= "All" and cat ~= selectedCategory then continue end
		if not grouped[cat] then
			grouped[cat] = {}
			table.insert(presentCategories, cat)
		end
		table.insert(grouped[cat], data)
	end

	-- Order categories consistently
	local orderedCats: { string } = {}
	for _, cat in ipairs(CATEGORY_ORDER) do
		if cat ~= "All" and grouped[cat] then
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

	if #orderedCats == 0 then
		createMessageCard("No activities in this category.", theme.SubText)
		return
	end

	local layoutOrder = 0
	for _, cat in ipairs(orderedCats) do
		createCategoryHeader(cat, layoutOrder)
		layoutOrder += 1

		for _, data in ipairs(grouped[cat]) do
			createActivityCard(data, layoutOrder)
			layoutOrder += 1
		end
	end
end

local function buildPills(categories: { string })
	for _, child in ipairs(pillBar:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	pillButtons = {}

	for i, cat in ipairs(categories) do
		local catColor = CATEGORY_COLORS[cat] or theme.Purple
		local active = cat == selectedCategory

		local pill = Instance.new("TextButton")
		pill.Name = "Pill_" .. cat
		pill.Size = UDim2.new(0, 0, 0, PILL_HEIGHT)
		pill.AutomaticSize = Enum.AutomaticSize.X
		pill.BackgroundColor3 = active and catColor or theme.Card
		pill.BackgroundTransparency = if active then 0.15 else 0
		pill.BorderSizePixel = 0
		pill.Text = cat
		pill.TextColor3 = active and theme.Text or theme.SubText
		pill.TextSize = 13
		pill.Font = Enum.Font.GothamBold
		pill.AutoButtonColor = false
		pill.ZIndex = 5
		pill.LayoutOrder = i
		pill.Parent = pillBar
		corner(pill, 999)

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 14)
		pad.PaddingRight = UDim.new(0, 14)
		pad.Parent = pill

		bindTap(pill, function()
			selectedCategory = cat
			updatePillHighlight()
			if activityCache then
				renderActivities(activityCache)
			end
		end)

		pillButtons[cat] = pill
	end
end

local function refresh()
	clearScroll()
	selectedCategory = "All"
	createMessageCard("Loading activities...", theme.SubText)

	local success, activities = pcall(function()
		return getActivityList:InvokeServer()
	end)

	clearScroll()

	if not success then
		warn("[MobileActivitiesPanel] Failed to get activities:", activities)
		createMessageCard("Could not load activities.\nCheck server output.", theme.Bad)
		return
	end

	if not activities or #activities == 0 then
		createMessageCard("No activities available.", theme.SubText)
		return
	end

	activityCache = activities

	-- Determine which categories are present
	local seen: { [string]: boolean } = {}
	for _, data in ipairs(activities) do
		seen[data.Category or "Life"] = true
	end
	local pillCats: { string } = { "All" }
	for _, cat in ipairs(CATEGORY_ORDER) do
		if cat ~= "All" and seen[cat] then
			table.insert(pillCats, cat)
		end
	end

	buildPills(pillCats)
	renderActivities(activities)
end

local function openPanel()
	gui.Enabled = true
	scroll.CanvasPosition = Vector2.zero
	refresh()
end

local function closePanel()
	gui.Enabled = false
	activityCache = nil
end

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
