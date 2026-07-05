-- Shared "seen it once" tracking, wrapping the stats.TutorialFlags / MarkTutorialSeen
-- pattern already used by the onboarding tutorial (see FirstTimeGuidancePanel.luau's
-- tutorialAlreadySeen/markSeen). Server-side persistence lives in
-- GameManager.server.luau's MarkTutorialSeen.OnServerEvent handler, which does
-- `stats.TutorialFlags[name .. "Seen"] = true` -- this module is just the
-- client-side read/write pair for that same flag, reused by Fase 5 (Consejos)
-- and Fase 6 (monetization offer) instead of duplicating the check by hand.
local remotes = require("@ui-state/remotes")

local function isSeen(stats, name: string): boolean
	if typeof(stats) ~= "table" then
		return false
	end

	local flags = stats.TutorialFlags
	if typeof(flags) ~= "table" then
		return false
	end

	return flags[name .. "Seen"] == true
end

local function markSeen(name: string)
	local remote = remotes.markTutorialSeen()
	if remote then
		remote:FireServer(name)
	end
end

return { isSeen = isSeen, markSeen = markSeen }
