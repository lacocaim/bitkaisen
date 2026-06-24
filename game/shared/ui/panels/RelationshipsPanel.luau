local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local uiState = require("@ui-state/uiState")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local create = vide.create

local STAT_COLORS = {
	Bond = theme.Green,
	Trust = theme.Blue,
	Respect = Color3.fromRGB(255, 210, 100),
	Fear = Color3.fromRGB(210, 90, 90),
	Romance = Color3.fromRGB(255, 120, 190),
}

local function createStatBar(parent: Frame, label: string, value: number, maxVal: number, color: Color3, order: number)
	local frac = math.clamp(value / math.max(maxVal, 1), 0, 1)
	local bar = create("Frame") {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		ZIndex = 55,
		Parent = parent,
	}
	create("TextLabel") {
		Size = UDim2.new(0.3, 0, 1, 0),
		BackgroundTransparency = 1,
		TextColor3 = color,
		TextSize = 11,
		Font = Enum.Font.GothamBold,
		Text = label .. " " .. tostring(value),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 56,
		Parent = bar,
	}
	local track = create("Frame") {
		Size = UDim2.new(0.7, 0, 0.5, 0),
		Position = UDim2.new(0.3, 0, 0.25, 0),
		BackgroundColor3 = Color3.fromRGB(25, 25, 30),
		BorderSizePixel = 0,
		ZIndex = 55,
		Parent = bar,
		create("UICorner") { CornerRadius = UDim.new(0, 999) },
	}
	create("Frame") {
		Size = UDim2.new(frac, 0, 1, 0),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = 56,
		Parent = track,
		create("UICorner") { CornerRadius = UDim.new(0, 999) },
	}
end

local function buildRelationships(parent: Frame)
	local scroll, title = factory.createCardList(parent, "RELATIONSHIPS")

	local getRelationships = remotes.getRelationships()
	if not getRelationships then
		factory.createMessageCard(scroll, "Relationship system unavailable.")
		return
	end

	local ok, relationships = pcall(function() return getRelationships:InvokeServer() end)
	if not ok or typeof(relationships) ~= "table" then
		factory.createMessageCard(scroll, "Failed to load relationships.")
		return
	end

	if #relationships == 0 then
		factory.createMessageCard(scroll, "You haven't met anyone yet.")
		return
	end

	for i, rel in relationships do
		local name = tostring(rel.Name or "Unknown")
		local role = tostring(rel.Role or "")
		local alive = rel.Alive ~= false
		local subtitle = role .. (alive and "" or " (Deceased)")
		local accentColor = alive and theme.Stroke or theme.Muted

		local card = factory.createCard(scroll, i, {
			title = name,
			subtitle = subtitle,
			accentColor = accentColor,
		})

		local barParent = card
		local barOrder = 5
		for _, statName in { "Bond", "Trust", "Respect", "Fear", "Romance" } do
			local val = tonumber(rel[statName]) or 0
			if val ~= 0 or statName == "Bond" then
				createStatBar(barParent, statName, val, 100, STAT_COLORS[statName] or theme.SubText, barOrder)
				barOrder += 1
			end
		end

		if alive then
			local actionRow = create("Frame") {
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundTransparency = 1,
				LayoutOrder = 20,
				ZIndex = 54,
				Parent = card,
				create("UIListLayout") {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 6),
					SortOrder = Enum.SortOrder.LayoutOrder,
				},
			}
			local actions = { "Hang Out", "Train Together", "Talk" }
			for j, actLabel in actions do
				create("TextButton") {
					Size = UDim2.new(0, 80, 1, 0),
					BackgroundColor3 = theme.Button,
					TextColor3 = theme.Text,
					TextSize = 11,
					Font = Enum.Font.GothamBold,
					Text = actLabel,
					AutoButtonColor = false,
					LayoutOrder = j,
					ZIndex = 55,
					Parent = actionRow,
					create("UICorner") { CornerRadius = UDim.new(0, 6) },
					[vide.action(function(btn)
						btn.MouseButton1Click:Connect(function()
							local ra = remotes.relationshipAction()
							if ra then ra:FireServer(actLabel, rel.Id or rel.Name) end
						end)
					end)] = true,
				}
			end
		end
	end
end

local function init()
	OverlayPanel.registerPanelBuilder("relationships", buildRelationships)
end

return { init = init }
