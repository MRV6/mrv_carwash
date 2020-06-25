Utils = {
    Zones = {
        {
            pos = vector3(-3.976, -1392.261, 29.304), 
            heading = 92.158, 
            startPos = vector3(49.581, -1392.304, 28.420), 
            endPos = vector3(-3.804, -1391.698, 28.302),
            wait = 12, -- seconds

            particlesStart = {
                -- Premier rouleau (droite)
                {pos = vector3(37.440, -1390.143, 28.000), particle = "ent_amb_car_wash_jet", xRot = 90.0},
                {pos = vector3(37.440, -1390.143, 29.800), particle = "ent_amb_car_wash_jet", xRot = 90.0},
                
                -- Premier rouleau (gauche)
                {pos = vector3(37.430, -1393.497, 28.000), particle = "ent_amb_car_wash_jet", xRot = -90.0},
                {pos = vector3(37.430, -1393.497, 29.800), particle = "ent_amb_car_wash_jet", xRot = -90.0}
            }
        }
    },

    MarkerType = 2,

    Labels = {
        ["carwash_help"] = "CWASH_RIDEHLP",
        -- ["carwash_no_money"] = "CWASH_NOMONEY",
        ["car_broke"] = "CWASH_CARBROKE"
    },

    DisplayHelp = true,
    MinimalDirtLevel = 5.0,
    MaximalBodyHealth = 800.0,
    CarWashPrice = 5
}

function Utils:ShowHelp(label, addNumber)
    if self.DisplayHelp then
        BeginTextCommandDisplayHelp(label)
        if (addNumber) then AddTextComponentInteger(addNumber) end
        EndTextCommandDisplayHelp(0, 0, 0, -1)
    end
end

function Utils.ShowNotification(text, begin)
    BeginTextCommandThefeedPost(begin or "STRING")
    if (text) then AddTextComponentSubstringPlayerName(text) end
    EndTextCommandThefeedPostTicker(true, true)
end

function Utils.GetDistance(coords1, coords2)
    return #(coords1 - coords2)
end

function Utils.CreateBlip(label, sprite, x, y, z, scale, color)
    local blip = AddBlipForCoord(x, y, z)

	SetBlipSprite (blip, sprite)
	SetBlipDisplay(blip, 4)
	SetBlipScale  (blip, (scale or 1.0))
	SetBlipColour (blip, (color or 4))
	SetBlipAsShortRange(blip, true)

	BeginTextCommandSetBlipName("STRING")
	AddTextComponentSubstringPlayerName(label)
	EndTextCommandSetBlipName(blip)
end

function Utils.ShowLoadingPrompt(msg, type)
	BeginTextCommandBusyspinnerOn("STRING")
	AddTextComponentSubstringPlayerName(msg)
    EndTextCommandBusyspinnerOn(type)
end

function Utils.StartWashParticle(actualZone)
    local asset = "scr_carwash"

    for i = 1, #actualZone.particlesStart do
        local particle = actualZone.particlesStart[i]
        local x, y, z = table.unpack(particle.pos)

        RequestNamedPtfxAsset(asset)
        UseParticleFxAssetNextCall(asset)

        while not HasNamedPtfxAssetLoaded(asset) do
            Citizen.Wait(100)

            RequestNamedPtfxAsset(asset)
        end
        
        StartParticleFxLoopedAtCoord(particle.particle, x, y, z, particle.xRot, 0.0, 0.0, 1.0, 0, 0, 0)
    end
end

function Utils:StartCarWash(actualZone)
    Citizen.CreateThread(function()
        local plyPed = PlayerPedId()
        local plyVeh = GetVehiclePedIsIn(plyPed, false)
        local wait = (actualZone.wait * 1000)

        -- Citizen.InvokeNative(0x6D6840CEE8845831, "launcher_CarWash")

        if (DoesEntityExist(plyVeh)) then
            local endX, endY, enZ = table.unpack(actualZone.endPos)
            local bodyHealth = GetVehicleBodyHealth(plyVeh)

            if (bodyHealth > self.MaximalBodyHealth) then
                self.DisplayHelp = false

                SetEntityCoordsNoOffset(plyVeh, actualZone.startPos, false, false, false)
                SetEntityHeading(plyVeh, actualZone.heading)

                SetCurrentPedWeapon(plyPed, GetHashKey("WEAPON_UNARMED"), true)
                SetEveryoneIgnorePlayer(plyPed, true)
                SetPlayerControl(plyPed, false)

                DisplayHud(false)
                DisplayRadar(false)

                Citizen.Wait(250)

                Utils.StartWashParticle(actualZone)

                TaskVehicleDriveToCoord(plyPed, plyVeh, endX, endY, enZ, 5.0, 0.0, GetEntityModel(plyVeh), 262144, 1.0, 1000.0)

                self.ShowLoadingPrompt("Lavage du véhicule ...", 1)

                Citizen.Wait(wait)

                if (BusyspinnerIsOn()) then BusyspinnerOff() end

                DisplayHud(true)
                DisplayRadar(true)

                SetVehicleDirtLevel(plyVeh, 0.0)
                SetEveryoneIgnorePlayer(plyPed, false)
                SetPlayerControl(plyPed, true)

                self.DisplayHelp = true
            else
                self.ShowNotification(nil, self.Labels["car_broke"])
            end
        end
    end)
end

-- # TEST # --
RegisterCommand("veh", function(source, args)
    local hash = GetHashKey(args[1])

    RequestModel(hash)

    while not HasModelLoaded(hash) do
        Citizen.Wait(100)

        RequestModel(hash)
    end

    local x, y, z = table.unpack(GetEntityCoords(PlayerPedId()))
    local veh = CreateVehicle(hash, x, y, z, 180.0, false, false)

    SetPedIntoVehicle(PlayerPedId(), veh, -1)
end)

RegisterCommand("tpm", function(source, args)
    local WaypointHandle = GetFirstBlipInfoId(8)

    if DoesBlipExist(WaypointHandle) then
        local waypointCoords = GetBlipInfoIdCoord(WaypointHandle)

        for height = 1, 1000 do
            SetPedCoordsKeepVehicle(PlayerPedId(), waypointCoords["x"], waypointCoords["y"], height + 0.0)

            local foundGround, zPos = GetGroundZFor_3dCoord(waypointCoords["x"], waypointCoords["y"], height + 0.0)

            if foundGround then
                SetPedCoordsKeepVehicle(PlayerPedId(), waypointCoords["x"], waypointCoords["y"], height + 0.0)

                break
            end

            Citizen.Wait(5)
        end
    end
end)

RegisterCommand("coords", function(source, args)
    print(table.unpack(GetEntityCoords(PlayerPedId())))
end)

RegisterCommand("vcoords", function(source, args)
    print(table.unpack(GetEntityCoords(GetVehiclePedIsIn(PlayerPedId(), false))))
end)

RegisterCommand("dv", function(source, args)
    local ply = PlayerPedId()
    local plyVeh = GetVehiclePedIsIn(ply, true)

    if (DoesEntityExist(plyVeh)) then
        DeleteEntity(plyVeh)
    end
end)

RegisterCommand("seth", function(source, args)
    local ply = PlayerPedId()
    local plyVeh = GetVehiclePedIsIn(ply, true)

    if (DoesEntityExist(plyVeh)) then
        SetVehicleBodyHealth(plyVeh, tonumber(args[1]))
    end
end)

RegisterCommand("geth", function(source, args)
    local ply = PlayerPedId()
    print(GetEntityHeading(ply))
end)