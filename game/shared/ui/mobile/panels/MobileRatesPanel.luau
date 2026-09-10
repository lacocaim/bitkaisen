local Players = game:GetService("Players")

local uiState = require("@ui-state/uiState")
local mc = require("@ui/mobile/mobileComponents")

local theme = mc.theme
local mobileCard = mc.mobileCard
local mobileLabel = mc.mobileLabel
local mobileSheet = mc.mobileSheet

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui: ScreenGui
local sheet: Frame
local scroll: ScrollingFrame

local CLAN_RATES = {
	{ Tier = "Common Clan", Rate = "65%", Color = theme.SubText },
	{ Tier = "Uncommon Clan", Rate = "20%", Color = theme.SubText },
	{ Tier = "Rare Clan", Rate = "10%", Color = theme.Blue },
	{ Tier = "Epic Clan", Rate = "3.5%", Color = theme.Purple },
	{ Tier = "Legendary Clan", Rate = "1.4%", Color = theme.Gold, Note = "Example: Itadori" },
	{ Tier = "Honored Clan", Rate = "0.09%", Color = theme.Orange, Note = "Example: Gojo" },
	{ Tier = "Secret Clan", Rate = "???", Color = theme.Bad, Note = "Example: Pumpkin King" },
}

local CT_RATES = {
	{ Tier = "Common CT", Rate = "65%", Color = theme.SubText },
	{ Tier = "Uncommon CT", Rate = "20%", Color = theme.SubText },
	{ Tier = "Rare CT", Rate = "10%", Color = theme.Blue },
	{ Tier = "Epic CT", Rate = "3.5%", Color = theme.Purple },
	{ Tier = "Legendary CT", Rate = "1.4%", Color = theme.Gold },
	{ Tier = "Honored CT", Rate = "0.09%", Color = theme.Orange },
	{ Tier = "Secret CT", Rate = "???", Color = theme.Bad },
}

-- Update 31: the traits section, asked for by Vigilante. Counted from the trait table at
-- load rather than typed in, so the numbers cannot drift from the game. Mirrors the
-- desktop RatesPanel.
local TRAIT_RATES = {}
do
	local counts, total = {}, 0
	local ok, traits = pcall(function()
		return require(game:GetService("ReplicatedStorage"):WaitForChild("BitKaisenTraits", 5))
	end)
	if ok and typeof(traits) == "table" and typeof(traits.Definitions) == "table" then
		for _, definition in ipairs(traits.Definitions) do
			if definition.Id and definition.Name then
				total += 1
				local rarity = tostring(definition.Rarity or "Common")
				counts[rarity] = (counts[rarity] or 0) + 1
			end
		end
	end
	local order = {
		{ "Common", theme.SubText }, { "Uncommon", theme.SubText }, { "Rare", theme.Blue },
		{ "Legendary", theme.Gold }, { "Mythic", theme.Bad },
	}
	for _, entry in ipairs(order) do
		local count = counts[entry[1]]
		if count and count > 0 then
			table.insert(TRAIT_RATES, { Tier = entry[1] .. " Trait", Rate = tostring(count), Color = entry[2] })
		end
	end
	if total > 0 then
		table.insert(TRAIT_RATES, 1, {
			Tier = "All traits", Rate = tostring(total), Color = theme.Text,
			Note = "Born with some, the rest are earned by living",
		})
	end
end

local function clearScroll()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function buildRateRow(parent: GuiObject, tier: string, rate: string, color: Color3, note: string?, order: number)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.Parent = parent

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.Padding = UDim.new(0, 0)
	rowLayout.Parent = row

	local tierLabel = Instance.new("TextLabel")
	tierLabel.Size = UDim2.new(0.6, 0, 0, 22)
	tierLabel.BackgroundTransparency = 1
	tierLabel.Text = tier
	tierLabel.TextColor3 = color
	tierLabel.TextSize = 14
	tierLabel.Font = Enum.Font.GothamMedium
	tierLabel.TextXAlignment = Enum.TextXAlignment.Left
	tierLabel.LayoutOrder = 1
	tierLabel.Parent = row

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Size = UDim2.new(0.4, 0, 0, 22)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = rate
	rateLabel.TextColor3 = color
	rateLabel.TextSize = 14
	rateLabel.Font = Enum.Font.GothamBold
	rateLabel.TextXAlignment = Enum.TextXAlignment.Right
	rateLabel.LayoutOrder = 2
	rateLabel.Parent = row

	if note then
		local noteLabel = Instance.new("TextLabel")
		noteLabel.Size = UDim2.new(1, 0, 0, 18)
		noteLabel.BackgroundTransparency = 1
		noteLabel.Text = note
		noteLabel.TextColor3 = theme.Muted
		noteLabel.TextSize = 12
		noteLabel.Font = Enum.Font.GothamMedium
		noteLabel.TextXAlignment = Enum.TextXAlignment.Left
		noteLabel.TextWrapped = true
		noteLabel.Parent = parent
		noteLabel.LayoutOrder = order + 1
	end
end

local function buildSection(title: string, rates: { { Tier: string, Rate: string, Color: Color3, Note: string? } }, order: number)
	local card = mobileCard({
		parent = scroll,
		accentColor = theme.Gold,
		order = order,
	})

	mobileLabel({
		parent = card,
		text = title,
		size = 16,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 0,
	})

	local rowOrder = 1
	for _, entry in ipairs(rates) do
		buildRateRow(card, entry.Tier, entry.Rate, entry.Color, entry.Note, rowOrder)
		rowOrder += entry.Note and 2 or 1
	end
end

local function refresh()
	clearScroll()
	buildSection("Clan Rates", CLAN_RATES, 0)
	buildSection("Cursed Technique Rates", CT_RATES, 1)

	local footerOrder = 2
	if #TRAIT_RATES > 0 then
		buildSection("Traits", TRAIT_RATES, 2)
		footerOrder = 3
	end

	local footerCard = mobileCard({
		parent = scroll,
		color = Color3.fromRGB(30, 26, 18),
		accentColor = theme.Muted,
		order = footerOrder,
	})

	mobileLabel({
		parent = footerCard,
		text = "Secret rates are intentionally hidden.",
		size = 13,
		color = theme.Muted,
		font = Enum.Font.GothamMedium,
		order = 1,
	})
end

local function openPanel()
	gui.Enabled = true
	refresh()
end

local function closePanel()
	gui.Enabled = false
end

local function init()
	gui = Instance.new("ScreenGui")
	gui.Name = "MobileRatesGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 644
	gui.Enabled = false
	gui.Parent = playerGui

	sheet = mobileSheet({
		name = "MobileRatesSheet",
		parent = gui,
		title = "CLAN / CT RATES",
		onClose = function()
			uiState.closeRoute()
		end,
	})

	scroll = sheet:FindFirstChildWhichIsA("ScrollingFrame") :: ScrollingFrame
	sheet.Visible = true

	uiState.subscribe(function(route)
		if route == "rates" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
