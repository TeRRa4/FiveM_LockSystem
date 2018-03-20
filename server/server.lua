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

    if(secondOwners[plate])then
        table.insert(secondOwners[plate], targetIdentifier)
    else
        secondOwners[plate] = {targetIdentifier}
    end
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

if(globalConf["SERVER"]["GIVEKEY"].enable)
    if(globalConf["SERVER"]["GIVEKEY"].basic_chat)
        RegisterCommand('givekey', function(source, args, rawCommand)
            local src = source
            local identifier = GetPlayerIdentifiers(src)[1]

            if(args[1])then
                local targetId = args[1]
                local targetIdentifier = GetPlayerIdentifiers(targetId)[1]
                if(targetIdentifier)then 
                    if(targetIdentifier ~= identifier)then
                        if(args[2])then
                            local plate = string.lower(args[2])
                            if(owners[plate])then
                                if(owners[plate] == identifier)then
                                    alreadyHas = false
                                    for k, v in pairs(secondOwners) do 
                                        if(k == plate)then
                                            for _, val in ipairs(v) do
                                                if(val == targetIdentifier)then
                                                    alreadyHas = true
                                                end
                                            end
                                        end
                                    end

                                    if(not alreadyHas)then
                                        TriggerClientEvent("ls:giveKeys", targetIdentifier, plate)
                                        TriggerEvent("ls:addSecondOwner", targetIdentifier, plate)

                                        TriggerClientEvent("ls:notify", targetId, "You have been received the keys of vehicle " .. plate .. " by " .. GetPlayerName(src))
                                        TriggerClientEvent("ls:notify", src, "You gave the keys of vehicle " .. plate .. " to " .. GetPlayerName(targetId))
                                    else 
                                        TriggerClientEvent("ls:notify", src, "The target already has the keys of the vehicle")
                                        TriggerClientEvent("ls:notify", targetId, GetPlayerName(src) .. " tried to give you his keys, but you already had them")
                                    end
                                else 
                                    TriggerClientEvent("ls:notify", src, "This is not your vehicle")
                                end
                            else 
                                TriggerClientEvent("ls:notify", src, "The vehicle with this plate doesn't exist")
                            end
                        else 
                            TriggerClientEvent("ls:notify", src, "Second missing argument : /givekey <id> <plate>")
                        end
                    else
                        TriggerClientEvent("ls:notify", src, "You can't target yourself")
                    end
                else
                    TriggerClientEvent("ls:notify", src, "Player not found")
                end
            else
                TriggerClientEvent("ls:notify", src, 'First missing argument : /givekey <id> <plate>')
            end

            CancelEvent()
        end)
    end
end

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