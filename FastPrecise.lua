-- Скрипт: сбор Crosshair по кнопке V с возвратом на исходную (настраиваемая задержка)
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Particles = Workspace:FindFirstChild("Particles")

if not Particles then
    warn("Particles not found")
    return
end

-- ===== НАСТРОЙКИ =====
local COLLECT_DELAY = 0.15        -- задержка между телепортами (сек)
-- =====================

local visited = {}
local isActive = false
local startPosition = nil

-- Создание/обновление индикатора
local function createIndicator(part, isVisited)
    if not part:IsA("BasePart") then return end
    local old = part:FindFirstChild("CrosshairIndicator")
    if old then old:Destroy() end

    local color = isVisited and Color3.new(0,1,0) or Color3.new(1,0,0)
    local gui = Instance.new("BillboardGui")
    gui.Name = "CrosshairIndicator"
    gui.Adornee = part
    gui.Size = UDim2.new(0, 30, 0, 30)
    gui.StudsOffset = Vector3.new(0, 4, 0)
    gui.AlwaysOnTop = true
    gui.Parent = part

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundColor3 = color
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
end

-- Сброс индикаторов (все красные)
local function resetIndicators()
    visited = {}
    for _, obj in ipairs(Particles:GetDescendants()) do
        if obj.Name == "Crosshair" and obj:IsA("BasePart") then
            createIndicator(obj, false)
        end
    end
end

local function getRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function teleportTo(obj)
    local root = getRoot()
    if not root then return end

    local pos
    if obj:IsA("BasePart") then
        pos = obj.Position
    elseif obj:IsA("Model") and obj.PrimaryPart then
        pos = obj.PrimaryPart.Position
    elseif obj:IsA("Model") then
        local part = obj:FindFirstChildWhichIsA("BasePart")
        if part then pos = part.Position end
    end

    if pos then
        root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        visited[obj] = true
        createIndicator(obj, true)
        print("✅ Собран Crosshair", obj.Name)
    end
end

-- Появление новых Crosshair
Particles.DescendantAdded:Connect(function(obj)
    if obj.Name == "Crosshair" and obj:IsA("BasePart") then
        createIndicator(obj, visited[obj] and true or false)
    end
end)

-- Инициализация существующих
for _, obj in ipairs(Particles:GetDescendants()) do
    if obj.Name == "Crosshair" and obj:IsA("BasePart") then
        createIndicator(obj, false)
    end
end

-- Обработка нажатия V
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.V then
        local root = getRoot()
        if root then
            startPosition = root.Position
            isActive = true
            resetIndicators()
            print("▶️ Режим сбора активирован. Задержка:", COLLECT_DELAY, "сек.")
            -- Запускаем цикл сбора в отдельном потоке
            task.spawn(function()
                while isActive do
                    local target = nil
                    for _, obj in ipairs(Particles:GetDescendants()) do
                        if obj.Name == "Crosshair" and obj:IsA("BasePart") and not visited[obj] then
                            target = obj
                            break
                        end
                    end
                    if target then
                        teleportTo(target)
                        task.wait(COLLECT_DELAY)
                    else
                        -- Все собраны – немного подождём и проверим снова
                        task.wait(0.2)
                    end
                end
            end)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.V then
        if isActive and startPosition then
            local root = getRoot()
            if root then
                root.CFrame = CFrame.new(startPosition + Vector3.new(0, 3, 0))
                print("◀️ Возврат на исходную. Режим деактивирован.")
            end
        end
        isActive = false
    end
end)

print("✅ Скрипт готов. Нажмите и удерживайте V для сбора Crosshair. Отпустите – вернётесь назад.")
print("⏱️ Текущая задержка между телепортами:", COLLECT_DELAY, "сек (можно изменить в коде).")
