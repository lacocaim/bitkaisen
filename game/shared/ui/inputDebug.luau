local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local overlayManager = require("@ui-state/overlayManager")

local PREFIX = "[BK-INPUTDEBUG]"

local KNOWN_PREFIXES = { "BitKaisen", "Mobile", "Topbar" }

local function isKnownGui(name: string): boolean
	for _, prefix in KNOWN_PREFIXES do
		if string.sub(name, 1, #prefix) == prefix then
			return true
		end
	end
	return false
end

local function fmt(v)
	if typeof(v) == "Vector2" then
		return string.format("%.0fx%.0f", v.X, v.Y)
	end
	return tostring(v)
end

local inputDebug = {}

local hudLabel: TextLabel? = nil
local consoleEnabled = false
local lastTapInfo = "none"

local function getEnabledFullScreenGuis(): string
	local list = {}
	for _, child in playerGui:GetChildren() do
		if child:IsA("ScreenGui") and child.Enabled and child.Name ~= "BK_DebugHUD" then
			table.insert(list, child.Name)
		end
	end
	return table.concat(list, ", ")
end

local function updateHud()
	if not hudLabel then return end
	local overlay = overlayManager.currentName() or "none"
	local guis = getEnabledFullScreenGuis()
	hudLabel.Text = string.format(
		"TAP: %s\nOVERLAY: %s\nGUIs: %s",
		lastTapInfo, overlay, guis
	)
end

function inputDebug.hitTestAt(x, y)
	local objects = playerGui:GetGuiObjectsAtPosition(x, y)

	if #objects > 0 then
		local top = objects[1]
		local active = "?"
		pcall(function() active = tostring(top.Active) end)
		lastTapInfo = string.format("%s [%s] Active=%s", top.Name, top.ClassName, active)
	else
		lastTapInfo = string.format("(%d,%d) MISS", x, y)
	end
	updateHud()

	if consoleEnabled then
		print(PREFIX, string.format("--- hit-test at (%d, %d) => %d objects ---", x, y, #objects))
		for i, obj in objects do
			local act = "?"
			pcall(function() act = tostring(obj.Active) end)
			print(PREFIX, string.format(
				"  [%d] %s (%s) Active=%s Visible=%s Size=%s BgTransp=%.2f",
				i, obj:GetFullName(), obj.ClassName, act,
				tostring(obj.Visible), fmt(obj.AbsoluteSize), obj.BackgroundTransparency
			))
			if i >= 12 then
				print(PREFIX, "  ... truncated")
				break
			end
		end
	end
end

function inputDebug.dumpScreenGuis()
	if not consoleEnabled then return end
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(0, 0)

	print(PREFIX, "=== ScreenGui dump === viewport:", fmt(viewport))
	for _, child in playerGui:GetChildren() do
		if child:IsA("ScreenGui") then
			local tag = ""
			if not isKnownGui(child.Name) then
				tag = " [ORPHAN?]"
			end
			print(PREFIX, string.format(
				"  %s  Enabled=%s  DisplayOrder=%d%s",
				child:GetFullName(), tostring(child.Enabled), child.DisplayOrder, tag
			))
		end
	end
	print(PREFIX, "=== end dump ===")
end

function inputDebug.init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "BK_DebugHUD"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 9999
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	-- Toggle button (always visible, tiny, top-left)
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "ToggleDebug"
	toggleBtn.Size = UDim2.fromOffset(28, 28)
	toggleBtn.Position = UDim2.new(0, 4, 0, 50)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	toggleBtn.BackgroundTransparency = 0.3
	toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 255)
	toggleBtn.TextSize = 14
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.Text = "D"
	toggleBtn.BorderSizePixel = 0
	toggleBtn.ZIndex = 10
	toggleBtn.Parent = gui
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

	-- HUD panel (initially hidden)
	local hudFrame = Instance.new("Frame")
	hudFrame.Name = "HudPanel"
	hudFrame.Size = UDim2.new(1, -8, 0, 120)
	hudFrame.Position = UDim2.new(0, 4, 1, -124)
	hudFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
	hudFrame.BackgroundTransparency = 0.15
	hudFrame.BorderSizePixel = 0
	hudFrame.Visible = false
	hudFrame.ZIndex = 10
	hudFrame.Parent = gui
	Instance.new("UICorner", hudFrame).CornerRadius = UDim.new(0, 8)

	hudLabel = Instance.new("TextLabel")
	hudLabel.Name = "InfoLabel"
	hudLabel.Size = UDim2.new(1, -90, 1, -8)
	hudLabel.Position = UDim2.new(0, 6, 0, 4)
	hudLabel.BackgroundTransparency = 1
	hudLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
	hudLabel.TextSize = 10
	hudLabel.Font = Enum.Font.Code
	hudLabel.TextXAlignment = Enum.TextXAlignment.Left
	hudLabel.TextYAlignment = Enum.TextYAlignment.Top
	hudLabel.TextWrapped = true
	hudLabel.Text = "TAP: none\nOVERLAY: none\nGUIs: ..."
	hudLabel.ZIndex = 11
	hudLabel.Parent = hudFrame

	-- RESET UI button (always tappable, large)
	local resetBtn = Instance.new("TextButton")
	resetBtn.Name = "ResetUI"
	resetBtn.Size = UDim2.new(0, 78, 0, 50)
	resetBtn.AnchorPoint = Vector2.new(1, 0)
	resetBtn.Position = UDim2.new(1, -4, 0, 4)
	resetBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	resetBtn.TextSize = 12
	resetBtn.Font = Enum.Font.GothamBlack
	resetBtn.Text = "RESET\nUI"
	resetBtn.BorderSizePixel = 0
	resetBtn.ZIndex = 12
	resetBtn.Parent = hudFrame
	Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 8)

	-- Console toggle button
	local consoleBtn = Instance.new("TextButton")
	consoleBtn.Name = "ConsoleToggle"
	consoleBtn.Size = UDim2.new(0, 78, 0, 30)
	consoleBtn.AnchorPoint = Vector2.new(1, 0)
	consoleBtn.Position = UDim2.new(1, -4, 0, 58)
	consoleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
	consoleBtn.TextColor3 = Color3.fromRGB(180, 180, 220)
	consoleBtn.TextSize = 10
	consoleBtn.Font = Enum.Font.GothamBold
	consoleBtn.Text = "LOG: OFF"
	consoleBtn.BorderSizePixel = 0
	consoleBtn.ZIndex = 12
	consoleBtn.Parent = hudFrame
	Instance.new("UICorner", consoleBtn).CornerRadius = UDim.new(0, 6)

	-- Wiring
	local hudVisible = false
	toggleBtn.Activated:Connect(function()
		hudVisible = not hudVisible
		hudFrame.Visible = hudVisible
		if hudVisible then
			updateHud()
		end
	end)

	resetBtn.Activated:Connect(function()
		overlayManager.closeAll()
		local uiState = require("@ui-state/uiState")
		uiState.closeAll()
		for _, child in playerGui:GetChildren() do
			if child:IsA("ScreenGui") and child.Name ~= "BK_DebugHUD" and child.Name ~= "MobileGui"
				and child.Name ~= "MobilePopupLayer" and child.Name ~= "MobileNotifLayer"
				and child.Name ~= "BitKaisenTopBarGui" and child.Name ~= "TopbarCentered"
				and child.Name ~= "TopbarStandard" and child.Name ~= "TopbarCenteredClipped"
				and child.Name ~= "TopbarStandardClipped" and child.Name ~= "Freecam" then
				if child.Enabled then
					child.Enabled = false
				end
			end
		end
		lastTapInfo = "RESET FIRED"
		updateHud()
	end)

	consoleBtn.Activated:Connect(function()
		consoleEnabled = not consoleEnabled
		consoleBtn.Text = consoleEnabled and "LOG: ON" or "LOG: OFF"
		consoleBtn.BackgroundColor3 = consoleEnabled and Color3.fromRGB(40, 80, 40) or Color3.fromRGB(40, 40, 80)
		if consoleEnabled then
			inputDebug.dumpScreenGuis()
		end
	end)

	-- Input tracking
	UserInputService.InputBegan:Connect(function(input, _gameProcessed)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local pos = input.Position
		local inset = GuiService:GetGuiInset()
		inputDebug.hitTestAt(math.floor(pos.X + inset.X), math.floor(pos.Y + inset.Y))
	end)

	-- Periodic HUD refresh
	task.spawn(function()
		while true do
			task.wait(1)
			updateHud()
		end
	end)

	print(PREFIX, "Debug HUD active (tap D to show)")
end

return inputDebug
