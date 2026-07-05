-- Cooldown-based "seen" tracking for the Guide's monetization nudges (see
-- GuideController.luau/MobileGuideController.luau's MONETIZATION_RULES).
--
-- Different from onceFlags.luau (which is a real "seen once, ever, forever"
-- flag -- correct for the tutorial itself): these 4 nudges (low health,
-- broke, losing streak, wants to skip time) all describe situations that can
-- genuinely recur more than once in the same life. A permanent one-shot
-- meant saying "no thanks" once (or just not noticing it in time) silenced
-- it for the rest of that character's life, even if the same real friction
-- point happened again later -- confirmed by Luisa as not making sense.
-- Instead: track the age it last fired at, and allow it again once enough
-- ages have passed, so it can still recur without ever feeling spammy.
local remotes = require("@ui-state/remotes")

local COOLDOWN_AGES = 12 -- 6 years (2 ages per year)

-- A simple monotonically increasing "age unit" count (6-month ticks), not
-- tied to any particular calendar meaning -- just needs to increase by 1 per
-- real age-up so cooldowns can be measured in "ages passed".
local function ageUnit(stats): number
	local age = tonumber(stats.Age) or 0
	local month = tonumber(stats.CurrentMonth) or 1
	return age * 2 + (month > 6 and 1 or 0)
end

local function isOnCooldown(stats, name: string): boolean
	if typeof(stats) ~= "table" then
		return false
	end
	local flags = stats.TutorialFlags
	if typeof(flags) ~= "table" then
		return false
	end
	local lastAge = flags[name .. "LastAge"]
	if typeof(lastAge) ~= "number" then
		return false
	end
	return (ageUnit(stats) - lastAge) < COOLDOWN_AGES
end

local function markShown(stats, name: string)
	local remote = remotes.markTutorialSeen()
	if remote then
		remote:FireServer(name, ageUnit(stats))
	end
end

return { isOnCooldown = isOnCooldown, markShown = markShown }
