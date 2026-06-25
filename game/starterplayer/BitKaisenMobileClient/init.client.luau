local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local experienceMode = require("@ui-state/experienceMode")
local mode = experienceMode.resolve()
if mode ~= "Mobile" then return end

print("[BK] Booting Mobile shell")

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

navRegistry.register({ id = "missions", label = "MISSIONS", order = 1, color = theme.Red })
navRegistry.register({ id = "activities", label = "ACTIVITIES", order = 2, color = theme.Red })
navRegistry.register({ id = "relationships", label = "RELATIONSHIPS", order = 3, color = theme.Red })
navRegistry.register({ id = "assets", label = "ASSETS", order = 4, color = theme.Red })
navRegistry.register({ id = "jobs", label = "JOBS", order = 5, color = theme.Gold })
navRegistry.register({ id = "affiliations", label = "AFFILIATIONS", order = 6, color = theme.Purple })
navRegistry.register({ id = "domain", label = "DOMAIN", order = 7, color = theme.Purple })
navRegistry.register({ id = "rivals", label = "RIVALS", order = 8, color = theme.Bad })
navRegistry.register({ id = "history", label = "HISTORY", order = 9, color = theme.Blue })
navRegistry.register({ id = "mentor", label = "MENTOR", order = 10, color = Color3.fromRGB(55, 180, 220) })

loadingScreen.bump("Preparing panels...")

tryInit("MobileMissionsPanel", function() return require("@ui/mobile/panels/MobileMissionsPanel") end)
tryInit("MobileActivitiesPanel", function() return require("@ui/mobile/panels/MobileActivitiesPanel") end)
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
	local afkRef = nil
	pcall(function() godModeRef = require("@ui/mobile/panels/MobileGodModePanel") end)
	pcall(function() clanWarRef = require("@ui/mobile/panels/MobileClanWarPanel") end)
	pcall(function() afkRef = require("@ui/mobile/panels/MobileAFKPanel") end)
	topbarIcons.init({
		godMode = godModeRef,
		clanWar = clanWarRef,
		afk = afkRef,
	})
end

do
	local inputDebug = require("@ui/inputDebug")
	inputDebug.init()
end

local helpers = require("@ui/helpers")

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
		local formattedAge = helpers.getLogTimeLabel(updatedStats)
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
