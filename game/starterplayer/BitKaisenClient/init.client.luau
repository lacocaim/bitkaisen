local Players = game:GetService("Players")

local vide = require("@packages/vide")
local theme = require("@ui/theme")
local playerState = require("@ui-state/playerState")
local uiState = require("@ui-state/uiState")
local navRegistry = require("@ui-state/navRegistry")
local remotes = require("@ui-state/remotes")
local device = require("@ui-state/device")
local px = require("@ui/px")

local ProfileCard = require("@ui-components/shell/ProfileCard")
local LifeLog = require("@ui-components/shell/LifeLog")
local AgeUpButton = require("@ui-components/shell/AgeUpButton")
local NavPanel = require("@ui-components/shell/NavPanel")
local NotificationHolder = require("@ui-components/shell/NotificationHolder")
local MajorPopup = require("@ui-components/shell/MajorPopup")
local SettingsButton = require("@ui-components/shell/SettingsButton")
local ServerSelection = require("@ui-components/shell/ServerSelection")

local MissionsPanel = require("@ui-panels/MissionsPanel")
local ActivitiesPanel = require("@ui-panels/ActivitiesPanel")
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
local ConsoleSupport = require("@ui/ConsoleSupport")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local create = vide.create

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

local function applyResponsiveLayout(mainPanel: Frame)
	local camera = workspace.CurrentCamera
	if not camera then return end
	local viewport = camera.ViewportSize
	local mobile = device.isMobileLayout()
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

		local layout = navPanelObj:FindFirstChildWhichIsA("UIListLayout")
		if layout then
			layout.FillDirection = Enum.FillDirection.Horizontal
			layout.Padding = UDim.new(0, 6)
		end
	else
		profileCard.Size = UDim2.new(0.30, 0, 0.60, 0)
		profileCard.Position = UDim2.new(0.67, 0, 0.07, 0)

		logContainer.Size = UDim2.new(0.61, 0, 0.76, 0)
		logContainer.Position = UDim2.new(0.025, 0, 0.07, 0)

		actionRow.Size = UDim2.new(0.61, 0, 0.08, 0)
		actionRow.Position = UDim2.new(0.025, 0, 0.86, 0)

		local navPanelObj = navPanel :: ScrollingFrame
		navPanelObj.Size = UDim2.new(0.30, 0, 0.28, 0)
		navPanelObj.Position = UDim2.new(0.67, 0, 0.68, 0)

		local layout = navPanelObj:FindFirstChildWhichIsA("UIListLayout")
		if layout then
			layout.FillDirection = Enum.FillDirection.Vertical
			layout.Padding = UDim.new(0, 10)
		end
	end
end

local function BitKaisenGui()
	local gui = create("ScreenGui") {
		Name = "BitKaisenGui",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
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
		SettingsButton(),
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

	local selectionLayer = create("ScreenGui") {
		Name = "BitKaisenSelectionLayer",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 2000,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	}
	local selectionScreen = ServerSelection.create()
	selectionScreen.Parent = selectionLayer

	applyResponsiveLayout(mainPanel)
	task.defer(function() applyResponsiveLayout(mainPanel) end)
	task.delay(0.25, function() applyResponsiveLayout(mainPanel) end)

	device.subscribe(function()
		applyResponsiveLayout(mainPanel)
	end)

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

MissionsPanel.init()
ActivitiesPanel.init()
RelationshipsPanel.init()
AssetsPanel.init()
AffiliationsPanel.init()
JobsPanel.init()
DomainPanel.init()
RivalsPanel.init()
WorldHistoryPanel.init()
MentorPanel.init()
DevToolsPanel.init()
SettingsPanel.init()
BindingVowsPanel.init()
DailyLoginPanel.init()
FreeRewardsPanel.init()
UpdateLogPanel.init()
ClanWarPanel.init()
GodModePanel.init()
AFKPanel.init()
IncidentMapPanel.init()

px.usePx()
device.init()

vide.mount(function()
	return BitKaisenGui()
end, playerGui)

RatesPanel.init()
TechniqueMasteryPanel.init()
TraitDetailsPanel.init(playerGui)

CombatPanel.init(playerGui)
MinigamesPanel.init(playerGui)
CharacterCustomizationPanel.init(playerGui)
DeathPanel.init(playerGui)
MissionSituationPanel.init(playerGui)
FirstTimeGuidancePanel.init(playerGui)

TopBarController.init()
SFXController.init()
ConsoleSupport.init()

local helpers = require("@ui/helpers")

local lastLogMessage = ""
local lastLogTimeKey = ""
local lastLogClock = 0
local lastLoggedAge = ""
local lastLifeWasDead = false
local serverSelectionHandled = false

local ule = remotes.updateLifeEvent()
if ule then
	ule.OnClientEvent:Connect(function(updatedStats, logMessage, forceResetLog)
		if not updatedStats then return end

		if not serverSelectionHandled then
			serverSelectionHandled = true
			local savedMode = nil
			if typeof(updatedStats) == "table" and typeof(updatedStats.Settings) == "table" then
				savedMode = updatedStats.Settings.PlatformMode
			end
			if typeof(savedMode) == "string" and (savedMode == "CrossPlatform" or savedMode == "Mobile") then
				device.setUiMode(savedMode :: device.UiMode)
			end
			if ServerSelection.shouldShow(savedMode) then
				ServerSelection.show()
			end
		end

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
	end)
end


