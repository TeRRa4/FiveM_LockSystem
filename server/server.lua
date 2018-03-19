local owners = {} -- owners[plate] = identifier
local secondOwners = {} -- secondOwners[plate] = {identifier, identifier, ...}

RegisterServerEvent("ls:updateServerVehiclePlate")
AddEventHandler("ls:updateServerVehiclePlate", function(oldPlate, newPlate)
    local oldPlate = string.lower(oldPlate)
    local newPlate = string.lower(newPlate)

    if(owners[oldPlate] and not owners[newPlate])then 
        owners[newPlate] = owners[oldPlate]
        owners[oldPlate] = nil
    end
    if(secondOwners[oldPlate] and not secondOwners[newPlate])then
        secondOwners[newPlate] = secondOwners[oldPlate]
        secondOwners[oldPlate] = nil
    end
end)

RegisterServerEvent("ls:retrieveVehiclesOnconnect")
AddEventHandler("ls:retrieveVehiclesOnconnect", function()
    local src = source
    local srcIdentifier = GetPlayerIdentifiers(src)[1]

    for plate, plyIdentifier in pairs(owners) do
        if(plyIdentifier == srcIdentifier)then 
            TriggerClientEvent("ls:newVehicle", src, nil, plate, nil)
        end
    end

    for plate, identifiers in pairs(secondOwners) do 
        for _, plyIdentifier in ipairs(identifiers) do 
            if(plyIdentifier == srcIdentifier)then
                TriggerClientEvent("ls:newVehicle", src, nil, plate, nil)
            end
        end
    end
end)

RegisterServerEvent("ls:addSecondOwner")
AddEventHandler("ls:addSecondOwner", function(targetIdentifier, plate)
    local plate = string.lower(plate)
    table.insert(secondOwners[plate], targetIdentifier)
end)

RegisterServerEvent("ls:addOwner")
AddEventHandler("ls:addOwner", function(plate)
    local src = source
    local identifier = GetPlayerIdentifiers(src)[1]
    local plate = string.lower(plate)

    owners[plate] = identifier
end)

RegisterNetEvent("ls:checkOwner")
AddEventHandler("ls:checkOwner", function(localVehId, plate, lockStatus)
    local plate = string.lower(plate)
    local src = source
    local hasOwner = false

    if(not owners[plate])then
        TriggerClientEvent("ls:getHasOwner", src, nil, localVehId, plate, lockStatus)
    else 
        TriggerClientEvent("ls:getHasOwner", src, true, localVehId, plate, lockStatus)
    end
end)

RegisterCommand('givekey', function(source, args, rawCommand)
    local src = source
    local identifier = GetPlayerIdentifiers(src)[1]

    local targetId = args[1]
    local plate = string.lower(args[2])

    if(targetId)then
        local targetIdentifier = GetPlayerIdentifiers(targetId)[1]
        if(targetIdentifier)then 
            if(targetIdentifier ~= identifier)then
                if(plate)then
                    if(owners[plate])then
                        if(owners[plate] == identifier)then
                            TriggerClientEvent("ls:giveKeys", targetIdentifier, plate)
                            TriggerEvent("ls:addSecondOwner", targetIdentifier, plate)

                            TriggerClientEvent('chatMessage', targetId, '', {255, 255, 255}, "You have received the keys to car " .. plate .. " by " .. GetPlayerName(src))
                            TriggerClientEvent('chatMessage', src, '', {255, 255, 255}, "You gave the keys to car " .. plate .. " to " .. GetPlayerName(targetId))
                        else 
                            TriggerClientEvent('chatMessage', src, '', {255, 255, 255}, "^1It's not your vehicle.")
                        end
                    else 
                        TriggerClientEvent('chatMessage', src, '', {255, 255, 255}, '^1The vehicle with this plate does not exist.')
                    end
                else 
                    TriggerClientEvent('chatMessage', src, '', {255, 255, 255}, '^1Second missing argument : ^0/givekey <id> ^3<plate>')
                end
            else
                TriggerClientEvent('chatMessage', src, '', {255, 255, 255}, "^1You can't target yourself.")
            end
        else
            TriggerClientEvent('chatMessage', src, '', {255, 255, 255}, '^1Player not found.')
        end
    else
        TriggerClientEvent('chatMessage', src, '', {255, 255, 255}, '^First missing argument : ^0/givekey ^3<id> ^0<plate>')
    end

    CancelEvent()
end)

-- Piece of code from Scott's InteractSound script : https://forum.fivem.net/t/release-play-custom-sounds-for-interactions/8282
RegisterServerEvent('InteractSound_SV:PlayWithinDistance')
AddEventHandler('InteractSound_SV:PlayWithinDistance', function(maxDistance, soundFile, soundVolume)
    TriggerClientEvent('InteractSound_CL:PlayWithinDistance', -1, source, maxDistance, soundFile, soundVolume)
end)

if globalConf['SERVER'].versionChecker then
	PerformHttpRequest("https://www.dropbox.com/s/3m0pubbh3qqfqyy/version.txt?dl=0", function(err, rText, headers)
		if rText then
			if tonumber(rText) > tonumber(_VERSION) then
				print("\n---------------------------------------------------")
				print("LockSystem : An update is available !")
				print("---------------------------------------------------")
				print("Current : " .. _VERSION)
				print("Latest  : " .. rText .. "\n")
			end
		else
			print("\n---------------------------------------------------")
			print("Unable to find the version.")
			print("---------------------------------------------------\n")
		end
	end, "GET", "", {what = 'this'})
end