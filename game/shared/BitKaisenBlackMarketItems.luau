-- ModuleScript: BitKaisenBlackMarketItems
-- Purpose: Illegal, single-use consumable items sold on the Black Market.

local BitKaisenBlackMarketItems = {}

BitKaisenBlackMarketItems.Database = {
	{
		Id = "cursed_finger_vial",
		Name = "Sealed Finger Vial",
		Price = 850,
		Description = "A single cursed finger suspended in warding fluid. Illegal to possess outside Jujutsu Society custody.",
		UseText = "You consumed the sealed finger. Cursed energy surged through you unevenly.",
		UseEffects = { CursedEnergy = 10, Health = -6, Happiness = -2 },
	},
	{
		Id = "black_ash_powder",
		Name = "Black Ash Powder",
		Price = 400,
		Description = "Ash ground from a burned curse corpse. Sorcerers use it to mask their presence, at a cost.",
		UseText = "You inhaled the black ash powder. Your senses sharpened, but your mood soured.",
		UseEffects = { CursedEnergy = 5, Happiness = -4 },
	},
	{
		Id = "contraband_ward_tag",
		Name = "Contraband Ward Tag",
		Price = 1100,
		Description = "A ward tag copied from a stolen Society template. Using an unlicensed ward carries its own risk.",
		UseText = "You activated the contraband ward tag. It worked, but word of the forgery could spread.",
		UseEffects = { CursedEnergy = 6, Reputation = -3 },
	},
	{
		Id = "unlicensed_cursed_serum",
		Name = "Unlicensed Cursed Serum",
		Price = 2200,
		Description = "An experimental serum brewed outside any registered lab. No safety testing, no guarantees.",
		UseText = "You injected the unlicensed serum. Cursed energy flooded your body faster than it could adjust.",
		UseEffects = { CursedEnergy = 22, Health = -14, Happiness = -6 },
	},
	{
		Id = "smuggled_death_painting_shard",
		Name = "Smuggled Death Painting Shard",
		Price = 5000,
		Description = "A fragment smuggled out of a Death Painting incident site. Owning one is a felony under Society law.",
		UseText = "You absorbed the shard's cursed energy. The strain was immediate and your name is now attached to the theft.",
		UseEffects = { CursedEnergy = 35, Health = -20, Happiness = -8, Reputation = -10 },
	},
}

local byId = {}
for _, item in ipairs(BitKaisenBlackMarketItems.Database) do
	byId[item.Id] = item
end
BitKaisenBlackMarketItems.ById = byId

function BitKaisenBlackMarketItems.GetItem(itemId)
	return byId[tostring(itemId or "")]
end

function BitKaisenBlackMarketItems.GetCatalogPayload()
	local payload = {}
	for _, item in ipairs(BitKaisenBlackMarketItems.Database) do
		table.insert(payload, {
			Id = item.Id,
			Name = item.Name,
			Price = item.Price,
			Description = item.Description,
			UseEffects = item.UseEffects,
		})
	end
	return payload
end

return BitKaisenBlackMarketItems
