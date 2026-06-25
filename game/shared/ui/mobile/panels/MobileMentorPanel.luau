local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local uiState = require("@ui-state/uiState")
local mc = require("@ui/mobile/mobileComponents")

local theme = mc.theme

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getMentor = ReplicatedStorage:WaitForChild("GetMentor")
local mentorAction = ReplicatedStorage:WaitForChild("MentorAction")

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenMobileMentorGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 626
gui.Enabled = false
gui.Parent = playerGui

local sheet = mc.mobileSheet({
	name = "MentorSheet",
	parent = gui,
	title = "JUJUTSU MENTOR",
	onClose = function()
		uiState.closeRoute()
	end,
})

local scroll = sheet:FindFirstChild("Content") :: ScrollingFrame

local isOpen = false

local function clearContent()
	for _, child in scroll:GetChildren() do
		if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("Frame") then
			if child.Name ~= "UIListLayout" then
				child:Destroy()
			end
		end
	end
end

local function addStatusCard(payload)
	local card = mc.mobileCard({ parent = scroll, order = 1, accentColor = theme.Blue })

	mc.mobileLabel({
		parent = card,
		text = "Status",
		size = 13,
		color = theme.SubText,
		font = Enum.Font.GothamMedium,
		order = 1,
	})

	mc.mobileLabel({
		parent = card,
		text = "<b>Active Jujutsu Mentor</b>",
		size = 16,
		color = theme.Blue,
		font = Enum.Font.GothamBold,
		order = 2,
	})
end

local function addRankCard(payload)
	local card = mc.mobileCard({ parent = scroll, order = 2, accentColor = theme.Gold })

	mc.mobileLabel({
		parent = card,
		text = "Mentor Rank",
		size = 13,
		color = theme.SubText,
		font = Enum.Font.GothamMedium,
		order = 1,
	})

	mc.mobileLabel({
		parent = card,
		text = "<b>" .. tostring(payload.MentorRank or "None") .. "</b>",
		size = 16,
		color = theme.Gold,
		font = Enum.Font.GothamBold,
		order = 2,
	})
end

local function addXPCard(payload)
	local card = mc.mobileCard({ parent = scroll, order = 3 })

	mc.mobileLabel({
		parent = card,
		text = "Mentor XP",
		size = 13,
		color = theme.SubText,
		font = Enum.Font.GothamMedium,
		order = 1,
	})

	local xpText = "<b>" .. tostring(payload.MentorXP or 0) .. "</b>"
	if payload.NextRank then
		xpText ..= " / " .. tostring(payload.NextRank.MinXP) .. " for " .. payload.NextRank.Id
	else
		xpText ..= " (Max Rank)"
	end

	mc.mobileLabel({
		parent = card,
		text = xpText,
		size = 15,
		color = theme.Text,
		font = Enum.Font.GothamMedium,
		order = 2,
	})
end

local function addStatsCard(payload)
	local card = mc.mobileCard({ parent = scroll, order = 4 })

	mc.mobileLabel({
		parent = card,
		text = "Yearly Income",
		size = 13,
		color = theme.SubText,
		font = Enum.Font.GothamMedium,
		order = 1,
	})

	mc.mobileLabel({
		parent = card,
		text = "<b>$" .. tostring(payload.MentorIncome or 0) .. "</b>",
		size = 15,
		color = theme.Green,
		font = Enum.Font.GothamBold,
		order = 2,
	})

	mc.mobileLabel({
		parent = card,
		text = "Students Mentored",
		size = 13,
		color = theme.SubText,
		font = Enum.Font.GothamMedium,
		order = 3,
	})

	mc.mobileLabel({
		parent = card,
		text = "<b>" .. tostring(payload.StudentsMentored or 0) .. "</b>",
		size = 15,
		color = theme.Text,
		font = Enum.Font.GothamBold,
		order = 4,
	})
end

local function addTipCard()
	local card = mc.mobileCard({ parent = scroll, order = 5 })

	mc.mobileLabel({
		parent = card,
		text = "Use <b>Mentor activities</b> in the Activities menu to earn XP and rank up.",
		size = 14,
		color = theme.SubText,
		font = Enum.Font.GothamMedium,
		order = 1,
	})
end

local function addNotMentorContent(payload)
	local card = mc.mobileCard({ parent = scroll, order = 1 })

	mc.mobileLabel({
		parent = card,
		text = "You are not a Jujutsu Mentor yet.",
		size = 15,
		color = theme.SubText,
		font = Enum.Font.GothamBold,
		order = 1,
	})

	if payload.CanApply then
		mc.mobileLabel({
			parent = card,
			text = "Requirements met! You can apply to become a Jujutsu Mentor.",
			size = 14,
			color = theme.Green,
			font = Enum.Font.GothamMedium,
			order = 2,
		})
	else
		mc.mobileLabel({
			parent = card,
			text = "Cannot apply: " .. tostring(payload.ApplyReason or "Unknown reason."),
			size = 14,
			color = theme.SubText,
			font = Enum.Font.GothamMedium,
			order = 2,
		})

		mc.mobileLabel({
			parent = card,
			text = "Requirements: Graduate JJH, Age 20+, Grade 2+, recommendations.",
			size = 13,
			color = theme.Muted,
			font = Enum.Font.GothamMedium,
			order = 3,
		})
	end

	if payload.CanApply then
		mc.mobileButton({
			parent = scroll,
			text = "Apply to Become a Mentor",
			color = theme.Blue,
			textColor = theme.Text,
			textSize = 15,
			order = 2,
			callback = function()
				mentorAction:FireServer("apply")
			end,
		})
	end
end

local function refresh()
	local ok, payload = pcall(function()
		return getMentor:InvokeServer()
	end)

	if not ok or not payload then return end

	clearContent()

	if payload.IsMentor then
		addStatusCard(payload)
		addRankCard(payload)
		addXPCard(payload)
		addStatsCard(payload)
		addTipCard()
	else
		addNotMentorContent(payload)
	end
end

local function openPanel()
	isOpen = true
	sheet.Visible = true
	gui.Enabled = true
	refresh()
end

local function closePanel()
	isOpen = false
	sheet.Visible = false
	gui.Enabled = false
end

mentorAction.OnClientEvent:Connect(function()
	if isOpen then
		refresh()
	end
end)

local function init()
	uiState.subscribe(function(route)
		if route == "mentor" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
