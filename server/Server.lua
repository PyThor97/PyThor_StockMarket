local Core = exports.vorp_core:GetCore()

local function ConsolePrint(...) if Config.DevMode then print("[DEV MODE]", ...) end end

RegisterNetEvent('stocks:GetValue', function(stockName)
    local src = source -- מזהה הלקוח ששלח את הבקשה
    print("Received stock name: " .. stockName)
    local stockValue = MySQL.scalar.await('SELECT `stock_value` FROM `pythor_stocks` WHERE `stock_name` = ?', { stockName })

    if stockValue then
        ConsolePrint("Stock value for " .. stockName .. ": " .. stockValue)
        TriggerClientEvent('stocks:ReturnValue', src, stockValue)
    else
        ConsolePrint("No stock found for: " .. stockName)
        TriggerClientEvent('stocks:ReturnValue', src, "No stock found")
    end
end)

RegisterNetEvent('stocks:buyShares')
AddEventHandler('stocks:buyShares', function(stockName, quantity)
    local src = source 
    local user = Core.getUser(src) 
    local character = user.getUsedCharacter
    local playerIdentifier = character.identifier -- מזהה השחקן
    local characterName = character.firstname .. ' ' .. character.lastname -- שם הדמות של השחקן
    local playerMoney = character.money -- סכום הכסף של השחקן

    -- שליפת מחיר המניה מהטבלה `pythor_stocks`
    local stockPrice = Config.Price

    local totalPrice = stockPrice * quantity -- חישוב המחיר הכולל לרכישה

    -- בדיקת מספיק כסף
    if playerMoney >= totalPrice then
        character.removeCurrency(0, totalPrice)

        -- עדכון הטבלה `player_stocks` עם מניות חדשות או תוספת למניות קיימות
        MySQL.update.await(
            [[
            INSERT INTO player_stocks (player_identifier, character_name, stock_name, shares)
            VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                shares = shares + VALUES(shares)
            ]],
            {playerIdentifier, characterName, stockName, quantity}
        )

        TriggerClientEvent('stocks:TransactionResult', src, true, "You successfully bought " .. quantity .. " shares of " .. stockName .. " for $" .. totalPrice .. ".")
    else
        TriggerClientEvent('stocks:TransactionResult', src, false, "You don't have enough money to buy " .. quantity .. " shares of " .. stockName .. ".")
    end
end)


