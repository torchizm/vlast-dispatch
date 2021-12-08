isOpen = false
lastNotification = {}

local PlayerData = {}

Citizen.CreateThread(function() 
    while QBCore == nil do
        TriggerEvent("QBCore:GetObject", function(obj) QBCore = obj end)
        Citizen.Wait(200)
    end

	PlayerData = QBCore.Functions.GetPlayerData()
end)


RegisterNUICallback('close', function()
	SetNuiFocus(false, false)
	isOpen = false
end)

RegisterNUICallback('get-self', function()
	SendSelf()
end)

RegisterNUICallback("addActiveUnit", function(data)
	TriggerServerEvent("vlast-dispatch:add-active-units", data)
end)

RegisterNUICallback("removeActiveUnit", function(data)
	TriggerServerEvent("vlast-dispatch:remove-active-units", data)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
	
	while PlayerData == nil do
		Citizen.Wait(5)
	end

	SendSelf()
end)

RegisterNetEvent("vlast-dispatch:add-active-units")
AddEventHandler("vlast-dispatch:add-active-units", function(data)
	SendNUIMessage({type = "update", content = "add-active-unit", data = data})
end)

RegisterNetEvent("vlast-dispatch:remove-active-units")
AddEventHandler("vlast-dispatch:remove-active-units", function(data)
	SendNUIMessage({type = "update", content = "remove-active-unit", data = data})
end)

RegisterNetEvent("QBCore:Client:OnJobUpdate")
AddEventHandler("QBCore:Client:OnJobUpdate", function(job)
    PlayerData.job = job
end)

function SendSelf()
	PlayerData = QBCore.Functions.GetPlayerData()

	data = {}
	data.name = PlayerData.charinfo.firstname .. " " .. PlayerData.charinfo.lastname
	data.citizenId = PlayerData.citizenid
	data.radioCode = PlayerData.metadata["radiocode"]
	data.job = PlayerData.job.label

	SendNUIMessage({type = "update", content = "self", data = data})
end

RegisterNUICallback('set-radio-code', function(data, cb)
	PlayerData.metadata["radiocode"] = data.radiocode
	QBCore.Functions.TriggerCallback('vlast-dispatch:set-radio-code', function(data)
		cb(data)
	end, data.radiocode)
end)

RegisterNUICallback('set-waypoint', function(data)
	SetNewWaypoint(tonumber(data.x), tonumber(data.y))
end)

RegisterKeyMapping('+dispatch', 'Dispatch', 'keyboard', 'F6') 

RegisterCommand("+dispatch", function(source, args)
	if (isOpen == false) then
		if PlayerData == nil or PlayerData.job == nil or PlayerData.job.name == nil then
			PlayerData = QBCore.Functions.GetPlayerData()
		end
		while PlayerData == nil do
			Citizen.Wait(10)
		end
		if PlayerData.job.name ~= "police" and PlayerData.job.name ~= "ambulance" then
			return
		end
	end
    Toggle(not isOpen)
end)

RegisterCommand('kod', function(source, args, raw)
	if args[1] == nil then return end

	if PlayerData == nil or PlayerData.job == nil or PlayerData.job.name == nil then
		PlayerData = QBCore.Functions.GetPlayerData()
	end

	while PlayerData == nil do
		Citizen.Wait(10)
	end

	if PlayerData.job.name ~= "police" then
		return
	end

	local description = ""
	local code = Codes[tonumber(args[1])]

	local id = math.random(1, 9999)
	data = {
		id = id,
		code = args[1],
		sprite = 280,
	}

	if code == nil or code.description == nil then 
		data.description = "Memur yardım istiyor"
	else
		data.description = PlayerData.charinfo.firstname.." "..PlayerData.charinfo.lastname.. code.description

		if code.coords == true then 
			local ped = PlayerPedId()
			local street = GetTheStreet()
			local playerPos = GetEntityCoords(ped)
			
			data.coords = playerPos
			data.location = street
		end
	end
	
	TriggerServerEvent("vlast-dispatch:add-notification", data, "police")
end)


RegisterNetEvent("vlast-dispatch:send-notification")
AddEventHandler("vlast-dispatch:send-notification", function(data) 
	SendNotification(data)
end)

RegisterNetEvent("vlast-dispatch:refresh")
AddEventHandler("vlast-dispatch:refresh", function(data)
	SendNUIMessage({type = "update", contents = "notifications", data = data})
end)


function Toggle(val)
	if val then
		QBCore.Functions.TriggerCallback('vlast-dispatch:get-dispatchs', function(data)
			user = {}
			user.name = PlayerData.charinfo.firstname .. " " .. PlayerData.charinfo.lastname
			user.citizenId = PlayerData.citizenid
			user.radioCode = PlayerData.metadata["radiocode"] or "YOK"
			user.job = PlayerData.job.label
			SendNUIMessage({type = "open", data = data, user = user})
		end)
		SetNuiFocus(true, true)
	else
		SendNUIMessage({type = "close"})
		SetNuiFocus(false, false)
	end

	isOpen = val
end

function SendNotification(data)
	lastNotification = data
	SendNUIMessage({type = "notification", data = data})

	Citizen.Wait(5000)
	lastNotification.focused = true
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)
		local ped = PlayerPedId()
		local playerPos = GetEntityCoords(ped)
		
		if IsPedShooting(ped) and math.random(1, 2) == 1 and PlayerData.job.name ~= "police" then

			if GetSelectedPedWeapon(ped) == "101631238" then 
				return 
			end
			
			local street = GetTheStreet()
			local weapon = WeaponNames[tostring(GetSelectedPedWeapon(ped))]
			local id = math.random(1, 9999)

			data = {
				id = id,
				code = 1,
				description = "Ateş sesleri duyuldu",
				location = street,
				coords = playerPos,
				sprite = 433
			}
			
			TriggerServerEvent("vlast-dispatch:add-notification", data, "police")
			Citizen.Wait(20000)
		end
	end
end)
 
RegisterNetEvent("vlast-dispatchAddBlip")
AddEventHandler("vlast-dispatchAddBlip", function(x, y, icon, alertName)
	local alpha = 200
    local blip = AddBlipForCoord(x, y, 5.0)
	SetBlipSprite(blip, icon)
    SetBlipDisplay(blip, 2)
    SetBlipScale(blip, 1.60)
    SetBlipColour(blip, 75)
    SetBlipAsShortRange(blip, false)
    SetBlipAlpha(blip, alpha)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(alertName)
    EndTextCommandSetBlipName(blip)

    while alpha ~= 0 do
        Citizen.Wait(60 * 6)
        alpha = alpha - 1
        SetBlipAlpha(blip, alpha)

        if alpha == 0 then
            RemoveBlip(blip)
            break
        end
    end
end)


function GetTheStreet()
    local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
    local currentStreetHash, intersectStreetHash = GetStreetNameAtCoord(x, y, z, currentStreetHash, intersectStreetHash)
    currentStreetName = GetStreetNameFromHashKey(currentStreetHash)
    intersectStreetName = GetStreetNameFromHashKey(intersectStreetHash)
    zone = tostring(GetNameOfZone(x, y, z))
    playerStreetsLocation = ZoneNames[tostring(zone)]

    if not zone then
        zone = "UNKNOWN"
        ZoneNames['UNKNOWN'] = zone
    elseif not ZoneNames[tostring(zone)] then
        local undefinedZone = zone .. " " .. x .. " " .. y .. " " .. z
        ZoneNames[tostring(zone)] = "Undefined Zone"
    end

    if (intersectStreetName ~= nil and intersectStreetName ~= "") or (currentStreetName ~= nil and currentStreetName ~= "") then
        playerStreetsLocation = currentStreetName
    else
        playerStreetsLocation = ZoneNames[tostring(zone)]
    end

	return playerStreetsLocation
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(5)

		if IsControlJustPressed(0, 19) and lastNotification.id ~= nil and (lastNotification.focused == nil or lastNotification.focues == false) and lastNotification.coords ~= nil then
			lastNotification.focused = true
			SetNewWaypoint(lastNotification.coords.x, lastNotification.coords.y)
		end
	end
end)