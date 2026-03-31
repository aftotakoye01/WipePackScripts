require(ReplicatedStorage.Events).ClientListen("PlayerAbilityEvent", function(data)
    for tag, info in pairs(data) do
        if tag == "Combo Coconuts" or tag == "ComboCoconuts" then
            if info.Action == "Update" then
                local value = info.Values and info.Values[1] or 0
                if value >= 30 then
                    -- Надеваем Petal Belt
                    game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer(table.unpack({
                        [1] = "Equip",
                        [2] = {
                            ["Category"] = "Accessory",
                            ["Type"] = "Petal Belt",
                        },
                    }))
                    task.wait(0.5)
                    -- Надеваем Coconut Belt
                    game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer(table.unpack({
                        [1] = "Equip",
                        [2] = {
                            ["Category"] = "Accessory",
                            ["Type"] = "Coconut Belt",
                        },
                    }))
                end
            end
        end
    end
end)
