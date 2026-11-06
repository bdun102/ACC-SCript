-- =========================================================================
-- ACC MASTER SUITE: STRICT UI ISOLATION, CASH GRADER, LUNAS3VEN & QYRIX
-- =========================================================================

pcall(function()
    local keyName = "Key.txt"
    local keyValue = "qyrix-ghasldhjgsa"
    if writefile and isfile and not isfile(keyName) then
        writefile(keyName, keyValue)
    end
end)

local SCRIPT_URL = ""
local LOAD_EXTERNAL_HUBS = false
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local RF = game:GetService("ReplicatedFirst")
local HS = game:GetService("HttpService")
local TS = game:GetService("TweenService")
local VU = game:GetService("VirtualUser")
local VIM = game:GetService("VirtualInputManager")
local U2 = UDim2.new
local C3 = Color3.fromRGB
local F_GB = Enum.Font.GothamBold
local F_GM = Enum.Font.GothamMedium

LP:WaitForChild("PlayerGui", 15)
RS:WaitForChild("Remotes", 15)

local UID = tostring(LP.UserId)
local ConfigFileName = "ACC_Config_" .. UID .. ".json"
local StateFileName  = "ACC_State_" .. UID .. ".json"

pcall(function()
    local qTeleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if qTeleport and SCRIPT_URL ~= "" then
        LP.OnTeleport:Connect(function(state)
            if state == Enum.TeleportState.Started then qTeleport('loadstring(game:HttpGet("' .. SCRIPT_URL .. '"))()') end
        end)
    end
end)

-- EXTERNAL HUBS
task.spawn(function()
    if not LOAD_EXTERNAL_HUBS then return end
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end)
end)
task.spawn(function()
    if not LOAD_EXTERNAL_HUBS then return end
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/LunaS3ven/Script/Games/Loader.lua"))() end)
end)
task.spawn(function()
    if not LOAD_EXTERNAL_HUBS then return end
    pcall(function()
        local Data = { Owner = "Mana", Library = "Neverlose-UI" }
        local BaseURL = ("https://raw.githubusercontent.com/%s-scripts/%s/refs/heads/main/Games/"):format(Data.Owner, Data.Library)
        local function EncodeSpaces(str) return BaseURL .. str:gsub(" ", "%%20") end
        local Games = {
            [18172550962] = EncodeSpaces("Pixel Blade.lua"), [18172553902] = EncodeSpaces("Pixel Blade.lua"), [133884972346775] = EncodeSpaces("Pixel Blade.lua"),
            [130247632398296] = EncodeSpaces("Anime Fighting Simulator.lua"), [76285745979410] = EncodeSpaces("Anime Card Collection.lua"),
            [75992362647444] = EncodeSpaces("Tap Simulator.lua"), [111187356770616] = EncodeSpaces("Tap Simulator.lua"), 
            [74260430392611] = EncodeSpaces("Rebirth Champions Ultimate.lua"), [2753915549] = EncodeSpaces("Blox Fruits.lua"),
            [4442272183] = EncodeSpaces("Blox Fruits.lua"), [7449423635] = EncodeSpaces("Blox Fruits.lua"),
            [70768610276749] = EncodeSpaces("Anime Final Quest.lua"), [73019180051115] = EncodeSpaces("Anime Final Quest.lua"),
            [73912821025828] = EncodeSpaces("Anime Final Quest.lua"), [77367808280910] = EncodeSpaces("Anime Final Quest.lua"),
            [81100481912247] = EncodeSpaces("Anime Final Quest.lua"), [92577188734435] = EncodeSpaces("Anime Final Quest.lua"),
            [95240177479580] = EncodeSpaces("Anime Final Quest.lua"), [95996380540192] = EncodeSpaces("Anime Final Quest.lua"),
            [100744519298647] = EncodeSpaces("Anime Final Quest.lua"), [112175864208911] = EncodeSpaces("Anime Final Quest.lua"),
            [113644871968832] = EncodeSpaces("Anime Final Quest.lua"), [113963744934619] = EncodeSpaces("Anime Final Quest.lua"),
            [120826799896677] = EncodeSpaces("Anime Final Quest.lua"), [126889338150949] = EncodeSpaces("Anime Final Quest.lua"),
            [127316980657672] = EncodeSpaces("Anime Final Quest.lua"), [129369781546936] = EncodeSpaces("Anime Final Quest.lua"),
            [130426042808804] = EncodeSpaces("Anime Final Quest.lua"), [132561514935233] = EncodeSpaces("Anime Final Quest.lua"),
            [136683944064056] = EncodeSpaces("Anime Final Quest.lua"), [89469502395769] = EncodeSpaces("Kick A Lucky Block.lua"),
            [88933961678687] = EncodeSpaces("Hyper Speed Runner.lua")
        }
        local function LoadScript(id)
            local url = Games[id]
            if not url then return end
            loadstring(game:HttpGetAsync(url))()
        end
        LoadScript(game.PlaceId)
    end)
end)

-- ==========================================
-- 1. DATABASE EXTRACTION
-- ==========================================
local GRADE_ORDER = { "UR", "SR", "SS", "S+", "S", "A", "B", "C", "D", "E", "F" }
local GRADE_LIST = { "F", "E", "D", "C", "B", "A", "S", "S+", "SS", "SR", "UR" }
local GRADE_RANK = { F = 1, E = 2, D = 3, C = 4, B = 5, A = 6, S = 7, ["S+"] = 8, SS = 9, SR = 10, UR = 11 }
local ROLL_TIMEOUT_SECONDS = 15

local function stripTags(str)
    if str == nil then return "" end
    local s = string.gsub(tostring(str), "<[^>]+>", "")
    return (string.match(s, "^%s*(.-)%s*$") or s)
end
local function extractId(str) return string.match(tostring(str), "%d+") or tostring(str) end

local function parseGrade(text)
    if text == nil then return nil end
    local raw = string.upper(stripTags(tostring(text)))
    if raw == "" then return nil end
    local compact = string.gsub(raw, "S%s*%+", "S+")
    compact = string.gsub(compact, "[%s:%-_%[%]%(%)|]+", "")
    if GRADE_RANK[compact] then return compact end
    local spaced = string.gsub(raw, "S%s*%+", "S+")
    for _, g in ipairs(GRADE_ORDER) do
        local startAt = 1
        while true do
            local i, j = string.find(spaced, g, startAt, true)
            if not i then break end
            local before = i > 1 and string.sub(spaced, i - 1, i - 1) or ""
            local after = string.sub(spaced, j + 1, j + 1)
            local beforeOk = before == "" or string.match(before, "[%a%+]") == nil
            local afterOk = after == "" or string.match(after, "[%a%+]") == nil
            if beforeOk and afterOk then return g end
            startAt = i + 1
        end
    end
    return nil
end

local function gradeFromValue(v)
    if type(v) == "table" then return parseGrade(v.Grade or v.grade or v.Rarity or v.Result or v.Tier) end
    return parseGrade(v)
end

local function exactGrade(v)
    if type(v) == "table" then return exactGrade(v.Grade or v.grade or v.Rarity or v.Result or v.Tier) end
    if v == nil then return nil end
    local s = string.upper(stripTags(tostring(v)))
    s = string.gsub(s, "S%s*%+", "S+")
    s = string.gsub(s, "%s+", "")
    if GRADE_RANK[s] then return s end
    return nil
end

local liveDataModule
local function getLiveData(...)
    local args = { ... }
    local ok, record = pcall(function()
        if not liveDataModule then
            local moduleScript = RF:FindFirstChild("ReplicatedData")
            if not moduleScript then return nil end
            liveDataModule = require(moduleScript)
        end
        return liveDataModule.GetData(table.unpack(args))
    end)
    return ok and record or nil
end

local function getLiveRecord(collection, itemName)
    local record = getLiveData(collection, itemName)
    return type(record) == "table" and record or nil
end

local CardSortedPacks, CardPackCards = {}, {}
local nameToImage, imageIdToNames, cardDisplayNames = {}, {}, {}

pcall(function()
    local rawImageDb = require(RS.Modules.Config.Core.ImageConfig)
    local function parseImages(tbl)
        for key, value in pairs(tbl) do
            if type(value) == "string" and string.find(value, "rbxassetid", 1, true) then
                local imageId = extractId(value)
                local cleanName = string.lower(stripTags(key))
                nameToImage[cleanName] = imageId
                imageIdToNames[imageId] = imageIdToNames[imageId] or {}
                table.insert(imageIdToNames[imageId], cleanName)
            elseif type(value) == "table" then
                parseImages(value)
            end
        end
    end
    parseImages(rawImageDb)
    for key, value in pairs(rawImageDb.Names or {}) do
        cardDisplayNames[string.lower(stripTags(key))] = string.lower(stripTags(value))
    end
end)

pcall(function()
    local rawCardDb = require(RS.Modules.Config.Core.CardConfig)
    local targetPacks = rawCardDb.Packs or rawCardDb
    for key, value in pairs(rawCardDb) do
        if type(value) == "table" and not value.Price then
            local firstChild = next(value)
            if type(value[firstChild]) == "table" and (value[firstChild].Price or value[firstChild].List) then
                targetPacks = value
                break
            end
        end
    end
    for packName, packData in pairs(targetPacks or {}) do
        if type(packData) == "table" and type(packData.List) == "table" then
            local cards, seen = {}, {}
            for key, value in pairs(packData.List) do
                local name = type(value) == "string" and value or (type(value) == "table" and value.Name or (type(key) == "string" and key or ""))
                local cleanName = stripTags(name)
                if cleanName ~= "" and not seen[cleanName] then
                    seen[cleanName] = true
                    table.insert(cards, cleanName)
                end
            end
            if #cards > 0 then
                local cleanPackName = stripTags(packName)
                table.insert(CardSortedPacks, { Name = cleanPackName, Price = tonumber(packData.Price) or math.huge, Raw = packData })
                CardPackCards[cleanPackName] = cards
            end
        end
    end
    table.sort(CardSortedPacks, function(a, b) return a.Price < b.Price end)
end)

-- ==========================================
-- 2. STRICT DIRECT UI LOOKUP (NO CACHE/HEURISTICS)
-- ==========================================
local function findGradeInUI(iName)
    if not iName then return nil end
    local cleanKey = string.lower(stripTags(iName))
    local targetId = nameToImage[cleanKey]
    for _, collection in ipairs({ "Cards", "TowerCards" }) do
        local record = getLiveRecord(collection, iName)
        local liveGrade = record and exactGrade(record.Grade)
        if liveGrade then return liveGrade end
    end
    local displayKey = cardDisplayNames[cleanKey]
    local pg = LP:FindFirstChild("PlayerGui")
    local gsFrame = pg and pg:FindFirstChild("GradeSelect") and pg.GradeSelect:FindFirstChild("Frame") and pg.GradeSelect.Frame:FindFirstChild("ScrollingFrame")
    if not gsFrame then return nil end

    local function textValue(node)
        if node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox") then
            return string.lower(stripTags(node.Text))
        end
        return ""
    end

    local function gradeFromItem(item)
        local fallback
        for _, node in ipairs(item:GetDescendants()) do
            if node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox") then
                local value = stripTags(node.Text)
                if value ~= "" and string.lower(value) ~= "ungraded" and string.lower(value) ~= "none" then
                    local grade = exactGrade(value) or parseGrade(value)
                    if grade then
                        local nodeName = string.lower(node.Name)
                        if nodeName == "grade" or nodeName == "gradelabel" then return grade end
                        fallback = fallback or grade
                    end
                end
            end
        end
        return fallback
    end

    for _, item in ipairs(gsFrame:GetChildren()) do
        if item:IsA("GuiObject") then
            local isMatch = false
            for _, node in ipairs(item:GetDescendants()) do
                local text = textValue(node)
                if text == cleanKey or (displayKey and text == displayKey) or string.sub(text, 1, #cleanKey + 1) == cleanKey .. " " then
                    isMatch = true
                    break
                end
            end
            if not isMatch and targetId then
                for _, node in ipairs(item:GetDescendants()) do
                    if (node:IsA("ImageLabel") or node:IsA("ImageButton")) and extractId(node.Image) == targetId then
                        isMatch = true
                        break
                    end
                end
            end
            if isMatch then
                local grade = gradeFromItem(item)
                if grade then return grade end
            end
        end
    end
    return nil
end

-- ==========================================
-- 3. MASTER UI SETUP
-- ==========================================
local AllItemButtons = {}
local SaveConfig, SaveState 

local sharedEnv = (type(getgenv) == "function" and getgenv()) or _G
local function safeGuiParent()
    local ok, parent = pcall(function()
        if type(gethui) == "function" then return gethui() end
        return game:GetService("CoreGui")
    end)
    return ok and parent or LP:FindFirstChild("PlayerGui")
end

local cleanupParents = { safeGuiParent(), game:GetService("CoreGui"), LP:FindFirstChild("PlayerGui") }
local seenCleanupParents = {}
for _, parent in ipairs(cleanupParents) do
    if parent and not seenCleanupParents[parent] then
        seenCleanupParents[parent] = true
        local oldSuite = parent:FindFirstChild("ACC_Suite")
        if oldSuite then oldSuite:Destroy() end
    end
end
if type(sharedEnv.ACC_SpyBound) == "table" then
    for remote, connection in pairs(sharedEnv.ACC_SpyBound) do
        pcall(function() connection:Disconnect() end)
        sharedEnv.ACC_SpyBound[remote] = nil
    end
end
sharedEnv.ACC_SpyOn = false

local targetParent = safeGuiParent() or LP:FindFirstChild("PlayerGui")

local sg = Instance.new("ScreenGui", targetParent)
sg.Name = "ACC_Suite"
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.ResetOnSpawn = false

local sqBtn = Instance.new("TextButton", sg)
sqBtn.Size, sqBtn.Position, sqBtn.BackgroundColor3, sqBtn.TextColor3 = U2(0, 45, 0, 45), U2(0.5, -22, 0, 20), C3(35, 35, 35), C3(255, 255, 255)
sqBtn.Text, sqBtn.Font, sqBtn.TextSize, sqBtn.Visible, sqBtn.Active, sqBtn.Draggable, sqBtn.BorderSizePixel = "ACC", F_GB, 12, false, true, true, 0
Instance.new("UICorner", sqBtn).CornerRadius = UDim.new(0, 8)

local mFrame = Instance.new("Frame", sg)
mFrame.Size, mFrame.Position, mFrame.BackgroundColor3, mFrame.BorderSizePixel = U2(0.94, 0, 0.88, 0), U2(0.5, 0, 0.5, 0), C3(35, 35, 35), 0
mFrame.Active, mFrame.Draggable, mFrame.ClipsDescendants = true, true, true
local frameConstraint = Instance.new("UISizeConstraint", mFrame)
frameConstraint.MinSize = Vector2.new(360, 420)
frameConstraint.MaxSize = Vector2.new(980, 760)

task.spawn(function()
    while task.wait(2) do
        if not mFrame:IsDescendantOf(game) then break end
        for _, d in ipairs(AllItemButtons) do
            if d.btn.Parent and d.btn.Parent.Visible then
                local cG = findGradeInUI(d.name)
                local isS = d.selData[d.packName].items[d.name]
                d.btn.Text = "   ↳ " .. (isS and "[X] " or "[ ] ") .. d.name .. (cG and " [" .. cG .. "]" or " [?]")
                d.btn.TextColor3 = isS and C3(40, 200, 120) or (cG and C3(200, 200, 200) or C3(100, 100, 100))
            end
        end
    end
end)

local uiScale = Instance.new("UIScale", mFrame) uiScale.Scale = 1
local tBar = Instance.new("Frame", mFrame) tBar.Size, tBar.BackgroundColor3, tBar.BorderSizePixel = U2(1, 0, 0, 40), C3(20, 20, 20), 0
local title = Instance.new("TextLabel", tBar) title.Size, title.Position, title.BackgroundTransparency, title.TextColor3, title.Text, title.Font, title.TextSize, title.TextXAlignment = U2(1,-60,1,0), U2(0,10,0,0), 1, C3(255,255,255), "ACC Master Suite (" .. LP.Name .. ")", F_GB, 14, Enum.TextXAlignment.Left

local minBtn = Instance.new("TextButton", tBar) minBtn.Size, minBtn.Position, minBtn.BackgroundColor3, minBtn.TextColor3, minBtn.Text, minBtn.Font, minBtn.TextSize, minBtn.BorderSizePixel = U2(0,40,0,40), U2(1,-40,0,0), C3(200,180,40), C3(25,25,25), "—", F_GB, 14, 0
minBtn.MouseButton1Click:Connect(function() mFrame.Visible = false sqBtn.Visible = true end)
sqBtn.MouseButton1Click:Connect(function() sqBtn.Visible = false mFrame.Visible = true end)

local tabC = Instance.new("ScrollingFrame", mFrame)
tabC.Size, tabC.Position, tabC.BackgroundColor3, tabC.BorderSizePixel = U2(1, 0, 0, 42), U2(0, 0, 0, 40), C3(25, 25, 25), 0
tabC.Active, tabC.ScrollingDirection, tabC.ScrollBarThickness, tabC.CanvasSize = true, Enum.ScrollingDirection.X, 4, U2(0, 0, 0, 0)
tabC.AutomaticCanvasSize = Enum.AutomaticSize.X
local tabLayout = Instance.new("UIListLayout", tabC)
tabLayout.FillDirection, tabLayout.SortOrder, tabLayout.Padding = Enum.FillDirection.Horizontal, Enum.SortOrder.LayoutOrder, UDim.new(0, 2)

local function mkTabBtn(name, pIdx, tot)
    local b = Instance.new("TextButton", tabC) b.Size, b.LayoutOrder, b.Text, b.Font, b.TextSize, b.BorderSizePixel = U2(0, 94, 1, 0), pIdx, name, F_GB, 12, 0
    b.BackgroundColor3, b.TextColor3 = pIdx==1 and C3(45,45,45) or C3(35,35,35), pIdx==1 and C3(255,255,255) or C3(150,150,150)
    return b
end

local nTabs = 12
local tBtns = {
    mkTabBtn("Cards",1,nTabs), mkTabBtn("Tower",2,nTabs), mkTabBtn("Event",3,nTabs), mkTabBtn("Auto",4,nTabs), 
    mkTabBtn("Figurines",5,nTabs), mkTabBtn("Raid",6,nTabs), mkTabBtn("Manga",7,nTabs), mkTabBtn("Fish",8,nTabs), mkTabBtn("Gems",9,nTabs), mkTabBtn("HUD",10,nTabs), mkTabBtn("Spy",11,nTabs), mkTabBtn("⚙",12,nTabs)
}
local tFrames = {}
for i=1, nTabs do
    local f = Instance.new("Frame", mFrame) f.Size, f.Position, f.BackgroundTransparency, f.Visible = U2(1,0,1,-82), U2(0,0,0,82), 1, i==1
    tFrames[i] = f
end
for i, btn in ipairs(tBtns) do
    btn.MouseButton1Click:Connect(function()
        for j, b in ipairs(tBtns) do
            b.BackgroundColor3, b.TextColor3 = b==btn and C3(45,45,45) or C3(35,35,35), b==btn and C3(255,255,255) or C3(150,150,150)
            tFrames[j].Visible = tFrames[j]==tFrames[i]
        end
    end)
end
local cFrame, tFrame, hFrame, aFrame, figFrame, raidFrame, mangaFrame, fFrame, gFrame, hudTabFrame, spyFrame, sFrame = unpack(tFrames)

local function mkInp(p, lblText, def, py, xOff, wid)
    wid = wid or 240
    local l = Instance.new("TextLabel", p) l.Size, l.Position, l.BackgroundTransparency, l.TextColor3, l.Text, l.Font, l.TextSize, l.TextXAlignment = U2(0,wid,0,20), U2(0.5,xOff,0,py), 1, C3(200,200,200), lblText, F_GB, 12, Enum.TextXAlignment.Left
    local b = Instance.new("TextBox", p) b.Size, b.Position, b.BackgroundColor3, b.TextColor3, b.Text, b.Font, b.TextSize, b.BorderSizePixel = U2(0,wid,0,36), U2(0.5,xOff,0,py+20), C3(15,15,15), C3(255,255,255), def, F_GM, 14, 0
    return b
end

local function mkDropdown(parent, labelText, options, defaultValue, y, width)
    width = width or 260
    local label = Instance.new("TextLabel", parent)
    label.Size, label.Position, label.BackgroundTransparency, label.TextColor3, label.Text, label.Font, label.TextSize = U2(0, width, 0, 20), U2(0.5, -width / 2, 0, y), 1, C3(200, 200, 200), labelText, F_GB, 12
    local button = Instance.new("TextButton", parent)
    button.Size, button.Position, button.BackgroundColor3, button.TextColor3, button.Text, button.Font, button.TextSize, button.BorderSizePixel = U2(0, width, 0, 36), U2(0.5, -width / 2, 0, y + 20), C3(15, 15, 15), C3(255, 255, 255), tostring(defaultValue or options[1] or ""), F_GM, 14, 0
    local menu = Instance.new("ScrollingFrame", parent)
    menu.Size, menu.Position, menu.BackgroundColor3, menu.BorderSizePixel, menu.ScrollBarThickness, menu.Visible, menu.ZIndex = U2(0, width, 0, 180), U2(0.5, -width / 2, 0, y + 58), C3(25, 25, 25), 0, 6, false, 20
    menu.CanvasSize = U2(0, 0, 0, #options * 36)
    local layout = Instance.new("UIListLayout", menu)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    for index, option in ipairs(options) do
        local item = Instance.new("TextButton", menu)
        item.Size, item.LayoutOrder, item.BackgroundColor3, item.TextColor3, item.Text, item.Font, item.TextSize, item.BorderSizePixel, item.ZIndex = U2(1, -8, 0, 36), index, C3(35, 35, 35), C3(255, 255, 255), tostring(option), F_GM, 13, 0, 21
        item.MouseButton1Click:Connect(function()
            button.Text = tostring(option)
            menu.Visible = false
        end)
    end
    button.MouseButton1Click:Connect(function() menu.Visible = not menu.Visible end)
    return button
end

-- ==========================================
-- 4. SPY SCANNER (WITH FILE DUMP)
-- ==========================================
local function buildSpy(parent)
    local env = (type(getgenv) == "function" and getgenv()) or _G
    local listening, view, scanEntries, liveEntries = false, "scan", {}, {}
    local selectedBody, renderQueued, hookNote = "", false, "hook not installed yet"
    local bound = env.ACC_SpyBound or {} env.ACC_SpyBound, env.ACC_SpyOn = bound, false

    local bar = Instance.new("Frame", parent) bar.Size, bar.Position, bar.BackgroundTransparency = U2(1, -12, 0, 28), U2(0, 6, 0, 6), 1
    local filter = Instance.new("TextBox", parent) filter.Size, filter.Position, filter.BackgroundColor3, filter.TextColor3 = U2(1, -12, 0, 26), U2(0, 6, 0, 38), C3(15, 15, 15), C3(255, 255, 255)
    filter.PlaceholderText, filter.Text, filter.Font, filter.TextSize, filter.ClearTextOnFocus, filter.BorderSizePixel = "Filter (remote, module, args...)", "", F_GM, 13, false, 0

    local status = Instance.new("TextLabel", parent)
    status.BackgroundTransparency, status.Size, status.Position, status.Font, status.TextSize = 1, U2(1, -165, 0, 16), U2(0, 8, 0, 68), F_GM, 12
    status.TextXAlignment, status.TextColor3, status.Text = Enum.TextXAlignment.Left, C3(180, 180, 180), "Full maps the game. Listen logs calls."

    local copyBtn = Instance.new("TextButton", parent) copyBtn.Size, copyBtn.Position, copyBtn.BackgroundColor3, copyBtn.TextColor3, copyBtn.Text, copyBtn.Font, copyBtn.TextSize, copyBtn.BorderSizePixel, copyBtn.ZIndex, copyBtn.Visible = U2(0, 64, 0, 18), U2(1, -70, 0, 66), C3(40, 40, 40), C3(255, 255, 255), "Copy", F_GB, 12, 0, 10, true
    local dumpBtn = Instance.new("TextButton", parent) dumpBtn.Size, dumpBtn.Position, dumpBtn.BackgroundColor3, dumpBtn.TextColor3, dumpBtn.Text, dumpBtn.Font, dumpBtn.TextSize, dumpBtn.BorderSizePixel, dumpBtn.ZIndex, dumpBtn.Visible = U2(0, 80, 0, 18), U2(1, -155, 0, 66), C3(40, 40, 40), C3(255, 255, 255), "Dump File", F_GB, 12, 0, 10, true

    local list = Instance.new("ScrollingFrame", parent) list.Size, list.Position, list.BackgroundColor3, list.BorderSizePixel, list.ScrollBarThickness, list.CanvasSize = U2(1, -12, 1, -196), U2(0, 6, 0, 88), C3(18, 18, 18), 0, 6, U2(0, 0, 0, 0)
    local lay = Instance.new("UIListLayout", list) lay.SortOrder, lay.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 2)
    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() list.CanvasSize = U2(0, 0, 0, lay.AbsoluteContentSize.Y + 4) end)

    local detail = Instance.new("TextBox", parent) detail.Size, detail.Position, detail.BackgroundColor3, detail.TextColor3, detail.Font, detail.TextSize = U2(1, -12, 0, 92), U2(0, 6, 1, -98), C3(12, 12, 12), C3(220, 220, 220), F_GM, 12
    detail.TextXAlignment, detail.TextYAlignment, detail.TextWrapped, detail.ClearTextOnFocus, detail.TextEditable, detail.MultiLine, detail.BorderSizePixel, detail.Text = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top, true, false, false, true, 0, "Nothing selected."

    local function setStatus(txt) status.Text = txt end
    local function render()
        local source = view == "live" and liveEntries or scanEntries
        local q = string.lower(filter.Text or "")
        for _, child in ipairs(list:GetChildren()) do if not child:IsA("UIListLayout") then child:Destroy() end end
        local shown = 0
        for i, entry in ipairs(source) do
            local hay = string.lower(entry.title .. "\n" .. (entry.body or ""))
            if q == "" or string.find(hay, q, 1, true) ~= nil then
                shown = shown + 1
                local row = Instance.new("TextButton", list)
                row.Size, row.BackgroundColor3, row.TextColor3, row.Font, row.TextSize, row.TextXAlignment, row.BorderSizePixel, row.AutoButtonColor, row.Text, row.LayoutOrder = U2(1, -8, 0, 20), (i % 2 == 0) and C3(30, 30, 30) or C3(24, 24, 24), C3(230, 230, 230), F_GM, 12, Enum.TextXAlignment.Left, 0, true, "  " .. entry.title, i
                local body = entry.body or entry.title
                row.MouseButton1Click:Connect(function() selectedBody = body detail.Text = body end)
            end
        end
        setStatus(string.format("%s  %d/%d   %s", (view == "live" and "live" or "scan"), shown, #source, hookNote))
    end
    filter:GetPropertyChangedSignal("Text"):Connect(render)
    local function queueRender() if renderQueued then return end renderQueued = true task.defer(function() renderQueued = false if parent.Visible or view == "scan" then render() end end) end
    local function push(bucket, title, body, key)
        if key and #bucket > 0 then local last = bucket[#bucket] if last.key == key then last.count = (last.count or 1) + 1 last.title = title .. "  x" .. tostring(last.count) last.body = (body or title) .. "\n\nrepeated " .. tostring(last.count) .. " times" return end end
        bucket[#bucket + 1] = {title = title, body = body or title, key = key, count = 1}
        if #bucket > 300 then table.remove(bucket, 1) end
    end
    local function instPath(inst)
        local names, cur, n = {}, inst, 0
        while typeof(cur) == "Instance" and n < 10 do local okN, name = pcall(function() return cur.Name end) if not okN then break end table.insert(names, 1, name) local okP, par = pcall(function() return cur.Parent end) if not okP then break end cur = par n = n + 1 end
        return table.concat(names, ".")
    end

    local function formatValue(value, depth, seen)
        depth, seen = depth or 0, seen or {}
        local valueType = typeof(value)
        if value == nil then return "nil" end
        if valueType == "string" then return string.format("%q", value) end
        if valueType == "number" or valueType == "boolean" then return tostring(value) end
        if valueType == "Instance" then
            local ok, full = pcall(function() return value:GetFullName() end)
            return "<" .. (ok and full or value.Name) .. ">"
        end
        if valueType ~= "table" then return "<" .. valueType .. ">" end
        if seen[value] then return "<cycle>" end
        if depth >= 2 then return "{...}" end
        seen[value] = true
        local parts, count = {}, 0
        for key, child in pairs(value) do
            count = count + 1
            if count > 20 then
                parts[#parts + 1] = "..."
                break
            end
            parts[#parts + 1] = "[" .. formatValue(key, depth + 1, seen) .. "]=" .. formatValue(child, depth + 1, seen)
        end
        seen[value] = nil
        return "{" .. table.concat(parts, ", ") .. "}"
    end

    local function onOutgoing(self, method, args, results)
        if not listening then return end
        local path = instPath(self)
        local argStr = ""
        if args and type(args) == "table" then for i, v in ipairs(args) do argStr = argStr .. formatValue(v) .. (i < #args and ", " or "") end end
        push(liveEntries, "[OUT] " .. method .. " " .. (self.Name or path), path .. "\n" .. method .. "(" .. argStr .. ")", method .. " " .. path)
        if view == "live" then queueRender() end
    end
    local function onIncoming(remote, args)
        if not listening then return end
        local path = instPath(remote)
        local argStr = ""
        if args and type(args) == "table" then for i, v in ipairs(args) do argStr = argStr .. formatValue(v) .. (i < #args and ", " or "") end end
        push(liveEntries, "[IN] " .. (remote.Name or "event"), path .. "\nOnClientEvent(" .. argStr .. ")", "IN " .. path)
        if view == "live" then queueRender() end
    end

    env.ACC_SpyDispatch = function(self, method, args, results) pcall(onOutgoing, self, method, args, results) end
    env.ACC_SpyIn = function(remote, args) pcall(onIncoming, remote, args) end

    local function bindIncoming(remote)
        if bound[remote] then return end
        local ok, conn = pcall(function() return remote.OnClientEvent:Connect(function(...) if env.ACC_SpyIn then env.ACC_SpyIn(remote, {...}) end end) end)
        if ok and conn then bound[remote] = conn end
    end

    local function bindAll()
        local roots, n = { RS, LP:FindFirstChild("PlayerGui") }, 0
        for _, root in ipairs(roots) do
            if root then
                local ok, desc = pcall(function() return root:GetDescendants() end)
                if ok then for _, d in ipairs(desc) do local cls = d.ClassName if cls == "RemoteEvent" or cls == "UnreliableRemoteEvent" then bindIncoming(d) n = n + 1 end end end
            end
        end
        return n
    end

    local function scanAll()
        local out, seen = {}, {}
        local function add(title, body)
            out[#out + 1] = { title = title, body = body }
        end
        local function fullName(inst)
            local ok, value = pcall(function() return inst:GetFullName() end)
            return ok and value or instPath(inst)
        end
        for _, root in ipairs({ RS, game:GetService("ReplicatedFirst"), LP:FindFirstChild("PlayerGui") }) do
            if root then
                local ok, descendants = pcall(function() return root:GetDescendants() end)
                if ok then
                    for _, inst in ipairs(descendants) do
                        local cls = inst.ClassName
                        if cls == "RemoteEvent" or cls == "UnreliableRemoteEvent" or cls == "RemoteFunction" or inst:IsA("ModuleScript") then
                            local path = fullName(inst)
                            if not seen[path] then
                                seen[path] = true
                                add("[" .. cls .. "] " .. inst.Name, path)
                            end
                        end
                    end
                end
            end
        end
        local pg = LP:FindFirstChild("PlayerGui")
        if pg then
            for _, gui in ipairs(pg:GetChildren()) do
                if gui:IsA("ScreenGui") then
                    add("[GUI] " .. gui.Name, fullName(gui) .. "\nEnabled: " .. tostring(gui.Enabled))
                end
            end
        end
        table.sort(out, function(a, b) return a.title < b.title end)
        return out
    end

    local function installHook()
        if env.ACC_SpyHooked then
            hookNote = "outgoing hook already active"
            return true
        end
        if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then
            hookNote = "outgoing hook unavailable; incoming only"
            return false
        end
        local old
        local function handler(self, ...)
            local method = getnamecallmethod()
            if env.ACC_SpyOn and not env.ACC_SpyBusy and (method == "FireServer" or method == "InvokeServer") and typeof(self) == "Instance" then
                env.ACC_SpyBusy = true
                pcall(env.ACC_SpyDispatch, self, method, { ... })
                env.ACC_SpyBusy = false
            end
            return old(self, ...)
        end
        if type(newcclosure) == "function" then handler = newcclosure(handler) end
        local ok, previous = pcall(function() return hookmetamethod(game, "__namecall", handler) end)
        if not ok then
            hookNote = "outgoing hook failed: " .. tostring(previous)
            return false
        end
        old = previous
        env.ACC_SpyHooked = true
        hookNote = "outgoing hook active"
        return true
    end

    buttons.Full.MouseButton1Click:Connect(function()
        setStatus("Scanning remotes, modules, and GUI...")
        task.spawn(function()
            scanEntries = scanAll()
            view = "scan"
            render()
            setStatus("Full scan complete: " .. tostring(#scanEntries) .. " entries")
        end)
    end)
    buttons.Clear.MouseButton1Click:Connect(function() scanEntries, liveEntries, selectedBody, detail.Text = {}, {}, "", "Cleared." render() end)
    buttons.Listen.MouseButton1Click:Connect(function()
        listening = not listening env.ACC_SpyOn = listening
        if listening then
            local n = 0
            pcall(function() n = bindAll() end)
            pcall(installHook)
            buttons.Listen.Text, buttons.Listen.BackgroundColor3 = "Stop", C3(200, 40, 40)
            view = "live"
            hookNote = hookNote .. " | incoming bound " .. tostring(n)
            render()
        else buttons.Listen.Text, buttons.Listen.BackgroundColor3 = "Listen", C3(40, 40, 40) setStatus("Listener off.") end
    end)
    copyBtn.MouseButton1Click:Connect(function()
        local text = detail.Text or "" if text == "" then return end
        if type(setclipboard) == "function" then pcall(setclipboard, text) setStatus("Copied") elseif type(toclipboard) == "function" then pcall(toclipboard, text) setStatus("Copied") else setStatus("No setclipboard.") end
    end)
    dumpBtn.MouseButton1Click:Connect(function()
        local dumpFileName = "ACC_Spy_Dump.txt"
        if not writefile then setStatus("Executor does not support writefile!") return end
        local out = {} local source = view == "live" and liveEntries or scanEntries
        for _, entry in ipairs(source) do table.insert(out, "TITLE: " .. entry.title .. "\nBODY:\n" .. (entry.body or "") .. "\n------------------------") end
        if #out == 0 then setStatus("Nothing to dump!") return end
        pcall(function()
            local content = table.concat(out, "\n\n")
            if isfile and isfile(dumpFileName) and readfile then writefile(dumpFileName, readfile(dumpFileName) .. "\n\n=== NEW DUMP ===\n\n" .. content)
            else writefile(dumpFileName, content) end
        end)
        setStatus("Dumped " .. #source .. " items to " .. dumpFileName)
    end)
    parent:GetPropertyChangedSignal("Visible"):Connect(function() if parent.Visible then render() end end)
end
local spyBuilt, spyError = pcall(buildSpy, spyFrame)
if not spyBuilt then
    warn("[ACC] Spy tab failed: " .. tostring(spyError))
    local spyErrorLabel = Instance.new("TextLabel", spyFrame)
    spyErrorLabel.Size = U2(1, -20, 0, 60)
    spyErrorLabel.Position = U2(0, 10, 0, 20)
    spyErrorLabel.BackgroundTransparency = 1
    spyErrorLabel.TextColor3 = C3(255, 140, 140)
    spyErrorLabel.TextWrapped = true
    spyErrorLabel.Text = "Spy failed to build:\n" .. tostring(spyError)
end

-- ==========================================
-- 5. BACKGROUND MODULES (HUD, EVENT, FISH, GEMS)
-- ==========================================
local isHudEnabled = false
local accHud = Instance.new("Frame", sg)
accHud.Size, accHud.Position, accHud.BackgroundColor3, accHud.BackgroundTransparency = U2(0, 200, 0, 150), U2(0, 20, 0.5, -75), C3(15,15,15), 0.3
accHud.Active, accHud.Draggable, accHud.Visible = true, true, false
Instance.new("UICorner", accHud).CornerRadius = UDim.new(0, 8)

local function mkHudRow(py, iconId, defText)
    local r = Instance.new("Frame", accHud) r.Size, r.Position, r.BackgroundTransparency = U2(1,0,0,25), U2(0,0,0,py), 1
    local ic = Instance.new("ImageLabel", r) ic.Size, ic.Position, ic.BackgroundTransparency, ic.Image = U2(0,20,0,20), U2(0,10,0,2), 1, iconId
    local tx = Instance.new("TextLabel", r) tx.Size, tx.Position, tx.BackgroundTransparency, tx.TextColor3, tx.Text, tx.Font, tx.TextSize, tx.TextXAlignment = U2(1,-40,1,0), U2(0,35,0,0), 1, C3(255,255,255), defText, F_GM, 13, Enum.TextXAlignment.Left
    return tx
end
local hCash = mkHudRow(30, "rbxassetid://84225083685543", "Cash: 0")
local hEvt = mkHudRow(55, "rbxassetid://82846623271410", "Event: 0")
local hGrade = mkHudRow(80, "rbxassetid://76024843045813", "Grade: 0")
local hFish = mkHudRow(105, "rbxassetid://131575541379453", "Fish: 0")

local hudTglBtn = Instance.new("TextButton", hudTabFrame) hudTglBtn.Size, hudTglBtn.Position, hudTglBtn.BackgroundColor3, hudTglBtn.TextColor3, hudTglBtn.Text, hudTglBtn.Font, hudTglBtn.TextSize, hudTglBtn.BorderSizePixel = U2(0,240,0,40), U2(0.5,-120,0,20), C3(50,50,50), C3(200,200,200), "[ ] Enable Live HUD", F_GB, 14, 0
local function setHudState(state)
    isHudEnabled = state hudTglBtn.Text, hudTglBtn.BackgroundColor3 = isHudEnabled and "[X] Enable Live HUD" or "[ ] Enable Live HUD", isHudEnabled and C3(40,200,120) or C3(50,50,50) accHud.Visible = isHudEnabled
    if isHudEnabled then task.spawn(function()
        while isHudEnabled and accHud:IsDescendantOf(game) do
            local pg = LP.PlayerGui
            if pg:FindFirstChild("HUD") and pg.HUD:FindFirstChild("Frame") and pg.HUD.Frame:FindFirstChild("Cash") then hCash.Text = "Cash: " .. stripTags(pg.HUD.Frame.Cash.Text) end
            if pg:FindFirstChild("Grade") and pg.Grade:FindFirstChild("Frame") and pg.Grade.Frame:FindFirstChild("PlayerTokens") then hGrade.Text = "Grade: " .. stripTags(pg.Grade.Frame.PlayerTokens.Amount.Text) end
            if pg:FindFirstChild("LiveEventShop") and pg.LiveEventShop:FindFirstChild("Frame") and pg.LiveEventShop.Frame:FindFirstChild("PlayerTokens") then hEvt.Text = "Event: " .. stripTags(pg.LiveEventShop.Frame.PlayerTokens.Amount.Text) end
            if pg:FindFirstChild("Fishing") and pg.Fishing:FindFirstChild("Frame") and pg.Fishing.Frame:FindFirstChild("PlayerTokens") then hFish.Text = "Fish: " .. stripTags(pg.Fishing.Frame.PlayerTokens.Amount.Text) end
            task.wait(1)
        end
    end) end
end
hudTglBtn.MouseButton1Click:Connect(function() setHudState(not isHudEnabled) if SaveState then SaveState() end end)

local function clickUIPath(pathStr)
    local ok, clicked = pcall(function()
        local parts = string.split(pathStr, ".") local current = game
        for _, p in ipairs(parts) do
            if p == "Players" then current = game.Players elseif p == "LocalPlayer" then current = LP else current = current:FindFirstChild(p) end
            if not current then return false end
        end
        if not current or not current:IsA("GuiButton") then return false end
        if type(firesignal) == "function" then
            firesignal(current.MouseButton1Click)
            return true
        end
        if type(getconnections) == "function" then
            for _, connection in ipairs(getconnections(current.MouseButton1Click)) do
                if type(connection.Function) == "function" then
                    pcall(connection.Function)
                    return true
                end
            end
        end
        return false
    end)
    return ok and clicked == true
end

local isSmelt, isPotion, isClaim = false, false, false
local aSmelt = Instance.new("TextButton", aFrame) aSmelt.Size, aSmelt.Position, aSmelt.BackgroundColor3, aSmelt.TextColor3, aSmelt.Text, aSmelt.Font, aSmelt.TextSize, aSmelt.BorderSizePixel = U2(0,240,0,40), U2(0.5,-120,0,20), C3(50,50,50), C3(200,200,200), "[ ] Auto-Smelt All", F_GB, 13, 0
local function setSmeltState(state)
    isSmelt = state aSmelt.Text, aSmelt.BackgroundColor3 = isSmelt and "[X] Auto-Smelt All" or "[ ] Auto-Smelt All", isSmelt and C3(40,200,120) or C3(50,50,50)
    if isSmelt then task.spawn(function() while isSmelt and mFrame:IsDescendantOf(game) do clickUIPath("Players.LocalPlayer.PlayerGui.Smelt.Frame.SmeltAllPack") task.wait(2) end end) end
end
aSmelt.MouseButton1Click:Connect(function() setSmeltState(not isSmelt) if SaveState then SaveState() end end)

local aPotion = Instance.new("TextButton", aFrame) aPotion.Size, aPotion.Position, aPotion.BackgroundColor3, aPotion.TextColor3, aPotion.Text, aPotion.Font, aPotion.TextSize, aPotion.BorderSizePixel = U2(0,240,0,40), U2(0.5,-120,0,70), C3(50,50,50), C3(200,200,200), "[ ] Auto-Craft Potions (Max)", F_GB, 13, 0
local function setPotionState(state)
    isPotion = state aPotion.Text, aPotion.BackgroundColor3 = isPotion and "[X] Auto-Craft Potions (Max)" or "[ ] Auto-Craft Potions (Max)", isPotion and C3(40,200,120) or C3(50,50,50)
    if isPotion then task.spawn(function() while isPotion and mFrame:IsDescendantOf(game) do clickUIPath("Players.LocalPlayer.PlayerGui.Potions.Frame.CraftMax") task.wait(5) end end) end
end
aPotion.MouseButton1Click:Connect(function() setPotionState(not isPotion) if SaveState then SaveState() end end)

local aClaim = Instance.new("TextButton", aFrame) aClaim.Size, aClaim.Position, aClaim.BackgroundColor3, aClaim.TextColor3, aClaim.Text, aClaim.Font, aClaim.TextSize, aClaim.BorderSizePixel = U2(0,240,0,40), U2(0.5,-120,0,120), C3(50,50,50), C3(200,200,200), "[ ] Auto-Claim Group/Daily", F_GB, 13, 0
local function setClaimState(state)
    isClaim = state aClaim.Text, aClaim.BackgroundColor3 = isClaim and "[X] Auto-Claim Group/Daily" or "[ ] Auto-Claim Group/Daily", isClaim and C3(40,200,120) or C3(50,50,50)
    if isClaim then task.spawn(function() while isClaim and mFrame:IsDescendantOf(game) do
        clickUIPath("Players.LocalPlayer.PlayerGui.Rewards.Frame.Claim")
        clickUIPath("Players.LocalPlayer.PlayerGui.LeaveRewards.Main.Claim")
        clickUIPath("Players.LocalPlayer.PlayerGui.AdRewards.Frame.Claim")
        task.wait(10)
    end end) end
end
aClaim.MouseButton1Click:Connect(function() setClaimState(not isClaim) if SaveState then SaveState() end end)

local fPnl = Instance.new("Frame", fFrame) fPnl.Size, fPnl.Position, fPnl.BackgroundColor3, fPnl.BorderSizePixel = U2(1,-20,1,-20), U2(0,10,0,10), C3(30,30,30), 0
local fDelInp = mkInp(fPnl, "Loop Delay (Seconds)", "3", 50, -120) fDelInp.FocusLost:Connect(function() if SaveConfig then SaveConfig() end end)
local fTglBtn = Instance.new("TextButton", fPnl) fTglBtn.Size, fTglBtn.Position, fTglBtn.BackgroundColor3, fTglBtn.TextColor3, fTglBtn.Text, fTglBtn.Font, fTglBtn.TextSize, fTglBtn.BorderSizePixel = U2(0,240,0,40), U2(0.5,-120,0,120), C3(200,40,40), C3(255,255,255), "Stop Auto-Fish", F_GB, 14, 0
local remotes = RS:FindFirstChild("Remotes")
local function getRemote(name)
    return remotes and remotes:FindFirstChild(name) or nil
end

local RaidConfig, CardConfig
pcall(function() RaidConfig = require(RS.Modules.Config.Core.RaidConfig) end)
pcall(function() CardConfig = require(RS.Modules.Config.Core.CardConfig) end)

local raidPanel = Instance.new("Frame", raidFrame)
raidPanel.Size, raidPanel.Position, raidPanel.BackgroundColor3, raidPanel.BorderSizePixel = U2(1, -20, 1, -20), U2(0, 10, 0, 10), C3(30, 30, 30), 0
local raidPacks = RaidConfig and RaidConfig.ActiveRaids or {}
local raidStatus = Instance.new("TextLabel", raidPanel)
raidStatus.Size, raidStatus.Position, raidStatus.BackgroundColor3, raidStatus.TextColor3, raidStatus.Text, raidStatus.Font, raidStatus.TextSize = U2(1, -20, 0, 28), U2(0, 10, 0, 12), C3(20, 20, 20), C3(200, 200, 200), "Status: Idle", F_GM, 12
local raidBtn = Instance.new("TextButton", raidPanel)
raidBtn.Size, raidBtn.Position, raidBtn.BackgroundColor3, raidBtn.TextColor3, raidBtn.Text, raidBtn.Font, raidBtn.TextSize = U2(0, 260, 0, 40), U2(0.5, -130, 0, 190), C3(40, 200, 120), C3(255, 255, 255), "Start Auto-Raid", F_GB, 14
local raidPackList = Instance.new("ScrollingFrame", raidPanel)
raidPackList.Size, raidPackList.Position, raidPackList.BackgroundColor3, raidPackList.BorderSizePixel, raidPackList.ScrollBarThickness = U2(1, -20, 1, -250), U2(0, 10, 0, 240), C3(22, 22, 22), 0, 6
raidPackList.CanvasSize = U2(0, 0, 0, #raidPacks * 34)
local raidPackLayout = Instance.new("UIListLayout", raidPackList)
raidPackLayout.SortOrder = Enum.SortOrder.LayoutOrder
local raidSelectedPacks, raidPackButtons = {}, {}

local function raidProgress(packName)
    return math.max(0, tonumber(getLiveData("RaidsDefeated", "Packs", packName)) or 0)
end

local function refreshRaidPackRows()
    for _, packName in ipairs(raidPacks) do
        local button = raidPackButtons[packName]
        if button then
            local count = raidProgress(packName)
            button.Text = (raidSelectedPacks[packName] and "[X] " or "[ ] ") .. packName .. "  " .. tostring(math.min(count, 9)) .. "/9"
            button.TextColor3 = count >= 9 and C3(150, 150, 150) or (raidSelectedPacks[packName] and C3(40, 220, 130) or C3(210, 210, 210))
        end
    end
end

for index, packName in ipairs(raidPacks) do
    local packBtn = Instance.new("TextButton", raidPackList)
    packBtn.Size, packBtn.LayoutOrder, packBtn.BackgroundColor3, packBtn.TextColor3, packBtn.Text, packBtn.Font, packBtn.TextSize, packBtn.BorderSizePixel = U2(1, -8, 0, 32), index, C3(35, 35, 35), C3(210, 210, 210), "[ ] " .. packName .. "  0/9", F_GM, 12, 0
    raidPackButtons[packName] = packBtn
    packBtn.MouseButton1Click:Connect(function()
        if raidProgress(packName) >= 9 then return end
        raidSelectedPacks[packName] = not raidSelectedPacks[packName]
        refreshRaidPackRows()
    end)
end
local raidRunning, raidRun = false, 0

local function getRaidQueue()
    local queue = {}
    for _, packName in ipairs(raidPacks) do
        if raidSelectedPacks[packName] then queue[#queue + 1] = packName end
    end
    return queue
end

local mutationRank = { Regular = 1, Gold = 2, Emerald = 3, Void = 4, Diamond = 5, Rainbow = 6 }
local function getBestRaidTeam(packName)
    local team = {}
    local candidates = {}
    local packData = CardConfig and CardConfig.Packs and CardConfig.Packs[packName]
    if not packData or type(packData.List) ~= "table" then return team end
    for cardName in pairs(packData.List) do
        local record = getLiveRecord("Cards", cardName)
        if record then
            candidates[#candidates + 1] = {
                name = cardName,
                grade = GRADE_RANK[exactGrade(record.Grade) or "F"] or 0,
                level = tonumber(record.Level) or 0,
                star = tonumber(record.Star) or 0,
                mutation = mutationRank[record.Mutation or "Regular"] or 1,
                power = tonumber(record.Damage or record.DPS or record.Power) or 0,
            }
        end
    end
    table.sort(candidates, function(a, b)
        if a.power ~= b.power then return a.power > b.power end
        if a.grade ~= b.grade then return a.grade > b.grade end
        if a.level ~= b.level then return a.level > b.level end
        if a.star ~= b.star then return a.star > b.star end
        return a.mutation > b.mutation
    end)
    for index = 1, math.min(3, #candidates) do
        team[index] = candidates[index].name
    end
    return team
end

refreshRaidPackRows()
task.spawn(function()
    while raidPanel:IsDescendantOf(game) do
        refreshRaidPackRows()
        task.wait(2)
    end
end)

local function setRaidState(state)
    raidRunning, raidRun = state, raidRun + 1
    local myRun = raidRun
    raidBtn.Text, raidBtn.BackgroundColor3 = raidRunning and "Stop Auto-Raid" or "Start Auto-Raid", raidRunning and C3(200, 40, 40) or C3(40, 200, 120)
    if not raidRunning then
        raidStatus.Text = "Status: Idle"
        return
    end
    local raidRemote = getRemote("Raid")
    if not raidRemote then
        raidRunning = false
        raidBtn.Text = "Raid remote missing"
        return
    end
    local queue = getRaidQueue()
    if #queue == 0 then
        raidRunning = false
        raidBtn.Text = "Select a raid pack"
        return
    end
    task.spawn(function()
        -- One raid clear is not the end of the queue. Stay up, re-read the live
        -- vote/raid clock, and keep the first selected pack that is still under 9/9.
        local joinedKey, joinedPack, progressAtJoin = nil, nil, nil
        local fallbackKey, fallbackStart = nil, nil
        while raidRunning and raidRun == myRun and mFrame:IsDescendantOf(game) do
            refreshRaidPackRows()

            local packName = nil
            for _, name in ipairs(raidPacks) do
                if raidSelectedPacks[name] and raidProgress(name) < 9 then
                    packName = name
                    break
                end
            end
            if not packName then
                raidRunning = false
                raidStatus.Text = "Status: All selected raids are 9/9"
                raidBtn.Text, raidBtn.BackgroundColor3 = "Start Auto-Raid", C3(40, 200, 120)
                break
            end

            local now = workspace:GetServerTimeNow()
            local voteAttr = workspace:GetAttribute("RaidVoteTime")
            local voteTime = tonumber(voteAttr)
            local activePack = workspace:GetAttribute("RaidPack")
            local raidStart = tonumber(workspace:GetAttribute("RaidStart"))
            local raidDuration = (RaidConfig and RaidConfig.RaidDuration or 460) + (RaidConfig and RaidConfig.GracePeriod or 10)
            local progress = raidProgress(packName)

            -- RaidStart is normally a server start timestamp. If it is missing, keep our own
            -- clock from the moment this pack became active so the countdown still shows.
            if activePack ~= nil and raidStart == nil then
                local key = tostring(activePack)
                if fallbackKey ~= key or fallbackStart == nil then
                    fallbackKey = key
                    fallbackStart = now
                end
                raidStart = fallbackStart
            else
                fallbackKey, fallbackStart = nil, nil
            end

            local cycleKey = raidStart and (tostring(activePack) .. ":" .. tostring(raidStart)) or nil
            local raidLeft = nil
            if raidStart then
                local fromStart = (raidStart + raidDuration) - now
                if fromStart > 0 and fromStart <= raidDuration + 30 then
                    raidLeft = fromStart
                elseif raidStart > now and (raidStart - now) <= raidDuration + 5 then
                    raidLeft = raidStart - now
                elseif raidStart >= 0 and raidStart <= raidDuration + 5 then
                    raidLeft = raidStart
                else
                    raidLeft = fromStart
                end
            end
            local raidGoing = activePack ~= nil and raidLeft ~= nil and raidLeft > 0
            local finishedThisCycle = joinedKey ~= nil and cycleKey == joinedKey and joinedPack == packName and progressAtJoin ~= nil and progress > progressAtJoin

            if raidGoing and not finishedThisCycle then
                local remaining = math.max(0, math.ceil(raidLeft))
                if tostring(activePack) == tostring(packName) then
                    if joinedKey ~= cycleKey then
                        local team = getBestRaidTeam(packName)
                        if #team == 0 then
                            raidStatus.Text = "No owned cards for " .. packName .. " (" .. tostring(remaining) .. "s)"
                            task.wait(2)
                        else
                            raidStatus.Text = "Joining " .. packName .. ": " .. table.concat(team, ", ")
                            local okJoin, joinError = pcall(function() raidRemote:FireServer("Join", team) end)
                            if okJoin then
                                joinedKey = cycleKey
                                joinedPack = packName
                                progressAtJoin = progress
                                raidStatus.Text = "Raid active: " .. packName .. " (" .. tostring(remaining) .. "s) " .. tostring(progress) .. "/9"
                            else
                                raidStatus.Text = "Raid join failed: " .. tostring(joinError)
                            end
                            task.wait(0.5)
                        end
                    else
                        raidStatus.Text = "Raid active: " .. packName .. " (" .. tostring(remaining) .. "s) " .. tostring(progress) .. "/9"
                        task.wait(0.5)
                    end
                else
                    raidStatus.Text = "Raid timer: " .. tostring(activePack) .. " (" .. tostring(remaining) .. "s). Next " .. packName .. " " .. tostring(progress) .. "/9"
                    task.wait(0.5)
                end
            elseif voteTime ~= nil then
                local voteRemaining = math.ceil(math.max(60 - (now - voteTime), 0))
                raidStatus.Text = "Voting for " .. packName .. " (" .. tostring(progress) .. "/9, " .. tostring(voteRemaining) .. "s)"
                pcall(function() raidRemote:FireServer("Vote", packName) end)
                task.wait(0.5)
            else
                -- Cycle is over. Keep the button on and wait for the next vote/raid clock.
                -- Only forget the join once this pack is no longer the active raid.
                if activePack == nil or tostring(activePack) ~= tostring(joinedPack) then
                    joinedKey, joinedPack, progressAtJoin = nil, nil, nil
                end
                if joinedKey ~= nil then
                    local remaining = raidLeft and math.max(0, math.ceil(raidLeft)) or 0
                    raidStatus.Text = "Raid complete. " .. packName .. " " .. tostring(progress) .. "/9. Timer: " .. tostring(remaining) .. "s"
                else
                    raidStatus.Text = "Waiting for raid timer. Next: " .. packName .. " " .. tostring(progress) .. "/9"
                end
                task.wait(0.5)
            end
        end
    end)
end
raidBtn.MouseButton1Click:Connect(function() setRaidState(not raidRunning) end)

local mangaPanel = Instance.new("Frame", mangaFrame)
mangaPanel.Size, mangaPanel.Position, mangaPanel.BackgroundColor3, mangaPanel.BorderSizePixel = U2(1, -20, 1, -20), U2(0, 10, 0, 10), C3(30, 30, 30), 0
local mangaStatus = Instance.new("TextLabel", mangaPanel)
mangaStatus.Size, mangaStatus.Position, mangaStatus.BackgroundColor3, mangaStatus.TextColor3, mangaStatus.Text, mangaStatus.Font, mangaStatus.TextSize = U2(1, -20, 0, 42), U2(0, 10, 0, 12), C3(20, 20, 20), C3(200, 200, 200), "Requires SS+, level 30, Rainbow", F_GM, 12
local mangaBtn = Instance.new("TextButton", mangaPanel)
mangaBtn.Size, mangaBtn.Position, mangaBtn.BackgroundColor3, mangaBtn.TextColor3, mangaBtn.Text, mangaBtn.Font, mangaBtn.TextSize = U2(0, 260, 0, 40), U2(0.5, -130, 0, 80), C3(40, 200, 120), C3(255, 255, 255), "Start Auto-Manga", F_GB, 14
local mangaRunning, mangaRun = false, 0

local function setMangaState(state)
    mangaRunning, mangaRun = state, mangaRun + 1
    local myRun = mangaRun
    mangaBtn.Text, mangaBtn.BackgroundColor3 = mangaRunning and "Stop Auto-Manga" or "Start Auto-Manga", mangaRunning and C3(200, 40, 40) or C3(40, 200, 120)
    if not mangaRunning then
        mangaStatus.Text = "Status: Idle"
        return
    end
    local raidRemote = getRemote("Raid")
    if not raidRemote or not CardConfig then
        mangaRunning = false
        mangaBtn.Text = "Manga data unavailable"
        return
    end
    task.spawn(function()
        while mangaRunning and mangaRun == myRun and mFrame:IsDescendantOf(game) do
            local tokens = tonumber(getLiveData("MangaTokens")) or 0
            local upgraded = 0
            for packName, packData in pairs(CardConfig.Packs or {}) do
                if not mangaRunning or mangaRun ~= myRun then break end
                if type(packData) == "table" and type(packData.List) == "table" then
                    local raids = tonumber(getLiveData("RaidsDefeated", "Packs", packName)) or 0
                    for cardName, cardInfo in pairs(packData.List) do
                        local record = getLiveRecord("Cards", cardName)
                        local level = record and tonumber(record.Level) or 0
                        local grade = record and exactGrade(record.Grade)
                        local cost = math.round((tonumber(cardInfo.Layout) or 0) * 5)
                        if record and record.Manga ~= true and level >= (RaidConfig and RaidConfig.LevelRequirement or 30) and grade and (GRADE_RANK[grade] or 0) >= (GRADE_RANK.SS or 9) and record.Mutation == "Rainbow" and raids >= (tonumber(cardInfo.Layout) or math.huge) and tokens >= cost then
                            mangaStatus.Text = "Upgrading " .. cardName .. " (" .. packName .. ")"
                            pcall(function() raidRemote:FireServer("Manga", cardName) end)
                            upgraded = upgraded + 1
                            task.wait(1)
                            tokens = tonumber(getLiveData("MangaTokens")) or math.max(0, tokens - cost)
                        end
                    end
                end
            end
            mangaStatus.Text = upgraded > 0 and ("Upgraded " .. upgraded .. " card(s)") or "No eligible cards found"
            task.wait(5)
        end
    end)
end
mangaBtn.MouseButton1Click:Connect(function() setMangaState(not mangaRunning) end)

local isFish, fEvt = false, getRemote("Fish")
local function fishLoop()
    if not fEvt then return end
    task.spawn(function()
        while isFish and mFrame:IsDescendantOf(game) do
            local d = tonumber(fDelInp.Text) or 3
            pcall(function() fEvt:FireServer("CastRod", 0.9999) end)
            task.wait(1)
            if not isFish then break end
            pcall(function() fEvt:FireServer("FishCaught") end)
            task.wait(d)
        end
    end)
end
local function setFishState(state)
    isFish = state and fEvt ~= nil
    fTglBtn.Text = fEvt and (isFish and "Stop Auto-Fish" or "Start Auto-Fish") or "ERR: Fish Remote Missing"
    fTglBtn.BackgroundColor3 = isFish and C3(200,40,40) or C3(40,200,120)
    if isFish then fishLoop() end
end
setFishState(false)
fTglBtn.MouseButton1Click:Connect(function() setFishState(not isFish) if SaveState then SaveState() end end)

local gPnl = Instance.new("Frame", gFrame) gPnl.Size, gPnl.Position, gPnl.BackgroundColor3, gPnl.BorderSizePixel = U2(1,-20,1,-20), U2(0,10,0,10), C3(30,30,30), 0
local gmBtn = Instance.new("TextButton", gPnl) gmBtn.Size, gmBtn.Position, gmBtn.BackgroundColor3, gmBtn.TextColor3, gmBtn.Text, gmBtn.Font, gmBtn.TextSize, gmBtn.BorderSizePixel = U2(0,240,0,40), U2(0.5,-120,0,100), C3(40,200,120), C3(255,255,255), "Start Auto-Gems", F_GB, 14, 0
local gmStat = Instance.new("TextLabel", gPnl) gmStat.Size, gmStat.Position, gmStat.BackgroundTransparency, gmStat.TextColor3, gmStat.Text, gmStat.Font, gmStat.TextSize = U2(0,240,0,30), U2(0.5,-120,0,160), 1, C3(200,200,200), "Status: Idle", F_GM, 12
local isGems, GalEvt, CardEvt = false, getRemote("Gallery"), getRemote("Card")
local function setGemsState(state)
    isGems = state and GalEvt ~= nil and CardEvt ~= nil
    gmBtn.Text, gmBtn.BackgroundColor3 = (GalEvt and CardEvt) and (isGems and "Stop Auto-Gems" or "Start Auto-Gems") or "ERR: Gallery/Card Remote Missing", isGems and C3(200,40,40) or C3(40,200,120)
    if isGems then task.spawn(function()
        while isGems and mFrame:IsDescendantOf(game) do
            for p=1,13 do if not isGems then break end gmStat.Text = "Sweeping Page "..p.."/13" for s=1,10 do pcall(function() GalEvt:FireServer("Collect", tostring(s)) end) end if p<13 then pcall(function() CardEvt:FireServer("Page", "RightArrowFigurine") end) task.wait(0.5) end end
            for b=1,12 do pcall(function() CardEvt:FireServer("Page", "LeftArrowFigurine") end) task.wait(0.1) end
            for w=20,1,-1 do if not isGems then break end gmStat.Text = "Waiting "..w.."s..." task.wait(1) end
        end gmStat.Text = "Status: Idle"
    end) end
end
gmBtn.MouseButton1Click:Connect(function() setGemsState(not isGems) if SaveState then SaveState() end end)

local hkDel = mkInp(hFrame, "Attack->Kill Delay", "0.3", 10, -250, 220) local hnDel = mkInp(hFrame, "Next Target Gap", "0.1", 70, -250, 220)
local hmUnits = mkInp(hFrame, "Max Units", "24", 130, -250, 220) local hwDel = mkInp(hFrame, "Wave Reset Delay", "1", 10, 30, 220)
local hzInp = mkInp(hFrame, "Zone Sizes", "4,6,8,6", 70, 30, 220) local hsInp = mkInp(hFrame, "Walk Speed (Studs/s)", "60", 130, 30, 220)
for _, box in ipairs({hkDel, hnDel, hmUnits, hwDel, hzInp, hsInp}) do box.FocusLost:Connect(function() if SaveConfig then SaveConfig() end end) end

local htTPBtn = Instance.new("TextButton", hFrame) htTPBtn.Size, htTPBtn.Position, htTPBtn.BackgroundColor3, htTPBtn.TextColor3, htTPBtn.Text, htTPBtn.Font, htTPBtn.TextSize, htTPBtn.BorderSizePixel = U2(0,240,0,30), U2(0.5,-120,0,190), C3(40,200,120), C3(255,255,255), "[X] Smart Walk To Zones", F_GB, 12, 0
local hBtn = Instance.new("TextButton", hFrame) hBtn.Size, hBtn.Position, hBtn.BackgroundColor3, hBtn.TextColor3, hBtn.Text, hBtn.Font, hBtn.TextSize, hBtn.BorderSizePixel = U2(0,240,0,40), U2(0.5,-120,0,230), C3(40,200,120), C3(255,255,255), "Start Halloween Battle", F_GB, 14, 0
local hStat = Instance.new("TextLabel", hFrame) hStat.Size, hStat.Position, hStat.BackgroundTransparency, hStat.TextColor3, hStat.Text, hStat.Font, hStat.TextSize = U2(0,240,0,25), U2(0.5,-120,0,280), 1, C3(200,200,200), "Status: Idle", F_GM, 12
local isHal, isTP, HalEvt = false, true, getRemote("Halloween")
htTPBtn.MouseButton1Click:Connect(function() isTP = not isTP htTPBtn.Text, htTPBtn.BackgroundColor3 = isTP and "[X] Smart Walk To Zones" or "[ ] Smart Walk To Zones", isTP and C3(40,200,120) or C3(50,50,50) if SaveConfig then SaveConfig() end end)
local function tweenTo(targetCFrame) local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") if not hrp then return end local dist = (hrp.Position - targetCFrame.Position).Magnitude local tSpeed = math.max(1, tonumber(hsInp.Text) or 60) local tw = TS:Create(hrp, TweenInfo.new(dist / tSpeed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}) tw:Play() tw.Completed:Wait() end
local function setHalState(state)
    if not HalEvt then hBtn.Text = "ERR: NOT FOUND" return end
    isHal = state hBtn.Text, hBtn.BackgroundColor3 = isHal and "Stop Halloween Battle" or "Start Halloween Battle", isHal and C3(200,40,40) or C3(40,200,120)
    if isHal then task.spawn(function()
        while isHal and mFrame:IsDescendantOf(game) do
            local killDelay, nextGap, mx, waveDelay = tonumber(hkDel.Text) or 0.3, tonumber(hnDel.Text) or 0.1, tonumber(hmUnits.Text) or 24, tonumber(hwDel.Text) or 1
            local zList = {} for s in string.gmatch(hzInp.Text, "%d+") do table.insert(zList, tonumber(s)) end if #zList == 0 then zList = {mx} end
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local origCF, unitCounter = hrp and hrp.CFrame, 1
            for zIdx, zSize in ipairs(zList) do
                if not isHal or unitCounter > mx then break end
                local startUnit, endUnit = unitCounter, math.min(unitCounter + zSize - 1, mx)
                local midUnit = math.floor((startUnit + endUnit) / 2)
                if isTP and hrp then
                    local mobFol = workspace:FindFirstChild("Client") and workspace.Client:FindFirstChild("HalloweenEnemies")
                    local mob = mobFol and mobFol:FindFirstChild(tostring(midUnit))
                    local tpPart = mob and (mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart"))
                    if tpPart then hStat.Text = "Walking to Zone " .. zIdx .. "..." tweenTo(tpPart.CFrame * CFrame.new(0, 0, 5)) end
                end
                for i = startUnit, endUnit do
                    if not isHal or i > mx then break end
                    hStat.Text = "Zone " .. zIdx .. " | Unit " .. i
                    HalEvt:FireServer("Attack", i) task.wait(killDelay)
                    if not isHal then break end
                    HalEvt:FireServer("Kill", i) task.wait(nextGap)
                end
                unitCounter = endUnit + 1
            end
            if isTP and hrp and origCF then tweenTo(origCF) end
            task.wait(waveDelay)
        end hStat.Text = "Status: Idle"
    end) end
end
hBtn.MouseButton1Click:Connect(function() setHalState(not isHal) if SaveState then SaveState() end end)

-- ==========================================
-- 6. STRICT CASH-ONLY GRADER
-- ==========================================
local GraderAPI = {}

local function bGrader(pFrame, sData, pcData, rName, aName, gList, gRanks)
    local lPnl = Instance.new("Frame", pFrame) lPnl.Size, lPnl.Position, lPnl.BackgroundColor3, lPnl.BorderSizePixel = U2(0,230,1,-20), U2(0,10,0,10), C3(30,30,30), 0
    local saBtn = Instance.new("TextButton", lPnl) saBtn.Size, saBtn.BackgroundColor3, saBtn.TextColor3, saBtn.Text, saBtn.Font, saBtn.TextSize, saBtn.BorderSizePixel = U2(0.5,0,0,25), C3(40,40,40), C3(255,255,255), "Select All", F_GM, 12, 0
    local daBtn = Instance.new("TextButton", lPnl) daBtn.Size, daBtn.Position, daBtn.BackgroundColor3, daBtn.TextColor3, daBtn.Text, daBtn.Font, daBtn.TextSize, daBtn.BorderSizePixel = U2(0.5,0,0,25), U2(0.5,0,0,0), C3(40,40,40), C3(255,255,255), "Deselect All", F_GM, 12, 0
    local pScr = Instance.new("ScrollingFrame", lPnl) pScr.Size, pScr.Position, pScr.BackgroundColor3, pScr.ScrollBarThickness, pScr.BorderSizePixel = U2(1,0,1,-25), U2(0,0,0,25), C3(25,25,25), 6, 0
    local sLyt = Instance.new("UIListLayout", pScr) sLyt.SortOrder = Enum.SortOrder.LayoutOrder sLyt:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() pScr.CanvasSize = U2(0,0,0,sLyt.AbsoluteContentSize.Y) end)
    
    local SData = {}
    local CardBtnMap = {}

    local function uncheckCard(packName, cardName)
        if SData[packName] and SData[packName].items[cardName] ~= nil then
            SData[packName].items[cardName] = false
            local btn = CardBtnMap[cardName]
            if btn then
                local cg = findGradeInUI(cardName)
                btn.Text = "   ↳ [ ] " .. cardName .. (cg and " [" .. cg .. "]" or " [?]")
                btn.TextColor3 = cg and C3(200, 200, 200) or C3(100, 100, 100)
            end
            local anyLeft = false
            for _, v in pairs(SData[packName].items) do if v then anyLeft = true break end end
            SData[packName].isSelected = anyLeft
            SData[packName].cBtn.Text = (anyLeft and " [X] " or " [ ] ") .. packName
            SData[packName].cBtn.TextColor3 = anyLeft and C3(40, 200, 120) or C3(200, 200, 200)
            if SaveState then SaveState() end
        end
    end

    for lIdx, pD in ipairs(sData) do
        local pN = pD.Name SData[pN] = { isSelected = false, items = {} }
        local pC = Instance.new("Frame", pScr) pC.Size, pC.BackgroundTransparency, pC.LayoutOrder, pC.AutomaticSize = U2(1,0,0,25), 1, lIdx, Enum.AutomaticSize.Y
        local cLyt = Instance.new("UIListLayout", pC) cLyt.SortOrder = Enum.SortOrder.LayoutOrder
        local pH = Instance.new("Frame", pC) pH.Size, pH.BackgroundColor3, pH.BorderSizePixel, pH.LayoutOrder = U2(1,0,0,25), C3(30,30,30), 0, 1
        local eBtn = Instance.new("TextButton", pH) eBtn.Size, eBtn.BackgroundColor3, eBtn.TextColor3, eBtn.Text, eBtn.Font, eBtn.BorderSizePixel = U2(0,25,0,25), C3(35,35,35), C3(200,200,200), "+", F_GB, 0
        local cBtn = Instance.new("TextButton", pH) cBtn.Size, cBtn.Position, cBtn.BackgroundTransparency, cBtn.TextColor3, cBtn.Text, cBtn.Font, cBtn.TextSize, cBtn.TextXAlignment = U2(1,-25,1,0), U2(0,25,0,0), 1, C3(200,200,200), " [ ] "..pN, F_GM, 12, Enum.TextXAlignment.Left
        local iF = Instance.new("Frame", pC) iF.Size, iF.BackgroundTransparency, iF.Visible, iF.LayoutOrder, iF.AutomaticSize = U2(1,0,0,0), 1, false, 2, Enum.AutomaticSize.Y
        Instance.new("UIListLayout", iF) local iBtns = {} SData[pN].cBtn = cBtn
        if pcData[pN] then for _, iN in ipairs(pcData[pN]) do
            SData[pN].items[iN] = false
            local ib = Instance.new("TextButton", iF) ib.Size, ib.BackgroundColor3, ib.TextColor3, ib.Text, ib.Font, ib.TextSize, ib.TextXAlignment, ib.BorderSizePixel = U2(1,0,0,20), C3(20,20,20), C3(150,150,150), "   ↳ [ ] "..iN, F_GM, 11, Enum.TextXAlignment.Left, 0
            CardBtnMap[iN] = ib
            ib.MouseButton1Click:Connect(function()
                local s = not SData[pN].items[iN] SData[pN].items[iN] = s
                local cg = findGradeInUI(iN) ib.Text = "   ↳ "..(s and "[X] " or "[ ] ")..iN..(cg and " ["..cg.."]" or " [?]") ib.TextColor3 = s and C3(40,200,120) or (cg and C3(200, 200, 200) or C3(100, 100, 100))
                if SaveState then SaveState() end
            end)
            table.insert(iBtns, {btn=ib, name=iN, update = function(s) SData[pN].items[iN] = s local cg = findGradeInUI(iN) ib.Text = "   ↳ "..(s and "[X] " or "[ ] ")..iN..(cg and " ["..cg.."]" or " [?]") ib.TextColor3 = s and C3(40,200,120) or (cg and C3(200, 200, 200) or C3(100, 100, 100)) end})
            table.insert(AllItemButtons, {btn=ib, name=iN, packName=pN, selData=SData})
        end end
        eBtn.MouseButton1Click:Connect(function() iF.Visible = not iF.Visible eBtn.Text = iF.Visible and "-" or "+" end)
        local function updUI(s)
            SData[pN].isSelected = s cBtn.Text = (s and " [X] " or " [ ] ")..pN cBtn.TextColor3 = s and C3(40,200,120) or C3(200,200,200)
            for _, d in ipairs(iBtns) do d.update(s) end
        end
        cBtn.MouseButton1Click:Connect(function() updUI(not SData[pN].isSelected) if SaveState then SaveState() end end)
        SData[pN].updateUI = updUI
    end
    saBtn.MouseButton1Click:Connect(function() for _, pd in pairs(SData) do pd.updateUI(true) end if SaveState then SaveState() end end)
    daBtn.MouseButton1Click:Connect(function() for _, pd in pairs(SData) do pd.updateUI(false) end if SaveState then SaveState() end end)
    
    local rPnl = Instance.new("Frame", pFrame) rPnl.Size, rPnl.Position, rPnl.BackgroundTransparency = U2(1,-250,1,-20), U2(0,250,0,10), 1
    local sLbl = Instance.new("TextLabel", rPnl) sLbl.Size, sLbl.BackgroundColor3, sLbl.TextColor3, sLbl.Text, sLbl.Font, sLbl.TextSize, sLbl.BorderSizePixel = U2(1,0,0,25), C3(20,20,20), C3(200,200,200), "Status: Idle", F_GM, 12, 0
    
    local selG = "UR"
    local tgBtn = Instance.new("TextButton", rPnl) tgBtn.Size, tgBtn.Position, tgBtn.BackgroundColor3, tgBtn.TextColor3, tgBtn.Font, tgBtn.TextSize, tgBtn.BorderSizePixel = U2(1,0,0,35), U2(0,0,0,40), C3(40,40,40), C3(255,200,0), F_GB, 14, 0
    local gScr = Instance.new("ScrollingFrame", rPnl) gScr.Size, gScr.Position, gScr.BackgroundColor3, gScr.ScrollBarThickness, gScr.Visible, gScr.ZIndex, gScr.BorderSizePixel = U2(1,0,0,120), U2(0,0,0,75), C3(20,20,20), 6, false, 10, 0
    local gY = 0 tgBtn.Text = "Target: "..selG
    for _, g in ipairs(gList) do
        local b = Instance.new("TextButton", gScr) b.Size, b.Position, b.BackgroundColor3, b.TextColor3, b.Text, b.Font, b.ZIndex, b.BorderSizePixel = U2(1,-10,0,30), U2(0,0,0,gY), C3(30,30,30), C3(255,255,255), g, F_GM, 11, 0
        b.MouseButton1Click:Connect(function() selG = g tgBtn.Text = "Target: "..g gScr.Visible = false if SaveConfig then SaveConfig() end end) gY = gY+30
    end
    gScr.CanvasSize = U2(0,0,0,gY)
    tgBtn.MouseButton1Click:Connect(function() gScr.Visible = not gScr.Visible end)
    
    local cTypeLbl = Instance.new("TextLabel", rPnl) cTypeLbl.Size, cTypeLbl.Position, cTypeLbl.BackgroundColor3, cTypeLbl.TextColor3, cTypeLbl.Text, cTypeLbl.Font, cTypeLbl.TextSize, cTypeLbl.BorderSizePixel = U2(1,0,0,30), U2(0,0,0,100), C3(40,120,60), C3(255,255,255), "Currency: Cash Only", F_GB, 13, 0
    local anBtn = Instance.new("TextButton", rPnl) anBtn.Size, anBtn.Position, anBtn.BackgroundColor3, anBtn.TextColor3, anBtn.Text, anBtn.Font, anBtn.TextSize, anBtn.BorderSizePixel = U2(1,0,0,30), U2(0,0,0,140), C3(40,200,120), C3(255,255,255), "[X] Auto Next Item", F_GB, 13, 0
    local apBtn = Instance.new("TextButton", rPnl) apBtn.Size, apBtn.Position, apBtn.BackgroundColor3, apBtn.TextColor3, apBtn.Text, apBtn.Font, apBtn.TextSize, apBtn.BorderSizePixel = U2(1,0,0,30), U2(0,0,0,180), C3(40,200,120), C3(255,255,255), "[X] Auto Next Pack", F_GB, 13, 0
    
    local fBtn = Instance.new("TextButton", rPnl) fBtn.Size, fBtn.Position, fBtn.BackgroundColor3, fBtn.TextColor3, fBtn.Text, fBtn.Font, fBtn.TextSize, fBtn.BorderSizePixel = U2(1,0,0,30), U2(0,0,0,220), C3(120,40,120), C3(255,255,255), "Filter Missing Grades", F_GB, 13, 0
    fBtn.MouseButton1Click:Connect(function()
        local tr = gRanks[selG] or 10
        for pN, pD in pairs(SData) do
            local hasMiss = false
            for iN, _ in pairs(pD.items) do
                local cG = findGradeInUI(iN)
                local cr = (cG and gRanks[cG]) or 0
                if cr < tr then pD.items[iN] = true hasMiss = true else pD.items[iN] = false end
            end
            pD.isSelected = hasMiss pD.updateUI(hasMiss)
        end
        if SaveState then SaveState() end
    end)
    
    local dInp = mkInp(rPnl, "Delay (ms)", "300", 255, 0) dInp.Size = U2(1,0,0,30) dInp.Position = U2(0,0,0,275)
    dInp.FocusLost:Connect(function() if SaveConfig then SaveConfig() end end)
    local sgBtn = Instance.new("TextButton", rPnl) sgBtn.Size, sgBtn.Position, sgBtn.BackgroundColor3, sgBtn.TextColor3, sgBtn.Text, sgBtn.Font, sgBtn.TextSize, sgBtn.BorderSizePixel = U2(1,0,0,40), U2(0,0,0,315), C3(40,200,120), C3(255,255,255), "Start Grader", F_GB, 14, 0
    
    local anC, anP = true, true
    anBtn.MouseButton1Click:Connect(function() anC = not anC anBtn.Text, anBtn.BackgroundColor3 = anC and "[X] Auto Next Item" or "[ ] Auto Next Item", anC and C3(40,200,120) or C3(50,50,50) if SaveConfig then SaveConfig() end end)
    apBtn.MouseButton1Click:Connect(function() anP = not anP apBtn.Text, apBtn.BackgroundColor3 = anP and "[X] Auto Next Pack" or "[ ] Auto Next Pack", anP and C3(40,200,120) or C3(50,50,50) if SaveConfig then SaveConfig() end end)
    
    local isG, rEvt = false, nil
    local waitingRoll = false
    local rollGrade = nil
    rEvt = getRemote(rName)
    
    if rEvt then rEvt.OnClientEvent:Connect(function(...)
        if not waitingRoll then return end
        local args = { ... }
        local best, bestR = nil, -1
        local function consider(g)
            if g and (gRanks[g] or 0) > bestR then best = g bestR = gRanks[g] end
        end
        for _, arg in ipairs(args) do
            if type(arg) == "table" then
                if arg.Grade then consider(exactGrade(arg.Grade)) end
                if arg.grade then consider(exactGrade(arg.grade)) end
                if arg.Result then consider(exactGrade(arg.Result)) end
            elseif type(arg) == "string" then consider(exactGrade(arg)) end
        end
        if best then rollGrade = best end
    end) end
    
    local function setGraderRunning(state)
        if not rEvt then sgBtn.Text = "ERR" return end 
        if not state then 
            isG = false waitingRoll = false sLbl.Text = "Idle" sgBtn.Text, sgBtn.BackgroundColor3 = "Start Grader", C3(40,200,120) 
            if SaveState then SaveState() end
        else
            local aQ = {} 
            for _, pD in ipairs(sData) do 
                if SData[pD.Name] then 
                    for _, iN in ipairs(pcData[pD.Name] or {}) do 
                        if SData[pD.Name].items[iN] then table.insert(aQ, {Pack=pD.Name, Item=iN}) end 
                    end 
                end 
            end
            if #aQ == 0 then isG = false sgBtn.Text = "ERR: NO ITEMS" if SaveState then SaveState() end return end
            
            local cIdx = 1
            isG, waitingRoll, rollGrade = true, false, nil
            sgBtn.Text, sgBtn.BackgroundColor3 = "Stop Grader", C3(200,40,40)
            if SaveState then SaveState() end
            
            task.spawn(function() 
                while isG do 
                    if not mFrame:IsDescendantOf(game) then break end 
                    local cT = aQ[cIdx] 
                    if not cT then 
                        isG = false sLbl.Text = "Finished" sgBtn.Text, sgBtn.BackgroundColor3 = "Start Grader", C3(40,200,120)
                        if SaveState then SaveState() end
                        break 
                    end
                    
                    local cUIG = findGradeInUI(cT.Item) 
                    local targetRank = gRanks[selG] or 10
                    
                    if cUIG and gRanks[cUIG] and gRanks[cUIG] >= targetRank then 
                        uncheckCard(cT.Pack, cT.Item)
                        if anC then 
                            cIdx = cIdx + 1 
                            local nT = aQ[cIdx] 
                            if not nT then 
                                isG = false sLbl.Text = "Finished" sgBtn.Text, sgBtn.BackgroundColor3 = "Start Grader", C3(40,200,120)
                                if SaveState then SaveState() end
                            elseif nT.Pack ~= cT.Pack and not anP then 
                                isG = false sLbl.Text = "Stopped (Pack)" sgBtn.Text, sgBtn.BackgroundColor3 = "Start Grader", C3(40,200,120)
                                if SaveState then SaveState() end
                            else 
                                sLbl.Text = "Skipped: " .. nT.Item 
                                task.wait(0.2) 
                            end 
                        else 
                            isG = false sLbl.Text = "Met ("..cUIG..")" sgBtn.Text, sgBtn.BackgroundColor3 = "Start Grader", C3(40,200,120)
                            if SaveState then SaveState() end
                        end 
                    else
                        sLbl.Text = "Grading: " .. cT.Item
                        rollGrade = nil
                        waitingRoll = true
                        
                        pcall(function() rEvt:FireServer(aName, cT.Item) end)
                        
                        local delaySec = (tonumber(dInp.Text) or 300) / 1000
                        local t0 = os.clock()
                        
                        while isG and waitingRoll and not rollGrade and (os.clock() - t0) < ROLL_TIMEOUT_SECONDS do task.wait(0.05) end
                        waitingRoll = false
                        
                        local finalGrade = rollGrade or findGradeInUI(cT.Item)
                        local timedOut = not rollGrade and not finalGrade and (os.clock() - t0) >= ROLL_TIMEOUT_SECONDS
                        if timedOut then
                            sLbl.Text = "Timed out: " .. cT.Item
                            if anC then
                                cIdx = cIdx + 1
                            else
                                isG = false
                                sgBtn.Text, sgBtn.BackgroundColor3 = "Start Grader", C3(40,200,120)
                            end
                        elseif finalGrade and gRanks[finalGrade] and gRanks[finalGrade] >= targetRank then
                            uncheckCard(cT.Pack, cT.Item)
                            if anC then
                                cIdx = cIdx + 1
                                local nT = aQ[cIdx]
                                if not nT then isG = false sLbl.Text = "Finished" sgBtn.Text, sgBtn.BackgroundColor3 = "Start Grader", C3(40,200,120) if SaveState then SaveState() end 
                                elseif nT.Pack ~= cT.Pack and not anP then isG = false sLbl.Text = "Stopped (Pack)" sgBtn.Text, sgBtn.BackgroundColor3 = "Start Grader", C3(40,200,120) if SaveState then SaveState() end end
                            else
                                isG = false sLbl.Text = "Hit Target!" sgBtn.Text, sgBtn.BackgroundColor3 = "Start Grader", C3(40,200,120) if SaveState then SaveState() end
                            end
                            task.wait(0.2)
                        else
                            local elapsed = os.clock() - t0
                            if elapsed < delaySec then task.wait(delaySec - elapsed) end
                        end
                    end
                end 
            end) 
        end
    end

    sgBtn.MouseButton1Click:Connect(function() setGraderRunning(not isG) end)

    GraderAPI.GetConfig = function() return {selG = selG, anC = anC, anP = anP, delay = dInp.Text} end
    GraderAPI.LoadConfig = function(cfg)
        if not cfg then return end
        if cfg.selG and gRanks[cfg.selG] then selG = cfg.selG tgBtn.Text = "Target: " .. selG end
        if cfg.anC ~= nil then anC = cfg.anC anBtn.Text, anBtn.BackgroundColor3 = anC and "[X] Auto Next Item" or "[ ] Auto Next Item", anC and C3(40,200,120) or C3(50,50,50) end
        if cfg.anP ~= nil then anP = cfg.anP apBtn.Text, apBtn.BackgroundColor3 = anP and "[X] Auto Next Pack" or "[ ] Auto Next Pack", anP and C3(40,200,120) or C3(50,50,50) end
        if cfg.delay then dInp.Text = tostring(cfg.delay) end
    end
    GraderAPI.GetState = function()
        local checked = {}
        for _, pD in pairs(SData) do
            for iN, isS in pairs(pD.items) do if isS then table.insert(checked, iN) end end
        end
        return {isG = isG, items = checked}
    end
    GraderAPI.LoadState = function(st)
        if not st then return end
        local lookup = {} for _, iN in ipairs(st.items or {}) do lookup[iN] = true end
        for pN, pD in pairs(SData) do
            local anySelected = false
            for iN, _ in pairs(pD.items) do
                local s = lookup[iN] == true
                pD.items[iN] = s
                if s then anySelected = true end
                local btn = CardBtnMap[iN]
                if btn then
                    local cg = findGradeInUI(iN)
                    btn.Text = "   ↳ " .. (s and "[X] " or "[ ] ") .. iN .. (cg and " [" .. cg .. "]" or " [?]")
                    btn.TextColor3 = s and C3(40, 200, 120) or (cg and C3(200, 200, 200) or C3(100, 100, 100))
                end
            end
            pD.isSelected = anySelected
            pD.cBtn.Text = (anySelected and " [X] " or " [ ] ") .. pN
            pD.cBtn.TextColor3 = anySelected and C3(40, 200, 120) or C3(200, 200, 200)
        end
        if st.isG and #(st.items or {}) > 0 then
            sLbl.Text = "Resuming in 2s..."
            task.delay(2, function() setGraderRunning(true) end)
        end
    end
end
bGrader(cFrame, CardSortedPacks, CardPackCards, "Grade", "Roll", GRADE_LIST, GRADE_RANK)

-- ==========================================
-- 7. TOWER TRAIT ROLLER (NETWORK INTERCEPT)
-- ==========================================
local TowerAPI = {}

local function bTraitRoller(pFrame, sData, pcData)
    local lPnl = Instance.new("Frame", pFrame) lPnl.Size, lPnl.Position, lPnl.BackgroundColor3, lPnl.BorderSizePixel = U2(0,230,1,-20), U2(0,10,0,10), C3(30,30,30), 0
    local saBtn = Instance.new("TextButton", lPnl) saBtn.Size, saBtn.BackgroundColor3, saBtn.TextColor3, saBtn.Text, saBtn.Font, saBtn.TextSize, saBtn.BorderSizePixel = U2(0.5,0,0,25), C3(40,40,40), C3(255,255,255), "Select All", F_GM, 12, 0
    local daBtn = Instance.new("TextButton", lPnl) daBtn.Size, daBtn.Position, daBtn.BackgroundColor3, daBtn.TextColor3, daBtn.Text, daBtn.Font, daBtn.TextSize, daBtn.BorderSizePixel = U2(0.5,0,0,25), U2(0.5,0,0,0), C3(40,40,40), C3(255,255,255), "Deselect All", F_GM, 12, 0
    local pScr = Instance.new("ScrollingFrame", lPnl) pScr.Size, pScr.Position, pScr.BackgroundColor3, pScr.ScrollBarThickness, pScr.BorderSizePixel = U2(1,0,1,-25), U2(0,0,0,25), C3(25,25,25), 6, 0
    local sLyt = Instance.new("UIListLayout", pScr) sLyt.SortOrder = Enum.SortOrder.LayoutOrder sLyt:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() pScr.CanvasSize = U2(0,0,0,sLyt.AbsoluteContentSize.Y) end)
    
    local SData = {}
    local CardBtnMap = {}

    local function towerSummary(cardName)
        for _, collection in ipairs({ "TowerCards", "Cards" }) do
            local record = getLiveRecord(collection, cardName)
            if record then
                return " | " .. tostring(record.Grade or "?") .. " | " .. tostring(record.Trait or "?")
            end
        end
        return " | ? | ?"
    end

    local function uncheckCard(packName, cardName)
        if SData[packName] and SData[packName].items[cardName] ~= nil then
            SData[packName].items[cardName] = false
            local btn = CardBtnMap[cardName]
            if btn then btn.Text = "   ↳ [ ] " .. cardName .. towerSummary(cardName) btn.TextColor3 = C3(150, 150, 150) end
            local anyLeft = false
            for _, v in pairs(SData[packName].items) do if v then anyLeft = true break end end
            SData[packName].isSelected = anyLeft
            SData[packName].cBtn.Text = (anyLeft and " [X] " or " [ ] ") .. packName
            SData[packName].cBtn.TextColor3 = anyLeft and C3(40, 200, 120) or C3(200, 200, 200)
            if SaveState then SaveState() end
        end
    end

    for lIdx, pD in ipairs(sData) do
        local pN = pD.Name SData[pN] = { isSelected = false, items = {} }
        local pC = Instance.new("Frame", pScr) pC.Size, pC.BackgroundTransparency, pC.LayoutOrder, pC.AutomaticSize = U2(1,0,0,25), 1, lIdx, Enum.AutomaticSize.Y
        local cLyt = Instance.new("UIListLayout", pC) cLyt.SortOrder = Enum.SortOrder.LayoutOrder
        local pH = Instance.new("Frame", pC) pH.Size, pH.BackgroundColor3, pH.BorderSizePixel, pH.LayoutOrder = U2(1,0,0,25), C3(30,30,30), 0, 1
        local eBtn = Instance.new("TextButton", pH) eBtn.Size, eBtn.BackgroundColor3, eBtn.TextColor3, eBtn.Text, eBtn.Font, eBtn.BorderSizePixel = U2(0,25,0,25), C3(35,35,35), C3(200,200,200), "+", F_GB, 0
        local cBtn = Instance.new("TextButton", pH) cBtn.Size, cBtn.Position, cBtn.BackgroundTransparency, cBtn.TextColor3, cBtn.Text, cBtn.Font, cBtn.TextSize, cBtn.TextXAlignment = U2(1,-25,1,0), U2(0,25,0,0), 1, C3(200,200,200), " [ ] "..pN, F_GM, 12, Enum.TextXAlignment.Left
        local iF = Instance.new("Frame", pC) iF.Size, iF.BackgroundTransparency, iF.Visible, iF.LayoutOrder, iF.AutomaticSize = U2(1,0,0,0), 1, false, 2, Enum.AutomaticSize.Y
        Instance.new("UIListLayout", iF) local iBtns = {} SData[pN].cBtn = cBtn
        if pcData[pN] then for _, iN in ipairs(pcData[pN]) do
            SData[pN].items[iN] = false
            local ib = Instance.new("TextButton", iF) ib.Size, ib.BackgroundColor3, ib.TextColor3, ib.Text, ib.Font, ib.TextSize, ib.TextXAlignment, ib.BorderSizePixel = U2(1,0,0,20), C3(20,20,20), C3(150,150,150), "   ↳ [ ] "..iN..towerSummary(iN), F_GM, 11, Enum.TextXAlignment.Left, 0
            CardBtnMap[iN] = ib
            ib.MouseButton1Click:Connect(function()
                local s = not SData[pN].items[iN] SData[pN].items[iN] = s
                ib.Text = "   ↳ "..(s and "[X] " or "[ ] ")..iN..towerSummary(iN)
                ib.TextColor3 = s and C3(40,200,120) or C3(150, 150, 150)
                if SaveState then SaveState() end
            end)
            table.insert(iBtns, {btn=ib, name=iN, update = function(s) SData[pN].items[iN] = s ib.Text = "   ↳ "..(s and "[X] " or "[ ] ")..iN..towerSummary(iN) ib.TextColor3 = s and C3(40,200,120) or C3(150, 150, 150) end})
        end end
        eBtn.MouseButton1Click:Connect(function() iF.Visible = not iF.Visible eBtn.Text = iF.Visible and "-" or "+" end)
        local function updUI(s)
            SData[pN].isSelected = s cBtn.Text = (s and " [X] " or " [ ] ")..pN cBtn.TextColor3 = s and C3(40,200,120) or C3(200,200,200)
            for _, d in ipairs(iBtns) do d.update(s) end
        end
        cBtn.MouseButton1Click:Connect(function() updUI(not SData[pN].isSelected) if SaveState then SaveState() end end)
        SData[pN].updateUI = updUI
    end
    saBtn.MouseButton1Click:Connect(function() for _, pd in pairs(SData) do pd.updateUI(true) end if SaveState then SaveState() end end)
    daBtn.MouseButton1Click:Connect(function() for _, pd in pairs(SData) do pd.updateUI(false) end if SaveState then SaveState() end end)
    
    local rPnl = Instance.new("Frame", pFrame) rPnl.Size, rPnl.Position, rPnl.BackgroundTransparency = U2(1,-250,1,-20), U2(0,250,0,10), 1
    local sLbl = Instance.new("TextLabel", rPnl) sLbl.Size, sLbl.BackgroundColor3, sLbl.TextColor3, sLbl.Text, sLbl.Font, sLbl.TextSize, sLbl.BorderSizePixel = U2(1,0,0,25), C3(20,20,20), C3(200,200,200), "Status: Idle", F_GM, 12, 0
    
    local towerTraits = {}
    pcall(function()
        local towerConfig = require(RS.Modules.Config.Core.TowerConfig)
        for _, trait in ipairs(towerConfig.TraitList or {}) do towerTraits[#towerTraits + 1] = trait end
    end)
    local tInp = mkDropdown(rPnl, "Target Tower Trait", towerTraits, towerTraits[1], 50, 260)
    
    local anBtn = Instance.new("TextButton", rPnl) anBtn.Size, anBtn.Position, anBtn.BackgroundColor3, anBtn.TextColor3, anBtn.Text, anBtn.Font, anBtn.TextSize, anBtn.BorderSizePixel = U2(1,0,0,30), U2(0,0,0,110), C3(40,200,120), C3(255,255,255), "[X] Auto Next Item", F_GB, 13, 0
    local apBtn = Instance.new("TextButton", rPnl) apBtn.Size, apBtn.Position, apBtn.BackgroundColor3, apBtn.TextColor3, apBtn.Text, apBtn.Font, apBtn.TextSize, apBtn.BorderSizePixel = U2(1,0,0,30), U2(0,0,0,150), C3(40,200,120), C3(255,255,255), "[X] Auto Next Pack", F_GB, 13, 0
    local dInp = mkInp(rPnl, "Delay (ms)", "300", 255, 0) dInp.Size = U2(1,0,0,30) dInp.Position = U2(0,0,0,275)
    dInp.FocusLost:Connect(function() if SaveConfig then SaveConfig() end end)
    
    local stBtn = Instance.new("TextButton", rPnl) stBtn.Size, stBtn.Position, stBtn.BackgroundColor3, stBtn.TextColor3, stBtn.Text, stBtn.Font, stBtn.TextSize, stBtn.BorderSizePixel = U2(1,0,0,40), U2(0,0,0,315), C3(40,200,120), C3(255,255,255), "Start Roller", F_GB, 14, 0
    
    local anC, anP = true, true
    anBtn.MouseButton1Click:Connect(function() anC = not anC anBtn.Text, anBtn.BackgroundColor3 = anC and "[X] Auto Next Item" or "[ ] Auto Next Item", anC and C3(40,200,120) or C3(50,50,50) if SaveConfig then SaveConfig() end end)
    apBtn.MouseButton1Click:Connect(function() anP = not anP apBtn.Text, apBtn.BackgroundColor3 = anP and "[X] Auto Next Pack" or "[ ] Auto Next Pack", anP and C3(40,200,120) or C3(50,50,50) if SaveConfig then SaveConfig() end end)
    
    local isT, rEvt = false, nil
    local waitingRoll = false
    local rollTrait = nil
    rEvt = getRemote("Tower")
    
    if rEvt then rEvt.OnClientEvent:Connect(function(action, trait, ...) 
        if action == "Roll" and isT and waitingRoll then
            if type(trait) == "string" then rollTrait = trait
            elseif type(trait) == "table" then rollTrait = trait.Trait or trait.trait or trait.Name or tostring(trait) end
        end
    end) end
    
    local function setRollerRunning(state)
        if not rEvt then stBtn.Text = "ERR: Remote Not Found" return end 
        if not state then 
            isT = false waitingRoll = false sLbl.Text = "Idle" stBtn.Text, stBtn.BackgroundColor3 = "Start Roller", C3(40,200,120) 
            if SaveState then SaveState() end
        else
            local aQ = {} 
            for _, pD in ipairs(sData) do 
                if SData[pD.Name] then 
                    for _, iN in ipairs(pcData[pD.Name] or {}) do 
                        if SData[pD.Name].items[iN] then table.insert(aQ, {Pack=pD.Name, Item=iN}) end 
                    end 
                end 
            end
            if #aQ == 0 then isT = false stBtn.Text = "ERR: NO ITEMS" if SaveState then SaveState() end return end
            
            local parsedTargets = {}
            for t in string.gmatch(tInp.Text, "[^,]+") do table.insert(parsedTargets, string.lower(stripTags(t))) end
            if #parsedTargets == 0 then isT = false stBtn.Text = "ERR: NO TARGETS" return end

            local function matchesTrait(value)
                local cleanValue = string.lower(stripTags(tostring(value or "")))
                for _, target in ipairs(parsedTargets) do
                    if string.find(cleanValue, target, 1, true) then return true end
                end
                return false
            end
            
            local cIdx = 1
            isT, waitingRoll, rollTrait = true, false, nil
            stBtn.Text, stBtn.BackgroundColor3 = "Stop Roller", C3(200,40,40)
            if SaveState then SaveState() end
            
            task.spawn(function()
                while isT do 
                    if not mFrame:IsDescendantOf(game) then break end 
                    local cT = aQ[cIdx] 
                    if not cT then 
                        isT = false sLbl.Text = "Finished" stBtn.Text, stBtn.BackgroundColor3 = "Start Roller", C3(40,200,120)
                        if SaveState then SaveState() end
                        break 
                    end
                    
                    local currentRecord = getLiveRecord("TowerCards", cT.Item) or getLiveRecord("Cards", cT.Item)
                    local currentTrait = currentRecord and currentRecord.Trait
                    rollTrait = nil
                    local delaySec = (tonumber(dInp.Text) or 300) / 1000
                    local t0 = os.clock()
                    if currentTrait and matchesTrait(currentTrait) then
                        sLbl.Text = "Already met: " .. cT.Item
                        rollTrait = currentTrait
                    else
                        sLbl.Text = "Rolling: " .. cT.Item
                        waitingRoll = true
                        pcall(function() rEvt:FireServer("Roll", cT.Item) end)
                        while isT and waitingRoll and not rollTrait and (os.clock() - t0) < ROLL_TIMEOUT_SECONDS do task.wait(0.05) end
                        waitingRoll = false
                    end
                    
                    if rollTrait then
                        local matched = matchesTrait(rollTrait)
                        
                        if matched then
                            uncheckCard(cT.Pack, cT.Item)
                            if anC then
                                cIdx = cIdx + 1
                                local nT = aQ[cIdx]
                                if not nT then isT = false sLbl.Text = "Finished" stBtn.Text, stBtn.BackgroundColor3 = "Start Roller", C3(40,200,120) if SaveState then SaveState() end
                                elseif nT.Pack ~= cT.Pack and not anP then isT = false sLbl.Text = "Stopped (Pack)" stBtn.Text, stBtn.BackgroundColor3 = "Start Roller", C3(40,200,120) if SaveState then SaveState() end end
                            else
                                isT = false sLbl.Text = "Hit Target!" stBtn.Text, stBtn.BackgroundColor3 = "Start Roller", C3(40,200,120) if SaveState then SaveState() end
                            end
                            task.wait(0.2)
                        else
                            local elapsed = os.clock() - t0
                            if elapsed >= ROLL_TIMEOUT_SECONDS then
                                sLbl.Text = "Timed out: " .. cT.Item
                                if anC then
                                    cIdx = cIdx + 1
                                else
                                    isT = false
                                    stBtn.Text, stBtn.BackgroundColor3 = "Start Roller", C3(40,200,120)
                                end
                            elseif elapsed < delaySec then
                                task.wait(delaySec - elapsed)
                            end
                        end
                    else
                        local elapsed = os.clock() - t0
                        if elapsed >= ROLL_TIMEOUT_SECONDS then
                            sLbl.Text = "Timed out: " .. cT.Item
                            if anC then
                                cIdx = cIdx + 1
                            else
                                isT = false
                                stBtn.Text, stBtn.BackgroundColor3 = "Start Roller", C3(40,200,120)
                            end
                        elseif elapsed < delaySec then
                            task.wait(delaySec - elapsed)
                        end
                    end
                end 
            end) 
        end
    end

    stBtn.MouseButton1Click:Connect(function() setRollerRunning(not isT) end)

    TowerAPI.GetConfig = function() return {targets = tInp.Text, anC = anC, anP = anP, delay = dInp.Text} end
    TowerAPI.LoadConfig = function(cfg)
        if not cfg then return end
        if cfg.targets then tInp.Text = tostring(cfg.targets) end
        if cfg.anC ~= nil then anC = cfg.anC anBtn.Text, anBtn.BackgroundColor3 = anC and "[X] Auto Next Item" or "[ ] Auto Next Item", anC and C3(40,200,120) or C3(50,50,50) end
        if cfg.anP ~= nil then anP = cfg.anP apBtn.Text, apBtn.BackgroundColor3 = anP and "[X] Auto Next Pack" or "[ ] Auto Next Pack", anP and C3(40,200,120) or C3(50,50,50) end
        if cfg.delay then dInp.Text = tostring(cfg.delay) end
    end
    TowerAPI.GetState = function()
        local checked = {}
        for _, pD in pairs(SData) do
            for iN, isS in pairs(pD.items) do if isS then table.insert(checked, iN) end end
        end
        return {isT = isT, items = checked}
    end
    TowerAPI.LoadState = function(st)
        if not st then return end
        local lookup = {} for _, iN in ipairs(st.items or {}) do lookup[iN] = true end
        for pN, pD in pairs(SData) do
            local anySelected = false
            for iN, _ in pairs(pD.items) do
                local s = lookup[iN] == true
                pD.items[iN] = s
                if s then anySelected = true end
                local btn = CardBtnMap[iN]
                if btn then
                    btn.Text = "   ↳ " .. (s and "[X] " or "[ ] ") .. iN .. towerSummary(iN)
                    btn.TextColor3 = s and C3(40, 200, 120) or C3(150, 150, 150)
                end
            end
            pD.isSelected = anySelected
            pD.cBtn.Text = (anySelected and " [X] " or " [ ] ") .. pN
            pD.cBtn.TextColor3 = anySelected and C3(40, 200, 120) or C3(200, 200, 200)
        end
        if st.isT and #(st.items or {}) > 0 then
            sLbl.Text = "Resuming in 2s..."
            task.delay(2, function() setRollerRunning(true) end)
        end
    end
end
bTraitRoller(tFrame, CardSortedPacks, CardPackCards)

-- ==========================================
-- 8. FIGURINE GRADE / TRAIT ROLLER
-- ==========================================
local FigurineAPI = {}

local function buildFigurineGrader(parent)
    local panel = Instance.new("Frame", parent)
    panel.Size, panel.Position, panel.BackgroundColor3, panel.BorderSizePixel = U2(1, -20, 1, -20), U2(0, 10, 0, 10), C3(30, 30, 30), 0

    local list = Instance.new("ScrollingFrame", panel)
    list.Size, list.Position, list.BackgroundColor3, list.ScrollBarThickness, list.BorderSizePixel = U2(0, 300, 1, -20), U2(0, 10, 0, 10), C3(22, 22, 22), 6, 0
    list.CanvasSize = U2(0, 0, 0, 0)
    local layout = Instance.new("UIListLayout", list)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        list.CanvasSize = U2(0, 0, 0, layout.AbsoluteContentSize.Y + 4)
    end)

    local controls = Instance.new("Frame", panel)
    controls.Size, controls.Position, controls.BackgroundTransparency = U2(1, -320, 1, -20), U2(0, 310, 0, 10), 1
    local status = Instance.new("TextLabel", controls)
    status.Size, status.BackgroundColor3, status.TextColor3, status.Text, status.Font, status.TextSize = U2(1, 0, 0, 28), C3(20, 20, 20), C3(200, 200, 200), "Status: Idle", F_GM, 12

    local modeBtn = Instance.new("TextButton", controls)
    modeBtn.Size, modeBtn.Position, modeBtn.BackgroundColor3, modeBtn.TextColor3, modeBtn.Text, modeBtn.Font, modeBtn.TextSize = U2(1, 0, 0, 34), U2(0, 0, 0, 38), C3(40, 40, 120), C3(255, 255, 255), "Mode: Grade", F_GB, 13
    local figurineGrades, figurineTraits = {}, {}
    local okGalleryConfig, galleryConfig = pcall(function() return require(RS.Modules.Config.Core.GalleryConfig) end)
    if okGalleryConfig and type(galleryConfig) == "table" then
        for _, grade in ipairs(GRADE_LIST) do
            if galleryConfig.Grades and galleryConfig.Grades[grade] then figurineGrades[#figurineGrades + 1] = grade end
        end
        for trait in pairs(galleryConfig.Traits or {}) do figurineTraits[#figurineTraits + 1] = trait end
        table.sort(figurineTraits)
    end
    local gradeInp = mkDropdown(controls, "Target Figurine Grade", figurineGrades, "UR", 82, 260)
    local traitInp = mkDropdown(controls, "Target Figurine Trait", figurineTraits, figurineTraits[1], 140, 260)
    traitInp.Visible = false
    local delayInp = mkInp(controls, "Delay (ms)", "300", 198, 0, 260)
    local selectBtn = Instance.new("TextButton", controls)
    selectBtn.Size, selectBtn.Position, selectBtn.BackgroundColor3, selectBtn.TextColor3, selectBtn.Text, selectBtn.Font, selectBtn.TextSize = U2(0.5, -4, 0, 32), U2(0, 0, 0, 258), C3(45, 45, 45), C3(255, 255, 255), "Select All", F_GM, 12
    local clearBtn = selectBtn:Clone()
    clearBtn.Position, clearBtn.Text, clearBtn.Parent = U2(0.5, 4, 0, 258), "Clear", controls
    local runBtn = Instance.new("TextButton", controls)
    runBtn.Size, runBtn.Position, runBtn.BackgroundColor3, runBtn.TextColor3, runBtn.Text, runBtn.Font, runBtn.TextSize = U2(1, 0, 0, 40), U2(0, 0, 0, 300), C3(40, 200, 120), C3(255, 255, 255), "Start Figurine Roller", F_GB, 14

    local selected, buttons, names = {}, {}, {}
    local mode, running, waiting, result, runId = "Grade", false, false, nil, 0
    local gallery = getRemote("Gallery")

    local function currentValue(name, key)
        local liveRecord = getLiveRecord("Figurines", name)
        if liveRecord and liveRecord[key] ~= nil then return tostring(liveRecord[key]) end
        local pg = LP:FindFirstChild("PlayerGui")
        local root = pg and pg:FindFirstChild("FigurineSelect")
        local frame = root and root:FindFirstChild("Frame")
        local main = frame and frame:FindFirstChild("Main")
        local item = main and main:FindFirstChild(name)
        local field = item and item:FindFirstChild(key, true)
        if not field then return nil end
        if field:IsA("TextLabel") or field:IsA("TextButton") or field:IsA("TextBox") then
            return stripTags(field.Text)
        end
        local gradient = field:FindFirstChildOfClass("UIGradient")
        return gradient and gradient.Name ~= "UIGradient" and gradient.Name or nil
    end

    local function paint(name)
        local b = buttons[name]
        if not b then return end
        local grade = currentValue(name, "Grade") or "?"
        local trait = currentValue(name, "Trait") or "?"
        b.Text = (selected[name] and "[X] " or "[ ] ") .. name .. " | " .. grade .. " | " .. trait
        b.TextColor3 = selected[name] and C3(40, 200, 120) or C3(210, 210, 210)
    end

    local function refresh()
        for _, name in ipairs(names) do paint(name) end
    end

    if okGalleryConfig and type(galleryConfig) == "table" and type(galleryConfig.Figurines) == "table" then
        for name in pairs(galleryConfig.Figurines) do names[#names + 1] = name end
    end
    table.sort(names)
    for index, name in ipairs(names) do
        local b = Instance.new("TextButton", list)
        b.Size, b.BackgroundColor3, b.Font, b.TextSize, b.TextXAlignment, b.BorderSizePixel, b.LayoutOrder = U2(1, -8, 0, 24), C3(28, 28, 28), F_GM, 11, Enum.TextXAlignment.Left, 0, index
        buttons[name] = b
        b.MouseButton1Click:Connect(function()
            selected[name] = not selected[name]
            paint(name)
        end)
    end
    refresh()

    modeBtn.MouseButton1Click:Connect(function()
        mode = mode == "Grade" and "Trait" or "Grade"
        modeBtn.Text = "Mode: " .. mode
        gradeInp.Visible, traitInp.Visible = mode == "Grade", mode == "Trait"
    end)
    selectBtn.MouseButton1Click:Connect(function()
        for _, name in ipairs(names) do selected[name] = true end
        refresh()
    end)
    clearBtn.MouseButton1Click:Connect(function()
        for _, name in ipairs(names) do selected[name] = false end
        refresh()
    end)

    if gallery then
        gallery.OnClientEvent:Connect(function(action, value)
            if waiting and ((mode == "Grade" and action == "RollGrade") or (mode == "Trait" and action == "RollTrait")) then
                result = tostring(value)
            end
        end)
    end

    local function targetMet(value)
        if mode == "Grade" then
            local target = exactGrade(gradeInp.Text) or "UR"
            return GRADE_RANK[exactGrade(value) or "F"] >= (GRADE_RANK[target] or GRADE_RANK.UR)
        end
        local lower = string.lower(tostring(value or ""))
        for target in string.gmatch(traitInp.Text, "[^,]+") do
            if string.find(lower, string.lower(stripTags(target)), 1, true) then return true end
        end
        return false
    end

    runBtn.MouseButton1Click:Connect(function()
        if running then
            running, runId, waiting = false, runId + 1, false
            runBtn.Text, runBtn.BackgroundColor3 = "Start Figurine Roller", C3(40, 200, 120)
            status.Text = "Stopped"
            return
        end
        if not gallery then
            status.Text = "Gallery remote missing"
            return
        end
        local queue = {}
        for _, name in ipairs(names) do
            if selected[name] and getLiveRecord("Figurines", name) then
                queue[#queue + 1] = name
            end
        end
        if #queue == 0 then status.Text = "Select at least one figurine" return end
        running, runId = true, runId + 1
        local myRun, index = runId, 1
        runBtn.Text, runBtn.BackgroundColor3 = "Stop Figurine Roller", C3(200, 40, 40)
        task.spawn(function()
            while running and runId == myRun do
                local name = queue[index]
                if not name then
                    running = false
                    status.Text = "Finished"
                    runBtn.Text, runBtn.BackgroundColor3 = "Start Figurine Roller", C3(40, 200, 120)
                    break
                end
                local ownedRecord = getLiveRecord("Figurines", name)
                if not ownedRecord then
                    status.Text = "Skipping unowned: " .. name
                    index = index + 1
                else
                    local current = currentValue(name, mode)
                    if targetMet(current) then
                        index = index + 1
                    else
                        status.Text = "Rolling " .. mode .. ": " .. name
                        result, waiting = nil, true
                        local action = mode == "Grade" and "RollGrade" or "RollTrait"
                        pcall(function() gallery:FireServer(action, name) end)
                        local delaySec, started = math.max(50, tonumber(delayInp.Text) or 300) / 1000, os.clock()
                        while running and runId == myRun and waiting and not result and os.clock() - started < ROLL_TIMEOUT_SECONDS do task.wait(0.05) end
                        local timedOut = not result and os.clock() - started >= ROLL_TIMEOUT_SECONDS
                        waiting = false
                        if timedOut then
                            status.Text = "Timed out: " .. name
                            index = index + 1
                        elseif result and targetMet(result) then
                            index = index + 1
                        end
                        local remaining = delaySec - (os.clock() - started)
                        if remaining > 0 then task.wait(remaining) end
                    end
                end
                refresh()
            end
        end)
    end)

    task.spawn(function()
        while parent:IsDescendantOf(game) do
            refresh()
            task.wait(1)
        end
    end)
end

buildFigurineGrader(figFrame)

-- ==========================================
-- 9. SETTINGS TAB & AUTO-SYNC ENGINE
-- ==========================================
local sPnl = Instance.new("Frame", sFrame)
sPnl.Size, sPnl.Position, sPnl.BackgroundColor3, sPnl.BorderSizePixel = U2(1,-20,1,-20), U2(0,10,0,10), C3(30,30,30), 0

local accInfoLbl = Instance.new("TextLabel", sPnl)
accInfoLbl.Size, accInfoLbl.Position, accInfoLbl.BackgroundTransparency, accInfoLbl.TextColor3, accInfoLbl.Font, accInfoLbl.TextSize = U2(1,-20,0,45), U2(0,10,0,15), 1, C3(255,215,0), F_GB, 13
accInfoLbl.Text = "Account: " .. LP.Name .. "  |  UserId: " .. UID .. "\nConfig: " .. ConfigFileName .. "  |  State: " .. StateFileName

local scInp = mkInp(sPnl, "UI Scale (e.g. 1.0)", "1.0", 75, -120, 240)
scInp.FocusLost:Connect(function() uiScale.Scale = tonumber(scInp.Text) or 1 if SaveConfig then SaveConfig() end end)

local isAFK = true
local afkBtn = Instance.new("TextButton", sPnl)
afkBtn.Size, afkBtn.Position, afkBtn.BackgroundColor3, afkBtn.TextColor3, afkBtn.Text, afkBtn.Font, afkBtn.TextSize, afkBtn.BorderSizePixel = U2(0,240,0,40), U2(0.5,-120,0,145), C3(40,200,120), C3(255,255,255), "[X] Built-In Anti-AFK", F_GB, 13, 0

local afkRun = 0
local function setAfkState(state)
    isAFK = state
    afkBtn.Text, afkBtn.BackgroundColor3 = isAFK and "[X] Built-In Anti-AFK" or "[ ] Built-In Anti-AFK", isAFK and C3(40,200,120) or C3(50,50,50)
    
    if isAFK then
        afkRun = afkRun + 1
        local currentRun = afkRun
        task.spawn(function()
            while isAFK and afkRun == currentRun and mFrame:IsDescendantOf(game) do
                task.wait(150)
                if not isAFK or afkRun ~= currentRun then break end
                
                pcall(function()
                    local char = LP.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hum then hum.Jump = true end
                    VIM:SendKeyEvent(true, Enum.KeyCode.D, false, game)
                    task.wait(1)
                    VIM:SendKeyEvent(false, Enum.KeyCode.D, false, game)
                end)
            end
        end)
    end
end
afkBtn.MouseButton1Click:Connect(function() setAfkState(not isAFK) if SaveConfig then SaveConfig() end end)

LP.Idled:Connect(function()
    if isAFK then pcall(function() VU:CaptureController() VU:ClickButton2(Vector2.new()) end) end
end)

local statusFileLbl = Instance.new("TextLabel", sPnl)
statusFileLbl.Size, statusFileLbl.Position, statusFileLbl.BackgroundTransparency, statusFileLbl.TextColor3, statusFileLbl.Font, statusFileLbl.TextSize = U2(1,-20,0,30), U2(0,10,0,205), 1, C3(150,220,150), F_GM, 12
statusFileLbl.Text = "Auto-Sync Active (No manual save/load required)"

local rstBtn = Instance.new("TextButton", sPnl)
rstBtn.Size, rstBtn.Position, rstBtn.BackgroundColor3, rstBtn.TextColor3, rstBtn.Text, rstBtn.Font, rstBtn.TextSize, rstBtn.BorderSizePixel = U2(0,240,0,35), U2(0.5,-120,0,250), C3(180,50,50), C3(255,255,255), "Reset Account State & Queue", F_GB, 12, 0
rstBtn.MouseButton1Click:Connect(function()
    GraderAPI.LoadState({isG = false, items = {}})
    TowerAPI.LoadState({isT = false, items = {}})
    if SaveState then SaveState() end
    statusFileLbl.Text = "Account state & queue cleared!"
    task.delay(2, function() statusFileLbl.Text = "Auto-Sync Active (No manual save/load required)" end)
end)

SaveConfig = function()
    if not writefile then return end
    local cfg = {
        userId = LP.UserId, accountName = LP.Name, uiScale = scInp.Text, afk = isAFK, fishDelay = fDelInp.Text,
        event = { hk = hkDel.Text, hn = hnDel.Text, hm = hmUnits.Text, hw = hwDel.Text, hz = hzInp.Text, hs = hsInp.Text, htp = isTP },
        grader = GraderAPI.GetConfig(), tower = TowerAPI.GetConfig()
    }
    pcall(function() writefile(ConfigFileName, HS:JSONEncode(cfg)) end)
end

SaveState = function()
    if not writefile then return end
    local st = {
        userId = LP.UserId, accountName = LP.Name, fish = isFish, gems = isGems, hal = isHal, hud = isHudEnabled,
        smelt = isSmelt, potion = isPotion, claim = isClaim, grader = GraderAPI.GetState(), tower = TowerAPI.GetState()
    }
    pcall(function() writefile(StateFileName, HS:JSONEncode(st)) end)
end

local function InitAccountFiles()
    if readfile and isfile and isfile(ConfigFileName) then
        local ok, cfg = pcall(function() return HS:JSONDecode(readfile(ConfigFileName)) end)
        if ok and type(cfg) == "table" then
            if cfg.uiScale then scInp.Text = tostring(cfg.uiScale) uiScale.Scale = tonumber(scInp.Text) or 1 end
            if cfg.afk ~= nil then setAfkState(cfg.afk) end
            if cfg.fishDelay then fDelInp.Text = tostring(cfg.fishDelay) end
            if type(cfg.event) == "table" then
                if cfg.event.hk then hkDel.Text = tostring(cfg.event.hk) end
                if cfg.event.hn then hnDel.Text = tostring(cfg.event.hn) end
                if cfg.event.hm then hmUnits.Text = tostring(cfg.event.hm) end
                if cfg.event.hw then hwDel.Text = tostring(cfg.event.hw) end
                if cfg.event.hz then hzInp.Text = tostring(cfg.event.hz) end
                if cfg.event.hs then hsInp.Text = tostring(cfg.event.hs) end
                if cfg.event.htp ~= nil then isTP = cfg.event.htp htTPBtn.Text, htTPBtn.BackgroundColor3 = isTP and "[X] Smart Walk To Zones" or "[ ] Smart Walk To Zones", isTP and C3(40,200,120) or C3(50,50,50) end
            end
            if cfg.grader then GraderAPI.LoadConfig(cfg.grader) end
            if cfg.tower then TowerAPI.LoadConfig(cfg.tower) end
        end
    else SaveConfig() end

    if readfile and isfile and isfile(StateFileName) then
        local ok, st = pcall(function() return HS:JSONDecode(readfile(StateFileName)) end)
        if ok and type(st) == "table" then
            if st.fish ~= nil and st.fish ~= isFish then setFishState(st.fish) end
            if st.gems ~= nil and st.gems ~= isGems then setGemsState(st.gems) end
            if st.hal ~= nil and st.hal ~= isHal then setHalState(st.hal) end
            if st.hud ~= nil and st.hud ~= isHudEnabled then setHudState(st.hud) end
            if st.smelt ~= nil and st.smelt ~= isSmelt then setSmeltState(st.smelt) end
            if st.potion ~= nil and st.potion ~= isPotion then setPotionState(st.potion) end
            if st.claim ~= nil and st.claim ~= isClaim then setClaimState(st.claim) end
            if st.grader then GraderAPI.LoadState(st.grader) end
            if st.tower then TowerAPI.LoadState(st.tower) end
        end
    else SaveState() end
end

InitAccountFiles()
print("ACC Master Suite Loaded Successfully!")
