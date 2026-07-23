-- Multiplayer Fase 4 ("Buscador y creación"): shown after picking "Público"
-- in WorldModePanel.luau, before ChooseWorldMode/loadOrStartLife ever runs.
-- Entrada Rápida reuses the exact Fase 1-3 flow (ChooseWorldMode("Public"),
-- no teleport, lands in "genesis") -- Search/Code/Create are the genuinely
-- new Fase 4 paths, all going through real TeleportService-backed worlds
-- via BK_WorldRegistryService (server side).
--
-- One single view (like BitSeas' own browser) instead of separate tabs --
-- Luisa flagged the first version (4 tabs) and the version before that
-- (one long scroll) as wrong/ugly. Search + world list are the dominant,
-- always-visible content; Quick Entry and Join Code are small pill buttons
-- above the list; Create toggles the list area to a compact form.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = require("@ui-state/remotes")

local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _g(key: string, fallback: string): string
	return BitKaisenLocale.tOrFallback(_L, "worldbrowser." .. key, nil, fallback)
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUI_NAME = "BitKaisenWorldBrowserGui"

local THEME = {
	Bg = Color3.fromRGB(13, 13, 20),
	Panel = Color3.fromRGB(19, 19, 29),
	Card = Color3.fromRGB(24, 24, 34),
	CardStroke = Color3.fromRGB(52, 48, 72),
	Stroke = Color3.fromRGB(116, 84, 165),
	Gold = Color3.fromRGB(255, 212, 94),
	Purple = Color3.fromRGB(156, 96, 246),
	Text = Color3.fromRGB(245, 241, 255),
	Muted = Color3.fromRGB(176, 169, 195),
	Red = Color3.fromRGB(220, 84, 90),
	Pill = Color3.fromRGB(40, 36, 54),
}

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

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 641
screenGui.Enabled = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.AutoLocalize = false
screenGui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.25
overlay.BorderSizePixel = 0
overlay.Size = UDim2.fromScale(1, 1)
overlay.Visible = false
overlay.Active = true
overlay.Parent = screenGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(600, 520)
panel.BackgroundColor3 = THEME.Bg
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = overlay

Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = THEME.Stroke
panelStroke.Thickness = 1
panelStroke.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(20, 16)
title.Size = UDim2.new(1, -120, 0, 26)
title.Text = _g("title", "World Browser")
title.TextColor3 = THEME.Gold
title.Font = Enum.Font.GothamBlack
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local backButton = Instance.new("TextButton")
backButton.Position = UDim2.new(1, -84, 0, 14)
backButton.Size = UDim2.fromOffset(64, 28)
backButton.Text = _g("back", "BACK")
backButton.TextColor3 = THEME.Text
backButton.Font = Enum.Font.GothamBlack
backButton.TextSize = 11
backButton.BackgroundColor3 = THEME.Pill
backButton.BorderSizePixel = 0
backButton.Parent = panel
Instance.new("UICorner", backButton).CornerRadius = UDim.new(0, 6)

-- ── Search row: text box + 3 small pill actions ───────────────────────────
local searchRow = Instance.new("Frame")
searchRow.Position = UDim2.fromOffset(20, 52)
searchRow.Size = UDim2.new(1, -40, 0, 32)
searchRow.BackgroundTransparency = 1
searchRow.Parent = panel

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, 0, 1, 0)
searchBox.BackgroundColor3 = Color3.fromRGB(14, 12, 20)
searchBox.BorderSizePixel = 0
searchBox.Text = ""
searchBox.PlaceholderText = "🔍  " .. _g("search_placeholder", "Search worlds by name...")
searchBox.PlaceholderColor3 = THEME.Muted
searchBox.TextColor3 = THEME.Text
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 13
searchBox.ClearTextOnFocus = false
searchBox.Parent = searchRow
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 6)
local searchPadding = Instance.new("UIPadding")
searchPadding.PaddingLeft = UDim.new(0, 10)
searchPadding.PaddingRight = UDim.new(0, 10)
searchPadding.Parent = searchBox

local actionRow = Instance.new("Frame")
actionRow.Position = UDim2.fromOffset(20, 92)
actionRow.Size = UDim2.new(1, -40, 0, 30)
actionRow.BackgroundTransparency = 1
actionRow.Parent = panel

local actionLayout = Instance.new("UIListLayout")
actionLayout.FillDirection = Enum.FillDirection.Horizontal
actionLayout.Padding = UDim.new(0, 8)
actionLayout.Parent = actionRow

local function makePillButton(parent, order, text)
	local btn = Instance.new("TextButton")
	btn.LayoutOrder = order
	btn.AutomaticSize = Enum.AutomaticSize.X
	btn.Size = UDim2.new(0, 0, 1, 0)
	btn.Text = text
	btn.TextColor3 = THEME.Text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.BackgroundColor3 = THEME.Pill
	btn.BorderSizePixel = 0
	btn.Parent = parent
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 15)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = btn
	return btn
end

local quickButton = makePillButton(actionRow, 1, "⚡ " .. _g("quick_entry_button", "QUICK ENTRY"))
local codeButton = makePillButton(actionRow, 2, "🔑 " .. _g("code_button_pill", "JOIN CODE"))
local createButton = makePillButton(actionRow, 3, "🏗️ " .. _g("create_button_pill", "CREATE WORLD"))

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.fromOffset(20, 130)
statusLabel.Size = UDim2.new(1, -40, 0, 18)
statusLabel.Text = ""
statusLabel.TextColor3 = THEME.Red
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = panel

local function setStatus(message: string, isError: boolean)
	statusLabel.Text = message or ""
	statusLabel.TextColor3 = isError and THEME.Red or THEME.Muted
end

-- ── Inline "join with code" row (hidden until CODE pill is tapped) ────────
local codeRow = Instance.new("Frame")
codeRow.Position = UDim2.fromOffset(20, 152)
codeRow.Size = UDim2.new(1, -40, 0, 34)
codeRow.BackgroundTransparency = 1
codeRow.Visible = false
codeRow.Parent = panel

local codeRowLayout = Instance.new("UIListLayout")
codeRowLayout.FillDirection = Enum.FillDirection.Horizontal
codeRowLayout.Padding = UDim.new(0, 8)
codeRowLayout.Parent = codeRow

local codeBoxHolder = Instance.new("Frame")
codeBoxHolder.Size = UDim2.new(1, -100, 1, 0)
codeBoxHolder.BackgroundTransparency = 1
codeBoxHolder.Parent = codeRow

local codeBox = Instance.new("TextBox")
codeBox.Size = UDim2.new(1, 0, 1, 0)
codeBox.BackgroundColor3 = Color3.fromRGB(14, 12, 20)
codeBox.BorderSizePixel = 0
codeBox.Text = ""
codeBox.PlaceholderText = "🔑  " .. _g("code_placeholder", "6-character code...")
codeBox.PlaceholderColor3 = THEME.Muted
codeBox.TextColor3 = THEME.Text
codeBox.Font = Enum.Font.Gotham
codeBox.TextSize = 13
codeBox.ClearTextOnFocus = false
codeBox.Parent = codeBoxHolder
Instance.new("UICorner", codeBox).CornerRadius = UDim.new(0, 6)
local codeBoxPadding = Instance.new("UIPadding")
codeBoxPadding.PaddingLeft = UDim.new(0, 10)
codeBoxPadding.PaddingRight = UDim.new(0, 10)
codeBoxPadding.Parent = codeBox

local codeSubmitButton = Instance.new("TextButton")
codeSubmitButton.Size = UDim2.fromOffset(92, 34)
codeSubmitButton.Text = _g("code_button", "JOIN")
codeSubmitButton.TextColor3 = THEME.Bg
codeSubmitButton.Font = Enum.Font.GothamBlack
codeSubmitButton.TextSize = 12
codeSubmitButton.BackgroundColor3 = THEME.Gold
codeSubmitButton.BorderSizePixel = 0
codeSubmitButton.Parent = codeRow
Instance.new("UICorner", codeSubmitButton).CornerRadius = UDim.new(0, 6)

-- ── Main content area: either the world list, or the create-world form ───
local contentArea = Instance.new("Frame")
contentArea.Position = UDim2.fromOffset(20, 152)
contentArea.Size = UDim2.new(1, -40, 1, -176)
contentArea.BackgroundTransparency = 1
contentArea.Parent = panel

local listScroll = Instance.new("ScrollingFrame")
listScroll.Size = UDim2.fromScale(1, 1)
listScroll.BackgroundTransparency = 1
listScroll.BorderSizePixel = 0
listScroll.ScrollBarThickness = 5
listScroll.ScrollBarImageColor3 = THEME.Purple
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
createForm.ScrollBarThickness = 5
createForm.ScrollBarImageColor3 = THEME.Purple
createForm.CanvasSize = UDim2.new(0, 0, 0, 0)
createForm.AutomaticCanvasSize = Enum.AutomaticSize.Y
createForm.Visible = false
createForm.Parent = contentArea

local createLayout = Instance.new("UIListLayout")
createLayout.SortOrder = Enum.SortOrder.LayoutOrder
createLayout.Padding = UDim.new(0, 10)
createLayout.Parent = createForm

-- Shown right after a successful RequestCreateWorld instead of teleporting
-- immediately -- per Luisa, the founder needs time to actually read/copy
-- the join code before getting yanked to the new server. The real teleport
-- now only fires when CONNECT NOW is pressed (via the same goToWorld/
-- RequestJoinWorld path the search list and Join Code row already use).
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
successTitle.TextColor3 = THEME.Gold
successTitle.Font = Enum.Font.GothamBlack
successTitle.TextSize = 15
successTitle.TextXAlignment = Enum.TextXAlignment.Left
successTitle.Parent = createSuccessView

local successHint = Instance.new("TextLabel")
successHint.LayoutOrder = 2
successHint.BackgroundTransparency = 1
successHint.Size = UDim2.new(1, 0, 0, 34)
successHint.Text = _g("create_success_hint", "Share this code so friends can join you. Tap the box below to select it, then copy (Ctrl+C, or press and hold on mobile).")
successHint.TextColor3 = THEME.Muted
successHint.Font = Enum.Font.Gotham
successHint.TextSize = 12
successHint.TextWrapped = true
successHint.TextXAlignment = Enum.TextXAlignment.Left
successHint.TextYAlignment = Enum.TextYAlignment.Top
successHint.Parent = createSuccessView

local codeDisplayBox = Instance.new("TextBox")
codeDisplayBox.LayoutOrder = 3
codeDisplayBox.Size = UDim2.new(1, 0, 0, 46)
codeDisplayBox.BackgroundColor3 = Color3.fromRGB(14, 12, 20)
codeDisplayBox.BorderSizePixel = 0
codeDisplayBox.Text = ""
codeDisplayBox.TextColor3 = THEME.Gold
codeDisplayBox.Font = Enum.Font.GothamBlack
codeDisplayBox.TextSize = 22
codeDisplayBox.ClearTextOnFocus = false
codeDisplayBox.TextXAlignment = Enum.TextXAlignment.Center
codeDisplayBox.Parent = createSuccessView
Instance.new("UICorner", codeDisplayBox).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", codeDisplayBox).Color = THEME.Gold

local connectNowButton = Instance.new("TextButton")
connectNowButton.LayoutOrder = 4
connectNowButton.Size = UDim2.new(0, 220, 0, 40)
connectNowButton.Text = "🔗 " .. _g("connect_now", "CONNECT NOW")
connectNowButton.TextColor3 = THEME.Bg
connectNowButton.Font = Enum.Font.GothamBlack
connectNowButton.TextSize = 13
connectNowButton.BackgroundColor3 = THEME.Gold
connectNowButton.BorderSizePixel = 0
connectNowButton.Parent = createSuccessView
Instance.new("UICorner", connectNowButton).CornerRadius = UDim.new(0, 6)

local function sectionLabel(parent, order, text)
	local label = Instance.new("TextLabel")
	label.LayoutOrder = order
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 18)
	label.Text = text
	label.TextColor3 = THEME.Purple
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function makeSmallButton(parent, order, text, selected)
	local btn = Instance.new("TextButton")
	btn.LayoutOrder = order
	btn.Size = UDim2.fromOffset(120, 30)
	btn.Text = text
	btn.TextColor3 = selected and THEME.Bg or THEME.Text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.BackgroundColor3 = selected and THEME.Gold or THEME.Pill
	btn.BorderSizePixel = 0
	btn.Parent = parent
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
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
	createButton.BackgroundColor3 = THEME.Pill
	createButton.TextColor3 = THEME.Text
end

local function showCreate()
	state.ShowingCreate = true
	state.ShowingCreateSuccess = false
	listScroll.Visible = false
	createForm.Visible = true
	createSuccessView.Visible = false
	createButton.BackgroundColor3 = THEME.Gold
	createButton.TextColor3 = THEME.Bg
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
			row.Size = UDim2.new(1, 0, 0, 68)
			row.BackgroundColor3 = THEME.Card
			row.BorderSizePixel = 0
			row.Parent = listScroll
			Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
			local rowStroke = Instance.new("UIStroke")
			rowStroke.Color = THEME.CardStroke
			rowStroke.Thickness = 1
			rowStroke.Parent = row

			local info = Instance.new("TextLabel")
			info.BackgroundTransparency = 1
			info.Position = UDim2.fromOffset(12, 4)
			info.Size = UDim2.new(1, -110, 0, 40)
			info.Text = "🌍 " .. tostring(worldRecord.Name or "Unnamed") .. "\n🗓️ " .. tostring(worldRecord.StartEra or "Modern Era") .. "   👥 " .. tostring(worldRecord.Population or 0) .. "/" .. tostring(worldRecord.MaxCapacity or "?")
			info.TextColor3 = THEME.Text
			info.Font = Enum.Font.GothamMedium
			info.TextSize = 12
			info.TextXAlignment = Enum.TextXAlignment.Left
			info.TextYAlignment = Enum.TextYAlignment.Center
			info.Parent = row

			-- Fase 8 (pedido de Luisa, referencia BitSeas): burbujas con los
			-- avatares reales de quienes están conectados ahora, no solo el
			-- número. Se solapan un poco, como en el "Departures" de BitSeas.
			local presentSouls = worldRecord.PresentSouls or {}
			local bubbleSize = 22
			local bubbleOverlap = 8
			for bi, soul in ipairs(presentSouls) do
				if bi > 5 then break end
				local bubble = Instance.new("ImageLabel")
				bubble.Position = UDim2.fromOffset(12 + (bi - 1) * (bubbleSize - bubbleOverlap), 46)
				bubble.Size = UDim2.fromOffset(bubbleSize, bubbleSize)
				bubble.BackgroundColor3 = Color3.fromRGB(25, 24, 34)
				bubble.BorderSizePixel = 0
				bubble.ZIndex = row.ZIndex + 2 - bi
				bubble.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(soul.UserId) .. "&w=48&h=48"
				bubble.Parent = row
				Instance.new("UICorner", bubble).CornerRadius = UDim.new(1, 0)
				local bubbleStroke = Instance.new("UIStroke")
				bubbleStroke.Color = THEME.Card
				bubbleStroke.Thickness = 2
				bubbleStroke.Parent = bubble
			end
			if #presentSouls > 5 then
				local overflow = Instance.new("TextLabel")
				overflow.Position = UDim2.fromOffset(12 + 5 * (bubbleSize - bubbleOverlap) + 2, 46)
				overflow.Size = UDim2.fromOffset(30, bubbleSize)
				overflow.BackgroundTransparency = 1
				overflow.Text = "+" .. tostring(#presentSouls - 5)
				overflow.TextColor3 = THEME.Muted
				overflow.Font = Enum.Font.GothamBold
				overflow.TextSize = 11
				overflow.TextXAlignment = Enum.TextXAlignment.Left
				overflow.Parent = row
			end

			local joinBtn = Instance.new("TextButton")
			joinBtn.AnchorPoint = Vector2.new(1, 0.5)
			joinBtn.Position = UDim2.new(1, -10, 0.5, 0)
			joinBtn.Size = UDim2.fromOffset(74, 28)
			joinBtn.Text = _g("join_button", "JOIN")
			joinBtn.TextColor3 = THEME.Bg
			joinBtn.Font = Enum.Font.GothamBlack
			joinBtn.TextSize = 11
			joinBtn.BackgroundColor3 = THEME.Gold
			joinBtn.BorderSizePixel = 0
			joinBtn.Parent = row
			Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 6)

			joinBtn.Activated:Connect(function()
				goToWorld(worldRecord.WorldId)
			end)
		end
	end

	if shown == 0 then
		local empty = Instance.new("TextLabel")
		empty.BackgroundTransparency = 1
		empty.Size = UDim2.new(1, 0, 0, 26)
		empty.Text = _g("search_empty", "No worlds found.")
		empty.TextColor3 = THEME.Muted
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 12
		empty.Parent = listScroll
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

quickButton.Activated:Connect(function()
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
	screenGui.Enabled = false
	overlay.Visible = false
	state.IsOpen = false
	state.Busy = false
end)

codeButton.Activated:Connect(function()
	state.CodeRowOpen = not state.CodeRowOpen
	codeRow.Visible = state.CodeRowOpen
	codeButton.BackgroundColor3 = state.CodeRowOpen and THEME.Gold or THEME.Pill
	codeButton.TextColor3 = state.CodeRowOpen and THEME.Bg or THEME.Text
	if state.CodeRowOpen then
		contentArea.Position = UDim2.fromOffset(20, 190)
		contentArea.Size = UDim2.new(1, -40, 1, -214)
	else
		contentArea.Position = UDim2.fromOffset(20, 152)
		contentArea.Size = UDim2.new(1, -40, 1, -176)
	end
end)

codeSubmitButton.Activated:Connect(function()
	local code = codeBox.Text
	if tostring(code or "") == "" then
		setStatus(_g("err_no_code", "Enter a code first."), true)
		return
	end
	goToWorld(code)
end)

createButton.Activated:Connect(function()
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
	nameBox.Size = UDim2.new(1, 0, 0, 34)
	nameBox.BackgroundColor3 = Color3.fromRGB(14, 12, 20)
	nameBox.BorderSizePixel = 0
	nameBox.Text = ""
	nameBox.PlaceholderText = "✏️  " .. _g("create_name_placeholder", "World name (optional)...")
	nameBox.PlaceholderColor3 = THEME.Muted
	nameBox.TextColor3 = THEME.Text
	nameBox.Font = Enum.Font.Gotham
	nameBox.TextSize = 13
	nameBox.ClearTextOnFocus = false
	nameBox.Parent = createForm
	Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 6)
	local nameBoxPadding = Instance.new("UIPadding")
	nameBoxPadding.PaddingLeft = UDim.new(0, 10)
	nameBoxPadding.PaddingRight = UDim.new(0, 10)
	nameBoxPadding.Parent = nameBox

	sectionLabel(createForm, 2, "🗓️  " .. _g("create_era_label", "STARTING ERA"))
	local eraRow = Instance.new("Frame")
	eraRow.LayoutOrder = 3
	eraRow.Size = UDim2.new(1, 0, 0, 30)
	eraRow.BackgroundTransparency = 1
	eraRow.Parent = createForm
	local eraLayout = Instance.new("UIListLayout")
	eraLayout.FillDirection = Enum.FillDirection.Horizontal
	eraLayout.Padding = UDim.new(0, 6)
	eraLayout.Parent = eraRow

	local eraButtons = {}
	local function refreshEraButtons()
		for era, btn in pairs(eraButtons) do
			local selected = state.SelectedEra == era
			btn.BackgroundColor3 = selected and THEME.Gold or THEME.Pill
			btn.TextColor3 = selected and THEME.Bg or THEME.Text
		end
	end
	for i, era in ipairs(ERA_OPTIONS) do
		local btn = makeSmallButton(eraRow, i, era, era == state.SelectedEra)
		eraButtons[era] = btn
		btn.Activated:Connect(function()
			state.SelectedEra = era
			refreshEraButtons()
		end)
	end

	sectionLabel(createForm, 4, "👥  " .. _g("create_capacity_label", "CAPACITY & TYPE"))

	local optionsRow = Instance.new("Frame")
	optionsRow.LayoutOrder = 5
	optionsRow.Size = UDim2.new(1, 0, 0, 30)
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
			btn.BackgroundColor3 = selected and THEME.Gold or THEME.Pill
			btn.TextColor3 = selected and THEME.Bg or THEME.Text
		end
	end
	for i, capacity in ipairs(CAPACITY_OPTIONS) do
		local btn = makeSmallButton(optionsRow, i, tostring(capacity), capacity == state.SelectedCapacity)
		btn.Size = UDim2.fromOffset(60, 30)
		capacityButtons[capacity] = btn
		btn.Activated:Connect(function()
			state.SelectedCapacity = capacity
			refreshCapacityButtons()
		end)
	end

	local openButton = makeSmallButton(optionsRow, 4, "🔓 " .. _g("create_type_open", "OPEN"), state.SelectedType == "Open")
	local codeTypeButton = makeSmallButton(optionsRow, 5, "🔒 " .. _g("create_type_code", "CODE ONLY"), state.SelectedType == "Code")
	openButton.Activated:Connect(function()
		state.SelectedType = "Open"
		openButton.BackgroundColor3 = THEME.Gold
		openButton.TextColor3 = THEME.Bg
		codeTypeButton.BackgroundColor3 = THEME.Pill
		codeTypeButton.TextColor3 = THEME.Text
	end)
	codeTypeButton.Activated:Connect(function()
		state.SelectedType = "Code"
		codeTypeButton.BackgroundColor3 = THEME.Gold
		codeTypeButton.TextColor3 = THEME.Bg
		openButton.BackgroundColor3 = THEME.Pill
		openButton.TextColor3 = THEME.Text
	end)

	local createSubmitButton = Instance.new("TextButton")
	createSubmitButton.LayoutOrder = 5
	createSubmitButton.Size = UDim2.new(0, 200, 0, 36)
	createSubmitButton.Text = _g("create_button", "CREATE WORLD")
	createSubmitButton.TextColor3 = THEME.Bg
	createSubmitButton.Font = Enum.Font.GothamBlack
	createSubmitButton.TextSize = 12
	createSubmitButton.BackgroundColor3 = THEME.Gold
	createSubmitButton.BorderSizePixel = 0
	createSubmitButton.Parent = createForm
	Instance.new("UICorner", createSubmitButton).CornerRadius = UDim.new(0, 6)

	createSubmitButton.Activated:Connect(function()
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
			-- Per Luisa: don't auto-teleport right away -- the server no
			-- longer does either (see requestCreateWorld in
			-- GameManager.server.luau). Show the real join code with room to
			-- actually copy it, and let CONNECT NOW below trigger the real
			-- teleport (reuses goToWorld/RequestJoinWorld) whenever she's
			-- ready.
			setStatus("", false)
			showCreateSuccess(tostring(result.WorldId), tostring(result.JoinCode or ""))
		else
			local message = (ok and typeof(result) == "table" and result.Message) or _g("err_create_failed", "Could not create the world.")
			setStatus(tostring(message), true)
		end
	end)

	connectNowButton.Activated:Connect(function()
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
	overlay.Visible = false
	screenGui.Enabled = false
end

local function open(onBack)
	state.OnBack = onBack
	state.IsOpen = true
	state.CodeRowOpen = false
	codeRow.Visible = false
	contentArea.Position = UDim2.fromOffset(20, 152)
	contentArea.Size = UDim2.new(1, -40, 1, -176)
	setStatus("", false)
	showList()
	screenGui.Enabled = true
	overlay.Visible = true
	refreshList()
end

backButton.Activated:Connect(function()
	close()
	if state.OnBack then
		state.OnBack()
	end
end)

return { open = open, close = close }
