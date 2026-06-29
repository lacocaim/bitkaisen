local TweenService = game:GetService("TweenService")
local vide = require("@packages/vide")
local theme = require("@ui/theme")
local helpers = require("@ui/helpers")
local playerState = require("@ui-state/playerState")
local uiState = require("@ui-state/uiState")
local navRegistry = require("@ui-state/navRegistry")
local remotes = require("@ui-state/remotes")
local mc = require("@ui/mobile/mobileComponents")
local bindTap = mc.bindTap

local create = vide.create
local derive = vide.derive
local indexes = vide.indexes

local TWEEN_QUICK = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function StatBar(title: string, color: Color3, getValue: () -> number)
	local fraction = derive(function()
		return math.clamp((getValue() or 0) / 100, 0, 1)
	end)

	local track = create("Frame") {
		Name = "StatBar_" .. title,
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,

		create("TextLabel") {
			Name = "Title",
			Size = UDim2.new(0.35, 0, 1, 0),
			BackgroundTransparency = 1,
			TextColor3 = color,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
			Text = title,
			TextXAlignment = Enum.TextXAlignment.Left,
		},

		create("Frame") {
			Name = "Track",
			Size = UDim2.new(0.63, 0, 0, 10),
			Position = UDim2.new(0.35, 0, 0.25, 0),
			BackgroundColor3 = Color3.fromRGB(25, 25, 30),
			BorderSizePixel = 0,
			create("UICorner") { CornerRadius = UDim.new(0, 999) },

			create("Frame") {
				Name = "Fill",
				Size = function()
					return UDim2.new(fraction(), 0, 1, 0)
				end,
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				create("UICorner") { CornerRadius = UDim.new(0, 999) },
			},
		},
	}
	return track
end

local function MobileProfileHeader()
	local stats = playerState.stats

	local nameText = derive(function()
		local s = stats()
		return tostring(s and s.Name or "Loading...")
	end)

	local ageText = derive(function()
		local s = stats()
		if not s then return "Age: 0" end
		return "Age: " .. helpers.getAgeDisplay(s) .. " | Year: " .. tostring(helpers.getCurrentYear(s)) .. " | Era: " .. helpers.getCurrentEraDisplay(s)
	end)

	local gradeText = derive(function()
		local s = stats()
		if not s then return "Rank: Unknown" end
		if helpers.isProfileCurseLife(s) then
			return (s.CurseClassified == true and "Classification: " or "Estimated: ") .. tostring(s.CurseGrade or "Unregistered Grade 3 Cursed Spirit")
		end
		return "Rank: " .. tostring(s.Grade or "Unknown")
	end)

	local worldRepText = derive(function()
		local s = stats()
		if not s then return "" end
		local lifePath = tostring(s.LifePath or helpers.getRoutePathText(s) or "Undecided")
		local fame = math.clamp(tonumber(s.Fame) or 0, 0, 100)
		local fear = math.clamp(tonumber(s.Fear) or 0, 0, 100)
		return "World: " .. lifePath .. " | Fame " .. tostring(fame) .. " | Fear " .. tostring(fear)
	end)

	local clanText = derive(function() return helpers.getLineageText(stats()) end)
	local techText = derive(function()
		local s = stats()
		return "Technique: " .. tostring(s and s.CursedTechnique or "None")
	end)
	local traitText = derive(function()
		local s = stats()
		return "Traits: " .. tostring(s and s.TraitSummary or "None")
	end)
	local ceText = derive(function()
		local s = stats()
		return "CE: " .. tostring(s and s.CursedEnergy or 0)
	end)
	local moneyText = derive(function()
		local s = stats()
		return "Money: $" .. helpers.formatMoneyAmount(s and s.Money or 0)
	end)
	local repText = derive(function()
		local s = stats()
		return "Rep: " .. tostring(s and s.Reputation or 0)
	end)
	local repColor = derive(function()
		local s = stats()
		return (tonumber(s and s.Reputation) or 0) < 0 and theme.Red or theme.Gold
	end)

	local schoolText = derive(function()
		return "School: " .. helpers.getSchoolDisplay(stats())
	end)

	local pathText = derive(function()
		return "Path: " .. helpers.getRoutePathText(stats())
	end)
	local pathColor = derive(function() return helpers.getRouteColor(stats()) end)

	local alignText = derive(function()
		local s = stats()
		if helpers.isProfileCurseLife(s) then
			return "Threat: " .. tostring(s and (s.CurseThreatClass or s.SocietyStatus) or "Local")
		end
		return "Alignment: " .. helpers.getDisplayedAlignment(s)
	end)
	local alignColor = derive(function()
		local s = stats()
		if helpers.isProfileCurseLife(s) then return theme.Orange end
		return helpers.getAlignmentColor(helpers.getDisplayedAlignment(s))
	end)

	return create("Frame") {
		Name = "ProfileHeader",
		Size = UDim2.new(0.94, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		LayoutOrder = 1,

		create("UICorner") { CornerRadius = UDim.new(0, 10) },
		create("UIStroke") { Color = theme.StrokeSoft },
		create("UIGradient") {
			Color = ColorSequence.new(theme.Panel, theme.Bg2),
			Rotation = 90,
		},
		create("UIPadding") {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
		},
		create("UIListLayout") {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		},

		create("TextLabel") {
			Name = "Name",
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			Text = nameText,
			TextColor3 = theme.Text,
			TextSize = 18,
			Font = Enum.Font.GothamBlack,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 1,
		},
		create("TextLabel") {
			Name = "AgeEra",
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			Text = ageText,
			TextColor3 = theme.SubText,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
		},
		create("TextLabel") {
			Name = "Grade",
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			Text = gradeText,
			TextColor3 = theme.SubText,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 3,
		},
		create("TextLabel") {
			Name = "WorldRep",
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			Text = worldRepText,
			TextColor3 = theme.Gold,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 4,
		},
		create("TextLabel") {
			Name = "Clan",
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			Text = clanText,
			TextColor3 = theme.Text,
			TextSize = 11,
			Font = Enum.Font.GothamMedium,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 5,
		},
		create("TextButton") {
			Name = "Technique",
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			Text = techText,
			TextColor3 = theme.Purple,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			AutoButtonColor = false,
			LayoutOrder = 6,

			[vide.action(function(btn: TextButton)
				bindTap(btn, function()
					uiState.navigate("technique_mastery")
				end)
			end)] = true,
		},
		create("TextLabel") {
			Name = "Traits",
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			Text = traitText,
			TextColor3 = theme.Gold,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 7,
		},
		create("Frame") {
			Name = "StatsRow",
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 8,

			create("UIListLayout") {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
			},

			create("TextLabel") {
				Size = UDim2.new(0, 0, 0, 14),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Text = ceText,
				TextColor3 = theme.Purple,
				TextSize = 11,
				Font = Enum.Font.GothamBold,
			},
			create("TextLabel") {
				Size = UDim2.new(0, 0, 0, 14),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Text = moneyText,
				TextColor3 = theme.Green,
				TextSize = 11,
				Font = Enum.Font.GothamBold,
			},
			create("TextLabel") {
				Size = UDim2.new(0, 0, 0, 14),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Text = repText,
				TextColor3 = repColor,
				TextSize = 11,
				Font = Enum.Font.GothamBold,
			},
		},
		create("TextLabel") {
			Name = "School",
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			Text = schoolText,
			TextColor3 = theme.Blue,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 9,
		},
		create("TextLabel") {
			Name = "Path",
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			Text = pathText,
			TextColor3 = pathColor,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 10,
		},
		create("TextLabel") {
			Name = "Alignment",
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			Text = alignText,
			TextColor3 = alignColor,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 11,
		},

		create("Frame") {
			Name = "Divider",
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = theme.StrokeSoft,
			BorderSizePixel = 0,
			LayoutOrder = 12,
		},

		StatBar("Health", theme.Bad, function()
			local s = playerState.stats()
			return s and s.Health or 100
		end),
		StatBar("Happiness", theme.Green, function()
			local s = playerState.stats()
			return s and s.Happiness or 100
		end),
		StatBar("Smarts", theme.Gold, function()
			local s = playerState.stats()
			return s and s.Smarts or 50
		end),
		StatBar("Looks", Color3.fromRGB(96, 170, 255), function()
			local s = playerState.stats()
			return s and s.Looks or 50
		end),
		StatBar("Strength", Color3.fromRGB(236, 116, 76), function()
			local s = playerState.stats()
			return s and s.Strength or 0
		end),
	}
end

local function MobileLifeLog()
	local logContent = derive(function()
		local _ = playerState.logVersion()
		local lines = playerState.lifeLog()
		if #lines == 0 then
			return "Loading into the Jujutsu world..."
		end
		return table.concat(lines, "\n")
	end)

	local scrollRef: ScrollingFrame = nil :: any

	return create("Frame") {
		Name = "LogContainer",
		Size = UDim2.new(0.94, 0, 0.30, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = 2,

		create("UICorner") { CornerRadius = UDim.new(0, 10) },
		create("UIStroke") { Color = theme.StrokeSoft },
		create("UIGradient") {
			Color = ColorSequence.new(theme.Panel, theme.Bg2),
			Rotation = 90,
		},

		create("ScrollingFrame") {
			Name = "LifeLog",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = theme.RedSoft,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingEnabled = true,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ElasticBehavior = Enum.ElasticBehavior.Always,
			ZIndex = 2,

			create("UIPadding") {
				PaddingTop = UDim.new(0, 12),
				PaddingBottom = UDim.new(0, 12),
				PaddingLeft = UDim.new(0, 14),
				PaddingRight = UDim.new(0, 14),
			},

			create("TextLabel") {
				Name = "LogText",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Text = logContent,
				TextColor3 = theme.Text,
				TextSize = 14,
				Font = Enum.Font.GothamMedium,
				TextWrapped = true,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextXAlignment = Enum.TextXAlignment.Left,
				RichText = true,
			},

			[vide.action(function(sf: ScrollingFrame)
				scrollRef = sf
				-- scroll to bottom on new content
				local function scrollToBottom()
					if sf and sf.CanvasSize.Y.Offset > sf.AbsoluteSize.Y then
						sf.CanvasPosition = Vector2.new(0, sf.AbsoluteContentSize.Y)
					end
				end
				sf:GetPropertyChangedSignal("CanvasSize"):Connect(scrollToBottom)
			end)] = true,
		},
	}
end

local function MobileAgeButton()
	return create("TextButton") {
		Name = "AgeUpButton",
		Size = UDim2.new(0.94, 0, 0, 48),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundColor3 = theme.RedDark,
		BorderSizePixel = 0,
		Text = "+ AGE",
		TextColor3 = theme.Text,
		TextSize = 20,
		Font = Enum.Font.GothamBlack,
		AutoButtonColor = false,
		ZIndex = 6,
		LayoutOrder = 3,

		create("UICorner") { CornerRadius = UDim.new(0, 10) },
		create("UIStroke") { Color = theme.Red },

		[vide.action(function(btn: TextButton)
			bindTap(btn, function()
				if _G.BitKaisenPlaySFX then _G.BitKaisenPlaySFX("Tick") end
				local ule = remotes.updateLifeEvent()
				if ule then
					ule:FireServer("AgeUp")
				end
			end)
		end)] = true,
	}
end

local function MobileNavPanel()
	return create("ScrollingFrame") {
		Name = "NavPanel",
		Size = UDim2.new(0.94, 0, 0, 48),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = theme.StrokeSoft,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 1,
		LayoutOrder = 4,

		create("UICorner") { CornerRadius = UDim.new(0, 10) },
		create("UIStroke") { Color = theme.StrokeSoft },
		create("UIFlexItem") { FlexMode = Enum.UIFlexMode.Fill },
		create("UIListLayout") {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		},
		create("UIPadding") {
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		},

		indexes(function()
			local _ = navRegistry.version()
			return navRegistry.getEntries()
		end, function(value)
			local entry = value()
			local isActive = derive(function()
				return uiState.activeRoute() == entry.id
			end)

			local btn = create("TextButton") {
				Name = entry.id,
				Size = UDim2.new(1, 0, 0, 42),
				BackgroundColor3 = function()
					return isActive() and theme.Panel3 or theme.Panel2
				end,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 5,

				create("UICorner") { CornerRadius = UDim.new(0, 8) },
				create("UIStroke") { Color = theme.Stroke },

				create("Frame") {
					Name = "Accent",
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 8, 0.5, 0),
					Size = UDim2.new(0, 4, 0, 20),
					BackgroundColor3 = entry.color or theme.Red,
					BorderSizePixel = 0,
					create("UICorner") { CornerRadius = UDim.new(1, 0) },
				},

				create("TextLabel") {
					Name = "Label",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = entry.label,
					TextColor3 = function()
						return isActive() and theme.Text or theme.SubText
					end,
					TextSize = 13,
					Font = Enum.Font.GothamBlack,
					TextXAlignment = Enum.TextXAlignment.Center,
				},

			[vide.action(function(b: TextButton)
				bindTap(b, function()
					if _G.BitKaisenPlaySFX then _G.BitKaisenPlaySFX("Click") end
					uiState.navigate(entry.id)
				end)
			end)] = true,
			}

			return btn
		end),
	}
end

local function create_(playerGui: PlayerGui)
	local gui = create("ScreenGui") {
		Name = "MobileGui",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		DisplayOrder = 15,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}

	create("Frame") {
		Name = "MainPanel",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Bg,
		BorderSizePixel = 0,
		Parent = gui,

		create("UIListLayout") {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		},
		create("UIPadding") {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 6),
		},

		MobileProfileHeader(),
		MobileLifeLog(),
		MobileAgeButton(),
		MobileNavPanel(),
	}

	-- vide.action callbacks don't fire for Vide-created buttons in this tree,
	-- so register shell buttons in the tap router imperatively.
	do
		local mainPanel = gui:FindFirstChild("MainPanel")
		if mainPanel then
			local ageBtn = mainPanel:FindFirstChild("AgeUpButton")
			if ageBtn and ageBtn:IsA("TextButton") then
				bindTap(ageBtn, function()
					if _G.BitKaisenPlaySFX then _G.BitKaisenPlaySFX("Tick") end
					local ule = remotes.updateLifeEvent()
					if ule then
						ule:FireServer("AgeUp")
					end
				end)
			end

			local navPanel = mainPanel:FindFirstChild("NavPanel")
			if navPanel then
				local function registerNavBtn(child)
					if not child:IsA("TextButton") then return end
					bindTap(child, function()
						uiState.navigate(child.Name)
					end)
				end
				for _, child in ipairs(navPanel:GetChildren()) do
					registerNavBtn(child)
				end
				navPanel.ChildAdded:Connect(registerNavBtn)
			end
		end
	end

	return gui
end

return { create = create_ }
