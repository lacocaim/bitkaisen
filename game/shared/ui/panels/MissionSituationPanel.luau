local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")

local create = vide.create
local source = vide.source

local guiRef: ScreenGui? = nil

local function showSituation(playerGui: Instance, data: { [string]: any })
	if guiRef and guiRef.Parent then guiRef:Destroy() end

	local gui = create("ScreenGui") {
		Name = "BitKaisenMissionSituationGui",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 450,
		Parent = playerGui,
	}
	guiRef = gui

	local overlay = create("Frame") {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.4,
		ZIndex = 450,
		Parent = gui,
	}

	local window = create("Frame") {
		Size = UDim2.new(0, 460, 0, 400),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		ZIndex = 451,
		Parent = overlay,

		create("UICorner") { CornerRadius = UDim.new(0, 14) },
		create("UIStroke") { Color = theme.StrokePurple },
		create("UIPadding") {
			PaddingTop = UDim.new(0, 20), PaddingBottom = UDim.new(0, 20),
			PaddingLeft = UDim.new(0, 24), PaddingRight = UDim.new(0, 24),
		},
		create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center },

		create("TextLabel") {
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundTransparency = 1,
			TextColor3 = theme.Gold,
			TextSize = 20,
			Font = Enum.Font.GothamBlack,
			Text = tostring(data.Title or "MISSION SITUATION"),
			TextWrapped = true,
			LayoutOrder = 1,
			ZIndex = 452,
		},

		create("TextLabel") {
			Size = UDim2.new(1, 0, 0, 80),
			BackgroundTransparency = 1,
			TextColor3 = theme.Text,
			TextSize = 15,
			Font = Enum.Font.GothamMedium,
			Text = tostring(data.Body or data.Description or ""),
			TextWrapped = true,
			RichText = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
			ZIndex = 452,
		},
	}

	local choices = data.Choices or data.Options or {}
	for i, choice in choices do
		create("TextButton") {
			Size = UDim2.new(0.85, 0, 0, 38),
			BackgroundColor3 = theme.Button,
			TextColor3 = theme.Text,
			TextSize = 14,
			Font = Enum.Font.GothamBold,
			Text = tostring(choice.Label or choice.Text or "Choice " .. tostring(i)),
			AutoButtonColor = false,
			LayoutOrder = 10 + i,
			ZIndex = 452,
			Parent = window,
			create("UICorner") { CornerRadius = UDim.new(0, 8) },
			[vide.action(function(btn)
				btn.MouseButton1Click:Connect(function()
					local mc = remotes.get("MissionChoice")
					if mc then mc:FireServer(choice.Id or i) end
					if guiRef then guiRef:Destroy() guiRef = nil end
				end)
			end)] = true,
		}
	end
end

local function init(playerGui: Instance)
	local sms = remotes.get("ShowMissionSituation")
	if sms then
		sms.OnClientEvent:Connect(function(data)
			if typeof(data) == "table" then
				showSituation(playerGui, data)
			end
		end)
	end
end

return { init = init }
