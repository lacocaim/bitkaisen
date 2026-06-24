local TweenService = game:GetService("TweenService")
local vide = require("@packages/vide")
local theme = require("@ui/theme")
local uiState = require("@ui-state/uiState")
local device = require("@ui-state/device")

local create = vide.create
local derive = vide.derive
local effect = vide.effect
local source = vide.source

local panelContentSlots = {} :: { [string]: (parent: Frame) -> () }
local registeredPanels = {} :: { [string]: Frame }

local overlayRef: Frame? = nil
local contentHost: Frame? = nil

local function registerPanelBuilder(route: string, builder: (parent: Frame) -> ())
	panelContentSlots[route] = builder
end

local function clearContent()
	if contentHost then
		for _, child in contentHost:GetChildren() do
			if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
				child:Destroy()
			end
		end
	end
end

local function showOverlay(route: string)
	if not overlayRef or not contentHost then return end

	clearContent()

	local builder = panelContentSlots[route]
	if builder then
		builder(contentHost)
	end

	overlayRef.Visible = true
	TweenService:Create(overlayRef, TweenInfo.new(0.2), { BackgroundTransparency = 0.5 }):Play()

	if contentHost then
		contentHost.Visible = true
		contentHost.Position = UDim2.new(0.5, 0, 0.55, 0)
		TweenService:Create(contentHost, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0.5, 0),
		}):Play()
	end
end

local function hideOverlay()
	if not overlayRef then return end

	TweenService:Create(overlayRef, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
	if contentHost then
		TweenService:Create(contentHost, TweenInfo.new(0.15), { Position = UDim2.new(0.5, 0, 0.55, 0) }):Play()
	end
	task.delay(0.15, function()
		if overlayRef then overlayRef.Visible = false end
		if contentHost then contentHost.Visible = false end
		clearContent()
	end)
end

local function OverlayPanel()
	local overlay = create("Frame") {
		Name = "OverlayPanel",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 50,
		Visible = false,

		[vide.action(function(inst)
			inst.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					uiState.closeRoute()
				end
			end)
		end)] = true,
	}
	overlayRef = overlay

	local function getContentWindowSize()
		if device.isMobileLayout() then
			local portrait = device.isPortrait()
			return UDim2.new(
				portrait and 0.96 or 0.92, 0,
				portrait and 0.88 or 0.86, 0
			)
		end
		return UDim2.new(0.56, 0, 0.76, 0)
	end

	local host = create("Frame") {
		Name = "ContentWindow",
		Size = function()
			local _ = device.version()
			return getContentWindowSize()
		end,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		ZIndex = 51,
		ClipsDescendants = true,
		Visible = false,
		Parent = overlay,

		create("UICorner") { CornerRadius = UDim.new(0, 14) },
		create("UIStroke") { Color = theme.StrokeSoft },

		create("TextButton") {
			Name = "CloseButton",
			Size = UDim2.new(0, 36, 0, 36),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -8, 0, 8),
			BackgroundColor3 = theme.Panel2,
			TextColor3 = theme.Text,
			TextSize = 20,
			Font = Enum.Font.GothamBlack,
			Text = "X",
			AutoButtonColor = false,
			ZIndex = 55,
			create("UICorner") { CornerRadius = UDim.new(0, 999) },
			[vide.action(function(btn)
				btn.MouseButton1Click:Connect(function()
					uiState.closeRoute()
				end)
			end)] = true,
		},
	}
	contentHost = host

	effect(function()
		local route = uiState.activeRoute()
		if route == "" then
			hideOverlay()
		else
			showOverlay(route)
		end
	end)

	return overlay
end

return {
	create = OverlayPanel,
	registerPanelBuilder = registerPanelBuilder,
}
