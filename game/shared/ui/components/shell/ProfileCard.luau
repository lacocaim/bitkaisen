local vide = require("@packages/vide")
local container = require("@ui-components/core/container")
local theme = require("@ui/theme")
local helpers = require("@ui/helpers")
local playerState = require("@ui-state/playerState")
local uiState = require("@ui-state/uiState")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local BitKaisenCombat = require(ReplicatedStorage:WaitForChild("BitKaisenCombat"))
local BitKaisenTraits = require(ReplicatedStorage:WaitForChild("BitKaisenTraits"))
local BitKaisenStudies = require(ReplicatedStorage:WaitForChild("BitKaisenStudies"))
local _pcL = BitKaisenLocale.getClientLocale()
local function _pc(key, fallback) return BitKaisenLocale.tOrFallback(_pcL, "ui." .. key, nil, fallback) end

local create = vide.create
local derive = vide.derive
local source = vide.source

local DIM    = Color3.fromRGB(100, 98, 120)
local DIMLO  = Color3.fromRGB(60, 58, 78)
local LABEL  = Color3.fromRGB(130, 128, 158)

-- powerKey is the stat's name in BitKaisenCombat.STAT_POWER_WEIGHTS. When it is given,
-- the row also shows what that stat is contributing to combat power right now.
-- Requested twice in content-suggestions by noobeh: "currently speed strength and
-- durability's bonuses are unknown". They were: the number lived on the server and the
-- bar only ever showed a value out of 100. Stats with no combat weight, like Looks,
-- pass nothing and the row stays as it was.
local function DossierBar(title: string, color: Color3, getValue: () -> number, powerKey: string?)
	local frac = derive(function() return math.clamp((getValue() or 0) / 100, 0, 1) end)
	local val  = derive(function()
		local base = tostring(math.floor(getValue() or 0)) .. " / 100"
		if not powerKey then
			return base
		end
		return base .. "   +" .. tostring(BitKaisenCombat.GetStatPower(powerKey, getValue() or 0))
	end)
	return create("Frame") {
		Name = "DB_" .. title,
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		create("Frame") {
			Name = "Dot",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.new(0, 8, 0, 8),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			create("UICorner") { CornerRadius = UDim.new(1, 0) },
		},
		create("TextLabel") {
			Position = UDim2.new(0, 14, 0, 0),
			Size = UDim2.new(0, 90, 1, 0),
			BackgroundTransparency = 1,
			Text = string.upper(title),
			TextColor3 = DIM,
			TextSize = 10,
			Font = Enum.Font.GothamBlack,
			TextXAlignment = Enum.TextXAlignment.Left,
		},
		create("Frame") {
			Name = "Track",
			Position = UDim2.new(0, 110, 0.5, -3),
			Size = UDim2.new(1, -212, 0, 6),
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
			Size = UDim2.new(0, 98, 1, 0),
			BackgroundTransparency = 1,
			Text = val,
			TextColor3 = DIMLO,
			TextSize = 10,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Right,
		},
	}
end

-- `visible` must be passed in here rather than assigned onto the returned Frame afterwards.
-- Roblox silently swallows `frame.Visible = <function>`: it does not error, it coerces the
-- function to true, and the row is then visible forever. That is why every conditional row
-- in this card was showing even when empty. Only vide's own property binding, applied at
-- creation, actually tracks the source.
local function DInfoRow(label: string, val: any, color: Color3?, valueName: string?, visible: any)
	return create("Frame") {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = visible,
		create("UISizeConstraint") { MinSize = Vector2.new(0, 18) },
		create("TextLabel") {
			Size = UDim2.new(0, 68, 0, 18),
			BackgroundTransparency = 1,
			Text = "\226\128\162 " .. string.upper(label),
			TextColor3 = LABEL,
			TextSize = 8,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
		},
		create("TextLabel") {
			Name = valueName,
			Position = UDim2.new(0, 70, 0, 0),
			Size = UDim2.new(1, -70, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = val,
			TextColor3 = color or theme.Text,
			TextSize = 11,
			Font = Enum.Font.GothamBlack,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextWrapped = true,
		},
	}
end

-- A Cursed Data row: hides itself while its getter returns nil, and keeps its slot in the
-- list. `getter` returns the text or nil, so the visibility and the value stay one source.
local function DInfoRowOrdered(label: string, getter: () -> string?, color: Color3?, order: number)
	return create("Frame") {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Visible = function() return getter() ~= nil end,
		create("UISizeConstraint") { MinSize = Vector2.new(0, 18) },
		create("TextLabel") {
			Size = UDim2.new(0, 68, 0, 18),
			BackgroundTransparency = 1,
			Text = "\226\128\162 " .. string.upper(label),
			TextColor3 = LABEL,
			TextSize = 8,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
		},
		create("TextLabel") {
			Position = UDim2.new(0, 70, 0, 0),
			Size = UDim2.new(1, -70, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = function() return getter() or "" end,
			TextColor3 = color or theme.Text,
			TextSize = 11,
			Font = Enum.Font.GothamBlack,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextWrapped = true,
		},
	}
end

-- Clickable info row (uses the container/guistate click pattern used
-- throughout the rest of the shell, instead of wiring GuiButton events by
-- hand -- see NavPanel/AgeUpButton for why that matters).
local function DClickableRow(label: string, val: any, color: Color3?, onClick: () -> ())
	return container {
		h = 18,
		ws = 1,
		transparency = 1,
		clicked = onClick,
		create("TextLabel") {
			Size = UDim2.new(0, 68, 1, 0),
			BackgroundTransparency = 1,
			Text = "\226\128\162 " .. string.upper(label),
			TextColor3 = LABEL,
			TextSize = 8,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
		},
		create("TextLabel") {
			Position = UDim2.new(0, 70, 0, 0),
			Size = UDim2.new(1, -70, 1, 0),
			BackgroundTransparency = 1,
			Text = val,
			TextColor3 = color or theme.Text,
			TextSize = 11,
			Font = Enum.Font.GothamBlack,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextWrapped = true,
		},
	}
end

local function ProfileCard()
	local stats = playerState.stats

	local nameText  = derive(function() local s = stats() return tostring(s and s.Name or "...") end)
	local ageVal    = derive(function() local s = stats() return s and helpers.getAgeDisplay(s) or "0" end)
	local yearVal   = derive(function() local s = stats() return s and tostring(helpers.getCurrentYear(s)) or "\226\128\148" end)
	local eraVal    = derive(function() local s = stats() return s and helpers.getCurrentEraDisplay(s) or "\226\128\148" end)

	local rankVal   = derive(function()
		local s = stats()
		if not s then return "\226\128\148" end
		if helpers.isProfileCurseLife(s) then return tostring(s.CurseGrade or "Unregistered Grade 3") end
		return tostring(s.Grade or "Unknown")
	end)
	local worldVal  = derive(function()
		local s = stats()
		if not s then return "\226\128\148" end
		return tostring(s.LifePath or helpers.getRoutePathText(s) or "Undecided")
	end)
	local fameVal   = derive(function() local s = stats() return tostring(math.clamp(tonumber(s and s.Fame) or 0, 0, 100)) end)
	local fearVal   = derive(function() local s = stats() return tostring(math.clamp(tonumber(s and s.Fear) or 0, 0, 100)) end)
	local lineageVal = derive(function() return helpers.getLineageText(stats()) end)
	local techVal   = derive(function()
		local s = stats()
		local technique = tostring(s and s.CursedTechnique or "None")
		if technique == "Miracle" then
			local charges = tonumber(s and s.MiracleCharges) or 0
			return "Miracle | Marks: " .. tostring(charges) .. "/6"
		end
		return technique
	end)
	local traitVal    = derive(function() local s = stats() return tostring(s and s.TraitSummary or "None") end)
	-- Update 31: the row used to list trait names and stop there, which is why players
	-- kept reporting that traits do nothing. They do. This adds up every modifier the
	-- traits are applying and says so, the way the stat bars started doing in Update 30.
	-- Computed here rather than on the server so it can never disagree with the traits
	-- the player actually holds.
	local traitEffectVal = derive(function()
		local s = stats()
		return (s and BitKaisenTraits.GetModifierSummary(s)) or "No active modifiers"
	end)
	local ceTraitVal  = derive(function() local s = stats() local t = s and tostring(s.CETrait or "") return (t and t ~= "") and ("Cursed Energy: " .. t) or "None" end)
	local assistantVal = derive(function()
		local s = stats()
		if not s then return "None" end
		local aname = s.AssistantName and tostring(s.AssistantName) or "None"
		local trust = math.clamp(tonumber(s.AssistantTrust) or 0, 0, 100)
		local skill = math.clamp(tonumber(s.AssistantSkill) or 0, 0, 100)
		return aname .. " | Trust " .. tostring(trust) .. " | Skill " .. tostring(skill)
	end)

	local ceVal     = derive(function() local s = stats() return tostring(s and s.CursedEnergy or 0) end)
	local cePotVal  = derive(function() local s = stats() return tostring(s and s.CEPotential or 0) end)
	local ceOutVal  = derive(function() local s = stats() return tostring(s and s.CEOutput or 0) end)
	local ceReinVal = derive(function() local s = stats() return tostring(s and s.CEReinforcement or 0) end)
	local ceCtrlVal = derive(function() local s = stats() return tostring(s and s.CEControl or 0) end)
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
	local popularityVal = derive(function()
		local s = stats()
		if not s then return "0" end
		local pop = math.clamp(tonumber(s.JujutsuHighPopularity) or 0, 0, 100)
		local wins = math.max(0, tonumber(s.GoodwillWins) or 0)
		return tostring(pop) .. " | Goodwill Wins " .. tostring(wins)
	end)
	local evolutionVal = derive(function()
		local s = stats()
		if not s then return "Dormant" end
		return tostring(s.TechniqueEvolutionStage or "Dormant") .. " | " .. tostring(s.TechniqueBranch or "None")
	end)
	local recVal    = derive(function() local s = stats() return tostring(s and s.TeacherRecommendations or 0) end)
	-- Update 31: a field of study is a decade of a life and it gates real content, so the
	-- dossier has to say where you stand in it. Without this the only feedback is a log
	-- line that scrolls away, which is the exact problem the Doing row was added to fix.
	-- Fields you have never opened stay hidden instead of showing Untrained forever.
	local studiesVal = derive(function()
		local s = stats()
		if not s then return "" end
		local parts = {}
		for _, field in ipairs(BitKaisenStudies.FIELDS) do
			local progress = BitKaisenStudies.GetProgress(s, field.Id)
			if progress > 0 then
				local level = BitKaisenStudies.GetLevel(s, field.Id)
				local nextLevel = BitKaisenStudies.GetNextLevel(s, field.Id)
				local text = field.Name .. ": " .. level.Name
				if nextLevel then
					text = text .. " (" .. tostring(math.max(0, nextLevel.Progress - progress))
						.. " to " .. nextLevel.Name .. ")"
				end
				table.insert(parts, text)
			end
		end
		return table.concat(parts, " | ")
	end)
	local studiesVisible = derive(function() return studiesVal() ~= "" end)

	local karmaVal  = derive(function() local s = stats() return tostring(s and s.KarmaLevel or "") end)
	local karmaVisible = derive(function() local s = stats() return s and s.KarmaLevel ~= nil end)
	local progressVal = derive(function() return helpers.getProfileProgressText(stats()) or "" end)
	local progressVisible = derive(function()
		local t = helpers.getProfileProgressText(stats())
		return t ~= nil and t ~= ""
	end)

	local cursedDataOpen = source(false)

	local resentmentVal = derive(function() local s = stats() return math.max(0, tonumber(s and s.CursedResentment) or 0) end)
	local resentmentFrac = derive(function() return math.clamp(resentmentVal() / 200, 0, 1) end)
	local resentmentColor = derive(function() return resentmentVal() > 100 and theme.Red or Color3.fromRGB(180, 60, 220) end)

	local rctRevivesText = derive(function()
		local s = stats()
		if not s then return nil end
		local used = math.max(0, tonumber(s.RCTRevives) or 0)
		local maxR = math.max(0, tonumber(s.RCTReviveMaxPerLife) or 0)
		if used == 0 and maxR == 0 then return nil end
		return tostring(used) .. " / " .. tostring(maxR) .. " this life"
	end)
	local rctPendingText = derive(function()
		local s = stats()
		local v = math.max(0, tonumber(s and s.RCTPendingRevive) or 0)
		return v > 0 and (tostring(v) .. " banked") or nil
	end)
	local ceTraitName = derive(function()
		local s = stats()
		local t = s and tostring(s.CETrait or "")
		return (t and t ~= "") and t or nil
	end)
	local awakeningText = derive(function()
		local s = stats()
		if not s then return "Not yet" end
		if s.AwakeningTriggered == true then
			local ctx = tostring(s.AwakeningContext or "")
			local label = ctx == "near_death" and "Near-death"
				or ctx == "domain_loss" and "Domain loss"
				or ctx == "mission_survive" and "Mission survival"
				or ctx == "age_threshold" and "Age threshold"
				or "Triggered"
			return "Triggered: " .. label
		elseif s.AwakeningEligible == true then
			return "Eligible, not yet met"
		else
			return "Not yet"
		end
	end)
	local awakeningColor = derive(function()
		local s = stats()
		if s and s.AwakeningTriggered == true then return theme.Purple end
		if s and s.AwakeningEligible == true then return theme.Gold end
		return theme.Muted
	end)
	local timesExorcisedText = derive(function()
		local s = stats()
		if not (s and helpers.isProfileCurseLife(s)) then return nil end
		local v = math.max(0, tonumber(s.TimesExorcised) or 0)
		return tostring(v)
	end)
	local bindingVowText = derive(function()
		local s = stats()
		if not s or s.BindingVowActive == nil then return nil end
		return s.BindingVowActive and "Active" or "None"
	end)
	local vodRCTText = derive(function()
		local s = stats()
		if not s or s.VoDRCTUsed == nil then return nil end
		return s.VoDRCTUsed and "Used this life" or "Available"
	end)
	local vodRCTColor = derive(function()
		local s = stats()
		return (s and s.VoDRCTUsed) and theme.Muted or theme.Green
	end)
	local rctSecondChancesText = derive(function()
		local s = stats()
		if not s then return nil end
		local v = math.max(0, tonumber(s.RCTSecondChances) or 0)
		return v > 0 and tostring(v) or nil
	end)

	local fileId = derive(function()
		local s = stats()
		local yr = helpers.getCurrentYear(s) or 2000
		local nm = tostring(s and s.Name or "")
		local h = 0
		for i = 1, #nm do h = (h * 31 + string.byte(nm, i)) % 100000 end
		return string.format("BK-%d-%05d", yr, h)
	end)

	return container {
		name = "ProfileCard",
		ws = 0.30, hs = 0.853,
		xs = 0.67, ys = 0.07,
		color = Color3.fromRGB(10, 9, 15),
		corner = 10,
		clips = true,
		create("UIStroke") { Color = Color3.fromRGB(55, 50, 75), Thickness = 1 },

		create("ScrollingFrame") {
			Name = "ProfileScroll",
			Size = UDim2.new(1, 0, 1, -22),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 5,
			ScrollBarImageColor3 = theme.SubText,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,

			create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder },

			create("Frame") {
				Name = "DossierHeader",
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundColor3 = Color3.fromRGB(14, 12, 20),
				BorderSizePixel = 0,
				LayoutOrder = 1,
				create("UIStroke") { Color = Color3.fromRGB(55, 50, 75), ApplyStrokeMode = Enum.ApplyStrokeMode.Border },
				create("TextLabel") {
					Position = UDim2.new(0, 14, 0, 5),
					Size = UDim2.new(0.6, 0, 0, 12),
					BackgroundTransparency = 1,
					Text = "CLASSIFIED  \230\169\159\229\175\134\230\140\135\229\174\154",
					TextColor3 = Color3.fromRGB(200, 196, 218),
					TextSize = 11,
					Font = Enum.Font.GothamBlack,
					TextXAlignment = Enum.TextXAlignment.Left,
				},
				create("TextLabel") {
					Position = UDim2.new(0, 14, 0, 18),
					Size = UDim2.new(0.6, 0, 0, 10),
					BackgroundTransparency = 1,
					Text = "BITKAISEN SORCERER DOSSIER",
					TextColor3 = DIMLO,
					TextSize = 8,
					Font = Enum.Font.GothamBold,
					TextXAlignment = Enum.TextXAlignment.Left,
				},
				create("TextLabel") {
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -14, 0, 5),
					Size = UDim2.new(0, 110, 0, 10),
					BackgroundTransparency = 1,
					Text = "FILE No.",
					TextColor3 = DIMLO,
					TextSize = 8,
					Font = Enum.Font.GothamBold,
					TextXAlignment = Enum.TextXAlignment.Right,
				},
				create("TextLabel") {
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -14, 0, 17),
					Size = UDim2.new(0, 140, 0, 12),
					BackgroundTransparency = 1,
					Text = fileId,
					TextColor3 = DIM,
					TextSize = 10,
					Font = Enum.Font.Code,
					TextXAlignment = Enum.TextXAlignment.Right,
				},
			},

			create("Frame") {
				Name = "Bars",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 2,
				create("UIPadding") { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) },
				create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3) },
				DossierBar(_pc("stat_health",     "Health"),     theme.Bad,                    function() local s = stats() return s and s.Health     or 100 end, "Health"),
				DossierBar(_pc("stat_happiness",  "Happiness"),  theme.Green,                  function() local s = stats() return s and s.Happiness  or 100 end),
				DossierBar(_pc("stat_smarts",     "Smarts"),     theme.Gold,                   function() local s = stats() return s and s.Smarts     or 50  end, "Smarts"),
				DossierBar(_pc("stat_looks",      "Looks"),      Color3.fromRGB(96, 170, 255), function() local s = stats() return s and s.Looks      or 50  end),
				DossierBar(_pc("stat_strength",   "Strength"),   Color3.fromRGB(236, 116, 76), function() local s = stats() return s and s.Strength   or 0   end, "Strength"),
				DossierBar(_pc("stat_speed",      "Speed"),      Color3.fromRGB(96, 220, 200), function() local s = stats() return s and s.Speed      or 0   end, "Speed"),
				DossierBar(_pc("stat_durability", "Durability"), Color3.fromRGB(150, 150, 160), function() local s = stats() return s and s.Durability or 0  end, "Durability"),
			},

			create("Frame") { Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.fromRGB(55, 50, 75), BorderSizePixel = 0, LayoutOrder = 3 },

			create("Frame") {
				Name = "BodyTop",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 4,
				create("UIPadding") { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) },

				create("Frame") {
					Name = "NameRow",
					Size = UDim2.new(1, 0, 0, 74),
					BackgroundTransparency = 1,

					create("TextLabel") {
						Position = UDim2.new(0, 0, 0, 0),
						Size = UDim2.new(1, -54, 0, 11),
						BackgroundTransparency = 1,
						Text = _pc("subject", "SUBJECT"),
						TextColor3 = DIMLO,
						TextSize = 8,
						Font = Enum.Font.GothamBlack,
						TextXAlignment = Enum.TextXAlignment.Left,
					},
					create("TextLabel") {
						Position = UDim2.new(0, 0, 0, 12),
						Size = UDim2.new(1, -54, 0, 28),
						BackgroundTransparency = 1,
						Text = nameText,
						TextColor3 = theme.Text,
						TextSize = 24,
						Font = Enum.Font.GothamBlack,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top,
						TextWrapped = true,
					},
					create("TextLabel") {
						Position = UDim2.new(0, 0, 0, 44),
						Size = UDim2.new(1, -54, 0, 14),
						BackgroundTransparency = 1,
						RichText = true,
						Text = derive(function()
							return string.format(
								'<font color="#6e6c88" size="8">%s</font>  <b>%s</b>    <font color="#6e6c88" size="8">%s</font>  <b>%s</b>    <font color="#6e6c88" size="8">%s</font>  <b>%s</b>',
								_pc("label_age", "AGE"), ageVal(), _pc("label_year", "YEAR"), yearVal(), _pc("label_era", "ERA"), eraVal()
							)
						end),
						TextColor3 = Color3.fromRGB(210, 208, 230),
						TextSize = 10,
						Font = Enum.Font.GothamBold,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Center,
					},
					create("TextLabel") {
						Name = "MonetizationBadges",
						Position = UDim2.new(0, 0, 0, 58),
						Size = UDim2.new(1, -54, 0, 14),
						BackgroundTransparency = 1,
						RichText = true,
						Text = derive(function()
							local s = stats()
							if not s then return "" end
							local badges = {}
							if s.HasPremiumOriginsPass then
								table.insert(badges, '<font color="#ffcf69">' .. _pc("badge_premium_origins", "LEGENDARY LINEAGE") .. '</font>')
							end
							if s.HasHighSocietyPass then
								table.insert(badges, '<font color="#e0a6ff">' .. _pc("badge_high_society", "HIGH SOCIETY") .. '</font>')
							end
							return table.concat(badges, "   ")
						end),
						TextSize = 9,
						Font = Enum.Font.GothamBlack,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Center,
					},

					create("Frame") {
						Name = "Stamp",
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.new(1, 0, 0, 0),
						Size = UDim2.new(0, 48, 0, 48),
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
							Position = UDim2.new(0, 0, 0.08, 0),
							Size = UDim2.new(1, 0, 0.42, 0),
							BackgroundTransparency = 1,
							Text = "\233\171\152\231\173\137\232\161\147\229\184\171",
							TextColor3 = Color3.fromRGB(140, 35, 35),
							TextSize = 10,
							Font = Enum.Font.GothamBold,
							TextXAlignment = Enum.TextXAlignment.Center,
							ZIndex = 3,
						},
						create("TextLabel") {
							Position = UDim2.new(0, 0, 0.5, 0),
							Size = UDim2.new(1, 0, 0.42, 0),
							BackgroundTransparency = 1,
							Text = "\232\170\141\229\143\175\230\184\136",
							TextColor3 = Color3.fromRGB(190, 50, 50),
							TextSize = 12,
							Font = Enum.Font.GothamBlack,
							TextXAlignment = Enum.TextXAlignment.Center,
							ZIndex = 3,
						},
					},
				},
			},

			create("Frame") { Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.fromRGB(55, 50, 75), BorderSizePixel = 0, LayoutOrder = 5 },

			create("Frame") {
				Name = "BodyBottom",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 6,
				create("UIPadding") { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) },
				create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) },

				create("Frame") {
					Name = "InfoGrid",
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = 1,
					create("UIListLayout") {
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Top,
						Padding = UDim.new(0, 10),
					},

					create("Frame") {
						Name = "LeftCol",
						Size = UDim2.new(0.5, -5, 0, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
						LayoutOrder = 1,
						create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) },
						DInfoRow(_pc("dossier_rank",      "Rank"),      rankVal,      theme.Gold),
						DInfoRow(_pc("dossier_world",     "World"),     worldVal,     theme.Gold),
						DInfoRow(_pc("dossier_fame",      "Fame"),      fameVal,      theme.Orange),
						DInfoRow(_pc("dossier_fear",      "Fear"),      fearVal,      theme.Red),
						DInfoRow(_pc("dossier_lineage",   "Lineage"),   lineageVal,   theme.Text),
						DClickableRow(_pc("dossier_technique", "TECHNIQUE"), techVal, theme.Purple, function()
							uiState.navigate("technique_mastery")
						end),
						DInfoRow(_pc("dossier_traits",    "Traits"),    traitVal,     theme.Gold, "Traits"),
						DInfoRow(_pc("dossier_trait_effect", "Doing"),  traitEffectVal, theme.Green),
						DInfoRow(_pc("dossier_studies", "Studies"), studiesVal, theme.Blue, nil, studiesVisible),
						DInfoRow(_pc("dossier_cetrait",   "CE Trait"),  ceTraitVal,   theme.Purple),
						DInfoRow(_pc("dossier_assistant", "Assistant"), assistantVal, theme.SubText),
					},

					create("Frame") {
						Name = "RightCol",
						Size = UDim2.new(0.5, -5, 0, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
						LayoutOrder = 2,
						create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) },
						DInfoRow(_pc("dossier_ce",        "CE"),          ceVal,        theme.Purple),
						DInfoRow(_pc("dossier_cepot",     "CE Potential"),cePotVal,     theme.Purple),
						DInfoRow(_pc("dossier_ceout",     "CE Output"),   ceOutVal,     theme.Purple),
						DInfoRow(_pc("dossier_cerein",    "CE Reinf."),   ceReinVal,    theme.Purple),
						DInfoRow(_pc("dossier_cectrl",    "CE Control"),  ceCtrlVal,    theme.Purple),
						DInfoRow(_pc("dossier_money",     "Money"),       moneyVal,     theme.Green),
						DInfoRow(_pc("dossier_rep",       "Rep"),         repVal,       repColor),
						DInfoRow(_pc("dossier_school",    "School"),      schoolVal,    theme.Blue),
						DInfoRow(_pc("dossier_path",      "Path"),        pathVal,      pathColor),
						DInfoRow(_pc("dossier_alignment", "Alignment"),   alignVal,     alignColor),
						DInfoRow(_pc("dossier_jjh_pop",   "JJH Pop."),    popularityVal, theme.Gold),
						DInfoRow(_pc("dossier_tech_stage","Tech Stage"),  evolutionVal, theme.Purple),
						DInfoRow(_pc("dossier_recs",      "Recs"),        recVal,       theme.Orange),
						DInfoRow(_pc("dossier_karma", "Karma"), karmaVal, theme.Gold, nil, karmaVisible),
					},
				},

				create("TextLabel") {
					Name = "Progress",
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Text = progressVal,
					TextColor3 = pathColor,
					TextSize = 10,
					Font = Enum.Font.GothamBold,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
					Visible = progressVisible,
					LayoutOrder = 2,
				},

				-- Cursed Data collapsible section
				create("Frame") {
					Name = "CursedDataSection",
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = 3,
					create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0) },

					-- Toggle button
					create("TextButton") {
						Name = "CursedDataToggle",
						Size = UDim2.new(1, 0, 0, 22),
						BackgroundColor3 = Color3.fromRGB(18, 14, 28),
						BorderSizePixel = 0,
						LayoutOrder = 1,
						Text = function() return cursedDataOpen() and "\226\150\190 CURSED DATA" or "\226\150\184 CURSED DATA" end,
						TextColor3 = Color3.fromRGB(160, 80, 200),
						TextSize = 9,
						Font = Enum.Font.GothamBlack,
						TextXAlignment = Enum.TextXAlignment.Left,
						create("UIPadding") { PaddingLeft = UDim.new(0, 4) },
						create("UIStroke") { Color = Color3.fromRGB(55, 30, 75), Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border },
						Activated = function()
							cursedDataOpen(not cursedDataOpen())
						end,
					},

					-- Expandable body
					create("Frame") {
						Name = "CursedDataBody",
						Size = UDim2.new(1, 0, 0, 0),
						AutomaticSize = function()
							return cursedDataOpen() and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
						end,
						BackgroundColor3 = Color3.fromRGB(12, 8, 20),
						BorderSizePixel = 0,
						Visible = cursedDataOpen,
						LayoutOrder = 2,
						create("UIStroke") { Color = Color3.fromRGB(55, 30, 75), Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border },
						create("UIPadding") { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) },
						create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) },

						-- Cursed Resentment bar (always shown)
						create("Frame") {
							Name = "ResentmentRow",
							Size = UDim2.new(1, 0, 0, 0),
							AutomaticSize = Enum.AutomaticSize.Y,
							BackgroundTransparency = 1,
							LayoutOrder = 1,
							create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3) },

							create("Frame") {
								Size = UDim2.new(1, 0, 0, 14),
								BackgroundTransparency = 1,
								create("TextLabel") {
									Size = UDim2.new(0, 110, 1, 0),
									BackgroundTransparency = 1,
									Text = "\226\128\162 CURSED RESENTMENT",
									TextColor3 = LABEL,
									TextSize = 8,
									Font = Enum.Font.GothamBold,
									TextXAlignment = Enum.TextXAlignment.Left,
								},
								create("TextLabel") {
									Position = UDim2.new(0, 112, 0, 0),
									Size = UDim2.new(1, -112, 1, 0),
									BackgroundTransparency = 1,
									Text = function() return tostring(resentmentVal()) .. " / 200" end,
									TextColor3 = function() return resentmentVal() > 100 and theme.Red or Color3.fromRGB(200, 196, 218) end,
									TextSize = 10,
									Font = Enum.Font.GothamBlack,
									TextXAlignment = Enum.TextXAlignment.Right,
								},
							},

							-- Bar track
							create("Frame") {
								Size = UDim2.new(1, 0, 0, 6),
								BackgroundColor3 = Color3.fromRGB(22, 16, 34),
								BorderSizePixel = 0,
								ClipsDescendants = true,
								create("UICorner") { CornerRadius = UDim.new(0, 999) },
								-- Fill
								create("Frame") {
									Size = function() return UDim2.new(resentmentFrac(), 0, 1, 0) end,
									BackgroundColor3 = resentmentColor,
									BorderSizePixel = 0,
									create("UICorner") { CornerRadius = UDim.new(0, 999) },
								},
								-- Threshold marker at 50% (100/200)
								create("Frame") {
									Name = "ThresholdMarker",
									AnchorPoint = Vector2.new(0.5, 0),
									Position = UDim2.new(0.5, 0, 0, 0),
									Size = UDim2.new(0, 1, 1, 0),
									BackgroundColor3 = theme.Red,
									BorderSizePixel = 0,
									ZIndex = 2,
								},
							},

							-- "Curse Risk" label at threshold
							create("Frame") {
								Size = UDim2.new(1, 0, 0, 10),
								BackgroundTransparency = 1,
								create("TextLabel") {
									AnchorPoint = Vector2.new(0.5, 0),
									Position = UDim2.new(0.5, 0, 0, 0),
									Size = UDim2.new(0, 70, 1, 0),
									BackgroundTransparency = 1,
									Text = "▲ CURSE RISK",
									TextColor3 = theme.Red,
									TextSize = 7,
									Font = Enum.Font.GothamBold,
									TextXAlignment = Enum.TextXAlignment.Center,
								},
							},
						},

						-- Optional rows (only rendered when value is relevant)
						(function()
							local rows = create("Frame") {
								Name = "OptionalRows",
								Size = UDim2.new(1, 0, 0, 0),
								AutomaticSize = Enum.AutomaticSize.Y,
								BackgroundTransparency = 1,
								LayoutOrder = 2,
								create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) },

								DInfoRowOrdered("RCT Revives", rctRevivesText, theme.Green, 1),
								DInfoRowOrdered("Banked RCT", rctPendingText, theme.Green, 2),
								DInfoRowOrdered("CE Trait", ceTraitName, theme.Purple, 3),
								(function()
									local row = DInfoRow("Awakening", awakeningText, awakeningColor)
									row.LayoutOrder = 4
									return row
								end)(),
								DInfoRowOrdered("Times Exorcised", timesExorcisedText, theme.Orange, 5),
								DInfoRowOrdered("Binding Vow", bindingVowText, theme.Gold, 6),
								DInfoRowOrdered("VoD RCT", vodRCTText, vodRCTColor, 7),
								DInfoRowOrdered("RCT 2nd Chances", rctSecondChancesText, theme.Green, 8),
							}
							return rows
						end)(),
					},
				},
			},

		},

		-- Pinned outside the scroll so it always sits flush with the bottom
		-- edge of the card instead of leaving dead space after short content.
		create("Frame") {
			Name = "DossierFooter",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundColor3 = Color3.fromRGB(14, 12, 20),
			BorderSizePixel = 0,
			create("UIStroke") { Color = Color3.fromRGB(55, 50, 75), ApplyStrokeMode = Enum.ApplyStrokeMode.Border },
			create("TextLabel") {
				Position = UDim2.new(0, 14, 0, 6),
				Size = UDim2.new(0.7, 0, 0, 10),
				BackgroundTransparency = 1,
				Text = "BITKAISEN BUREAU OF JUJUTSU AFFAIRS  \229\145\170\232\161\147\229\177\128\194\183\232\168\152\194\183\194\183\194\183",
				TextColor3 = DIMLO,
				TextSize = 8,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
			},
			create("TextLabel") {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.new(0, 70, 0, 10),
				BackgroundTransparency = 1,
				Text = "AUTHORIZED",
				TextColor3 = DIMLO,
				TextSize = 8,
				Font = Enum.Font.GothamBlack,
				TextXAlignment = Enum.TextXAlignment.Right,
			},
		},
	}
end

return ProfileCard
