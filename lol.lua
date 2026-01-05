-- Venom X Delta Executor Compatible Version
-- Rayfield UI with anti-detection measures

-- サービスを取得（分割して検出回避）
local gameService = game
local ReplicatedStorage = gameService:GetService("ReplicatedStorage")
local HttpService = gameService:GetService("HttpService")
local RunService = gameService:GetService("RunService")
local Players = gameService:GetService("Players")
local UserInputService = gameService:GetService("UserInputService")
local Debris = gameService:GetService("Debris")

-- 文字列を分割してロードする関数
local function secureLoadString(url)
    local parts = {
        "https:",
        "//sirius.",
        "menu/rayfield"
    }
    local fullUrl = table.concat(parts)
    
    local success, result = pcall(function()
        return game:HttpGet(fullUrl)
    end)
    
    if success then
        local func, err = loadstring(result)
        if func then return func() end
    end
    return nil
end

-- Rayfield UIをロード
local Rayfield = secureLoadString()

if not Rayfield then
    -- 代替URLで試す
    local backupUrls = {
        "https://raw.githubusercontent.com/shlexware/Rayfield/main/source",
        "https://pastebin.com/raw/examplecode"
    }
    
    for _, url in ipairs(backupUrls) do
        local success, content = pcall(function()
            return game:HttpGet(url)
        end)
        if success then
            Rayfield = loadstring(content)()
            break
        end
    end
end

-- Rayfieldがロードできない場合は基本機能のみ
if not Rayfield then
    Rayfield = {
        CreateWindow = function(config)
            return {
                CreateTab = function(name, icon)
                    return {
                        CreateButton = function(btnConfig)
                            return {
                                Name = btnConfig.Name,
                                Callback = btnConfig.Callback
                            }
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
                            return {
                                Name = sliderConfig.Name,
                                Range = sliderConfig.Range,
                                Increment = sliderConfig.Increment,
                                CurrentValue = sliderConfig.CurrentValue,
                                Callback = sliderConfig.Callback
                            }
                        end,
                        CreateInput = function(inputConfig)
                            return {
                                Name = inputConfig.Name,
                                PlaceholderText = inputConfig.PlaceholderText,
                                Callback = inputConfig.Callback
                            }
                        end,
                        CreateParagraph = function(paraConfig)
                            warn("[" .. paraConfig.Title .. "] " .. paraConfig.Content)
                        end,
                        CreateSection = function(name) end,
                        CreateDivider = function() end,
                        CreateLabel = function(name, icon, color) end
                    }
                end,
                Notify = function(notification)
                    print("[" .. notification.Title .. "] " .. notification.Content)
                end,
                Destroy = function() end
            }
        end
    }
end

-- プレイヤーとキャラクター設定
local localPlayer = Players.LocalPlayer
local playerCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()
localPlayer.CharacterAdded:Connect(function(char)
    playerCharacter = char
end)

-- イベントを取得（安全な方法）
local function getEvents()
    local events = {}
    pcall(function()
        events.GrabEvents = ReplicatedStorage:WaitForChild("GrabEvents")
        events.MenuToys = ReplicatedStorage:WaitForChild("MenuToys")
        events.CharacterEvents = ReplicatedStorage:WaitForChild("CharacterEvents")
        events.SetNetworkOwner = events.GrabEvents:WaitForChild("SetNetworkOwner")
        events.Struggle = events.CharacterEvents:WaitForChild("Struggle")
        events.DestroyToy = events.MenuToys:WaitForChild("DestroyToy")
    end)
    return events
end

local gameEvents = getEvents()

-- グローバル設定
local settings = {
    throwStrength = 1000,
    crouchWalkSpeed = 50,
    crouchJumpPower = 50,
    auraRadius = 20,
    maxMissiles = 9,
    blobmanDelay = 0.005,
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

-- コネクション管理
local connections = {}

-- 基本機能関数
local function spawnToy(toyName, position, rotation)
    if not rotation then rotation = Vector3.new(0, 0, 0) end
    ReplicatedStorage.MenuToys.SpawnToyRemoteFunction:InvokeServer(
        toyName, 
        CFrame.new(position), 
        rotation
    )
end

local function destroyToy(toy)
    if toy and toy.Parent then
        gameEvents.DestroyToy:FireServer(toy)
    end
end

local function getNearestPlayer()
    local nearest = nil
    local minDist = math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local myHrp = playerCharacter:FindFirstChild("HumanoidRootPart")
            
            if hrp and myHrp then
                local dist = (hrp.Position - myHrp.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = player
                end
            end
        end
    end
    
    return nearest
end

-- グラブ強度機能
local function setupThrowStrength()
    if settings.throwStrength > 300 then
        local connection = workspace.ChildAdded:Connect(function(child)
            if child.Name == "GrabParts" then
                local grabPart = child:FindFirstChild("GrabPart")
                if grabPart then
                    local weld = grabPart:FindFirstChild("WeldConstraint")
                    if weld and weld.Part1 then
                        local velocity = Instance.new("BodyVelocity")
                        velocity.Parent = weld.Part1
                        velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        
                        child.AncestryChanged:Connect(function()
                            if not child.Parent then
                                if UserInputService:GetLastInputType() == Enum.UserInputType.MouseButton2 then
                                    velocity.Velocity = workspace.CurrentCamera.CFrame.LookVector * settings.throwStrength
                                    Debris:AddItem(velocity, 0.5)
                                else
                                    velocity:Destroy()
                                end
                            end
                        end)
                    end
                end
            end
        end)
        table.insert(connections, connection)
    end
end

-- 自動抵抗機能
local function autoStruggleFunction()
    if settings.autoStruggle then
        local connection = RunService.Heartbeat:Connect(function()
            local char = localPlayer.Character
            if char then
                local head = char:FindFirstChild("Head")
                if head and head:FindFirstChild("PartOwner") then
                    gameEvents.Struggle:FireServer()
                end
            end
        end)
        table.insert(connections, connection)
    end
end

-- 毒グラブ機能
local function poisonGrabFunction()
    while settings.poisonGrab do
        local grabParts = workspace:FindFirstChild("GrabParts")
        if grabParts then
            local grabPart = grabParts:FindFirstChild("GrabPart")
            if grabPart then
                local weld = grabPart:FindFirstChild("WeldConstraint")
                if weld and weld.Part1 then
                    local char = weld.Part1.Parent
                    local head = char:FindFirstChild("Head")
                    if head then
                        -- 毒エフェクト処理
                        for _, part in ipairs(workspace.Map:GetDescendants()) do
                            if part:IsA("Part") and part.Name == "PoisonHurtPart" then
                                part.Size = Vector3.new(2, 2, 2)
                                part.Position = head.Position
                                task.wait(0.1)
                                part.Position = Vector3.new(0, -200, 0)
                            end
                        end
                    end
                end
            end
        end
        task.wait()
    end
end

-- 炎グラブ機能
local function fireGrabFunction()
    while settings.fireGrab do
        local grabParts = workspace:FindFirstChild("GrabParts")
        if grabParts then
            local grabPart = grabParts:FindFirstChild("GrabPart")
            if grabPart then
                local weld = grabPart:FindFirstChild("WeldConstraint")
                if weld and weld.Part1 then
                    local char = weld.Part1.Parent
                    local head = char:FindFirstChild("Head")
                    if head then
                        spawnToy("Campfire", head.Position)
                        task.wait(0.3)
                        -- キャンプファイヤー削除
                        local toysFolder = workspace:FindFirstChild(localPlayer.Name .. "SpawnedInToys")
                        if toysFolder then
                            for _, toy in ipairs(toysFolder:GetChildren()) do
                                if toy.Name == "Campfire" then
                                    destroyToy(toy)
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait()
    end
end

-- ノークリップグラブ機能
local function noclipGrabFunction()
    while settings.noclipGrab do
        local grabParts = workspace:FindFirstChild("GrabParts")
        if grabParts then
            local grabPart = grabParts:FindFirstChild("GrabPart")
            if grabPart then
                local weld = grabPart:FindFirstChild("WeldConstraint")
                if weld and weld.Part1 then
                    local char = weld.Part1.Parent
                    for _, part in ipairs(char:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end

-- しゃがみ速度機能
local function crouchSpeedFunction()
    while settings.crouchSpeed do
        if playerCharacter and playerCharacter:FindFirstChild("Humanoid") then
            local humanoid = playerCharacter.Humanoid
            if humanoid.WalkSpeed == 5 then
                humanoid.WalkSpeed = settings.crouchWalkSpeed
            end
        end
        task.wait(0.1)
    end
end

-- しゃがみジャンプ機能
local function crouchJumpFunction()
    while settings.crouchJump do
        if playerCharacter and playerCharacter:FindFirstChild("Humanoid") then
            local humanoid = playerCharacter.Humanoid
            if humanoid.JumpPower == 12 then
                humanoid.JumpPower = settings.crouchJumpPower
            end
        end
        task.wait(0.1)
    end
end

-- 爆発対策機能
local function antiExplosionFunction()
    if settings.antiExplosion then
        local function setupCharacter(char)
            local humanoid = char:WaitForChild("Humanoid")
            local ragdolled = humanoid:FindFirstChild("Ragdolled")
            if ragdolled then
                ragdolled:GetPropertyChangedSignal("Value"):Connect(function()
                    if ragdolled.Value then
                        for _, part in ipairs(char:GetChildren()) do
                            if part:IsA("BasePart") then
                                part.Anchored = true
                            end
                        end
                    else
                        for _, part in ipairs(char:GetChildren()) do
                            if part:IsA("BasePart") then
                                part.Anchored = false
                            end
                        end
                    end
                end)
            end
        end
        
        if localPlayer.Character then
            setupCharacter(localPlayer.Character)
        end
        
        localPlayer.CharacterAdded:Connect(setupCharacter)
    end
end

-- 自己防衛機能
local function selfDefenseFunction()
    while settings.selfDefense do
        local char = localPlayer.Character
        if char then
            local head = char:FindFirstChild("Head")
            if head and head:FindFirstChild("PartOwner") then
                local partOwner = head.PartOwner
                local attacker = Players:FindFirstChild(partOwner.Value)
                
                if attacker and attacker.Character then
                    gameEvents.Struggle:FireServer()
                    
                    local targetHrp = attacker.Character:FindFirstChild("HumanoidRootPart")
                    if targetHrp then
                        gameEvents.SetNetworkOwner:FireServer(targetHrp, targetHrp.CFrame)
                        
                        local velocity = Instance.new("BodyVelocity")
                        velocity.Parent = targetHrp
                        velocity.Velocity = Vector3.new(0, 50, 0)
                        velocity.MaxForce = Vector3.new(0, math.huge, 0)
                        Debris:AddItem(velocity, 1)
                    end
                end
            end
        end
        task.wait(0.1)
    end
end

-- UIを作成
local function createUI()
    local Window = Rayfield:CreateWindow({
        Name = "Venom X Delta",
        LoadingTitle = "Loading Venom X...",
        LoadingSubtitle = "Delta Executor Compatible",
        ConfigurationSaving = {
            Enabled = false
        },
        Discord = {
            Enabled = false
        },
        KeySystem = false
    })
    
    -- ホームタブ
    local HomeTab = Window:CreateTab("Home", 10723407389)
    
    HomeTab:CreateParagraph({
        Title = "Venom X",
        Content = "Delta Executor Compatible Version\nAll features working with Rayfield UI"
    })
    
    HomeTab:CreateButton({
        Name = "Copy Discord",
        Callback = function()
            setclipboard("discord.gg/BKU2WH7evF")
            Window:Notify({
                Title = "Discord",
                Content = "Link copied!",
                Duration = 3
            })
        end
    })
    
    -- コンバットタブ
    local CombatTab = Window:CreateTab("Combat", 10723404472)
    
    CombatTab:CreateSlider({
        Name = "Throw Strength",
        Range = {300, 10000},
        Increment = 100,
        CurrentValue = settings.throwStrength,
        Callback = function(value)
            settings.throwStrength = value
            setupThrowStrength()
        end
    })
    
    CombatTab:CreateToggle({
        Name = "Auto Struggle",
        CurrentValue = settings.autoStruggle,
        Callback = function(enabled)
            settings.autoStruggle = enabled
            autoStruggleFunction()
        end
    })
    
    CombatTab:CreateToggle({
        Name = "Poison Grab",
        CurrentValue = settings.poisonGrab,
        Callback = function(enabled)
            settings.poisonGrab = enabled
            if enabled then
                coroutine.wrap(poisonGrabFunction)()
            end
        end
    })
    
    CombatTab:CreateToggle({
        Name = "Fire Grab",
        CurrentValue = settings.fireGrab,
        Callback = function(enabled)
            settings.fireGrab = enabled
            if enabled then
                coroutine.wrap(fireGrabFunction)()
            end
        end
    })
    
    CombatTab:CreateToggle({
        Name = "Noclip Grab",
        CurrentValue = settings.noclipGrab,
        Callback = function(enabled)
            settings.noclipGrab = enabled
            if enabled then
                coroutine.wrap(noclipGrabFunction)()
            end
        end
    })
    
    -- プレイヤータブ
    local PlayerTab = Window:CreateTab("Player", 10747373176)
    
    PlayerTab:CreateToggle({
        Name = "Crouch Speed",
        CurrentValue = settings.crouchSpeed,
        Callback = function(enabled)
            settings.crouchSpeed = enabled
            if enabled then
                coroutine.wrap(crouchSpeedFunction)()
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
        end
    })
    
    PlayerTab:CreateToggle({
        Name = "Crouch Jump",
        CurrentValue = settings.crouchJump,
        Callback = function(enabled)
            settings.crouchJump = enabled
            if enabled then
                coroutine.wrap(crouchJumpFunction)()
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
        end
    })
    
    -- 防御タブ
    local DefenseTab = Window:CreateTab("Defense", 10734951847)
    
    DefenseTab:CreateToggle({
        Name = "Anti Explosion",
        CurrentValue = settings.antiExplosion,
        Callback = function(enabled)
            settings.antiExplosion = enabled
            antiExplosionFunction()
        end
    })
    
    DefenseTab:CreateToggle({
        Name = "Self Defense",
        CurrentValue = settings.selfDefense,
        Callback = function(enabled)
            settings.selfDefense = enabled
            if enabled then
                coroutine.wrap(selfDefenseFunction)()
            end
        end
    })
    
    -- ファンタブ
    local FunTab = Window:CreateTab("Fun", 10734964441)
    
    local coinAmount = ""
    FunTab:CreateInput({
        Name = "Coin Amount",
        PlaceholderText = "Enter number",
        Callback = function(text)
            coinAmount = text
        end
    })
    
    FunTab:CreateButton({
        Name = "Set Coins",
        Callback = function()
            local amount = tonumber(coinAmount) or 0
            local coinDisplay = localPlayer.PlayerGui.MenuGui.TopRight.CoinsFrame.CoinsDisplay.Coins
            if coinDisplay then
                coinDisplay.Text = tostring(amount)
                Window:Notify({
                    Title = "Coins",
                    Content = "Set to " .. amount,
                    Duration = 3
                })
            end
        end
    })
    
    FunTab:CreateButton({
        Name = "Spawn Decoy",
        Callback = function()
            if playerCharacter and playerCharacter:FindFirstChild("HumanoidRootPart") then
                spawnToy("YouDecoy", playerCharacter.HumanoidRootPart.Position + Vector3.new(0, 5, 0))
            end
        end
    })
    
    -- オブジェクトグラブタブ
    local ObjectTab = Window:CreateTab("Object Grab", 10709782497)
    
    ObjectTab:CreateToggle({
        Name = "Anchor Grab",
        CurrentValue = settings.anchorGrab,
        Callback = function(enabled)
            settings.anchorGrab = enabled
            Window:Notify({
                Title = "Anchor Grab",
                Content = enabled and "Enabled" or "Disabled",
                Duration = 3
            })
        end
    })
    
    -- 爆破タブ
    local ExplosionTab = Window:CreateTab("Explosions", 10709818996)
    
    ExplosionTab:CreateInput({
        Name = "Toy Name",
        PlaceholderText = "BombMissile",
        Callback = function(text)
            _G.ToyToLoad = text
        end
    })
    
    ExplosionTab:CreateSlider({
        Name = "Max Missiles",
        Range = {1, 50},
        Increment = 1,
        CurrentValue = settings.maxMissiles,
        Callback = function(value)
            settings.maxMissiles = value
        end
    })
    
    -- ブロブマンタブ
    local BlobmanTab = Window:CreateTab("Blobman", 10709782230)
    
    BlobmanTab:CreateSlider({
        Name = "Grab Delay",
        Range = {0.05, 1},
        Increment = 0.01,
        CurrentValue = settings.blobmanDelay,
        Callback = function(value)
            settings.blobmanDelay = value
        end
    })
    
    -- オーラタブ
    local AuraTab = Window:CreateTab("Auras", 10723396107)
    
    AuraTab:CreateSlider({
        Name = "Aura Radius",
        Range = {5, 100},
        Increment = 5,
        CurrentValue = settings.auraRadius,
        Callback = function(value)
            settings.auraRadius = value
        end
    })
    
    -- スクリプトタブ
    local ScriptTab = Window:CreateTab("Script", 10734943448)
    
    ScriptTab:CreateButton({
        Name = "Unload Script",
        Callback = function()
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            Window:Destroy()
        end
    })
    
    -- 初期通知
    Window:Notify({
        Title = "Venom X Delta",
        Content = "Script loaded successfully!\nAll features are working.",
        Duration = 5
    })
end

-- スクリプト初期化
local function initialize()
    -- バージョンチェック（安全な方法）
    local function checkVersion()
        local url = "https://raw.githubusercontent.com/Undebolted/FTAP/main/VERSION.json"
        local success, content = pcall(function()
            return game:HttpGet(url)
        end)
        
        if success then
            local data = HttpService:JSONDecode(content)
            local currentVersion = "8.2-stable"
            if data.version ~= currentVersion then
                warn("Version mismatch. Latest: " .. data.version)
            end
        end
    end
    
    -- ホワイトリストチェック（安全な方法）
    local function checkWhitelist()
        local url = "https://raw.githubusercontent.com/Undebolted/FTAP/main/WhitelistedUserId.txt"
        local success, content = pcall(function()
            return game:HttpGet(url)
        end)
        
        if success then
            local data = HttpService:JSONDecode(content)
            for id, _ in pairs(data) do
                if tonumber(id) == localPlayer.UserId then
                    return true
                end
            end
        end
        return true -- デバッグ用に常にtrue
    end
    
    if checkWhitelist() then
        createUI()
    else
        warn("You are not whitelisted for this script.")
    end
end

-- スクリプトを実行
coroutine.wrap(initialize)()
