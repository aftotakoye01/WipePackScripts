-- FIREBASE COMBO COCONUT - ЛОКАЛЬНАЯ ОЧЕРЕДЬ, БЕСКОНЕЧНЫЙ ЦИКЛ
-- Запускается на каждом из 5 аккаунтов
-- Единственное, что нужно изменить: ACCOUNT_ID

local ACCOUNT_ID = 1  -- <--- ИЗМЕНИТЬ ДЛЯ КАЖДОГО АККАУНТА (1,2,3,4,5)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

-- 🔥 FIREBASE (не трогаем)
local FIREBASE_URL = "https://coconutcombo-363b6-default-rtdb.europe-west1.firebasedatabase.app/"
local FIREBASE_SECRET = "D1rn5TSyMvE84thM8YsSBvEDuNCznVD18Tfg3ZT8"

-- ==============================================
-- ПЕРЕМЕННЫЕ
-- ==============================================
local comboActive = false          -- есть ли сейчас комбо в мире (по детектору)
local comboLostTime = nil          -- когда комбо пропало (tick)
local currentAccessory = "none"
local hasCanister = false
local hasPorcelain = false
local hasSpawnedCombo = false      -- этот аккаунт уже запустил СВОЁ комбо в текущем круге
local spawnValues = {5, 11, 17, 23}
local localComboValue = 0          -- ЛОКАЛЬНОЕ значение комбо (только для этого аккаунта)

-- ==============================================
-- БАЗОВЫЕ ФУНКЦИИ FIREBASE
-- ==============================================
local function SetFirebase(path, data)
    pcall(function()
        local url = string.format("%s%s.json?auth=%s", FIREBASE_URL, path, FIREBASE_SECRET)
        HttpService:RequestAsync({
            Url = url,
            Method = "PUT",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
end

local function GetFirebase(path)
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
-- АТОМАРНАЯ БЛОКИРОВКА
-- ==============================================
local function TryAcquireAtomicLock()
    local lockPath = "locks/spawn_lock"
    local currentTime = os.time()
    local maxRetries = 3
    
    for retry = 1, maxRetries do
        local getUrl = string.format("%s%s.json?auth=%s", FIREBASE_URL, lockPath, FIREBASE_SECRET)
        local getSuccess, getResponse = pcall(function()
            return HttpService:RequestAsync({
                Url = getUrl,
                Method = "GET",
                Headers = {["X-Firebase-ETag"] = "true"}
            })
        end)
        
        if not getSuccess or not getResponse.Success then
            task.wait(0.1)
            continue
        end
        
        local etag = getResponse.Headers["etag"]
        if not etag then
            task.wait(0.1)
            continue
        end
        
        local lockData = nil
        if getResponse.Body and #getResponse.Body > 0 and getResponse.Body ~= "null" then
            lockData = HttpService:JSONDecode(getResponse.Body)
        end
        
        if lockData and (currentTime - (lockData.timestamp or 0)) <= 10 then
            return false
        end
        
        local newLock = {owner = ACCOUNT_ID, timestamp = currentTime}
        local putUrl = string.format("%s%s.json?auth=%s", FIREBASE_URL, lockPath, FIREBASE_SECRET)
        local putSuccess, putResponse = pcall(function()
            return HttpService:RequestAsync({
                Url = putUrl,
                Method = "PUT",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["if-match"] = etag
                },
                Body = HttpService:JSONEncode(newLock)
            })
        end)
        
        if putSuccess and putResponse.Success then
            print("🔒 Аккаунт " .. ACCOUNT_ID .. " захватил блокировку")
            return true
        end
        
        task.wait(0.2)
    end
    
    return false
end

local function ReleaseAtomicLock()
    local lockPath = "locks/spawn_lock"
    
    local getUrl = string.format("%s%s.json?auth=%s", FIREBASE_URL, lockPath, FIREBASE_SECRET)
    local getSuccess, getResponse = pcall(function()
        return HttpService:RequestAsync({
            Url = getUrl,
            Method = "GET",
            Headers = {["X-Firebase-ETag"] = "true"}
        })
    end)
    
    if not getSuccess or not getResponse.Success then return end
    local etag = getResponse.Headers["etag"]
    if not etag then return end
    
    local deleteUrl = string.format("%s%s.json?auth=%s", FIREBASE_URL, lockPath, FIREBASE_SECRET)
    pcall(function()
        HttpService:RequestAsync({
            Url = deleteUrl,
            Method = "DELETE",
            Headers = {["if-match"] = etag}
        })
    end)
    
    print("🔓 Аккаунт " .. ACCOUNT_ID .. " освободил блокировку")
end

-- ==============================================
-- ФУНКЦИИ ИГРЫ
-- ==============================================
local function EquipCanister()
    local args = {{"Equip",{Category="Accessory",Type="Coconut Canister"}}}
    ReplicatedStorage:WaitForChild("Events"):WaitForChild("ItemPackageEvent"):InvokeServer(unpack(args[1]))
    currentAccessory = "canister"
    hasCanister = true
    hasPorcelain = false
    print("✅ Аккаунт " .. ACCOUNT_ID .. " Coconut Canister")
end

local function EquipPorcelain()
    local args = {{"Equip",{Category="Accessory",Type="Porcelain Port-O-Hive"}}}
    ReplicatedStorage:WaitForChild("Events"):WaitForChild("ItemPackageEvent"):InvokeServer(unpack(args[1]))
    currentAccessory = "porcelain"
    hasPorcelain = true
    hasCanister = false
    print("✅ Аккаунт " .. ACCOUNT_ID .. " Porcelain Port-O-Hive")
end

local function SpawnCoconut(isCombo)
    local args = {{{Name="Coconut"}}}
    ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlayerActivesCommand"):FireServer(unpack(args[1]))
    if isCombo then
        print("🎯 АККАУНТ " .. ACCOUNT_ID .. " КОМБО КОКОС!")
    else
        print("🥥 Аккаунт " .. ACCOUNT_ID .. " обычный кокос")
    end
end

local function IsComboCoconutPresent()
    local particles = Workspace:FindFirstChild("Particles")
    if not particles then return false end
    for _, obj in pairs(particles:GetChildren()) do
        if obj.Name == "ComboCoconut" and obj.ClassName == "UnionOperation" then
            return true
        end
    end
    return false
end

local function GetCurrentTurn()
    return GetFirebase("turns/current_turn") or 1
end

local function NextTurn()
    local nextTurn = GetCurrentTurn() + 1
    if nextTurn > 5 then nextTurn = 1 end
    SetFirebase("turns/current_turn", nextTurn)
    print("🔄 Аккаунт " .. ACCOUNT_ID .. ": ход перешел к " .. nextTurn)
end

-- ==============================================
-- ИНИЦИАЛИЗАЦИЯ FIREBASE
-- ==============================================
pcall(function()
    if not GetFirebase("turns") then
        SetFirebase("turns", {current_turn=1})
    end
    if not GetFirebase("locks") then
        SetFirebase("locks", {})
    end
end)

-- ==============================================
-- МОНИТОРИНГ ПОЯВЛЕНИЯ / ИСЧЕЗНОВЕНИЯ КОМБО
-- ==============================================
spawn(function()
    while true do
        local present = IsComboCoconutPresent()
        if present and not comboActive then
            comboActive = true
            comboLostTime = nil
            print("🥥 Аккаунт " .. ACCOUNT_ID .. " комбо появилось")
        elseif not present and comboActive then
            comboActive = false
            comboLostTime = tick()
            print("🥥 Аккаунт " .. ACCOUNT_ID .. " комбо исчезло")
            
            if hasSpawnedCombo then
                hasSpawnedCombo = false
                print("✅ Аккаунт " .. ACCOUNT_ID .. " завершил свой цикл комбо")
            end
        end
        task.wait(0.5)
    end
end)

-- ==============================================
-- ТАЙМЕР 15 СЕКУНД ПОСЛЕ КОНЦА ЛЮБОГО КОМБО
-- (кидаем 1 кокос и надеваем канистру, чтобы начать новый набив)
-- ==============================================
spawn(function()
    while true do
        if not comboActive and comboLostTime and tick() - comboLostTime >= 15 then
            if currentAccessory ~= "canister" then
                EquipCanister()
            end
            SpawnCoconut(false) -- это первый кокос нового цикла (comboValue станет 1)
            comboLostTime = nil
        end
        task.wait(1)
    end
end)

-- ==============================================
-- СТРАХОВКА КАНИСТРЫ КАЖДЫЕ 5 СЕКУНД
-- (если комбо < 39, должен быть Coconut Canister)
-- ==============================================
spawn(function()
    while true do
        if localComboValue < 39 and currentAccessory ~= "canister" then
            EquipCanister()
        end
        task.wait(5)
    end
end)

-- ==============================================
-- ОСНОВНАЯ ЛОГИКА ОЧЕРЕДИ СПАВНА КОМБО
-- (запуск 40-го кокоса, когда мой ход и я на 39)
-- ==============================================
spawn(function()
    while true do
        local myTurn = (GetCurrentTurn() == ACCOUNT_ID)
        
        if myTurn and localComboValue == 39 and not comboActive and not hasSpawnedCombo then
            if TryAcquireAtomicLock() then
                if not comboActive then
                    print("🎯 АККАУНТ " .. ACCOUNT_ID .. " ЗАПУСКАЕТ КОМБО ПО ОЧЕРЕДИ!")
                    SpawnCoconut(true) -- это 40-й кокос, comboValue в игре сбросится в 0
                    hasSpawnedCombo = true
                    NextTurn()
                end
                ReleaseAtomicLock()
            end
        end
        
        task.wait(1.5)
    end
end)

-- ==============================================
-- СЛУШАТЕЛЬ СОБЫТИЙ КОМБО (ЛОКАЛЬНЫЙ comboValue)
-- ==============================================
require(ReplicatedStorage.Events).ClientListen("PlayerAbilityEvent", function(data)
    for tag, info in pairs(data) do
        if (tag == "Combo Coconuts" or tag == "ComboCoconuts") and info.Action == "Update" then
            local value = info.Values and info.Values[1] or 0
            localComboValue = value
            
            -- < 39 — должен быть Coconut Canister
            if value < 39 and not hasCanister then
                EquipCanister()
            elseif value == 39 and not hasPorcelain then
                -- на 39 — надеваем Porcelain, чтобы отключить пассивку и контролировать 40-й кокос
                EquipPorcelain()
            end
            
            -- На 5 / 11 / 17 / 23 — кидаем обычный кокос
            for _, sv in pairs(spawnValues) do
                if value == sv then
                    SpawnCoconut(false)
                    break
                end
            end
        end
    end
end)

-- ==============================================
-- ОЧИСТКА СТАРЫХ БЛОКИРОВОК
-- ==============================================
spawn(function()
    while true do
        task.wait(30)
        local lockData = GetFirebase("locks/spawn_lock")
        if lockData and (os.time() - (lockData.timestamp or 0)) > 30 then
            SetFirebase("locks/spawn_lock", nil)
            print("🧨 Принудительно сброшена старая блокировка")
        end
    end
end)

-- ==============================================
-- ДЕБАГ КАЖДЫЕ 10 СЕКУНД
-- ==============================================
spawn(function()
    while true do
        task.wait(10)
        print("📊 Firebase статус:")
        print("   Текущий ход: " .. GetCurrentTurn())
        local lock = GetFirebase("locks/spawn_lock")
        print("   Блокировка: " .. (lock and ("аккаунт " .. tostring(lock.owner)) or "свободна"))
        print("   Локальное комбо: " .. tostring(localComboValue) .. ", comboActive=" .. tostring(comboActive))
    end
end)

print("========================================")
print("✅ FIREBASE ЛОКАЛЬНАЯ ОЧЕРЕДЬ - АККАУНТ " .. ACCOUNT_ID)
print("========================================")
print("🎯 Старт. Ожидание комбо...")
