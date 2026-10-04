shared.KillAllDelay = 0 
shared.AutoWin = true
shared.LoopKill = true

loadstring(game:HttpGet("https://githubusercontent.com"))()

task.spawn(function()
    local p = game:GetService("Players").LocalPlayer
    while task.wait(1) do
        if p.Backpack:FindFirstChild("Knife") or (p.Character and p.Character:FindFirstChild("Knife")) then
            for _, v in pairs(game:GetService("Players"):GetPlayers()) do
                if v ~= p and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                    p.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame
                    task.wait(0.05) -- 検知回避のディレイ
                end
            end
        end
    end
end)
