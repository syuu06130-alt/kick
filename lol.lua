-- Blobman Kick Script for Fling Things and People (修正版)
-- 全ての機能が反応しない問題を修正。Remoteの複数試行、自動Spawn、TP+Grab+Return+Flingの0.01秒ループ、オンオフトグル完備。
-- 手動Spawnボタンあり。Kick時は自動Spawn確認。
-- Single: プレイヤーリストから選択 / All: 全員対象
-- 動作: TP(0.01s) → Grab → TP戻り(0.01s) → Fling/Release → 繰り返し

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- GUI作成
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BlobmanKickGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 450)
mainFrame.Position = UDim2.new(0, 10, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
titleLabel.BorderSizePixel = 0
titleLabel.Text = "🟢 Blobman Kick (修正版)"
titleLabel.TextColor3 = Color3.new(1,1,1)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

local spawnBtn = Instance.new("TextButton")
spawnBtn.Size = UDim2.new(1, -20, 0, 45)
spawnBtn.Position = UDim2.new(0, 10, 0, 50)
spawnBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
spawnBtn.Text = "Spawn Blobman (Auto Mount)"
spawnBtn.TextColor3 = Color3.new(1,1,1)
spawnBtn.TextScaled = true
spawnBtn.Font = Enum.Font.Gotham
spawnBtn.BorderSizePixel = 0
spawnBtn.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 0, 180)
scrollFrame.Position = UDim2.new(0, 10, 0, 105)
scrollFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = mainFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.SortOrder = Enum.SortOrder.Name
uiListLayout.Padding = UDim.new(0, 2)
uiListLayout.Parent = scrollFrame

local allKickBtn = Instance.new("TextButton")
allKickBtn.Size = UDim2.new(0.49, -10, 0, 45)
allKickBtn.Position = UDim2.new(0, 10, 0, 295)
allKickBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
allKickBtn.Text = "All Kick (OFF)"
allKickBtn.TextColor3 = Color3.new(1,1,1)
allKickBtn.TextScaled = true
allKickBtn.Font = Enum.Font.GothamBold
allKickBtn.BorderSizePixel = 0
allKickBtn.Parent = mainFrame

local singleKickBtn = Instance.new("TextButton")
singleKickBtn.Size = UDim2.new(0.49, -10
