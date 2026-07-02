local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local experienceMode = require("@ui-state/experienceMode")
local mode = experienceMode.resolve()
if mode ~= "Computer" then return end

local vide = require("@packages/vide")
local theme = require("@ui/theme")
local playerState = require("@ui-state/playerState")
local uiState = require("@ui-state/uiState")
local navRegistry = require("@ui-state/navRegistry")
local remotes = require("@ui-state/remotes")
local px = require("@ui/px")

local ProfileCard = require("@ui-components/shell/ProfileCard")
local LifeLog = require("@ui-components/shell/LifeLog")
local AgeUpButton = require("@ui-components/shell/AgeUpButton")
local NavPanel = require("@ui-components/shell/NavPanel")
local NotificationHolder = require("@ui-components/shell/NotificationHolder")
local MajorPopup = require("@ui-components/shell/MajorPopup")
local WeeklyChallengesPanel = require("@ui-panels/WeeklyChallengesPanel")
local MissionsPanel = require("@ui-panels/MissionsPanel")
local ActivitiesPanel = require("@ui-panels/ActivitiesPanel")
local BlackMarketPanel = require("@ui-panels/BlackMarketPanel")
local CultPanel = require("@ui-panels/CultPanel")
local RelationshipsPanel = require("@ui-panels/RelationshipsPanel")
local AssetsPanel = require("@ui-panels/AssetsPanel")
local AffiliationsPanel = require("@ui-panels/AffiliationsPanel")
local JobsPanel = require("@ui-panels/JobsPanel")
local DomainPanel = require("@ui-panels/DomainPanel")
local RivalsPanel = require("@ui-panels/RivalsPanel")
local WorldHistoryPanel = require("@ui-panels/WorldHistoryPanel")
local MentorPanel = require("@ui-panels/MentorPanel")
local RatesPanel = require("@ui-panels/RatesPanel")
local TechniqueMasteryPanel = require("@ui-panels/TechniqueMasteryPanel")
local TraitDetailsPanel = require("@ui-panels/TraitDetailsPanel")
local DevToolsPanel = require("@ui-panels/DevToolsPanel")
local SettingsPanel = require("@ui-panels/SettingsPanel")
local BindingVowsPanel = require("@ui-panels/BindingVowsPanel")
local DailyLoginPanel = require("@ui-panels/DailyLoginPanel")
local FreeRewardsPanel = require("@ui-panels/FreeRewardsPanel")
local UpdateLogPanel = require("@ui-panels/UpdateLogPanel")
local ClanWarPanel = require("@ui-panels/ClanWarPanel")
local CultWarPanel = require("@ui-panels/CultWarPanel")
local GodModePanel = require("@ui-panels/GodModePanel")
local AFKPanel = require("@ui-panels/AFKPanel")
local CombatPanel = require("@ui-panels/CombatPanel")
local MinigamesPanel = require("@ui-panels/MinigamesPanel")
local CharacterCustomizationPanel = require("@ui-panels/CharacterCustomizationPanel")
local DeathPanel = require("@ui-panels/DeathPanel")
local MissionSituationPanel = require("@ui-panels/MissionSituationPanel")
local FirstTimeGuidancePanel = require("@ui-panels/FirstTimeGuidancePanel")
local IncidentMapPanel = require("@ui-panels/IncidentMapPanel")

local TopBarController = require("@ui-panels/TopBarController")
local SFXController = require("@ui/SFXController")
local topbarIcons = require("@ui/topbarIcons")
local loadingScreen = require("@ui/loadingScreen")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local create = vide.create

local function safeInit(label, fn)
	local ok, err = pcall(fn)
	if not ok then warn("[BKClient] init failed: " .. label .. " -> " .. tostring(err)) end
end

if game:GetService("RunService"):IsStudio() then print("[BK] Booting Computer shell") end

do
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://77695327434474"
	sound.Volume = 0.4
	sound.Looped = true
	sound.RollOffMaxDistance = 0
	sound.Parent = game:GetService("SoundService")
	sound:Play()
end

loadingScreen.bump("Registering navigation...")

navRegistry.register({ id = "weekly", label = "WEEKLY", order = 0, color = theme.Blue })
navRegistry.register({ id = "missions", label = "MISSIONS", order = 1, color = theme.Bad })
navRegistry.register({ id = "activities", label = "ACTIVITIES", order = 2, color = theme.Orange })
navRegistry.register({ id = "relationships", label = "RELATIONSHIPS", order = 3, color = Color3.fromRGB(255, 120, 190) })
navRegistry.register({ id = "assets", label = "ASSETS", order = 4, color = theme.Gold })
navRegistry.register({ id = "jobs", label = "JOBS", order = 5, color = theme.Green })
navRegistry.register({ id = "affiliations", label = "AFFILIATIONS", order = 6, color = theme.Purple })
navRegistry.register({ id = "domain", label = "DOMAIN", order = 7, color = Color3.fromRGB(190, 130, 255) })
navRegistry.register({ id = "rivals", label = "RIVALS", order = 8, color = theme.Red })
navRegistry.register({ id = "history", label = "HISTORY", order = 9, color = theme.Blue })
navRegistry.register({ id = "mentor", label = "MENTOR", order = 10, color = Color3.fromRGB(55, 200, 230) })
navRegistry.register({ id = "binding_vows", label = "VOWS", order = 11, color = Color3.fromRGB(220, 180, 255) })
navRegistry.register({ id = "technique_mastery", label = "MASTERY", order = 12, color = Color3.fromRGB(180, 130, 255) })

local function isMobile()
	local camera = workspace.CurrentCamera
	if not camera then return false end
	local viewport = camera.ViewportSize
	return viewport.X < 900 or viewport.Y > viewport.X
end

local function applyResponsiveLayout(mainPanel: Frame)
	local camera = workspace.CurrentCamera
	if not camera then return end
	local viewport = camera.ViewportSize
	local mobile = isMobile()
	local smallMobile = viewport.X < 520
	local portrait = mobile and viewport.Y > viewport.X

	local profileCard = mainPanel:FindFirstChild("ProfileCard")
	local logContainer = mainPanel:FindFirstChild("LogContainer")
	local actionRow = mainPanel:FindFirstChild("ActionRow")
	local navPanel = mainPanel:FindFirstChild("NavPanel")

	if not profileCard or not logContainer or not actionRow or not navPanel then return end

	if mobile then
		profileCard.Size = UDim2.new(0.94, 0, portrait and 0.43 or 0.40, 0)
		profileCard.Position = UDim2.new(0.03, 0, 0.02, 0)

		local logTop = portrait and 0.46 or 0.43
		local logHeight = portrait and 0.28 or 0.23
		logContainer.Size = UDim2.new(0.94, 0, logHeight, 0)
		logContainer.Position = UDim2.new(0.03, 0, logTop, 0)

		local actionTop = logTop + logHeight + 0.01
		actionRow.Size = UDim2.new(0.94, 0, smallMobile and 0.065 or 0.06, 0)
		actionRow.Position = UDim2.new(0.03, 0, actionTop, 0)

		local navPanelObj = navPanel :: ScrollingFrame
		navPanelObj.Size = UDim2.new(0.94, 0, portrait and 0.105 or 0.095, 0)
		navPanelObj.Position = UDim2.new(0.03, 0, 1 - (portrait and 0.115 or 0.105), 0)

		local navScrollMob = navPanelObj:FindFirstChild("NavScroll") or navPanelObj:FindFirstChildWhichIsA("ScrollingFrame")
		local layoutParentMob = navScrollMob or navPanelObj
		local layout = layoutParentMob:FindFirstChildWhichIsA("UIListLayout")
		if layout then
			layout.FillDirection = Enum.FillDirection.Horizontal
			layout.Padding = UDim.new(0, 6)
			layout.VerticalAlignment = Enum.VerticalAlignment.Center
		end
	else
		local navPanelObj = navPanel :: ScrollingFrame
		navPanelObj.Size = UDim2.new(0.945, 0, 0, 40)
		navPanelObj.Position = UDim2.new(0.025, 0, 0.003, 0)

		profileCard.Size = UDim2.new(0.30, 0, 0.76, 0)
		profileCard.Position = UDim2.new(0.67, 0, 0.095, 0)

		logContainer.Size = UDim2.new(0.61, 0, 0.76, 0)
		logContainer.Position = UDim2.new(0.025, 0, 0.095, 0)

		actionRow.Size = UDim2.new(0.61, 0, 0.07, 0)
		actionRow.Position = UDim2.new(0.025, 0, 0.878, 0)
	end
end

local function BitKaisenGui()
	local gui = create("ScreenGui") {
		Name = "BitKaisenGui",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		DisplayOrder = 15,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}

	local mainPanel = create("Frame") {
		Name = "MainPanel",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Bg,
		BorderSizePixel = 0,
		Parent = gui,

		ProfileCard(),
		LifeLog(),
		AgeUpButton(),
		NavPanel(),
	}

	local popupLayer = create("ScreenGui") {
		Name = "BitKaisenPopupLayer",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 1000,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	}
	local majorPopup = MajorPopup()
	majorPopup.Parent = popupLayer

	local notifLayer = create("ScreenGui") {
		Name = "BitKaisenNotifLayer",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 990,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	}
	local notifHolder = NotificationHolder()
	notifHolder.Parent = notifLayer

	applyResponsiveLayout(mainPanel)
	task.defer(function() applyResponsiveLayout(mainPanel) end)
	task.delay(0.25, function() applyResponsiveLayout(mainPanel) end)

	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			applyResponsiveLayout(mainPanel)
		end)
	end

	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		task.delay(0.1, function()
			applyResponsiveLayout(mainPanel)
			if workspace.CurrentCamera then
				workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
					applyResponsiveLayout(mainPanel)
				end)
			end
		end)
	end)

	return gui
end

loadingScreen.bump("Preparing panels...")

safeInit("WeeklyChallengesPanel", WeeklyChallengesPanel.init)
safeInit("MissionsPanel", MissionsPanel.init)
safeInit("ActivitiesPanel", ActivitiesPanel.init)
safeInit("BlackMarketPanel", BlackMarketPanel.init)
safeInit("CultPanel", CultPanel.init)
safeInit("RelationshipsPanel", RelationshipsPanel.init)
safeInit("AssetsPanel", AssetsPanel.init)
safeInit("AffiliationsPanel", AffiliationsPanel.init)
safeInit("JobsPanel", JobsPanel.init)
safeInit("DomainPanel", DomainPanel.init)
safeInit("RivalsPanel", RivalsPanel.init)
safeInit("WorldHistoryPanel", WorldHistoryPanel.init)
safeInit("MentorPanel", MentorPanel.init)
safeInit("DevToolsPanel", DevToolsPanel.init)
safeInit("SettingsPanel", SettingsPanel.init)
safeInit("BindingVowsPanel", BindingVowsPanel.init)
safeInit("DailyLoginPanel", DailyLoginPanel.init)
safeInit("FreeRewardsPanel", FreeRewardsPanel.init)
safeInit("UpdateLogPanel", UpdateLogPanel.init)
safeInit("ClanWarPanel", ClanWarPanel.init)
safeInit("CultWarPanel", CultWarPanel.init)
safeInit("GodModePanel", GodModePanel.init)
safeInit("AFKPanel", AFKPanel.init)
safeInit("IncidentMapPanel", IncidentMapPanel.init)

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
	return BitKaisenGui()
end, playerGui)

safeInit("RatesPanel", RatesPanel.init)
safeInit("TechniqueMasteryPanel", TechniqueMasteryPanel.init)
safeInit("TraitDetailsPanel", function() TraitDetailsPanel.init(playerGui) end)

safeInit("CombatPanel", function() CombatPanel.init(playerGui) end)
safeInit("MinigamesPanel", function() MinigamesPanel.init(playerGui) end)
safeInit("CharacterCustomizationPanel", function() CharacterCustomizationPanel.init(playerGui) end)
safeInit("DeathPanel", function() DeathPanel.init(playerGui) end)
safeInit("MissionSituationPanel", function() MissionSituationPanel.init(playerGui) end)
safeInit("FirstTimeGuidancePanel", function() FirstTimeGuidancePanel.init(playerGui) end)

safeInit("TopBarController", TopBarController.init)
safeInit("SFXController", SFXController.init)

safeInit("topbarIcons", function()
	topbarIcons.init({
		godMode = GodModePanel,
		clanWar = ClanWarPanel,
		cultWar = CultWarPanel,
		afk = AFKPanel,
		freeRewards = FreeRewardsPanel,
	})
end)

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


