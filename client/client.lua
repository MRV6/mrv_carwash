AddEventHandler('playerSpawned', function()
    if (GetCurrentResourceName() == "mrv_carwash") then
        Utils:CreateBlips()
        Utils:StartMainLoop()
    end
end)