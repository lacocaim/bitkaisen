-- Update 30 -- the phone half of the Incident Map.
--
-- Desktop got the full-screen map in this update and the phone was left on the old list
-- of twelve text cards, which is the wrong way round: most of the people playing this are
-- on a phone. This is the same map, laid out for a portrait screen: the board sits at the
-- top at its true aspect ratio, the twelve incidents are pins on it, and tapping a pin
-- fills the dossier underneath instead of opening a second screen.
--
-- Every piece of map data (pin coordinates, artwork slots, the OpenStreetMap credit) comes
-- from BitKaisenIncidentMap, shared with IncidentMapPanel, so the two cannot drift.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local mc = require("@ui/mobile/mobileComponents")
local uiState = require("@ui-state/uiState")
local BitKaisenIncidentMap = require(ReplicatedStorage:WaitForChild("BitKaisenIncidentMap"))
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _im(key, fallback)
	return BitKaisenLocale.tOrFallback(_L, "incident_map." .. key, nil, fallback)
end

local theme = mc.theme
local bindTap = mc.bindTap
local corner = mc.corner
local stroke = mc.stroke
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MAP_ASPECT = BitKaisenIncidentMap.MAP_ASPECT
local MAP_POINTS = BitKaisenIncidentMap.MAP_POINTS
local HOME_POINT = BitKaisenIncidentMap.HOME_POINT
local artId = BitKaisenIncidentMap.ArtId

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local BOARD_TOP = 56
local BOARD_PAD = 8

local function threatColor(value)
	value = tonumber(value) or 0
	if value >= 70 then return theme.Bad end
	if value >= 50 then return theme.Red end
	if value >= 35 then return theme.Gold end
	return theme.Green
end

local function statColor(value, kind)
	value = tonumber(value) or 0
	if kind == "bad" then
		if value >= 70 then return theme.Bad end
		if value >= 40 then return theme.Gold end
		return theme.Green
	end
	if value >= 70 then return theme.Bad end
	if value >= 40 then return theme.Gold end
	return theme.SubText
end

local gui: ScreenGui
local sheet: Frame
local board: Frame
local mapImage: ImageLabel
local pinLayer: Frame
local marker: Frame
local scroll: ScrollingFrame
local subtitle: TextLabel

local isOpen = false
local busy = false
local currentPayload = nil
local selectedId = nil
local pinsById = {}

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

local renderAll
local loadMap
local refreshAfterAction

----------------------------------------------------------------
-- LAYOUT
----------------------------------------------------------------

-- The board keeps the map image's own 1024x572 shape so the pin coordinates stay honest.
-- Everything below it gets whatever height is left, which on a tall phone is most of the
-- screen and on a short one is still enough for the dossier to scroll.
local function layout()
	if not sheet or sheet.AbsoluteSize.X <= 0 then
		return
	end
	local boardW = sheet.AbsoluteSize.X - (BOARD_PAD * 2)
	local boardH = math.floor(boardW / MAP_ASPECT)
	board.Position = UDim2.fromOffset(BOARD_PAD, BOARD_TOP)
	board.Size = UDim2.fromOffset(boardW, boardH)
	scroll.Position = UDim2.fromOffset(0, BOARD_TOP + boardH + BOARD_PAD)
	scroll.Size = UDim2.new(1, 0, 1, -(BOARD_TOP + boardH + BOARD_PAD))
end

----------------------------------------------------------------
-- BOARD
----------------------------------------------------------------

local function clearPins()
	for _, pin in pairs(pinsById) do
		pin:Destroy()
	end
	table.clear(pinsById)
end

local function pointFor(locationId)
	return MAP_POINTS[tostring(locationId)] or HOME_POINT
end

local function moveMarkerTo(locationId)
	if not marker then return end
	local target = pointFor(locationId)
	local from = Vector2.new(marker.Position.X.Scale, marker.Position.Y.Scale)
	local distance = (target - from).Magnitude
	TweenService:Create(
		marker,
		TweenInfo.new(math.clamp(distance * 2.2, 0.25, 1.4), Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(target.X, target.Y) }
	):Play()
end

local selectLocation

local function makePin(location)
	local id = tostring(location.Id)
	local point = pointFor(id)
	local threat = tonumber(location.Threat) or 0
	local color = threatColor(threat)

	local pin = Instance.new("TextButton")
	pin.Name = "Pin_" .. id
	pin.AnchorPoint = Vector2.new(0.5, 0.5)
	pin.Position = UDim2.fromScale(point.X, point.Y)
	pin.Size = UDim2.fromOffset(16, 16)
	pin.BackgroundColor3 = color
	pin.BorderSizePixel = 0
	pin.AutoButtonColor = false
	pin.Text = ""
	pin.ZIndex = 6
	pin.Parent = pinLayer
	corner(pin, 999)
	stroke(pin, Color3.fromRGB(8, 8, 12), 2)

	-- The radar ring. Only active incidents pulse, and the higher the threat the faster,
	-- so a glance at the board tells you where the night is going wrong.
	if location.ActiveIncident then
		local ring = Instance.new("Frame")
		ring.Name = "Ring"
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.Position = UDim2.fromScale(0.5, 0.5)
		ring.Size = UDim2.fromScale(1, 1)
		ring.BackgroundTransparency = 1
		ring.ZIndex = 5
		ring.Parent = pin
		corner(ring, 999)
		local ringStroke = stroke(ring, color, 2)

		local period = math.clamp(1.9 - (threat / 100) * 1.1, 0.7, 1.9)
		local info = TweenInfo.new(period, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1)
		TweenService:Create(ring, info, { Size = UDim2.fromScale(2.6, 2.6) }):Play()
		TweenService:Create(ringStroke, info, { Transparency = 1 }):Play()
	end

	-- A shikigami standing here gets a purple collar, which is the only thing on the board
	-- that is not about threat.
	if location.Shikigami then
		local collar = Instance.new("Frame")
		collar.Name = "Held"
		collar.AnchorPoint = Vector2.new(0.5, 0.5)
		collar.Position = UDim2.fromScale(0.5, 0.5)
		collar.Size = UDim2.fromScale(1.75, 1.75)
		collar.BackgroundTransparency = 1
		collar.ZIndex = 5
		collar.Parent = pin
		corner(collar, 999)
		stroke(collar, theme.Purple, 2)
	end

	bindTap(pin, function()
		selectLocation(id)
	end)

	pinsById[id] = pin
	return pin
end

local function highlightSelectedPin()
	for id, pin in pairs(pinsById) do
		local selected = id == selectedId
		pin.Size = UDim2.fromOffset(selected and 22 or 16, selected and 22 or 16)
		pin.ZIndex = selected and 8 or 6
	end
end

----------------------------------------------------------------
-- DOSSIER
----------------------------------------------------------------

local function clearScroll()
	for _, child in ipairs(scroll:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function findLocation(id)
	for _, location in ipairs((currentPayload and currentPayload.Locations) or {}) do
		if tostring(location.Id) == tostring(id) then
			return location
		end
	end
	return nil
end

local function doAction(locationId, actionId, shikigamiName)
	if busy then return end
	busy = true
	incidentMapAction:FireServer(locationId, actionId, shikigamiName)
	task.delay(0.45, function()
		busy = false
		refreshAfterAction()
	end)
end

local function makeStatRow(parent, order, label, value, kind)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 18)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.Parent = parent

	local name = Instance.new("TextLabel")
	name.Size = UDim2.fromOffset(74, 18)
	name.BackgroundTransparency = 1
	name.Text = label
	name.TextColor3 = theme.Muted
	name.TextSize = 10
	name.Font = Enum.Font.GothamBlack
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = row

	local track = Instance.new("Frame")
	track.Position = UDim2.new(0, 78, 0.5, -3)
	track.Size = UDim2.new(1, -122, 0, 5)
	track.BackgroundColor3 = Color3.fromRGB(22, 20, 32)
	track.BorderSizePixel = 0
	track.Parent = row
	corner(track, 999)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(math.clamp((tonumber(value) or 0) / 100, 0, 1), 1)
	fill.BackgroundColor3 = statColor(value, kind)
	fill.BorderSizePixel = 0
	fill.Parent = track
	corner(fill, 999)

	local amount = Instance.new("TextLabel")
	amount.AnchorPoint = Vector2.new(1, 0.5)
	amount.Position = UDim2.new(1, 0, 0.5, 0)
	amount.Size = UDim2.fromOffset(40, 18)
	amount.BackgroundTransparency = 1
	amount.Text = tostring(math.floor(tonumber(value) or 0)) .. "%"
	amount.TextColor3 = theme.SubText
	amount.TextSize = 10
	amount.Font = Enum.Font.GothamBold
	amount.TextXAlignment = Enum.TextXAlignment.Right
	amount.Parent = row
end

-- A site with no photograph gets a drawn case-file plate rather than a gap, so an empty
-- artwork slot reads as a deliberate style and not as a broken image.
local function makeHeaderPlate(parent, location, order)
	local id = tostring(location.Id)
	local art = artId(BitKaisenIncidentMap.LOCATION_ART[id])
	local accent = threatColor(location.Threat)

	local plate = Instance.new("Frame")
	plate.Name = "Plate"
	plate.Size = UDim2.new(1, 0, 0, art and 116 or 66)
	plate.BackgroundColor3 = Color3.fromRGB(13, 13, 19)
	plate.BorderSizePixel = 0
	plate.ClipsDescendants = true
	plate.LayoutOrder = order
	plate.Parent = parent
	corner(plate, 10)
	stroke(plate, theme.StrokeSoft, 1)

	if art then
		local photo = Instance.new("ImageLabel")
		photo.Size = UDim2.fromScale(1, 1)
		photo.BackgroundTransparency = 1
		photo.Image = art
		photo.ScaleType = Enum.ScaleType.Crop
		photo.ImageTransparency = 0.15
		photo.Parent = plate

		local credit = artId(BitKaisenIncidentMap.LOCATION_CREDITS[id])
		if credit then
			local creditLabel = Instance.new("TextLabel")
			creditLabel.AnchorPoint = Vector2.new(1, 1)
			creditLabel.Position = UDim2.new(1, -6, 1, -4)
			creditLabel.Size = UDim2.fromOffset(190, 12)
			creditLabel.BackgroundTransparency = 1
			creditLabel.Text = credit
			creditLabel.TextColor3 = Color3.fromRGB(190, 190, 205)
			creditLabel.TextSize = 9
			creditLabel.Font = Enum.Font.Gotham
			creditLabel.TextXAlignment = Enum.TextXAlignment.Right
			creditLabel.TextTransparency = 0.25
			creditLabel.TextStrokeTransparency = 0.5
			creditLabel.ZIndex = 3
			creditLabel.Parent = plate
		end
	else
		-- Upright bars, not rotated ones. ClipsDescendants does not clip a rotated child in
		-- Roblox, so the diagonal version of this ran straight out of the plate and across
		-- the rest of the dossier.
		for i = 0, 11 do
			local stripe = Instance.new("Frame")
			stripe.Position = UDim2.new(0, i * 38, 0, 0)
			stripe.Size = UDim2.new(0, 12, 1, 0)
			stripe.BackgroundColor3 = accent
			stripe.BackgroundTransparency = 0.88
			stripe.BorderSizePixel = 0
			stripe.Parent = plate
		end
	end

	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0, 1)
	bar.Position = UDim2.new(0, 0, 1, 0)
	bar.Size = UDim2.new(1, 0, 0, 3)
	bar.BackgroundColor3 = accent
	bar.BorderSizePixel = 0
	bar.ZIndex = 4
	bar.Parent = plate

	local grade = Instance.new("TextLabel")
	grade.Position = UDim2.fromOffset(10, 8)
	grade.Size = UDim2.new(1, -20, 0, 14)
	grade.BackgroundTransparency = 1
	grade.Text = "CASE FILE  //  " .. string.upper(tostring(location.RecommendedGrade or "?"))
	grade.TextColor3 = accent
	grade.TextSize = 10
	grade.Font = Enum.Font.GothamBlack
	grade.TextXAlignment = Enum.TextXAlignment.Left
	grade.TextStrokeTransparency = 0.6
	grade.ZIndex = 4
	grade.Parent = plate
end

local function makeButtonRow(parent, order, entries)
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, 0, 0, 0)
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.BackgroundTransparency = 1
	holder.LayoutOrder = order
	holder.Parent = parent

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.5, -4, 0, 38)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = holder

	for index, entry in ipairs(entries) do
		mc.mobileButton({
			parent = holder,
			text = entry.Text,
			size = UDim2.new(1, 0, 1, 0),
			color = entry.Locked and Color3.fromRGB(30, 30, 36) or (entry.Color or theme.Button),
			textColor = entry.Locked and theme.Muted or (entry.TextColor or theme.Blue),
			textSize = 11,
			order = index,
			callback = function()
				if entry.Locked then return end
				entry.Run()
			end,
		})
	end
	return holder
end

local function renderDossier()
	clearScroll()

	if not currentPayload or currentPayload.Error then
		mc.mobileLabel({
			parent = scroll,
			text = tostring(currentPayload and currentPayload.Error or _im("error_default", "Could not load Incident Map.")),
			size = 13,
			color = theme.Bad,
			order = 1,
		})
		return
	end

	local location = findLocation(selectedId)
	if not location then
		mc.mobileLabel({
			parent = scroll,
			text = _im("tap_hint", "Tap a pin to open its case file."),
			size = 12,
			color = theme.Muted,
			font = Enum.Font.GothamBold,
			order = 1,
		})
		return
	end

	local card = mc.mobileCard({
		parent = scroll,
		color = theme.Card,
		accentColor = location.ActiveIncident and Color3.fromRGB(105, 32, 44) or theme.Stroke,
	})

	makeHeaderPlate(card, location, 1)

	mc.mobileLabel({
		parent = card,
		text = tostring(location.Name or "Unknown"),
		size = 16,
		color = theme.Text,
		font = Enum.Font.GothamBlack,
		order = 2,
	})

	mc.mobileLabel({
		parent = card,
		text = tostring(location.Description or ""),
		size = 12,
		color = theme.SubText,
		font = Enum.Font.GothamMedium,
		order = 3,
	})

	local stats = Instance.new("Frame")
	stats.Size = UDim2.new(1, 0, 0, 0)
	stats.AutomaticSize = Enum.AutomaticSize.Y
	stats.BackgroundTransparency = 1
	stats.LayoutOrder = 4
	stats.Parent = card

	local statsList = Instance.new("UIListLayout")
	statsList.SortOrder = Enum.SortOrder.LayoutOrder
	statsList.Padding = UDim.new(0, 2)
	statsList.Parent = stats

	makeStatRow(stats, 1, _im("stat_threat", "THREAT"), location.Threat)
	makeStatRow(stats, 2, _im("stat_fear", "FEAR"), location.Fear)
	makeStatRow(stats, 3, _im("stat_attention", "ATTENTION"), location.SocietyAttention, "bad")
	makeStatRow(stats, 4, _im("stat_residue", "RESIDUE"), location.CursedResidue)
	makeStatRow(stats, 5, _im("stat_control", "CONTROL"), location.Control)

	local rumorKey = location.ActiveIncident and "rumor_active" or "rumor_quiet"
	local rumorFallback = location.ActiveIncident and "Rumor: {rumor} | Active Incident" or "Rumor: {rumor} | Quiet"
	mc.mobileLabel({
		parent = card,
		text = (_im(rumorKey, rumorFallback):gsub("{rumor}", tostring(location.Rumor or "None"))),
		size = 11,
		color = theme.Purple,
		font = Enum.Font.GothamBold,
		order = 5,
	})

	-- Shikigami. Either one is standing here, in which case the only move is to call it
	-- back, or the tamed ones that are free can be sent.
	local roster = currentPayload.Shikigami or {}
	local limit = tonumber(currentPayload.DeployLimit) or 0
	local deployed = tonumber(currentPayload.DeployedCount) or 0

	if location.Shikigami then
		local holder = tostring(location.Shikigami)
		local role, effect = "", ""
		for _, entry in ipairs(roster) do
			if tostring(entry.Name) == holder then
				role = tostring(entry.Role or "")
				effect = tostring(entry.Effect or "")
				break
			end
		end
		mc.mobileLabel({
			parent = card,
			text = holder .. (role ~= "" and ("  //  " .. string.upper(role)) or "") .. (effect ~= "" and ("\n" .. effect) or ""),
			size = 11,
			color = theme.Purple,
			font = Enum.Font.GothamBold,
			order = 6,
		})
		makeButtonRow(card, 7, {
			{
				Text = _im("recall", "RECALL"),
				TextColor = theme.Purple,
				Run = function()
					doAction(location.Id, "recall_shikigami", holder)
				end,
			},
		})
	elseif #roster > 0 then
		local free = {}
		for _, entry in ipairs(roster) do
			if not entry.DeployedTo then
				table.insert(free, entry)
			end
		end
		local atLimit = deployed >= limit
		mc.mobileLabel({
			parent = card,
			text = _im("shikigami_slots", "Shadows on the map: {n} of {max}")
				:gsub("{n}", tostring(deployed))
				:gsub("{max}", tostring(limit)),
			size = 11,
			color = atLimit and theme.Muted or theme.Purple,
			font = Enum.Font.GothamBold,
			order = 6,
		})
		local entries = {}
		for _, entry in ipairs(free) do
			table.insert(entries, {
				Text = "SEND " .. string.upper(tostring(entry.Name)),
				TextColor = theme.Purple,
				Locked = atLimit,
				Run = function()
					doAction(location.Id, "deploy_shikigami", tostring(entry.Name))
				end,
			})
		end
		if #entries > 0 then
			makeButtonRow(card, 7, entries)
		end
	end

	local actions = {}
	for _, action in ipairs(currentPayload.Actions or {}) do
		table.insert(actions, {
			Text = tostring(action.Name or action.Id),
			Locked = action.Locked == true,
			TextColor = tostring(currentPayload.Role) == "CursedSpirit" and theme.Purple or theme.Blue,
			Run = function()
				doAction(location.Id, action.Id)
			end,
		})
	end
	if #actions > 0 then
		makeButtonRow(card, 8, actions)
	end
end

function selectLocation(id)
	selectedId = tostring(id)
	highlightSelectedPin()
	moveMarkerTo(selectedId)
	renderDossier()
	scroll.CanvasPosition = Vector2.zero
end

----------------------------------------------------------------
-- RENDER
----------------------------------------------------------------

function renderAll(payload)
	currentPayload = payload
	clearPins()

	if not payload or payload.Error then
		subtitle.Text = _im("error_load", "Error loading map")
		renderDossier()
		return
	end

	subtitle.Text = tostring(payload.RoleLabel or "Unknown")
		.. " | " .. tostring(payload.SocietyStatus or "Unknown")
		.. " | " .. tostring(payload.CurrentTerritory or "None")

	local locations = payload.Locations or {}
	for _, location in ipairs(locations) do
		makePin(location)
	end

	-- Keep whatever the player was reading; otherwise open on the worst active site, so
	-- the dossier is never a blank panel on first look.
	if not (selectedId and pinsById[selectedId]) then
		local worst, worstThreat = nil, -1
		for _, location in ipairs(locations) do
			local threat = tonumber(location.Threat) or 0
			if location.ActiveIncident and threat > worstThreat then
				worst, worstThreat = tostring(location.Id), threat
			end
		end
		selectedId = worst or (locations[1] and tostring(locations[1].Id)) or nil
	end

	highlightSelectedPin()
	if selectedId then
		moveMarkerTo(selectedId)
	end
	renderDossier()
end

function refreshAfterAction()
	if not isOpen then return end
	local ok, payload = pcall(function()
		return getIncidentMap:InvokeServer()
	end)
	if ok and payload then
		task.defer(function()
			if isOpen then
				renderAll(payload)
			end
		end)
	end
end

function loadMap()
	local ok, payload = pcall(function()
		return getIncidentMap:InvokeServer()
	end)
	if ok then
		renderAll(payload)
	else
		renderAll({ Error = "Incident Map failed to load: " .. tostring(payload) })
	end
end

local function openMap()
	isOpen = true
	gui.Enabled = true
	sheet.Visible = true
	sheet.BackgroundTransparency = 1
	TweenService:Create(sheet, TWEEN_FAST, { BackgroundTransparency = 0 }):Play()
	layout()
	loadMap()
end

local function closeMap()
	isOpen = false
	gui.Enabled = false
	sheet.Visible = false
end

----------------------------------------------------------------
-- BUILD
----------------------------------------------------------------

local function buildHeader(parent)
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundColor3 = theme.Panel
	header.BorderSizePixel = 0
	header.ZIndex = 10
	header.Parent = parent
	corner(header, 0)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.6, 0, 0, 20)
	title.Position = UDim2.new(0, 14, 0, 6)
	title.BackgroundTransparency = 1
	title.Text = _im("title", "INCIDENT MAP")
	title.TextColor3 = theme.Gold
	title.TextSize = 16
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 11
	title.Parent = header

	subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, -130, 0, 16)
	subtitle.Position = UDim2.new(0, 14, 0, 28)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = _im("loading", "Loading...")
	subtitle.TextColor3 = theme.SubText
	subtitle.TextSize = 11
	subtitle.Font = Enum.Font.GothamBold
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.TextTruncate = Enum.TextTruncate.AtEnd
	subtitle.ZIndex = 11
	subtitle.Parent = header

	local refreshBtn = Instance.new("TextButton")
	refreshBtn.AnchorPoint = Vector2.new(1, 0.5)
	refreshBtn.Position = UDim2.new(1, -52, 0.5, 0)
	refreshBtn.Size = UDim2.fromOffset(70, 32)
	refreshBtn.BackgroundColor3 = theme.Card
	refreshBtn.BorderSizePixel = 0
	refreshBtn.Text = _im("refresh", "REFRESH")
	refreshBtn.TextColor3 = theme.Blue
	refreshBtn.TextSize = 11
	refreshBtn.Font = Enum.Font.GothamBlack
	refreshBtn.AutoButtonColor = false
	refreshBtn.ZIndex = 12
	refreshBtn.Parent = header
	corner(refreshBtn, 8)
	bindTap(refreshBtn, loadMap)

	local closeBtn = Instance.new("TextButton")
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, -10, 0.5, 0)
	closeBtn.Size = UDim2.fromOffset(34, 34)
	closeBtn.BackgroundColor3 = theme.Card
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "X"
	closeBtn.TextColor3 = theme.Bad
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.AutoButtonColor = false
	closeBtn.ZIndex = 12
	closeBtn.Parent = header
	corner(closeBtn, 999)
	bindTap(closeBtn, function()
		uiState.closeRoute()
	end)
end

local function buildBoard(parent)
	board = Instance.new("Frame")
	board.Name = "Board"
	board.BackgroundColor3 = Color3.fromRGB(9, 9, 14)
	board.BorderSizePixel = 0
	board.ClipsDescendants = true
	board.Parent = parent
	corner(board, 10)
	stroke(board, theme.StrokeSoft, 1)

	mapImage = Instance.new("ImageLabel")
	mapImage.Name = "Tokyo"
	mapImage.Size = UDim2.fromScale(1, 1)
	mapImage.BackgroundTransparency = 1
	mapImage.Image = BitKaisenIncidentMap.MAP_IMAGE
	mapImage.ScaleType = Enum.ScaleType.Stretch
	mapImage.ZIndex = 1
	mapImage.Parent = board

	-- OpenStreetMap's licence requires this line to stay visible. Do not remove it.
	local credit = Instance.new("TextLabel")
	credit.Name = "MapCredit"
	credit.AnchorPoint = Vector2.new(1, 1)
	credit.Position = UDim2.new(1, -6, 1, -4)
	credit.Size = UDim2.fromOffset(200, 12)
	credit.BackgroundTransparency = 1
	credit.Text = BitKaisenIncidentMap.MAP_CREDIT
	credit.TextColor3 = Color3.fromRGB(150, 150, 170)
	credit.TextSize = 8
	credit.Font = Enum.Font.Gotham
	credit.TextXAlignment = Enum.TextXAlignment.Right
	credit.TextTransparency = 0.35
	credit.ZIndex = 9
	credit.Parent = board

	pinLayer = Instance.new("Frame")
	pinLayer.Name = "PinLayer"
	pinLayer.Size = UDim2.fromScale(1, 1)
	pinLayer.BackgroundTransparency = 1
	pinLayer.ZIndex = 4
	pinLayer.Parent = board

	-- The travelling marker: the same idea as the boat sailing between islands in
	-- BitSeas, moved onto a city.
	marker = Instance.new("Frame")
	marker.Name = "Marker"
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.Position = UDim2.fromScale(HOME_POINT.X, HOME_POINT.Y)
	marker.Size = UDim2.fromOffset(10, 10)
	marker.Rotation = 45
	marker.BackgroundColor3 = theme.Purple
	marker.BorderSizePixel = 0
	marker.ZIndex = 7
	marker.Parent = pinLayer
	stroke(marker, Color3.fromRGB(8, 8, 12), 2)
end

local function init()
	getIncidentMap = waitForRemote("GetIncidentMap", "RemoteFunction") :: RemoteFunction
	incidentMapAction = waitForRemote("IncidentMapAction", "RemoteEvent") :: RemoteEvent

	gui = Instance.new("ScreenGui")
	gui.Name = "BitKaisenMobileIncidentMapGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 639
	gui.Enabled = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	sheet = Instance.new("Frame")
	sheet.Name = "IncidentMapSheet"
	sheet.Size = UDim2.fromScale(1, 1)
	sheet.BackgroundColor3 = theme.Bg
	sheet.BorderSizePixel = 0
	sheet.Visible = false
	sheet.Parent = gui
	corner(sheet, 0)

	buildHeader(sheet)
	buildBoard(sheet)

	scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Dossier"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = theme.Stroke
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	scroll.Parent = sheet

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 16)
	pad.Parent = scroll

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 8)
	list.Parent = scroll

	layout()
	sheet:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)

	uiState.subscribe(function(route)
		if route == "incident_map" then
			openMap()
		else
			closeMap()
		end
	end)
end

return { init = init, open = openMap }
