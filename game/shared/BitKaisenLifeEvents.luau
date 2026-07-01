-- ModuleScript: BitKaisenLifeEvents
-- Location: ReplicatedStorage

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BitKaisenCursedTools = require(ReplicatedStorage:WaitForChild("BitKaisenCursedTools"))

local BitKaisenLifeEvents = {}

BitKaisenLifeEvents.Database = {
	{
		Id = "child_curse_corner",
		MinAge = 3,
		MaxAge = 10,
		Weight = 8,
		Texts = {
			"You noticed something standing in the corner of your room. When you blinked, it was gone.",
			"You woke up and felt something watching you from the dark corner of your room.",
			"At night, you kept seeing a shape near your wall that nobody else could see."
		},
		Effects = { Happiness = -4, CursedEnergy = 2 }
	},

	{
		Id = "child_school_incident",
		MinAge = 6,
		MaxAge = 12,
		Weight = 10,
		Texts = {
			"A strange accident happened at school. You were the only one who saw the curse behind it.",
			"During class, something crawled across the ceiling. Nobody else reacted.",
			"A student got hurt during a strange accident, and you felt cursed energy in the room."
		},
		Effects = { Happiness = -5, Smarts = 2, CursedEnergy = 2 }
	},

	{
		Id = "child_bad_dreams",
		MinAge = 4,
		MaxAge = 12,
		Weight = 8,
		Texts = {
			"You kept dreaming about a place covered in cursed energy.",
			"Your dreams were filled with distorted faces and voices calling your name.",
			"You woke up from the same cursed dream multiple times this year."
		},
		Effects = { Happiness = -3, Smarts = 1, CursedEnergy = 1 }
	},

	{
		Id = "child_family_pressure",
		MinAge = 6,
		MaxAge = 14,
		Weight = 12,
		RequiredFamilyType = "Sorcerer",
		Texts = {
			"Your family forced you through basic cursed energy training.",
			"Your family began teaching you how to sense cursed energy.",
			"Your family tested your cursed energy control, even though you were still young."
		},
		Effects = { CursedEnergy = 6, Health = -3, Happiness = -2 }
	},

	{
		Id = "fallen_family_memory",
		MinAge = 6,
		MaxAge = 18,
		Weight = 11,
		RequiredFamilyType = "Fallen",
		Texts = {
			"Your family spoke about the status they lost in the jujutsu world.",
			"You heard old stories about how your family fell out of favor.",
			"An older relative warned you not to repeat your family's past mistakes."
		},
		Effects = { Smarts = 3, CursedEnergy = 3, Happiness = -2 }
	},

	{
		Id = "unknown_family_record",
		MinAge = 8,
		MaxAge = 25,
		Weight = 11,
		RequiredFamilyType = "Unknown",
		Texts = {
			"You found an old family record with most of the names scratched out.",
			"You discovered a damaged document tied to your family name.",
			"You found proof that your family had been erased from certain records."
		},
		Effects = { Smarts = 4, CursedEnergy = 3, Happiness = -2 }
	},

	{
		Id = "womb_presence",
		MinAge = 1,
		MaxAge = 20,
		Weight = 12,
		RequiredOrigin = "Cursed Womb",
		Texts = {
			"People around you seemed uncomfortable, even when you did nothing.",
			"Adults lowered their voices when they spoke about you.",
			"Your presence made people uneasy in ways they could not explain."
		},
		Effects = { Happiness = -5, CursedEnergy = 5 }
	},

	{
		Id = "clan_private_training",
		MinAge = 6,
		MaxAge = 18,
		Weight = 12,
		RequiredOriginCategory = "Clan",
		Texts = {
			"Your clan arranged private cursed energy training for you.",
			"A clan instructor tested your cursed energy control.",
			"Your family name brought attention from clan instructors."
		},
		Effects = { CursedEnergy = 8, Smarts = 2, Health = -2 }
	},

	{
		Id = "technique_control",
		MinAge = 8,
		MaxAge = 35,
		Weight = 10,
		RequiresTechnique = true,
		Texts = {
			"You started understanding the shape and limits of your cursed technique.",
			"Your cursed technique felt easier to control this year.",
			"You practiced your technique enough to understand one of its weaknesses."
		},
		Effects = { CursedEnergy = 6, Smarts = 3 }
	},

	{
		Id = "technique_backlash",
		MinAge = 10,
		MaxAge = 45,
		Weight = 6,
		RequiresTechnique = true,
		Texts = {
			"You pushed your cursed technique too hard and suffered backlash.",
			"Your technique misfired during training and left your body sore.",
			"You overused your cursed technique and spent days recovering."
		},
		Effects = { Health = -8, CursedEnergy = 4 }
	},

	{
		Id = "teen_curse_sighting",
		MinAge = 13,
		MaxAge = 19,
		Weight = 10,
		Texts = {
			"You saw a curse watching you from an alley after school.",
			"Something followed you home, staying just outside your sight.",
			"You felt cursed energy trailing behind you for most of the day."
		},
		Effects = { Happiness = -4, CursedEnergy = 3 }
	},

	{
		Id = "high_sparring",
		MinAge = 13,
		MaxAge = 22,
		Weight = 12,
		RequiresJujutsuHigh = true,
		Texts = {
			"You sparred with another Jujutsu High student and learned from the fight.",
			"A classmate pushed you hard during sparring, forcing you to adapt.",
			"You left a training match bruised, but more confident in your cursed energy."
		},
		Effects = { CursedEnergy = 6, Reputation = 4, Health = -3 }
	},

	{
		Id = "high_teacher_lesson",
		MinAge = 13,
		MaxAge = 22,
		Weight = 10,
		RequiresJujutsuHigh = true,
		Texts = {
			"A teacher gave you a harsh but useful lesson about surviving as a sorcerer.",
			"One of your teachers corrected your cursed energy control in front of the class.",
			"A teacher noticed your habits in combat and gave you advice that stuck."
		},
		Effects = { Smarts = 4, CursedEnergy = 4, Happiness = -2 }
	},

	{
		Id = "teacher_recommendation_hint",
		MinAge = 13,
		MaxAge = 30,
		Weight = 7,
		RequiresJujutsuHigh = true,
		Texts = {
			"A teacher started paying closer attention to your progress.",
			"Your performance made one of your teachers consider recommending you.",
			"One of your instructors told you that your growth was becoming hard to ignore."
		},
		Effects = { Reputation = 3, Smarts = 2 }
	},

	{
		Id = "adult_curse_case",
		MinAge = 20,
		MaxAge = 59,
		Weight = 8,
		Texts = {
			"You heard about a curse-related incident nearby and quietly investigated it.",
			"You sensed cursed energy around a local incident and looked into it.",
			"A strange case caught your attention, and you followed the cursed energy trail."
		},
		Effects = { CursedEnergy = 5, Reputation = 2, Health = -2 }
	},

	{
		Id = "adult_burnout",
		MinAge = 20,
		MaxAge = 59,
		Weight = 7,
		Texts = {
			"The pressure of dealing with cursed energy started wearing you down.",
			"You felt exhausted from constantly sensing curses around you.",
			"The jujutsu world started feeling heavier than you expected."
		},
		Effects = { Happiness = -6, Health = -3 }
	},

	{
		Id = "rare_cursed_object",
		MinAge = 10,
		MaxAge = 60,
		Weight = 2,
		Texts = {
			"You found a small cursed object hidden where nobody should have left it.",
			"You discovered a sealed charm that leaked cursed energy.",
			"You found an old object that reacted the moment you touched it."
		},
		Effects = { CursedEnergy = 12, Smarts = 3, Happiness = -4 }
	},

	{
		Id = "rare_near_death_spark",
		MinAge = 8,
		MaxAge = 45,
		Weight = 2,
		Texts = {
			"A curse nearly killed you, but the fear forced your cursed energy to surge.",
			"You barely survived a curse encounter that changed how your energy moved.",
			"You came dangerously close to death, and your cursed energy reacted violently."
		},
		Effects = { Health = -18, CursedEnergy = 18, Happiness = -8 }
	},

	{
		Id = "rare_black_spark",
		MinAge = 15,
		MaxAge = 50,
		Weight = 1,
		RequiresTechnique = true,
		Texts = {
			"For one instant, your cursed energy aligned perfectly with your movement. You felt a black spark.",
			"Your cursed energy and physical strike connected in a way you could barely understand.",
			"A flash of cursed energy erupted from your movement for less than a second."
		},
		Effects = { CursedEnergy = 25, Reputation = 10, Health = -5 }
	}
	,
	{
		Id = "curse_user_black_market_tip",
		Category = "CurseUser",
		MinAge = 16,
		MaxAge = 100,
		Weight = 10,
		RequiresCurseUser = true,
		Texts = {
			"A black market broker passed you a curse job before Jujutsu Society could intercept it.",
			"Someone from the underground curse world recognized your name and offered information for a price.",
			"A forbidden contact reached out, treating you like someone useful instead of someone to control."
		},
		Effects = { Money = 220, CursedEnergy = 4, Reputation = -3, WantedLevel = 1, CursedResentment = 4 }
	},

	{
		Id = "curse_user_society_warning",
		Category = "CurseUser",
		MinAge = 16,
		MaxAge = 100,
		Weight = 8,
		RequiresCurseUser = true,
		Texts = {
			"A Jujutsu Society notice started circulating with details that sounded too close to you.",
			"You heard that scouts were asking about an unregistered sorcerer moving through illegal jobs.",
			"Someone warned you that the higher-ups were beginning to connect your incidents."
		},
		Effects = { Happiness = -4, WantedLevel = 2, CursedResentment = 5, Reputation = -4 }
	},

	{
		Id = "curse_user_rogue_success",
		Category = "CurseUser",
		MinAge = 18,
		MaxAge = 100,
		Weight = 7,
		RequiresCurseUser = true,
		Texts = {
			"You completed a rogue job cleanly and walked away before anyone official arrived.",
			"An illegal curse job paid better than anything Jujutsu High would have approved.",
			"Your curse user reputation made people scared to negotiate against you."
		},
		Effects = { Money = 480, CursedEnergy = 8, TechniqueMastery = 2, Reputation = -5, WantedLevel = 2, CursedResentment = 6 }
	},

	{
		Id = "curse_user_stranger_murder",
		Category = "CurseUser",
		MinAge = 18,
		MaxAge = 100,
		Weight = 3,
		RequiresCurseUser = true,
		Texts = {
			"A stranger saw too much during a forbidden job. You made sure they never reported it.",
			"Someone unknown crossed your path at the wrong time, and the alley went silent afterward.",
			"A civilian witness panicked when your cursed energy leaked. You chose violence before mercy."
		},
		Effects = { Happiness = -12, Reputation = -10, WantedLevel = 5, Fear = 8, CursedResentment = 10, TechniqueMastery = 1 }
	},

	{
		Id = "curse_user_murder_investigation",
		Category = "CurseUser",
		MinAge = 18,
		MaxAge = 100,
		Weight = 4,
		RequiresCurseUser = true,
		MinWantedLevel = 5,
		Texts = {
			"Jujutsu Society investigators started connecting dead civilians to your route through the city.",
			"Rumors spread that strangers disappear wherever your cursed energy signature appears.",
			"A quiet investigation began after another body was found near one of your illegal jobs."
		},
		Effects = { Happiness = -8, Reputation = -8, WantedLevel = 3, Fear = 6, CursedResentment = 6 }
	},

	{
		Id = "curse_spirit_rumor_growth",
		Category = "Curse",
		MinAge = 0,
		MaxAge = 999,
		Weight = 12,
		RequiresCurse = true,
		Texts = {
			"People started whispering about a cursed presence near your territory.",
			"Your rumor spread through frightened civilians, feeding the shape of your curse.",
			"A small story about you became a local warning."
		},
		Effects = { CursedEnergy = 8, CurseThreat = 3, CurseEvolutionProgress = 4, CurseRumorSpread = 6, SocietyAttention = 2, ExorcismRisk = 1 }
	},

	{
		Id = "curse_spirit_hunger_pang",
		Category = "Curse",
		MinAge = 0,
		MaxAge = 999,
		Weight = 10,
		RequiresCurse = true,
		Texts = {
			"Your hunger twisted harder than usual, making every nearby emotion feel loud.",
			"The cursed hunger inside you sharpened until hiding became difficult.",
			"You felt your form destabilize from hunger before absorbing a trace of fear."
		},
		Effects = { CurseHunger = 8, CursedEnergy = 5, Happiness = -3, ExorcismRisk = 2 }
	},

	{
		Id = "curse_spirit_scouted",
		Category = "Curse",
		MinAge = 8,
		MaxAge = 999,
		Weight = 7,
		RequiresCurse = true,
		Texts = {
			"A low-grade sorcerer patrol passed near your territory and nearly noticed your trail.",
			"Jujutsu scouts inspected an incident connected to your rumor.",
			"Someone left a talisman near your haunt. They are starting to look closer."
		},
		Effects = { SocietyAttention = 6, ExorcismRisk = 5, CurseThreat = 1, CursedEnergy = 3 }
	},

	{
		Id = "curse_spirit_territory_claim",
		Category = "Curse",
		MinAge = 8,
		MaxAge = 999,
		Weight = 8,
		RequiresCurse = true,
		Texts = {
			"Your cursed energy settled deeper into your territory.",
			"The place you haunt started reacting to your presence as if it belonged to you.",
			"You pushed weaker curse traces away and strengthened your hold on the area."
		},
		Effects = { CurseTerritoryControl = 6, CurseThreat = 2, CurseEvolutionProgress = 3, CursedEnergy = 6 }
	},

	{
		Id = "dojo_student_breakthrough",
		Category = "Dojo",
		MinAge = 25,
		MaxAge = 120,
		Weight = 9,
		RequiresGrandDojo = true,
		RequiresDojoStudents = true,
		Texts = {
			"One of your dojo students finally understood a correction you gave them weeks ago.",
			"Your students stayed late after training and pushed each other harder than usual.",
			"The Grand Dojo felt alive as your students improved together."
		},
		Effects = { ClanReputation = 4, DojoPrestige = 3, Reputation = 1 }
	},

	{
		Id = "dojo_student_accident",
		Category = "Dojo",
		MinAge = 25,
		MaxAge = 120,
		Weight = 5,
		RequiresGrandDojo = true,
		RequiresDojoStudents = true,
		Texts = {
			"A student pushed too hard during training and damaged part of the dojo floor.",
			"A sparring drill went wrong, forcing you to repair the training hall.",
			"Your students learned from a rough session, but the Grand Dojo took damage."
		},
		Effects = { ClanReputation = 2, DojoPrestige = 1, DojoCondition = -6, Happiness = -2 }
	},

	{
		Id = "miracle_charge_bystander_escape",
		Category = "Normal",
		MinAge = 6,
		MaxAge = 90,
		Weight = 4,
		RequiredTechnique = "Miracle",
		Texts = {
			"A child stepped off a curb directly into traffic — and a car swerved at the last instant for no clear reason. You forgot what you saw within the hour.",
			"A stranger's bag caught on a railing just before she fell down a flight of stairs. You can't remember her face by evening.",
			"A coin rolled off a table and landed perfectly upright on its edge. You stared at it for a moment, then forgot completely.",
		},
		Effects = { MiracleCharges = 1 }
	},

	{
		Id = "miracle_charge_near_miss",
		Category = "Normal",
		MinAge = 10,
		MaxAge = 90,
		Weight = 3,
		RequiredTechnique = "Miracle",
		Texts = {
			"Something grazed your cheek at high speed. You never worked out what it was.",
			"A support beam groaned above you in an old building. It held. The memory was gone before you reached the door.",
			"You stepped over a crack in the road without looking. The concrete gave way seconds after you passed.",
		},
		Effects = { MiracleCharges = 1 }
	},

	{
		Id = "miracle_charge_witnessed_coincidence",
		Category = "Normal",
		MinAge = 8,
		MaxAge = 90,
		Weight = 3,
		RequiredTechnique = "Miracle",
		Texts = {
			"Two people you'd never met said the exact same sentence at the exact same time on opposite sides of the street. You filed it away somewhere deep.",
			"A curse you'd been tracking vanished from a location before you arrived — someone else was there and walked away unharmed. Pure chance.",
			"You watched a sparring match end exactly in a draw, down to the half-second. The instructor called it a once-in-a-decade outcome.",
		},
		Effects = { MiracleCharges = 1 }
	},

	{
		Id = "miracle_charge_impossible_timing",
		Category = "CurseUser",
		MinAge = 12,
		MaxAge = 90,
		Weight = 3,
		RequiredTechnique = "Miracle",
		Texts = {
			"A cursed spirit attacked you in an alley and froze — for no reason you could identify — just long enough for a sorcerer to arrive and finish it.",
			"You were trapped inside a barrier technique and it collapsed a second before you passed out. The caster claimed it wasn't their doing.",
			"Your technique misfired and the energy dispersed harmlessly into the air instead of back into your body. You marked it as a fluke.",
		},
		Effects = { MiracleCharges = 1 }
	}

}

local QuietYearTexts = {
	"You moved through the year quietly.",
	"The year passed without anything major changing.",
	"You spent the year trying to understand the strange things around you.",
	"Nothing major happened, but the feeling of cursed energy never fully left.",
	"You had a calm year, though the world still felt slightly wrong.",
	"You kept living your life, even with cursed energy lingering around you.",
	"The year passed slowly, with only small changes in your life.",
	"You stayed out of trouble for most of the year.",
	"You spent the year watching, learning, and trying not to stand out.",
	"The year was mostly calm, but something about your life still felt unusual.",
	"You tried to live normally, even though normal never felt fully real.",
	"You carried on with your life while strange feelings moved around you.",
	"The year passed with no major incident, but your senses kept sharpening.",
	"You kept noticing things most people ignored.",
	"Nothing dramatic happened, but your life still felt connected to something darker."
}

local function hasTechnique(stats)
	if not stats then
		return false
	end

	return stats.CursedTechnique ~= nil and stats.CursedTechnique ~= "None"
end

local function isCurseUser(stats)
	if not stats then
		return false
	end

	return stats.IsCurseUser == true
		or stats.CurseUser == true
		or stats.Path == "Curse User"
		or stats.SorcererPath == "Curse User"
		or stats.Alignment == "Curse User"
		or string.sub(tostring(stats.Grade or ""), 1, 11) == "Curse User "
end

local function isCurseLife(stats)
	if not stats then
		return false
	end

	local origin = tostring(stats.Origin or stats.Clan or "")
	local originCategory = tostring(stats.OriginCategory or "")
	local familyType = tostring(stats.FamilyType or "")
	local race = tostring(stats.Race or "")
	local curseType = tostring(stats.CurseType or "")

	return stats.IsCurse == true
		or race == "Cursed Spirit"
		or race == "Curse"
		or origin == "Cursed Womb"
		or origin == "Cursed Spirit"
		or origin == "Vengeful Spirit Rebirth"
		or originCategory == "Race"
		or familyType == "Cursed Spirit"
		or curseType == "Cursed Womb"
		or curseType == "Death Painting"
		or curseType == "Cursed Spirit"
		or string.find(curseType, "Cursed Spirit", 1, true) ~= nil
end

local function ownsAssetById(stats, assetId)
	if not stats or type(stats.Assets) ~= "table" then
		return false
	end

	for _, asset in ipairs(stats.Assets) do
		if asset and asset.Id == assetId then
			return true
		end
	end

	return false
end

local function countDojoStudents(stats)
	local count = 0
	for _, relationship in ipairs(stats and stats.Relationships or {}) do
		if relationship and relationship.Alive ~= false and (relationship.Role == "Student" or relationship.Role == "Ward") then
			count += 1
		end
	end
	return count
end

local function isRecent(stats, eventId)
	if not stats or not stats.RecentLifeEvents then
		return false
	end

	for _, recentId in ipairs(stats.RecentLifeEvents) do
		if recentId == eventId then
			return true
		end
	end

	return false
end

local function rememberEvent(stats, eventId)
	stats.RecentLifeEvents = stats.RecentLifeEvents or {}

	table.insert(stats.RecentLifeEvents, 1, eventId)

	while #stats.RecentLifeEvents > 6 do
		table.remove(stats.RecentLifeEvents)
	end
end

local function matchesEvent(stats, eventData)
	if not stats or not eventData then
		return false
	end

	local age = stats.Age or 0

	if eventData.MinAge and age < eventData.MinAge then
		return false
	end

	if eventData.MaxAge and age > eventData.MaxAge then
		return false
	end

	if eventData.RequiredFamilyType and stats.FamilyType ~= eventData.RequiredFamilyType then
		return false
	end

	if eventData.RequiredOrigin and stats.Origin ~= eventData.RequiredOrigin then
		return false
	end

	if eventData.RequiredOriginCategory and stats.OriginCategory ~= eventData.RequiredOriginCategory then
		return false
	end

	if eventData.RequiredGrade and stats.Grade ~= eventData.RequiredGrade then
		return false
	end

	if eventData.RequiresTechnique and not hasTechnique(stats) then
		return false
	end

	if eventData.RequiredTechnique then
		local ct = tostring(stats.CursedTechnique or "None")
		local it = tostring(stats.InnateTechnique or "None")
		if ct ~= eventData.RequiredTechnique and it ~= eventData.RequiredTechnique then
			return false
		end
	end

	if eventData.RequiresJujutsuHigh and not stats.InJujutsuHigh then
		return false
	end

	if eventData.RequiresCurseUser and not isCurseUser(stats) then
		return false
	end

	if eventData.RequiresCurse and not isCurseLife(stats) then
		return false
	end

	if eventData.RequiresGrandDojo and (stats.ClanFounded ~= true or not ownsAssetById(stats, "grand_dojo")) then
		return false
	end

	if eventData.RequiresDojoStudents and countDojoStudents(stats) <= 0 then
		return false
	end

	if eventData.MinWantedLevel and (tonumber(stats.WantedLevel) or 0) < eventData.MinWantedLevel then
		return false
	end

	return true
end

function BitKaisenLifeEvents.GetQuietYearText(stats)
	stats.RecentQuietTexts = stats.RecentQuietTexts or {}

	local available = {}

	for _, text in ipairs(QuietYearTexts) do
		local recentlyUsed = false

		for _, recentText in ipairs(stats.RecentQuietTexts) do
			if recentText == text then
				recentlyUsed = true
				break
			end
		end

		if not recentlyUsed then
			table.insert(available, text)
		end
	end

	if #available <= 0 then
		available = QuietYearTexts
		stats.RecentQuietTexts = {}
	end

	local chosen = available[math.random(1, #available)]

	table.insert(stats.RecentQuietTexts, 1, chosen)

	while #stats.RecentQuietTexts > 5 do
		table.remove(stats.RecentQuietTexts)
	end

	return chosen
end

function BitKaisenLifeEvents.GetValidEvents(stats, ignoreRecent)
	local validEvents = {}

	for _, eventData in ipairs(BitKaisenLifeEvents.Database) do
		if matchesEvent(stats, eventData) then
			if ignoreRecent or not isRecent(stats, eventData.Id) then
				table.insert(validEvents, eventData)
			end
		end
	end

	return validEvents
end

function BitKaisenLifeEvents.RollEvent(stats)
	local validEvents = BitKaisenLifeEvents.GetValidEvents(stats, false)

	if #validEvents <= 0 then
		validEvents = BitKaisenLifeEvents.GetValidEvents(stats, true)
	end

	if #validEvents <= 0 then
		return nil
	end

	local totalWeight = 0

	for _, eventData in ipairs(validEvents) do
		totalWeight += eventData.Weight or 1
	end

	local roll = math.random(1, totalWeight)
	local currentWeight = 0

	for _, eventData in ipairs(validEvents) do
		currentWeight += eventData.Weight or 1

		if roll <= currentWeight then
			local chosenText = eventData.Text

			if eventData.Texts and #eventData.Texts > 0 then
				chosenText = eventData.Texts[math.random(1, #eventData.Texts)]
			end

			return {
				Id = eventData.Id,
				Category = eventData.Category,
				Text = chosenText,
				Effects = eventData.Effects or {}
			}
		end
	end

	return nil
end

function BitKaisenLifeEvents.ApplyEvent(stats, eventData)
	if not stats or not eventData then
		return ""
	end

	local effects = eventData.Effects or {}
	local ceToolBonus = 0
	local ceToolName = nil

	if effects.Health then
		stats.Health = math.clamp((stats.Health or 100) + effects.Health, 0, 100)
	end

	if effects.Happiness then
		stats.Happiness = math.clamp((stats.Happiness or 100) + effects.Happiness, 0, 100)
	end

	if effects.Smarts then
		stats.Smarts = math.clamp((stats.Smarts or 0) + effects.Smarts, 0, 100)
	end

	if effects.CursedEnergy then
		local ceGain, bonus, tool = BitKaisenCursedTools.ApplyCEGain(stats, effects.CursedEnergy)
		stats.CursedEnergy = math.max(0, (stats.CursedEnergy or 0) + ceGain)
		ceToolBonus = bonus or 0
		ceToolName = tool and tool.Name or nil
	end

	if effects.Money then
		stats.Money = math.max(0, (stats.Money or 0) + effects.Money)
	end

	if effects.Reputation then
		stats.Reputation = (tonumber(stats.Reputation) or 0) + effects.Reputation
	end


	if effects.TechniqueMastery then
		stats.TechniqueMastery = math.clamp((tonumber(stats.TechniqueMastery) or 0) + effects.TechniqueMastery, 0, 100)
	end

	if effects.TeacherRecommendations then
		stats.TeacherRecommendations = math.max(0, (tonumber(stats.TeacherRecommendations) or 0) + effects.TeacherRecommendations)
	end

	if effects.CursedResentment then
		stats.CursedResentment = math.clamp((tonumber(stats.CursedResentment) or 0) + effects.CursedResentment, 0, 999)
	end

	if effects.WantedLevel then
		stats.WantedLevel = math.clamp((tonumber(stats.WantedLevel) or 0) + effects.WantedLevel, 0, 100)
	end

	if effects.CurseThreat then
		stats.CurseThreat = math.max(0, (tonumber(stats.CurseThreat) or 0) + effects.CurseThreat)
	end

	if effects.SocietyAttention then
		stats.SocietyAttention = math.clamp((tonumber(stats.SocietyAttention) or 0) + effects.SocietyAttention, 0, 100)
	end

	if effects.ExorcismRisk then
		stats.ExorcismRisk = math.clamp((tonumber(stats.ExorcismRisk) or 0) + effects.ExorcismRisk, 0, 100)
	end

	if effects.CurseEvolutionProgress then
		stats.CurseEvolutionProgress = math.max(0, (tonumber(stats.CurseEvolutionProgress) or 0) + effects.CurseEvolutionProgress)
	end

	if effects.CurseHunger then
		stats.CurseHunger = math.clamp((tonumber(stats.CurseHunger) or 0) + effects.CurseHunger, 0, 100)
	end

	if effects.CurseTerritoryControl then
		stats.CurseTerritoryControl = math.clamp((tonumber(stats.CurseTerritoryControl) or 0) + effects.CurseTerritoryControl, 0, 100)
	end

	if effects.CurseRumorSpread then
		stats.CurseRumorSpread = math.max(0, (tonumber(stats.CurseRumorSpread) or 0) + effects.CurseRumorSpread)
	end

	if effects.CurseFearLevel then
		stats.CurseFearLevel = math.max(0, (tonumber(stats.CurseFearLevel) or 0) + effects.CurseFearLevel)
	end

	if effects.ClanReputation then
		stats.ClanReputation = math.max(0, (tonumber(stats.ClanReputation) or 0) + effects.ClanReputation)
	end

	if effects.DojoPrestige then
		stats.DojoPrestige = math.max(0, (tonumber(stats.DojoPrestige) or 0) + effects.DojoPrestige)
	end

	if effects.DojoCondition then
		stats.DojoCondition = math.clamp((tonumber(stats.DojoCondition) or 100) + effects.DojoCondition, 0, 100)
	end

	if effects.MiracleCharges and tostring(stats.CursedTechnique) == "Miracle" then
		stats.MiracleCharges = math.clamp((tonumber(stats.MiracleCharges) or 0) + effects.MiracleCharges, 0, 6)
	end

	rememberEvent(stats, eventData.Id)

	local text = tostring(eventData.Text or "Something happened.")
	if ceToolBonus > 0 then
		text ..= "\n<font color='#f0b955'><b>[ CURSED TOOL ]</b></font> " .. tostring(ceToolName or "Your equipped cursed tool") .. " stabilized the gain: <b>+" .. tostring(ceToolBonus) .. " bonus CE</b>."
	end
	return text
end

return BitKaisenLifeEvents
