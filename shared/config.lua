Config = {}

Config.DevMode = true

Config.Settings = {randomValues = true, minValue = -200, maxValue = 200}

-- stock Locations
Config.Locations = {
    valentine = {
        Blip = true,
        BlipSprite = 'blip_robbery_bank',
        BlipName = 'Valentine Stock Market',
        coords = vector3(-306.02, 773.52, 118.7),
        ped = 's_m_m_bankclerk_01',
        distance = 2,
        categories = {'Trains', 'Oil'}
    },
    rhodes = {
        Blip = true,
        BlipSprite = 'blip_robbery_bank',
        BlipName = 'Rhodes Stock Market',
        coords = vector3(1291.26, -1303.23, 77.04),
        ped = 's_m_m_bankclerk_01',
        distance = 2,
        categories = {'Trains', 'Oil'}
    }
}

-- missions
Config.advertising = {
    valentine = {
        {coords = vector3(-182.72, 584.77, 113.42), reward = 5},
        {coords = vector3(-191.61, 563.51, 113.79), reward = 5}
    },
    rhodes = {
        {coords = vector3(1381.95, -1403.74, 79.3), reward = 5},
        {coords = vector3(1381.95, -1403.74, 79.3), reward = 5}
    }
}

Config.Recruting = {
    valentine = {
        {
            coords = vector4(-240.88, 618.2, 113.36, 265.57),
            ped = 'cs_crackpotinventor',
            reward = 5
        }, {
            coords = vector4(-291.79, 682.76, 113.62, 86.9),
            ped = 'cs_crackpotinventor',
            reward = 5
        }
    },
    rhodes = {
        {
            coords = vector4(1431.59, -1392.85, 81.75, 70.62),
            ped = 'cs_crackpotinventor',
            reward = 5
        }, {
            coords = vector4(1427.53, -1279.08, 78.06, 147.12),
            ped = 'cs_crackpotinventor',
            reward = 5
        }
    }
}

Config.infoExtracting = {
    valentine = {},
    rhodes = {
        {coords = vector3(1331.64, -1378.09, 80.51), reward = 5},
        {coords = vector3(1399.2, -1285.79, 78.17), reward = 5}
    }
}
