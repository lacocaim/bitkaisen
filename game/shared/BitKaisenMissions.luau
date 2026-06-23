-- ModuleScript: BitKaisenMissions
-- Location: ReplicatedStorage
-- Content Update:
--   Expanded mission board across every grade.
--   Keeps the same API:
--     GetMissionById(id)
--     CanAttemptMission(playerGrade, missionGrade)
--     GenerateMissionBoard(playerGrade)

local BitKaisenMissions = {}


BitKaisenMissions.HeianDatabase = {
	{
		Id = "heian_forest_curse",
		Title = "Forest Shrine Curse",
		Grade = "Heian Trial",
		Era = "Heian Era",
		RiskColor = Color3.fromRGB(190, 150, 80),
		Difficulty = 38,
		RequiredPower = 0,
		RewardCE = 18,
		RewardMoney = 90,
		RewardRep = 5,
		DmgPenalty = 22,
		OrphanRescueChance = 4
	},
	{
		Id = "heian_roadside_ambush",
		Title = "Roadside Curse Ambush",
		Grade = "Heian Trial",
		Era = "Heian Era",
		RiskColor = Color3.fromRGB(190, 150, 80),
		Difficulty = 48,
		RequiredPower = 20,
		RewardCE = 24,
		RewardMoney = 120,
		RewardRep = 7,
		DmgPenalty = 28,
		OrphanRescueChance = 3
	},
	{
		Id = "heian_temple_exorcism",
		Title = "Temple Exorcism Request",
		Grade = "Heian Trial",
		Era = "Heian Era",
		RiskColor = Color3.fromRGB(210, 165, 90),
		Difficulty = 62,
		RequiredPower = 45,
		RewardCE = 32,
		RewardMoney = 170,
		RewardRep = 10,
		DmgPenalty = 34,
		OrphanRescueChance = 5
	},
	{
		Id = "heian_noble_estate",
		Title = "Noble Estate Possession",
		Grade = "Heian Rite",
		Era = "Heian Era",
		RiskColor = Color3.fromRGB(220, 120, 90),
		Difficulty = 84,
		RequiredPower = 75,
		RewardCE = 45,
		RewardMoney = 260,
		RewardRep = 15,
		DmgPenalty = 45,
		OrphanRescueChance = 4
	},
	{
		Id = "heian_cursed_tool_theft",
		Title = "Cursed Tool Theft",
		Grade = "Heian Rite",
		Era = "Heian Era",
		RiskColor = Color3.fromRGB(220, 120, 90),
		Difficulty = 102,
		RequiredPower = 105,
		RewardCE = 56,
		RewardMoney = 350,
		RewardRep = 18,
		DmgPenalty = 55,
		OrphanRescueChance = 2
	},
	{
		Id = "heian_onmyoji_duel",
		Title = "Onmyoji Duel Challenge",
		Grade = "Heian Rite",
		Era = "Heian Era",
		RiskColor = Color3.fromRGB(230, 100, 130),
		Difficulty = 128,
		RequiredPower = 140,
		RewardCE = 70,
		RewardMoney = 480,
		RewardRep = 26,
		DmgPenalty = 70,
		OrphanRescueChance = 2
	},
	{
		Id = "heian_clan_border_war",
		Title = "Clan Border Curse War",
		Grade = "Heian War",
		Era = "Heian Era",
		RiskColor = Color3.fromRGB(180, 95, 255),
		Difficulty = 165,
		RequiredPower = 190,
		RewardCE = 92,
		RewardMoney = 700,
		RewardRep = 38,
		DmgPenalty = 88,
		OrphanRescueChance = 3
	},
	{
		Id = "heian_village_massacre",
		Title = "Village Massacre Investigation",
		Grade = "Heian War",
		Era = "Heian Era",
		RiskColor = Color3.fromRGB(180, 95, 255),
		Difficulty = 190,
		RequiredPower = 235,
		RewardCE = 110,
		RewardMoney = 900,
		RewardRep = 48,
		DmgPenalty = 105,
		OrphanRescueChance = 8
	},
	{
		Id = "heian_court_calamity",
		Title = "Imperial Court Calamity",
		Grade = "Heian Calamity",
		Era = "Heian Era",
		RiskColor = Color3.fromRGB(255, 85, 110),
		Difficulty = 245,
		RequiredPower = 300,
		RewardCE = 145,
		RewardMoney = 1300,
		RewardRep = 72,
		DmgPenalty = 130,
		OrphanRescueChance = 2
	},
	{
		Id = "heian_named_curse_hunt",
		Title = "Named Curse Hunt",
		Grade = "Heian Calamity",
		Era = "Heian Era",
		RiskColor = Color3.fromRGB(255, 65, 95),
		Difficulty = 305,
		RequiredPower = 380,
		RewardCE = 185,
		RewardMoney = 1900,
		RewardRep = 95,
		DmgPenalty = 155,
		OrphanRescueChance = 2
	}
}

local function getHeianPowerTier(stats)
	local cursedEnergy = tonumber(stats and stats.CursedEnergy) or 0
	local mastery = tonumber(stats and stats.TechniqueMastery) or 0
	local smarts = tonumber(stats and stats.Smarts) or 0
	local reputation = tonumber(stats and stats.Reputation) or 0

	return cursedEnergy + (mastery * 3) + math.floor(smarts * 0.5) + math.max(0, reputation)
end



BitKaisenMissions.Database = {
	-- Grade 4
	{ Id = "graveyard_grade4", Title = "Investigate Local Graveyard", Grade = "Grade 4", RiskColor = Color3.fromRGB(150, 150, 150), Difficulty = 20, RewardCE = 8, RewardMoney = 50, RewardRep = 2, DmgPenalty = 12, OrphanRescueChance = 3 },
	{ Id = "hospital_grade4", Title = "Abandoned Hospital Sounds", Grade = "Grade 4", RiskColor = Color3.fromRGB(150, 150, 150), Difficulty = 28, RewardCE = 12, RewardMoney = 70, RewardRep = 3, DmgPenalty = 18, OrphanRescueChance = 5 },
	{ Id = "school_curse_grade4", Title = "School Curse Report", Grade = "Grade 4", RiskColor = Color3.fromRGB(150, 150, 150), Difficulty = 32, RewardCE = 14, RewardMoney = 80, RewardRep = 4, DmgPenalty = 20, OrphanRescueChance = 2 },
	{ Id = "convenience_store_grade4", Title = "Convenience Store Haunting", Grade = "Grade 4", RiskColor = Color3.fromRGB(150, 150, 150), Difficulty = 24, RewardCE = 10, RewardMoney = 65, RewardRep = 3, DmgPenalty = 14, OrphanRescueChance = 2 },
	{ Id = "apartment_noise_grade4", Title = "Apartment Wall Scratching", Grade = "Grade 4", RiskColor = Color3.fromRGB(150, 150, 150), Difficulty = 30, RewardCE = 13, RewardMoney = 90, RewardRep = 4, DmgPenalty = 18, OrphanRescueChance = 4 },
	{ Id = "train_platform_grade4", Title = "Last Train Platform Curse", Grade = "Grade 4", RiskColor = Color3.fromRGB(150, 150, 150), Difficulty = 36, RewardCE = 16, RewardMoney = 100, RewardRep = 5, DmgPenalty = 22, OrphanRescueChance = 3 },

	-- Semi-Grade 3
	{ Id = "morgue_sg3", Title = "Morgue Curse Outbreak", Grade = "Semi-Grade 3", RiskColor = Color3.fromRGB(180, 140, 70), Difficulty = 48, RewardCE = 18, RewardMoney = 120, RewardRep = 5, DmgPenalty = 26, OrphanRescueChance = 3 },
	{ Id = "tunnel_sg3", Title = "Service Tunnel Howling", Grade = "Semi-Grade 3", RiskColor = Color3.fromRGB(180, 140, 70), Difficulty = 54, RewardCE = 20, RewardMoney = 145, RewardRep = 6, DmgPenalty = 28, OrphanRescueChance = 4 },
	{ Id = "shrine_sg3", Title = "Forgotten Shrine Distortion", Grade = "Semi-Grade 3", RiskColor = Color3.fromRGB(180, 140, 70), Difficulty = 60, RewardCE = 23, RewardMoney = 160, RewardRep = 7, DmgPenalty = 32, OrphanRescueChance = 5 },

	-- Grade 3
	{ Id = "rogue_sorcerer_grade3", Title = "Rogue Sorcerer Sighting", Grade = "Grade 3", RiskColor = Color3.fromRGB(200, 150, 50), Difficulty = 68, RewardCE = 28, RewardMoney = 200, RewardRep = 10, DmgPenalty = 38, OrphanRescueChance = 7 },
	{ Id = "bridge_grade3", Title = "Bridge Curse Manifestation", Grade = "Grade 3", RiskColor = Color3.fromRGB(200, 150, 50), Difficulty = 75, RewardCE = 35, RewardMoney = 240, RewardRep = 12, DmgPenalty = 42, OrphanRescueChance = 8 },
	{ Id = "movie_theater_grade3", Title = "Closed Theater Curse", Grade = "Grade 3", RiskColor = Color3.fromRGB(200, 150, 50), Difficulty = 82, RewardCE = 38, RewardMoney = 265, RewardRep = 13, DmgPenalty = 44, OrphanRescueChance = 6 },
	{ Id = "riverbank_grade3", Title = "Riverbank Missing Persons", Grade = "Grade 3", RiskColor = Color3.fromRGB(200, 150, 50), Difficulty = 88, RewardCE = 40, RewardMoney = 290, RewardRep = 14, DmgPenalty = 46, OrphanRescueChance = 9 },

	-- Semi-Grade 2
	{ Id = "cursed_womb_sg2", Title = "Cursed Womb Trace", Grade = "Semi-Grade 2", RiskColor = Color3.fromRGB(220, 100, 80), Difficulty = 95, RewardCE = 45, RewardMoney = 320, RewardRep = 16, DmgPenalty = 55, OrphanRescueChance = 6 },
	{ Id = "factory_sg2", Title = "Factory Residual Curse", Grade = "Semi-Grade 2", RiskColor = Color3.fromRGB(220, 100, 80), Difficulty = 108, RewardCE = 52, RewardMoney = 380, RewardRep = 18, DmgPenalty = 60, OrphanRescueChance = 5 },
	{ Id = "curse_user_sg2", Title = "Low-Rank Curse User Hunt", Grade = "Semi-Grade 2", RiskColor = Color3.fromRGB(220, 100, 80), Difficulty = 118, RewardCE = 58, RewardMoney = 430, RewardRep = 20, DmgPenalty = 66, OrphanRescueChance = 4 },

	-- Grade 2
	{ Id = "subway_grade2", Title = "Subway Domain Residue", Grade = "Grade 2", RiskColor = Color3.fromRGB(220, 80, 80), Difficulty = 130, RewardCE = 65, RewardMoney = 500, RewardRep = 24, DmgPenalty = 75, OrphanRescueChance = 5 },
	{ Id = "mall_grade2", Title = "Shopping Mall Curse Nest", Grade = "Grade 2", RiskColor = Color3.fromRGB(220, 80, 80), Difficulty = 142, RewardCE = 70, RewardMoney = 560, RewardRep = 26, DmgPenalty = 78, OrphanRescueChance = 7 },
	{ Id = "barrier_break_grade2", Title = "Collapsed Barrier Incident", Grade = "Grade 2", RiskColor = Color3.fromRGB(220, 80, 80), Difficulty = 155, RewardCE = 74, RewardMoney = 620, RewardRep = 28, DmgPenalty = 82, OrphanRescueChance = 4 },

	-- Semi-Grade 1
	{ Id = "estate_sg1", Title = "Abandoned Estate Barrier", Grade = "Semi-Grade 1", RiskColor = Color3.fromRGB(190, 90, 255), Difficulty = 175, RewardCE = 82, RewardMoney = 750, RewardRep = 35, DmgPenalty = 85, OrphanRescueChance = 4 },
	{ Id = "curse_market_sg1", Title = "Illegal Cursed Tool Market", Grade = "Semi-Grade 1", RiskColor = Color3.fromRGB(190, 90, 255), Difficulty = 188, RewardCE = 88, RewardMoney = 850, RewardRep = 38, DmgPenalty = 90, OrphanRescueChance = 3 },
	{ Id = "old_clan_house_sg1", Title = "Old Clan House Suppression", Grade = "Semi-Grade 1", RiskColor = Color3.fromRGB(190, 90, 255), Difficulty = 198, RewardCE = 94, RewardMoney = 925, RewardRep = 42, DmgPenalty = 94, OrphanRescueChance = 5 },

	-- Grade 1
	{ Id = "special_grade_trace", Title = "Special Grade Curse Trace", Grade = "Grade 1", RiskColor = Color3.fromRGB(170, 90, 255), Difficulty = 210, RewardCE = 100, RewardMoney = 1000, RewardRep = 50, DmgPenalty = 95, OrphanRescueChance = 3 },
	{ Id = "urban_domain_grade1", Title = "Urban Domain Breach", Grade = "Grade 1", RiskColor = Color3.fromRGB(170, 90, 255), Difficulty = 235, RewardCE = 115, RewardMoney = 1250, RewardRep = 58, DmgPenalty = 105, OrphanRescueChance = 4 },
	{ Id = "vessel_intercept_grade1", Title = "Cursed Vessel Intercept", Grade = "Grade 1", RiskColor = Color3.fromRGB(170, 90, 255), Difficulty = 255, RewardCE = 128, RewardMoney = 1450, RewardRep = 64, DmgPenalty = 112, OrphanRescueChance = 2 },

	-- Special Grade 1
	{ Id = "disaster_seed_sg1", Title = "Disaster Curse Seed", Grade = "Special Grade 1", RiskColor = Color3.fromRGB(255, 120, 70), Difficulty = 285, RewardCE = 145, RewardMoney = 1800, RewardRep = 78, DmgPenalty = 125, OrphanRescueChance = 3 },
	{ Id = "domain_collapse_sg1", Title = "Unstable Domain Collapse", Grade = "Special Grade 1", RiskColor = Color3.fromRGB(255, 120, 70), Difficulty = 315, RewardCE = 165, RewardMoney = 2200, RewardRep = 90, DmgPenalty = 140, OrphanRescueChance = 2 },

	-- Special Grade
	{ Id = "special_grade_suppression", Title = "Special Grade Suppression Order", Grade = "Special Grade", RiskColor = Color3.fromRGB(255, 65, 95), Difficulty = 365, RewardCE = 210, RewardMoney = 3200, RewardRep = 120, DmgPenalty = 165, OrphanRescueChance = 1 },
	{ Id = "citywide_curse_event", Title = "Citywide Curse Event", Grade = "Special Grade", RiskColor = Color3.fromRGB(255, 65, 95), Difficulty = 420, RewardCE = 260, RewardMoney = 4500, RewardRep = 155, DmgPenalty = 190, OrphanRescueChance = 3 }
}

local gradeOrder = {
	["Non-Sorcerer"] = 0,
	["Grade 4"] = 1,
	["Semi-Grade 3"] = 2,
	["Grade 3"] = 3,
	["Semi-Grade 2"] = 4,
	["Grade 2"] = 5,
	["Semi-Grade 1"] = 6,
	["Grade 1"] = 7,
	["Special Grade 1"] = 8,
	["Special Grade"] = 9
}

function BitKaisenMissions.GetMissionById(id)
	for _, mission in ipairs(BitKaisenMissions.Database) do
		if mission.Id == id then
			return mission
		end
	end

	for _, mission in ipairs(BitKaisenMissions.HeianDatabase) do
		if mission.Id == id then
			return mission
		end
	end

	return nil
end

function BitKaisenMissions.CanAttemptMission(playerGrade, missionGrade)
	local playerRank = gradeOrder[playerGrade] or 0
	local missionRank = gradeOrder[missionGrade] or 999

	if playerRank <= 0 then
		return false
	end

	return missionRank <= playerRank + 1
end

function BitKaisenMissions.GenerateMissionBoard(playerGrade)
	local board = {}

	if playerGrade == "Non-Sorcerer" then
		return board
	end

	local validMissions = {}

	for _, mission in ipairs(BitKaisenMissions.Database) do
		if BitKaisenMissions.CanAttemptMission(playerGrade, mission.Grade) then
			table.insert(validMissions, mission)
		end
	end

	local used = {}

	while #board < 3 and #board < #validMissions do
		local index = math.random(1, #validMissions)
		local mission = validMissions[index]

		if not used[mission.Id] then
			used[mission.Id] = true
			table.insert(board, mission)
		end
	end

	return board
end


function BitKaisenMissions.IsHeianMission(mission)
	return typeof(mission) == "table" and mission.Era == "Heian Era"
end

function BitKaisenMissions.CanAttemptHeianMission(stats, mission)
	if not BitKaisenMissions.IsHeianMission(mission) then
		return false
	end

	local age = tonumber(stats and stats.Age) or 0
	if age < 10 then
		return false
	end

	local power = getHeianPowerTier(stats)
	local requiredPower = tonumber(mission.RequiredPower) or 0

	return power >= requiredPower
end

function BitKaisenMissions.GenerateHeianMissionBoard(stats)
	local board = {}

	local age = tonumber(stats and stats.Age) or 0
	if age < 10 then
		return board
	end

	local validMissions = {}

	for _, mission in ipairs(BitKaisenMissions.HeianDatabase) do
		if BitKaisenMissions.CanAttemptHeianMission(stats, mission) then
			table.insert(validMissions, mission)
		end
	end

	local used = {}

	while #board < 3 and #board < #validMissions do
		local index = math.random(1, #validMissions)
		local mission = validMissions[index]

		if not used[mission.Id] then
			used[mission.Id] = true
			table.insert(board, mission)
		end
	end

	return board
end


return BitKaisenMissions
