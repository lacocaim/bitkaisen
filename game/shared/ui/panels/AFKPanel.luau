local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local responsiveScale = require("@ui/responsiveScale")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _afk(key, fallback) return BitKaisenLocale.tOrFallback(_L, "afk." .. key, nil, fallback) end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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
gui.Name = "BitKaisenAFKStabilizationGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 642
gui.Enabled = false
gui.Parent = playerGui

local function makeCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function makeStroke(parent, color, thickness, transparency)
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
button.ZIndex = 642
button.Parent = gui
makeCorner(button, 8)
makeStroke(button, theme.Purple, 1, 0.12)

local panel = Instance.new("Frame")
panel.Name = "AFKPanel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -40, 0, 124)
panel.Size = UDim2.fromOffset(292, 226)
panel.BackgroundColor3 = theme.Panel
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 643
panel.Parent = gui
makeCorner(panel, 10)
makeStroke(panel, theme.Stroke, 1, 0.05)

do
	local uiScale = Instance.new("UIScale")
	uiScale.Name = "ResponsiveScale"
	uiScale.Parent = panel
	local function recompute()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local vp = cam.ViewportSize
		local sx = (vp.X - 28) / 292
		local sy = (vp.Y - 70) / 226
		uiScale.Scale = math.clamp(math.min(sx, sy, 1), 0.34, 1)
	end
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(recompute)
	end
	recompute()
end

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.new(1, -8, 0, 8)
closeBtn.Size = UDim2.fromOffset(28, 28)
closeBtn.BackgroundColor3 = Color3.fromRGB(37, 38, 50)
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.Text = "X"
closeBtn.TextColor3 = theme.Red
closeBtn.TextSize = 14
closeBtn.ZIndex = 645
closeBtn.Parent = panel
makeCorner(closeBtn, 8)

closeBtn.MouseButton1Click:Connect(function()
	panel.Visible = false
end)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 16, 0, 12)
title.Size = UDim2.new(1, -52, 0, 26)
title.Text = _afk("title", "AFK STABILIZATION")
title.TextColor3 = theme.Gold
title.TextSize = 18
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 644
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
body.ZIndex = 644
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
statsText.ZIndex = 644
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
actionButton.ZIndex = 645
actionButton.Parent = panel
makeCorner(actionButton, 8)
makeStroke(actionButton, Color3.fromRGB(255, 255, 255), 1, 0.35)

local state = { Unlocked = true, Active = false, RatePerSecond = 0.2, SessionEarned = 0, EarnedTotal = 0, ProductId = 0, TestingPlace = false, HasAFKPass = false }
local ignoreInputUntil = 0
local lastAutoStopAt = 0

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
	button.Text = active and _afk("btn_open_on", "AFK ON") or _afk("btn_open_off", "AFK")
	button.TextColor3 = active and theme.Green or theme.Gold
	local buttonStroke = button:FindFirstChildOfClass("UIStroke")
	if buttonStroke then
		buttonStroke.Color = active and theme.Green or theme.Purple
		buttonStroke.Transparency = active and 0.25 or 0.12
	end
	local passNote = state.HasAFKPass and _afk("pass_note", " (2x ACTIVE)") or ""
	body.Text = state.Active and (_afk("body_active", "Stabilizing. Avoid normal play actions while AFK mode is active.") .. passNote) or (_afk("body_idle", "Start AFK mode to earn while idle.") .. passNote)
	actionButton.Text = state.Active and _afk("btn_stop", "STOP AFK") or _afk("btn_start", "START AFK")
	actionButton.BackgroundColor3 = state.Active and theme.Red or theme.Green
	local displayRate = (state.RatePerSecond or 0) * (state.HasAFKPass and 2 or 1)
	local rateStr = state.HasAFKPass and _afk("stats_rate_2x", "Rate: {rate}/sec (2x)"):gsub("{rate}", formatMoney(displayRate)) or _afk("stats_rate", "Rate: {rate}/sec"):gsub("{rate}", formatMoney(displayRate))
	statsText.Text = rateStr .. "\n" .. _afk("stats_session", "This session: {earned}"):gsub("{earned}", formatMoney(state.SessionEarned or 0)) .. "\n" .. _afk("stats_lifetime", "Lifetime AFK: {earned}"):gsub("{earned}", formatMoney(state.EarnedTotal or 0))
end

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

local function init()
	local getAFK = ReplicatedStorage:WaitForChild("GetAFKStabilization", 20)
	local afkAction = ReplicatedStorage:WaitForChild("AFKStabilizationAction", 20)
	local afkUpdate = ReplicatedStorage:WaitForChild("AFKStabilizationUpdate", 20)

	if not getAFK or not afkAction or not afkUpdate then
		warn("[AFKPanel] AFK remotes missing. UI skipped.")
		return
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

	button.MouseButton1Click:Connect(function()
		fetch()
		panel.Visible = not panel.Visible
		if panel.Visible then
			panel.Size = UDim2.new(0, 270, 0, 206)
			tween(panel, 0.14, { Size = UDim2.new(0, 292, 0, 226) })
		end
	end)

	actionButton.MouseButton1Click:Connect(function()
		local nextAction = state.Active and "stop" or "start"
		if nextAction == "start" then
			ignoreInputUntil = os.clock() + 1.25
		end
		afkAction:FireServer(nextAction)
		task.delay(0.2, fetch)
	end)

	afkUpdate.OnClientEvent:Connect(function(payload)
		if typeof(payload) == "table" then
			state = payload
			refresh()
		end
	end)

	UserInputService.InputBegan:Connect(function(input, _gameProcessed)
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

	UserInputService.InputChanged:Connect(function(input, _gameProcessed)
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

	button.Visible = false

	gui.Enabled = true
	fetch()
end

local function open()
	if not gui then return end
	gui.Enabled = true
	local getAFK = ReplicatedStorage:FindFirstChild("GetAFKStabilization")
	if getAFK then
		local ok2, p2 = pcall(function() return getAFK:InvokeServer() end)
		if ok2 and typeof(p2) == "table" then
			state = p2
			refresh()
		end
	end
	if panel then panel.Visible = true end
end

local function close()
	if panel then panel.Visible = false end
end

return { init = init, open = open, close = close }
