local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local uiState = require("@ui-state/uiState")
local responsiveScale = require("@ui/responsiveScale")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getMentor = ReplicatedStorage:WaitForChild("GetMentor")
local mentorAction = ReplicatedStorage:WaitForChild("MentorAction")

local THEME = {
	Bg = Color3.fromRGB(8, 8, 13),
	Panel = Color3.fromRGB(15, 15, 23),
	Card = Color3.fromRGB(20, 20, 29),
	Stroke = Color3.fromRGB(58, 52, 76),
	Text = Color3.fromRGB(242, 240, 250),
	SubText = Color3.fromRGB(168, 164, 186),
	Gold = Color3.fromRGB(255, 204, 102),
	Green = Color3.fromRGB(105, 225, 145),
	Blue = Color3.fromRGB(95, 165, 255),
	Purple = Color3.fromRGB(178, 120, 255),
}

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenMentorGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 626
gui.Enabled = false
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "MentorOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.35
overlay.ZIndex = 626
overlay.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "MentorPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Size = UDim2.new(0, 480, 0, 540)
panel.BackgroundColor3 = THEME.Panel
panel.BorderSizePixel = 0
panel.ZIndex = 627
panel.Parent = overlay

responsiveScale.attach(panel, 480, 540)

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = THEME.Stroke
panelStroke.Thickness = 1.5
panelStroke.Parent = panel

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -16, 0, 36)
titleLabel.Position = UDim2.new(0, 8, 0, 8)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 20
titleLabel.TextColor3 = THEME.Blue
titleLabel.Text = "JUJUTSU MENTOR"
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 628
titleLabel.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.Size = UDim2.new(0, 32, 0, 32)
closeButton.Position = UDim2.new(1, -40, 0, 8)
closeButton.BackgroundColor3 = THEME.Card
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
closeButton.TextColor3 = THEME.Text
closeButton.Text = "X"
closeButton.ZIndex = 629
closeButton.Parent = panel
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 8)

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Content"
scroll.Size = UDim2.new(1, -16, 1, -52)
scroll.Position = UDim2.new(0, 8, 0, 48)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = THEME.Stroke
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ZIndex = 628
scroll.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = scroll

local isOpen = false

local function createLine(lineText, order, color, bold)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 22)
	label.BackgroundTransparency = 1
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextColor3 = color or THEME.Text
	label.Text = lineText
	label.RichText = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.LayoutOrder = order
	label.ZIndex = 629
	label.TextWrapped = true
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Parent = scroll
	return label
end

local function createButton(btnText, order, color, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 38)
	btn.BackgroundColor3 = color or THEME.Blue
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 15
	btn.TextColor3 = THEME.Text
	btn.Text = btnText
	btn.LayoutOrder = order
	btn.ZIndex = 629
	btn.AutoButtonColor = true
	btn.Parent = scroll
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	btn.MouseButton1Click:Connect(callback)
	return btn
end

local function clearContent()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function refresh()
	local ok, payload = pcall(function()
		return getMentor:InvokeServer()
	end)

	if not ok or not payload then return end

	clearContent()

	if payload.IsMentor then
		createLine("Status: <b>Active Jujutsu Mentor</b>", 1, THEME.Blue, true)
		createLine("Rank: <b>" .. tostring(payload.MentorRank or "None") .. "</b>", 2, THEME.Gold, false)
		createLine("Mentor XP: <b>" .. tostring(payload.MentorXP or 0) .. "</b>" .. (payload.NextRank and (" / " .. tostring(payload.NextRank.MinXP) .. " for " .. payload.NextRank.Id) or " (Max Rank)"), 3, THEME.Text, false)
		createLine("Yearly Income: <b>$" .. tostring(payload.MentorIncome or 0) .. "</b>", 4, THEME.Green, false)
		createLine("Students Mentored: <b>" .. tostring(payload.StudentsMentored or 0) .. "</b>", 5, THEME.SubText, false)
		createLine("", 6, THEME.SubText, false)
		createLine("Use <b>Mentor activities</b> in the Activities menu to earn XP and rank up.", 7, THEME.SubText, false)
	else
		createLine("You are not a Jujutsu Mentor yet.", 1, THEME.SubText, true)

		if payload.CanApply then
			createLine("", 2, THEME.SubText, false)
			createLine("Requirements met! You can apply to become a Jujutsu Mentor.", 3, THEME.Green, false)
			createButton("Apply to Become a Mentor", 4, THEME.Blue, function()
				mentorAction:FireServer("apply")
			end)
		else
			createLine("", 2, THEME.SubText, false)
			createLine("Cannot apply: " .. tostring(payload.ApplyReason or "Unknown reason."), 3, THEME.SubText, false)
			createLine("", 4, THEME.SubText, false)
			createLine("Requirements: Graduate JJH, Age 20+, Grade 2+, recommendations.", 5, THEME.SubText, false)
		end
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

mentorAction.OnClientEvent:Connect(function()
	if isOpen then
		refresh()
	end
end)

local function init()
	uiState.subscribe(function(route)
		if route == "mentor" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
