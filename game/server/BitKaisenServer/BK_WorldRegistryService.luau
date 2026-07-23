-- ModuleScript: BK_WorldRegistryService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose:
--   Multiplayer Fase 4 ("Buscador y creación"): the catalog of real Public
--   worlds -- separate from BK_WorldStateService, which owns each world's
--   own Era/Year/Events/Sealed state. This service only knows "what worlds
--   exist, how to find them, and how to get into one" -- creation reserves
--   a real Roblox server via TeleportService, so each world from here on is
--   an actual separate server process, not a logical partition of one
--   server like Fases 1-3 assumed.
--
--   Population is tracked in MemoryStoreService (not DataStore) because it
--   changes constantly -- each world's own server calls ReportPopulation
--   on a heartbeat; a short TTL means a crashed/emptied world's entry just
--   expires on its own, no manual cleanup needed.

local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local registryStore = DataStoreService:GetDataStore("BK_WorldRegistry")
local populationMap = MemoryStoreService:GetSortedMap("BK_WorldPopulation")

local INDEX_KEY = "index"
local POPULATION_TTL_SECONDS = 120
-- Must never exceed the place's published "Número máximo de visitantes"
-- (server size, set to 30 in Creator Hub to match BitSeas' cap) -- reserved
-- world servers inherit that hard cap, so any capacity above it would be a
-- lie in the browser UI.
local MAX_WORLD_CAPACITY = 30
local JOIN_CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" -- no 0/O/1/I -- easy to read aloud/type

local BK_WorldRegistryService = {}

local function registryKey(worldId)
	return "registry_" .. tostring(worldId)
end

local function joinCodeKey(code)
	return "joincode_" .. tostring(code)
end

local function generateJoinCode()
	local chars = {}
	for _ = 1, 6 do
		local index = math.random(1, #JOIN_CODE_ALPHABET)
		table.insert(chars, JOIN_CODE_ALPHABET:sub(index, index))
	end
	return table.concat(chars)
end

-- Every known world id, oldest first. Kept as one small array under one key
-- -- fine at BitKaisen's expected scale (a world is a deliberate, rare
-- creation, not a per-player object); would need real pagination far beyond
-- what a single DataStore value can hold.
function BK_WorldRegistryService.GetIndex()
	local ok, result = pcall(function()
		return registryStore:GetAsync(INDEX_KEY)
	end)
	if not ok or typeof(result) ~= "table" then
		return {}
	end
	return result
end

function BK_WorldRegistryService.GetWorld(worldId)
	if typeof(worldId) ~= "string" or worldId == "" then
		return nil
	end
	local ok, result = pcall(function()
		return registryStore:GetAsync(registryKey(worldId))
	end)
	if not ok or typeof(result) ~= "table" then
		return nil
	end
	-- Stored records don't carry their own id (it's the key) -- attach it so
	-- callers can build TeleportData.WorldId from any lookup path.
	result.WorldId = worldId
	return result
end

function BK_WorldRegistryService.GetWorldByJoinCode(code)
	if typeof(code) ~= "string" or code == "" then
		return nil
	end
	local ok, worldId = pcall(function()
		return registryStore:GetAsync(joinCodeKey(string.upper(code)))
	end)
	if not ok or typeof(worldId) ~= "string" then
		return nil
	end
	return BK_WorldRegistryService.GetWorld(worldId)
end

-- Every world's summary, for the browser list. Sequential reads -- fine for
-- the expected small number of worlds; would need batching at real scale.
function BK_WorldRegistryService.ListWorlds()
	local index = BK_WorldRegistryService.GetIndex()
	local worlds = {}
	for _, worldId in ipairs(index) do
		local record = BK_WorldRegistryService.GetWorld(worldId)
		if record then
			record.WorldId = worldId
			record.Population = BK_WorldRegistryService.GetPopulation(worldId)
			record.PresentSouls = BK_WorldRegistryService.GetPresentSouls(worldId, 6)
			table.insert(worlds, record)
		end
	end
	return worlds
end

-- Best target for Entrada Rápida: the fullest Open world that still has
-- room, so souls pool together instead of spreading one per server. The
-- optional isJoinable(worldId) callback lets the caller veto candidates the
-- registry can't judge itself (e.g. sealed worlds live in
-- BK_WorldStateService, injected from GameManager -- same dependency
-- pattern as getEraForYear).
function BK_WorldRegistryService.FindOpenWorld(isJoinable)
	local best = nil
	for _, record in ipairs(BK_WorldRegistryService.ListWorlds()) do
		local capacity = tonumber(record.MaxCapacity) or MAX_WORLD_CAPACITY
		local population = tonumber(record.Population) or 0
		if record.Type == "Open" and population < capacity and (not isJoinable or isJoinable(record.WorldId)) then
			if not best or population > (tonumber(best.Population) or 0) then
				best = record
			end
		end
	end
	return best
end

-- Heartbeat from a world's own server -- call every ~60s from that world's
-- GameManager instance, passing the actual present souls (not just a
-- count) so the World Browser can render real avatar bubbles per card
-- (Luisa's BitSeas reference). TTL means a crashed server's entry just
-- expires -- no manual cleanup needed either way.
-- souls: array of { UserId: number, Name: string }
function BK_WorldRegistryService.ReportPopulation(worldId, souls)
	if typeof(worldId) ~= "string" or worldId == "" then
		return
	end
	souls = typeof(souls) == "table" and souls or {}
	pcall(function()
		populationMap:SetAsync(worldId, { Count = #souls, Souls = souls }, POPULATION_TTL_SECONDS)
	end)
end

local function readPopulationEntry(worldId)
	if typeof(worldId) ~= "string" or worldId == "" then
		return nil
	end
	local ok, result = pcall(function()
		return populationMap:GetAsync(worldId)
	end)
	if not ok then
		return nil
	end
	-- Old entries (before this field split) were a bare number -- treat
	-- them as a count with no known souls rather than erroring.
	if typeof(result) == "number" then
		return { Count = result, Souls = {} }
	end
	if typeof(result) == "table" then
		return result
	end
	return nil
end

function BK_WorldRegistryService.GetPopulation(worldId)
	local entry = readPopulationEntry(worldId)
	return entry and tonumber(entry.Count) or 0
end

-- The real souls (UserId + Name) currently present, for rendering avatar
-- bubbles on a world's browser card. Capped small since it's only ever
-- displayed as a handful of headshots, never the full roster.
function BK_WorldRegistryService.GetPresentSouls(worldId, maxCount)
	local entry = readPopulationEntry(worldId)
	local souls = entry and entry.Souls or {}
	local limit = tonumber(maxCount) or 6
	if #souls <= limit then
		return souls
	end
	local trimmed = {}
	for i = 1, limit do
		trimmed[i] = souls[i]
	end
	return trimmed
end

-- Multiplayer Fase 8 (world lifecycle, pedido de Luisa): permanently marks
-- a world as having had at least one real player in it at some point, and
-- refreshes WHEN that last happened -- distinct from the ephemeral 120s-TTL
-- population entry, both live in the registry's DataStore record forever.
-- Lets the Buscador tell apart three cases: a brand-new world nobody has
-- entered yet (hidden after a short grace period), a world with real
-- history that's just quiet right now (still shown -- someone may come
-- back soon), and a world that's been truly dormant for a long time
-- despite once having people (eventually hidden too, per LastPopulatedAt --
-- see the long-dormancy check in GameManager's getWorldBrowser). Call only
-- once per world per server process (see the caller in GameManager) to
-- avoid a redundant UpdateAsync write every heartbeat.
function BK_WorldRegistryService.MarkEverPopulated(worldId)
	if typeof(worldId) ~= "string" or worldId == "" then
		return
	end
	pcall(function()
		registryStore:UpdateAsync(registryKey(worldId), function(old)
			if typeof(old) ~= "table" then
				return old
			end
			local new = table.clone(old)
			new.EverPopulated = true
			new.LastPopulatedAt = os.time()
			return new
		end)
	end)
end

-- Reserves a real server for a brand-new world, generates its join code,
-- and stores its registry record. Does NOT touch BK_WorldStateService --
-- the caller (GameManager) still owns calling GetOrCreate with the chosen
-- starting Era/Year, keeping these two services' responsibilities separate.
-- config: { Name: string?, Type: "Open" | "Code", MinSouls: number,
--           MaxCapacity: number, StartEra: string }
function BK_WorldRegistryService.CreateWorld(founderUserId, config)
	config = typeof(config) == "table" and config or {}

	local ok, accessCode, privateServerId = pcall(function()
		return TeleportService:ReserveServer(game.PlaceId)
	end)
	if not ok then
		warn("[BK_WorldRegistryService] ReserveServer failed: " .. tostring(accessCode))
		return nil, "Could not reserve a server. Try again."
	end

	local worldId = HttpService:GenerateGUID(false)

	local joinCode = nil
	if config.Type == "Code" then
		for _ = 1, 5 do
			local candidate = generateJoinCode()
			if not BK_WorldRegistryService.GetWorldByJoinCode(candidate) then
				joinCode = candidate
				break
			end
		end
		joinCode = joinCode or generateJoinCode()
	end

	local record = {
		Name = tostring(config.Name or "Unnamed World"),
		FounderUserId = founderUserId,
		Type = config.Type == "Code" and "Code" or "Open",
		JoinCode = joinCode,
		MinSouls = math.max(1, tonumber(config.MinSouls) or 1),
		MaxCapacity = math.clamp(tonumber(config.MaxCapacity) or MAX_WORLD_CAPACITY, 1, MAX_WORLD_CAPACITY),
		StartEra = tostring(config.StartEra or "Modern Era"),
		AccessCode = accessCode,
		PrivateServerId = privateServerId,
		CreatedAt = os.time(),
	}

	local writeOk = pcall(function()
		registryStore:SetAsync(registryKey(worldId), record)
	end)
	if not writeOk then
		return nil, "Could not save the new world. Try again."
	end

	if joinCode then
		pcall(function()
			registryStore:SetAsync(joinCodeKey(joinCode), worldId)
		end)
	end

	pcall(function()
		registryStore:UpdateAsync(INDEX_KEY, function(old)
			local index = typeof(old) == "table" and table.clone(old) or {}
			table.insert(index, worldId)
			return index
		end)
	end)

	record.WorldId = worldId
	return record, nil
end

return BK_WorldRegistryService
