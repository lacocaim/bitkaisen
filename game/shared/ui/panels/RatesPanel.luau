local vide = require("@packages/vide")
local theme = require("@ui/theme")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local create = vide.create

local RATES_TEXT = [[<b>Clan Rates:</b>
- Gojo Clan: <font color="#78BEFF">0.5%</font>
- Zenin Clan: <font color="#78BEFF">1%</font>
- Kamo Clan: <font color="#78BEFF">1.5%</font>
- Normal Family: <font color="#A5A5B9">97%</font>

<b>Cursed Technique Rates:</b>
- Innate Technique at birth: <font color="#B27AFF">15%</font>
- Awakening by age 12: <font color="#B27AFF">25%</font>
- Late awakening (13-16): <font color="#B27AFF">10%</font>

<b>Trait Rates:</b>
- Legendary: <font color="#FFCD69">0.5%</font>
- Epic: <font color="#BE82FF">2%</font>
- Rare: <font color="#78BEFF">8%</font>
- Uncommon: <font color="#78F0A0">20%</font>
- Common: <font color="#BEBEC8">69.5%</font>]]

local function buildRates(parent: Frame)
	local scroll, title = factory.createCardList(parent, "RATES & PROBABILITIES")

	create("TextLabel") {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		TextColor3 = theme.Text,
		TextSize = 14,
		Font = Enum.Font.GothamMedium,
		Text = RATES_TEXT,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		RichText = true,
		LayoutOrder = 1,
		ZIndex = 53,
		Parent = scroll,
	}
end

local function init()
	OverlayPanel.registerPanelBuilder("rates", buildRates)
end

return { init = init }
