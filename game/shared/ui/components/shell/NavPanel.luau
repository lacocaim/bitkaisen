local vide = require("@packages/vide")
local container = require("@ui-components/core/container")
local text = require("@ui-components/core/text")
local stroke = require("@ui-components/core/stroke")
local gradient = require("@ui-components/core/gradient")
local theme = require("@ui/theme")
local uiState = require("@ui-state/uiState")
local navRegistry = require("@ui-state/navRegistry")

local create = vide.create
local derive = vide.derive
local source = vide.source
local indexes = vide.indexes

local function NavButton(entry: { id: string, label: string, color: Color3? })
	local isActive = derive(function()
		return uiState.activeRoute() == entry.id
	end)

	return container {
		name = entry.id .. "Button",
		ws = 0.86, h = 42,
		color = function()
			return isActive() and theme.Panel3 or theme.Panel2
		end,
		corner = 9,
		clicked = function()
			uiState.navigate(entry.id)
		end,
		stroke { color = theme.Stroke },
		container {
			name = "Accent",
			w = 4, hs = 1, h = -14,
			x = 8, y = 7,
			color = entry.color or theme.Red,
			corner = 999,
		},
		text {
			text = entry.label,
			color = function()
				return isActive() and theme.Text or theme.SubText
			end,
			size = 14,
			font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold),
			ws = 1, hs = 1,
		},
	}
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
				Padding = UDim.new(0, 10),
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
