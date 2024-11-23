RegisterNetEvent('stocks:GetValue', function(stockName)
    local src = source -- מזהה הלקוח ששלח את הבקשה
    print("Received stock name: " .. stockName)

    -- שליפת הערך ממסד הנתונים
    local stockValue = MySQL.scalar.await('SELECT `stock_value` FROM `pythor_stocks` WHERE `stock_name` = ?', { stockName })

    -- בדיקה אם הערך נמצא
    if stockValue then
        print("Stock value for " .. stockName .. ": " .. stockValue)
        -- שליחת הערך ללקוח
        TriggerClientEvent('stocks:ReturnValue', src, stockValue)
    else
        print("No stock found for: " .. stockName)
        TriggerClientEvent('stocks:ReturnValue', src, "No stock found")
    end
end)
