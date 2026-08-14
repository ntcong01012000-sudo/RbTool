-- Prevent multiple instances
if getgenv().AntigravitySpyLoaded then
    local oldGui = game:GetService("CoreGui"):FindFirstChild("AntigravityRemoteSpy") or game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("AntigravityRemoteSpy")
    if oldGui then
        oldGui:Destroy()
    end
    getgenv().AntigravitySpyLoaded = nil
    task.wait(0.1)
end
getgenv().AntigravitySpyLoaded = true

-- Services
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- Parent GUI finder
local parentGui = nil
local success, err = pcall(function()
    parentGui = game:GetService("CoreGui")
end)
if not success or not parentGui then
    parentGui = Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- Core States
local IsRecording = true
local FilterCurrentUser = true
local logs = {}
local logButtons = {}
local logOrder = {}
local maxLogs = 150
local currentSelectedLog = nil
local connections = {}
local originalFireServer = nil
local originalInvokeServer = nil
local originalNewIndex = nil
local originalNamecall = nil
local UiScale = nil

-- UI Colors & Theme
local Theme = {
    BgMain = Color3.fromRGB(24, 25, 33),
    BgSidebar = Color3.fromRGB(18, 19, 26),
    BgHeader = Color3.fromRGB(30, 31, 41),
    BgCode = Color3.fromRGB(14, 15, 20),
    TextPrimary = Color3.fromRGB(240, 240, 245),
    TextSecondary = Color3.fromRGB(150, 155, 175),
    AccentBlue = Color3.fromRGB(75, 120, 255),
    AccentBlueHover = Color3.fromRGB(95, 140, 255),
    AccentGreen = Color3.fromRGB(46, 204, 113),
    AccentGreenHover = Color3.fromRGB(66, 224, 133),
    AccentRed = Color3.fromRGB(231, 76, 60),
    AccentRedHover = Color3.fromRGB(251, 96, 80),
    AccentGrey = Color3.fromRGB(60, 62, 74),
    AccentGreyHover = Color3.fromRGB(80, 82, 94),
    AccentOrange = Color3.fromRGB(220, 120, 30),
    AccentOrangeHover = Color3.fromRGB(240, 140, 50)
}

-- UI States
local buttonStates = {}

-- =====================================================================
-- UTILITY FUNCTIONS
-- =====================================================================

local function addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
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
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function getPath(instance)
    if not instance or not instance.Parent then
        return "nil --[[ Instance parented to nil ]]"
    end
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
            pathString = 'game:GetService("' .. name .. '")'
        else
            if name:match("^[a-zA-Z_][a-zA-Z0-9_]*$") then
                pathString = pathString .. "." .. name
            else
                pathString = pathString .. '["' .. name:gsub('"', '\\"') .. '"]'
            end
        end
    end
    return pathString
end

local function formatVal(value, depth)
    depth = depth or 0
    if depth > 10 then return '"[Table too deep]"' end
    
    local t = typeof(value)
    if t == "string" then
        return '"' .. value:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n') .. '"'
    elseif t == "number" then
        if value == math.floor(value) then
            return tostring(value)
        else
            return string.format("%.4f", value):gsub("%.?0+$", "")
        end
    elseif t == "boolean" then
        return tostring(value)
    elseif t == "nil" then
        return "nil"
    elseif t == "Instance" then
        return getPath(value)
    elseif t == "Vector3" then
        return string.format("Vector3.new(%.3f, %.3f, %.3f)", value.X, value.Y, value.Z):gsub("%.000", "")
    elseif t == "Vector2" then
        return string.format("Vector2.new(%.3f, %.3f)", value.X, value.Y):gsub("%.000", "")
    elseif t == "CFrame" then
        return "CFrame.new(" .. tostring(value) .. ")"
    elseif t == "Color3" then
        return string.format("Color3.fromRGB(%d, %d, %d)", math.round(value.R * 255), math.round(value.G * 255), math.round(value.B * 255))
    elseif t == "UDim2" then
        return string.format("UDim2.new(%f, %d, %f, %d)", value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
    elseif t == "UDim" then
        return string.format("UDim.new(%f, %d)", value.Scale, value.Offset)
    elseif t == "BrickColor" then
        return string.format("BrickColor.new(%q)", value.Name)
    elseif t == "EnumItem" then
        return tostring(value)
    elseif t == "ColorSequence" then
        return "ColorSequence.new(" .. formatVal(value.Keypoints, depth + 1) .. ")"
    elseif t == "NumberSequence" then
        return "NumberSequence.new(" .. formatVal(value.Keypoints, depth + 1) .. ")"
    elseif t == "NumberRange" then
        return string.format("NumberRange.new(%f, %f)", value.Min, value.Max)
    elseif t == "Rect" then
        return string.format("Rect.new(%f, %f, %f, %f)", value.Min.X, value.Min.Y, value.Max.X, value.Max.Y)
    elseif t == "table" then
        local isArray = true
        local maxIdx = 0
        local count = 0
        for k, v in pairs(value) do
            count = count + 1
            if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
                isArray = false
                break
            end
            if k > maxIdx then maxIdx = k end
        end
        if isArray and maxIdx ~= count then
            isArray = false
        end
        
        local parts = {}
        local indent = string.rep("  ", depth + 1)
        local closingIndent = string.rep("  ", depth)
        
        if isArray then
            for i = 1, #value do
                table.insert(parts, formatVal(value[i], depth + 1))
            end
            if #parts == 0 then return "{}" end
            if #parts <= 3 then
                return "{ " .. table.concat(parts, ", ") .. " }"
            else
                return "{\n" .. indent .. table.concat(parts, ",\n" .. indent) .. "\n" .. closingIndent .. "}"
            end
        else
            for k, v in pairs(value) do
                local keyStr
                if type(k) == "string" and k:match("^[a-zA-Z_][a-zA-Z0-9_]*$") then
                    keyStr = k
                else
                    keyStr = "[" .. formatVal(k, depth + 1) .. "]"
                end
                table.insert(parts, keyStr .. " = " .. formatVal(v, depth + 1))
            end
            if #parts == 0 then return "{}" end
            return "{\n" .. indent .. table.concat(parts, ",\n" .. indent) .. "\n" .. closingIndent .. "}"
        end
    else
        return '"[' .. tostring(t) .. ': ' .. tostring(value) .. ']"'
    end
end

-- Custom Lua Syntax Highlighter
local function Highlight(code)
    if not code or code == "" then return "" end
    local escaped = code:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
    
    -- 1. Mask comments
    local comments = {}
    local commCount = 0
    escaped = escaped:gsub("(%-%-[^\n]*)", function(c)
        commCount = commCount + 1
        comments[commCount] = '<font color="#6272a4">' .. c .. '</font>'
        return "___COMM_" .. commCount .. "___"
    end)
    
    -- 2. Mask strings (double quoted)
    local strings = {}
    local strCount = 0
    escaped = escaped:gsub('("[^"\\]*(?:\\.[^"\\]*)*")', function(s)
        strCount = strCount + 1
        strings[strCount] = '<font color="#f1fa8c">' .. s .. '</font>'
        return "___STR_" .. strCount .. "___"
    end)
    -- Mask strings (single quoted)
    escaped = escaped:gsub("('[^'\\]*(?:\\.[^'\\]*)*')", function(s)
        strCount = strCount + 1
        strings[strCount] = '<font color="#f1fa8c">' .. s .. '</font>'
        return "___STR_" .. strCount .. "___"
    end)
    
    -- 3. Highlight keywords (using frontier patterns)
    local keywords = {
        "local", "function", "return", "if", "then", "else", "elseif", "end",
        "for", "while", "do", "in", "and", "or", "not", "true", "false", "nil"
    }
    for _, kw in ipairs(keywords) do
        escaped = escaped:gsub("%f[%a]" .. kw .. "%f[%A]", '<font color="#ff79c6">' .. kw .. '</font>')
    end
    
    -- 4. Highlight Roblox methods
    local methods = {"FireServer", "InvokeServer", "OnClientEvent", "OnClientInvoke", "GetService", "FindFirstChild", "WaitForChild"}
    for _, m in ipairs(methods) do
        escaped = escaped:gsub("%f[%a]" .. m .. "%f[%A]", '<font color="#50fa7b">' .. m .. '</font>')
    end
    
    -- 5. Highlight numbers
    escaped = escaped:gsub("%f[%d]%d+%.?%d*%f[%D]", '<font color="#bd93f9">%1</font>')
    
    -- 6. Restore strings safely using functions to avoid escape character issues
    for i = 1, strCount do
        escaped = escaped:gsub("___STR_" .. i .. "___", function() return strings[i] end)
    end
    
    -- 7. Restore comments
    for i = 1, commCount do
        escaped = escaped:gsub("___COMM_" .. i .. "___", function() return comments[i] end)
    end
    
    return escaped
end

-- Check if remote call involves LocalPlayer
local function isRelatedToLocalPlayer(remote, args)
    local LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then return true end
    
    local char = LocalPlayer.Character
    if remote:IsDescendantOf(LocalPlayer) or (char and remote:IsDescendantOf(char)) then
        return true
    end
    
    if string.find(string.lower(remote.Name), string.lower(LocalPlayer.Name), 1, true) then
        return true
    end
    
    local function checkValue(val, depth)
        depth = depth or 0
        if depth > 5 then return false end
        
        if typeof(val) == "Instance" then
            local char = LocalPlayer.Character
            if val == LocalPlayer or val:IsDescendantOf(LocalPlayer) or (char and (val == char or val:IsDescendantOf(char))) then
                return true
            end
        elseif type(val) == "string" then
            if val == LocalPlayer.Name or string.find(val, LocalPlayer.Name, 1, true) then
                return true
            end
        elseif type(val) == "number" then
            if val == LocalPlayer.UserId then
                return true
            end
        elseif type(val) == "table" then
            for k, v in pairs(val) do
                if checkValue(k, depth + 1) or checkValue(v, depth + 1) then
                    return true
                end
            end
        end
        return false
    end
    
    return checkValue(args)
end

-- =====================================================================
-- UI CREATION
-- =====================================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AntigravityRemoteSpy"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = parentGui

-- Floating Minimize Button
local FloatingIcon = Instance.new("TextButton")
FloatingIcon.Name = "FloatingIcon"
FloatingIcon.Size = UDim2.new(0, 48, 0, 48)
FloatingIcon.Position = UDim2.new(0, 30, 0.4, 0)
FloatingIcon.BackgroundColor3 = Theme.AccentBlue
FloatingIcon.BorderSizePixel = 0
FloatingIcon.Text = "👁"
FloatingIcon.TextColor3 = Theme.TextPrimary
FloatingIcon.Font = Enum.Font.GothamBold
FloatingIcon.TextSize = 22
FloatingIcon.Visible = false
addCorner(FloatingIcon, 24)
FloatingIcon.Parent = ScreenGui

local FloatingStroke = Instance.new("UIStroke")
FloatingStroke.Color = Color3.fromRGB(45, 47, 57)
FloatingStroke.Thickness = 1.5
FloatingStroke.Parent = FloatingIcon

-- Main Window
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 680, 0, 420)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = Theme.BgMain
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = true
addCorner(MainFrame, 8)
MainFrame.Parent = ScreenGui

-- UI Scale for premium animations
UiScale = Instance.new("UIScale")
UiScale.Scale = 1
UiScale.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 47, 57)
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

-- Top Bar Header
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Theme.BgHeader
TopBar.BorderSizePixel = 0
addCorner(TopBar, 8)
TopBar.Parent = MainFrame

-- Hide bottom corners of TopBar
local TopBarHider = Instance.new("Frame")
TopBarHider.Size = UDim2.new(1, 0, 0, 8)
TopBarHider.Position = UDim2.new(0, 0, 1, -8)
TopBarHider.BackgroundColor3 = Theme.BgHeader
TopBarHider.BorderSizePixel = 0
TopBarHider.Parent = TopBar

local TopBarDivider = Instance.new("Frame")
TopBarDivider.Size = UDim2.new(1, 0, 0, 1)
TopBarDivider.Position = UDim2.new(0, 0, 1, 0)
TopBarDivider.BackgroundColor3 = Color3.fromRGB(45, 47, 57)
TopBarDivider.BorderSizePixel = 0
TopBarDivider.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Text = "  🕵️ Antigravity Remote Spy"
Title.Size = UDim2.new(0.6, 0, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Theme.TextPrimary
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local HeaderButtons = Instance.new("Frame")
HeaderButtons.Size = UDim2.new(0, 80, 1, 0)
HeaderButtons.Position = UDim2.new(1, -85, 0, 0)
HeaderButtons.BackgroundTransparency = 1
HeaderButtons.Parent = TopBar

local HeaderLayout = Instance.new("UIListLayout")
HeaderLayout.FillDirection = Enum.FillDirection.Horizontal
HeaderLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
HeaderLayout.VerticalAlignment = Enum.VerticalAlignment.Center
HeaderLayout.Padding = UDim.new(0, 8)
HeaderLayout.Parent = HeaderButtons

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Text = "➖"
MinimizeBtn.Size = UDim2.new(0, 24, 0, 24)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextColor3 = Theme.TextSecondary
MinimizeBtn.TextSize = 12
MinimizeBtn.Parent = HeaderButtons

local ShutdownBtn = Instance.new("TextButton")
ShutdownBtn.Name = "ShutdownBtn"
ShutdownBtn.Text = "❌"
ShutdownBtn.Size = UDim2.new(0, 24, 0, 24)
ShutdownBtn.BackgroundTransparency = 1
ShutdownBtn.Font = Enum.Font.GothamBold
ShutdownBtn.TextColor3 = Theme.TextSecondary
ShutdownBtn.TextSize = 12
ShutdownBtn.Parent = HeaderButtons

-- Left Sidebar Card (Remote List)
local LeftCard = Instance.new("Frame")
LeftCard.Name = "LeftCard"
LeftCard.Position = UDim2.new(0, 10, 0, 50)
LeftCard.Size = UDim2.new(0, 200, 1, -60)
LeftCard.BackgroundColor3 = Theme.BgSidebar
LeftCard.BorderSizePixel = 0
addCorner(LeftCard, 6)
LeftCard.Parent = MainFrame

local LeftStroke = Instance.new("UIStroke")
LeftStroke.Color = Color3.fromRGB(38, 40, 50)
LeftStroke.Thickness = 1
LeftStroke.Parent = LeftCard

local SearchBar = Instance.new("TextBox")
SearchBar.Name = "SearchBar"
SearchBar.Size = UDim2.new(1, -16, 0, 30)
SearchBar.Position = UDim2.new(0, 8, 0, 8)
SearchBar.BackgroundColor3 = Theme.BgMain
SearchBar.BorderSizePixel = 0
SearchBar.PlaceholderText = "🔍 Search remotes..."
SearchBar.PlaceholderColor3 = Theme.TextSecondary
SearchBar.TextColor3 = Theme.TextPrimary
SearchBar.Text = ""
SearchBar.Font = Enum.Font.GothamMedium
SearchBar.TextSize = 11
SearchBar.ClearTextOnFocus = true
addCorner(SearchBar, 4)
SearchBar.Parent = LeftCard

local SearchPadding = Instance.new("UIPadding")
SearchPadding.PaddingLeft = UDim.new(0, 8)
SearchPadding.Parent = SearchBar

local SearchStroke = Instance.new("UIStroke")
SearchStroke.Color = Color3.fromRGB(45, 47, 57)
SearchStroke.Thickness = 1
SearchStroke.Parent = SearchBar

local LogList = Instance.new("ScrollingFrame")
LogList.Name = "LogList"
LogList.Size = UDim2.new(1, -16, 1, -54)
LogList.Position = UDim2.new(0, 8, 0, 46)
LogList.BackgroundTransparency = 1
LogList.BorderSizePixel = 0
LogList.ScrollBarThickness = 4
LogList.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 85)
LogList.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
LogList.CanvasSize = UDim2.new(0, 0, 0, 0)
LogList.Parent = LeftCard

local LogListLayout = Instance.new("UIListLayout")
LogListLayout.SortOrder = Enum.SortOrder.LayoutOrder
LogListLayout.Padding = UDim.new(0, 5)
LogListLayout.Parent = LogList

-- Right Detail Panel Card
local RightCard = Instance.new("Frame")
RightCard.Name = "RightCard"
RightCard.Position = UDim2.new(0, 220, 0, 50)
RightCard.Size = UDim2.new(1, -230, 1, -60)
RightCard.BackgroundColor3 = Theme.BgSidebar
RightCard.BorderSizePixel = 0
addCorner(RightCard, 6)
RightCard.Parent = MainFrame

local RightStroke = Instance.new("UIStroke")
RightStroke.Color = Color3.fromRGB(38, 40, 50)
RightStroke.Thickness = 1
RightStroke.Parent = RightCard

-- Detail Header
local SelectedRemoteLabel = Instance.new("TextLabel")
SelectedRemoteLabel.Name = "SelectedRemoteLabel"
SelectedRemoteLabel.Text = "No remote selected"
SelectedRemoteLabel.Size = UDim2.new(1, -16, 0, 18)
SelectedRemoteLabel.Position = UDim2.new(0, 8, 0, 8)
SelectedRemoteLabel.BackgroundTransparency = 1
SelectedRemoteLabel.Font = Enum.Font.GothamBold
SelectedRemoteLabel.TextColor3 = Theme.TextPrimary
SelectedRemoteLabel.TextSize = 12
SelectedRemoteLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectedRemoteLabel.TextTruncate = Enum.TextTruncate.AtEnd
SelectedRemoteLabel.Parent = RightCard

local SelectedMethodLabel = Instance.new("TextLabel")
SelectedMethodLabel.Name = "SelectedMethodLabel"
SelectedMethodLabel.Text = "Select a remote from the sidebar to inspect details"
SelectedMethodLabel.Size = UDim2.new(1, -16, 0, 14)
SelectedMethodLabel.Position = UDim2.new(0, 8, 0, 26)
SelectedMethodLabel.BackgroundTransparency = 1
SelectedMethodLabel.Font = Enum.Font.GothamMedium
SelectedMethodLabel.TextColor3 = Theme.TextSecondary
SelectedMethodLabel.TextSize = 10
SelectedMethodLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectedMethodLabel.Parent = RightCard

-- Code Scroll Panel
local CodeScroll = Instance.new("ScrollingFrame")
CodeScroll.Name = "CodeScroll"
CodeScroll.Position = UDim2.new(0, 8, 0, 48)
CodeScroll.Size = UDim2.new(1, -16, 1, -95)
CodeScroll.BackgroundColor3 = Theme.BgCode
CodeScroll.BorderSizePixel = 0
CodeScroll.ScrollBarThickness = 4
CodeScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 85)
CodeScroll.AutomaticCanvasSize = Enum.AutomaticCanvasSize.XY
CodeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
addCorner(CodeScroll, 4)
CodeScroll.Parent = RightCard

local CodeScrollStroke = Instance.new("UIStroke")
CodeScrollStroke.Color = Color3.fromRGB(30, 32, 42)
CodeScrollStroke.Thickness = 1
CodeScrollStroke.Parent = CodeScroll

local CodeBox = Instance.new("TextBox")
CodeBox.Name = "CodeBox"
CodeBox.Size = UDim2.new(1, 0, 1, 0)
CodeBox.BackgroundTransparency = 1
CodeBox.ClearTextOnFocus = false
CodeBox.MultiLine = true
CodeBox.TextEditable = false
CodeBox.RichText = true
CodeBox.Font = Enum.Font.Code
CodeBox.TextSize = 11
CodeBox.TextColor3 = Theme.TextPrimary
CodeBox.TextXAlignment = Enum.TextXAlignment.Left
CodeBox.TextYAlignment = Enum.TextYAlignment.Top
CodeBox.TextWrapped = false
CodeBox.AutomaticSize = Enum.AutomaticSize.XY
CodeBox.Text = ""
CodeBox.Parent = CodeScroll

local CodePadding = Instance.new("UIPadding")
CodePadding.PaddingLeft = UDim.new(0, 8)
CodePadding.PaddingTop = UDim.new(0, 8)
CodePadding.Parent = CodeBox

-- Button Bar (Footer of Right Card)
local ButtonBar = Instance.new("Frame")
ButtonBar.Name = "ButtonBar"
ButtonBar.Position = UDim2.new(0, 8, 1, -38)
ButtonBar.Size = UDim2.new(1, -16, 0, 30)
ButtonBar.BackgroundTransparency = 1
ButtonBar.Parent = RightCard

local ButtonBarLayout = Instance.new("UIListLayout")
ButtonBarLayout.FillDirection = Enum.FillDirection.Horizontal
ButtonBarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ButtonBarLayout.Padding = UDim.new(0, 6)
ButtonBarLayout.Parent = ButtonBar

-- Create buttons in ButtonBar
local function registerButtonHover(btn)
    btn.MouseEnter:Connect(function()
        local state = buttonStates[btn]
        if state then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = state.hover}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        local state = buttonStates[btn]
        if state then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = state.normal}):Play()
        end
    end)
end

local function setButtonState(btn, text, normalColor, hoverColor)
    btn.Text = text
    btn.BackgroundColor3 = normalColor
    buttonStates[btn] = {normal = normalColor, hover = hoverColor}
end

local function createBarButton(name, text, normalColor, hoverColor)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0.2, -5, 1, 0)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    addCorner(btn, 4)
    btn.Parent = ButtonBar
    
    setButtonState(btn, text, normalColor, hoverColor)
    registerButtonHover(btn)
    return btn
end

local CopyBtn = createBarButton("CopyBtn", "Copy", Theme.AccentBlue, Theme.AccentBlueHover)
local ExecBtn = createBarButton("ExecBtn", "Execute", Theme.AccentGreen, Theme.AccentGreenHover)
local ClearBtn = createBarButton("ClearBtn", "Clear", Theme.AccentGrey, Theme.AccentGreyHover)
local RecordBtn = createBarButton("RecordBtn", "Recording", Theme.AccentGreen, Theme.AccentGreenHover)
local FilterBtn = createBarButton("FilterBtn", "User Only", Theme.AccentBlue, Theme.AccentBlueHover)

-- Dragging behavior
makeDraggable(MainFrame, TopBar)

-- Header Button Hover Effects
local function addTextHover(btn, normalColor, hoverColor)
    btn.MouseEnter:Connect(function()
        btn.TextColor3 = hoverColor
    end)
    btn.MouseLeave:Connect(function()
        btn.TextColor3 = normalColor
    end)
end
addTextHover(MinimizeBtn, Theme.TextSecondary, Theme.TextPrimary)
addTextHover(ShutdownBtn, Theme.TextSecondary, Theme.AccentRed)

-- Initialize code display
CodeBox.Text = Highlight("-- Waiting for remotes...\n-- Click any remote in the list to view its code and execute it.")

-- =====================================================================
-- LOGGING & INTERCEPTION SYSTEM
-- =====================================================================

local function updateLogUI(log)
    local btn = logButtons[log.Sig]
    if btn then
        local infoLabel = btn:FindFirstChild("InfoLabel")
        if infoLabel then
            infoLabel.Text = log.Method .. "  •  x" .. log.Count
        end
        btn.LayoutOrder = -log.Timestamp
    else
        btn = Instance.new("TextButton")
        btn.Name = log.Name
        btn.Size = UDim2.new(1, -8, 0, 38)
        btn.BackgroundColor3 = Color3.fromRGB(28, 29, 37)
        btn.BorderSizePixel = 0
        btn.LayoutOrder = -log.Timestamp
        addCorner(btn, 4)
        
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(38, 40, 50)
        btnStroke.Thickness = 1
        btnStroke.Parent = btn
        
        local accent = Instance.new("Frame")
        accent.Size = UDim2.new(0, 4, 1, 0)
        accent.BorderSizePixel = 0
        local isEvent = (log.Method == "FireServer" or log.Method == "OnClientEvent")
        accent.BackgroundColor3 = (isEvent and Theme.AccentBlue or Theme.AccentOrange)
        addCorner(accent, 4)
        accent.Parent = btn
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Text = " " .. log.Name
        nameLabel.Size = UDim2.new(1, -50, 0, 18)
        nameLabel.Position = UDim2.new(0, 8, 0, 3)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 11
        nameLabel.TextColor3 = Theme.TextPrimary
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = btn
        
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Name = "InfoLabel"
        infoLabel.Text = log.Method .. "  •  x" .. log.Count
        infoLabel.Size = UDim2.new(1, -50, 0, 14)
        infoLabel.Position = UDim2.new(0, 8, 0, 20)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Font = Enum.Font.GothamMedium
        infoLabel.TextSize = 9
        infoLabel.TextColor3 = Theme.TextSecondary
        infoLabel.TextXAlignment = Enum.TextXAlignment.Left
        infoLabel.Parent = btn
        
        local badge = Instance.new("TextLabel")
        badge.Name = "Badge"
        badge.Size = UDim2.new(0, 32, 0, 16)
        badge.Position = UDim2.new(1, -38, 0.5, -8)
        local isOut = (log.Method == "FireServer" or log.Method == "InvokeServer")
        badge.Text = isOut and "OUT" or "IN"
        badge.BackgroundColor3 = isOut and Theme.AccentBlue or Theme.AccentRed
        badge.TextColor3 = Color3.fromRGB(255, 255, 255)
        badge.Font = Enum.Font.GothamBold
        badge.TextSize = 8
        badge.TextAlignment = Enum.TextXAlignment.Center
        addCorner(badge, 3)
        badge.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            for _, b in pairs(logButtons) do
                b.BackgroundColor3 = Color3.fromRGB(28, 29, 37)
            end
            btn.BackgroundColor3 = Color3.fromRGB(45, 47, 57)
            
            currentSelectedLog = log
            SelectedRemoteLabel.Text = log.Path
            SelectedMethodLabel.Text = log.Method
            CodeBox.Text = Highlight(log.Code)
        end)
        
        btn.Parent = LogList
        logButtons[log.Sig] = btn
    end
end

local function addLog(log)
    if logButtons[log.Sig] then
        log.Count = log.Count + 1
        log.Timestamp = os.time()
        updateLogUI(log)
        
        for i, sig in ipairs(logOrder) do
            if sig == log.Sig then
                table.remove(logOrder, i)
                break
            end
        end
        table.insert(logOrder, log.Sig)
    else
        if #logOrder >= maxLogs then
            local oldestSig = table.remove(logOrder, 1)
            local oldestLog = logs[oldestSig]
            if oldestLog then
                logs[oldestSig] = nil
                if logButtons[oldestSig] then
                    logButtons[oldestSig]:Destroy()
                    logButtons[oldestSig] = nil
                end
            end
        end
        
        logs[log.Sig] = log
        table.insert(logOrder, log.Sig)
        updateLogUI(log)
    end
end

local function handleRemoteCall(remote, method, args)
    if not IsRecording then return end
    
    -- Filter current user related remotes
    if FilterCurrentUser then
        local isIncoming = (method == "OnClientEvent" or method == "OnClientInvoke")
        if isIncoming and not isRelatedToLocalPlayer(remote, args) then
            return
        end
    end
    
    local name = remote.Name
    local path = getPath(remote)
    
    local code = ""
    local argsFormatted = {}
    for i, arg in ipairs(args) do
        argsFormatted[i] = string.format("[%d] = %s", i, formatVal(arg))
    end
    local argsString = table.concat(argsFormatted, ",\n  ")
    
    if method == "FireServer" then
        code = string.format("-- Outgoing Event\nlocal remote = %s\nlocal args = {\n  %s\n}\nremote:FireServer(unpack(args))", path, argsString)
    elseif method == "InvokeServer" then
        code = string.format("-- Outgoing Function\nlocal remote = %s\nlocal args = {\n  %s\n}\nlocal result = remote:InvokeServer(unpack(args))", path, argsString)
    elseif method == "OnClientEvent" then
        code = string.format("-- Incoming Event (From Server)\nlocal remote = %s\nlocal args = {\n  %s\n}\n-- Fired to Client. Simulating locally:\n-- remote:FireClient(game.Players.LocalPlayer, unpack(args))", path, argsString)
    elseif method == "OnClientInvoke" then
        code = string.format("-- Incoming Function (From Server)\nlocal remote = %s\nlocal args = {\n  %s\n}", path, argsString)
    end
    
    local sig = path .. "|" .. method .. "|" .. formatVal(args)
    
    addLog({
        Sig = sig,
        Name = name,
        Path = path,
        Method = method,
        Args = args,
        Code = code,
        Count = 1,
        Timestamp = os.time()
    })
end

-- =====================================================================
-- HOOKING LOGIC
-- =====================================================================

local function setupIncomingEvent(remote)
    if not remote:IsA("RemoteEvent") then return end
    local conn = remote.OnClientEvent:Connect(function(...)
        local args = {...}
        if not getgenv().AntigravitySpyLoaded then return end
        task.spawn(function()
            handleRemoteCall(remote, "OnClientEvent", args)
        end)
    end)
    table.insert(connections, conn)
end

local function wrapExistingOnClientInvoke(remote)
    if not remote:IsA("RemoteFunction") then return end
    local existing = remote.OnClientInvoke
    if existing and type(existing) == "function" then
        remote.OnClientInvoke = function(...)
            local args = {...}
            task.spawn(function()
                if getgenv().AntigravitySpyLoaded then
                    handleRemoteCall(remote, "OnClientInvoke", args)
                end
            end)
            return existing(...)
        end
    end
end

local function scanAndHook(serviceName)
    local success, service = pcall(function()
        return game:GetService(serviceName)
    end)
    if success and service then
        for _, descendant in ipairs(service:GetDescendants()) do
            if descendant:IsA("RemoteEvent") then
                setupIncomingEvent(descendant)
            elseif descendant:IsA("RemoteFunction") then
                wrapExistingOnClientInvoke(descendant)
            end
        end
        
        local conn = service.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("RemoteEvent") then
                setupIncomingEvent(descendant)
            elseif descendant:IsA("RemoteFunction") then
                wrapExistingOnClientInvoke(descendant)
            end
        end)
        table.insert(connections, conn)
    end
end

local function initHooks()
    -- 1. Hook outgoing calls using __namecall (Always preferred for :FireServer and :InvokeServer)
    if hookmetamethod then
        pcall(function()
            originalNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                if getgenv().AntigravitySpyLoaded and typeof(self) == "Instance" then
                    if method == "FireServer" or method == "fireServer" then
                        task.spawn(function()
                            handleRemoteCall(self, "FireServer", args)
                        end)
                    elseif method == "InvokeServer" or method == "invokeServer" then
                        task.spawn(function()
                            handleRemoteCall(self, "InvokeServer", args)
                        end)
                    end
                end
                return originalNamecall(self, ...)
            end))
        end)
    end
    
    -- 2. Hook function calls directly using hookfunction (Fallback for dot-syntax calls)
    if hookfunction then
        pcall(function()
            originalFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, newcclosure(function(self, ...)
                local args = {...}
                if getgenv().AntigravitySpyLoaded then
                    task.spawn(function()
                        handleRemoteCall(self, "FireServer", args)
                    end)
                end
                return originalFireServer(self, ...)
            end))
        end)
        
        pcall(function()
            originalInvokeServer = hookfunction(Instance.new("RemoteFunction").InvokeServer, newcclosure(function(self, ...)
                local args = {...}
                if getgenv().AntigravitySpyLoaded then
                    task.spawn(function()
                        handleRemoteCall(self, "InvokeServer", args)
                    end)
                end
                return originalInvokeServer(self, ...)
            end))
        end)
    end
    
    -- 3. Hook __newindex for OnClientInvoke
    if hookmetamethod then
        pcall(function()
            originalNewIndex = hookmetamethod(game, "__newindex", newcclosure(function(self, key, value)
                if getgenv().AntigravitySpyLoaded and typeof(self) == "Instance" and self:IsA("RemoteFunction") and key == "OnClientInvoke" then
                    local originalFunc = value
                    local wrappedFunc = function(...)
                        local args = {...}
                        task.spawn(function()
                            if getgenv().AntigravitySpyLoaded then
                                handleRemoteCall(self, "OnClientInvoke", args)
                            end
                        end)
                        if type(originalFunc) == "function" then
                            return originalFunc(...)
                        end
                    end
                    return originalNewIndex(self, key, wrappedFunc)
                end
                return originalNewIndex(self, key, value)
            end))
        end)
    end
end

-- =====================================================================
-- CONTROL BUTTON EVENTS
-- =====================================================================

-- Search Bar Event
SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
    local query = string.lower(SearchBar.Text)
    for _, btn in ipairs(LogList:GetChildren()) do
        if btn:IsA("TextButton") then
            if query == "" or string.find(string.lower(btn.Name), query, 1, true) then
                btn.Visible = true
            else
                btn.Visible = false
            end
        end
    end
end)

-- Copy Button
CopyBtn.MouseButton1Click:Connect(function()
    if not currentSelectedLog then return end
    if setclipboard then
        setclipboard(currentSelectedLog.Code)
        CopyBtn.Text = "Copied!"
        task.wait(1)
        CopyBtn.Text = "Copy"
    else
        warn("Executor does not support setclipboard")
    end
end)

-- Execute Button
ExecBtn.MouseButton1Click:Connect(function()
    if not currentSelectedLog then return end
    local func, err = loadstring(currentSelectedLog.Code)
    if func then
        task.spawn(func)
        ExecBtn.Text = "Executed!"
        task.wait(1)
        ExecBtn.Text = "Execute"
    else
        warn("Execution error: " .. tostring(err))
    end
end)

-- Clear Button
ClearBtn.MouseButton1Click:Connect(function()
    logs = {}
    logOrder = {}
    for _, btn in pairs(logButtons) do
        btn:Destroy()
    end
    logButtons = {}
    currentSelectedLog = nil
    SelectedRemoteLabel.Text = "No remote selected"
    SelectedMethodLabel.Text = "Select a remote from the sidebar to inspect details"
    CodeBox.Text = Highlight("-- Waiting for remotes...\n-- Click any remote in the list to view its code and execute it.")
    
    ClearBtn.Text = "Cleared!"
    task.wait(0.8)
    ClearBtn.Text = "Clear"
end)

-- Record Button
RecordBtn.MouseButton1Click:Connect(function()
    IsRecording = not IsRecording
    if IsRecording then
        setButtonState(RecordBtn, "Recording", Theme.AccentGreen, Theme.AccentGreenHover)
    else
        setButtonState(RecordBtn, "Paused", Theme.AccentGrey, Theme.AccentGreyHover)
    end
end)

-- Filter Button
FilterBtn.MouseButton1Click:Connect(function()
    FilterCurrentUser = not FilterCurrentUser
    if FilterCurrentUser then
        setButtonState(FilterBtn, "User Only", Theme.AccentBlue, Theme.AccentBlueHover)
    else
        setButtonState(FilterBtn, "All Remotes", Theme.AccentOrange, Theme.AccentOrangeHover)
    end
end)

-- Minimize Event
MinimizeBtn.MouseButton1Click:Connect(function()
    local tween = TweenService:Create(UiScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0})
    tween.Completed:Connect(function()
        MainFrame.Visible = false
        FloatingIcon.Visible = true
    end)
    tween:Play()
end)

-- Draggable click handler for FloatingIcon
local dragStartPos = nil
local isDragging = false

FloatingIcon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragStartPos = input.Position
        isDragging = false
    end
end)

FloatingIcon.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragStartPos then
            local delta = (input.Position - dragStartPos).Magnitude
            if delta > 5 then
                isDragging = true
            end
        end
    end
end)

FloatingIcon.MouseButton1Click:Connect(function()
    if isDragging then return end
    FloatingIcon.Visible = false
    MainFrame.Visible = true
    UiScale.Scale = 0
    local tween = TweenService:Create(UiScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
    tween:Play()
end)

-- Shutdown Function
local function shutdownSpy()
    getgenv().AntigravitySpyLoaded = nil
    
    -- Disconnect all events
    for _, conn in ipairs(connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(connections)
    
    -- Restore hooked functions
    pcall(function()
        if originalFireServer then
            hookfunction(Instance.new("RemoteEvent").FireServer, originalFireServer)
        end
    end)
    pcall(function()
        if originalInvokeServer then
            hookfunction(Instance.new("RemoteFunction").InvokeServer, originalInvokeServer)
        end
    end)
    
    -- Clean up UI
    if ScreenGui then
        ScreenGui:Destroy()
    end
    
    print("---------------------------------------------")
    print("Antigravity Remote Spy completely unloaded.")
    print("---------------------------------------------")
end

ShutdownBtn.MouseButton1Click:Connect(shutdownSpy)

-- =====================================================================
-- INITIALIZATION
-- =====================================================================

-- Hook Services
initHooks()

-- Scan existing descendants and listen for new ones
local targetServices = {"ReplicatedStorage", "StarterGui", "StarterPack", "StarterPlayer", "Workspace", "Players"}
for _, serviceName in ipairs(targetServices) do
    scanAndHook(serviceName)
end

-- Clear UI states when closed
ScreenGui.Destroying:Connect(function()
    getgenv().AntigravitySpyLoaded = nil
end)

print("==============================================")
print("  ANTIGRAVITY REMOTE SPY LOADED SUCCESSFULLY  ")
print("==============================================")
print("- Default: Logs current user remotes only.")
print("- Toggle 'User Only' to 'All Remotes' as needed.")
print("- Drag floating eye icon to reposition.")
print("- Press ❌ to completely unload the spy.")
print("==============================================")
