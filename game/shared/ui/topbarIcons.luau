local iconOk, Icon = pcall(require, "@packages/topbarplus")
if not iconOk then
	local packagesFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Packages")
	if packagesFolder then
		local topbarplusMod = packagesFolder:FindFirstChild("topbarplus")
		if topbarplusMod then
			iconOk, Icon = pcall(require, topbarplusMod)
		end
	end
end
if not iconOk then
	warn("[topbarIcons] Could not load TopbarPlus: " .. tostring(Icon))
	Icon = nil
end
local uiState = require("@ui-state/uiState")
local overlayManager = require("@ui-state/overlayManager")

local topbarIcons = {}

function topbarIcons.init(panelRefs)
	if not Icon or not Icon.new then
		warn("[topbarIcons] Icon module missing or has no .new - cannot create topbar icons")
		return
	end
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
	warIcon:bindEvent("selected", function()
		if panelRefs.clanWar then
			overlayManager.show("clanWar", panelRefs.clanWar.open, panelRefs.clanWar.close)
		end
		warIcon:deselect()
	end)

	local cultWarIcon = Icon.new()
	cultWarIcon:setLabel(utf8.char(0x1F480))
	cultWarIcon:setRight()
	cultWarIcon:setOrder(104)
	cultWarIcon:bindEvent("selected", function()
		if panelRefs.cultWar then
			overlayManager.show("cultWar", panelRefs.cultWar.open, panelRefs.cultWar.close)
		end
		cultWarIcon:deselect()
	end)

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

	local freeRewardsIcon = Icon.new()
	freeRewardsIcon:setLabel(utf8.char(0x1F381))
	freeRewardsIcon:setRight()
	freeRewardsIcon:setOrder(99)
	freeRewardsIcon:bindEvent("selected", function()
		if panelRefs.freeRewards then
			overlayManager.show("freeRewards", panelRefs.freeRewards.open, panelRefs.freeRewards.close)
		end
		freeRewardsIcon:deselect()
	end)

	-- How To Play (replay tutorial) + Guide toggle. Kept separate from the
	-- settings gear (⚙) since neither is a QoL toggle -- see memory
	-- project-bitkaisen-tutorial-system for why these two are grouped
	-- together but distinct from Settings.
	local helpGuideIcon = Icon.new()
	helpGuideIcon:setLabel(utf8.char(0x2753))
	helpGuideIcon:setRight()
	helpGuideIcon:setOrder(98)
	helpGuideIcon:bindEvent("selected", function()
		if panelRefs.helpGuide then
			overlayManager.show("helpGuide", panelRefs.helpGuide.open, panelRefs.helpGuide.close)
		end
		helpGuideIcon:deselect()
	end)

end

return topbarIcons
