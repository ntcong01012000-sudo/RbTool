--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
--[[
    WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
-- =====================================================================
-- CENIROSO REMOTE SPY - V1.8 (Optimisé par Gemini)
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

-- =====================================================================
-- 1. CRÉATION DE L'INTERFACE UTILISATEUR (UI)
-- =====================================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "cenirosoRemoteSpy"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 37, 43)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
MainFrame.Size = UDim2.new(0, 550, 0, 350)
MainFrame.Active = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = Color3.fromRGB(25, 27, 33)
TopBar.BorderSizePixel = 0
TopBar.Size = UDim2.new(1, 0, 0, 30)

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 8)
TopBarCorner.Parent = TopBar

local TopBarHider = Instance.new("Frame")
TopBarHider.Parent = TopBar
TopBarHider.BackgroundColor3 = Color3.fromRGB(25, 27, 33)
TopBarHider.BorderSizePixel = 0
TopBarHider.Position = UDim2.new(0, 0, 1, -5)
TopBarHider.Size = UDim2.new(1, 0, 0, 5)

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Parent = TopBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Size = UDim2.new(0.5, 0, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "ceniroso Remote Spy - V1.8"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Parent = TopBar
CloseButton.BackgroundTransparency = 1
CloseButton.Position = UDim2.new(1, -30, 0, 0)
CloseButton.Size = UDim2.new(0, 30, 1, 0)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseButton.TextSize = 14

local RemotesList = Instance.new("ScrollingFrame")
RemotesList.Name = "RemotesList"
RemotesList.Parent = MainFrame
RemotesList.Active = true
RemotesList.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
RemotesList.BorderSizePixel = 0
RemotesList.Position = UDim2.new(0, 10, 0, 40)
RemotesList.Size = UDim2.new(0, 180, 1, -50)
RemotesList.CanvasSize = UDim2.new(0, 0, 0, 0)
RemotesList.ScrollBarThickness = 4
RemotesList.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)

local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 6)
ListCorner.Parent = RemotesList

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = RemotesList
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

-- Auto-ajustement dynamique de la taille de défilement (CanvasSize)
UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    RemotesList.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
end)

local CodeDisplay = Instance.new("TextLabel")
CodeDisplay.Name = "CodeDisplay"
CodeDisplay.Parent = MainFrame
CodeDisplay.BackgroundColor3 = Color3.fromRGB(40, 42, 54)
CodeDisplay.BorderSizePixel = 0
CodeDisplay.Position = UDim2.new(0, 200, 0, 40)
CodeDisplay.Size = UDim2.new(1, -210, 1, -90)
CodeDisplay.Font = Enum.Font.Code
CodeDisplay.Text = "<font color=\"#7A828B\">-- En attente d'événements...\n-- Les scripts apparaîtront ici avec la coloration syntaxique.</font>"
CodeDisplay.TextColor3 = Color3.fromRGB(248, 248, 242)
CodeDisplay.TextSize = 14
CodeDisplay.TextXAlignment = Enum.TextXAlignment.Left
CodeDisplay.TextYAlignment = Enum.TextYAlignment.Top
CodeDisplay.RichText = true
CodeDisplay.TextWrapped = true

local CodeCorner = Instance.new("UICorner")
CodeCorner.CornerRadius = UDim.new(0, 6)
CodeCorner.Parent = CodeDisplay

local UIPadding = Instance.new("UIPadding")
UIPadding.Parent = CodeDisplay
UIPadding.PaddingTop = UDim.new(0, 10)
UIPadding.PaddingLeft = UDim.new(0, 10)

-- Boutons de contrôle
local CopyButton = Instance.new("TextButton")
CopyButton.Name = "CopyButton"
CopyButton.Parent = MainFrame
CopyButton.BackgroundColor3 = Color3.fromRGB(45, 100, 200)
CopyButton.Position = UDim2.new(0, 200, 1, -40)
CopyButton.Size = UDim2.new(0, 110, 0, 30)
CopyButton.Font = Enum.Font.GothamBold
CopyButton.Text = "Copier"
CopyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyButton.TextSize = 13

local CopyCorner = Instance.new("UICorner")
CopyCorner.CornerRadius = UDim.new(0, 6)
CopyCorner.Parent = CopyButton

local SlowButton = Instance.new("TextButton")
SlowButton.Name = "SlowButton"
SlowButton.Parent = MainFrame
SlowButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
SlowButton.Position = UDim2.new(0, 315, 1, -40)
SlowButton.Size = UDim2.new(0, 110, 0, 30)
SlowButton.Font = Enum.Font.GothamBold
SlowButton.Text = "Ralentir: OFF"
SlowButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SlowButton.TextSize = 13

local SlowCorner = Instance.new("UICorner")
SlowCorner.CornerRadius = UDim.new(0, 6)
SlowCorner.Parent = SlowButton

local ClearButton = Instance.new("TextButton")
ClearButton.Name = "ClearButton"
ClearButton.Parent = MainFrame
ClearButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
ClearButton.Position = UDim2.new(0, 430, 1, -40)
ClearButton.Size = UDim2.new(0, 110, 0, 30)
ClearButton.Font = Enum.Font.GothamBold
ClearButton.Text = "Effacer"
ClearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearButton.TextSize = 13

local ClearCorner = Instance.new("UICorner")
ClearCorner.CornerRadius = UDim.new(0, 6)
ClearCorner.Parent = ClearButton

-- =====================================================================
-- 2. GESTION DU DÉPLACEMENT DE LA FENÊTRE (DRAG)
-- =====================================================================

local dragging, dragInput, dragStart, startPos

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
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
    RemoteBtn.BackgroundColor3 = Color3.fromRGB(45, 47, 55)
    RemoteBtn.BorderSizePixel = 0
    RemoteBtn.Size = UDim2.new(1, -10, 0, 25)
    RemoteBtn.Position = UDim2.new(0, 5, 0, 0)
    RemoteBtn.Font = Enum.Font.Gotham
    RemoteBtn.Text = " " .. remoteName
    RemoteBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    RemoteBtn.TextSize = 13
    RemoteBtn.TextXAlignment = Enum.TextXAlignment.Left

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 4)
    BtnCorner.Parent = RemoteBtn

    RemoteBtn.MouseButton1Click:Connect(function()
        _G.RawCode = generatedCode 
        local coloredCode = ApplySyntaxHighlighting(generatedCode)
        CodeDisplay.Text = coloredCode
    end)
end

-- Boucle de traitement de la file d'attente (Performances améliorées)
task.spawn(function()
    while true do
        if #RemoteQueue > 0 then
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
            
            if #RemoteQueue < MAX_QUEUE_SIZE then
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
            
            if #RemoteQueue < MAX_QUEUE_SIZE then
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
-- 6. LANCEMENT ET BOUTONS ANNEXES
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

CopyButton.MouseButton1Click:Connect(function()
    if setclipboard then
        if _G.RawCode ~= "" then
            setclipboard(_G.RawCode)
            CopyButton.Text = "Copié !"
            task.wait(1.5)
            CopyButton.Text = "Copier"
        end
    else
        warn("Ton exécuteur ne supporte pas setclipboard")
    end
end)

SlowButton.MouseButton1Click:Connect(function()
    IsSlowMode = not IsSlowMode
    
    if IsSlowMode then
        SlowButton.Text = "Ralentir: ON"
        SlowButton.BackgroundColor3 = Color3.fromRGB(200, 130, 40) -- Orange actif
    else
        SlowButton.Text = "Ralentir: OFF"
        SlowButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120) -- Gris inactif
    end
end)

ClearButton.MouseButton1Click:Connect(function()
    RemoteQueue = {}
    
    for _, child in pairs(RemotesList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    CodeDisplay.Text = "<font color=\"#7A828B\">-- En attente d'événements...\n-- Les scripts apparaîtront ici avec la coloration syntaxique.</font>"
    _G.RawCode = ""
end)

print("CENIROSO SPY V1.8 chargé avec succès (Optimisé & Sécurisé).")
