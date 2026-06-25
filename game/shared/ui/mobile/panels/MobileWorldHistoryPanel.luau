local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local uiState = require("@ui-state/uiState")
local mc = require("@ui/mobile/mobileComponents")

local theme = mc.theme
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local getWorldHistory = ReplicatedStorage:WaitForChild("GetWorldHistory")
local getTitles = ReplicatedStorage:WaitForChild("GetTitles")

local gui: ScreenGui
local sheet: Frame
local scroll: ScrollingFrame
local headerFrame: Frame

local activeTab = "history"
local historyTabBtn: TextButton
local titlesTabBtn: TextButton

local function clearList()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
end

local function updateTabStyles()
	if activeTab == "history" then
		historyTabBtn.BackgroundColor3 = theme.Button
		historyTabBtn.TextColor3 = theme.Gold
		titlesTabBtn.BackgroundColor3 = theme.Panel
		titlesTabBtn.TextColor3 = theme.SubText
	else
		historyTabBtn.BackgroundColor3 = theme.Panel
		historyTabBtn.TextColor3 = theme.SubText
		titlesTabBtn.BackgroundColor3 = theme.Button
		titlesTabBtn.TextColor3 = theme.Gold
	end
end

local function renderHistory()
	clearList()
	activeTab = "history"
	updateTabStyles()

	local ok, data = pcall(function()
		return getWorldHistory:InvokeServer()
	end)

	if not ok or typeof(data) ~= "table" then
		local errCard = mc.mobileCard({ parent = scroll, order = 1 })
		mc.mobileLabel({
			parent = errCard,
			text = "Could not load world history.",
			size = 14,
			color = theme.Bad,
			font = Enum.Font.GothamBold,
		})
		return
	end

	local summary = data.Summary or {}

	local sumCard = mc.mobileCard({ parent = scroll, order = 1, accentColor = theme.Gold })
	mc.mobileLabel({
		parent = sumCard,
		text = "Era: " .. tostring(summary.Era or "Unknown"),
		size = 15,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})
	mc.mobileLabel({
		parent = sumCard,
		text = "World Events: " .. tostring(summary.WorldEvents or 0) .. "  •  Notable Births: " .. tostring(summary.NotableBirths or 0),
		size = 13,
		color = theme.SubText,
		order = 2,
	})
	mc.mobileLabel({
		parent = sumCard,
		text = "Strongest Sorcerer: " .. tostring(summary.StrongestSorcerer or "Unknown"),
		size = 13,
		color = theme.Blue,
		order = 3,
	})

	local equippedTool = summary.EquippedCursedToolName or summary.EquippedCursedToolId or "None"
	mc.mobileLabel({
		parent = sumCard,
		text = "Cursed Tools: " .. tostring(summary.CursedToolsOwned or 0) .. "  •  Equipped: " .. tostring(equippedTool),
		size = 13,
		color = theme.SubText,
		order = 4,
	})

	local clanWarText = "Clan Wars: " .. tostring(summary.ClanWarWins or 0) .. "W / " .. tostring(summary.ClanWarLosses or 0) .. "L"
	if summary.ClanWarActive == true then
		clanWarText ..= "\nActive vs " .. tostring(summary.ClanWarRival or "Rival Clan") .. " (" .. tostring(summary.ClanWarTension or 0) .. "% tension)"
	end
	mc.mobileLabel({
		parent = sumCard,
		text = clanWarText,
		size = 13,
		color = theme.Muted,
		order = 5,
	})

	local history = data.History or {}
	for i, entry in ipairs(history) do
		local evCard = mc.mobileCard({ parent = scroll, order = i + 1 })

		mc.mobileLabel({
			parent = evCard,
			text = tostring(entry.Year or "?") .. "  •  " .. tostring(entry.Type or "World"),
			size = 14,
			color = theme.Blue,
			font = Enum.Font.GothamBlack,
			order = 1,
		})
		mc.mobileLabel({
			parent = evCard,
			text = tostring(entry.Text or "Unknown event"),
			size = 14,
			color = theme.Text,
			order = 2,
		})
	end
end

local function renderTitles()
	clearList()
	activeTab = "titles"
	updateTabStyles()

	local ok, data = pcall(function()
		return getTitles:InvokeServer()
	end)

	if not ok or typeof(data) ~= "table" then
		local errCard = mc.mobileCard({ parent = scroll, order = 1 })
		mc.mobileLabel({
			parent = errCard,
			text = "Could not load titles.",
			size = 14,
			color = theme.Bad,
			font = Enum.Font.GothamBold,
		})
		return
	end

	for i, item in ipairs(data.Titles or {}) do
		local unlocked = item.Unlocked == true
		local accentColor = if unlocked then theme.Green else theme.Stroke

		local card = mc.mobileCard({ parent = scroll, order = i, accentColor = accentColor })

		mc.mobileLabel({
			parent = card,
			text = tostring(item.Name or "???"),
			size = 15,
			color = if unlocked then theme.Green else theme.SubText,
			font = Enum.Font.GothamBlack,
			order = 1,
		})
		mc.mobileLabel({
			parent = card,
			text = if unlocked then "Unlocked" else "Locked",
			size = 13,
			color = if unlocked then theme.Green else theme.Bad,
			font = Enum.Font.GothamBold,
			order = 2,
		})
		mc.mobileLabel({
			parent = card,
			text = tostring(item.Requirement or "Requirement hidden."),
			size = 13,
			color = theme.SubText,
			order = 3,
		})
	end
end

local function buildTabBar()
	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(1, -20, 0, 46)
	tabBar.Position = UDim2.new(0, 10, 0, 0)
	tabBar.BackgroundTransparency = 1
	tabBar.LayoutOrder = -1
	tabBar.Parent = scroll

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.Parent = tabBar

	historyTabBtn = mc.mobileButton({
		parent = tabBar,
		text = "HISTORY",
		size = UDim2.new(0.5, -4, 0, 44),
		position = UDim2.new(0, 0, 0, 0),
		color = theme.Button,
		textColor = theme.Gold,
		textSize = 14,
		order = 1,
		callback = function()
			if activeTab ~= "history" then renderHistory() end
		end,
	})

	titlesTabBtn = mc.mobileButton({
		parent = tabBar,
		text = "TITLES",
		size = UDim2.new(0.5, -4, 0, 44),
		position = UDim2.new(0, 0, 0, 0),
		color = theme.Panel,
		textColor = theme.SubText,
		textSize = 14,
		order = 2,
		callback = function()
			if activeTab ~= "titles" then renderTitles() end
		end,
	})
end

local function openPanel()
	gui.Enabled = true
	activeTab = "history"
	buildTabBar()
	renderHistory()
end

local function closePanel()
	gui.Enabled = false
	clearList()
end

local function init()
	gui = Instance.new("ScreenGui")
	gui.Name = "BitKaisenMobileWorldHistoryGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 625
	gui.Enabled = false
	gui.Parent = playerGui

	sheet = mc.mobileSheet({
		name = "MobileWorldHistorySheet",
		parent = gui,
		title = "WORLD HISTORY",
		onClose = function()
			uiState.closeRoute()
		end,
	})

	scroll = sheet:FindFirstChildWhichIsA("ScrollingFrame") :: ScrollingFrame

	uiState.subscribe(function(route)
		if route == "history" then
			sheet.Visible = true
			openPanel()
		else
			sheet.Visible = false
			closePanel()
		end
	end)
end

return { init = init }
