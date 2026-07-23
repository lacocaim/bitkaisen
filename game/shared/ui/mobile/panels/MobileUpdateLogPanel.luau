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
		header = "Update 23 - Kenjaku Clan: Death Paintings & Culling Games",
		body = "• Kenjaku characters with Brain Transplant can now create Death Paintings, usable as a special attack in combat.\n• Recruit Notable Sorcerers into the Culling Games for a shot at big rewards.",
		color = theme.Purple,
	},
	{
		header = "Update 23 - New Features",
		body = "• Looks & Surgery: a new activity to improve your Looks stat, once per age, for a price.\n• You can now rename your children from the relationship menu.",
		color = theme.Gold,
	},
	{
		header = "Update 23 - Bug Fixes",
		body = "• Fixed Curse User missions guaranteeing success with zero risk. They now roll against your power like other missions, and failure has real consequences instead of free money.\n• Fixed the Update Log appearing to lag behind when spamming missions or choices too fast; you'll now see a clear warning instead of the action silently doing nothing.\n• Fixed traits like Six Eyes (and every other trait's Cursed Energy, Mastery, Smarts, and Money bonuses) not applying during random life scenarios and some missions. This is very likely why Six Eyes and similar traits felt like they stopped working.\n• Fixed around 130 Spanish/Portuguese activity translations that were never loading correctly.\n• The locked message for founding a Cult now correctly mentions you also need Wanted Level 3+.\n• Fixed Notable Sorcerers repeating the 'became your friend' message over and over.\n• Fixed Brain Transplant incorrectly aging characters.\n• Fixed Clan War and Cult War combat getting stuck in a restart loop.\n• Fixed Domain Clash not working correctly on Mobile.\n• Fixed the info '?' button being misplaced on the Traits/Technique Stage screen.\n• Fixed a critical bug that could make the game fail to load entirely for some players.",
		color = theme.Green,
	},
	{
		header = "Update 22 - New Gamepasses",
		body = "• Premium Origins: guarantees you're born into a canon clan or lineage (Gojo, Zenin, Itadori, and more), plus a family heirloom cursed tool at birth.\n• High Society: +25% Bond, Trust, and Romance gains, an extra relationship action every age, an easier path to courting Notable Sorcerers, and more of them appearing in your world.",
		color = theme.Gold,
	},
	{
		header = "Update 22 - Real Domain Clash",
		body = "• Domain Clash is now an actual minigame: a tug of war meter you push toward your side before time runs out, instead of a hidden dice roll.\n• Works with touch, mouse, or gamepad (mash A or B).",
		color = theme.Purple,
	},
	{
		header = "Update 22 - Bug Fixes",
		body = "• Fixed the Domain Clash never showing its minigame.\n• Fixed a child's age and 'years known' falling out of sync after using Brain Transplant.\n• Strength, Speed, and Durability can no longer creep past their 100 cap.\n• Fixed Grade Up never advancing once a character was branded a Curse User.\n• Fixed the Affiliations list cutting off and not scrolling all the way down on smaller screens.\n• Fixed the persistent Guide staying visible after being turned off.\n• Update log now shows the latest update instead of getting stuck on an old one.\n• Combat quick-time events now show a 'Press A or B' hint for gamepad players.",
		color = theme.Green,
	},
	{
		header = "Update 21 - New Player Guide System",
		body = "• A full interactive tutorial for new sorcerers, on PC and Mobile: walks you through every screen and mechanic step by step.\n• A persistent Guide that always points you to your next best move: activities, rivals, missions, relationships, domain, or aging up.\n• New Help & Guide panel: replay the tutorial or turn the Guide on/off anytime from one place.\n• Redesigned main UI on PC to match Mobile's dossier style: classified file header, stat bars, and system log.",
		color = theme.Gold,
	},
	{
		header = "Update 21 - Bug Fixes",
		body = "• Starting a relationship no longer instantly ages your partner by 10 years.\n• Finger Hunt no longer breaks permanently after dying to it once.\n• Removed stray 'ui.' text showing up on some buttons.\n• Fixed gaining Technique Mastery with no technique to speak of.\n• Children can no longer be trained endlessly without aging up, and their Cursed Energy no longer carries over unbalanced when you take over their life.\n• Brain Transplant no longer incorrectly changes the age of other people in your life.\n• Fixed the curse overlapping a finger during Finger Hunt, making them impossible to tell apart.\n• Notable Sorcerers can now become friends with a great relationship, like everyone else.\n• Removed a duplicate Physical Conditioning training option.\n• Notable Sorcerers' traits and info now display correctly.",
		color = theme.Green,
	},
	{
		header = "Update 20 - Bug Fixes",
		body = "• Not all traits were showing up on the mobile UI, fixed and now display correctly.\n• Traits with long text on PC were getting cut off, now show in full.\n• Vows now appear on PC and Xbox, not just mobile, added scroll support.\n• Cemetery now correctly registers your past life technique.\n• Black Flash timing window now appears on mobile when triggered in combat.\n• Text in combat logs no longer cuts off mid sentence.\n• Notable Sorcerer romance now correctly loads personality and gender.\n• Relations panel now shows all traits correctly.",
		color = theme.Green,
	},
	{
		header = "Update 20 - Multi-Language System",
		body = "• Added Phase 1 support for Spanish and Portuguese in-game.",
		color = theme.Blue,
	},
	{
		header = "Update 20 - Black Market",
		body = "• Buy and sell cursed tools and illegal items through the underground market.",
		color = theme.Gold,
	},
	{
		header = "Update 20 - Cursed Organization and Cult",
		body = "• Create your own organization of curse users and build your influence.\n• Declare war between cults and fight for dominance.",
		color = theme.Purple,
	},
	{
		header = "Update 20 - New Codes",
		body = "Redeem in Settings > Codes:\n\n• OPCODE: +$15,000, +80 CE, +10 Mastery, +5 Rep\n• BLACKMARKET: +$25,000, +5 Strength, +5 Smarts\n• HIDDENVEIL: +60 CE, +8 Mastery, +10 Fear",
		color = theme.Blue,
	},
	{
		header = "Update 20 - Beach Hero Gamepass Grants",
		body = "• Remaining Beach Hero players now automatically receive their earned gamepass on login.",
		color = theme.Green,
	},
	{
		header = "Summer Update Pt.3 - Bug Fixes",
		body = "• Black Flash popup no longer blocks the dodge button during combat.\n• Relations (siblings and others) now age correctly alongside the player.\n• Settings menu no longer accidentally triggers buttons behind it.\n• Weeklies now save correctly across servers.\n• 'Steady Work' weekly no longer appears as incomplete after rejoining.\n• Achievement unlock and claim states are now in sync.\n• Xbox cursor now shows the native cursor correctly, dodge restored.",
		color = theme.Green,
	},
	{
		header = "Summer Update Pt.3 - Black Flash Improvements",
		body = "• Failing a Black Flash now penalizes you: expect CE drain and the enemy gaining an opening on your next defense.",
		color = theme.Red,
	},
	{
		header = "Summer Update Pt.3 - CT Preserved When Possessed by Sukuna",
		body = "• Manga canon: consuming all 20 fingers no longer replaces your Cursed Technique with Shrine. Your technique stays yours.",
		color = theme.Purple,
	},
	{
		header = "Summer Update Pt.3 - Gender of Notable Sorcerers",
		body = "• Notable Sorcerer cards now display gender alongside age and grade.",
		color = theme.Gold,
	},
	{
		header = "Summer Update Pt.3 - Cause of Death",
		body = "• The death screen now shows the specific reason you died.",
		color = theme.Gold,
	},
	{
		header = "Summer Update Pt.3 - Mobile UI Redesign",
		body = "• The main mobile interface has been completely redesigned with a classified file aesthetic.",
		color = theme.Gold,
	},
	{
		header = "Summer Update Pt.3 - Background Music",
		body = "• BitKaisen now has background music.",
		color = theme.Blue,
	},
	{
		header = "Summer Update Pt.2 - Bug Fixes",
		body = "• Life log text on mobile no longer gets cut off.\n• Brain transplant no longer causes time to roll back.\n• Weekly mission now correctly marks as completed after reconnecting.\n• Fixed visual glitch in reward thumbnails.\n• Mobile UI locked to portrait only with spacing and visibility fixes.\n• World History tabs no longer mix content when tapped simultaneously.\n• Technique Mastery is now accessible from the mobile navigation panel.",
		color = theme.Green,
	},
	{
		header = "Summer Update Pt.2 - Black Flash in Combat",
		body = "• New skill check during combat: land a Black Flash with the right timing and your own Mastery level.",
		color = theme.Red,
	},
	{
		header = "Summer Update Pt.2 - Wanted and Bounty System",
		body = "• Reach high threat levels and bounty hunters will start tracking you down based on your danger level.",
		color = theme.Red,
	},
	{
		header = "Summer Update Pt.2 - Hereditary Properties",
		body = "• Dojo, clan house, and cursed tools can now be passed down as assets through your lineage.",
		color = theme.Gold,
	},
	{
		header = "Summer Update Pt.2 - Romance with Notable Sorcerers",
		body = "• Select NPCs with lore are now romanceable, each with their own personality and story.",
		color = theme.Purple,
	},
	{
		header = "Summer Update Pt.2 - Domain Effects by CT",
		body = "• Your Cursed Technique now determines unique effects inside your Domain Expansion.",
		color = theme.Gold,
	},
	{
		header = "Summer Update Pt.2 - Siblings at Birth",
		body = "• 40% chance to be born with 1 or 2 siblings, each with their own name, age, personality, and background.",
		color = theme.Purple,
	},
	{
		header = "Summer Update Pt.2 - CE Addiction System",
		body = "• CE Boosts now build a hidden addiction. At high levels expect withdrawal: losing Health and Happiness each year. It fades if you stop.",
		color = theme.Red,
	},
	{
		header = "Summer Update Pt.2 - Beach Hero Gamepass Grants",
		body = "• Players selected during the Beach Hero event now receive their earned gamepass automatically on login: God Mode, VIP Sorcerer, Training Prodigy, or Go Rogue.",
		color = theme.Green,
	},
	{
		header = "Summer Update Pt.2 - New Codes",
		body = "Redeem in Settings > Codes:\n\n• SUMMERPT2: +$20,000, +100 CE, +10 Mastery, +10 Rep\n• VEILOFCURSES: +$10,000, +60 CE, +8 Strength, Full Health",
		color = theme.Blue,
	},
	{
		header = "Summer Update - Bug Fixes",
		body = "• Auto-enroll into JJH at 16 no longer cuts the Curse User route.\n• Log and actions not scrollable after age up, fixed on mobile and desktop.\n• White cursor on Xbox making combat unplayable, fixed.\n• Jujutsu High existing in the Heian Era (year 810), fixed.",
		color = theme.Green,
	},
	{
		header = "Summer Update - Cemetery of Lives",
		body = "• New Cemetery panel: see every past life, cause of death, and legacy summary.",
		color = theme.Gold,
	},
	{
		header = "Summer Update - Death Ribbons and Life Titles",
		body = "• Earn a title when you die based on how you lived.\n• Examples: Heroic Sorcerer, Curse User, Wanderer, Fallen, and more.",
		color = theme.Purple,
	},
	{
		header = "Summer Update - Special Talents at Birth",
		body = "• Rare birth talents that go beyond your Cursed Technique.\n• Affects training speed, stat growth, social ability, and more.",
		color = theme.Gold,
	},
	{
		header = "Summer Update - Hidden Karma System",
		body = "• Every life builds a hidden Karma score that silently shapes your world.\n• You won't see the number, but your choices matter.",
		color = theme.Purple,
	},
	{
		header = "Summer Update - Fame and Fear Expanded",
		body = "• New ways to raise Fame and Fear.\n• Rivals, NPCs, and affiliations now react to your reputation.",
		color = theme.Gold,
	},
	{
		header = "Summer Update - Weekly Challenges",
		body = "• New WEEKLY nav tab, 6 challenges rotating every Monday.\n• Complete the condition, get the reward, track it in the panel.",
		color = theme.Blue,
	},
	{
		header = "Summer Update - Time Skip Products",
		body = "+5, +10, +25 Years now available as developer products in the Shop.\n\n• +5 Years: R$ 75\n• +10 Years: R$ 149\n• +25 Years: R$ 299",
		color = theme.Blue,
	},
	{
		header = "Summer Update - New Hair Colors",
		body = "• Green, Blue, and Orange now available at character creation.",
		color = theme.Gold,
	},
	{
		header = "Summer Update - New Codes",
		body = "Redeem in Settings > Codes:\n\n• SUMMERUPDATE: +$25k, +120 CE, +12 Mastery, +12 Rep, +12 Happiness\n• CURSESEASON: +$15k, +80 CE, +10 Strength, +10 Rep\n• DOMAINOPENED: +200 CE, +15 Mastery, Full Health, Full Happiness\n• SHADOWTHREAD: +$60k, +200 CE, +15 Mastery, +15 Rep",
		color = theme.Blue,
	},
	{
		header = "Update 19 - Sound Effects",
		body = "• Navigation buttons now have sound on press.\n• Sound when aging up (+AGE).\n• Death sound, notifications, positive and negative events.\n• All sounds respect your audio settings in Settings.",
		color = theme.Blue,
	},
	{
		header = "Update 19 - Bug Fixes",
		body = "• Fixed bug where recruiting candidates at the Dojo wasn't working.\n• Fixed bug where Brain Transplant changed the character's year incorrectly.\n• Fixed invisible scroll bar on the profile panel.",
		color = theme.Green,
	},
	{
		header = "Update 19 - UI",
		body = "• Black background behind the UI on PC and mobile.\n• Navigation buttons redesigned with unique colors per category.\n• Mentor panel updated to match the standard visual style.\n• Main interface looks more balanced and polished on PC.",
		color = theme.Gold,
	},
	{
		header = "Hotfix - Gift System",
		body = "• Gifts now work cross-server - enter any Roblox username to send a gift.\n• Recipient no longer needs to be in your server.\n• If the recipient is offline, the gift is saved and delivered on their next login.\n• Server validates the username before opening the Robux prompt.\n• Improved retry handling for edge cases during purchase.",
		color = theme.Green,
	},
	{
		header = "Shop Overhaul",
		body = "• All shop prices now match the Creator Dashboard - no more mismatches.\n• Every gamepass and developer product has an accurate description.\n• Go Rogue gamepass now listed in the shop.\n• God Mode updated to R$ 800 with expanded features.\n• 2x Progress updated to R$ 400 - doubled CE, Strength, and Mastery gains.\n• 5 new developer products priced: CT Evolution Accelerator, Black Flash Drill Pack, Clan War Mediation, Cursed Tool Salvage Kit, Combat Recovery Kit.",
		color = theme.Gold,
	},
	{
		header = "New Gamepasses",
		body = "• Lucky Sorcerer (R$ 349) - +15% birth stats every new life.\n• Training Prodigy (R$ 349) - 1.5x CE, Strength, and Mastery training.\n• Mission Investor (R$ 299) - 1.5x cash from missions (stacks with 2x Money).\n• Legacy Blessing (R$ 349) - Heirs start stronger each generation (+CE, +Strength, +Smarts, +Health, +Rep scaling with bloodline depth).\n• Focused Training (R$ 199) - +25% CE from CE training (stacks with everything).\n• AFK Pass (R$ 200) - 2x AFK payouts (AFK is free for all now).\n• Binding Vow Specialist (R$ 349) - 5 vows instead of 3, -25% negative effects.\n• Dojo Expansion (coming soon) - +5 recruit candidates, +2 student capacity.",
		color = theme.Gold,
	},
	{
		header = "VIP Sorcerer Pass Expansion",
		body = "• 2x daily login rewards.\n• 1.5x money from missions and jobs.\n• 1.5x training gains.\n• 2x Technique Mastery gains.\n• Exclusive 'VIP Sorcerer' title.\n• Extra save slots included.",
		color = theme.Gold,
	},
	{
		header = "Binding Vow Specialist",
		body = "• Custom vow limit raised from 3 to 5.\n• All negative effects reduced by 25%.\n• New VOWS nav button for quick access.",
		color = theme.Purple,
	},
	{
		header = "Lucky Birth Enhancement",
		body = "• Guaranteed Rare+ trait at birth.\n• 25% luck boost to clan/origin rolls.\n• Extra cursed technique roll if first fails.",
		color = theme.Gold,
	},
	{
		header = "AFK Free for All",
		body = "• AFK Stabilization is now FREE for everyone.\n• AFK Pass doubles your idle payouts (2x).",
		color = theme.Green,
	},
	{
		header = "New Codes",
		body = "Redeem in Settings > Codes:\n\n• Update18 - +$25k, +150 CE, +15 Mastery, +15 Rep, +15 Happiness\n• ShopOverhaul - +$30k, +100 CE, +10 Rep\n• VipSorcerer - +200 CE, +20 Mastery, Max Health, Max Happiness\n• BindingVow - +$15k, +100 CE, +15 Strength, +10 Rep\n• SixEyes - +$75k, +300 CE, +20 Mastery, +20 Rep",
		color = theme.Blue,
	},
	{
		header = "Update 17 - Bug Fixes",
		body = "• Physical Conditioning now correctly resets each age-up (was capped at 3 per lifetime).\n• Fixed exploit where relationship action counter could be bypassed with rapid requests.\n• Unregistered sorcerers can now promote past Grade 4.\n• Send Students on Patrol no longer crashes and consumes your turn.\n• World events, notable sorcerer aging, and era changes now continue past age 16.\n• Newborns no longer default as the strongest sorcerer alive.\n• Gender no longer randomly swaps on surviving spouses during generation takeover.\n• Cursed spirits can now take over prior-life children after death.\n• Rival entries in Affiliations no longer show broken action buttons.\n• God Mode clan picker now shows all clans including Ryomen.\n• Randomize Path button no longer crashes.\n• WAR button now hides when overlay menus are open.",
		color = theme.Red,
	},
	{
		header = "Update 17 - School System",
		body = "• Characters now attend Elementary School (ages 6-10), Middle School (ages 11-13), and High School (ages 14-15).\n• Academic Performance and Attendance drift each year based on your Smarts stat.\n• Earn a Report Card Grade (A+ through F) from performance and attendance.\n• At age 16 you graduate with a full report card popup - honor students earn Smarts and Reputation bonuses.\n• New school activities: Attend Class, Study for Exams, Join a Club (8 clubs), Skip School.",
		color = theme.Red,
	},
	{
		header = "Update 17 - Jujutsu Mentor Career",
		body = "• Jujutsu High students now graduate at age 20 - become a fully Registered Sorcerer with a graduation popup.\n• Awakened sorcerers who graduate civilian school at 16 are offered a transfer to Jujutsu High.\n• After graduating JJH, apply to become a Jujutsu Mentor (age 20+, Grade 2+, recommendations).\n• 4-rank career ladder: Assistant Instructor, Instructor, Senior Instructor, Master Instructor.\n• Earn yearly salary, Mentor XP, reputation, and students assigned to your care.\n• New mentor activities: Teach a Class, Supervise Student Mission, Grade Students, Mentor a Prodigy.\n• New MENTOR panel in the navigation bar to view rank, income, XP progress, and apply.",
		color = theme.Red,
	},
	{
		header = "Update 17 - Activity Sidebar",
		body = "• The Activities menu now has a category sidebar on the left side.\n• Activities grouped into: Life, School, Training, Jujutsu High, Mentor, Missions, Dojo/Clan, Social, Minigames, Curse Spirit, Curse User, Era, Premium.\n• Click any category to instantly scroll to that section.\n• Section headers visually separate each category with color-coded labels.",
		color = theme.Red,
	},
	{
		header = "Update 17 - Full UI Overhaul",
		body = "• Entire client UI rebuilt on Vide (reactive UI architecture).\n• Replaces old monolithic UI script that was hitting engine limits and breaking features.\n• Every major screen restored to full parity - not stripped-down stubs.\n• Fixed panels that would not open, buttons that did not respond, and reactive-scope crashes.\n• 58 Vide modules under game/shared/ui/ (components, panels, hooks, theme).\n• Single bootstrap mounts the full UI, centralized remotes, shared state system.\n• All 30+ panels migrated: Missions, Activities, Relationships, Assets, Jobs, Settings, Combat, Minigames, Domain, Rivals, History, Mentor, Affiliations, Binding Vows, Daily Login, Free Rewards, Update Log, Clan War, God Mode, AFK, Death, Character Customization, Technique Mastery, Trait Details, and more.",
		color = theme.Red,
	},
	{
		header = "Update 17 - Mobile UI",
		body = "• Full mobile UI with portrait-locked layout and touch-optimized controls.\n• Mobile shell: profile header, life log, age-up button, and nav panel all in portrait layout.\n• Every panel has a dedicated Mobile version with swipe-friendly sheets and tap routing.\n• TopbarPlus icons on mobile: Settings, God Mode, War, AFK, Free Rewards.\n• Affiliations actions use an expandable grid instead of overflowing buttons.\n• Combat panel layers above other panels so fights are never obscured.\n• Stat notifications positioned at the top, below TopbarPlus.\n• Trait info button next to traits text on mobile profile.",
		color = theme.Red,
	},
	{
		header = "Update 17 - PC UI",
		body = "• TopbarPlus icons restored on PC: Settings, God Mode, War, AFK, Free Rewards.\n• Legacy WAR nav button hidden - War is now TopbarPlus only.\n• AFK panel now has a working close button.\n• Nav button list scrollable - all nav entries reachable.\n• Responsive layout adapts to portrait, landscape, and desktop viewports.\n• Trait info button next to traits on PC profile.\n• Profile card, life log, and shell components fully functional.",
		color = theme.Red,
	},
	{
		header = "Update 17 - Quality of Life",
		body = "• Loading screen shows for a minimum of 5 seconds to ensure everything loads.\n• Loading screen logo and progress bar positioned closer together.\n• Startup log messages silent on live servers - only visible in Studio.\n• Default Roblox respawn button removed.\n• Update Log accessible from Settings panel LOG tab.",
		color = theme.Red,
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
		text = "UPDATE 23: Kenjaku's Death Paintings, Surgery, and a big bug fix pass",
		size = 13,
		color = theme.SubText,
		order = 1,
	})
	mc.mobileLabel({
		parent = subtitleCard,
		text = "Rejoin once if anything looks off after the update.",
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
