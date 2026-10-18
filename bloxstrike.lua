--[[
    AxomJB Blox Strike Panel
    Aim + ESP | Real modifications | Production-grade
    Author: AxomJB
]]

-- ============================================================
-- SERVICES & GUARDS
-- ============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local Camera            = Workspace.CurrentCamera
local LocalPlayer       = Players.LocalPlayer
local Mouse             = LocalPlayer:GetMouse()

if not game:IsLoaded() then game.Loaded:Wait() end

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    Aim = {
        Enabled       = false,
        Key           = Enum.UserInputType.MouseButton2, -- Right-click
        Smoothness    = 0.15,
        FOV           = 120,
        SilentAim     = false,
        Triggerbot    = false,
        TriggerDelay  = 0.05,
        TriggerRange  = 200,
        WallCheck     = true,
        TargetPart    = "Head",
    },
    ESP = {
        Box        = true,
        Skeleton   = true,
        Name       = true,
        Health     = true,
        Weapon     = true,
        Distance   = true,
        Color      = Color3.fromRGB(0, 255, 140),
        TextColor  = Color3.fromRGB(255, 255, 255),
        MaxDist    = 1000,
    },
}

-- ============================================================
-- HELPERS
-- ============================================================
local function getCharacter(model)
    if model and model:FindFirstChildOfClass("Humanoid") then return model end
    return nil
end

local function isAlive(char)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function getTargets()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isAlive(p.Character) then
            table.insert(list, p)
        end
    end
    return list
end

local function worldToViewport(worldPos)
    local screen, onScreen = Camera:WorldToViewportPoint(worldPos)
    return Vector2.new(screen.X, screen.Y), onScreen, screen.Z
end

local function getCameraPos()
    return Camera.CFrame.Position
end

local function hasLineOfSight(char, part)
    local origin = getCameraPos()
    local dir    = (part.Position - origin)
    local ray    = Ray.new(origin, dir)
    local hit    = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
    return hit == nil or hit:IsDescendantOf(char)
end

-- ============================================================
-- TARGET SELECTION (FOV-based, closest to crosshair)
-- ============================================================
local function getBestTarget(fov)
    local best, bestScore = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, p in ipairs(getTargets()) do
        local char = p.Character
        local part = char:FindFirstChild(Config.Aim.TargetPart) or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end

        local screenPos, onScreen, depth = worldToViewport(part.Position)
        if onScreen and depth > 0 then
            local dist = (screenPos - center).Magnitude
            if dist <= fov and dist < bestScore then
                if not Config.Aim.WallCheck or hasLineOfSight(char, part) then
                    best, bestScore = { player = p, part = part, screen = screenPos }, dist
                end
            end
        end
    end
    return best
end

-- ============================================================
-- AIMBOT (Right-Click pulls to head, smooth)
-- ============================================================
local aimHeld = false

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Config.Aim.Key then
        aimHeld = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Config.Aim.Key then
        aimHeld = false
    end
end)

-- Silent aim hook (metatable on CFrame for Camera fire — classic method)
local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
    if not checkcaller() and Config.Aim.Enabled and Config.Aim.SilentAim and key == "CFrame" then
        local target = getBestTarget(Config.Aim.FOV)
        if target then
            local origin = Camera.CFrame.Position
            local dir    = (target.part.Position - origin).Unit
            return CFrame.lookAt(origin, origin + dir)
        end
    end
    return oldIndex(self, key)
end))

RunService.RenderStepped:Connect(function()
    if not Config.Aim.Enabled then return end
    if not aimHeld and not Config.Aim.SilentAim then return end
    if not isAlive(LocalPlayer.Character) then return end

    local target = getBestTarget(Config.Aim.FOV)
    if not target then return end

    if Config.Aim.SilentAim then
        -- handled in hookmetamethod
    else
        -- Smooth aim toward head
        local currentCF = Camera.CFrame
        local desired   = CFrame.lookAt(currentCF.Position, target.part.Position)
        Camera.CFrame   = currentCF:Lerp(desired, Config.Aim.Smoothness)
    end
end)

-- ============================================================
-- TRIGGERBOT
-- ============================================================
local lastTrigger = 0
RunService.Heartbeat:Connect(function()
    if not Config.Aim.Enabled or not Config.Aim.Triggerbot then return end
    if not isAlive(LocalPlayer.Character) then return end
    if tick() - lastTrigger < Config.Aim.TriggerDelay then return end

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, p in ipairs(getTargets()) do
        local char = p.Character
        local part = char:FindFirstChild("HumanoidRootPart")
        if not part then continue end
        local screenPos, onScreen, depth = worldToViewport(part.Position)
        if onScreen and depth > 0 and depth <= Config.Aim.TriggerRange then
            if (screenPos - center).Magnitude < 35 then
                if not Config.Aim.WallCheck or hasLineOfSight(char, part) then
                    mouse1click()
                    lastTrigger = tick()
                    break
                end
            end
        end
    end
end)

-- ============================================================
-- ESP (Drawing API — box/skeleton/name/health/weapon/distance)
-- ============================================================
local ESP_Objects = {}

local function makeESP(player)
    local data = { drawings = {} }
    local function newD(class, props)
        local d = Drawing.new(class)
        for k, v in pairs(props) do d[k] = v end
        table.insert(data.drawings, d)
        return d
    end
    data.box      = newD("Square",   { Thickness = 1, Filled = false, Color = Config.ESP.Color, Visible = false })
    data.boxFill  = newD("Square",   { Thickness = 1, Filled = true,  Transparency = 0.75, Color = Color3.new(0,0,0), Visible = false })
    data.name     = newD("Text",     { Size = 14, Center = true, Outline = true, Color = Config.ESP.TextColor, Visible = false })
    data.healthBg = newD("Square",   { Filled = true, Color = Color3.new(0,0,0), Transparency = 0.5, Visible = false })
    data.health   = newD("Square",   { Filled = true, Color = Color3.fromRGB(0,255,0), Visible = false })
    data.weapon   = newD("Text",     { Size = 13, Center = true, Outline = true, Color = Color3.fromRGB(255,220,120), Visible = false })
    data.distance = newD("Text",     { Size = 13, Center = true, Outline = true, Color = Color3.fromRGB(200,200,255), Visible = false })
    data.lines    = {}
    ESP_Objects[player] = data
end

local function removeESP(player)
    local data = ESP_Objects[player]
    if not data then return end
    for _, d in ipairs(data.drawings) do d:Remove() end
    for _, l in ipairs(data.lines) do l:Remove() end
    ESP_Objects[player] = nil
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then makeESP(p) end
end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then makeESP(p) end end)
Players.PlayerRemoving:Connect(removeESP)

-- Skeleton parts
local SKELETON_PARTS = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}

local function getWeaponName(char)
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then return tool.Name end
    end
    return nil
end

RunService.RenderStepped:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        local data = ESP_Objects[p]
        if not data then continue end
        local char = p.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")

        if not isAlive(char) then
            for _, d in ipairs(data.drawings) do d.Visible = false end
            for _, l in ipairs(data.lines) do l.Visible = false end
            continue
        end

        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if not root or not head then continue end

        local dist = (Camera.CFrame.Position - root.Position).Magnitude
        local onScreenInRange = dist <= Config.ESP.MaxDist

        -- BOX
        local topPos, topOn, topD = worldToViewport(head.Position + Vector3.new(0,0.5,0))
        local botPos, botOn, botD = worldToViewport(root.Position - Vector3.new(0,3,0))
        if onScreenInRange and topOn and botOn and topD > 0 and botD > 0 then
            local h = botPos.Y - topPos.Y
            local w = h * 0.55
            data.box.Position = Vector2.new(topPos.X - w/2, topPos.Y)
            data.box.Size     = Vector2.new(w, h)
            data.box.Visible  = Config.ESP.Box
            data.box.Color    = Config.ESP.Color

            data.boxFill.Position = data.box.Position
            data.boxFill.Size     = data.box.Size
            data.boxFill.Visible  = Config.ESP.Box and false -- toggle if u want

            -- Name
            data.name.Text     = p.Name
            data.name.Position = Vector2.new(topPos.X, topPos.Y - 18)
            data.name.Visible  = Config.ESP.Name
            data.name.Color    = Config.ESP.TextColor

            -- Health
            if hum then
                local ratio = hum.Health / hum.MaxHealth
                data.healthBg.Position = Vector2.new(topPos.X - w/2 - 6, topPos.Y)
                data.healthBg.Size     = Vector2.new(4, h)
                data.healthBg.Visible  = Config.ESP.Health

                data.health.Position = Vector2.new(topPos.X - w/2 - 6, topPos.Y + h*(1-ratio))
                data.health.Size     = Vector2.new(4, h*ratio)
                data.health.Color    = Color3.fromRGB(255*(1-ratio), 255*ratio, 0)
                data.health.Visible  = Config.ESP.Health
            end

            -- Weapon
            local wpn = getWeaponName(char)
            data.weapon.Text     = wpn or ""
            data.weapon.Position = Vector2.new(topPos.X, botPos.Y + 4)
            data.weapon.Visible  = Config.ESP.Weapon and wpn ~= nil

            -- Distance
            data.distance.Text     = ("[%d m]"):format(math.floor(dist))
            data.distance.Position = Vector2.new(topPos.X, botPos.Y + 20)
            data.distance.Visible  = Config.ESP.Distance

            -- Skeleton
            if Config.ESP.Skeleton then
                for i, pair in ipairs(SKELETON_PARTS) do
                    local a = char:FindFirstChild(pair[1])
                    local b = char:FindFirstChild(pair[2])
                    if a and b then
                        local pa, onA, dA = worldToViewport(a.Position)
                        local pb, onB, dB = worldToViewport(b.Position)
                        if not data.lines[i] then
                            data.lines[i] = Drawing.new("Line")
                            data.lines[i].Thickness = 1
                            data.lines[i].Color = Config.ESP.Color
                        end
                        local line = data.lines[i]
                        if onA and onB and dA > 0 and dB > 0 then
                            line.From    = pa
                            line.To      = pb
                            line.Visible = true
                        else
                            line.Visible = false
                        end
                    end
                end
            else
                for _, l in ipairs(data.lines) do l.Visible = false end
            end
        else
            for _, d in ipairs(data.drawings) do d.Visible = false end
            for _, l in ipairs(data.lines) do l.Visible = false end
        end
    end

    -- FOV Circle
    if FOV_CIRCLE then
        FOV_CIRCLE.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        FOV_CIRCLE.Radius   = Config.Aim.FOV
        FOV_CIRCLE.Visible  = Config.Aim.Enabled
    end
end)

-- ============================================================
-- UI (2 tabs: Aim + ESP)
-- ============================================================
local function createUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AxomJB_Panel"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 520, 0, 380)
    Main.Position = UDim2.new(0.5, -260, 0.5, -190)
    Main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Main

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(0, 255, 140)
    Stroke.Thickness = 1.5
    Stroke.Parent = Main

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 36)
    Title.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    Title.BorderSizePixel = 0
    Title.Text = "  AxomJB | Blox Strike"
    Title.TextColor3 = Color3.fromRGB(0, 255, 140)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.Parent = Main

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 10)
    TitleCorner.Parent = Title

    -- Tab buttons
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(1, -20, 0, 32)
    TabBar.Position = UDim2.new(0, 10, 0, 44)
    TabBar.BackgroundTransparency = 1
    TabBar.Parent = Main

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.Padding = UDim.new(0, 8)
    TabLayout.Parent = TabBar

    local function makeTabBtn(text)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 100, 1, 0)
        b.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        b.BorderSizePixel = 0
        b.Text = text
        b.TextColor3 = Color3.fromRGB(200, 200, 200)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 13
        b.AutoButtonColor = false
        b.Parent = TabBar
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = b
        return b
    end

    local AimTab = makeTabBtn("AIM")
    local EspTab = makeTabBtn("ESP")

    -- Content
    local AimPage = Instance.new("ScrollingFrame")
    AimPage.Size = UDim2.new(1, -20, 1, -110)
    AimPage.Position = UDim2.new(0, 10, 0, 84)
    AimPage.BackgroundTransparency = 1
    AimPage.BorderSizePixel = 0
    AimPage.ScrollBarThickness = 4
    AimPage.CanvasSize = UDim2.new(0, 0, 0, 0)
    AimPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
    AimPage.Parent = Main

    local EspPage = AimPage:Clone()
    EspPage.Parent = Main
    EspPage.Visible = false

    local AimLayout = Instance.new("UIListLayout")
    AimLayout.Padding = UDim.new(0, 8)
    AimLayout.Parent = AimPage

    local EspLayout = Instance.new("UIListLayout")
    EspLayout.Padding = UDim.new(0, 8)
    EspLayout.Parent = EspPage

    local function setActiveTab(active)
        AimPage.Visible = active == AimTab
        EspPage.Visible = active == EspTab
        AimTab.BackgroundColor3 = (active == AimTab) and Color3.fromRGB(0,255,140) or Color3.fromRGB(30,30,38)
        AimTab.TextColor3       = (active == AimTab) and Color3.fromRGB(15,15,18) or Color3.fromRGB(200,200,200)
        EspTab.BackgroundColor3 = (active == EspTab) and Color3.fromRGB(0,255,140) or Color3.fromRGB(30,30,38)
        EspTab.TextColor3       = (active == EspTab) and Color3.fromRGB(15,15,18) or Color3.fromRGB(200,200,200)
    end
    AimTab.MouseButton1Click:Connect(function() setActiveTab(AimTab) end)
    EspTab.MouseButton1Click:Connect(function() setActiveTab(EspTab) end)
    setActiveTab(AimTab)

    -- ============================================
    -- WIDGETS
    -- ============================================
    local function makeToggle(parent, label, configTable, key)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
        row.BorderSizePixel = 0
        row.Parent = parent
        local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 6); rc.Parent = row

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -70, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 50, 0, 22)
        btn.Position = UDim2.new(1, -60, 0.5, -11)
        btn.BackgroundColor3 = configTable[key] and Color3.fromRGB(0,255,140) or Color3.fromRGB(50,50,60)
        btn.Text = configTable[key] and "ON" or "OFF"
        btn.TextColor3 = Color3.fromRGB(15,15,18)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.BorderSizePixel = 0
        btn.Parent = row
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 4); bc.Parent = btn

        btn.MouseButton1Click:Connect(function()
            configTable[key] = not configTable[key]
            btn.BackgroundColor3 = configTable[key] and Color3.fromRGB(0,255,140) or Color3.fromRGB(50,50,60)
            btn.Text = configTable[key] and "ON" or "OFF"
        end)
        return row
    end

    local function makeSlider(parent, label, configTable, key, min, max, isInt)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 44)
        row.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
        row.BorderSizePixel = 0
        row.Parent = parent
        local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 6); rc.Parent = row

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 20)
        lbl.Position = UDim2.new(0, 10, 0, 2)
        lbl.BackgroundTransparency = 1
        lbl.Text = ("%s: %s"):format(label, tostring(configTable[key]))
        lbl.TextColor3 = Color3.fromRGB(220,220,220)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -20, 0, 6)
        bar.Position = UDim2.new(0, 10, 0, 30)
        bar.BackgroundColor3 = Color3.fromRGB(40,40,50)
        bar.BorderSizePixel = 0
        bar.Parent = row
        local brc = Instance.new("UICorner"); brc.CornerRadius = UDim.new(0, 3); brc.Parent = bar

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((configTable[key]-min)/(max-min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(0,255,140)
        fill.BorderSizePixel = 0
        fill.Parent = bar
        local frc = Instance.new("UICorner"); frc.CornerRadius = UDim.new(0, 3); frc.Parent = fill

        local dragging = false
        local function updateFromX(x)
            local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = min + rel * (max - min)
            if isInt then val = math.floor(val + 0.5) end
            configTable[key] = val
            fill.Size = UDim2.new(rel, 0, 1, 0)
            lbl.Text = ("%s: %s"):format(label, tostring(val))
        end
        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                updateFromX(i.Position.X)
            end
        end)
        return row
    end

    -- ============ AIM PAGE ============
    makeToggle(AimPage, "Aimbot  [Right-Click]",  Config.Aim, "Enabled")
    makeToggle(AimPage, "Silent Aim",            Config.Aim, "SilentAim")
    makeToggle(AimPage, "Triggerbot",            Config.Aim, "Triggerbot")
    makeToggle(AimPage, "Wall Check",            Config.Aim, "WallCheck")
    makeSlider(AimPage, "Smoothness", Config.Aim, "Smoothness", 0.01, 1.0, false)
    makeSlider(AimPage, "FOV",        Config.Aim, "FOV",        10,   500, true)
    makeSlider(AimPage, "Trigger Delay", Config.Aim, "TriggerDelay", 0, 0.5, false)
    makeSlider(AimPage, "Trigger Range", Config.Aim, "TriggerRange", 10, 500, true)

    -- ============ ESP PAGE ============
    makeToggle(EspPage, "Box ESP",      Config.ESP, "Box")
    makeToggle(EspPage, "Skeleton ESP", Config.ESP, "Skeleton")
    makeToggle(EspPage, "Name ESP",     Config.ESP, "Name")
    makeToggle(EspPage, "Health Bar",   Config.ESP, "Health")
    makeToggle(EspPage, "Weapon ESP",   Config.ESP, "Weapon")
    makeToggle(EspPage, "Distance ESP", Config.ESP, "Distance")
    makeSlider(EspPage, "Max Distance", Config.ESP, "MaxDist", 50, 3000, true)

    -- FOV circle drawing
    FOV_CIRCLE = Drawing.new("Circle")
    FOV_CIRCLE.Thickness = 1.5
    FOV_CIRCLE.NumSides = 60
    FOV_CIRCLE.Color = Color3.fromRGB(0,255,140)
    FOV_CIRCLE.Transparency = 0.6
    FOV_CIRCLE.Filled = false
    FOV_CIRCLE.Visible = false
    FOV_CIRCLE.Radius = Config.Aim.FOV
end

createUI()

-- ============================================================
-- MOUSE FUNCTIONS (for triggerbot)
-- ============================================================
local function mouse1click()
    if mouse1click_real then return mouse1click_real() end
    -- fallback: virtual mouse input
    local vim = game:GetService("VirtualInputManager")
    vim:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, game, 0)
    task.wait(0.02)
    vim:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, game, 0)
end

print("[AxomJB] Loaded. Panel ready. Aimbot + ESP live. 🔥")