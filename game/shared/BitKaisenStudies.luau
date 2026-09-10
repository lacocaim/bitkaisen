-- ModuleScript: BitKaisenStudies
-- Location: ReplicatedStorage
--
-- Update 31: knowledge you accumulate over years, rather than a family you were born into.
--
-- Raised by LavieCovie, twice. First that "Barrier Techniques" should not be a cursed
-- technique at all, because barriers are a discipline you study, with your finesse coming
-- from Smarts. Then that Death Paintings and the Culling Games "should just be locked
-- under an accumulated Study and Knowledge check, requiring one to amass their knowledge
-- for several years, therefore making this feat Brain Transplant exclusive, and not
-- requiring some Kenjaku Clan".
--
-- Both asks are the same missing mechanic, so it is built once. A field of study advances
-- while you work at it, faster if you are clever, and it gates content that should be
-- earned by a life spent learning instead of handed out at birth.

local BitKaisenStudies = {}

-- Years of study, not sessions: a level here is meant to represent a real stretch of a
-- life. Reaching Master is roughly a decade of an adult life spent on one subject.
BitKaisenStudies.LEVELS = {
	{ Id = "none",       Name = "Untrained",  Progress = 0 },
	{ Id = "novice",     Name = "Novice",     Progress = 100 },
	{ Id = "apprentice", Name = "Apprentice", Progress = 260 },
	{ Id = "adept",      Name = "Adept",      Progress = 520 },
	{ Id = "expert",     Name = "Expert",     Progress = 900 },
	{ Id = "master",     Name = "Master",     Progress = 1500 },
}

BitKaisenStudies.FIELDS = {
	{
		Id = "barrier",
		Name = "Barrier Techniques",
		Line = "Curtains, veils and the geometry that holds them. A discipline, not a birthright.",
		MinAge = 14,
		MinSmarts = 25,
	},
	{
		Id = "reincarnation",
		Name = "Reincarnation Theory",
		Line = "What a soul is anchored to, and what it takes to move it. Most who study this are never trusted again.",
		MinAge = 20,
		MinSmarts = 55,
	},
}

local fieldsById = {}
for _, field in ipairs(BitKaisenStudies.FIELDS) do
	fieldsById[field.Id] = field
end

function BitKaisenStudies.GetField(fieldId)
	return fieldsById[tostring(fieldId or "")]
end

function BitKaisenStudies.EnsureStudies(stats)
	if typeof(stats) ~= "table" then
		return {}
	end
	if typeof(stats.Studies) ~= "table" then
		stats.Studies = {}
	end
	for _, field in ipairs(BitKaisenStudies.FIELDS) do
		local entry = stats.Studies[field.Id]
		if typeof(entry) ~= "table" then
			entry = { Progress = 0, Years = 0 }
			stats.Studies[field.Id] = entry
		end
		entry.Progress = math.max(0, tonumber(entry.Progress) or 0)
		entry.Years = math.max(0, tonumber(entry.Years) or 0)
	end
	return stats.Studies
end

-- Reading progress must never mutate. The client renders this inside a reactive block on
-- its replicated copy of the stats, and having a read call EnsureStudies there would write
-- into that copy on every redraw.
function BitKaisenStudies.GetProgress(stats, fieldId): number
	local studies = typeof(stats) == "table" and typeof(stats.Studies) == "table" and stats.Studies or nil
	local entry = studies and studies[tostring(fieldId or "")]
	if typeof(entry) ~= "table" then
		return 0
	end
	return math.max(0, tonumber(entry.Progress) or 0)
end

-- Returns the level table, never nil, so callers can read .Name without checking.
function BitKaisenStudies.GetLevel(stats, fieldId)
	local progress = BitKaisenStudies.GetProgress(stats, fieldId)
	local current = BitKaisenStudies.LEVELS[1]
	for _, level in ipairs(BitKaisenStudies.LEVELS) do
		if progress >= level.Progress then
			current = level
		end
	end
	return current
end

function BitKaisenStudies.GetNextLevel(stats, fieldId)
	local progress = BitKaisenStudies.GetProgress(stats, fieldId)
	for _, level in ipairs(BitKaisenStudies.LEVELS) do
		if progress < level.Progress then
			return level
		end
	end
	return nil
end

-- True once the field has reached the named level or better.
function BitKaisenStudies.IsAtLeast(stats, fieldId, levelId): boolean
	local wanted, current = nil, BitKaisenStudies.GetProgress(stats, fieldId)
	for _, level in ipairs(BitKaisenStudies.LEVELS) do
		if level.Id == tostring(levelId or "") then
			wanted = level
		end
	end
	if not wanted then
		return false
	end
	return current >= wanted.Progress
end

-- Smarts decide how much a stretch of study is worth, so the clever sorcerer gets there in
-- fewer years and nobody gets there without spending them.
function BitKaisenStudies.GetSessionGain(stats, fieldId): number
	local smarts = math.clamp(tonumber(stats and stats.Smarts) or 0, 0, 100)
	local base = 26 + math.floor(smarts * 0.55)
	local level = BitKaisenStudies.GetLevel(stats, fieldId)
	-- The last stretch is the slow one. Expert to Master should feel like a wall.
	if level.Id == "expert" then
		base = math.floor(base * 0.7)
	elseif level.Id == "adept" then
		base = math.floor(base * 0.85)
	end
	return math.max(8, base)
end

-- Returns: gained, leveledUpTo (or nil), newLevel
function BitKaisenStudies.Study(stats, fieldId)
	local field = BitKaisenStudies.GetField(fieldId)
	if not field then
		return 0, nil, nil
	end
	local studies = BitKaisenStudies.EnsureStudies(stats)
	local entry = studies[field.Id]
	local before = BitKaisenStudies.GetLevel(stats, field.Id)
	local gain = BitKaisenStudies.GetSessionGain(stats, field.Id)

	entry.Progress += gain
	entry.Years += 1

	local after = BitKaisenStudies.GetLevel(stats, field.Id)
	local leveled = (after.Id ~= before.Id) and after or nil
	return gain, leveled, after
end

function BitKaisenStudies.CanStudy(stats, fieldId): (boolean, string?)
	local field = BitKaisenStudies.GetField(fieldId)
	if not field then
		return false, "That is not something you can study."
	end
	local age = tonumber(stats and stats.Age) or 0
	if age < field.MinAge then
		return false, field.Name .. " is not something you can begin before " .. tostring(field.MinAge) .. "."
	end
	local smarts = tonumber(stats and stats.Smarts) or 0
	if smarts < field.MinSmarts then
		return false, "You need " .. tostring(field.MinSmarts) .. " Smarts to follow " .. field.Name .. "."
	end
	if BitKaisenStudies.IsAtLeast(stats, field.Id, "master") then
		return false, "You have taken " .. field.Name .. " as far as it goes."
	end
	return true, nil
end

return BitKaisenStudies
