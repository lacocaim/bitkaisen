--[[
	BitKaisenSaveSystem -- ProfileStore Adapter

	This module preserves the original public API so GameManager and all BK_*
	services continue to work unchanged. Internally it delegates to
	accountService (ProfileStore + Charm + delta-compress).

	Session locking prevents data loss from dual-server conflicts.
	Auto-save is handled by ProfileStore.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local accountService = require(ServerScriptService:WaitForChild("global"):WaitForChild("services"):WaitForChild("accountService"))
local schema = require(ServerScriptService:WaitForChild("global"):WaitForChild("services"):WaitForChild("accountService"):WaitForChild("schema"))

local BitKaisenSaveSystem = {}

local function deepClone(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local clone = table.clone(t)
	for k, v in clone do
		if type(v) == "table" then
			clone[k] = deepClone(v)
		end
	end
	return clone
end

local DEFAULT_SLOT_COUNT = schema.DEFAULT_SLOT_COUNT

local function buildCleanStats(stats)
	local cleanStats = {}
	for k, v in stats do
		if k == "__SlotId" or k == "__SelectedSlot" or k == "__PublicWorldId" then
			continue
		end
		if typeof(v) == "function" or typeof(v) == "Instance" or typeof(v) == "RBXScriptConnection" then
			continue
		end
		if typeof(v) == "table" then
			cleanStats[k] = deepClone(v)
		else
			cleanStats[k] = v
		end
	end
	cleanStats.DataVersion = cleanStats.DataVersion or 2
	cleanStats.LastSaved = os.time()
	return cleanStats
end

local PROFILE_WAIT_TIMEOUT = 30

local function waitForProfile(player: Player): boolean
	local elapsed = 0
	while player and player.Parent and elapsed < PROFILE_WAIT_TIMEOUT do
		if accountService.getAccountFor(player) then
			return true
		end
		task.wait(0.2)
		elapsed += 0.2
	end
	return accountService.getAccountFor(player) ~= nil
end

local function getAccountData(player: Player): schema.Account?
	return accountService.getAccountFor(player)
end

local function buildSummaryFromStats(stats, slotId: number): schema.SlotSummary
	local summary = schema.makeEmptySlotSummary(slotId)
	if typeof(stats) ~= "table" then
		return summary
	end

	summary.Exists = true
	local firstName = tostring(stats.FirstName or "")
	local familyName = tostring(stats.FamilyName or "")

	if firstName ~= "" and firstName ~= "Unknown" and familyName ~= "" and familyName ~= "Unknown" and familyName ~= "None" then
		summary.Name = firstName .. " " .. familyName
	else
		summary.Name = tostring(stats.Name or "Unknown")
	end

	summary.Age = tonumber(stats.Age) or 0
	summary.CurrentMonth = math.clamp(tonumber(stats.CurrentMonth) or 1, 1, 12)
	summary.MonthsIntoAge = math.clamp(tonumber(stats.MonthsIntoAge) or 0, 0, 11)
	summary.Grade = tostring(stats.Grade or "Unknown")
	summary.Generation = tonumber(stats.Generation) or 1
	summary.FirstName = firstName ~= "" and firstName or "Unknown"
	summary.FamilyName = familyName ~= "" and familyName or "Unknown"
	summary.Origin = tostring(stats.Origin or stats.Clan or "Unknown")
	summary.Clan = tostring(stats.Clan or stats.Origin or "Unknown")
	summary.Gender = tostring(stats.Gender or "Unknown")
	summary.CursedTechnique = tostring(stats.CursedTechnique or "None")
	summary.Alive = stats.Alive ~= false
	summary.LastPlayed = os.time()
	summary.LastSaved = os.time()

	return summary
end

function BitKaisenSaveSystem.Init()
	if _G.__BitKaisenSaveSystemInitialized then
		return
	end
	_G.__BitKaisenSaveSystemInitialized = true
	accountService.init()
end

function BitKaisenSaveSystem.GetSlotCount()
	return DEFAULT_SLOT_COUNT
end

function BitKaisenSaveSystem.GetSelectedSlot(player)
	if not player then
		return 1
	end
	local account = getAccountData(player)
	if account then
		return account.selectedSlot or 1
	end
	return 1
end

function BitKaisenSaveSystem.GetSlots(player, hasVIP)
	if not player then
		return {
			SelectedSlot = 1,
			SlotCount = DEFAULT_SLOT_COUNT,
			Slots = {},
		}
	end

	waitForProfile(player)

	local account = getAccountData(player)
	if not account then
		return {
			SelectedSlot = 1,
			SlotCount = DEFAULT_SLOT_COUNT,
			Slots = {},
		}
	end

	local hasSlotAccess = hasVIP == true or account.extraSlotsUnlocked == true
	local slots = {}
	for i = 1, DEFAULT_SLOT_COUNT do
		local slotData = account.slots[i]
		if slotData then
			local summary = slotData.summary
			local copy = {}
			for k, v in summary do
				copy[k] = v
			end
			copy.Locked = (i > 1 and not hasSlotAccess)
			slots[i] = copy
		else
			local empty = schema.makeEmptySlotSummary(i)
			empty.Locked = (i > 1 and not hasSlotAccess)
			slots[i] = empty
		end
	end

	return {
		SelectedSlot = account.selectedSlot or 1,
		SlotCount = DEFAULT_SLOT_COUNT,
		ExtraSaveSlotsUnlocked = account.extraSlotsUnlocked == true,
		Slots = slots,
	}
end

function BitKaisenSaveSystem.SelectSlot(player, slotId, hasVIP)
	if not player or not player.Parent then
		return false, "Player not found."
	end

	slotId = math.clamp(tonumber(slotId) or 1, 1, DEFAULT_SLOT_COUNT)

	local account = getAccountData(player)
	if not account then
		return false, "Account not loaded."
	end

	local hasSlotAccess = hasVIP == true or account.extraSlotsUnlocked == true
	if slotId > 1 and not hasSlotAccess then
		return false, "That slot is locked."
	end

	local slotData = account.slots[slotId]
	if not slotData or not slotData.exists then
		return false, "That slot is empty."
	end

	accountService.transaction(function(tx)
		tx(player, function()
			accountService.mutateData(function(acc)
				local new = table.clone(acc)
				new.selectedSlot = slotId
				return new
			end)
		end)
	end)

	return true, nil
end

function BitKaisenSaveSystem.SetSelectedSlot(player, slotId, hasVIP)
	if not player or not player.Parent then
		return false, "Player not found."
	end

	slotId = math.clamp(tonumber(slotId) or 1, 1, DEFAULT_SLOT_COUNT)

	local account = getAccountData(player)
	if not account then
		return false, "Account not loaded."
	end

	local hasSlotAccess = hasVIP == true or account.extraSlotsUnlocked == true
	if slotId > 1 and not hasSlotAccess then
		return false, "That slot is locked."
	end

	accountService.transaction(function(tx)
		tx(player, function()
			accountService.mutateData(function(acc)
				local new = table.clone(acc)
				new.selectedSlot = slotId
				return new
			end)
		end)
	end)

	return true, nil
end

function BitKaisenSaveSystem.LoadSlot(player, slotId)
	if not player or not player.Parent then
		return nil
	end

	slotId = math.clamp(tonumber(slotId) or 1, 1, DEFAULT_SLOT_COUNT)

	local account = getAccountData(player)
	if not account then
		return nil
	end

	local slotData = account.slots[slotId]
	if not slotData or not slotData.exists or not slotData.stats then
		return nil
	end

	local stats = {}
	for k, v in slotData.stats do
		if typeof(v) == "table" then
			stats[k] = deepClone(v)
		else
			stats[k] = v
		end
	end
	stats.__SlotId = slotId

	return stats
end

-- Multiplayer Fase 1: mirrors LoadSlot, but reads a Public-mode save from
-- account.publicWorldSaves[worldId] instead of the 3 private account.slots.
function BitKaisenSaveSystem.LoadPublicWorld(player, worldId)
	if not player or not player.Parent then
		return nil
	end
	if typeof(worldId) ~= "string" or worldId == "" then
		return nil
	end

	local account = getAccountData(player)
	if not account then
		return nil
	end

	local saves = account.publicWorldSaves
	local slotData = saves and saves[worldId]
	if not slotData or not slotData.exists or not slotData.stats then
		return nil
	end

	local stats = {}
	for k, v in slotData.stats do
		if typeof(v) == "table" then
			stats[k] = deepClone(v)
		else
			stats[k] = v
		end
	end
	stats.__PublicWorldId = worldId

	return stats
end

function BitKaisenSaveSystem.Load(player, hasVIP)
	if not player or not player.Parent then
		return nil
	end

	if not waitForProfile(player) then
		warn("[BitKaisenSaveSystem] Timed out waiting for profile to load for " .. tostring(player.Name))
		return nil
	end

	local account = getAccountData(player)
	if not account then
		return nil
	end

	-- Multiplayer Fase 1: Public/Private is now an explicit per-join choice
	-- (see GameManager's PromptWorldMode/loadOrStartLife) rather than
	-- something Load() infers on its own -- callers who want the Public
	-- save call LoadPublicWorld directly. This always resolves the private
	-- slots, same as before Fase 1 existed.
	local selectedSlot = account.selectedSlot or 1
	local loaded = BitKaisenSaveSystem.LoadSlot(player, selectedSlot)
	return loaded
end

function BitKaisenSaveSystem.Save(player, stats, slotId)
	if not player then
		return false
	end
	if typeof(stats) ~= "table" then
		return false
	end

	-- Multiplayer Fase 1: a Public-mode life is keyed by world id, not one of
	-- the 3 private slots. Routes to account.publicWorldSaves instead.
	if stats.WorldMode == "Public" then
		local worldId = tostring(stats.PublicWorldId or "")
		if worldId == "" then
			return false
		end

		local cleanStats = buildCleanStats(stats)
		local summary = buildSummaryFromStats(cleanStats, 0)

		accountService.transaction(function(tx)
			tx(player, function()
				accountService.mutateData(function(acc)
					local new = table.clone(acc)
					local newPublicSaves = table.clone(new.publicWorldSaves or {})
					-- Fase 8: clone the EXISTING entry first (not a fresh
					-- table literal) so sibling fields like GodModeUnlocked
					-- survive every autosave instead of being silently
					-- wiped -- same class of bug already caught once in
					-- BK_WorldStateService.
					local existingEntry = newPublicSaves[worldId]
					local newEntry = typeof(existingEntry) == "table" and table.clone(existingEntry) or {}
					newEntry.exists = true
					newEntry.summary = summary
					newEntry.stats = cleanStats
					newPublicSaves[worldId] = newEntry
					new.publicWorldSaves = newPublicSaves
					new.lastWorldMode = "Public"
					new.lastPublicWorldId = worldId
					return new
				end)
			end)
		end)

		stats.__PublicWorldId = worldId
		return true
	end

	local resolvedSlot = tonumber(slotId) or tonumber(stats.__SlotId)
	if not resolvedSlot then
		local account = getAccountData(player)
		resolvedSlot = account and account.selectedSlot or 1
	end
	resolvedSlot = math.clamp(tonumber(resolvedSlot) or 1, 1, DEFAULT_SLOT_COUNT)

	local cleanStats = buildCleanStats(stats)
	cleanStats.SlotId = resolvedSlot

	local summary = buildSummaryFromStats(cleanStats, resolvedSlot)

	accountService.transaction(function(tx)
		tx(player, function()
			accountService.mutateData(function(acc)
				local new = table.clone(acc)
				local newSlots = table.clone(new.slots)
				newSlots[resolvedSlot] = {
					exists = true,
					summary = summary,
					stats = cleanStats,
				}
				new.slots = newSlots
				new.selectedSlot = resolvedSlot
				new.lastWorldMode = "Private"
				return new
			end)
		end)
	end)

	stats.__SlotId = resolvedSlot
	return true
end

function BitKaisenSaveSystem.CreateSlot(player, slotId, stats, hasVIP)
	if not player or not player.Parent then
		return false, "Player not found."
	end

	slotId = math.clamp(tonumber(slotId) or 1, 1, DEFAULT_SLOT_COUNT)

	local account = getAccountData(player)
	if not account then
		return false, "Account not loaded."
	end

	local hasSlotAccess = hasVIP == true or account.extraSlotsUnlocked == true
	if slotId > 1 and not hasSlotAccess then
		return false, "That slot is locked."
	end

	local slotData = account.slots[slotId]
	if slotData and slotData.exists then
		return false, "That slot already has a life."
	end

	if typeof(stats) ~= "table" then
		return false, "Missing life data."
	end

	stats.__SlotId = slotId
	BitKaisenSaveSystem.Save(player, stats, slotId)
	return true, nil
end

function BitKaisenSaveSystem.DeleteSlot(player, slotId, hasVIP)
	if not player or not player.Parent then
		return false, "Player not found."
	end

	slotId = math.clamp(tonumber(slotId) or 1, 1, DEFAULT_SLOT_COUNT)

	local account = getAccountData(player)
	if not account then
		return false, "Account not loaded."
	end

	local hasSlotAccess = hasVIP == true or account.extraSlotsUnlocked == true
	if slotId > 1 and not hasSlotAccess then
		return false, "That slot is locked."
	end

	local newSelectedSlot = account.selectedSlot
	if newSelectedSlot == slotId then
		newSelectedSlot = nil
		for candidateSlot = 1, DEFAULT_SLOT_COUNT do
			if candidateSlot ~= slotId then
				local cd = account.slots[candidateSlot]
				if cd and cd.exists then
					newSelectedSlot = candidateSlot
					break
				end
			end
		end
		newSelectedSlot = newSelectedSlot or 1
	end

	accountService.transaction(function(tx)
		tx(player, function()
			accountService.mutateData(function(acc)
				local new = table.clone(acc)
				local newSlots = table.clone(new.slots)
				newSlots[slotId] = {
					exists = false,
					summary = schema.makeEmptySlotSummary(slotId),
					stats = nil,
				}
				new.slots = newSlots
				new.selectedSlot = newSelectedSlot
				return new
			end)
		end)
	end)

	return true, nil
end

function BitKaisenSaveSystem.HasAccountRewardClaimed(player, rewardKey)
	if not player or rewardKey == nil then
		return false
	end
	local account = getAccountData(player)
	if not account then
		return false
	end
	return account.accountRewards[tostring(rewardKey)] == true
end

function BitKaisenSaveSystem.MarkAccountRewardClaimed(player, rewardKey)
	if not player or rewardKey == nil then
		return false
	end
	accountService.transaction(function(tx)
		tx(player, function()
			accountService.mutateData(function(acc)
				local new = table.clone(acc)
				local newRewards = table.clone(new.accountRewards)
				newRewards[tostring(rewardKey)] = true
				new.accountRewards = newRewards
				return new
			end)
		end)
	end)
	return true
end

function BitKaisenSaveSystem.HasGroupJoinRewardClaimed(player)
	return BitKaisenSaveSystem.HasAccountRewardClaimed(player, "GroupJoinRewardClaimed")
end

function BitKaisenSaveSystem.MarkGroupJoinRewardClaimed(player)
	return BitKaisenSaveSystem.MarkAccountRewardClaimed(player, "GroupJoinRewardClaimed")
end

function BitKaisenSaveSystem.GetAccountDailyLogin(player)
	if not player then
		return {}
	end
	local account = getAccountData(player)
	if not account then
		return {}
	end
	return deepClone(account.dailyLogin or {})
end

function BitKaisenSaveSystem.SetAccountDailyLogin(player, dailyData)
	if not player then
		return false
	end
	local cleanDaily = typeof(dailyData) == "table" and deepClone(dailyData) or {}
	accountService.transaction(function(tx)
		tx(player, function()
			accountService.mutateData(function(acc)
				local new = table.clone(acc)
				new.dailyLogin = cleanDaily
				return new
			end)
		end)
	end)
	return true
end

function BitKaisenSaveSystem.ClearAccountDailyLogin(player)
	return BitKaisenSaveSystem.SetAccountDailyLogin(player, {})
end

function BitKaisenSaveSystem.ReleaseSession(userId)
	-- ProfileStore handles session lifecycle automatically via accountService
end

function BitKaisenSaveSystem.IsSessionActive(userId)
	local player = Players:GetPlayerByUserId(userId)
	if not player then
		return false
	end
	return getAccountData(player) ~= nil
end

function BitKaisenSaveSystem.UnlockExtraSaveSlots(player)
	if not player then
		return false
	end
	accountService.transaction(function(tx)
		tx(player, function()
			accountService.mutateData(function(acc)
				local new = table.clone(acc)
				new.extraSlotsUnlocked = true
				return new
			end)
		end)
	end)
	return true
end

function BitKaisenSaveSystem.HasExtraSaveSlotsUnlocked(player)
	if not player then
		return false
	end
	local account = getAccountData(player)
	if not account then
		return false
	end
	return account.extraSlotsUnlocked == true
end

-- Multiplayer Fase 8: "God Mode (This World)" dev product -- unlocks God
-- Mode permanently for ONE specific Public world. Stored as a sibling
-- field on that world's own publicWorldSaves entry (not inside `stats`),
-- so it survives death/new-life within the SAME world without being tied
-- to any one character -- a different Public world needs its own separate
-- purchase, exactly like the design calls for.
function BitKaisenSaveSystem.UnlockGodModeForWorld(player, worldId)
	if not player or typeof(worldId) ~= "string" or worldId == "" then
		return false
	end
	accountService.transaction(function(tx)
		tx(player, function()
			accountService.mutateData(function(acc)
				local new = table.clone(acc)
				local newPublicSaves = table.clone(new.publicWorldSaves or {})
				local existingEntry = newPublicSaves[worldId]
				local newEntry = typeof(existingEntry) == "table" and table.clone(existingEntry) or {}
				newEntry.GodModeUnlocked = true
				newPublicSaves[worldId] = newEntry
				new.publicWorldSaves = newPublicSaves
				return new
			end)
		end)
	end)
	return true
end

function BitKaisenSaveSystem.HasGodModeUnlockedForWorld(player, worldId)
	if not player or typeof(worldId) ~= "string" or worldId == "" then
		return false
	end
	local account = getAccountData(player)
	if not account then
		return false
	end
	local entry = account.publicWorldSaves and account.publicWorldSaves[worldId]
	return typeof(entry) == "table" and entry.GodModeUnlocked == true
end

function BitKaisenSaveSystem.GrantGiftedGamePassByUserId(userId, passKey)
	userId = tonumber(userId)
	passKey = tostring(passKey or "")
	if not userId or userId <= 0 or passKey == "" then
		return false
	end
	local player = Players:GetPlayerByUserId(userId)
	if not player then
		return false
	end
	accountService.transaction(function(tx)
		tx(player, function()
			accountService.mutateData(function(acc)
				local new = table.clone(acc)
				local newPasses = table.clone(new.giftedPasses)
				newPasses[passKey] = true
				new.giftedPasses = newPasses
				return new
			end)
		end)
	end)
	return true
end

function BitKaisenSaveSystem.HasGiftedGamePass(player, passKey)
	if not player then
		return false
	end
	passKey = tostring(passKey or "")
	if passKey == "" then
		return false
	end
	local account = getAccountData(player)
	if not account then
		return false
	end
	return account.giftedPasses[passKey] == true
end

function BitKaisenSaveSystem.GetGiftedGamePasses(player)
	if not player then
		return {}
	end
	local account = getAccountData(player)
	if not account then
		return {}
	end
	local copy = {}
	for key, value in account.giftedPasses do
		if value == true then
			copy[tostring(key)] = true
		end
	end
	return copy
end

function BitKaisenSaveSystem.SaveAllPlayers(playerLives)
	for _, player in Players:GetPlayers() do
		local stats = playerLives[player.UserId]
		if stats then
			BitKaisenSaveSystem.Save(player, stats)
		end
	end
end

return BitKaisenSaveSystem
