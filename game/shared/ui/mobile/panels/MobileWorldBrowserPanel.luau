-- Mobile counterpart of WorldBrowserPanel.luau (PC). Multiplayer Fase 4
-- ("Buscador y creación") -- shown after picking "Público" in
-- MobileWorldModePanel.luau, before ChooseWorldMode/loadOrStartLife ever
-- runs. Same remotes, same logic, same one-single-view layout as PC (search
-- + world list dominant, small pill buttons for Quick/Code/Create, Create
-- toggles the list area to a compact form) -- mirrors the PC redesign.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local mc = require("@ui/mobile/mobileComponents")
local remotes = require("@ui-state/remotes")

local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _g(key: string, fallback: string): string
	return BitKaisenLocale.tOrFallback(_L, "worldbrowser." .. key, nil, fallback)
end

local theme = mc.theme
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUI_NAME = "BitKaisenMobileWorldBrowserGui"
local ERA_OPTIONS = { "Heian Era", "Edo Era", "Modern Era", "Collapse Era" }
local CAPACITY_OPTIONS = { 10, 20, 30 }

local state = {
	IsOpen = false,
	Busy = false,
	OnBack = nil,
	ShowingCreate = false,
	CodeRowOpen = false,
	SelectedEra = "Modern Era",
	SelectedType = "Open",
	SelectedCapacity = 10,
	ShowingCreateSuccess = false,
	PendingWorldId = nil :: string?,
}

local existing = playerGui:FindFirstChild(GUI_NAME)
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 641
gui.Enabled = false
gui.AutoLocalize = false
gui.Parent = playerGui

-- Opaque full-screen backdrop -- see MobileWorldModePanel.luau for why
-- (this used to be a 25%-transparent scrim with no opaque window behind
-- it, so the dashboard showed through).
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.BackgroundColor3 = theme.Bg
overlay.BackgroundTransparency = 0
overlay.BorderSizePixel = 0
overlay.Size = UDim2.fromScale(1, 1)
overlay.Active = true
overlay.Parent = gui

local header = Instance.new("Frame")
header.Position = UDim2.new(0, 12, 0, 36)
header.Size = UDim2.new(1, -24, 0, 34)
header.BackgroundTransparency = 1
header.Parent = overlay

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -80, 1, 0)
title.Text = _g("title", "World Browser")
title.TextColor3 = theme.Gold
title.Font = Enum.Font.GothamBlack
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local backButton = Instance.new("TextButton")
backButton.AnchorPoint = Vector2.new(1, 0)
backButton.Position = UDim2.new(1, 0, 0, 0)
backButton.Size = UDim2.fromOffset(64, 30)
backButton.Text = _g("back", "BACK")
backButton.TextColor3 = theme.Text
backButton.Font = Enum.Font.GothamBlack
backButton.TextSize = 11
backButton.BackgroundColor3 = theme.Panel
backButton.BorderSizePixel = 0
backButton.Parent = header
mc.corner(backButton, 6)

local searchBox = Instance.new("TextBox")
searchBox.Position = UDim2.new(0, 12, 0, 78)
searchBox.Size = UDim2.new(1, -24, 0, 32)
searchBox.BackgroundColor3 = theme.Panel
searchBox.BorderSizePixel = 0
searchBox.Text = ""
searchBox.PlaceholderText = "🔍  " .. _g("search_placeholder", "Search worlds by name...")
searchBox.PlaceholderColor3 = theme.SubText
searchBox.TextColor3 = theme.Text
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 12
searchBox.ClearTextOnFocus = false
searchBox.Parent = overlay
mc.corner(searchBox, 6)
local searchPadding = Instance.new("UIPadding")
searchPadding.PaddingLeft = UDim.new(0, 10)
searchPadding.PaddingRight = UDim.new(0, 10)
searchPadding.Parent = searchBox

local actionRow = Instance.new("Frame")
actionRow.Position = UDim2.new(0, 12, 0, 116)
actionRow.Size = UDim2.new(1, -24, 0, 28)
actionRow.BackgroundTransparency = 1
actionRow.Parent = overlay

local actionLayout = Instance.new("UIListLayout")
actionLayout.FillDirection = Enum.FillDirection.Horizontal
actionLayout.Padding = UDim.new(0, 6)
actionLayout.Parent = actionRow

local function makePillButton(parent, order, text)
	local btn = Instance.new("TextButton")
	btn.LayoutOrder = order
	btn.AutomaticSize = Enum.AutomaticSize.X
	btn.Size = UDim2.new(0, 0, 1, 0)
	btn.Text = text
	btn.TextColor3 = theme.Text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.BackgroundColor3 = theme.Panel
	btn.BorderSizePixel = 0
	btn.Parent = parent
	mc.corner(btn, 14)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = btn
	return btn
end

local quickButton = makePillButton(actionRow, 1, "⚡ " .. _g("quick_entry_button", "QUICK"))
local codeButton = makePillButton(actionRow, 2, "🔑 " .. _g("code_button_pill", "CODE"))
local createButton = makePillButton(actionRow, 3, "🏗️ " .. _g("create_button_pill", "CREATE"))

local statusLabel = Instance.new("TextLabel")
statusLabel.Position = UDim2.new(0, 12, 0, 150)
statusLabel.Size = UDim2.new(1, -24, 0, 18)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = theme.Bad
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = overlay

local function setStatus(message: string, isError: boolean)
	statusLabel.Text = message or ""
	statusLabel.TextColor3 = isError and theme.Bad or theme.SubText
end

-- ── Inline "join with code" row (hidden until CODE pill is tapped) ────────
local codeRow = Instance.new("Frame")
codeRow.Position = UDim2.new(0, 12, 0, 170)
codeRow.Size = UDim2.new(1, -24, 0, 34)
codeRow.BackgroundTransparency = 1
codeRow.Visible = false
codeRow.Parent = overlay

local codeRowLayout = Instance.new("UIListLayout")
codeRowLayout.FillDirection = Enum.FillDirection.Horizontal
codeRowLayout.Padding = UDim.new(0, 6)
codeRowLayout.Parent = codeRow

local codeBoxHolder = Instance.new("Frame")
codeBoxHolder.Size = UDim2.new(1, -84, 1, 0)
codeBoxHolder.BackgroundTransparency = 1
codeBoxHolder.Parent = codeRow

local codeBox = Instance.new("TextBox")
codeBox.Size = UDim2.new(1, 0, 1, 0)
codeBox.BackgroundColor3 = theme.Panel
codeBox.BorderSizePixel = 0
codeBox.Text = ""
codeBox.PlaceholderText = "🔑  " .. _g("code_placeholder", "6-character code...")
codeBox.PlaceholderColor3 = theme.SubText
codeBox.TextColor3 = theme.Text
codeBox.Font = Enum.Font.Gotham
codeBox.TextSize = 12
codeBox.ClearTextOnFocus = false
codeBox.Parent = codeBoxHolder
mc.corner(codeBox, 6)
local codeBoxPadding = Instance.new("UIPadding")
codeBoxPadding.PaddingLeft = UDim.new(0, 10)
codeBoxPadding.PaddingRight = UDim.new(0, 10)
codeBoxPadding.Parent = codeBox

local codeSubmitButton = Instance.new("TextButton")
codeSubmitButton.Size = UDim2.fromOffset(78, 34)
codeSubmitButton.Text = _g("code_button", "JOIN")
codeSubmitButton.TextColor3 = theme.Bg
codeSubmitButton.Font = Enum.Font.GothamBlack
codeSubmitButton.TextSize = 11
codeSubmitButton.BackgroundColor3 = theme.Gold
codeSubmitButton.BorderSizePixel = 0
codeSubmitButton.Parent = codeRow
mc.corner(codeSubmitButton, 6)

-- ── Main content area: either the world list, or the create-world form ───
local contentArea = Instance.new("Frame")
contentArea.Position = UDim2.new(0, 12, 0, 170)
contentArea.Size = UDim2.new(1, -24, 1, -182)
contentArea.BackgroundTransparency = 1
contentArea.Parent = overlay

local listScroll = Instance.new("ScrollingFrame")
listScroll.Size = UDim2.fromScale(1, 1)
listScroll.BackgroundTransparency = 1
listScroll.BorderSizePixel = 0
listScroll.ScrollBarThickness = 4
listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
listScroll.Parent = contentArea

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = listScroll

local createForm = Instance.new("ScrollingFrame")
createForm.Size = UDim2.fromScale(1, 1)
createForm.BackgroundTransparency = 1
createForm.BorderSizePixel = 0
createForm.ScrollBarThickness = 4
createForm.CanvasSize = UDim2.new(0, 0, 0, 0)
createForm.AutomaticCanvasSize = Enum.AutomaticSize.Y
createForm.Visible = false
createForm.Parent = contentArea

local createLayout = Instance.new("UIListLayout")
createLayout.SortOrder = Enum.SortOrder.LayoutOrder
createLayout.Padding = UDim.new(0, 10)
createLayout.Parent = createForm

-- See WorldBrowserPanel.luau (PC): shown right after a successful
-- RequestCreateWorld instead of teleporting immediately, so the founder has
-- time to actually read/copy the join code first.
local createSuccessView = Instance.new("Frame")
createSuccessView.Size = UDim2.fromScale(1, 1)
createSuccessView.BackgroundTransparency = 1
createSuccessView.Visible = false
createSuccessView.Parent = contentArea

local successLayout = Instance.new("UIListLayout")
successLayout.SortOrder = Enum.SortOrder.LayoutOrder
successLayout.Padding = UDim.new(0, 10)
successLayout.Parent = createSuccessView

local successTitle = Instance.new("TextLabel")
successTitle.LayoutOrder = 1
successTitle.BackgroundTransparency = 1
successTitle.Size = UDim2.new(1, 0, 0, 22)
successTitle.Text = "🌍 " .. _g("create_success_title", "WORLD CREATED!")
successTitle.TextColor3 = theme.Gold
successTitle.Font = Enum.Font.GothamBlack
successTitle.TextSize = 15
successTitle.TextXAlignment = Enum.TextXAlignment.Left
successTitle.Parent = createSuccessView

local successHint = Instance.new("TextLabel")
successHint.LayoutOrder = 2
successHint.BackgroundTransparency = 1
successHint.Size = UDim2.new(1, 0, 0, 46)
successHint.Text = _g("create_success_hint", "Share this code so friends can join you. Tap the box below to select it, then copy (Ctrl+C, or press and hold on mobile).")
successHint.TextColor3 = theme.SubText
successHint.Font = Enum.Font.Gotham
successHint.TextSize = 12
successHint.TextWrapped = true
successHint.TextXAlignment = Enum.TextXAlignment.Left
successHint.TextYAlignment = Enum.TextYAlignment.Top
successHint.Parent = createSuccessView

local codeDisplayBox = Instance.new("TextBox")
codeDisplayBox.LayoutOrder = 3
codeDisplayBox.Size = UDim2.new(1, 0, 0, 46)
codeDisplayBox.BackgroundColor3 = theme.Panel
codeDisplayBox.BorderSizePixel = 0
codeDisplayBox.Text = ""
codeDisplayBox.TextColor3 = theme.Gold
codeDisplayBox.Font = Enum.Font.GothamBlack
codeDisplayBox.TextSize = 22
codeDisplayBox.ClearTextOnFocus = false
codeDisplayBox.TextXAlignment = Enum.TextXAlignment.Center
codeDisplayBox.Parent = createSuccessView
mc.corner(codeDisplayBox, 6)
mc.stroke(codeDisplayBox, theme.Gold, 1)

local connectNowButton = Instance.new("TextButton")
connectNowButton.LayoutOrder = 4
connectNowButton.Size = UDim2.new(1, 0, 0, 44)
connectNowButton.Text = "🔗 " .. _g("connect_now", "CONNECT NOW")
connectNowButton.TextColor3 = theme.Bg
connectNowButton.Font = Enum.Font.GothamBlack
connectNowButton.TextSize = 13
connectNowButton.BackgroundColor3 = theme.Gold
connectNowButton.BorderSizePixel = 0
connectNowButton.Parent = createSuccessView
mc.corner(connectNowButton, 6)

local function makeSmallButton(parent, order, text, selected)
	local btn = Instance.new("TextButton")
	btn.LayoutOrder = order
	btn.Size = UDim2.fromOffset(96, 30)
	btn.Text = text
	btn.TextColor3 = selected and theme.Bg or theme.Text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.BackgroundColor3 = selected and theme.Gold or theme.Panel
	btn.BorderSizePixel = 0
	btn.Parent = parent
	mc.corner(btn, 6)
	return btn
end

local function goToWorld(worldIdOrCode)
	if state.Busy then
		return
	end
	local requestJoinWorld = remotes.get("RequestJoinWorld")
	if not requestJoinWorld then
		setStatus(_g("err_no_remote", "Could not reach the server."), true)
		return
	end
	state.Busy = true
	setStatus(_g("joining", "Joining world..."), false)
	local ok, result = pcall(function()
		return requestJoinWorld:InvokeServer(worldIdOrCode)
	end)
	state.Busy = false
	if ok and typeof(result) == "table" and result.Success == true then
		setStatus(_g("teleporting", "Teleporting..."), false)
	else
		local message = (ok and typeof(result) == "table" and result.Message) or _g("err_join_failed", "Could not join that world.")
		setStatus(tostring(message), true)
	end
end

local function showList()
	state.ShowingCreate = false
	state.ShowingCreateSuccess = false
	listScroll.Visible = true
	createForm.Visible = false
	createSuccessView.Visible = false
	createButton.BackgroundColor3 = theme.Panel
	createButton.TextColor3 = theme.Text
end

local function showCreate()
	state.ShowingCreate = true
	state.ShowingCreateSuccess = false
	listScroll.Visible = false
	createForm.Visible = true
	createSuccessView.Visible = false
	createButton.BackgroundColor3 = theme.Gold
	createButton.TextColor3 = theme.Bg
end

local function showCreateSuccess(worldId: string, code: string)
	state.ShowingCreateSuccess = true
	state.PendingWorldId = worldId
	listScroll.Visible = false
	createForm.Visible = false
	createSuccessView.Visible = true
	codeDisplayBox.Text = code
end

local function renderWorldList(worlds, filterText)
	for _, child in ipairs(listScroll:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local lowered = string.lower(filterText or "")
	local shown = 0
	for i, worldRecord in ipairs(worlds) do
		local matches = lowered == "" or string.find(string.lower(tostring(worldRecord.Name or "")), lowered, 1, true) ~= nil
		if matches then
			shown += 1
			local row = Instance.new("Frame")
			row.LayoutOrder = i
			row.Size = UDim2.new(1, 0, 0, 64)
			row.BackgroundColor3 = theme.Panel
			row.BorderSizePixel = 0
			row.Parent = listScroll
			mc.corner(row, 6)

			local info = Instance.new("TextLabel")
			info.BackgroundTransparency = 1
			info.Position = UDim2.fromOffset(10, 2)
			info.Size = UDim2.new(1, -94, 0, 38)
			info.Text = "🌍 " .. tostring(worldRecord.Name or "Unnamed") .. "\n🗓️ " .. tostring(worldRecord.StartEra or "Modern Era") .. "  👥 " .. tostring(worldRecord.Population or 0) .. "/" .. tostring(worldRecord.MaxCapacity or "?")
			info.TextColor3 = theme.Text
			info.TextWrapped = true
			info.Font = Enum.Font.GothamMedium
			info.TextSize = 11
			info.TextXAlignment = Enum.TextXAlignment.Left
			info.Parent = row

			-- Fase 8 (pedido de Luisa, referencia BitSeas): burbujas con los
			-- avatares reales de quienes están conectados ahora.
			local presentSouls = worldRecord.PresentSouls or {}
			local bubbleSize = 20
			local bubbleOverlap = 7
			for bi, soul in ipairs(presentSouls) do
				if bi > 5 then break end
				local bubble = Instance.new("ImageLabel")
				bubble.Position = UDim2.fromOffset(10 + (bi - 1) * (bubbleSize - bubbleOverlap), 42)
				bubble.Size = UDim2.fromOffset(bubbleSize, bubbleSize)
				bubble.BackgroundColor3 = Color3.fromRGB(25, 24, 34)
				bubble.BorderSizePixel = 0
				bubble.ZIndex = row.ZIndex + 2 - bi
				bubble.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(soul.UserId) .. "&w=48&h=48"
				bubble.Parent = row
				mc.corner(bubble, 10)
				local bubbleStroke = Instance.new("UIStroke")
				bubbleStroke.Color = theme.Panel
				bubbleStroke.Thickness = 2
				bubbleStroke.Parent = bubble
			end
			if #presentSouls > 5 then
				local overflow = Instance.new("TextLabel")
				overflow.Position = UDim2.fromOffset(10 + 5 * (bubbleSize - bubbleOverlap) + 2, 42)
				overflow.Size = UDim2.fromOffset(28, bubbleSize)
				overflow.BackgroundTransparency = 1
				overflow.Text = "+" .. tostring(#presentSouls - 5)
				overflow.TextColor3 = theme.SubText
				overflow.Font = Enum.Font.GothamBold
				overflow.TextSize = 10
				overflow.TextXAlignment = Enum.TextXAlignment.Left
				overflow.Parent = row
			end

			local joinBtn = Instance.new("TextButton")
			joinBtn.AnchorPoint = Vector2.new(1, 0.5)
			joinBtn.Position = UDim2.new(1, -8, 0.5, 0)
			joinBtn.Size = UDim2.fromOffset(74, 30)
			joinBtn.Text = _g("join_button", "JOIN")
			joinBtn.TextColor3 = theme.Bg
			joinBtn.Font = Enum.Font.GothamBlack
			joinBtn.TextSize = 11
			joinBtn.BackgroundColor3 = theme.Gold
			joinBtn.BorderSizePixel = 0
			joinBtn.Parent = row
			mc.corner(joinBtn, 6)

			mc.bindTap(joinBtn, function()
				goToWorld(worldRecord.WorldId)
			end)
		end
	end

	if shown == 0 then
		mc.mobileLabel({ parent = listScroll, text = _g("search_empty", "No worlds found."), size = 12, color = theme.SubText, order = 1 })
	end
end

local lastWorlds = {}
local function refreshList()
	if state.Busy then
		return
	end
	local getWorldBrowser = remotes.get("GetWorldBrowser")
	if not getWorldBrowser then
		setStatus(_g("err_no_remote", "Could not reach the server."), true)
		return
	end
	state.Busy = true
	local ok, result = pcall(function()
		return getWorldBrowser:InvokeServer()
	end)
	state.Busy = false
	if ok and typeof(result) == "table" then
		lastWorlds = result.Worlds or {}
		renderWorldList(lastWorlds, searchBox.Text)
	else
		setStatus(_g("err_search_failed", "Could not load the world list."), true)
	end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	renderWorldList(lastWorlds, searchBox.Text)
end)

mc.bindTap(quickButton, function()
	if state.Busy then
		return
	end
	local chooseWorldMode = remotes.get("ChooseWorldMode")
	if not chooseWorldMode then
		setStatus(_g("err_no_remote", "Could not reach the server."), true)
		return
	end
	state.Busy = true
	chooseWorldMode:FireServer("Public")
	gui.Enabled = false
	state.IsOpen = false
	state.Busy = false
end)

mc.bindTap(codeButton, function()
	state.CodeRowOpen = not state.CodeRowOpen
	codeRow.Visible = state.CodeRowOpen
	codeButton.BackgroundColor3 = state.CodeRowOpen and theme.Gold or theme.Panel
	codeButton.TextColor3 = state.CodeRowOpen and theme.Bg or theme.Text
	if state.CodeRowOpen then
		contentArea.Position = UDim2.new(0, 12, 0, 208)
		contentArea.Size = UDim2.new(1, -24, 1, -220)
	else
		contentArea.Position = UDim2.new(0, 12, 0, 170)
		contentArea.Size = UDim2.new(1, -24, 1, -182)
	end
end)

mc.bindTap(codeSubmitButton, function()
	local code = codeBox.Text
	if tostring(code or "") == "" then
		setStatus(_g("err_no_code", "Enter a code first."), true)
		return
	end
	goToWorld(code)
end)

mc.bindTap(createButton, function()
	if state.ShowingCreate then
		showList()
	else
		showCreate()
	end
end)

-- ── Create-world form content ─────────────────────────────────────────────
do
	local nameBox = Instance.new("TextBox")
	nameBox.LayoutOrder = 1
	nameBox.Size = UDim2.new(1, 0, 0, 36)
	nameBox.BackgroundColor3 = theme.Panel
	nameBox.BorderSizePixel = 0
	nameBox.Text = ""
	nameBox.PlaceholderText = "✏️  " .. _g("create_name_placeholder", "World name (optional)...")
	nameBox.PlaceholderColor3 = theme.SubText
	nameBox.TextColor3 = theme.Text
	nameBox.Font = Enum.Font.Gotham
	nameBox.TextSize = 13
	nameBox.ClearTextOnFocus = false
	nameBox.Parent = createForm
	mc.corner(nameBox, 6)
	local nameBoxPadding = Instance.new("UIPadding")
	nameBoxPadding.PaddingLeft = UDim.new(0, 10)
	nameBoxPadding.PaddingRight = UDim.new(0, 10)
	nameBoxPadding.Parent = nameBox

	mc.mobileLabel({ parent = createForm, text = "🗓️  " .. _g("create_era_label", "STARTING ERA"), size = 12, color = theme.SubText, font = Enum.Font.GothamBlack, order = 2 })
	local eraRow = Instance.new("Frame")
	eraRow.LayoutOrder = 3
	eraRow.Size = UDim2.new(1, 0, 0, 66)
	eraRow.BackgroundTransparency = 1
	eraRow.Parent = createForm
	local eraGrid = Instance.new("UIGridLayout")
	eraGrid.CellSize = UDim2.new(0.5, -4, 0, 30)
	eraGrid.CellPadding = UDim2.new(0, 8, 0, 6)
	eraGrid.Parent = eraRow

	local eraButtons = {}
	local function refreshEraButtons()
		for era, btn in pairs(eraButtons) do
			local selected = state.SelectedEra == era
			btn.BackgroundColor3 = selected and theme.Gold or theme.Panel
			btn.TextColor3 = selected and theme.Bg or theme.Text
		end
	end
	for _, era in ipairs(ERA_OPTIONS) do
		local btn = makeSmallButton(eraRow, 1, era, era == state.SelectedEra)
		btn.Size = UDim2.new(1, 0, 1, 0)
		eraButtons[era] = btn
		mc.bindTap(btn, function()
			state.SelectedEra = era
			refreshEraButtons()
		end)
	end

	mc.mobileLabel({ parent = createForm, text = "👥  " .. _g("create_capacity_label", "CAPACITY & TYPE"), size = 12, color = theme.SubText, font = Enum.Font.GothamBlack, order = 4 })

	local optionsRow = Instance.new("Frame")
	optionsRow.LayoutOrder = 5
	optionsRow.Size = UDim2.new(1, 0, 0, 32)
	optionsRow.BackgroundTransparency = 1
	optionsRow.Parent = createForm
	local optionsLayout = Instance.new("UIListLayout")
	optionsLayout.FillDirection = Enum.FillDirection.Horizontal
	optionsLayout.Padding = UDim.new(0, 6)
	optionsLayout.Parent = optionsRow

	local capacityButtons = {}
	local function refreshCapacityButtons()
		for capacity, btn in pairs(capacityButtons) do
			local selected = state.SelectedCapacity == capacity
			btn.BackgroundColor3 = selected and theme.Gold or theme.Panel
			btn.TextColor3 = selected and theme.Bg or theme.Text
		end
	end
	for _, capacity in ipairs(CAPACITY_OPTIONS) do
		local btn = makeSmallButton(optionsRow, 1, tostring(capacity), capacity == state.SelectedCapacity)
		btn.Size = UDim2.fromOffset(50, 30)
		capacityButtons[capacity] = btn
		mc.bindTap(btn, function()
			state.SelectedCapacity = capacity
			refreshCapacityButtons()
		end)
	end

	local openButton = makeSmallButton(optionsRow, 4, "🔓 " .. _g("create_type_open", "OPEN"), state.SelectedType == "Open")
	local codeTypeButton = makeSmallButton(optionsRow, 5, "🔒 " .. _g("create_type_code", "CODE"), state.SelectedType == "Code")
	mc.bindTap(openButton, function()
		state.SelectedType = "Open"
		openButton.BackgroundColor3 = theme.Gold
		openButton.TextColor3 = theme.Bg
		codeTypeButton.BackgroundColor3 = theme.Panel
		codeTypeButton.TextColor3 = theme.Text
	end)
	mc.bindTap(codeTypeButton, function()
		state.SelectedType = "Code"
		codeTypeButton.BackgroundColor3 = theme.Gold
		codeTypeButton.TextColor3 = theme.Bg
		openButton.BackgroundColor3 = theme.Panel
		openButton.TextColor3 = theme.Text
	end)

	local createSubmitButton = Instance.new("TextButton")
	createSubmitButton.LayoutOrder = 5
	createSubmitButton.Size = UDim2.new(1, 0, 0, 40)
	createSubmitButton.Text = _g("create_button", "CREATE WORLD")
	createSubmitButton.TextColor3 = theme.Bg
	createSubmitButton.Font = Enum.Font.GothamBlack
	createSubmitButton.TextSize = 13
	createSubmitButton.BackgroundColor3 = theme.Gold
	createSubmitButton.BorderSizePixel = 0
	createSubmitButton.Parent = createForm
	mc.corner(createSubmitButton, 6)

	mc.bindTap(createSubmitButton, function()
		if state.Busy then
			return
		end
		local requestCreateWorld = remotes.get("RequestCreateWorld")
		if not requestCreateWorld then
			setStatus(_g("err_no_remote", "Could not reach the server."), true)
			return
		end
		state.Busy = true
		setStatus(_g("creating", "Creating world..."), false)
		local ok, result = pcall(function()
			return requestCreateWorld:InvokeServer({
				Name = nameBox.Text,
				StartEra = state.SelectedEra,
				Type = state.SelectedType,
				MinSouls = 1,
				MaxCapacity = state.SelectedCapacity,
			})
		end)
		state.Busy = false
		if ok and typeof(result) == "table" and result.Success == true then
			-- See WorldBrowserPanel.luau (PC): don't auto-teleport -- the
			-- server no longer does either. Show the join code with room to
			-- copy it; CONNECT NOW triggers the real teleport when ready.
			setStatus("", false)
			showCreateSuccess(tostring(result.WorldId), tostring(result.JoinCode or ""))
		else
			local message = (ok and typeof(result) == "table" and result.Message) or _g("err_create_failed", "Could not create the world.")
			setStatus(tostring(message), true)
		end
	end)

	mc.bindTap(connectNowButton, function()
		if state.PendingWorldId then
			goToWorld(state.PendingWorldId)
		end
	end)
end

local function close()
	if not state.IsOpen then
		return
	end
	state.IsOpen = false
	gui.Enabled = false
end

local function open(onBack)
	state.OnBack = onBack
	state.IsOpen = true
	state.CodeRowOpen = false
	codeRow.Visible = false
	contentArea.Position = UDim2.new(0, 12, 0, 170)
	contentArea.Size = UDim2.new(1, -24, 1, -182)
	setStatus("", false)
	showList()
	gui.Enabled = true
	refreshList()
end

mc.bindTap(backButton, function()
	close()
	if state.OnBack then
		state.OnBack()
	end
end)

return { open = open, close = close }
