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
	unregister = unregister,
	getEntries = getEntries,
	select = select,
}
