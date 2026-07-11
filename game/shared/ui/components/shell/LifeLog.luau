local vide = require("@packages/vide")
local container = require("@ui-components/core/container")
local theme = require("@ui/theme")
local playerState = require("@ui-state/playerState")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _pcL = BitKaisenLocale.getClientLocale()
local function _pc(key, fallback) return BitKaisenLocale.tOrFallback(_pcL, "ui." .. key, nil, fallback) end

local create = vide.create
local derive = vide.derive
local effect = vide.effect

local DIMLO = Color3.fromRGB(60, 58, 78)

local function LifeLog()
	local logContent = derive(function()
		local _ = playerState.logVersion()
		local lines = playerState.lifeLog()
		if #lines == 0 then
			return "Loading into the Jujutsu world..."
		end
		return table.concat(lines, "\n")
	end)

	local logCount = derive(function()
		local _ = playerState.logVersion()
		return #playerState.lifeLog()
	end)

	local scrollRef: ScrollingFrame = nil :: any

	effect(function()
		playerState.logVersion()
		task.delay(0, function()
			if scrollRef then
				scrollRef.CanvasPosition = Vector2.new(0, math.huge)
			end
		end)
	end)

	return container {
		name = "LogContainer",
		ws = 0.61, hs = 0.76,
		xs = 0.025, ys = 0.07,
		color = Color3.fromRGB(10, 9, 15),
		corner = 10,
		clips = true,
		create("UIStroke") { Color = Color3.fromRGB(55, 50, 75), Thickness = 1 },
		create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder },

		create("Frame") {
			Name = "SysLogHeader",
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = Color3.fromRGB(14, 12, 20),
			BorderSizePixel = 0,
			LayoutOrder = 1,
			create("UIStroke") { Color = Color3.fromRGB(55, 50, 75), ApplyStrokeMode = Enum.ApplyStrokeMode.Border },
			create("TextLabel") {
				Position = UDim2.new(0, 14, 0, 0),
				Size = UDim2.new(0.5, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = _pc("system_log", "SYSTEM LOG"),
				TextColor3 = Color3.fromRGB(180, 80, 80),
				TextSize = 11,
				Font = Enum.Font.GothamBlack,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
			},
			create("TextLabel") {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.new(0, 100, 0, 12),
				BackgroundTransparency = 1,
				Text = function() return "LOG-" .. string.format("%04d", logCount()) end,
				TextColor3 = DIMLO,
				TextSize = 9,
				Font = Enum.Font.Code,
				TextXAlignment = Enum.TextXAlignment.Right,
			},
		},

		create("ScrollingFrame") {
			Name = "LifeLog",
			Size = UDim2.new(1, 0, 1, -26),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 5,
			ScrollBarImageColor3 = Color3.fromRGB(100, 40, 40),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
			LayoutOrder = 2,

			create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder },
			create("UIPadding") {
				PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 16),
				PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 22),
			},

			create("TextLabel") {
				Name = "LogText",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Text = logContent,
				TextColor3 = theme.Text,
				TextSize = 15,
				Font = Enum.Font.Code,
				TextWrapped = true,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextXAlignment = Enum.TextXAlignment.Left,
				RichText = true,
			},

			[vide.action(function(sf: ScrollingFrame)
				scrollRef = sf
				sf:GetPropertyChangedSignal("CanvasSize"):Connect(function()
					sf.CanvasPosition = Vector2.new(0, math.huge)
				end)
			end)] = true,
		},
	}
end

return LifeLog
