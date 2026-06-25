local Icon = require("@packages/topbarplus")
local uiState = require("@ui-state/uiState")
local overlayManager = require("@ui-state/overlayManager")

local topbarIcons = {}

function topbarIcons.init(panelRefs)
	local settingsIcon = Icon.new()
	settingsIcon:setLabel(utf8.char(0x2699))
	settingsIcon:setRight()
	settingsIcon:setOrder(100)
	settingsIcon:bindEvent("selected", function()
		overlayManager.closeAll()
		uiState.navigate("settings")
		settingsIcon:deselect()
	end)

	local godModeIcon = Icon.new()
	godModeIcon:setLabel(utf8.char(0x26A1))
	godModeIcon:setRight()
	godModeIcon:setOrder(101)
	godModeIcon:bindEvent("selected", function()
		if panelRefs.godMode then
			overlayManager.show("godMode", panelRefs.godMode.open, panelRefs.godMode.close)
		end
		godModeIcon:deselect()
	end)

	local warIcon = Icon.new()
	warIcon:setLabel(utf8.char(0x2694))
	warIcon:setRight()
	warIcon:setOrder(102)
	warIcon:setEnabled(false)
	warIcon:bindEvent("selected", function()
		if panelRefs.clanWar then
			overlayManager.show("clanWar", panelRefs.clanWar.open, panelRefs.clanWar.close)
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
		if panelRefs.afk then
			overlayManager.show("afk", panelRefs.afk.open, panelRefs.afk.close)
		end
		afkIcon:deselect()
	end)
end

return topbarIcons
