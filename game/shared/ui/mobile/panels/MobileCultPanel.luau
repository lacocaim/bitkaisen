local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local uiState = require("@ui-state/uiState")
local mc = require("@ui/mobile/mobileComponents")
local BitKaisenCultData = require(ReplicatedStorage:WaitForChild("BitKaisenCultData"))

local theme = mc.theme
local corner = mc.corner
local stroke = mc.stroke
local bindTap = mc.bindTap
local mobileButton = mc.mobileButton
local mobileCard = mc.mobileCard
local mobileLabel = mc.mobileLabel
local mobileSheet = mc.mobileSheet

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getCult = ReplicatedStorage:WaitForChild("GetCult")
local cultAction = ReplicatedStorage:WaitForChild("CultAction")

local gui: ScreenGui
local sheet: Frame
local scroll: ScrollingFrame
local statusLabel: TextLabel
local tabHolder: Frame

local isOpen = false
local busy = false
local currentTab = "Overview"
local currentData: { [string]: any }? = nil

local tabs: { [string]: TextButton } = {}
local TAB_NAMES = { "Overview", "Members", "Actions", "History" }
local TAB_LABELS = { Overview = "Overview", Members = "Members", Actions = "Actions", History = "History" }

local ROLE_COLORS = {
	CultInitiate = Color3.fromRGB(190, 190, 205),
	CultDisciple = Color3.fromRGB(200, 170, 90),
	CultLieutenant = Color3.fromRGB(200, 70, 80),
}

local FOCUS_NAMES = { "Fear", "Ritual", "Conversion" }

local ACTION_ORDER = {
	"Cult_RecruitInitiate",
	"Cult_BindingRitual",
	"Cult_CollectTribute",
	"Cult_ExpandTerritory",
	"Cult_ReviewMembers",
	"Cult_SupplyRun",
	"Cult_CurseFusion",
}

local refresh: () -> ()

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------
local function clampPercent(value)
	return math.clamp(math.floor(tonumber(value) or 0), 0, 100)
end

local function roleColor(role)
	return ROLE_COLORS[tostring(role or "")] or Color3.fromRGB(190, 190, 205)
end

local function clearScroll()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function setStatus(text, color)
	if statusLabel then
		statusLabel.Text = text or ""
		statusLabel.TextColor3 = color or theme.Muted
	end
end

----------------------------------------------------------------
-- ACTION FIRER
----------------------------------------------------------------
local function fireCultAction(actionId, targetId)
	if busy then
		setStatus("Please wait...", theme.Gold)
		return
	end
	busy = true
	setStatus("Processing...", theme.Gold)
	cultAction:FireServer(actionId, targetId)
	task.delay(0.35, function()
		busy = false
		if isOpen then
			setStatus("Updated.", theme.Green)
			task.delay(1.2, function()
				if isOpen and statusLabel and statusLabel.Text == "Updated." then
					setStatus("")
				end
			end)
		end
	end)
end

----------------------------------------------------------------
-- TABS
----------------------------------------------------------------
local function setTab(name)
	currentTab = name
	for tabName, btn in pairs(tabs) do
		if tabName == name then
			btn.BackgroundColor3 = Color3.fromRGB(140, 20, 30)
			btn.TextColor3 = theme.Text
		else
			btn.BackgroundColor3 = theme.Button
			btn.TextColor3 = theme.SubText
		end
	end
end

local function buildTabs()
	tabHolder = Instance.new("Frame")
	tabHolder.Name = "CultTabs"
	tabHolder.Size = UDim2.new(1, -20, 0, 40)
	tabHolder.Position = UDim2.new(0, 10, 0, 50)
	tabHolder.BackgroundTransparency = 1
	tabHolder.Parent = sheet

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = tabHolder

	for i, tabName in ipairs(TAB_NAMES) do
		local btn = Instance.new("TextButton")
		btn.Name = tabName .. "Tab"
		btn.Size = UDim2.new(0.25, -4, 1, 0)
		btn.BackgroundColor3 = theme.Button
		btn.BorderSizePixel = 0
		btn.TextColor3 = theme.SubText
		btn.TextSize = 11
		btn.Font = Enum.Font.GothamBlack
		btn.Text = string.upper(TAB_LABELS[tabName])
		btn.AutoButtonColor = false
		btn.LayoutOrder = i
		btn.Parent = tabHolder
		corner(btn, 8)
		stroke(btn, theme.Stroke)
		bindTap(btn, function()
			setTab(tabName)
			refresh()
		end)
		tabs[tabName] = btn
	end
end

----------------------------------------------------------------
-- STAT BAR (Devotion / Trust / Fear / Loyalty / Territory)
----------------------------------------------------------------
local function makeStatBar(parent, labelText, value, color, order)
	local clamped = clampPercent(value)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 20)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order or 0
	row.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 64, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.TextSize = 11
	label.Font = Enum.Font.GothamBlack
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = labelText
	label.Parent = row

	local back = Instance.new("Frame")
	back.Size = UDim2.new(1, -110, 0, 7)
	back.Position = UDim2.new(0, 64, 0.5, -3)
	back.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	back.BorderSizePixel = 0
	back.Parent = row
	corner(back, 999)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(clamped / 100, 0, 1, 0)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = back
	corner(fill, 999)

	local percent = Instance.new("TextLabel")
	percent.Size = UDim2.new(0, 38, 1, 0)
	percent.AnchorPoint = Vector2.new(1, 0)
	percent.Position = UDim2.new(1, 0, 0, 0)
	percent.BackgroundTransparency = 1
	percent.TextColor3 = Color3.fromRGB(170, 170, 185)
	percent.TextSize = 10
	percent.Font = Enum.Font.GothamBold
	percent.TextXAlignment = Enum.TextXAlignment.Right
	percent.Text = tostring(clamped) .. "%"
	percent.Parent = row
end

local function addEmptyCard(text, order)
	local card = mobileCard({ parent = scroll, order = order or 0 })
	mobileLabel({ parent = card, text = text, size = 14, color = theme.SubText, order = 1 })
end

----------------------------------------------------------------
-- OVERVIEW TAB
----------------------------------------------------------------
local function buildOverviewTab(data)
	local card = mobileCard({ parent = scroll, order = 0 })
	mobileLabel({
		parent = card,
		text = tostring(data.Rank or "No Cult") .. "  •  Infamy " .. tostring(data.Infamy or 0),
		size = 16, color = theme.Text, font = Enum.Font.GothamBlack, order = 1,
	})
	mobileLabel({
		parent = card,
		text = "Members " .. tostring(data.Members or 0) .. "  •  Treasury $" .. tostring(data.Treasury or 0),
		size = 12, color = theme.SubText, order = 2,
	})
	mobileLabel({
		parent = card,
		text = "Territory: " .. tostring(data.Territory or "None"),
		size = 12, color = theme.SubText, order = 3,
	})

	local barsHolder = Instance.new("Frame")
	barsHolder.Size = UDim2.new(1, 0, 0, 54)
	barsHolder.BackgroundTransparency = 1
	barsHolder.LayoutOrder = 4
	barsHolder.Parent = card
	local barsLayout = Instance.new("UIListLayout")
	barsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	barsLayout.Padding = UDim.new(0, 6)
	barsLayout.Parent = barsHolder
	makeStatBar(barsHolder, "Loyalty", data.Loyalty, theme.Green, 1)
	makeStatBar(barsHolder, "Territory", data.TerritoryControl, theme.Gold, 2)

	local focusRow = Instance.new("Frame")
	focusRow.Size = UDim2.new(1, 0, 0, 36)
	focusRow.BackgroundTransparency = 1
	focusRow.LayoutOrder = 5
	focusRow.Parent = card
	local focusLayout = Instance.new("UIListLayout")
	focusLayout.FillDirection = Enum.FillDirection.Horizontal
	focusLayout.SortOrder = Enum.SortOrder.LayoutOrder
	focusLayout.Padding = UDim.new(0, 6)
	focusLayout.Parent = focusRow

	for i, focusName in ipairs(FOCUS_NAMES) do
		local isActive = data.Focus == focusName
		mobileButton({
			parent = focusRow,
			text = string.upper(focusName),
			size = UDim2.new(0.333, -4, 1, 0),
			color = isActive and Color3.fromRGB(140, 20, 30) or theme.Button,
			textColor = isActive and theme.Text or theme.SubText,
			textSize = 12,
			order = i,
			callback = function()
				if not isActive then
					fireCultAction("Cult_SetFocus", focusName)
				end
			end,
		})
	end
end

----------------------------------------------------------------
-- MEMBERS TAB
----------------------------------------------------------------
local function buildMembersTab(data)
	local roster = data.Roster or {}
	if #roster <= 0 then
		addEmptyCard("Your cult has no members yet. Recruit initiates from Activities.", 0)
		return
	end

	for i, member in ipairs(roster) do
		local card = mobileCard({ parent = scroll, order = i, accentColor = roleColor(member.Role) })
		mobileLabel({
			parent = card, text = tostring(member.Name or "Unknown") .. "  •  " .. tostring(member.Role or "Unknown"),
			size = 14, color = theme.Text, font = Enum.Font.GothamBlack, order = 1,
		})

		local barsHolder = Instance.new("Frame")
		barsHolder.Size = UDim2.new(1, 0, 0, 66)
		barsHolder.BackgroundTransparency = 1
		barsHolder.LayoutOrder = 2
		barsHolder.Parent = card
		local barsLayout = Instance.new("UIListLayout")
		barsLayout.SortOrder = Enum.SortOrder.LayoutOrder
		barsLayout.Padding = UDim.new(0, 6)
		barsLayout.Parent = barsHolder
		makeStatBar(barsHolder, "Devotion", member.Devotion, Color3.fromRGB(200, 90, 200), 1)
		makeStatBar(barsHolder, "Trust", member.Trust, Color3.fromRGB(90, 170, 230), 2)
		makeStatBar(barsHolder, "Fear", member.Fear, Color3.fromRGB(210, 90, 90), 3)
	end
end

----------------------------------------------------------------
-- ACTIONS TAB
----------------------------------------------------------------
local function buildActionsTab(data)
	local actions = data.Actions or {}
	local rankIndex = BitKaisenCultData.GetRankIndex(data.Rank)

	for i, actionId in ipairs(ACTION_ORDER) do
		local def = actions[actionId]
		if def then
			local enabled = true
			local lockedReason = nil
			if def.MinRank then
				local minRankIndex = BitKaisenCultData.GetRankIndex(def.MinRank)
				if rankIndex < minRankIndex then
					enabled = false
					lockedReason = "Requires: " .. tostring(def.MinRank)
				end
			end

			local card = mobileCard({ parent = scroll, order = i })
			mobileLabel({
				parent = card, text = tostring(def.Name or actionId),
				size = 15, color = theme.Text, font = Enum.Font.GothamBlack, order = 1,
			})
			mobileLabel({
				parent = card, text = lockedReason or tostring(def.Description or ""),
				size = 12, color = lockedReason and theme.Bad or theme.SubText, order = 2,
			})

			if enabled then
				mobileButton({
					parent = card, text = "DO IT", order = 3,
					size = UDim2.new(1, 0, 0, 44), color = Color3.fromRGB(140, 20, 30),
					textSize = 14, callback = function() fireCultAction(actionId) end,
				})
			else
				local btn = mobileButton({
					parent = card, text = "LOCKED", order = 3,
					size = UDim2.new(1, 0, 0, 44), color = theme.Button,
					textColor = theme.SubText, textSize = 14, callback = function() end,
				})
				btn.Active = false
			end
		end
	end
end

----------------------------------------------------------------
-- HISTORY TAB
----------------------------------------------------------------
local function buildHistoryTab(data)
	local history = data.History or {}
	if #history <= 0 then
		addEmptyCard("Your cult has no recorded history yet.", 0)
		return
	end

	local order = 0
	for i = #history, 1, -1 do
		order += 1
		local entry = history[i]
		local card = mobileCard({ parent = scroll, order = order })
		mobileLabel({
			parent = card,
			text = "<b>Year " .. tostring(entry.Year or 0) .. ":</b> " .. tostring(entry.Text or ""),
			size = 13, color = theme.SubText, order = 1,
		})
	end
end

----------------------------------------------------------------
-- MAIN REFRESH
----------------------------------------------------------------
refresh = function()
	local ok, data = pcall(function() return getCult:InvokeServer() end)
	clearScroll()

	if not ok then
		warn("[MobileCultPanel] Failed to load cult:", data)
		addEmptyCard("Could not load the cult. Try again later.", 0)
		return
	end

	currentData = data or {}

	if currentTab == "Overview" then
		buildOverviewTab(currentData)
	elseif currentTab == "Members" then
		buildMembersTab(currentData)
	elseif currentTab == "Actions" then
		buildActionsTab(currentData)
	elseif currentTab == "History" then
		buildHistoryTab(currentData)
	end
end

----------------------------------------------------------------
-- OPEN / CLOSE
----------------------------------------------------------------
local function openPanel()
	if isOpen then return end
	isOpen = true
	setTab(currentTab)
	gui.Enabled = true
	sheet.Visible = true
	refresh()
end

local function closePanel()
	isOpen = false
	gui.Enabled = false
end

----------------------------------------------------------------
-- INIT
----------------------------------------------------------------
local function init()
	gui = Instance.new("ScreenGui")
	gui.Name = "MobileCultGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 631
	gui.Enabled = false
	gui.Parent = playerGui

	sheet = mobileSheet({
		name = "MobileCultSheet",
		parent = gui,
		title = "CULT SANCTUM",
		onClose = function()
			uiState.closeRoute()
		end,
	})

	scroll = sheet:FindFirstChildWhichIsA("ScrollingFrame") :: ScrollingFrame

	statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -20, 0, 16)
	statusLabel.Position = UDim2.new(0, 10, 0, 92)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = theme.Muted
	statusLabel.TextSize = 11
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextWrapped = true
	statusLabel.Text = ""
	statusLabel.Parent = sheet

	buildTabs()

	scroll.Position = UDim2.new(0, 0, 0, 118)
	scroll.Size = UDim2.new(1, 0, 1, -118)

	sheet.Visible = true

	cultAction.OnClientEvent:Connect(function()
		if isOpen then refresh() end
	end)

	uiState.subscribe(function(route)
		if route == "cult" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
