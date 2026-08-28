-- LocalScript: BitKaisenVoDRCTUI
-- Location: StarterPlayerScripts
-- Purpose: 10-second Verge of Death RCT prompt — Force RCT or Accept Death.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local vodRCTPrompt = ReplicatedStorage:WaitForChild("VoDRCTPrompt")
local vodRCTResponse = ReplicatedStorage:WaitForChild("VoDRCTResponse")

-- Update 29: this used to be `playerGui:WaitForChild("BitKaisenGui")`, a ScreenGui
-- only the desktop shell creates. The mobile shell makes "MobileGui" instead, so on
-- phones this script yielded forever and the Verge of Death prompt never appeared:
-- the server still locked the player for the full 10 seconds and then killed them,
-- with the one-per-life RCT save silently unreachable. Hosting our own ScreenGui
-- makes the prompt shell-agnostic and keeps it above both UIs.
local vodGui = Instance.new("ScreenGui")
vodGui.Name = "BitKaisenVoDRCTGui"
vodGui.ResetOnSpawn = false
vodGui.IgnoreGuiInset = true
vodGui.DisplayOrder = 900
vodGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
vodGui.Parent = playerGui

local bitKaisenGui = vodGui

local ACCENT_COLOR = Color3.fromRGB(167, 130, 255)
local BG_COLOR = Color3.fromRGB(12, 12, 18)
local FORCE_COLOR = Color3.fromRGB(55, 35, 120)
local FORCE_HOVER = Color3.fromRGB(80, 52, 170)
local ACCEPT_COLOR = Color3.fromRGB(35, 20, 20)
local ACCEPT_HOVER = Color3.fromRGB(60, 30, 30)
local COUNTDOWN_FULL = Color3.fromRGB(167, 130, 255)
local COUNTDOWN_LOW = Color3.fromRGB(220, 80, 80)

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Parent = parent
end

local function setHover(btn, hover)
	local base = btn.BackgroundColor3
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = hover }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = base }):Play()
	end)
end

-- Build overlay
local existing = bitKaisenGui:FindFirstChild("VoDRCTOverlay")
if existing then existing:Destroy() end

local overlay = Instance.new("Frame")
overlay.Name = "VoDRCTOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.6
overlay.Visible = false
overlay.ZIndex = 850
overlay.Parent = bitKaisenGui

local window = Instance.new("Frame")
window.Name = "VoDWindow"
window.Size = UDim2.new(0, 500, 0, 360)
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.new(0.5, 0, 0.48, 0)
window.BackgroundColor3 = BG_COLOR
window.BackgroundTransparency = 0
window.BorderSizePixel = 0
window.ZIndex = 851
window.Parent = overlay
addCorner(window, 12)
addStroke(window, ACCENT_COLOR, 2)

-- Driven by applyResponsiveLayout so a short screen shrinks the window whole.
local windowScale = Instance.new("UIScale")
windowScale.Scale = 1
windowScale.Parent = window

local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.new(1, 0, 0, 4)
accentBar.BackgroundColor3 = ACCENT_COLOR
accentBar.BorderSizePixel = 0
accentBar.ZIndex = 852
accentBar.Parent = window
addCorner(accentBar, 4)
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, ACCENT_COLOR),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 80, 80)),
})
grad.Parent = accentBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 0, 44)
titleLabel.Position = UDim2.new(0, 20, 0, 20)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 24
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.Text = "VERGE OF DEATH"
titleLabel.ZIndex = 852
titleLabel.Parent = window

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Size = UDim2.new(1, -50, 0, 36)
subtitleLabel.Position = UDim2.new(0, 25, 0, 64)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.TextColor3 = Color3.fromRGB(180, 160, 220)
subtitleLabel.TextSize = 13
subtitleLabel.Font = Enum.Font.GothamBold
subtitleLabel.TextWrapped = true
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Center
subtitleLabel.Text = "You are on the brink of death. Force Reverse Cursed Technique to survive — at the cost of all your CE."
subtitleLabel.ZIndex = 852
subtitleLabel.Parent = window

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -60, 0, 1)
divider.Position = UDim2.new(0, 30, 0, 108)
divider.BackgroundColor3 = Color3.fromRGB(55, 45, 80)
divider.BorderSizePixel = 0
divider.ZIndex = 852
divider.Parent = window

local ceLabel = Instance.new("TextLabel")
ceLabel.Size = UDim2.new(1, -40, 0, 30)
ceLabel.Position = UDim2.new(0, 20, 0, 118)
ceLabel.BackgroundTransparency = 1
ceLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
ceLabel.TextSize = 13
ceLabel.Font = Enum.Font.Gotham
ceLabel.TextXAlignment = Enum.TextXAlignment.Center
ceLabel.RichText = true
ceLabel.ZIndex = 852
ceLabel.Parent = window

local warningLabel = Instance.new("TextLabel")
warningLabel.Size = UDim2.new(1, -40, 0, 22)
warningLabel.Position = UDim2.new(0, 20, 0, 148)
warningLabel.BackgroundTransparency = 1
warningLabel.TextColor3 = Color3.fromRGB(220, 140, 50)
warningLabel.TextSize = 12
warningLabel.Font = Enum.Font.GothamBold
warningLabel.TextXAlignment = Enum.TextXAlignment.Center
warningLabel.Text = "One use per life. You will survive with minimal health."
warningLabel.ZIndex = 852
warningLabel.Parent = window

-- Countdown bar background
local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1, -60, 0, 8)
barBg.Position = UDim2.new(0, 30, 0, 182)
barBg.BackgroundColor3 = Color3.fromRGB(30, 25, 45)
barBg.BorderSizePixel = 0
barBg.ZIndex = 852
barBg.Parent = window
addCorner(barBg, 4)

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(1, 0, 1, 0)
barFill.BackgroundColor3 = COUNTDOWN_FULL
barFill.BorderSizePixel = 0
barFill.ZIndex = 853
barFill.Parent = barBg
addCorner(barFill, 4)

local countdownLabel = Instance.new("TextLabel")
countdownLabel.Size = UDim2.new(1, -40, 0, 20)
countdownLabel.Position = UDim2.new(0, 20, 0, 192)
countdownLabel.BackgroundTransparency = 1
countdownLabel.TextColor3 = Color3.fromRGB(180, 160, 220)
countdownLabel.TextSize = 12
countdownLabel.Font = Enum.Font.GothamBold
countdownLabel.TextXAlignment = Enum.TextXAlignment.Center
countdownLabel.ZIndex = 852
countdownLabel.Parent = window

-- Buttons
local forceBtn = Instance.new("TextButton")
forceBtn.AnchorPoint = Vector2.new(0.5, 0)
forceBtn.Size = UDim2.new(0, 200, 0, 48)
forceBtn.Position = UDim2.new(0.5, -105, 0, 288)
forceBtn.BackgroundColor3 = FORCE_COLOR
forceBtn.BorderSizePixel = 0
forceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
forceBtn.TextSize = 14
forceBtn.Font = Enum.Font.GothamBlack
forceBtn.Text = "FORCE RCT"
forceBtn.ZIndex = 852
forceBtn.Parent = window
addCorner(forceBtn, 8)
addStroke(forceBtn, ACCENT_COLOR, 1.5)
setHover(forceBtn, FORCE_HOVER)

local acceptBtn = Instance.new("TextButton")
acceptBtn.AnchorPoint = Vector2.new(0.5, 0)
acceptBtn.Size = UDim2.new(0, 200, 0, 48)
acceptBtn.Position = UDim2.new(0.5, 105, 0, 288)
acceptBtn.BackgroundColor3 = ACCEPT_COLOR
acceptBtn.BorderSizePixel = 0
acceptBtn.TextColor3 = Color3.fromRGB(200, 150, 150)
acceptBtn.TextSize = 14
acceptBtn.Font = Enum.Font.GothamBold
acceptBtn.Text = "ACCEPT DEATH"
acceptBtn.ZIndex = 852
acceptBtn.Parent = window
addCorner(acceptBtn, 8)
addStroke(acceptBtn, Color3.fromRGB(80, 40, 40), 1.5)
setHover(acceptBtn, ACCEPT_HOVER)

-- The window is 500x360, which overflows a phone in portrait and pushed both buttons
-- off-screen. Narrow viewports get a stacked button layout, and short ones get the
-- window scaled down so it cannot spill past the top edge.
--
-- Measured from the ScreenGui rather than workspace.CurrentCamera.ViewportSize: under
-- Studio's device emulator the camera reports 1x1 while the GUI correctly reports the
-- emulated screen, so reading the camera skipped the whole layout.
local BASE_WIDTH, BASE_HEIGHT = 500, 360
local NARROW_HEIGHT = 400

local function applyResponsiveLayout()
	local viewport = vodGui.AbsoluteSize
	if viewport.X < 2 or viewport.Y < 2 then
		return
	end

	local width, height
	if viewport.X < 560 then
		width = math.clamp(viewport.X - 40, 260, 440)
		height = NARROW_HEIGHT
		local buttonWidth = width - 60
		forceBtn.Size = UDim2.new(0, buttonWidth, 0, 46)
		forceBtn.Position = UDim2.new(0.5, 0, 0, 276)
		acceptBtn.Size = UDim2.new(0, buttonWidth, 0, 46)
		acceptBtn.Position = UDim2.new(0.5, 0, 0, 332)
	else
		width, height = BASE_WIDTH, BASE_HEIGHT
		forceBtn.Size = UDim2.new(0, 200, 0, 48)
		forceBtn.Position = UDim2.new(0.5, -105, 0, 288)
		acceptBtn.Size = UDim2.new(0, 200, 0, 48)
		acceptBtn.Position = UDim2.new(0.5, 105, 0, 288)
	end

	window.Size = UDim2.new(0, width, 0, height)

	-- Everything inside the window is laid out at absolute offsets, so a short screen
	-- is handled by scaling the whole window instead of reflowing it.
	local scale = math.min(1, (viewport.Y - 24) / height)
	windowScale.Scale = math.max(0.55, scale)
end

applyResponsiveLayout()
vodGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyResponsiveLayout)

local TOTAL_SECONDS = 10
local active = false
local countdownThread = nil

local function closeOverlay()
	active = false
	-- The timeout path calls this from inside countdownThread itself. Cancelling the
	-- running thread killed closeOverlay mid-execution, so the overlay never hid and
	-- the caller never reached its FireServer(false): the prompt stayed frozen on
	-- screen over the death screen and the server only cleared via its own timeout.
	local thread = countdownThread
	countdownThread = nil
	if thread and thread ~= coroutine.running() then
		task.cancel(thread)
	end
	TweenService:Create(overlay, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(window, TweenInfo.new(0.2), { Position = UDim2.new(0.5, 0, 0.52, 0) }):Play()
	task.delay(0.22, function()
		overlay.Visible = false
		window.Position = UDim2.new(0.5, 0, 0.44, 0)
	end)
end

local function openOverlay(data)
	active = true
	-- Re-measure on open: the camera can report a 1x1 viewport during boot, which is
	-- exactly when the layout above first runs.
	applyResponsiveLayout()
	local ce = tonumber(data and data.CE) or 0
	local ct = tostring(data and data.CursedTechnique or "None")

	ceLabel.Text = string.format("<b>CE Available:</b> %d   |   <b>Technique:</b> %s", ce, ct)

	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = COUNTDOWN_FULL
	countdownLabel.Text = string.format("Decision window: %ds", TOTAL_SECONDS)

	overlay.BackgroundTransparency = 1
	window.Position = UDim2.new(0.5, 0, 0.44, 0)
	overlay.Visible = true

	TweenService:Create(overlay, TweenInfo.new(0.25), { BackgroundTransparency = 0.6 }):Play()
	TweenService:Create(window, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0.48, 0) }):Play()

	local startTime = os.clock()
	countdownThread = task.spawn(function()
		while active do
			local elapsed = os.clock() - startTime
			local remaining = math.max(0, TOTAL_SECONDS - elapsed)
			local fraction = remaining / TOTAL_SECONDS
			barFill.Size = UDim2.new(fraction, 0, 1, 0)
			barFill.BackgroundColor3 = fraction > 0.35 and COUNTDOWN_FULL or COUNTDOWN_LOW
			countdownLabel.Text = string.format("Decision window: %ds", math.ceil(remaining))
			if remaining <= 0 then
				-- time ran out: auto-reject and close
				if active then
					closeOverlay()
					vodRCTResponse:FireServer(false)
				end
				break
			end
			task.wait(0.05)
		end
	end)
end

forceBtn.MouseButton1Click:Connect(function()
	if not active then return end
	closeOverlay()
	vodRCTResponse:FireServer(true)
end)

acceptBtn.MouseButton1Click:Connect(function()
	if not active then return end
	closeOverlay()
	vodRCTResponse:FireServer(false)
end)

vodRCTPrompt.OnClientEvent:Connect(function(data)
	openOverlay(data)
end)
