local vide = require("@packages/vide")
local container = require("@ui-components/core/container")
local stroke = require("@ui-components/core/stroke")
local theme = require("@ui/theme")
local uiState = require("@ui-state/uiState")

local create = vide.create

local function SettingsButton()
	return container {
		name = "MainMenuButton",
		w = 42, h = 42,
		anchor = { 1, 0 },
		xs = 1, x = -18,
		ys = 0, y = 16,
		color = theme.Panel2,
		corner = 999,
		z = 5,
		clicked = function()
			uiState.navigate("settings")
		end,
		stroke { color = theme.Stroke },
		container {
			name = "Accent",
			anchor = { 0.5, 0.5 },
			xs = 0.5, ys = 0.5,
			ws = 1, w = -10, hs = 1, h = -10,
			corner = 999,
			stroke { color = theme.RedSoft },
		},
		create("TextLabel") {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			TextColor3 = theme.Text,
			TextSize = 25,
			Font = Enum.Font.GothamBlack,
			Text = utf8.char(0x2630),
			ZIndex = 6,
		},
	}
end

return SettingsButton
