local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local uiState = require("@ui-state/uiState")
local responsiveScale = require("@ui/responsiveScale")
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _wc(key, fallback) return BitKaisenLocale.tOrFallback(_L, "ui." .. key, nil, fallback) end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getChallenges = ReplicatedStorage:FindFirstChild("GetChallenges") or ReplicatedStorage:WaitForChild("GetChallenges", 10)
local challengeCompletedEvent = ReplicatedStorage:FindFirstChild("ChallengeCompleted")

local COLORS = {
	Window   = Color3.fromRGB(16, 16, 22),
	Card     = Color3.fromRGB(24, 24, 32),
	Stroke   = Color3.fromRGB(54, 54, 70),
	Text     = Color3.fromRGB(235, 235, 244),
	SubText  = Color3.fromRGB(166, 166, 186),
	Muted    = Color3.fromRGB(110, 110, 130),
	Gold     = Color3.fromRGB(255, 205, 92),
	Blue     = Color3.fromRGB(116, 190, 255),
	Green    = Color3.fromRGB(122, 236, 165),
	Red      = Color3.fromRGB(220, 84, 90),
	Purple   = Color3.fromRGB(180, 130, 255),
	Orange   = Color3.fromRGB(255, 165, 80),
}

local CATEGORY_COLOR = {
	Life        = COLORS.Green,
	Combat      = COLORS.Red,
	Social      = Color3.fromRGB(255, 120, 190),
	Missions    = COLORS.Gold,
	Influence   = COLORS.Purple,
	Assets      = COLORS.Gold,
	Affiliation = COLORS.Blue,
	Vows        = Color3.fromRGB(220, 180, 255),
}

local function makeCorner(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = obj
end

local function makeStroke(obj, color, thick)
	local s = Instance.new("UIStroke")
	s.Color = color or COLORS.Stroke
	s.Thickness = thick or 1
	s.Parent = obj
end

-- ── GUI root ─────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenWeeklyGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 618
gui.Enabled = false
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "WeeklyOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.35
overlay.BorderSizePixel = 0
overlay.ZIndex = 618
overlay.Parent = gui

local window = Instance.new("Frame")
window.Name = "WeeklyWindow"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.new(0.5, 0, 0.52, 0)
window.Size = UDim2.new(0, 1114, 0, 778)
window.BackgroundColor3 = COLORS.Window
window.BorderSizePixel = 0
window.ZIndex = 619
window.Parent = overlay
makeCorner(window, 10)
makeStroke(window)
responsiveScale.attach(window, 1114, 778)

-- Title — igual que WorldHistoryPanel
local titleLabel = Instance.new("TextLabel")
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.new(0, 24, 0, 18)
titleLabel.Size = UDim2.new(1, -200, 0, 30)
titleLabel.Text = _wc("challenge_title", "WEEKLY CHALLENGES")
titleLabel.TextColor3 = COLORS.Text
titleLabel.TextSize = 22
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 620
titleLabel.Parent = window

-- Timer junto al título, a la derecha del texto
local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.BackgroundTransparency = 1
timerLabel.Text = ""
timerLabel.TextColor3 = COLORS.Gold
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextXAlignment = Enum.TextXAlignment.Left
timerLabel.Position = UDim2.new(0, 24, 0, 46)
timerLabel.Size = UDim2.new(0.6, 0, 0, 16)
timerLabel.TextSize = 12
timerLabel.ZIndex = 620
timerLabel.Parent = window

-- Close button — igual que WorldHistoryPanel
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Position = UDim2.new(1, -58, 0, 16)
closeBtn.Size = UDim2.new(0, 38, 0, 34)
closeBtn.Text = "X"
closeBtn.TextColor3 = COLORS.Red
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 46)
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 621
closeBtn.Parent = window
makeCorner(closeBtn, 8)

-- Scroll container for challenge cards
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "ChallengeScroll"
scroll.Position = UDim2.new(0, 0, 0, 70)
scroll.Size = UDim2.new(1, 0, 1, -70)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = COLORS.Stroke
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ZIndex = 619
scroll.Parent = window

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = scroll

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 14)
padding.PaddingBottom = UDim.new(0, 14)
padding.PaddingLeft = UDim.new(0, 18)
padding.PaddingRight = UDim.new(0, 18)
padding.Parent = scroll

-- ── Loading / Empty states ────────────────────────────────────────────────────
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.BackgroundTransparency = 1
statusLabel.Text = _wc("challenge_loading", "Loading challenges...")
statusLabel.TextColor3 = COLORS.SubText
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = 15
statusLabel.Size = UDim2.new(1, -36, 0, 40)
statusLabel.Position = UDim2.new(0, 18, 0, 90)
statusLabel.ZIndex = 620
statusLabel.Visible = false
statusLabel.Parent = window

-- ── Card builder ──────────────────────────────────────────────────────────────
local function clearCards()
	for _, child in scroll:GetChildren() do
		if child:IsA("Frame") then child:Destroy() end
	end
end

local function applyCompletedOverlay(card)
	-- Dim the card
	card.BackgroundColor3 = Color3.fromRGB(18, 18, 24)

	-- Gray overlay strip
	local overlay = Instance.new("Frame")
	overlay.Name = "CompletedOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.55
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 630
	overlay.Parent = card
	makeCorner(overlay, 8)

	-- "COMPLETADO" badge
	local badge = Instance.new("TextLabel")
	badge.BackgroundTransparency = 1
	badge.Size = UDim2.new(1, 0, 1, 0)
	badge.Text = _wc("challenge_completed", "✓  COMPLETED")
	badge.TextColor3 = Color3.fromRGB(122, 236, 165)
	badge.Font = Enum.Font.GothamBlack
	badge.TextSize = 20
	badge.ZIndex = 631
	badge.Parent = overlay
end

local function buildCard(challenge, order, isCompleted)
	local accent = CATEGORY_COLOR[challenge.Category] or COLORS.Blue

	local card = Instance.new("Frame")
	card.Name = "ChallengeCard_" .. challenge.Id
	card.Size = UDim2.new(1, 0, 0, 100)
	card.BackgroundColor3 = COLORS.Card
	card.BorderSizePixel = 0
	card.LayoutOrder = order
	card.ZIndex = 620
	card.Parent = scroll
	makeCorner(card, 8)
	makeStroke(card, COLORS.Stroke)

	-- Left accent bar
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 3, 1, -16)
	bar.Position = UDim2.new(0, 0, 0, 8)
	bar.BackgroundColor3 = accent
	bar.BorderSizePixel = 0
	bar.ZIndex = 621
	bar.Parent = card
	makeCorner(bar, 2)

	-- Category chip
	local chip = Instance.new("Frame")
	chip.Size = UDim2.new(0, 90, 0, 20)
	chip.Position = UDim2.new(0, 14, 0, 12)
	chip.BackgroundColor3 = Color3.fromRGB(
		math.floor(accent.R * 255 * 0.15),
		math.floor(accent.G * 255 * 0.15),
		math.floor(accent.B * 255 * 0.15)
	)
	chip.BorderSizePixel = 0
	chip.ZIndex = 621
	chip.Parent = card
	makeCorner(chip, 4)

	local chipText = Instance.new("TextLabel")
	chipText.BackgroundTransparency = 1
	chipText.Text = string.upper(challenge.Category)
	chipText.TextColor3 = accent
	chipText.Font = Enum.Font.GothamBold
	chipText.TextSize = 11
	chipText.Size = UDim2.new(1, 0, 1, 0)
	chipText.ZIndex = 622
	chipText.Parent = chip

	-- Title
	local titleTxt = Instance.new("TextLabel")
	titleTxt.BackgroundTransparency = 1
	titleTxt.Text = challenge.Title
	titleTxt.TextColor3 = COLORS.Text
	titleTxt.Font = Enum.Font.GothamBlack
	titleTxt.TextXAlignment = Enum.TextXAlignment.Left
	titleTxt.Position = UDim2.new(0, 14, 0, 35)
	titleTxt.Size = UDim2.new(0.60, 0, 0, 22)
	titleTxt.TextSize = 17
	titleTxt.ZIndex = 621
	titleTxt.Parent = card

	-- Description
	local descTxt = Instance.new("TextLabel")
	descTxt.BackgroundTransparency = 1
	descTxt.Text = challenge.Desc
	descTxt.TextColor3 = COLORS.SubText
	descTxt.Font = Enum.Font.GothamMedium
	descTxt.TextXAlignment = Enum.TextXAlignment.Left
	descTxt.TextWrapped = true
	descTxt.Position = UDim2.new(0, 14, 0, 60)
	descTxt.Size = UDim2.new(0.60, 0, 0, 32)
	descTxt.TextSize = 13
	descTxt.ZIndex = 621
	descTxt.Parent = card

	-- Right side: Goal
	local goalLabel = Instance.new("TextLabel")
	goalLabel.BackgroundTransparency = 1
	goalLabel.Text = _wc("challenge_goal_label", "GOAL")
	goalLabel.TextColor3 = COLORS.Muted
	goalLabel.Font = Enum.Font.GothamBold
	goalLabel.TextXAlignment = Enum.TextXAlignment.Right
	goalLabel.Position = UDim2.new(0.60, 0, 0, 12)
	goalLabel.Size = UDim2.new(0.40, -16, 0, 14)
	goalLabel.TextSize = 11
	goalLabel.ZIndex = 621
	goalLabel.Parent = card

	local goalValue = Instance.new("TextLabel")
	goalValue.BackgroundTransparency = 1
	goalValue.Text = challenge.Goal
	goalValue.TextColor3 = COLORS.Text
	goalValue.Font = Enum.Font.GothamBold
	goalValue.TextXAlignment = Enum.TextXAlignment.Right
	goalValue.Position = UDim2.new(0.60, 0, 0, 28)
	goalValue.Size = UDim2.new(0.40, -16, 0, 22)
	goalValue.TextSize = 16
	goalValue.ZIndex = 621
	goalValue.Parent = card

	-- Right side: Reward
	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Text = _wc("challenge_reward_label", "REWARD")
	rewardLabel.TextColor3 = COLORS.Muted
	rewardLabel.Font = Enum.Font.GothamBold
	rewardLabel.TextXAlignment = Enum.TextXAlignment.Right
	rewardLabel.Position = UDim2.new(0.60, 0, 0, 56)
	rewardLabel.Size = UDim2.new(0.40, -16, 0, 14)
	rewardLabel.TextSize = 11
	rewardLabel.ZIndex = 621
	rewardLabel.Parent = card

	local rewardValue = Instance.new("TextLabel")
	rewardValue.BackgroundTransparency = 1
	rewardValue.Text = challenge.Reward
	rewardValue.TextColor3 = COLORS.Gold
	rewardValue.Font = Enum.Font.GothamBold
	rewardValue.TextXAlignment = Enum.TextXAlignment.Right
	rewardValue.Position = UDim2.new(0.60, 0, 0, 72)
	rewardValue.Size = UDim2.new(0.40, -16, 0, 20)
	rewardValue.TextSize = 15
	rewardValue.ZIndex = 621
	rewardValue.Parent = card

	if isCompleted then
		applyCompletedOverlay(card)
	end

	return card
end

-- ── Timer display ─────────────────────────────────────────────────────────────
local resetsInSeconds = 0
local timerConn = nil

local function formatTime(secs)
	secs = math.max(0, math.floor(secs))
	local d = math.floor(secs / 86400)
	local h = math.floor((secs % 86400) / 3600)
	local m = math.floor((secs % 3600) / 60)
	if d > 0 then
		return _wc("resets_days", "Resets in {d}d {h}h"):gsub("{d}", tostring(d)):gsub("{h}", tostring(h))
	elseif h > 0 then
		return _wc("resets_hours", "Resets in {h}h {m}m"):gsub("{h}", tostring(h)):gsub("{m}", tostring(m))
	else
		return _wc("resets_mins", "Resets in {m}m"):gsub("{m}", tostring(m))
	end
end

local function startTimer()
	if timerConn then timerConn:Disconnect() timerConn = nil end
	local startClock = os.clock()
	timerConn = RunService.Heartbeat:Connect(function()
		local elapsed = os.clock() - startClock
		local remaining = resetsInSeconds - elapsed
		timerLabel.Text = formatTime(remaining)
	end)
end

-- ── Load data ─────────────────────────────────────────────────────────────────
local loaded = false

local function loadChallenges()
	if loaded then return end
	loaded = true
	statusLabel.Visible = true
	statusLabel.Text = _wc("challenge_loading", "Loading challenges...")
	clearCards()

	task.spawn(function()
		local ok, result = pcall(function()
			return getChallenges:InvokeServer()
		end)
		if not ok or not result or not result.Challenges then
			statusLabel.Text = _wc("challenge_error", "Could not load challenges.\nTry again later.")
			return
		end
		statusLabel.Visible = false
		resetsInSeconds = result.ResetsIn or 0
		startTimer()

		local completedIds = result.CompletedIds or {}
		for i, ch in ipairs(result.Challenges) do
			buildCard(ch, i, completedIds[ch.Id] == true)
		end

		if #result.Challenges == 0 then
			statusLabel.Visible = true
			statusLabel.Text = _wc("challenge_none", "No challenges this week.")
		end
	end)
end

-- ── Open / Close ──────────────────────────────────────────────────────────────
local function openPanel()
	gui.Enabled = true
	loadChallenges()
end

local function closePanel()
	gui.Enabled = false
	if timerConn then timerConn:Disconnect() timerConn = nil end
	loaded = false
end

overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if not window:IsDescendantOf(game) then return end
		local mp = UserInputService:GetMouseLocation()
		local wp = window.AbsolutePosition
		local ws = window.AbsoluteSize
		if mp.X < wp.X or mp.X > wp.X + ws.X or mp.Y < wp.Y or mp.Y > wp.Y + ws.Y then
			uiState.closeRoute()
		end
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	uiState.closeRoute()
end)

-- ── Nav integration ───────────────────────────────────────────────────────────
local WeeklyChallengesPanel = {}

function WeeklyChallengesPanel.init()
	uiState.subscribe(function(route)
		if route == "weekly" then
			openPanel()
		else
			closePanel()
		end
	end)

	-- Mark a card as completed in real-time when the server fires the event
	if challengeCompletedEvent then
		challengeCompletedEvent.OnClientEvent:Connect(function(challengeId)
			local cardName = "ChallengeCard_" .. tostring(challengeId)
			local card = scroll:FindFirstChild(cardName)
			if card and not card:FindFirstChild("CompletedOverlay") then
				applyCompletedOverlay(card)
			end
		end)
	end
end

return WeeklyChallengesPanel
