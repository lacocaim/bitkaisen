-- ModuleScript: BitKaisenLifeEvents
-- Location: ReplicatedStorage

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BitKaisenCursedTools = require(ReplicatedStorage:WaitForChild("BitKaisenCursedTools"))
local BitKaisenStudies = require(ReplicatedStorage:WaitForChild("BitKaisenStudies"))
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))

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

	-- Bounty / Wanted events
	{
		Id = "bounty_posted_publicly",
		Category = "Wanted",
		MinAge = 16,
		MaxAge = 100,
		Weight = 8,
		MinWantedLevel = 2,
		Texts = {
			"A wanted notice with your description circulated through the sorcerer underground.",
			"Your name appeared on a bounty board. Anyone with cursed energy and a death wish could come for you now.",
			"Jujutsu Society posted a public alert. Your face was everywhere people like you gathered."
		},
		Effects = { WantedLevel = 1, Reputation = -6, Happiness = -5 }
	},

	{
		Id = "bounty_hunter_close_call",
		Category = "Wanted",
		MinAge = 16,
		MaxAge = 100,
		Weight = 7,
		MinWantedLevel = 3,
		Texts = {
			"A bounty hunter tracked you to your last known location. You noticed too late but got out just in time.",
			"Someone following you for three blocks turned out to be a licensed hunter. You lost them in a crowd.",
			"A masked figure with a Jujutsu Society contractor badge cornered you briefly. You slipped out before it escalated."
		},
		Effects = { WantedLevel = 1, Health = -8, Happiness = -7 }
	},

	{
		Id = "bounty_hunter_intimidated",
		Category = "Wanted",
		MinAge = 16,
		MaxAge = 100,
		Weight = 6,
		MinWantedLevel = 3,
		Texts = {
			"A bounty hunter found you, but your cursed energy flared before they could act. They walked away.",
			"The hunter who came for your bounty hesitated when they felt what you were capable of. They chose to live.",
			"You didn't run. You just looked at the hunter until they decided the bounty wasn't worth it."
		},
		Effects = { WantedLevel = 1, TechniqueMastery = 1, Happiness = -3 }
	},

	{
		Id = "bounty_hunter_ambush",
		Category = "Wanted",
		MinAge = 18,
		MaxAge = 100,
		Weight = 5,
		MinWantedLevel = 4,
		Texts = {
			"Two bounty hunters cornered you in an alley. You walked out. They didn't.",
			"A coordinated ambush hit you from three directions at once. You survived on instinct and cursed energy alone.",
			"A bounty hunter team tracked you for a week. Their preparation was impressive. It wasn't enough."
		},
		Effects = { WantedLevel = 2, Health = -18, Happiness = -10, CursedEnergy = -8 }
	},

	{
		Id = "bounty_bribed_away",
		Category = "Wanted",
		MinAge = 16,
		MaxAge = 100,
		Weight = 6,
		MinWantedLevel = 4,
		Texts = {
			"You paid off an official to quietly bury your bounty record. It cost a lot, but it bought breathing room.",
			"A contact connected you to someone who could make wanted notices disappear - for a price you paid without hesitation.",
			"You funneled money to the right hands and watched your heat level drop. Expensive, but worth it."
		},
		Effects = { WantedLevel = -3, Money = -600, Reputation = 2, Happiness = 4 }
	},

	{
		Id = "miracle_charge_bystander_escape",
		Category = "Normal",
		MinAge = 6,
		MaxAge = 90,
		Weight = 4,
		RequiredTechnique = "Miracle",
		Texts = {
			"A child stepped off a curb directly into traffic - and a car swerved at the last instant for no clear reason. You forgot what you saw within the hour.",
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
			"A curse you'd been tracking vanished from a location before you arrived - someone else was there and walked away unharmed. Pure chance.",
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
			"A cursed spirit attacked you in an alley and froze - for no reason you could identify - just long enough for a sorcerer to arrive and finish it.",
			"You were trapped inside a barrier technique and it collapsed a second before you passed out. The caster claimed it wasn't their doing.",
			"Your technique misfired and the energy dispersed harmlessly into the air instead of back into your body. You marked it as a fluke.",
		},
		Effects = { MiracleCharges = 1 }
	},

	-- =====================================================================
	-- Update 28: bloodline life. Before this, 37 origins shared the same
	-- handful of generic events, so being born a Gojo read exactly like
	-- being born a civilian. Everything below is gated on RequiredOrigin so
	-- a life is shaped by the name it was born into, across every age band.
	-- =====================================================================

	-- ---------- Gojo Clan ----------
	{
		Id = "gojo_child_measured",
		Category = "Clan",
		MinAge = 3,
		MaxAge = 10,
		Weight = 14,
		RequiredOrigin = "Gojo Clan",
		Texts = {
			"Elders came to measure your cursed energy again. Nobody explained why they kept writing things down.",
			"A room full of adults went quiet when you walked in. One of them wrote something and left without speaking.",
			"You were weighed, measured and tested for a full day. Afterwards an elder said only: it is confirmed.",
		},
		Effects = { CursedEnergy = 10, Happiness = -4, Smarts = 2 }
	},

	{
		Id = "gojo_child_no_playmates",
		Category = "Clan",
		MinAge = 4,
		MaxAge = 12,
		Weight = 12,
		RequiredOrigin = "Gojo Clan",
		Texts = {
			"The other children were told not to touch you. You never found out who gave the order.",
			"You asked why nobody your age was allowed in the inner compound. The answer was: for their sake.",
			"A servant's child played with you once. You never saw them in the compound again.",
		},
		Effects = { Happiness = -7, CursedEnergy = 4 }
	},

	{
		Id = "gojo_teen_weight",
		Category = "Clan",
		MinAge = 13,
		MaxAge = 24,
		Weight = 13,
		RequiredOrigin = "Gojo Clan",
		Texts = {
			"An elder told you the clan's standing rests on you personally. He said it like a fact, not a burden.",
			"You realised the adults around you were not protecting you. They were protecting an asset.",
			"Someone bowed to you before they knew your name. Only the name mattered.",
		},
		Effects = { CursedEnergy = 8, Reputation = 4, Happiness = -5 }
	},

	{
		Id = "gojo_adult_isolation",
		Category = "Clan",
		MinAge = 25,
		MaxAge = 60,
		Weight = 11,
		RequiredOrigin = "Gojo Clan",
		Texts = {
			"You noticed that nobody argues with you anymore. You could not decide whether that was respect or distance.",
			"A colleague admitted they had been told, years ago, never to correct you. They apologised for it.",
			"You won a disagreement you were wrong about. Nobody in the room was willing to say so.",
		},
		Effects = { Reputation = 6, Happiness = -6, Smarts = 3 }
	},

	-- ---------- Zenin Clan ----------
	{
		Id = "zenin_child_ranked",
		Category = "Clan",
		MinAge = 4,
		MaxAge = 12,
		Weight = 14,
		RequiredOrigin = "Zenin Clan",
		Texts = {
			"Your cousins were ranked by strength in front of the whole family. You learned where you stood.",
			"An uncle told you the clan has no use for the weak, then asked how your training was going.",
			"You were made to spar with an older child until one of you could not stand. Nobody stopped it.",
		},
		Effects = { CursedEnergy = 6, Health = -6, Happiness = -5 }
	},

	{
		Id = "zenin_teen_proving",
		Category = "Clan",
		MinAge = 13,
		MaxAge = 28,
		Weight = 13,
		RequiredOrigin = "Zenin Clan",
		Texts = {
			"You were sent on an assignment above your grade. The clan called it an opportunity.",
			"An elder said your worth would be decided by your results this year, and nothing else.",
			"You overheard your own name in a conversation about which branch members were still worth funding.",
		},
		Effects = { CursedEnergy = 7, Health = -5, Reputation = 3 }
	},

	{
		Id = "zenin_adult_politics",
		Category = "Clan",
		MinAge = 25,
		MaxAge = 70,
		Weight = 11,
		RequiredOrigin = "Zenin Clan",
		Texts = {
			"A branch of the family quietly stopped speaking to yours. Nobody would say what started it.",
			"You were asked to take a side in a clan dispute. Refusing was also taking a side.",
			"An elder died and the succession argument began before the funeral ended.",
		},
		Effects = { Reputation = 4, ClanReputation = 5, Happiness = -4 }
	},

	-- ---------- Kamo Clan ----------
	{
		Id = "kamo_child_bloodline",
		Category = "Clan",
		MinAge = 4,
		MaxAge = 14,
		Weight = 14,
		RequiredOrigin = "Kamo Clan",
		Texts = {
			"You were taught to read your own pulse before you were taught to read words.",
			"A physician visited monthly to take your blood. It was described as routine.",
			"An elder explained that your blood is clan property before it is yours.",
		},
		Effects = { CursedEnergy = 7, Smarts = 3, Happiness = -4 }
	},

	{
		Id = "kamo_adult_reputation",
		Category = "Clan",
		MinAge = 20,
		MaxAge = 70,
		Weight = 12,
		RequiredOrigin = "Kamo Clan",
		Texts = {
			"Someone brought up the clan's old crimes to your face, politely, as if it were history.",
			"You were received with perfect courtesy and complete suspicion.",
			"A stranger flinched at your family name before they caught themselves.",
		},
		Effects = { Reputation = -3, Smarts = 4, Fear = 4 }
	},

	-- ---------- Inumaki Clan ----------
	{
		Id = "inumaki_child_silence",
		Category = "Clan",
		MinAge = 3,
		MaxAge = 12,
		Weight = 14,
		RequiredOrigin = "Inumaki Clan",
		Texts = {
			"You were taught which words you are never allowed to say out loud, before you understood why.",
			"You raised your voice at a sibling and every adult in the house went rigid.",
			"Your family taught you to speak in food names. It stopped feeling strange after a while.",
		},
		Effects = { CursedEnergy = 6, Happiness = -4, Smarts = 3 }
	},

	{
		Id = "inumaki_teen_throat",
		Category = "Clan",
		MinAge = 13,
		MaxAge = 40,
		Weight = 12,
		RequiredOrigin = "Inumaki Clan",
		Texts = {
			"Your throat bled after a conversation you should not have had.",
			"You spoke without thinking and someone did exactly what you said. You could not take it back.",
			"You went a full week without speaking. It was easier than the alternative.",
		},
		Effects = { CursedEnergy = 5, Health = -6, Happiness = -3 }
	},

	-- ---------- Fushiguro Lineage ----------
	{
		Id = "fushiguro_child_shadow",
		Category = "Clan",
		MinAge = 3,
		MaxAge = 12,
		Weight = 14,
		RequiredOrigin = "Fushiguro Lineage",
		Texts = {
			"Your shadow moved a half second after you did. You watched it happen twice before you told anyone.",
			"Something in the dark under your bed was not hostile. That unsettled you more than if it had been.",
			"You woke to find the shadows in your room arranged around you like they were keeping watch.",
		},
		Effects = { CursedEnergy = 8, Happiness = -3, Smarts = 2 }
	},

	{
		Id = "fushiguro_teen_inheritance",
		Category = "Clan",
		MinAge = 13,
		MaxAge = 45,
		Weight = 12,
		RequiredOrigin = "Fushiguro Lineage",
		Texts = {
			"An old sorcerer recognised your bloodline on sight and asked, carefully, how far you had gotten.",
			"You learned that what you inherited has beaten every previous holder. Nobody said it unkindly.",
			"Someone described your lineage as unfinished business. They would not explain.",
		},
		Effects = { CursedEnergy = 7, Smarts = 3, Reputation = 3 }
	},

	-- ---------- Okkotsu Lineage ----------
	{
		Id = "okkotsu_child_attachment",
		Category = "Clan",
		MinAge = 4,
		MaxAge = 14,
		Weight = 14,
		RequiredOrigin = "Okkotsu Lineage",
		Texts = {
			"Something followed you home and nobody else could see it. It did not feel like a threat to you.",
			"You made a promise to someone as a child. The air changed when you said it.",
			"You were never alone, even when the room was empty. You stopped finding it frightening.",
		},
		Effects = { CursedEnergy = 12, Happiness = -5 }
	},

	-- ---------- Itadori Lineage ----------
	{
		Id = "itadori_child_body",
		Category = "Clan",
		MinAge = 4,
		MaxAge = 16,
		Weight = 13,
		RequiredOrigin = "Itadori Lineage",
		Texts = {
			"You broke a piece of playground equipment by accident and could not explain how.",
			"An adult tested your grip strength as a joke, then stopped smiling and tested it again.",
			"You outran everyone in your year without training for it once.",
		},
		Effects = { Health = 6, CursedEnergy = 4, Happiness = 3 }
	},

	{
		Id = "itadori_adult_watched",
		Category = "Clan",
		MinAge = 16,
		MaxAge = 70,
		Weight = 11,
		RequiredOrigin = "Itadori Lineage",
		Texts = {
			"An old man you barely knew took an unusual interest in your development.",
			"Someone asked about your grandparents in a way that was not small talk.",
			"You found a photograph of a relative you were never told about.",
		},
		Effects = { Smarts = 3, SocietyAttention = 4, Happiness = -2 }
	},

	-- ---------- Kenjaku Clan ----------
	{
		Id = "kenjaku_child_wrong",
		Category = "Clan",
		MinAge = 3,
		MaxAge = 14,
		Weight = 14,
		RequiredOrigin = "Kenjaku Clan",
		Texts = {
			"You caught a relative watching you with an expression that did not belong to their face.",
			"An elder asked what you would do with a thousand years. You were seven.",
			"Someone in your family spoke about a person from four centuries ago in the first person, then corrected themselves.",
		},
		Effects = { Smarts = 8, CursedEnergy = 6, Happiness = -6 }
	},

	{
		Id = "kenjaku_adult_patience",
		Category = "Clan",
		MinAge = 20,
		MaxAge = 90,
		Weight = 11,
		RequiredOrigin = "Kenjaku Clan",
		Texts = {
			"You found a plan in the family archive that will not finish within your lifetime. Your name was already on it.",
			"You realised your clan measures progress in centuries and treats people as steps.",
			"An elder told you that nobody in this family truly dies, and did not seem to be speaking figuratively.",
		},
		Effects = { Smarts = 7, CursedResentment = 5, Happiness = -5 }
	},

	-- ---------- Hakari Lineage ----------
	{
		Id = "hakari_child_luck",
		Category = "Clan",
		MinAge = 4,
		MaxAge = 16,
		Weight = 13,
		RequiredOrigin = "Hakari Lineage",
		Texts = {
			"You won a schoolyard bet eleven times running and had to start losing on purpose.",
			"A relative taught you the odds on every game they knew, then told you odds are for other people.",
			"You found money on the ground three days in a row. You stopped believing it was chance.",
		},
		Effects = { Money = 400, Happiness = 5, Smarts = 2 }
	},

	-- ---------- Higuruma Lineage ----------
	{
		Id = "higuruma_child_fairness",
		Category = "Clan",
		MinAge = 5,
		MaxAge = 18,
		Weight = 13,
		RequiredOrigin = "Higuruma Lineage",
		Texts = {
			"You argued a punishment down to nothing and the adult admitted you were right. It changed something in you.",
			"You watched someone guilty walk free and could not let it go for months.",
			"A teacher said you had the instincts of a lawyer. It was not entirely a compliment.",
		},
		Effects = { Smarts = 7, Happiness = -3, Reputation = 3 }
	},

	-- ---------- Todo Lineage ----------
	{
		Id = "todo_teen_taste",
		Category = "Clan",
		MinAge = 12,
		MaxAge = 50,
		Weight = 12,
		RequiredOrigin = "Todo Lineage",
		Texts = {
			"You asked someone what kind of person they liked, and took the answer more seriously than they did.",
			"You decided a stranger was your closest friend after a single conversation. You were not wrong.",
			"You judged an opponent entirely on their taste and it turned out to be accurate.",
		},
		Effects = { Happiness = 6, CursedEnergy = 4, Reputation = 2 }
	},

	-- ---------- Nanami Lineage ----------
	{
		Id = "nanami_adult_hours",
		Category = "Clan",
		MinAge = 18,
		MaxAge = 70,
		Weight = 12,
		RequiredOrigin = "Nanami Lineage",
		Texts = {
			"You worked past the hour you promised yourself you would stop, again.",
			"You calculated exactly how many years of this were left. The number did not help.",
			"Someone asked if the work was worth it. You gave the professional answer instead of the true one.",
		},
		Effects = { Money = 900, Smarts = 4, Happiness = -5 }
	},

	-- ---------- Mei Mei Lineage ----------
	{
		Id = "meimei_adult_price",
		Category = "Clan",
		MinAge = 16,
		MaxAge = 70,
		Weight = 12,
		RequiredOrigin = "Mei Mei Lineage",
		Texts = {
			"You put a number on something most people would call priceless, and got paid it.",
			"A colleague was disgusted by your rate. You noticed they still hired you.",
			"You turned down meaningful work because the fee was wrong, and slept fine.",
		},
		Effects = { Money = 2200, Reputation = -2, Smarts = 4 }
	},

	-- ---------- Kusakabe Lineage ----------
	{
		Id = "kusakabe_adult_caution",
		Category = "Clan",
		MinAge = 16,
		MaxAge = 75,
		Weight = 12,
		RequiredOrigin = "Kusakabe Lineage",
		Texts = {
			"You walked away from a fight you could probably have won, and were the only one who called that a victory.",
			"You taught a student the technique that keeps people alive instead of the one that impresses them.",
			"Someone called you unambitious. You had already counted the funerals you did not attend.",
		},
		Effects = { Health = 5, Smarts = 4, TechniqueMastery = 3 }
	},

	-- ---------- Geto Lineage ----------
	{
		Id = "geto_teen_disgust",
		Category = "Clan",
		MinAge = 12,
		MaxAge = 60,
		Weight = 12,
		RequiredOrigin = "Geto Lineage",
		Texts = {
			"You saved someone who never learned your name, and caught yourself resenting it.",
			"A civilian thanked you and you felt nothing at all. That absence stayed with you.",
			"You did the right thing, correctly, and it did not feel like enough anymore.",
		},
		Effects = { CursedResentment = 7, CursedEnergy = 5, Happiness = -5 }
	},

	-- ---------- Uraume Lineage ----------
	{
		Id = "uraume_child_cold",
		Category = "Clan",
		MinAge = 3,
		MaxAge = 20,
		Weight = 12,
		RequiredOrigin = "Uraume Lineage",
		Texts = {
			"Water left standing near you turned to ice overnight, in summer.",
			"You never felt the cold. Adults kept putting coats on you anyway.",
			"You held someone's hand and they pulled away from the temperature of it.",
		},
		Effects = { CursedEnergy = 8, Happiness = -3 }
	},

	-- ---------- Kashimo Lineage ----------
	{
		Id = "kashimo_adult_hunger",
		Category = "Clan",
		MinAge = 14,
		MaxAge = 80,
		Weight = 12,
		RequiredOrigin = "Kashimo Lineage",
		Texts = {
			"You won a fight easily and felt cheated by it.",
			"You went looking for someone stronger than you and were disappointed by what you found.",
			"Someone asked what you wanted from life. You said: one good fight. They thought you were joking.",
		},
		Effects = { CursedEnergy = 7, Happiness = -4, Fear = 4 }
	},

	-- ---------- Death Painting Lineage ----------
	{
		Id = "death_painting_child_made",
		Category = "Clan",
		MinAge = 1,
		MaxAge = 25,
		Weight = 13,
		RequiredOrigin = "Death Painting Lineage",
		Texts = {
			"You have no memory of being a child, and no one who can tell you about it.",
			"You understood, without being told, that you were made rather than born.",
			"Someone examined you the way a curator examines a piece, and you knew the word for what you are.",
		},
		Effects = { CursedEnergy = 9, Happiness = -7, CursedResentment = 4 }
	},

	-- ---------- Cursed Womb ----------
	{
		Id = "cursed_womb_animals",
		Category = "Clan",
		MinAge = 1,
		MaxAge = 30,
		Weight = 12,
		RequiredOrigin = "Cursed Womb",
		Texts = {
			"Animals refused to be in the same room as you. People noticed and said nothing.",
			"A dog barked at you until it lost its voice. Its owner apologised. You both knew why.",
			"Plants near where you slept died out of season.",
		},
		Effects = { CursedEnergy = 7, Happiness = -6, Fear = 4 }
	},

	-- ---------- Civilian Family ----------
	-- The most common roll in the game had almost nothing written for it.
	{
		Id = "civilian_child_normal",
		Category = "Normal",
		MinAge = 4,
		MaxAge = 12,
		Weight = 14,
		RequiredOrigin = "Civilian Family",
		Texts = {
			"You had an ordinary year. Later you would look back on it as the last one.",
			"Your parents worried about your grades, not your cursed energy. It was almost restful.",
			"You went on a family trip and nothing supernatural happened at all.",
		},
		Effects = { Happiness = 8, Smarts = 2 }
	},

	{
		Id = "civilian_child_gap",
		Category = "Normal",
		MinAge = 6,
		MaxAge = 16,
		Weight = 13,
		RequiredOrigin = "Civilian Family",
		Texts = {
			"You tried to describe what you saw and your family gently suggested you were imagining it.",
			"A doctor was consulted about your descriptions. Nothing was found.",
			"You learned it was easier to stop mentioning the things nobody else noticed.",
		},
		Effects = { Happiness = -6, Smarts = 3, CursedEnergy = 3 }
	},

	{
		Id = "civilian_adult_distance",
		Category = "Normal",
		MinAge = 18,
		MaxAge = 80,
		Weight = 12,
		RequiredOrigin = "Civilian Family",
		Texts = {
			"You could not explain your work to your family, so you stopped trying.",
			"A relative asked what you actually do. You gave the answer you always give.",
			"You missed a family occasion for a reason you were not allowed to name.",
		},
		Effects = { Happiness = -5, Reputation = 2 }
	},

	-- ---------- Minor / Branch / Fallen / Unknown ----------
	{
		Id = "minor_family_ceiling",
		Category = "Normal",
		MinAge = 10,
		MaxAge = 60,
		Weight = 12,
		RequiredOrigin = "Minor Sorcerer Family",
		Texts = {
			"Your family had connections, but only enough to get you into the room.",
			"You were told, kindly, exactly how far your name would carry you.",
			"You watched a clan child receive what you had spent years earning.",
		},
		Effects = { Smarts = 3, CursedEnergy = 3, Happiness = -4 }
	},

	{
		Id = "branch_family_service",
		Category = "Clan",
		MinAge = 8,
		MaxAge = 60,
		Weight = 12,
		RequiredOrigin = "Branch Sorcerer Family",
		Texts = {
			"You were reminded that a branch exists to support the main house, not to rival it.",
			"Your results were credited to the main family. Nobody thought that was strange.",
			"You were given the work, and someone else was given the recognition.",
		},
		Effects = { CursedEnergy = 5, ClanReputation = 3, Happiness = -5 }
	},

	{
		Id = "unknown_family_search",
		Category = "Normal",
		MinAge = 12,
		MaxAge = 70,
		Weight = 11,
		RequiredOrigin = "Unknown Family",
		Texts = {
			"You went looking for records of your family and found a gap where they should have been.",
			"Someone recognised your surname, went pale, and refused to explain.",
			"You accepted that you may never learn what your family did, or what was done to them.",
		},
		Effects = { Smarts = 5, Happiness = -4, CursedEnergy = 3 }
	},

	-- ---------- Original clans ----------
	{
		Id = "kumiwado_blood_ledger",
		Category = "Clan",
		MinAge = 6,
		MaxAge = 60,
		Weight = 12,
		RequiredOrigin = "Kumiwado Clan",
		Texts = {
			"Your family keeps a ledger of debts owed in blood. You were shown your page.",
			"An elder explained that the clan forgives nothing and forgets less.",
			"You learned that a favour accepted by your grandfather is still owed by you.",
		},
		Effects = { CursedEnergy = 6, CursedResentment = 4, Smarts = 3 }
	},

	{
		Id = "mizukara_mirror_rule",
		Category = "Clan",
		MinAge = 4,
		MaxAge = 60,
		Weight = 12,
		RequiredOrigin = "Mizukara Clan",
		Texts = {
			"Every mirror in the house is covered after dark. You were never told what happened before that rule existed.",
			"You saw your reflection turn a moment late and understood the covering.",
			"A child in the compound uncovered a mirror on a dare. The adults did not punish them, which was worse.",
		},
		Effects = { CursedEnergy = 7, Happiness = -4, Smarts = 2 }
	},

	{
		Id = "amahara_storm_watch",
		Category = "Clan",
		MinAge = 5,
		MaxAge = 60,
		Weight = 12,
		RequiredOrigin = "Amahara Clan",
		Texts = {
			"The clan reads weather the way others read letters. You were taught the alphabet of it.",
			"A storm changed direction over the compound and the elders treated it as a message.",
			"You felt the pressure drop hours before the sky did anything, and nobody found that remarkable.",
		},
		Effects = { CursedEnergy = 7, Smarts = 3 }
	},

	{
		Id = "tsukigane_forge_night",
		Category = "Clan",
		MinAge = 6,
		MaxAge = 60,
		Weight = 12,
		RequiredOrigin = "Tsukigane Clan",
		Texts = {
			"The forge in the compound never goes cold. You took your first shift at it this year.",
			"You were taught that the clan does not buy its tools, and that this is the whole point.",
			"An elder showed you a blade with your great-grandmother's name still on the tang.",
		},
		Effects = { CursedEnergy = 5, TechniqueMastery = 3, Health = -3 }
	},

	{
		Id = "kurogiri_quiet_house",
		Category = "Clan",
		MinAge = 4,
		MaxAge = 60,
		Weight = 12,
		RequiredOrigin = "Kurogiri Clan",
		Texts = {
			"Your family moves through the house without sound. You learned it before you learned to run.",
			"You were praised for the first time when nobody heard you enter a room.",
			"An elder crossed the entire compound in front of you and you could not track them.",
		},
		Effects = { CursedEnergy = 6, Smarts = 3, Happiness = -2 }
	},

	{
		Id = "hoshinari_reading_stars",
		Category = "Clan",
		MinAge = 5,
		MaxAge = 60,
		Weight = 12,
		RequiredOrigin = "Hoshinari Clan",
		Texts = {
			"The clan makes decisions by a chart nobody outside the family can read. You began learning it.",
			"An elder told you the outcome of something before it happened, then refused to explain the method.",
			"You were told your birth was calculated, not merely timed.",
		},
		Effects = { Smarts = 6, CursedEnergy = 4 }
	},

	{
		Id = "yamashiro_barrier_duty",
		Category = "Clan",
		MinAge = 8,
		MaxAge = 60,
		Weight = 12,
		RequiredOrigin = "Yamashiro Clan",
		Texts = {
			"Your family maintains barriers nobody thanks them for. You took your first watch.",
			"You were taught that the clan's work is invisible when it succeeds.",
			"A curtain your grandfather raised is still standing. You were shown where it holds.",
		},
		Effects = { CursedEnergy = 5, TechniqueMastery = 3, Reputation = 2 }
	},

	{
		Id = "shinkawa_thread_lesson",
		Category = "Clan",
		MinAge = 6,
		MaxAge = 60,
		Weight = 12,
		RequiredOrigin = "Shinkawa Clan",
		Texts = {
			"You were given thread instead of a weapon and told the difference was patience.",
			"An elder bound your hands and told you to free yourself. It took three days.",
			"You learned every knot the clan uses before you were allowed to learn why.",
		},
		Effects = { CursedEnergy = 5, Smarts = 4, Health = -3 }
	},

	{
		Id = "morikage_grave_tending",
		Category = "Clan",
		MinAge = 6,
		MaxAge = 60,
		Weight = 12,
		RequiredOrigin = "Morikage Clan",
		Texts = {
			"The clan tends a grove where the family's dead are buried standing. You were given a row to keep.",
			"You were taught which plants grow only where something is buried.",
			"An elder said the clan's strength comes from what it refuses to let rot cleanly.",
		},
		Effects = { CursedEnergy = 6, CursedResentment = 3, Happiness = -3 }
	},

	{
		Id = "fushidori_bird_keeping",
		Category = "Clan",
		MinAge = 5,
		MaxAge = 60,
		Weight = 12,
		RequiredOrigin = "Fushidori Clan",
		Texts = {
			"You were given a bird to raise. You were not told it would outlive several of your relatives.",
			"The crows in the compound answer to the family, and this year they began answering to you.",
			"An elder sent word across the country without writing anything down.",
		},
		Effects = { CursedEnergy = 6, Smarts = 3, Happiness = 2 }
	},

	{
		Id = "fujiwara_old_name",
		Category = "Clan",
		MinAge = 8,
		MaxAge = 70,
		Weight = 11,
		RequiredOrigin = "Fujiwara Lineage",
		Texts = {
			"Your name opens doors that have been closed for a thousand years. You learned which ones.",
			"Someone treated your family as history rather than as people, to your face.",
			"You were reminded that the clan's influence was built long before cursed energy was measured.",
		},
		Effects = { Reputation = 6, Smarts = 4, Money = 700 }
	},

	{
		Id = "sugawara_scholar_debt",
		Category = "Clan",
		MinAge = 8,
		MaxAge = 70,
		Weight = 11,
		RequiredOrigin = "Sugawara Lineage",
		Texts = {
			"The family archive is older than the school system. You were finally given a key to it.",
			"You were told that your ancestor was exiled for being right, and that this is the family tradition.",
			"A scholar came a long way to consult a text your family has never let leave the house.",
		},
		Effects = { Smarts = 8, CursedEnergy = 3, Reputation = 3 }
	},

	-- =====================================================================
	-- Update 28: technique life. RequiredTechnique matches either the
	-- inherited or the awakened technique, so these fire for anyone who
	-- actually holds it. Living with a technique should read differently
	-- depending on which one you got, not just change a combat number.
	-- =====================================================================

	{
		Id = "ct_limitless_distance",
		Category = "Normal",
		MinAge = 6,
		MaxAge = 90,
		Weight = 9,
		RequiredTechnique = "Limitless",
		Texts = {
			"You reached for a cup and stopped, because for a moment the distance to it did not resolve.",
			"Someone threw something at you and it slowed without you deciding anything.",
			"You understood, briefly and completely, why nothing has ever actually touched you.",
		},
		Effects = { CursedEnergy = 8, Smarts = 4, Happiness = -3 }
	},

	{
		Id = "ct_ten_shadows_refusal",
		Category = "Normal",
		MinAge = 6,
		MaxAge = 90,
		Weight = 9,
		RequiredTechnique = "Ten Shadows",
		Texts = {
			"A shadow you have not tamed watched you from the edge of the ritual and did not come forward.",
			"You called something and it arrived slower than it should have. You understood it was a warning.",
			"One of your shikigami refused an order for the first time. You did not repeat it.",
		},
		Effects = { CursedEnergy = 6, TechniqueMastery = 3, Happiness = -3 }
	},

	{
		Id = "ct_copy_borrowed",
		Category = "Normal",
		MinAge = 8,
		MaxAge = 90,
		Weight = 9,
		RequiredTechnique = "Copy",
		Texts = {
			"You used a technique that was not yours and could not stop thinking about whose it was.",
			"Someone recognised their own technique in your hands and went very quiet.",
			"You caught yourself wondering whether you have anything that started with you.",
		},
		Effects = { CursedEnergy = 6, Smarts = 4, Happiness = -4 }
	},

	{
		Id = "ct_rika_presence",
		Category = "Normal",
		MinAge = 6,
		MaxAge = 90,
		Weight = 9,
		RequiredTechnique = "Rika Manifestation",
		Texts = {
			"She answered before you finished asking. She has been getting faster.",
			"Someone spoke badly of you and the temperature in the room dropped. You apologised on her behalf.",
			"You slept badly and woke to find she had not left your side all night.",
		},
		Effects = { CursedEnergy = 10, Happiness = -4, Fear = 5 }
	},

	{
		Id = "ct_shrine_edges",
		Category = "Normal",
		MinAge = 8,
		MaxAge = 90,
		Weight = 9,
		RequiredTechnique = "Shrine",
		Texts = {
			"You cut something that was not in front of you, and only noticed afterwards.",
			"A line appeared across a wall you had merely looked at.",
			"You started measuring rooms by what you could reach from where you stood.",
		},
		Effects = { CursedEnergy = 8, Fear = 6, Happiness = -3 }
	},

	{
		Id = "ct_blood_cost",
		Category = "Normal",
		MinAge = 8,
		MaxAge = 90,
		Weight = 9,
		RequiredTechnique = "Blood Manipulation",
		Texts = {
			"You spent more of yourself than the fight was worth, and felt it for a week.",
			"You learned exactly how much you can lose before your hands stop working.",
			"A physician asked why your iron levels read like someone twice your age.",
		},
		Effects = { CursedEnergy = 6, Health = -7, TechniqueMastery = 3 }
	},

	{
		Id = "ct_cursed_speech_slip",
		Category = "Normal",
		MinAge = 6,
		MaxAge = 90,
		Weight = 9,
		RequiredTechnique = "Cursed Speech",
		Texts = {
			"You told someone to wait and they could not move until you said otherwise.",
			"You lost your temper mid-sentence and everyone in the room obeyed the half of it you finished.",
			"Your voice gave out entirely for two days after a single word.",
		},
		Effects = { CursedEnergy = 6, Health = -5, Fear = 4 }
	},

	{
		Id = "ct_idle_transfiguration_weight",
		Category = "Normal",
		MinAge = 10,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "Idle Transfiguration",
		Texts = {
			"You touched someone by accident and had to consciously do nothing.",
			"You understood that you could rewrite anyone you can reach, and that no one else in the room knew it.",
			"You caught yourself seeing people as shapes that could be otherwise.",
		},
		Effects = { CursedEnergy = 7, CursedResentment = 5, Happiness = -5 }
	},

	{
		Id = "ct_brain_transplant_borrowed_time",
		Category = "Normal",
		MinAge = 12,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "Brain Transplant",
		Texts = {
			"You caught your reflection and needed a moment to recognise which face you were wearing.",
			"You remembered a room you have never been in, clearly, including the smell of it.",
			"You realised you have stopped counting your age in the usual way.",
		},
		Effects = { Smarts = 7, CursedEnergy = 4, Happiness = -5 }
	},

	{
		Id = "ct_heavenly_restriction_body",
		Category = "Normal",
		MinAge = 6,
		MaxAge = 90,
		Weight = 9,
		RequiredTechnique = "Heavenly Restriction",
		Texts = {
			"A sorcerer looked straight through you and did not register that you were there at all.",
			"You outperformed people with decades of technique training and none of them could explain how.",
			"You were told what you traded away. You had never had it, so it did not feel like a loss.",
		},
		Effects = { Health = 8, Smarts = 3, Happiness = 2 }
	},

	{
		Id = "ct_cursed_spirit_manipulation_menagerie",
		Category = "Normal",
		MinAge = 10,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "Cursed Spirit Manipulation",
		Texts = {
			"Something you swallowed months ago moved on its own while you slept.",
			"You catalogued what you carry and were unsettled by the length of the list.",
			"One of the spirits you keep has begun to feel less like a tool.",
		},
		Effects = { CursedEnergy = 7, CursedResentment = 4, Fear = 4 }
	},

	{
		Id = "ct_projection_frames",
		Category = "Normal",
		MinAge = 10,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "Projection Sorcery",
		Texts = {
			"You caught yourself counting a conversation in frames instead of seconds.",
			"Someone moved wrong in front of you and your hands answered before you decided to.",
			"You practised until a full second stopped feeling like one thing.",
		},
		Effects = { CursedEnergy = 6, TechniqueMastery = 4, Smarts = 3 }
	},

	{
		Id = "ct_boogie_woogie_habit",
		Category = "Normal",
		MinAge = 8,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "Boogie Woogie",
		Texts = {
			"You clapped to get someone's attention and had to explain why they were suddenly across the room.",
			"You stopped clapping in public entirely. It was simpler.",
			"You swapped out of danger without thinking about it, and only understood afterwards.",
		},
		Effects = { CursedEnergy = 5, Happiness = 3, TechniqueMastery = 3 }
	},

	{
		Id = "ct_deadly_sentencing_judgement",
		Category = "Normal",
		MinAge = 14,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "Deadly Sentencing",
		Texts = {
			"You found yourself assembling the case against someone before they had finished speaking.",
			"You understood that your technique only works if you actually believe the verdict.",
			"You reached a conclusion about a person and could not make yourself doubt it afterwards.",
		},
		Effects = { Smarts = 6, CursedEnergy = 5, Happiness = -3 }
	},

	{
		Id = "ct_private_pure_love_run",
		Category = "Normal",
		MinAge = 10,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "Private Pure Love Train",
		Texts = {
			"A long streak of nothing broke all at once and you were the only one who saw it coming.",
			"You lost, repeatedly and cheerfully, because you knew what losing was buying.",
			"Someone called you reckless. You were doing arithmetic they could not see.",
		},
		Effects = { Money = 1500, Happiness = 6, CursedEnergy = 4 }
	},

	{
		Id = "ct_pumpkin_control_company",
		Category = "Normal",
		MinAge = 6,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "Pumpkin Control",
		Texts = {
			"The thing you made stayed by the door all night, uninstructed.",
			"You caught yourself talking to it, and it caught you back.",
			"Someone laughed at your technique right up until it moved.",
		},
		Effects = { CursedEnergy = 5, Happiness = 4, Fear = 3 }
	},

	{
		Id = "ct_mythical_beast_amber_charge",
		Category = "Normal",
		MinAge = 8,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "Mythical Beast Amber",
		Texts = {
			"Every light in the room flickered when you lost your temper.",
			"You touched a door handle and the spark jumped before your hand arrived.",
			"You had to relearn how hard to hold things.",
		},
		Effects = { CursedEnergy = 7, Health = -4, Fear = 4 }
	},

	{
		Id = "ct_ratio_point",
		Category = "Normal",
		MinAge = 10,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "Ratio Technique",
		Texts = {
			"You saw the weak point on a stranger in a shop and looked away, embarrassed.",
			"You stopped being able to watch a fight without marking where it should end.",
			"Someone asked how you always know where to hit. You could not make the answer sound normal.",
		},
		Effects = { Smarts = 5, TechniqueMastery = 4, CursedEnergy = 3 }
	},

	{
		Id = "ct_construction_detail",
		Category = "Normal",
		MinAge = 8,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "Construction",
		Texts = {
			"You spent a month studying an object you will only ever need to make once.",
			"You built something perfectly and it failed anyway, because you had misremembered one detail.",
			"You began keeping notebooks of things measured exactly.",
		},
		Effects = { Smarts = 6, TechniqueMastery = 3, CursedEnergy = 3 }
	},

	{
		Id = "ct_simple_domain_reflex",
		Category = "Normal",
		MinAge = 10,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "Simple Domain",
		Texts = {
			"Your circle came up before you consciously registered the danger.",
			"You practised the same footwork until it stopped being a decision.",
			"Someone tried to open a domain on you and it did not take. Neither of you said anything.",
		},
		Effects = { TechniqueMastery = 5, Health = 4, CursedEnergy = 3 }
	},

	{
		Id = "ct_disaster_flames_control",
		Category = "Normal",
		MinAge = 8,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "Disaster Flames",
		Texts = {
			"You burned more than you meant to and spent the rest of the year being careful.",
			"Nothing in your home is made of paper anymore.",
			"You learned to judge a room by what in it would catch first.",
		},
		Effects = { CursedEnergy = 7, Fear = 5, Health = -3 }
	},

	{
		Id = "ct_ice_formation_stillness",
		Category = "Normal",
		MinAge = 8,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "Ice Formation",
		Texts = {
			"You left frost on a railing in the middle of a warm day and doubled back to check nobody saw.",
			"You practised until the shapes came out clean instead of merely sharp.",
			"Someone shook your hand and asked if you were feeling unwell.",
		},
		Effects = { CursedEnergy = 6, TechniqueMastery = 3, Happiness = -2 }
	},

	{
		Id = "ct_soul_striking_through",
		Category = "Normal",
		MinAge = 10,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "Soul Striking",
		Texts = {
			"You hit something that should have been protected and it went through anyway.",
			"You started to feel the shape of what is under a person, and wished you could stop.",
			"An opponent's guard meant nothing and both of you understood that at the same moment.",
		},
		Effects = { CursedEnergy = 6, Fear = 5, TechniqueMastery = 3 }
	},

	{
		Id = "ct_divergent_fist_second",
		Category = "Normal",
		MinAge = 8,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "Divergent Fist",
		Texts = {
			"The second impact landed a half beat late, exactly as it should, and you finally felt it work.",
			"You broke a training post that was rated for far more than you weigh.",
			"Someone blocked your punch and got hit anyway.",
		},
		Effects = { CursedEnergy = 5, Health = 3, TechniqueMastery = 4 }
	},

	{
		Id = "ct_new_shadow_style_form",
		Category = "Normal",
		MinAge = 8,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "New Shadow Style",
		Texts = {
			"You drew and cut in one motion for the first time without thinking about either.",
			"An instructor corrected your stance by a finger's width and everything improved.",
			"You practised the same cut until the repetition stopped being boring and started being useful.",
		},
		Effects = { TechniqueMastery = 5, Health = -3, Smarts = 2 }
	},

	{
		Id = "ct_barrier_technique_quiet",
		Category = "Normal",
		MinAge = 8,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "Barrier Technique",
		Texts = {
			"You raised a curtain over a street and nobody inside it ever knew.",
			"Your work held all night and nobody mentioned it, which is how you knew it worked.",
			"You found a flaw in your own barrier before anyone tested it.",
		},
		Effects = { TechniqueMastery = 4, CursedEnergy = 4, Smarts = 3 }
	},

	{
		Id = "ct_tool_manipulation_reach",
		Category = "Normal",
		MinAge = 8,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "Tool Manipulation",
		Texts = {
			"You fought an entire exchange without closing the distance once.",
			"You lost a tool mid-fight and felt it go, like a finger.",
			"You learned the weight of every blade you own well enough to move them blind.",
		},
		Effects = { TechniqueMastery = 4, CursedEnergy = 4, Health = -2 }
	},

	{
		Id = "ct_shikigami_technique_first",
		Category = "Normal",
		MinAge = 6,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "Shikigami Technique",
		Texts = {
			"The paper held its shape for a full minute this time.",
			"What you made turned to look at you before it dissolved.",
			"You gave one a name, privately, and did not tell anyone.",
		},
		Effects = { CursedEnergy = 5, TechniqueMastery = 3, Happiness = 3 }
	},

	{
		Id = "ct_rot_technique_care",
		Category = "Normal",
		MinAge = 10,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "Rot Technique",
		Texts = {
			"Fruit spoils faster in your kitchen than anywhere else you have lived.",
			"You held something too long and it came apart in your hands.",
			"You learned to touch people with the back of your hand out of habit.",
		},
		Effects = { CursedEnergy = 6, Happiness = -5, Fear = 4 }
	},

	{
		Id = "ct_comedian_absurd",
		Category = "Normal",
		MinAge = 8,
		MaxAge = 90,
		Weight = 7,
		RequiredTechnique = "Comedian",
		Texts = {
			"Something impossible happened because it would have been funnier that way, and you were the only one who laughed.",
			"You made a joke and reality took it literally.",
			"You have stopped being surprised. Everyone around you has not.",
		},
		Effects = { CursedEnergy = 5, Happiness = 7, Smarts = -2 }
	},

	{
		Id = "ct_contractual_recreation_memory",
		Category = "Normal",
		MinAge = 10,
		MaxAge = 90,
		Weight = 8,
		RequiredTechnique = "Contractual Re-Creation",
		Texts = {
			"You spent a week memorising an object down to its flaws, because the flaws are the hard part.",
			"You recreated something perfectly and it felt hollow to hold.",
			"You realised your memory has become a storeroom rather than a memory.",
		},
		Effects = { Smarts = 6, TechniqueMastery = 3, CursedEnergy = 3 }
	},

	-- =====================================================================
	-- Update 28: the second half of life. Before this, not a single event in
	-- the database started after age 40 -- a character could live to ninety
	-- and the last fifty years drew from the same pool as their teens.
	-- Everything below only appears once a life has some distance behind it.
	-- =====================================================================

	{
		Id = "late_body_first_refusal",
		Category = "Normal",
		MinAge = 40,
		MaxAge = 70,
		Weight = 12,
		Texts = {
			"Your body did not answer as fast as you expected, for the first time. You noticed. Nobody else did, yet.",
			"You woke up stiff from a fight that would not have marked you ten years ago.",
			"You caught yourself planning around an injury instead of ignoring it.",
		},
		Effects = { Health = -6, Smarts = 4, Happiness = -4 }
	},

	{
		Id = "late_technique_still_sharp",
		Category = "Normal",
		MinAge = 42,
		MaxAge = 90,
		Weight = 11,
		RequiresTechnique = true,
		Texts = {
			"Your body has slowed and your technique has not. You have started relying on the half of you that is still young.",
			"You did in one motion what younger sorcerers needed three for, because you have stopped wasting any of them.",
			"You realised you are more dangerous now than at thirty, and that it has nothing to do with strength.",
		},
		Effects = { TechniqueMastery = 6, CursedEnergy = 4, Health = -3 }
	},

	{
		Id = "late_outlived_them",
		Category = "Normal",
		MinAge = 45,
		MaxAge = 90,
		Weight = 12,
		Texts = {
			"You went to another funeral and recognised almost nobody under forty.",
			"You are the oldest person in the room at briefings now. It happened without any announcement.",
			"Someone referred to a sorcerer you trained beside as history, and they were not wrong.",
		},
		Effects = { Happiness = -8, Smarts = 4, CursedResentment = 3 }
	},

	{
		Id = "late_asked_to_teach",
		Category = "Normal",
		MinAge = 44,
		MaxAge = 85,
		Weight = 12,
		Texts = {
			"They asked you to teach instead of deploy. You have not decided whether that is respect or retirement.",
			"A first year asked you a question you have been answering wrong for twenty years, and you finally noticed.",
			"You taught something you have never had to explain before, and understood it properly for the first time.",
		},
		Effects = { Smarts = 6, Reputation = 5, TechniqueMastery = 3 }
	},

	{
		Id = "late_cannot_stop",
		Category = "Normal",
		MinAge = 50,
		MaxAge = 90,
		Weight = 11,
		Texts = {
			"You had a clean opportunity to stop this year and did not take it.",
			"Someone asked when you plan to retire. You gave an answer that was not really an answer.",
			"You realised you have no idea who you would be without the work, and stopped thinking about it.",
		},
		Effects = { Happiness = -6, Reputation = 4, Health = -4 }
	},

	{
		Id = "late_name_outgrew_you",
		Category = "Normal",
		MinAge = 48,
		MaxAge = 90,
		Weight = 10,
		Texts = {
			"You were introduced by a reputation that no longer matches what you can actually do.",
			"Someone was frightened of you for something you did twenty years ago and have half forgotten.",
			"A rumour about you came back around, larger than when it left.",
		},
		Effects = { Reputation = 6, Fear = 5, Happiness = -3 }
	},

	{
		Id = "late_reckoning",
		Category = "Normal",
		MinAge = 55,
		MaxAge = 90,
		Weight = 11,
		Texts = {
			"You made a list, privately, of the ones you did not reach in time. It was longer than you expected.",
			"You accepted that some of what you did was simply wrong, and that no one is going to come and say so.",
			"A decision you made decades ago finally stopped keeping you awake. You were not sure that was an improvement.",
		},
		Effects = { Happiness = -9, Smarts = 6, CursedResentment = 4 }
	},

	{
		Id = "late_quiet_good_year",
		Category = "Normal",
		MinAge = 46,
		MaxAge = 90,
		Weight = 10,
		Texts = {
			"Nothing happened this year, and you were old enough to recognise that as a gift.",
			"You spent the year on small things and none of it was wasted.",
			"You slept well for most of the year. At your age that counts as an achievement.",
		},
		Effects = { Happiness = 10, Health = 5 }
	},

	{
		Id = "late_successor_question",
		Category = "Normal",
		MinAge = 50,
		MaxAge = 90,
		Weight = 11,
		Texts = {
			"You caught yourself assessing younger sorcerers for who could carry what you know.",
			"Someone asked who you are training to replace you. You did not have a name ready.",
			"You wrote down something you have never written down before, in case you do not get to say it.",
		},
		Effects = { Smarts = 5, Reputation = 4, Happiness = -3 }
	},

	{
		Id = "late_ce_plateau",
		Category = "Normal",
		MinAge = 52,
		MaxAge = 90,
		Weight = 10,
		Texts = {
			"Your cursed energy stopped growing this year. It had been slowing for a while and you had been pretending otherwise.",
			"You measured yourself honestly and found the number lower than last time.",
			"You have started spending cursed energy the way an old person spends money.",
		},
		Effects = { CursedEnergy = -4, Smarts = 5, Happiness = -5 }
	},

	-- Clan-specific late life
	{
		Id = "late_gojo_alone_at_top",
		Category = "Clan",
		MinAge = 40,
		MaxAge = 90,
		Weight = 12,
		RequiredOrigin = "Gojo Clan",
		Texts = {
			"There is nobody left who can correct you, and you have started to understand why that is dangerous.",
			"You realised you have not had a real conversation with an equal in over a decade.",
			"An elder who used to intimidate you asked for your approval on something. You gave it, and felt nothing.",
		},
		Effects = { Reputation = 8, Happiness = -9, Smarts = 4 }
	},

	{
		Id = "late_zenin_succession",
		Category = "Clan",
		MinAge = 42,
		MaxAge = 90,
		Weight = 12,
		RequiredOrigin = "Zenin Clan",
		Texts = {
			"The succession argument has started, and this time you are one of the people arguing.",
			"You were asked to rank the next generation by strength. You did it, and hated how easily the list came.",
			"A branch child was written off in front of you. You recognised the sentence from your own childhood.",
		},
		Effects = { ClanReputation = 7, Happiness = -7, Reputation = 3 }
	},

	{
		Id = "late_kenjaku_horizon",
		Category = "Clan",
		MinAge = 45,
		MaxAge = 90,
		Weight = 12,
		RequiredOrigin = "Kenjaku Clan",
		Texts = {
			"Age has never been the problem for your family. You have started thinking about the next body rather than the last years.",
			"You updated the plan in the archive and moved your own name one column across.",
			"You caught yourself measuring a stranger's skull and did not find it strange.",
		},
		Effects = { Smarts = 8, CursedResentment = 6, Happiness = -6 }
	},

	{
		Id = "late_nanami_arithmetic",
		Category = "Clan",
		MinAge = 40,
		MaxAge = 85,
		Weight = 12,
		RequiredOrigin = "Nanami Lineage",
		Texts = {
			"You calculated the years left again and this time the number was small enough to plan around.",
			"You told a younger sorcerer to leave this work while they still could. You meant it, and you stayed.",
			"You realised the retirement you have been describing for twenty years was never going to happen.",
		},
		Effects = { Money = 1600, Happiness = -8, Smarts = 5 }
	},

	{
		Id = "late_kusakabe_survivors",
		Category = "Clan",
		MinAge = 45,
		MaxAge = 90,
		Weight = 12,
		RequiredOrigin = "Kusakabe Lineage",
		Texts = {
			"You counted the students who are still alive and understood that the boring lessons were the ones that mattered.",
			"Somebody finally thanked you for teaching them how to run. It took them thirty years.",
			"You are old, and in this profession that is the entire argument for your method.",
		},
		Effects = { Happiness = 11, Reputation = 6, Health = 4 }
	},

	{
		Id = "late_civilian_gap_closed",
		Category = "Normal",
		MinAge = 45,
		MaxAge = 90,
		Weight = 11,
		RequiredOrigin = "Civilian Family",
		Texts = {
			"Your family finally stopped asking what you do. You are not sure when they gave up.",
			"You buried a relative who never once believed what you told them about the world.",
			"You went back to the street you grew up on and understood that you could not explain any of it to anyone there.",
		},
		Effects = { Happiness = -10, Smarts = 4 }
	},

	{
		Id = "late_geto_conclusion",
		Category = "Clan",
		MinAge = 40,
		MaxAge = 90,
		Weight = 12,
		RequiredOrigin = "Geto Lineage",
		Texts = {
			"You have been carrying the same question for twenty years and this year you stopped arguing with it.",
			"You met someone young who feels exactly what you felt at their age. You did not talk them out of it.",
			"You understood that the resentment did not grow. You simply stopped putting energy into denying it.",
		},
		Effects = { CursedResentment = 11, Smarts = 5, Happiness = -6 }
	},

	{
		Id = "late_morikage_grove",
		Category = "Clan",
		MinAge = 45,
		MaxAge = 90,
		Weight = 11,
		RequiredOrigin = "Morikage Clan",
		Texts = {
			"You were shown which row of the grove is yours. It has been reserved since you were born.",
			"You buried someone in the family grove and understood the ritual properly for the first time.",
			"You have started tending the grove without being asked. That is how the family knows.",
		},
		Effects = { CursedEnergy = 5, Happiness = -4, ClanReputation = 5 }
	},

	{
		Id = "late_hakari_run_ends",
		Category = "Clan",
		MinAge = 40,
		MaxAge = 90,
		Weight = 11,
		RequiredOrigin = "Hakari Lineage",
		Texts = {
			"The run finally broke, and you had known it would, and it still landed badly.",
			"You have enough money that the odds stopped being interesting. That was worse than losing.",
			"You went back to a game you used to love and felt nothing at all.",
		},
		Effects = { Money = -800, Happiness = -8, Smarts = 4 }
	},

	{
		Id = "late_technique_outlives_you",
		Category = "Normal",
		MinAge = 55,
		MaxAge = 90,
		Weight = 10,
		RequiresTechnique = true,
		Texts = {
			"You taught the shape of your technique to someone who will still be using it long after you stop.",
			"You realised the technique was never really yours. You are the part that ends.",
			"Someone described your technique to you, accurately, having never seen you use it.",
		},
		Effects = { TechniqueMastery = 5, Reputation = 5, Happiness = -4 }
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
			-- Update 31: barrier work is something you can study into. Same opening as in
			-- BitKaisenSituations, and LavieCovie for why.
			if eventData.RequiredTechnique ~= "Barrier Technique"
				or not BitKaisenStudies.IsAtLeast(stats, "barrier", "adept") then
				return false
			end
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

function BitKaisenLifeEvents.GetQuietYearText(stats, playerLocale)
	stats.RecentQuietTexts = stats.RecentQuietTexts or {}

	local sourceTexts = QuietYearTexts
	if playerLocale and playerLocale ~= "en" then
		local localized = BitKaisenLocale.getQuietYearTexts(playerLocale)
		if localized and #localized > 0 then
			sourceTexts = localized
		end
	end

	local available = {}
	for _, text in ipairs(sourceTexts) do
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
		available = sourceTexts
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
			local chosenIndex = nil

			if eventData.Texts and #eventData.Texts > 0 then
				chosenIndex = math.random(1, #eventData.Texts)
				chosenText = eventData.Texts[chosenIndex]
			end

			return {
				Id = eventData.Id,
				Category = eventData.Category,
				Text = chosenText,
				TextIndex = chosenIndex,
				Effects = eventData.Effects or {},
				-- Carried through so ApplyEvent can label WHY this event fired.
				-- Without the label a bloodline-only event is indistinguishable
				-- from a generic one, and the player never learns that their
				-- clan is shaping the life they are living.
				SourceOrigin = eventData.RequiredOrigin,
				SourceTechnique = eventData.RequiredTechnique,
			}
		end
	end

	return nil
end

function BitKaisenLifeEvents.ApplyEvent(stats, eventData, playerLocale)
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


	if effects.TechniqueMastery and hasTechnique(stats) then
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
	if playerLocale and playerLocale ~= "en" and eventData.Id and eventData.TextIndex then
		local translated = BitKaisenLocale.tEvent(playerLocale, eventData.Id, eventData.TextIndex)
		if translated then text = translated end
	end
	-- Label bloodline and technique events so the player can see that this
	-- happened because of who they were born as, not by chance. Prefixed
	-- rather than appended so it reads as a heading on the entry.
	if eventData.SourceOrigin then
		text = "<font color='#d9a441'><b>[ " .. string.upper(tostring(eventData.SourceOrigin)) .. " ]</b></font> " .. text
	elseif eventData.SourceTechnique then
		text = "<font color='#9b6dff'><b>[ " .. string.upper(tostring(eventData.SourceTechnique)) .. " ]</b></font> " .. text
	end

	if ceToolBonus > 0 then
		text ..= "\n<font color='#f0b955'><b>[ CURSED TOOL ]</b></font> " .. tostring(ceToolName or "Your equipped cursed tool") .. " stabilized the gain: <b>+" .. tostring(ceToolBonus) .. " bonus CE</b>."
	end
	return text
end

return BitKaisenLifeEvents
