--[[
    Poison Grab - Standalone
    Theme: Purple & Dark
    Target: Fling Things and People
]]

-- ■■■ Services ■■■
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ■■■ Variables ■■■
local TargetPlayer = nil
local IsGrabbing = false
local CurrentCamera = Workspace.CurrentCamera

-- ■■■ UI Setup (Purple Theme) ■■■
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PoisonGrabUI"
ScreenGui.ResetOnSpawn = false
if LocalPlayer:FindFirstChild("PlayerGui") then
    ScreenGui.Parent = LocalPlayer.PlayerGui
else
    ScreenGui.Parent = game.CoreGui
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Position = UDim2.new(0.5, -150, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(170, 0, 255) -- Purple Border
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(40, 20, 50)
Title.Text = "Poison Grab UI"
Title.TextColor3 = Color3.fromRGB(200, 100, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = MainFrame

-- Target Input
local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(0.9, 0, 0, 40)
InputBox.Position = UDim2.new(0.05, 0, 0.15, 0)
InputBox.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
InputBox.BorderColor3 = Color3.fromRGB(100, 0, 150)
InputBox.Text = ""
InputBox.PlaceholderText = "Enter Target Name..."
InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputBox.Font = Enum.Font.Gotham
InputBox.TextSize = 14
InputBox.Parent = MainFrame

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0.9, 0, 0, 30)
StatusLabel.Position = UDim2.new(0.05, 0, 0.28, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Idle"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.Parent = MainFrame

-- ■■■ Utility Functions ■■■

-- プレイヤー検索（部分一致対応）
function FindPlayer(namePart)
    if not namePart or namePart == "" then return nil end
    namePart = string.lower(namePart)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if string.find(string.lower(player.Name), namePart) or string.find(string.lower(player.DisplayName), namePart) then
                return player
            end
        end
    end
    return nil
end

-- Blobman（Poison）を探す
function FindPoison()
    local nearest = nil
    for _, v in pairs(Workspace:GetDescendants()) do
        if (v.Name == "Blobman" or v.Name == "Ragdoll") and v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") then
            if not Players:GetPlayerFromCharacter(v) then
                nearest = v
                break -- 最初に見つけたものを使う
            end
        end
    end
    return nearest
end

-- Blobmanをスポーンさせる
function SpawnPoison()
    local args = { [1] = "Blobman" }
    local remotes = {
        ReplicatedStorage:FindFirstChild("SpawnItem"),
        ReplicatedStorage:FindFirstChild("CreateItem"),
        Workspace:FindFirstChild("SpawnEvents")
    }
    for _, remote in pairs(remotes) do
        if remote and remote:IsA("RemoteEvent") then
            pcall(function() remote:FireServer(unpack(args)) end)
        end
    end
end

-- ■■■ Core Logic ■■■
local function StartGrab()
    if not TargetPlayer then
        StatusLabel.Text = "Status: Invalid Target"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        return
    end

    IsGrabbing = true
    StatusLabel.Text = "Status: POISONING " .. TargetPlayer.Name
    StatusLabel.TextColor3 = Color3.fromRGB(170, 0, 255)

    -- メインループ
    task.spawn(function()
        while IsGrabbing and TargetPlayer and TargetPlayer.Character do
            local myChar = LocalPlayer.Character
            local targetChar = TargetPlayer.Character
            
            if myChar and targetChar and myChar:FindFirstChild("HumanoidRootPart") and targetChar:FindFirstChild("HumanoidRootPart") then
                local myHRP = myChar.HumanoidRootPart
                local targetHRP = targetChar.HumanoidRootPart

                -- 1. 自分をターゲットの背後に固定 (Grab)
                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 2)
                myHRP.Velocity = Vector3.zero
                myHRP.RotVelocity = Vector3.zero

                -- 2. Poison (Blobman) をターゲットに接触させる
                local poison = FindPoison()
                if not poison then
                    SpawnPoison()
                elseif poison:FindFirstChild("HumanoidRootPart") then
                    -- Poisonをターゲット位置へ飛ばす
                    poison.HumanoidRootPart.CFrame = targetHRP.CFrame
                    poison.HumanoidRootPart.Velocity = Vector3.zero
                    poison.HumanoidRootPart.RotVelocity = Vector3.zero
                end
            else
                -- キャラクターが存在しない場合待機
                IsGrabbing = false
                StatusLabel.Text = "Status: Target Lost"
            end
            RunService.RenderStepped:Wait()
        end
        IsGrabbing = false
    end)
end

-- ■■■ Buttons ■■■

-- Grab Button
local GrabBtn = Instance.new("TextButton")
GrabBtn.Size = UDim2.new(0.9, 0, 0, 50)
GrabBtn.Position = UDim2.new(0.05, 0, 0.45, 0)
GrabBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 80)
GrabBtn.Text = "GRAB & POISON"
GrabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GrabBtn.Font = Enum.Font.GothamBold
GrabBtn.TextSize = 16
GrabBtn.Parent = MainFrame
Instance.new("UICorner", GrabBtn).CornerRadius = UDim.new(0, 8)
local Stroke1 = Instance.new("UIStroke")
Stroke1.Color = Color3.fromRGB(170, 0, 255)
Stroke1.Thickness = 2
Stroke1.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
Stroke1.Parent = GrabBtn

GrabBtn.MouseButton1Click:Connect(function()
    local name = InputBox.Text
    local found = FindPlayer(name)
    if found then
        TargetPlayer = found
        InputBox.Text = found.Name -- フルネームに補完
        StartGrab()
    else
        StatusLabel.Text = "Status: Player not found"
    end
end)

-- Release Button
local ReleaseBtn = Instance.new("TextButton")
ReleaseBtn.Size = UDim2.new(0.9, 0, 0, 50)
ReleaseBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
ReleaseBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
ReleaseBtn.Text = "RELEASE TARGET"
ReleaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ReleaseBtn.Font = Enum.Font.GothamBold
ReleaseBtn.TextSize = 16
ReleaseBtn.Parent = MainFrame
Instance.new("UICorner", ReleaseBtn).CornerRadius = UDim.new(0, 8)
local Stroke2 = Instance.new("UIStroke")
Stroke2.Color = Color3.fromRGB(255, 50, 50)
Stroke2.Thickness = 1
Stroke2.Parent = ReleaseBtn

ReleaseBtn.MouseButton1Click:Connect(function()
    IsGrabbing = false
    StatusLabel.Text = "Status: Released"
    StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
end)

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = MainFrame
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)

CloseBtn.MouseButton1Click:Connect(function()
    IsGrabbing = false
    ScreenGui:Destroy()
end)

print("Poison Grab UI Loaded")
