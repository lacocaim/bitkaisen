local schema = require("@global/server/services/accountService/schema")
local charm = require("@packages/charm")
local profilestore = require("@server-packages/profilestore")

local get: charm.Getter<{ [string]: schema.ProfileData }>, set: charm.Setter<{ [string]: schema.ProfileData }> =
	charm.signal({})
local playerStore = profilestore.New("PlayerData", schema.template)
local profiles: { [Player]: typeof(playerStore:StartSessionAsync(...)) } = {}

return {
	playerStore = playerStore,
	profiles = profiles,
	get = get,
	set = set,
}
