local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local uiState = require("@ui-state/uiState")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local create = vide.create

local CATEGORY_COLORS = {
	Life = theme.CategoryColors.Life,
	School = theme.CategoryColors.School,
	Training = theme.CategoryColors.Training,
	Jujutsu = theme.CategoryColors.Jujutsu,
	Social = theme.CategoryColors.Social,
	Career = theme.CategoryColors.Career,
	Crime = theme.CategoryColors.Crime,
	Misc = theme.CategoryColors.Misc,
}

local CATEGORY_ORDER = { "Life", "School", "Training", "Jujutsu", "Social", "Career", "Crime", "Misc" }

local function buildActivities(parent: Frame)
	local titleLabel = create("TextLabel") {
		Name = "Title",
		Size = UDim2.new(1, -50, 0, 30),
		Position = UDim2.new(0, 16, 0, 10),
		BackgroundTransparency = 1,
		TextColor3 = theme.Gold,
		TextSize = 20,
		Font = Enum.Font.GothamBlack,
		Text = "ACTIVITIES",
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 55,
		Parent = parent,
	}

	local categoryRail = create("ScrollingFrame") {
		Name = "CategoryRail",
		Size = UDim2.new(0, 120, 1, -50),
		Position = UDim2.new(0, 0, 0, 50),
		BackgroundColor3 = theme.Bg2,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ZIndex = 52,
		Parent = parent,

		create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) },
		create("UIPadding") { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) },
	}

	local scroll = create("ScrollingFrame") {
		Name = "Scroll",
		Size = UDim2.new(1, -130, 1, -50),
		Position = UDim2.new(0, 130, 0, 50),
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
			PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
		},
	}

	local getActivityList = remotes.getActivityList()
	if not getActivityList then
		factory.createMessageCard(scroll, "Activity system unavailable.")
		return
	end

	local ok, payload = pcall(function() return getActivityList:InvokeServer() end)
	if not ok or typeof(payload) ~= "table" then
		factory.createMessageCard(scroll, "Failed to load activities.")
		return
	end

	local categorized = payload.Categorized or payload
	local categoryHeaders = {}
	local cardOrder = 1

	for catIdx, catName in CATEGORY_ORDER do
		local catActivities = categorized[catName]
		if catActivities and #catActivities > 0 then
			local catColor = CATEGORY_COLORS[catName] or theme.SubText

			local headerFrame = create("Frame") {
				Name = "CategoryHeader_" .. catName,
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundTransparency = 1,
				LayoutOrder = cardOrder,
				ZIndex = 53,
				Parent = scroll,
			}
			categoryHeaders[catName] = headerFrame
			cardOrder += 1

			create("TextLabel") {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				TextColor3 = catColor,
				TextSize = 15,
				Font = Enum.Font.GothamBlack,
				Text = string.upper(catName),
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 54,
				Parent = headerFrame,
			}

			local catBtn = create("TextButton") {
				Name = "CatBtn_" .. catName,
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundColor3 = theme.Panel2,
				TextColor3 = catColor,
				TextSize = 11,
				Font = Enum.Font.GothamBold,
				Text = catName,
				AutoButtonColor = false,
				LayoutOrder = catIdx,
				ZIndex = 53,
				Parent = categoryRail,
				create("UICorner") { CornerRadius = UDim.new(0, 6) },
				[vide.action(function(btn)
					btn.MouseButton1Click:Connect(function()
						local header = categoryHeaders[catName]
						if header then
							local yPos = header.AbsolutePosition.Y - scroll.AbsolutePosition.Y + scroll.CanvasPosition.Y
							scroll.CanvasPosition = Vector2.new(0, math.max(0, yPos - 10))
						end
					end)
				end)] = true,
			}

			for j, activity in catActivities do
				local canDo = activity.CanDo ~= false
				factory.createCard(scroll, cardOrder, {
					title = tostring(activity.Name or activity.Id or "Activity"),
					subtitle = canDo and "AVAILABLE" or "LOCKED",
					body = tostring(activity.Description or ""),
					accentColor = canDo and catColor or theme.Muted,
					actions = canDo and {
						{
							label = "DO",
							callback = function()
								if not activity.Id then return end
								local ule = remotes.updateLifeEvent()
								if ule then ule:FireServer("DoActivity", activity.Id) end
								uiState.closeRoute()
							end,
						},
					} or nil,
				})
				cardOrder += 1
			end
		end
	end
end

local function init()
	OverlayPanel.registerPanelBuilder("activities", buildActivities)
end

return { init = init }
