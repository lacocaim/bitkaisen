local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local mc = require("@ui/mobile/mobileComponents")
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local theme = mc.theme
local bindTap = mc.bindTap

local L = BitKaisenLocale.getClientLocale()
local function _cc(key, fallback) return BitKaisenLocale.tOrFallback(L, "customization." .. key, nil, fallback) end

local FIELD_LABEL_KEYS = {
	FirstName = "field_name", Gender = "field_gender", HairColor = "field_hair",
	EyeColor = "field_eyes", SkinTone = "field_skin", Height = "field_height",
	Build = "field_build", Feature = "field_feature", AuraColor = "field_ce_color",
	OriginLocation = "field_origin", Era = "field_era", Upbringing = "field_upbringing",
	EarlyCurseExposure = "field_curse_exp", Temperament = "field_temperament",
	LifeGoal = "field_goal", BirthYear = "field_birth_year",
}
local function _fieldLabel(key, fallback)
	local k = FIELD_LABEL_KEYS[key]
	return k and _cc(k, fallback) or fallback
end

local player = Players.LocalPlayer

local GOD_MODE_GAMEPASS_ID = 1861509054

local FIRST_LOAD_POPUP_DELAY = 1.05
local NORMAL_POPUP_DELAY = 0.45

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SLIDE = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local OPTIONS = {
	Gender = { "Male", "Female" },

	HairColor = {
		"Black", "Brown", "Dark Brown", "Blonde", "White", "Silver",
		"Red", "Blue-Black", "Ash Gray", "Pink", "Purple", "Green", "Blue", "Orange",
	},

	EyeColor = {
		"Brown", "Black", "Blue", "Green", "Gray", "Gold",
		"Violet", "Red", "Hazel", "Silver",
	},

	SkinTone = {
		"Pale", "Fair", "Light Tan", "Tan", "Brown", "Dark",
	},

	Height = {
		"Short", "Below Average", "Average", "Above Average", "Tall",
	},

	Build = {
		"Slim", "Lean", "Average", "Athletic", "Muscular",
	},

	Feature = {
		"None", "Sharp Eyes", "Tired Eyes", "Beauty Mark", "Scar Under Eye",
		"Burn Mark", "Cold Expression", "Gentle Expression", "Resting Scowl",
	},

	AuraColor = {
		"Blue", "Red", "Purple", "Black", "White", "Gold", "Green", "Silver",
		"Cyan", "Crimson", "Indigo", "Violet", "Ash Gray", "Pale Blue",
		"Deep Red", "Emerald", "Rose", "Amber",
	},

	OriginLocation = {
		"Tokyo", "Kyoto", "Osaka", "Sendai", "Yokohama", "Sapporo",
		"Nagoya", "Fukuoka", "Kobe", "Nara", "Okinawa", "Shibuya",
		"Shinjuku", "Roppongi", "Akihabara", "Ikebukuro", "Ueno",
		"Kamakura", "Yokosuka", "Chiba", "Saitama", "Kawasaki",
		"Hiroshima", "Nagasaki", "Kumamoto", "Kagoshima", "Kanazawa",
		"Niigata", "Nagano", "Hakone", "Aomori", "Kurashiki",
		"Matsuyama", "Miyazaki", "Beppu", "Tsukuba", "Ise", "Koyasan",
		"Hokkaido Countryside", "Kyoto Outskirts", "Tokyo Outskirts",
		"Unnamed Rural Village",
	},

	Era = {
		"Modern Era", "Edo Era", "Heian Era", "Collapse Era",
	},

	Upbringing = {
		"Normal Household", "Sorcerer Household", "Strict Clan Home",
		"Orphaned", "Shrine Raised", "Street Kid", "Rural Family",
		"Hidden Bloodline",
	},

	EarlyCurseExposure = {
		"Low", "Moderate", "High", "Traumatic",
	},

	Temperament = {
		"Calm", "Ambitious", "Reckless", "Kind", "Cold", "Proud",
		"Curious", "Stoic",
	},

	LifeGoal = {
		"Peace", "Power", "Family", "Revenge", "Recognition", "Freedom",
		"Mastery", "Control",
	},
}

local DEFAULTS = {
	FirstName = "Ren",
	Gender = "Male",
	HairColor = "Black",
	EyeColor = "Brown",
	SkinTone = "Fair",
	Height = "Average",
	Build = "Lean",
	Feature = "None",
	AuraColor = "Blue",
	OriginLocation = "Tokyo",
	Era = "Modern Era",
	Upbringing = "Normal Household",
	EarlyCurseExposure = "Moderate",
	Temperament = "Calm",
	LifeGoal = "Peace",
	BirthYear = "",
}

local ERA_START_YEARS = {
	["Modern Era"] = 2000,
	["Edo Era"] = 1603,
	["Heian Era"] = 794,
	["Collapse Era"] = 2018,
}

local PAGE1_FIELDS = {
	{ Key = "FirstName", Label = "Name", Description = "" },
	{ Key = "Gender", Label = "Gender", Description = "" },
	{ Key = "HairColor", Label = "Hair", Description = "" },
	{ Key = "EyeColor", Label = "Eyes", Description = "" },
	{ Key = "SkinTone", Label = "Skin", Description = "" },
	{ Key = "Height", Label = "Height", Description = "" },
	{ Key = "Build", Label = "Build", Description = "" },
	{ Key = "Feature", Label = "Feature", Description = "" },
	{ Key = "AuraColor", Label = "CE Color", Description = "" },
	{ Key = "OriginLocation", Label = "Origin", Description = "" },
}

local PAGE2_FIELDS = {
	{ Key = "Era", Label = "Era", Description = "Time period this life begins in.", LockedByGodMode = false },
	{ Key = "Upbringing", Label = "Upbringing", Description = "The home or environment that shaped you.", LockedByGodMode = false },
	{ Key = "EarlyCurseExposure", Label = "Curse Exposure", Description = "How early cursed energy touched your life.", LockedByGodMode = true },
	{ Key = "Temperament", Label = "Temperament", Description = "Your starting personality direction.", LockedByGodMode = true },
	{ Key = "LifeGoal", Label = "Goal", Description = "What this life is chasing first.", LockedByGodMode = true },
	{ Key = "BirthYear", Label = "Birth Year", Description = "Optional exact start year. Era updates from the year.", LockedByGodMode = true },
}

local MALE_NAMES = {
	"Ren", "Akio", "Daiki", "Haruto", "Kaito", "Riku", "Sora", "Toma", "Yuto", "Itsuki",
	"Shin", "Rei", "Niko", "Tatsu", "Hiro", "Masaru", "Ryo", "Kenshi", "Kei", "Kazuki",
	"Naoki", "Hayate", "Kiyoshi", "Isamu", "Koga", "Touya", "Makoto", "Arata", "Jin",
}

local FEMALE_NAMES = {
	"Mizuki", "Airi", "Hana", "Yuna", "Kira", "Emi", "Saki", "Rina", "Aya", "Mei",
	"Kana", "Aiko", "Reina", "Mira", "Yuki", "Amane", "Koharu", "Hikari", "Natsuki",
	"Kaede", "Saya", "Yua", "Shiori", "Miyu", "Rikka", "Kanna", "Tomoe",
}

-----------------------------------------------------------------------
-- State
-----------------------------------------------------------------------

local state = {}
local lockedIdentityState = nil
local lockedRolledIdentityState = nil
local currentStats = nil
local currentPage = 1
local isOpen = false
local submitting = false
local lastOpenLifeKey = nil
local hasSeenAnyLifeUpdate = false
local pendingOpenToken = 0
local ownsGodMode = false
local checkedGodMode = false

-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------

local function cleanText(text)
	text = tostring(text or "")
	text = text:gsub("<[^>]->", "")
	text = text:gsub("[\n\r\t]", " ")
	text = text:gsub("^%s+", "")
	text = text:gsub("%s+$", "")
	return text
end

local function isAllowed(key, value)
	local list = OPTIONS[key]
	if not list then return false end
	for _, option in ipairs(list) do
		if option == value then return true end
	end
	return false
end

local function firstAllowed(key)
	local list = OPTIONS[key]
	return list and list[1] or ""
end

local function pickRandom(list)
	return list[math.random(1, #list)]
end

local function getLifeKey(stats)
	if not stats then return "nil" end
	return table.concat({
		tostring(stats.__SlotId or stats.SlotId or "slot"),
		tostring(stats.Generation or 1),
		tostring(stats.Name or "Unknown"),
		tostring(stats.Age or 0),
		tostring(stats.Alive ~= false),
	}, "|")
end

local function checkGodMode()
	if typeof(currentStats) == "table" and (currentStats.HasGodModePass == true or currentStats.GodModeUnlocked == true) then
		ownsGodMode = true
		checkedGodMode = true
		return true
	end

	if checkedGodMode then return ownsGodMode end

	checkedGodMode = true
	ownsGodMode = false

	if not GOD_MODE_GAMEPASS_ID or GOD_MODE_GAMEPASS_ID <= 0 then return false end

	local ok, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GOD_MODE_GAMEPASS_ID)
	end)

	if ok and result == true then
		ownsGodMode = true
	end

	return ownsGodMode
end

local function getStatsFirstName(stats)
	local firstName = cleanText(stats and stats.FirstName or "")
	if firstName ~= "" and firstName ~= "Unknown" then return firstName end

	local fullName = cleanText(stats and stats.Name or "")
	local familyName = cleanText(stats and stats.FamilyName or "")
	if fullName ~= "" and fullName ~= "Unknown" then
		if familyName ~= "" and familyName ~= "Unknown" then
			local suffix = " " .. familyName
			if string.sub(fullName, -#suffix) == suffix then
				fullName = string.sub(fullName, 1, #fullName - #suffix)
			end
		end
		local firstWord = string.match(fullName, "^(%S+)")
		return cleanText(firstWord or fullName)
	end

	return DEFAULTS.FirstName
end

local function captureRolledIdentity(stats)
	lockedRolledIdentityState = {
		FamilyName = tostring(stats and stats.FamilyName or ""),
		Clan = tostring(stats and stats.Clan or ""),
		Origin = tostring(stats and stats.Origin or ""),
		OriginCategory = tostring(stats and stats.OriginCategory or ""),
	}
end

local function readStatsDefaults(stats)
	local appearance = typeof(stats and stats.Appearance) == "table" and stats.Appearance or {}
	local birthPath = typeof(stats and stats.BirthPath) == "table" and stats.BirthPath or {}

	state.FirstName = getStatsFirstName(stats)
	if state.FirstName == "" or state.FirstName == "Unknown" then
		state.FirstName = DEFAULTS.FirstName
	end

	state.Gender = tostring(stats and stats.Gender or DEFAULTS.Gender)
	if not isAllowed("Gender", state.Gender) then
		state.Gender = DEFAULTS.Gender
	end

	for _, field in ipairs(PAGE1_FIELDS) do
		if field.Key ~= "Gender" and field.Key ~= "FirstName" then
			local value = tostring(appearance[field.Key] or stats and stats[field.Key] or DEFAULTS[field.Key])
			if not isAllowed(field.Key, value) then
				value = DEFAULTS[field.Key]
			end
			state[field.Key] = value
		end
	end

	for _, field in ipairs(PAGE2_FIELDS) do
		local value = tostring(birthPath[field.Key] or stats and stats[field.Key] or DEFAULTS[field.Key])
		if not isAllowed(field.Key, value) then
			value = DEFAULTS[field.Key]
		end
		state[field.Key] = value
	end
end

local function randomizeIdentity()
	state.Gender = pickRandom(OPTIONS.Gender)
	state.FirstName = pickRandom(state.Gender == "Female" and FEMALE_NAMES or MALE_NAMES)

	for _, field in ipairs(PAGE1_FIELDS) do
		if field.Key ~= "Gender" and field.Key ~= "FirstName" then
			state[field.Key] = pickRandom(OPTIONS[field.Key])
		end
	end
end

local function randomizeBirthPath()
	for _, field in ipairs(PAGE2_FIELDS) do
		if not OPTIONS[field.Key] then continue end
		if field.LockedByGodMode and not checkGodMode() then
			state[field.Key] = DEFAULTS[field.Key]
		else
			state[field.Key] = pickRandom(OPTIONS[field.Key])
		end
	end
end

local function cycleOption(field, direction)
	if field.LockedByGodMode and not checkGodMode() then return end

	local key = field.Key
	local list = OPTIONS[key]
	if not list then return end

	local current = state[key]
	local index = 1

	for i, option in ipairs(list) do
		if option == current then
			index = i
			break
		end
	end

	index += direction
	if index > #list then
		index = 1
	elseif index < 1 then
		index = #list
	end

	state[key] = list[index]
end

local function getDisplayFullName()
	local first = cleanText(state.FirstName)
	if first == "" then first = DEFAULTS.FirstName end

	local family = tostring(
		(lockedRolledIdentityState and lockedRolledIdentityState.FamilyName)
		or (currentStats and currentStats.FamilyName)
		or ""
	)
	if family == "" or family == "Unknown" or family == "None" then
		return first
	end

	return first .. " " .. family
end

local function getSelectedEraStartYear()
	return ERA_START_YEARS[tostring(state.Era or DEFAULTS.Era)] or ERA_START_YEARS[DEFAULTS.Era] or 2000
end

-----------------------------------------------------------------------
-- Init
-----------------------------------------------------------------------

local function init(playerGui: Instance)
	local updateLifeEvent = ReplicatedStorage:WaitForChild("UpdateLifeEvent")
	local submitRemote = ReplicatedStorage:WaitForChild("SubmitCharacterCustomization")

	local gui = Instance.new("ScreenGui")
	gui.Name = "BitKaisenMobileCharacterCustomizationGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 650
	gui.Enabled = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local overlay = Instance.new("Frame")
	overlay.Name = "CustomizationOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.Visible = false
	overlay.ZIndex = 800
	overlay.Parent = gui

	local sheet = Instance.new("Frame")
	sheet.Name = "CustomizationSheet"
	sheet.Size = UDim2.fromScale(1, 1)
	sheet.BackgroundColor3 = theme.Bg
	sheet.BackgroundTransparency = 1
	sheet.BorderSizePixel = 0
	sheet.Visible = false
	sheet.ZIndex = 801
	sheet.Parent = overlay

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 56)
	header.BackgroundColor3 = theme.Panel
	header.BorderSizePixel = 0
	header.ZIndex = 810
	header.Parent = sheet
	mc.corner(header, 0)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -80, 0, 24)
	titleLabel.Position = UDim2.new(0, 16, 0, 6)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = _cc("create_title", "CREATE CHARACTER")
	titleLabel.TextColor3 = theme.Gold
	titleLabel.TextSize = 17
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 812
	titleLabel.Parent = header

	local pageLabel = Instance.new("TextLabel")
	pageLabel.Size = UDim2.new(1, -80, 0, 16)
	pageLabel.Position = UDim2.new(0, 16, 0, 32)
	pageLabel.BackgroundTransparency = 1
	pageLabel.Text = _cc("page1_sub", "Page 1/2 • Identity")
	pageLabel.TextColor3 = theme.Muted
	pageLabel.TextSize = 10
	pageLabel.Font = Enum.Font.GothamBold
	pageLabel.TextXAlignment = Enum.TextXAlignment.Left
	pageLabel.ZIndex = 812
	pageLabel.Parent = header

	-- Scrollable content area
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Content"
	scroll.Size = UDim2.new(1, 0, 1, -56 - 70)
	scroll.Position = UDim2.new(0, 0, 0, 56)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = theme.Stroke
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ZIndex = 802
	scroll.Parent = sheet

	local scrollPad = Instance.new("UIPadding")
	scrollPad.PaddingTop = UDim.new(0, 12)
	scrollPad.PaddingBottom = UDim.new(0, 20)
	scrollPad.PaddingLeft = UDim.new(0, 14)
	scrollPad.PaddingRight = UDim.new(0, 14)
	scrollPad.Parent = scroll

	local scrollLayout = Instance.new("UIListLayout")
	scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
	scrollLayout.Padding = UDim.new(0, 10)
	scrollLayout.Parent = scroll

	-- Bottom action bar
	local bottomBar = Instance.new("Frame")
	bottomBar.Name = "BottomBar"
	bottomBar.Size = UDim2.new(1, 0, 0, 70)
	bottomBar.Position = UDim2.new(0, 0, 1, -70)
	bottomBar.BackgroundColor3 = theme.Panel
	bottomBar.BorderSizePixel = 0
	bottomBar.ZIndex = 810
	bottomBar.Parent = sheet

	local bottomLine = Instance.new("Frame")
	bottomLine.Size = UDim2.new(1, 0, 0, 1)
	bottomLine.BackgroundColor3 = theme.Stroke
	bottomLine.BorderSizePixel = 0
	bottomLine.ZIndex = 811
	bottomLine.Parent = bottomBar

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -20, 0, 14)
	statusLabel.Position = UDim2.new(0, 10, 0, 3)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = ""
	statusLabel.TextColor3 = theme.Gold
	statusLabel.TextSize = 10
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextWrapped = true
	statusLabel.TextXAlignment = Enum.TextXAlignment.Center
	statusLabel.Visible = false
	statusLabel.ZIndex = 812
	statusLabel.Parent = bottomBar

	local randomizeBtn = mc.mobileButton({
		parent = bottomBar,
		text = _cc("btn_randomize", "RANDOMIZE"),
		size = UDim2.new(0.42, -8, 0, 40),
		position = UDim2.new(0, 10, 0, 22),
		color = theme.Button,
		textSize = 12,
		callback = function() end,
	})

	local backBtn = mc.mobileButton({
		parent = bottomBar,
		text = BitKaisenLocale.tOrFallback(L, "ui.back", nil, "Back"),
		size = UDim2.new(0.2, -4, 0, 40),
		position = UDim2.new(0.42, 4, 0, 22),
		color = theme.Button,
		textSize = 12,
		callback = function() end,
	})
	backBtn.Visible = false

	local continueBtn = mc.mobileButton({
		parent = bottomBar,
		text = _cc("btn_continue", "CONTINUE"),
		size = UDim2.new(0.38, -8, 0, 40),
		position = UDim2.new(0.62, 4, 0, 22),
		color = Color3.fromRGB(120, 30, 42),
		textSize = 13,
		callback = function() end,
	})

	-----------------------------------------------------------------------
	-- Option row refs for value label updates
	-----------------------------------------------------------------------

	local optionValueLabels = {}
	local nameBox = nil

	-----------------------------------------------------------------------
	-- Status messages
	-----------------------------------------------------------------------

	local function setStatus(message, isError)
		message = tostring(message or "")
		statusLabel.Text = message
		statusLabel.TextColor3 = isError and theme.Bad or theme.Gold
		statusLabel.Visible = message ~= ""
	end

	local function clearStatus()
		setStatus("", false)
	end

	-----------------------------------------------------------------------
	-- Build option rows
	-----------------------------------------------------------------------

	local function clearScrollContent()
		for _, child in ipairs(scroll:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextBox") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		table.clear(optionValueLabels)
		nameBox = nil
	end

	local function createOptionRow(parent, field, order)
		local locked = field.LockedByGodMode == true and not checkGodMode()

		if field.Key == "FirstName" then
			local row = Instance.new("Frame")
			row.Name = "FirstNameRow"
			row.Size = UDim2.new(1, 0, 0, 52)
			row.BackgroundColor3 = theme.Card
			row.BorderSizePixel = 0
			row.LayoutOrder = order
			row.ZIndex = 804
			row.Parent = parent
			mc.corner(row, 10)
			mc.stroke(row, theme.Stroke)

			local rowPad = Instance.new("UIPadding")
			rowPad.PaddingLeft = UDim.new(0, 12)
			rowPad.PaddingRight = UDim.new(0, 12)
			rowPad.Parent = row

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(0, 50, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = _cc("field_name", "Name")
			label.TextColor3 = theme.SubText
			label.TextSize = 11
			label.Font = Enum.Font.GothamBold
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.ZIndex = 805
			label.Parent = row

			local input = Instance.new("TextBox")
			input.Name = "FirstNameInput"
			input.Size = UDim2.new(1, -60, 0, 34)
			input.Position = UDim2.new(0, 56, 0.5, -17)
			input.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
			input.BorderSizePixel = 0
			input.ClearTextOnFocus = false
			input.Text = tostring(state.FirstName or DEFAULTS.FirstName)
			input.PlaceholderText = _cc("ph_name", "First name")
			input.TextColor3 = theme.Text
			input.PlaceholderColor3 = theme.Muted
			input.TextSize = 14
			input.Font = Enum.Font.GothamBold
			input.TextXAlignment = Enum.TextXAlignment.Left
			input.ZIndex = 806
			input.Parent = row
			mc.corner(input, 8)
			mc.stroke(input, theme.StrokeSoft)

			local inputPad = Instance.new("UIPadding")
			inputPad.PaddingLeft = UDim.new(0, 10)
			inputPad.PaddingRight = UDim.new(0, 10)
			inputPad.Parent = input

			input:GetPropertyChangedSignal("Text"):Connect(function()
				clearStatus()
				local cleaned = cleanText(input.Text)
				if #cleaned > 16 then
					input.Text = string.sub(cleaned, 1, 16)
					input.CursorPosition = #input.Text + 1
				end
				state.FirstName = cleanText(input.Text)
			end)

			nameBox = input
			return row
		end

		if field.Key == "BirthYear" then
			local row = Instance.new("Frame")
			row.Name = "BirthYearRow"
			row.Size = UDim2.new(1, 0, 0, 64)
			row.BackgroundColor3 = locked and Color3.fromRGB(28, 26, 34) or theme.Card
			row.BorderSizePixel = 0
			row.LayoutOrder = order
			row.ZIndex = 804
			row.Parent = parent
			mc.corner(row, 10)
			mc.stroke(row, locked and Color3.fromRGB(90, 72, 42) or theme.Stroke)

			local rowPad = Instance.new("UIPadding")
			rowPad.PaddingLeft = UDim.new(0, 12)
			rowPad.PaddingRight = UDim.new(0, 12)
			rowPad.Parent = row

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(0, 90, 0, 18)
			label.Position = UDim2.new(0, 0, 0, 8)
			label.BackgroundTransparency = 1
			label.Text = _fieldLabel(field.Key, field.Label)
			label.TextColor3 = locked and theme.Gold or theme.SubText
			label.TextSize = 11
			label.Font = Enum.Font.GothamBold
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.ZIndex = 805
			label.Parent = row

			if locked then
				local pill = Instance.new("TextLabel")
				pill.Size = UDim2.new(0, 62, 0, 16)
				pill.Position = UDim2.new(0, 0, 0, 28)
				pill.BackgroundColor3 = Color3.fromRGB(54, 40, 28)
				pill.Text = _cc("god_mode_pill", "GOD MODE")
				pill.TextColor3 = theme.Gold
				pill.TextSize = 9
				pill.Font = Enum.Font.GothamBlack
				pill.TextXAlignment = Enum.TextXAlignment.Center
				pill.TextYAlignment = Enum.TextYAlignment.Center
				pill.ZIndex = 806
				pill.Parent = row
				mc.corner(pill, 7)
				mc.stroke(pill, Color3.fromRGB(90, 72, 42))
			end

			local input = Instance.new("TextBox")
			input.Name = "BirthYearInput"
			input.Size = UDim2.new(1, -100, 0, 34)
			input.Position = UDim2.new(0, 96, 0.5, -17)
			input.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
			input.BorderSizePixel = 0
			input.ClearTextOnFocus = false
			input.Text = tostring(state.BirthYear or "")
			input.PlaceholderText = locked and _cc("ph_year_lock", "God Mode") or _cc("ph_year_open", "900-2200")
			input.TextColor3 = locked and theme.Gold or theme.Text
			input.PlaceholderColor3 = theme.Muted
			input.TextSize = 13
			input.Font = Enum.Font.GothamBold
			input.TextXAlignment = Enum.TextXAlignment.Left
			input.Active = not locked
			input.TextEditable = not locked
			input.ZIndex = 806
			input.Parent = row
			mc.corner(input, 8)
			mc.stroke(input, theme.StrokeSoft)

			input:GetPropertyChangedSignal("Text"):Connect(function()
				clearStatus()
				local digits = tostring(input.Text or ""):gsub("%D", "")
				if #digits > 4 then digits = string.sub(digits, 1, 4) end
				if input.Text ~= digits then
					input.Text = digits
					input.CursorPosition = #digits + 1
				end
				state.BirthYear = digits
				local year = tonumber(digits)
				if year then
					if year >= 2018 then state.Era = "Collapse Era"
					elseif year >= 2000 then state.Era = "Modern Era"
					elseif year >= 1603 then state.Era = "Edo Era"
					else state.Era = "Heian Era" end
					if optionValueLabels["Era"] then
						optionValueLabels["Era"].Text = state.Era
					end
				end
			end)

			return row
		end

		-- Standard option row with < value > arrows
		local row = Instance.new("Frame")
		row.Name = field.Key .. "Row"
		row.Size = UDim2.new(1, 0, 0, 48)
		row.BackgroundColor3 = locked and Color3.fromRGB(28, 26, 34) or theme.Card
		row.BorderSizePixel = 0
		row.LayoutOrder = order
		row.ZIndex = 804
		row.Parent = parent
		mc.corner(row, 10)
		mc.stroke(row, locked and Color3.fromRGB(90, 72, 42) or theme.Stroke)

		local rowPad = Instance.new("UIPadding")
		rowPad.PaddingLeft = UDim.new(0, 12)
		rowPad.PaddingRight = UDim.new(0, 12)
		rowPad.Parent = row

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0, 72, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = field.Label
		label.TextColor3 = locked and theme.Gold or theme.SubText
		label.TextSize = 11
		label.Font = Enum.Font.GothamBold
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 805
		label.Parent = row

		if locked then
			local pill = Instance.new("TextLabel")
			pill.Size = UDim2.new(0, 56, 0, 14)
			pill.AnchorPoint = Vector2.new(0, 0.5)
			pill.Position = UDim2.new(0, 0, 0.5, 12)
			pill.BackgroundColor3 = Color3.fromRGB(54, 40, 28)
			pill.Text = _cc("god_mode_pill", "GOD MODE")
			pill.TextColor3 = theme.Gold
			pill.TextSize = 8
			pill.Font = Enum.Font.GothamBlack
			pill.TextXAlignment = Enum.TextXAlignment.Center
			pill.TextYAlignment = Enum.TextYAlignment.Center
			pill.ZIndex = 806
			pill.Parent = row
			mc.corner(pill, 6)
		end

		local leftBtn = Instance.new("TextButton")
		leftBtn.Name = "Left"
		leftBtn.Size = UDim2.new(0, 30, 0, 30)
		leftBtn.AnchorPoint = Vector2.new(0, 0.5)
		leftBtn.Position = UDim2.new(0, 76, 0.5, 0)
		leftBtn.BackgroundColor3 = locked and Color3.fromRGB(35, 33, 42) or theme.Button
		leftBtn.BorderSizePixel = 0
		leftBtn.Text = locked and "" or "<"
		leftBtn.TextColor3 = theme.Text
		leftBtn.TextSize = 13
		leftBtn.Font = Enum.Font.GothamBlack
		leftBtn.AutoButtonColor = false
		leftBtn.Active = not locked
		leftBtn.Visible = not locked
		leftBtn.ZIndex = 806
		leftBtn.Parent = row
		mc.corner(leftBtn, 7)

		local valueLabel = Instance.new("TextLabel")
		valueLabel.Name = "Value"
		valueLabel.Size = UDim2.new(1, -150, 1, 0)
		valueLabel.Position = UDim2.new(0, 110, 0, 0)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text = locked and _cc("locked", "Locked") or tostring(state[field.Key] or firstAllowed(field.Key))
		valueLabel.TextColor3 = locked and theme.Gold or theme.Text
		valueLabel.TextSize = 12
		valueLabel.Font = Enum.Font.GothamBold
		valueLabel.TextXAlignment = Enum.TextXAlignment.Center
		valueLabel.TextYAlignment = Enum.TextYAlignment.Center
		valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
		valueLabel.ZIndex = 805
		valueLabel.Parent = row

		local rightBtn = Instance.new("TextButton")
		rightBtn.Name = "Right"
		rightBtn.Size = UDim2.new(0, 30, 0, 30)
		rightBtn.AnchorPoint = Vector2.new(1, 0.5)
		rightBtn.Position = UDim2.new(1, 0, 0.5, 0)
		rightBtn.BackgroundColor3 = locked and Color3.fromRGB(35, 33, 42) or theme.Button
		rightBtn.BorderSizePixel = 0
		rightBtn.Text = locked and "" or ">"
		rightBtn.TextColor3 = theme.Text
		rightBtn.TextSize = 13
		rightBtn.Font = Enum.Font.GothamBlack
		rightBtn.AutoButtonColor = false
		rightBtn.Active = not locked
		rightBtn.Visible = not locked
		rightBtn.ZIndex = 806
		rightBtn.Parent = row
		mc.corner(rightBtn, 7)

		optionValueLabels[field.Key] = valueLabel

		local busy = false
		local function applyCycle(direction)
			if busy then return end
			busy = true
			cycleOption(field, direction)
			valueLabel.Text = tostring(state[field.Key] or firstAllowed(field.Key))
			task.delay(0.08, function() busy = false end)
		end

		bindTap(leftBtn, function() applyCycle(-1) end)
		bindTap(rightBtn, function() applyCycle(1) end)

		return row
	end

	-----------------------------------------------------------------------
	-- Rebuild page content
	-----------------------------------------------------------------------

	local function rebuildContent()
		clearScrollContent()

		local fields = currentPage == 1 and PAGE1_FIELDS or PAGE2_FIELDS
		for i, field in ipairs(fields) do
			createOptionRow(scroll, field, i)
		end

		-- Summary card at the bottom
		local summaryCard = mc.mobileCard({
			parent = scroll,
			color = Color3.fromRGB(18, 18, 26),
			accentColor = Color3.fromRGB(100, 60, 160),
			order = #fields + 1,
		})

		local summaryText
		if currentPage == 1 then
			summaryText = "<b>" .. getDisplayFullName() .. "</b>"
				.. "\n" .. tostring(state.Height) .. " • " .. tostring(state.Build)
				.. "\n" .. _cc("sum_hair", "{hair} hair • {eyes} eyes"):gsub("{hair}", tostring(state.HairColor)):gsub("{eyes}", tostring(state.EyeColor))
				.. "\n" .. _cc("sum_ce", "CE Color: {color}"):gsub("{color}", "<font color='#b27aff'><b>" .. tostring(state.AuraColor) .. "</b></font>")
				.. "\n" .. _cc("sum_origin", "Origin: {origin}"):gsub("{origin}", tostring(state.OriginLocation))
		else
			local advancedText
			if checkGodMode() then
				advancedText = "\n" .. _cc("sum_curse_exp", "Curse Exposure: {value}"):gsub("{value}", tostring(state.EarlyCurseExposure))
					.. "\n" .. _cc("sum_temp", "Temperament: {value}"):gsub("{value}", tostring(state.Temperament))
					.. "\n" .. _cc("sum_goal", "Goal: {value}"):gsub("{value}", tostring(state.LifeGoal))
			else
				local locked = _cc("sum_locked", "Locked")
				advancedText = "\n" .. _cc("sum_curse_exp", "Curse Exposure: {value}"):gsub("{value}", locked)
					.. "\n" .. _cc("sum_temp", "Temperament: {value}"):gsub("{value}", locked)
					.. "\n" .. _cc("sum_goal", "Goal: {value}"):gsub("{value}", locked)
			end

			summaryText = "<b>" .. getDisplayFullName() .. "</b>"
				.. "\n" .. _cc("sum_era", "Era: {era}"):gsub("{era}", "<font color='#ffcd69'><b>" .. tostring(state.Era) .. "</b></font>")
				.. "\n" .. _cc("sum_year", "Start Year: {year}"):gsub("{year}", tostring(getSelectedEraStartYear()))
				.. "\n" .. _cc("sum_upbringing", "Upbringing: {value}"):gsub("{value}", tostring(state.Upbringing))
				.. advancedText
		end

		mc.mobileLabel({
			parent = summaryCard,
			text = summaryText,
			size = 12,
			color = theme.Text,
			order = 1,
		})
	end

	-----------------------------------------------------------------------
	-- Page navigation
	-----------------------------------------------------------------------

	local function refreshPage()
		if currentPage == 1 then
			titleLabel.Text = _cc("create_title", "CREATE CHARACTER")
			pageLabel.Text = _cc("page1_sub", "Page 1/2 • Identity")
			randomizeBtn.Text = _cc("btn_randomize", "RANDOMIZE")
			backBtn.Visible = false
			continueBtn.Text = _cc("btn_continue", "CONTINUE")
			continueBtn.Size = UDim2.new(0.55, -8, 0, 40)
			continueBtn.Position = UDim2.new(0.45, 4, 0, 22)
		else
			titleLabel.Text = _cc("birth_title", "BIRTH PATH")
			pageLabel.Text = _cc("page2_sub", "Page 2/2 • Circumstances")
			randomizeBtn.Text = _cc("btn_random", "RANDOM")
			randomizeBtn.Size = UDim2.new(0.3, -6, 0, 40)
			randomizeBtn.Position = UDim2.new(0, 10, 0, 22)
			backBtn.Visible = true
			backBtn.Size = UDim2.new(0.22, -4, 0, 40)
			backBtn.Position = UDim2.new(0.3, 6, 0, 22)
			continueBtn.Text = _cc("btn_finish", "FINISH")
			continueBtn.Size = UDim2.new(0.46, -8, 0, 40)
			continueBtn.Position = UDim2.new(0.54, 4, 0, 22)
		end

		rebuildContent()
	end

	-----------------------------------------------------------------------
	-- Open / close
	-----------------------------------------------------------------------

	local function showPanel()
		if isOpen then return end
		isOpen = true

		gui.Enabled = true
		overlay.Visible = true
		sheet.Visible = true
		overlay.BackgroundTransparency = 1
		sheet.BackgroundTransparency = 1

		TweenService:Create(overlay, TweenInfo.new(0.2), { BackgroundTransparency = 0.4 }):Play()
		TweenService:Create(sheet, TWEEN_SLIDE, { BackgroundTransparency = 0 }):Play()
	end

	local function hidePanel()
		if not isOpen then return end

		TweenService:Create(overlay, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
		local tw = TweenService:Create(sheet, TweenInfo.new(0.18), { BackgroundTransparency = 1 })
		tw:Play()
		tw.Completed:Wait()

		sheet.Visible = false
		overlay.Visible = false
		gui.Enabled = false
		isOpen = false
		lockedIdentityState = nil
		lockedRolledIdentityState = nil
	end

	local function openCustomization(stats)
		if isOpen then return end

		currentStats = stats
		currentPage = 1
		lockedIdentityState = nil
		captureRolledIdentity(stats)
		readStatsDefaults(stats)
		checkGodMode()

		refreshPage()
		showPanel()
	end

	local function queueCustomizationOpen(stats)
		if typeof(stats) ~= "table" then return end

		pendingOpenToken += 1
		local token = pendingOpenToken

		local delayTime = hasSeenAnyLifeUpdate and NORMAL_POPUP_DELAY or FIRST_LOAD_POPUP_DELAY
		hasSeenAnyLifeUpdate = true

		task.spawn(function()
			task.wait(delayTime)

			if token ~= pendingOpenToken then return end

			if typeof(currentStats) == "table" and currentStats.CharacterCustomized == true then
				return
			end

			if typeof(stats) == "table" and stats.Alive == false then
				return
			end

			openCustomization(stats)
		end)
	end

	-----------------------------------------------------------------------
	-- Button callbacks
	-----------------------------------------------------------------------

	bindTap(randomizeBtn, function()
		clearStatus()
		if currentPage == 1 then
			lockedIdentityState = nil
			randomizeIdentity()
		else
			randomizeBirthPath()
		end
		refreshPage()
	end)

	bindTap(backBtn, function()
		clearStatus()
		lockedIdentityState = nil
		currentPage = 1
		refreshPage()
	end)

	bindTap(continueBtn, function()
		clearStatus()

		if submitting then return end

		if currentPage == 1 then
			if nameBox then
				state.FirstName = cleanText(nameBox.Text)
			end

			if tostring(state.FirstName or "") == "" then
				setStatus(_cc("err_name", "Enter a first name before continuing."), true)
				return
			end

			lockedIdentityState = {
				FirstName = state.FirstName,
				Gender = state.Gender,
				HairColor = state.HairColor,
				EyeColor = state.EyeColor,
				SkinTone = state.SkinTone,
				Height = state.Height,
				Build = state.Build,
				Feature = state.Feature,
				AuraColor = state.AuraColor,
				OriginLocation = state.OriginLocation,
			}

			currentPage = 2
			refreshPage()
			return
		end

		-- Page 2: submit
		local identity = lockedIdentityState or state

		submitting = true
		continueBtn.Text = _cc("btn_saving", "SAVING...")

		local payload = {
			FirstName = identity.FirstName,
			Gender = identity.Gender,
			Appearance = {
				HairColor = identity.HairColor,
				EyeColor = identity.EyeColor,
				SkinTone = identity.SkinTone,
				Height = identity.Height,
				Build = identity.Build,
				Feature = identity.Feature,
				AuraColor = identity.AuraColor,
				OriginLocation = identity.OriginLocation,
			},
			BirthPath = {
				Era = state.Era,
				Upbringing = state.Upbringing,
				EarlyCurseExposure = state.EarlyCurseExposure,
				Temperament = state.Temperament,
				LifeGoal = state.LifeGoal,
				BirthYear = state.BirthYear,
			},
		}

		local ok, result = pcall(function()
			return submitRemote:InvokeServer(payload)
		end)

		submitting = false

		if ok and typeof(result) == "table" and result.Success == true then
			continueBtn.Text = _cc("btn_saved", "SAVED")
			task.delay(0.2, function()
				hidePanel()
			end)
		else
			local message = _cc("err_save", "Could not save character.")
			if ok and typeof(result) == "table" and result.Message then
				message = tostring(result.Message)
			elseif not ok then
				message = "Server error. Try again."
			end

			local loweredMessage = string.lower(message)
			if message == "That name is not allowed." or string.find(loweredMessage, "blocked") then
				message = "Name rejected. Choose a different first name."
			end

			continueBtn.Text = _cc("btn_finish", "FINISH")
			setStatus(message, true)
		end
	end)

	-----------------------------------------------------------------------
	-- Listen for UpdateLifeEvent (same trigger as PC panel)
	-----------------------------------------------------------------------

	updateLifeEvent.OnClientEvent:Connect(function(stats)
		if typeof(stats) ~= "table" then return end
		if isOpen and stats.CharacterCustomized ~= true then return end

		currentStats = stats

		if stats.Alive == false then return end
		if stats.CharacterCustomized == true then return end

		local lifeKey = getLifeKey(stats)
		if lastOpenLifeKey == lifeKey and isOpen then return end

		lastOpenLifeKey = lifeKey
		queueCustomizationOpen(stats)
	end)
end

return { init = init }
