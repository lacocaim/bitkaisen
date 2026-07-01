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
local source = vide.source


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

local DIM    = Color3.fromRGB(100, 98, 120)
local DIMLO  = Color3.fromRGB(60, 58, 78)
local LABEL  = Color3.fromRGB(130, 128, 158)

local function DossierBar(label: string, color: Color3, getValue: () -> number)
	local frac = derive(function() return math.clamp((getValue() or 0) / 100, 0, 1) end)
	local val  = derive(function() return tostring(math.floor(getValue() or 0)) .. " / 100" end)
	return create("Frame") {
		Name = "DB_" .. label,
		Size = UDim2.new(1, 0, 0, 17),
		BackgroundTransparency = 1,
		create("Frame") {
			Name = "Dot",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.new(0, 7, 0, 7),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			create("UICorner") { CornerRadius = UDim.new(1, 0) },
		},
		create("TextLabel") {
			Position = UDim2.new(0, 12, 0, 0),
			Size = UDim2.new(0, 72, 1, 0),
			BackgroundTransparency = 1,
			Text = string.upper(label),
			TextColor3 = DIM,
			TextSize = 8,
			Font = Enum.Font.GothamBlack,
			TextXAlignment = Enum.TextXAlignment.Left,
		},
		create("Frame") {
			Name = "Track",
			Position = UDim2.new(0, 88, 0.5, -3),
			Size = UDim2.new(1, -142, 0, 5),
			BackgroundColor3 = Color3.fromRGB(22, 20, 32),
			BorderSizePixel = 0,
			create("UICorner") { CornerRadius = UDim.new(0, 999) },
			create("Frame") {
				Size = function() return UDim2.new(frac(), 0, 1, 0) end,
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				create("UICorner") { CornerRadius = UDim.new(0, 999) },
			},
		},
		create("TextLabel") {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.new(0, 50, 1, 0),
			BackgroundTransparency = 1,
			Text = val,
			TextColor3 = DIMLO,
			TextSize = 8,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Right,
		},
	}
end

local function DInfoRow(label: string, val: any, color: Color3?, valueName: string?)
	return create("Frame") {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		create("UISizeConstraint") { MinSize = Vector2.new(0, 17) },
		create("TextLabel") {
			Size = UDim2.new(0, 60, 0, 17),
			BackgroundTransparency = 1,
			Text = "• " .. string.upper(label),
			TextColor3 = LABEL,
			TextSize = 7,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
		},
		create("TextLabel") {
			Name = valueName,
			Position = UDim2.new(0, 62, 0, 0),
			Size = UDim2.new(1, -62, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = val,
			TextColor3 = color or theme.Text,
			TextSize = 9,
			Font = Enum.Font.GothamBlack,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextWrapped = true,
		},
	}
end

local function MobileProfileHeader()
	local stats = playerState.stats

	local nameText  = derive(function() local s = stats() return tostring(s and s.Name or "...") end)
	local ageVal    = derive(function() local s = stats() return s and helpers.getAgeDisplay(s) or "0" end)
	local monthVal  = derive(function() local s = stats() return s and tostring(s.CurrentMonth or 1) or "1" end)
	local yearVal   = derive(function() local s = stats() return s and tostring(helpers.getCurrentYear(s)) or "—" end)
	local eraVal    = derive(function() local s = stats() return s and helpers.getCurrentEraDisplay(s) or "—" end)
	local rankVal   = derive(function()
		local s = stats()
		if not s then return "—" end
		if helpers.isProfileCurseLife(s) then return tostring(s.CurseGrade or "Unknown") end
		return tostring(s.Grade or "Non-Sorcerer")
	end)
	local worldVal  = derive(function()
		local s = stats()
		if not s then return "—" end
		return tostring(s.LifePath or helpers.getRoutePathText(s) or "Undecided")
	end)
	local fameVal   = derive(function() local s = stats() return tostring(math.clamp(tonumber(s and s.Fame) or 0, 0, 100)) end)
	local fearVal   = derive(function() local s = stats() return tostring(math.clamp(tonumber(s and s.Fear) or 0, 0, 100)) end)
	local lineageVal = derive(function() return helpers.getLineageText(stats()) end)
	local techVal   = derive(function() local s = stats() return tostring(s and s.CursedTechnique or "None") end)
	local traitVal  = derive(function() local s = stats() return tostring(s and s.TraitSummary or "None") end)
	local ceVal     = derive(function() local s = stats() return tostring(s and s.CursedEnergy or 0) end)
	local moneyVal  = derive(function() local s = stats() return "$" .. helpers.formatMoneyAmount(s and s.Money or 0) end)
	local repVal    = derive(function() local s = stats() return tostring(s and s.Reputation or 0) end)
	local repColor  = derive(function() local s = stats() return (tonumber(s and s.Reputation) or 0) < 0 and theme.Red or theme.Gold end)
	local schoolVal = derive(function() return helpers.getSchoolDisplay(stats()) end)
	local pathVal   = derive(function() return helpers.getRoutePathText(stats()) end)
	local pathColor = derive(function() return helpers.getRouteColor(stats()) end)
	local alignVal  = derive(function()
		local s = stats()
		if helpers.isProfileCurseLife(s) then return tostring(s and (s.CurseThreatClass or s.SocietyStatus) or "Local") end
		return helpers.getDisplayedAlignment(s)
	end)
	local alignColor = derive(function()
		local s = stats()
		if helpers.isProfileCurseLife(s) then return theme.Orange end
		return helpers.getAlignmentColor(helpers.getDisplayedAlignment(s))
	end)
	local fileId = derive(function()
		local s = stats()
		local yr = helpers.getCurrentYear(s) or 2000
		local nm = tostring(s and s.Name or "")
		local h = 0
		for i = 1, #nm do h = (h * 31 + string.byte(nm, i)) % 100000 end
		return string.format("BK-%d-%05d", yr, h)
	end)

	return create("Frame") {
		Name = "ProfileHeader",
		Size = UDim2.new(0.97, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 4),
		BackgroundColor3 = Color3.fromRGB(10, 9, 15),
		BorderSizePixel = 0,
		LayoutOrder = 1,
		create("UIStroke") { Color = Color3.fromRGB(55, 50, 75), Thickness = 1 },
		create("UICorner") { CornerRadius = UDim.new(0, 4) },
		create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0) },

		-- Header bar
		create("Frame") {
			Name = "DossierHeader",
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundColor3 = Color3.fromRGB(14, 12, 20),
			BorderSizePixel = 0,
			LayoutOrder = 1,
			create("UIStroke") { Color = Color3.fromRGB(55, 50, 75), ApplyStrokeMode = Enum.ApplyStrokeMode.Border },
			create("TextLabel") {
				Position = UDim2.new(0, 10, 0, 4),
				Size = UDim2.new(0.5, 0, 0, 10),
				BackgroundTransparency = 1,
				Text = "CLASSIFIED  機密指定",
				TextColor3 = Color3.fromRGB(200, 196, 218),
				TextSize = 9,
				Font = Enum.Font.GothamBlack,
				TextXAlignment = Enum.TextXAlignment.Left,
			},
			create("TextLabel") {
				Position = UDim2.new(0, 10, 0, 15),
				Size = UDim2.new(0.5, 0, 0, 8),
				BackgroundTransparency = 1,
				Text = "BITKAISEN SORCERER DOSSIER",
				TextColor3 = DIMLO,
				TextSize = 6,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
			},
			create("TextLabel") {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -10, 0, 4),
				Size = UDim2.new(0, 80, 0, 8),
				BackgroundTransparency = 1,
				Text = "FILE No.",
				TextColor3 = DIMLO,
				TextSize = 6,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Right,
			},
			create("TextLabel") {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -10, 0, 13),
				Size = UDim2.new(0, 110, 0, 10),
				BackgroundTransparency = 1,
				Text = fileId,
				TextColor3 = DIM,
				TextSize = 8,
				Font = Enum.Font.Code,
				TextXAlignment = Enum.TextXAlignment.Right,
			},
		},

		-- Stat bars block
		create("Frame") {
			Name = "Bars",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			create("UIPadding") { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) },
			create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) },
			DossierBar("Health",    theme.Red,                    function() local s = stats() return s and s.Health    or 100 end),
			DossierBar("Happiness", theme.Green,                  function() local s = stats() return s and s.Happiness or 100 end),
			DossierBar("Smarts",    theme.Gold,                   function() local s = stats() return s and s.Smarts    or 50  end),
			DossierBar("Looks",     Color3.fromRGB(96, 170, 255), function() local s = stats() return s and s.Looks     or 50  end),
			DossierBar("Strength",  Color3.fromRGB(236, 116, 76), function() local s = stats() return s and s.Strength  or 0   end),
			DossierBar("Speed",     Color3.fromRGB(96, 220, 200), function() local s = stats() return s and s.Speed     or 0   end),
			DossierBar("Durability",Color3.fromRGB(150, 150, 160),function() local s = stats() return s and s.Durability or 0  end),
		},

		-- Divider
		create("Frame") { Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.fromRGB(55, 50, 75), BorderSizePixel = 0, LayoutOrder = 3 },

		-- BodyTop: SUBJECT + nombre + stamp + age/year/era
		create("Frame") {
			Name = "BodyTop",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 4,
			create("UIPadding") { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) },

			-- Name row: SUBJECT label + name text + stamp circle
			create("Frame") {
				Name = "NameRow",
				Size = UDim2.new(1, 0, 0, 56),
				BackgroundTransparency = 1,

				-- SUBJECT label
				create("TextLabel") {
					Position = UDim2.new(0, 0, 0, 0),
					Size = UDim2.new(1, -50, 0, 10),
					BackgroundTransparency = 1,
					Text = "SUBJECT",
					TextColor3 = DIMLO,
					TextSize = 7,
					Font = Enum.Font.GothamBlack,
					TextXAlignment = Enum.TextXAlignment.Left,
				},

				-- Character name
				create("TextLabel") {
					Name = "CharName",
					Position = UDim2.new(0, 0, 0, 11),
					Size = UDim2.new(1, -50, 0, 26),
					BackgroundTransparency = 1,
					Text = nameText,
					TextColor3 = theme.Text,
					TextSize = 22,
					Font = Enum.Font.GothamBlack,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextWrapped = true,
					ClipsDescendants = false,
				},

				-- Age / Year / Era
				create("TextLabel") {
					Name = "AgeEraInline",
					Position = UDim2.new(0, 0, 0, 42),
					Size = UDim2.new(1, -50, 0, 14),
					BackgroundTransparency = 1,
					RichText = true,
					Text = derive(function()
						return string.format(
							'<font color="#6e6c88" size="7">AGE</font>  <b>%s</b>    <font color="#6e6c88" size="7">YEAR</font>  <b>%s</b>    <font color="#6e6c88" size="7">ERA</font>  <b>%s</b>',
							ageVal(), yearVal(), eraVal()
						)
					end),
					TextColor3 = Color3.fromRGB(210, 208, 230),
					TextSize = 9,
					Font = Enum.Font.GothamBold,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
				},

				-- Stamp circle (top-right)
				create("Frame") {
					Name = "Stamp",
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, 0, 0, 0),
					Size = UDim2.new(0, 44, 0, 44),
					BackgroundColor3 = Color3.fromRGB(6, 4, 10),
					BorderSizePixel = 0,
					ZIndex = 3,
					create("UICorner") { CornerRadius = UDim.new(1, 0) },
					create("UIStroke") { Color = Color3.fromRGB(110, 25, 25), Thickness = 1.5 },
					create("Frame") {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.new(1, -10, 1, -10),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ZIndex = 3,
						create("UICorner") { CornerRadius = UDim.new(1, 0) },
						create("UIStroke") { Color = Color3.fromRGB(80, 18, 18), Thickness = 0.8 },
					},
					create("TextLabel") {
						Position = UDim2.new(0, 0, 0.1, 0),
						Size = UDim2.new(1, 0, 0.42, 0),
						BackgroundTransparency = 1,
						Text = "高等術師",
						TextColor3 = Color3.fromRGB(140, 35, 35),
						TextSize = 9,
						Font = Enum.Font.GothamBold,
						TextXAlignment = Enum.TextXAlignment.Center,
						ZIndex = 3,
					},
					create("TextLabel") {
						Position = UDim2.new(0, 0, 0.5, 0),
						Size = UDim2.new(1, 0, 0.42, 0),
						BackgroundTransparency = 1,
						Text = "認可済",
						TextColor3 = Color3.fromRGB(190, 50, 50),
						TextSize = 11,
						Font = Enum.Font.GothamBlack,
						TextXAlignment = Enum.TextXAlignment.Center,
						ZIndex = 3,
					},
				},
			},
		},

		-- Divider medio — hijo directo de ProfileHeader, mismo ancho que el de arriba
		create("Frame") {
			Size = UDim2.new(1, 0, 0, 2),
			BackgroundColor3 = Color3.fromRGB(55, 50, 75),
			BorderSizePixel = 0,
			LayoutOrder = 5,
		},

		-- BodyBottom: grid de info
		create("Frame") {
			Name = "BodyBottom",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 6,
			create("UIPadding") { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) },

			-- Two-column info grid
			create("Frame") {
				Name = "InfoGrid",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				create("UIListLayout") {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Top,
					Padding = UDim.new(0, 8),
				},

				-- Left column
				create("Frame") {
					Name = "LeftCol",
					Size = UDim2.new(0.5, -4, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = 1,
					create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) },
					DInfoRow("Rank",    rankVal,    theme.Gold),
					DInfoRow("World",   worldVal,   theme.Gold),
					DInfoRow("Fame",    fameVal,    theme.Orange),
					DInfoRow("Fear",    fearVal,    theme.Red),
					DInfoRow("Lineage", lineageVal, theme.Text),
					create("TextButton") {
						Size = UDim2.new(1, 0, 0, 17),
						BackgroundTransparency = 1,
						Text = "",
						AutoButtonColor = false,
						[vide.action(function(btn: TextButton)
							bindTap(btn, function() uiState.navigate("technique_mastery") end)
						end)] = true,
						create("TextLabel") {
							Size = UDim2.new(0, 60, 1, 0),
							BackgroundTransparency = 1,
							Text = "• TECHNIQUE",
							TextColor3 = LABEL,
							TextSize = 7,
							Font = Enum.Font.GothamBold,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextYAlignment = Enum.TextYAlignment.Center,
						},
						create("TextLabel") {
							Position = UDim2.new(0, 62, 0, 0),
							Size = UDim2.new(1, -62, 1, 0),
							BackgroundTransparency = 1,
							Text = techVal,
							TextColor3 = theme.Purple,
							TextSize = 9,
							Font = Enum.Font.GothamBlack,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextYAlignment = Enum.TextYAlignment.Center,
							TextWrapped = true,
						},
					},
					DInfoRow("Traits",  traitVal,   theme.Gold, "Traits"),
				},

				-- Right column
				create("Frame") {
					Name = "RightCol",
					Size = UDim2.new(0.5, -4, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = 2,
					create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) },
					DInfoRow("CE",        ceVal,     theme.Purple),
					DInfoRow("Money",     moneyVal,  theme.Green),
					DInfoRow("Rep",       repVal,    repColor),
					DInfoRow("School",    schoolVal, theme.Blue),
					DInfoRow("Path",      pathVal,   pathColor),
					DInfoRow("Alignment", alignVal,  alignColor),
				},
			},
		},

		-- Footer bar
		create("Frame") {
			Name = "DossierFooter",
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundColor3 = Color3.fromRGB(14, 12, 20),
			BorderSizePixel = 0,
			LayoutOrder = 7,
			create("UIStroke") { Color = Color3.fromRGB(55, 50, 75), ApplyStrokeMode = Enum.ApplyStrokeMode.Border },
			create("TextLabel") {
				Position = UDim2.new(0, 10, 0, 4),
				Size = UDim2.new(0.7, 0, 0, 10),
				BackgroundTransparency = 1,
				Text = "BITKAISEN BUREAU OF JUJUTSU AFFAIRS  呪術局・記録部",
				TextColor3 = DIMLO,
				TextSize = 6,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
			},
			create("TextLabel") {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.new(0, 60, 0, 10),
				BackgroundTransparency = 1,
				Text = "AUTHORIZED",
				TextColor3 = DIMLO,
				TextSize = 6,
				Font = Enum.Font.GothamBlack,
				TextXAlignment = Enum.TextXAlignment.Right,
			},
		},
	}
end

local function MobileLifeLog()
	local logContent = derive(function()
		local _ = playerState.logVersion()
		local lines = playerState.lifeLog()
		if #lines == 0 then return "Loading into the Jujutsu world..." end
		return table.concat(lines, "\n")
	end)

	local logCount = derive(function()
		local _ = playerState.logVersion()
		return #playerState.lifeLog()
	end)

	local scrollRef: ScrollingFrame = nil :: any

	local function scrollToBottom()
		if scrollRef and scrollRef.Parent then
			scrollRef.CanvasPosition = Vector2.new(0, math.huge)
		end
	end

	vide.effect(function()
		local _ = playerState.logVersion()
		task.defer(scrollToBottom)
	end)

	return create("Frame") {
		Name = "LogContainer",
		Size = UDim2.new(0.97, 0, 1, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(10, 9, 15),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = 2,
		create("UIStroke") { Color = Color3.fromRGB(55, 50, 75), Thickness = 1 },
		create("UICorner") { CornerRadius = UDim.new(0, 4) },
		create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder },

		-- Header
		create("Frame") {
			Name = "SysLogHeader",
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundColor3 = Color3.fromRGB(14, 12, 20),
			BorderSizePixel = 0,
			create("UIStroke") { Color = Color3.fromRGB(55, 50, 75), ApplyStrokeMode = Enum.ApplyStrokeMode.Border },
			create("TextLabel") {
				Position = UDim2.new(0, 10, 0, 4),
				Size = UDim2.new(0.5, 0, 0, 12),
				BackgroundTransparency = 1,
				Text = "SYSTEM LOG",
				TextColor3 = Color3.fromRGB(180, 80, 80),
				TextSize = 9,
				Font = Enum.Font.GothamBlack,
				TextXAlignment = Enum.TextXAlignment.Left,
			},
			create("TextLabel") {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.new(0, 80, 0, 10),
				BackgroundTransparency = 1,
				Text = function() return "LOG-" .. string.format("%04d", logCount()) end,
				TextColor3 = DIMLO,
				TextSize = 7,
				Font = Enum.Font.Code,
				TextXAlignment = Enum.TextXAlignment.Right,
			},
		},

		-- Scroll content
		create("ScrollingFrame") {
			Name = "LifeLog",
			Size = UDim2.new(1, 0, 1, -20),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Color3.fromRGB(100, 40, 40),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingEnabled = true,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
			ZIndex = 2,
			create("UIPadding") { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) },
			create("TextLabel") {
				Name = "LogText",
				Size = UDim2.new(1, -20, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Text = logContent,
				TextColor3 = Color3.fromRGB(180, 176, 200),
				TextSize = 11,
				Font = Enum.Font.Code,
				TextWrapped = true,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextXAlignment = Enum.TextXAlignment.Left,
				RichText = true,
			},
			[vide.action(function(sf: ScrollingFrame) scrollRef = sf end)] = true,
		},
	}
end

local function MobileAgeButton()
	return create("Frame") {
		Name = "AgeUpOuter",
		Size = UDim2.new(0.97, 0, 1, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(10, 9, 15),
		BorderSizePixel = 0,
		LayoutOrder = 3,
		ZIndex = 12,
		create("UIStroke") { Color = Color3.fromRGB(90, 25, 25), Thickness = 1 },
		create("UICorner") { CornerRadius = UDim.new(0, 4) },

		-- Left bracket label
		create("TextLabel") {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 8, 0.5, 0),
			Size = UDim2.new(0, 16, 0, 20),
			BackgroundTransparency = 1,
			Text = "[",
			TextColor3 = Color3.fromRGB(130, 40, 40),
			TextSize = 18,
			Font = Enum.Font.GothamBlack,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 12,
		},
		create("TextLabel") {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.new(0, 16, 0, 20),
			BackgroundTransparency = 1,
			Text = "]",
			TextColor3 = Color3.fromRGB(130, 40, 40),
			TextSize = 18,
			Font = Enum.Font.GothamBlack,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 12,
		},

		-- Main button — casi full width
		create("TextButton") {
			Name = "AgeUpButton",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0.88, 0, 0, 34),
			BackgroundColor3 = Color3.fromRGB(90, 12, 12),
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 13,
			create("UICorner") { CornerRadius = UDim.new(0, 4) },
			create("UIStroke") { Color = Color3.fromRGB(180, 50, 50), Thickness = 1 },

			create("TextLabel") {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = "+ AGE",
				TextColor3 = Color3.fromRGB(240, 220, 220),
				TextSize = 18,
				Font = Enum.Font.GothamBlack,
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = 13,
			},

			[vide.action(function(btn: TextButton)
				bindTap(btn, function()
					if _G.BitKaisenPlaySFX then _G.BitKaisenPlaySFX("Tick") end
					local ule = remotes.updateLifeEvent()
					if ule then ule:FireServer("AgeUp") end
				end)
			end)] = true,
		},

	}
end

local function MobileNavPanel()
	return create("Frame") {
		Name = "NavPanel",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 1,
		LayoutOrder = 4,

		create("UIPadding") { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) },
		create("UIGridLayout") {
			CellSize = UDim2.new(0.5, -7, 0, 44),
			CellPadding = UDim2.new(0, 6, 0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Horizontal,
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
				BackgroundColor3 = function()
					return isActive() and Color3.fromRGB(22, 20, 32) or Color3.fromRGB(14, 12, 20)
				end,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 5,
				create("UICorner") { CornerRadius = UDim.new(0, 4) },
				create("UIStroke") {
					Color = function()
						return isActive() and (entry.color or Color3.fromRGB(160, 40, 40)) or Color3.fromRGB(55, 50, 75)
					end,
					Thickness = 1,
				},

				-- Left color accent bar
				create("Frame") {
					Name = "Accent",
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.new(0, 3, 0.7, 0),
					BackgroundColor3 = entry.color or theme.Red,
					BorderSizePixel = 0,
					create("UICorner") { CornerRadius = UDim.new(1, 0) },
				},

				-- Title
				create("TextLabel") {
					Name = "Label",
					Position = UDim2.new(0, 10, 0, 0),
					Size = UDim2.new(1, -22, 1, 0),
					BackgroundTransparency = 1,
					Text = entry.label,
					TextColor3 = function()
						return isActive() and theme.Text or DIM
					end,
					TextSize = 11,
					Font = Enum.Font.GothamBlack,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = false,
					ClipsDescendants = true,
				},

				-- Arrow
				create("TextLabel") {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -6, 0.5, 0),
					Size = UDim2.new(0, 12, 0, 12),
					BackgroundTransparency = 1,
					Text = "›",
					TextColor3 = function()
						return isActive() and (entry.color or theme.Red) or DIMLO
					end,
					TextSize = 14,
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

		-- BLOQUE 1: Stats — scroll propio si el perfil no entra.
		-- Ocupa todo el espacio sobre el log (150px) + gap (6px) + age+nav (326px).
		create("ScrollingFrame") {
			Name = "StatsScroll",
			Size = UDim2.new(1, 0, 1, -386),   -- screen - 150log - 68age - 162nav - 6gap
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 0,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,

			create("UIListLayout") {
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			},
			create("UIPadding") {
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			},

			MobileProfileHeader(),
		},

		-- BLOQUE 2: Life Log — 150px fijos, scroll interno estilo WhatsApp.
		-- Siempre visible, completamente independiente del bloque de stats.
		create("Frame") {
			Name = "LogArea",
			Size = UDim2.new(1, 0, 0, 150),
			Position = UDim2.new(0, 0, 1, -380),   -- encima de age+nav
			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			MobileLifeLog(),
		},

		-- BLOQUE 3: +AGE — fijo, con margen claro sobre el nav.
		create("Frame") {
			Name = "AgeButtonAnchor",
			Size = UDim2.new(1, 0, 0, 68),
			Position = UDim2.new(0, 0, 1, -230),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 10,

			create("UIPadding") {
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
			},

			MobileAgeButton(),
		},

		-- BLOQUE 4: Nav — muestra 3 filas (6 items), resto scrolleable.
		create("ScrollingFrame") {
			Name = "NavAnchor",
			Size = UDim2.new(1, 0, 0, 162),
			Position = UDim2.new(0, 0, 1, -162),
			BackgroundColor3 = theme.Bg,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = theme.StrokeSoft,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,

			create("UIStroke") {
				Color = theme.StrokeSoft,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Thickness = 1,
			},
			create("UIPadding") {
				PaddingTop = UDim.new(0, 2),
				PaddingBottom = UDim.new(0, 6),
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
			},

			MobileNavPanel(),
		},
	}

	-- vide.action callbacks don't fire for Vide-created buttons in this tree,
	-- so register shell buttons in the tap router imperatively.
	do
		local mainPanel = gui:FindFirstChild("MainPanel")
		if mainPanel then
			local ageBtn = mainPanel:FindFirstChild("AgeUpButton", true)
			if ageBtn and ageBtn:IsA("TextButton") then
				bindTap(ageBtn, function()
					if _G.BitKaisenPlaySFX then _G.BitKaisenPlaySFX("Tick") end
					local ule = remotes.updateLifeEvent()
					if ule then
						ule:FireServer("AgeUp")
					end
				end)
			end

			local function registerNavBtn(child)
				if not child:IsA("TextButton") then return end
				bindTap(child, function()
					uiState.navigate(child.Name)
				end)
			end
			local function hookNavPanel(navPanel)
				if not navPanel then return end
				for _, child in ipairs(navPanel:GetChildren()) do
					registerNavBtn(child)
				end
				navPanel.ChildAdded:Connect(registerNavBtn)
			end
			local navAnchor = mainPanel:FindFirstChild("NavAnchor")
			hookNavPanel(navAnchor and navAnchor:FindFirstChild("NavPanel"))
		end
	end

	return gui
end

return { create = create_ }



