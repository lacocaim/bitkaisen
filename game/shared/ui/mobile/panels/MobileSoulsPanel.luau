-- Multiplayer Fase 6 ("Reunión de Vidas"): Mobile mirror of SoulsPanel.luau
-- -- the "SOULS" nav tab listing every real player living in your Public
-- world, with per-soul actions (signal, gift money; duels arrive with Fase
-- 6B). Modeled on MobileRivalsPanel.luau (mobileSheet + card list).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local uiState = require("@ui-state/uiState")
local mc = require("@ui/mobile/mobileComponents")
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _g(key, fallback) return BitKaisenLocale.tOrFallback(_L, "souls." .. key, nil, fallback) end

local theme = mc.theme
local mobileButton = mc.mobileButton
local mobileCard = mc.mobileCard
local mobileLabel = mc.mobileLabel
local mobileSheet = mc.mobileSheet

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getSouls = ReplicatedStorage:WaitForChild("GetSouls")
local soulAction = ReplicatedStorage:WaitForChild("SoulAction")
local duelAction = ReplicatedStorage:WaitForChild("DuelAction")
local cellAction = ReplicatedStorage:WaitForChild("CellAction")

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenMobileSoulsGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 723
gui.Enabled = false
gui.Parent = playerGui

local sheet = mobileSheet({
	name = "MobileSoulsSheet",
	parent = gui,
	title = "👥 " .. _g("title", "LIVES"),
	onClose = function()
		uiState.closeRoute()
	end,
})

local scroll: ScrollingFrame = sheet:FindFirstChildOfClass("ScrollingFrame")

local isOpen = false
local payload = nil
local refresh: () -> ()

local function clear()
	for _, child in scroll:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = scroll

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 16)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = scroll
end

local function fetch()
	local ok, data = pcall(function()
		return getSouls:InvokeServer()
	end)
	payload = ok and typeof(data) == "table" and data or { IsPublic = false, Souls = {} }
	return payload
end

local function refreshSoon()
	task.delay(0.3, function()
		if isOpen then
			fetch()
			refresh()
		end
	end)
end

refresh = function()
	clear()
	local data = payload or fetch()

	if data.IsPublic ~= true then
		local infoCard = mobileCard({ parent = scroll, order = 1, accentColor = theme.Gold })
		mobileLabel({ parent = infoCard, text = "👥 " .. _g("private_title", "A PUBLIC WORLD FEATURE"), size = 15, color = theme.Gold, font = Enum.Font.GothamBlack, order = 1 })
		mobileLabel({
			parent = infoCard,
			text = _g("private_body", "The Lives tab lists the real sorcerers living in your shared world. Enter a Public world to meet them."),
			size = 13,
			color = theme.SubText,
			order = 2,
		})
		return
	end

	local souls = data.Souls or {}

	local headerCard = mobileCard({ parent = scroll, order = 1, accentColor = theme.Gold })
	mobileLabel({ parent = headerCard, text = "🌍 " .. _g("header", "LIVES IN THIS WORLD") .. ": " .. tostring(#souls), size = 15, color = theme.Gold, font = Enum.Font.GothamBlack, order = 1 })
	mobileLabel({ parent = headerCard, text = _g("header_hint", "Every name here is a real player sharing your calendar."), size = 12, color = theme.SubText, order = 2 })

	-- Fase 8: pursuit indicator -- your live rank by CE and who's above you.
	local byCE = table.clone(souls)
	table.sort(byCE, function(a, b)
		return a.CursedEnergy > b.CursedEnergy
	end)
	for i, soul in ipairs(byCE) do
		if soul.IsYou then
			local target = byCE[i - 1]
			local pursuitText = "🎯 #" .. tostring(i) .. " " .. _g("pursuit_of", "of") .. " " .. tostring(#byCE) .. " " .. _g("pursuit_souls", "lives")
				.. (target and (" -- " .. _g("pursuit_chasing", "chasing") .. " " .. tostring(target.Name)) or " -- " .. _g("pursuit_top", "you lead this world"))
			mobileLabel({ parent = headerCard, text = pursuitText, size = 12, color = theme.Purple, font = Enum.Font.GothamBold, order = 3 })
			break
		end
	end

	-- Fase 8: Tablón de los Más Buscados.
	local wantedSouls = {}
	for _, soul in ipairs(souls) do
		if soul.WantedLevel > 0 then
			table.insert(wantedSouls, soul)
		end
	end
	table.sort(wantedSouls, function(a, b)
		return a.WantedLevel > b.WantedLevel
	end)
	if #wantedSouls > 0 then
		local boardCard = mobileCard({ parent = scroll, order = 9, accentColor = theme.Bad })
		mobileLabel({ parent = boardCard, text = "💀 " .. _g("wanted_title", "MOST WANTED"), size = 13, color = theme.Bad, font = Enum.Font.GothamBlack, order = 1 })
		for i = 1, math.min(5, #wantedSouls) do
			local soul = wantedSouls[i]
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 40)
			row.BackgroundTransparency = 1
			row.LayoutOrder = 1 + i
			row.Parent = boardCard
			local face = Instance.new("ImageLabel")
			face.Size = UDim2.fromOffset(36, 36)
			face.BackgroundColor3 = theme.Panel
			face.BorderSizePixel = 0
			face.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(soul.UserId) .. "&w=48&h=48"
			face.Parent = row
			mc.corner(face, 8)
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Position = UDim2.fromOffset(44, 0)
			nameLabel.Size = UDim2.new(1, -44, 1, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = tostring(soul.Name) .. "   💀 " .. _g("wanted_level", "Wanted") .. " " .. tostring(soul.WantedLevel)
			nameLabel.TextColor3 = theme.Text
			nameLabel.TextSize = 12
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = row
		end
	end

	-- Fase 6D: PvP build selector (only affects duels, free re-plan 1x/year).
	local specCard = mobileCard({ parent = scroll, order = 2, accentColor = theme.Purple })
	local specStatus = data.YourSpec and (": " .. tostring(data.YourSpec)) or ""
	local lockNote = data.YourSpecLocked and ("  🔒 " .. _g("spec_locked", "re-plan next year")) or ""
	mobileLabel({ parent = specCard, text = "🧬 " .. _g("spec_title", "YOUR PVP BUILD") .. specStatus .. lockNote, size = 13, color = theme.Gold, font = Enum.Font.GothamBlack, order = 1 })
	local specRow = Instance.new("Frame")
	specRow.Size = UDim2.new(1, 0, 0, 40)
	specRow.BackgroundTransparency = 1
	specRow.LayoutOrder = 2
	specRow.Parent = specCard
	local specLayout = Instance.new("UIListLayout")
	specLayout.FillDirection = Enum.FillDirection.Horizontal
	specLayout.SortOrder = Enum.SortOrder.LayoutOrder
	specLayout.Padding = UDim.new(0, 4)
	specLayout.Parent = specRow
	for i, spec in ipairs({ "Offensive", "Defensive", "Technical", "Spiritual" }) do
		mobileButton({
			parent = specRow,
			text = spec,
			size = UDim2.new(0.25, -3, 0, 40),
			position = UDim2.new(0, 0, 0, 0),
			color = data.YourSpec == spec and theme.Purple or theme.Panel,
			textSize = 10,
			order = i,
			callback = function()
				duelAction:FireServer("set_spec", { Spec = spec })
				refreshSoon()
			end,
		})
	end

	-- Fase 7: fire a cell action then re-pull the panel state.
	local function cellFire(actionId, actionData)
		cellAction:FireServer(actionId, actionData or {})
		refreshSoon()
	end

	local cellData = data.CellData or {}
	local yourCell = cellData.YourCell

	-- Fase 7: pending cell invitation.
	if cellData.PendingInvite then
		local invite = cellData.PendingInvite
		local inviteCard = mobileCard({ parent = scroll, order = 4, accentColor = theme.Gold })
		mobileLabel({ parent = inviteCard, text = "🏯 " .. _g("invite_title", "CELL INVITATION"), size = 14, color = theme.Gold, font = Enum.Font.GothamBlack, order = 1 })
		mobileLabel({ parent = inviteCard, text = tostring(invite.FromName) .. " " .. _g("invite_body", "invites you to join") .. " '" .. tostring(invite.CellName) .. "'.", size = 12, color = theme.Text, order = 2 })
		local inviteRow = Instance.new("Frame")
		inviteRow.Size = UDim2.new(1, 0, 0, 44)
		inviteRow.BackgroundTransparency = 1
		inviteRow.LayoutOrder = 3
		inviteRow.Parent = inviteCard
		local inviteLayout = Instance.new("UIListLayout")
		inviteLayout.FillDirection = Enum.FillDirection.Horizontal
		inviteLayout.SortOrder = Enum.SortOrder.LayoutOrder
		inviteLayout.Padding = UDim.new(0, 6)
		inviteLayout.Parent = inviteRow
		mobileButton({ parent = inviteRow, text = "✔ " .. _g("accept", "ACCEPT"), size = UDim2.new(0.5, -3, 0, 44), position = UDim2.new(0, 0, 0, 0), color = theme.Green, textSize = 12, order = 1, callback = function()
			cellFire("accept_invite")
		end })
		mobileButton({ parent = inviteRow, text = "✘ " .. _g("decline", "DECLINE"), size = UDim2.new(0.5, -3, 0, 44), position = UDim2.new(0, 0, 0, 0), color = theme.Bad, textSize = 12, order = 2, callback = function()
			cellFire("decline_invite")
		end })
	end

	-- Fase 7: your cell (or the founding card if you have none).
	if yourCell then
		local memberNames = {}
		for _, member in ipairs(yourCell.Members or {}) do
			table.insert(memberNames, (member.IsLeader and "⭐" or "") .. tostring(member.Name))
		end
		local cellCard = mobileCard({ parent = scroll, order = 5, accentColor = theme.Gold })
		mobileLabel({ parent = cellCard, text = "🏯 " .. tostring(yourCell.Name) .. "   💰 $" .. tostring(yourCell.Treasury) .. "   👥 " .. tostring(yourCell.MemberCount) .. "/" .. tostring(yourCell.MaxMembers), size = 14, color = theme.Gold, font = Enum.Font.GothamBlack, order = 1 })
		mobileLabel({ parent = cellCard, text = "👥 " .. table.concat(memberNames, ", "), size = 12, color = theme.Text, order = 2 })
		local allyNames = {}
		for _, ally in ipairs(yourCell.Allies or {}) do
			table.insert(allyNames, tostring(ally.Name))
		end
		mobileLabel({ parent = cellCard, text = "🚩 " .. (#(yourCell.Territories or {}) > 0 and table.concat(yourCell.Territories, ", ") or _g("no_territory", "no territory yet")) .. (#allyNames > 0 and ("   🤝 " .. table.concat(allyNames, ", ")) or ""), size = 12, color = theme.SubText, order = 3 })
		mobileLabel({ parent = cellCard, text = "📜 " .. _g("oath", "Juramento de Era") .. ": " .. tostring(yourCell.EraDuelWins) .. "/" .. tostring(yourCell.OathGoal) .. " " .. _g("oath_body", "duel wins this era for") .. " +$" .. tostring(yourCell.OathReward), size = 12, color = theme.Purple, order = 4 })

		local amountBox = Instance.new("TextBox")
		amountBox.Size = UDim2.new(1, 0, 0, 36)
		amountBox.BackgroundColor3 = theme.Panel
		amountBox.BorderSizePixel = 0
		amountBox.PlaceholderText = "💰  " .. _g("amount_placeholder", "Amount...")
		amountBox.Text = ""
		amountBox.TextColor3 = theme.Text
		amountBox.TextSize = 13
		amountBox.Font = Enum.Font.GothamBold
		amountBox.ClearTextOnFocus = false
		amountBox.LayoutOrder = 5
		amountBox.Parent = cellCard
		mc.corner(amountBox, 6)

		local moneyRow = Instance.new("Frame")
		moneyRow.Size = UDim2.new(1, 0, 0, 44)
		moneyRow.BackgroundTransparency = 1
		moneyRow.LayoutOrder = 6
		moneyRow.Parent = cellCard
		local moneyLayout = Instance.new("UIListLayout")
		moneyLayout.FillDirection = Enum.FillDirection.Horizontal
		moneyLayout.SortOrder = Enum.SortOrder.LayoutOrder
		moneyLayout.Padding = UDim.new(0, 6)
		moneyLayout.Parent = moneyRow
		mobileButton({ parent = moneyRow, text = "💰 " .. _g("deposit", "DEPOSIT"), size = UDim2.new(0.5, -3, 0, 44), position = UDim2.new(0, 0, 0, 0), color = theme.Green, textSize = 12, order = 1, callback = function()
			local amount = math.floor(tonumber(amountBox.Text) or 0)
			if amount > 0 then
				amountBox.Text = ""
				cellFire("deposit", { Amount = amount })
			end
		end })
		mobileButton({ parent = moneyRow, text = "💸 " .. _g("withdraw", "WITHDRAW"), size = UDim2.new(0.5, -3, 0, 44), position = UDim2.new(0, 0, 0, 0), color = theme.Blue, textSize = 12, order = 2, callback = function()
			local amount = math.floor(tonumber(amountBox.Text) or 0)
			if amount > 0 then
				amountBox.Text = ""
				cellFire("withdraw", { Amount = amount })
			end
		end })

		local manageRow = Instance.new("Frame")
		manageRow.Size = UDim2.new(1, 0, 0, 44)
		manageRow.BackgroundTransparency = 1
		manageRow.LayoutOrder = 7
		manageRow.Parent = cellCard
		local manageLayout = Instance.new("UIListLayout")
		manageLayout.FillDirection = Enum.FillDirection.Horizontal
		manageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		manageLayout.Padding = UDim.new(0, 6)
		manageLayout.Parent = manageRow
		mobileButton({ parent = manageRow, text = "🚩 " .. _g("claim", "CLAIM"), size = UDim2.new(0.5, -3, 0, 44), position = UDim2.new(0, 0, 0, 0), color = theme.Purple, textSize = 12, order = 1, callback = function()
			for _, territory in ipairs(cellData.TerritoryList or {}) do
				if not (cellData.Territories or {})[territory] then
					cellFire("claim", { Territory = territory })
					return
				end
			end
		end })
		mobileButton({ parent = manageRow, text = "🚪 " .. _g("leave", "LEAVE"), size = UDim2.new(0.5, -3, 0, 44), position = UDim2.new(0, 0, 0, 0), color = theme.Bad, textSize = 12, order = 2, callback = function()
			cellFire("leave")
		end })

		for _, war in ipairs(yourCell.Wars or {}) do
			local warCard = mobileCard({ parent = scroll, order = 6, accentColor = theme.Bad })
			mobileLabel({ parent = warCard, text = "⚔ " .. _g("war_vs", "WAR vs") .. " '" .. tostring(war.FoeName) .. "'   " .. tostring(war.YourScore) .. " : " .. tostring(war.FoeScore), size = 13, color = theme.Bad, font = Enum.Font.GothamBold, order = 1 })
			local truceOfferedByFoe = war.TruceOfferedBy ~= nil and war.TruceOfferedBy == war.FoeCellId
			mobileButton({ parent = warCard, text = truceOfferedByFoe and ("🕊 " .. _g("accept_truce", "ACCEPT TRUCE")) or ("🕊 " .. _g("offer_truce", "OFFER TRUCE")), color = theme.Blue, textSize = 12, order = 2, callback = function()
				cellFire(truceOfferedByFoe and "accept_truce" or "offer_truce", { WarKey = war.WarKey })
			end })
		end
	else
		local foundCard = mobileCard({ parent = scroll, order = 5, accentColor = theme.Gold })
		mobileLabel({ parent = foundCard, text = "🏯 " .. _g("found_title", "FOUND A CELL") .. "  ($1000)", size = 14, color = theme.Gold, font = Enum.Font.GothamBlack, order = 1 })
		local nameBox = Instance.new("TextBox")
		nameBox.Size = UDim2.new(1, 0, 0, 36)
		nameBox.BackgroundColor3 = theme.Panel
		nameBox.BorderSizePixel = 0
		nameBox.PlaceholderText = "✏️  " .. _g("found_placeholder", "Cell name...")
		nameBox.Text = ""
		nameBox.TextColor3 = theme.Text
		nameBox.TextSize = 13
		nameBox.Font = Enum.Font.GothamBold
		nameBox.ClearTextOnFocus = false
		nameBox.LayoutOrder = 2
		nameBox.Parent = foundCard
		mc.corner(nameBox, 6)
		mobileButton({ parent = foundCard, text = "🏯 " .. _g("found_button", "CREATE"), color = theme.Green, textSize = 13, order = 3, callback = function()
			if nameBox.Text ~= "" then
				cellFire("create", { Name = nameBox.Text })
				nameBox.Text = ""
			end
		end })
	end

	-- Fase 7: the other cells of this world (war/alliance targets).
	for _, cell in ipairs(cellData.Cells or {}) do
		if not yourCell or cell.CellId ~= yourCell.CellId then
			local isAlly = false
			if yourCell then
				for _, ally in ipairs(yourCell.Allies or {}) do
					if ally.CellId == cell.CellId then
						isAlly = true
					end
				end
			end
			local otherCard = mobileCard({ parent = scroll, order = 7 })
			mobileLabel({ parent = otherCard, text = "🏯 " .. tostring(cell.Name) .. "  👥 " .. tostring(cell.MemberCount) .. "  🚩 " .. tostring(#(cell.Territories or {})) .. (isAlly and "  🤝" or ""), size = 13, color = theme.Text, font = Enum.Font.GothamBold, order = 1 })
			if yourCell and yourCell.IsLeader then
				local diploRow = Instance.new("Frame")
				diploRow.Size = UDim2.new(1, 0, 0, 40)
				diploRow.BackgroundTransparency = 1
				diploRow.LayoutOrder = 2
				diploRow.Parent = otherCard
				local diploLayout = Instance.new("UIListLayout")
				diploLayout.FillDirection = Enum.FillDirection.Horizontal
				diploLayout.SortOrder = Enum.SortOrder.LayoutOrder
				diploLayout.Padding = UDim.new(0, 6)
				diploLayout.Parent = diploRow
				if isAlly then
					mobileButton({ parent = diploRow, text = "🗡 " .. _g("betray", "BETRAY"), size = UDim2.new(1, 0, 0, 40), position = UDim2.new(0, 0, 0, 0), color = theme.Bad, textSize = 12, order = 1, callback = function()
						cellFire("break_alliance", { TargetCellId = cell.CellId })
					end })
				else
					mobileButton({ parent = diploRow, text = "⚔ " .. _g("war", "WAR"), size = UDim2.new(0.5, -3, 0, 40), position = UDim2.new(0, 0, 0, 0), color = theme.Bad, textSize = 12, order = 1, callback = function()
						cellFire("declare_war", { TargetCellId = cell.CellId })
					end })
					mobileButton({ parent = diploRow, text = "🤝 " .. _g("ally", "ALLY"), size = UDim2.new(0.5, -3, 0, 40), position = UDim2.new(0, 0, 0, 0), color = theme.Green, textSize = 12, order = 2, callback = function()
						cellFire("offer_alliance", { TargetCellId = cell.CellId })
					end })
				end
			end
		end
	end

	-- Fase 7: Los Tronos -- the world's elite council by Fame.
	local thrones = data.Thrones or {}
	if #thrones > 0 then
		local throneCard = mobileCard({ parent = scroll, order = 8, accentColor = theme.Gold })
		mobileLabel({ parent = throneCard, text = "👑 " .. _g("thrones_title", "LOS TRONOS"), size = 13, color = theme.Gold, font = Enum.Font.GothamBlack, order = 1 })
		for i, seat in ipairs(thrones) do
			mobileLabel({ parent = throneCard, text = (seat.IsSovereignSeat and "👑 " or tostring(i) .. ". ") .. tostring(seat.Name) .. "  --  ⭐ " .. tostring(seat.Fame) .. " Fame", size = 12, color = seat.IsSovereignSeat and theme.Gold or theme.SubText, order = 1 + i })
		end
	end

	-- Fase 6C: live duels of this world, watchable by anyone present.
	local activeDuels = data.ActiveDuels or {}
	for i, liveDuel in ipairs(activeDuels) do
		local duelCard = mobileCard({ parent = scroll, order = 3, accentColor = theme.Bad })
		mobileLabel({ parent = duelCard, text = "👁 " .. _g("duels_title", "LIVE DUEL") .. ": " .. tostring(liveDuel.AName) .. " vs " .. tostring(liveDuel.BName) .. " (R" .. tostring(liveDuel.Round) .. ")", size = 13, color = theme.Text, font = Enum.Font.GothamBold, order = 1 })
		mobileButton({
			parent = duelCard,
			text = "👁 " .. _g("action_watch", "WATCH"),
			color = theme.Blue,
			textSize = 13,
			order = 2,
			callback = function()
				duelAction:FireServer("spectate", { DuelId = liveDuel.DuelId })
			end,
		})
		local _ = i
	end

	local othersCount = 0
	for _, soul in ipairs(souls) do
		if not soul.IsYou then
			othersCount += 1
		end
	end

	if othersCount == 0 then
		local emptyCard = mobileCard({ parent = scroll, order = 5 })
		mobileLabel({
			parent = emptyCard,
			text = _g("empty", "No other lives are connected right now. They will appear here the moment someone joins your world."),
			size = 13,
			color = theme.SubText,
			order = 1,
		})
		return
	end

	for idx, soul in ipairs(souls) do
		if not soul.IsYou then
			local soulCard = mobileCard({ parent = scroll, order = 10 + idx })
			mobileLabel({ parent = soulCard, text = "👤 " .. tostring(soul.Name) .. "  (@" .. tostring(soul.PlayerName) .. ")", size = 15, color = theme.Gold, font = Enum.Font.GothamBlack, order = 1 })
			mobileLabel({
				parent = soulCard,
				text = "⚔ " .. tostring(soul.Grade) .. "  |  🧭 " .. tostring(soul.LifePath) .. "  |  🎂 " .. _g("age", "Age") .. " " .. tostring(soul.Age),
				size = 12,
				color = theme.Purple,
				font = Enum.Font.GothamBold,
				order = 2,
			})
			local clanText = soul.Clan ~= "" and ("  |  🏯 " .. tostring(soul.Clan)) or ""
			mobileLabel({
				parent = soulCard,
				text = "🔮 CE " .. tostring(soul.CursedEnergy) .. "  |  ⭐ Rep " .. tostring(soul.Reputation) .. "  |  💀 Wanted " .. tostring(soul.WantedLevel) .. clanText,
				size = 12,
				color = theme.SubText,
				order = 3,
			})
			local cellTag = soul.CellName and ("  |  🏯 " .. tostring(soul.CellName)) or ""
			mobileLabel({
				parent = soulCard,
				text = "🥊 " .. _g("record", "Record") .. ": " .. tostring(soul.CombatWins) .. "W / " .. tostring(soul.CombatLosses) .. "L" .. cellTag,
				size = 12,
				color = theme.SubText,
				order = 4,
			})

			-- Inline gift amount box, hidden until GIFT toggles it (same
			-- single-view convention as the Buscador's code field).
			local giftBox = Instance.new("TextBox")
			giftBox.Size = UDim2.new(1, 0, 0, 36)
			giftBox.BackgroundColor3 = theme.Panel
			giftBox.BorderSizePixel = 0
			giftBox.PlaceholderText = "💰  " .. _g("gift_placeholder", "Amount to gift...")
			giftBox.Text = ""
			giftBox.TextColor3 = theme.Text
			giftBox.TextSize = 13
			giftBox.Font = Enum.Font.GothamBold
			giftBox.ClearTextOnFocus = false
			giftBox.Visible = false
			giftBox.LayoutOrder = 5
			giftBox.Parent = soulCard
			mc.corner(giftBox, 6)

			local actionRow = Instance.new("Frame")
			actionRow.Size = UDim2.new(1, 0, 0, 44)
			actionRow.BackgroundTransparency = 1
			actionRow.LayoutOrder = 6
			actionRow.Parent = soulCard

			local rowLayout = Instance.new("UIListLayout")
			rowLayout.FillDirection = Enum.FillDirection.Horizontal
			rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
			rowLayout.Padding = UDim.new(0, 6)
			rowLayout.Parent = actionRow

			mobileButton({
				parent = actionRow,
				text = "📡 " .. _g("action_signal", "SIGNAL"),
				size = UDim2.new(1 / 3, -4, 0, 44),
				position = UDim2.new(0, 0, 0, 0),
				color = theme.Blue,
				textSize = 12,
				order = 1,
				callback = function()
					soulAction:FireServer(soul.UserId, "signal", {})
					refreshSoon()
				end,
			})
			mobileButton({
				parent = actionRow,
				text = "🎁 " .. _g("action_gift", "GIFT $"),
				size = UDim2.new(1 / 3, -4, 0, 44),
				position = UDim2.new(0, 0, 0, 0),
				color = theme.Purple,
				textSize = 12,
				order = 2,
				callback = function()
					if giftBox.Visible and giftBox.Text ~= "" then
						local amount = math.floor(tonumber(giftBox.Text) or 0)
						if amount > 0 then
							soulAction:FireServer(soul.UserId, "gift_money", { Amount = amount })
							giftBox.Text = ""
							giftBox.Visible = false
							refreshSoon()
						end
					else
						giftBox.Visible = not giftBox.Visible
					end
				end,
			})
			-- Fase 6B: challenge to a live duel (REVANCHA if you hold a
			-- rematch marker against this soul; dimmed while they duel).
			local duelText = soul.RematchAvailable and ("🔥 " .. _g("action_rematch", "REVANCHA")) or ("⚔ " .. _g("action_duel", "DUEL"))
			mobileButton({
				parent = actionRow,
				text = soul.InDuel and ("⚔ " .. _g("action_dueling", "DUELING...")) or duelText,
				size = UDim2.new(1 / 3, -4, 0, 44),
				position = UDim2.new(0, 0, 0, 0),
				color = soul.InDuel and theme.Panel or theme.Bad,
				textSize = 12,
				order = 3,
				callback = function()
					if not soul.InDuel then
						duelAction:FireServer("invite", { TargetUserId = soul.UserId })
					end
				end,
			})

			-- Fase 7: recruit into your cell (leaders with room, souls
			-- without a cell only).
			if yourCell and yourCell.IsLeader and yourCell.MemberCount < yourCell.MaxMembers and not soul.CellName then
				mobileButton({
					parent = soulCard,
					text = "🏯 " .. _g("action_invite", "INVITE TO CELL"),
					color = theme.Green,
					textSize = 12,
					order = 7,
					callback = function()
						cellFire("invite", { TargetUserId = soul.UserId })
					end,
				})
			end
		end
	end
end

local function openPanel()
	isOpen = true
	gui.Enabled = true
	fetch()
	refresh()
end

local function closePanel()
	isOpen = false
	gui.Enabled = false
end

local function init()
	uiState.subscribe(function(route)
		if route == "souls" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
