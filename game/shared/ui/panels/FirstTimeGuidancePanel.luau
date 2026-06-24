local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local playerState = require("@ui-state/playerState")

local create = vide.create

local guiRef: ScreenGui? = nil

local function showGuidance(playerGui: Instance)
	if guiRef and guiRef.Parent then return end

	local gui = create("ScreenGui") {
		Name = "BitKaisenFirstTimeGui",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 600,
		Parent = playerGui,
	}
	guiRef = gui

	local overlay = create("Frame") {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		ZIndex = 600,
		Parent = gui,
	}

	local window = create("Frame") {
		Size = UDim2.new(0, 440, 0, 340),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		ZIndex = 601,
		Parent = overlay,
		create("UICorner") { CornerRadius = UDim.new(0, 14) },
		create("UIStroke") { Color = theme.StrokePurple },
		create("UIPadding") {
			PaddingTop = UDim.new(0, 24), PaddingBottom = UDim.new(0, 24),
			PaddingLeft = UDim.new(0, 28), PaddingRight = UDim.new(0, 28),
		},
		create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 14), HorizontalAlignment = Enum.HorizontalAlignment.Center },

		create("TextLabel") {
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundTransparency = 1,
			TextColor3 = theme.Gold,
			TextSize = 22,
			Font = Enum.Font.GothamBlack,
			Text = "WELCOME TO BIT KAISEN",
			LayoutOrder = 1,
			ZIndex = 602,
		},
		create("TextLabel") {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			TextColor3 = theme.Text,
			TextSize = 14,
			Font = Enum.Font.GothamMedium,
			Text = "Live your life as a sorcerer in the Jujutsu Kaisen universe.\n\nPress <b>+ AGE</b> to advance time.\nUse the <b>navigation buttons</b> to explore menus.\nComplete <b>missions</b> and <b>activities</b> to grow stronger.",
			TextWrapped = true,
			RichText = true,
			LayoutOrder = 2,
			ZIndex = 602,
		},
		create("TextButton") {
			Size = UDim2.new(0.6, 0, 0, 40),
			BackgroundColor3 = theme.Purple,
			TextColor3 = theme.Text,
			TextSize = 16,
			Font = Enum.Font.GothamBlack,
			Text = "GOT IT",
			AutoButtonColor = false,
			LayoutOrder = 3,
			ZIndex = 602,
			create("UICorner") { CornerRadius = UDim.new(0, 8) },
			[vide.action(function(btn)
				btn.MouseButton1Click:Connect(function()
					local mt = remotes.get("MarkTutorialSeen")
					if mt then mt:FireServer() end
					if guiRef then guiRef:Destroy() guiRef = nil end
				end)
			end)] = true,
		},
	}
end

local function init(playerGui: Instance)
	local ule = remotes.updateLifeEvent()
	if ule then
		ule.OnClientEvent:Connect(function(stats)
			if typeof(stats) == "table" and stats.TutorialSeen == false and stats.Age == 0 then
				showGuidance(playerGui)
			end
		end)
	end
end

return { init = init }
