local vide = require("@packages/vide")
local uiState = require("@ui-state/uiState")

type NavEntry = {
	id: string,
	label: string,
	order: number,
	color: Color3?,
	visible: (() -> boolean)?,
}

local entries = vide.source({} :: { NavEntry })
local version = vide.source(0)

local function register(entry: NavEntry)
	local list = table.clone(entries())
	for i, e in list do
		if e.id == entry.id then
			list[i] = entry
			entries(list)
			version(version() + 1)
			return
		end
	end
	table.insert(list, entry)
	table.sort(list, function(a, b) return a.order < b.order end)
	entries(list)
	version(version() + 1)
end

-- Registers many entries in a single reactive update instead of one per
-- entry. Firing register() N times in a row (e.g. at client boot) bumps
-- `version` N times back-to-back before anything yields, and the NavPanel's
-- `indexes()` list can drop the second-to-last item when it reconciles that
-- many rapid-fire size changes in one frame. Doing it once avoids the churn.
local function registerBatch(newEntries: { NavEntry })
	local list = table.clone(entries())
	for _, entry in newEntries do
		local replaced = false
		for i, e in list do
			if e.id == entry.id then
				list[i] = entry
				replaced = true
				break
			end
		end
		if not replaced then
			table.insert(list, entry)
		end
	end
	table.sort(list, function(a, b) return a.order < b.order end)
	entries(list)
	version(version() + 1)
end

local function unregister(id: string)
	local list = table.clone(entries())
	for i, e in list do
		if e.id == id then
			table.remove(list, i)
			entries(list)
			version(version() + 1)
			return
		end
	end
end

local function getEntries(): { NavEntry }
	local _ = version()
	return entries()
end

local function select(id: string)
	uiState.navigate(id)
end

-- Update 30 -- Simple nav bar.
-- The bar carried fifteen equally weighted entries, and that is what players actually
-- complained about: "I like the UI but its kinda a lot to have to find each". Simple
-- mode keeps the core life-sim loop on the bar and folds everything else behind one
-- MORE entry -- the same trick QuickMenuPanel already uses for the topbar icons.
-- Nothing is removed and no panel changes; only which buttons the bar draws.
local MORE_ID = "nav_more"

local PRIMARY_IDS = {
	missions = true,
	activities = true,
	relationships = true,
	assets = true,
	jobs = true,
}

local simpleMode = vide.source(true)

-- Plain callbacks rather than a vide effect: NavPanel builds its buttons eagerly and
-- outside any reactive scope (see the comment there), so it needs a signal it can
-- subscribe to imperatively.
local modeListeners: { () -> () } = {}

local function isPrimary(id: string): boolean
	return PRIMARY_IDS[id] == true
end

-- Whether this entry belongs on the bar right now. MORE exists only in simple mode.
local function isEntryVisible(id: string): boolean
	if id == MORE_ID then
		return simpleMode()
	end
	if not simpleMode() then
		return true
	end
	return isPrimary(id)
end

local function setSimpleMode(value: boolean)
	local wanted = value == true
	if simpleMode() == wanted then
		return
	end
	simpleMode(wanted)
	version(version() + 1)
	for _, fn in modeListeners do
		task.spawn(fn)
	end
end

local function onModeChanged(fn: () -> ()): () -> ()
	table.insert(modeListeners, fn)
	return function()
		for i, listener in modeListeners do
			if listener == fn then
				table.remove(modeListeners, i)
				return
			end
		end
	end
end

-- The entries hidden from the bar in simple mode, in registered order. MORE itself is
-- not one of them, or opening MORE would list MORE.
local function getOverflowEntries(): { NavEntry }
	local list = {}
	for _, entry in getEntries() do
		if entry.id ~= MORE_ID and not isPrimary(entry.id) then
			table.insert(list, entry)
		end
	end
	return list
end

return {
	entries = entries,
	version = version,
	register = register,
	registerBatch = registerBatch,
	unregister = unregister,
	getEntries = getEntries,
	select = select,

	MORE_ID = MORE_ID,
	simpleMode = simpleMode,
	setSimpleMode = setSimpleMode,
	isPrimary = isPrimary,
	isEntryVisible = isEntryVisible,
	onModeChanged = onModeChanged,
	getOverflowEntries = getOverflowEntries,
}
