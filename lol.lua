--[[
    Syu_hub v8.3 | Multi-Target Support & Auto Blobman
    Target: Fling Things and People
    Features: Auto-Spawn Blobman, Single/All Kick, Toggle On/Off
    Fix: Reaction Issues, Enhanced Loop for Grab-Throw Cycle
]]

-- ■■■ Services ■■■
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ■■■ Variables ■■■
local TargetPlayerNames = {}  -- Now supports multiple targets (table)
local IsAttacking = false
local OriginalPosition = nil
local MinimizeLevel = 0 -- 0:Max, 1:Bar, 2:Small

-- ■■■ Utility Functions ■■■

local function Notify(msg)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Syu_hub";
        Text = msg;
        Duration = 3;
    })
    print("[Syu_hub] " .. msg)
end

local function GetPlayerNames(includeAll)
    local names = {}
    if includeAll then
        table.insert(names, "All Players")
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    return names
end

-- ■■■ Logic Functions ■■■

function GetBlobman()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    local blobman = nil
    local shortestDist = 500
    
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and (v.Name == "Blobman" or v.Name == "Ragdoll") and not Players:GetPlayerFromCharacter(v) then
            local root = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Torso")
            if root then
                if hrp then
                    local dist = (root.Position - hrp.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        blobman = v
                    end
                else
                    blobman = v
                end
            end
        end
    end
    return blobman
end

function SpawnBlobman()
    local args = { [1] = "Blobman" }
    for _, desc in pairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("RemoteEvent") and (string.find(desc.Name:lower(), "spawn") or string.find(desc.Name:lower(), "create")) then
            pcall(function() desc:FireServer(unpack(args)) end)
        end
    end
    -- Wait briefly for spawn
    task.wait(0.1)
end

function TriggerGrab(part)
    for _, desc in pairs(LocalPlayer.Character:GetDescendants()) do
        if desc:IsA("RemoteEvent") and (string.find(desc.Name:lower(), "grab") or string.find(desc.Name:lower(), "interact")) then
            pcall(function() desc:FireServer(part) end)
        end
    end
    for _, desc in pairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("RemoteEvent") and (string.find(desc.Name:lower(), "grab") or string.find(desc.Name:lower(), "interact")) then
            pcall(function() desc:FireServer(part) end)
        end
    end
end

function TriggerThrow()
    for _, desc in pairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("RemoteEvent") and (string.find(desc.Name:lower(), "throw") or string.find(desc.Name:lower(), "release")) then
            pcall(function() desc:FireServer(Vector3.new(0, 100, 0)) end)  -- Increased throw force for better fling
        end
    end
end

-- ■■■ Attack Loop (Enhanced for Multi-Target & Auto Blobman) ■■■
function StartLoopAttack(targets)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if not OriginalPosition then OriginalPosition = hrp.CFrame end
    local startTime = tick()
    
    while IsAttacking and (tick() - startTime < 60) do
        for _, targetName in ipairs(targets) do
            if not IsAttacking then break end
            local target = Players:FindFirstChild(targetName)
            if target and target.Character then
                local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
                if targetHrp then
                    -- Auto-Spawn Blobman if not found
                    local ammo = GetBlobman()
                    if not ammo then
                        SpawnBlobman()
                        ammo = GetBlobman()
                    end
                    
                    if ammo then
                        -- Move to target (0.01s simulation)
                        hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, -2)  -- Position behind target for grab
                        task.wait(0.01)
                        
                        -- Position Blobman for grab
                        local ammoRoot = ammo:FindFirstChild("HumanoidRootPart") or ammo:FindFirstChild("Torso")
                        if ammoRoot then
                            ammoRoot.CFrame = hrp.CFrame * CFrame.new(0, 0, -1)
                            ammoRoot.Velocity = Vector3.zero
                            ammoRoot.AssemblyLinearVelocity = Vector3.zero
                        end
                        
                        -- Grab with Blobman (assuming game mechanics handle Blobman as tool)
                        TriggerGrab(targetHrp)
                        task.wait(0.01)
                        
                        -- Return to original position (0.01s)
                        hrp.CFrame = OriginalPosition
                        task.wait(0.01)
                        
                        -- Throw and repeat grab-throw cycle
                        hrp.Velocity = hrp.CFrame.LookVector * 100 + Vector3.new(0, 50, 0)
                        TriggerThrow()
                        task.wait(0.01)
                        
                        -- Quick re-grab simulation for cycle
                        TriggerGrab(targetHrp)
                        task.wait(0.01)
                    end
                end
            end
        end
        task.wait(0.05)  -- Slight delay to prevent overload
    end

    IsAttacking = false
    if OriginalPosition and hrp then
        hrp.CFrame = OriginalPosition
        hrp.Velocity = Vector3.zero
        hrp.AssemblyLinearVelocity = Vector3.zero
        OriginalPosition = nil
    end
    Notify("Loop Finished.")
end

-- ■■■ UI Construction ■■■

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SyuHub_v8_3"
ScreenGui.ResetOnSpawn = false
if game.CoreGui:FindFirstChild("SyuHub_v8_3") then
    game.CoreGui.SyuHub_v8_3:Destroy()
end
ScreenGui.Parent = game.CoreGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 350, 0, 400)
MainFrame.Position = UDim2.new(0.5, -175, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 1
MainFrame.BorderColor3 = Color3.fromRGB(60, 60, 100)
MainFrame.Parent = ScreenGui
MainFrame.ClipsDescendants = true 

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Title Bar
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
TitleText.Text = "Syu_hub v8.3 | Multi Fixed"
TitleText.TextColor3 = Color3.fromRGB(200, 200, 255)
TitleText.BackgroundTransparency = 1
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 16
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -40, 0, 5)
MinBtn.Text = "-"
MinBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
MinBtn.TextColor3 = Color3.new(1,1,1)
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- Content Area
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -50)
ScrollFrame.Position = UDim2.new(0, 10, 0, 45)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.Parent = MainFrame
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)  -- Auto-size

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)

-- ■■■ Dropdown Section (With All Players) ■■■

local DropdownBtn = Instance.new("TextButton")
DropdownBtn.Size = UDim2.new(1, 0, 0, 40)
DropdownBtn.LayoutOrder = 1
DropdownBtn.Text = "Select Target ▼"
DropdownBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
DropdownBtn.TextColor3 = Color3.new(1,1,1)
DropdownBtn.Font = Enum.Font.Gotham
DropdownBtn.TextSize = 14
DropdownBtn.Parent = ScrollFrame
Instance.new("UICorner", DropdownBtn).CornerRadius = UDim.new(0, 6)

-- Container for the list items
local PlayerListContainer = Instance.new("Frame")
PlayerListContainer.LayoutOrder = 2
PlayerListContainer.Size = UDim2.new(1, 0, 0, 0) -- Initially 0 height
PlayerListContainer.BackgroundTransparency = 1
PlayerListContainer.ClipsDescendants = true
PlayerListContainer.Parent = ScrollFrame
PlayerListContainer.Visible = false

local ContainerLayout = Instance.new("UIListLayout")
ContainerLayout.Parent = PlayerListContainer
ContainerLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContainerLayout.Padding = UDim.new(0, 5)

local isDropdownOpen = false

DropdownBtn.MouseButton1Click:Connect(function()
    isDropdownOpen = not isDropdownOpen
    
    if isDropdownOpen then
        -- Refresh list
        for _, child in pairs(PlayerListContainer:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        
        local players = GetPlayerNames(true)  -- Include "All Players"
        local count = 0
        
        for _, name in ipairs(players) do
            count = count + 1
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.Text = name
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            btn.TextColor3 = Color3.new(1,1,1)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.Parent = PlayerListContainer
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            
            btn.MouseButton1Click:Connect(function()
                if name == "All Players" then
                    TargetPlayerNames = {}
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer then
                            table.insert(TargetPlayerNames, p.Name)
                        end
                    end
                    DropdownBtn.Text = "Target: All Players"
                    Notify("Selected: All Players")
                else
                    TargetPlayerNames = {name}
                    DropdownBtn.Text = "Target: " .. name
                    Notify("Selected: " .. name)
                end
                
                -- Close menu
                isDropdownOpen = false
                PlayerListContainer.Visible = false
                PlayerListContainer.Size = UDim2.new(1, 0, 0, 0)
                ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 50)
            end)
        end
        
        -- Resize container and ScrollFrame
        local height = count * 35
        PlayerListContainer.Size = UDim2.new(1, 0, 0, height)
        PlayerListContainer.Visible = true
        
        -- Update ScrollFrame canvas
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + height + 100)
    else
        PlayerListContainer.Visible = false
        PlayerListContainer.Size = UDim2.new(1, 0, 0, 0)
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
    end
end)

-- ■■■ Toggle Button ■■■

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, 0, 0, 50)
ToggleBtn.LayoutOrder = 3
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
        if #TargetPlayerNames == 0 then
            Notify("Select a target first!")
            IsAttacking = false
            return
        end
        
        ToggleBtn.Text = "STOP LOOP (ON)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        
        task.spawn(function()
            StartLoopAttack(TargetPlayerNames)
            -- Reset after loop ends
            IsAttacking = false
            ToggleBtn.Text = "START LOOP (OFF)"
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
        end)
    else
        ToggleBtn.Text = "START LOOP (OFF)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
    end
end)

-- ■■■ Spawn Button ■■■

local SpawnBtn = Instance.new("TextButton")
SpawnBtn.Size = UDim2.new(1, 0, 0, 40)
SpawnBtn.LayoutOrder = 4
SpawnBtn.Text = "Manual Spawn Blobman"
SpawnBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
SpawnBtn.TextColor3 = Color3.new(1,1,1)
SpawnBtn.Parent = ScrollFrame
Instance.new("UICorner", SpawnBtn).CornerRadius = UDim.new(0, 8)

SpawnBtn.MouseButton1Click:Connect(function()
    SpawnBlobman()
    Notify("Blobman Spawned Manually")
end)

-- ■■■ Window Features ■■■

MinBtn.MouseButton1Click:Connect(function()
    MinimizeLevel = (MinimizeLevel + 1) % 3
    if MinimizeLevel == 0 then
        MainFrame:TweenSize(UDim2.new(0, 350, 0, 400), "Out", "Quad", 0.3)
        ScrollFrame.Visible = true
        MinBtn.Text = "-"
        TitleText.Visible = true
    elseif MinimizeLevel == 1 then
        MainFrame:TweenSize(UDim2.new(0, 350, 0, 40), "Out", "Quad", 0.3)
        ScrollFrame.Visible = false
        MinBtn.Text = "□"
        TitleText.Visible = true
    elseif MinimizeLevel == 2 then
        MainFrame:TweenSize(UDim2.new(0, 120, 0, 40), "Out", "Quad", 0.3)
        ScrollFrame.Visible = false
        MinBtn.Text = "Max"
        TitleText.Visible = false
    end
end)

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
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Initial Canvas Size Update
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 50)

-- Player Join/Leave Refresh
Players.PlayerAdded:Connect(function()
    if isDropdownOpen then
        DropdownBtn.MouseButton1Click:Invoke()  -- Close and reopen to refresh
        DropdownBtn.MouseButton1Click:Invoke()
    end
end)
Players.PlayerRemoving:Connect(function()
    if isDropdownOpen then
        DropdownBtn.MouseButton1Click:Invoke()  -- Close and reopen to refresh
        DropdownBtn.MouseButton1Click:Invoke()
    end
end)

Notify("Syu_hub v8.3 Loaded - Auto Blobman & All Kick Enabled")
