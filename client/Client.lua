-- impport all tools
local Core = exports.vorp_core:GetCore()
local Animations = exports.vorp_animations.initiate()
local FeatherMenu = exports['feather-menu'].initiate()
local BccUtils = exports['bcc-utils'].initiate()

-- global vars
local StockMenuPrompt = BccUtils.Prompts:SetupPromptGroup()
local Stockprompt = StockMenuPrompt:RegisterPrompt("Invest in stock",
                                                   0x760A9C6F, 1, 1, true,
                                                   'click')
local pedsCreated = {}
local blipsCreated = {}

-- devprint function
local function DevPrint(...) if Config.DevMode then print("[DEV MODE]", ...) end end

-- create peds
Citizen.CreateThread(function()
    for _, value in ipairs(Config.Locations) do
        local StockPed = BccUtils.Ped:Create(value.ped, value.coords.x,
                                             value.coords.y, value.coords.z - 1,
                                             0, 'world', false)
        pedsCreated[#pedsCreated + 1] = StockPed
        StockPed:SetHeading(value.NpcHeading)
        StockPed:Freeze()
        StockPed:Invincible()
    end
    DevPrint('Peds created')
end)

-- Create blips
Citizen.CreateThread(function()
    for _, v in pairs(Config.Locations) do
        local blip = BccUtils.Blips:SetBlip('Stock Market', v.BlipSprite, 3.2,
                                            v.coords.x, v.coords.y, v.coords.z)
        blipsCreated[#blipsCreated + 1] = blip
    end
end)

-- Create the menu
Citizen.CreateThread(function()
    StockMenu = FeatherMenu:RegisterMenu('Stock:main', {
        top = '40%',
        left = '20%',
        ['720width'] = '500px',
        ['1080width'] = '600px',
        ['2kwidth'] = '700px',
        ['4kwidth'] = '900px',
        style = {},
        contentslot = {
            style = { -- This style is what is currently making the content slot scoped and scrollable. If you delete this, it will make the content height dynamic to its inner content.
                ['height'] = '600px',
                ['min-height'] = '300px'
            }
        },
        draggable = true
    })

    StockMenuFirstPage = StockMenu:RegisterPage('first:page')

    StockMenuFirstPage:RegisterElement('header', {
        value = 'Stock Broker',
        slot = "header",
        style = {}
    })

    local StockInfoPage = StockMenu:RegisterPage('info:page')

    StockInfoPage:RegisterElement('header', {
        value = 'Stock info',
        slot = "header",
        style = {}
    })

    StockInfoPage:RegisterElement('textdisplay',{value = '', style = {fontSize = '20px'}})

    for index, category in ipairs(Config.Categories) do
        local cat = category
        StockMenuFirstPage:RegisterElement('button', {
            label = '',
            style = {},
            sound = {action = "SELECT", soundset = "RDRO_Character_Creator_Sounds"}
        }, 
        function()
             StockInfoPage:RouteTo() 
        end)
    end

    StockMenuFirstPage:RegisterElement('button', {
        label = "Check your stock shares",
        style = {},
        sound = {action = "SELECT", soundset = "RDRO_Character_Creator_Sounds"}
    }, 
    function()
         StockInfoPage:RouteTo() 
    end)

    StockMenuFirstPage:RegisterElement('button', {
        label = "Buy Stock",
        style = {},
        sound = {action = "SELECT", soundset = "RDRO_Character_Creator_Sounds"}
    }, function()
        -- This gets triggered whenever the button is clicked
    end)

    StockMenuFirstPage:RegisterElement('button', {
        label = "Sell Stock",
        style = {},
        sound = {action = "SELECT", soundset = "RDRO_Character_Creator_Sounds"}
    }, function()
        -- This gets triggered whenever the button is clicked
    end)

    StockMenuFirstPage:RegisterElement('button', {
        label = "Missions",
        style = {},
        sound = {action = "SELECT", soundset = "RDRO_Character_Creator_Sounds"}
    }, function()
        -- This gets triggered whenever the button is clicked
    end)
end)

-- open menu
Citizen.CreateThread(function()
    while true do
        Wait(1)
        local playerCoords = GetEntityCoords(PlayerPedId())
        for _, v in pairs(Config.Locations) do
            local dist = #(playerCoords - v.coords)
            if dist < 2 then
                StockMenuPrompt:ShowGroup('Press G')
                if Stockprompt:HasCompleted() then
                    StockMenu:Open({startupPage = StockMenuFirstPage})
                end
            end
        end
    end
end)

-- clear peds and blip on restart
AddEventHandler('onResourceStop', function(resourceName)
    for _, npcs in ipairs(pedsCreated) do npcs:Remove() end
    for _, blips in ipairs(blipsCreated) do blips:Remove() end
end)
