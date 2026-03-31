local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local currentTool = 1

function equipGummyballer()
    local args = {
        "Equip",
        {
            Category = "Collector",
            Type = "Gummyballer"
        }
    }
    ReplicatedStorage:WaitForChild("Events"):WaitForChild("ItemPackageEvent"):InvokeServer(unpack(args))
    print("Gummyballer")
end

function equipDarkScythe()
    local args = {
        "Equip",
        {
            Type = "Dark Scythe",
            Category = "Collector",
            Amount = 1
        }
    }
    ReplicatedStorage:WaitForChild("Events"):WaitForChild("ItemPackageEvent"):InvokeServer(unpack(args))
    print("Dark Scythe")
end

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.R then
        if currentTool == 1 then
            equipGummyballer()
            currentTool = 2
        else
            equipDarkScythe()
            currentTool = 1
        end
    end
end)
