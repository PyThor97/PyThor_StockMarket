Config = {}

--[[
=====================================
--       PyThor_StockMarket GUIDE
--=====================================
This script intreduce in depth stock market system 
you can add more locations and change the rewards of each mission
by default the value of the stocks will change every day in the DB to change it you will need to change 
the SQL event provided in the shared folder more info there.

]]

-- =======================
--        Config
-- ========================
Config.DevMode = false

--If a player failed in a mission should the stock value decrease? 
Config.EnableDecreaseOnFail = true

Config.WebHooks = {

    Sell = '',
    Buy = '',
    Mission = ''

}

-- ========================
--        Job lock
-- ========================
-- Can anyone use the stock market or specific job
Config.JobLock = false

-- You can add or remove jobs. ONLY WORKS IF JobLock set to true
Config.JobsAllowed = {
    'banker',
    'trader'
}

-- ========================
--        General
-- ========================

-- stock Locations, you can add more
Config.Locations = {
    { -- Valentine
        Blip = true,
        BlipSprite = 'blip_robbery_bank',
        BlipName = 'Valentine Stock Market',
        coords = vector3(-306.02, 773.52, 118.7),
        NpcHeading = 320.12,
        ped = 'a_m_m_htlfancytravellers_01',
        distance = 2
    },
    { -- Rhodes
        Blip = true,
        BlipSprite = 'blip_robbery_bank',
        BlipName = 'Rhodes Stock Market',
        coords = vector3(1291.26, -1303.23, 77.04),
        NpcHeading = 319.5,
        ped = 'a_m_m_htlfancytravellers_01',
        distance = 2
    }
}
-- You can add or remove categories make sure to update DB as well
Config.Categories = {'Train', 'Oil', 'Spices', 'Gold'}

-- How much the player will pay for 1 share
Config.BuyPrice = 100

-- how much to profit per precent (Can't profit while the stock under 100%)
Config.ProfitPerPrecent = 10

-- ========================
--        Missions
-- ========================
Config.AdMinigameCFG = {
    focus = true,
    cursor = true,
    nails = 5,
    type = 'dark-wood'
}

Config.Advertising = {

    {coords = vector3(-182.72, 584.77, 113.42)},
    {coords = vector3(-191.61, 563.51, 113.79)},
    {coords = vector3(1381.95, -1403.74, 79.3)},
    {coords = vector3(1381.95, -1403.74, 79.3)}

}

-- Value for all Advertising missions or a set number
Config.AdValue = math.random(1, 5)

--Recruting mission
Config.RecMinigameCFG = {focus = true, cursor = true, allowretry = false}

Config.Recruting = {
    {
        coords = vector3(-240.88, 618.2, 113.36),
        heading = 265.57,
        ped = 'cs_crackpotinventor'
    }, {
        coords = vector3(-291.79, 682.76, 113.62),
        heading = 86.9,
        ped = 'cs_crackpotinventor'
    }, {
        coords = vector3(1431.59, -1392.85, 81.75),
        heading = 70.62,
        ped = 'cs_crackpotinventor'
    }, {
        coords = vector3(1427.53, -1279.08, 78.06),
        heading = 147.12,
        ped = 'cs_crackpotinventor'
    }
}

-- Value for all Recruting missions or a set number
Config.RecValue = math.random(1, 5)

--Info extraction
Config.InfoMinigameCFG = {
    focus = true, -- Should minigame take nui focus (required)
    cursor = false, -- Should minigame have cursor
    maxattempts = 3, -- How many fail attempts are allowed before game over
    type = 'bar', -- What should the bar look like. (bar, trailing)
    userandomkey = true, -- Should the minigame generate a random key to press?
    keytopress = 'G', -- userandomkey must be false for this to work. Static key to press
    keycode = 71, -- The JS keycode for the keytopress
    speed = 20, -- How fast the orbiter grows
    strict = true -- if true, letting the timer run out counts as a failed attempt
}

Config.infoExtracting = {
    {coords = vector3(1331.6, -1378.07, 80.51)},
    {coords = vector3(1331.6, -1378.07, 80.51)}
}
-- Value for all info Extracting missions or a set number
Config.InfoValue = math.random(1, 5)
