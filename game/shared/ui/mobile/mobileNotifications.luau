local TweenService = game:GetService("TweenService")
local vide = require("@packages/vide")
local playerState = require("@ui-state/playerState")

local mc = require("@ui/mobile/mobileComponents")
local t = mc.theme

local TRACKED_STATS = {
	{ Key = "Health", Label = "Health" },
	{ Key = "Happiness", Label = "Happiness" },
	{ Key = "Smarts", Label = "Smarts" },
	{ Key = "Looks", Label = "Looks" },
	{ Key = "Strength", Label = "Strength" },
	{ Key = "CursedEnergy", Label = "CE Reserves" },
	{ Key = "Money", Label = "Money", Prefix = "$" },
	{ Key = "Reputation", Label = "Reputation" },
	{ Key = "TeacherRecommendations", Label = "Recommendation" },
	{ Key = "TechniqueMastery", Label = "Technique Mastery" },
}

local holder: Frame? = nil
local activeNotifications = {}

local function trimNotifications()
	while #activeNotifications > 3 do
		local oldest = table.remove(activeNotifications, 1)
		if oldest and oldest.Parent then oldest:Destroy() end
	end
end

local function makeStatNotification(text: string, isPositive: boolean)
	if not holder then return end

	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 34)
	card.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
	card.BackgroundTransparency = 1
	card.BorderSizePixel = 0
	card.ZIndex = 201
	card.Parent = holder
	mc.corner(card, 8)

	table.insert(activeNotifications, card)
	trimNotifications()

	local str = Instance.new("UIStroke")
	str.Color = isPositive and Color3.fromRGB(70, 190, 110) or Color3.fromRGB(210, 70, 70)
	str.Transparency = 1
	str.Parent = card

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -16, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = isPositive and Color3.fromRGB(120, 240, 160) or Color3.fromRGB(255, 115, 115)
	label.TextTransparency = 1
	label.TextSize = 13
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.ZIndex = 202
	label.Parent = card

	card.Position = UDim2.new(0, 30, 0, 0)
	TweenService:Create(card, TweenInfo.new(0.2), { BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0) }):Play()
	TweenService:Create(str, TweenInfo.new(0.2), { Transparency = 0 }):Play()
	TweenService:Create(label, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()

	task.delay(2, function()
		if not card or not card.Parent then return end
		TweenService:Create(card, TweenInfo.new(0.25), { BackgroundTransparency = 1, Position = UDim2.new(0, 30, 0, 0) }):Play()
		TweenService:Create(str, TweenInfo.new(0.25), { Transparency = 1 }):Play()
		TweenService:Create(label, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
		task.delay(0.3, function()
			for index, n in ipairs(activeNotifications) do
				if n == card then table.remove(activeNotifications, index) break end
			end
			if card then card:Destroy() end
		end)
	end)
end

local function showStatChanges(oldStats: { [string]: any }, newStats: { [string]: any })
	if not oldStats or not newStats then return end
	for _, data in ipairs(TRACKED_STATS) do
		local before = oldStats[data.Key] or 0
		local after = newStats[data.Key] or 0
		local diff = after - before
		if diff ~= 0 then
			local sign = diff > 0 and "+" or "-"
			local amount = math.abs(diff)
			local valueText = data.Prefix and (sign .. data.Prefix .. tostring(amount)) or (sign .. tostring(amount))
			makeStatNotification(valueText .. " " .. data.Label, diff > 0)
		end
	end
end

local function init(playerGui: PlayerGui)
	local gui = Instance.new("ScreenGui")
	gui.Name = "MobileNotifLayer"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 990
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "MobileNotificationHolder"
	frame.Size = UDim2.new(0.85, 0, 0, 120)
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -140)
	frame.BackgroundTransparency = 1
	frame.ZIndex = 200
	frame.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.Parent = frame

	holder = frame

	vide.root(function()
		vide.effect(function()
			local prev = playerState.previousStats()
			local curr = playerState.stats()
			if prev and curr then
				showStatChanges(prev, curr)
			end
		end)
	end)
end

return { init = init }
