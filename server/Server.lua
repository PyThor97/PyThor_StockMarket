RegisterNetEvent('stocks:GetValue', function(stockName)
    local src = source -- מזהה הלקוח ששלח את הבקשה
    print("Received stock name: " .. stockName)
    local stockValue = MySQL.scalar.await('SELECT `stock_value` FROM `pythor_stocks` WHERE `stock_name` = ?', { stockName })

    if stockValue then
        print("Stock value for " .. stockName .. ": " .. stockValue)
        TriggerClientEvent('stocks:ReturnValue', src, stockValue)
    else
        print("No stock found for: " .. stockName)
        TriggerClientEvent('stocks:ReturnValue', src, "No stock found")
    end
end)
