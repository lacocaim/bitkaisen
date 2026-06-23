-- ModuleScript: BitKaisenAssets
-- Location: ReplicatedStorage
-- Purpose:
-- Asset database, shop, ownership, and passive bonuses.
-- Includes SanitizeOnLoad to repair save data that may be missing newer fields.

local BitKaisenAssets = {}

BitKaisenAssets.Database = {
	{
		Id = "sealed_charm",
		Name = "Sealed Charm",
		Type = "Cursed Object",
		Rarity = "Common",
		Price = 180,
		Description = "A weak cursed charm wrapped in old paper seals.",
		EffectsText = "Can be studied for cursed energy insight.",
		CanUse = true,
		UseText = "You studied the sealed charm and felt faint cursed energy leaking from it.",
		UseEffects = {
			CursedEnergy = 4,
			Smarts = 2,
			Happiness = -1
		},
		PassiveEffects = {}
	},

	{
		Id = "training_room_basic",
		Name = "Basic Training Room",
		Type = "Property",
		Rarity = "Common",
		Price = 250,
		Description = "A small private room used for basic cursed energy training.",
		EffectsText = "Improves cursed energy training.",
		CanUse = false,
		PassiveEffects = {
			CursedEnergyTrainingBonus = 2
		}
	},

	{
		Id = "wedding_ring",
		Name = "Wedding Ring",
		Type = "Relationship Item",
		Rarity = "Rare",
		Price = 5000,
		Description = "A ring used to propose to someone you have built a serious life with.",
		EffectsText = "Required to propose marriage.",
		CanUse = false,
		PassiveEffects = {}
	},

	{
		Id = "rusted_cursed_knife",
		Name = "Rusted Cursed Knife",
		Type = "Cursed Tool",
		Rarity = "Uncommon",
		Price = 500,
		Description = "An old cursed knife with unstable energy clinging to the blade.",
		EffectsText = "Helps during dangerous assignments.",
		CanUse = false,
		PassiveEffects = {
			MissionPowerBonus = 8
		}
	},

	{
		Id = "family_scroll",
		Name = "Inherited Family Scroll",
		Type = "Scroll",
		Rarity = "Uncommon",
		Price = 650,
		Description = "A handwritten scroll containing old notes on cursed energy control.",
		EffectsText = "Can be studied to improve technique understanding.",
		CanUse = true,
		UseText = "You studied the inherited scroll and understood cursed energy a little better.",
		UseEffects = {
			Smarts = 6,
			CursedEnergy = 3
		},
		PassiveEffects = {}
	},

	{
		Id = "low_grade_cursed_core",
		Name = "Low-Grade Cursed Core",
		Type = "Cursed Object",
		Rarity = "Uncommon",
		Price = 900,
		Description = "A small cursed core recovered from a weak curse.",
		EffectsText = "Can be absorbed for risky cursed energy growth.",
		CanUse = true,
		UseText = "You absorbed the cursed core. Your cursed energy surged, but your body rejected part of it.",
		UseEffects = {
			CursedEnergy = 14,
			Health = -8,
			Happiness = -3
		},
		PassiveEffects = {}
	},

	{
		Id = "safehouse_small",
		Name = "Small Safehouse",
		Type = "Property",
		Rarity = "Rare",
		Price = 1500,
		Description = "A hidden room prepared for recovery after curse-related incidents.",
		EffectsText = "Improves recovery and survival.",
		CanUse = false,
		PassiveEffects = {
			HealthRecoveryBonus = 4
		}
	},

	{
		Id = "barrier_manual",
		Name = "Barrier Technique Manual",
		Type = "Scroll",
		Rarity = "Rare",
		Price = 2000,
		Description = "A difficult manual about barrier theory and domain foundations.",
		EffectsText = "Can be studied for advanced growth.",
		CanUse = true,
		UseText = "You studied the barrier manual. Most of it was difficult, but some parts finally clicked.",
		UseEffects = {
			Smarts = 10,
			CursedEnergy = 6
		},
		PassiveEffects = {}
	},

	{
		Id = "black_rope_fragment",
		Name = "Black Rope Fragment",
		Type = "Cursed Tool",
		Rarity = "Rare",
		Price = 3500,
		Description = "A damaged fragment of rope carrying strange interference properties.",
		EffectsText = "Greatly helps against stronger cursed techniques.",
		CanUse = false,
		PassiveEffects = {
			MissionPowerBonus = 20
		}
	},

	{
		Id = "private_dojo",
		Name = "Private Dojo",
		Type = "Property",
		Rarity = "Epic",
		Price = 6000,
		Description = "A serious training space built for sorcerers with growing potential.",
		EffectsText = "Major training bonus.",
		CanUse = false,
		PassiveEffects = {
			CursedEnergyTrainingBonus = 8,
			HealthRecoveryBonus = 2
		}
	},

	{
		Id = "sealed_special_grade_relic",
		Name = "Sealed Special Grade Relic",
		Type = "Cursed Object",
		Rarity = "Legendary",
		Price = 15000,
		Description = "A sealed relic with pressure strong enough to make weaker sorcerers sick.",
		EffectsText = "Extremely risky to study.",
		CanUse = true,
		UseText = "You studied the sealed relic. The cursed energy almost overwhelmed you.",
		UseEffects = {
			CursedEnergy = 45,
			Smarts = 8,
			Health = -25,
			Happiness = -10,
			Reputation = 10,
			CursedObjectAnchorProgress = 18
		},
		PassiveEffects = {}
	},

	{
		Id = "grand_dojo",
		Name = "Grand Dojo",
		Type = "Property",
		Rarity = "Legendary",
		Price = 25000,
		Description = "A private sorcerer dojo large enough to train students, allies, and future clan members.",
		EffectsText = "Unlocks clan founding. Huge training advantage.",
		CanUse = false,
		PassiveEffects = {
			CursedEnergyTrainingBonus = 12,
			MissionPowerBonus = 25,
			HealthRecoveryBonus = 3,
			ReputationBonus = 10
		}
	},
	{
		Id = "weighted_training_gi",
		Name = "Weighted Training Gi",
		Type = "Training Gear",
		Rarity = "Uncommon",
		Price = 1200,
		Description = "A reinforced gi used by sorcerers to build stamina during cursed energy training.",
		EffectsText = "Improves cursed energy training and recovery.",
		CanUse = false,
		PassiveEffects = {
			CursedEnergyTrainingBonus = 4,
			HealthRecoveryBonus = 1
		}
	},

	{
		Id = "punching_bag",
		Name = "Punching Bag",
		Type = "Training Gear",
		Rarity = "Uncommon",
		Price = 1200,
		Description = "A durable training bag for building basic striking power.",
		EffectsText = "Active item: +25 Strength.",
		CanUse = true,
		UseText = "You worked the punching bag until your arms burned. Strength increased.",
		UseEffects = {
			Strength = 25
		},
		PassiveEffects = {}
	},

	{
		Id = "in_home_gym",
		Name = "In-Home Gym",
		Type = "Property",
		Rarity = "Epic",
		Price = 9000,
		Description = "A private gym built for steady physical conditioning.",
		EffectsText = "Passive: +15% Strength gain from physical conditioning.",
		CanUse = false,
		PassiveEffects = {
			StrengthPassiveGainPercent = 15
		}
	},

	{
		Id = "curse_detection_talisman",
		Name = "Curse Detection Talisman",
		Type = "Cursed Object",
		Rarity = "Uncommon",
		Price = 1600,
		Description = "A talisman that twitches when weak cursed energy gathers nearby.",
		EffectsText = "Helps during assignments and patrols.",
		CanUse = false,
		PassiveEffects = {
			MissionPowerBonus = 10
		}
	},

	{
		Id = "old_clan_record",
		Name = "Old Clan Record",
		Type = "Scroll",
		Rarity = "Rare",
		Price = 2800,
		Description = "A damaged record containing family names, failed inheritances, and old curse incidents.",
		EffectsText = "Can be studied for Smarts, CE, and Reputation.",
		CanUse = true,
		UseText = "You studied the old clan record and found patterns in how sorcerer families survive.",
		UseEffects = {
			Smarts = 9,
			CursedEnergy = 5,
			Reputation = 3
		},
		PassiveEffects = {}
	},

	{
		Id = "barrier_anchor_stone",
		Name = "Barrier Anchor Stone",
		Type = "Cursed Object",
		Rarity = "Rare",
		Price = 4200,
		Description = "A small stone used to stabilize basic curtains and defensive barriers.",
		EffectsText = "Improves dangerous assignment performance.",
		CanUse = false,
		PassiveEffects = {
			MissionPowerBonus = 18,
			HealthRecoveryBonus = 2
		}
	},

	{
		Id = "dojo_training_mats",
		Name = "Dojo Training Mats",
		Type = "Dojo Upgrade",
		Rarity = "Rare",
		Price = 7000,
		Description = "Thick mats designed to survive cursed energy sparring.",
		EffectsText = "Improves training and recovery.",
		CanUse = false,
		PassiveEffects = {
			CursedEnergyTrainingBonus = 7,
			HealthRecoveryBonus = 3
		}
	},

	{
		Id = "grade_one_cursed_core",
		Name = "Grade One Cursed Core",
		Type = "Cursed Object",
		Rarity = "Epic",
		Price = 11000,
		Description = "A dense cursed core taken from a dangerous curse.",
		EffectsText = "Can be absorbed for major CE growth at a cost.",
		CanUse = true,
		UseText = "You absorbed the Grade One cursed core. Your cursed energy surged violently through your body.",
		UseEffects = {
			CursedEnergy = 32,
			Health = -16,
			Happiness = -5,
			Reputation = 6,
			CursedObjectAnchorProgress = 12
		},
		PassiveEffects = {}
	},

	{
		Id = "inverted_spear_fragment",
		Name = "Inverted Spear Fragment",
		Type = "Cursed Tool",
		Rarity = "Epic",
		Price = 17500,
		Description = "A broken fragment from a cursed tool with technique-interfering properties.",
		EffectsText = "Greatly improves mission performance.",
		CanUse = false,
		PassiveEffects = {
			MissionPowerBonus = 34
		}
	},

	{
		Id = "special_grade_training_room",
		Name = "Special Grade Training Room",
		Type = "Property",
		Rarity = "Legendary",
		Price = 45000,
		Description = "A reinforced training space made to withstand extreme cursed energy output.",
		EffectsText = "Massive training and mission advantage.",
		CanUse = false,
		PassiveEffects = {
			CursedEnergyTrainingBonus = 18,
			MissionPowerBonus = 20,
			HealthRecoveryBonus = 6,
			ReputationBonus = 8
		}
	}

}

local rarityOrder = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5
}

function BitKaisenAssets.GetAssetById(assetId)
	for _, asset in ipairs(BitKaisenAssets.Database) do
		if asset.Id == assetId then
			return asset
		end
	end

	return nil
end

function BitKaisenAssets.GetShopList(stats)
	local list = {}

	for _, asset in ipairs(BitKaisenAssets.Database) do
		local alreadyOwned = false

		if stats and stats.Assets then
			for _, owned in ipairs(stats.Assets) do
				if owned.Id == asset.Id then
					alreadyOwned = true
					break
				end
			end
		end

		if not alreadyOwned then
			table.insert(list, asset)
		end
	end

	table.sort(list, function(a, b)
		local rarityA = rarityOrder[a.Rarity] or 99
		local rarityB = rarityOrder[b.Rarity] or 99

		if rarityA == rarityB then
			return (a.Price or 0) < (b.Price or 0)
		end

		return rarityA < rarityB
	end)

	return list
end

function BitKaisenAssets.GetOwnedList(stats)
	if not stats then
		return {}
	end

	stats.Assets = stats.Assets or {}

	table.sort(stats.Assets, function(a, b)
		local rarityA = rarityOrder[a.Rarity] or 99
		local rarityB = rarityOrder[b.Rarity] or 99

		if rarityA == rarityB then
			return tostring(a.Name) < tostring(b.Name)
		end

		return rarityA < rarityB
	end)

	return stats.Assets
end

function BitKaisenAssets.GetPassiveBonuses(stats)
	local bonuses = {
		CursedEnergyTrainingBonus = 0,
		MissionPowerBonus = 0,
		HealthRecoveryBonus = 0,
		ReputationBonus = 0
	}

	if not stats or not stats.Assets then
		return bonuses
	end

	for _, asset in ipairs(stats.Assets) do
		local passive = asset.PassiveEffects or {}

		for key, value in pairs(passive) do
			if typeof(value) == "number" then
				bonuses[key] = (bonuses[key] or 0) + value
			end
		end
	end

	return bonuses
end

function BitKaisenAssets.MakeOwnedAsset(asset)
	return {
		Id = asset.Id,
		Name = asset.Name,
		Type = asset.Type,
		Rarity = asset.Rarity,
		Price = asset.Price,
		Description = asset.Description,
		EffectsText = asset.EffectsText,
		CanUse = asset.CanUse,
		UseText = asset.UseText,
		UseEffects = asset.UseEffects or {},
		PassiveEffects = asset.PassiveEffects or {},
		Uses = asset.CanUse and 1 or nil
	}
end

function BitKaisenAssets.SanitizeOnLoad(stats)
	if not stats then
		return
	end

	stats.Assets = stats.Assets or {}

	local validAssets = {}

	for _, ownedAsset in ipairs(stats.Assets) do
		if typeof(ownedAsset) == "table" and ownedAsset.Id then
			local sourceAsset = BitKaisenAssets.GetAssetById(ownedAsset.Id)

			if sourceAsset then
				ownedAsset.Name = ownedAsset.Name or sourceAsset.Name
				ownedAsset.Type = ownedAsset.Type or sourceAsset.Type
				ownedAsset.Rarity = ownedAsset.Rarity or sourceAsset.Rarity
				ownedAsset.Price = ownedAsset.Price or sourceAsset.Price
				ownedAsset.Description = ownedAsset.Description or sourceAsset.Description
				ownedAsset.EffectsText = ownedAsset.EffectsText or sourceAsset.EffectsText

				if ownedAsset.CanUse == nil then
					ownedAsset.CanUse = sourceAsset.CanUse
				end

				ownedAsset.UseText = ownedAsset.UseText or sourceAsset.UseText
				ownedAsset.UseEffects = ownedAsset.UseEffects or sourceAsset.UseEffects or {}
				ownedAsset.PassiveEffects = ownedAsset.PassiveEffects or sourceAsset.PassiveEffects or {}

				if ownedAsset.CanUse and ownedAsset.Uses == nil then
					ownedAsset.Uses = 1
				end

				table.insert(validAssets, ownedAsset)
			end
		end
	end

	stats.Assets = validAssets
end

return BitKaisenAssets
