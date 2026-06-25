local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TWEEN_HOVER = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local BG = Color3.fromRGB(7, 7, 10)
local CARD = Color3.fromRGB(20, 20, 30)
local CARD_HOVER = Color3.fromRGB(28, 28, 38)
local STROKE = Color3.fromRGB(48, 48, 64)
local TEXT = Color3.fromRGB(245, 243, 252)
local SUBTEXT = Color3.fromRGB(165, 165, 185)
local PURPLE = Color3.fromRGB(178, 122, 255)
local BLUE = Color3.fromRGB(120, 190, 255)
local GOLD = Color3.fromRGB(255, 207, 105)

local function isNarrow(): boolean
	local cam = workspace.CurrentCamera
	if not cam then return false end
	local vp = cam.ViewportSize
	return vp.X < 700 or vp.Y > vp.X
end

local function prompt(): string
	local picked: string? = nil
	local doneEvent = Instance.new("BindableEvent")

	local isTouchDevice = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
	local recommended = if isTouchDevice or isNarrow() then "Mobile" else "Computer"

	local gui = Instance.new("ScreenGui")
	gui.Name = "BitKaisenModeSelect"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 5000
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = BG
	bg.BorderSizePixel = 0
	bg.Parent = gui

	local narrow = isNarrow()

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Position = UDim2.new(0, 0, 0, narrow and 40 or 60)
	title.BackgroundTransparency = 1
	title.Text = "CHOOSE YOUR EXPERIENCE"
	title.TextColor3 = GOLD
	title.TextSize = narrow and 20 or 28
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.ZIndex = 2
	title.Parent = bg

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(0.8, 0, 0, 36)
	subtitle.AnchorPoint = Vector2.new(0.5, 0)
	subtitle.Position = UDim2.new(0.5, 0, 0, narrow and 70 or 120)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "You can change this anytime in Settings."
	subtitle.TextColor3 = SUBTEXT
	subtitle.TextSize = narrow and 13 or 15
	subtitle.Font = Enum.Font.GothamMedium
	subtitle.TextXAlignment = Enum.TextXAlignment.Center
	subtitle.ZIndex = 2
	subtitle.Parent = bg

	local cardContainer = Instance.new("Frame")
	cardContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	cardContainer.Position = UDim2.fromScale(0.5, narrow and 0.55 or 0.52)
	cardContainer.BackgroundTransparency = 1
	cardContainer.ZIndex = 2
	cardContainer.Parent = bg

	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = cardContainer

	local cards: { [string]: { button: TextButton, stroke: UIStroke } } = {}
	local allElements: { { obj: GuiObject, prop: string, narrow: any, wide: any } } = {}

	local function applyLayout()
		local n = isNarrow()
		local cam = workspace.CurrentCamera
		local vpX = if cam then cam.ViewportSize.X else 1920
		local vpY = if cam then cam.ViewportSize.Y else 1080

		if n then
			layout.FillDirection = Enum.FillDirection.Vertical
			layout.Padding = UDim.new(0, 16)
			local cardW = math.clamp(vpX - 40, 200, 400)
			local cardH = math.clamp(math.floor(vpY * 0.28), 140, 260)
			cardContainer.Size = UDim2.new(0, cardW + 40, 0, cardH * 2 + 56)
			for _, info in cards do
				info.button.Size = UDim2.new(0, cardW, 0, cardH)
			end
		else
			layout.FillDirection = Enum.FillDirection.Horizontal
			layout.Padding = UDim.new(0, 24)
			cardContainer.Size = UDim2.new(0.9, 0, 0, 340)
			for _, info in cards do
				info.button.Size = UDim2.new(0, 300, 0, 320)
			end
		end

		title.TextSize = n and 20 or 28
		title.Position = UDim2.new(0, 0, 0, n and 40 or 60)
		subtitle.TextSize = n and 13 or 15
		subtitle.Position = UDim2.new(0.5, 0, 0, n and 70 or 120)
		cardContainer.Position = UDim2.fromScale(0.5, n and 0.55 or 0.52)

		for _, elem in allElements do
			elem.obj[elem.prop] = if n then elem.narrow else elem.wide
		end
	end

	local function makeCard(mode: string, icon: string, label: string, desc: string, accent: Color3)
		local isRec = (mode == recommended)

		local card = Instance.new("TextButton")
		card.Name = mode
		card.Size = UDim2.new(0, if narrow then math.clamp((workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1920) - 40, 200, 400) else 300, 0, if narrow then 200 else 320)
		card.BackgroundColor3 = CARD
		card.BorderSizePixel = 0
		card.Text = ""
		card.AutoButtonColor = false
		card.ZIndex = 3
		card.Parent = cardContainer

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 14)
		corner.Parent = card

		local stroke = Instance.new("UIStroke")
		stroke.Color = if isRec then accent else STROKE
		stroke.Thickness = if isRec then 2 else 1
		stroke.Parent = card

		cards[mode] = { button = card, stroke = stroke }

		local iconLabel = Instance.new("TextLabel")
		iconLabel.Size = UDim2.new(1, 0, 0, if narrow then 40 else 70)
		iconLabel.Position = UDim2.new(0, 0, 0, if narrow then 14 else 30)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = icon
		iconLabel.TextSize = if narrow then 32 else 52
		iconLabel.Font = Enum.Font.GothamBlack
		iconLabel.TextColor3 = accent
		iconLabel.ZIndex = 4
		iconLabel.Parent = card
		table.insert(allElements, { obj = iconLabel, prop = "TextSize", narrow = 32, wide = 52 })
		table.insert(allElements, { obj = iconLabel, prop = "Size", narrow = UDim2.new(1, 0, 0, 40), wide = UDim2.new(1, 0, 0, 70) })
		table.insert(allElements, { obj = iconLabel, prop = "Position", narrow = UDim2.new(0, 0, 0, 14), wide = UDim2.new(0, 0, 0, 30) })

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -30, 0, 36)
		nameLabel.Position = UDim2.new(0, 15, 0, if narrow then 56 else 110)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = label
		nameLabel.TextColor3 = TEXT
		nameLabel.TextSize = if narrow then 17 else 22
		nameLabel.Font = Enum.Font.GothamBlack
		nameLabel.TextXAlignment = Enum.TextXAlignment.Center
		nameLabel.ZIndex = 4
		nameLabel.Parent = card
		table.insert(allElements, { obj = nameLabel, prop = "TextSize", narrow = 17, wide = 22 })
		table.insert(allElements, { obj = nameLabel, prop = "Position", narrow = UDim2.new(0, 15, 0, 56), wide = UDim2.new(0, 15, 0, 110) })

		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -30, 0, if narrow then 40 else 60)
		descLabel.Position = UDim2.new(0, 15, 0, if narrow then 90 else 155)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = desc
		descLabel.TextColor3 = SUBTEXT
		descLabel.TextSize = if narrow then 12 else 14
		descLabel.Font = Enum.Font.GothamMedium
		descLabel.TextWrapped = true
		descLabel.TextXAlignment = Enum.TextXAlignment.Center
		descLabel.ZIndex = 4
		descLabel.Parent = card
		table.insert(allElements, { obj = descLabel, prop = "TextSize", narrow = 12, wide = 14 })
		table.insert(allElements, { obj = descLabel, prop = "Size", narrow = UDim2.new(1, -30, 0, 40), wide = UDim2.new(1, -30, 0, 60) })
		table.insert(allElements, { obj = descLabel, prop = "Position", narrow = UDim2.new(0, 15, 0, 90), wide = UDim2.new(0, 15, 0, 155) })

		if isRec then
			local badge = Instance.new("TextLabel")
			badge.Size = UDim2.new(0, 120, 0, 26)
			badge.AnchorPoint = Vector2.new(0.5, 0)
			badge.Position = UDim2.new(0.5, 0, 1, -38)
			badge.BackgroundColor3 = accent
			badge.TextColor3 = BG
			badge.TextSize = 11
			badge.Font = Enum.Font.GothamBlack
			badge.Text = "RECOMMENDED"
			badge.ZIndex = 5
			badge.Parent = card

			local badgeCorner = Instance.new("UICorner")
			badgeCorner.CornerRadius = UDim.new(0, 6)
			badgeCorner.Parent = badge
		end

		card.MouseEnter:Connect(function()
			TweenService:Create(card, TWEEN_HOVER, { BackgroundColor3 = CARD_HOVER }):Play()
		end)
		card.MouseLeave:Connect(function()
			TweenService:Create(card, TWEEN_HOVER, { BackgroundColor3 = CARD }):Play()
		end)

		card.MouseButton1Click:Connect(function()
			if picked then return end
			picked = mode

			TweenService:Create(stroke, TWEEN_HOVER, { Color = GOLD, Thickness = 3 }):Play()

			local evt = ReplicatedStorage:FindFirstChild("UpdateSettingsEvent")
			if evt then
				(evt :: RemoteEvent):FireServer("UIMode", mode)
			end

			task.delay(0.35, function()
				TweenService:Create(bg, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
				for _, child in bg:GetChildren() do
					if child:IsA("GuiObject") then
						TweenService:Create(child, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
					end
				end
				task.delay(0.35, function()
					gui:Destroy()
					doneEvent:Fire()
				end)
			end)
		end)

		return card
	end

	makeCard(
		"Computer",
		"\xF0\x9F\x96\xA5\xEF\xB8\x8F",
		"COMPUTER",
		"Full desktop layout designed for keyboard & mouse. Best on PC and large screens.",
		BLUE
	)

	makeCard(
		"Mobile",
		"\xF0\x9F\x93\xB1",
		"MOBILE",
		"Portrait layout optimized for touch. Built for phones and tablets.",
		PURPLE
	)

	applyLayout()

	local viewportConn = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		if picked then return end
		applyLayout()
	end)

	doneEvent.Event:Wait()
	viewportConn:Disconnect()
	doneEvent:Destroy()

	return picked :: string
end

return {
	prompt = prompt,
}
