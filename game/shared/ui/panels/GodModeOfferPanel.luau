-- Multiplayer monetization nudge: a small, dossier-styled offer modal shown
-- once per life by GuideController/MobileGuideController, roughly 10 real
-- minutes into a Public-world life, if the player hasn't already unlocked
-- God Mode for that specific world (see BK_GodModeService.GetPayload's
-- IsPublic/Owned fields, checked right before this shows -- see the caller).
-- Shared between PC and Mobile since it's a plain centered overlay, not part
-- of either dashboard's own layout -- same reasoning as TimeSkipOfferPanel.luau.
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

-- Same product ID BK_CommerceService.GOD_MODE_THIS_WORLD_PRODUCT_ID sells
-- this under -- kept in sync manually since there's no shared constants
-- module for product IDs today (same precedent as TimeSkipOfferPanel.luau).
local GOD_MODE_THIS_WORLD_PRODUCT_ID = 3611191860
local TEST_PURCHASE_PLACE_ID = 104206065947170

local testPurchase = ReplicatedStorage:WaitForChild("TestPurchase")

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
gui.Name = "BitKaisenGodModeOfferUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 683
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
card.Name = "GodModeOfferCard"
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.fromScale(0.5, 0.5)
card.Size = UDim2.fromOffset(380, 264)
card.BackgroundColor3 = GM_BG
card.BorderSizePixel = 0
card.Active = true
card.Parent = overlay
addCorner(card, 10)
addStroke(card, GM_STROKE, 1, 0)
responsiveScale.attach(card, 380, 264)

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
title.Text = _g("godmode_offer_title", "Settling In?")
title.TextColor3 = GM_GOLD
title.TextSize = 20
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = card

local body = Instance.new("TextLabel")
body.BackgroundTransparency = 1
body.Position = UDim2.new(0, 18, 0, 48)
body.Size = UDim2.new(1, -36, 0, 72)
body.Text = _g("godmode_offer_body", "You've been building your story in this world for a while. God Mode unlocks full control over traits, clan, and life resets -- only for this world.")
body.TextColor3 = GM_MUTED
body.TextSize = 12
body.Font = Enum.Font.GothamMedium
body.TextWrapped = true
body.TextXAlignment = Enum.TextXAlignment.Left
body.TextYAlignment = Enum.TextYAlignment.Top
body.Parent = card

local buyButton = Instance.new("TextButton")
buyButton.Name = "UnlockButton"
buyButton.Position = UDim2.new(0, 18, 0, 130)
buyButton.Size = UDim2.new(1, -36, 0, 48)
buyButton.BackgroundColor3 = Color3.fromRGB(38, 34, 52)
buyButton.AutoButtonColor = true
buyButton.Text = ""
buyButton.Parent = card
addCorner(buyButton, 8)
addStroke(buyButton, GM_STROKE, 1, 0.4)

local buyLabel = Instance.new("TextLabel")
buyLabel.BackgroundTransparency = 1
buyLabel.Position = UDim2.new(0, 12, 0, 0)
buyLabel.Size = UDim2.new(1, -100, 1, 0)
buyLabel.Text = _g("godmode_offer_option", "Unlock For This World")
buyLabel.TextColor3 = GM_TEXT
buyLabel.TextSize = 14
buyLabel.Font = Enum.Font.GothamBlack
buyLabel.TextXAlignment = Enum.TextXAlignment.Left
buyLabel.Parent = buyButton

local buyPrice = Instance.new("TextLabel")
buyPrice.BackgroundTransparency = 1
buyPrice.AnchorPoint = Vector2.new(1, 0.5)
buyPrice.Position = UDim2.new(1, -12, 0.5, 0)
buyPrice.Size = UDim2.new(0, 70, 1, 0)
buyPrice.Text = "R$ 399"
buyPrice.TextColor3 = GM_GOLD
buyPrice.TextSize = 13
buyPrice.Font = Enum.Font.GothamBlack
buyPrice.TextXAlignment = Enum.TextXAlignment.Right
buyPrice.Parent = buyButton

buyButton.Activated:Connect(function()
	promptProduct(GOD_MODE_THIS_WORLD_PRODUCT_ID)
end)

local skipButton = Instance.new("TextButton")
skipButton.Name = "NoThanksButton"
skipButton.BackgroundTransparency = 1
skipButton.Position = UDim2.new(0, 18, 1, -36)
skipButton.Size = UDim2.new(1, -36, 0, 20)
skipButton.Text = _g("godmode_offer_skip", "No thanks")
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

closeButton.Activated:Connect(close)
skipButton.Activated:Connect(close)

return { show = show, close = close }
