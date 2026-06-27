local Players = game:GetService("Players")

local uiState = require("@ui-state/uiState")
local mc = require("@ui/mobile/mobileComponents")

local theme = mc.theme
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui: ScreenGui
local sheet: Frame
local scroll: ScrollingFrame

local sections = {
	{
		header = "Update 18 - Shop Overhaul",
		body = "• All shop prices updated to match Roblox Creator Dashboard — no more mismatched prices.\n• Accurate descriptions for every gamepass and developer product.\n• 5 previously TBD developer products now have real prices: CT Evolution Accelerator (R$ 299), Black Flash Drill Pack (R$ 299), Clan War Mediation (R$ 99), Cursed Tool Salvage Kit (R$ 99), Combat Recovery Kit (R$ 99).\n• Go Rogue gamepass now listed in the shop.\n• God Mode increased to R$ 800 with expanded feature set.\n• 2x Progress (Training) increased to R$ 400 with doubled training gains across CE, Strength, and Mastery.",
		color = theme.Gold,
	},
	{
		header = "Update 18 - New Gamepasses",
		body = "• Lucky Sorcerer (R$ 349) — 15% boost to Smarts, Health, Happiness, Looks, and Strength at birth on every new life.\n• Training Prodigy (R$ 349) — 1.5x gains on Cursed Energy, Strength, and Technique Mastery during all training.\n• Mission Investor (R$ 299) — 1.5x cash, reputation, and CE gains from all mission completions.\n• Legacy Blessing (R$ 349) — Future heirs start stronger through your family line.\n• Focused Training (R$ 199) — Permanent +25% Cursed Energy gains from CE training.\n• AFK Pass (R$ 200) — 2x AFK payouts. AFK is free for everyone; this pass doubles your idle earnings.\n• Binding Vow Specialist (R$ 349) — Hold up to 5 custom vows per life instead of 3. Negative vow effects reduced by 25%.",
		color = theme.Gold,
	},
	{
		header = "Update 18 - VIP Sorcerer Pass Expansion",
		body = "• VIP Pass now grants 2x daily login rewards.\n• VIP Pass now grants 1.5x money from missions and jobs.\n• VIP Pass now grants 1.5x training gains (CE and Strength).\n• VIP Pass now grants 2x Technique Mastery gains.\n• VIP Pass owners receive the exclusive 'VIP Sorcerer' title.\n• VIP Pass still includes extra save slots.\n• VIP price updated to R$ 400 to reflect expanded value.",
		color = theme.Gold,
	},
	{
		header = "Update 18 - Binding Vow Specialist",
		body = "• New gamepass: Binding Vow Specialist (R$ 349).\n• Raises the custom binding vow limit from 3 to 5 per life.\n• Reduces all negative vow effects (sacrifices) by 25%.\n• Works on both custom vows and preset binding vows.\n• New VOWS button added to the navigation bar for quick access.",
		color = theme.Purple,
	},
	{
		header = "Update 18 - Lucky Birth Enhancement",
		body = "• Lucky Birth now guarantees a Rare or higher trait at birth — no more Common-only rolls.\n• 25% luck boost to clan and origin rolls — Lucky Birth now rolls 5 origins and keeps the best.\n• Extra cursed technique roll — if the first innate technique roll fails, Lucky Birth tries again.\n• Lucky Birth price adjusted to R$ 150.",
		color = theme.Gold,
	},
	{
		header = "Update 18 - AFK Free for All",
		body = "• AFK Stabilization is now free for all players — no unlock required.\n• The AFK Pass (R$ 200) now exclusively doubles your AFK payouts (2x).\n• Unlock buttons removed from AFK panels on both PC and Mobile.\n• AFK panel shows '2x ACTIVE' badge if AFK Pass is owned.\n• Rate display reflects the doubled payout for pass owners.",
		color = theme.Green,
	},
	{
		header = "Update 17 - Bug Fixes",
		body = "• Physical Conditioning now correctly resets each age-up (was capped at 3 per lifetime).\n• Fixed exploit where relationship action counter could be bypassed with rapid requests.\n• Unregistered sorcerers can now promote past Grade 4.\n• Send Students on Patrol no longer crashes and consumes your turn.\n• World events, notable sorcerer aging, and era changes now continue past age 16.\n• Newborns no longer default as the strongest sorcerer alive.\n• Gender no longer randomly swaps on surviving spouses during generation takeover.\n• Cursed spirits can now take over prior-life children after death.\n• Rival entries in Affiliations no longer show broken action buttons.\n• God Mode clan picker now shows all clans including Ryomen.\n• Randomize Path button no longer crashes.\n• WAR button now hides when overlay menus are open.",
		color = theme.Red,
	},
	{
		header = "Update 17 - School System",
		body = "• Characters now attend Elementary School (ages 6-10), Middle School (ages 11-13), and High School (ages 14-15).\n• Academic Performance and Attendance drift each year based on your Smarts stat.\n• Earn a Report Card Grade (A+ through F) from performance and attendance.\n• At age 16 you graduate with a full report card popup — honor students earn Smarts and Reputation bonuses.\n• New school activities: Attend Class, Study for Exams, Join a Club (8 clubs), Skip School.",
		color = theme.Red,
	},
	{
		header = "Update 17 - Jujutsu Mentor Career",
		body = "• Jujutsu High students now graduate at age 20 — become a fully Registered Sorcerer with a graduation popup.\n• Awakened sorcerers who graduate civilian school at 16 are offered a transfer to Jujutsu High.\n• After graduating JJH, apply to become a Jujutsu Mentor (age 20+, Grade 2+, recommendations).\n• 4-rank career ladder: Assistant Instructor, Instructor, Senior Instructor, Master Instructor.\n• Earn yearly salary, Mentor XP, reputation, and students assigned to your care.\n• New mentor activities: Teach a Class, Supervise Student Mission, Grade Students, Mentor a Prodigy.\n• New MENTOR panel in the navigation bar to view rank, income, XP progress, and apply.",
		color = theme.Red,
	},
	{
		header = "Update 17 - Activity Sidebar",
		body = "• The Activities menu now has a category sidebar on the left side.\n• Activities grouped into: Life, School, Training, Jujutsu High, Mentor, Missions, Dojo/Clan, Social, Minigames, Curse Spirit, Curse User, Era, Premium.\n• Click any category to instantly scroll to that section.\n• Section headers visually separate each category with color-coded labels.",
		color = theme.Red,
	},
	{
		header = "Update 17 - Full UI Overhaul",
		body = "• Entire client UI rebuilt on Vide (reactive UI architecture).\n• Replaces old monolithic UI script that was hitting engine limits and breaking features.\n• Every major screen restored to full parity — not stripped-down stubs.\n• Fixed panels that would not open, buttons that did not respond, and reactive-scope crashes.\n• 58 Vide modules under game/shared/ui/ (components, panels, hooks, theme).\n• Single bootstrap mounts the full UI, centralized remotes, shared state system.\n• All 30+ panels migrated: Missions, Activities, Relationships, Assets, Jobs, Settings, Combat, Minigames, Domain, Rivals, History, Mentor, Affiliations, Binding Vows, Daily Login, Free Rewards, Update Log, Clan War, God Mode, AFK, Death, Character Customization, Technique Mastery, Trait Details, and more.",
		color = theme.Red,
	},
	{
		header = "Update 17 - Mobile UI",
		body = "• Full mobile UI with portrait-locked layout and touch-optimized controls.\n• Mobile shell: profile header, life log, age-up button, and nav panel all in portrait layout.\n• Every panel has a dedicated Mobile version with swipe-friendly sheets and tap routing.\n• TopbarPlus icons on mobile: Settings, God Mode, War, AFK, Free Rewards.\n• Affiliations actions use an expandable grid instead of overflowing buttons.\n• Combat panel layers above other panels so fights are never obscured.\n• Stat notifications positioned at the top, below TopbarPlus.\n• Trait info button next to traits text on mobile profile.",
		color = theme.Red,
	},
	{
		header = "Update 17 - PC UI",
		body = "• TopbarPlus icons restored on PC: Settings, God Mode, War, AFK, Free Rewards.\n• Legacy WAR nav button hidden — War is now TopbarPlus only.\n• AFK panel now has a working close button.\n• Nav button list scrollable — all nav entries reachable.\n• Responsive layout adapts to portrait, landscape, and desktop viewports.\n• Trait info button next to traits on PC profile.\n• Profile card, life log, and shell components fully functional.",
		color = theme.Red,
	},
	{
		header = "Update 17 - Quality of Life",
		body = "• Loading screen shows for a minimum of 5 seconds to ensure everything loads.\n• Loading screen logo and progress bar positioned closer together.\n• Startup log messages silent on live servers — only visible in Studio.\n• Default Roblox respawn button removed.\n• Update Log accessible from Settings panel LOG tab.",
		color = theme.Red,
	},
	{
		header = "Update 18 - Codes",
		body = "Redeem these in Settings > Codes:\n\n• Update18 — +$25k, +150 CE, +15 Mastery, +15 Rep, +15 Happiness\n• ShopOverhaul — +$30k, +100 CE, +10 Rep\n• VipSorcerer — +200 CE, +20 Mastery, Max Health, Max Happiness\n• BindingVow — +$15k, +100 CE, +15 Strength, +10 Rep\n• SixEyes — +$75k, +300 CE, +20 Mastery, +20 Rep",
		color = theme.Gold,
	},
	{
		header = "Update 16 - QOL & Progression",
		body = "• Console support improvements added.\n• RCT requirements increased and RCT now gives passive health regeneration.\n• Missions and special missions are capped per age-up.\n• Early progression and visible stat gains are slower for a healthier long-term pace.\n• Curse encounters are more frequent based on Curse Exposure.",
		color = theme.Gold,
	},
	{
		header = "Update 16 - Combat & Strength",
		body = "• New Strength stat added.\n• Physical Conditioning activity added.\n• Strength improves basic attack damage, crit chance, and attack timing control.\n• Punching Bag and In-Home Gym added to Assets.\n• Finger hunting can now trigger curse obstacle combat if you get caught.",
		color = theme.Gold,
	},
	{
		header = "Update 16 - Family, Legacy & God Mode",
		body = "• Rivals now appear in Relationships.\n• Children and wards can be recruited into your Grand Dojo.\n• Reincarnation backend added for cursed-object anchor lives.\n• God Mode can directly pick clans and choose exact birth year.\n• Update 16 codes added: Update16, ConsoleSupport, NewGUI, Secret.",
		color = theme.Gold,
	},
	{
		header = "Update 15 - Enemies of Your Era",
		body = "• New Rivals tab added to the main navigation.\n• Your fame, fear, wanted level, hunter pressure, clan history, and cursed identity now shape your reputation path.\n• Reputation paths include Public Hero, Honored Sorcerer, Clan Champion, Rogue Curse User, Infamous Criminal, Feared Curse, and Hidden Monster.\n• Rivals can appear as your name spreads through the world.",
		color = theme.Orange,
	},
	{
		header = "Update 15 - Rival Encounters",
		body = "• Rivals now track name, age, grade, clan, technique intel, threat, status, and win/loss history.\n• Rival encounters can appear during yearly age-up pressure.\n• Respond by fighting, talking them down, escaping, gathering intel, sparing them, or humiliating them.\n• Rival fights use the existing combat system and update rival records after the fight.",
		color = theme.Orange,
	},
	{
		header = "Update 15 - Reputation Rewards",
		body = "• Fame, Fear, Wanted level, Hunter Pressure, and Public Support now matter more.\n• Rival outcomes are recorded into your legacy/world history.\n• New titles added: Rival Maker, Untouchable, Public Hero, Walking Disaster, Marked Sorcerer, and Enemy of Jujutsu Society.\n• Test-rival generation is restricted to dev/testing access only.",
		color = theme.Orange,
	},
	{
		header = "Update 14 - Domain Expansion",
		body = "• New Domain tab added to the main navigation.\n• Players can train Domain progress, stabilize barriers, and unlock Domain stages.\n• Domains progress from Seed to Incomplete Domain to full Domain Expansion.\n• Domain names now reflect your technique, including Unlimited Void, Malevolent Shrine, Chimera Shadow Garden, and more.\n• Combat pressure, victories, defeats, and Domain use can raise Domain progress.",
		color = theme.Purple,
	},
	{
		header = "Update 14 - Domain Combat",
		body = "• Domain button added to combat when your Domain is manifested and you have enough CE.\n• Domain Expansion can deal heavy damage once per fight.\n• Strong enemies can trigger Domain clashes.\n• Winning a clash improves momentum and damage; losing a clash causes backlash.\n• Domain progression is gameplay-first, with monetization focused on support and convenience instead of instant unlocks.",
		color = theme.Purple,
	},
	{
		header = "Update 13 - Combat Expansion",
		body = "• Combat now feels faster with attack timing, dodges, counters, fleeing, and fight results.\n• Critical hits, damage popups, hit/miss feedback, and combat sounds make fights easier to read.\n• Losing a fight can offer a Reset Fight purchase in live servers.\n• New optional Update 13 products added: Combat Recovery Kit, Clan War Mediation, and Cursed Tool Salvage Kit.",
		color = theme.Blue,
	},
	{
		header = "Update 13 - Cursed Tools and Inventory",
		body = "• Cursed Tools can now be collected, equipped, and viewed from Assets.\n• Combat victories and successful missions can rarely drop cursed tools.\n• Stronger enemies and harder missions can reward better cursed tools.\n• Equipped cursed tools can improve combat power, defense, mission survival, or CE gains.\n• Duplicate cursed tools now convert into money and CE.\n• The Cursed Tool Catalog shows owned and locked tools, rarity, effects, and drop weight.\n• New Epic cursed tool added: Binding Chain Wrap.\n• Cursed Tool cards now fit better on smaller screens.\n• New collection titles added: Cursed Tool Bearer, Relic Collector, and Complete Arsenal.\n• World History now tracks cursed tool collection count.",
		color = theme.Blue,
	},
	{
		header = "Update 13 - Clan War System",
		body = "• Established clans can now be pulled into Clan Wars against rival clans.\n• Clan Wars track tension, battles, wins, losses, history, and yearly escalation.\n• Use Defend, Strike, Negotiate, or Betray to shape the war.\n• Defend, Strike, and Betray can trigger real combat against rival clan fighters.\n• Yearly war events now include raids, truce talks, rumors, training pressure, and public fear.\n• Clan War actions show recovery time when your clan needs to regroup.\n• Affiliations now shows active and recent Clan War rivals.\n• World History now records Clan War outcomes.\n• New Clan War titles added: War-Proven, Clan Conqueror, and Unbroken Banner.",
		color = theme.Blue,
	},
	{
		header = "Update 12 - Combat Gameplay",
		body = "• Interactive combat encounters added.\n• Attack timing minigame added with sweet spot critical hits.\n• Technique attacks added with CE cost and limited uses.\n• Dodge and counter attack QTEs added.\n• Combat result popups, damage text, hit/miss feedback, and fight sounds added.",
		color = theme.Green,
	},
	{
		header = "Update 12 - AFK Stabilization",
		body = "• AFK Stabilization added as a monetized idle earning feature.\n• AFK button moved to the top bar beside Shop.\n• AFK sessions now stop when the player gives input.\n• AFK earnings now pay out correctly when AFK stops or the player disconnects.\n• AFK money display now rounds cleanly to cents.",
		color = theme.Green,
	},
	{
		header = "Update 12 - Premium and Live Prompts",
		body = "• Reset Fight developer product added for combat recovery.\n• AFK Stabilization purchase flow added.\n• Live place purchases now use Roblox purchase prompts.\n• Testing place bypass remains limited to the testing place.",
		color = theme.Green,
	},
	{
		header = "Update 12 - Polish and Fixes",
		body = "• Combat pacing improved for faster rounds.\n• Flee, dodge, counter, and attack feedback improved.\n• Money values no longer show long decimal tails.",
		color = theme.Green,
	},
	{
		header = "Update 10 - Premium Testing",
		body = "• Added test-place Robux bypass for the current testing place.\n• Developer products can be tested without purchasing in the test place.\n• Gamepasses are treated as owned in the test place for verification.\n• Production places still require normal Roblox Marketplace purchases.",
		color = theme.SubText,
	},
	{
		header = "Update 10 - Go Rogue Route",
		body = "• Go Rogue in Jobs is now a Developer Product route purchase.\n• Go Rogue grants only after a valid product receipt or test-place grant.\n• Old free remote calls no longer grant Rogue Sorcerer status.\n• Jobs now show SET ID until the Go Rogue product ID is configured.",
		color = theme.SubText,
	},
	{
		header = "Update 10 - Burglary Fixes",
		body = "• Burglary loot can no longer spawn under guards.\n• Burglary loot can no longer spawn on start, exit, or invalid cells.\n• Burglary boards now verify that loot and exit are reachable.\n• Added a LEAVE button so players can abandon burglary without being captured.\n• Dojo Raid burglary-style boards now use the same safe board generation.",
		color = theme.SubText,
	},
	{
		header = "Update 10 - Activity and Relationship Fixes",
		body = "• Relationship actions no longer consume normal activity slots.\n• Using relationship actions first no longer blocks activities until aging up.\n• Cursed Womb and curse activities no longer get wrongly blocked by human-life checks.\n• Curse activity access now uses a safer cursed-life eligibility check.",
		color = theme.SubText,
	},
	{
		header = "Update 10 - Stability",
		body = "• Added server validation for test purchases by place ID.\n• Added product ID payload support for paid Jobs actions.\n• Confirmed key updated scripts load cleanly in Play mode.\n• Continued UI and gameplay bug cleanup from tester reports.",
		color = theme.SubText,
	},
	{
		header = "Update 10 - Combat Foundation",
		body = "• Added interactive combat sessions with player and enemy HP/CE.\n• Added attack timing minigame with target zone and sweet spot.\n• Added defend QTE for 1 to 3 hit enemy combos.\n• Added perfect-dodge counter attack window.\n• Added test-place combat starter for verification.\n• Added Reset Fight developer product hook with test-place bypass.",
		color = theme.SubText,
	},
}

local function clearList()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
end

local function renderSections()
	clearList()

	local subtitleCard = mc.mobileCard({ parent = scroll, order = 0, accentColor = theme.Gold })
	mc.mobileLabel({
		parent = subtitleCard,
		text = "Shop overhaul, VIP expansion, Binding Vow Specialist, AFK for all, and new gamepasses",
		size = 13,
		color = theme.SubText,
		order = 1,
	})
	mc.mobileLabel({
		parent = subtitleCard,
		text = "Rejoin once if anything looks weird after the update.",
		size = 12,
		color = theme.Muted,
		order = 2,
	})

	for i, section in ipairs(sections) do
		local card = mc.mobileCard({ parent = scroll, order = i, accentColor = section.color })

		mc.mobileLabel({
			parent = card,
			text = section.header,
			size = 15,
			color = section.color,
			font = Enum.Font.GothamBlack,
			order = 1,
		})
		mc.mobileLabel({
			parent = card,
			text = section.body,
			size = 13,
			color = theme.Text,
			order = 2,
		})
	end
end

local function openPanel()
	gui.Enabled = true
	sheet.Visible = true
	renderSections()
end

local function closePanel()
	gui.Enabled = false
	sheet.Visible = false
	clearList()
end

local function init()
	gui = Instance.new("ScreenGui")
	gui.Name = "BitKaisenMobileUpdateLogGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 637
	gui.Enabled = false
	gui.Parent = playerGui

	sheet = mc.mobileSheet({
		name = "MobileUpdateLogSheet",
		parent = gui,
		title = "UPDATE LOG",
		onClose = function()
			uiState.closeRoute()
		end,
	})

	scroll = sheet:FindFirstChildWhichIsA("ScrollingFrame") :: ScrollingFrame

	uiState.subscribe(function(route)
		if route == "updatelog" then
			openPanel()
		else
			if gui.Enabled then
				closePanel()
			end
		end
	end)
end

return { init = init, open = openPanel, close = closePanel }
