local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")

local mc = require("@ui/mobile/mobileComponents")
local overlayManager = require("@ui-state/overlayManager")

local theme = mc.theme
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui: ScreenGui
local sheet: Frame
local scroll: ScrollingFrame

local state = { Unlocked = false, Active = false, RatePerSecond = 0.2, SessionEarned = 0, EarnedTotal = 0, ProductId = 0, TestingPlace = false }
local ignoreInputUntil = 0
local lastAutoStopAt = 0

local openButton: TextButton
local actionButton: TextButton
local bodyLabel: TextLabel
local statsLabel: TextLabel

local function formatMoney(value)
	return "$" .. string.format("%.1f", tonumber(value) or 0)
end

local function refresh()
	if not openButton then return end

	local active = state.Active == true
	openButton.Text = active and "AFK ON" or "AFK"
	openButton.TextColor3 = active and theme.Green or theme.Gold
	openButton.BackgroundColor3 = active and Color3.fromRGB(28, 72, 45) or theme.Panel

	local openStroke = openButton:FindFirstChildOfClass("UIStroke")
	if openStroke then
		openStroke.Color = active and theme.Green or theme.Purple
	end

	if actionButton then
		actionButton.Visible = true
		if state.Unlocked then
			bodyLabel.Text = state.Active and "Stabilizing. Avoid normal play actions while AFK mode is active." or "Start AFK mode to earn while idle."
			actionButton.Text = state.Active and "STOP AFK" or "START AFK"
			actionButton.BackgroundColor3 = state.Active and theme.Bad or theme.Green
			actionButton.TextColor3 = state.Active and theme.Text or theme.Bg
		else
			bodyLabel.Text = "One-time unlock. Earn money while idle after activating AFK mode."
			actionButton.Text = state.TestingPlace and "TEST UNLOCK" or "UNLOCK"
			actionButton.BackgroundColor3 = theme.Purple
			actionButton.TextColor3 = theme.Text
		end
	end

	if statsLabel then
		statsLabel.Text = "Rate: " .. formatMoney(state.RatePerSecond or 0) .. "/sec\nThis session: " .. formatMoney(state.SessionEarned or 0) .. "\nLifetime AFK: " .. formatMoney(state.EarnedTotal or 0)
	end
end

local function isPointInside(guiObject, position)
	if not guiObject or not guiObject.Parent or not guiObject.Visible then return false end
	local topLeft = guiObject.AbsolutePosition
	local size = guiObject.AbsoluteSize
	return position.X >= topLeft.X and position.X <= topLeft.X + size.X and position.Y >= topLeft.Y and position.Y <= topLeft.Y + size.Y
end

local function isAFKUiInput(input)
	local position = input.Position
	if typeof(position) ~= "Vector3" then return false end
	local point = Vector2.new(position.X, position.Y)
	return isPointInside(sheet, point) or isPointInside(openButton, point)
end

local function close()
	if not gui then return end
	if sheet then sheet.Visible = false end
	gui.Enabled = false
end

local function init()
	local getAFK = ReplicatedStorage:WaitForChild("GetAFKStabilization", 20)
	local afkAction = ReplicatedStorage:WaitForChild("AFKStabilizationAction", 20)
	local afkUpdate = ReplicatedStorage:WaitForChild("AFKStabilizationUpdate", 20)

	if not getAFK or not afkAction or not afkUpdate then
		warn("[MobileAFKPanel] AFK remotes missing. UI skipped.")
		return
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "MobileAFKStabilizationGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 642
	gui.Enabled = false
	gui.Parent = playerGui

	sheet = mc.mobileSheet({
		name = "MobileAFKSheet",
		parent = gui,
		title = "AFK STABILIZATION",
		onClose = function()
			close()
			overlayManager.closeAll()
		end,
	})

	scroll = sheet:FindFirstChildOfClass("ScrollingFrame")

	local infoCard = mc.mobileCard({ parent = scroll, order = 1 })

	bodyLabel = mc.mobileLabel({
		parent = infoCard,
		text = "Start AFK mode to earn while idle.",
		size = 14,
		color = theme.SubText,
		order = 1,
	})

	statsLabel = mc.mobileLabel({
		parent = infoCard,
		text = "",
		size = 14,
		color = theme.Text,
		font = Enum.Font.GothamBold,
		order = 2,
	})

	actionButton = mc.mobileButton({
		parent = infoCard,
		text = "START AFK",
		color = theme.Green,
		textColor = theme.Bg,
		textSize = 15,
		order = 3,
		callback = function()
			if state.Unlocked then
				local nextAction = state.Active and "stop" or "start"
				if nextAction == "start" then
					ignoreInputUntil = os.clock() + 1.25
				end
				afkAction:FireServer(nextAction)
			else
				local productId = tonumber(state.ProductId) or 0
				if state.TestingPlace then
					afkAction:FireServer("test_unlock")
				elseif productId > 0 then
					MarketplaceService:PromptGamePassPurchase(player, productId)
				end
			end
			task.delay(0.2, function()
				local ok2, p2 = pcall(function() return getAFK:InvokeServer() end)
				if ok2 and typeof(p2) == "table" then
					state = p2
					refresh()
				end
			end)
		end,
	})

	openButton = mc.mobileButton({
		parent = gui,
		text = "AFK",
		size = UDim2.fromOffset(92, 44),
		position = UDim2.new(1, -104, 0, 82),
		color = theme.Panel,
		textColor = theme.Gold,
		textSize = 14,
		callback = function()
			local ok2, p2 = pcall(function() return getAFK:InvokeServer() end)
			if ok2 and typeof(p2) == "table" then
				state = p2
				refresh()
			end
			sheet.Visible = not sheet.Visible
		end,
	})
	mc.stroke(openButton, theme.Purple)

	local function stopAFKFromInput()
		if state.Active ~= true then return end
		if os.clock() < ignoreInputUntil then return end
		if os.clock() - lastAutoStopAt < 0.35 then return end
		lastAutoStopAt = os.clock()
		afkAction:FireServer("stop")
		state.Active = false
		refresh()
		task.delay(0.25, function()
			local ok2, p2 = pcall(function() return getAFK:InvokeServer() end)
			if ok2 and typeof(p2) == "table" then
				state = p2
				refresh()
			end
		end)
	end

	afkUpdate.OnClientEvent:Connect(function(p)
		if typeof(p) == "table" then
			state = p
			refresh()
		end
	end)

	UserInputService.InputBegan:Connect(function(input, _gameProcessed)
		if not state.Active then return end
		if isAFKUiInput(input) then return end
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.Keyboard
			or input.UserInputType == Enum.UserInputType.Gamepad1
		then
			stopAFKFromInput()
		end
	end)

	UserInputService.InputChanged:Connect(function(input, _gameProcessed)
		if not state.Active then return end
		if isAFKUiInput(input) then return end
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.Gamepad1
		then
			stopAFKFromInput()
		end
	end)

	openButton.Visible = false
	sheet.Visible = false

	local ok, p = pcall(function() return getAFK:InvokeServer() end)
	if ok and typeof(p) == "table" then
		state = p
		refresh()
	end
end

local function open()
	if not gui then return end
	gui.Enabled = true
	local getAFK = game:GetService("ReplicatedStorage"):FindFirstChild("GetAFKStabilization")
	if getAFK then
		local ok2, p2 = pcall(function() return getAFK:InvokeServer() end)
		if ok2 and typeof(p2) == "table" then
			state = p2
			refresh()
		end
	end
	if sheet then sheet.Visible = true end
end

return { init = init, open = open, close = close }
