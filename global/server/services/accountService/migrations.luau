local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local schema = require("../accountService/schema")

local migrations: { (data: schema.ProfileData) -> schema.ProfileData } = {}

local LEGACY_DATASTORE_V2 = "BitkaizenSave_v2_Slots"
local LEGACY_DATASTORE_V1 = "BitkaizenSave_v1"

local function safeGetAsync(store, key)
	local ok, result = pcall(function()
		return store:GetAsync(key)
	end)
	if ok then
		return result
	end
	warn("[Migration] Failed to read legacy key " .. tostring(key) .. ": " .. tostring(result))
	return nil
end

local function buildSummaryFromLegacyStats(stats, slotId: number): schema.SlotSummary
	local summary = schema.makeEmptySlotSummary(slotId)
	if typeof(stats) ~= "table" then
		return summary
	end

	summary.Exists = true
	local firstName = tostring(stats.FirstName or "")
	local familyName = tostring(stats.FamilyName or "")
	if firstName ~= "" and firstName ~= "Unknown" and familyName ~= "" and familyName ~= "Unknown" and familyName ~= "None" then
		summary.Name = firstName .. " " .. familyName
	else
		summary.Name = tostring(stats.Name or "Unknown")
	end
	summary.Age = tonumber(stats.Age) or 0
	summary.CurrentMonth = math.clamp(tonumber(stats.CurrentMonth) or 1, 1, 12)
	summary.MonthsIntoAge = math.clamp(tonumber(stats.MonthsIntoAge) or 0, 0, 11)
	summary.Grade = tostring(stats.Grade or "Unknown")
	summary.Generation = tonumber(stats.Generation) or 1
	summary.FirstName = firstName ~= "" and firstName or "Unknown"
	summary.FamilyName = familyName ~= "" and familyName or "Unknown"
	summary.Origin = tostring(stats.Origin or stats.Clan or "Unknown")
	summary.Clan = tostring(stats.Clan or stats.Origin or "Unknown")
	summary.Gender = tostring(stats.Gender or "Unknown")
	summary.CursedTechnique = tostring(stats.CursedTechnique or "None")
	summary.Alive = stats.Alive ~= false
	summary.LastPlayed = tonumber(stats.LastPlayed) or os.time()
	summary.LastSaved = tonumber(stats.LastSaved) or os.time()
	return summary
end

--[[
	Migration 1: Import existing player data from old raw DataStore keys.

	Old layout:
		BitkaizenSave_v2_Slots / Player_{userId}_Profile  -> profile table
		BitkaizenSave_v2_Slots / Player_{userId}_Slot_{n} -> life stats
		BitkaizenSave_v1       / Player_{userId}          -> legacy v1 stats

	This migration runs once when a player first loads into the new ProfileStore
	system (migrationVersion == 0 and no slot data exists yet).
]]
table.insert(migrations, function(data: schema.ProfileData): schema.ProfileData
	if RunService:IsStudio() then
		return data
	end

	local hasExistingData = false
	for _, slot in data.account.slots do
		if slot.exists then
			hasExistingData = true
			break
		end
	end
	if hasExistingData then
		return data
	end

	local userId: number? = nil
	-- userId is extracted from the ProfileStore key during migrateFields
	-- We store it temporarily in the profile data for this migration
	local tempUserId = (data :: any)._migrationUserId
	if not tempUserId then
		return data
	end
	userId = tempUserId

	local legacyStoreV2 = DataStoreService:GetDataStore(LEGACY_DATASTORE_V2)

	local oldProfile = safeGetAsync(legacyStoreV2, "Player_" .. tostring(userId) .. "_Profile")

	local newAccount = table.clone(data.account)
	local newSlots = table.clone(newAccount.slots)

	if typeof(oldProfile) == "table" then
		newAccount.selectedSlot = math.clamp(tonumber(oldProfile.SelectedSlot) or 1, 1, schema.DEFAULT_SLOT_COUNT)
		newAccount.extraSlotsUnlocked = oldProfile.ExtraSaveSlotsUnlocked == true

		if typeof(oldProfile.GiftedGamePasses) == "table" then
			local passes = {}
			for k, v in oldProfile.GiftedGamePasses do
				if v == true then
					passes[tostring(k)] = true
				end
			end
			newAccount.giftedPasses = passes
		end

		if typeof(oldProfile.AccountRewards) == "table" then
			local rewards = {}
			for k, v in oldProfile.AccountRewards do
				rewards[tostring(k)] = v
			end
			newAccount.accountRewards = rewards
		end

		if typeof(oldProfile.AccountDailyLogin) == "table" then
			newAccount.dailyLogin = oldProfile.AccountDailyLogin
		end
	end

	for slotId = 1, schema.DEFAULT_SLOT_COUNT do
		local slotStats = safeGetAsync(legacyStoreV2, "Player_" .. tostring(userId) .. "_Slot_" .. tostring(slotId))

		if slotId == 1 and not slotStats then
			local legacyStoreV1 = DataStoreService:GetDataStore(LEGACY_DATASTORE_V1)
			slotStats = safeGetAsync(legacyStoreV1, "Player_" .. tostring(userId))
			if slotStats then
				print("[Migration] Found legacy v1 save for user " .. tostring(userId) .. ", migrating to slot 1")
			end
		end

		if typeof(slotStats) == "table" then
			newSlots[slotId] = {
				exists = true,
				summary = buildSummaryFromLegacyStats(slotStats, slotId),
				stats = slotStats,
			}
			print("[Migration] Imported slot " .. tostring(slotId) .. " for user " .. tostring(userId))
		end
	end

	newAccount.slots = newSlots
	data.account = newAccount

	return data
end)

local function validateMigrations()
	-- Validation: ensure migrations are ordered and don't corrupt data
end

local function migrateFields(player: Player, profile: any)
	local data = profile.Data :: schema.ProfileData
	local currentVersion = data.migrationVersion or 0

	if currentVersion < #migrations then
		(data :: any)._migrationUserId = player.UserId
	end

	for i = currentVersion + 1, #migrations do
		data = migrations[i](data)
		data.migrationVersion = i
	end

	(data :: any)._migrationUserId = nil
	profile.Data = data
end

return {
	migrations = migrations,
	validateMigrations = validateMigrations,
	migrateFields = migrateFields,
}
