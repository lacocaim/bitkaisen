-- Shown once per brand-new life, right before CharacterCustomizationPanel
-- opens (which already has its own ~0.45-1.05s open delay -- this panel
-- sits on top at a higher DisplayOrder and blocks input, so by the time the
-- player dismisses it, customization is already waiting underneath; no
-- coordination with that file needed). Mirrors the arrival-narrative BEAT
-- BitSeas gives players (a founding-crew screen for a fresh world, a recap
-- of who's already living there for an established one) -- but the copy
-- here is BitKaisen's own, not a translation of BitSeas' pirate wording.
-- Watch for pirate leftovers ("voyage", "captains", "tide"...) creeping
-- into new copy in this file.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local responsiveScale = require("@ui/responsiveScale")
local remotes = require("@ui-state/remotes")

local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _g(key: string, fallback: string): string
	return BitKaisenLocale.tOrFallback(_L, "arrival." .. key, nil, fallback)
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUI_NAME = "BitKaisenArrivalGui"

local THEME = {
	Bg = Color3.fromRGB(13, 13, 20),
	Panel = Color3.fromRGB(19, 19, 29),
	Panel2 = Color3.fromRGB(28, 28, 40),
	CardStroke = Color3.fromRGB(52, 48, 72),
	Stroke = Color3.fromRGB(116, 84, 165),
	Gold = Color3.fromRGB(255, 212, 94),
	Purple = Color3.fromRGB(156, 96, 246),
	Text = Color3.fromRGB(245, 241, 255),
	Muted = Color3.fromRGB(176, 169, 195),
}

local RANK_MEDALS = { "🥇", "🥈", "🥉" }

local state = { LastLifeKey = nil, IsOpen = false }

local existing = playerGui:FindFirstChild(GUI_NAME)
if existing then
	existing:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
-- Above WorldModePanel/CharacterCustomizationPanel (640) and
-- WorldBrowserPanel (641) -- deliberately sits on top of both so it
-- blocks input into customization until the player dismisses it.
screenGui.DisplayOrder = 645
screenGui.Enabled = false
screenGui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.35
overlay.BorderSizePixel = 0
overlay.Size = UDim2.fromScale(1, 1)
overlay.Active = true
overlay.Parent = screenGui

local window = Instance.new("Frame")
window.Name = "Window"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.fromScale(0.5, 0.5)
window.BackgroundColor3 = THEME.Bg
window.BorderSizePixel = 0
window.Active = true
window.Parent = overlay
responsiveScale.attach(window, 620, 560)

local windowCorner = Instance.new("UICorner")
windowCorner.CornerRadius = UDim.new(0, 12)
windowCorner.Parent = window

local windowStroke = Instance.new("UIStroke")
windowStroke.Color = THEME.Stroke
windowStroke.Thickness = 1
windowStroke.Parent = window

local eyebrow = Instance.new("TextLabel")
eyebrow.BackgroundTransparency = 1
eyebrow.Position = UDim2.new(0.5, 0, 0, 32)
eyebrow.AnchorPoint = Vector2.new(0.5, 0)
eyebrow.Size = UDim2.new(1, -60, 0, 18)
eyebrow.Text = ""
eyebrow.TextColor3 = THEME.Muted
eyebrow.Font = Enum.Font.Code
eyebrow.TextSize = 12
eyebrow.TextXAlignment = Enum.TextXAlignment.Center
eyebrow.Parent = window

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0.5, 0, 0, 54)
title.AnchorPoint = Vector2.new(0.5, 0)
title.Size = UDim2.new(1, -60, 0, 42)
title.Text = ""
title.TextColor3 = THEME.Gold
title.Font = Enum.Font.GothamBlack
title.TextSize = 30
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = window

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.new(0.5, 0, 0, 98)
subtitle.AnchorPoint = Vector2.new(0.5, 0)
subtitle.Size = UDim2.new(1, -60, 0, 22)
subtitle.Text = ""
subtitle.TextColor3 = THEME.Purple
subtitle.Font = Enum.Font.GothamBlack
subtitle.TextSize = 14
subtitle.TextXAlignment = Enum.TextXAlignment.Center
subtitle.Parent = window

local divider = Instance.new("Frame")
divider.Position = UDim2.new(0.5, 0, 0, 132)
divider.AnchorPoint = Vector2.new(0.5, 0)
divider.Size = UDim2.new(0, 80, 0, 2)
divider.BackgroundColor3 = THEME.Purple
divider.BorderSizePixel = 0
divider.Parent = window

local body = Instance.new("TextLabel")
body.BackgroundTransparency = 1
body.Position = UDim2.new(0.5, 0, 0, 150)
body.AnchorPoint = Vector2.new(0.5, 0)
body.Size = UDim2.new(1, -80, 0, 50)
body.Text = ""
body.TextColor3 = THEME.Text
body.Font = Enum.Font.Gotham
body.TextSize = 14
body.TextWrapped = true
body.TextXAlignment = Enum.TextXAlignment.Center
body.Parent = window

local rankingLabel = Instance.new("TextLabel")
rankingLabel.BackgroundTransparency = 1
rankingLabel.Position = UDim2.new(0, 30, 0, 214)
rankingLabel.Size = UDim2.new(1, -60, 0, 18)
rankingLabel.Text = "🏆 " .. _g("ranking_title", "NOTABLE SORCERERS ALREADY LIVING HERE")
rankingLabel.TextColor3 = THEME.Muted
rankingLabel.Font = Enum.Font.GothamBlack
rankingLabel.TextSize = 11
rankingLabel.TextXAlignment = Enum.TextXAlignment.Left
rankingLabel.Visible = false
rankingLabel.Parent = window

local rankingScroll = Instance.new("ScrollingFrame")
rankingScroll.Position = UDim2.new(0, 30, 0, 238)
rankingScroll.Size = UDim2.new(1, -60, 0, 140)
rankingScroll.BackgroundTransparency = 1
rankingScroll.BorderSizePixel = 0
rankingScroll.ScrollBarThickness = 4
rankingScroll.CanvasSize = UDim2.fromOffset(0, 0)
rankingScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
rankingScroll.Visible = false
rankingScroll.Parent = window

local rankingLayout = Instance.new("UIListLayout")
rankingLayout.Padding = UDim.new(0, 6)
rankingLayout.SortOrder = Enum.SortOrder.LayoutOrder
rankingLayout.Parent = rankingScroll

local continueButton = Instance.new("TextButton")
continueButton.AnchorPoint = Vector2.new(0.5, 1)
continueButton.Position = UDim2.new(0.5, 0, 1, -30)
continueButton.Size = UDim2.new(1, -60, 0, 48)
continueButton.BackgroundColor3 = THEME.Gold
continueButton.BorderSizePixel = 0
continueButton.Text = ""
continueButton.AutoButtonColor = true
continueButton.Parent = window

local continueCorner = Instance.new("UICorner")
continueCorner.CornerRadius = UDim.new(0, 10)
continueCorner.Parent = continueButton

local continueLabel = Instance.new("TextLabel")
continueLabel.BackgroundTransparency = 1
continueLabel.Size = UDim2.fromScale(1, 1)
continueLabel.Text = ""
continueLabel.TextColor3 = THEME.Bg
continueLabel.Font = Enum.Font.GothamBlack
continueLabel.TextSize = 16
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
	row.Size = UDim2.new(1, 0, 0, 24)
	row.BackgroundTransparency = 1
	row.Text = text
	row.TextColor3 = THEME.Text
	row.Font = Enum.Font.GothamMedium
	row.TextSize = 13
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
	overlay.Visible = false
	screenGui.Enabled = false
end

local function open(stats)
	state.IsOpen = true
	screenGui.Enabled = true
	overlay.Visible = true

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
		-- Same gate as CharacterCustomizationPanel: wait for the
		-- Private/Public choice before anything about "arrival" is shown.
		if stats.WorldMode == nil then return end

		local lifeKey = getLifeKey(stats)
		if state.LastLifeKey == lifeKey then return end
		state.LastLifeKey = lifeKey

		open(stats)
	end)
end

return { init = init }
