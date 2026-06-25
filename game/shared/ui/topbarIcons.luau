local Icon = require("@packages/topbarplus")
local uiState = require("@ui-state/uiState")

local topbarIcons = {}

function topbarIcons.init(panelRefs)
	local settingsIcon = Icon.new()
	settingsIcon:setLabel(utf8.char(0x2699))
	settingsIcon:setRight()
	settingsIcon:setOrder(100)
	settingsIcon:bindEvent("selected", function()
		uiState.navigate("settings")
		settingsIcon:deselect()
	end)

	local godModeIcon = Icon.new()
	godModeIcon:setLabel(utf8.char(0x26A1))
	godModeIcon:setRight()
	godModeIcon:setOrder(101)
	godModeIcon:bindEvent("selected", function()
		if panelRefs.godMode and panelRefs.godMode.open then
			panelRefs.godMode.open()
		end
		godModeIcon:deselect()
	end)

	local warIcon = Icon.new()
	warIcon:setLabel(utf8.char(0x2694))
	warIcon:setRight()
	warIcon:setOrder(102)
	warIcon:setEnabled(false)
	warIcon:bindEvent("selected", function()
		if panelRefs.clanWar and panelRefs.clanWar.open then
			panelRefs.clanWar.open()
		end
		warIcon:deselect()
	end)

	if panelRefs.clanWar and panelRefs.clanWar.isAvailable then
		task.spawn(function()
			while true do
				local ok, avail = pcall(panelRefs.clanWar.isAvailable)
				warIcon:setEnabled(ok and avail == true)
				task.wait(2)
			end
		end)
	end

	local afkIcon = Icon.new()
	afkIcon:setLabel(utf8.char(0x1F4A4))
	afkIcon:setRight()
	afkIcon:setOrder(103)
	afkIcon:bindEvent("selected", function()
		if panelRefs.afk and panelRefs.afk.open then
			panelRefs.afk.open()
		end
		afkIcon:deselect()
	end)
end

return topbarIcons
