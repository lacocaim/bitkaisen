-- Mobile counterpart of ArrivalScreenPanel.luau -- see that file for the
-- full rationale (shown once per brand-new life, sits above
-- MobileCharacterCustomizationPanel via a higher DisplayOrder + an opaque
-- backdrop, blocking input until dismissed, no direct coordination needed).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local mc = require("@ui/mobile/mobileComponents")
local remotes = require("@ui-state/remotes")

local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _g(key: string, fallback: string): string
	return BitKaisenLocale.tOrFallback(_L, "arrival." .. key, nil, fallback)
end

local theme = mc.theme
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUI_NAME = "BitKaisenMobileArrivalGui"
local RANK_MEDALS = { "🥇", "🥈", "🥉" }

local state = { LastLifeKey = nil, IsOpen = false }

local existing = playerGui:FindFirstChild(GUI_NAME)
if existing then
	existing:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
-- Above MobileWorldModePanel/MobileCharacterCustomizationPanel and
-- MobileWorldBrowserPanel (640/641) -- blocks input into customization
-- until the player dismisses this arrival beat.
screenGui.DisplayOrder = 645
screenGui.Enabled = false
screenGui.Parent = playerGui

-- Opaque backdrop -- same lesson as MobileWorldModePanel/
-- MobileWorldBrowserPanel earlier today: a translucent scrim with no
-- opaque window behind it lets the dashboard show through.
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.BackgroundColor3 = theme.Bg
overlay.BackgroundTransparency = 0
overlay.BorderSizePixel = 0
overlay.Size = UDim2.fromScale(1, 1)
overlay.Active = true
overlay.Parent = screenGui

local eyebrow = Instance.new("TextLabel")
eyebrow.BackgroundTransparency = 1
eyebrow.Position = UDim2.new(0.5, 0, 0, 70)
eyebrow.AnchorPoint = Vector2.new(0.5, 0)
eyebrow.Size = UDim2.new(1, -40, 0, 16)
eyebrow.Text = ""
eyebrow.TextColor3 = theme.SubText
eyebrow.Font = Enum.Font.Code
eyebrow.TextSize = 11
eyebrow.TextXAlignment = Enum.TextXAlignment.Center
eyebrow.Parent = overlay

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0.5, 0, 0, 90)
title.AnchorPoint = Vector2.new(0.5, 0)
title.Size = UDim2.new(1, -32, 0, 36)
title.Text = ""
title.TextColor3 = theme.Gold
title.Font = Enum.Font.GothamBlack
title.TextSize = 24
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = overlay

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.new(0.5, 0, 0, 128)
subtitle.AnchorPoint = Vector2.new(0.5, 0)
subtitle.Size = UDim2.new(1, -32, 0, 20)
subtitle.Text = ""
subtitle.TextColor3 = theme.Purple
subtitle.Font = Enum.Font.GothamBlack
subtitle.TextSize = 13
subtitle.TextXAlignment = Enum.TextXAlignment.Center
subtitle.Parent = overlay

local divider = Instance.new("Frame")
divider.Position = UDim2.new(0.5, 0, 0, 158)
divider.AnchorPoint = Vector2.new(0.5, 0)
divider.Size = UDim2.new(0, 60, 0, 2)
divider.BackgroundColor3 = theme.Purple
divider.BorderSizePixel = 0
divider.Parent = overlay

local body = Instance.new("TextLabel")
body.BackgroundTransparency = 1
body.Position = UDim2.new(0.5, 0, 0, 174)
body.AnchorPoint = Vector2.new(0.5, 0)
body.Size = UDim2.new(1, -48, 0, 70)
body.Text = ""
body.TextColor3 = theme.Text
body.Font = Enum.Font.Gotham
body.TextSize = 13
body.TextWrapped = true
body.TextXAlignment = Enum.TextXAlignment.Center
body.Parent = overlay

local rankingLabel = Instance.new("TextLabel")
rankingLabel.Position = UDim2.new(0, 24, 0, 254)
rankingLabel.Size = UDim2.new(1, -48, 0, 16)
rankingLabel.BackgroundTransparency = 1
rankingLabel.Text = "🏆 " .. _g("ranking_title", "NOTABLE SORCERERS ALREADY LIVING HERE")
rankingLabel.TextColor3 = theme.SubText
rankingLabel.Font = Enum.Font.GothamBlack
rankingLabel.TextSize = 10
rankingLabel.TextXAlignment = Enum.TextXAlignment.Left
rankingLabel.Visible = false
rankingLabel.Parent = overlay

local rankingScroll = Instance.new("ScrollingFrame")
rankingScroll.Position = UDim2.new(0, 24, 0, 276)
rankingScroll.Size = UDim2.new(1, -48, 0, 160)
rankingScroll.BackgroundTransparency = 1
rankingScroll.BorderSizePixel = 0
rankingScroll.ScrollBarThickness = 4
rankingScroll.CanvasSize = UDim2.fromOffset(0, 0)
rankingScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
rankingScroll.Visible = false
rankingScroll.Parent = overlay

local rankingLayout = Instance.new("UIListLayout")
rankingLayout.Padding = UDim.new(0, 6)
rankingLayout.SortOrder = Enum.SortOrder.LayoutOrder
rankingLayout.Parent = rankingScroll

local continueButton = Instance.new("TextButton")
continueButton.AnchorPoint = Vector2.new(0.5, 1)
continueButton.Position = UDim2.new(0.5, 0, 1, -40)
continueButton.Size = UDim2.new(1, -48, 0, 50)
continueButton.BackgroundColor3 = theme.Gold
continueButton.BorderSizePixel = 0
continueButton.Text = ""
continueButton.Parent = overlay
mc.corner(continueButton, 10)

local continueLabel = Instance.new("TextLabel")
continueLabel.BackgroundTransparency = 1
continueLabel.Size = UDim2.fromScale(1, 1)
continueLabel.Text = ""
continueLabel.TextColor3 = theme.Bg
continueLabel.Font = Enum.Font.GothamBlack
continueLabel.TextSize = 15
continueLabel.Parent = continueButton

local function clearRankingRows()
	for _, child in ipairs(rankingScroll:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function addRankingRow(order, text)
	local row = Instance.new("TextLabel")
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, 22)
	row.BackgroundTransparency = 1
	row.Text = text
	row.TextColor3 = theme.Text
	row.Font = Enum.Font.GothamMedium
	row.TextSize = 12
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.Parent = rankingScroll
	return row
end

local function getLifeKey(stats)
	if not stats then return "nil" end
	return table.concat({
		tostring(stats.__SlotId or stats.SlotId or "slot"),
		tostring(stats.Generation or 1),
		tostring(stats.Name or "Unknown"),
	}, "|")
end

local function close()
	if not state.IsOpen then return end
	state.IsOpen = false
	screenGui.Enabled = false
end

local function open(stats)
	state.IsOpen = true
	screenGui.Enabled = true

	local year = tostring(stats.CurrentYear or "?")
	local era = tostring(stats.CurrentEra or stats.Era or "")

	if stats.WorldMode == "Public" then
		eyebrow.Text = _g("public_eyebrow", "THE SHARED WORLD")
		title.Text = _g("public_title_prefix", "YEAR") .. " " .. year
		subtitle.Text = era
		body.Text = _g("public_body_loading", "Reading the world's living history...")
		rankingLabel.Visible = false
		rankingScroll.Visible = false
		clearRankingRows()

		local getWorldHistory = remotes.getWorldHistory()
		if getWorldHistory then
			task.spawn(function()
				local ok, payload = pcall(function()
					return getWorldHistory:InvokeServer()
				end)
				if not state.IsOpen then return end
				local ranking = ok and typeof(payload) == "table" and payload.PublicRanking or {}
				if typeof(ranking) == "table" and #ranking > 0 then
					body.Text = _g("public_body_established", "You arrive as this era already unfolds. This world has a history -- make your place in it.")
					rankingLabel.Visible = true
					rankingScroll.Visible = true
					for i, entry in ipairs(ranking) do
						local medal = RANK_MEDALS[i] or ("#" .. tostring(i))
						addRankingRow(i, medal .. "  " .. tostring(entry.Name) .. "  --  " .. tostring(entry.Grade))
					end
				else
					body.Text = _g("public_body_founding", "You are among the first to arrive. This world barely stirs awake -- your story may be the one that defines it.")
				end
			end)
		else
			body.Text = _g("public_body_founding", "You are among the first to arrive. This world barely stirs awake -- your story may be the one that defines it.")
		end

		continueLabel.Text = "⚔ " .. _g("public_button", "ENTER THE WORLD")
	else
		eyebrow.Text = _g("private_eyebrow", "YOUR OWN ERA")
		title.Text = _g("private_title", "A NEW CHAPTER BEGINS")
		subtitle.Text = era ~= "" and (era .. " · " .. year) or year
		body.Text = _g("private_body", "No one else lives this story. Every choice, every fall, every legacy -- yours alone, for as long as you carry it.")
		rankingLabel.Visible = false
		rankingScroll.Visible = false
		continueLabel.Text = "📜 " .. _g("private_button", "BEGIN YOUR STORY")
	end
end

continueButton.Activated:Connect(close)

local function init()
	local ule = remotes.updateLifeEvent()
	if not ule then return end

	ule.OnClientEvent:Connect(function(stats)
		if typeof(stats) ~= "table" then return end
		if stats.Alive == false then return end
		if stats.CharacterCustomized == true then return end
		if stats.WorldMode == nil then return end

		local lifeKey = getLifeKey(stats)
		if state.LastLifeKey == lifeKey then return end
		state.LastLifeKey = lifeKey

		open(stats)
	end)
end

return { init = init }
