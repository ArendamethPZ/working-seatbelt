--[[ Since the airbag part is added using script, the relevant snippet should remain in "shared" folder, that way it can run on
both server and client ]]

local function spawnAirbags()
    -- This section blacklists certain vehicles from having an airbag part, either because they're not expected to have it,
    -- or because the lore-friendly option is turned on.
    local scriptManager = getScriptManager()
    local vehicleScripts = scriptManager:getAllVehicleScripts()

    local partTemplates = {
        "Airbag",
    }

    -- Vehicles that are not supposed to have an airbag at all, no matter the circumstances
    local abs_blacklist = {
        -- Vanilla Vehicles
        ["Base.Trailer"] = true,
        ["Base.TrailerAdvert"] = true,
        ["Base.TrailerCover"] = true,

        -- Autotsar Motorclub
        -- https://steamcommunity.com/sharedfiles/filedetails/?id=2778576730
        ["Base.AMC_Waverunner"] = true,
        ["Base.AMC_Waverunner_Ground"] = true,
        ["Base.AMC_bmw_classic"] = true,
        ["Base.AMC_bmw_custom"] = true,
        ["Base.AMC_harley"] = true,
        ["Base.AMC_quad"] = true,
        ["Base.TrailerAMC"] = true,
        ["Base.TrailerAMCWaveRunner"] = true,
        ["Base.TrailerAMCWaveRunnerWithBody"] = true,

        -- APOCALYPSE MACHINES 2 WHEELZ
        -- https://steamcommunity.com/sharedfiles/filedetails/?id=2638496761
        ["Base.AM2_Balrog"] = true,
        ["Base.AM2_Balrog_Sidecar"] = true,
        ["Base.AM2_Camel"] = true,
        ["Base.AM2_Camel2"] = true,
        ["Base.AM2_Courier"] = true,
        ["Base.AM2_DirtDemon"] = true,
        ["Base.AM2_DirtDemon2"] = true,
        ["Base.AM2_Fireball"] = true,
        ["Base.AM2_Kaiju"] = true,
        ["Base.AM2_SkullKing"] = true,
        ["Base.AM2_Steelhorse"] = true,
        ["Base.AM2_Steelhorse2"] = true,
        ["Base.AM2_Vesper"] = true,
        ["Base.AM2_Vesper2"] = true,
        ["Base.AM2_Vesper3"] = true,
        ["Base.AM2_Warhorse"] = true,
        ["Base.AM2_Warhorse2"] = true,
        ["Base.AM2_Warhorse3"] = true,
        ["Base.AM2_Wendigo"] = true,
        ["Base.AM2_Yeti"] = true,

        -- Braven's Bicycles Redux
        -- https://steamcommunity.com/sharedfiles/filedetails/?id=2988491347
        ["Base.BicycleMTB"] = true,
        ["Base.BicycleMTBScrap"] = true,
        ["Base.BicycleRegular"] = true,
        ["Base.BicycleRegularScrap"] = true,
        ["Base.BicycleTrailer"] = true,

        -- '28 Brough Superior SS100
        -- https://steamcommunity.com/sharedfiles/filedetails/?id=2913634132
        ["Base.28ss100"] = true,
        ["Base.28ss100hermes"] = true,

        -- '80 Kawasaki Kz1000 Police
        -- https://steamcommunity.com/sharedfiles/filedetails/?id=2818847163
        ["Base.80kz1000"] = true,

        -- '13 Yamaha Vino 125 + PizzaBoy
        -- https://steamcommunity.com/sharedfiles/filedetails/?id=2878374713
        ["Base.vino125"] = true,
        ["Base.vino125b"] = true,
        ["Base.vino125pizza"] = true,

        -- '90 Zanella 50cc Delivery Scooter
        -- https://steamcommunity.com/sharedfiles/filedetails/?id=2922441474
        ["Base.90zanella50cc"] = true,

        -- Aquatsar Yacht Club
        -- https://steamcommunity.com/sharedfiles/filedetails/?id=2392987599
        ["Base.BoatMotor"] = true,
        ["Base.BoatMotor_Ground"] = true,
        ["Base.BoatSailingYacht"] = true,
        ["Base.BoatSailingYacht_Ground"] = true,
        ["Base.BoatSailingYacht_shipwreckland"] = true,
        ["Base.BoatSailingYacht_shipwreckwater"] = true,
        ["Base.BoatZeroPatient"] = true,

        -- Skateboard
        -- Multiple mods
        ["Base.Skateboard"] = true,
    }

    -- Additional keywords to blacklist, helpul with vehicles mods
    local keyword_blacklist = {
        "trailer",
        "bike",
        "motorcycle",
        "yacht",
        "boat",
        "skateboard"
    }

    -- Helper function to check if a string contains any of the keywords in lowercase
    local function containsKeyword(str, keywords)
        local lowercaseStr = string.lower(str)
        for _, keyword in ipairs(keywords) do
            if string.find(lowercaseStr, string.lower(keyword)) then
                return true
            end
        end
        return false
    end

    -- Vehicles that are not supposed to have an airbag if the lore-friendly option is on
    local lore_blacklist = {
        ["Base.PickUpTruck"] = true,
        ["Base.PickUpTruckLightsFire"] = true,
        ["Base.PickUpTruckLights"] = true,
        ["Base.PickUpTruckMccoy"] = true,
        ["Base.SmallCar"] = true,
        ["Base.StepVan"] = true,
        ["Base.StepVanMail"] = true,
        ["Base.StepVan_Heralds"] = true,
        ["Base.StepVan_Scarlet"] = true,
        ["Base.PickUpVan"] = true,
        ["Base.PickUpVanLights"] = true,
        ["Base.PickUpVanLightsFire"] = true,
        ["Base.PickUpVanLightsPolice"] = true,
        ["Base.PickUpVanMccoy"] = true,
        ["Base.OffRoad"] = true,
        ["Base.SUV"] = true,
        ["Base.Van"] = true,
        ["Base.VanAmbulance"] = true,
        ["Base.VanRadio"] = true,
        ["Base.VanRadio_3N"] = true,
        ["Base.VanSeats"] = true,
        ["Base.VanSpecial"] = true,
        ["Base.VanSpiffo"] = true,
        ["Base.Van_KnoxDisti"] = true,
        ["Base.Van_LectroMax"] = true,
        ["Base.Van_MassGenFac"] = true,
        ["Base.Van_Transit"] = true,
    }

    -- Chevalier D6:
    -- Real-Life Basis: Third-generation Chevrolet C/K truck.
    -- Full-size trucks during the 1990s might not have had airbags as a standard feature, especially in work-oriented or base models.
    -- Variants: Base.PickUpTruck, Base.PickUpTruckLightsFire, Base.PickUpTruckLights, Base.PickUpTruckMccoy

    -- Chevalier Dart:
    -- Real-Life Basis: Chevrolet Sprint, Chevrolet Chevette, and Chevrolet Citation 3-door hatchbacks.
    -- Compact hatchbacks of the time might not have featured airbags as standard, especially in base models.
    -- Variants: Base.SmallCar

    -- Chevalier Step Van:
    -- Real-Life Basis: Chevrolet Stepvan.
    -- Utility vehicles like step vans might not have had airbags as a standard feature due to their commercial and industrial use.
    -- Variants: Base.StepVan, Base.StepVanMail, Base.StepVan_Heralds, Base.StepVan_Scarlet

    -- Dash Bulldriver:
    -- Real-Life Basis: Third-generation Chevrolet C/K truck with an added truck bed cap.
    -- Similar to the Chevalier D6, full-size trucks might not have had airbags as standard in work-oriented or base models.
    -- Variants: Base.PickUpVan, Base.PickUpVanLights, Base.PickUpVanLightsFire, Base.PickUpVanLightsPolice, Base.PickUpVanMccoy

    -- Dash Rancher:
    -- Real-Life Basis: Jeep Wrangler YJ.
    -- Off-road vehicles like the Wrangler might not have had airbags as a standard feature due to their rugged design.
    -- Variants: Base.OffRoad

    -- Franklin All-Terrain:
    -- Real-Life Basis: First-generation Ford Explorer.
    -- SUVs like the Explorer might not have had airbags as a standard feature in the early 1990s.
    -- Variants: Base.SUV

    -- Franklin Valuline:
    -- Real-Life Basis: Third-generation Ford E-Series vans.
    -- Vans like the E-Series might not have had airbags as a standard feature, especially in commercial configurations.
    -- Variants: Base.Van, Base.VanAmbulance, Base.VanRadio, Base.VanRadio_3N, Base.VanSeats, Base.VanSpecial, Base.VanSpiffo,
    -- Base.Van_KnoxDisti, Base.Van_LectroMax, Base.Van_MassGenFac, Base.Van_Transit

    -- We add an airbag to the vehicle if:
    -- 1: It's not in abs_blacklist
    -- 2: It's not in lore_blacklist, assuming SandboxVars.workingSeatbelt.loreFriendlyAirbags is true
    -- 3: It doesn't contain any of the keywords in keyword_blacklist (case-insensitive)

    for i = 0, vehicleScripts:size() - 1 do
        ---@type VehicleScript
        local vehicleScript = vehicleScripts:get(i)
        local name = vehicleScript:getName()
        local fullName = vehicleScript:getFullName()

        local addAirbag = not abs_blacklist[fullName]

        if addAirbag then
            if SandboxVars.workingSeatbelt.loreFriendlyAirbags then
                if not lore_blacklist[fullName] then
                    if not containsKeyword(name, keyword_blacklist) then
                        for _, template in ipairs(partTemplates) do
                            vehicleScript:Load(name, "{template=" .. template .. ",}")
                        end
                    end
                end
            else
                if not containsKeyword(name, keyword_blacklist) then
                    for _, template in ipairs(partTemplates) do
                        vehicleScript:Load(name, "{template=" .. template .. ",}")
                    end
                end
            end
        end
    end
end

Events.OnInitGlobalModData.Add(spawnAirbags)
