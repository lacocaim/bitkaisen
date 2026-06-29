local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local uiState = require("@ui-state/uiState")
local mc = require("@ui/mobile/mobileComponents")

local theme = mc.theme
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local getChallenges
local challengeCompletedEvent

local CATEGORY_COLOR = {
	Life        = Color3.fromRGB(122, 236, 165),
	Combat      = Color3.fromRGB(220, 84, 90),
	Social      = Color3.fromRGB(255, 120, 190),
	Missions    = Color3.fromRGB(255, 205, 92),
	Influence   = Color3.fromRGB(180, 130, 255),
	Assets      = Color3.fromRGB(255, 205, 92),
	Affiliation = Color3.fromRGB(116, 190, 255),
	Vows        = Color3.fromRGB(220, 180, 255),
}

local gui: ScreenGui
local sheet: Frame
local scroll: ScrollingFrame

local loaded = false
local resetsInSeconds = 0
local timerConn = nil

local function formatTime(secs)
	secs = math.max(0, math.floor(secs))
	local d = math.floor(secs / 86400)
	local h = math.floor((secs % 86400) / 3600)
	local m = math.floor((secs % 3600) / 60)
	if d > 0 then
		return string.format("Resets in %dd %dh", d, h)
	elseif h > 0 then
		return string.format("Resets in %dh %dm", h, m)
	else
		return string.format("Resets in %dm", m)
	end
end

local function clearList()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
end

local function createChallengeCard(challenge, order: number, isCompleted: boolean)
	local accent = CATEGORY_COLOR[challenge.Category] or theme.Blue

	local card = mc.mobileCard({
		parent = scroll,
		accentColor = isCompleted and Color3.fromRGB(122, 236, 165) or accent,
		order = order,
	})

	if isCompleted then
		mc.mobileLabel({
			parent = card,
			text = "✓  COMPLETED",
			size = 13,
			color = Color3.fromRGB(122, 236, 165),
			font = Enum.Font.GothamBlack,
			order = 0,
		})
	end

	mc.mobileLabel({
		parent = card,
		text = challenge.Title,
		size = 15,
		color = isCompleted and Color3.fromRGB(160, 160, 175) or theme.Text,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	mc.mobileLabel({
		parent = card,
		text = string.upper(challenge.Category),
		size = 10,
		color = isCompleted and Color3.fromRGB(120, 120, 140) or accent,
		font = Enum.Font.GothamBold,
		order = 2,
	})

	mc.mobileLabel({
		parent = card,
		text = challenge.Desc,
		size = 12,
		color = theme.SubText,
		order = 3,
	})

	mc.mobileLabel({
		parent = card,
		text = "Goal: " .. challenge.Goal .. "   •   Reward: " .. challenge.Reward,
		size = 12,
		color = isCompleted and Color3.fromRGB(120, 120, 140) or (theme.Gold or Color3.fromRGB(255, 205, 92)),
		font = Enum.Font.GothamBold,
		order = 4,
	})

	return card
end

local function refresh()
	if loaded then return end
	loaded = true
	clearList()

	local card = mc.mobileCard({ parent = scroll, order = 1 })
	mc.mobileLabel({
		parent = card,
		text = "Loading challenges...",
		size = 13,
		color = theme.SubText,
		font = Enum.Font.GothamMedium,
	})

	task.spawn(function()
		local ok, result = pcall(function()
			return getChallenges:InvokeServer()
		end)

		clearList()

		if not ok or not result or not result.Challenges then
			local errCard = mc.mobileCard({ parent = scroll, order = 1 })
			mc.mobileLabel({
				parent = errCard,
				text = "Could not load challenges.\nTry again later.",
				size = 13,
				color = theme.SubText,
			})
			return
		end

		resetsInSeconds = result.ResetsIn or 0

		if timerConn then timerConn:Disconnect() timerConn = nil end

		if #result.Challenges == 0 then
			local emptyCard = mc.mobileCard({ parent = scroll, order = 1 })
			mc.mobileLabel({
				parent = emptyCard,
				text = "No challenges this week.",
				size = 13,
				color = theme.SubText,
			})
			return
		end

		local completedIds = result.CompletedIds or {}
		for i, ch in ipairs(result.Challenges) do
			createChallengeCard(ch, i, completedIds[ch.Id] == true)
		end
	end)
end

local function openPanel()
	gui.Enabled = true
	refresh()
end

local function closePanel()
	gui.Enabled = false
	if timerConn then timerConn:Disconnect() timerConn = nil end
	loaded = false
end

local function init()
	getChallenges = ReplicatedStorage:WaitForChild("GetChallenges", 10)
	challengeCompletedEvent = ReplicatedStorage:FindFirstChild("ChallengeCompleted")

	gui = Instance.new("ScreenGui")
	gui.Name = "BitKaisenMobileWeeklyGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 618
	gui.Enabled = false
	gui.Parent = playerGui

	sheet = mc.mobileSheet({
		name = "MobileWeeklySheet",
		parent = gui,
		title = "WEEKLY",
		onClose = function()
			uiState.closeRoute()
		end,
	})

	scroll = sheet:FindFirstChildWhichIsA("ScrollingFrame") :: ScrollingFrame

	uiState.subscribe(function(route)
		if route == "weekly" then
			sheet.Visible = true
			openPanel()
		else
			sheet.Visible = false
			closePanel()
		end
	end)

	-- If panel is open when a challenge completes, refresh the list
	if challengeCompletedEvent then
		challengeCompletedEvent.OnClientEvent:Connect(function()
			if gui.Enabled then
				loaded = false
				clearList()
				refresh()
			end
		end)
	end
end

return { init = init }
