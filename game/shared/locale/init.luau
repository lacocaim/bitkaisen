-- BitKaisenLocale
-- Central localization module. Server stores each player's locale on join,
-- then passes it down whenever text gets built. Client uses it for UI labels.
-- Translations live in es.luau / pt_br.luau add more files as needed.
-- Falls back to the English key if a translation is missing, never errors out.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BitKaisenLocale = {}

-- Supported locales and their Roblox locale ID prefixes
local LOCALE_MAP = {
	["es"]    = "es",
	["es-es"] = "es",
	["es-419"] = "es",
	["pt-br"] = "pt_br",
	["pt"]    = "pt_br",
}

local DEFAULT_LOCALE = "en"

-- Lazy-load translation tables so we don't require everything upfront
local cache: { [string]: any } = {}

local function loadLang(code: string): any
	if cache[code] then return cache[code] end

	local folder = ReplicatedStorage:FindFirstChild("locale")
	if not folder then return {} end

	local mod = folder:FindFirstChild(code)
	if not mod then return {} end

	local ok, data = pcall(require, mod)
	if not ok or type(data) ~= "table" then return {} end

	cache[code] = data
	return data
end

-- Resolve a Roblox locale string (e.g. "es-419") to our internal code
function BitKaisenLocale.resolveLocale(robloxLocale: string): string
	local lower = string.lower(tostring(robloxLocale or ""))
	return LOCALE_MAP[lower] or DEFAULT_LOCALE
end

-- Server-side: store per-player locale so we don't hit LocalizationService every call
local playerLocales: { [number]: string } = {}

function BitKaisenLocale.setPlayerLocale(userId: number, robloxLocale: string)
	playerLocales[userId] = BitKaisenLocale.resolveLocale(robloxLocale)
end

function BitKaisenLocale.getPlayerLocale(userId: number): string
	return playerLocales[userId] or DEFAULT_LOCALE
end

function BitKaisenLocale.clearPlayer(userId: number)
	playerLocales[userId] = nil
end

-- Client-side: read locale from the local player. Player.LocaleId matches what the server
-- gets on PlayerAdded, so both sides agree. Falls back to LocalizationService if somehow
-- LocalPlayer isn't available (e.g. called from server context by mistake).
function BitKaisenLocale.getClientLocale(): string
	local ok, localeId = pcall(function()
		return game:GetService("Players").LocalPlayer.LocaleId
	end)
	if ok and localeId and localeId ~= "" then
		return BitKaisenLocale.resolveLocale(localeId)
	end
	local ok2, localeId2 = pcall(function()
		return game:GetService("LocalizationService").RobloxLocaleId
	end)
	if ok2 and localeId2 and localeId2 ~= "" then
		return BitKaisenLocale.resolveLocale(localeId2)
	end
	return DEFAULT_LOCALE
end

-- Interpolate {key} placeholders in a string
local function interpolate(str: string, params: { [string]: any }?): string
	if not params then return str end
	return (str:gsub("{(%w+)}", function(k)
		local v = params[k]
		return v ~= nil and tostring(v) or ("{" .. k .. "}")
	end))
end

-- Translate with fallback to English string use this on the server so English players get
-- the hardcoded string and non-English players get the translation. Returns fallback if the
-- locale is "en" or the key has no translation.
function BitKaisenLocale.tOrFallback(locale: string, key: string, params: { [string]: any }?, fallback: string): string
	if locale == "en" then return fallback end
	local result = BitKaisenLocale.t(locale, key, params)
	if result == key then return fallback end
	return result
end

-- Main translate function
-- locale: "es", "pt_br", "en" etc
-- key: dot-separated path like "life_events.child_curse_corner.1"
-- params: optional table for {placeholder} substitution
function BitKaisenLocale.t(locale: string, key: string, params: { [string]: any }?): string
	local lang = loadLang(locale)

	-- Walk the dot-separated key through the table
	local value: any = lang
	for segment in key:gmatch("[^%.]+") do
		if type(value) ~= "table" then
			value = nil
			break
		end
		-- numeric segments for array access
		local n = tonumber(segment)
		value = n and value[n] or value[segment]
	end

	if type(value) == "string" then
		return interpolate(value, params)
	end

	-- No translation found — return the key so devs can spot missing entries
	return key
end

-- Shorthand: translate a life event text by id and index
function BitKaisenLocale.tEvent(locale: string, eventId: string, index: number): string?
	local lang = loadLang(locale)
	local events = lang.life_events
	if not events then return nil end
	local entry = events[eventId]
	if not entry then return nil end
	return entry[index] or nil
end

-- Shorthand: get all quiet year texts for a locale (falls back to nil so caller uses English)
function BitKaisenLocale.getQuietYearTexts(locale: string): { string }?
	local lang = loadLang(locale)
	return lang.quiet_year or nil
end

-- Return the raw scenario translation subtable for a given scenario ID, or nil if missing/English
function BitKaisenLocale.getScenarioLocale(locale: string, scenarioId: string): any
	if locale == "en" then return nil end
	local lang = loadLang(locale)
	return lang.scenarios and lang.scenarios[scenarioId] or nil
end

return BitKaisenLocale
