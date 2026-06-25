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
local getRivals = ReplicatedStorage:WaitForChild("GetRivals")
local rivalAction = ReplicatedStorage:WaitForChild("RivalAction")

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenMobileRivalsGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 723
gui.Enabled = false
gui.Parent = playerGui

local sheet = mobileSheet({
	name = "MobileRivalsSheet",
	parent = gui,
	title = "RIVALS",
	onClose = function()
		uiState.closeRoute()
	end,
})

local scroll: ScrollingFrame = sheet:FindFirstChildOfClass("ScrollingFrame")

local isOpen = false
local payload = nil
local refresh: () -> ()

local function clear()
	for _, child in scroll:GetChildren() do
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

local function fetch()
	local ok, data = pcall(function()
		return getRivals:InvokeServer()
	end)
	payload = ok and typeof(data) == "table" and data or { Rivals = {}, History = {}, ReputationPath = "Unknown" }
	return payload
end

local function fire(actionId: string, rivalId: string)
	rivalAction:FireServer(actionId, { RivalId = rivalId })
	task.delay(0.3, function()
		fetch()
		if isOpen then
			refresh()
		end
	end)
end

local function makeActionRow(parent: GuiObject, actions: { { text: string, color: Color3, action: () -> () } }, order: number)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 44)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.Parent = parent

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Padding = UDim.new(0, 6)
	rowLayout.Parent = row

	for i, act in actions do
		mobileButton({
			parent = row,
			text = act.text,
			size = UDim2.new(1 / #actions, -(6 * (#actions - 1)) / #actions, 0, 44),
			position = UDim2.new(0, 0, 0, 0),
			color = act.color,
			textSize = 13,
			order = i,
			callback = act.action,
		})
	end

	return row
end

refresh = function()
	clear()
	local data = payload or fetch()

	-- Summary card
	local summaryCard = mobileCard({ parent = scroll, order = 1, accentColor = theme.Gold })
	mobileLabel({ parent = summaryCard, text = "Reputation: " .. tostring(data.ReputationPath or "Unknown"), size = 16, color = theme.Gold, font = Enum.Font.GothamBlack, order = 1 })
	mobileLabel({
		parent = summaryCard,
		text = "Fame " .. tostring(data.Fame or 0) .. "  |  Fear " .. tostring(data.Fear or 0) .. "  |  Wanted " .. tostring(data.WantedLevel or 0),
		size = 13,
		color = theme.SubText,
		order = 2,
	})
	mobileLabel({
		parent = summaryCard,
		text = "Hunter Pressure " .. tostring(data.HunterPressure or 0) .. "  |  Public Support " .. tostring(data.PublicSupport or 0),
		size = 13,
		color = theme.SubText,
		order = 3,
	})
	local stats = data.Stats or {}
	mobileLabel({
		parent = summaryCard,
		text = "Encounters " .. tostring(stats.Encounters or 0) .. "  |  Defeated " .. tostring(stats.Defeated or 0) .. "  |  Losses " .. tostring(stats.Losses or 0) .. "  |  Escapes " .. tostring(stats.Escapes or 0),
		size = 13,
		color = theme.Green,
		font = Enum.Font.GothamBold,
		order = 4,
	})

	if data.Debug then
		mobileButton({
			parent = summaryCard,
			text = "TEST RIVAL",
			color = theme.Purple,
			textSize = 14,
			order = 5,
			callback = function()
				rivalAction:FireServer("generate_test_rival", {})
				task.delay(0.3, function()
					fetch()
					if isOpen then
						refresh()
					end
				end)
			end,
		})
	end

	-- Pending encounter
	local pending = data.PendingEncounter
	if pending then
		local encounterCard = mobileCard({ parent = scroll, order = 2, color = Color3.fromRGB(35, 20, 25), accentColor = theme.Orange })
		mobileLabel({ parent = encounterCard, text = "ACTIVE ENCOUNTER", size = 15, color = theme.Orange, font = Enum.Font.GothamBlack, order = 1 })
		mobileLabel({
			parent = encounterCard,
			text = tostring(pending.Name) .. "  |  " .. tostring(pending.Grade) .. "  |  Threat " .. tostring(pending.Threat),
			size = 14,
			color = theme.Text,
			font = Enum.Font.GothamBold,
			order = 2,
		})
		mobileLabel({ parent = encounterCard, text = tostring(pending.Reason or "A rival stepped into your path."), size = 13, color = theme.SubText, order = 3 })
		makeActionRow(encounterCard, {
			{ text = "FIGHT", color = theme.Bad, action = function() fire("fight", pending.RivalId) end },
			{ text = "TALK", color = theme.Blue, action = function() fire("talk_down", pending.RivalId) end },
			{ text = "ESCAPE", color = theme.Purple, action = function() fire("escape", pending.RivalId) end },
		}, 4)
	end

	-- Rival cards
	local rivals = data.Rivals or {}
	if #rivals == 0 then
		local emptyCard = mobileCard({ parent = scroll, order = 10 })
		mobileLabel({
			parent = emptyCard,
			text = "No rivals yet. Fame, fear, clan wars, wanted level, and major combat can draw enemies into your era.",
			size = 14,
			color = theme.SubText,
			order = 1,
		})
	else
		for idx, rival in rivals do
			local rivalCard = mobileCard({ parent = scroll, order = 10 + idx })
			mobileLabel({ parent = rivalCard, text = tostring(rival.Name or "Unknown Rival"), size = 16, color = theme.Gold, font = Enum.Font.GothamBlack, order = 1 })
			mobileLabel({
				parent = rivalCard,
				text = tostring(rival.Grade or "Unknown") .. "  |  Age " .. tostring(rival.Age or "?") .. "  |  " .. tostring(rival.Clan or "No Clan") .. "  |  " .. tostring(rival.Status or "Active"),
				size = 13,
				color = theme.Purple,
				font = Enum.Font.GothamBold,
				order = 2,
			})
			mobileLabel({
				parent = rivalCard,
				text = "Technique: " .. tostring(rival.Technique or "Unknown") .. "  |  Threat: " .. tostring(rival.Threat or 0) .. "  |  Record: " .. tostring(rival.Wins or 0) .. "W / " .. tostring(rival.Losses or 0) .. "L",
				size = 13,
				color = theme.SubText,
				order = 3,
			})
			mobileLabel({
				parent = rivalCard,
				text = tostring(rival.Relationship or "Enemy") .. ": " .. tostring(rival.Reason or "watching your rise"),
				size = 13,
				color = theme.SubText,
				order = 4,
			})
			makeActionRow(rivalCard, {
				{ text = "INTEL", color = theme.Blue, action = function() fire("intel", rival.Id) end },
				{ text = "FIGHT", color = theme.Bad, action = function() fire("fight", rival.Id) end },
				{ text = "SPARE", color = theme.Green, action = function() fire("spare", rival.Id) end },
				{ text = "HUMILIATE", color = theme.Orange, action = function() fire("humiliate", rival.Id) end },
			}, 5)
		end
	end

	-- History card
	local historyCard = mobileCard({ parent = scroll, order = 999 })
	mobileLabel({ parent = historyCard, text = "Rival History", size = 15, color = theme.Text, font = Enum.Font.GothamBold, order = 1 })
	local history = data.History or {}
	local lines = {}
	for i = 1, math.min(3, #history) do
		table.insert(lines, tostring(history[i]))
	end
	mobileLabel({
		parent = historyCard,
		text = #lines > 0 and table.concat(lines, "\n") or "No rival history yet.",
		size = 13,
		color = theme.SubText,
		order = 2,
	})
end

local function openPanel()
	isOpen = true
	gui.Enabled = true
	sheet.Visible = true
	fetch()
	refresh()
end

local function closePanel()
	isOpen = false
	sheet.Visible = false
	gui.Enabled = false
end

local function init()
	uiState.subscribe(function(route)
		if route == "rivals" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
