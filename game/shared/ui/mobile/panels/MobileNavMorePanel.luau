-- Update 30 -- mobile half of the Simple nav bar (see NavMorePanel for the desktop one).
--
-- With Simple mode on the nav grid only draws the core life-sim loop plus a MORE tile
-- that routes here; this sheet lists every category the grid is not showing. Nothing is
-- removed, it is one extra tap. In Full mode the MORE tile does not exist and this
-- sheet is never routed to (navRegistry.isEntryVisible).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local L = BitKaisenLocale.getClientLocale()
local function _nm(key, fallback)
	return BitKaisenLocale.tOrFallback(L, "nav_more_panel." .. key, nil, fallback)
end

local uiState = require("@ui-state/uiState")
local navRegistry = require("@ui-state/navRegistry")
local mc = require("@ui/mobile/mobileComponents")

local theme = mc.theme
local corner = mc.corner
local stroke = mc.stroke
local bindTap = mc.bindTap
local mobileHeader = mc.mobileHeader

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "MobileNavMoreGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 621
gui.Enabled = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local sheet = Instance.new("Frame")
sheet.Name = "Sheet"
sheet.Size = UDim2.fromScale(1, 1)
sheet.BackgroundColor3 = theme.Bg
sheet.BorderSizePixel = 0
sheet.Parent = gui

mobileHeader(sheet, _nm("title", "MORE"), function()
	uiState.closeRoute()
end)

local hint = Instance.new("TextLabel")
hint.Name = "Hint"
hint.BackgroundTransparency = 1
hint.Position = UDim2.new(0, 12, 0, 54)
hint.Size = UDim2.new(1, -24, 0, 30)
hint.Text = _nm("subtitle_mobile", "Turn off Simple Menu in Settings to keep every category on the menu.")
hint.TextColor3 = theme.SubText
hint.Font = Enum.Font.GothamMedium
hint.TextSize = 12
hint.TextWrapped = true
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.TextYAlignment = Enum.TextYAlignment.Top
hint.Parent = sheet

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "EntryScroll"
scroll.Position = UDim2.new(0, 0, 0, 88)
scroll.Size = UDim2.new(1, 0, 1, -88)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = theme.Stroke
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
scroll.Parent = sheet

local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 12)
pad.PaddingRight = UDim.new(0, 12)
pad.PaddingTop = UDim.new(0, 4)
pad.PaddingBottom = UDim.new(0, 16)
pad.Parent = scroll

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.5, -5, 0, 52)
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

local function makeEntryTile(entry, order: number)
	local tile = Instance.new("TextButton")
	tile.Name = entry.id
	tile.LayoutOrder = order
	tile.BackgroundColor3 = Color3.fromRGB(14, 12, 20)
	tile.BorderSizePixel = 0
	tile.AutoButtonColor = false
	tile.Text = ""
	tile.Parent = scroll
	corner(tile, 6)
	stroke(tile, Color3.fromRGB(55, 50, 75), 1)

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.AnchorPoint = Vector2.new(0, 0.5)
	accent.Position = UDim2.new(0, 0, 0.5, 0)
	accent.Size = UDim2.new(0, 3, 0.7, 0)
	accent.BackgroundColor3 = entry.color or theme.Red
	accent.BorderSizePixel = 0
	accent.Parent = tile
	corner(accent, 999)

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 12, 0, 0)
	label.Size = UDim2.new(1, -20, 1, 0)
	label.Text = entry.label
	label.TextColor3 = theme.Text
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = tile

	-- navigate() replaces the route, so this closes MORE and opens the target in one
	-- step instead of stacking two sheets.
	bindTap(tile, function()
		uiState.navigate(entry.id)
	end)

	return tile
end

local function rebuild()
	clearEntries()
	for index, entry in ipairs(navRegistry.getOverflowEntries()) do
		makeEntryTile(entry, index)
	end
end

local function openPanel()
	rebuild()
	scroll.CanvasPosition = Vector2.zero
	gui.Enabled = true
end

local function closePanel()
	gui.Enabled = false
end

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
