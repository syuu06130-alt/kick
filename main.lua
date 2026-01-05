--[[
    Syu_hub v8.0 | Blobman Rapid Loop Throw
    Target: Fling Things and People
    Features: 3-Step Min, Drag UI, Player Select, 0.01s Grab/Throw Loop
]]

-- ■■■ Services ■■■
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ■■■ Variables ■■■
local TargetPlayerName = nil
local IsAttacking = false
local OriginalPosition = nil
local MinimizeLevel = 0 -- 0:Max, 1:Bar, 2:Small

-- ■■■ Utility Functions ■■■

function SendNotif(title, content)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title;
        Text = content;
        Duration = 2;
    })
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

-- Blobmanを探す、なければイベントで呼ぶ
function GetBlobman()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    local blobman = nil
    local shortestDist = 500
    
    -- 既存のBlobmanを探す
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and (v.Name == "Blobman" or v.Name == "Ragdoll") then
            local root = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Torso")
            if root and not Players:GetPlayerFromCharacter(v) then
                if hrp then
                    local dist = (root.Position - hrp.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        blobman = v
                    end
                else
                    blobman = v -- キャラ未ロード時はとりあえず見つけたやつ
                end
            end
        end
    end

    return blobman
end

function SpawnBlobman()
    -- 一般的なSpawnイベントを探索して叩く
    local args = { [1] = "Blobman" }
    for _, desc in pairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("RemoteEvent") and (string.find(desc.Name, "Spawn") or string.find(desc.Name, "Create")) then
             pcall(function() desc:FireServer(unpack(args)) end)
        end
    end
end

-- 汎用Grab関数 (ゲーム内のRemoteを探して実行)
function TriggerGrab(part)
    -- 右手にあるGrabイベントを探す想定
    for _, desc in pairs(LocalPlayer.Character:GetDescendants()) do
        if desc:IsA("RemoteEvent") and (string.find(desc.Name, "Grab") or string.find(desc.Name, "Interact")) then
            pcall(function() desc:FireServer(part) end)
        end
    end
    -- BackpackやReplicatedStorageにある汎用Grabも探す
    for _, desc in pairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("RemoteEvent") and (string.find(desc.Name, "Grab") or string.find(desc.Name, "Interact")) then
            pcall(function() desc:FireServer(part) end)
        end
    end
end

-- 汎用Release/Throw関数
function TriggerThrow()
    for _, desc in pairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("RemoteEvent") and (string.find(desc.Name, "Throw") or string.find(desc.Name, "Release")) then
            pcall(function() desc:FireServer(Vector3.new(0, 50, 0)) end) -- 上に投げる
        end
    end
end

-- ■■■ メイン攻撃ロジック (0.01秒ループ) ■■■
function StartLoopAttack(targetName)
    local target = Players:FindFirstChild(targetName)
    if not target then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- 元の場所を記憶
    if not OriginalPosition then OriginalPosition = hrp.CFrame end

    local startTime = tick()
    
    -- 1分間 (60秒) または オフにするまでループ
    while IsAttacking and target and target.Character and (tick() - startTime < 60) do
        local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
        if not targetHrp then break end

        -- 1. Blobman確保
        local ammo = GetBlobman()
        if not ammo then
            SpawnBlobman()
            task.wait(0.05)
            ammo = GetBlobman()
        end

        -- 2. ターゲットへTP
        hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 2) -- 少し後ろに
        
        -- 3. 掴む (Grab)
        if ammo then
            -- Blobmanを自分の手元に持ってくる（物理固定）
            local ammoRoot = ammo:FindFirstChild("HumanoidRootPart")
            if ammoRoot then
                ammoRoot.CFrame = hrp.CFrame * CFrame.new(0, 0, -1)
                ammoRoot.Velocity = Vector3.new(0,0,0)
            end
            -- ターゲットをGrabする信号を送る
            TriggerGrab(targetHrp)
        end

        -- 指定された待機時間
        task.wait(0.01)

        -- 4. 投げる (Throw)
        -- 物理的に吹き飛ばす
        hrp.Velocity = (hrp.CFrame.LookVector * 100) + Vector3.new(0, 50, 0)
        TriggerThrow()

        -- 指定された待機時間
        task.wait(0.01)
    end

    -- ループ終了後の後始末
    IsAttacking = false
    if OriginalPosition then
        hrp.CFrame = OriginalPosition
        hrp.Velocity = Vector3.new(0,0,0)
        OriginalPosition = nil
    end
    SendNotif("System", "Loop Finished.")
end


-- ■■■ UI Construction ■■■

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SyuHub_Fixed_v8"
ScreenGui.ResetOnSpawn = false
if game.CoreGui:FindFirstChild("SyuHub_Fixed_v8") then
    game.CoreGui.SyuHub_Fixed_v8:Destroy()
end
ScreenGui.Parent = game.CoreGui

-- メインフレーム
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 350, 0, 400) -- 通常サイズ
MainFrame.Position = UDim2.new(0.5, -175, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 1
MainFrame.BorderColor3 = Color3.fromRGB(60, 60, 100)
MainFrame.Parent = ScreenGui
MainFrame.ClipsDescendants = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- タイトルバー（ドラッグ対象）
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
TitleBar.Parent = MainFrame
local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -50, 1, 0)
TitleText.Position = UDim2.new(0, 10, 0, 0)
TitleText.Text = "Syu_hub v8.0 | Fixed UI"
TitleText.TextColor3 = Color3.fromRGB(200, 200, 255)
TitleText.BackgroundTransparency = 1
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 16
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

-- 最小化ボタン
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -40, 0, 5)
MinBtn.Text = "-"
MinBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
MinBtn.TextColor3 = Color3.new(1,1,1)
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- コンテンツエリア
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -50)
ScrollFrame.Position = UDim2.new(0, 10, 0, 45)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.Parent = MainFrame

-- ■ UI Components ■

-- プレイヤー選択ドロップダウン
local DropdownBtn = Instance.new("TextButton")
DropdownBtn.Size = UDim2.new(1, 0, 0, 40)
DropdownBtn.Position = UDim2.new(0, 0, 0, 0)
DropdownBtn.Text = "Target: Select Player ▼"
DropdownBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
DropdownBtn.TextColor3 = Color3.new(1,1,1)
DropdownBtn.Font = Enum.Font.Gotham
DropdownBtn.TextSize = 14
DropdownBtn.Parent = ScrollFrame
Instance.new("UICorner", DropdownBtn).CornerRadius = UDim.new(0, 6)

local PlayerListFrame = Instance.new("ScrollingFrame")
PlayerListFrame.Size = UDim2.new(1, 0, 0, 150)
PlayerListFrame.Position = UDim2.new(0, 0, 0, 45)
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
PlayerListFrame.Visible = false
PlayerListFrame.ZIndex = 5
PlayerListFrame.Parent = ScrollFrame
Instance.new("UICorner", PlayerListFrame).CornerRadius = UDim.new(0, 6)
local ListLayout = Instance.new("UIListLayout")
ListLayout.Parent = PlayerListFrame

-- ドロップダウン開閉処理
local isDropdownOpen = false
DropdownBtn.MouseButton1Click:Connect(function()
    isDropdownOpen = not isDropdownOpen
    PlayerListFrame.Visible = isDropdownOpen
    
    if isDropdownOpen then
        -- リスト更新
        for _, c in pairs(PlayerListFrame:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        
        for _, name in pairs(GetPlayerNames()) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.Text = name
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            btn.TextColor3 = Color3.new(1,1,1)
            btn.Parent = PlayerListFrame
            
            btn.MouseButton1Click:Connect(function()
                TargetPlayerName = name
                DropdownBtn.Text = "Target: " .. name
                PlayerListFrame.Visible = false
                isDropdownOpen = false
            end)
        end
        PlayerListFrame.CanvasSize = UDim2.new(0,0,0, #GetPlayerNames() * 30)
    end
end)

-- 攻撃開始/停止ボタン（トグル）
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, 0, 0, 50)
ToggleBtn.Position = UDim2.new(0, 0, 0, 210) -- ドロップダウンの下に配置
ToggleBtn.Text = "START LOOP (OFF)"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
ToggleBtn.TextColor3 = Color3.new(1,1,1)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 16
ToggleBtn.Parent = ScrollFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)

ToggleBtn.MouseButton1Click:Connect(function()
    IsAttacking = not IsAttacking
    
    if IsAttacking then
        if not TargetPlayerName then
            SendNotif("Error", "プレイヤーを選択してください")
            IsAttacking = false
            return
        end
        
        ToggleBtn.Text = "STOP LOOP (ON)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        
        -- ループ処理開始
        task.spawn(function()
            StartLoopAttack(TargetPlayerName)
            -- ループが終わったらボタンを戻す
            IsAttacking = false
            ToggleBtn.Text = "START LOOP (OFF)"
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
        end)
    else
        ToggleBtn.Text = "START LOOP (OFF)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
    end
end)

-- 手動Blobmanスポーンボタン
local SpawnBtn = Instance.new("TextButton")
SpawnBtn.Size = UDim2.new(1, 0, 0, 40)
SpawnBtn.Position = UDim2.new(0, 0, 0, 270)
SpawnBtn.Text = "Spawn Blobman Only"
SpawnBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
SpawnBtn.TextColor3 = Color3.new(1,1,1)
SpawnBtn.Parent = ScrollFrame
Instance.new("UICorner", SpawnBtn).CornerRadius = UDim.new(0, 8)

SpawnBtn.MouseButton1Click:Connect(function()
    SpawnBlobman()
end)

-- ■ 3段階最小化ロジック ■
MinBtn.MouseButton1Click:Connect(function()
    MinimizeLevel = (MinimizeLevel + 1) % 3
    
    if MinimizeLevel == 0 then
        -- 通常状態
        MainFrame:TweenSize(UDim2.new(0, 350, 0, 400), "Out", "Quad", 0.3)
        ScrollFrame.Visible = true
        MinBtn.Text = "-"
        TitleText.Visible = true
        TitleText.Text = "Syu_hub v8.0 | Fixed UI"
        
    elseif MinimizeLevel == 1 then
        -- バーのみ
        MainFrame:TweenSize(UDim2.new(0, 350, 0, 40), "Out", "Quad", 0.3)
        ScrollFrame.Visible = false
        MinBtn.Text = "□"
        TitleText.Visible = true
        
    elseif MinimizeLevel == 2 then
        -- 極小アイコン
        MainFrame:TweenSize(UDim2.new(0, 120, 0, 40), "Out", "Quad", 0.3)
        ScrollFrame.Visible = false
        MinBtn.Text = "Max"
        TitleText.Visible = false -- タイトルも消す
    end
end)

-- ■ ドラッグ機能 (Drag Function) ■
local dragging, dragInput, dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
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
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
end)

SendNotif("Syu_hub", "UI Fixed & Logic Updated!")
