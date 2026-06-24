local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local uiState = require("@ui-state/uiState")
local responsiveScale = require("@ui/responsiveScale")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getWorldHistory = ReplicatedStorage:WaitForChild("GetWorldHistory")
local getTitles = ReplicatedStorage:WaitForChild("GetTitles")

local COLORS = {
	Window = Color3.fromRGB(16, 16, 22),
	Card = Color3.fromRGB(24, 24, 32),
	Stroke = Color3.fromRGB(54, 54, 70),
	Text = Color3.fromRGB(235, 235, 244),
	SubText = Color3.fromRGB(166, 166, 186),
	Gold = Color3.fromRGB(255, 205, 92),
	Blue = Color3.fromRGB(116, 190, 255),
	Green = Color3.fromRGB(122, 236, 165),
	Red = Color3.fromRGB(220, 84, 90),
}

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenWorldHistoryGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 625
gui.Enabled = false
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "WorldHistoryOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.42
overlay.BorderSizePixel = 0
overlay.ZIndex = 625
overlay.Parent = gui

local window = Instance.new("Frame")
window.Name = "WorldHistoryWindow"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.new(0.5, 0, 0.52, 0)
window.Size = UDim2.new(0.58, 0, 0.72, 0)
window.BackgroundColor3 = COLORS.Window
window.BorderSizePixel = 0
window.ZIndex = 626
window.Parent = overlay

local function makeCorner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = obj
end

local function makeStroke(obj)
	local s = Instance.new("UIStroke")
	s.Color = COLORS.Stroke
	s.Thickness = 1
	s.Transparency = 0.15
	s.Parent = obj
end

makeCorner(window, 10)
makeStroke(window)

local titleLabel = Instance.new("TextLabel")
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.new(0, 24, 0, 18)
titleLabel.Size = UDim2.new(1, -86, 0, 30)
titleLabel.Text = "WORLD HISTORY"
titleLabel.TextColor3 = COLORS.Text
titleLabel.TextSize = 22
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 627
titleLabel.Parent = window

local closeButton = Instance.new("TextButton")
closeButton.Position = UDim2.new(1, -58, 0, 16)
closeButton.Size = UDim2.new(0, 38, 0, 34)
closeButton.Text = "X"
closeButton.TextColor3 = COLORS.Red
closeButton.TextSize = 16
closeButton.Font = Enum.Font.GothamBlack
closeButton.BackgroundColor3 = Color3.fromRGB(35, 35, 46)
closeButton.BorderSizePixel = 0
closeButton.ZIndex = 628
closeButton.Parent = window
makeCorner(closeButton, 8)

local historyTab = Instance.new("TextButton")
historyTab.Position = UDim2.new(0, 24, 0, 54)
historyTab.Size = UDim2.new(0, 100, 0, 28)
historyTab.Text = "HISTORY"
historyTab.TextColor3 = COLORS.Gold
historyTab.TextSize = 12
historyTab.Font = Enum.Font.GothamBlack
historyTab.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
historyTab.BorderSizePixel = 0
historyTab.ZIndex = 628
historyTab.Parent = window
makeCorner(historyTab, 7)

local titlesTab = Instance.new("TextButton")
titlesTab.Position = UDim2.new(0, 132, 0, 54)
titlesTab.Size = UDim2.new(0, 80, 0, 28)
titlesTab.Text = "TITLES"
titlesTab.TextColor3 = COLORS.SubText
titlesTab.TextSize = 12
titlesTab.Font = Enum.Font.GothamBlack
titlesTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
titlesTab.BorderSizePixel = 0
titlesTab.ZIndex = 628
titlesTab.Parent = window
makeCorner(titlesTab, 7)

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.new(0, 24, 0, 92)
scroll.Size = UDim2.new(1, -48, 1, -116)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = COLORS.Blue
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ZIndex = 627
scroll.Parent = window

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = scroll

local isOpen = false
local activeTab = "history"

responsiveScale.attach(window, 1114, 778)

local function clear()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
end

local function text(parent, value, size, color, y, bold)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 14, 0, y)
	label.Size = UDim2.new(1, -28, 0, 22)
	label.Text = value or ""
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

local function card(height)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -8, 0, height or 84)
	frame.BackgroundColor3 = COLORS.Card
	frame.BorderSizePixel = 0
	frame.ZIndex = 627
	frame.Parent = scroll
	makeCorner(frame, 8)
	makeStroke(frame)
	return frame
end

local function updateTabStyles()
	if activeTab == "history" then
		historyTab.TextColor3 = COLORS.Gold
		historyTab.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
		titlesTab.TextColor3 = COLORS.SubText
		titlesTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		titleLabel.Text = "WORLD HISTORY"
	else
		historyTab.TextColor3 = COLORS.SubText
		historyTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		titlesTab.TextColor3 = COLORS.Gold
		titlesTab.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
		titleLabel.Text = "TITLES"
	end
end

local function renderHistory()
	clear()
	updateTabStyles()
	local ok, data = pcall(function() return getWorldHistory:InvokeServer() end)
	if not ok or typeof(data) ~= "table" then
		text(card(70), "Could not load world history.", 13, COLORS.Red, 20, true)
		return
	end

	local summary = data.Summary or {}
	local top = card(128)
	text(top, "Era: " .. tostring(summary.Era or "Unknown") .. " | World Events: " .. tostring(summary.WorldEvents or 0) .. " | Notable Births: " .. tostring(summary.NotableBirths or 0), 12, COLORS.Gold, 14, true)
	text(top, "Strongest sorcerer of your era: " .. tostring(summary.StrongestSorcerer or "Unknown"), 12, COLORS.SubText, 42, false)

	local clanWarText = "Clan War Record: " .. tostring(summary.ClanWarWins or 0) .. "W / " .. tostring(summary.ClanWarLosses or 0) .. "L"
	if summary.ClanWarActive == true then
		clanWarText ..= " | Active vs " .. tostring(summary.ClanWarRival or "Rival Clan") .. " (" .. tostring(summary.ClanWarTension or 0) .. "% tension)"
	end

	local equippedToolText = summary.EquippedCursedToolName or summary.EquippedCursedToolId or "None"
	text(top, "Cursed Tools Owned: " .. tostring(summary.CursedToolsOwned or 0) .. " | Equipped: " .. tostring(equippedToolText), 11, COLORS.Blue, 68, false)
	text(top, clanWarText, 11, COLORS.SubText, 94, false)

	for _, entry in ipairs(data.History or {}) do
		local c = card(92)
		text(c, tostring(entry.Year or "?") .. " | " .. tostring(entry.Type or "World"), 12, COLORS.Blue, 12, true)
		text(c, tostring(entry.Text or "Unknown event"), 12, COLORS.Text, 38, false)
	end
end

local function renderTitles()
	clear()
	updateTabStyles()
	local ok, data = pcall(function() return getTitles:InvokeServer() end)
	if not ok or typeof(data) ~= "table" then
		text(card(70), "Could not load titles.", 13, COLORS.Red, 20, true)
		return
	end

	for _, item in ipairs(data.Titles or {}) do
		local c = card(88)
		local unlocked = item.Unlocked == true
		text(c, tostring(item.Name or "???"), 14, unlocked and COLORS.Green or COLORS.SubText, 12, true)
		text(c, unlocked and "Unlocked" or "Locked", 11, unlocked and COLORS.Green or COLORS.Red, 38, true)
		text(c, tostring(item.Requirement or "Requirement hidden."), 11, COLORS.SubText, 58, false)
	end
end

historyTab.MouseButton1Click:Connect(function()
	if activeTab ~= "history" then
		activeTab = "history"
		renderHistory()
	end
end)

titlesTab.MouseButton1Click:Connect(function()
	if activeTab ~= "titles" then
		activeTab = "titles"
		renderTitles()
	end
end)

local function openPanel()
	isOpen = true
	activeTab = "history"
	gui.Enabled = true
	renderHistory()
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
		if route == "history" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
