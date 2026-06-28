local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")

local responsiveScale = require("@ui/responsiveScale")

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
	window.Size = UDim2.new(0, 640, 0, 610)
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
	responsiveScale.attach(window, 640, 610)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 0, 50)
	title.Position = UDim2.new(0, 20, 0, 18)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 30
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Text = "LIFE ENDED"
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

	local biographyBox = Instance.new("Frame")
	biographyBox.Name = "BiographyBox"
	biographyBox.Size = UDim2.new(1, -70, 0, 175)
	biographyBox.Position = UDim2.new(0, 35, 0, 105)
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
	statsText.Position = UDim2.new(0, 35, 0, 290)
	statsText.BackgroundTransparency = 1
	statsText.TextColor3 = Color3.fromRGB(170, 170, 190)
	statsText.TextSize = 12
	statsText.Font = Enum.Font.GothamBold
	statsText.TextXAlignment = Enum.TextXAlignment.Center
	statsText.Text = ""
	statsText.ZIndex = 902
	statsText.Parent = window

	local buttonsHolder = Instance.new("Frame")
	buttonsHolder.Name = "ButtonsHolder"
	buttonsHolder.Size = UDim2.new(1, -70, 0, 260)
	buttonsHolder.Position = UDim2.new(0, 35, 0, 330)
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
	newLifeButton.Text = "START NEW LIFE"
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
	successorButton.Text = "PLAY AS CHILD"
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
	rctReviveButton.Text = "RCT REVIVE — R$50"
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
	curseRebirthButton.Text = "BECOME VENGEFUL SPIRIT"
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
	reincarnateButton.Text = "REINCARNATE"
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
	pickerTitle.Text = "CHOOSE YOUR SUCCESSOR"
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

	-- State
	local isShowingDeath = false
	local isShowingPicker = false
	local pickerBusy = false
	local lastDeathStats = nil

	local function getViewport()
		local camera = workspace.CurrentCamera
		return camera and camera.ViewportSize or Vector2.new(1280, 720)
	end

	local function isDeathMobile()
		local viewport = getViewport()
		return viewport.X < 720 or viewport.Y < 620 or UserInputService.TouchEnabled
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
		chooseButton.Text = "CONTINUE AS"
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
			chooseButton.Text = "STARTING..."
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
			rctReviveButton.Text = "RCT REVIVE LIMIT REACHED"
			rctReviveButton.Active = false
			rctReviveButton.BackgroundColor3 = RCT_REVIVE_LOCKED_COLOR
			rctReviveDesc.TextColor3 = Color3.fromRGB(155, 155, 170)
			rctReviveDesc.Text = "Your body has already survived through RCT twice in this life."
		else
			rctReviveButton.Text = "RCT REVIVE — R$50  (" .. tostring(remaining) .. "/" .. tostring(RCT_REVIVE_MAX_PER_LIFE) .. " LEFT)"
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

	local function hideDeathScreen()
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
		newLifeButton.Text = "STARTING..."
		updateLifeEvent:FireServer("StartNewLife")

		task.delay(0.25, function()
			hideDeathScreen()
			newLifeButton.Text = "START NEW LIFE"
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
		curseRebirthButton.Text = "REBIRTHING..."
		updateLifeEvent:FireServer("BecomeVengefulSpirit")

		task.delay(0.45, function()
			curseRebirthButton.Text = "BECOME VENGEFUL SPIRIT"
		end)
	end)

	reincarnateButton.MouseButton1Click:Connect(function()
		reincarnateButton.Text = "REINCARNATING..."
		updateLifeEvent:FireServer("Reincarnate")

		task.delay(0.45, function()
			reincarnateButton.Text = "REINCARNATE"
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
