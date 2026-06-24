local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")

local create = vide.create
local source = vide.source

local TONE_BG = {
	default = theme.Panel2,
	success = Color3.fromRGB(20, 70, 42),
	danger = Color3.fromRGB(92, 24, 34),
}

local popupQueue = {}
local isShowing = source(false)
local titleText = source("")
local bodyText = source("")
local highlightText = source("")
local footerText = source("")
local footerVisible = source(false)
local toneColor = source(theme.Purple)
local toneBgColor = source(theme.Panel2)

local overlayRef: Frame? = nil
local windowRef: Frame? = nil

local function showNextPopup()
	if #popupQueue == 0 then
		isShowing(false)
		if overlayRef then
			TweenService:Create(overlayRef, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
			task.delay(0.2, function() if overlayRef then overlayRef.Visible = false end end)
		end
		return
	end

	local data = table.remove(popupQueue, 1)
	titleText(tostring(data.Title or "EVENT"))
	bodyText(tostring(data.Body or ""))
	highlightText(tostring(data.Highlight or ""))
	local footer = tostring(data.Footer or "")
	footerText(footer)
	footerVisible(footer ~= "")

	local tone = string.lower(tostring(data.Tone or ""))
	if tone == "success" then
		toneColor(theme.Green)
		toneBgColor(TONE_BG.success)
	elseif tone == "danger" or tone == "error" then
		toneColor(theme.Red)
		toneBgColor(TONE_BG.danger)
	else
		toneColor(theme.Purple)
		toneBgColor(TONE_BG.default)
	end

	isShowing(true)
	if overlayRef then
		overlayRef.Visible = true
		TweenService:Create(overlayRef, TweenInfo.new(0.25), { BackgroundTransparency = 0.45 }):Play()
	end
	if windowRef then
		windowRef.BackgroundTransparency = 1
		windowRef.Position = UDim2.new(0.5, 0, 0.55, 0)
		windowRef.Visible = true
		TweenService:Create(windowRef, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0,
			Position = UDim2.new(0.5, 0, 0.5, 0),
		}):Play()
	end
end

local function queueMajorPopup(data: { [string]: any })
	table.insert(popupQueue, data)
	if not isShowing() then
		showNextPopup()
	end
end

local function closeCurrentPopup()
	if not isShowing() then return end
	if windowRef then
		local closeTween = TweenService:Create(windowRef, TweenInfo.new(0.2), {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.55, 0),
		})
		if overlayRef then
			TweenService:Create(overlayRef, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
		end
		closeTween:Play()
		closeTween.Completed:Wait()
		if overlayRef then overlayRef.Visible = false end
	end
	isShowing(false)
	showNextPopup()
end

local function MajorPopup()
	local overlay = create("Frame") {
		Name = "MajorPopupOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 100,
		Visible = false,
		Active = true,
	}
	overlayRef = overlay

	local window = create("Frame") {
		Name = "MajorPopupWindow",
		Size = UDim2.new(0, 520, 0, 360),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.55, 0),
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		ZIndex = 101,
		Visible = false,
		Parent = overlay,

		create("UICorner") { CornerRadius = UDim.new(0, 14) },
		create("UIStroke") { Color = theme.RedSoft, Thickness = 1 },
		create("UIGradient") {
			Color = ColorSequence.new(theme.Panel, theme.Bg2),
			Rotation = 90,
		},

		create("TextLabel") {
			Name = "Title",
			Size = UDim2.new(1, -56, 0, 38),
			Position = UDim2.new(0, 28, 0, 24),
			BackgroundTransparency = 1,
			TextColor3 = theme.Text,
			TextSize = 24,
			Font = Enum.Font.GothamBlack,
			Text = titleText,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = 1,
			ZIndex = 102,
		},
		create("TextLabel") {
			Name = "Body",
			Size = UDim2.new(1, -70, 0, 76),
			Position = UDim2.new(0, 35, 0, 78),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(205, 205, 218),
			TextSize = 15,
			Font = Enum.Font.GothamMedium,
			Text = bodyText,
			TextWrapped = true,
			RichText = true,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = 2,
			ZIndex = 102,
		},
		create("Frame") {
			Name = "Highlight",
			Size = UDim2.new(1, -70, 0, 44),
			Position = UDim2.new(0, 35, 0, 166),
			BackgroundColor3 = toneBgColor,
			BorderSizePixel = 0,
			ZIndex = 102,
			LayoutOrder = 3,
			create("UICorner") { CornerRadius = UDim.new(0, 8) },
			create("UIStroke") { Color = theme.Stroke, Thickness = 1 },
			create("TextLabel") {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				TextColor3 = toneColor,
				TextSize = 20,
				Font = Enum.Font.GothamBlack,
				Text = highlightText,
				TextWrapped = true,
				RichText = true,
				ZIndex = 103,
			},
		},
		create("TextLabel") {
			Name = "Footer",
			Size = UDim2.new(1, -70, 0, 48),
			Position = UDim2.new(0, 35, 0, 222),
			BackgroundTransparency = 1,
			TextColor3 = theme.Muted,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			Text = footerText,
			TextWrapped = true,
			RichText = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Top,
			Visible = footerVisible,
			LayoutOrder = 4,
			ZIndex = 102,
		},
		(function()
			local btn = create("TextButton") {
				Name = "ContinueButton",
				Size = UDim2.new(0, 180, 0, 38),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -22),
				BackgroundColor3 = toneColor,
				BorderSizePixel = 0,
				TextColor3 = theme.Text,
				TextSize = 13,
				Font = Enum.Font.GothamBlack,
				Text = "CONTINUE",
				AutoButtonColor = false,
				LayoutOrder = 5,
				ZIndex = 102,
				create("UICorner") { CornerRadius = UDim.new(0, 8) },
				create("UIStroke") { Color = theme.RedSoft, Thickness = 1 },
			}
			btn.MouseButton1Click:Connect(closeCurrentPopup)
			return btn
		end)(),
	}
	windowRef = window

	overlay.InputBegan:Connect(function(input)
		if not isShowing() then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local pos = window.AbsolutePosition
		local size = window.AbsoluteSize
		local mouse = UserInputService:GetMouseLocation()
		if mouse.X < pos.X or mouse.X > pos.X + size.X or mouse.Y < pos.Y or mouse.Y > pos.Y + size.Y then
			closeCurrentPopup()
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if not isShowing() then return end
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
			closeCurrentPopup()
		end
	end)

	local smp = remotes.get("ShowMajorPopup")
	if smp then
		smp.OnClientEvent:Connect(function(data)
			if typeof(data) == "table" then
				queueMajorPopup(data)
			end
		end)
	end

	return overlay
end

return MajorPopup
