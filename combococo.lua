local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer

-- ==============================================
-- ВИЗУАЛЬНАЯ КОНСОЛЬ
-- ==============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ComboConsole"
screenGui.Parent = game:GetService("CoreGui")
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 380, 0, 250)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BackgroundTransparency = 0.2
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 25)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30, 1, 0)
title.Position = UDim2.new(0, 8, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🥥 Combo Console"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -25, 0.5, -10)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    screenGui.Enabled = not screenGui.Enabled
end)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -10, 1, -35)
scrollFrame.Position = UDim2.new(0, 5, 0, 30)
scrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
scrollFrame.BackgroundTransparency = 0.3
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = mainFrame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 6)
scrollCorner.Parent = scrollFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 2)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scrollFrame

-- ==============================================
-- ФУНКЦИЯ ДОБАВЛЕНИЯ В КОНСОЛЬ
-- ==============================================
local messageCount = 0
local maxMessages = 30

local function addToConsole(text, color)
    messageCount = messageCount + 1
    
    local msgFrame = Instance.new("Frame")
    msgFrame.Size = UDim2.new(1, -10, 0, 18)
    msgFrame.BackgroundColor3 = color or Color3.fromRGB(40, 40, 40)
    msgFrame.BackgroundTransparency = 0.3
    msgFrame.Parent = scrollFrame
    
    local msgCorner = Instance.new("UICorner")
    msgCorner.CornerRadius = UDim.new(0, 4)
    msgCorner.Parent = msgFrame
    
    local msgText = Instance.new("TextLabel")
    msgText.Size = UDim2.new(1, -5, 1, 0)
    msgText.Position = UDim2.new(0, 5, 0, 0)
    msgText.BackgroundTransparency = 1
    msgText.Text = "[" .. os.date("%H:%M:%S") .. "] " .. text
    msgText.TextColor3 = Color3.fromRGB(255, 255, 255)
    msgText.Font = Enum.Font.Gotham
    msgText.TextSize = 11
    msgText.TextXAlignment = Enum.TextXAlignment.Left
    msgText.Parent = msgFrame
    
    if messageCount > maxMessages then
        local children = scrollFrame:GetChildren()
        for _, child in pairs(children) do
            if child:IsA("Frame") and child ~= msgFrame then
                child:Destroy()
                messageCount = messageCount - 1
                break
            end
        end
    end
    
    task.wait()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    scrollFrame.CanvasPosition = Vector2.new(0, layout.AbsoluteContentSize.Y)
end

-- Перехватываем print
local oldPrint = print
print = function(...)
    local args = {...}
    local str = ""
    for i, v in pairs(args) do
        str = str .. tostring(v) .. (i < #args and " " or "")
    end
    addToConsole(str, Color3.fromRGB(40, 40, 40))
    oldPrint(...)
end

-- ==============================================
-- ОСНОВНОЙ СКРИПТ
-- ==============================================
local lastValue = -1
local coconutActive = false
local coconutLostTime = nil
local sentValues = {}
local currentAccessory = "none"
local timerThread = nil

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
            if timerThread then
                task.cancel(timerThread)
                timerThread = nil
            end
            print("🥥 ComboCoconut появился")
        elseif not present and coconutActive then
            coconutActive = false
            coconutLostTime = tick()
            print("🥥 ComboCoconut исчез - начало отсчета 15 сек")
            
            -- Запускаем таймер обратного отсчета
            if timerThread then task.cancel(timerThread) end
            timerThread = task.spawn(function()
                for i = 15, 1, -1 do
                    print("⏱️ До спавна кокоса: " .. i .. " сек")
                    task.wait(1)
                end
                print("⏰ 15 секунд прошло! Спавн кокоса...")
            end)
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
            if timerThread then
                task.cancel(timerThread)
                timerThread = nil
            end
        end
        task.wait(1)
    end
end)

-- Страховка каждые 5 секунд
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
                
                if value < 39 then
                    if currentAccessory ~= "canister" then
                        EquipCanister()
                    end
                elseif value == 39 then
                    if currentAccessory ~= "porcelain" and not sentValues[39] then
                        EquipPorcelain()
                        sentValues[39] = true
                    end
                end
                
                if value ~= lastValue then
                    print("🥥 Комбо значение: " .. value)
                    
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

print("✅ Combo Coconut менеджер с визуальной консолью")
print("📱 Отсчет 15 секунд отображается в консоли")
