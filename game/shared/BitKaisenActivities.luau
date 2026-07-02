-- ModuleScript: BitKaisenActivities
-- Location: ReplicatedStorage

local BitKaisenActivities = {}

BitKaisenActivities.Database = {
	{
		Id = "dev_awaken",
		Title = "DEV: Awaken Technique",
		Description = "Testing button. Forces your cursed technique to awaken.",
		MinAge = 0,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(150, 40, 150),
		LockedText = "",
		HideWhenLocked = true
	},

	{
		Id = "play_outside",
		Title = "Play Outside",
		Description = "Spend time outside and live like a normal kid while you still can.",
		MinAge = 0,
		MaxAge = 9,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(80, 120, 70),
		LockedText = "You are too old for this activity.",
		HideWhenLocked = true
	},

	{
		Id = "spend_time_family",
		Title = "Spend Time With Family",
		Description = "Spend time with the people connected to your early life.",
		MinAge = 0,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(130, 85, 45),
		LockedText = "",
		HideWhenLocked = true
	},

	{
		Id = "watch_shadows",
		Title = "Watch Strange Shadows",
		Description = "Focus on the shapes that move where no one else looks.",
		MinAge = 4,
		MaxAge = 12,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(70, 70, 110),
		LockedText = "You are not at the right age for this.",
		HideWhenLocked = true
	},

	{
		Id = "ask_about_curses",
		Title = "Ask About Curses",
		Description = "Ask questions about the strange things you keep seeing.",
		MinAge = 6,
		MaxAge = 13,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(80, 80, 140),
		LockedText = "You are not at the right age for this.",
		HideWhenLocked = true
	},

	{
		Id = "basic_school_study",
		Title = "Study Schoolwork",
		Description = "Focus on normal school and improve your general intelligence.",
		MinAge = 6,
		MaxAge = 18,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(55, 75, 150),
		LockedText = "You are not school-aged.",
		HideWhenLocked = true
	},

	{
		Id = "school_attend_class",
		Title = "Attend Class",
		Description = "Show up, pay attention, and take notes. Steady gains to performance and attendance.",
		MinAge = 6,
		MaxAge = 15,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		RequiresSchool = true,
		ButtonColor = Color3.fromRGB(55, 100, 170),
		LockedText = "You must be enrolled in school (ages 6-15).",
		HideWhenLocked = true
	},
	{
		Id = "school_study_exams",
		Title = "Study for Exams",
		Description = "Cram for upcoming exams. Large performance boost but costs happiness.",
		MinAge = 6,
		MaxAge = 15,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		RequiresSchool = true,
		ButtonColor = Color3.fromRGB(75, 60, 160),
		LockedText = "You must be enrolled in school (ages 6-15).",
		HideWhenLocked = true
	},
	{
		Id = "school_join_club",
		Title = "Join a Club",
		Description = "Join or participate in an extracurricular club. Boosts happiness and attendance.",
		MinAge = 8,
		MaxAge = 15,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		RequiresSchool = true,
		ButtonColor = Color3.fromRGB(50, 140, 100),
		LockedText = "You must be enrolled in school (ages 8-15).",
		HideWhenLocked = true
	},
	{
		Id = "school_skip",
		Title = "Skip School",
		Description = "Blow off school for the day. +Happiness but drops attendance and performance.",
		MinAge = 6,
		MaxAge = 15,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		RequiresSchool = true,
		ButtonColor = Color3.fromRGB(170, 55, 55),
		LockedText = "You must be enrolled in school (ages 6-15).",
		HideWhenLocked = true
	},

	{
		Id = "mentor_teach_class",
		Title = "Teach a Class",
		Description = "Teach young sorcerers about cursed energy theory and fundamentals.",
		MinAge = 20,
		MaxAge = 90,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		RequiresMentor = true,
		ButtonColor = Color3.fromRGB(55, 130, 200),
		LockedText = "You must be an active Jujutsu Mentor.",
		HideWhenLocked = true
	},
	{
		Id = "mentor_supervise_mission",
		Title = "Supervise Student Mission",
		Description = "Oversee students on a real mission. Risky but great XP for both of you.",
		MinAge = 20,
		MaxAge = 90,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		RequiresMentor = true,
		ButtonColor = Color3.fromRGB(65, 100, 170),
		LockedText = "You must be an active Jujutsu Mentor.",
		HideWhenLocked = true
	},
	{
		Id = "mentor_grade_students",
		Title = "Grade Students",
		Description = "Evaluate student progress and submit recommendations to the higher-ups.",
		MinAge = 20,
		MaxAge = 90,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		RequiresMentor = true,
		ButtonColor = Color3.fromRGB(80, 80, 160),
		LockedText = "You must be an active Jujutsu Mentor.",
		HideWhenLocked = true
	},
	{
		Id = "mentor_prodigy",
		Title = "Mentor a Prodigy",
		Description = "Take a promising student under your personal wing. High reward, high stakes.",
		MinAge = 20,
		MaxAge = 90,
		RequiresTechnique = true,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		RequiresMentor = true,
		ButtonColor = Color3.fromRGB(95, 75, 190),
		LockedText = "You must be an active Jujutsu Mentor with a cursed technique.",
		HideWhenLocked = true
	},

	{
		Id = "train_ce",
		Title = "Train Cursed Energy",
		Description = "Push your cursed energy reserves through raw training.",
		MinAge = 8,
		MaxAge = 70,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(90, 45, 140),
		LockedText = "You are not at the right age to train cursed energy properly.",
		HideWhenLocked = true
	},

	{
		Id = "physical_conditioning",
		Title = "Physical Conditioning",
		Description = "Build raw strength for basic attacks and critical-hit timing.",
		MinAge = 8,
		MaxAge = 80,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(145, 78, 45),
		LockedText = "You are not at the right age to physically condition.",
		HideWhenLocked = true
	},

	{
		Id = "study_theory",
		Title = "Study Jujutsu Theory",
		Description = "Read about curses, barriers, binding vows, and sorcerer history.",
		MinAge = 10,
		MaxAge = 80,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(55, 75, 150),
		LockedText = "You are not at the right age to understand jujutsu theory.",
		HideWhenLocked = true
	},

	{
		Id = "blackjack_table",
		Title = "Play 21 Card Game",
		Description = "Sit at a low-stakes 21 Card Game table. Wager $100 and try to beat the dealer without going over 21.",
		MinAge = 18,
		MaxAge = 100,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(36, 96, 72),
		LockedText = "You need to be at least 18 to gamble.",
		HideWhenLocked = true
	},

	{
		Id = "burglary_job",
		Title = "Burglary Job",
		Description = "Break into a marked house, grab cursed valuables, and escape before guards catch you.",
		MinAge = 18,
		MaxAge = 100,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(112, 76, 42),
		LockedText = "You need to be at least 18 to risk a burglary.",
		HideWhenLocked = true
	},

	{
		Id = "heirloom_search",
		Title = "Search For Heirloom",
		Description = "Search old family storage for a forgotten item before the moment passes.",
		MinAge = 8,
		MaxAge = 100,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(132, 96, 54),
		LockedText = "You need to be at least 8 to search family storage.",
		HideWhenLocked = true
	},

	{
		Id = "rct_memory_training",
		Title = "Learn RCT",
		Description = "Attempt a Simon-style reverse cursed technique memory drill. Complete the sequence to unlock RCT healing.",
		MinAge = 12,
		MaxAge = 100,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		MinCursedEnergy = 150,
		MinTechniqueMastery = 25,
		ButtonColor = Color3.fromRGB(74, 128, 146),
		LockedText = "You need to be a sorcerer with at least 150 CE and 25 Technique Mastery.",
		HideWhenLocked = false
	},

	{
		Id = "cursed_finger_hunt",
		Title = "Hunt Cursed Fingers",
		Description = "Track a sealed cursed finger through a dangerous snake-style search. Collect 20 total to unlock Sukuna choices.",
		MinAge = 10,
		MaxAge = 100,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(118, 48, 58),
		LockedText = "You need to be at least 10 to hunt cursed fingers.",
		HideWhenLocked = true
	},

	{
		Id = "consume_cursed_fingers",
		Title = "Consume 20 Fingers",
		Description = "Consume twenty cursed fingers and gamble your life against Sukuna's power.",
		MinAge = 12,
		MaxAge = 100,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(150, 38, 48),
		LockedText = "You need twenty cursed fingers.",
		HideWhenLocked = false
	},

	{
		Id = "sukuna_vessel_ritual",
		Title = "Find Sukuna Vessel",
		Description = "Use twenty cursed fingers to draw out a vessel and fight for control instead of eating them yourself.",
		MinAge = 12,
		MaxAge = 100,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(92, 54, 120),
		LockedText = "You need twenty cursed fingers.",
		HideWhenLocked = false
	},

	{
		Id = "expand_curse_knowledge",
		Title = "Expand Knowledge on Curses",
		Description = "Study curse classification, curse behavior, and how sorcerers track incidents.",
		MinAge = 16,
		MaxAge = 80,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(75, 55, 145),
		LockedText = "You need to be at least 16 to study curses seriously.",
		HideWhenLocked = true
	},

	{
		Id = "meditate",
		Title = "Meditate",
		Description = "Calm your mind and stabilize your cursed energy.",
		MinAge = 10,
		MaxAge = 90,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(60, 110, 130),
		LockedText = "You are not at the right age to meditate properly.",
		HideWhenLocked = true
	},

	{
		Id = "rest",
		Title = "Rest",
		Description = "Recover your body and clear your head.",
		MinAge = 0,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(45, 120, 75),
		LockedText = "",
		HideWhenLocked = true
	},

	{
		Id = "doctor",
		Title = "Visit Doctor",
		Description = "Spend money to recover your health.",
		MinAge = 0,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(120, 50, 50),
		LockedText = "",
		HideWhenLocked = true
	},

	{
		Id = "socialize",
		Title = "Socialize",
		Description = "Spend time around people instead of living like a curse in a basement.",
		MinAge = 4,
		MaxAge = 100,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(130, 85, 45),
		LockedText = "You are not at the right age to socialize properly.",
		HideWhenLocked = true
	},

	{
		Id = "curse_absorb_fear",
		Title = "Absorb Fear",
		Description = "Feed on nearby fear and negative emotion. Strong cursed energy gain, but your threat can rise.",
		MinAge = 8,
		MaxAge = 999,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		RequiresCurse = true,
		ButtonColor = Color3.fromRGB(120, 35, 70),
		LockedText = "Only curse lives can absorb fear this way.",
		HideWhenLocked = true
	},

	{
		Id = "curse_hide_presence",
		Title = "Hide Cursed Presence",
		Description = "Suppress your cursed energy so sorcerers have a harder time tracking you.",
		MinAge = 8,
		MaxAge = 999,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		RequiresCurse = true,
		ButtonColor = Color3.fromRGB(55, 55, 95),
		LockedText = "Only curse lives can hide cursed presence this way.",
		HideWhenLocked = true
	},

	{
		Id = "curse_hunt_remnants",
		Title = "Hunt Curse Remnants",
		Description = "Track weaker cursed remnants and absorb what they leave behind. Good growth, moderate risk.",
		MinAge = 10,
		MaxAge = 999,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		RequiresCurse = true,
		ButtonColor = Color3.fromRGB(115, 45, 120),
		LockedText = "Only curse lives can hunt curse remnants.",
		HideWhenLocked = true
	},

	{
		Id = "curse_lure_sorcerer",
		Title = "Lure a Sorcerer",
		Description = "Expose your cursed energy and bait a sorcerer into attacking. High risk, high reward.",
		MinAge = 16,
		MaxAge = 999,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		RequiresCurse = true,
		ButtonColor = Color3.fromRGB(150, 35, 45),
		LockedText = "Only older curse lives can bait sorcerers safely enough to try.",
		HideWhenLocked = true
	},


	{
		Id = "curse_claim_territory",
		Title = "Claim Territory",
		Description = "Move into a new haunt and build a local rumor around your cursed presence.",
		MinAge = 8,
		MaxAge = 999,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		RequiresCurse = true,
		ButtonColor = Color3.fromRGB(95, 45, 130),
		LockedText = "Only cursed spirit lives can claim territory.",
		HideWhenLocked = true
	},

	{
		Id = "curse_spread_rumor",
		Title = "Spread Rumor",
		Description = "Grow your urban legend. More fear means more power, but society may notice the pattern.",
		MinAge = 8,
		MaxAge = 999,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		RequiresCurse = true,
		ButtonColor = Color3.fromRGB(130, 40, 100),
		LockedText = "Only cursed spirit lives can spread rumors this way.",
		HideWhenLocked = true
	},

	{
		Id = "curse_feed_negative_emotion",
		Title = "Feed on Negative Emotion",
		Description = "Feed quietly from grief, dread, jealousy, and panic. Reliable CE gain with attention risk.",
		MinAge = 8,
		MaxAge = 999,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		RequiresCurse = true,
		ButtonColor = Color3.fromRGB(115, 30, 65),
		LockedText = "Only cursed spirit lives can feed on negative emotion.",
		HideWhenLocked = true
	},

	{
		Id = "practice_technique",
		Title = "Practice Cursed Technique",
		Description = "Refine your innate cursed technique and improve your Technique Mastery.",
		MinAge = 10,
		MaxAge = 85,
		RequiresTechnique = true,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(150, 70, 210),
		LockedText = "You need an awakened cursed technique before you can practice it.",
		HideWhenLocked = true
	},

	{
		Id = "apply_jujutsu_high",
		Title = "Apply to Jujutsu High",
		Description = "Try to enter the official jujutsu world.",
		MinAge = 16,
		MaxAge = 22,
		RequiresTechnique = true,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(120, 30, 30),
		LockedText = "You must be between 16 and 22 with a cursed technique.",
		HideWhenLocked = true
	},

	{
		Id = "jujutsu_affiliation_duty",
		Title = "Affiliation Duty",
		Description = "Take an official Jujutsu High duty to build standing, earn trust, and affect public reputation.",
		MinAge = 16,
		MaxAge = 85,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = true,
		ButtonColor = Color3.fromRGB(80, 105, 180),
		LockedText = "You need to be registered through Jujutsu High.",
		HideWhenLocked = true
	},

	{
		Id = "request_assistant",
		Title = "Request Assistant",
		Description = "Ask your affiliation to assign a field assistant who can help manage missions and technique training.",
		MinAge = 18,
		MaxAge = 85,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = true,
		ButtonColor = Color3.fromRGB(70, 125, 135),
		LockedText = "You need Jujutsu High standing before requesting an assistant.",
		HideWhenLocked = true
	},

	{
		Id = "train_with_assistant",
		Title = "Train With Assistant",
		Description = "Coordinate drills with your assistant to improve technique control and assistant reliability.",
		MinAge = 18,
		MaxAge = 85,
		RequiresTechnique = true,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = true,
		RequiresAssistant = true,
		ButtonColor = Color3.fromRGB(85, 140, 105),
		LockedText = "You need an assigned assistant first.",
		HideWhenLocked = true
	},

	{
		Id = "evolve_technique",
		Title = "Evolve Technique",
		Description = "Attempt to convert mastery into a new technique stage or higher application.",
		MinAge = 13,
		MaxAge = 95,
		RequiresTechnique = true,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		MinTechniqueMastery = 25,
		ButtonColor = Color3.fromRGB(170, 85, 220),
		LockedText = "You need an awakened technique and at least 25 Technique Mastery.",
		HideWhenLocked = true
	},

	{
		Id = "body_hop",
		Title = "Body Hop",
		Description = "Transplant your brain into a fresh young host, cheating death while keeping your cursed energy, technique, and knowledge intact.",
		MinAge = 25,
		MaxAge = 120,
		RequiresTechnique = true,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(120, 40, 160),
		LockedText = "Evolve Brain Transplant to its Body Hopping stage first.",
		HideWhenLocked = true
	},

	{
		Id = "jujutsu_school_event",
		Title = "Jujutsu High Event",
		Description = "Attend a school event, meet peers, and build your Jujutsu High popularity.",
		MinAge = 16,
		MaxAge = 24,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = true,
		ButtonColor = Color3.fromRGB(85, 110, 190),
		LockedText = "You need to be enrolled in Jujutsu High.",
		HideWhenLocked = true
	},

	{
		Id = "goodwill_event",
		Title = "Goodwill Event",
		Description = "Represent your school in a Tokyo/Kyoto exchange contest. Strong rewards, real injury risk.",
		MinAge = 16,
		MaxAge = 24,
		RequiresTechnique = true,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = true,
		MinTechniqueMastery = 20,
		ButtonColor = Color3.fromRGB(185, 120, 45),
		LockedText = "Requires Age 16-24, Jujutsu High enrollment, a cursed technique, and 20 Technique Mastery.",
		HideWhenLocked = false
	},

	{
		Id = "underground_tournament",
		Title = "Underground Tournament",
		Description = "Enter a three-round bracket against randomized sorcerers, rogues, and clan fighters.",
		MinAge = 16,
		MaxAge = 95,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(145, 85, 45),
		LockedText = "You need to be an adult sorcerer.",
		HideWhenLocked = true
	},

	{
		Id = "bulk_train_ce",
		Title = "Bulk Train CE",
		Description = "Run several cursed-energy training sessions at once. Saves clicks, costs more health.",
		MinAge = 10,
		MaxAge = 85,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(100, 65, 160),
		LockedText = "You need to be at least 10.",
		HideWhenLocked = true
	},

	{
		Id = "bulk_practice_technique",
		Title = "Bulk Practice Technique",
		Description = "Practice your cursed technique five times in one action with compressed rewards and fatigue.",
		MinAge = 10,
		MaxAge = 85,
		RequiresTechnique = true,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(150, 80, 210),
		LockedText = "You need an awakened cursed technique.",
		HideWhenLocked = true
	},

	{
		Id = "bulk_mission_sweep",
		Title = "Bulk Mission Sweep",
		Description = "Run a chain of minor assignments in one action. Counts as multiple mission outcomes.",
		MinAge = 16,
		MaxAge = 85,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(145, 45, 55),
		LockedText = "You need to be a sorcerer and at least 16.",
		HideWhenLocked = true
	},

	{
		Id = "premium_select_clan",
		Title = "Select Featured Clan",
		Description = "Spend $5000 to lock in a featured clan option for this life path.",
		MinAge = 0,
		MaxAge = 85,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		RequiresMoney = 5000,
		ButtonColor = Color3.fromRGB(190, 145, 55),
		LockedText = "You need $5000 to select a featured clan.",
		HideWhenLocked = false
	},

	{
		Id = "premium_select_ct",
		Title = "Select Featured CT",
		Description = "Spend $7500 to choose a featured cursed technique if you do not already have one.",
		MinAge = 0,
		MaxAge = 85,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		RequiresMoney = 7500,
		ButtonColor = Color3.fromRGB(150, 95, 210),
		LockedText = "You need $7500 and no awakened cursed technique.",
		HideWhenLocked = false
	},

	{
		Id = "era_lore_encounter",
		Title = "Era Lore Encounter",
		Description = "Seek a dangerous era-specific encounter. Heian/Edo/Modern paths give different outcomes.",
		MinAge = 16,
		MaxAge = 95,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(120, 95, 75),
		LockedText = "You need to be an adult sorcerer.",
		HideWhenLocked = true
	},

	{
		Id = "star_plasma_guard",
		Title = "Star Plasma Guard",
		Description = "Protect a high-value vessel through a dangerous escort arc. High reward, high assassination risk.",
		MinAge = 16,
		MaxAge = 45,
		RequiresTechnique = true,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		MinTechniqueMastery = 25,
		ButtonColor = Color3.fromRGB(80, 140, 190),
		LockedText = "You need an awakened technique and 25 Technique Mastery.",
		HideWhenLocked = true
	},

	{
		Id = "assassination_attempt",
		Title = "Assassination Attempt",
		Description = "Investigate rumors that someone has put a price on your head.",
		MinAge = 16,
		MaxAge = 90,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(170, 50, 65),
		LockedText = "You need to be an adult sorcerer.",
		HideWhenLocked = true
	},

	{
		Id = "assistant_manage_dojo",
		Title = "Assistant: Manage Dojo",
		Description = "Send your assistant to handle clan and dojo paperwork, repairs, and schedules.",
		MinAge = 18,
		MaxAge = 95,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = true,
		RequiresAssistant = true,
		ButtonColor = Color3.fromRGB(80, 125, 130),
		LockedText = "You need an assigned assistant.",
		HideWhenLocked = true
	},

	{
		Id = "assistant_train_npcs",
		Title = "Assistant: Train NPCs",
		Description = "Have your assistant run drills for students, wards, or younger sorcerers connected to you.",
		MinAge = 18,
		MaxAge = 95,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = true,
		RequiresAssistant = true,
		ButtonColor = Color3.fromRGB(90, 145, 95),
		LockedText = "You need an assigned assistant.",
		HideWhenLocked = true
	},

	{
		Id = "assistant_field_support",
		Title = "Assistant: Field Support",
		Description = "Bring your assistant on a controlled assignment for mission support and relationship growth.",
		MinAge = 18,
		MaxAge = 95,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = true,
		RequiresAssistant = true,
		ButtonColor = Color3.fromRGB(95, 115, 180),
		LockedText = "You need an assigned assistant.",
		HideWhenLocked = true
	},

	{
		Id = "fame_public_audience",
		Title = "Public Reputation Move",
		Description = "Use your Fame to sway NPC reactions, pull support, and turn reputation into opportunity.",
		MinAge = 16,
		MaxAge = 95,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		MinFame = 20,
		ButtonColor = Color3.fromRGB(210, 160, 70),
		LockedText = "You need at least 20 Fame.",
		HideWhenLocked = true
	},

	{
		Id = "fear_intimidate_network",
		Title = "Fear Network",
		Description = "Use your Fear to intimidate enemies, lower resistance, and risk attracting hunters.",
		MinAge = 16,
		MaxAge = 95,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		MinFear = 20,
		ButtonColor = Color3.fromRGB(150, 45, 65),
		LockedText = "You need at least 20 Fear.",
		HideWhenLocked = true
	},

	{
		Id = "world_reputation_cleanup",
		Title = "Reputation Cleanup",
		Description = "Use contacts, support, and careful messaging to reduce hunter pressure and copycat fallout.",
		MinAge = 16,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		RequiresReputationCleanup = true,
		ButtonColor = Color3.fromRGB(90, 130, 160),
		LockedText = "You need hunter pressure, world pressure, or copycat fallout to clean up.",
		HideWhenLocked = true
	},

	{
		Id = "heian_blood_moon",
		Title = "Heian Blood Moon",
		Description = "A brutal Heian-era night where curses and sorcerer clans clash openly.",
		MinAge = 16,
		MaxAge = 95,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		RequiresEra = "Heian Era",
		ButtonColor = Color3.fromRGB(130, 45, 75),
		LockedText = "This event belongs to the Heian Era.",
		HideWhenLocked = true
	},

	{
		Id = "edo_lightning_duel",
		Title = "Edo Lightning Duel",
		Description = "Face a Kashimo-like challenger in an Edo-era duel with high danger and high mastery gain.",
		MinAge = 16,
		MaxAge = 95,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		RequiresEra = "Edo Era",
		ButtonColor = Color3.fromRGB(115, 125, 190),
		LockedText = "This event belongs to the Edo Era.",
		HideWhenLocked = true
	},

	{
		Id = "stabilize_cursed_object_anchor",
		Title = "Stabilize Cursed Object Anchor",
		Description = "Bind cursed-object residue into a stable anchor for reincarnation and cursed-object systems.",
		MinAge = 16,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		MinCursedObjectAnchorProgress = 25,
		ButtonColor = Color3.fromRGB(115, 65, 155),
		LockedText = "You need 25 cursed object anchor progress.",
		HideWhenLocked = true
	},

	{
		Id = "idle_add_trait",
		Title = "Idle: Shape Trait",
		Description = "Use Idle Transfiguration to add a controlled soul-shape trait. Powerful but costly.",
		MinAge = 13,
		MaxAge = 95,
		RequiresTechnique = true,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		RequiresSpecificTechnique = "Idle Transfiguration",
		MinTechniqueMastery = 50,
		ButtonColor = Color3.fromRGB(165, 75, 185),
		LockedText = "Requires Idle Transfiguration and 50 Technique Mastery.",
		HideWhenLocked = true
	},

	{
		Id = "idle_remove_trait",
		Title = "Idle: Remove Trait",
		Description = "Use Idle Transfiguration to cut away an unwanted trait at heavy health and happiness cost.",
		MinAge = 13,
		MaxAge = 95,
		RequiresTechnique = true,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		RequiresSpecificTechnique = "Idle Transfiguration",
		MinTechniqueMastery = 65,
		ButtonColor = Color3.fromRGB(120, 55, 145),
		LockedText = "Requires Idle Transfiguration and 65 Technique Mastery.",
		HideWhenLocked = true
	},

	{
		Id = "black_flash_training",
		Title = "Black Flash Training",
		Description = "High-risk timing training. Strong reward, but it can hurt you.",
		MinAge = 16,
		MaxAge = 45,
		RequiresTechnique = true,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = true,
		ButtonColor = Color3.fromRGB(160, 70, 180),
		LockedText = "You need to be 16+, enrolled in Jujutsu High, and still in fighting shape.",
		HideWhenLocked = true
	},

	{
		Id = "mission_review",
		Title = "Review Mission Records",
		Description = "Study your past assignments and look for mistakes in your decisions.",
		MinAge = 16,
		MaxAge = 80,
		RequiresTechnique = true,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = true,
		ButtonColor = Color3.fromRGB(95, 80, 150),
		LockedText = "You need to be older and enrolled in Jujutsu High.",
		HideWhenLocked = true
	},

	{
		Id = "mentor_younger_sorcerers",
		Title = "Mentor Younger Sorcerers",
		Description = "Help younger sorcerers understand cursed energy and survival.",
		MinAge = 25,
		MaxAge = 90,
		RequiresTechnique = true,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(120, 100, 45),
		LockedText = "You need more age and experience before mentoring others.",
		HideWhenLocked = true
	},

	{
		Id = "retirement_reflection",
		Title = "Reflect on Your Life",
		Description = "Look back on the people, curses, and choices that shaped you.",
		MinAge = 60,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(90, 90, 115),
		LockedText = "This is for later years.",
		HideWhenLocked = true
	},

	{
		Id = "society_influence_push",
		Title = "Society Influence Push",
		Description = "Turn Fame, missions, and affiliation standing into Jujutsu Society influence.",
		MinAge = 25,
		MaxAge = 110,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		MinFame = 35,
		ButtonColor = Color3.fromRGB(190, 145, 65),
		LockedText = "You need 35 Fame and a mature sorcerer career.",
		HideWhenLocked = true
	},

	{
		Id = "clan_leadership_council",
		Title = "Clan Leadership Council",
		Description = "Use reputation and clan standing to claim leadership or strengthen clan politics.",
		MinAge = 30,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		MinSocietyInfluence = 20,
		ButtonColor = Color3.fromRGB(145, 100, 55),
		LockedText = "You need 20 Society Influence and enough age to handle clan politics.",
		HideWhenLocked = true
	},

	{
		Id = "dojo_legacy_ceremony",
		Title = "Dojo Legacy Ceremony",
		Description = "Formalize your dojo legacy, successors, and long-term student reputation.",
		MinAge = 35,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		RequiresDojoStudents = true,
		MinDojoLegacy = 10,
		ButtonColor = Color3.fromRGB(95, 135, 105),
		LockedText = "You need students and 10 Dojo Legacy.",
		HideWhenLocked = true
	},

	{
		Id = "clan_merge_request",
		Title = "Send Clan Merge Request",
		Description = "Ask another dojo/clan to merge influence with yours. Acceptance scales from dojo reputation and political power.",
		MinAge = 30,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		RequiresDojoStudents = true,
		MinSocietyInfluence = 15,
		ButtonColor = Color3.fromRGB(150, 105, 70),
		LockedText = "You need a dojo, students, and 15 Society Influence.",
		HideWhenLocked = true
	},

	{
		Id = "dojo_raid_defense",
		Title = "Dojo Raid Defense",
		Description = "A rival raid threatens your dojo. Win the defense drill to prevent collapse damage.",
		MinAge = 25,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		RequiresDojoStudents = true,
		MinDojoLegacy = 5,
		ButtonColor = Color3.fromRGB(155, 55, 65),
		LockedText = "You need students and 5 Dojo Legacy.",
		HideWhenLocked = true
	},

	{
		Id = "dojo_recovery_work",
		Title = "Dojo Recovery Work",
		Description = "Repair raid damage, pay down recovery debt, and stabilize a collapsed dojo.",
		MinAge = 25,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		RequiresDojoStudents = true,
		RequiresDojoRecovery = true,
		ButtonColor = Color3.fromRGB(85, 125, 145),
		LockedText = "Your dojo needs raid damage, recovery debt, or collapse recovery work.",
		HideWhenLocked = true
	},

	{
		Id = "rogue_student_incident",
		Title = "Rogue Student Incident",
		Description = "A student may be drifting into dangerous behavior. Confront them before they become a threat.",
		MinAge = 25,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		RequiresDojoStudents = true,
		MinDojoLegacy = 5,
		ButtonColor = Color3.fromRGB(120, 70, 120),
		LockedText = "You need an established dojo and students.",
		HideWhenLocked = true
	},
	{
		Id = "physical_conditioning",
		Title = "Physical Conditioning",
		Description = "Train your body so missions do not break you as easily.",
		MinAge = 10,
		MaxAge = 75,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(95, 95, 120),
		LockedText = "You are not at the right age for serious conditioning.",
		HideWhenLocked = true
	},

	{
		Id = "barrier_drills",
		Title = "Barrier Drills",
		Description = "Practice basic curtains, veil reading, and barrier response timing.",
		MinAge = 16,
		MaxAge = 90,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(85, 65, 150),
		LockedText = "You need to be a sorcerer to practice barrier drills.",
		HideWhenLocked = true
	},

	{
		Id = "patrol_city",
		Title = "Patrol the City",
		Description = "Walk the streets and respond to weak curse traces before they grow.",
		MinAge = 14,
		MaxAge = 90,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(70, 90, 135),
		LockedText = "You need to be a sorcerer to patrol properly.",
		HideWhenLocked = true
	},

	{
		Id = "cursed_tool_practice",
		Title = "Cursed Tool Practice",
		Description = "Practice with cursed tools and sharpen your mission instincts.",
		MinAge = 13,
		MaxAge = 90,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(115, 75, 60),
		LockedText = "You need sorcerer-level awareness to practice cursed tools safely.",
		HideWhenLocked = true
	},

	{
		Id = "student_training_review",
		Title = "Review Student Training",
		Description = "Watch over your dojo students and correct sloppy cursed energy habits.",
		MinAge = 25,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(120, 80, 120),
		LockedText = "You need more experience before reviewing students.",
		HideWhenLocked = true
	},

	{
		Id = "clan_admin",
		Title = "Manage Clan Affairs",
		Description = "Handle clan records, student issues, and the reputation of your dojo.",
		MinAge = 25,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(130, 95, 55),
		LockedText = "You are not ready to manage clan affairs.",
		HideWhenLocked = true
	},

	{
		Id = "domain_foundation_study",
		Title = "Study Domain Foundations",
		Description = "Study the theory behind barrier expansion and innate technique territory.",
		MinAge = 18,
		MaxAge = 90,
		RequiresTechnique = true,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(120, 65, 160),
		LockedText = "You need a cursed technique before studying domain foundations.",
		HideWhenLocked = true
	},

	{
		Id = "binding_vow_research",
		Title = "Research Binding Vows",
		Description = "Study restrictions, vows, and the cost of forcing cursed energy to obey.",
		MinAge = 16,
		MaxAge = 90,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(80, 70, 125),
		LockedText = "You need to be a sorcerer to research binding vows safely.",
		HideWhenLocked = true
	}
	,
	{
		Id = "join_other_dojo",
		Title = "Join Another Dojo",
		Description = "Apply to train under an established dojo instead of founding your own right away.",
		MinAge = 12,
		MaxAge = 90,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(95, 95, 145),
		LockedText = "You need sorcerer-level awareness before a dojo will accept you.",
		HideWhenLocked = true
	},

	{
		Id = "train_at_joined_dojo",
		Title = "Train at Your Dojo",
		Description = "Use your joined dojo's instructors, sparring partners, and cursed energy drills to grow faster.",
		MinAge = 12,
		MaxAge = 90,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(75, 90, 150),
		LockedText = "You need sorcerer-level awareness before dojo training matters.",
		HideWhenLocked = true
	},

	{
		Id = "dojo_assignment",
		Title = "Dojo Assignment",
		Description = "Take a small request through your joined dojo for money, reputation, and practical experience.",
		MinAge = 14,
		MaxAge = 90,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(120, 80, 75),
		LockedText = "You need sorcerer-level awareness before a dojo will send you out.",
		HideWhenLocked = true
	},

	{
		Id = "leave_joined_dojo",
		Title = "Leave Joined Dojo",
		Description = "Cut ties with the dojo you joined and return to independent training.",
		MinAge = 12,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(90, 70, 70),
		LockedText = "You are not ready for dojo politics yet.",
		HideWhenLocked = true
	},

	{
		Id = "curse_user_black_market",
		Title = "Black Market Contact",
		Description = "Meet an underground broker. Good money and rare information, but society will notice if you keep going rogue.",
		MinAge = 16,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresCurseUser = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(105, 45, 55),
		LockedText = "Only Curse Users can use black market contacts.",
		HideWhenLocked = true
	},

	{
		Id = "black_market_shop",
		Title = "Visit Black Market",
		Description = "Browse illegal cursed tools and contraband curse items. Buying or selling raises your Wanted Level.",
		MinAge = 16,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresCurseUser = false,
		RequiresJujutsuHigh = false,
		OpensPanel = "blackmarket",
		ButtonColor = Color3.fromRGB(120, 45, 130),
		LockedText = "You need to be at least 16 to access the black market.",
		HideWhenLocked = true
	},

	{
		Id = "curse_user_hide_society",
		Title = "Hide From Jujutsu Society",
		Description = "Lay low, erase tracks, and keep scouts from connecting incidents back to you.",
		MinAge = 16,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresCurseUser = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(55, 55, 80),
		LockedText = "Only Curse Users need to hide from Jujutsu Society this way.",
		HideWhenLocked = true
	},

	{
		Id = "curse_user_illegal_job",
		Title = "Illegal Curse Job",
		Description = "Take a forbidden job for fast money. High reward, but high risk.",
		MinAge = 16,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresCurseUser = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(145, 45, 45),
		LockedText = "Only Curse Users can take illegal curse jobs.",
		HideWhenLocked = true
	},

	{
		Id = "curse_user_secret_training",
		Title = "Train in Secret",
		Description = "Train outside official oversight. Strong growth, but your cursed energy becomes harder to hide.",
		MinAge = 14,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresCurseUser = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(120, 60, 145),
		LockedText = "Only Curse Users can use this secret training path.",
		HideWhenLocked = true
	},

	{
		Id = "curse_user_threaten_informant",
		Title = "Threaten Informant",
		Description = "Force information out of someone connected to the underground curse world.",
		MinAge = 16,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = true,
		RequiresCurseUser = true,
		RequiresJujutsuHigh = false,
		ButtonColor = Color3.fromRGB(120, 35, 35),
		LockedText = "Only Curse Users can lean on informants this way.",
		HideWhenLocked = true
	},

	{
		Id = "cult_found",
		Title = "Found a Cursed Cult",
		Description = "Gather your first followers and declare a cursed organization of your own. There is no going back once word spreads.",
		MinAge = 16,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresCurseUser = false,
		RequiresJujutsuHigh = false,
		RequiresCultEligible = true,
		ButtonColor = Color3.fromRGB(90, 20, 30),
		LockedText = "Only Curse Users or rogue sorcerers with a big enough Wanted Level can found a cult.",
		HideWhenLocked = true
	},

	{
		Id = "cult_recruit_initiate",
		Title = "Recruit Initiate",
		Description = "Draw a vulnerable or curious soul into your cult's lowest rank.",
		MinAge = 16,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresCurseUser = false,
		RequiresJujutsuHigh = false,
		RequiresCultFounded = true,
		ButtonColor = Color3.fromRGB(90, 20, 30),
		LockedText = "You need to found a cult before recruiting initiates.",
		HideWhenLocked = true
	},

	{
		Id = "cult_binding_ritual",
		Title = "Binding Ritual",
		Description = "Bind a member closer through fear and devotion. Small backlash risk.",
		MinAge = 16,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresCurseUser = false,
		RequiresJujutsuHigh = false,
		RequiresCultFounded = true,
		ButtonColor = Color3.fromRGB(90, 20, 30),
		LockedText = "You need to found a cult before performing rituals.",
		HideWhenLocked = true
	},

	{
		Id = "cult_collect_tribute",
		Title = "Collect Tribute",
		Description = "Tax the membership for the treasury. Loyalty suffers.",
		MinAge = 16,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresCurseUser = false,
		RequiresJujutsuHigh = false,
		RequiresCultFounded = true,
		ButtonColor = Color3.fromRGB(90, 20, 30),
		LockedText = "You need to found a cult before collecting tribute.",
		HideWhenLocked = true
	},

	{
		Id = "cult_expand_territory",
		Title = "Expand Territory",
		Description = "Push the cult's claim into new ground. Wanted Level rises.",
		MinAge = 16,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresCurseUser = false,
		RequiresJujutsuHigh = false,
		RequiresCultFounded = true,
		ButtonColor = Color3.fromRGB(90, 20, 30),
		LockedText = "You need to found a cult before expanding territory.",
		HideWhenLocked = true
	},

	{
		Id = "cult_curse_fusion",
		Title = "Curse Fusion",
		Description = "Consume a low-ranking member for power. Dark, permanent, irreversible.",
		MinAge = 16,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresCurseUser = false,
		RequiresJujutsuHigh = false,
		RequiresCultFounded = true,
		ButtonColor = Color3.fromRGB(60, 10, 15),
		LockedText = "You need cult initiates before you can perform a curse fusion.",
		HideWhenLocked = true
	},

	{
		Id = "dojo_send_students_patrol",
		Title = "Send Students on Patrol",
		Description = "Send dojo students to handle minor curse traces. Their grade, CE, CT, and potential affect the result.",
		MinAge = 25,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		RequiresGrandDojo = true,
		RequiresDojoStudents = true,
		ButtonColor = Color3.fromRGB(75, 95, 145),
		LockedText = "You need a founded clan, Grand Dojo, and students before sending patrols.",
		HideWhenLocked = true
	},

	{
		Id = "dojo_grade_review",
		Title = "Review Student Grades",
		Description = "Evaluate student growth and push promising recruits toward higher grades.",
		MinAge = 25,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		RequiresGrandDojo = true,
		RequiresDojoStudents = true,
		ButtonColor = Color3.fromRGB(115, 85, 155),
		LockedText = "You need a founded clan, Grand Dojo, and students before grading progress.",
		HideWhenLocked = true
	},

	{
		Id = "dojo_pair_sparring",
		Title = "Pair Student Sparring",
		Description = "Pair students by grade and potential. Great growth, but it damages dojo condition.",
		MinAge = 25,
		MaxAge = 120,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		RequiresGrandDojo = true,
		RequiresDojoStudents = true,
		ButtonColor = Color3.fromRGB(145, 80, 95),
		LockedText = "You need a founded clan, Grand Dojo, and students before running sparring pairs.",
		HideWhenLocked = true
	},

	{
		Id = "curse_stalk_haunt",
		Title = "Stalk Your Haunt",
		Description = "Move through your territory and grow the fear attached to your curse rumor.",
		MinAge = 8,
		MaxAge = 999,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		RequiresCurse = true,
		ButtonColor = Color3.fromRGB(105, 35, 90),
		LockedText = "Only cursed spirit lives can stalk a haunt this way.",
		HideWhenLocked = true
	},

	{
		Id = "curse_confuse_trackers",
		Title = "Confuse Trackers",
		Description = "Scatter your cursed energy trail to make sorcerers less certain about your location.",
		MinAge = 8,
		MaxAge = 999,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		RequiresCurse = true,
		ButtonColor = Color3.fromRGB(60, 55, 110),
		LockedText = "Only cursed spirit lives need to confuse trackers this way.",
		HideWhenLocked = true
	},

	{
		Id = "curse_force_evolution",
		Title = "Force Evolution",
		Description = "Twist your cursed body toward its next form. Strong growth, painful risk.",
		MinAge = 12,
		MaxAge = 999,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		RequiresCurse = true,
		ButtonColor = Color3.fromRGB(145, 45, 135),
		LockedText = "Only cursed spirit lives can force evolution.",
		HideWhenLocked = true
	},

	{
		Id = "curse_devour_remnant",
		Title = "Devour Curse Remnant",
		Description = "Consume unstable cursed remains for CE and evolution progress. It can backfire.",
		MinAge = 10,
		MaxAge = 999,
		RequiresTechnique = false,
		RequiresSorcerer = false,
		RequiresJujutsuHigh = false,
		RequiresCurse = true,
		ButtonColor = Color3.fromRGB(135, 35, 80),
		LockedText = "Only cursed spirit lives can devour curse remnants.",
		HideWhenLocked = true
	}


}

local function isSorcerer(stats)
	if not stats then
		return false
	end

	if stats.Grade and stats.Grade ~= "Non-Sorcerer" then
		return true
	end

	if stats.CursedTechnique and stats.CursedTechnique ~= "None" then
		return true
	end

	if stats.CursedEnergy and stats.CursedEnergy >= 35 then
		return true
	end

	return false
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

local function ownsAssetById(stats, assetId)
	if not stats or type(stats.Assets) ~= "table" then
		return false
	end

	for _, asset in ipairs(stats.Assets) do
		if typeof(asset) == "table" then
			if asset.Id == assetId or asset.BaseId == assetId then
				return true
			end
		elseif asset == assetId then
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

local function isCurseLife(stats)
	if not stats then
		return false
	end

	local origin = tostring(stats.Origin or stats.Clan or "")
	local originCategory = tostring(stats.OriginCategory or "")
	local familyType = tostring(stats.FamilyType or "")
	local curseType = tostring(stats.CurseType or "")

	return stats.IsCurse == true
		or tostring(stats.Race or "") == "Cursed Spirit"
		or tostring(stats.Race or "") == "Curse"
		or origin == "Cursed Womb"
		or origin == "Cursed Spirit"
		or origin == "Vengeful Spirit Rebirth"
		or originCategory == "Race"
		or familyType == "Race"
		or familyType == "Cursed Spirit"
		or curseType == "Cursed Womb"
		or curseType == "Death Painting"
		or curseType == "Cursed Spirit"
		or string.find(curseType, "Cursed Spirit", 1, true) ~= nil
end

function BitKaisenActivities.GetActivityById(id)
	for _, activity in ipairs(BitKaisenActivities.Database) do
		if activity.Id == id then
			return activity
		end
	end

	return nil
end

function BitKaisenActivities.CanDoActivity(stats, activity)
	if not stats or not activity then
		return false, "Invalid activity."
	end

	local age = stats.Age or 0

	if activity.Id == "dev_awaken" then
		if stats.CursedTechnique and stats.CursedTechnique ~= "None" then
			return false, "You already awakened a cursed technique."
		end

		return true, nil
	end

	if activity.RequiresCurse and not isCurseLife(stats) then
		return false, activity.LockedText ~= "" and activity.LockedText or "Only curse lives can do this."
	end

	if activity.RequiresCurseUser and not isCurseUser(stats) then
		return false, activity.LockedText ~= "" and activity.LockedText or "Only Curse Users can do this."
	end

	if activity.RequiresCultEligible then
		if stats.CultFounded == true then
			return false, "You already lead a cursed organization."
		end
		if stats.ClanFounded == true then
			return false, "You cannot found a cult while leading a legitimate clan."
		end
		local societyStatus = tostring(stats.SocietyStatus or "")
		local eligible = isCurseUser(stats) or societyStatus == "Rogue Sorcerer" or societyStatus == "Unregistered Sorcerer"
		if not eligible then
			return false, activity.LockedText ~= "" and activity.LockedText or "Only Curse Users or rogue sorcerers can found a cult."
		end
		if (tonumber(stats.WantedLevel) or 0) < 3 then
			return false, "You need a bigger criminal reputation before anyone will follow you into a cult."
		end
	end

	if activity.RequiresCultFounded and stats.CultFounded ~= true then
		return false, activity.LockedText ~= "" and activity.LockedText or "You need to found a cult first."
	end

	if activity.RequiresGrandDojo then
		if stats.ClanFounded ~= true or not ownsAssetById(stats, "grand_dojo") then
			return false, activity.LockedText ~= "" and activity.LockedText or "You need a founded clan and Grand Dojo."
		end
	end

	if activity.RequiresDojoStudents and countDojoStudents(stats) <= 0 then
		return false, activity.LockedText ~= "" and activity.LockedText or "You need dojo students first."
	end

	if activity.RequiresDojoRecovery then
		local condition = tonumber(stats.DojoCondition) or 100
		local debt = tonumber(stats.DojoRecoveryDebt) or 0
		if condition >= 100 and debt <= 0 and tostring(stats.DojoRank or "") ~= "Collapsed Dojo" then
			return false, activity.LockedText ~= "" and activity.LockedText or "Your dojo does not need recovery work."
		end
	end

	if activity.RequiresReputationCleanup then
		local hunterPressure = tonumber(stats.HunterPressure) or 0
		local worldPressure = tonumber(stats.WorldPressure) or 0
		local copycats = tonumber(stats.CopycatIncidents) or 0
		if hunterPressure < 10 and worldPressure < 35 and copycats <= 0 then
			return false, activity.LockedText ~= "" and activity.LockedText or "Your public reputation is stable right now."
		end
	end

	if activity.MinAge and age < activity.MinAge then
		return false, activity.LockedText ~= "" and activity.LockedText or "You are too young."
	end

	if activity.MaxAge and age > activity.MaxAge then
		return false, activity.LockedText ~= "" and activity.LockedText or "You are too old."
	end

	if activity.RequiresTechnique then
		if not stats.CursedTechnique or stats.CursedTechnique == "None" then
			return false, activity.LockedText ~= "" and activity.LockedText or "You need a cursed technique."
		end
	end

	if activity.RequiresSorcerer and not isSorcerer(stats) then
		return false, activity.LockedText ~= "" and activity.LockedText or "You are not a sorcerer."
	end

	if activity.RequiresJujutsuHigh and not stats.InJujutsuHigh then
		return false, activity.LockedText ~= "" and activity.LockedText or "You are not enrolled in Jujutsu High."
	end

	if activity.RequiresSchool then
		local stage = tostring(stats.SchoolStage or "None")
		if stage == "None" or stage == "Graduated" then
			return false, activity.LockedText ~= "" and activity.LockedText or "You must be enrolled in school."
		end
	end

	if activity.RequiresMentor and stats.IsJujutsuMentor ~= true then
		return false, activity.LockedText ~= "" and activity.LockedText or "You must be an active Jujutsu Mentor."
	end

	if activity.RequiresEra then
		local currentEra = tostring(stats.CurrentEra or stats.Era or (typeof(stats.BirthPath) == "table" and stats.BirthPath.Era) or "Modern Era")
		if currentEra ~= activity.RequiresEra then
			return false, activity.LockedText ~= "" and activity.LockedText or "Wrong era."
		end
	end

	if activity.RequiresSpecificTechnique and tostring(stats.CursedTechnique or stats.InnateTechnique or "None") ~= activity.RequiresSpecificTechnique then
		return false, activity.LockedText ~= "" and activity.LockedText or "Wrong cursed technique."
	end

	if activity.RequiresAssistant and not stats.AssistantName then
		return false, activity.LockedText ~= "" and activity.LockedText or "You need an assigned assistant."
	end

	if activity.MinTechniqueMastery and (tonumber(stats.TechniqueMastery) or 0) < activity.MinTechniqueMastery then
		return false, activity.LockedText ~= "" and activity.LockedText or "Your technique mastery is too low."
	end

	if activity.MinCursedEnergy and (tonumber(stats.CursedEnergy) or 0) < activity.MinCursedEnergy then
		return false, activity.LockedText ~= "" and activity.LockedText or "Your cursed energy is too low."
	end

	if activity.MinCursedObjectAnchorProgress and (tonumber(stats.CursedObjectAnchorProgress) or 0) < activity.MinCursedObjectAnchorProgress then
		return false, activity.LockedText ~= "" and activity.LockedText or "Your cursed object anchor progress is too low."
	end

	if activity.MinFame and (tonumber(stats.Fame) or 0) < activity.MinFame then
		return false, activity.LockedText ~= "" and activity.LockedText or "Your Fame is too low."
	end

	if activity.MinFear and (tonumber(stats.Fear) or 0) < activity.MinFear then
		return false, activity.LockedText ~= "" and activity.LockedText or "Your Fear is too low."
	end

	if activity.MinSocietyInfluence and (tonumber(stats.SocietyInfluence) or 0) < activity.MinSocietyInfluence then
		return false, activity.LockedText ~= "" and activity.LockedText or "Your Society Influence is too low."
	end

	if activity.MinDojoLegacy and (tonumber(stats.DojoLegacy) or 0) < activity.MinDojoLegacy then
		return false, activity.LockedText ~= "" and activity.LockedText or "Your Dojo Legacy is too low."
	end

	if activity.RequiresMoney and (tonumber(stats.Money) or 0) < activity.RequiresMoney then
		return false, activity.LockedText ~= "" and activity.LockedText or "You do not have enough money."
	end

	if activity.Id == "premium_select_ct" and tostring(stats.CursedTechnique or "None") ~= "None" then
		return false, "You already have a cursed technique."
	end

	if activity.Id == "request_assistant" and stats.AssistantName then
		return false, "You already have an assigned assistant."
	end

	if activity.Id == "evolve_technique" then
		local stage = tostring(stats.TechniqueEvolutionStage or "Dormant")
		local mastery = tonumber(stats.TechniqueMastery) or 0
		if stage == "Domain Seed" or stage == "Complete Domain" then
			return false, "Your technique has no further evolution available yet."
		end
		if stage == "Maximum Technique" and mastery < 95 then
			return false, "Reach 95 Technique Mastery to pursue a domain seed."
		elseif stage == "Extension Technique" and mastery < 75 then
			return false, "Reach 75 Technique Mastery to pursue a maximum technique."
		elseif stage == "Refined Form" and mastery < 50 then
			return false, "Reach 50 Technique Mastery to pursue an extension technique."
		end
	end

	if activity.Id == "body_hop" then
		local tech = string.lower(tostring(stats.CursedTechnique or stats.InnateTechnique or ""))
		if not (string.find(tech, "brain", 1, true) or string.find(tech, "transplant", 1, true)) then
			return false, "Only Brain Transplant users can body hop."
		end
		local stage = tostring(stats.TechniqueEvolutionStage or "Dormant")
		if stage ~= "Extension Technique" and stage ~= "Maximum Technique" and stage ~= "Domain Seed" and stage ~= "Complete Domain" then
			return false, "Evolve Brain Transplant to its Body Hopping stage first."
		end
	end

	if activity.Id == "apply_jujutsu_high" and stats.InJujutsuHigh then
		return false, "You are already enrolled in Jujutsu High."
	end

	return true, nil
end

function BitKaisenActivities.GenerateActivityList(stats)
	local list = {}

	for _, activity in ipairs(BitKaisenActivities.Database) do
		local canDo, reason = BitKaisenActivities.CanDoActivity(stats, activity)

		if canDo then
			table.insert(list, {
				Id = activity.Id,
				Title = activity.Title,
				Description = activity.Description,
				ButtonColor = activity.ButtonColor,
				CanDo = true,
				LockedReason = nil,
				OpensPanel = activity.OpensPanel
			})
		else
			if not activity.HideWhenLocked then
				table.insert(list, {
					Id = activity.Id,
					Title = activity.Title,
					Description = activity.Description,
					ButtonColor = activity.ButtonColor,
					CanDo = false,
					LockedReason = reason,
					OpensPanel = activity.OpensPanel
				})
			end
		end
	end

	return list
end

local CATEGORY_MAP = {
	play_outside = "Life",
	spend_time_family = "Life",
	watch_shadows = "Life",
	ask_about_curses = "Life",
	meditate = "Life",
	rest = "Life",
	doctor = "Life",
	socialize = "Social",
	retirement_reflection = "Life",

	basic_school_study = "School",
	school_attend_class = "School",
	school_study_exams = "School",
	school_join_club = "School",
	school_skip = "School",

	train_ce = "Training",
	physical_conditioning = "Training",
	study_theory = "Training",
	practice_technique = "Training",
	bulk_train_ce = "Training",
	bulk_practice_technique = "Training",
	evolve_technique = "Training",
	black_flash_training = "Training",
	barrier_drills = "Training",
	cursed_tool_practice = "Training",
	domain_foundation_study = "Training",
	binding_vow_research = "Training",
	rct_memory_training = "Minigames",
	stabilize_cursed_object_anchor = "Training",

	apply_jujutsu_high = "Jujutsu High",
	jujutsu_affiliation_duty = "Jujutsu High",
	request_assistant = "Jujutsu High",
	train_with_assistant = "Jujutsu High",
	jujutsu_school_event = "Jujutsu High",
	goodwill_event = "Jujutsu High",
	underground_tournament = "Jujutsu High",

	mentor_teach_class = "Mentor",
	mentor_supervise_mission = "Mentor",
	mentor_grade_students = "Mentor",
	mentor_prodigy = "Mentor",
	mentor_younger_sorcerers = "Mentor",

	mission_review = "Missions",
	patrol_city = "Missions",
	bulk_mission_sweep = "Missions",
	star_plasma_guard = "Missions",
	assassination_attempt = "Missions",
	cursed_finger_hunt = "Missions",

	clan_admin = "Dojo/Clan",
	clan_leadership_council = "Dojo/Clan",
	clan_merge_request = "Dojo/Clan",
	dojo_legacy_ceremony = "Dojo/Clan",
	dojo_raid_defense = "Dojo/Clan",
	dojo_recovery_work = "Dojo/Clan",
	rogue_student_incident = "Dojo/Clan",
	student_training_review = "Dojo/Clan",
	dojo_send_students_patrol = "Dojo/Clan",
	dojo_grade_review = "Dojo/Clan",
	dojo_pair_sparring = "Dojo/Clan",
	assistant_manage_dojo = "Dojo/Clan",
	assistant_train_npcs = "Dojo/Clan",
	assistant_field_support = "Dojo/Clan",
	join_other_dojo = "Dojo/Clan",
	train_at_joined_dojo = "Dojo/Clan",
	dojo_assignment = "Dojo/Clan",
	leave_joined_dojo = "Dojo/Clan",

	fame_public_audience = "Social",
	fear_intimidate_network = "Social",
	world_reputation_cleanup = "Social",
	society_influence_push = "Social",

	blackjack_table = "Minigames",
	burglary_job = "Minigames",
	heirloom_search = "Minigames",

	consume_cursed_fingers = "Curse Spirit",
	sukuna_vessel_ritual = "Curse Spirit",
	expand_curse_knowledge = "Curse Spirit",
	curse_absorb_fear = "Curse Spirit",
	curse_hide_presence = "Curse Spirit",
	curse_hunt_remnants = "Curse Spirit",
	curse_lure_sorcerer = "Curse Spirit",
	curse_claim_territory = "Curse Spirit",
	curse_spread_rumor = "Curse Spirit",
	curse_feed_negative_emotion = "Curse Spirit",
	curse_stalk_haunt = "Curse Spirit",
	curse_confuse_trackers = "Curse Spirit",
	curse_force_evolution = "Curse Spirit",
	curse_devour_remnant = "Curse Spirit",

	black_market_shop = "Underworld",

	curse_user_black_market = "Curse User",
	curse_user_hide_society = "Curse User",
	curse_user_illegal_job = "Curse User",
	curse_user_secret_training = "Curse User",
	curse_user_threaten_informant = "Curse User",

	cult_found = "Cult",
	cult_recruit_initiate = "Cult",
	cult_binding_ritual = "Cult",
	cult_collect_tribute = "Cult",
	cult_expand_territory = "Cult",
	cult_curse_fusion = "Cult",

	heian_blood_moon = "Era",
	edo_lightning_duel = "Era",
	era_lore_encounter = "Era",

	premium_select_clan = "Premium",
	premium_select_ct = "Premium",
	idle_add_trait = "Premium",
	idle_remove_trait = "Premium",
	dev_awaken = "Premium",
}

local CATEGORY_ORDER = {
	"Life", "School", "Training", "Jujutsu High", "Mentor",
	"Missions", "Dojo/Clan", "Social", "Minigames",
	"Curse Spirit", "Underworld", "Curse User", "Cult", "Era", "Premium",
}

function BitKaisenActivities.GetActivityCategory(activityId)
	return CATEGORY_MAP[tostring(activityId or "")] or "Life"
end

function BitKaisenActivities.GetCategoryOrder()
	return CATEGORY_ORDER
end

function BitKaisenActivities.GenerateCategorizedActivityList(stats)
	local list = BitKaisenActivities.GenerateActivityList(stats)
	for _, entry in ipairs(list) do
		entry.Category = BitKaisenActivities.GetActivityCategory(entry.Id)
	end
	return list
end

return BitKaisenActivities
