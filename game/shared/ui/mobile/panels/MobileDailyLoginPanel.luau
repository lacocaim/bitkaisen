local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local mc = require("@ui/mobile/mobileComponents")
local overlayManager = require("@ui-state/overlayManager")

local theme = mc.theme
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local getDailyLogin = ReplicatedStorage:WaitForChild("GetDailyLogin", 20)
local claimDailyLogin = ReplicatedStorage:WaitForChild("ClaimDailyLogin", 20)
local updateLifeEvent = ReplicatedStorage:WaitForChild("UpdateLifeEvent", 20)

if not getDailyLogin or not claimDailyLogin then
	warn("[MobileDailyLoginPanel] Daily login remotes missing. UI skipped.")
	return { init = function() end }
end

local GUI_NAME = "BitKaisenMobileDailyLoginGui"
local TWEEN_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local state = {
	Data = nil,
	Open = false,
	Busy = false,
	HasAutoOpened = false,
}

local gui: ScreenGui
local sheet: Frame
local scroll: ScrollingFrame
local streakLabel: TextLabel
local bestLabel: TextLabel
local todayLabel: TextLabel
local statusLabel: TextLabel
local claimBtn: TextButton
local rewardCards: { [number]: { card: Frame, stroke: UIStroke, day: TextLabel, name: TextLabel, short: TextLabel } } = {}

local function formatRewardShort(reward): string
	if typeof(reward) ~= "table" then return "Reward" end
	return tostring(reward.Short or reward.Name or "Reward")
end

local function fetchDailyLogin()
	local ok, result = pcall(function()
		return getDailyLogin:InvokeServer()
	end)
	if ok and typeof(result) == "table" then
		state.Data = result
		return result
	end
	warn("[MobileDailyLoginPanel] GetDailyLogin failed:", result)
	return nil
end

local function setClaimButton(canClaim: boolean)
	if not claimBtn then return end
	if state.Busy then
		claimBtn.Text = "CLAIMING..."
		claimBtn.Active = false
		claimBtn.BackgroundColor3 = theme.Stroke
		claimBtn.TextColor3 = theme.Muted
		return
	end
	if canClaim then
		claimBtn.Text = "CLAIM DAILY REWARD"
		claimBtn.Active = true
		claimBtn.BackgroundColor3 = theme.Purple
		claimBtn.TextColor3 = theme.Text
	else
		claimBtn.Text = "ALREADY CLAIMED"
		claimBtn.Active = false
		claimBtn.BackgroundColor3 = theme.Stroke
		claimBtn.TextColor3 = theme.Muted
	end
end

local function render(data)
	data = data or state.Data
	if typeof(data) ~= "table" then return end
	state.Data = data

	local canClaim = data.CanClaim == true
	local streak = tonumber(data.Streak) or 0
	local bestStreak = tonumber(data.BestStreak) or 0
	local totalClaims = tonumber(data.TotalClaims) or 0
	local nextStreak = tonumber(data.NextStreak) or math.max(1, streak)
	local nextReward = data.NextReward

	if streakLabel then
		streakLabel.Text = "Streak: " .. tostring(streak)
	end
	if bestLabel then
		bestLabel.Text = "Best: " .. tostring(bestStreak) .. "  •  Claims: " .. tostring(totalClaims)
	end
	if todayLabel then
		todayLabel.Text = "Today's reward: " .. formatRewardShort(nextReward)
	end
	if statusLabel then
		if canClaim then
			statusLabel.Text = "Ready to claim Day " .. tostring(((nextStreak - 1) % 7) + 1) .. "."
		else
			statusLabel.Text = "Already claimed today. Come back tomorrow."
		end
	end

	local rewards = typeof(data.Rewards) == "table" and data.Rewards or {}
	local activeDay = ((math.max(1, nextStreak) - 1) % 7) + 1

	for i = 1, 7 do
		local refs = rewardCards[i]
		if refs then
			local reward = rewards[i]
			refs.day.Text = "DAY " .. tostring(i)
			refs.name.Text = reward and tostring(reward.Name or "Reward") or "Reward"
			refs.short.Text = reward and tostring(reward.Short or "+???") or "+???"

			if i == activeDay and canClaim then
				refs.card.BackgroundColor3 = Color3.fromRGB(31, 25, 44)
				refs.stroke.Color = theme.Gold
				refs.stroke.Thickness = 2
			elseif i == activeDay then
				refs.card.BackgroundColor3 = Color3.fromRGB(26, 25, 34)
				refs.stroke.Color = theme.Purple
				refs.stroke.Thickness = 1
			else
				refs.card.BackgroundColor3 = theme.Card
				refs.stroke.Color = theme.Stroke
				refs.stroke.Thickness = 1
			end
		end
	end

	setClaimButton(canClaim)
end

local function doClose()
	state.Open = false
	sheet.Visible = false
	gui.Enabled = false
end

local function doOpen()
	gui.Enabled = true
	sheet.Visible = true
	sheet.BackgroundTransparency = 0
end

local function openPanel(autoOpen: boolean?)
	if state.Open then return end
	state.Open = true

	local data = fetchDailyLogin()
	render(data)

	overlayManager.show("daily_login", doOpen, doClose)
end

local function closePanel()
	if not state.Open then return end
	doClose()
	overlayManager.closeAll()
end

local function makeRewardCard(parent: GuiObject, index: number)
	local card = Instance.new("Frame")
	card.Name = "Day" .. tostring(index)
	card.Size = UDim2.new(1, 0, 0, 72)
	card.BackgroundColor3 = theme.Card
	card.BorderSizePixel = 0
	card.LayoutOrder = index
	card.Parent = parent
	mc.corner(card, 10)
	local s = mc.stroke(card, theme.Stroke)

	local dayLabel = Instance.new("TextLabel")
	dayLabel.Size = UDim2.new(0, 60, 1, 0)
	dayLabel.Position = UDim2.fromOffset(12, 0)
	dayLabel.BackgroundTransparency = 1
	dayLabel.Text = "DAY " .. tostring(index)
	dayLabel.TextColor3 = theme.Gold
	dayLabel.TextSize = 14
	dayLabel.Font = Enum.Font.GothamBlack
	dayLabel.TextXAlignment = Enum.TextXAlignment.Left
	dayLabel.Parent = card

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -160, 1, -8)
	nameLabel.Position = UDim2.new(0, 80, 0, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "Reward"
	nameLabel.TextColor3 = theme.Text
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextWrapped = true
	nameLabel.Parent = card

	local shortLabel = Instance.new("TextLabel")
	shortLabel.Size = UDim2.new(0, 70, 1, 0)
	shortLabel.AnchorPoint = Vector2.new(1, 0)
	shortLabel.Position = UDim2.new(1, -12, 0, 0)
	shortLabel.BackgroundTransparency = 1
	shortLabel.Text = "+???"
	shortLabel.TextColor3 = theme.Green
	shortLabel.TextSize = 14
	shortLabel.Font = Enum.Font.GothamBlack
	shortLabel.TextXAlignment = Enum.TextXAlignment.Right
	shortLabel.Parent = card

	rewardCards[index] = {
		card = card,
		stroke = s,
		day = dayLabel,
		name = nameLabel,
		short = shortLabel,
	}
end

local function buildUI()
	local existing = playerGui:FindFirstChild(GUI_NAME)
	if existing then existing:Destroy() end

	gui = Instance.new("ScreenGui")
	gui.Name = GUI_NAME
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 636
	gui.Enabled = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	sheet = mc.mobileSheet({
		name = "MobileDailyLoginSheet",
		parent = gui,
		title = "DAILY LOGIN",
		onClose = closePanel,
	})

	scroll = sheet:FindFirstChildWhichIsA("ScrollingFrame") :: ScrollingFrame

	-- Status card
	local statusCard = mc.mobileCard({ parent = scroll, order = 0, accentColor = theme.Gold })

	streakLabel = mc.mobileLabel({
		parent = statusCard,
		text = "Streak: 0",
		size = 16,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	bestLabel = mc.mobileLabel({
		parent = statusCard,
		text = "Best: 0  •  Claims: 0",
		size = 13,
		color = theme.SubText,
		font = Enum.Font.GothamBold,
		order = 2,
	})

	todayLabel = mc.mobileLabel({
		parent = statusCard,
		text = "Today's reward: loading...",
		size = 14,
		color = theme.Text,
		font = Enum.Font.GothamBold,
		order = 3,
	})

	statusLabel = mc.mobileLabel({
		parent = statusCard,
		text = "",
		size = 13,
		color = theme.SubText,
		order = 4,
	})

	-- Reward day cards
	for i = 1, 7 do
		makeRewardCard(scroll, i)
	end

	-- Claim button at bottom of scroll
	claimBtn = mc.mobileButton({
		parent = scroll,
		text = "CLAIM DAILY REWARD",
		size = UDim2.new(1, 0, 0, 50),
		color = theme.Purple,
		textSize = 16,
		order = 100,
		callback = function()
			if state.Busy then return end
			if not state.Data or state.Data.CanClaim ~= true then return end
			state.Busy = true
			setClaimButton(false)
			claimDailyLogin:FireServer()
		end,
	})
end

local function startupCheck(delayTime: number)
	task.delay(delayTime, function()
		if not gui or not gui.Parent then return end
		local data = fetchDailyLogin()
		render(data)
		if data and data.CanClaim == true and not state.HasAutoOpened and not state.Open then
			state.HasAutoOpened = true
			openPanel(true)
		end
	end)
end

local function init()
	buildUI()

	claimDailyLogin.OnClientEvent:Connect(function(result)
		state.Busy = false
		if typeof(result) == "table" and typeof(result.Data) == "table" then
			state.Data = result.Data
			render(result.Data)
		else
			local data = fetchDailyLogin()
			render(data)
		end
	end)

	if updateLifeEvent then
		updateLifeEvent.OnClientEvent:Connect(function(stats)
			if typeof(stats) ~= "table" or stats.Alive == false then return end
			startupCheck(0.75)
		end)
	end

	startupCheck(1.25)
	startupCheck(2.75)
end

return { init = init }
