-- ModuleScript: BitKaisenCultData
-- Location: ReplicatedStorage
-- Purpose:
--   Static data for the Cursed Cult system: rank thresholds, initiate name/
--   personality pools, action definitions, and weighted yearly betrayal events.

local BitKaisenCultData = {}

local MALE_INITIATE_NAMES = { "Souta", "Yugo", "Renji", "Katsuo", "Isamu", "Norio", "Tetsuya", "Kuro", "Masaru", "Eizo", "Ryuunosuke", "Fumihiko" }
local FEMALE_INITIATE_NAMES = { "Yoru", "Suzume", "Chinatsu", "Ibuki", "Kagari", "Yuzuki", "Mayumi", "Sachi", "Rurika", "Tsukiko", "Ayame", "Kohaku" }
local INITIATE_FAMILY_NAMES = { "Kuroyume", "Ashigami", "Nokemono", "Yamikawa", "Sabishii", "Tsuchigumo", "Higanbana", "Kagenui", "Warazumi", "Nurikabe" }

local INITIATE_PERSONALITIES = {
	"Desperate for a place to belong, no questions asked.",
	"Quietly furious at a world that gave up on them first.",
	"Fascinated by curses, unafraid of what that fascination costs.",
	"Numb, compliant, and easy to point at a task.",
	"Sharp and opportunistic, looking for leverage inside the circle.",
	"Haunted by something they will not talk about.",
}

local INITIATE_BACKGROUNDS = {
	"Slipped through every safety net the Jujutsu Society ever built.",
	"Was cast out of a legitimate dojo for reasons never fully explained.",
	"Lost everything to a curse incident nobody official bothered to investigate.",
	"Sought out the cult after hearing whispered rumors in the underworld.",
	"Was recruited straight out of a black market deal gone sideways.",
	"Came looking for power and stopped asking about the price.",
}

-- Mirrors DojoRank's 0/25/60/120/250 thresholds so Cult progression feels
-- like a direct dark reflection of legitimate clan progression.
BitKaisenCultData.RANKS = {
	{ Threshold = 0, Name = "No Cult" },
	{ Threshold = 1, Name = "Whispering Circle" },
	{ Threshold = 25, Name = "Hollow Congregation" },
	{ Threshold = 60, Name = "Black Rope Sect" },
	{ Threshold = 120, Name = "Vengeful Order" },
	{ Threshold = 250, Name = "Disaster Cult" },
}

function BitKaisenCultData.GetRankForInfamy(infamy)
	infamy = tonumber(infamy) or 0
	local rank = BitKaisenCultData.RANKS[1].Name
	for _, tier in ipairs(BitKaisenCultData.RANKS) do
		if infamy >= tier.Threshold then
			rank = tier.Name
		end
	end
	return rank
end

function BitKaisenCultData.GetRankIndex(rankName)
	for index, tier in ipairs(BitKaisenCultData.RANKS) do
		if tier.Name == rankName then
			return index
		end
	end
	return 1
end

BitKaisenCultData.ACTION_DEFINITIONS = {
	Cult_Found = {
		Name = "Found the Cult",
		Description = "Bring together your first followers and declare your organization.",
	},
	Cult_RecruitInitiate = {
		Name = "Recruit Initiate",
		Description = "Draw a vulnerable or curious soul into the cult's lowest rank.",
	},
	Cult_BindingRitual = {
		Name = "Binding Ritual",
		Description = "Bind a member closer through fear and devotion. Small backlash risk.",
	},
	Cult_CollectTribute = {
		Name = "Collect Tribute",
		Description = "Tax the membership for the treasury. Loyalty suffers.",
	},
	Cult_ExpandTerritory = {
		Name = "Expand Territory",
		Description = "Push the cult's claim into new ground. Wanted Level rises.",
	},
	Cult_CurseFusion = {
		Name = "Curse Fusion",
		Description = "Consume a low-ranking member for power. Dark, permanent, irreversible.",
		MinRank = "Black Rope Sect",
	},
	Cult_SupplyRun = {
		Name = "Cult Supply Run",
		Description = "Funnel cult treasury into black market contacts for a temporary price discount.",
	},
	Cult_ReviewMembers = {
		Name = "Review Members",
		Description = "Promote initiates and disciples who have proven their devotion, trust, and fear.",
	},
}

-- Weighted yearly events rolled when CultLoyalty drops below the betrayal
-- threshold in BK_CultService.AdvanceYear.
BitKaisenCultData.BETRAYAL_EVENTS = {
	{
		Id = "treasury_theft",
		Weight = 20,
		Text = "A disillusioned lieutenant emptied part of the treasury before vanishing.",
	},
	{
		Id = "mass_desertion",
		Weight = 16,
		Text = "A handful of initiates lost faith and abandoned the cult overnight.",
	},
	{
		Id = "informant_leak",
		Weight = 12,
		Text = "A bitter member sold whispers of the cult's activities to the authorities.",
	},
}

-- MVP has no name-entry UI yet, so founding the cult picks from this pool
-- instead of prompting the player for text input.
local CULT_NAME_POOL = {
	"The Hollow Choir", "Black Rope Assembly", "The Withering Hand", "Nightbound Congregation",
	"The Ash Covenant", "Sable Vein Sect", "The Unspoken Order", "Gravebound Circle",
	"The Famished Chorus", "Widow's Lantern Sect",
}

local function pickRandom(list)
	if #list <= 0 then
		return nil
	end
	return list[math.random(1, #list)]
end

function BitKaisenCultData.PickCultName()
	return pickRandom(CULT_NAME_POOL)
end

function BitKaisenCultData.GenerateInitiateCandidate()
	local gender = math.random(1, 2) == 1 and "Male" or "Female"
	local firstName = gender == "Female" and pickRandom(FEMALE_INITIATE_NAMES) or pickRandom(MALE_INITIATE_NAMES)
	local familyName = pickRandom(INITIATE_FAMILY_NAMES)

	return {
		Name = firstName .. " " .. familyName,
		FirstName = firstName,
		FamilyName = familyName,
		Gender = gender,
		Personality = pickRandom(INITIATE_PERSONALITIES),
		Background = pickRandom(INITIATE_BACKGROUNDS),
		Devotion = math.random(15, 45),
	}
end

return BitKaisenCultData
