local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local uiState = require("@ui-state/uiState")
local responsiveScale = require("@ui/responsiveScale")

local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _aff(key, fallback) return BitKaisenLocale.tOrFallback(_L, "affiliations." .. key, nil, fallback) end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getRelationships = ReplicatedStorage:WaitForChild("GetRelationships")
local relationshipAction = ReplicatedStorage:WaitForChild("RelationshipAction")

local COLORS = {
	Window = Color3.fromRGB(15, 15, 22),
	Card = Color3.fromRGB(22, 22, 30),
	Stroke = Color3.fromRGB(48, 48, 64),
	Text = Color3.fromRGB(235, 235, 245),
	SubText = Color3.fromRGB(165, 165, 185),
	Muted = Color3.fromRGB(110, 110, 130),
	Purple = Color3.fromRGB(180, 130, 255),
	Gold = Color3.fromRGB(255, 200, 90),
	Green = Color3.fromRGB(120, 240, 160),
	Red = Color3.fromRGB(210, 70, 80),
	Button = Color3.fromRGB(32, 32, 44),
}

local refreshStamp = 0
local refreshInProgress = false
local groupPages = {}
local isOpen = false

local function addCorner(obj, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = obj
end

local function addStroke(obj, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or COLORS.Stroke
	stroke.Thickness = thickness or 1
	stroke.Transparency = 0.15
	stroke.Parent = obj
end

local function getViewport()
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local function isPortraitViewport()
	local viewport = getViewport()
	return viewport.Y > viewport.X
end

local function isMobileViewport()
	local viewport = getViewport()
	return viewport.X < 900 or (UserInputService.TouchEnabled and viewport.Y > viewport.X)
end

local function makeText(parent, text, size, color, pos, sizeDim, bold)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = pos or UDim2.new(0, 0, 0, 0)
	label.Size = sizeDim or UDim2.new(1, 0, 0, 24)
	label.Text = text or ""
	label.TextColor3 = color or COLORS.Text
	label.TextSize = size or 14
	label.Font = bold and Enum.Font.GothamBlack or Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
	label.RichText = true
	label.ZIndex = 605
	label.Parent = parent
	return label
end

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenAffiliationsGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 622
gui.Enabled = false
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "AffiliationsOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.45
overlay.ZIndex = 600
overlay.Parent = gui

local window = Instance.new("Frame")
window.Name = "AffiliationsWindow"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.new(0.5, 0, 0.5, 0)
window.Size = UDim2.new(0.62, 0, 0.78, 0)
window.BackgroundColor3 = COLORS.Window
window.BorderSizePixel = 0
window.ZIndex = 601
window.Parent = overlay
addCorner(window, 14)
addStroke(window, Color3.fromRGB(120, 70, 150), 2)

local title = makeText(window, _aff("title", "AFFILIATIONS"), 24, COLORS.Text, UDim2.new(0, 26, 0, 20), UDim2.new(1, -96, 0, 32), true)
local subtitle = makeText(window, _aff("subtitle", "Clan, dojo, teachers, students, and rivals grouped from your current relationships."), 13, COLORS.SubText, UDim2.new(0, 26, 0, 54), UDim2.new(1, -96, 0, 38), false)

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 44, 0, 44)
close.Position = UDim2.new(1, -62, 0, 20)
close.BackgroundColor3 = COLORS.Button
close.BorderSizePixel = 0
close.Text = "X"
close.TextColor3 = COLORS.Red
close.TextSize = 18
close.Font = Enum.Font.GothamBlack
close.ZIndex = 606
close.Parent = window
addCorner(close, 10)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -52, 1, -110)
scroll.Position = UDim2.new(0, 26, 0, 92)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = COLORS.Purple
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ZIndex = 602
scroll.Parent = window

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 10)
layout.Parent = scroll
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 18)
end)

local function clearScroll()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
end

local function relationId(rel)
	return rel.Id or rel.RelationshipId or rel.Name
end

local GROUPS = {
	{ Key = "Clan", Title = "Clan Members", Roles = { Mother=true, Father=true, Caretaker=true, Sibling=true, Child=true, Spouse=true, Partner=true } },
	{ Key = "Dojo", Title = "Dojo Members", Roles = { Student=true, Ward=true, ["Mission Partner"]=true } },
	{ Key = "Teachers", Title = "Teachers", Roles = { Teacher=true, Sensei=true, ["Jujutsu High Teacher"]=true } },
	{ Key = "Students", Title = "Students", Roles = { Student=true, Ward=true, Child=true } },
	{ Key = "Rivals", Title = "Rivals", Roles = { Rival=true } },
	{ Key = "Notable", Title = "Notable Sorcerers", Roles = { ["Notable Sorcerer"]=true } },
}

local function groupedRelationships(list)
	local groups = {}
	for _, group in ipairs(GROUPS) do
		groups[group.Key] = {}
	end
	for _, rel in ipairs(list or {}) do
		local role = tostring(rel.Role or rel.Status or "Unknown")
		for _, group in ipairs(GROUPS) do
			if group.Roles[role] then
				table.insert(groups[group.Key], rel)
			end
		end
	end
	return groups
end

local refresh

local function actionButton(parent, text, color, x, rel, actionId)
	local b = Instance.new("TextButton")
	local mobile = parent:GetAttribute("MobileAffiliationCard") == true
	if mobile then
		local portrait = isPortraitViewport()
		local order = ({ spend_time = 1, train_together = 2, challenge = 3, argue = 4 })[actionId] or 1
		local col = (order - 1) % 2
		local row = math.floor((order - 1) / 2)
		local buttonWidth = portrait and 0.43 or 0.46
		local leftX = portrait and 0.05 or 0.04
		local rightX = portrait and 0.52 or 0.50
		b.Size = UDim2.new(buttonWidth, 0, 0, portrait and 30 or 26)
		b.Position = UDim2.new(col == 0 and leftX or rightX, 0, 1, row == 0 and -72 or -36)
	else
		b.Size = UDim2.new(0, 96, 0, 30)
		b.Position = UDim2.new(0, x, 1, -38)
	end
	b.BackgroundColor3 = color or COLORS.Button
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = COLORS.Text
	b.TextSize = mobile and 9 or 11
	b.TextScaled = false
	b.Font = Enum.Font.GothamBlack
	b.ZIndex = 606
	b.Parent = parent
	addCorner(b, 7)
	b.MouseButton1Click:Connect(function()
		local id = relationId(rel)
		if id then
			relationshipAction:FireServer(id, actionId)
			task.delay(0.35, function()
				if isOpen then refresh() end
			end)
		end
	end)
	return b
end

local function createStatusCard(text, color)
	clearScroll()
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -8, 0, 86)
	card.BackgroundColor3 = COLORS.Card
	card.BorderSizePixel = 0
	card.ZIndex = 603
	card.Parent = scroll
	addCorner(card, 8)
	addStroke(card)
	makeText(card, text, 14, color or COLORS.SubText, UDim2.new(0, 18, 0, 18), UDim2.new(1, -36, 0, 40), true)
end

local function getAffiliationPageSize()
	return isMobileViewport() and 3 or 5
end

local function createPageControls(groupKey, totalCount, currentPage, pageSize, layoutOrder)
	local totalPages = math.max(1, math.ceil(totalCount / pageSize))
	local controls = Instance.new("Frame")
	controls.Name = groupKey .. "PageControls"
	controls.Size = UDim2.new(1, -8, 0, 36)
	controls.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
	controls.BorderSizePixel = 0
	controls.LayoutOrder = layoutOrder
	controls.ZIndex = 603
	controls.Parent = scroll
	addCorner(controls, 8)
	addStroke(controls, Color3.fromRGB(36, 36, 50), 1)

	local info = makeText(controls, "Page " .. tostring(currentPage) .. "/" .. tostring(totalPages) .. " | " .. tostring(totalCount) .. " total", isMobileViewport() and 9 or 11, COLORS.SubText, UDim2.new(0, 12, 0, 10), UDim2.new(1, -164, 0, 16), true)
	info.TextWrapped = false
	info.TextTruncate = Enum.TextTruncate.AtEnd

	local function navButton(text, x, enabled, delta)
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0, 70, 0, 24)
		button.Position = UDim2.new(1, x, 0.5, -12)
		button.BackgroundColor3 = enabled and COLORS.Button or Color3.fromRGB(24, 24, 32)
		button.BorderSizePixel = 0
		button.TextColor3 = enabled and COLORS.Text or COLORS.Muted
		button.TextSize = 10
		button.Font = Enum.Font.GothamBlack
		button.Text = text
		button.Active = enabled
		button.AutoButtonColor = enabled
		button.ZIndex = 604
		button.Parent = controls
		addCorner(button, 7)
		if enabled then
			button.MouseButton1Click:Connect(function()
				groupPages[groupKey] = math.clamp(currentPage + delta, 1, totalPages)
				refresh()
			end)
		end
	end

	navButton(_aff("btn_prev", "PREV"), -150, currentPage > 1, -1)
	navButton(_aff("btn_next", "NEXT"), -76, currentPage < totalPages, 1)
end

function refresh()
	refreshStamp += 1
	local thisRefresh = refreshStamp
	refreshInProgress = true
	createStatusCard(_aff("loading", "Loading affiliations..."), COLORS.SubText)

	task.spawn(function()
		local ok, data = pcall(function()
			return getRelationships:InvokeServer()
		end)
		if refreshStamp ~= thisRefresh or not isOpen then
			refreshInProgress = false
			return
		end

		local list = ok and (typeof(data) == "table" and (data.Relationships or data) or {}) or {}
		if not ok then
			createStatusCard(_aff("error_load", "Could not load affiliations."), COLORS.Red)
			refreshInProgress = false
			return
		end

		clearScroll()
		local groups = groupedRelationships(list)
		local rendered = 0
		local function yieldIfNeeded()
			rendered += 1
			if rendered % 5 == 0 then
				scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 18)
				task.wait()
			end
		end

		for order, group in ipairs(GROUPS) do
			local entries = groups[group.Key] or {}
			local header = Instance.new("Frame")
			header.Size = UDim2.new(1, -8, 0, 36)
			header.BackgroundTransparency = 1
			header.LayoutOrder = order * 100
			header.ZIndex = 603
			header.Parent = scroll
			makeText(header, _aff("group_" .. string.lower(group.Key), group.Title) .. "  (" .. tostring(#entries) .. ")", 14, COLORS.Gold, UDim2.new(0, 0, 0, 8), UDim2.new(1, 0, 0, 24), true)

			if refreshStamp ~= thisRefresh or not isOpen then
				refreshInProgress = false
				return
			end

			if #entries == 0 then
				local empty = Instance.new("Frame")
				empty.Size = UDim2.new(1, -8, 0, 54)
				empty.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
				empty.BorderSizePixel = 0
				empty.LayoutOrder = order * 100 + 1
				empty.ZIndex = 603
				empty.Parent = scroll
				addCorner(empty, 8)
				addStroke(empty, Color3.fromRGB(36, 36, 50), 1)
				makeText(empty, _aff("none", "No entries yet."), 12, COLORS.Muted, UDim2.new(0, 18, 0, 18), UDim2.new(1, -36, 0, 22), false)
				yieldIfNeeded()
			else
				local pageSize = getAffiliationPageSize()
				local totalPages = math.max(1, math.ceil(#entries / pageSize))
				local currentPage = math.clamp(tonumber(groupPages[group.Key]) or 1, 1, totalPages)
				groupPages[group.Key] = currentPage
				local startIndex = ((currentPage - 1) * pageSize) + 1
				local endIndex = math.min(#entries, startIndex + pageSize - 1)
				if #entries > pageSize then
					createPageControls(group.Key, #entries, currentPage, pageSize, order * 100 + 1)
				end
				for index = startIndex, endIndex do
					local rel = entries[index]
					if refreshStamp ~= thisRefresh or not isOpen then
						refreshInProgress = false
						return
					end
					local card = Instance.new("Frame")
					local mobileCard = isMobileViewport()
					card:SetAttribute("MobileAffiliationCard", mobileCard)
					local portraitCard = mobileCard and isPortraitViewport()
					card.Size = UDim2.new(1, -8, 0, portraitCard and 176 or (mobileCard and 154 or 118))
					card.BackgroundColor3 = COLORS.Card
					card.BorderSizePixel = 0
					card.LayoutOrder = order * 100 + index + 1
					card.ZIndex = 603
					card.Parent = scroll
					addCorner(card, 8)
					addStroke(card)

					local name = tostring(rel.Name or "Unknown")
					local role = tostring(rel.Role or rel.Status or "Unknown")
					local age = tostring(rel.Age or "?")
					local grade = tostring(rel.Grade or rel.UnregisteredGrade or "Non-Sorcerer")
					local nameLabel = makeText(card, name, portraitCard and 13 or (mobileCard and 14 or 16), COLORS.Text, UDim2.new(0, 18, 0, 14), UDim2.new(1, -36, 0, 24), true)
					nameLabel.TextWrapped = false
					nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
					local status = tostring(rel.Status or "Active")
					local relation = tostring(rel.Relationship or role)
					local progressing = rel.Progressing == false and "Not progressing" or "Progressing"
					local summaryText = role .. " | Age " .. age .. " | " .. grade
					if role == "Notable Sorcerer" then
						summaryText = summaryText .. " | CE " .. tostring(rel.CursedEnergy or 0) .. " | Power " .. tostring(rel.Power or 0)
					end
					makeText(card, summaryText, portraitCard and 9 or (mobileCard and 10 or 12), COLORS.SubText, UDim2.new(0, 18, 0, 40), UDim2.new(1, -36, 0, portraitCard and 46 or (mobileCard and 34 or 22)), false)
					local detailText = status .. " | " .. relation .. " | " .. progressing
					if rel.PublicNote then
						detailText = tostring(rel.PublicNote)
					end
					makeText(card, detailText, portraitCard and 8 or (mobileCard and 9 or 11), COLORS.Muted, UDim2.new(0, 18, 0, portraitCard and 88 or (mobileCard and 72 or 62)), UDim2.new(1, -36, 0, portraitCard and 52 or (mobileCard and 42 or 34)), false)

					if rel.ReadOnly ~= true then
						actionButton(card, "HANG OUT", COLORS.Button, 18, rel, "spend_time")
						actionButton(card, "TRAIN", Color3.fromRGB(45, 80, 55), 122, rel, "train_together")
						actionButton(card, "RIVALRY", Color3.fromRGB(80, 55, 35), 226, rel, "challenge")
						actionButton(card, "BULLY", Color3.fromRGB(90, 35, 45), 330, rel, "argue")
					end
					yieldIfNeeded()
				end
			end
		end

		refreshInProgress = false
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 18)
	end)
end

responsiveScale.attach(window, 1190, 842)

local function openPanel()
	isOpen = true
	gui.Enabled = true
	window.BackgroundTransparency = 1
	TweenService:Create(window, TweenInfo.new(0.18), { BackgroundTransparency = 0 }):Play()
	refresh()
end

local function closePanel()
	isOpen = false
	refreshStamp += 1
	refreshInProgress = false
	window.BackgroundTransparency = 1
	gui.Enabled = false
end

close.MouseButton1Click:Connect(function()
	uiState.closeRoute()
end)

overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if input.Position then
			local absPos = window.AbsolutePosition
			local absSize = window.AbsoluteSize
			local x, y = input.Position.X, input.Position.Y
			if x < absPos.X or x > absPos.X + absSize.X or y < absPos.Y or y > absPos.Y + absSize.Y then
				uiState.closeRoute()
			end
		end
	end
end)

local function init()
	uiState.subscribe(function(route)
		if route == "affiliations" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
