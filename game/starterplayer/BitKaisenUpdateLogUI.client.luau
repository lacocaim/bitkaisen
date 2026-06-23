-- Script: BitKaisenUpdateLogUI
-- Location: StarterPlayerScripts
-- Purpose:
--   Lightweight in-game Update Log button/popup for BitKaisen Update 13.
--   Standalone and release-safe: does not modify GameManager, remotes, menus, or save data.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUI_NAME = "BitKaisenUpdateLogGui"
local BASE_PANEL_WIDTH = 560
local BASE_PANEL_HEIGHT = 500
local MOBILE_WINDOW_MARGIN_X = 28
local MOBILE_WINDOW_MARGIN_Y = 70

local existing = playerGui:FindFirstChild(GUI_NAME)
if existing then
	existing:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 950
screenGui.Parent = playerGui

local function makeCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = parent
	return corner
end

local function makeStroke(parent, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0.35
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Parent = parent
	return stroke
end

local function makeText(parent, name, text, size, bold)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = text or ""
	label.TextColor3 = Color3.fromRGB(245, 239, 225)
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	label.TextSize = size or 14
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.RichText = true
	label.Parent = parent
	return label
end

local function getViewport()
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local function isSmallScreen()
	local viewport = getViewport()
	return viewport.X < 780 or viewport.Y < 520 or UserInputService.TouchEnabled
end

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.Size = UDim2.fromScale(1, 1)
overlay.Visible = false
overlay.Parent = screenGui

overlay.Active = true

overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		overlay.Visible = false
	end
end)

local panel = Instance.new("Frame")
panel.Name = "UpdateLogPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(18, 15, 13)
panel.BorderSizePixel = 0
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(BASE_PANEL_WIDTH, BASE_PANEL_HEIGHT)
panel.Visible = false
panel.Parent = overlay
panel.Active = true
makeCorner(panel, 18)
makeStroke(panel, 1, 0.45)

local panelScale = Instance.new("UIScale")
panelScale.Name = "ResponsiveScale"
panelScale.Scale = 1
panelScale.Parent = panel

panel.InputBegan:Connect(function()
	-- absorb clicks so the overlay itself does not close when clicking inside the panel
end)

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 16)
padding.PaddingBottom = UDim.new(0, 16)
padding.PaddingLeft = UDim.new(0, 16)
padding.PaddingRight = UDim.new(0, 16)
padding.Parent = panel

local title = makeText(panel, "Title", "UPDATE 16", 22, true)
title.Size = UDim2.new(1, -48, 0, 34)
title.Position = UDim2.new(0, 0, 0, 0)
title.TextColor3 = Color3.fromRGB(255, 220, 139)

local subtitle = makeText(panel, "Subtitle", "Enemies of your era, rival encounters, reputation paths, and legacy pressure", 14, false)
subtitle.Size = UDim2.new(1, -48, 0, 22)
subtitle.Position = UDim2.new(0, 0, 0, 34)
subtitle.TextColor3 = Color3.fromRGB(198, 186, 164)

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(55, 42, 38)
closeButton.BorderSizePixel = 0
closeButton.Position = UDim2.new(1, 0, 0, 0)
closeButton.Size = UDim2.new(0, 38, 0, 34)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 238, 218)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.Parent = panel
makeCorner(closeButton, 10)

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "LogScroll"
scroll.BackgroundColor3 = Color3.fromRGB(25, 21, 18)
scroll.BackgroundTransparency = 0.05
scroll.BorderSizePixel = 0
scroll.Position = UDim2.new(0, 0, 0, 68)
scroll.Size = UDim2.new(1, 0, 1, -118)
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel
makeCorner(scroll, 14)
makeStroke(scroll, 1, 0.7)

local list = Instance.new("UIListLayout")
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, 10)
list.Parent = scroll

local scrollPad = Instance.new("UIPadding")
scrollPad.PaddingTop = UDim.new(0, 12)
scrollPad.PaddingBottom = UDim.new(0, 12)
scrollPad.PaddingLeft = UDim.new(0, 12)
scrollPad.PaddingRight = UDim.new(0, 12)
scrollPad.Parent = scroll

local function addSection(headerText, bodyText, headerColor)
	local box = Instance.new("Frame")
	box.Name = headerText:gsub("%s+", "")
	box.BackgroundColor3 = Color3.fromRGB(36, 29, 25)
	box.BackgroundTransparency = 0.08
	box.BorderSizePixel = 0
	box.Size = UDim2.new(1, -6, 0, 10)
	box.AutomaticSize = Enum.AutomaticSize.Y
	box.Parent = scroll
	makeCorner(box, 12)
	makeStroke(box, 1, 0.75)

	local boxPad = Instance.new("UIPadding")
	boxPad.PaddingTop = UDim.new(0, 10)
	boxPad.PaddingBottom = UDim.new(0, 10)
	boxPad.PaddingLeft = UDim.new(0, 10)
	boxPad.PaddingRight = UDim.new(0, 10)
	boxPad.Parent = box

	local boxList = Instance.new("UIListLayout")
	boxList.SortOrder = Enum.SortOrder.LayoutOrder
	boxList.Padding = UDim.new(0, 6)
	boxList.Parent = box

	local header = makeText(box, "Header", headerText, 16, true)
	header.Size = UDim2.new(1, 0, 0, 22)
	header.TextColor3 = headerColor or Color3.fromRGB(255, 220, 139)

	local body = makeText(box, "Body", bodyText, 13, false)
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.TextColor3 = Color3.fromRGB(232, 223, 205)
end

addSection("Update 16 - QOL & Progression", [[
• Console support improvements added.
• RCT requirements increased and RCT now gives passive health regeneration.
• Missions and special missions are capped per age-up.
• Early progression and visible stat gains are slower for a healthier long-term pace.
• Curse encounters are more frequent based on Curse Exposure.
]])

addSection("Update 16 - Combat & Strength", [[
• New Strength stat added.
• Physical Conditioning activity added.
• Strength improves basic attack damage, crit chance, and attack timing control.
• Punching Bag and In-Home Gym added to Assets.
• Finger hunting can now trigger curse obstacle combat if you get caught.
]])

addSection("Update 16 - Family, Legacy & God Mode", [[
• Rivals now appear in Relationships.
• Children and wards can be recruited into your Grand Dojo.
• Reincarnation backend added for cursed-object anchor lives.
• God Mode can directly pick clans and choose exact birth year.
• Update 16 codes added: Update16, ConsoleSupport, NewGUI, Secret.
]])

addSection("Update 15 - Enemies of Your Era", [[
• New Rivals tab added to the main navigation.
• Your fame, fear, wanted level, hunter pressure, clan history, and cursed identity now shape your reputation path.
• Reputation paths include Public Hero, Honored Sorcerer, Clan Champion, Rogue Curse User, Infamous Criminal, Feared Curse, and Hidden Monster.
• Rivals can appear as your name spreads through the world.
]])

addSection("Update 15 - Rival Encounters", [[
• Rivals now track name, age, grade, clan, technique intel, threat, status, and win/loss history.
• Rival encounters can appear during yearly age-up pressure.
• Respond by fighting, talking them down, escaping, gathering intel, sparing them, or humiliating them.
• Rival fights use the existing combat system and update rival records after the fight.
]])

addSection("Update 15 - Reputation Rewards", [[
• Fame, Fear, Wanted level, Hunter Pressure, and Public Support now matter more.
• Rival outcomes are recorded into your legacy/world history.
• New titles added: Rival Maker, Untouchable, Public Hero, Walking Disaster, Marked Sorcerer, and Enemy of Jujutsu Society.
• Test-rival generation is restricted to dev/testing access only.
]])

addSection("Update 14 - Domain Expansion", [[
• New Domain tab added to the main navigation.
• Players can train Domain progress, stabilize barriers, and unlock Domain stages.
• Domains progress from Seed to Incomplete Domain to full Domain Expansion.
• Domain names now reflect your technique, including Unlimited Void, Malevolent Shrine, Chimera Shadow Garden, and more.
• Combat pressure, victories, defeats, and Domain use can raise Domain progress.
]])

addSection("Update 14 - Domain Combat", [[
• Domain button added to combat when your Domain is manifested and you have enough CE.
• Domain Expansion can deal heavy damage once per fight.
• Strong enemies can trigger Domain clashes.
• Winning a clash improves momentum and damage; losing a clash causes backlash.
• Domain progression is gameplay-first, with monetization focused on support and convenience instead of instant unlocks.
]])

addSection("Update 13 - Combat Expansion", [[
• Combat now feels faster with attack timing, dodges, counters, fleeing, and fight results.
• Critical hits, damage popups, hit/miss feedback, and combat sounds make fights easier to read.
• Losing a fight can offer a Reset Fight purchase in live servers.
• New optional Update 13 products added: Combat Recovery Kit, Clan War Mediation, and Cursed Tool Salvage Kit.
]])

addSection("Update 13 - Cursed Tools and Inventory", [[
• Cursed Tools can now be collected, equipped, and viewed from Assets.
• Combat victories and successful missions can rarely drop cursed tools.
• Stronger enemies and harder missions can reward better cursed tools.
• Equipped cursed tools can improve combat power, defense, mission survival, or CE gains.
• Duplicate cursed tools now convert into money and CE.
• The Cursed Tool Catalog shows owned and locked tools, rarity, effects, and drop weight.
• New Epic cursed tool added: Binding Chain Wrap.
• Cursed Tool cards now fit better on smaller screens.
• New collection titles added: Cursed Tool Bearer, Relic Collector, and Complete Arsenal.
• World History now tracks cursed tool collection count.
]])

addSection("Update 13 - Clan War System", [[
• Established clans can now be pulled into Clan Wars against rival clans.
• Clan Wars track tension, battles, wins, losses, history, and yearly escalation.
• Use Defend, Strike, Negotiate, or Betray to shape the war.
• Defend, Strike, and Betray can trigger real combat against rival clan fighters.
• Yearly war events now include raids, truce talks, rumors, training pressure, and public fear.
• Clan War actions show recovery time when your clan needs to regroup.
• Affiliations now shows active and recent Clan War rivals.
• World History now records Clan War outcomes.
• New Clan War titles added: War-Proven, Clan Conqueror, and Unbroken Banner.
]])

addSection("Update 12 - Combat Gameplay", [[
• Interactive combat encounters added.
• Attack timing minigame added with sweet spot critical hits.
• Technique attacks added with CE cost and limited uses.
• Dodge and counter attack QTEs added.
• Combat result popups, damage text, hit/miss feedback, and fight sounds added.
]])

addSection("Update 12 - AFK Stabilization", [[
• AFK Stabilization added as a monetized idle earning feature.
• AFK button moved to the top bar beside Shop.
• AFK sessions now stop when the player gives input.
• AFK earnings now pay out correctly when AFK stops or the player disconnects.
• AFK money display now rounds cleanly to cents.
]])

addSection("Update 12 - Premium and Live Prompts", [[
• Reset Fight developer product added for combat recovery.
• AFK Stabilization purchase flow added.
• Live place purchases now use Roblox purchase prompts.
• Testing place bypass remains limited to the testing place.
]])

addSection("Update 12 - Polish and Fixes", [[
• Combat pacing improved for faster rounds.
• Flee, dodge, counter, and attack feedback improved.
• Money values no longer show long decimal tails.
]])

addSection("Update 10 - Premium Testing", [[
- Added test-place Robux bypass for the current testing place
- Developer products can be tested without purchasing in the test place
- Gamepasses are treated as owned in the test place for verification
- Production places still require normal Roblox Marketplace purchases
]])

addSection("Update 10 - Go Rogue Route", [[
- Go Rogue in Jobs is now a Developer Product route purchase
- Go Rogue grants only after a valid product receipt or test-place grant
- Old free remote calls no longer grant Rogue Sorcerer status
- Jobs now show SET ID until the Go Rogue product ID is configured
]])

addSection("Update 10 - Burglary Fixes", [[
- Burglary loot can no longer spawn under guards
- Burglary loot can no longer spawn on start, exit, or invalid cells
- Burglary boards now verify that loot and exit are reachable
- Added a LEAVE button so players can abandon burglary without being captured
- Dojo Raid burglary-style boards now use the same safe board generation
]])

addSection("Update 10 - Activity and Relationship Fixes", [[
- Relationship actions no longer consume normal activity slots
- Using relationship actions first no longer blocks activities until aging up
- Cursed Womb and curse activities no longer get wrongly blocked by human-life checks
- Curse activity access now uses a safer cursed-life eligibility check
]])

addSection("Update 10 - Stability", [[
- Added server validation for test purchases by place ID
- Added product ID payload support for paid Jobs actions
- Confirmed key updated scripts load cleanly in Play mode
- Continued UI and gameplay bug cleanup from tester reports
]])

addSection("Update 10 - Combat Foundation", [[
- Added interactive combat sessions with player and enemy HP/CE
- Added attack timing minigame with target zone and sweet spot
- Added defend QTE for 1 to 3 hit enemy combos
- Added perfect-dodge counter attack window
- Added test-place combat starter for verification
- Added Reset Fight developer product hook with test-place bypass
]])

local footer = makeText(panel, "Footer", "Update 16 is live. Rejoin once if anything looks weird after the update.", 12, false)
footer.AnchorPoint = Vector2.new(0, 1)
footer.Position = UDim2.new(0, 0, 1, 0)
footer.Size = UDim2.new(1, 0, 0, 34)
footer.TextColor3 = Color3.fromRGB(190, 177, 153)

local openButton = Instance.new("TextButton")
openButton.Name = "OpenUpdateLog"
openButton.AnchorPoint = Vector2.new(0.5, 0)
openButton.BackgroundColor3 = Color3.fromRGB(42, 31, 24)
openButton.BorderSizePixel = 0
openButton.Position = UDim2.new(0.5, 0, 0, 10)
openButton.Size = UDim2.new(0, 170, 0, 34)
openButton.Text = "UPDATE LOG"
openButton.TextColor3 = Color3.fromRGB(255, 232, 178)
openButton.Font = Enum.Font.GothamBold
openButton.TextSize = 14
openButton:SetAttribute("BKTopBarKey", "UpdateLog")
openButton.Parent = screenGui
makeCorner(openButton, 12)
makeStroke(openButton, 1, 0.45)

local newBadge = Instance.new("TextLabel")
newBadge.Name = "NewBadge"
newBadge.AnchorPoint = Vector2.new(1, 0)
newBadge.BackgroundColor3 = Color3.fromRGB(135, 45, 33)
newBadge.BorderSizePixel = 0
newBadge.Position = UDim2.new(1, 8, 0, -6)
newBadge.Size = UDim2.new(0, 42, 0, 18)
newBadge.Text = "NEW"
newBadge.TextColor3 = Color3.fromRGB(255, 244, 232)
newBadge.Font = Enum.Font.GothamBold
newBadge.TextSize = 10
newBadge.Parent = openButton
makeCorner(newBadge, 8)

local function resizeForScreen()
	local viewport = getViewport()
	local scaleX = (viewport.X - MOBILE_WINDOW_MARGIN_X) / BASE_PANEL_WIDTH
	local scaleY = (viewport.Y - MOBILE_WINDOW_MARGIN_Y) / BASE_PANEL_HEIGHT

	panel.Size = UDim2.fromOffset(BASE_PANEL_WIDTH, BASE_PANEL_HEIGHT)
	panelScale.Scale = math.clamp(math.min(scaleX, scaleY, 1), 0.38, 1)

	if isSmallScreen() then
		openButton.Size = UDim2.new(0, 140, 0, 30)
		openButton.Position = UDim2.new(0.5, 0, 0, 6)
		openButton.TextSize = 12

		title.TextSize = 18
		subtitle.TextSize = 12
		scroll.ScrollBarThickness = 4
	else
		openButton.Size = UDim2.new(0, 170, 0, 34)
		openButton.Position = UDim2.new(0.5, 0, 0, 10)
		openButton.TextSize = 14

		title.TextSize = 22
		subtitle.TextSize = 14
		scroll.ScrollBarThickness = 6
	end
end

local function openLog()
	resizeForScreen()
	overlay.Visible = true
	panel.Visible = true
	overlay.BackgroundTransparency = 1
	panel.Position = UDim2.fromScale(0.5, 0.53)
	panel.BackgroundTransparency = 0.08

	TweenService:Create(overlay, TweenInfo.new(0.12), { BackgroundTransparency = 0.35 }):Play()
	TweenService:Create(panel, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 0
	}):Play()
end

local function closeLog()
	TweenService:Create(overlay, TweenInfo.new(0.1), { BackgroundTransparency = 1 }):Play()
	local tween = TweenService:Create(panel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.fromScale(0.5, 0.53),
		BackgroundTransparency = 0.08
	})
	tween:Play()
	tween.Completed:Once(function()
		overlay.Visible = false
		panel.Visible = false
	end)
end

openButton.MouseButton1Click:Connect(openLog)
closeButton.MouseButton1Click:Connect(closeLog)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Escape and overlay.Visible then
		closeLog()
	end
end)

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeForScreen)
end

resizeForScreen()

print("[BitKaisenUpdateLogUI] Update 16 log loaded.")

