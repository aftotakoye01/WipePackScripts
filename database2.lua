-- FIREBASE COMBO COCONUT - С ЗАМОРОЗКОЙ КОКОСОВ
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
-- ТВОИ ОРИГИНАЛЬНЫЕ ПЕРЕМЕННЫЕ
-- ==============================================
local lastValue = -1
local coconutActive = false
local coconutLostTime = nil
local sentValues = {}
local currentAccessory = "none"
local myTurn = false
local hasSpawnedCombo = false
local canSpawnAfter15 = false -- ✅ РАЗРЕШЕНИЕ НА СПАВН ПОСЛЕ 15 СЕКУНД

-- ==============================================
-- ФУНКЦИИ FIREBASE
-- ==============================================
function SetFirebase(path, data)
    local success, result = pcall(function()
        local url = string.format("%s%s.json?auth=%s", FIREBASE_URL, path, FIREBASE_SECRET)
        local body = HttpService:JSONEncode(data)
        
        local response = HttpService:RequestAsync({
            Url = url,
            Method = "PUT",
            Headers = {["Content-Type"] = "application/json"},
            Body = body
        })
        
        return response.Success
    end)
    return success
end

function GetFirebase(path)
    local success, result = pcall(function()
        local url = string.format("%s%s.json?auth=%s", FIREBASE_URL, path, FIREBASE_SECRET)
        
        local response = HttpService:RequestAsync({
            Url = url,
            Method = "GET"
        })
        
        if response.Success then
            return HttpService:JSONDecode(response.Body)
        end
    end)
    return success and result
end

-- ==============================================
-- ТВОИ ОРИГИНАЛЬНЫЕ ФУНКЦИИ
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
    print("✅ Аккаунт " .. ACCOUNT_ID .. " Porcelain")
end

function SpawnCoconut(isFromTimer)
    local args = {
        {
            Name = "Coconut"
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("PlayerActivesCommand"):FireServer(unpack(args))
    if isFromTimer then
        print("🥥 Аккаунт " .. ACCOUNT_ID .. " спавн кокоса (по таймеру 15с)")
    else
        print("🥥 Аккаунт " .. ACCOUNT_ID .. " спавн кокоса")
    end
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
        online = true,
        can_spawn = false -- ✅ Флаг разрешения на спавн после 15 сек
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
-- МОНИТОРИНГ ОЧЕРЕДИ (КТО МОЖЕТ СПАВНИТЬ ПОСЛЕ 15 СЕК)
-- ==============================================
spawn(function()
    while true do
        local currentTurn = GetCurrentTurn()
        myTurn = (currentTurn == ACCOUNT_ID)
        
        -- Разрешаем спавн после 15 сек ТОЛЬКО тому, чей сейчас ход
        if myTurn then
            SetFirebase("accounts/" .. ACCOUNT_ID .. "/can_spawn", true)
            -- Снимаем разрешение у всех остальных
            for i = 1, 5 do
                if i ~= ACCOUNT_ID then
                    SetFirebase("accounts/" .. i .. "/can_spawn", false)
                end
            end
        end
        
        task.wait(1)
    end
end)

-- ==============================================
-- ТВОЙ МОНИТОРИНГ КОМБО
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
            
            -- Если это был наш спавн, через 15 сек отметим готовность
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
-- ТАЙМЕР НА 15 СЕКУНД (ТОЛЬКО ДЛЯ ТЕКУЩЕГО В ОЧЕРЕДИ)
-- ==============================================
spawn(function()
    while true do
        -- Проверяем: прошло 15 сек, комбо не активно, И МЫ ИМЕЕМ РАЗРЕШЕНИЕ
        local canSpawn = GetFirebase("accounts/" .. ACCOUNT_ID .. "/can_spawn")
        
        if not coconutActive and coconutLostTime and tick() - coconutLostTime >= 15 and canSpawn then
            SpawnCoconut(true) -- true = это спавн от таймера
            if currentAccessory ~= "canister" then
                EquipCanister()
            end
            coconutLostTime = nil
            
            -- Снимаем разрешение после спавна
            SetFirebase("accounts/" .. ACCOUNT_ID .. "/can_spawn", false)
            print("🔒 Аккаунт " .. ACCOUNT_ID .. " заморозил спавн до следующего хода")
        end
        task.wait(1)
    end
end)

-- ==============================================
-- СТРАХОВОЧНЫЙ МЕХАНИЗМ (каждые 5 секунд)
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
-- ТВОЯ ОСНОВНАЯ ЛОГИКА
-- ==============================================
require(ReplicatedStorage.Events).ClientListen("PlayerAbilityEvent", function(data)
    for tag, info in pairs(data) do
        if tag == "Combo Coconuts" or tag == "ComboCoconuts" then
            if info.Action == "Update" then
                local value = info.Values and info.Values[1] or 0
                
                SetFirebase("accounts/" .. ACCOUNT_ID .. "/combo_value", value)
                
                if value < 39 then
                    if currentAccessory ~= "canister" then
                        EquipCanister()
                    end
                elseif value == 39 then
                    if currentAccessory ~= "porcelain" and not sentValues[39] then
                        EquipPorcelain()
                        sentValues[39] = true
                        print("🎯 Аккаунт " .. ACCOUNT_ID .. " ДОСТИГ 39!")
                    end
                end
                
                if value ~= lastValue then
                    print("🥥 Аккаунт " .. ACCOUNT_ID .. " комбо значение:", value)
                    
                    if value == 0 and not sentValues[0] then
                        sentValues[0] = true
                    end
                    
                    if (value == 5 or value == 11 or value == 16 or value == 21) and not sentValues[value] then
                        SpawnCoconut()
                        sentValues[value] = true
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
print("🔒 Спавн после 15 сек ТОЛЬКО у текущего в очереди")
print("========================================")
