local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GroupService = game:GetService("GroupService")

local uiState = require("@ui-state/uiState")
local mc = require("@ui/mobile/mobileComponents")

local theme = mc.theme
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local getFreeReward = ReplicatedStorage:WaitForChild("GetFreeReward", 20)
local claimFreeReward = ReplicatedStorage:WaitForChild("ClaimFreeReward", 20)

if not getFreeReward or not claimFreeReward then
	warn("[MobileFreeRewardsPanel] Free reward remotes missing. UI skipped.")
	return { init = function() end }
end

local GROUP_ID = 212374896

local state = {
	Liked = false,
	Payload = nil,
	Status = "",
}

local gui: ScreenGui
local sheet: Frame
local scroll: ScrollingFrame

local likeBtn: TextButton
local groupBtn: TextButton
local claimBtn: TextButton
local statusLabel: TextLabel

local function fetchPayload()
	local ok, payload = pcall(function()
		return getFreeReward:InvokeServer()
	end)
	if ok and typeof(payload) == "table" then
		state.Payload = payload
		if tonumber(payload.GroupId) then
			GROUP_ID = tonumber(payload.GroupId) :: number
		end
		return payload
	end
	state.Status = "Could not load free reward right now."
	return state.Payload
end

local function updateVisuals()
	if not likeBtn then return end

	local payload = state.Payload or {}
	local groupVerified = payload.GroupVerified == true
	local claimed = payload.Claimed == true

	likeBtn.Text = state.Liked and "LIKED ✓" or "👍  I LIKED THE GAME"
	likeBtn.BackgroundColor3 = state.Liked and Color3.fromRGB(28, 72, 45) or theme.Button

	groupBtn.Text = groupVerified and "JOINED ✓" or "👥  JOIN / CHECK GROUP"
	groupBtn.BackgroundColor3 = groupVerified and Color3.fromRGB(28, 72, 45) or theme.Button

	if claimed then
		claimBtn.Text = "CLAIMED"
		claimBtn.BackgroundColor3 = theme.Card
		statusLabel.TextColor3 = theme.Gold
		statusLabel.Text = "You already claimed this free reward."
	elseif state.Status ~= "" then
		claimBtn.Text = "VERIFY & CLAIM"
		claimBtn.BackgroundColor3 = Color3.fromRGB(28, 72, 45)
		statusLabel.TextColor3 = theme.SubText
		statusLabel.Text = state.Status
	else
		claimBtn.Text = "VERIFY & CLAIM"
		claimBtn.BackgroundColor3 = Color3.fromRGB(28, 72, 45)
		statusLabel.TextColor3 = theme.SubText
		statusLabel.Text = "Complete both steps, then verify to claim."
	end
end

local function clearList()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
end

local function refresh()
	clearList()
	fetchPayload()

	local rewardCard = mc.mobileCard({
		parent = scroll,
		accentColor = theme.Gold,
		order = 1,
	})

	mc.mobileLabel({
		parent = rewardCard,
		text = "🎁  FREE REWARD",
		size = 17,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	mc.mobileLabel({
		parent = rewardCard,
		text = "x2 Technique Mastery Boost (5 Minutes)",
		size = 14,
		color = theme.Text,
		font = Enum.Font.GothamBold,
		order = 2,
	})

	mc.mobileLabel({
		parent = rewardCard,
		text = "Claim a limited mastery boost after supporting the game.",
		size = 13,
		color = theme.SubText,
		order = 3,
	})

	local stepsCard = mc.mobileCard({
		parent = scroll,
		order = 2,
	})

	mc.mobileLabel({
		parent = stepsCard,
		text = "STEPS",
		size = 14,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	mc.mobileLabel({
		parent = stepsCard,
		text = "1. Like the game  •  2. Join our Roblox group",
		size = 13,
		color = theme.SubText,
		order = 2,
	})

	likeBtn = mc.mobileButton({
		parent = stepsCard,
		text = "👍  I LIKED THE GAME",
		size = UDim2.new(1, 0, 0, 48),
		color = theme.Button,
		textColor = theme.Text,
		textSize = 14,
		order = 3,
		callback = function()
			state.Liked = true
			state.Status = "Like confirmed. Join the group, then press VERIFY."
			updateVisuals()
		end,
	})

	groupBtn = mc.mobileButton({
		parent = stepsCard,
		text = "👥  JOIN / CHECK GROUP",
		size = UDim2.new(1, 0, 0, 48),
		color = theme.Button,
		textColor = theme.Text,
		textSize = 14,
		order = 4,
		callback = function()
			local ok, result = pcall(function()
				return GroupService:PromptJoinAsync(GROUP_ID)
			end)
			if ok and (result == Enum.GroupMembershipStatus.Joined or result == Enum.GroupMembershipStatus.AlreadyMember) then
				state.Status = "Group membership checked."
			else
				state.Status = "Join the group, then press this again to check."
			end
			fetchPayload()
			updateVisuals()
		end,
	})

	local claimCard = mc.mobileCard({
		parent = scroll,
		order = 3,
	})

	statusLabel = mc.mobileLabel({
		parent = claimCard,
		text = "Complete both steps, then verify to claim.",
		size = 13,
		color = theme.SubText,
		order = 1,
	})

	claimBtn = mc.mobileButton({
		parent = claimCard,
		text = "VERIFY & CLAIM",
		size = UDim2.new(1, 0, 0, 52),
		color = Color3.fromRGB(28, 72, 45),
		textColor = theme.Text,
		textSize = 15,
		order = 2,
		callback = function()
			local ok, result = pcall(function()
				return claimFreeReward:InvokeServer(state.Liked == true)
			end)
			if ok and typeof(result) == "table" then
				state.Status = tostring(result.Message or "")
				if typeof(result.Payload) == "table" then
					state.Payload = result.Payload
				else
					fetchPayload()
				end
			else
				state.Status = "Could not claim right now."
				fetchPayload()
			end
			updateVisuals()
		end,
	})

	updateVisuals()
end

local function openPanel()
	gui.Enabled = true
	refresh()
end

local function closePanel()
	gui.Enabled = false
end

local function init()
	gui = Instance.new("ScreenGui")
	gui.Name = "BitKaisenMobileFreeRewardsGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 636
	gui.Enabled = false
	gui.Parent = playerGui

	sheet = mc.mobileSheet({
		name = "MobileFreeRewardsSheet",
		parent = gui,
		title = "FREE REWARD",
		onClose = function()
			uiState.closeRoute()
		end,
	})

	scroll = sheet:FindFirstChildWhichIsA("ScrollingFrame") :: ScrollingFrame

	uiState.subscribe(function(route)
		if route == "free_rewards" then
			sheet.Visible = true
			openPanel()
		else
			sheet.Visible = false
			closePanel()
		end
	end)
end

return { init = init }
