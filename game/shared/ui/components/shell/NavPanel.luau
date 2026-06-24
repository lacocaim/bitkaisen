local TweenService = game:GetService("TweenService")

local vide = require("@packages/vide")
local container = require("@ui-components/core/container")
local text = require("@ui-components/core/text")
local stroke = require("@ui-components/core/stroke")
local gradient = require("@ui-components/core/gradient")
local theme = require("@ui/theme")
local px = require("@ui/px")
local uiState = require("@ui-state/uiState")
local navRegistry = require("@ui-state/navRegistry")

local create = vide.create
local derive = vide.derive
local source = vide.source
local indexes = vide.indexes

local TWEEN_QUICK = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HOVER_BG = Color3.fromRGB(25, 25, 32)
local HOVER_STROKE = Color3.fromRGB(170, 58, 58)
local HOVER_ACCENT = Color3.fromRGB(255, 90, 90)

local function NavButton(entry: { id: string, label: string, color: Color3? })
	local isActive = derive(function()
		return uiState.activeRoute() == entry.id
	end)

	local hovered = source(false)
	local pressed = source(false)

	local buttonRef: GuiObject = nil :: any
	local strokeRef: UIStroke = nil :: any
	local accentRef: GuiObject = nil :: any
	local glowRef: Frame = nil :: any
	local glowStrokeRef: UIStroke = nil :: any
	local scaleRef: UIScale = nil :: any

	local function applyVisualState()
		if not buttonRef then return end
		local isHover = hovered()
		local isPress = pressed()
		local active = isActive()

		local targetBg = if active then theme.Panel3 elseif isHover then HOVER_BG else theme.Panel2
		local targetStroke = if isHover then HOVER_STROKE else theme.Stroke
		local targetAccent = if isHover then HOVER_ACCENT else (entry.color or theme.Red)
		local targetScale = if isPress then (if isHover then 0.985 else 0.975) elseif isHover then 1.015 else 1

		TweenService:Create(buttonRef, TWEEN_QUICK, { BackgroundColor3 = targetBg }):Play()
		if strokeRef then
			TweenService:Create(strokeRef, TWEEN_QUICK, { Color = targetStroke }):Play()
		end
		if accentRef then
			TweenService:Create(accentRef, TWEEN_QUICK, { BackgroundColor3 = targetAccent }):Play()
		end
		if glowRef then
			TweenService:Create(glowRef, TWEEN_QUICK, {
				BackgroundTransparency = if isHover then 0.92 else 1,
			}):Play()
		end
		if glowStrokeRef then
			TweenService:Create(glowStrokeRef, TWEEN_QUICK, {
				Transparency = if isHover then 0.35 else 1,
				Thickness = if isHover then 2 else 1,
			}):Play()
		end
		if scaleRef then
			TweenService:Create(scaleRef, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Scale = targetScale,
			}):Play()
		end
	end

	local theStroke = stroke { color = theme.Stroke }
	strokeRef = theStroke :: any

	local theScale = create("UIScale") { Scale = 1 }
	scaleRef = theScale

	local theGlowStroke = create("UIStroke") {
		Name = "GlowStroke",
		Color = theme.RedSoft,
		Thickness = 1,
		Transparency = 1,
	}
	glowStrokeRef = theGlowStroke

	local theGlow = create("Frame") {
		Name = "HoverGlow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 8, 1, 8),
		BackgroundColor3 = theme.RedSoft,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 0,
		create("UICorner") { CornerRadius = UDim.new(0, 12) },
		theGlowStroke,
	}
	glowRef = theGlow

	local theAccent = container {
		name = "Accent",
		w = 4, hs = 1, h = -14,
		x = 8, y = 7,
		color = entry.color or theme.Red,
		corner = 999,
	}
	accentRef = theAccent :: any

	local btn = container {
		name = entry.id .. "Button",
		ws = 0.86, h = px(42),
		color = function()
			return isActive() and theme.Panel3 or theme.Panel2
		end,
		corner = 9,
		hover = function(state)
			hovered(state)
			if not state then pressed(false) end
			applyVisualState()
		end,
		hold = function(state)
			pressed(state)
			applyVisualState()
		end,
		clicked = function()
			pressed(false)
			applyVisualState()
			uiState.navigate(entry.id)
		end,
		theStroke,
		theScale,
		theGlow,
		theAccent,
		text {
			text = entry.label,
			color = function()
				return if isActive() or hovered() then theme.Text else theme.SubText
			end,
			size = px(14),
			font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold),
			truncate = "end",
			ws = 1, hs = 1,
		},
	}
	buttonRef = btn :: any

	return btn
end

local function NavPanel()
	return container {
		name = "NavPanel",
		ws = 0.30, hs = 0.28,
		xs = 0.67, ys = 0.68,
		color = theme.Panel,
		corner = 12,
		clips = true,
		gradient { color = ColorSequence.new(theme.Panel, theme.Bg2), rotation = 90 },
		stroke { color = theme.StrokeSoft },

		create("ScrollingFrame") {
			Name = "NavScroll",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 0,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(0, 0, 0, 0),

			create("UIListLayout") {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = px.udim(0, 10),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			},

			indexes(function()
				local _ = navRegistry.version()
				return navRegistry.getEntries()
			end, function(value, index)
				local entry = value()
				return NavButton({
					id = entry.id,
					label = entry.label,
					color = entry.color,
				})
			end),
		},
	}
end

return NavPanel
