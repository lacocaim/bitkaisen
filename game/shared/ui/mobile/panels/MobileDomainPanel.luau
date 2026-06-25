local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local uiState = require("@ui-state/uiState")
local mc = require("@ui/mobile/mobileComponents")

local theme = mc.theme
local mobileButton = mc.mobileButton
local mobileCard = mc.mobileCard
local mobileLabel = mc.mobileLabel
local mobileSheet = mc.mobileSheet

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getDomain = ReplicatedStorage:WaitForChild("GetDomain")
local domainAction = ReplicatedStorage:WaitForChild("DomainAction")

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenMobileDomainGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 624
gui.Enabled = false
gui.Parent = playerGui

local sheet = mobileSheet({
	name = "DomainSheet",
	parent = gui,
	title = "DOMAIN EXPANSION",
	onClose = function()
		uiState.closeRoute()
	end,
})

local scroll = sheet:FindFirstChildWhichIsA("ScrollingFrame")
local isOpen = false

local function clear()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = scroll

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 16)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = scroll
end

local function progressBar(parent: GuiObject, progress: number, order: number)
	local wrapper = Instance.new("Frame")
	wrapper.Size = UDim2.new(1, 0, 0, 18)
	wrapper.BackgroundTransparency = 1
	wrapper.LayoutOrder = order
	wrapper.Parent = parent

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 0, 12)
	bg.Position = UDim2.new(0, 0, 0, 3)
	bg.BackgroundColor3 = Color3.fromRGB(43, 39, 54)
	bg.BorderSizePixel = 0
	bg.Parent = wrapper
	mc.corner(bg, 999)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(math.clamp(progress / 100, 0, 1), 0, 1, 0)
	fill.BackgroundColor3 = theme.Purple
	fill.BorderSizePixel = 0
	fill.Parent = bg
	mc.corner(fill, 999)
end

local function refresh()
	clear()

	local ok, data = pcall(function()
		return getDomain:InvokeServer()
	end)

	if not ok or typeof(data) ~= "table" then
		local errCard = mobileCard({ parent = scroll, order = 1 })
		mobileLabel({ parent = errCard, text = "Could not load domain data.", size = 14, color = theme.Bad, order = 1 })
		return
	end

	local domain = data.Domain or {}
	local progress = tonumber(domain.Progress) or 0

	-- Domain overview card
	local overviewCard = mobileCard({ parent = scroll, accentColor = theme.Purple, order = 1 })

	mobileLabel({
		parent = overviewCard,
		text = tostring(domain.Name or "Unknown Domain"),
		size = 16,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	mobileLabel({
		parent = overviewCard,
		text = "Stage: " .. tostring(domain.Stage or "Locked") .. "  |  Type: " .. tostring(domain.Type or "Personal Barrier"),
		size = 13,
		color = theme.Purple,
		font = Enum.Font.GothamBold,
		order = 2,
	})

	mobileLabel({
		parent = overviewCard,
		text = "Technique: " .. tostring(data.Technique or "None") .. "\nStability: " .. tostring(domain.Stability or 0) .. "%  |  Cost: " .. tostring(domain.Cost or 0) .. " CE",
		size = 13,
		color = theme.SubText,
		order = 3,
	})

	progressBar(overviewCard, progress, 4)

	mobileLabel({
		parent = overviewCard,
		text = tostring(progress) .. "/100 Domain Progress",
		size = 13,
		color = theme.Text,
		font = Enum.Font.GothamBold,
		order = 5,
	})

	-- Training card
	local domainTrainingUsed = tonumber(data.DomainTrainingThisAge) or 0
	local domainTrainingMax = tonumber(data.DomainTrainingMax) or 3
	local trainCard = mobileCard({ parent = scroll, order = 2 })

	mobileLabel({
		parent = trainCard,
		text = "Domain Training",
		size = 15,
		color = theme.Text,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	mobileLabel({
		parent = trainCard,
		text = tostring(data.TrainReason or "Shape your innate territory and raise Domain progress.")
			.. " (" .. tostring(domainTrainingUsed) .. "/" .. tostring(domainTrainingMax) .. " this age)",
		size = 13,
		color = if data.CanTrain then theme.SubText else theme.Bad,
		order = 2,
	})

	mobileButton({
		parent = trainCard,
		text = "TRAIN",
		size = UDim2.new(1, 0, 0, 46),
		color = if data.CanTrain then theme.Purple else Color3.fromRGB(60, 54, 72),
		textSize = 14,
		order = 3,
		callback = function()
			domainAction:FireServer("train")
			task.delay(0.3, function()
				if isOpen then refresh() end
			end)
		end,
	})

	mobileButton({
		parent = trainCard,
		text = "STABILIZE  $2500",
		size = UDim2.new(1, 0, 0, 46),
		color = theme.Blue,
		textSize = 14,
		order = 4,
		callback = function()
			domainAction:FireServer("stabilize")
			task.delay(0.3, function()
				if isOpen then refresh() end
			end)
		end,
	})

	-- Combat effects card
	local combatCard = mobileCard({ parent = scroll, order = 3 })

	mobileLabel({
		parent = combatCard,
		text = "Combat Effects",
		size = 15,
		color = theme.Text,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	mobileLabel({
		parent = combatCard,
		text = "Incomplete Domain unlocks a high-cost combat finisher. Complete Domain hits harder and performs better during clashes.",
		size = 13,
		color = theme.SubText,
		order = 2,
	})

	mobileLabel({
		parent = combatCard,
		text = "Clashes: " .. tostring(data.ClashesWon or 0) .. "W / " .. tostring(data.ClashesLost or 0) .. "L  |  Simple Domain: " .. tostring(data.SimpleDomainProgress or 0) .. "%",
		size = 13,
		color = theme.Green,
		font = Enum.Font.GothamBold,
		order = 3,
	})

	-- Milestones card
	local req = data.Requirements or {}
	local milestonesCard = mobileCard({ parent = scroll, order = 4 })

	mobileLabel({
		parent = milestonesCard,
		text = "Milestones",
		size = 15,
		color = theme.Text,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	mobileLabel({
		parent = milestonesCard,
		text = "Seed: " .. tostring(req.Seed or 20) .. "  |  Incomplete: " .. tostring(req.Incomplete or 55) .. "  |  Full Expansion: " .. tostring(req.Complete or 100),
		size = 13,
		color = theme.Gold,
		font = Enum.Font.GothamBold,
		order = 2,
	})

	mobileLabel({
		parent = milestonesCard,
		text = "Progress comes from domain training, dangerous combat, near-death losses, and Domain clashes.",
		size = 13,
		color = theme.SubText,
		order = 3,
	})
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

local function init()
	uiState.subscribe(function(route)
		if route == "domain" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
