local schema = require("../accountService/schema")

local migrations: { (data: schema.ProfileData) -> schema.ProfileData } = {}

local function validateMigrations()
	-- Ensure all migrations are properly ordered
end

local function migrateFields(player: Player, profile: any)
	local data = profile.Data :: schema.ProfileData
	local currentVersion = data.migrationVersion or 0

	for i = currentVersion + 1, #migrations do
		data = migrations[i](data)
		data.migrationVersion = i
	end

	profile.Data = data
end

return {
	migrations = migrations,
	validateMigrations = validateMigrations,
	migrateFields = migrateFields,
}
