local Core = exports.vorp_core:GetCore()

local function ConsolePrint(...) if Config.DevMode then print("[DEV MODE]", ...) end end

-- ===============================
--          DEV PRINT
-- ===============================
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

-- ===============================
--          BUY SHARES
-- ===============================
RegisterNetEvent('stocks:buyShares')
AddEventHandler('stocks:buyShares', function(stockName, quantity)
    local src = source
    local user = Core.getUser(src)

    if not user then
        print("[ERROR] User not found for source: " .. tostring(src))
        Core.NotifyObjective(src, "Error processing your request.", 4000)
        return
    end

    local character = user.getUsedCharacter
    if not character then
        print("[ERROR] Character not found for user: " .. tostring(src))
        Core.NotifyObjective(src, "Error processing your character data.", 4000)
        return
    end

    local playerIdentifier = character.identifier
    local characterName = character.firstname .. ' ' .. character.lastname
    local playerMoney = character.money

    local stockPrice = Config.Price or 100
    local totalPrice = stockPrice * quantity

    if playerMoney >= totalPrice then
        character.removeCurrency(0, totalPrice)

        local success, errorMessage = pcall(function()
            MySQL.update.await(
                [[
                INSERT INTO player_stocks (player_identifier, character_name, stock_name, shares)
                VALUES (?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE
                    shares = shares + VALUES(shares)
                ]],
                {playerIdentifier, characterName, stockName, quantity}
            )
        end)

        if not success then
            print("[ERROR] Failed to update database: " .. errorMessage)
            Core.NotifyObjective(src, "Error updating your stocks.", 4000)
            return
        end

        Core.NotifyObjective(src, "You successfully bought " .. quantity .. " shares of " .. stockName .. " for $" .. totalPrice, 4000)
        print("[INFO] Player " .. playerIdentifier .. " bought " .. quantity .. " shares of " .. stockName)
    else
        Core.NotifyObjective(src, "You don't have enough money to buy " .. quantity .. " shares.", 4000)
        print("[INFO] Player " .. playerIdentifier .. " tried to buy " .. quantity .. " shares but didn't have enough money.")
    end
end)

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
        {playerIdentifier}
    )

    -- החזרת רשימת המניות לצד הלקוח
    TriggerClientEvent('stocks:ReturnPlayerStocks', src, playerStocks)
end)

-- ====================================
--          GET PLAYER SHARES COUNT
-- ====================================

RegisterNetEvent('stocks:GetStockValue')
AddEventHandler('stocks:GetStockValue', function(stockName)
    local src = source -- מזהה הלקוח ששלח את הבקשה

    local stockValue = MySQL.scalar.await(
        'SELECT stock_value FROM pythor_stocks WHERE stock_name = ?',
        {stockName}
    )
    if stockValue then
        TriggerClientEvent('stocks:ReturnStockValue', src, stockValue)
        ConsolePrint('Returned ' .. stockName .. ':' .. stockValue .. 'for:' .. src)
    else
        TriggerClientEvent('stocks:ReturnStockValue', src, nil) -- במקרה שלא נמצאה מניה
    end
end)




