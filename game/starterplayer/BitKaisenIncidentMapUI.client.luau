-- LocalScript: BitKaisenIncidentMapUI
-- Location: StarterPlayerScripts
-- Purpose:
--   Standalone Incident Map UI.
--   Does NOT replace BitKaisenUIBuilder and does NOT require editing the main UI.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local getIncidentMap = ReplicatedStorage:WaitForChild("GetIncidentMap")
local incidentMapAction = ReplicatedStorage:WaitForChild("IncidentMapAction")

local old = playerGui:FindFirstChild("BitKaisenIncidentMapGui")
if old then
	old:Destroy()
end

local COLORS = {
	Bg = Color3.fromRGB(7, 7, 10),
	Window = Color3.fromRGB(15, 15, 22),
	Card = Color3.fromRGB(22, 22, 31),
	Card2 = Color3.fromRGB(28, 28, 40),
	Stroke = Color3.fromRGB(52, 52, 70),
	StrokeRed = Color3.fromRGB(105, 32, 44),
	Text = Color3.fromRGB(238, 238, 248),
	SubText = Color3.fromRGB(165, 165, 185),
	Muted = Color3.fromRGB(112, 112, 132),
	Red = Color3.fromRGB(190, 55, 70),
	Purple = Color3.fromRGB(178, 122, 255),
	Blue = Color3.fromRGB(120, 190, 255),
	Green = Color3.fromRGB(120, 240, 160),
	Gold = Color3.fromRGB(255, 200, 90),
	Bad = Color3.fromRGB(230, 75, 90),
}

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenIncidentMapGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 780
gui.Parent = playerGui

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

local function addPadding(parent, l, r, t, b)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, l or 0)
	p.PaddingRight = UDim.new(0, r or 0)
	p.PaddingTop = UDim.new(0, t or 0)
	p.PaddingBottom = UDim.new(0, b or 0)
	p.Parent = parent
	return p
end

local function tween(instance, duration, props)
	local t = TweenService:Create(instance, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function makeButton(parent, text, size, position, color, z)
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color or COLORS.Card2
	button.BorderSizePixel = 0
	button.TextColor3 = COLORS.Text
	button.TextSize = 12
	button.Font = Enum.Font.GothamBlack
	button.Text = text
	button.AutoButtonColor = false
	button.ZIndex = z or 2
	button.Parent = parent
	addCorner(button, 8)
	addStroke(button, COLORS.Stroke, 1)
	return button
end

local openButton = makeButton(gui, "MAP", UDim2.new(0, 74, 0, 34), UDim2.new(1, -92, 0, 96), COLORS.Card2, 780)
openButton.TextColor3 = COLORS.Purple

local overlay = Instance.new("Frame")
overlay.Name = "IncidentMapOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.Visible = false
overlay.Active = true
overlay.ZIndex = 800
overlay.Parent = gui

local window = Instance.new("Frame")
window.Name = "IncidentMapWindow"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.new(0.5, 0, 0.53, 0)
window.Size = UDim2.new(0.72, 0, 0.80, 0)
window.BackgroundColor3 = COLORS.Window
window.BackgroundTransparency = 1
window.BorderSizePixel = 0
window.Visible = false
window.ZIndex = 801
window.Parent = overlay
addCorner(window, 14)
addStroke(window, COLORS.StrokeRed, 1)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -110, 0, 36)
title.Position = UDim2.new(0, 26, 0, 16)
title.BackgroundTransparency = 1
title.TextColor3 = COLORS.Text
title.TextSize = 24
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "INCIDENT MAP"
title.ZIndex = 802
title.Parent = window

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -110, 0, 36)
subtitle.Position = UDim2.new(0, 27, 0, 52)
subtitle.BackgroundTransparency = 1
subtitle.TextColor3 = COLORS.SubText
subtitle.TextSize = 12
subtitle.Font = Enum.Font.GothamBold
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextWrapped = true
subtitle.Text = "Loading incidents..."
subtitle.ZIndex = 802
subtitle.Parent = window

local closeButton = makeButton(window, "X", UDim2.new(0, 40, 0, 40), UDim2.new(1, -54, 0, 16), COLORS.Card2, 803)
closeButton.TextColor3 = COLORS.Bad
closeButton.TextSize = 18

local refreshButton = makeButton(window, "REFRESH", UDim2.new(0, 96, 0, 30), UDim2.new(1, -156, 0, 21), COLORS.Card2, 803)
refreshButton.TextColor3 = COLORS.Blue
refreshButton.TextSize = 11

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "MapScroll"
scroll.Size = UDim2.new(1, -52, 1, -116)
scroll.Position = UDim2.new(0, 26, 0, 96)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = COLORS.StrokeRed
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ZIndex = 802
scroll.Parent = window

local list = Instance.new("UIListLayout")
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, 12)
list.Parent = scroll
addPadding(scroll, 0, 8, 0, 18)

list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 22)
end)

local isOpen = false
local currentPayload = nil
local busy = false

local function isMobile()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	return viewport.X < 900
end

local function applyResponsive()
	if isMobile() then
		window.Size = UDim2.new(0.92, 0, 0.82, 0)
		window.Position = UDim2.new(0.5, 0, 0.50, 0)
		title.TextSize = 18
		subtitle.TextSize = 10
		scroll.Size = UDim2.new(1, -28, 1, -112)
		scroll.Position = UDim2.new(0, 14, 0, 94)
		openButton.Size = UDim2.new(0, 62, 0, 32)
		openButton.Position = UDim2.new(1, -76, 0, 88)
	else
		window.Size = UDim2.new(0.72, 0, 0.80, 0)
		window.Position = UDim2.new(0.5, 0, 0.53, 0)
		title.TextSize = 24
		subtitle.TextSize = 12
		scroll.Size = UDim2.new(1, -52, 1, -116)
		scroll.Position = UDim2.new(0, 26, 0, 96)
		openButton.Size = UDim2.new(0, 74, 0, 34)
		openButton.Position = UDim2.new(1, -92, 0, 96)
	end
end

applyResponsive()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsive)
end

local function clearScroll()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

local function statColor(value, kind)
	value = tonumber(value) or 0
	if kind == "bad" then
		if value >= 70 then return COLORS.Bad end
		if value >= 40 then return COLORS.Gold end
		return COLORS.Green
	end
	if value >= 70 then return COLORS.Bad end
	if value >= 40 then return COLORS.Gold end
	return COLORS.SubText
end

local function makeStat(parent, text, x, y, color)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.33, -8, 0, 18)
	label.Position = UDim2.new(x, 0, 0, y)
	label.BackgroundTransparency = 1
	label.TextColor3 = color or COLORS.SubText
	label.TextSize = isMobile() and 10 or 11
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.ZIndex = 805
	label.Parent = parent
	return label
end

local function doAction(locationId, actionId)
	if busy then return end
	busy = true
	incidentMapAction:FireServer(locationId, actionId)
	task.delay(0.45, function()
		busy = false
		if isOpen then
			pcall(function()
				currentPayload = getIncidentMap:InvokeServer()
			end)
			if currentPayload then
				-- rebuild after refresh
				clearScroll()
				local oldPayload = currentPayload
				currentPayload = oldPayload
				-- call render through deferred closure
				task.defer(function()
					if isOpen then
						_G.BitKaisenIncidentMapRender(currentPayload)
					end
				end)
			end
		end
	end)
end

local function makeLocationCard(location, actions, role)
	local cardHeight = isMobile() and 270 or 242
	local card = Instance.new("Frame")
	card.Name = "Location_" .. tostring(location.Id)
	card.Size = UDim2.new(1, -8, 0, cardHeight)
	card.BackgroundColor3 = COLORS.Card
	card.BorderSizePixel = 0
	card.ZIndex = 804
	card.Parent = scroll
	addCorner(card, 12)
	addStroke(card, location.ActiveIncident and COLORS.StrokeRed or COLORS.Stroke, 1)

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -28, 0, 24)
	name.Position = UDim2.new(0, 14, 0, 12)
	name.BackgroundTransparency = 1
	name.TextColor3 = COLORS.Text
	name.TextSize = isMobile() and 14 or 17
	name.Font = Enum.Font.GothamBlack
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Text = tostring(location.Name or "Unknown")
	name.ZIndex = 805
	name.Parent = card

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -28, 0, 42)
	desc.Position = UDim2.new(0, 14, 0, 38)
	desc.BackgroundTransparency = 1
	desc.TextColor3 = COLORS.SubText
	desc.TextSize = isMobile() and 10 or 11
	desc.Font = Enum.Font.GothamMedium
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.TextWrapped = true
	desc.Text = tostring(location.Description or "")
	desc.ZIndex = 805
	desc.Parent = card

	makeStat(card, "Threat: " .. tostring(location.Threat or 0) .. "%", 0.04, 86, statColor(location.Threat))
	makeStat(card, "Fear: " .. tostring(location.Fear or 0) .. "%", 0.36, 86, statColor(location.Fear))
	makeStat(card, "Attention: " .. tostring(location.SocietyAttention or 0) .. "%", 0.68, 86, statColor(location.SocietyAttention, "bad"))
	makeStat(card, "Residue: " .. tostring(location.CursedResidue or 0) .. "%", 0.04, 108, statColor(location.CursedResidue))
	makeStat(card, "Control: " .. tostring(location.Control or 0) .. "%", 0.36, 108, COLORS.Purple)
	makeStat(card, "Grade: " .. tostring(location.RecommendedGrade or "Unknown"), 0.68, 108, COLORS.Gold)

	local rumor = Instance.new("TextLabel")
	rumor.Size = UDim2.new(1, -28, 0, 34)
	rumor.Position = UDim2.new(0, 14, 0, 134)
	rumor.BackgroundColor3 = COLORS.Card2
	rumor.BorderSizePixel = 0
	rumor.TextColor3 = COLORS.Purple
	rumor.TextSize = isMobile() and 10 or 11
	rumor.Font = Enum.Font.GothamBold
	rumor.TextWrapped = true
	rumor.TextXAlignment = Enum.TextXAlignment.Left
	rumor.Text = "  Rumor: " .. tostring(location.Rumor or "None") .. "  |  " .. (location.ActiveIncident and "Active Incident" or "Quiet")
	rumor.ZIndex = 805
	rumor.Parent = card
	addCorner(rumor, 8)

	local buttonHolder = Instance.new("Frame")
	buttonHolder.Size = UDim2.new(1, -28, 0, isMobile() and 88 or 54)
	buttonHolder.Position = UDim2.new(0, 14, 0, isMobile() and 174 or 176)
	buttonHolder.BackgroundTransparency = 1
	buttonHolder.ZIndex = 805
	buttonHolder.Parent = card

	local grid = Instance.new("UIGridLayout")
	grid.CellPadding = UDim2.new(0, 8, 0, 8)
	grid.CellSize = isMobile() and UDim2.new(0.48, -4, 0, 32) or UDim2.new(0.24, -6, 0, 32)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = buttonHolder

	local maxButtons = isMobile() and 4 or 6
	local made = 0
	for _, action in ipairs(actions or {}) do
		if made >= maxButtons then break end
		made += 1
		local b = makeButton(buttonHolder, tostring(action.Name or action.Id), UDim2.new(0, 0, 0, 0), UDim2.new(0, 0, 0, 0), action.Locked and Color3.fromRGB(30, 30, 36) or COLORS.Card2, 806)
		b.TextSize = isMobile() and 9 or 10
		b.TextColor3 = action.Locked and COLORS.Muted or (role == "CursedSpirit" and COLORS.Purple or COLORS.Blue)
		b.LayoutOrder = made
		b.MouseButton1Click:Connect(function()
			if action.Locked then return end
			doAction(location.Id, action.Id)
		end)
	end
end

function _G.BitKaisenIncidentMapRender(payload)
	clearScroll()
	currentPayload = payload

	if not payload or payload.Error then
		subtitle.Text = tostring(payload and payload.Error or "Could not load Incident Map.")
		return
	end

	subtitle.Text = "Role: " .. tostring(payload.RoleLabel or "Unknown") .. " | Status: " .. tostring(payload.SocietyStatus or "Unknown") .. " | Territory: " .. tostring(payload.CurrentTerritory or "None")

	for _, location in ipairs(payload.Locations or {}) do
		makeLocationCard(location, payload.Actions or {}, tostring(payload.Role or "Sorcerer"))
	end
end

local function loadMap()
	local ok, payload = pcall(function()
		return getIncidentMap:InvokeServer()
	end)
	if ok then
		_G.BitKaisenIncidentMapRender(payload)
	else
		_G.BitKaisenIncidentMapRender({ Error = "Incident Map failed to load: " .. tostring(payload) })
	end
end

local function openMap()
	isOpen = true
	overlay.Visible = true
	window.Visible = true
	overlay.BackgroundTransparency = 1
	window.BackgroundTransparency = 1
	tween(overlay, 0.12, { BackgroundTransparency = 0.35 })
	tween(window, 0.12, { BackgroundTransparency = 0 })
	loadMap()
end

local function closeMap()
	isOpen = false
	tween(overlay, 0.10, { BackgroundTransparency = 1 })
	tween(window, 0.10, { BackgroundTransparency = 1 })
	task.delay(0.11, function()
		if not isOpen then
			overlay.Visible = false
			window.Visible = false
		end
	end)
end

openButton.MouseButton1Click:Connect(openMap)
closeButton.MouseButton1Click:Connect(closeMap)
refreshButton.MouseButton1Click:Connect(loadMap)

print("[BitKaisenIncidentMapUI] Loaded.")

