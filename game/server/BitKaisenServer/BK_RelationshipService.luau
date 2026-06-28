-- ModuleScript: BK_RelationshipService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose:
--   Phase 5 GameManager split.
--   Owns relationship payloads and relationship action handling that used to live directly inside GameManager.
--   Keep relationship UI behavior/server protocol unchanged.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BitKaisenRelationships = require(ReplicatedStorage:WaitForChild("BitKaisenRelationships"))
local BitKaisenTraits = require(ReplicatedStorage:WaitForChild("BitKaisenTraits"))
local BK_WorldHistoryService = require(script.Parent:WaitForChild("BK_WorldHistoryService"))

local BK_RelationshipService = {}
local context = {}

local RELATIONSHIP_PAYLOAD_CACHE_TTL = 20
local relationshipPayloadCache = {}

local function getRelationshipPayloadSignature(stats)
	local relationships = typeof(stats and stats.Relationships) == "table" and stats.Relationships or {}
	local history = typeof(stats and stats.RelationshipHistory) == "table" and stats.RelationshipHistory or {}
	local notables = typeof(stats and stats.NotableSorcerers) == "table" and stats.NotableSorcerers or {}
	local rivals = typeof(stats and stats.Rivals) == "table" and stats.Rivals or {}
	local clanWar = typeof(stats and stats.ClanWarState) == "table" and stats.ClanWarState or {}
	local clanWarHistory = typeof(stats and stats.ClanWarHistory) == "table" and stats.ClanWarHistory or {}
	return table.concat({
		tostring(stats and stats.Alive ~= false),
		tostring(stats and stats.Age or 0),
		tostring(stats and stats.CurrentMonth or 1),
		tostring(stats and stats.MonthsIntoAge or 0),
		tostring(#relationships),
		tostring(#history),
		tostring(#notables),
		tostring(#rivals),
		tostring(clanWar.Active),
		tostring(clanWar.RivalClanName),
		tostring(clanWar.Tension),
		tostring(clanWar.BattlesWon),
		tostring(clanWar.BattlesLost),
		tostring(#clanWarHistory),
		tostring(stats and stats.ClanWarWins or 0),
		tostring(stats and stats.ClanWarLosses or 0),
		tostring(stats and stats.RelationshipVersion or 0),
		tostring(stats and stats.NotableVersion or 0),
	}, "|")
end

local function invalidateRelationshipPayloadCache(player)
	if player then
		relationshipPayloadCache[player.UserId] = nil
	end
end

local function getStats(player)
	if context.GetStats then
		return context.GetStats(player)
	end
	return nil
end

local function ensureExtraStats(stats)
	if context.EnsureExtraStats then
		return context.EnsureExtraStats(stats)
	end
end

local function fireLifeUpdate(player, stats, message, forceResetLog)
	if context.FireLifeUpdate then
		return context.FireLifeUpdate(player, stats, message, forceResetLog)
	end
end

local function fireMajorPopup(player, title, body, highlight, footer)
	if context.FireMajorPopup then
		return context.FireMajorPopup(player, title, body, highlight, footer)
	end
end

local function saveStats(player, reason)
	if context.SaveStats then
		return context.SaveStats(player, reason)
	end
end

local function adjustWorldReputation(stats, fameDelta, fearDelta, pathDelta)
	if context.AdjustWorldReputation then
		return context.AdjustWorldReputation(stats, fameDelta, fearDelta, pathDelta)
	end
	return ""
end

local function hasPendingMission(player)
	local pending = context.PendingMissions
	return player and typeof(pending) == "table" and pending[player.UserId] ~= nil
end

local function pickRandom(list)
	if context.PickRandom then
		return context.PickRandom(list)
	end
	return list[math.random(1, #list)]
end

local function captureTraitBuffSnapshot(stats, relationship)
	if context.CaptureTraitBuffSnapshot then
		return context.CaptureTraitBuffSnapshot(stats, relationship)
	end

	return {
		CursedEnergy = tonumber(stats and stats.CursedEnergy) or 0,
		TechniqueMastery = tonumber(stats and stats.TechniqueMastery) or 0,
		Smarts = tonumber(stats and stats.Smarts) or 0,
		Money = tonumber(stats and stats.Money) or 0,
		Reputation = tonumber(stats and stats.Reputation) or 0,
		Health = tonumber(stats and stats.Health) or 0,
		Happiness = tonumber(stats and stats.Happiness) or 0,
		Relationship = relationship and {
			Bond = tonumber(relationship.Bond) or 0,
			Trust = tonumber(relationship.Trust) or 0,
			Respect = tonumber(relationship.Respect) or 0,
			Romance = tonumber(relationship.Romance) or 0,
			Fear = tonumber(relationship.Fear) or 0,
			Role = tostring(relationship.Role or "")
		} or nil
	}
end

local function applyTraitBuffsFromSnapshot(stats, before, actionContext, relationship)
	if context.ApplyTraitBuffsFromSnapshot then
		return context.ApplyTraitBuffsFromSnapshot(stats, before, actionContext, relationship)
	end
	return ""
end

local function awardUnregisteredProgress(player, stats, amount, reason, logMessage)
	if context.AwardUnregisteredProgress then
		return context.AwardUnregisteredProgress(player, stats, amount, reason, logMessage)
	end
	return logMessage or ""
end

local function checkPromotionAndPopup(player, stats, logMessage)
	if context.CheckPromotionAndPopup then
		return context.CheckPromotionAndPopup(player, stats, logMessage)
	end
	return logMessage or ""
end

local function syncFamilyStatus(stats)
	if context.SyncFamilyStatus then
		return context.SyncFamilyStatus(stats)
	end
end

local function calculatePlayerPower(stats)
	if context.CalculatePlayerPower then
		return context.CalculatePlayerPower(stats)
	end
	return (tonumber(stats and stats.CursedEnergy) or 0) + ((tonumber(stats and stats.TechniqueMastery) or 0) * 3)
end

local function ownsAssetById(stats, assetId)
	if context.OwnsAssetById then
		return context.OwnsAssetById(stats, assetId)
	end
	return false, nil
end

local function getClanWarAffiliationEntries(stats)
	ensureExtraStats(stats)
	local entries = {}
	local war = typeof(stats.ClanWarState) == "table" and stats.ClanWarState or {}
	if war.Active == true then
		table.insert(entries, {
			Id = "clan_war_active",
			Name = tostring(war.RivalClanName or "Rival Clan") .. " Clan War",
			Role = "Rival",
			Status = tostring(war.Phase or "Active War"),
			Relationship = "Active Clan War",
			Age = tostring(war.StartYear or "?"),
			Grade = "Tension " .. tostring(math.clamp(tonumber(war.Tension) or 0, 0, 100)) .. "%",
			Progressing = true,
			ReadOnly = true,
			PublicNote = "Battles " .. tostring(war.BattlesWon or 0) .. "-" .. tostring(war.BattlesLost or 0) .. " against the " .. tostring(war.RivalClanName or "rival") .. " Clan.",
		})
	end

	local history = typeof(stats.ClanWarHistory) == "table" and stats.ClanWarHistory or {}
	for index = #history, math.max(1, #history - 2), -1 do
		local entry = history[index]
		if entry then
			table.insert(entries, {
				Id = "clan_war_history_" .. tostring(index),
				Name = "Clan War Record",
				Role = "Rival",
				Status = tostring(entry.Result or "History"),
				Relationship = "World History",
				Age = tostring(entry.Year or "?"),
				Grade = "Record",
				Progressing = false,
				ReadOnly = true,
				PublicNote = tostring(entry.Text or "Clan war event."),
			})
		end
	end

	return entries
end

local function getRelationshipById(stats, relationshipId, includeDead)
	ensureExtraStats(stats)

	for _, relationship in ipairs(stats.Relationships or {}) do
		if relationship.Id == relationshipId and (includeDead or relationship.Alive ~= false) then
			return relationship
		end
	end

	return nil
end

local function hasBrainTransplant(stats)
	local technique = tostring(stats and stats.CursedTechnique or "None")
	local innate = tostring(stats and stats.InnateTechnique or "None")
	return technique == "Brain Transplant" or innate == "Brain Transplant"
end

local function getFirstNameFromFullName(fullName)
	local firstName = tostring(fullName or ""):match("^%s*(%S+)")
	return firstName and firstName ~= "" and firstName or "Unknown"
end

local MURDER_BLOCKED_RELATIONSHIP_ROLES = {
	Child = true,
	Ward = true,
	Mother = true,
	Father = true,
	Caretaker = true,
	Sibling = true,
	Teacher = true,
	Student = true,
}

local function canMurderRelationship(relationship)
	local role = tostring(relationship and relationship.Role or "")
	return relationship and relationship.Alive ~= false and not MURDER_BLOCKED_RELATIONSHIP_ROLES[role]
end

local function markRelationshipMurdered(relationship, killerName)
	relationship.Alive = false
	relationship.Status = "Deceased"
	relationship.DeathCause = "Murdered"
	relationship.DeathText = tostring(relationship.Name or "Someone") .. " was murdered by " .. tostring(killerName or "someone they knew") .. "."
	relationship.DeathAge = relationship.Age
	relationship.Romance = 0
end

local function removeRelationshipById(stats, relationshipId, reason)
	ensureExtraStats(stats)
	stats.RelationshipHistory = stats.RelationshipHistory or {}

	for index = #(stats.Relationships or {}), 1, -1 do
		local relationship = stats.Relationships[index]
		if relationship and relationship.Id == relationshipId then
			table.insert(stats.RelationshipHistory, {
				Id = relationship.Id,
				Name = relationship.Name,
				Role = relationship.Role,
				RemovedAtAge = stats.Age,
				Reason = reason or "Removed"
			})
			table.remove(stats.Relationships, index)
			return relationship
		end
	end

	return nil
end

local function canRemoveRelationship(relationship)
	local role = tostring(relationship and relationship.Role or "")
	local protectedRoles = {
		Mother = true,
		Father = true,
		Caretaker = true,
		Child = true,
		Spouse = true,
		Teacher = true,
		Student = true,
		Ward = true,
	}

	return protectedRoles[role] ~= true
end

local function getAdviceTopic(stats, relationship)
	local topics = {
		"cursed energy control",
		"how to stay calm around curses",
		"the strange things you keep sensing",
		"how to survive in the jujutsu world",
		"your future as a sorcerer"
	}

	if stats.CursedTechnique and stats.CursedTechnique ~= "None" then
		table.insert(topics, "your cursed technique")
		table.insert(topics, tostring(stats.CursedTechnique))
	end

	if relationship.Role == "Teacher" then
		table.insert(topics, "promotion reviews")
		table.insert(topics, "mission discipline")
	end

	if relationship.Role == "Mother" or relationship.Role == "Father" or relationship.Role == "Caretaker" then
		table.insert(topics, "your family history")
	end

	return pickRandom(topics)
end


local FREE_RELATIONSHIP_ACTIONS = {
	divorce = true,
	remove_relationship = true,
	forget_relationship = true,
	disown_child = true,
}

local FAMILY_RELATIONSHIP_ROLES = {
	Mother = true,
	Father = true,
	Caretaker = true,
	Sibling = true,
	Child = true,
}

local ROMANCE_ALLOWED_RELATIONSHIP_ROLES = {
	Friend = true,
	["Best Friend"] = true,
	Classmate = true,
	["Mission Partner"] = true,
}

local function appendLine(baseText, extraText)
	if not extraText or extraText == "" then
		return baseText or ""
	end

	if baseText and baseText ~= "" then
		return baseText .. "\n" .. extraText
	end

	return extraText
end

local function isFamilyRelationshipRole(role)
	return FAMILY_RELATIONSHIP_ROLES[tostring(role or "")] == true
end

local function hasRomanceSafeAges(stats, relationship)
	local playerAge = tonumber(stats and stats.Age) or 0
	local targetAge = tonumber(relationship and relationship.Age)
	if playerAge < 13 then
		return false
	end
	if targetAge and targetAge < 13 then
		return false
	end
	if targetAge and ((playerAge >= 18 and targetAge < 18) or (playerAge < 18 and targetAge >= 18)) then
		return false
	end
	return true
end

local function canGainRomanceFromGift(stats, relationship)
	if not hasRomanceSafeAges(stats, relationship) then
		return false
	end

	local role = tostring(relationship.Role or "")

	if role == "Partner" or role == "Spouse" then
		return true
	end

	if ROMANCE_ALLOWED_RELATIONSHIP_ROLES[role] and (relationship.Romance or 0) > 0 then
		return true
	end

	return false
end

local function applyRelationshipMilestones(player, stats, relationship)
	local role = tostring(relationship.Role or "")
	local message = ""

	if relationship.Alive == false then
		return message
	end

	if role == "Classmate" and (relationship.Bond or 0) >= 60 and (relationship.Trust or 0) >= 45 then
		relationship.Role = "Friend"
		relationship.Status = "Friend"
		message = appendLine(message, relationship.Name .. " became more than just a classmate. They are now your friend.")

		fireMajorPopup(
			player,
			"FRIENDSHIP FORMED",
			relationship.Name .. " started trusting you outside of school life.",
			relationship.Name,
			"They are now listed as a friend."
		)
	elseif role == "Friend" and (relationship.Bond or 0) >= 80 and (relationship.Trust or 0) >= 65 then
		relationship.Role = "Best Friend"
		relationship.Status = "Best Friend"
		message = appendLine(message, relationship.Name .. " became one of the closest people in your life.")

		fireMajorPopup(
			player,
			"BEST FRIEND",
			"Your connection with " .. relationship.Name .. " reached a new level.",
			relationship.Name,
			"They are now your best friend."
		)
	elseif role == "Rival" and (relationship.Respect or 0) >= 90 and (relationship.Trust or 0) >= 45 then
		relationship.Role = "Mission Partner"
		relationship.Status = "Trusted Rival"
		message = appendLine(message, relationship.Name .. " stopped treating you like an enemy and started treating you like someone worth fighting beside.")

		fireMajorPopup(
			player,
			"RIVALRY EVOLVED",
			relationship.Name .. " finally acknowledged your growth.",
			"Mission Partner",
			"They can now stand beside you during dangerous work."
		)
	end

	return message
end

local function sanitizeChildName(rawName)
	local text = tostring(rawName or "")
	text = text:gsub("<[^>]->", "")
	text = text:gsub("[^%a%s%-']", "")
	text = text:gsub("^%s+", "")
	text = text:gsub("%s+$", "")
	if #text > 16 then
		text = string.sub(text, 1, 16)
	end
	if text == "" then
		return nil
	end
	return string.upper(string.sub(text, 1, 1)) .. string.lower(string.sub(text, 2))
end

local function processRelationshipAction(player, relationshipId, actionId, data)
	local stats = getStats(player)

	if not stats or not stats.Alive then
		return
	end

	ensureExtraStats(stats)
	data = typeof(data) == "table" and data or {}

	if typeof(relationshipId) ~= "string" or typeof(actionId) ~= "string" then
		return
	end

	local deadBodyAction = actionId == "brain_transplant"
	local cleanupAction = actionId == "remove_relationship" or actionId == "forget_relationship" or actionId == "disown_child" or deadBodyAction
	local relationship = getRelationshipById(stats, relationshipId, cleanupAction)

	if not relationship and tostring(actionId) ~= "forget_relationship" then
		for _, npc in ipairs(stats.NotableSorcerers or {}) do
			if typeof(npc) == "table" and tostring(npc.Id) == tostring(relationshipId) then
				npc.Id = tostring(npc.Id)
				npc.Name = tostring(npc.Name or "Notable Sorcerer")
				npc.Role = "Notable Sorcerer"
				npc.Status = tostring(npc.Status or "Tracked")
				npc.Age = tonumber(npc.Age) or 0
				npc.Grade = tostring(npc.Grade or "Unknown")
				npc.CursedEnergy = tonumber(npc.CursedEnergy) or 0
				npc.TechniqueMastery = tonumber(npc.TechniqueMastery) or 0
				npc.Bond = tonumber(npc.Bond) or 8
				npc.Trust = tonumber(npc.Trust) or 4
				npc.Respect = math.clamp(tonumber(npc.Respect) or tonumber(npc.Progress) or 10, 0, 100)
				npc.Fear = tonumber(npc.Fear) or 0
				npc.Alive = tostring(npc.Status or "Tracked") ~= "Dead"
				npc.Background = tostring(npc.Background or npc.PublicNote or "A notable figure from your era.")
				npc.NotableSourceId = npc.Id
				relationship = npc
				stats.NotableVersion = (tonumber(stats.NotableVersion) or 0) + 1
				break
			end
		end
	end

	if not relationship then
		fireLifeUpdate(player, stats, cleanupAction and "That relationship is already gone." or "That relationship could not be found.")
		return
	end

	if actionId == "forget_relationship" then
		if relationship.Alive ~= false then
			fireLifeUpdate(player, stats, "You can only forget deceased relationship memories.")
			return
		end

		local oldName = tostring(relationship.Name or "that memory")
		removeRelationshipById(stats, relationshipId, "Forgot deceased relationship")
		fireLifeUpdate(player, stats, "You removed " .. oldName .. " from your relationship memories.")
		saveStats(player)
		return
	elseif actionId == "disown_child" then
		if relationship.Role ~= "Child" then
			fireLifeUpdate(player, stats, "You can only disown a child with this action.")
			return
		end

		local oldName = tostring(relationship.Name or "your child")
		removeRelationshipById(stats, relationshipId, "Disowned child")
		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - 12, 0, 100)
		fireLifeUpdate(player, stats, "You disowned " .. oldName .. ". They are no longer listed as part of your active relationships.")
		saveStats(player)
		return
	elseif actionId == "remove_relationship" then
		if relationship.Alive == false then
			fireLifeUpdate(player, stats, "Use Forget to remove deceased relationship memories.")
			return
		end
		if not canRemoveRelationship(relationship) then
			fireLifeUpdate(player, stats, "That relationship is too important to remove directly.")
			return
		end

		local oldName = tostring(relationship.Name or "that relationship")
		removeRelationshipById(stats, relationshipId, "Removed active relationship")
		fireLifeUpdate(player, stats, "You removed " .. oldName .. " from your active relationships.")
		saveStats(player)
		return
	end

	local freeRelationshipAction = FREE_RELATIONSHIP_ACTIONS[actionId] == true
	stats.RelationshipActionsThisAge = stats.RelationshipActionsThisAge or 0

	if stats.RelationshipActionsThisAge >= 3 and not freeRelationshipAction then
		fireLifeUpdate(player, stats, "You already used all 3 relationship actions this year. Age up first.")
		return
	end

	local logMessage = ""
	local relationshipActionCostsTurn = not freeRelationshipAction
	local traitBefore = captureTraitBuffSnapshot(stats, relationship)

	if actionId == "brain_transplant" then
		if not hasBrainTransplant(stats) then
			fireLifeUpdate(player, stats, "Only Brain Transplant users can perform that action.")
			return
		end
		if relationship.Alive ~= false then
			fireLifeUpdate(player, stats, "Brain Transplant requires a deceased host body.")
			return
		end

		local ceCost = 80
		if (tonumber(stats.CursedEnergy) or 0) < ceCost then
			fireLifeUpdate(player, stats, "You need at least " .. tostring(ceCost) .. " cursed energy to force a Brain Transplant.")
			return
		end

		local oldName = tostring(stats.Name or stats.FullName or "your old body")
		local hostName = tostring(relationship.Name or "the dead host")
		local hostAge = math.max(16, tonumber(relationship.Age) or tonumber(stats.Age) or 16)

		stats.PreviousBodyName = oldName
		stats.BrainTransplants = (tonumber(stats.BrainTransplants) or 0) + 1
		stats.BrainTransplantHostHistory = typeof(stats.BrainTransplantHostHistory) == "table" and stats.BrainTransplantHostHistory or {}
		table.insert(stats.BrainTransplantHostHistory, {
			Name = hostName,
			Role = relationship.Role,
			Age = relationship.Age,
			TransferredAtAge = stats.Age,
		})

		local preservedYear = (tonumber(stats.BirthYear) or 0) + (tonumber(stats.Age) or 0)
		print("[DEBUG][BrainTransplant] Year before=" .. tostring(preservedYear) .. " hostAge=" .. tostring(hostAge) .. " newBirthYear=" .. tostring(preservedYear - hostAge))
		stats.Name = hostName
		stats.FullName = hostName
		stats.FirstName = getFirstNameFromFullName(hostName)
		stats.Gender = relationship.Gender or stats.Gender
		stats.Age = hostAge
		stats.BirthYear = preservedYear - hostAge
		stats.CurrentMonth = 1
		stats.MonthsIntoAge = 0
		stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) - ceCost)
		stats.Health = math.clamp(math.max(70, tonumber(stats.Health) or 70), 1, 100)
		stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + 3, 0, 100)
		stats.BrainTransplantOriginalTechnique = stats.BrainTransplantOriginalTechnique or "Brain Transplant"

		removeRelationshipById(stats, relationshipId, "Used as Brain Transplant host")
		logMessage = "You forced Brain Transplant into " .. hostName .. ". Your old body is gone, but your will kept moving."

		fireMajorPopup(
			player,
			"BRAIN TRANSPLANT",
			"A forbidden technique crossed the line between death and identity.",
			hostName,
			"You now live through this host body."
		)

	elseif actionId == "talk" then
		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(1, 4),
			Trust = math.random(1, 3)
		})

		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(1, 3), 0, 100)

		local talkLines = {
			"You talked with " .. relationship.Name .. " about the strange direction your life has been taking.",
			relationship.Name .. " listened while you spoke about the pressure building around you.",
			"You had a quiet conversation with " .. relationship.Name .. " about curses, family, and the future.",
			"You and " .. relationship.Name .. " talked for a while. It helped more than you expected."
		}

		logMessage = pickRandom(talkLines)

	elseif actionId == "spend_time" then
		local romanceGain = 0

		if (relationship.Role == "Partner" or relationship.Role == "Spouse") and hasRomanceSafeAges(stats, relationship) then
			romanceGain = math.random(2, 5)
		end

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(4, 9),
			Trust = math.random(2, 5),
			Romance = romanceGain
		})

		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(4, 10), 0, 100)

		local spendLines = {
			"You spent the day with " .. relationship.Name .. ", keeping your mind away from curses for once.",
			relationship.Name .. " stayed with you for most of the day, and things felt normal for a while.",
			"You spent time with " .. relationship.Name .. ". The bond between you felt a little stronger afterward.",
			"You and " .. relationship.Name .. " passed the time together, talking about nothing and everything."
		}

		logMessage = pickRandom(spendLines)

	elseif actionId == "flirt" then
		local playerAge = tonumber(stats.Age) or 0
		local targetAge = tonumber(relationship.Age)
		if playerAge < 13 then
			fireLifeUpdate(player, stats, "You are too young for that.")
			return
		end
		if targetAge and targetAge < 13 then
			fireLifeUpdate(player, stats, relationship.Name .. " is too young for that.")
			return
		end
		if targetAge and ((playerAge >= 18 and targetAge < 18) or (playerAge < 18 and targetAge >= 18)) then
			fireLifeUpdate(player, stats, "That age gap is not appropriate.")
			return
		end

		local allowedRoles = {
			Friend = true,
			["Best Friend"] = true,
			Classmate = true,
			["Mission Partner"] = true
		}

		if not allowedRoles[relationship.Role] then
			fireLifeUpdate(player, stats, "That relationship cannot become romantic.")
			return
		end
		BitKaisenRelationships.AdjustRelationship(relationship, {
			Romance = math.random(10, 20),
			Bond = math.random(2, 5),
			Trust = math.random(0, 3)
		})

		local flirtLines = {
			"You flirted with " .. relationship.Name .. ". They seemed to notice.",
			"You tried flirting with " .. relationship.Name .. ", and the moment actually landed.",
			"You and " .. relationship.Name .. " shared a moment that felt different from usual.",
			"You flirted with " .. relationship.Name .. ". The tension between you shifted slightly."
		}

		logMessage = pickRandom(flirtLines)

	elseif actionId == "ask_out" then
		local playerAge = tonumber(stats.Age) or 0
		local targetAge = tonumber(relationship.Age)
		if playerAge < 13 then
			fireLifeUpdate(player, stats, "You are too young for that.")
			return
		end
		if targetAge and targetAge < 13 then
			fireLifeUpdate(player, stats, relationship.Name .. " is too young for that.")
			return
		end
		if targetAge and ((playerAge >= 18 and targetAge < 18) or (playerAge < 18 and targetAge >= 18)) then
			fireLifeUpdate(player, stats, "That age gap is not appropriate.")
			return
		end

		local allowedRoles = {
			Friend = true,
			["Best Friend"] = true,
			Classmate = true,
			["Mission Partner"] = true
		}

		if not allowedRoles[relationship.Role] then
			fireLifeUpdate(player, stats, "That relationship cannot become romantic.")
			return
		end

		if (relationship.Bond or 0) < 40 or (relationship.Trust or 0) < 25 or (relationship.Romance or 0) < 30 then
			fireLifeUpdate(player, stats, "You thought about asking " .. relationship.Name .. " out, but the relationship was not there yet.")
			return
		end
		local chance = 20
		chance += math.floor((relationship.Bond or 0) / 4)
		chance += math.floor((relationship.Trust or 0) / 5)
		chance += math.floor((relationship.Romance or 0) / 3)
		chance += math.floor((BitKaisenTraits.GetModifier(stats, "RomanceGainMult", 1) - 1) * 20)
		chance += math.floor((BitKaisenTraits.GetModifier(relationship, "RomanceGainMult", 1) - 1) * 20)

		chance = math.clamp(chance, 15, 92)

		if math.random(1, 100) <= chance then
			relationship.Role = "Partner"
			relationship.Status = "Dating"
			relationship.YearsDating = 0
			relationship.DatingStartedAge = math.max(0, tonumber(stats.Age) or 0)
			relationship.MetAtAge = relationship.MetAtAge or math.max(0, tonumber(stats.Age) or 0)
			relationship.AgeAtMet = relationship.AgeAtMet or relationship.Age

			BitKaisenRelationships.AdjustRelationship(relationship, {
				Bond = math.random(6, 12),
				Trust = math.random(4, 8),
				Romance = math.random(12, 24)
			})

			stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(8, 16), 0, 100)

			logMessage = "You asked " .. relationship.Name .. " out. They said yes, and the two of you started dating."

			fireMajorPopup(
				player,
				"RELATIONSHIP STARTED",
				"You asked someone important out.",
				relationship.Name,
				"They are now your partner."
			)
		else
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Bond = -math.random(2, 6),
				Trust = -math.random(1, 4),
				Romance = -math.random(4, 10)
			})

			stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(4, 10), 0, 100)

			logMessage = "You asked " .. relationship.Name .. " out, but they did not feel the same way."
		end

	elseif actionId == "train_together" then
		if (stats.Age or 0) < 8 then
			fireLifeUpdate(player, stats, "You are too young to train with someone.")
			return
		end
		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(2, 6),
			Respect = math.random(3, 8)
		})

		stats.CursedEnergy += math.random(4, 12)
		stats.Health = math.clamp((stats.Health or 100) - math.random(1, 5), 0, 100)

		local trainLines = {
			"You trained with " .. relationship.Name .. ", pushing your cursed energy until your body started to ache.",
			relationship.Name .. " helped you sharpen your cursed energy control during training.",
			"You and " .. relationship.Name .. " trained together. It was rough, but neither of you backed down.",
			"Training with " .. relationship.Name .. " forced you to control your cursed energy under pressure."
		}

		logMessage = pickRandom(trainLines)

	elseif actionId == "ask_advice" then
		local adviceBonus = math.random(2, 6)

		if relationship.Role == "Teacher" or relationship.Role == "Father" or relationship.Role == "Mother" or relationship.Role == "Caretaker" then
			adviceBonus += 3
		end

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Trust = math.random(1, 4),
			Respect = math.random(1, 4)
		})

		stats.Smarts = math.clamp((stats.Smarts or 0) + adviceBonus, 0, 100)

		local topic = getAdviceTopic(stats, relationship)

		local adviceLines = {
			"You asked " .. relationship.Name .. " for advice about " .. topic .. ".",
			relationship.Name .. " gave you advice about " .. topic .. ", and it stayed with you.",
			"You went to " .. relationship.Name .. " for guidance on " .. topic .. ".",
			relationship.Name .. " helped you understand more about " .. topic .. "."
		}

		logMessage = pickRandom(adviceLines)

	elseif actionId == "check_in" then
		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(1, 3),
			Trust = math.random(2, 5),
			Fear = -math.random(0, 2)
		})

		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(1, 4), 0, 100)

		local checkLines = {
			"You checked in on " .. relationship.Name .. " instead of only showing up when you needed something.",
			relationship.Name .. " seemed surprised that you asked how they were doing.",
			"You took a moment to check on " .. relationship.Name .. ". It made the connection feel less one-sided.",
			"You and " .. relationship.Name .. " had a short, honest check-in. Nothing dramatic, but it mattered."
		}

		logMessage = pickRandom(checkLines)

	elseif actionId == "deep_talk" then
		if (relationship.Bond or 0) < 20 and (relationship.Trust or 0) < 15 then
			fireLifeUpdate(player, stats, relationship.Name .. " was not ready for that kind of conversation yet.")
			return
		end
		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(4, 9),
			Trust = math.random(5, 11),
			Respect = math.random(1, 4),
			Fear = -math.random(0, 3)
		})

		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(2, 7), 0, 100)

		local deepLines = {
			"You had a real conversation with " .. relationship.Name .. " about fear, pressure, and the jujutsu world.",
			"You and " .. relationship.Name .. " talked past the usual small talk. The trust between you shifted.",
			relationship.Name .. " opened up more than usual, and you actually listened.",
			"You spoke with " .. relationship.Name .. " about the kind of person you are becoming."
		}

		logMessage = pickRandom(deepLines)

	elseif actionId == "give_gift" then
		local giftCost = 1000

		if relationship.Role == "Partner" or relationship.Role == "Spouse" then
			giftCost = 2500
		elseif relationship.Role == "Child" then
			giftCost = 750
		elseif relationship.Role == "Teacher" then
			giftCost = 1500
		end

		if (stats.Money or 0) < giftCost then
			fireLifeUpdate(player, stats, "You need $" .. tostring(giftCost) .. " to buy a meaningful gift for " .. relationship.Name .. ".")
			return
		end

		stats.Money -= giftCost

		local romanceGain = 0
		if canGainRomanceFromGift(stats, relationship) then
			romanceGain = math.random(2, 6)
		end

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(4, 9),
			Trust = math.random(1, 4),
			Romance = romanceGain
		})

		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(1, 5), 0, 100)

		local giftLines = {
			"You bought a gift for " .. relationship.Name .. ". It was not flashy, but it showed you were paying attention.",
			relationship.Name .. " accepted your gift and seemed to understand the thought behind it.",
			"You spent $" .. tostring(giftCost) .. " on something for " .. relationship.Name .. ". The gesture landed well.",
			"You gave " .. relationship.Name .. " something useful instead of just saying you cared."
		}

		logMessage = pickRandom(giftLines)

	elseif actionId == "study_together" then
		if (stats.Age or 0) < 8 then
			fireLifeUpdate(player, stats, "You are too young to study seriously with someone.")
			return
		end
		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(2, 5),
			Trust = math.random(2, 5),
			Respect = math.random(2, 6)
		})

		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(2, 6), 0, 100)

		if stats.CursedTechnique and stats.CursedTechnique ~= "None" then
			stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + math.random(0, 2), 0, 100)
		end

		logMessage = "You studied with " .. relationship.Name .. ", comparing notes on curses, missions, and bad habits you needed to fix."

	elseif actionId == "spar" then
		if (stats.Age or 0) < 10 then
			fireLifeUpdate(player, stats, "You are too young to spar seriously.")
			return
		end

		if relationship.Role == "Mother" or relationship.Role == "Father" or relationship.Role == "Caretaker" or relationship.Role == "Child" then
			fireLifeUpdate(player, stats, "That is not the kind of relationship you should spar with.")
			return
		end
		local cleanSession = math.random(1, 100) <= math.clamp((stats.Smarts or 0) + (relationship.Respect or 0), 15, 90)

		stats.CursedEnergy += math.random(4, 11)
		stats.Health = math.clamp((stats.Health or 100) - math.random(1, cleanSession and 4 or 9), 0, 100)

		if stats.CursedTechnique and stats.CursedTechnique ~= "None" then
			stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + math.random(1, 3), 0, 100)
		end

		if relationship.CursedEnergy then
			relationship.CursedEnergy = (relationship.CursedEnergy or 0) + math.random(1, 5)
		end

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(1, 5),
			Respect = math.random(4, 9),
			Fear = cleanSession and 0 or math.random(1, 3)
		})

		if cleanSession then
			logMessage = "You sparred with " .. relationship.Name .. ". The session was rough, but controlled enough to build real respect."
		else
			logMessage = "You sparred with " .. relationship.Name .. ", but the session got messy and left both of you tense."
		end

	elseif actionId == "apologize" then
		local sincereChance = 35 + math.floor((stats.Smarts or 0) / 3) + math.floor((relationship.Bond or 0) / 6)
		sincereChance = math.clamp(sincereChance, 20, 85)

		if math.random(1, 100) <= sincereChance then
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Bond = math.random(1, 4),
				Trust = math.random(4, 9),
				Respect = math.random(0, 3),
				Fear = -math.random(0, 2)
			})

			logMessage = "You apologized to " .. relationship.Name .. " without trying to win the conversation. The trust between you recovered a little."
		else
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Trust = -math.random(1, 4),
				Respect = -math.random(0, 2)
			})

			logMessage = "You tried apologizing to " .. relationship.Name .. ", but it sounded forced and made things awkward."
		end

	elseif actionId == "family_time" then
		if not isFamilyRelationshipRole(relationship.Role) then
			fireLifeUpdate(player, stats, "That action is only for family relationships.")
			return
		end
		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(5, 11),
			Trust = math.random(3, 8),
			Fear = -math.random(0, 3)
		})

		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(4, 10), 0, 100)

		logMessage = "You spent real family time with " .. relationship.Name .. ", away from missions, grades, and cursed energy."

	elseif actionId == "mentor_session" then
		if relationship.Role ~= "Teacher" then
			fireLifeUpdate(player, stats, "Only teachers can run a mentor session.")
			return
		end

		if not stats.InJujutsuHigh then
			fireLifeUpdate(player, stats, "You need to be enrolled in Jujutsu High first.")
			return
		end
		stats.Smarts = math.clamp((stats.Smarts or 0) + math.random(2, 5), 0, 100)
		stats.CursedEnergy += math.random(5, 12)

		if stats.CursedTechnique and stats.CursedTechnique ~= "None" then
			stats.TechniqueMastery = math.clamp((stats.TechniqueMastery or 0) + math.random(2, 5), 0, 100)
		end

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Trust = math.random(2, 5),
			Respect = math.random(4, 9)
		})

		if math.random(1, 100) <= 12 + math.floor((relationship.Respect or 0) / 10) then
			stats.TeacherRecommendations += 1
			logMessage = relationship.Name .. " ran a mentor session with you and later added a quiet recommendation to your record."
		else
			logMessage = relationship.Name .. " ran a mentor session with you, correcting the flaws in your cursed energy control."
		end

	elseif actionId == "pair_mission" then
		if (stats.Age or 0) < 16 then
			fireLifeUpdate(player, stats, "You need to be at least 16 to take a paired mission.")
			return
		end

		local allowedPairRoles = {
			Friend = true,
			["Best Friend"] = true,
			Classmate = true,
			["Mission Partner"] = true,
			Rival = true,
			["Notable Sorcerer"] = true,
		}

		if not allowedPairRoles[relationship.Role] then
			fireLifeUpdate(player, stats, "That person is not suited for a paired mission.")
			return
		end
		local missionPower = calculatePlayerPower(stats) + ((relationship.CursedEnergy or 0) * 0.4) + ((relationship.Respect or 0) * 0.5)
		local difficulty = math.random(70, 160)

		if missionPower >= difficulty then
			stats.Money += math.random(1200, 3500)
			stats.Reputation += math.random(3, 9)
			stats.MissionsCompleted += 1

			BitKaisenRelationships.AdjustRelationship(relationship, {
				Bond = math.random(3, 8),
				Trust = math.random(3, 8),
				Respect = math.random(4, 10),
				Fear = -math.random(0, 2)
			})

			logMessage = "You took a paired mission with " .. relationship.Name .. ". The job went clean, and the two of you came back with more respect for each other."
		else
			stats.Health = math.clamp((stats.Health or 100) - math.random(8, 18), 0, 100)
			stats.Reputation = (stats.Reputation or 0 - math.random(0, 3))
			stats.MissionsFailed += 1

			BitKaisenRelationships.AdjustRelationship(relationship, {
				Bond = math.random(0, 3),
				Trust = -math.random(1, 5),
				Respect = math.random(1, 4),
				Fear = math.random(1, 5)
			})

			logMessage = "You took a paired mission with " .. relationship.Name .. ", but the job turned ugly and exposed problems in your teamwork."
		end

	elseif actionId == "ask_recommendation" then
		if relationship.Role ~= "Teacher" then
			fireLifeUpdate(player, stats, "Only teachers can submit promotion recommendations.")
			return
		end

		if not stats.InJujutsuHigh then
			fireLifeUpdate(player, stats, "You need to be enrolled in Jujutsu High first.")
			return
		end
		local chance = 20
		chance += math.floor((relationship.Respect or 0) / 4)
		chance += math.floor((relationship.Trust or 0) / 6)

		if stats.Reputation >= 20 then
			chance += 10
		end

		if stats.ClanFounded then
			chance += 5
		end

		if math.random(1, 100) <= chance then
			stats.TeacherRecommendations += 1

			BitKaisenRelationships.AdjustRelationship(relationship, {
				Trust = math.random(1, 3),
				Respect = math.random(2, 5)
			})

			logMessage = relationship.Name .. " reviewed your recent progress and submitted a recommendation for your promotion review."

			fireMajorPopup(
				player,
				"TEACHER RECOMMENDATION",
				relationship.Name .. " reviewed your progress and submitted a recommendation.",
				"Recommendation Added",
				"Recommendations help you advance through semi-grades."
			)
		else
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Respect = math.random(1, 3),
				Trust = -math.random(1, 3)
			})

			logMessage = relationship.Name .. " refused to recommend you yet, saying your record still needed more proof."
		end

	elseif actionId == "compliment" then
		local romanceGain = 0

		if relationship.Role == "Partner" or relationship.Role == "Spouse" then
			romanceGain = math.random(3, 8)
		end

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(2, 5),
			Trust = math.random(1, 3),
			Romance = romanceGain
		})

		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(1, 4), 0, 100)

		local complimentLines = {
			"You complimented " .. relationship.Name .. " on how they handled themselves lately.",
			"You said something kind to " .. relationship.Name .. ", and they seemed to appreciate it.",
			"You gave " .. relationship.Name .. " a genuine compliment instead of brushing the moment off.",
			relationship.Name .. " looked caught off guard when you complimented them, but they smiled anyway."
		}

		logMessage = pickRandom(complimentLines)

	elseif actionId == "argue" then
		local wonArgument = math.random(1, 100) <= ((stats.Smarts or 0) + 20)

		if wonArgument then
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Bond = -math.random(2, 6),
				Respect = math.random(2, 6),
				Trust = -math.random(1, 4)
			})

			local winLines = {
				"You argued with " .. relationship.Name .. " about your choices, but they respected that you stood your ground.",
				"You and " .. relationship.Name .. " clashed over your path, but your point landed.",
				"Your argument with " .. relationship.Name .. " got heated, but they could not ignore what you said."
			}

			logMessage = pickRandom(winLines)
		else
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Bond = -math.random(4, 10),
				Trust = -math.random(2, 6),
				Respect = -math.random(1, 4)
			})

			stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(2, 6), 0, 100)

			local loseLines = {
				"You argued with " .. relationship.Name .. ", and the conversation ended badly.",
				"You and " .. relationship.Name .. " fought over something that clearly mattered to both of you.",
				"Your argument with " .. relationship.Name .. " left the relationship colder than before."
			}

			logMessage = pickRandom(loseLines)
		end

	elseif actionId == "propose" then
		if (stats.Age or 0) < 18 then
			fireLifeUpdate(player, stats, "You need to be at least 18 to propose.")
			return
		end

		if relationship.Role ~= "Partner" then
			fireLifeUpdate(player, stats, "You can only propose to your partner.")
			return
		end

		local ownsRing = ownsAssetById(stats, "wedding_ring")

		if not ownsRing then
			fireLifeUpdate(player, stats, "You need a <b>Wedding Ring</b> before you can propose.")
			return
		end

		BitKaisenRelationships.ReconcileRelationshipTimeline(stats, relationship)
		if (tonumber(relationship.Age) or 0) < 18 then
			fireLifeUpdate(player, stats, relationship.Name .. " needs to be an adult before marriage.")
			return
		end

		local marriageReqMult = BitKaisenTraits.GetModifier(stats, "MarriageReqMult", 1) * BitKaisenTraits.GetModifier(relationship, "MarriageReqMult", 1)
		local neededDatingYears = math.max(1, math.floor((3 * marriageReqMult) + 0.5))
		local neededBond = math.clamp(math.floor((85 * marriageReqMult) + 0.5), 55, 95)
		local neededTrust = math.clamp(math.floor((80 * marriageReqMult) + 0.5), 50, 95)
		local neededRomance = math.clamp(math.floor((80 * marriageReqMult) + 0.5), 50, 95)

		if (relationship.YearsDating or 0) < neededDatingYears then
			fireLifeUpdate(player, stats, "You thought about proposing to " .. relationship.Name .. ", but the relationship had not been serious long enough yet. Date for at least " .. tostring(neededDatingYears) .. " year" .. (neededDatingYears == 1 and "" or "s") .. " first.")
			return
		end

		if (relationship.Bond or 0) < neededBond or (relationship.Trust or 0) < neededTrust or (relationship.Romance or 0) < neededRomance then
			fireLifeUpdate(player, stats, "You thought about proposing to " .. relationship.Name .. ", but the relationship was not strong enough yet. Aim for " .. tostring(neededBond) .. " Bond, " .. tostring(neededTrust) .. " Trust, and " .. tostring(neededRomance) .. " Romance.")
			return
		end

		relationship.Role = "Spouse"
		relationship.Status = "Married"
		relationship.YearsMarried = 0
		relationship.MarriedAtAge = math.max(0, tonumber(stats.Age) or 0)
		relationship.Romance = 100
		relationship.Bond = 100
		relationship.Trust = 100

		stats.Happiness = math.clamp((stats.Happiness or 100) + 20, 0, 100)

		logMessage = "You proposed to " .. relationship.Name .. " with a wedding ring. After everything you survived together, they accepted."

		fireMajorPopup(
			player,
			"MARRIAGE",
			"Your relationship reached a new stage.",
			relationship.Name,
			"They are now your spouse."
		)

	elseif actionId == "start_family" then
		if (stats.Age or 0) < 18 then
			fireLifeUpdate(player, stats, "You need to be at least 18 to start a family.")
			return
		end

		if relationship.Role ~= "Spouse" then
			fireLifeUpdate(player, stats, "You need to be married before starting a family.")
			return
		end

		BitKaisenRelationships.ReconcileRelationshipTimeline(stats, relationship)
		if (tonumber(relationship.Age) or 0) < 18 then
			fireLifeUpdate(player, stats, relationship.Name .. " needs to be an adult before starting a family.")
			return
		end

		if (relationship.Bond or 0) < 70 or (relationship.Trust or 0) < 70 or (relationship.Romance or 0) < 70 then
			fireLifeUpdate(player, stats, "You and " .. relationship.Name .. " talked about starting a family, but the relationship needed more stability first. Aim for 70 Bond, 70 Trust, and 70 Romance.")
			return
		end

		local chance = 35
		chance += math.floor((relationship.Romance or 0) / 4)
		chance += math.floor((relationship.Bond or 0) / 7)
		chance += math.floor((stats.Happiness or 0) / 9)
		chance += math.floor((BitKaisenTraits.GetModifier(stats, "FamilyGainMult", 1) - 1) * 25)
		chance += math.floor((BitKaisenTraits.GetModifier(relationship, "FamilyGainMult", 1) - 1) * 25)
		chance = math.clamp(chance, 25, 95)

		if math.random(1, 100) <= chance then
			local child = BitKaisenRelationships.AddChild(stats, sanitizeChildName(data.ChildName), relationship.Name)

			BitKaisenRelationships.AdjustRelationship(relationship, {
				Bond = math.random(3, 8),
				Trust = math.random(2, 6),
				Romance = math.random(1, 4)
			})

			stats.Happiness = math.clamp((stats.Happiness or 100) + 18, 0, 100)

			logMessage = "You and " .. relationship.Name .. " decided to start a family. Later that year, you welcomed a child named " .. child.Name .. "."

			fireMajorPopup(
				player,
				"CHILD BORN",
				"Your family grew.",
				child.Name,
				"They have been added to your Relationships page."
			)
		else
			stats.Happiness = math.clamp((stats.Happiness or 100) - 3, 0, 100)
			logMessage = "You and " .. relationship.Name .. " talked about starting a family, but the timing did not feel right yet."
		end

	elseif actionId == "divorce" then
		if relationship.Role ~= "Spouse" then
			fireLifeUpdate(player, stats, "You can only divorce your current spouse.")
			return
		end

		if hasPendingMission(player) then
			fireLifeUpdate(player, stats, "You cannot divorce during an active mission/event. Finish the situation first.")
			return
		end

		local oldName = relationship.Name or "your spouse"
		local yearsMarried = tonumber(relationship.YearsMarried) or 0

		relationship.WasSpouse = true
		relationship.Divorced = true
		relationship.Role = "Ex-Spouse"
		relationship.Status = "Divorced"
		relationship.Romance = 0
		relationship.Trust = math.clamp((relationship.Trust or 0) - 45, 0, 100)
		relationship.Bond = math.clamp((relationship.Bond or 0) - 30, 0, 100)
		relationship.Respect = math.clamp((relationship.Respect or 0) - 15, 0, 100)
		relationship.YearsDating = relationship.YearsDating or 0
		relationship.YearsMarried = yearsMarried
		relationship.YearsDivorced = 0

		local custodyResult = BitKaisenRelationships.ApplyDivorceCustody(stats, relationship)

		stats.Happiness = math.clamp((stats.Happiness or 100) - 12, 0, 100)

		local custodySummary = ""
		if custodyResult and (custodyResult.Total or 0) > 0 then
			custodySummary = " Custody was decided for " .. tostring(custodyResult.Total) .. " child" .. ((custodyResult.Total == 1) and "" or "ren") .. ": " .. table.concat(custodyResult.Lines or {}, "; ") .. "."
		end

		logMessage = "You divorced " .. oldName .. ". The marriage ended, but any children remain part of your family legacy." .. custodySummary

		fireMajorPopup(
			player,
			"DIVORCE",
			(custodyResult and (custodyResult.Total or 0) > 0) and "The marriage ended and custody was arranged." or "The marriage ended.",
			oldName,
			(custodyResult and (custodyResult.Total or 0) > 0) and "Check your children's info cards for custody." or "They are now listed as your ex-spouse."
		)

	elseif actionId == "adopt_child" then
		if (stats.Age or 0) < 21 then
			fireLifeUpdate(player, stats, "You need to be at least 21 to adopt a child.")
			return
		end

		if relationship.Role ~= "Spouse" then
			fireLifeUpdate(player, stats, "You need to be married before adopting a child.")
			return
		end

		local adoptionCost = 10000

		if (stats.Money or 0) < adoptionCost then
			fireLifeUpdate(player, stats, "Adoption costs $" .. tostring(adoptionCost) .. ".")
			return
		end

		if (stats.Health or 0) < 40 or (stats.Happiness or 0) < 40 then
			fireLifeUpdate(player, stats, "You were not in a stable enough place to adopt yet.")
			return
		end

		stats.Money -= adoptionCost

		local child = BitKaisenRelationships.AddChild(stats, sanitizeChildName(data.ChildName), relationship.Name)

		stats.Happiness = math.clamp((stats.Happiness or 100) + 16, 0, 100)

		logMessage = "You and " .. relationship.Name .. " adopted a child named " .. child.Name .. " and brought them into your family."

		fireMajorPopup(
			player,
			"ADOPTION",
			"Your family grew through adoption.",
			child.Name,
			"They have been added to your Relationships page."
		)

	elseif actionId == "induct_child_dojo" then
		local role = tostring(relationship.Role or "")
		if role ~= "Child" and role ~= "Ward" then
			fireLifeUpdate(player, stats, "Only your children or wards can be brought into your dojo.")
			return
		end
		if relationship.Alive == false then
			fireLifeUpdate(player, stats, "You cannot induct someone who is no longer alive.")
			return
		end
		if (tonumber(relationship.Age) or 0) < 8 then
			fireLifeUpdate(player, stats, relationship.Name .. " is too young for dojo training.")
			return
		end
		if relationship.DojoStudent == true or relationship.IsClanStudent == true then
			fireLifeUpdate(player, stats, relationship.Name .. " is already part of your dojo path.")
			return
		end

		local current = context.CountDojoStudentsAndWards and context.CountDojoStudentsAndWards(stats) or 0
		local capacity = context.GetDojoStudentCapacity and context.GetDojoStudentCapacity(stats) or 3
		if current >= capacity then
			fireLifeUpdate(player, stats, "Your dojo is full. Upgrade or expand before bringing " .. relationship.Name .. " into training.")
			return
		end
		relationship.DojoStudent = true
		relationship.IsClanStudent = true
		relationship.FamilyCareer = "Dojo Heir"
		relationship.WorldPath = "Sorcerer Candidate"
		relationship.Occupation = "Dojo Trainee"
		relationship.DojoProgress = math.max(tonumber(relationship.DojoProgress) or 0, math.random(4, 10))
		relationship.DojoPotential = (relationship.DojoPotential and tostring(relationship.DojoPotential) ~= "") and tostring(relationship.DojoPotential) or "Family Heir"
		relationship.GrowthStyle = (relationship.GrowthStyle and tostring(relationship.GrowthStyle) ~= "") and tostring(relationship.GrowthStyle) or "Inherited Training"
		relationship.CursedEnergy = math.max(tonumber(relationship.CursedEnergy) or 0, math.random(25, 55))
		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(3, 7),
			Trust = math.random(4, 9),
			Respect = math.random(4, 9),
			Fear = -math.random(0, 2)
		})
		stats.ChildrenInductedIntoDojo = math.max(0, tonumber(stats.ChildrenInductedIntoDojo) or 0) + 1
		stats.ClanMembers = math.max(tonumber(stats.ClanMembers) or 0, current + 1)
		stats.DojoReputation = math.max(0, (tonumber(stats.DojoReputation) or 0) + math.random(2, 5))
		stats.ClanReputation = math.clamp((tonumber(stats.ClanReputation) or 0) + math.random(1, 4), 0, 100)
		stats.DojoLegacy = math.clamp((tonumber(stats.DojoLegacy) or 0) + math.random(1, 4), 0, 100)

		logMessage = "You brought " .. relationship.Name .. " into your dojo and clan training path. They are now counted as a dojo trainee while remaining part of your family."
		fireMajorPopup(player, "DOJO HEIR", relationship.Name .. " joined your dojo path.", "Family Trainee", "They now appear in dojo student systems and can grow through training.")

	elseif actionId == "discuss_custody" then
		if relationship.Role ~= "Ex-Spouse" then
			fireLifeUpdate(player, stats, "You can only discuss custody with an ex-spouse.")
			return
		end

		local result = BitKaisenRelationships.RebalanceCustody(stats, relationship)

		if result and result.Changed then
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Trust = math.random(2, 5),
				Respect = math.random(1, 4)
			})
			stats.Happiness = math.clamp((stats.Happiness or 100) + 2, 0, 100)
		else
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Trust = -math.random(1, 4),
				Respect = -math.random(0, 3)
			})
			stats.Happiness = math.clamp((stats.Happiness or 100) - 2, 0, 100)
		end

		logMessage = result and result.Message or "You tried to discuss custody, but nothing changed."

	elseif actionId == "custody_visit" then
		if relationship.Role ~= "Child" then
			fireLifeUpdate(player, stats, "You can only schedule custody visits with your child.")
			return
		end

		if (relationship.Age or 0) >= 18 or relationship.Custody == "Independent" then
			fireLifeUpdate(player, stats, relationship.Name .. " is an adult now and does not need custody visits.")
			return
		end

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(3, 7),
			Trust = math.random(2, 5),
			Respect = math.random(0, 3)
		})

		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(1, 4), 0, 100)

		local custody = tostring(relationship.Custody or "With You")
		if custody == "With Ex-Spouse" then
			logMessage = "You arranged a custody visit with " .. relationship.Name .. ". They mostly live with " .. tostring(relationship.CustodyParentName or relationship.OtherParentName or "your ex-spouse") .. ", but you stayed present."
		elseif custody == "Shared" then
			logMessage = "You spent your shared custody time with " .. relationship.Name .. "."
		else
			logMessage = "You spent extra time with " .. relationship.Name .. " and made sure the divorce did not make them feel abandoned."
		end

	elseif actionId == "teach_child" then
		if relationship.Role ~= "Child" then
			fireLifeUpdate(player, stats, "You can only teach your child with this action.")
			return
		end

		local teachWindowAge = math.max(0, tonumber(stats.Age) or 0)
		if tonumber(relationship.ChildTeachWindowAge) ~= teachWindowAge then
			relationship.ChildTeachWindowAge = teachWindowAge
			relationship.ChildTeachUsedThisAge = 0
		end
		local teachUsed = math.max(0, tonumber(relationship.ChildTeachUsedThisAge) or 0)
		if teachUsed >= 3 then
			fireLifeUpdate(player, stats, "You have already taught " .. tostring(relationship.Name or "your child") .. " 3 time(s) this age. Age up before teaching them more.")
			return
		end
		relationship.ChildTeachUsedThisAge = teachUsed + 1
		relationship.CursedEnergy = (relationship.CursedEnergy or 0) + math.random(1, 5)

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(3, 7),
			Trust = math.random(2, 6),
			Respect = math.random(1, 4)
		})

		logMessage = "You taught " .. relationship.Name .. " about curses, family history, and how dangerous the jujutsu world can be."

	elseif actionId == "protect_child" then
		if relationship.Role ~= "Child" then
			fireLifeUpdate(player, stats, "You can only protect your child with this action.")
			return
		end
		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(4, 8),
			Trust = math.random(4, 8),
			Fear = -math.random(1, 4)
		})

		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(2, 6), 0, 100)

		logMessage = "You spent time protecting " .. relationship.Name .. " from the darker parts of the cursed world."

	elseif actionId == "train_child" then
		if relationship.Role ~= "Child" then
			fireLifeUpdate(player, stats, "You can only train your child with this action.")
			return
		end

		if (relationship.Age or 0) < 8 then
			fireLifeUpdate(player, stats, relationship.Name .. " is too young to train cursed energy.")
			return
		end
		relationship.CursedEnergy = (relationship.CursedEnergy or 0) + math.random(4, 10)

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(2, 6),
			Respect = math.random(3, 8),
			Fear = math.random(0, 2)
		})

		logMessage = "You trained " .. relationship.Name .. " in cursed energy control, making sure they understood the danger before the power."

	elseif actionId == "recruit_dojo" then
		if relationship.Role ~= "Child" and relationship.Role ~= "Ward" then
			fireLifeUpdate(player, stats, "You can only recruit your children or wards into your Grand Dojo.")
			return
		end
		if relationship.Alive == false then
			fireLifeUpdate(player, stats, "You cannot recruit someone who has died.")
			return
		end
		if (tonumber(relationship.Age) or 0) < 12 then
			fireLifeUpdate(player, stats, tostring(relationship.Name or "They") .. " is too young for Grand Dojo recruitment.")
			return
		end
		if relationship.DojoStudent == true then
			fireLifeUpdate(player, stats, tostring(relationship.Name or "They") .. " is already training at your Grand Dojo.")
			return
		end
		if not stats.ClanFounded then
			fireLifeUpdate(player, stats, "You need to found a clan before recruiting family into your Grand Dojo.")
			return
		end
		local ownsDojo = context.OwnsAssetById and context.OwnsAssetById(stats, "grand_dojo")
		if not ownsDojo then
			fireLifeUpdate(player, stats, "You need to own a Grand Dojo before recruiting family into it.")
			return
		end
		local currentStudents = context.CountDojoStudentsAndWards and context.CountDojoStudentsAndWards(stats) or 0
		local capacity = context.GetDojoStudentCapacity and context.GetDojoStudentCapacity(stats) or 3
		if currentStudents >= capacity then
			fireLifeUpdate(player, stats, "Your Grand Dojo is at capacity. Upgrade it or increase clan reputation before taking in more students.")
			return
		end

		relationship.DojoStudent = true
		relationship.DojoJoinedYear = context.GetCurrentYear and context.GetCurrentYear(stats) or stats.Year or 0
		relationship.DojoPotential = relationship.DojoPotential or "Legacy"
		relationship.DojoProgress = math.max(tonumber(relationship.DojoProgress) or 0, 5)
		relationship.GrowthStyle = relationship.GrowthStyle or "Legacy Student"
		relationship.PreviousSchool = relationship.PreviousSchool or "Family Training"
		relationship.Background = tostring(relationship.Background or "")
		if relationship.Background == "" then
			relationship.Background = tostring(relationship.Name or "This child") .. " joined your Grand Dojo through your family legacy."
		end
		stats.ClanMembers = math.max(tonumber(stats.ClanMembers) or 0, currentStudents + 1)
		stats.ClanReputation = math.clamp((tonumber(stats.ClanReputation) or 0) + 2, 0, 999)
		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(2, 5),
			Trust = math.random(2, 5),
			Respect = math.random(3, 7),
		})
		logMessage = tostring(relationship.Name or "Your child") .. " joined your Grand Dojo and began training under your clan name."

	elseif actionId == "murder_relationship" then
		if not canMurderRelationship(relationship) then
			fireLifeUpdate(player, stats, "You cannot murder that relationship.")
			return
		end
		if (tonumber(stats.Age) or 0) < 16 then
			fireLifeUpdate(player, stats, "You are too young to carry out something that dangerous.")
			return
		end
		if hasPendingMission(player) then
			fireLifeUpdate(player, stats, "You cannot do that during an active mission/event. Finish the situation first.")
			return
		end
		local playerPower = calculatePlayerPower(stats)
		local targetPower = (tonumber(relationship.CursedEnergy) or 0) + math.floor((tonumber(relationship.TechniqueMastery) or 0) * 2.5)
		local successChance = 38 + math.floor(playerPower / 18) - math.floor(targetPower / 20) + math.floor((tonumber(stats.Smarts) or 0) / 12)
		if tostring(relationship.Role or "") == "Rival" then
			successChance -= 8
		end
		successChance = math.clamp(successChance, 18, 88)

		local caughtChance = 42 - math.floor((tonumber(stats.Smarts) or 0) / 8) - math.floor((tonumber(stats.TechniqueMastery) or 0) / 12)
		if relationship.Role == "Spouse" or relationship.Role == "Partner" or relationship.Role == "Ex-Spouse" then
			caughtChance += 14
		end
		caughtChance += math.floor((tonumber(relationship.Respect) or 0) / 12)
		caughtChance = math.clamp(caughtChance, 8, 75)

		local targetName = tostring(relationship.Name or "that person")
		if math.random(1, 100) <= successChance then
			local caught = math.random(1, 100) <= caughtChance
			markRelationshipMurdered(relationship, tostring(stats.Name or stats.FullName or "you"))

			stats.RelationshipMurders = (tonumber(stats.RelationshipMurders) or 0) + 1
			stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + (caught and 8 or 3), 0, 100)
			stats.CursedResentment = math.clamp((tonumber(stats.CursedResentment) or 0) + math.random(6, 12), 0, 100)
			stats.Fear = math.clamp((tonumber(stats.Fear) or 0) + (caught and 15 or 9), 0, 100)
			stats.Reputation = math.clamp((tonumber(stats.Reputation) or 0) - (caught and 18 or 8), -100, 100)
			stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - math.random(10, 24), 0, 100)
			stats.Health = math.clamp((tonumber(stats.Health) or 100) - math.random(0, 7), 0, 100)

			logMessage = "You murdered " .. targetName .. ". Their name was moved into your deceased relationships."
			if caught then
				logMessage ..= " Witnesses connected the death back to you, and your wanted level surged."
			else
				logMessage ..= " No one proved it was you, but the fear around you changed."
			end
			logMessage ..= adjustWorldReputation(stats, caught and -4 or -2, caught and 4 or 2, caught and 5 or 3)

			fireMajorPopup(
				player,
				caught and "MURDER EXPOSED" or "MURDER",
				caught and "The killing was traced back to you." or "A relationship ended violently.",
				targetName,
				caught and "Wanted level and fear increased heavily." or "They are now listed as deceased."
			)
		else
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Bond = -math.random(22, 40),
				Trust = -math.random(35, 60),
				Respect = -math.random(8, 18),
				Fear = math.random(24, 45),
			})
			stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + 4, 0, 100)
			stats.Fear = math.clamp((tonumber(stats.Fear) or 0) + 6, 0, 100)
			stats.Reputation = math.clamp((tonumber(stats.Reputation) or 0) - 10, -100, 100)
			stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - math.random(6, 16), 0, 100)
			stats.Health = math.clamp((tonumber(stats.Health) or 100) - math.random(5, 18), 0, 100)
			logMessage = "You tried to murder " .. targetName .. ", but they survived. The relationship is poisoned, and people are asking questions." .. adjustWorldReputation(stats, -2, 2, 3)
		end

	elseif actionId == "challenge" then
		if relationship.Role ~= "Rival" then
			fireLifeUpdate(player, stats, "You can only challenge a rival.")
			return
		end

		if (stats.Age or 0) < 12 then
			fireLifeUpdate(player, stats, "You are too young to issue a serious challenge.")
			return
		end
		local winChance = 25 + math.floor((stats.CursedEnergy or 0) / 8) + math.floor((stats.TechniqueMastery or 0) / 6) + math.floor((stats.Smarts or 0) / 10)
		winChance = math.clamp(winChance, 20, 85)

		if math.random(1, 100) <= winChance then
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Respect = math.random(8, 14),
				Trust = math.random(2, 5),
				Bond = math.random(1, 4)
			})

			stats.CursedEnergy += math.random(5, 12)
			stats.Reputation += math.random(1, 3)
			stats.Health = math.clamp((stats.Health or 100) - math.random(2, 7), 0, 100)

			logMessage = "You challenged " .. relationship.Name .. " directly and proved you were not someone they could ignore." .. adjustWorldReputation(stats, 1, 1, 2)
		else
			BitKaisenRelationships.AdjustRelationship(relationship, {
				Respect = math.random(2, 6),
				Trust = -math.random(1, 4),
				Fear = math.random(1, 4)
			})

			stats.Health = math.clamp((stats.Health or 100) - math.random(8, 18), 0, 100)
			stats.Happiness = math.clamp((stats.Happiness or 100) - math.random(2, 6), 0, 100)

			logMessage = "You challenged " .. relationship.Name .. ", but the clash exposed the gap between confidence and control." .. adjustWorldReputation(stats, 0, 1, 1)
		end

	elseif actionId == "acknowledge" then
		if relationship.Role ~= "Rival" then
			fireLifeUpdate(player, stats, "That action only makes sense with a rival.")
			return
		end

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Trust = math.random(4, 8),
			Respect = math.random(3, 7),
			Bond = math.random(0, 3),
			Fear = -math.random(0, 2)
		})

		logMessage = "You acknowledged " .. relationship.Name .. " as a real rival instead of treating them like noise. The respect between you shifted."

	elseif actionId == "encourage_child" then
		if relationship.Role ~= "Child" and relationship.Role ~= "Student" then
			fireLifeUpdate(player, stats, "You can only encourage a child or student with this action.")
			return
		end

		BitKaisenRelationships.AdjustRelationship(relationship, {
			Bond = math.random(3, 7),
			Trust = math.random(3, 7),
			Respect = math.random(1, 4),
			Fear = -math.random(0, 3)
		})

		stats.Happiness = math.clamp((stats.Happiness or 100) + math.random(1, 4), 0, 100)
		logMessage = "You encouraged " .. relationship.Name .. " instead of forcing growth. It helped them feel seen."

	else
		fireLifeUpdate(player, stats, "Invalid relationship action.")
		return
	end

	if actionId == "train_together" or actionId == "spar" or actionId == "study_together" or actionId == "ask_advice" then
		logMessage = awardUnregisteredProgress(player, stats, math.random(4, 10), "Private growth through relationships", logMessage)
	end

	logMessage = checkPromotionAndPopup(player, stats, logMessage)
	if actionId ~= "brain_transplant" and actionId ~= "murder_relationship" then
		logMessage = appendLine(logMessage, applyRelationshipMilestones(player, stats, relationship))
	end

	if stats.Health <= 0 then
		stats.Alive = false
		logMessage = logMessage .. "\nYour body could not handle the strain."
	end

	if actionId ~= "brain_transplant" and actionId ~= "murder_relationship" then
		logMessage = logMessage .. applyTraitBuffsFromSnapshot(stats, traitBefore, "Relationship", relationship)
	end
	if relationshipActionCostsTurn then
		stats.RelationshipActionsThisAge = math.clamp((tonumber(stats.RelationshipActionsThisAge) or 0) + 1, 0, 3)
	end
	syncFamilyStatus(stats)
	fireLifeUpdate(player, stats, logMessage)
	saveStats(player)
end


function BK_RelationshipService.GetRelationshipsPayload(player)
	local stats = getStats(player)

	if not stats or not stats.Alive then
		return {}
	end

	ensureExtraStats(stats)
	local signature = getRelationshipPayloadSignature(stats)
	local cached = relationshipPayloadCache[player.UserId]
	if cached and cached.Signature == signature and (os.clock() - cached.Time) <= RELATIONSHIP_PAYLOAD_CACHE_TTL then
		return cached.Payload
	end

	local removed = BitKaisenRelationships.PruneRelationships and BitKaisenRelationships.PruneRelationships(stats) or 0
	if removed and removed > 0 then
		stats.RelationshipVersion = (tonumber(stats.RelationshipVersion) or 0) + 1
		signature = getRelationshipPayloadSignature(stats)
		saveStats(player, "Pruned relationship list")
	end

	local notableIds = {}
	for _, npc in ipairs(stats.NotableSorcerers or {}) do
		if typeof(npc) == "table" and npc.Id ~= nil then
			notableIds[tostring(npc.Id)] = true
		end
	end
	local removedNotableCopies = 0
	if typeof(stats.Relationships) == "table" then
		for index = #stats.Relationships, 1, -1 do
			local rel = stats.Relationships[index]
			if typeof(rel) == "table" and tostring(rel.Role or "") == "Notable Sorcerer" and notableIds[tostring(rel.NotableSourceId or rel.Id or "")] then
				table.remove(stats.Relationships, index)
				removedNotableCopies += 1
			end
		end
	end
	if removedNotableCopies > 0 then
		stats.RelationshipVersion = (tonumber(stats.RelationshipVersion) or 0) + 1
		signature = getRelationshipPayloadSignature(stats)
		saveStats(player, "Removed duplicate notable relationship copies")
	end

	local displayList = BitKaisenRelationships.GetDisplayList(stats)
	for _, notable in ipairs(BK_WorldHistoryService.GetAffiliationNotables(stats)) do
		table.insert(displayList, notable)
	end
	for _, clanWarEntry in ipairs(getClanWarAffiliationEntries(stats)) do
		table.insert(displayList, clanWarEntry)
	end
	for _, rival in ipairs(stats.Rivals or {}) do
		if typeof(rival) == "table" then
			table.insert(displayList, {
				Id = "rival_" .. tostring(rival.Id or rival.Name or #displayList + 1),
				Name = tostring(rival.Name or "Unknown Rival"),
				Role = "Rival",
				Status = tostring(rival.Status or "Active"),
				Age = tonumber(rival.Age) or tonumber(stats.Age) or 0,
				Grade = tostring(rival.Grade or "Unknown"),
				CursedTechnique = tostring((rival.Revealed or (stats.ReputationIntelRevealed and stats.ReputationIntelRevealed[rival.Id])) and rival.Technique or "Unknown"),
				Clan = tostring(rival.Clan or "Unknown"),
				Relationship = tostring(rival.Relationship or rival.Reason or "Rival"),
				Bond = math.clamp(35 - (tonumber(rival.Threat) or 0), 0, 100),
				Trust = 0,
				Respect = math.clamp(tonumber(rival.Threat) or 25, 0, 100),
				Fear = math.clamp(tonumber(rival.Threat) or 25, 0, 100),
				Alive = tostring(rival.Status or "Active") ~= "Dead",
				IsRivalEntry = true,
				ReadOnly = true,
			})
		end
	end

	local payload = {
		Relationships = displayList,
		CanBrainTransplant = hasBrainTransplant(stats),
		CanNameChildren = context.OwnsGodModePass and context.OwnsGodModePass(player) == true or false,
	}

	relationshipPayloadCache[player.UserId] = {
		Signature = signature,
		Time = os.clock(),
		Payload = payload,
	}

	return payload
end

function BK_RelationshipService.ProcessRelationshipAction(player, relationshipId, actionId, data)
	invalidateRelationshipPayloadCache(player)
	local result = processRelationshipAction(player, relationshipId, actionId, data)
	local stats = getStats(player)
	if stats then
		stats.RelationshipVersion = (tonumber(stats.RelationshipVersion) or 0) + 1
	end
	invalidateRelationshipPayloadCache(player)
	return result
end

function BK_RelationshipService.Init(ctx)
	context = ctx or {}
	if context.IS_DEBUG then print("[BK_RelationshipService] Phase 5 relationship handling loaded.") end
end

return BK_RelationshipService

