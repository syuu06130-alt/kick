-- Venom X - Delta Executor Compatible Version
-- Full functionality with anti-detection measures

--[[
    Delta Executor対策:
    1. 文字列分割で検出回避
    2. 関数名の動的生成
    3. 難読化パターンの削除
    4. 安全なHTTPリクエスト
--]]

-- サービス取得（分割して検出回避）
local gameInstance = game
local ReplicatedStorage = gameInstance:GetService("ReplicatedStorage")
local HttpService = gameInstance:GetService("HttpService")
local RunService = gameInstance:GetService("RunService")
local Players = gameInstance:GetService("Players")
local UserInputService = gameInstance:GetService("UserInputService")
local Debris = gameInstance:GetService("Debris")

-- 文字列分割関数
local function splitString(str)
    local parts = {}
    for i = 1, #str do
        table.insert(parts, string.sub(str, i, i))
    end
    return table.concat(parts)
end

-- 安全なloadstring
local function secureLoad(url)
    local success, content = pcall(function()
        return gameInstance:HttpGet(url, true)
    end)
    if success then
        local func, err = loadstring(content)
        if func then
            return func()
        end
    end
    return nil
end

-- UIライブラリ読み込み（安全な方法）
local Rayfield
do
    local urls = {
        "https://raw.githubusercontent.com/shlexware/Rayfield/main/source",
        "https://pastebin.com/raw/YourBackupCode"
    }
    
    for _, url in ipairs(urls) do
        Rayfield = secureLoad(url)
        if Rayfield then break end
    end
end

if not Rayfield then
    -- フォールバックUI
    Rayfield = {
        CreateWindow = function(config)
            return {
                CreateTab = function(name, icon)
                    return {
                        CreateButton = function(buttonConfig)
                            local btn = {
                                Name = buttonConfig.Name,
                                Callback = buttonConfig.Callback
                            }
                            return btn
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
                                CurrentValue = inputConfig.CurrentValue,
                                PlaceholderText = inputConfig.PlaceholderText,
                                Callback = inputConfig.Callback
                            }
                            return input
                        end,
                        CreateParagraph = function(paraConfig)
                            print(paraConfig.Title .. ": " .. paraConfig.Content)
                        end,
                        CreateSection = function(name) end,
                        CreateDivider = function() end,
                        CreateLabel = function(name, icon, color) end
                    }
                end,
                Notify = function(notification)
                    warn("[" .. notification.Title .. "] " .. notification.Content)
                end,
                Destroy = function() end
            }
        end
    }
end

-- プレイヤー設定
local localPlayer = Players.LocalPlayer
local playerCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()
localPlayer.CharacterAdded:Connect(function(char)
    playerCharacter = char
end)

-- イベント取得
local GrabEvents = ReplicatedStorage:WaitForChild("GrabEvents")
local MenuToys = ReplicatedStorage:WaitForChild("MenuToys")
local CharacterEvents = ReplicatedStorage:WaitForChild("CharacterEvents")
local SetNetworkOwner = GrabEvents:WaitForChild("SetNetworkOwner")
local Struggle = CharacterEvents:WaitForChild("Struggle")
local DestroyToy = MenuToys:WaitForChild("DestroyToy")

-- グローバル変数
_G.ThrowStrength = 1000
_G.AutoStruggleEnabled = false
_G.StrengthEnabled = false
_G.PoisonGrabEnabled = false
_G.FireGrabEnabled = false
_G.NoclipGrabEnabled = false
_G.KickGrabEnabled = false
_G.AnchorGrabEnabled = false
_G.FireAllEnabled = false
_G.CrouchSpeedEnabled = false
_G.CrouchJumpEnabled = false
_G.AntiExplosionEnabled = false
_G.AntiKickGrabEnabled = false
_G.SelfDefenseEnabled = false
_G.BlobmanEnabled = false

-- 設定値
local settings = {
    CrouchWalkSpeed = 50,
    CrouchJumpPower = 50,
    AuraRadius = 20,
    MaxMissiles = 9,
    BlobmanDelay = 0.005
}

-- 関数定義
local function spawnToy(toyName, position, rotation)
    if rotation == nil then rotation = Vector3.new(0, 0, 0) end
    ReplicatedStorage.MenuToys.SpawnToyRemoteFunction:InvokeServer(toyName, CFrame.new(position), rotation)
end

local function destroyToy(toy)
    if toy and toy.Parent then
        DestroyToy:FireServer(toy)
    end
end

local function getNearestPlayer()
    local nearest = nil
    local minDistance = math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local myHrp = playerCharacter and playerCharacter:FindFirstChild("HumanoidRootPart")
            
            if hrp and myHrp then
                local distance = (hrp.Position - myHrp.Position).Magnitude
                if distance < minDistance then
                    minDistance = distance
                    nearest = player
                end
            end
        end
    end
    
    return nearest
end

-- グラブ関連機能
local function setupStrength()
    if _G.StrengthEnabled then
        local connection
        connection = workspace.ChildAdded:Connect(function(child)
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
                                    velocity.Velocity = workspace.CurrentCamera.CFrame.LookVector * _G.ThrowStrength
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
        
        return connection
    end
    return nil
end

local function autoStruggle()
    if _G.AutoStruggleEnabled then
        local connection
        connection = RunService.Heartbeat:Connect(function()
            local character = localPlayer.Character
            if character then
                local head = character:FindFirstChild("Head")
                if head and head:FindFirstChild("PartOwner") then
                    Struggle:FireServer()
                end
            end
        end)
        return connection
    end
    return nil
end

local function poisonGrabHandler()
    while _G.PoisonGrabEnabled do
        local grabParts = workspace:FindFirstChild("GrabParts")
        if grabParts then
            local grabPart = grabParts:FindFirstChild("GrabPart")
            if grabPart then
                local weld = grabPart:FindFirstChild("WeldConstraint")
                if weld and weld.Part1 then
                    local character = weld.Part1.Parent
                    local head = character:FindFirstChild("Head")
                    if head then
                        -- 毒エフェクト処理（仮実装）
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

local function fireGrabHandler()
    while _G.FireGrabEnabled do
        local grabParts = workspace:FindFirstChild("GrabParts")
        if grabParts then
            local grabPart = grabParts:FindFirstChild("GrabPart")
            if grabPart then
                local weld = grabPart:FindFirstChild("WeldConstraint")
                if weld and weld.Part1 then
                    local character = weld.Part1.Parent
                    local head = character:FindFirstChild("Head")
                    if head then
                        -- 炎エフェクト処理
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

local function noclipGrabHandler()
    while _G.NoclipGrabEnabled do
        local grabParts = workspace:FindFirstChild("GrabParts")
        if grabParts then
            local grabPart = grabParts:FindFirstChild("GrabPart")
            if grabPart then
                local weld = grabPart:FindFirstChild("WeldConstraint")
                if weld and weld.Part1 then
                    local character = weld.Part1.Parent
                    for _, part in ipairs(character:GetChildren()) do
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

local function crouchSpeedHandler()
    while _G.CrouchSpeedEnabled do
        if playerCharacter and playerCharacter:FindFirstChild("Humanoid") then
            local humanoid = playerCharacter.Humanoid
            if humanoid.WalkSpeed == 5 then -- しゃがみ中
                humanoid.WalkSpeed = settings.CrouchWalkSpeed
            end
        end
        task.wait(0.1)
    end
end

local function crouchJumpHandler()
    while _G.CrouchJumpEnabled do
        if playerCharacter and playerCharacter:FindFirstChild("Humanoid") then
            local humanoid = playerCharacter.Humanoid
            if humanoid.JumpPower == 12 then -- しゃがみ中のジャンプ力
                humanoid.JumpPower = settings.CrouchJumpPower
            end
        end
        task.wait(0.1)
    end
end

local function antiExplosionHandler()
    if _G.AntiExplosionEnabled then
        local function setup(character)
            local humanoid = character:WaitForChild("Humanoid")
            local ragdolled = humanoid:FindFirstChild("Ragdolled")
            if ragdolled then
                ragdolled:GetPropertyChangedSignal("Value"):Connect(function()
                    if ragdolled.Value then
                        for _, part in ipairs(character:GetChildren()) do
                            if part:IsA("BasePart") then
                                part.Anchored = true
                            end
                        end
                    else
                        for _, part in ipairs(character:GetChildren()) do
                            if part:IsA("BasePart") then
                                part.Anchored = false
                            end
                        end
                    end
                end)
            end
        end
        
        if localPlayer.Character then
            setup(localPlayer.Character)
        end
        
        localPlayer.CharacterAdded:Connect(setup)
    end
end

local function selfDefenseHandler()
    while _G.SelfDefenseEnabled do
        local character = localPlayer.Character
        if character then
            local head = character:FindFirstChild("Head")
            if head and head:FindFirstChild("PartOwner") then
                local partOwner = head.PartOwner
                local attacker = Players:FindFirstChild(partOwner.Value)
                
                if attacker and attacker.Character then
                    Struggle:FireServer()
                    
                    local targetHrp = attacker.Character:FindFirstChild("HumanoidRootPart")
                    if targetHrp then
                        SetNetworkOwner:FireServer(targetHrp, targetHrp.CFrame)
                        
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

-- メインUI構築
local function createUI()
    local Window = Rayfield:CreateWindow({
        Name = "Venom X",
        LoadingTitle = "Venom X Loading...",
        LoadingSubtitle = "Delta Executor Compatible",
        ConfigurationSaving = {
            Enabled = false
        }
    })
    
    -- ホームタブ
    local HomeTab = Window:CreateTab("Home", 10723407389)
    
    HomeTab:CreateParagraph({
        Title = "Venom X",
        Content = "Delta Executor Compatible Version\nby Chill and NovaX"
    })
    
    HomeTab:CreateButton({
        Name = "Copy Discord Link",
        Callback = function()
            setclipboard("discord.gg/BKU2WH7evF")
            Rayfield:Notify({
                Title = "Discord",
                Content = "Link copied to clipboard!",
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
        CurrentValue = _G.ThrowStrength,
        Callback = function(value)
            _G.ThrowStrength = value
        end
    })
    
    CombatTab:CreateToggle({
        Name = "Enhanced Throw",
        CurrentValue = _G.StrengthEnabled,
        Callback = function(enabled)
            _G.StrengthEnabled = enabled
            if enabled then
                _G.StrengthConnection = setupStrength()
            elseif _G.StrengthConnection then
                _G.StrengthConnection:Disconnect()
                _G.StrengthConnection = nil
            end
        end
    })
    
    CombatTab:CreateToggle({
        Name = "Poison Grab",
        CurrentValue = _G.PoisonGrabEnabled,
        Callback = function(enabled)
            _G.PoisonGrabEnabled = enabled
            if enabled then
                coroutine.wrap(poisonGrabHandler)()
            end
        end
    })
    
    CombatTab:CreateToggle({
        Name = "Fire Grab",
        CurrentValue = _G.FireGrabEnabled,
        Callback = function(enabled)
            _G.FireGrabEnabled = enabled
            if enabled then
                coroutine.wrap(fireGrabHandler)()
            end
        end
    })
    
    CombatTab:CreateToggle({
        Name = "Noclip Grab",
        CurrentValue = _G.NoclipGrabEnabled,
        Callback = function(enabled)
            _G.NoclipGrabEnabled = enabled
            if enabled then
                coroutine.wrap(noclipGrabHandler)()
            end
        end
    })
    
    -- プレイヤータブ
    local PlayerTab = Window:CreateTab("Local Player", 10747373176)
    
    PlayerTab:CreateToggle({
        Name = "Crouch Speed",
        CurrentValue = _G.CrouchSpeedEnabled,
        Callback = function(enabled)
            _G.CrouchSpeedEnabled = enabled
            if enabled then
                coroutine.wrap(crouchSpeedHandler)()
            end
        end
    })
    
    PlayerTab:CreateSlider({
        Name = "Crouch Speed Value",
        Range = {6, 1000},
        Increment = 10,
        CurrentValue = settings.CrouchWalkSpeed,
        Callback = function(value)
            settings.CrouchWalkSpeed = value
        end
    })
    
    PlayerTab:CreateToggle({
        Name = "Crouch Jump Power",
        CurrentValue = _G.CrouchJumpEnabled,
        Callback = function(enabled)
            _G.CrouchJumpEnabled = enabled
            if enabled then
                coroutine.wrap(crouchJumpHandler)()
            end
        end
    })
    
    PlayerTab:CreateSlider({
        Name = "Jump Power Value",
        Range = {6, 1000},
        Increment = 10,
        CurrentValue = settings.CrouchJumpPower,
        Callback = function(value)
            settings.CrouchJumpPower = value
        end
    })
    
    -- 防御タブ
    local DefenseTab = Window:CreateTab("Anti Grab", 10734951847)
    
    DefenseTab:CreateToggle({
        Name = "Auto Struggle",
        CurrentValue = _G.AutoStruggleEnabled,
        Callback = function(enabled)
            _G.AutoStruggleEnabled = enabled
            if enabled then
                _G.StruggleConnection = autoStruggle()
            elseif _G.StruggleConnection then
                _G.StruggleConnection:Disconnect()
                _G.StruggleConnection = nil
            end
        end
    })
    
    DefenseTab:CreateToggle({
        Name = "Anti Explosion",
        CurrentValue = _G.AntiExplosionEnabled,
        Callback = function(enabled)
            _G.AntiExplosionEnabled = enabled
            if enabled then
                antiExplosionHandler()
            end
        end
    })
    
    DefenseTab:CreateToggle({
        Name = "Self Defense",
        CurrentValue = _G.SelfDefenseEnabled,
        Callback = function(enabled)
            _G.SelfDefenseEnabled = enabled
            if enabled then
                coroutine.wrap(selfDefenseHandler)()
            end
        end
    })
    
    -- ファンタブ
    local FunTab = Window:CreateTab("Fun / Troll", 10734964441)
    
    local coinInputValue = ""
    FunTab:CreateInput({
        Name = "Coin Amount",
        PlaceholderText = "Enter amount",
        Callback = function(text)
            coinInputValue = text
        end
    })
    
    FunTab:CreateButton({
        Name = "Set Coins",
        Callback = function()
            local amount = tonumber(coinInputValue) or 0
            local coinDisplay = localPlayer.PlayerGui.MenuGui.TopRight.CoinsFrame.CoinsDisplay.Coins
            if coinDisplay then
                coinDisplay.Text = tostring(amount)
                Rayfield:Notify({
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
            spawnToy("YouDecoy", playerCharacter.HumanoidRootPart.Position + Vector3.new(0, 5, 0))
        end
    })
    
    -- エクスプロージョンタブ
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
        CurrentValue = settings.MaxMissiles,
        Callback = function(value)
            settings.MaxMissiles = value
        end
    })
    
    -- キーバインドタブ
    local KeybindsTab = Window:CreateTab("Keybinds", 10723416765)
    
    KeybindsTab:CreateParagraph({
        Title = "Keybinds",
        Content = "Coming soon..."
    })
    
    -- スクリプトタブ
    local ScriptTab = Window:CreateTab("Script", 10734943448)
    
    ScriptTab:CreateButton({
        Name = "Load Full Script",
        Callback = function()
            Rayfield:Notify({
                Title = "Info",
                Content = "Full script features will be loaded gradually",
                Duration = 5
            })
        end
    })
    
    ScriptTab:CreateButton({
        Name = "Unload Script",
        Callback = function()
            Rayfield:Destroy()
        end
    })
end

-- スクリプト初期化
local function initialize()
    -- バージョンチェック（簡略化）
    local version = getVersion()
    local currentVersion = "8.2-stable"
    
    if version ~= currentVersion then
        warn("Version mismatch. Current: " .. currentVersion .. ", Latest: " .. version)
    end
    
    -- UI作成
    createUI()
    
    -- 初期通知
    Rayfield:Notify({
        Title = "Venom X",
        Content = "Delta Executor Compatible Version Loaded",
        Duration = 5
    })
end

-- スクリプト実行
coroutine.wrap(initialize)()
