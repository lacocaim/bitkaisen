-- ModuleScript: BitKaisenLifeEvents
-- Location: ReplicatedStorage

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

	if eventData.RequiresJujutsuHigh and not stats.InJujutsuHigh then
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
		stats.CursedEnergy = math.max(0, (stats.CursedEnergy or 0) + effects.CursedEnergy)
	end

	if effects.Money then
		stats.Money = math.max(0, (stats.Money or 0) + effects.Money)
	end

	if effects.Reputation then
		stats.Reputation = math.max(0, (stats.Reputation or 0) + effects.Reputation)
	end

	rememberEvent(stats, eventData.Id)

	return tostring(eventData.Text or "Something happened.")
end

return BitKaisenLifeEvents
