local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local uiState = require("@ui-state/uiState")
local mc = require("@ui/mobile/mobileComponents")

local theme = mc.theme
local bindTap = mc.bindTap

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getRelationships = ReplicatedStorage:WaitForChild("GetRelationships")
local relationshipAction = ReplicatedStorage:WaitForChild("RelationshipAction")

local refreshStamp = 0
local isOpen = false
local groupPages: { [string]: number } = {}

local PAGE_SIZE = 4

local GROUPS = {
	{ Key = "Clan", Title = "Clan Members", Roles = { Mother = true, Father = true, Caretaker = true, Sibling = true, Child = true, Spouse = true, Partner = true } },
	{ Key = "Dojo", Title = "Dojo Members", Roles = { Student = true, Ward = true, ["Mission Partner"] = true } },
	{ Key = "Teachers", Title = "Teachers", Roles = { Teacher = true, Sensei = true, ["Jujutsu High Teacher"] = true } },
	{ Key = "Students", Title = "Students", Roles = { Student = true, Ward = true, Child = true } },
	{ Key = "Rivals", Title = "Rivals", Roles = { Rival = true } },
	{ Key = "Notable", Title = "Notable Sorcerers", Roles = { ["Notable Sorcerer"] = true } },
}

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenMobileAffiliationsGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 622
gui.Enabled = false
gui.Parent = playerGui

local sheet = mc.mobileSheet({
	name = "MobileAffiliationsSheet",
	parent = gui,
	title = "AFFILIATIONS",
	onClose = function()
		uiState.closeRoute()
	end,
})

local scroll: ScrollingFrame = sheet:FindFirstChildWhichIsA("ScrollingFrame") :: ScrollingFrame

local function clearScroll()
	for _, child in scroll:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function relationId(rel)
	return rel.Id or rel.RelationshipId or rel.Name
end

local function groupRelationships(list)
	local groups: { [string]: { any } } = {}
	for _, group in GROUPS do
		groups[group.Key] = {}
	end
	for _, rel in list or {} do
		local role = tostring(rel.Role or rel.Status or "Unknown")
		for _, group in GROUPS do
			if group.Roles[role] then
				table.insert(groups[group.Key], rel)
			end
		end
	end
	return groups
end

local refresh: () -> ()

local function makeActionRow(parent: Frame, rel: any, layoutOrder: number)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 48)
	row.BackgroundTransparency = 1
	row.LayoutOrder = layoutOrder
	row.Parent = parent

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.48, 0, 0, 44)
	grid.CellPadding = UDim2.new(0.04, 0, 0, 4)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = row

	local actions = {
		{ text = "HANG OUT", color = theme.Button, id = "spend_time" },
		{ text = "TRAIN", color = Color3.fromRGB(45, 80, 55), id = "train_together" },
		{ text = "RIVALRY", color = Color3.fromRGB(80, 55, 35), id = "challenge" },
		{ text = "BULLY", color = Color3.fromRGB(90, 35, 45), id = "argue" },
	}

	for i, action in actions do
		mc.mobileButton({
			parent = row,
			text = action.text,
			size = UDim2.new(0.48, 0, 0, 44),
			color = action.color,
			textSize = 13,
			order = i,
			callback = function()
				local id = relationId(rel)
				if id then
					relationshipAction:FireServer(id, action.id)
					task.delay(0.35, function()
						if isOpen then refresh() end
					end)
				end
			end,
		})
	end

	return row
end

local function createStatusCard(text: string, color: Color3?)
	clearScroll()
	local card = mc.mobileCard({ parent = scroll, order = 1 })
	mc.mobileLabel({ parent = card, text = text, size = 14, color = color or theme.SubText, font = Enum.Font.GothamBold, order = 1 })
end

local function createPageControls(groupKey: string, totalCount: number, currentPage: number, totalPages: number, layoutOrder: number)
	local controls = Instance.new("Frame")
	controls.Size = UDim2.new(1, 0, 0, 44)
	controls.BackgroundColor3 = theme.Card
	controls.BorderSizePixel = 0
	controls.LayoutOrder = layoutOrder
	controls.Parent = scroll
	mc.corner(controls, 10)
	mc.stroke(controls, theme.Stroke)

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = controls

	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1, -110, 1, 0)
	info.BackgroundTransparency = 1
	info.Text = "Page " .. currentPage .. "/" .. totalPages .. "  (" .. totalCount .. " total)"
	info.TextColor3 = theme.SubText
	info.TextSize = 13
	info.Font = Enum.Font.GothamMedium
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextTruncate = Enum.TextTruncate.AtEnd
	info.Parent = controls

	local prev = Instance.new("TextButton")
	prev.Size = UDim2.fromOffset(50, 34)
	prev.AnchorPoint = Vector2.new(1, 0.5)
	prev.Position = UDim2.new(1, -54, 0.5, 0)
	prev.BackgroundColor3 = currentPage > 1 and theme.Button or Color3.fromRGB(24, 24, 32)
	prev.BorderSizePixel = 0
	prev.Text = "<"
	prev.TextColor3 = currentPage > 1 and theme.Text or theme.Muted
	prev.TextSize = 14
	prev.Font = Enum.Font.GothamBold
	prev.Active = currentPage > 1
	prev.AutoButtonColor = currentPage > 1
	prev.Parent = controls
	mc.corner(prev, 8)
	if currentPage > 1 then
		bindTap(prev, function()
			groupPages[groupKey] = math.clamp(currentPage - 1, 1, totalPages)
			refresh()
		end)
	end

	local nxt = Instance.new("TextButton")
	nxt.Size = UDim2.fromOffset(50, 34)
	nxt.AnchorPoint = Vector2.new(1, 0.5)
	nxt.Position = UDim2.new(1, 0, 0.5, 0)
	nxt.BackgroundColor3 = currentPage < totalPages and theme.Button or Color3.fromRGB(24, 24, 32)
	nxt.BorderSizePixel = 0
	nxt.Text = ">"
	nxt.TextColor3 = currentPage < totalPages and theme.Text or theme.Muted
	nxt.TextSize = 14
	nxt.Font = Enum.Font.GothamBold
	nxt.Active = currentPage < totalPages
	nxt.AutoButtonColor = currentPage < totalPages
	nxt.Parent = controls
	mc.corner(nxt, 8)
	if currentPage < totalPages then
		bindTap(nxt, function()
			groupPages[groupKey] = math.clamp(currentPage + 1, 1, totalPages)
			refresh()
		end)
	end

	return controls
end

function refresh()
	refreshStamp += 1
	local thisRefresh = refreshStamp
	createStatusCard("Loading affiliations...", theme.SubText)

	task.spawn(function()
		local ok, data = pcall(function()
			return getRelationships:InvokeServer()
		end)

		if refreshStamp ~= thisRefresh or not isOpen then return end

		local list = ok and (typeof(data) == "table" and (data.Relationships or data) or {}) or {}
		if not ok then
			createStatusCard("Could not load affiliations.", theme.Bad)
			return
		end

		clearScroll()
		local groups = groupRelationships(list)
		local rendered = 0

		for order, group in GROUPS do
			local entries = groups[group.Key] or {}

			local headerCard = Instance.new("Frame")
			headerCard.Size = UDim2.new(1, 0, 0, 32)
			headerCard.BackgroundTransparency = 1
			headerCard.LayoutOrder = order * 100
			headerCard.Parent = scroll
			mc.mobileLabel({
				parent = headerCard,
				text = string.upper(group.Title) .. "  (" .. #entries .. ")",
				size = 15,
				color = theme.Gold,
				font = Enum.Font.GothamBlack,
				order = 1,
			})

			if refreshStamp ~= thisRefresh or not isOpen then return end

			if #entries == 0 then
				local emptyCard = mc.mobileCard({ parent = scroll, order = order * 100 + 1 })
				mc.mobileLabel({
					parent = emptyCard,
					text = "No entries yet.",
					size = 13,
					color = theme.Muted,
					order = 1,
				})
			else
				local totalPages = math.max(1, math.ceil(#entries / PAGE_SIZE))
				local currentPage = math.clamp(tonumber(groupPages[group.Key]) or 1, 1, totalPages)
				groupPages[group.Key] = currentPage
				local startIdx = ((currentPage - 1) * PAGE_SIZE) + 1
				local endIdx = math.min(#entries, startIdx + PAGE_SIZE - 1)

				if #entries > PAGE_SIZE then
					createPageControls(group.Key, #entries, currentPage, totalPages, order * 100 + 1)
				end

				for idx = startIdx, endIdx do
					local rel = entries[idx]
					if refreshStamp ~= thisRefresh or not isOpen then return end

					local name = tostring(rel.Name or "Unknown")
					local role = tostring(rel.Role or rel.Status or "Unknown")
					local age = tostring(rel.Age or "?")
					local grade = tostring(rel.Grade or rel.UnregisteredGrade or "Non-Sorcerer")
					local status = tostring(rel.Status or "Active")
					local relation = tostring(rel.Relationship or role)
					local progressing = rel.Progressing == false and "Not progressing" or "Progressing"

					local summaryText = role .. " | Age " .. age .. " | " .. grade
					if role == "Notable Sorcerer" then
						summaryText ..= " | CE " .. tostring(rel.CursedEnergy or 0) .. " | Power " .. tostring(rel.Power or 0)
					end

					local detailText = status .. " | " .. relation .. " | " .. progressing
					if rel.PublicNote then
						detailText = tostring(rel.PublicNote)
					end

					local card = mc.mobileCard({
						parent = scroll,
						order = order * 100 + idx + 1,
					})

					mc.mobileLabel({
						parent = card,
						text = name,
						size = 15,
						color = theme.Text,
						font = Enum.Font.GothamBlack,
						order = 1,
						wrap = false,
					})

					mc.mobileLabel({
						parent = card,
						text = summaryText,
						size = 13,
						color = theme.SubText,
						order = 2,
					})

					mc.mobileLabel({
						parent = card,
						text = detailText,
						size = 13,
						color = theme.Muted,
						order = 3,
					})

					if rel.ReadOnly ~= true then
						makeActionRow(card, rel, 4)
					end

					rendered += 1
					if rendered % 5 == 0 then task.wait() end
				end
			end
		end
	end)
end

local function openPanel()
	isOpen = true
	gui.Enabled = true
	sheet.Visible = true
	refresh()
end

local function closePanel()
	isOpen = false
	refreshStamp += 1
	sheet.Visible = false
	gui.Enabled = false
end

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
