-- ===============================
--         IMPORT TOOLS
-- ===============================
local Core = exports.vorp_core:GetCore()
local FeatherMenu = exports['feather-menu'].initiate()
local BccUtils = exports['bcc-utils'].initiate()
local MiniGame = exports['bcc-minigames'].initiate()
local progressbar = exports.vorp_progressbar:initiate()

-- ===============================
--          PROMPTS
-- ===============================
local StockMenuPrompt = BccUtils.Prompts:SetupPromptGroup()
local Stockprompt = StockMenuPrompt:RegisterPrompt("Invest in stock",
    0x760A9C6F, 1, 1, true,
    'click')

local AdvertisingPromptGroup = BccUtils.Prompt:SetupPromptGroup()
local AdvertisingPrompt = AdvertisingPromptGroup:RegisterPrompt("Hang a poster",
    0x760A9C6F, 1,
    1, true, 'hold',
    {
        timedeventhash = "MEDIUM_TIMED_EVENT"
    })

local RecruitingPromptGroup = BccUtils.Prompt:SetupPromptGroup()
local RecrutingPrompt = RecruitingPromptGroup:RegisterPrompt(
    "Recruit this person", 0x760A9C6F, 1, 1, true,
    'hold', { timedeventhash = "MEDIUM_TIMED_EVENT" })

local InfoPromptGroup = BccUtils.Prompt:SetupPromptGroup()
local InfoPrompt = InfoPromptGroup:RegisterPrompt("Extract Info", 0x760A9C6F, 1,
    1, true, 'hold', {
        timedeventhash = "MEDIUM_TIMED_EVENT"
    })
-- ===============================
--          GLOBAL VARS
-- ===============================
local pedsCreated = {}
local blipsCreated = {}
local SellButtonClicked = ''
local sell_amount = nil
local mission_button_clicked = ''
local IsMissionActive = false
local HasJob = false

if Config.JobLock then
    HasJob = false
else
    HasJob = true
end
-- ===============================
--          DEV PRINT FUNC
-- ===============================
local function DevPrint(...) if Config.DevMode then print("[DEV MODE]", ...) end end

-- ===============================
--          Mission functions
-- ===============================

function Advertising_mission(stockName)
    stockName = mission_button_clicked

    DevPrint('advertising mission started for: ' .. stockName)

    if #Config.Advertising == 0 then
        DevPrint("[ERROR] No advertising missions configured.")
        return
    end

    Core.NotifyObjective('Open your map to locate the mission target.', 4000)

    local randomIndex = math.random(1, #Config.Advertising)
    local selectedMission = Config.Advertising[randomIndex]

    BccUtils.Misc.SetGps(selectedMission.coords.x, selectedMission.coords.y,
        selectedMission.coords.z)

    local mission_blip = BccUtils.Blips:SetBlip('Advertising Mission',
        'blip_wanted_poster', 0.2,
        selectedMission.coords.x,
        selectedMission.coords.y,
        selectedMission.coords.z)

    local blipMod = BccUtils.Blips:AddBlipModifier(mission_blip,
        'BLIP_MODIFIER_DEBUG_YELLOW')

    blipMod:ApplyModifier()

    function HangPosterCanFail()
        local playerPed = PlayerPedId()
        local animDict = "amb_work@world_human_hammer@wall@male_a@stand_exit"
        local animName = "exit_front"

        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do Citizen.Wait(100) end

        MiniGame.Start('skillcheck', Config.InfoMinigameCFG, function(result)
            DevPrint(result.result)
            if result.passed then
                TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, 5000, 0, 0, false, false, false)
                TriggerServerEvent('stocks:IncreaseStockValue', mission_button_clicked, 'AD')
            elseif not result.passed then
                Core.NotifyObjective('You hit your finger, mission failed', 5000)
                TriggerServerEvent('stocks:DecreaseStockValue', mission_button_clicked, 'AD')
            end
        end)
        mission_blip:Remove()
    end

    function HangPoster()
        local playerPed = PlayerPedId()
        local animDict = "amb_work@world_human_hammer@wall@male_a@stand_exit"
        local animName = "exit_front"

        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do Citizen.Wait(100) end

        MiniGame.Start('hammertime', Config.AdMinigameCFG, function(result)
            DevPrint(result.result)
            TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, 5000, 0,
                0, false, false, false)
            TriggerServerEvent('stocks:IncreaseStockValue',
                mission_button_clicked, 'AD')
        end)
        mission_blip:Remove()
    end

    while IsMissionActive do
        Citizen.Wait(1)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local targetCoords = vector3(selectedMission.coords.x,
            selectedMission.coords.y,
            selectedMission.coords.z)

        if #(playerCoords - targetCoords) < 1.0 then
            BccUtils.Misc.RemoveGps()
            AdvertisingPromptGroup:ShowGroup("Hang a poster")
            AdvertisingPrompt:TogglePrompt(true)
            if AdvertisingPrompt:HasCompleted() then
                if Config.EnableDecreaseOnFail then
                    AdvertisingPrompt:TogglePrompt(false)
                    HangPosterCanFail()
                    IsMissionActive = false
                else
                    AdvertisingPrompt:TogglePrompt(false)
                    HangPoster()
                    IsMissionActive = false
                end
            end
        end
    end
end

function Recruit_misssion(stockName)
    stockName = mission_button_clicked
    DevPrint('Recruit misssion started for: ' .. stockName)

    Core.NotifyObjective('Open your map to locate the mission target.', 4000)

    local randomIndex = math.random(1, #Config.Recruting)
    local selectedMission = Config.Recruting[randomIndex]

    BccUtils.Misc.SetGps(selectedMission.coords.x, selectedMission.coords.y,
        selectedMission.coords.z)

    local mission_blip = BccUtils.Blips:SetBlip('Recruit Mission',
        'blip_gunslinger', 0.2,
        selectedMission.coords.x,
        selectedMission.coords.y,
        selectedMission.coords.z)

    local blipMod = BccUtils.Blips:AddBlipModifier(mission_blip,
        'BLIP_MODIFIER_DEBUG_YELLOW')

    blipMod:ApplyModifier()

    local recruit_ped = BccUtils.Ped:Create('u_f_m_tumgeneralstoreowner_01',
        selectedMission.coords.x,
        selectedMission.coords.y,
        selectedMission.coords.z - 1, 0,
        'world', false)
    recruit_ped:Invincible()
    recruit_ped:Freeze()
    recruit_ped:CanBeDamaged()
    recruit_ped:SetHeading(selectedMission.heading)

    function Recruit_person()
        local playerPed = PlayerPedId()
        local animDict = "ai_gestures@gen_female@standing@silent@script"
        local animName = "silent_dirty_hands_l_001"

        MiniGame.Start('rps', Config.RecMinigameCFG, function(result)
            TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, 5000, 0, 0,
                false, false, false)
            if result.result == 'win' or result.result == 'tie' then
                DevPrint(result.result)
                TriggerServerEvent('stocks:IncreaseStockValue',
                    mission_button_clicked, 'Recruit')
            else
                if Config.EnableDecreaseOnFail then
                    DevPrint(result.result)
                    Core.NotifyObjective('This person do not want to join you cause...', 5000)
                    TriggerServerEvent('stocks:DecreaseStockValue', mission_button_clicked, 'Recruit')
                    IsMissionActive = false
                else
                    DevPrint(result.result)
                    Core.NotifyObjective('This person do not want to join you cause...', 5000)
                    IsMissionActive = false
                end
            end
        end)

        Wait(5000)
        mission_blip:Remove()
        recruit_ped:Remove()
    end

    while IsMissionActive do
        Citizen.Wait(1)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local targetCoords = vector3(selectedMission.coords.x,
            selectedMission.coords.y,
            selectedMission.coords.z)

        if #(playerCoords - targetCoords) < 2.0 then
            BccUtils.Misc.RemoveGps()
            RecruitingPromptGroup:ShowGroup("Recruit")
            RecrutingPrompt:TogglePrompt(true)
            if RecrutingPrompt:HasCompleted() then
                RecrutingPrompt:TogglePrompt(false)
                Recruit_person()
                IsMissionActive = false
            end
        end
    end
end

function Info_mission(stockName)
    stockName = mission_button_clicked

    DevPrint('Info extraction misssion started for: ' .. stockName)

    Core.NotifyObjective('Open your map to locate the mission target.', 4000)

    local randomIndex = math.random(1, #Config.infoExtracting)
    local selectedMission = Config.infoExtracting[randomIndex]

    BccUtils.Misc.SetGps(selectedMission.coords.x, selectedMission.coords.y,
        selectedMission.coords.z)

    local mission_blip = BccUtils.Blips:SetBlip('Info extraction Mission',
        'blip_radius_search', 0.3,
        selectedMission.coords.x,
        selectedMission.coords.y,
        selectedMission.coords.z)

    local blipMod = BccUtils.Blips:AddBlipModifier(mission_blip,
        'BLIP_MODIFIER_DEBUG_YELLOW')

    blipMod:ApplyModifier()

    function ExtractInfo()
        local playerPed = PlayerPedId()
        local scenario_name = 'WORLD_HUMAN_WRITE_NOTEBOOK'

        MiniGame.Start('skillcheck', Config.InfoMinigameCFG, function(result)
            DevPrint("Passed?", result.passed)
            if result.passed then
                TaskStartScenarioInPlace(playerPed, scenario_name, 5, true)
                TriggerServerEvent('stocks:IncreaseStockValue',
                    mission_button_clicked, 'Info')
                mission_blip:Remove()
                IsMissionActive = false
            else
                if Config.EnableDecreaseOnFail then
                    Core.NotifyObjective(
                        'Those are fake documents... better luck next time', 4000)
                    TriggerServerEvent('stocks:DecreaseStockValue', mission_button_clicked, 'Info')
                    mission_blip:Remove()
                    IsMissionActive = false
                else
                    Core.NotifyObjective(
                        'Those are fake documents... better luck next time', 4000)
                    mission_blip:Remove()
                    IsMissionActive = false
                end
            end
        end)
    end

    while IsMissionActive do
        Citizen.Wait(1)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local targetCoords = vector3(selectedMission.coords.x,
            selectedMission.coords.y,
            selectedMission.coords.z)

        if #(playerCoords - targetCoords) < 2.0 then
            BccUtils.Misc.RemoveGps()
            InfoPromptGroup:ShowGroup("Stock market mission")
            InfoPrompt:TogglePrompt(true)
            if InfoPrompt:HasCompleted() then
                InfoPrompt:TogglePrompt(false)
                ExtractInfo()
                IsMissionActive = false
            end
        end
    end
end

-- ===============================
--          CREATE PEDS
-- ===============================
function CreatePeds()
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
end

CreatePeds()
-- ===============================
--          CREATE BLIPS
-- ===============================

function CreateBlips()
    for _, v in pairs(Config.Locations) do
        local blip = BccUtils.Blips:SetBlip('Stock Market', v.BlipSprite, 3.2,
            v.coords.x, v.coords.y, v.coords.z)
        blipsCreated[#blipsCreated + 1] = blip
    end
end

CreateBlips()

-- ===============================
--          MAIN MENU
-- ===============================
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

    -- ===============================
    --          STOCK INFO
    -- ===============================
    local StockInfoPage = StockMenu:RegisterPage('info:page')

    StockInfoPage:RegisterElement('header', {
        value = 'Stock info',
        slot = "header",
        style = {}
    })

    StockInfoPage:RegisterElement('textdisplay', {
        value = 'Note: stocks cannot reach more than 200% !',
        style = { fontSize = '20px' }
    })

    StockInfoPage:RegisterElement('button', {
        label = "Return",
        style = {},
        slot = 'footer',
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function() StockMenuFirstPage:RouteTo() end)

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
            style = { color = textColor },
            sound = {
                action = "SELECT",
                soundset = "RDRO_Character_Creator_Sounds"
            }
        }, function() end)
    end

    StockMenuFirstPage:RegisterElement('button', {
        label = "Check stocks info",
        style = {},
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function() StockInfoPage:RouteTo() end)

    -- ===============================
    --          BUY PAGE
    -- ===============================

    local buypage = StockMenu:RegisterPage('Buy:page')

    buypage:RegisterElement('header',
        { value = 'Buy shares', slot = "header", style = {} })

    buypage:RegisterElement('button', {
        label = "Return",
        style = {},
        slot = 'footer',
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function() StockMenuFirstPage:RouteTo() end)

    local amountPage = StockMenu:RegisterPage('amount:page')

    amountPage:RegisterElement('header', {
        value = 'how much?',
        slot = 'header',
        style = {}
    })
    local amount_to_buy = nil
    local price = amountPage:RegisterElement('textdisplay', {
        slot = 'footer',
        value = nil,
        style = { color = 'red', fontSize = '20px' }
    })

    amountPage:RegisterElement('slider', {
        label = "Amount to buy",
        start = 0,
        min = 0,
        max = 100,
        persist = false,
        steps = 1
    }, function(data)
        amount_to_buy = data.value
        price:update({
            value = 'Cost: ' .. amount_to_buy * Config.BuyPrice .. '$'
        })
    end)

    amountPage:RegisterElement('button', {
        label = "Return",
        style = {},
        slot = 'footer',
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function() buypage:RouteTo() end)

    amountPage:RegisterElement('button', {
        label = "Confirm",
        style = {},
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function()
        if not amount_to_buy or amount_to_buy <= 0 then
            Core.NotifyObjective("title", 4000)
            return
        end

        if not ButtonClicked or ButtonClicked == '' then
            Core.NotifyObjective("title", 4000)
            return
        end

        -- שליחת שם המניה וכמות לשרת
        TriggerServerEvent('stocks:BuyShares', ButtonClicked, amount_to_buy)

        -- קבלת תגובה מהשרת
        RegisterNetEvent('stocks:BuyResult')
        AddEventHandler('stocks:BuyResult', function(success, message)
            if success then
                DevPrint(message)
                Core.NotifyObjective(message, 4000)
            else
                DevPrint(message)
                Core.NotifyObjective(message, 4000)
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
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function() buypage:RouteTo() end)

    -- ===============================
    --          SELL PAGE
    -- ===============================

    local sell_stock_page = StockMenu:RegisterPage('sell:page')
    local sell_stock_amount = StockMenu:RegisterPage('sell_amount:page')

    sell_stock_page:RegisterElement('button', {
        label = "Return",
        style = {},
        slot = 'footer',
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function() StockMenuFirstPage:RouteTo() end)

    sell_stock_amount:RegisterElement('header', {
        value = 'How much to sell?',
        slot = "header",
        style = {}
    })

    local player_shares_amount = sell_stock_amount:RegisterElement('button', {
        label = '',
        style = {}
    }, function() end)

    sell_stock_amount:RegisterElement('button', {
        label = "Return",
        style = {},
        slot = 'footer',
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function() sell_stock_page:RouteTo() end)

    sell_stock_amount:RegisterElement('slider', {
        label = "Amount to sell",
        start = 1,
        min = 0,
        max = 100,
        steps = 1
    }, function(data)
        sell_amount = data.value
        DevPrint('Sell amount = ' .. sell_amount)
    end)

    sell_stock_amount:RegisterElement('button', {
        label = "Confirm",
        style = {},
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function()
        if sell_amount and SellButtonClicked then
            TriggerServerEvent('stocks:SellShares', SellButtonClicked,
                sell_amount)

            RegisterNetEvent('stocks:SellResult')
            AddEventHandler('stocks:SellResult', function(success, message)
                if success then
                    Core.NotifyObjective(message, 4000)
                else
                    Core.NotifyObjective(message, 4000)
                end
            end)
        else
            TriggerEvent("vorp:TipBottom",
                "Please select a valid amount and stock.", 4000)
        end
    end)

    sell_stock_page:RegisterElement('header', {
        value = 'Sell Stocks',
        slot = "header",
        style = {}
    })

    for _, v in ipairs(Config.Categories) do
        sell_stock_page:RegisterElement('button', {
            label = 'Sell ' .. v .. ' shares',
            style = {},
            id = v,
            sound = {
                action = "SELECT",
                soundset = "RDRO_Character_Creator_Sounds"
            }
        }, function(data)
            SellButtonClicked = data.id
            DevPrint('sell button clicked = ' .. SellButtonClicked)
            TriggerServerEvent('stocks:GetPlayerShares', SellButtonClicked)
            RegisterNetEvent('stocks:ReturnPlayerShares')
            AddEventHandler('stocks:ReturnPlayerShares', function(shares)
                if shares then
                    DevPrint('shares owned: ' .. shares)
                    local PlayerShares = shares
                    player_shares_amount:update({
                        label = 'Your ' .. SellButtonClicked .. ' shares: ' ..
                            PlayerShares
                    })
                else
                    print("You have no shares in " .. SellButtonClicked)
                end
            end)
            sell_stock_amount:RouteTo()
        end)
    end

    StockMenuFirstPage:RegisterElement('button', {
        label = "Sell stocks",
        style = {},
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function() sell_stock_page:RouteTo() end)
    -- ===============================
    --          LEADERBOARD
    -- ===============================
    local leaderBoard = StockMenu:RegisterPage('leaderboard:page')
    leaderBoard:RegisterElement('header', {
        value = 'Leaderboard',
        slot = "header",
        style = {}
    })
    leaderBoard:RegisterElement('button', {
        label = "Return",
        style = {},
        slot = 'footer',
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function() StockMenuFirstPage:RouteTo() end)

    for _, category in ipairs(Config.Categories) do
        TriggerServerEvent('stocks:getTopContributer', category)
        RegisterNetEvent('stocks:returnTopContributer',
            function(receivedCategory, message)
                if receivedCategory == category then
                    local contribution = leaderBoard:RegisterElement('textdisplay', {
                        value = category .. ': ' .. message,
                        style = { color = 'gold', fontSize = '24px' },
                        id = category,
                    })
                end
            end)
    end

    StockMenuFirstPage:RegisterElement('button', {
        label = "Leaderboard",
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function() leaderBoard:RouteTo() end)
    -- ===============================
    --          MISSIONS
    -- ===============================
    local mission_page = StockMenu:RegisterPage('mission:page')
    local mission_type_select = StockMenu:RegisterPage('mission_type:page')

    mission_page:RegisterElement('button', {
        label = "Return",
        style = {},
        slot = 'footer',
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function() StockMenuFirstPage:RouteTo() end)

    mission_type_select:RegisterElement('button', {
        label = "Return",
        style = {},
        slot = 'footer',
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function() mission_page:RouteTo() end)

    mission_page:RegisterElement('header', {
        value = 'Choose a stock to work for',
        slot = "header"
    })

    mission_type_select:RegisterElement('header', {
        value = 'What type of mission?',
        slot = 'header'
    })

    mission_type_select:RegisterElement('button', {
        label = "Start advertising mission",
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function()
        if not IsMissionActive then
            IsMissionActive = true
            DevPrint('mission status: ' .. tostring(IsMissionActive))
            Advertising_mission(mission_button_clicked)
        else
            Core.NotifyObjective('Mission already active', 4000)
        end
    end)

    mission_type_select:RegisterElement('button', {
        label = "Start recruiting mission",
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function()
        if not IsMissionActive then
            IsMissionActive = true
            DevPrint('mission status: ' .. tostring(IsMissionActive))
            Recruit_misssion(mission_button_clicked)
        else
            Core.NotifyObjective('Mission already active', 4000)
        end
    end)

    mission_type_select:RegisterElement('button', {
        label = "Start Info extraction mission",
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function()
        if not IsMissionActive then
            IsMissionActive = true
            DevPrint('mission status: ' .. tostring(IsMissionActive))
            Info_mission(mission_button_clicked)
        else
            Core.NotifyObjective('Mission already active', 4000)
        end
    end)

    for index, v in ipairs(Config.Categories) do
        mission_page:RegisterElement('button', {
            label = v,
            style = {},
            sound = {
                action = "SELECT",
                soundset = "RDRO_Character_Creator_Sounds"
            },
            id = v
        }, function(data)
            mission_button_clicked = data.id
            mission_type_select:RouteTo()
        end)
    end

    StockMenuFirstPage:RegisterElement('button', {
        label = "Missions",
        style = {},
        sound = { action = "SELECT", soundset = "RDRO_Character_Creator_Sounds" }
    }, function() mission_page:RouteTo() end)
end)

-- ========================
--      OPEN MENU
-- ========================
Citizen.CreateThread(function()
    TriggerServerEvent('stocks:checkPlayerJob')
    RegisterNetEvent("client:receiveJobCheck", function(isJobValid)
        if isJobValid then
            DevPrint("The player has the valid job!")
            HasJob = true
        else
            DevPrint("The player does not have the valid job.")
            HasJob = false
        end
    end)

    local menuIsOpen = false

    while true and not menuIsOpen do
        Wait(1)
        local playerCoords = GetEntityCoords(PlayerPedId())
        for _, v in pairs(Config.Locations) do
            local dist = #(playerCoords - v.coords)
            if dist < 2 then
                StockMenuPrompt:ShowGroup('Press G')
                if Stockprompt:HasCompleted() then
                    if HasJob then
                        StockMenu:Open({ startupPage = StockMenuFirstPage })
                        menuIsOpen = true
                        DevPrint('Menu is open')
                    else
                        Core.NotifyObjective("You don't have the right job!",
                            4000)
                    end
                end
            end
            menuIsOpen = false
        end
    end
end)

-- clear peds and blip on restart
AddEventHandler('onResourceStop', function(resourceName)
    for _, npcs in ipairs(pedsCreated) do npcs:Remove() end
    for _, blips in ipairs(blipsCreated) do blips:Remove() end
    IsMissionActive = false
    DevPrint('Removed NPC and blips')
end)
