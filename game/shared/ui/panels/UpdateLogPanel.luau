local vide = require("@packages/vide")
local theme = require("@ui/theme")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local create = vide.create

local warm = theme.UpdateLogWarm

local function buildUpdateLog(parent: Frame)
	local scroll, title = factory.createCardList(parent, "UPDATE LOG")
	title.TextColor3 = warm.Gold

	create("TextLabel") {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		TextColor3 = warm.Text,
		TextSize = 14,
		Font = Enum.Font.GothamMedium,
		Text = [[<b>Latest Update</b>

- Full Civilian School System (Elementary through High School)
- Jujutsu Mentor career path for graduated sorcerers
- Activity Category Sidebar with click-to-scroll navigation
- Production hardening and debug logging improvements
- Vide reactive UI migration for better performance

Stay tuned for more updates!]],
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		RichText = true,
		LayoutOrder = 1,
		ZIndex = 53,
		Parent = scroll,
	}
end

local function init()
	OverlayPanel.registerPanelBuilder("update_log", buildUpdateLog)
end

return { init = init }
