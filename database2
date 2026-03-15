-- FIREBASE COMBO COCONUT - ИДЕАЛЬНАЯ ВЕРСИЯ
-- Запускается на каждом из 5 аккаунтов

local ACCOUNT_ID = 2 -- <-- ИЗМЕНИТЬ ДЛЯ КАЖДОГО АККАУНТА (1,2,3,4,5)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

-- 🔥 ТВОИ ДАННЫЕ FIREBASE
local FIREBASE_URL = "https://coconutcombo-363b6-default-rtdb.europe-west1.firebasedatabase.app/"
local FIREBASE_SECRET = "D1rn5TSyMvE84thM8YsSBvEDuNCznVD18Tfg3ZT8"

-- ==============================================
-- ТВОИ ПЕРЕМЕННЫЕ (из идеального скрипта)
-- ==============================================
local lastValue = -1
local coconutActive = false
local coconutLostTime = nil
local currentAccessory = "none"
local hasCanister = false
local hasPorcelain = false
local myTurn = false
local hasSpawnedCombo = false

-- Значения для спавна кокосов
local spawnValues = {5, 11, 17, 23}

-- ==============================================
-- ФУНКЦИИ FIREBASE
-- ==============================================
function SetFirebase(path, data)
    pcall(function()
        local url = string.format("%s%s.json?auth=%s", FIREBASE_URL, path, FIREBASE_SECRET)
        local body = HttpService:JSONEncode(data)
        HttpService:RequestAsync({
            Url = url,
            Method = "PUT",
            Headers = {["Content-Type"] = "application/json"},
            Body = body
        })
    end)
end

function GetFirebase(path)
    local success, result = pcall(function()
        local url = string.format("%s%s.json?auth=%s", FIREBASE_URL, path, FIREBASE_SECRET)
        local response = HttpService:RequestAsync({Url = url, Method = "GET"})
        if response.Success then
            return HttpService:JSONDecode(response.Body)
        end
    end)
    return success and result
end

-- ==============================================
-- ТВОИ ФУНКЦИИ (из идеального скрипта)
-- ==============================================
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
    print("✅ Аккаунт " .. ACCOUNT_ID .. " Coconut Canister")
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
    print("✅ Аккаунт " .. ACCOUNT_ID .. " Porcelain")
end

function SpawnCoconut()
    local args = {
        {
            Name = "Coconut"
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("PlayerActivesCommand"):FireServer(unpack(args))
    print("🥥 Аккаунт " .. ACCOUNT_ID .. " спавн кокоса")
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

-- ==============================================
-- ИНИЦИАЛИЗАЦИЯ FIREBASE
-- ==============================================
pcall(function()
    SetFirebase("accounts/" .. ACCOUNT_ID, {
        ready = false,
        combo_value = 0,
        online = true
    })
    
    local turns = GetFirebase("turns")
    if not turns then
        SetFirebase("turns", {
            current_turn = 1,
            last_spawn = 0
        })
    end
end)

-- ==============================================
-- ФУНКЦИИ ОЧЕРЕДИ
-- ==============================================
function GetCurrentTurn()
    return GetFirebase("turns/current_turn") or 1
end

function NextTurn()
    local current = GetCurrentTurn()
    local nextTurn = current + 1
    if nextTurn > 5 then nextTurn = 1 end
    SetFirebase("turns/current_turn", nextTurn)
    SetFirebase("turns/last_spawn", os.time())
    print("🔄 Аккаунт " .. ACCOUNT_ID .. ": ход перешел к " .. nextTurn)
end

-- ==============================================
-- ТВОЙ МОНИТОРИНГ КОМБО (из идеального скрипта)
-- ==============================================
spawn(function()
    while true do
        local present = IsComboCoconutPresent()
        if present and not coconutActive then
            coconutActive = true
            coconutLostTime = nil
            print("🥥 Аккаунт " .. ACCOUNT_ID .. " комбо появилось")
        elseif not present and coconutActive then
            coconutActive = false
            coconutLostTime = tick()
            print("🥥 Аккаунт " .. ACCOUNT_ID .. " комбо исчезло")
            
            -- Если это был наш спавн, через 15 сек отмечаем готовность
            if GetCurrentTurn() == ACCOUNT_ID and hasSpawnedCombo then
                task.wait(15)
                SetFirebase("accounts/" .. ACCOUNT_ID .. "/ready", true)
                hasSpawnedCombo = false
                print("✅ Аккаунт " .. ACCOUNT_ID .. " готов к следующему циклу")
            end
        end
        task.wait(0.5)
    end
end)

-- ==============================================
-- ТВОЙ ТАЙМЕР НА 15 СЕКУНД (из идеального скрипта)
-- ==============================================
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

-- ==============================================
-- СТРАХОВКА КАЖДЫЕ 5 СЕКУНД (из идеального скрипта)
-- ==============================================
spawn(function()
    while true do
        if lastValue ~= 39 and currentAccessory ~= "canister" then
            EquipCanister()
        end
        task.wait(5)
    end
end)

-- ==============================================
-- ПРОВЕРКА ГОТОВНОСТИ ВСЕХ АККАУНТОВ
-- ==============================================
spawn(function()
    while true do
        myTurn = (GetCurrentTurn() == ACCOUNT_ID)
        
        if myTurn and lastValue == 39 and not hasSpawnedCombo then
            
            local allReady = true
            for i = 1, 5 do
                if i ~= ACCOUNT_ID then
                    local ready = GetFirebase("accounts/" .. i .. "/ready")
                    if not ready then
                        allReady = false
                        break
                    end
                end
            end
            
            if allReady then
                print("🎯 АККАУНТ " .. ACCOUNT_ID .. " СПАВНИТ КОМБО!")
                SpawnCoconut()
                hasSpawnedCombo = true
                
                for i = 1, 5 do
                    SetFirebase("accounts/" .. i .. "/ready", false)
                end
                
                NextTurn()
            end
        end
        
        task.wait(2)
    end
end)

-- ==============================================
-- ТВОЯ ОСНОВНАЯ ЛОГИКА (из идеального скрипта)
-- ==============================================
require(ReplicatedStorage.Events).ClientListen("PlayerAbilityEvent", function(data)
    for tag, info in pairs(data) do
        if tag == "Combo Coconuts" or tag == "ComboCoconuts" then
            if info.Action == "Update" then
                local value = info.Values and info.Values[1] or 0
                
                -- Обновляем значение в Firebase
                SetFirebase("accounts/" .. ACCOUNT_ID .. "/combo_value", value)
                
                -- Логика переключения рюкзаков
                if value < 39 and not hasCanister then
                    EquipCanister()
                elseif value == 39 and not hasPorcelain then
                    EquipPorcelain()
                end
                
                if value ~= lastValue then
                    print("🥥 Аккаунт " .. ACCOUNT_ID .. " комбо значение:", value)
                    
                    -- Спавн кокосов на определенных значениях
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

-- ==============================================
-- ИНФОРМАЦИЯ О ЗАПУСКЕ
-- ==============================================
print("========================================")
print("✅ FIREBASE COMBO COCONUT - АККАУНТ " .. ACCOUNT_ID)
print("========================================")
print("📡 Firebase подключен")
print("🎯 Текущий ход: Аккаунт " .. GetCurrentTurn())
print("🔄 Очередь: 1 → 2 → 3 → 4 → 5 → 1...")
print("📊 Спавн кокосов на:", table.concat(spawnValues, ", "))
print("========================================")
