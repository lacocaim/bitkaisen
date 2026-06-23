-- ModuleScript: CurseUserService
-- Location: ServerStorage > BitKaisenModules > CurseUserService
-- Purpose:
--   Server-only Curse User route data and helpers.
--   Keeps Curse User mission definitions, morality, alignment, and mission board generation out of GameManager.

local CurseUserService = {}

CurseUserService.Missions = {
	{
		Id = "curse_user_information_broker",
		Title = "Sell Information",
		Grade = "Curse User Grade 4",
		Difficulty = 28,
		RewardCE = 8,
		RewardMoney = 450,
		RewardRep = -3,
		DmgPenalty = 8,
		Body = "A shady broker wants information about a minor cursed object route.",
		Choices = {
			{ Text = "Sell the information", Description = "You sold the information and kept your name out of it.", Effects = { Money = 550, Reputation = -3, CursedEnergy = 2, CurseUserProgress = 8 }, Morality = -4 },
			{ Text = "Sell fake information", Description = "You sold fake information and left the broker chasing ghosts.", Effects = { Money = 300, Smarts = 3, Reputation = -1, CurseUserProgress = 5 }, Morality = -1 },
			{ Text = "Refuse the job", Description = "You refused the job. Even curse users can have lines.", Effects = { Happiness = 1, Reputation = 1 }, Morality = 2 },
		}
	},
	{
		Id = "curse_user_hidden_cache",
		Title = "Hidden Cache",
		Grade = "Curse User Grade 4",
		Difficulty = 32,
		RewardCE = 10,
		RewardMoney = 350,
		RewardRep = -2,
		DmgPenalty = 10,
		Body = "You hear about a hidden cache of minor cursed objects nobody is guarding.",
		Choices = {
			{ Text = "Take everything", Description = "You took the cache before anyone else could reach it.", Effects = { Money = 700, CursedEnergy = 4, Reputation = -4, CurseUserProgress = 10 }, Morality = -5 },
			{ Text = "Take one object", Description = "You only took one object and left the rest alone.", Effects = { Money = 250, CursedEnergy = 3, Reputation = -1, CurseUserProgress = 6 }, Morality = -1 },
			{ Text = "Destroy the cache", Description = "You destroyed the cache so nobody could use it.", Effects = { Reputation = 2, Happiness = 2, CursedEnergy = -2 }, Morality = 3 },
		}
	},
	{
		Id = "curse_user_intimidation",
		Title = "Intimidation Job",
		Grade = "Curse User Grade 3",
		Difficulty = 45,
		RewardCE = 14,
		RewardMoney = 800,
		RewardRep = -5,
		DmgPenalty = 14,
		Body = "Someone offers payment if you scare off a rival contact without involving officials.",
		Choices = {
			{ Text = "Intimidate them", Description = "You made the warning clear enough that they will remember it.", Effects = { Money = 850, Reputation = -5, CurseUserProgress = 12 }, Morality = -6 },
			{ Text = "Warn them quietly", Description = "You gave a quiet warning instead of making a spectacle.", Effects = { Money = 450, Smarts = 3, Reputation = -2, CurseUserProgress = 8 }, Morality = -2 },
			{ Text = "Expose the client", Description = "You exposed the person who hired you and ruined their plan.", Effects = { Reputation = 3, Happiness = 2, Money = -100 }, Morality = 4 },
		}
	},
	{
		Id = "curse_user_cursed_tool_theft",
		Title = "Cursed Tool Theft",
		Grade = "Curse User Grade 3",
		Difficulty = 55,
		RewardCE = 18,
		RewardMoney = 1200,
		RewardRep = -6,
		DmgPenalty = 18,
		Body = "A low-security storage room contains a cursed tool that could sell for a lot.",
		Choices = {
			{ Text = "Steal it", Description = "You stole the cursed tool and disappeared before the alarm spread.", Effects = { Money = 1400, Reputation = -7, CursedEnergy = 4, CurseUserProgress = 14 }, Morality = -8 },
			{ Text = "Copy the records", Description = "You copied the storage records instead. Less profit, less heat.", Effects = { Money = 500, Smarts = 5, Reputation = -2, CurseUserProgress = 8 }, Morality = -2 },
			{ Text = "Tip off Jujutsu High", Description = "You anonymously warned Jujutsu High about the weak storage.", Effects = { Reputation = 2, Happiness = 1 }, Morality = 4 },
		}
	},
	{
		Id = "curse_user_grudge_request",
		Title = "Grudge Request",
		Grade = "Curse User Grade 2",
		Difficulty = 70,
		RewardCE = 24,
		RewardMoney = 1800,
		RewardRep = -9,
		DmgPenalty = 22,
		Body = "A client wants you to ruin someone's career through cursed energy pressure and rumors.",
		Choices = {
			{ Text = "Take the request", Description = "You accepted the request and left the target's reputation damaged.", Effects = { Money = 1900, Reputation = -10, CurseUserProgress = 18, Happiness = -2 }, Morality = -10 },
			{ Text = "Scam the client", Description = "You took partial payment and gave the client nothing useful.", Effects = { Money = 800, Smarts = 4, Reputation = -4, CurseUserProgress = 10 }, Morality = -3 },
			{ Text = "Warn the target", Description = "You warned the target and earned a little respect from yourself.", Effects = { Reputation = 4, Happiness = 3, Money = -150 }, Morality = 5 },
		}
	},
	{
		Id = "curse_user_underworld_duel",
		Title = "Underworld Duel",
		Grade = "Curse User Grade 2",
		Difficulty = 82,
		RewardCE = 30,
		RewardMoney = 2200,
		RewardRep = -7,
		DmgPenalty = 28,
		Body = "Another curse user challenges you for status in the underground.",
		Choices = {
			{ Text = "Accept the duel", Description = "You accepted and proved your strength where officials were not watching.", Effects = { Money = 1200, CursedEnergy = 8, Reputation = -6, Health = -8, CurseUserProgress = 20 }, Morality = -4 },
			{ Text = "Set a trap", Description = "You won before the duel really started. Dirty, but effective.", Effects = { Money = 1600, Smarts = 5, Reputation = -9, CurseUserProgress = 22 }, Morality = -8 },
			{ Text = "Refuse publicly", Description = "You refused and called the duel pointless. Some mocked you, others respected the control.", Effects = { Reputation = 1, Smarts = 4, Happiness = 1 }, Morality = 2 },
		}
	},
	{
		Id = "curse_user_special_contract",
		Title = "Special Contract",
		Grade = "Curse User Grade 1",
		Difficulty = 105,
		RewardCE = 40,
		RewardMoney = 3500,
		RewardRep = -14,
		DmgPenalty = 34,
		Body = "A dangerous client offers a serious contract. The payment is huge, but the request is ugly.",
		Choices = {
			{ Text = "Accept the contract", Description = "You accepted the contract and crossed a line people do not forget.", Effects = { Money = 4000, Reputation = -15, CursedEnergy = 8, Happiness = -6, CurseUserProgress = 28 }, Morality = -14 },
			{ Text = "Negotiate limits", Description = "You negotiated strict limits and took a cleaner version of the job.", Effects = { Money = 1800, Reputation = -5, Smarts = 5, CurseUserProgress = 14 }, Morality = -3 },
			{ Text = "Leak the contract", Description = "You leaked the contract details and caused chaos for the client.", Effects = { Reputation = 5, Happiness = 2, Money = -300 }, Morality = 6 },
		}
	},
}

for _, mission in ipairs(CurseUserService.Missions) do
	local rep = tonumber(mission.RewardRep) or 0
	local repText = "Rep +" .. tostring(rep)

	if rep < 0 then
		repText = "Rep " .. tostring(rep)
	end

	mission.RewardText = mission.RewardText or (
		"Choice rewards • $" ..
			tostring(mission.RewardMoney or 0) ..
			" • CE +" ..
			tostring(mission.RewardCE or 0) ..
			" • " ..
			repText ..
			" • Underground Progress"
	)
end

function CurseUserService.IsCurseUser(stats)
	if not stats then
		return false
	end

	return stats.IsCurseUser == true
		or stats.CurseUser == true
		or stats.Path == "Curse User"
		or stats.SorcererPath == "Curse User"
		or stats.Alignment == "Curse User"
		or string.sub(tostring(stats.Grade or ""), 1, 11) == "Curse User"
end

function CurseUserService.GetMoralAlignment(stats)
	local reputation = tonumber(stats and stats.Reputation) or 0
	local morality = tonumber(stats and stats.Morality) or 0
	local score = reputation + morality

	if score <= -75 then
		return "Infamous Evil"
	elseif score <= -35 then
		return "Evil"
	elseif score <= -10 then
		return "Shady"
	elseif score < 20 then
		return "Neutral"
	elseif score < 60 then
		return "Respected"
	end

	return "Honored"
end

function CurseUserService.ApplyMorality(stats, amount)
	if not stats then
		return
	end

	stats.Morality = math.clamp((tonumber(stats.Morality) or 0) + (tonumber(amount) or 0), -100, 100)
	stats.Alignment = CurseUserService.GetMoralAlignment(stats)
end

function CurseUserService.GetMissionById(missionId)
	for _, mission in ipairs(CurseUserService.Missions) do
		if mission.Id == missionId then
			return mission
		end
	end

	return nil
end

function CurseUserService.CanAttemptMission(stats, mission, getGradeValue)
	if not stats or not mission then
		return false
	end

	if not CurseUserService.IsCurseUser(stats) then
		return false
	end

	if typeof(getGradeValue) ~= "function" then
		return true
	end

	return getGradeValue(stats.Grade) >= getGradeValue(mission.Grade)
end

function CurseUserService.GenerateMissionBoard(stats, getGradeValue)
	local board = {}

	if not CurseUserService.IsCurseUser(stats) then
		return board
	end

	for _, mission in ipairs(CurseUserService.Missions) do
		if CurseUserService.CanAttemptMission(stats, mission, getGradeValue) then
			table.insert(board, mission)
		end
	end

	while #board > 4 do
		table.remove(board, math.random(1, #board))
	end

	return board
end

return CurseUserService
