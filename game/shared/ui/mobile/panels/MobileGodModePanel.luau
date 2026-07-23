local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local mc = require("@ui/mobile/mobileComponents")
local overlayManager = require("@ui-state/overlayManager")
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _gm(key, fallback) return BitKaisenLocale.tOrFallback(_L, "god_mode." .. key, nil, fallback) end
local function _gmp(key, params, fallback)
	local s = _gm(key, fallback)
	if params then for k, v in pairs(params) do s = s:gsub("{" .. k .. "}", tostring(v)) end end
	return s
end

local theme = mc.theme
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local getGodMode = ReplicatedStorage:WaitForChild("GetGodMode")
local godModeAction = ReplicatedStorage:WaitForChild("GodModeAction")

local GOD_MODE_GAMEPASS_ID = 1861509054

local gui: ScreenGui
local sheet: Frame
local scroll: ScrollingFrame
local payload = nil

local function clearList()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
end

local render

local function fetchPayload()
	local ok, result = pcall(function()
		return getGodMode:InvokeServer()
	end)
	if ok and typeof(result) == "table" then
		payload = result
	else
		payload = { Owned = false, Error = "Could not load God Mode." }
	end
	return payload
end

local function fire(actionId, data)
	godModeAction:FireServer(actionId, data or {})
	task.delay(0.25, function()
		fetchPayload()
		if sheet and sheet.Visible then
			render()
		end
	end)
end

render = function()
	clearList()
	local data = payload or fetchPayload()

	local summaryCard = mc.mobileCard({ parent = scroll, order = 1 })
	mc.mobileLabel({
		parent = summaryCard,
		text = _gm("section_controls", "PERMANENT LIFE CONTROLS"),
		size = 15,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	if not data.Owned then
		-- Multiplayer Fase 8 (Fair Play Doctrine): the account-wide gamepass
		-- never applies inside a Public world, so a different purchase
		-- path (and explicit "only this world" copy) shows up there
		-- instead of the normal one -- never both.
		if data.IsPublic then
			mc.mobileLabel({
				parent = summaryCard,
				text = _gm("locked_desc_public", "This unlock applies ONLY to the Public world you're in right now -- not your account, not any other world. Buy it again separately for each Public world you want it in."),
				size = 13,
				color = theme.SubText,
				order = 2,
			})
			mc.mobileButton({
				parent = summaryCard,
				text = _gm("btn_unlock_public", "UNLOCK FOR THIS WORLD"),
				color = theme.Purple,
				order = 3,
				callback = function()
					if tonumber(data.GodModeThisWorldProductId) and data.GodModeThisWorldProductId > 0 then
						MarketplaceService:PromptProductPurchase(player, data.GodModeThisWorldProductId)
					end
				end,
			})
		else
			mc.mobileLabel({
				parent = summaryCard,
				text = _gm("locked_desc", "Unlock God Mode to use trait edits, clan rerolls, start boosts, legacy inheritance, and reset life controls."),
				size = 13,
				color = theme.SubText,
				order = 2,
			})
			mc.mobileButton({
				parent = summaryCard,
				text = _gm("btn_unlock", "UNLOCK"),
				color = theme.Purple,
				order = 3,
				callback = function()
					if tonumber(data.PassId) and data.PassId > 0 then
						MarketplaceService:PromptGamePassPurchase(player, data.PassId)
					end
				end,
			})
		end
		return
	end

	mc.mobileLabel({
		parent = summaryCard,
		text = _gm("owned_desc", "Tune traits, clan rerolls, start boosts, legacy inheritance, and reset the current life while keeping God Mode settings."),
		size = 13,
		color = theme.SubText,
		order = 2,
	})

	local settings = data.Settings or {}

	local boostCard = mc.mobileCard({ parent = scroll, order = 2 })
	mc.mobileLabel({
		parent = boostCard,
		text = _gm("section_boost", "START BOOST"),
		size = 15,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})
	mc.mobileLabel({
		parent = boostCard,
		text = _gmp("boost_desc", {current = tostring(settings.StartBoost or "None")}, "Pick one boost for the start of each fresh life. Current: " .. tostring(settings.StartBoost or "None")),
		size = 13,
		color = theme.SubText,
		order = 2,
	})

	local boosts = { { _gm("boost_none","NONE"), "None" }, { "CE", "CE" }, { _gm("boost_stats","STATS"), "Stats" }, { _gm("boost_luck","LUCK"), "Luck" } }
	for idx, option in ipairs(boosts) do
		mc.mobileButton({
			parent = boostCard,
			text = option[1],
			color = option[2] == settings.StartBoost and theme.Green or theme.Purple,
			textColor = option[2] == settings.StartBoost and theme.Bg or theme.Text,
			order = idx + 2,
			callback = function()
				fire("set_start_boost", { Choice = option[2] })
			end,
		})
	end

	local legacyCard = mc.mobileCard({ parent = scroll, order = 3 })
	mc.mobileLabel({
		parent = legacyCard,
		text = _gm("section_legacy", "CHILD TRAITS"),
		size = 15,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})
	mc.mobileLabel({
		parent = legacyCard,
		text = _gmp("legacy_desc", {status = settings.GuaranteedLegacyTraits and _gm("legacy_on","ON") or _gm("legacy_off","OFF")}, "Guaranteed Legacy Traits: " .. (settings.GuaranteedLegacyTraits and "ON" or "OFF")),
		size = 13,
		color = theme.SubText,
		order = 2,
	})
	mc.mobileButton({
		parent = legacyCard,
		text = settings.GuaranteedLegacyTraits and _gm("btn_turn_off","TURN OFF") or _gm("btn_turn_on","TURN ON"),
		color = settings.GuaranteedLegacyTraits and theme.Bad or theme.Green,
		textColor = settings.GuaranteedLegacyTraits and theme.Text or theme.Bg,
		order = 3,
		callback = function()
			fire("toggle_legacy_traits", { Enabled = not settings.GuaranteedLegacyTraits })
		end,
	})

	local clanOptions = data.ClanOptions or {}
	local clanCard = mc.mobileCard({ parent = scroll, order = 4 })
	mc.mobileLabel({
		parent = clanCard,
		text = _gm("section_clan", "CLAN CONTROL"),
		size = 15,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})
	mc.mobileLabel({
		parent = clanCard,
		text = _gmp("clan_rerolls", {clan = tostring(data.CurrentClan or "Unknown"), used = tostring(data.ClanRerollsUsed or 0), max = tostring(data.ClanRerollsMax or 3)}, tostring(data.CurrentClan or "Unknown") .. " • " .. tostring(data.ClanRerollsUsed or 0) .. "/" .. tostring(data.ClanRerollsMax or 3) .. " rerolls used."),
		size = 13,
		color = theme.SubText,
		order = 2,
	})

	mc.mobileButton({
		parent = clanCard,
		text = _gm("btn_reroll_clan", "REROLL CLAN"),
		color = theme.Purple,
		order = 3,
		callback = function()
			fire("reroll_clan")
		end,
	})

	local clanBox = Instance.new("TextBox")
	clanBox.Size = UDim2.new(1, 0, 0, 44)
	clanBox.BackgroundColor3 = theme.Card
	clanBox.BorderSizePixel = 0
	clanBox.PlaceholderText = "Gojo / Zenin / ..."
	clanBox.Text = ""
	clanBox.TextColor3 = theme.Text
	clanBox.PlaceholderColor3 = theme.Muted
	clanBox.Font = Enum.Font.GothamBold
	clanBox.TextSize = 14
	clanBox.ClearTextOnFocus = false
	clanBox.LayoutOrder = 4
	clanBox.Parent = clanCard
	mc.corner(clanBox, 10)

	mc.mobileButton({
		parent = clanCard,
		text = _gm("btn_pick_clan", "PICK CLAN"),
		color = theme.Green,
		textColor = theme.Bg,
		order = 5,
		callback = function()
			fire("select_clan", { ClanName = clanBox.Text })
		end,
	})

	if #clanOptions > 0 then
		for idx, clan in ipairs(clanOptions) do
			mc.mobileButton({
				parent = clanCard,
				text = tostring(clan.Name or "Unknown") .. " (" .. tostring(clan.Category or "Clan") .. ")",
				color = theme.Button,
				textSize = 13,
				order = idx + 5,
				callback = function()
					fire("select_clan", { ClanName = clan.FamilyName or clan.Name })
				end,
			})
		end
	end

	local traitCard = mc.mobileCard({ parent = scroll, order = 5 })
	mc.mobileLabel({
		parent = traitCard,
		text = _gm("section_trait_ed", "TRAIT EDITOR"),
		size = 15,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})
	mc.mobileLabel({
		parent = traitCard,
		text = _gmp("trait_usage", {adds = tostring(data.TraitAddsUsed or 0), maxAdds = tostring(data.TraitAddsMax or 2), removes = tostring(data.TraitRemovesUsed or 0), maxRemoves = tostring(data.TraitRemovesMax or 2)}, "Add " .. tostring(data.TraitAddsUsed or 0) .. "/" .. tostring(data.TraitAddsMax or 2) .. " • Remove " .. tostring(data.TraitRemovesUsed or 0) .. "/" .. tostring(data.TraitRemovesMax or 2)),
		size = 13,
		color = theme.SubText,
		order = 2,
	})

	local traitBox = Instance.new("TextBox")
	traitBox.Size = UDim2.new(1, 0, 0, 44)
	traitBox.BackgroundColor3 = theme.Card
	traitBox.BorderSizePixel = 0
	traitBox.PlaceholderText = _gm("trait_placeholder", "Type trait name or id")
	traitBox.Text = ""
	traitBox.TextColor3 = theme.Text
	traitBox.PlaceholderColor3 = theme.Muted
	traitBox.Font = Enum.Font.GothamBold
	traitBox.TextSize = 14
	traitBox.ClearTextOnFocus = false
	traitBox.LayoutOrder = 3
	traitBox.Parent = traitCard
	mc.corner(traitBox, 10)

	mc.mobileButton({
		parent = traitCard,
		text = _gm("btn_add_trait", "ADD TRAIT"),
		color = theme.Green,
		textColor = theme.Bg,
		order = 4,
		callback = function()
			fire("add_trait", { TraitName = traitBox.Text })
		end,
	})
	mc.mobileButton({
		parent = traitCard,
		text = _gm("btn_remove_trait", "REMOVE TRAIT"),
		color = theme.Bad,
		order = 5,
		callback = function()
			fire("remove_trait", { TraitName = traitBox.Text })
		end,
	})

	local ownedNames = {}
	for _, trait in ipairs(data.CurrentTraits or {}) do
		table.insert(ownedNames, trait.Name .. " [" .. trait.Rarity .. "]")
	end
	mc.mobileLabel({
		parent = traitCard,
		text = _gmp("trait_current", {list = #ownedNames > 0 and table.concat(ownedNames, ", ") or _gm("trait_none","None")}, "Current: " .. (#ownedNames > 0 and table.concat(ownedNames, ", ") or "None")),
		size = 12,
		color = theme.Muted,
		order = 6,
	})

	local resetCard = mc.mobileCard({ parent = scroll, order = 6 })
	mc.mobileLabel({
		parent = resetCard,
		text = _gm("section_reset", "RESET LIFE"),
		size = 15,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})
	mc.mobileLabel({
		parent = resetCard,
		text = _gm("reset_desc", "Restart current life instantly. God Mode settings stay, but current-life uses reset."),
		size = 13,
		color = theme.SubText,
		order = 2,
	})
	mc.mobileButton({
		parent = resetCard,
		text = _gm("btn_reset_life", "RESET LIFE"),
		color = theme.Orange,
		order = 3,
		callback = function()
			fire("reset_life")
			sheet.Visible = false
		end,
	})
end

local function close()
	if not gui then return end
	if sheet then sheet.Visible = false end
	gui.Enabled = false
end

local function init()
	gui = Instance.new("ScreenGui")
	gui.Name = "MobileGodModeGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 641
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Enabled = false
	gui.Parent = playerGui

	sheet = mc.mobileSheet({
		name = "MobileGodModeSheet",
		parent = gui,
		title = _gm("title", "GOD MODE"),
		onClose = function()
			close()
			overlayManager.closeAll()
		end,
	})

	scroll = sheet:FindFirstChildOfClass("ScrollingFrame")
	sheet.Visible = false

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(purchasePlayer, purchasedPassId, wasPurchased)
		if purchasePlayer ~= player then return end
		if purchasedPassId ~= GOD_MODE_GAMEPASS_ID then return end
		task.delay(0.5, function()
			fetchPayload()
			if sheet and sheet.Visible then
				render()
			end
		end)
	end)

	-- Refreshes after the "God Mode (This World)" Dev Product purchase.
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(purchasePlayer, purchasedProductId, wasPurchased)
		if purchasePlayer ~= player or wasPurchased ~= true then return end
		if not payload or purchasedProductId ~= tonumber(payload.GodModeThisWorldProductId) then return end
		task.delay(0.5, function()
			fetchPayload()
			if sheet and sheet.Visible then
				render()
			end
		end)
	end)
end

local function open()
	if not gui then return end
	fetchPayload()
	render()
	sheet.Visible = true
	gui.Enabled = true
end

return { init = init, open = open, close = close }
