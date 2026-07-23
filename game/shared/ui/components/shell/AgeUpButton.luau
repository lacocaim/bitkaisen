local vide = require("@packages/vide")
local container = require("@ui-components/core/container")
local text = require("@ui-components/core/text")
local stroke = require("@ui-components/core/stroke")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local playerState = require("@ui-state/playerState")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _ui(key, fallback) return BitKaisenLocale.tOrFallback(_L, "ui." .. key, nil, fallback) end

local source = vide.source
local derive = vide.derive

local function AgeUpButton()
	local busy = source(false)
	local stats = playerState.stats

	-- Multiplayer Fase 2 ("El Repique"): Public-mode worlds share one
	-- calendar -- there's no individual +AGE, only a vote to advance it.
	-- Private stays exactly as it always was.
	local buttonText = derive(function()
		local s = stats()
		if s and s.WorldMode == "Public" then
			local count = tonumber(s.PublicEraVoteCount) or 0
			local needed = tonumber(s.PublicEraVoteNeeded) or 1
			return "🗳️ " .. _ui("btn_propose_era", "PROPOSE ERA ADVANCE") .. " (" .. count .. "/" .. needed .. ")"
		end
		return _ui("btn_age_up", "+ AGE")
	end)

	-- Visual polish pass: a thin fill bar under the label showing vote
	-- progress at a glance, not just the "(count/needed)" text. Zero width
	-- (invisible) in Private mode.
	local voteProgressScale = derive(function()
		local s = stats()
		if s and s.WorldMode == "Public" then
			local count = tonumber(s.PublicEraVoteCount) or 0
			local needed = math.max(1, tonumber(s.PublicEraVoteNeeded) or 1)
			return math.clamp(count / needed, 0, 1)
		end
		return 0
	end)

	return container {
		name = "ActionRow",
		ws = 1, hs = 1,
		color = Color3.fromRGB(10, 9, 15),
		corner = 10,
		stroke { color = Color3.fromRGB(90, 25, 25), thickness = 1 },

		container {
			name = "Bracket_Left",
			w = 20, h = 26,
			x = 14, xs = 0, ys = 0.5, y = 0, anchor = { 0, 0.5 },
			transparency = 1,
			text {
				text = "[",
				color = Color3.fromRGB(130, 40, 40),
				size = 22,
				font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy),
				xalign = "left",
				ws = 1, hs = 1,
			},
		},
		container {
			name = "Bracket_Right",
			w = 20, h = 26,
			x = -14, xs = 1, ys = 0.5, y = 0, anchor = { 1, 0.5 },
			transparency = 1,
			text {
				text = "]",
				color = Color3.fromRGB(130, 40, 40),
				size = 22,
				font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy),
				xalign = "right",
				ws = 1, hs = 1,
			},
		},

		container {
			name = "AgeUpButton",
			ws = 1, w = -60, hs = 1, h = -12,
			xs = 0.5, ys = 0.5, anchor = { 0.5, 0.5 },
			color = Color3.fromRGB(90, 12, 12),
			corner = 8,
			clicked = function()
				if busy() then return end
				busy(true)
				if _G.BitKaisenPlaySFX then _G.BitKaisenPlaySFX("Tick") end
				local s = stats()
				if s and s.WorldMode == "Public" then
					local proposeEraAdvance = remotes.get("ProposeEraAdvance")
					if proposeEraAdvance then
						proposeEraAdvance:FireServer()
					end
				else
					local ule = remotes.updateLifeEvent()
					if ule then
						ule:FireServer("AgeUp")
					end
				end
				task.delay(0.35, function() busy(false) end)
			end,
			stroke { color = Color3.fromRGB(180, 50, 50), thickness = 2 },
			text {
				text = buttonText,
				color = Color3.fromRGB(240, 220, 220),
				size = 22,
				font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy),
				ws = 1, hs = 1,
			},
			container {
				name = "VoteProgressTrack",
				ws = 1, w = -24, h = 4,
				xs = 0.5, ys = 1, y = -8, anchor = { 0.5, 1 },
				color = Color3.fromRGB(40, 12, 12),
				corner = 2,
				clips = true,

				container {
					name = "VoteProgressFill",
					ws = voteProgressScale, hs = 1,
					xs = 0, ys = 0,
					color = Color3.fromRGB(255, 212, 94),
				},
			},
		},
	}
end

return AgeUpButton
