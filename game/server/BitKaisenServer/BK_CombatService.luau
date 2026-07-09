-- ModuleScript: BK_CombatService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose: Server-owned interactive combat sessions for BitKaisen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BitKaisenCombat = require(ReplicatedStorage:WaitForChild("BitKaisenCombat"))
local BitKaisenCursedTools = require(ReplicatedStorage:WaitForChild("BitKaisenCursedTools"))
local BitKaisenDomains = require(ReplicatedStorage:WaitForChild("BitKaisenDomains"))
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))

local function _ct(session, key, fallback)
	local p = session and session.Player
	if not p then return fallback end
	return BitKaisenLocale.tOrFallback(BitKaisenLocale.getPlayerLocale(p.UserId), "combat." .. key, nil, fallback)
end
local function _cl(session, key, params, fallback)
	local s = _ct(session, key, fallback)
	if params then for k, v in pairs(params) do s = s:gsub("{" .. k .. "}", tostring(v)) end end
	return s
end

local BK_CombatService = {}

local context = {}
local sessions = {}
local initialized = false

local TECHNIQUE_MAX_USES = 3
local TECHNIQUE_CE_COST = 18
local BF_CE_COST = 35

local TEST_PURCHASE_PLACE_IDS = {
	[104206065947170] = true,
}

local function getRemote(name, className)
	local remote = ReplicatedStorage:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = ReplicatedStorage
	end
	return remote
end

local getCombatState
local combatAction
local combatStateUpdate
local combatMinigameResult

local function isTestingPlace()
	return RunService:IsStudio() or TEST_PURCHASE_PLACE_IDS[game.PlaceId] == true
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

local function fireMajorPopup(player, title, body, highlight, footer)
	if context.FireMajorPopup then
		context.FireMajorPopup(player, title, body, highlight, footer)
	end
end

local function forceSaveStats(player, reason)
	if context.ForceSaveStats then
		context.ForceSaveStats(player, reason)
	end
end

local function ensureExtraStats(stats)
	if context.EnsureExtraStats then
		context.EnsureExtraStats(stats)
	end
end

local function clampNumber(value, fallback, minValue, maxValue)
	value = tonumber(value) or fallback
	if minValue then value = math.max(minValue, value) end
	if maxValue then value = math.min(maxValue, value) end
	return value
end

local function getStrength(stats)
	return math.max(0, tonumber(stats and stats.Strength) or 0)
end

local function getStrengthCritChance(stats)
	return math.clamp(math.floor(getStrength(stats) / 100), 0, 20)
end

local function getTechniqueName(stats)
	local technique = tostring(stats and stats.CursedTechnique or "None")
	if technique == "None" or technique == "" then
		technique = tostring(stats and stats.InnateTechnique or "None")
	end
	return technique
end

local function buildEnemy(stats, config)
	config = config or {}
	local playerPower = BitKaisenCombat.GetCombatPower(stats)
	local grade = tostring(config.Grade or (playerPower >= 190 and "Special Grade" or playerPower >= 116 and "Grade 1" or playerPower >= 72 and "Grade 2" or "Grade 3"))
	local power = tonumber(config.Power) or math.max(24, math.floor(playerPower * (tonumber(config.PowerScale) or 0.82)) + math.random(-12, 18))
	local maxHp = tonumber(config.MaxHP) or math.clamp(65 + math.floor(power * 0.55), 70, 260)
	local names = {
		"Rogue Curse User",
		"Enemy Clan Fighter",
		"Vengeful Cursed Spirit",
		"Ambushing Sorcerer",
		"Restless Grade Curse",
	}
	return {
		Name = tostring(config.Name or names[math.random(1, #names)]),
		Grade = grade,
		Kind = tostring(config.Kind or "Enemy"),
		Power = power,
		MaxHP = maxHp,
		HP = maxHp,
		ComboMin = math.clamp(tonumber(config.ComboMin) or 1, 1, 3),
		ComboMax = math.clamp(tonumber(config.ComboMax) or 3, 1, 3),
	}
end

local function makeToken(prefix)
	return prefix .. "_" .. tostring(os.clock()):gsub("%.", "") .. "_" .. tostring(math.random(1000, 9999))
end

local function publicState(session)
	if not session then
		return { Active = false }
	end
	return {
		Active = true,
		Phase = session.Phase,
		Round = session.Round,
		Source = session.Source,
		PlayerHP = session.PlayerHP,
		PlayerMaxHP = session.PlayerMaxHP,
		PlayerCE = session.PlayerCE,
		PlayerMaxCE = session.PlayerMaxCE,
		TechniqueUses = session.TechniqueUses or 0,
		TechniqueMaxUses = session.TechniqueMaxUses or TECHNIQUE_MAX_USES,
		TechniqueCECost = session.TechniqueCECost or TECHNIQUE_CE_COST,
		EnemyName = session.Enemy.Name,
		EnemyGrade = session.Enemy.Grade,
		EnemyKind = session.Enemy.Kind,
		EnemyHP = session.Enemy.HP,
		EnemyMaxHP = session.Enemy.MaxHP,
		Log = session.Log,
		CanReset = session.CanReset == true and session.Winner == "enemy" and session.Phase == "finished",
		ResetProductId = tonumber(context.GetResetFightProductId and context.GetResetFightProductId()) or 0,
		Domain = session.DomainPayload,
		BlackFlashCECost = BF_CE_COST,
		TestingPlace = isTestingPlace(),
		PendingAttack = session.PendingAttackPublic,
		PendingDefense = session.PendingDefensePublic,
		PendingCounter = session.PendingCounterPublic,
		PendingDomainClash = session.PendingDomainClashPublic,
		Winner = session.Winner,
	}
end

local function sendState(player, session)
	if session then
		local stats = getStats(player)
		if stats then
			BitKaisenDomains.Ensure(stats)
			session.DomainPayload = BitKaisenDomains.GetCombatPayload(stats)
		end
	end
	if combatStateUpdate then
		combatStateUpdate:FireClient(player, publicState(session))
	end
end

local function addLog(session, text)
	table.insert(session.Log, 1, tostring(text))
	while #session.Log > 8 do
		table.remove(session.Log)
	end
end

local function syncHealthToStats(player, session)
	local stats = getStats(player)
	if not stats then return end
	stats.Health = math.clamp(math.floor(session.PlayerHP + 0.5), 0, 100)
	stats.CursedEnergy = math.max(0, math.floor(session.PlayerCE + 0.5))
	if stats.Health <= 0 then
		local charges = tonumber(stats.MiracleCharges) or 0
		if tostring(stats.CursedTechnique) == "Miracle" and charges > 0 then
			stats.MiracleCharges = charges - 1
			stats.Health = 1
			session.PlayerHP = 1
			local remaining = tonumber(stats.MiracleCharges) or 0
			fireLifeUpdate(player, stats, remaining > 0
				and ("<font color='#c8a4ff'><b>[ MIRACLE ]</b></font> A miracle rewrote your fate. Marks remaining: <b>" .. remaining .. "</b>.")
				or "<font color='#c8a4ff'><b>[ MIRACLE ]</b></font> Your last miracle saved you. Your marks have disappeared — you are now completely vulnerable.")
		else
			stats.Alive = false
			stats.CauseOfDeath = _cl(session, "cause_of_death", {enemy = tostring(session.Enemy and session.Enemy.Name or "an enemy")}, "Defeated in combat by " .. tostring(session.Enemy and session.Enemy.Name or "an enemy"))
		end
	end
end

local function finishCombat(player, session, winner, reason)
	session.Phase = "finished"
	session.Winner = winner
	session.PendingAttack = nil
	session.PendingDefense = nil
	session.PendingCounter = nil
	session.PendingDomainClash = nil
	session.PendingAttackPublic = nil
	session.PendingDefensePublic = nil
	session.PendingCounterPublic = nil
	session.PendingDomainClashPublic = nil

	local stats = getStats(player)
	if stats then
		syncHealthToStats(player, session)
		if winner == "enemy" and stats.Alive == false then
			session.CanReset = false
		end
		if winner == "player" then
			local moneyGain = math.max(25, math.floor(session.Enemy.Power * 7))
			local repGain = math.max(1, math.floor(session.Enemy.Power / 22))
			local baseCEGain = math.max(1, math.floor(session.Enemy.Power / 30))
			local ceGain, ceBonus, ceTool = BitKaisenCursedTools.ApplyCEGain(stats, baseCEGain)
			stats.Money = (tonumber(stats.Money) or 0) + moneyGain
			stats.Reputation = (tonumber(stats.Reputation) or 0) + repGain
			stats.CursedEnergy = (tonumber(stats.CursedEnergy) or 0) + ceGain
			stats.CombatWins = (tonumber(stats.CombatWins) or 0) + 1
			local dropText = ""
			local dropChance, maxRarity = BitKaisenCursedTools.GetCombatDropConfig(session.Enemy.Power)
			if math.random(1, 100) <= dropChance then
				local tool = BitKaisenCursedTools.RollDrop(maxRarity)
				if tool then
					local _, added = BitKaisenCursedTools.AddTool(stats, tool.Id, tostring(session.Enemy.Name or "Combat Drop"), stats.Year or os.date("!*t").year)
					if added then
						dropText = " Cursed tool found: " .. tostring(tool.Name) .. "."
					else
						local duplicateReward = BitKaisenCursedTools.GetDuplicateReward(tool)
						stats.Money = (tonumber(stats.Money) or 0) + duplicateReward.Money
						stats.CursedEnergy = (tonumber(stats.CursedEnergy) or 0) + duplicateReward.CursedEnergy
						dropText = " Duplicate cursed tool converted: " .. tostring(tool.Name) .. " became +$" .. tostring(duplicateReward.Money) .. " and +" .. tostring(duplicateReward.CursedEnergy) .. " CE."
					end
				end
			end
			local ceToolText = ceBonus > 0 and (" (including +" .. tostring(ceBonus) .. " from " .. tostring(ceTool and ceTool.Name or "equipped cursed tool") .. ")") or ""
			addLog(session, _cl(session, "log_victory", {money = moneyGain, rep = repGain, ce = ceGain, tools = ceToolText .. "." .. dropText}, "Victory. Rewards: +$" .. tostring(moneyGain) .. ", +" .. tostring(repGain) .. " reputation, +" .. tostring(ceGain) .. " CE" .. ceToolText .. "." .. dropText))
			fireLifeUpdate(player, stats, "<font color='#7ee787'><b>[ COMBAT ]</b></font> You defeated <b>" .. session.Enemy.Name .. "</b>. Rewards: <b>+$" .. tostring(moneyGain) .. "</b>, Reputation <b>+" .. tostring(repGain) .. "</b>, CE <b>+" .. tostring(ceGain) .. "</b>" .. ceToolText .. "." .. (dropText ~= "" and ("\n<font color='#f0b955'><b>[ CURSED TOOL ]</b></font>" .. dropText) or ""))
		elseif winner == "enemy" then
			stats.CombatLosses = (tonumber(stats.CombatLosses) or 0) + 1
			addLog(session, _cl(session, "log_defeat", {reason = tostring(reason or _ct(session, "log_defeat_default", "You were overwhelmed."))}, "Defeat. " .. tostring(reason or "You were overwhelmed.")))
			fireLifeUpdate(player, stats, "<font color='#e53935'><b>[ COMBAT ]</b></font> You were defeated by <b>" .. session.Enemy.Name .. "</b>. " .. tostring(reason or "Your health collapsed."))
		elseif winner == "fled" then
			stats.CombatFlees = (tonumber(stats.CombatFlees) or 0) + 1
			addLog(session, _ct(session, "log_escaped", "You escaped the fight."))
			fireLifeUpdate(player, stats, "<font color='#ffcd69'><b>[ COMBAT ]</b></font> You escaped from <b>" .. session.Enemy.Name .. "</b>.")
		end
		local domainReason = winner == "player" and "combat_win" or (winner == "enemy" and "combat_loss" or nil)
		if domainReason then
			local domainGain = BitKaisenDomains.GetProgressGain(stats, domainReason)
			local domainText = BitKaisenDomains.AddProgress(stats, domainGain, domainReason)
			if domainText ~= "" then
				addLog(session, _ct(session, "log_domain_progress", "Domain progress gained from combat pressure."))
			end
		end
		if typeof(session.OnFinish) == "function" then
			local ok, err = pcall(session.OnFinish, player, session, winner, reason, stats)
			if not ok then
				warn("[BK_CombatService] OnFinish callback failed: " .. tostring(err))
			end
		end
		forceSaveStats(player, "combat_finished")
	end

	sendState(player, session)
	if winner ~= "enemy" or session.CanReset ~= true then
		local clearDelay = winner == "fled" and 1.1 or (winner == "enemy" and 1.35 or 2.2)
		task.delay(clearDelay, function()
			if sessions[player.UserId] == session and session.Phase == "finished" then
				sessions[player.UserId] = nil
				sendState(player, nil)
			end
		end)
	end
end

local resolveEnemyCombo
local resolveAttack
local resolveCounter

local function beginEnemyCombo(player, session, guarded, autoResolve, warningOverride)
	local hits = math.random(session.Enemy.ComboMin, session.Enemy.ComboMax)
	if (tonumber(session.EnemyAdvantage) or 0) > 0 then
		hits = hits + 1
		session.EnemyAdvantage = 0
	end
	local token = makeToken("defense")
	session.Phase = "enemy_attack"
	session.PendingAttack = nil
	session.PendingAttackPublic = nil
	session.PendingDefense = {
		Token = token,
		Hits = hits,
		Guarded = guarded == true,
		StartedAt = os.clock(),
		ExpiresAt = os.clock() + 4,
	}
	if autoResolve == true then
		session.PendingDefensePublic = nil
	else
		session.PendingDefensePublic = {
			Token = token,
			Hits = hits,
			Window = 0.8,
			Warning = tostring(warningOverride or _cl(session, "log_warning_dodge", {enemy = session.Enemy.Name}, session.Enemy.Name .. " is attacking. Prepare to dodge!")),
			Guarded = guarded == true,
		}
	end
	addLog(session, _cl(session, "log_prepares_combo", {enemy = session.Enemy.Name, hits = hits}, session.Enemy.Name .. " prepares a " .. tostring(hits) .. " hit combo."))
	sendState(player, session)
	task.delay(5, function()
		if sessions[player.UserId] == session and session.PendingDefense and session.PendingDefense.Token == token then
			resolveEnemyCombo(player, session, 0, 0)
		end
	end)
end

function resolveEnemyCombo(player, session, accuracy, perfectHits)
	local pending = session.PendingDefense
	if not pending then return end
	local hits = pending.Hits
	local guarded = pending.Guarded == true
	local dodgeRatio = math.clamp(tonumber(accuracy) or 0, 0, 1)
	local perfect = math.clamp(tonumber(perfectHits) or 0, 0, hits)
	local baseDamage = math.max(5, math.floor(session.Enemy.Power * 0.16)) * hits
	local damageMult = 1 - (dodgeRatio * (guarded and 0.78 or 0.62))
	local damage = math.max(0, math.floor(baseDamage * damageMult + 0.5))
	if dodgeRatio >= 1 or perfect >= hits then
		damage = 0
	end
	session.PlayerHP = math.clamp(session.PlayerHP - damage, 0, session.PlayerMaxHP)
	session.PendingDefense = nil
	session.PendingDefensePublic = nil
	if damage <= 0 then
		addLog(session, _ct(session, "log_perfect_defense", "Perfect defense. You avoided the full combo."))
	else
		addLog(session, _cl(session, "log_defense_resolved", {dmg = damage}, "Defense resolved. Health -" .. tostring(damage) .. "."))
	end
	if session.PlayerHP <= 0 then
		finishCombat(player, session, "enemy", "You were beaten down during the enemy combo.")
		return
	end
	local counterEligible = perfect >= 1 or dodgeRatio >= 0.67 or (hits == 1 and dodgeRatio >= 1)
	if counterEligible then
		local token = makeToken("counter")
		session.Phase = "counter"
		session.PendingCounter = { Token = token, StartedAt = os.clock(), ExpiresAt = os.clock() + 1.15 }
		session.PendingCounterPublic = { Token = token, Window = 1.15, Warning = "Counter opening." }
		addLog(session, _ct(session, "log_counter_open", "Counter opening. Strike now."))
		syncHealthToStats(player, session)
		sendState(player, session)
		task.delay(1.35, function()
			if sessions[player.UserId] == session and session.PendingCounter and session.PendingCounter.Token == token then
				resolveCounter(player, session, false)
			end
		end)
	else
		session.Round += 1
		session.Phase = "pause"
		addLog(session, _ct(session, "log_regain_stance", "You regain your stance."))
		syncHealthToStats(player, session)
		sendState(player, session)
		task.delay(0.35, function()
			if sessions[player.UserId] == session and session.Phase == "pause" then
				session.Phase = "player_turn"
				sendState(player, session)
			end
		end)
	end
end

local function startAttackCheck(player, session, isTechnique, autoResolve, isBlackFlash)
	local stats = getStats(player)
	local token = makeToken("attack")
	local playerPower = BitKaisenCombat.GetCombatPower(stats)
	local targetSide = math.random(1, 4)
	local targetCenter = ({0.125, 0.375, 0.625, 0.875})[targetSide]
	local mastery = tonumber(stats and stats.TechniqueMastery) or 0
	local strength = getStrength(stats)
	local duration = math.clamp(1.7 - (math.min(playerPower, 260) / 900), 1.28, 1.7)
	local targetWidth = math.clamp(0.12 + (mastery / 900) + (strength / 5000), 0.12, 0.24)
	local sweetWidth = math.clamp(0.035 + (mastery / 2400) + (strength / 12000), 0.035, 0.085)
	if isTechnique then
		duration = math.max(1.12, duration - 0.12)
		targetWidth = math.clamp(targetWidth * 0.72, 0.08, 0.15)
		sweetWidth = math.clamp(sweetWidth * 0.55, 0.018, 0.045)
	end
	if isBlackFlash then
		duration = math.max(1.05, duration - 0.18)
		targetWidth = math.clamp(targetWidth * 0.68, 0.07, 0.11)
		sweetWidth = math.clamp(sweetWidth * 0.4, 0.010, 0.020)
	end
	session.Phase = "attack_check"
	session.PendingAttack = {
		Token = token,
		StartedAt = os.clock(),
		ExpiresAt = os.clock() + 5,
		IsTechnique = isTechnique == true,
		Target = targetCenter,
		TargetWidth = targetWidth,
		SweetWidth = sweetWidth,
	}
	if autoResolve == true then
		session.PendingAttackPublic = nil
	else
		session.PendingAttackPublic = {
			Token = token,
			Duration = duration,
			Target = targetCenter,
			TargetWidth = targetWidth,
			SweetWidth = sweetWidth,
			TargetSide = targetSide,
			IsTechnique = isTechnique == true,
			IsBlackFlash = isBlackFlash == true,
		}
	end
	addLog(session, isTechnique and _ct(session, "log_tech_timing", "Technique timing started.") or _ct(session, "log_attack_timing", "Attack timing started."))
	sendState(player, session)
	task.delay(5, function()
		if sessions[player.UserId] == session and session.PendingAttack and session.PendingAttack.Token == token then
			resolveAttack(player, session, 0, false)
		end
	end)
end

function resolveAttack(player, session, accuracy, sweet)
	local pending = session.PendingAttack
	if not pending then return end
	local stats = getStats(player)
	local playerPower = BitKaisenCombat.GetCombatPower(stats)
	local strength = getStrength(stats)
	local baseDamage = math.max(7, math.floor((math.min(playerPower, 260) * (pending.IsTechnique and 0.18 or 0.13)) + (pending.IsTechnique and 0 or math.min(22, strength * 0.035))))
	local quality = math.clamp(tonumber(accuracy) or 0, 0, 1)
	local isTechnique = pending.IsTechnique == true
	local isSweet = sweet == true or quality >= 0.96
	local isBlackFlash = session.BlackFlashPending == true
	if isBlackFlash then session.BlackFlashPending = nil end
	local critChance = isTechnique and 0 or getStrengthCritChance(stats)
	if not isTechnique and quality >= 0.7 and math.random(1, 100) <= critChance then
		isSweet = true
	end
	local damage = math.max(2, math.floor(baseDamage * (0.35 + quality)))
	if isTechnique then
		if isSweet then
			damage = math.max(damage, math.floor(session.Enemy.MaxHP * 0.35))
		elseif quality >= 0.7 then
			damage = math.max(damage, math.floor(session.Enemy.MaxHP * 0.22))
		elseif quality >= 0.35 then
			damage = math.max(damage, math.floor(session.Enemy.MaxHP * 0.12))
		end
		damage = math.min(damage, math.floor(session.Enemy.MaxHP * 0.35))
	elseif isSweet then
		damage = math.floor(baseDamage * 1.85)
		damage = math.min(damage, math.floor(session.Enemy.MaxHP * 0.24))
	else
		damage = math.min(damage, math.floor(session.Enemy.MaxHP * 0.18))
	end
	if isSweet then
		if isBlackFlash then
			addLog(session, _ct(session, "log_black_flash", "BLACK FLASH. Cursed energy and impact converged in the same instant."))
		else
			addLog(session, isTechnique and _ct(session, "log_perfect_tech", "Perfect technique timing. Massive impact.") or _ct(session, "log_perfect_hit", "Sweet spot. Maximum impact."))
		end
	elseif quality >= 0.7 then
		addLog(session, isTechnique and _ct(session, "log_clean_tech", "Technique connected cleanly.") or (isBlackFlash and _ct(session, "log_strong_bf", "Strong hit — timing nearly landed the Black Flash.") or _ct(session, "log_clean_hit", "Clean hit.")))
	elseif quality >= 0.35 then
		addLog(session, isTechnique and _ct(session, "log_graze_tech", "Technique grazed the target.") or (isBlackFlash and _ct(session, "log_weak_bf", "Black Flash timing slipped. Weak impact.") or _ct(session, "log_glancing_hit", "Glancing hit.")))
	else
		addLog(session, isTechnique and _ct(session, "log_failed_tech", "Technique timing failed.") or (isBlackFlash and _ct(session, "log_bf_failed", "Black Flash failed. No amplification.") or _ct(session, "log_mistimed", "Mistimed attack.")))
	end
	if isBlackFlash then
		if isSweet then
			damage = math.floor(damage * 2.5)
			damage = math.min(damage, math.floor(session.Enemy.MaxHP * 0.65))
			local bfStats = getStats(player)
			if bfStats then
				bfStats.BlackFlashCount = (tonumber(bfStats.BlackFlashCount) or 0) + 1
			end
			addLog(session, _cl(session, "log_bf_number", {n = tostring(tonumber(bfStats and bfStats.BlackFlashCount) or 1)}, "BLACK FLASH #" .. tostring(tonumber(bfStats and bfStats.BlackFlashCount) or 1) .. " — ×2.5 damage."))
		elseif quality >= 0.7 then
			damage = math.floor(damage * 1.3)
		elseif quality < 0.35 then
			-- penalización por fallar Black Flash: CE extra perdida y el enemigo gana ventaja
			session.PlayerCE = math.max(0, session.PlayerCE - 15)
			local pfStats = getStats(player)
			if pfStats then pfStats.CursedEnergy = math.floor(session.PlayerCE + 0.5) end
			session.EnemyAdvantage = (tonumber(session.EnemyAdvantage) or 0) + 1
			addLog(session, _ct(session, "log_exposed", "The failed attempt left you exposed. The enemy senses the opening."))
		end
	end
	if isTechnique then
		session.TechniqueUses = (tonumber(session.TechniqueUses) or 0) + 1
		session.PlayerCE = math.max(0, session.PlayerCE - (tonumber(session.TechniqueCECost) or TECHNIQUE_CE_COST))
	end
	session.Enemy.HP = math.clamp(session.Enemy.HP - damage, 0, session.Enemy.MaxHP)
	addLog(session, _cl(session, "log_enemy_takes", {enemy = session.Enemy.Name, dmg = damage}, session.Enemy.Name .. " takes " .. tostring(damage) .. " damage."))
	session.PendingAttack = nil
	session.PendingAttackPublic = nil
	if session.Enemy.HP <= 0 then
		finishCombat(player, session, "player")
		return
	end
	session.Phase = "pause"
	addLog(session, _ct(session, "log_enemy_reels", "The enemy reels. Prepare for the counterattack."))
	sendState(player, session)
	task.delay(0.15, function()
		if sessions[player.UserId] == session and session.Phase == "pause" then
			beginEnemyCombo(player, session, false)
		end
	end)
end

function resolveCounter(player, session, success)
	local pending = session.PendingCounter
	if not pending then return end
	session.PendingCounter = nil
	session.PendingCounterPublic = nil
	if success == true then
		local stats = getStats(player)
		local strength = getStrength(stats)
		local damage = math.max(8, math.floor((math.min(BitKaisenCombat.GetCombatPower(stats), 260) * 0.11) + math.min(18, strength * 0.025)))
		damage = math.min(damage, math.floor(session.Enemy.MaxHP * 0.16))
		session.Enemy.HP = math.clamp(session.Enemy.HP - damage, 0, session.Enemy.MaxHP)
		addLog(session, _cl(session, "log_counter_hit", {dmg = damage}, "Counter attack landed for " .. tostring(damage) .. "."))
		if session.Enemy.HP <= 0 then
			finishCombat(player, session, "player")
			return
		end
	else
		addLog(session, _ct(session, "log_counter_miss", "Counter missed."))
	end
	session.Round += 1
	session.Phase = "pause"
	addLog(session, _ct(session, "log_reset_stance", "You reset your footing."))
	sendState(player, session)
	task.delay(0.35, function()
		if sessions[player.UserId] == session and session.Phase == "pause" then
			session.Phase = "player_turn"
			sendState(player, session)
		end
	end)
end

function BK_CombatService.HasActiveFight(player)
	if not player then
		return false
	end
	local existingSession = sessions[player.UserId]
	return existingSession ~= nil and existingSession.Phase ~= "finished"
end

function BK_CombatService.StartCombat(player, source, enemyConfig)
	local stats = getStats(player)
	if not player or not stats or stats.Alive == false then
		return false, "No active life."
	end
	if BK_CombatService.HasActiveFight(player) then
		-- Some callers (e.g. Clan War actions) can be invoked again while a fight
		-- from the same source is still in progress; overwriting sessions[player.UserId]
		-- here would silently reset the in-progress fight (HP/round/pending minigame)
		-- back to the start every time, which is what caused Clan War combat to
		-- keep reinitiating instead of resolving.
		sendState(player, sessions[player.UserId])
		return false, "Already in combat."
	end
	ensureExtraStats(stats)
	local enemy = buildEnemy(stats, enemyConfig)
	local playerHealth = math.clamp(tonumber(stats.Health) or 100, 1, 100)
	local playerCE = math.max(0, tonumber(stats.CursedEnergy) or 0)
	local session = {
		Source = tostring(source or "Combat"),
		Player = player,
		Enemy = enemy,
		Phase = "player_turn",
		Round = 1,
		PlayerHP = playerHealth,
		PlayerMaxHP = 100,
		PlayerCE = playerCE,
		PlayerMaxCE = math.max(playerCE, 100),
		StartHealth = playerHealth,
		StartCE = playerCE,
		TechniqueUses = 0,
		TechniqueMaxUses = TECHNIQUE_MAX_USES,
		TechniqueCECost = TECHNIQUE_CE_COST,
		DomainUses = 0,
		DomainMaxUses = 1,
		Log = {},
		CanReset = true,
		StartedAt = os.clock(),
		OnFinish = typeof(enemyConfig and enemyConfig.OnFinish) == "function" and enemyConfig.OnFinish or nil,
		Metadata = typeof(enemyConfig and enemyConfig.Metadata) == "table" and enemyConfig.Metadata or nil,
	}
	sessions[player.UserId] = session
	addLog(session, _cl(session, "log_engaged", {enemy = enemy.Name}, enemy.Name .. " engaged you in combat."))
	fireMajorPopup(player, _ct(session, "log_combat_started", "COMBAT STARTED"), _cl(session, "log_combat_forced", {enemy = enemy.Name}, enemy.Name .. " has forced a fight."), enemy.Grade, _ct(session, "log_combat_hint", "Attack, defend, or flee."))
	sendState(player, session)
	return true
end

function BK_CombatService.ClearCurrentFight(player, reason)
	if not player then
		return false
	end
	local session = sessions[player.UserId]
	if not session then
		sendState(player, nil)
		return false
	end
	sessions[player.UserId] = nil
	addLog(session, _cl(session, "log_fight_cleared", {reason = reason and (" (" .. tostring(reason) .. ")") or ""}, "Fight cleared" .. (reason and (" (" .. tostring(reason) .. ")") or "") .. "."))
	sendState(player, nil)
	return true
end

function BK_CombatService.ResetCurrentFight(player, reason)
	local session = sessions[player.UserId]
	if not session or (session.Phase == "finished" and session.Winner ~= "enemy") then
		return false
	end
	session.PlayerHP = session.StartHealth
	session.PlayerCE = session.StartCE
	session.Enemy.HP = session.Enemy.MaxHP
	session.Round = 1
	session.Phase = "player_turn"
	session.Winner = nil
	session.TechniqueUses = 0
	session.PendingAttack = nil
	session.PendingDefense = nil
	session.PendingCounter = nil
	session.PendingDomainClash = nil
	session.PendingAttackPublic = nil
	session.PendingDefensePublic = nil
	session.PendingCounterPublic = nil
	session.PendingDomainClashPublic = nil
	local stats = getStats(player)
	if stats then
		stats.Alive = true
		stats.Health = math.clamp(math.floor(session.PlayerHP + 0.5), 1, 100)
		stats.CursedEnergy = math.max(0, math.floor(session.PlayerCE + 0.5))
		stats.CauseOfDeath = nil
		fireLifeUpdate(player, stats, "<font color='#7ee787'><b>[ COMBAT RESET ]</b></font> Your fight was reset to its starting stats.")
		forceSaveStats(player, "combat_reset")
	end
	addLog(session, _cl(session, "log_fight_reset", {reason = reason and (" (" .. tostring(reason) .. ")") or ""}, "Fight reset to starting stats" .. (reason and (" (" .. tostring(reason) .. ")") or "") .. "."))
	sendState(player, session)
	return true
end

local function finishDomainUse(player, session, damage, progressReason)
	local stats = getStats(player)
	if not stats then return end

	-- CT-specific effect: modify damage before applying
	local ctEffect = BitKaisenDomains.GetCTCombatEffect(stats)
	if ctEffect then
		if (ctEffect.DamageMult or 1) ~= 1 then
			damage = math.floor(damage * ctEffect.DamageMult)
		end
		if ctEffect.CritChance and math.random(1, 100) <= ctEffect.CritChance then
			damage = math.floor(damage * 1.5)
			addLog(session, _ct(session, "log_domain_crit", "Critical geometry aligned, damage amplified."))
		end
	end

	session.Enemy.HP = math.clamp(session.Enemy.HP - damage, 0, session.Enemy.MaxHP)
	addLog(session, _cl(session, "log_domain_dealt", {dmg = damage}, "Domain dealt " .. tostring(damage) .. " damage."))

	-- CT-specific effect: post-damage (CE refund, heal, narrative)
	if ctEffect then
		if (ctEffect.CERefund or 0) > 0 then
			session.PlayerCE = math.clamp(session.PlayerCE + ctEffect.CERefund, 0, session.PlayerMaxCE or 999)
			stats.CursedEnergy = math.floor(session.PlayerCE + 0.5)
		end
		if (ctEffect.Heal or 0) > 0 then
			session.PlayerHP = math.clamp(session.PlayerHP + ctEffect.Heal, 0, session.PlayerMaxHP)
			stats.Health = math.clamp(math.floor(session.PlayerHP + 0.5), 0, 100)
		end
		if ctEffect.Log then
			addLog(session, ctEffect.Log)
		end
	end

	-- Fire challenge event (fixes "use_domain" challenge never completing)
	if context.OnChallengeEvent then
		context.OnChallengeEvent(player, "domain_used", {})
	end

	local progressText = BitKaisenDomains.AddProgress(stats, BitKaisenDomains.GetProgressGain(stats, progressReason), progressReason)
	if progressText ~= "" then
		addLog(session, _ct(session, "log_domain_mastery", "Domain mastery improved."))
	end
	if session.Enemy.HP <= 0 then
		finishCombat(player, session, "player")
		return
	end
	session.Round += 1
	session.Phase = "pause"
	sendState(player, session)
	task.delay(0.45, function()
		if sessions[player.UserId] == session and session.Phase == "pause" then
			beginEnemyCombo(player, session, false)
		end
	end)
end

function resolveDomainClash(player, session, success)
	local pending = session.PendingDomainClash
	if not pending then return end
	session.PendingDomainClash = nil
	session.PendingDomainClashPublic = nil

	local stats = getStats(player)
	if not stats then return end

	local damage = pending.Damage
	local domainName = pending.DomainName

	if success then
		stats.DomainClashesWon = (tonumber(stats.DomainClashesWon) or 0) + 1
		damage = math.floor(damage * 1.15)
		addLog(session, _cl(session, "log_domain_won", {domain = domainName}, tostring(domainName) .. " won the domain clash."))
		finishDomainUse(player, session, damage, "clash")
	else
		stats.DomainClashesLost = (tonumber(stats.DomainClashesLost) or 0) + 1
		local backlash = math.max(8, math.floor(session.Enemy.Power * 0.14))
		session.PlayerHP = math.clamp(session.PlayerHP - backlash, 0, session.PlayerMaxHP)
		stats.Health = math.clamp(math.floor(session.PlayerHP + 0.5), 0, 100)
		addLog(session, _cl(session, "log_domain_lost", {domain = domainName, dmg = backlash}, tostring(domainName) .. " lost the domain clash. Backlash hit for " .. tostring(backlash) .. "."))
		if session.PlayerHP <= 0 then
			finishCombat(player, session, "enemy", "Your domain collapsed under the clash.")
			return
		end
		damage = math.floor(damage * 0.45)
		finishDomainUse(player, session, damage, "domain_use")
	end
end

local function resolveDomainAction(player, session)
	local stats = getStats(player)
	if not stats then return end
	BitKaisenDomains.Ensure(stats)
	local domain = BitKaisenDomains.GetCombatPayload(stats)
	local uses = tonumber(session.DomainUses) or 0
	if domain.Unlocked ~= true then
		addLog(session, _ct(session, "log_domain_none", "Your domain has not manifested yet."))
		sendState(player, session)
		return
	end
	if uses >= (tonumber(session.DomainMaxUses) or 1) then
		addLog(session, _ct(session, "log_domain_cooldown", "You cannot expand your domain again in this fight."))
		sendState(player, session)
		return
	end
	local cost = tonumber(domain.Cost) or 100
	if session.PlayerCE < cost then
		addLog(session, _cl(session, "log_domain_no_ce", {cost = cost}, "Not enough CE to expand your domain. Need " .. tostring(cost) .. " CE."))
		sendState(player, session)
		return
	end

	session.DomainUses = uses + 1
	session.PlayerCE = math.max(0, session.PlayerCE - cost)
	stats.CursedEnergy = math.max(0, math.floor(session.PlayerCE + 0.5))
	local playerPower = BitKaisenCombat.GetCombatPower(stats) + (tonumber(domain.ClashBonus) or 0) + math.floor((tonumber(domain.Stability) or 0) / 4)
	local enemyPower = tonumber(session.Enemy.Power) or 1
	local complete = tostring(domain.Stage) == "Complete"
	local clash = enemyPower >= playerPower * 0.72 or math.random(1, 100) <= 28
	local damage = complete and math.floor(session.Enemy.MaxHP * 0.48) or math.floor(session.Enemy.MaxHP * 0.32)

	if clash then
		-- The clash used to resolve on a single dice roll (playerPower+rand
		-- vs enemyPower+rand). It's now a real minigame (see openDomainClashMinigame
		-- in CombatPanel.luau) -- the enemy's pull rate below reuses that same
		-- power ratio so a clash against a much stronger enemy is genuinely
		-- harder to win, not just a coin flip either way.
		local powerRatio = enemyPower / math.max(1, playerPower)
		local pullRate = math.clamp(7 + (powerRatio - 1) * 12, 4, 20)
		local token = makeToken("domain_clash")
		session.Phase = "domain_clash"
		session.PendingDomainClash = {
			Token = token,
			StartedAt = os.clock(),
			ExpiresAt = os.clock() + 4.5,
			Damage = damage,
			DomainName = domain.Name,
		}
		session.PendingDomainClashPublic = {
			Token = token,
			Duration = 4,
			PullRate = pullRate,
			DomainName = domain.Name,
		}
		addLog(session, _cl(session, "log_domain_clash_start", {domain = tostring(domain.Name)}, tostring(domain.Name) .. " is clashing against " .. tostring(session.Enemy.Name) .. "'s resistance!"))
		sendState(player, session)
		task.delay(4.5, function()
			if sessions[player.UserId] == session and session.PendingDomainClash and session.PendingDomainClash.Token == token then
				resolveDomainClash(player, session, false)
			end
		end)
		return
	end

	addLog(session, _cl(session, "log_domain_expand", {domain = tostring(domain.Name)}, "Domain Expansion: " .. tostring(domain.Name) .. "."))
	finishDomainUse(player, session, damage, "domain_use")
end

local function handleAction(player, action, payload)
	local session = sessions[player.UserId]
	if action == "debug_start" then
		if not isTestingPlace() then return end
		BK_CombatService.StartCombat(player, "Testing Encounter", {
			Name = "Testing Curse User",
			Kind = "Curse User",
			Grade = "Grade 2",
			PowerScale = 0.72,
		})
		return
	end
	if action == "reset_purchase_bypass" then
		if session and isTestingPlace() then
			BK_CombatService.ResetCurrentFight(player, "testing bypass")
		end
		return
	end
	if not session or session.Phase == "finished" then return end
	if action == "attack" and session.Phase == "player_turn" then
		local stats = getStats(player)
		if stats and stats.Settings and stats.Settings.SkipCombatSkillChecks == true then
			startAttackCheck(player, session, false, true)
			task.delay(0.15, function()
				if sessions[player.UserId] == session and session.PendingAttack then
					resolveAttack(player, session, 0.78, false)
				end
			end)
		else
			startAttackCheck(player, session, false)
		end
	elseif action == "technique" and session.Phase == "player_turn" then
		local stats = getStats(player)
		local uses = tonumber(session.TechniqueUses) or 0
		local maxUses = tonumber(session.TechniqueMaxUses) or TECHNIQUE_MAX_USES
		local cost = tonumber(session.TechniqueCECost) or TECHNIQUE_CE_COST
		if uses >= maxUses then
			addLog(session, _ct(session, "log_no_tech_uses", "No technique uses left this fight."))
			sendState(player, session)
		elseif session.PlayerCE < cost then
			addLog(session, _cl(session, "log_no_tech_ce", {cost = cost}, "Not enough cursed energy for a technique. Need " .. tostring(cost) .. " CE."))
			sendState(player, session)
		else
			if stats and stats.Settings and stats.Settings.SkipCombatSkillChecks == true then
				startAttackCheck(player, session, true, true)
				task.delay(0.15, function()
					if sessions[player.UserId] == session and session.PendingAttack then
						resolveAttack(player, session, 0.78, false)
					end
				end)
			else
				startAttackCheck(player, session, true)
			end
		end
	elseif action == "black_flash" and session.Phase == "player_turn" then
		if session.PlayerCE < BF_CE_COST then
			addLog(session, _cl(session, "log_bf_no_ce", {cost = BF_CE_COST}, "Not enough CE for Black Flash. Need " .. tostring(BF_CE_COST) .. " CE."))
			sendState(player, session)
		else
			session.PlayerCE = math.max(0, session.PlayerCE - BF_CE_COST)
			local bfStats = getStats(player)
			if bfStats then bfStats.CursedEnergy = math.floor(session.PlayerCE + 0.5) end
			session.BlackFlashPending = true
			addLog(session, _ct(session, "log_bf_timing", "Black Flash attempt. Hit the timing window at the exact moment."))
			if bfStats and bfStats.Settings and bfStats.Settings.SkipCombatSkillChecks == true then
				startAttackCheck(player, session, false, true, true)
				task.delay(0.15, function()
					if sessions[player.UserId] == session and session.PendingAttack then
						resolveAttack(player, session, 1.0, true)
					end
				end)
			else
				startAttackCheck(player, session, false, false, true)
			end
		end
	elseif action == "domain" and session.Phase == "player_turn" then
		resolveDomainAction(player, session)
	elseif action == "defend" and session.Phase == "player_turn" then
		local stats = getStats(player)
		if stats and stats.Settings and stats.Settings.SkipCombatSkillChecks == true then
			beginEnemyCombo(player, session, true, true)
			task.delay(0.15, function()
				if sessions[player.UserId] == session and session.PendingDefense then
					resolveEnemyCombo(player, session, 0.72, 0)
				end
			end)
		else
			beginEnemyCombo(player, session, true)
		end
	elseif action == "flee" and session.Phase == "player_turn" then
		local stats = getStats(player)
		local chance = math.clamp(35 + math.floor((tonumber(stats and stats.Smarts) or 0) / 3) - math.floor(session.Enemy.Power / 16), 12, 82)
		if math.random(1, 100) <= chance then
			finishCombat(player, session, "fled")
		else
			local caughtWarning = _cl(session, "cause_of_death_got_caught", {enemy = session.Enemy.Name}, "You got caught! " .. session.Enemy.Name .. " is attacking. Prepare to dodge!")
			addLog(session, _ct(session, "log_flee_caught", "Flee failed. You got caught as the enemy attacks."))
			beginEnemyCombo(player, session, false, false, caughtWarning)
		end
	end
end

local function handleMinigame(player, token, resultType, accuracy, extra)
	local session = sessions[player.UserId]
	if not session or session.Phase == "finished" then return end
	token = tostring(token or "")
	if resultType == "attack" and session.PendingAttack and session.PendingAttack.Token == token then
		resolveAttack(player, session, accuracy, extra and extra.Sweet == true)
	elseif resultType == "defense" and session.PendingDefense and session.PendingDefense.Token == token then
		resolveEnemyCombo(player, session, accuracy, tonumber(extra and extra.PerfectHits) or 0)
	elseif resultType == "counter" and session.PendingCounter and session.PendingCounter.Token == token then
		resolveCounter(player, session, accuracy == true or (tonumber(accuracy) or 0) >= 0.65)
	elseif resultType == "domain_clash" and session.PendingDomainClash and session.PendingDomainClash.Token == token then
		resolveDomainClash(player, session, accuracy == true)
	end
end

function BK_CombatService.Init(ctx)
	if initialized then return end
	initialized = true
	context = ctx or {}
	getCombatState = getRemote("GetCombatState", "RemoteFunction")
	combatAction = getRemote("CombatAction", "RemoteEvent")
	combatStateUpdate = getRemote("CombatStateUpdate", "RemoteEvent")
	combatMinigameResult = getRemote("CombatMinigameResult", "RemoteEvent")
	getCombatState.OnServerInvoke = function(player)
		local session = sessions[player.UserId]
		if session then
			local stats = getStats(player)
			if stats then
				BitKaisenDomains.Ensure(stats)
				session.DomainPayload = BitKaisenDomains.GetCombatPayload(stats)
			end
		end
		return publicState(session)
	end
	combatAction.OnServerEvent:Connect(handleAction)
	combatMinigameResult.OnServerEvent:Connect(handleMinigame)
	if context.IS_DEBUG then print("[BK_CombatService] Interactive combat loaded.") end
end

function BK_CombatService.PlayerRemoving(player)
	sessions[player.UserId] = nil
end

return BK_CombatService
