local vide = require("@packages/vide")
local container = require("@ui-components/core/container")
local text = require("@ui-components/core/text")
local theme = require("@ui/theme")
local px = require("@ui/px")
local uiState = require("@ui-state/uiState")
local navRegistry = require("@ui-state/navRegistry")

local create = vide.create
local derive = vide.derive

local PADDING = 6

local function NavButton(entry: { id: string, label: string, color: Color3? })
	local isActive = derive(function()
		return uiState.activeRoute() == entry.id
	end)

	local hovered = false
	local buttonRef: GuiObject = nil :: any

	local theAccent = create("Frame") {
		Name = "Accent",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.new(0, 3, 0, 16),
		BackgroundColor3 = entry.color or theme.Red,
		BorderSizePixel = 0,
		create("UICorner") { CornerRadius = UDim.new(1, 0) },
	}

	local btn = container {
		name = entry.id .. "Button",
		h = 32,
		color = function()
			return isActive() and theme.Panel3 or theme.Panel2
		end,
		corner = 7,
		hover = function(state)
			hovered = state
		end,
		clicked = function()
			if _G.BitKaisenPlaySFX then _G.BitKaisenPlaySFX("Click") end
			uiState.navigate(entry.id)
		end,
		create("UIStroke") {
			Color = function()
				return if isActive() then (entry.color or theme.Red) else theme.Stroke
			end,
			Thickness = 1,
		},
		theAccent,
		text {
			text = entry.label,
			color = function()
				return isActive() and theme.Text or theme.SubText
			end,
			size = px(16),
			font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold),
			truncate = "end",
			xalign = "left",
			x = 18, w = -26,
			ws = 1, hs = 1,
		},
	}
	buttonRef = btn :: any
	btn.Size = UDim2.new(0, 190, 0, 32)

	return btn
end

-- Sizes every NavButton so the row fills the full width of navPanelObj with no
-- dead space. Call after the panel has real AbsoluteSize (e.g. from
-- applyResponsiveLayout in BitKaisenClient, which runs post-layout).
local function fitButtonsToWidth(navPanelObj: Instance, padding: number?)
	local pad = padding or PADDING
	local entries = navRegistry.getEntries()
	local count = math.max(#entries, 1)
	local totalPadding = pad * (count - 1)
	local w = math.max((navPanelObj.AbsoluteSize.X - totalPadding) / count, 40)
	for _, child in ipairs(navPanelObj:GetChildren()) do
		if child:IsA("GuiButton") then
			child.Size = UDim2.new(0, w, 0, child.Size.Y.Offset)
		end
	end
end

local function NavPanel()
	-- Categories are all registered once at client boot (see
	-- BitKaisenClient/BitKaisenMobileClient) and nothing calls
	-- navRegistry.register/unregister afterwards, so this list never changes
	-- at runtime -- a plain array is enough, no need for vide.indexes().
	local buttons = {}
	for _, entry in navRegistry.getEntries() do
		table.insert(buttons, NavButton({
			id = entry.id,
			label = entry.label,
			color = entry.color,
		}))
	end

	return create("Frame") {
		Name = "NavPanel",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		create("UIListLayout") {
			Name = "NavLayout",
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, PADDING),
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
		},

		buttons,
	}
end

local M = setmetatable({}, { __call = function(_, ...) return NavPanel(...) end })
M.fitButtonsToWidth = fitButtonsToWidth
return M
