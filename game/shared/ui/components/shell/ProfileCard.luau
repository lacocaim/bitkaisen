local vide = require("@packages/vide")
local container = require("@ui-components/core/container")
local text = require("@ui-components/core/text")
local stroke = require("@ui-components/core/stroke")
local gradient = require("@ui-components/core/gradient")
local theme = require("@ui/theme")
local helpers = require("@ui/helpers")
local playerState = require("@ui-state/playerState")

local create = vide.create
local derive = vide.derive

local function StatBar(title: string, color: Color3, getValue: () -> number)
	local fraction = derive(function()
		return math.clamp((getValue() or 0) / 100, 0, 1)
	end)

	return container {
		name = "StatBar_" .. title,
		ws = 1, h = 24,
		container {
			name = "Title",
			ws = 0.35, hs = 1,
			text {
				text = title,
				color = color,
				size = 13,
				font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
				xalign = "left",
				ws = 1, hs = 1,
			},
		},
		container {
			name = "Track",
			ws = 0.65, h = 12,
			xs = 0.35, ys = 0.25,
			color = Color3.fromRGB(25, 25, 30),
			corner = 999,
			container {
				name = "Fill",
				w = function() return fraction() end,
				ws = function() return fraction() end,
				hs = 1,
				color = color,
				corner = 999,
			},
		},
	}
end

local function ProfileCard()
	local stats = playerState.stats

	local nameText = derive(function()
		local s = stats()
		return tostring(s and s.Name or "Loading...")
	end)

	local ageText = derive(function()
		local s = stats()
		if not s then return "Age: 0" end
		return "Age: " .. helpers.getAgeDisplay(s) .. "  \u{2022}  Year: " .. tostring(helpers.getCurrentYear(s)) .. "  \u{2022}  Era: " .. helpers.getCurrentEraDisplay(s)
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
		if not s then return "World: Fame 0 | Fear 0" end
		local lifePath = tostring(s.LifePath or helpers.getRoutePathText(s) or "Undecided")
		local fame = math.clamp(tonumber(s.Fame) or 0, 0, 100)
		local fear = math.clamp(tonumber(s.Fear) or 0, 0, 100)
		local support = math.clamp(tonumber(s.PublicSupport) or 0, 0, 100)
		local hunters = math.clamp(tonumber(s.HunterPressure) or 0, 0, 100)
		local copycats = math.max(0, tonumber(s.CopycatIncidents) or 0)
		local tier = tostring(s.WorldReputationTier or "Unknown")
		local extras = ""
		if support > 0 then extras ..= " | Support " .. tostring(support) end
		if hunters > 0 then extras ..= " | Hunters " .. tostring(hunters) end
		if copycats > 0 then extras ..= " | Copycats " .. tostring(copycats) end
		return "World: " .. lifePath .. " | " .. tier .. " | Fame " .. tostring(fame) .. " | Fear " .. tostring(fear) .. extras
	end)

	local affiliationText = derive(function()
		local s = stats()
		if not s then return "Affiliation: Unaffiliated" end
		local aff = tostring(s.Affiliation or (s.InJujutsuHigh and "Jujutsu High" or "Unaffiliated"))
		local rank = tostring(s.AffiliationRank or "None")
		local rep = math.clamp(tonumber(s.AffiliationReputation) or 0, 0, 100)
		return "Affiliation: " .. aff .. " | " .. rank .. " | Rep " .. tostring(rep)
	end)

	local popularityText = derive(function()
		local s = stats()
		if not s then return "Jujutsu High: Popularity 0" end
		local pop = math.clamp(tonumber(s.JujutsuHighPopularity) or 0, 0, 100)
		local wins = math.max(0, tonumber(s.GoodwillWins) or 0)
		return "Jujutsu High: Popularity " .. tostring(pop) .. " | Goodwill Wins " .. tostring(wins)
	end)

	local assistantText = derive(function()
		local s = stats()
		if not s then return "Assistant: None" end
		local name = s.AssistantName and tostring(s.AssistantName) or "None"
		local trust = math.clamp(tonumber(s.AssistantTrust) or 0, 0, 100)
		local skill = math.clamp(tonumber(s.AssistantSkill) or 0, 0, 100)
		return "Assistant: " .. name .. " | Trust " .. tostring(trust) .. " | Skill " .. tostring(skill)
	end)

	local evolutionText = derive(function()
		local s = stats()
		if not s then return "Technique Stage: Dormant" end
		local branch = tostring(s.TechniqueBranch or "None")
		return "Technique Stage: " .. tostring(s.TechniqueEvolutionStage or "Dormant") .. " | " .. branch
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
		return "CE Reserves: " .. tostring(s and s.CursedEnergy or 0)
	end)
	local moneyText = derive(function()
		local s = stats()
		return "Money: $" .. helpers.formatMoneyAmount(s and s.Money or 0)
	end)
	local repText = derive(function()
		local s = stats()
		return "Reputation: " .. tostring(s and s.Reputation or 0)
	end)
	local repColor = derive(function()
		local s = stats()
		return (tonumber(s and s.Reputation) or 0) < 0 and theme.Red or theme.Gold
	end)
	local recText = derive(function()
		local s = stats()
		return "Recommendations: " .. tostring(s and s.TeacherRecommendations or 0)
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
			return "Threat Class: " .. tostring(s and (s.CurseThreatClass or s.SocietyStatus) or "Local")
		end
		return "Alignment: " .. helpers.getDisplayedAlignment(s)
	end)
	local alignColor = derive(function()
		local s = stats()
		if helpers.isProfileCurseLife(s) then return theme.Orange end
		return helpers.getAlignmentColor(helpers.getDisplayedAlignment(s))
	end)

	local progressText = derive(function() return helpers.getProfileProgressText(stats()) or "" end)
	local progressVisible = derive(function()
		local t = helpers.getProfileProgressText(stats())
		return t ~= nil and t ~= ""
	end)

	return container {
		name = "ProfileCard",
		ws = 0.30, hs = 0.60,
		xs = 0.67, ys = 0.07,
		color = theme.Panel,
		corner = 12,
		gradient { color = ColorSequence.new(theme.Panel, theme.Bg2), rotation = 90 },
		stroke { color = theme.StrokeSoft },

		create("ScrollingFrame") {
			Name = "ProfileScroll",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 6,
			ScrollBarImageColor3 = theme.SubText,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ClipsDescendants = true,
			Active = true,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,

			create("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) },
			create("UIPadding") {
				PaddingTop = UDim.new(0, 15), PaddingBottom = UDim.new(0, 15),
				PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20),
			},

			text { text = nameText, size = 24, font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold), color = theme.Text, xalign = "left", ws = 1, auto = "y", order = 1 },
			text { text = ageText, size = 16, font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), color = theme.SubText, xalign = "left", ws = 1, auto = "y", order = 2 },

			container { name = "Divider", ws = 1, h = 1, color = theme.StrokeSoft, order = 3 },

			text { text = gradeText, size = 14, font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), color = theme.SubText, xalign = "left", ws = 1, auto = "y", order = 4 },
			text { text = worldRepText, size = 12, font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), color = theme.Gold, xalign = "left", ws = 1, auto = "y", order = 5 },
			text { text = affiliationText, size = 12, font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), color = theme.SubText, xalign = "left", ws = 1, auto = "y", order = 6 },
			text { text = popularityText, size = 12, font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), color = theme.Gold, xalign = "left", ws = 1, auto = "y", order = 7 },
			text { text = assistantText, size = 12, font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium), color = theme.SubText, xalign = "left", ws = 1, auto = "y", order = 8 },
			text { text = evolutionText, size = 12, font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), color = theme.Purple, xalign = "left", ws = 1, auto = "y", order = 9 },
			text { text = clanText, size = 14, font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium), color = theme.Text, xalign = "left", ws = 1, auto = "y", order = 10 },
			text { text = techText, size = 14, font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), color = theme.Purple, xalign = "left", ws = 1, auto = "y", order = 11 },
			text { text = traitText, size = 12, font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), color = theme.Gold, xalign = "left", ws = 1, auto = "y", order = 12 },
			text { text = ceText, size = 14, font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), color = theme.Purple, xalign = "left", ws = 1, auto = "y", order = 13 },
			text { text = moneyText, size = 14, font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), color = theme.Green, xalign = "left", ws = 1, auto = "y", order = 14 },
			text { text = repText, size = 14, font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), color = repColor, xalign = "left", ws = 1, auto = "y", order = 15 },
			text { text = recText, size = 14, font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), color = theme.Orange, xalign = "left", ws = 1, auto = "y", order = 16 },
			text { text = schoolText, size = 14, font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), color = theme.Blue, xalign = "left", ws = 1, auto = "y", order = 17 },
			text { text = pathText, size = 13, font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), color = pathColor, xalign = "left", ws = 1, auto = "y", order = 18 },
			text { text = alignText, size = 13, font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), color = alignColor, xalign = "left", ws = 1, auto = "y", order = 19 },
			text { text = progressText, size = 12, font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), color = pathColor, xalign = "left", ws = 1, auto = "y", order = 20, visible = progressVisible },

			container { name = "Divider2", ws = 1, h = 1, color = theme.StrokeSoft, order = 21 },

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
			StatBar("Speed", Color3.fromRGB(96, 220, 200), function()
				local s = playerState.stats()
				return s and s.Speed or 0
			end),
			StatBar("Durability", Color3.fromRGB(150, 150, 160), function()
				local s = playerState.stats()
				return s and s.Durability or 0
			end),
		},
	}
end

return ProfileCard
