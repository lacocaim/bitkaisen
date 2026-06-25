local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local mc = require("@ui/mobile/mobileComponents")

local theme = mc.theme
local bindTap = mc.bindTap
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

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
local scroll: ScrollingFrame
local subtitle: TextLabel

local isOpen = false
local currentPayload = nil
local busy = false

local getIncidentMap: RemoteFunction
local incidentMapAction: RemoteEvent

local renderMap
local loadMap
local closeMap

local function clearScroll()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
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
				task.defer(function()
					if isOpen then
						renderMap(currentPayload)
					end
				end)
			end
		end
	end)
end

local function makeLocationCard(location, actions, role)
	local card = mc.mobileCard({
		parent = scroll,
		color = theme.Card,
		accentColor = location.ActiveIncident and Color3.fromRGB(105, 32, 44) or theme.Stroke,
	})

	mc.mobileLabel({
		parent = card,
		text = tostring(location.Name or "Unknown"),
		size = 16,
		color = theme.Text,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	mc.mobileLabel({
		parent = card,
		text = tostring(location.Description or ""),
		size = 12,
		color = theme.SubText,
		font = Enum.Font.GothamMedium,
		order = 2,
	})

	local statsRow = Instance.new("Frame")
	statsRow.Size = UDim2.new(1, 0, 0, 0)
	statsRow.AutomaticSize = Enum.AutomaticSize.Y
	statsRow.BackgroundTransparency = 1
	statsRow.LayoutOrder = 3
	statsRow.Parent = card

	local statsGrid = Instance.new("UIGridLayout")
	statsGrid.CellSize = UDim2.new(0.5, -4, 0, 18)
	statsGrid.CellPadding = UDim2.new(0, 6, 0, 4)
	statsGrid.SortOrder = Enum.SortOrder.LayoutOrder
	statsGrid.Parent = statsRow

	local stats = {
		{ "Threat: " .. tostring(location.Threat or 0) .. "%", statColor(location.Threat) },
		{ "Fear: " .. tostring(location.Fear or 0) .. "%", statColor(location.Fear) },
		{ "Attn: " .. tostring(location.SocietyAttention or 0) .. "%", statColor(location.SocietyAttention, "bad") },
		{ "Residue: " .. tostring(location.CursedResidue or 0) .. "%", statColor(location.CursedResidue) },
		{ "Control: " .. tostring(location.Control or 0) .. "%", theme.Purple },
		{ "Grade: " .. tostring(location.RecommendedGrade or "?"), theme.Gold },
	}

	for i, stat in ipairs(stats) do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = stat[2]
		label.TextSize = 11
		label.Font = Enum.Font.GothamBold
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = stat[1]
		label.LayoutOrder = i
		label.Parent = statsRow
	end

	local rumorText = "Rumor: " .. tostring(location.Rumor or "None") .. " | " .. (location.ActiveIncident and "Active Incident" or "Quiet")
	mc.mobileLabel({
		parent = card,
		text = rumorText,
		size = 11,
		color = theme.Purple,
		font = Enum.Font.GothamBold,
		order = 4,
	})

	local btnHolder = Instance.new("Frame")
	btnHolder.Size = UDim2.new(1, 0, 0, 0)
	btnHolder.AutomaticSize = Enum.AutomaticSize.Y
	btnHolder.BackgroundTransparency = 1
	btnHolder.LayoutOrder = 5
	btnHolder.Parent = card

	local btnGrid = Instance.new("UIGridLayout")
	btnGrid.CellSize = UDim2.new(0.5, -4, 0, 40)
	btnGrid.CellPadding = UDim2.new(0, 6, 0, 6)
	btnGrid.SortOrder = Enum.SortOrder.LayoutOrder
	btnGrid.Parent = btnHolder

	local made = 0
	for _, action in ipairs(actions or {}) do
		if made >= 4 then break end
		made += 1
		mc.mobileButton({
			parent = btnHolder,
			text = tostring(action.Name or action.Id),
			size = UDim2.new(1, 0, 1, 0),
			color = action.Locked and Color3.fromRGB(30, 30, 36) or theme.Button,
			textColor = action.Locked and theme.Muted or (role == "CursedSpirit" and theme.Purple or theme.Blue),
			textSize = 12,
			order = made,
			callback = function()
				if action.Locked then return end
				doAction(location.Id, action.Id)
			end,
		})
	end
end

function renderMap(payload)
	clearScroll()
	currentPayload = payload

	if not payload or payload.Error then
		mc.mobileLabel({
			parent = scroll,
			text = tostring(payload and payload.Error or "Could not load Incident Map."),
			size = 13,
			color = theme.Bad,
			order = 1,
		})
		subtitle.Text = "Error loading map"
		return
	end

	subtitle.Text = tostring(payload.RoleLabel or "Unknown") .. " | " .. tostring(payload.SocietyStatus or "Unknown") .. " | " .. tostring(payload.CurrentTerritory or "None")

	for _, location in ipairs(payload.Locations or {}) do
		makeLocationCard(location, payload.Actions or {}, tostring(payload.Role or "Sorcerer"))
	end
end

function loadMap()
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
	sheet.Visible = true
	sheet.BackgroundTransparency = 1
	TweenService:Create(sheet, TWEEN_FAST, { BackgroundTransparency = 0 }):Play()
	loadMap()
end

function closeMap()
	isOpen = false
	TweenService:Create(sheet, TWEEN_FAST, { BackgroundTransparency = 1 }):Play()
	task.delay(0.16, function()
		if not isOpen then
			sheet.Visible = false
			gui.Enabled = false
		end
	end)
end

local function buildHeader(parent)
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundColor3 = theme.Panel
	header.BorderSizePixel = 0
	header.Parent = parent
	mc.corner(header, 0)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.6, 0, 0, 20)
	title.Position = UDim2.new(0, 14, 0, 6)
	title.BackgroundTransparency = 1
	title.Text = "INCIDENT MAP"
	title.TextColor3 = theme.Gold
	title.TextSize = 16
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, -130, 0, 16)
	subtitle.Position = UDim2.new(0, 14, 0, 28)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Loading..."
	subtitle.TextColor3 = theme.SubText
	subtitle.TextSize = 11
	subtitle.Font = Enum.Font.GothamBold
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.TextWrapped = true
	subtitle.Parent = header

	local refreshBtn = Instance.new("TextButton")
	refreshBtn.AnchorPoint = Vector2.new(1, 0.5)
	refreshBtn.Position = UDim2.new(1, -52, 0.5, 0)
	refreshBtn.Size = UDim2.fromOffset(70, 32)
	refreshBtn.BackgroundColor3 = theme.Card
	refreshBtn.BorderSizePixel = 0
	refreshBtn.Text = "REFRESH"
	refreshBtn.TextColor3 = theme.Blue
	refreshBtn.TextSize = 11
	refreshBtn.Font = Enum.Font.GothamBlack
	refreshBtn.AutoButtonColor = false
	refreshBtn.Parent = header
	mc.corner(refreshBtn, 8)
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
	closeBtn.Parent = header
	mc.corner(closeBtn, 999)
	bindTap(closeBtn, closeMap)
end

local function init()
	getIncidentMap = ReplicatedStorage:WaitForChild("GetIncidentMap")
	incidentMapAction = ReplicatedStorage:WaitForChild("IncidentMapAction")

	gui = Instance.new("ScreenGui")
	gui.Name = "BitKaisenMobileIncidentMapGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 638
	gui.Enabled = false
	gui.Parent = playerGui

	sheet = Instance.new("Frame")
	sheet.Name = "IncidentMapSheet"
	sheet.Size = UDim2.fromScale(1, 1)
	sheet.BackgroundColor3 = theme.Bg
	sheet.BorderSizePixel = 0
	sheet.Visible = false
	sheet.Parent = gui
	mc.corner(sheet, 0)

	buildHeader(sheet)
	scroll = mc.mobileList(sheet)
end

return { init = init, open = openMap }
