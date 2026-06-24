local ReplicatedStorage = game:GetService("ReplicatedStorage")
local vide = require("@packages/vide")
local theme = require("@ui/theme")
local playerState = require("@ui-state/playerState")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local create = vide.create

local function buildTraitDetails(parent: Frame)
	local scroll, title = factory.createCardList(parent, "TRAIT DETAILS")

	local stats = playerState.stats()
	if not stats then
		factory.createMessageCard(scroll, "No character data loaded.")
		return
	end

	local traitSummary = tostring(stats.TraitSummary or "None")
	if traitSummary == "None" or traitSummary == "" then
		factory.createMessageCard(scroll, "You don't have any traits.")
		return
	end

	local traitDefs = nil
	local traitModule = ReplicatedStorage:FindFirstChild("BitKaisenTraits")
	if traitModule then
		local ok, result = pcall(function() return require(traitModule) end)
		if ok then traitDefs = result end
	end

	local traitNames = {}
	for name in string.gmatch(traitSummary, "([^,]+)") do
		local trimmed = string.match(name, "^%s*(.-)%s*$")
		if trimmed and trimmed ~= "" then
			table.insert(traitNames, trimmed)
		end
	end

	for i, traitName in traitNames do
		local def = traitDefs and (traitDefs.Traits and traitDefs.Traits[traitName] or traitDefs[traitName])
		local rarity = def and tostring(def.Rarity or "Common") or "Common"
		local description = def and tostring(def.Description or "") or ""
		local effects = def and def.Effects

		local rarityColor = theme.RarityColors[rarity] or theme.SubText
		local bodyParts = {}
		if description ~= "" then table.insert(bodyParts, description) end
		if effects and typeof(effects) == "table" then
			for stat, val in effects do
				local sign = (tonumber(val) or 0) >= 0 and "+" or ""
				table.insert(bodyParts, stat .. ": " .. sign .. tostring(val))
			end
		end

		factory.createCard(scroll, i, {
			title = traitName,
			subtitle = rarity,
			body = #bodyParts > 0 and table.concat(bodyParts, "\n") or nil,
			accentColor = rarityColor,
		})
	end
end

local function init()
	OverlayPanel.registerPanelBuilder("trait_details", buildTraitDetails)
end

return { init = init }
