local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local mc = require("@ui/mobile/mobileComponents")

local theme = mc.theme
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function cleanText(value, fallback)
	if typeof(value) == "table" then
		value = fallback
	end
	local text = tostring(value or fallback or "")
	text = text:gsub("<br%s*/?>", "\n")
	text = text:gsub("^%s*table:%s*0x[%da-fA-F]+%s*$", tostring(fallback or ""))
	return text
end

local function upperContains(text, pattern)
	return string.find(string.upper(tostring(text or "")), string.upper(pattern), 1, true) ~= nil
end

local function detectStyle(payload)
	payload = payload or {}
	local raw = table.concat({
		tostring(payload.Type or ""),
		tostring(payload.MissionTitle or ""),
		tostring(payload.Title or ""),
		tostring(payload.Body or ""),
	}, " ")

	if upperContains(raw, "CURSED SPIRIT") or upperContains(raw, "CURSE") or upperContains(raw, "HAUNT") or upperContains(raw, "HUNGER") or upperContains(raw, "RUMOR") then
		return {
			Badge = "CURSED SPIRIT EVENT",
			Tag = "HAUNT",
			Accent = theme.Purple,
			Button = Color3.fromRGB(71, 30, 45),
			ButtonStroke = Color3.fromRGB(102, 71, 152),
		}
	end

	if upperContains(raw, "JUJUTSU SOCIETY") or upperContains(raw, "CLASSIFICATION") or upperContains(raw, "NOTICE") or upperContains(raw, "REGISTERED") then
		return {
			Badge = "JUJUTSU SOCIETY",
			Tag = "NOTICE",
			Accent = theme.Gold,
			Button = Color3.fromRGB(73, 55, 28),
			ButtonStroke = Color3.fromRGB(130, 101, 52),
		}
	end

	return {
		Badge = upperContains(raw, "MISSION") and "MISSION EVENT" or "LIFE EVENT",
		Tag = "CHOICE",
		Accent = theme.Red,
		Button = Color3.fromRGB(78, 31, 43),
		ButtonStroke = Color3.fromRGB(126, 47, 61),
	}
end

local function playSFX(name)
	if _G.BitKaisenPlaySFX then
		pcall(function()
			_G.BitKaisenPlaySFX(name)
		end)
	end
end

local function init()
	local showMissionSituation = ReplicatedStorage:WaitForChild("ShowMissionSituation")
	local missionChoice = ReplicatedStorage:WaitForChild("MissionChoice")
	local clearPendingMission = ReplicatedStorage:FindFirstChild("ClearPendingMission")

	local gui = Instance.new("ScreenGui")
	gui.Name = "BitKaisenMobileMissionSituationGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 660
	gui.Enabled = false
	gui.Parent = playerGui

	local currentOpen = false
	local clickBusy = false
	local currentOptions = {}
	local lastPayload = nil

	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.Visible = false
	overlay.Active = true
	overlay.Parent = gui

	local sheet = Instance.new("Frame")
	sheet.Name = "MissionSituationSheet"
	sheet.AnchorPoint = Vector2.new(0.5, 1)
	sheet.Position = UDim2.new(0.5, 0, 1, 20)
	sheet.Size = UDim2.new(1, -16, 0.75, 0)
	sheet.BackgroundColor3 = theme.Panel
	sheet.BorderSizePixel = 0
	sheet.ClipsDescendants = true
	sheet.Parent = overlay
	mc.corner(sheet, 16)
	mc.stroke(sheet, theme.Stroke)

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 52)
	header.BackgroundColor3 = theme.Card
	header.BorderSizePixel = 0
	header.Parent = sheet
	mc.corner(header, 10)

	local badgeLabel = Instance.new("TextLabel")
	badgeLabel.Position = UDim2.new(0, 14, 0, 8)
	badgeLabel.Size = UDim2.new(0.7, 0, 0, 16)
	badgeLabel.BackgroundTransparency = 1
	badgeLabel.TextColor3 = theme.Text
	badgeLabel.TextSize = 12
	badgeLabel.Font = Enum.Font.GothamBlack
	badgeLabel.TextXAlignment = Enum.TextXAlignment.Left
	badgeLabel.Text = "LIFE EVENT"
	badgeLabel.Parent = header

	local subBadgeLabel = Instance.new("TextLabel")
	subBadgeLabel.Position = UDim2.new(0, 14, 0, 26)
	subBadgeLabel.Size = UDim2.new(0.7, 0, 0, 14)
	subBadgeLabel.BackgroundTransparency = 1
	subBadgeLabel.TextColor3 = theme.SubText
	subBadgeLabel.TextSize = 10
	subBadgeLabel.Font = Enum.Font.GothamBold
	subBadgeLabel.TextXAlignment = Enum.TextXAlignment.Left
	subBadgeLabel.Text = "Situation"
	subBadgeLabel.Parent = header

	local tagPill = Instance.new("Frame")
	tagPill.AnchorPoint = Vector2.new(1, 0.5)
	tagPill.Position = UDim2.new(1, -52, 0.5, 0)
	tagPill.Size = UDim2.new(0, 64, 0, 24)
	tagPill.BackgroundColor3 = theme.Bg
	tagPill.BorderSizePixel = 0
	tagPill.Parent = header
	mc.corner(tagPill, 8)
	mc.stroke(tagPill, theme.StrokeSoft)

	local tagLabel = Instance.new("TextLabel")
	tagLabel.Size = UDim2.fromScale(1, 1)
	tagLabel.BackgroundTransparency = 1
	tagLabel.TextColor3 = theme.Text
	tagLabel.TextSize = 10
	tagLabel.Font = Enum.Font.GothamBlack
	tagLabel.Text = "CHOICE"
	tagLabel.Parent = tagPill

	local closeBtn = Instance.new("TextButton")
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, -10, 0.5, 0)
	closeBtn.Size = UDim2.fromOffset(34, 34)
	closeBtn.BackgroundColor3 = theme.Card
	closeBtn.BorderSizePixel = 0
	closeBtn.TextColor3 = theme.Bad
	closeBtn.TextSize = 14
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.Text = "X"
	closeBtn.AutoButtonColor = false
	closeBtn.Parent = header
	mc.corner(closeBtn, 999)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Position = UDim2.new(0, 0, 0, 54)
	scroll.Size = UDim2.new(1, 0, 1, -54)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = theme.Stroke
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = sheet

	local scrollPad = Instance.new("UIPadding")
	scrollPad.PaddingTop = UDim.new(0, 12)
	scrollPad.PaddingBottom = UDim.new(0, 20)
	scrollPad.PaddingLeft = UDim.new(0, 14)
	scrollPad.PaddingRight = UDim.new(0, 14)
	scrollPad.Parent = scroll

	local scrollLayout = Instance.new("UIListLayout")
	scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
	scrollLayout.Padding = UDim.new(0, 10)
	scrollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	scrollLayout.Parent = scroll

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 0)
	titleLabel.AutomaticSize = Enum.AutomaticSize.Y
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = theme.Text
	titleLabel.TextSize = 18
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextWrapped = true
	titleLabel.Text = "Situation"
	titleLabel.LayoutOrder = 1
	titleLabel.Parent = scroll

	local accentLine = Instance.new("Frame")
	accentLine.Size = UDim2.new(0.5, 0, 0, 2)
	accentLine.BackgroundColor3 = theme.Red
	accentLine.BorderSizePixel = 0
	accentLine.LayoutOrder = 2
	accentLine.Parent = scroll

	local bodyCard = mc.mobileCard({
		parent = scroll,
		order = 3,
		color = theme.Card,
	})

	local bodyText = Instance.new("TextLabel")
	bodyText.Size = UDim2.new(1, 0, 0, 0)
	bodyText.AutomaticSize = Enum.AutomaticSize.Y
	bodyText.BackgroundTransparency = 1
	bodyText.TextColor3 = theme.SubText
	bodyText.TextSize = 14
	bodyText.Font = Enum.Font.GothamMedium
	bodyText.TextWrapped = true
	bodyText.TextXAlignment = Enum.TextXAlignment.Center
	bodyText.Text = "Choose how to respond."
	bodyText.LayoutOrder = 1
	bodyText.Parent = bodyCard

	local questionLabel = Instance.new("TextLabel")
	questionLabel.Size = UDim2.new(1, 0, 0, 22)
	questionLabel.BackgroundTransparency = 1
	questionLabel.TextColor3 = theme.Text
	questionLabel.TextSize = 15
	questionLabel.Font = Enum.Font.GothamBlack
	questionLabel.Text = "What will you do?"
	questionLabel.LayoutOrder = 4
	questionLabel.Parent = scroll

	local optionsHolder = Instance.new("Frame")
	optionsHolder.Size = UDim2.new(1, 0, 0, 0)
	optionsHolder.AutomaticSize = Enum.AutomaticSize.Y
	optionsHolder.BackgroundTransparency = 1
	optionsHolder.LayoutOrder = 5
	optionsHolder.Parent = scroll

	local optionsLayout = Instance.new("UIListLayout")
	optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	optionsLayout.Padding = UDim.new(0, 8)
	optionsLayout.Parent = optionsHolder

	local fateButton = Instance.new("TextButton")
	fateButton.Size = UDim2.new(1, 0, 0, 28)
	fateButton.BackgroundTransparency = 1
	fateButton.BorderSizePixel = 0
	fateButton.TextColor3 = theme.Red
	fateButton.TextSize = 13
	fateButton.Font = Enum.Font.GothamBold
	fateButton.Text = "Let fate decide"
	fateButton.AutoButtonColor = false
	fateButton.LayoutOrder = 6
	fateButton.Parent = scroll

	local footerLabel = Instance.new("TextLabel")
	footerLabel.Size = UDim2.new(1, 0, 0, 14)
	footerLabel.BackgroundTransparency = 1
	footerLabel.TextColor3 = theme.Muted
	footerLabel.TextSize = 10
	footerLabel.Font = Enum.Font.GothamBold
	footerLabel.Text = ""
	footerLabel.LayoutOrder = 7
	footerLabel.Parent = scroll

	local function clearOptions()
		for _, child in ipairs(optionsHolder:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
	end

	local function closeWindow(sendClear)
		if not currentOpen then
			overlay.Visible = false
			return
		end
		currentOpen = false
		clickBusy = false
		if sendClear == true and clearPendingMission then
			clearPendingMission:FireServer()
		end
		TweenService:Create(sheet, TWEEN_FAST, { Position = UDim2.new(0.5, 0, 1, 20) }):Play()
		TweenService:Create(overlay, TWEEN_FAST, { BackgroundTransparency = 1 }):Play()
		task.delay(0.16, function()
			if not currentOpen then
				overlay.Visible = false
				gui.Enabled = false
			end
		end)
	end

	local function chooseOption(optionData, index)
		if clickBusy or not currentOpen then return end
		clickBusy = true
		playSFX("ChoiceSelect")
		local optionIndex = tonumber(optionData and optionData.Index) or index
		closeWindow(false)
		missionChoice:FireServer(optionIndex)
	end

	local function makeOptionButton(optionData, index, style)
		local btn = Instance.new("TextButton")
		btn.Name = "Choice" .. tostring(index)
		btn.Size = UDim2.new(1, 0, 0, 48)
		btn.BackgroundColor3 = style.Button
		btn.BorderSizePixel = 0
		btn.TextColor3 = theme.Text
		btn.TextSize = 14
		btn.Font = Enum.Font.GothamBold
		btn.TextWrapped = true
		btn.Text = cleanText(optionData and optionData.Text, "Option " .. tostring(index))
		btn.AutoButtonColor = false
		btn.LayoutOrder = index
		btn.Parent = optionsHolder
		mc.corner(btn, 10)
		mc.stroke(btn, style.ButtonStroke)

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 14)
		pad.PaddingRight = UDim.new(0, 14)
		pad.Parent = btn

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TWEEN_FAST, { BackgroundColor3 = theme.CardHover }):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TWEEN_FAST, { BackgroundColor3 = style.Button }):Play()
		end)
		btn.MouseButton1Click:Connect(function()
			chooseOption(optionData, index)
		end)
	end

	local function pickRandomOption()
		if clickBusy or not currentOpen or #currentOptions <= 0 then return end
		local randomIndex = math.random(1, #currentOptions)
		chooseOption(currentOptions[randomIndex], randomIndex)
	end

	local function openWindow(data)
		data = data or {}
		lastPayload = data
		clearOptions()

		local style = detectStyle(data)
		local missionTitle = cleanText(data.MissionTitle or data.Type or "Situation", "Situation")
		local titleText = cleanText(data.Title or data.MissionTitle or "Situation", "Situation")
		local body = cleanText(data.Body or "Choose how to respond.", "Choose how to respond.")

		currentOptions = data.Options
		if typeof(currentOptions) ~= "table" or #currentOptions <= 0 then
			currentOptions = { { Index = 1, Text = "Continue" } }
		end

		badgeLabel.Text = style.Badge
		subBadgeLabel.Text = missionTitle
		tagLabel.Text = style.Tag
		accentLine.BackgroundColor3 = style.Accent
		fateButton.TextColor3 = style.Accent
		titleLabel.Text = titleText
		bodyText.Text = body

		local extraFooter = ""
		if data.Footer and tostring(data.Footer) ~= "" then
			extraFooter = tostring(data.Footer)
		elseif data.Highlight and tostring(data.Highlight) ~= "" then
			extraFooter = tostring(data.Highlight)
		end
		footerLabel.Text = extraFooter

		for index, optionData in ipairs(currentOptions) do
			makeOptionButton(optionData, index, style)
		end

		fateButton.Visible = #currentOptions >= 2
		scroll.CanvasPosition = Vector2.new(0, 0)
		gui.Enabled = true
		overlay.Visible = true
		overlay.BackgroundTransparency = 1
		sheet.Position = UDim2.new(0.5, 0, 1, 20)
		currentOpen = true
		clickBusy = false
		playSFX("PopupOpen")
		TweenService:Create(overlay, TWEEN_FAST, { BackgroundTransparency = 0.4 }):Play()
		TweenService:Create(sheet, TWEEN_FAST, { Position = UDim2.new(0.5, 0, 1, -8) }):Play()
	end

	closeBtn.MouseButton1Click:Connect(function()
		playSFX("ChoiceSelect")
		closeWindow(true)
	end)

	fateButton.MouseButton1Click:Connect(pickRandomOption)

	showMissionSituation.OnClientEvent:Connect(openWindow)
end

return { init = init }
