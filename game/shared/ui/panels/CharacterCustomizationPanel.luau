local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local remotes = require("@ui-state/remotes")
local responsiveScale = require("@ui/responsiveScale")

local player = Players.LocalPlayer

local MAIN_GUI_NAME = "BitKaisenGui"

local GOD_MODE_GAMEPASS_ID = 1861509054

local FIRST_LOAD_POPUP_DELAY = 1.05
local NORMAL_POPUP_DELAY = 0.45

local THEME = {
	Bg = Color3.fromRGB(0, 0, 0),
	Window = Color3.fromRGB(13, 13, 20),
	Panel = Color3.fromRGB(17, 17, 26),
	Card = Color3.fromRGB(19, 19, 29),
	Card2 = Color3.fromRGB(24, 24, 35),
	Stroke = Color3.fromRGB(55, 55, 76),
	StrokeSoft = Color3.fromRGB(38, 38, 54),
	Red = Color3.fromRGB(145, 32, 45),
	RedDark = Color3.fromRGB(92, 18, 31),
	RedSoft = Color3.fromRGB(110, 35, 48),
	Gold = Color3.fromRGB(255, 205, 105),
	Green = Color3.fromRGB(120, 240, 160),
	Blue = Color3.fromRGB(120, 190, 255),
	Purple = Color3.fromRGB(178, 122, 255),
	Text = Color3.fromRGB(240, 240, 248),
	SubText = Color3.fromRGB(170, 170, 190),
	Muted = Color3.fromRGB(110, 110, 130),
	Bad = Color3.fromRGB(230, 75, 90),
	Button = Color3.fromRGB(32, 32, 45),
	ButtonHover = Color3.fromRGB(45, 45, 62),
	Locked = Color3.fromRGB(32, 30, 38),
	LockedStroke = Color3.fromRGB(90, 72, 42),
}

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
-- UI references
-----------------------------------------------------------------------

local playerGuiRef: PlayerGui = nil
local screenGui: ScreenGui = nil
local overlay = nil
local window = nil
local titleLabel = nil
local pageLabel = nil
local subtitleLabel = nil
local leftTitleLabel = nil
local leftHintLabel = nil
local nameBox = nil
local summaryLabel = nil
local fieldsPanel = nil
local bottomBar = nil
local randomizeButton = nil
local backButton = nil
local continueButton = nil
local statusLabel = nil
local optionRows = {}
local optionClickBusy = {}

-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------

local function getMainGui()
	local gui = playerGuiRef:FindFirstChild(MAIN_GUI_NAME)
	if gui then return gui end
	return playerGuiRef:WaitForChild(MAIN_GUI_NAME, 10)
end

local function waitForMainUIReady()
	local mainGui = getMainGui()
	if not mainGui then return nil end

	local mainPanel = mainGui:FindFirstChild("MainPanel") or mainGui:WaitForChild("MainPanel", 10)
	if not mainPanel then return mainGui end

	local deadline = os.clock() + 4
	while os.clock() < deadline do
		local ageButton = mainPanel:FindFirstChild("AgeUpButton", true)
		local profileCard = mainPanel:FindFirstChild("ProfileCard", true)
		if ageButton and profileCard then break end
		task.wait(0.05)
	end

	return mainGui
end

local function viewport()
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local function getModalSize()
	return 760, 430
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or THEME.Stroke
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local function addPadding(parent, top, right, bottom, left)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, top or 0)
	padding.PaddingRight = UDim.new(0, right or 0)
	padding.PaddingBottom = UDim.new(0, bottom or 0)
	padding.PaddingLeft = UDim.new(0, left or 0)
	padding.Parent = parent
	return padding
end

local function tween(instance, duration, props)
	local tw = TweenService:Create(instance, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function cleanText(text)
	text = tostring(text or "")
	text = text:gsub("<[^>]->", "")
	text = text:gsub("[\n\r\t]", " ")
	text = text:gsub("^%s+", "")
	text = text:gsub("%s+$", "")
	return text
end

local function setHover(button, hoverColor)
	local base = button.BackgroundColor3

	button.MouseEnter:Connect(function()
		if button.Active then
			tween(button, 0.12, { BackgroundColor3 = hoverColor })
		end
	end)

	button.MouseLeave:Connect(function()
		tween(button, 0.12, { BackgroundColor3 = base })
	end)
end

local function makeText(parent, name, text, textSize, color, bold)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = text or ""
	label.TextColor3 = color or THEME.Text
	label.TextSize = textSize or 14
	label.Font = bold and Enum.Font.GothamBlack or Enum.Font.GothamMedium
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.RichText = true
	label.ZIndex = 1804
	label.Parent = parent
	return label
end

local function makeButton(parent, name, text, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.BackgroundColor3 = color or THEME.Button
	button.BorderSizePixel = 0
	button.Text = text or "BUTTON"
	button.TextColor3 = THEME.Text
	button.TextSize = 13
	button.Font = Enum.Font.GothamBlack
	button.AutoButtonColor = false
	button.ZIndex = 1812
	button.Parent = parent
	addCorner(button, 8)
	addStroke(button, THEME.StrokeSoft, 1)
	setHover(button, THEME.ButtonHover)
	return button
end

-----------------------------------------------------------------------
-- Status messages
-----------------------------------------------------------------------

local function setStatusMessage(message, isError)
	if not statusLabel then return end
	message = tostring(message or "")
	statusLabel.Text = message
	statusLabel.TextColor3 = isError and THEME.Bad or THEME.Gold
	statusLabel.Visible = message ~= ""
end

local function clearStatusMessage()
	setStatusMessage("", false)
end

-----------------------------------------------------------------------
-- Option / state helpers
-----------------------------------------------------------------------

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
-- Forward declarations
-----------------------------------------------------------------------

local updateSummary
local rebuildFields
local refreshPage
local layoutWindow
local buildUI
local openCustomization
local queueCustomizationOpen

-----------------------------------------------------------------------
-- Summary / display updates
-----------------------------------------------------------------------

function updateSummary()
	if nameBox and nameBox.Visible and nameBox.Parent and nameBox.Parent.Visible and currentPage == 1 then
		local typed = cleanText(nameBox.Text)
		if typed ~= "" then
			state.FirstName = typed
		end
	end

	if not summaryLabel then return end

	if currentPage == 1 then
		summaryLabel.Text =
			"<b>" .. getDisplayFullName() .. "</b>"
			.. "\n" .. tostring(state.Height) .. " • " .. tostring(state.Build)
			.. "\n" .. tostring(state.HairColor) .. " hair • " .. tostring(state.EyeColor) .. " eyes"
			.. "\nCE Color: <font color='#b27aff'><b>" .. tostring(state.AuraColor) .. "</b></font>"
			.. "\nOrigin: " .. tostring(state.OriginLocation)
	else
		local advancedText
		if checkGodMode() then
			advancedText =
				"\nCurse Exposure: " .. tostring(state.EarlyCurseExposure)
				.. "\nTemperament: " .. tostring(state.Temperament)
				.. "\nGoal: " .. tostring(state.LifeGoal)
		else
			advancedText =
				"\nCurse Exposure: Locked"
				.. "\nTemperament: Locked"
				.. "\nGoal: Locked"
		end

		summaryLabel.Text =
			"<b>" .. getDisplayFullName() .. "</b>"
			.. "\nEra: <font color='#ffcd69'><b>" .. tostring(state.Era) .. "</b></font>"
			.. "\nStart Year: " .. tostring(getSelectedEraStartYear())
			.. "\nUpbringing: " .. tostring(state.Upbringing)
			.. advancedText
	end

	for key, refs in pairs(optionRows) do
		if refs and refs.ValueLabel then
			refs.ValueLabel.Text = refs.Locked and "Locked" or tostring(state[key] or firstAllowed(key))
		end
	end
end

-----------------------------------------------------------------------
-- GUI element builders
-----------------------------------------------------------------------

local function clearGuiObjects(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("GuiObject") or child:IsA("UIListLayout") or child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function createArrow(parent, name, text, locked)
	local button = Instance.new("TextButton")
	button.Name = name
	button.BackgroundColor3 = locked and THEME.Locked or THEME.Button
	button.BorderSizePixel = 0
	button.Text = locked and "" or text
	button.TextColor3 = locked and THEME.Muted or THEME.Text
	button.TextSize = 12
	button.Font = Enum.Font.GothamBlack
	button.AutoButtonColor = false
	button.Active = not locked
	button.Visible = not locked
	button.ZIndex = 1822
	button.Parent = parent
	addCorner(button, 7)
	addStroke(button, THEME.StrokeSoft, 1)
	if not locked then
		setHover(button, THEME.ButtonHover)
	end
	return button
end

local function createLockedPill(parent)
	local pill = Instance.new("TextLabel")
	pill.Name = "LockedPill"
	pill.BackgroundColor3 = Color3.fromRGB(54, 40, 28)
	pill.BorderSizePixel = 0
	pill.Text = "GOD MODE"
	pill.TextColor3 = THEME.Gold
	pill.TextSize = 9
	pill.Font = Enum.Font.GothamBlack
	pill.TextXAlignment = Enum.TextXAlignment.Center
	pill.TextYAlignment = Enum.TextYAlignment.Center
	pill.ZIndex = 1806
	pill.Parent = parent
	addCorner(pill, 7)
	addStroke(pill, THEME.LockedStroke, 1)
	return pill
end

local function createOptionRow(parent, field)
	local locked = field.LockedByGodMode and not checkGodMode()
	local v = viewport()
	local compact = v.X < 700
	local tiny = v.X < 520

	if field.Key == "FirstName" then
		if not compact then return nil end

		local row = Instance.new("Frame")
		row.Name = "FirstNameRow"
		row.Size = UDim2.new(1, -8, 0, tiny and 46 or 50)
		row.BackgroundColor3 = THEME.Card
		row.BorderSizePixel = 0
		row.ZIndex = 1804
		row.Parent = parent
		addCorner(row, 8)
		addStroke(row, THEME.StrokeSoft, 1)

		local label = makeText(row, "Label", "Name", tiny and 9 or 11, THEME.SubText, true)
		label.Size = UDim2.new(0, tiny and 54 or 72, 1, 0)
		label.Position = UDim2.new(0, tiny and 7 or 10, 0, 0)
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.TextTruncate = Enum.TextTruncate.AtEnd

		local input = Instance.new("TextBox")
		input.Name = "MobileFirstNameBox"
		input.Size = UDim2.new(1, -(tiny and 72 or 92), 0, tiny and 30 or 34)
		input.Position = UDim2.new(0, tiny and 62 or 82, 0.5, tiny and -15 or -17)
		input.BackgroundColor3 = THEME.Card2
		input.BorderSizePixel = 0
		input.ClearTextOnFocus = false
		input.Text = tostring(state.FirstName or DEFAULTS.FirstName)
		input.PlaceholderText = "First name"
		input.TextColor3 = THEME.Text
		input.PlaceholderColor3 = THEME.Muted
		input.TextSize = tiny and 11 or 13
		input.Font = Enum.Font.GothamBold
		input.TextXAlignment = Enum.TextXAlignment.Left
		input.ZIndex = 1822
		input.Parent = row
		addCorner(input, 7)
		addStroke(input, THEME.Stroke, 1)

		local inputPad = Instance.new("UIPadding")
		inputPad.PaddingLeft = UDim.new(0, 9)
		inputPad.PaddingRight = UDim.new(0, 9)
		inputPad.Parent = input

		input:GetPropertyChangedSignal("Text"):Connect(function()
			clearStatusMessage()
			local cleaned = cleanText(input.Text)
			if #cleaned > 16 then
				input.Text = string.sub(cleaned, 1, 16)
				input.CursorPosition = #input.Text + 1
				cleaned = cleanText(input.Text)
			end
			state.FirstName = cleaned
			updateSummary()
		end)

		return row
	end

	if field.Key == "BirthYear" then
		local row = Instance.new("Frame")
		row.Name = "BirthYearRow"
		row.Size = UDim2.new(1, -8, 0, tiny and 58 or 52)
		row.BackgroundColor3 = locked and THEME.Locked or THEME.Card
		row.BorderSizePixel = 0
		row.ZIndex = 1804
		row.Parent = parent
		addCorner(row, 8)
		addStroke(row, locked and THEME.LockedStroke or THEME.StrokeSoft, 1)

		local label = makeText(row, "Label", field.Label, tiny and 9 or 11, locked and THEME.Gold or THEME.SubText, true)
		label.Size = UDim2.new(0, tiny and 70 or 110, 0, 18)
		label.Position = UDim2.new(0, tiny and 7 or 10, 0, 7)
		if locked then
			local pill = createLockedPill(row)
			pill.Size = UDim2.new(0, tiny and 58 or 70, 0, 16)
			pill.Position = UDim2.new(0, tiny and 7 or 10, 0, 27)
		end

		local input = Instance.new("TextBox")
		input.Name = "BirthYearBox"
		input.Size = UDim2.new(1, -(tiny and 92 or 150), 0, 30)
		input.Position = UDim2.new(0, tiny and 84 or 132, 0.5, -15)
		input.BackgroundColor3 = THEME.Card2
		input.BorderSizePixel = 0
		input.ClearTextOnFocus = false
		input.Text = tostring(state.BirthYear or "")
		input.PlaceholderText = locked and "God Mode" or "900-2200"
		input.TextColor3 = locked and THEME.Gold or THEME.Text
		input.PlaceholderColor3 = THEME.Muted
		input.TextSize = tiny and 11 or 13
		input.Font = Enum.Font.GothamBold
		input.TextXAlignment = Enum.TextXAlignment.Left
		input.ZIndex = 1822
		input.Active = not locked
		input.TextEditable = not locked
		input.Parent = row
		addCorner(input, 7)
		addStroke(input, THEME.Stroke, 1)

		input:GetPropertyChangedSignal("Text"):Connect(function()
			clearStatusMessage()
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
			end
			updateSummary()
		end)

		return row
	end

	local rowHeight = currentPage == 1 and (tiny and 38 or 36) or (tiny and 58 or 52)

	local row = Instance.new("Frame")
	row.Name = field.Key .. "Row"
	row.Size = UDim2.new(1, -8, 0, rowHeight)
	row.BackgroundColor3 = locked and THEME.Locked or THEME.Card
	row.BorderSizePixel = 0
	row.ZIndex = 1804
	row.Parent = parent
	addCorner(row, 8)
	addStroke(row, locked and THEME.LockedStroke or THEME.StrokeSoft, 1)

	local label = makeText(row, "Label", field.Label, tiny and 9 or 11, locked and THEME.Gold or THEME.SubText, true)
	label.Size = UDim2.new(0, tiny and 58 or (compact and 72 or 110), currentPage == 1 and 1 or 0, currentPage == 1 and 0 or 18)
	label.Position = UDim2.new(0, tiny and 7 or 10, 0, currentPage == 1 and 0 or 7)
	label.TextYAlignment = currentPage == 1 and Enum.TextYAlignment.Center or Enum.TextYAlignment.Top
	label.TextTruncate = Enum.TextTruncate.AtEnd

	if locked then
		local pill = createLockedPill(row)
		pill.Size = UDim2.new(0, tiny and 58 or 70, 0, 16)
		pill.Position = UDim2.new(0, tiny and 7 or 10, 0, 27)
	end

	if currentPage == 2 and not locked and not tiny then
		local desc = makeText(row, "Description", field.Description or "", compact and 8 or 9, THEME.Muted, false)
		desc.Size = UDim2.new(0.40, 0, 0, 18)
		desc.Position = UDim2.new(0, 10, 0, 27)
	elseif currentPage == 2 and locked and not tiny then
		local desc = makeText(row, "Description", "Unlock God Mode to edit.", 9, THEME.Muted, false)
		desc.Size = UDim2.new(0.36, 0, 0, 18)
		desc.Position = UDim2.new(0, 88, 0, 28)
	end

	local arrowSize = tiny and 26 or 30
	local leftX = tiny and 64 or (compact and 84 or 0)
	local valueLeft = tiny and 98 or (compact and 122 or 0)
	local valueRightPad = tiny and 40 or 48

	local left = createArrow(row, "Left", "<", locked)
	left.Size = UDim2.new(0, arrowSize, 0, 26)
	if compact then
		left.Position = UDim2.new(0, leftX, 0.5, -13)
	else
		left.Position = UDim2.new(0.38, 0, 0.5, -13)
	end

	local value = makeText(row, "Value", locked and "Locked" or tostring(state[field.Key] or firstAllowed(field.Key)), tiny and 10 or 11, locked and THEME.Gold or THEME.Text, true)
	if compact then
		value.Size = UDim2.new(1, -(valueLeft + valueRightPad), 1, 0)
		value.Position = UDim2.new(0, valueLeft, 0, 0)
	else
		value.Size = UDim2.new(0.43, -8, 1, 0)
		value.Position = UDim2.new(0.43, 0, 0, 0)
	end
	value.TextXAlignment = Enum.TextXAlignment.Center
	value.TextYAlignment = Enum.TextYAlignment.Center
	value.TextTruncate = Enum.TextTruncate.AtEnd
	value.ZIndex = 1821

	local right = createArrow(row, "Right", ">", locked)
	right.Size = UDim2.new(0, arrowSize, 0, 26)
	right.Position = UDim2.new(1, tiny and -33 or -40, 0.5, -13)

	local function applyCycle(direction)
		if optionClickBusy[field.Key] then return end
		optionClickBusy[field.Key] = true

		cycleOption(field, direction)

		local refs = optionRows[field.Key]
		if refs and refs.ValueLabel then
			refs.ValueLabel.Text = locked and "Locked" or tostring(state[field.Key] or firstAllowed(field.Key))
		end

		updateSummary()

		task.delay(0.08, function()
			optionClickBusy[field.Key] = nil
		end)
	end

	left.MouseButton1Click:Connect(function()
		applyCycle(-1)
	end)

	right.MouseButton1Click:Connect(function()
		applyCycle(1)
	end)

	optionRows[field.Key] = {
		Row = row,
		ValueLabel = value,
		Locked = locked,
	}

	return row
end

-----------------------------------------------------------------------
-- Rebuild / refresh
-----------------------------------------------------------------------

function rebuildFields()
	if not fieldsPanel then return end

	table.clear(optionRows)
	table.clear(optionClickBusy)
	clearGuiObjects(fieldsPanel)

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = fieldsPanel

	addPadding(fieldsPanel, 4, 4, 22, 4)

	local fields = currentPage == 1 and PAGE1_FIELDS or PAGE2_FIELDS
	for _, field in ipairs(fields) do
		createOptionRow(fieldsPanel, field)
	end

	local function updateCanvas()
		fieldsPanel.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 26)
	end

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
	updateCanvas()
end

function refreshPage()
	if not titleLabel or not subtitleLabel then return end

	if currentPage == 1 then
		titleLabel.Text = "CREATE CHARACTER"
		pageLabel.Text = "Page 1/2 • Identity"
		subtitleLabel.Text = "Choose your identity for this life. Clan, cursed technique, and birth origin are still rolled by the game."
		leftTitleLabel.Text = "Birth Profile"
		leftHintLabel.Text = "First Name"
		randomizeButton.Text = "RANDOMIZE"
		backButton.Visible = false
		continueButton.Text = "CONTINUE"

		if nameBox then
			nameBox.Visible = true
			nameBox.Text = tostring(state.FirstName or DEFAULTS.FirstName)
		end
	else
		titleLabel.Text = "BIRTH PATH"
		pageLabel.Text = "Page 2/2 • Circumstances"
		subtitleLabel.Text = "Era and upbringing are free. God Mode unlocks advanced birth options."
		leftTitleLabel.Text = "Life Foundation"
		leftHintLabel.Text = "Profile Summary"
		randomizeButton.Text = "RANDOMIZE PATH"
		backButton.Visible = true
		continueButton.Text = "FINISH"

		if nameBox then
			nameBox.Visible = false
		end
	end

	rebuildFields()
	updateSummary()
end

-----------------------------------------------------------------------
-- Layout
-----------------------------------------------------------------------

function layoutWindow()
	if not window then return end

	local v = viewport()
	local modalWidth, modalHeight = getModalSize()
	local compact = modalWidth < 620 or v.X < 700
	local tiny = modalWidth < 460 or v.X < 520
	local titleAreaHeight = compact and 58 or 68
	local bottomBarHeight = tiny and 78 or 86

	window.Size = UDim2.new(0, modalWidth, 0, modalHeight)
	window.Position = UDim2.new(0.5, 0, 0.5, 0)

	if titleLabel then
		titleLabel.Position = UDim2.new(0, compact and 14 or 20, 0, compact and 9 or 12)
		titleLabel.Size = UDim2.new(0.58, 0, 0, compact and 22 or 25)
		titleLabel.TextSize = compact and 16 or 21
	end

	if pageLabel then
		pageLabel.Position = UDim2.new(0.58, 0, 0, compact and 11 or 15)
		pageLabel.Size = UDim2.new(0.42, compact and -14 or -20, 0, 18)
		pageLabel.TextSize = compact and 8 or 10
	end

	if subtitleLabel then
		subtitleLabel.Position = UDim2.new(0, compact and 14 or 20, 0, compact and 32 or 40)
		subtitleLabel.Size = UDim2.new(1, compact and -28 or -40, 0, compact and 18 or 22)
		subtitleLabel.TextSize = compact and 8 or 11
		subtitleLabel.TextWrapped = true
	end

	if bottomBar then
		bottomBar.Position = UDim2.new(0, 0, 1, -bottomBarHeight)
		bottomBar.Size = UDim2.new(1, 0, 0, bottomBarHeight)
	end

	local body = window:FindFirstChild("Body")
	if body then
		body.Position = UDim2.new(0, compact and 12 or 20, 0, titleAreaHeight)
		body.Size = UDim2.new(1, compact and -24 or -40, 1, -(titleAreaHeight + bottomBarHeight + 10))
	end

	local bodyWidth = modalWidth - (compact and 24 or 40)
	local leftPanel = body and body:FindFirstChild("LeftPanel")
	local leftWidth = compact and 0 or math.clamp(math.floor(bodyWidth * 0.34), 210, 250)

	if leftPanel then
		if compact then
			leftPanel.Visible = false
			leftPanel.Size = UDim2.new(0, 0, 0, 0)
		else
			leftPanel.Visible = true
			leftPanel.Size = UDim2.new(0, leftWidth, 1, 0)
			leftPanel.Position = UDim2.new(0, 0, 0, 0)
		end
	end

	if fieldsPanel then
		if compact then
			fieldsPanel.Position = UDim2.new(0, 0, 0, 0)
			fieldsPanel.Size = UDim2.new(1, 0, 1, 0)
		else
			fieldsPanel.Position = UDim2.new(0, leftWidth + 14, 0, 0)
			fieldsPanel.Size = UDim2.new(1, -(leftWidth + 14), 1, 0)
		end
	end

	local buttonY = tiny and 38 or 44
	local smallButtonWidth = tiny and 96 or 132
	local backWidth = tiny and 78 or 104
	local continueWidth = tiny and 112 or 146

	if statusLabel then
		statusLabel.Position = UDim2.new(0, tiny and 10 or 18, 0, 8)
		statusLabel.Size = UDim2.new(1, tiny and -20 or -36, 0, tiny and 26 or 28)
		statusLabel.TextSize = tiny and 9 or 11
	end

	if randomizeButton then
		randomizeButton.Size = UDim2.new(0, smallButtonWidth, 0, tiny and 32 or 36)
		randomizeButton.Position = UDim2.new(0, tiny and 10 or 20, 0, buttonY)
		randomizeButton.TextSize = tiny and 9 or 13
	end

	if continueButton then
		continueButton.Size = UDim2.new(0, continueWidth, 0, tiny and 32 or 36)
		continueButton.Position = UDim2.new(1, -(continueWidth + (tiny and 10 or 20)), 0, buttonY)
		continueButton.TextSize = tiny and 10 or 13
	end

	if backButton then
		backButton.Size = UDim2.new(0, backWidth, 0, tiny and 32 or 36)
		backButton.Position = UDim2.new(1, -(continueWidth + backWidth + (tiny and 18 or 32)), 0, buttonY)
		backButton.TextSize = tiny and 10 or 13
	end
end

-----------------------------------------------------------------------
-- Build
-----------------------------------------------------------------------

local function destroyExisting()
	local mainGui = playerGuiRef and playerGuiRef:FindFirstChild(MAIN_GUI_NAME)
	if mainGui then
		local old = mainGui:FindFirstChild("CharacterCustomizationOverlay")
		if old then old:Destroy() end
	end

	local oldStandalone = playerGuiRef and playerGuiRef:FindFirstChild("BitKaisenCharacterCustomizationGui")
	if oldStandalone then oldStandalone:Destroy() end

	screenGui = nil
	overlay = nil
	window = nil
end

function buildUI()
	destroyExisting()

	local mainGui = getMainGui()
	if not mainGui then
		warn("[CharacterCustomizationPanel] BitKaisenGui not found.")
		return
	end

	local modalWidth, modalHeight = getModalSize()

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BitKaisenCharacterCustomizationGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Enabled = false
	screenGui.DisplayOrder = 640
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGuiRef

	overlay = Instance.new("Frame")
	overlay.Name = "CharacterCustomizationOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.Position = UDim2.fromScale(0, 0)
	overlay.BackgroundColor3 = THEME.Bg
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.Visible = false
	overlay.Active = true
	overlay.ZIndex = 1800
	overlay.Parent = screenGui

	window = Instance.new("Frame")
	window.Name = "CharacterCustomizationWindow"
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.new(0.5, 0, 0.5, 0)
	window.Size = UDim2.new(0, modalWidth, 0, modalHeight)
	window.BackgroundColor3 = THEME.Window
	window.BackgroundTransparency = 1
	window.BorderSizePixel = 0
	window.Visible = false
	window.ClipsDescendants = false
	window.ZIndex = 1801
	window.Parent = overlay
	addCorner(window, 12)
	addStroke(window, THEME.RedSoft, 2)
	responsiveScale.attach(window, 760, 430)

	titleLabel = makeText(window, "Title", "CREATE CHARACTER", 21, THEME.Text, true)
	titleLabel.Size = UDim2.new(0.58, 0, 0, 25)
	titleLabel.Position = UDim2.new(0, 20, 0, 12)

	pageLabel = makeText(window, "PageLabel", "Page 1/2 • Identity", 10, THEME.Muted, true)
	pageLabel.Size = UDim2.new(0.38, -20, 0, 18)
	pageLabel.Position = UDim2.new(0.62, 0, 0, 15)
	pageLabel.TextXAlignment = Enum.TextXAlignment.Right

	subtitleLabel = makeText(window, "Subtitle", "", 11, THEME.SubText, false)
	subtitleLabel.Size = UDim2.new(1, -40, 0, 22)
	subtitleLabel.Position = UDim2.new(0, 20, 0, 40)

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.Position = UDim2.new(0, 20, 0, 68)
	body.Size = UDim2.new(1, -40, 1, -152)
	body.ZIndex = 1803
	body.Parent = window

	local leftPanel = Instance.new("Frame")
	leftPanel.Name = "LeftPanel"
	leftPanel.Size = UDim2.new(0, 230, 1, 0)
	leftPanel.Position = UDim2.new(0, 0, 0, 0)
	leftPanel.BackgroundColor3 = THEME.Panel
	leftPanel.BorderSizePixel = 0
	leftPanel.ZIndex = 1803
	leftPanel.Parent = body
	addCorner(leftPanel, 10)
	addStroke(leftPanel, THEME.StrokeSoft, 1)
	addPadding(leftPanel, 12, 12, 12, 12)

	leftTitleLabel = makeText(leftPanel, "LeftTitle", "Birth Profile", 16, THEME.Gold, true)
	leftTitleLabel.Size = UDim2.new(1, 0, 0, 22)
	leftTitleLabel.Position = UDim2.new(0, 0, 0, 0)

	leftHintLabel = makeText(leftPanel, "LeftHint", "First Name", 11, THEME.SubText, true)
	leftHintLabel.Size = UDim2.new(1, 0, 0, 18)
	leftHintLabel.Position = UDim2.new(0, 0, 0, 34)

	nameBox = Instance.new("TextBox")
	nameBox.Name = "FirstNameBox"
	nameBox.Size = UDim2.new(1, 0, 0, 36)
	nameBox.Position = UDim2.new(0, 0, 0, 56)
	nameBox.BackgroundColor3 = THEME.Card2
	nameBox.BorderSizePixel = 0
	nameBox.ClearTextOnFocus = false
	nameBox.Text = tostring(state.FirstName or DEFAULTS.FirstName)
	nameBox.PlaceholderText = "First name"
	nameBox.TextColor3 = THEME.Text
	nameBox.PlaceholderColor3 = THEME.Muted
	nameBox.TextSize = 14
	nameBox.Font = Enum.Font.GothamBold
	nameBox.TextXAlignment = Enum.TextXAlignment.Left
	nameBox.ZIndex = 1805
	nameBox.Parent = leftPanel
	addCorner(nameBox, 8)
	addStroke(nameBox, THEME.Stroke, 1)

	local namePadding = Instance.new("UIPadding")
	namePadding.PaddingLeft = UDim.new(0, 10)
	namePadding.PaddingRight = UDim.new(0, 10)
	namePadding.Parent = nameBox

	nameBox:GetPropertyChangedSignal("Text"):Connect(function()
		clearStatusMessage()
		local cleaned = cleanText(nameBox.Text)
		if #cleaned > 16 then
			nameBox.Text = string.sub(cleaned, 1, 16)
			nameBox.CursorPosition = #nameBox.Text + 1
		end
		updateSummary()
	end)

	summaryLabel = makeText(leftPanel, "Summary", "", 11, THEME.Text, false)
	summaryLabel.Size = UDim2.new(1, 0, 1, -104)
	summaryLabel.Position = UDim2.new(0, 0, 0, 104)

	fieldsPanel = Instance.new("ScrollingFrame")
	fieldsPanel.Name = "FieldsPanel"
	fieldsPanel.BackgroundColor3 = THEME.Panel
	fieldsPanel.BackgroundTransparency = 0
	fieldsPanel.BorderSizePixel = 0
	fieldsPanel.Position = UDim2.new(0, 244, 0, 0)
	fieldsPanel.Size = UDim2.new(1, -244, 1, 0)
	fieldsPanel.ScrollBarThickness = 4
	fieldsPanel.ScrollBarImageColor3 = THEME.RedSoft
	fieldsPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
	fieldsPanel.ZIndex = 1803
	fieldsPanel.Parent = body
	addCorner(fieldsPanel, 10)
	addStroke(fieldsPanel, THEME.StrokeSoft, 1)

	bottomBar = Instance.new("Frame")
	bottomBar.Name = "BottomBar"
	bottomBar.BackgroundColor3 = THEME.Window
	bottomBar.BackgroundTransparency = 0
	bottomBar.BorderSizePixel = 0
	bottomBar.Position = UDim2.new(0, 0, 1, -72)
	bottomBar.Size = UDim2.new(1, 0, 0, 72)
	bottomBar.ZIndex = 1810
	bottomBar.Parent = window

	local bottomLine = Instance.new("Frame")
	bottomLine.Name = "BottomLine"
	bottomLine.BackgroundColor3 = THEME.StrokeSoft
	bottomLine.BorderSizePixel = 0
	bottomLine.Size = UDim2.new(1, 0, 0, 1)
	bottomLine.Position = UDim2.new(0, 0, 0, 0)
	bottomLine.ZIndex = 1811
	bottomLine.Parent = bottomBar

	statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.BackgroundTransparency = 1
	statusLabel.BorderSizePixel = 0
	statusLabel.Text = ""
	statusLabel.TextColor3 = THEME.Gold
	statusLabel.TextSize = 11
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextWrapped = true
	statusLabel.TextXAlignment = Enum.TextXAlignment.Center
	statusLabel.TextYAlignment = Enum.TextYAlignment.Center
	statusLabel.Visible = false
	statusLabel.ZIndex = 1812
	statusLabel.Parent = bottomBar

	randomizeButton = makeButton(bottomBar, "RandomizeButton", "RANDOMIZE", THEME.Button)
	randomizeButton.Size = UDim2.new(0, 132, 0, 36)
	randomizeButton.Position = UDim2.new(0, 20, 0, 18)

	randomizeButton.MouseButton1Click:Connect(function()
		clearStatusMessage()
		if currentPage == 1 then
			lockedIdentityState = nil
			randomizeIdentity()
			if nameBox then
				nameBox.Text = tostring(state.FirstName or DEFAULTS.FirstName)
			end
		else
			randomizeBirthPath()
		end
		refreshPage()
	end)

	backButton = makeButton(bottomBar, "BackButton", "BACK", THEME.Button)
	backButton.Size = UDim2.new(0, 104, 0, 36)
	backButton.Position = UDim2.new(1, -280, 0, 18)
	backButton.Visible = false

	backButton.MouseButton1Click:Connect(function()
		clearStatusMessage()
		lockedIdentityState = nil
		currentPage = 1
		refreshPage()
	end)

	continueButton = makeButton(bottomBar, "ContinueButton", "CONTINUE", THEME.RedDark)
	continueButton.Size = UDim2.new(0, 146, 0, 36)
	continueButton.Position = UDim2.new(1, -166, 0, 18)

	continueButton.MouseButton1Click:Connect(function()
		clearStatusMessage()

		if submitting then return end

		if currentPage == 1 then
			if nameBox and nameBox.Visible and nameBox.Parent and nameBox.Parent.Visible then
				state.FirstName = cleanText(nameBox.Text)
			end

			if tostring(state.FirstName or "") == "" then
				setStatusMessage("Enter a first name before continuing.", true)
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

		local identity = lockedIdentityState or state

		submitting = true
		continueButton.Text = "SAVING..."

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

		local submitRemote = remotes.submitCharacterCustomization()
		if not submitRemote then
			submitting = false
			continueButton.Text = "FINISH"
			setStatusMessage("Submit remote not available.", true)
			return
		end

		local ok, result = pcall(function()
			return submitRemote:InvokeServer(payload)
		end)

		submitting = false

		if ok and typeof(result) == "table" and result.Success == true then
			continueButton.Text = "SAVED"

			task.delay(0.15, function()
				if overlay then
					tween(overlay, 0.18, { BackgroundTransparency = 1 })
				end
				if window then
					tween(window, 0.18, { BackgroundTransparency = 1 })
				end

				task.delay(0.2, function()
					if overlay then overlay.Visible = false end
					if window then window.Visible = false end
					if screenGui then screenGui.Enabled = false end
					isOpen = false
					lockedIdentityState = nil
					lockedRolledIdentityState = nil
				end)
			end)
		else
			local message = "Could not save character."
			if ok and typeof(result) == "table" and result.Message then
				message = tostring(result.Message)
			elseif not ok then
				message = "Server error. Try again."
				warn("[CharacterCustomizationPanel] Submit failed:", result)
			end

			local loweredMessage = string.lower(message)
			if message == "That name is not allowed." or string.find(loweredMessage, "blocked") then
				message = "Name rejected. Choose a different first name."
			end

			continueButton.Text = "FINISH"
			setStatusMessage(message, true)
		end
	end)

	layoutWindow()
	refreshPage()
end

-----------------------------------------------------------------------
-- Open / close
-----------------------------------------------------------------------

function openCustomization(stats)
	if isOpen then return end

	currentStats = stats
	currentPage = 1
	lockedIdentityState = nil
	captureRolledIdentity(stats)
	readStatsDefaults(stats)
	checkGodMode()

	if not overlay or not overlay.Parent then
		buildUI()
	else
		layoutWindow()
		if nameBox then
			nameBox.Text = tostring(state.FirstName or DEFAULTS.FirstName)
		end
		refreshPage()
	end

	if not overlay or not window or not screenGui then return end

	isOpen = true
	screenGui.Enabled = true
	overlay.Visible = true
	window.Visible = true
	overlay.BackgroundTransparency = 1
	window.BackgroundTransparency = 1
	window.Position = UDim2.new(0.5, 0, 0.52, 0)

	tween(overlay, 0.18, { BackgroundTransparency = 0.35 })
	tween(window, 0.2, {
		BackgroundTransparency = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
	})
end

function queueCustomizationOpen(stats)
	if typeof(stats) ~= "table" then return end

	pendingOpenToken += 1
	local token = pendingOpenToken

	local delayTime = hasSeenAnyLifeUpdate and NORMAL_POPUP_DELAY or FIRST_LOAD_POPUP_DELAY
	hasSeenAnyLifeUpdate = true

	task.spawn(function()
		waitForMainUIReady()
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
-- Init
-----------------------------------------------------------------------

local function init(playerGui: Instance)
	playerGuiRef = playerGui

	local ule = remotes.updateLifeEvent()
	if ule then
		ule.OnClientEvent:Connect(function(stats)
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

	task.defer(function()
		buildUI()
	end)
end

return { init = init }
