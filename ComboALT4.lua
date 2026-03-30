local ACCOUNT_ID = 4

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
local comboCounter = 0
local spawnTimer = nil

-- Интерфейс
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ComboCounter"
screenGui.Parent = game:GetService("CoreGui")
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 100, 0, 40)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Text = "0"
label.TextColor3 = Color3.fromRGB(255, 200, 100)
label.Font = Enum.Font.GothamBold
label.TextSize = 20
label.Parent = frame

local function updateCounterDisplay()
    label.Text = tostring(comboCounter)
    if comboCounter == ACCOUNT_ID then
        frame.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    else
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end

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
    print("🥥 Канистра надета")
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
    print("🍶 Фарфор надет")
end

function SpawnCoconut(isCombo)
    local args = {
        {
            Name = "Coconut"
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("PlayerActivesCommand"):FireServer(unpack(args))
    if isCombo then
        print("✅ Аккаунт " .. ACCOUNT_ID .. " КОМБО КОКОС (очередь " .. comboCounter .. ")")
        task.spawn(function()
            task.wait(11)
            SpawnCoconut(false)
        end)
    else
        print("🥥 Аккаунт " .. ACCOUNT_ID .. " обычный кокос")
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

-- Мониторинг появления/исчезновения комбо для счётчика очереди (4 аккаунта)
spawn(function()
    while true do
        local present = IsComboCoconutPresent()
        if present and not coconutActive then
            coconutActive = true
            coconutLostTime = nil
            print("🌟 Комбо появилось")
        elseif not present and coconutActive then
            coconutActive = false
            coconutLostTime = tick()
            comboCounter = comboCounter + 1
            if comboCounter > 4 then comboCounter = 1 end
            updateCounterDisplay()
            print("📊 Счетчик комбо:", comboCounter)
        end
        task.wait(0.5)
    end
end)

local function startSpawnTimer()
    if spawnTimer then
        task.cancel(spawnTimer)
        spawnTimer = nil
    end
    spawnTimer = task.spawn(function()
        task.wait(15)
        if lastValue == 39 and comboCounter == ACCOUNT_ID then
            print("🎯 Аккаунт " .. ACCOUNT_ID .. " кидает КОМБО по таймеру")
            SpawnCoconut(true)
        end
        spawnTimer = nil
    end)
end

require(ReplicatedStorage.Events).ClientListen("PlayerAbilityEvent", function(data)
    for tag, info in pairs(data) do
        if tag == "Combo Coconuts" or tag == "ComboCoconuts" then
            if info.Action == "Update" then
                local value = info.Values and info.Values[1] or 0

                if value < 39 and spawnTimer then
                    task.cancel(spawnTimer)
                    spawnTimer = nil
                end

                if value == 39 and not hasPorcelain then
                    EquipPorcelain()
                end

                if value < 39 and not hasCanister then
                    EquipCanister()
                end

                if value == 11 or value == 17 or value == 23 then
                    SpawnCoconut(false)
                end

                if value == 39 and comboCounter == ACCOUNT_ID and not spawnTimer then
                    startSpawnTimer()
                end

                lastValue = value
            end
        end
    end
end)

spawn(function()
    while true do
        if lastValue ~= 39 and currentAccessory ~= "canister" then
            EquipCanister()
        end
        task.wait(5)
    end
end)

updateCounterDisplay()
print("========================================")
print("✅ Аккаунт " .. ACCOUNT_ID .. " запущен")
print("📊 Счетчик комбо (1-4):", comboCounter)
print("🎯 Комбо кидается через 15 сек после готовности (39 + очередь)")
print("🍶 Фарфор надевается на 39 всегда")
print("🥥 Канистра надевается при <39 всегда")
print("⏱️ Через 11 сек после комбо кидается обычный кокос")
print("🔄 Очередь: 1 → 2 → 3 → 4 → 1...")
print("========================================")
