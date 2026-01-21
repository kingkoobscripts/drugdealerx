Config = {}

Config.PoliceAlertChance = 30 
Config.MinPolice = 1 
Config.PoliceJobName = "police"

-- Admin Controls (Can be changed via command in-game)
Config.GlobalInflation = 1.0 -- 1.0 is 100% price. 1.2 would be 20% bonus.
Config.BulkBonus = 1.15      -- 15% extra money for bulk orders

Config.Drugs = {
    ["weed_baggy"] = {
        label = "Bag of Weed",
        minPrice = 100,
        maxPrice = 250,
        repGain = 1,
        effect = "high_weed",
        rarity = 1.0 -- 100% find rate
    },
    ["meth"] = {
        label = "Meth Crystal",
        minPrice = 400,
        maxPrice = 650,
        repGain = 3,
        effect = "high_meth",
        rarity = 0.4 -- 40% find rate
    },
    ["coke_small"] = {
        label = "Cocaine",
        minPrice = 300,
        maxPrice = 500,
        repGain = 2,
        effect = "high_coke",
        rarity = 0.6 -- 60% find rate
    }
}

Config.PickLocations = {
    { coords = vector3(2208.5, 5578.2, 53.7), label = "Hidden Farm", drug = "weed_baggy", amount = {1, 3}, time = 12000 },
    { coords = vector3(-1154.1, -1520.4, 4.3), label = "Beach Shack", drug = "coke_small", amount = {1, 2}, time = 15000 },
    { coords = vector3(1525.2, 6331.4, 24.2), label = "Abandoned Motel", drug = "meth", amount = {1, 2}, time = 20000 }
}

Config.Messages = {
    no_drugs = "You don't have any drugs on you!",
    rejected = "The buyer wasn't interested...",
    sold = "You sold %s for $%s",
    police = "Someone reported suspicious activity!",
    not_enough_police = "The streets are too quiet right now (Not enough police)",
    delivery_incoming = "A buyer is heading to your location. Wait for them.",
    too_far = "You moved too far! The buyer got spooked.",
    picked = "You found some %s",
    failed_pick = "You searched but found nothing useful here.",
    cooldown = "You need to wait before picking here again.",
    inflation_set = "Global inflation multiplier set to %sx",
    no_perms = "You do not have permission to use this command."
}