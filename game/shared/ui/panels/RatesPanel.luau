local Players = game:GetService("Players")
local responsiveScale = require("@ui/responsiveScale")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenRatesGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 644
gui.Enabled = false
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "RatesOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.42
overlay.BorderSizePixel = 0
overlay.Visible = false
overlay.ZIndex = 644
overlay.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.52, 0)
panel.Size = UDim2.new(0, 430, 0, 420)
panel.BackgroundColor3 = Color3.fromRGB(17, 17, 24)
panel.BorderSizePixel = 0
panel.ZIndex = 645
panel.Parent = overlay

local function makeCorner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = obj
end

local function makeStroke(obj)
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(70, 70, 90)
	s.Thickness = 1
	s.Transparency = 0.15
	s.Parent = obj
end

makeCorner(panel, 10)
makeStroke(panel)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 22, 0, 18)
title.Size = UDim2.new(1, -78, 0, 28)
title.Text = "CLAN / CT RATES"
title.TextColor3 = Color3.fromRGB(255, 215, 120)
title.TextSize = 20
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 646
title.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.Position = UDim2.new(1, -54, 0, 14)
closeButton.Size = UDim2.new(0, 34, 0, 30)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(230, 90, 96)
closeButton.TextSize = 15
closeButton.Font = Enum.Font.GothamBlack
closeButton.BackgroundColor3 = Color3.fromRGB(35, 35, 46)
closeButton.BorderSizePixel = 0
closeButton.ZIndex = 647
closeButton.Parent = panel
makeCorner(closeButton, 8)

closeButton.MouseButton1Click:Connect(function()
	overlay.Visible = false
end)

overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if input.Position then
			local absPos = panel.AbsolutePosition
			local absSize = panel.AbsoluteSize
			local x, y = input.Position.X, input.Position.Y
			if x < absPos.X or x > absPos.X + absSize.X or y < absPos.Y or y > absPos.Y + absSize.Y then
				overlay.Visible = false
			end
		end
	end
end)

local body = Instance.new("TextLabel")
body.BackgroundTransparency = 1
body.Position = UDim2.new(0, 24, 0, 62)
body.Size = UDim2.new(1, -48, 1, -84)
body.TextColor3 = Color3.fromRGB(230, 230, 240)
body.TextSize = 13
body.Font = Enum.Font.GothamMedium
body.TextXAlignment = Enum.TextXAlignment.Left
body.TextYAlignment = Enum.TextYAlignment.Top
body.TextWrapped = true
body.RichText = true
body.ZIndex = 646
body.Parent = panel
body.Text = "<b>Clan Rates</b>\nCommon Clan - 65%\nUncommon Clan - 20%\nRare Clan - 10%\nEpic Clan - 3.5%\nLegendary Clan - 1.4%  Example: Itadori\nHonored Clan - 0.09%  Example: Gojo\nSecret Clan - ???  Examples: Pumpkin, Ryomen\n\n<b>Cursed Technique Rates</b>\nCommon CT - 65%\nUncommon CT - 20%\nRare CT - 10%\nEpic CT - 3.5%\nLegendary CT - 1.4%\nHonored CT - 0.09%\nSecret CT - ???\n\nSecret rates are intentionally hidden."

responsiveScale.attach(panel, 430, 420)

local function attachButton()
	local bitKaisenGui = playerGui:FindFirstChild("BitKaisenGui")
	if not bitKaisenGui then return false end
	local mainPanel = bitKaisenGui:FindFirstChild("MainPanel")
	if not mainPanel then return false end
	local profileCard = mainPanel:FindFirstChild("ProfileCard", true)
	local techRow = profileCard and profileCard:FindFirstChild("TechniqueRow", true)
	if not techRow or techRow:FindFirstChild("RatesButton") then return false end

	local ratesButton = Instance.new("TextButton")
	ratesButton.Name = "RatesButton"
	ratesButton.AnchorPoint = Vector2.new(1, 0.5)
	ratesButton.Position = UDim2.new(1, 0, 0.5, 0)
	ratesButton.Size = UDim2.new(0, 24, 0, 22)
	ratesButton.Text = "%"
	ratesButton.TextColor3 = Color3.fromRGB(255, 230, 165)
	ratesButton.TextSize = 13
	ratesButton.Font = Enum.Font.GothamBlack
	ratesButton.BackgroundColor3 = Color3.fromRGB(45, 36, 64)
	ratesButton.BorderSizePixel = 0
	ratesButton.ZIndex = 20
	ratesButton.Parent = techRow
	makeCorner(ratesButton, 7)
	ratesButton.MouseButton1Click:Connect(function()
		overlay.Visible = true
	end)
	return true
end

local function init()
	gui.Enabled = true

	if not attachButton() then
		task.spawn(function()
			for _ = 1, 40 do
				if attachButton() then break end
				task.wait(0.25)
			end
		end)
	end
end

return { init = init }
