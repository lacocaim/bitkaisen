local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local uiState = require("@ui-state/uiState")
local responsiveScale = require("@ui/responsiveScale")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getRivals = ReplicatedStorage:WaitForChild("GetRivals")
local rivalAction = ReplicatedStorage:WaitForChild("RivalAction")

local COLORS = {
	Window = Color3.fromRGB(14, 13, 20),
	Card = Color3.fromRGB(23, 22, 33),
	Card2 = Color3.fromRGB(30, 28, 42),
	Stroke = Color3.fromRGB(83, 67, 104),
	Text = Color3.fromRGB(244, 240, 250),
	SubText = Color3.fromRGB(174, 168, 191),
	Gold = Color3.fromRGB(255, 207, 94),
	Red = Color3.fromRGB(235, 82, 104),
	Purple = Color3.fromRGB(160, 101, 244),
	Green = Color3.fromRGB(112, 224, 153),
	Blue = Color3.fromRGB(104, 178, 246),
	Orange = Color3.fromRGB(244, 142, 86),
}

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenRivalsGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 623
gui.Enabled = false
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "RivalsOverlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.4
overlay.BorderSizePixel = 0
overlay.ZIndex = 623
overlay.Parent = gui

local window = Instance.new("Frame")
window.Name = "RivalsWindow"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.new(0.5, 0, 0.5, 0)
window.BackgroundColor3 = COLORS.Window
window.BorderSizePixel = 0
window.ZIndex = 624
window.Parent = overlay

local function makeCorner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = obj
	return c
end

local function makeStroke(obj, color)
	local s = Instance.new("UIStroke")
	s.Color = color or COLORS.Stroke
	s.Thickness = 1
	s.Transparency = 0.12
	s.Parent = obj
	return s
end

makeCorner(window, 10)
makeStroke(window)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 24, 0, 16)
title.Size = UDim2.new(1, -90, 0, 34)
title.Text = "RIVALS"
title.TextColor3 = COLORS.Gold
title.TextSize = 22
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 625
title.Parent = window

local closeButton = Instance.new("TextButton")
closeButton.Position = UDim2.new(1, -58, 0, 16)
closeButton.Size = UDim2.fromOffset(38, 34)
closeButton.Text = "X"
closeButton.TextColor3 = COLORS.Red
closeButton.TextSize = 16
closeButton.Font = Enum.Font.GothamBlack
closeButton.BackgroundColor3 = Color3.fromRGB(35, 35, 46)
closeButton.BorderSizePixel = 0
closeButton.ZIndex = 626
closeButton.Parent = window
makeCorner(closeButton, 8)

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.new(0, 24, 0, 64)
scroll.Size = UDim2.new(1, -48, 1, -88)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = COLORS.Purple
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ZIndex = 625
scroll.Parent = window

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = scroll

local isOpen = false
local payload = nil
local refresh

responsiveScale.attach(window, 1190, 821)

local function clear()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") and child ~= listLayout then child:Destroy() end
	end
end

local function makeText(parent, value, size, color, y, bold, height)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 14, 0, y)
	label.Size = UDim2.new(1, -28, 0, height or 24)
	label.Text = tostring(value or "")
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

local function card(height, color)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -8, 0, height or 90)
	frame.BackgroundColor3 = color or COLORS.Card
	frame.BorderSizePixel = 0
	frame.ZIndex = 625
	frame.Parent = scroll
	makeCorner(frame, 8)
	makeStroke(frame)
	return frame
end

local function actionButton(parent, text, xScale, y, widthScale, color, callback)
	local btn = Instance.new("TextButton")
	btn.Position = UDim2.new(xScale, 14, 0, y)
	btn.Size = UDim2.new(widthScale, -18, 0, 32)
	btn.BackgroundColor3 = color
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = COLORS.Text
	btn.TextSize = 10
	btn.TextWrapped = true
	btn.Font = Enum.Font.GothamBlack
	btn.ZIndex = parent.ZIndex + 2
	btn.Parent = parent
	makeCorner(btn, 8)
	btn.MouseButton1Click:Connect(callback)
	return btn
end

local function fetch()
	local ok, data = pcall(function() return getRivals:InvokeServer() end)
	payload = ok and typeof(data) == "table" and data or { Rivals = {}, History = {}, ReputationPath = "Unknown" }
	return payload
end

local function fire(actionId, rivalId)
	rivalAction:FireServer(actionId, { RivalId = rivalId })
	task.delay(0.25, function()
		fetch()
		if isOpen then refresh() end
	end)
end

refresh = function()
	clear()
	local data = payload or fetch()

	local summary = card(data.Debug and 132 or 104, COLORS.Card2)
	makeText(summary, "Reputation Path: " .. tostring(data.ReputationPath or "Unknown"), 17, COLORS.Gold, 12, true)
	makeText(summary, "Fame " .. tostring(data.Fame or 0) .. " | Fear " .. tostring(data.Fear or 0) .. " | Wanted " .. tostring(data.WantedLevel or 0) .. " | Hunter Pressure " .. tostring(data.HunterPressure or 0) .. " | Public Support " .. tostring(data.PublicSupport or 0), 11, COLORS.SubText, 44, false, 34)
	local stats = data.Stats or {}
	makeText(summary, "Encounters " .. tostring(stats.Encounters or 0) .. " | Defeated " .. tostring(stats.Defeated or 0) .. " | Losses " .. tostring(stats.Losses or 0) .. " | Escapes " .. tostring(stats.Escapes or 0), 11, COLORS.Green, 82, true, 22)
	if data.Debug then
		actionButton(summary, "TEST RIVAL", 0, 98, 0.34, COLORS.Purple, function()
			rivalAction:FireServer("generate_test_rival", {})
			task.delay(0.25, function() fetch(); if isOpen then refresh() end end)
		end)
	end

	local pending = data.PendingEncounter
	if pending then
		local box = card(150, Color3.fromRGB(41, 26, 32))
		makeText(box, "ACTIVE ENCOUNTER", 14, COLORS.Orange, 12, true)
		makeText(box, tostring(pending.Name) .. " | " .. tostring(pending.Grade) .. " | Threat " .. tostring(pending.Threat), 13, COLORS.Text, 36, true)
		makeText(box, tostring(pending.Reason or "A rival stepped into your path."), 11, COLORS.SubText, 60, false, 34)
		actionButton(box, "FIGHT", 0, 102, 0.25, COLORS.Red, function() fire("fight", pending.RivalId) end)
		actionButton(box, "TALK", 0.25, 102, 0.25, COLORS.Blue, function() fire("talk_down", pending.RivalId) end)
		actionButton(box, "ESCAPE", 0.5, 102, 0.25, COLORS.Purple, function() fire("escape", pending.RivalId) end)
	end

	local rivals = data.Rivals or {}
	if #rivals <= 0 then
		makeText(card(80), "No rivals yet. Fame, fear, clan wars, wanted level, and major combat can draw enemies into your era.", 12, COLORS.SubText, 22, false, 44)
	else
		for _, rival in ipairs(rivals) do
			local box = card(184)
			makeText(box, tostring(rival.Name or "Unknown Rival"), 15, COLORS.Gold, 10, true)
			makeText(box, tostring(rival.Grade or "Unknown") .. " | Age " .. tostring(rival.Age or "?") .. " | " .. tostring(rival.Clan or "No Clan") .. " | " .. tostring(rival.Status or "Active"), 11, COLORS.Purple, 34, true)
			makeText(box, "Technique: " .. tostring(rival.Technique or "Unknown") .. " | Threat: " .. tostring(rival.Threat or 0) .. " | Record: " .. tostring(rival.Wins or 0) .. "W / " .. tostring(rival.Losses or 0) .. "L", 11, COLORS.SubText, 58, false, 26)
			makeText(box, tostring(rival.Relationship or "Enemy") .. ": " .. tostring(rival.Reason or "watching your rise"), 11, COLORS.SubText, 84, false, 34)
			actionButton(box, "INTEL", 0, 130, 0.25, COLORS.Blue, function() fire("intel", rival.Id) end)
			actionButton(box, "FIGHT", 0.25, 130, 0.25, COLORS.Red, function() fire("fight", rival.Id) end)
			actionButton(box, "SPARE", 0.5, 130, 0.25, COLORS.Green, function() fire("spare", rival.Id) end)
			actionButton(box, "HUMILIATE", 0.75, 130, 0.25, COLORS.Orange, function() fire("humiliate", rival.Id) end)
		end
	end

	local history = data.History or {}
	local h = card(110)
	makeText(h, "Rival History", 15, COLORS.Text, 12, true)
	local lines = {}
	for i = 1, math.min(3, #history) do table.insert(lines, tostring(history[i])) end
	makeText(h, #lines > 0 and table.concat(lines, "\n") or "No rival history yet.", 11, COLORS.SubText, 42, false, 56)
end

local function openPanel()
	isOpen = true
	gui.Enabled = true
	fetch()
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
		if route == "rivals" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
