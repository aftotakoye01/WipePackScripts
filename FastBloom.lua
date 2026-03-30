-- PetalPart Teleporter (ковдаун: красные 4 сек, остальные 8 сек)
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
local NEW_PETAL_DELAY = 0.3

-- Ковдаун для разных цветов
local COOLDOWN_RED = 4      -- красные: 4 секунды
local COOLDOWN_OTHER = 8    -- остальные: 8 секунд

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

-- Проверка, красный ли цвет
local function isRedColor(color)
    local redColor = PETAL_COLORS["Red Petal"]
    if not redColor then return false end
    return math.abs(color.R - redColor.R) < 0.01 and
           math.abs(color.G - redColor.G) < 0.01 and
           math.abs(color.B - redColor.B) < 0.01
end

-- Получение ковдауна для цвета
local function getCooldownForColor(color)
    if isRedColor(color) then
        return COOLDOWN_RED
    else
        return COOLDOWN_OTHER
    end
end

-- Проверка, находится ли цвет на ковдауне
local function isOnCooldown(color)
    local colorKey = getColorName(color)
    if not colorKey then return false end
    local cooldownEnd = colorCooldowns[colorKey]
    if cooldownEnd and os.time() < cooldownEnd then
        local remaining = cooldownEnd - os.time()
        local cdType = isRedColor(color) and "красный" or "обычный"
        print(string.format("⏳ %s (%s) на ковдауне еще %.1f сек", colorKey, cdType, remaining))
        return true
    end
    return false
end

-- Установка ковдауна для цвета
local function setCooldown(color)
    local colorKey = getColorName(color)
    if colorKey then
        local cooldownTime = getCooldownForColor(color)
        colorCooldowns[colorKey] = os.time() + cooldownTime
        local cdType = isRedColor(color) and "красный" or "обычный"
        print(string.format("🕐 Установлен ковдаун %d сек для %s (%s)", cooldownTime, colorKey, cdType))
    end
end

-- Остальные функции (поиск, телепорт, баффы) остаются без изменений
-- ... (вставьте сюда все остальные функции из предыдущей версии)

-- ========== ТЕЛЕПОРТ ==========
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
    
    -- Отмагничивание камеры
    local oldCameraType = Camera.CameraType
    local oldCameraCFrame = Camera.CFrame
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = oldCameraCFrame
    
    task.wait(0.05)

    -- Отключение физики
    humanoid.AutoRotate = false
    humanoid.PlatformStand = true
    hrp.Velocity = Vector3.new(0, 0, 0)
    hrp.RotVelocity = Vector3.new(0, 0, 0)

    -- Телепорт к лепестку
    hrp.CFrame = petal.CFrame + Vector3.new(0, 3, 0)
    task.wait(0.1)  -- задержка на лепестке

    -- Возврат
    hrp.CFrame = originalPos
    task.wait(0.05)
    hrp.CFrame = originalPos

    hrp.Velocity = Vector3.new(0, 0, 0)
    hrp.RotVelocity = Vector3.new(0, 0, 0)

    -- Восстановление
    humanoid.PlatformStand = false
    humanoid.AutoRotate = true
    Camera.CameraType = oldCameraType

    hrp.CFrame = hrp.CFrame + Vector3.new(0, 0.5, 0)
    task.wait(0.05)

    print(string.format("✅ ТЕЛЕПОРТ ВЫПОЛНЕН: %s — %s", colorName, reason))
    
    -- Устанавливаем ковдаун
    setCooldown(petal.Color)
    
    isTeleporting = false
end

-- Поиск цели для постоянного телепорта
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

    -- Приоритет красного
    local redColor = PETAL_COLORS["Red Petal"]
    for color, data in pairs(byColor) do
        if redColor and
           math.abs(color.R - redColor.R) < 0.01 and
           math.abs(color.G - redColor.G) < 0.01 and
           math.abs(color.B - redColor.B) < 0.01 then
            return data.part
        end
    end

    -- Ближайший среди уникальных
    local nearest, nearestDist = nil, math.huge
    for _, data in pairs(byColor) do
        if data.dist < nearestDist then
            nearestDist = data.dist
            nearest = data.part
        end
    end
    return nearest
end

-- ========== ПОСТОЯННЫЙ ТЕЛЕПОРТ ==========
task.spawn(function()
    while true do
        if enabled and not isTeleporting then
            local target = findTargetForConstantTeleport()
            if target then
                teleportToPetalAndBack(target, "постоянный")
            end
        end
        task.wait(CONSTANT_TELEPORT_INTERVAL)
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

print("✅ PetalPart Teleporter загружен")
print("📊 Ковдаун: красные лепестки - 4 сек, остальные - 8 сек")
print("Нажмите R чтобы включить/выключить")
