-- Update 30 -- the overflow half of the Simple nav bar.
--
-- With Simple mode on, the nav bar only draws the core life-sim loop (missions,
-- activities, relationships, assets, jobs) plus a MORE button that routes here. This
-- panel lists every category the bar is not showing, so nothing becomes unreachable --
-- it is one extra click, not a removed feature. Full mode never opens this panel
-- because the MORE button does not exist there (navRegistry.isEntryVisible).
--
-- Same shape as QuickMenuPanel, which already does this for the topbar icons.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local uiState = require("@ui-state/uiState")
local navRegistry = require("@ui-state/navRegistry")
local responsiveScale = require("@ui/responsiveScale")

local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local L = BitKaisenLocale.getClientLocale()
local function _nm(key, fallback)
	return BitKaisenLocale.tOrFallback(L, "nav_more_panel." .. key, nil, fallback)
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUI_NAME = "BitKaisenNavMoreGui"

local THEME = {
	Bg = Color3.fromRGB(11, 11, 17),
	Panel = Color3.fromRGB(18, 18, 27),
	Card = Color3.fromRGB(24, 24, 35),
	Stroke = Color3.fromRGB(56, 50, 74),
	Text = Color3.fromRGB(242, 240, 250),
	SubText = Color3.fromRGB(168, 164, 186),
	Gold = Color3.fromRGB(255, 212, 94),
	Red = Color3.fromRGB(235, 82, 104),
}

local existing = playerGui:FindFirstChild(GUI_NAME)
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 628
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.AutoLocalize = false
gui.Enabled = false
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "NavMoreOverlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.45
overlay.BorderSizePixel = 0
overlay.Active = true
overlay.ZIndex = 1
overlay.Parent = gui

local window = Instance.new("Frame")
window.Name = "NavMoreWindow"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.fromScale(0.5, 0.5)
window.BackgroundColor3 = THEME.Bg
window.BorderSizePixel = 0
window.Active = true
window.ZIndex = 2
window.Parent = overlay
responsiveScale.attach(window, 560, 430)

Instance.new("UICorner", window).CornerRadius = UDim.new(0, 10)
local windowStroke = Instance.new("UIStroke")
windowStroke.Color = THEME.Stroke
windowStroke.Thickness = 1
windowStroke.Parent = window

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(20, 15)
title.Size = UDim2.new(1, -76, 0, 30)
title.Text = _nm("title", "MORE")
title.TextColor3 = THEME.Gold
title.Font = Enum.Font.GothamBlack
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 3
title.Parent = window

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(20, 44)
subtitle.Size = UDim2.new(1, -76, 0, 18)
subtitle.Text = _nm("subtitle", "Everything else. Turn off Simple Menu in Settings to keep it all on the bar.")
subtitle.TextColor3 = THEME.SubText
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 12
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextTruncate = Enum.TextTruncate.AtEnd
subtitle.ZIndex = 3
subtitle.Parent = window

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -16, 0, 15)
closeButton.Size = UDim2.fromOffset(38, 34)
closeButton.BackgroundColor3 = THEME.Card
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = THEME.Red
closeButton.Font = Enum.Font.GothamBlack
closeButton.TextSize = 16
closeButton.AutoButtonColor = true
closeButton.ZIndex = 3
closeButton.Parent = window
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 8)

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Entries"
scroll.Position = UDim2.fromOffset(18, 72)
scroll.Size = UDim2.new(1, -36, 1, -90)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ZIndex = 3
scroll.Parent = window

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.5, -5, 0, 46)
grid.CellPadding = UDim2.fromOffset(10, 10)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.FillDirection = Enum.FillDirection.Horizontal
grid.Parent = scroll

local function clearEntries()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end
end

local function makeEntryCard(entry, order: number)
	local card = Instance.new("TextButton")
	card.Name = entry.id
	card.LayoutOrder = order
	card.BackgroundColor3 = THEME.Card
	card.BorderSizePixel = 0
	card.AutoButtonColor = true
	card.Text = ""
	card.ZIndex = 4
	card.Parent = scroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = THEME.Stroke
	cardStroke.Thickness = 1
	cardStroke.Parent = card

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.AnchorPoint = Vector2.new(0, 0.5)
	accent.Position = UDim2.new(0, 10, 0.5, 0)
	accent.Size = UDim2.new(0, 4, 0, 22)
	accent.BackgroundColor3 = entry.color or THEME.Red
	accent.BorderSizePixel = 0
	accent.ZIndex = 5
	accent.Parent = card
	Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(24, 0)
	label.Size = UDim2.new(1, -34, 1, 0)
	label.Text = entry.label
	label.TextColor3 = THEME.Text
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.ZIndex = 5
	label.Parent = card

	-- navigate() replaces the current route, so this closes MORE and opens the target
	-- in one step rather than stacking one overlay on top of the other.
	card.Activated:Connect(function()
		if _G.BitKaisenPlaySFX then
			_G.BitKaisenPlaySFX("Click")
		end
		uiState.navigate(entry.id)
	end)

	return card
end

local function rebuild()
	clearEntries()
	local overflow = navRegistry.getOverflowEntries()
	for index, entry in ipairs(overflow) do
		makeEntryCard(entry, index)
	end
end

local function openPanel()
	rebuild()
	gui.Enabled = true
end

local function closePanel()
	gui.Enabled = false
end

closeButton.Activated:Connect(function()
	uiState.closeRoute()
end)

overlay.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local pos = window.AbsolutePosition
	local size = window.AbsoluteSize
	local x, y = input.Position.X, input.Position.Y
	if x < pos.X or x > pos.X + size.X or y < pos.Y or y > pos.Y + size.Y then
		uiState.closeRoute()
	end
end)

local function init()
	uiState.subscribe(function(route)
		if route == navRegistry.MORE_ID then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
