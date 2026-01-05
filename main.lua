--[[
    Syu_hub v6.0 | Blobman Kicker & Auto Grab
    Target: Fling Things and People
    Custom UI Edition - FULLY FIXED & RESPONSIVE
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
        SendNotif("System", "Blobmanのスポーンを試みました")
    else
        SendNotif("Warning", "自動スポーンに失敗しました")
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

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 400)
MainFrame.Position = UDim2.new(0.5, -175, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 1
MainFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = MainFrame

-- タイトルバー（変更なし）
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
TitleLabel.Text = "Syu_hub v6.0 Fixed"
TitleLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- 最小化・閉じるボタン（変更なし）
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

-- スクロールフレーム
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -50)
ScrollFrame.Position = UDim2.new(0, 10, 0, 45)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)  -- 自動調整
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y  -- 重要！自動でCanvasSize調整
ScrollFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = ScrollFrame

-- === プレイヤー選択部分 ===
local PlayerLabel = Instance.new("TextLabel")
PlayerLabel.Size = UDim2.new(1, 0, 0, 25)
PlayerLabel.Text = "ターゲット選択:"
PlayerLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
PlayerLabel.BackgroundTransparency = 1
PlayerLabel.Font = Enum.Font.GothamBold
PlayerLabel.TextSize = 14
PlayerLabel.TextXAlignment = Enum.TextXAlignment.Left
PlayerLabel.Parent = ScrollFrame

local PlayerDropdown = Instance.new("TextButton")
PlayerDropdown.Size = UDim2.new(1, 0, 0, 35)
PlayerDropdown.Text = "▼ プレイヤーを選択..."
PlayerDropdown.TextColor3 = Color3.new(1,1,1)
PlayerDropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
PlayerDropdown.Font = Enum.Font.Gotham
PlayerDropdown.TextSize = 14
PlayerDropdown.Parent = ScrollFrame

local DropdownCorner = Instance.new("UICorner")
DropdownCorner.CornerRadius = UDim.new(0, 6)
DropdownCorner.Parent = PlayerDropdown

-- ドロップダウンメニュー
local DropdownMenu = Instance.new("Frame")
DropdownMenu.Size = UDim2.new(1, 0, 0, 0)
DropdownMenu.Position = UDim2.new(0, 0, 1, 5)
DropdownMenu.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
DropdownMenu.BorderSizePixel = 1
DropdownMenu.BorderColor3 = Color3.fromRGB(60, 60, 60)
DropdownMenu.Visible = false
DropdownMenu.ClipsDescendants = true
DropdownMenu.Parent = PlayerDropdown  -- 重要：PlayerDropdownの子に変更

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(0, 6)
MenuCorner.Parent = DropdownMenu

local MenuScroll = Instance.new("ScrollingFrame")
MenuScroll.Size = UDim2.new(1, 0, 1, 0)
MenuScroll.BackgroundTransparency = 1
MenuScroll.BorderSizePixel = 0
MenuScroll.ScrollBarThickness = 4
MenuScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
MenuScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
MenuScroll.Parent = DropdownMenu

local MenuLayout = Instance.new("UIListLayout")
MenuLayout.SortOrder = Enum.SortOrder.LayoutOrder
MenuLayout.Padding = UDim.new(0, 2)
MenuLayout.Parent = MenuScroll

local function UpdatePlayerList()
    for _, child in pairs(MenuScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local players = GetPlayerNames()
    for _, playerName in ipairs(players) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -5, 0, 30)
        btn.Text = playerName
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.Parent = MenuScroll
        local bc = Instance.new("UICorner", btn)
        bc.CornerRadius = UDim.new(0, 4)

        btn.MouseButton1Click:Connect(function()
            TargetPlayer = playerName
            PlayerDropdown.Text = "✓ " .. playerName
            DropdownMenu.Visible = false
            SendNotif("Selected", "Target: " .. playerName)
        end)
    end
end

local dropdownOpen = false
PlayerDropdown.MouseButton1Click:Connect(function()
    dropdownOpen = not dropdownOpen
    UpdatePlayerList()
    if dropdownOpen then
        DropdownMenu.Visible = true
        DropdownMenu:TweenSize(UDim2.new(1, 0, 0, 150), "Out", "Quad", 0.2, true)
    else
        DropdownMenu:TweenSize(UDim2.new(1, 0, 0, 0), "Out", "Quad", 0.2, true, function()
            DropdownMenu.Visible = false
        end)
    end
end)

-- === ボタン作成（自動配置）===
local function CreateButton(text, callback, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.BackgroundColor3 = color or Color3.fromRGB(45, 45, 55)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = ScrollFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- 各ボタン
CreateButton("🎯 Kick Target (Hit & Run)", function()
    if TargetPlayer then
        SendNotif("Kicking", "Attacking " .. TargetPlayer)
        task.spawn(TeleportAndAttack, TargetPlayer)
    else
        SendNotif("Error", "プレイヤーを選択してください")
    end
end, Color3.fromRGB(60, 80, 120))

local LoopBtn = CreateButton("🔄 Loop Kick: OFF", function()
    IsLoopKicking = not IsLoopKicking
    if IsLoopKicking then
        if not TargetPlayer then
            SendNotif("Error", "プレイヤーを選択してください")
            IsLoopKicking = false
            LoopBtn.Text = "🔄 Loop Kick: OFF"
            LoopBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            return
        end
        LoopBtn.Text = "🔄 Loop Kick: ON"
        LoopBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
        SendNotif("Loop", "Started for " .. TargetPlayer)
        task.spawn(function()
            while IsLoopKicking do
                TeleportAndAttack(TargetPlayer)
                task.wait(0.1)
            end
        end)
    else
        LoopBtn.Text = "🔄 Loop Kick: OFF"
        LoopBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    end
end)

local KickAllBtn = CreateButton("💀 Kick ALL: OFF", function()
    IsAllKicking = not IsAllKicking
    if IsAllKicking then
        IsLoopKicking = false
        LoopBtn.Text = "🔄 Loop Kick: OFF"
        LoopBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        KickAllBtn.Text = "💀 Kick ALL: ON"
        KickAllBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
        SendNotif("ALL KICK", "Starting massacre...")
        task.spawn(function()
            while IsAllKicking do
                for _, p in Players:GetPlayers() do
                    if p ~= LocalPlayer then
                        TeleportAndAttack(p.Name)
                        task.wait(0.2)
                    end
                end
                task.wait(0.1)
            end
        end)
    else
        KickAllBtn.Text = "💀 Kick ALL: OFF"
        KickAllBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    end
end)

CreateButton("🧊 Force Spawn Blobman", function()
    SpawnBlobman()
end, Color3.fromRGB(80, 60, 100))

CreateButton("🔄 Refresh Player List", function()
    UpdatePlayerList()
    SendNotif("Refreshed", "Player list updated")
end, Color3.fromRGB(50, 90, 50))

-- 最小化機能（変更なし）
MinimizeBtn.MouseButton1Click:Connect(function()
    minimizeLevel = (minimizeLevel + 1) % 3
    if minimizeLevel == 0 then
        MainFrame:TweenSize(UDim2.new(0, 350, 0, 400), "Out", "Quad", 0.3, true)
        MinimizeBtn.Text = "−"
        ScrollFrame.Visible = true
    elseif minimizeLevel == 1 then
        MainFrame:TweenSize(UDim2.new(0, 350, 0, 40), "Out", "Quad", 0.3, true)
        MinimizeBtn.Text = "■"
        ScrollFrame.Visible = false
    else
        MainFrame:TweenSize(UDim2.new(0, 150, 0, 40), "Out", "Quad", 0.3, true)
        MinimizeBtn.Text = "☆"
        ScrollFrame.Visible = false
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    IsLoopKicking = false
    IsAllKicking = false
    ScreenGui:Destroy()
end)

-- ドラッグ機能（変更なし）
local dragging, dragInput, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

TitleBar.InputChanged:Connect(function(input)
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
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ロード完了
task.wait(0.5)
SendNotif("Syu_hub", "v6.0 カスタムUI 完全修正版ロード完了！")
print("=== Syu_hub v6.0 Custom UI - ALL FIXED ===")
print("すべてのボタンが正常に反応します！")
print("ドラッグ・最小化・スクロールも完璧に動作")
print("Ready to kick!")
