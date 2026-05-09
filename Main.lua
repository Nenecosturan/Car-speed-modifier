-- Rayfield'ı engellemelere takılmaması için doğrudan GitHub Raw üzerinden çekiyoruz
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Senin İstediğin Yeni Varsayılan Değerler
local maxSpeed = 5000      -- Maksimum hız sınırını 5000 yaptık
local acceleration = 10    -- Hızlanmayı (İvmeyi) 10 yaptık
local brakePower = 20      -- Frenin tutması için fren gücünü artırdık
local currentSpeed = 0

local useBackupSystem = false

-- Buton Durumları
local isGas = false
local isBrake = false
local isLeft = false
local isRight = false

-- ==========================================
-- 1. SIVI CAM (FROSTED GLASS) BUTONLAR
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YedekMobilKontroller"
ScreenGui.Parent = game.CoreGui
ScreenGui.Enabled = false 

local function createGlassButton(name, text, pos, strokeColor)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 80, 0, 80)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    btn.BackgroundTransparency = 0.4
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextScaled = true
    btn.Parent = ScreenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.2, 0)
    corner.Parent = btn
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 150, 150))
    })
    gradient.Rotation = 90
    gradient.Parent = btn
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = strokeColor
    stroke.Thickness = 3
    stroke.Transparency = 0.2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = btn
    
    return btn
end

local GasBtn = createGlassButton("Gas", "GAZ", UDim2.new(1, -100, 1, -200), Color3.fromRGB(0, 255, 100))
local BrakeBtn = createGlassButton("Brake", "FREN", UDim2.new(1, -100, 1, -100), Color3.fromRGB(255, 50, 50))
local LeftBtn = createGlassButton("Left", "< SOL", UDim2.new(0, 20, 1, -150), Color3.fromRGB(50, 150, 255))
local RightBtn = createGlassButton("Right", "SAĞ >", UDim2.new(0, 120, 1, -150), Color3.fromRGB(50, 150, 255))

local function bindButton(btn, varName)
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if varName == "Gas" then isGas = true
            elseif varName == "Brake" then isBrake = true
            elseif varName == "Left" then isLeft = true
            elseif varName == "Right" then isRight = true end
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if varName == "Gas" then isGas = false
            elseif varName == "Brake" then isBrake = false
            elseif varName == "Left" then isLeft = false
            elseif varName == "Right" then isRight = false end
        end
    end)
end

bindButton(GasBtn, "Gas")
bindButton(BrakeBtn, "Brake")
bindButton(LeftBtn, "Left")
bindButton(RightBtn, "Right")

-- ==========================================
-- 2. RAYFIELD MENÜSÜ (GÜNCELLENMİŞ DEĞERLER)
-- ==========================================
local Window = Rayfield:CreateWindow({
    Name = "Evrensel Araç Pro v3",
    LoadingTitle = "Mod Yükleniyor...",
    LoadingSubtitle = "Sorunsuz Bağlantı",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local TabMain = Window:CreateTab("Motor Kontrolü", 4483362458)

TabMain:CreateParagraph({Title = "ÖNEMLİ BİLGİ", Content = "Mobil oyunlarda oyunun kendi gaz pedalı sistemi bozduğu için aracı sadece ekrandaki Sıvı Cam butonlarla kontrol edin."})

TabMain:CreateToggle({
    Name = "Sistemi ve Butonları Aç",
    CurrentValue = false,
    Flag = "BackupToggle",
    Callback = function(Value)
        useBackupSystem = Value
        ScreenGui.Enabled = Value 
    end
})

TabMain:CreateSlider({
    Name = "Maksimum Hız Limiti", Range = {100, 5000}, Increment = 50, CurrentValue = 5000, Flag = "MaxSpd",
    Callback = function(Value) maxSpeed = Value end
})

TabMain:CreateSlider({
    Name = "İvmelenme (Hızlanma Gücü)", Range = {1, 50}, Increment = 1, CurrentValue = 10, Flag = "Accel",
    Callback = function(Value) acceleration = Value end
})

TabMain:CreateSlider({
    Name = "Fren Gücü (Hızlı Durma)", Range = {1, 50}, Increment = 1, CurrentValue = 20, Flag = "BrakePwr",
    Callback = function(Value) brakePower = Value end
})

-- ==========================================
-- 3. FİZİK MOTORU (DURMA SORUNU ÇÖZÜLDÜ)
-- ==========================================
RunService.RenderStepped:Connect(function()
    if not LocalPlayer.Character then return end
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    
    if humanoid and humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
        local seat = humanoid.SeatPart
        local carRoot = seat.Parent:FindFirstChild("HumanoidRootPart") or seat
        local lookVector = seat.CFrame.LookVector
        local currentVelocity = carRoot.AssemblyLinearVelocity
        
        if useBackupSystem then
            -- İvmelenme ve Fren Mantığı
            if isGas then
                currentSpeed = math.min(currentSpeed + acceleration, maxSpeed)
            elseif isBrake then
                currentSpeed = math.max(currentSpeed - brakePower, -maxSpeed / 2) 
            else
                -- KULLANICI GAZI BIRAKTIĞINDA ARACIN DURMASI İÇİN AGRESİF SÜRTÜNME
                if currentSpeed > 0 then 
                    currentSpeed = math.max(currentSpeed - (brakePower / 1.2), 0)
                elseif currentSpeed < 0 then 
                    currentSpeed = math.min(currentSpeed + (brakePower / 1.2), 0) 
                end
            end
            
            -- Hızı uygula
            if math.abs(currentSpeed) > 1 or isGas or isBrake then
                carRoot.AssemblyLinearVelocity = Vector3.new(lookVector.X * currentSpeed, currentVelocity.Y, lookVector.Z * currentSpeed)
            end
            
            -- Dönüş (Direksiyon) Kontrolü
            if isLeft then 
                carRoot.AssemblyAngularVelocity = Vector3.new(0, 3, 0)
            elseif isRight then 
                carRoot.AssemblyAngularVelocity = Vector3.new(0, -3, 0) 
            end
        end
    else
        currentSpeed = 0 
    end
end)
