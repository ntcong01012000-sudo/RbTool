--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
--[[
    WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
-- =====================================================================
-- CENIROSO REMOTE SPY - V1.8 (Giao dien moi - Than thien mobile)
-- =====================================================================

if getgenv().SoroniceV1SpyLoaded then
    if game.CoreGui:FindFirstChild("cenirosoRemoteSpy") then
        game.CoreGui.cenirosoRemoteSpy:Destroy()
    end
end
getgenv().SoroniceV1SpyLoaded = true

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

_G.RawCode = ""

-- Système de file d'attente pour le mode Ralenti
local RemoteQueue = {}
local IsSlowMode = false
local MAX_QUEUE_SIZE = 150

-- Trang thai
local IsCollecting = true
local IsMinimized = false
local selectedButton = nil
local totalRemotes = 0

-- Kich thuoc gioi han khi resize
local MIN_W, MIN_H = 340, 230
local MAX_W, MAX_H = 900, 600

-- =====================================================================
-- 1. GIAO DIEN NGUOI DUNG (UI)
-- =====================================================================

-- Bang mau chu dao
local C = {
    Bg        = Color3.fromRGB(18, 18, 24),
    Surface   = Color3.fromRGB(26, 27, 35),
    SurfaceLt = Color3.fromRGB(34, 36, 46),
    TopBar    = Color3.fromRGB(14, 14, 20),
    Accent    = Color3.fromRGB(75, 115, 230),
    Green     = Color3.fromRGB(55, 178, 120),
    Red       = Color3.fromRGB(210, 65, 65),
    Orange    = Color3.fromRGB(220, 150, 45),
    Gray      = Color3.fromRGB(65, 70, 82),
    Text1     = Color3.fromRGB(220, 224, 232),
    Text2     = Color3.fromRGB(120, 128, 145),
    Text3     = Color3.fromRGB(72, 78, 92),
    Border    = Color3.fromRGB(38, 40, 50),
    Selected  = Color3.fromRGB(55, 90, 180),
    Resize    = Color3.fromRGB(55, 58, 70),
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "cenirosoRemoteSpy"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ========== NUT TOGGLE NOI (thu nho / phong to) ==========
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Parent = ScreenGui
ToggleBtn.BackgroundColor3 = C.Accent
ToggleBtn.Position = UDim2.new(0, 10, 0.7, 0)
ToggleBtn.Size = UDim2.new(0, 38, 0, 38)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Text = "RS"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 13
ToggleBtn.ZIndex = 100
ToggleBtn.Active = true
ToggleBtn.Visible = false

Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 19)

local tglStroke = Instance.new("UIStroke")
tglStroke.Parent = ToggleBtn
tglStroke.Color = C.Accent
tglStroke.Thickness = 1.5
tglStroke.Transparency = 0.5

-- Hieu ung nhap nhay nhe cho nut toggle
task.spawn(function()
    while ToggleBtn and ToggleBtn.Parent do
        if ToggleBtn.Visible then
            TweenService:Create(tglStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.8}):Play()
            task.wait(1)
            TweenService:Create(tglStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.3}):Play()
            task.wait(1)
        else
            task.wait(0.5)
        end
    end
end)

-- ========== KHUNG CHINH (nho hon, phu hop mobile) ==========
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = C.Bg
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -220, 0.5, -150)
MainFrame.Size = UDim2.new(0, 440, 0, 300)
MainFrame.Active = true
MainFrame.ClipsDescendants = true

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local mfStroke = Instance.new("UIStroke")
mfStroke.Parent = MainFrame
mfStroke.Color = C.Border
mfStroke.Thickness = 1
mfStroke.Transparency = 0.5

-- ========== THANH TIEU DE (keo tha o day) ==========
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = C.TopBar
TopBar.BorderSizePixel = 0
TopBar.Size = UDim2.new(1, 0, 0, 34)

Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)

local tbHide = Instance.new("Frame")
tbHide.Parent = TopBar
tbHide.BackgroundColor3 = C.TopBar
tbHide.BorderSizePixel = 0
tbHide.Position = UDim2.new(0, 0, 1, -5)
tbHide.Size = UDim2.new(1, 0, 0, 5)

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Parent = TopBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 12, 0, 0)
Title.Size = UDim2.new(0.45, 0, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "Remote Spy v1.8"
Title.TextColor3 = C.Text1
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Cham trang thai + nhan
local StatusDot = Instance.new("Frame")
StatusDot.Parent = TopBar
StatusDot.BackgroundColor3 = C.Green
StatusDot.Size = UDim2.new(0, 7, 0, 7)
StatusDot.Position = UDim2.new(1, -120, 0.5, -3)
Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = TopBar
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(1, -109, 0, 0)
StatusLabel.Size = UDim2.new(0, 50, 1, 0)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Dang thu"
StatusLabel.TextColor3 = C.Green
StatusLabel.TextSize = 10
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Nut thu nho (minimize)
local MinBtn = Instance.new("TextButton")
MinBtn.Parent = TopBar
MinBtn.BackgroundTransparency = 1
MinBtn.Position = UDim2.new(1, -52, 0, 0)
MinBtn.Size = UDim2.new(0, 26, 1, 0)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "-"
MinBtn.TextColor3 = C.Text2
MinBtn.TextSize = 18

-- Nut dong
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Parent = TopBar
CloseButton.BackgroundTransparency = 1
CloseButton.Position = UDim2.new(1, -26, 0, 0)
CloseButton.Size = UDim2.new(0, 26, 1, 0)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "X"
CloseButton.TextColor3 = C.Text2
CloseButton.TextSize = 12

-- Hover cho cac nut tren thanh tieu de
for _, btn in ipairs({MinBtn, CloseButton}) do
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {TextColor3 = C.Text1}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {TextColor3 = C.Text2}):Play()
    end)
end

-- ========== BANG TRAI (Danh sach Remote) - Scale-based ==========
local LeftPanel = Instance.new("Frame")
LeftPanel.Parent = MainFrame
LeftPanel.BackgroundColor3 = C.Surface
LeftPanel.BorderSizePixel = 0
LeftPanel.Position = UDim2.new(0, 6, 0, 40)
LeftPanel.Size = UDim2.new(0.35, -3, 1, -80)
Instance.new("UICorner", LeftPanel).CornerRadius = UDim.new(0, 8)

-- O tim kiem
local SearchBar = Instance.new("Frame")
SearchBar.Parent = LeftPanel
SearchBar.BackgroundColor3 = C.SurfaceLt
SearchBar.BorderSizePixel = 0
SearchBar.Position = UDim2.new(0, 5, 0, 5)
SearchBar.Size = UDim2.new(1, -10, 0, 26)
Instance.new("UICorner", SearchBar).CornerRadius = UDim.new(0, 5)

local SearchIcon = Instance.new("TextLabel")
SearchIcon.Parent = SearchBar
SearchIcon.BackgroundTransparency = 1
SearchIcon.Position = UDim2.new(0, 5, 0, 0)
SearchIcon.Size = UDim2.new(0, 14, 1, 0)
SearchIcon.Font = Enum.Font.Gotham
SearchIcon.Text = "?"
SearchIcon.TextColor3 = C.Text3
SearchIcon.TextSize = 11

local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchBox"
SearchBox.Parent = SearchBar
SearchBox.BackgroundTransparency = 1
SearchBox.Position = UDim2.new(0, 20, 0, 0)
SearchBox.Size = UDim2.new(1, -25, 1, 0)
SearchBox.Font = Enum.Font.Gotham
SearchBox.PlaceholderText = "Tim remote..."
SearchBox.PlaceholderColor3 = C.Text3
SearchBox.Text = ""
SearchBox.TextColor3 = C.Text1
SearchBox.TextSize = 11
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false

-- Dem so remote
local RemoteCount = Instance.new("TextLabel")
RemoteCount.Parent = LeftPanel
RemoteCount.BackgroundTransparency = 1
RemoteCount.Position = UDim2.new(0, 7, 0, 34)
RemoteCount.Size = UDim2.new(1, -14, 0, 13)
RemoteCount.Font = Enum.Font.Gotham
RemoteCount.Text = "0 remotes"
RemoteCount.TextColor3 = C.Text3
RemoteCount.TextSize = 9
RemoteCount.TextXAlignment = Enum.TextXAlignment.Left

-- Danh sach cuon remote
local RemotesList = Instance.new("ScrollingFrame")
RemotesList.Name = "RemotesList"
RemotesList.Parent = LeftPanel
RemotesList.Active = true
RemotesList.BackgroundTransparency = 1
RemotesList.BorderSizePixel = 0
RemotesList.Position = UDim2.new(0, 3, 0, 50)
RemotesList.Size = UDim2.new(1, -6, 1, -54)
RemotesList.CanvasSize = UDim2.new(0, 0, 0, 0)
RemotesList.ScrollBarThickness = 3
RemotesList.ScrollBarImageColor3 = C.Text3

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = RemotesList
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 2)

-- Auto-cap nhat kich thuoc cuon
UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    RemotesList.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
end)

-- ========== BANG PHAI (Hien thi ma nguon) - Scale-based ==========
local RightPanel = Instance.new("Frame")
RightPanel.Parent = MainFrame
RightPanel.BackgroundColor3 = C.Surface
RightPanel.BorderSizePixel = 0
RightPanel.Position = UDim2.new(0.35, 3, 0, 40)
RightPanel.Size = UDim2.new(0.65, -9, 1, -80)
Instance.new("UICorner", RightPanel).CornerRadius = UDim.new(0, 8)

-- Header ma nguon
local CodeHeader = Instance.new("Frame")
CodeHeader.Parent = RightPanel
CodeHeader.BackgroundColor3 = C.SurfaceLt
CodeHeader.BorderSizePixel = 0
CodeHeader.Size = UDim2.new(1, 0, 0, 22)
Instance.new("UICorner", CodeHeader).CornerRadius = UDim.new(0, 8)

local chHide = Instance.new("Frame")
chHide.Parent = CodeHeader
chHide.BackgroundColor3 = C.SurfaceLt
chHide.BorderSizePixel = 0
chHide.Position = UDim2.new(0, 0, 1, -4)
chHide.Size = UDim2.new(1, 0, 0, 4)

local CodeHeaderLbl = Instance.new("TextLabel")
CodeHeaderLbl.Parent = CodeHeader
CodeHeaderLbl.BackgroundTransparency = 1
CodeHeaderLbl.Position = UDim2.new(0, 8, 0, 0)
CodeHeaderLbl.Size = UDim2.new(1, -16, 1, 0)
CodeHeaderLbl.Font = Enum.Font.GothamBold
CodeHeaderLbl.Text = "Ma nguon"
CodeHeaderLbl.TextColor3 = C.Text2
CodeHeaderLbl.TextSize = 9
CodeHeaderLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Khung cuon ma nguon
local CodeScroll = Instance.new("ScrollingFrame")
CodeScroll.Parent = RightPanel
CodeScroll.BackgroundTransparency = 1
CodeScroll.BorderSizePixel = 0
CodeScroll.Position = UDim2.new(0, 0, 0, 22)
CodeScroll.Size = UDim2.new(1, 0, 1, -22)
CodeScroll.CanvasSize = UDim2.new(0, 0, 0, 600)
CodeScroll.ScrollBarThickness = 3
CodeScroll.ScrollBarImageColor3 = C.Text3

-- Thu dung AutomaticCanvasSize neu executor ho tro
pcall(function()
    CodeScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
end)

local CodeDisplay = Instance.new("TextLabel")
CodeDisplay.Name = "CodeDisplay"
CodeDisplay.Parent = CodeScroll
CodeDisplay.BackgroundTransparency = 1
CodeDisplay.Size = UDim2.new(1, 0, 0, 0)
CodeDisplay.Font = Enum.Font.Code
CodeDisplay.Text = '<font color="#7A828B">-- Cho su kien...\n-- Ma nguon se hien thi o day.</font>'
CodeDisplay.TextColor3 = Color3.fromRGB(248, 248, 242)
CodeDisplay.TextSize = 12
CodeDisplay.TextXAlignment = Enum.TextXAlignment.Left
CodeDisplay.TextYAlignment = Enum.TextYAlignment.Top
CodeDisplay.RichText = true
CodeDisplay.TextWrapped = true

-- Thu dung AutomaticSize neu executor ho tro
pcall(function()
    CodeDisplay.AutomaticSize = Enum.AutomaticSize.Y
end)

-- Fallback: cap nhat canvas size qua TextBounds
CodeDisplay:GetPropertyChangedSignal("TextBounds"):Connect(function()
    local h = CodeDisplay.TextBounds.Y + 24
    if h > CodeScroll.AbsoluteSize.Y then
        CodeScroll.CanvasSize = UDim2.new(0, 0, 0, h)
    else
        CodeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    end
end)

local codePad = Instance.new("UIPadding")
codePad.Parent = CodeDisplay
codePad.PaddingTop = UDim.new(0, 6)
codePad.PaddingLeft = UDim.new(0, 8)
codePad.PaddingRight = UDim.new(0, 8)
codePad.PaddingBottom = UDim.new(0, 6)

-- ========== THANH CONG CU DUOI (full width) ==========
local Toolbar = Instance.new("Frame")
Toolbar.Parent = MainFrame
Toolbar.BackgroundTransparency = 1
Toolbar.Position = UDim2.new(0, 6, 1, -34)
Toolbar.Size = UDim2.new(1, -12, 0, 28)

local tbLayout = Instance.new("UIListLayout")
tbLayout.Parent = Toolbar
tbLayout.FillDirection = Enum.FillDirection.Horizontal
tbLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tbLayout.Padding = UDim.new(0, 5)

-- Ham tao nut toolbar co hover effect
local function MakeBtn(name, text, color)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Parent = Toolbar
    btn.BackgroundColor3 = color
    btn.Size = UDim2.new(0, 78, 0, 26)
    btn.Font = Enum.Font.GothamBold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 10
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    local base = color
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(
                math.min(base.R * 255 + 20, 255),
                math.min(base.G * 255 + 20, 255),
                math.min(base.B * 255 + 20, 255)
            )
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = base}):Play()
    end)

    return btn
end

local PauseButton = MakeBtn("PauseBtn", "Dung thu", C.Orange)
local CopyButton = MakeBtn("CopyBtn", "Sao chep", C.Accent)
local SlowButton = MakeBtn("SlowBtn", "Cham: TAT", C.Gray)
local ClearButton = MakeBtn("ClearBtn", "Xoa het", C.Red)

-- ========== TAY CAM RESIZE (goc duoi phai) ==========
local ResizeHandle = Instance.new("TextButton")
ResizeHandle.Name = "ResizeHandle"
ResizeHandle.Parent = MainFrame
ResizeHandle.BackgroundColor3 = C.Resize
ResizeHandle.BackgroundTransparency = 0.2
ResizeHandle.Position = UDim2.new(1, -16, 1, -16)
ResizeHandle.Size = UDim2.new(0, 16, 0, 16)
ResizeHandle.Text = ""
ResizeHandle.ZIndex = 10
ResizeHandle.Active = true

Instance.new("UICorner", ResizeHandle).CornerRadius = UDim.new(0, 3)

-- Duong chi thi resize (2 duong cheo nho)
local resizeLine1 = Instance.new("Frame")
resizeLine1.Parent = ResizeHandle
resizeLine1.BackgroundColor3 = C.Text2
resizeLine1.BackgroundTransparency = 0.4
resizeLine1.BorderSizePixel = 0
resizeLine1.Position = UDim2.new(0.55, 0, 0.85, 0)
resizeLine1.Size = UDim2.new(0.4, 0, 0, 1)
resizeLine1.Rotation = -45

local resizeLine2 = Instance.new("Frame")
resizeLine2.Parent = ResizeHandle
resizeLine2.BackgroundColor3 = C.Text2
resizeLine2.BackgroundTransparency = 0.4
resizeLine2.BorderSizePixel = 0
resizeLine2.Position = UDim2.new(0.3, 0, 0.6, 0)
resizeLine2.Size = UDim2.new(0.65, 0, 0, 1)
resizeLine2.Rotation = -45

-- Hover effect cho resize handle
ResizeHandle.MouseEnter:Connect(function()
    TweenService:Create(ResizeHandle, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
end)
ResizeHandle.MouseLeave:Connect(function()
    TweenService:Create(ResizeHandle, TweenInfo.new(0.1), {BackgroundTransparency = 0.2}):Play()
end)

-- =====================================================================
-- 2. HE THONG KEO THA (DRAG) + RESIZE
-- =====================================================================

local function SetupDrag(handle, target, clickFn)
    local dragging, dragInput, dragStart, startPos
    local moved = false

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if not moved and clickFn then
                        clickFn()
                    end
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if delta.Magnitude > 5 then
                moved = true
            end
            if moved then
                target.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
end

-- Keo khung chinh qua thanh tieu de
SetupDrag(TopBar, MainFrame, nil)

-- Keo nut toggle (click de mo lai cua so)
SetupDrag(ToggleBtn, ToggleBtn, function()
    IsMinimized = false
    MainFrame.Visible = true
    ToggleBtn.Visible = false
end)

-- ========== LOGIC RESIZE ==========
do
    local resizing, resizeInput, resizeStart, startSize

    ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            startSize = Vector2.new(MainFrame.Size.X.Offset, MainFrame.Size.Y.Offset)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                end
            end)
        end
    end)

    ResizeHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            resizeInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == resizeInput and resizing then
            local delta = input.Position - resizeStart
            local newW = math.clamp(startSize.X + delta.X, MIN_W, MAX_W)
            local newH = math.clamp(startSize.Y + delta.Y, MIN_H, MAX_H)
            MainFrame.Size = UDim2.new(0, newW, 0, newH)
        end
    end)
end

-- =====================================================================
-- THU NHO / PHONG TO QUA ICON
-- =====================================================================

MinBtn.MouseButton1Click:Connect(function()
    IsMinimized = true
    MainFrame.Visible = false
    ToggleBtn.Visible = true
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- =====================================================================
-- TIM KIEM REMOTE (loc theo ten)
-- =====================================================================

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local query = SearchBox.Text:lower()
    for _, child in ipairs(RemotesList:GetChildren()) do
        if child:IsA("TextButton") then
            if query == "" then
                child.Visible = true
            else
                child.Visible = child.Name:lower():find(query, 1, true) ~= nil
            end
        end
    end
end)

-- =====================================================================
-- 3. MOTEUR DE COLORATION SYNTAXIQUE SÉCURISÉ (RichText)
-- =====================================================================

local function ApplySyntaxHighlighting(codeString)
    -- Sécurisation contre les balises HTML natives de l'utilisateur
    local highlighted = codeString:gsub("<", "&lt;"):gsub(">", "&gt;")

    local colorKeyword = "#FF79C6" 
    local colorString = "#F1FA8C"  
    local colorNumber = "#BD93F9"  
    local colorMethod = "#50FA7B"  

    -- Système de Masquage : On extrait temporairement les chaînes
    -- pour éviter que des mots-clés à l'intérieur ne soient colorés.
    local tempStrings = {}
    local stringCounter = 0
    highlighted = highlighted:gsub('("[^"]*")', function(str)
        stringCounter = stringCounter + 1
        tempStrings[stringCounter] = str
        return "___STR_PLACEHOLDER_" .. stringCounter .. "___"
    end)

    -- Coloration des nombres
    highlighted = highlighted:gsub("([%s%[,=])(%d+%.?%d*)([%s%],;])", "%1<font color=\""..colorNumber.."\">%2</font>%3")
    highlighted = highlighted:gsub("^(%d+%.?%d*)([%s%],;])", "<font color=\""..colorNumber.."\">%1</font>%2")
    
    -- Coloration des méthodes clés
    highlighted = highlighted:gsub("(FireServer)", '<font color="'..colorMethod..'">%1</font>')
    highlighted = highlighted:gsub("(InvokeServer)", '<font color="'..colorMethod..'">%1</font>')

    -- Coloration des mots-clés
    local keywords = {
        "local", "function", "return", "if", "then", "else", "elseif", 
        "end", "for", "while", "do", "in", "and", "or", "not", 
        "true", "false", "nil", "unpack"
    }

    for _, kw in ipairs(keywords) do
        highlighted = highlighted:gsub("([^%a_])("..kw..")([^%a_])", "%1<font color=\""..colorKeyword.."\">%2</font>%3")
        highlighted = highlighted:gsub("^("..kw..")([^%a_])", "<font color=\""..colorKeyword.."\">%1</font>%2")
        highlighted = highlighted:gsub("([^%a_])("..kw..")$", "%1<font color=\""..colorKeyword.."\">%2</font>")
    end

    -- Restauration des chaînes avec leur propre couleur
    for i = 1, stringCounter do
        local styledString = '<font color="'..colorString..'">'..tempStrings[i]..'</font>'
        highlighted = highlighted:gsub("___STR_PLACEHOLDER_" .. i .. "___", styledString)
    end

    return highlighted
end

-- =====================================================================
-- 4. LOGIQUE DE SÉRIALISATION ET FORMATAGE DES ARGUMENTS
-- =====================================================================

local function getPathToInstance(instance)
    local path = {}
    local current = instance
    while current and current ~= game do
        table.insert(path, 1, current)
        current = current.Parent
    end
    
    local pathString = "game"
    for i, inst in ipairs(path) do
        local name = inst.Name
        if i == 1 then
            -- Récupère le service de manière propre (ex: game:GetService("ReplicatedStorage"))
            pathString = string.format("game:GetService(%q)", name)
        else
            -- Si le nom contient des caractères spéciaux, on utilise ["nom"] au lieu de .nom
            if name:match("^[a-zA-Z_][a-zA-Z0-9_]*$") then
                pathString = pathString .. "." .. name
            else
                pathString = pathString .. string.format("[%q]", name)
            end
        end
    end
    return pathString
end

-- Formateur récursif ultra complet
local function formatValue(value, depth)
    depth = depth or 0
    if depth > 8 then return '"[Table trop profonde]"' end -- Sécurité anti débordement de pile
    
    local valType = typeof(value)
    if valType == "string" then
        return string.format("%q", value)
    elseif valType == "number" then
        return tostring(value)
    elseif valType == "boolean" then
        return value and "true" or "false"
    elseif valType == "Instance" then
        return getPathToInstance(value)
    elseif valType == "Vector3" then
        return string.format("Vector3.new(%f, %f, %f)", value.X, value.Y, value.Z)
    elseif valType == "Vector2" then
        return string.format("Vector2.new(%f, %f)", value.X, value.Y)
    elseif valType == "CFrame" then
        return string.format("CFrame.new(%f, %f, %f)", value.X, value.Y, value.Z)
    elseif valType == "Color3" then
        return string.format("Color3.fromRGB(%d, %d, %d)", value.R * 255, value.G * 255, value.B * 255)
    elseif valType == "UDim2" then
        return string.format("UDim2.new(%f, %d, %f, %d)", value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
    elseif valType == "table" then
        local parts = {}
        local isArray = true
        local maxIndex = 0
        
        -- Détection automatique Table vs Tableau indexé (Array)
        for k, _ in pairs(value) do
            if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
                isArray = false
                break
            end
            if k > maxIndex then maxIndex = k end
        end
        if maxIndex ~= #value then isArray = false end

        local indent = string.rep("    ", depth + 1)
        local closingIndent = string.rep("    ", depth)

        if isArray then
            for _, val in ipairs(value) do
                table.insert(parts, formatValue(val, depth + 1))
            end
            if #parts == 0 then return "{}" end
            if #parts <= 3 then
                return "{ " .. table.concat(parts, ", ") .. " }"
            else
                return "{\n" .. indent .. table.concat(parts, ",\n" .. indent) .. "\n" .. closingIndent .. "}"
            end
        else
            for k, val in pairs(value) do
                local keyStr
                if type(k) == "string" and k:match("^[a-zA-Z_][a-zA-Z0-9_]*$") then
                    keyStr = k
                else
                    keyStr = "[" .. formatValue(k, depth + 1) .. "]"
                end
                table.insert(parts, string.format("%s = %s", keyStr, formatValue(val, depth + 1)))
            end
            if #parts == 0 then return "{}" end
            return "{\n" .. indent .. table.concat(parts, ",\n" .. indent) .. "\n" .. closingIndent .. "}"
        end
    else
        return string.format("%q", tostring(value))
    end
end

local function Format(args)
    local formattedArgs = {}
    for i, arg in ipairs(args) do
        formattedArgs[i] = string.format("[%d] = %s", i, formatValue(arg))
    end
    return formattedArgs
end

-- =====================================================================
-- 5. LOGIQUE D'AFFICHAGE ET DE FILE D'ATTENTE
-- =====================================================================

local function CreateRemoteButton(remoteName, generatedCode)
    local RemoteBtn = Instance.new("TextButton")
    RemoteBtn.Name = remoteName
    RemoteBtn.Parent = RemotesList
    RemoteBtn.BackgroundColor3 = C.SurfaceLt
    RemoteBtn.BorderSizePixel = 0
    RemoteBtn.Size = UDim2.new(1, -4, 0, 26)
    RemoteBtn.Position = UDim2.new(0, 2, 0, 0)
    RemoteBtn.Font = Enum.Font.Gotham
    RemoteBtn.Text = "  " .. remoteName
    RemoteBtn.TextColor3 = C.Text1
    RemoteBtn.TextSize = 10
    RemoteBtn.TextXAlignment = Enum.TextXAlignment.Left

    -- Cat text neu qua dai
    pcall(function() RemoteBtn.TextTruncate = Enum.TextTruncate.AtEnd end)

    Instance.new("UICorner", RemoteBtn).CornerRadius = UDim.new(0, 4)

    -- Hover effect
    RemoteBtn.MouseEnter:Connect(function()
        if selectedButton ~= RemoteBtn then
            TweenService:Create(RemoteBtn, TweenInfo.new(0.1), {BackgroundColor3 = C.Gray}):Play()
        end
    end)
    RemoteBtn.MouseLeave:Connect(function()
        if selectedButton ~= RemoteBtn then
            TweenService:Create(RemoteBtn, TweenInfo.new(0.1), {BackgroundColor3 = C.SurfaceLt}):Play()
        end
    end)

    RemoteBtn.MouseButton1Click:Connect(function()
        -- Bo chon nut truoc do
        if selectedButton and selectedButton ~= RemoteBtn then
            TweenService:Create(selectedButton, TweenInfo.new(0.1), {BackgroundColor3 = C.SurfaceLt}):Play()
        end
        -- Chon nut nay
        selectedButton = RemoteBtn
        TweenService:Create(RemoteBtn, TweenInfo.new(0.1), {BackgroundColor3 = C.Selected}):Play()

        _G.RawCode = generatedCode 
        local coloredCode = ApplySyntaxHighlighting(generatedCode)
        CodeDisplay.Text = coloredCode
    end)

    -- Cap nhat dem remote
    totalRemotes = totalRemotes + 1
    RemoteCount.Text = totalRemotes .. " remotes"

    -- Ap dung bo loc tim kiem hien tai
    local query = SearchBox.Text:lower()
    if query ~= "" then
        RemoteBtn.Visible = remoteName:lower():find(query, 1, true) ~= nil
    end
end

-- Boucle de traitement de la file d'attente (Performances améliorées)
task.spawn(function()
    while true do
        if IsCollecting and #RemoteQueue > 0 then
            if IsSlowMode then
                local eventData = table.remove(RemoteQueue, 1)
                if eventData then
                    CreateRemoteButton(eventData.Name, eventData.Code)
                end
                task.wait(5)
            else
                -- On vide toute la file de manière sécurisée sans limite fixe
                while #RemoteQueue > 0 do
                    local eventData = table.remove(RemoteQueue, 1)
                    if eventData then
                        CreateRemoteButton(eventData.Name, eventData.Code)
                    end
                end
                task.wait(0.1)
            end
        else
            task.wait(0.1)
        end
    end
end)

-- Intercepteur principal
local function handleRemote(remote)
    if remote:IsA("RemoteEvent") then
        remote.OnClientEvent:Connect(function(...)
            local args = {...}
            local argsFormatted = Format(args)
            local argsString = table.concat(argsFormatted, ",\n    ")
            local fullPath = getPathToInstance(remote)
            
            local code = string.format("local args = {\n    %s\n}\n\n%s:FireServer(unpack(args))", argsString, fullPath)
            
            if IsCollecting and #RemoteQueue < MAX_QUEUE_SIZE then
                table.insert(RemoteQueue, {Name = remote.Name, Code = code})
            end
        end)
        
    elseif remote:IsA("RemoteFunction") then
        remote.OnClientInvoke = function(...)
            local args = {...}
            local argsFormatted = Format(args)
            local argsString = table.concat(argsFormatted, ",\n    ")
            local fullPath = getPathToInstance(remote)
            
            local code = string.format("local args = {\n    %s\n}\n\nlocal response = %s:InvokeServer(unpack(args))", argsString, fullPath)
            
            if IsCollecting and #RemoteQueue < MAX_QUEUE_SIZE then
                table.insert(RemoteQueue, {Name = remote.Name, Code = code})
            end
            
            return ...
        end
    end
end

local function wrapRemotes(folder)
    for _, obj in ipairs(folder:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            handleRemote(obj)
        end
    end
    folder.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
            handleRemote(descendant)
        end
    end)
end

-- =====================================================================
-- 6. KHOI CHAY VA XU LY NUT
-- =====================================================================

local folders = {
    game:GetService("ReplicatedStorage"),
    game:GetService("StarterGui"),
    game:GetService("StarterPack"),
    game:GetService("StarterPlayer")
}

for _, folder in ipairs(folders) do
    wrapRemotes(folder)
end

-- Nut Dung / Tiep tuc thu thap
PauseButton.MouseButton1Click:Connect(function()
    IsCollecting = not IsCollecting
    if IsCollecting then
        PauseButton.Text = "Dung thu"
        PauseButton.BackgroundColor3 = C.Orange
        StatusDot.BackgroundColor3 = C.Green
        StatusLabel.Text = "Dang thu"
        StatusLabel.TextColor3 = C.Green
    else
        PauseButton.Text = "Tiep tuc"
        PauseButton.BackgroundColor3 = C.Green
        StatusDot.BackgroundColor3 = C.Orange
        StatusLabel.Text = "Da dung"
        StatusLabel.TextColor3 = C.Orange
    end
end)

-- Nut Sao chep
CopyButton.MouseButton1Click:Connect(function()
    if setclipboard then
        if _G.RawCode ~= "" then
            setclipboard(_G.RawCode)
            CopyButton.Text = "Da chep!"
            task.wait(1.5)
            CopyButton.Text = "Sao chep"
        end
    else
        warn("Executor khong ho tro setclipboard")
    end
end)

-- Nut Che do cham
SlowButton.MouseButton1Click:Connect(function()
    IsSlowMode = not IsSlowMode
    
    if IsSlowMode then
        SlowButton.Text = "Cham: BAT"
        SlowButton.BackgroundColor3 = C.Orange
    else
        SlowButton.Text = "Cham: TAT"
        SlowButton.BackgroundColor3 = C.Gray
    end
end)

-- Nut Xoa het
ClearButton.MouseButton1Click:Connect(function()
    RemoteQueue = {}
    selectedButton = nil
    totalRemotes = 0
    RemoteCount.Text = "0 remotes"
    
    for _, child in pairs(RemotesList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    CodeDisplay.Text = '<font color="#7A828B">-- Cho su kien...\n-- Ma nguon se hien thi o day.</font>'
    _G.RawCode = ""
end)

print("CENIROSO SPY V1.8 - Giao dien mobile da tai thanh cong!")
