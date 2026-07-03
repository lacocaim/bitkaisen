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

return {
	entries = entries,
	version = version,
	register = register,
	registerBatch = registerBatch,
	unregister = unregister,
	getEntries = getEntries,
	select = select,
}
