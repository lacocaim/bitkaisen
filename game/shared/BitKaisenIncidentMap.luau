local BitKaisenStats = require(script.Parent:WaitForChild("BitKaisenStats"))

local BitKaisenIncidentMap = {}

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

function BitKaisenIncidentMap.BuildPayload(stats)
	local map = BitKaisenIncidentMap.EnsureMapState(stats)
	if not map then
		return {
			Error = "Your life data is not loaded yet.",
			Locations = {},
			Actions = {},
		}
	end

	local isCursedSpirit = BitKaisenIncidentMap.IsCursedSpirit(stats)
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

	return {
		Role = isCursedSpirit and "CursedSpirit" or "Sorcerer",
		RoleLabel = isCursedSpirit and "Cursed Spirit" or "Sorcerer",
		SocietyStatus = tostring(stats.SocietyStatus or "Unknown"),
		CurrentTerritory = tostring(stats.CurseTerritory or "None"),
		ActionsTaken = map.ActionsTaken,
		Locations = locations,
		Actions = actions,
	}
end

return BitKaisenIncidentMap
