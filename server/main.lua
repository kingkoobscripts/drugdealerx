local pickCooldowns = {}
local GlobalInflation = Config.GlobalInflation

--- Initialize Database
MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS player_rep (
        citizenid VARCHAR(50) NOT NULL,
        reputation INT DEFAULT 0,
        total_sold INT DEFAULT 0,
        total_value INT DEFAULT 0,
        PRIMARY KEY (citizenid)
    )
]])

local function getPlayerData(identifier)
    local result = MySQL.single.await("SELECT reputation, total_sold, total_value FROM player_rep WHERE citizenid = ?", {identifier})
    if not result then
        return { reputation = 0, total_sold = 0, total_value = 0 }
    end
    return result
end

local function updateStats(identifier, repAdd, soldAdd, valueAdd)
    local data = getPlayerData(identifier)
    MySQL.update.await([[
        INSERT INTO player_rep (citizenid, reputation, total_sold, total_value) 
        VALUES (?, ?, ?, ?) 
        ON DUPLICATE KEY UPDATE 
        reputation = reputation + ?, 
        total_sold = total_sold + ?, 
        total_value = total_value + ?
    ]], {
        identifier, repAdd, soldAdd, valueAdd,
        repAdd, soldAdd, valueAdd
    })
end

--- Callbacks
lib.callback.register("drugdealerx:server:getLeaderboard", function(source)
    local results = MySQL.query.await("SELECT citizenid, reputation, total_sold, total_value FROM player_rep ORDER BY total_value DESC LIMIT 10")
    return results
end)

lib.callback.register("drugdealerx:server:getStats", function(source)
    local identifier = Bridge.GetIdentifier(source)
    return getPlayerData(identifier)
end)

lib.callback.register("drugdealerx:server:canSell", function(source)
    local players = GetPlayers()
    local policeCount = 0
    for _, src in pairs(players) do
        if Bridge.GetJob(tonumber(src)) == Config.PoliceJobName then
            policeCount = policeCount + 1
        end
    end
    return policeCount >= Config.MinPolice
end)

--- Admin Commands
RegisterCommand("setinflation", function(source, args)
    if source ~= 0 then
        -- Check permissions via Bridge (Example for QB/ESX)
        local player = Bridge.GetPlayer(source)
        local isAdmin = false
        if Framework == "qb" or Framework == "qbx" then isAdmin = QBCore.Functions.HasPermission(source, "admin")
        elseif Framework == "esx" then isAdmin = (player.getGroup() == "admin") end
        
        if not isAdmin then
            Bridge.Notify(source, Config.Messages.no_perms, "error")
            return
        end
    end

    local newRate = tonumber(args[1])
    if newRate then
        GlobalInflation = newRate
        Bridge.Notify(source, string.format(Config.Messages.inflation_set, newRate), "success")
    end
end, false)

--- Events
RegisterNetEvent("drugdealerx:server:pickDrug", function(index)
    local src = source
    local identifier = Bridge.GetIdentifier(src)
    if not identifier or not Config.PickLocations[index] then return end

    local loc = Config.PickLocations[index]
    local drugData = Config.Drugs[loc.drug]
    local cooldownId = identifier .. "_" .. index
    
    if pickCooldowns[cooldownId] and os.time() < pickCooldowns[cooldownId] then
        Bridge.Notify(src, Config.Messages.cooldown, "error")
        return
    end

    -- Custom Rate Logic
    if math.random() > drugData.rarity then
        Bridge.Notify(src, Config.Messages.failed_pick, "error")
        pickCooldowns[cooldownId] = os.time() + 30
        return
    end

    local amount = math.random(loc.amount[1], loc.amount[2])
    if Bridge.AddItem(src, loc.drug, amount) then
        Bridge.Notify(src, string.format(Config.Messages.picked, drugData.label), "success")
        pickCooldowns[cooldownId] = os.time() + 60
    end
end)

RegisterNetEvent("drugdealerx:server:processSale", function(isBulk)
    local src = source
    local identifier = Bridge.GetIdentifier(src)
    if not identifier then return end

    local availableDrugs = {}
    for itemName, data in pairs(Config.Drugs) do
        local count = Bridge.GetItemCount(src, itemName)
        if count > 0 then
            table.insert(availableDrugs, {
                name = itemName,
                label = data.label,
                min = data.minPrice,
                max = data.maxPrice,
                rep = data.repGain,
                count = count
            })
        end
    end

    if #availableDrugs == 0 then
        Bridge.Notify(src, Config.Messages.no_drugs, "error")
        return
    end

    local selected = availableDrugs[math.random(1, #availableDrugs)]
    local sellAmount = isBulk and math.random(5, 10) or 1
    if sellAmount > selected.count then sellAmount = selected.count end

    -- Price Calculation with Inflation and Bonus
    local pricePer = math.random(selected.min, selected.max)
    local data = getPlayerData(identifier)
    
    local basePrice = (pricePer + math.floor(data.reputation / 10)) * sellAmount
    local inflatedPrice = basePrice * GlobalInflation
    
    if isBulk then
        inflatedPrice = inflatedPrice * Config.BulkBonus
    end

    local finalPrice = math.floor(inflatedPrice)

    if Bridge.RemoveItem(src, selected.name, sellAmount) then
        local player = Bridge.GetPlayer(src)
        if Framework == "esx" then player.addMoney(finalPrice) else player.Functions.AddMoney("cash", finalPrice) end
        
        updateStats(identifier, selected.rep * sellAmount, sellAmount, finalPrice)
        Bridge.Notify(src, string.format(Config.Messages.sold, selected.label .. " x" .. sellAmount, finalPrice), "success")

        if math.random(1, 100) <= Config.PoliceAlertChance then
            TriggerClientEvent("drugdealerx:client:policeAlert", -1, GetEntityCoords(GetPlayerPed(src)))
        end
    end
end)