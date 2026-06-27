-- ModuleScript: BitKaisenTraits
-- Location: ReplicatedStorage
-- Purpose: Hundreds of life traits for BitKaisen.
-- Update 4.1: Reworked modifiers for all traits.
--   - Removed unused LifeEventFlavor and DojoTrainingMult placeholders.
--   - All modifier keys are read by GameManager or ApplyStartingBonuses.
--   - No trait names, IDs, or categories changed. Old saves compatible.

local BitKaisenTraits = {}
BitKaisenTraits.Version = "AlphaTraits_002"
BitKaisenTraits.RarityWeights = {
	Common    = 100,
	Uncommon  = 55,
	Rare      = 18,
	Legendary = 5,
}

----------------------------------------------------------------
-- DESIGN SCALE
-- Common:    1-2 modifiers, small bonus (~1.04-1.08 mult or +3-5 starting)
-- Uncommon:  2-3 modifiers, noticeable bonus (~1.08-1.15 mult or +6-10 starting)
-- Rare:      3-4 modifiers, strong bonus (~1.15-1.22 mult or +10-20 starting)
-- Legendary: 4+ modifiers, game-changing values (~1.22-1.32 mult or +20-35 starting)
----------------------------------------------------------------

BitKaisenTraits.Definitions = {

	----------------------------------------------------------------
	-- PERSONALITY
	----------------------------------------------------------------

	-- Stoic: tanks happiness hits, earns respect, harder to read emotionally
	{ Id = "stoic", Name = "Stoic", Category = "Personality", Rarity = "Uncommon", Weight = 55,
		Description = "takes less happiness loss, earns respect faster, and is harder to shake in dangerous situations.",
		Modifiers = { HappinessLossMult = 0.80, RespectGainMult = 1.12, RiskMult = 0.95 } },

	-- Friendly: relationship generalist
	{ Id = "friendly", Name = "Friendly", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "builds bonds and trust slightly faster with everyone.",
		Modifiers = { RelationshipGainMult = 1.08 } },

	-- Hot-Headed: combat up, risk up, happiness fragile
	{ Id = "hot_headed", Name = "Hot-Headed", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "fights harder but takes more damage and loses happiness faster under pressure.",
		Modifiers = { CombatGainMult = 1.10, RiskMult = 1.14, HappinessLossMult = 1.10 } },

	-- Shy: slower social, smarts and mastery up slightly
	{ Id = "shy", Name = "Shy", Category = "Personality", Rarity = "Uncommon", Weight = 55,
		Description = "slower to connect with others but sharper focus when alone.",
		Modifiers = { RelationshipGainMult = 0.88, SmartsGainMult = 1.08, MasteryGainMult = 1.06 } },

	-- Loyal: family and existing bonds are stronger
	{ Id = "loyal", Name = "Loyal", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "family bonds and existing relationships grow faster.",
		Modifiers = { FamilyGainMult = 1.10, RelationshipGainMult = 1.04 } },

	-- Ambitious: grade and mastery up, happiness cost
	{ Id = "ambitious", Name = "Ambitious", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "pushes grade and mastery progress faster at the cost of happiness.",
		Modifiers = { GradeProgressMult = 1.10, MasteryGainMult = 1.06, HappinessLossMult = 1.08 } },

	-- Reckless: combat and CE up, meaningful risk spike
	{ Id = "reckless", Name = "Reckless", Category = "Personality", Rarity = "Uncommon", Weight = 55,
		Description = "cursed energy and combat output spike but dangerous situations become more lethal.",
		Modifiers = { CombatGainMult = 1.12, CEGainMult = 1.08, RiskMult = 1.18 } },

	-- Calm: happiness protection, smarts up, CE steady
	{ Id = "calm", Name = "Calm", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "stays composed under pressure, protecting happiness and sharpening focus.",
		Modifiers = { HappinessLossMult = 0.82, SmartsGainMult = 1.06 } },

	-- Blunt: slight social penalty, grade progress up (directness cuts through)
	{ Id = "blunt", Name = "Blunt", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "direct speech costs social warmth but cuts through to what matters faster.",
		Modifiers = { RelationshipGainMult = 0.94, GradeProgressMult = 1.06 } },

	-- Patient: happiness protected, mastery grows steadily
	{ Id = "patient", Name = "Patient", Category = "Personality", Rarity = "Uncommon", Weight = 55,
		Description = "slow to frustrate and steady in practice, mastery grows more reliably.",
		Modifiers = { HappinessLossMult = 0.82, MasteryGainMult = 1.10 } },

	-- Proud: grade progress up, romance harder (pride creates distance)
	{ Id = "proud", Name = "Proud", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "pride drives grade progress but makes intimate relationships harder to build.",
		Modifiers = { GradeProgressMult = 1.08, RomanceGainMult = 0.92 } },

	-- Humble: trust and respect grow well, romance slightly easier
	{ Id = "humble", Name = "Humble", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "earns trust and respect steadily, and people open up more easily.",
		Modifiers = { RelationshipGainMult = 1.06, RomanceGainMult = 1.05 } },

	-- Curious: smarts and CE up slightly (always exploring)
	{ Id = "curious", Name = "Curious", Category = "Personality", Rarity = "Uncommon", Weight = 55,
		Description = "natural curiosity pushes smarts and cursed energy understanding forward.",
		Modifiers = { SmartsGainMult = 1.10, CEGainMult = 1.06 } },

	-- Cynical: risk slightly down (expects the worst, rarely surprised), relationships slower
	{ Id = "cynical", Name = "Cynical", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "expects the worst and is rarely caught off guard, but keeps people at arm's length.",
		Modifiers = { RiskMult = 0.94, RelationshipGainMult = 0.92 } },

	-- Optimistic: happiness protected, relationships up
	{ Id = "optimistic", Name = "Optimistic", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "positive outlook protects happiness and makes others more comfortable.",
		Modifiers = { HappinessLossMult = 0.88, RelationshipGainMult = 1.07 } },

	-- Pessimistic: happiness fragile, smarts slightly up (overthinking = awareness)
	{ Id = "pessimistic", Name = "Pessimistic", Category = "Personality", Rarity = "Uncommon", Weight = 55,
		Description = "overthinking makes happiness fragile but also sharpens awareness of risk.",
		Modifiers = { HappinessLossMult = 1.12, SmartsGainMult = 1.06, RiskMult = 0.96 } },

	-- Disciplined: mastery and grade up, small happiness cost
	{ Id = "disciplined", Name = "Disciplined", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "structured habits push mastery and grade progress reliably forward.",
		Modifiers = { MasteryGainMult = 1.08, GradeProgressMult = 1.06 } },

	-- Lazy: money and grade slightly worse, happiness protected (low pressure)
	{ Id = "lazy", Name = "Lazy", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "avoids effort where possible, slowing growth but keeping life comfortable.",
		Modifiers = { GradeProgressMult = 0.92, MoneyGainMult = 0.94, HappinessLossMult = 0.90 } },

	-- Competitive: grade and combat up, relationships slightly worse
	{ Id = "competitive", Name = "Competitive", Category = "Personality", Rarity = "Uncommon", Weight = 55,
		Description = "drives grade and combat growth through rivalry but strains relationships.",
		Modifiers = { GradeProgressMult = 1.10, CombatGainMult = 1.08, RelationshipGainMult = 0.92 } },

	-- Gentle: family and kid bonds strong, romance easier
	{ Id = "gentle", Name = "Gentle", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "warmth makes family bonds and romance grow more naturally.",
		Modifiers = { FamilyGainMult = 1.10, RomanceGainMult = 1.08 } },

	-- Cold: CE up (emotional distance = focus), relationships and romance suffer
	{ Id = "cold", Name = "Cold", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "emotional distance sharpens cursed energy focus but pushes people away.",
		Modifiers = { CEGainMult = 1.08, RelationshipGainMult = 0.88, RomanceGainMult = 0.88 } },

	-- Protective: family and kid bonds up, risk slightly up (throws self into danger)
	{ Id = "protective", Name = "Protective", Category = "Personality", Rarity = "Uncommon", Weight = 55,
		Description = "deep protectiveness strengthens family bonds but draws more dangerous situations.",
		Modifiers = { FamilyGainMult = 1.12, KidBondGainMult = 1.12, RiskMult = 1.08 } },

	-- Secretive: smarts up, relationships slower (guarded)
	{ Id = "secretive", Name = "Secretive", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "guarded nature slows trust but sharpens independent thinking.",
		Modifiers = { RelationshipGainMult = 0.90, SmartsGainMult = 1.08 } },

	-- Honest: trust builds faster, romance up (vulnerability = intimacy)
	{ Id = "honest", Name = "Honest", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "honesty builds trust faster and makes romantic connections more genuine.",
		Modifiers = { RelationshipGainMult = 1.07, RomanceGainMult = 1.06 } },

	-- Deceptive: money up (manipulation), trust slower
	{ Id = "deceptive", Name = "Deceptive", Category = "Personality", Rarity = "Uncommon", Weight = 55,
		Description = "manipulative instincts improve financial outcomes but erode trust.",
		Modifiers = { MoneyGainMult = 1.10, RelationshipGainMult = 0.90 } },

	-- Merciful: happiness protected, relationships up (people appreciate it)
	{ Id = "merciful", Name = "Merciful", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "compassion protects personal happiness and earns quiet respect from others.",
		Modifiers = { HappinessLossMult = 0.90, RelationshipGainMult = 1.06 } },

	-- Ruthless: combat and mission success up, happiness fragile
	{ Id = "ruthless", Name = "Ruthless", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "gets results in combat and missions but pays for it emotionally.",
		Modifiers = { CombatGainMult = 1.08, MissionSuccessBonus = 3, HappinessLossMult = 1.10 } },

	-- Forgiving: relationships recover faster, romance up
	{ Id = "forgiving", Name = "Forgiving", Category = "Personality", Rarity = "Uncommon", Weight = 55,
		Description = "lets go of grudges easily, keeping bonds healthy and romance warmer.",
		Modifiers = { RelationshipGainMult = 1.10, RomanceGainMult = 1.08 } },

	-- Petty: happiness fragile, money slightly up (grudges are motivating)
	{ Id = "petty", Name = "Petty", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "holds grudges hard, which costs happiness but turns spite into motivation.",
		Modifiers = { HappinessLossMult = 1.12, MoneyGainMult = 1.06 } },

	-- Brave: mission success and combat up, risk slightly up
	{ Id = "brave", Name = "Brave", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "steps into danger willingly, improving combat and missions but drawing more risk.",
		Modifiers = { MissionSuccessBonus = 3, CombatGainMult = 1.06, RiskMult = 1.08 } },

	-- Careful: risk down, mastery up (deliberate practice)
	{ Id = "careful", Name = "Careful", Category = "Personality", Rarity = "Uncommon", Weight = 55,
		Description = "deliberate approach reduces dangerous outcomes and sharpens technique control.",
		Modifiers = { RiskMult = 0.88, MasteryGainMult = 1.08 } },

	-- Impulsive: CE and combat spike, risk up, happiness fragile
	{ Id = "impulsive", Name = "Impulsive", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "acts before thinking, spiking output but drawing more danger and emotional cost.",
		Modifiers = { CombatGainMult = 1.10, CEGainMult = 1.06, RiskMult = 1.16, HappinessLossMult = 1.08 } },

	-- Focused: mastery and smarts up, relationship slightly slower
	{ Id = "focused", Name = "Focused", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "deep focus accelerates mastery and smarts but makes social investment harder.",
		Modifiers = { MasteryGainMult = 1.08, SmartsGainMult = 1.06, RelationshipGainMult = 0.94 } },

	-- Dreamy: CE up (abstract thinking = cursed energy resonance), smarts and grade slower
	{ Id = "dreamy", Name = "Dreamy", Category = "Personality", Rarity = "Uncommon", Weight = 55,
		Description = "detachment from reality feeds cursed energy intuition but drifts from structure.",
		Modifiers = { CEGainMult = 1.10, SmartsGainMult = 0.94, GradeProgressMult = 0.94 } },

	-- Sarcastic: smarts up (sharp wit), relationships slightly slower
	{ Id = "sarcastic", Name = "Sarcastic", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "sharp wit keeps the mind quick but makes first impressions harder.",
		Modifiers = { SmartsGainMult = 1.07, RelationshipGainMult = 0.94 } },

	-- Serious: mastery up, romance slower (hard to be vulnerable)
	{ Id = "serious", Name = "Serious", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "serious approach to everything pushes mastery but makes romance harder to start.",
		Modifiers = { MasteryGainMult = 1.08, RomanceGainMult = 0.90 } },

	-- Playful: romance and relationship up, mastery slightly slower
	{ Id = "playful", Name = "Playful", Category = "Personality", Rarity = "Uncommon", Weight = 55,
		Description = "playful energy makes connections easier but focus on discipline suffers.",
		Modifiers = { RelationshipGainMult = 1.10, RomanceGainMult = 1.10, MasteryGainMult = 0.94 } },

	-- Reserved: smarts and mastery up, social slower
	{ Id = "reserved", Name = "Reserved", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "private nature slows social bonds but sharpens internal focus.",
		Modifiers = { SmartsGainMult = 1.06, MasteryGainMult = 1.05, RelationshipGainMult = 0.90 } },

	-- Outgoing: relationship generalist bonus
	{ Id = "outgoing", Name = "Outgoing", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "natural ease with people accelerates bonds of all kinds.",
		Modifiers = { RelationshipGainMult = 1.10, RomanceGainMult = 1.06 } },

	-- Stubborn: mastery up (refuses to give up), grade progress slower (won't adapt)
	{ Id = "stubborn", Name = "Stubborn", Category = "Personality", Rarity = "Uncommon", Weight = 55,
		Description = "sheer refusal to quit builds mastery but stubbornness slows adaptation.",
		Modifiers = { MasteryGainMult = 1.10, GradeProgressMult = 0.94 } },

	-- Flexible: grade progress up (adapts quickly), mastery slightly slower (no deep grooves)
	{ Id = "flexible", Name = "Flexible", Category = "Personality", Rarity = "Common", Weight = 100,
		Description = "adapts quickly to new styles, pushing grade progress but lacking deep specialization.",
		Modifiers = { GradeProgressMult = 1.08, MasteryGainMult = 0.96 } },

	----------------------------------------------------------------
	-- SOCIAL
	----------------------------------------------------------------

	-- Charismatic: strong relationship + romance + marriage threshold down
	{ Id = "charismatic", Name = "Charismatic", Category = "Social", Rarity = "Uncommon", Weight = 55,
		Description = "natural pull makes relationships, romance, and commitment all come easier.",
		Modifiers = { RelationshipGainMult = 1.14, RomanceGainMult = 1.14, MarriageReqMult = 0.92 } },

	-- Awkward: social and romance slower
	{ Id = "awkward", Name = "Awkward", Category = "Social", Rarity = "Common", Weight = 100,
		Description = "struggles to connect naturally, making social and romantic progress slower.",
		Modifiers = { RelationshipGainMult = 0.86, RomanceGainMult = 0.88 } },

	-- Popular: relationship and romance up
	{ Id = "popular", Name = "Popular", Category = "Social", Rarity = "Common", Weight = 100,
		Description = "widely liked, making it easier to build and maintain connections.",
		Modifiers = { RelationshipGainMult = 1.12, RomanceGainMult = 1.08 } },

	-- Intimidating: risk slightly down (people think twice), relationship slower
	{ Id = "intimidating", Name = "Intimidating", Category = "Social", Rarity = "Uncommon", Weight = 55,
		Description = "imposing presence deters aggression but makes warm connections harder.",
		Modifiers = { RiskMult = 0.90, RelationshipGainMult = 0.92, MissionSuccessBonus = 2 } },

	-- Soft-Spoken: relationship and family up (people feel safe)
	{ Id = "soft_spoken", Name = "Soft-Spoken", Category = "Social", Rarity = "Common", Weight = 100,
		Description = "quiet, careful words make people feel safe and build trust steadily.",
		Modifiers = { RelationshipGainMult = 1.08, FamilyGainMult = 1.06 } },

	-- Silver Tongue: romance and relationship up, money up (persuasion)
	{ Id = "silver_tongue", Name = "Silver Tongue", Category = "Social", Rarity = "Common", Weight = 100,
		Description = "persuasive words improve romance, bonds, and financial negotiations.",
		Modifiers = { RelationshipGainMult = 1.10, RomanceGainMult = 1.10, MoneyGainMult = 1.06 } },

	-- Deadpan Humor: smarts up, relationship up slightly (dry wit is disarming)
	{ Id = "deadpan_humor", Name = "Deadpan Humor", Category = "Social", Rarity = "Uncommon", Weight = 55,
		Description = "dry wit disarms people unexpectedly, earning quiet smarts and subtle social gains.",
		Modifiers = { SmartsGainMult = 1.08, RelationshipGainMult = 1.06 } },

	-- Natural Leader: relationship and grade progress up, mission bonus
	{ Id = "natural_leader", Name = "Natural Leader", Category = "Social", Rarity = "Common", Weight = 100,
		Description = "people follow naturally, improving mission outcomes and group bonds.",
		Modifiers = { RelationshipGainMult = 1.10, GradeProgressMult = 1.06, MissionSuccessBonus = 2 } },

	-- Follower Mindset: happiness protected (less pressure), grade progress slower
	{ Id = "follower_mindset", Name = "Follower Mindset", Category = "Social", Rarity = "Common", Weight = 100,
		Description = "comfortable following others, keeping stress low but limiting independent growth.",
		Modifiers = { HappinessLossMult = 0.90, GradeProgressMult = 0.94 } },

	-- Trusted Face: relationship and family up, risk slightly down
	{ Id = "trusted_face", Name = "Trusted Face", Category = "Social", Rarity = "Uncommon", Weight = 55,
		Description = "easy to trust on sight, opening doors and reducing hostility.",
		Modifiers = { RelationshipGainMult = 1.10, FamilyGainMult = 1.08, RiskMult = 0.94 } },

	-- Suspicious Aura: risk up, relationship and romance slower
	{ Id = "suspicious_aura", Name = "Suspicious Aura", Category = "Social", Rarity = "Common", Weight = 100,
		Description = "something about this person puts others on edge, slowing trust and attracting trouble.",
		Modifiers = { RelationshipGainMult = 0.86, RomanceGainMult = 0.88, RiskMult = 1.10 } },

	-- Easy to Love: romance and marriage threshold down, relationship up
	{ Id = "easy_to_love", Name = "Easy to Love", Category = "Social", Rarity = "Common", Weight = 100,
		Description = "naturally lovable, making romance and commitment come more easily.",
		Modifiers = { RomanceGainMult = 1.14, MarriageReqMult = 0.92, RelationshipGainMult = 1.08 } },

	-- Hard to Read: smarts up (unpredictability = intelligence), romance slower
	{ Id = "hard_to_read", Name = "Hard to Read", Category = "Social", Rarity = "Uncommon", Weight = 55,
		Description = "unreadable expression sharpens independent thinking but makes intimacy harder.",
		Modifiers = { SmartsGainMult = 1.10, RomanceGainMult = 0.90 } },

	-- Family Oriented: family and kid bonds strong
	{ Id = "family_oriented", Name = "Family Oriented", Category = "Social", Rarity = "Common", Weight = 100,
		Description = "family comes first, making family bonds and child connections grow faster.",
		Modifiers = { FamilyGainMult = 1.18, KidBondGainMult = 1.18 } },

	-- Commitment Issues: romance exists but marriage harder, relationships slightly slower
	{ Id = "commitment_issues", Name = "Commitment Issues", Category = "Social", Rarity = "Common", Weight = 100,
		Description = "struggles to commit fully, slowing deep bonds and making marriage harder.",
		Modifiers = { MarriageReqMult = 1.18, RomanceGainMult = 0.90, RelationshipGainMult = 0.94 } },

	-- Jealous Heart: romance up (passion), risk slightly up (jealousy causes problems)
	{ Id = "jealous_heart", Name = "Jealous Heart", Category = "Social", Rarity = "Uncommon", Weight = 55,
		Description = "deep passion fuels romance but jealousy pulls in more conflict.",
		Modifiers = { RomanceGainMult = 1.12, RiskMult = 1.08, HappinessLossMult = 1.08 } },

	-- Smooth Talker: romance and money up, relationship up
	{ Id = "smooth_talker", Name = "Smooth Talker", Category = "Social", Rarity = "Common", Weight = 100,
		Description = "effortlessly charming, improving romance, bonds, and financial outcomes.",
		Modifiers = { RomanceGainMult = 1.12, MoneyGainMult = 1.06, RelationshipGainMult = 1.08 } },

	-- Quiet Charm: relationship up, romance up slightly
	{ Id = "quiet_charm", Name = "Quiet Charm", Category = "Social", Rarity = "Common", Weight = 100,
		Description = "subtle appeal that builds slowly and genuinely.",
		Modifiers = { RelationshipGainMult = 1.08, RomanceGainMult = 1.06 } },

	-- Protective Lover: family and kid bonds up, risk up slightly
	{ Id = "protective_lover", Name = "Protective Lover", Category = "Social", Rarity = "Uncommon", Weight = 55,
		Description = "fierce protectiveness strengthens family bonds but creates dangerous situations.",
		Modifiers = { FamilyGainMult = 1.14, KidBondGainMult = 1.14, RiskMult = 1.08 } },

	-- Distant Partner: romance and relationship slower
	{ Id = "distant_partner", Name = "Distant Partner", Category = "Social", Rarity = "Common", Weight = 100,
		Description = "emotional distance makes romance and deep bonds harder to sustain.",
		Modifiers = { RomanceGainMult = 0.86, RelationshipGainMult = 0.90 } },

	-- Romantic Idealist: romance up, marriage threshold down slightly
	{ Id = "romantic_idealist", Name = "Romantic Idealist", Category = "Social", Rarity = "Common", Weight = 100,
		Description = "believes in love deeply, making romantic connections grow faster.",
		Modifiers = { RomanceGainMult = 1.12, MarriageReqMult = 0.95 } },

	-- Cold Romantic: romance slower, relationship slower but smarts up
	{ Id = "cold_romantic", Name = "Cold Romantic", Category = "Social", Rarity = "Uncommon", Weight = 55,
		Description = "feels things deeply but shows nothing, slowing romance but sharpening awareness.",
		Modifiers = { RomanceGainMult = 0.88, RelationshipGainMult = 0.90, SmartsGainMult = 1.08 } },

	-- Good Listener: family and kid bonds up, relationship up
	{ Id = "good_listener", Name = "Good Listener", Category = "Social", Rarity = "Common", Weight = 100,
		Description = "genuine attention builds deep family bonds and broad relationship trust.",
		Modifiers = { FamilyGainMult = 1.12, KidBondGainMult = 1.10, RelationshipGainMult = 1.06 } },

	-- Bad Liar: relationship up (people trust honesty), smarts slightly down
	{ Id = "bad_liar", Name = "Bad Liar", Category = "Social", Rarity = "Common", Weight = 100,
		Description = "too honest to deceive effectively, which earns trust but costs cunning.",
		Modifiers = { RelationshipGainMult = 1.08, SmartsGainMult = 0.94 } },

	-- Sharp Tongue: smarts up, relationship and romance slower
	{ Id = "sharp_tongue", Name = "Sharp Tongue", Category = "Social", Rarity = "Uncommon", Weight = 55,
		Description = "cutting words keep the mind sharp but push people away over time.",
		Modifiers = { SmartsGainMult = 1.10, RelationshipGainMult = 0.90, RomanceGainMult = 0.92 } },

	-- Kind Eyes: relationship and romance up, happiness protected
	{ Id = "kind_eyes", Name = "Kind Eyes", Category = "Social", Rarity = "Common", Weight = 100,
		Description = "warmth in expression builds connections and keeps emotional life stable.",
		Modifiers = { RelationshipGainMult = 1.08, RomanceGainMult = 1.06, HappinessLossMult = 0.92 } },

	-- Terrible First Impression: relationship and romance slower
	{ Id = "terrible_first_impression", Name = "Terrible First Impression", Category = "Social", Rarity = "Common", Weight = 100,
		Description = "hard to like at first, making bonds and romance start slower.",
		Modifiers = { RelationshipGainMult = 0.84, RomanceGainMult = 0.86 } },

	-- Natural Mentor: kid bonds and family up, mission bonus
	{ Id = "natural_mentor", Name = "Natural Mentor", Category = "Social", Rarity = "Uncommon", Weight = 55,
		Description = "natural teaching instinct builds bonds with younger people and helps in field work.",
		Modifiers = { KidBondGainMult = 1.14, FamilyGainMult = 1.10, MissionSuccessBonus = 2 } },

	-- Student Magnet: relationship up, CE up slightly (teaching cements understanding)
	{ Id = "student_magnet", Name = "Student Magnet", Category = "Social", Rarity = "Common", Weight = 100,
		Description = "naturally draws students and learners, deepening both bonds and personal understanding.",
		Modifiers = { RelationshipGainMult = 1.08, CEGainMult = 1.05 } },

	-- Lonely Presence: CE up (isolation = focus), relationship and romance slower
	{ Id = "lonely_presence", Name = "Lonely Presence", Category = "Social", Rarity = "Common", Weight = 100,
		Description = "difficult to get close to, but solitude sharpens cursed energy instincts.",
		Modifiers = { CEGainMult = 1.08, RelationshipGainMult = 0.86, RomanceGainMult = 0.88 } },

	----------------------------------------------------------------
	-- SORCERER
	----------------------------------------------------------------

	-- Natural Prodigy: top-tier mastery, grade, mission bonus, awakening
	{ Id = "natural_prodigy", Name = "Natural Prodigy", Category = "Sorcerer", Rarity = "Rare", Weight = 18,
		Description = "born with exceptional aptitude. Mastery, grade, missions, and awakening all improve significantly.",
		Modifiers = { MasteryGainMult = 1.24, GradeProgressMult = 1.18, MissionSuccessBonus = 5, AwakeningChanceBonus = 4, RarityPower = 2 } },

	-- Late Bloomer: mastery slower early but CE builds quietly
	{ Id = "late_bloomer", Name = "Late Bloomer", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "slow to develop but cursed energy builds steadily beneath the surface.",
		Modifiers = { MasteryGainMult = 0.92, CEGainMult = 1.14 } },

	-- Cursed Energy Sensitive: CE and awakening up
	{ Id = "cursed_energy_sensitive", Name = "Cursed Energy Sensitive", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "naturally attuned to cursed energy, improving CE growth and awakening chances.",
		Modifiers = { CEGainMult = 1.18, AwakeningChanceBonus = 5 } },

	-- Poor CE Control: high CE ceiling, mastery penalty
	{ Id = "poor_ce_control", Name = "Poor CE Control", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "cursed energy pours out naturally but control is hard to develop.",
		Modifiers = { CEGainMult = 1.16, MasteryGainMult = 0.84 } },

	-- Combat Savant: top-tier combat, mastery, mission bonus
	{ Id = "combat_savant", Name = "Combat Savant", Category = "Sorcerer", Rarity = "Rare", Weight = 18,
		Description = "born for battle. Combat, mastery, and mission success all reach a higher ceiling.",
		Modifiers = { CombatGainMult = 1.22, MasteryGainMult = 1.18, MissionSuccessBonus = 6, RarityPower = 2 } },

	-- Sharp Mind: smarts, mastery, grade all up
	{ Id = "sharp_mind", Name = "Sharp Mind", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "analytical mind improves technique understanding, smarts, and grade progress.",
		Modifiers = { SmartsGainMult = 1.12, MasteryGainMult = 1.10, GradeProgressMult = 1.06 } },

	-- Iron Will: happiness protected, mastery and mission bonus
	{ Id = "iron_will", Name = "Iron Will", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "unbreakable will keeps emotions steady and pushes through difficult missions.",
		Modifiers = { HappinessLossMult = 0.78, MasteryGainMult = 1.10, MissionSuccessBonus = 3 } },

	-- Fragile Body: risk up, mission penalty, CE up (overcomes limits mentally)
	{ Id = "fragile_body", Name = "Fragile Body", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "physical fragility makes missions more dangerous but forces stronger CE reliance.",
		Modifiers = { RiskMult = 1.22, MissionSuccessBonus = -4, CEGainMult = 1.10 } },

	-- Massive CE Reserve: top CE and awakening
	{ Id = "massive_ce_reserve", Name = "Massive CE Reserve", Category = "Sorcerer", Rarity = "Rare", Weight = 18,
		Description = "an unusually large cursed energy reserve that grows faster and awakens techniques earlier.",
		Modifiers = { CEGainMult = 1.24, AwakeningChanceBonus = 6, StartingCEBonus = 12, RarityPower = 2 } },

	-- Efficient CE Flow: CE and mastery up
	{ Id = "efficient_ce_flow", Name = "Efficient CE Flow", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "cursed energy flows cleanly through the body, improving both output and technique control.",
		Modifiers = { CEGainMult = 1.14, MasteryGainMult = 1.10 } },

	-- Sloppy Output: CE up, mastery down, risk slightly up
	{ Id = "sloppy_output", Name = "Sloppy Output", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "massive output but no finesse. Technique control suffers and collateral risk rises.",
		Modifiers = { CEGainMult = 1.14, MasteryGainMult = 0.82, RiskMult = 1.10 } },

	-- Precise Output: mastery up, risk down
	{ Id = "precise_output", Name = "Precise Output", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "surgical control over cursed energy output reduces accidents and deepens mastery.",
		Modifiers = { MasteryGainMult = 1.14, RiskMult = 0.90 } },

	-- Domain Sense: mastery and smarts up, awakening bonus
	{ Id = "domain_sense", Name = "Domain Sense", Category = "Sorcerer", Rarity = "Rare", Weight = 18,
		Description = "innate understanding of domain theory accelerates mastery, smarts, and awakening.",
		Modifiers = { MasteryGainMult = 1.18, SmartsGainMult = 1.14, AwakeningChanceBonus = 5, RarityPower = 2 } },

	-- Barrier Instinct: mastery and risk reduction
	{ Id = "barrier_instinct", Name = "Barrier Instinct", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "instinctive grasp of barrier techniques improves mastery and reduces dangerous situations.",
		Modifiers = { MasteryGainMult = 1.10, RiskMult = 0.90 } },

	-- Reverse Curse Spark: mastery and happiness protected
	{ Id = "reverse_curse_spark", Name = "Reverse Curse Spark", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "early intuition for reverse cursed technique protects against emotional and physical damage.",
		Modifiers = { MasteryGainMult = 1.10, HappinessLossMult = 0.85 } },

	-- Black Flash Prone: mastery, grade, CE all up
	{ Id = "black_flash_prone", Name = "Black Flash Prone", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "cursed energy timing is naturally sharp, improving mastery, CE, and grade advancement.",
		Modifiers = { MasteryGainMult = 1.14, CEGainMult = 1.10, GradeProgressMult = 1.10 } },

	-- Technique Analyst: top mastery, smarts, grade, mission
	{ Id = "technique_analyst", Name = "Technique Analyst", Category = "Sorcerer", Rarity = "Rare", Weight = 18,
		Description = "reads techniques and situations like a puzzle. Mastery, smarts, grade, and missions all advance faster.",
		Modifiers = { MasteryGainMult = 1.22, SmartsGainMult = 1.16, GradeProgressMult = 1.14, MissionSuccessBonus = 4, RarityPower = 2 } },

	-- Mission Instinct: mission bonus, mastery, grade up
	{ Id = "mission_instinct", Name = "Mission Instinct", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "adapts quickly under mission pressure, improving success rates and technique growth.",
		Modifiers = { MissionSuccessBonus = 5, MasteryGainMult = 1.10, GradeProgressMult = 1.08 } },

	-- Curse Tracker: smarts, mastery, risk down
	{ Id = "curse_tracker", Name = "Curse Tracker", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "sharp sense for cursed energy signatures reduces surprises and improves combat preparation.",
		Modifiers = { SmartsGainMult = 1.10, MasteryGainMult = 1.08, RiskMult = 0.92 } },

	-- Shikigami Affinity: CE and mastery up
	{ Id = "shikigami_affinity", Name = "Shikigami Affinity", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "natural bond with shikigami-style cursed energy improves CE and technique mastery.",
		Modifiers = { CEGainMult = 1.12, MasteryGainMult = 1.10 } },

	-- Weapon Specialist: combat and mastery up, mission bonus
	{ Id = "weapon_specialist", Name = "Weapon Specialist", Category = "Sorcerer", Rarity = "Rare", Weight = 18,
		Description = "weapon expertise translates into stronger combat output and better mission performance.",
		Modifiers = { CombatGainMult = 1.18, MasteryGainMult = 1.14, MissionSuccessBonus = 4, RarityPower = 2 } },

	-- Hand-to-Hand Genius: combat and CE up
	{ Id = "hand_to_hand_genius", Name = "Hand-to-Hand Genius", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "exceptional at close range, turning physical skill into cursed energy output.",
		Modifiers = { CombatGainMult = 1.16, CEGainMult = 1.08 } },

	-- Binding Vow Mind: mastery and smarts up, happiness slightly fragile (vows cost)
	{ Id = "binding_vow_mind", Name = "Binding Vow Mind", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "deep understanding of vow mechanics improves mastery and smarts but adds personal cost.",
		Modifiers = { MasteryGainMult = 1.12, SmartsGainMult = 1.10, HappinessLossMult = 1.08 } },

	-- Curse Resistant: risk down, mastery up
	{ Id = "curse_resistant", Name = "Curse Resistant", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "naturally resistant to cursed energy effects, reducing danger and building technique endurance.",
		Modifiers = { RiskMult = 0.86, MasteryGainMult = 1.08 } },

	-- Fearless Exorcist: mission bonus, combat, risk up slightly
	{ Id = "fearless_exorcist", Name = "Fearless Exorcist", Category = "Sorcerer", Rarity = "Rare", Weight = 18,
		Description = "walks into exorcisms without hesitation. Mission success and combat climb, but risk follows.",
		Modifiers = { MissionSuccessBonus = 6, CombatGainMult = 1.16, RiskMult = 1.10, RarityPower = 2 } },

	-- Pressure Fighter: combat and mastery spike under risk
	{ Id = "pressure_fighter", Name = "Pressure Fighter", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "fights best when the stakes are high, improving combat and mastery under pressure.",
		Modifiers = { CombatGainMult = 1.14, MasteryGainMult = 1.08, RiskMult = 1.06 } },

	-- Defensive Genius: risk down, mastery up, happiness protected
	{ Id = "defensive_genius", Name = "Defensive Genius", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "reads incoming threats better than most, reducing danger and preserving composure.",
		Modifiers = { RiskMult = 0.84, MasteryGainMult = 1.10, HappinessLossMult = 0.90 } },

	-- Ambush Reader: risk down, smarts and mission bonus
	{ Id = "ambush_reader", Name = "Ambush Reader", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "never fully caught off guard. Sharpens situational awareness and mission performance.",
		Modifiers = { RiskMult = 0.86, SmartsGainMult = 1.10, MissionSuccessBonus = 3 } },

	-- Tactical Coward: risk down significantly, mission bonus, combat slightly down
	{ Id = "tactical_coward", Name = "Tactical Coward", Category = "Sorcerer", Rarity = "Rare", Weight = 18,
		Description = "survival instinct over pride. Dramatically reduces dangerous outcomes at the cost of raw combat.",
		Modifiers = { RiskMult = 0.78, MissionSuccessBonus = 5, CombatGainMult = 0.90, RarityPower = 2 } },

	-- Battle Addict: combat and CE up significantly, risk up, happiness fragile
	{ Id = "battle_addict", Name = "Battle Addict", Category = "Sorcerer", Rarity = "Uncommon", Weight = 55,
		Description = "lives for the fight. Combat and CE surge but constant danger wears on mind and body.",
		Modifiers = { CombatGainMult = 1.18, CEGainMult = 1.12, RiskMult = 1.18, HappinessLossMult = 1.12 } },

	----------------------------------------------------------------
	-- BODY
	----------------------------------------------------------------

	-- Fast Reflexes: combat and mission bonus
	{ Id = "fast_reflexes", Name = "Fast Reflexes", Category = "Body", Rarity = "Uncommon", Weight = 55,
		Description = "faster than most people expect, improving combat and mission reaction.",
		Modifiers = { CombatGainMult = 1.14, MissionSuccessBonus = 3 } },

	-- Heavy Sleeper: happiness protected (well rested), smarts slightly down
	{ Id = "heavy_sleeper", Name = "Heavy Sleeper", Category = "Body", Rarity = "Common", Weight = 100,
		Description = "sleeps deeply, protecting happiness, but misses things that happen early.",
		Modifiers = { HappinessLossMult = 0.92, SmartsGainMult = 0.96 } },

	-- Light Sleeper: smarts up (always alert), happiness slightly fragile
	{ Id = "light_sleeper", Name = "Light Sleeper", Category = "Body", Rarity = "Common", Weight = 100,
		Description = "always half-aware, sharpening alertness but making rest incomplete.",
		Modifiers = { SmartsGainMult = 1.06, HappinessLossMult = 1.06 } },

	-- Strong Grip: combat up, mastery up slightly
	{ Id = "strong_grip", Name = "Strong Grip", Category = "Body", Rarity = "Uncommon", Weight = 55,
		Description = "exceptional grip strength improves close combat and technique holding.",
		Modifiers = { CombatGainMult = 1.14, MasteryGainMult = 1.06 } },

	-- Weak Stamina: risk up, combat down
	{ Id = "weak_stamina", Name = "Weak Stamina", Category = "Body", Rarity = "Common", Weight = 100,
		Description = "runs out of energy quickly, making extended fights and missions more dangerous.",
		Modifiers = { RiskMult = 1.16, CombatGainMult = 0.90 } },

	-- High Stamina: combat up, risk down slightly
	{ Id = "high_stamina", Name = "High Stamina", Category = "Body", Rarity = "Common", Weight = 100,
		Description = "outlasts most opponents, improving combat endurance and reducing dangerous outcomes.",
		Modifiers = { CombatGainMult = 1.10, RiskMult = 0.94 } },

	-- Pain Tolerant: risk down, happiness protected
	{ Id = "pain_tolerant", Name = "Pain Tolerant", Category = "Body", Rarity = "Uncommon", Weight = 55,
		Description = "absorbs damage without flinching, reducing danger and protecting emotional state.",
		Modifiers = { RiskMult = 0.88, HappinessLossMult = 0.88 } },

	-- Low Pain Tolerance: risk up, happiness fragile
	{ Id = "low_pain_tolerance", Name = "Low Pain Tolerance", Category = "Body", Rarity = "Common", Weight = 100,
		Description = "pain hits harder emotionally and physically, raising risk and draining happiness.",
		Modifiers = { RiskMult = 1.18, HappinessLossMult = 1.14 } },

	-- Athletic Build: combat and mission bonus
	{ Id = "athletic_build", Name = "Athletic Build", Category = "Body", Rarity = "Common", Weight = 100,
		Description = "natural athleticism improves combat and physical mission performance.",
		Modifiers = { CombatGainMult = 1.10, MissionSuccessBonus = 2 } },

	-- Unsteady Hands: mastery down, smarts up (compensates mentally)
	{ Id = "unsteady_hands", Name = "Unsteady Hands", Category = "Body", Rarity = "Uncommon", Weight = 55,
		Description = "physical technique is shakier than peers, but mental compensation sharpens awareness.",
		Modifiers = { MasteryGainMult = 0.88, SmartsGainMult = 1.10 } },

	-- Steady Hands: mastery and smarts up
	{ Id = "steady_hands", Name = "Steady Hands", Category = "Body", Rarity = "Common", Weight = 100,
		Description = "precise and controlled hands improve technique mastery and focused thinking.",
		Modifiers = { MasteryGainMult = 1.08, SmartsGainMult = 1.06 } },

	-- Good Eyesight: smarts and mission bonus
	{ Id = "good_eyesight", Name = "Good Eyesight", Category = "Body", Rarity = "Common", Weight = 100,
		Description = "sharp vision improves situational awareness and mission reads.",
		Modifiers = { SmartsGainMult = 1.06, MissionSuccessBonus = 2 } },

	-- Bad Eyesight: smarts slightly down, risk slightly up
	{ Id = "bad_eyesight", Name = "Bad Eyesight", Category = "Body", Rarity = "Uncommon", Weight = 55,
		Description = "poor vision creates blind spots that cost situational awareness and raise risk.",
		Modifiers = { SmartsGainMult = 0.92, RiskMult = 1.08 } },

	-- Fast Learner: smarts and mastery up
	{ Id = "fast_learner", Name = "Fast Learner", Category = "Body", Rarity = "Common", Weight = 100,
		Description = "picks up new techniques and knowledge faster than most.",
		Modifiers = { SmartsGainMult = 1.10, MasteryGainMult = 1.08 } },

	-- Slow Starter: grade progress slower early, mastery up over time
	{ Id = "slow_starter", Name = "Slow Starter", Category = "Body", Rarity = "Common", Weight = 100,
		Description = "takes time to warm up but builds technique endurance through slow repetition.",
		Modifiers = { GradeProgressMult = 0.92, MasteryGainMult = 1.08 } },

	-- Quick Recovery: happiness and risk protection
	{ Id = "quick_recovery", Name = "Quick Recovery", Category = "Body", Rarity = "Uncommon", Weight = 55,
		Description = "bounces back from physical and emotional hits faster than normal.",
		Modifiers = { HappinessLossMult = 0.82, RiskMult = 0.90 } },

	-- Sickly Youth: risk up, CE up (suffering builds sensitivity)
	{ Id = "sickly_youth", Name = "Sickly Youth", Category = "Body", Rarity = "Common", Weight = 100,
		Description = "chronic illness raises physical risk but sharpens cursed energy sensitivity.",
		Modifiers = { RiskMult = 1.16, CEGainMult = 1.08 } },

	-- Healthy Body: risk down, happiness protected
	{ Id = "healthy_body", Name = "Healthy Body", Category = "Body", Rarity = "Common", Weight = 100,
		Description = "good baseline health reduces physical risk and keeps morale stable.",
		Modifiers = { RiskMult = 0.92, HappinessLossMult = 0.92 } },

	-- Scarred Aura: intimidation effect — risk slightly down, relationship slightly slower
	{ Id = "scarred_aura", Name = "Scarred Aura", Category = "Body", Rarity = "Uncommon", Weight = 55,
		Description = "visible scars signal experience, deterring casual threats but making warm bonds harder.",
		Modifiers = { RiskMult = 0.90, RelationshipGainMult = 0.92, MissionSuccessBonus = 2 } },

	-- Quiet Footsteps: mission bonus, risk down slightly
	{ Id = "quiet_footsteps", Name = "Quiet Footsteps", Category = "Body", Rarity = "Common", Weight = 100,
		Description = "moves without sound, improving mission stealth and reducing surprise encounters.",
		Modifiers = { MissionSuccessBonus = 3, RiskMult = 0.94 } },

	-- Loud Presence: relationship up (hard to ignore), risk slightly up
	{ Id = "loud_presence", Name = "Loud Presence", Category = "Body", Rarity = "Common", Weight = 100,
		Description = "impossible to ignore, drawing attention that builds connections but also trouble.",
		Modifiers = { RelationshipGainMult = 1.06, RiskMult = 1.08 } },

	-- Natural Balance: combat and mastery up slightly
	{ Id = "natural_balance", Name = "Natural Balance", Category = "Body", Rarity = "Uncommon", Weight = 55,
		Description = "exceptional body control improves technique execution and combat footwork.",
		Modifiers = { CombatGainMult = 1.10, MasteryGainMult = 1.08 } },

	-- Clumsy: risk up, combat down, smarts up (learned helplessness = awareness)
	{ Id = "clumsy", Name = "Clumsy", Category = "Body", Rarity = "Common", Weight = 100,
		Description = "physically awkward, raising combat risk, but the constant self-correction builds awareness.",
		Modifiers = { RiskMult = 1.12, CombatGainMult = 0.90, SmartsGainMult = 1.06 } },

	-- Explosive Speed: combat and mission bonus
	{ Id = "explosive_speed", Name = "Explosive Speed", Category = "Body", Rarity = "Common", Weight = 100,
		Description = "bursts of speed improve combat and give a physical edge in dangerous situations.",
		Modifiers = { CombatGainMult = 1.10, MissionSuccessBonus = 2 } },

	-- Heavy Strikes: combat up, risk up slightly (committed swings leave openings)
	{ Id = "heavy_strikes", Name = "Heavy Strikes", Category = "Body", Rarity = "Uncommon", Weight = 55,
		Description = "hits harder than most but committed strikes leave brief openings.",
		Modifiers = { CombatGainMult = 1.16, RiskMult = 1.08 } },

	-- Light Frame: risk down (hard to hit), combat slightly lower (less mass)
	{ Id = "light_frame", Name = "Light Frame", Category = "Body", Rarity = "Common", Weight = 100,
		Description = "small and difficult to pin down, reducing risk at the cost of raw striking power.",
		Modifiers = { RiskMult = 0.90, CombatGainMult = 0.94 } },

	-- Iron Lungs: stamina-based combat up, happiness protected
	{ Id = "iron_lungs", Name = "Iron Lungs", Category = "Body", Rarity = "Common", Weight = 100,
		Description = "never runs out of breath, outlasting opponents and keeping stress in check.",
		Modifiers = { CombatGainMult = 1.08, HappinessLossMult = 0.92 } },

	-- Tense Shoulders: mastery down (tension = control problems), CE up (stored pressure)
	{ Id = "tense_shoulders", Name = "Tense Shoulders", Category = "Body", Rarity = "Uncommon", Weight = 55,
		Description = "constant physical tension disrupts fine technique but channels into raw CE output.",
		Modifiers = { MasteryGainMult = 0.90, CEGainMult = 1.10 } },

	-- Flexible Body: combat and mastery up slightly
	{ Id = "flexible_body", Name = "Flexible Body", Category = "Body", Rarity = "Common", Weight = 100,
		Description = "exceptional flexibility improves combat range and technique execution.",
		Modifiers = { CombatGainMult = 1.06, MasteryGainMult = 1.06 } },

	-- Brittle Bones: risk up significantly, combat down
	{ Id = "brittle_bones", Name = "Brittle Bones", Category = "Body", Rarity = "Common", Weight = 100,
		Description = "fragile frame makes physical confrontations significantly more dangerous.",
		Modifiers = { RiskMult = 1.22, CombatGainMult = 0.86 } },

	-- Cursed Energy Heavenly Restriction: Mechamaru-style body cost for massive CE reach
	{ Id = "cursed_energy_heavenly_restriction", Name = "Cursed Energy Heavenly Restriction", Category = "Body", Rarity = "Mythic", Weight = 3,
		Description = "a fragile body pays the price for monstrous cursed energy range and output.",
		Modifiers = { StartingCEBonus = 34, CEGainMult = 1.32, MasteryGainMult = 1.12, MissionSuccessBonus = 4, RiskMult = 1.20, CombatGainMult = 0.94, HealthGainMult = 0.82 } },

	----------------------------------------------------------------
	-- CLAN BLOODLINE
	----------------------------------------------------------------

	-- Blessed Birth: strong starting CE, mastery, inheritance
	{ Id = "blessed_birth", Name = "Blessed Birth", Category = "ClanBloodline", Rarity = "Rare", Weight = 18,
		Description = "born under favorable signs with a strong bloodline foundation.",
		Modifiers = { StartingCEBonus = 14, MasteryGainMult = 1.16, InheritanceBonus = 12, RarityPower = 2 } },

	-- Inherited Instinct: starting CE and mastery, inheritance
	{ Id = "inherited_instinct", Name = "Inherited Instinct", Category = "ClanBloodline", Rarity = "Uncommon", Weight = 55,
		Description = "bloodline knowledge surfaces early, boosting starting CE and technique instinct.",
		Modifiers = { StartingCEBonus = 8, MasteryGainMult = 1.12, InheritanceBonus = 10 } },

	-- Fallen Bloodline: inheritance and relationship up, happiness fragile
	{ Id = "fallen_bloodline", Name = "Fallen Bloodline", Category = "ClanBloodline", Rarity = "Uncommon", Weight = 55,
		Description = "carries the weight of a collapsed lineage, which bonds people differently.",
		Modifiers = { InheritanceBonus = 6, RelationshipGainMult = 1.06, HappinessLossMult = 1.08 } },

	-- Clan Favorite: strong inheritance, relationship, grade up
	{ Id = "clan_favorite", Name = "Clan Favorite", Category = "ClanBloodline", Rarity = "Rare", Weight = 18,
		Description = "the bloodline's chosen one. Inheritance, bonds, and grade progress all improve.",
		Modifiers = { InheritanceBonus = 8, RelationshipGainMult = 1.10, GradeProgressMult = 1.10, RarityPower = 2 } },

	-- Clan Disappointment: stress up, grade progress up (spite as fuel)
	{ Id = "clan_disappointment", Name = "Clan Disappointment", Category = "ClanBloodline", Rarity = "Uncommon", Weight = 55,
		Description = "failing the family's expectations creates pressure that ironically pushes grade progress.",
		Modifiers = { StressMult = 1.14, GradeProgressMult = 1.10, HappinessLossMult = 1.10 } },

	-- Branch Family Talent: inheritance and CE up, smarts up slightly
	{ Id = "branch_family_talent", Name = "Branch Family Talent", Category = "ClanBloodline", Rarity = "Uncommon", Weight = 55,
		Description = "talent from a side branch of the family that was never fully recognized.",
		Modifiers = { InheritanceBonus = 6, CEGainMult = 1.08, SmartsGainMult = 1.06 } },

	-- Main Family Pressure: stress up, grade and mastery up significantly
	{ Id = "main_family_pressure", Name = "Main Family Pressure", Category = "ClanBloodline", Rarity = "Rare", Weight = 18,
		Description = "main family expectations are crushing but drive mastery and grade progress hard.",
		Modifiers = { StressMult = 1.18, GradeProgressMult = 1.14, MasteryGainMult = 1.12, RarityPower = 2 } },

	-- Old Blood Memory: starting CE, mastery, inheritance
	{ Id = "old_blood_memory", Name = "Old Blood Memory", Category = "ClanBloodline", Rarity = "Uncommon", Weight = 55,
		Description = "ancestral technique memory surfaces during training, sharpening CE and mastery.",
		Modifiers = { StartingCEBonus = 8, MasteryGainMult = 1.12, InheritanceBonus = 8 } },

	-- Bloodline Echo: starting CE, mastery, inheritance
	{ Id = "bloodline_echo", Name = "Bloodline Echo", Category = "ClanBloodline", Rarity = "Uncommon", Weight = 55,
		Description = "echoes of older generations resonate in cursed energy and technique instinct.",
		Modifiers = { StartingCEBonus = 8, CEGainMult = 1.08, InheritanceBonus = 8 } },

	-- Dormant Heir: strong starting CE, mastery, awakening, inheritance
	{ Id = "dormant_heir", Name = "Dormant Heir", Category = "ClanBloodline", Rarity = "Rare", Weight = 18,
		Description = "bloodline potential is buried but substantial. Awakening, CE, and mastery all climb faster.",
		Modifiers = { StartingCEBonus = 12, MasteryGainMult = 1.16, AwakeningChanceBonus = 5, InheritanceBonus = 10, RarityPower = 2 } },

	-- Lost Heir: inheritance and CE up, happiness fragile (identity crisis)
	{ Id = "lost_heir", Name = "Lost Heir", Category = "ClanBloodline", Rarity = "Uncommon", Weight = 55,
		Description = "disconnected from the bloodline but carrying its potential without knowing it.",
		Modifiers = { InheritanceBonus = 6, CEGainMult = 1.08, HappinessLossMult = 1.08 } },

	-- Pure Lineage: inheritance and mastery up, relationship slightly slower (elitism)
	{ Id = "pure_lineage", Name = "Pure Lineage", Category = "ClanBloodline", Rarity = "Uncommon", Weight = 55,
		Description = "unbroken lineage strengthens technique inheritance and mastery but breeds distance.",
		Modifiers = { InheritanceBonus = 8, MasteryGainMult = 1.10, RelationshipGainMult = 0.94 } },

	-- Mixed Lineage: inheritance and CE up, adaptability bonus
	{ Id = "mixed_lineage", Name = "Mixed Lineage", Category = "ClanBloodline", Rarity = "Rare", Weight = 18,
		Description = "multiple bloodlines converging creates unpredictable but powerful cursed energy.",
		Modifiers = { InheritanceBonus = 6, CEGainMult = 1.14, MasteryGainMult = 1.10, RarityPower = 2 } },

	-- Cursed Ancestor: CE up, risk up, inheritance
	{ Id = "cursed_ancestor", Name = "Cursed Ancestor", Category = "ClanBloodline", Rarity = "Uncommon", Weight = 55,
		Description = "a dark ancestor's cursed energy echoes forward, boosting CE but adding inherited risk.",
		Modifiers = { CEGainMult = 1.10, InheritanceBonus = 6, RiskMult = 1.08 } },

	-- Honored Descendant: relationship and grade up, inheritance
	{ Id = "honored_descendant", Name = "Honored Descendant", Category = "ClanBloodline", Rarity = "Uncommon", Weight = 55,
		Description = "carries a respected family name that opens doors and pushes personal ambition.",
		Modifiers = { InheritanceBonus = 6, RelationshipGainMult = 1.08, GradeProgressMult = 1.06 } },

	-- Family Shame: stress up, grade and CE up (shame as fuel)
	{ Id = "family_shame", Name = "Family Shame", Category = "ClanBloodline", Rarity = "Rare", Weight = 18,
		Description = "the family name is a burden. The weight of shame pushes CE and grade progress hard.",
		Modifiers = { StressMult = 1.18, GradeProgressMult = 1.12, CEGainMult = 1.12, RarityPower = 2 } },

	-- Family Hope: relationship and inheritance up, happiness protected
	{ Id = "family_hope", Name = "Family Hope", Category = "ClanBloodline", Rarity = "Uncommon", Weight = 55,
		Description = "the family's hope rests here. That support keeps spirits up and bonds strong.",
		Modifiers = { InheritanceBonus = 6, RelationshipGainMult = 1.08, HappinessLossMult = 0.88 } },

	-- Inherited Grudge: CE and combat up, happiness fragile (resentment)
	{ Id = "inherited_grudge", Name = "Inherited Grudge", Category = "ClanBloodline", Rarity = "Uncommon", Weight = 55,
		Description = "a generational grudge fuels cursed energy and combat but leaves happiness fragile.",
		Modifiers = { CEGainMult = 1.10, CombatGainMult = 1.08, HappinessLossMult = 1.12 } },

	-- Name Carrier: inheritance, grade, relationship all up
	{ Id = "name_carrier", Name = "Name Carrier", Category = "ClanBloodline", Rarity = "Rare", Weight = 18,
		Description = "carries the family name with full weight. Grade, bonds, and inheritance all benefit.",
		Modifiers = { InheritanceBonus = 8, GradeProgressMult = 1.10, RelationshipGainMult = 1.10, RarityPower = 2 } },

	-- Hidden Pedigree: CE and mastery up, smarts up (unrecognized talent)
	{ Id = "hidden_pedigree", Name = "Hidden Pedigree", Category = "ClanBloodline", Rarity = "Uncommon", Weight = 55,
		Description = "true bloodline potential is hidden, allowing independent growth without expectation.",
		Modifiers = { CEGainMult = 1.10, MasteryGainMult = 1.08, SmartsGainMult = 1.06 } },

	-- Forgotten Branch: CE and inheritance up, smarts slightly up
	{ Id = "forgotten_branch", Name = "Forgotten Branch", Category = "ClanBloodline", Rarity = "Uncommon", Weight = 55,
		Description = "a branch of the family no one tracks anymore, carrying quiet potential.",
		Modifiers = { CEGainMult = 1.08, InheritanceBonus = 6, SmartsGainMult = 1.06 } },

	-- Clan Politics Magnet: relationship up, risk up (politics = enemies)
	{ Id = "clan_politics_magnet", Name = "Clan Politics Magnet", Category = "ClanBloodline", Rarity = "Rare", Weight = 18,
		Description = "drawn into clan politics whether willing or not. Bonds grow faster but enemies follow.",
		Modifiers = { InheritanceBonus = 6, RelationshipGainMult = 1.12, RiskMult = 1.12, RarityPower = 2 } },

	-- Ancestral Dreams: CE and awakening up
	{ Id = "ancestral_dreams", Name = "Ancestral Dreams", Category = "ClanBloodline", Rarity = "Uncommon", Weight = 55,
		Description = "ancestors appear in dreams, passing down CE instincts and awakening hints.",
		Modifiers = { CEGainMult = 1.10, AwakeningChanceBonus = 4, InheritanceBonus = 4 } },

	-- Rival Clan Mark: combat and CE up, relationship slightly slower
	{ Id = "rival_clan_mark", Name = "Rival Clan Mark", Category = "ClanBloodline", Rarity = "Uncommon", Weight = 55,
		Description = "born into a rivalry, this mark pushes combat and CE forward but creates tension.",
		Modifiers = { CombatGainMult = 1.10, CEGainMult = 1.08, RelationshipGainMult = 0.92 } },

	-- Rare Mutation: strong starting CE, mastery, awakening
	{ Id = "rare_mutation", Name = "Rare Mutation", Category = "ClanBloodline", Rarity = "Rare", Weight = 18,
		Description = "a spontaneous bloodline mutation producing unusual cursed energy and awakening potential.",
		Modifiers = { StartingCEBonus = 14, MasteryGainMult = 1.16, AwakeningChanceBonus = 6, RarityPower = 2 } },

	-- Bloodline Pressure: stress up, CE and grade up
	{ Id = "bloodline_pressure", Name = "Bloodline Pressure", Category = "ClanBloodline", Rarity = "Uncommon", Weight = 55,
		Description = "bloodline expectations create constant pressure that pushes CE and grade progress.",
		Modifiers = { StressMult = 1.10, CEGainMult = 1.08, GradeProgressMult = 1.08 } },

	-- Legacy Burden: stress and happiness fragile, mastery and grade up significantly
	{ Id = "legacy_burden", Name = "Legacy Burden", Category = "ClanBloodline", Rarity = "Uncommon", Weight = 55,
		Description = "a heavy legacy to carry. Emotional cost is real but mastery and grade advance faster.",
		Modifiers = { StressMult = 1.14, HappinessLossMult = 1.12, MasteryGainMult = 1.12, GradeProgressMult = 1.08 } },

	-- Legacy Spark: inheritance, CE, and mastery up
	{ Id = "legacy_spark", Name = "Legacy Spark", Category = "ClanBloodline", Rarity = "Rare", Weight = 18,
		Description = "a generational spark of technique potential that surfaces suddenly and clearly.",
		Modifiers = { InheritanceBonus = 8, CEGainMult = 1.12, MasteryGainMult = 1.14, RarityPower = 2 } },

	-- Traditional Upbringing: mastery and smarts up, relationship up slightly
	{ Id = "traditional_upbringing", Name = "Traditional Upbringing", Category = "ClanBloodline", Rarity = "Uncommon", Weight = 55,
		Description = "strict traditional training builds solid mastery and smarts from an early age.",
		Modifiers = { MasteryGainMult = 1.10, SmartsGainMult = 1.06, RelationshipGainMult = 1.04 } },

	-- Broken Household: happiness fragile, CE and combat up (survival instinct)
	{ Id = "broken_household", Name = "Broken Household", Category = "ClanBloodline", Rarity = "Uncommon", Weight = 55,
		Description = "a fractured upbringing leaves emotional scars but builds raw survival instincts.",
		Modifiers = { HappinessLossMult = 1.14, CEGainMult = 1.10, CombatGainMult = 1.08 } },

	----------------------------------------------------------------
	-- DARK RARE
	----------------------------------------------------------------

	-- Heavenly Tempered: legendary physical combat, CE weaker
	{ Id = "heavenly_tempered", Name = "Heavenly Tempered", Category = "DarkRare", Rarity = "Legendary", Weight = 5,
		Description = "body refined to an extreme. Physical combat and health surge but cursed energy growth suffers.",
		Modifiers = { StartingHealthBonus = 12, CombatGainMult = 1.30, MasteryGainMult = 1.18, CEGainMult = 0.82, RarityPower = 4 } },

	-- Cursed Mark: strong CE, risk, encounters
	{ Id = "cursed_mark", Name = "Cursed Mark", Category = "DarkRare", Rarity = "Rare", Weight = 18,
		Description = "a cursed mark that accelerates CE and awakening but draws dangerous attention.",
		Modifiers = { CEGainMult = 1.20, AwakeningChanceBonus = 6, RiskMult = 1.20, RarityPower = 2 } },

	-- Omen Child: CE, mastery, awakening up, risk up
	{ Id = "omen_child", Name = "Omen Child", Category = "DarkRare", Rarity = "Rare", Weight = 18,
		Description = "born under a bad omen. Cursed power comes naturally but dangerous events follow.",
		Modifiers = { CEGainMult = 1.18, MasteryGainMult = 1.12, AwakeningChanceBonus = 5, RiskMult = 1.18, RarityPower = 2 } },

	-- Disaster Magnet: legendary CE, awakening, risk
	{ Id = "disaster_magnet", Name = "Disaster Magnet", Category = "DarkRare", Rarity = "Legendary", Weight = 5,
		Description = "cursed energy pours in naturally but catastrophe follows. CE and awakening are exceptional, risk is severe.",
		Modifiers = { CEGainMult = 1.28, AwakeningChanceBonus = 8, RiskMult = 1.28, MasteryGainMult = 1.14, RarityPower = 4 } },

	-- Cursed Womb Touched: strong starting CE, grade floor, risk
	{ Id = "cursed_womb_touched", Name = "Cursed Womb Touched", Category = "DarkRare", Rarity = "Rare", Weight = 18,
		Description = "touched by a cursed womb's energy. Starts with a high CE floor and natural grade advantage.",
		Modifiers = { StartingCEBonus = 35, GradeFloor = "Grade 2", CEGainMult = 1.14, RiskMult = 1.18, RarityPower = 2 } },

	-- Death Painting Blood: starting CE, grade floor, CE growth
	{ Id = "death_painting_blood", Name = "Death Painting Blood", Category = "Legacy", Rarity = "Rare", Weight = 0,
		Description = "blood from a Death Painting. Exceptional starting CE and grade floor.",
		Modifiers = { StartingCEBonus = 35, GradeFloor = "Grade 2", CEGainMult = 1.16, MasteryGainMult = 1.10, RarityPower = 2 } },

	-- Void-Touched: legendary starting CE, mastery, awakening, risk
	{ Id = "void_touched", Name = "Void-Touched", Category = "DarkRare", Rarity = "Legendary", Weight = 5,
		Description = "touched by something beyond normal cursed energy. Starting CE, mastery, and awakening are all exceptional.",
		Modifiers = { StartingCEBonus = 20, CEGainMult = 1.22, MasteryGainMult = 1.20, AwakeningChanceBonus = 8, RiskMult = 1.18, RarityPower = 4 } },

	-- Moon-Cursed: CE, awakening, risk
	{ Id = "moon_cursed", Name = "Moon-Cursed", Category = "DarkRare", Rarity = "Rare", Weight = 18,
		Description = "cursed energy responds to unseen cycles, improving CE and awakening but adding instability.",
		Modifiers = { StartingCEBonus = 10, CEGainMult = 1.14, AwakeningChanceBonus = 5, RiskMult = 1.12, RarityPower = 2 } },

	-- Spirit Watched: mastery, CE, risk slightly up
	{ Id = "spirit_watched", Name = "Spirit Watched", Category = "DarkRare", Rarity = "Rare", Weight = 18,
		Description = "something watches and reinforces this person's growth. Mastery and CE both advance faster.",
		Modifiers = { StartingCEBonus = 10, MasteryGainMult = 1.14, CEGainMult = 1.12, RiskMult = 1.10, RarityPower = 2 } },

	-- Haunted Dreams: legendary CE, mastery, awakening, happiness fragile
	{ Id = "haunted_dreams", Name = "Haunted Dreams", Category = "DarkRare", Rarity = "Legendary", Weight = 5,
		Description = "something teaches through nightmares. CE, mastery, and awakening all reach exceptional heights, but happiness is fragile.",
		Modifiers = { StartingCEBonus = 16, CEGainMult = 1.24, MasteryGainMult = 1.22, AwakeningChanceBonus = 8, HappinessLossMult = 1.18, RarityPower = 4 } },

	-- Bad Luck Vessel: risk up significantly, CE and mastery up (adversity = growth)
	{ Id = "bad_luck_vessel", Name = "Bad Luck Vessel", Category = "DarkRare", Rarity = "Rare", Weight = 18,
		Description = "misfortune follows constantly but every near-miss sharpens CE and technique.",
		Modifiers = { StartingCEBonus = 8, RiskMult = 1.20, CEGainMult = 1.14, MasteryGainMult = 1.10, RarityPower = 2 } },

	-- Miracle Survivor: awakening and mastery up, risk down (luck out of danger)
	{ Id = "miracle_survivor", Name = "Miracle Survivor", Category = "DarkRare", Rarity = "Rare", Weight = 18,
		Description = "survives things they shouldn't. Each near-death sharpens awakening and mastery.",
		Modifiers = { AwakeningChanceBonus = 8, MasteryGainMult = 1.20, RiskMult = 0.88, RarityPower = 2 } },

	-- Near-Death Spark: legendary awakening, mastery, CE
	{ Id = "near_death_spark", Name = "Near-Death Spark", Category = "DarkRare", Rarity = "Legendary", Weight = 5,
		Description = "nearly died and something woke up. Awakening, mastery, and CE are all dramatically stronger.",
		Modifiers = { AwakeningChanceBonus = 12, MasteryGainMult = 1.28, CEGainMult = 1.22, StartingCEBonus = 14, RarityPower = 4 } },

	-- Malevolent Aura: combat and CE up, relationship slower
	{ Id = "malevolent_aura", Name = "Malevolent Aura", Category = "DarkRare", Rarity = "Rare", Weight = 18,
		Description = "something dark in the cursed energy pushes combat and CE but unsettles people nearby.",
		Modifiers = { CEGainMult = 1.14, CombatGainMult = 1.16, RelationshipGainMult = 0.88, RarityPower = 2 } },

	-- Blessed by Chance: CE, mastery, risk slightly down
	{ Id = "blessed_by_chance", Name = "Blessed by Chance", Category = "DarkRare", Rarity = "Rare", Weight = 18,
		Description = "good fortune follows without reason. CE and mastery grow faster and danger is slightly less.",
		Modifiers = { StartingCEBonus = 10, CEGainMult = 1.12, MasteryGainMult = 1.12, RiskMult = 0.90, RarityPower = 2 } },

	-- Unnatural Calm: legendary risk reduction, mastery, happiness protection
	{ Id = "unnatural_calm", Name = "Unnatural Calm", Category = "DarkRare", Rarity = "Legendary", Weight = 5,
		Description = "nothing shakes this person. Risk is dramatically reduced and mastery grows cleanly under any pressure.",
		Modifiers = { RiskMult = 0.70, MasteryGainMult = 1.26, HappinessLossMult = 0.72, MissionSuccessBonus = 6, RarityPower = 4 } },

	-- Forbidden Talent: awakening, mastery, CE up, risk up
	{ Id = "forbidden_talent", Name = "Forbidden Talent", Category = "DarkRare", Rarity = "Rare", Weight = 18,
		Description = "a technique capability that shouldn't exist yet. Awakening, mastery, and CE surge with matching danger.",
		Modifiers = { AwakeningChanceBonus = 8, MasteryGainMult = 1.20, CEGainMult = 1.16, RiskMult = 1.14, RarityPower = 2 } },

	-- Fate Resistant: risk down, mastery up, mission bonus
	{ Id = "fate_resistant", Name = "Fate Resistant", Category = "DarkRare", Rarity = "Rare", Weight = 18,
		Description = "defies bad outcomes with unusual consistency. Risk stays lower and missions go better.",
		Modifiers = { RiskMult = 0.82, MasteryGainMult = 1.14, MissionSuccessBonus = 4, RarityPower = 2 } },

	-- Fate Bound: legendary mastery, CE, grade, risk
	{ Id = "fate_bound", Name = "Fate Bound", Category = "DarkRare", Rarity = "Legendary", Weight = 5,
		Description = "destiny pulls hard in one direction. Mastery, CE, and grade all accelerate, but the path is dangerous.",
		Modifiers = { MasteryGainMult = 1.26, CEGainMult = 1.22, GradeProgressMult = 1.20, RiskMult = 1.18, RarityPower = 4 } },

	-- Calamity Seed: CE, combat, risk all up significantly
	{ Id = "calamity_seed", Name = "Calamity Seed", Category = "DarkRare", Rarity = "Rare", Weight = 18,
		Description = "a seed of disaster growing quietly. CE and combat push higher as danger intensifies.",
		Modifiers = { CEGainMult = 1.16, CombatGainMult = 1.14, RiskMult = 1.18, RarityPower = 2 } },

	-- Ancient Echo: CE, mastery, inheritance up
	{ Id = "ancient_echo", Name = "Ancient Echo", Category = "DarkRare", Rarity = "Rare", Weight = 18,
		Description = "echoes of an ancient sorcerer's power reverberate through this bloodline.",
		Modifiers = { CEGainMult = 1.14, MasteryGainMult = 1.14, InheritanceBonus = 10, RarityPower = 2 } },

	-- Unstable Soul: legendary CE and awakening, mastery and happiness fragile
	{ Id = "unstable_soul", Name = "Unstable Soul", Category = "DarkRare", Rarity = "Legendary", Weight = 5,
		Description = "soul and cursed energy are in constant flux. CE and awakening are exceptional, but control and happiness suffer.",
		Modifiers = { CEGainMult = 1.30, AwakeningChanceBonus = 10, MasteryGainMult = 0.84, HappinessLossMult = 1.22, RarityPower = 4 } },

	-- Split Instinct: combat and mastery up, smarts up, risk up slightly
	{ Id = "split_instinct", Name = "Split Instinct", Category = "DarkRare", Rarity = "Rare", Weight = 18,
		Description = "instincts split between offense and analysis, producing strong combat and technique reads.",
		Modifiers = { CombatGainMult = 1.14, MasteryGainMult = 1.12, SmartsGainMult = 1.10, RarityPower = 2 } },

	-- Predator Sense: mission bonus, combat, risk down
	{ Id = "predator_sense", Name = "Predator Sense", Category = "DarkRare", Rarity = "Rare", Weight = 18,
		Description = "reads danger and targets like a predator. Mission success, combat, and safety all improve.",
		Modifiers = { MissionSuccessBonus = 6, CombatGainMult = 1.16, RiskMult = 0.86, RarityPower = 2 } },

	-- Star-Crossed: legendary CE, romance and happiness fragile
	{ Id = "star_crossed", Name = "Star-Crossed", Category = "DarkRare", Rarity = "Legendary", Weight = 5,
		Description = "marked by fate for something extraordinary. CE is exceptional but romance and happiness are constantly tested.",
		Modifiers = { CEGainMult = 1.28, MasteryGainMult = 1.18, RomanceGainMult = 0.78, HappinessLossMult = 1.22, RarityPower = 4 } },

	-- Marked by Higher-Ups: mission bonus, grade up, risk up
	{ Id = "marked_by_higher_ups", Name = "Marked by Higher-Ups", Category = "DarkRare", Rarity = "Rare", Weight = 18,
		Description = "the higher-ups have their eye on this person. Missions and grade benefit, but attention brings risk.",
		Modifiers = { MissionSuccessBonus = 6, GradeProgressMult = 1.14, RiskMult = 1.14, RarityPower = 2 } },

	-- Vessel Candidate: CE and awakening up significantly, risk up
	{ Id = "vessel_candidate", Name = "Vessel Candidate", Category = "DarkRare", Rarity = "Rare", Weight = 18,
		Description = "a body considered for a cursed vessel. CE and awakening are exceptional but danger follows.",
		Modifiers = { CEGainMult = 1.18, AwakeningChanceBonus = 8, RiskMult = 1.16, RarityPower = 2 } },

	-- Curse Bait: legendary CE, awakening, risk — the highest risk trait
	{ Id = "curse_bait", Name = "Curse Bait", Category = "DarkRare", Rarity = "Legendary", Weight = 5,
		Description = "curses are drawn to this person instinctively. CE and awakening reach extreme heights, but danger is constant.",
		Modifiers = { CEGainMult = 1.32, AwakeningChanceBonus = 10, RiskMult = 1.32, CombatGainMult = 1.14, RarityPower = 4 } },

	-- Doomed Genius: mastery and CE excellent, risk up, happiness fragile
	{ Id = "doomed_genius", Name = "Doomed Genius", Category = "DarkRare", Rarity = "Rare", Weight = 18,
		Description = "brilliant but marked for tragedy. Mastery and CE grow fast while risk and emotional cost build.",
		Modifiers = { MasteryGainMult = 1.20, CEGainMult = 1.16, RiskMult = 1.16, HappinessLossMult = 1.14, RarityPower = 2 } },

	-- Impossible Potential: awakening, mastery, CE all up significantly
	{ Id = "impossible_potential", Name = "Impossible Potential", Category = "DarkRare", Rarity = "Rare", Weight = 18,
		Description = "potential that shouldn't exist at this age. Awakening, mastery, and CE are all dramatically higher.",
		Modifiers = { AwakeningChanceBonus = 10, MasteryGainMult = 1.22, CEGainMult = 1.18, RarityPower = 2 } },

	----------------------------------------------------------------
	-- DOJO CAREER
	-- DojoTrainingMult removed (nothing reads it).
	-- Replaced with real modifier combos that match each trait's flavor.
	----------------------------------------------------------------

	-- Strict Teacher: mastery and grade up, kid bonds up, relationships slightly slower
	{ Id = "strict_teacher", Name = "Strict Teacher", Category = "DojoCareer", Rarity = "Uncommon", Weight = 55,
		Description = "demands the best from students. Mastery and grade advance faster but warmth suffers.",
		Modifiers = { MasteryGainMult = 1.12, GradeProgressMult = 1.08, KidBondGainMult = 1.10, RelationshipGainMult = 0.92 } },

	-- Patient Teacher: mastery and kid bonds up, happiness protected
	{ Id = "patient_teacher", Name = "Patient Teacher", Category = "DojoCareer", Rarity = "Common", Weight = 100,
		Description = "takes time with students, building genuine bonds and steady mastery progress.",
		Modifiers = { MasteryGainMult = 1.08, KidBondGainMult = 1.14, HappinessLossMult = 0.90 } },

	-- Cruel Mentor: mastery and grade up significantly, relationships suffer
	{ Id = "cruel_mentor", Name = "Cruel Mentor", Category = "DojoCareer", Rarity = "Common", Weight = 100,
		Description = "brutal training methods push mastery and grade hard, but bonds break under the pressure.",
		Modifiers = { MasteryGainMult = 1.14, GradeProgressMult = 1.10, RelationshipGainMult = 0.86 } },

	-- Beloved Mentor: kid bonds, family, and relationship all up
	{ Id = "beloved_mentor", Name = "Beloved Mentor", Category = "DojoCareer", Rarity = "Uncommon", Weight = 55,
		Description = "students and family alike adore this person, making all bonds grow faster.",
		Modifiers = { KidBondGainMult = 1.16, FamilyGainMult = 1.12, RelationshipGainMult = 1.10 } },

	-- Dojo Builder: mastery and CE up slightly, money up
	{ Id = "dojo_builder", Name = "Dojo Builder", Category = "DojoCareer", Rarity = "Common", Weight = 100,
		Description = "natural instinct for building systems and training structures.",
		Modifiers = { MasteryGainMult = 1.06, CEGainMult = 1.05, MoneyGainMult = 1.06 } },

	-- Recruit Whisperer: relationship and kid bonds up, smarts up slightly
	{ Id = "recruit_whisperer", Name = "Recruit Whisperer", Category = "DojoCareer", Rarity = "Common", Weight = 100,
		Description = "reads potential recruits accurately and builds trust fast.",
		Modifiers = { RelationshipGainMult = 1.08, KidBondGainMult = 1.08, SmartsGainMult = 1.05 } },

	-- Training Maniac: mastery and CE up, happiness slightly fragile
	{ Id = "training_maniac", Name = "Training Maniac", Category = "DojoCareer", Rarity = "Uncommon", Weight = 55,
		Description = "trains obsessively, pushing mastery and CE faster at the cost of rest.",
		Modifiers = { MasteryGainMult = 1.14, CEGainMult = 1.10, HappinessLossMult = 1.08 } },

	-- Theory Nerd: smarts and mastery up, CE slightly up
	{ Id = "theory_nerd", Name = "Theory Nerd", Category = "DojoCareer", Rarity = "Common", Weight = 100,
		Description = "deep theoretical understanding of jujutsu improves smarts, mastery, and CE insight.",
		Modifiers = { SmartsGainMult = 1.10, MasteryGainMult = 1.08, CEGainMult = 1.05 } },

	-- Practical Teacher: mastery and mission bonus, grade up slightly
	{ Id = "practical_teacher", Name = "Practical Teacher", Category = "DojoCareer", Rarity = "Common", Weight = 100,
		Description = "focused on real applications. Mastery and mission results improve together.",
		Modifiers = { MasteryGainMult = 1.08, MissionSuccessBonus = 3, GradeProgressMult = 1.05 } },

	-- Sparring Demon: combat and mastery up, risk slightly up
	{ Id = "sparring_demon", Name = "Sparring Demon", Category = "DojoCareer", Rarity = "Uncommon", Weight = 55,
		Description = "thrives in sparring sessions, improving combat and mastery through constant friction.",
		Modifiers = { CombatGainMult = 1.14, MasteryGainMult = 1.10, RiskMult = 1.08 } },

	-- Good With Kids: kid bonds and family up, happiness protected
	{ Id = "good_with_kids", Name = "Good With Kids", Category = "DojoCareer", Rarity = "Common", Weight = 100,
		Description = "naturally connects with younger students, keeping morale high.",
		Modifiers = { KidBondGainMult = 1.16, FamilyGainMult = 1.08, HappinessLossMult = 0.90 } },

	-- Bad With Kids: kid bonds slower, mastery up (focuses on adult technique)
	{ Id = "bad_with_kids", Name = "Bad With Kids", Category = "DojoCareer", Rarity = "Common", Weight = 100,
		Description = "uncomfortable with younger students but focuses that energy into personal technique.",
		Modifiers = { KidBondGainMult = 0.84, MasteryGainMult = 1.10 } },

	-- Student Favorite: relationship and romance up slightly, grade up
	{ Id = "student_favorite", Name = "Student Favorite", Category = "DojoCareer", Rarity = "Uncommon", Weight = 55,
		Description = "beloved by students, which opens social doors and reflects well on reputation.",
		Modifiers = { RelationshipGainMult = 1.10, GradeProgressMult = 1.08, RomanceGainMult = 1.06 } },

	-- Harsh Critic: mastery and grade up, relationships suffer
	{ Id = "harsh_critic", Name = "Harsh Critic", Category = "DojoCareer", Rarity = "Common", Weight = 100,
		Description = "unsparing feedback drives results but damages personal connections.",
		Modifiers = { MasteryGainMult = 1.12, GradeProgressMult = 1.08, RelationshipGainMult = 0.88 } },

	-- Clan Organizer: money and grade up, relationship up slightly
	{ Id = "clan_organizer", Name = "Clan Organizer", Category = "DojoCareer", Rarity = "Common", Weight = 100,
		Description = "natural organizational skill improves clan efficiency, money, and internal bonds.",
		Modifiers = { MoneyGainMult = 1.08, GradeProgressMult = 1.06, RelationshipGainMult = 1.05 } },

	-- Legacy Planner: inheritance and grade up, smarts up slightly
	{ Id = "legacy_planner", Name = "Legacy Planner", Category = "DojoCareer", Rarity = "Uncommon", Weight = 55,
		Description = "always thinking generations ahead. Inheritance, grade planning, and smarts all benefit.",
		Modifiers = { InheritanceBonus = 6, GradeProgressMult = 1.08, SmartsGainMult = 1.08 } },

	-- Money Minded: money up, smarts up slightly
	{ Id = "money_minded", Name = "Money Minded", Category = "DojoCareer", Rarity = "Common", Weight = 100,
		Description = "financial instincts keep the clan profitable and personal wealth growing.",
		Modifiers = { MoneyGainMult = 1.12, SmartsGainMult = 1.05 } },

	-- Poor Saver: money down, happiness protected (doesn't stress about it)
	{ Id = "poor_saver", Name = "Poor Saver", Category = "DojoCareer", Rarity = "Common", Weight = 100,
		Description = "spends freely and worries little, which costs money but preserves happiness.",
		Modifiers = { MoneyGainMult = 0.88, HappinessLossMult = 0.92 } },

	-- Lucky Investor: money up significantly
	{ Id = "lucky_investor", Name = "Lucky Investor", Category = "DojoCareer", Rarity = "Uncommon", Weight = 55,
		Description = "financial decisions land well more often than they should.",
		Modifiers = { MoneyGainMult = 1.18 } },

	-- Mission Workhorse: mission bonus, money up, grade up slightly
	{ Id = "mission_workhorse", Name = "Mission Workhorse", Category = "DojoCareer", Rarity = "Common", Weight = 100,
		Description = "gets missions done without fuss, improving success rates and financial returns.",
		Modifiers = { MissionSuccessBonus = 3, MoneyGainMult = 1.06, GradeProgressMult = 1.04 } },

	-- Paperwork Hater: money slightly down (sloppy records), grade up (hates admin, loves results)
	{ Id = "paperwork_hater", Name = "Paperwork Hater", Category = "DojoCareer", Rarity = "Common", Weight = 100,
		Description = "avoids bureaucracy, losing money on admin but pushing real grade results instead.",
		Modifiers = { MoneyGainMult = 0.92, GradeProgressMult = 1.08 } },

	-- Recommendation Magnet: grade and relationship up
	{ Id = "recommendation_magnet", Name = "Recommendation Magnet", Category = "DojoCareer", Rarity = "Uncommon", Weight = 55,
		Description = "earns recommendations through consistent performance, pushing grade and social standing.",
		Modifiers = { GradeProgressMult = 1.10, RelationshipGainMult = 1.08 } },

	-- Higher-Up Pleaser: grade and money up, relationship slightly slower (political)
	{ Id = "higher_up_pleaser", Name = "Higher-Up Pleaser", Category = "DojoCareer", Rarity = "Common", Weight = 100,
		Description = "knows how to manage up. Grade and money benefit from institutional approval.",
		Modifiers = { GradeProgressMult = 1.08, MoneyGainMult = 1.08, RelationshipGainMult = 0.94 } },

	-- Rule Breaker: CE and combat up, risk up, grade slower (out of favor)
	{ Id = "rule_breaker", Name = "Rule Breaker", Category = "DojoCareer", Rarity = "Common", Weight = 100,
		Description = "ignores the system and finds shortcuts. CE and combat benefit but the institution notices.",
		Modifiers = { CEGainMult = 1.08, CombatGainMult = 1.08, RiskMult = 1.12, GradeProgressMult = 0.92 } },

	-- Quiet Professional: mastery and smarts up, risk down slightly
	{ Id = "quiet_professional", Name = "Quiet Professional", Category = "DojoCareer", Rarity = "Uncommon", Weight = 55,
		Description = "gets results without drawing attention. Clean, efficient, and hard to target.",
		Modifiers = { MasteryGainMult = 1.10, SmartsGainMult = 1.08, RiskMult = 0.90 } },

	-- Risk Manager: risk down, mission bonus, smarts up
	{ Id = "risk_manager", Name = "Risk Manager", Category = "DojoCareer", Rarity = "Common", Weight = 100,
		Description = "calculates danger carefully, reducing bad outcomes and improving mission reads.",
		Modifiers = { RiskMult = 0.88, MissionSuccessBonus = 3, SmartsGainMult = 1.06 } },

	-- Scout Eye: smarts, mission bonus, risk down
	{ Id = "scout_eye", Name = "Scout Eye", Category = "DojoCareer", Rarity = "Common", Weight = 100,
		Description = "sharp scouting instincts improve mission preparation and reduce surprised encounters.",
		Modifiers = { SmartsGainMult = 1.08, MissionSuccessBonus = 3, RiskMult = 0.92 } },

	-- Trainee Crusher: mastery and grade up, kid bonds suffer
	{ Id = "trainee_crusher", Name = "Trainee Crusher", Category = "DojoCareer", Rarity = "Uncommon", Weight = 55,
		Description = "relentless in pushing trainees, improving mastery and grade but damaging junior bonds.",
		Modifiers = { MasteryGainMult = 1.14, GradeProgressMult = 1.10, KidBondGainMult = 0.82 } },

	-- Protective Sensei: kid bonds and family up, risk slightly up
	{ Id = "protective_sensei", Name = "Protective Sensei", Category = "DojoCareer", Rarity = "Common", Weight = 100,
		Description = "puts students and family above self, which strengthens bonds but draws more danger.",
		Modifiers = { KidBondGainMult = 1.14, FamilyGainMult = 1.10, RiskMult = 1.08 } },

	-- Inspirational Speaker: relationship, grade, and CE up
	{ Id = "inspirational_speaker", Name = "Inspirational Speaker", Category = "DojoCareer", Rarity = "Common", Weight = 100,
		Description = "words that push others forward. Relationships, grade momentum, and CE all benefit.",
		Modifiers = { RelationshipGainMult = 1.10, GradeProgressMult = 1.06, CEGainMult = 1.05 } },

	----------------------------------------------------------------
	-- LIFE FLAVOR
	-- LifeEventFlavor removed. Each trait now has a real modifier matching its name.
	----------------------------------------------------------------

	-- City Kid: money and smarts up (urban survival)
	{ Id = "city_kid", Name = "City Kid", Category = "LifeFlavor", Rarity = "Uncommon", Weight = 55,
		Description = "grew up in the city with street-smart instincts and access to more resources.",
		Modifiers = { MoneyGainMult = 1.06, SmartsGainMult = 1.06 } },

	-- Countryside Kid: CE and happiness up (peaceful upbringing, natural CE resonance)
	{ Id = "countryside_kid", Name = "Countryside Kid", Category = "LifeFlavor", Rarity = "Common", Weight = 100,
		Description = "quiet rural upbringing builds cursed energy resonance and emotional stability.",
		Modifiers = { CEGainMult = 1.06, HappinessLossMult = 0.90 } },

	-- Temple Raised: smarts and mastery up, CE slightly up
	{ Id = "temple_raised", Name = "Temple Raised", Category = "LifeFlavor", Rarity = "Common", Weight = 100,
		Description = "raised around spiritual discipline, sharpening smarts and technique instinct.",
		Modifiers = { SmartsGainMult = 1.10, MasteryGainMult = 1.06, CEGainMult = 1.04 } },

	-- Street Raised: money and combat up, risk slightly down
	{ Id = "street_raised", Name = "Street Raised", Category = "LifeFlavor", Rarity = "Uncommon", Weight = 55,
		Description = "survival on the streets sharpened instincts for money, combat, and danger.",
		Modifiers = { MoneyGainMult = 1.08, CombatGainMult = 1.08, RiskMult = 0.94 } },

	-- Orphan Tempered: CE and combat up, happiness fragile
	{ Id = "orphan_tempered", Name = "Orphan Tempered", Category = "LifeFlavor", Rarity = "Common", Weight = 100,
		Description = "hardship built resilience and cursed sensitivity but left emotional scars.",
		Modifiers = { CEGainMult = 1.08, CombatGainMult = 1.06, HappinessLossMult = 1.10 } },

	-- Rich Household: starting money bonus, risk down slightly
	{ Id = "rich_household", Name = "Rich Household", Category = "LifeFlavor", Rarity = "Common", Weight = 100,
		Description = "comfortable upbringing provides a financial head start and reduced early risk.",
		Modifiers = { StartingMoneyBonus = 2000, RiskMult = 0.94 } },

	-- Poor Household: CE up (adversity), money growth slower
	{ Id = "poor_household", Name = "Poor Household", Category = "LifeFlavor", Rarity = "Uncommon", Weight = 55,
		Description = "financial hardship sharpened cursed energy sensitivity but left money scarce.",
		Modifiers = { CEGainMult = 1.08, MoneyGainMult = 0.90 } },

	-- Quiet Childhood: mastery and smarts up (undisturbed focus)
	{ Id = "quiet_childhood", Name = "Quiet Childhood", Category = "LifeFlavor", Rarity = "Common", Weight = 100,
		Description = "a calm upbringing allowed uninterrupted focus on learning and technique.",
		Modifiers = { MasteryGainMult = 1.06, SmartsGainMult = 1.06 } },

	-- Chaotic Childhood: CE and combat up, happiness fragile
	{ Id = "chaotic_childhood", Name = "Chaotic Childhood", Category = "LifeFlavor", Rarity = "Common", Weight = 100,
		Description = "chaos forced early adaptation, sharpening CE and combat at an emotional cost.",
		Modifiers = { CEGainMult = 1.08, CombatGainMult = 1.06, HappinessLossMult = 1.08 } },

	-- Sheltered: starting money bonus, risk down, relationship slightly slower
	{ Id = "sheltered", Name = "Sheltered", Category = "LifeFlavor", Rarity = "Uncommon", Weight = 55,
		Description = "protected upbringing reduces risk but limits real-world social exposure.",
		Modifiers = { StartingMoneyBonus = 1500, RiskMult = 0.90, RelationshipGainMult = 0.92 } },

	-- Independent: money and CE up, family bonds slightly slower
	{ Id = "independent", Name = "Independent", Category = "LifeFlavor", Rarity = "Common", Weight = 100,
		Description = "self-reliant from an early age, building financial and cursed energy independence.",
		Modifiers = { MoneyGainMult = 1.06, CEGainMult = 1.06, FamilyGainMult = 0.92 } },

	-- Bookworm: smarts up, mastery up slightly, social slightly slower
	{ Id = "bookworm", Name = "Bookworm", Category = "LifeFlavor", Rarity = "Common", Weight = 100,
		Description = "reads everything. Smarts and mastery grow faster but social time suffers.",
		Modifiers = { SmartsGainMult = 1.12, MasteryGainMult = 1.05, RelationshipGainMult = 0.94 } },

	-- Troublemaker: combat and CE up, risk up, grade slower
	{ Id = "troublemaker", Name = "Troublemaker", Category = "LifeFlavor", Rarity = "Uncommon", Weight = 55,
		Description = "constant trouble sharpened instincts and cursed energy but hurt academic progress.",
		Modifiers = { CombatGainMult = 1.10, CEGainMult = 1.08, RiskMult = 1.10, GradeProgressMult = 0.92 } },

	-- Early Worker: money up, mastery slightly up
	{ Id = "early_worker", Name = "Early Worker", Category = "LifeFlavor", Rarity = "Common", Weight = 100,
		Description = "started working early, building financial habits and practical discipline.",
		Modifiers = { MoneyGainMult = 1.08, MasteryGainMult = 1.04 } },

	-- Family Cook: family and kid bonds up, happiness protected
	{ Id = "family_cook", Name = "Family Cook", Category = "LifeFlavor", Rarity = "Common", Weight = 100,
		Description = "feeding the family built warmth and bonds that linger throughout life.",
		Modifiers = { FamilyGainMult = 1.10, KidBondGainMult = 1.08, HappinessLossMult = 0.92 } },

	-- Night Owl: CE and smarts up slightly, happiness slightly fragile (poor sleep)
	{ Id = "night_owl", Name = "Night Owl", Category = "LifeFlavor", Rarity = "Uncommon", Weight = 55,
		Description = "thinks and trains best at night, sharpening CE and smarts at the cost of rest.",
		Modifiers = { CEGainMult = 1.07, SmartsGainMult = 1.07, HappinessLossMult = 1.07 } },

	-- Morning Person: happiness protected, grade up (structure and routine)
	{ Id = "morning_person", Name = "Morning Person", Category = "LifeFlavor", Rarity = "Common", Weight = 100,
		Description = "productive mornings build emotional stability and consistent grade progress.",
		Modifiers = { HappinessLossMult = 0.90, GradeProgressMult = 1.06 } },

	-- Rumor Magnet: relationship up (people know the name), risk slightly up
	{ Id = "rumor_magnet", Name = "Rumor Magnet", Category = "LifeFlavor", Rarity = "Common", Weight = 100,
		Description = "always the center of gossip, which builds name recognition but draws trouble.",
		Modifiers = { RelationshipGainMult = 1.06, RiskMult = 1.06 } },

	-- Lucky Smile: romance and relationship up slightly
	{ Id = "lucky_smile", Name = "Lucky Smile", Category = "LifeFlavor", Rarity = "Uncommon", Weight = 55,
		Description = "a disarming smile that makes people warm up faster.",
		Modifiers = { RomanceGainMult = 1.10, RelationshipGainMult = 1.08 } },

	-- Bad Reputation: relationship and romance slower, CE up (chip on shoulder)
	{ Id = "bad_reputation", Name = "Bad Reputation", Category = "LifeFlavor", Rarity = "Common", Weight = 100,
		Description = "a bad name makes social progress harder but the drive to prove everyone wrong feeds CE.",
		Modifiers = { RelationshipGainMult = 0.88, RomanceGainMult = 0.88, CEGainMult = 1.08 } },

	-- Clean Record: grade and relationship up slightly (trustworthy)
	{ Id = "clean_record", Name = "Clean Record", Category = "LifeFlavor", Rarity = "Common", Weight = 100,
		Description = "no skeletons. A clean history makes it easier to advance and build trust.",
		Modifiers = { GradeProgressMult = 1.06, RelationshipGainMult = 1.06 } },

	-- Minor Delinquent: combat and CE up, grade and money slightly down
	{ Id = "minor_delinquent", Name = "Minor Delinquent", Category = "LifeFlavor", Rarity = "Uncommon", Weight = 55,
		Description = "a rough youth sharpened instincts but left academic and financial habits behind.",
		Modifiers = { CombatGainMult = 1.08, CEGainMult = 1.06, GradeProgressMult = 0.92, MoneyGainMult = 0.92 } },

	-- Festival Lover: happiness protected, relationship up
	{ Id = "festival_lover", Name = "Festival Lover", Category = "LifeFlavor", Rarity = "Common", Weight = 100,
		Description = "finds joy in community events, keeping morale up and connections strong.",
		Modifiers = { HappinessLossMult = 0.90, RelationshipGainMult = 1.07 } },

	-- Rain Lover: CE and mastery up slightly (introspective)
	{ Id = "rain_lover", Name = "Rain Lover", Category = "LifeFlavor", Rarity = "Common", Weight = 100,
		Description = "finds focus in rain and quiet, sharpening CE resonance and technique reflection.",
		Modifiers = { CEGainMult = 1.06, MasteryGainMult = 1.05 } },

	-- Winter Born: CE and mastery up, happiness slightly fragile
	{ Id = "winter_born", Name = "Winter Born", Category = "LifeFlavor", Rarity = "Uncommon", Weight = 55,
		Description = "born in the coldest season, carrying a stillness that sharpens CE and mastery.",
		Modifiers = { CEGainMult = 1.08, MasteryGainMult = 1.07, HappinessLossMult = 1.06 } },

	-- Summer Born: relationship and happiness up (warmth)
	{ Id = "summer_born", Name = "Summer Born", Category = "LifeFlavor", Rarity = "Common", Weight = 100,
		Description = "natural warmth from a summer birth keeps happiness stable and bonds easy.",
		Modifiers = { RelationshipGainMult = 1.07, HappinessLossMult = 0.90 } },

	-- March Child: smarts and grade up (in-between season, adaptable)
	{ Id = "march_child", Name = "March Child", Category = "LifeFlavor", Rarity = "Common", Weight = 100,
		Description = "born between seasons, naturally adaptable with a sharp mind and steady progress.",
		Modifiers = { SmartsGainMult = 1.07, GradeProgressMult = 1.05 } },

	-- Quiet Talent: mastery and CE up, relationship slightly slower
	{ Id = "quiet_talent", Name = "Quiet Talent", Category = "LifeFlavor", Rarity = "Uncommon", Weight = 55,
		Description = "ability that goes unnoticed until it matters. Mastery and CE build quietly.",
		Modifiers = { MasteryGainMult = 1.10, CEGainMult = 1.08, RelationshipGainMult = 0.94 } },

	-- Loud Talent: relationship and grade up, risk slightly up (everyone watching)
	{ Id = "loud_talent", Name = "Loud Talent", Category = "LifeFlavor", Rarity = "Common", Weight = 100,
		Description = "ability that announces itself. Grade and bonds benefit from the attention.",
		Modifiers = { RelationshipGainMult = 1.07, GradeProgressMult = 1.07, RiskMult = 1.06 } },

	-- Ordinary Mask: risk down, smarts up (hides potential well)
	{ Id = "ordinary_mask", Name = "Ordinary Mask", Category = "LifeFlavor", Rarity = "Common", Weight = 100,
		Description = "presents as completely average, reducing threat assessment and sharpening quiet observation.",
		Modifiers = { RiskMult = 0.88, SmartsGainMult = 1.08 } },
	-- Technique evolution markers: earned when a cursed technique advances stages.
	{ Id = "technique_refined", Name = "Technique Refined", Category = "TechniqueEvolution", Rarity = "Uncommon", Weight = 0,
		Description = "your cursed technique has stabilized into a refined form.",
		Modifiers = { MasteryGainMult = 1.06, CombatGainMult = 1.04 } },
	{ Id = "extension_savant", Name = "Extension Savant", Category = "TechniqueEvolution", Rarity = "Rare", Weight = 0,
		Description = "you can convert mastery into named extension applications under pressure.",
		Modifiers = { MasteryGainMult = 1.08, MissionSuccessBonus = 2, CombatGainMult = 1.05 } },
	{ Id = "maximum_pressure", Name = "Maximum Pressure", Category = "TechniqueEvolution", Rarity = "Rare", Weight = 0,
		Description = "your technique can reach maximum output in decisive clashes.",
		Modifiers = { CombatGainMult = 1.08, MissionSuccessBonus = 3, RiskMult = 1.04 } },
	{ Id = "domain_seed", Name = "Domain Seed", Category = "TechniqueEvolution", Rarity = "Legendary", Weight = 0,
		Description = "the outline of a future domain exists in your cursed technique.",
		Modifiers = { MasteryGainMult = 1.10, CombatGainMult = 1.10, MissionSuccessBonus = 5, RiskMult = 0.96 } },

	-- Six Eyes: Gojo bloodline trait, not a cursed technique.
	{ Id = "six_eyes", Name = "Six Eyes", Category = "Bloodline", Rarity = "Legendary", Weight = 1,
		Description = "a rare Gojo bloodline trait that reads cursed energy with unnatural precision. Six Eyes is a trait, not a cursed technique.",
		OriginWhitelist = { "Gojo Clan", "Gojo", "Sugawara Lineage" },
		Modifiers = {
			StartingCEBonus = 25,
			CEGainMult = 1.25,
			MasteryGainMult = 1.22,
			SmartsGainMult = 1.12,
			MissionSuccessBonus = 8,
			RiskMult = 0.94
		} },


}


----------------------------------------------------------------
-- LOOKUP TABLES
----------------------------------------------------------------
local function clamp(value, minValue, maxValue)
	value = tonumber(value) or minValue
	if value < minValue then return minValue end
	if value > maxValue then return maxValue end
	return value
end

local function copyArray(list)
	local output = {}
	for _, item in ipairs(list or {}) do
		table.insert(output, item)
	end
	return output
end

local function normalizeTraitId(text)
	text = tostring(text or "")
	text = string.lower(text)
	text = string.gsub(text, "[^%w]+", "_")
	text = string.gsub(text, "^_+", "")
	text = string.gsub(text, "_+$", "")
	return text
end

local function traitAlreadyPickedById(result, traitId)
	traitId = normalizeTraitId(traitId)

	for _, ownedId in ipairs(result or {}) do
		if normalizeTraitId(ownedId) == traitId then
			return true
		end
	end

	return false
end

local function addTraitId(result, traitId)
	traitId = normalizeTraitId(traitId)

	if traitId == "" or traitAlreadyPickedById(result, traitId) then
		return false
	end

	table.insert(result, traitId)
	return true
end

local function isGojoBloodline(stats)
	if not stats then
		return false
	end

	local origin = tostring(stats.Origin or stats.Clan or "")
	local familyName = tostring(stats.FamilyName or "")
	local playerClanName = tostring(stats.PlayerClanName or "")

	return origin == "Gojo Clan"
		or origin == "Gojo"
		or origin == "Sugawara Lineage"
		or origin == "Sugawara"
		or familyName == "Gojo"
		or familyName == "Sugawara"
		or playerClanName == "Gojo"
		or playerClanName == "Sugawara"
end

local function shouldForceSixEyesTrait(stats)
	if not stats then
		return false
	end

	return tostring(stats.CursedTechnique or "None") == "Six Eyes"
		or tostring(stats.InnateTechnique or "None") == "Six Eyes"
		or tostring(stats.PlayerClanInnateTechnique or "None") == "Six Eyes"
		or stats.SixEyesBornTraitPending == true
end

local function normalizeSixEyesTechniqueFields(stats)
	if not stats then
		return false
	end

	local changed = false

	if tostring(stats.CursedTechnique or "None") == "Six Eyes" then
		stats.CursedTechnique = "Limitless"
		stats.TechniqueKnown = true
		stats.TechniqueUsable = true
		stats.TechniqueAwakened = true
		if not stats.TechniqueType or stats.TechniqueType == "None" then
			stats.TechniqueType = "Innate"
		end
		changed = true
	end

	if tostring(stats.InnateTechnique or "None") == "Six Eyes" then
		stats.InnateTechnique = "Limitless"
		stats.TechniqueType = "Innate"
		stats.TechniqueKnown = true
		changed = true
	end

	if tostring(stats.PlayerClanInnateTechnique or "None") == "Six Eyes" then
		stats.PlayerClanInnateTechnique = "Limitless"
		changed = true
	end

	if changed then
		stats.SixEyesBornTraitPending = nil
	end

	return changed
end


BitKaisenTraits.ById       = {}
BitKaisenTraits.ByName     = {}
BitKaisenTraits.ByCategory = {}
BitKaisenTraits.ByRarity   = {}

for _, trait in ipairs(BitKaisenTraits.Definitions) do
	BitKaisenTraits.ById[trait.Id] = trait
	BitKaisenTraits.ByName[string.lower(trait.Name)] = trait

	BitKaisenTraits.ByCategory[trait.Category] = BitKaisenTraits.ByCategory[trait.Category] or {}
	table.insert(BitKaisenTraits.ByCategory[trait.Category], trait)

	BitKaisenTraits.ByRarity[trait.Rarity] = BitKaisenTraits.ByRarity[trait.Rarity] or {}
	table.insert(BitKaisenTraits.ByRarity[trait.Rarity], trait)
end

----------------------------------------------------------------
-- PUBLIC FUNCTIONS — all signatures preserved exactly
----------------------------------------------------------------
function BitKaisenTraits.GetTrait(traitIdOrName)
	if type(traitIdOrName) == "table" then
		traitIdOrName = traitIdOrName.Id or traitIdOrName.Name
	end

	local raw  = tostring(traitIdOrName or "")
	local byId = BitKaisenTraits.ById[normalizeTraitId(raw)]
	if byId then return byId end
	return BitKaisenTraits.ByName[string.lower(raw)]
end

function BitKaisenTraits.HasTrait(stats, traitIdOrName)
	if not stats or not stats.Traits then return false end

	local trait = BitKaisenTraits.GetTrait(traitIdOrName)
	if not trait then return false end

	for _, ownedId in ipairs(stats.Traits) do
		if normalizeTraitId(ownedId) == trait.Id then return true end
	end
	return false
end

function BitKaisenTraits.GetTraitNames(stats)
	local names = {}
	if not stats or not stats.Traits then return names end

	for _, traitId in ipairs(stats.Traits) do
		local trait = BitKaisenTraits.GetTrait(traitId)
		if trait then table.insert(names, trait.Name) end
	end
	return names
end

function BitKaisenTraits.GetTraitDisplay(stats)
	local names = BitKaisenTraits.GetTraitNames(stats)
	if #names <= 0 then return "None" end
	return table.concat(names, ", ")
end

function BitKaisenTraits.GetTraitTooltip(stats)
	local parts = {}
	if not stats or not stats.Traits then return "No traits." end

	for _, traitId in ipairs(stats.Traits) do
		local trait = BitKaisenTraits.GetTrait(traitId)
		if trait then
			table.insert(parts, trait.Name .. " [" .. trait.Rarity .. "]: " .. trait.Description)
		end
	end

	if #parts <= 0 then return "No traits." end
	return table.concat(parts, "\n")
end

function BitKaisenTraits.GetModifier(stats, modifierName, defaultValue)
	local value = defaultValue

	if not stats or not stats.Traits then return value end

	for _, traitId in ipairs(stats.Traits) do
		local trait = BitKaisenTraits.GetTrait(traitId)
		local modifiers = trait and trait.Modifiers
		local modifierValue = modifiers and modifiers[modifierName]

		if modifierValue ~= nil then
			if type(modifierValue) == "number" and type(value) == "number" then
				if string.find(modifierName, "Mult") then
					value *= modifierValue
				else
					value += modifierValue
				end
			else
				value = modifierValue
			end
		end
	end

	if type(value) == "number" then
		value = math.floor((value * 100) + 0.5) / 100
	end

	return value
end

function BitKaisenTraits.ApplyNumberModifier(stats, modifierName, baseValue, minValue, maxValue)
	local result = BitKaisenTraits.GetModifier(stats, modifierName, baseValue)
	if minValue ~= nil and maxValue ~= nil then
		result = clamp(result, minValue, maxValue)
	end
	return result
end

local function weightedPick(pool)
	local total = 0
	for _, trait in ipairs(pool) do
		total += tonumber(trait.Weight) or 1
	end

	if total <= 0 then return pool[math.random(1, #pool)] end

	local roll    = math.random() * total
	local current = 0

	for _, trait in ipairs(pool) do
		current += tonumber(trait.Weight) or 1
		if roll <= current then return trait end
	end

	return pool[#pool]
end

local function traitAlreadyPicked(result, trait)
	for _, traitId in ipairs(result) do
		if traitId == trait.Id then return true end
	end
	return false
end

local RARITY_RANK = { Common = 1, Uncommon = 2, Rare = 3, Legendary = 4 }

local function buildEligiblePool(stats, options)
	options = options or {}
	local pool = {}
	local minRarityRank = options.MinRarity and RARITY_RANK[options.MinRarity] or 0

	for _, trait in ipairs(BitKaisenTraits.Definitions) do
		local allowed = true
		if options.Category and trait.Category ~= options.Category then allowed = false end
		if options.Rarity   and trait.Rarity   ~= options.Rarity   then allowed = false end
		if minRarityRank > 0 and (RARITY_RANK[trait.Rarity] or 1) < minRarityRank then allowed = false end

		if allowed and typeof(trait.OriginWhitelist) == "table" then
			allowed = false

			local origin = tostring(stats and (stats.Origin or stats.Clan or "") or "")
			local familyName = tostring(stats and (stats.FamilyName or "") or "")
			local playerClanName = tostring(stats and (stats.PlayerClanName or "") or "")

			for _, allowedOrigin in ipairs(trait.OriginWhitelist) do
				allowedOrigin = tostring(allowedOrigin)
				if origin == allowedOrigin or familyName == allowedOrigin or playerClanName == allowedOrigin then
					allowed = true
					break
				end
			end
		end

		if allowed then table.insert(pool, trait) end
	end

	return pool
end

function BitKaisenTraits.RollTraitCount(stats)
	local count = 1
	local luck  = tonumber(stats and stats.Luck) or 0

	if math.random(1, 100) <= (28 + math.floor(luck * 0.2)) then count += 1 end
	if math.random(1, 100) <= (7  + math.floor(luck * 0.08)) then count += 1 end
	if math.random(1, 1000) <= 20 then count += 1 end

	return clamp(count, 1, 4)
end

function BitKaisenTraits.RollTraits(stats, count, options)
	count = tonumber(count) or BitKaisenTraits.RollTraitCount(stats)
	count = clamp(count, 1, 4)

	local result = {}
	local pool   = buildEligiblePool(stats, options)

	if #pool <= 0 then return result end

	local safety = 0
	while #result < count and safety < 100 do
		safety += 1
		local trait = weightedPick(pool)
		if trait and not traitAlreadyPicked(result, trait) then
			table.insert(result, trait.Id)
		end
	end

	return result
end

function BitKaisenTraits.RollBirthTraits(stats, luckyBirth)
	local traitOptions = nil
	if luckyBirth then
		traitOptions = { MinRarity = "Rare" }
	end
	local traits = BitKaisenTraits.RollTraits(stats, nil, traitOptions)

	local origin = tostring(stats and (stats.Origin or stats.Clan) or "")
	-- Death Painting is handled as lineage/origin now, not as a visible trait.

	if stats and stats.HeavenlyRestricted == true and math.random(1, 100) <= 35 then
		local heavenly = BitKaisenTraits.GetTrait("Heavenly Tempered")
		if heavenly and not traitAlreadyPicked(traits, heavenly) then
			table.insert(traits, heavenly.Id)
		end
	end

	local sixEyes = BitKaisenTraits.GetTrait("Six Eyes")
	if sixEyes then
		local shouldAddSixEyes = false

		if shouldForceSixEyesTrait(stats) then
			shouldAddSixEyes = true
		elseif isGojoBloodline(stats) then
			local chance = 8

			if tostring(stats and (stats.InnateTechnique or stats.CursedTechnique) or "") == "Limitless" then
				chance = 12
			end

			shouldAddSixEyes = math.random(1, 100) <= chance
		end

		if shouldAddSixEyes and not traitAlreadyPicked(traits, sixEyes) then
			while #traits >= 4 do
				table.remove(traits, #traits)
			end
			table.insert(traits, sixEyes.Id)
		end
	end

	while #traits > 4 do table.remove(traits, #traits) end

	return traits
end

function BitKaisenTraits.EnsureTraits(stats)
	if not stats then return end

	if type(stats.Traits) ~= "table" then
		stats.Traits = {}
	end

	local clean = {}
	local seen  = {}

	for _, traitId in ipairs(stats.Traits) do
		local trait = BitKaisenTraits.GetTrait(traitId)
		local isDeathPaintingTrait = trait and (trait.Id == "death_painting_blood" or trait.Name == "Death Painting Blood")
		if isDeathPaintingTrait then
			stats.Lineage = "Death Painting"
			stats.DeathPaintingLineage = true
			stats.CurseType = "Death Painting"
		elseif trait and not seen[trait.Id] then
			seen[trait.Id] = true
			table.insert(clean, trait.Id)
		end
	end

	if shouldForceSixEyesTrait(stats) then
		local sixEyes = BitKaisenTraits.GetTrait("Six Eyes")
		if sixEyes and not seen[sixEyes.Id] then
			seen[sixEyes.Id] = true
			table.insert(clean, sixEyes.Id)
		end
	end

	normalizeSixEyesTechniqueFields(stats)

	stats.Traits       = clean
	stats.TraitSummary = BitKaisenTraits.GetTraitDisplay(stats)
end


function BitKaisenTraits.NormalizeSixEyesTrait(stats)
	BitKaisenTraits.EnsureTraits(stats)
	return stats
end

function BitKaisenTraits.ApplyStartingBonuses(stats)
	if not stats then return end

	BitKaisenTraits.EnsureTraits(stats)

	local ceBonus     = BitKaisenTraits.GetModifier(stats, "StartingCEBonus",     0)
	local healthBonus = BitKaisenTraits.GetModifier(stats, "StartingHealthBonus", 0)
	local moneyBonus  = BitKaisenTraits.GetModifier(stats, "StartingMoneyBonus",  0)
	local gradeFloor  = BitKaisenTraits.GetModifier(stats, "GradeFloor",          nil)

	stats.CursedEnergy = math.max(0, (tonumber(stats.CursedEnergy) or 0) + ceBonus)
	stats.Health       = clamp((tonumber(stats.Health) or 100) + healthBonus, 0, 100)
	stats.Money        = math.max(0, (tonumber(stats.Money) or 0) + moneyBonus)

	if gradeFloor and tostring(gradeFloor) ~= "" then
		local order = {
			["Non-Sorcerer"]   = 0,
			["Grade 4"]        = 1,
			["Semi-Grade 3"]   = 2,
			["Grade 3"]        = 3,
			["Semi-Grade 2"]   = 4,
			["Grade 2"]        = 5,
			["Semi-Grade 1"]   = 6,
			["Grade 1"]        = 7,
			["Special Grade 1"]= 8,
			["Special Grade"]  = 9,
		}

		local currentGrade = tostring(stats.Grade or "Non-Sorcerer")
		if (order[currentGrade] or 0) < (order[gradeFloor] or 0) then
			stats.Grade = gradeFloor
		end
	end

	stats.TraitSummary = BitKaisenTraits.GetTraitDisplay(stats)
end

function BitKaisenTraits.BuildBirthMessage(stats)
	if not stats or not stats.Traits or #stats.Traits <= 0 then
		return "Traits: <b>None</b>"
	end
	return "Traits: <b>" .. BitKaisenTraits.GetTraitDisplay(stats) .. "</b>"
end

local function getRarityInheritanceChance(trait)
	local rarity = tostring(trait and trait.Rarity or "Common")
	if rarity == "Legendary" then return 6  end
	if rarity == "Rare"      then return 12 end
	if rarity == "Uncommon"  then return 22 end
	return 32
end

local function addInheritedTrait(result, trait)
	if trait and not traitAlreadyPicked(result, trait) then
		table.insert(result, trait.Id)
		return true
	end
	return false
end

function BitKaisenTraits.RollInheritedTraits(parentStats, childStats, coParentStats)
	childStats = childStats or {}

	local result     = BitKaisenTraits.RollTraits(childStats, 1)
	local parentPool = {}

	local function collectFromParent(sourceStats)
		if not sourceStats or type(sourceStats.Traits) ~= "table" then return end
		BitKaisenTraits.EnsureTraits(sourceStats)
		for _, traitId in ipairs(sourceStats.Traits) do
			local trait = BitKaisenTraits.GetTrait(traitId)
			if trait then table.insert(parentPool, trait) end
		end
	end

	collectFromParent(parentStats)
	collectFromParent(coParentStats)

	for _, trait in ipairs(parentPool) do
		local inheritanceBonus = tonumber(trait.Modifiers and trait.Modifiers.InheritanceBonus) or 0
		local chance = math.clamp(getRarityInheritanceChance(trait) + inheritanceBonus, 1, 85)
		if math.random(1, 100) <= chance then
			addInheritedTrait(result, trait)
		end
	end

	if #parentPool > 0 and #result < 2 and math.random(1, 100) <= 45 then
		addInheritedTrait(result, parentPool[math.random(1, #parentPool)])
	end

	local sixEyes = BitKaisenTraits.GetTrait("Six Eyes")
	if sixEyes then
		local shouldAddSixEyes = shouldForceSixEyesTrait(childStats)
		local gojoLineage = isGojoBloodline(childStats) or isGojoBloodline(parentStats) or isGojoBloodline(coParentStats)

		if not shouldAddSixEyes and gojoLineage then
			local chance = 8
			local childTechnique = tostring(childStats.InnateTechnique or childStats.CursedTechnique or "")
			if childTechnique == "Limitless" then
				chance += 5
			end
			if BitKaisenTraits.HasTrait(parentStats, "Six Eyes") or BitKaisenTraits.HasTrait(coParentStats, "Six Eyes") then
				chance += 12
			end
			chance += math.floor(math.clamp(tonumber(childStats.BloodlineStrength) or tonumber(parentStats and parentStats.BloodlineStrength) or 0, 0, 100) * 0.08)
			shouldAddSixEyes = math.random(1, 100) <= math.clamp(chance, 3, 35)
		end

		if shouldAddSixEyes then
			while #result >= 4 and not traitAlreadyPicked(result, sixEyes) do
				table.remove(result, #result)
			end
			addInheritedTrait(result, sixEyes)
		end
	end

	while #result > 4 do table.remove(result, #result) end

	childStats.Traits       = result
	childStats.TraitSummary = BitKaisenTraits.GetTraitDisplay(childStats)
	return result
end

return BitKaisenTraits
