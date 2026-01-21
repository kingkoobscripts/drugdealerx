Framework = nil
PlayerItems = {}

--- Detect Framework
if GetResourceState("qb-core") == "started" then
    Framework = "qb"
    QBCore = exports["qb-core"]:GetCoreObject()
elseif GetResourceState("qbx_core") == "started" then
    Framework = "qbx"
elseif GetResourceState("es_extended") == "started" then
    Framework = "esx"
    ESX = exports["es_extended"]:getSharedObject()
else
    Framework = "standalone"
end

--- Bridge Functions
Bridge = {
    GetPlayer = function(source)
        if Framework == "qb" then
            return QBCore.Functions.GetPlayer(source)
        elseif Framework == "qbx" then
            return exports.qbx_core:GetPlayer(source)
        elseif Framework == "esx" then
            return ESX.GetPlayerFromId(source)
        end
        return nil
    end,

    GetIdentifier = function(source)
        local player = Bridge.GetPlayer(source)
        if not player then return nil end
        if Framework == "qb" or Framework == "qbx" then return player.PlayerData.citizenid end
        if Framework == "esx" then return player.identifier end
        return GetPlayerIdentifier(source, 0)
    end,

    Notify = function(source, text, type)
        if IsDuplicityVersion() then
            TriggerClientEvent("ox_lib:notify", source, { description = text, type = type or "inform" })
        else
            lib.notify({ description = text, type = type or "inform" })
        end
    end,

    GetJob = function(source)
        local player = Bridge.GetPlayer(source)
        if not player then return "none" end
        if Framework == "qb" or Framework == "qbx" then return player.PlayerData.job.name end
        if Framework == "esx" then return player.job.name end
        return "none"
    end,

    AddItem = function(source, item, count)
        if Framework == "qb" or Framework == "qbx" then
            local player = Bridge.GetPlayer(source)
            return player.Functions.AddItem(item, count)
        elseif Framework == "esx" then
            local player = Bridge.GetPlayer(source)
            player.addInventoryItem(item, count)
            return true
        end
        return false
    end,

    RemoveItem = function(source, item, count)
        if Framework == "qb" or Framework == "qbx" then
            local player = Bridge.GetPlayer(source)
            return player.Functions.RemoveItem(item, count)
        elseif Framework == "esx" then
            local player = Bridge.GetPlayer(source)
            if player.getInventoryItem(item).count >= count then
                player.removeInventoryItem(item, count)
                return true
            end
        end
        return false
    end,

    GetItemCount = function(source, item)
        if Framework == "qb" or Framework == "qbx" then
            local player = Bridge.GetPlayer(source)
            local itemData = player.Functions.GetItemByName(item)
            return itemData and itemData.amount or 0
        elseif Framework == "esx" then
            local player = Bridge.GetPlayer(source)
            return player.getInventoryItem(item).count
        end
        return 0
    end
}