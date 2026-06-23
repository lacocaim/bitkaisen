-- LocalScript: BitKaisenClanWarUI
-- Location: StarterPlayer.StarterPlayerScripts
-- Purpose: Update 13 clan war panel and action controls.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local getClanWar = ReplicatedStorage:WaitForChild("GetClanWar")
local clanWarAction = ReplicatedStorage:WaitForChild("ClanWarAction")
local updateLifeEvent = ReplicatedStorage:WaitForChild("UpdateLifeEvent")

local THEME = {
	Bg = Color3.fromRGB(10, 10, 14),
	Panel = Color3.fromRGB(18, 18, 26),
	Card = Color3.fromRGB(25, 25, 35),
	Stroke = Color3.fromRGB(71, 58, 90),
	Gold = Color3.fromRGB(255, 207, 87),
	Red = Color3.fromRGB(201, 54, 73),
	Green = Color3.fromRGB(102, 220, 139),
	Blue = Color3.fromRGB(93, 177, 210),
	Purple = Color3.fromRGB(154, 95, 242),
	Text = Color3.fromRGB(238, 234, 245),
	Muted = Color3.fromRGB(166, 160, 178),
}

local currentData = nil
local panelOpen = false

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BitKaisenClanWarUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.DisplayOrder = 65
screenGui.Parent = playerGui

local warButton = Instance.new("TextButton")
warButton.Name = "ClanWarButton"
warButton.AnchorPoint = Vector2.new(1, 0)
warButton.Position = UDim2.new(1, -106, 0, 52)
warButton.Size = UDim2.fromOffset(86, 32)
warButton.BackgroundColor3 = Color3.fromRGB(33, 18, 20)
warButton.BorderSizePixel = 0
warButton.Font = Enum.Font.GothamBlack
warButton.Text = "WAR"
warButton.TextColor3 = THEME.Gold
warButton.TextScaled = true
warButton.Visible = false
warButton.Parent = screenGui

local warButtonCorner = Instance.new("UICorner")
warButtonCorner.CornerRadius = UDim.new(0, 8)
warButtonCorner.Parent = warButton

local warButtonStroke = Instance.new("UIStroke")
warButtonStroke.Color = THEME.Stroke
warButtonStroke.Thickness = 1
warButtonStroke.Parent = warButton

local warButtonPad = Instance.new("UIPadding")
warButtonPad.PaddingLeft = UDim.new(0, 12)
warButtonPad.PaddingRight = UDim.new(0, 12)
warButtonPad.PaddingTop = UDim.new(0, 6)
warButtonPad.PaddingBottom = UDim.new(0, 6)
warButtonPad.Parent = warButton

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.35
overlay.BorderSizePixel = 0
overlay.Size = UDim2.fromScale(1, 1)
overlay.Visible = false
overlay.Parent = screenGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0, 520, 0, 430)
panel.BackgroundColor3 = THEME.Panel
panel.BorderSizePixel = 0
panel.Parent = overlay

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 8)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = THEME.Stroke
panelStroke.Thickness = 1
panelStroke.Parent = panel

local panelPad = Instance.new("UIPadding")
panelPad.PaddingLeft = UDim.new(0, 14)
panelPad.PaddingRight = UDim.new(0, 14)
panelPad.PaddingTop = UDim.new(0, 14)
panelPad.PaddingBottom = UDim.new(0, 14)
panelPad.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -46, 0, 30)
title.Font = Enum.Font.GothamBlack
title.Text = "CLAN WAR"
title.TextColor3 = THEME.Gold
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, 0, 0, 0)
closeButton.Size = UDim2.fromOffset(34, 30)
closeButton.BackgroundColor3 = Color3.fromRGB(37, 38, 50)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBlack
closeButton.Text = "X"
closeButton.TextColor3 = THEME.Red
closeButton.TextScaled = true
closeButton.Parent = panel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

local summary = Instance.new("TextLabel")
summary.Name = "Summary"
summary.BackgroundColor3 = THEME.Card
summary.BorderSizePixel = 0
summary.Position = UDim2.new(0, 0, 0, 42)
summary.Size = UDim2.new(1, 0, 0, 86)
summary.Font = Enum.Font.GothamBold
summary.TextColor3 = THEME.Text
summary.TextWrapped = true
summary.TextScaled = true
summary.TextXAlignment = Enum.TextXAlignment.Left
summary.TextYAlignment = Enum.TextYAlignment.Top
summary.Parent = panel

local summaryCorner = Instance.new("UICorner")
summaryCorner.CornerRadius = UDim.new(0, 8)
summaryCorner.Parent = summary

local summaryPad = Instance.new("UIPadding")
summaryPad.PaddingLeft = UDim.new(0, 12)
summaryPad.PaddingRight = UDim.new(0, 12)
summaryPad.PaddingTop = UDim.new(0, 10)
summaryPad.PaddingBottom = UDim.new(0, 10)
summaryPad.Parent = summary

local tensionBg = Instance.new("Frame")
tensionBg.Name = "TensionBg"
tensionBg.Position = UDim2.new(0, 0, 0, 140)
tensionBg.Size = UDim2.new(1, 0, 0, 12)
tensionBg.BackgroundColor3 = Color3.fromRGB(44, 41, 48)
tensionBg.BorderSizePixel = 0
tensionBg.Parent = panel

local tensionCorner = Instance.new("UICorner")
tensionCorner.CornerRadius = UDim.new(1, 0)
tensionCorner.Parent = tensionBg

local tensionFill = Instance.new("Frame")
tensionFill.Name = "Fill"
tensionFill.Size = UDim2.fromScale(0, 1)
tensionFill.BackgroundColor3 = THEME.Red
tensionFill.BorderSizePixel = 0
tensionFill.Parent = tensionBg

local tensionFillCorner = Instance.new("UICorner")
tensionFillCorner.CornerRadius = UDim.new(1, 0)
tensionFillCorner.Parent = tensionFill

local actionFrame = Instance.new("Frame")
actionFrame.Name = "Actions"
actionFrame.BackgroundTransparency = 1
actionFrame.Position = UDim2.new(0, 0, 0, 166)
actionFrame.Size = UDim2.new(1, 0, 0, 118)
actionFrame.Parent = panel

local actionGrid = Instance.new("UIGridLayout")
actionGrid.CellPadding = UDim2.fromOffset(8, 8)
actionGrid.CellSize = UDim2.new(0.5, -4, 0, 52)
actionGrid.SortOrder = Enum.SortOrder.LayoutOrder
actionGrid.Parent = actionFrame

local historyBox = Instance.new("ScrollingFrame")
historyBox.Name = "History"
historyBox.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
historyBox.BorderSizePixel = 0
historyBox.Position = UDim2.new(0, 0, 0, 300)
historyBox.Size = UDim2.new(1, 0, 1, -300)
historyBox.ScrollBarThickness = 4
historyBox.CanvasSize = UDim2.fromOffset(0, 0)
historyBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
historyBox.Parent = panel

local historyCorner = Instance.new("UICorner")
historyCorner.CornerRadius = UDim.new(0, 8)
historyCorner.Parent = historyBox

local historyLayout = Instance.new("UIListLayout")
historyLayout.Padding = UDim.new(0, 6)
historyLayout.SortOrder = Enum.SortOrder.LayoutOrder
historyLayout.Parent = historyBox

local historyPad = Instance.new("UIPadding")
historyPad.PaddingLeft = UDim.new(0, 10)
historyPad.PaddingRight = UDim.new(0, 10)
historyPad.PaddingTop = UDim.new(0, 10)
historyPad.PaddingBottom = UDim.new(0, 10)
historyPad.Parent = historyBox

local function clearChildren(frame, keepClasses)
	for _, child in ipairs(frame:GetChildren()) do
		if not keepClasses[child.ClassName] then
			child:Destroy()
		end
	end
end

local function makeActionButton(actionId, label, color, disabled, disabledText)
	local button = Instance.new("TextButton")
	button.Name = actionId
	button.BackgroundColor3 = disabled and Color3.fromRGB(54, 52, 62) or color
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBlack
	button.Text = string.upper(disabled and (disabledText or label) or label)
	button.TextColor3 = disabled and THEME.Muted or Color3.fromRGB(255, 255, 255)
	button.TextScaled = true
	button.AutoButtonColor = disabled ~= true
	button.Active = disabled ~= true
	button.Parent = actionFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.Parent = button

	if disabled ~= true then
		button.Activated:Connect(function()
			button.Active = false
			clanWarAction:FireServer(actionId)
			task.delay(0.35, function()
				button.Active = true
			end)
		end)
	end

	return button
end

local function makeHistoryLine(text, index)
	local label = Instance.new("TextLabel")
	label.Name = "HistoryLine"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 34)
	label.Font = Enum.Font.GothamMedium
	label.TextColor3 = index == 1 and THEME.Gold or THEME.Muted
	label.TextScaled = true
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = tostring(text or "")
	label.Parent = historyBox
	return label
end

local function applyResponsiveLayout()
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local narrow = viewport.X < 680
	local short = viewport.Y < 520

	panel.Size = UDim2.new(0, math.min(520, viewport.X - 24), 0, math.min(430, viewport.Y - 30))
	warButton.Position = UDim2.new(1, -106, 0, narrow and 44 or 52)

	if narrow and not short then
		actionGrid.CellSize = UDim2.new(1, 0, 0, 48)
		actionFrame.Size = UDim2.new(1, 0, 0, 220)
		historyBox.Position = UDim2.new(0, 0, 0, 350)
		historyBox.Size = UDim2.new(1, 0, 1, -350)
	elseif short then
		actionGrid.CellSize = UDim2.new(0.5, -4, 0, 44)
		actionFrame.Size = UDim2.new(1, 0, 0, 100)
		historyBox.Position = UDim2.new(0, 0, 0, 280)
		historyBox.Size = UDim2.new(1, 0, 1, -280)
	else
		actionGrid.CellSize = UDim2.new(0.5, -4, 0, 52)
		actionFrame.Size = UDim2.new(1, 0, 0, 118)
		historyBox.Position = UDim2.new(0, 0, 0, 300)
		historyBox.Size = UDim2.new(1, 0, 1, -300)
	end
end

local function fetchClanWar()
	local ok, data = pcall(function()
		return getClanWar:InvokeServer()
	end)
	if ok and typeof(data) == "table" then
		currentData = data
	else
		currentData = { Eligible = false, Active = false, History = {} }
	end
	return currentData
end

local function render()
	local data = currentData or fetchClanWar()
	local visible = data.Active == true or data.Eligible == true
	warButton.Visible = visible
	if not visible then
		overlay.Visible = false
		panelOpen = false
		return
	end

	warButton.BackgroundColor3 = data.Active and Color3.fromRGB(54, 20, 26) or Color3.fromRGB(31, 27, 19)
	warButtonStroke.Color = data.Active and THEME.Red or THEME.Gold

	local tension = math.clamp(tonumber(data.Tension) or 0, 0, 100)
	tensionFill.Size = UDim2.fromScale(tension / 100, 1)
	tensionFill.BackgroundColor3 = tension >= 70 and THEME.Red or (tension >= 35 and THEME.Gold or THEME.Green)

	local cooldown = math.max(0, tonumber(data.Cooldown) or 0)
	local canAct = data.CanAct ~= false and cooldown <= 0
	local cooldownText = cooldown > 0 and ("\nRecovery: " .. tostring(cooldown) .. " year(s) before the next clan move.") or ""
	if data.Active then
		summary.Text = "" .. tostring(data.PlayerClanName or "Your Clan") .. " vs " .. tostring(data.RivalClanName or "Rival Clan") .. "\nPhase: " .. tostring(data.Phase or "Unknown") .. " | Tension: " .. tostring(tension) .. "% | Battles " .. tostring(data.BattlesWon or 0) .. "-" .. tostring(data.BattlesLost or 0) .. "\n" .. tostring(data.Description or "The clan war continues.") .. cooldownText
	else
		summary.Text = tostring(data.PlayerClanName or "Your clan") .. " is not in open war.\nPower: " .. tostring(data.Power or 0) .. " | Record: " .. tostring(data.Wins or 0) .. "W / " .. tostring(data.Losses or 0) .. "L\nA rival clan can pressure you through yearly events, or you can provoke a conflict." .. cooldownText
	end

	clearChildren(actionFrame, { UIGridLayout = true })
	if data.Active then
		makeActionButton("ClanWar_Defend", "Defend", THEME.Blue, not canAct, "Recovering")
		makeActionButton("ClanWar_Strike", "Strike", THEME.Red, not canAct, "Recovering")
		makeActionButton("ClanWar_Negotiate", "Negotiate", THEME.Green, not canAct, "Recovering")
		makeActionButton("ClanWar_Betray", "Betray", THEME.Purple, not canAct, "Recovering")
	else
		makeActionButton("ClanWar_Start", "Provoke Rival", THEME.Red, cooldown > 0, "Recovering")
	end

	clearChildren(historyBox, { UIListLayout = true, UIPadding = true, UICorner = true })
	local history = data.History or {}
	if #history <= 0 then
		makeHistoryLine("No clan war history yet.", 1)
	else
		for i = #history, math.max(1, #history - 8), -1 do
			local entry = history[i]
			local prefix = entry.Year and ("Year " .. tostring(entry.Year) .. ": ") or ""
			makeHistoryLine(prefix .. tostring(entry.Text or "Clan war event."), #history - i + 1)
		end
	end
end

local function refresh()
	fetchClanWar()
	render()
end

warButton.Activated:Connect(function()
	panelOpen = not panelOpen
	overlay.Visible = panelOpen
	if panelOpen then
		refresh()
	end
end)

closeButton.Activated:Connect(function()
	panelOpen = false
	overlay.Visible = false
end)

clanWarAction.OnClientEvent:Connect(function()
	task.delay(0.15, refresh)
end)

updateLifeEvent.OnClientEvent:Connect(function()
	task.delay(0.2, refresh)
end)

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		applyResponsiveLayout()
	end)
end

UserInputService.WindowFocused:Connect(refresh)

applyResponsiveLayout()
refresh()

