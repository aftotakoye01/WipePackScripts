local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer

local lastValue = -1
local coconutActive = false
local coconutLostTime = nil
local currentAccessory = "none"
local hasCanister = false
local hasPorcelain = false

-- Значения для спавна кокосов (теперь они будут срабатывать каждый раз)
local spawnValues = {5, 11, 17, 23}

function EquipCanister()
    local args = {
        "Equip",
        {
            Category = "Accessory",
            Type = "Coconut Canister"
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("ItemPackageEvent"):InvokeServer(unpack(args))
    currentAccessory = "canister"
    hasCanister = true
    hasPorcelain = false
    print("✅ Экипирован Coconut Canister")
end

function EquipPorcelain()
    local args = {
        "Equip",
        {
            Category = "Accessory",
            Type = "Porcelain Port-O-Hive"
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("ItemPackageEvent"):InvokeServer(unpack(args))
    currentAccessory = "porcelain"
    hasPorcelain = true
    hasCanister = false
    print("✅ Экипирован Porcelain Port-O-Hive")
end

function SpawnCoconut()
    local args = {
        {
            Name = "Coconut"
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("PlayerActivesCommand"):FireServer(unpack(args))
    print("🥥 Спавн кокоса")
end

function IsComboCoconutPresent()
    local particles = Workspace:FindFirstChild("Particles")
    if not particles then return false end
    for _, obj in pairs(particles:GetChildren()) do
        if obj.Name == "ComboCoconut" and obj.ClassName == "UnionOperation" then
            return true
        end
    end
    return false
end

spawn(function()
    while true do
        local present = IsComboCoconutPresent()
        if present and not coconutActive then
            coconutActive = true
            coconutLostTime = nil
            print("🥥 ComboCoconut появился")
        elseif not present and coconutActive then
            coconutActive = false
            coconutLostTime = tick()
            print("🥥 ComboCoconut исчез")
        end
        task.wait(0.5)
    end
end)

spawn(function()
    while true do
        if not coconutActive and coconutLostTime and tick() - coconutLostTime >= 15 then
            SpawnCoconut()
            if currentAccessory ~= "canister" then
                EquipCanister()
            end
            coconutLostTime = nil
        end
        task.wait(1)
    end
end)

-- Страховка для кокосового рюкзака (каждые 5 секунд)
spawn(function()
    while true do
        if lastValue ~= 39 and currentAccessory ~= "canister" then
            EquipCanister()
        end
        task.wait(5)
    end
end)

require(ReplicatedStorage.Events).ClientListen("PlayerAbilityEvent", function(data)
    for tag, info in pairs(data) do
        if tag == "Combo Coconuts" or tag == "ComboCoconuts" then
            if info.Action == "Update" then
                local value = info.Values and info.Values[1] or 0
                
                -- Логика переключения рюкзаков (теперь будет работать постоянно)
                if value < 39 and not hasCanister then
                    EquipCanister()
                elseif value == 39 and not hasPorcelain then
                    EquipPorcelain()
                end
                
                if value ~= lastValue then
                    print("🥥 Комбо значение:", value)
                    
                    -- Спавн кокосов на определенных значениях (теперь всегда)
                    for _, spawnVal in pairs(spawnValues) do
                        if value == spawnVal then
                            SpawnCoconut()
                            break
                        end
                    end
                    
                    lastValue = value
                end
            end
        end
    end
end)

print("✅ Combo Coconut менеджер (ЦИКЛИЧЕСКАЯ ВЕРСИЯ)")
print("🔄 Теперь всё работает постоянно!")
