local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local uiState = require("@ui-state/uiState")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local create = vide.create

local TAB_ORDER = { "Owned", "Shop", "Dojo" }

local function createTabBar(parent: Frame, currentTab: string, onSelect: (string) -> ())
	local bar = create("Frame") {
		Name = "TabBar",
		Size = UDim2.new(1, -50, 0, 36),
		Position = UDim2.new(0, 16, 0, 44),
		BackgroundTransparency = 1,
		ZIndex = 55,
		Parent = parent,
		create("UIListLayout") {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
	}
	for i, tabName in TAB_ORDER do
		local isActive = tabName == currentTab
		create("TextButton") {
			Size = UDim2.new(0, 80, 1, 0),
			BackgroundColor3 = isActive and theme.Panel3 or theme.Panel2,
			TextColor3 = isActive and theme.Text or theme.SubText,
			TextSize = 13,
			Font = Enum.Font.GothamBold,
			Text = tabName,
			AutoButtonColor = false,
			LayoutOrder = i,
			ZIndex = 56,
			Parent = bar,
			create("UICorner") { CornerRadius = UDim.new(0, 8) },
			[vide.action(function(btn)
				btn.MouseButton1Click:Connect(function() onSelect(tabName) end)
			end)] = true,
		}
	end
	return bar
end

local function buildAssets(parent: Frame)
	local titleLabel = create("TextLabel") {
		Name = "Title",
		Size = UDim2.new(1, -50, 0, 30),
		Position = UDim2.new(0, 16, 0, 10),
		BackgroundTransparency = 1,
		TextColor3 = theme.Gold,
		TextSize = 20,
		Font = Enum.Font.GothamBlack,
		Text = "ASSETS",
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 55,
		Parent = parent,
	}

	local currentTab = "Owned"

	local scroll = create("ScrollingFrame") {
		Name = "Scroll",
		Size = UDim2.new(1, 0, 1, -90),
		Position = UDim2.new(0, 0, 0, 90),
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

	local function clearScroll()
		for _, child in scroll:GetChildren() do
			if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
				child:Destroy()
			end
		end
	end

	local function renderTab(tab: string, payload: { [string]: any })
		clearScroll()
		if tab == "Owned" then
			local items = payload.Owned or {}
			if #items == 0 then
				factory.createMessageCard(scroll, "You don't own any assets yet.")
				return
			end
			for i, item in items do
				factory.createCard(scroll, i, {
					title = tostring(item.Name or "Unknown"),
					subtitle = tostring(item.Type or "Item"),
					body = tostring(item.Description or ""),
				})
			end
		elseif tab == "Shop" then
			local items = payload.Shop or {}
			if #items == 0 then
				factory.createMessageCard(scroll, "No items available in the shop.")
				return
			end
			for i, item in items do
				factory.createCard(scroll, i, {
					title = tostring(item.Name or "Unknown"),
					subtitle = "Price: $" .. tostring(item.Price or 0),
					body = tostring(item.Description or ""),
					actions = {
						{ label = "BUY", callback = function()
							local aa = remotes.assetAction()
							if aa then aa:FireServer("buy", item.Id) end
						end },
					},
				})
			end
		elseif tab == "Dojo" then
			local dojo = payload.Dojo or {}
			if typeof(dojo) == "table" and dojo.HasDojo then
				factory.createCard(scroll, 1, {
					title = "Your Dojo",
					subtitle = "Reputation: " .. tostring(dojo.Reputation or 0),
					body = "Students: " .. tostring(dojo.StudentCount or 0) .. " | Funding: $" .. tostring(dojo.Funding or 0),
				})
			else
				factory.createMessageCard(scroll, "You don't have a dojo yet.")
			end
		end
	end

	local getAssets = remotes.getAssets()
	if not getAssets then
		factory.createMessageCard(scroll, "Asset system unavailable.")
		return
	end

	local ok, payload = pcall(function() return getAssets:InvokeServer() end)
	if not ok or typeof(payload) ~= "table" then
		factory.createMessageCard(scroll, "Failed to load assets.")
		return
	end

	createTabBar(parent, currentTab, function(tab)
		currentTab = tab
		renderTab(tab, payload)
	end)

	renderTab(currentTab, payload)
end

local function init()
	OverlayPanel.registerPanelBuilder("assets", buildAssets)
end

return { init = init }
