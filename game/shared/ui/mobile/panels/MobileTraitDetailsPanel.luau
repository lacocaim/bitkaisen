local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local uiState = require("@ui-state/uiState")
local playerState = require("@ui-state/playerState")
local mc = require("@ui/mobile/mobileComponents")

local theme = mc.theme
local mobileCard = mc.mobileCard
local mobileLabel = mc.mobileLabel
local mobileSheet = mc.mobileSheet

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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

local INVERSE_MULT_KEYS = {
	HappinessLossMult = true,
	RiskMult = true,
	StressMult = true,
	MarriageReqMult = true,
}

local traitModule = nil
local traitDefinitions = {}
local traitLookupByName = {}
local traitLookupById = {}

local gui: ScreenGui
local sheet: Frame
local scroll: ScrollingFrame

-- Helpers (mirrored from PC panel)

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
	return text:gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeKey(text: string): string
	text = stripRichText(text)
	text = string.lower(text)
	text = text:gsub("[^%w]+", "_")
	text = text:gsub("^_+", ""):gsub("_+$", "")
	return text
end

local function formatNumber(value: number): string
	value = tonumber(value) or 0
	if math.abs(value - math.floor(value)) < 0.001 then
		return tostring(math.floor(value))
	end
	return string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", "")
end

local function formatModifierLine(key: string, value: any): string
	local label = MODIFIER_LABELS[key] or tostring(key)
	local numberValue = tonumber(value)

	if numberValue == nil then
		return label .. ": " .. tostring(value)
	end

	if MULT_KEYS[key] then
		if INVERSE_MULT_KEYS[key] then
			local delta = (numberValue - 1) * 100
			if delta < 0 then
				return label .. ": " .. tostring(math.abs(math.floor(delta - 0.5))) .. "% lower"
			elseif delta > 0 then
				return label .. ": " .. tostring(math.floor(delta + 0.5)) .. "% higher"
			end
			return label .. ": no change"
		end
		local delta = (numberValue - 1) * 100
		local sign = delta >= 0 and "+" or ""
		return label .. ": " .. sign .. tostring(math.floor(delta + (delta >= 0 and 0.5 or -0.5))) .. "%"
	end

	if key == "StartingMoneyBonus" then
		local sign = numberValue >= 0 and "+" or ""
		return label .. ": " .. sign .. "$" .. formatNumber(numberValue)
	end

	local sign = numberValue >= 0 and "+" or ""
	return label .. ": " .. sign .. formatNumber(numberValue)
end

-- Trait data loading (same source as PC panel: ReplicatedStorage.BitKaisenTraits)

local function safeRequireTraitModule()
	if traitModule ~= nil then
		return traitModule
	end

	local moduleScript = ReplicatedStorage:FindFirstChild("BitKaisenTraits")
	if not moduleScript then
		warn("[MobileTraitDetailsPanel] ReplicatedStorage.BitKaisenTraits was not found.")
		return nil
	end

	local ok, result = pcall(function()
		return require(moduleScript)
	end)

	if not ok then
		warn("[MobileTraitDetailsPanel] Could not require BitKaisenTraits: " .. tostring(result))
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

-- Extract trait names from playerState or by scanning PlayerGui labels

local function getTraitNames(): { string }
	local stats = playerState.stats()
	if stats then
		local raw = stats.Traits
		if typeof(raw) == "table" then
			local names = {}
			for _, v in ipairs(raw) do
				local cleaned = trim(tostring(v))
				if cleaned ~= "" and string.lower(cleaned) ~= "none" then
					table.insert(names, cleaned)
				end
			end
			if #names > 0 then return names end
		end
		if typeof(raw) == "string" and raw ~= "" then
			local names = {}
			for part in string.gmatch(raw, "([^,]+)") do
				local cleaned = trim(part)
				if cleaned ~= "" and string.lower(cleaned) ~= "none" then
					table.insert(names, cleaned)
				end
			end
			if #names > 0 then return names end
		end
	end

	for _, descendant in ipairs(playerGui:GetDescendants()) do
		if descendant:IsA("TextLabel") then
			local text = stripRichText(descendant.Text or "")
			if string.sub(text, 1, 7) == "Traits:" then
				text = text:gsub("^%s*Traits%s*:%s*", "")
				text = trim(text)
				if text ~= "" and string.lower(text) ~= "none" then
					local names = {}
					for part in string.gmatch(text, "([^,]+)") do
						local cleaned = trim(part)
						if cleaned ~= "" and string.lower(cleaned) ~= "none" then
							table.insert(names, cleaned)
						end
					end
					if #names > 0 then return names end
				end
			end
		end
	end

	return {}
end

-- Scroll helpers

local function clearList()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function modifierColor(key: string, value: number): Color3
	if INVERSE_MULT_KEYS[key] then
		if value < 1 then return theme.Green end
		if value > 1 then return theme.Bad end
		return theme.SubText
	end
	if MULT_KEYS[key] then
		if value > 1 then return theme.Green end
		if value < 1 then return theme.Bad end
		return theme.SubText
	end
	if value > 0 then return theme.Green end
	if value < 0 then return theme.Bad end
	return theme.SubText
end

-- Build a single collapsible trait card

local function buildTraitCard(traitName: string, order: number)
	local definition = findTraitDefinition(traitName)

	local displayName = traitName
	local rarity = "Unknown"
	local category = "Trait"
	local description = "No description found for this trait."
	local modifiers = nil

	if definition then
		displayName = tostring(definition.Name or traitName)
		rarity = tostring(definition.Rarity or "Unknown")
		category = tostring(definition.Category or "Trait")
		description = tostring(definition.Description or description)
		modifiers = definition.Modifiers
	end

	local rarityColor = RARITY_COLORS[rarity] or theme.Text

	local card = mobileCard({
		parent = scroll,
		order = order,
		accentColor = rarityColor,
	})

	-- Header row: Name + rarity badge
	mobileLabel({
		parent = card,
		text = displayName,
		size = 16,
		color = rarityColor,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	mobileLabel({
		parent = card,
		text = rarity .. "  \u{2022}  " .. category,
		size = 12,
		color = theme.Muted,
		font = Enum.Font.GothamBold,
		order = 2,
	})

	-- Description
	mobileLabel({
		parent = card,
		text = description,
		size = 13,
		color = theme.SubText,
		order = 3,
	})

	-- Modifiers section
	if typeof(modifiers) == "table" then
		local modifierCount = 0
		local used = {}

		local headerLabel = mobileLabel({
			parent = card,
			text = "Buffs",
			size = 13,
			color = theme.Gold,
			font = Enum.Font.GothamBold,
			order = 10,
		})

		for _, key in ipairs(ORDERED_MODIFIER_KEYS) do
			if modifiers[key] ~= nil then
				modifierCount += 1
				used[key] = true
				local numVal = tonumber(modifiers[key])
				mobileLabel({
					parent = card,
					text = "\u{2022} " .. formatModifierLine(key, modifiers[key]),
					size = 12,
					color = if numVal then modifierColor(key, numVal) else theme.Text,
					order = 10 + modifierCount,
				})
			end
		end

		for key, value in pairs(modifiers) do
			if not used[key] then
				modifierCount += 1
				local numVal = tonumber(value)
				mobileLabel({
					parent = card,
					text = "\u{2022} " .. formatModifierLine(key, value),
					size = 12,
					color = if numVal then modifierColor(key, numVal) else theme.Text,
					order = 100 + modifierCount,
				})
			end
		end

		if modifierCount <= 0 then
			headerLabel.Text = ""
			mobileLabel({
				parent = card,
				text = "No mechanical modifiers.",
				size = 12,
				color = theme.Muted,
				order = 11,
			})
		end
	else
		mobileLabel({
			parent = card,
			text = "No mechanical modifiers.",
			size = 12,
			color = theme.Muted,
			order = 10,
		})
	end
end

-- Panel lifecycle

local function refresh()
	clearList()

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = scroll

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 16)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = scroll

	-- Info subtitle
	local infoCard = mobileCard({ parent = scroll, order = 0, accentColor = theme.Gold })
	mobileLabel({
		parent = infoCard,
		text = "Traits are rolled at birth, passed through legacy, and modify your life progression.",
		size = 13,
		color = theme.SubText,
		font = Enum.Font.GothamBold,
		order = 1,
	})

	local names = getTraitNames()

	if #names <= 0 then
		local emptyCard = mobileCard({ parent = scroll, order = 1 })
		mobileLabel({
			parent = emptyCard,
			text = "No traits found on this life.",
			size = 14,
			color = theme.SubText,
			font = Enum.Font.GothamBold,
			order = 1,
		})
		return
	end

	for i, traitName in ipairs(names) do
		buildTraitCard(traitName, i)
	end
end

local function openPanel()
	gui.Enabled = true
	sheet.Visible = true
	refresh()
end

local function closePanel()
	sheet.Visible = false
	gui.Enabled = false
end

local function init()
	gui = Instance.new("ScreenGui")
	gui.Name = "BitKaisenMobileTraitDetailsGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 628
	gui.Enabled = false
	gui.Parent = playerGui

	sheet = mobileSheet({
		name = "MobileTraitDetailsSheet",
		parent = gui,
		title = "TRAITS",
		onClose = function()
			uiState.closeRoute()
		end,
	})

	scroll = sheet:FindFirstChildWhichIsA("ScrollingFrame") :: ScrollingFrame

	task.spawn(rebuildTraitLookup)

	uiState.subscribe(function(route)
		if route == "trait_details" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
