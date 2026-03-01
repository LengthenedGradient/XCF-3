if SERVER then
    local Baseplate = XCF.DefineClass("Baseplate", nil, function(Class, BaseClass)
        print("Baseplate class initialized", Class, BaseClass)
    end)

    local AircraftBaseplate = XCF.DefineClass("AircraftBP", "Baseplate", function(Class, BaseClass)
        print("AircraftBaseplate class initialized", Class, BaseClass)
    end)

    local GroundVehicleBaseplate = XCF.DefineClass("GroundVehicleBP", "Baseplate", function(Class, BaseClass)
        print("GroundVehicleBaseplate class initialized", Class, BaseClass)
    end)

    print("test")
end