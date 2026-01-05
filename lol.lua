--[[
    Syu_hub v6.0 | Blobman Kicker & Auto Grab
    Target: Fling Things and People
    Library: Delta Library (UIのみ変更)
]]

-- Delta UI ライブラリを読み込み
local Delta = loadstring(game:HttpGet("https://raw.githubusercontent.com/Delta-Phantom/Delta-Lib/main/Source.lua"))()

-- ■■■ Services ■■■
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ■■■ Variables ■■■
local TargetPlayer = nil
local IsLoopKicking = false
local IsAutoGrabbing = false
local SelectedAmmo = nil -- Blobman or similar
local OriginalPosition = nil -- 戻るための位置保存用

-- ■■■ UI Setup ■■■
local Window = Delta:Window({
    Title = "Syu_hub | Blobman Kick v6",
    Position = UDim2.new(0, 100, 0, 100)
})

-- ■■■ Utility Functions ■■■

-- 通知機能
function SendNotif(title, content)
    Delta:Notify({
        Title = title,
        Description = content,
        Duration = 5
    })
end

-- プレイヤーリストの取得
function GetPlayerNames()
    local names = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    return names
end

-- Blobman (Ammo) を探す
function FindBlobman()
    -- 既に掴んでいる場合はそれを返す
    if LocalPlayer.Character then
        local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
        -- ツールそのものではなく、周囲の物体としてのBlobmanを探す
    end

    local nearest, dist = nil, 500
    for _, v in pairs(Workspace:GetDescendants()) do
        -- Blobmanまたは類似の物理オブジェクトを検索
        if (v.Name == "Blobman" or v.Name == "Ragdoll") and v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") then
            -- プレイヤーのキャラクターではないことを確認
            if not Players:GetPlayerFromCharacter(v) then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and v.HumanoidRootPart then
                    local d = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < dist then
                        dist = d
                        nearest = v
                    end
                end
            end
        end
    end
    return nearest
end

-- Blobmanをスポーンさせる（ゲーム固有のリモート推測）
function SpawnBlobman()
    -- Fling Things and Peopleの一般的なスポーンパスを試行
    -- ※ゲームのアップデートによりパスが変わる可能性があります
    local args = {
        [1] = "Blobman"
    }
    
    -- いくつかの可能性のあるリモートを叩く
    local spawned = false
    local remotes = {
        ReplicatedStorage:FindFirstChild("SpawnItem"),
        ReplicatedStorage:FindFirstChild("CreateItem"),
        Workspace:FindFirstChild("SpawnEvents")
    }

    for _, remote in pairs(remotes) do
        if remote and remote:IsA("RemoteEvent") then
            remote:FireServer(unpack(args))
            spawned = true
        end
    end
    
    if spawned then
        SendNotif("System", "Blobmanのスポーンを試みました")
    else
        SendNotif("Warning", "自動スポーンに失敗しました。手動で出してください。")
    end
end

-- 物理的にくっつけて攻撃する処理
function TeleportAndAttack(targetName)
    local target = Players:FindFirstChild(targetName)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end

    local myHrp = char.HumanoidRootPart
    local targetHrp = target.Character.HumanoidRootPart

    -- 1. 現在位置を保存（戻ってくるため）
    if not OriginalPosition then
        OriginalPosition = myHrp.CFrame
    end

    -- 2. Blobmanを探す
    local ammo = FindBlobman()
    if not ammo then
        SpawnBlobman()
        task.wait(0.2)
        ammo = FindBlobman()
        if not ammo then return end -- それでもなければ中止
    end

    -- 3. Blobmanを自分の近くに持ってくる
    if ammo and ammo:FindFirstChild("HumanoidRootPart") then
        for i = 1, 5 do
            ammo.HumanoidRootPart.CFrame = myHrp.CFrame * CFrame.new(0, 0, -2)
            ammo.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
            RunService.RenderStepped:Wait()
        end
    end

    -- 4. 超高速アタック (Hit & Run)
    -- 敵の位置へTP
    myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 1) 
    
    -- 0.01秒待機して物理演算を適用させる（掴んで離す動作のシミュレーション）
    task.wait(0.01) 
    
    -- 敵をFlingするための回転力を付与
    local bv = Instance.new("BodyAngularVelocity")
    bv.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bv.AngularVelocity = Vector3.new(500, 500, 500)
    bv.Parent = myHrp
    
    -- アモ（Blobman）を敵に叩きつける
    if ammo and ammo:FindFirstChild("HumanoidRootPart") then
        ammo.HumanoidRootPart.CFrame = targetHrp.CFrame
        ammo.HumanoidRootPart.Velocity = (targetHrp.Position - myHrp.Position).Unit * 1000
    end

    task.wait(0.05) -- 少しだけ維持
    bv:Destroy()

    -- 5. 元の位置に戻る (Hit & Run完了)
    myHrp.CFrame = OriginalPosition
    myHrp.Velocity = Vector3.new(0,0,0)
    OriginalPosition = nil -- リセット
end

-- ■■■ UI Construction ■■■

-- ターゲット選択セクション
local PlayerDropdown = Window:Dropdown({
    Title = "Select Target Player",
    List = GetPlayerNames(),
    Callback = function(value)
        TargetPlayer = value
        SendNotif("Selected", "Target: " .. value)
    end
})

-- リフレッシュボタン
Window:Button({
    Title = "Refresh Player List",
    Callback = function()
        PlayerDropdown:Refresh(GetPlayerNames())
        SendNotif("Refreshed", "Player list updated.")
    end
})

-- アクションセクション
Window:Label({Title = "Actions", Centered = true})

-- 単発Kickボタン
Window:Button({
    Title = "Kick Target (Hit & Run)",
    Callback = function()
        if TargetPlayer then
            SendNotif("Kicking", "Attacking " .. TargetPlayer)
            TeleportAndAttack(TargetPlayer)
        else
            SendNotif("Error", "プレイヤーを選択してください")
        end
    end
})

-- ループKickトグル
local LoopToggle = Window:Toggle({
    Title = "Loop Kick Target",
    Callback = function(state)
        IsLoopKicking = state
        if state and TargetPlayer then
            SendNotif("Loop Check", "Loop started for " .. TargetPlayer)
            task.spawn(function()
                while IsLoopKicking and TargetPlayer do
                    TeleportAndAttack(TargetPlayer)
                    task.wait(0.1) -- 連続攻撃の間隔
                end
            end)
        end
    end
})

-- 全員Kickボタン
Window:Button({
    Title = "Kick ALL Loop",
    Callback = function()
        IsLoopKicking = not IsLoopKicking
        if IsLoopKicking then
            SendNotif("ALL KICK", "Starting massacre...")
            task.spawn(function()
                while IsLoopKicking do
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and IsLoopKicking then
                            TeleportAndAttack(p.Name)
                            task.wait(0.2)
                        end
                    end
                    task.wait()
                end
            end)
        else
            SendNotif("Stopped", "All Kick Stopped.")
        end
    end
})

-- その他セクション
Window:Label({Title = "Misc / Settings", Centered = true})

Window:Button({
    Title = "Force Spawn Blobman",
    Callback = function()
        SpawnBlobman()
    end
})

-- 初期化完了
Delta:Ready()
SendNotif("Syu_hub Loaded", "Version 6.0 with Delta UI\nReady to kick.")
