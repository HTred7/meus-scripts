--[[
    ═══════════════════════════════════════════════════════════
    AxomJB's Turbo Grid | RACE SCRIPT | v1.0.0
    Loadstring Payload — AutoFarm Corrida + AutoSpeed
    ═══════════════════════════════════════════════════════════
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Nuke old instance
local old = PlayerGui:FindFirstChild("AxomJB_RaceScript")
if old then old:Destroy() end

-- State
local autoFarmEnabled = false
local autoSpeedEnabled = false
local maxSpeed = 5000

-- ═══════════════════════════════════════════════════════════
-- VEHICLE DETECTION
-- ═══════════════════════════════════════════════════════════
local function getCurrentVehicle()
    local char = LocalPlayer.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    if humanoid and humanoid.SeatPart then
        return humanoid.SeatPart:FindFirstAncestorWhichIsA("Model")
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════
-- AUTOSPEED CORE
-- ═══════════════════════════════════════════════════════════
local speedConnection

local function startAutoSpeed()
    if speedConnection then speedConnection:Disconnect() end
    speedConnection = RunService.Heartbeat:Connect(function()
        if not autoSpeedEnabled then return end
        local vehicle = getCurrentVehicle()
        if not vehicle then return end
        local seat = vehicle:FindFirstChildWhichIsA("VehicleSeat") 
            or vehicle:FindFirstChildWhichIsA("BasePart")
        if not seat then return end

        local targetVelocity = maxSpeed * 0.28

        for _, v in pairs(seat:GetChildren()) do
            if v:IsA("BodyVelocity") or v:IsA("LinearVelocity") then
                v:Destroy()
            end
        end

        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = seat.CFrame.LookVector * targetVelocity
        bv.Parent = seat
    end)
end

local function stopAutoSpeed()
    if speedConnection then
        speedConnection:Disconnect()
        speedConnection = nil
    end
    local vehicle = getCurrentVehicle()
    if vehicle then
        local seat = vehicle:FindFirstChildWhichIsA("VehicleSeat") 
            or vehicle:FindFirstChildWhichIsA("BasePart")
        if seat then
            for _, v in pairs(seat:GetChildren()) do
                if v:IsA("BodyVelocity") or v:IsA("LinearVelocity") then
                    v:Destroy()
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- AUTOFARM CORRIDA
-- ═══════════════════════════════════════════════════════════
local autoFarmThread

local function startAutoFarm()
    if autoFarmThread then task.cancel(autoFarmThread) end
    autoFarmThread = task.spawn(function()
        while autoFarmEnabled do
            task.wait(0.5)
            local char = LocalPlayer.Character
            if not char then continue end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then continue end

            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") and obj.Enabled then
                    local part = obj.Parent
                    if part and part:IsA("BasePart") then
                        if (root.Position - part.Position).Magnitude < 50 then
                            fireproximityprompt(obj)
                            task.wait(1)
                            break
                        end
                    end
                elseif obj:IsA("ClickDetector") then
                    local part = obj.Parent
                    if part and part:IsA("BasePart") then
                        if (root.Position - part.Position).Magnitude < 50 then
                            fireclickdetector(obj)
                            task.wait(1)
                            break
                        end
                    end
                end
            end
            task.wait(3)
        end
    end)
end

local function stopAutoFarm()
    if autoFarmThread then
        task.cancel(autoFarmThread)
        autoFarmThread = nil
    end
end

-- ═══════════════════════════════════════════════════════════
-- UI CONSTRUCTION
-- ═══════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AxomJB_RaceScript"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 720, 0, 480)
MainFrame.Position = UDim2.new(0.5, -360, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(35, 35, 45)
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

-- HEADER
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 70)
Header.BackgroundTransparency = 1
Header.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 400, 0, 30)
Title.Position = UDim2.new(0, 80, 0, 15)
Title.BackgroundTransparency = 1
Title.Text = "RACE SCRIPT"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 24
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(0, 400, 0, 20)
Subtitle.Position = UDim2.new(0, 80, 0, 42)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Mais velocidade, mais progresso!"
Subtitle.TextColor3 = Color3.fromRGB(150, 150, 170)
Subtitle.TextSize = 14
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

local SpeedoIcon = Instance.new("TextLabel")
SpeedoIcon.Size = UDim2.new(0, 50, 0, 50)
SpeedoIcon.Position = UDim2.new(0, 15, 0, 10)
SpeedoIcon.BackgroundTransparency = 1
SpeedoIcon.Text = "🏁"
SpeedoIcon.TextSize = 36
SpeedoIcon.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 20)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = Header
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -75, 0, 20)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "─"
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinBtn.TextSize = 18
MinBtn.Parent = Header

-- SIDEBAR
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 160, 1, -70)
Sidebar.Position = UDim2.new(0, 0, 0, 70)
Sidebar.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)

local function makeSideBtn(text, yPos, isActive)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 140, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = isActive and Color3.fromRGB(0, 140, 255) or Color3.fromRGB(30, 30, 40)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamMedium
    btn.Parent = Sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

makeSideBtn("🏠 Principal", 15, true)
makeSideBtn("⚙️ Configurações", 60, false)
makeSideBtn("📋 Script", 105, false)
makeSideBtn("ℹ️ Sobre", 150, false)

-- CONTENT
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -175, 1, -135)
Content.Position = UDim2.new(0, 165, 0, 75)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- AUTOFARM CARD
local AutoFarmCard = Instance.new("Frame")
AutoFarmCard.Size = UDim2.new(1, -10, 0, 130)
AutoFarmCard.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
AutoFarmCard.BorderSizePixel = 0
AutoFarmCard.Parent = Content
Instance.new("UICorner", AutoFarmCard).CornerRadius = UDim.new(0, 8)

local AFHeader = Instance.new("TextLabel")
AFHeader.Size = UDim2.new(0, 200, 0, 24)
AFHeader.Position = UDim2.new(0, 15, 0, 12)
AFHeader.BackgroundTransparency = 1
AFHeader.Text = "Autofarm"
AFHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
AFHeader.TextSize = 18
AFHeader.Font = Enum.Font.GothamBold
AFHeader.TextXAlignment = Enum.TextXAlignment.Left
AFHeader.Parent = AutoFarmCard

local AFDesc = Instance.new("TextLabel")
AFDesc.Size = UDim2.new(0, 300, 0, 20)
AFDesc.Position = UDim2.new(0, 15, 0, 36)
AFDesc.BackgroundTransparency = 1
AFDesc.Text = "Automatiza a corrida para você ganhar mais."
AFDesc.TextColor3 = Color3.fromRGB(150, 150, 170)
AFDesc.TextSize = 13
AFDesc.Font = Enum.Font.Gotham
AFDesc.TextXAlignment = Enum.TextXAlignment.Left
AFDesc.Parent = AutoFarmCard

local AFRow = Instance.new("Frame")
AFRow.Size = UDim2.new(1, -30, 0, 45)
AFRow.Position = UDim2.new(0, 15, 0, 70)
AFRow.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
AFRow.BorderSizePixel = 0
AFRow.Parent = AutoFarmCard
Instance.new("UICorner", AFRow).CornerRadius = UDim.new(0, 6)

local AFLabel = Instance.new("TextLabel")
AFLabel.Size = UDim2.new(0, 300, 0, 20)
AFLabel.Position = UDim2.new(0, 12, 0, 4)
AFLabel.BackgroundTransparency = 1
AFLabel.Text = "Ativar Autofarm Corrida"
AFLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
AFLabel.TextSize = 14
AFLabel.Font = Enum.Font.GothamMedium
AFLabel.TextXAlignment = Enum.TextXAlignment.Left
AFLabel.Parent = AFRow

local AFSubLabel = Instance.new("TextLabel")
AFSubLabel.Size = UDim2.new(0, 300, 0, 16)
AFSubLabel.Position = UDim2.new(0, 12, 0, 24)
AFSubLabel.BackgroundTransparency = 1
AFSubLabel.Text = "O script irá correr automaticamente e coletar recompensas."
AFSubLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
AFSubLabel.TextSize = 11
AFSubLabel.Font = Enum.Font.Gotham
AFSubLabel.TextXAlignment = Enum.TextXAlignment.Left
AFSubLabel.Parent = AFRow

local AFToggleBg = Instance.new("Frame")
AFToggleBg.Size = UDim2.new(0, 50, 0, 26)
AFToggleBg.Position = UDim2.new(1, -62, 0.5, -13)
AFToggleBg.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
AFToggleBg.BorderSizePixel = 0
AFToggleBg.Parent = AFRow
Instance.new("UICorner", AFToggleBg).CornerRadius = UDim.new(1, 0)

local AFToggleKnob = Instance.new("Frame")
AFToggleKnob.Size = UDim2.new(0, 22, 0, 22)
AFToggleKnob.Position = UDim2.new(1, -24, 0, 2)
AFToggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
AFToggleKnob.BorderSizePixel = 0
AFToggleKnob.Parent = AFToggleBg
Instance.new("UICorner", AFToggleKnob).CornerRadius = UDim.new(1, 0)

local AFToggleHit = Instance.new("TextButton")
AFToggleHit.Size = UDim2.new(1, 0, 1, 0)
AFToggleHit.BackgroundTransparency = 1
AFToggleHit.Text = ""
AFToggleHit.Parent = AFToggleBg

local afState = true
AFToggleHit.MouseButton1Click:Connect(function()
    afState = not afState
    autoFarmEnabled = afState
    TweenService:Create(AFToggleBg, TweenInfo.new(0.15), {
        BackgroundColor3 = afState and Color3.fromRGB(0, 140, 255) or Color3.fromRGB(60, 60, 70)
    }):Play()
    TweenService:Create(AFToggleKnob, TweenInfo.new(0.15), {
        Position = afState and UDim2.new(1, -24, 0, 2) or UDim2.new(0, 2, 0, 2)
    }):Play()
    if afState then startAutoFarm() else stopAutoFarm() end
end)

-- AUTOSPEED CARD
local AutoSpeedCard = Instance.new("Frame")
AutoSpeedCard.Size = UDim2.new(1, -10, 0, 190)
AutoSpeedCard.Position = UDim2.new(0, 0, 0, 145)
AutoSpeedCard.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
AutoSpeedCard.BorderSizePixel = 0
AutoSpeedCard.Parent = Content
Instance.new("UICorner", AutoSpeedCard).CornerRadius = UDim.new(0, 8)

local ASHeader = Instance.new("TextLabel")
ASHeader.Size = UDim2.new(0, 200, 0, 24)
ASHeader.Position = UDim2.new(0, 15, 0, 12)
ASHeader.BackgroundTransparency = 1
ASHeader.Text = "AutoSpeed"
ASHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
ASHeader.TextSize = 18
ASHeader.Font = Enum.Font.GothamBold
ASHeader.TextXAlignment = Enum.TextXAlignment.Left
ASHeader.Parent = AutoSpeedCard

local ASDesc = Instance.new("TextLabel")
ASDesc.Size = UDim2.new(0, 300, 0, 20)
ASDesc.Position = UDim2.new(0, 15, 0, 36)
ASDesc.BackgroundTransparency = 1
ASDesc.Text = "Aumenta a velocidade do carro em até 5000 km/h."
ASDesc.TextColor3 = Color3.fromRGB(150, 150, 170)
ASDesc.TextSize = 13
ASDesc.Font = Enum.Font.Gotham
ASDesc.TextXAlignment = Enum.TextXAlignment.Left
ASDesc.Parent = AutoSpeedCard

local ASRow = Instance.new("Frame")
ASRow.Size = UDim2.new(1, -30, 0, 45)
ASRow.Position = UDim2.new(0, 15, 0, 65)
ASRow.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
ASRow.BorderSizePixel = 0
ASRow.Parent = AutoSpeedCard
Instance.new("UICorner", ASRow).CornerRadius = UDim.new(0, 6)

local ASLabel = Instance.new("TextLabel")
ASLabel.Size = UDim2.new(0, 300, 0, 20)
ASLabel.Position = UDim2.new(0, 12, 0, 4)
ASLabel.BackgroundTransparency = 1
ASLabel.Text = "Ativar AutoSpeed"
ASLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
ASLabel.TextSize = 14
ASLabel.Font = Enum.Font.GothamMedium
ASLabel.TextXAlignment = Enum.TextXAlignment.Left
ASLabel.Parent = ASRow

local ASSubLabel = Instance.new("TextLabel")
ASSubLabel.Size = UDim2.new(0, 300, 0, 16)
ASSubLabel.Position = UDim2.new(0, 12, 0, 24)
ASSubLabel.BackgroundTransparency = 1
ASSubLabel.Text = "Aumenta a velocidade do seu carro automaticamente."
ASSubLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
ASSubLabel.TextSize = 11
ASSubLabel.Font = Enum.Font.Gotham
ASSubLabel.TextXAlignment = Enum.TextXAlignment.Left
ASSubLabel.Parent = ASRow

local ASToggleBg = Instance.new("Frame")
ASToggleBg.Size = UDim2.new(0, 50, 0, 26)
ASToggleBg.Position = UDim2.new(1, -62, 0.5, -13)
ASToggleBg.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
ASToggleBg.BorderSizePixel = 0
ASToggleBg.Parent = ASRow
Instance.new("UICorner", ASToggleBg).CornerRadius = UDim.new(1, 0)

local ASToggleKnob = Instance.new("Frame")
ASToggleKnob.Size = UDim2.new(0, 22, 0, 22)
ASToggleKnob.Position = UDim2.new(1, -24, 0, 2)
ASToggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ASToggleKnob.BorderSizePixel = 0
ASToggleKnob.Parent = ASToggleBg
Instance.new("UICorner", ASToggleKnob).CornerRadius = UDim.new(1, 0)

local ASToggleHit = Instance.new("TextButton")
ASToggleHit.Size = UDim2.new(1, 0, 1, 0)
ASToggleHit.BackgroundTransparency = 1
ASToggleHit.Text = ""
ASToggleHit.Parent = ASToggleBg

local asState = true
ASToggleHit.MouseButton1Click:Connect(function()
    asState = not asState
    autoSpeedEnabled = asState
    TweenService:Create(ASToggleBg, TweenInfo.new(0.15), {
        BackgroundColor3 = asState and Color3.fromRGB(0, 140, 255) or Color3.fromRGB(60, 60, 70)
    }):Play()
    TweenService:Create(ASToggleKnob, TweenInfo.new(0.15), {
        Position = asState and UDim2.new(1, -24, 0, 2) or UDim2.new(0, 2, 0, 2)
    }):Play()
    if asState then startAutoSpeed() else stopAutoSpeed() end
end)

-- SLIDER
local SliderRow = Instance.new("Frame")
SliderRow.Size = UDim2.new(1, -30, 0, 60)
SliderRow.Position = UDim2.new(0, 15, 0, 120)
SliderRow.BackgroundTransparency = 1
SliderRow.Parent = AutoSpeedCard

local SliderLabel = Instance.new("TextLabel")
SliderLabel.Size = UDim2.new(0, 250, 0, 20)
SliderLabel.BackgroundTransparency = 1
SliderLabel.Text = "Velocidade Máxima (km/h)"
SliderLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
SliderLabel.TextSize = 14
SliderLabel.Font = Enum.Font.GothamMedium
SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
SliderLabel.Parent = SliderRow

local SpeedBox = Instance.new("TextLabel")
SpeedBox.Size = UDim2.new(0, 70, 0, 28)
SpeedBox.Position = UDim2.new(1, -145, 0, 0)
SpeedBox.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
SpeedBox.Text = "5000"
SpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedBox.TextSize = 14
SpeedBox.Font = Enum.Font.GothamBold
SpeedBox.Parent = SliderRow
Instance.new("UICorner", SpeedBox).CornerRadius = UDim.new(0, 4)

local KMHLabel = Instance.new("TextLabel")
KMHLabel.Size = UDim2.new(0, 30, 0, 20)
KMHLabel.Position = UDim2.new(1, -70, 0, 4)
KMHLabel.BackgroundTransparency = 1
KMHLabel.Text = "km/h"
KMHLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
KMHLabel.TextSize = 12
KMHLabel.Font = Enum.Font.Gotham
KMHLabel.Parent = SliderRow

local SliderTrack = Instance.new("Frame")
SliderTrack.Size = UDim2.new(1, 0, 0, 6)
SliderTrack.Position = UDim2.new(0, 0, 0, 40)
SliderTrack.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
SliderTrack.BorderSizePixel = 0
SliderTrack.Parent = SliderRow
Instance.new("UICorner", SliderTrack).CornerRadius = UDim.new(1, 0)

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(1, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderTrack
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

local SliderKnob = Instance.new("Frame")
SliderKnob.Size = UDim2.new(0, 16, 0, 16)
SliderKnob.Position = UDim2.new(1, -8, 0.5, -8)
SliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderKnob.BorderSizePixel = 0
SliderKnob.Parent = SliderTrack
Instance.new("UICorner", SliderKnob).CornerRadius = UDim.new(1, 0)

local dragging = false
SliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement 
                     or input.UserInputType == Enum.UserInputType.Touch) then
        local mousePos = UserInputService:GetMouseLocation()
        local relX = mousePos.X - SliderTrack.AbsolutePosition.X
        local percent = math.clamp(relX / SliderTrack.AbsoluteSize.X, 0, 1)
        SliderKnob.Position = UDim2.new(percent, -8, 0.5, -8)
        SliderFill.Size = UDim2.new(percent, 0, 1, 0)
        maxSpeed = math.floor(100 + percent * 4900)
        SpeedBox.Text = tostring(maxSpeed)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- EXECUTE BUTTON
local ExecBtn = Instance.new("TextButton")
ExecBtn.Size = UDim2.new(1, -30, 0, 50)
ExecBtn.Position = UDim2.new(0, 15, 1, -65)
ExecBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
ExecBtn.Text = "▶ Executar Script"
ExecBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ExecBtn.TextSize = 16
ExecBtn.Font = Enum.Font.GothamBold
ExecBtn.Parent = MainFrame
Instance.new("UICorner", ExecBtn).CornerRadius = UDim.new(0, 8)

ExecBtn.MouseButton1Click:Connect(function()
    autoFarmEnabled = afState
    autoSpeedEnabled = asState
    if afState then startAutoFarm() end
    if asState then startAutoSpeed() end
    ExecBtn.Text = "✓ Script Ativado"
    task.wait(2)
    ExecBtn.Text = "▶ Executar Script"
end)

-- STATUS
local StatusBar = Instance.new("TextLabel")
StatusBar.Size = UDim2.new(0, 300, 0, 20)
StatusBar.Position = UDim2.new(0, 15, 1, -25)
StatusBar.BackgroundTransparency = 1
StatusBar.Text = "● Status: Pronto | Versão 1.0.0"
StatusBar.TextColor3 = Color3.fromRGB(100, 255, 100)
StatusBar.TextSize = 12
StatusBar.Font = Enum.Font.Gotham
StatusBar.TextXAlignment = Enum.TextXAlignment.Left
StatusBar.Parent = MainFrame

-- MINIMIZE
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    ExecBtn.Visible = not minimized
    StatusBar.Visible = not minimized
    Sidebar.Visible = not minimized
    MainFrame.Size = minimized and UDim2.new(0, 720, 0, 70) 
                       or UDim2.new(0, 720, 0, 480)
end)

-- Start enabled by default (toggles are ON in screenshot)
startAutoFarm()
startAutoSpeed()

print("[AxomJB] Race Script loaded. Status: Pronto | v1.0.0")