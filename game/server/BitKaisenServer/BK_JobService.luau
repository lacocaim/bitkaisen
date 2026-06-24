-- ModuleScript: BK_JobService
-- Location: ServerScriptService.BitKaisenServer
-- Purpose: Civilian route job board and yearly job applications.

local BK_JobService = {}
local context = {}

local JOB_POOL = {
	{ Id = "hospital_attendant", Title = "Hospital Attendant", Pay = 2200, Acceptance = 10, Stat = "Smarts", MinAge = 18 },
	{ Id = "junior_clerk", Title = "Junior Office Clerk", Pay = 1800, Acceptance = 20, Stat = "Smarts", MinAge = 16 },
	{ Id = "security_guard", Title = "Security Guard", Pay = 1700, Acceptance = 30, Stat = "Health", MinAge = 18 },
	{ Id = "dojo_reception", Title = "Dojo Reception Staff", Pay = 1500, Acceptance = 40, Stat = "Reputation", MinAge = 16 },
	{ Id = "courier", Title = "Courier", Pay = 1350, Acceptance = 50, Stat = "Health", MinAge = 15 },
	{ Id = "shop_staff", Title = "Shop Staff", Pay = 1200, Acceptance = 60, Stat = "Happiness", MinAge = 15 },
	{ Id = "tutor", Title = "Tutor", Pay = 1600, Acceptance = 35, Stat = "Smarts", MinAge = 16 },
	{ Id = "kitchen_hand", Title = "Kitchen Hand", Pay = 1050, Acceptance = 70, Stat = "Health", MinAge = 14 },
	{ Id = "cleaner", Title = "Cleaner", Pay = 900, Acceptance = 85, Stat = "Health", MinAge = 14 },
	{ Id = "flyer_runner", Title = "Flyer Runner", Pay = 650, Acceptance = 100, Stat = "Happiness", MinAge = 12 },
	{ Id = "archive_assistant", Title = "Archive Assistant", Pay = 1550, Acceptance = 25, Stat = "Smarts", MinAge = 16 },
	{ Id = "train_station_staff", Title = "Station Staff", Pay = 1300, Acceptance = 55, Stat = "Reputation", MinAge = 16 },
	{ Id = "family_store_helper", Title = "Family Store Helper", Pay = 800, Acceptance = 90, Stat = "Happiness", MinAge = 12 },
	{ Id = "delivery_loader", Title = "Delivery Loader", Pay = 1150, Acceptance = 75, Stat = "Health", MinAge = 15 },
	{ Id = "private_assistant", Title = "Private Assistant", Pay = 2400, Acceptance = 12, Stat = "Smarts", MinAge = 18 },
}

local function getStats(player)
	return context.GetStats and context.GetStats(player) or nil
end

local function fireLifeUpdate(player, stats, message)
	if context.FireLifeUpdate then
		context.FireLifeUpdate(player, stats, message)
	end
end

local function adjustWorldReputation(stats, fameDelta, fearDelta, pathDelta)
	if context.AdjustWorldReputation then
		return context.AdjustWorldReputation(stats, fameDelta, fearDelta, pathDelta)
	end
	return ""
end

local function saveStats(player, reason)
	if context.SaveStats then
		context.SaveStats(player, reason)
	end
end

local function getYear(stats)
	return tonumber(stats and stats.Year) or (2000 + (tonumber(stats and stats.Age) or 0))
end

local function cloneJob(job, rank)
	return {
		Id = job.Id,
		Title = job.Title,
		Pay = job.Pay,
		Acceptance = job.Acceptance,
		Stat = job.Stat,
		Rank = rank,
		MinAge = job.MinAge,
	}
end

local function ensureJobState(stats)
	stats.JobApplicationsThisYear = tonumber(stats.JobApplicationsThisYear) or 0
	stats.JobBoardYear = tonumber(stats.JobBoardYear) or -1
	stats.JobBoardSeed = tonumber(stats.JobBoardSeed) or 0
	stats.JobHistory = typeof(stats.JobHistory) == "table" and stats.JobHistory or {}
	stats.RogueActions = math.max(0, tonumber(stats.RogueActions) or 0)
	stats.RogueActionsThisYear = math.max(0, tonumber(stats.RogueActionsThisYear) or 0)
	stats.RogueNetwork = math.clamp(tonumber(stats.RogueNetwork) or 0, 0, 100)
	stats.JobExperience = math.max(0, tonumber(stats.JobExperience) or 0)
	stats.JobLevel = math.clamp(tonumber(stats.JobLevel) or 0, 0, 5)
	stats.JobYearsWorked = math.max(0, tonumber(stats.JobYearsWorked) or 0)
	stats.JobSalary = math.max(0, tonumber(stats.JobSalary) or 0)
	stats.RetiredFromSorcery = stats.RetiredFromSorcery == true
	stats.RetirementYears = math.max(0, tonumber(stats.RetirementYears) or 0)
	stats.CivilianStability = math.clamp(tonumber(stats.CivilianStability) or 0, 0, 100)
end

local function generateBoard(stats)
	ensureJobState(stats)
	local year = getYear(stats)
	if stats.JobBoardYear == year and typeof(stats.JobBoard) == "table" and #stats.JobBoard == 10 then
		return stats.JobBoard
	end

	local pool = {}
	for _, job in ipairs(JOB_POOL) do
		table.insert(pool, job)
	end

	local board = {}
	for rank = 1, 10 do
		if #pool <= 0 then break end
		local index = math.random(1, #pool)
		local job = table.remove(pool, index)
		local copy = cloneJob(job, rank)
		copy.Acceptance = math.clamp(rank * 10, 10, 100)
		table.insert(board, copy)
	end

	table.sort(board, function(a, b)
		return (a.Acceptance or 100) < (b.Acceptance or 100)
	end)

	stats.JobBoardYear = year
	stats.JobBoard = board
	stats.JobApplicationsThisYear = 0
	stats.RogueActionsThisYear = 0
	return board
end

local function getStatBonus(stats, statName)
	local value = tonumber(stats and stats[statName]) or 0
	return math.clamp(math.floor(value / 20), 0, 8)
end

local function canGoRogue(stats)
	if not stats or stats.Alive == false then
		return false
	end
	if tostring(stats.LifePath or "") == "Rogue Sorcerer" or tostring(stats.SocietyStatus or "") == "Rogue Sorcerer" then
		return false
	end
	if stats.InJujutsuHigh == true or stats.RegisteredSorcerer == true then
		return true
	end
	return (tonumber(stats.CursedEnergy) or 0) >= 200 and tostring(stats.Grade or "Non-Sorcerer") ~= "Non-Sorcerer"
end

function BK_JobService.GetJobsPayload(player)
	local stats = getStats(player)
	if not stats or stats.Alive == false then
		return { Jobs = {}, CanApply = false, Message = "No active life." }
	end

	ensureJobState(stats)
	local board = generateBoard(stats)
	return {
		Jobs = board,
		CurrentJob = stats.JobTitle or "Unemployed",
		JobLevel = stats.JobLevel or 0,
		JobExperience = stats.JobExperience or 0,
		JobYearsWorked = stats.JobYearsWorked or 0,
		JobSalary = stats.JobSalary or 0,
		ApplicationsThisYear = stats.JobApplicationsThisYear or 0,
		CanApply = (stats.JobApplicationsThisYear or 0) < 1,
		CanGoRogue = canGoRogue(stats),
		IsRogueSorcerer = tostring(stats.LifePath or "") == "Rogue Sorcerer" or tostring(stats.SocietyStatus or "") == "Rogue Sorcerer",
		RogueActions = stats.RogueActions or 0,
		RogueActionsThisYear = stats.RogueActionsThisYear or 0,
		RogueNetwork = stats.RogueNetwork or 0,
		Year = getYear(stats),
		Route = stats.RetiredFromSorcery and "Civilian Survival" or (stats.LifePath or ((stats.RegisteredSorcerer or stats.InJujutsuHigh) and "Sorcerer" or "Civilian")),
		RetiredFromSorcery = stats.RetiredFromSorcery == true,
		CivilianStability = stats.CivilianStability or 0,
		Age = tonumber(stats.Age) or 0,
	}
end

function BK_JobService.GoRogue(player)
	local stats = getStats(player)
	if not stats or stats.Alive == false then
		return false
	end

	if not canGoRogue(stats) then
		fireLifeUpdate(player, stats, "You are not in a position to go rogue yet.")
		return false
	end

	stats.InJujutsuHigh = false
	stats.RegisteredSorcerer = false
	stats.LifePath = "Rogue Sorcerer"
	stats.SocietyStatus = "Rogue Sorcerer"
	stats.Affiliation = "Rogue"
	stats.AffiliationRank = "Independent"
	stats.RogueActions = tonumber(stats.RogueActions) or 0
	stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + 1, 0, 100)
	stats.Reputation = (tonumber(stats.Reputation) or 0) - 5
	stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - 3, 0, 100)

	fireLifeUpdate(player, stats, "<font color='#b27aff'><b>[ ROGUE ROUTE ]</b></font> You cut ties with official Jujutsu society. You are now moving as a <b>Rogue Sorcerer</b>.")
	saveStats(player, "Went rogue")
	return true
end

function BK_JobService.PerformRogueAction(player, actionId)
	local stats = getStats(player)
	if not stats or stats.Alive == false then
		return
	end

	ensureJobState(stats)
	local isRogue = tostring(stats.LifePath or "") == "Rogue Sorcerer" or tostring(stats.SocietyStatus or "") == "Rogue Sorcerer"
	if not isRogue then
		fireLifeUpdate(player, stats, "You need to be on the <b>Rogue Sorcerer</b> route first.")
		return
	end

	if (tonumber(stats.RogueActionsThisYear) or 0) >= 1 then
		fireLifeUpdate(player, stats, "You already made a rogue move this year. Age up before taking another risk.")
		return
	end

	stats.RogueActionsThisYear += 1
	stats.RogueActions += 1
	local message = ""

	if actionId == "rogue_black_market" then
		local cash = math.random(1800, 4200) + math.floor((tonumber(stats.RogueNetwork) or 0) * 18)
		local networkGain = math.random(4, 9)
		stats.Money = math.max(0, (tonumber(stats.Money) or 0) + cash)
		stats.RogueNetwork = math.clamp((tonumber(stats.RogueNetwork) or 0) + networkGain, 0, 100)
		stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + math.random(0, 2), 0, 100)
		message = "<font color='#b27aff'><b>[ ROGUE ]</b></font> You moved cursed tools through a black-market contact. Money <b>+$" .. tostring(cash) .. "</b>, Rogue Network <b>+" .. tostring(networkGain) .. "</b>." .. adjustWorldReputation(stats, 0, 2, 2)
	elseif actionId == "rogue_hide_trail" then
		local wantedDrop = math.random(1, 4) + math.floor((tonumber(stats.Smarts) or 0) / 35)
		local networkGain = math.random(1, 4)
		stats.WantedLevel = math.max(0, (tonumber(stats.WantedLevel) or 0) - wantedDrop)
		stats.RogueNetwork = math.clamp((tonumber(stats.RogueNetwork) or 0) + networkGain, 0, 100)
		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - math.random(0, 2), 0, 100)
		message = "<font color='#b27aff'><b>[ ROGUE ]</b></font> You erased witnesses, records, and cursed energy traces. Wanted Level <b>-" .. tostring(wantedDrop) .. "</b>, Rogue Network <b>+" .. tostring(networkGain) .. "</b>." .. adjustWorldReputation(stats, 0, -1, 1)
	elseif actionId == "rogue_contract" then
		local ceGain = math.random(12, 28)
		local cash = math.random(900, 2600)
		local damage = math.random(3, 12)
		stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + ceGain)
		stats.Money = math.max(0, (tonumber(stats.Money) or 0) + cash)
		stats.Health = math.clamp((tonumber(stats.Health) or 100) - damage, 0, 100)
		stats.Reputation = (tonumber(stats.Reputation) or 0) - math.random(1, 4)
		stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + math.random(1, 3), 0, 100)
		message = "<font color='#b27aff'><b>[ ROGUE ]</b></font> You accepted an unofficial curse contract. CE <b>+" .. tostring(ceGain) .. "</b>, Money <b>+$" .. tostring(cash) .. "</b>, Health <b>-" .. tostring(damage) .. "</b>." .. adjustWorldReputation(stats, 1, 3, 2)
	else
		stats.RogueActionsThisYear = math.max(0, stats.RogueActionsThisYear - 1)
		stats.RogueActions = math.max(0, stats.RogueActions - 1)
		fireLifeUpdate(player, stats, "That rogue action is no longer available.")
		return
	end

	if (tonumber(stats.WantedLevel) or 0) >= 8 then
		stats.SocietyStatus = "Wanted Curse User"
		message ..= "\nJujutsu society now treats you as a <b>Wanted Curse User</b>."
	end

	fireLifeUpdate(player, stats, message)
	saveStats(player, "Rogue action")
end

function BK_JobService.AdvanceYear(player, stats)
	if not stats or stats.Alive == false then
		return ""
	end

	ensureJobState(stats)
	if not stats.JobTitle or stats.JobTitle == "" or stats.JobTitle == "Unemployed" then
		return ""
	end

	local salary = math.max(0, tonumber(stats.JobSalary) or 0)
	if salary <= 0 then
		for _, job in ipairs(JOB_POOL) do
			if job.Title == stats.JobTitle then
				salary = job.Pay
				break
			end
		end
	end

	local level = math.clamp(tonumber(stats.JobLevel) or 1, 1, 5)
	local yearlyPay = math.floor(salary * (1 + ((level - 1) * 0.18)))
	local expGain = math.random(8, 16) + getStatBonus(stats, "Smarts") + getStatBonus(stats, "Happiness")
	stats.Money = math.max(0, (tonumber(stats.Money) or 0) + yearlyPay)
	stats.JobExperience = math.max(0, (tonumber(stats.JobExperience) or 0) + expGain)
	stats.JobYearsWorked = math.max(0, (tonumber(stats.JobYearsWorked) or 0) + 1)
	stats.JobSalary = salary
	stats.LifePath = stats.RetiredFromSorcery and "Civilian" or (stats.LifePath == "Undecided" and "Civilian" or (stats.LifePath or "Civilian"))
	if stats.RetiredFromSorcery == true then
		stats.RetirementYears = math.max(0, (tonumber(stats.RetirementYears) or 0) + 1)
		stats.CivilianStability = math.clamp((tonumber(stats.CivilianStability) or 0) + math.random(2, 6), 0, 100)
		stats.WorldPressure = math.clamp((tonumber(stats.WorldPressure) or 0) - math.random(0, 2), 0, 100)
	end

	local notes = { "<font color='#78d98f'><b>[ JOB ]</b></font> You worked as a <b>" .. tostring(stats.JobTitle) .. "</b> and earned <b>$" .. tostring(yearlyPay) .. "</b>." }
	local promotionNeed = 35 + (level * 22)
	if level < 5 and stats.JobExperience >= promotionNeed then
		stats.JobExperience = math.max(0, stats.JobExperience - promotionNeed)
		stats.JobLevel = level + 1
		stats.JobSalary = math.floor(salary * 1.16)
		stats.Reputation = (tonumber(stats.Reputation) or 0) + math.random(1, 3)
		table.insert(notes, "You were promoted to career level <b>" .. tostring(stats.JobLevel) .. "</b>.")
	elseif math.random(1, 100) <= 8 then
		local stress = math.random(1, 4)
		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - stress, 0, 100)
		table.insert(notes, "The work wore you down. Happiness <b>-" .. tostring(stress) .. "</b>.")
	end

	if #stats.JobHistory > 20 then
		table.remove(stats.JobHistory, 1)
	end

	return "\n" .. table.concat(notes, " ")
end

function BK_JobService.ApplyForJob(player, jobId)
	local stats = getStats(player)
	if not stats or stats.Alive == false then
		return
	end

	ensureJobState(stats)
	local board = generateBoard(stats)
	if (stats.JobApplicationsThisYear or 0) >= 1 then
		fireLifeUpdate(player, stats, "You already applied for a job this year. Age up to refresh the job board.")
		return
	end

	local selected = nil
	for _, job in ipairs(board) do
		if job.Id == jobId then
			selected = job
			break
		end
	end

	if not selected then
		fireLifeUpdate(player, stats, "That job is no longer available.")
		return
	end

	if (tonumber(stats.Age) or 0) < (tonumber(selected.MinAge) or 0) then
		fireLifeUpdate(player, stats, "You are too young for " .. selected.Title .. ".")
		return
	end

	stats.JobApplicationsThisYear += 1
	local retirementBonus = stats.RetiredFromSorcery and math.clamp(6 + math.floor((tonumber(stats.CivilianStability) or 0) / 12), 6, 18) or 0
	local chance = math.clamp((tonumber(selected.Acceptance) or 100) + getStatBonus(stats, selected.Stat) + retirementBonus, 5, 100)
	local accepted = math.random(1, 100) <= chance

	if accepted then
		stats.JobTitle = selected.Title
		stats.JobSalary = tonumber(selected.Pay) or 0
		stats.JobLevel = math.max(1, tonumber(stats.JobLevel) or 0)
		stats.JobYearsWorked = 0
		stats.LifePath = stats.RetiredFromSorcery and "Civilian" or (stats.LifePath or "Civilian")
		if stats.RetiredFromSorcery == true then
			stats.CivilianStability = math.clamp((tonumber(stats.CivilianStability) or 0) + math.random(1, 4), 0, 100)
		end
		stats.Money = math.max(0, tonumber(stats.Money) or 0) + (tonumber(selected.Pay) or 0)
		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) + math.random(1, 4), 0, 100)
		table.insert(stats.JobHistory, {
			Year = getYear(stats),
			Title = selected.Title,
			Accepted = true,
			Pay = selected.Pay,
		})
		fireLifeUpdate(player, stats, "You were accepted as a <b>" .. selected.Title .. "</b> and earned $" .. tostring(selected.Pay) .. ".")
	else
		stats.Happiness = math.clamp((tonumber(stats.Happiness) or 100) - 2, 0, 100)
		table.insert(stats.JobHistory, {
			Year = getYear(stats),
			Title = selected.Title,
			Accepted = false,
		})
		fireLifeUpdate(player, stats, "You applied for <b>" .. selected.Title .. "</b>, but they rejected your application.")
	end

	saveStats(player, "Job application")
end

function BK_JobService.Init(ctx)
	context = ctx or {}
	if context.IS_DEBUG then print("[BK_JobService] Civilian jobs loaded.") end
end

return BK_JobService
