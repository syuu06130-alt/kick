--[[
    Syu_hub v6.0 | Blobman Auto Grab & Throw Loop
    Target: Fling Things and People
    完全修正版
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Variables
local TargetPlayer = nil
local IsLoopKicking = false
local IsAllKicking = false
local OriginalPosition = nil
local BlobmanTool = nil

-- Notification
local function Notify(msg)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Syu_hub";
        Text = msg;
        Duration = 3;
    })
    print("[Syu_hub] " .. msg)
end

-- Get Player List
local function GetPlayerNames()
    local names = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    return names
end

-- Spawn Blobman from Toy category
local function SpawnBlobman()
    -- Fling Things and Peopleのスポーンリモートを探す
    local success = pcall(function()
        local args = {
            [1] = workspace.Spawn,
            [2] = "Blobman"
        }
        -- よくあるパターン
        if ReplicatedStorage:FindFirstChild("SpawnItem") then
            ReplicatedStorage.SpawnItem:FireServer(unpack(args))
        elseif ReplicatedStorage:FindFirstChild("RE") then
            ReplicatedStorage.RE:FireServer("SpawnItem", "Blobman")
        end
    end)
    
    if success then
        Notify("Blobmanをスポーンしました")
        wait(0.5)
        -- スポーンしたBlobmanを探して装備
        for _, v in pairs(workspace:GetDescendants()) do
            if v.Name == "Blobman" and v:IsA("Tool") then
                v.Parent = LocalPlayer.Backpack
                BlobmanTool = v
                break
            end
        end
    end
end

-- Grab and Throw Loop
local function GrabThrowLoop(targetName)
    local target = Players:FindFirstChild(targetName)
    if not target or not target.Character then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local myHrp = char.HumanoidRootPart
    local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHrp then return end
    
    -- 元の位置を保存
    if not OriginalPosition then
        OriginalPosition = myHrp.CFrame
    end
    
    -- Blobmanがなければスポーン
    if not BlobmanTool or not BlobmanTool.Parent then
        SpawnBlobman()
        wait(0.3)
    end
    
    -- Blobmanを装備
    if BlobmanTool and BlobmanTool.Parent == LocalPlayer.Backpack then
        char.Humanoid:EquipTool(BlobmanTool)
        wait(0.1)
    end
    
    -- ターゲットにTP
    myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 3)
    wait(0.01)
    
    -- 掴む→投げるループ
    for i = 1, 5 do
        if not (IsLoopKicking or IsAllKicking) then break end
        
        -- 掴む動作（物理的に近づける）
        myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 1)
        
        -- Blobmanで掴む
        if BlobmanTool and BlobmanTool:FindFirstChild("Handle") then
            BlobmanTool.Handle.CFrame = targetHrp.CFrame
            -- 掴むアクション
            if BlobmanTool:FindFirstChild("MouseClick") then
                BlobmanTool.MouseClick:Fire()
            end
        end
        
        wait(0.01)
        
        -- 投げる動作
        myHrp.Velocity = (targetHrp.Position - myHrp.Position).Unit * 500
        
        -- Unequip して投げる
        if BlobmanTool then
            char.Humanoid:UnequipTools()
        end
        
        wait(0.01)
        
        -- 再装備
        if BlobmanTool and BlobmanTool.Parent == LocalPlayer.Backpack then
            char.Humanoid:EquipTool(BlobmanTool)
        end
    end
    
    -- 元の位置に戻る
    myHrp.CFrame = OriginalPosition
    myHrp.Velocity = Vector3.new(0, 0, 0)
end

-- UI作成
wait(1) -- キャラクターロード待機

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SyuHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- PlayerGuiに配置
if LocalPlayer:FindFirstChild("PlayerGui") then
    ScreenGui.Parent = LocalPlayer.PlayerGui
else
    ScreenGui.Parent = game.CoreGui
end

-- メインフレーム
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 350, 0, 450)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -225)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
MainFrame.Active = true
MainFrame.Draggable = true -- これで自動的にドラッグ可能
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = MainFrame

-- タイトルバー
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.Text = "🎯 Syu_hub v6.0"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- 閉じるボタン
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 2.5)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 5)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    IsLoopKicking = false
    IsAllKicking = false
    ScreenGui:Destroy()
    Notify("UIを閉じました")
end)

-- スクロールフレーム
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -45)
ScrollFrame.Position = UDim2.new(0, 10, 0, 40)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 550)
ScrollFrame.Parent = MainFrame

-- ボタン作成関数
local yPos = 10
local function CreateButton(text, callback, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 45)
    btn.Position = UDim2.new(0, 5, 0, yPos)
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 60)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = ScrollFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
    
    yPos = yPos + 50
    return btn
end

-- プレイヤー選択
local PlayerLabel = Instance.new("TextLabel")
PlayerLabel.Size = UDim2.new(1, -10, 0, 25)
PlayerLabel.Position = UDim2.new(0, 5, 0, yPos)
PlayerLabel.Text = "ターゲット選択:"
PlayerLabel.TextColor3 = Color3.new(1, 1, 1)
PlayerLabel.BackgroundTransparency = 1
PlayerLabel.Font = Enum.Font.GothamBold
PlayerLabel.TextSize = 14
PlayerLabel.TextXAlignment = Enum.TextXAlignment.Left
PlayerLabel.Parent = ScrollFrame
yPos = yPos + 30

local PlayerDropdown = Instance.new("TextButton")
PlayerDropdown.Size = UDim2.new(1, -10, 0, 40)
PlayerDropdown.Position = UDim2.new(0, 5, 0, yPos)
PlayerDropdown.Text = "▼ クリックして選択"
PlayerDropdown.TextColor3 = Color3.new(1, 1, 1)
PlayerDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
PlayerDropdown.Font = Enum.Font.Gotham
PlayerDropdown.TextSize = 13
PlayerDropdown.Parent = ScrollFrame

local DropCorner = Instance.new("UICorner")
DropCorner.CornerRadius = UDim.new(0, 6)
DropCorner.Parent = PlayerDropdown

yPos = yPos + 45

-- ドロップダウンメニュー
local DropMenu = Instance.new("Frame")
DropMenu.Size = UDim2.new(1, -10, 0, 0)
DropMenu.Position = UDim2.new(0, 5, 0, yPos)
DropMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
DropMenu.BorderSizePixel = 1
DropMenu.BorderColor3 = Color3.fromRGB(70, 70, 70)
DropMenu.Visible = false
DropMenu.ClipsDescendants = true
DropMenu.Parent = ScrollFrame

local DropScroll = Instance.new("ScrollingFrame")
DropScroll.Size = UDim2.new(1, 0, 1, 0)
DropScroll.BackgroundTransparency = 1
DropScroll.BorderSizePixel = 0
DropScroll.ScrollBarThickness = 4
DropScroll.Parent = DropMenu

local DropLayout = Instance.new("UIListLayout")
DropLayout.SortOrder = Enum.SortOrder.LayoutOrder
DropLayout.Padding = UDim.new(0, 2)
DropLayout.Parent = DropScroll

local function UpdatePlayers()
    for _, v in pairs(DropScroll:GetChildren()) do
        if v:IsA("TextButton") then v:Destroy() end
    end
    
    local players = GetPlayerNames()
    for _, name in ipairs(players) do
        local pbtn = Instance.new("TextButton")
        pbtn.Size = UDim2.new(1, -5, 0, 30)
        pbtn.Text = name
        pbtn.TextColor3 = Color3.new(1, 1, 1)
        pbtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        pbtn.Font = Enum.Font.Gotham
        pbtn.TextSize = 12
        pbtn.Parent = DropScroll
        
        pbtn.MouseButton1Click:Connect(function()
            TargetPlayer = name
            PlayerDropdown.Text = "✓ " .. name
            DropMenu.Visible = false
            Notify("選択: " .. name)
        end)
    end
    
    DropScroll.CanvasSize = UDim2.new(0, 0, 0, #players * 32)
end

local dropOpen = false
PlayerDropdown.MouseButton1Click:Connect(function()
    dropOpen = not dropOpen
    if dropOpen then
        UpdatePlayers()
        DropMenu.Visible = true
        DropMenu:TweenSize(UDim2.new(1, -10, 0, 150), "Out", "Quad", 0.2, true)
    else
        DropMenu:TweenSize(UDim2.new(1, -10, 0, 0), "Out", "Quad", 0.2, true, function()
            DropMenu.Visible = false
        end)
    end
end)

yPos = yPos + 10

-- Spawn Blobman ボタン
CreateButton("🧊 Blobman スポーン", function()
    Notify("Blobmanをスポーン中...")
    SpawnBlobman()
end, Color3.fromRGB(80, 60, 100))

-- Kick Target ボタン
CreateButton("🎯 Kick Target", function()
    if not TargetPlayer then
        Notify("プレイヤーを選択してください")
        return
    end
    Notify("攻撃中: " .. TargetPlayer)
    task.spawn(function()
        GrabThrowLoop(TargetPlayer)
    end)
end, Color3.fromRGB(60, 80, 120))

-- Loop Kick ボタン
local LoopBtn = CreateButton("🔄 Loop Kick: OFF", function()
    IsLoopKicking = not IsLoopKicking
    IsAllKicking = false
    
    if IsLoopKicking then
        if not TargetPlayer then
            Notify("プレイヤーを選択してください")
            IsLoopKicking = false
            return
        end
        
        LoopBtn.Text = "🔄 Loop Kick: ON"
        LoopBtn.BackgroundColor3 = Color3.fromRGB(60, 150, 60)
        Notify("ループ開始: " .. TargetPlayer)
        
        task.spawn(function()
            while IsLoopKicking do
                if TargetPlayer then
                    GrabThrowLoop(TargetPlayer)
                end
                wait(0.05)
            end
        end)
    else
        LoopBtn.Text = "🔄 Loop Kick: OFF"
        LoopBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        Notify("ループ停止")
    end
end, Color3.fromRGB(50, 50, 60))

-- Kick ALL ボタン
local AllBtn = CreateButton("💀 Kick ALL: OFF", function()
    IsAllKicking = not IsAllKicking
    IsLoopKicking = false
    LoopBtn.Text = "🔄 Loop Kick: OFF"
    LoopBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    
    if IsAllKicking then
        AllBtn.Text = "💀 Kick ALL: ON"
        AllBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        Notify("全員攻撃開始！")
        
        task.spawn(function()
            while IsAllKicking do
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and IsAllKicking then
                        GrabThrowLoop(p.Name)
                        wait(0.1)
                    end
                end
                wait(0.05)
            end
        end)
    else
        AllBtn.Text = "💀 Kick ALL: OFF"
        AllBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        Notify("全員攻撃停止")
    end
end, Color3.fromRGB(50, 50, 60))

-- Refresh ボタン
CreateButton("🔄 更新", function()
    UpdatePlayers()
    Notify("リスト更新完了")
end, Color3.fromRGB(50, 90, 50))

Notify("v6.0 ロード完了！")
print("=== Syu_hub v6.0 ===")
print("準備完了！")
