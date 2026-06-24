local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local schema = require("../accountService/schema")

local charm = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("charm"))
local profilestore = require(ServerScriptService:WaitForChild("server-packages"):WaitForChild("profilestore"))

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
