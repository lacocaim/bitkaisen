local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local uiState = require("@ui-state/uiState")
local mc = require("@ui/mobile/mobileComponents")
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _h(key, fallback) return BitKaisenLocale.tOrFallback(_L, "history_ui." .. key, nil, fallback) end

local theme = mc.theme
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local getWorldHistory = ReplicatedStorage:WaitForChild("GetWorldHistory")
local getTitles = ReplicatedStorage:WaitForChild("GetTitles")
local getPastLives = ReplicatedStorage:WaitForChild("GetPastLives", 5)

local gui: ScreenGui
local sheet: Frame
local scroll: ScrollingFrame
local headerFrame: Frame

local RIBBON_COLORS = {
	["LEGEND OF THE CURSED WORLD"] = Color3.fromRGB(255, 200, 50),
	["SPECIAL GRADE SORCERER"] = Color3.fromRGB(220, 160, 255),
	["CURSE USER KING"] = Color3.fromRGB(200, 60, 80),
	["FEARED CURSE USER"] = Color3.fromRGB(180, 40, 60),
	["CURSE USER"] = Color3.fromRGB(200, 80, 90),
	["CURSED SPIRIT"] = Color3.fromRGB(140, 80, 200),
	["ELITE JUJUTSU SORCERER"] = Color3.fromRGB(120, 200, 255),
	["DOMAIN USER"] = Color3.fromRGB(140, 120, 255),
	["RCT PRACTITIONER"] = Color3.fromRGB(100, 220, 180),
	["CLAN FOUNDER"] = Color3.fromRGB(255, 180, 60),
	["DEEP BLOODLINE"] = Color3.fromRGB(180, 140, 255),
	["VETERAN SORCERER"] = Color3.fromRGB(120, 200, 140),
	["GRADE 1 SORCERER"] = Color3.fromRGB(100, 180, 255),
	["LONG LIFE"] = Color3.fromRGB(160, 160, 180),
	["LIFE CUT SHORT"] = Color3.fromRGB(180, 180, 200),
	["CELEBRATED SORCERER"] = Color3.fromRGB(255, 220, 80),
	["ORDINARY LIFE"] = Color3.fromRGB(140, 140, 160),
}

local activeTab = "history"
local rendering = false
local historyTabBtn: TextButton
local titlesTabBtn: TextButton
local livesTabBtn: TextButton
local influenceTabBtn: TextButton

local function clearList()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") and child.Name ~= "TabBar" then child:Destroy() end
	end
end

local function updateTabStyles()
	local active = { bg = theme.Button, text = theme.Gold }
	local inactive = { bg = theme.Panel, text = theme.SubText }
	local h = activeTab == "history" and active or inactive
	local t = activeTab == "titles" and active or inactive
	local l = activeTab == "lives" and active or inactive
	local inf = activeTab == "influence" and active or inactive
	historyTabBtn.BackgroundColor3 = h.bg; historyTabBtn.TextColor3 = h.text
	titlesTabBtn.BackgroundColor3 = t.bg; titlesTabBtn.TextColor3 = t.text
	if livesTabBtn then livesTabBtn.BackgroundColor3 = l.bg; livesTabBtn.TextColor3 = l.text end
	if influenceTabBtn then influenceTabBtn.BackgroundColor3 = inf.bg; influenceTabBtn.TextColor3 = inf.text end
end

local function renderHistory()
	rendering = true
	clearList()
	activeTab = "history"
	updateTabStyles()

	local ok, data = pcall(function()
		return getWorldHistory:InvokeServer()
	end)
	rendering = false

	if not ok or typeof(data) ~= "table" then
		local errCard = mc.mobileCard({ parent = scroll, order = 1 })
		mc.mobileLabel({
			parent = errCard,
			text = _h("load_error", "Could not load world history."),
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
		text = _h("era_label", "Era: ") .. tostring(summary.Era or "Unknown"),
		size = 15,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})
	mc.mobileLabel({
		parent = sumCard,
		text = _h("world_events", "World Events") .. ": " .. tostring(summary.WorldEvents or 0) .. "  •  " .. _h("notable_births", "Notable Births") .. ": " .. tostring(summary.NotableBirths or 0),
		size = 13,
		color = theme.SubText,
		order = 2,
	})
	mc.mobileLabel({
		parent = sumCard,
		text = _h("strongest", "Strongest Sorcerer") .. ": " .. tostring(summary.StrongestSorcerer or "Unknown"),
		size = 13,
		color = theme.Blue,
		order = 3,
	})

	local equippedTool = summary.EquippedCursedToolName or summary.EquippedCursedToolId or "None"
	mc.mobileLabel({
		parent = sumCard,
		text = _h("cursed_tools", "Cursed Tools") .. ": " .. tostring(summary.CursedToolsOwned or 0) .. "  •  " .. _h("equipped", "Equipped") .. ": " .. tostring(equippedTool),
		size = 13,
		color = theme.SubText,
		order = 4,
	})

	local clanWarText = _h("clan_wars", "Clan Wars") .. ": " .. tostring(summary.ClanWarWins or 0) .. "W / " .. tostring(summary.ClanWarLosses or 0) .. "L"
	if summary.ClanWarActive == true then
		clanWarText ..= "\n" .. _h("active_vs", "Active vs") .. " " .. tostring(summary.ClanWarRival or "Rival Clan") .. " (" .. tostring(summary.ClanWarTension or 0) .. "% " .. _h("tension", "tension") .. ")"
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
	rendering = true
	clearList()
	activeTab = "titles"
	updateTabStyles()

	local ok, data = pcall(function()
		return getTitles:InvokeServer()
	end)
	rendering = false

	if not ok or typeof(data) ~= "table" then
		local errCard = mc.mobileCard({ parent = scroll, order = 1 })
		mc.mobileLabel({
			parent = errCard,
			text = _h("titles_error", "Could not load titles."),
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
			text = if unlocked then _h("unlocked", "Unlocked") else _h("locked", "Locked"),
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

local function renderLives()
	rendering = true
	clearList()
	activeTab = "lives"
	updateTabStyles()

	if not getPastLives then
		rendering = false
		local errCard = mc.mobileCard({ parent = scroll, order = 1 })
		mc.mobileLabel({ parent = errCard, text = _h("cemetery_unavail", "Cemetery unavailable — rejoin to enable it."), size = 13, color = theme.SubText, order = 1 })
		return
	end

	local ok, data = pcall(function() return getPastLives:InvokeServer() end)
	rendering = false
	if not ok or typeof(data) ~= "table" then
		local errCard = mc.mobileCard({ parent = scroll, order = 1 })
		mc.mobileLabel({ parent = errCard, text = _h("past_lives_error", "Could not load past lives."), size = 14, color = theme.Bad, font = Enum.Font.GothamBold, order = 1 })
		return
	end

	local lives = data.PastLives or {}
	if #lives == 0 then
		local c = mc.mobileCard({ parent = scroll, order = 1 })
		mc.mobileLabel({ parent = c, text = _h("cemetery_none", "⚰  No past lives recorded yet."), size = 14, color = theme.SubText, font = Enum.Font.GothamBold, order = 1 })
		mc.mobileLabel({ parent = c, text = _h("cemetery_start", "Start a new life to begin your cemetery."), size = 13, color = theme.SubText, order = 2 })
		return
	end

	for i, life in ipairs(lives) do
		local ribColor = RIBBON_COLORS[life.Ribbon] or Color3.fromRGB(140, 140, 160)
		local c = mc.mobileCard({ parent = scroll, order = i, accentColor = ribColor })
		mc.mobileLabel({ parent = c, text = "⚰  " .. tostring(life.Name or "Unknown"), size = 16, color = theme.Text, font = Enum.Font.GothamBlack, order = 1 })
		mc.mobileLabel({ parent = c, text = tostring(life.Ribbon or "ORDINARY LIFE"), size = 13, color = ribColor, font = Enum.Font.GothamBlack, order = 2 })
		mc.mobileLabel({ parent = c, text = _h("cemetery_age", "Age") .. " " .. tostring(life.Age or 0) .. "  ·  " .. tostring(life.Grade or "Unranked") .. "  ·  " .. tostring(life.Clan or ""), size = 13, color = theme.SubText, order = 3 })
		mc.mobileLabel({ parent = c, text = _h("cemetery_tech", "Technique") .. ": " .. tostring(life.Technique or "None") .. "  ·  " .. _h("cemetery_miss", "Missions") .. ": " .. tostring(life.Missions or 0), size = 12, color = theme.Muted, order = 4 })
		mc.mobileLabel({ parent = c, text = "— #" .. tostring(i) .. " —", size = 11, color = theme.SubText, order = 5 })
	end
end

local function makeMobileBar(parent, label, value, barColor, order)
	local barCard = mc.mobileCard({ parent = parent, order = order, accentColor = barColor })

	mc.mobileLabel({ parent = barCard, text = label, size = 13, color = theme.Text, font = Enum.Font.GothamMedium, order = 1 })
	mc.mobileLabel({ parent = barCard, text = tostring(math.floor(value)) .. " / 100", size = 13, color = barColor, font = Enum.Font.GothamBlack, order = 2 })

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -24, 0, 10)
	track.Position = UDim2.new(0, 12, 0, 0)
	track.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
	track.BorderSizePixel = 0
	track.LayoutOrder = 3
	track.Parent = barCard
	local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 5); tc.Parent = track

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(math.clamp(value / 100, 0, 1), 0, 1, 0)
	fill.BackgroundColor3 = barColor
	fill.BorderSizePixel = 0
	fill.ZIndex = track.ZIndex + 1
	fill.Parent = track
	local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0, 5); fc.Parent = fill
end

local function renderInfluence()
	rendering = true
	clearList()
	activeTab = "influence"
	updateTabStyles()

	local ok, data = pcall(function() return getWorldHistory:InvokeServer() end)
	rendering = false
	if not ok or typeof(data) ~= "table" then
		local errCard = mc.mobileCard({ parent = scroll, order = 1 })
		mc.mobileLabel({ parent = errCard, text = _h("influence_error", "Could not load influence data."), size = 14, color = theme.Bad, font = Enum.Font.GothamBold, order = 1 })
		return
	end

	local s = data.Summary or {}
	local fame   = tonumber(s.Fame) or 0
	local fear   = tonumber(s.Fear) or 0
	local attn   = tonumber(s.WorldAttention) or 0
	local press  = tonumber(s.WorldPressure) or 0
	local soc    = tonumber(s.SocietyInfluence) or 0
	local wanted = tonumber(s.WantedLevel) or 0

	local descCard = mc.mobileCard({ parent = scroll, order = 1 })
	mc.mobileLabel({ parent = descCard, text = _h("influence_title", "How the world perceives you."), size = 14, color = theme.Gold, font = Enum.Font.GothamBlack, order = 1 })
	mc.mobileLabel({ parent = descCard, text = _h("influence_sub", "Built from your actions, missions, and reputation."), size = 13, color = theme.SubText, order = 2 })

	local fameCard = mc.mobileCard({ parent = scroll, order = 2, accentColor = theme.Gold })
	mc.mobileLabel({ parent = fameCard, text = _h("fame_header", "⭐  FAME") .. " — " .. tostring(math.floor(fame)) .. " / 100", size = 15, color = theme.Gold, font = Enum.Font.GothamBlack, order = 1 })
	mc.mobileLabel({ parent = fameCard, text = fame >= 75 and _h("fame_high", "Celebrated across the jujutsu world.") or fame >= 40 and _h("fame_mid", "Your name is known in sorcerer circles.") or _h("fame_low", "Still unknown to most."), size = 13, color = theme.SubText, order = 2 })
	local fameTrack = Instance.new("Frame")
	fameTrack.Size = UDim2.new(1, -24, 0, 10)
	fameTrack.Position = UDim2.new(0, 12, 0, 0)
	fameTrack.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
	fameTrack.BorderSizePixel = 0
	fameTrack.LayoutOrder = 3
	fameTrack.Parent = fameCard
	local ftc = Instance.new("UICorner"); ftc.CornerRadius = UDim.new(0, 5); ftc.Parent = fameTrack
	local fameFill = Instance.new("Frame")
	fameFill.Size = UDim2.new(math.clamp(fame / 100, 0, 1), 0, 1, 0)
	fameFill.BackgroundColor3 = theme.Gold
	fameFill.BorderSizePixel = 0
	fameFill.ZIndex = fameTrack.ZIndex + 1
	fameFill.Parent = fameTrack
	local ffc = Instance.new("UICorner"); ffc.CornerRadius = UDim.new(0, 5); ffc.Parent = fameFill

	local fearColor = Color3.fromRGB(220, 84, 90)
	local fearCard = mc.mobileCard({ parent = scroll, order = 3, accentColor = fearColor })
	mc.mobileLabel({ parent = fearCard, text = _h("fear_header", "💀  FEAR") .. " — " .. tostring(math.floor(fear)) .. " / 100", size = 15, color = fearColor, font = Enum.Font.GothamBlack, order = 1 })
	mc.mobileLabel({ parent = fearCard, text = fear >= 75 and _h("fear_high", "Enemies flee when they hear your name.") or fear >= 40 and _h("fear_mid", "Your presence unsettles those who know you.") or _h("fear_low", "You haven't yet made them afraid."), size = 13, color = theme.SubText, order = 2 })
	local fearTrack = Instance.new("Frame")
	fearTrack.Size = UDim2.new(1, -24, 0, 10)
	fearTrack.Position = UDim2.new(0, 12, 0, 0)
	fearTrack.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
	fearTrack.BorderSizePixel = 0
	fearTrack.LayoutOrder = 3
	fearTrack.Parent = fearCard
	local frtc = Instance.new("UICorner"); frtc.CornerRadius = UDim.new(0, 5); frtc.Parent = fearTrack
	local fearFill = Instance.new("Frame")
	fearFill.Size = UDim2.new(math.clamp(fear / 100, 0, 1), 0, 1, 0)
	fearFill.BackgroundColor3 = fearColor
	fearFill.BorderSizePixel = 0
	fearFill.ZIndex = fearTrack.ZIndex + 1
	fearFill.Parent = fearTrack
	local frc = Instance.new("UICorner"); frc.CornerRadius = UDim.new(0, 5); frc.Parent = fearFill

	local blueColor = Color3.fromRGB(116, 190, 255)
	local orangeColor = Color3.fromRGB(255, 160, 60)
	local purpleColor = Color3.fromRGB(180, 130, 255)

	local presCard = mc.mobileCard({ parent = scroll, order = 4 })
	mc.mobileLabel({ parent = presCard, text = _h("world_presence", "WORLD PRESENCE"), size = 14, color = theme.Text, font = Enum.Font.GothamBlack, order = 1 })
	mc.mobileLabel({ parent = presCard, text = _h("world_attention", "World Attention") .. ": " .. tostring(math.floor(attn)), size = 13, color = blueColor, order = 2 })
	mc.mobileLabel({ parent = presCard, text = _h("world_pressure", "World Pressure") .. ": " .. tostring(math.floor(press)), size = 13, color = orangeColor, order = 3 })
	mc.mobileLabel({ parent = presCard, text = _h("society_inf", "Society Influence") .. ": " .. tostring(math.floor(soc)), size = 13, color = purpleColor, order = 4 })
	mc.mobileLabel({ parent = presCard, text = _h("wanted_level", "Wanted Level") .. ": " .. tostring(math.floor(wanted)), size = 13, color = wanted >= 50 and fearColor or theme.SubText, order = 5 })
end

local function buildTabBar()
	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(1, -20, 0, 100)
	tabBar.Position = UDim2.new(0, 10, 0, 0)
	tabBar.BackgroundTransparency = 1
	tabBar.LayoutOrder = -1
	tabBar.Parent = scroll

	local tabGrid = Instance.new("UIGridLayout")
	tabGrid.CellSize = UDim2.new(0.5, -6, 0, 44)
	tabGrid.CellPadding = UDim2.new(0, 8, 0, 8)
	tabGrid.SortOrder = Enum.SortOrder.LayoutOrder
	tabGrid.Parent = tabBar

	historyTabBtn = mc.mobileButton({
		parent = tabBar,
		text = _h("tab_history", "HISTORY"),
		size = UDim2.new(0, 0, 0, 0),
		position = UDim2.new(0, 0, 0, 0),
		color = theme.Button,
		textColor = theme.Gold,
		textSize = 13,
		order = 1,
		callback = function()
			if activeTab ~= "history" and not rendering then renderHistory() end
		end,
	})

	titlesTabBtn = mc.mobileButton({
		parent = tabBar,
		text = _h("tab_titles", "TITLES"),
		size = UDim2.new(0, 0, 0, 0),
		position = UDim2.new(0, 0, 0, 0),
		color = theme.Panel,
		textColor = theme.SubText,
		textSize = 13,
		order = 2,
		callback = function()
			if activeTab ~= "titles" and not rendering then renderTitles() end
		end,
	})

	livesTabBtn = mc.mobileButton({
		parent = tabBar,
		text = _h("tab_cemetery", "CEMETERY"),
		size = UDim2.new(0, 0, 0, 0),
		position = UDim2.new(0, 0, 0, 0),
		color = theme.Panel,
		textColor = theme.SubText,
		textSize = 13,
		order = 3,
		callback = function()
			if activeTab ~= "lives" and not rendering then renderLives() end
		end,
	})

	influenceTabBtn = mc.mobileButton({
		parent = tabBar,
		text = _h("tab_influence", "INFLUENCE"),
		size = UDim2.new(0, 0, 0, 0),
		position = UDim2.new(0, 0, 0, 0),
		color = theme.Panel,
		textColor = theme.SubText,
		textSize = 13,
		order = 4,
		callback = function()
			if activeTab ~= "influence" and not rendering then renderInfluence() end
		end,
	})
end

local function openPanel()
	gui.Enabled = true
	activeTab = "history"
	if not scroll:FindFirstChild("TabBar") then
		buildTabBar()
	end
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
