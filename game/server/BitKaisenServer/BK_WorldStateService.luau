-- ModuleScript: BK_WorldStateService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose:
--   Multiplayer Fase 1 (Fundaciones): owns the shared, per-world state for
--   Public mode -- currently just Era/Year -- stored globally (not keyed per
--   player), separate from the normal per-account ProfileStore save system.
--   Only one world exists for now (DEFAULT_PUBLIC_WORLD_ID in
--   GameManager.server.luau); Fase 4 introduces real multi-world creation.
--   Fase 2 ("El Repique") added AdvanceYear -- the shared calendar now moves
--   forward via collective vote/backup clock in GameManager, not just once
--   at creation.
--   Fase 3 ("Mundo con memoria y final") added Events (a short shared
--   history log) and Sealed (frozen once the world hits its year limit --
--   see SEALED_WORLD_AGE_YEARS in GameManager).
--   Fase 5 ("Exclusividad") added LegendaryTraitOwners -- which of the 13
--   Legendary-rarity traits (BitKaisenTraits.luau) are currently claimed by
--   a living character in this world, and by whom.

local DataStoreService = game:GetService("DataStoreService")

local worldStateStore = DataStoreService:GetDataStore("BK_WorldState")

local BK_WorldStateService = {}

local function worldKey(worldId)
	return "world_" .. tostring(worldId)
end

-- Only reads. Returns nil if the world has never been created.
function BK_WorldStateService.Get(worldId)
	if typeof(worldId) ~= "string" or worldId == "" then
		return nil
	end

	local ok, result = pcall(function()
		return worldStateStore:GetAsync(worldKey(worldId))
	end)

	if not ok then
		warn("[BK_WorldStateService] Get failed for " .. tostring(worldId) .. ": " .. tostring(result))
		return nil
	end

	if typeof(result) ~= "table" then
		return nil
	end

	return result
end

-- Reads the world record, creating it with default Era/Year if it doesn't
-- exist yet. Safe to call from multiple players joining the same world at
-- once -- UpdateAsync's transform function only writes the default once.
-- `startYear`/`startEra` are only used the first time a world is created
-- (Fase 4: the founder picks a starting Era); omit both for the old
-- Modern Era/2000 default, still used by the single-world Fase 1 fallback.
function BK_WorldStateService.GetOrCreate(worldId, startYear, startEra)
	if typeof(worldId) ~= "string" or worldId == "" then
		return nil
	end

	local resolvedStartYear = tonumber(startYear) or 2000
	local resolvedStartEra = tostring(startEra or "Modern Era")

	local ok, result = pcall(function()
		return worldStateStore:UpdateAsync(worldKey(worldId), function(old)
			if typeof(old) == "table" then
				return old
			end
			return {
				Era = resolvedStartEra,
				Year = resolvedStartYear,
				-- Multiplayer Fase 2 (catch-up): the world's initial Year,
				-- kept immutable through AdvanceYear -- lets GameManager
				-- compute "how many years has this world been running" for
				-- a late joiner's starting bonus (Year - StartYear).
				StartYear = resolvedStartYear,
				FoundedAt = os.time(),
				-- Multiplayer Fase 3: shared event log + frozen-world flag.
				Events = {},
				Sealed = false,
				-- Multiplayer Fase 5: who currently holds each Legendary trait.
				LegendaryTraitOwners = {},
			}
		end)
	end)

	if not ok then
		warn("[BK_WorldStateService] GetOrCreate failed for " .. tostring(worldId) .. ": " .. tostring(result))
		return nil
	end

	return result
end

-- Multiplayer Fase 2: advances the shared calendar by one year, recomputing
-- Era from the new Year. `getEraForYear` is injected (a plain function
-- taking a numeric year, returning an era name string) rather than
-- duplicated here -- GameManager.server.luau already owns
-- CHARACTER_ERA_TIMELINE, the single source of truth for era boundaries.
function BK_WorldStateService.AdvanceYear(worldId, getEraForYear)
	if typeof(worldId) ~= "string" or worldId == "" then
		return nil
	end
	if typeof(getEraForYear) ~= "function" then
		return nil
	end

	local ok, result = pcall(function()
		return worldStateStore:UpdateAsync(worldKey(worldId), function(old)
			local base = typeof(old) == "table" and old or {
				Era = "Modern Era",
				Year = 2000,
				StartYear = 2000,
				FoundedAt = os.time(),
				Events = {},
				Sealed = false,
				LegendaryTraitOwners = {},
			}

			-- Multiplayer Fase 3: a sealed world is frozen -- no-op instead
			-- of silently ticking the calendar forward past its own end.
			if base.Sealed == true then
				return base
			end

			local newYear = (tonumber(base.Year) or 2000) + 1
			-- Multiplayer Fase 7 refactor: clone-then-set (same pattern as
			-- every other mutator here) instead of rebuilding the record as a
			-- fresh table literal -- the old literal silently dropped any
			-- field it didn't explicitly re-list, which already bit us once
			-- (LegendaryTraitOwners, Fase 5) and would have wiped Fase 7's
			-- Cells/Territories/Wars on every advance.
			local new = table.clone(base)
			new.Era = getEraForYear(newYear)
			new.Year = newYear
			-- StartYear never changes once a world is founded. base.Year
			-- covers records saved before this field existed.
			new.StartYear = base.StartYear or base.Year or 2000
			new.FoundedAt = base.FoundedAt or os.time()
			return new
		end)
	end)

	if not ok then
		warn("[BK_WorldStateService] AdvanceYear failed for " .. tostring(worldId) .. ": " .. tostring(result))
		return nil
	end

	return result
end

-- Multiplayer Fase 7: generic safe mutator for per-world data owned by
-- other services (player cells, territories, wars -- see BK_CellService).
-- transform receives a CLONE of the record and mutates/returns it; unknown
-- fields always survive because the base is cloned, never rebuilt. Keeps
-- this file from growing one bespoke UpdateAsync wrapper per Fase 7 verb.
function BK_WorldStateService.Mutate(worldId, transform)
	if typeof(worldId) ~= "string" or worldId == "" then
		return nil
	end
	if typeof(transform) ~= "function" then
		return nil
	end

	local ok, result = pcall(function()
		return worldStateStore:UpdateAsync(worldKey(worldId), function(old)
			local base = typeof(old) == "table" and old or {
				Era = "Modern Era",
				Year = 2000,
				StartYear = 2000,
				FoundedAt = os.time(),
				Events = {},
				Sealed = false,
				LegendaryTraitOwners = {},
			}
			local new = transform(table.clone(base))
			return typeof(new) == "table" and new or base
		end)
	end)

	if not ok then
		warn("[BK_WorldStateService] Mutate failed for " .. tostring(worldId) .. ": " .. tostring(result))
		return nil
	end

	return result
end

-- Multiplayer Fase 3: appends one line to the world's shared event log,
-- trimmed to the most recent 20 -- meant for genuinely world-level moments
-- (an Era shift, the Sello Final), not per-player flavor text.
function BK_WorldStateService.AddEvent(worldId, year, text)
	if typeof(worldId) ~= "string" or worldId == "" then
		return nil
	end
	if typeof(text) ~= "string" or text == "" then
		return nil
	end

	local ok, result = pcall(function()
		return worldStateStore:UpdateAsync(worldKey(worldId), function(old)
			local base = typeof(old) == "table" and old or {
				Era = "Modern Era",
				Year = 2000,
				StartYear = 2000,
				FoundedAt = os.time(),
				Events = {},
				Sealed = false,
				LegendaryTraitOwners = {},
			}
			local events = typeof(base.Events) == "table" and table.clone(base.Events) or {}
			table.insert(events, { Year = tonumber(year) or base.Year, Text = text })
			while #events > 20 do
				table.remove(events, 1)
			end

			local new = table.clone(base)
			new.Events = events
			return new
		end)
	end)

	if not ok then
		warn("[BK_WorldStateService] AddEvent failed for " .. tostring(worldId) .. ": " .. tostring(result))
		return nil
	end

	return result
end

-- Multiplayer Fase 3: freezes the world once its year limit is reached.
-- Idempotent -- safe to call even if it's already sealed.
function BK_WorldStateService.SealWorld(worldId)
	if typeof(worldId) ~= "string" or worldId == "" then
		return nil
	end

	local ok, result = pcall(function()
		return worldStateStore:UpdateAsync(worldKey(worldId), function(old)
			local base = typeof(old) == "table" and old or {
				Era = "Modern Era",
				Year = 2000,
				StartYear = 2000,
				FoundedAt = os.time(),
				Events = {},
				Sealed = false,
				LegendaryTraitOwners = {},
			}
			local new = table.clone(base)
			new.Sealed = true
			return new
		end)
	end)

	if not ok then
		warn("[BK_WorldStateService] SealWorld failed for " .. tostring(worldId) .. ": " .. tostring(result))
		return nil
	end

	return result
end

-- Multiplayer Fase 5 ("Exclusividad"): only writes the claim if the slot is
-- free or already held by this same userId -- protects against a race
-- (two players rolling the same Legendary at once) overwriting whoever won.
-- Returns true if this userId ends up holding it, false otherwise.
function BK_WorldStateService.ClaimLegendaryTrait(worldId, traitId, userId, characterName)
	if typeof(worldId) ~= "string" or worldId == "" then
		return false
	end
	if typeof(traitId) ~= "string" or traitId == "" then
		return false
	end

	local claimed = false
	local ok = pcall(function()
		worldStateStore:UpdateAsync(worldKey(worldId), function(old)
			local base = typeof(old) == "table" and old or {
				Era = "Modern Era",
				Year = 2000,
				StartYear = 2000,
				FoundedAt = os.time(),
				Events = {},
				Sealed = false,
				LegendaryTraitOwners = {},
			}
			local owners = typeof(base.LegendaryTraitOwners) == "table" and table.clone(base.LegendaryTraitOwners) or {}
			local current = owners[traitId]
			if current == nil or current.UserId == userId then
				owners[traitId] = { UserId = userId, CharacterName = tostring(characterName or "Unknown") }
				claimed = true
			end

			local new = table.clone(base)
			new.LegendaryTraitOwners = owners
			return new
		end)
	end)

	if not ok then
		warn("[BK_WorldStateService] ClaimLegendaryTrait failed for " .. tostring(worldId) .. "/" .. tostring(traitId))
		return false
	end

	return claimed
end

-- Only clears the slot if the current owner recorded is this same userId --
-- protects against releasing (and freeing up) a claim that belongs to
-- someone else due to stale/out-of-order calls.
function BK_WorldStateService.ReleaseLegendaryTrait(worldId, traitId, userId)
	if typeof(worldId) ~= "string" or worldId == "" then
		return
	end
	if typeof(traitId) ~= "string" or traitId == "" then
		return
	end

	pcall(function()
		worldStateStore:UpdateAsync(worldKey(worldId), function(old)
			if typeof(old) ~= "table" then
				return old
			end
			local owners = typeof(old.LegendaryTraitOwners) == "table" and table.clone(old.LegendaryTraitOwners) or {}
			local current = owners[traitId]
			if current and current.UserId == userId then
				owners[traitId] = nil
			end

			local new = table.clone(old)
			new.LegendaryTraitOwners = owners
			return new
		end)
	end)
end

function BK_WorldStateService.GetLegendaryTraitOwners(worldId)
	local world = BK_WorldStateService.Get(worldId)
	if not world or typeof(world.LegendaryTraitOwners) ~= "table" then
		return {}
	end
	return world.LegendaryTraitOwners
end

return BK_WorldStateService
