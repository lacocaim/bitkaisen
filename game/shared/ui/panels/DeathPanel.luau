local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")

local responsiveScale = require("@ui/responsiveScale")
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _d(key, fallback) return BitKaisenLocale.tOrFallback(_L, "death." .. key, nil, fallback) end

local player = Players.LocalPlayer

local RCT_REVIVE_PRODUCT_ID = 3601401158
local RCT_REVIVE_MAX_PER_LIFE = 2
local TEST_PURCHASE_PLACE_ID = 104206065947170
local RCT_REVIVE_READY_COLOR = Color3.fromRGB(55, 35, 120)
local RCT_REVIVE_LOCKED_COLOR = Color3.fromRGB(45, 45, 58)

local function formatMoneyAmount(value)
	value = math.floor((tonumber(value) or 0) * 100 + 0.5) / 100
	if value % 1 == 0 then
		return tostring(math.floor(value))
	end
	return string.format("%.2f", value)
end

local function getOrdinalSuffix(n)
	n = tonumber(n) or 1
	local lastTwo = n % 100
	if lastTwo >= 11 and lastTwo <= 13 then
		return "th"
	end
	local lastDigit = n % 10
	if lastDigit == 1 then return "st"
	elseif lastDigit == 2 then return "nd"
	elseif lastDigit == 3 then return "rd"
	end
	return "th"
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Parent = parent
	return stroke
end

local function setHoverTween(button, hoverColor)
	local baseColor = button.BackgroundColor3
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = hoverColor }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = baseColor }):Play()
	end)
end

local function init(playerGui: Instance)
	local updateLifeEvent = ReplicatedStorage:WaitForChild("UpdateLifeEvent")
	local testPurchase = ReplicatedStorage:WaitForChild("TestPurchase")
	local getSuccessorOptions = ReplicatedStorage:WaitForChild("GetSuccessorOptions")
	local chooseSuccessor = ReplicatedStorage:WaitForChild("ChooseSuccessor")

	local gui = Instance.new("ScreenGui")
	gui.Name = "BitKaisenDeathGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 670
	gui.Enabled = true
	gui.Parent = playerGui

	local overlay = Instance.new("Frame")
	overlay.Name = "DeathOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.Visible = false
	overlay.ZIndex = 900
	overlay.Parent = gui

	local window = Instance.new("Frame")
	window.Name = "DeathWindow"
	window.Size = UDim2.new(0, 640, 0, 730)
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.new(0.5, 0, 0.54, 0)
	window.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
	window.BackgroundTransparency = 1
	window.BorderSizePixel = 0
	window.Visible = false
	window.ZIndex = 901
	window.Parent = overlay
	addCorner(window, 14)
	addStroke(window, Color3.fromRGB(120, 35, 35), 2)
	responsiveScale.attach(window, 640, 730)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 0, 50)
	title.Position = UDim2.new(0, 20, 0, 18)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 30
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Text = _d("title", "LIFE ENDED")
	title.ZIndex = 902
	title.Parent = window

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(1, -50, 0, 22)
	subtitle.Position = UDim2.new(0, 25, 0, 68)
	subtitle.BackgroundTransparency = 1
	subtitle.TextColor3 = Color3.fromRGB(180, 180, 195)
	subtitle.TextSize = 13
	subtitle.Font = Enum.Font.GothamBold
	subtitle.TextXAlignment = Enum.TextXAlignment.Center
	subtitle.Text = "Your story has reached its end. Choose what comes next."
	subtitle.ZIndex = 902
	subtitle.Parent = window

	local causeLabel = Instance.new("TextLabel")
	causeLabel.Name = "CauseOfDeathLabel"
	causeLabel.Size = UDim2.new(1, -50, 0, 22)
	causeLabel.Position = UDim2.new(0, 25, 0, 88)
	causeLabel.BackgroundTransparency = 1
	causeLabel.TextColor3 = Color3.fromRGB(220, 100, 100)
	causeLabel.TextSize = 12
	causeLabel.Font = Enum.Font.GothamBold
	causeLabel.TextXAlignment = Enum.TextXAlignment.Center
	causeLabel.Text = ""
	causeLabel.ZIndex = 902
	causeLabel.Parent = window

	local biographyBox = Instance.new("Frame")
	biographyBox.Name = "BiographyBox"
	biographyBox.Size = UDim2.new(1, -70, 0, 175)
	biographyBox.Position = UDim2.new(0, 35, 0, 118)
	biographyBox.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	biographyBox.BorderSizePixel = 0
	biographyBox.ZIndex = 902
	biographyBox.Parent = window
	addCorner(biographyBox, 10)
	addStroke(biographyBox, Color3.fromRGB(45, 45, 60), 1)

	local biographyText = Instance.new("TextLabel")
	biographyText.Name = "BiographyText"
	biographyText.Size = UDim2.new(1, -28, 1, -24)
	biographyText.Position = UDim2.new(0, 14, 0, 12)
	biographyText.BackgroundTransparency = 1
	biographyText.TextColor3 = Color3.fromRGB(215, 215, 225)
	biographyText.TextSize = 14
	biographyText.Font = Enum.Font.GothamMedium
	biographyText.TextWrapped = true
	biographyText.TextYAlignment = Enum.TextYAlignment.Top
	biographyText.TextXAlignment = Enum.TextXAlignment.Left
	biographyText.RichText = true
	biographyText.Text = ""
	biographyText.ZIndex = 903
	biographyText.Parent = biographyBox

	local statsText = Instance.new("TextLabel")
	statsText.Name = "StatsText"
	statsText.Size = UDim2.new(1, -70, 0, 28)
	statsText.Position = UDim2.new(0, 35, 0, 303)
	statsText.BackgroundTransparency = 1
	statsText.TextColor3 = Color3.fromRGB(170, 170, 190)
	statsText.TextSize = 12
	statsText.Font = Enum.Font.GothamBold
	statsText.TextXAlignment = Enum.TextXAlignment.Center
	statsText.Text = ""
	statsText.ZIndex = 902
	statsText.Parent = window

	local ribbonLabel = Instance.new("TextLabel")
	ribbonLabel.Name = "RibbonLabel"
	ribbonLabel.Size = UDim2.new(1, -70, 0, 70)
	ribbonLabel.Position = UDim2.new(0, 35, 0, 331)
	ribbonLabel.TextWrapped = true
	ribbonLabel.BackgroundTransparency = 1
	ribbonLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
	ribbonLabel.TextSize = 18
	ribbonLabel.Font = Enum.Font.GothamBlack
	ribbonLabel.TextXAlignment = Enum.TextXAlignment.Center
	ribbonLabel.TextYAlignment = Enum.TextYAlignment.Center
	ribbonLabel.Text = ""
	ribbonLabel.ZIndex = 910
	ribbonLabel.Parent = window

	local buttonsHolder = Instance.new("Frame")
	buttonsHolder.Name = "ButtonsHolder"
	buttonsHolder.Size = UDim2.new(1, -70, 0, 314)
	buttonsHolder.Position = UDim2.new(0, 35, 0, 403)
	buttonsHolder.BackgroundTransparency = 1
	buttonsHolder.ZIndex = 902
	buttonsHolder.Parent = window

	local newLifeButton = Instance.new("TextButton")
	newLifeButton.Name = "StartNewLifeButton"
	newLifeButton.Size = UDim2.new(0.48, 0, 0, 50)
	newLifeButton.Position = UDim2.new(0, 0, 0, 0)
	newLifeButton.BackgroundColor3 = Color3.fromRGB(120, 35, 35)
	newLifeButton.BorderSizePixel = 0
	newLifeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	newLifeButton.TextSize = 14
	newLifeButton.Font = Enum.Font.GothamBlack
	newLifeButton.Text = _d("start_new_life", "START NEW LIFE")
	newLifeButton.AutoButtonColor = false
	newLifeButton.ZIndex = 903
	newLifeButton.Parent = buttonsHolder
	addCorner(newLifeButton, 9)
	setHoverTween(newLifeButton, Color3.fromRGB(150, 50, 50))

	local newLifeDesc = Instance.new("TextLabel")
	newLifeDesc.Name = "NewLifeDesc"
	newLifeDesc.Size = UDim2.new(0.48, 0, 0, 40)
	newLifeDesc.Position = UDim2.new(0, 0, 0, 56)
	newLifeDesc.BackgroundTransparency = 1
	newLifeDesc.TextColor3 = Color3.fromRGB(150, 150, 165)
	newLifeDesc.TextSize = 11
	newLifeDesc.Font = Enum.Font.GothamMedium
	newLifeDesc.TextWrapped = true
	newLifeDesc.TextXAlignment = Enum.TextXAlignment.Center
	newLifeDesc.TextYAlignment = Enum.TextYAlignment.Top
	newLifeDesc.Text = "Reroll origin, family, technique.\nFresh bloodline. Nothing carries over."
	newLifeDesc.ZIndex = 903
	newLifeDesc.Parent = buttonsHolder

	local successorButton = Instance.new("TextButton")
	successorButton.Name = "PlayAsChildButton"
	successorButton.Size = UDim2.new(0.48, 0, 0, 50)
	successorButton.Position = UDim2.new(0.52, 0, 0, 0)
	successorButton.BackgroundColor3 = Color3.fromRGB(95, 55, 150)
	successorButton.BorderSizePixel = 0
	successorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	successorButton.TextSize = 14
	successorButton.Font = Enum.Font.GothamBlack
	successorButton.Text = _d("play_as_child", "PLAY AS CHILD")
	successorButton.AutoButtonColor = false
	successorButton.ZIndex = 903
	successorButton.Parent = buttonsHolder
	addCorner(successorButton, 9)
	setHoverTween(successorButton, Color3.fromRGB(125, 75, 190))

	local successorDesc = Instance.new("TextLabel")
	successorDesc.Name = "SuccessorDesc"
	successorDesc.Size = UDim2.new(0.48, 0, 0, 40)
	successorDesc.Position = UDim2.new(0.52, 0, 0, 56)
	successorDesc.BackgroundTransparency = 1
	successorDesc.TextColor3 = Color3.fromRGB(180, 150, 220)
	successorDesc.TextSize = 11
	successorDesc.Font = Enum.Font.GothamMedium
	successorDesc.TextWrapped = true
	successorDesc.TextXAlignment = Enum.TextXAlignment.Center
	successorDesc.TextYAlignment = Enum.TextYAlignment.Top
	successorDesc.Text = "Continue as one of your children.\nInherit assets, clan, technique, money."
	successorDesc.ZIndex = 903
	successorDesc.Parent = buttonsHolder

	local rctReviveButton = Instance.new("TextButton")
	rctReviveButton.Name = "RCTReviveButton"
	rctReviveButton.Size = UDim2.new(1, 0, 0, 46)
	rctReviveButton.Position = UDim2.new(0, 0, 0, 108)
	rctReviveButton.BackgroundColor3 = RCT_REVIVE_READY_COLOR
	rctReviveButton.BorderSizePixel = 0
	rctReviveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	rctReviveButton.TextSize = 13
	rctReviveButton.Font = Enum.Font.GothamBlack
	rctReviveButton.Text = "RCT REVIVE - R$50"
	rctReviveButton.AutoButtonColor = false
	rctReviveButton.ZIndex = 903
	rctReviveButton.Parent = buttonsHolder
	addCorner(rctReviveButton, 9)
	setHoverTween(rctReviveButton, Color3.fromRGB(80, 55, 170))

	local rctReviveDesc = Instance.new("TextLabel")
	rctReviveDesc.Name = "RCTReviveDesc"
	rctReviveDesc.Size = UDim2.new(1, -20, 0, 28)
	rctReviveDesc.Position = UDim2.new(0, 10, 0, 156)
	rctReviveDesc.BackgroundTransparency = 1
	rctReviveDesc.TextColor3 = Color3.fromRGB(190, 175, 255)
	rctReviveDesc.TextSize = 10
	rctReviveDesc.Font = Enum.Font.GothamMedium
	rctReviveDesc.TextWrapped = true
	rctReviveDesc.TextXAlignment = Enum.TextXAlignment.Center
	rctReviveDesc.TextYAlignment = Enum.TextYAlignment.Top
	rctReviveDesc.Text = "Reverse cursed energy pulls you back. Old age extends lifespan; other deaths give a second chance."
	rctReviveDesc.ZIndex = 903
	rctReviveDesc.Parent = buttonsHolder

	local curseRebirthButton = Instance.new("TextButton")
	curseRebirthButton.Name = "BecomeVengefulSpiritButton"
	curseRebirthButton.Size = UDim2.new(1, 0, 0, 46)
	curseRebirthButton.Position = UDim2.new(0, 0, 0, 198)
	curseRebirthButton.BackgroundColor3 = Color3.fromRGB(110, 45, 160)
	curseRebirthButton.BorderSizePixel = 0
	curseRebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	curseRebirthButton.TextSize = 13
	curseRebirthButton.Font = Enum.Font.GothamBlack
	curseRebirthButton.Text = _d("become_spirit", "BECOME VENGEFUL SPIRIT")
	curseRebirthButton.AutoButtonColor = false
	curseRebirthButton.Visible = false
	curseRebirthButton.ZIndex = 903
	curseRebirthButton.Parent = buttonsHolder
	addCorner(curseRebirthButton, 9)
	setHoverTween(curseRebirthButton, Color3.fromRGB(145, 65, 205))

	local curseRebirthDesc = Instance.new("TextLabel")
	curseRebirthDesc.Name = "CurseRebirthDesc"
	curseRebirthDesc.Size = UDim2.new(1, -20, 0, 28)
	curseRebirthDesc.Position = UDim2.new(0, 10, 0, 246)
	curseRebirthDesc.BackgroundTransparency = 1
	curseRebirthDesc.TextColor3 = Color3.fromRGB(205, 170, 245)
	curseRebirthDesc.TextSize = 10
	curseRebirthDesc.Font = Enum.Font.GothamMedium
	curseRebirthDesc.TextWrapped = true
	curseRebirthDesc.TextXAlignment = Enum.TextXAlignment.Center
	curseRebirthDesc.TextYAlignment = Enum.TextYAlignment.Top
	curseRebirthDesc.Text = "Your cursed energy or cursed-object anchor refused to disappear. Return as a reborn cursed spirit."
	curseRebirthDesc.Visible = false
	curseRebirthDesc.ZIndex = 903
	curseRebirthDesc.Parent = buttonsHolder

	local reincarnateButton = Instance.new("TextButton")
	reincarnateButton.Name = "ReincarnateButton"
	reincarnateButton.Size = UDim2.new(1, 0, 0, 46)
	reincarnateButton.Position = UDim2.new(0, 0, 0, 198)
	reincarnateButton.BackgroundColor3 = Color3.fromRGB(75, 70, 170)
	reincarnateButton.BorderSizePixel = 0
	reincarnateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	reincarnateButton.TextSize = 13
	reincarnateButton.Font = Enum.Font.GothamBlack
	reincarnateButton.Text = _d("reincarnate", "REINCARNATE")
	reincarnateButton.AutoButtonColor = false
	reincarnateButton.Visible = false
	reincarnateButton.ZIndex = 903
	reincarnateButton.Parent = buttonsHolder
	addCorner(reincarnateButton, 9)
	setHoverTween(reincarnateButton, Color3.fromRGB(105, 95, 215))

	local reincarnateDesc = Instance.new("TextLabel")
	reincarnateDesc.Name = "ReincarnateDesc"
	reincarnateDesc.Size = UDim2.new(1, -20, 0, 28)
	reincarnateDesc.Position = UDim2.new(0, 10, 0, 246)
	reincarnateDesc.BackgroundTransparency = 1
	reincarnateDesc.TextColor3 = Color3.fromRGB(190, 190, 255)
	reincarnateDesc.TextSize = 10
	reincarnateDesc.Font = Enum.Font.GothamMedium
	reincarnateDesc.TextWrapped = true
	reincarnateDesc.TextXAlignment = Enum.TextXAlignment.Center
	reincarnateDesc.TextYAlignment = Enum.TextYAlignment.Top
	reincarnateDesc.Text = "A cursed-object anchor can pull your soul into a new life while keeping CE, clan, and technique."
	reincarnateDesc.Visible = false
	reincarnateDesc.ZIndex = 903
	reincarnateDesc.Parent = buttonsHolder

	local quickRerollButton = Instance.new("TextButton")
	quickRerollButton.Name = "QuickRerollButton"
	quickRerollButton.Size = UDim2.new(1, 0, 0, 38)
	quickRerollButton.Position = UDim2.new(0, 0, 0, 278)
	quickRerollButton.BackgroundColor3 = Color3.fromRGB(38, 26, 65)
	quickRerollButton.BorderSizePixel = 0
	quickRerollButton.TextColor3 = Color3.fromRGB(200, 170, 255)
	quickRerollButton.TextSize = 13
	quickRerollButton.Font = Enum.Font.GothamBlack
	quickRerollButton.Text = "QUICK REROLL  — Pick CT & Clan"
	quickRerollButton.AutoButtonColor = false
	quickRerollButton.ZIndex = 903
	quickRerollButton.Parent = buttonsHolder
	addCorner(quickRerollButton, 9)
	addStroke(quickRerollButton, Color3.fromRGB(90, 55, 160), 1)
	setHoverTween(quickRerollButton, Color3.fromRGB(58, 40, 100))

	-- Successor Picker
	local pickerOverlay = Instance.new("Frame")
	pickerOverlay.Name = "SuccessorPickerOverlay"
	pickerOverlay.Size = UDim2.new(1, 0, 1, 0)
	pickerOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	pickerOverlay.BackgroundTransparency = 1
	pickerOverlay.Visible = false
	pickerOverlay.ZIndex = 950
	pickerOverlay.Parent = gui

	local pickerWindow = Instance.new("Frame")
	pickerWindow.Name = "SuccessorPickerWindow"
	pickerWindow.Size = UDim2.new(0, 580, 0, 480)
	pickerWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	pickerWindow.Position = UDim2.new(0.5, 0, 0.54, 0)
	pickerWindow.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
	pickerWindow.BackgroundTransparency = 1
	pickerWindow.BorderSizePixel = 0
	pickerWindow.Visible = false
	pickerWindow.ZIndex = 951
	pickerWindow.Parent = pickerOverlay
	addCorner(pickerWindow, 14)
	addStroke(pickerWindow, Color3.fromRGB(95, 55, 150), 2)

	local pickerTitle = Instance.new("TextLabel")
	pickerTitle.Name = "Title"
	pickerTitle.Size = UDim2.new(1, -90, 0, 38)
	pickerTitle.Position = UDim2.new(0, 30, 0, 18)
	pickerTitle.BackgroundTransparency = 1
	pickerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	pickerTitle.TextSize = 22
	pickerTitle.Font = Enum.Font.GothamBlack
	pickerTitle.TextXAlignment = Enum.TextXAlignment.Left
	pickerTitle.Text = _d("choose_successor", "CHOOSE YOUR SUCCESSOR")
	pickerTitle.ZIndex = 952
	pickerTitle.Parent = pickerWindow

	local pickerSubtitle = Instance.new("TextLabel")
	pickerSubtitle.Name = "Subtitle"
	pickerSubtitle.Size = UDim2.new(1, -90, 0, 20)
	pickerSubtitle.Position = UDim2.new(0, 30, 0, 54)
	pickerSubtitle.BackgroundTransparency = 1
	pickerSubtitle.TextColor3 = Color3.fromRGB(170, 150, 210)
	pickerSubtitle.TextSize = 12
	pickerSubtitle.Font = Enum.Font.GothamBold
	pickerSubtitle.TextXAlignment = Enum.TextXAlignment.Left
	pickerSubtitle.Text = "Pick the child who will carry on your bloodline."
	pickerSubtitle.ZIndex = 952
	pickerSubtitle.Parent = pickerWindow

	local pickerClose = Instance.new("TextButton")
	pickerClose.Name = "CloseButton"
	pickerClose.Size = UDim2.new(0, 40, 0, 40)
	pickerClose.Position = UDim2.new(1, -54, 0, 16)
	pickerClose.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
	pickerClose.BorderSizePixel = 0
	pickerClose.TextColor3 = Color3.fromRGB(220, 90, 90)
	pickerClose.TextSize = 20
	pickerClose.Font = Enum.Font.GothamBlack
	pickerClose.Text = "X"
	pickerClose.AutoButtonColor = false
	pickerClose.ZIndex = 953
	pickerClose.Parent = pickerWindow
	addCorner(pickerClose, 8)
	setHoverTween(pickerClose, Color3.fromRGB(45, 25, 32))

	local pickerScroll = Instance.new("ScrollingFrame")
	pickerScroll.Name = "Scroll"
	pickerScroll.Size = UDim2.new(1, -60, 1, -110)
	pickerScroll.Position = UDim2.new(0, 30, 0, 90)
	pickerScroll.BackgroundTransparency = 1
	pickerScroll.BorderSizePixel = 0
	pickerScroll.ScrollBarThickness = 4
	pickerScroll.ScrollBarImageColor3 = Color3.fromRGB(95, 55, 150)
	pickerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	pickerScroll.ZIndex = 952
	pickerScroll.Parent = pickerWindow

	local pickerLayout = Instance.new("UIListLayout")
	pickerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pickerLayout.Padding = UDim.new(0, 10)
	pickerLayout.Parent = pickerScroll

	pickerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		pickerScroll.CanvasSize = UDim2.new(0, 0, 0, pickerLayout.AbsoluteContentSize.Y + 16)
	end)

	local lastDeathStats = nil   -- forward-declared so Quick Reroll closures can reference it
	local hideDeathScreen        -- forward-declared; assigned below in the State section

	-- ================== QUICK REROLL DATA ==================
	local BitKaisenStats = require(ReplicatedStorage:WaitForChild("BitKaisenStats"))

	local QR_TOTAL_CHANCE = 0
	for _, origin in ipairs(BitKaisenStats.Origins) do
		if (origin.Chance or 0) > 0 then QR_TOTAL_CHANCE = QR_TOTAL_CHANCE + origin.Chance end
	end

	local QR_CT_PROB  = {}  -- CT name → combined natural probability (0-1)
	local QR_CT_CLANS = {}  -- CT name → { origin, ... }
	for _, origin in ipairs(BitKaisenStats.Origins) do
		if (origin.Chance or 0) > 0 and typeof(origin.InnatePool) == "table" then
			local poolTotal = 0
			for _, e in ipairs(origin.InnatePool) do poolTotal = poolTotal + (e.Weight or 1) end
			for _, e in ipairs(origin.InnatePool) do
				local ct = e.Name
				QR_CT_CLANS[ct] = QR_CT_CLANS[ct] or {}
				table.insert(QR_CT_CLANS[ct], origin)
				QR_CT_PROB[ct] = (QR_CT_PROB[ct] or 0) + (origin.Chance / QR_TOTAL_CHANCE) * ((e.Weight or 1) / poolTotal)
			end
		end
	end

	local QR_CT_NAMES = {}
	for ct in pairs(QR_CT_CLANS) do table.insert(QR_CT_NAMES, ct) end
	table.sort(QR_CT_NAMES, function(a, b)
		local pa, pb = QR_CT_PROB[a] or 0, QR_CT_PROB[b] or 0
		if math.abs(pa - pb) > 0.0005 then return pa < pb end
		return a < b
	end)

	local QR_CT_COLORS = {
		["Limitless"]                  = Color3.fromRGB(138, 92, 246),
		["Ten Shadows"]                = Color3.fromRGB(55, 55, 70),
		["Copy"]                       = Color3.fromRGB(100, 200, 255),
		["Rika Manifestation"]         = Color3.fromRGB(230, 100, 160),
		["Shrine"]                     = Color3.fromRGB(220, 80, 80),
		["Brain Transplant"]           = Color3.fromRGB(120, 200, 120),
		["Pumpkin Control"]            = Color3.fromRGB(230, 140, 40),
		["Cursed Spirit Manipulation"] = Color3.fromRGB(100, 60, 160),
		["Idle Transfiguration"]       = Color3.fromRGB(90, 180, 160),
		["Mythical Beast Amber"]       = Color3.fromRGB(240, 180, 50),
		["Puppet Manipulation"]        = Color3.fromRGB(180, 120, 80),
		["Mechamaru"]                  = Color3.fromRGB(150, 150, 180),
		["Heavenly Restriction"]       = Color3.fromRGB(200, 200, 220),
		["Private Pure Love Train"]    = Color3.fromRGB(220, 100, 180),
		["Deadly Sentencing"]          = Color3.fromRGB(220, 60, 60),
		["Projection Sorcery"]         = Color3.fromRGB(80, 160, 240),
		["Blood Manipulation"]         = Color3.fromRGB(200, 50, 50),
		["Cursed Speech"]              = Color3.fromRGB(160, 120, 220),
		["Boogie Woogie"]              = Color3.fromRGB(100, 220, 120),
		["Ratio Technique"]            = Color3.fromRGB(220, 200, 100),
		["Construction"]               = Color3.fromRGB(180, 160, 120),
		["Tool Manipulation"]          = Color3.fromRGB(160, 160, 160),
		["Simple Domain"]              = Color3.fromRGB(80, 140, 200),
		["Ice Formation"]              = Color3.fromRGB(150, 220, 255),
		["Disaster Flames"]            = Color3.fromRGB(240, 120, 40),
	}
	local QR_CT_DESCS = {
		["Limitless"]                  = "Manipulates space at the atomic level.",
		["Ten Shadows"]                = "Summons shikigami from shadow.",
		["Copy"]                       = "Replicates any cursed technique on contact.",
		["Rika Manifestation"]         = "Channels the Queen of Curses.",
		["Shrine"]                     = "Slashes that cut across any distance.",
		["Brain Transplant"]           = "Transplants consciousness. Near-immortal.",
		["Pumpkin Control"]            = "Conjures explosive pumpkin constructs.",
		["Cursed Spirit Manipulation"] = "Absorbs and deploys cursed spirits.",
		["Idle Transfiguration"]       = "Reshapes souls and bodies at a touch.",
		["Mythical Beast Amber"]       = "Electrifies the body to superhuman extremes.",
		["Puppet Manipulation"]        = "Remote-controls puppets and constructs.",
		["Mechamaru"]                  = "Pilots mechanical shells from any distance.",
		["Heavenly Restriction"]       = "No cursed energy for a perfected body.",
		["Private Pure Love Train"]    = "Probability jackpot. Losing streaks reset.",
		["Deadly Sentencing"]          = "Holds court to strip the right to exist.",
		["Projection Sorcery"]         = "Divides time into frames. Deviation freezes.",
		["Blood Manipulation"]         = "Shapes and weaponizes blood.",
		["Cursed Speech"]              = "Words carry absolute commands.",
		["Boogie Woogie"]              = "Swaps positions of CE carriers with a clap.",
		["Ratio Technique"]            = "Exploits the 7:3 ratio as a fatal point.",
		["Construction"]               = "Materializes anything imagined in detail.",
		["Tool Manipulation"]          = "Remotely controls cursed tools.",
		["Simple Domain"]              = "Automatic counter-technique barrier.",
		["Ice Formation"]              = "Shapes and fires weaponized ice.",
		["Disaster Flames"]            = "Generates destructive cursed-energy flames.",
		["Soul Striking"]              = "Delivers hits that bypass physical defenses.",
		["Divergent Fist"]             = "CE release on contact doubles strike impact.",
		["New Shadow Style"]           = "Precise sword-form amplified by CE.",
		["Barrier Technique"]          = "Erects curtains and barriers with CE.",
		["Contractual Re-Creation"]    = "Reconstructs anything previously memorized.",
		["Sky Manipulation"]           = "Reshapes and commands aerial space.",
		["Cursed Energy Discharge"]    = "Releases CE in raw, unfocused bursts.",
		["Shikigami Technique"]        = "Creates and directs shikigami constructs.",
		["Rot Technique"]              = "Decays cursed matter and living targets.",
		["Comedian"]                   = "Reality-warping through laughter and absurdity.",
	}

	local QR_DEFAULT_COLOR = Color3.fromRGB(120, 80, 180)
	local function getQRCTRarity(ct)
		local p = (QR_CT_PROB[ct] or 0) * 100
		if p <= 0.3 then return "LEGENDARY", Color3.fromRGB(220, 160, 255)
		elseif p <= 1 then return "RARE", Color3.fromRGB(100, 160, 255)
		elseif p <= 3 then return "UNCOMMON", Color3.fromRGB(100, 210, 120)
		else return "COMMON", Color3.fromRGB(160, 160, 170)
		end
	end
	local function getQRClanRarity(chance)
		local p = QR_TOTAL_CHANCE > 0 and (chance / QR_TOTAL_CHANCE) * 100 or 0
		if p <= 0.5 then return "LEGENDARY", Color3.fromRGB(220, 160, 255)
		elseif p <= 1.5 then return "RARE", Color3.fromRGB(100, 160, 255)
		elseif p <= 3 then return "UNCOMMON", Color3.fromRGB(100, 210, 120)
		else return "COMMON", Color3.fromRGB(160, 160, 170)
		end
	end

	-- ================== QUICK REROLL OVERLAY ==================
	local rerollOverlay = Instance.new("Frame")
	rerollOverlay.Name = "QuickRerollOverlay"
	rerollOverlay.Size = UDim2.new(1, 0, 1, 0)
	rerollOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	rerollOverlay.BackgroundTransparency = 1
	rerollOverlay.Visible = false
	rerollOverlay.ZIndex = 960
	rerollOverlay.Parent = gui

	local rerollWindow = Instance.new("Frame")
	rerollWindow.Name = "QuickRerollWindow"
	rerollWindow.Size = UDim2.new(0, 600, 0, 540)
	rerollWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	rerollWindow.Position = UDim2.new(0.5, 0, 0.56, 0)
	rerollWindow.BackgroundColor3 = Color3.fromRGB(12, 10, 20)
	rerollWindow.BackgroundTransparency = 1
	rerollWindow.BorderSizePixel = 0
	rerollWindow.Visible = false
	rerollWindow.ZIndex = 961
	rerollWindow.Parent = rerollOverlay
	addCorner(rerollWindow, 14)
	addStroke(rerollWindow, Color3.fromRGB(90, 45, 140), 2)
	responsiveScale.attach(rerollWindow, 600, 540)

	local rerollTitleLabel = Instance.new("TextLabel")
	rerollTitleLabel.Size = UDim2.new(1, -90, 0, 28)
	rerollTitleLabel.Position = UDim2.new(0, 22, 0, 14)
	rerollTitleLabel.BackgroundTransparency = 1
	rerollTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	rerollTitleLabel.TextSize = 18
	rerollTitleLabel.Font = Enum.Font.GothamBlack
	rerollTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	rerollTitleLabel.Text = "QUICK REROLL"
	rerollTitleLabel.ZIndex = 962
	rerollTitleLabel.Parent = rerollWindow

	local rerollBreadcrumb = Instance.new("TextLabel")
	rerollBreadcrumb.Size = UDim2.new(1, -90, 0, 16)
	rerollBreadcrumb.Position = UDim2.new(0, 22, 0, 44)
	rerollBreadcrumb.BackgroundTransparency = 1
	rerollBreadcrumb.TextColor3 = Color3.fromRGB(160, 140, 200)
	rerollBreadcrumb.TextSize = 10
	rerollBreadcrumb.Font = Enum.Font.GothamBold
	rerollBreadcrumb.TextXAlignment = Enum.TextXAlignment.Left
	rerollBreadcrumb.Text = "Step 1 of 3  —  Select Cursed Technique"
	rerollBreadcrumb.ZIndex = 962
	rerollBreadcrumb.Parent = rerollWindow

	local rerollDivider = Instance.new("Frame")
	rerollDivider.Size = UDim2.new(1, -44, 0, 1)
	rerollDivider.Position = UDim2.new(0, 22, 0, 64)
	rerollDivider.BackgroundColor3 = Color3.fromRGB(55, 45, 80)
	rerollDivider.BorderSizePixel = 0
	rerollDivider.ZIndex = 962
	rerollDivider.Parent = rerollWindow

	local rerollClose = Instance.new("TextButton")
	rerollClose.Size = UDim2.new(0, 34, 0, 34)
	rerollClose.Position = UDim2.new(1, -48, 0, 12)
	rerollClose.BackgroundColor3 = Color3.fromRGB(25, 20, 38)
	rerollClose.BorderSizePixel = 0
	rerollClose.TextColor3 = Color3.fromRGB(220, 90, 90)
	rerollClose.TextSize = 14
	rerollClose.Font = Enum.Font.GothamBlack
	rerollClose.Text = "X"
	rerollClose.AutoButtonColor = false
	rerollClose.ZIndex = 963
	rerollClose.Parent = rerollWindow
	addCorner(rerollClose, 7)
	setHoverTween(rerollClose, Color3.fromRGB(45, 20, 35))

	local QR_CONTENT_Y = 70
	local QR_CONTENT_H = 540 - QR_CONTENT_Y - 6

	-- ===== PAGE 1: CT SELECTION =====
	local ctPage = Instance.new("Frame")
	ctPage.Name = "CTPage"
	ctPage.Size = UDim2.new(1, 0, 0, QR_CONTENT_H)
	ctPage.Position = UDim2.new(0, 0, 0, QR_CONTENT_Y)
	ctPage.BackgroundTransparency = 1
	ctPage.ZIndex = 962
	ctPage.Parent = rerollWindow

	local ctTopBar = Instance.new("Frame")
	ctTopBar.Size = UDim2.new(1, 0, 0, 42)
	ctTopBar.BackgroundTransparency = 1
	ctTopBar.ZIndex = 963
	ctTopBar.Parent = ctPage

	local ctRandomBtn = Instance.new("TextButton")
	ctRandomBtn.Size = UDim2.new(0, 130, 0, 30)
	ctRandomBtn.Position = UDim2.new(0, 14, 0, 6)
	ctRandomBtn.BackgroundColor3 = Color3.fromRGB(35, 28, 55)
	ctRandomBtn.BorderSizePixel = 0
	ctRandomBtn.TextColor3 = Color3.fromRGB(200, 180, 255)
	ctRandomBtn.TextSize = 11
	ctRandomBtn.Font = Enum.Font.GothamBlack
	ctRandomBtn.Text = "RANDOM CT"
	ctRandomBtn.AutoButtonColor = false
	ctRandomBtn.ZIndex = 964
	ctRandomBtn.Parent = ctTopBar
	addCorner(ctRandomBtn, 7)
	addStroke(ctRandomBtn, Color3.fromRGB(80, 55, 130), 1)
	setHoverTween(ctRandomBtn, Color3.fromRGB(55, 44, 85))

	local ctRandomEverythingBtn = Instance.new("TextButton")
	ctRandomEverythingBtn.Size = UDim2.new(0, 160, 0, 30)
	ctRandomEverythingBtn.Position = UDim2.new(0, 152, 0, 6)
	ctRandomEverythingBtn.BackgroundColor3 = Color3.fromRGB(22, 48, 32)
	ctRandomEverythingBtn.BorderSizePixel = 0
	ctRandomEverythingBtn.TextColor3 = Color3.fromRGB(130, 215, 150)
	ctRandomEverythingBtn.TextSize = 11
	ctRandomEverythingBtn.Font = Enum.Font.GothamBlack
	ctRandomEverythingBtn.Text = "RANDOM EVERYTHING"
	ctRandomEverythingBtn.AutoButtonColor = false
	ctRandomEverythingBtn.ZIndex = 964
	ctRandomEverythingBtn.Parent = ctTopBar
	addCorner(ctRandomEverythingBtn, 7)
	addStroke(ctRandomEverythingBtn, Color3.fromRGB(50, 100, 65), 1)
	setHoverTween(ctRandomEverythingBtn, Color3.fromRGB(36, 72, 48))

	local ctScroll = Instance.new("ScrollingFrame")
	ctScroll.Size = UDim2.new(1, -18, 0, QR_CONTENT_H - 44)
	ctScroll.Position = UDim2.new(0, 9, 0, 42)
	ctScroll.BackgroundTransparency = 1
	ctScroll.BorderSizePixel = 0
	ctScroll.ScrollBarThickness = 4
	ctScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 55, 140)
	ctScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	ctScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ctScroll.ZIndex = 963
	ctScroll.Parent = ctPage

	local ctGrid = Instance.new("UIGridLayout")
	ctGrid.CellSize = UDim2.new(0.5, -6, 0, 80)
	ctGrid.CellPadding = UDim2.new(0, 8, 0, 8)
	ctGrid.SortOrder = Enum.SortOrder.LayoutOrder
	ctGrid.Parent = ctScroll

	local ctScrollPad = Instance.new("UIPadding")
	ctScrollPad.PaddingLeft = UDim.new(0, 4)
	ctScrollPad.PaddingRight = UDim.new(0, 4)
	ctScrollPad.PaddingTop = UDim.new(0, 4)
	ctScrollPad.PaddingBottom = UDim.new(0, 4)
	ctScrollPad.Parent = ctScroll

	-- CT Info modal (inline)
	local ctInfoModal = Instance.new("Frame")
	ctInfoModal.Name = "CTInfoModal"
	ctInfoModal.Size = UDim2.new(0, 320, 0, 190)
	ctInfoModal.AnchorPoint = Vector2.new(0.5, 0.5)
	ctInfoModal.Position = UDim2.fromScale(0.5, 0.5)
	ctInfoModal.BackgroundColor3 = Color3.fromRGB(18, 14, 30)
	ctInfoModal.BorderSizePixel = 0
	ctInfoModal.Visible = false
	ctInfoModal.ZIndex = 985
	ctInfoModal.Parent = rerollWindow
	addCorner(ctInfoModal, 12)
	addStroke(ctInfoModal, Color3.fromRGB(100, 60, 160), 2)

	local ctInfoCloseBtn = Instance.new("TextButton")
	ctInfoCloseBtn.Size = UDim2.new(0, 26, 0, 26)
	ctInfoCloseBtn.Position = UDim2.new(1, -34, 0, 8)
	ctInfoCloseBtn.BackgroundColor3 = Color3.fromRGB(30, 22, 45)
	ctInfoCloseBtn.BorderSizePixel = 0
	ctInfoCloseBtn.TextColor3 = Color3.fromRGB(200, 80, 80)
	ctInfoCloseBtn.TextSize = 12
	ctInfoCloseBtn.Font = Enum.Font.GothamBlack
	ctInfoCloseBtn.Text = "X"
	ctInfoCloseBtn.AutoButtonColor = false
	ctInfoCloseBtn.ZIndex = 986
	ctInfoCloseBtn.Parent = ctInfoModal
	addCorner(ctInfoCloseBtn, 5)

	local ctInfoNameLabel = Instance.new("TextLabel")
	ctInfoNameLabel.Size = UDim2.new(1, -50, 0, 26)
	ctInfoNameLabel.Position = UDim2.new(0, 14, 0, 10)
	ctInfoNameLabel.BackgroundTransparency = 1
	ctInfoNameLabel.TextColor3 = Color3.fromRGB(240, 235, 255)
	ctInfoNameLabel.TextSize = 15
	ctInfoNameLabel.Font = Enum.Font.GothamBlack
	ctInfoNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	ctInfoNameLabel.Text = ""
	ctInfoNameLabel.ZIndex = 986
	ctInfoNameLabel.Parent = ctInfoModal

	local ctInfoRarityLabel = Instance.new("TextLabel")
	ctInfoRarityLabel.Size = UDim2.new(1, -28, 0, 16)
	ctInfoRarityLabel.Position = UDim2.new(0, 14, 0, 38)
	ctInfoRarityLabel.BackgroundTransparency = 1
	ctInfoRarityLabel.TextSize = 9
	ctInfoRarityLabel.Font = Enum.Font.GothamBold
	ctInfoRarityLabel.TextXAlignment = Enum.TextXAlignment.Left
	ctInfoRarityLabel.Text = ""
	ctInfoRarityLabel.ZIndex = 986
	ctInfoRarityLabel.Parent = ctInfoModal

	local ctInfoDescLabel = Instance.new("TextLabel")
	ctInfoDescLabel.Size = UDim2.new(1, -28, 0, 56)
	ctInfoDescLabel.Position = UDim2.new(0, 14, 0, 58)
	ctInfoDescLabel.BackgroundTransparency = 1
	ctInfoDescLabel.TextColor3 = Color3.fromRGB(210, 205, 230)
	ctInfoDescLabel.TextSize = 11
	ctInfoDescLabel.Font = Enum.Font.GothamMedium
	ctInfoDescLabel.TextWrapped = true
	ctInfoDescLabel.TextYAlignment = Enum.TextYAlignment.Top
	ctInfoDescLabel.TextXAlignment = Enum.TextXAlignment.Left
	ctInfoDescLabel.Text = ""
	ctInfoDescLabel.ZIndex = 986
	ctInfoDescLabel.Parent = ctInfoModal

	local ctInfoClansLabel = Instance.new("TextLabel")
	ctInfoClansLabel.Size = UDim2.new(1, -28, 0, 48)
	ctInfoClansLabel.Position = UDim2.new(0, 14, 0, 120)
	ctInfoClansLabel.BackgroundTransparency = 1
	ctInfoClansLabel.TextColor3 = Color3.fromRGB(155, 140, 185)
	ctInfoClansLabel.TextSize = 9
	ctInfoClansLabel.Font = Enum.Font.GothamBold
	ctInfoClansLabel.TextWrapped = true
	ctInfoClansLabel.TextYAlignment = Enum.TextYAlignment.Top
	ctInfoClansLabel.TextXAlignment = Enum.TextXAlignment.Left
	ctInfoClansLabel.Text = ""
	ctInfoClansLabel.ZIndex = 986
	ctInfoClansLabel.Parent = ctInfoModal

	local function openCTInfoModal(ctName)
		local rarity, rarityColor = getQRCTRarity(ctName)
		ctInfoNameLabel.Text = ctName
		ctInfoNameLabel.TextColor3 = QR_CT_COLORS[ctName] or QR_DEFAULT_COLOR
		local prob = (QR_CT_PROB[ctName] or 0) * 100
		ctInfoRarityLabel.Text = rarity .. "  —  " .. string.format("%.2f%%", prob) .. " natural rate"
		ctInfoRarityLabel.TextColor3 = rarityColor
		ctInfoDescLabel.Text = QR_CT_DESCS[ctName] or "A clan-exclusive cursed technique."
		local clans = QR_CT_CLANS[ctName] or {}
		local names = {}
		for _, clan in ipairs(clans) do table.insert(names, clan.DisplayName) end
		ctInfoClansLabel.Text = "Available from: " .. (#names > 0 and table.concat(names, ", ") or "—")
		ctInfoModal.Visible = true
	end

	ctInfoCloseBtn.MouseButton1Click:Connect(function()
		ctInfoModal.Visible = false
	end)

	-- ===== PAGE 2: CLAN SELECTION =====
	local clanPage = Instance.new("Frame")
	clanPage.Name = "ClanPage"
	clanPage.Size = UDim2.new(1, 0, 0, QR_CONTENT_H)
	clanPage.Position = UDim2.new(0, 0, 0, QR_CONTENT_Y)
	clanPage.BackgroundTransparency = 1
	clanPage.ZIndex = 962
	clanPage.Visible = false
	clanPage.Parent = rerollWindow

	local clanTopBar = Instance.new("Frame")
	clanTopBar.Size = UDim2.new(1, 0, 0, 54)
	clanTopBar.BackgroundTransparency = 1
	clanTopBar.ZIndex = 963
	clanTopBar.Parent = clanPage

	local clanBackBtn = Instance.new("TextButton")
	clanBackBtn.Size = UDim2.new(0, 80, 0, 28)
	clanBackBtn.Position = UDim2.new(0, 14, 0, 6)
	clanBackBtn.BackgroundColor3 = Color3.fromRGB(30, 25, 45)
	clanBackBtn.BorderSizePixel = 0
	clanBackBtn.TextColor3 = Color3.fromRGB(190, 180, 210)
	clanBackBtn.TextSize = 11
	clanBackBtn.Font = Enum.Font.GothamBold
	clanBackBtn.Text = "BACK"
	clanBackBtn.AutoButtonColor = false
	clanBackBtn.ZIndex = 964
	clanBackBtn.Parent = clanTopBar
	addCorner(clanBackBtn, 7)
	setHoverTween(clanBackBtn, Color3.fromRGB(48, 40, 70))

	local clanRandomBtn = Instance.new("TextButton")
	clanRandomBtn.Size = UDim2.new(0, 130, 0, 28)
	clanRandomBtn.Position = UDim2.new(1, -148, 0, 6)
	clanRandomBtn.BackgroundColor3 = Color3.fromRGB(35, 28, 55)
	clanRandomBtn.BorderSizePixel = 0
	clanRandomBtn.TextColor3 = Color3.fromRGB(200, 180, 255)
	clanRandomBtn.TextSize = 11
	clanRandomBtn.Font = Enum.Font.GothamBlack
	clanRandomBtn.Text = "RANDOM CLAN"
	clanRandomBtn.AutoButtonColor = false
	clanRandomBtn.ZIndex = 964
	clanRandomBtn.Parent = clanTopBar
	addCorner(clanRandomBtn, 7)
	addStroke(clanRandomBtn, Color3.fromRGB(80, 55, 130), 1)
	setHoverTween(clanRandomBtn, Color3.fromRGB(55, 44, 85))

	local clanCTLabel = Instance.new("TextLabel")
	clanCTLabel.Size = UDim2.new(1, -28, 0, 16)
	clanCTLabel.Position = UDim2.new(0, 14, 0, 38)
	clanCTLabel.BackgroundTransparency = 1
	clanCTLabel.TextColor3 = Color3.fromRGB(155, 140, 190)
	clanCTLabel.TextSize = 9
	clanCTLabel.Font = Enum.Font.GothamBold
	clanCTLabel.TextXAlignment = Enum.TextXAlignment.Left
	clanCTLabel.Text = ""
	clanCTLabel.ZIndex = 963
	clanCTLabel.Parent = clanPage

	local clanScroll = Instance.new("ScrollingFrame")
	clanScroll.Size = UDim2.new(1, -18, 0, QR_CONTENT_H - 58)
	clanScroll.Position = UDim2.new(0, 9, 0, 56)
	clanScroll.BackgroundTransparency = 1
	clanScroll.BorderSizePixel = 0
	clanScroll.ScrollBarThickness = 4
	clanScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 55, 140)
	clanScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	clanScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	clanScroll.ZIndex = 963
	clanScroll.Parent = clanPage

	local clanLayout = Instance.new("UIListLayout")
	clanLayout.SortOrder = Enum.SortOrder.LayoutOrder
	clanLayout.Padding = UDim.new(0, 6)
	clanLayout.Parent = clanScroll

	local clanScrollPad = Instance.new("UIPadding")
	clanScrollPad.PaddingLeft = UDim.new(0, 4)
	clanScrollPad.PaddingRight = UDim.new(0, 4)
	clanScrollPad.PaddingTop = UDim.new(0, 3)
	clanScrollPad.PaddingBottom = UDim.new(0, 3)
	clanScrollPad.Parent = clanScroll

	-- ===== PAGE 3: SUMMARY =====
	local summaryPage = Instance.new("Frame")
	summaryPage.Name = "SummaryPage"
	summaryPage.Size = UDim2.new(1, 0, 0, QR_CONTENT_H)
	summaryPage.Position = UDim2.new(0, 0, 0, QR_CONTENT_Y)
	summaryPage.BackgroundTransparency = 1
	summaryPage.ZIndex = 962
	summaryPage.Visible = false
	summaryPage.Parent = rerollWindow

	local summaryBox = Instance.new("Frame")
	summaryBox.Size = UDim2.new(1, -44, 0, 175)
	summaryBox.Position = UDim2.new(0, 22, 0, 24)
	summaryBox.BackgroundColor3 = Color3.fromRGB(18, 14, 28)
	summaryBox.BorderSizePixel = 0
	summaryBox.ZIndex = 963
	summaryBox.Parent = summaryPage
	addCorner(summaryBox, 12)
	addStroke(summaryBox, Color3.fromRGB(80, 50, 120), 1)

	local summaryBoxTitle = Instance.new("TextLabel")
	summaryBoxTitle.Size = UDim2.new(1, -28, 0, 20)
	summaryBoxTitle.Position = UDim2.new(0, 14, 0, 12)
	summaryBoxTitle.BackgroundTransparency = 1
	summaryBoxTitle.TextColor3 = Color3.fromRGB(200, 180, 255)
	summaryBoxTitle.TextSize = 11
	summaryBoxTitle.Font = Enum.Font.GothamBlack
	summaryBoxTitle.TextXAlignment = Enum.TextXAlignment.Left
	summaryBoxTitle.Text = "CONFIRM NEW LIFE"
	summaryBoxTitle.ZIndex = 964
	summaryBoxTitle.Parent = summaryBox

	local summaryCTLine = Instance.new("TextLabel")
	summaryCTLine.Size = UDim2.new(1, -28, 0, 32)
	summaryCTLine.Position = UDim2.new(0, 14, 0, 40)
	summaryCTLine.BackgroundTransparency = 1
	summaryCTLine.TextColor3 = Color3.fromRGB(235, 235, 245)
	summaryCTLine.TextSize = 16
	summaryCTLine.Font = Enum.Font.GothamBlack
	summaryCTLine.TextXAlignment = Enum.TextXAlignment.Left
	summaryCTLine.RichText = true
	summaryCTLine.Text = ""
	summaryCTLine.ZIndex = 964
	summaryCTLine.Parent = summaryBox

	local summaryClanLine = Instance.new("TextLabel")
	summaryClanLine.Size = UDim2.new(1, -28, 0, 32)
	summaryClanLine.Position = UDim2.new(0, 14, 0, 80)
	summaryClanLine.BackgroundTransparency = 1
	summaryClanLine.TextColor3 = Color3.fromRGB(235, 235, 245)
	summaryClanLine.TextSize = 16
	summaryClanLine.Font = Enum.Font.GothamBlack
	summaryClanLine.TextXAlignment = Enum.TextXAlignment.Left
	summaryClanLine.RichText = true
	summaryClanLine.Text = ""
	summaryClanLine.ZIndex = 964
	summaryClanLine.Parent = summaryBox

	local summaryNoteLine = Instance.new("TextLabel")
	summaryNoteLine.Size = UDim2.new(1, -28, 0, 36)
	summaryNoteLine.Position = UDim2.new(0, 14, 0, 126)
	summaryNoteLine.BackgroundTransparency = 1
	summaryNoteLine.TextColor3 = Color3.fromRGB(140, 130, 165)
	summaryNoteLine.TextSize = 10
	summaryNoteLine.Font = Enum.Font.GothamMedium
	summaryNoteLine.TextWrapped = true
	summaryNoteLine.TextYAlignment = Enum.TextYAlignment.Top
	summaryNoteLine.TextXAlignment = Enum.TextXAlignment.Left
	summaryNoteLine.Text = "Name and appearance will be customized in the next step."
	summaryNoteLine.ZIndex = 964
	summaryNoteLine.Parent = summaryBox

	local lastPickBadge = Instance.new("Frame")
	lastPickBadge.Size = UDim2.new(1, -44, 0, 28)
	lastPickBadge.Position = UDim2.new(0, 22, 0, 208)
	lastPickBadge.BackgroundColor3 = Color3.fromRGB(42, 32, 68)
	lastPickBadge.BorderSizePixel = 0
	lastPickBadge.Visible = false
	lastPickBadge.ZIndex = 963
	lastPickBadge.Parent = summaryPage
	addCorner(lastPickBadge, 7)
	addStroke(lastPickBadge, Color3.fromRGB(100, 70, 160), 1)

	local lastPickText = Instance.new("TextLabel")
	lastPickText.Size = UDim2.new(1, -16, 1, 0)
	lastPickText.Position = UDim2.new(0, 8, 0, 0)
	lastPickText.BackgroundTransparency = 1
	lastPickText.TextColor3 = Color3.fromRGB(180, 150, 240)
	lastPickText.TextSize = 10
	lastPickText.Font = Enum.Font.GothamBold
	lastPickText.TextXAlignment = Enum.TextXAlignment.Left
	lastPickText.Text = ""
	lastPickText.ZIndex = 964
	lastPickText.Parent = lastPickBadge

	local summaryConfirmBtn = Instance.new("TextButton")
	summaryConfirmBtn.Size = UDim2.new(0.5, -16, 0, 42)
	summaryConfirmBtn.Position = UDim2.new(0.5, 6, 0, QR_CONTENT_H - 50)
	summaryConfirmBtn.BackgroundColor3 = Color3.fromRGB(32, 96, 52)
	summaryConfirmBtn.BorderSizePixel = 0
	summaryConfirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	summaryConfirmBtn.TextSize = 13
	summaryConfirmBtn.Font = Enum.Font.GothamBlack
	summaryConfirmBtn.Text = "CONFIRM & START"
	summaryConfirmBtn.AutoButtonColor = false
	summaryConfirmBtn.ZIndex = 963
	summaryConfirmBtn.Parent = summaryPage
	addCorner(summaryConfirmBtn, 9)
	setHoverTween(summaryConfirmBtn, Color3.fromRGB(48, 138, 75))

	local summaryRePickBtn = Instance.new("TextButton")
	summaryRePickBtn.Size = UDim2.new(0.5, -16, 0, 42)
	summaryRePickBtn.Position = UDim2.new(0, 10, 0, QR_CONTENT_H - 50)
	summaryRePickBtn.BackgroundColor3 = Color3.fromRGB(32, 26, 52)
	summaryRePickBtn.BorderSizePixel = 0
	summaryRePickBtn.TextColor3 = Color3.fromRGB(200, 180, 240)
	summaryRePickBtn.TextSize = 13
	summaryRePickBtn.Font = Enum.Font.GothamBlack
	summaryRePickBtn.Text = "RE-PICK"
	summaryRePickBtn.AutoButtonColor = false
	summaryRePickBtn.ZIndex = 963
	summaryRePickBtn.Parent = summaryPage
	addCorner(summaryRePickBtn, 9)
	setHoverTween(summaryRePickBtn, Color3.fromRGB(52, 44, 84))

	-- ===== REROLL STATE & NAVIGATION =====
	local isShowingReroll = false
	local rerollBusy = false
	local rerollSelectedCT = nil
	local rerollSelectedClanId = nil
	local rerollCurrentCT = nil
	local rerollSessionToken = 0  -- incremented each open; delayed callbacks check token before acting

	local goToCTPage, goToClanPage, goToSummaryPage

	goToCTPage = function()
		ctInfoModal.Visible = false
		ctPage.Visible = true
		clanPage.Visible = false
		summaryPage.Visible = false
		rerollBreadcrumb.Text = "Step 1 of 3  —  Select Cursed Technique"
	end

	local function populateClanPage(forCT)
		for _, child in ipairs(clanScroll:GetChildren()) do
			if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
		end
		local clans = QR_CT_CLANS[forCT] or {}
		local lastClanId = lastDeathStats and lastDeathStats.LastQuickRerollClan

		local sorted = {}
		for _, clan in ipairs(clans) do table.insert(sorted, clan) end
		table.sort(sorted, function(a, b)
			if (a.Id == lastClanId) ~= (b.Id == lastClanId) then return a.Id == lastClanId end
			if a.Chance ~= b.Chance then return a.Chance < b.Chance end
			return a.DisplayName < b.DisplayName
		end)

		for i, clan in ipairs(sorted) do
			local card = Instance.new("TextButton")
			card.Name = "Clan_" .. clan.Id
			card.Size = UDim2.new(1, -8, 0, 56)
			card.BackgroundColor3 = Color3.fromRGB(18, 14, 28)
			card.BorderSizePixel = 0
			card.AutoButtonColor = false
			card.Text = ""
			card.LayoutOrder = i
			card.ZIndex = 964
			card.Parent = clanScroll
			addCorner(card, 8)
			addStroke(card, Color3.fromRGB(55, 40, 80), 1)
			setHoverTween(card, Color3.fromRGB(30, 24, 46))

			local nameL = Instance.new("TextLabel")
			nameL.Size = UDim2.new(1, -170, 0, 24)
			nameL.Position = UDim2.new(0, 12, 0, 7)
			nameL.BackgroundTransparency = 1
			nameL.TextColor3 = Color3.fromRGB(235, 235, 245)
			nameL.TextSize = 13
			nameL.Font = Enum.Font.GothamBlack
			nameL.TextXAlignment = Enum.TextXAlignment.Left
			nameL.Text = clan.DisplayName
			nameL.ZIndex = 965
			nameL.Parent = card

			local rarity, rarityColor = getQRClanRarity(clan.Chance)
			local pct = string.format("%.2f%%", QR_TOTAL_CHANCE > 0 and (clan.Chance / QR_TOTAL_CHANCE) * 100 or 0)
			local rarityL = Instance.new("TextLabel")
			rarityL.Size = UDim2.new(1, -170, 0, 16)
			rarityL.Position = UDim2.new(0, 12, 0, 32)
			rarityL.BackgroundTransparency = 1
			rarityL.TextColor3 = rarityColor
			rarityL.TextSize = 9
			rarityL.Font = Enum.Font.GothamBold
			rarityL.TextXAlignment = Enum.TextXAlignment.Left
			rarityL.Text = rarity .. "  " .. pct
			rarityL.ZIndex = 965
			rarityL.Parent = card

			if clan.Id == lastClanId then
				local badge = Instance.new("TextLabel")
				badge.Size = UDim2.new(0, 78, 0, 20)
				badge.Position = UDim2.new(1, -92, 0.5, -10)
				badge.BackgroundColor3 = Color3.fromRGB(55, 40, 90)
				badge.BorderSizePixel = 0
				badge.TextColor3 = Color3.fromRGB(200, 170, 255)
				badge.TextSize = 9
				badge.Font = Enum.Font.GothamBlack
				badge.TextXAlignment = Enum.TextXAlignment.Center
				badge.Text = "LAST PICK"
				badge.ZIndex = 966
				badge.Parent = card
				addCorner(badge, 5)
			end

			card.MouseButton1Click:Connect(function()
				goToSummaryPage(forCT, clan.Id, clan.DisplayName)
			end)
		end
	end

	goToClanPage = function(ctName)
		rerollCurrentCT = ctName
		populateClanPage(ctName)
		clanCTLabel.Text = "CT selected: " .. ctName .. "  —  " .. #(QR_CT_CLANS[ctName] or {}) .. " origin(s) available"
		ctPage.Visible = false
		clanPage.Visible = true
		summaryPage.Visible = false
		rerollBreadcrumb.Text = "Step 2 of 3  —  Select Clan  (" .. ctName .. ")"
	end

	goToSummaryPage = function(ctName, clanId, clanDisplayName)
		rerollSelectedCT = ctName
		rerollSelectedClanId = clanId
		local ctColor = QR_CT_COLORS[ctName] or QR_DEFAULT_COLOR
		local hex = string.format("%02x%02x%02x",
			math.floor(ctColor.R * 255), math.floor(ctColor.G * 255), math.floor(ctColor.B * 255))
		summaryCTLine.Text   = string.format('Technique:  <b><font color="#%s">%s</font></b>', hex, ctName)
		summaryClanLine.Text = string.format('Origin:  <b>%s</b>', clanDisplayName)
		local lastClan = lastDeathStats and lastDeathStats.LastQuickRerollClan
		local lastCT   = lastDeathStats and lastDeathStats.LastQuickRerollCT
		if lastClan == clanId and lastCT == ctName then
			lastPickText.Text = "★  Same combination as your last Quick Reroll"
			lastPickBadge.Visible = true
		else
			lastPickBadge.Visible = false
		end
		ctPage.Visible = false
		clanPage.Visible = false
		summaryPage.Visible = true
		rerollBreadcrumb.Text = "Step 3 of 3  —  Confirm"
	end

	local function showReroll()
		if isShowingReroll then return end
		isShowingReroll = true
		rerollBusy = false
		rerollSessionToken = rerollSessionToken + 1
		summaryConfirmBtn.Text = "CONFIRM & START"
		summaryConfirmBtn.Active = true
		goToCTPage()
		rerollOverlay.Visible = true
		rerollWindow.Visible = true
		rerollOverlay.BackgroundTransparency = 1
		rerollWindow.BackgroundTransparency = 1
		rerollWindow.Position = UDim2.new(0.5, 0, 0.56, 0)
		TweenService:Create(rerollOverlay, TweenInfo.new(0.22), { BackgroundTransparency = 0.5 }):Play()
		TweenService:Create(rerollWindow, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0,
			Position = UDim2.new(0.5, 0, 0.5, 0),
		}):Play()
	end

	local function hideReroll()
		if not isShowingReroll then return end
		isShowingReroll = false
		ctInfoModal.Visible = false
		TweenService:Create(rerollOverlay, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
		local t = TweenService:Create(rerollWindow, TweenInfo.new(0.18), {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.56, 0),
		})
		t:Play()
		t.Completed:Wait()
		if not isShowingReroll then
			rerollWindow.Visible = false
			rerollOverlay.Visible = false
		end
	end

	-- Populate CT cells (done once at init)
	for i, ctName in ipairs(QR_CT_NAMES) do
		local cell = Instance.new("TextButton")
		cell.Name = "CT_" .. i
		cell.BackgroundColor3 = Color3.fromRGB(18, 14, 28)
		cell.BorderSizePixel = 0
		cell.AutoButtonColor = false
		cell.Text = ""
		cell.LayoutOrder = i
		cell.ZIndex = 964
		cell.Parent = ctScroll
		addCorner(cell, 8)
		addStroke(cell, Color3.fromRGB(55, 40, 80), 1)
		setHoverTween(cell, Color3.fromRGB(30, 24, 46))

		local accent = Instance.new("Frame")
		accent.Size = UDim2.new(0, 3, 1, -14)
		accent.Position = UDim2.new(0, 6, 0, 7)
		accent.BackgroundColor3 = QR_CT_COLORS[ctName] or QR_DEFAULT_COLOR
		accent.BorderSizePixel = 0
		accent.ZIndex = 965
		accent.Parent = cell
		addCorner(accent, 2)

		local nameL = Instance.new("TextLabel")
		nameL.Size = UDim2.new(1, -44, 0, 22)
		nameL.Position = UDim2.new(0, 16, 0, 5)
		nameL.BackgroundTransparency = 1
		nameL.TextColor3 = Color3.fromRGB(235, 235, 245)
		nameL.TextSize = 11
		nameL.Font = Enum.Font.GothamBlack
		nameL.TextXAlignment = Enum.TextXAlignment.Left
		nameL.TextWrapped = true
		nameL.Text = ctName
		nameL.ZIndex = 965
		nameL.Parent = cell

		local rarity, rarityColor = getQRCTRarity(ctName)
		local prob = (QR_CT_PROB[ctName] or 0) * 100
		local rarityL = Instance.new("TextLabel")
		rarityL.Size = UDim2.new(1, -16, 0, 14)
		rarityL.Position = UDim2.new(0, 16, 0, 28)
		rarityL.BackgroundTransparency = 1
		rarityL.TextColor3 = rarityColor
		rarityL.TextSize = 8
		rarityL.Font = Enum.Font.GothamBold
		rarityL.TextXAlignment = Enum.TextXAlignment.Left
		rarityL.Text = rarity .. "  " .. string.format("%.2f%%", prob)
		rarityL.ZIndex = 965
		rarityL.Parent = cell

		local descL = Instance.new("TextLabel")
		descL.Size = UDim2.new(1, -20, 0, 26)
		descL.Position = UDim2.new(0, 16, 0, 46)
		descL.BackgroundTransparency = 1
		descL.TextColor3 = Color3.fromRGB(160, 155, 185)
		descL.TextSize = 9
		descL.Font = Enum.Font.GothamMedium
		descL.TextXAlignment = Enum.TextXAlignment.Left
		descL.TextYAlignment = Enum.TextYAlignment.Top
		descL.TextWrapped = true
		descL.Text = QR_CT_DESCS[ctName] or "Clan-exclusive technique."
		descL.ZIndex = 965
		descL.Parent = cell

		local infoBtn = Instance.new("TextButton")
		infoBtn.Size = UDim2.new(0, 20, 0, 20)
		infoBtn.Position = UDim2.new(1, -26, 0, 5)
		infoBtn.BackgroundColor3 = Color3.fromRGB(28, 20, 46)
		infoBtn.BorderSizePixel = 0
		infoBtn.TextColor3 = Color3.fromRGB(155, 115, 215)
		infoBtn.TextSize = 11
		infoBtn.Font = Enum.Font.GothamBlack
		infoBtn.Text = "?"
		infoBtn.AutoButtonColor = false
		infoBtn.ZIndex = 966
		infoBtn.Parent = cell
		addCorner(infoBtn, 4)

		local capturedCT = ctName
		infoBtn.MouseButton1Click:Connect(function()
			openCTInfoModal(capturedCT)
		end)
		cell.MouseButton1Click:Connect(function()
			if ctInfoModal.Visible then return end
			goToClanPage(capturedCT)
		end)
	end

	-- Reroll button connections
	rerollClose.MouseButton1Click:Connect(function()
		hideReroll()
	end)
	clanBackBtn.MouseButton1Click:Connect(function()
		goToCTPage()
	end)
	clanRandomBtn.MouseButton1Click:Connect(function()
		local clans = QR_CT_CLANS[rerollCurrentCT] or {}
		if #clans > 0 then
			local picked = clans[math.random(1, #clans)]
			goToSummaryPage(rerollCurrentCT, picked.Id, picked.DisplayName)
		end
	end)
	ctRandomBtn.MouseButton1Click:Connect(function()
		if #QR_CT_NAMES > 0 then
			goToClanPage(QR_CT_NAMES[math.random(1, #QR_CT_NAMES)])
		end
	end)
	ctRandomEverythingBtn.MouseButton1Click:Connect(function()
		updateLifeEvent:FireServer("StartNewLife")
		local tok = rerollSessionToken
		task.delay(0.25, function()
			if rerollSessionToken ~= tok then return end
			hideReroll()
			hideDeathScreen()
		end)
	end)
	summaryRePickBtn.MouseButton1Click:Connect(function()
		goToCTPage()
	end)
	summaryConfirmBtn.MouseButton1Click:Connect(function()
		if rerollBusy then return end
		rerollBusy = true
		summaryConfirmBtn.Text = "STARTING..."
		summaryConfirmBtn.Active = false
		updateLifeEvent:FireServer("StartNewLife", {
			PreferredOriginId = rerollSelectedClanId,
			PreferredCT       = rerollSelectedCT,
		})
		local tok = rerollSessionToken
		task.delay(0.35, function()
			if rerollSessionToken ~= tok then return end
			hideReroll()
			hideDeathScreen()
		end)
	end)
	quickRerollButton.MouseButton1Click:Connect(function()
		showReroll()
	end)

	-- State
	local isShowingDeath = false
	local isShowingPicker = false
	local pickerBusy = false

	local function getViewport()
		local camera = workspace.CurrentCamera
		return camera and camera.ViewportSize or Vector2.new(1280, 720)
	end

	local function isDeathMobile()
		local viewport = getViewport()
		return viewport.X < 720 or viewport.Y < 620 or UserInputService.TouchEnabled
	end

	local function getRibbon(stats)
		local age = tonumber(stats.Age) or 0
		local grade = tostring(stats.Grade or "")
		local rep = tonumber(stats.Reputation) or 0
		local missions = tonumber(stats.MissionsCompleted) or 0
		local isCurseUser = stats.IsCurseUser == true or stats.Path == "Curse User" or stats.Alignment == "Curse User"
		local isCurseLife = tostring(stats.World or "") == "Cursed Spirit" or tostring(stats.Lineage or ""):find("Cursed")
		local hasSpecialGrade = grade == "Special Grade"
		local hasDomain = stats.DomainExpansion and stats.DomainExpansion ~= "None" and stats.DomainExpansion ~= ""
		local hasRCT = stats.RCT == true or stats.HasRCT == true
		local generation = tonumber(stats.Generation) or 1
		local founded = stats.ClanFounded == true

		if hasSpecialGrade and hasDomain and age >= 50 then
			return "🏆 LEGEND OF THE CURSED WORLD", Color3.fromRGB(255, 200, 50)
		elseif hasSpecialGrade and hasDomain then
			return "👑 SPECIAL GRADE SORCERER", Color3.fromRGB(220, 160, 255)
		elseif isCurseUser and grade == "Special Grade" then
			return "☠️ CURSE USER KING", Color3.fromRGB(200, 60, 80)
		elseif isCurseUser and rep < -50 then
			return "💀 FEARED CURSE USER", Color3.fromRGB(180, 40, 60)
		elseif isCurseUser then
			return "🩸 CURSE USER", Color3.fromRGB(200, 80, 90)
		elseif isCurseLife then
			return "👁 CURSED SPIRIT", Color3.fromRGB(140, 80, 200)
		elseif hasRCT and hasDomain then
			return "⚡ ELITE JUJUTSU SORCERER", Color3.fromRGB(120, 200, 255)
		elseif hasDomain then
			return "🌀 DOMAIN USER", Color3.fromRGB(140, 120, 255)
		elseif hasRCT then
			return "✨ RCT PRACTITIONER", Color3.fromRGB(100, 220, 180)
		elseif founded then
			return "🏯 CLAN FOUNDER", Color3.fromRGB(255, 180, 60)
		elseif generation >= 5 then
			return "🔱 DEEP BLOODLINE", Color3.fromRGB(180, 140, 255)
		elseif missions >= 100 then
			return "⚔️ VETERAN SORCERER", Color3.fromRGB(120, 200, 140)
		elseif grade == "Grade 1" or grade == "Semi-Grade 1" then
			return "🎖 GRADE 1 SORCERER", Color3.fromRGB(100, 180, 255)
		elseif age >= 80 then
			return "🕰 LONG LIFE", Color3.fromRGB(160, 160, 180)
		elseif age <= 18 then
			return "🌱 LIFE CUT SHORT", Color3.fromRGB(180, 180, 200)
		elseif rep >= 100 then
			return "🌟 CELEBRATED SORCERER", Color3.fromRGB(255, 220, 80)
		else
			return "📜 ORDINARY LIFE", Color3.fromRGB(140, 140, 160)
		end
	end

	local function buildBiography(stats)
		local name = tostring(stats.Name or "Unknown")
		local age = tostring(stats.Age or 0)
		local grade = tostring(stats.Grade or "Unknown")
		local technique = tostring(stats.CursedTechnique or "None")
		local family = tostring(stats.FamilyName or "Unknown")
		local origin = tostring(stats.Origin or stats.Clan or "Unknown")
		local missionsCompleted = tostring(stats.MissionsCompleted or 0)
		local reputation = tostring(stats.Reputation or 0)
		local generation = tostring(stats.Generation or 1)

		local clanLine = ""
		if stats.ClanFounded then
			clanLine = "\n\nThey founded the <b>" .. tostring(stats.PlayerClanName or "Unnamed Clan") .. "</b>, leaving behind a name that other sorcerers would remember."
		end

		local techniqueLine = ""
		if technique ~= "None" then
			techniqueLine = " They awakened <b>" .. technique .. "</b>, carrying that technique through the cursed world."
		else
			techniqueLine = " They never awakened a recognized cursed technique, but still lived through the pressure of the cursed world."
		end

		local generationLine = ""
		if stats.Generation and stats.Generation > 1 then
			generationLine = "\n\nThey were the <b>" .. generation .. getOrdinalSuffix(stats.Generation) .. " generation</b> of the bloodline."
		end

		return "<b>" .. name .. "</b> of the <b>" .. family .. " Family</b> lived for <b>" .. age .. " years</b>.\n\n" ..
			"They were born from <b>" .. origin .. "</b> and reached the rank of <b>" .. grade .. "</b>." ..
			techniqueLine ..
			"\n\nAcross their life, they completed <b>" .. missionsCompleted .. "</b> confirmed missions and built a reputation of <b>" .. reputation .. "</b>." ..
			clanLine ..
			generationLine
	end

	local function clearPickerCards()
		for _, child in ipairs(pickerScroll:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
	end

	local function createEmptyPickerCard(text)
		local card = Instance.new("Frame")
		card.Name = "EmptyCard"
		card.Size = UDim2.new(1, -8, 0, 110)
		card.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		card.BorderSizePixel = 0
		card.ZIndex = 953
		card.Parent = pickerScroll
		addCorner(card, 10)
		addStroke(card, Color3.fromRGB(60, 45, 90), 1)

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -40, 1, 0)
		label.Position = UDim2.new(0, 20, 0, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(190, 180, 220)
		label.TextSize = 14
		label.Font = Enum.Font.GothamBold
		label.TextWrapped = true
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Text = text
		label.ZIndex = 954
		label.Parent = card
	end

	local function createSuccessorCard(successor)
		local mobile = isDeathMobile()
		local card = Instance.new("Frame")
		card.Name = "SuccessorCard"
		card.Size = mobile and UDim2.new(1, -8, 0, 174) or UDim2.new(1, -8, 0, 130)
		card.BackgroundColor3 = Color3.fromRGB(22, 20, 35)
		card.BorderSizePixel = 0
		card.ZIndex = 953
		card.Parent = pickerScroll
		addCorner(card, 10)
		addStroke(card, Color3.fromRGB(75, 55, 120), 1)

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = mobile and UDim2.new(1, -32, 0, 26) or UDim2.new(1, -180, 0, 28)
		nameLabel.Position = UDim2.new(0, mobile and 16 or 20, 0, 14)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = Color3.fromRGB(235, 235, 245)
		nameLabel.TextSize = mobile and 15 or 17
		nameLabel.Font = Enum.Font.GothamBlack
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Text = tostring(successor.Name or "Unknown Child")
		nameLabel.ZIndex = 954
		nameLabel.Parent = card

		local ageLabel = Instance.new("TextLabel")
		ageLabel.Size = mobile and UDim2.new(1, -32, 0, 18) or UDim2.new(1, -180, 0, 18)
		ageLabel.Position = UDim2.new(0, mobile and 16 or 20, 0, 42)
		ageLabel.BackgroundTransparency = 1
		ageLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
		ageLabel.TextSize = 12
		ageLabel.Font = Enum.Font.GothamBold
		ageLabel.TextXAlignment = Enum.TextXAlignment.Left
		ageLabel.Text = "Age: " .. tostring(successor.Age or 0)
		ageLabel.ZIndex = 954
		ageLabel.Parent = card

		local ceLabel = Instance.new("TextLabel")
		ceLabel.Size = mobile and UDim2.new(1, -32, 0, 18) or UDim2.new(1, -180, 0, 18)
		ceLabel.Position = UDim2.new(0, mobile and 16 or 20, 0, 62)
		ceLabel.BackgroundTransparency = 1
		ceLabel.TextColor3 = Color3.fromRGB(180, 150, 240)
		ceLabel.TextSize = 12
		ceLabel.Font = Enum.Font.GothamBold
		ceLabel.TextXAlignment = Enum.TextXAlignment.Left
		ceLabel.Text = "Cursed Energy: " .. tostring(successor.CursedEnergy or 0)
		ceLabel.ZIndex = 954
		ceLabel.Parent = card

		local techLabel = Instance.new("TextLabel")
		techLabel.Size = mobile and UDim2.new(1, -32, 0, 44) or UDim2.new(1, -180, 0, 32)
		techLabel.Position = UDim2.new(0, mobile and 16 or 20, 0, 82)
		techLabel.BackgroundTransparency = 1

		if successor.HasInheritedTechnique then
			techLabel.TextColor3 = Color3.fromRGB(255, 200, 90)
			techLabel.Text = "Inherited Technique: <b>" .. tostring(successor.CursedTechnique) .. "</b>\nThey will start as a sorcerer."
		else
			techLabel.TextColor3 = Color3.fromRGB(150, 150, 165)
			techLabel.Text = "No technique inherited yet.\nTheir cursed energy may still awaken."
		end

		techLabel.TextSize = 11
		techLabel.Font = Enum.Font.GothamMedium
		techLabel.TextWrapped = true
		techLabel.RichText = true
		techLabel.TextXAlignment = Enum.TextXAlignment.Left
		techLabel.TextYAlignment = Enum.TextYAlignment.Top
		techLabel.ZIndex = 954
		techLabel.Parent = card

		local chooseButton = Instance.new("TextButton")
		chooseButton.Size = mobile and UDim2.new(1, -32, 0, 40) or UDim2.new(0, 140, 0, 50)
		chooseButton.Position = mobile and UDim2.new(0, 16, 1, -52) or UDim2.new(1, -160, 0.5, -25)
		chooseButton.BackgroundColor3 = Color3.fromRGB(95, 55, 150)
		chooseButton.BorderSizePixel = 0
		chooseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		chooseButton.TextSize = mobile and 12 or 13
		chooseButton.Font = Enum.Font.GothamBlack
		chooseButton.Text = _d("continue_as", "CONTINUE AS")
		chooseButton.AutoButtonColor = false
		chooseButton.ZIndex = 955
		chooseButton.Parent = card
		addCorner(chooseButton, 8)
		setHoverTween(chooseButton, Color3.fromRGB(125, 75, 190))

		chooseButton.MouseButton1Click:Connect(function()
			if pickerBusy then
				return
			end
			pickerBusy = true
			chooseButton.Text = _d("starting", "STARTING...")
			chooseSuccessor:FireServer(successor.Id)
		end)
	end

	local function getRCTReviveUses(stats)
		if typeof(stats) ~= "table" then
			return 0
		end
		return math.max(0, tonumber(stats.RCTRevives) or 0)
	end

	local function updateRCTReviveButtonForStats(stats)
		local uses = getRCTReviveUses(stats)
		local remaining = math.max(0, RCT_REVIVE_MAX_PER_LIFE - uses)

		if remaining <= 0 then
			rctReviveButton.Text = _d("rct_limit_reached", "RCT REVIVE LIMIT REACHED")
			rctReviveButton.Active = false
			rctReviveButton.BackgroundColor3 = RCT_REVIVE_LOCKED_COLOR
			rctReviveDesc.TextColor3 = Color3.fromRGB(155, 155, 170)
			rctReviveDesc.Text = "Your body has already survived through RCT twice in this life."
		else
			rctReviveButton.Text = _d("rct_left", "RCT REVIVE - R$50  ({remaining}/{max} LEFT)"):gsub("{remaining}", tostring(remaining)):gsub("{max}", tostring(RCT_REVIVE_MAX_PER_LIFE))
			rctReviveButton.Active = true
			rctReviveButton.BackgroundColor3 = RCT_REVIVE_READY_COLOR
			rctReviveDesc.TextColor3 = Color3.fromRGB(190, 175, 255)
			rctReviveDesc.Text = "Reverse cursed energy pulls you back. Can be used twice per life."
		end
	end

	local function canShowReincarnation(stats)
		if typeof(stats) ~= "table" then
			return false
		end
		local ce = tonumber(stats.CursedEnergy) or 0
		local anchors = tonumber(stats.CursedObjectAnchors) or 0
		local anchorProgress = tonumber(stats.CursedObjectAnchorProgress) or 0
		return ce >= 120 and (anchors >= 1 or anchorProgress >= 75)
	end

	local function canShowCurseRebirth(stats)
		if typeof(stats) ~= "table" then
			return false
		end
		if stats.IsCurse == true or tostring(stats.Race or "") == "Curse" then
			return false
		end
		return stats.CurseRebirthEligible == true
			or (tonumber(stats.CursedResentment) or 0) >= 100
			or (tonumber(stats.CursedObjectAnchors) or 0) >= 1
			or tostring(stats.ReincarnationAnchor or "None") ~= "None"
	end

	local function showDeathScreen(stats)
		if isShowingDeath then
			return
		end

		isShowingDeath = true
		lastDeathStats = stats
		if _G.BitKaisenPlaySFX then _G.BitKaisenPlaySFX("Death") end
		updateRCTReviveButtonForStats(stats)

		biographyText.Text = buildBiography(stats)

		local cause = tostring(stats.CauseOfDeath or stats.DeathReason or "")
		causeLabel.Text = cause ~= "" and ("Cause of death: " .. cause) or ""
		causeLabel.Visible = cause ~= ""

		local ribbonText, ribbonColor = getRibbon(stats)
		local karma = tonumber(stats.HiddenKarma) or 0
		local karmaLabel = ""
		if karma >= 60 then
			karmaLabel = "  ✦ The cursed world remembers your light."
		elseif karma >= 20 then
			karmaLabel = "  ✦ You left the world a little better."
		elseif karma <= -60 then
			karmaLabel = "  ✦ Darkness followed you everywhere."
		elseif karma <= -20 then
			karmaLabel = "  ✦ The weight of your choices lingered."
		end
		ribbonLabel.Text = ribbonText .. (karmaLabel ~= "" and ("\n" .. karmaLabel) or "")
		ribbonLabel.TextColor3 = ribbonColor

		statsText.Text =
			"Age " .. tostring(stats.Age or 0) ..
			"  •  Grade: " .. tostring(stats.Grade or "Unknown") ..
			"  •  CE: " .. tostring(stats.CursedEnergy or 0) ..
			"  •  Resentment: " .. tostring(stats.CursedResentment or 0) ..
			"  •  Money: $" .. formatMoneyAmount(stats.Money or 0)

		local reincarnationUnlocked = canShowReincarnation(stats)
		local curseUnlocked = canShowCurseRebirth(stats) and not reincarnationUnlocked
		reincarnateButton.Visible = reincarnationUnlocked
		reincarnateDesc.Visible = reincarnationUnlocked
		curseRebirthButton.Visible = curseUnlocked
		curseRebirthDesc.Visible = curseUnlocked

		overlay.Visible = true
		window.Visible = true

		overlay.BackgroundTransparency = 1
		window.BackgroundTransparency = 1
		window.Position = UDim2.new(0.5, 0, 0.56, 0)

		TweenService:Create(overlay, TweenInfo.new(0.25), {
			BackgroundTransparency = 0.55
		}):Play()

		TweenService:Create(window, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0,
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}):Play()
	end

	hideDeathScreen = function()
		isShowingDeath = false

		TweenService:Create(overlay, TweenInfo.new(0.18), {
			BackgroundTransparency = 1
		}):Play()

		local tween = TweenService:Create(window, TweenInfo.new(0.18), {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.56, 0)
		})

		tween:Play()
		tween.Completed:Wait()

		window.Visible = false
		overlay.Visible = false
	end

	local function showPicker()
		if isShowingPicker then
			return
		end

		isShowingPicker = true
		pickerBusy = false

		clearPickerCards()

		local ok, successors = pcall(function()
			return getSuccessorOptions:InvokeServer()
		end)

		if not ok then
			createEmptyPickerCard("Could not load successor options.\nTry again.")
		elseif typeof(successors) ~= "table" or #successors <= 0 then
			createEmptyPickerCard("You have no eligible children to continue your bloodline.\nStart a new life instead.")
		else
			for _, successor in ipairs(successors) do
				createSuccessorCard(successor)
			end
		end

		pickerOverlay.Visible = true
		pickerWindow.Visible = true
		pickerOverlay.BackgroundTransparency = 1
		pickerWindow.BackgroundTransparency = 1
		pickerWindow.Position = UDim2.new(0.5, 0, 0.56, 0)

		TweenService:Create(pickerOverlay, TweenInfo.new(0.22), {
			BackgroundTransparency = 0.5
		}):Play()

		TweenService:Create(pickerWindow, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0,
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}):Play()
	end

	local function hidePicker()
		if not isShowingPicker then
			return
		end

		isShowingPicker = false

		TweenService:Create(pickerOverlay, TweenInfo.new(0.18), {
			BackgroundTransparency = 1
		}):Play()

		local tween = TweenService:Create(pickerWindow, TweenInfo.new(0.18), {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.56, 0)
		})

		tween:Play()
		tween.Completed:Wait()

		pickerWindow.Visible = false
		pickerOverlay.Visible = false
	end

	-- Button connections
	newLifeButton.MouseButton1Click:Connect(function()
		newLifeButton.Text = _d("starting", "STARTING...")
		updateLifeEvent:FireServer("StartNewLife")

		task.delay(0.25, function()
			hideDeathScreen()
			newLifeButton.Text = _d("start_new_life", "START NEW LIFE")
		end)
	end)

	rctReviveButton.MouseButton1Click:Connect(function()
		if getRCTReviveUses(lastDeathStats) >= RCT_REVIVE_MAX_PER_LIFE then
			updateRCTReviveButtonForStats(lastDeathStats)
			return
		end

		rctReviveButton.Text = "OPENING PURCHASE..."
		rctReviveButton.Active = false

		if game.PlaceId == TEST_PURCHASE_PLACE_ID then
			testPurchase:FireServer("DeveloperProduct", RCT_REVIVE_PRODUCT_ID)
		else
			MarketplaceService:PromptProductPurchase(player, RCT_REVIVE_PRODUCT_ID)
		end

		task.delay(1.25, function()
			if rctReviveButton and rctReviveButton.Parent then
				updateRCTReviveButtonForStats(lastDeathStats)
			end
		end)
	end)

	curseRebirthButton.MouseButton1Click:Connect(function()
		curseRebirthButton.Text = _d("rebirthing", "REBIRTHING...")
		updateLifeEvent:FireServer("BecomeVengefulSpirit")

		task.delay(0.45, function()
			curseRebirthButton.Text = _d("become_spirit", "BECOME VENGEFUL SPIRIT")
		end)
	end)

	reincarnateButton.MouseButton1Click:Connect(function()
		reincarnateButton.Text = _d("reincarnating", "REINCARNATING...")
		updateLifeEvent:FireServer("Reincarnate")

		task.delay(0.45, function()
			reincarnateButton.Text = _d("reincarnate", "REINCARNATE")
		end)
	end)

	successorButton.MouseButton1Click:Connect(function()
		showPicker()
	end)

	pickerClose.MouseButton1Click:Connect(function()
		hidePicker()
	end)

	-- Listen for death/alive events
	updateLifeEvent.OnClientEvent:Connect(function(stats, message)
		if typeof(stats) ~= "table" then
			return
		end

		if stats.Alive == false then
			task.defer(function()
				if isShowingPicker then
					hidePicker()
				end
				showDeathScreen(stats)
			end)
		else
			if isShowingDeath then
				task.defer(function()
					hideDeathScreen()
				end)
			end

			if isShowingPicker then
				task.defer(function()
					hidePicker()
				end)
			end
		end
	end)
end

return { init = init }
