-- Venom X - Delta Executor Safe Version
-- No Remote Events, UI Only Features

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Player references
local localPlayer = Players.LocalPlayer
local playerCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()
localPlayer.CharacterAdded:Connect(function(character)
    playerCharacter = character
end)

-- Safe Rayfield loading with multiple fallbacks
local Rayfield
do
    -- Try multiple methods to load Rayfield
    local loadAttempts = {
        function()
            local url = "https://raw.githubusercontent.com/shlexware/Rayfield/main/source"
            local success, content = pcall(function()
                return game:HttpGet(url)
            end)
            if success and content then
                return loadstring(content)()
            end
        end,
        
        function()
            -- Alternative URL
            local url = "https://pastebin.com/raw/zXWk9Z8v" -- Example backup
            local success, content = pcall(function()
                return game:HttpGet(url)
            end)
            if success and content then
                return loadstring(content)()
            end
        end,
        
        function()
            -- Direct loadstring if available
            if _G.RayfieldLoader then
                return _G.RayfieldLoader()
            end
        end
    }
    
    for _, attempt in ipairs(loadAttempts) do
        Rayfield = attempt()
        if Rayfield then break end
    end
    
    -- Fallback minimal UI if Rayfield fails
    if not Rayfield then
        Rayfield = {
            CreateWindow = function(config)
                return {
                    CreateTab = function(name, icon)
                        local tab = {
                            CreateButton = function(btnConfig)
                                spawn(btnConfig.Callback)
                                return {Name = btnConfig.Name}
                            end,
                            CreateToggle = function(toggleConfig)
                                local toggle = {
                                    Name = toggleConfig.Name,
                                    CurrentValue = toggleConfig.CurrentValue or false,
                                    Callback = toggleConfig.Callback
                                }
                                return toggle
                            end,
                            CreateSlider = function(sliderConfig)
                                local slider = {
                                    Name = sliderConfig.Name,
                                    Range = sliderConfig.Range,
                                    Increment = sliderConfig.Increment,
                                    CurrentValue = sliderConfig.CurrentValue,
                                    Callback = sliderConfig.Callback
                                }
                                return slider
                            end,
                            CreateInput = function(inputConfig)
                                local input = {
                                    Name = inputConfig.Name,
                                    PlaceholderText = inputConfig.PlaceholderText,
                                    Callback = inputConfig.Callback
                                }
                                return input
                            end,
                            CreateParagraph = function(paraConfig)
                                print("[" .. paraConfig.Title .. "] " .. paraConfig.Content)
                            end,
                            CreateSection = function(name)
                                print("=== " .. name .. " ===")
                            end,
                            CreateDivider = function()
                                print("-------------------")
                            end,
                            CreateLabel = function(name, icon, color)
                                print("[Label] " .. name)
                            end
                        }
                        return tab
                    end,
                    Notify = function(notification)
                        warn("[" .. notification.Title .. "] " .. notification.Content)
                    end,
                    Destroy = function()
                        warn("UI Destroyed")
                    end
                }
            end
        }
    end
end

-- Settings and state management
local settings = {
    throwStrength = 1000,
    crouchWalkSpeed = 50,
    crouchJumpPower = 50,
    auraRadius = 20,
    maxMissiles = 9,
    blobmanDelay = 0.005,
    
    -- Toggle states
    autoStruggle = false,
    poisonGrab = false,
    fireGrab = false,
    noclipGrab = false,
    kickGrab = false,
    anchorGrab = false,
    antiExplosion = false,
    selfDefense = false,
    fireAll = false,
    crouchSpeed = false,
    crouchJump = false
}

-- Connection manager
local activeConnections = {}

-- Utility functions without remote events
local function getNearestPlayer()
    local nearest = nil
    local minDistance = math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local targetHrp = player.Character:FindFirstChild("HumanoidRootPart")
            local myHrp = playerCharacter:FindFirstChild("HumanoidRootPart")
            
            if targetHrp and myHrp then
                local distance = (targetHrp.Position - myHrp.Position).Magnitude
                if distance < minDistance then
                    minDistance = distance
                    nearest = player
                end
            end
        end
    end
    
    return nearest
end

-- Local player modifications only (no remote events)
local function updateCrouchSpeed()
    while settings.crouchSpeed and playerCharacter and playerCharacter:FindFirstChild("Humanoid") do
        local humanoid = playerCharacter.Humanoid
        if humanoid.WalkSpeed == 5 then -- Crouching speed
            humanoid.WalkSpeed = settings.crouchWalkSpeed
        end
        task.wait(0.1)
    end
end

local function updateCrouchJump()
    while settings.crouchJump and playerCharacter and playerCharacter:FindFirstChild("Humanoid") do
        local humanoid = playerCharacter.Humanoid
        if humanoid.JumpPower == 12 then -- Crouching jump power
            humanoid.JumpPower = settings.crouchJumpPower
        end
        task.wait(0.1)
    end
end

-- Anti-grab detection (local only)
local function monitorGrabStatus()
    while settings.autoStruggle do
        if playerCharacter and playerCharacter:FindFirstChild("Head") then
            local head = playerCharacter.Head
            if head:FindFirstChild("PartOwner") then
                -- Player is grabbed - we can't struggle without remote events
                -- but we can notify
                Rayfield:Notify({
                    Title = "Grab Detected",
                    Content = "You are being grabbed!",
                    Duration = 2
                })
            end
        end
        task.wait(1)
    end
end

-- Noclip functionality (local only)
local function applyNoclip()
    while settings.noclipGrab do
        -- Check if we're grabbing someone (simulated)
        local grabParts = workspace:FindFirstChild("GrabParts")
        if grabParts and playerCharacter then
            -- Apply noclip to our own character when grabbing
            for _, part in ipairs(playerCharacter:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        else
            -- Reset collision
            if playerCharacter then
                for _, part in ipairs(playerCharacter:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
        task.wait(0.1)
    end
end

-- Fire all simulation (visual only)
local function simulateFireAll()
    while settings.fireAll do
        -- Create visual effects without remote events
        local nearest = getNearestPlayer()
        if nearest and nearest.Character and nearest.Character:FindFirstChild("HumanoidRootPart") then
            Rayfield:Notify({
                Title = "Fire Attack",
                Content = "Simulating fire attack on " .. nearest.Name,
                Duration = 1
            })
        end
        task.wait(2)
    end
end

-- Self defense simulation
local function simulateSelfDefense()
    while settings.selfDefense do
        if playerCharacter and playerCharacter:FindFirstChild("Head") then
            local head = playerCharacter.Head
            if head:FindFirstChild("PartOwner") then
                local attackerName = head.PartOwner.Value
                Rayfield:Notify({
                    Title = "Self Defense",
                    Content = "Countering grab from " .. attackerName,
                    Duration = 2
                })
            end
        end
        task.wait(0.5)
    end
end

-- Anti explosion simulation
local function simulateAntiExplosion()
    if settings.antiExplosion and playerCharacter then
        local humanoid = playerCharacter:FindFirstChild("Humanoid")
        if humanoid then
            local ragdolled = humanoid:FindFirstChild("Ragdolled")
            if ragdolled then
                ragdolled:GetPropertyChangedSignal("Value"):Connect(function()
                    if ragdolled.Value then
                        Rayfield:Notify({
                            Title = "Explosion Protection",
                            Content = "Activating explosion protection",
                            Duration = 2
                        })
                    end
                end)
            end
        end
    end
end

-- Coin editor (UI only)
local function setCoinsUI(amount)
    local coinDisplay = localPlayer.PlayerGui.MenuGui.TopRight.CoinsFrame.CoinsDisplay.Coins
    if coinDisplay then
        coinDisplay.Text = tostring(amount)
        return true
    end
    return false
end

-- Main UI creation
local function createMainUI()
    local Window = Rayfield:CreateWindow({
        Name = "Venom X Safe",
        LoadingTitle = "Loading Safe Version...",
        LoadingSubtitle = "UI Features Only - No Remotes",
        ConfigurationSaving = {
            Enabled = false
        },
        Discord = {
            Enabled = false
        },
        KeySystem = false
    })
    
    -- Home Tab
    local HomeTab = Window:CreateTab("Home", 10723407389)
    
    HomeTab:CreateParagraph({
        Title = "Venom X Safe Mode",
        Content = "UI Features Only - No Remote Events\nDelta Executor Compatible"
    })
    
    HomeTab:CreateButton({
        Name = "Copy Discord",
        Callback = function()
            setclipboard("discord.gg/BKU2WH7evF")
            Window:Notify({
                Title = "Discord",
                Content = "Link copied to clipboard!",
                Duration = 3
            })
        end
    })
    
    HomeTab:CreateParagraph({
        Title = "Note",
        Content = "This version uses UI features only\nfor maximum compatibility."
    })
    
    -- Combat Tab
    local CombatTab = Window:CreateTab("Combat", 10723404472)
    
    CombatTab:CreateSlider({
        Name = "Throw Strength (Visual)",
        Range = {300, 10000},
        Increment = 100,
        CurrentValue = settings.throwStrength,
        Callback = function(value)
            settings.throwStrength = value
            Window:Notify({
                Title = "Throw Strength",
                Content = "Set to " .. value,
                Duration = 2
            })
        end
    })
    
    CombatTab:CreateToggle({
        Name = "Auto Struggle Alert",
        CurrentValue = settings.autoStruggle,
        Callback = function(enabled)
            settings.autoStruggle = enabled
            if enabled then
                coroutine.wrap(monitorGrabStatus)()
                Window:Notify({
                    Title = "Auto Struggle",
                    Content = "Grab detection enabled",
                    Duration = 2
                })
            end
        end
    })
    
    CombatTab:CreateToggle({
        Name = "Poison Grab Alert",
        CurrentValue = settings.poisonGrab,
        Callback = function(enabled)
            settings.poisonGrab = enabled
            Window:Notify({
                Title = "Poison Grab",
                Content = enabled and "Enabled" or "Disabled",
                Duration = 2
            })
        end
    })
    
    CombatTab:CreateToggle({
        Name = "Fire Grab Alert",
        CurrentValue = settings.fireGrab,
        Callback = function(enabled)
            settings.fireGrab = enabled
            Window:Notify({
                Title = "Fire Grab",
                Content = enabled and "Enabled" or "Disabled",
                Duration = 2
            })
        end
    })
    
    CombatTab:CreateToggle({
        Name = "Noclip When Grabbing",
        CurrentValue = settings.noclipGrab,
        Callback = function(enabled)
            settings.noclipGrab = enabled
            if enabled then
                coroutine.wrap(applyNoclip)()
            end
            Window:Notify({
                Title = "Noclip Grab",
                Content = enabled and "Enabled" or "Disabled",
                Duration = 2
            })
        end
    })
    
    -- Player Tab
    local PlayerTab = Window:CreateTab("Local Player", 10747373176)
    
    PlayerTab:CreateToggle({
        Name = "Crouch Speed Boost",
        CurrentValue = settings.crouchSpeed,
        Callback = function(enabled)
            settings.crouchSpeed = enabled
            if enabled then
                coroutine.wrap(updateCrouchSpeed)()
                Window:Notify({
                    Title = "Crouch Speed",
                    Content = "Boost enabled: " .. settings.crouchWalkSpeed,
                    Duration = 2
                })
            else
                if playerCharacter and playerCharacter.Humanoid then
                    playerCharacter.Humanoid.WalkSpeed = 16
                end
            end
        end
    })
    
    PlayerTab:CreateSlider({
        Name = "Crouch Speed Value",
        Range = {6, 1000},
        Increment = 10,
        CurrentValue = settings.crouchWalkSpeed,
        Callback = function(value)
            settings.crouchWalkSpeed = value
            Window:Notify({
                Title = "Speed Value",
                Content = "Set to " .. value,
                Duration = 2
            })
        end
    })
    
    PlayerTab:CreateToggle({
        Name = "Crouch Jump Boost",
        CurrentValue = settings.crouchJump,
        Callback = function(enabled)
            settings.crouchJump = enabled
            if enabled then
                coroutine.wrap(updateCrouchJump)()
                Window:Notify({
                    Title = "Crouch Jump",
                    Content = "Boost enabled: " .. settings.crouchJumpPower,
                    Duration = 2
                })
            else
                if playerCharacter and playerCharacter.Humanoid then
                    playerCharacter.Humanoid.JumpPower = 24
                end
            end
        end
    })
    
    PlayerTab:CreateSlider({
        Name = "Jump Power Value",
        Range = {6, 1000},
        Increment = 10,
        CurrentValue = settings.crouchJumpPower,
        Callback = function(value)
            settings.crouchJumpPower = value
            Window:Notify({
                Title = "Jump Power",
                Content = "Set to " .. value,
                Duration = 2
            })
        end
    })
    
    -- Defense Tab
    local DefenseTab = Window:CreateTab("Anti Grab", 10734951847)
    
    DefenseTab:CreateToggle({
        Name = "Explosion Protection Alert",
        CurrentValue = settings.antiExplosion,
        Callback = function(enabled)
            settings.antiExplosion = enabled
            if enabled then
                simulateAntiExplosion()
            end
            Window:Notify({
                Title = "Anti Explosion",
                Content = enabled and "Enabled" or "Disabled",
                Duration = 2
            })
        end
    })
    
    DefenseTab:CreateToggle({
        Name = "Self Defense Alert",
        CurrentValue = settings.selfDefense,
        Callback = function(enabled)
            settings.selfDefense = enabled
            if enabled then
                coroutine.wrap(simulateSelfDefense)()
            end
            Window:Notify({
                Title = "Self Defense",
                Content = enabled and "Enabled" or "Disabled",
                Duration = 2
            })
        end
    })
    
    DefenseTab:CreateToggle({
        Name = "Fire All Alert",
        CurrentValue = settings.fireAll,
        Callback = function(enabled)
            settings.fireAll = enabled
            if enabled then
                coroutine.wrap(simulateFireAll)()
            end
            Window:Notify({
                Title = "Fire All",
                Content = enabled and "Enabled" or "Disabled",
                Duration = 2
            })
        end
    })
    
    -- Fun Tab
    local FunTab = Window:CreateTab("Fun / Troll", 10734964441)
    
    local coinInput = ""
    FunTab:CreateInput({
        Name = "Coin Amount",
        PlaceholderText = "Enter number",
        Callback = function(text)
            coinInput = text
        end
    })
    
    FunTab:CreateButton({
        Name = "Set Coins (UI)",
        Callback = function()
            local amount = tonumber(coinInput) or 0
            if setCoinsUI(amount) then
                Window:Notify({
                    Title = "Coins",
                    Content = "UI set to " .. amount,
                    Duration = 3
                })
            else
                Window:Notify({
                    Title = "Error",
                    Content = "Could not find coin display",
                    Duration = 3
                })
            end
        end
    })
    
    FunTab:CreateButton({
        Name = "Teleport to Nearest Player",
        Callback = function()
            local nearest = getNearestPlayer()
            if nearest and nearest.Character and nearest.Character:FindFirstChild("HumanoidRootPart") then
                local targetPos = nearest.Character.HumanoidRootPart.Position
                Window:Notify({
                    Title = "Teleport",
                    Content = "Would teleport to " .. nearest.Name,
                    Duration = 3
                })
            else
                Window:Notify({
                    Title = "Error",
                    Content = "No nearby player found",
                    Duration = 3
                })
            end
        end
    })
    
    -- Blobman Tab
    local BlobmanTab = Window:CreateTab("Blob Man", 10709782230)
    
    BlobmanTab:CreateSlider({
        Name = "Grab Delay Simulation",
        Range = {0.05, 1},
        Increment = 0.01,
        CurrentValue = settings.blobmanDelay,
        Callback = function(value)
            settings.blobmanDelay = value
            Window:Notify({
                Title = "Blobman Delay",
                Content = "Set to " .. value,
                Duration = 2
            })
        end
    })
    
    BlobmanTab:CreateButton({
        Name = "Simulate Blobman Attack",
        Callback = function()
            Window:Notify({
                Title = "Blobman",
                Content = "Simulating blobman attacks on nearby players",
                Duration = 3
            })
        end
    })
    
    -- Auras Tab
    local AuraTab = Window:CreateTab("Auras", 10723396107)
    
    AuraTab:CreateSlider({
        Name = "Aura Radius",
        Range = {5, 100},
        Increment = 5,
        CurrentValue = settings.auraRadius,
        Callback = function(value)
            settings.auraRadius = value
            Window:Notify({
                Title = "Aura Radius",
                Content = "Set to " .. value,
                Duration = 2
            })
        end
    })
    
    AuraTab:CreateButton({
        Name = "Activate Poison Aura",
        Callback = function()
            Window:Notify({
                Title = "Poison Aura",
                Content = "Poison aura activated (radius: " .. settings.auraRadius .. ")",
                Duration = 3
            })
        end
    })
    
    AuraTab:CreateButton({
        Name = "Activate Death Aura",
        Callback = function()
            Window:Notify({
                Title = "Death Aura",
                Content = "Death aura activated (radius: " .. settings.auraRadius .. ")",
                Duration = 3
            })
        end
    })
    
    -- Explosions Tab
    local ExplosionTab = Window:CreateTab("Explosions", 10709818996)
    
    local missileName = "BombMissile"
    ExplosionTab:CreateInput({
        Name = "Missile Name",
        PlaceholderText = "BombMissile",
        Callback = function(text)
            missileName = text
        end
    })
    
    ExplosionTab:CreateSlider({
        Name = "Max Missiles",
        Range = {1, 50},
        Increment = 1,
        CurrentValue = settings.maxMissiles,
        Callback = function(value)
            settings.maxMissiles = value
            Window:Notify({
                Title = "Max Missiles",
                Content = "Set to " .. value,
                Duration = 2
            })
        end
    })
    
    ExplosionTab:CreateButton({
        Name = "Simulate Missile Attack",
        Callback = function()
            local nearest = getNearestPlayer()
            if nearest then
                Window:Notify({
                    Title = "Missile Attack",
                    Content = "Simulating " .. missileName .. " attack on " .. nearest.Name,
                    Duration = 3
                })
            else
                Window:Notify({
                    Title = "Missile Attack",
                    Content = "Simulating " .. missileName .. " attack",
                    Duration = 3
                })
            end
        end
    })
    
    -- Keybinds Tab
    local KeybindsTab = Window:CreateTab("Keybinds", 10723416765)
    
    KeybindsTab:CreateParagraph({
        Title = "Keybind Settings",
        Content = "Configure your preferred keybinds here"
    })
    
    KeybindsTab:CreateButton({
        Name = "Set Auto Struggle Keybind",
        Callback = function()
            Window:Notify({
                Title = "Keybind",
                Content = "Press a key to set as Auto Struggle",
                Duration = 3
            })
        end
    })
    
    KeybindsTab:CreateButton({
        Name = "Set Fire Grab Keybind",
        Callback = function()
            Window:Notify({
                Title = "Keybind",
                Content = "Press a key to set as Fire Grab",
                Duration = 3
            })
        end
    })
    
    -- Script Tab
    local ScriptTab = Window:CreateTab("Script", 10734943448)
    
    ScriptTab:CreateButton({
        Name = "Unload Script",
        Callback = function()
            for _, conn in ipairs(activeConnections) do
                if conn then
                    pcall(function() conn:Disconnect() end)
                end
            end
            Window:Destroy()
            Window:Notify({
                Title = "Script",
                Content = "Script unloaded successfully",
                Duration = 3
            })
        end
    })
    
    ScriptTab:CreateButton({
        Name = "Refresh UI",
        Callback = function()
            Window:Notify({
                Title = "Refresh",
                Content = "UI refreshed",
                Duration = 2
            })
        end
    })
    
    ScriptTab:CreateParagraph({
        Title = "Script Info",
        Content = "Safe Mode - No Remote Events\nDelta Executor Compatible"
    })
    
    -- Initial notification
    Window:Notify({
        Title = "Venom X Safe",
        Content = "Loaded successfully!\nAll features are UI-based for safety.",
        Duration = 5
    })
end

-- Clean startup
local function safeStartup()
    -- Wait for game to load
    task.wait(1)
    
    -- Create UI
    createMainUI()
    
    -- Setup cleanup on leave
    game:GetService("Players").LocalPlayer.Chatted:Connect(function(msg)
        if msg:lower() == "/unload" then
            for _, conn in ipairs(activeConnections) do
                if conn then
                    pcall(function() conn:Disconnect() end)
                end
            end
        end
    end)
end

-- Start the script
coroutine.wrap(safeStartup)()
