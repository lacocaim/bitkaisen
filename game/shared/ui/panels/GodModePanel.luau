local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local responsiveScale = require("@ui/responsiveScale")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local getGodMode = ReplicatedStorage:WaitForChild("GetGodMode")
local godModeAction = ReplicatedStorage:WaitForChild("GodModeAction")

local GOD_MODE_GAMEPASS_ID = 1861509054

local THEME = {
	Bg = Color3.fromRGB(13, 13, 20),
	Panel = Color3.fromRGB(19, 19, 29),
	Panel2 = Color3.fromRGB(28, 28, 40),
	Stroke = Color3.fromRGB(116, 84, 165),
	Gold = Color3.fromRGB(255, 212, 94),
	Purple = Color3.fromRGB(156, 96, 246),
	Green = Color3.fromRGB(105, 220, 143),
	Red = Color3.fromRGB(235, 82, 104),
	Text = Color3.fromRGB(245, 241, 255),
	Muted = Color3.fromRGB(176, 169, 195),
}

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenGodModeUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 641
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = false
gui.Parent = playerGui

local openButton = Instance.new("TextButton")
openButton.Name = "GodModeButton"
openButton.AnchorPoint = Vector2.new(0, 0)
openButton.Position = UDim2.new(0, 16, 0, 92)
openButton.Size = UDim2.fromOffset(92, 32)
openButton.BackgroundColor3 = THEME.Panel
openButton.BorderSizePixel = 0
openButton.Text = "GOD MODE"
openButton.TextColor3 = THEME.Gold
openButton.Font = Enum.Font.GothamBlack
openButton.TextSize = 11
openButton.AutoButtonColor = true
openButton.Visible = false
openButton.Parent = gui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 8)
openCorner.Parent = openButton

local openStroke = Instance.new("UIStroke")
openStroke.Color = THEME.Stroke
openStroke.Thickness = 1
openStroke.Parent = openButton

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.42
overlay.BorderSizePixel = 0
overlay.Size = UDim2.fromScale(1, 1)
overlay.Visible = false
overlay.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.BackgroundColor3 = THEME.Bg
panel.BorderSizePixel = 0
panel.Parent = overlay
responsiveScale.attach(panel, 620, 610)

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = THEME.Stroke
panelStroke.Thickness = 1
panelStroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(18, 14)
title.Size = UDim2.new(1, -70, 0, 30)
title.Text = "GOD MODE"
title.TextColor3 = THEME.Gold
title.Font = Enum.Font.GothamBlack
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local close = Instance.new("TextButton")
close.Name = "Close"
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -16, 0, 14)
close.Size = UDim2.fromOffset(36, 32)
close.BackgroundColor3 = THEME.Panel2
close.BorderSizePixel = 0
close.Text = "X"
close.TextColor3 = THEME.Red
close.Font = Enum.Font.GothamBlack
close.TextSize = 16
close.Parent = panel
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Scroll"
scroll.Position = UDim2.fromOffset(18, 56)
scroll.Size = UDim2.new(1, -36, 1, -74)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local payload = nil
local render

local function clearContent()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function makeCard(height)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, height)
	card.BackgroundColor3 = THEME.Panel
	card.BorderSizePixel = 0
	card.Parent = scroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(52, 48, 72)
	stroke.Thickness = 1
	stroke.Parent = card
	return card
end

local function makeLabel(parent, text, y, height, color, size, bold)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(12, y)
	label.Size = UDim2.new(1, -24, 0, height)
	label.Text = text
	label.TextColor3 = color or THEME.Text
	label.Font = bold and Enum.Font.GothamBlack or Enum.Font.GothamBold
	label.TextSize = size or 13
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Parent = parent
	return label
end

local function makeButton(parent, text, x, y, w, h, color, callback)
	local button = Instance.new("TextButton")
	button.Position = UDim2.fromOffset(x, y)
	button.Size = UDim2.fromOffset(w, h)
	button.BackgroundColor3 = color or THEME.Purple
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = THEME.Text
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 11
	button.TextWrapped = true
	button.Parent = parent
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)
	button.Activated:Connect(callback)
	return button
end

local function fetchPayload()
	local ok, result = pcall(function()
		return getGodMode:InvokeServer()
	end)
	if ok and typeof(result) == "table" then
		payload = result
	else
		payload = { Owned = false, Error = "Could not load God Mode." }
	end
	return payload
end

local function fire(actionId, data)
	godModeAction:FireServer(actionId, data or {})
	task.delay(0.25, function()
		fetchPayload()
		if overlay.Visible then
			render()
		end
	end)
end

render = function()
	clearContent()
	local data = payload or fetchPayload()

	-- Multiplayer Fase 8 (Fair Play Doctrine): the account-wide gamepass never
	-- applies inside a Public world, so a different purchase path (and
	-- explicit "only this world" copy) shows up there instead -- never both.
	if data.IsPublic then
		local summaryCard = makeCard(data.Owned and 106 or 182)
		makeLabel(summaryCard, "Permanent life controls", 10, 20, THEME.Gold, 15, true)
		if data.Owned then
			makeLabel(summaryCard, "Tune traits, clan rerolls, start boosts, legacy inheritance, and reset the current life while keeping God Mode settings.", 36, 50, THEME.Muted, 12, false)
			-- fall through to the rest of the panel below
		else
			makeLabel(summaryCard, "This unlock applies ONLY to the Public world you're in right now -- not your account, not any other world. Buy it again separately for each Public world you want it in.", 36, 60, THEME.Muted, 12, false)
			makeButton(summaryCard, "UNLOCK FOR THIS WORLD", 12, 100, 220, 34, THEME.Purple, function()
				if tonumber(data.GodModeThisWorldProductId) and data.GodModeThisWorldProductId > 0 then
					MarketplaceService:PromptProductPurchase(player, data.GodModeThisWorldProductId)
				end
			end)
			return
		end
	else
		local summaryCard = makeCard(data.Owned and 106 or 158)
		makeLabel(summaryCard, "Permanent life controls", 10, 20, THEME.Gold, 15, true)
		makeLabel(summaryCard, data.Owned and "Tune traits, clan rerolls, start boosts, legacy inheritance, and reset the current life while keeping God Mode settings." or "Unlock God Mode to use trait edits, clan rerolls, start boosts, legacy inheritance, and reset life controls.", 36, 50, THEME.Muted, 12, false)
		if not data.Owned then
			makeButton(summaryCard, "UNLOCK", 12, 104, 190, 34, THEME.Purple, function()
				if tonumber(data.PassId) and data.PassId > 0 then
					MarketplaceService:PromptGamePassPurchase(player, data.PassId)
				end
			end)
			return
		end
	end

	local settings = data.Settings or {}
	local boostCard = makeCard(126)
	makeLabel(boostCard, "Start Boost", 10, 20, THEME.Gold, 15, true)
	makeLabel(boostCard, "Pick one boost for the start of each fresh life. Current: " .. tostring(settings.StartBoost or "None"), 34, 30, THEME.Muted, 12, false)
	local boosts = { {"NONE", "None"}, {"CE", "CE"}, {"STATS", "Stats"}, {"LUCK", "Luck"} }
	for index, option in ipairs(boosts) do
		local x = 12 + ((index - 1) * 68)
		makeButton(boostCard, option[1], x, 76, 62, 34, option[2] == settings.StartBoost and THEME.Green or THEME.Purple, function()
			fire("set_start_boost", { Choice = option[2] })
		end)
	end

	local legacyCard = makeCard(86)
	makeLabel(legacyCard, "Child Traits", 10, 20, THEME.Gold, 15, true)
	makeLabel(legacyCard, "Guaranteed Legacy Traits: " .. (settings.GuaranteedLegacyTraits and "ON" or "OFF"), 34, 22, THEME.Muted, 12, false)
	makeButton(legacyCard, settings.GuaranteedLegacyTraits and "TURN OFF" or "TURN ON", 12, 48, 245, 30, settings.GuaranteedLegacyTraits and THEME.Red or THEME.Green, function()
		fire("toggle_legacy_traits", { Enabled = not settings.GuaranteedLegacyTraits })
	end)

	local clanOptions = data.ClanOptions or {}
	local clanListHeight = math.min(#clanOptions * 26, 130)
	local clanCardHeight = 142 + clanListHeight + (clanListHeight > 0 and 10 or 0)
	local clanCard = makeCard(clanCardHeight)
	makeLabel(clanCard, "Clan Control", 10, 20, THEME.Gold, 15, true)
	makeLabel(clanCard, tostring(data.CurrentClan or "Unknown") .. " • " .. tostring(data.ClanRerollsUsed or 0) .. "/" .. tostring(data.ClanRerollsMax or 3) .. " rerolls used. Type a clan name or pick from the list.", 34, 34, THEME.Muted, 12, false)
	makeButton(clanCard, "REROLL CLAN", 12, 72, 145, 30, THEME.Purple, function()
		fire("reroll_clan")
	end)
	local clanBox = Instance.new("TextBox")
	clanBox.Position = UDim2.fromOffset(166, 72)
	clanBox.Size = UDim2.new(1, -302, 0, 30)
	clanBox.BackgroundColor3 = THEME.Panel2
	clanBox.BorderSizePixel = 0
	clanBox.PlaceholderText = "Gojo / Zenin / ..."
	clanBox.Text = ""
	clanBox.TextColor3 = THEME.Text
	clanBox.PlaceholderColor3 = THEME.Muted
	clanBox.Font = Enum.Font.GothamBold
	clanBox.TextSize = 12
	clanBox.ClearTextOnFocus = false
	clanBox.Parent = clanCard
	Instance.new("UICorner", clanBox).CornerRadius = UDim.new(0, 7)
	makeButton(clanCard, "PICK", 12, 106, 145, 28, THEME.Green, function()
		fire("select_clan", { ClanName = clanBox.Text })
	end)

	if #clanOptions > 0 then
		local clanScroll = Instance.new("ScrollingFrame")
		clanScroll.Position = UDim2.fromOffset(12, 140)
		clanScroll.Size = UDim2.new(1, -24, 0, clanListHeight)
		clanScroll.BackgroundColor3 = THEME.Panel2
		clanScroll.BorderSizePixel = 0
		clanScroll.ScrollBarThickness = 4
		clanScroll.ScrollBarImageColor3 = THEME.Muted
		clanScroll.CanvasSize = UDim2.new(0, 0, 0, #clanOptions * 26)
		clanScroll.Parent = clanCard
		Instance.new("UICorner", clanScroll).CornerRadius = UDim.new(0, 6)
		local clanLayout = Instance.new("UIListLayout")
		clanLayout.SortOrder = Enum.SortOrder.LayoutOrder
		clanLayout.Parent = clanScroll
		for idx, clan in ipairs(clanOptions) do
			local clanBtn = Instance.new("TextButton")
			clanBtn.Size = UDim2.new(1, 0, 0, 26)
			clanBtn.BackgroundTransparency = idx % 2 == 0 and 0.6 or 0.8
			clanBtn.BackgroundColor3 = THEME.Panel
			clanBtn.BorderSizePixel = 0
			clanBtn.Text = "  " .. tostring(clan.Name or "Unknown") .. "  (" .. tostring(clan.Category or "Clan") .. ")"
			clanBtn.TextColor3 = THEME.Text
			clanBtn.Font = Enum.Font.GothamBold
			clanBtn.TextSize = 11
			clanBtn.TextXAlignment = Enum.TextXAlignment.Left
			clanBtn.TextWrapped = true
			clanBtn.LayoutOrder = idx
			clanBtn.Parent = clanScroll
			clanBtn.Activated:Connect(function()
				fire("select_clan", { ClanName = clan.FamilyName or clan.Name })
			end)
		end
	end

	local traitCard = makeCard(202)
	makeLabel(traitCard, "Trait Editor", 10, 20, THEME.Gold, 15, true)
	makeLabel(traitCard, "Add " .. tostring(data.TraitAddsUsed or 0) .. "/" .. tostring(data.TraitAddsMax or 2) .. " • Remove " .. tostring(data.TraitRemovesUsed or 0) .. "/" .. tostring(data.TraitRemovesMax or 2), 34, 22, THEME.Muted, 12, false)

	local traitBox = Instance.new("TextBox")
	traitBox.Position = UDim2.fromOffset(12, 62)
	traitBox.Size = UDim2.new(1, -24, 0, 34)
	traitBox.BackgroundColor3 = THEME.Panel2
	traitBox.BorderSizePixel = 0
	traitBox.PlaceholderText = "Type trait name or id"
	traitBox.Text = ""
	traitBox.TextColor3 = THEME.Text
	traitBox.PlaceholderColor3 = THEME.Muted
	traitBox.Font = Enum.Font.GothamBold
	traitBox.TextSize = 12
	traitBox.ClearTextOnFocus = false
	traitBox.Parent = traitCard
	Instance.new("UICorner", traitBox).CornerRadius = UDim.new(0, 7)

	makeButton(traitCard, "ADD", 12, 106, 124, 32, THEME.Green, function()
		fire("add_trait", { TraitName = traitBox.Text })
	end)
	makeButton(traitCard, "REMOVE", 144, 106, 124, 32, THEME.Red, function()
		fire("remove_trait", { TraitName = traitBox.Text })
	end)

	local ownedNames = {}
	for _, trait in ipairs(data.CurrentTraits or {}) do
		table.insert(ownedNames, trait.Name .. " [" .. trait.Rarity .. "]")
	end
	makeLabel(traitCard, "Current: " .. (#ownedNames > 0 and table.concat(ownedNames, ", ") or "None"), 148, 42, THEME.Muted, 11, false)

	local resetCard = makeCard(92)
	makeLabel(resetCard, "Reset Life", 10, 20, THEME.Gold, 15, true)
	makeLabel(resetCard, "Restart current life instantly. God Mode settings stay, but current-life uses reset.", 34, 26, THEME.Muted, 12, false)
	makeButton(resetCard, "RESET LIFE", 12, 60, 245, 30, Color3.fromRGB(126, 75, 32), function()
		fire("reset_life")
		overlay.Visible = false
	end)
end

openButton.Activated:Connect(function()
	fetchPayload()
	render()
	overlay.Visible = true
	gui.Enabled = true
end)

close.Activated:Connect(function()
	overlay.Visible = false
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(purchasePlayer, purchasedPassId, wasPurchased)
	if purchasePlayer ~= player then return end
	if purchasedPassId ~= GOD_MODE_GAMEPASS_ID then return end
	task.delay(0.5, function()
		fetchPayload()
		if overlay.Visible then
			render()
		end
	end)
end)

-- Refreshes after the "God Mode (This World)" Dev Product purchase (server
-- applies the unlock in ProcessReceipt, which finishes slightly before or
-- around when this event fires -- the short delay covers the gap).
MarketplaceService.PromptProductPurchaseFinished:Connect(function(purchasePlayer, purchasedProductId, wasPurchased)
	if purchasePlayer ~= player or wasPurchased ~= true then return end
	if not payload or purchasedProductId ~= tonumber(payload.GodModeThisWorldProductId) then return end
	task.delay(0.5, function()
		fetchPayload()
		if overlay.Visible then
			render()
		end
	end)
end)

local function open()
	fetchPayload()
	render()
	overlay.Visible = true
	gui.Enabled = true
end

local function init()
	gui.Enabled = true
end

return { init = init, open = open }
