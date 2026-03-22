-- Скрипт для переключения видимости RewardsPopUp по клавише V
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local isHidden = false  -- состояние: скрыты или видны
local savedStates = {}  -- таблица для хранения сохранённых состояний

-- Функция для проверки, является ли объект RewardsPopUp
local function isRewardsPopUp(obj)
    return obj.Name and obj.Name:lower():find("rewards") and obj.Name:lower():find("popup")
end

-- Функция для скрытия объекта
local function hideObject(obj)
    if obj:IsA("ScreenGui") then
        obj.Enabled = false
    elseif obj:IsA("Frame") or obj:IsA("GuiObject") then
        obj.Visible = false
    end
end

-- Функция для показа объекта
local function showObject(obj, savedState)
    if obj:IsA("ScreenGui") then
        obj.Enabled = savedState and savedState.enabled or true
    elseif obj:IsA("Frame") or obj:IsA("GuiObject") then
        obj.Visible = savedState and savedState.visible or true
    end
end

-- Функция для рекурсивного поиска и сохранения/восстановления RewardsPopUp в GUI
local function processRewardsPopUpInGUI(guiObject, action)
    if not guiObject then return end
    
    -- Проверяем текущий объект
    if isRewardsPopUp(guiObject) then
        if action == "hide" then
            -- Сохраняем состояние
            if not savedStates[guiObject] then
                savedStates[guiObject] = {
                    isScreenGui = guiObject:IsA("ScreenGui"),
                    isFrame = guiObject:IsA("Frame"),
                    enabled = guiObject:IsA("ScreenGui") and guiObject.Enabled or nil,
                    visible = guiObject.Visible
                }
            end
            -- Скрываем
            hideObject(guiObject)
            print("🔒 Скрыт: " .. guiObject:GetFullName())
        elseif action == "show" then
            -- Восстанавливаем состояние
            if savedStates[guiObject] then
                showObject(guiObject, savedStates[guiObject])
                print("🔓 Показан: " .. guiObject:GetFullName())
            end
        end
    end
    
    -- Обрабатываем дочерние объекты
    for _, child in ipairs(guiObject:GetChildren()) do
        if child:IsA("GuiObject") or child:IsA("ScreenGui") or child:IsA("Frame") then
            processRewardsPopUpInGUI(child, action)
        end
    end
end

-- Функция для скрытия/показа RewardsPopUp в PlayerGui
local function processRewardsPopUpInPlayerGui(action)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        processRewardsPopUpInGUI(playerGui, action)
        
        -- Также ищем напрямую по имени
        local rewardsPopUp = playerGui:FindFirstChild("RewardsPopUp")
        if rewardsPopUp and isRewardsPopUp(rewardsPopUp) then
            if action == "hide" then
                if not savedStates[rewardsPopUp] then
                    savedStates[rewardsPopUp] = {
                        isScreenGui = rewardsPopUp:IsA("ScreenGui"),
                        isFrame = rewardsPopUp:IsA("Frame"),
                        enabled = rewardsPopUp:IsA("ScreenGui") and rewardsPopUp.Enabled or nil,
                        visible = rewardsPopUp.Visible
                    }
                end
                hideObject(rewardsPopUp)
                print("✅ RewardsPopUp скрыт из PlayerGui")
            elseif action == "show" then
                if savedStates[rewardsPopUp] then
                    showObject(rewardsPopUp, savedStates[rewardsPopUp])
                    print("✅ RewardsPopUp показан в PlayerGui")
                end
            end
        end
        
        -- Ищем похожие названия
        for _, child in ipairs(playerGui:GetChildren()) do
            if isRewardsPopUp(child) then
                if action == "hide" then
                    if not savedStates[child] then
                        savedStates[child] = {
                            isScreenGui = child:IsA("ScreenGui"),
                            isFrame = child:IsA("Frame"),
                            enabled = child:IsA("ScreenGui") and child.Enabled or nil,
                            visible = child.Visible
                        }
                    end
                    hideObject(child)
                    print("✅ " .. child.Name .. " скрыт из PlayerGui")
                elseif action == "show" then
                    if savedStates[child] then
                        showObject(child, savedStates[child])
                        print("✅ " .. child.Name .. " показан в PlayerGui")
                    end
                end
            end
        end
    end
end

-- Функция для скрытия/показа RewardsPopUp в StarterGui
local function processRewardsPopUpInStarterGui(action)
    local starterGui = game:FindFirstChild("StarterGui")
    if starterGui then
        local rewardsPopUp = starterGui:FindFirstChild("RewardsPopUp")
        if rewardsPopUp and isRewardsPopUp(rewardsPopUp) then
            if action == "hide" then
                if not savedStates[rewardsPopUp] then
                    savedStates[rewardsPopUp] = {
                        isScreenGui = rewardsPopUp:IsA("ScreenGui"),
                        isFrame = rewardsPopUp:IsA("Frame"),
                        enabled = rewardsPopUp:IsA("ScreenGui") and rewardsPopUp.Enabled or nil,
                        visible = rewardsPopUp.Visible
                    }
                end
                hideObject(rewardsPopUp)
                print("✅ RewardsPopUp скрыт из StarterGui")
            elseif action == "show" then
                if savedStates[rewardsPopUp] then
                    showObject(rewardsPopUp, savedStates[rewardsPopUp])
                    print("✅ RewardsPopUp показан в StarterGui")
                end
            end
        end
        
        -- Ищем похожие названия
        for _, child in ipairs(starterGui:GetChildren()) do
            if isRewardsPopUp(child) then
                if action == "hide" then
                    if not savedStates[child] then
                        savedStates[child] = {
                            isScreenGui = child:IsA("ScreenGui"),
                            isFrame = child:IsA("Frame"),
                            enabled = child:IsA("ScreenGui") and child.Enabled or nil,
                            visible = child.Visible
                        }
                    end
                    hideObject(child)
                    print("✅ " .. child.Name .. " скрыт из StarterGui")
                elseif action == "show" then
                    if savedStates[child] then
                        showObject(child, savedStates[child])
                        print("✅ " .. child.Name .. " показан в StarterGui")
                    end
                end
            end
        end
    end
end

-- Функция для скрытия/показа RewardsPopUp в CoreGui
local function processRewardsPopUpInCoreGui(action)
    local coreGui = game:FindFirstChild("CoreGui")
    if coreGui then
        for _, gui in ipairs(coreGui:GetChildren()) do
            if isRewardsPopUp(gui) and gui:IsA("ScreenGui") then
                if action == "hide" then
                    if not savedStates[gui] then
                        savedStates[gui] = {
                            isScreenGui = true,
                            enabled = gui.Enabled,
                            visible = gui.Visible
                        }
                    end
                    gui.Enabled = false
                    print("✅ " .. gui.Name .. " отключён в CoreGui")
                elseif action == "show" then
                    if savedStates[gui] then
                        gui.Enabled = savedStates[gui].enabled
                        print("✅ " .. gui.Name .. " включён в CoreGui")
                    end
                end
            end
        end
    end
end

-- Функция для перехвата новых экземпляров RewardsPopUp
local function setupInterceptor()
    -- Перехват в PlayerGui
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    playerGui.ChildAdded:Connect(function(child)
        if isRewardsPopUp(child) then
            if isHidden then
                hideObject(child)
                print("🚫 Перехвачен и скрыт новый: " .. child.Name)
            end
            -- Сохраняем состояние
            if not savedStates[child] then
                savedStates[child] = {
                    isScreenGui = child:IsA("ScreenGui"),
                    isFrame = child:IsA("Frame"),
                    enabled = child:IsA("ScreenGui") and child.Enabled or nil,
                    visible = child.Visible
                }
            end
        end
    end)
    
    -- Перехват в StarterGui
    local starterGui = game:FindFirstChild("StarterGui")
    if starterGui then
        starterGui.ChildAdded:Connect(function(child)
            if isRewardsPopUp(child) then
                if isHidden then
                    hideObject(child)
                    print("🚫 Перехвачен и скрыт новый в StarterGui: " .. child.Name)
                end
                if not savedStates[child] then
                    savedStates[child] = {
                        isScreenGui = child:IsA("ScreenGui"),
                        isFrame = child:IsA("Frame"),
                        enabled = child:IsA("ScreenGui") and child.Enabled or nil,
                        visible = child.Visible
                    }
                end
            end
        end)
    end
    
    -- Перехват в CoreGui
    local coreGui = game:FindFirstChild("CoreGui")
    if coreGui then
        coreGui.ChildAdded:Connect(function(child)
            if isRewardsPopUp(child) and child:IsA("ScreenGui") and isHidden then
                child.Enabled = false
                print("🚫 Перехвачен и отключён новый в CoreGui: " .. child.Name)
                if not savedStates[child] then
                    savedStates[child] = {
                        isScreenGui = true,
                        enabled = child.Enabled,
                        visible = child.Visible
                    }
                end
            end
        end)
    end
end

-- Функция для скрытия всех RewardsPopUp
local function hideAllRewardsPopUp()
    print("🔍 Скрываю все RewardsPopUp...")
    print("--------------------------------------------------")
    
    processRewardsPopUpInPlayerGui("hide")
    processRewardsPopUpInStarterGui("hide")
    processRewardsPopUpInCoreGui("hide")
    
    print("--------------------------------------------------")
    print("✅ Все RewardsPopUp скрыты")
end

-- Функция для показа всех RewardsPopUp
local function showAllRewardsPopUp()
    print("🔍 Показываю все RewardsPopUp...")
    print("--------------------------------------------------")
    
    processRewardsPopUpInPlayerGui("show")
    processRewardsPopUpInStarterGui("show")
    processRewardsPopUpInCoreGui("show")
    
    print("--------------------------------------------------")
    print("✅ Все RewardsPopUp показаны")
end

-- Функция для переключения видимости
local function toggleRewardsPopUp()
    if isHidden then
        showAllRewardsPopUp()
        isHidden = false
    else
        hideAllRewardsPopUp()
        isHidden = true
    end
end

-- Обработчик нажатия клавиши V
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.V then
        toggleRewardsPopUp()
    end
end)

-- Запускаем перехватчик
setupInterceptor()

print("✅ Скрипт управления RewardsPopUp загружен")
print("📌 Нажмите V, чтобы скрыть/показать все окна наград")
print("💡 Текущее состояние: ВИДНЫ")
