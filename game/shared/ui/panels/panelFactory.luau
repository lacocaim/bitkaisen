local vide = require("@packages/vide")
local theme = require("@ui/theme")

local create = vide.create

local function createCardList(parent: Frame, title: string)
	local titleLabel = create("TextLabel") {
		Name = "Title",
		Size = UDim2.new(1, -50, 0, 30),
		Position = UDim2.new(0, 16, 0, 10),
		BackgroundTransparency = 1,
		TextColor3 = theme.Gold,
		TextSize = 20,
		Font = Enum.Font.GothamBlack,
		Text = title,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 55,
		Parent = parent,
	}

	local scroll = create("ScrollingFrame") {
		Name = "Scroll",
		Size = UDim2.new(1, 0, 1, -50),
		Position = UDim2.new(0, 0, 0, 50),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = theme.Stroke,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 52,
		Parent = parent,

		create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) },
		create("UIPadding") {
			PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 16),
			PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16),
		},
	}

	return scroll, titleLabel
end

local function createCard(parent: Frame, order: number, props: {
	title: string?,
	subtitle: string?,
	body: string?,
	bodyColor: Color3?,
	accentColor: Color3?,
	actions: { { label: string, callback: () -> () } }?,
})
	local card = create("Frame") {
		Name = "Card_" .. tostring(order),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Card,
		BorderSizePixel = 0,
		LayoutOrder = order,
		ZIndex = 53,
		Parent = parent,

		create("UICorner") { CornerRadius = UDim.new(0, 10) },
		create("UIStroke") { Color = props.accentColor or theme.Stroke },
		create("UIPadding") {
			PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
		},
		create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) },
	}

	if props.title then
		create("TextLabel") {
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			TextColor3 = theme.Text,
			TextSize = 16,
			Font = Enum.Font.GothamBold,
			Text = props.title,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 1,
			ZIndex = 54,
			Parent = card,
		}
	end

	if props.subtitle then
		create("TextLabel") {
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			TextColor3 = props.accentColor or theme.SubText,
			TextSize = 13,
			Font = Enum.Font.GothamBold,
			Text = props.subtitle,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
			ZIndex = 54,
			Parent = card,
		}
	end

	if props.body then
		create("TextLabel") {
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			TextColor3 = props.bodyColor or theme.SubText,
			TextSize = 12,
			Font = Enum.Font.GothamMedium,
			Text = props.body,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			RichText = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 3,
			ZIndex = 54,
			Parent = card,
		}
	end

	if props.actions and #props.actions > 0 then
		local actionRow = create("Frame") {
			Name = "Actions",
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			LayoutOrder = 10,
			ZIndex = 54,
			Parent = card,
			create("UIListLayout") {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			},
		}
		for i, act in props.actions do
			create("TextButton") {
				Size = UDim2.new(0, 90, 1, 0),
				BackgroundColor3 = theme.Button,
				TextColor3 = theme.Text,
				TextSize = 12,
				Font = Enum.Font.GothamBold,
				Text = act.label,
				AutoButtonColor = false,
				LayoutOrder = i,
				ZIndex = 55,
				Parent = actionRow,
				create("UICorner") { CornerRadius = UDim.new(0, 6) },
				[vide.action(function(btn)
					btn.MouseButton1Click:Connect(act.callback)
				end)] = true,
			}
		end
	end

	return card
end

local function createMessageCard(parent: Frame, text: string, order: number?)
	return create("TextLabel") {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		TextColor3 = theme.Muted,
		TextSize = 14,
		Font = Enum.Font.GothamMedium,
		Text = text,
		TextWrapped = true,
		LayoutOrder = order or 0,
		ZIndex = 53,
		Parent = parent,
	}
end

return {
	createCardList = createCardList,
	createCard = createCard,
	createMessageCard = createMessageCard,
}
