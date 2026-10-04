loadstring(game:HttpGet("https://githubusercontent.com"))()

local Players = game:GetService("Players")
local p = Players.LocalPlayer

local function teleportToCeiling()
    if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        local currentPos = p.Character.HumanoidRootPart.Position
        p.Character.HumanoidRootPart.CFrame = CFrame.new(currentPos.X, currentPos.Y + 150, currentPos.Z)
    end
end

local function getMurderer()
    for _, v in pairs(Players:GetPlayers()) do
        if v.Backpack:FindFirstChild("Knife") or (v.Character and v.Character:FindFirstChild("Knife")) then
            return v
        end
    end
    return nil
end

task.spawn(function()
    while task.wait(0.1) do
        if not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then continue end
        
        if p.Backpack:FindFirstChild("Gun") or (p.Character and p.Character:FindFirstChild("Gun")) then
            local murderer = getMurderer()
            if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.CFrame = murderer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
            end
            
        elseif p.Backpack:FindFirstChild("Knife") or (p.Character and p.Character:FindFirstChild("Knife")) then
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= p and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                    p.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame
                    task.wait(0.05)
                end
            end
            
        else
            local droppedGun = workspace:FindFirstChild("GunDrop") or workspace:FindFirstChild("Gun")
            if droppedGun then
                p.Character.HumanoidRootPart.CFrame = droppedGun.CFrame
            else
                teleportToCeiling()
            end
        end
    end
end)


