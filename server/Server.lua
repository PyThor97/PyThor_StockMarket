local Core = exports.vorp_core:GetCore()
local BccUtils = exports['bcc-utils'].initiate()

local function ConsolePrint(...)
    if Config.DevMode then print("[DEV MODE]", ...) end
end

local function versionCheckPrint(_type, log)
    local color = _type == 'success' and '^2' or '^1'

    print(('^5['..GetCurrentResourceName()..']%s %s^7'):format(color, log))
end

local function CheckVersion()
    PerformHttpRequest('https://raw.githubusercontent.com/PyThor97/PyThor_StockMarket/refs/heads/main/version.file', function(err, text, headers)
        local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')

        if not text then 
            versionCheckPrint('error', 'Currently unable to run a version check.')
            return 
        end

      
        if text == currentVersion then
            versionCheckPrint('success', 'You are running the latest version.')
        else
            versionCheckPrint('error', ('Current Version: %s'):format(currentVersion))
            versionCheckPrint('success', ('Latest Version: %s'):format(text))
            versionCheckPrint('error', ('You are currently running an outdated version, please update to version %s'):format(text))
        end
    end)
end

-- ===============================
--          DEV PRINT
-- ===============================
RegisterNetEvent('stocks:GetValue', function(stockName)
    local src = source
    print("Received stock name: " .. stockName)
    local stockValue = MySQL.scalar.await(
                           'SELECT `stock_value` FROM `pythor_stocks` WHERE `stock_name` = ?',
                           {stockName})

    if stockValue then
        ConsolePrint("Stock value for " .. stockName .. ": " .. stockValue)
        TriggerClientEvent('stocks:ReturnValue', src, stockValue)
    else
        ConsolePrint("No stock found for: " .. stockName)
        TriggerClientEvent('stocks:ReturnValue', src, "No stock found")
    end
end)

-- ===============================
--          BUY SHARES
-- ===============================
RegisterNetEvent('stocks:BuyShares')
AddEventHandler('stocks:BuyShares', function(stockName, quantity)
    local src = source
    local user = Core.getUser(src)
    if not user then
        TriggerClientEvent('stocks:BuyResult', src, false, "User not found.")
        return
    end

    local character = user.getUsedCharacter
    if not character then
        TriggerClientEvent('stocks:BuyResult', src, false,
                           "Character not found.")
        return
    end

    local playerIdentifier = character.identifier
    local playerMoney = character.money

    -- שליפת הערך הנוכחי של המניה
    local stockValue = MySQL.scalar.await(
                           'SELECT stock_value FROM pythor_stocks WHERE stock_name = ?',
                           {stockName})
    if not stockValue then
        TriggerClientEvent('stocks:BuyResult', src, false, "Stock not found.")
        return
    end

    local totalPrice = Config.BuyPrice * quantity
    if playerMoney < totalPrice then
        TriggerClientEvent('stocks:BuyResult', src, false, "Not enough money.")
        return
    end

    character.removeCurrency(0, totalPrice)

    MySQL.update.await([[
    INSERT INTO player_stocks (player_identifier, character_name, stock_name, shares)
    VALUES (?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE shares = shares + VALUES(shares)
    ]], {
        playerIdentifier, character.firstname .. " " .. character.lastname,
        stockName, quantity
    })

    TriggerClientEvent('stocks:BuyResult', src, true,
                       "Bought " .. quantity .. " shares of " .. stockName)

    BccUtils.Discord.sendMessage(Config.WebHooks.Buy, 'PyThor_StockMarket',
                                 'https://cdn2.iconfinder.com/data/icons/frosted-glass/256/Danger.png',
                                 character.firstname .. " " ..
                                     character.lastname .. ' has bought ' ..
                                     quantity .. ' in: ' .. stockName ..
                                     ' for: ' .. totalPrice .. '$')

end)

-- ==========================
---     Get players shares
-- ==========================
RegisterNetEvent('stocks:GetPlayerStocks')
AddEventHandler('stocks:GetPlayerStocks', function()
    local src = source
    local user = Core.getUser(src)

    if not user then
        TriggerClientEvent('stocks:ReturnPlayerStocks', src, {})
        return
    end

    local character = user.getUsedCharacter
    local playerIdentifier = character.identifier

    -- שליפת כל המניות של השחקן
    local playerStocks = MySQL.query.await(
                             'SELECT stock_name, shares FROM player_stocks WHERE player_identifier = ?',
                             {playerIdentifier})

    TriggerClientEvent('stocks:ReturnPlayerStocks', src, playerStocks)
end)

-- ====================================
--      GET PLAYER SHARES COUNT
-- ====================================
RegisterNetEvent('stocks:GetPlayerShares')
AddEventHandler('stocks:GetPlayerShares', function(stockName)
    local src = source
    local user = Core.getUser(src)
    local character = user.getUsedCharacter
    local playerIdentifier = character.identifier

    local shares = MySQL.scalar.await(
                       'SELECT `shares` FROM `player_stocks` WHERE `player_identifier` = ? AND `stock_name` = ?',
                       {playerIdentifier, stockName})

    if shares then
        TriggerClientEvent('stocks:ReturnPlayerShares', src, shares)
    else
        TriggerClientEvent('stocks:ReturnPlayerShares', src, 0)
    end
end)

-- ====================================
--        SELL PLAYER SHARES
-- ====================================
RegisterNetEvent('stocks:SellShares')
AddEventHandler('stocks:SellShares', function(stockName, quantity)
    local src = source
    local user = Core.getUser(src)
    if not user then
        TriggerClientEvent('stocks:SellResult', src, false, "User not found.")
        return
    end

    local character = user.getUsedCharacter
    if not character then
        TriggerClientEvent('stocks:SellResult', src, false,
                           "Character not found.")
        return
    end

    local playerIdentifier = character.identifier

    local stockValue = MySQL.scalar.await(
                           'SELECT stock_value FROM pythor_stocks WHERE stock_name = ?',
                           {stockName})
    if not stockValue then
        TriggerClientEvent('stocks:SellResult', src, false, "Stock not found.")
        return
    end

    local playerShares = MySQL.scalar.await(
                             'SELECT shares FROM player_stocks WHERE player_identifier = ? AND stock_name = ?',
                             {playerIdentifier, stockName})
    if not playerShares or playerShares < quantity then
        TriggerClientEvent('stocks:SellResult', src, false,
                           "Not enough shares to sell.")
        return
    end

    local profitAmount = Config.ProfitPerPrecent
    local buyPrice = Config.BuyPrice
    local amountIncresed = stockValue - 100
    local sellPrice = 0

    if stockValue >= 100 then
        sellPrice = (buyPrice * quantity) + (profitAmount * amountIncresed)
    else
        TriggerClientEvent('stocks:SellResult', src, false,
                           "There is no demend for that stock")
        return
    end

    MySQL.update.await(
        'UPDATE player_stocks SET shares = shares - ? WHERE player_identifier = ? AND stock_name = ?',
        {quantity, playerIdentifier, stockName})

    -- הוספת כסף לשחקן
    character.addCurrency(0, sellPrice)

    TriggerClientEvent('stocks:SellResult', src, true,
                       "Sold " .. quantity .. " shares of " .. stockName ..
                           " for $" .. math.floor(sellPrice))

    BccUtils.Discord.sendMessage(Config.WebHooks.Sell, 'PyThor_StockMarket',
                                 'https://cdn2.iconfinder.com/data/icons/frosted-glass/256/Danger.png',
                                 character.firstname .. " " ..
                                     character.lastname .. ' has sold ' ..
                                     quantity .. ' in: ' .. stockName ..
                                     ' for: ' .. sellPrice .. '$')
end)

-- ===============================
--          GET STOCK VALUE
-- ===============================
RegisterNetEvent('stocks:GetStockValue')
AddEventHandler('stocks:GetStockValue', function(stockName)
    local src = source
    if not stockName then
        print("[ERROR] No stock name provided.")
        TriggerClientEvent('stocks:ReturnStockValue', src, nil)
        return
    end

    local stockValue = MySQL.scalar.await(
                           'SELECT `stock_value` FROM `pythor_stocks` WHERE `stock_name` = ?',
                           {stockName}) or 0

    TriggerClientEvent('stocks:ReturnStockValue', src, stockValue)
    print("[INFO] Sent stock value:", stockValue, "for stock:", stockName)
end)

-- ===============================
--      INCREASE STOCK VALUE
-- ===============================
RegisterNetEvent('stocks:IncreaseStockValue')
AddEventHandler('stocks:IncreaseStockValue', function(stockName, mission_type)
    local src = source
    local user = Core.getUser(src)
    local character = user.getUsedCharacter
    local playerIdentifier = character.identifier
    local contributionPoints

    if mission_type == 'AD' then contributionPoints = Config.AdValue end
    if mission_type == 'Recruit' then contributionPoints = Config.RecValue end
    if mission_type == 'Info' then contributionPoints = Config.InfoValue end

    if not stockName then
        print("[ERROR] Missing stock name or value increase from client.")
        return
    end

    local currentStockValue = MySQL.scalar.await(
                                  'SELECT stock_value FROM pythor_stocks WHERE stock_name = ?',
                                  {stockName})

    if not currentStockValue then
        print("[ERROR] Stock not found: " .. tostring(stockName))
        TriggerClientEvent("vorp:TipBottom", src, "Stock not found.", 5000)
        return
    end

    local newStockValue = currentStockValue + contributionPoints

    MySQL.update.await(
        'UPDATE pythor_stocks SET stock_value = ? WHERE stock_name = ?',
        {newStockValue, stockName})

    -- עדכון טבלת התרומות לפי קטגוריה
    MySQL.update.await([[
        INSERT INTO category_contributions (player_identifier, character_name, category_name, total_contribution)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE total_contribution = total_contribution + VALUES(total_contribution)
    ]], {
        playerIdentifier,
        character.firstname .. " " .. character.lastname,
        stockName, -- הקטגוריה היא שם המניה
        contributionPoints or 0
    })

    Core.NotifySimpleTop(src, stockName .. ' value incresed by: ' ..
                             contributionPoints, "Well done.", 5000)

    BccUtils.Discord.sendMessage(Config.WebHooks.Mission, 'PyThor_StockMarket',
                                 'https://cdn2.iconfinder.com/data/icons/frosted-glass/256/Danger.png',
                                 character.firstname .. " " ..
                                     character.lastname .. 
                                     ' has finished a mission ' .. mission_type .. 
                                     ' in: ' .. stockName .. 
                                     ' and increased the value by ' .. 
                                     contributionPoints .. '%')

    print("[INFO] Stock value updated: " .. stockName .. " -> " .. newStockValue)
end)


-- ===============================
--      DECREASE STOCK VALUE
-- ===============================
RegisterNetEvent('stocks:DecreaseStockValue')
AddEventHandler('stocks:DecreaseStockValue', function(stockName, mission_type)
    local src = source
    local user = Core.getUser(src)
    local character = user.getUsedCharacter
    local playerIdentifier = character.identifier
    local deductionPoints

    -- Assign deduction points based on mission type
    if mission_type == 'AD' then deductionPoints = Config.AdValue end
    if mission_type == 'Recruit' then deductionPoints = Config.RecValue end
    if mission_type == 'Info' then deductionPoints = Config.InfoValue end

    if not stockName then
        print("[ERROR] Missing stock name or value decrease from client.")
        return
    end

    -- Get the current stock value
    local currentStockValue = MySQL.scalar.await(
                                  'SELECT stock_value FROM pythor_stocks WHERE stock_name = ?',
                                  {stockName})

    if not currentStockValue then
        print("[ERROR] Stock not found: " .. tostring(stockName))
        TriggerClientEvent("vorp:TipBottom", src, "Stock not found.", 5000)
        return
    end

    -- Calculate the new stock value
    local newStockValue = currentStockValue - deductionPoints

    -- Ensure stock value does not drop below a minimum threshold
    newStockValue = math.max(-50, newStockValue)

    -- Update the stock value in the database
    MySQL.update.await(
        'UPDATE pythor_stocks SET stock_value = ? WHERE stock_name = ?',
        {newStockValue, stockName})

    Core.NotifySimpleTop(src, stockName .. ' value decreased by: ' .. deductionPoints, "Mission failed.", 5000)

    BccUtils.Discord.sendMessage(Config.WebHooks.Mission, 'PyThor_StockMarket',
                                 'https://cdn2.iconfinder.com/data/icons/frosted-glass/256/Danger.png',
                                 character.firstname .. " " .. character.lastname ..
                                     ' has failed a mission ' .. mission_type .. ' in: ' ..
                                     stockName .. ' and decreased the value by ' .. deductionPoints .. '%')

    print("[INFO] Stock value updated: " .. stockName .. " -> " .. newStockValue)
end)

-- ===============================
--      CHECK PLAYER JOB
-- ===============================

RegisterNetEvent('stocks:checkPlayerJob', function()
    if Config.JobLock then
        local src = source
        local user = Core.getUser(src)
        local character = user.getUsedCharacter
        local job = character.job
        local hasJob = false

        for _, v in ipairs(Config.JobsAllowed) do
            if job == v then hasJob = true end
        end

        TriggerClientEvent("client:receiveJobCheck", src, hasJob)
    end
end)

-- =================================
--   Get best player in category
-- =================================
RegisterNetEvent('stocks:getTopContributer')
AddEventHandler('stocks:getTopContributer', function(categoryName)
    local src = source

    MySQL.query([[
        SELECT character_name, MAX(total_contribution) AS highest_contribution
        FROM category_contributions
        WHERE category_name = ?
        GROUP BY character_name
        ORDER BY highest_contribution DESC
        LIMIT 1
    ]], {categoryName}, function(result)
        if result and #result > 0 then
            local topContributor = result[1]
            local message = ("%s - %d points"):format(topContributor.character_name, topContributor.highest_contribution)
            TriggerClientEvent('stocks:returnTopContributer', src, categoryName, message)
        else
            TriggerClientEvent('stocks:returnTopContributer', src, categoryName, "No contributors found.")
        end
    end)
end)

CheckVersion()
