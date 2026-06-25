local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local overlayManager = require("@ui-state/overlayManager")

local inputDebug = {}

local hudLabel: TextLabel? = nil

local function getEnabledGuis(): string
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
	local guis = getEnabledGuis()
	hudLabel.Text = string.format("OVERLAY: %s\nGUIs: %s", overlay, guis)
end

function inputDebug.init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "BK_DebugHUD"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 9999
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

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

	local hudFrame = Instance.new("Frame")
	hudFrame.Name = "HudPanel"
	hudFrame.Size = UDim2.new(1, -8, 0, 90)
	hudFrame.Position = UDim2.new(0, 4, 1, -94)
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
	hudLabel.Text = "OVERLAY: none\nGUIs: ..."
	hudLabel.ZIndex = 11
	hudLabel.Parent = hudFrame

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

	local hudVisible = false
	toggleBtn.Activated:Connect(function()
		hudVisible = not hudVisible
		hudFrame.Visible = hudVisible
		if hudVisible then updateHud() end
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
		updateHud()
	end)

	task.spawn(function()
		while true do
			task.wait(2)
			if hudVisible then updateHud() end
		end
	end)
end

return inputDebug
