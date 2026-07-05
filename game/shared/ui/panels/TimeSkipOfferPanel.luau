-- Fase 6 (gancho de Time Skip): a small, dossier-styled offer modal shown
-- once per life by GuideController/MobileGuideController when the
-- GuideTimeSkipTip signal fires (see those files -- either the 4 categories
-- are genuinely exhausted, or the player has aged up repeatedly without
-- touching any of them, both read as "just wants to skip ahead in time").
-- Shared between PC and Mobile since it's a plain centered overlay, not part
-- of either dashboard's own layout -- same reasoning as topbarIcons.luau/
-- FocusHighlight.luau being platform-agnostic.
--
-- Per Luisa: don't just point at the Settings icon and make the player dig
-- for the product themselves -- show the actual purchase options directly,
-- same as BitSeas does, mirroring the opt-in "Keep the Guide on?" modal's
-- own flat GodModePanel-style convention (see FirstTimeGuidancePanel.luau).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local responsiveScale = require("@ui/responsiveScale")

local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _g(key: string, fallback: string): string
	return BitKaisenLocale.tOrFallback(_L, "guidance." .. key, nil, fallback)
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Same product IDs SettingsPanel.luau's shop already sells these under (Time
-- Skip category) -- kept in sync manually since there's no shared constants
-- module for product IDs today.
local TIME_SKIP_5_PRODUCT_ID = 3607128993
local TIME_SKIP_10_PRODUCT_ID = 3607129012
local TIME_SKIP_25_PRODUCT_ID = 3607129036
local TEST_PURCHASE_PLACE_ID = 104206065947170

local testPurchase = ReplicatedStorage:WaitForChild("TestPurchase")

-- Mirrors SettingsPanel.luau's promptRobuxItem (kept local there) so
-- purchases here go through the exact same test-place-aware path.
local function promptProduct(robloxId: number)
	if game.PlaceId == TEST_PURCHASE_PLACE_ID then
		testPurchase:FireServer("Product", robloxId)
		return
	end
	MarketplaceService:PromptProductPurchase(player, robloxId)
end

local GM_BG = Color3.fromRGB(13, 13, 20)
local GM_STROKE = Color3.fromRGB(116, 84, 165)
local GM_GOLD = Color3.fromRGB(255, 212, 94)
local GM_PURPLE = Color3.fromRGB(156, 96, 246)
local GM_MUTED = Color3.fromRGB(176, 169, 195)
local GM_TEXT = Color3.fromRGB(245, 243, 252)

local function addCorner(parent: Instance, radius: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = parent
	return corner
end

local function addStroke(parent: Instance, color: Color3, thickness: number?, transparency: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenTimeSkipOfferUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 682
gui.Enabled = false
gui.AutoLocalize = false
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.4
overlay.BorderSizePixel = 0
overlay.Active = true
overlay.Parent = gui

local card = Instance.new("Frame")
card.Name = "TimeSkipOfferCard"
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.fromScale(0.5, 0.5)
card.Size = UDim2.fromOffset(380, 300)
card.BackgroundColor3 = GM_BG
card.BorderSizePixel = 0
card.Active = true
card.Parent = overlay
addCorner(card, 10)
addStroke(card, GM_STROKE, 1, 0)
responsiveScale.attach(card, 380, 300)

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -12, 0, 12)
closeButton.Size = UDim2.fromOffset(24, 24)
closeButton.BackgroundColor3 = Color3.fromRGB(30, 20, 24)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(240, 90, 90)
closeButton.TextSize = 14
closeButton.Font = Enum.Font.GothamBlack
closeButton.AutoButtonColor = true
closeButton.Parent = card
addCorner(closeButton, 6)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 18, 0, 16)
title.Size = UDim2.new(1, -50, 0, 26)
title.Text = _g("timeskip_offer_title", "Skip Ahead?")
title.TextColor3 = GM_GOLD
title.TextSize = 20
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = card

local body = Instance.new("TextLabel")
body.BackgroundTransparency = 1
body.Position = UDim2.new(0, 18, 0, 48)
body.Size = UDim2.new(1, -36, 0, 48)
body.Text = _g("timeskip_offer_body", "Looks like you're aging up fast. A Time Skip jumps years ahead instantly.")
body.TextColor3 = GM_MUTED
body.TextSize = 12
body.Font = Enum.Font.GothamMedium
body.TextWrapped = true
body.TextXAlignment = Enum.TextXAlignment.Left
body.TextYAlignment = Enum.TextYAlignment.Top
body.Parent = card

local OPTIONS = {
	{ years = 5, robloxId = TIME_SKIP_5_PRODUCT_ID, price = "R$ 75" },
	{ years = 10, robloxId = TIME_SKIP_10_PRODUCT_ID, price = "R$ 149" },
	{ years = 25, robloxId = TIME_SKIP_25_PRODUCT_ID, price = "R$ 299" },
}

local OPTIONS_TOP = 104
local OPTION_HEIGHT = 44
local OPTION_GAP = 8

for i, opt in ipairs(OPTIONS) do
	local btn = Instance.new("TextButton")
	btn.Name = "TimeSkip" .. opt.years
	btn.Position = UDim2.new(0, 18, 0, OPTIONS_TOP + (i - 1) * (OPTION_HEIGHT + OPTION_GAP))
	btn.Size = UDim2.new(1, -36, 0, OPTION_HEIGHT)
	btn.BackgroundColor3 = Color3.fromRGB(38, 34, 52)
	btn.AutoButtonColor = true
	btn.Text = ""
	btn.Parent = card
	addCorner(btn, 8)
	addStroke(btn, GM_STROKE, 1, 0.4)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 12, 0, 0)
	label.Size = UDim2.new(1, -80, 1, 0)
	label.Text = string.format(_g("timeskip_offer_option", "+%d Years"), opt.years)
	label.TextColor3 = GM_TEXT
	label.TextSize = 14
	label.Font = Enum.Font.GothamBlack
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = btn

	local priceLabel = Instance.new("TextLabel")
	priceLabel.BackgroundTransparency = 1
	priceLabel.AnchorPoint = Vector2.new(1, 0.5)
	priceLabel.Position = UDim2.new(1, -12, 0.5, 0)
	priceLabel.Size = UDim2.new(0, 70, 1, 0)
	priceLabel.Text = opt.price
	priceLabel.TextColor3 = GM_GOLD
	priceLabel.TextSize = 13
	priceLabel.Font = Enum.Font.GothamBlack
	priceLabel.TextXAlignment = Enum.TextXAlignment.Right
	priceLabel.Parent = btn

	btn.MouseButton1Click:Connect(function()
		promptProduct(opt.robloxId)
	end)
end

local skipButton = Instance.new("TextButton")
skipButton.Name = "NoThanksButton"
skipButton.BackgroundTransparency = 1
skipButton.Position = UDim2.new(0, 18, 1, -36)
skipButton.Size = UDim2.new(1, -36, 0, 20)
skipButton.Text = _g("timeskip_offer_skip", "No thanks")
skipButton.TextColor3 = GM_MUTED
skipButton.TextSize = 11
skipButton.Font = Enum.Font.GothamMedium
skipButton.AutoButtonColor = false
skipButton.Parent = card

local function close()
	gui.Enabled = false
end

local function show()
	gui.Enabled = true
end

closeButton.MouseButton1Click:Connect(close)
skipButton.MouseButton1Click:Connect(close)

return { show = show, close = close }
