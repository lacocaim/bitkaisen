-- LocalScript: BitKaisenAFKStabilizationUI
-- Location: StarterPlayerScripts
-- Purpose: AFK Stabilization purchase/start UI.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local getAFK = ReplicatedStorage:WaitForChild("GetAFKStabilization", 20)
local afkAction = ReplicatedStorage:WaitForChild("AFKStabilizationAction", 20)
local afkUpdate = ReplicatedStorage:WaitForChild("AFKStabilizationUpdate", 20)

if not getAFK or not afkAction or not afkUpdate then
	warn("[BitKaisenAFKStabilizationUI] AFK remotes missing. UI skipped.")
	return
end

local GUI_NAME = "BitKaisenAFKStabilizationGui"
local oldGui = playerGui:FindFirstChild(GUI_NAME)
if oldGui then oldGui:Destroy() end

local theme = {
	Panel = Color3.fromRGB(13, 13, 20),
	Card = Color3.fromRGB(22, 22, 32),
	Stroke = Color3.fromRGB(78, 67, 96),
	Text = Color3.fromRGB(245, 243, 252),
	Sub = Color3.fromRGB(184, 178, 202),
	Gold = Color3.fromRGB(255, 207, 105),
	Green = Color3.fromRGB(115, 220, 150),
	Purple = Color3.fromRGB(165, 112, 255),
	Red = Color3.fromRGB(222, 72, 88),
}

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1455
gui.Parent = playerGui

local state = { Unlocked = false, Active = false, RatePerSecond = 0.2, SessionEarned = 0, EarnedTotal = 0, ProductId = 0, TestingPlace = false }

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or theme.Stroke
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.Parent = parent
	return s
end

local function tween(instance, duration, props)
	local tw = TweenService:Create(instance, TweenInfo.new(duration or 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local button = Instance.new("TextButton")
button.Name = "AFKButton"
button:SetAttribute("BKTopBarKey", "AFK")
button.AnchorPoint = Vector2.new(1, 0)
button.Position = UDim2.new(1, -132, 0, 82)
button.Size = UDim2.new(0, 92, 0, 34)
button.BackgroundColor3 = Color3.fromRGB(33, 28, 48)
button.BorderSizePixel = 0
button.Text = "AFK"
button.TextColor3 = theme.Gold
button.TextSize = 13
button.Font = Enum.Font.GothamBlack
button.ZIndex = 400
button.Parent = gui
corner(button, 8)
stroke(button, theme.Purple, 1, 0.12)

local panel = Instance.new("Frame")
panel.Name = "AFKPanel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -40, 0, 124)
panel.Size = UDim2.new(0, 292, 0, 226)
panel.BackgroundColor3 = theme.Panel
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 1460
panel.Parent = gui
corner(panel, 10)
stroke(panel, theme.Stroke, 1, 0.05)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 16, 0, 12)
title.Size = UDim2.new(1, -32, 0, 26)
title.Text = "AFK STABILIZATION"
title.TextColor3 = theme.Gold
title.TextSize = 18
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 1461
title.Parent = panel

local body = Instance.new("TextLabel")
body.BackgroundTransparency = 1
body.Position = UDim2.new(0, 16, 0, 44)
body.Size = UDim2.new(1, -32, 0, 50)
body.Text = "Idle stabilization converts quiet time into money."
body.TextColor3 = theme.Sub
body.TextSize = 12
body.Font = Enum.Font.GothamMedium
body.TextWrapped = true
body.TextXAlignment = Enum.TextXAlignment.Left
body.TextYAlignment = Enum.TextYAlignment.Top
body.ZIndex = 1461
body.Parent = panel

local statsText = Instance.new("TextLabel")
statsText.BackgroundTransparency = 1
statsText.Position = UDim2.new(0, 16, 0, 96)
statsText.Size = UDim2.new(1, -32, 0, 56)
statsText.Text = ""
statsText.TextColor3 = theme.Text
statsText.TextSize = 12
statsText.Font = Enum.Font.GothamBold
statsText.TextWrapped = true
statsText.TextXAlignment = Enum.TextXAlignment.Left
statsText.TextYAlignment = Enum.TextYAlignment.Top
statsText.ZIndex = 1461
statsText.Parent = panel

local actionButton = Instance.new("TextButton")
actionButton.Name = "AFKPanelActionButton"
actionButton.Position = UDim2.new(0, 16, 0, 170)
actionButton.Size = UDim2.new(1, -32, 0, 40)
actionButton.BackgroundColor3 = theme.Purple
actionButton.BorderSizePixel = 0
actionButton.Text = "START"
actionButton.TextColor3 = theme.Text
actionButton.TextSize = 14
actionButton.Font = Enum.Font.GothamBlack
actionButton.ZIndex = 1462
actionButton.Parent = panel
corner(actionButton, 8)
stroke(actionButton, Color3.fromRGB(255, 255, 255), 1, 0.35)

local function formatMoney(value)
	return "$" .. string.format("%.1f", tonumber(value) or 0)
end

local function refresh()
	actionButton.Visible = true
	actionButton.Active = true
	actionButton.AutoButtonColor = true
	local active = state.Active == true
	button:SetAttribute("BKAFKActive", active)
	button.BackgroundColor3 = active and Color3.fromRGB(28, 72, 45) or Color3.fromRGB(33, 28, 48)
	button.Text = active and "AFK ON" or "AFK"
	button.TextColor3 = active and theme.Green or theme.Gold
	local buttonStroke = button:FindFirstChildOfClass("UIStroke")
	if buttonStroke then
		buttonStroke.Color = active and theme.Green or theme.Purple
		buttonStroke.Transparency = active and 0.25 or 0.12
	end
	if state.Unlocked then
		body.Text = state.Active and "Stabilizing. Avoid normal play actions while AFK mode is active." or "Start AFK mode to earn while idle."
		actionButton.Text = state.Active and "STOP AFK" or "START AFK"
		actionButton.BackgroundColor3 = state.Active and theme.Red or theme.Green
	else
		body.Text = "One-time unlock. Earn money while idle after activating AFK mode."
		actionButton.Text = state.TestingPlace and "TEST UNLOCK" or "UNLOCK"
		actionButton.BackgroundColor3 = theme.Purple
	end
	statsText.Text = "Rate: " .. formatMoney(state.RatePerSecond or 0) .. "/sec\nThis session: " .. formatMoney(state.SessionEarned or 0) .. "\nLifetime AFK: " .. formatMoney(state.EarnedTotal or 0)
end

local function fetch()
	local ok, payload = pcall(function()
		return getAFK:InvokeServer()
	end)
	if ok and typeof(payload) == "table" then
		state = payload
		refresh()
	end
end

button.MouseButton1Click:Connect(function()
	fetch()
	panel.Visible = not panel.Visible
	if panel.Visible then
		panel.Size = UDim2.new(0, 270, 0, 206)
		tween(panel, 0.14, { Size = UDim2.new(0, 292, 0, 226) })
	end
end)

local ignoreInputUntil = 0

actionButton.MouseButton1Click:Connect(function()
	if state.Unlocked then
		local nextAction = state.Active and "stop" or "start"
		if nextAction == "start" then
			ignoreInputUntil = os.clock() + 1.25
		end
		afkAction:FireServer(nextAction)
	else
		local productId = tonumber(state.ProductId) or 0
		if state.TestingPlace then
			afkAction:FireServer("test_unlock")
		elseif productId > 0 then
			MarketplaceService:PromptGamePassPurchase(player, productId)
		else
			actionButton.Text = "SET PRODUCT ID"
			task.delay(1, refresh)
		end
	end
	task.delay(0.2, fetch)
end)

afkUpdate.OnClientEvent:Connect(function(payload)
	if typeof(payload) == "table" then
		state = payload
		refresh()
	end
end)

local lastAutoStopAt = 0
local function isPointInside(guiObject, position)
	if not guiObject or not guiObject.Parent or not guiObject.Visible then return false end
	local topLeft = guiObject.AbsolutePosition
	local size = guiObject.AbsoluteSize
	return position.X >= topLeft.X and position.X <= topLeft.X + size.X and position.Y >= topLeft.Y and position.Y <= topLeft.Y + size.Y
end

local function isAFKUiInput(input)
	local position = input.Position
	if typeof(position) ~= "Vector3" then return false end
	local point = Vector2.new(position.X, position.Y)
	return isPointInside(panel, point) or isPointInside(button, point)
end

local function stopAFKFromInput()
	if state.Active ~= true then return end
	if os.clock() < ignoreInputUntil then return end
	if os.clock() - lastAutoStopAt < 0.35 then return end
	lastAutoStopAt = os.clock()
	afkAction:FireServer("stop")
	state.Active = false
	refresh()
	task.delay(0.25, fetch)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not state.Active then return end
	if isAFKUiInput(input) then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.MouseButton2
		or input.UserInputType == Enum.UserInputType.MouseButton3
		or input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.Keyboard
		or input.UserInputType == Enum.UserInputType.Gamepad1
	then
		stopAFKFromInput()
	end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
	if not state.Active then return end
	if isAFKUiInput(input) then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.Gamepad1
	then
		stopAFKFromInput()
	end
end)

UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(refresh)
fetch()
print("[BitKaisenAFKStabilizationUI] Loaded.")

