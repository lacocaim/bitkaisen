local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local playerState = require("@ui-state/playerState")
local uiState = require("@ui-state/uiState")
local factory = require("@ui-panels/panelFactory")

local create = vide.create
local source = vide.source
local effect = vide.effect

local deathGuiRef: ScreenGui? = nil

local function createDeathScreen(playerGui: Instance)
	if deathGuiRef and deathGuiRef.Parent then return end

	local gui = create("ScreenGui") {
		Name = "BitKaisenDeathGui",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 500,
		Parent = playerGui,
	}
	deathGuiRef = gui

	local overlay = create("Frame") {
		Name = "DeathOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.3,
		ZIndex = 500,
		Parent = gui,
	}

	local window = create("Frame") {
		Name = "DeathWindow",
		Size = UDim2.new(0, 420, 0, 380),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = theme.Window,
		BorderSizePixel = 0,
		ZIndex = 501,
		Parent = overlay,

		create("UICorner") { CornerRadius = UDim.new(0, 14) },
		create("UIStroke") { Color = theme.Red },
		create("UIPadding") {
			PaddingTop = UDim.new(0, 24), PaddingBottom = UDim.new(0, 24),
			PaddingLeft = UDim.new(0, 28), PaddingRight = UDim.new(0, 28),
		},
		create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 14), HorizontalAlignment = Enum.HorizontalAlignment.Center },

		create("TextLabel") {
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			TextColor3 = theme.Bad,
			TextSize = 24,
			Font = Enum.Font.GothamBlack,
			Text = "YOU HAVE DIED",
			LayoutOrder = 1,
			ZIndex = 502,
		},

		create("TextLabel") {
			Size = UDim2.new(1, 0, 0, 60),
			BackgroundTransparency = 1,
			TextColor3 = theme.Text,
			TextSize = 14,
			Font = Enum.Font.GothamMedium,
			Text = "Your journey has come to an end. Choose how to continue.",
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
			ZIndex = 502,
		},

		create("TextButton") {
			Size = UDim2.new(0.8, 0, 0, 40),
			BackgroundColor3 = theme.Red,
			TextColor3 = theme.Text,
			TextSize = 16,
			Font = Enum.Font.GothamBlack,
			Text = "NEW LIFE",
			AutoButtonColor = false,
			LayoutOrder = 3,
			ZIndex = 502,
			create("UICorner") { CornerRadius = UDim.new(0, 8) },
			[vide.action(function(btn)
				btn.MouseButton1Click:Connect(function()
					local ule = remotes.updateLifeEvent()
					if ule then ule:FireServer("NewLife") end
					if deathGuiRef then deathGuiRef:Destroy() deathGuiRef = nil end
				end)
			end)] = true,
		},

		create("TextButton") {
			Size = UDim2.new(0.8, 0, 0, 40),
			BackgroundColor3 = Color3.fromRGB(95, 55, 150),
			TextColor3 = theme.Text,
			TextSize = 16,
			Font = Enum.Font.GothamBlack,
			Text = "CHOOSE SUCCESSOR",
			AutoButtonColor = false,
			LayoutOrder = 4,
			ZIndex = 502,
			create("UICorner") { CornerRadius = UDim.new(0, 8) },
			[vide.action(function(btn)
				btn.MouseButton1Click:Connect(function()
					local ule = remotes.updateLifeEvent()
					if ule then ule:FireServer("ChooseSuccessor") end
					if deathGuiRef then deathGuiRef:Destroy() deathGuiRef = nil end
				end)
			end)] = true,
		},
	}
end

local function init(playerGui: Instance)
	effect(function()
		local alive = playerState.alive()
		if not alive then
			createDeathScreen(playerGui)
		else
			if deathGuiRef then deathGuiRef:Destroy() deathGuiRef = nil end
		end
	end)
end

return { init = init }
