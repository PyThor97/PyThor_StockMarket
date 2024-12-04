local Core = exports.vorp_core:GetCore()

local function ConsolePrint(...)
    if Config.DevMode then print("[DEV MODE]", ...) end
end

-- ===============================
--          DEV PRINT
-- ===============================
RegisterNetEvent('stocks:GetValue', function(stockName)
    local src = source -- מזהה הלקוח ששלח את הבקשה
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

    -- עדכון הטבלה
    MySQL.update.await([[
    INSERT INTO player_stocks (player_identifier, character_name, stock_name, shares)
    VALUES (?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE shares = shares + VALUES(shares)
    ]], {
        playerIdentifier, character.firstname .. " " .. character.lastname,
        stockName, quantity
    })

    -- החזרת תגובה ללקוח
    TriggerClientEvent('stocks:BuyResult', src, true,
                       "Bought " .. quantity .. " shares of " .. stockName)
end)

--==========================
--- Get players shares
--==========================
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

    -- החזרת רשימת המניות לצד הלקוח
    TriggerClientEvent('stocks:ReturnPlayerStocks', src, playerStocks)
end)

-- ====================================
--          GET PLAYER SHARES COUNT
-- ====================================
RegisterNetEvent('stocks:GetPlayerShares')
AddEventHandler('stocks:GetPlayerShares', function(stockName)
    local src = source -- מזהה הלקוח ששלח את הבקשה
    local user = Core.getUser(src) -- קבלת מידע על המשתמש
    local character = user.getUsedCharacter -- קבלת מידע על הדמות
    local playerIdentifier = character.identifier -- מזהה השחקן

    -- שאילתה לבדיקת מספר המניות בטבלת השחקנים
    local shares = MySQL.scalar.await(
                       'SELECT `shares` FROM `player_stocks` WHERE `player_identifier` = ? AND `stock_name` = ?',
                       {playerIdentifier, stockName})

    -- שליחת התשובה ללקוח
    if shares then
        TriggerClientEvent('stocks:ReturnPlayerShares', src, shares)
    else
        TriggerClientEvent('stocks:ReturnPlayerShares', src, 0) -- אם אין מניות, החזר 0
    end
end)

-- ====================================
--        SELL PLAYER SHARES
-- ====================================
RegisterNetEvent('stocks:SellShares')
AddEventHandler('stocks:SellShares', function(stockName, sellAmount)
    local src = source -- מזהה הלקוח ששלח את הבקשה
    local user = Core.getUser(src) -- קבלת מידע על השחקן
    local character = user.getUsedCharacter -- קבלת מידע על הדמות
    local playerIdentifier = character.identifier -- מזהה השחקן

    local shares = MySQL.scalar.await(
                       'SELECT `shares` FROM `player_stocks` WHERE `player_identifier` = ? AND `stock_name` = ?',
                       {playerIdentifier, stockName})

    local stockValue = MySQL.scalar.await(
                           'SELECT `stock_value` FROM `pythor_stocks` WHERE `stock_name` = ?',
                           {stockName})

    if not shares or shares < sellAmount then
        -- אם אין מספיק מניות למכירה
        TriggerClientEvent('stocks:SellResult', src, false,
                           "You don't have enough shares to sell.")
        return
    end

    -- חישוב הסכום שמגיע לשחקן
    local totalValue = stockValue * sellAmount

    -- עדכון מספר המניות
    MySQL.update.await(
        'UPDATE `player_stocks` SET `shares` = `shares` - ? WHERE `player_identifier` = ? AND `stock_name` = ?',
        {sellAmount, playerIdentifier, stockName})

    -- הוספת הכסף לשחקן
    character.addCurrency(0, 1000)

    -- החזרת הודעת הצלחה ללקוח
    TriggerClientEvent('stocks:SellResult', src, true,
                       "You sold " .. sellAmount .. " shares of " .. stockName ..
                           " for $" .. totalValue .. ".")
end)

-- ===============================
--          GET STOCK VALUE
-- ===============================
RegisterNetEvent('stocks:GetStockValue')
AddEventHandler('stocks:GetStockValue', function(stockName)
    local src = source -- מזהה השחקן ששלח את הבקשה
    if not stockName then
        print("[ERROR] No stock name provided.")
        TriggerClientEvent('stocks:ReturnStockValue', src, nil) -- מחזיר NIL
        return
    end

    -- שליפת ערך המניה מתוך הטבלה
    local stockValue = MySQL.scalar.await(
                           'SELECT `stock_value` FROM `pythor_stocks` WHERE `stock_name` = ?',
                           {stockName}) or 0 -- ברירת מחדל לערך 0 אם לא נמצא

    -- שליחת הערך חזרה לצד הלקוח
    TriggerClientEvent('stocks:ReturnStockValue', src, stockValue)
    print("[INFO] Sent stock value:", stockValue, "for stock:", stockName)
end)
