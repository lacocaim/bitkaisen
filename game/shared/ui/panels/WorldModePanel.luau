-- Shown once per new life, before CharacterCustomizationPanel opens, only
-- while stats.WorldMode == nil (see the guard added to
-- CharacterCustomizationPanel.luau). Multiplayer Fase 1 -- see
-- sorted-popping-haven.md plan ("Multijugador -- Fase 1: Fundaciones").
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local responsiveScale = require("@ui/responsiveScale")
local remotes = require("@ui-state/remotes")
local WorldBrowserPanel = require("@ui-panels/WorldBrowserPanel")

local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _g(key: string, fallback: string): string
	return BitKaisenLocale.tOrFallback(_L, "worldmode." .. key, nil, fallback)
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUI_NAME = "BitKaisenWorldModeGui"

local THEME = {
	Bg = Color3.fromRGB(13, 13, 20),
	Panel = Color3.fromRGB(19, 19, 29),
	CardStroke = Color3.fromRGB(52, 48, 72),
	Stroke = Color3.fromRGB(116, 84, 165),
	Gold = Color3.fromRGB(255, 212, 94),
	Purple = Color3.fromRGB(156, 96, 246),
	Text = Color3.fromRGB(245, 241, 255),
	Muted = Color3.fromRGB(176, 169, 195),
}

local state = { IsOpen = false, Choosing = false }

local existing = playerGui:FindFirstChild(GUI_NAME)
if existing then
	existing:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 640
screenGui.Enabled = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.AutoLocalize = false
screenGui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.25
overlay.BorderSizePixel = 0
overlay.Size = UDim2.fromScale(1, 1)
overlay.Visible = false
overlay.Active = true
overlay.Parent = screenGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.BackgroundColor3 = THEME.Bg
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = overlay
responsiveScale.attach(panel, 640, 460)

Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = THEME.Stroke
panelStroke.Thickness = 1
panelStroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(0, 18)
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = _g("title", "Choose Your Path")
title.TextColor3 = THEME.Gold
title.Font = Enum.Font.GothamBlack
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = panel

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(0, 50)
subtitle.Size = UDim2.new(1, 0, 0, 20)
subtitle.Text = _g("subtitle", "One life is yours alone - the other is shared by every sorcerer brave enough to live it.")
subtitle.TextColor3 = THEME.Muted
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 12
subtitle.TextXAlignment = Enum.TextXAlignment.Center
subtitle.Parent = panel

local row = Instance.new("Frame")
row.Name = "Row"
row.Position = UDim2.fromOffset(24, 90)
row.Size = UDim2.new(1, -48, 1, -110)
row.BackgroundTransparency = 1
row.Parent = panel

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0, 16)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = row

-- Pulido visual (pedido de Luisa, referencia BitSeas): en vez de un icono
-- emoji generico, un sello circular de tinta roja como el "Stamp" del
-- dossier (mobileShell.luau MobileProfileHeader) -- dos lineas de kanji
-- inventado, mismo tono burocratico "Bureau of Jujutsu Affairs".
local function makeSeal(parent: Instance, topText: string, bottomText: string, size: number)
	local seal = Instance.new("Frame")
	seal.Name = "Seal"
	seal.AnchorPoint = Vector2.new(0.5, 0)
	seal.Position = UDim2.new(0.5, 0, 0, 18)
	seal.Size = UDim2.fromOffset(size, size)
	seal.BackgroundColor3 = Color3.fromRGB(6, 4, 10)
	seal.BorderSizePixel = 0
	seal.Parent = parent
	Instance.new("UICorner", seal).CornerRadius = UDim.new(1, 0)
	local outerStroke = Instance.new("UIStroke")
	outerStroke.Color = Color3.fromRGB(110, 25, 25)
	outerStroke.Thickness = 1.5
	outerStroke.Parent = seal

	local inner = Instance.new("Frame")
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.fromScale(0.5, 0.5)
	inner.Size = UDim2.new(1, -10, 1, -10)
	inner.BackgroundTransparency = 1
	inner.BorderSizePixel = 0
	inner.Parent = seal
	Instance.new("UICorner", inner).CornerRadius = UDim.new(1, 0)
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
	topLabel.TextSize = 13
	topLabel.Font = Enum.Font.GothamBold
	topLabel.TextXAlignment = Enum.TextXAlignment.Center
	topLabel.Parent = seal

	local bottomLabel = Instance.new("TextLabel")
	bottomLabel.Position = UDim2.new(0, 0, 0.5, 0)
	bottomLabel.Size = UDim2.new(1, 0, 0.4, 0)
	bottomLabel.BackgroundTransparency = 1
	bottomLabel.Text = bottomText
	bottomLabel.TextColor3 = Color3.fromRGB(195, 52, 52)
	bottomLabel.TextSize = 14
	bottomLabel.Font = Enum.Font.GothamBlack
	bottomLabel.TextXAlignment = Enum.TextXAlignment.Center
	bottomLabel.Parent = seal

	return seal
end

local function makeCard(order: number, sealTop: string, sealBottom: string, accent: Color3, label: string, title2: string, body: string, mode: string, ctaText: string, onActivate: () -> ())
	local card = Instance.new("Frame")
	card.Name = mode
	card.LayoutOrder = order
	card.Size = UDim2.new(0.5, -8, 1, 0)
	card.BackgroundColor3 = THEME.Panel
	card.BorderSizePixel = 0
	card.Parent = row
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME.CardStroke
	stroke.Thickness = 1
	stroke.Parent = card

	-- Visual polish pass: a thin colored accent bar along the top (matches
	-- the dossier look used elsewhere -- ProfileCard's stat bars, etc.),
	-- clipped to the card's own rounded corners.
	local accentClip = Instance.new("Frame")
	accentClip.BackgroundTransparency = 1
	accentClip.ClipsDescendants = true
	accentClip.Size = UDim2.new(1, 0, 0, 4)
	accentClip.ZIndex = card.ZIndex
	accentClip.Parent = card
	local accentBar = Instance.new("Frame")
	accentBar.BorderSizePixel = 0
	accentBar.BackgroundColor3 = accent
	accentBar.Size = UDim2.new(1, 0, 1, 6)
	accentBar.Parent = accentClip

	makeSeal(card, sealTop, sealBottom, 76)

	local tag = Instance.new("TextLabel")
	tag.BackgroundTransparency = 1
	tag.AnchorPoint = Vector2.new(0.5, 0)
	tag.Position = UDim2.new(0.5, 0, 0, 104)
	tag.Size = UDim2.new(1, -32, 0, 16)
	tag.Text = label
	tag.TextColor3 = accent
	tag.Font = Enum.Font.GothamBlack
	tag.TextSize = 12
	tag.TextXAlignment = Enum.TextXAlignment.Center
	tag.Parent = card

	local heading = Instance.new("TextLabel")
	heading.BackgroundTransparency = 1
	heading.AnchorPoint = Vector2.new(0.5, 0)
	heading.Position = UDim2.new(0.5, 0, 0, 122)
	heading.Size = UDim2.new(1, -24, 0, 26)
	heading.Text = title2
	heading.TextColor3 = THEME.Text
	heading.Font = Enum.Font.GothamBlack
	heading.TextSize = 19
	heading.TextXAlignment = Enum.TextXAlignment.Center
	heading.Parent = card

	local divider = Instance.new("Frame")
	divider.BackgroundColor3 = THEME.CardStroke
	divider.BorderSizePixel = 0
	divider.Position = UDim2.fromOffset(16, 160)
	divider.Size = UDim2.new(1, -32, 0, 1)
	divider.Parent = card

	local desc = Instance.new("TextLabel")
	desc.BackgroundTransparency = 1
	desc.Position = UDim2.fromOffset(16, 174)
	desc.Size = UDim2.new(1, -32, 0, 120)
	desc.Text = body
	desc.TextColor3 = THEME.Muted
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 13
	desc.TextWrapped = true
	desc.TextXAlignment = Enum.TextXAlignment.Center
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.Parent = card

	local button = Instance.new("TextButton")
	button.Name = "CTA"
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.new(0.5, 0, 1, -16)
	button.Size = UDim2.new(1, -32, 0, 40)
	button.BackgroundColor3 = accent
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Text = ctaText
	button.TextColor3 = Color3.fromRGB(15, 13, 10)
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 14
	button.Parent = card
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
	button.Activated:Connect(onActivate)

	return card
end

local chooseWorldMode = remotes.get("ChooseWorldMode")

local function close()
	if not state.IsOpen then
		return
	end
	state.IsOpen = false
	overlay.Visible = false
	screenGui.Enabled = false
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
	screenGui.Enabled = true
	overlay.Visible = true
end

makeCard(1, "個人記録", "封印済", THEME.Purple, _g("private_tag", "PRIVATE"), _g("private_title", "Your Own Era"), _g("private_body", "The classic BitKaisen life - live, rise, fall, and raise a dynasty at your own pace."), "Private", _g("private_cta", "BEGIN YOUR OWN ERA"), function()
	choose("Private")
end)

-- Multiplayer Fase 4: Público no longer commits to ChooseWorldMode
-- immediately -- it opens the Buscador de Mundos (Entrada Rápida there is
-- the direct equivalent of the old one-tap behavior). This panel just
-- steps aside; WorldBrowserPanel handles everything from here. Passing
-- `open` as a callback (not requiring WorldModePanel from WorldBrowserPanel)
-- avoids a circular require between the two modules.
makeCard(2, "共有世界", "開放中", THEME.Gold, _g("public_tag", "PUBLIC"), _g("public_title", "The Shared World"), _g("public_body", "One shared world, real sorcerers, one calendar. Forge your legend among true rivals."), "Public", _g("public_cta", "ENTER THE SHARED WORLD"), function()
	close()
	WorldBrowserPanel.open(open)
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
