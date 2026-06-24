local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")

local uiState = require("@ui-state/uiState")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

----------------------------------------------------------------
-- REMOTES
----------------------------------------------------------------
local updateLifeEvent = ReplicatedStorage:WaitForChild("UpdateLifeEvent")
local updateSettingsEvent = ReplicatedStorage:WaitForChild("UpdateSettingsEvent")
local testPurchase = ReplicatedStorage:WaitForChild("TestPurchase")
local setGiftRecipient = ReplicatedStorage:WaitForChild("SetGiftRecipient")

local TEST_PURCHASE_PLACE_ID = 104206065947170
local function promptRobuxItem(kind, robloxId)
	robloxId = tonumber(robloxId) or 0
	if robloxId <= 0 then return end
	if game.PlaceId == TEST_PURCHASE_PLACE_ID then
		testPurchase:FireServer(kind, robloxId)
		return
	end
	if kind == "GamePass" then
		MarketplaceService:PromptGamePassPurchase(player, robloxId)
	else
		MarketplaceService:PromptProductPurchase(player, robloxId)
	end
end

local getSaveSlots = ReplicatedStorage:WaitForChild("GetSaveSlots")
local selectSaveSlot = ReplicatedStorage:WaitForChild("SelectSaveSlot")
local createSaveSlot = ReplicatedStorage:WaitForChild("CreateSaveSlot")
local deleteSaveSlot = ReplicatedStorage:WaitForChild("DeleteSaveSlot")

local redeemCode = ReplicatedStorage:WaitForChild("RedeemCode")
local getCodeGate = ReplicatedStorage:WaitForChild("GetCodeGate")

local getAchievements = ReplicatedStorage:FindFirstChild("GetAchievements")
local claimAchievement = ReplicatedStorage:FindFirstChild("ClaimAchievement")

----------------------------------------------------------------
-- IDS
----------------------------------------------------------------
local VIP_SORCERER_PASS_ID = 1847855390
local EXTRA_SAVE_SLOTS_GAMEPASS_ID = 1850884816
local DOUBLE_MONEY_GAMEPASS_ID = 1849510820
local DOUBLE_TRAINING_GAMEPASS_ID = 1849210885
local LUCKY_BIRTH_GAMEPASS_ID = 1859848647
local EXTRA_DOJO_STUDENTS_GAMEPASS_ID = 1862959768
local GOD_MODE_GAMEPASS_ID = 1861509054

local STARTER_SORCERER_PACK_PRODUCT_ID = 3595826857
local FOCUSED_TRAINING_PRODUCT_ID = 3595838153
local MONEY_5000_PRODUCT_ID = 3596044734
local MONEY_25000_PRODUCT_ID = 3595898637
local MONEY_100000_PRODUCT_ID = 3596045207
local RECRUIT_REROLL_PRODUCT_ID = 3596045471
local RECOMMENDATION_LETTER_PRODUCT_ID = 3600600214
local EMERGENCY_TREATMENT_PRODUCT_ID = 3600600619

local CT_REROLL_PRODUCT_ID = 3601369202
local CLAN_REROLL_PRODUCT_ID = 3601369293
local TRAIT_REROLL_PRODUCT_ID = 3601369404
local FULL_POWER_REROLL_PRODUCT_ID = 3601369468
local MASTERY_BOOST_15_PRODUCT_ID = 3601369579
local CE_BOOST_15_PRODUCT_ID = 3601369642
local ELITE_SORCERER_PACK_PRODUCT_ID = 3601369769
local DOJO_FUNDING_PACK_PRODUCT_ID = 3603671641
local CT_EVOLUTION_ACCELERATOR_PRODUCT_ID = 3603684614
local BLACK_FLASH_DRILL_PACK_PRODUCT_ID = 3603684671
local GIFT_GO_ROGUE_PRODUCT_ID = 3604042615
local GIFT_GOD_MODE_PRODUCT_ID = 3606084567
local GIFT_AFK_STABILIZATION_PRODUCT_ID = 3606084638
local TEST_GIFT_PRODUCT_ID = 3606089240

local CLAN_WAR_MEDIATION_PRODUCT_ID = 3605163954
local CURSED_TOOL_SALVAGE_KIT_PRODUCT_ID = 3605164055
local COMBAT_RECOVERY_KIT_PRODUCT_ID = 3605164164

----------------------------------------------------------------
-- SETTINGS / THEME
----------------------------------------------------------------
local MAIN_GUI_NAME = "BitKaisenGui"

local DEFAULT_SETTINGS = {
	MusicVolume = 1,
	SFXVolume = 1,
	MuteMusic = false,
	MuteSFX = false,
	FastText = false,
	HighContrastText = false,
	ReducedMotion = false,
	ScreenShake = true,
	SkipCombatSkillChecks = false,
}

local THEME = {
	Bg = Color3.fromRGB(8, 8, 12),
	Bg2 = Color3.fromRGB(12, 12, 18),
	Panel = Color3.fromRGB(15, 15, 22),
	Panel2 = Color3.fromRGB(20, 20, 30),
	Panel3 = Color3.fromRGB(27, 27, 38),
	Card = Color3.fromRGB(21, 21, 30),
	Card2 = Color3.fromRGB(27, 27, 38),
	Stroke = Color3.fromRGB(50, 50, 66),
	StrokeSoft = Color3.fromRGB(36, 36, 50),

	Text = Color3.fromRGB(240, 240, 248),
	SubText = Color3.fromRGB(170, 170, 190),
	Muted = Color3.fromRGB(115, 115, 135),

	Red = Color3.fromRGB(155, 35, 48),
	RedDark = Color3.fromRGB(74, 18, 27),
	RedSoft = Color3.fromRGB(105, 31, 43),

	Gold = Color3.fromRGB(240, 190, 90),
	Green = Color3.fromRGB(105, 220, 140),
	Blue = Color3.fromRGB(105, 170, 255),
	Purple = Color3.fromRGB(170, 115, 255),
	Orange = Color3.fromRGB(245, 145, 70),
	Bad = Color3.fromRGB(235, 75, 95),
}

local SHOP_CATEGORIES = {
	{
		Name = "Featured",
		Subtitle = "Best value packs and starter purchases.",
		Accent = THEME.Gold,
		Items = {
			{ Id = "god_mode", Name = "God Mode", Subtitle = "Premium life tuning: trait edits, clan rerolls, start boosts, legacy trait inheritance, and reset life controls.", Kind = "GamePass", RobloxId = GOD_MODE_GAMEPASS_ID, PriceText = "R$ 399", Accent = THEME.Gold },
			{ Id = "elite_sorcerer_pack", Name = "Elite Sorcerer Pack", Subtitle = "Money, CE, recommendations, boosts, and power rerolls bundled together.", Kind = "Product", RobloxId = ELITE_SORCERER_PACK_PRODUCT_ID, PriceText = "R$ 500", Accent = THEME.Gold },
			{ Id = "starter_pack", Name = "Starter Sorcerer Pack", Subtitle = "Money, CE boost, and early-game help.", Kind = "Product", RobloxId = STARTER_SORCERER_PACK_PRODUCT_ID, PriceText = "R$ 149", Accent = THEME.Gold },
			{ Id = "gift_go_rogue", Name = "Gift Go Rogue", Subtitle = "Gift permanent Go Rogue access to another Roblox user.", Kind = "Product", RobloxId = GIFT_GO_ROGUE_PRODUCT_ID, GiftPassKey = "GoRogue", PriceText = "GIFT", Accent = THEME.Purple },
			{ Id = "gift_god_mode", Name = "Gift God Mode", Subtitle = "Gift God Mode access to another Roblox user.", Kind = "Product", RobloxId = GIFT_GOD_MODE_PRODUCT_ID, GiftPassKey = "GodMode", PriceText = "GIFT", Accent = THEME.Gold },
			{ Id = "gift_afk_stabilization", Name = "Gift AFK Stabilization", Subtitle = "Gift AFK Stabilization access to another Roblox user.", Kind = "Product", RobloxId = GIFT_AFK_STABILIZATION_PRODUCT_ID, GiftPassKey = "AFKStabilization", PriceText = "GIFT", Accent = THEME.Green },
			{ Id = "test_gift", Name = "Test Gift", Subtitle = "Testing-place-only gift item for validating the gift username and receipt flow.", Kind = "Product", RobloxId = TEST_GIFT_PRODUCT_ID, GiftPassKey = "TestGift", PriceText = "TEST", Accent = THEME.Blue, TestOnly = true },
		},
	},
	{
		Name = "Rerolls",
		Subtitle = "Change your current life power setup.",
		Accent = THEME.Purple,
		Items = {
			{ Id = "full_power_reroll", Name = "Full Reroll", Subtitle = "Reroll clan, cursed technique, and traits in one purchase.", Kind = "Product", RobloxId = FULL_POWER_REROLL_PRODUCT_ID, PriceText = "R$ 200", Accent = THEME.Red },
			{ Id = "ct_reroll", Name = "Cursed Technique Reroll", Subtitle = "Reroll your current cursed technique without wiping the life.", Kind = "Product", RobloxId = CT_REROLL_PRODUCT_ID, PriceText = "R$ 99", Accent = THEME.Purple },
			{ Id = "clan_reroll", Name = "Clan Reroll", Subtitle = "Reroll your human clan/origin. Cursed Spirit lives save this as a token instead.", Kind = "Product", RobloxId = CLAN_REROLL_PRODUCT_ID, PriceText = "R$ 40", Accent = THEME.Gold },
			{ Id = "trait_reroll", Name = "Trait Reroll", Subtitle = "Reroll your current life traits.", Kind = "Product", RobloxId = TRAIT_REROLL_PRODUCT_ID, PriceText = "R$ 49", Accent = THEME.Blue },
		},
	},
	{
		Name = "Boosts & Recovery",
		Subtitle = "Temporary growth boosts and current-life help.",
		Accent = THEME.Blue,
		Items = {
			{ Id = "mastery_boost_15", Name = "Mastery Boost 15 Min", Subtitle = "Activates 2x mastery growth support and gives instant mastery if you have a technique.", Kind = "Product", RobloxId = MASTERY_BOOST_15_PRODUCT_ID, PriceText = "R$ 100", Accent = THEME.Purple },
			{ Id = "ce_boost_15", Name = "CE Boost 15 Min", Subtitle = "Activates 2x cursed energy growth support and gives instant cursed energy.", Kind = "Product", RobloxId = CE_BOOST_15_PRODUCT_ID, PriceText = "R$ 99", Accent = THEME.Blue },
			{ Id = "focused_training", Name = "Focused Training Session", Subtitle = "Gain cursed energy, technique mastery, and sharper growth.", Kind = "Product", RobloxId = FOCUSED_TRAINING_PRODUCT_ID, PriceText = "R$ 199", Accent = THEME.Blue },
			{ Id = "ct_evolution_accelerator", Name = "CT Evolution Accelerator", Subtitle = "Adds mastery and evolution pressure for your current cursed technique.", Kind = "Product", RobloxId = CT_EVOLUTION_ACCELERATOR_PRODUCT_ID, PriceText = "R$ TBD", Accent = THEME.Purple },
			{ Id = "black_flash_drill_pack", Name = "Black Flash Drill Pack", Subtitle = "Adds drill tokens, CE, and a small mastery push for Black Flash training.", Kind = "Product", RobloxId = BLACK_FLASH_DRILL_PACK_PRODUCT_ID, PriceText = "R$ TBD", Accent = THEME.Red },
			{ Id = "clan_war_mediation", Name = "Clan War Mediation", Subtitle = "Lowers active Clan War tension or saves a mediation credit if no war is active.", Kind = "Product", RobloxId = CLAN_WAR_MEDIATION_PRODUCT_ID, PriceText = "R$ TBD", Accent = THEME.Gold },
			{ Id = "cursed_tool_salvage_kit", Name = "Cursed Tool Salvage Kit", Subtitle = "Recover a Common-Epic cursed tool. Duplicates convert into money and CE.", Kind = "Product", RobloxId = CURSED_TOOL_SALVAGE_KIT_PRODUCT_ID, PriceText = "R$ TBD", Accent = THEME.Purple },
			{ Id = "combat_recovery_kit", Name = "Combat Recovery Kit", Subtitle = "Restore health and cursed energy after rough fights. Does not revive dead lives.", Kind = "Product", RobloxId = COMBAT_RECOVERY_KIT_PRODUCT_ID, PriceText = "R$ TBD", Accent = THEME.Green },
			{ Id = "recommendation_letter", Name = "Recommendation Letter", Subtitle = "Adds +1 teacher recommendation to your promotion record.", Kind = "Product", RobloxId = RECOMMENDATION_LETTER_PRODUCT_ID, PriceText = "R$ 129", Accent = THEME.Gold },
			{ Id = "emergency_treatment", Name = "Emergency Treatment", Subtitle = "Restores your current life to full health if you are alive.", Kind = "Product", RobloxId = EMERGENCY_TREATMENT_PRODUCT_ID, PriceText = "R$ 49", Accent = THEME.Green },
		},
	},
	{
		Name = "Money",
		Subtitle = "Cash packs for assets, dojo progress, and recovery.",
		Accent = THEME.Green,
		Items = {
			{ Id = "money_5000", Name = "$5,000 Money", Subtitle = "Small cash pack for early assets, healing, and recovery.", Kind = "Product", RobloxId = MONEY_5000_PRODUCT_ID, PriceText = "R$ 99", Accent = THEME.Green },
			{ Id = "money_25000", Name = "$25,000 Money", Subtitle = "Large money pack for assets and dojo progress.", Kind = "Product", RobloxId = MONEY_25000_PRODUCT_ID, PriceText = "R$ 299", Accent = THEME.Green },
			{ Id = "money_100000", Name = "$100,000 Money", Subtitle = "Huge cash pack for late-game upgrades and clan progress.", Kind = "Product", RobloxId = MONEY_100000_PRODUCT_ID, PriceText = "R$ 499", Accent = THEME.Green },
		},
	},
	{
		Name = "Dojo",
		Subtitle = "Clan and student support.",
		Accent = THEME.Orange,
		Items = {
			{ Id = "recruit_reroll", Name = "Student Reroll", Subtitle = "Reroll your Grand Dojo recruit board.", Kind = "Product", RobloxId = RECRUIT_REROLL_PRODUCT_ID, PriceText = "R$ 49", Accent = THEME.Orange },
			{ Id = "dojo_funding_pack", Name = "Dojo Funding Pack", Subtitle = "Funds your clan dojo with money, reputation, repairs, capacity support, and recruit help.", Kind = "Product", RobloxId = DOJO_FUNDING_PACK_PRODUCT_ID, PriceText = "R$ 199", Accent = THEME.Gold },
			{ Id = "extra_dojo_students", Name = "Extra Dojo Students", Subtitle = "Permanently increases Grand Dojo student capacity by +3.", Kind = "GamePass", RobloxId = EXTRA_DOJO_STUDENTS_GAMEPASS_ID, PriceText = "R$ 399", Accent = THEME.Purple },
		},
	},
	{
		Name = "Gamepasses",
		Subtitle = "Permanent account-wide upgrades.",
		Accent = THEME.Purple,
		Items = {
			{ Id = "vip_pass", Name = "VIP Sorcerer Pass", Subtitle = "Unlocks VIP perks, save slots support, and future VIP bonuses.", Kind = "GamePass", RobloxId = VIP_SORCERER_PASS_ID, PriceText = "R$ 750", Accent = THEME.Purple },
			{ Id = "extra_save_slots", Name = "Extra Save Slots", Subtitle = "Unlocks save slots 2 and 3 without needing the full VIP pass.", Kind = "GamePass", RobloxId = EXTRA_SAVE_SLOTS_GAMEPASS_ID, PriceText = "R$ 200", Accent = THEME.Blue },
			{ Id = "double_money", Name = "2x Money", Subtitle = "Permanent money multiplier for supported rewards and money products.", Kind = "GamePass", RobloxId = DOUBLE_MONEY_GAMEPASS_ID, PriceText = "R$ 250", Accent = THEME.Green },
			{ Id = "double_training", Name = "2x Progress", Subtitle = "Permanent progress multiplier for supported training and progression rewards.", Kind = "GamePass", RobloxId = DOUBLE_TRAINING_GAMEPASS_ID, PriceText = "R$ 250", Accent = THEME.Red },
			{ Id = "lucky_birth", Name = "Lucky Birth", Subtitle = "Improves future birth outcomes and gives new lives a small starting boost.", Kind = "GamePass", RobloxId = LUCKY_BIRTH_GAMEPASS_ID, PriceText = "R$ 399", Accent = THEME.Gold },
		},
	},
}

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------
local currentStats = nil
local currentSettings = {}
local trackedSounds = {}
local isOpen = false
local currentTab = "Home"
local buildingPage = false
local confirmingDeleteSlotId = nil
local lastTypedCode = ""
local lastCodeRedeemResult = nil
local sessionCodeGroupVerified = false

for key, value in pairs(DEFAULT_SETTINGS) do
	currentSettings[key] = value
end

----------------------------------------------------------------
-- BASIC UTIL
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenSettingsGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 630
gui.Enabled = false
gui.Parent = playerGui

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function addStroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.Parent = parent
	return s
end

local function addPadding(parent, left, right, top, bottom)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, left or 0)
	p.PaddingRight = UDim.new(0, right or 0)
	p.PaddingTop = UDim.new(0, top or 0)
	p.PaddingBottom = UDim.new(0, bottom or 0)
	p.Parent = parent
	return p
end

local function setGradient(parent, colorA, colorB, rotation)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("UIGradient") then child:Destroy() end
	end
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, colorA),
		ColorSequenceKeypoint.new(1, colorB),
	})
	g.Rotation = rotation or 90
	g.Parent = parent
	return g
end

local function clamp01(value)
	return math.clamp(tonumber(value) or 0, 0, 1)
end

local function bool(value)
	return value == true
end

local function getViewport()
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local BASE_WINDOW_WIDTH = 500
local BASE_WINDOW_HEIGHT = 610
local MOBILE_WINDOW_MARGIN_X = 28
local MOBILE_WINDOW_MARGIN_Y = 70

local function isMobile()
	return getViewport().X < 900
end

local function isSmallMobile()
	return getViewport().X < 540
end

local function tween(instance, duration, props)
	if currentSettings.ReducedMotion then
		for prop, value in pairs(props) do
			instance[prop] = value
		end
		return nil
	end
	local t = TweenService:Create(instance, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function wipeChildren(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function getMainGui()
	return playerGui:FindFirstChild(MAIN_GUI_NAME)
end

local function syncSettingsFromStats(stats)
	currentStats = stats
	if typeof(stats) ~= "table" then return end

	if stats.CodeGroupVerified == true then
		sessionCodeGroupVerified = true
	end
	if typeof(stats.Codes) == "table" and stats.Codes.GroupVerified == true then
		sessionCodeGroupVerified = true
	end

	if typeof(stats.Settings) ~= "table" then return end

	for key, defaultValue in pairs(DEFAULT_SETTINGS) do
		local loadedValue = stats.Settings[key]
		if loadedValue ~= nil then
			if typeof(defaultValue) == "number" then
				currentSettings[key] = clamp01(loadedValue)
			elseif typeof(defaultValue) == "boolean" then
				currentSettings[key] = loadedValue == true
			end
		end
	end
end

local function saveSetting(key, value)
	if DEFAULT_SETTINGS[key] == nil then return end
	if typeof(DEFAULT_SETTINGS[key]) == "number" then
		value = clamp01(value)
	elseif typeof(DEFAULT_SETTINGS[key]) == "boolean" then
		value = bool(value)
	else
		return
	end
	currentSettings[key] = value
	updateSettingsEvent:FireServer(key, value)
end

local function hasClaimedStarterPack()
	if typeof(currentStats) ~= "table" then return false end
	if typeof(currentStats.Purchases) ~= "table" then return false end
	return currentStats.Purchases.StarterSorcererPackClaimed == true
end

----------------------------------------------------------------
-- SOUND / READABILITY
----------------------------------------------------------------
local function isMusicSound(sound)
	local name = string.lower(sound.Name or "")
	if sound.Looped then return true end
	if string.find(name, "music") then return true end
	if string.find(name, "bgm") then return true end
	if string.find(name, "theme") then return true end
	if string.find(name, "ost") then return true end
	if string.find(name, "song") then return true end
	return false
end

local function rememberSound(sound)
	if not sound:IsA("Sound") then return end
	if trackedSounds[sound] then return end
	local baseVolume = sound:GetAttribute("BitKaisenBaseVolume")
	if typeof(baseVolume) ~= "number" then
		baseVolume = sound.Volume
		sound:SetAttribute("BitKaisenBaseVolume", baseVolume)
	end
	trackedSounds[sound] = {
		BaseVolume = baseVolume,
		IsMusic = isMusicSound(sound),
	}
end

local function scanSounds()
	for _, container in ipairs({ SoundService, workspace, playerGui }) do
		for _, descendant in ipairs(container:GetDescendants()) do
			if descendant:IsA("Sound") then
				rememberSound(descendant)
			end
		end
	end
end

local function applyAudioSettings()
	for sound, data in pairs(trackedSounds) do
		if not sound or not sound.Parent then
			trackedSounds[sound] = nil
		else
			local baseVolume = data.BaseVolume or sound:GetAttribute("BitKaisenBaseVolume") or sound.Volume
			if data.IsMusic then
				sound.Volume = currentSettings.MuteMusic and 0 or (baseVolume * clamp01(currentSettings.MusicVolume))
			else
				sound.Volume = currentSettings.MuteSFX and 0 or (baseVolume * clamp01(currentSettings.SFXVolume))
			end
		end
	end
end

local function applyReadabilityMode()
	local mainGui = getMainGui()
	if not mainGui then return end
	local logText = mainGui:FindFirstChild("LogText", true)
	if logText and logText:IsA("TextLabel") then
		if currentSettings.HighContrastText then
			logText.TextColor3 = Color3.fromRGB(255, 255, 255)
			logText.TextSize = 19
			logText.Font = Enum.Font.GothamBlack
		else
			logText.TextColor3 = THEME.Text
			logText.TextSize = 17
			logText.Font = Enum.Font.GothamMedium
		end
	end
end

local clientSFXFolder = SoundService:FindFirstChild("BitKaisenClientSFX")
if clientSFXFolder then clientSFXFolder:Destroy() end
clientSFXFolder = Instance.new("Folder")
clientSFXFolder.Name = "BitKaisenClientSFX"
clientSFXFolder.Parent = SoundService

local function createClientSound(name, soundId, volume)
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = soundId or ""
	sound.Volume = volume or 0.35
	sound.Looped = false
	sound.Parent = clientSFXFolder
	sound:SetAttribute("BitKaisenBaseVolume", sound.Volume)
	rememberSound(sound)
	return sound
end

local clientSounds = {
	Click = createClientSound("Click", "", 0.35),
	Hover = createClientSound("Hover", "", 0.2),
	Open = createClientSound("Open", "", 0.35),
	Close = createClientSound("Close", "", 0.35),
	Tick = createClientSound("Tick", "", 0.25),
	Success = createClientSound("Success", "", 0.45),
	Error = createClientSound("Error", "", 0.45),
}

local function playSFX(name)
	if currentSettings.MuteSFX then return end
	local sound = clientSounds[name]
	if not sound or sound.SoundId == "" then return end
	sound.Volume = (sound:GetAttribute("BitKaisenBaseVolume") or 0.35) * clamp01(currentSettings.SFXVolume)
	sound.TimePosition = 0
	sound:Play()
end

local function applyAllSettings()
	scanSounds()
	applyAudioSettings()
	applyReadabilityMode()
end

task.spawn(function()
	while gui and gui.Parent do
		scanSounds()
		applyAudioSettings()
		task.wait(2)
	end
end)

----------------------------------------------------------------
-- WINDOW ROOT
----------------------------------------------------------------
local overlay = Instance.new("Frame")
overlay.Name = "SettingsOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.35
overlay.ZIndex = 630
overlay.Parent = gui

local window = Instance.new("Frame")
window.Name = "SettingsWindow"
window.Size = UDim2.fromOffset(BASE_WINDOW_WIDTH, BASE_WINDOW_HEIGHT)
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.new(0.5, 0, 0.5, 0)
window.BackgroundColor3 = THEME.Bg2
window.BorderSizePixel = 0
window.ZIndex = 631
window.Parent = overlay
addCorner(window, 18)
addStroke(window, THEME.RedSoft, 1, 0.08)
setGradient(window, THEME.Panel, THEME.Bg, 90)

local windowScale = Instance.new("UIScale")
windowScale.Name = "ResponsiveScale"
windowScale.Scale = 1
windowScale.Parent = window

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 36, 0, 36)
closeButton.Position = UDim2.new(1, -48, 0, 14)
closeButton.BackgroundColor3 = THEME.Panel3
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = THEME.Bad
closeButton.TextSize = 16
closeButton.Font = Enum.Font.GothamBlack
closeButton.AutoButtonColor = false
closeButton.ZIndex = 635
closeButton.Parent = window
addCorner(closeButton, 10)
addStroke(closeButton, THEME.Stroke, 1, 0.2)

----------------------------------------------------------------
-- TOP SECTION
----------------------------------------------------------------
local topSection = Instance.new("Frame")
topSection.Name = "TopSection"
topSection.Position = UDim2.new(0, 18, 0, 16)
topSection.Size = UDim2.new(1, -76, 0, 92)
topSection.BackgroundColor3 = THEME.Panel2
topSection.BorderSizePixel = 0
topSection.ZIndex = 632
topSection.Parent = window
addCorner(topSection, 16)
addStroke(topSection, THEME.StrokeSoft, 1, 0)
setGradient(topSection, Color3.fromRGB(25, 20, 28), Color3.fromRGB(17, 17, 24), 0)

local topAccent = Instance.new("Frame")
topAccent.Name = "TopAccent"
topAccent.Size = UDim2.new(0, 4, 1, -24)
topAccent.Position = UDim2.new(0, 14, 0, 12)
topAccent.BackgroundColor3 = THEME.Red
topAccent.BorderSizePixel = 0
topAccent.ZIndex = 633
topAccent.Parent = topSection
addCorner(topAccent, 999)

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Position = UDim2.new(0, 28, 0, 13)
titleLabel.Size = UDim2.new(1, -44, 0, 28)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = THEME.Text
titleLabel.TextSize = 22
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "MENU"
titleLabel.ZIndex = 633
titleLabel.Parent = topSection

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Name = "Subtitle"
subtitleLabel.Position = UDim2.new(0, 29, 0, 43)
subtitleLabel.Size = UDim2.new(1, -44, 0, 36)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.TextColor3 = THEME.SubText
subtitleLabel.TextSize = 12
subtitleLabel.Font = Enum.Font.GothamMedium
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subtitleLabel.TextYAlignment = Enum.TextYAlignment.Top
subtitleLabel.TextWrapped = true
subtitleLabel.Text = "Audio, gameplay options, save slots, codes, achievements, and purchases."
subtitleLabel.ZIndex = 633
subtitleLabel.Parent = topSection

----------------------------------------------------------------
-- TABS
----------------------------------------------------------------
local tabHolder = Instance.new("Frame")
tabHolder.Name = "TabHolder"
tabHolder.Position = UDim2.new(0, 18, 0, 122)
tabHolder.Size = UDim2.new(1, -36, 0, 38)
tabHolder.BackgroundTransparency = 1
tabHolder.ZIndex = 632
tabHolder.Parent = window

local tabLayout = Instance.new("UIGridLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.FillDirectionMaxCells = 7
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.CellPadding = UDim2.new(0, 7, 0, 0)
tabLayout.CellSize = UDim2.new(1 / 7, -6, 1, 0)
tabLayout.Parent = tabHolder

local tabs = {}
local TAB_ORDER = {
	{ Id = "Home", Text = "HOME" },
	{ Id = "Audio", Text = "AUDIO" },
	{ Id = "Gameplay", Text = "GAMEPLAY" },
	{ Id = "Saves", Text = "SAVES" },
	{ Id = "Codes", Text = "CODES" },
	{ Id = "Achievements", Text = "ACHIEVE" },
	{ Id = "Shop", Text = "SHOP" },
}

local function makeTab(tabInfo, order)
	local button = Instance.new("TextButton")
	button.Name = tabInfo.Id .. "Tab"
	button.Size = UDim2.new(1 / #TAB_ORDER, -6, 1, 0)
	button.BackgroundColor3 = THEME.Panel2
	button.BorderSizePixel = 0
	button.TextColor3 = THEME.SubText
	button.TextSize = 11
	button.Font = Enum.Font.GothamBlack
	button.Text = tabInfo.Text
	button.AutoButtonColor = false
	button.LayoutOrder = order
	button.ZIndex = 633
	button.Parent = tabHolder
	addCorner(button, 9)
	addStroke(button, THEME.StrokeSoft, 1, 0.15)
	tabs[tabInfo.Id] = button
end

for index, info in ipairs(TAB_ORDER) do
	makeTab(info, index)
end

----------------------------------------------------------------
-- CONTENT
----------------------------------------------------------------
local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.Position = UDim2.new(0, 18, 0, 174)
content.Size = UDim2.new(1, -36, 1, -192)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.ScrollBarImageColor3 = THEME.RedSoft
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.ScrollingDirection = Enum.ScrollingDirection.Y
content.ScrollingEnabled = true
content.Active = true
content.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
content.ZIndex = 632
content.Parent = window

addPadding(content, 0, 4, 0, 12)

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 10)
contentLayout.Parent = content

local function updateContentCanvas()
	content.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 44)
end

contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateContentCanvas)

----------------------------------------------------------------
-- RESPONSIVE
----------------------------------------------------------------
local function applyResponsiveLayout()
	local viewport = getViewport()
	local mobile = isMobile()
	local small = isSmallMobile()
	local scaleX = (viewport.X - MOBILE_WINDOW_MARGIN_X) / BASE_WINDOW_WIDTH
	local scaleY = (viewport.Y - MOBILE_WINDOW_MARGIN_Y) / BASE_WINDOW_HEIGHT

	window.Size = UDim2.fromOffset(BASE_WINDOW_WIDTH, BASE_WINDOW_HEIGHT)
	windowScale.Scale = math.clamp(math.min(scaleX, scaleY, 1), 0.34, 1)

	if small then
		window.Position = UDim2.new(0.5, 0, 0.5, 0)
		topSection.Position = UDim2.new(0, 10, 0, 12)
		topSection.Size = UDim2.new(1, -58, 0, 82)
		titleLabel.TextSize = 18
		subtitleLabel.TextSize = 10

		closeButton.Size = UDim2.new(0, 32, 0, 32)
		closeButton.Position = UDim2.new(1, -40, 0, 14)

		tabHolder.Position = UDim2.new(0, 10, 0, 104)
		tabHolder.Size = UDim2.new(1, -20, 0, 74)
		tabLayout.FillDirectionMaxCells = 4
		tabLayout.CellPadding = UDim2.new(0, 6, 0, 6)
		tabLayout.CellSize = UDim2.new(0.25, -5, 0, 32)

		for _, button in pairs(tabs) do
			button.Size = UDim2.new(1, 0, 1, 0)
			button.TextSize = viewport.X < 430 and 8 or 9
			button.TextTruncate = Enum.TextTruncate.AtEnd
		end

		content.Position = UDim2.new(0, 10, 0, 188)
		content.Size = UDim2.new(1, -20, 1, -202)
	elseif mobile then
		window.Position = UDim2.new(0.5, 0, 0.5, 0)
		topSection.Position = UDim2.new(0, 14, 0, 14)
		topSection.Size = UDim2.new(1, -68, 0, 86)
		titleLabel.TextSize = 20
		subtitleLabel.TextSize = 11

		closeButton.Size = UDim2.new(0, 34, 0, 34)
		closeButton.Position = UDim2.new(1, -44, 0, 14)

		tabHolder.Position = UDim2.new(0, 14, 0, 112)
		tabHolder.Size = UDim2.new(1, -28, 0, 74)
		tabLayout.FillDirectionMaxCells = 4
		tabLayout.CellPadding = UDim2.new(0, 7, 0, 6)
		tabLayout.CellSize = UDim2.new(0.25, -6, 0, 32)

		for _, button in pairs(tabs) do
			button.Size = UDim2.new(1, 0, 1, 0)
			button.TextSize = 10
			button.TextTruncate = Enum.TextTruncate.AtEnd
		end

		content.Position = UDim2.new(0, 14, 0, 196)
		content.Size = UDim2.new(1, -28, 1, -212)
	else
		window.Position = UDim2.new(0.5, 0, 0.5, 0)
		topSection.Position = UDim2.new(0, 18, 0, 16)
		topSection.Size = UDim2.new(1, -76, 0, 92)
		titleLabel.TextSize = 22
		subtitleLabel.TextSize = 12

		closeButton.Size = UDim2.new(0, 36, 0, 36)
		closeButton.Position = UDim2.new(1, -48, 0, 14)

		tabHolder.Position = UDim2.new(0, 18, 0, 122)
		tabHolder.Size = UDim2.new(1, -36, 0, 38)
		tabLayout.FillDirectionMaxCells = #TAB_ORDER
		tabLayout.CellPadding = UDim2.new(0, 7, 0, 0)
		tabLayout.CellSize = UDim2.new(1 / #TAB_ORDER, -6, 1, 0)

		for _, button in pairs(tabs) do
			button.Size = UDim2.new(1, 0, 1, 0)
			button.TextSize = 11
			button.TextTruncate = Enum.TextTruncate.AtEnd
		end

		content.Position = UDim2.new(0, 18, 0, 174)
		content.Size = UDim2.new(1, -36, 1, -192)
	end
end

----------------------------------------------------------------
-- CONTENT HELPERS
----------------------------------------------------------------
local function setTabVisuals()
	for id, button in pairs(tabs) do
		if id == currentTab then
			button.BackgroundColor3 = THEME.RedDark
			button.TextColor3 = THEME.Text
		else
			button.BackgroundColor3 = THEME.Panel2
			button.TextColor3 = THEME.SubText
		end
	end
end

local function setHeader(title, subtitle)
	titleLabel.Text = tostring(title or "Menu")
	subtitleLabel.Text = tostring(subtitle or "")
end

local function makeCard(height)
	local card = Instance.new("Frame")
	card.Name = "Card"
	card.Size = UDim2.new(1, -4, 0, height or 92)
	card.BackgroundColor3 = THEME.Card
	card.BorderSizePixel = 0
	card.ZIndex = 633
	card.Parent = content
	addCorner(card, 14)
	addStroke(card, THEME.StrokeSoft, 1, 0.05)
	return card
end

local function makeSectionLabel(text)
	local label = Instance.new("TextLabel")
	label.Name = "SectionLabel"
	label.Size = UDim2.new(1, -4, 0, 24)
	label.BackgroundTransparency = 1
	label.TextColor3 = THEME.SubText
	label.TextSize = 12
	label.Font = Enum.Font.GothamBlack
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = string.upper(tostring(text or "Section"))
	label.ZIndex = 633
	label.Parent = content
	return label
end

local function makeNotice(text, height, accent)
	local card = makeCard(height or 82)
	card.BackgroundColor3 = THEME.Panel2

	local stripe = Instance.new("Frame")
	stripe.Size = UDim2.new(0, 4, 1, -22)
	stripe.Position = UDim2.new(0, 12, 0, 11)
	stripe.BackgroundColor3 = accent or THEME.Red
	stripe.BorderSizePixel = 0
	stripe.ZIndex = 634
	stripe.Parent = card
	addCorner(stripe, 999)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -36, 1, -22)
	label.Position = UDim2.new(0, 28, 0, 11)
	label.BackgroundTransparency = 1
	label.TextColor3 = THEME.SubText
	label.TextSize = 12
	label.Font = Enum.Font.GothamMedium
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Text = tostring(text or "")
	label.ZIndex = 634
	label.Parent = card

	return card
end

local function makeSmallButton(parent, text, color, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 100, 0, 32)
	button.BackgroundColor3 = color or THEME.RedDark
	button.BorderSizePixel = 0
	button.TextColor3 = THEME.Text
	button.TextSize = 11
	button.Font = Enum.Font.GothamBlack
	button.Text = tostring(text or "OK")
	button.AutoButtonColor = false
	button.ZIndex = 636
	button.Parent = parent
	addCorner(button, 9)
	addStroke(button, THEME.Stroke, 1, 0.2)

	button.MouseEnter:Connect(function()
		tween(button, 0.12, { BackgroundColor3 = THEME.Panel3 })
	end)
	button.MouseLeave:Connect(function()
		tween(button, 0.12, { BackgroundColor3 = color or THEME.RedDark })
	end)
	button.MouseButton1Click:Connect(function()
		playSFX("Click")
		if callback then callback() end
	end)

	return button
end

local function makeActionRow(iconText, titleText, descText, accent, buttonText, callback)
	local card = makeCard(90)

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 42, 0, 42)
	icon.Position = UDim2.new(0, 14, 0.5, -21)
	icon.BackgroundColor3 = THEME.Panel3
	icon.BorderSizePixel = 0
	icon.TextColor3 = accent or THEME.Red
	icon.TextSize = 18
	icon.Font = Enum.Font.GothamBlack
	icon.Text = tostring(iconText or "•")
	icon.ZIndex = 634
	icon.Parent = card
	addCorner(icon, 12)
	addStroke(icon, THEME.StrokeSoft, 1, 0)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -186, 0, 22)
	title.Position = UDim2.new(0, 68, 0, 18)
	title.BackgroundTransparency = 1
	title.TextColor3 = THEME.Text
	title.TextSize = 14
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Text = tostring(titleText or "Row")
	title.ZIndex = 634
	title.Parent = card

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -186, 0, 36)
	desc.Position = UDim2.new(0, 68, 0, 42)
	desc.BackgroundTransparency = 1
	desc.TextColor3 = THEME.SubText
	desc.TextSize = 11
	desc.Font = Enum.Font.GothamMedium
	desc.TextWrapped = true
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.Text = tostring(descText or "")
	desc.ZIndex = 634
	desc.Parent = card

	local button = makeSmallButton(card, buttonText or "OPEN", accent or THEME.RedDark, callback)
	button.Position = UDim2.new(1, -116, 0.5, -16)

	return card
end

local function makeToggleRow(titleText, descText, key)
	local card = makeCard(84)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -150, 0, 22)
	title.Position = UDim2.new(0, 16, 0, 15)
	title.BackgroundTransparency = 1
	title.TextColor3 = THEME.Text
	title.TextSize = 14
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = tostring(titleText)
	title.ZIndex = 634
	title.Parent = card

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -150, 0, 34)
	desc.Position = UDim2.new(0, 16, 0, 38)
	desc.BackgroundTransparency = 1
	desc.TextColor3 = THEME.SubText
	desc.TextSize = 11
	desc.Font = Enum.Font.GothamMedium
	desc.TextWrapped = true
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.Text = tostring(descText)
	desc.ZIndex = 634
	desc.Parent = card

	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(0, 92, 0, 34)
	toggle.Position = UDim2.new(1, -108, 0.5, -17)
	toggle.BorderSizePixel = 0
	toggle.TextSize = 12
	toggle.Font = Enum.Font.GothamBlack
	toggle.AutoButtonColor = false
	toggle.ZIndex = 635
	toggle.Parent = card
	addCorner(toggle, 999)
	addStroke(toggle, THEME.Stroke, 1, 0.2)

	local function refreshToggle()
		local enabled = currentSettings[key] == true
		toggle.Text = enabled and "ON" or "OFF"
		toggle.TextColor3 = enabled and THEME.Text or THEME.SubText
		toggle.BackgroundColor3 = enabled and THEME.RedDark or THEME.Panel3
	end

	toggle.MouseButton1Click:Connect(function()
		saveSetting(key, not (currentSettings[key] == true))
		playSFX("Tick")
		refreshToggle()
		applyAllSettings()
	end)

	refreshToggle()
	return card
end

local function makeVolumeRow(titleText, descText, key)
	local card = makeCard(100)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -150, 0, 22)
	title.Position = UDim2.new(0, 16, 0, 14)
	title.BackgroundTransparency = 1
	title.TextColor3 = THEME.Text
	title.TextSize = 14
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = tostring(titleText)
	title.ZIndex = 634
	title.Parent = card

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -150, 0, 30)
	desc.Position = UDim2.new(0, 16, 0, 37)
	desc.BackgroundTransparency = 1
	desc.TextColor3 = THEME.SubText
	desc.TextSize = 11
	desc.Font = Enum.Font.GothamMedium
	desc.TextWrapped = true
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.Text = tostring(descText)
	desc.ZIndex = 634
	desc.Parent = card

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, -170, 0, 8)
	barBg.Position = UDim2.new(0, 16, 1, -20)
	barBg.BackgroundColor3 = THEME.Panel3
	barBg.BorderSizePixel = 0
	barBg.ZIndex = 634
	barBg.Parent = card
	addCorner(barBg, 999)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(clamp01(currentSettings[key]), 0, 1, 0)
	fill.BackgroundColor3 = THEME.Red
	fill.BorderSizePixel = 0
	fill.ZIndex = 635
	fill.Parent = barBg
	addCorner(fill, 999)

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0, 48, 0, 22)
	valueLabel.Position = UDim2.new(1, -64, 0, 16)
	valueLabel.BackgroundTransparency = 1
	valueLabel.TextColor3 = THEME.Gold
	valueLabel.TextSize = 12
	valueLabel.Font = Enum.Font.GothamBlack
	valueLabel.Text = tostring(math.floor(clamp01(currentSettings[key]) * 100 + 0.5)) .. "%"
	valueLabel.ZIndex = 635
	valueLabel.Parent = card

	local minus = makeSmallButton(card, "-", THEME.Panel3, function()
		saveSetting(key, clamp01((currentSettings[key] or 0) - 0.1))
		valueLabel.Text = tostring(math.floor(clamp01(currentSettings[key]) * 100 + 0.5)) .. "%"
		tween(fill, 0.08, { Size = UDim2.new(clamp01(currentSettings[key]), 0, 1, 0) })
		applyAllSettings()
	end)
	minus.Size = UDim2.new(0, 34, 0, 30)
	minus.Position = UDim2.new(1, -108, 1, -38)

	local plus = makeSmallButton(card, "+", THEME.Panel3, function()
		saveSetting(key, clamp01((currentSettings[key] or 0) + 0.1))
		valueLabel.Text = tostring(math.floor(clamp01(currentSettings[key]) * 100 + 0.5)) .. "%"
		tween(fill, 0.08, { Size = UDim2.new(clamp01(currentSettings[key]), 0, 1, 0) })
		applyAllSettings()
	end)
	plus.Size = UDim2.new(0, 34, 0, 30)
	plus.Position = UDim2.new(1, -68, 1, -38)

	return card
end

----------------------------------------------------------------
-- SAFE SERVER CALLS
----------------------------------------------------------------
local function getSlotsSafe()
	local ok, result = pcall(function()
		return getSaveSlots:InvokeServer()
	end)
	if ok and typeof(result) == "table" then return result end
	return { HasVIP = false, SelectedSlot = 1, SlotCount = 3, Slots = {} }
end

local function readGroupGateFlags(result)
	if typeof(result) ~= "table" then return false, false end
	local joined =
		result.GroupJoined == true
		or result.IsInGroup == true
		or result.GroupMember == true
		or result.JoinedGroup == true
	local verified =
		result.CodeGroupVerified == true
		or result.GroupVerified == true
		or result.Verified == true
		or result.PermanentVerified == true
		or joined
	return joined, verified
end

local function getCodeGateSafe()
	local ok, result = pcall(function()
		return getCodeGate:InvokeServer(true)
	end)
	if ok and typeof(result) == "table" then
		local joined, verified = readGroupGateFlags(result)
		if verified then sessionCodeGroupVerified = true end
		result.GroupJoined = joined or sessionCodeGroupVerified
		result.CodeGroupVerified = verified or sessionCodeGroupVerified
		result.CanRedeem = result.CanRedeem == true or sessionCodeGroupVerified or verified or joined
		return result
	end
	return {
		GroupJoined = sessionCodeGroupVerified,
		CodeGroupVerified = sessionCodeGroupVerified,
		GroupRequired = true,
		CanRedeem = sessionCodeGroupVerified,
		Message = sessionCodeGroupVerified and "Code redemption is unlocked." or "Code redemption is not available right now.",
		RedeemedCount = 0,
	}
end

----------------------------------------------------------------
-- PAGE BUILDING
----------------------------------------------------------------
local function rebuildPage(builder, tabId, resetScroll)
	if buildingPage then return end
	buildingPage = true

	local oldTab = currentTab
	local oldCanvasPosition = content.CanvasPosition
	currentTab = tabId or currentTab

	setTabVisuals()
	wipeChildren(content)
	builder()
	updateContentCanvas()

	if resetScroll == true or oldTab ~= currentTab then
		content.CanvasPosition = Vector2.new(0, 0)
	else
		task.defer(function()
			if content and content.Parent then
				content.CanvasPosition = oldCanvasPosition
			end
		end)
	end

	buildingPage = false
end

local buildHomePage
local buildAudioPage
local buildGameplayPage
local buildSavesPage
local buildCodesPage
local buildAchievementsPage
local buildShopPage

buildHomePage = function()
	setHeader("Menu", "Audio, gameplay options, save slots, codes, and purchases.")

	makeSectionLabel("Quick Access")
	makeActionRow("♪", "Audio", "Control music and sound effects.", THEME.Red, "OPEN", function()
		rebuildPage(buildAudioPage, "Audio")
	end)
	makeActionRow("⚙", "Gameplay", "Quality-of-life toggles and display behavior.", THEME.Blue, "OPEN", function()
		rebuildPage(buildGameplayPage, "Gameplay")
	end)
	makeActionRow("◆", "Save Slots", "Manage different lives and bloodlines.", THEME.Gold, "OPEN", function()
		confirmingDeleteSlotId = nil
		rebuildPage(buildSavesPage, "Saves")
	end)
	makeActionRow("#", "Codes", "Redeem update codes after joining the group.", THEME.Green, "OPEN", function()
		rebuildPage(buildCodesPage, "Codes")
	end)
	makeActionRow("★", "Achievements", "Track milestones and claim rewards.", THEME.Gold, "OPEN", function()
		rebuildPage(buildAchievementsPage, "Achievements")
	end)
	makeActionRow("$", "Shop", "Gamepasses and developer products.", THEME.Purple, "OPEN", function()
		rebuildPage(buildShopPage, "Shop")
	end)
end

buildAudioPage = function()
	setHeader("Audio", "Tune the game without digging through Roblox settings.")

	makeSectionLabel("Volume")
	makeVolumeRow("Music Volume", "Controls background music and looped theme sounds.", "MusicVolume")
	makeVolumeRow("SFX Volume", "Controls click sounds, popups, and other short effects.", "SFXVolume")

	makeSectionLabel("Mute")
	makeToggleRow("Mute Music", "Turns off background music only.", "MuteMusic")
	makeToggleRow("Mute SFX", "Turns off button and event sound effects.", "MuteSFX")
end

buildGameplayPage = function()
	setHeader("Gameplay", "Control readability, motion, and general feel.")

	makeSectionLabel("Text / Motion")
	makeToggleRow("Fast Text", "Speeds up supported text and log behavior.", "FastText")
	makeToggleRow("Reduced Motion", "Cuts down on animations where supported.", "ReducedMotion")
	makeToggleRow("Screen Shake", "Allows screen shake during supported events.", "ScreenShake")
	makeToggleRow("Skip Combat Skill Checks", "Auto-resolves combat attack and dodge checks to speed up fights.", "SkipCombatSkillChecks")

	makeSectionLabel("Display")
	makeToggleRow("High Contrast Text", "Makes life log text larger and easier to read.", "HighContrastText")
end

local function makeSlotCard(slot, selectedSlot)
	local slotId = tonumber(slot and slot.SlotId) or 1
	local exists = slot and slot.Exists == true
	local locked = slot and slot.Locked == true
	local isSelected = selectedSlot == slotId

	local card = makeCard(locked and 94 or 118)
	card.BackgroundColor3 = isSelected and THEME.Card2 or THEME.Card
	addStroke(card, isSelected and THEME.Gold or THEME.StrokeSoft, isSelected and 2 or 1, 0)

	local accent = locked and THEME.Gold or (isSelected and THEME.Green or THEME.Red)

	local stripe = Instance.new("Frame")
	stripe.Size = UDim2.new(0, 4, 1, -24)
	stripe.Position = UDim2.new(0, 12, 0, 12)
	stripe.BackgroundColor3 = accent
	stripe.BorderSizePixel = 0
	stripe.ZIndex = 634
	stripe.Parent = card
	addCorner(stripe, 999)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -160, 0, 24)
	title.Position = UDim2.new(0, 28, 0, 13)
	title.BackgroundTransparency = 1
	title.TextColor3 = THEME.Text
	title.TextSize = 15
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Slot " .. tostring(slotId) .. (isSelected and "  [ACTIVE]" or "")
	title.ZIndex = 634
	title.Parent = card

	local statusText = "Empty Slot"
	if locked then
		statusText = "Locked — VIP or Extra Save Slots required."
	elseif exists then
		statusText = tostring(slot.Name or "Unknown") .. " | Age " .. tostring(slot.Age or 0) .. " | " .. tostring(slot.Grade or "Unknown")
	end

	local status = Instance.new("TextLabel")
	status.Size = UDim2.new(1, -160, 0, 22)
	status.Position = UDim2.new(0, 28, 0, 39)
	status.BackgroundTransparency = 1
	status.TextColor3 = locked and THEME.Gold or THEME.SubText
	status.TextSize = 11
	status.Font = Enum.Font.GothamBold
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.TextTruncate = Enum.TextTruncate.AtEnd
	status.Text = statusText
	status.ZIndex = 634
	status.Parent = card

	if exists and not locked then
		local extra = Instance.new("TextLabel")
		extra.Size = UDim2.new(1, -160, 0, 22)
		extra.Position = UDim2.new(0, 28, 0, 62)
		extra.BackgroundTransparency = 1
		extra.TextColor3 = THEME.Muted
		extra.TextSize = 10
		extra.Font = Enum.Font.GothamMedium
		extra.TextXAlignment = Enum.TextXAlignment.Left
		extra.TextTruncate = Enum.TextTruncate.AtEnd
		extra.Text = tostring(slot.CursedTechnique or "None") .. " | Gen " .. tostring(slot.Generation or 1)
		extra.ZIndex = 634
		extra.Parent = card
	end

	local actionButton = makeSmallButton(card, locked and "UNLOCK" or (exists and "LOAD" or "CREATE"), locked and THEME.Gold or THEME.RedDark, function()
		if locked then
			promptRobuxItem("GamePass", EXTRA_SAVE_SLOTS_GAMEPASS_ID)
			return
		end
		confirmingDeleteSlotId = nil
		if exists then
			selectSaveSlot:FireServer(slotId)
		else
			createSaveSlot:FireServer(slotId)
		end
		task.delay(0.45, function()
			if isOpen and currentTab == "Saves" then
				rebuildPage(buildSavesPage, "Saves")
			end
		end)
	end)
	actionButton.Position = UDim2.new(1, -116, 0, 18)

	if exists and not locked then
		local deleteButton = makeSmallButton(card, confirmingDeleteSlotId == slotId and "CONFIRM" or "DELETE", THEME.Panel3, function()
			if confirmingDeleteSlotId == slotId then
				deleteSaveSlot:FireServer(slotId)
				confirmingDeleteSlotId = nil
				task.delay(0.45, function()
					if isOpen and currentTab == "Saves" then
						rebuildPage(buildSavesPage, "Saves")
					end
				end)
			else
				confirmingDeleteSlotId = slotId
				rebuildPage(buildSavesPage, "Saves")
			end
		end)
		deleteButton.Position = UDim2.new(1, -116, 0, 58)
		deleteButton.TextColor3 = confirmingDeleteSlotId == slotId and THEME.Bad or THEME.SubText
	end
end

buildSavesPage = function()
	setHeader("Save Slots", "Manage separate lives without mixing logs.")

	makeNotice("Loading or creating a slot resets the current life log view so old dialogue does not bleed into the new life.", 70, THEME.Gold)

	local payload = getSlotsSafe()
	local selectedSlot = tonumber(payload.SelectedSlot) or 1
	local slotCount = tonumber(payload.SlotCount) or 3
	local hasVIP = payload.HasVIP == true

	if hasVIP then
		makeNotice("VIP active. Slots 1-3 are unlocked.", 60, THEME.Green)
	else
		makeNotice("Free players can use Slot 1. VIP Sorcerer Pass or Extra Save Slots unlocks slots 2 and 3.", 74, THEME.Gold)
	end

	makeSectionLabel("Slots")

	for slotId = 1, slotCount do
		local slot = payload.Slots and payload.Slots[slotId]
		if typeof(slot) ~= "table" then
			slot = {
				SlotId = slotId,
				Exists = false,
				Locked = slotId > 1 and not hasVIP,
				Name = "Empty Slot",
				Age = 0,
				Grade = "None",
				Generation = 1,
				CursedTechnique = "None",
			}
		end
		makeSlotCard(slot, selectedSlot)
	end
end

buildCodesPage = function()
	setHeader("Codes", "Redeem update rewards after joining the group.")

	local gate = getCodeGateSafe()
	local groupJoined = gate.GroupJoined == true
	local verified = gate.CodeGroupVerified == true or sessionCodeGroupVerified == true
	local canRedeem = gate.CanRedeem == true or verified == true or groupJoined == true

	makeNotice("Codes are not listed in-game anymore. Join the Roblox group once, then check official community announcements for active codes.", 86, THEME.Gold)

	makeSectionLabel("Access")
	if canRedeem then
		makeNotice("Group Status: Verified\nCode redemption is unlocked. You should not need to verify again.", 72, THEME.Green)
	else
		makeNotice("Group Status: Not joined\nJoin the Roblox group to unlock code redemption.", 72, THEME.Bad)
	end

	makeSectionLabel("Redeem")

	local inputCard = makeCard(150)

	local input = Instance.new("TextBox")
	input.Size = UDim2.new(1, -32, 0, 42)
	input.Position = UDim2.new(0, 16, 0, 16)
	input.BackgroundColor3 = THEME.Panel3
	input.BorderSizePixel = 0
	input.TextColor3 = THEME.Text
	input.PlaceholderColor3 = THEME.Muted
	input.TextSize = 15
	input.Font = Enum.Font.GothamBlack
	input.TextXAlignment = Enum.TextXAlignment.Left
	input.PlaceholderText = canRedeem and "Enter code" or "Join group first"
	input.ClearTextOnFocus = false
	input.Text = lastTypedCode
	input.ZIndex = 634
	input.Parent = inputCard
	addCorner(input, 10)
	addStroke(input, THEME.Stroke, 1, 0.1)
	addPadding(input, 12, 12, 0, 0)

	local status = Instance.new("TextLabel")
	status.Size = UDim2.new(1, -148, 0, 48)
	status.Position = UDim2.new(0, 16, 0, 72)
	status.BackgroundTransparency = 1
	status.TextColor3 = THEME.SubText
	status.TextSize = 11
	status.Font = Enum.Font.GothamMedium
	status.TextWrapped = true
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.TextYAlignment = Enum.TextYAlignment.Top
	status.Text = lastCodeRedeemResult and tostring(lastCodeRedeemResult) or "Codes are found through official community announcements."
	status.ZIndex = 634
	status.Parent = inputCard

	local function handleRedeem()
		lastTypedCode = tostring(input.Text or "")

		if not canRedeem then
			lastCodeRedeemResult = "Join the Roblox group first. After joining, reopen this tab."
			rebuildPage(buildCodesPage, "Codes")
			return
		end

		if lastTypedCode == "" then
			lastCodeRedeemResult = "Enter a code first."
			rebuildPage(buildCodesPage, "Codes")
			return
		end

		local ok, result = pcall(function()
			return redeemCode:InvokeServer(lastTypedCode, true)
		end)

		if ok and typeof(result) == "table" then
			local joined, verifiedResult = readGroupGateFlags(result)
			if joined or verifiedResult or result.CodeGroupVerified == true then
				sessionCodeGroupVerified = true
			end
			if result.Success == true then
				lastCodeRedeemResult = tostring(result.Message or result.RewardText or "Code redeemed.")
			else
				lastCodeRedeemResult = tostring(result.Message or "Code failed.")
			end
		elseif ok then
			lastCodeRedeemResult = tostring(result or "Code submitted.")
		else
			lastCodeRedeemResult = "Could not redeem right now."
		end

		rebuildPage(buildCodesPage, "Codes")
	end

	local redeemButton = makeSmallButton(inputCard, canRedeem and "REDEEM" or "LOCKED", canRedeem and THEME.RedDark or THEME.Panel3, handleRedeem)
	redeemButton.Position = UDim2.new(1, -116, 0, 76)

	input.FocusLost:Connect(function(enterPressed)
		lastTypedCode = tostring(input.Text or "")
		if enterPressed and canRedeem and lastTypedCode ~= "" then
			handleRedeem()
		end
	end)

	makeSectionLabel("Reminder")
	makeNotice("Do not ask staff for private codes. Active codes should come from official announcements only.", 64, THEME.Red)
end

local function getAchievementsSafe()
	if not getAchievements or not getAchievements:IsA("RemoteFunction") then
		return {
			Achievements = {},
			ClaimedCount = 0,
			UnlockedCount = 0,
			TotalCount = 0,
			Error = "Achievement remotes are missing.",
		}
	end
	local ok, payload = pcall(function()
		return getAchievements:InvokeServer()
	end)
	if ok and typeof(payload) == "table" then return payload end
	return {
		Achievements = {},
		ClaimedCount = 0,
		UnlockedCount = 0,
		TotalCount = 0,
		Error = "Could not load achievements right now.",
	}
end

local function makeAchievementCard(achievement)
	local unlocked = achievement.Unlocked == true
	local claimed = achievement.Claimed == true
	local card = makeCard(132)
	card.BackgroundColor3 = claimed and THEME.Panel2 or THEME.Card

	local accentColor = claimed and THEME.Green or (unlocked and THEME.Gold or THEME.Muted)

	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(0, 4, 1, -24)
	accent.Position = UDim2.new(0, 12, 0, 12)
	accent.BackgroundColor3 = accentColor
	accent.BorderSizePixel = 0
	accent.ZIndex = 634
	accent.Parent = card
	addCorner(accent, 999)

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -160, 0, 24)
	name.Position = UDim2.new(0, 28, 0, 14)
	name.BackgroundTransparency = 1
	name.TextColor3 = unlocked and THEME.Text or THEME.SubText
	name.TextSize = 15
	name.Font = Enum.Font.GothamBlack
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Text = tostring(achievement.Name or "Achievement")
	name.ZIndex = 634
	name.Parent = card

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -160, 0, 40)
	desc.Position = UDim2.new(0, 28, 0, 42)
	desc.BackgroundTransparency = 1
	desc.TextColor3 = THEME.SubText
	desc.TextSize = 11
	desc.Font = Enum.Font.GothamMedium
	desc.TextWrapped = true
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.Text = tostring(achievement.Description or "No description available.")
	desc.ZIndex = 634
	desc.Parent = card

	local reward = Instance.new("TextLabel")
	reward.Size = UDim2.new(1, -160, 0, 28)
	reward.Position = UDim2.new(0, 28, 0, 86)
	reward.BackgroundTransparency = 1
	reward.TextColor3 = THEME.Gold
	reward.TextSize = 11
	reward.Font = Enum.Font.GothamBold
	reward.TextWrapped = true
	reward.TextXAlignment = Enum.TextXAlignment.Left
	reward.TextYAlignment = Enum.TextYAlignment.Top
	reward.Text = "Reward: " .. tostring(achievement.RewardText or "Reward available")
	reward.ZIndex = 634
	reward.Parent = card

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(0, 116, 0, 20)
	statusLabel.Position = UDim2.new(1, -132, 0, 14)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = accentColor
	statusLabel.TextSize = 11
	statusLabel.Font = Enum.Font.GothamBlack
	statusLabel.TextXAlignment = Enum.TextXAlignment.Right
	statusLabel.Text = claimed and "CLAIMED" or (unlocked and "UNLOCKED" or "LOCKED")
	statusLabel.ZIndex = 634
	statusLabel.Parent = card

	local claimButton = makeSmallButton(card, claimed and "CLAIMED" or (unlocked and "CLAIM" or "LOCKED"), unlocked and not claimed and THEME.RedDark or THEME.Panel3, function()
		if claimed then playSFX("Error") return end
		if not unlocked then playSFX("Error") return end
		if not claimAchievement or not claimAchievement:IsA("RemoteEvent") then playSFX("Error") return end
		claimAchievement:FireServer(tostring(achievement.Id or ""))
		task.delay(0.45, function()
			if isOpen and currentTab == "Achievements" then
				rebuildPage(buildAchievementsPage, "Achievements")
			end
		end)
	end)
	claimButton.Position = UDim2.new(1, -116, 1, -44)
	claimButton.TextColor3 = unlocked and not claimed and THEME.Text or THEME.Muted
end

buildAchievementsPage = function()
	setHeader("Achievements", "Track milestones and claim rewards.")

	local payload = getAchievementsSafe()
	local achievements = payload.Achievements
	if typeof(achievements) ~= "table" then achievements = {} end

	local unlockedCount = tonumber(payload.UnlockedCount) or 0
	local claimedCount = tonumber(payload.ClaimedCount) or 0
	local totalCount = tonumber(payload.TotalCount) or #achievements

	makeNotice("Unlocked: " .. tostring(unlockedCount) .. "/" .. tostring(totalCount) .. "    Claimed: " .. tostring(claimedCount) .. "/" .. tostring(totalCount), 64, THEME.Gold)

	if payload.Error then
		makeNotice(tostring(payload.Error), 72, THEME.Bad)
		return
	end

	if #achievements <= 0 then
		makeNotice("No achievements are available yet. If this is wrong, check BK_AchievementService and the GetAchievements remote.", 82, THEME.Bad)
		return
	end

	makeSectionLabel("Milestones")
	for _, achievement in ipairs(achievements) do
		makeAchievementCard(achievement)
	end
end

local function showGiftStatusPopup(success, titleText, bodyText)
	local shade = Instance.new("Frame")
	shade.Name = "GiftStatusPopup"
	shade.Size = UDim2.new(1, 0, 1, 0)
	shade.BackgroundTransparency = 1
	shade.ZIndex = 8000
	shade.Parent = gui

	local popupCard = Instance.new("Frame")
	popupCard.Size = UDim2.new(0, 360, 0, 132)
	popupCard.Position = UDim2.new(0.5, -180, 0.5, -66)
	popupCard.BackgroundColor3 = success and Color3.fromRGB(22, 75, 42) or Color3.fromRGB(92, 24, 34)
	popupCard.BorderSizePixel = 0
	popupCard.ZIndex = 8001
	popupCard.Parent = shade
	addCorner(popupCard, 10)
	addStroke(popupCard, success and THEME.Green or THEME.Bad, 2)

	local popupTitle = Instance.new("TextLabel")
	popupTitle.Size = UDim2.new(1, -28, 0, 28)
	popupTitle.Position = UDim2.new(0, 14, 0, 18)
	popupTitle.BackgroundTransparency = 1
	popupTitle.TextColor3 = THEME.Text
	popupTitle.TextSize = 18
	popupTitle.Font = Enum.Font.GothamBlack
	popupTitle.Text = tostring(titleText or (success and "GIFT READY" or "GIFT ERROR"))
	popupTitle.ZIndex = 8002
	popupTitle.Parent = popupCard

	local popupBody = Instance.new("TextLabel")
	popupBody.Size = UDim2.new(1, -36, 0, 56)
	popupBody.Position = UDim2.new(0, 18, 0, 58)
	popupBody.BackgroundTransparency = 1
	popupBody.TextColor3 = THEME.Text
	popupBody.TextSize = 13
	popupBody.Font = Enum.Font.GothamMedium
	popupBody.TextWrapped = true
	popupBody.Text = tostring(bodyText or "")
	popupBody.ZIndex = 8002
	popupBody.Parent = popupCard

	task.delay(2.2, function()
		if shade and shade.Parent then shade:Destroy() end
	end)
end

local function promptGiftRecipient(item)
	local giftOverlay = Instance.new("Frame")
	giftOverlay.Name = "GiftRecipientPrompt"
	giftOverlay.Size = UDim2.new(1, 0, 1, 0)
	giftOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	giftOverlay.BackgroundTransparency = 0.42
	giftOverlay.ZIndex = 5000
	giftOverlay.Parent = gui

	local box = Instance.new("Frame")
	box.Size = UDim2.new(0, 360, 0, 190)
	box.Position = UDim2.new(0.5, -180, 0.5, -95)
	box.BackgroundColor3 = THEME.Panel
	box.BorderSizePixel = 0
	box.ZIndex = 5001
	box.Parent = giftOverlay
	addCorner(box, 10)
	addStroke(box, THEME.Stroke, 1)

	local giftTitle = Instance.new("TextLabel")
	giftTitle.Size = UDim2.new(1, -32, 0, 28)
	giftTitle.Position = UDim2.new(0, 16, 0, 16)
	giftTitle.BackgroundTransparency = 1
	giftTitle.TextColor3 = item.Accent or THEME.Gold
	giftTitle.TextSize = 18
	giftTitle.Font = Enum.Font.GothamBlack
	giftTitle.TextXAlignment = Enum.TextXAlignment.Left
	giftTitle.Text = tostring(item.Name or "Gift")
	giftTitle.ZIndex = 5002
	giftTitle.Parent = box

	local note = Instance.new("TextLabel")
	note.Size = UDim2.new(1, -32, 0, 20)
	note.Position = UDim2.new(0, 16, 0, 44)
	note.BackgroundTransparency = 1
	note.TextColor3 = THEME.SubText
	note.TextSize = 11
	note.Font = Enum.Font.GothamMedium
	note.TextXAlignment = Enum.TextXAlignment.Left
	note.Text = "Type the receiver's Roblox username. Gifts cannot be sent to yourself."
	note.ZIndex = 5002
	note.Parent = box

	local giftInput = Instance.new("TextBox")
	giftInput.Size = UDim2.new(1, -32, 0, 42)
	giftInput.Position = UDim2.new(0, 16, 0, 72)
	giftInput.BackgroundColor3 = THEME.Panel2
	giftInput.BorderSizePixel = 0
	giftInput.PlaceholderText = "Recipient Roblox username"
	giftInput.Text = ""
	giftInput.TextColor3 = THEME.Text
	giftInput.PlaceholderColor3 = THEME.SubText
	giftInput.TextSize = 14
	giftInput.Font = Enum.Font.GothamBold
	giftInput.ClearTextOnFocus = false
	giftInput.ZIndex = 5002
	giftInput.Parent = box
	addCorner(giftInput, 8)
	addStroke(giftInput, THEME.Stroke, 1)

	local cancel = Instance.new("TextButton")
	cancel.Size = UDim2.new(0.48, -8, 0, 40)
	cancel.Position = UDim2.new(0, 16, 1, -56)
	cancel.BackgroundColor3 = THEME.Panel2
	cancel.BorderSizePixel = 0
	cancel.TextColor3 = THEME.Text
	cancel.TextSize = 13
	cancel.Font = Enum.Font.GothamBlack
	cancel.Text = "CANCEL"
	cancel.ZIndex = 5002
	cancel.Parent = box
	addCorner(cancel, 8)

	local giftButton = cancel:Clone()
	giftButton.Position = UDim2.new(0.52, 0, 1, -56)
	giftButton.BackgroundColor3 = item.Accent or THEME.Purple
	giftButton.Text = "GIFT"
	giftButton.Parent = box

	cancel.MouseButton1Click:Connect(function()
		giftOverlay:Destroy()
	end)

	giftButton.MouseButton1Click:Connect(function()
		local receiverName = tostring(giftInput.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if receiverName == "" then
			showGiftStatusPopup(false, "GIFT ERROR", "Enter the receiver's Roblox username first.")
			return
		end
		if string.lower(receiverName) == string.lower(player.Name) then
			showGiftStatusPopup(false, "GIFT ERROR", "You cannot gift this to yourself. Enter another player's Roblox username.")
			return
		end
		giftButton.Text = "CHECKING..."
		local ok, result = pcall(function()
			return setGiftRecipient:InvokeServer(item.RobloxId, receiverName)
		end)
		if not ok or typeof(result) ~= "table" or result.Success ~= true then
			giftButton.Text = "GIFT"
			showGiftStatusPopup(false, "GIFT ERROR", (typeof(result) == "table" and result.Message) or "Could not set gift recipient.")
			return
		end
		giftOverlay:Destroy()
		showGiftStatusPopup(true, "GIFT READY", "Receiver confirmed: " .. tostring(result.RecipientName or receiverName) .. ". Complete the purchase to send the gift.")
		promptRobuxItem(item.Kind, item.RobloxId)
	end)

	task.defer(function()
		giftInput:CaptureFocus()
	end)
end

local function makeProductCard(item)
	local isStarterPackClaimed = item.Id == "starter_pack" and hasClaimedStarterPack()
	local card = makeCard(118)

	local accentFrame = Instance.new("Frame")
	accentFrame.Size = UDim2.new(0, 4, 1, -24)
	accentFrame.Position = UDim2.new(0, 12, 0, 12)
	accentFrame.BackgroundColor3 = item.Accent or THEME.Gold
	accentFrame.BorderSizePixel = 0
	accentFrame.ZIndex = 634
	accentFrame.Parent = card
	addCorner(accentFrame, 999)

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -160, 0, 24)
	name.Position = UDim2.new(0, 28, 0, 14)
	name.BackgroundTransparency = 1
	name.TextColor3 = THEME.Text
	name.TextSize = 15
	name.Font = Enum.Font.GothamBlack
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Text = tostring(item.Name or "Product")
	name.ZIndex = 634
	name.Parent = card

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -160, 0, 44)
	desc.Position = UDim2.new(0, 28, 0, 42)
	desc.BackgroundTransparency = 1
	desc.TextColor3 = THEME.SubText
	desc.TextSize = 11
	desc.Font = Enum.Font.GothamMedium
	desc.TextWrapped = true
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.Text = tostring(item.Subtitle or "")
	desc.ZIndex = 634
	desc.Parent = card

	local price = Instance.new("TextLabel")
	price.Size = UDim2.new(0, 110, 0, 20)
	price.Position = UDim2.new(1, -126, 0, 14)
	price.BackgroundTransparency = 1
	price.TextColor3 = item.Accent or THEME.Gold
	price.TextSize = 11
	price.Font = Enum.Font.GothamBlack
	price.TextXAlignment = Enum.TextXAlignment.Right
	price.Text = tostring(item.PriceText or item.Kind or "SHOP")
	price.ZIndex = 634
	price.Parent = card

	local buyText = isStarterPackClaimed and "OWNED" or (item.GiftPassKey and "GIFT" or ((item.RobloxId and item.RobloxId > 0) and "BUY" or "SET ID"))
	local buyButton = makeSmallButton(card, buyText, isStarterPackClaimed and THEME.Panel3 or THEME.RedDark, function()
		if isStarterPackClaimed then playSFX("Error") return end
		if item.GiftPassKey then
			promptGiftRecipient(item)
		else
			promptRobuxItem(item.Kind, item.RobloxId)
		end
	end)
	buyButton.Position = UDim2.new(1, -116, 1, -44)
end

buildShopPage = function()
	setHeader("Shop", "Organized purchases by category.")

	makeNotice("Shop is split into Featured, Rerolls, Boosts & Recovery, Money, Dojo, and Gamepasses. Developer products can be bought more than once.", 82, THEME.Purple)

	for _, category in ipairs(SHOP_CATEGORIES) do
		makeSectionLabel(category.Name)
		if category.Subtitle and category.Subtitle ~= "" then
			makeNotice(category.Subtitle, 56, category.Accent or THEME.Purple)
		end
		for _, item in ipairs(category.Items) do
			if item.TestOnly ~= true or game.PlaceId == TEST_PURCHASE_PLACE_ID then
				makeProductCard(item)
			end
		end
	end
end

----------------------------------------------------------------
-- OPEN / CLOSE
----------------------------------------------------------------
local function openPanel()
	if isOpen then return end
	isOpen = true
	gui.Enabled = true
	applyResponsiveLayout()
	confirmingDeleteSlotId = nil
	rebuildPage(buildHomePage, "Home")
	applyAllSettings()
	playSFX("Open")
end

local function closePanel()
	if not isOpen then return end
	isOpen = false
	confirmingDeleteSlotId = nil
	gui.Enabled = false
	playSFX("Close")
end

----------------------------------------------------------------
-- TAB CONNECTIONS
----------------------------------------------------------------
local PAGE_BUILDERS = {
	Home = buildHomePage,
	Audio = buildAudioPage,
	Gameplay = buildGameplayPage,
	Saves = buildSavesPage,
	Codes = buildCodesPage,
	Achievements = buildAchievementsPage,
	Shop = buildShopPage,
}

for tabId, button in pairs(tabs) do
	button.MouseEnter:Connect(function()
		if currentTab ~= tabId then
			tween(button, 0.1, { BackgroundColor3 = THEME.Panel3 })
		end
	end)
	button.MouseLeave:Connect(function()
		setTabVisuals()
	end)
	button.MouseButton1Click:Connect(function()
		playSFX("Click")
		confirmingDeleteSlotId = nil
		local builder = PAGE_BUILDERS[tabId] or buildHomePage
		rebuildPage(builder, tabId)
	end)
end

closeButton.MouseButton1Click:Connect(function()
	playSFX("Click")
	uiState.closeRoute()
end)

overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if input.Position then
			local absPos = window.AbsolutePosition
			local absSize = window.AbsoluteSize
			local x, y = input.Position.X, input.Position.Y
			if x < absPos.X or x > absPos.X + absSize.X or y < absPos.Y or y > absPos.Y + absSize.Y then
				uiState.closeRoute()
			end
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Escape and isOpen then
		uiState.closeRoute()
	end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(purchasePlayer, purchasedPassId, wasPurchased)
	if purchasePlayer ~= player then return end
	if not wasPurchased then return end
	if purchasedPassId == VIP_SORCERER_PASS_ID or purchasedPassId == EXTRA_SAVE_SLOTS_GAMEPASS_ID or purchasedPassId == LUCKY_BIRTH_GAMEPASS_ID or purchasedPassId == EXTRA_DOJO_STUDENTS_GAMEPASS_ID or purchasedPassId == DOUBLE_MONEY_GAMEPASS_ID or purchasedPassId == DOUBLE_TRAINING_GAMEPASS_ID or purchasedPassId == GOD_MODE_GAMEPASS_ID then
		task.delay(0.5, function()
			if isOpen and currentTab == "Saves" then
				rebuildPage(buildSavesPage, "Saves")
			elseif isOpen and currentTab == "Shop" then
				rebuildPage(buildShopPage, "Shop")
			end
		end)
	end
end)

updateLifeEvent.OnClientEvent:Connect(function(stats)
	syncSettingsFromStats(stats)
	applyAllSettings()
end)

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		if isOpen then applyResponsiveLayout() end
	end)
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	task.wait()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if isOpen then applyResponsiveLayout() end
		end)
	end
	if isOpen then applyResponsiveLayout() end
end)

----------------------------------------------------------------
-- INIT
----------------------------------------------------------------
local function init()
	uiState.subscribe(function(route)
		if route == "settings" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
