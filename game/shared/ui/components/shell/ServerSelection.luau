local TweenService = game:GetService("TweenService")

local vide = require("@packages/vide")
local theme = require("@ui/theme")
local device = require("@ui-state/device")
local remotes = require("@ui-state/remotes")

local create = vide.create
local source = vide.source

local SHOW_EVERY_JOIN = false

local CROSS_PLATFORM_COLOR = Color3.fromRGB(100, 160, 235)
local MOBILE_COLOR = Color3.fromRGB(235, 100, 115)

local TWEEN_HOVER = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local _visible = source(false)
local _onDismiss: (() -> ())? = nil

local function setOnDismiss(fn: () -> ())
	_onDismiss = fn
end

local function show()
	_visible(true)
end

local function shouldShow(savedMode: string?): boolean
	if SHOW_EVERY_JOIN then return true end
	if savedMode and (savedMode == "CrossPlatform" or savedMode == "Mobile") then
		return false
	end
	return true
end

local function pick(mode: device.UiMode)
	device.setUiMode(mode)

	local evt = remotes.updateSettingsEvent()
	if evt then
		(evt :: RemoteEvent):FireServer("PlatformMode", mode)
	end

	_visible(false)

	if _onDismiss then
		task.defer(_onDismiss)
	end
end

local function ModeCard(props: {
	title: string,
	subtitle: string,
	accent: Color3,
	mode: device.UiMode,
	iconText: string,
	recommended: boolean,
})
	local hovered = source(false)

	local card = create("ImageButton") {
		Name = props.mode .. "Card",
		Size = UDim2.new(0.42, 0, 0.55, 0),
		BackgroundColor3 = props.accent,
		BorderSizePixel = 0,
		AutoButtonColor = false,

		create("UICorner") { CornerRadius = UDim.new(0, 16) },
		create("UIStroke") {
			Color = Color3.new(1, 1, 1),
			Thickness = function()
				return if props.recommended then 3 else (if hovered() then 2 else 0)
			end,
			Transparency = function()
				return if props.recommended then 0.3 else (if hovered() then 0.5 else 1)
			end,
		},

		create("Frame") {
			Name = "IconHolder",
			Size = UDim2.new(0.5, 0, 0.45, 0),
			Position = UDim2.new(0.25, 0, 0.06, 0),
			BackgroundColor3 = props.accent,
			BorderSizePixel = 0,
			create("UICorner") { CornerRadius = UDim.new(0, 12) },
			create("TextLabel") {
				Name = "Icon",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 48,
				Font = Enum.Font.GothamBlack,
				Text = props.iconText,
				TextScaled = true,
			},
		},

		create("TextLabel") {
			Name = "Title",
			Size = UDim2.new(0.9, 0, 0.14, 0),
			Position = UDim2.new(0.05, 0, 0.55, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 22,
			Font = Enum.Font.GothamBlack,
			Text = props.title,
			TextScaled = true,
			create("UITextSizeConstraint") { MaxTextSize = 22, MinTextSize = 10 },
		},

		create("TextLabel") {
			Name = "Subtitle",
			Size = UDim2.new(0.85, 0, 0.14, 0),
			Position = UDim2.new(0.075, 0, 0.72, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.new(1, 1, 1),
			TextTransparency = 0.15,
			TextSize = 14,
			Font = Enum.Font.GothamBold,
			Text = props.subtitle,
			TextScaled = true,
			TextWrapped = true,
			create("UITextSizeConstraint") { MaxTextSize = 14, MinTextSize = 8 },
		},

		create("TextLabel") {
			Name = "Recommended",
			Size = UDim2.new(0.7, 0, 0.08, 0),
			Position = UDim2.new(0.15, 0, 0.88, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.new(1, 1, 1),
			TextTransparency = function()
				return if props.recommended then 0.2 else 1
			end,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
			Text = "RECOMMENDED",
			TextScaled = true,
			create("UITextSizeConstraint") { MaxTextSize = 11, MinTextSize = 6 },
		},
	}

	card.MouseEnter:Connect(function()
		hovered(true)
		TweenService:Create(card, TWEEN_HOVER, { BackgroundColor3 = props.accent:Lerp(Color3.new(1, 1, 1), 0.1) }):Play()
	end)
	card.MouseLeave:Connect(function()
		hovered(false)
		TweenService:Create(card, TWEEN_HOVER, { BackgroundColor3 = props.accent }):Play()
	end)
	card.MouseButton1Click:Connect(function()
		pick(props.mode)
	end)

	return card
end

local function ServerSelection()
	local isTouchDevice = device.isTouchPrimary()

	local overlay = create("Frame") {
		Name = "ServerSelectionOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0,
		ZIndex = 9000,
		Visible = function()
			return _visible()
		end,

		create("TextLabel") {
			Name = "Title",
			Size = UDim2.new(0.8, 0, 0.1, 0),
			Position = UDim2.new(0.1, 0, 0.05, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 42,
			Font = Enum.Font.GothamBlack,
			Text = "Server Selection",
			TextScaled = true,
			ZIndex = 9001,
			create("UITextSizeConstraint") { MaxTextSize = 42, MinTextSize = 16 },
		},

		create("Frame") {
			Name = "CardContainer",
			Size = UDim2.new(0.85, 0, 0.7, 0),
			Position = UDim2.new(0.075, 0, 0.18, 0),
			BackgroundTransparency = 1,
			ZIndex = 9001,

			create("UIListLayout") {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0.04, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
			},

			ModeCard({
				title = "Cross Platform",
				subtitle = "Join an all platform server!",
				accent = CROSS_PLATFORM_COLOR,
				mode = "CrossPlatform",
				iconText = "\xF0\x9F\x8C\x90",
				recommended = not isTouchDevice,
			}),

			ModeCard({
				title = "Mobile",
				subtitle = "Join a mobile only server!",
				accent = MOBILE_COLOR,
				mode = "Mobile",
				iconText = "\xF0\x9F\x93\xB1",
				recommended = isTouchDevice,
			}),
		},
	}

	return overlay
end

return {
	create = ServerSelection,
	show = show,
	shouldShow = shouldShow,
	setOnDismiss = setOnDismiss,
	visible = _visible,
}
