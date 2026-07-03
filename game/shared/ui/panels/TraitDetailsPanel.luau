local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local uiState = require("@ui-state/uiState")
local responsiveScale = require("@ui/responsiveScale")

local player = Players.LocalPlayer

local GUI_NAME = "BitKaisenTraitDetailsGui"
local MAIN_GUI_NAME = "BitKaisenGui"

local COLORS = {
	Bg = Color3.fromRGB(7, 7, 10),
	Panel = Color3.fromRGB(15, 15, 22),
	Panel2 = Color3.fromRGB(20, 20, 30),
	Card = Color3.fromRGB(24, 24, 34),
	Stroke = Color3.fromRGB(48, 48, 64),
	StrokeSoft = Color3.fromRGB(34, 34, 46),
	Text = Color3.fromRGB(238, 238, 248),
	SubText = Color3.fromRGB(165, 165, 185),
	Muted = Color3.fromRGB(105, 105, 125),
	Gold = Color3.fromRGB(255, 205, 105),
	Purple = Color3.fromRGB(178, 122, 255),
	Blue = Color3.fromRGB(120, 190, 255),
	Green = Color3.fromRGB(120, 240, 160),
	Red = Color3.fromRGB(145, 32, 45),
	Bad = Color3.fromRGB(230, 75, 90),
	Orange = Color3.fromRGB(255, 160, 78),
}

local RARITY_COLORS = {
	Common = Color3.fromRGB(190, 190, 200),
	Uncommon = Color3.fromRGB(120, 240, 160),
	Rare = Color3.fromRGB(120, 190, 255),
	Epic = Color3.fromRGB(190, 130, 255),
	Legendary = Color3.fromRGB(255, 205, 105),
	Mythic = Color3.fromRGB(255, 120, 160),
	Special = Color3.fromRGB(255, 120, 160),
}

local MODIFIER_LABELS = {
	CEGainMult = "Cursed Energy gain",
	MasteryGainMult = "Technique mastery gain",
	SmartsGainMult = "Smarts gain",
	MoneyGainMult = "Money gain",
	GradeProgressMult = "Grade progress",
	CombatGainMult = "Combat growth",
	HappinessLossMult = "Happiness loss",
	RiskMult = "Danger / injury risk",
	RelationshipGainMult = "Relationship gain",
	RomanceGainMult = "Romance gain",
	FamilyGainMult = "Family bond gain",
	KidBondGainMult = "Child bond gain",
	StartingCEBonus = "Starting Cursed Energy",
	StartingSmartsBonus = "Starting Smarts",
	StartingMoneyBonus = "Starting Money",
	StartingReputationBonus = "Starting Reputation",
	StartingHealthBonus = "Starting Health",
	StartingHappinessBonus = "Starting Happiness",
	MissionSuccessBonus = "Mission success",
	AwakeningChanceBonus = "Awakening chance",
	InheritanceBonus = "Inheritance chance",
	StressMult = "Stress",
	MarriageReqMult = "Marriage requirement",
	RespectGainMult = "Respect gain",
	RarityPower = "Rarity power",
	GradeFloor = "Minimum grade floor",
	CurseEncounterMult = "Curse encounter rate",
}

local MULT_KEYS = {
	CEGainMult = true,
	MasteryGainMult = true,
	SmartsGainMult = true,
	MoneyGainMult = true,
	GradeProgressMult = true,
	CombatGainMult = true,
	HappinessLossMult = true,
	RiskMult = true,
	RelationshipGainMult = true,
	RomanceGainMult = true,
	FamilyGainMult = true,
	KidBondGainMult = true,
	StressMult = true,
	MarriageReqMult = true,
	RespectGainMult = true,
	CurseEncounterMult = true,
}

local ORDERED_MODIFIER_KEYS = {
	"CEGainMult", "MasteryGainMult", "SmartsGainMult", "MoneyGainMult",
	"GradeProgressMult", "CombatGainMult", "HappinessLossMult", "RiskMult",
	"RelationshipGainMult", "RomanceGainMult", "FamilyGainMult", "KidBondGainMult",
	"StartingCEBonus", "StartingSmartsBonus", "StartingMoneyBonus",
	"StartingReputationBonus", "StartingHealthBonus", "StartingHappinessBonus",
	"MissionSuccessBonus", "AwakeningChanceBonus", "InheritanceBonus",
	"StressMult", "MarriageReqMult", "RespectGainMult", "RarityPower",
	"GradeFloor", "CurseEncounterMult",
}

local traitModule = nil
local traitDefinitions = {}
local traitLookupByName = {}
local traitLookupById = {}

local screenGui: ScreenGui = nil :: any
local overlay: Frame = nil :: any
local panel: Frame = nil :: any
local scroll: ScrollingFrame = nil :: any
local listLayout: UIListLayout = nil :: any
local title: TextLabel = nil :: any
local subtitle: TextLabel = nil :: any
local traitOpenButton: TextButton = nil :: any

local activeTraitLabel: TextLabel? = nil
local activeProfileScroll: ScrollingFrame? = nil
local activeProfileCard: Frame? = nil

-- Helpers

local function addCorner(parent: Instance, radius: number?): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = parent
	return corner
end

local function addStroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or COLORS.Stroke
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local function stripRichText(text: string): string
	text = tostring(text or "")
	text = text:gsub("<br%s*/?>", "\n")
	text = text:gsub("<[^>]->", "")
	text = text:gsub("&amp;", "&")
	text = text:gsub("&lt;", "<")
	text = text:gsub("&gt;", ">")
	text = text:gsub("&quot;", '"')
	text = text:gsub("&#39;", "'")
	return text
end

local function trim(text: string): string
	text = tostring(text or "")
	text = text:gsub("^%s+", "")
	text = text:gsub("%s+$", "")
	return text
end

local function normalizeKey(text: string): string
	text = stripRichText(text)
	text = string.lower(text)
	text = text:gsub("[^%w]+", "_")
	text = text:gsub("^_+", "")
	text = text:gsub("_+$", "")
	return text
end

local function formatNumber(value: number): string
	value = tonumber(value) or 0
	if math.abs(value - math.floor(value)) < 0.001 then
		return tostring(math.floor(value))
	end
	return string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", "")
end

local function percentFromMult(value: number): string
	value = tonumber(value) or 1
	local delta = (value - 1) * 100
	local sign = delta >= 0 and "+" or ""
	return sign .. tostring(math.floor(delta + (delta >= 0 and 0.5 or -0.5))) .. "%"
end

local function formatModifierLine(key: string, value: any): string
	local label = MODIFIER_LABELS[key] or tostring(key)
	local numberValue = tonumber(value)

	if numberValue == nil then
		return label .. ": " .. tostring(value)
	end

	if MULT_KEYS[key] then
		if key == "HappinessLossMult" or key == "RiskMult" or key == "StressMult" or key == "MarriageReqMult" then
			local delta = (numberValue - 1) * 100
			if delta < 0 then
				return label .. ": " .. tostring(math.abs(math.floor(delta - 0.5))) .. "% lower"
			elseif delta > 0 then
				return label .. ": " .. tostring(math.floor(delta + 0.5)) .. "% higher"
			end
			return label .. ": no change"
		end
		return label .. ": " .. percentFromMult(numberValue)
	end

	if key == "StartingMoneyBonus" then
		local sign = numberValue >= 0 and "+" or ""
		return label .. ": " .. sign .. "$" .. formatNumber(numberValue)
	end

	local sign = numberValue >= 0 and "+" or ""
	return label .. ": " .. sign .. formatNumber(numberValue)
end

-- Trait data loading

local function safeRequireTraitModule()
	if traitModule ~= nil then
		return traitModule
	end

	local moduleScript = ReplicatedStorage:FindFirstChild("BitKaisenTraits")
	if not moduleScript then
		warn("[TraitDetailsPanel] ReplicatedStorage.BitKaisenTraits was not found.")
		return nil
	end

	local ok, result = pcall(function()
		return require(moduleScript)
	end)

	if not ok then
		warn("[TraitDetailsPanel] Could not require BitKaisenTraits: " .. tostring(result))
		return nil
	end

	traitModule = result
	return traitModule
end

local function registerTraitDefinition(definition: { [string]: any })
	if typeof(definition) ~= "table" then return end

	table.insert(traitDefinitions, definition)

	local id = tostring(definition.Id or "")
	local name = tostring(definition.Name or "")

	if id ~= "" then
		traitLookupById[normalizeKey(id)] = definition
	end
	if name ~= "" then
		traitLookupByName[normalizeKey(name)] = definition
	end
end

local function rebuildTraitLookup()
	table.clear(traitDefinitions)
	table.clear(traitLookupByName)
	table.clear(traitLookupById)

	local traits = safeRequireTraitModule()
	if typeof(traits) ~= "table" then return end

	if typeof(traits.Definitions) == "table" then
		for _, definition in ipairs(traits.Definitions) do
			registerTraitDefinition(definition)
		end
	end

	for _, value in pairs(traits) do
		if typeof(value) == "table" then
			for _, possibleDefinition in ipairs(value) do
				if typeof(possibleDefinition) == "table" and possibleDefinition.Id and possibleDefinition.Name then
					registerTraitDefinition(possibleDefinition)
				end
			end
		end
	end
end

local function findTraitDefinition(rawTraitName: string): { [string]: any }?
	if not rawTraitName or rawTraitName == "" then return nil end

	if #traitDefinitions <= 0 then
		rebuildTraitLookup()
	end

	local key = normalizeKey(rawTraitName)
	return traitLookupByName[key] or traitLookupById[key]
end

-- Trait name extraction

local function getTraitNamesFromLabel(traitLabel: TextLabel): { string }
	local text = stripRichText(traitLabel and traitLabel.Text or "")
	text = text:gsub("^%s*Traits%s*:%s*", "")
	text = trim(text)

	if text == "" or string.lower(text) == "none" then
		return {}
	end

	local names = {}
	for part in string.gmatch(text, "([^,]+)") do
		local cleaned = trim(part)
		if cleaned ~= "" and string.lower(cleaned) ~= "none" then
			table.insert(names, cleaned)
		end
	end
	return names
end

-- Screen size utilities

local function getViewport(): Vector2
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local function isSmallScreen(): boolean
	local viewport = getViewport()
	return viewport.X < 760 or viewport.Y < 540 or UserInputService.TouchEnabled
end

-- UI building helpers

local function clearScroll()
	for _, child in ipairs(scroll:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function makeInfoText(parent: Instance, text: string, textSize: number?, color: Color3?, bold: boolean?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = text or ""
	label.TextColor3 = color or COLORS.Text
	label.TextSize = textSize or 13
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Size = UDim2.new(1, 0, 0, 0)
	label.Parent = parent
	return label
end

local function buildTraitCard(traitName: string, order: number)
	local definition = findTraitDefinition(traitName)

	local card = Instance.new("Frame")
	card.Name = "TraitCard"
	card.Size = UDim2.new(1, -4, 0, 50)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = COLORS.Card
	card.BorderSizePixel = 0
	card.LayoutOrder = order
	card.Parent = scroll
	addCorner(card, 10)
	addStroke(card, COLORS.StrokeSoft, 1, 0)

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = card

	local cardList = Instance.new("UIListLayout")
	cardList.SortOrder = Enum.SortOrder.LayoutOrder
	cardList.Padding = UDim.new(0, 6)
	cardList.Parent = card

	local headerButton = Instance.new("TextButton")
	headerButton.Name = "Header"
	headerButton.Size = UDim2.new(1, 0, 0, 30)
	headerButton.BackgroundTransparency = 1
	headerButton.BorderSizePixel = 0
	headerButton.AutoButtonColor = false
	headerButton.Text = ""
	headerButton.LayoutOrder = 1
	headerButton.Parent = card

	local displayName = traitName
	local rarity = "Unknown"
	local category = "Trait"
	local description = "No description found for this trait. The trait may still work if the save stores it, but it was not found in BitKaisenTraits.Definitions."
	local modifiers = nil

	if definition then
		displayName = tostring(definition.Name or traitName)
		rarity = tostring(definition.Rarity or "Unknown")
		category = tostring(definition.Category or "Trait")
		description = tostring(definition.Description or description)
		modifiers = definition.Modifiers
	end

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, -30, 1, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = RARITY_COLORS[rarity] or COLORS.Text
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextYAlignment = Enum.TextYAlignment.Center
	nameLabel.Text = displayName .. "  •  " .. rarity .. "  •  " .. category
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = headerButton

	local arrow = Instance.new("TextLabel")
	arrow.Name = "Arrow"
	arrow.AnchorPoint = Vector2.new(1, 0.5)
	arrow.Position = UDim2.new(1, 0, 0.5, 0)
	arrow.Size = UDim2.new(0, 24, 0, 24)
	arrow.BackgroundTransparency = 1
	arrow.TextColor3 = COLORS.SubText
	arrow.TextSize = 16
	arrow.Font = Enum.Font.GothamBlack
	arrow.Text = "+"
	arrow.Parent = headerButton

	local detailFrame = Instance.new("Frame")
	detailFrame.Name = "Details"
	detailFrame.Size = UDim2.new(1, 0, 0, 0)
	detailFrame.AutomaticSize = Enum.AutomaticSize.Y
	detailFrame.BackgroundTransparency = 1
	detailFrame.Visible = false
	detailFrame.LayoutOrder = 2
	detailFrame.Parent = card

	local detailList = Instance.new("UIListLayout")
	detailList.SortOrder = Enum.SortOrder.LayoutOrder
	detailList.Padding = UDim.new(0, 5)
	detailList.Parent = detailFrame

	makeInfoText(detailFrame, description, 12, COLORS.SubText, false)

	local modifierHeader = makeInfoText(detailFrame, "Buffs", 12, COLORS.Gold, true)
	modifierHeader.LayoutOrder = 10

	if typeof(modifiers) == "table" then
		local modifierCount = 0
		local used = {}

		for _, key in ipairs(ORDERED_MODIFIER_KEYS) do
			if modifiers[key] ~= nil then
				modifierCount += 1
				used[key] = true
				local line = makeInfoText(detailFrame, "• " .. formatModifierLine(key, modifiers[key]), 12, COLORS.Text, false)
				line.LayoutOrder = 10 + modifierCount
			end
		end

		for key, value in pairs(modifiers) do
			if not used[key] then
				modifierCount += 1
				local line = makeInfoText(detailFrame, "• " .. formatModifierLine(key, value), 12, COLORS.Text, false)
				line.LayoutOrder = 100 + modifierCount
			end
		end

		if modifierCount <= 0 then
			makeInfoText(detailFrame, "• No mechanical modifiers listed.", 12, COLORS.Muted, false)
		end
	else
		makeInfoText(detailFrame, "• No mechanical modifiers listed.", 12, COLORS.Muted, false)
	end

	headerButton.MouseButton1Click:Connect(function()
		detailFrame.Visible = not detailFrame.Visible
		arrow.Text = detailFrame.Visible and "-" or "+"
	end)
end

-- Panel open/close


local function openTraitPanel()
	if not activeTraitLabel then return end

	clearScroll()

	local names = getTraitNamesFromLabel(activeTraitLabel)
	if #names <= 0 then
		makeInfoText(scroll, "No traits found on this life.", 14, COLORS.SubText, true)
	else
		for index, traitName in ipairs(names) do
			buildTraitCard(traitName, index)
		end
	end

	screenGui.Enabled = true
	overlay.Visible = true
	panel.Visible = true
	overlay.BackgroundTransparency = 1
	panel.BackgroundTransparency = 0.08
	panel.Position = UDim2.new(0.5, 0, 0.53, 0)

	TweenService:Create(overlay, TweenInfo.new(0.12), { BackgroundTransparency = 0.35 }):Play()
	TweenService:Create(panel, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 0,
	}):Play()
end

local function closeTraitPanel()
	local overlayTween = TweenService:Create(overlay, TweenInfo.new(0.1), { BackgroundTransparency = 1 })
	local panelTween = TweenService:Create(panel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 0.53, 0),
		BackgroundTransparency = 0.08,
	})

	overlayTween:Play()
	panelTween:Play()

	panelTween.Completed:Once(function()
		overlay.Visible = false
		panel.Visible = false
		screenGui.Enabled = false
	end)
end

-- Profile scanning & floating button positioning

local function findProfileParts(playerGui: PlayerGui)
	local mainGui = playerGui:FindFirstChild(MAIN_GUI_NAME)
	if not mainGui then return nil, nil, nil end

	local mainPanel = mainGui:FindFirstChild("MainPanel")
	if not mainPanel then return nil, nil, nil end

	local profileCard = mainPanel:FindFirstChild("ProfileCard")
	if not profileCard then return nil, nil, nil end

	local profileScroll = profileCard:FindFirstChild("ProfileScroll")
	if not profileScroll then return nil, nil, profileCard end

	return profileScroll, profileCard, mainGui
end

local function findTraitLabel(profileScroll: Instance?): TextLabel?
	if not profileScroll then return nil end

	-- Dossier layout names the value label "Traits" directly (see
	-- ProfileCard.luau's DInfoRow calls) instead of a single combined
	-- "Traits: X" string, so look it up by name first.
	local byName = profileScroll:FindFirstChild("Traits", true)
	if byName and byName:IsA("TextLabel") then
		return byName
	end

	for _, descendant in ipairs(profileScroll:GetDescendants()) do
		if descendant:IsA("TextLabel") then
			local text = stripRichText(descendant.Text or "")
			if string.sub(text, 1, 7) == "Traits:" then
				return descendant
			end
		end
	end

	return nil
end

local function removeOldBrokenTraitButtons(profileScroll: Instance?)
	if not profileScroll then return end

	for _, descendant in ipairs(profileScroll:GetDescendants()) do
		if descendant.Name == "TraitDetailsButton" or descendant.Name == "TraitDetailsOpenButton" then
			if descendant ~= traitOpenButton then
				descendant:Destroy()
			end
		end
	end
end

local function scanAndAttach(playerGui: PlayerGui)
	local profileScroll, profileCard = findProfileParts(playerGui)
	local traitLabel = findTraitLabel(profileScroll)

	if traitLabel then
		activeTraitLabel = traitLabel
		activeProfileScroll = profileScroll
		activeProfileCard = profileCard
		removeOldBrokenTraitButtons(profileScroll)
		traitLabel.ClipsDescendants = false
	end
end

local function updateFloatingTraitButton()
	if not activeTraitLabel or not activeTraitLabel.Parent or not activeProfileCard or not (activeProfileCard :: any).Parent then
		traitOpenButton.Visible = false
		return
	end

	local labelPos = activeTraitLabel.AbsolutePosition
	local labelSize = activeTraitLabel.AbsoluteSize
	local cardPos = (activeProfileCard :: any).AbsolutePosition
	local cardSize = (activeProfileCard :: any).AbsoluteSize

	if labelSize.Y <= 0 or cardSize.Y <= 0 then
		traitOpenButton.Visible = false
		return
	end

	if traitOpenButton.Parent ~= activeProfileCard then
		traitOpenButton.Parent = activeProfileCard
	end

	local centerYAbs = labelPos.Y + (labelSize.Y * 0.5)
	local visibleTop = cardPos.Y + 4
	local visibleBottom = cardPos.Y + cardSize.Y - 4

	if centerYAbs < visibleTop or centerYAbs > visibleBottom then
		traitOpenButton.Visible = false
		return
	end

	local plainText = stripRichText(activeTraitLabel.Text or "")
	local textWidth = 0

	local ok, measured = pcall(function()
		return TextService:GetTextSize(
			plainText,
			activeTraitLabel.TextSize,
			activeTraitLabel.Font,
			Vector2.new(10000, math.max(24, labelSize.Y))
		)
	end)

	if ok and measured then
		textWidth = measured.X
	else
		pcall(function()
			textWidth = activeTraitLabel.TextBounds.X
		end)
	end

	if textWidth <= 0 then
		textWidth = math.min(labelSize.X, 110)
	end

	local paddingAfterText = 10
	local desiredXAbs = labelPos.X + textWidth + paddingAfterText

	local minXAbs = labelPos.X + 70
	local maxXAbs = cardPos.X + cardSize.X - 18
	local finalXAbs = math.clamp(desiredXAbs, minXAbs, maxXAbs)

	local localX = finalXAbs - cardPos.X
	local localY = centerYAbs - cardPos.Y

	traitOpenButton.Position = UDim2.fromOffset(localX, localY)
	traitOpenButton.Visible = true
end

-- Module init

local function init(playerGui: Instance)
	local existingGui = playerGui:FindFirstChild(GUI_NAME)
	if existingGui then existingGui:Destroy() end

	-- ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = GUI_NAME
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Enabled = false
	screenGui.DisplayOrder = 627
	screenGui.Parent = playerGui

	-- Overlay
	overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.Visible = false
	overlay.Active = true
	overlay.Parent = screenGui

	-- Panel
	panel = Instance.new("Frame")
	panel.Name = "TraitPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	panel.Size = UDim2.new(0, 520, 0, 460)
	panel.BackgroundColor3 = COLORS.Panel
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Active = true
	panel.Parent = overlay
	addCorner(panel, 14)
	addStroke(panel, COLORS.Stroke, 1, 0)
	responsiveScale.attach(panel, 520, 460)

	local panelPadding = Instance.new("UIPadding")
	panelPadding.PaddingTop = UDim.new(0, 14)
	panelPadding.PaddingBottom = UDim.new(0, 14)
	panelPadding.PaddingLeft = UDim.new(0, 14)
	panelPadding.PaddingRight = UDim.new(0, 14)
	panelPadding.Parent = panel

	-- Title
	title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -48, 0, 30)
	title.BackgroundTransparency = 1
	title.TextColor3 = COLORS.Gold
	title.TextSize = 20
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.Text = "TRAITS"
	title.Parent = panel

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.new(1, 0, 0, 0)
	closeButton.Size = UDim2.new(0, 36, 0, 32)
	closeButton.BackgroundColor3 = COLORS.Panel2
	closeButton.BorderSizePixel = 0
	closeButton.TextColor3 = COLORS.Bad
	closeButton.TextSize = 16
	closeButton.Font = Enum.Font.GothamBlack
	closeButton.Text = "X"
	closeButton.AutoButtonColor = false
	closeButton.Parent = panel
	addCorner(closeButton, 8)
	addStroke(closeButton, COLORS.StrokeSoft, 1, 0)

	-- Subtitle
	subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Position = UDim2.new(0, 0, 0, 34)
	subtitle.Size = UDim2.new(1, 0, 0, 34)
	subtitle.BackgroundTransparency = 1
	subtitle.TextColor3 = COLORS.SubText
	subtitle.TextSize = 12
	subtitle.Font = Enum.Font.GothamBold
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.TextYAlignment = Enum.TextYAlignment.Top
	subtitle.TextWrapped = true
	subtitle.Text = "Traits are rolled at birth, passed through legacy, and modify your life progression."
	subtitle.Parent = panel

	-- Scroll
	scroll = Instance.new("ScrollingFrame")
	scroll.Name = "TraitScroll"
	scroll.Position = UDim2.new(0, 0, 0, 76)
	scroll.Size = UDim2.new(1, 0, 1, -76)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 5
	scroll.ScrollBarImageColor3 = COLORS.Stroke
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Parent = panel

	listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 8)
	listLayout.Parent = scroll

	local scrollPadding = Instance.new("UIPadding")
	scrollPadding.PaddingTop = UDim.new(0, 2)
	scrollPadding.PaddingBottom = UDim.new(0, 14)
	scrollPadding.PaddingLeft = UDim.new(0, 2)
	scrollPadding.PaddingRight = UDim.new(0, 8)
	scrollPadding.Parent = scroll

	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
	end)

	-- Floating "?" open button (parented to screenGui initially, moves to ProfileCard)
	traitOpenButton = Instance.new("TextButton")
	traitOpenButton.Name = "TraitDetailsOpenButton"
	traitOpenButton.Size = UDim2.new(0, 22, 0, 22)
	traitOpenButton.AnchorPoint = Vector2.new(0.5, 0.5)
	traitOpenButton.BackgroundColor3 = COLORS.Panel2
	traitOpenButton.BorderSizePixel = 0
	traitOpenButton.TextColor3 = COLORS.Gold
	traitOpenButton.TextSize = 14
	traitOpenButton.Font = Enum.Font.GothamBlack
	traitOpenButton.Text = "?"
	traitOpenButton.AutoButtonColor = false
	traitOpenButton.Visible = false
	traitOpenButton.ZIndex = 50
	traitOpenButton.Parent = screenGui
	addCorner(traitOpenButton, 999)
	addStroke(traitOpenButton, COLORS.StrokeSoft, 1, 0)

	-- Connections
	traitOpenButton.MouseButton1Click:Connect(openTraitPanel)
	closeButton.MouseButton1Click:Connect(closeTraitPanel)

	overlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			closeTraitPanel()
		end
	end)

	panel.InputBegan:Connect(function()
		-- absorb panel clicks so overlay doesn't close
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.Escape and overlay.Visible then
			closeTraitPanel()
		end
	end)

	-- Background: load trait data, scan for profile elements, keep scanning
	task.spawn(function()
		rebuildTraitLookup()

		for _ = 1, 120 do
			scanAndAttach(playerGui :: any)
			updateFloatingTraitButton()
			if activeTraitLabel then break end
			task.wait(0.25)
		end

		while true do
			task.wait(1)
			scanAndAttach(playerGui :: any)
		end
	end)

	-- Frame-accurate floating button tracking
	RunService.RenderStepped:Connect(updateFloatingTraitButton)
end

return { init = init, open = openTraitPanel, close = closeTraitPanel }
