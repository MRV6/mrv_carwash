Citizen.CreateThread(function()
    for i = 1, #Utils.Zones do
        local x, y, z = table.unpack(Utils.Zones[i].pos)

        Utils.CreateBlip("CarWash", 100, x, y, z)
    end

    while true do
        Citizen.Wait(0)

        for i = 1, #Utils.Zones do
            local plyPed = PlayerPedId()
            local plyPos = GetEntityCoords(plyPed)
            local carWashPos = Utils.Zones[i].startPos

            local distance = Utils.GetDistance(plyPos, carWashPos)
            local x, y, z = table.unpack(carWashPos)

            if (distance < 3.5 and IsPedInAnyVehicle(plyPed, false)) then
                Utils:ShowHelp(Utils.Labels["carwash_help"], Utils.CarWashPrice)

                if IsControlJustPressed(0, 51) then
                    Utils:StartCarWash(Utils.Zones[i])
                end
            end
        end
    end
end)