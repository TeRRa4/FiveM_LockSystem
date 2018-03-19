local vehicles = {} -- vehicles[plate] = Object vehicle

AddEventHandler("playerSpawned", function()
    TriggerServerEvent("ls:retrieveVehiclesOnconnect")
end)

Citizen.CreateThread(function()
    while true do 
        Wait(0)

        -- If the defined key is pressed
        if(IsControlJustPressed(1, globalConf["CLIENT"].key))then

            -- Init player infos
            local ply = GetPlayerPed(-1)
            local pCoords = GetEntityCoords(ply, true)
            local px, py, pz = table.unpack(GetEntityCoords(ply, true))
            isInside = false

            -- Retrieve the local ID of the targeted vehicle
            if(IsPedInAnyVehicle(ply, true))then
                localVehId = GetVehiclePedIsIn(GetPlayerPed(-1), false) -- by sitting inside him
                isInside = true
            else
                localVehId = GetTargetedVehicle(pCoords, ply) -- by targeting the vehicle
            end

            -- Get targeted vehicle infos
            if(localVehId and localVehId ~= 0)then
                local localVehPlate = string.lower(GetVehicleNumberPlateText(localVehId))
                local localVehLockStatus = GetVehicleDoorLockStatus(localVehId)
                local hasKey = false

                -- If the player has the keys
                for plate, vehicle in pairs(vehicles) do
                    if(string.lower(plate) == localVehPlate)then
                        hasKey = true
                        vehicle.update(localVehId, localVehLockStatus) -- update the vehicle infos (Useful for hydrating instances created by the /givekey command)
                        vehicle.lock() -- Lock or unlock the vehicle
                    end
                end

                -- Else if the player doesn't have the keys
                if(not hasKey)then
                    
                    -- If the player is inside the vehicle
                    if(isInside)then

                        -- Check if vehicle is owned by someone
                        hasOwner = false
                        TriggerServerEvent('ls:checkOwner', localVehPlate)

                        -- If no one owns the vehicle
                        if(not hasOwner)then
                            -- Get the keys
                            TriggerEvent("ls:newVehicle", localVehId, localVehPlate, localVehLockStatus)
                            TriggerServerEvent("ls:addOwner", localVehPlate)

                            TriggerEvent("ls:notify", "You recovered the keys of the vehicle.")
                        else
                            TriggerEvent("ls:notify", "This vehicle is not yours!")
                        end
                    end
                end
            end
        end
    end
end)

-- Prevents the player from breaking the window if the vehicle is locked 
-- (fixing a bug in the previous version)
Citizen.CreateThread(function()
	while true do
		Wait(0)
		local ped = GetPlayerPed(-1)
        if DoesEntityExist(GetVehiclePedIsTryingToEnter(PlayerPedId(ped))) then
        	local veh = GetVehiclePedIsTryingToEnter(PlayerPedId(ped))
	        local lock = GetVehicleDoorLockStatus(veh)
	        if lock == 4 then
	        	ClearPedTasks(ped)
	        end
        end
	end
end)

-- Locks a car if a nonplayer character is in it
if(globalConf['CLIENT'].disableCar_NPC)then
    Citizen.CreateThread(function()
        while true do 
            Wait(0)
            local ped = GetPlayerPed(-1)
            if DoesEntityExist(GetVehiclePedIsTryingToEnter(PlayerPedId(ped))) then
                local veh = GetVehiclePedIsTryingToEnter(PlayerPedId(ped))
                local lock = GetVehicleDoorLockStatus(veh)
                if lock == 7 then
                    SetVehicleDoorsLocked(veh, 2)
                end
                local pedd = GetPedInVehicleSeat(veh, -1)
                if pedd then
                    SetPedCanBeDraggedOut(pedd, false)
                end
            end
        end
    end)
end

------------------------    EVENTS      ------------------------ 
------------------------     :)         ------------------------ 

RegisterNetEvent("ls:updateVehiclePlate")
AddEventHandler("ls:updateVehiclePlate", function(oldPlate, newPlate)
    local oldPlate = string.lower(oldPlate)
    local newPlate = string.lower(newPlate)

    if(vehicles[oldPlate])then
        vehicles[newPlate] = vehicles[oldPlate]
        vehicles[oldPlate] = nil

        TriggerServerEvent("ls:updateServerVehiclePlate", oldPlate, newPlate)
    end
end)

-- @ Create client instance of a vehicle
-- @ Get params : [id], plate, [lockStatus]
RegisterNetEvent("ls:newVehicle")
AddEventHandler("ls:newVehicle", function(id, plate, lockStatus)
    if(plate)then
        local plate = string.lower(plate)
        if(not id)then id = nil end
        if(not lockStatus)then lockStatus = nil end
        vehicles[plate] = newVehicle()
        vehicles[plate].__construct(id, plate, lockStatus)
    else
        print("Can't create the vehicle instance. Missing argument PLATE")
    end
end)

-- @ Create client instance of a vehicle
-- @ Returns void
RegisterNetEvent("ls:giveKeys")
AddEventHandler("ls:giveKeys", function(plate)
    local plate = string.lower(plate)
    TriggerEvent("ls:newVehicle", nil, plate, nil)
end)

-- @ Returns hasOwner : Boolean
RegisterNetEvent("ls:getHasOwner")
AddEventHandler("ls:getHasOwner", function(hasOwner)
    print("RECEIVED HASOWNER :")
    print(hasOwner) -- nil
    print("END")
    if(hasOwner)then
        hasOwner = true
    end
end)

-- Piece of code from Scott's InteractSound script : https://forum.fivem.net/t/release-play-custom-sounds-for-interactions/8282
-- I've decided to use only one part of its script so that administrators don't have to download more scripts. I hope you won't forget to thank him!
RegisterNetEvent('InteractSound_CL:PlayWithinDistance')
AddEventHandler('InteractSound_CL:PlayWithinDistance', function(playerNetId, maxDistance, soundFile, soundVolume)
    local lCoords = GetEntityCoords(GetPlayerPed(-1))
    local eCoords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(playerNetId)))
    local distIs  = Vdist(lCoords.x, lCoords.y, lCoords.z, eCoords.x, eCoords.y, eCoords.z)
    if(distIs <= maxDistance) then
        SendNUIMessage({
            transactionType     = 'playSound',
            transactionFile     = soundFile,
            transactionVolume   = soundVolume
        })
    end
end)

-- @ Send a notification
RegisterNetEvent('ls:notify')
AddEventHandler('ls:notify', function(text, duration)
	Notify(text, duration)
end)

------------------------    FUNCTIONS      ------------------------ 
------------------------        :O         ------------------------ 

-- @ Returns the direction from coordA to coordB
function GetVehicleInDirection(coordFrom, coordTo)
	local rayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, GetPlayerPed(-1), 0)
	local a, b, c, d, vehicle = GetRaycastResult(rayHandle)
	return vehicle
end

-- @ Returns the targeted vehicle id in direction
function GetTargetedVehicle(pCoords, ply)
    for i = 1, 200 do
        coordB = GetOffsetFromEntityInWorldCoords(ply, 0.0, (6.281)/i, 0.0)
        targetedVehicle = GetVehicleInDirection(pCoords, coordB)
        if(targetedVehicle ~= nil and targetedVehicle ~= 0)then
            return targetedVehicle
        end
    end
    return
end

-- @ Send a notification (chatMessage, LockSystem notification or nothing | Configuration inside Config/shared.lua)
-- @ Returns void
function Notify(text, duration)
	if(globalConf['CLIENT'].notification)then
		if(globalConf['CLIENT'].notification == 1)then
			if(not duration)then
				duration = 0.080
			end
			SetNotificationTextEntry("STRING")
			AddTextComponentString(text)
			Citizen.InvokeNative(0x1E6611149DB3DB6B, "CHAR_LIFEINVADER", "CHAR_LIFEINVADER", true, 1, "LockSystem V_" .. _VERSION, "By Deediezi", duration)
			DrawNotification_4(false, true)
		elseif(globalConf['CLIENT'].notification == 2)then
			TriggerEvent('chatMessage', '^1LockSystem', {255, 255, 255}, text)
		else
			return
		end
	else
		return
	end
end