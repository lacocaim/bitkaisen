local vide = require("@packages/vide")
local container = require("@ui-components/core/container")
local text = require("@ui-components/core/text")
local stroke = require("@ui-components/core/stroke")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")

local source = vide.source

local function AgeUpButton()
	local busy = source(false)

	return container {
		name = "ActionRow",
		ws = 0.61, hs = 0.08,
		xs = 0.025, ys = 0.86,

		container {
			name = "AgeUpButton",
			ws = 1, hs = 1,
			color = theme.RedDark,
			corner = 10,
			clicked = function()
				if busy() then return end
				busy(true)
				if _G.BitKaisenPlaySFX then _G.BitKaisenPlaySFX("Tick") end
				local ule = remotes.updateLifeEvent()
				if ule then
					ule:FireServer("AgeUp")
				end
				task.delay(0.35, function() busy(false) end)
			end,
			stroke { color = theme.Red },
			text {
				text = "+ AGE",
				color = theme.Text,
				size = 22,
				font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold),
				ws = 1, hs = 1,
			},
		},
	}
end

return AgeUpButton
