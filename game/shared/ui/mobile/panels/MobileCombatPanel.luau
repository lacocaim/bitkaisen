local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local mobileComponents = require(script.Parent.Parent.mobileComponents)
local overlayManager = require(script.Parent.Parent.Parent.state.overlayManager)
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _cb(key, fallback) return BitKaisenLocale.tOrFallback(_L, "combat." .. key, nil, fallback) end
local uiState = require(script.Parent.Parent.Parent.state.uiState)
local theme = mobileComponents.theme
local corner = mobileComponents.corner
local stroke = mobileComponents.stroke
local bindTap = mobileComponents.bindTap
local mobileButton = mobileComponents.mobileButton
local mobileCard = mobileComponents.mobileCard
local mobileLabel = mobileComponents.mobileLabel

local TEST_PURCHASE_PLACE_ID = 104206065947170

local combatSounds = {
	Hit = { "Hit1", "Hit2" },
	Dodge = { "Dodge1", "Dodge2" },
	Critical = "CriticalHit",
}

local function resolveCombatSound(soundOrPool)
	local soundName = soundOrPool
	if typeof(soundOrPool) == "table" then
		soundName = soundOrPool[math.random(1, #soundOrPool)]
	end
	if typeof(soundName) == "string" then
		return SoundService:FindFirstChild(soundName)
	end
	if typeof(soundName) == "Instance" and soundName:IsA("Sound") then
		return soundName
	end
	return nil
end

local function playCombatSound(soundOrPool)
	local source = resolveCombatSound(soundOrPool)
	if not source or not source:IsA("Sound") or source.SoundId == "" then return end
	local sound = source:Clone()
	sound.Name = "CombatOneShot_" .. source.Name
	sound.Parent = SoundService
	sound.TimePosition = 0
	sound:Play()
	Debris:AddItem(sound, math.max(1.25, (tonumber(sound.TimeLength) or 0) + 0.5))
end

local lastHitSoundAt = 0

local function playHitSound()
	lastHitSoundAt = os.clock()
	playCombatSound(combatSounds.Hit)
end

local function playConfirmedHitSound()
	if os.clock() - lastHitSoundAt < 0.2 then return end
	playHitSound()
end

local function pulseFeedback(parent, color)
	if not parent or not parent.Parent then return end
	local pulse = Instance.new("Frame")
	pulse.Name = "CombatFeedbackPulse"
	pulse.Size = UDim2.new(1, 0, 1, 0)
	pulse.BackgroundColor3 = color
	pulse.BackgroundTransparency = 0.68
	pulse.BorderSizePixel = 0
	pulse.ZIndex = 1990
	pulse.Parent = parent
	TweenService:Create(pulse, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
	task.delay(0.38, function()
		if pulse then pulse:Destroy() end
	end)
end

local function shakeGui(guiObject)
	if not guiObject or not guiObject.Parent then return end
	local originalPosition = guiObject.Position
	local offsets = { -6, 6, -4, 4, 0 }
	for index, offset in ipairs(offsets) do
		task.delay((index - 1) * 0.035, function()
			if guiObject and guiObject.Parent then
				guiObject.Position = originalPosition + UDim2.new(0, offset, 0, 0)
			end
		end)
	end
	task.delay(#offsets * 0.035 + 0.02, function()
		if guiObject and guiObject.Parent then
			guiObject.Position = originalPosition
		end
	end)
end

local function setButtonEnabled(button: TextButton, enabled: boolean)
	button.Active = enabled
	button.AutoButtonColor = enabled
	button.TextTransparency = enabled and 0 or 0.5
	button.BackgroundTransparency = enabled and 0 or 0.4
end

local function init(playerGui: Instance)
	local getCombatState = ReplicatedStorage:WaitForChild("GetCombatState", 20)
	local combatAction = ReplicatedStorage:WaitForChild("CombatAction", 20)
	local combatStateUpdate = ReplicatedStorage:WaitForChild("CombatStateUpdate", 20)
	local combatMinigameResult = ReplicatedStorage:WaitForChild("CombatMinigameResult", 20)

	local existing = playerGui:FindFirstChild("BitKaisenMobileCombatGui")
	if existing then existing:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "BitKaisenMobileCombatGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.Enabled = false
	gui.DisplayOrder = 730
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local state = { Active = false }
	local activeMinigame = nil
	local promptedLossReset = false
	local lastAttackToken = nil
	local lastDefenseToken = nil
	local lastCounterToken = nil
	local lastResultSignature = nil

	-- Full-screen overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "CombatOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = theme.Bg
	overlay.BackgroundTransparency = 0
	overlay.Visible = false
	overlay.ZIndex = 700
	overlay.Parent = gui

	-- Scrollable content
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "CombatScroll"
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.Position = UDim2.new(0, 0, 0, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = theme.Purple
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ZIndex = 701
	scroll.Parent = overlay

	local scrollLayout = Instance.new("UIListLayout")
	scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
	scrollLayout.Padding = UDim.new(0, 10)
	scrollLayout.Parent = scroll

	local scrollPad = Instance.new("UIPadding")
	scrollPad.PaddingTop = UDim.new(0, 12)
	scrollPad.PaddingBottom = UDim.new(0, 24)
	scrollPad.PaddingLeft = UDim.new(0, 12)
	scrollPad.PaddingRight = UDim.new(0, 12)
	scrollPad.Parent = scroll

	-- Header
	local headerFrame = Instance.new("Frame")
	headerFrame.Name = "Header"
	headerFrame.Size = UDim2.new(1, 0, 0, 40)
	headerFrame.BackgroundTransparency = 1
	headerFrame.LayoutOrder = 1
	headerFrame.Parent = scroll

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -50, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = _cb("title", "COMBAT")
	titleLabel.TextColor3 = theme.Gold
	titleLabel.TextSize = 20
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = headerFrame

	-- Enemy card
	local enemyCard = mobileCard({
		parent = scroll,
		color = Color3.fromRGB(22, 18, 24),
		accentColor = Color3.fromRGB(107, 55, 66),
		order = 2,
	})

	local enemyNameLabel = mobileLabel({
		parent = enemyCard,
		text = _cb("enemy_label", "Enemy"),
		size = 17,
		font = Enum.Font.GothamBlack,
		color = theme.Text,
		order = 1,
	})

	local enemyInfo = mobileLabel({
		parent = enemyCard,
		text = _cb("enemy_label", "Enemy"),
		size = 13,
		color = theme.SubText,
		order = 2,
	})

	local enemyBarContainer = Instance.new("Frame")
	enemyBarContainer.Size = UDim2.new(1, 0, 0, 18)
	enemyBarContainer.BackgroundColor3 = Color3.fromRGB(43, 36, 43)
	enemyBarContainer.BorderSizePixel = 0
	enemyBarContainer.LayoutOrder = 3
	enemyBarContainer.Parent = enemyCard
	corner(enemyBarContainer, 9)

	local enemyBar = Instance.new("Frame")
	enemyBar.Size = UDim2.new(1, 0, 1, 0)
	enemyBar.BackgroundColor3 = theme.Bad
	enemyBar.BorderSizePixel = 0
	enemyBar.Parent = enemyBarContainer
	corner(enemyBar, 9)

	-- Player card
	local playerCard = mobileCard({
		parent = scroll,
		color = Color3.fromRGB(18, 22, 28),
		accentColor = Color3.fromRGB(65, 87, 116),
		order = 3,
	})

	local hpRow = Instance.new("Frame")
	hpRow.Size = UDim2.new(1, 0, 0, 20)
	hpRow.BackgroundTransparency = 1
	hpRow.LayoutOrder = 1
	hpRow.Parent = playerCard

	local hpLabel = Instance.new("TextLabel")
	hpLabel.Size = UDim2.new(0, 80, 1, 0)
	hpLabel.BackgroundTransparency = 1
	hpLabel.Text = _cb("bar_hp", "HP")
	hpLabel.TextColor3 = theme.Green
	hpLabel.TextSize = 14
	hpLabel.Font = Enum.Font.GothamBold
	hpLabel.TextXAlignment = Enum.TextXAlignment.Left
	hpLabel.Parent = hpRow

	local hpBarBg = Instance.new("Frame")
	hpBarBg.Position = UDim2.new(0, 82, 0, 2)
	hpBarBg.Size = UDim2.new(1, -82, 0, 16)
	hpBarBg.BackgroundColor3 = Color3.fromRGB(35, 42, 38)
	hpBarBg.BorderSizePixel = 0
	hpBarBg.Parent = hpRow
	corner(hpBarBg, 8)

	local hpBar = Instance.new("Frame")
	hpBar.Size = UDim2.new(1, 0, 1, 0)
	hpBar.BackgroundColor3 = theme.Green
	hpBar.BorderSizePixel = 0
	hpBar.Parent = hpBarBg
	corner(hpBar, 8)

	local ceRow = Instance.new("Frame")
	ceRow.Size = UDim2.new(1, 0, 0, 20)
	ceRow.BackgroundTransparency = 1
	ceRow.LayoutOrder = 2
	ceRow.Parent = playerCard

	local ceLabel = Instance.new("TextLabel")
	ceLabel.Size = UDim2.new(0, 80, 1, 0)
	ceLabel.BackgroundTransparency = 1
	ceLabel.Text = _cb("bar_ce", "CE")
	ceLabel.TextColor3 = theme.Blue
	ceLabel.TextSize = 14
	ceLabel.Font = Enum.Font.GothamBold
	ceLabel.TextXAlignment = Enum.TextXAlignment.Left
	ceLabel.Parent = ceRow

	local ceBarBg = Instance.new("Frame")
	ceBarBg.Position = UDim2.new(0, 82, 0, 2)
	ceBarBg.Size = UDim2.new(1, -82, 0, 16)
	ceBarBg.BackgroundColor3 = Color3.fromRGB(31, 37, 48)
	ceBarBg.BorderSizePixel = 0
	ceBarBg.Parent = ceRow
	corner(ceBarBg, 8)

	local ceBar = Instance.new("Frame")
	ceBar.Size = UDim2.new(1, 0, 1, 0)
	ceBar.BackgroundColor3 = theme.Blue
	ceBar.BorderSizePixel = 0
	ceBar.Parent = ceBarBg
	corner(ceBar, 8)

	-- Action buttons (2-column grid for touch)
	local actionCard = Instance.new("Frame")
	actionCard.Name = "ActionButtons"
	actionCard.Size = UDim2.new(1, 0, 0, 0)
	actionCard.AutomaticSize = Enum.AutomaticSize.Y
	actionCard.BackgroundTransparency = 1
	actionCard.LayoutOrder = 4
	actionCard.Parent = scroll

	local actionGrid = Instance.new("UIGridLayout")
	actionGrid.CellSize = UDim2.new(0.48, 0, 0, 54)
	actionGrid.CellPadding = UDim2.new(0.04, 0, 0, 10)
	actionGrid.SortOrder = Enum.SortOrder.LayoutOrder
	actionGrid.Parent = actionCard

	local function makeActionButton(text, color, order)
		local btn = Instance.new("TextButton")
		btn.BackgroundColor3 = color
		btn.BorderSizePixel = 0
		btn.Text = text
		btn.TextColor3 = theme.Text
		btn.TextSize = 16
		btn.Font = Enum.Font.GothamBlack
		btn.LayoutOrder = order
		btn.Parent = actionCard
		corner(btn, 10)
		return btn
	end

	local attackButton = makeActionButton(_cb("btn_attack", "ATTACK"), Color3.fromRGB(119, 43, 53), 1)
	local techniqueButton = makeActionButton(_cb("btn_technique", "TECHNIQUE"), Color3.fromRGB(73, 52, 126), 2)
	local domainButton = makeActionButton(_cb("btn_domain", "DOMAIN"), Color3.fromRGB(91, 58, 145), 3)
	local defendButton = makeActionButton(_cb("btn_defend", "DEFEND"), Color3.fromRGB(48, 91, 112), 4)
	local fleeButton = makeActionButton(_cb("btn_flee", "FLEE"), Color3.fromRGB(64, 64, 75), 5)
	local resetButton = makeActionButton(_cb("btn_reset", "RESET"), Color3.fromRGB(90, 61, 31), 6)
	resetButton.Visible = false
	local blackFlashButton = makeActionButton(_cb("btn_bflash", "B.FLASH"), Color3.fromRGB(48, 28, 90), 7)
	blackFlashButton.Visible = false

	-- Combat log
	local logCard = Instance.new("Frame")
	logCard.Name = "CombatLogCard"
	logCard.Size = UDim2.new(1, 0, 0, 180)
	logCard.BackgroundColor3 = Color3.fromRGB(11, 11, 17)
	logCard.BorderSizePixel = 0
	logCard.LayoutOrder = 5
	logCard.Parent = scroll
	corner(logCard, 10)
	stroke(logCard, Color3.fromRGB(42, 38, 54))

	local logScroll = Instance.new("ScrollingFrame")
	logScroll.Size = UDim2.new(1, -16, 1, -16)
	logScroll.Position = UDim2.new(0, 8, 0, 8)
	logScroll.BackgroundTransparency = 1
	logScroll.BorderSizePixel = 0
	logScroll.ScrollBarThickness = 3
	logScroll.ScrollBarImageColor3 = theme.Purple
	logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	logScroll.Parent = logCard

	local logLayout = Instance.new("UIListLayout")
	logLayout.Padding = UDim.new(0, 5)
	logLayout.SortOrder = Enum.SortOrder.LayoutOrder
	logLayout.Parent = logScroll

	local logPad = Instance.new("UIPadding")
	logPad.PaddingTop = UDim.new(0, 4)
	logPad.PaddingBottom = UDim.new(0, 4)
	logPad.PaddingLeft = UDim.new(0, 4)
	logPad.PaddingRight = UDim.new(0, 4)
	logPad.Parent = logScroll

	-- Floating popup text
	local function popCombatText(text, color, anchorPosition, big)
		local popup = Instance.new("TextLabel")
		popup.Name = "CombatPopText"
		popup.AnchorPoint = Vector2.new(0.5, 0.5)
		popup.Position = anchorPosition + UDim2.new(0, math.random(-24, 24), 0, math.random(-10, 10))
		popup.Size = UDim2.new(0, big and 180 or 140, 0, big and 44 or 36)
		popup.BackgroundTransparency = 1
		popup.Text = tostring(text)
		popup.TextColor3 = color
		popup.TextStrokeColor3 = Color3.new(0, 0, 0)
		popup.TextStrokeTransparency = 0.18
		popup.TextTransparency = 0
		popup.Font = Enum.Font.GothamBlack
		popup.TextSize = big and 26 or 20
		popup.ZIndex = 2100
		popup.Parent = gui
		local driftX = math.random(-18, 18)
		local driftY = math.random(-56, -36)
		TweenService:Create(popup, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, big and 200 or 156, 0, big and 52 or 42),
		}):Play()
		task.delay(0.15, function()
			if popup and popup.Parent then
				TweenService:Create(popup, TweenInfo.new(0.62, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = popup.Position + UDim2.new(0, driftX, 0, driftY),
					TextTransparency = 1,
					TextStrokeTransparency = 1,
				}):Play()
			end
		end)
		task.delay(0.85, function()
			if popup then popup:Destroy() end
		end)
	end

	local function popEnemyText(text, color, big)
		popCombatText(text, color, UDim2.new(0.5, 0, 0.22, 0), big)
	end

	local function popPlayerText(text, color, big)
		popCombatText(text, color, UDim2.new(0.5, 0, 0.52, 0), big)
	end

	local function clearLog()
		for _, child in ipairs(logScroll:GetChildren()) do
			if child:IsA("TextLabel") then child:Destroy() end
		end
	end

	local function refreshLog(log)
		clearLog()
		for index, text in ipairs(log or {}) do
			local row = Instance.new("TextLabel")
			row.Size = UDim2.new(1, 0, 0, 0)
			row.AutomaticSize = Enum.AutomaticSize.Y
			row.BackgroundTransparency = 1
			row.Text = tostring(text)
			row.TextColor3 = index == 1 and theme.Text or theme.SubText
			row.TextSize = 14
			row.Font = Enum.Font.GothamMedium
			row.TextWrapped = true
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.LayoutOrder = index
			row.Parent = logScroll
		end
	end

	local function updateBars()
		local enemyRatio = 0
		if (tonumber(state.EnemyMaxHP) or 0) > 0 then
			enemyRatio = math.clamp((tonumber(state.EnemyHP) or 0) / tonumber(state.EnemyMaxHP), 0, 1)
		end
		TweenService:Create(enemyBar, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(enemyRatio, 0, 1, 0),
		}):Play()

		local hpRatio = math.clamp((tonumber(state.PlayerHP) or 0) / math.max(1, tonumber(state.PlayerMaxHP) or 100), 0, 1)
		TweenService:Create(hpBar, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(hpRatio, 0, 1, 0),
		}):Play()

		local ceRatio = math.clamp((tonumber(state.PlayerCE) or 0) / math.max(1, tonumber(state.PlayerMaxCE) or 100), 0, 1)
		TweenService:Create(ceBar, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(ceRatio, 0, 1, 0),
		}):Play()

		hpLabel.Text = _cb("bar_hp", "HP") .. " " .. tostring(math.floor(tonumber(state.PlayerHP) or 0))
		ceLabel.Text = _cb("bar_ce", "CE") .. " " .. tostring(math.floor(tonumber(state.PlayerCE) or 0))
	end

	local function destroyMinigame()
		if activeMinigame then
			if activeMinigame.Connection then activeMinigame.Connection:Disconnect() end
			if activeMinigame.Root then activeMinigame.Root:Destroy() end
		end
		activeMinigame = nil
	end

	-- Attack timing minigame (mobile-optimized)
	local function openAttackMinigame(payload)
		destroyMinigame()

		local root = Instance.new("Frame")
		root.Name = "MobileCombatAttackMinigame"
		root.Size = UDim2.new(1, 0, 1, 0)
		root.BackgroundColor3 = Color3.new(0, 0, 0)
		root.BackgroundTransparency = 0.3
		root.ZIndex = 760
		root.Parent = gui

		local panel = Instance.new("Frame")
		panel.AnchorPoint = Vector2.new(0.5, 0.5)
		panel.Position = UDim2.new(0.5, 0, 0.45, 0)
		panel.Size = UDim2.new(0.85, 0, 0, 380)
		panel.BackgroundColor3 = Color3.fromRGB(13, 13, 20)
		panel.BorderSizePixel = 0
		panel.ZIndex = 761
		panel.Parent = root
		corner(panel, 14)
		stroke(panel, theme.Gold)

		local caption = Instance.new("TextLabel")
		caption.Size = UDim2.new(1, -24, 0, 32)
		caption.Position = UDim2.new(0, 12, 0, 14)
		caption.BackgroundTransparency = 1
		caption.Text = payload.IsBlackFlash and _cb("minigame_bflash", "BLACK FLASH") or (payload.IsTechnique and _cb("minigame_tech", "TECHNIQUE TIMING") or _cb("minigame_attack", "ATTACK TIMING"))
		caption.TextColor3 = payload.IsBlackFlash and theme.Purple or theme.Gold
		caption.TextSize = 17
		caption.Font = Enum.Font.GothamBlack
		caption.TextXAlignment = Enum.TextXAlignment.Center
		caption.ZIndex = 762
		caption.Parent = panel

		local board = Instance.new("Frame")
		board.AnchorPoint = Vector2.new(0.5, 0.5)
		board.Position = UDim2.new(0.5, 0, 0, 196)
		board.Size = UDim2.new(0, 220, 0, 220)
		board.BackgroundTransparency = 1
		board.ZIndex = 762
		board.Parent = panel

		local barThickness = 20
		local specs = {
			{ UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, barThickness) },
			{ UDim2.new(1, -barThickness, 0, 0), UDim2.new(0, barThickness, 1, 0) },
			{ UDim2.new(0, 0, 1, -barThickness), UDim2.new(1, 0, 0, barThickness) },
			{ UDim2.new(0, 0, 0, 0), UDim2.new(0, barThickness, 1, 0) },
		}
		for i = 1, 4 do
			local seg = Instance.new("Frame")
			seg.Position = specs[i][1]
			seg.Size = specs[i][2]
			seg.BorderSizePixel = 0
			seg.BackgroundColor3 = i == payload.TargetSide and theme.Bad or Color3.fromRGB(54, 50, 58)
			seg.ZIndex = 763
			seg.Parent = board
			corner(seg, 5)
		end

		local sweet = Instance.new("Frame")
		sweet.BorderSizePixel = 0
		sweet.BackgroundColor3 = payload.IsBlackFlash and theme.Purple or theme.Gold
		sweet.ZIndex = 764
		sweet.Parent = board
		corner(sweet, 5)
		local side = tonumber(payload.TargetSide) or 1
		if side == 1 then
			sweet.Size = UDim2.new(0, 40, 0, barThickness)
			sweet.Position = UDim2.new(0.5, -20, 0, 0)
		elseif side == 2 then
			sweet.Size = UDim2.new(0, barThickness, 0, 40)
			sweet.Position = UDim2.new(1, -barThickness, 0.5, -20)
		elseif side == 3 then
			sweet.Size = UDim2.new(0, 40, 0, barThickness)
			sweet.Position = UDim2.new(0.5, -20, 1, -barThickness)
		else
			sweet.Size = UDim2.new(0, barThickness, 0, 40)
			sweet.Position = UDim2.new(0, 0, 0.5, -20)
		end

		local pointer = Instance.new("Frame")
		pointer.Size = UDim2.new(0, 28, 0, 28)
		pointer.AnchorPoint = Vector2.new(0.5, 0.5)
		pointer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		pointer.BorderSizePixel = 0
		pointer.ZIndex = 765
		pointer.Parent = board
		corner(pointer, 14)
		stroke(pointer, theme.Purple, 2)

		local stop = Instance.new("TextButton")
		stop.AnchorPoint = Vector2.new(0.5, 0)
		stop.Position = UDim2.new(0.5, 0, 0, 320)
		stop.Size = UDim2.new(0.7, 0, 0, 52)
		stop.BackgroundColor3 = theme.Purple
		stop.Text = _cb("btn_hit", "HIT!")
		stop.TextColor3 = theme.Text
		stop.TextSize = 18
		stop.Font = Enum.Font.GothamBlack
		stop.ZIndex = 766
		stop.Parent = panel
		corner(stop, 12)

		local startedAt = os.clock()
		local duration = tonumber(payload.Duration) or 1.35
		local submitted = false

		local function positionPointer(progress)
			progress = progress % 1
			local sideProgress = (progress * 4) % 1
			local currentSide = math.floor(progress * 4) + 1
			local x, y
			if currentSide == 1 then
				x = sideProgress; y = 0
			elseif currentSide == 2 then
				x = 1; y = sideProgress
			elseif currentSide == 3 then
				x = 1 - sideProgress; y = 1
			else
				x = 0; y = 1 - sideProgress
			end
			pointer.Position = UDim2.new(x, 0, y, 0)
		end

		local function submit(cancelled)
			if submitted then return end
			submitted = true
			local progress = ((os.clock() - startedAt) / duration) % 1
			local target = tonumber(payload.Target) or 0.5
			local distance = math.abs(progress - target)
			distance = math.min(distance, 1 - distance)
			local targetWidth = tonumber(payload.TargetWidth) or 0.14
			local sweetWidth = tonumber(payload.SweetWidth) or 0.04
			positionPointer(progress)
			if activeMinigame and activeMinigame.Connection then
				activeMinigame.Connection:Disconnect()
				activeMinigame.Connection = nil
			end
			stop.Active = false
			stop.AutoButtonColor = false
			local accuracy = cancelled and 0 or math.clamp(1 - (distance / math.max(targetWidth, 0.01)), 0, 1)
			local isSweet = distance <= sweetWidth
			local success = isSweet or accuracy >= 0.7
			if isSweet then
				playCombatSound(combatSounds.Critical)
				popEnemyText(_cb("pop_critical", "CRITICAL"), theme.Gold, true)
			elseif success then
				playHitSound()
				popEnemyText(_cb("pop_hit", "HIT"), theme.Green, false)
			else
				popEnemyText(_cb("pop_miss", "MISS"), theme.Bad, false)
			end
			pulseFeedback(root, success and theme.Green or theme.Bad)
			shakeGui(panel)
			combatMinigameResult:FireServer(payload.Token, "attack", accuracy, { Sweet = isSweet })
			task.delay(0.22, function()
				if activeMinigame and activeMinigame.Root == root then
					destroyMinigame()
				end
			end)
		end

		bindTap(stop, function() submit(false) end)
		root.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then submit(false) end
		end)

		activeMinigame = {
			Root = root,
			Connection = RunService.RenderStepped:Connect(function()
				positionPointer((os.clock() - startedAt) / duration)
			end),
		}
		task.delay(duration * 1.2, function()
			if activeMinigame and activeMinigame.Root == root then submit(true) end
		end)
	end

	-- Defense QTE (mobile-optimized with large dodge buttons)
	local function openDefenseQTE(payload)
		destroyMinigame()

		local root = Instance.new("Frame")
		root.Name = "MobileCombatDefenseQTE"
		root.Size = UDim2.new(1, 0, 1, 0)
		root.BackgroundColor3 = Color3.new(0, 0, 0)
		root.BackgroundTransparency = 0.25
		root.ZIndex = 770
		root.Parent = gui

		local warning = Instance.new("TextLabel")
		warning.AnchorPoint = Vector2.new(0.5, 0)
		warning.Position = UDim2.new(0.5, 0, 0.14, 0)
		warning.Size = UDim2.new(0.9, 0, 0, 56)
		warning.BackgroundTransparency = 1
		warning.Text = tostring(payload.Warning or _cb("dodge_warning", "Incoming attack! Tap to dodge!"))
		warning.TextColor3 = theme.Gold
		warning.TextSize = 18
		warning.Font = Enum.Font.GothamBlack
		warning.TextWrapped = true
		warning.TextXAlignment = Enum.TextXAlignment.Center
		warning.ZIndex = 771
		warning.Parent = root

		local hits = math.clamp(tonumber(payload.Hits) or 1, 1, 3)
		local windowSeconds = tonumber(payload.Window) or 0.8
		local currentHit = 0
		local goodHits = 0
		local perfectHits = 0
		local button
		local startedAt = 0
		local finished = false
		local activeHitId = 0

		local function finish()
			if finished then return end
			finished = true
			activeHitId += 1
			local accuracy = goodHits / hits
			combatMinigameResult:FireServer(payload.Token, "defense", accuracy, { PerfectHits = perfectHits })
			task.delay(0.12, function()
				if activeMinigame and activeMinigame.Root == root then
					destroyMinigame()
				end
			end)
		end

		local function nextHit()
			if finished then return end
			currentHit += 1
			if currentHit > hits then
				finish()
				return
			end
			activeHitId += 1
			local hitId = activeHitId
			if button then button:Destroy() end

			button = Instance.new("TextButton")
			button.AnchorPoint = Vector2.new(0.5, 0.5)
			button.Position = UDim2.new(0.5, math.random(-60, 60), 0.52, math.random(-40, 40))
			button.Size = UDim2.new(0, 120, 0, 120)
			button.BackgroundColor3 = theme.Blue
			button.Text = _cb("btn_dodge", "DODGE")
			button.TextColor3 = theme.Text
			button.TextSize = 18
			button.Font = Enum.Font.GothamBlack
			button.ZIndex = 772
			button.Parent = root
			corner(button, 60)
			stroke(button, Color3.fromRGB(255, 255, 255), 2)

			startedAt = os.clock()
			bindTap(button, function()
				if finished or hitId ~= activeHitId then return end
				local elapsed = os.clock() - startedAt
				local success = elapsed <= windowSeconds
				if success then
					goodHits += 1
					playCombatSound(combatSounds.Dodge)
					popPlayerText(_cb("pop_dodge", "DODGE"), theme.Green, false)
					if elapsed <= windowSeconds * 0.38 then
						perfectHits += 1
					end
				else
					popPlayerText(_cb("pop_miss", "MISS"), theme.Bad, false)
				end
				pulseFeedback(root, success and theme.Green or theme.Bad)
				shakeGui(button)
				activeHitId += 1
				task.delay(0.08, nextHit)
			end)
			task.delay(windowSeconds, function()
				if not finished and hitId == activeHitId and button and button.Parent then
					popPlayerText(_cb("pop_miss", "MISS"), theme.Bad, false)
					pulseFeedback(root, theme.Bad)
					activeHitId += 1
					task.delay(0.08, nextHit)
				end
			end)
		end

		task.delay(0.8, nextHit)
		activeMinigame = { Root = root }
	end

	-- Counter QTE (mobile-optimized with big tap target)
	local function openCounterQTE(payload)
		destroyMinigame()

		local root = Instance.new("Frame")
		root.Name = "MobileCombatCounterQTE"
		root.Size = UDim2.new(1, 0, 1, 0)
		root.BackgroundTransparency = 0.3
		root.BackgroundColor3 = Color3.new(0, 0, 0)
		root.ZIndex = 780
		root.Parent = gui

		local button = Instance.new("TextButton")
		button.AnchorPoint = Vector2.new(0.5, 0.5)
		button.Position = UDim2.new(0.5, 0, 0.5, 0)
		button.Size = UDim2.new(0, 180, 0, 90)
		button.BackgroundColor3 = theme.Bad
		button.Text = _cb("btn_counter", "COUNTER!")
		button.TextColor3 = theme.Text
		button.TextSize = 22
		button.Font = Enum.Font.GothamBlack
		button.ZIndex = 781
		button.Parent = root
		corner(button, 14)
		stroke(button, theme.Gold, 2)

		local counterScale = Instance.new("UIScale")
		counterScale.Scale = 1
		counterScale.Parent = button

		local pulseAlive = true
		local function heartbeatPulse()
			if not pulseAlive or not button.Parent then return end
			TweenService:Create(counterScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.12 }):Play()
			task.delay(0.12, function()
				if not pulseAlive or not button.Parent then return end
				TweenService:Create(counterScale, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.98 }):Play()
			end)
			task.delay(0.26, function()
				if not pulseAlive or not button.Parent then return end
				TweenService:Create(counterScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.08 }):Play()
			end)
			task.delay(0.38, function()
				if not pulseAlive or not button.Parent then return end
				TweenService:Create(counterScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 1 }):Play()
			end)
			task.delay(0.72, heartbeatPulse)
		end
		heartbeatPulse()

		local clicked = false
		bindTap(button, function()
			if clicked then return end
			clicked = true
			pulseAlive = false
			playHitSound()
			popEnemyText(_cb("pop_counter", "COUNTER"), theme.Green, false)
			pulseFeedback(root, theme.Green)
			shakeGui(button)
			combatMinigameResult:FireServer(payload.Token, "counter", 1, {})
			task.delay(0.2, destroyMinigame)
		end)

		task.delay(tonumber(payload.Window) or 1.3, function()
			if activeMinigame and activeMinigame.Root == root then
				pulseAlive = false
				popPlayerText(_cb("pop_miss", "MISS"), theme.Bad, false)
				pulseFeedback(root, theme.Bad)
				combatMinigameResult:FireServer(payload.Token, "counter", 0, {})
				task.delay(0.2, destroyMinigame)
			end
		end)

		activeMinigame = { Root = root }
	end

	-- Result popup
	local function showCombatResultPopup(winner, enemyDisplayName)
		local old = gui:FindFirstChild("MobileCombatResultPopup")
		if old then old:Destroy() end

		local popup = Instance.new("Frame")
		popup.Name = "MobileCombatResultPopup"
		popup.AnchorPoint = Vector2.new(0.5, 0.5)
		popup.Position = UDim2.new(0.5, 0, 0.4, 0)
		popup.Size = UDim2.new(0.8, 0, 0, 120)
		popup.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
		popup.BackgroundTransparency = 0.06
		popup.BorderSizePixel = 0
		popup.ZIndex = 2300
		popup.Parent = gui
		corner(popup, 14)
		stroke(popup, winner == "player" and theme.Gold or winner == "enemy" and theme.Bad or theme.Green, 2)

		local resultTitle = winner == "player" and _cb("result_victory", "VICTORY") or winner == "enemy" and _cb("result_defeat", "DEFEAT") or _cb("result_escaped", "ESCAPED")
		local enemyStr = tostring(enemyDisplayName or _cb("enemy_label", "Enemy"))
		local resultSub = winner == "player" and (_cb("you_defeated", "You defeated {enemy}."):gsub("{enemy}", enemyStr))
			or winner == "enemy" and (_cb("you_lost", "You were defeated by {enemy}."):gsub("{enemy}", enemyStr))
			or _cb("you_escaped", "You escaped the fight.")

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.new(1, -32, 0, 42)
		titleLbl.Position = UDim2.new(0, 16, 0, 18)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text = resultTitle
		titleLbl.TextColor3 = winner == "player" and theme.Gold or winner == "enemy" and theme.Bad or theme.Green
		titleLbl.TextSize = 26
		titleLbl.Font = Enum.Font.GothamBlack
		titleLbl.TextXAlignment = Enum.TextXAlignment.Center
		titleLbl.Parent = popup

		local subtitleLbl = Instance.new("TextLabel")
		subtitleLbl.Size = UDim2.new(1, -32, 0, 36)
		subtitleLbl.Position = UDim2.new(0, 16, 0, 64)
		subtitleLbl.BackgroundTransparency = 1
		subtitleLbl.Text = resultSub
		subtitleLbl.TextColor3 = theme.SubText
		subtitleLbl.TextSize = 14
		subtitleLbl.Font = Enum.Font.GothamMedium
		subtitleLbl.TextWrapped = true
		subtitleLbl.TextXAlignment = Enum.TextXAlignment.Center
		subtitleLbl.Parent = popup

		popup.Size = UDim2.new(0.7, 0, 0, 96)
		TweenService:Create(popup, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.8, 0, 0, 120),
		}):Play()

		task.delay(1.6, function()
			if popup and popup.Parent then
				TweenService:Create(popup, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					BackgroundTransparency = 1,
					Size = UDim2.new(0.75, 0, 0, 108),
				}):Play()
				task.delay(0.22, function()
					if popup then popup:Destroy() end
				end)
			end
		end)
	end

	-- Main state application
	local function applyState(newState)
		local previousState = state
		state = newState or { Active = false }
		overlay.Visible = state.Active == true
		gui.Enabled = state.Active == true
		if state.Active then
			overlayManager.closeAll()
			uiState.closeRoute()
		end
		if not state.Active then
			destroyMinigame()
			return
		end

		enemyNameLabel.Text = tostring(state.EnemyName or "Enemy")
		enemyInfo.Text = _cb("enemy_info", "{grade} | {kind} | Round {round}")
			:gsub("{grade}", tostring(state.EnemyGrade or "Unknown"))
			:gsub("{kind}", tostring(state.EnemyKind or _cb("enemy_label", "Enemy")))
			:gsub("{round}", tostring(state.Round or 1))
		updateBars()
		refreshLog(state.Log)

		if previousState and previousState.Active == true then
			local enemyDamage = math.floor((tonumber(previousState.EnemyHP) or 0) - (tonumber(state.EnemyHP) or 0))
			local playerDamage = math.floor((tonumber(previousState.PlayerHP) or 0) - (tonumber(state.PlayerHP) or 0))
			if enemyDamage > 0 then
				playConfirmedHitSound()
				popEnemyText("-" .. tostring(enemyDamage), theme.Bad, enemyDamage >= 25)
			end
			if playerDamage > 0 then
				playConfirmedHitSound()
				popPlayerText("-" .. tostring(playerDamage), theme.Bad, playerDamage >= 20)
			end
		end

		if state.Phase == "finished" or (not state.PendingAttack and not state.PendingDefense and not state.PendingCounter and activeMinigame) then
			destroyMinigame()
		end

		if state.Phase == "finished" and state.Winner then
			local resultSignature = tostring(state.Winner) .. ":" .. tostring(state.EnemyName or "") .. ":" .. tostring(state.Round or 0)
			if resultSignature ~= lastResultSignature then
				lastResultSignature = resultSignature
				showCombatResultPopup(state.Winner, state.EnemyName)
			end
		elseif state.Phase ~= "finished" then
			lastResultSignature = nil
		end

		local playerTurn = state.Phase == "player_turn"
		local defeated = state.Phase == "finished" and state.Winner == "enemy"

		local techniqueUses = tonumber(state.TechniqueUses) or 0
		local techniqueMaxUses = tonumber(state.TechniqueMaxUses) or 3
		local techniqueRemaining = math.max(0, techniqueMaxUses - techniqueUses)
		techniqueButton.Text = _cb("tech_count", "TECH {r}/{m}"):gsub("{r}", techniqueRemaining):gsub("{m}", techniqueMaxUses)

		local domain = state.Domain or {}
		local domainCost = tonumber(domain.Cost) or 0
		local domainReady = domain.Unlocked == true and (tonumber(state.PlayerCE) or 0) >= domainCost
		domainButton.Text = domain.Unlocked == true and (_cb("domain_unlocked", "DOMAIN {cost}"):gsub("{cost}", domainCost)) or _cb("domain_locked", "DOMAIN")

		setButtonEnabled(attackButton, playerTurn)
		setButtonEnabled(techniqueButton, playerTurn and techniqueRemaining > 0 and (tonumber(state.PlayerCE) or 0) >= (tonumber(state.TechniqueCECost) or 0))
		setButtonEnabled(domainButton, playerTurn and domainReady)
		setButtonEnabled(defendButton, playerTurn)
		setButtonEnabled(fleeButton, playerTurn)
		local bfCost = tonumber(state.BlackFlashCECost) or 35
		local bfReady = playerTurn and (tonumber(state.PlayerCE) or 0) >= bfCost
		blackFlashButton.Text = _cb("bflash_count", "B.FLASH {cost}"):gsub("{cost}", bfCost)
		blackFlashButton.Visible = not defeated
		setButtonEnabled(blackFlashButton, bfReady)
		resetButton.Visible = defeated
		setButtonEnabled(resetButton, defeated and state.CanReset == true)

		if defeated and state.CanReset == true and not promptedLossReset then
			promptedLossReset = true
			local productId = tonumber(state.ResetProductId) or 0
			if game.PlaceId == TEST_PURCHASE_PLACE_ID or RunService:IsStudio() then
				combatAction:FireServer("reset_purchase_bypass")
			elseif productId > 0 then
				MarketplaceService:PromptProductPurchase(player, productId)
			end
		elseif not defeated then
			promptedLossReset = false
		end

		if state.PendingAttack then
			if state.PendingAttack.Token ~= lastAttackToken then
				lastAttackToken = state.PendingAttack.Token
				if not state.PendingAttack.IsBlackFlash then
					openAttackMinigame(state.PendingAttack)
				end
			end
		else
			lastAttackToken = nil
		end
		if state.PendingDefense then
			if state.PendingDefense.Token ~= lastDefenseToken then
				lastDefenseToken = state.PendingDefense.Token
				openDefenseQTE(state.PendingDefense)
			end
		else
			lastDefenseToken = nil
		end
		if state.PendingCounter then
			if state.PendingCounter.Token ~= lastCounterToken then
				lastCounterToken = state.PendingCounter.Token
				openCounterQTE(state.PendingCounter)
			end
		else
			lastCounterToken = nil
		end
	end

	-- Button connections (via tap router for ScrollingFrame reliability)
	bindTap(attackButton, function()
		if state.Phase == "player_turn" then combatAction:FireServer("attack") end
	end)
	bindTap(techniqueButton, function()
		if state.Phase == "player_turn" then combatAction:FireServer("technique") end
	end)
	bindTap(domainButton, function()
		if state.Phase == "player_turn" then combatAction:FireServer("domain") end
	end)
	bindTap(blackFlashButton, function()
		if state.Phase == "player_turn" then combatAction:FireServer("black_flash") end
	end)
	bindTap(defendButton, function()
		if state.Phase == "player_turn" then combatAction:FireServer("defend") end
	end)
	bindTap(fleeButton, function()
		if state.Phase == "player_turn" then combatAction:FireServer("flee") end
	end)
	bindTap(resetButton, function()
		if not state.Active then return end
		local productId = tonumber(state.ResetProductId) or 0
		if game.PlaceId == TEST_PURCHASE_PLACE_ID or RunService:IsStudio() then
			combatAction:FireServer("reset_purchase_bypass")
		elseif productId > 0 then
			MarketplaceService:PromptProductPurchase(player, productId)
		else
			resetButton.Text = "SET ID"
			task.delay(1, function() resetButton.Text = _cb("btn_reset", "RESET") end)
		end
	end)

	-- Events
	combatStateUpdate.OnClientEvent:Connect(applyState)

	-- Initial state fetch
	local ok, initial = pcall(function()
		return getCombatState:InvokeServer()
	end)
	if ok then applyState(initial) end

	if RunService:IsStudio() then print("[MobileCombatPanel] Mobile combat UI loaded.") end
end

return { init = init }
