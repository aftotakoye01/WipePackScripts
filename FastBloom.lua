-- PetalPart Teleporter (автоматическое отмагничивание камеры перед телепортом)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ========== КОНФИГУРАЦИЯ ==========
local CONSTANT_TELEPORT_INTERVAL = 1.0
local PETAL_PART_NAME = "PetalPart"
local BUFF_THRESHOLD = 4
local MAX_ATTEMPTS = 3
local RETRY_DELAY = 0.2
local COOLDOWN_TIME = 4
local NEW_PETAL_DELAY = 0.3

local PETAL_COLORS = {
    ["Blue Petal"]    = Color3.fromRGB(33, 66, 249),
    ["Black Petal"]   = Color3.fromRGB(11, 11, 11),
    ["White Petal"]   = Color3.fromRGB(249, 249, 249),
    ["Green Petal"]   = Color3.fromRGB(35, 232, 5),
    ["Cyan Petal"]    = Color3.fromRGB(29, 196, 222),
    ["Violet Petal"]  = Color3.fromRGB(94, 38, 177),
    ["Yellow Petal"]  = Color3.fromRGB(238, 204, 79),
    ["Scarlet Petal"] = Color3.fromRGB(171, 19, 19),
    ["Marigold Petal"]= Color3.fromRGB(218, 168, 28),
    ["Red Petal"]     = Color3.fromRGB(249, 34, 34),
}

local isTeleporting = false
local enabled = true
local colorCooldowns = {}

-- ========== СИСТЕМА УПРАВЛЕНИЯ КАМЕРОЙ (автоматическая) ==========
local isCameraDetached = false
local savedCFrame = nil
local cameraConnection = nil

-- Функция для отстыковки камеры
local function detachCamera()
    if isCameraDetached then return end
    
    -- Сохраняем текущую позицию камеры
    savedCFrame = Camera.CFrame
    
    -- Переключаем камеру в ручной режим
    Camera.CameraType = Enum.CameraType.Scriptable
    
    -- Замораживаем камеру на текущей позиции
    Camera.CFrame = savedCFrame
    
    -- Создаём цикл обновления, чтобы камера оставалась на месте
    cameraConnection = RunService.RenderStepped:Connect(function()
        if isCameraDetached then
            Camera.CFrame = savedCFrame
        end
    end)
    
    isCameraDetached = true
    print("📸 Камера отстыкована от персонажа")
end

-- Функция для пристыковки камеры обратно
local function attachCamera()
    if not isCameraDetached then return end
    
    -- Отключаем цикл фиксации камеры
    if cameraConnection then
        cameraConnection:Disconnect()
        cameraConnection = nil
    end
    
    -- Возвращаем камере стандартный режим
    Camera.CameraType = Enum.CameraType.Custom
    
    isCameraDetached = false
    print("📸 Камера пристыкована к персонажу")
end

-- ========== ВСПОМОГАТЕЛЬНЫЕ ==========
local function getColorName(color)
    for name, col in pairs(PETAL_COLORS) do
        if math.abs(col.R - color.R) < 0.01 and
           math.abs(col.G - color.G) < 0.01 and
           math.abs(col.B - color.B) < 0.01 then
            return name
        end
    end
    return "Unknown"
end

local function isOnCooldown(color)
    local colorKey = getColorName(color)
    if not colorKey then return false end
    local cooldownEnd = colorCooldowns[colorKey]
    if cooldownEnd and os.time() < cooldownEnd then
        local remaining = cooldownEnd - os.time()
        print(string.format("⏳ Цвет %s на ковдауне еще %.1f сек", colorKey, remaining))
        return true
    end
    return false
end

local function setCooldown(color)
    local colorKey = getColorName(color)
    if colorKey then
        colorCooldowns[colorKey] = os.time() + COOLDOWN_TIME
        print(string.format("🕐 Установлен ковдаун %d сек для цвета %s", COOLDOWN_TIME, colorKey))
    end
end

local function isColorUnique(color)
    local particles = Workspace:FindFirstChild("Particles")
    if not particles then return true end
    local count = 0
    for _, obj in ipairs(particles:GetChildren()) do
        if obj.Name == PETAL_PART_NAME and obj:IsA("BasePart") then
            if math.abs(obj.Color.R - color.R) < 0.01 and
               math.abs(obj.Color.G - color.G) < 0.01 and
               math.abs(obj.Color.B - color.B) < 0.01 then
                count = count + 1
                if count > 1 then return false end
            end
        end
    end
    return count == 1
end

local function findNearestPetalByColor(targetColor, maxAttempts)
    maxAttempts = maxAttempts or 1
    for attempt = 1, maxAttempts do
        local particles = Workspace:FindFirstChild("Particles")
        if particles then
            local character = LocalPlayer.Character
            if character then
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local best, bestDist = nil, math.huge
                    for _, obj in ipairs(particles:GetChildren()) do
                        if obj.Name == PETAL_PART_NAME and obj:IsA("BasePart") then
                            local col = obj.Color
                            if math.abs(col.R - targetColor.R) < 0.01 and
                               math.abs(col.G - targetColor.G) < 0.01 and
                               math.abs(col.B - targetColor.B) < 0.01 then
                                local dist = (obj.Position - hrp.Position).Magnitude
                                if dist < bestDist then
                                    bestDist = dist
                                    best = obj
                                end
                            end
                        end
                    end
                    if best then return best end
                end
            end
        end
        if attempt < maxAttempts then task.wait(0.1) end
    end
    return nil
end

local function findTargetForConstantTeleport()
    local particles = Workspace:FindFirstChild("Particles")
    if not particles then return nil end

    local character = LocalPlayer.Character
    if not character then return nil end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local byColor = {}
    for _, obj in ipairs(particles:GetChildren()) do
        if obj.Name == PETAL_PART_NAME and obj:IsA("BasePart") then
            local color = obj.Color
            if isOnCooldown(color) then continue end
            
            local dist = (obj.Position - hrp.Position).Magnitude
            local foundKey = nil
            for c, data in pairs(byColor) do
                if math.abs(c.R - color.R) < 0.01 and
                   math.abs(c.G - color.G) < 0.01 and
                   math.abs(c.B - color.B) < 0.01 then
                    foundKey = c
                    break
                end
            end
            if foundKey then
                if dist < byColor[foundKey].dist then
                    byColor[foundKey] = {part = obj, dist = dist, color = color}
                end
            else
                byColor[color] = {part = obj, dist = dist, color = color}
            end
        end
    end

    if not next(byColor) then return nil end

    local redColor = PETAL_COLORS["Red Petal"]
    for color, data in pairs(byColor) do
        if redColor and
           math.abs(color.R - redColor.R) < 0.01 and
           math.abs(color.G - redColor.G) < 0.01 and
           math.abs(color.B - redColor.B) < 0.01 then
            return data.part
        end
    end

    local nearest, nearestDist = nil, math.huge
    for _, data in pairs(byColor) do
        if data.dist < nearestDist then
            nearestDist = data.dist
            nearest = data.part
        end
    end
    return nearest
end

-- ========== ТЕЛЕПОРТ С АВТОМАТИЧЕСКИМ ОТМАГНИЧИВАНИЕМ КАМЕРЫ ==========
local function teleportToPetalAndBack(petal, reason)
    if not petal or isTeleporting then return end
    
    local colorName = getColorName(petal.Color) or "Unknown"
    print(string.format("🎯 НАЙДЕН ЛЕПЕСТОК: %s (%s)", colorName, reason))
    
    isTeleporting = true

    local character = LocalPlayer.Character
    if not character then isTeleporting = false; return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not hrp or not humanoid then isTeleporting = false; return end

    local originalPos = hrp.CFrame
    
    -- === ОТМАГНИЧИВАЕМ КАМЕРУ ПЕРЕД ТЕЛЕПОРТОМ ===
    detachCamera()
    
    -- Небольшая задержка для применения
    task.wait(0.05)

    -- Отключение физики персонажа
    humanoid.AutoRotate = false
    humanoid.PlatformStand = true
    hrp.Velocity = Vector3.new(0, 0, 0)
    hrp.RotVelocity = Vector3.new(0, 0, 0)

    -- Телепорт к лепестку
    hrp.CFrame = petal.CFrame + Vector3.new(0, 3, 0)
    task.wait(0.1)

    -- Возврат на исходную
    hrp.CFrame = originalPos
    task.wait(0.05)
    hrp.CFrame = originalPos  -- двойная фиксация

    hrp.Velocity = Vector3.new(0, 0, 0)
    hrp.RotVelocity = Vector3.new(0, 0, 0)

    -- Восстановление физики
    humanoid.PlatformStand = false
    humanoid.AutoRotate = true

    -- === ПРИСТЫКОВЫВАЕМ КАМЕРУ ОБРАТНО ===
    attachCamera()

    -- Коррекция высоты
    hrp.CFrame = hrp.CFrame + Vector3.new(0, 0.5, 0)
    task.wait(0.05)

    print(string.format("✅ ТЕЛЕПОРТ ВЫПОЛНЕН: %s — %s", colorName, reason))
    
    setCooldown(petal.Color)
    isTeleporting = false
end

-- ========== ПОСТОЯННЫЙ ТЕЛЕПОРТ ==========
task.spawn(function()
    while true do
        if enabled and not isTeleporting then
            local target = findTargetForConstantTeleport()
            if target then
                teleportToPetalAndBack(target, "постоянный (каждую сек)")
            end
        end
        task.wait(CONSTANT_TELEPORT_INTERVAL)
    end
end)

-- ========== МОМЕНТАЛЬНАЯ РЕАКЦИЯ НА НОВЫЙ ЦВЕТ ==========
local particles = Workspace:FindFirstChild("Particles")
if particles then
    particles.ChildAdded:Connect(function(child)
        if enabled and not isTeleporting and child.Name == PETAL_PART_NAME and child:IsA("BasePart") then
            local colorName = getColorName(child.Color)
            print(string.format("🔍 ОБНАРУЖЕН НОВЫЙ ЛЕПЕСТОК: %s, задержка %.1f сек...", colorName, NEW_PETAL_DELAY))
            
            task.wait(NEW_PETAL_DELAY)
            
            if not child.Parent then
                print(string.format("⚠️ Лепесток %s был удалён за время задержки", colorName))
                return
            end
            
            if isOnCooldown(child.Color) then
                print(string.format("⏸️ Цвет %s на ковдауне, пропускаем", colorName))
                return
            end
            
            if isColorUnique(child.Color) then
                print(string.format("⚡ УНИКАЛЬНЫЙ ЦВЕТ! Моментальный телепорт к %s", colorName))
                teleportToPetalAndBack(child, "новый уникальный цвет (моментально)")
            else
                print(string.format("ℹ️ Цвет %s уже существует в мире, пропускаем", colorName))
            end
        end
    end)
end

-- ========== БАФФЫ ==========
local activeBuffs = {}

local function fetchPlayerStats()
    local event = ReplicatedStorage:FindFirstChild("Events")
    if not event then return nil end
    local func = event:FindFirstChild("RetrievePlayerStats")
    if not func then return nil end
    local success, result = pcall(function()
        return func:InvokeServer()
    end)
    return success and result or nil
end

local function collectBuffs(data, results)
    if type(data) ~= "table" then return end
    if data.Src and data.Start and data.Dur then
        if PETAL_COLORS[data.Src] then
            table.insert(results, data)
        end
    end
    for _, v in pairs(data) do
        if type(v) == "table" then
            collectBuffs(v, results)
        end
    end
end

task.spawn(function()
    while true do
        if enabled then
            local stats = fetchPlayerStats()
            if stats then
                local buffs = {}
                collectBuffs(stats, buffs)
                local seenBuffs = {}

                for _, buff in ipairs(buffs) do
                    local id = buff.Start
                    seenBuffs[id] = true
                    local src = buff.Src
                    local targetColor = PETAL_COLORS[src]
                    if not targetColor then continue end

                    local remaining = (buff.Start + buff.Dur) - os.time()
                    if remaining < 0 then remaining = 0 end

                    if remaining > 0 and remaining < BUFF_THRESHOLD then
                        if isOnCooldown(targetColor) then
                            continue
                        end
                        
                        if not activeBuffs[id] then
                            activeBuffs[id] = { attempts = 0 }
                        end
                        local state = activeBuffs[id]
                        if state.attempts < MAX_ATTEMPTS then
                            state.attempts = state.attempts + 1
                            print(string.format("⏰ БАФФ %s истекает через %.1f сек! Попытка %d/%d", src, remaining, state.attempts, MAX_ATTEMPTS))
                            local petal = findNearestPetalByColor(targetColor, 3)
                            if petal then
                                teleportToPetalAndBack(petal, string.format("%s < %dс (попытка %d)", src, BUFF_THRESHOLD, state.attempts))
                            end
                        end
                    else
                        activeBuffs[id] = nil
                    end
                end

                for id in pairs(activeBuffs) do
                    if not seenBuffs[id] then
                        activeBuffs[id] = nil
                    end
                end
            end
        end
        task.wait(1.0)
    end
end)

-- ========== ПЕРЕКЛЮЧЕНИЕ ПО R ==========
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.R then
        enabled = not enabled
        if enabled then
            print("🟢 Скрипт включен")
        else
            print("🔴 Скрипт выключен")
        end
    end
end)

print("✅ PetalPart Teleporter (автоматическое отмагничивание камеры) загружен")
print("📸 Камера автоматически отстыковывается перед телепортом и пристыковывается после")
print("Нажмите R чтобы включить/выключить скрипт")
