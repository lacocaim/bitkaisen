-- Consolidated menu opened from the topbar "MENU" icon (see topbarIcons.luau).
-- Folds the less-frequently-tapped topbar icons (God Mode, Clan War, Cult
-- War, AFK) into one list instead of each having its own always-visible
-- icon -- per Luisa's boss, referencing how BitSeas/BitShinobi keep only a
-- couple of icons visible and put the rest behind a menu. Settings (gear),
-- Free Rewards (gift), and Help & Guide (?) stay as their own icons --
-- Help & Guide was pulled back out of this menu per Luisa (2026-07-21).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local responsiveScale = require("@ui/responsiveScale")
local overlayManager = require("@ui-state/overlayManager")

local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _g(key: string, fallback: string): string
	return BitKaisenLocale.tOrFallback(_L, "quickmenu." .. key, nil, fallback)
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUI_NAME = "BitKaisenQuickMenuGui"

local THEME = {
	Bg = Color3.fromRGB(13, 13, 20),
	Panel = Color3.fromRGB(19, 19, 29),
	Panel2 = Color3.fromRGB(28, 28, 40),
	CardStroke = Color3.fromRGB(52, 48, 72),
	Stroke = Color3.fromRGB(116, 84, 165),
	Gold = Color3.fromRGB(255, 212, 94),
	Purple = Color3.fromRGB(156, 96, 246),
	Red = Color3.fromRGB(235, 82, 104),
	Text = Color3.fromRGB(245, 241, 255),
	Muted = Color3.fromRGB(176, 169, 195),
}

local state = { IsOpen = false, PanelRefs = nil :: { [string]: any }? }

local existing = playerGui:FindFirstChild(GUI_NAME)
if existing then
	existing:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 635
screenGui.Enabled = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.AutoLocalize = false
screenGui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.Size = UDim2.fromScale(1, 1)
overlay.Visible = false
overlay.Active = true
overlay.Parent = screenGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.BackgroundColor3 = THEME.Bg
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = overlay
responsiveScale.attach(panel, 380, 420)

Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = THEME.Stroke
panelStroke.Thickness = 1
panelStroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(18, 14)
title.Size = UDim2.new(1, -70, 0, 30)
title.Text = _g("title", "Menu")
title.TextColor3 = THEME.Gold
title.Font = Enum.Font.GothamBlack
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -16, 0, 14)
closeButton.Size = UDim2.fromOffset(36, 32)
closeButton.BackgroundColor3 = THEME.Panel2
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = THEME.Red
closeButton.Font = Enum.Font.GothamBlack
closeButton.TextSize = 16
closeButton.AutoButtonColor = true
closeButton.Parent = panel
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 8)

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Scroll"
scroll.Position = UDim2.fromOffset(18, 56)
scroll.Size = UDim2.new(1, -36, 1, -74)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scroll

local function close()
	if not state.IsOpen then return end
	state.IsOpen = false
	overlay.Visible = false
	screenGui.Enabled = false
end

local function open()
	if state.IsOpen then return end
	state.IsOpen = true
	screenGui.Enabled = true
	overlay.Visible = true
end

closeButton.Activated:Connect(close)

overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local pos = panel.AbsolutePosition
		local size = panel.AbsoluteSize
		local mouse = input.Position
		local inside = mouse.X >= pos.X and mouse.X <= pos.X + size.X and mouse.Y >= pos.Y and mouse.Y <= pos.Y + size.Y
		if not inside then
			close()
		end
	end
end)

local function makeRow(order: number, icon: string, labelKey: string, fallback: string, onTap: () -> ())
	local row = Instance.new("TextButton")
	row.Name = labelKey
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, 52)
	row.BackgroundColor3 = THEME.Panel
	row.BorderSizePixel = 0
	row.AutoButtonColor = true
	row.Text = ""
	row.Parent = scroll
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME.CardStroke
	stroke.Thickness = 1
	stroke.Parent = row

	local iconLabel = Instance.new("TextLabel")
	iconLabel.BackgroundTransparency = 1
	iconLabel.Position = UDim2.fromOffset(14, 0)
	iconLabel.Size = UDim2.fromOffset(28, 52)
	iconLabel.Text = icon
	iconLabel.TextSize = 20
	iconLabel.TextXAlignment = Enum.TextXAlignment.Left
	iconLabel.TextYAlignment = Enum.TextYAlignment.Center
	iconLabel.Parent = row

	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.Position = UDim2.fromOffset(50, 0)
	textLabel.Size = UDim2.new(1, -64, 1, 0)
	textLabel.Text = _g(labelKey, fallback)
	textLabel.TextColor3 = THEME.Text
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 14
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.Parent = row

	row.Activated:Connect(function()
		close()
		onTap()
	end)
end

local function buildRows(panelRefs)
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	if panelRefs.godMode then
		makeRow(1, utf8.char(0x26A1), "god_mode", "God Mode", function()
			overlayManager.show("godMode", panelRefs.godMode.open, panelRefs.godMode.close)
		end)
	end
	if panelRefs.clanWar then
		makeRow(2, utf8.char(0x2694), "clan_war", "Clan War", function()
			overlayManager.show("clanWar", panelRefs.clanWar.open, panelRefs.clanWar.close)
		end)
	end
	if panelRefs.cultWar then
		makeRow(3, utf8.char(0x1F480), "cult_war", "Cult War", function()
			overlayManager.show("cultWar", panelRefs.cultWar.open, panelRefs.cultWar.close)
		end)
	end
	if panelRefs.afk then
		makeRow(4, utf8.char(0x1F4A4), "afk", "AFK Stabilization", function()
			overlayManager.show("afk", panelRefs.afk.open, panelRefs.afk.close)
		end)
	end
end

local function init(panelRefs)
	state.PanelRefs = panelRefs
	buildRows(panelRefs)
end

return { init = init, open = open, close = close }
