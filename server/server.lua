QBCore = nil
Dispatchs = {}

TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)

QBCore.Functions.CreateCallback('vlast-dispatch:get-dispatchs', function(source, cb)
    cb(Dispatchs)
end)

QBCore.Functions.CreateCallback('vlast-dispatch:set-radio-code', function(source, cb, code)
    player = QBCore.Functions.GetPlayer(source)

    exports["ghmattimysql"]:execute("SELECT * FROM players WHERE `metadata` LIKE '%"..code.."%'", {
    }, function(result)
        if result[1] == nil then
            player.Functions.SetMetaData("radiocode", code)
            cb(true)
        else
            cb(false)
        end
    end)
end)

RegisterServerEvent("vlast-dispatch:add-notification")
AddEventHandler("vlast-dispatch:add-notification", function(data, job)
    if job == nil or job == "all" then
        TriggerClientEvent("vlast-dispatch:send-notification", -1, data)
        return
    end

    players = QBCore.Functions.GetPlayers()
    
    for k,v in pairs(players) do
        player = QBCore.Functions.GetPlayer(v)
        if player.PlayerData.job.name == job then
            TriggerClientEvent("vlast-dispatch:send-notification", v, data)
            if data.sprite == nil then data.sprite = 433 end
            TriggerClientEvent("vlast-dispatchAddBlip", v, data.coords.x, data.coords.y, data.sprite, data.description)
        end
    end
end)

RegisterServerEvent("vlast-dispatch:add-dispatch")
AddEventHandler("vlast-dispatch:add-dispatch", function(data, refresh)
    table.insert(Dispatchs, data)

    if refresh then
        TriggerClientEvent("vlast-dispatch:refresh-dispatchs", Dispatchs)
    end
end)

RegisterServerEvent("vlast-dispatch:add-active-units")
AddEventHandler("vlast-dispatch:add-active-units", function(data)
    TriggerClientEvent("vlast-dispatch:add-active-units", -1, data)
end)

RegisterServerEvent("vlast-dispatch:remove-active-units")
AddEventHandler("vlast-dispatch:remove-active-units", function(data)
    TriggerClientEvent("vlast-dispatch:remove-active-units", -1, data)
end)