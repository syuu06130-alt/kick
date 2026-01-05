--[[
    Syu_hub v7.0 | Blobman Kicker - Rayfield Edition
    Target: Fling Things and People
    Library: Rayfield (Sirius Menu)
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Variables
local TargetPlayer = nil
local IsLoopKicking = false
local IsAllKicking = false
local BlobmanTool = nil
local GrabDelay = 0.01

-- Rayfield Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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

-- Find or Spawn Blobman
local function GetBlobman()
    for _, item in pairs(Workspace:GetDescendants()) do
        if item.Name == "CreatureBlobman" and item:FindFirstChild("VehicleSeat") then
            return item
        end
    end
    
    -- Spawn new Blobman
    local args = {
        [1] = Workspace.Spawn,
        [2] = "Blobman"
    }
    
    if ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction") then
        ReplicatedStorage.MenuToys.SpawnToyRemoteFunction:InvokeServer("Blobman", LocalPlayer.Character.HumanoidRootPart.CFrame, Vector3.new(0, 0, 0))
        wait(0.5)
        return GetBlobman()
    end
    
    return nil
end

-- Grab Player with Blobman
local grabSide = 1
local function BlobGrabPlayer(targetName)
    local target = Players:FindFirstChild(targetName)
    if not target or not target.Character then return end
    
    local blobman = GetBlobman()
    if not blobman then 
        Rayfield:Notify({
            Title = "Error",
            Content = "Blobmanが見つかりません！",
            Duration = 3,
            Image = 4483362458,
        })
        return 
    end
    
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    
    -- Alternate between left and right grab
    local detector = grabSide == 1 and blobman:FindFirstChild("LeftDetector") or blobman:FindFirstChild("RightDetector")
    local weld = grabSide == 1 and detector:FindFirstChild("LeftWeld") or detector:FindFirstChild("RightWeld")
    
    if detector and weld and blobman:FindFirstChild("BlobmanSeatAndOwnerScript") then
        local grabRemote = blobman.BlobmanSeatAndOwnerScript:FindFirstChild("CreatureGrab")
        if grabRemote then
            local args = {
                [1] = detector,
                [2] = targetHRP,
                [3] = weld
            }
            grabRemote:FireServer(unpack(args))
            grabSide = grabSide == 1 and 2 or 1
        end
    end
end

-- Kick Single Target Loop
local function KickTargetLoop()
    while IsLoopKicking and TargetPlayer do
        pcall(function()
            BlobGrabPlayer(TargetPlayer)
        end)
        wait(GrabDelay)
    end
end

-- Kick All Players Loop
local function KickAllLoop()
    while IsAllKicking do
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and IsAllKicking then
                pcall(function()
                    BlobGrabPlayer(player.Name)
                end)
                wait(GrabDelay)
            end
        end
        wait(0.05)
    end
end

-- Create Rayfield Window
local Window = Rayfield:CreateWindow({
    Name = "🎯 Syu_hub v7.0 | Rayfield",
    Icon = 0,
    LoadingTitle = "Syu_hub Loading...",
    LoadingSubtitle = "by Syu",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "SyuHub_Rayfield"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "Syu_hub",
        Subtitle = "Key System",
        Note = "No key required",
        FileName = "SyuHubKey",
        SaveKey = false,
        GrabKeyFromSite = false,
        Key = {""}
    }
})

-- Home Tab
local HomeTab = Window:CreateTab("🏠 Home", 10723407389)

HomeTab:CreateParagraph({
    Title = "Welcome!",
    Content = "Syu_hub v7.0 - Blobman Auto Kick\n現在のプレイヤー: " .. LocalPlayer.Name
})

HomeTab:CreateLabel("Rayfield Library by Sirius", 10709797725, Color3.fromRGB(100, 100, 255), false)

HomeTab:CreateDivider()

HomeTab:CreateParagraph({
    Title = "使い方",
    Content = "1. ターゲットを選択\n2. Loop Kickを有効化\n3. 停止する場合は再度トグル"
})

-- Main Tab
local MainTab = Window:CreateTab("⚔️ Combat", 10723404472)

MainTab:CreateParagraph({
    Title = "Blobman Auto Kick",
    Content = "Blobmanで自動的にプレイヤーを掴んで投げます"
})

-- Player Selection
local playerDropdownValue = nil
local PlayerDropdown = MainTab:CreateDropdown({
    Name = "ターゲット選択",
    Options = GetPlayerNames(),
    CurrentOption = {"プレイヤーを選択..."},
    MultipleOptions = false,
    Flag = "PlayerDropdown",
    Callback = function(Option)
        TargetPlayer = Option[1]
        playerDropdownValue = Option[1]
        Rayfield:Notify({
            Title = "ターゲット選択",
            Content = "選択: " .. TargetPlayer,
            Duration = 2,
            Image = 4483362458,
        })
    end,
})

-- Refresh Button
MainTab:CreateButton({
    Name = "🔄 プレイヤーリスト更新",
    Callback = function()
        PlayerDropdown:Refresh(GetPlayerNames())
        Rayfield:Notify({
            Title = "更新完了",
            Content = "プレイヤーリストを更新しました",
            Duration = 2,
            Image = 4483362458,
        })
    end,
})

MainTab:CreateDivider()

-- Spawn Blobman Button
MainTab:CreateButton({
    Name = "🧊 Blobman スポーン",
    Callback = function()
        local success = pcall(function()
            GetBlobman()
        end)
        if success then
            Rayfield:Notify({
                Title = "成功",
                Content = "Blobmanをスポーンしました",
                Duration = 2,
                Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title = "エラー",
                Content = "スポーンに失敗しました",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})

-- Single Kick Button
MainTab:CreateButton({
    Name = "🎯 Kick Target (1回)",
    Callback = function()
        if not TargetPlayer then
            Rayfield:Notify({
                Title = "エラー",
                Content = "プレイヤーを選択してください",
                Duration = 3,
                Image = 4483362458,
            })
            return
        end
        
        BlobGrabPlayer(TargetPlayer)
        Rayfield:Notify({
            Title = "Kick実行",
            Content = TargetPlayer .. " を攻撃しました",
            Duration = 2,
            Image = 4483362458,
        })
    end,
})

MainTab:CreateDivider()

-- Loop Kick Toggle
local LoopToggle = MainTab:CreateToggle({
    Name = "🔄 Loop Kick Target",
    CurrentValue = false,
    Flag = "LoopKick",
    Callback = function(Value)
        IsLoopKicking = Value
        IsAllKicking = false
        
        if Value then
            if not TargetPlayer then
                Rayfield:Notify({
                    Title = "エラー",
                    Content = "プレイヤーを選択してください",
                    Duration = 3,
                    Image = 4483362458,
                })
                LoopToggle:Set(false)
                return
            end
            
            Rayfield:Notify({
                Title = "ループ開始",
                Content = TargetPlayer .. " へのループ攻撃開始",
                Duration = 2,
                Image = 4483362458,
            })
            
            task.spawn(KickTargetLoop)
        else
            Rayfield:Notify({
                Title = "停止",
                Content = "ループ攻撃を停止しました",
                Duration = 2,
                Image = 4483362458,
            })
        end
    end,
})

-- Kick All Toggle
local AllToggle = MainTab:CreateToggle({
    Name = "💀 Kick ALL Players",
    CurrentValue = false,
    Flag = "KickAll",
    Callback = function(Value)
        IsAllKicking = Value
        IsLoopKicking = false
        LoopToggle:Set(false)
        
        if Value then
            Rayfield:Notify({
                Title = "全員攻撃",
                Content = "全プレイヤーへの攻撃を開始",
                Duration = 2,
                Image = 4483362458,
            })
            
            task.spawn(KickAllLoop)
        else
            Rayfield:Notify({
                Title = "停止",
                Content = "全員攻撃を停止しました",
                Duration = 2,
                Image = 4483362458,
            })
        end
    end,
})

MainTab:CreateDivider()

-- Grab Delay Slider
MainTab:CreateSlider({
    Name = "⏱️ 掴み間隔 (秒)",
    Range = {0.01, 1},
    Increment = 0.01,
    Suffix = "秒",
    CurrentValue = 0.01,
    Flag = "GrabDelay",
    Callback = function(Value)
        GrabDelay = Value
    end,
})

-- Settings Tab
local SettingsTab = Window:CreateTab("⚙️ Settings", 10734943448)

SettingsTab:CreateParagraph({
    Title = "設定",
    Content = "スクリプトの各種設定を変更できます"
})

SettingsTab:CreateButton({
    Name = "🔄 UI再読み込み",
    Callback = function()
        Rayfield:Destroy()
        wait(0.5)
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Undebolted/FTAP/main/Script.lua"))()
    end,
})

SettingsTab:CreateButton({
    Name = "❌ UI閉じる",
    Callback = function()
        IsLoopKicking = false
        IsAllKicking = false
        Rayfield:Destroy()
    end,
})

-- Info Tab
local InfoTab = Window:CreateTab("ℹ️ Info", 10747373176)

InfoTab:CreateParagraph({
    Title = "Syu_hub v7.0",
    Content = "Rayfield Edition\n対応ゲーム: Fling Things and People"
})

InfoTab:CreateLabel("作成者: Syu", 10709797725, Color3.fromRGB(150, 150, 255), false)

InfoTab:CreateParagraph({
    Title = "機能一覧",
    Content = "• ターゲット選択\n• 単発Kick\n• ループKick\n• 全員Kick\n• Blobman自動スポーン\n• 掴み間隔調整"
})

InfoTab:CreateParagraph({
    Title = "注意事項",
    Content = "このスクリプトは教育目的のみで作成されています。\n悪用は絶対にしないでください。"
})

-- Initial Notification
Rayfield:Notify({
    Title = "🎯 Syu_hub v7.0",
    Content = "Rayfield版ロード完了！",
    Duration = 5,
    Image = 4483362458,
})

print("=== Syu_hub v7.0 Rayfield Edition ===")
print("Loaded successfully!")
print("Ready to kick!")
