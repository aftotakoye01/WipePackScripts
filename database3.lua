-- FIREBASE COMBO COCONUT - С АТОМАРНОЙ БЛОКИРОВКОЙ
-- Запускается на каждом из 5 аккаунтов

local ACCOUNT_ID = 3 -- <-- ИЗМЕНИТЬ ДЛЯ КАЖДОГО АККАУНТА (1,2,3,4,5)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

-- 🔥 ТВОИ ДАННЫЕ FIREBASE
local FIREBASE_URL = "https://coconutcombo-363b6-default-rtdb.europe-west1.firebasedatabase.app/"
local FIREBASE_SECRET = "D1rn5TSyMvE84thM8YsSBvEDuNCznVD18Tfg3ZT8"

-- ==============================================
-- ПЕРЕМЕННЫЕ
-- ==============================================
local coconutActive = false
local coconutLostTime = nil
local currentAccessory = "none"
local hasCanister = false
local hasPorcelain = false
local myTurn = false
local hasSpawnedCombo = false
local spawnValues = {5, 11, 17, 23}
local lockTimestamp = 0

-- ==============================================
-- ФУНКЦИИ FIREBASE (УЛУЧШЕННЫЕ)
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
-- НОВЫЕ ФУНКЦИИ АТОМАРНОЙ БЛОКИРОВКИ
-- ==============================================

-- Попытка захватить блокировку на спавн
function TryAcquireSpawnLock()
    local lockPath = "locks/spawn_lock"
    local lockData = GetFirebase(lockPath)
    local currentTime = os.time()
    
    -- Если блокировка свободна или истекла (старше 10 секунд)
    if not lockData or (currentTime - (lockData.timestamp or 0)) > 10 then
        -- Пытаемся установить блокировку
        local success = SetFirebase(lockPath, {
            owner = ACCOUNT_ID,
            timestamp = currentTime,
            expires = currentTime + 10
        })
        
        if success then
            -- Проверяем, что действительно захватили (нет гонки)
            local verifyLock = GetFirebase(lockPath)
            if verifyLock and verifyLock.owner == ACCOUNT_ID then
                print("🔒 Аккаунт " .. ACCOUNT_ID .. " захватил блокировку спавна")
                return true
            end
        end
    end
    
    return false
end

-- Освобождение блокировки
function ReleaseSpawnLock()
    SetFirebase("locks/spawn_lock", nil)
    print("🔓 Аккаунт " .. ACCOUNT_ID .. " освободил блокировку")
end

-- Проверка, активна ли блокировка
function IsSpawnLockActive()
    local lockData = GetFirebase("locks/spawn_lock")
    if not lockData then return false end
    
    local currentTime = os.time()
    -- Считаем блокировку неактивной, если она старше 10 секунд
    if (currentTime - (lockData.timestamp or 0)) > 10 then
        return false
    end
    
    return lockData.owner ~= nil
end

-- Кто владеет блокировкой?
function GetSpawnLockOwner()
    local lockData = GetFirebase("locks/spawn_lock")
    if not lockData then return nil end
    
    local currentTime = os.time()
    if (currentTime - (lockData.timestamp or 0)) > 10 then
        return nil
    end
    
    return lockData.owner
end

-- ==============================================
-- ТВОИ ФУНКЦИИ
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

function SpawnCoconut(isCombo)
    local args = {
        {
            Name = "Coconut"
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("PlayerActivesCommand"):FireServer(unpack(args))
    if isCombo then
        print("🎯 АККАУНТ " .. ACCOUNT_ID .. " КОМБО КОКОС!")
    else
        print("🥥 Аккаунт " .. ACCOUNT_ID .. " обычный кокос")
    end
    lockTimestamp = tick()
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

function GetAccountValue(accId)
    return GetFirebase("accounts/" .. accId .. "/combo_value") or 0
end

function IsAccountReady(accId)
    return GetFirebase("accounts/" .. accId .. "/ready") or false
end

-- ==============================================
-- ИНИЦИАЛИЗАЦИЯ FIREBASE
-- ==============================================
pcall(function()
    SetFirebase("accounts/" .. ACCOUNT_ID, {
        ready = false,
        combo_value = 0,
        last_update = os.time()
    })
    
    if not GetFirebase("turns") then
        SetFirebase("turns", {
            current_turn = 1,
            last_spawn = 0
        })
    end
    
    -- Инициализация locks, если нет
    if not GetFirebase("locks") then
        SetFirebase("locks", {})
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
-- МОНИТОРИНГ ПОЯВЛЕНИЯ КОМБО
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
-- ТАЙМЕР НА 15 СЕКУНД
-- ==============================================
spawn(function()
    while true do
        if not coconutActive and coconutLostTime and tick() - coconutLostTime >= 15 then
            SpawnCoconut(false)
            if currentAccessory ~= "canister" then
                EquipCanister()
            end
            coconutLostTime = nil
        end
        task.wait(1)
    end
end)

-- ==============================================
-- СТРАХОВКА КАЖДЫЕ 5 СЕКУНД
-- ==============================================
spawn(function()
    while true do
        local myValue = GetAccountValue(ACCOUNT_ID)
        if myValue ~= 39 and currentAccessory ~= "canister" then
            EquipCanister()
        end
        task.wait(5)
    end
end)

-- ==============================================
-- УЛУЧШЕННАЯ ПРОВЕРКА ГОТОВНОСТИ С БЛОКИРОВКОЙ
-- ==============================================
spawn(function()
    while true do
        myTurn = (GetCurrentTurn() == ACCOUNT_ID)
        local myValue = GetAccountValue(ACCOUNT_ID)
        
        -- Только если наш ход, значение 39, и мы еще не спавнили
        if myTurn and myValue == 39 and not hasSpawnedCombo then
            
            -- Проверяем, свободна ли блокировка
            local lockOwner = GetSpawnLockOwner()
            
            -- Если блокировка свободна или принадлежит нам (с истекшим сроком)
            if lockOwner == nil or (lockOwner ~= ACCOUNT_ID and tick() - lockTimestamp > 10) then
                
                -- Пытаемся захватить блокировку
                if TryAcquireSpawnLock() then
                    
                    -- Проверяем готовность всех аккаунтов
                    local allReady = true
                    for i = 1, 5 do
                        if i ~= ACCOUNT_ID and not IsAccountReady(i) then
                            allReady = false
                            break
                        end
                    end
                    
                    if allReady then
                        print("🎯 АККАУНТ " .. ACCOUNT_ID .. " СПАВНИТ КОМБО!")
                        SpawnCoconut(true)
                        hasSpawnedCombo = true
                        
                        -- Сбрасываем ready флаги
                        for i = 1, 5 do
                            SetFirebase("accounts/" .. i .. "/ready", false)
                        end
                        
                        -- Переключаем ход
                        NextTurn()
                        
                        -- Освобождаем блокировку
                        ReleaseSpawnLock()
                    else
                        -- Не все готовы - освобождаем блокировку
                        ReleaseSpawnLock()
                    end
                end
            end
        end
        
        task.wait(2)
    end
end)

-- ==============================================
-- ОЧИСТКА СТАРЫХ БЛОКИРОВОК
-- ==============================================
spawn(function()
    while true do
        -- Раз в 30 секунд проверяем и чистим старые блокировки
        task.wait(30)
        
        local lockData = GetFirebase("locks/spawn_lock")
        if lockData then
            local currentTime = os.time()
            if (currentTime - (lockData.timestamp or 0)) > 30 then
                print("🧹 Очистка старой блокировки от аккаунта " .. (lockData.owner or "unknown"))
                SetFirebase("locks/spawn_lock", nil)
            end
        end
    end
end)

-- ==============================================
-- ОСНОВНАЯ ЛОГИКА
-- ==============================================
require(ReplicatedStorage.Events).ClientListen("PlayerAbilityEvent", function(data)
    for tag, info in pairs(data) do
        if tag == "Combo Coconuts" or tag == "ComboCoconuts" then
            if info.Action == "Update" then
                local value = info.Values and info.Values[1] or 0
                
                -- Обновляем Firebase
                SetFirebase("accounts/" .. ACCOUNT_ID .. "/combo_value", value)
                SetFirebase("accounts/" .. ACCOUNT_ID .. "/last_update", os.time())
                
                -- Логика переключения рюкзаков
                if value < 39 and not hasCanister then
                    EquipCanister()
                elseif value == 39 and not hasPorcelain then
                    EquipPorcelain()
                end
                
                -- Спавн кокосов на определенных значениях
                for _, spawnVal in pairs(spawnValues) do
                    if value == spawnVal then
                        SpawnCoconut(false)
                        break
                    end
                end
            end
        end
    end
end)

-- ==============================================
-- ДЕБАГ
-- ==============================================
spawn(function()
    while true do
        task.wait(10)
        print("📊 Firebase статус:")
        for i = 1, 5 do
            local val = GetAccountValue(i)
            local ready = IsAccountReady(i)
            print("   Аккаунт " .. i .. ": value=" .. val .. ", ready=" .. tostring(ready))
        end
        local lockOwner = GetSpawnLockOwner()
        print("   Текущий ход: " .. GetCurrentTurn() .. " | Блокировка: " .. (lockOwner and "аккаунт " .. lockOwner or "свободна"))
    end
end)

-- ==============================================
-- ИНФОРМАЦИЯ О ЗАПУСКЕ
-- ==============================================
print("========================================")
print("✅ FIREBASE COMBO COCONUT - АККАУНТ " .. ACCOUNT_ID)
print("========================================")
print("📡 Атомарная блокировка спавна активирована")
print("🎯 Текущий ход: Аккаунт " .. GetCurrentTurn())
print("🔄 Очередь: 1 → 2 → 3 → 4 → 5 → 1...")
print("========================================")
