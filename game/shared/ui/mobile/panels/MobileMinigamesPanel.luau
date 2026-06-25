local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local mc = require("@ui/mobile/mobileComponents")

local theme = mc.theme
local corner = mc.corner
local stroke = mc.stroke
local bindTap = mc.bindTap

local MobileMinigamesPanel = {}

local gui: ScreenGui
local active = nil

local startMinigame: RemoteEvent?
local completeMinigame: RemoteEvent?

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

local function sendBlackjackAction(action)
	if not active or active.Kind ~= "Blackjack" then
		return
	end
	if completeMinigame and completeMinigame:IsA("RemoteEvent") then
		completeMinigame:FireServer(active.Token, 0, action)
	end
end

local function sendRCTResult(sequence)
	if not active or active.Kind ~= "RCTMemory" then
		return
	end
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

local function makeLabel(parent, text, size, color, pos, frameSize, bold)
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

local function makeActionButton(parent, text, pos, size, color)
	local btn = Instance.new("TextButton")
	btn.Size = size or UDim2.new(1, -32, 0, 50)
	btn.Position = pos or UDim2.new(0, 16, 0, 0)
	btn.BackgroundColor3 = color or theme.Button
	btn.BorderSizePixel = 0
	btn.TextColor3 = theme.Text
	btn.TextSize = 15
	btn.Font = Enum.Font.GothamBlack
	btn.Text = text
	btn.AutoButtonColor = true
	btn.ZIndex = 763
	btn.Parent = parent
	corner(btn, 10)
	stroke(btn, theme.StrokeSoft)
	return btn
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
	root.Name = "MobileBlackFlashTiming"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	root.BackgroundTransparency = 0.3
	root.BorderSizePixel = 0
	root.ZIndex = 760
	root.Parent = gui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(1, -32, 0, 280)
	panel.BackgroundColor3 = Color3.fromRGB(13, 13, 20)
	panel.BorderSizePixel = 0
	panel.ZIndex = 761
	panel.Parent = root
	corner(panel, 14)
	stroke(panel, Color3.fromRGB(82, 58, 122))

	makeLabel(panel, tostring(payload.Title or "Timing Challenge"), 20, Color3.fromRGB(245, 241, 255), UDim2.new(0, 18, 0, 18), UDim2.new(1, -36, 0, 28), true)
	makeLabel(panel, tostring(payload.Body or "Stop the marker inside the impact window."), 13, Color3.fromRGB(184, 180, 202), UDim2.new(0, 18, 0, 52), UDim2.new(1, -36, 0, 42), false)

	local track = Instance.new("Frame")
	track.Position = UDim2.new(0, 24, 0, 112)
	track.Size = UDim2.new(1, -48, 0, 24)
	track.BackgroundColor3 = Color3.fromRGB(28, 26, 38)
	track.BorderSizePixel = 0
	track.ZIndex = 762
	track.Parent = panel
	corner(track, 999)
	stroke(track, Color3.fromRGB(55, 49, 76))

	local zone = Instance.new("Frame")
	zone.AnchorPoint = Vector2.new(0.5, 0.5)
	zone.Position = UDim2.new(target, 0, 0.5, 0)
	zone.Size = UDim2.new(0, 60, 1, 12)
	zone.BackgroundColor3 = Color3.fromRGB(185, 70, 92)
	zone.BorderSizePixel = 0
	zone.ZIndex = 763
	zone.Parent = track
	corner(zone, 999)

	local perfect = Instance.new("Frame")
	perfect.AnchorPoint = Vector2.new(0.5, 0.5)
	perfect.Position = UDim2.fromScale(0.5, 0.5)
	perfect.Size = UDim2.new(0, 16, 1, 14)
	perfect.BackgroundColor3 = Color3.fromRGB(255, 214, 105)
	perfect.BorderSizePixel = 0
	perfect.ZIndex = 764
	perfect.Parent = zone
	corner(perfect, 999)

	local marker = Instance.new("Frame")
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.Position = UDim2.new(0, 0, 0.5, 0)
	marker.Size = UDim2.new(0, 14, 1, 32)
	marker.BackgroundColor3 = Color3.fromRGB(238, 235, 255)
	marker.BorderSizePixel = 0
	marker.ZIndex = 765
	marker.Parent = track
	corner(marker, 999)

	local resultLabel = Instance.new("TextLabel")
	resultLabel.BackgroundTransparency = 1
	resultLabel.Position = UDim2.new(0, 18, 0, 148)
	resultLabel.Size = UDim2.new(1, -36, 0, 28)
	resultLabel.TextColor3 = Color3.fromRGB(255, 214, 105)
	resultLabel.TextTransparency = 1
	resultLabel.TextSize = 20
	resultLabel.Font = Enum.Font.GothamBlack
	resultLabel.TextXAlignment = Enum.TextXAlignment.Center
	resultLabel.Text = ""
	resultLabel.ZIndex = 762
	resultLabel.Parent = panel

	local hitButton = makeActionButton(panel, "STRIKE", UDim2.new(0, 16, 1, -70), UDim2.new(1, -32, 0, 54), Color3.fromRGB(78, 27, 41))
	stroke(hitButton, Color3.fromRGB(190, 72, 94))

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

	bindTap(hitButton, function()
		submitActive(false)
	end)
end

local function openBlackjack(payload)
	destroyActive()

	local token = tostring(payload.Token or "")
	if token == "" then
		return
	end

	local root = Instance.new("Frame")
	root.Name = "MobileBlackjack"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	root.BackgroundTransparency = 0.3
	root.BorderSizePixel = 0
	root.ZIndex = 760
	root.Parent = gui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(1, -32, 0, 360)
	panel.BackgroundColor3 = Color3.fromRGB(12, 31, 27)
	panel.BorderSizePixel = 0
	panel.ZIndex = 761
	panel.Parent = root
	corner(panel, 14)
	stroke(panel, Color3.fromRGB(94, 150, 120))

	makeLabel(panel, "21 CARD GAME", 20, Color3.fromRGB(238, 246, 228), UDim2.new(0, 18, 0, 18), UDim2.new(1, -36, 0, 28), true)

	local wager = tostring(payload.Wager or 100)
	local status = tostring(payload.Status or "Beat the dealer without going over 21. Wager: $" .. wager)
	makeLabel(panel, status, 13, Color3.fromRGB(190, 212, 196), UDim2.new(0, 18, 0, 52), UDim2.new(1, -36, 0, 48), false)
	makeLabel(panel, "Dealer: " .. tostring(payload.DealerText or "?"), 16, Color3.fromRGB(255, 218, 130), UDim2.new(0, 18, 0, 116), UDim2.new(1, -36, 0, 34), true)
	makeLabel(panel, "You: " .. tostring(payload.PlayerText or "?"), 16, Color3.fromRGB(235, 240, 235), UDim2.new(0, 18, 0, 162), UDim2.new(1, -36, 0, 46), true)

	local btnH = 50
	local btnGap = 8
	local btnY = 360 - 18 - (btnH * 3) - (btnGap * 2)

	local hit = makeActionButton(panel, "HIT", UDim2.new(0, 16, 0, btnY), UDim2.new(1, -32, 0, btnH), Color3.fromRGB(44, 112, 82))
	local stand = makeActionButton(panel, "STAND", UDim2.new(0, 16, 0, btnY + btnH + btnGap), UDim2.new(1, -32, 0, btnH), Color3.fromRGB(64, 89, 134))
	local leave = makeActionButton(panel, payload.Done and "CLOSE" or "LEAVE", UDim2.new(0, 16, 0, btnY + (btnH + btnGap) * 2), UDim2.new(1, -32, 0, btnH), Color3.fromRGB(124, 54, 60))

	active = { Kind = "Blackjack", Token = token, Root = root }

	if payload.Done == true then
		hit.Active = false
		stand.Active = false
		hit.TextTransparency = 0.45
		stand.TextTransparency = 0.45
	end

	bindTap(hit, function()
		sendBlackjackAction("hit")
	end)
	bindTap(stand, function()
		sendBlackjackAction("stand")
	end)
	bindTap(leave, function()
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
	if token == "" then
		return
	end

	local size = math.clamp(tonumber(payload.Size) or 5, 4, 6)
	local playerPos = { X = 1, Y = size }
	local lootPos = payload.Loot or { X = math.ceil(size / 2), Y = math.ceil(size / 2) }
	local exitPos = payload.Exit or { X = size, Y = 1 }
	local guards = typeof(payload.Guards) == "table" and payload.Guards or {}
	local hasLoot = false

	local root = Instance.new("Frame")
	root.Name = "MobileBurglary"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	root.BackgroundTransparency = 0.28
	root.BorderSizePixel = 0
	root.ZIndex = 760
	root.Parent = gui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(1, -24, 0, 520)
	panel.BackgroundColor3 = Color3.fromRGB(25, 22, 19)
	panel.BorderSizePixel = 0
	panel.ZIndex = 761
	panel.Parent = root
	corner(panel, 14)
	stroke(panel, Color3.fromRGB(154, 112, 67))

	makeLabel(panel, "BURGLARY", 20, Color3.fromRGB(246, 233, 206), UDim2.new(0, 18, 0, 16), UDim2.new(0.6, 0, 0, 28), true)

	local leaveBtn = makeActionButton(panel, "LEAVE", UDim2.new(1, -90, 0, 14), UDim2.new(0, 72, 0, 32), Color3.fromRGB(105, 54, 54))
	leaveBtn.TextSize = 12
	bindTap(leaveBtn, function()
		sendBurglaryResult("fled")
	end)

	local statusLabel = makeLabel(panel, "Grab the loot, then reach the exit. Avoid guards.", 13, Color3.fromRGB(210, 192, 166), UDim2.new(0, 18, 0, 50), UDim2.new(1, -36, 0, 36), false)

	local boardSize = 260
	local board = Instance.new("Frame")
	board.AnchorPoint = Vector2.new(0.5, 0)
	board.Position = UDim2.new(0.5, 0, 0, 96)
	board.Size = UDim2.fromOffset(boardSize, boardSize)
	board.BackgroundTransparency = 1
	board.ZIndex = 762
	board.Parent = panel

	local cells = {}
	local function key(x, y)
		return tostring(x) .. ":" .. tostring(y)
	end
	local function isGuard(x, y)
		for _, guard in ipairs(guards) do
			if tonumber(guard.X) == x and tonumber(guard.Y) == y then
				return true
			end
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
					text = "YOU"
					color = Color3.fromRGB(74, 119, 82)
				elseif isGuard(x, y) then
					text = "G"
					color = Color3.fromRGB(116, 46, 49)
				elseif not hasLoot and tonumber(lootPos.X) == x and tonumber(lootPos.Y) == y then
					text = "$"
					color = Color3.fromRGB(132, 102, 42)
				elseif tonumber(exitPos.X) == x and tonumber(exitPos.Y) == y then
					text = "EXIT"
					color = Color3.fromRGB(52, 82, 112)
				end
				cell.Text = text
				cell.BackgroundColor3 = color
			end
		end
		statusLabel.Text = hasLoot and "Loot secured. Reach the exit." or "Find the loot, then escape."
	end

	for y = 1, size do
		for x = 1, size do
			local cell = Instance.new("TextLabel")
			cell.Size = UDim2.new(1 / size, -4, 1 / size, -4)
			cell.Position = UDim2.new((x - 1) / size, 2, (y - 1) / size, 2)
			cell.BackgroundColor3 = Color3.fromRGB(42, 38, 33)
			cell.BorderSizePixel = 0
			cell.TextColor3 = Color3.fromRGB(246, 238, 220)
			cell.TextSize = 13
			cell.Font = Enum.Font.GothamBlack
			cell.ZIndex = 763
			cell.Parent = board
			corner(cell, 6)
			cells[key(x, y)] = cell
		end
	end

	local function step(dx, dy)
		playerPos.X = math.clamp(playerPos.X + dx, 1, size)
		playerPos.Y = math.clamp(playerPos.Y + dy, 1, size)
		if isGuard(playerPos.X, playerPos.Y) then
			sendBurglaryResult("caught")
			return
		end
		if tonumber(lootPos.X) == playerPos.X and tonumber(lootPos.Y) == playerPos.Y then
			hasLoot = true
		end
		if hasLoot and tonumber(exitPos.X) == playerPos.X and tonumber(exitPos.Y) == playerPos.Y then
			sendBurglaryResult("success")
			return
		end
		redraw()
	end

	local dpadY = 370
	local dpadBtnSize = UDim2.new(0, 72, 0, 50)
	local dpadCenter = 0.5

	local up = makeActionButton(panel, "UP", UDim2.new(dpadCenter, -36, 0, dpadY), dpadBtnSize, Color3.fromRGB(104, 76, 47))
	local left = makeActionButton(panel, "LEFT", UDim2.new(dpadCenter, -112, 0, dpadY + 56), dpadBtnSize, Color3.fromRGB(75, 70, 68))
	local down = makeActionButton(panel, "DOWN", UDim2.new(dpadCenter, -36, 0, dpadY + 56), dpadBtnSize, Color3.fromRGB(75, 70, 68))
	local right = makeActionButton(panel, "RIGHT", UDim2.new(dpadCenter, 40, 0, dpadY + 56), dpadBtnSize, Color3.fromRGB(75, 70, 68))

	bindTap(up, function() step(0, -1) end)
	bindTap(down, function() step(0, 1) end)
	bindTap(left, function() step(-1, 0) end)
	bindTap(right, function() step(1, 0) end)

	active = { Kind = "Burglary", Token = token, Root = root }
	redraw()
end

local function openHeirloom(payload)
	destroyActive()
	local token = tostring(payload.Token or "")
	if token == "" then
		return
	end
	local target = math.clamp(tonumber(payload.Target) or 5, 1, 9)
	local guessesLeft = math.clamp(tonumber(payload.Guesses) or 3, 1, 5)

	local root = Instance.new("Frame")
	root.Name = "MobileHeirloom"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	root.BackgroundTransparency = 0.3
	root.BorderSizePixel = 0
	root.ZIndex = 760
	root.Parent = gui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(1, -24, 0, 420)
	panel.BackgroundColor3 = Color3.fromRGB(31, 25, 21)
	panel.BorderSizePixel = 0
	panel.ZIndex = 761
	panel.Parent = root
	corner(panel, 14)
	stroke(panel, Color3.fromRGB(174, 130, 75))

	makeLabel(panel, "HEIRLOOM SEARCH", 20, Color3.fromRGB(248, 231, 200), UDim2.new(0, 18, 0, 18), UDim2.new(1, -36, 0, 28), true)
	local statusLabel = makeLabel(panel, "Pick an old box. Guesses left: " .. tostring(guessesLeft), 13, Color3.fromRGB(214, 193, 162), UDim2.new(0, 18, 0, 52), UDim2.new(1, -36, 0, 36), false)

	local gridW = 270
	local grid = Instance.new("Frame")
	grid.AnchorPoint = Vector2.new(0.5, 0)
	grid.Position = UDim2.new(0.5, 0, 0, 100)
	grid.Size = UDim2.fromOffset(gridW, 280)
	grid.BackgroundTransparency = 1
	grid.ZIndex = 762
	grid.Parent = panel

	active = { Kind = "Heirloom", Token = token, Root = root }

	for i = 1, 9 do
		local button = Instance.new("TextButton")
		local x = (i - 1) % 3
		local y = math.floor((i - 1) / 3)
		button.Size = UDim2.new(0, 82, 0, 82)
		button.Position = UDim2.new(0, x * 94, 0, y * 94)
		button.BackgroundColor3 = Color3.fromRGB(84, 61, 38)
		button.BorderSizePixel = 0
		button.TextColor3 = Color3.fromRGB(248, 232, 202)
		button.TextSize = 13
		button.Font = Enum.Font.GothamBlack
		button.Text = "BOX " .. tostring(i)
		button.AutoButtonColor = true
		button.ZIndex = 763
		button.Parent = grid
		corner(button, 10)
		stroke(button, Color3.fromRGB(190, 143, 82))

		bindTap(button, function()
			if not active or active.Kind ~= "Heirloom" or button:GetAttribute("Opened") == true then
				return
			end
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
	end
end

local function openCursedFingerHunt(payload)
	destroyActive()
	local token = tostring(payload.Token or "")
	if token == "" then
		return
	end
	local size = math.clamp(tonumber(payload.Size) or 6, 4, 7)
	local goal = math.clamp(tonumber(payload.Goal) or 5, 1, 10)
	local playerPos = { X = 1, Y = size }
	local fingerPos = { X = size, Y = 1 }
	local cursePos = { X = size, Y = math.max(1, size - 1) }
	local collected = 0
	local steps = 0

	local root = Instance.new("Frame")
	root.Name = "MobileCursedFingerHunt"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	root.BackgroundTransparency = 0.28
	root.BorderSizePixel = 0
	root.ZIndex = 760
	root.Parent = gui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(1, -24, 0, 540)
	panel.BackgroundColor3 = Color3.fromRGB(28, 17, 22)
	panel.BorderSizePixel = 0
	panel.ZIndex = 761
	panel.Parent = root
	corner(panel, 14)
	stroke(panel, Color3.fromRGB(160, 62, 77))

	makeLabel(panel, "CURSED FINGER HUNT", 18, Color3.fromRGB(252, 226, 230), UDim2.new(0, 18, 0, 16), UDim2.new(1, -36, 0, 28), true)
	local statusLabel = makeLabel(panel, "Collect fingers: 0/" .. tostring(goal), 13, Color3.fromRGB(220, 180, 188), UDim2.new(0, 18, 0, 48), UDim2.new(1, -36, 0, 28), false)

	local boardSize = 260
	local board = Instance.new("Frame")
	board.AnchorPoint = Vector2.new(0.5, 0)
	board.Position = UDim2.new(0.5, 0, 0, 86)
	board.Size = UDim2.fromOffset(boardSize, boardSize)
	board.BackgroundTransparency = 1
	board.ZIndex = 762
	board.Parent = panel

	local cells = {}
	local function key(x, y)
		return tostring(x) .. ":" .. tostring(y)
	end
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
			cell.Size = UDim2.new(1 / size, -4, 1 / size, -4)
			cell.Position = UDim2.new((x - 1) / size, 2, (y - 1) / size, 2)
			cell.BackgroundColor3 = Color3.fromRGB(39, 27, 32)
			cell.BorderSizePixel = 0
			cell.TextColor3 = Color3.fromRGB(250, 226, 230)
			cell.TextSize = 12
			cell.Font = Enum.Font.GothamBlack
			cell.ZIndex = 763
			cell.Parent = board
			corner(cell, 6)
			cells[key(x, y)] = cell
		end
	end

	local function step(dx, dy)
		playerPos.X = math.clamp(playerPos.X + dx, 1, size)
		playerPos.Y = math.clamp(playerPos.Y + dy, 1, size)
		steps += 1
		if playerPos.X == fingerPos.X and playerPos.Y == fingerPos.Y then
			collected += 1
			if collected >= goal then
				sendFingerResult(collected)
				return
			end
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

	local dpadY = 360
	local dpadBtnSize = UDim2.new(0, 72, 0, 50)
	local dpadCenter = 0.5

	local up = makeActionButton(panel, "UP", UDim2.new(dpadCenter, -36, 0, dpadY), dpadBtnSize, Color3.fromRGB(112, 46, 58))
	local left = makeActionButton(panel, "LEFT", UDim2.new(dpadCenter, -112, 0, dpadY + 56), dpadBtnSize, Color3.fromRGB(72, 46, 54))
	local down = makeActionButton(panel, "DOWN", UDim2.new(dpadCenter, -36, 0, dpadY + 56), dpadBtnSize, Color3.fromRGB(72, 46, 54))
	local right = makeActionButton(panel, "RIGHT", UDim2.new(dpadCenter, 40, 0, dpadY + 56), dpadBtnSize, Color3.fromRGB(72, 46, 54))

	bindTap(up, function() step(0, -1) end)
	bindTap(down, function() step(0, 1) end)
	bindTap(left, function() step(-1, 0) end)
	bindTap(right, function() step(1, 0) end)

	active = { Kind = "CursedFinger", Token = token, Root = root }
	redraw()
end

local function openRCTMemory(payload)
	destroyActive()
	local token = tostring(payload.Token or "")
	if token == "" then
		return
	end
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
	root.Name = "MobileRCTMemory"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	root.BackgroundTransparency = 0.28
	root.BorderSizePixel = 0
	root.ZIndex = 760
	root.Parent = gui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(1, -24, 0, 380)
	panel.BackgroundColor3 = Color3.fromRGB(18, 30, 35)
	panel.BorderSizePixel = 0
	panel.ZIndex = 761
	panel.Parent = root
	corner(panel, 14)
	stroke(panel, Color3.fromRGB(88, 160, 180))

	makeLabel(panel, "RCT MEMORY DRILL", 18, Color3.fromRGB(226, 246, 250), UDim2.new(0, 18, 0, 16), UDim2.new(1, -36, 0, 28), true)
	makeLabel(panel, "Memorize: " .. table.concat(sequence, " - "), 13, Color3.fromRGB(178, 216, 224), UDim2.new(0, 18, 0, 48), UDim2.new(1, -36, 0, 40), false)
	local inputLabel = makeLabel(panel, "Input: 0/" .. tostring(#sequence), 14, Color3.fromRGB(226, 246, 250), UDim2.new(0, 18, 0, 92), UDim2.new(1, -36, 0, 28), true)

	active = { Kind = "RCTMemory", Token = token, Root = root }

	for i = 1, 4 do
		local button = Instance.new("TextButton")
		local x = (i - 1) % 2
		local y = math.floor((i - 1) / 2)
		button.Size = UDim2.new(0.44, 0, 0, 72)
		button.Position = UDim2.new(x == 0 and 0.04 or 0.52, 0, 0, 132 + y * 84)
		button.BackgroundColor3 = colors[i]
		button.BorderSizePixel = 0
		button.TextColor3 = Color3.fromRGB(248, 252, 252)
		button.TextSize = 15
		button.Font = Enum.Font.GothamBlack
		button.Text = tostring(i) .. "  " .. labels[i]
		button.AutoButtonColor = true
		button.ZIndex = 763
		button.Parent = panel
		corner(button, 12)
		stroke(button, Color3.fromRGB(230, 250, 250))

		bindTap(button, function()
			if not active or active.Kind ~= "RCTMemory" then
				return
			end
			table.insert(input, i)
			inputLabel.Text = "Input: " .. tostring(#input) .. "/" .. tostring(#sequence)
			if #input >= #sequence then
				sendRCTResult(input)
			end
		end)
	end
end

function MobileMinigamesPanel.init(playerGui: PlayerGui)
	local existing = playerGui:FindFirstChild("MobileMinigamesGui")
	if existing then
		existing:Destroy()
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "MobileMinigamesGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.Enabled = false
	gui.DisplayOrder = 660
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	startMinigame = ReplicatedStorage:WaitForChild("StartMinigame", 20)
	completeMinigame = ReplicatedStorage:WaitForChild("CompleteMinigame", 20)

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

	if RunService:IsStudio() then
		print("[MobileMinigamesPanel] Loaded all minigame types for mobile.")
	end
end

return { init = MobileMinigamesPanel.init }
