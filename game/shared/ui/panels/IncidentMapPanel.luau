-- Update 30 -- the Incident Map, rebuilt as a full-screen map instead of a list.
--
-- It used to be twelve text cards in a scrolling window, which threw away the only
-- interesting thing the data had: every location already carries Threat, Fear,
-- SocietyAttention and CursedResidue, and none of that was ever spatial. Now the
-- locations are pins on a map of Tokyo Metropolis, the pin reads its own threat, and a
-- marker travels between them -- the same shape BitSeas uses with its boat and islands.
--
-- Art is optional on purpose. MAP_ART holds uploaded asset ids; anything still empty (or
-- still in Roblox moderation) falls back to the code-drawn look with no code change, so
-- the panel ships whether or not the images have cleared.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local uiState = require("@ui-state/uiState")
local BitKaisenIncidentMap = require(ReplicatedStorage:WaitForChild("BitKaisenIncidentMap"))
local shikigamiEmblem = require("@ui/shikigamiEmblem")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local getIncidentMap: RemoteFunction
local incidentMapAction: RemoteEvent

local function waitForRemote(name, className)
	local deadline = os.clock() + 10
	repeat
		local remote = ReplicatedStorage:FindFirstChild(name)
		if remote and remote:IsA(className) then
			return remote
		end
		task.wait()
	until os.clock() >= deadline
	error(name .. " remote missing or has the wrong class")
end

local COLORS = {
	Bg = Color3.fromRGB(7, 7, 10),
	Panel = Color3.fromRGB(14, 14, 20),
	Card = Color3.fromRGB(21, 21, 30),
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

-- The map data, the pin coordinates and the artwork slots all live in
-- BitKaisenIncidentMap so this panel and MobileIncidentMapPanel read one source. Keeping
-- a private copy here is what let the phone drift out of sync before.
local MAP_ART = {
	Map = BitKaisenIncidentMap.MAP_IMAGE,
	Locations = BitKaisenIncidentMap.LOCATION_ART,
	Credits = BitKaisenIncidentMap.LOCATION_CREDITS,
	Shikigami = BitKaisenIncidentMap.SHIKIGAMI_ART,
}
local artId = BitKaisenIncidentMap.ArtId
local MAP_ASPECT = BitKaisenIncidentMap.MAP_ASPECT
local MAP_POINTS = BitKaisenIncidentMap.MAP_POINTS
local HOME_POINT = BitKaisenIncidentMap.HOME_POINT

local isOpen = false
local busy = false
-- Declared here so the action buttons built in renderDetail can capture it as an
-- upvalue; it is assigned further down, once the remotes exist.
local doAction
local deployShikigami
local recallShikigami
local currentPayload = nil
local selectedId = nil
local pinsById = {}

local function addCorner(instance, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = instance
	return c
end

local function addStroke(instance, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.Parent = instance
	return s
end

local function tween(instance, time, goal)
	TweenService:Create(instance, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

local function threatColor(value)
	value = tonumber(value) or 0
	if value >= 70 then return COLORS.Bad end
	if value >= 50 then return COLORS.Red end
	if value >= 35 then return COLORS.Gold end
	return COLORS.Green
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

----------------------------------------------------------------
-- SHELL
----------------------------------------------------------------
local existing = playerGui:FindFirstChild("BitKaisenIncidentMapGui")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenIncidentMapGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 626
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.AutoLocalize = false
gui.Enabled = false
gui.Parent = playerGui

-- Full-screen, not a window: opening the map replaces the screen the way the rest of the
-- "go somewhere" screens in the game do.
local root = Instance.new("Frame")
root.Name = "MapRoot"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = COLORS.Bg
root.BorderSizePixel = 0
root.Active = true
root.ZIndex = 1
root.Parent = gui

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 64)
header.BackgroundColor3 = COLORS.Panel
header.BorderSizePixel = 0
header.ZIndex = 5
header.Parent = root

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Position = UDim2.fromOffset(26, 12)
title.Size = UDim2.new(0, 420, 0, 26)
title.BackgroundTransparency = 1
title.Text = "INCIDENT MAP"
title.TextColor3 = COLORS.Gold
title.Font = Enum.Font.GothamBlack
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 6
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Position = UDim2.fromOffset(26, 38)
subtitle.Size = UDim2.new(1, -300, 0, 18)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Loading..."
subtitle.TextColor3 = COLORS.SubText
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 12
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextTruncate = Enum.TextTruncate.AtEnd
subtitle.ZIndex = 6
subtitle.Parent = header

local function makeHeaderButton(name, text, offsetX, color)
	local b = Instance.new("TextButton")
	b.Name = name
	b.AnchorPoint = Vector2.new(1, 0.5)
	b.Position = UDim2.new(1, offsetX, 0.5, 0)
	b.Size = UDim2.fromOffset(name == "CloseButton" and 44 or 108, 36)
	b.BackgroundColor3 = COLORS.Card2
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = color
	b.Font = Enum.Font.GothamBlack
	b.TextSize = 13
	b.AutoButtonColor = true
	b.ZIndex = 6
	b.Parent = header
	addCorner(b, 8)
	addStroke(b, COLORS.Stroke, 1, 0.2)
	return b
end

local closeButton = makeHeaderButton("CloseButton", "X", -20, COLORS.Bad)
local refreshButton = makeHeaderButton("RefreshButton", "REFRESH", -76, COLORS.Blue)

----------------------------------------------------------------
-- MAP AREA
----------------------------------------------------------------
local DETAIL_WIDTH = 372

local mapArea = Instance.new("Frame")
mapArea.Name = "MapArea"
mapArea.Position = UDim2.fromOffset(0, 64)
mapArea.Size = UDim2.new(1, -DETAIL_WIDTH, 1, -64)
mapArea.BackgroundTransparency = 1
mapArea.ZIndex = 2
mapArea.Parent = root

-- The board keeps the map image's aspect ratio so a pin's normalised position always
-- lands on the same piece of geography, whatever the window is doing.
local board = Instance.new("Frame")
board.Name = "Board"
board.AnchorPoint = Vector2.new(0.5, 0.5)
board.Position = UDim2.fromScale(0.5, 0.5)
board.Size = UDim2.new(1, -48, 1, -48)
board.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
board.BorderSizePixel = 0
board.ZIndex = 2
board.Parent = mapArea
addCorner(board, 12)
addStroke(board, COLORS.Stroke, 1, 0.35)

local ratio = Instance.new("UIAspectRatioConstraint")
ratio.AspectRatio = MAP_ASPECT
ratio.DominantAxis = Enum.DominantAxis.Width
ratio.Parent = board

local mapImage = Instance.new("ImageLabel")
mapImage.Name = "MapImage"
mapImage.Size = UDim2.fromScale(1, 1)
mapImage.BackgroundTransparency = 1
mapImage.Image = MAP_ART.Map
mapImage.ScaleType = Enum.ScaleType.Fit
mapImage.ImageTransparency = 0
mapImage.ZIndex = 2
mapImage.Parent = board
addCorner(mapImage, 12)

-- Shown only while the map art is missing or still in moderation, so the panel never
-- reads as broken.
local mapFallback = Instance.new("TextLabel")
mapFallback.Name = "MapFallback"
-- Bottom-left and small: centred and large, the pins sat on top of it and it read as
-- clutter rather than as a watermark.
mapFallback.AnchorPoint = Vector2.new(0, 1)
mapFallback.Position = UDim2.new(0, 16, 1, -10)
mapFallback.Size = UDim2.fromOffset(300, 20)
mapFallback.BackgroundTransparency = 1
mapFallback.Text = "TOKYO METROPOLIS"
mapFallback.TextColor3 = Color3.fromRGB(52, 50, 70)
mapFallback.Font = Enum.Font.GothamBlack
mapFallback.TextSize = 13
mapFallback.TextXAlignment = Enum.TextXAlignment.Left
mapFallback.Visible = not mapImage.IsLoaded
-- Behind the image, not on top of it: at the same ZIndex the label was created second
-- and so painted over the map once the art finally loaded.
mapFallback.ZIndex = 1
mapFallback.Parent = board

-- IsLoaded does not reliably raise a property-changed signal, and the art can also land
-- before this line runs, so poll it for a few seconds instead of trusting the event.
task.spawn(function()
	for _ = 1, 40 do
		if mapImage.IsLoaded then break end
		task.wait(0.25)
	end
	mapFallback.Visible = not mapImage.IsLoaded
end)

-- Cursed-energy haze. This is the ambient motion BitSeas gets from its sea: soft blobs
-- drifting across the board on endless tweens, so the map breathes instead of sitting
-- there. Drawn entirely in code -- no texture, no upload, no moderation to wait on.
local fogLayer = Instance.new("Frame")
fogLayer.Name = "FogLayer"
fogLayer.Size = UDim2.fromScale(1, 1)
fogLayer.BackgroundTransparency = 1
fogLayer.ClipsDescendants = true
fogLayer.ZIndex = 2
fogLayer.Parent = board

local FOG_BANKS = {
	{ w = 0.62, h = 0.44, y = 0.22, seconds = 46, alpha = 0.90 },
	{ w = 0.48, h = 0.34, y = 0.54, seconds = 33, alpha = 0.93 },
	{ w = 0.76, h = 0.52, y = 0.72, seconds = 61, alpha = 0.95 },
	{ w = 0.36, h = 0.28, y = 0.38, seconds = 27, alpha = 0.94 },
}

for index, bank in ipairs(FOG_BANKS) do
	local blob = Instance.new("Frame")
	blob.Name = "Fog" .. index
	blob.AnchorPoint = Vector2.new(0.5, 0.5)
	blob.Size = UDim2.fromScale(bank.w, bank.h)
	blob.Position = UDim2.fromScale(-0.4, bank.y)
	blob.BackgroundColor3 = COLORS.Purple
	blob.BackgroundTransparency = bank.alpha
	blob.BorderSizePixel = 0
	blob.ZIndex = 2
	blob.Parent = fogLayer
	addCorner(blob, 999)

	-- Fades out towards the edges so it reads as haze rather than a moving rectangle.
	local grad = Instance.new("UIGradient")
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	grad.Rotation = index * 37
	grad.Parent = blob

	-- Staggered so the four banks never line up into one obvious sweep.
	task.delay(index * 2.5, function()
		if not blob.Parent then return end
		TweenService:Create(
			blob,
			TweenInfo.new(bank.seconds, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false, 0),
			{ Position = UDim2.fromScale(1.4, bank.y) }
		):Play()
	end)
end

-- Code-drawn stand-in for the map art. The pins are placed against Tokyo's real shape,
-- so with no image behind them they read as dots in a void. These three bands give back
-- the one thing the pins actually need: west is mountain, the middle is the ward belt,
-- east is the bay. Hidden the moment real art loads.
local terrain = Instance.new("Frame")
terrain.Name = "TerrainFallback"
terrain.Size = UDim2.fromScale(1, 1)
terrain.BackgroundTransparency = 1
terrain.ZIndex = 1
terrain.Parent = board

for index, band in ipairs({
	{ x = 0.00, w = 0.34, color = Color3.fromRGB(26, 30, 30), label = "OKUTAMA" },
	{ x = 0.34, w = 0.44, color = Color3.fromRGB(31, 29, 40), label = "WARDS" },
	{ x = 0.78, w = 0.22, color = Color3.fromRGB(17, 21, 34), label = "BAY" },
}) do
	local strip = Instance.new("Frame")
	strip.Name = "Band" .. index
	strip.Position = UDim2.fromScale(band.x, 0)
	strip.Size = UDim2.fromScale(band.w, 1)
	strip.BackgroundColor3 = band.color
	strip.BorderSizePixel = 0
	strip.ZIndex = 1
	strip.Parent = terrain

	local tag = Instance.new("TextLabel")
	tag.AnchorPoint = Vector2.new(0.5, 0)
	tag.Position = UDim2.new(0.5, 0, 0, 12)
	tag.Size = UDim2.new(1, -12, 0, 14)
	tag.BackgroundTransparency = 1
	tag.Text = band.label
	tag.TextColor3 = Color3.fromRGB(58, 56, 76)
	tag.Font = Enum.Font.GothamBlack
	tag.TextSize = 11
	tag.ZIndex = 1
	tag.Parent = strip
end

-- A survey grid, so the board reads as a chart instead of a flat rectangle.
for i = 1, 7 do
	local line = Instance.new("Frame")
	line.Position = UDim2.fromScale(i / 8, 0)
	line.Size = UDim2.new(0, 1, 1, 0)
	line.BackgroundColor3 = Color3.fromRGB(60, 58, 80)
	line.BackgroundTransparency = 0.8
	line.BorderSizePixel = 0
	line.ZIndex = 1
	line.Parent = terrain
end
for i = 1, 3 do
	local line = Instance.new("Frame")
	line.Position = UDim2.fromScale(0, i / 4)
	line.Size = UDim2.new(1, 0, 0, 1)
	line.BackgroundColor3 = Color3.fromRGB(60, 58, 80)
	line.BackgroundTransparency = 0.8
	line.BorderSizePixel = 0
	line.ZIndex = 1
	line.Parent = terrain
end

-- Required by the OpenStreetMap licence. Small, out of the way, and always present while
-- the map art is the one derived from their data.
local mapCredit = Instance.new("TextLabel")
mapCredit.Name = "MapCredit"
mapCredit.AnchorPoint = Vector2.new(1, 1)
mapCredit.Position = UDim2.new(1, -10, 1, -8)
mapCredit.Size = UDim2.fromOffset(260, 14)
mapCredit.BackgroundTransparency = 1
mapCredit.Text = "Map data (c) OpenStreetMap contributors"
mapCredit.TextColor3 = Color3.fromRGB(96, 92, 118)
mapCredit.Font = Enum.Font.GothamMedium
mapCredit.TextSize = 10
mapCredit.TextXAlignment = Enum.TextXAlignment.Right
mapCredit.ZIndex = 9
mapCredit.Parent = board

local pinLayer = Instance.new("Frame")
pinLayer.Name = "PinLayer"
pinLayer.Size = UDim2.fromScale(1, 1)
pinLayer.BackgroundTransparency = 1
pinLayer.ZIndex = 3
pinLayer.Parent = board

-- The travelling marker. This is the piece BitSeas does with a boat sailing between
-- islands; here it is the shadow you send ahead of you.
local token = Instance.new("Frame")
token.Name = "Marker"
token.AnchorPoint = Vector2.new(0.5, 0.5)
token.Position = UDim2.fromScale(HOME_POINT.X, HOME_POINT.Y)
token.Size = UDim2.fromOffset(16, 16)
token.BackgroundColor3 = COLORS.Purple
token.BorderSizePixel = 0
token.ZIndex = 8
token.Parent = pinLayer
addCorner(token, 999)
addStroke(token, Color3.fromRGB(236, 226, 255), 1, 0.25)

local tokenHalo = Instance.new("Frame")
tokenHalo.Name = "Halo"
tokenHalo.AnchorPoint = Vector2.new(0.5, 0.5)
tokenHalo.Position = UDim2.fromScale(0.5, 0.5)
tokenHalo.Size = UDim2.fromScale(2.2, 2.2)
tokenHalo.BackgroundColor3 = COLORS.Purple
tokenHalo.BackgroundTransparency = 0.72
tokenHalo.BorderSizePixel = 0
tokenHalo.ZIndex = 7
tokenHalo.Parent = token
addCorner(tokenHalo, 999)

local function travelTo(point: Vector2)
	-- Distance sets the duration, so crossing to Okutama visibly costs more than hopping
	-- one ward over.
	local distance = (point - Vector2.new(token.Position.X.Scale, token.Position.Y.Scale)).Magnitude
	local duration = math.clamp(0.35 + distance * 1.6, 0.35, 1.5)
	TweenService:Create(
		token,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{ Position = UDim2.fromScale(point.X, point.Y) }
	):Play()
end

----------------------------------------------------------------
-- DETAIL SIDE
----------------------------------------------------------------
local detail = Instance.new("Frame")
detail.Name = "Detail"
detail.AnchorPoint = Vector2.new(1, 0)
detail.Position = UDim2.new(1, 0, 0, 64)
detail.Size = UDim2.new(0, DETAIL_WIDTH, 1, -64)
detail.BackgroundColor3 = COLORS.Panel
detail.BorderSizePixel = 0
detail.ZIndex = 4
detail.Parent = root

local detailScroll = Instance.new("ScrollingFrame")
detailScroll.Name = "DetailScroll"
detailScroll.Position = UDim2.fromOffset(0, 0)
detailScroll.Size = UDim2.fromScale(1, 1)
detailScroll.BackgroundTransparency = 1
detailScroll.BorderSizePixel = 0
detailScroll.ScrollBarThickness = 4
detailScroll.ScrollBarImageColor3 = COLORS.Stroke
detailScroll.CanvasSize = UDim2.fromOffset(0, 0)
detailScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
detailScroll.ZIndex = 4
detailScroll.Parent = detail

local detailPad = Instance.new("UIPadding")
detailPad.PaddingTop = UDim.new(0, 18)
detailPad.PaddingLeft = UDim.new(0, 18)
detailPad.PaddingRight = UDim.new(0, 18)
detailPad.PaddingBottom = UDim.new(0, 24)
detailPad.Parent = detailScroll

local detailList = Instance.new("UIListLayout")
detailList.Padding = UDim.new(0, 10)
detailList.SortOrder = Enum.SortOrder.LayoutOrder
detailList.Parent = detailScroll

local function clearDetail()
	for _, child in ipairs(detailScroll:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function detailLabel(text, size, color, font, order, height)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 0, height or 20)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = color
	l.Font = font or Enum.Font.GothamMedium
	l.TextSize = size
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Top
	l.TextWrapped = height ~= nil
	l.LayoutOrder = order
	l.ZIndex = 5
	l.Parent = detailScroll
	return l
end

local function renderDetail(location)
	local payload = currentPayload or {}
	local actions = payload.Actions or {}
	local role = tostring(payload.Role or "Sorcerer")
	clearDetail()

	if not location then
		detailLabel("Select an incident on the map.", 13, COLORS.Muted, Enum.Font.GothamBold, 1, 40)
		return
	end

	local order = 0
	local function nextOrder()
		order += 1
		return order
	end

	-- The header for the site. If there is a photograph for it, that is what shows. If there
	-- is not, this draws a case-file plate instead: the threat colour, the grade, and a
	-- hazard pattern. It is deliberate rather than an empty gap, and it costs nothing to
	-- license, so a site without a photograph does not look like a site with a bug.
	local art = artId(MAP_ART.Locations[tostring(location.Id)])
	local threat = tonumber(location.Threat) or 0
	local accent = threatColor(threat)

	local plate = Instance.new("Frame")
	plate.Name = "Header"
	plate.Size = UDim2.new(1, 0, 0, 118)
	plate.BackgroundColor3 = Color3.fromRGB(13, 13, 19)
	plate.BorderSizePixel = 0
	plate.ClipsDescendants = true
	plate.LayoutOrder = nextOrder()
	plate.ZIndex = 5
	plate.Parent = detailScroll
	addCorner(plate, 10)
	addStroke(plate, accent, 1, 0.55)

	if art then
		local photo = Instance.new("ImageLabel")
		photo.Name = "Photo"
		photo.Size = UDim2.fromScale(1, 1)
		photo.BackgroundTransparency = 1
		photo.Image = art
		photo.ScaleType = Enum.ScaleType.Crop
		photo.ImageColor3 = Color3.fromRGB(190, 185, 205)
		photo.ZIndex = 5
		photo.Parent = plate

		local credit = MAP_ART.Credits and MAP_ART.Credits[tostring(location.Id)]
		if credit then
			local line = Instance.new("TextLabel")
			line.Name = "PhotoCredit"
			line.AnchorPoint = Vector2.new(1, 1)
			line.Position = UDim2.new(1, -8, 1, -6)
			line.Size = UDim2.fromOffset(240, 14)
			line.BackgroundTransparency = 1
			line.Text = credit
			line.TextColor3 = Color3.fromRGB(150, 145, 170)
			line.Font = Enum.Font.GothamMedium
			line.TextSize = 10
			line.TextXAlignment = Enum.TextXAlignment.Right
			line.TextStrokeTransparency = 0.5
			line.TextStrokeColor3 = Color3.new(0, 0, 0)
			line.ZIndex = 7
			line.Parent = plate
		end
	else
		-- Upright bars, not rotated ones. ClipsDescendants does not clip a rotated child in
		-- Roblox, so the diagonal version of this ran straight out of the plate and across
		-- the rest of the dossier.
		for i = 0, 17 do
			local stripe = Instance.new("Frame")
			stripe.Position = UDim2.new(0, i * 34, 0, 0)
			stripe.Size = UDim2.new(0, 9, 1, 0)
			stripe.BackgroundColor3 = accent
			stripe.BackgroundTransparency = 0.93
			stripe.BorderSizePixel = 0
			stripe.ZIndex = 5
			stripe.Parent = plate
		end

		local grade = Instance.new("TextLabel")
		grade.AnchorPoint = Vector2.new(0, 1)
		grade.Position = UDim2.new(0, 14, 1, -12)
		grade.Size = UDim2.new(1, -28, 0, 34)
		grade.BackgroundTransparency = 1
		grade.Text = string.upper(tostring(location.RecommendedGrade or "Unknown"))
		grade.TextColor3 = accent
		grade.Font = Enum.Font.GothamBlack
		grade.TextSize = 26
		grade.TextXAlignment = Enum.TextXAlignment.Left
		grade.TextTransparency = 0.25
		grade.ZIndex = 6
		grade.Parent = plate

		local tag = Instance.new("TextLabel")
		tag.Position = UDim2.new(0, 14, 0, 12)
		tag.Size = UDim2.new(1, -28, 0, 16)
		tag.BackgroundTransparency = 1
		tag.Text = "CASE FILE"
		tag.TextColor3 = COLORS.Muted
		tag.Font = Enum.Font.GothamBlack
		tag.TextSize = 11
		tag.TextXAlignment = Enum.TextXAlignment.Left
		tag.ZIndex = 6
		tag.Parent = plate
	end

	detailLabel(tostring(location.Name or "Unknown"), 19, COLORS.Text, Enum.Font.GothamBlack, nextOrder(), 26)
	detailLabel(tostring(location.Description or ""), 12, COLORS.SubText, Enum.Font.GothamMedium, nextOrder(), 54)

	local statusText = location.ActiveIncident and "ACTIVE INCIDENT" or "QUIET"
	detailLabel(statusText .. "   |   " .. tostring(location.RecommendedGrade or "Unknown"),
		12, location.ActiveIncident and COLORS.Bad or COLORS.Green, Enum.Font.GothamBlack, nextOrder(), 20)

	local stats = {
		{ "Threat", location.Threat, nil },
		{ "Fear", location.Fear, nil },
		{ "Attention", location.SocietyAttention, "bad" },
		{ "Residue", location.CursedResidue, nil },
		{ "Control", location.Control, nil },
	}
	for _, entry in ipairs(stats) do
		local value = tonumber(entry[2]) or 0
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 26)
		row.BackgroundTransparency = 1
		row.LayoutOrder = nextOrder()
		row.ZIndex = 5
		row.Parent = detailScroll

		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(0, 82, 1, 0)
		name.BackgroundTransparency = 1
		name.Text = entry[1]
		name.TextColor3 = COLORS.Muted
		name.Font = Enum.Font.GothamBold
		name.TextSize = 11
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.ZIndex = 6
		name.Parent = row

		local barBg = Instance.new("Frame")
		barBg.AnchorPoint = Vector2.new(0, 0.5)
		barBg.Position = UDim2.new(0, 86, 0.5, 0)
		barBg.Size = UDim2.new(1, -132, 0, 8)
		barBg.BackgroundColor3 = COLORS.Card
		barBg.BorderSizePixel = 0
		barBg.ZIndex = 6
		barBg.Parent = row
		addCorner(barBg, 999)

		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(math.clamp(value / 100, 0, 1), 0, 1, 0)
		bar.BackgroundColor3 = statColor(value, entry[3])
		bar.BorderSizePixel = 0
		bar.ZIndex = 7
		bar.Parent = barBg
		addCorner(bar, 999)

		local valueLabel = Instance.new("TextLabel")
		valueLabel.AnchorPoint = Vector2.new(1, 0)
		valueLabel.Position = UDim2.new(1, 0, 0, 0)
		valueLabel.Size = UDim2.new(0, 40, 1, 0)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text = tostring(math.floor(value)) .. "%"
		valueLabel.TextColor3 = statColor(value, entry[3])
		valueLabel.Font = Enum.Font.GothamBold
		valueLabel.TextSize = 11
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.ZIndex = 6
		valueLabel.Parent = row
	end

	if location.Rumor and tostring(location.Rumor) ~= "" then
		local rumor = detailLabel("Rumor: " .. tostring(location.Rumor), 11, COLORS.Purple, Enum.Font.GothamBold, nextOrder(), 40)
		rumor.TextWrapped = true
	end

	for _, action in ipairs(actions or {}) do
		local b = Instance.new("TextButton")
		b.Name = tostring(action.Id)
		b.Size = UDim2.new(1, 0, 0, 36)
		b.BackgroundColor3 = action.Locked and Color3.fromRGB(26, 26, 32) or COLORS.Card2
		b.BorderSizePixel = 0
		b.Text = tostring(action.Name or action.Id)
		b.TextColor3 = action.Locked and COLORS.Muted or (role == "CursedSpirit" and COLORS.Purple or COLORS.Blue)
		b.Font = Enum.Font.GothamBlack
		b.TextSize = 12
		b.AutoButtonColor = not action.Locked
		b.LayoutOrder = nextOrder()
		b.ZIndex = 5
		b.Parent = detailScroll
		addCorner(b, 8)
		addStroke(b, action.Locked and COLORS.Stroke or COLORS.StrokeRed, 1, 0.35)

		b.Activated:Connect(function()
			if action.Locked then return end
			if doAction then
				doAction(location.Id, action.Id)
			end
		end)
	end

	-- Shikigami. Guard / Hunt / Scout are not new categories invented for the map: they are
	-- the shikigami's own combat posture, so what it is good at in a fight is what it is
	-- good at standing on a site.
	local roster = payload.Shikigami or {}
	if #roster == 0 then
		return
	end

	detailLabel("SHIKIGAMI", 12, COLORS.Gold, Enum.Font.GothamBlack, nextOrder(), 22)

	local holder = tostring(location.Shikigami or "")
	if holder ~= "" then
		local holderRole, holderEffect = "", ""
		for _, entry in ipairs(roster) do
			if tostring(entry.Name) == holder then
				holderRole = tostring(entry.Role or "")
				holderEffect = tostring(entry.Effect or "")
				break
			end
		end
		local holderArt = artId(MAP_ART.Shikigami[holder])
		local portrait = Instance.new("ImageLabel")
		portrait.Name = "ShikigamiPortrait"
		portrait.Size = UDim2.new(1, 0, 0, 132)
		portrait.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
		portrait.BorderSizePixel = 0
		portrait.Image = holderArt or ""
		portrait.ScaleType = Enum.ScaleType.Crop
		portrait.LayoutOrder = nextOrder()
		portrait.ZIndex = 5
		portrait.Parent = detailScroll
		addCorner(portrait, 10)
		addStroke(portrait, COLORS.Purple, 1, 0.5)
		if not holderArt then
			shikigamiEmblem.draw(portrait, holder, COLORS.Purple, 6)
		end
		detailLabel(holder .. "  ·  " .. holderRole, 13, COLORS.Purple, Enum.Font.GothamBlack, nextOrder(), 20)
		detailLabel(holderEffect, 11, COLORS.SubText, Enum.Font.GothamMedium, nextOrder(), 32)

		local recall = Instance.new("TextButton")
		recall.Name = "RecallShikigami"
		recall.Size = UDim2.new(1, 0, 0, 34)
		recall.BackgroundColor3 = COLORS.Card2
		recall.BorderSizePixel = 0
		recall.Text = "RECALL " .. string.upper(holder)
		recall.TextColor3 = COLORS.Gold
		recall.Font = Enum.Font.GothamBlack
		recall.TextSize = 11
		recall.LayoutOrder = nextOrder()
		recall.ZIndex = 5
		recall.Parent = detailScroll
		addCorner(recall, 8)
		addStroke(recall, COLORS.Gold, 1, 0.55)
		recall.Activated:Connect(function()
			if recallShikigami then
				recallShikigami(location.Id, holder)
			end
		end)
		return
	end

	local deployedCount = tonumber(payload.DeployedCount) or 0
	local deployLimit = tonumber(payload.DeployLimit) or 1
	detailLabel(string.format("Shadows on the map: %d / %d", deployedCount, deployLimit),
		11, deployedCount >= deployLimit and COLORS.Bad or COLORS.Muted, Enum.Font.GothamBold, nextOrder(), 18)

	local anyFree = false
	for _, entry in ipairs(roster) do
		if not entry.DeployedTo then
			anyFree = true
			local atLimit = deployedCount >= deployLimit
			local send = Instance.new("TextButton")
			send.Name = "Send_" .. tostring(entry.Name)
			send.Size = UDim2.new(1, 0, 0, 34)
			send.BackgroundColor3 = atLimit and Color3.fromRGB(26, 26, 32) or COLORS.Card2
			send.BorderSizePixel = 0
			send.Text = "SEND " .. string.upper(tostring(entry.Name)) .. "  (" .. tostring(entry.Role) .. ")"
			send.TextColor3 = atLimit and COLORS.Muted or COLORS.Purple
			send.Font = Enum.Font.GothamBlack
			send.TextSize = 11
			send.AutoButtonColor = not atLimit
			send.LayoutOrder = nextOrder()
			send.ZIndex = 5
			send.Parent = detailScroll
			addCorner(send, 8)
			addStroke(send, atLimit and COLORS.Stroke or COLORS.Purple, 1, 0.55)
			send.Activated:Connect(function()
				if atLimit then return end
				if deployShikigami then
					deployShikigami(location.Id, tostring(entry.Name))
				end
			end)
		end
	end

	if not anyFree then
		detailLabel("Every shikigami you have tamed is already holding a site.",
			11, COLORS.Muted, Enum.Font.GothamMedium, nextOrder(), 30)
	end
end

----------------------------------------------------------------
-- PINS
----------------------------------------------------------------
local renderMap

-- Every map action -- the role actions, and sending or recalling a shikigami -- leaves on
-- the same remote and comes back the same way, so the round trip lives here once.
local function fireAndRefresh(locationId, actionId, extra)
	if busy then return end
	busy = true
	incidentMapAction:FireServer(locationId, actionId, extra)
	task.delay(0.45, function()
		busy = false
		if not isOpen then return end
		local ok, payload = pcall(function()
			return getIncidentMap:InvokeServer()
		end)
		if ok and payload then
			task.defer(function()
				if isOpen then
					renderMap(payload)
				end
			end)
		end
	end)
end

function doAction(locationId, actionId)
	fireAndRefresh(locationId, actionId)
end

function deployShikigami(locationId, shikigamiName)
	fireAndRefresh(locationId, "deploy_shikigami", shikigamiName)
end

function recallShikigami(locationId, shikigamiName)
	fireAndRefresh(locationId, "recall_shikigami", shikigamiName)
end

local function clearPins()
	for _, child in ipairs(pinLayer:GetChildren()) do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end
	table.clear(pinsById)
end

local function selectLocation(location)
	selectedId = tostring(location.Id)
	renderDetail(location)
	local point = MAP_POINTS[selectedId]
	if point then
		travelTo(point)
	end
	for id, pin in pairs(pinsById) do
		local ring = pin:FindFirstChild("Select")
		if ring then
			ring.Visible = (id == selectedId)
		end
	end
end

local function makePin(location)
	local id = tostring(location.Id)
	local point = MAP_POINTS[id]
	if not point then
		return
	end

	local threat = tonumber(location.Threat) or 0
	local color = threatColor(threat)

	local pin = Instance.new("TextButton")
	pin.Name = "Pin_" .. id
	pin.AnchorPoint = Vector2.new(0.5, 0.5)
	pin.Position = UDim2.fromScale(point.X, point.Y)
	pin.Size = UDim2.fromOffset(18, 18)
	pin.BackgroundColor3 = color
	pin.BorderSizePixel = 0
	pin.Text = ""
	pin.AutoButtonColor = false
	pin.ZIndex = 6
	pin.Parent = pinLayer
	addCorner(pin, 999)
	addStroke(pin, Color3.fromRGB(240, 240, 250), 1, 0.4)

	-- Selection ring, hidden until this pin is the one being looked at.
	local selectRing = Instance.new("Frame")
	selectRing.Name = "Select"
	selectRing.AnchorPoint = Vector2.new(0.5, 0.5)
	selectRing.Position = UDim2.fromScale(0.5, 0.5)
	selectRing.Size = UDim2.fromScale(2.4, 2.4)
	selectRing.BackgroundTransparency = 1
	selectRing.Visible = id == selectedId
	selectRing.ZIndex = 5
	selectRing.Parent = pin
	addCorner(selectRing, 999)
	addStroke(selectRing, COLORS.Gold, 2, 0.1)

	-- An active incident pulses, and the higher the threat the faster it goes, so the
	-- map reads at a glance without anyone having to open a single card.
	if location.ActiveIncident then
		local pulse = Instance.new("Frame")
		pulse.Name = "Pulse"
		pulse.AnchorPoint = Vector2.new(0.5, 0.5)
		pulse.Position = UDim2.fromScale(0.5, 0.5)
		pulse.Size = UDim2.fromScale(1, 1)
		pulse.BackgroundColor3 = color
		pulse.BackgroundTransparency = 0.35
		pulse.BorderSizePixel = 0
		pulse.ZIndex = 4
		pulse.Parent = pin
		addCorner(pulse, 999)

		local period = math.clamp(1.9 - (threat / 100) * 1.1, 0.7, 1.9)
		-- repeatCount -1 loops forever and dies with the instance, so no manual loop to
		-- leak when the panel closes.
		TweenService:Create(
			pulse,
			TweenInfo.new(period, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1, false, 0),
			{ Size = UDim2.fromScale(3.2, 3.2), BackgroundTransparency = 1 }
		):Play()
	end

	-- A shadow standing here gets its own badge, so map control is readable without
	-- opening anything.
	if location.Shikigami then
		local badge = Instance.new("Frame")
		badge.Name = "ShikigamiBadge"
		badge.AnchorPoint = Vector2.new(0.5, 0.5)
		badge.Position = UDim2.fromScale(0.5, 0.5)
		badge.Size = UDim2.fromScale(1.75, 1.75)
		badge.BackgroundTransparency = 1
		badge.ZIndex = 5
		badge.Parent = pin
		addCorner(badge, 999)
		addStroke(badge, COLORS.Purple, 2, 0.15)


		local holderLabel = Instance.new("TextLabel")
		holderLabel.Name = "Holder"
		holderLabel.AnchorPoint = Vector2.new(0.5, 1)
		holderLabel.Position = UDim2.new(0.5, 0, 0, -8)
		holderLabel.Size = UDim2.fromOffset(150, 14)
		holderLabel.BackgroundTransparency = 1
		holderLabel.Text = tostring(location.Shikigami)
		holderLabel.TextColor3 = COLORS.Purple
		holderLabel.Font = Enum.Font.GothamBlack
		holderLabel.TextSize = 10
		holderLabel.TextStrokeTransparency = 0.4
		holderLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
		holderLabel.ZIndex = 7
		holderLabel.Parent = pin
	end

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 1, 6)
	label.Size = UDim2.fromOffset(150, 16)
	label.BackgroundTransparency = 1
	label.Text = tostring(location.Name or id)
	label.TextColor3 = COLORS.Text
	label.Font = Enum.Font.GothamBold
	label.TextSize = 11
	label.TextStrokeTransparency = 0.4
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.ZIndex = 7
	label.Parent = pin

	-- Hover card. Only exists when a shikigami is standing here and we have its portrait,
	-- so the map stays a map and the creature is something you find by looking closer.
	local hoverCard = nil
	local holderArt = location.Shikigami and artId(MAP_ART.Shikigami[tostring(location.Shikigami)])
	if location.Shikigami then
		hoverCard = Instance.new("Frame")
		hoverCard.Name = "ShikigamiCard"
		hoverCard.AnchorPoint = Vector2.new(0.5, 1)
		hoverCard.Position = UDim2.new(0.5, 0, 0, -14)
		hoverCard.Size = UDim2.fromOffset(132, 158)
		hoverCard.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
		hoverCard.BorderSizePixel = 0
		hoverCard.Visible = false
		hoverCard.ZIndex = 20
		hoverCard.Parent = pin
		addCorner(hoverCard, 10)
		addStroke(hoverCard, COLORS.Purple, 1, 0.25)

		local face = Instance.new("ImageLabel")
		face.Name = "Portrait"
		face.Position = UDim2.fromOffset(8, 8)
		face.Size = UDim2.new(1, -16, 0, 112)
		face.BackgroundColor3 = Color3.fromRGB(9, 9, 14)
		face.BorderSizePixel = 0
		face.Image = holderArt or ""
		face.ScaleType = Enum.ScaleType.Crop
		face.ZIndex = 21
		face.Parent = hoverCard
		addCorner(face, 8)

		-- No illustration means the drawn sigil, not an empty frame. The moment an id is
		-- put in SHIKIGAMI_ART the image takes over and this stops being built.
		if not holderArt then
			shikigamiEmblem.draw(face, tostring(location.Shikigami), COLORS.Purple, 22)
		end

		local caption = Instance.new("TextLabel")
		caption.Name = "Caption"
		caption.Position = UDim2.fromOffset(8, 122)
		caption.Size = UDim2.new(1, -16, 0, 28)
		caption.BackgroundTransparency = 1
		caption.Text = tostring(location.Shikigami)
		caption.TextColor3 = COLORS.Purple
		caption.Font = Enum.Font.GothamBlack
		caption.TextSize = 11
		caption.TextWrapped = true
		caption.ZIndex = 21
		caption.Parent = hoverCard
	end

	pin.MouseEnter:Connect(function()
		tween(pin, 0.12, { Size = UDim2.fromOffset(24, 24) })
		if hoverCard then
			hoverCard.Visible = true
			hoverCard.Size = UDim2.fromOffset(132, 148)
			tween(hoverCard, 0.14, { Size = UDim2.fromOffset(132, 158) })
		end
	end)
	pin.MouseLeave:Connect(function()
		tween(pin, 0.12, { Size = UDim2.fromOffset(18, 18) })
		if hoverCard then
			hoverCard.Visible = false
		end
	end)
	pin.Activated:Connect(function()
		if _G.BitKaisenPlaySFX then
			_G.BitKaisenPlaySFX("Click")
		end
		selectLocation(location)
	end)

	pinsById[id] = pin
end

function renderMap(payload)
	currentPayload = payload
	clearPins()

	if not payload or payload.Error then
		local reason = tostring(payload and payload.Error or "Could not load the Incident Map.")
		subtitle.Text = reason
		-- Say it over the board as well: an empty map with a one-line subtitle reads as
		-- broken rather than as "this does not exist for you".
		mapFallback.Text = reason
		mapFallback.TextSize = 18
		mapFallback.TextWrapped = true
		mapFallback.ZIndex = 4
		mapFallback.Visible = true
		renderDetail(nil)
		return
	end

	-- Back to the plain watermark once a real payload arrives.
	mapFallback.Text = "TOKYO METROPOLIS"
	mapFallback.TextSize = 34
	mapFallback.TextWrapped = false
	mapFallback.ZIndex = 1
	mapFallback.Visible = not mapImage.IsLoaded

	subtitle.Text = "Role: " .. tostring(payload.RoleLabel or "Unknown")
		.. "   |   Status: " .. tostring(payload.SocietyStatus or "Unknown")
		.. "   |   Territory: " .. tostring(payload.CurrentTerritory or "None")

	local locations = payload.Locations or {}

	for _, location in ipairs(locations) do
		makePin(location)
	end

	-- Keep whatever was selected across a refresh; otherwise fall back to the detail
	-- placeholder rather than silently picking something for the player.
	local kept = nil
	for _, location in ipairs(locations) do
		if tostring(location.Id) == selectedId then
			kept = location
			break
		end
	end
	if kept then
		renderDetail(kept)
		local ring = pinsById[selectedId] and pinsById[selectedId]:FindFirstChild("Select")
		if ring then
			ring.Visible = true
		end
	else
		selectedId = nil
		renderDetail(nil)
	end
end

local function loadMap()
	local ok, payload = pcall(function()
		return getIncidentMap:InvokeServer()
	end)
	if ok then
		renderMap(payload)
	else
		renderMap({ Error = "Incident Map failed to load: " .. tostring(payload) })
	end
end

local function openMap()
	isOpen = true
	gui.Enabled = true
	root.Visible = true
	-- Re-checked on every open: the art can finish loading long after the boot-time poll
	-- above has given up, and a stale fallback sits on top of a perfectly good map.
	mapFallback.Visible = not mapImage.IsLoaded
	terrain.Visible = not mapImage.IsLoaded
	loadMap()
end

local function closeMap()
	isOpen = false
	gui.Enabled = false
end

closeButton.Activated:Connect(function()
	uiState.closeRoute()
end)
refreshButton.Activated:Connect(loadMap)

local function init()
	getIncidentMap = waitForRemote("GetIncidentMap", "RemoteFunction") :: RemoteFunction
	incidentMapAction = waitForRemote("IncidentMapAction", "RemoteEvent") :: RemoteEvent

	uiState.subscribe(function(route)
		if route == "incident_map" then
			openMap()
		else
			closeMap()
		end
	end)
end

return { init = init, open = openMap }
