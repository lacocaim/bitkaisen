local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local uiState = require("@ui-state/uiState")
local responsiveScale = require("@ui/responsiveScale")
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _wh(key, fallback) return BitKaisenLocale.tOrFallback(_L, "world_history." .. key, nil, fallback) end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getWorldHistory = ReplicatedStorage:WaitForChild("GetWorldHistory")
local getTitles = ReplicatedStorage:WaitForChild("GetTitles")
local getPastLives = ReplicatedStorage:WaitForChild("GetPastLives", 5)

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
titleLabel.Text = _wh("title", "WORLD HISTORY")
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
historyTab.Text = _wh("tab_history", "HISTORY")
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
titlesTab.Text = _wh("tab_titles", "TITLES")
titlesTab.TextColor3 = COLORS.SubText
titlesTab.TextSize = 12
titlesTab.Font = Enum.Font.GothamBlack
titlesTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
titlesTab.BorderSizePixel = 0
titlesTab.ZIndex = 628
titlesTab.Parent = window
makeCorner(titlesTab, 7)

local livesTab = Instance.new("TextButton")
livesTab.Position = UDim2.new(0, 220, 0, 54)
livesTab.Size = UDim2.new(0, 100, 0, 28)
livesTab.Text = _wh("tab_cemetery", "CEMETERY")
livesTab.TextColor3 = COLORS.SubText
livesTab.TextSize = 12
livesTab.Font = Enum.Font.GothamBlack
livesTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
livesTab.BorderSizePixel = 0
livesTab.ZIndex = 628
livesTab.Parent = window
makeCorner(livesTab, 7)

local influenceTab = Instance.new("TextButton")
influenceTab.Position = UDim2.new(0, 328, 0, 54)
influenceTab.Size = UDim2.new(0, 100, 0, 28)
influenceTab.Text = _wh("tab_influence", "INFLUENCE")
influenceTab.TextColor3 = COLORS.SubText
influenceTab.TextSize = 12
influenceTab.Font = Enum.Font.GothamBlack
influenceTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
influenceTab.BorderSizePixel = 0
influenceTab.ZIndex = 628
influenceTab.Parent = window
makeCorner(influenceTab, 7)

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

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingTop = UDim.new(0, 12)
scrollPadding.PaddingBottom = UDim.new(0, 12)
scrollPadding.Parent = scroll

local isOpen = false
local activeTab = "history"
local rendering = false

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

local RIBBON_COLORS = {
	["LEGEND OF THE CURSED WORLD"] = Color3.fromRGB(255, 200, 50),
	["SPECIAL GRADE SORCERER"] = Color3.fromRGB(220, 160, 255),
	["CURSE USER KING"] = Color3.fromRGB(200, 60, 80),
	["FEARED CURSE USER"] = Color3.fromRGB(180, 40, 60),
	["CURSE USER"] = Color3.fromRGB(200, 80, 90),
	["CURSED SPIRIT"] = Color3.fromRGB(140, 80, 200),
	["ELITE JUJUTSU SORCERER"] = Color3.fromRGB(120, 200, 255),
	["DOMAIN USER"] = Color3.fromRGB(140, 120, 255),
	["RCT PRACTITIONER"] = Color3.fromRGB(100, 220, 180),
	["CLAN FOUNDER"] = Color3.fromRGB(255, 180, 60),
	["DEEP BLOODLINE"] = Color3.fromRGB(180, 140, 255),
	["VETERAN SORCERER"] = Color3.fromRGB(120, 200, 140),
	["GRADE 1 SORCERER"] = Color3.fromRGB(100, 180, 255),
	["LONG LIFE"] = Color3.fromRGB(160, 160, 180),
	["LIFE CUT SHORT"] = Color3.fromRGB(180, 180, 200),
	["CELEBRATED SORCERER"] = Color3.fromRGB(255, 220, 80),
	["ORDINARY LIFE"] = Color3.fromRGB(140, 140, 160),
}

local function updateTabStyles()
	local inactive = { color = COLORS.SubText, bg = Color3.fromRGB(30, 30, 40) }
	local active = { color = COLORS.Gold, bg = Color3.fromRGB(40, 40, 52) }
	historyTab.TextColor3 = (activeTab == "history" and active or inactive).color
	historyTab.BackgroundColor3 = (activeTab == "history" and active or inactive).bg
	titlesTab.TextColor3 = (activeTab == "titles" and active or inactive).color
	titlesTab.BackgroundColor3 = (activeTab == "titles" and active or inactive).bg
	livesTab.TextColor3 = (activeTab == "lives" and active or inactive).color
	livesTab.BackgroundColor3 = (activeTab == "lives" and active or inactive).bg
	influenceTab.TextColor3 = (activeTab == "influence" and active or inactive).color
	influenceTab.BackgroundColor3 = (activeTab == "influence" and active or inactive).bg
	if activeTab == "history" then titleLabel.Text = _wh("title", "WORLD HISTORY")
	elseif activeTab == "titles" then titleLabel.Text = _wh("tab_titles", "TITLES")
	elseif activeTab == "lives" then titleLabel.Text = _wh("title_lives", "CEMETERY OF LIVES")
	else titleLabel.Text = _wh("tab_influence", "INFLUENCE") end
end

local function renderHistory()
	rendering = true
	clear()
	updateTabStyles()
	local ok, data = pcall(function() return getWorldHistory:InvokeServer() end)
	rendering = false
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
	rendering = true
	clear()
	updateTabStyles()
	local ok, data = pcall(function() return getTitles:InvokeServer() end)
	rendering = false
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

local function makeTombstone(parent, lifeData, index)
	local ribColor = RIBBON_COLORS[lifeData.Ribbon] or Color3.fromRGB(140, 140, 160)
	local stoneColor = Color3.fromRGB(36, 32, 50)

	-- outer wrapper
	local wrap = Instance.new("Frame")
	wrap.Size = UDim2.new(0, 160, 0, 296)
	wrap.BackgroundTransparency = 1
	wrap.BorderSizePixel = 0
	wrap.ZIndex = 627
	wrap.LayoutOrder = index
	wrap.Parent = parent

	-- main tombstone body (rounded top only trick: full rounded + square bottom overlay)
	local stone = Instance.new("Frame")
	stone.Size = UDim2.new(1, 0, 1, -16)
	stone.Position = UDim2.new(0, 0, 0, 0)
	stone.BackgroundColor3 = stoneColor
	stone.BorderSizePixel = 0
	stone.ZIndex = 628
	stone.Parent = wrap
	local stoneCorner = Instance.new("UICorner")
	stoneCorner.CornerRadius = UDim.new(0, 32)  -- arch feel at top
	stoneCorner.Parent = stone
	local stoneStroke = Instance.new("UIStroke")
	stoneStroke.Color = ribColor
	stoneStroke.Thickness = 2
	stoneStroke.Transparency = 0.3
	stoneStroke.Parent = stone

	-- square off the bottom corners (overlay)
	local squareBottom = Instance.new("Frame")
	squareBottom.Size = UDim2.new(1, 0, 0.4, 0)
	squareBottom.Position = UDim2.new(0, 0, 0.6, 0)
	squareBottom.BackgroundColor3 = stoneColor
	squareBottom.BorderSizePixel = 0
	squareBottom.ZIndex = 628
	squareBottom.Parent = stone

	-- base slab
	local base = Instance.new("Frame")
	base.Size = UDim2.new(1.2, 0, 0, 12)
	base.Position = UDim2.new(-0.1, 0, 1, -12)
	base.BackgroundColor3 = Color3.fromRGB(26, 22, 38)
	base.BorderSizePixel = 0
	base.ZIndex = 629
	base.Parent = wrap
	local baseCorner = Instance.new("UICorner")
	baseCorner.CornerRadius = UDim.new(0, 3)
	baseCorner.Parent = base

	-- cross (vertical bar)
	local crossV = Instance.new("Frame")
	crossV.Size = UDim2.new(0, 8, 0, 34)
	crossV.Position = UDim2.new(0.5, -4, 0, 28)
	crossV.BackgroundColor3 = ribColor
	crossV.BackgroundTransparency = 0
	crossV.BorderSizePixel = 0
	crossV.ZIndex = 630
	crossV.Parent = stone
	local cvc = Instance.new("UICorner"); cvc.CornerRadius = UDim.new(0, 4); cvc.Parent = crossV

	-- cross (horizontal bar)
	local crossH = Instance.new("Frame")
	crossH.Size = UDim2.new(0, 44, 0, 8)
	crossH.Position = UDim2.new(0.5, -22, 0, 38)
	crossH.BackgroundColor3 = ribColor
	crossH.BackgroundTransparency = 0
	crossH.BorderSizePixel = 0
	crossH.ZIndex = 630
	crossH.Parent = stone
	local chc = Instance.new("UICorner"); chc.CornerRadius = UDim.new(0, 4); chc.Parent = crossH

	-- divider line
	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(0.7, 0, 0, 1)
	divider.Position = UDim2.new(0.15, 0, 0, 78)
	divider.BackgroundColor3 = ribColor
	divider.BackgroundTransparency = 0.4
	divider.BorderSizePixel = 0
	divider.ZIndex = 630
	divider.Parent = stone

	-- name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(1, -10, 0, 40)
	nameLabel.Position = UDim2.new(0, 5, 0, 84)
	nameLabel.Text = tostring(lifeData.Name or "Unknown")
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.TextWrapped = true
	nameLabel.ZIndex = 630
	nameLabel.Parent = stone

	-- ribbon
	local ribLabel = Instance.new("TextLabel")
	ribLabel.BackgroundTransparency = 1
	ribLabel.Size = UDim2.new(1, -10, 0, 32)
	ribLabel.Position = UDim2.new(0, 5, 0, 124)
	ribLabel.Text = tostring(lifeData.Ribbon or "ORDINARY LIFE")
	ribLabel.TextColor3 = ribColor
	ribLabel.TextSize = 13
	ribLabel.Font = Enum.Font.GothamBlack
	ribLabel.TextXAlignment = Enum.TextXAlignment.Center
	ribLabel.TextWrapped = true
	ribLabel.ZIndex = 630
	ribLabel.Parent = stone

	-- age · grade
	local ageLabel = Instance.new("TextLabel")
	ageLabel.BackgroundTransparency = 1
	ageLabel.Size = UDim2.new(1, -10, 0, 34)
	ageLabel.Position = UDim2.new(0, 5, 0, 156)
	ageLabel.Text = "Age " .. tostring(lifeData.Age or 0) .. "  ·  " .. tostring(lifeData.Grade or "Unranked")
	ageLabel.TextColor3 = COLORS.SubText
	ageLabel.TextSize = 12
	ageLabel.Font = Enum.Font.Gotham
	ageLabel.TextXAlignment = Enum.TextXAlignment.Center
	ageLabel.TextWrapped = true
	ageLabel.ZIndex = 630
	ageLabel.Parent = stone

	-- clan
	local clanLabel = Instance.new("TextLabel")
	clanLabel.BackgroundTransparency = 1
	clanLabel.Size = UDim2.new(1, -10, 0, 18)
	clanLabel.Position = UDim2.new(0, 5, 0, 192)
	clanLabel.Text = tostring(lifeData.Clan or "")
	clanLabel.TextColor3 = Color3.fromRGB(180, 168, 210)
	clanLabel.TextSize = 12
	clanLabel.Font = Enum.Font.Gotham
	clanLabel.TextXAlignment = Enum.TextXAlignment.Center
	clanLabel.ZIndex = 630
	clanLabel.Parent = stone

	-- technique · missions
	local techLabel = Instance.new("TextLabel")
	techLabel.BackgroundTransparency = 1
	techLabel.Size = UDim2.new(1, -10, 0, 18)
	techLabel.Position = UDim2.new(0, 5, 0, 212)
	techLabel.Text = "Technique: " .. tostring(lifeData.Technique or "None") .. "  ·  Missions: " .. tostring(lifeData.Missions or 0)
	techLabel.TextColor3 = COLORS.SubText
	techLabel.TextSize = 12
	techLabel.Font = Enum.Font.Gotham
	techLabel.TextXAlignment = Enum.TextXAlignment.Center
	techLabel.TextWrapped = true
	techLabel.ZIndex = 630
	techLabel.Parent = stone

	-- index number at bottom
	local numLabel = Instance.new("TextLabel")
	numLabel.BackgroundTransparency = 1
	numLabel.Size = UDim2.new(1, 0, 0, 20)
	numLabel.Position = UDim2.new(0, 0, 0, 236)
	numLabel.Text = "— #" .. tostring(index) .. " —"
	numLabel.TextColor3 = Color3.fromRGB(120, 108, 155)
	numLabel.TextSize = 13
	numLabel.Font = Enum.Font.GothamBlack
	numLabel.TextXAlignment = Enum.TextXAlignment.Center
	numLabel.ZIndex = 630
	numLabel.Parent = stone
end

local function renderLives()
	rendering = true
	clear()
	updateTabStyles()
	if not getPastLives then
		rendering = false
		text(card(70), "Cemetery unavailable — rejoin to enable it.", 13, COLORS.SubText, 20, false)
		return
	end
	local ok, data = pcall(function() return getPastLives:InvokeServer() end)
	rendering = false
	if not ok or typeof(data) ~= "table" then
		text(card(70), "Could not load past lives.", 13, COLORS.Red, 20, true)
		return
	end

	local lives = data.PastLives or {}
	if #lives == 0 then
		local c = card(80)
		text(c, "⚰  No past lives recorded yet.", 14, COLORS.SubText, 16, true)
		text(c, "Start a new life to begin your cemetery.", 12, COLORS.SubText, 42, false)
		return
	end

	-- grid container
	local grid = Instance.new("Frame")
	grid.Size = UDim2.new(1, -8, 0, 0)
	grid.AutomaticSize = Enum.AutomaticSize.Y
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.ZIndex = 627
	grid.LayoutOrder = 1
	grid.Parent = scroll

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 170, 0, 316)
	gridLayout.CellPadding = UDim2.new(0, 20, 0, 32)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.Parent = grid

	for i, life in ipairs(lives) do
		makeTombstone(grid, life, i)
	end
end

local function makeStatBar(parent, label, value, barColor, yOffset)
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, -28, 0, 38)
	bg.Position = UDim2.new(0, 14, 0, yOffset)
	bg.BackgroundTransparency = 1
	bg.BorderSizePixel = 0
	bg.ZIndex = parent.ZIndex + 1
	bg.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(0.5, 0, 0, 18)
	lbl.Position = UDim2.new(0, 0, 0, 0)
	lbl.Text = label
	lbl.TextColor3 = COLORS.Text
	lbl.TextSize = 12
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = bg.ZIndex + 1
	lbl.Parent = bg

	local valLbl = Instance.new("TextLabel")
	valLbl.BackgroundTransparency = 1
	valLbl.Size = UDim2.new(0.5, 0, 0, 18)
	valLbl.Position = UDim2.new(0.5, 0, 0, 0)
	valLbl.Text = tostring(math.floor(value)) .. " / 100"
	valLbl.TextColor3 = barColor
	valLbl.TextSize = 12
	valLbl.Font = Enum.Font.GothamBlack
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.ZIndex = bg.ZIndex + 1
	valLbl.Parent = bg

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, 0, 0, 10)
	track.Position = UDim2.new(0, 0, 0, 22)
	track.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
	track.BorderSizePixel = 0
	track.ZIndex = bg.ZIndex + 1
	track.Parent = bg
	local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 5); tc.Parent = track

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(math.clamp(value / 100, 0, 1), 0, 1, 0)
	fill.BackgroundColor3 = barColor
	fill.BorderSizePixel = 0
	fill.ZIndex = bg.ZIndex + 2
	fill.Parent = track
	local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0, 5); fc.Parent = fill
end

local function renderInfluence()
	rendering = true
	clear()
	updateTabStyles()
	local ok, data = pcall(function() return getWorldHistory:InvokeServer() end)
	rendering = false
	if not ok or typeof(data) ~= "table" then
		text(card(70), "Could not load influence data.", 13, COLORS.Red, 20, true)
		return
	end
	local s = data.Summary or {}

	local fame   = tonumber(s.Fame) or 0
	local fear   = tonumber(s.Fear) or 0
	local attn   = tonumber(s.WorldAttention) or 0
	local press  = tonumber(s.WorldPressure) or 0
	local soc    = tonumber(s.SocietyInfluence) or 0
	local wanted = tonumber(s.WantedLevel) or 0

	-- description card
	local descCard = card(64)
	text(descCard, "How the world perceives you — built from your actions, missions, and reputation.", 12, COLORS.SubText, 14, false)
	text(descCard, "Fame and Fear grow silently as you live your life.", 11, COLORS.SubText, 36, false)

	-- fame card
	local fameCard = card(110)
	text(fameCard, "⭐  FAME", 13, COLORS.Gold, 12, true)
	text(fameCard, fame >= 75 and "Celebrated across the jujutsu world." or fame >= 40 and "Your name is known in sorcerer circles." or "Still unknown to most.", 11, COLORS.SubText, 36, false)
	makeStatBar(fameCard, "Fame", fame, COLORS.Gold, 58)

	-- fear card
	local fearCard = card(110)
	text(fearCard, "💀  FEAR", 13, COLORS.Red, 12, true)
	text(fearCard, fear >= 75 and "Enemies flee when they hear your name." or fear >= 40 and "Your presence unsettles those who know you." or "You haven't yet made them afraid.", 11, COLORS.SubText, 36, false)
	makeStatBar(fearCard, "Fear", fear, COLORS.Red, 58)

	-- combined stats card
	local combinedCard = card(190)
	text(combinedCard, "WORLD PRESENCE", 13, COLORS.Blue, 12, true)
	makeStatBar(combinedCard, "World Attention", attn, COLORS.Blue, 38)
	makeStatBar(combinedCard, "World Pressure", press, Color3.fromRGB(255, 160, 60), 86)
	makeStatBar(combinedCard, "Society Influence", soc, Color3.fromRGB(180, 130, 255), 134)

	-- wanted
	local wantedCard = card(72)
	text(wantedCard, "Wanted Level:  " .. tostring(wanted), 13, wanted >= 50 and COLORS.Red or COLORS.SubText, 14, true)
	text(wantedCard, wanted >= 70 and "Hunter squads are actively tracking you." or wanted >= 30 and "Authorities have flagged you as a person of interest." or "You are not currently a target.", 11, COLORS.SubText, 38, false)
end

historyTab.MouseButton1Click:Connect(function()
	if activeTab ~= "history" and not rendering then
		activeTab = "history"
		renderHistory()
	end
end)

titlesTab.MouseButton1Click:Connect(function()
	if activeTab ~= "titles" and not rendering then
		activeTab = "titles"
		renderTitles()
	end
end)

livesTab.MouseButton1Click:Connect(function()
	if activeTab ~= "lives" and not rendering then
		activeTab = "lives"
		renderLives()
	end
end)

influenceTab.MouseButton1Click:Connect(function()
	if activeTab ~= "influence" and not rendering then
		activeTab = "influence"
		renderInfluence()
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
