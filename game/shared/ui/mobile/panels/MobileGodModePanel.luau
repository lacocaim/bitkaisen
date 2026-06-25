local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local mc = require("@ui/mobile/mobileComponents")

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
		text = "PERMANENT LIFE CONTROLS",
		size = 15,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	if not data.Owned then
		mc.mobileLabel({
			parent = summaryCard,
			text = "Unlock God Mode to use trait edits, clan rerolls, start boosts, legacy inheritance, and reset life controls.",
			size = 13,
			color = theme.SubText,
			order = 2,
		})
		mc.mobileButton({
			parent = summaryCard,
			text = "UNLOCK",
			color = theme.Purple,
			order = 3,
			callback = function()
				if tonumber(data.PassId) and data.PassId > 0 then
					MarketplaceService:PromptGamePassPurchase(player, data.PassId)
				end
			end,
		})
		return
	end

	mc.mobileLabel({
		parent = summaryCard,
		text = "Tune traits, clan rerolls, start boosts, legacy inheritance, and reset the current life while keeping God Mode settings.",
		size = 13,
		color = theme.SubText,
		order = 2,
	})

	local settings = data.Settings or {}

	local boostCard = mc.mobileCard({ parent = scroll, order = 2 })
	mc.mobileLabel({
		parent = boostCard,
		text = "START BOOST",
		size = 15,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})
	mc.mobileLabel({
		parent = boostCard,
		text = "Pick one boost for the start of each fresh life. Current: " .. tostring(settings.StartBoost or "None"),
		size = 13,
		color = theme.SubText,
		order = 2,
	})

	local boosts = { { "NONE", "None" }, { "CE", "CE" }, { "STATS", "Stats" }, { "LUCK", "Luck" } }
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
		text = "CHILD TRAITS",
		size = 15,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})
	mc.mobileLabel({
		parent = legacyCard,
		text = "Guaranteed Legacy Traits: " .. (settings.GuaranteedLegacyTraits and "ON" or "OFF"),
		size = 13,
		color = theme.SubText,
		order = 2,
	})
	mc.mobileButton({
		parent = legacyCard,
		text = settings.GuaranteedLegacyTraits and "TURN OFF" or "TURN ON",
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
		text = "CLAN CONTROL",
		size = 15,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})
	mc.mobileLabel({
		parent = clanCard,
		text = tostring(data.CurrentClan or "Unknown") .. " • " .. tostring(data.ClanRerollsUsed or 0) .. "/" .. tostring(data.ClanRerollsMax or 3) .. " rerolls used.",
		size = 13,
		color = theme.SubText,
		order = 2,
	})

	mc.mobileButton({
		parent = clanCard,
		text = "REROLL CLAN",
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
		text = "PICK CLAN",
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
		text = "TRAIT EDITOR",
		size = 15,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})
	mc.mobileLabel({
		parent = traitCard,
		text = "Add " .. tostring(data.TraitAddsUsed or 0) .. "/" .. tostring(data.TraitAddsMax or 2) .. " • Remove " .. tostring(data.TraitRemovesUsed or 0) .. "/" .. tostring(data.TraitRemovesMax or 2),
		size = 13,
		color = theme.SubText,
		order = 2,
	})

	local traitBox = Instance.new("TextBox")
	traitBox.Size = UDim2.new(1, 0, 0, 44)
	traitBox.BackgroundColor3 = theme.Card
	traitBox.BorderSizePixel = 0
	traitBox.PlaceholderText = "Type trait name or id"
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
		text = "ADD TRAIT",
		color = theme.Green,
		textColor = theme.Bg,
		order = 4,
		callback = function()
			fire("add_trait", { TraitName = traitBox.Text })
		end,
	})
	mc.mobileButton({
		parent = traitCard,
		text = "REMOVE TRAIT",
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
		text = "Current: " .. (#ownedNames > 0 and table.concat(ownedNames, ", ") or "None"),
		size = 12,
		color = theme.Muted,
		order = 6,
	})

	local resetCard = mc.mobileCard({ parent = scroll, order = 6 })
	mc.mobileLabel({
		parent = resetCard,
		text = "RESET LIFE",
		size = 15,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})
	mc.mobileLabel({
		parent = resetCard,
		text = "Restart current life instantly. God Mode settings stay, but current-life uses reset.",
		size = 13,
		color = theme.SubText,
		order = 2,
	})
	mc.mobileButton({
		parent = resetCard,
		text = "RESET LIFE",
		color = theme.Orange,
		order = 3,
		callback = function()
			fire("reset_life")
			sheet.Visible = false
		end,
	})
end

local function init()
	gui = Instance.new("ScreenGui")
	gui.Name = "MobileGodModeGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 641
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Enabled = false
	gui.Parent = playerGui

	sheet = mc.mobileSheet({
		name = "MobileGodModeSheet",
		parent = gui,
		title = "GOD MODE",
		onClose = function()
			sheet.Visible = false
			gui.Enabled = false
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
end

local function open()
	if not gui then return end
	fetchPayload()
	render()
	sheet.Visible = true
	gui.Enabled = true
end

return { init = init, open = open }
