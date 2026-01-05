--[[
    Syu_hub v6.0 Fixed | Blobman Kicker & Auto Grab
    UI: Original Custom Design
    Logic: Refactored for better physics replication
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
local CurrentConnection = nil -- ループ制御用

-- ■■■ Utility Functions ■■■
function SendNotif(title, content)
    -- StarterGuiの通知も利用（確実に見えるように）
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title;
        Text = content;
        Duration = 3;
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

-- Blobman探索ロジックの改善
function FindBlobman()
    local nearest, dist = nil, 1000 -- 探索範囲拡大
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then return nil end

    -- 物理演算が有効なパーツを持つモデルを探す
    for _, v in pairs(Workspace:GetDescendants()) do
        if (v.Name == "Blobman" or v.Name == "Ragdoll" or v.Name == "Item") and v:IsA("Model") then
            local targetPart = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Torso") or v:FindFirstChild("Head") or v.PrimaryPart
            
            if targetPart and not Players:GetPlayerFromCharacter(v) then
                local d = (targetPart.Position - hrp.Position).Magnitude
                if d < dist then
                    dist = d
                    nearest = v
                end
            end
        end
    end
    return nearest
end

function SpawnBlobman()
    -- ゲーム固有のリモートを探して発火させる試み
    local args = { [1] = "Blobman" }
    local possibleRemotes = {
        "SpawnItem", "CreateItem", "SpawnObject", "RequestSpawn"
    }
    
    local fired = false
    
    -- ReplicatedStorage内を検索
    for _, name in pairs(possibleRemotes) do
        local remote = ReplicatedStorage:FindFirstChild(name, true) -- 再帰的に検索
        if remote and remote:IsA("RemoteEvent") then
            pcall(function()
                remote:FireServer(unpack(args))
                fired = true
                print("Fired remote: " .. remote.Name)
            end)
        end
    end

    if fired then
        SendNotif("System", "Spawn信号を送信しました")
    else
        SendNotif("Warning", "Spawnリモートが見つかりません (手動で出してください)")
    end
end

-- 攻撃ロジックの完全書き換え
function TeleportAndAttack(targetName)
    local target = Players:FindFirstChild(targetName)
    local char = LocalPlayer.Character
    
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then 
        SendNotif("Error", "ターゲットが見つかりません/死んでいます")
        return 
    end
    
    local myHrp = char.HumanoidRootPart
    local targetHrp = target.Character.HumanoidRootPart
    
    -- 元の位置を保存
    if not OriginalPosition then
        OriginalPosition = myHrp.CFrame
    end
    
    -- 弾薬(Blobman)を探す
    local ammo = FindBlobman()
    if not ammo then
        SpawnBlobman()
        task.wait(0.1)
        ammo = FindBlobman()
        if not ammo then 
            SendNotif("Error", "近くにBlobmanがいません")
            return 
        end
    end
    
    local ammoRoot = ammo:FindFirstChild("HumanoidRootPart") or ammo:FindFirstChild("Torso") or ammo.PrimaryPart
    if not ammoRoot then return end

    -- Step 1: 物理権限を取得するためにBlobmanへ一瞬テレポート
    local oldCFrame = myHrp.CFrame
    myHrp.CFrame = ammoRoot.CFrame
    task.wait(0.1) -- サーバー認識待ち
    
    -- Step 2: 回転力の付与
    local bv = Instance.new("BodyAngularVelocity")
    bv.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bv.AngularVelocity = Vector3.new(0, 1000, 0) -- Y軸回転
    bv.Parent = myHrp
    
    -- Step 3: ターゲットへ突撃 (RunServiceで位置を強制固定し続ける)
    local startTime = tick()
    local connection
    
    -- 0.35秒間ヒット処理を実行
    connection = RunService.Heartbeat:Connect(function()
        if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
            connection:Disconnect()
            return
        end
        
        -- 自分の位置を相手に重ねる
        myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 0)
        myHrp.Velocity = Vector3.new(0, 0, 0) -- 自分が吹っ飛ばないようにリセット
        
        -- Blobmanを自分の前に強制固定（これが攻撃判定になる）
        if ammoRoot then
            ammoRoot.CFrame = myHrp.CFrame * CFrame.new(0, 0, -2)
            ammoRoot.Velocity = (targetHrp.Position - myHrp.Position).Unit * 500
            ammoRoot.RotVelocity = Vector3.new(100, 100, 100)
        end
    end)
    
    task.wait(0.35) -- 攻撃持続時間
    
    if connection then connection:Disconnect() end
    if bv then bv:Destroy() end
    
    -- Step 4: 帰還
    if OriginalPosition then
        myHrp.CFrame = OriginalPosition
        myHrp.Velocity = Vector3.new(0,0,0)
        OriginalPosition = nil
    end
end

-- ■■■ UI Construction (User Provided Design) ■■■
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SyuHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

-- メインフレーム
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
TitleLabel.Text = "Syu_hub v6.0 Fixed"
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

-- スクロール可能なコンテンツエリア
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -50)
ScrollFrame.Position = UDim2.new(0, 10, 0, 45)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 500)
ScrollFrame.Parent = MainFrame

-- プレイヤー選択ラベル
local PlayerLabel = Instance.new("TextLabel")
PlayerLabel.Size = UDim2.new(1, 0, 0, 25)
PlayerLabel.Position = UDim2.new(0, 0, 0, 5)
PlayerLabel.Text = "ターゲット選択:"
PlayerLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
PlayerLabel.BackgroundTransparency = 1
PlayerLabel.Font = Enum.Font.GothamBold
PlayerLabel.TextSize = 14
PlayerLabel.TextXAlignment = Enum.TextXAlignment.Left
PlayerLabel.Parent = ScrollFrame

-- プレイヤー選択ドロップダウン
local PlayerDropdown = Instance.new("TextButton")
PlayerDropdown.Size = UDim2.new(1, 0, 0, 35)
PlayerDropdown.Position = UDim2.new(0, 0, 0, 30)
PlayerDropdown.Text = "▼ プレイヤーを選択..."
PlayerDropdown.TextColor3 = Color3.new(1,1,1)
PlayerDropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
PlayerDropdown.Font = Enum.Font.Gotham
PlayerDropdown.TextSize = 14
PlayerDropdown.Parent = ScrollFrame

local DropdownCorner = Instance.new("UICorner")
DropdownCorner.CornerRadius = UDim.new(0, 6)
DropdownCorner.Parent = PlayerDropdown

-- ドロップダウンメニュー（プレイヤーリスト）
local DropdownMenu = Instance.new("Frame")
DropdownMenu.Size = UDim2.new(1, 0, 0, 0)
DropdownMenu.Position = UDim2.new(0, 0, 0, 65)
DropdownMenu.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
DropdownMenu.BorderSizePixel = 1
DropdownMenu.BorderColor3 = Color3.fromRGB(60, 60, 60)
DropdownMenu.Visible = false
DropdownMenu.ClipsDescendants = true
DropdownMenu.Parent = ScrollFrame
DropdownMenu.ZIndex = 5 -- 重なり順を上げる

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(0, 6)
MenuCorner.Parent = DropdownMenu

local MenuScroll = Instance.new("ScrollingFrame")
MenuScroll.Size = UDim2.new(1, 0, 1, 0)
MenuScroll.BackgroundTransparency = 1
MenuScroll.BorderSizePixel = 0
MenuScroll.ScrollBarThickness = 4
MenuScroll.Parent = DropdownMenu
MenuScroll.ZIndex = 6

local MenuLayout = Instance.new("UIListLayout")
MenuLayout.SortOrder = Enum.SortOrder.LayoutOrder
MenuLayout.Padding = UDim.new(0, 2)
MenuLayout.Parent = MenuScroll

-- プレイヤーリスト更新関数
local function UpdatePlayerList()
    for _, child in pairs(MenuScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local players = GetPlayerNames()
    for i, playerName in ipairs(players) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -5, 0, 30)
        btn.Text = playerName
        btn.TextColor3 = Color3.new(1,1,1)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.Parent = MenuScroll
        btn.ZIndex = 7
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            TargetPlayer = playerName
            PlayerDropdown.Text = "✓ " .. playerName
            DropdownMenu:TweenSize(UDim2.new(1, 0, 0, 0), "Out", "Quad", 0.2, true, function()
                DropdownMenu.Visible = false
            end)
            SendNotif("Selected", "Target: " .. playerName)
        end)
    end
    
    MenuScroll.CanvasSize = UDim2.new(0, 0, 0, #players * 32)
end

-- ドロップダウン開閉
local dropdownOpen = false
PlayerDropdown.MouseButton1Click:Connect(function()
    dropdownOpen = not dropdownOpen
    if dropdownOpen then
        UpdatePlayerList()
        DropdownMenu.Visible = true
        DropdownMenu:TweenSize(UDim2.new(1, 0, 0, 150), "Out", "Quad", 0.2, true)
    else
        DropdownMenu:TweenSize(UDim2.new(1, 0, 0, 0), "Out", "Quad", 0.2, true, function()
            DropdownMenu.Visible = false
        end)
    end
end)

-- ボタン作成関数
local function CreateButton(text, position, callback, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Position = position
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

-- Kick Target ボタン
local KickBtn = CreateButton("🎯 Kick Target (Hit & Run)", UDim2.new(0, 0, 0, 230), function()
    if TargetPlayer then
        SendNotif("Kicking", "Attacking " .. TargetPlayer)
        -- 非同期処理でUIをフリーズさせない
        task.spawn(function()
            TeleportAndAttack(TargetPlayer)
        end)
    else
        SendNotif("Error", "プレイヤーを選択してください")
    end
end, Color3.fromRGB(60, 80, 120))

-- Loop Kick ボタン
local LoopBtn = CreateButton("🔄 Loop Kick: OFF", UDim2.new(0, 0, 0, 280), function()
    IsLoopKicking = not IsLoopKicking
    
    if IsLoopKicking then
        if not TargetPlayer then
            SendNotif("Error", "プレイヤーを選択してください")
            IsLoopKicking = false
            return
        end
        LoopBtn.Text = "🔄 Loop Kick: ON"
        LoopBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
        SendNotif("Loop Kick", "Loop started for " .. TargetPlayer)
        
        task.spawn(function()
            while IsLoopKicking and TargetPlayer and Players:FindFirstChild(TargetPlayer) do
                TeleportAndAttack(TargetPlayer)
                task.wait(0.1) -- 攻撃間隔
            end
            -- ループが終了したらUIを戻す
            IsLoopKicking = false
            LoopBtn.Text = "🔄 Loop Kick: OFF"
            LoopBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        end)
    else
        LoopBtn.Text = "🔄 Loop Kick: OFF"
        LoopBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        SendNotif("Stopped", "Loop Kick Stopped")
    end
end, Color3.fromRGB(45, 45, 55))

-- Kick ALL ボタン
local KickAllBtn = CreateButton("💀 Kick ALL: OFF", UDim2.new(0, 0, 0, 330), function()
    IsAllKicking = not IsAllKicking
    IsLoopKicking = false -- ループキックは止める
    
    if IsAllKicking then
        KickAllBtn.Text = "💀 Kick ALL: ON"
        KickAllBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
        SendNotif("ALL KICK", "Starting massacre...")
        
        task.spawn(function()
            while IsAllKicking do
                local victims = GetPlayerNames()
                if #victims == 0 then break end
                
                for _, name in pairs(victims) do
                    if not IsAllKicking then break end
                    TargetPlayer = name -- 現在のターゲットを更新（UI表示用）
                    PlayerDropdown.Text = "💀 " .. name
                    TeleportAndAttack(name)
                    task.wait(0.2)
                end
                task.wait(0.5)
            end
            
            -- 終了処理
            IsAllKicking = false
            KickAllBtn.Text = "💀 Kick ALL: OFF"
            KickAllBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            SendNotif("Stopped", "All Kick Stopped")
        end)
    else
        KickAllBtn.Text = "💀 Kick ALL: OFF"
        KickAllBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        SendNotif("Stopped", "All Kick Stopped")
    end
end, Color3.fromRGB(45, 45, 55))

-- Spawn Blobman ボタン
CreateButton("🧊 Force Spawn Blobman", UDim2.new(0, 0, 0, 380), function()
    SendNotif("Spawning", "Blobmanをスポーン中...")
    task.spawn(function()
        SpawnBlobman()
    end)
end, Color3.fromRGB(80, 60, 100))

-- Refresh ボタン
CreateButton("🔄 Refresh Player List", UDim2.new(0, 0, 0, 430), function()
    UpdatePlayerList()
    SendNotif("Refreshed", "Player list updated")
end, Color3.fromRGB(50, 90, 50))

-- 3段階最小化
MinimizeBtn.MouseButton1Click:Connect(function()
    minimizeLevel = (minimizeLevel + 1) % 3
    if minimizeLevel == 0 then
        MainFrame:TweenSize(UDim2.new(0, 350, 0, 400), "Out", "Quad", 0.3, true)
        MinimizeBtn.Text = "−"
        task.wait(0.2)
        ScrollFrame.Visible = true
    elseif minimizeLevel == 1 then
        ScrollFrame.Visible = false
        MainFrame:TweenSize(UDim2.new(0, 350, 0, 40), "Out", "Quad", 0.3, true)
        MinimizeBtn.Text = "■"
    else
        ScrollFrame.Visible = false
        MainFrame:TweenSize(UDim2.new(0, 150, 0, 40), "Out", "Quad", 0.3, true)
        MinimizeBtn.Text = "☆"
    end
end)

-- 閉じる
CloseBtn.MouseButton1Click:Connect(function()
    IsLoopKicking = false
    IsAllKicking = false
    ScreenGui:Destroy()
end)

-- ドラッグ機能
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

-- 初期化完了
SendNotif("Syu_hub", "v6.0 REPAIRED Loaded!")
