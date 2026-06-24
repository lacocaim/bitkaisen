local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local uiState = require("@ui-state/uiState")
local responsiveScale = require("@ui/responsiveScale")
local playerState = require("@ui-state/playerState")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getMissionBoard = ReplicatedStorage:WaitForChild("GetMissionBoard")
local updateLifeEvent = ReplicatedStorage:WaitForChild("UpdateLifeEvent")

local THEME = {
	Bg = Color3.fromRGB(7, 7, 10),
	Panel = Color3.fromRGB(15, 15, 22),
	Panel2 = Color3.fromRGB(20, 20, 30),
	Card = Color3.fromRGB(20, 20, 30),
	Stroke = Color3.fromRGB(48, 48, 64),
	Text = Color3.fromRGB(238, 238, 248),
	SubText = Color3.fromRGB(165, 165, 185),
	Muted = Color3.fromRGB(105, 105, 125),
	Gold = Color3.fromRGB(255, 205, 105),
	Red = Color3.fromRGB(145, 32, 45),
	RedDark = Color3.fromRGB(82, 20, 28),
	Purple = Color3.fromRGB(178, 122, 255),
	Bad = Color3.fromRGB(230, 75, 90),
}

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenMissionsGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 620
gui.Enabled = false
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "MissionsOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.35
overlay.ZIndex = 620
overlay.Parent = gui

local window = Instance.new("Frame")
window.Name = "MissionsWindow"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.BackgroundColor3 = THEME.Panel
window.BorderSizePixel = 0
window.ZIndex = 621
window.Parent = overlay

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = window

local stroke = Instance.new("UIStroke")
stroke.Color = THEME.Stroke
stroke.Thickness = 1
stroke.Parent = window

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Text = "AVAILABLE MISSIONS"
title.TextColor3 = THEME.Text
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.Position = UDim2.new(0, 24, 0, 18)
title.Size = UDim2.new(1, -90, 0, 30)
title.TextSize = 23
title.ZIndex = 622
title.Parent = window

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.TextColor3 = THEME.SubText
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextWrapped = true
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Position = UDim2.new(0, 24, 0, 50)
subtitle.Size = UDim2.new(1, -48, 0, 32)
subtitle.TextSize = 12
subtitle.ZIndex = 622
subtitle.Parent = window

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.BackgroundColor3 = Color3.fromRGB(34, 35, 48)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = THEME.Bad
closeButton.Font = Enum.Font.GothamBlack
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -56, 0, 16)
closeButton.TextSize = 19
closeButton.ZIndex = 623
closeButton.Parent = window
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 8)

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "MissionsScroll"
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarImageColor3 = THEME.Purple
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Position = UDim2.new(0, 24, 0, 92)
scroll.Size = UDim2.new(1, -48, 1, -110)
scroll.ScrollBarThickness = 5
scroll.ZIndex = 622
scroll.Parent = window

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 10)
layout.Parent = scroll

local isOpen = false

local function viewport()
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local function mobile()
	local v = viewport()
	return UserInputService.TouchEnabled or v.X < 900
end

responsiveScale.attach(window, 1114, 756)

local function clear()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
end

local function addText(parent, text, size, color, pos, box, bold)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextSize = size
	label.Font = bold and Enum.Font.GothamBlack or Enum.Font.GothamMedium
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Position = pos
	label.Size = box
	label.ZIndex = parent.ZIndex + 1
	label.Parent = parent
	return label
end

local function createMessageCard(text, color)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -10, 0, 112)
	card.BackgroundColor3 = THEME.Panel2
	card.BorderSizePixel = 0
	card.ZIndex = 623
	card.Parent = scroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = THEME.Stroke
	cardStroke.Thickness = 1
	cardStroke.Parent = card

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

local function getMissionEmptyMessage()
	local stats = playerState.stats()
	if not stats then return "No missions available.\nLoading your sorcerer profile..." end

	local age = tonumber(stats.Age) or 0
	local grade = tostring(stats.Grade or "Non-Sorcerer")
	local technique = tostring(stats.CursedTechnique or "None")
	local innateTechnique = tostring(stats.InnateTechnique or "None")
	local hasTechnique = technique ~= "None" or innateTechnique ~= "None"
		or stats.TechniqueKnown == true or stats.TechniqueAwakened == true
		or stats.TechniqueUsable == true
	local isUnregistered = string.sub(grade, 1, 13) == "Unregistered "
	local isOfficialSorcerer = (stats.InJujutsuHigh == true or stats.RegisteredSorcerer == true)
		and not isUnregistered

	if age < 16 then return "No official missions available.\nYou need to be at least 16." end
	if not hasTechnique then return "No missions available.\nAwaken a cursed technique first." end
	if not isOfficialSorcerer then
		if isUnregistered then
			return "No official missions available.\nApply to Jujutsu High to register your " .. grade .. "."
		end
		return "No official missions available.\nApply to Jujutsu High and become a registered sorcerer first."
	end
	if stats.TechniqueUsable == false then
		return "No missions available.\nYour technique exists, but it is not usable in missions yet."
	end
	return "No missions available.\nCheck your official grade or try again later."
end

local function createMissionCard(missionData)
	local isMobile = mobile()
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -10, 0, isMobile and 124 or 116)
	card.BackgroundColor3 = THEME.Panel2
	card.BorderSizePixel = 0
	card.ZIndex = 623
	card.Parent = scroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = THEME.Stroke
	cardStroke.Thickness = 1
	cardStroke.Parent = card

	local riskColor = missionData.RiskColor or THEME.Muted

	local accent = Instance.new("Frame")
	accent.Name = "RiskAccent"
	accent.Size = UDim2.new(0, 5, 1, -24)
	accent.Position = UDim2.new(0, 12, 0, 11)
	accent.BackgroundColor3 = riskColor
	accent.BorderSizePixel = 0
	accent.ZIndex = 624
	accent.Parent = card
	Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 999)

	local missionName = Instance.new("TextLabel")
	missionName.Size = UDim2.new(1, -190, 0, 28)
	missionName.Position = UDim2.new(0, 28, 0, 14)
	missionName.BackgroundTransparency = 1
	missionName.TextColor3 = THEME.Text
	missionName.TextSize = isMobile and 15 or 18
	missionName.Font = Enum.Font.GothamBlack
	missionName.TextXAlignment = Enum.TextXAlignment.Left
	missionName.Text = tostring(missionData.Title or "Unknown Mission")
	missionName.ZIndex = 624
	missionName.Parent = card

	local missionRisk = Instance.new("TextLabel")
	missionRisk.Size = UDim2.new(1, -190, 0, 22)
	missionRisk.Position = UDim2.new(0, 28, 0, 45)
	missionRisk.BackgroundTransparency = 1
	missionRisk.TextColor3 = riskColor
	missionRisk.TextSize = isMobile and 11 or 13
	missionRisk.Font = Enum.Font.GothamBlack
	missionRisk.TextXAlignment = Enum.TextXAlignment.Left
	missionRisk.Text = "RISK \u{2022} " .. tostring(missionData.Grade or "Unknown")
	missionRisk.ZIndex = 624
	missionRisk.Parent = card

	local rewardText = missionData.RewardText
	if not rewardText or rewardText == "" then
		local rewardRep = tonumber(missionData.RewardRep) or 0
		local repText = "Rep +" .. tostring(rewardRep)
		if rewardRep < 0 then repText = "Rep " .. tostring(rewardRep) end
		rewardText = "CE +" .. tostring(missionData.RewardCE or 0)
			.. " \u{2022} $" .. tostring(missionData.RewardMoney or 0)
			.. " \u{2022} " .. repText
	end

	local missionReward = Instance.new("TextLabel")
	missionReward.Size = UDim2.new(1, -190, 0, 36)
	missionReward.Position = UDim2.new(0, 28, 0, 70)
	missionReward.BackgroundTransparency = 1
	missionReward.TextColor3 = THEME.SubText
	missionReward.TextSize = isMobile and 10 or 12
	missionReward.Font = Enum.Font.GothamMedium
	missionReward.TextWrapped = true
	missionReward.TextXAlignment = Enum.TextXAlignment.Left
	missionReward.TextYAlignment = Enum.TextYAlignment.Top
	missionReward.Text = "Reward: " .. tostring(rewardText)
	missionReward.ZIndex = 624
	missionReward.Parent = card

	local acceptBtn = Instance.new("TextButton")
	acceptBtn.Size = UDim2.new(0, isMobile and 106 or 124, 0, isMobile and 38 or 42)
	acceptBtn.Position = UDim2.new(1, isMobile and -118 or -142, 0.5, isMobile and -19 or -21)
	acceptBtn.BackgroundColor3 = THEME.RedDark
	acceptBtn.TextColor3 = THEME.Text
	acceptBtn.TextSize = isMobile and 11 or 13
	acceptBtn.Font = Enum.Font.GothamBlack
	acceptBtn.Text = "ACCEPT"
	acceptBtn.AutoButtonColor = false
	acceptBtn.BorderSizePixel = 0
	acceptBtn.ZIndex = 624
	acceptBtn.Parent = card
	Instance.new("UICorner", acceptBtn).CornerRadius = UDim.new(0, 8)
	local acceptStroke = Instance.new("UIStroke")
	acceptStroke.Color = THEME.Red
	acceptStroke.Thickness = 1
	acceptStroke.Parent = acceptBtn

	acceptBtn.MouseEnter:Connect(function()
		acceptBtn.BackgroundColor3 = THEME.Red
	end)
	acceptBtn.MouseLeave:Connect(function()
		acceptBtn.BackgroundColor3 = THEME.RedDark
	end)
	acceptBtn.MouseButton1Click:Connect(function()
		if not missionData.Id then return end
		updateLifeEvent:FireServer("DoMission", missionData.Id)
		uiState.closeRoute()
	end)
end

local function refresh()
	clear()
	subtitle.Text = "Loading missions..."
	local ok, board = pcall(function()
		return getMissionBoard:InvokeServer()
	end)
	if not ok then
		subtitle.Text = "Accept missions from the Jujutsu Society."
		createMessageCard("Could not load missions.\nCheck server output.", Color3.fromRGB(220, 90, 90))
		return
	end
	if not board or #board <= 0 then
		subtitle.Text = "Accept missions from the Jujutsu Society."
		createMessageCard(getMissionEmptyMessage(), Color3.fromRGB(180, 180, 190))
		return
	end

	subtitle.Text = tostring(#board) .. " mission" .. (#board ~= 1 and "s" or "") .. " available."

	for _, missionData in ipairs(board) do
		createMissionCard(missionData)
	end
	task.defer(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
	end)
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
		if route == "missions" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
