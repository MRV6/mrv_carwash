AddEventHandler('onResourceStart', function(resourceName)
    if (resourceName == "mrv_carwash") then
        Utils:CreateBlips()
        Utils:StartMainLoop()
    end
end)