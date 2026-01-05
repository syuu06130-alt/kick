--[[
    Syu_hub v7.0 | Blobman High-Speed Kidnap & Yeet
    Target: Fling Things and People
    Logic: Teleport -> Auto Grab -> Teleport Back -> Throw
]]

-- ■■■ Services ■■■
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ■■■ Variables ■■■
local TargetPlayer = nil
local IsLoopKicking = false
local IsAllKicking = false
local OriginalPosition = nil
local minimizeLevel = 0

-- ■■■ Utility Functions ■■■
function SendNotif(title, content)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title;
        Text = content;
        Duration = 2;
    })
    print("[" .. title .. "] " .. content)
end

function GetPlayerNames()
    local names = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    return names
end

-- ブロブマン（弾薬）を探す
function FindBlobman()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local nearest, dist = nil, 500
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and (v.Name == "Blobman" or v.Name == "Ragdoll" or v.Name == "OddBlobman") then
            local part = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Torso") or v.PrimaryPart
            if part and not Players:GetPlayerFromCharacter(v) then
                local d = (part.Position - hrp.Position).Magnitude
                if d < dist then
                    dist = d
                    nearest = v
                end
            end
        end
    end
    return nearest
end

-- ブロブマンを強制スポーンさせる
function SpawnBlobman()
    local args = { [1] = "Blobman" }
    local remotesToTry = {
        "SpawnItem", "CreateItem", "SpawnObject", "RequestSpawn", "ItemSpawn"
    }
    
    local spawned = false
    -- ReplicatedStorage内を全検索
    for _, desc in pairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("RemoteEvent") and (string.find(desc.Name, "Spawn") or string.find(desc.Name, "Create")) then
             pcall(function()
                desc:FireServer(unpack(args))
                spawned = true
             end)
        end
    end
    
    if spawned then
        SendNotif("System", "Spawnリクエスト送信完了")
    else
        SendNotif("Error", "Spawnリモートが見つかりません")
    end
end

-- ゲーム内の「掴み」を実行する関数（汎用的な名前で試行）
function TryGrab(targetModel)
    local char = LocalPlayer.Character
    if not char then return end
    
    -- 手（RightHandなど）を探す
    local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
    local targetPart = targetModel:FindFirstChild("HumanoidRootPart") or targetModel:FindFirstChild("Torso")
    
    if hand and targetPart then
        -- 一般的なGrab系Remoteを探して発火
        for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") and (string.find(remote.Name, "Grab") or string.find(remote.Name, "Interact")) then
                pcall(function()
                    remote:FireServer(targetPart)
                end)
            end
        end
    end
end

-- ■■■ 攻撃ロジック（掴んで戻って投げる） ■■■
function TeleportGrabAndThrow(targetName)
    local target = Players:FindFirstChild(targetName)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local myHrp = char.HumanoidRootPart
    local targetHrp = target.Character.HumanoidRootPart
    
    -- 1. 元の場所を記録
    if not OriginalPosition then
        OriginalPosition = myHrp.CFrame
    end

    -- 2. ブロブマン確保（なければ出す）
    local ammo = FindBlobman()
    if not ammo then
        SpawnBlobman()
        RunService.Heartbeat:Wait() -- 1フレーム待つ
        ammo = FindBlobman()
    end
    
    -- もしブロブマンがあれば、まずそれを掴みに行く
    if ammo then
        local ammoPart = ammo:FindFirstChild("HumanoidRootPart") or ammo.PrimaryPart
        if ammoPart then
            myHrp.CFrame = ammoPart.CFrame
            TryGrab(ammo) -- ブロブマンを掴む試行
            RunService.Heartbeat:Wait()
        end
    end

    -- 3. ターゲットへ瞬間移動 (0.01秒相当の速さ)
    myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 1) -- 相手の少し後ろ
    
    -- 4. 掴み処理 (Grab)
    TryGrab(target.Character) -- 相手を掴む試行
    
    -- 物理的にくっつける（Grabが効かない場合の保険）
    if ammo and ammo:FindFirstChild("HumanoidRootPart") then
        ammo.HumanoidRootPart.CFrame = targetHrp.CFrame -- ブロブマンを相手に重ねる
    end
    
    -- 待機 (0.01s)
    local start = os.clock()
    while os.clock() - start < 0.01 do
        RunService.Heartbeat:Wait()
    end
    
    -- 5. 元の場所へ戻る (Teleport Back)
    if OriginalPosition then
        myHrp.CFrame = OriginalPosition
    end
    
    -- 6. 投げる (Throw / Release)
    -- 回転力を加えて離す
    myHrp.Velocity = (myHrp.CFrame.LookVector) * 100
    if ammo and ammo:FindFirstChild("HumanoidRootPart") then
         ammo.HumanoidRootPart.Velocity = (myHrp.CFrame.LookVector) * 300
    end
    
    -- Grab解除のリモートがあればここで送る（省略：多くの場合は離れれば外れるか、Releaseリモートが必要）
    for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") and (string.find(remote.Name, "Release") or string.find(remote.Name, "Drop")) then
            pcall(function() remote:FireServer() end)
        end
    end
    
    -- 待機 (0.01s)
    start = os.clock()
    while os.clock() - start < 0.01 do
        RunService.Heartbeat:Wait()
    end
end

-- ■■■ UI Construction ■■■
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SyuHubFixedV7"
ScreenGui.ResetOnSpawn = false
if game.CoreGui:FindFirstChild("SyuHubFixedV7") then
    game.CoreGui.SyuHubFixedV7:Destroy()
end
ScreenGui.Parent = game.CoreGui

-- メインフレーム
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 420)
MainFrame.Position = UDim2.new(0.5, -160, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = MainFrame

-- タイトル
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 40)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Syu_hub v7.0 (Fast Grab)"
TitleLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 20
TitleLabel.Parent = MainFrame

-- コンテンツ
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -50)
ScrollFrame.Position = UDim2.new(0, 10, 0, 45)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.Parent = MainFrame

-- UI要素作成ヘルパー
local function CreateBtn(text, order, callback, toggle)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.Position = UDim2.new(0, 0, 0, (order - 1) * 45)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Parent = ScrollFrame
    
    local c = Instance.new("UICorner")
    c.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        callback(btn)
    end)
    return btn
end

-- ターゲット入力欄
local TargetBox = Instance.new("TextBox")
TargetBox.Size = UDim2.new(1, 0, 0, 35)
TargetBox.PlaceholderText = "Target Name (Partial works)"
TargetBox.Text = ""
TargetBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
TargetBox.TextColor3 = Color3.new(1,1,1)
TargetBox.Parent = ScrollFrame
local tbc = Instance.new("UICorner")
tbc.Parent = TargetBox

-- ターゲット検索
TargetBox.FocusLost:Connect(function()
    local text = TargetBox.Text:lower()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Name:lower():find(text) then
            TargetPlayer = p.Name
            TargetBox.Text = p.Name
            SendNotif("Target", "Selected: " .. p.Name)
            break
        end
    end
end)

-- Loop Kick Button
CreateBtn("🔄 Loop Kick (Target)", 2, function(btn)
    IsLoopKicking = not IsLoopKicking
    IsAllKicking = false
    
    if IsLoopKicking then
        if not TargetPlayer then
            SendNotif("Error", "名前を入力してください")
            IsLoopKicking = false
            return
        end
        btn.Text = "🔄 Loop Kick: ON"
        btn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        
        -- 高速ループ処理 (Heartbeat)
        task.spawn(function()
            while IsLoopKicking and TargetPlayer do
                TeleportGrabAndThrow(TargetPlayer)
                RunService.Heartbeat:Wait() -- 最速ループ
            end
            btn.Text = "🔄 Loop Kick (Target)"
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end)
    else
        btn.Text = "🔄 Loop Kick (Target)"
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        -- 停止時に元の場所へ戻る
        if OriginalPosition and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = OriginalPosition
            LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
            OriginalPosition = nil
        end
    end
end)

-- Kick ALL Button
CreateBtn("💀 Kick ALL", 3, function(btn)
    IsAllKicking = not IsAllKicking
    IsLoopKicking = false
    
    if IsAllKicking then
        btn.Text = "💀 Kick ALL: ON"
        btn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        
        task.spawn(function()
            while IsAllKicking do
                local players = GetPlayerNames()
                for _, name in pairs(players) do
                    if not IsAllKicking then break end
                    TargetPlayer = name
                    -- 各プレイヤーに対して数回実行して確実に飛ばす
                    for i = 1, 5 do 
                        TeleportGrabAndThrow(name)
                        RunService.Heartbeat:Wait()
                    end
                end
                RunService.Heartbeat:Wait()
            end
            btn.Text = "💀 Kick ALL"
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end)
    else
        btn.Text = "💀 Kick ALL"
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end
end)

-- Force Spawn
CreateBtn("🧊 Force Spawn Blobman", 4, function()
    SpawnBlobman()
end)

-- 最小化ボタン
local MiniBtn = Instance.new("TextButton")
MiniBtn.Size = UDim2.new(0, 30, 0, 30)
MiniBtn.Position = UDim2.new(1, -35, 0, 5)
MiniBtn.Text = "-"
MiniBtn.Parent = MainFrame
MiniBtn.MouseButton1Click:Connect(function()
    if MainFrame.Size.Y.Offset > 50 then
        MainFrame:TweenSize(UDim2.new(0, 320, 0, 40), "Out", "Quad", 0.3)
        ScrollFrame.Visible = false
    else
        MainFrame:TweenSize(UDim2.new(0, 320, 0, 420), "Out", "Quad", 0.3)
        ScrollFrame.Visible = true
    end
end)

-- ドラッグ処理
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

SendNotif("Syu_hub", "v7.0 Fixed Loaded")
