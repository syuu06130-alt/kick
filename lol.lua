-- Blobman Auto Spawn + Kick (All or Single) Toggle Script for Fling Things and People
-- 修正版: 正しいRemote名 "CreatureBlobman" 使用、0.01秒高速ループ、自動Spawn/Mount、トグルオンオフ
-- 使い方: Fling Things and Peopleに入って実行。Blobman自動スポーン&マウント。
-- GUIで "All Kick" ボタン: All Playerループキックオン/オフ
-- "Kick Player" ボタン: ドロップダウンで単体選択&ループキックオン/オフ

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BlobmanKickGui"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 200)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.Text = "Blobman Kick (修正版)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.Font = Enum.Font.SourceSansBold
Title.Parent = MainFrame

local SpawnButton = Instance.new("TextButton")
SpawnButton.Size = UDim2.new(1, -20, 0, 30)
SpawnButton.Position = UDim2.new(0, 10, 0, 40)
SpawnButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
SpawnButton.Text = "Auto Spawn & Mount Blobman"
SpawnButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SpawnButton.TextScaled = true
SpawnButton.Font = Enum.Font.SourceSans
SpawnButton.Parent = MainFrame

local AllKickToggle = Instance.new("TextButton")
AllKickToggle.Size = UDim2.new(1, -20, 0, 30)
AllKickToggle.Position = UDim2.new(0, 10, 0, 80)
AllKickToggle.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
AllKickToggle.Text = "All Kick: OFF"
AllKickToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
AllKickToggle.TextScaled = true
AllKickToggle.Font = Enum.Font.SourceSans
AllKickToggle.Parent = MainFrame

local PlayerFrame = Instance.new("ScrollingFrame")
PlayerFrame.Size = UDim2.new(1, -20, 0, 50)
PlayerFrame.Position = UDim2.new(0, 10, 0, 120)
PlayerFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
PlayerFrame.BorderSizePixel = 0
PlayerFrame.ScrollBarThickness = 5
PlayerFrame.Parent = MainFrame

local SingleKickToggle = Instance.new("TextButton")
SingleKickToggle.Size = UDim2.new(1, -20, 0, 30)
SingleKickToggle.Position = UDim2.new(0, 10, 1, -30)
SingleKickToggle.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
SingleKickToggle.Text = "Kick Selected: OFF"
SingleKickToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
SingleKickToggle.TextScaled = true
SingleKickToggle.Font = Enum.Font.SourceSans
SingleKickToggle.Parent = MainFrame

-- Variables
local blobman = nil
local originPos = HumanoidRootPart.Position
local allKickEnabled = false
local singleKickEnabled = false
local selectedPlayer = nil
local connection = nil

-- Update Origin
local function updateOrigin()
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        originPos = Character.HumanoidRootPart.Position
    end
end

-- Spawn Blobman
local function spawnAndMount()
    pcall(function()
        local spawnPos = CFrame.new(originPos + Vector3.new(0, 10, 0))
        ReplicatedStorage.MenuToys.SpawnToyRemoteFunction:InvokeServer("CreatureBlobman", spawnPos, Vector3.new(0, 59.667, 0))
    end)
    
    wait(0.5)
    
    local toysFolder = workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
    if toysFolder then
        blobman = toysFolder:FindFirstChild("CreatureBlobman")
        if blobman then
            -- Mount
            local hum = Character:FindFirstChildOfClass("Humanoid")
            local seat = blobman:FindFirstChild("VehicleSeat")
            if seat and hum then
                Character.HumanoidRootPart.CFrame = seat.CFrame + Vector3.new(0, 5, 0)
                seat:Sit(hum)
                wait(0.5)
                print("Blobman Mounted!")
                return true
            end
        end
    end
    print("Failed to spawn/mount Blobman")
    return false
end

-- Teleport Blobman to target fast (0.01s sim)
local function tpBlobmanToTarget(targetHRP)
    if not blobman or not blobman.PrimaryPart then return end
    local targetPos = targetHRP.Position + Vector3.new(0, 5, 0)
    local bp = Instance.new("BodyPosition")
    bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bp.Position = targetPos
    bp.P = 1e6
    bp.Parent = blobman.PrimaryPart
    game:GetService("Debris"):AddItem(bp, 0.01)
    blobman:SetPrimaryPartCFrame(CFrame.new(targetPos))
end

-- TP Blobman back to origin
local function tpBlobmanToOrigin()
    if not blobman or not blobman.PrimaryPart then return end
    local bp = Instance.new("BodyPosition")
    bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bp.Position = originPos + Vector3.new(0, 10, 0)
    bp.P = 1e6
    bp.Parent = blobman.PrimaryPart
    game:GetService("Debris"):AddItem(bp, 0.01)
    blobman:SetPrimaryPartCFrame(CFrame.new(originPos + Vector3.new(0, 10, 0)))
end

-- Grab target with Blobman (alternate sides)
local grabSide = 1
local function grabTarget(targetPlayer)
    if not blobman then return end
    local targetHRP = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    
    local scriptObj = blobman:FindFirstChild("BlobmanSeatAndOwnerScript")
    if not scriptObj then return end
    
    local grabRemote = scriptObj:FindFirstChild("CreatureGrab")
    if not grabRemote then return end
    
    local detectors = {blobman:FindFirstChild("RightDetector"), blobman:FindFirstChild("LeftDetector")}
    local detector = detectors[grabSide] or detectors[1]
    if detector then
        local weld = detector:FindFirstChild("RightWeld") or detector:FindFirstChild("LeftWeld") or detector:FindFirstChild("RigidConstraint")
        if weld then
            pcall(function()
                grabRemote:FireServer(detector, targetHRP, weld)
            end)
        end
    end
    grabSide = grabSide == 1 and 2 or 1
end

-- Drop/Throw
local function dropTarget()
    if not blobman then return end
    local scriptObj = blobman:FindFirstChild("BlobmanSeatAndOwnerScript")
    if not scriptObj then return end
    
    local dropRemote = scriptObj:FindFirstChild("CreatureDrop")
    if dropRemote then
        -- Drop on any attached (assumes recent grab)
        local detectors = {blobman:FindFirstChild("LeftDetector"), blobman:FindFirstChild("RightDetector")}
        for _, detector in pairs(detectors) do
            if detector then
                local weld = detector:FindFirstChild("LeftWeld") or detector:FindFirstChild("RightWeld") or detector:FindFirstChild("RigidConstraint")
                if weld then
                    pcall(function()
                        dropRemote:FireServer(weld, Character.HumanoidRootPart)  -- or target, but cycle uses own?
                    end)
                end
            end
        end
    end
end

-- Single Kick Loop
local function singleKickLoop()
    if not singleKickEnabled or not selectedPlayer or not selectedPlayer.Parent then return end
    local targetHRP = selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    
    updateOrigin()
    tpBlobmanToTarget(targetHRP)
    wait(0.01)
    grabTarget(selectedPlayer)
    wait(0.01)
    tpBlobmanToOrigin()
    wait(0.01)
    dropTarget()
    wait(0.01)
end

-- All Kick Loop
local function allKickLoop()
    if not allKickEnabled then return end
    updateOrigin()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetHRP = player.Character.HumanoidRootPart
            tpBlobmanToTarget(targetHRP)
            wait(0.01)
            grabTarget(player)
            wait(0.01)
            tpBlobmanToOrigin()
            wait(0.01)
            dropTarget()
            wait(0.01)
        end
    end
end

-- Main Loop
connection = RunService.Heartbeat:Connect(function()
    if allKickEnabled then
        allKickLoop()
    elseif singleKickEnabled then
        singleKickLoop()
    end
end)

-- Update Player List
local function updatePlayerList()
    for _, child in pairs(PlayerFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = PlayerFrame
    layout.SortOrder = Enum.SortOrder.Name
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 25)
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            btn.Text = player.Name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextScaled = true
            btn.Font = Enum.Font.SourceSans
            btn.Parent = PlayerFrame
            
            btn.MouseButton1Click:Connect(function()
                selectedPlayer = player
                print("Selected: " .. player.Name)
            end)
        end
    end
    
    PlayerFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
end

Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)
updatePlayerList()

-- Button Events
SpawnButton.MouseButton1Click:Connect(function()
    spawnAndMount()
end)

AllKickToggle.MouseButton1Click:Connect(function()
    allKickEnabled = not allKickEnabled
    AllKickToggle.Text = allKickEnabled and "All Kick: ON" or "All Kick: OFF"
    AllKickToggle.BackgroundColor3 = allKickEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(255, 100, 100)
end)

SingleKickToggle.MouseButton1Click:Connect(function()
    singleKickEnabled = not singleKickEnabled
    SingleKickToggle.Text = singleKickEnabled and "Kick Selected: ON" or "Kick Selected: OFF"
    SingleKickToggle.BackgroundColor3 = singleKickEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(255, 100, 100)
end)

-- Character Respawn
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
    spawnAndMount()  -- Auto respawn Blobman
end)

print("Blobman Kick Script Loaded! 全ての機能修正完了。")
