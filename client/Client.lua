-- impport all tools
local Core = exports.vorp_core:GetCore()
local Animations = exports.vorp_animations.initiate()
local FeatherMenu = exports['feather-menu'].initiate()
local BccUtils = exports['bcc-utils'].initiate()
local progressbar = exports.vorp_progressbar:initiate()

-- global vars
local StockMenuPrompt = BccUtils.Prompts:SetupPromptGroup()
local Stockprompt = StockMenuPrompt:RegisterPrompt("Invest in stock",
                                                   0x760A9C6F, 1, 1, true,
                                                   'click')
local pedsCreated = {}
local blipsCreated = {}
local stock_to_buy = ''

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

    StockInfoPage:RegisterElement('textdisplay', {
        value = 'Note: stocks cannot reach more than 200% !',
        style = {fontSize = '20px'}
    })

    for index, category in ipairs(Config.Categories) do
        local stockValue = nil
        local waiting = true
        local cat = category
        TriggerServerEvent('stocks:GetValue', cat)

        RegisterNetEvent('stocks:ReturnValue')
        AddEventHandler('stocks:ReturnValue', function(value)
            stockValue = value
            waiting = false
        end)
        while waiting do Citizen.Wait(100) end

        local textColor = (tonumber(stockValue) >= 100) and "green" or "red"

        StockInfoPage:RegisterElement('button', {
            label = cat .. ": " .. tostring(stockValue) .. '%',
            style = {color = textColor}, -- הגדרת הצבע
            sound = {
                action = "SELECT",
                soundset = "RDRO_Character_Creator_Sounds"
            }
        }, function() end)
    end

    StockMenuFirstPage:RegisterElement('button', {
        label = "Check your stock shares",
        style = {},
        sound = {action = "SELECT", soundset = "RDRO_Character_Creator_Sounds"}
    }, function() StockInfoPage:RouteTo() end)

    local buypage = StockMenu:RegisterPage('Buy:page')

    buypage:RegisterElement('header',
                            {value = 'Buy shares', slot = "header", style = {}})

    local amountPage = StockMenu:RegisterPage('amount:page')

    amountPage:RegisterElement('header', {
        value = 'how much?',
        slot = 'header',
        style = {}
    })
    local amount = nil
    local price = amountPage:RegisterElement('textdisplay', {
        slot = 'footer',
        value = nil,
        style = {color = 'red', fontSize = '20px'}
    })

    amountPage:RegisterElement('slider', {
        label = "Amount to buy",
        start = 1,
        min = 0,
        max = 100,
        steps = 1
    }, function(data)
        amount = data.value
        price:update({
            value = amount * Config.Price .. '$',
            style = {fontSize = '20px'}
        })
    end)

    amountPage:RegisterElement('button', {
        label = "Confirm",
        style = {},
        sound = {action = "SELECT", soundset = "RDRO_Character_Creator_Sounds"}
    }, function()
        if amount and ButtonClicked then
            DevPrint(
                'Sending amount and category: ' .. tostring(amount) .. ', ' ..
                    tostring(ButtonClicked))
            TriggerServerEvent('stocks:buyShares', ButtonClicked, amount)
        else
            DevPrint('Amount or ButtonClicked is nil')
            TriggerEvent('chat:addMessage', {
                args = {
                    "^1[Error]:^0 Please select a valid amount and category."
                }
            })
        end

        RegisterNetEvent('stocks:TransactionResult')
        AddEventHandler('stocks:TransactionResult', function(success, message)
            if success then
                -- הודעה על הצלחה
                TriggerEvent('chat:addMessage',
                             {args = {"^2[Success]:^0 " .. message}})
            else
                -- הודעה על כישלון
                TriggerEvent('chat:addMessage',
                             {args = {"^1[Error]:^0 " .. message}})
            end
        end)
    end)

    for _, v in ipairs(Config.Categories) do
        buypage:RegisterElement('button', {
            label = v,
            style = {},
            id = v,
            sound = {
                action = "SELECT",
                soundset = "RDRO_Character_Creator_Sounds"
            }
        }, function(data)
            ButtonClicked = data.id
            amountPage:RouteTo()
        end)
    end

    StockMenuFirstPage:RegisterElement('button', {
        label = "Buy Stock",
        style = {},
        sound = {action = "SELECT", soundset = "RDRO_Character_Creator_Sounds"}
    }, function() buypage:RouteTo() end)

    local sell_stock_page = StockMenu:RegisterPage('sell:page')

    sell_stock_page:RegisterElement('header', {
        value = 'Sell Stocks',
        slot = "header",
        style = {}
    })

    StockMenuFirstPage:RegisterElement('button', {
        label = "Sell Stock",
        style = {},
        sound = {action = "SELECT", soundset = "RDRO_Character_Creator_Sounds"}
    }, function()
        sell_stock_page:RouteTo()
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
