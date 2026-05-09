local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- PERFORMANS DEĞİŞKENLERİ
-- ==========================================
local maxSpeed = 5000
local acceleration = 10
local brakePower = 20
local turnSpeed = 8 -- YENİ: Dönüş Hızı (Önceden 3'tü, şimdi 8 yaptık ki seri dönsün)
local currentSpeed = 0
local isSystemActive = false

-- Buton Durumları
local isGas, isBrake, isLeft, isRight = false, false, false, false

-- ==========================================
-- 1. ANA ARAYÜZ (KENDİ YAZDIĞIMIZ MENÜ)
-- ==========================================
local MainGui = Instance.new("ScreenGui")
MainGui.Name = "NenecoProUI"
MainGui.Parent = game.CoreGui

-- Menü Aç/Kapat Butonu
local ToggleMenuBtn = Instance.new("TextButton")
ToggleMenuBtn.Size = UDim2.new(0, 120, 0, 35)
ToggleMenuBtn.Position = UDim2.new(0, 10, 0, 10)
ToggleMenuBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleMenuBtn.BackgroundTransparency = 0.2
ToggleMenuBtn.Text = "AYARLARI AÇ"
ToggleMenuBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
ToggleMenuBtn.Font = Enum.Font.GothamBold
ToggleMenuBtn.Parent = MainGui

local cornerToggle = Instance.new("UICorner")
cornerToggle.CornerRadius = UDim.new(0.2, 0)
cornerToggle.Parent = ToggleMenuBtn

-- Ayar Paneli (Arka Plan)
local MenuFrame = Instance.new("Frame")
MenuFrame.Size = UDim2.new(0, 280, 0, 320)
MenuFrame.Position = UDim2.new(0.5, -140, 0.4, -160)
MenuFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MenuFrame.BackgroundTransparency = 0.15
MenuFrame.Visible = false
MenuFrame.Parent = MainGui

local cornerMenu = Instance.new("UICorner")
cornerMenu.CornerRadius = UDim.new(0, 15)
cornerMenu.Parent = MenuFrame

-- Başlık
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "NENECO KONTROL PANELİ"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 16
Title.Parent = MenuFrame

-- Sistem Aç/Kapat Butonu
local ActiveToggle = Instance.new("TextButton")
ActiveToggle.Size = UDim2.new(0, 240, 0, 40)
ActiveToggle.Position = UDim2.new(0.5, -120, 0, 50)
ActiveToggle.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
ActiveToggle.Text = "SİSTEM: KAPALI (TIKLA AÇ)"
ActiveToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
ActiveToggle.Font = Enum.Font.GothamBold
ActiveToggle.Parent = MenuFrame

local cornerActive = Instance.new("UICorner")
cornerActive.CornerRadius = UDim.new(0.2, 0)
cornerActive.Parent = ActiveToggle

-- Değer Değiştirme Kutucukları (TextBox) Oluşturan Fonksiyon
local function createSettingRow(yPos, labelText, defaultValue, callback)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 150, 0, 30)
    Label.Position = UDim2.new(0, 20, 0, yPos)
    Label.BackgroundTransparency = 1
    Label.Text = labelText
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.Font = Enum.Font.GothamSemibold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = MenuFrame
    
    local InputBox = Instance.new("TextBox")
    InputBox.Size = UDim2.new(0, 70, 0, 30)
    InputBox.Position = UDim2.new(1, -90, 0, yPos)
    InputBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    InputBox.TextColor3 = Color3.fromRGB(0, 255, 150)
    InputBox.Font = Enum.Font.GothamBold
    InputBox.Text = tostring(defaultValue)
    InputBox.Parent = MenuFrame
    
    local cornerInput = Instance.new("UICorner")
    cornerInput.CornerRadius = UDim.new(0.2, 0)
    cornerInput.Parent = InputBox
    
    InputBox.FocusLost:Connect(function()
        local num = tonumber(InputBox.Text)
        if num then
            callback(num)
        else
            InputBox.Text = tostring(defaultValue) -- Harf girilirse eski değere dön
        end
    end)
end

-- Ayarları Menüye Ekliyoruz
createSettingRow(100, "Maksimum Hız:", maxSpeed, function(val) maxSpeed = val end)
createSettingRow(140, "İvmelenme (Güç):", acceleration, function(val) acceleration = val end)
createSettingRow(180, "Fren Gücü:", brakePower, function(val) brakePower = val end)
createSettingRow(220, "Dönüş Keskinliği:", turnSpeed, function(val) turnSpeed = val end) -- YENİ: Dönüş hızı ayarı

-- Buton İşlevleri
ActiveToggle.MouseButton1Click:Connect(function()
    isSystemActive = not isSystemActive
    MainGui.Controls.Enabled = isSystemActive
    ActiveToggle.Text = isSystemActive and "SİSTEM: AÇIK" or "SİSTEM: KAPALI (TIKLA AÇ)"
    ActiveToggle.BackgroundColor3 = isSystemActive and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
end)

ToggleMenuBtn.MouseButton1Click:Connect(function()
    MenuFrame.Visible = not MenuFrame.Visible
end)

-- ==========================================
-- 2. SIVI CAM BUTONLAR (EKRAN KONTROLLERİ)
-- ==========================================
local Controls = Instance.new("Frame")
Controls.Name = "Controls"
Controls.Size = UDim2.new(1, 0, 1, 0)
Controls.BackgroundTransparency = 1
Controls.Enabled = false
Controls.Parent = MainGui

local function createGlassBtn(name, text, pos, color)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(0, 85, 0, 85)
    b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    b.BackgroundTransparency = 0.45
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamBold
    b.TextScaled = true
    b.Parent = Controls
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0.3, 0)
    c.Parent = b
    
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = 3.5
    s.Parent = b
    
    return b
end

local GasBtn = createGlassBtn("Gas", "GAZ", UDim2.new(1, -110, 1, -220), Color3.fromRGB(0, 255, 120))
local BrakeBtn = createGlassBtn("Brake", "FREN", UDim2.new(1, -110, 1, -110), Color3.fromRGB(255, 60, 60))
local LeftBtn = createGlassBtn("Left", "< SOL", UDim2.new(0, 30, 1, -150), Color3.fromRGB(60, 160, 255))
local RightBtn = createGlassBtn("Right", "SAĞ >", UDim2.new(0, 130, 1, -150), Color3.fromRGB(60, 160, 255))

-- Mobilde basılı tutmayı algılama
local function setupTouch(btn, type)
    btn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then 
        if type == "G" then isGas = true elseif type == "B" then isBrake = true elseif type == "L" then isLeft = true elseif type == "R" then isRight = true end
    end end)
    btn.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then 
        if type == "G" then isGas = false elseif type == "B" then isBrake = false elseif type == "L" then isLeft = false elseif type == "R" then isRight = false end
    end end)
end

setupTouch(GasBtn, "G"); setupTouch(BrakeBtn, "B"); setupTouch(LeftBtn, "L"); setupTouch(RightBtn, "R")

-- ==========================================
-- 3. FİZİK VE HAREKET MOTORU
-- ==========================================
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        local seat = char.Humanoid.SeatPart
        -- Eğer sistem açıksa ve oyuncu bir araçtaysa
        if seat and seat:IsA("VehicleSeat") and isSystemActive then
            local root = seat.Parent:FindFirstChild("HumanoidRootPart") or seat
            
            -- İvmelenme ve Yavaşlama
            if isGas then
                currentSpeed = math.min(currentSpeed + acceleration, maxSpeed)
            elseif isBrake then
                currentSpeed = math.max(currentSpeed - brakePower, -maxSpeed/2)
            else
                currentSpeed = currentSpeed * 0.85 -- Gazı bırakınca sürtünme
                if math.abs(currentSpeed) < 1 then currentSpeed = 0 end
            end
            
            -- Aracı ileri doğru itme
            root.AssemblyLinearVelocity = Vector3.new(
                seat.CFrame.LookVector.X * currentSpeed, 
                root.AssemblyLinearVelocity.Y, 
                seat.CFrame.LookVector.Z * currentSpeed
            )
            
            -- YENİ: Aracı sağa/sola döndürme (Keskinliği menüden ayarlanabilir turnSpeed değişkenine bağlandı)
            if isLeft then 
                root.AssemblyAngularVelocity = Vector3.new(0, turnSpeed, 0)
            elseif isRight then 
                root.AssemblyAngularVelocity = Vector3.new(0, -turnSpeed, 0) 
            end
        else
            currentSpeed = 0 -- Araçtan inince veya sistem kapanınca hızı sıfırla
        end
    end
end)
