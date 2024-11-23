Config = {}

Config.DevMode = true

Config.Settings = {randomValues = true, minValue = -50, maxValue = 200}

Config.DBupdateInterval = {intervalDays = 7, resetPlayerInfluence = true}

-- stock Locations
Config.Locations = {
    {
        Blip = true,
        BlipSprite = 'blip_robbery_bank',
        BlipName = 'Valentine Stock Market',
        coords = vector3(-306.02, 773.52, 118.7),
        NpcHeading = 320.12,
        ped = 's_m_m_bankclerk_01',
        distance = 2
    }, -- Rhodes
    {
        Blip = true,
        BlipSprite = 'blip_robbery_bank',
        BlipName = 'Rhodes Stock Market',
        coords = vector3(1291.26, -1303.23, 77.04),
        NpcHeading = 319.5,
        ped = 's_m_m_bankclerk_01',
        distance = 2
    }
}

Config.Categories = {'Trains', 'Oil'}

-- missions
Config.advertising = {

    {coords = vector3(-182.72, 584.77, 113.42), reward = math.random(1, 5)},
    {coords = vector3(-191.61, 563.51, 113.79), reward = math.random(1, 5)},
    {coords = vector3(1381.95, -1403.74, 79.3), reward = math.random(1, 5)},
    {coords = vector3(1381.95, -1403.74, 79.3), reward = math.random(1, 5)}

}

Config.Recruting = {
    {
        coords = vector4(-240.88, 618.2, 113.36, 265.57),
        ped = 'cs_crackpotinventor',
        reward = math.random(1, 5)
    }, {
        coords = vector4(-291.79, 682.76, 113.62, 86.9),
        ped = 'cs_crackpotinventor',
        reward = math.random(1, 5)
    }, {
        coords = vector4(1431.59, -1392.85, 81.75, 70.62),
        ped = 'cs_crackpotinventor',
        reward = math.random(1, 5)
    }, {
        coords = vector4(1427.53, -1279.08, 78.06, 147.12),
        ped = 'cs_crackpotinventor',
        reward = math.random(1, 5)
    }
}

Config.infoExtracting = {
    {coords = vector3(1331.64, -1378.09, 80.51), reward = math.random(1, 5)},
    {coords = vector3(1399.2, -1285.79, 78.17), reward = math.random(1, 5)}
}
