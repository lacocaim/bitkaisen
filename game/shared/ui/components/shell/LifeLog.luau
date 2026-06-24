local vide = require("@packages/vide")
local container = require("@ui-components/core/container")
local text = require("@ui-components/core/text")
local stroke = require("@ui-components/core/stroke")
local gradient = require("@ui-components/core/gradient")
local theme = require("@ui/theme")
local playerState = require("@ui-state/playerState")

local create = vide.create
local derive = vide.derive

local function LifeLog()
	local logContent = derive(function()
		local _ = playerState.logVersion()
		local lines = playerState.lifeLog()
		if #lines == 0 then
			return "Loading into the Jujutsu world..."
		end
		return table.concat(lines, "\n")
	end)

	local scrollRef: ScrollingFrame = nil :: any

	return container {
		name = "LogContainer",
		ws = 0.61, hs = 0.76,
		xs = 0.025, ys = 0.07,
		color = theme.Panel,
		corner = 12,
		clips = true,
		gradient { color = ColorSequence.new(theme.Panel, theme.Bg2), rotation = 90 },
		stroke { color = theme.StrokeSoft },

		create("ScrollingFrame") {
			Name = "LifeLog",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = theme.RedSoft,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,

			create("UIListLayout") {
				SortOrder = Enum.SortOrder.LayoutOrder,
				[vide.action(function(layout: UIListLayout)
					layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
						if scrollRef then
							local contentHeight = layout.AbsoluteContentSize.Y + 40
							scrollRef.CanvasPosition = Vector2.new(0, contentHeight)
						end
					end)
				end)] = true,
			},
			create("UIPadding") {
				PaddingTop = UDim.new(0, 20), PaddingBottom = UDim.new(0, 20),
				PaddingLeft = UDim.new(0, 25), PaddingRight = UDim.new(0, 25),
			},

			text {
				name = "LogText",
				text = logContent,
				color = theme.Text,
				size = 17,
				font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
				wraps = true,
				yalign = "top",
				xalign = "left",
				rich = true,
				auto = "y",
				ws = 1,
			},

			[vide.action(function(sf: ScrollingFrame)
				scrollRef = sf
			end)] = true,
		},
	}
end

return LifeLog
