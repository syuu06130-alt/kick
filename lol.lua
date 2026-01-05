--[[
    Syu_hub v6.1 | Blobman Kicker & Auto Grab
    Target: Fling Things and People
    Status: Fixed (NaN Crash & Black Screen Resolved)
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
    print("[" .. title .. "] " .. content)
    -- スターターGUIが使える場合は通知を出す（オプション）
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title;
            Text = content;
            Duration = 3;
        })
    end)
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

function FindBlobman()
    local nearest, dist = nil, 500
    for _, v in pairs(Workspace:GetDescendants()) do
        if (v.Name == "Blobman" or v.Name == "Ragdoll") and v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") then
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

function SpawnBlobman()
    local args = { [1] = "Blobman" }
    local spawned = false
    local remotes = {
        ReplicatedStorage:FindFirstChild("SpawnItem"),
        ReplicatedStorage:FindFirstChild("CreateItem"),
        Workspace:FindFirstChild("SpawnEvents")
    }
    for _, remote in pairs(remotes) do
        if remote and remote:IsA("RemoteEvent") then
            pcall(function()
                remote:FireServer(unpack(args))
                spawned = true
            end)
        end
    end
    if spawned then
        SendNotif("System", "Spawn request sent")
    end
end

-- ■■■ Core Attack Logic (Fixed NaN Crash) ■■■
function TeleportAndAttack(targetName)
    local target = Players:FindFirstChild(targetName)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local myHrp = char.HumanoidRootPart
    local targetHrp = target.Character.HumanoidRootPart
    local humanoid = char:FindFirstChild("Humanoid")
    
    -- 位置保存
    if not OriginalPosition then
        OriginalPosition = myHrp.CFrame
    end
    
    -- 弾（Blobman）の確保
    local ammo = FindBlobman()
    if not ammo then
        SpawnBlobman()
        task.wait(0.2)
        ammo = FindBlobman()
        if not ammo then return end
    end
    
    -- 弾の準備（CFrame操作時の安全策）
    if ammo and ammo:FindFirstChild("HumanoidRootPart") then
        local safeCFrame = myHrp.CFrame * CFrame.new(0, 0, -2)
        for i = 1, 3 do
            if ammo and ammo:FindFirstChild("HumanoidRootPart") then
                ammo.HumanoidRootPart.CFrame = safeCFrame
                ammo.HumanoidRootPart.Velocity = Vector3.zero
                ammo.HumanoidRootPart.RotVelocity = Vector3.zero
            end
            RunService.RenderStepped:Wait()
        end
    end
    
    -- ターゲットへテレポート
    myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 1)
    
    -- 回転力を付与
    local bv = Instance.new("BodyAngularVelocity")
    bv.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bv.AngularVelocity = Vector3.new(500, 500, 500)
    bv.Parent = myHrp
    
    -- 攻撃実行（NaNチェック付き）
    if ammo and ammo:FindFirstChild("HumanoidRootPart") then
        ammo.HumanoidRootPart.CFrame = targetHrp.CFrame
        
        local direction = targetHrp.Position - myHrp.Position
        -- 距離が極端に近い場合の0除算回避
        if direction.Magnitude > 0.1 then
            ammo.HumanoidRootPart.Velocity = direction.Unit * 1000
        else
            -- 重なっている場合は上へ飛ばす
            ammo.HumanoidRootPart.Velocity = Vector3.new(0, 1000, 0)
        end
    end
    
    task.wait(0.05)
    if bv then bv:Destroy() end
    
    -- 元の位置へ戻る
    if OriginalPosition then
        myHrp.CFrame = OriginalPosition
        myHrp.Velocity = Vector3.zero
        myHrp.RotVelocity = Vector3.zero
        OriginalPosition = nil
    end
    
    -- ■■ カメラ修正（ブラックアウト対策） ■■
    if humanoid then
        Workspace.CurrentCamera.CameraSubject = humanoid
    end
end

-- ■■■ UI Construction ■■■
-- 既存のGUIがあれば削除
if game.CoreGui:FindFirstChild("SyuHubUI") then
    game.CoreGui.SyuHubUI:Destroy()
end
if LocalPlayer.PlayerGui:FindFirstChild("SyuHubUI") then
    LocalPlayer.PlayerGui.SyuHubUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SyuHubUI"
ScreenGui.ResetOnSpawn = false

-- 親の設定（安全策）
if LocalPlayer:FindFirstChild("PlayerGui") then
    ScreenGui.Parent = LocalPlayer.PlayerGui
else
    ScreenGui.Parent = game.CoreGui
end

-- メインフレーム
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 400)
MainFrame.Position = UDim2.new(0.5, -175, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 1
MainFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
MainFrame.Parent = ScreenGui
MainFrame.Active = true
MainFrame.Draggable = true -- シンプルなドラッグ有効化

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = MainFrame

-- タイトルバー
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.Text = "Syu_hub v6.1 Stable"
TitleLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- 最小化ボタン
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -70, 0, 5)
MinimizeBtn.Text = "−"
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MinimizeBtn.TextColor3 = Color3.new(1,1,1)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 20
MinimizeBtn.Parent = TitleBar
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 8)

-- 閉じるボタン
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.Text = "×"
CloseBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

-- コンテンツエリア
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -50)
ScrollFrame.Position = UDim2.new(0, 10, 0, 45)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 550)
ScrollFrame.Parent = MainFrame

-- プレイヤー選択
local PlayerDropdown = Instance.new("TextButton")
PlayerDropdown.Size = UDim2.new(1, 0, 0, 35)
PlayerDropdown.Position = UDim2.new(0, 0, 0, 10)
PlayerDropdown.Text = "▼ Select Target"
PlayerDropdown.TextColor3 = Color3.new(1,1,1)
PlayerDropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
PlayerDropdown.Font = Enum.Font.Gotham
PlayerDropdown.TextSize = 14
PlayerDropdown.Parent = ScrollFrame
Instance.new("UICorner", PlayerDropdown).CornerRadius = UDim.new(0, 6)

local DropdownMenu = Instance.new("ScrollingFrame")
DropdownMenu.Size = UDim2.new(1, 0, 0, 0) -- 初期は閉じる
DropdownMenu.Position = UDim2.new(0, 0, 0, 50)
DropdownMenu.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
DropdownMenu.Visible = false
DropdownMenu.Parent = ScrollFrame
Instance.new("UICorner", DropdownMenu).CornerRadius = UDim.new(0, 6)
local MenuLayout = Instance.new("UIListLayout")
MenuLayout.Parent = DropdownMenu

local function UpdatePlayerList()
    for _, c in pairs(DropdownMenu:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local players = GetPlayerNames()
    for _, name in pairs(players) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.Text = name
        btn.TextColor3 = Color3.new(1,1,1)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        btn.Parent = DropdownMenu
        btn.MouseButton1Click:Connect(function()
            TargetPlayer = name
            PlayerDropdown.Text = "Target: " .. name
            DropdownMenu.Visible = false
            DropdownMenu.Size = UDim2.new(1, 0, 0, 0)
        end)
    end
    DropdownMenu.CanvasSize = UDim2.new(0,0,0, #players * 30)
end

PlayerDropdown.MouseButton1Click:Connect(function()
    if DropdownMenu.Visible then
        DropdownMenu.Visible = false
        DropdownMenu.Size = UDim2.new(1, 0, 0, 0)
    else
        UpdatePlayerList()
        DropdownMenu.Visible = true
        DropdownMenu.Size = UDim2.new(1, 0, 0, 150)
    end
end)

-- ボタン生成ヘルパー
local function CreateBtn(text, order, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Position = UDim2.new(0, 0, 0, 210 + (order * 50))
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = ScrollFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ボタン配置
CreateBtn("🎯 Kick Target (Hit & Run)", 0, Color3.fromRGB(60, 80, 120), function()
    if TargetPlayer then
        SendNotif("Action", "Attacking " .. TargetPlayer)
        TeleportAndAttack(TargetPlayer)
    else
        SendNotif("Error", "Select a player first")
    end
end)

local LoopBtn
LoopBtn = CreateBtn("🔄 Loop Kick: OFF", 1, Color3.fromRGB(45, 45, 55), function()
    IsLoopKicking = not IsLoopKicking
    if IsLoopKicking then
        if not TargetPlayer then IsLoopKicking = false return end
        LoopBtn.Text = "🔄 Loop Kick: ON"
        LoopBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
        task.spawn(function()
            while IsLoopKicking and TargetPlayer do
                TeleportAndAttack(TargetPlayer)
                task.wait(0.15) -- 安定のため少し待機時間を増やす
            end
            IsLoopKicking = false
            LoopBtn.Text = "🔄 Loop Kick: OFF"
            LoopBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        end)
    else
        LoopBtn.Text = "🔄 Loop Kick: OFF"
        LoopBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    end
end)

local KickAllBtn
KickAllBtn = CreateBtn("💀 Kick ALL: OFF", 2, Color3.fromRGB(45, 45, 55), function()
    IsAllKicking = not IsAllKicking
    IsLoopKicking = false
    if IsAllKicking then
        KickAllBtn.Text = "💀 Kick ALL: ON"
        KickAllBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
        task.spawn(function()
            while IsAllKicking do
                for _, p in pairs(Players:GetPlayers()) do
                    if not IsAllKicking then break end
                    if p ~= LocalPlayer then
                        TeleportAndAttack(p.Name)
                        task.wait(0.1)
                    end
                end
                task.wait(0.5)
            end
        end)
    else
        KickAllBtn.Text = "💀 Kick ALL: OFF"
        KickAllBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    end
end)

CreateBtn("🧊 Force Spawn Blobman", 3, Color3.fromRGB(80, 60, 100), function()
    SpawnBlobman()
end)

-- ウィンドウ制御
MinimizeBtn.MouseButton1Click:Connect(function()
    minimizeLevel = (minimizeLevel + 1) % 2
    if minimizeLevel == 1 then
        MainFrame:TweenSize(UDim2.new(0, 350, 0, 40), "Out", "Quad", 0.3, true)
        ScrollFrame.Visible = false
    else
        MainFrame:TweenSize(UDim2.new(0, 350, 0, 400), "Out", "Quad", 0.3, true)
        ScrollFrame.Visible = true
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    IsLoopKicking = false
    IsAllKicking = false
    ScreenGui:Destroy()
end)

SendNotif("System", "Syu_hub v6.1 Loaded (Crash Fixed)")
