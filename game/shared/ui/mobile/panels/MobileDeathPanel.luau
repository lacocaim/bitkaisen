local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local mc = require("@ui/mobile/mobileComponents")
local theme = mc.theme
local bindTap = mc.bindTap
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _dt(key, fallback) return BitKaisenLocale.tOrFallback(_L, "death." .. key, nil, fallback) end

local player = Players.LocalPlayer

local RCT_REVIVE_PRODUCT_ID = 3601401158
local RCT_REVIVE_MAX_PER_LIFE = 2
local TEST_PURCHASE_PLACE_ID = 104206065947170

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SLIDE = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function formatMoneyAmount(value)
	value = math.floor((tonumber(value) or 0) * 100 + 0.5) / 100
	if value % 1 == 0 then
		return tostring(math.floor(value))
	end
	return string.format("%.2f", value)
end

local function getOrdinalSuffix(n)
	n = tonumber(n) or 1
	local lastTwo = n % 100
	if lastTwo >= 11 and lastTwo <= 13 then
		return "th"
	end
	local lastDigit = n % 10
	if lastDigit == 1 then return "st"
	elseif lastDigit == 2 then return "nd"
	elseif lastDigit == 3 then return "rd"
	end
	return "th"
end

local function buildBiography(stats)
	local name = tostring(stats.Name or "Unknown")
	local age = tostring(stats.Age or 0)
	local grade = tostring(stats.Grade or "Unknown")
	local technique = tostring(stats.CursedTechnique or "None")
	local family = tostring(stats.FamilyName or "Unknown")
	local origin = tostring(stats.Origin or stats.Clan or "Unknown")
	local missionsCompleted = tostring(stats.MissionsCompleted or 0)
	local reputation = tostring(stats.Reputation or 0)
	local generation = tostring(stats.Generation or 1)

	local clanLine = ""
	if stats.ClanFounded then
		local clanName = tostring(stats.PlayerClanName or "Unnamed Clan")
		clanLine = BitKaisenLocale.tOrFallback(_L, "death.bio_clan_founded", nil,
			"\n\nThey founded the <b>{clan}</b>, leaving behind a name that other sorcerers would remember.")
			:gsub("{clan}", clanName)
	end

	local techniqueLine = ""
	if technique ~= "None" then
		techniqueLine = BitKaisenLocale.tOrFallback(_L, "death.bio_technique", nil, " They awakened <b>{technique}</b>.")
			:gsub("{technique}", technique)
	else
		techniqueLine = _dt("bio_no_technique", " No recognized cursed technique was awakened.")
	end

	local generationLine = ""
	if stats.Generation and stats.Generation > 1 then
		local genStr = generation .. getOrdinalSuffix(stats.Generation)
		generationLine = BitKaisenLocale.tOrFallback(_L, "death.bio_generation", nil, "\n\n<b>{gen} generation</b> of the bloodline.")
			:gsub("{gen}", genStr)
	end

	local mainText = BitKaisenLocale.tOrFallback(_L, "death.bio_main", nil,
		"<b>{name}</b> of the <b>Family {family}</b> lived <b>{age} years</b>.\n\nBorn from <b>{origin}</b>, reached <b>{grade}</b>.{technique}\n\nMissions: <b>{missions}</b>  •  Reputation: <b>{rep}</b>")
		:gsub("{name}", name):gsub("{family}", family):gsub("{age}", age):gsub("{origin}", origin)
		:gsub("{grade}", grade):gsub("{technique}", techniqueLine):gsub("{missions}", missionsCompleted):gsub("{rep}", reputation)

	return mainText .. clanLine .. generationLine
end

local function getRibbon(stats)
	local age = tonumber(stats.Age) or 0
	local grade = tostring(stats.Grade or "")
	local rep = tonumber(stats.Reputation) or 0
	local missions = tonumber(stats.MissionsCompleted) or 0
	local isCurseUser = stats.IsCurseUser == true or stats.Path == "Curse User" or stats.Alignment == "Curse User"
	local isCurseLife = tostring(stats.World or "") == "Cursed Spirit" or tostring(stats.Lineage or ""):find("Cursed")
	local hasSpecialGrade = grade == "Special Grade"
	local hasDomain = stats.DomainExpansion and stats.DomainExpansion ~= "None" and stats.DomainExpansion ~= ""
	local hasRCT = stats.RCT == true or stats.HasRCT == true
	local generation = tonumber(stats.Generation) or 1
	local founded = stats.ClanFounded == true

	if hasSpecialGrade and hasDomain and age >= 50 then
		return _dt("ribbon_legend", "🏆 LEGEND OF THE CURSED WORLD"), Color3.fromRGB(255, 200, 50)
	elseif hasSpecialGrade and hasDomain then
		return _dt("ribbon_special", "👑 SPECIAL GRADE SORCERER"), Color3.fromRGB(220, 160, 255)
	elseif isCurseUser and grade == "Special Grade" then
		return _dt("ribbon_curse_king", "☠️ CURSE USER KING"), Color3.fromRGB(200, 60, 80)
	elseif isCurseUser and rep < -50 then
		return _dt("ribbon_feared", "💀 FEARED CURSE USER"), Color3.fromRGB(180, 40, 60)
	elseif isCurseUser then
		return _dt("ribbon_curse_user", "🩸 CURSE USER"), Color3.fromRGB(200, 80, 90)
	elseif isCurseLife then
		return _dt("ribbon_spirit", "👁 CURSED SPIRIT"), Color3.fromRGB(140, 80, 200)
	elseif hasRCT and hasDomain then
		return _dt("ribbon_elite", "⚡ ELITE JUJUTSU SORCERER"), Color3.fromRGB(120, 200, 255)
	elseif hasDomain then
		return _dt("ribbon_domain", "🌀 DOMAIN USER"), Color3.fromRGB(140, 120, 255)
	elseif hasRCT then
		return _dt("ribbon_rct", "✨ RCT PRACTITIONER"), Color3.fromRGB(100, 220, 180)
	elseif founded then
		return _dt("ribbon_founder", "🏯 CLAN FOUNDER"), Color3.fromRGB(255, 180, 60)
	elseif generation >= 5 then
		return _dt("ribbon_bloodline", "🔱 DEEP BLOODLINE"), Color3.fromRGB(180, 140, 255)
	elseif missions >= 100 then
		return _dt("ribbon_veteran", "⚔️ VETERAN SORCERER"), Color3.fromRGB(120, 200, 140)
	elseif grade == "Grade 1" or grade == "Semi-Grade 1" then
		return _dt("ribbon_grade1", "🎖 GRADE 1 SORCERER"), Color3.fromRGB(100, 180, 255)
	elseif age >= 80 then
		return _dt("ribbon_long_life", "🕰 LONG LIFE"), Color3.fromRGB(160, 160, 180)
	elseif age <= 18 then
		return _dt("ribbon_short_life", "🌱 LIFE CUT SHORT"), Color3.fromRGB(180, 180, 200)
	elseif rep >= 100 then
		return _dt("ribbon_celebrated", "🌟 CELEBRATED SORCERER"), Color3.fromRGB(255, 220, 80)
	else
		return _dt("ribbon_ordinary", "📜 ORDINARY LIFE"), Color3.fromRGB(140, 140, 160)
	end
end

local function getRCTReviveUses(stats)
	if typeof(stats) ~= "table" then
		return 0
	end
	return math.max(0, tonumber(stats.RCTRevives) or 0)
end

local function canShowReincarnation(stats)
	if typeof(stats) ~= "table" then
		return false
	end
	local ce = tonumber(stats.CursedEnergy) or 0
	local anchors = tonumber(stats.CursedObjectAnchors) or 0
	local anchorProgress = tonumber(stats.CursedObjectAnchorProgress) or 0
	return ce >= 120 and (anchors >= 1 or anchorProgress >= 75)
end

local function canShowCurseRebirth(stats)
	if typeof(stats) ~= "table" then
		return false
	end
	if stats.IsCurse == true or tostring(stats.Race or "") == "Curse" then
		return false
	end
	return stats.CurseRebirthEligible == true
		or (tonumber(stats.CursedResentment) or 0) >= 100
		or (tonumber(stats.CursedObjectAnchors) or 0) >= 1
		or tostring(stats.ReincarnationAnchor or "None") ~= "None"
end

local function init(playerGui: Instance)
	local updateLifeEvent = ReplicatedStorage:WaitForChild("UpdateLifeEvent")
	local testPurchase = ReplicatedStorage:WaitForChild("TestPurchase")
	local getSuccessorOptions = ReplicatedStorage:WaitForChild("GetSuccessorOptions")
	local chooseSuccessor = ReplicatedStorage:WaitForChild("ChooseSuccessor")

	local gui = Instance.new("ScreenGui")
	gui.Name = "BitKaisenMobileDeathGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 670
	gui.Enabled = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	-- Full-screen overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "DeathOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.Visible = false
	overlay.ZIndex = 900
	overlay.Parent = gui

	-- Main death sheet (portrait-friendly full-screen scroll)
	local sheet = Instance.new("Frame")
	sheet.Name = "DeathSheet"
	sheet.Size = UDim2.fromScale(1, 1)
	sheet.BackgroundColor3 = theme.Bg
	sheet.BackgroundTransparency = 1
	sheet.BorderSizePixel = 0
	sheet.Visible = false
	sheet.ZIndex = 901
	sheet.Parent = overlay

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Content"
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 35, 35)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ZIndex = 902
	scroll.Parent = sheet

	local scrollPad = Instance.new("UIPadding")
	scrollPad.PaddingTop = UDim.new(0, 50)
	scrollPad.PaddingBottom = UDim.new(0, 40)
	scrollPad.PaddingLeft = UDim.new(0, 16)
	scrollPad.PaddingRight = UDim.new(0, 16)
	scrollPad.Parent = scroll

	local scrollLayout = Instance.new("UIListLayout")
	scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
	scrollLayout.Padding = UDim.new(0, 12)
	scrollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	scrollLayout.Parent = scroll

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 36)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = _dt("title", "LIFE ENDED")
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 26
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.LayoutOrder = 1
	titleLabel.ZIndex = 903
	titleLabel.Parent = scroll

	-- Subtitle
	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "Subtitle"
	subtitleLabel.Size = UDim2.new(1, 0, 0, 20)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = _dt("subtitle", "Your story has reached its end.")
	subtitleLabel.TextColor3 = theme.SubText
	subtitleLabel.TextSize = 12
	subtitleLabel.Font = Enum.Font.GothamBold
	subtitleLabel.TextXAlignment = Enum.TextXAlignment.Center
	subtitleLabel.LayoutOrder = 2
	subtitleLabel.ZIndex = 903
	subtitleLabel.Parent = scroll

	-- Cause of death
	local causeLabel = Instance.new("TextLabel")
	causeLabel.Name = "CauseOfDeathLabel"
	causeLabel.Size = UDim2.new(1, 0, 0, 18)
	causeLabel.BackgroundTransparency = 1
	causeLabel.Text = ""
	causeLabel.TextColor3 = Color3.fromRGB(220, 100, 100)
	causeLabel.TextSize = 11
	causeLabel.Font = Enum.Font.GothamBold
	causeLabel.TextXAlignment = Enum.TextXAlignment.Center
	causeLabel.LayoutOrder = 3
	causeLabel.ZIndex = 903
	causeLabel.Visible = false
	causeLabel.Parent = scroll

	-- Ribbon
	local ribbonLabel = Instance.new("TextLabel")
	ribbonLabel.Name = "RibbonLabel"
	ribbonLabel.Size = UDim2.new(1, 0, 0, 52)
	ribbonLabel.TextWrapped = true
	ribbonLabel.BackgroundTransparency = 1
	ribbonLabel.Text = ""
	ribbonLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
	ribbonLabel.TextSize = 13
	ribbonLabel.Font = Enum.Font.GothamBlack
	ribbonLabel.TextXAlignment = Enum.TextXAlignment.Center
	ribbonLabel.LayoutOrder = 4
	ribbonLabel.ZIndex = 903
	ribbonLabel.Parent = scroll

	-- Biography card
	local bioCard = mc.mobileCard({
		parent = scroll,
		color = Color3.fromRGB(18, 18, 26),
		accentColor = Color3.fromRGB(120, 35, 35),
		order = 4,
	})

	local biographyLabel = Instance.new("TextLabel")
	biographyLabel.Name = "BioText"
	biographyLabel.Size = UDim2.new(1, 0, 0, 0)
	biographyLabel.AutomaticSize = Enum.AutomaticSize.Y
	biographyLabel.BackgroundTransparency = 1
	biographyLabel.TextColor3 = Color3.fromRGB(215, 215, 225)
	biographyLabel.TextSize = 13
	biographyLabel.Font = Enum.Font.GothamMedium
	biographyLabel.TextWrapped = true
	biographyLabel.RichText = true
	biographyLabel.TextXAlignment = Enum.TextXAlignment.Left
	biographyLabel.TextYAlignment = Enum.TextYAlignment.Top
	biographyLabel.Text = ""
	biographyLabel.LayoutOrder = 1
	biographyLabel.ZIndex = 904
	biographyLabel.Parent = bioCard

	-- Stats line
	local statsLabel = Instance.new("TextLabel")
	statsLabel.Name = "Stats"
	statsLabel.Size = UDim2.new(1, 0, 0, 0)
	statsLabel.AutomaticSize = Enum.AutomaticSize.Y
	statsLabel.BackgroundTransparency = 1
	statsLabel.TextColor3 = theme.Muted
	statsLabel.TextSize = 11
	statsLabel.Font = Enum.Font.GothamBold
	statsLabel.TextWrapped = true
	statsLabel.TextXAlignment = Enum.TextXAlignment.Center
	statsLabel.Text = ""
	statsLabel.LayoutOrder = 5
	statsLabel.ZIndex = 903
	statsLabel.Parent = scroll

	-- Action buttons container
	local actionsFrame = Instance.new("Frame")
	actionsFrame.Name = "Actions"
	actionsFrame.Size = UDim2.new(1, 0, 0, 0)
	actionsFrame.AutomaticSize = Enum.AutomaticSize.Y
	actionsFrame.BackgroundTransparency = 1
	actionsFrame.LayoutOrder = 6
	actionsFrame.ZIndex = 903
	actionsFrame.Parent = scroll

	local actionsLayout = Instance.new("UIListLayout")
	actionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	actionsLayout.Padding = UDim.new(0, 10)
	actionsLayout.Parent = actionsFrame

	-- New Life button
	local newLifeBtn = mc.mobileButton({
		parent = actionsFrame,
		text = _dt("start_new_life", "START NEW LIFE"),
		size = UDim2.new(1, 0, 0, 48),
		position = UDim2.new(0, 0, 0, 0),
		color = Color3.fromRGB(120, 35, 35),
		textSize = 14,
		order = 1,
		callback = function() end,
	})

	-- Successor button
	local successorBtn = mc.mobileButton({
		parent = actionsFrame,
		text = _dt("play_as_child", "PLAY AS CHILD"),
		size = UDim2.new(1, 0, 0, 48),
		position = UDim2.new(0, 0, 0, 0),
		color = Color3.fromRGB(95, 55, 150),
		textSize = 14,
		order = 2,
		callback = function() end,
	})

	local successorHint = Instance.new("TextLabel")
	successorHint.Size = UDim2.new(1, 0, 0, 16)
	successorHint.BackgroundTransparency = 1
	successorHint.TextColor3 = Color3.fromRGB(180, 150, 220)
	successorHint.TextSize = 10
	successorHint.Font = Enum.Font.GothamMedium
	successorHint.Text = _dt("successor_hint", "Inherit assets, clan, technique, money.")
	successorHint.TextWrapped = true
	successorHint.TextXAlignment = Enum.TextXAlignment.Center
	successorHint.LayoutOrder = 3
	successorHint.Parent = actionsFrame

	-- RCT Revive button
	local rctBtn = mc.mobileButton({
		parent = actionsFrame,
		text = _dt("rct_revive", "RCT REVIVE — R$50"),
		size = UDim2.new(1, 0, 0, 44),
		position = UDim2.new(0, 0, 0, 0),
		color = Color3.fromRGB(55, 35, 120),
		textSize = 13,
		order = 4,
		callback = function() end,
	})

	local rctHint = Instance.new("TextLabel")
	rctHint.Size = UDim2.new(1, 0, 0, 16)
	rctHint.BackgroundTransparency = 1
	rctHint.TextColor3 = Color3.fromRGB(190, 175, 255)
	rctHint.TextSize = 10
	rctHint.Font = Enum.Font.GothamMedium
	rctHint.Text = _dt("rct_hint", "Reverse cursed energy pulls you back. Can be used twice per life.")
	rctHint.TextWrapped = true
	rctHint.TextXAlignment = Enum.TextXAlignment.Center
	rctHint.LayoutOrder = 5
	rctHint.Parent = actionsFrame

	-- Curse Rebirth button (conditionally visible)
	local curseBtn = mc.mobileButton({
		parent = actionsFrame,
		text = _dt("become_spirit", "BECOME VENGEFUL SPIRIT"),
		size = UDim2.new(1, 0, 0, 44),
		position = UDim2.new(0, 0, 0, 0),
		color = Color3.fromRGB(110, 45, 160),
		textSize = 13,
		order = 6,
		callback = function() end,
	})
	curseBtn.Visible = false

	local curseHint = Instance.new("TextLabel")
	curseHint.Size = UDim2.new(1, 0, 0, 16)
	curseHint.BackgroundTransparency = 1
	curseHint.TextColor3 = Color3.fromRGB(205, 170, 245)
	curseHint.TextSize = 10
	curseHint.Font = Enum.Font.GothamMedium
	curseHint.Text = _dt("spirit_hint", "Your cursed energy refused to disappear. Return as a reborn cursed spirit.")
	curseHint.TextWrapped = true
	curseHint.TextXAlignment = Enum.TextXAlignment.Center
	curseHint.LayoutOrder = 7
	curseHint.Visible = false
	curseHint.Parent = actionsFrame

	-- Reincarnate button (conditionally visible)
	local reincarnateBtn = mc.mobileButton({
		parent = actionsFrame,
		text = _dt("reincarnate", "REINCARNATE"),
		size = UDim2.new(1, 0, 0, 44),
		position = UDim2.new(0, 0, 0, 0),
		color = Color3.fromRGB(75, 70, 170),
		textSize = 13,
		order = 8,
		callback = function() end,
	})
	reincarnateBtn.Visible = false

	local reincarnateHint = Instance.new("TextLabel")
	reincarnateHint.Size = UDim2.new(1, 0, 0, 16)
	reincarnateHint.BackgroundTransparency = 1
	reincarnateHint.TextColor3 = Color3.fromRGB(190, 190, 255)
	reincarnateHint.TextSize = 10
	reincarnateHint.Font = Enum.Font.GothamMedium
	reincarnateHint.Text = _dt("reincarnate_hint", "A cursed-object anchor pulls your soul into a new life keeping CE, clan, and technique.")
	reincarnateHint.TextWrapped = true
	reincarnateHint.TextXAlignment = Enum.TextXAlignment.Center
	reincarnateHint.LayoutOrder = 9
	reincarnateHint.Visible = false
	reincarnateHint.Parent = actionsFrame

	-- Successor Picker (full-screen sheet)
	local pickerSheet = Instance.new("Frame")
	pickerSheet.Name = "SuccessorPicker"
	pickerSheet.Size = UDim2.fromScale(1, 1)
	pickerSheet.BackgroundColor3 = theme.Bg
	pickerSheet.BackgroundTransparency = 1
	pickerSheet.BorderSizePixel = 0
	pickerSheet.Visible = false
	pickerSheet.ZIndex = 950
	pickerSheet.Parent = gui

	local pickerHeader = mc.mobileHeader(pickerSheet, _dt("choose_successor", "CHOOSE SUCCESSOR"), function() end)
	pickerHeader.ZIndex = 952

	local pickerScroll = Instance.new("ScrollingFrame")
	pickerScroll.Name = "PickerScroll"
	pickerScroll.Size = UDim2.new(1, 0, 1, -56)
	pickerScroll.Position = UDim2.new(0, 0, 0, 56)
	pickerScroll.BackgroundTransparency = 1
	pickerScroll.BorderSizePixel = 0
	pickerScroll.ScrollBarThickness = 3
	pickerScroll.ScrollBarImageColor3 = Color3.fromRGB(95, 55, 150)
	pickerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	pickerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	pickerScroll.ZIndex = 952
	pickerScroll.Parent = pickerSheet

	local pickerPad = Instance.new("UIPadding")
	pickerPad.PaddingTop = UDim.new(0, 10)
	pickerPad.PaddingBottom = UDim.new(0, 24)
	pickerPad.PaddingLeft = UDim.new(0, 14)
	pickerPad.PaddingRight = UDim.new(0, 14)
	pickerPad.Parent = pickerScroll

	local pickerLayout = Instance.new("UIListLayout")
	pickerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pickerLayout.Padding = UDim.new(0, 10)
	pickerLayout.Parent = pickerScroll

	-- State
	local isShowingDeath = false
	local isShowingPicker = false
	local pickerBusy = false
	local lastDeathStats = nil

	local function updateRCTButton(stats)
		local uses = getRCTReviveUses(stats)
		local remaining = math.max(0, RCT_REVIVE_MAX_PER_LIFE - uses)

		if remaining <= 0 then
			rctBtn.Text = _dt("rct_limit_reached", "RCT REVIVE LIMIT REACHED")
			rctBtn.Active = false
			rctBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
			rctHint.Text = _dt("rct_hint_used", "Your body has already survived through RCT twice in this life.")
			rctHint.TextColor3 = Color3.fromRGB(155, 155, 170)
		else
			rctBtn.Text = _dt("rct_left", "RCT REVIVE — R$50  ({remaining}/{max} LEFT)")
				:gsub("{remaining}", tostring(remaining)):gsub("{max}", tostring(RCT_REVIVE_MAX_PER_LIFE))
			rctBtn.Active = true
			rctBtn.BackgroundColor3 = Color3.fromRGB(55, 35, 120)
			rctHint.Text = _dt("rct_hint", "Reverse cursed energy pulls you back. Can be used twice per life.")
			rctHint.TextColor3 = Color3.fromRGB(190, 175, 255)
		end
	end

	local function clearPickerCards()
		for _, child in ipairs(pickerScroll:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
	end

	local function createSuccessorCard(successor)
		local card = mc.mobileCard({
			parent = pickerScroll,
			color = Color3.fromRGB(22, 20, 35),
			accentColor = Color3.fromRGB(75, 55, 120),
		})

		mc.mobileLabel({
			parent = card,
			text = tostring(successor.Name or "Unknown Child"),
			size = 15,
			font = Enum.Font.GothamBlack,
			color = Color3.fromRGB(235, 235, 245),
			order = 1,
		})

		mc.mobileLabel({
			parent = card,
			text = _dt("age_ce", "Age: {age}  •  CE: {ce}"):gsub("{age}", tostring(successor.Age or 0)):gsub("{ce}", tostring(successor.CursedEnergy or 0)),
			size = 12,
			color = Color3.fromRGB(160, 160, 180),
			order = 2,
		})

		local techText, techColor
		if successor.HasInheritedTechnique then
			techText = _dt("tech_inherited", "Inherited: <b>{tech}</b> — starts as sorcerer"):gsub("{tech}", tostring(successor.CursedTechnique))
			techColor = Color3.fromRGB(255, 200, 90)
		else
			techText = _dt("tech_none", "No technique inherited yet. May still awaken.")
			techColor = Color3.fromRGB(150, 150, 165)
		end

		mc.mobileLabel({
			parent = card,
			text = techText,
			size = 11,
			color = techColor,
			order = 3,
		})

		mc.mobileButton({
			parent = card,
			text = _dt("continue_as", "CONTINUE AS"),
			size = UDim2.new(1, 0, 0, 40),
			color = Color3.fromRGB(95, 55, 150),
			textSize = 12,
			order = 4,
			callback = function()
				if pickerBusy then
					return
				end
				pickerBusy = true
				chooseSuccessor:FireServer(successor.Id)
			end,
		})
	end

	local function showPicker()
		if isShowingPicker then
			return
		end
		isShowingPicker = true
		pickerBusy = false
		clearPickerCards()

		local ok, successors = pcall(function()
			return getSuccessorOptions:InvokeServer()
		end)

		if not ok or typeof(successors) ~= "table" or #successors <= 0 then
			local emptyCard = mc.mobileCard({
				parent = pickerScroll,
				color = Color3.fromRGB(20, 20, 30),
				accentColor = Color3.fromRGB(60, 45, 90),
			})
			mc.mobileLabel({
				parent = emptyCard,
				text = if not ok then _dt("successor_error", "Could not load successor options.") else _dt("no_successor", "No eligible children to continue your bloodline."),
				size = 14,
				font = Enum.Font.GothamBold,
				color = Color3.fromRGB(190, 180, 220),
			})
		else
			for _, successor in ipairs(successors) do
				createSuccessorCard(successor)
			end
		end

		pickerSheet.Visible = true
		pickerSheet.BackgroundTransparency = 1
		TweenService:Create(pickerSheet, TweenInfo.new(0.22), { BackgroundTransparency = 0 }):Play()
	end

	local function hidePicker()
		if not isShowingPicker then
			return
		end
		isShowingPicker = false

		local tween = TweenService:Create(pickerSheet, TweenInfo.new(0.18), { BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		pickerSheet.Visible = false
	end

	local function showDeathScreen(stats)
		if isShowingDeath then
			return
		end
		isShowingDeath = true
		lastDeathStats = stats
		if _G.BitKaisenPlaySFX then _G.BitKaisenPlaySFX("Death") end

		biographyLabel.Text = buildBiography(stats)

		local cause = tostring(stats.CauseOfDeath or stats.DeathReason or "")
		causeLabel.Text = cause ~= "" and (_dt("cause_of_death", "Cause of death: ") .. cause) or ""
		causeLabel.Visible = cause ~= ""

		local ribbonText, ribbonColor = getRibbon(stats)
		local karma = tonumber(stats.HiddenKarma) or 0
		local karmaLabel = ""
		if karma >= 60 then
			karmaLabel = _dt("karma_high", "\n✦ The cursed world remembers your light.")
		elseif karma >= 20 then
			karmaLabel = _dt("karma_ok", "\n✦ You left the world a little better.")
		elseif karma <= -60 then
			karmaLabel = _dt("karma_bad", "\n✦ Darkness followed you everywhere.")
		elseif karma <= -20 then
			karmaLabel = _dt("karma_low", "\n✦ The weight of your choices lingered.")
		end
		ribbonLabel.Text = ribbonText .. karmaLabel
		ribbonLabel.TextColor3 = ribbonColor

		statsLabel.Text = _dt("stats_line", "Age {age}  •  Grade: {grade}  •  CE: {ce}\nResentment: {resentment}  •  Money: ${money}")
			:gsub("{age}", tostring(stats.Age or 0)):gsub("{grade}", tostring(stats.Grade or "?"))
			:gsub("{ce}", tostring(stats.CursedEnergy or 0)):gsub("{resentment}", tostring(stats.CursedResentment or 0))
			:gsub("{money}", formatMoneyAmount(stats.Money or 0))

		updateRCTButton(stats)

		local reincarnationUnlocked = canShowReincarnation(stats)
		local curseUnlocked = canShowCurseRebirth(stats) and not reincarnationUnlocked
		reincarnateBtn.Visible = reincarnationUnlocked
		reincarnateHint.Visible = reincarnationUnlocked
		curseBtn.Visible = curseUnlocked
		curseHint.Visible = curseUnlocked

		gui.Enabled = true
		overlay.Visible = true
		sheet.Visible = true
		overlay.BackgroundTransparency = 1
		sheet.BackgroundTransparency = 1

		TweenService:Create(overlay, TweenInfo.new(0.25), { BackgroundTransparency = 0.45 }):Play()
		TweenService:Create(sheet, TWEEN_SLIDE, { BackgroundTransparency = 0 }):Play()
	end

	local function hideDeathScreen()
		isShowingDeath = false

		TweenService:Create(overlay, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
		local tween = TweenService:Create(sheet, TweenInfo.new(0.18), { BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()

		sheet.Visible = false
		overlay.Visible = false
		gui.Enabled = false
	end

	-- Wire close button on picker header
	for _, child in ipairs(pickerHeader:GetChildren()) do
		if child:IsA("TextButton") then
			bindTap(child, function()
				hidePicker()
			end)
			break
		end
	end

	-- Button actions
	bindTap(newLifeBtn, function()
		newLifeBtn.Text = _dt("starting", "STARTING...")
		updateLifeEvent:FireServer("StartNewLife")
		task.delay(0.25, function()
			hideDeathScreen()
			newLifeBtn.Text = _dt("start_new_life", "START NEW LIFE")
		end)
	end)

	bindTap(successorBtn, function()
		showPicker()
	end)

	bindTap(rctBtn, function()
		if getRCTReviveUses(lastDeathStats) >= RCT_REVIVE_MAX_PER_LIFE then
			updateRCTButton(lastDeathStats)
			return
		end

		rctBtn.Text = _dt("opening_purchase", "OPENING PURCHASE...")
		rctBtn.Active = false

		if game.PlaceId == TEST_PURCHASE_PLACE_ID then
			testPurchase:FireServer("DeveloperProduct", RCT_REVIVE_PRODUCT_ID)
		else
			MarketplaceService:PromptProductPurchase(player, RCT_REVIVE_PRODUCT_ID)
		end

		task.delay(1.25, function()
			if rctBtn and rctBtn.Parent then
				updateRCTButton(lastDeathStats)
			end
		end)
	end)

	bindTap(curseBtn, function()
		curseBtn.Text = _dt("rebirthing", "REBIRTHING...")
		updateLifeEvent:FireServer("BecomeVengefulSpirit")
		task.delay(0.45, function()
			curseBtn.Text = _dt("become_spirit", "BECOME VENGEFUL SPIRIT")
		end)
	end)

	bindTap(reincarnateBtn, function()
		reincarnateBtn.Text = _dt("reincarnating", "REINCARNATING...")
		updateLifeEvent:FireServer("Reincarnate")
		task.delay(0.45, function()
			reincarnateBtn.Text = _dt("reincarnate", "REINCARNATE")
		end)
	end)

	-- Listen for death/alive events (same remote as PC panel)
	updateLifeEvent.OnClientEvent:Connect(function(stats, _message)
		if typeof(stats) ~= "table" then
			return
		end

		if stats.Alive == false then
			task.defer(function()
				if isShowingPicker then
					hidePicker()
				end
				showDeathScreen(stats)
			end)
		else
			if isShowingDeath then
				task.defer(function()
					hideDeathScreen()
				end)
			end
			if isShowingPicker then
				task.defer(function()
					hidePicker()
				end)
			end
		end
	end)
end

return { init = init }
