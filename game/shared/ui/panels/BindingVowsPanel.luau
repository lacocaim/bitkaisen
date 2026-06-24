local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local factory = require("@ui-panels/panelFactory")
local navRegistry = require("@ui-state/navRegistry")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local function buildBindingVows(parent: Frame)
	local scroll, title = factory.createCardList(parent, "BINDING VOWS")

	local getBindingVows = remotes.getBindingVows()
	if not getBindingVows then
		factory.createMessageCard(scroll, "Binding Vows system unavailable.")
		return
	end

	local ok, payload = pcall(function() return getBindingVows:InvokeServer() end)
	if not ok or typeof(payload) ~= "table" then
		factory.createMessageCard(scroll, "Failed to load binding vows.")
		return
	end

	local activeVows = payload.Active or {}
	local availableVows = payload.Available or {}
	local order = 1

	if #activeVows > 0 then
		factory.createCard(scroll, order, { title = "Active Vows", accentColor = theme.Purple })
		order += 1
		for _, vow in activeVows do
			factory.createCard(scroll, order, {
				title = tostring(vow.Name or "Unknown Vow"),
				subtitle = tostring(vow.Effect or ""),
				body = "Cost: " .. tostring(vow.Cost or "None"),
				accentColor = theme.Purple,
				actions = vow.CanBreak and {
					{ label = "BREAK", callback = function()
						local bva = remotes.bindingVowAction()
						if bva then bva:FireServer("break", vow.Id) end
					end },
				} or nil,
			})
			order += 1
		end
	end

	if #availableVows > 0 then
		factory.createCard(scroll, order, { title = "Available Vows", accentColor = theme.Gold })
		order += 1
		for _, vow in availableVows do
			factory.createCard(scroll, order, {
				title = tostring(vow.Name or "Unknown Vow"),
				subtitle = "Benefit: " .. tostring(vow.Benefit or ""),
				body = "Restriction: " .. tostring(vow.Restriction or ""),
				accentColor = theme.Gold,
				actions = {
					{ label = "TAKE VOW", callback = function()
						local bva = remotes.bindingVowAction()
						if bva then bva:FireServer("take", vow.Id) end
					end },
				},
			})
			order += 1
		end
	end

	if order == 1 then
		factory.createMessageCard(scroll, "No binding vows available yet.")
	end
end

local function init()
	OverlayPanel.registerPanelBuilder("binding_vows", buildBindingVows)
end

return { init = init }
