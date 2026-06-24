local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local GROUP_ORDER = { "Clan", "Dojo", "Teachers", "Students", "Rivals", "Notable" }

local function buildAffiliations(parent: Frame)
	local scroll, title = factory.createCardList(parent, "AFFILIATIONS")

	local getRelationships = remotes.getRelationships()
	if not getRelationships then
		factory.createMessageCard(scroll, "Affiliations unavailable.")
		return
	end

	local ok, relationships = pcall(function() return getRelationships:InvokeServer() end)
	if not ok or typeof(relationships) ~= "table" then
		factory.createMessageCard(scroll, "Failed to load affiliations.")
		return
	end

	local groups = {}
	for _, grp in GROUP_ORDER do groups[grp] = {} end

	for _, rel in relationships do
		local role = tostring(rel.Role or "")
		if string.find(role, "Clan", 1, true) then table.insert(groups.Clan, rel)
		elseif string.find(role, "Dojo", 1, true) or string.find(role, "Master", 1, true) then table.insert(groups.Dojo, rel)
		elseif string.find(role, "Teacher", 1, true) or string.find(role, "Mentor", 1, true) then table.insert(groups.Teachers, rel)
		elseif string.find(role, "Student", 1, true) then table.insert(groups.Students, rel)
		elseif string.find(role, "Rival", 1, true) then table.insert(groups.Rivals, rel)
		elseif (tonumber(rel.Bond) or 0) >= 50 or (tonumber(rel.Respect) or 0) >= 50 then table.insert(groups.Notable, rel)
		end
	end

	local order = 1
	for _, grpName in GROUP_ORDER do
		local members = groups[grpName]
		if members and #members > 0 then
			factory.createCard(scroll, order, {
				title = grpName,
				subtitle = tostring(#members) .. " member" .. (#members > 1 and "s" or ""),
				accentColor = theme.Purple,
			})
			order += 1
			for _, rel in members do
				factory.createCard(scroll, order, {
					title = tostring(rel.Name or "Unknown"),
					body = tostring(rel.Role or "") .. " | Bond " .. tostring(rel.Bond or 0),
					actions = (rel.Alive ~= false) and {
						{ label = "Hang Out", callback = function()
							local ra = remotes.relationshipAction()
							if ra then ra:FireServer("Hang Out", rel.Id or rel.Name) end
						end },
					} or nil,
				})
				order += 1
			end
		end
	end

	if order == 1 then
		factory.createMessageCard(scroll, "No affiliations yet.")
	end
end

local function init()
	OverlayPanel.registerPanelBuilder("affiliations", buildAffiliations)
end

return { init = init }
