-- Mobile counterpart of WorldModePanel.luau (PC). Shown once per new life,
-- before MobileCharacterCustomizationPanel opens, only while
-- stats.WorldMode == nil. Multiplayer Fase 1 -- see sorted-popping-haven.md
-- plan ("Multijugador -- Fase 1: Fundaciones").
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local mc = require("@ui/mobile/mobileComponents")
local remotes = require("@ui-state/remotes")
local MobileWorldBrowserPanel = require("@ui/mobile/panels/MobileWorldBrowserPanel")

local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _g(key: string, fallback: string): string
	return BitKaisenLocale.tOrFallback(_L, "worldmode." .. key, nil, fallback)
end

local theme = mc.theme

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUI_NAME = "BitKaisenMobileWorldModeGui"

local state = { IsOpen = false, Choosing = false }

local existing = playerGui:FindFirstChild(GUI_NAME)
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 640
gui.Enabled = false
gui.AutoLocalize = false
gui.Parent = playerGui

-- Opaque full-screen backdrop -- NOT a semi-transparent scrim like PC's
-- modal (which sits over a separately-drawn opaque "window" card). Mobile
-- never got that inner window, so the dashboard showed through at 25%
-- transparency. Matches the established Mobile convention (mobileSheet's
-- full-opaque background) instead of inventing a floating-card layout.
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.BackgroundColor3 = theme.Bg
overlay.BackgroundTransparency = 0
overlay.BorderSizePixel = 0
overlay.Size = UDim2.fromScale(1, 1)
overlay.Active = true
overlay.Parent = gui

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0.5, 0, 0, 60)
title.AnchorPoint = Vector2.new(0.5, 0)
title.Size = UDim2.new(1, -40, 0, 30)
title.Text = _g("title", "Choose Your Path")
title.TextColor3 = theme.Gold
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = overlay

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.new(0.5, 0, 0, 92)
subtitle.AnchorPoint = Vector2.new(0.5, 0)
subtitle.Size = UDim2.new(1, -50, 0, 40)
subtitle.Text = _g("subtitle", "One life is yours alone - the other is shared by every sorcerer brave enough to live it.")
subtitle.TextColor3 = theme.SubText
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 12
subtitle.TextWrapped = true
subtitle.TextXAlignment = Enum.TextXAlignment.Center
subtitle.Parent = overlay

local column = Instance.new("Frame")
column.Position = UDim2.new(0.5, 0, 0, 150)
column.AnchorPoint = Vector2.new(0.5, 0)
column.Size = UDim2.new(1, -32, 1, -170)
column.BackgroundTransparency = 1
column.Parent = overlay

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 14)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = column

-- Pulido visual (pedido de Luisa, referencia BitSeas): en vez de un icono
-- emoji generico, un sello circular de tinta roja como el "Stamp" del
-- dossier (mobileShell.luau MobileProfileHeader) -- dos lineas de kanji
-- inventado, mismo tono burocratico "Bureau of Jujutsu Affairs".
local function makeSeal(parent: Instance, topText: string, bottomText: string, size: number)
	local seal = Instance.new("Frame")
	seal.Name = "Seal"
	seal.AnchorPoint = Vector2.new(0.5, 0)
	seal.Position = UDim2.new(0.5, 0, 0, 14)
	seal.Size = UDim2.fromOffset(size, size)
	seal.BackgroundColor3 = Color3.fromRGB(6, 4, 10)
	seal.BorderSizePixel = 0
	seal.Parent = parent
	mc.corner(seal, size / 2)
	local outerStroke = Instance.new("UIStroke")
	outerStroke.Color = Color3.fromRGB(110, 25, 25)
	outerStroke.Thickness = 1.5
	outerStroke.Parent = seal

	local inner = Instance.new("Frame")
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.fromScale(0.5, 0.5)
	inner.Size = UDim2.new(1, -8, 1, -8)
	inner.BackgroundTransparency = 1
	inner.BorderSizePixel = 0
	inner.Parent = seal
	mc.corner(inner, size / 2)
	local innerStroke = Instance.new("UIStroke")
	innerStroke.Color = Color3.fromRGB(80, 18, 18)
	innerStroke.Thickness = 0.8
	innerStroke.Parent = inner

	local topLabel = Instance.new("TextLabel")
	topLabel.Position = UDim2.new(0, 0, 0.14, 0)
	topLabel.Size = UDim2.new(1, 0, 0.4, 0)
	topLabel.BackgroundTransparency = 1
	topLabel.Text = topText
	topLabel.TextColor3 = Color3.fromRGB(150, 38, 38)
	topLabel.TextSize = 11
	topLabel.Font = Enum.Font.GothamBold
	topLabel.TextXAlignment = Enum.TextXAlignment.Center
	topLabel.Parent = seal

	local bottomLabel = Instance.new("TextLabel")
	bottomLabel.Position = UDim2.new(0, 0, 0.5, 0)
	bottomLabel.Size = UDim2.new(1, 0, 0.4, 0)
	bottomLabel.BackgroundTransparency = 1
	bottomLabel.Text = bottomText
	bottomLabel.TextColor3 = Color3.fromRGB(195, 52, 52)
	bottomLabel.TextSize = 12
	bottomLabel.Font = Enum.Font.GothamBlack
	bottomLabel.TextXAlignment = Enum.TextXAlignment.Center
	bottomLabel.Parent = seal

	return seal
end

local function makeCard(order: number, sealTop: string, sealBottom: string, accent: Color3, label: string, heading: string, body: string, mode: string, ctaText: string, onActivate: () -> ())
	local card = Instance.new("Frame")
	card.Name = mode
	card.LayoutOrder = order
	card.Size = UDim2.new(1, 0, 0, 236)
	card.BackgroundColor3 = theme.Card
	card.BorderSizePixel = 0
	card.Parent = column
	mc.corner(card, 10)
	mc.stroke(card, theme.StrokeSoft, 1)

	-- Visual polish pass: thin colored accent bar along the top.
	local accentClip = Instance.new("Frame")
	accentClip.BackgroundTransparency = 1
	accentClip.ClipsDescendants = true
	accentClip.Size = UDim2.new(1, 0, 0, 4)
	accentClip.Parent = card
	local accentBar = Instance.new("Frame")
	accentBar.BorderSizePixel = 0
	accentBar.BackgroundColor3 = accent
	accentBar.Size = UDim2.new(1, 0, 1, 6)
	accentBar.Parent = accentClip

	makeSeal(card, sealTop, sealBottom, 64)

	local tag = Instance.new("TextLabel")
	tag.BackgroundTransparency = 1
	tag.AnchorPoint = Vector2.new(0.5, 0)
	tag.Position = UDim2.new(0.5, 0, 0, 82)
	tag.Size = UDim2.new(1, -28, 0, 16)
	tag.Text = label
	tag.TextColor3 = accent
	tag.Font = Enum.Font.GothamBlack
	tag.TextSize = 11
	tag.TextXAlignment = Enum.TextXAlignment.Center
	tag.Parent = card

	local headingLabel = Instance.new("TextLabel")
	headingLabel.BackgroundTransparency = 1
	headingLabel.AnchorPoint = Vector2.new(0.5, 0)
	headingLabel.Position = UDim2.new(0.5, 0, 0, 98)
	headingLabel.Size = UDim2.new(1, -20, 0, 24)
	headingLabel.Text = heading
	headingLabel.TextColor3 = theme.Text
	headingLabel.Font = Enum.Font.GothamBlack
	headingLabel.TextSize = 16
	headingLabel.TextXAlignment = Enum.TextXAlignment.Center
	headingLabel.Parent = card

	local divider = Instance.new("Frame")
	divider.BackgroundColor3 = theme.StrokeSoft
	divider.BorderSizePixel = 0
	divider.Position = UDim2.fromOffset(14, 128)
	divider.Size = UDim2.new(1, -28, 0, 1)
	divider.Parent = card

	local desc = Instance.new("TextLabel")
	desc.BackgroundTransparency = 1
	desc.Position = UDim2.fromOffset(14, 140)
	desc.Size = UDim2.new(1, -28, 0, 40)
	desc.Text = body
	desc.TextColor3 = theme.SubText
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 12
	desc.TextWrapped = true
	desc.TextXAlignment = Enum.TextXAlignment.Center
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.Parent = card

	local button = Instance.new("TextButton")
	button.Name = "CTA"
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.new(0.5, 0, 1, -14)
	button.Size = UDim2.new(1, -28, 0, 40)
	button.BackgroundColor3 = accent
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Text = ctaText
	button.TextColor3 = Color3.fromRGB(15, 13, 10)
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 14
	button.Parent = card
	mc.corner(button, 6)
	button.Activated:Connect(onActivate)

	return card
end

local chooseWorldMode = remotes.get("ChooseWorldMode")

local function close()
	if not state.IsOpen then
		return
	end
	state.IsOpen = false
	gui.Enabled = false
end

local function choose(mode: string)
	if state.Choosing then
		return
	end
	state.Choosing = true
	if chooseWorldMode then
		chooseWorldMode:FireServer(mode)
	end
	close()
end

local function open()
	if state.IsOpen or state.Choosing then
		return
	end
	state.IsOpen = true
	gui.Enabled = true
end

makeCard(1, "個人記録", "封印済", theme.Purple, _g("private_tag", "PRIVATE"), _g("private_title", "Your Own Era"), _g("private_body", "The classic BitKaisen life - live, rise, fall, and raise a dynasty at your own pace."), "Private", _g("private_cta", "BEGIN YOUR OWN ERA"), function()
	choose("Private")
end)

-- Multiplayer Fase 4: same change as WorldModePanel.luau (PC) -- Público
-- opens the Buscador de Mundos instead of committing to ChooseWorldMode
-- immediately. `open` passed as a callback avoids a circular require.
makeCard(2, "共有世界", "開放中", theme.Gold, _g("public_tag", "PUBLIC"), _g("public_title", "The Shared World"), _g("public_body", "One shared world, real sorcerers, one calendar. Forge your legend among true rivals."), "Public", _g("public_cta", "ENTER THE SHARED WORLD"), function()
	close()
	MobileWorldBrowserPanel.open(open)
end)

-- Multiplayer Fase 1: shown once per join (matches BitSeas), not once per
-- life -- the server fires PromptWorldMode right at PlayerAdded, before any
-- life is loaded or started, and waits for ChooseWorldMode before doing so.
local function init()
	local promptWorldMode = remotes.get("PromptWorldMode")
	if not promptWorldMode then
		return
	end

	promptWorldMode.OnClientEvent:Connect(function()
		state.Choosing = false
		open()
	end)
end

return { init = init }
