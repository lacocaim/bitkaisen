local TweenService = game:GetService("TweenService")

local vide = require("@packages/vide")
local container = require("@ui-components/core/container")
local text = require("@ui-components/core/text")
local stroke = require("@ui-components/core/stroke")
local theme = require("@ui/theme")
local px = require("@ui/px")
local uiState = require("@ui-state/uiState")
local navRegistry = require("@ui-state/navRegistry")

local create = vide.create
local derive = vide.derive
local source = vide.source
local indexes = vide.indexes

local TWEEN_QUICK = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HOVER_BG = Color3.fromRGB(28, 28, 38)

local function NavButton(entry: { id: string, label: string, color: Color3? })
	local isActive = derive(function()
		return uiState.activeRoute() == entry.id
	end)

	local hovered = source(false)
	local pressed = source(false)

	local buttonRef: GuiObject = nil :: any
	local strokeRef: UIStroke = nil :: any
	local scaleRef: UIScale = nil :: any

	local function applyVisualState()
		if not buttonRef then return end
		local isHover = hovered()
		local isPress = pressed()
		local active = isActive()

		local targetBg = if active then theme.Panel3 elseif isHover then HOVER_BG else theme.Panel2
		local targetScale = if isPress then 0.95 elseif isHover then 1.03 else 1

		TweenService:Create(buttonRef, TWEEN_QUICK, { BackgroundColor3 = targetBg }):Play()
		if scaleRef then
			TweenService:Create(scaleRef, TweenInfo.new(0.1, Enum.EasingStyle.Quad), { Scale = targetScale }):Play()
		end
	end

	local theStroke = create("UIStroke") {
		Color = function()
			return if isActive() or hovered() then (entry.color or theme.Red) else theme.Stroke
		end,
		Thickness = 1,
	}
	strokeRef = theStroke :: any

	local theScale = create("UIScale") { Scale = 1 }
	scaleRef = theScale

	local theAccent = create("Frame") {
		Name = "Accent",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 7, 0.5, 0),
		Size = UDim2.new(0, 3, 0, 12),
		BackgroundColor3 = entry.color or theme.Red,
		BorderSizePixel = 0,
		create("UICorner") { CornerRadius = UDim.new(1, 0) },
	}

	local btn = container {
		name = entry.id .. "Button",
		h = px(32),
		color = function()
			return isActive() and theme.Panel3 or theme.Panel2
		end,
		corner = 7,
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
			if _G.BitKaisenPlaySFX then _G.BitKaisenPlaySFX("Click") end
			uiState.navigate(entry.id)
		end,
		create("UIFlexItem") { FlexMode = Enum.UIFlexMode.Fill },
		theStroke,
		theScale,
		theAccent,
		text {
			text = entry.label,
			color = function()
				return if isActive() or hovered() then theme.Text else theme.SubText
			end,
			size = px(18),
			font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold),
			truncate = "end",
			ws = 1, hs = 1,
		},
	}
	buttonRef = btn :: any

	return btn
end

local function NavPanel()
	return create("Frame") {
		Name = "NavPanel",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		create("UIListLayout") {
			Name = "NavLayout",
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 5),
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
		},

		indexes(function()
			local _ = navRegistry.version()
			return navRegistry.getEntries()
		end, function(value)
			local entry = value()
			return NavButton({
				id = entry.id,
				label = entry.label,
				color = entry.color,
			})
		end),
	}
end

return NavPanel
