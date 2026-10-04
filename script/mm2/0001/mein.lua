-- [[ ZenosHub をベースにした完全自動勝利＆避難カスタム ]]
loadstring(game:HttpGet("https://githubusercontent.com"))()

local Players = game:GetService("Players")
local p = Players.LocalPlayer

-- 天井（安置）の座標を自動計算してテレポートする関数
local function teleportToCeiling()
    if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        -- 現在の位置から真上（Y軸+150）の空中（天井の上など）へワープ
        local currentPos = p.Character.HumanoidRootPart.Position
        p.Character.HumanoidRootPart.CFrame = CFrame.new(currentPos.X, currentPos.Y + 150, currentPos.Z)
    end
end

-- 殺人犯（Murderer）を探す関数
local function getMurderer()
    for _, v in pairs(Players:GetPlayers()) do
        if v.Backpack:FindFirstChild("Knife") or (v.Character and v.Character:FindFirstChild("Knife")) then
            return v
        end
    end
    return nil
end

-- メインループ処理（高速検知）
task.spawn(function()
    while task.wait(0.1) do
        if not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then continue end
        
        -- 【1. 保安官（Sheriff）のとき】殺人犯の場所にワープして即射殺
        if p.Backpack:FindFirstChild("Gun") or (p.Character and p.Character:FindFirstChild("Gun")) then
            local murderer = getMurderer()
            if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then
                -- 殺人犯の目の前にワープして銃を撃てるようにする
                p.Character.HumanoidRootPart.CFrame = murderer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
            end
            
        -- 【2. 殺人犯（Murderer）のとき】前回の KillAll も維持
        elseif p.Backpack:FindFirstChild("Knife") or (p.Character and p.Character:FindFirstChild("Knife")) then
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= p and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                    p.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame
                    task.wait(0.05)
                end
            end
            
        -- 【3. 無実（Innocent）のとき】
        else
            -- マップ上に銃が落ちているか確認
            local droppedGun = workspace:FindFirstChild("GunDrop") or workspace:FindFirstChild("Gun")
            
            if droppedGun then
                -- 保安官が死んで銃が落ちたら即座に回収（テレポート）
                p.Character.HumanoidRootPart.CFrame = droppedGun.CFrame
            else
                -- 銃が落ちていない安全な時は、一番上の天井に避難して待機
                teleportToCeiling()
            end
        end
    end
end)

