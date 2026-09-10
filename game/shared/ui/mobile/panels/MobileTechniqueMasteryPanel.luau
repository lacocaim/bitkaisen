local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local uiState = require("@ui-state/uiState")
local remotes = require("@ui-state/remotes")
local playerState = require("@ui-state/playerState")
local mc = require("@ui/mobile/mobileComponents")

local BitKaisenTechniqueEffects = require(ReplicatedStorage:WaitForChild("BitKaisenTechniqueEffects"))
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local L = BitKaisenLocale.getClientLocale()
local function _tm(key, fallback) return BitKaisenLocale.tOrFallback(L, "mastery." .. key, nil, fallback) end

local theme = mc.theme
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ROUTE = "technique_mastery"

local isOpen = false
local currentStats = nil

local gui: ScreenGui
local sheet: Frame
local scroll: ScrollingFrame

local STAGE_DATA = {
	{ Min = 0, Max = 9, Name = "Dormant Control", Short = "Dormant", Description = "You barely understand how your cursed technique reacts.", Color = Color3.fromRGB(125, 125, 150) },
	{ Min = 10, Max = 24, Name = "Basic Control", Short = "Basic", Description = "You can use your technique, but it is still unstable.", Color = Color3.fromRGB(120, 170, 255) },
	{ Min = 25, Max = 49, Name = "Refined Control", Short = "Refined", Description = "Your technique is becoming reliable during assignments.", Color = Color3.fromRGB(130, 220, 170) },
	{ Min = 50, Max = 74, Name = "Advanced Application", Short = "Advanced", Description = "Your technique is starting to define your sorcerer identity.", Color = Color3.fromRGB(180, 130, 255) },
	{ Min = 75, Max = 94, Name = "Elite Mastery", Short = "Elite", Description = "You are dangerous even among trained sorcerers.", Color = Color3.fromRGB(255, 205, 105) },
	{ Min = 95, Max = 100, Name = "Complete Mastery", Short = "Complete", Description = "Your control is near the top of the jujutsu world.", Color = Color3.fromRGB(255, 105, 150) },
}

-- Update 31: technique descriptions and mastery flavor lines both live in one shared
-- module now, so the desktop and mobile panels can never drift apart again. Every
-- technique in BitKaisenStats.Techniques has an entry in both tables.
local BitKaisenTechniqueLore = require(ReplicatedStorage:WaitForChild("BitKaisenTechniqueLore"))
local TECHNIQUE_FLAVOR = BitKaisenTechniqueLore.Flavor
local TECHNIQUE_DESCRIPTION = BitKaisenTechniqueLore.Descriptions

local CE_TRAIT_DISPLAY = {
	lightning_ce      = "Lightning CE",
	cursed_flame_ce   = "Cursed Flame CE",
	infinity_pulse_ce = "Infinity Pulse CE",
	venom_ce          = "Venom CE",
	serene_ce         = "Serene CE",
	cursed_pressure_ce= "Cursed Pressure CE",
}

local TIMELINE_DATA = {
	{ Value = 0, Label = "Dormant", Note = "Technique barely awakened" },
	{ Value = 10, Label = "Basic", Note = "Stable enough to use" },
	{ Value = 25, Label = "Refined", Note = "Mission choices improve" },
	{ Value = 50, Label = "Advanced", Note = "Stronger CT applications" },
	{ Value = 75, Label = "Elite", Note = "High-level pressure" },
	{ Value = 95, Label = "Domain Path", Note = "Future domain unlock path" },
}

local function getTechniqueName(stats)
	if not stats then return "None" end
	local ct = tostring(stats.CursedTechnique or "None")
	if ct == "None" or ct == "" then
		ct = tostring(stats.InnateTechnique or "None")
	end
	return ct
end

local function getMastery(stats)
	if not stats then return 0 end
	return math.clamp(math.floor(stats.TechniqueMastery or 0), 0, 100)
end

local function getMissionPowerBonus(mastery)
	return math.floor(mastery * 0.55)
end

local function getTechniqueFlavor(technique)
	return TECHNIQUE_FLAVOR[technique] or "Your cursed technique grows through training, assignments, pressure, and life events. Higher mastery improves mission power and can unlock better technique-specific choices."
end

local function getStageData(mastery)
	for _, data in ipairs(STAGE_DATA) do
		if mastery >= data.Min and mastery <= data.Max then
			return data
		end
	end
	return STAGE_DATA[1]
end

local function getNextStageData(mastery)
	for _, data in ipairs(STAGE_DATA) do
		if mastery < data.Min then
			return data
		end
	end
	return nil
end

local function clearList()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
end

local barFillRef: Frame? = nil

local function buildMasteryBar(parent: GuiObject, mastery: number, stageColor: Color3, order: number): Frame
	local barContainer = Instance.new("Frame")
	barContainer.Size = UDim2.new(1, 0, 0, 22)
	barContainer.BackgroundTransparency = 1
	barContainer.LayoutOrder = order
	barContainer.Parent = parent

	local barBack = Instance.new("Frame")
	barBack.Size = UDim2.new(1, 0, 1, 0)
	barBack.BackgroundColor3 = Color3.fromRGB(26, 26, 38)
	barBack.BorderSizePixel = 0
	barBack.Parent = barContainer
	mc.corner(barBack, 999)
	mc.stroke(barBack, theme.Stroke)

	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(mastery / 100, 0, 1, 0)
	barFill.BackgroundColor3 = stageColor
	barFill.BorderSizePixel = 0
	barFill.Parent = barBack
	mc.corner(barFill, 999)
	barFillRef = barFill

	local percentLabel = Instance.new("TextLabel")
	percentLabel.Size = UDim2.new(1, 0, 1, 0)
	percentLabel.BackgroundTransparency = 1
	percentLabel.TextColor3 = theme.Text
	percentLabel.TextSize = 12
	percentLabel.Font = Enum.Font.GothamBlack
	percentLabel.Text = tostring(mastery) .. " / 100"
	percentLabel.Parent = barBack

	return barContainer
end

local function buildTimelineCard(parent: GuiObject, mastery: number, order: number)
	local card = mc.mobileCard({ parent = parent, accentColor = theme.Purple, order = order })

	mc.mobileLabel({
		parent = card,
		text = "MASTERY TIMELINE",
		size = 15,
		color = theme.Text,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	for i, data in ipairs(TIMELINE_DATA) do
		local unlocked = mastery >= data.Value
		local nodeColor = unlocked and theme.Purple or theme.Muted
		local labelColor = unlocked and theme.Text or theme.SubText
		local noteColor = unlocked and theme.SubText or theme.Muted

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 26)
		row.BackgroundTransparency = 1
		row.LayoutOrder = i + 1
		row.Parent = card

		local dot = Instance.new("Frame")
		dot.Size = UDim2.fromOffset(10, 10)
		dot.Position = UDim2.new(0, 0, 0.5, -5)
		dot.BackgroundColor3 = nodeColor
		dot.BorderSizePixel = 0
		dot.Parent = row
		mc.corner(dot, 999)

		local valueLabel = Instance.new("TextLabel")
		valueLabel.Size = UDim2.new(0, 34, 1, 0)
		valueLabel.Position = UDim2.new(0, 16, 0, 0)
		valueLabel.BackgroundTransparency = 1
		valueLabel.TextColor3 = unlocked and theme.Gold or theme.Muted
		valueLabel.TextSize = 12
		valueLabel.Font = Enum.Font.GothamBlack
		valueLabel.Text = tostring(data.Value) .. "+"
		valueLabel.TextXAlignment = Enum.TextXAlignment.Left
		valueLabel.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0, 70, 1, 0)
		nameLabel.Position = UDim2.new(0, 52, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = labelColor
		nameLabel.TextSize = 13
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.Text = data.Label
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Parent = row

		local noteLabel = Instance.new("TextLabel")
		noteLabel.Size = UDim2.new(1, -130, 1, 0)
		noteLabel.Position = UDim2.new(0, 126, 0, 0)
		noteLabel.BackgroundTransparency = 1
		noteLabel.TextColor3 = noteColor
		noteLabel.TextSize = 11
		noteLabel.Font = Enum.Font.GothamMedium
		noteLabel.Text = data.Note
		noteLabel.TextXAlignment = Enum.TextXAlignment.Left
		noteLabel.TextWrapped = true
		noteLabel.TextTruncate = Enum.TextTruncate.AtEnd
		noteLabel.Parent = row
	end
end

local function refresh()
	clearList()

	local stats = currentStats or playerState.stats()
	if not stats then stats = {} end

	local technique = getTechniqueName(stats)
	local mastery = getMastery(stats)
	local stage = getStageData(mastery)
	local nextData = getNextStageData(mastery)
	local powerBonus = getMissionPowerBonus(mastery)

	-- Technique header card
	local headerCard = mc.mobileCard({ parent = scroll, accentColor = stage.Color, order = 1 })

	mc.mobileLabel({
		parent = headerCard,
		text = string.upper(technique),
		size = 18,
		color = theme.Purple,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	mc.mobileLabel({
		parent = headerCard,
		text = stage.Name,
		size = 13,
		color = stage.Color,
		font = Enum.Font.GothamBlack,
		order = 2,
	})

	buildMasteryBar(headerCard, mastery, stage.Color, 3)

	local nextText
	if nextData then
		local needed = math.max(0, nextData.Min - mastery)
		nextText = _tm("next_prefix", "Next: {name} at {min}"):gsub("{name}", nextData.Name):gsub("{min}", tostring(nextData.Min))
			.. " (" .. _tm("needed", "{n} needed"):gsub("{n}", tostring(needed)) .. ")"
	else
		nextText = _tm("complete_cap", "Complete: you have reached the current mastery cap.")
	end

	mc.mobileLabel({
		parent = headerCard,
		text = nextText,
		size = 12,
		color = theme.Gold,
		font = Enum.Font.GothamBold,
		order = 4,
	})

	-- Stats row card
	local statsCard = mc.mobileCard({ parent = scroll, order = 2 })

	mc.mobileLabel({
		parent = statsCard,
		text = BitKaisenLocale.tOrFallback(L, "ui.stats", nil, "Stats"),
		size = 14,
		color = theme.Text,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	mc.mobileLabel({
		parent = statsCard,
		text = "Mission Power Bonus: <b>+" .. tostring(powerBonus) .. "</b>",
		size = 13,
		color = theme.Green,
		font = Enum.Font.GothamMedium,
		order = 2,
	})

	mc.mobileLabel({
		parent = statsCard,
		text = "Current Stage: <b>" .. stage.Name .. "</b>",
		size = 13,
		color = theme.SubText,
		font = Enum.Font.GothamMedium,
		order = 3,
	})

	mc.mobileLabel({
		parent = statsCard,
		text = stage.Description,
		size = 12,
		color = theme.Muted,
		font = Enum.Font.GothamMedium,
		order = 4,
	})

	-- Technique notes card
	local notesCard = mc.mobileCard({ parent = scroll, order = 3 })

	mc.mobileLabel({
		parent = notesCard,
		text = "TECHNIQUE NOTES",
		size = 14,
		color = theme.Text,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	local flavorBody
	if technique == "None" then
		flavorBody = "You have not awakened an innate cursed technique yet. Age up, train cursed energy, and survive long enough for your cursed energy to take shape."
	else
		local effectNote = BitKaisenTechniqueEffects.GetTechniqueNote(stats)
		flavorBody = getTechniqueFlavor(technique)
		if effectNote and effectNote ~= "" then
			flavorBody = flavorBody .. "\n\nCombat effect: " .. effectNote
		end
	end

	mc.mobileLabel({
		parent = notesCard,
		text = flavorBody,
		size = 12,
		color = theme.SubText,
		font = Enum.Font.GothamMedium,
		order = 2,
	})

	-- CT Info card
	local infoCard = mc.mobileCard({ parent = scroll, order = 4 })

	mc.mobileLabel({
		parent = infoCard,
		text = "TECHNIQUE INFO",
		size = 14,
		color = theme.Text,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	local desc = TECHNIQUE_DESCRIPTION[technique]
	mc.mobileLabel({
		parent = infoCard,
		text = desc or (technique == "None" and "Your technique has not manifested yet." or "Description not yet available."),
		size = 12,
		color = theme.SubText,
		font = Enum.Font.GothamMedium,
		order = 2,
	})

	local traitId = tostring(stats.CETrait or "")
	local traitLabel = CE_TRAIT_DISPLAY[traitId] or "None"
	mc.mobileLabel({
		parent = infoCard,
		text = "CE Trait: <b>" .. traitLabel .. "</b>",
		size = 12,
		color = traitId ~= "" and theme.Gold or theme.Muted,
		font = Enum.Font.GothamMedium,
		order = 3,
	})

	local awakeText, awakeColor
	if stats.AwakeningTriggered == true then
		local ctx = tostring(stats.AwakeningContext or "")
		local ctxLabel = ctx == "near_death" and "near-death" or ctx == "domain_loss" and "domain loss" or ctx == "mission_survive" and "mission survival" or ctx == "age_threshold" and "age threshold" or "event"
		awakeText = "Awakening: Triggered (" .. ctxLabel .. ")"
		awakeColor = theme.Purple
	elseif stats.AwakeningEligible == true then
		awakeText = "Awakening: Eligible, conditions not yet met"
		awakeColor = theme.Gold
	else
		awakeText = "Awakening: Not applicable"
		awakeColor = theme.Muted
	end

	mc.mobileLabel({
		parent = infoCard,
		text = awakeText,
		size = 12,
		color = awakeColor,
		font = Enum.Font.GothamMedium,
		order = 4,
	})

	-- Timeline card
	buildTimelineCard(scroll, mastery, 5)
end

local function openPanel()
	if isOpen then return end
	isOpen = true
	gui.Enabled = true
	sheet.Visible = true
	refresh()
end

local function closePanel()
	if not isOpen then return end
	isOpen = false
	sheet.Visible = false
	gui.Enabled = false
end

local function init()
	gui = Instance.new("ScreenGui")
	gui.Name = "BitKaisenMobileTechniqueMasteryGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 626
	gui.Enabled = false
	gui.Parent = playerGui

	sheet = mc.mobileSheet({
		name = "MobileTechniqueMasterySheet",
		parent = gui,
		title = "TECHNIQUE MASTERY",
		onClose = function()
			uiState.closeRoute()
		end,
	})

	scroll = sheet:FindFirstChildWhichIsA("ScrollingFrame") :: ScrollingFrame

	uiState.subscribe(function(route)
		if route == ROUTE then
			openPanel()
		else
			if isOpen then closePanel() end
		end
	end)

	local ule = remotes.updateLifeEvent()
	if ule then
		ule.OnClientEvent:Connect(function(updatedStats)
			if typeof(updatedStats) == "table" then
				currentStats = updatedStats
				if isOpen then refresh() end
			end
		end)
	end
end

return { init = init }
