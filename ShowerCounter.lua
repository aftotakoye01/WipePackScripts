-- === ФИНАЛЬНЫЙ СКРИПТ (таймер только от звезды, лимит токенов просто сбрасывает счётчик) ===
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Particles = Workspace:FindFirstChild("Particles")

if not Particles then
    warn("Папка Particles не найдена")
    return
end

-- ===== НАСТРОЙКИ =====
local COOLDOWN_TIME = 20               -- таймер после звезды (сек)
local TARGET_AMOUNT = 25                -- сколько токенов для сброса
local LIFESPAN_MULTIPLIER = 1.24        -- ваш множитель способностей
local COLLECT_THRESHOLD_FACTOR = 0.9    -- порог сбора (90% от полного времени)
-- =====================

-- Базовое время токенов (ID -> секунды) – оставляем вашу таблицу
local tokenBaseLifetimes = {
    [65867881] = 4,   -- Haste
    [1629649299] = 4, -- Focus
    [1442700745] = 24, -- Rage
    [1629547638] = 4, -- Token Link
    [2499514197] = 8, -- Honey Mark
    [2499540966] = 8, -- Pollen Mark
    [1472256444] = 8, -- Baby Love
    [253828517] = 8,  -- Melody
    [1442764904] = 4, -- Pollen Bomb
    [1442725244] = 4, -- Pollen Bomb (alt)
    [1442859163] = 4, -- Red Boost
    [3877732821] = 4, -- White Boost
    [1442863423] = 4, -- Blue Boost
    [4519523935] = 4, -- Triangulate
    [4528379338] = 4, -- Mark Surge
    [4519549299] = 4, -- Inferno
    [4528208186] = 8, -- Flame Fuel
    [4528414666] = 8, -- Summon Frog
    [8083436978] = 4, -- Blue Balloon
    [8083943936] = 24, -- Surprise Balloon
    [8173559749] = 8, -- Target Practice
    [1671281844] = 12, -- Beamstorm
    [1104415222] = 4, -- Scratch
    [1753904608] = 16, -- Tabby Love
    [2319100769] = 8, -- Fetch
    [2305425690] = 8, -- Puppy Love
    [1472532912] = 15, -- Polar Bear
    [1472491940] = 15, -- Black Bear
    [1472425802] = 15, -- Brown Bear
    [2032949183] = 15, -- Mother Bear
    [1472580249] = 15, -- Panda
    [1489734171] = 15, -- Science Bear
    [1874564120] = 12, -- Pulse
    [1874704640] = 24, -- Red Bomb Sync
    [1874692303] = 24, -- Blue Bomb Sync
    [177997841] = 4,   -- Glob
    [1839454544] = 4,  -- Gumdrop Barrage
    [3582501342] = 24, -- Rain Cloud
    [3582519526] = 24, -- Tornado
    [5877939956] = 12, -- Glitch
    [5877998606] = 16, -- Mind Hack
    [2000457501] = 8,  -- Inspire
    [6077288982] = 16, -- Festive Mark
}

-- ID, которые игнорируем (снежинка и частые не-способности)
local IGNORE_IDS = {
    [6087969886] = true,
    [1472135114] = true,
    [1952682401] = true,
    [2028574353] = true,
    [1952796032] = true,
    [2028453802] = true,
    [1952740625] = true,
    [1838129169] = true,
}

-- Состояние
local currentCount = 0
local timerActive = false
local endTime = 0
local tokenSpawnTimes = {}

-- Функция проверки WarningDisk (Beesmas Light)
local function isTargetWarningDisk(obj)
    if obj.Name ~= "WarningDisk" or not obj:IsA("BasePart") then return false end
    local r, g, b = obj.Color.R, obj.Color.G, obj.Color.B
    if math.abs(r - 0.988) > 0.01 or math.abs(g) > 0.01 or math.abs(b - 0.0235) > 0.01 then return false end
    local sx, sy, sz = obj.Size.X, obj.Size.Y, obj.Size.Z
    if math.abs(sx - 8) > 0.1 or math.abs(sy - 0.4) > 0.05 or math.abs(sz - 8) > 0.1 then return false end
    local mesh = obj:FindFirstChildOfClass("CylinderMesh")
    if not mesh then return false end
    local mx, my, mz = mesh.Scale.X, mesh.Scale.Y, mesh.Scale.Z
    if math.abs(mx - 0.9) > 0.05 or math.abs(my - 0.4) > 0.05 or math.abs(mz - 0.9) > 0.05 then return false end
    return true
end

local function getTextureId(texture)
    local id = texture:match("id=(%d+)") or texture:match("rbxassetid://(%d+)")
    return id and tonumber(id)
end

-- GUI (без изменений)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BeesmasLightTracker"
screenGui.Parent = PlayerGui
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 110)
mainFrame.Position = UDim2.new(0.5, -125, 0.9, -55)
mainFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
mainFrame.BackgroundTransparency = 0.3
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 20)
title.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
title.Text = "Beesmas Light Tracker"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.Parent = mainFrame

local counterLabel = Instance.new("TextLabel")
counterLabel.Size = UDim2.new(1, 0, 0, 25)
counterLabel.Position = UDim2.new(0, 0, 0.2, 0)
counterLabel.BackgroundTransparency = 1
counterLabel.Text = "0/" .. TARGET_AMOUNT
counterLabel.TextColor3 = Color3.new(1, 1, 1)
counterLabel.Font = Enum.Font.SourceSansBold
counterLabel.TextSize = 20
counterLabel.Parent = mainFrame

local progressBg = Instance.new("Frame")
progressBg.Size = UDim2.new(0.9, 0, 0, 10)
progressBg.Position = UDim2.new(0.05, 0, 0.45, 0)
progressBg.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
progressBg.BorderSizePixel = 0
progressBg.Parent = mainFrame

local progressBar = Instance.new("Frame")
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.BackgroundColor3 = Color3.new(0, 1, 0)
progressBar.BorderSizePixel = 0
progressBar.Parent = progressBg

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(1, 0, 0, 25)
timerLabel.Position = UDim2.new(0, 0, 0.65, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = ""
timerLabel.TextColor3 = Color3.new(1, 0.8, 0)
timerLabel.Font = Enum.Font.SourceSansBold
timerLabel.TextSize = 22
timerLabel.Parent = mainFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -25, 0, 2)
closeBtn.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 12
closeBtn.Parent = mainFrame
closeBtn.MouseButton1Click:Connect(function()
    screenGui.Enabled = false
end)

local function updateDisplay()
    counterLabel.Text = currentCount .. "/" .. TARGET_AMOUNT
    local percent = currentCount / TARGET_AMOUNT
    progressBar.Size = UDim2.new(percent, 0, 1, 0)
    if timerActive then
        local remaining = endTime - tick()
        if remaining <= 0 then
            timerLabel.Text = ""
            timerActive = false
        else
            timerLabel.Text = string.format("%.1f с", remaining)
        end
    else
        timerLabel.Text = ""
    end
end

-- Появление токена – запоминаем время
Workspace.DescendantAdded:Connect(function(obj)
    if obj.Name == "C" and obj:IsA("BasePart") then
        local front = obj:FindFirstChild("FrontDecal")
        if front and front:IsA("Decal") then
            local id = getTextureId(front.Texture)
            if id and not IGNORE_IDS[id] and tokenBaseLifetimes[id] then
                tokenSpawnTimes[obj] = tick()
            end
        end
    end
end)

-- Исчезновение токена – проверяем сбор (только если не на кулдауне)
game.DescendantRemoving:Connect(function(obj)
    if timerActive then return end  -- во время кулдауна токены не считаем

    local spawnTime = tokenSpawnTimes[obj]
    if spawnTime then
        local front = obj:FindFirstChild("FrontDecal")
        local id = front and getTextureId(front.Texture) or 0
        local base = tokenBaseLifetimes[id]
        if base then
            local fullLifetime = base * LIFESPAN_MULTIPLIER
            local lifetime = tick() - spawnTime
            if lifetime < fullLifetime * COLLECT_THRESHOLD_FACTOR then
                currentCount = currentCount + 1
                print(string.format("✅ Собран токен ID %d за %.2f сек, теперь %d/%d", id, lifetime, currentCount, TARGET_AMOUNT))
                if currentCount >= TARGET_AMOUNT then
                    -- Достигли лимита: просто сбрасываем счётчик, таймер НЕ запускаем
                    print("📊 Достигнут лимит в 25 токенов. Счётчик сброшен.")
                    currentCount = 0
                    tokenSpawnTimes = {}
                end
            else
                print(string.format("⏳ Деспавн ID %d через %.2f сек", id, lifetime))
            end
        end
        tokenSpawnTimes[obj] = nil
        updateDisplay()
    end
end)

-- Появление WarningDisk (Beesmas Light) – запускаем таймер, если не активен
Particles.DescendantAdded:Connect(function(obj)
    if isTargetWarningDisk(obj) then
        if not timerActive then
            print("⚠️ Звезда обнаружена! Запуск таймера на 20 секунд.")
            timerActive = true
            endTime = tick() + COOLDOWN_TIME
            currentCount = 0
            tokenSpawnTimes = {}
            updateDisplay()
        else
            print("⚠️ Звезда проигнорирована (таймер уже активен).")
        end
    end
end)

-- Цикл обновления GUI
RunService.Heartbeat:Connect(updateDisplay)

-- Горячая клавиша F9
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F9 then
        screenGui.Enabled = not screenGui.Enabled
    end
end)

updateDisplay()
print("✅ Финальный скрипт (таймер только от звезды) запущен. Нажмите F9 для скрытия.")
print("🎯 Цель счётчика:", TARGET_AMOUNT, "токенов (сброс без таймера).")
print("⏳ Таймер 20 секунд запускается только при появлении звезды.")
print("⛔ Во время таймера токены не засчитываются.")
