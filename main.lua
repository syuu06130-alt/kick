--[[
    Syu_hub v6.0 | Blobman Kicker & Auto Grab
    Target: Fling Things and People
    Custom UI Edition (No External Library)
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
local IsAutoGrabbing = false
local SelectedAmmo = nil
local OriginalPosition = nil
local minimizeLevel = 0

-- ■■■ Utility Functions ■■■
function SendNotif(title, content)
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

function FindBlobman()
    if LocalPlayer.Character then
        local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
    end
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
    local args = {
        [1] = "Blobman"
    }
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

function TeleportAndAttack(targetName)
    local target = Players:FindFirstChild(targetName)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
    local myHrp = char.HumanoidRootPart
    local targetHrp = target.Character.HumanoidRootPart
    if not OriginalPosition then
        OriginalPosition = myHrp.CFrame
    end
    local ammo = FindBlobman()
    if not ammo then
        SpawnBlobman()
        task.wait(0.2)
        ammo = FindBlobman()
        if not ammo then return end
    end
    if ammo and ammo:FindFirstChild("HumanoidRootPart") then
        for i = 1, 5 do
            ammo.HumanoidRootPart.CFrame = myHrp.CFrame * CFrame.new(0, 0, -2)
            ammo.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
            RunService.RenderStepped:Wait()
        end
    end
    myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 1)
    task.wait(0.01)
    local bv = Instance.new("BodyAngularVelocity")
    bv.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bv.AngularVelocity = Vector3.new(500, 500, 500)
    bv.Parent = myHrp
    if ammo and ammo:FindFirstChild("HumanoidRootPart") then
        ammo.HumanoidRootPart.CFrame = targetHrp.CFrame
        ammo.HumanoidRootPart.Velocity = (targetHrp.Position - myHrp.Position).Unit * 1000
    end
    task.wait(0.05)
    bv:Destroy()
    myHrp.CFrame = OriginalPosition
    myHrp.Velocity = Vector3.new(0,0,0)
    OriginalPosition = nil
end

-- ■■■ UI Construction ■■■
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SyuHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

-- メインフレーム（クールな黒デザイン）
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 280)
MainFrame.Position = UDim2.new(0.5, -160, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 1
MainFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
MainFrame.Parent = ScreenGui

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
TitleLabel.Text = "Syu_hub v6.0"
TitleLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- 最小化ボタン（3段階）
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -70, 0, 5)
MinimizeBtn.Text = "−"
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MinimizeBtn.TextColor3 = Color3.new(1,1,1)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 20
MinimizeBtn.Parent = TitleBar

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 8)
MinimizeCorner.Parent = MinimizeBtn

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

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

-- コンテンツエリア
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -20, 1, -50)
Content.Position = UDim2.new(0, 10, 0, 45)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- プレイヤー選択ドロップダウン
local PlayerLabel = Instance.new("TextLabel")
PlayerLabel.Size = UDim2.new(1, 0, 0, 20)
PlayerLabel.Position = UDim2.new(0, 0, 0, 5)
PlayerLabel.Text = "ターゲット選択:"
PlayerLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
PlayerLabel.BackgroundTransparency = 1
PlayerLabel.Font = Enum.Font.Gotham
PlayerLabel.TextSize = 14
PlayerLabel.TextXAlignment = Enum.TextXAlignment.Left
PlayerLabel.Parent = Content

local PlayerDropdown = Instance.new("TextButton")
PlayerDropdown.Size = UDim2.new(1, 0, 0, 30)
PlayerDropdown.Position = UDim2.new(0, 0, 0, 28)
PlayerDropdown.Text = "プレイヤーを選択..."
PlayerDropdown.TextColor3 = Color3.new(1,1,1)
PlayerDropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
PlayerDropdown.Font = Enum.Font.Gotham
PlayerDropdown.TextSize = 14
PlayerDropdown.Parent = Content

local DropdownCorner = Instance.new("UICorner")
DropdownCorner.CornerRadius = UDim.new(0, 6)
DropdownCorner.Parent = PlayerDropdown

-- ボタン作成ヘルパー
local function CreateButton(text, position, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.Position = position
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Parent = Content
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Kick ボタン
CreateButton("Kick Target (Hit & Run)", UDim2.new(0, 0, 0, 65), function()
    if TargetPlayer then
        SendNotif("Kicking", "Attacking " .. TargetPlayer)
        TeleportAndAttack(TargetPlayer)
    else
        SendNotif("Error", "プレイヤーを選択してください")
    end
end)

-- Loop Kick トグル
local LoopBtn = CreateButton("Loop Kick: OFF", UDim2.new(0, 0, 0, 100), function()
    IsLoopKicking = not IsLoopKicking
    if IsLoopKicking and TargetPlayer then
        LoopBtn.Text = "Loop Kick: ON"
        LoopBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
        SendNotif("Loop Kick", "Loop started for " .. TargetPlayer)
        task.spawn(function()
            while IsLoopKicking and TargetPlayer do
                TeleportAndAttack(TargetPlayer)
                task.wait(0.1)
            end
        end)
    else
        IsLoopKicking = false
        LoopBtn.Text = "Loop Kick: OFF"
        LoopBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    end
end)

-- Kick ALL ボタン
local KickAllBtn = CreateButton("Kick ALL: OFF", UDim2.new(0, 0, 0, 135), function()
    IsLoopKicking = not IsLoopKicking
    if IsLoopKicking then
        KickAllBtn.Text = "Kick ALL: ON"
        KickAllBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
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
        IsLoopKicking = false
        KickAllBtn.Text = "Kick ALL: OFF"
        KickAllBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        SendNotif("Stopped", "All Kick Stopped.")
    end
end)

-- Spawn Blobman ボタン
CreateButton("Force Spawn Blobman", UDim2.new(0, 0, 0, 170), function()
    SpawnBlobman()
end)

-- リフレッシュボタン
CreateButton("🔄 Refresh Player List", UDim2.new(0, 0, 0, 205), function()
    SendNotif("Refreshed", "Player list updated.")
end)

-- ドロップダウンクリック（シンプル版 - 最初のプレイヤーを選択）
PlayerDropdown.MouseButton1Click:Connect(function()
    local players = GetPlayerNames()
    if #players > 0 then
        TargetPlayer = players[1]
        PlayerDropdown.Text = TargetPlayer
        SendNotif("Selected", "Target: " .. TargetPlayer)
    end
end)

-- 3段階最小化
MinimizeBtn.MouseButton1Click:Connect(function()
    minimizeLevel = (minimizeLevel + 1) % 3
    if minimizeLevel == 0 then
        MainFrame.Size = UDim2.new(0, 320, 0, 280)
        MinimizeBtn.Text = "−"
        Content.Visible = true
    elseif minimizeLevel == 1 then
        MainFrame.Size = UDim2.new(0, 320, 0, 40)
        MinimizeBtn.Text = "■"
        Content.Visible = false
    else
        MainFrame.Size = UDim2.new(0, 150, 0, 40)
        MinimizeBtn.Text = "☆"
        Content.Visible = false
    end
end)

-- 閉じる
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- メインUIドラッグ
local dragging = false
local dragInput, dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
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
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

SendNotif("Syu_hub", "v6.0 カスタムUI版 ロード完了!")
print("Syu_hub v6.0 Ready to kick!")
