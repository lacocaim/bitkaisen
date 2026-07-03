local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local experienceMode = require("@ui-state/experienceMode")
local mode = experienceMode.resolve()
if mode ~= "Mobile" then return end

if game:GetService("RunService"):IsStudio() then print("[BK] Booting Mobile shell") end

do
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://77695327434474"
	sound.Volume = 0.4
	sound.Looped = true
	sound.RollOffMaxDistance = 0
	sound.Parent = game:GetService("SoundService")
	sound:Play()
end

pcall(function()
	StarterGui.ScreenOrientation = Enum.ScreenOrientation.Portrait
end)
pcall(function()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	playerGui.ScreenOrientation = Enum.ScreenOrientation.Portrait
end)

local vide = require("@packages/vide")
local theme = require("@ui/theme")
local playerState = require("@ui-state/playerState")
local uiState = require("@ui-state/uiState")
local navRegistry = require("@ui-state/navRegistry")
local remotes = require("@ui-state/remotes")
local px = require("@ui/px")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function navT(key, fallback) return BitKaisenLocale.tOrFallback(_L, "ui." .. key, nil, fallback) end

local helpers = require("@ui/helpers")
local _MONTH_KEYS = {"month_1","month_2","month_3","month_4","month_5","month_6","month_7","month_8","month_9","month_10","month_11","month_12"}
local _MONTH_FALLBACKS = {"January","February","March","April","May","June","July","August","September","October","November","December"}
local _ERA_KEYS = { ["Modern Era"]="era_modern", ["Edo Era"]="era_edo", ["Heian Era"]="era_heian", ["Collapse Era"]="era_collapse" }
local function _locMonth(i) return navT(_MONTH_KEYS[i] or "month_1", _MONTH_FALLBACKS[i] or "January") end
local function _locEra(e) local k=_ERA_KEYS[e] return k and navT(k,e) or e end
local function getLogTimeLabelLocale(stats)
	if not stats then return "" end
	local age = tonumber(stats.Age) or 0
	local month = math.clamp(tonumber(stats.CurrentMonth) or 1, 1, 12)
	local year = helpers.getCurrentYear(stats)
	local era = _locEra(helpers.getCurrentEraDisplay(stats))
	local tpl = navT("age_header", "Age {age} • {month} {year} • {era}")
	return "<font color='#7a2a2a'><b>[ " .. tpl
		:gsub("{age}", age):gsub("{month}", _locMonth(month)):gsub("{year}", year):gsub("{era}", era)
		.. " ]</b></font>"
end

local mobileShell = require("@ui/mobile/mobileShell")
local mobilePopup = require("@ui/mobile/mobilePopup")
local mobileNotifications = require("@ui/mobile/mobileNotifications")
local loadingScreen = require("@ui/loadingScreen")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function tryInit(label: string, loader: () -> any, ...: any)
	local ok, mod = pcall(loader)
	if not ok then
		warn("[MobileClient] Failed to load " .. label .. ": " .. tostring(mod))
		return
	end
	local args = { ... }
	local initOk, initErr = pcall(function()
		mod.init(table.unpack(args))
	end)
	if not initOk then
		warn("[MobileClient] Failed to init " .. label .. ": " .. tostring(initErr))
	end
end

loadingScreen.bump("Registering navigation...")

navRegistry.register({ id = "weekly",            label = navT("nav_weekly",        "WEEKLY"),        order = 0,  color = theme.Blue })
navRegistry.register({ id = "missions",          label = navT("nav_missions",       "MISSIONS"),       order = 1,  color = theme.Bad })
navRegistry.register({ id = "activities",        label = navT("nav_activities",     "ACTIVITIES"),     order = 2,  color = theme.Orange })
navRegistry.register({ id = "relationships",     label = navT("nav_relationships",  "RELATIONSHIPS"),  order = 3,  color = Color3.fromRGB(255, 120, 190) })
navRegistry.register({ id = "assets",            label = navT("nav_assets",         "ASSETS"),         order = 4,  color = theme.Gold })
navRegistry.register({ id = "jobs",              label = navT("nav_jobs",           "JOBS"),           order = 5,  color = theme.Green })
navRegistry.register({ id = "affiliations",      label = navT("nav_affiliations",   "AFFILIATIONS"),   order = 6,  color = theme.Purple })
navRegistry.register({ id = "domain",            label = navT("nav_domain",         "DOMAIN"),         order = 7,  color = Color3.fromRGB(190, 130, 255) })
navRegistry.register({ id = "rivals",            label = navT("nav_rivals",         "RIVALS"),         order = 8,  color = theme.Red })
navRegistry.register({ id = "history",           label = navT("nav_history",        "HISTORY"),        order = 9,  color = theme.Blue })
navRegistry.register({ id = "mentor",            label = navT("nav_mentor",         "MENTOR"),         order = 10, color = Color3.fromRGB(55, 200, 230) })
navRegistry.register({ id = "binding_vows",      label = navT("nav_vows",           "VOWS"),           order = 11, color = Color3.fromRGB(220, 180, 255) })
navRegistry.register({ id = "technique_mastery", label = navT("nav_mastery",        "MASTERY"),        order = 12, color = theme.Purple })

loadingScreen.bump("Preparing panels...")

tryInit("MobileWeeklyChallengesPanel", function() return require("@ui/mobile/panels/MobileWeeklyChallengesPanel") end)
tryInit("MobileMissionsPanel", function() return require("@ui/mobile/panels/MobileMissionsPanel") end)
tryInit("MobileActivitiesPanel", function() return require("@ui/mobile/panels/MobileActivitiesPanel") end)
tryInit("MobileBlackMarketPanel", function() return require("@ui/mobile/panels/MobileBlackMarketPanel") end)
tryInit("MobileCultPanel", function() return require("@ui/mobile/panels/MobileCultPanel") end)
tryInit("MobileRelationshipsPanel", function() return require("@ui/mobile/panels/MobileRelationshipsPanel") end)
tryInit("MobileAssetsPanel", function() return require("@ui/mobile/panels/MobileAssetsPanel") end)
tryInit("MobileJobsPanel", function() return require("@ui/mobile/panels/MobileJobsPanel") end)
tryInit("MobileAffiliationsPanel", function() return require("@ui/mobile/panels/MobileAffiliationsPanel") end)
tryInit("MobileDomainPanel", function() return require("@ui/mobile/panels/MobileDomainPanel") end)
tryInit("MobileRivalsPanel", function() return require("@ui/mobile/panels/MobileRivalsPanel") end)
tryInit("MobileWorldHistoryPanel", function() return require("@ui/mobile/panels/MobileWorldHistoryPanel") end)
tryInit("MobileMentorPanel", function() return require("@ui/mobile/panels/MobileMentorPanel") end)

tryInit("MobileDailyLoginPanel", function() return require("@ui/mobile/panels/MobileDailyLoginPanel") end)
tryInit("MobileFreeRewardsPanel", function() return require("@ui/mobile/panels/MobileFreeRewardsPanel") end)
tryInit("MobileBindingVowsPanel", function() return require("@ui/mobile/panels/MobileBindingVowsPanel") end)
tryInit("MobileTechniqueMasteryPanel", function() return require("@ui/mobile/panels/MobileTechniqueMasteryPanel") end)
tryInit("MobileTraitDetailsPanel", function() return require("@ui/mobile/panels/MobileTraitDetailsPanel") end, playerGui)
tryInit("MobileRatesPanel", function() return require("@ui/mobile/panels/MobileRatesPanel") end)
tryInit("MobileUpdateLogPanel", function() return require("@ui/mobile/panels/MobileUpdateLogPanel") end)
tryInit("MobileClanWarPanel", function() return require("@ui/mobile/panels/MobileClanWarPanel") end)
tryInit("MobileDeathPanel", function() return require("@ui/mobile/panels/MobileDeathPanel") end, playerGui)
tryInit("MobileMissionSituationPanel", function() return require("@ui/mobile/panels/MobileMissionSituationPanel") end, playerGui)
tryInit("MobileFirstTimeGuidancePanel", function() return require("@ui/mobile/panels/MobileFirstTimeGuidancePanel") end, playerGui)
tryInit("MobileIncidentMapPanel", function() return require("@ui/mobile/panels/MobileIncidentMapPanel") end)

tryInit("MobileCombatPanel", function() return require("@ui/mobile/panels/MobileCombatPanel") end, playerGui)
tryInit("MobileMinigamesPanel", function() return require("@ui/mobile/panels/MobileMinigamesPanel") end, playerGui)
tryInit("MobileCharacterCustomizationPanel", function() return require("@ui/mobile/panels/MobileCharacterCustomizationPanel") end, playerGui)
tryInit("MobileDevToolsPanel", function() return require("@ui/mobile/panels/MobileDevToolsPanel") end)
tryInit("MobileGodModePanel", function() return require("@ui/mobile/panels/MobileGodModePanel") end)
tryInit("MobileAFKPanel", function() return require("@ui/mobile/panels/MobileAFKPanel") end)

tryInit("SettingsPanel", function() return require("@ui-panels/SettingsPanel") end)

px.usePx()

loadingScreen.bump("Building your world...")

local bgGui = Instance.new("ScreenGui")
bgGui.Name = "BitKaisenBg"
bgGui.ResetOnSpawn = false
bgGui.IgnoreGuiInset = true
bgGui.DisplayOrder = 1
bgGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local bgFrame = Instance.new("Frame")
bgFrame.Size = UDim2.fromScale(1, 1)
bgFrame.BackgroundColor3 = theme.Bg
bgFrame.BorderSizePixel = 0
bgFrame.Parent = bgGui
bgGui.Parent = playerGui

vide.mount(function()
	return mobileShell.create(playerGui)
end, playerGui)

mobilePopup.init(playerGui)
mobileNotifications.init(playerGui)

tryInit("TopBarController", function() return require("@ui-panels/TopBarController") end)
tryInit("SFXController", function() return require("@ui/SFXController") end)

do
	local topbarIcons = require("@ui/topbarIcons")
	local godModeRef = nil
	local clanWarRef = nil
	local cultWarRef = nil
	local afkRef = nil
	local freeRewardsRef = nil
	pcall(function() godModeRef = require("@ui/mobile/panels/MobileGodModePanel") end)
	pcall(function() clanWarRef = require("@ui/mobile/panels/MobileClanWarPanel") end)
	pcall(function() cultWarRef = require("@ui/mobile/panels/MobileCultWarPanel") end)
	pcall(function() afkRef = require("@ui/mobile/panels/MobileAFKPanel") end)
	pcall(function() freeRewardsRef = require("@ui/mobile/panels/MobileFreeRewardsPanel") end)
	topbarIcons.init({
		godMode = godModeRef,
		clanWar = clanWarRef,
		cultWar = cultWarRef,
		afk = afkRef,
		freeRewards = freeRewardsRef,
	})
end

local lastLogMessage = ""
local lastLogTimeKey = ""
local lastLogClock = 0
local lastLoggedAge = ""
local lastLifeWasDead = false

local function handleLifeUpdate(updatedStats, logMessage, forceResetLog)
	if not updatedStats then return end

	if forceResetLog == true then
		lastLifeWasDead = false
		playerState.clearLog()
	end

	if updatedStats.Alive and lastLifeWasDead then
		playerState.clearLog()
		lastLifeWasDead = false
	end

	playerState.update(updatedStats, nil, forceResetLog)

	if logMessage then
		local currentTimeKey = helpers.getLogTimeKey(updatedStats)
		local formattedAge = getLogTimeLabelLocale(updatedStats)
		local now = os.clock()
		logMessage = tostring(logMessage)

		if lastLogMessage == logMessage and lastLogTimeKey == currentTimeKey and (now - lastLogClock) < 0.85 then
			return
		end
		lastLogMessage = logMessage
		lastLogTimeKey = currentTimeKey
		lastLogClock = now

		local log = playerState.lifeLog()
		if #log == 0 then
			playerState.pushLog(formattedAge)
			playerState.pushLog(logMessage)
			lastLoggedAge = currentTimeKey
			return
		end

		if lastLoggedAge == currentTimeKey then
			playerState.pushLog(logMessage)
		else
			playerState.pushLog("")
			playerState.pushLog(formattedAge)
			playerState.pushLog(logMessage)
			lastLoggedAge = currentTimeKey
		end
	end

	if updatedStats and updatedStats.Alive == false then
		lastLifeWasDead = true
	end
end

local s0, m0, f0 = experienceMode.getInitialLifeEvent()
if s0 then
	handleLifeUpdate(s0, m0, f0)
end

task.defer(function()
	loadingScreen.finish()
end)

local ule = remotes.updateLifeEvent()
if ule then
	ule.OnClientEvent:Connect(handleLifeUpdate)
end
