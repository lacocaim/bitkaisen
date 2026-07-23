local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local uiState = require("@ui-state/uiState")
local overlayManager = require("@ui-state/overlayManager")
local mc = require("@ui/mobile/mobileComponents")
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _cw(key, fallback) return BitKaisenLocale.tOrFallback(_L, "clan_war." .. key, nil, fallback) end

local theme = mc.theme
local mobileButton = mc.mobileButton
local mobileCard = mc.mobileCard
local mobileLabel = mc.mobileLabel
local mobileSheet = mc.mobileSheet

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getClanWar = ReplicatedStorage:WaitForChild("GetClanWar")
local clanWarAction = ReplicatedStorage:WaitForChild("ClanWarAction")
local updateLifeEvent = ReplicatedStorage:WaitForChild("UpdateLifeEvent")

local closePanel: () -> ()

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenMobileClanWarGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 724
gui.Enabled = false
gui.Parent = playerGui

local sheet = mobileSheet({
	name = "MobileClanWarSheet",
	parent = gui,
	title = "CLAN WAR",
	onClose = function()
		closePanel()
		overlayManager.closeAll()
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
		return getClanWar:InvokeServer()
	end)
	payload = ok and typeof(data) == "table" and data or { Eligible = false, Active = false, History = {} }
	return payload
end

local function fire(actionId: string)
	clanWarAction:FireServer(actionId)
	task.delay(0.35, function()
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

local function makeTensionBar(parent: GuiObject, tension: number, order: number)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 22)
	container.BackgroundTransparency = 1
	container.LayoutOrder = order
	container.Parent = parent

	local barLabel = Instance.new("TextLabel")
	barLabel.Size = UDim2.new(1, 0, 0, 14)
	barLabel.BackgroundTransparency = 1
	barLabel.Text = _cw("tension", "Tension: {pct}%"):gsub("{pct}", tostring(tension))
	barLabel.TextColor3 = theme.SubText
	barLabel.TextSize = 11
	barLabel.Font = Enum.Font.GothamBold
	barLabel.TextXAlignment = Enum.TextXAlignment.Left
	barLabel.Parent = container

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 0, 8)
	bg.Position = UDim2.new(0, 0, 0, 14)
	bg.BackgroundColor3 = Color3.fromRGB(44, 41, 48)
	bg.BorderSizePixel = 0
	bg.Parent = container
	mc.corner(bg, 4)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(math.clamp(tension / 100, 0, 1), 1)
	fill.BackgroundColor3 = if tension >= 70 then theme.Bad elseif tension >= 35 then theme.Gold else theme.Green
	fill.BorderSizePixel = 0
	fill.Parent = bg
	mc.corner(fill, 4)

	return container
end

refresh = function()
	clear()
	local data = payload or fetch()

	if not data.Active and not data.Eligible then
		local emptyCard = mobileCard({ parent = scroll, order = 1 })
		mobileLabel({
			parent = emptyCard,
			text = _cw("no_war", "Your clan is not involved in any war and no rivals are pressing for conflict."),
			size = 14,
			color = theme.SubText,
			order = 1,
		})
		return
	end

	local tension = math.clamp(tonumber(data.Tension) or 0, 0, 100)
	local cooldown = math.max(0, tonumber(data.Cooldown) or 0)
	local canAct = data.CanAct ~= false and cooldown <= 0

	if data.Active then
		-- War status card
		local statusCard = mobileCard({ parent = scroll, order = 1, accentColor = theme.Bad })
		mobileLabel({
			parent = statusCard,
			text = tostring(data.PlayerClanName or "Your Clan") .. " vs " .. tostring(data.RivalClanName or "Rival Clan"),
			size = 17,
			color = theme.Gold,
			font = Enum.Font.GothamBlack,
			order = 1,
		})
		mobileLabel({
			parent = statusCard,
			text = _cw("phase", "Phase: {phase}  |  Battles: {wins}W / {losses}L"):gsub("{phase}", tostring(data.Phase or "Unknown")):gsub("{wins}", tostring(data.BattlesWon or 0)):gsub("{losses}", tostring(data.BattlesLost or 0)),
			size = 13,
			color = theme.Purple,
			font = Enum.Font.GothamBold,
			order = 2,
		})
		makeTensionBar(statusCard, tension, 3)
		mobileLabel({
			parent = statusCard,
			text = tostring(data.Description or _cw("description_def", "The clan war continues.")),
			size = 13,
			color = theme.SubText,
			order = 4,
		})
		if cooldown > 0 then
			mobileLabel({
				parent = statusCard,
				text = _cw("recovery", "Recovery: {cooldown} year(s) before the next clan move."):gsub("{cooldown}", tostring(cooldown)),
				size = 12,
				color = theme.Orange,
				order = 5,
			})
		end

		-- Action buttons
		local actionsCard = mobileCard({ parent = scroll, order = 2 })
		mobileLabel({ parent = actionsCard, text = _cw("actions", "Actions"), size = 15, color = theme.Text, font = Enum.Font.GothamBold, order = 1 })
		if canAct then
			makeActionRow(actionsCard, {
				{ text = _cw("defend", "DEFEND"), color = theme.Blue, action = function() fire("ClanWar_Defend") end },
				{ text = _cw("strike", "STRIKE"), color = theme.Bad, action = function() fire("ClanWar_Strike") end },
			}, 2)
			makeActionRow(actionsCard, {
				{ text = _cw("negotiate", "NEGOTIATE"), color = theme.Green, action = function() fire("ClanWar_Negotiate") end },
				{ text = _cw("betray", "BETRAY"), color = theme.Purple, action = function() fire("ClanWar_Betray") end },
			}, 3)
		else
			mobileLabel({ parent = actionsCard, text = _cw("recovering", "Recovering - no actions available."), size = 13, color = theme.Muted, order = 2 })
		end
	else
		-- Peacetime / eligible card
		local peaceCard = mobileCard({ parent = scroll, order = 1, accentColor = theme.Gold })
		mobileLabel({
			parent = peaceCard,
			text = tostring(data.PlayerClanName or "Your Clan"),
			size = 17,
			color = theme.Gold,
			font = Enum.Font.GothamBlack,
			order = 1,
		})
		mobileLabel({
			parent = peaceCard,
			text = _cw("power_record", "Power: {power}  |  Record: {wins}W / {losses}L"):gsub("{power}", tostring(data.Power or 0)):gsub("{wins}", tostring(data.Wins or 0)):gsub("{losses}", tostring(data.Losses or 0)),
			size = 13,
			color = theme.SubText,
			order = 2,
		})
		mobileLabel({
			parent = peaceCard,
			text = _cw("peace_desc", "A rival clan can pressure you through yearly events, or you can provoke a conflict."),
			size = 13,
			color = theme.SubText,
			order = 3,
		})
		if cooldown > 0 then
			mobileLabel({
				parent = peaceCard,
				text = _cw("recovery", "Recovery: {cooldown} year(s) before the next clan move."):gsub("{cooldown}", tostring(cooldown)),
				size = 12,
				color = theme.Orange,
				order = 4,
			})
		end

		-- Provoke button
		local actionsCard = mobileCard({ parent = scroll, order = 2 })
		if cooldown <= 0 then
			mobileButton({
				parent = actionsCard,
				text = _cw("provoke", "PROVOKE RIVAL"),
				color = theme.Bad,
				textSize = 14,
				order = 1,
				callback = function() fire("ClanWar_Start") end,
			})
		else
			mobileLabel({ parent = actionsCard, text = _cw("cannot_provoke", "Recovering - cannot provoke yet."), size = 13, color = theme.Muted, order = 1 })
		end
	end

	-- History card
	local historyCard = mobileCard({ parent = scroll, order = 999 })
	mobileLabel({ parent = historyCard, text = _cw("war_history", "War History"), size = 15, color = theme.Text, font = Enum.Font.GothamBold, order = 1 })
	local history = data.History or {}
	if #history == 0 then
		mobileLabel({ parent = historyCard, text = _cw("no_history", "No clan war history yet."), size = 13, color = theme.SubText, order = 2 })
	else
		local lines = {}
		for i = #history, math.max(1, #history - 8), -1 do
			local entry = history[i]
			local prefix = entry.Year and (_cw("year_prefix", "Year {year}: "):gsub("{year}", tostring(entry.Year))) or ""
			table.insert(lines, prefix .. tostring(entry.Text or _cw("default_event", "Clan war event.")))
		end
		mobileLabel({ parent = historyCard, text = table.concat(lines, "\n"), size = 13, color = theme.SubText, order = 2 })
	end
end

local function openPanel()
	isOpen = true
	gui.Enabled = true
	sheet.Visible = true
	fetch()
	refresh()
end

closePanel = function()
	isOpen = false
	sheet.Visible = false
	gui.Enabled = false
end

local function init()
	uiState.subscribe(function(route)
		if route == "clanwar" then
			openPanel()
		else
			closePanel()
		end
	end)

	clanWarAction.OnClientEvent:Connect(function()
		task.delay(0.15, function()
			fetch()
			if isOpen then
				refresh()
			end
		end)
	end)

	updateLifeEvent.OnClientEvent:Connect(function()
		task.delay(0.2, function()
			fetch()
			if isOpen then
				refresh()
			end
		end)
	end)
end

local function isAvailable()
	local ok, data = pcall(function()
		return getClanWar:InvokeServer()
	end)
	if not ok or typeof(data) ~= "table" then return false end
	return data.Active == true or data.Eligible == true
end

return { init = init, open = openPanel, close = closePanel, isAvailable = isAvailable }
