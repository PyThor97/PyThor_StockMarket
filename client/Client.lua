local FeatherMenu = exports['feather-menu'].initiate()
local BccUtils = exports['bcc-utils'].initiate()
local StockMenuPrompt = BccUtils.Prompts:SetupPromptGroup()
local Stockprompt = StockMenuPrompt:RegisterPrompt("Invest in stock",
                                                   0x760A9C6F, 1, 1, true,
                                                   'click')
local pedsCreated = {}
local blipsCreated = {}

function CreateClerks()
    Citizen.CreateThread(function()
        for _, value in ipairs(Config.Locations) do
            local coords = value.coords
            local ped = BccUtils.Peds:Create(value.ped, coords.x, coords.y,
                                             coords.z, 0, 'world', false)
            ped:AddPedToGroup(GetPedGroupIndex(Stockprompt))
            pedsCreated[#pedsCreated + 1] = ped
        end
    end)
end

function CreateBlips()
    function CreateBlips()
        Citizen.CreateThread(function()
            for _, value in ipairs(Config.Locations) do
                if value.Blip then
                    local  blip = BccUtils.Blips:SetBlip(value.BlipName, value.BlipSprite, 0.2, value.coords)
                    blipsCreated[#blipsCreated + 1] = blip
                end
            end
        end)
    end
end
