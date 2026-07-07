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
if existing then existing:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 637
screenGui.Enabled = false
screenGui.Parent = playerGui

local isOpen = false

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

panel.InputBegan:Connect(function() end)

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 16)
padding.PaddingBottom = UDim.new(0, 16)
padding.PaddingLeft = UDim.new(0, 16)
padding.PaddingRight = UDim.new(0, 16)
padding.Parent = panel

local title = makeText(panel, "Title", "UPDATE 21", 22, true)
title.Size = UDim2.new(1, -48, 0, 34)
title.Position = UDim2.new(0, 0, 0, 0)
title.TextColor3 = Color3.fromRGB(255, 220, 139)

local subtitle = makeText(panel, "Subtitle", "New Player Guide system and a big round of bug fixes", 14, false)
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

addSection("Update 21 - New Player Guide System", "• A full <b>interactive tutorial</b> for new sorcerers, on PC and Mobile: walks you through every screen and mechanic step by step.\n• A <b>persistent Guide</b> that always points you to your next best move: activities, rivals, missions, relationships, domain, or aging up.\n• New <b>Help & Guide</b> panel: replay the tutorial or turn the Guide on/off anytime from one place.\n• Redesigned main UI on PC to match Mobile's dossier style: classified file header, stat bars, and system log.\n", Color3.fromRGB(255, 220, 139))

addSection("Update 21 - Bug Fixes", "• Starting a relationship no longer instantly ages your partner by 10 years.\n• Finger Hunt no longer breaks permanently after dying to it once.\n• Removed stray 'ui.' text showing up on some buttons.\n• Fixed gaining Technique Mastery with no technique to speak of.\n• Children can no longer be trained endlessly without aging up, and their Cursed Energy no longer carries over unbalanced when you take over their life.\n• Brain Transplant no longer incorrectly changes the age of other people in your life.\n• Fixed the curse overlapping a finger during Finger Hunt, making them impossible to tell apart.\n• Notable Sorcerers can now become friends with a great relationship, like everyone else.\n• Removed a duplicate Physical Conditioning training option.\n• Notable Sorcerers' traits and info now display correctly.\n", Color3.fromRGB(115, 220, 150))

addSection("Update 20 - Bug Fixes", "• Not all traits were showing up on the mobile UI, fixed and now display correctly.\n• Traits with long text on PC were getting cut off, now show in full.\n• Vows now appear on PC and Xbox, not just mobile, added scroll support.\n• Cemetery now correctly registers your past life technique.\n• Black Flash timing window now appears on mobile when triggered in combat.\n• Text in combat logs no longer cuts off mid sentence.\n• Notable Sorcerer romance now correctly loads personality and gender.\n• Relations panel now shows all traits correctly.\n", Color3.fromRGB(115, 220, 150))

addSection("Update 20 - Multi-Language System", "• Added Phase 1 support for Spanish and Portuguese in-game.\n", Color3.fromRGB(120, 190, 255))

addSection("Update 20 - Black Market", "• Buy and sell cursed tools and illegal items through the underground market.\n", Color3.fromRGB(255, 220, 139))

addSection("Update 20 - Cursed Organization and Cult", "• Create your own organization of curse users and build your influence.\n• Declare war between cults and fight for dominance.\n", Color3.fromRGB(179, 136, 255))

addSection("Update 20 - New Codes", "Redeem in Settings > Codes:\n\n• OPCODE: +$15,000, +80 CE, +10 Mastery, +5 Rep\n• BLACKMARKET: +$25,000, +5 Strength, +5 Smarts\n• HIDDENVEIL: +60 CE, +8 Mastery, +10 Fear\n", Color3.fromRGB(120, 190, 255))

addSection("Update 20 - Beach Hero Gamepass Grants", "• Remaining Beach Hero players now automatically receive their earned gamepass on login.\n", Color3.fromRGB(115, 220, 150))

addSection("Summer Update Pt.3 - Bug Fixes", "• Black Flash popup no longer blocks the dodge button during combat.\n• Relations (siblings and others) now age correctly alongside the player.\n• Settings menu no longer accidentally triggers buttons behind it.\n• Weeklies now save correctly across servers.\n• 'Steady Work' weekly no longer appears as incomplete after rejoining.\n• Achievement unlock and claim states are now in sync.\n• Xbox cursor now shows the native cursor correctly, dodge restored.\n", Color3.fromRGB(115, 220, 150))

addSection("Summer Update Pt.3 - Black Flash Improvements", "• Failing a Black Flash now penalizes you: expect CE drain and the enemy gaining an opening on your next defense.\n", Color3.fromRGB(255, 90, 125))

addSection("Summer Update Pt.3 - CT Preserved When Possessed by Sukuna", "• Manga canon: consuming all 20 fingers no longer replaces your Cursed Technique with Shrine. Your technique stays yours.\n", Color3.fromRGB(179, 136, 255))

addSection("Summer Update Pt.3 - Gender of Notable Sorcerers", "• Notable Sorcerer cards now display gender alongside age and grade.\n", Color3.fromRGB(255, 220, 139))

addSection("Summer Update Pt.3 - Cause of Death", "• The death screen now shows the specific reason you died.\n", Color3.fromRGB(255, 220, 139))

addSection("Summer Update Pt.3 - Mobile UI Redesign", "• The main mobile interface has been completely redesigned with a classified file aesthetic.\n", Color3.fromRGB(255, 220, 139))

addSection("Summer Update Pt.3 - Background Music", "• BitKaisen now has background music.\n", Color3.fromRGB(120, 190, 255))

addSection("Summer Update Pt.2 - Bug Fixes", "• Life log text on mobile no longer gets cut off.\n• Brain transplant no longer causes time to roll back.\n• Weekly mission now correctly marks as completed after reconnecting.\n• Fixed visual glitch in reward thumbnails.\n• Mobile UI locked to portrait only with spacing and visibility fixes.\n• World History tabs no longer mix content when tapped simultaneously.\n• Technique Mastery is now accessible from the mobile navigation panel.\n", Color3.fromRGB(115, 220, 150))

addSection("Summer Update Pt.2 - Black Flash in Combat", "• New skill check during combat: land a Black Flash with the right timing and your own Mastery level.\n", Color3.fromRGB(255, 90, 125))

addSection("Summer Update Pt.2 - Wanted and Bounty System", "• Reach high threat levels and bounty hunters will start tracking you down based on your danger level.\n", Color3.fromRGB(255, 90, 125))

addSection("Summer Update Pt.2 - Hereditary Properties", "• Dojo, clan house, and cursed tools can now be passed down as assets through your lineage.\n", Color3.fromRGB(255, 220, 139))

addSection("Summer Update Pt.2 - Romance with Notable Sorcerers", "• Select NPCs with lore are now romanceable, each with their own personality and story.\n", Color3.fromRGB(179, 136, 255))

addSection("Summer Update Pt.2 - Domain Effects by CT", "• Your Cursed Technique now determines unique effects inside your Domain Expansion.\n", Color3.fromRGB(255, 220, 139))

addSection("Summer Update Pt.2 - Siblings at Birth", "• 40% chance to be born with 1 or 2 siblings, each with their own name, age, personality, and background.\n", Color3.fromRGB(179, 136, 255))

addSection("Summer Update Pt.2 - CE Addiction System", "• CE Boosts now build a hidden addiction. At high levels expect withdrawal: losing Health and Happiness each year. It fades if you stop.\n", Color3.fromRGB(255, 90, 125))

addSection("Summer Update Pt.2 - Beach Hero Gamepass Grants", "• Players selected during the Beach Hero event now receive their earned gamepass automatically on login: God Mode, VIP Sorcerer, Training Prodigy, or Go Rogue.\n", Color3.fromRGB(115, 220, 150))

addSection("Summer Update Pt.2 - New Codes", "Redeem in Settings > Codes:\n\n• SUMMERPT2: +$20,000, +100 CE, +10 Mastery, +10 Rep\n• VEILOFCURSES: +$10,000, +60 CE, +8 Strength, Full Health\n", Color3.fromRGB(120, 190, 255))

addSection("Summer Update - Bug Fixes", "• Auto-enroll into JJH at 16 no longer cuts the Curse User route.\n• Log and actions not scrollable after age up, fixed on mobile and desktop.\n• White cursor on Xbox making combat unplayable, fixed.\n• Jujutsu High existing in the Heian Era (year 810), fixed.\n", Color3.fromRGB(115, 220, 150))

addSection("Summer Update - Cemetery of Lives", "• New Cemetery panel: see every past life, cause of death, and legacy summary.\n", Color3.fromRGB(255, 220, 139))

addSection("Summer Update - Death Ribbons and Life Titles", "• Earn a title when you die based on how you lived.\n• Examples: Heroic Sorcerer, Curse User, Wanderer, Fallen, and more.\n", Color3.fromRGB(179, 136, 255))

addSection("Summer Update - Special Talents at Birth", "• Rare birth talents that go beyond your Cursed Technique.\n• Affects training speed, stat growth, social ability, and more.\n", Color3.fromRGB(255, 220, 139))

addSection("Summer Update - Hidden Karma System", "• Every life builds a hidden Karma score that silently shapes your world.\n• You won't see the number, but your choices matter.\n", Color3.fromRGB(179, 136, 255))

addSection("Summer Update - Fame and Fear Expanded", "• New ways to raise Fame and Fear.\n• Rivals, NPCs, and affiliations now react to your reputation.\n", Color3.fromRGB(255, 220, 139))

addSection("Summer Update - Weekly Challenges", "• New WEEKLY nav tab, 6 challenges rotating every Monday.\n• Complete the condition, get the reward, track it in the panel.\n", Color3.fromRGB(120, 190, 255))

addSection("Summer Update - Time Skip Products", "+5, +10, +25 Years now available as developer products in the Shop.\n\n• +5 Years: R$ 75\n• +10 Years: R$ 149\n• +25 Years: R$ 299\n", Color3.fromRGB(120, 190, 255))

addSection("Summer Update - New Hair Colors", "• Green, Blue, and Orange now available at character creation.\n", Color3.fromRGB(255, 220, 139))

addSection("Summer Update - New Codes", "Redeem in Settings > Codes:\n\n• SUMMERUPDATE: +$25k, +120 CE, +12 Mastery, +12 Rep, +12 Happiness\n• CURSESEASON: +$15k, +80 CE, +10 Strength, +10 Rep\n• DOMAINOPENED: +200 CE, +15 Mastery, Full Health, Full Happiness\n• SHADOWTHREAD: +$60k, +200 CE, +15 Mastery, +15 Rep\n", Color3.fromRGB(120, 190, 255))

addSection("Update 19 - Sound Effects", "• Navigation buttons now have sound on press.\n• Sound when aging up (+AGE).\n• Death sound, notifications, positive and negative events.\n• All sounds respect your audio settings in Settings.\n", Color3.fromRGB(120, 190, 255))

addSection("Update 19 - Bug Fixes", "• Fixed bug where recruiting candidates at the Dojo wasn't working.\n• Fixed bug where Brain Transplant changed the character's year incorrectly.\n• Fixed invisible scroll bar on the profile panel.\n", Color3.fromRGB(115, 220, 150))

addSection("Update 19 - UI", "• Black background behind the UI on PC and mobile.\n• Navigation buttons redesigned with unique colors per category.\n• Mentor panel updated to match the standard visual style.\n• Main interface looks more balanced and polished on PC.\n", Color3.fromRGB(255, 220, 139))

addSection("Hotfix - Gift System", "• Gifts now work cross-server: enter any Roblox username to send a gift.\n• Recipient no longer needs to be in your server.\n• If the recipient is offline, the gift is saved and delivered on their next login.\n• Server validates the username before opening the Robux prompt.\n• Improved retry handling for edge cases during purchase.\n", Color3.fromRGB(115, 220, 150))

addSection("Shop Overhaul", "• All shop prices now match the Creator Dashboard — no more mismatches.\n• Every gamepass and developer product has an accurate description.\n• Go Rogue gamepass now listed in the shop.\n• God Mode updated to R$ 800 with expanded features.\n• 2x Progress updated to R$ 400 — doubled CE, Strength, and Mastery gains.\n• 5 new developer products priced: CT Evolution Accelerator, Black Flash Drill Pack, Clan War Mediation, Cursed Tool Salvage Kit, Combat Recovery Kit.\n", Color3.fromRGB(255, 220, 139))

addSection("New Gamepasses", "• Lucky Sorcerer (R$ 349) — +15% birth stats every new life.\n• Training Prodigy (R$ 349) — 1.5x CE, Strength, and Mastery training.\n• Mission Investor (R$ 299) — 1.5x cash from missions (stacks with 2x Money).\n• Legacy Blessing (R$ 349) — Heirs start stronger each generation (+CE, +Strength, +Smarts, +Health, +Rep scaling with bloodline depth).\n• Focused Training (R$ 199) — +25% CE from CE training (stacks with everything).\n• AFK Pass (R$ 200) — 2x AFK payouts (AFK is free for all now).\n• Binding Vow Specialist (R$ 349) — 5 vows instead of 3, -25% negative effects.\n• Dojo Expansion (coming soon) — +5 recruit candidates, +2 student capacity.\n", Color3.fromRGB(255, 220, 139))

addSection("VIP Sorcerer Pass Expansion", "• 2x daily login rewards.\n• 1.5x money from missions and jobs.\n• 1.5x training gains.\n• 2x Technique Mastery gains.\n• Exclusive 'VIP Sorcerer' title.\n• Extra save slots included.\n", Color3.fromRGB(255, 220, 139))

addSection("Binding Vow Specialist", "• Custom vow limit raised from 3 to 5.\n• All negative effects reduced by 25%.\n• New VOWS nav button for quick access.\n", Color3.fromRGB(179, 136, 255))

addSection("Lucky Birth Enhancement", "• Guaranteed Rare+ trait at birth.\n• 25% luck boost to clan/origin rolls.\n• Extra cursed technique roll if first fails.\n", Color3.fromRGB(255, 220, 139))

addSection("AFK Free for All", "• AFK Stabilization is now FREE for everyone.\n• AFK Pass doubles your idle payouts (2x).\n", Color3.fromRGB(115, 220, 150))

addSection("New Codes", "Redeem in Settings > Codes:\n\n• Update18 — +$25k, +150 CE, +15 Mastery, +15 Rep, +15 Happiness\n• ShopOverhaul — +$30k, +100 CE, +10 Rep\n• VipSorcerer — +200 CE, +20 Mastery, Max Health, Max Happiness\n• BindingVow — +$15k, +100 CE, +15 Strength, +10 Rep\n• SixEyes — +$75k, +300 CE, +20 Mastery, +20 Rep\n", Color3.fromRGB(120, 190, 255))

addSection("Update 17 - Bug Fixes", "• Physical Conditioning now correctly resets each age-up (was capped at 3 per lifetime).\n• Fixed exploit where relationship action counter could be bypassed with rapid requests.\n• Unregistered sorcerers can now promote past Grade 4.\n• Send Students on Patrol no longer crashes and consumes your turn.\n• World events, notable sorcerer aging, and era changes now continue past age 16.\n• Newborns no longer default as the strongest sorcerer alive.\n• Gender no longer randomly swaps on surviving spouses during generation takeover.\n• Cursed spirits can now take over prior-life children after death.\n• Rival entries in Affiliations no longer show broken action buttons.\n• God Mode clan picker now shows all clans including Ryomen.\n• Randomize Path button no longer crashes.\n• WAR button now hides when overlay menus are open.\n")

addSection("Update 17 - School System", "• Characters now attend Elementary School (ages 6-10), Middle School (ages 11-13), and High School (ages 14-15).\n• Academic Performance and Attendance drift each year based on your Smarts stat.\n• Earn a Report Card Grade (A+ through F) from performance and attendance.\n• At age 16 you graduate with a full report card popup — honor students earn Smarts and Reputation bonuses.\n• New school activities: Attend Class, Study for Exams, Join a Club (8 clubs), Skip School.\n")

addSection("Update 17 - Jujutsu Mentor Career", "• Jujutsu High students now graduate at age 20 — become a fully Registered Sorcerer with a graduation popup.\n• Awakened sorcerers who graduate civilian school at 16 are offered a transfer to Jujutsu High.\n• After graduating JJH, apply to become a Jujutsu Mentor (age 20+, Grade 2+, recommendations).\n• 4-rank career ladder: Assistant Instructor, Instructor, Senior Instructor, Master Instructor.\n• Earn yearly salary, Mentor XP, reputation, and students assigned to your care.\n• New mentor activities: Teach a Class, Supervise Student Mission, Grade Students, Mentor a Prodigy.\n• New MENTOR panel in the navigation bar to view rank, income, XP progress, and apply.\n")

addSection("Update 17 - Activity Sidebar", "• The Activities menu now has a category sidebar on the left side.\n• Activities grouped into: Life, School, Training, Jujutsu High, Mentor, Missions, Dojo/Clan, Social, Minigames, Curse Spirit, Curse User, Era, Premium.\n• Click any category to instantly scroll to that section.\n• Section headers visually separate each category with color-coded labels.\n")

addSection("Update 17 - Full UI Overhaul", "• Entire client UI rebuilt on Vide (reactive UI architecture).\n• Replaces old monolithic UI script that was hitting engine limits and breaking features.\n• Every major screen restored to full parity — not stripped-down stubs.\n• Fixed panels that would not open, buttons that did not respond, and reactive-scope crashes.\n• 58 Vide modules under game/shared/ui/ (components, panels, hooks, theme).\n• Single bootstrap mounts the full UI, centralized remotes, shared state system.\n• All 30+ panels migrated: Missions, Activities, Relationships, Assets, Jobs, Settings, Combat, Minigames, Domain, Rivals, History, Mentor, Affiliations, Binding Vows, Daily Login, Free Rewards, Update Log, Clan War, God Mode, AFK, Death, Character Customization, Technique Mastery, Trait Details, and more.\n")

addSection("Update 17 - Mobile UI", "• Full mobile UI with portrait-locked layout and touch-optimized controls.\n• Mobile shell: profile header, life log, age-up button, and nav panel all in portrait layout.\n• Every panel has a dedicated Mobile version with swipe-friendly sheets and tap routing.\n• Tap router handles touch input through ScrollingFrames reliably.\n• Mobile-safe area respected — all panels sit below the Roblox topbar.\n• TopbarPlus icons on mobile: Settings, God Mode, War, AFK, Free Rewards.\n• Affiliations actions use an expandable grid instead of overflowing buttons.\n• Combat panel layers above other panels so fights are never obscured.\n• Stat notifications positioned at the top, below TopbarPlus.\n• Trait info button next to traits text on mobile profile.\n")

addSection("Update 17 - PC UI", "• TopbarPlus icons restored on PC: Settings, God Mode, War, AFK, Free Rewards.\n• Legacy WAR nav button hidden — War is now TopbarPlus only.\n• AFK panel now has a working close button.\n• Nav button list scrollable — all nav entries reachable.\n• Responsive layout adapts to portrait, landscape, and desktop viewports.\n• Trait info button next to traits on PC profile.\n• Profile card, life log, and shell components fully functional.\n")

addSection("Update 17 - Quality of Life", "• Loading screen shows for a minimum of 5 seconds to ensure everything loads.\n• Loading screen logo and progress bar positioned closer together.\n• Startup log messages silent on live servers — only visible in Studio.\n• Default Roblox respawn button removed.\n• Update Log accessible from Settings panel LOG tab.\n")

addSection("Update 16 - QOL & Progression", "• Console support improvements added.\n• RCT requirements increased and RCT now gives passive health regeneration.\n• Missions and special missions are capped per age-up.\n• Early progression and visible stat gains are slower for a healthier long-term pace.\n• Curse encounters are more frequent based on Curse Exposure.\n")

addSection("Update 16 - Combat & Strength", "• New Strength stat added.\n• Physical Conditioning activity added.\n• Strength improves basic attack damage, crit chance, and attack timing control.\n• Punching Bag and In-Home Gym added to Assets.\n• Finger hunting can now trigger curse obstacle combat if you get caught.\n")

addSection("Update 16 - Family, Legacy & God Mode", "• Rivals now appear in Relationships.\n• Children and wards can be recruited into your Grand Dojo.\n• Reincarnation backend added for cursed-object anchor lives.\n• God Mode can directly pick clans and choose exact birth year.\n• Update 16 codes added: Update16, ConsoleSupport, NewGUI, Secret.\n")

addSection("Update 15 - Enemies of Your Era", "• New Rivals tab added to the main navigation.\n• Your fame, fear, wanted level, hunter pressure, clan history, and cursed identity now shape your reputation path.\n• Reputation paths include Public Hero, Honored Sorcerer, Clan Champion, Rogue Curse User, Infamous Criminal, Feared Curse, and Hidden Monster.\n• Rivals can appear as your name spreads through the world.\n")

addSection("Update 15 - Rival Encounters", "• Rivals now track name, age, grade, clan, technique intel, threat, status, and win/loss history.\n• Rival encounters can appear during yearly age-up pressure.\n• Respond by fighting, talking them down, escaping, gathering intel, sparing them, or humiliating them.\n• Rival fights use the existing combat system and update rival records after the fight.\n")

addSection("Update 15 - Reputation Rewards", "• Fame, Fear, Wanted level, Hunter Pressure, and Public Support now matter more.\n• Rival outcomes are recorded into your legacy/world history.\n• New titles added: Rival Maker, Untouchable, Public Hero, Walking Disaster, Marked Sorcerer, and Enemy of Jujutsu Society.\n• Test-rival generation is restricted to dev/testing access only.\n")

addSection("Update 14 - Domain Expansion", "• New Domain tab added to the main navigation.\n• Players can train Domain progress, stabilize barriers, and unlock Domain stages.\n• Domains progress from Seed to Incomplete Domain to full Domain Expansion.\n• Domain names now reflect your technique, including Unlimited Void, Malevolent Shrine, Chimera Shadow Garden, and more.\n• Combat pressure, victories, defeats, and Domain use can raise Domain progress.\n")

addSection("Update 14 - Domain Combat", "• Domain button added to combat when your Domain is manifested and you have enough CE.\n• Domain Expansion can deal heavy damage once per fight.\n• Strong enemies can trigger Domain clashes.\n• Winning a clash improves momentum and damage; losing a clash causes backlash.\n• Domain progression is gameplay-first, with monetization focused on support and convenience instead of instant unlocks.\n")

addSection("Update 13 - Combat Expansion", "• Combat now feels faster with attack timing, dodges, counters, fleeing, and fight results.\n• Critical hits, damage popups, hit/miss feedback, and combat sounds make fights easier to read.\n• Losing a fight can offer a Reset Fight purchase in live servers.\n• New optional Update 13 products added: Combat Recovery Kit, Clan War Mediation, and Cursed Tool Salvage Kit.\n")

addSection("Update 13 - Cursed Tools and Inventory", "• Cursed Tools can now be collected, equipped, and viewed from Assets.\n• Combat victories and successful missions can rarely drop cursed tools.\n• Stronger enemies and harder missions can reward better cursed tools.\n• Equipped cursed tools can improve combat power, defense, mission survival, or CE gains.\n• Duplicate cursed tools now convert into money and CE.\n• The Cursed Tool Catalog shows owned and locked tools, rarity, effects, and drop weight.\n• New Epic cursed tool added: Binding Chain Wrap.\n• Cursed Tool cards now fit better on smaller screens.\n• New collection titles added: Cursed Tool Bearer, Relic Collector, and Complete Arsenal.\n• World History now tracks cursed tool collection count.\n")

addSection("Update 13 - Clan War System", "• Established clans can now be pulled into Clan Wars against rival clans.\n• Clan Wars track tension, battles, wins, losses, history, and yearly escalation.\n• Use Defend, Strike, Negotiate, or Betray to shape the war.\n• Defend, Strike, and Betray can trigger real combat against rival clan fighters.\n• Yearly war events now include raids, truce talks, rumors, training pressure, and public fear.\n• Clan War actions show recovery time when your clan needs to regroup.\n• Affiliations now shows active and recent Clan War rivals.\n• World History now records Clan War outcomes.\n• New Clan War titles added: War-Proven, Clan Conqueror, and Unbroken Banner.\n")

addSection("Update 12 - Combat Gameplay", "• Interactive combat encounters added.\n• Attack timing minigame added with sweet spot critical hits.\n• Technique attacks added with CE cost and limited uses.\n• Dodge and counter attack QTEs added.\n• Combat result popups, damage text, hit/miss feedback, and fight sounds added.\n")

addSection("Update 12 - AFK Stabilization", "• AFK Stabilization added as a monetized idle earning feature.\n• AFK button moved to the top bar beside Shop.\n• AFK sessions now stop when the player gives input.\n• AFK earnings now pay out correctly when AFK stops or the player disconnects.\n• AFK money display now rounds cleanly to cents.\n")

addSection("Update 12 - Premium and Live Prompts", "• Reset Fight developer product added for combat recovery.\n• AFK Stabilization purchase flow added.\n• Live place purchases now use Roblox purchase prompts.\n• Testing place bypass remains limited to the testing place.\n")

addSection("Update 12 - Polish and Fixes", "• Combat pacing improved for faster rounds.\n• Flee, dodge, counter, and attack feedback improved.\n• Money values no longer show long decimal tails.\n")

addSection("Update 10 - Premium Testing", "- Added test-place Robux bypass for the current testing place\n- Developer products can be tested without purchasing in the test place\n- Gamepasses are treated as owned in the test place for verification\n- Production places still require normal Roblox Marketplace purchases\n")

addSection("Update 10 - Go Rogue Route", "- Go Rogue in Jobs is now a Developer Product route purchase\n- Go Rogue grants only after a valid product receipt or test-place grant\n- Old free remote calls no longer grant Rogue Sorcerer status\n- Jobs now show SET ID until the Go Rogue product ID is configured\n")

addSection("Update 10 - Burglary Fixes", "- Burglary loot can no longer spawn under guards\n- Burglary loot can no longer spawn on start, exit, or invalid cells\n- Burglary boards now verify that loot and exit are reachable\n- Added a LEAVE button so players can abandon burglary without being captured\n- Dojo Raid burglary-style boards now use the same safe board generation\n")

addSection("Update 10 - Activity and Relationship Fixes", "- Relationship actions no longer consume normal activity slots\n- Using relationship actions first no longer blocks activities until aging up\n- Cursed Womb and curse activities no longer get wrongly blocked by human-life checks\n- Curse activity access now uses a safer cursed-life eligibility check\n")

addSection("Update 10 - Stability", "- Added server validation for test purchases by place ID\n- Added product ID payload support for paid Jobs actions\n- Confirmed key updated scripts load cleanly in Play mode\n- Continued UI and gameplay bug cleanup from tester reports\n")

addSection("Update 10 - Combat Foundation", "- Added interactive combat sessions with player and enemy HP/CE\n- Added attack timing minigame with target zone and sweet spot\n- Added defend QTE for 1 to 3 hit enemy combos\n- Added perfect-dodge counter attack window\n- Added test-place combat starter for verification\n- Added Reset Fight developer product hook with test-place bypass\n")

local footer = makeText(panel, "Footer", "Update 21 is live. Rejoin once if anything looks off after the update.", 12, false)
footer.AnchorPoint = Vector2.new(0, 1)
footer.Position = UDim2.new(0, 0, 1, 0)
footer.Size = UDim2.new(1, 0, 0, 34)
footer.TextColor3 = Color3.fromRGB(190, 177, 153)

local function resizeForScreen()
	local viewport = getViewport()
	local scaleX = (viewport.X - MOBILE_WINDOW_MARGIN_X) / BASE_PANEL_WIDTH
	local scaleY = (viewport.Y - MOBILE_WINDOW_MARGIN_Y) / BASE_PANEL_HEIGHT
	panelScale.Scale = math.clamp(math.min(scaleX, scaleY, 1), 0.38, 1)
	panel.Size = UDim2.fromOffset(BASE_PANEL_WIDTH, BASE_PANEL_HEIGHT)

	if isSmallScreen() then
		title.TextSize = 18
		subtitle.TextSize = 12
		scroll.ScrollBarThickness = 4
	else
		title.TextSize = 22
		subtitle.TextSize = 14
		scroll.ScrollBarThickness = 6
	end
end

local function openLog()
	if isOpen then return end
	isOpen = true
	resizeForScreen()
	screenGui.Enabled = true
	overlay.Visible = true
	panel.Visible = true
	overlay.BackgroundTransparency = 1
	panel.Position = UDim2.fromScale(0.5, 0.53)
	panel.BackgroundTransparency = 0.08

	TweenService:Create(overlay, TweenInfo.new(0.12), { BackgroundTransparency = 0.35 }):Play()
	TweenService:Create(panel, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 0,
	}):Play()
end

local function closeLog()
	isOpen = false
	TweenService:Create(overlay, TweenInfo.new(0.1), { BackgroundTransparency = 1 }):Play()
	local tw = TweenService:Create(panel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.fromScale(0.5, 0.53),
		BackgroundTransparency = 0.08,
	})
	tw:Play()
	tw.Completed:Once(function()
		overlay.Visible = false
		panel.Visible = false
		screenGui.Enabled = false
	end)
end

closeButton.MouseButton1Click:Connect(closeLog)

overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		closeLog()
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Escape and isOpen then
		closeLog()
	end
end)

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeForScreen)
end

resizeForScreen()

local function init()
	-- Update log auto-opens or is opened externally; expose open for callers.
end

return { init = init, open = openLog, close = closeLog }
