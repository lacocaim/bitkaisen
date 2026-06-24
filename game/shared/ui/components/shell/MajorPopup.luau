local TweenService = game:GetService("TweenService")
local vide = require("@packages/vide")
local container = require("@ui-components/core/container")
local text = require("@ui-components/core/text")
local stroke = require("@ui-components/core/stroke")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")

local create = vide.create
local source = vide.source

local popupQueue = {}
local isShowing = source(false)
local titleText = source("")
local bodyText = source("")
local highlightText = source("")
local footerText = source("")
local toneColor = source(theme.Purple)

local overlayRef: Frame? = nil
local windowRef: Frame? = nil

local function showNextPopup()
	if #popupQueue == 0 then
		isShowing(false)
		if overlayRef then
			TweenService:Create(overlayRef, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
			task.delay(0.2, function() if overlayRef then overlayRef.Visible = false end end)
		end
		return
	end

	local data = table.remove(popupQueue, 1)
	titleText(tostring(data.Title or ""))
	bodyText(tostring(data.Body or ""))
	highlightText(tostring(data.Highlight or ""))
	footerText(tostring(data.Footer or ""))

	local tone = tostring(data.Tone or "")
	if tone == "success" then
		toneColor(theme.Green)
	elseif tone == "danger" or tone == "error" then
		toneColor(theme.Bad)
	else
		toneColor(theme.Purple)
	end

	isShowing(true)
	if overlayRef then
		overlayRef.Visible = true
		TweenService:Create(overlayRef, TweenInfo.new(0.25), { BackgroundTransparency = 0.45 }):Play()
	end
	if windowRef then
		windowRef.Position = UDim2.new(0.5, 0, 0.55, 0)
		windowRef.Visible = true
		TweenService:Create(windowRef, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
	end
end

local function queueMajorPopup(data: { [string]: any })
	table.insert(popupQueue, data)
	if not isShowing() then
		showNextPopup()
	end
end

local function dismissPopup()
	if windowRef then
		TweenService:Create(windowRef, TweenInfo.new(0.15), { Position = UDim2.new(0.5, 0, 0.55, 0) }):Play()
	end
	task.delay(0.15, showNextPopup)
end

local function MajorPopup()
	local overlay = create("Frame") {
		Name = "MajorPopupOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 100,
		Visible = false,
	}
	overlayRef = overlay

	local window = create("Frame") {
		Name = "MajorPopupWindow",
		Size = UDim2.new(0, 420, 0, 320),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		ZIndex = 101,
		Visible = false,
		Parent = overlay,

		create("UICorner") { CornerRadius = UDim.new(0, 14) },
		create("UIStroke") { Color = theme.StrokePurple, Thickness = 1 },
		create("UIPadding") {
			PaddingTop = UDim.new(0, 24), PaddingBottom = UDim.new(0, 24),
			PaddingLeft = UDim.new(0, 28), PaddingRight = UDim.new(0, 28),
		},
		create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center },

		create("TextLabel") {
			Name = "Title",
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundTransparency = 1,
			TextColor3 = theme.Gold,
			TextSize = 22,
			Font = Enum.Font.GothamBlack,
			Text = titleText,
			TextWrapped = true,
			RichText = true,
			LayoutOrder = 1,
			ZIndex = 102,
		},
		create("TextLabel") {
			Name = "Body",
			Size = UDim2.new(1, 0, 0, 60),
			BackgroundTransparency = 1,
			TextColor3 = theme.Text,
			TextSize = 16,
			Font = Enum.Font.GothamMedium,
			Text = bodyText,
			TextWrapped = true,
			RichText = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
			ZIndex = 102,
		},
		create("TextLabel") {
			Name = "Highlight",
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			TextColor3 = toneColor,
			TextSize = 18,
			Font = Enum.Font.GothamBold,
			Text = highlightText,
			TextWrapped = true,
			RichText = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 3,
			ZIndex = 102,
		},
		create("TextLabel") {
			Name = "Footer",
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			TextColor3 = theme.SubText,
			TextSize = 13,
			Font = Enum.Font.GothamMedium,
			Text = footerText,
			TextWrapped = true,
			RichText = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 4,
			ZIndex = 102,
		},
		create("TextButton") {
			Name = "ContinueButton",
			Size = UDim2.new(0.7, 0, 0, 40),
			BackgroundColor3 = toneColor,
			TextColor3 = theme.Text,
			TextSize = 16,
			Font = Enum.Font.GothamBlack,
			Text = "CONTINUE",
			AutoButtonColor = false,
			LayoutOrder = 5,
			ZIndex = 102,
			create("UICorner") { CornerRadius = UDim.new(0, 8) },
			[vide.action(function(btn)
				btn.MouseButton1Click:Connect(dismissPopup)
			end)] = true,
		},
	}
	windowRef = window

	local smp = remotes.get("ShowMajorPopup")
	if smp then
		smp.OnClientEvent:Connect(function(data)
			if typeof(data) == "table" then
				queueMajorPopup(data)
			end
		end)
	end

	return overlay
end

return MajorPopup
