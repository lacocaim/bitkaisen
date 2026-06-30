-- ModuleScript: BitKaisenStats
-- Location: ReplicatedStorage
-- Clan + Innate Technique rework.
-- Rules:
--   * Clan innate techniques are assigned at birth and stay dormant until age 10-11.
--   * Normal techniques awaken later at ages 8 / 10 / 13.
--   * Player-made clans can turn a parent's normal technique into a bloodline innate for descendants.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BitKaisenTraits = require(ReplicatedStorage:WaitForChild("BitKaisenTraits"))

local BitKaisenStats = {}

BitKaisenStats.FirstNames = {
	"Ren", "Akio", "Daiki", "Haruto", "Kaito", "Riku", "Sora", "Toma", "Yuto", "Itsuki",
	"Shin", "Rei", "Aren", "Kazue", "Niko", "Tatsu", "Hiro", "Masaru", "Ryo", "Kenshi",
	"Kei", "Naru", "Taiga", "Yori", "Kuro", "Seiji", "Atsu", "Mako", "Shiro", "Jin",
	"Kazuki", "Toren", "Yami", "Rento", "Naoki", "Hayate", "Kiyoshi", "Isamu", "Raisen", "Koga",
	"Mizuki", "Airi", "Hana", "Yuna", "Kira", "Emi", "Saki", "Nari", "Rina", "Aya",
	"Mei", "Yoriha", "Kana", "Noa", "Aiko", "Reina", "Mira", "Yuki", "Amane", "Koharu",
	"Akira", "Hikari", "Natsuki", "Tsubaki", "Rumi", "Kaede", "Saya", "Hinari", "Mina", "Yua",
	"Shiori", "Miyu", "Asahi", "Rikka", "Nanami", "Ena", "Kanna", "Suzune", "Tomoe", "Kasumi",
	"Raito", "Senyu", "Mitsu", "Kiyora", "Azuma", "Ori", "Ranmaru", "Touya", "Reizo", "Amano",
	"Shura", "Kairi", "Ryusei", "Makoto", "Arata", "Yuzuru", "Senka", "Hozuki", "Miori", "Raika"
}

BitKaisenStats.MaleFirstNames = {
	"Ren", "Akio", "Daiki", "Haruto", "Kaito", "Riku", "Sora", "Toma", "Yuto", "Itsuki",
	"Shin", "Rei", "Aren", "Niko", "Tatsu", "Hiro", "Masaru", "Ryo", "Kenshi", "Kei",
	"Naru", "Taiga", "Yori", "Kuro", "Seiji", "Jin", "Kazuki", "Toren", "Rento", "Naoki",
	"Hayate", "Kiyoshi", "Isamu", "Raisen", "Koga", "Raito", "Senyu", "Mitsu", "Azuma", "Ranmaru",
	"Touya", "Reizo", "Kairi", "Ryusei", "Makoto", "Arata", "Yuzuru"
}

BitKaisenStats.FemaleFirstNames = {
	"Mizuki", "Airi", "Hana", "Yuna", "Kira", "Emi", "Saki", "Nari", "Rina", "Aya",
	"Mei", "Yoriha", "Kana", "Noa", "Aiko", "Reina", "Mira", "Yuki", "Amane", "Koharu",
	"Akira", "Hikari", "Natsuki", "Tsubaki", "Rumi", "Kaede", "Saya", "Hinari", "Mina", "Yua",
	"Shiori", "Miyu", "Asahi", "Rikka", "Nanami", "Ena", "Kanna", "Suzune", "Tomoe", "Kasumi",
	"Shura", "Senka", "Hozuki", "Miori", "Raika", "Kiyora", "Ori"
}

BitKaisenStats.FamilyNames = {
	"Kumiwado", "Mizukara", "Amahara", "Tsukigane", "Kurogiri", "Hoshinari", "Yamashiro", "Shinkawa", "Morikage", "Fushidori",
	"Kazehara", "Midorikawa", "Arakane", "Sakuraba", "Onikawa", "Higashino", "Kurosawa", "Tachibara", "Murasaki", "Yorimune",
	"Kaneshima", "Hakamori", "Tengawa", "Shirogane", "Akatsuba", "Yuzanami", "Kisaragi", "Mikazuchi", "Reikado", "Asamura",
	"Tomishiro", "Nagakura", "Hoshikawa", "Kamishiro", "Kurogane", "Ametsuchi", "Sazanami", "Yukimura", "Kanzaki", "Shigure",
	"Rokuhara", "Minazuki", "Aokiri", "Haranome", "Kagetsu", "Onizuka", "Kurobane", "Mizuhashi", "Tsukishiro", "Kiryudo",
	"Yamigawa", "Hoshizora", "Kurotsuki", "Akamori", "Shiranui", "Kazumori", "Todorane", "Miyagiri", "Sengoku", "Fuyutsuki"
}

BitKaisenStats.UnknownFamilies = {
	"Nameless", "Unregistered", "Forgotten", "Hidden", "Obscured", "Ashen", "Hollow", "Lost", "Veiled", "Stray"
}

-- Each technique can be restricted to specific Origins. If Origins is nil
-- or empty, any sorcerer can potentially roll it (the "open pool").

local function pickRandom(list)
	return list[math.random(1, #list)]
end

local function weightedPick(list)
	local total = 0
	for _, item in ipairs(list) do
		total += tonumber(item.Chance or item.Weight or 0) or 0
	end

	if total <= 0 then
		return list[1]
	end

	local roll = math.random() * total
	local current = 0

	for _, item in ipairs(list) do
		current += tonumber(item.Chance or item.Weight or 0) or 0
		if roll <= current then
			return item
		end
	end

	return list[#list]
end

local function cleanName(text)
	text = tostring(text or "")
	text = text:gsub("^%s+", ""):gsub("%s+$", "")
	return text
end

local function stripGradePrefix(grade)
	local gradeText = tostring(grade or "Non-Sorcerer")
	if string.sub(gradeText, 1, 13) == "Unregistered " then
		return string.sub(gradeText, 14)
	end
	if string.sub(gradeText, 1, 11) == "Curse User " then
		return string.sub(gradeText, 12)
	end
	return gradeText
end

BitKaisenStats.GradeOrder = {
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

local function getGradeValue(grade)
	return BitKaisenStats.GradeOrder[stripGradePrefix(grade)] or 0
end

local function ensureMinimumGrade(stats, minimumGrade)
	if not stats then
		return
	end
	local currentGrade = tostring(stats.Grade or "Non-Sorcerer")
	if getGradeValue(currentGrade) >= getGradeValue(minimumGrade) then
		return
	end
	if string.sub(currentGrade, 1, 13) == "Unregistered " then
		stats.Grade = "Unregistered " .. minimumGrade
	else
		stats.Grade = minimumGrade
	end
end

-- Origins are weighted. Higher Chance = easier to be born with.
-- Canon clans are intentionally rarer than custom/minor families.
BitKaisenStats.Origins = {
	{ Id = "civilian_family", DisplayName = "Civilian Family", Category = "Family", FamilyType = "Civilian", Chance = 30, BonusCE = 0, BonusSmarts = 3 },
	{ Id = "minor_sorcerer_family", DisplayName = "Minor Sorcerer Family", Category = "Family", FamilyType = "Sorcerer", Chance = 20, BonusCE = 12, BonusSmarts = 5 },
	{ Id = "fallen_sorcerer_family", DisplayName = "Fallen Sorcerer Family", Category = "Family", FamilyType = "Fallen", Chance = 8, BonusCE = 15, BonusSmarts = 4 },
	{ Id = "unknown_family", DisplayName = "Unknown Family", Category = "Family", FamilyType = "Unknown", Chance = 7, BonusCE = 20, BonusSmarts = 3 },
	{ Id = "branch_family", DisplayName = "Branch Sorcerer Family", Category = "Family", FamilyType = "Sorcerer", Chance = 7, BonusCE = 18, BonusSmarts = 7 },

	-- Custom / game-original clans. These keep BitKaisen from becoming only a canon reroll sim.
	{ Id = "kumiwado_clan", DisplayName = "Kumiwado Clan", Category = "Clan", FamilyType = "Sorcerer", Chance = 2.2, BonusCE = 22, BonusSmarts = 8, FamilyName = "Kumiwado", InnatePool = { {Name="Blood Dominion", Weight=35}, {Name="Soul Ledger", Weight=25}, {Name="Static Crown", Weight=20}, {Name="Starfall Dice", Weight=20} } },
	{ Id = "mizukara_clan", DisplayName = "Mizukara Clan", Category = "Clan", FamilyType = "Sorcerer", Chance = 2.1, BonusCE = 20, BonusSmarts = 8, FamilyName = "Mizukara", InnatePool = { {Name="Mirror Curse", Weight=35}, {Name="Frost Burial", Weight=30}, {Name="Moon Thread", Weight=20}, {Name="Echo Step", Weight=15} } },
	{ Id = "amahara_clan", DisplayName = "Amahara Clan", Category = "Clan", FamilyType = "Sorcerer", Chance = 2.0, BonusCE = 19, BonusSmarts = 9, FamilyName = "Amahara", InnatePool = { {Name="Storm Vessel", Weight=40}, {Name="Paper Shikigami", Weight=25}, {Name="Ink Binding", Weight=20}, {Name="Static Binding", Weight=15} } },
	{ Id = "tsukigane_clan", DisplayName = "Tsukigane Clan", Category = "Clan", FamilyType = "Sorcerer", Chance = 1.7, BonusCE = 21, BonusSmarts = 6, FamilyName = "Tsukigane", InnatePool = { {Name="Iron Bloom", Weight=40}, {Name="Bone Script", Weight=25}, {Name="Construction", Weight=15}, {Name="Glass Coffin", Weight=20} } },
	{ Id = "kurogiri_clan", DisplayName = "Kurogiri Clan", Category = "Clan", FamilyType = "Sorcerer", Chance = 1.5, BonusCE = 20, BonusSmarts = 7, FamilyName = "Kurogiri", InnatePool = { {Name="Shadow Thread", Weight=45}, {Name="Smoke Threading", Weight=25}, {Name="Shadow Stitch", Weight=20}, {Name="Grave Bloom", Weight=10} } },
	{ Id = "hoshinari_clan", DisplayName = "Hoshinari Clan", Category = "Clan", FamilyType = "Sorcerer", Chance = 1.4, BonusCE = 19, BonusSmarts = 9, FamilyName = "Hoshinari", InnatePool = { {Name="Starfall Dice", Weight=40}, {Name="Contractual Re-Creation", Weight=20}, {Name="Comedian", Weight=10}, {Name="Echo Pulse", Weight=30} } },
	{ Id = "yamashiro_clan", DisplayName = "Yamashiro Clan", Category = "Clan", FamilyType = "Sorcerer", Chance = 1.4, BonusCE = 18, BonusSmarts = 10, FamilyName = "Yamashiro", InnatePool = { {Name="Barrier Technique", Weight=40}, {Name="Curtain Specialist", Weight=30}, {Name="Tool Manipulation", Weight=20}, {Name="Simple Domain", Weight=10} } },
	{ Id = "shinkawa_clan", DisplayName = "Shinkawa Clan", Category = "Clan", FamilyType = "Sorcerer", Chance = 1.3, BonusCE = 17, BonusSmarts = 9, FamilyName = "Shinkawa", InnatePool = { {Name="Thread Manipulation", Weight=35}, {Name="Cursed Tool Reinforcement", Weight=25}, {Name="Binding Rope Technique", Weight=20}, {Name="Mirror Step", Weight=20} } },
	{ Id = "morikage_clan", DisplayName = "Morikage Clan", Category = "Clan", FamilyType = "Sorcerer", Chance = 1.2, BonusCE = 20, BonusSmarts = 6, FamilyName = "Morikage", InnatePool = { {Name="Grave Bloom", Weight=35}, {Name="Ash Binding", Weight=25}, {Name="Rot Technique", Weight=20}, {Name="Crow Funeral", Weight=20} } },
	{ Id = "fushidori_clan", DisplayName = "Fushidori Clan", Category = "Clan", FamilyType = "Sorcerer", Chance = 1.1, BonusCE = 18, BonusSmarts = 8, FamilyName = "Fushidori", InnatePool = { {Name="Black Bird Manipulation", Weight=35}, {Name="Crow Funeral", Weight=30}, {Name="Paper Shikigami", Weight=20}, {Name="Shikigami Technique", Weight=15} } },

	-- Canon major clans / lineages.
	{ Id = "inumaki_clan", DisplayName = "Inumaki Clan", Category = "Clan", FamilyType = "Sorcerer", Chance = 5, BonusCE = 18, BonusSmarts = 8, FamilyName = "Inumaki", InnatePool = { {Name="Cursed Speech", Weight=100} } },
	{ Id = "kamo_clan", DisplayName = "Kamo Clan", Category = "Clan", FamilyType = "Sorcerer", Chance = 4, BonusCE = 22, BonusSmarts = 10, FamilyName = "Kamo", InnatePool = { {Name="Blood Manipulation", Weight=100} } },
	{ Id = "zenin_clan", DisplayName = "Zenin Clan", Category = "Clan", FamilyType = "Sorcerer", Chance = 3, BonusCE = 24, BonusSmarts = 5, FamilyName = "Zenin", InnatePool = { {Name="Ten Shadows", Weight=18}, {Name="Projection Sorcery", Weight=32}, {Name="Construction", Weight=18}, {Name="Tool Manipulation", Weight=20}, {Name="Heavenly Restriction", Weight=12} } },
	{ Id = "fushiguro_lineage", DisplayName = "Fushiguro Lineage", Category = "Lineage", FamilyType = "Sorcerer", Chance = 2.5, BonusCE = 22, BonusSmarts = 5, FamilyName = "Fushiguro", InnatePool = { {Name="Ten Shadows", Weight=55}, {Name="Shikigami Technique", Weight=30}, {Name="Tool Manipulation", Weight=15} } },
	{ Id = "okkotsu_lineage", DisplayName = "Okkotsu Lineage", Category = "Lineage", FamilyType = "Sorcerer", Chance = 2, BonusCE = 36, BonusSmarts = 7, FamilyName = "Okkotsu", InnatePool = { {Name="Copy", Weight=70}, {Name="Rika Manifestation", Weight=30} } },
	{ Id = "itadori_lineage", DisplayName = "Itadori Lineage", Category = "Lineage", FamilyType = "Sorcerer", Chance = 2, BonusCE = 25, BonusSmarts = 3, FamilyName = "Itadori", InnatePool = { {Name="Shrine", Weight=18}, {Name="Divergent Fist", Weight=45}, {Name="Soul Striking", Weight=37} } },
	{ Id = "hakari_lineage", DisplayName = "Hakari Lineage", Category = "Lineage", FamilyType = "Sorcerer", Chance = 2, BonusCE = 24, BonusSmarts = 6, FamilyName = "Hakari", InnatePool = { {Name="Private Pure Love Train", Weight=100} } },
	{ Id = "higuruma_lineage", DisplayName = "Higuruma Lineage", Category = "Lineage", FamilyType = "Sorcerer", Chance = 1.5, BonusCE = 20, BonusSmarts = 18, FamilyName = "Higuruma", InnatePool = { {Name="Deadly Sentencing", Weight=100} } },
	{ Id = "fujiwara_lineage", DisplayName = "Fujiwara Lineage", Category = "Lineage", FamilyType = "Sorcerer", Chance = 1.5, BonusCE = 25, BonusSmarts = 14, FamilyName = "Fujiwara", InnatePool = { {Name="Sky Manipulation", Weight=30}, {Name="Contractual Re-Creation", Weight=25}, {Name="Barrier Technique", Weight=25}, {Name="Cursed Energy Discharge", Weight=20} } },
	{ Id = "sugawara_lineage", DisplayName = "Sugawara Lineage", Category = "Lineage", FamilyType = "Sorcerer", Chance = 1, BonusCE = 30, BonusSmarts = 16, FamilyName = "Sugawara", InnatePool = { {Name="Copy", Weight=30}, {Name="Limitless", Weight=12}, {Name="Rika Manifestation", Weight=18}, {Name="Cursed Energy Discharge", Weight=40} } },
	{ Id = "gojo_clan", DisplayName = "Gojo Clan", Category = "Clan", FamilyType = "Sorcerer", Chance = 0.7, BonusCE = 35, BonusSmarts = 15, FamilyName = "Gojo", InnatePool = { {Name="Limitless", Weight=100} } },
	{ Id = "pumpkin_king_clan", DisplayName = "Pumpkin King Clan", Category = "Clan", FamilyType = "Sorcerer", Chance = 0, BonusCE = 32, BonusSmarts = 8, FamilyName = "Pumpkin", InnatePool = { {Name="Pumpkin Control", Weight=100} } },

	-- Other canon/semi-canon family routes for flavor.
	{ Id = "kashimo_lineage", DisplayName = "Kashimo Lineage", Category = "Lineage", FamilyType = "Sorcerer", Chance = 1, BonusCE = 28, BonusSmarts = 5, FamilyName = "Kashimo", InnatePool = { {Name="Mythical Beast Amber", Weight=100} } },
	{ Id = "uraume_lineage", DisplayName = "Uraume Lineage", Category = "Lineage", FamilyType = "Sorcerer", Chance = 1, BonusCE = 24, BonusSmarts = 8, FamilyName = "Uraume", InnatePool = { {Name="Ice Formation", Weight=100} } },
	{ Id = "geto_lineage", DisplayName = "Geto Lineage", Category = "Lineage", FamilyType = "Sorcerer", Chance = 1, BonusCE = 26, BonusSmarts = 12, FamilyName = "Geto", InnatePool = { {Name="Cursed Spirit Manipulation", Weight=100} } },
	{ Id = "kenjaku_clan", DisplayName = "Kenjaku Clan", Category = "Clan", FamilyType = "Sorcerer", Chance = 0.4, BonusCE = 34, BonusSmarts = 22, FamilyName = "Kenjaku", InnatePool = { {Name="Brain Transplant", Weight=100} } },
	{ Id = "todo_lineage", DisplayName = "Todo Lineage", Category = "Lineage", FamilyType = "Sorcerer", Chance = 1.2, BonusCE = 21, BonusSmarts = 8, FamilyName = "Todo", InnatePool = { {Name="Boogie Woogie", Weight=100} } },
	{ Id = "mei_mei_lineage", DisplayName = "Mei Mei Lineage", Category = "Lineage", FamilyType = "Sorcerer", Chance = 1.2, BonusCE = 18, BonusSmarts = 12, FamilyName = "Mei", InnatePool = { {Name="Black Bird Manipulation", Weight=100} } },
	{ Id = "nanami_lineage", DisplayName = "Nanami Lineage", Category = "Lineage", FamilyType = "Sorcerer", Chance = 1.2, BonusCE = 18, BonusSmarts = 14, FamilyName = "Nanami", InnatePool = { {Name="Ratio Technique", Weight=100} } },
	{ Id = "kusakabe_lineage", DisplayName = "Kusakabe Lineage", Category = "Lineage", FamilyType = "Sorcerer", Chance = 1.2, BonusCE = 16, BonusSmarts = 16, FamilyName = "Kusakabe", InnatePool = { {Name="New Shadow Style", Weight=60}, {Name="Simple Domain", Weight=40} } },
	{ Id = "death_painting_lineage", DisplayName = "Death Painting Lineage", Category = "Lineage", FamilyType = "Race", CurseType = "Death Painting", Chance = 1.4, BonusCE = 45, BonusSmarts = -2, FamilyName = "Death Painting", InnatePool = { {Name="Blood Manipulation", Weight=45}, {Name="Rot Technique", Weight=35}, {Name="Soul Striking", Weight=20} } },
	{ Id = "cursed_womb", DisplayName = "Cursed Womb", Category = "Race", FamilyType = "Race", Chance = 2.8, BonusCE = 42, BonusSmarts = -4, FamilyName = "None", InnatePool = { {Name="Idle Transfiguration", Weight=45}, {Name="Disaster Flames", Weight=30}, {Name="Rot Technique", Weight=25} } },
}

BitKaisenStats.Clans = BitKaisenStats.Origins

BitKaisenStats.Techniques = {
	-- Legendary / special grade leaning
	{ Name = "Limitless", Rarity = "Legendary", ClanInnate = true, Origins = { "Gojo Clan", "Sugawara Lineage" } },
	{ Name = "Ten Shadows", Rarity = "Legendary", ClanInnate = true, Origins = { "Zenin Clan", "Fushiguro Lineage" } },
	{ Name = "Copy", Rarity = "Legendary", ClanInnate = true, Origins = { "Okkotsu Lineage", "Sugawara Lineage" } },
	{ Name = "Rika Manifestation", Rarity = "Legendary", ClanInnate = true, Origins = { "Okkotsu Lineage" } },
	{ Name = "Cursed Spirit Manipulation", Rarity = "Legendary", ClanInnate = true, Origins = { "Geto Lineage" } },
	{ Name = "Brain Transplant", Rarity = "Legendary", ClanInnate = true, Origins = { "Kenjaku Clan" } },
	{ Name = "Idle Transfiguration", Rarity = "Legendary", ClanInnate = true, Origins = { "Cursed Womb" } },
	{ Name = "Mythical Beast Amber", Rarity = "Legendary", ClanInnate = true, Origins = { "Kashimo Lineage" } },
	{ Name = "Shrine", Rarity = "Legendary", ClanInnate = true, Origins = { "Itadori Lineage", "Ryomen Clan" } },
	{ Name = "Pumpkin Control", Rarity = "Legendary", ClanInnate = true, Origins = { "Pumpkin King Clan" } },
	{ Name = "Star Rage", Rarity = "Legendary" },
	{ Name = "Comedian", Rarity = "Legendary", Origins = { "Hoshinari Clan" } },

	-- Rare / clan-grade canon
	{ Name = "Blood Manipulation", Rarity = "Rare", ClanInnate = true, Origins = { "Kamo Clan" } },
	{ Name = "Projection Sorcery", Rarity = "Rare", ClanInnate = true, Origins = { "Zenin Clan" } },
	{ Name = "Construction", Rarity = "Rare", ClanInnate = true, Origins = { "Zenin Clan", "Tsukigane Clan" } },
	{ Name = "Cursed Speech", Rarity = "Rare", ClanInnate = true, Origins = { "Inumaki Clan" } },
	{ Name = "Boogie Woogie", Rarity = "Rare", ClanInnate = true, Origins = { "Todo Lineage" } },
	{ Name = "Ratio Technique", Rarity = "Rare", ClanInnate = true, Origins = { "Nanami Lineage" } },
	{ Name = "Straw Doll", Rarity = "Uncommon" },
	{ Name = "Private Pure Love Train", Rarity = "Rare", ClanInnate = true, Origins = { "Hakari Lineage" } },
	{ Name = "Deadly Sentencing", Rarity = "Rare", ClanInnate = true, Origins = { "Higuruma Lineage" } },
	{ Name = "Ice Formation", Rarity = "Rare", ClanInnate = true, Origins = { "Uraume Lineage" } },
	{ Name = "Black Bird Manipulation", Rarity = "Rare", ClanInnate = true, Origins = { "Mei Mei Lineage", "Fushidori Clan" } },
	{ Name = "Tool Manipulation", Rarity = "Uncommon", ClanInnate = true, Origins = { "Zenin Clan", "Yamashiro Clan", "Fushiguro Lineage" } },
	{ Name = "Seance Technique", Rarity = "Rare" },
	{ Name = "Inverse", Rarity = "Rare" },
	{ Name = "Miracle", Rarity = "Rare" },
	{ Name = "Contractual Re-Creation", Rarity = "Rare", Origins = { "Fujiwara Lineage", "Hoshinari Clan" } },
	{ Name = "Sky Manipulation", Rarity = "Rare", Origins = { "Fujiwara Lineage" } },

	-- Common / normal awakened techniques
	{ Name = "Cloning Technique", Rarity = "Common" },
	{ Name = "Rot Technique", Rarity = "Uncommon", Origins = { "Cursed Womb", "Morikage Clan" } },
	{ Name = "Puppet Manipulation", Rarity = "Uncommon" },
	{ Name = "Barrier Technique", Rarity = "Common", Origins = { "Yamashiro Clan", "Fujiwara Lineage" } },
	{ Name = "Simple Domain", Rarity = "Common", Origins = { "Kusakabe Lineage", "Yamashiro Clan" } },
	{ Name = "New Shadow Style", Rarity = "Uncommon", Origins = { "Kusakabe Lineage" } },
	{ Name = "Shikigami Technique", Rarity = "Common", Origins = { "Fushiguro Lineage", "Fushidori Clan" } },
	{ Name = "Hairpin Technique", Rarity = "Common" },
	{ Name = "Cursed Tool Reinforcement", Rarity = "Common", Origins = { "Shinkawa Clan" } },
	{ Name = "Cursed Energy Discharge", Rarity = "Common", Origins = { "Fujiwara Lineage", "Sugawara Lineage" } },
	{ Name = "Explosive CE Output", Rarity = "Common" },
	{ Name = "Binding Rope Technique", Rarity = "Common", Origins = { "Shinkawa Clan" } },
	{ Name = "Curtain Specialist", Rarity = "Common", Origins = { "Yamashiro Clan" } },
	{ Name = "Divergent Fist", Rarity = "Uncommon", Origins = { "Itadori Lineage" } },
	{ Name = "Soul Striking", Rarity = "Rare", Origins = { "Itadori Lineage" } },
	{ Name = "Heavenly Restriction", Rarity = "Rare", ClanInnate = true, Origins = { "Zenin Clan" } },
	{ Name = "Disaster Flames", Rarity = "Rare", Origins = { "Cursed Womb" } },

	-- Custom / BitKaisen originals
	{ Name = "Blood Dominion", Rarity = "Rare", ClanInnate = true, Origins = { "Kumiwado Clan" } },
	{ Name = "Storm Vessel", Rarity = "Rare", ClanInnate = true, Origins = { "Amahara Clan" } },
	{ Name = "Mirror Curse", Rarity = "Rare", ClanInnate = true, Origins = { "Mizukara Clan" } },
	{ Name = "Paper Shikigami", Rarity = "Uncommon", Origins = { "Amahara Clan", "Fushidori Clan" } },
	{ Name = "Iron Bloom", Rarity = "Rare", ClanInnate = true, Origins = { "Tsukigane Clan" } },
	{ Name = "Shadow Thread", Rarity = "Rare", ClanInnate = true, Origins = { "Kurogiri Clan" } },
	{ Name = "Soul Ledger", Rarity = "Rare", ClanInnate = true, Origins = { "Kumiwado Clan" } },
	{ Name = "Ash Binding", Rarity = "Uncommon", Origins = { "Morikage Clan" } },
	{ Name = "Frost Burial", Rarity = "Rare", ClanInnate = true, Origins = { "Mizukara Clan" } },
	{ Name = "Starfall Dice", Rarity = "Rare", ClanInnate = true, Origins = { "Kumiwado Clan", "Hoshinari Clan" } },
	{ Name = "Static Crown", Rarity = "Rare", ClanInnate = true, Origins = { "Kumiwado Clan" } },
	{ Name = "Bone Script", Rarity = "Uncommon", Origins = { "Tsukigane Clan" } },
	{ Name = "Glass Coffin", Rarity = "Uncommon", Origins = { "Tsukigane Clan" } },
	{ Name = "Smoke Threading", Rarity = "Uncommon", Origins = { "Kurogiri Clan" } },
	{ Name = "Ink Binding", Rarity = "Uncommon", Origins = { "Amahara Clan" } },
	{ Name = "Moon Thread", Rarity = "Uncommon", Origins = { "Mizukara Clan" } },
	{ Name = "Echo Step", Rarity = "Uncommon", Origins = { "Mizukara Clan" } },
	{ Name = "Grave Bloom", Rarity = "Uncommon", Origins = { "Morikage Clan", "Kurogiri Clan" } },
	{ Name = "Thread Manipulation", Rarity = "Common", Origins = { "Shinkawa Clan" } },
	{ Name = "Mirror Step", Rarity = "Uncommon", Origins = { "Mizukara Clan", "Shinkawa Clan" } },
	{ Name = "Static Binding", Rarity = "Common", Origins = { "Amahara Clan" } },
	{ Name = "Glass Veil", Rarity = "Common" },
	{ Name = "Bone Forge", Rarity = "Common" },
	{ Name = "Shadow Stitch", Rarity = "Common", Origins = { "Kurogiri Clan" } },
	{ Name = "Echo Pulse", Rarity = "Common", Origins = { "Hoshinari Clan" } },
	{ Name = "Crow Funeral", Rarity = "Uncommon", Origins = { "Fushidori Clan", "Morikage Clan" } },
	{ Name = "Threaded Verdict", Rarity = "Rare", Origins = { "Higuruma Lineage", "Shinkawa Clan" } },
	{ Name = "Mirror Garden", Rarity = "Rare", Origins = { "Mizukara Clan" } },
	{ Name = "Static Execution", Rarity = "Rare", Origins = { "Amahara Clan", "Kumiwado Clan" } },
	{ Name = "Grave Lantern", Rarity = "Uncommon", Origins = { "Morikage Clan", "Kurogiri Clan" } },
	{ Name = "Ashen Step", Rarity = "Uncommon", Origins = { "Morikage Clan" } },
	{ Name = "Blood Tax", Rarity = "Rare", Origins = { "Kumiwado Clan", "Kamo Clan" } },
	{ Name = "Curtain Maw", Rarity = "Uncommon", Origins = { "Yamashiro Clan" } },
	{ Name = "Cursed Pulse Radar", Rarity = "Common" },
	{ Name = "Vow Chain", Rarity = "Uncommon" },
	{ Name = "Shatter Palm", Rarity = "Common" },

}

local RARITY_WEIGHTS = { Common = 45, Uncommon = 27, Rare = 14, Legendary = 4, Mythic = 1 }

function BitKaisenStats.GetTechniqueData(techniqueName)
	techniqueName = tostring(techniqueName or "None")
	for _, tech in ipairs(BitKaisenStats.Techniques) do
		if tech.Name == techniqueName then
			return tech
		end
	end
	return nil
end

function BitKaisenStats.GenerateRandomIdentity(originData, gender)
	gender = gender == "Female" and "Female" or "Male"

	local firstNamePool = gender == "Female" and BitKaisenStats.FemaleFirstNames or BitKaisenStats.MaleFirstNames
	local firstName = pickRandom(firstNamePool)
	local familyName = "Unknown"
	local familyType = "Unknown"

	if not originData then
		originData = BitKaisenStats.Origins[1]
	end

	if originData.Category == "Clan" or originData.Category == "Lineage" then
		familyName = originData.FamilyName or originData.DisplayName:gsub(" Clan", ""):gsub(" Lineage", "")
		familyType = "Sorcerer"
	elseif originData.Category == "Race" then
		familyName = "None"
		familyType = "Race"
	elseif originData.FamilyType == "Unknown" then
		familyName = pickRandom(BitKaisenStats.UnknownFamilies)
		familyType = "Unknown"
	elseif originData.FamilyType == "Civilian" then
		familyName = pickRandom(BitKaisenStats.FamilyNames)
		familyType = "Civilian"
	else
		familyName = pickRandom(BitKaisenStats.FamilyNames)
		familyType = originData.FamilyType or "Sorcerer"
	end

	local fullName = firstName
	if familyName ~= "None" and familyName ~= "Unknown" then
		fullName = firstName .. " " .. familyName
	end

	return {
		FirstName = firstName,
		FamilyName = familyName,
		FullName = fullName,
		FamilyType = familyType,
		Gender = gender
	}
end

function BitKaisenStats.GetDefaultStats()
	return {
		Name = "Unknown", FirstName = "Unknown", FamilyName = "Unknown", FamilyType = "Unknown", Gender = "Unknown",
		Age = 0,
		CurrentMonth = 1,
		MonthsIntoAge = 0,
		Health = 100, Happiness = 100, Smarts = math.random(20, 80), CursedEnergy = math.random(5, 35),
		Grade = "Non-Sorcerer", Clan = "Minor Sorcerer Family", Origin = "Minor Sorcerer Family", OriginCategory = "Family",
		CursedTechnique = "None",
		InnateTechnique = "None",
		TechniqueType = "None",
		TechniqueKnown = false,
		TechniqueUsable = false,
		TechniqueAwakened = false,
		InnateDormant = false,
		TechniqueMastery = 0,
		HasRCT = false,
		RCTMastery = 0,
		RCTProgress = 0,
		StoredCurses = 0,
		StoredCursePower = 0,
		TamedShikigami = 0,
		TamedShikigamiNames = {},
		PlayerClanInnateTechnique = "None",

		-- Phase 1: Cursed Society foundation fields.
		-- These are intentionally plain values so old saves can load cleanly and future systems can build on them.
		IsCurse = false,
		CurseType = "None",
		CurseGrade = "None",
		CurseThreat = 0,
		CurseThreatClass = "None",
		CurseEvolution = "Dormant",
		CurseEvolutionProgress = 0,
		CurseMutations = {},
		CurseMutationCount = 0,
		CurseLatestMutation = "None",
		CursedResentment = 0,
		CEAddiction = 0,
		CurseRebirthEligible = false,
		CurseRebirthCount = 0,
		PreviousLifeName = nil,
		PreviousLifeCauseOfDeath = nil,
		SorcererAttackCooldown = 0,
		SorcerersKilled = 0,
		ExorcismRisk = 0,
		TimesExorcised = 0,

		SocietyStatus = "Civilian",
		RegisteredSorcerer = false,
		Recommendations = 0,
		RecommendationProgress = 0,
		PromotionDifficulty = 1,
		WantedLevel = 0,
		CursedFingers = 0,
		CursedObjectAnchors = 0,
		CursedObjectAnchorProgress = 0,
		ReincarnationAnchor = "None",
		SukunaVesselsDefeated = 0,
		SocietyRecognition = 0,
		SocietyInfluence = 0,
		SocietyRank = "None",
		CouncilSeats = 0,
		CouncilCampaigns = 0,
		SocietyPolicyWins = 0,
		LastSocietyOutcome = "None",
		HeianEraEncounters = 0,
		EdoEraEncounters = 0,
		ModernEraEncounters = 0,
		EraLoreDiscoveries = 0,
		SpecialGradeThreatsSurvived = 0,
		LastEraLoreOutcome = "None",
		Fame = 0,
		Fear = 0,
		WorldAttention = 0,
		WorldPressure = 0,
		WorldReputationTier = "Unknown",
		PublicSupport = 0,
		HunterPressure = 0,
		CopycatIncidents = 0,
		WorldReputationEvents = 0,
		ReputationCleanups = 0,
		LastWorldReputationEvent = "None",
		LifePath = "Undecided",
		PathReputation = 0,
		RetiredFromSorcery = false,
		RetirementAge = -1,
		RetirementYears = 0,
		CivilianStability = 0,
		RetirementRoute = "None",
		Affiliation = "Unaffiliated",
		AffiliationRank = "None",
		AffiliationReputation = 0,
		AffiliationDuties = 0,
		JujutsuHighPopularity = 0,
		GoodwillWins = 0,
		TournamentRuns = 0,
		TournamentBestStreak = 0,
		TournamentsWon = 0,
		AssistantName = nil,
		AssistantTrust = 0,
		AssistantSkill = 0,
		TechniqueEvolutionStage = "Dormant",
		TechniqueEvolutionProgress = 0,
		TechniqueBranch = "None",
		TechniqueUsageCount = 0,
		TechniqueMissionUses = 0,
		UnlockedExtensions = {},
		SecretAchievements = {},
		UnlockedPremiumClans = {},
		UnlockedPremiumTechniques = {},
		WorldHistory = {},
		NotableSorcerers = {},
		Looks = 50,
		Strength = 0,
		PhysicalConditioningThisAge = 0,
		CursedFingerHuntBlockedThisAge = false,
		UnlockedTitles = {},
		CursedTools = {},
		EquippedCursedToolId = nil,
		ClanWarState = {},
		ClanWarHistory = {},
		ClanWarWins = 0,
		ClanWarLosses = 0,
		ClanWarActions = 0,
		ClanWarCooldown = 0,

		GodModeSettings = { StartBoost = "None", GuaranteedLegacyTraits = false },
		GodModeTraitAddsUsed = 0,
		GodModeTraitRemovesUsed = 0,
		GodModeClanRerollsUsed = 0,
		GodModeStartBoostChoice = "None",
		GodModeStartBoostApplied = false,
		GodModeGuaranteedLegacyTraits = false,
		GodModeLuckBoost = false,
		EventLuckBonus = 0,
		DomainTrainingThisAge = 0,
		MissionAttemptsThisAge = 0,
		MissionAttemptsWindowAge = 0,

		Rivals = {},
		RivalHistory = {},
		RivalEncounters = 0,
		RivalsDefeated = 0,
		RivalLosses = 0,
		RivalEscapes = 0,
		RivalCooldown = 0,
		ReputationPath = "Unknown",
		ReputationPathScore = 0,
		HunterAmbushesSurvived = 0,
		ReputationIntelRevealed = {},

		DojoReputation = 0,
		DojoRank = "No Dojo",
		DojoIncome = 0,
		DojoLegacy = 0,
		DojoLegacyTier = "None",
		DojoSuccessors = 0,
		DojoNamedSuccessors = 0,
		DojoLegacyCeremonies = 0,
		ChildrenInductedIntoDojo = 0,
		DojoProtectionBonus = 0,
		LastDojoLegacyAge = -1,
		StudentMissionCooldown = 0,

		FamilyReputation = 0,
		ClanLeadership = "None",
		ClanPoliticalPower = 0,
		ClanMergeRequestsSent = 0,
		ClanMergeAlliances = 0,
		ClanMergePacts = 0,
		ClanMergeRejections = 0,
		ClanRivalries = 0,
		ClanMergeAccepted = false,
		LastClanMergeOutcome = "None",
		DojoRaidRisk = 0,
		DojoRaidsDefended = 0,
		DojoRaidsFailed = 0,
		DojoRaidDamageTaken = 0,
		DojoRaidStudentsInjured = 0,
		DojoRaidSuppliesLost = 0,
		DojoRecoveryDebt = 0,
		DojoRecoveryProjects = 0,
		LastDojoRaidType = "None",
		LastDojoRaidOutcome = "None",
		RogueStudentIncidents = 0,
		BloodlineStrength = 0,
		DeathPaintingLineage = false,

		HiddenKarma = 0,
		Money = 0, Reputation = 0, TeacherRecommendations = 0, MissionsCompleted = 0, MissionsFailed = 0,
		InJujutsuHigh = false, ActivitiesDoneThisAge = 0, RelationshipActionsThisAge = 0, RecentLifeEvents = {}, RecentQuietTexts = {},
		Settings = { MusicVolume = 1, SFXVolume = 1, FastText = false, HighContrastText = false },

		SchoolStage = "None",
		SchoolPerformance = 50,
		SchoolAttendance = 100,
		ReportCardGrade = "N/A",
		GraduatedSchool = false,
		SchoolClub = "None",

		GraduatedJujutsuHigh = false,
		IsJujutsuMentor = false,
		MentorRank = "None",
		MentorXP = 0,
		MentorIncome = 0,
		StudentsMentored = 0,
		MentorApplicationCooldown = 0,

		Alive = true
	}
end

function BitKaisenStats.IsCurseLife(stats)
	if not stats then
		return false
	end

	local origin = tostring(stats.Origin or stats.Clan or "")
	local originCategory = tostring(stats.OriginCategory or "")
	local familyType = tostring(stats.FamilyType or "")
	local race = tostring(stats.Race or "")
	local curseType = tostring(stats.CurseType or "")

	-- Phase 2B rule:
	-- Cursed Womb origin is not automatically a full cursed-spirit life.
	-- New secret race display is "Cursed Spirit"; old saves with "Curse" still work.
	if stats.IsCurse == true then
		return true
	end

	if race == "Cursed Spirit" or race == "Curse" then
		return true
	end

	if origin == "Vengeful Spirit Rebirth" or origin == "Cursed Spirit Rebirth" or origin == "Cursed Rebirth" or origin == "Curse" or origin == "Cursed Spirit" then
		return true
	end

	if originCategory == "Race" and (origin == "Cursed Spirit" or origin == "Curse" or familyType == "Cursed Spirit" or familyType == "Curse") then
		return true
	end

	return curseType == "Vengeful Cursed Spirit"
		or curseType == "Fear-Born Cursed Spirit"
		or curseType == "Death-Bound Cursed Spirit"
		or curseType == "Cursed Womb"
		or curseType == "Cursed Spirit"
		or curseType == "Disaster-Class Cursed Spirit"
		-- legacy labels
		or curseType == "Vengeful Curse"
		or curseType == "Fearborn Curse"
		or curseType == "Deathbound Curse"
		or curseType == "Grudge Womb"
		or curseType == "Natural Curse"
		or curseType == "Disaster Curse"
end

function BitKaisenStats.NormalizeCursedSocietyStats(stats)
	if typeof(stats) ~= "table" then
		return stats
	end

	local isCurse = BitKaisenStats.IsCurseLife(stats)

	stats.IsCurse = isCurse
	stats.CurseType = tostring(stats.CurseType or (isCurse and "Cursed Spirit" or "None"))
	if isCurse and stats.CurseType == "None" then
		stats.CurseType = "Cursed Spirit"
	end

	stats.CurseGrade = tostring(stats.CurseGrade or (isCurse and "Unregistered Grade 3 Cursed Spirit" or "None"))
	stats.CurseClassified = stats.CurseClassified == true
	if isCurse and stats.CurseGrade == "None" then
		stats.CurseGrade = "Unregistered Grade 3 Cursed Spirit"
	end

	stats.CurseThreat = math.max(0, tonumber(stats.CurseThreat) or 0)
	stats.CurseThreatClass = tostring(stats.CurseThreatClass or (isCurse and "Local" or "None"))
	if isCurse and stats.CurseThreatClass == "None" then stats.CurseThreatClass = "Local" end
	if tostring(stats.CurseGrade or "") == "Disaster-Class Cursed Spirit" or tostring(stats.CurseGrade or "") == "Unregistered Disaster-Class Cursed Spirit" then
		stats.CurseGrade = stats.CurseClassified and "Special Grade Cursed Spirit" or "Unregistered Special Grade Cursed Spirit"
		stats.CurseThreatClass = "Disaster"
	end
	if isCurse and stats.CurseClassified ~= true and string.sub(tostring(stats.CurseGrade or ""), 1, 13) ~= "Unregistered " then
		stats.CurseGrade = "Unregistered " .. tostring(stats.CurseGrade or "Grade 3 Cursed Spirit")
	end
	if isCurse and stats.CurseClassified == true and string.sub(tostring(stats.CurseGrade or ""), 1, 13) == "Unregistered " then
		stats.CurseGrade = string.sub(tostring(stats.CurseGrade), 14)
	end
	stats.CurseEvolution = tostring(stats.CurseEvolution or (isCurse and "Dormant" or "None"))
	if isCurse and stats.CurseEvolution == "None" then
		stats.CurseEvolution = "Dormant"
	end
	stats.CurseEvolutionProgress = math.max(0, tonumber(stats.CurseEvolutionProgress) or 0)
	if typeof(stats.CurseMutations) ~= "table" then stats.CurseMutations = {} end
	stats.CurseMutationCount = math.max(0, tonumber(stats.CurseMutationCount) or #stats.CurseMutations)
	stats.CurseLatestMutation = tostring(stats.CurseLatestMutation or "None")
	stats.CurseHunger = math.clamp(tonumber(stats.CurseHunger) or (isCurse and 35 or 0), 0, 100)
	stats.CurseTerritory = tostring(stats.CurseTerritory or (isCurse and "Abandoned School" or "None"))
	stats.CurseRumor = tostring(stats.CurseRumor or (isCurse and "The Mirror Thing" or "None"))
	stats.SocietyAttention = math.clamp(tonumber(stats.SocietyAttention) or tonumber(stats.ExorcismRisk) or 0, 0, 100)
	stats.CurseFearLevel = math.max(0, tonumber(stats.CurseFearLevel) or 0)
	stats.CurseTerritoryControl = math.clamp(tonumber(stats.CurseTerritoryControl) or (isCurse and 10 or 0), 0, 100)
	stats.CurseRumorSpread = math.clamp(tonumber(stats.CurseRumorSpread) or 0, 0, 100)
	stats.CiviliansTerrified = math.max(0, tonumber(stats.CiviliansTerrified) or 0)
	stats.HuntersEscaped = math.max(0, tonumber(stats.HuntersEscaped) or 0)
	stats.CursedResentment = math.max(0, tonumber(stats.CursedResentment) or 0)
	stats.CurseRebirthEligible = stats.CurseRebirthEligible == true
	stats.CurseRebirthCount = math.max(0, tonumber(stats.CurseRebirthCount) or 0)
	stats.PreviousLifeName = stats.PreviousLifeName
	stats.PreviousLifeCauseOfDeath = stats.PreviousLifeCauseOfDeath
	stats.SorcererAttackCooldown = math.max(0, tonumber(stats.SorcererAttackCooldown) or 0)
	stats.SorcerersKilled = math.max(0, tonumber(stats.SorcerersKilled) or 0)
	stats.ExorcismRisk = math.clamp(tonumber(stats.ExorcismRisk) or 0, 0, 100)
	stats.TimesExorcised = math.max(0, tonumber(stats.TimesExorcised) or 0)

	stats.SocietyStatus = tostring(stats.SocietyStatus or "Civilian")
	stats.RegisteredSorcerer = stats.RegisteredSorcerer == true
	stats.Recommendations = math.max(0, tonumber(stats.Recommendations) or tonumber(stats.TeacherRecommendations) or 0)
	stats.RecommendationProgress = math.max(0, tonumber(stats.RecommendationProgress) or 0)
	stats.PromotionDifficulty = math.max(0.25, tonumber(stats.PromotionDifficulty) or 1)
	stats.WantedLevel = math.clamp(tonumber(stats.WantedLevel) or 0, 0, 100)
	stats.CursedFingers = math.clamp(tonumber(stats.CursedFingers) or 0, 0, 20)
	stats.CursedObjectAnchors = math.max(0, tonumber(stats.CursedObjectAnchors) or 0)
	stats.CursedObjectAnchorProgress = math.clamp(tonumber(stats.CursedObjectAnchorProgress) or 0, 0, 100)
	stats.ReincarnationAnchor = tostring(stats.ReincarnationAnchor or "None")
	stats.SocietyRecognition = math.max(0, tonumber(stats.SocietyRecognition) or 0)
	stats.SocietyInfluence = math.clamp(tonumber(stats.SocietyInfluence) or math.floor((stats.SocietyRecognition + (tonumber(stats.Fame) or 0) + (tonumber(stats.AffiliationReputation) or 0)) / 3), 0, 100)
	stats.SocietyRank = tostring(stats.SocietyRank or "None")
	stats.CouncilSeats = math.max(0, tonumber(stats.CouncilSeats) or 0)
	stats.CouncilCampaigns = math.max(0, tonumber(stats.CouncilCampaigns) or 0)
	stats.SocietyPolicyWins = math.max(0, tonumber(stats.SocietyPolicyWins) or 0)
	stats.LastSocietyOutcome = tostring(stats.LastSocietyOutcome or "None")
	stats.HeianEraEncounters = math.max(0, tonumber(stats.HeianEraEncounters) or 0)
	stats.EdoEraEncounters = math.max(0, tonumber(stats.EdoEraEncounters) or 0)
	stats.ModernEraEncounters = math.max(0, tonumber(stats.ModernEraEncounters) or 0)
	stats.EraLoreDiscoveries = math.max(0, tonumber(stats.EraLoreDiscoveries) or 0)
	stats.SpecialGradeThreatsSurvived = math.max(0, tonumber(stats.SpecialGradeThreatsSurvived) or 0)
	stats.LastEraLoreOutcome = tostring(stats.LastEraLoreOutcome or "None")
	stats.Fame = math.clamp(tonumber(stats.Fame) or math.floor((tonumber(stats.Reputation) or 0) * 0.25), 0, 100)
	stats.Fear = math.clamp(tonumber(stats.Fear) or math.floor((tonumber(stats.WantedLevel) or 0) * 0.5), 0, 100)
	stats.WorldAttention = math.clamp(tonumber(stats.WorldAttention) or math.floor(((tonumber(stats.Fame) or 0) + (tonumber(stats.Fear) or 0)) / 2), 0, 100)
	stats.WorldPressure = math.clamp(tonumber(stats.WorldPressure) or math.floor(((tonumber(stats.Fear) or 0) * 0.65) + ((tonumber(stats.WantedLevel) or 0) * 2)), 0, 100)
	stats.WorldReputationTier = tostring(stats.WorldReputationTier or "Unknown")
	stats.PublicSupport = math.clamp(tonumber(stats.PublicSupport) or 0, 0, 100)
	stats.HunterPressure = math.clamp(tonumber(stats.HunterPressure) or 0, 0, 100)
	stats.CopycatIncidents = math.max(0, tonumber(stats.CopycatIncidents) or 0)
	stats.WorldReputationEvents = math.max(0, tonumber(stats.WorldReputationEvents) or 0)
	stats.ReputationCleanups = math.max(0, tonumber(stats.ReputationCleanups) or 0)
	stats.LastWorldReputationEvent = tostring(stats.LastWorldReputationEvent or "None")
	stats.LifePath = tostring(stats.LifePath or "Undecided")
	stats.PathReputation = math.clamp(tonumber(stats.PathReputation) or 0, 0, 100)
	stats.RetiredFromSorcery = stats.RetiredFromSorcery == true
	stats.RetirementAge = tonumber(stats.RetirementAge) or -1
	stats.RetirementYears = math.max(0, tonumber(stats.RetirementYears) or 0)
	stats.CivilianStability = math.clamp(tonumber(stats.CivilianStability) or 0, 0, 100)
	stats.RetirementRoute = tostring(stats.RetirementRoute or "None")
	stats.Affiliation = tostring(stats.Affiliation or (stats.InJujutsuHigh and "Jujutsu High" or "Unaffiliated"))
	stats.AffiliationRank = tostring(stats.AffiliationRank or (stats.InJujutsuHigh and "Student" or "None"))
	stats.AffiliationReputation = math.clamp(tonumber(stats.AffiliationReputation) or 0, 0, 100)
	stats.AffiliationDuties = math.max(0, tonumber(stats.AffiliationDuties) or 0)
	stats.JujutsuHighPopularity = math.clamp(tonumber(stats.JujutsuHighPopularity) or 0, 0, 100)
	stats.GoodwillWins = math.max(0, tonumber(stats.GoodwillWins) or 0)
	stats.TournamentRuns = math.max(0, tonumber(stats.TournamentRuns) or 0)
	stats.TournamentBestStreak = math.clamp(tonumber(stats.TournamentBestStreak) or 0, 0, 3)
	stats.TournamentsWon = math.max(0, tonumber(stats.TournamentsWon) or 0)
	stats.AssistantName = stats.AssistantName
	stats.AssistantTrust = math.clamp(tonumber(stats.AssistantTrust) or 0, 0, 100)
	stats.AssistantSkill = math.clamp(tonumber(stats.AssistantSkill) or 0, 0, 100)
	stats.TechniqueEvolutionStage = tostring(stats.TechniqueEvolutionStage or "Dormant")
	stats.TechniqueEvolutionProgress = math.clamp(tonumber(stats.TechniqueEvolutionProgress) or 0, 0, 100)
	stats.TechniqueBranch = tostring(stats.TechniqueBranch or "None")
	stats.TechniqueUsageCount = math.max(0, tonumber(stats.TechniqueUsageCount) or 0)
	stats.TechniqueMissionUses = math.max(0, tonumber(stats.TechniqueMissionUses) or 0)
	if typeof(stats.UnlockedExtensions) ~= "table" then stats.UnlockedExtensions = {} end
	if typeof(stats.SecretAchievements) ~= "table" then stats.SecretAchievements = {} end
	if typeof(stats.UnlockedPremiumClans) ~= "table" then stats.UnlockedPremiumClans = {} end
	if typeof(stats.UnlockedPremiumTechniques) ~= "table" then stats.UnlockedPremiumTechniques = {} end
	if typeof(stats.WorldHistory) ~= "table" then stats.WorldHistory = {} end
	if typeof(stats.NotableSorcerers) ~= "table" then stats.NotableSorcerers = {} end
	stats.Looks = math.clamp(tonumber(stats.Looks) or 50, 0, 100)
	stats.Strength = math.max(0, tonumber(stats.Strength) or 0)
	stats.PhysicalConditioningThisAge = math.clamp(tonumber(stats.PhysicalConditioningThisAge) or 0, 0, 3)
	stats.CursedFingerHuntBlockedThisAge = stats.CursedFingerHuntBlockedThisAge == true
	if typeof(stats.UnlockedTitles) ~= "table" then stats.UnlockedTitles = {} end
	if typeof(stats.CursedTools) ~= "table" then stats.CursedTools = {} end
	if stats.EquippedCursedToolId and not stats.CursedTools[stats.EquippedCursedToolId] then stats.EquippedCursedToolId = nil end
	if typeof(stats.ClanWarState) ~= "table" then stats.ClanWarState = {} end
	if typeof(stats.ClanWarHistory) ~= "table" then stats.ClanWarHistory = {} end
	stats.ClanWarWins = math.max(0, tonumber(stats.ClanWarWins) or 0)
	stats.ClanWarLosses = math.max(0, tonumber(stats.ClanWarLosses) or 0)
	stats.ClanWarActions = math.max(0, tonumber(stats.ClanWarActions) or 0)
	stats.ClanWarCooldown = math.max(0, tonumber(stats.ClanWarCooldown) or 0)

	if typeof(stats.GodModeSettings) ~= "table" then stats.GodModeSettings = {} end
	stats.GodModeSettings.StartBoost = tostring(stats.GodModeSettings.StartBoost or stats.GodModeStartBoostChoice or "None")
	if stats.GodModeSettings.StartBoost ~= "CE" and stats.GodModeSettings.StartBoost ~= "Stats" and stats.GodModeSettings.StartBoost ~= "Luck" then
		stats.GodModeSettings.StartBoost = "None"
	end
	stats.GodModeSettings.GuaranteedLegacyTraits = stats.GodModeSettings.GuaranteedLegacyTraits == true or stats.GodModeGuaranteedLegacyTraits == true
	stats.GodModeTraitAddsUsed = math.clamp(tonumber(stats.GodModeTraitAddsUsed) or 0, 0, 2)
	stats.GodModeTraitRemovesUsed = math.clamp(tonumber(stats.GodModeTraitRemovesUsed) or 0, 0, 2)
	stats.GodModeClanRerollsUsed = math.clamp(tonumber(stats.GodModeClanRerollsUsed) or 0, 0, 3)
	stats.GodModeStartBoostChoice = stats.GodModeSettings.StartBoost
	stats.GodModeStartBoostApplied = stats.GodModeStartBoostApplied == true
	stats.GodModeGuaranteedLegacyTraits = stats.GodModeSettings.GuaranteedLegacyTraits == true
	stats.GodModeLuckBoost = stats.GodModeStartBoostApplied == true and stats.GodModeStartBoostChoice == "Luck"
	stats.EventLuckBonus = math.clamp(tonumber(stats.EventLuckBonus) or 0, 0, 25)
	stats.DomainTrainingThisAge = math.clamp(tonumber(stats.DomainTrainingThisAge) or 0, 0, 3)
	stats.MissionAttemptsThisAge = math.clamp(tonumber(stats.MissionAttemptsThisAge) or 0, 0, 10)
	stats.MissionAttemptsWindowAge = math.max(0, tonumber(stats.MissionAttemptsWindowAge) or 0)

	if typeof(stats.Rivals) ~= "table" then stats.Rivals = {} end
	if typeof(stats.RivalHistory) ~= "table" then stats.RivalHistory = {} end
	if typeof(stats.ReputationIntelRevealed) ~= "table" then stats.ReputationIntelRevealed = {} end
	stats.RivalEncounters = math.max(0, tonumber(stats.RivalEncounters) or 0)
	stats.RivalsDefeated = math.max(0, tonumber(stats.RivalsDefeated) or 0)
	stats.RivalLosses = math.max(0, tonumber(stats.RivalLosses) or 0)
	stats.RivalEscapes = math.max(0, tonumber(stats.RivalEscapes) or 0)
	stats.RivalCooldown = math.max(0, tonumber(stats.RivalCooldown) or 0)
	stats.ReputationPath = tostring(stats.ReputationPath or "Unknown")
	stats.ReputationPathScore = math.clamp(tonumber(stats.ReputationPathScore) or 0, 0, 100)
	stats.HunterAmbushesSurvived = math.max(0, tonumber(stats.HunterAmbushesSurvived) or 0)

	stats.DojoReputation = math.max(0, tonumber(stats.DojoReputation) or tonumber(stats.ClanReputation) or 0)
	stats.DojoRank = tostring(stats.DojoRank or "No Dojo")
	stats.DojoIncome = math.max(0, tonumber(stats.DojoIncome) or 0)
	stats.DojoLegacy = math.clamp(tonumber(stats.DojoLegacy) or math.floor((stats.DojoReputation + (tonumber(stats.ClanReputation) or 0)) / 3), 0, 100)
	stats.DojoLegacyTier = tostring(stats.DojoLegacyTier or "None")
	stats.DojoSuccessors = math.max(0, tonumber(stats.DojoSuccessors) or 0)
	stats.DojoNamedSuccessors = math.max(0, tonumber(stats.DojoNamedSuccessors) or 0)
	stats.DojoLegacyCeremonies = math.max(0, tonumber(stats.DojoLegacyCeremonies) or 0)
	stats.ChildrenInductedIntoDojo = math.max(0, tonumber(stats.ChildrenInductedIntoDojo) or 0)
	stats.DojoProtectionBonus = math.clamp(tonumber(stats.DojoProtectionBonus) or 0, 0, 35)
	stats.LastDojoLegacyAge = tonumber(stats.LastDojoLegacyAge) or -1
	stats.StudentMissionCooldown = math.max(0, tonumber(stats.StudentMissionCooldown) or 0)

	stats.FamilyReputation = math.max(0, tonumber(stats.FamilyReputation) or 0)
	stats.ClanLeadership = tostring(stats.ClanLeadership or "None")
	stats.ClanPoliticalPower = math.clamp(tonumber(stats.ClanPoliticalPower) or math.floor((stats.FamilyReputation + (tonumber(stats.ClanReputation) or 0)) / 3), 0, 100)
	stats.ClanMergeRequestsSent = math.max(0, tonumber(stats.ClanMergeRequestsSent) or 0)
	stats.ClanMergeAlliances = math.max(0, tonumber(stats.ClanMergeAlliances) or 0)
	stats.ClanMergePacts = math.max(0, tonumber(stats.ClanMergePacts) or 0)
	stats.ClanMergeRejections = math.max(0, tonumber(stats.ClanMergeRejections) or 0)
	stats.ClanRivalries = math.max(0, tonumber(stats.ClanRivalries) or 0)
	stats.ClanMergeAccepted = stats.ClanMergeAccepted == true
	stats.LastClanMergeOutcome = tostring(stats.LastClanMergeOutcome or "None")
	stats.DojoRaidRisk = math.clamp(tonumber(stats.DojoRaidRisk) or 0, 0, 100)
	stats.DojoRaidsDefended = math.max(0, tonumber(stats.DojoRaidsDefended) or 0)
	stats.DojoRaidsFailed = math.max(0, tonumber(stats.DojoRaidsFailed) or 0)
	stats.DojoRaidDamageTaken = math.max(0, tonumber(stats.DojoRaidDamageTaken) or 0)
	stats.DojoRaidStudentsInjured = math.max(0, tonumber(stats.DojoRaidStudentsInjured) or 0)
	stats.DojoRaidSuppliesLost = math.max(0, tonumber(stats.DojoRaidSuppliesLost) or 0)
	stats.DojoRecoveryDebt = math.max(0, tonumber(stats.DojoRecoveryDebt) or 0)
	stats.DojoRecoveryProjects = math.max(0, tonumber(stats.DojoRecoveryProjects) or 0)
	stats.LastDojoRaidType = tostring(stats.LastDojoRaidType or "None")
	stats.LastDojoRaidOutcome = tostring(stats.LastDojoRaidOutcome or "None")
	stats.RogueStudentIncidents = math.max(0, tonumber(stats.RogueStudentIncidents) or 0)
	stats.BloodlineStrength = math.clamp(tonumber(stats.BloodlineStrength) or 0, 0, 100)
	stats.DeathPaintingLineage = stats.DeathPaintingLineage == true

	if isCurse then
		stats.SocietyStatus = stats.SocietyStatus ~= "Civilian" and stats.SocietyStatus or "Unregistered Cursed Spirit"
		stats.RegisteredSorcerer = false
	elseif stats.InJujutsuHigh == true then
		stats.SocietyStatus = "Jujutsu Student"
		stats.RegisteredSorcerer = true
	elseif tostring(stats.Grade or "Non-Sorcerer") ~= "Non-Sorcerer" then
		stats.SocietyStatus = stats.RegisteredSorcerer and "Registered Sorcerer" or "Unregistered Sorcerer"
	else
		stats.SocietyStatus = stats.SocietyStatus ~= "Unregistered Cursed Spirit" and stats.SocietyStatus or "Civilian"
	end

	return stats
end

function BitKaisenStats.RollOrigin()
	return weightedPick(BitKaisenStats.Origins)
end

function BitKaisenStats.RollClan()
	return BitKaisenStats.RollOrigin()
end

function BitKaisenStats.RollInnateTechniqueForOrigin(originData)
	if typeof(originData) == "string" then
		for _, origin in ipairs(BitKaisenStats.Origins) do
			if origin.DisplayName == originData or origin.Id == originData then
				originData = origin
				break
			end
		end
	end

	if typeof(originData) ~= "table" or typeof(originData.InnatePool) ~= "table" or #originData.InnatePool <= 0 then
		return nil
	end

	local picked = weightedPick(originData.InnatePool)
	return picked and picked.Name or nil
end


function BitKaisenStats.NormalizeSixEyesTechnique(stats)
	if not stats then
		return stats, false
	end

	local changed = false

	if tostring(stats.CursedTechnique or "None") == "Six Eyes" then
		stats.CursedTechnique = "Limitless"
		stats.TechniqueKnown = true
		stats.TechniqueUsable = true
		stats.TechniqueAwakened = true
		stats.TechniqueType = tostring(stats.TechniqueType or "Innate")
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

	return stats, changed
end

function BitKaisenStats.IsTechniqueUsable(stats)
	return stats and stats.CursedTechnique and stats.CursedTechnique ~= "None" and stats.TechniqueUsable ~= false
end

function BitKaisenStats.ApplyBirthTechnique(stats, originData, luckyBirth)
	if not stats then
		return stats
	end

	stats.CursedTechnique = stats.CursedTechnique or "None"
	stats.InnateTechnique = stats.InnateTechnique or "None"
	stats.TechniqueType = stats.TechniqueType or "None"
	stats.TechniqueKnown = stats.TechniqueKnown == true
	stats.TechniqueUsable = stats.TechniqueUsable == true
	stats.TechniqueAwakened = stats.TechniqueAwakened == true
	stats.InnateDormant = stats.InnateDormant == true

	local innate = BitKaisenStats.RollInnateTechniqueForOrigin(originData or stats.Origin or stats.Clan)
	if not innate and luckyBirth then
		innate = BitKaisenStats.RollInnateTechniqueForOrigin(originData or stats.Origin or stats.Clan)
	end
	if innate == "Six Eyes" then
		innate = "Limitless"
		stats.SixEyesBornTraitPending = true
	end

	if innate and innate ~= "None" then
		stats.InnateTechnique = innate
		stats.CursedTechnique = "None"
		stats.TechniqueType = "Innate"
		stats.TechniqueKnown = true
		stats.TechniqueUsable = false
		stats.TechniqueAwakened = false
		stats.InnateDormant = true
		stats.TechniqueMastery = 0
	end

	return stats
end

function BitKaisenStats.ApplyInheritedTechniqueFromParent(childStats, parentStats)
	if not childStats or not parentStats then
		return false, nil
	end

	local parentTechnique = tostring(parentStats.CursedTechnique or "None")
	local parentTechniqueType = tostring(parentStats.TechniqueType or "Normal")
	local hasFoundedClan = parentStats.ClanFounded == true or tostring(parentStats.PlayerClanName or "") ~= ""

	if parentTechnique == "None" or parentTechniqueType == "Innate" or not hasFoundedClan then
		return false, nil
	end

	if math.random(1, 100) > 55 then
		return false, nil
	end

	childStats.InnateTechnique = parentTechnique
	childStats.CursedTechnique = "None"
	childStats.TechniqueType = "Innate"
	childStats.TechniqueKnown = true
	childStats.TechniqueUsable = false
	childStats.TechniqueAwakened = false
	childStats.InnateDormant = true
	childStats.PlayerClanInnateTechnique = parentTechnique

	if parentStats.PlayerClanName then
		childStats.Clan = parentStats.PlayerClanName
		childStats.Origin = parentStats.PlayerClanName
		childStats.OriginCategory = "Clan"
	end

	return true, parentTechnique
end

function BitKaisenStats.RollTechnique(origin, options)
	options = options or {}
	local includeClanLocked = options.IncludeClanLocked == true
	local valid = {}

	for _, tech in ipairs(BitKaisenStats.Techniques) do
		local allowed = true
		local isClanLocked = tech.ClanInnate == true or (typeof(tech.Origins) == "table" and #tech.Origins > 0)

		if isClanLocked and not includeClanLocked then
			allowed = false
		end

		if allowed and typeof(tech.Origins) == "table" and #tech.Origins > 0 then
			allowed = false
			for _, allowedOrigin in ipairs(tech.Origins) do
				if allowedOrigin == origin then
					allowed = true
					break
				end
			end
		end

		if allowed then
			local weight = RARITY_WEIGHTS[tech.Rarity or "Common"] or 10
			table.insert(valid, { Name = tech.Name, Weight = weight })
		end
	end

	if #valid <= 0 then
		return "Cursed Energy Discharge"
	end

	local picked = weightedPick(valid)
	return picked.Name
end

function BitKaisenStats.AwakenInnateTechnique(stats)
	if not stats then return false, nil end
	local innate = tostring(stats.InnateTechnique or "None")
	if innate == "None" or stats.TechniqueAwakened == true or tostring(stats.CursedTechnique or "None") ~= "None" then
		return false, nil
	end

	stats.CursedTechnique = innate
	stats.TechniqueType = "Innate"
	stats.TechniqueKnown = true
	stats.TechniqueUsable = true
	stats.TechniqueAwakened = true
	stats.InnateDormant = false
	stats.TechniqueMastery = math.max(stats.TechniqueMastery or 0, math.random(2, 8))
	ensureMinimumGrade(stats, "Grade 4")
	if (stats.CursedEnergy or 0) < 35 then
		stats.CursedEnergy = math.random(35, 60)
	end
	return true, innate
end

function BitKaisenStats.AwakenNormalTechnique(stats)
	if not stats then return false, nil end
	if tostring(stats.CursedTechnique or "None") ~= "None" then return false, nil end
	if tostring(stats.InnateTechnique or "None") ~= "None" then return false, nil end

	local origin = stats.Origin or stats.Clan or "Minor Sorcerer Family"
	local technique = BitKaisenStats.RollTechnique(origin, { IncludeClanLocked = false })
	stats.CursedTechnique = technique
	stats.InnateTechnique = "None"
	stats.TechniqueType = "Normal"
	stats.TechniqueKnown = true
	stats.TechniqueUsable = true
	stats.TechniqueAwakened = true
	stats.InnateDormant = false
	stats.TechniqueMastery = math.max(stats.TechniqueMastery or 0, math.random(1, 8))
	ensureMinimumGrade(stats, "Grade 4")
	if (stats.CursedEnergy or 0) < 30 then
		stats.CursedEnergy = math.random(30, 55)
	end
	return true, technique
end

function BitKaisenStats.TryAwaken(stats)
	if not stats then
		return false, nil, nil
	end

	if tostring(stats.CursedTechnique or "None") ~= "None" then
		return false, nil, nil
	end

	local age = tonumber(stats.Age) or 0
	local innate = tostring(stats.InnateTechnique or "None")

	if innate ~= "None" then
		if age == 10 then
			if math.random(1, 100) <= 65 then
				local ok, tech = BitKaisenStats.AwakenInnateTechnique(stats)
				return ok, tech, "Innate"
			end
		elseif age >= 11 then
			local ok, tech = BitKaisenStats.AwakenInnateTechnique(stats)
			return ok, tech, "Innate"
		end
		return false, nil, nil
	end

	local chance = nil
	if age == 8 then
		chance = 18
	elseif age == 10 then
		chance = 38
	elseif age >= 13 then
		chance = 100
	end

	if not chance then
		return false, nil, nil
	end

	if math.random(1, 100) <= chance then
		local ok, tech = BitKaisenStats.AwakenNormalTechnique(stats)
		return ok, tech, "Normal"
	end

	return false, nil, nil
end

function BitKaisenStats.GetTechniqueMissionText(techniqueName, context)
	techniqueName = tostring(techniqueName or "None")
	context = tostring(context or "general")

	local text = {
		["Limitless"] = "You let the curse close the distance, then stop it cold in the impossible space between you.",
		["Ten Shadows"] = "A shikigami tears itself from the dark beneath your feet and forces the curse to split its focus.",
		["Copy"] = "You mirror the shape of another technique just long enough to turn the mission against the curse.",
		["Rika Manifestation"] = "A violent presence answers from behind you, and the curse suddenly realizes it is not fighting one opponent.",
		["Cursed Spirit Manipulation"] = "You command a stored curse into the field and make the enemy fight its own kind.",
		["Idle Transfiguration"] = "Your hand reaches past flesh and threatens the shape of the soul itself.",
		["Mythical Beast Amber"] = "Your cursed energy cracks like lightning, turning your body into a weapon that cannot stay restrained.",
		["Shrine"] = "A clean cut marks the air, and the curse feels the slash before it understands where it came from.",
		["Star Rage"] = "You pour impossible mass into your strike and make the curse fold under the weight of contact.",
		["Comedian"] = "Reality bends around a joke that should not matter, and somehow the curse loses control of the scene.",
		["Blood Manipulation"] = "You turn blood into a precise weapon, trading pain for control over the battlefield.",
		["Projection Sorcery"] = "You divide the next second into frames and move through them before the curse can process you.",
		["Construction"] = "You force cursed energy into matter, building exactly the tool the moment demands.",
		["Cursed Speech"] = "One command leaves your mouth, and the curse obeys before it can resist.",
		["Boogie Woogie"] = "A clap cracks through the air, and the battlefield swaps places before anyone can react.",
		["Ratio Technique"] = "You mark the weak point and strike the exact line where the curse breaks.",
		["Straw Doll"] = "You create a link through cursed residue and make distance stop mattering.",
		["Private Pure Love Train"] = "The rhythm of your technique starts rolling, turning risk into momentum and momentum into pressure.",
		["Deadly Sentencing"] = "A rule settles over the field, and the curse is forced to answer for what it is.",
		["Ice Formation"] = "Cold cursed energy hardens around the target, slowing the curse until the fight belongs to you.",
		["Black Bird Manipulation"] = "A crow dives through the chaos, carrying your cursed energy exactly where it hurts most.",
		["Tool Manipulation"] = "Your weapon shifts with your cursed energy, moving like an extension of your hand.",
		["Seance Technique"] = "You call on a shape that should be gone and borrow its violence for one decisive moment.",
		["Inverse"] = "The curse's strongest hit becomes the wrong answer as your technique twists the meaning of force.",
		["Miracle"] = "Luck bends at the edge of disaster, keeping you alive long enough to make the mission yours.",
		["Contractual Re-Creation"] = "You recreate the terms of the fight, forcing the curse into a rule it never agreed to.",
		["Sky Manipulation"] = "You twist the space above the battlefield and fold the curse's path away from you.",
		["Cloning Technique"] = "Copies of you scatter through the field, making the curse waste every instinct it trusted.",
		["Rot Technique"] = "Your cursed energy sinks into the target and makes its body betray it from within.",
		["Puppet Manipulation"] = "Threads of control snap into place, turning distance and timing into your advantage.",
		["Barrier Technique"] = "You raise a barrier with practiced control, cutting the battlefield into a shape you can survive.",
		["Simple Domain"] = "You anchor yourself inside a simple domain and refuse to let the curse overwhelm your space.",
		["New Shadow Style"] = "Your stance lowers, your blade line settles, and one clean draw controls the exchange.",
		["Shikigami Technique"] = "A shikigami enters the fight at your command, covering the angle you could not reach alone.",
		["Hairpin Technique"] = "Your cursed energy pins the target in place, then detonates the opening you created.",
		["Cursed Tool Reinforcement"] = "You reinforce your weapon until it hums, then drive it straight through the curse's guard.",
		["Cursed Energy Discharge"] = "You release cursed energy in a focused burst, blasting the curse off its rhythm.",
		["Explosive CE Output"] = "Your cursed energy erupts on contact, turning a single hit into a violent shockwave.",
		["Binding Rope Technique"] = "A cursed rope snaps around the target, dragging the curse into a position it cannot escape.",
		["Curtain Specialist"] = "You drop a curtain over the scene and turn panic into controlled silence.",
		["Divergent Fist"] = "Your first impact lands, then the second wave of cursed energy follows a beat later.",
		["Soul Striking"] = "You aim past the body and strike the part of the curse that tries to stay hidden.",
		["Heavenly Restriction"] = "You move without relying on technique at all, crossing the distance with raw physical violence.",
		["Disaster Flames"] = "Cursed fire floods the space and burns away the curse's chance to recover.",
		["Blood Dominion"] = "You command the fight through blood and pressure, making every wound part of your control.",
		["Storm Vessel"] = "Lightning crawls over your cursed energy as you turn speed into punishment.",
		["Mirror Curse"] = "A reflected angle opens beside the curse, and your attack arrives from where it was not looking.",
		["Paper Shikigami"] = "Paper folds into a watcher, then a weapon, slipping through the opening the curse ignored.",
		["Iron Bloom"] = "Metallic cursed energy flowers outward, beautiful for half a second and brutal after that.",
		["Shadow Thread"] = "Threads of shadow stitch the battlefield together and pull the curse into your timing.",
		["Soul Ledger"] = "You count the curse's debt in silence, then collect with a strike that feels inevitable.",
		["Ash Binding"] = "Ash wraps around the target and hardens, turning movement into a mistake.",
		["Frost Burial"] = "Frost crawls over the ground and seals the curse in a quiet, killing cold.",
		["Starfall Dice"] = "The roll lands in your favor, and falling cursed light turns chance into damage.",
		["Static Crown"] = "Static pressure gathers around your head like a crown before snapping into the curse.",
		["Bone Script"] = "Cursed markings crawl across bone-white energy, spelling out the attack before it lands.",
		["Glass Coffin"] = "Glasslike cursed energy closes around the curse, trapping it inside its own panic.",
		["Smoke Threading"] = "Smoke-thin threads slip through the scene and tighten around the curse before it notices.",
		["Ink Binding"] = "Ink-black cursed energy spreads under the target and writes its movement out of the fight.",
		["Moon Thread"] = "A pale thread arcs through the air and cuts the curse's momentum apart.",
		["Echo Step"] = "Your steps repeat a half-beat late, leaving the curse striking afterimages instead of you.",
		["Grave Bloom"] = "Cursed flowers bloom under the target and bury its hatred in one quiet motion.",
		["Thread Manipulation"] = "Threads catch the debris, the curse, and the timing of the room all at once.",
		["Mirror Step"] = "You step through a reflected angle and appear where the curse already failed to guard.",
		["Static Binding"] = "Static cursed energy locks the target's movement in sharp, twitching bursts.",
		["Glass Veil"] = "A thin glassy veil catches the curse's strike and turns the force aside.",
		["Bone Forge"] = "Bone-shaped cursed energy forms into a weapon made for the exact distance between you.",
		["Shadow Stitch"] = "You pin the curse's shadow in place and make its body obey the mistake.",
		["Echo Pulse"] = "A pulsing wave of cursed sound rolls outward and throws the curse off balance.",
		["Crow Funeral"] = "Crows of cursed energy descend in a black rush and tear open the curse's guard.",
	}

	return text[techniqueName] or ("You shape " .. techniqueName .. " into a clean mission response, forcing the curse to deal with your technique instead of your fear.")
end

function BitKaisenStats.GetTechniqueMissionOption(stats, baseOption)
	local technique = tostring(stats and stats.CursedTechnique or "None")
	if technique == "None" then
		return nil
	end

	local clone = {}
	for key, value in pairs(baseOption or {}) do
		clone[key] = value
	end

	clone.Text = "[" .. technique .. "] Use your technique"
	clone.Description = BitKaisenStats.GetTechniqueMissionText(technique, tostring(baseOption and baseOption.Text or "general"))
	clone.RequiresTechnique = nil
	clone.GeneratedTechniqueOption = true
	return clone
end

local TRAIT_RARITY_VALUE = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
}

local function hasTraitRarityAtLeast(stats, minimumRarity)
	local needed = TRAIT_RARITY_VALUE[minimumRarity] or 0
	if needed <= 0 then
		return true
	end

	for _, traitId in ipairs(typeof(stats and stats.Traits) == "table" and stats.Traits or {}) do
		local trait = BitKaisenTraits.GetTrait(traitId)
		if trait and (TRAIT_RARITY_VALUE[trait.Rarity] or 0) >= needed then
			return true
		end
	end

	return false
end

function BitKaisenStats.CheckPromotion(stats)
	if not stats then return nil end
	local currentGrade = stats.Grade or "Non-Sorcerer"
	if currentGrade == "Non-Sorcerer" then return nil end

	local lookupGrade = string.gsub(currentGrade, "^Unregistered ", "")

	local ce = stats.CursedEnergy or 0
	local rep = stats.Reputation or 0
	local rec = stats.TeacherRecommendations or 0
	local missions = stats.MissionsCompleted or 0
	local smarts = stats.Smarts or 0

	local promotionRequirements = {
		["Grade 4"] = { Next = "Grade 3", CE = 450, Rep = 4, Rec = 0, Missions = 0, Smarts = 0 },
		["Semi-Grade 3"] = { Next = "Grade 3", CE = 450, Rep = 8, Rec = 1, Missions = 1, Smarts = 25 },
		["Grade 3"] = { Next = "Semi-Grade 2", CE = 650, Rep = 16, Rec = 1, Missions = 3, Smarts = 35 },
		["Semi-Grade 2"] = { Next = "Grade 2", CE = 800, Rep = 28, Rec = 2, Missions = 5, Smarts = 50 },
		["Grade 2"] = { Next = "Semi-Grade 1", CE = 1000, Rep = 48, Rec = 3, Missions = 8, Smarts = 60 },
		["Semi-Grade 1"] = { Next = "Grade 1", CE = 1200, Rep = 75, Rec = 4, Missions = 12, Smarts = 70, MinTraitRarity = "Uncommon" },
		["Grade 1"] = { Next = "Special Grade", CE = 1000, Rep = 120, Rec = 6, Missions = 18, Smarts = 80, MinTraitRarity = "Rare" },
		["Special Grade 1"] = { Next = "Special Grade", CE = 1000, Rep = 120, Rec = 6, Missions = 18, Smarts = 80, MinTraitRarity = "Rare" },
	}

	local req = promotionRequirements[lookupGrade]
	if not req then return nil end

	if ce >= req.CE
		and rep >= req.Rep
		and rec >= req.Rec
		and missions >= req.Missions
		and smarts >= (req.Smarts or 0)
		and hasTraitRarityAtLeast(stats, req.MinTraitRarity)
	then
		stats.Grade = req.Next
		return req.Next
	end

	return nil
end

return BitKaisenStats

