local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local uiState = require("@ui-state/uiState")
local responsiveScale = require("@ui/responsiveScale")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getJobs = ReplicatedStorage:WaitForChild("GetJobs")
local jobAction = ReplicatedStorage:WaitForChild("JobAction")
local testPurchase = ReplicatedStorage:FindFirstChild("TestPurchase")
local TEST_PURCHASE_PLACE_ID = 104206065947170

local THEME = {
	Bg = Color3.fromRGB(8, 8, 13),
	Panel = Color3.fromRGB(15, 15, 23),
	Card = Color3.fromRGB(20, 20, 29),
	Stroke = Color3.fromRGB(58, 52, 76),
	Text = Color3.fromRGB(242, 240, 250),
	SubText = Color3.fromRGB(168, 164, 186),
	Gold = Color3.fromRGB(255, 204, 102),
	Green = Color3.fromRGB(105, 225, 145),
	Red = Color3.fromRGB(220, 75, 95),
	Purple = Color3.fromRGB(178, 120, 255),
}

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenJobsGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 620
gui.Enabled = false
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "JobsOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.35
overlay.ZIndex = 620
overlay.Parent = gui

local window = Instance.new("Frame")
window.Name = "JobsWindow"
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
title.Text = "JOBS"
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
closeButton.TextColor3 = THEME.Red
closeButton.Font = Enum.Font.GothamBlack
closeButton.Position = UDim2.new(1, -56, 0, 16)
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.TextSize = 19
closeButton.ZIndex = 623
closeButton.Parent = window
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 8)

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "JobsScroll"
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
local busy = false
local refresh

local function viewport()
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local function mobile()
	local v = viewport()
	return UserInputService.TouchEnabled or v.X < 900
end

local function portrait()
	local v = viewport()
	return v.Y > v.X
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

local function makeRouteCard(payload)
	local isMobile = mobile()
	local isRogue = payload.IsRogueSorcerer == true
	local canGo = payload.CanGoRogue == true
	local rogueProductId = tonumber(payload.GoRogueProductId) or 0
	local roguePassId = tonumber(payload.GoRoguePassId) or 0
	local canPurchaseRogue = canGo and (roguePassId > 0 or rogueProductId > 0)
	local rogueUsed = (tonumber(payload.RogueActionsThisYear) or 0) >= 1
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -8, 0, isRogue and (isMobile and 156 or 132) or (isMobile and 104 or 86))
	card.BackgroundColor3 = Color3.fromRGB(24, 18, 34)
	card.BorderSizePixel = 0
	card.ZIndex = 623
	card.Parent = scroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = THEME.Purple
	cardStroke.Thickness = 1
	cardStroke.Transparency = 0.25
	cardStroke.Parent = card

	addText(card, isRogue and "Rogue Sorcerer Route" or "Route Choice", isMobile and 13 or 15, THEME.Text, UDim2.new(0, 14, 0, 12), UDim2.new(1, -136, 0, 22), true)
	addText(card, isRogue and "You are outside official Jujutsu society." or "Cut ties with Jujutsu High and move independently.", isMobile and 9 or 11, THEME.SubText, UDim2.new(0, 14, 0, 38), UDim2.new(1, -136, 0, 42), false)

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, isMobile and 92 or 106, 0, 34)
	button.Position = UDim2.new(1, isMobile and -104 or -120, 0.5, -17)
	button.BackgroundColor3 = canPurchaseRogue and Color3.fromRGB(78, 46, 105) or Color3.fromRGB(34, 35, 45)
	button.BorderSizePixel = 0
	button.Text = isRogue and "ROGUE" or (canPurchaseRogue and "GO ROGUE" or (canGo and "SET ID" or "LOCKED"))
	button.TextColor3 = (canPurchaseRogue or isRogue) and THEME.Text or THEME.SubText
	button.TextSize = isMobile and 9 or 11
	button.Font = Enum.Font.GothamBlack
	button.Active = canPurchaseRogue
	button.AutoButtonColor = canPurchaseRogue
	button.ZIndex = 624
	button.Parent = card
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

	if canPurchaseRogue then
		button.MouseButton1Click:Connect(function()
			if busy then return end
			busy = true
			button.Text = "..."
			if game.PlaceId == TEST_PURCHASE_PLACE_ID then
				jobAction:FireServer("go_rogue", "test_place_bypass")
			else
				if roguePassId > 0 then
					MarketplaceService:PromptGamePassPurchase(player, roguePassId)
				else
					MarketplaceService:PromptProductPurchase(player, rogueProductId)
				end
			end
			task.delay(0.8, function()
				busy = false
				if isOpen then refresh() end
			end)
		end)
	end

	if isRogue then
		local actions = {
			{ Id = "rogue_black_market", Text = "MARKET" },
			{ Id = "rogue_hide_trail", Text = "HIDE" },
			{ Id = "rogue_contract", Text = "CONTRACT" },
		}
		local actionY = isMobile and 98 or 84
		local actionWidth = isMobile and 80 or 104
		local gap = isMobile and 8 or 10
		for index, action in ipairs(actions) do
			local actionButton = Instance.new("TextButton")
			actionButton.Size = UDim2.new(0, actionWidth, 0, isMobile and 30 or 32)
			actionButton.Position = UDim2.new(0, 14 + ((index - 1) * (actionWidth + gap)), 0, actionY)
			actionButton.BackgroundColor3 = rogueUsed and Color3.fromRGB(34, 35, 45) or Color3.fromRGB(64, 42, 82)
			actionButton.BorderSizePixel = 0
			actionButton.Text = rogueUsed and "USED" or action.Text
			actionButton.TextColor3 = rogueUsed and THEME.SubText or THEME.Text
			actionButton.TextSize = isMobile and 8 or 10
			actionButton.Font = Enum.Font.GothamBlack
			actionButton.Active = not rogueUsed
			actionButton.AutoButtonColor = not rogueUsed
			actionButton.ZIndex = 624
			actionButton.Parent = card
			Instance.new("UICorner", actionButton).CornerRadius = UDim.new(0, 7)
			if not rogueUsed then
				actionButton.MouseButton1Click:Connect(function()
					if busy then return end
					busy = true
					actionButton.Text = "..."
					jobAction:FireServer(action.Id, "")
					task.delay(0.8, function()
						busy = false
						if isOpen then refresh() end
					end)
				end)
			end
		end
	end
end

local function makeCard(job, canApply, playerAge)
	local isMobile = mobile()
	local tooYoung = playerAge < (tonumber(job.MinAge) or 0)
	local eligible = canApply and not tooYoung

	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -8, 0, isMobile and 112 or 96)
	card.BackgroundColor3 = THEME.Card
	card.BorderSizePixel = 0
	card.ZIndex = 623
	card.Parent = scroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = THEME.Stroke
	cardStroke.Thickness = 1
	cardStroke.Parent = card

	addText(card, tostring(job.Title or "Job"), isMobile and 13 or 15, THEME.Text, UDim2.new(0, 14, 0, 12), UDim2.new(1, -136, 0, 22), true)
	addText(card, "$" .. tostring(job.Pay or 0) .. " / year | " .. tostring(job.Acceptance or 0) .. "% acceptance", isMobile and 10 or 12, THEME.Gold, UDim2.new(0, 14, 0, 38), UDim2.new(1, -136, 0, 20), true)
	addText(card, "Best with " .. tostring(job.Stat or "stats") .. " | Age " .. tostring(job.MinAge or 0) .. "+", isMobile and 9 or 11, THEME.SubText, UDim2.new(0, 14, 0, 62), UDim2.new(1, -136, 0, 34), false)

	local buttonLabel
	if not canApply then
		buttonLabel = "USED"
	elseif tooYoung then
		buttonLabel = "AGE " .. tostring(job.MinAge) .. "+"
	else
		buttonLabel = "APPLY"
	end

	local buttonColor
	if eligible then
		buttonColor = Color3.fromRGB(38, 82, 54)
	elseif tooYoung then
		buttonColor = Color3.fromRGB(58, 48, 38)
	else
		buttonColor = Color3.fromRGB(34, 35, 45)
	end

	local apply = Instance.new("TextButton")
	apply.Size = UDim2.new(0, isMobile and 92 or 106, 0, 34)
	apply.Position = UDim2.new(1, isMobile and -104 or -120, 0.5, -17)
	apply.BackgroundColor3 = buttonColor
	apply.BorderSizePixel = 0
	apply.Text = buttonLabel
	apply.TextColor3 = eligible and THEME.Text or THEME.SubText
	apply.TextSize = isMobile and 10 or 12
	apply.Font = Enum.Font.GothamBlack
	apply.Active = eligible
	apply.AutoButtonColor = eligible
	apply.ZIndex = 624
	apply.Parent = card
	Instance.new("UICorner", apply).CornerRadius = UDim.new(0, 8)

	if eligible then
		apply.MouseButton1Click:Connect(function()
			if busy then return end
			busy = true
			apply.Text = "..."
			jobAction:FireServer("apply", job.Id)
			task.delay(0.8, function()
				busy = false
				if isOpen then
					refresh()
				end
			end)
		end)
	end
end

function refresh()
	clear()
	local ok, payload = pcall(function()
		return getJobs:InvokeServer()
	end)
	if not ok or typeof(payload) ~= "table" then
		subtitle.Text = "Civilian route jobs are unavailable."
		return
	end

	local playerAge = tonumber(payload.Age) or 0
	local jobLevel = tonumber(payload.JobLevel) or 0
	local salary = tonumber(payload.JobSalary) or 0
	local careerText = jobLevel > 0 and (" | Lv " .. tostring(jobLevel) .. " | $" .. tostring(salary) .. "/yr") or ""
	subtitle.Text = "Age " .. tostring(playerAge) .. " | Current: " .. tostring(payload.CurrentJob or "Unemployed") .. careerText .. " | Year " .. tostring(payload.Year or "?") .. " | Applications " .. tostring(payload.ApplicationsThisYear or 0) .. "/1"

	local hasAgeLocked = false
	for _, job in ipairs(payload.Jobs or {}) do
		if playerAge < (tonumber(job.MinAge) or 0) then
			hasAgeLocked = true
			break
		end
	end

	if hasAgeLocked then
		local note = Instance.new("TextLabel")
		note.Size = UDim2.new(1, -8, 0, 28)
		note.BackgroundColor3 = Color3.fromRGB(40, 32, 20)
		note.BorderSizePixel = 0
		note.Text = "  Some roles need you to be older — locked jobs show their minimum age."
		note.TextColor3 = THEME.Gold
		note.TextSize = 11
		note.Font = Enum.Font.GothamMedium
		note.TextXAlignment = Enum.TextXAlignment.Left
		note.TextWrapped = true
		note.ZIndex = 623
		note.LayoutOrder = -1
		note.Parent = scroll
		Instance.new("UICorner", note).CornerRadius = UDim.new(0, 6)
	end

	makeRouteCard(payload)
	for _, job in ipairs(payload.Jobs or {}) do
		makeCard(job, payload.CanApply == true, playerAge)
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

jobAction.OnClientEvent:Connect(function()
	if isOpen then refresh() end
end)

local function init()
	uiState.subscribe(function(route)
		if route == "jobs" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
