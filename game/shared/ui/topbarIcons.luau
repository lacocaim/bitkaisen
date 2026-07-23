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
local QuickMenuPanel = require("@ui-panels/QuickMenuPanel")

local topbarIcons = {}
local settingsIconRef = nil

-- Used by GuideController to point a monetization suggestion at the gear
-- icon (Settings -> Shop is the only place these products are purchasable).
-- Same direct-reference technique as the rest of this module -- see
-- FocusHighlight.luau for the inset-correction fix that makes highlighting
-- any topbar icon actually land in the right place.
function topbarIcons.getSettingsIconSpot(): GuiObject?
	if not settingsIconRef then
		return nil
	end
	local ok, spot = pcall(function()
		return settingsIconRef:getInstance("IconSpot")
	end)
	if ok and spot and spot:IsA("GuiObject") then
		return spot
	end
	return nil
end

function topbarIcons.init(panelRefs)
	if not Icon or not Icon.new then
		warn("[topbarIcons] Icon module missing or has no .new - cannot create topbar icons")
		return
	end
	local settingsIcon = Icon.new()
	settingsIconRef = settingsIcon
	settingsIcon:setLabel(utf8.char(0x2699))
	settingsIcon:setRight()
	settingsIcon:setOrder(100)
	settingsIcon:bindEvent("selected", function()
		overlayManager.closeAll()
		uiState.navigate("settings")
		settingsIcon:deselect()
	end)

	-- God Mode, Clan War, Cult War, and AFK used to each have their own
	-- always-visible topbar icon. Folded into one "MENU" icon (see
	-- QuickMenuPanel.luau) since none of them are tapped often enough to
	-- earn a permanent slot, and having every system as its own icon was
	-- exactly the crowded-topbar complaint (BitSeas/BitShinobi keep only a
	-- couple of icons visible and put the rest behind a menu). NOTE: the
	-- label must be an emoji -- plain glyphs like the U+2630 hamburger
	-- aren't in Roblox's fonts and render as the ugly tofu box.
	QuickMenuPanel.init(panelRefs)
	local menuIcon = Icon.new()
	menuIcon:setLabel(utf8.char(0x1F4CB))
	menuIcon:setRight()
	menuIcon:setOrder(101)
	menuIcon:bindEvent("selected", function()
		QuickMenuPanel.open()
		menuIcon:deselect()
	end)

	-- Help & Guide gets its own permanent icon (pulled back OUT of the
	-- quick menu per Luisa) -- new players need it visible, not buried.
	local helpIcon = Icon.new()
	helpIcon:setLabel(utf8.char(0x2753))
	helpIcon:setRight()
	helpIcon:setOrder(102)
	helpIcon:bindEvent("selected", function()
		if panelRefs.helpGuide then
			overlayManager.show("helpGuide", panelRefs.helpGuide.open, panelRefs.helpGuide.close)
		end
		helpIcon:deselect()
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

	-- Lives (the "souls" route) gets its own permanent icon rather than
	-- staying only in the NavPanel grid -- on Mobile it was nav order 13 of
	-- 13, meaning reaching it required scrolling all the way down inside the
	-- cramped 162px NavAnchor scrollbox (only 6 of 13 entries show without
	-- scrolling). Nested scroll gestures are notoriously unreliable on real
	-- touchscreens, so a player could tap around that area and have nothing
	-- happen -- same reasoning Luisa already gave for pulling Help & Guide
	-- out of a buried menu into its own icon.
	local livesIcon = Icon.new()
	livesIcon:setLabel(utf8.char(0x1F465))
	livesIcon:setRight()
	livesIcon:setOrder(98)
	livesIcon:bindEvent("selected", function()
		uiState.navigate("souls")
		livesIcon:deselect()
	end)

end

return topbarIcons
