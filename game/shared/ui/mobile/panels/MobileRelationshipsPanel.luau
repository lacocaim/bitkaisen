local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local uiState = require("@ui-state/uiState")
local mc = require("@ui/mobile/mobileComponents")

local theme = mc.theme
local corner = mc.corner
local stroke = mc.stroke
local bindTap = mc.bindTap
local mobileButton = mc.mobileButton
local mobileCard = mc.mobileCard
local mobileLabel = mc.mobileLabel
local mobileHeader = mc.mobileHeader

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local getRelationships = ReplicatedStorage:WaitForChild("GetRelationships")
local relationshipAction = ReplicatedStorage:WaitForChild("RelationshipAction")

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local FAMILY_ROLES = {
	Mother = true,
	Father = true,
	Caretaker = true,
	Sibling = true,
	Child = true,
	Ward = true,
	Student = true,
	["Late Mother"] = true,
	["Late Father"] = true,
}

local FLIRTABLE_ROLES = {
	Friend = true,
	["Best Friend"] = true,
	["Mission Partner"] = true,
}

local ROMANCE_ROLES = {
	Partner = true,
	Spouse = true,
}

local isOpen = false
local busyAction = false
local pendingRefresh = false
local refreshStamp = 0
local refreshInProgress = false
local canBrainTransplant = false
local canNameChildren = false
local expandedCardId = nil

local gui: ScreenGui
local scrollFrame: ScrollingFrame
local refreshRelationships: (preservePosition: boolean) -> ()

local function roleColor(role: string): Color3
	if role == "Mother" or role == "Father" or role == "Sibling" or role == "Caretaker" or role == "Child" or role == "Ward" or role == "Spouse" or role == "Late Mother" or role == "Late Father" then
		return theme.Gold
	elseif role == "Teacher" then
		return theme.Blue
	elseif role == "Rival" then
		return Color3.fromRGB(255, 90, 90)
	elseif role == "Partner" then
		return Color3.fromRGB(255, 120, 190)
	elseif role == "Ex-Spouse" then
		return theme.Bad
	elseif role == "Best Friend" or role == "Friend" or role == "Classmate" then
		return theme.Green
	elseif role == "Mission Partner" then
		return theme.Purple
	end
	return Color3.fromRGB(190, 190, 205)
end

local function clampPercent(value): number
	return math.clamp(tonumber(value) or 0, 0, 100)
end

local function canShowRomanceBar(relationship): boolean
	local role = tostring(relationship.Role or "")
	if FAMILY_ROLES[role] then return false end
	if role == "Teacher" or role == "Rival" or role == "Observer" then return false end
	if ROMANCE_ROLES[role] then return true end
	if FLIRTABLE_ROLES[role] and (relationship.Romance or 0) > 0 then return true end
	return false
end

local function getRelationshipAge(relationship): number
	if relationship.Age ~= nil then return tonumber(relationship.Age) or 0 end
	return tonumber(relationship.DisplayAge) or tonumber(relationship.EstimatedAge) or 0
end

local function getRelationshipGender(relationship): string
	local gender = tostring(relationship.Gender or "Unknown")
	if gender == "Male" or gender == "Female" then return gender end
	return "Unknown"
end

local function getRelationshipGrade(relationship): string
	return tostring(relationship.Grade or relationship.SorcererGrade or "Non-Sorcerer")
end

local function getRelationshipTechnique(relationship): string
	return tostring(relationship.CursedTechnique or "None")
end

local function getRelationshipCE(relationship): number
	return tonumber(relationship.CursedEnergy) or 0
end

local function getStatusLine(relationship): string
	local role = tostring(relationship.Role or "Unknown")
	local status = tostring(relationship.Status or "Neutral")
	local age = getRelationshipAge(relationship)
	local gender = getRelationshipGender(relationship)
	local line = status
	if gender ~= "Unknown" then line = line .. " · " .. gender end
	if age > 0 then line = line .. " · Age " .. tostring(age) end
	if role == "Child" then
		line = line .. " · " .. tostring(relationship.Custody or "With You")
	elseif role == "Partner" then
		line = line .. " · Dating " .. tostring(relationship.YearsDating or 0) .. "y"
	elseif role == "Spouse" then
		line = line .. " · Married " .. tostring(relationship.YearsMarried or 0) .. "y"
	elseif (relationship.YearsKnown or 0) > 0 then
		line = line .. " · " .. tostring(relationship.YearsKnown) .. "y known"
	end
	return line
end

local function getActionsForRelationship(relationship)
	local role = tostring(relationship.Role or "")

	local function addMurder(actions)
		local blocked = { Child = true, Ward = true, Mother = true, Father = true, Caretaker = true, Sibling = true, Teacher = true, Student = true }
		if relationship.Alive ~= false and not blocked[role] then
			table.insert(actions, { Id = "murder_relationship", Text = "Murder", Confirm = true })
		end
		return actions
	end

	if relationship.Alive == false then
		local actions = { { Id = "forget_relationship", Text = "Forget", Confirm = true } }
		if canBrainTransplant then
			table.insert(actions, { Id = "brain_transplant", Text = "Transplant", Confirm = true })
		end
		return actions
	end

	if role == "Notable Sorcerer" then
		return addMurder({ { Id = "talk", Text = "Talk" }, { Id = "compliment", Text = "Compliment" }, { Id = "train_together", Text = "Train" }, { Id = "pair_mission", Text = "Mission" } })
	end
	if role == "Ward" then
		local actions = { { Id = "talk", Text = "Talk" }, { Id = "encourage_child", Text = "Encourage" }, { Id = "protect_child", Text = "Protect" } }
		if (relationship.Age or 0) >= 8 then table.insert(actions, { Id = "train_child", Text = "Train CE" }) end
		if (relationship.Age or 0) >= 12 and relationship.DojoStudent ~= true then table.insert(actions, { Id = "recruit_dojo", Text = "Recruit Dojo" }) end
		return actions
	end
	if role == "Child" then
		local actions = { { Id = "teach_child", Text = "Teach" }, { Id = "protect_child", Text = "Protect" }, { Id = "encourage_child", Text = "Encourage" }, { Id = "take_over_child", Text = "Take Over", Confirm = true }, { Id = "disown_child", Text = "Disown", Confirm = true } }
		if relationship.Custody == "Shared" or relationship.Custody == "With Ex-Spouse" then
			table.insert(actions, { Id = "custody_visit", Text = "Custody Visit" })
		end
		if (relationship.Age or 0) >= 8 then table.insert(actions, { Id = "train_child", Text = "Train CE" }) end
		return actions
	end
	if role == "Student" then
		return { { Id = "talk", Text = "Talk" }, { Id = "encourage_child", Text = "Encourage" }, { Id = "train_together", Text = "Train" }, { Id = "ask_advice", Text = "Guide" } }
	end
	if role == "Mother" or role == "Father" or role == "Caretaker" or role == "Sibling" then
		return { { Id = "talk", Text = "Talk" }, { Id = "family_time", Text = "Family Time" }, { Id = "ask_advice", Text = "Ask Advice" }, { Id = "apologize", Text = "Apologize" } }
	end
	if role == "Teacher" then
		return { { Id = "ask_advice", Text = "Ask Advice" }, { Id = "train_together", Text = "Train" }, { Id = "mentor_session", Text = "Mentor Session" }, { Id = "ask_recommendation", Text = "Recommendation" } }
	end
	if role == "Rival" then
		return addMurder({ { Id = "talk", Text = "Talk" }, { Id = "spar", Text = "Spar" }, { Id = "challenge", Text = "Challenge" }, { Id = "acknowledge", Text = "Acknowledge" } })
	end
	if role == "Classmate" then
		return addMurder({ { Id = "talk", Text = "Talk" }, { Id = "study_together", Text = "Study" }, { Id = "train_together", Text = "Train" }, { Id = "spend_time", Text = "Hang Out" } })
	end
	if role == "Friend" or role == "Best Friend" then
		local actions = { { Id = "talk", Text = "Talk" }, { Id = "spend_time", Text = "Hang Out" }, { Id = "deep_talk", Text = "Open Up" }, { Id = "train_together", Text = "Train" }, { Id = "flirt", Text = "Flirt" }, { Id = "remove_relationship", Text = "Remove", Confirm = true } }
		if (relationship.Bond or 0) >= 45 and (relationship.Trust or 0) >= 35 and (relationship.Romance or 0) >= 25 then
			table.insert(actions, { Id = "ask_out", Text = "Ask Out" })
		end
		return addMurder(actions)
	end
	if role == "Mission Partner" then
		local actions = { { Id = "talk", Text = "Talk" }, { Id = "train_together", Text = "Train" }, { Id = "pair_mission", Text = "Paired Mission" }, { Id = "deep_talk", Text = "Open Up" }, { Id = "flirt", Text = "Flirt" }, { Id = "remove_relationship", Text = "Remove", Confirm = true } }
		if (relationship.Bond or 0) >= 45 and (relationship.Trust or 0) >= 35 and (relationship.Romance or 0) >= 25 then
			table.insert(actions, { Id = "ask_out", Text = "Ask Out" })
		end
		return addMurder(actions)
	end
	if role == "Partner" then
		return addMurder({ { Id = "spend_time", Text = "Spend Time" }, { Id = "deep_talk", Text = "Open Up" }, { Id = "give_gift", Text = "Gift" }, { Id = "propose", Text = "Propose" }, { Id = "remove_relationship", Text = "Break Up", Confirm = true } })
	end
	if role == "Spouse" then
		return addMurder({ { Id = "spend_time", Text = "Spend Time" }, { Id = "deep_talk", Text = "Open Up" }, { Id = "give_gift", Text = "Gift" }, { Id = "start_family", Text = "Start Family" }, { Id = "adopt_child", Text = "Adopt" }, { Id = "divorce", Text = "Divorce", Confirm = true } })
	end
	if role == "Ex-Spouse" then
		return addMurder({ { Id = "talk", Text = "Talk" }, { Id = "apologize", Text = "Apologize" }, { Id = "discuss_custody", Text = "Custody" }, { Id = "remove_relationship", Text = "Remove", Confirm = true } })
	end
	return addMurder({ { Id = "talk", Text = "Talk" }, { Id = "spend_time", Text = "Hang Out" }, { Id = "ask_advice", Text = "Ask Advice" }, { Id = "remove_relationship", Text = "Remove", Confirm = true } })
end

local function normalizeRelationships(result)
	local living = {}
	local dead = {}
	if typeof(result) ~= "table" then return living, dead end
	if result.Living or result.Deceased then
		for _, item in ipairs(result.Living or {}) do table.insert(living, item) end
		for _, item in ipairs(result.Deceased or {}) do table.insert(dead, item) end
		return living, dead
	end
	local source = result.Relationships or result
	for _, r in ipairs(source) do
		if r.Alive == false then table.insert(dead, r) else table.insert(living, r) end
	end
	return living, dead
end

local function promptChildName(callback: (string?) -> ())
	local promptGui = Instance.new("ScreenGui")
	promptGui.Name = "MobileChildNamePrompt"
	promptGui.ResetOnSpawn = false
	promptGui.IgnoreGuiInset = false
	promptGui.DisplayOrder = 998
	promptGui.Parent = playerGui

	local shade = Instance.new("Frame")
	shade.Size = UDim2.fromScale(1, 1)
	shade.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shade.BackgroundTransparency = 0.35
	shade.BorderSizePixel = 0
	shade.Parent = promptGui

	local box = Instance.new("Frame")
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, 0.5)
	box.Size = UDim2.new(0.9, 0, 0, 180)
	box.BackgroundColor3 = theme.Panel
	box.BorderSizePixel = 0
	box.Parent = shade
	corner(box, 12)
	stroke(box)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.fromOffset(16, 14)
	titleLabel.Size = UDim2.new(1, -32, 0, 24)
	titleLabel.Text = "CHILD NAME"
	titleLabel.TextColor3 = theme.Gold
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 16
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = box

	local input = Instance.new("TextBox")
	input.Position = UDim2.fromOffset(16, 50)
	input.Size = UDim2.new(1, -32, 0, 44)
	input.BackgroundColor3 = theme.Card
	input.BorderSizePixel = 0
	input.PlaceholderText = "Optional name"
	input.Text = ""
	input.TextColor3 = theme.Text
	input.PlaceholderColor3 = theme.Muted
	input.Font = Enum.Font.GothamBold
	input.TextSize = 14
	input.ClearTextOnFocus = false
	input.Parent = box
	corner(input, 8)
	stroke(input)

	local function close(value)
		promptGui:Destroy()
		callback(value)
	end

	mobileButton({
		parent = box,
		text = "RANDOM",
		size = UDim2.new(0.47, 0, 0, 48),
		position = UDim2.new(0, 16, 1, -60),
		color = theme.Card,
		textSize = 14,
		callback = function() close(nil) end,
	})

	mobileButton({
		parent = box,
		text = "USE NAME",
		size = UDim2.new(0.47, 0, 0, 48),
		position = UDim2.new(0.53, 0, 1, -60),
		color = theme.Purple,
		textSize = 14,
		callback = function() close(input.Text) end,
	})

	input:CaptureFocus()
end

local function makeStatBar(parent: GuiObject, label: string, value: number, color: Color3, order: number)
	local clamped = clampPercent(value)

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 20)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.Parent = parent

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0, 56, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = color
	nameLabel.TextSize = 11
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = label
	nameLabel.Parent = row

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -96, 0, 8)
	track.Position = UDim2.new(0, 58, 0.5, -4)
	track.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	track.BorderSizePixel = 0
	track.Parent = row
	corner(track, 999)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(clamped / 100, 0, 1, 0)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = track
	corner(fill, 999)

	local pct = Instance.new("TextLabel")
	pct.Size = UDim2.new(0, 34, 1, 0)
	pct.Position = UDim2.new(1, -34, 0, 0)
	pct.BackgroundTransparency = 1
	pct.TextColor3 = theme.SubText
	pct.TextSize = 10
	pct.Font = Enum.Font.GothamBold
	pct.TextXAlignment = Enum.TextXAlignment.Right
	pct.Text = tostring(clamped) .. "%"
	pct.Parent = row
end

local function createActionsGrid(parent: GuiObject, relationship, order: number): Frame
	local actions = getActionsForRelationship(relationship)
	local holder = Instance.new("Frame")
	holder.Name = "ActionsGrid"
	holder.Size = UDim2.new(1, 0, 0, 0)
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.BackgroundTransparency = 1
	holder.LayoutOrder = order
	holder.Parent = parent

	local grid = Instance.new("UIGridLayout")
	grid.CellPadding = UDim2.new(0, 8, 0, 8)
	grid.CellSize = UDim2.new(0.5, -4, 0, 46)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = holder

	for index, action in ipairs(actions) do
		local btn = Instance.new("TextButton")
		btn.Name = "Action_" .. action.Id
		btn.BackgroundColor3 = theme.Button
		btn.BorderSizePixel = 0
		btn.TextColor3 = theme.Text
		btn.TextSize = 13
		btn.Font = Enum.Font.GothamBold
		btn.Text = action.Text
		btn.AutoButtonColor = false
		btn.LayoutOrder = index
		btn.Parent = holder
		corner(btn, 9)
		stroke(btn, theme.StrokeSoft)

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TWEEN_FAST, { BackgroundColor3 = theme.CardHover }):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TWEEN_FAST, { BackgroundColor3 = theme.Button }):Play()
		end)

		bindTap(btn, function()
			if busyAction then return end

			if action.Confirm and btn:GetAttribute("Confirmed") ~= true then
				btn:SetAttribute("Confirmed", true)
				btn.Text = "CONFIRM?"
				btn.TextColor3 = theme.Bad
				task.delay(2.5, function()
					if btn and btn.Parent and btn:GetAttribute("Confirmed") == true then
						btn:SetAttribute("Confirmed", false)
						btn.Text = action.Text
						btn.TextColor3 = theme.Text
					end
				end)
				return
			end

			local function fireAction(extraData)
				busyAction = true
				pendingRefresh = true
				btn.Text = "..."
				btn.Active = false
				relationshipAction:FireServer(relationship.Id, action.Id, extraData)
			end

			if canNameChildren and (action.Id == "start_family" or action.Id == "adopt_child") then
				promptChildName(function(childName) fireAction({ ChildName = childName }) end)
			else
				fireAction(nil)
			end

			task.delay(1.2, function()
				if pendingRefresh then
					pendingRefresh = false
					busyAction = false
					if isOpen then refreshRelationships(true) end
				end
			end)
		end)
	end

	return holder
end

local function createRelationshipCard(parent: GuiObject, relationship, order: number)
	local alive = relationship.Alive ~= false
	local role = tostring(relationship.Role or "Unknown")
	local rColor = alive and roleColor(role) or theme.Muted
	local showRomance = canShowRomanceBar(relationship)
	local isExpanded = (expandedCardId == relationship.Id)

	local card = mobileCard({
		parent = parent,
		color = alive and theme.Card or Color3.fromRGB(18, 18, 24),
		accentColor = alive and theme.Stroke or Color3.fromRGB(55, 55, 65),
		order = order,
	})
	card.Name = "RelCard_" .. tostring(relationship.Id)
	card:SetAttribute("RelId", relationship.Id)

	mobileLabel({
		parent = card,
		text = tostring(relationship.Name or "Unknown"),
		size = 16,
		color = alive and theme.Text or theme.Muted,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	mobileLabel({
		parent = card,
		text = (alive and role or (role .. " †")) .. "  ·  " .. getStatusLine(relationship),
		size = 13,
		color = rColor,
		font = Enum.Font.GothamBold,
		order = 2,
	})

	local infoLine = getRelationshipGrade(relationship) .. "  ·  CE " .. tostring(getRelationshipCE(relationship)) .. "  ·  " .. getRelationshipTechnique(relationship)
	mobileLabel({
		parent = card,
		text = infoLine,
		size = 11,
		color = theme.SubText,
		font = Enum.Font.GothamMedium,
		order = 3,
	})

	local barsHolder = Instance.new("Frame")
	barsHolder.Name = "Bars"
	barsHolder.Size = UDim2.new(1, 0, 0, 0)
	barsHolder.AutomaticSize = Enum.AutomaticSize.Y
	barsHolder.BackgroundTransparency = 1
	barsHolder.LayoutOrder = 4
	barsHolder.Parent = card

	local barsLayout = Instance.new("UIListLayout")
	barsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	barsLayout.Padding = UDim.new(0, 4)
	barsLayout.Parent = barsHolder

	makeStatBar(barsHolder, "Bond", relationship.Bond or 0, theme.Green, 1)
	makeStatBar(barsHolder, "Trust", relationship.Trust or 0, theme.Blue, 2)
	makeStatBar(barsHolder, "Respect", relationship.Respect or 0, theme.Gold, 3)
	if showRomance then
		makeStatBar(barsHolder, "Romance", relationship.Romance or 0, Color3.fromRGB(255, 120, 190), 4)
	else
		makeStatBar(barsHolder, "Fear", relationship.Fear or 0, theme.Bad, 4)
	end

	local actionsHolder: Frame? = nil
	if isExpanded then
		actionsHolder = createActionsGrid(card, relationship, 5)
	end

	local expandBtn = Instance.new("TextButton")
	expandBtn.Name = "ExpandBtn"
	expandBtn.Size = UDim2.new(1, 0, 0, 36)
	expandBtn.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
	expandBtn.BorderSizePixel = 0
	expandBtn.TextColor3 = alive and theme.SubText or theme.Muted
	expandBtn.TextSize = 13
	expandBtn.Font = Enum.Font.GothamBold
	expandBtn.Text = isExpanded and "▲  Hide Actions" or "▼  Actions"
	expandBtn.AutoButtonColor = false
	expandBtn.LayoutOrder = 6
	expandBtn.Parent = card
	corner(expandBtn, 8)

	bindTap(expandBtn, function()
		if expandedCardId == relationship.Id then
			expandedCardId = nil
			if actionsHolder then actionsHolder:Destroy() end
			expandBtn.Text = "▼  Actions"
		else
			if expandedCardId then
				local prev = scrollFrame:FindFirstChild("RelCard_" .. tostring(expandedCardId))
				if prev then
					local prevActions = prev:FindFirstChild("ActionsGrid")
					if prevActions then prevActions:Destroy() end
					local prevBtn = prev:FindFirstChild("ExpandBtn")
					if prevBtn then (prevBtn :: TextButton).Text = "▼  Actions" end
				end
			end
			expandedCardId = relationship.Id
			actionsHolder = createActionsGrid(card, relationship, 5)
			expandBtn.Text = "▲  Hide Actions"
		end
	end)
end

local function clearContent()
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

local function makeSectionLabel(text: string, order: number)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 24)
	label.BackgroundTransparency = 1
	label.TextColor3 = theme.SubText
	label.TextSize = 13
	label.Font = Enum.Font.GothamBlack
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = string.upper(text)
	label.LayoutOrder = order
	label.Parent = scrollFrame
end

local function makeEmptyCard(text: string, order: number)
	local card = mobileCard({ parent = scrollFrame, order = order })
	mobileLabel({ parent = card, text = text, size = 14, color = theme.SubText, order = 1 })
end

refreshRelationships = function(preservePosition: boolean)
	refreshStamp += 1
	local thisRefresh = refreshStamp

	if refreshInProgress then
		pendingRefresh = true
		return
	end
	refreshInProgress = true

	local previousPosition = preservePosition and scrollFrame.CanvasPosition or Vector2.new(0, 0)

	if not preservePosition then
		clearContent()
		makeSectionLabel("Loading", 1)
		makeEmptyCard("Loading relationships...", 2)
	end

	task.spawn(function()
		local success, result = pcall(function()
			return getRelationships:InvokeServer()
		end)

		if refreshStamp ~= thisRefresh then
			refreshInProgress = false
			return
		end

		clearContent()

		if not success then
			refreshInProgress = false
			busyAction = false
			pendingRefresh = false
			makeSectionLabel("Error", 1)
			makeEmptyCard("Could not load relationships.", 2)
			return
		end

		canBrainTransplant = typeof(result) == "table" and result.CanBrainTransplant == true
		canNameChildren = typeof(result) == "table" and result.CanNameChildren == true
		local living, deceased = normalizeRelationships(result)

		local order = 1

		if #living > 0 then
			makeSectionLabel("Living (" .. tostring(#living) .. ")", order)
			order += 1
			for _, rel in ipairs(living) do
				createRelationshipCard(scrollFrame, rel, order)
				order += 1
			end
		end

		if #deceased > 0 then
			makeSectionLabel("Deceased (" .. tostring(#deceased) .. ")", order)
			order += 1
			for _, rel in ipairs(deceased) do
				createRelationshipCard(scrollFrame, rel, order)
				order += 1
			end
		end

		if #living == 0 and #deceased == 0 then
			makeSectionLabel("Relationships", 1)
			makeEmptyCard("No relationships found yet.", 2)
		end

		task.defer(function()
			if refreshStamp ~= thisRefresh then
				refreshInProgress = false
				return
			end
			if preservePosition then
				scrollFrame.CanvasPosition = previousPosition
			else
				scrollFrame.CanvasPosition = Vector2.new(0, 0)
			end
			refreshInProgress = false
			if pendingRefresh and isOpen then
				pendingRefresh = false
				refreshRelationships(true)
			end
		end)
	end)
end

local function openPanel()
	if isOpen then return end
	isOpen = true
	gui.Enabled = true
	refreshRelationships(false)
end

local function closePanel()
	if not isOpen then return end
	isOpen = false
	busyAction = false
	pendingRefresh = false
	refreshInProgress = false
	expandedCardId = nil
	gui.Enabled = false
end

local function init()
	gui = Instance.new("ScreenGui")
	gui.Name = "MobileRelationshipsGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 621
	gui.Enabled = false
	gui.Parent = playerGui

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = theme.Bg
	root.BorderSizePixel = 0
	root.Parent = gui

	mobileHeader(root, "RELATIONSHIPS", function()
		uiState.closeRoute()
	end)

	scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "Scroll"
	scrollFrame.Size = UDim2.new(1, 0, 1, -50)
	scrollFrame.Position = UDim2.new(0, 0, 0, 50)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 4
	scrollFrame.ScrollBarImageColor3 = theme.Stroke
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	scrollFrame.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	scrollFrame.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = scrollFrame

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 20)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = scrollFrame

	relationshipAction.OnClientEvent:Connect(function()
		busyAction = false
		if isOpen then
			if refreshInProgress then
				pendingRefresh = true
			else
				pendingRefresh = false
				refreshRelationships(true)
			end
		else
			pendingRefresh = false
		end
	end)

	uiState.subscribe(function(route)
		if route == "relationships" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
