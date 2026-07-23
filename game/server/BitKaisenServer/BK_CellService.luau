-- ModuleScript: BK_CellService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose:
--   Multiplayer Fase 7 ("Clanes, Guerras y Territorio"): REAL-player cells
--   (small clans, cap 5 souls -- BitSeas' "crew of captains" intimacy rule)
--   inside a Public world, with a shared treasury, claimable territories,
--   real wars whose scoreboard is fed by live PvP duels (BK_DuelService),
--   truces, alliances/betrayals, and the Juramento de Era (a shared
--   per-era goal that pays the treasury when met).
--
--   Deliberately SEPARATE from BK_ClanWarService/BK_CultWarService -- those
--   are single-player NPC simulations on per-player stats and stay
--   untouched. Everything here is per-WORLD data, persisted in the world's
--   own record via BK_WorldStateService.Mutate (clone-based, crash-safe).
--
--   World-record fields owned by this service (all optional on old
--   records, always accessed with `or {}`):
--     Cells       = { [cellId] = { Name, LeaderUserId, Members = {uidStr=true},
--                     MemberNames = {uidStr=name}, Treasury, CreatedYear,
--                     EraDuelWins, OathPaidEra } }
--     Territories = { [territoryName] = cellId }
--     Wars        = { [warKey "idA|idB"] = { CellA, CellB, ScoreA, ScoreB,
--                     StartYear, TruceOfferedBy } }
--     Alliances   = { [pairKey "idA|idB"] = true }

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BK_WorldStateService = require(script.Parent:WaitForChild("BK_WorldStateService"))

local BK_CellService = {}

local MAX_MEMBERS = 5
local CREATE_COST = 1000
local TERRITORY_INCOME_PER_YEAR = 200
local OATH_DUEL_WINS_GOAL = 5
local OATH_REWARD = 2000
local DEPOSIT_MAX = 100000

-- The claimable map of every Public world: the same 12 Japanese cities the
-- Dojo student system already names (BK_DojoService.JAPAN_STUDENT_LOCATIONS)
-- -- reused instead of inventing a new geography.
local TERRITORY_LIST = {
	"Tokyo", "Kyoto", "Osaka", "Yokohama", "Nagoya", "Sapporo",
	"Fukuoka", "Kobe", "Nara", "Sendai", "Hiroshima", "Kawasaki",
}

local context = {}
local initialized = false
local cellActionRemote
local cellCounter = 0
-- In-memory (same server = same world, per Fase 4): pending invites.
local cellInvites = {}

local function getRemote(name, className)
	local remote = ReplicatedStorage:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = ReplicatedStorage
	end
	return remote
end

local function getStats(player)
	if context.GetStats then
		return context.GetStats(player)
	end
	return nil
end

local function fireLifeUpdate(player, stats, message)
	if context.FireLifeUpdate then
		context.FireLifeUpdate(player, stats, message)
	end
end

local function fireMajorPopup(player, title, body, highlight, footer, style)
	if context.FireMajorPopup then
		context.FireMajorPopup(player, title, body, highlight, footer, style)
	end
end

local function checkRateLimit(player, key)
	if context.CheckRateLimit then
		return context.CheckRateLimit(player, key)
	end
	return true
end

local function isPublicSoul(stats)
	return stats ~= nil and stats.WorldMode == "Public" and stats.Alive ~= false
end

local function pairKey(idA, idB)
	if idA < idB then
		return idA .. "|" .. idB
	end
	return idB .. "|" .. idA
end

local function findCellOf(record, userId)
	local uid = tostring(userId)
	for cellId, cell in pairs(record.Cells or {}) do
		if typeof(cell) == "table" and (cell.Members or {})[uid] then
			return cellId, cell
		end
	end
	return nil, nil
end

local function memberCount(cell)
	local count = 0
	for _ in pairs(cell.Members or {}) do
		count += 1
	end
	return count
end

local function territoriesOf(record, cellId)
	local list = {}
	for name, owner in pairs(record.Territories or {}) do
		if owner == cellId then
			table.insert(list, name)
		end
	end
	table.sort(list)
	return list
end

local function notifyCellMembers(cell, title, body, highlight, style)
	for uidStr in pairs(cell.Members or {}) do
		local member = Players:GetPlayerByUserId(tonumber(uidStr) or 0)
		if member then
			fireMajorPopup(member, title, body, highlight, "Células", style or "info")
		end
	end
end

----------------------------------------------------------------
-- Payload (consumed by BK_SoulsService / the ALMAS tab)
----------------------------------------------------------------

function BK_CellService.GetCellsPayload(worldId, userId)
	local record = BK_WorldStateService.Get(worldId) or {}
	local cells = record.Cells or {}

	local yourCellId, yourCell = findCellOf(record, userId)

	local cellList = {}
	for cellId, cell in pairs(cells) do
		table.insert(cellList, {
			CellId = cellId,
			Name = cell.Name,
			LeaderUserId = cell.LeaderUserId,
			MemberCount = memberCount(cell),
			Territories = territoriesOf(record, cellId),
		})
	end
	table.sort(cellList, function(a, b)
		return a.Name < b.Name
	end)

	-- One flat uidStr -> cellName map so callers (the Souls tab) can tag
	-- every listed soul with its cell from THIS single DataStore read,
	-- instead of one read per soul.
	local membersIndex = {}
	for _, cell in pairs(cells) do
		if typeof(cell) == "table" then
			for uidStr in pairs(cell.Members or {}) do
				membersIndex[uidStr] = cell.Name
			end
		end
	end

	local payload = {
		Cells = cellList,
		TerritoryList = TERRITORY_LIST,
		Territories = record.Territories or {},
		MembersIndex = membersIndex,
	}

	if yourCell then
		local members = {}
		for uidStr in pairs(yourCell.Members or {}) do
			table.insert(members, {
				UserId = tonumber(uidStr),
				Name = (yourCell.MemberNames or {})[uidStr] or ("Life " .. uidStr),
				IsLeader = tostring(yourCell.LeaderUserId) == uidStr,
			})
		end
		table.sort(members, function(a, b)
			if a.IsLeader ~= b.IsLeader then
				return a.IsLeader
			end
			return a.Name < b.Name
		end)

		local wars = {}
		for warKey, war in pairs(record.Wars or {}) do
			if war.CellA == yourCellId or war.CellB == yourCellId then
				local foeCellId = war.CellA == yourCellId and war.CellB or war.CellA
				local foeCell = cells[foeCellId]
				table.insert(wars, {
					WarKey = warKey,
					FoeCellId = foeCellId,
					FoeName = foeCell and foeCell.Name or "Unknown Cell",
					YourScore = war.CellA == yourCellId and (war.ScoreA or 0) or (war.ScoreB or 0),
					FoeScore = war.CellA == yourCellId and (war.ScoreB or 0) or (war.ScoreA or 0),
					TruceOfferedBy = war.TruceOfferedBy,
				})
			end
		end

		local allies = {}
		for key in pairs(record.Alliances or {}) do
			local idA, idB = string.match(key, "^(.-)|(.+)$")
			local allyId = idA == yourCellId and idB or (idB == yourCellId and idA or nil)
			if allyId and cells[allyId] then
				table.insert(allies, { CellId = allyId, Name = cells[allyId].Name })
			end
		end

		payload.YourCell = {
			CellId = yourCellId,
			Name = yourCell.Name,
			IsLeader = yourCell.LeaderUserId == userId,
			Treasury = tonumber(yourCell.Treasury) or 0,
			Members = members,
			MemberCount = #members,
			MaxMembers = MAX_MEMBERS,
			Territories = territoriesOf(record, yourCellId),
			Wars = wars,
			Allies = allies,
			EraDuelWins = tonumber(yourCell.EraDuelWins) or 0,
			OathGoal = OATH_DUEL_WINS_GOAL,
			OathReward = OATH_REWARD,
		}
	end

	local invite = cellInvites[userId]
	if invite and os.time() <= invite.ExpiresAt and cells[invite.CellId] then
		payload.PendingInvite = {
			CellId = invite.CellId,
			CellName = cells[invite.CellId].Name,
			FromName = invite.FromName,
		}
	end

	return payload
end

----------------------------------------------------------------
-- Actions
----------------------------------------------------------------

local function handleCreate(player, stats, worldId, data)
	local name = typeof(data) == "table" and tostring(data.Name or "") or ""
	name = name:sub(1, 24)
	if name == "" then
		return
	end
	if (tonumber(stats.Money) or 0) < CREATE_COST then
		fireLifeUpdate(player, stats, "🏯 Founding a cell costs $" .. tostring(CREATE_COST) .. ".")
		return
	end

	cellCounter += 1
	local newCellId = "cell_" .. tostring(player.UserId) .. "_" .. tostring(cellCounter) .. "_" .. tostring(os.time())
	local created = false

	BK_WorldStateService.Mutate(worldId, function(record)
		if findCellOf(record, player.UserId) then
			return record
		end
		local cells = typeof(record.Cells) == "table" and table.clone(record.Cells) or {}
		cells[newCellId] = {
			Name = name,
			LeaderUserId = player.UserId,
			Members = { [tostring(player.UserId)] = true },
			MemberNames = { [tostring(player.UserId)] = tostring(stats.Name or player.Name) },
			Treasury = 0,
			CreatedYear = tonumber(stats.CurrentYear) or 0,
			EraDuelWins = 0,
		}
		record.Cells = cells
		created = true
		return record
	end)

	if created then
		stats.Money = (tonumber(stats.Money) or 0) - CREATE_COST
		player:SetAttribute("BKChatCell", name)
		fireMajorPopup(player, "CELL FOUNDED", "Your cell '" .. name .. "' now exists in this world. Recruit up to " .. tostring(MAX_MEMBERS - 1) .. " more lives from the Lives tab.", "🏯 " .. name, "Células", "success")
		fireLifeUpdate(player, stats, "🏯 You founded the cell '" .. name .. "' (-$" .. tostring(CREATE_COST) .. ").")
		if context.ForceSaveStats then
			context.ForceSaveStats(player, "CellFounded")
		end
	else
		fireLifeUpdate(player, stats, "🏯 You already belong to a cell.")
	end
end

local function handleInvite(player, stats, worldId, data)
	local targetPlayer = Players:GetPlayerByUserId(tonumber(typeof(data) == "table" and data.TargetUserId or nil) or 0)
	if not targetPlayer or targetPlayer == player then
		return
	end
	local targetStats = getStats(targetPlayer)
	if not isPublicSoul(targetStats) or targetStats.PublicWorldId ~= worldId then
		return
	end

	local record = BK_WorldStateService.Get(worldId) or {}
	local cellId, cell = findCellOf(record, player.UserId)
	if not cell or cell.LeaderUserId ~= player.UserId then
		fireLifeUpdate(player, stats, "🏯 Only a cell leader can invite.")
		return
	end
	if memberCount(cell) >= MAX_MEMBERS then
		fireLifeUpdate(player, stats, "🏯 Your cell is full (" .. tostring(MAX_MEMBERS) .. ").")
		return
	end
	if findCellOf(record, targetPlayer.UserId) then
		fireLifeUpdate(player, stats, "🏯 That life already belongs to a cell.")
		return
	end

	cellInvites[targetPlayer.UserId] = {
		CellId = cellId,
		FromUserId = player.UserId,
		FromName = tostring(stats.Name or player.Name),
		ExpiresAt = os.time() + 120,
	}
	fireMajorPopup(targetPlayer, "CELL INVITATION", tostring(stats.Name or player.Name) .. " invites you to join the cell '" .. tostring(cell.Name) .. "'. Open the Lives tab to answer.", "🏯 " .. tostring(cell.Name), "Células", "info")
	fireLifeUpdate(player, stats, "🏯 Invitation sent to " .. tostring(targetStats.Name or targetPlayer.Name) .. ".")
end

local function handleAcceptInvite(player, stats, worldId)
	local invite = cellInvites[player.UserId]
	cellInvites[player.UserId] = nil
	if not invite or os.time() > invite.ExpiresAt then
		return
	end

	local joinedName = nil
	BK_WorldStateService.Mutate(worldId, function(record)
		local cells = typeof(record.Cells) == "table" and table.clone(record.Cells) or {}
		local cell = cells[invite.CellId]
		if not cell or findCellOf(record, player.UserId) or memberCount(cell) >= MAX_MEMBERS then
			return record
		end
		cell = table.clone(cell)
		cell.Members = table.clone(cell.Members or {})
		cell.MemberNames = table.clone(cell.MemberNames or {})
		cell.Members[tostring(player.UserId)] = true
		cell.MemberNames[tostring(player.UserId)] = tostring(stats.Name or player.Name)
		cells[invite.CellId] = cell
		record.Cells = cells
		joinedName = cell.Name
		return record
	end)

	if joinedName then
		player:SetAttribute("BKChatCell", joinedName)
		fireMajorPopup(player, "CELL JOINED", "You are now part of '" .. joinedName .. "'.", "🏯 " .. joinedName, "Células", "success")
		local leader = Players:GetPlayerByUserId(invite.FromUserId)
		if leader then
			local leaderStats = getStats(leader)
			if leaderStats then
				fireLifeUpdate(leader, leaderStats, "🏯 " .. tostring(stats.Name or player.Name) .. " joined your cell.")
			end
		end
	end
end

local function handleLeave(player, stats, worldId)
	local leftName = nil
	BK_WorldStateService.Mutate(worldId, function(record)
		local cellId, cell = findCellOf(record, player.UserId)
		if not cell then
			return record
		end
		local cells = table.clone(record.Cells)
		cell = table.clone(cell)
		cell.Members = table.clone(cell.Members or {})
		cell.MemberNames = table.clone(cell.MemberNames or {})
		cell.Members[tostring(player.UserId)] = nil
		cell.MemberNames[tostring(player.UserId)] = nil
		leftName = cell.Name

		if next(cell.Members) == nil then
			-- Last soul out: the cell dissolves, its territories go free,
			-- its wars and alliances end.
			cells[cellId] = nil
			local territories = table.clone(record.Territories or {})
			for name, owner in pairs(territories) do
				if owner == cellId then
					territories[name] = nil
				end
			end
			record.Territories = territories
			local wars = table.clone(record.Wars or {})
			for warKey, war in pairs(wars) do
				if war.CellA == cellId or war.CellB == cellId then
					wars[warKey] = nil
				end
			end
			record.Wars = wars
			local alliances = table.clone(record.Alliances or {})
			for key in pairs(alliances) do
				if key:find(cellId, 1, true) then
					alliances[key] = nil
				end
			end
			record.Alliances = alliances
		else
			if cell.LeaderUserId == player.UserId then
				-- Leadership passes to any remaining member.
				local nextLeader = next(cell.Members)
				cell.LeaderUserId = tonumber(nextLeader)
			end
			cells[cellId] = cell
		end
		record.Cells = cells
		return record
	end)

	if leftName then
		player:SetAttribute("BKChatCell", nil)
		fireLifeUpdate(player, stats, "🏯 You left the cell '" .. tostring(leftName) .. "'.")
	end
end

local function handleDeposit(player, stats, worldId, data)
	local amount = math.floor(tonumber(typeof(data) == "table" and data.Amount or nil) or 0)
	amount = math.clamp(amount, 0, DEPOSIT_MAX)
	if amount <= 0 or (tonumber(stats.Money) or 0) < amount then
		return
	end

	local deposited = false
	BK_WorldStateService.Mutate(worldId, function(record)
		local cellId, cell = findCellOf(record, player.UserId)
		if not cell then
			return record
		end
		local cells = table.clone(record.Cells)
		cell = table.clone(cell)
		cell.Treasury = (tonumber(cell.Treasury) or 0) + amount
		cells[cellId] = cell
		record.Cells = cells
		deposited = true
		return record
	end)

	if deposited then
		stats.Money = (tonumber(stats.Money) or 0) - amount
		fireLifeUpdate(player, stats, "💰 You deposited $" .. tostring(amount) .. " into the cell treasury.")
		if context.ForceSaveStats then
			context.ForceSaveStats(player, "CellDeposit")
		end
	end
end

local function handleWithdraw(player, stats, worldId, data)
	local amount = math.floor(tonumber(typeof(data) == "table" and data.Amount or nil) or 0)
	if amount <= 0 then
		return
	end

	local withdrawn = false
	BK_WorldStateService.Mutate(worldId, function(record)
		local cellId, cell = findCellOf(record, player.UserId)
		if not cell or cell.LeaderUserId ~= player.UserId then
			return record
		end
		if (tonumber(cell.Treasury) or 0) < amount then
			return record
		end
		local cells = table.clone(record.Cells)
		cell = table.clone(cell)
		cell.Treasury = (tonumber(cell.Treasury) or 0) - amount
		cells[cellId] = cell
		record.Cells = cells
		withdrawn = true
		return record
	end)

	if withdrawn then
		stats.Money = (tonumber(stats.Money) or 0) + amount
		fireLifeUpdate(player, stats, "💰 You withdrew $" .. tostring(amount) .. " from the cell treasury.")
		if context.ForceSaveStats then
			context.ForceSaveStats(player, "CellWithdraw")
		end
	else
		fireLifeUpdate(player, stats, "💰 Only the leader can withdraw, and only what the treasury holds.")
	end
end

local function handleClaim(player, stats, worldId, data)
	local territory = typeof(data) == "table" and tostring(data.Territory or "") or ""
	if not table.find(TERRITORY_LIST, territory) then
		return
	end

	local claimed = false
	BK_WorldStateService.Mutate(worldId, function(record)
		local cellId, cell = findCellOf(record, player.UserId)
		if not cell or cell.LeaderUserId ~= player.UserId then
			return record
		end
		local territories = table.clone(record.Territories or {})
		if territories[territory] then
			return record
		end
		-- One free claim per cell; more territory only through war.
		if #territoriesOf(record, cellId) >= 1 then
			return record
		end
		territories[territory] = cellId
		record.Territories = territories
		claimed = true
		return record
	end)

	if claimed then
		local record = BK_WorldStateService.Get(worldId) or {}
		local _, cell = findCellOf(record, player.UserId)
		BK_WorldStateService.AddEvent(worldId, tonumber(stats.CurrentYear) or 0, "🚩 The cell '" .. tostring(cell and cell.Name) .. "' raised its banner over " .. territory .. ".")
		fireMajorPopup(player, "TERRITORY CLAIMED", territory .. " now flies your cell's banner. Every year it feeds your treasury.", "🚩 " .. territory, "Células", "success")
	else
		fireLifeUpdate(player, stats, "🚩 Claim failed: leaders only, one free territory per cell, and it must be unclaimed. War wins more.")
	end
end

local function handleDeclareWar(player, stats, worldId, data)
	local targetCellId = typeof(data) == "table" and tostring(data.TargetCellId or "") or ""
	local declared = false
	local foeName = nil

	BK_WorldStateService.Mutate(worldId, function(record)
		local cellId, cell = findCellOf(record, player.UserId)
		local foeCell = (record.Cells or {})[targetCellId]
		if not cell or cell.LeaderUserId ~= player.UserId or not foeCell or targetCellId == cellId then
			return record
		end
		if (record.Alliances or {})[pairKey(cellId, targetCellId)] then
			return record
		end
		local warKey = pairKey(cellId, targetCellId)
		local wars = table.clone(record.Wars or {})
		if wars[warKey] then
			return record
		end
		wars[warKey] = {
			CellA = cellId,
			CellB = targetCellId,
			ScoreA = 0,
			ScoreB = 0,
			StartYear = tonumber(stats.CurrentYear) or 0,
		}
		record.Wars = wars
		declared = true
		foeName = foeCell.Name
		return record
	end)

	if declared then
		BK_WorldStateService.AddEvent(worldId, tonumber(stats.CurrentYear) or 0, "⚔ WAR: two cells now feud openly. Every duel between their lives counts.")
		local record = BK_WorldStateService.Get(worldId) or {}
		local foeCell = (record.Cells or {})[targetCellId]
		if foeCell then
			notifyCellMembers(foeCell, "WAR DECLARED", "The cell of " .. tostring(stats.Name or player.Name) .. " declared war on '" .. tostring(foeName) .. "'. Duels between your cells now feed the war score -- the era's end settles it.", "⚔ WAR", "warning")
		end
		fireMajorPopup(player, "WAR DECLARED", "Your cell is now at war with '" .. tostring(foeName) .. "'. Win duels against their lives; when the Era turns, the leader takes a territory.", "⚔ WAR", "warning")
	else
		fireLifeUpdate(player, stats, "⚔ War refused: leaders only, no warring allies, no duplicate wars.")
	end
end

local function handleTruce(player, stats, worldId, data, isAccept)
	local warKey = typeof(data) == "table" and tostring(data.WarKey or "") or ""
	local resolved = false
	BK_WorldStateService.Mutate(worldId, function(record)
		local cellId, cell = findCellOf(record, player.UserId)
		local wars = table.clone(record.Wars or {})
		local war = wars[warKey]
		if not cell or cell.LeaderUserId ~= player.UserId or not war then
			return record
		end
		if war.CellA ~= cellId and war.CellB ~= cellId then
			return record
		end
		if isAccept then
			if war.TruceOfferedBy and war.TruceOfferedBy ~= cellId then
				wars[warKey] = nil
				record.Wars = wars
				resolved = true
			end
		else
			war = table.clone(war)
			war.TruceOfferedBy = cellId
			wars[warKey] = war
			record.Wars = wars
			resolved = true
		end
		return record
	end)

	if resolved then
		if isAccept then
			BK_WorldStateService.AddEvent(worldId, tonumber(stats.CurrentYear) or 0, "🕊 A truce was signed -- a cell war ends without a victor.")
			fireLifeUpdate(player, stats, "🕊 Truce accepted. The war is over.")
		else
			fireLifeUpdate(player, stats, "🕊 Truce offered. The other leader must accept it from the Lives tab.")
		end
	end
end

local function handleAlliance(player, stats, worldId, data, isBreak)
	local targetCellId = typeof(data) == "table" and tostring(data.TargetCellId or "") or ""
	local changed = false
	local foeName = nil

	BK_WorldStateService.Mutate(worldId, function(record)
		local cellId, cell = findCellOf(record, player.UserId)
		local otherCell = (record.Cells or {})[targetCellId]
		if not cell or cell.LeaderUserId ~= player.UserId or not otherCell or targetCellId == cellId then
			return record
		end
		local key = pairKey(cellId, targetCellId)
		local alliances = table.clone(record.Alliances or {})
		if isBreak then
			if not alliances[key] then
				return record
			end
			alliances[key] = nil
		else
			if alliances[key] or (record.Wars or {})[key] then
				return record
			end
			alliances[key] = true
		end
		record.Alliances = alliances
		changed = true
		foeName = otherCell.Name
		return record
	end)

	if changed then
		if isBreak then
			BK_WorldStateService.AddEvent(worldId, tonumber(stats.CurrentYear) or 0, "🗡 BETRAYAL: an alliance between cells was broken.")
			fireLifeUpdate(player, stats, "🗡 You broke the alliance with '" .. tostring(foeName) .. "'. The world will remember.")
		else
			BK_WorldStateService.AddEvent(worldId, tonumber(stats.CurrentYear) or 0, "🤝 Two cells swore an alliance.")
			fireLifeUpdate(player, stats, "🤝 Alliance sealed with '" .. tostring(foeName) .. "'.")
		end
	end
end

----------------------------------------------------------------
-- Hooks (called by BK_DuelService / GameManager)
----------------------------------------------------------------

-- Every finished PvP duel feeds war scoreboards and the Juramento de Era.
function BK_CellService.OnDuelResult(worldId, winnerUserId, loserUserId)
	BK_WorldStateService.Mutate(worldId, function(record)
		local winnerCellId = findCellOf(record, winnerUserId)
		local loserCellId = findCellOf(record, loserUserId)
		if not winnerCellId then
			return record
		end

		-- Juramento de Era: cell-wide duel wins this era.
		local cells = table.clone(record.Cells)
		local winnerCell = table.clone(cells[winnerCellId])
		winnerCell.EraDuelWins = (tonumber(winnerCell.EraDuelWins) or 0) + 1
		cells[winnerCellId] = winnerCell
		record.Cells = cells

		-- War score: only duels between the two warring cells count.
		if loserCellId and loserCellId ~= winnerCellId then
			local warKey = pairKey(winnerCellId, loserCellId)
			local wars = table.clone(record.Wars or {})
			local war = wars[warKey]
			if war then
				war = table.clone(war)
				if war.CellA == winnerCellId then
					war.ScoreA = (tonumber(war.ScoreA) or 0) + 1
				else
					war.ScoreB = (tonumber(war.ScoreB) or 0) + 1
				end
				wars[warKey] = war
				record.Wars = wars
			end
		end
		return record
	end)
end

-- Yearly territory income into each owning cell's treasury.
function BK_CellService.OnPublicYearAdvanced(worldId)
	BK_WorldStateService.Mutate(worldId, function(record)
		local territories = record.Territories or {}
		local income = {}
		for _, owner in pairs(territories) do
			income[owner] = (income[owner] or 0) + TERRITORY_INCOME_PER_YEAR
		end
		if next(income) == nil then
			return record
		end
		local cells = table.clone(record.Cells or {})
		for cellId, amount in pairs(income) do
			local cell = cells[cellId]
			if cell then
				cell = table.clone(cell)
				cell.Treasury = (tonumber(cell.Treasury) or 0) + amount
				cells[cellId] = cell
			end
		end
		record.Cells = cells
		return record
	end)
end

-- Era close settles everything: wars resolve (winner takes ONE territory
-- from the loser -- or an unclaimed one if the loser holds none), and the
-- Juramento de Era pays out and resets.
function BK_CellService.OnEraChanged(worldId, newYear)
	local announcements = {}

	BK_WorldStateService.Mutate(worldId, function(record)
		local cells = table.clone(record.Cells or {})
		local wars = record.Wars or {}
		local territories = table.clone(record.Territories or {})

		for _, war in pairs(wars) do
			local scoreA = tonumber(war.ScoreA) or 0
			local scoreB = tonumber(war.ScoreB) or 0
			if scoreA ~= scoreB then
				local winnerId = scoreA > scoreB and war.CellA or war.CellB
				local loserId = scoreA > scoreB and war.CellB or war.CellA
				local winnerCell = cells[winnerId]
				local loserCell = cells[loserId]
				if winnerCell and loserCell then
					local taken = nil
					for name, owner in pairs(territories) do
						if owner == loserId then
							taken = name
							break
						end
					end
					if not taken then
						for _, name in ipairs(TERRITORY_LIST) do
							if not territories[name] then
								taken = name
								break
							end
						end
					end
					if taken then
						territories[taken] = winnerId
					end
					table.insert(announcements, "⚔ The era closes a war: '" .. tostring(winnerCell.Name) .. "' defeats '" .. tostring(loserCell.Name) .. "'" .. (taken and (" and takes " .. taken .. ".") or "."))
				end
			else
				table.insert(announcements, "⚔ A cell war ends the era in a dead heat -- no territory changes hands.")
			end
		end
		record.Wars = {}
		record.Territories = territories

		for cellId, cell in pairs(cells) do
			cell = table.clone(cell)
			if (tonumber(cell.EraDuelWins) or 0) >= OATH_DUEL_WINS_GOAL then
				cell.Treasury = (tonumber(cell.Treasury) or 0) + OATH_REWARD
				table.insert(announcements, "📜 The cell '" .. tostring(cell.Name) .. "' fulfilled its Juramento de Era (+$" .. tostring(OATH_REWARD) .. " to its treasury).")
			end
			cell.EraDuelWins = 0
			cells[cellId] = cell
		end
		record.Cells = cells
		return record
	end)

	for _, text in ipairs(announcements) do
		BK_WorldStateService.AddEvent(worldId, tonumber(newYear) or 0, text)
	end
end

----------------------------------------------------------------
-- Wiring
----------------------------------------------------------------

local function handleAction(player, actionId, data)
	if not checkRateLimit(player, "CellAction") then
		return
	end
	local stats = getStats(player)
	if not isPublicSoul(stats) then
		return
	end
	local worldId = stats.PublicWorldId
	if typeof(worldId) ~= "string" or worldId == "" then
		return
	end

	if actionId == "create" then
		handleCreate(player, stats, worldId, data)
	elseif actionId == "invite" then
		handleInvite(player, stats, worldId, data)
	elseif actionId == "accept_invite" then
		handleAcceptInvite(player, stats, worldId)
	elseif actionId == "decline_invite" then
		cellInvites[player.UserId] = nil
	elseif actionId == "leave" then
		handleLeave(player, stats, worldId)
	elseif actionId == "deposit" then
		handleDeposit(player, stats, worldId, data)
	elseif actionId == "withdraw" then
		handleWithdraw(player, stats, worldId, data)
	elseif actionId == "claim" then
		handleClaim(player, stats, worldId, data)
	elseif actionId == "declare_war" then
		handleDeclareWar(player, stats, worldId, data)
	elseif actionId == "offer_truce" then
		handleTruce(player, stats, worldId, data, false)
	elseif actionId == "accept_truce" then
		handleTruce(player, stats, worldId, data, true)
	elseif actionId == "offer_alliance" then
		handleAlliance(player, stats, worldId, data, false)
	elseif actionId == "break_alliance" then
		handleAlliance(player, stats, worldId, data, true)
	end
end

function BK_CellService.Init(ctx)
	if initialized then return end
	initialized = true
	context = ctx or {}

	cellActionRemote = getRemote("CellAction", "RemoteEvent")
	cellActionRemote.OnServerEvent:Connect(handleAction)

	Players.PlayerRemoving:Connect(function(player)
		cellInvites[player.UserId] = nil
	end)
end

return BK_CellService
