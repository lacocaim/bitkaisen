-- Multiplayer Fase 6 ("Reunión de Vidas"): the "LIVES" nav tab. Lists every
-- real player living in your Public world with per-soul actions (signal,
-- gift money; duels arrive with Fase 6B). In Private mode it explains the
-- feature instead -- same convention as WorldHistoryPanel's MUNDO tab.
-- Modeled on RivalsPanel.luau (card list + action buttons + uiState route).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local uiState = require("@ui-state/uiState")
local responsiveScale = require("@ui/responsiveScale")
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _g(key, fallback) return BitKaisenLocale.tOrFallback(_L, "souls." .. key, nil, fallback) end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getSouls = ReplicatedStorage:WaitForChild("GetSouls")
local soulAction = ReplicatedStorage:WaitForChild("SoulAction")
local duelAction = ReplicatedStorage:WaitForChild("DuelAction")
local cellAction = ReplicatedStorage:WaitForChild("CellAction")

local COLORS = {
	Window = Color3.fromRGB(14, 13, 20),
	Card = Color3.fromRGB(23, 22, 33),
	Card2 = Color3.fromRGB(30, 28, 42),
	Stroke = Color3.fromRGB(83, 67, 104),
	Text = Color3.fromRGB(244, 240, 250),
	SubText = Color3.fromRGB(174, 168, 191),
	Gold = Color3.fromRGB(255, 207, 94),
	Red = Color3.fromRGB(235, 82, 104),
	Purple = Color3.fromRGB(160, 101, 244),
	Green = Color3.fromRGB(112, 224, 153),
	Blue = Color3.fromRGB(104, 178, 246),
}

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenSoulsGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 623
gui.Enabled = false
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "SoulsOverlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.4
overlay.BorderSizePixel = 0
overlay.ZIndex = 623
overlay.Parent = gui

local window = Instance.new("Frame")
window.Name = "SoulsWindow"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.new(0.5, 0, 0.5, 0)
window.BackgroundColor3 = COLORS.Window
window.BorderSizePixel = 0
window.ZIndex = 624
window.Parent = overlay

local function makeCorner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = obj
	return c
end

local function makeStroke(obj, color)
	local s = Instance.new("UIStroke")
	s.Color = color or COLORS.Stroke
	s.Thickness = 1
	s.Transparency = 0.12
	s.Parent = obj
	return s
end

makeCorner(window, 10)
makeStroke(window)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 24, 0, 16)
title.Size = UDim2.new(1, -90, 0, 34)
title.Text = "👥 " .. _g("title", "LIVES")
title.TextColor3 = COLORS.Gold
title.TextSize = 22
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 625
title.Parent = window

local closeButton = Instance.new("TextButton")
closeButton.Position = UDim2.new(1, -58, 0, 16)
closeButton.Size = UDim2.fromOffset(38, 34)
closeButton.Text = "X"
closeButton.TextColor3 = COLORS.Red
closeButton.TextSize = 16
closeButton.Font = Enum.Font.GothamBlack
closeButton.BackgroundColor3 = Color3.fromRGB(35, 35, 46)
closeButton.BorderSizePixel = 0
closeButton.ZIndex = 626
closeButton.Parent = window
makeCorner(closeButton, 8)

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.new(0, 24, 0, 64)
scroll.Size = UDim2.new(1, -48, 1, -88)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = COLORS.Purple
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ZIndex = 625
scroll.Parent = window

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = scroll

local isOpen = false
local payload = nil
local refresh

responsiveScale.attach(window, 1190, 821)

local function clear()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
end

local function makeText(parent, value, size, color, y, bold, height)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 14, 0, y)
	label.Size = UDim2.new(1, -28, 0, height or 24)
	label.Text = tostring(value or "")
	label.TextColor3 = color or COLORS.Text
	label.TextSize = size or 12
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Font = bold and Enum.Font.GothamBlack or Enum.Font.GothamMedium
	label.ZIndex = parent.ZIndex + 1
	label.Parent = parent
	return label
end

local function card(height, color)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -8, 0, height or 90)
	frame.BackgroundColor3 = color or COLORS.Card
	frame.BorderSizePixel = 0
	frame.ZIndex = 625
	frame.Parent = scroll
	makeCorner(frame, 8)
	makeStroke(frame)
	return frame
end

local function actionButton(parent, text, xScale, y, widthScale, color, callback)
	local btn = Instance.new("TextButton")
	btn.Position = UDim2.new(xScale, 14, 0, y)
	btn.Size = UDim2.new(widthScale, -18, 0, 32)
	btn.BackgroundColor3 = color
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = COLORS.Text
	btn.TextSize = 10
	btn.TextWrapped = true
	btn.Font = Enum.Font.GothamBlack
	btn.ZIndex = parent.ZIndex + 2
	btn.Parent = parent
	makeCorner(btn, 8)
	btn.MouseButton1Click:Connect(callback)
	return btn
end

local function fetch()
	local ok, data = pcall(function() return getSouls:InvokeServer() end)
	payload = ok and typeof(data) == "table" and data or { IsPublic = false, Souls = {} }
	return payload
end

-- Inline gift prompt: the card grows a small amount box + confirm instead
-- of opening a separate window (single-view convention from the Buscador).
local function attachGiftRow(box, soul)
	local giftBox = Instance.new("TextBox")
	giftBox.Position = UDim2.new(0.5, 14, 0, 130)
	giftBox.Size = UDim2.new(0.25, -18, 0, 32)
	giftBox.BackgroundColor3 = Color3.fromRGB(35, 35, 46)
	giftBox.BorderSizePixel = 0
	giftBox.PlaceholderText = "$..."
	giftBox.Text = ""
	giftBox.TextColor3 = COLORS.Text
	giftBox.TextSize = 12
	giftBox.Font = Enum.Font.GothamBold
	giftBox.ClearTextOnFocus = false
	giftBox.Visible = false
	giftBox.ZIndex = box.ZIndex + 2
	giftBox.Parent = box
	makeCorner(giftBox, 8)

	local confirmBtn = actionButton(box, "✔ " .. _g("gift_confirm", "SEND"), 0.75, 130, 0.25, COLORS.Green, function()
		local amount = math.floor(tonumber(giftBox.Text) or 0)
		if amount > 0 then
			soulAction:FireServer(soul.UserId, "gift_money", { Amount = amount })
			giftBox.Text = ""
			giftBox.Visible = false
		end
	end)
	confirmBtn.Visible = false

	return giftBox, confirmBtn
end

refresh = function()
	clear()
	local data = payload or fetch()

	if data.IsPublic ~= true then
		local info = card(120, COLORS.Card2)
		makeText(info, "👥 " .. _g("private_title", "A PUBLIC WORLD FEATURE"), 16, COLORS.Gold, 14, true)
		makeText(info, _g("private_body", "The Lives tab lists the real sorcerers living in your shared world. Enter a Public world to meet them."), 12, COLORS.SubText, 46, false, 60)
		return
	end

	local souls = data.Souls or {}
	local count = 0
	for _, soul in ipairs(souls) do
		if not soul.IsYou then count += 1 end
	end

	-- Fase 8: pursuit indicator -- your live rank by CE and who's above you.
	local byCE = table.clone(souls)
	table.sort(byCE, function(a, b)
		return a.CursedEnergy > b.CursedEnergy
	end)
	local pursuitText = ""
	for i, soul in ipairs(byCE) do
		if soul.IsYou then
			local target = byCE[i - 1]
			pursuitText = "🎯 #" .. tostring(i) .. " " .. _g("pursuit_of", "of") .. " " .. tostring(#byCE) .. " " .. _g("pursuit_souls", "lives")
				.. (target and (" -- " .. _g("pursuit_chasing", "chasing") .. " " .. tostring(target.Name)) or " -- " .. _g("pursuit_top", "you lead this world"))
			break
		end
	end

	local header = card(pursuitText ~= "" and 88 or 64, COLORS.Card2)
	makeText(header, "🌍 " .. _g("header", "LIVES IN THIS WORLD") .. ": " .. tostring(#souls), 15, COLORS.Gold, 10, true)
	makeText(header, _g("header_hint", "Every name here is a real player sharing your calendar."), 11, COLORS.SubText, 36, false, 20)
	if pursuitText ~= "" then
		makeText(header, pursuitText, 12, COLORS.Purple, 58, true, 22)
	end

	-- Fase 6D: PvP build selector (only affects duels, free re-plan 1x/year).
	local specCard = card(96, COLORS.Card2)
	local specStatus = data.YourSpec and (": " .. tostring(data.YourSpec)) or ""
	local lockNote = data.YourSpecLocked and ("  🔒 " .. _g("spec_locked", "re-plan next year")) or ""
	makeText(specCard, "🧬 " .. _g("spec_title", "YOUR PVP BUILD") .. specStatus .. lockNote, 13, COLORS.Gold, 10, true)
	local specOptions = { "Offensive", "Defensive", "Technical", "Spiritual" }
	for i, spec in ipairs(specOptions) do
		actionButton(specCard, spec, (i - 1) * 0.25, 48, 0.25, data.YourSpec == spec and COLORS.Purple or Color3.fromRGB(35, 35, 46), function()
			duelAction:FireServer("set_spec", { Spec = spec })
			task.delay(0.3, function()
				fetch()
				if isOpen then
					refresh()
				end
			end)
		end)
	end

	-- Fase 7: fire a cell action then re-pull the panel state.
	local function cellFire(actionId, actionData)
		cellAction:FireServer(actionId, actionData or {})
		task.delay(0.4, function()
			fetch()
			if isOpen then
				refresh()
			end
		end)
	end

	local cellData = data.CellData or {}
	local yourCell = cellData.YourCell

	-- Fase 7: pending cell invitation.
	if cellData.PendingInvite then
		local invite = cellData.PendingInvite
		local inviteCard = card(96, Color3.fromRGB(35, 30, 20))
		makeText(inviteCard, "🏯 " .. _g("invite_title", "CELL INVITATION"), 14, COLORS.Gold, 10, true)
		makeText(inviteCard, tostring(invite.FromName) .. " " .. _g("invite_body", "invites you to join") .. " '" .. tostring(invite.CellName) .. "'.", 12, COLORS.Text, 32, false, 22)
		actionButton(inviteCard, "✔ " .. _g("accept", "ACCEPT"), 0, 58, 0.3, COLORS.Green, function()
			cellFire("accept_invite")
		end)
		actionButton(inviteCard, "✘ " .. _g("decline", "DECLINE"), 0.32, 58, 0.3, COLORS.Red, function()
			cellFire("decline_invite")
		end)
	end

	-- Fase 7: your cell (or the founding card if you have none).
	if yourCell then
		local memberNames = {}
		for _, member in ipairs(yourCell.Members or {}) do
			table.insert(memberNames, (member.IsLeader and "⭐" or "") .. tostring(member.Name))
		end
		local warCount = #(yourCell.Wars or {})
		local cellCard = card(184, COLORS.Card2)
		makeText(cellCard, "🏯 " .. tostring(yourCell.Name) .. "   💰 $" .. tostring(yourCell.Treasury) .. "   👥 " .. tostring(yourCell.MemberCount) .. "/" .. tostring(yourCell.MaxMembers), 14, COLORS.Gold, 10, true)
		makeText(cellCard, "👥 " .. table.concat(memberNames, ", "), 11, COLORS.Text, 34, false, 26)
		local allyNames = {}
		for _, ally in ipairs(yourCell.Allies or {}) do
			table.insert(allyNames, tostring(ally.Name))
		end
		makeText(cellCard, "🚩 " .. (#(yourCell.Territories or {}) > 0 and table.concat(yourCell.Territories, ", ") or _g("no_territory", "no territory yet")) .. (#allyNames > 0 and ("   🤝 " .. table.concat(allyNames, ", ")) or ""), 11, COLORS.SubText, 62, false, 20)
		makeText(cellCard, "📜 " .. _g("oath", "Juramento de Era") .. ": " .. tostring(yourCell.EraDuelWins) .. "/" .. tostring(yourCell.OathGoal) .. " " .. _g("oath_body", "duel wins this era for") .. " +$" .. tostring(yourCell.OathReward), 11, COLORS.Purple, 84, false, 20)

		local amountBox = Instance.new("TextBox")
		amountBox.Position = UDim2.new(0, 14, 0, 108)
		amountBox.Size = UDim2.new(0.3, -18, 0, 30)
		amountBox.BackgroundColor3 = Color3.fromRGB(35, 35, 46)
		amountBox.BorderSizePixel = 0
		amountBox.PlaceholderText = "$..."
		amountBox.Text = ""
		amountBox.TextColor3 = COLORS.Text
		amountBox.TextSize = 12
		amountBox.Font = Enum.Font.GothamBold
		amountBox.ClearTextOnFocus = false
		amountBox.ZIndex = cellCard.ZIndex + 2
		amountBox.Parent = cellCard
		makeCorner(amountBox, 8)

		actionButton(cellCard, "💰 " .. _g("deposit", "DEPOSIT"), 0.32, 106, 0.33, COLORS.Green, function()
			local amount = math.floor(tonumber(amountBox.Text) or 0)
			if amount > 0 then
				amountBox.Text = ""
				cellFire("deposit", { Amount = amount })
			end
		end)
		actionButton(cellCard, "💸 " .. _g("withdraw", "WITHDRAW"), 0.66, 106, 0.33, COLORS.Blue, function()
			local amount = math.floor(tonumber(amountBox.Text) or 0)
			if amount > 0 then
				amountBox.Text = ""
				cellFire("withdraw", { Amount = amount })
			end
		end)

		actionButton(cellCard, "🚩 " .. _g("claim", "CLAIM TERRITORY"), 0, 144, 0.48, COLORS.Purple, function()
			for _, territory in ipairs(cellData.TerritoryList or {}) do
				if not (cellData.Territories or {})[territory] then
					cellFire("claim", { Territory = territory })
					return
				end
			end
		end)
		actionButton(cellCard, "🚪 " .. _g("leave", "LEAVE CELL"), 0.52, 144, 0.48, COLORS.Red, function()
			cellFire("leave")
		end)

		for _, war in ipairs(yourCell.Wars or {}) do
			local warCard = card(52, Color3.fromRGB(41, 26, 32))
			makeText(warCard, "⚔ " .. _g("war_vs", "WAR vs") .. " '" .. tostring(war.FoeName) .. "'   " .. tostring(war.YourScore) .. " : " .. tostring(war.FoeScore), 13, COLORS.Red, 14, true)
			local truceOfferedByFoe = war.TruceOfferedBy ~= nil and war.TruceOfferedBy == war.FoeCellId
			actionButton(warCard, truceOfferedByFoe and ("🕊 " .. _g("accept_truce", "ACCEPT TRUCE")) or ("🕊 " .. _g("offer_truce", "OFFER TRUCE")), 0.68, 10, 0.3, COLORS.Blue, function()
				cellFire(truceOfferedByFoe and "accept_truce" or "offer_truce", { WarKey = war.WarKey })
			end)
		end
		local _ = warCount
	else
		local foundCard = card(96, COLORS.Card2)
		makeText(foundCard, "🏯 " .. _g("found_title", "FOUND A CELL") .. "  ($1000)", 14, COLORS.Gold, 10, true)
		local nameBox = Instance.new("TextBox")
		nameBox.Position = UDim2.new(0, 14, 0, 46)
		nameBox.Size = UDim2.new(0.58, -18, 0, 32)
		nameBox.BackgroundColor3 = Color3.fromRGB(35, 35, 46)
		nameBox.BorderSizePixel = 0
		nameBox.PlaceholderText = "✏️  " .. _g("found_placeholder", "Cell name...")
		nameBox.Text = ""
		nameBox.TextColor3 = COLORS.Text
		nameBox.TextSize = 12
		nameBox.Font = Enum.Font.GothamBold
		nameBox.ClearTextOnFocus = false
		nameBox.ZIndex = foundCard.ZIndex + 2
		nameBox.Parent = foundCard
		makeCorner(nameBox, 8)
		actionButton(foundCard, "🏯 " .. _g("found_button", "CREATE"), 0.6, 44, 0.4, COLORS.Green, function()
			if nameBox.Text ~= "" then
				cellFire("create", { Name = nameBox.Text })
				nameBox.Text = ""
			end
		end)
	end

	-- Fase 7: the other cells of this world (war/alliance targets).
	local otherCells = {}
	for _, cell in ipairs(cellData.Cells or {}) do
		if not yourCell or cell.CellId ~= yourCell.CellId then
			table.insert(otherCells, cell)
		end
	end
	if #otherCells > 0 then
		local listCard = card(34 + #otherCells * 40, COLORS.Card2)
		makeText(listCard, "🏯 " .. _g("cells_title", "CELLS OF THIS WORLD"), 13, COLORS.Gold, 8, true)
		for i, cell in ipairs(otherCells) do
			local y = 28 + (i - 1) * 40
			local isAlly = false
			if yourCell then
				for _, ally in ipairs(yourCell.Allies or {}) do
					if ally.CellId == cell.CellId then
						isAlly = true
					end
				end
			end
			makeText(listCard, "🏯 " .. tostring(cell.Name) .. "  👥 " .. tostring(cell.MemberCount) .. "  🚩 " .. tostring(#(cell.Territories or {})) .. (isAlly and "  🤝" or ""), 12, COLORS.Text, y + 8, false, 22)
			if yourCell and yourCell.IsLeader then
				if isAlly then
					actionButton(listCard, "🗡 " .. _g("betray", "BETRAY"), 0.78, y, 0.2, COLORS.Red, function()
						cellFire("break_alliance", { TargetCellId = cell.CellId })
					end)
				else
					actionButton(listCard, "⚔ " .. _g("war", "WAR"), 0.56, y, 0.2, COLORS.Red, function()
						cellFire("declare_war", { TargetCellId = cell.CellId })
					end)
					actionButton(listCard, "🤝 " .. _g("ally", "ALLY"), 0.78, y, 0.2, COLORS.Green, function()
						cellFire("offer_alliance", { TargetCellId = cell.CellId })
					end)
				end
			end
		end
	end

	-- Fase 7: Los Tronos -- the world's elite council by Fame.
	local thrones = data.Thrones or {}
	if #thrones > 0 then
		local throneCard = card(34 + #thrones * 22, COLORS.Card2)
		makeText(throneCard, "👑 " .. _g("thrones_title", "LOS TRONOS"), 13, COLORS.Gold, 8, true)
		for i, seat in ipairs(thrones) do
			makeText(throneCard, (seat.IsSovereignSeat and "👑 " or tostring(i) .. ". ") .. tostring(seat.Name) .. "  --  ⭐ " .. tostring(seat.Fame) .. " Fame", 12, seat.IsSovereignSeat and COLORS.Gold or COLORS.SubText, 28 + (i - 1) * 22, false, 20)
		end
	end

	-- Fase 8: Tablón de los Más Buscados -- real player faces + wanted level.
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
		local boardCard = card(38 + math.min(5, #wantedSouls) * 44, Color3.fromRGB(35, 25, 22))
		makeText(boardCard, "💀 " .. _g("wanted_title", "MOST WANTED"), 13, COLORS.Red, 8, true)
		for i = 1, math.min(5, #wantedSouls) do
			local soul = wantedSouls[i]
			local y = 32 + (i - 1) * 44
			local face = Instance.new("ImageLabel")
			face.Position = UDim2.fromOffset(14, y)
			face.Size = UDim2.fromOffset(36, 36)
			face.BackgroundColor3 = Color3.fromRGB(25, 20, 18)
			face.BorderSizePixel = 0
			face.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(soul.UserId) .. "&w=48&h=48"
			face.ZIndex = boardCard.ZIndex + 1
			face.Parent = boardCard
			makeCorner(face, 8)
			local wantedLabel = makeText(boardCard, tostring(soul.Name) .. "   💀 " .. _g("wanted_level", "Wanted") .. " " .. tostring(soul.WantedLevel), 12, COLORS.Text, y + 8, true, 22)
			wantedLabel.Position = UDim2.new(0, 60, 0, y + 8)
		end
	end

	-- Fase 6C: live duels of this world, watchable by anyone present.
	local activeDuels = data.ActiveDuels or {}
	if #activeDuels > 0 then
		local duelsCard = card(40 + #activeDuels * 40, COLORS.Card2)
		makeText(duelsCard, "👁 " .. _g("duels_title", "LIVE DUELS"), 13, COLORS.Red, 8, true)
		for i, liveDuel in ipairs(activeDuels) do
			local y = 30 + (i - 1) * 40
			makeText(duelsCard, "⚔ " .. tostring(liveDuel.AName) .. "  vs  " .. tostring(liveDuel.BName) .. "   (Round " .. tostring(liveDuel.Round) .. ")", 12, COLORS.Text, y + 6, false, 22)
			actionButton(duelsCard, "👁 " .. _g("action_watch", "WATCH"), 0.75, y, 0.25, COLORS.Blue, function()
				duelAction:FireServer("spectate", { DuelId = liveDuel.DuelId })
			end)
		end
	end

	if count == 0 then
		makeText(card(70), _g("empty", "No other lives are connected right now. They will appear here the moment someone joins your world."), 12, COLORS.SubText, 22, false, 44)
	end

	for _, soul in ipairs(souls) do
		if not soul.IsYou then
			local box = card(176)
			makeText(box, "👤 " .. tostring(soul.Name) .. "  (@" .. tostring(soul.PlayerName) .. ")", 15, COLORS.Gold, 10, true)
			makeText(box, "⚔ " .. tostring(soul.Grade) .. "   🧭 " .. tostring(soul.LifePath) .. "   🎂 " .. _g("age", "Age") .. " " .. tostring(soul.Age), 11, COLORS.Purple, 34, true)
			local clanText = soul.Clan ~= "" and ("   🏯 " .. tostring(soul.Clan)) or ""
			makeText(box, "🔮 CE " .. tostring(soul.CursedEnergy) .. "   ⭐ Rep " .. tostring(soul.Reputation) .. "   💀 Wanted " .. tostring(soul.WantedLevel) .. clanText, 11, COLORS.SubText, 58, false, 22)
			local cellTag = soul.CellName and ("   🏯 " .. tostring(soul.CellName)) or ""
			makeText(box, "🥊 " .. _g("record", "Record") .. ": " .. tostring(soul.CombatWins) .. "W / " .. tostring(soul.CombatLosses) .. "L" .. cellTag, 11, COLORS.SubText, 82, false, 22)

			local giftBox, confirmBtn = attachGiftRow(box, soul)

			actionButton(box, "📡 " .. _g("action_signal", "SIGNAL"), 0, 130, 0.25, COLORS.Blue, function()
				soulAction:FireServer(soul.UserId, "signal", {})
			end)

			-- Fase 6B: challenge to a live duel (REVANCHA if you hold a
			-- rematch marker against this soul; dimmed while they duel).
			local duelText = soul.RematchAvailable and ("🔥 " .. _g("action_rematch", "REVANCHA")) or ("⚔ " .. _g("action_duel", "DUEL"))
			local duelBtn = actionButton(box, soul.InDuel and ("⚔ " .. _g("action_dueling", "DUELING...")) or duelText, 0.5, 130, 0.25, soul.InDuel and Color3.fromRGB(35, 35, 46) or COLORS.Red, function()
				if not soul.InDuel then
					duelAction:FireServer("invite", { TargetUserId = soul.UserId })
				end
			end)

			-- Fase 7: recruit into your cell (leaders with room, souls
			-- without a cell only). Shares the 0.75 slot with the gift
			-- confirm, so it hides while the gift row is open.
			local inviteBtn = nil
			if yourCell and yourCell.IsLeader and yourCell.MemberCount < yourCell.MaxMembers and not soul.CellName then
				inviteBtn = actionButton(box, "🏯 " .. _g("action_invite", "INVITE"), 0.75, 130, 0.25, COLORS.Green, function()
					cellFire("invite", { TargetUserId = soul.UserId })
				end)
			end

			actionButton(box, "🎁 " .. _g("action_gift", "GIFT $"), 0.25, 130, 0.25, COLORS.Purple, function()
				local showing = not giftBox.Visible
				giftBox.Visible = showing
				confirmBtn.Visible = showing
				duelBtn.Visible = not showing
				if inviteBtn then
					inviteBtn.Visible = not showing
				end
			end)
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

closeButton.MouseButton1Click:Connect(function()
	uiState.closeRoute()
end)

overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if input.Position then
			local absPos = window.AbsolutePosition
			local absSize = window.AbsoluteSize
			local x, y = input.Position.X, input.Position.Y
			if x < absPos.X or x > absPos.X + absSize.X or y < absPos.Y or y > absPos.Y + absSize.Y then
				uiState.closeRoute()
			end
		end
	end
end)

local function init()
	uiState.subscribe(function(route)
		if route == "souls" then
			openPanel()
		else
			closePanel()
		end
	end)
end

local function refreshIfOpen()
	if isOpen then
		fetch()
		refresh()
	end
end

return { init = init, refreshIfOpen = refreshIfOpen }
