local BitKaisenStats = require(script.Parent:WaitForChild("BitKaisenStats"))

local BitKaisenIncidentMap = {}

-- Presentation data for the map board, kept here rather than in either panel so the
-- desktop and the phone cannot drift apart. That drift is not hypothetical: the combat
-- power figures added to the dossier in Update 30 shipped on desktop only because the
-- phone had its own copy of the same widget.
--
-- The Tokyo image is built from OpenStreetMap data, restyled dark. OpenStreetMap is open
-- data and free to use commercially, on the condition that it is credited. That is what
-- the line in the corner of the board is for. Do not remove it.
BitKaisenIncidentMap.MAP_IMAGE = "rbxassetid://125198338888042"
BitKaisenIncidentMap.MAP_CREDIT = "Map data (c) OpenStreetMap contributors"

-- The map image is 1024x572. Pins are placed in that image's own normalised space so
-- they stay glued to the geography at any screen size.
BitKaisenIncidentMap.MAP_ASPECT = 1024 / 572

-- Roughly where each incident sits on Tokyo Metropolis: the mountainous Okutama/Tama
-- side is west (low X), the dense wards and the bay are east (high X). Rural Village and
-- Forest Shrine are the two western ones, which is also why they are the high-threat pair.
BitKaisenIncidentMap.MAP_POINTS = {
	rural_village         = Vector2.new(0.12, 0.42),
	forest_shrine         = Vector2.new(0.23, 0.56),
	construction_site     = Vector2.new(0.44, 0.47),
	abandoned_school      = Vector2.new(0.55, 0.38),
	old_apartment_complex = Vector2.new(0.60, 0.56),
	closed_mall           = Vector2.new(0.66, 0.34),
	apartment_stairwell   = Vector2.new(0.69, 0.63),
	sewer_tunnel          = Vector2.new(0.73, 0.49),
	hospital_basement     = Vector2.new(0.77, 0.41),
	underpass             = Vector2.new(0.76, 0.60),
	last_train_station    = Vector2.new(0.82, 0.50),
	burned_out_theater    = Vector2.new(0.72, 0.70),
}

-- Where the travelling marker rests before you send it anywhere: Tokyo Jujutsu High,
-- roughly west of the ward belt.
BitKaisenIncidentMap.HOME_POINT = Vector2.new(0.38, 0.30)

-- Artwork slots. An empty entry is deliberate, not a missing file: drop a Roblox asset id
-- in and it appears in game with no other change. The five site photographs are Creative
-- Commons Attribution, which is free to use and modify commercially provided the credit
-- stays visible, which is what CREDITS is for.
BitKaisenIncidentMap.LOCATION_ART = {
	abandoned_school      = "",
	forest_shrine         = "",
	last_train_station    = "rbxassetid://130862244840347",
	hospital_basement     = "rbxassetid://125237072867846",
	construction_site     = "rbxassetid://140563163782352",
	old_apartment_complex = "",
	rural_village         = "",
	sewer_tunnel          = "rbxassetid://99316352645992",
	closed_mall           = "",
	apartment_stairwell   = "",
	burned_out_theater    = "",
	underpass             = "rbxassetid://138242076990791",
}

BitKaisenIncidentMap.LOCATION_CREDITS = {
	last_train_station = "Photo: Rex Roof (CC BY)",
	hospital_basement  = "Photo: janbommes (CC BY)",
	construction_site  = "Photo: takomabibelot (CC BY)",
	sewer_tunnel       = "Photo: darkday (CC BY)",
	underpass          = "Photo: ell brown (CC BY)",
}

BitKaisenIncidentMap.SHIKIGAMI_ART = {
	["Divine Dogs"]   = "",
	["Nue"]           = "",
	["Toad"]          = "",
	["Great Serpent"] = "",
	["Max Elephant"]  = "",
	["Rabbit Escape"] = "",
	["Round Deer"]    = "",
	["Piercing Ox"]   = "",
	["Tiger Funeral"] = "",
	["Mahoraga"]      = "",
}

-- An unfilled slot above is an empty string, and an empty string is truthy in Lua, so a
-- plain `if art then` builds the frame anyway and shows an empty box. That is exactly what
-- happened to the shikigami hover card. Every read of the art tables goes through this.
function BitKaisenIncidentMap.ArtId(value): string?
	local id = tostring(value or "")
	return id ~= "" and id or nil
end

local RUMORS = {
	"The Hallway That Adds Another Door",
	"The Last Train Has No Driver",
	"The Basement Patient Who Never Left",
	"The Apartment That Breathes at Midnight",
	"The Shrine Bell That Rings Underground",
	"The Worker Standing Above the Crane",
	"The Voice Beneath the Sewer Grate",
	"The Village Where Every Dog Went Silent",
	"The Closed Mall's Thirteenth Floor",
	"The Footsteps Between Apartment Landings",
	"The Actor Still Bowing in the Burned Theater",
	"The Shadow Waiting Under the Underpass",
}

local LOCATIONS = {
	{
		Id = "abandoned_school",
		Name = "Abandoned School",
		Description = "Empty classrooms hold the residue of old fear and unfinished grudges.",
		RecommendedGrade = "Grade 3",
		Threat = 34,
		Fear = 42,
		SocietyAttention = 18,
		CursedResidue = 46,
	},
	{
		Id = "last_train_station",
		Name = "Last Train Station",
		Description = "A deserted platform where commuters hear a train after service ends.",
		RecommendedGrade = "Grade 2",
		Threat = 48,
		Fear = 55,
		SocietyAttention = 32,
		CursedResidue = 52,
	},
	{
		Id = "hospital_basement",
		Name = "Hospital Basement",
		Description = "Sealed treatment rooms gather grief faster than the wards can disperse it.",
		RecommendedGrade = "Grade 2",
		Threat = 56,
		Fear = 61,
		SocietyAttention = 38,
		CursedResidue = 66,
	},
	{
		Id = "old_apartment_complex",
		Name = "Old Apartment Complex",
		Description = "Thin walls carry arguments, whispers, and footsteps between empty units.",
		RecommendedGrade = "Grade 3",
		Threat = 39,
		Fear = 51,
		SocietyAttention = 24,
		CursedResidue = 43,
	},
	{
		Id = "forest_shrine",
		Name = "Forest Shrine",
		Description = "Broken wards surround a shrine that villagers stopped visiting years ago.",
		RecommendedGrade = "Grade 1",
		Threat = 68,
		Fear = 58,
		SocietyAttention = 47,
		CursedResidue = 75,
	},
	{
		Id = "construction_site",
		Name = "Construction Site",
		Description = "Repeated accidents have made the unfinished tower a magnet for resentment.",
		RecommendedGrade = "Grade 2",
		Threat = 51,
		Fear = 44,
		SocietyAttention = 41,
		CursedResidue = 57,
	},
	{
		Id = "sewer_tunnel",
		Name = "Sewer Tunnel",
		Description = "Something follows maintenance crews through passages missing from city plans.",
		RecommendedGrade = "Grade 2",
		Threat = 59,
		Fear = 64,
		SocietyAttention = 29,
		CursedResidue = 70,
	},
	{
		Id = "rural_village",
		Name = "Rural Village",
		Description = "A quiet settlement hides a pattern of disappearances behind local superstition.",
		RecommendedGrade = "Grade 1",
		Threat = 72,
		Fear = 67,
		SocietyAttention = 53,
		CursedResidue = 62,
	},
	{
		Id = "closed_mall",
		Name = "Closed Mall",
		Description = "Mannequins change positions beneath emergency lights after every patrol.",
		RecommendedGrade = "Grade 2",
		Threat = 54,
		Fear = 60,
		SocietyAttention = 36,
		CursedResidue = 59,
	},
	{
		Id = "apartment_stairwell",
		Name = "Apartment Stairwell",
		Description = "Residents avoid a landing that appears only when nobody else is watching.",
		RecommendedGrade = "Grade 3",
		Threat = 37,
		Fear = 49,
		SocietyAttention = 21,
		CursedResidue = 41,
	},
	{
		Id = "burned_out_theater",
		Name = "Burned-Out Theater",
		Description = "Applause echoes from a stage destroyed before its final performance.",
		RecommendedGrade = "Grade 1",
		Threat = 75,
		Fear = 70,
		SocietyAttention = 58,
		CursedResidue = 81,
	},
	{
		Id = "underpass",
		Name = "Underpass",
		Description = "A commuter shortcut has become a hunting ground after sunset.",
		RecommendedGrade = "Grade 2",
		Threat = 50,
		Fear = 56,
		SocietyAttention = 35,
		CursedResidue = 54,
	},
}

local LOCATION_BY_ID = {}
for _, definition in ipairs(LOCATIONS) do
	LOCATION_BY_ID[definition.Id] = definition
end

local SORCERER_ACTIONS = {
	{ Id = "investigate", Name = "INVESTIGATE" },
	{ Id = "search_residue", Name = "SEARCH RESIDUE" },
	{
		Id = "exorcise_threat",
		Name = "EXORCISE THREAT",
		IsLocked = function(stats)
			return (tonumber(stats.CursedEnergy) or 0) < 10, "Requires at least 10 cursed energy."
		end,
	},
	{ Id = "protect_civilians", Name = "PROTECT CIVILIANS" },
}

local CURSED_SPIRIT_ACTIONS = {
	{ Id = "claim_haunt", Name = "CLAIM HAUNT" },
	{ Id = "feed_fear", Name = "FEED ON FEAR" },
	{ Id = "spread_rumor", Name = "SPREAD RUMOR" },
	{ Id = "hide_residue", Name = "HIDE RESIDUE" },
	{ Id = "move_territory", Name = "MOVE TERRITORY" },
	{
		Id = "ambush_investigator",
		Name = "AMBUSH INVESTIGATOR",
		IsLocked = function(stats)
			return (tonumber(stats.CurseThreat) or 0) < 10, "Requires at least 10 curse threat."
		end,
	},
}

local function clamp(value, fallback)
	return math.clamp(tonumber(value) or fallback or 0, 0, 100)
end

local function actionList(stats)
	if BitKaisenIncidentMap.IsCursedSpirit(stats) then
		return CURSED_SPIRIT_ACTIONS
	end
	return SORCERER_ACTIONS
end

function BitKaisenIncidentMap.IsCursedSpirit(stats)
	return BitKaisenStats.IsCurseLife(stats)
end

function BitKaisenIncidentMap.GetLocationDefinition(locationId)
	return LOCATION_BY_ID[tostring(locationId or "")]
end

function BitKaisenIncidentMap.GetRandomRumor(definition)
	local index = math.random(1, #RUMORS)
	if definition and definition.Id then
		local offset = 0
		for i, location in ipairs(LOCATIONS) do
			if location.Id == definition.Id then
				offset = i - 1
				break
			end
		end
		index = ((index + offset - 1) % #RUMORS) + 1
	end
	return RUMORS[index]
end

function BitKaisenIncidentMap.EnsureMapState(stats)
	if typeof(stats) ~= "table" then
		return nil
	end

	if typeof(stats.IncidentMap) ~= "table" then
		stats.IncidentMap = {}
	end

	local map = stats.IncidentMap
	map.ActionsTaken = math.max(0, math.floor(tonumber(map.ActionsTaken) or 0))
	if typeof(map.Locations) ~= "table" then
		map.Locations = {}
	end

	for index, definition in ipairs(LOCATIONS) do
		local state = map.Locations[definition.Id]
		if typeof(state) ~= "table" then
			state = {}
			map.Locations[definition.Id] = state
		end

		state.Threat = clamp(state.Threat, definition.Threat)
		state.Fear = clamp(state.Fear, definition.Fear)
		state.SocietyAttention = clamp(state.SocietyAttention, definition.SocietyAttention)
		state.CursedResidue = clamp(state.CursedResidue, definition.CursedResidue)
		state.Control = clamp(state.Control, 0)
		state.ControlledBy = tostring(state.ControlledBy or "Unclaimed")
		state.Rumor = tostring(state.Rumor or RUMORS[index])
		state.LastResult = tostring(state.LastResult or "")
		state.ActiveIncident = state.Threat >= 35
	end

	return map
end

function BitKaisenIncidentMap.GetActionDefinition(stats, actionId)
	actionId = tostring(actionId or "")
	for _, action in ipairs(actionList(stats)) do
		if action.Id == actionId then
			return action
		end
	end
	return nil
end

function BitKaisenIncidentMap.IsActionAvailable(stats, actionId)
	local action = BitKaisenIncidentMap.GetActionDefinition(stats, actionId)
	if not action then
		return false, "That Incident Map action is not available."
	end
	if action.IsLocked then
		local locked, reason = action.IsLocked(stats)
		if locked then
			return false, reason or "That Incident Map action is locked."
		end
	end
	return true
end

-- Update 30 -- shikigami on the map.
-- The Ten Shadows roster already assigns each shikigami a combat posture (see
-- SHIKIGAMI_POSTURES in BK_CombatService), and those three postures translate straight
-- into three jobs a shikigami can do while it is standing on a site instead of standing
-- next to you. Guard suppresses, Hunt sharpens exorcism, Scout reveals.
local SHIKIGAMI_ROLES = {
	["Divine Dogs"]   = { Role = "Guard", Effect = "Holds the site. Threat falls while it stands there." },
	["Max Elephant"]  = { Role = "Guard", Effect = "Holds the site. Threat falls while it stands there." },
	["Nue"]           = { Role = "Hunt",  Effect = "Hunts the site. Exorcism bites harder here." },
	["Great Serpent"] = { Role = "Hunt",  Effect = "Hunts the site. Exorcism bites harder here." },
	["Piercing Ox"]   = { Role = "Hunt",  Effect = "Hunts the site. Exorcism bites harder here." },
	["Tiger Funeral"] = { Role = "Hunt",  Effect = "Hunts the site. Exorcism bites harder here." },
	["Toad"]          = { Role = "Scout", Effect = "Watches the site. Residue and rumors surface faster." },
	["Rabbit Escape"] = { Role = "Scout", Effect = "Watches the site. Residue and rumors surface faster." },
	["Round Deer"]    = { Role = "Scout", Effect = "Watches the site. Residue and rumors surface faster." },
	["Mahoraga"]      = { Role = "Guard", Effect = "Adapts to the site. Threat collapses, and so does everything near it." },
}

function BitKaisenIncidentMap.GetShikigamiRole(name)
	local entry = SHIKIGAMI_ROLES[tostring(name or "")]
	if not entry then
		return "Scout", "Watches the site."
	end
	return entry.Role, entry.Effect
end

function BitKaisenIncidentMap.GetTamedNames(stats)
	if typeof(stats) ~= "table" or typeof(stats.TamedShikigamiNames) ~= "table" then
		return {}
	end
	return stats.TamedShikigamiNames
end

-- Keyed by shikigami name so one shadow can only ever stand in one place.
function BitKaisenIncidentMap.EnsureShikigamiState(stats)
	if typeof(stats) ~= "table" then
		return {}
	end
	if typeof(stats.ShikigamiDeployments) ~= "table" then
		stats.ShikigamiDeployments = {}
	end

	-- A save can outlive the thing it points at: the life may have lost the shikigami, or
	-- the location id may no longer exist. Drop those rather than pinning a ghost.
	local owned = {}
	for _, name in ipairs(BitKaisenIncidentMap.GetTamedNames(stats)) do
		owned[tostring(name)] = true
	end
	for name, locationId in pairs(stats.ShikigamiDeployments) do
		if not owned[tostring(name)] or not LOCATION_BY_ID[tostring(locationId)] then
			stats.ShikigamiDeployments[name] = nil
		end
	end

	return stats.ShikigamiDeployments
end

function BitKaisenIncidentMap.CountDeployed(stats)
	local deployments = BitKaisenIncidentMap.EnsureShikigamiState(stats)
	local count = 0
	for _ in pairs(deployments) do
		count += 1
	end
	return count
end

-- Shikigami Master (Update 29) already means "hold two postures at once" in combat. On
-- the map it means the same promise: two shadows out instead of one.
function BitKaisenIncidentMap.GetDeployLimit(stats)
	return (stats and stats.HasShikigamiMasterPass == true) and 2 or 1
end

-- The Incident Map is a modern institution: a jujutsu-society case board over present-day
-- Tokyo, with a closed shopping mall and a construction site on it. A Heian life has no
-- business opening it, and now that the map is actually drawn the anachronism shows.
-- Modern activities are already era-blocked the same way (see BK_ActivityService).
-- The fallback chain has to match getCurrentEra in BK_ActivityService exactly. Reading
-- only CurrentEra and Era looked right and passed on a normal life, but a life that
-- carries its era in BirthEra or BirthPath.Era fell through to "Modern Era" and opened
-- present-day Tokyo on a Heian character, while activities blocked it correctly.
function BitKaisenIncidentMap.IsEraBlocked(stats)
	if typeof(stats) ~= "table" then
		return false
	end
	local birthPath = typeof(stats.BirthPath) == "table" and stats.BirthPath or nil
	local era = tostring(
		stats.CurrentEra
			or stats.Era
			or stats.BirthEra
			or (birthPath and birthPath.Era)
			or "Modern Era"
	)
	return era == "Heian Era"
end

function BitKaisenIncidentMap.BuildPayload(stats)
	local map = BitKaisenIncidentMap.EnsureMapState(stats)
	if not map then
		return {
			Error = "Your life data is not loaded yet.",
			Locations = {},
			Actions = {},
		}
	end

	if BitKaisenIncidentMap.IsEraBlocked(stats) then
		return {
			Error = "The Incident Map does not exist in this era. Jujutsu society keeps no case board yet.",
			Locations = {},
			Actions = {},
		}
	end

	local isCursedSpirit = BitKaisenIncidentMap.IsCursedSpirit(stats)

	local deployments = BitKaisenIncidentMap.EnsureShikigamiState(stats)
	local shikigamiAt = {}
	for name, locationId in pairs(deployments) do
		shikigamiAt[tostring(locationId)] = tostring(name)
	end

	local locations = {}
	for _, definition in ipairs(LOCATIONS) do
		local state = map.Locations[definition.Id]
		table.insert(locations, {
			Id = definition.Id,
			Name = definition.Name,
			Description = definition.Description,
			RecommendedGrade = definition.RecommendedGrade,
			Threat = state.Threat,
			Fear = state.Fear,
			SocietyAttention = state.SocietyAttention,
			CursedResidue = state.CursedResidue,
			Control = state.Control,
			ControlledBy = state.ControlledBy,
			Rumor = state.Rumor,
			ActiveIncident = state.ActiveIncident,
			LastResult = state.LastResult,
			Shikigami = shikigamiAt[definition.Id],
		})
	end

	local actions = {}
	for _, action in ipairs(actionList(stats)) do
		local locked = false
		local lockReason = nil
		if action.IsLocked then
			locked, lockReason = action.IsLocked(stats)
		end
		table.insert(actions, {
			Id = action.Id,
			Name = action.Name,
			Locked = locked,
			LockReason = lockReason,
		})
	end

	-- Cursed spirits do not command the Ten Shadows, so they simply get an empty roster and
	-- the client draws no rail at all.
	local roster = {}
	if not isCursedSpirit then
		for _, rawName in ipairs(BitKaisenIncidentMap.GetTamedNames(stats)) do
			local name = tostring(rawName)
			local role, effect = BitKaisenIncidentMap.GetShikigamiRole(name)
			table.insert(roster, {
				Name = name,
				Role = role,
				Effect = effect,
				DeployedTo = deployments[name],
			})
		end
	end

	return {
		Role = isCursedSpirit and "CursedSpirit" or "Sorcerer",
		RoleLabel = isCursedSpirit and "Cursed Spirit" or "Sorcerer",
		SocietyStatus = tostring(stats.SocietyStatus or "Unknown"),
		CurrentTerritory = tostring(stats.CurseTerritory or "None"),
		ActionsTaken = map.ActionsTaken,
		Locations = locations,
		Actions = actions,
		Shikigami = roster,
		DeployLimit = BitKaisenIncidentMap.GetDeployLimit(stats),
		DeployedCount = BitKaisenIncidentMap.CountDeployed(stats),
	}
end

return BitKaisenIncidentMap
