local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local responsiveScale = require("@ui/responsiveScale")
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local L = BitKaisenLocale.getClientLocale()
local MinigamesPanel = {}

local gui: ScreenGui
local active = nil
local gamepadInputActive = UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1

local startMinigame: RemoteEvent?
local completeMinigame: RemoteEvent?

local function isGamepadInputActive()
	return gamepadInputActive and UserInputService.GamepadEnabled
end

local function setConsoleSelection(button)
	if isGamepadInputActive() then
		GuiService.SelectedObject = button
	elseif GuiService.SelectedObject == button then
		GuiService.SelectedObject = nil
	end
end

local function getMinigameViewport()
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local function isMobileLandscapeViewport()
	local viewport = getMinigameViewport()
	return viewport.X < 920 and viewport.X > viewport.Y
end

local function fitMinigamePanel(panel, desktopWidth, desktopHeight, _landscapeWidth, _landscapeHeight)
	responsiveScale.attach(panel, desktopWidth, desktopHeight)
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local function destroyActive()
	if active then
		if active.Connection then
			active.Connection:Disconnect()
		end
		if active.Root and active.Root.Parent then
			active.Root:Destroy()
		end
	end
	active = nil
end

local function submitActive(cancelled)
	if not active then
		return
	end

	local session = active
	active = nil

	if session.Connection then
		session.Connection:Disconnect()
	end

	local elapsed = math.clamp(os.clock() - session.StartedAt, 0, session.Duration)
	local position = elapsed / session.Duration
	local distance = math.abs(position - session.Target)
	local accuracy = cancelled and 0 or math.clamp(1 - (distance / 0.22), 0, 1)

	if completeMinigame and completeMinigame:IsA("RemoteEvent") then
		completeMinigame:FireServer(session.Token, accuracy)
	end

	if session.ResultLabel and session.ResultLabel.Parent then
		local label = session.ResultLabel
		if accuracy >= 0.94 then
			label.Text = "BLACK FLASH"
		elseif accuracy >= 0.78 then
			label.Text = "PERFECT IMPACT"
		elseif accuracy >= 0.52 then
			label.Text = "CLEAN HIT"
		else
			label.Text = "MISTIMED"
		end
		label.TextTransparency = 0
	end

	if session.Root and session.Root.Parent then
		TweenService:Create(session.Root, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
		task.delay(0.35, function()
			if session.Root then
				session.Root:Destroy()
			end
		end)
	end
end

local function makeBlackjackText(parent, text, size, color, pos, frameSize, bold)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = pos
	label.Size = frameSize
	label.TextColor3 = color
	label.TextSize = size
	label.Font = bold and Enum.Font.GothamBlack or Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Text = text
	label.ZIndex = 762
	label.Parent = parent
	return label
end

local function makeBlackjackButton(parent, text, x, color)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0.31, -6, 0, 38)
	button.Position = UDim2.new(x, 0, 1, -52)
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.TextColor3 = Color3.fromRGB(245, 246, 238)
	button.TextSize = 13
	button.Font = Enum.Font.GothamBlack
	button.Text = text
	button.AutoButtonColor = true
	button.Selectable = true
	button.ZIndex = 763
	button.Parent = parent
	addCorner(button, 8)
	addStroke(button, Color3.fromRGB(225, 226, 205), 1, 0.65)
	return button
end

local function sendBlackjackAction(action)
	if not active or active.Kind ~= "Blackjack" then
		return
	end
	if completeMinigame and completeMinigame:IsA("RemoteEvent") then
		completeMinigame:FireServer(active.Token, 0, action)
	end
end

local function sendRCTResult(sequence)
	if not active or active.Kind ~= "RCTMemory" then return end
	if completeMinigame and completeMinigame:IsA("RemoteEvent") then
		completeMinigame:FireServer(active.Token, 0, table.concat(sequence or {}, ","))
	end
	destroyActive()
end

local function sendFingerResult(count)
	if not active or active.Kind ~= "CursedFinger" then
		return
	end
	if completeMinigame and completeMinigame:IsA("RemoteEvent") then
		completeMinigame:FireServer(active.Token, 0, tostring(count or 0))
	end
	destroyActive()
end

local function sendHeirloomResult(result)
	if not active or active.Kind ~= "Heirloom" then
		return
	end
	if completeMinigame and completeMinigame:IsA("RemoteEvent") then
		completeMinigame:FireServer(active.Token, 0, result)
	end
	destroyActive()
end

local function sendBurglaryResult(result)
	if not active or active.Kind ~= "Burglary" then
		return
	end
	if completeMinigame and completeMinigame:IsA("RemoteEvent") then
		completeMinigame:FireServer(active.Token, 0, result)
	end
	destroyActive()
end

local function openBlackFlashTiming(payload)
	destroyActive()

	local token = tostring(payload.Token or "")
	if token == "" then
		return
	end

	local target = math.clamp(tonumber(payload.Target) or 0.58, 0.12, 0.88)
	local duration = math.clamp(tonumber(payload.Duration) or 1.45, 0.8, 3)

	local root = Instance.new("Frame")
	root.Name = "BlackFlashTimingMinigame"
	root.Size = UDim2.new(1, 0, 1, 0)
	root.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	root.BackgroundTransparency = 0.42
	root.BorderSizePixel = 0
	root.ZIndex = 760
	root.Active = false
	root.Parent = gui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.new(0.5, 0, 0.52, 0)
	fitMinigamePanel(panel, 520, 210, 560, 190)
	panel.BackgroundColor3 = Color3.fromRGB(13, 13, 20)
	panel.BorderSizePixel = 0
	panel.ZIndex = 761
	panel.Parent = root
	addCorner(panel, 10)
	addStroke(panel, Color3.fromRGB(82, 58, 122), 1, 0.05)

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, 22, 0, 18)
	title.Size = UDim2.new(1, -44, 0, 28)
	title.TextColor3 = Color3.fromRGB(245, 241, 255)
	title.TextSize = 22
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = tostring(payload.Title or "Timing Challenge")
	title.ZIndex = 762
	title.Parent = panel

	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.Position = UDim2.new(0, 22, 0, 50)
	body.Size = UDim2.new(1, -44, 0, 42)
	body.TextColor3 = Color3.fromRGB(184, 180, 202)
	body.TextSize = 13
	body.Font = Enum.Font.GothamMedium
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextWrapped = true
	body.Text = tostring(payload.Body or "Stop the marker inside the impact window.")
	body.ZIndex = 762
	body.Parent = panel

	local track = Instance.new("Frame")
	track.Position = UDim2.new(0, 34, 0, 112)
	track.Size = UDim2.new(1, -68, 0, 20)
	track.BackgroundColor3 = Color3.fromRGB(28, 26, 38)
	track.BorderSizePixel = 0
	track.ZIndex = 762
	track.Parent = panel
	addCorner(track, 999)
	addStroke(track, Color3.fromRGB(55, 49, 76), 1, 0.1)

	local zone = Instance.new("Frame")
	zone.AnchorPoint = Vector2.new(0.5, 0.5)
	zone.Position = UDim2.new(target, 0, 0.5, 0)
	zone.Size = UDim2.new(0, 54, 1, 10)
	zone.BackgroundColor3 = Color3.fromRGB(185, 70, 92)
	zone.BorderSizePixel = 0
	zone.ZIndex = 763
	zone.Parent = track
	addCorner(zone, 999)

	local perfect = Instance.new("Frame")
	perfect.AnchorPoint = Vector2.new(0.5, 0.5)
	perfect.Position = UDim2.new(0.5, 0, 0.5, 0)
	perfect.Size = UDim2.new(0, 14, 1, 12)
	perfect.BackgroundColor3 = Color3.fromRGB(255, 214, 105)
	perfect.BorderSizePixel = 0
	perfect.ZIndex = 764
	perfect.Parent = zone
	addCorner(perfect, 999)

	local marker = Instance.new("Frame")
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.Position = UDim2.new(0, 0, 0.5, 0)
	marker.Size = UDim2.new(0, 12, 1, 28)
	marker.BackgroundColor3 = Color3.fromRGB(238, 235, 255)
	marker.BorderSizePixel = 0
	marker.ZIndex = 765
	marker.Parent = track
	addCorner(marker, 999)

	local hitButton = Instance.new("TextButton")
	hitButton.AnchorPoint = Vector2.new(0.5, 1)
	hitButton.Position = UDim2.new(0.5, 0, 1, -22)
	hitButton.Size = UDim2.new(0, 220, 0, 42)
	hitButton.BackgroundColor3 = Color3.fromRGB(78, 27, 41)
	hitButton.TextColor3 = Color3.fromRGB(255, 238, 244)
	hitButton.TextSize = 15
	hitButton.Font = Enum.Font.GothamBlack
	hitButton.Text = "STRIKE"
	hitButton.AutoButtonColor = true
	hitButton.Selectable = true
	hitButton.ZIndex = 762
	hitButton.Parent = panel
	addCorner(hitButton, 8)
	addStroke(hitButton, Color3.fromRGB(190, 72, 94), 1, 0)

	local resultLabel = Instance.new("TextLabel")
	resultLabel.BackgroundTransparency = 1
	resultLabel.Position = UDim2.new(0, 22, 0, 142)
	resultLabel.Size = UDim2.new(1, -44, 0, 24)
	resultLabel.TextColor3 = Color3.fromRGB(255, 214, 105)
	resultLabel.TextTransparency = 1
	resultLabel.TextSize = 18
	resultLabel.Font = Enum.Font.GothamBlack
	resultLabel.TextXAlignment = Enum.TextXAlignment.Center
	resultLabel.Text = ""
	resultLabel.ZIndex = 762
	resultLabel.Parent = panel

	local startedAt = os.clock()
	active = {
		Kind = "BlackFlashTiming",
		Token = token,
		Root = root,
		StartedAt = startedAt,
		Duration = duration,
		Target = target,
		Marker = marker,
		ResultLabel = resultLabel,
	}

	active.Connection = RunService.RenderStepped:Connect(function()
		if not active or active.Token ~= token then
			return
		end

		local progress = (os.clock() - startedAt) / duration
		if progress >= 1 then
			marker.Position = UDim2.new(1, 0, 0.5, 0)
			submitActive(true)
			return
		end
		marker.Position = UDim2.new(progress, 0, 0.5, 0)
	end)

	hitButton.MouseButton1Click:Connect(function()
		submitActive(false)
	end)

	setConsoleSelection(hitButton)
end

local function openBlackjack(payload)
	destroyActive()

	local token = tostring(payload.Token or "")
	if token == "" then
		return
	end

	local root = Instance.new("Frame")
	root.Name = "BlackjackMinigame"
	root.Size = UDim2.new(1, 0, 1, 0)
	root.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	root.BackgroundTransparency = 0.38
	root.BorderSizePixel = 0
	root.ZIndex = 760
	root.Parent = gui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.new(0.5, 0, 0.52, 0)
	fitMinigamePanel(panel, 540, 280, 560, 250)
	panel.BackgroundColor3 = Color3.fromRGB(12, 31, 27)
	panel.BorderSizePixel = 0
	panel.ZIndex = 761
	panel.Parent = root
	addCorner(panel, 10)
	addStroke(panel, Color3.fromRGB(94, 150, 120), 1, 0.1)

	makeBlackjackText(panel, "21 CARD GAME", 22, Color3.fromRGB(238, 246, 228), UDim2.new(0, 22, 0, 18), UDim2.new(1, -44, 0, 28), true)
	local wager = tostring(payload.Wager or 100)
	local status = tostring(payload.Status or "Beat the dealer without going over 21. Wager: $" .. wager)
	makeBlackjackText(panel, status, 13, Color3.fromRGB(190, 212, 196), UDim2.new(0, 22, 0, 50), UDim2.new(1, -44, 0, 42), false)
	makeBlackjackText(panel, "Dealer: " .. tostring(payload.DealerText or "?"), 16, Color3.fromRGB(255, 218, 130), UDim2.new(0, 28, 0, 108), UDim2.new(1, -56, 0, 34), true)
	makeBlackjackText(panel, "You: " .. tostring(payload.PlayerText or "?"), 16, Color3.fromRGB(235, 240, 235), UDim2.new(0, 28, 0, 154), UDim2.new(1, -56, 0, 46), true)

	local hit = makeBlackjackButton(panel, "HIT", 0.035, Color3.fromRGB(44, 112, 82))
	local stand = makeBlackjackButton(panel, "STAND", 0.345, Color3.fromRGB(64, 89, 134))
	local leave = makeBlackjackButton(panel, payload.Done and BitKaisenLocale.tOrFallback(L, "ui.close", nil, "Close") or BitKaisenLocale.tOrFallback(L, "ui.leave", nil, "Leave"), 0.655, Color3.fromRGB(124, 54, 60))

	active = {
		Kind = "Blackjack",
		Token = token,
		Root = root,
	}

	if payload.Done == true then
		hit.Active = false
		stand.Active = false
		hit.TextTransparency = 0.45
		stand.TextTransparency = 0.45
		setConsoleSelection(leave)
	else
		setConsoleSelection(hit)
	end

	hit.MouseButton1Click:Connect(function()
		sendBlackjackAction("hit")
	end)
	stand.MouseButton1Click:Connect(function()
		sendBlackjackAction("stand")
	end)
	leave.MouseButton1Click:Connect(function()
		if payload.Done == true then
			destroyActive()
		else
			sendBlackjackAction("forfeit")
		end
	end)
end

local function openBurglary(payload)
	destroyActive()
	local token = tostring(payload.Token or "")
	if token == "" then return end

	local size = math.clamp(tonumber(payload.Size) or 5, 4, 6)
	local playerPos = { X = 1, Y = size }
	local lootPos = payload.Loot or { X = math.ceil(size / 2), Y = math.ceil(size / 2) }
	local exitPos = payload.Exit or { X = size, Y = 1 }
	local guards = typeof(payload.Guards) == "table" and payload.Guards or {}
	local hasLoot = false

	local root = Instance.new("Frame")
	root.Name = "BurglaryMinigame"
	root.Size = UDim2.new(1, 0, 1, 0)
	root.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	root.BackgroundTransparency = 0.36
	root.BorderSizePixel = 0
	root.ZIndex = 760
	root.Parent = gui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.new(0.5, 0, 0.52, 0)
	fitMinigamePanel(panel, 420, 500, 520, 330)
	panel.BackgroundColor3 = Color3.fromRGB(25, 22, 19)
	panel.BorderSizePixel = 0
	panel.ZIndex = 761
	panel.Parent = root
	addCorner(panel, 10)
	addStroke(panel, Color3.fromRGB(154, 112, 67), 1, 0.08)

	local compactLandscape = isMobileLandscapeViewport()
	makeBlackjackText(panel, "BURGLARY", compactLandscape and 16 or 22, Color3.fromRGB(246, 233, 206), UDim2.new(0, 22, 0, 18), UDim2.new(1, -124, 0, 28), true)
	local status = makeBlackjackText(panel, "Grab the loot, then reach the exit. Avoid guards.", compactLandscape and 11 or 13, Color3.fromRGB(210, 192, 166), UDim2.new(0, 22, 0, 50), UDim2.new(1, -44, 0, 38), false)

	local leaveBtn = Instance.new("TextButton")
	leaveBtn.Size = UDim2.new(0, compactLandscape and 66 or 76, 0, compactLandscape and 24 or 28)
	leaveBtn.Position = UDim2.new(1, compactLandscape and -88 or -100, 0, 18)
	leaveBtn.BackgroundColor3 = Color3.fromRGB(105, 54, 54)
	leaveBtn.BorderSizePixel = 0
	leaveBtn.TextColor3 = Color3.fromRGB(245, 236, 224)
	leaveBtn.TextSize = compactLandscape and 10 or 12
	leaveBtn.Font = Enum.Font.GothamBlack
	leaveBtn.Text = "LEAVE"
	leaveBtn.AutoButtonColor = true
	leaveBtn.Selectable = true
	leaveBtn.ZIndex = 763
	leaveBtn.Parent = panel
	addCorner(leaveBtn, 7)
	addStroke(leaveBtn, Color3.fromRGB(210, 180, 150), 1, 0.55)
	leaveBtn.MouseButton1Click:Connect(function()
		sendBurglaryResult("fled")
	end)

	local board = Instance.new("Frame")
	local boardSize = compactLandscape and 210 or 300
	board.Position = compactLandscape and UDim2.new(0, 36, 0, 84) or UDim2.new(0.5, -boardSize / 2, 0, 105)
	board.Size = UDim2.new(0, boardSize, 0, boardSize)
	board.BackgroundTransparency = 1
	board.ZIndex = 762
	board.Parent = panel

	local cells = {}
	local function key(x, y) return tostring(x) .. ":" .. tostring(y) end
	local function isGuard(x, y)
		for _, guard in ipairs(guards) do
			if tonumber(guard.X) == x and tonumber(guard.Y) == y then return true end
		end
		return false
	end
	local function redraw()
		for y = 1, size do
			for x = 1, size do
				local cell = cells[key(x, y)]
				local text = ""
				local color = Color3.fromRGB(42, 38, 33)
				if playerPos.X == x and playerPos.Y == y then
					text = "YOU"; color = Color3.fromRGB(74, 119, 82)
				elseif isGuard(x, y) then
					text = "G"; color = Color3.fromRGB(116, 46, 49)
				elseif not hasLoot and tonumber(lootPos.X) == x and tonumber(lootPos.Y) == y then
					text = "$"; color = Color3.fromRGB(132, 102, 42)
				elseif tonumber(exitPos.X) == x and tonumber(exitPos.Y) == y then
					text = "EXIT"; color = Color3.fromRGB(52, 82, 112)
				end
				cell.Text = text
				cell.BackgroundColor3 = color
			end
		end
		status.Text = hasLoot and "Loot secured. Reach the exit." or "Find the loot, then escape."
	end
	for y = 1, size do
		for x = 1, size do
			local cell = Instance.new("TextLabel")
			cell.Size = UDim2.new(1 / size, -5, 1 / size, -5)
			cell.Position = UDim2.new((x - 1) / size, 3, (y - 1) / size, 3)
			cell.BackgroundColor3 = Color3.fromRGB(42, 38, 33)
			cell.BorderSizePixel = 0
			cell.TextColor3 = Color3.fromRGB(246, 238, 220)
			cell.TextSize = 12
			cell.Font = Enum.Font.GothamBlack
			cell.ZIndex = 763
			cell.Parent = board
			addCorner(cell, 6)
			cells[key(x, y)] = cell
		end
	end

	local function step(dx, dy)
		playerPos.X = math.clamp(playerPos.X + dx, 1, size)
		playerPos.Y = math.clamp(playerPos.Y + dy, 1, size)
		if isGuard(playerPos.X, playerPos.Y) then sendBurglaryResult("caught"); return end
		if tonumber(lootPos.X) == playerPos.X and tonumber(lootPos.Y) == playerPos.Y then hasLoot = true end
		if hasLoot and tonumber(exitPos.X) == playerPos.X and tonumber(exitPos.Y) == playerPos.Y then sendBurglaryResult("success"); return end
		redraw()
	end

	local up = makeBlackjackButton(panel, "UP", 0.345, Color3.fromRGB(104, 76, 47)); up.Position = UDim2.new(0.345, 0, 1, -88)
	local left = makeBlackjackButton(panel, "LEFT", 0.035, Color3.fromRGB(75, 70, 68))
	local down = makeBlackjackButton(panel, "DOWN", 0.345, Color3.fromRGB(75, 70, 68))
	local right = makeBlackjackButton(panel, "RIGHT", 0.655, Color3.fromRGB(75, 70, 68))
	if compactLandscape then
		local moveW, moveH = 92, 34
		up.Size = UDim2.new(0, moveW, 0, moveH)
		left.Size = UDim2.new(0, moveW, 0, moveH)
		down.Size = UDim2.new(0, moveW, 0, moveH)
		right.Size = UDim2.new(0, moveW, 0, moveH)
		up.Position = UDim2.new(1, -154, 0, 92)
		left.Position = UDim2.new(1, -204, 0, 134)
		down.Position = UDim2.new(1, -154, 0, 176)
		right.Position = UDim2.new(1, -104, 0, 134)
	end
	up.MouseButton1Click:Connect(function() step(0, -1) end)
	down.MouseButton1Click:Connect(function() step(0, 1) end)
	left.MouseButton1Click:Connect(function() step(-1, 0) end)
	right.MouseButton1Click:Connect(function() step(1, 0) end)

	active = { Kind = "Burglary", Token = token, Root = root }
	redraw()
	setConsoleSelection(up)
end

local function openHeirloom(payload)
	destroyActive()
	local token = tostring(payload.Token or "")
	if token == "" then return end
	local target = math.clamp(tonumber(payload.Target) or 5, 1, 9)
	local guessesLeft = math.clamp(tonumber(payload.Guesses) or 3, 1, 5)

	local root = Instance.new("Frame")
	root.Name = "HeirloomMinigame"
	root.Size = UDim2.new(1, 0, 1, 0)
	root.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	root.BackgroundTransparency = 0.38
	root.BorderSizePixel = 0
	root.ZIndex = 760
	root.Parent = gui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.new(0.5, 0, 0.52, 0)
	fitMinigamePanel(panel, 390, 390, 500, 310)
	panel.BackgroundColor3 = Color3.fromRGB(31, 25, 21)
	panel.BorderSizePixel = 0
	panel.ZIndex = 761
	panel.Parent = root
	addCorner(panel, 10)
	addStroke(panel, Color3.fromRGB(174, 130, 75), 1, 0.08)

	local compactLandscape = isMobileLandscapeViewport()
	makeBlackjackText(panel, "HEIRLOOM SEARCH", compactLandscape and 16 or 20, Color3.fromRGB(248, 231, 200), UDim2.new(0, 22, 0, 18), UDim2.new(1, -44, 0, 28), true)
	local statusLabel = makeBlackjackText(panel, "Pick an old box. Guesses left: " .. tostring(guessesLeft), compactLandscape and 11 or 13, Color3.fromRGB(214, 193, 162), UDim2.new(0, 22, 0, 52), UDim2.new(1, -44, 0, 36), false)

	local grid = Instance.new("Frame")
	local gridW = compactLandscape and 300 or 270
	local gridH = compactLandscape and 168 or 210
	grid.Position = UDim2.new(0.5, -gridW / 2, 0, compactLandscape and 92 or 105)
	grid.Size = UDim2.new(0, gridW, 0, gridH)
	grid.BackgroundTransparency = 1
	grid.ZIndex = 762
	grid.Parent = panel

	active = { Kind = "Heirloom", Token = token, Root = root }
	for i = 1, 9 do
		local button = Instance.new("TextButton")
		local x = (i - 1) % 3
		local y = math.floor((i - 1) / 3)
		button.Size = UDim2.new(0, compactLandscape and 90 or 80, 0, compactLandscape and 46 or 60)
		button.Position = UDim2.new(0, x * (compactLandscape and 105 or 95), 0, y * (compactLandscape and 58 or 72))
		button.BackgroundColor3 = Color3.fromRGB(84, 61, 38)
		button.BorderSizePixel = 0
		button.TextColor3 = Color3.fromRGB(248, 232, 202)
		button.TextSize = 12
		button.Font = Enum.Font.GothamBlack
		button.Text = "BOX " .. tostring(i)
		button.AutoButtonColor = true
		button.Selectable = true
		button.ZIndex = 763
		button.Parent = grid
		addCorner(button, 8)
		addStroke(button, Color3.fromRGB(190, 143, 82), 1, 0.45)
		button.MouseButton1Click:Connect(function()
			if not active or active.Kind ~= "Heirloom" or button:GetAttribute("Opened") == true then return end
			button:SetAttribute("Opened", true)
			if i == target then
				button.Text = "FOUND"
				button.BackgroundColor3 = Color3.fromRGB(92, 116, 67)
				sendHeirloomResult("success")
				return
			end
			guessesLeft -= 1
			button.Text = "EMPTY"
			button.BackgroundColor3 = Color3.fromRGB(58, 52, 48)
			statusLabel.Text = "Dust and old receipts. Guesses left: " .. tostring(guessesLeft)
			if guessesLeft <= 0 then
				sendHeirloomResult("miss")
			end
		end)
		if i == 1 then setConsoleSelection(button) end
	end
end

local function openCursedFingerHunt(payload)
	destroyActive()
	local token = tostring(payload.Token or "")
	if token == "" then return end
	local size = math.clamp(tonumber(payload.Size) or 6, 4, 7)
	local goal = math.clamp(tonumber(payload.Goal) or 5, 1, 10)
	local playerPos = { X = 1, Y = size }
	local fingerPos = { X = size, Y = 1 }
	local cursePos = { X = size, Y = math.max(1, size - 1) }
	local collected = 0
	local steps = 0

	local root = Instance.new("Frame")
	root.Name = "CursedFingerHuntMinigame"
	root.Size = UDim2.new(1, 0, 1, 0)
	root.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	root.BackgroundTransparency = 0.34
	root.BorderSizePixel = 0
	root.ZIndex = 760
	root.Parent = gui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.new(0.5, 0, 0.52, 0)
	fitMinigamePanel(panel, 430, 520, 520, 330)
	panel.BackgroundColor3 = Color3.fromRGB(28, 17, 22)
	panel.BorderSizePixel = 0
	panel.ZIndex = 761
	panel.Parent = root
	addCorner(panel, 10)
	addStroke(panel, Color3.fromRGB(160, 62, 77), 1, 0.08)

	local compactLandscape = isMobileLandscapeViewport()
	makeBlackjackText(panel, "CURSED FINGER HUNT", compactLandscape and 16 or 20, Color3.fromRGB(252, 226, 230), UDim2.new(0, 22, 0, 18), UDim2.new(1, -44, 0, 28), true)
	local statusLabel = makeBlackjackText(panel, "Collect fingers: 0/" .. tostring(goal), compactLandscape and 11 or 13, Color3.fromRGB(220, 180, 188), UDim2.new(0, 22, 0, 52), UDim2.new(1, -44, 0, 38), false)
	makeBlackjackText(panel, "Input: 0/" .. tostring(goal), compactLandscape and 12 or 13, Color3.fromRGB(226, 246, 250), UDim2.new(0, 22, 0, compactLandscape and 88 or 98), UDim2.new(1, -44, 0, 28), true)
	local board = Instance.new("Frame")
	local boardSize = compactLandscape and 190 or 300
	board.Position = compactLandscape and UDim2.new(0, 36, 0, 88) or UDim2.new(0.5, -boardSize / 2, 0, 105)
	board.Size = UDim2.new(0, boardSize, 0, boardSize)
	board.BackgroundTransparency = 1
	board.ZIndex = 762
	board.Parent = panel

	local cells = {}
	local function key(x, y) return tostring(x) .. ":" .. tostring(y) end
	local function placeFinger()
		repeat
			fingerPos.X = math.random(1, size)
			fingerPos.Y = math.random(1, size)
		until (fingerPos.X ~= playerPos.X or fingerPos.Y ~= playerPos.Y) and (fingerPos.X ~= cursePos.X or fingerPos.Y ~= cursePos.Y)
	end
	local function moveCurse()
		if math.abs(cursePos.X - playerPos.X) >= math.abs(cursePos.Y - playerPos.Y) then
			cursePos.X += cursePos.X < playerPos.X and 1 or (cursePos.X > playerPos.X and -1 or 0)
		else
			cursePos.Y += cursePos.Y < playerPos.Y and 1 or (cursePos.Y > playerPos.Y and -1 or 0)
		end
	end
	local function redraw()
		for y = 1, size do
			for x = 1, size do
				local cell = cells[key(x, y)]
				cell.Text = ""
				cell.BackgroundColor3 = Color3.fromRGB(39, 27, 32)
				if playerPos.X == x and playerPos.Y == y then
					cell.Text = "YOU"
					cell.BackgroundColor3 = Color3.fromRGB(91, 55, 72)
				elseif cursePos.X == x and cursePos.Y == y then
					cell.Text = "C"
					cell.BackgroundColor3 = Color3.fromRGB(92, 24, 34)
				elseif fingerPos.X == x and fingerPos.Y == y then
					cell.Text = "F"
					cell.BackgroundColor3 = Color3.fromRGB(132, 44, 58)
				end
			end
		end
		statusLabel.Text = "Collect fingers: " .. tostring(collected) .. "/" .. tostring(goal)
	end
	for y = 1, size do
		for x = 1, size do
			local cell = Instance.new("TextLabel")
			cell.Size = UDim2.new(1 / size, -5, 1 / size, -5)
			cell.Position = UDim2.new((x - 1) / size, 3, (y - 1) / size, 3)
			cell.BackgroundColor3 = Color3.fromRGB(39, 27, 32)
			cell.BorderSizePixel = 0
			cell.TextColor3 = Color3.fromRGB(250, 226, 230)
			cell.TextSize = 11
			cell.Font = Enum.Font.GothamBlack
			cell.ZIndex = 763
			cell.Parent = board
			addCorner(cell, 6)
			cells[key(x, y)] = cell
		end
	end
	local function step(dx, dy)
		playerPos.X = math.clamp(playerPos.X + dx, 1, size)
		playerPos.Y = math.clamp(playerPos.Y + dy, 1, size)
		steps += 1
		if playerPos.X == fingerPos.X and playerPos.Y == fingerPos.Y then
			collected += 1
			if collected >= goal then sendFingerResult(collected); return end
			placeFinger()
		end
		if steps % 2 == 0 then
			moveCurse()
		end
		if playerPos.X == cursePos.X and playerPos.Y == cursePos.Y then
			statusLabel.Text = "A curse caught you. Prepare to fight."
			redraw()
			task.delay(0.25, function()
				sendFingerResult("caught:" .. tostring(collected))
			end)
			return
		end
		redraw()
	end
	local up = makeBlackjackButton(panel, "UP", 0.345, Color3.fromRGB(112, 46, 58)); up.Position = UDim2.new(0.345, 0, 1, -88)
	local left = makeBlackjackButton(panel, "LEFT", 0.035, Color3.fromRGB(72, 46, 54))
	local down = makeBlackjackButton(panel, "DOWN", 0.345, Color3.fromRGB(72, 46, 54))
	local right = makeBlackjackButton(panel, "RIGHT", 0.655, Color3.fromRGB(72, 46, 54))
	if compactLandscape then
		local moveW, moveH = 92, 34
		up.Size = UDim2.new(0, moveW, 0, moveH)
		left.Size = UDim2.new(0, moveW, 0, moveH)
		down.Size = UDim2.new(0, moveW, 0, moveH)
		right.Size = UDim2.new(0, moveW, 0, moveH)
		up.Position = UDim2.new(1, -154, 0, 92)
		left.Position = UDim2.new(1, -204, 0, 134)
		down.Position = UDim2.new(1, -154, 0, 176)
		right.Position = UDim2.new(1, -104, 0, 134)
	end
	up.MouseButton1Click:Connect(function() step(0, -1) end)
	down.MouseButton1Click:Connect(function() step(0, 1) end)
	left.MouseButton1Click:Connect(function() step(-1, 0) end)
	right.MouseButton1Click:Connect(function() step(1, 0) end)
	active = { Kind = "CursedFinger", Token = token, Root = root }
	redraw()
	setConsoleSelection(up)
end

local function openRCTMemory(payload)
	destroyActive()
	local token = tostring(payload.Token or "")
	if token == "" then return end
	local sequence = typeof(payload.Sequence) == "table" and payload.Sequence or { 1, 2, 3, 4 }
	local input = {}
	local colors = {
		Color3.fromRGB(66, 128, 180),
		Color3.fromRGB(96, 168, 112),
		Color3.fromRGB(190, 145, 66),
		Color3.fromRGB(168, 78, 104),
	}
	local labels = { "BLUE", "GREEN", "GOLD", "RED" }

	local root = Instance.new("Frame")
	root.Name = "RCTMemoryMinigame"
	root.Size = UDim2.new(1, 0, 1, 0)
	root.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	root.BackgroundTransparency = 0.34
	root.BorderSizePixel = 0
	root.ZIndex = 760
	root.Parent = gui

	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local portrait = viewport.Y > viewport.X
	local compactLandscape = isMobileLandscapeViewport()
	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(18, 30, 35)
	panel.BorderSizePixel = 0
	panel.ZIndex = 761
	panel.Parent = root
	addCorner(panel, 10)
	addStroke(panel, Color3.fromRGB(88, 160, 180), 1, 0.08)
	responsiveScale.attach(panel, 430, 360)

	makeBlackjackText(panel, "RCT MEMORY DRILL", (portrait or compactLandscape) and 17 or 20, Color3.fromRGB(226, 246, 250), UDim2.new(0, 22, 0, portrait and 16 or 18), UDim2.new(1, -44, 0, 28), true)
	makeBlackjackText(panel, "Memorize: " .. table.concat(sequence, " - "), (portrait or compactLandscape) and 11 or 13, Color3.fromRGB(178, 216, 224), UDim2.new(0, 22, 0, portrait and 48 or 52), UDim2.new(1, -44, 0, portrait and 40 or 48), false)
	local inputLabel = makeBlackjackText(panel, "Input: 0/" .. tostring(#sequence), (portrait or compactLandscape) and 12 or 13, Color3.fromRGB(226, 246, 250), UDim2.new(0, 22, 0, portrait and 88 or 98), UDim2.new(1, -44, 0, 28), true)

	active = { Kind = "RCTMemory", Token = token, Root = root }
	for i = 1, 4 do
		local button = Instance.new("TextButton")
		local x = (i - 1) % 2
		local y = math.floor((i - 1) / 2)
		if portrait then
			button.Size = UDim2.new(0.44, 0, 0, 58)
			button.Position = UDim2.new(x == 0 and 0.04 or 0.52, 0, 0, 128 + y * 72)
		elseif compactLandscape then
			button.Size = UDim2.new(0.44, 0, 0, 48)
			button.Position = UDim2.new(x == 0 and 0.04 or 0.52, 0, 0, 122 + y * 58)
		else
			button.Size = UDim2.new(0, 180, 0, 68)
			button.Position = UDim2.new(0, 28 + x * 196, 0, 145 + y * 82)
		end
		button.BackgroundColor3 = colors[i]
		button.BorderSizePixel = 0
		button.TextColor3 = Color3.fromRGB(248, 252, 252)
		button.TextSize = (portrait or compactLandscape) and 11 or 13
		button.Font = Enum.Font.GothamBlack
		button.Text = tostring(i) .. "  " .. labels[i]
		button.AutoButtonColor = true
		button.Selectable = true
		button.ZIndex = 763
		button.Parent = panel
		addCorner(button, 9)
		addStroke(button, Color3.fromRGB(230, 250, 250), 1, 0.55)
		button.MouseButton1Click:Connect(function()
			if not active or active.Kind ~= "RCTMemory" then return end
			table.insert(input, i)
			inputLabel.Text = "Input: " .. tostring(#input) .. "/" .. tostring(#sequence)
			if #input >= #sequence then
				sendRCTResult(input)
			end
		end)
		if i == 1 then setConsoleSelection(button) end
	end
end

function MinigamesPanel.init(playerGui: PlayerGui)
	local existing = playerGui:FindFirstChild("BitKaisenMinigamesGui")
	if existing then
		existing:Destroy()
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "BitKaisenMinigamesGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Enabled = false
	gui.DisplayOrder = 660
	gui.Parent = playerGui

	startMinigame = ReplicatedStorage:WaitForChild("StartMinigame", 20)
	completeMinigame = ReplicatedStorage:WaitForChild("CompleteMinigame", 20)

	UserInputService.LastInputTypeChanged:Connect(function(inputType)
		gamepadInputActive = inputType == Enum.UserInputType.Gamepad1
		if not gamepadInputActive then
			setConsoleSelection(nil)
		end
	end)

	if startMinigame and startMinigame:IsA("RemoteEvent") then
		startMinigame.OnClientEvent:Connect(function(payload)
			if typeof(payload) ~= "table" then
				return
			end

			gui.Enabled = true

			if payload.Type == "BlackFlashTiming" then
				openBlackFlashTiming(payload)
			elseif payload.Type == "Blackjack" then
				openBlackjack(payload)
			elseif payload.Type == "Burglary" then
				openBurglary(payload)
			elseif payload.Type == "Heirloom" then
				openHeirloom(payload)
			elseif payload.Type == "CursedFingerHunt" then
				openCursedFingerHunt(payload)
			elseif payload.Type == "RCTMemory" then
				openRCTMemory(payload)
			end
		end)
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not active or gameProcessed then
			return
		end
		if active.Kind ~= "BlackFlashTiming" then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space then
			submitActive(false)
		elseif input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonA then
			submitActive(false)
		end
	end)

	if RunService:IsStudio() then
		print("[MinigamesPanel] Loaded Black Flash, 21 Card Game, Burglary, Heirloom, Cursed Finger, and RCT minigame UI.")
	end
end

return MinigamesPanel
