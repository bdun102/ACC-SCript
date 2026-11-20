-- ACC BOOT GUARD: wait for the game to load, then until 15s have passed since it started.
-- Injecting later than that adds no extra wait. Change ACC_BOOT_DELAY to adjust.
do
    local DELAY = (getgenv and getgenv().ACC_BOOT_DELAY) or 15
    if not game:IsLoaded() then game.Loaded:Wait() end
    local left = DELAY - time()
    if left > 0 then task.wait(left) end
end

-- =========================================================================
-- ACC MASTER SUITE: 11-TAB EDITION (UPGRADED OPENER + MARKET BUYALL) - REDESIGNED UI
-- =========================================================================

pcall(function()
    local keyName = "Key.txt"
    local keyValue = "qyrix-ghasldhjgsa"
    if writefile and isfile and not isfile(keyName) then
        writefile(keyName, keyValue)
    end
end)

local SCRIPT_URL = ""

-- Infinite Yield (set getgenv().ACC_LOAD_IY = false before running to skip it)
task.spawn(function()
    local g = (getgenv and getgenv()) or _G
    if g.ACC_LOAD_IY == false or g.ACC_IY_LOADED then return end
    g.ACC_IY_LOADED = true
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end)
end)
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local RF = game:GetService("ReplicatedFirst")
local HS = game:GetService("HttpService")
local VU = game:GetService("VirtualUser")
local VIM = game:GetService("VirtualInputManager")
local U2 = UDim2.new
local F_GB = Enum.Font.GothamBold
local F_GM = Enum.Font.GothamMedium

-- ==========================================
-- 0. DESIGN SYSTEM (theme, widgets, skin)
-- ==========================================
local TS = game:GetService("TweenService")
local rgb = Color3.fromRGB
local T = {
    bg = rgb(13, 14, 20), surface = rgb(20, 22, 31), surface2 = rgb(27, 30, 42), surface3 = rgb(37, 41, 57),
    input = rgb(15, 17, 25), stroke = rgb(46, 51, 71),
    text = rgb(236, 238, 246), text2 = rgb(188, 194, 212), text3 = rgb(130, 137, 160), text4 = rgb(88, 94, 114),
    accent = rgb(99, 102, 241), accentDim = rgb(52, 55, 128), amber = rgb(251, 191, 36),
    ok = rgb(16, 160, 112), ok2 = rgb(52, 211, 153), danger = rgb(222, 64, 84), info = rgb(59, 130, 246),
    off = rgb(62, 68, 92), white = rgb(255, 255, 255),
}

-- Legacy colours still written by the automation logic are mapped onto the new palette,
-- so every dynamic state change (running / stopped / selected) picks up the new theme.
local C3
do
    local LEGACY = {
        ["40,200,120"] = T.ok, ["40,220,130"] = T.ok2, ["200,40,40"] = T.danger, ["50,50,50"] = T.surface3,
        ["40,40,40"] = T.surface3, ["40,120,200"] = T.info,
        ["200,200,200"] = T.text2, ["210,210,210"] = T.text2, ["150,150,150"] = T.text3, ["100,100,100"] = T.text4,
    }
    C3 = function(r, g, b) return LEGACY[r .. "," .. g .. "," .. b] or rgb(r, g, b) end
end

local uiScale -- assigned when the main window is built
local DS = {}

-- ---------- primitives ----------
function DS.new(class, parent, props)
    local o = Instance.new(class)
    if o:IsA("GuiObject") then
        o.BorderSizePixel = 0
        if not (props and (props.BackgroundColor3 or props.BackgroundTransparency)) then o.BackgroundTransparency = 1 end
    end
    if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
        o.Font, o.TextSize, o.TextColor3 = F_GM, 13, T.text
    end
    for key, value in pairs(props or {}) do o[key] = value end
    o.Parent = parent
    return o
end

function DS.corner(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = o
    return c
end

function DS.stroke(o, color, thickness)
    local s = Instance.new("UIStroke")
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color, s.Thickness = color or T.stroke, thickness or 1
    s.Parent = o
    return s
end

function DS.pad(o, l, t, r, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft, p.PaddingTop, p.PaddingRight, p.PaddingBottom = UDim.new(0, l or 0), UDim.new(0, t or 0), UDim.new(0, r or 0), UDim.new(0, b or 0)
    p.Parent = o
    return p
end

function DS.vlist(o, gap)
    local l = Instance.new("UIListLayout")
    l.SortOrder, l.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, gap or 6)
    l.Parent = o
    return l
end

-- drag by a handle (title bar), works for mouse and touch and never fights scrolling lists
function DS.drag(handle, target)
    local dragging, origin, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, origin, startPos = true, input.Position, target.Position
            target:SetAttribute("wasDragged", false)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - origin
            if d.Magnitude > 5 then target:SetAttribute("wasDragged", true) end
            target.Position = U2(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ---------- text skin: turns the logic's "[X] Name [A]" strings into designed rows ----------
local GRADE_COLORS = {
    UR = "#fbbf24", SR = "#f472b6", SS = "#c084fc", ["S+"] = "#fb923c", S = "#fb923c",
    A = "#34d399", B = "#60a5fa", C = "#9ca3af", D = "#9ca3af", E = "#6b7280", F = "#6b7280",
}
local function esc(s) return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end
local function span(s, color) return "<font color=\"" .. color .. "\">" .. esc(s) .. "</font>" end
local function badge(s, color) return "<b>" .. span(s, color) .. "</b>" end

local function parseCheck(text)
    local i, j = string.find(text, "%[[X ]%]")
    if not i or i > 10 then return nil end
    local on = string.sub(text, i + 1, i + 1) == "X"
    local rest = string.match(string.sub(text, j + 1), "^%s*(.-)%s*$") or ""
    return on, rest
end

local MUT_COLORS = { Gold = "#fbbf24", Emerald = "#34d399", Void = "#a78bfa", Diamond = "#67e8f9", Rainbow = "#f472b6" }
local function decorate(rest)
    if string.find(rest, "\t", 1, true) then
        local parts, pos = {}, 1
        while true do
            local i = string.find(rest, "\t", pos, true)
            if not i then parts[#parts + 1] = string.sub(rest, pos) break end
            parts[#parts + 1] = string.sub(rest, pos, i - 1)
            pos = i + 1
        end
        for k, v in ipairs(parts) do parts[k] = string.match(v, "^%s*(.-)%s*$") or "" end
        local out = esc(parts[1])
        local g = parts[2]
        if g and g ~= "" and g ~= "?" then out = out .. "  " .. badge(g, GRADE_COLORS[g] or "#9ca3af") end
        for k = 3, #parts do
            local p = parts[k]
            if p ~= "" then
                local color = string.find(p, "★", 1, true) and "#fbbf24" or string.find(p, "✗", 1, true) and "#f87171" or string.find(p, "✓", 1, true) and "#60a5fa" or MUT_COLORS[p] or "#8b93a7"
                out = out .. "  " .. span(p, color)
            end
        end
        return out
    end
    local name, g = string.match(rest, "^(.-)%s*%[([%w%+%?]+)%]$")
    if name and name ~= "" then return esc(name) .. "   " .. badge(g, GRADE_COLORS[g] or "#6b7280") end
    local n1, a1, b1 = string.match(rest, "^(.-)%s*|%s*(.-)%s*|%s*(.-)$")
    if n1 and n1 ~= "" then return esc(n1) .. "   " .. badge(a1, GRADE_COLORS[a1] or "#9ca3af") .. "  " .. span(b1, "#8b93a7") end
    local n2, prog = string.match(rest, "^(.-)%s+(%d+/%d+)$")
    if n2 and n2 ~= "" then return esc(n2) .. "   " .. span(prog, "#8b93a7") end
    local n3, cnt = string.match(rest, "^(.-)%s*%((%d+)%)$")
    if n3 and n3 ~= "" then return esc(n3) .. "   " .. span("x" .. cnt, "#8b93a7") end
    return esc(rest)
end

-- checkbox row (tree items, pack headers, raid packs, figurines)
function DS.row(btn)
    btn.RichText = true
    local function apply()
        local on, rest = parseCheck(btn.Text)
        if on == nil then return end
        btn.Text = (on and span("●", "#34d399") or span("○", "#5b6380")) .. "  " .. decorate(rest)
    end
    btn:GetPropertyChangedSignal("Text"):Connect(apply)
    apply()
    return btn
end

-- ---------- widgets ----------
function DS.label(parent, text, size, color, font, order)
    return DS.new("TextLabel", parent, {
        Size = U2(1, 0, 0, (size or 13) + 4), Text = text, TextSize = size or 13, TextColor3 = color or T.text,
        Font = font or F_GM, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = order or 0,
    })
end

function DS.btn(parent, text, kind, order, h)
    local fill = ({ ok = T.ok, danger = T.danger, accent = T.accent, info = T.info })[kind or ""] or T.surface3
    local b = DS.new("TextButton", parent, {
        Size = U2(1, 0, 0, h or 38), BackgroundColor3 = fill, Text = text, TextColor3 = T.white,
        Font = F_GB, TextSize = 13, LayoutOrder = order or 0,
    })
    DS.corner(b, 8)
    return b
end

function DS.status(parent, text, order)
    local s = DS.new("TextLabel", parent, {
        Size = U2(1, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.input, Text = text,
        TextColor3 = T.text2, Font = F_GM, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, LayoutOrder = order or 0,
    })
    DS.corner(s, 8) DS.stroke(s) DS.pad(s, 10, 6, 10, 6)
    return s
end

-- switch row: the logic keeps writing "[X] Label" / "[ ] Label" to .Text; the skin turns that into a toggle
function DS.switch(parent, text, order)
    local row = DS.new("Frame", parent, { Size = U2(1, 0, 0, 40), BackgroundColor3 = T.surface3, LayoutOrder = order or 0 })
    DS.corner(row, 8)
    local btn = DS.new("TextButton", row, { Size = U2(1, 0, 1, 0), Text = text, TextTransparency = 1 })
    local lbl = DS.new("TextLabel", btn, { Size = U2(1, -64, 1, 0), Position = U2(0, 12, 0, 0), Font = F_GM, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
    local track = DS.new("Frame", btn, { Size = U2(0, 38, 0, 20), Position = U2(1, -50, 0.5, -10), BackgroundColor3 = T.off })
    DS.corner(track, 10)
    local knob = DS.new("Frame", track, { Size = U2(0, 14, 0, 14), Position = U2(0, 3, 0.5, -7), BackgroundColor3 = T.white })
    DS.corner(knob, 7)
    local function apply()
        local on, rest = parseCheck(btn.Text)
        if on == nil then return end
        lbl.Text = rest
        lbl.TextColor3 = on and T.text or T.text2
        TS:Create(track, TweenInfo.new(0.12), { BackgroundColor3 = on and T.ok or T.off }):Play()
        TS:Create(knob, TweenInfo.new(0.12), { Position = on and U2(1, -17, 0.5, -7) or U2(0, 3, 0.5, -7) }):Play()
        btn.Text = ""
    end
    btn:GetPropertyChangedSignal("Text"):Connect(apply)
    apply()
    return btn
end

function DS.chip(parent, text, order, color)
    local c = DS.new("TextLabel", parent, {
        Size = U2(1, 0, 0, 28), BackgroundColor3 = color or T.accentDim, Text = text, Font = F_GB, TextSize = 12,
        TextColor3 = T.white, LayoutOrder = order or 0,
    })
    DS.corner(c, 8)
    return c
end

-- labelled text input; "order" doubles as the layout position
function DS.fullInp(p, lblText, def, order, h)
    local box = DS.new("Frame", p, { Size = U2(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order or 0 })
    DS.vlist(box, 4)
    DS.label(box, lblText, 12, T.text2, F_GB, 1)
    local b = DS.new("TextBox", box, {
        Size = U2(1, 0, 0, math.max(h or 34, 34)), BackgroundColor3 = T.input, Text = def, TextColor3 = T.text, Font = F_GM,
        TextSize = 14, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, PlaceholderColor3 = T.text4, LayoutOrder = 2,
    })
    DS.corner(b, 8) DS.pad(b, 12, 0, 12, 0)
    local st = DS.stroke(b)
    b.Focused:Connect(function() st.Color = T.accent end)
    b.FocusLost:Connect(function() st.Color = T.stroke end)
    return b
end
function DS.inp(p, lblText, def, order) return DS.fullInp(p, lblText, def, order, 34) end

-- inline dropdown: opens in the layout flow (no overlap / clipping problems). Returns the button; .Text is the value.
function DS.dropdown(parent, labelText, options, defaultValue, order)
    local box = DS.new("Frame", parent, { Size = U2(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order or 0 })
    DS.vlist(box, 4)
    DS.label(box, labelText, 12, T.text2, F_GB, 1)
    local hold = DS.new("Frame", box, { Size = U2(1, 0, 0, 36), BackgroundColor3 = T.input, LayoutOrder = 2 })
    DS.corner(hold, 8) DS.stroke(hold)
    local button = DS.new("TextButton", hold, {
        Size = U2(1, 0, 1, 0), Text = tostring(defaultValue or options[1] or ""), TextColor3 = T.text, Font = F_GM, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    })
    DS.pad(button, 12, 0, 34, 0)
    local chev = DS.new("TextLabel", hold, { Size = U2(0, 24, 1, 0), Position = U2(1, -28, 0, 0), Text = "▾", Font = F_GB, TextSize = 14, TextColor3 = T.text3 })
    local menu = DS.new("ScrollingFrame", box, {
        Size = U2(1, 0, 0, math.min(#options * 32 + 8, 168)), BackgroundColor3 = T.surface2, Visible = false, LayoutOrder = 3,
        ScrollBarThickness = 3, ScrollBarImageColor3 = T.stroke, CanvasSize = U2(0, 0, 0, #options * 32 + 8),
    })
    DS.corner(menu, 8) DS.stroke(menu) DS.pad(menu, 4, 4, 4, 4) DS.vlist(menu, 0)
    for index, option in ipairs(options) do
        local item = DS.new("TextButton", menu, {
            Size = U2(1, 0, 0, 32), LayoutOrder = index, BackgroundColor3 = T.surface2, Text = tostring(option),
            TextColor3 = T.text, Font = F_GM, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
        })
        DS.corner(item, 6) DS.pad(item, 8, 0, 8, 0)
        item.MouseButton1Click:Connect(function()
            button.Text = tostring(option)
            menu.Visible = false
            chev.Text = "▾"
            if DS.onChange then DS.onChange() end
        end)
    end
    button.MouseButton1Click:Connect(function()
        menu.Visible = not menu.Visible
        chev.Text = menu.Visible and "▴" or "▾"
    end)
    button:GetPropertyChangedSignal("Visible"):Connect(function() box.Visible = button.Visible end)
    return button
end

-- ---------- layout containers ----------
-- single column, centred cards (Market, HUD, Fish, Gems, Settings)
function DS.page(parent)
    local sc = DS.new("ScrollingFrame", parent, {
        Size = U2(1, 0, 1, 0), ScrollBarThickness = 3, ScrollBarImageColor3 = T.stroke,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = U2(0, 0, 0, 0), ScrollingDirection = Enum.ScrollingDirection.Y,
    })
    DS.vlist(sc, 10).HorizontalAlignment = Enum.HorizontalAlignment.Center
    DS.pad(sc, 0, 0, 0, 8)
    return sc
end

function DS.card(page, title, sub, order)
    local c = DS.new("Frame", page, { Size = U2(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.surface, LayoutOrder = order or 0 })
    DS.corner(c, 12) DS.stroke(c) DS.pad(c, 14, 12, 14, 14) DS.vlist(c, 8)
    local limit = Instance.new("UISizeConstraint")
    limit.MaxSize = Vector2.new(520, 100000)
    limit.Parent = c
    if title then DS.label(c, title, 15, T.text, F_GB, -2) end
    if sub then
        local s = DS.label(c, sub, 12, T.text3, F_GM, -1)
        s.TextWrapped, s.TextTruncate, s.AutomaticSize, s.Size = true, Enum.TextTruncate.None, Enum.AutomaticSize.Y, U2(1, 0, 0, 16)
    end
    return c
end

-- two panes: list on the left, controls on the right. Stacks automatically on narrow screens.
function DS.split(page, leftW)
    local left = DS.new("Frame", page, { BackgroundColor3 = T.surface })
    DS.corner(left, 12) DS.stroke(left)
    local right = DS.new("ScrollingFrame", page, {
        ScrollBarThickness = 3, ScrollBarImageColor3 = T.stroke, AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = U2(0, 0, 0, 0), ScrollingDirection = Enum.ScrollingDirection.Y,
    })
    DS.vlist(right, 8) DS.pad(right, 0, 0, 6, 8)
    local function relayout()
        local w = page.AbsoluteSize.X / math.max(uiScale and uiScale.Scale or 1, 0.1)
        if w >= 640 then
            left.Position, left.Size = U2(0, 0, 0, 0), U2(0, leftW, 1, 0)
            right.Position, right.Size = U2(0, leftW + 10, 0, 0), U2(1, -(leftW + 10), 1, 0)
        else
            left.Position, left.Size = U2(0, 0, 0, 0), U2(1, 0, 0.45, 0)
            right.Position, right.Size = U2(0, 0, 0.45, 8), U2(1, 0, 0.55, -8)
        end
    end
    page:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
    relayout()
    return left, right
end

-- left pane of a checklist tab: Select all / Deselect all + scrolling tree
function DS.tree(card)
    local bar = DS.new("Frame", card, { Size = U2(1, -12, 0, 30), Position = U2(0, 6, 0, 6) })
    local function tb(txt, x)
        local b = DS.new("TextButton", bar, {
            Size = U2(0.5, -3, 1, 0), Position = U2(x, x == 0 and 0 or 3, 0, 0), BackgroundColor3 = T.surface3,
            Text = txt, TextColor3 = T.text2, Font = F_GM, TextSize = 12,
        })
        DS.corner(b, 6)
        return b
    end
    local sa, da = tb("Select all", 0), tb("Deselect all", 0.5)
    local pScr = DS.new("ScrollingFrame", card, {
        Size = U2(1, -12, 1, -44), Position = U2(0, 6, 0, 40), ScrollBarThickness = 3, ScrollBarImageColor3 = T.stroke,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = U2(0, 0, 0, 0), ScrollingDirection = Enum.ScrollingDirection.Y,
    })
    local lay = DS.vlist(pScr, 4)
    DS.pad(pScr, 0, 0, 6, 0)
    return sa, da, pScr, lay
end

-- one collapsible pack block: header (expand + checkbox) and an items frame
function DS.pack(pScr, order, packName)
    local pC = DS.new("Frame", pScr, { Size = U2(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order })
    DS.vlist(pC, 2)
    local pH = DS.new("Frame", pC, { Size = U2(1, 0, 0, 32), BackgroundColor3 = T.surface3, LayoutOrder = 1 })
    DS.corner(pH, 8)
    local eBtn = DS.new("TextButton", pH, { Size = U2(0, 32, 1, 0), Text = "+", Font = F_GB, TextSize = 16, TextColor3 = T.text2 })
    local cBtn = DS.new("TextButton", pH, {
        Size = U2(1, -32, 1, 0), Position = U2(0, 32, 0, 0), Text = " [ ] " .. packName, TextColor3 = T.text2,
        Font = F_GB, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    })
    DS.pad(cBtn, 4, 0, 6, 0) DS.row(cBtn)
    local iF = DS.new("Frame", pC, { Size = U2(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, LayoutOrder = 2 })
    DS.vlist(iF, 2) DS.pad(iF, 14, 2, 0, 4)
    return pC, eBtn, cBtn, iF
end

function DS.item(parent, text, textSize)
    local ib = DS.new("TextButton", parent, {
        Size = U2(1, 0, 0, 28), BackgroundColor3 = T.surface2, Text = text, TextColor3 = T.text3, Font = F_GM,
        TextSize = (textSize or 11) + 1, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    })
    DS.corner(ib, 6) DS.pad(ib, 10, 0, 6, 0)
    DS.row(ib)
    return ib
end


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

-- cards whose star trial failed, kept in their own file so the list survives restarts and "Reset Account State"
local FailedStore = { cards = {}, file = "ACC_FailedCards_" .. tostring(LP.UserId) .. ".json" }
pcall(function()
    if readfile and isfile and isfile(FailedStore.file) then
        local d = HS:JSONDecode(readfile(FailedStore.file))
        if type(d) == "table" and type(d.cards) == "table" then
            for _, c in ipairs(d.cards) do if type(c) == "string" then FailedStore.cards[c] = true end end
        end
    end
end)
function FailedStore.save()
    if not writefile then return end
    local list = {}
    for c in pairs(FailedStore.cards) do list[#list + 1] = c end
    table.sort(list)
    local packs = FailedStore.packs()
    pcall(writefile, FailedStore.file, HS:JSONEncode({ cards = list, packs = packs }))
end
function FailedStore.set(card, isFailed)
    if (FailedStore.cards[card] == true) == (isFailed == true) then return end
    FailedStore.cards[card] = isFailed and true or nil
    FailedStore.save()
end
-- packs (in shop order) that contain at least one failed card
function FailedStore.packs()
    local out = {}
    for _, pD in ipairs(CardSortedPacks) do
        for _, c in ipairs(CardPackCards[pD.Name] or {}) do
            if FailedStore.cards[c] then out[#out + 1] = pD.Name break end
        end
    end
    return out
end

-- Resume helper: a feature that was running when you left is started again until it really runs (the game data it needs,
-- e.g. your figurines or owned packs, can arrive later than the cards). While it is pending, the saved "was running" flag is kept,
-- so a slow start can never overwrite it.
local Resume = { pending = {}, tok = {} }
function Resume.cancel(label)
    Resume.tok[label] = (Resume.tok[label] or 0) + 1
    Resume.pending[label] = nil
end
function Resume.start(label, isRunning, start)
    Resume.tok[label] = (Resume.tok[label] or 0) + 1
    local my = Resume.tok[label]
    Resume.pending[label] = true
    task.spawn(function()
        task.wait(2)
        local t0 = os.clock()
        while Resume.tok[label] == my and os.clock() - t0 < 90 do
            if isRunning() then break end
            pcall(start)
            local started = false
            for _ = 1, 15 do
                task.wait(0.1)
                if isRunning() then started = true break end
            end
            if started then break end
            task.wait(2.5)
        end
        if Resume.tok[label] == my then Resume.pending[label] = nil end
    end)
end

-- ==========================================
-- 2. STRICT DIRECT UI LOOKUP
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
-- 3. MASTER UI SETUP (11 TABS, REDESIGNED)
-- ==========================================
local AllItemButtons, AllOpenerButtons = {}, {}
local SaveConfig, SaveState 
DS.onChange = function() if SaveConfig then SaveConfig() end end

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

local sg = DS.new("ScreenGui", targetParent, { Name = "ACC_Suite", ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false })

local sqBtn = DS.new("TextButton", sg, { AnchorPoint = Vector2.new(0.5, 0), Size = U2(0, 92, 0, 34), Position = U2(0.5, 0, 0, 16), BackgroundColor3 = T.surface, Text = "ACC  ▸", TextColor3 = T.text, Font = F_GB, TextSize = 13, Visible = false })
DS.corner(sqBtn, 17) DS.stroke(sqBtn, T.accent, 1.5)

local mFrame = DS.new("Frame", sg, { AnchorPoint = Vector2.new(0.5, 0.5), Size = U2(0.94, 0, 0.88, 0), Position = U2(0.5, 0, 0.5, 0), BackgroundColor3 = T.bg, Active = true, ClipsDescendants = true })
DS.corner(mFrame, 14) DS.stroke(mFrame)

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

uiScale = Instance.new("UIScale") uiScale.Scale = 1 uiScale.Parent = mFrame
local sqScale = Instance.new("UIScale") sqScale.Parent = sqBtn

-- UI scale: "Auto" picks a size from the screen (and whether it is a touch screen); a number is used as is.
-- The window is resized to fit the screen at that scale, so text stays visible at any setting.
local scaleSetting = "Auto"
local function viewport()
    local cam = workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1280, 720)
end
local function computeScale(txt)
    local n = tonumber(txt)
    if n then return n end
    local vp = viewport()
    local s = UIS.TouchEnabled and vp.Y / 760 or vp.Y / 1080
    return math.clamp(math.floor(s * 20 + 0.5) / 20, 1, 2.5)
end
local function fitWindow()
    local vp, sc = viewport(), math.max(uiScale.Scale, 0.1)
    mFrame.Size = U2(0, math.clamp(vp.X * 0.94 / sc, 340, 1000), 0, math.clamp(vp.Y * 0.9 / sc, 420, 760))
end
local function applyScale(txt)
    scaleSetting = txt or scaleSetting
    uiScale.Scale = computeScale(scaleSetting)
    sqScale.Scale = uiScale.Scale
    fitWindow()
end
applyScale("Auto")
pcall(function() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() applyScale() end) end)

-- title bar
local tBar = DS.new("Frame", mFrame, { Size = U2(1, 0, 0, 48), Active = true })
local minBtn
do
    local logo = DS.new("TextLabel", tBar, { Size = U2(0, 28, 0, 28), Position = U2(0, 14, 0.5, -14), BackgroundColor3 = T.accent, Text = "A", Font = F_GB, TextSize = 15, TextColor3 = T.white })
    DS.corner(logo, 8)
    DS.new("TextLabel", tBar, { Size = U2(1, -110, 0, 18), Position = U2(0, 52, 0, 7), Text = "ACC Master Suite", Font = F_GB, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
    DS.new("TextLabel", tBar, { Size = U2(1, -110, 0, 14), Position = U2(0, 52, 0, 26), Text = "@" .. LP.Name, Font = F_GM, TextSize = 11, TextColor3 = T.text3, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
    minBtn = DS.new("TextButton", tBar, { Size = U2(0, 32, 0, 32), Position = U2(1, -44, 0.5, -16), BackgroundColor3 = T.surface3, Text = "–", Font = F_GB, TextSize = 16, TextColor3 = T.text2 })
    DS.corner(minBtn, 8)
end
DS.new("Frame", mFrame, { Size = U2(1, 0, 0, 1), Position = U2(0, 0, 0, 48), BackgroundColor3 = T.stroke })

-- tab strip + pages
local tFrames, tBtns = {}, {}
do
    local tabC = DS.new("ScrollingFrame", mFrame, {
        Size = U2(1, 0, 0, 40), Position = U2(0, 0, 0, 49), ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 2,
        ScrollBarImageColor3 = T.stroke, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = U2(0, 0, 0, 0),
    })
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection, tabLayout.SortOrder, tabLayout.Padding = Enum.FillDirection.Horizontal, Enum.SortOrder.LayoutOrder, UDim.new(0, 4)
    tabLayout.Parent = tabC
    DS.pad(tabC, 10, 4, 10, 4)

    local tabNames = { "Cards", "Tower", "Auto Tower", "Star Trial", "Opener", "Figurines", "Market", "Raid", "Fish", "Gems", "Exchange", "Collect", "HUD", "Spy", "Settings" }
    for i, name in ipairs(tabNames) do
        local b = DS.new("TextButton", tabC, { Size = U2(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = i, BackgroundColor3 = T.surface3, Text = name, Font = F_GB, TextSize = 12 })
        DS.corner(b, 8) DS.pad(b, 12, 0, 12, 0)
        tBtns[i] = b
        local f = DS.new("Frame", mFrame, { Size = U2(1, 0, 1, -90), Position = U2(0, 0, 0, 90), ClipsDescendants = true })
        DS.pad(f, 10, 8, 10, 10)
        tFrames[i] = f
    end
    local function selectTab(idx)
        for j, b in ipairs(tBtns) do
            local on = j == idx
            b.BackgroundTransparency = on and 0 or 1
            b.BackgroundColor3 = on and T.accent or T.surface3
            b.TextColor3 = on and T.white or T.text3
            tFrames[j].Visible = on
        end
    end
    for i, btn in ipairs(tBtns) do btn.MouseButton1Click:Connect(function() selectTab(i) end) end
    selectTab(1)
end
local cFrame, tFrame, autoFrame, starFrame, oFrame, figFrame, mktFrame, raidFrame, fFrame, gFrame, exFrame, colFrame, hudTabFrame, spyFrame, sFrame = unpack(tFrames)

minBtn.MouseButton1Click:Connect(function() mFrame.Visible = false sqBtn.Visible = true end)
sqBtn.MouseButton1Click:Connect(function()
    if sqBtn:GetAttribute("wasDragged") then return end
    sqBtn.Visible = false mFrame.Visible = true
end)
DS.drag(tBar, mFrame)
DS.drag(sqBtn, sqBtn)

local mkInp, mkFullInp, mkDropdown = DS.inp, DS.fullInp, DS.dropdown


-- ==========================================
-- 4. SPY SCANNER (WITH FILE DUMP)
-- ==========================================
local function buildSpy(parent)
    local env = (type(getgenv) == "function" and getgenv()) or _G
    local listening, view, scanEntries, liveEntries = false, "scan", {}, {}
    local selectedBody, renderQueued, hookNote = "", false, "hook not installed yet"
    local bound = env.ACC_SpyBound or {} env.ACC_SpyBound, env.ACC_SpyOn = bound, false

    local bar = DS.new("Frame", parent, { Size = U2(1, 0, 0, 32) })
    local filter = DS.new("TextBox", parent, {
        Size = U2(1, 0, 0, 32), Position = U2(0, 0, 0, 40), BackgroundColor3 = T.input, TextColor3 = T.text, PlaceholderText = "Filter (remote, module, args...)",
        PlaceholderColor3 = T.text4, Text = "", Font = F_GM, TextSize = 13, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
    })
    DS.corner(filter, 8) DS.stroke(filter) DS.pad(filter, 12, 0, 12, 0)

    local status = DS.new("TextLabel", parent, {
        Size = U2(1, -170, 0, 18), Position = U2(0, 2, 0, 80), Font = F_GM, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = T.text3, Text = "Full maps the game. Listen logs calls.", TextTruncate = Enum.TextTruncate.AtEnd,
    })
    local copyBtn = DS.new("TextButton", parent, { Size = U2(0, 70, 0, 22), Position = U2(1, -70, 0, 78), BackgroundColor3 = T.surface3, TextColor3 = T.text2, Text = "Copy", Font = F_GM, TextSize = 12 })
    local dumpBtn = DS.new("TextButton", parent, { Size = U2(0, 84, 0, 22), Position = U2(1, -160, 0, 78), BackgroundColor3 = T.surface3, TextColor3 = T.text2, Text = "Dump file", Font = F_GM, TextSize = 12 })
    DS.corner(copyBtn, 6) DS.corner(dumpBtn, 6)

    local listWrap = DS.new("Frame", parent, { Size = U2(1, 0, 1, -212), Position = U2(0, 0, 0, 108), BackgroundColor3 = T.input })
    DS.corner(listWrap, 8) DS.stroke(listWrap)
    local list = DS.new("ScrollingFrame", listWrap, { Size = U2(1, -8, 1, -8), Position = U2(0, 4, 0, 4), ScrollBarThickness = 4, ScrollBarImageColor3 = T.stroke, CanvasSize = U2(0, 0, 0, 0) })
    local lay = DS.vlist(list, 2)
    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() list.CanvasSize = U2(0, 0, 0, lay.AbsoluteContentSize.Y + 4) end)

    local detail = DS.new("TextBox", parent, {
        Size = U2(1, 0, 0, 96), Position = U2(0, 0, 1, -96), BackgroundColor3 = T.input, TextColor3 = T.text2, Font = F_GM, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, ClearTextOnFocus = false,
        TextEditable = false, MultiLine = true, Text = "Nothing selected.",
    })
    DS.corner(detail, 8) DS.stroke(detail) DS.pad(detail, 10, 8, 10, 8)

    local labels = { "Full", "Listen", "Clear" }
    local buttons = {}
    for i, name in ipairs(labels) do
        local b = DS.new("TextButton", bar, { Size = U2(1 / #labels, -4, 1, 0), Position = U2((i - 1) / #labels, (i - 1) * 2, 0, 0), BackgroundColor3 = T.surface3, TextColor3 = T.text, Text = name, Font = F_GB, TextSize = 12 })
        DS.corner(b, 8)
        buttons[name] = b
    end

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
                local tint = string.sub(entry.title, 1, 5) == "[OUT]" and Color3.fromRGB(147, 197, 253) or (string.sub(entry.title, 1, 4) == "[IN]" and T.ok2 or T.text2)
                local row = DS.new("TextButton", list, {
                    Size = U2(1, -6, 0, 22), BackgroundColor3 = (i % 2 == 0) and T.surface2 or T.surface, TextColor3 = tint, Font = F_GM, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left, Text = "  " .. entry.title, LayoutOrder = i, TextTruncate = Enum.TextTruncate.AtEnd,
                })
                DS.corner(row, 4)
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
            if env.ACC_SpyOn and (method == "FireServer" or method == "InvokeServer") and typeof(self) == "Instance" then
                -- capture only; do all work outside the hook (nested calls here can corrupt the namecall method)
                local rem, mth, packed = self, method, table.pack(...)
                task.defer(function()
                    env.ACC_SpyBusy = true
                    pcall(env.ACC_SpyDispatch, rem, mth, { table.unpack(packed, 1, packed.n) })
                    env.ACC_SpyBusy = false
                end)
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
end

-- ==========================================
-- 5. BACKGROUND MODULES (MARKET, HUD, RAID, FISH, GEMS)
-- ==========================================
local remotes = RS:FindFirstChild("Remotes")
local function getRemote(name)
    return remotes and remotes:FindFirstChild(name) or nil
end

-- MARKET AUTO-BUY ALL ON REFRESH
local mktPnl = DS.card(DS.page(mktFrame), "Market", "Buys every item in the shop the moment it restocks.", 1)
local mktBuyBtn = DS.switch(mktPnl, "[ ] Auto-Buy All on Refresh", 1)
local mktNowBtn = DS.btn(mktPnl, "Trigger BuyAll Now", "info", 2, 38)
local mktStat = DS.status(mktPnl, "Status: Idle", 3)

local isMarketBuyAll = false
local marketBuyCount = 0
local lastStockSignature = ""
local stockEvt = getRemote("Stock")
local getStockFn = getRemote("GetStock")
local updateStockTimeEvt = getRemote("UpdateStockTime")

local lastBuyAt = -1e9
local stockInterval = 300 -- seconds between restocks, learned from the shop timer
local function executeMarketBuyAll(reason, force)
    if not stockEvt then
        mktStat.Text = "ERR: Stock Remote Missing"
        return
    end
    -- one BuyAll per restock: the timer and the stock event both fire around a restock, so ignore repeats for 20s
    if not force and os.clock() - lastBuyAt < 20 then return end
    lastBuyAt = os.clock()
    task.wait(0.25) -- Brief buffer so server finishes populating restocked items
    if pcall(function() stockEvt:FireServer("BuyAll") end) then
        marketBuyCount = marketBuyCount + 1
        mktStat.Text = string.format("Bought All (%s) | Total Restocks: %d | next in about %ds", reason or "Refresh", marketBuyCount, stockInterval)
    end
end

if updateStockTimeEvt then
    updateStockTimeEvt.OnClientEvent:Connect(function(timeLeft)
        if not isMarketBuyAll then return end
        -- When stock timer resets (high value or <= 1s rollover), trigger BuyAll
        local t = tonumber(timeLeft)
        if t and t > stockInterval then stockInterval = math.floor(t + 0.5) end
        if t and (t <= 1 or t >= stockInterval - 5) then
            executeMarketBuyAll("Timer Reset")
        end
    end)
end

if stockEvt then
    stockEvt.OnClientEvent:Connect(function(action)
        if not isMarketBuyAll then return end
        if action == "Refresh" or action == "Restock" or action == "Update" then
            executeMarketBuyAll("Stock Event")
        end
    end)
end

-- safety net: if the shop events never arrive, buy once per refresh interval anyway
task.spawn(function()
    while mFrame:IsDescendantOf(game) do
        task.wait(5)
        if isMarketBuyAll and os.clock() - lastBuyAt > stockInterval + 15 then executeMarketBuyAll("Interval") end
    end
end)

local function setMarketBuyState(state)
    isMarketBuyAll = state and stockEvt ~= nil
    mktBuyBtn.Text = isMarketBuyAll and "[X] Auto-Buy All on Refresh" or "[ ] Auto-Buy All on Refresh"
    mktBuyBtn.BackgroundColor3 = isMarketBuyAll and C3(40,200,120) or C3(50,50,50)
    mktBuyBtn.TextColor3 = isMarketBuyAll and C3(255,255,255) or C3(200,200,200)
    if isMarketBuyAll then
        mktStat.Text = "Listening for shop refresh..."
        task.spawn(executeMarketBuyAll, "Initial Sweep", true)
    else
        mktStat.Text = "Status: Idle"
    end
end

mktBuyBtn.MouseButton1Click:Connect(function()
    setMarketBuyState(not isMarketBuyAll)
    if SaveState then SaveState() end
end)

mktNowBtn.MouseButton1Click:Connect(function()
    executeMarketBuyAll("Manual", true)
end)

-- HUD
local isHudEnabled = false
local accHud = DS.new("Frame", sg, { Size = U2(0, 190, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = U2(0, 20, 0.5, -60), BackgroundColor3 = T.bg, BackgroundTransparency = 0.12, Active = true, Visible = false })
DS.corner(accHud, 10) DS.stroke(accHud) DS.pad(accHud, 10, 8, 10, 8) DS.vlist(accHud, 4)
DS.drag(accHud, accHud)

local function mkHudRow(py, iconId, defText)
    local r = DS.new("Frame", accHud, { Size = U2(1, 0, 0, 24), LayoutOrder = py })
    DS.new("ImageLabel", r, { Size = U2(0, 18, 0, 18), Position = U2(0, 0, 0.5, -9), Image = iconId })
    return DS.new("TextLabel", r, { Size = U2(1, -26, 1, 0), Position = U2(0, 26, 0, 0), Text = defText, Font = F_GB, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
end
local hCash = mkHudRow(30, "rbxassetid://84225083685543", "Cash: 0")
local hEvt = mkHudRow(55, "rbxassetid://82846623271410", "Event: 0")
local hGrade = mkHudRow(80, "rbxassetid://76024843045813", "Grade: 0")
local hFish = mkHudRow(105, "rbxassetid://131575541379453", "Fish: 0")

local hudTglBtn = DS.switch(DS.card(DS.page(hudTabFrame), "Live HUD", "Floating counters for cash, event, grade and fish tokens. Drag it anywhere.", 1), "[ ] Enable Live HUD", 1)
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

-- FISH
local fPnl = DS.card(DS.page(fFrame), "Auto Fish", "Casts the rod and reels in on a loop.", 1)
local fDelInp = mkInp(fPnl, "Loop Delay (Seconds)", "3", 50) fDelInp.FocusLost:Connect(function() if SaveConfig then SaveConfig() end end)
local fTglBtn = DS.btn(fPnl, "Stop Auto-Fish", "danger", 60, 40)

-- RAID
local RaidConfig, CardConfig
pcall(function() RaidConfig = require(RS.Modules.Config.Core.RaidConfig) end)
pcall(function() CardConfig = require(RS.Modules.Config.Core.CardConfig) end)

local raidPacks = RaidConfig and RaidConfig.ActiveRaids or {}
local raidListCard, raidPanel = DS.split(raidFrame, 260)
local raidStatus = DS.status(raidPanel, "Status: Idle", 1)
local raidBtn = DS.btn(raidPanel, "Start Auto-Raid", "ok", 2, 40)
local raidVisBtn = DS.switch(raidPanel, "[X] No raid teleport / visuals", 3)
local raidJoinAll = false
local raidAllBtn = DS.switch(raidPanel, "[ ] Join ALL raids (needed for manga tokens)", 4)
DS.label(raidListCard, "Raid packs  -  tap to queue", 12, T.text2, F_GB).Position = U2(0, 12, 0, 8)
local raidPackList = DS.new("ScrollingFrame", raidListCard, { Size = U2(1, -12, 1, -38), Position = U2(0, 6, 0, 32), ScrollBarThickness = 3, ScrollBarImageColor3 = T.stroke, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = U2(0, 0, 0, 0) })
local raidPackLayout = DS.vlist(raidPackList, 4)
DS.pad(raidPackList, 0, 0, 6, 0)
local raidSelectedPacks, raidPackButtons = {}, {}

local function raidProgress(packName)
    return math.max(0, tonumber(getLiveData("RaidsDefeated", "Packs", packName)) or 0)
end

local function refreshRaidPackRows()
    for _, packName in ipairs(raidPacks) do
        local button = raidPackButtons[packName]
        if button then
            local count = raidProgress(packName)
            if count >= 9 then
                -- finished packs can never stay queued: clear the selection so the green check goes away
                raidSelectedPacks[packName] = nil
                button.Text = "[ ] " .. packName .. "\t\t\226\156\147 9/9"
                button.TextColor3 = C3(150, 150, 150)
            else
                button.Text = (raidSelectedPacks[packName] and "[X] " or "[ ] ") .. packName .. "  " .. tostring(count) .. "/9"
                button.TextColor3 = raidSelectedPacks[packName] and C3(40, 220, 130) or C3(210, 210, 210)
            end
        end
    end
end

for index, packName in ipairs(raidPacks) do
    local packBtn = DS.new("TextButton", raidPackList, { Size = U2(1, 0, 0, 34), LayoutOrder = index, BackgroundColor3 = T.surface2, TextColor3 = T.text2, Text = "[ ] " .. packName .. "  0/9", Font = F_GM, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
    DS.corner(packBtn, 8) DS.pad(packBtn, 10, 0, 8, 0) DS.row(packBtn)
    raidPackButtons[packName] = packBtn
    packBtn.MouseButton1Click:Connect(function()
        if raidProgress(packName) >= 9 then return end
        raidSelectedPacks[packName] = not raidSelectedPacks[packName]
        refreshRaidPackRows()
    end)
end
local raidRunning, raidRun = false, 0

-- ===== no raid teleport / visuals =====
-- The game's raid events all go through RaidHandler[eventName]; the raid itself is run by the server (the client never sends an attack
-- answer), so swapping the UI / teleport functions for empty ones only removes what you see and where you get moved:
--   JoinedRaid  : PivotTo into the arena, WalkSpeed = 0, opens the raid screen
--   Results / LeftRaid / EnterRaidLobby : teleport to the raid lobby + screen flash, results screen
--   the rest    : health bars, damage tweens, notifications, vote popups
-- Joining and voting (the Join / Vote remote calls of Auto-Raid) are not touched. Only active while Auto-Raid runs.
local raidNoVis, raidOrig = true, nil
local RAID_NOOPS = { "JoinedRaid", "LeftRaid", "EnterRaidLobby", "ExitRaidLobby", "Results", "CheckpointReached", "RaidNotify", "Revived",
    "PlayerJoinedRaid", "PlayerLeftRaid", "PlayerAttack", "BossAttack", "PlayerDied", "PlayerCardDefeated", "CardDefeated",
    "ShowFrame", "InitEnemy", "InitPlayer", "VoteStart", "VoteEnd", "UpdateVotes" }
local function applyRaidVis(on)
    local H
    pcall(function() H = require(RS.Client.UI.RaidHandler) end)
    if type(H) ~= "table" then return end
    if on and not raidOrig then
        raidOrig = {}
        for _, name in ipairs(RAID_NOOPS) do
            if type(H[name]) == "function" then raidOrig[name] = H[name] H[name] = function() end end
        end
    elseif not on and raidOrig then
        for name, fn in pairs(raidOrig) do H[name] = fn end
        raidOrig = nil
    end
end
raidVisBtn.MouseButton1Click:Connect(function()
    raidNoVis = not raidNoVis
    raidVisBtn.Text = (raidNoVis and "[X] " or "[ ] ") .. "No raid teleport / visuals"
    applyRaidVis(raidRunning and raidNoVis)
    if SaveConfig then SaveConfig() end
end)

raidAllBtn.MouseButton1Click:Connect(function()
    raidJoinAll = not raidJoinAll
    raidAllBtn.Text = (raidJoinAll and "[X] " or "[ ] ") .. "Join ALL raids (needed for manga tokens)"
    raidAllBtn.BackgroundColor3 = raidJoinAll and C3(40, 200, 120) or C3(50, 50, 50)
    if SaveConfig then SaveConfig() end
end)

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
        if not raidRunning and raidOrig then applyRaidVis(false) end
        task.wait(2)
    end
end)

local function setRaidState(state)
    raidRunning, raidRun = state, raidRun + 1
    local myRun = raidRun
    raidBtn.Text, raidBtn.BackgroundColor3 = raidRunning and "Stop Auto-Raid" or "Start Auto-Raid", raidRunning and C3(200, 40, 40) or C3(40, 200, 120)
    applyRaidVis(raidRunning and raidNoVis)
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
    if #queue == 0 and not raidJoinAll then
        raidRunning = false
        raidBtn.Text = "Select a raid pack"
        return
    end
    task.spawn(function()
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
            if not packName and raidJoinAll then
                -- nothing left to progress: keep joining every raid that starts; vote for the first unfinished pack
                for _, name in ipairs(raidPacks) do
                    if raidProgress(name) < 9 then packName = name break end
                end
                packName = packName or raidPacks[1] or "?"
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
            if raidJoinAll and raidGoing then
                -- join whatever raid is running, not only the queued pack
                packName = tostring(activePack)
                progress = raidProgress(packName)
            end
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

-- AUTO TOWER (call pattern learned from a qyrix capture)
local AutoAPI = {}
do
    local pg = DS.page(autoFrame)
    local tCard = DS.card(pg, "Auto Tower", "Climbs the tower on a loop: StartTower, a burst of AttackDone, EquipBest.", 1)
    local tStat = DS.status(tCard, "Status: Idle", 1)
    local tDelay = DS.fullInp(tCard, "Cycle delay (seconds)", "0.15", 2, 30)
    local tBurst = DS.dropdown(tCard, "AttackDone per cycle", { "1", "2", "3", "4", "5", "6", "8", "10" }, "3", 3)
    local tLimit = DS.fullInp(tCard, "Stop at floor (0 = never)", "0", 4, 30)
    local tEqBtn = DS.switch(tCard, "[X] Equip best each cycle", 5)
    local tBtn = DS.btn(tCard, "Start Auto Tower", "ok", 6, 40)

    local function save() if SaveConfig then SaveConfig() end end
    for _, b in ipairs({ tDelay, tLimit }) do b.FocusLost:Connect(save) end

    local towerRem = getRemote("Tower")
    local tRun, tId, floor, cleared, eq = false, 0, nil, 0, true

    if towerRem then
        towerRem.OnClientEvent:Connect(function(action, a)
            if action == "FloorCleared" then
                floor = tonumber(a) or floor
                cleared = cleared + 1
                if tRun then tStat.Text = "Floor " .. tostring(floor) .. "  |  cleared " .. cleared end
            end
        end)
    end

    local function setTower(on)
        if on and not towerRem then tBtn.Text = "ERR: Tower Remote Missing" return end
        tRun = on and true or false
        tBtn.Text = tRun and "Stop Auto Tower" or "Start Auto Tower"
        tBtn.BackgroundColor3 = tRun and C3(200, 40, 40) or C3(40, 200, 120)
        if not tRun then tStat.Text = "Status: Idle" return end
        tId = tId + 1
        local run = tId
        cleared = 0
        tStat.Text = "Status: Running"
        task.spawn(function()
            while tRun and run == tId and mFrame:IsDescendantOf(game) do
                local n = math.clamp(math.floor(tonumber(tBurst.Text) or 3), 1, 10)
                pcall(function() towerRem:FireServer("StartTower") end)
                task.wait()
                for _ = 1, 2 do pcall(function() towerRem:FireServer("AttackDone") end) end
                if eq then pcall(function() towerRem:FireServer("EquipBest") end) end
                task.wait()
                for _ = 1, n do pcall(function() towerRem:FireServer("AttackDone") end) end
                local lim = tonumber(tLimit.Text) or 0
                if lim > 0 and floor and floor >= lim then
                    tRun = false
                    tBtn.Text, tBtn.BackgroundColor3 = "Start Auto Tower", C3(40, 200, 120)
                    tStat.Text = "Stopped at floor " .. tostring(floor)
                    if SaveState then SaveState() end
                    break
                end
                task.wait(math.max(tonumber(tDelay.Text) or 0.15, 0.05))
            end
        end)
    end

    tEqBtn.MouseButton1Click:Connect(function()
        eq = not eq
        tEqBtn.Text = (eq and "[X] " or "[ ] ") .. "Equip best each cycle"
        tEqBtn.BackgroundColor3 = eq and C3(40, 200, 120) or C3(50, 50, 50)
        save()
    end)
    tBtn.MouseButton1Click:Connect(function() setTower(not tRun) if SaveState then SaveState() end end)
    setTower(false)

    AutoAPI.GetConfig = function()
        return { delay = tDelay.Text, burst = tBurst.Text, limit = tLimit.Text, eq = eq }
    end
    AutoAPI.LoadConfig = function(c)
        if not c then return end
        if c.delay then tDelay.Text = tostring(c.delay) end
        if c.burst then tBurst.Text = tostring(c.burst) end
        if c.limit then tLimit.Text = tostring(c.limit) end
        if c.eq ~= nil then
            eq = c.eq
            tEqBtn.Text = (eq and "[X] " or "[ ] ") .. "Equip best each cycle"
            tEqBtn.BackgroundColor3 = eq and C3(40, 200, 120) or C3(50, 50, 50)
        end
    end
    AutoAPI.GetState = function() return { tower = tRun } end
    AutoAPI.LoadState = function(st)
        if not st then return end
        if st.tower ~= nil and st.tower ~= tRun then setTower(st.tower) end
    end
end

local gPnl = DS.card(DS.page(gFrame), "Auto Gems", "Sweeps every gallery page and collects gems on a loop.", 1)
local gmBtn = DS.btn(gPnl, "Start Auto-Gems", "ok", 1, 40)
local gmStat = DS.status(gPnl, "Status: Idle", 2)
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

-- ==========================================
-- 6. STRICT CASH-ONLY GRADER
-- ==========================================
local GraderAPI = {}

local function bGrader(pFrame, sData, pcData, rName, aName, gList, gRanks)
    local lPnl, rPnl = DS.split(pFrame, 230)
    local saBtn, daBtn, pScr, sLyt = DS.tree(lPnl)
    
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
        local pC, eBtn, cBtn, iF = DS.pack(pScr, lIdx, pN) local iBtns = {} SData[pN].cBtn = cBtn
        if pcData[pN] then for _, iN in ipairs(pcData[pN]) do
            SData[pN].items[iN] = false
            local ib = DS.item(iF, "   ↳ [ ] "..iN, 11)
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
    
    local sLbl = DS.status(rPnl, "Status: Idle", 0)

    local selG = "UR"
    local tgBtn = DS.new("TextButton", rPnl, { Size = U2(1, 0, 0, 36), BackgroundColor3 = T.surface3, TextColor3 = T.amber, Font = F_GB, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 10, Text = "Target: " .. selG })
    DS.corner(tgBtn, 8) DS.pad(tgBtn, 12, 0, 12, 0)
    local gScr = DS.new("ScrollingFrame", rPnl, { Size = U2(1, 0, 0, 132), BackgroundColor3 = T.surface2, Visible = false, LayoutOrder = 11, ScrollBarThickness = 3, ScrollBarImageColor3 = T.stroke, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = U2(0, 0, 0, 0) })
    DS.corner(gScr, 8) DS.stroke(gScr) DS.pad(gScr, 4, 4, 4, 4) DS.vlist(gScr, 2)
    for gi = #gList, 1, -1 do
        local g = gList[gi]
        local b = DS.new("TextButton", gScr, { Size = U2(1, 0, 0, 28), BackgroundColor3 = T.surface3, Text = g, Font = F_GM, TextSize = 12, TextColor3 = T.text, LayoutOrder = #gList - gi })
        DS.corner(b, 6)
        b.MouseButton1Click:Connect(function() selG = g tgBtn.Text = "Target: "..g gScr.Visible = false if SaveConfig then SaveConfig() end end)
    end
    tgBtn.MouseButton1Click:Connect(function() gScr.Visible = not gScr.Visible end)

    local cTypeLbl = DS.chip(rPnl, "Currency: Cash Only", 20)
    local anBtn = DS.switch(rPnl, "[X] Auto Next Item", 30)
    local apBtn = DS.switch(rPnl, "[X] Auto Next Pack", 40)

    local fBtn = DS.btn(rPnl, "Filter Missing Grades", "accent", 50, 36)
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
    
    local dInp = mkFullInp(rPnl, "Delay (ms)", "300", 255, 30)
    dInp.FocusLost:Connect(function() if SaveConfig then SaveConfig() end end)
    local sgBtn = DS.btn(rPnl, "Start Grader", "ok", 315, 40)
    
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
        return {isG = isG or Resume.pending.grader == true, items = checked}
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
            Resume.start("grader", function() return isG end, function() if not isG then setGraderRunning(true) end end)
        end
    end
end
bGrader(cFrame, CardSortedPacks, CardPackCards, "Grade", "Roll", GRADE_LIST, GRADE_RANK)

-- ==========================================
-- 7. TOWER TRAIT ROLLER
-- ==========================================
local TowerAPI = {}

local function bTraitRoller(pFrame, sData, pcData)
    local lPnl, rPnl = DS.split(pFrame, 230)
    local saBtn, daBtn, pScr, sLyt = DS.tree(lPnl)
    
    local SData = {}
    local CardBtnMap = {}

    local function towerSummary(cardName)
        for _, collection in ipairs({ "TowerCards", "Cards" }) do
            local record = getLiveRecord(collection, cardName)
            if record then
                local mut = record.Mutation and tostring(record.Mutation) or ""
                if mut == "Regular" then mut = "" end
                return "\t" .. (exactGrade(record.Grade) or "") .. "\t" .. tostring(record.Trait or "") .. "\t" .. mut
            end
        end
        return "\t\tnot owned"
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
        local pC, eBtn, cBtn, iF = DS.pack(pScr, lIdx, pN) local iBtns = {} SData[pN].cBtn = cBtn
        if pcData[pN] then for _, iN in ipairs(pcData[pN]) do
            SData[pN].items[iN] = false
            local ib = DS.item(iF, "   ↳ [ ] "..iN..towerSummary(iN), 11)
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
    
    local sLbl = DS.status(rPnl, "Status: Idle", 0)
    
    local towerTraits = {}
    pcall(function()
        local towerConfig = require(RS.Modules.Config.Core.TowerConfig)
        for _, trait in ipairs(towerConfig.TraitList or {}) do towerTraits[#towerTraits + 1] = trait end
    end)
    local tInp = mkDropdown(rPnl, "Target Tower Trait", towerTraits, towerTraits[1], 40, 260)
    
    local anBtn = DS.switch(rPnl, "[X] Auto Next Item", 110)
    local apBtn = DS.switch(rPnl, "[X] Auto Next Pack", 150)
    local dInp = mkFullInp(rPnl, "Delay (ms)", "300", 255, 30)
    dInp.FocusLost:Connect(function() if SaveConfig then SaveConfig() end end)
    
    local stBtn = DS.btn(rPnl, "Start Roller", "ok", 315, 40)
    
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
        return {isT = isT or Resume.pending.tower == true, items = checked}
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
            Resume.start("tower", function() return isT end, function() if not isT then setRollerRunning(true) end end)
        end
    end
end
bTraitRoller(tFrame, CardSortedPacks, CardPackCards)

-- ==========================================
-- 7b. STAR TRIAL: card/pack queue, live stars, scan, concurrent trials
-- ==========================================
local StarAPI = {}
local MAX_STAR = 5

local TRIAL_DIFFICULTIES = { "Easy", "Medium", "Hard", "Extreme", "Nightmare" }

local function bStarTrial(pFrame, sData, pcData)
    local lPnl, rPnl = DS.split(pFrame, 300)
    local saBtn, daBtn, pScr = DS.tree(lPnl)
    local SData = {}
    local failed, done = {}, {}
    local blockedNote = function(_) end

    local function infoOf(name)
        local r = getLiveRecord("Cards", name)
        if not r then return nil end
        return {
            star = tonumber(r.Star) or 0,
            grade = exactGrade(r.Grade) or (r.Grade and stripTags(tostring(r.Grade))) or "",
            mut = r.Mutation and tostring(r.Mutation) or "Regular",
            trait = r.Trait and tostring(r.Trait) or "",
        }
    end
    -- what the game needs for this card's NEXT star: completions per difficulty + currency (from StarTrialConfig)
    local StarCfg
    pcall(function() StarCfg = require(RS.Modules.Config.Core.StarTrialConfig) end)
    local function diffRank(d) for k, v in ipairs(TRIAL_DIFFICULTIES) do if v == d then return k end end return 0 end
    local function nextReq(card)
        local i = infoOf(card)
        if not i or i.star >= MAX_STAR then return nil end
        local ev = StarCfg and StarCfg.StarEvolutions and StarCfg.StarEvolutions[tostring(i.star + 1)]
        if type(ev) ~= "table" then return nil end
        local sd = getLiveData("StarData", card)
        local r = { ready = true, diff = nil, short = nil }
        local top
        for d, n in pairs(ev.Completions or {}) do
            if diffRank(d) > diffRank(top) then top = d end
            local have, rd = 0, diffRank(d)
            if type(sd) == "table" and rd > 0 then
                for k, v in pairs(sd) do if diffRank(k) >= rd then have = math.max(have, tonumber(v) or 0) end end
            end
            if have < n and (not r.diff or diffRank(d) < diffRank(r.diff)) then r.diff = d r.ready = false end
        end
        for k, n in pairs(ev.Currency or {}) do
            if (tonumber(getLiveData("StarCurrency", k)) or 0) < n then r.short = k r.ready = false end
        end
        r.top = top
        return r
    end
    local function rowText(name, on)
        local i = infoOf(name)
        local tail = i and ("\t" .. i.grade .. "\t★" .. i.star .. "\t" .. (i.mut ~= "Regular" and i.mut or "") .. "\t" .. i.trait) or "\t\tnot owned"
        local tag = failed[name] and "\t✗ failed" or (done[name] and "\t✓ done" or "")
        return "   ↳ " .. (on and "[X] " or "[ ] ") .. name .. tail .. tag
    end
    local function paintPack(pN)
        local d = SData[pN]
        local any = false
        for _, v in pairs(d.items) do if v then any = true break end end
        d.isSelected = any
        d.cBtn.Text = (any and " [X] " or " [ ] ") .. pN
        d.cBtn.TextColor3 = any and C3(40, 200, 120) or C3(200, 200, 200)
    end
    local function setItem(pN, iN, on)
        local d = SData[pN]
        if on and (failed[iN] or done[iN]) then on = false end -- failed / completed cards cannot be selected
        if on then local i0 = infoOf(iN) if i0 and i0.star >= MAX_STAR then on = false end end -- neither can maxed cards
        d.items[iN] = on and true or false
        local b = d.btns[iN]
        b.Text = rowText(iN, d.items[iN])
        b.TextColor3 = failed[iN] and C3(220, 70, 70) or done[iN] and C3(96, 165, 250) or (d.items[iN] and C3(40, 200, 120) or C3(150, 150, 150))
    end
    local function refreshPack(pN)
        local d = SData[pN]
        for iN, b in pairs(d.btns) do
            local txt = rowText(iN, d.items[iN])
            if b.Text ~= txt then b.Text = txt end
        end
    end

    -- kind: "done" (star went up), "failed" (upgrade did not work) or nil to clear
    local function markStatus(card, kind)
        failed[card], done[card] = nil, nil
        if kind == "done" then done[card] = true elseif kind == "failed" then failed[card] = true end
        FailedStore.set(card, kind == "failed")
        for pN, d in pairs(SData) do
            if d.items[card] ~= nil then
                if kind then d.items[card] = false end
                setItem(pN, card, d.items[card])
                paintPack(pN)
            end
        end
    end

    -- select-all skips failed / done / maxed cards. A direct pick of a pack whose remaining cards are all failed / done
    -- clears those marks and selects them again.
    local function setPack(pN, on, direct)
        local d, picked = SData[pN], 0
        for iN in pairs(d.items) do
            setItem(pN, iN, on)
            if on and d.items[iN] then picked = picked + 1 end
        end
        if on and direct and picked == 0 then
            for iN in pairs(d.items) do
                if failed[iN] or done[iN] then
                    markStatus(iN, nil)
                    setItem(pN, iN, true)
                    picked = picked + 1
                end
            end
            if picked > 0 then blockedNote("Cleared the failed/done marks in " .. pN .. " and selected those cards again") end
        end
        paintPack(pN)
    end

    for lIdx, pD in ipairs(sData) do
        local pN = pD.Name
        local pC, eBtn, cBtn, iF = DS.pack(pScr, lIdx, pN)
        SData[pN] = { items = {}, btns = {}, isSelected = false, cBtn = cBtn, iF = iF, maxed = false }
        for _, iN in ipairs(pcData[pN] or {}) do
            SData[pN].items[iN] = false
            local ib = DS.item(iF, rowText(iN, false), 11)
            ib.TextColor3 = C3(150, 150, 150)
            SData[pN].btns[iN] = ib
            ib.MouseButton1Click:Connect(function()
                local want = not SData[pN].items[iN]
                if want and (failed[iN] or done[iN]) then markStatus(iN, nil) end -- picking a card yourself overrides its mark
                setItem(pN, iN, want) paintPack(pN)
                if want and not SData[pN].items[iN] then blockedNote(iN .. " is already at max stars") end
                if SaveState then SaveState() end
            end)
        end
        eBtn.MouseButton1Click:Connect(function()
            iF.Visible = not iF.Visible eBtn.Text = iF.Visible and "-" or "+"
            if iF.Visible then refreshPack(pN) end
        end)
        cBtn.MouseButton1Click:Connect(function() setPack(pN, not SData[pN].isSelected, true) if SaveState then SaveState() end end)
    end
    saBtn.MouseButton1Click:Connect(function() for pN in pairs(SData) do setPack(pN, true) end if SaveState then SaveState() end end)
    daBtn.MouseButton1Click:Connect(function() for pN in pairs(SData) do setPack(pN, false) end if SaveState then SaveState() end end)

    -- scan: grays out cards at max stars and packs where every card is at max stars
    local function scanAll()
        local needPacks, maxedPacks, needCards = 0, 0, 0
        for _, pD in ipairs(sData) do
            local pN = pD.Name
            local d = SData[pN]
            local total, maxed = 0, 0
            for _, iN in ipairs(pcData[pN] or {}) do
                total = total + 1
                local i = infoOf(iN)
                local m = i ~= nil and i.star >= MAX_STAR
                if m then maxed = maxed + 1 elseif i then needCards = needCards + 1 end
                local want = m and 0.6 or 0
                if d.btns[iN].TextTransparency ~= want then d.btns[iN].TextTransparency = want end
            end
            d.maxed = total > 0 and maxed == total
            local want = d.maxed and 0.6 or 0
            if d.cBtn.TextTransparency ~= want then d.cBtn.TextTransparency = want end
            if d.maxed then maxedPacks = maxedPacks + 1 elseif total > 0 then needPacks = needPacks + 1 end
            refreshPack(pN)
        end
        return needPacks, maxedPacks, needCards
    end

    -- controls
    local sLbl = DS.status(rPnl, "Status: Idle", 1)
    local nowLbl = DS.status(rPnl, "Current card: - (not running)", 2)
    local shardLbl = DS.status(rPnl, "Shards: not scanned yet", 3)
    local shardBtn = DS.btn(rPnl, "Scan Shards", "info", 4, 30)
    local stBtn = DS.btn(rPnl, "Start Star Trials", "ok", 5, 34)
    local exitBtn = DS.btn(rPnl, "Exit Trial", "danger", 6, 34)
    local scanBtn = DS.btn(rPnl, "Scan Packs", "info", 7, 28)
    local selBtn = DS.btn(rPnl, "Select Unmaxed", "accent", 8, 28)
    local upBtn = DS.btn(rPnl, "Send Upgrade", "info", 9, 28)
    local clearBtn = DS.btn(rPnl, "Clear Marks", nil, 10, 28)
    local scanLbl = DS.status(rPnl, "Scan: not run yet (maxed cards and packs are grayed out)", 11)
    blockedNote = function(t) scanLbl.Text = t end
    local diffOpts = { "Auto (next star)" }
    for _, d in ipairs(TRIAL_DIFFICULTIES) do diffOpts[#diffOpts + 1] = d end
    local diffInp = DS.dropdown(rPnl, "Difficulty", diffOpts, diffOpts[1], 12)
    local concInp = DS.dropdown(rPnl, "Concurrent trials", { "1", "2", "3", "4", "5" }, "1", 13)
    local everyInp = DS.fullInp(rPnl, "Re-send Start after (s)", "20", 14, 30)
    local skipInp = DS.dropdown(rPnl, "Skip cards at ★ or higher", { "Off", "1", "2", "3", "4", "5" }, "5", 15)
    local giveInp = DS.dropdown(rPnl, "Mark failed after (trials)", { "1", "2", "3", "5", "10", "Unlimited" }, "1", 16)
    local stuckInp = DS.dropdown(rPnl, "Auto-exit stuck trial after (s)", { "Off", "30", "60", "120", "300" }, "60", 17)
    local chalInp = DS.dropdown(rPnl, "Start each fight by", { "Remote call (no movement)", "Hop to enemy, then back" }, "Remote call (no movement)", 18)
    local farmInp = DS.fullInp(rPnl, "Shard farm card name", "Luffy", 19, 30)
    local tpBtn = DS.switch(rPnl, "[X] Block teleport", 21)
    local uiBtn = DS.switch(rPnl, "[X] Hide trial screen", 22)
    local visBtn = DS.switch(rPnl, "[X] No trial visuals", 23)
    local closeBtn = DS.switch(rPnl, "[X] Keep my windows open", 24)
    local farmBtn = DS.switch(rPnl, "[ ] Shard farm (Nightmare)", 25)

    -- ===== compact layout: pairs side by side (stacked on a narrow screen), small buttons, 2-column switches =====
    local function ctlBox(c)
        if c.Parent == rPnl then return c end
        if c.Parent.Parent == rPnl then return c.Parent end
        return c.Parent.Parent
    end
    local function wide(f)
        local w = f.AbsoluteSize.X / math.max((uiScale and uiScale.Scale) or 1, 0.1)
        return w == 0 or w >= 440
    end
    local function slimLabel(box) local l = box:FindFirstChildOfClass("TextLabel") if l then l.TextSize, l.Size = 11, U2(1, 0, 0, 14) end end
    local function newRow(order)
        return DS.new("Frame", rPnl, { Size = U2(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order })
    end
    local function pairRow(order, a, b)
        local row = newRow(order)
        local lay = Instance.new("UIListLayout")
        lay.FillDirection, lay.SortOrder, lay.Padding = Enum.FillDirection.Horizontal, Enum.SortOrder.LayoutOrder, UDim.new(0, 8)
        lay.Parent = row
        local boxes = { ctlBox(a), ctlBox(b) }
        for i, bx in ipairs(boxes) do bx.Parent, bx.LayoutOrder = row, i slimLabel(bx) end
        local function adapt()
            local w = wide(row)
            lay.FillDirection = w and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
            for _, bx in ipairs(boxes) do bx.Size = w and U2(0.5, -4, 0, 0) or U2(1, 0, 0, 0) end
        end
        row:GetPropertyChangedSignal("AbsoluteSize"):Connect(adapt)
        adapt()
    end
    local function gridRow(order, cols, cellH, ...)
        local row = newRow(order)
        local g = Instance.new("UIGridLayout")
        g.SortOrder, g.CellPadding = Enum.SortOrder.LayoutOrder, U2(0, 6, 0, 6)
        g.Parent = row
        for i, c in ipairs({ ... }) do
            local bx = ctlBox(c)
            bx.Parent, bx.LayoutOrder = row, i
            if bx:IsA("TextButton") then bx.TextSize = 11 end
        end
        local function adapt()
            local n = wide(row) and cols or math.max(1, math.floor(cols / 2))
            g.CellSize = U2(1 / n, -math.ceil(6 * (n - 1) / n), 0, cellH)
        end
        row:GetPropertyChangedSignal("AbsoluteSize"):Connect(adapt)
        adapt()
    end
    for _, d in ipairs({ diffInp, concInp, skipInp, giveInp, stuckInp, chalInp }) do d.Parent.Size = U2(1, 0, 0, 30) end
    everyInp.Size, farmInp.Size = U2(1, 0, 0, 30), U2(1, 0, 0, 30)
    -- shards line + its button
    do
        local row = newRow(3)
        local lay = Instance.new("UIListLayout")
        lay.FillDirection, lay.SortOrder, lay.Padding, lay.VerticalAlignment = Enum.FillDirection.Horizontal, Enum.SortOrder.LayoutOrder, UDim.new(0, 6), Enum.VerticalAlignment.Top
        lay.Parent = row
        shardLbl.Parent, shardLbl.LayoutOrder, shardLbl.Size = row, 1, U2(1, -86, 0, 30)
        shardBtn.Parent, shardBtn.LayoutOrder, shardBtn.Size, shardBtn.TextSize = row, 2, U2(0, 80, 0, 30), 11
    end
    -- Start / Exit
    do
        local row = DS.new("Frame", rPnl, { Size = U2(1, 0, 0, 34), LayoutOrder = 4 })
        local lay = Instance.new("UIListLayout")
        lay.FillDirection, lay.SortOrder, lay.Padding = Enum.FillDirection.Horizontal, Enum.SortOrder.LayoutOrder, UDim.new(0, 6)
        lay.Parent = row
        stBtn.Parent, stBtn.LayoutOrder, stBtn.Size = row, 1, U2(0.68, -3, 1, 0)
        exitBtn.Parent, exitBtn.LayoutOrder, exitBtn.Size = row, 2, U2(0.32, -3, 1, 0)
    end
    gridRow(5, 4, 28, scanBtn, selBtn, upBtn, clearBtn)
    pairRow(12, diffInp, concInp)
    pairRow(13, everyInp, skipInp)
    pairRow(14, giveInp, stuckInp)
    -- chalInp gets the row to itself next to nothing: keep it half width
    do
        local row = newRow(15)
        local lay = Instance.new("UIListLayout")
        lay.FillDirection, lay.SortOrder, lay.Padding = Enum.FillDirection.Horizontal, Enum.SortOrder.LayoutOrder, UDim.new(0, 8)
        lay.Parent = row
        local cb = ctlBox(chalInp)
        cb.Parent, cb.LayoutOrder = row, 1 slimLabel(cb)
        local function adapt() local w = wide(row) cb.Size = w and U2(0.5, -4, 0, 0) or U2(1, 0, 0, 0) lay.FillDirection = w and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical end
        row:GetPropertyChangedSignal("AbsoluteSize"):Connect(adapt) adapt()
    end
    gridRow(16, 2, 30, tpBtn, uiBtn, visBtn, closeBtn)
    -- shard farm: its switch and the card name box together, name defaults to Luffy
    do
        local row = newRow(17)
        local lay = Instance.new("UIListLayout")
        lay.FillDirection, lay.SortOrder, lay.Padding, lay.VerticalAlignment = Enum.FillDirection.Horizontal, Enum.SortOrder.LayoutOrder, UDim.new(0, 8), Enum.VerticalAlignment.Bottom
        lay.Parent = row
        local fb, sb = ctlBox(farmInp), ctlBox(farmBtn)
        fb.Parent, fb.LayoutOrder = row, 1 slimLabel(fb)
        sb.Parent, sb.LayoutOrder = row, 2
        local function adapt()
            local w = wide(row)
            lay.FillDirection = w and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
            fb.Size = w and U2(0.5, -4, 0, 0) or U2(1, 0, 0, 0)
            sb.Size = w and U2(0.5, -4, 0, 30) or U2(1, 0, 0, 30)
        end
        row:GetPropertyChangedSignal("AbsoluteSize"):Connect(adapt) adapt()
    end
    everyInp.FocusLost:Connect(function() if SaveConfig then SaveConfig() end end)

    local function scanText(np, mp, nc)
        local nf, nd = 0, 0
        for _ in pairs(failed) do nf = nf + 1 end
        for _ in pairs(done) do nd = nd + 1 end
        return string.format("Scan: %d packs still need stars, %d packs fully ★%d (grayed out), %d owned cards below ★%d | marked: %d failed, %d done", np, mp, MAX_STAR, nc, MAX_STAR, nf, nd)
    end
    scanBtn.MouseButton1Click:Connect(function()
        local np, mp, nc = scanAll()
        scanLbl.Text = scanText(np, mp, nc)
    end)
    selBtn.MouseButton1Click:Connect(function()
        local np, mp, nc = scanAll()
        local picked = 0
        for _, pD in ipairs(sData) do
            local pN = pD.Name
            for _, iN in ipairs(pcData[pN] or {}) do
                local i = infoOf(iN)
                local on = i ~= nil and i.star < MAX_STAR and not failed[iN] and not done[iN]
                setItem(pN, iN, on)
                if on then picked = picked + 1 end
            end
            paintPack(pN)
        end
        scanLbl.Text = scanText(np, mp, nc) .. " | selected " .. picked
        if SaveState then SaveState() end
    end)

    local trialRem = getRemote("StarTrial")
    local running, runId = false, 0
    local noTp, hideUI, latency, gotFirst = true, true, nil, {}
    local noVis, noClose = true, true
    local lastTrialEvt, lastEvtAt, unanswered = -1e9, os.clock(), 0
    local forceExit
    local trialOn, battle, curCard, chalAt, chalN = false, false, nil, 0, 0
    -- ===== shards (star currency) and shard farm =====
    local farm, farmRuns, farmGain, farmBase, farmNextAt = false, 0, 0, nil, 0
    local function fmtN(n)
        local str, r = tostring(math.floor(tonumber(n) or 0))
        repeat str, r = str:gsub("^(-?%d+)(%d%d%d)", "%1,%2") until r == 0
        return str
    end
    -- every star currency in the inventory (Shards, tickets, ...) plus anything named *shard* in other collections
    local function readCurrencies()
        local have = {}
        local cur = getLiveData("StarCurrency")
        if type(cur) == "table" then for k, v in pairs(cur) do if type(v) == "number" then have[k] = v end end end
        if StarCfg and type(StarCfg.CurrencyList) == "table" then
            for _, k in ipairs(StarCfg.CurrencyList) do
                if have[k] == nil then local v = tonumber(getLiveData("StarCurrency", k)) if v then have[k] = v end end
            end
        end
        if have.Shards == nil then local v = tonumber(getLiveData("StarCurrency", "Shards")) if v then have.Shards = v end end
        for _, col in ipairs({ "Consumables", "Currency", "Items" }) do
            local t = getLiveData(col)
            if type(t) == "table" then
                for k, v in pairs(t) do
                    if type(k) == "string" and type(v) == "number" and have[k] == nil and string.find(string.lower(k), "shard", 1, true) then have[k] = v end
                end
            end
        end
        return have
    end
    local function updateShards()
        local have = readCurrencies()
        local keys = {}
        for k in pairs(have) do if k ~= "Shards" then keys[#keys + 1] = k end end
        table.sort(keys)
        local parts = { "Shards: " .. (have.Shards and fmtN(have.Shards) or "none found") }
        for _, k in ipairs(keys) do parts[#parts + 1] = k .. ": " .. fmtN(have[k]) end
        local txt = table.concat(parts, " | ")
        if farmBase and have.Shards and (farm or farmRuns > 0) then
            txt = txt .. string.format("\nShard farm: %d runs | %s%s shards this farm (%s from trial rewards)",
                farmRuns, have.Shards - farmBase >= 0 and "+" or "", fmtN(have.Shards - farmBase), fmtN(farmGain))
        end
        if shardLbl.Text ~= txt then shardLbl.Text = txt end
        return have
    end
    local function resolveFarmCard()
        local want = string.lower((farmInp.Text or ""):gsub("^%s+", ""):gsub("%s+$", ""))
        if want == "" then return nil end
        for _, pD in ipairs(sData) do
            for _, iN in ipairs(pcData[pD.Name] or {}) do
                if string.lower(iN) == want and infoOf(iN) then return iN end
            end
        end
        return nil
    end
    local curDiff
    local function cardLine(c)
        local i = infoOf(c)
        local t = c
        if i then
            t = t .. " | grade " .. (i.grade ~= "" and i.grade or "?") .. " | ★" .. i.star
            if i.mut ~= "Regular" then t = t .. " | " .. i.mut end
            if i.trait ~= "" then t = t .. " | " .. i.trait end
        end
        return t
    end
    -- the "Current card" line: card, grade, stars, trial difficulty and what its next star still needs
    local function updateNow(live)
        local names = live
        if (not names or #names == 0) and trialOn and curCard then names = { curCard } end
        if not names or #names == 0 then
            nowLbl.Text = running and "Current card: waiting for the next trial..." or "Current card: - (not running)"
            return
        end
        local parts = {}
        for _, c in ipairs(names) do
            local p = cardLine(c)
            local r = nextReq(c)
            if r then
                if r.ready then p = p .. " | next star: ready"
                elseif r.diff then p = p .. " | next star needs " .. r.diff
                elseif r.short then p = p .. " | next star needs " .. tostring(r.short) end
            end
            parts[#parts + 1] = p
        end
        nowLbl.Text = "Current card: " .. table.concat(parts, "   +   ") .. (curDiff and (" | trial: " .. tostring(curDiff)) or "")
    end
    -- re-read every card (stars, grade, mutation, trait, maxed state) in every pack, not just the open ones
    local function refreshAll()
        local np, mp, nc = scanAll()
        for _, pD in ipairs(sData) do
            local pN = pD.Name
            local d = SData[pN]
            if d then
                for iN, on in pairs(d.items) do
                    if on then
                        local i = infoOf(iN)
                        if i and i.star >= MAX_STAR then setItem(pN, iN, false) end
                    end
                end
                paintPack(pN)
            end
        end
        scanLbl.Text = scanText(np, mp, nc)
        updateNow()
        pcall(updateShards)
    end
    -- event log, written to ACC_StarTrial_Log.txt while running so a bad run can be inspected
    local slog, t0log = {}, os.clock()
    local function L(msg)
        slog[#slog + 1] = string.format("[%8.2f] %s", os.clock() - t0log, msg)
        if #slog > 400 then table.remove(slog, 1) end
    end
    local function short(v)
        if type(v) == "table" then local ok, j = pcall(function() return HS:JSONEncode(v) end) v = ok and j or "{...}" end
        v = tostring(v)
        return #v > 90 and (string.sub(v, 1, 90) .. "...") or v
    end
    local function saveLog()
        if writefile then pcall(writefile, "ACC_StarTrial_Log.txt", table.concat(slog, "\n")) end
    end
    local activeAt, startedAt, sent, fights, stages, fightT, times = {}, {}, 0, 0, 0, nil, {}
    local wasActive, tries, upgrades, lastOther, verifying, evoAt = {}, {}, 0, nil, {}, {}
    local lostTrial = {}
    local KNOWN = { StartTrial = true, StartFight = true, Attack = true, EnemyDefeated = true, StageCleared = true, Results = true, EvolutionSuccess = true }
    local ACTIVE_FOR = 8

    local function sendUpgrade(card)
        L("OUT Star " .. tostring(card))
        if trialRem then pcall(function() trialRem:FireServer("Star", card) end) end
    end
    local function maxTries() return tonumber(giveInp.Text) or 0 end

    -- sends the upgrade and waits for either EvolutionSuccess or a higher star count
    local function attemptUpgrade(card)
        local i0 = infoOf(card)
        local before = i0 and i0.star or 0
        evoAt[card] = nil
        sendUpgrade(card)
        local t0 = os.clock()
        while os.clock() - t0 < 3 do
            local i = infoOf(card)
            if evoAt[card] or (i and i.star > before) then return true end
            task.wait(0.25)
        end
        return false
    end
    -- upgrades one star at a time while the game's requirements allow it; returns how many stars it gained
    local function upgradeChain(card)
        local ok, gained = attemptUpgrade(card), 0
        while ok do
            gained = gained + 1
            local i1 = infoOf(card)
            if i1 and i1.star >= MAX_STAR then break end
            task.wait(0.3)
            local r2 = nextReq(card)
            if not r2 or not r2.ready then break end
            ok = attemptUpgrade(card)
        end
        return gained
    end
    -- a card is complete when it is maxed or reached the "skip at" star; otherwise it stays in the queue
    local function settle(card, gained)
        tries[card] = 0
        local i2 = infoOf(card)
        local skipAt = tonumber(skipInp.Text) or 0
        if i2 and (i2.star >= MAX_STAR or (skipAt > 0 and i2.star >= skipAt)) then markStatus(card, "done") end
        L("upgraded " .. card .. " x" .. gained .. " -> star " .. tostring(i2 and i2.star))
    end
    -- upgrade attempts for cards that already have what the game asks for (start of a run / manual button)
    local function cashIn(list)
        local n = 0
        for _, c in ipairs(list) do
            local r = nextReq(c)
            if not r or r.ready then
                local g = upgradeChain(c)
                if g > 0 then settle(c, g) n = n + 1 end
            end
        end
        if n > 0 and SaveState then SaveState() end
        return n
    end
    -- a trial just finished: upgrade as far as the game allows; only a real failed attempt counts against the card
    local function verifyAfterTrial(card)
        verifying[card] = true
        task.wait(1) -- let the new completion count replicate
        if lostTrial[card] then
            -- the card was defeated in the trial: that is a real failure (one is enough when "Mark failed after" is 1)
            lostTrial[card] = nil
            tries[card] = (tries[card] or 0) + 1
            local limit = maxTries()
            L("LOST trial " .. card .. " (failure " .. tries[card] .. (limit > 0 and ("/" .. limit) or "") .. ")")
            if limit > 0 and tries[card] >= limit then markStatus(card, "failed") end
            verifying[card] = nil
            if SaveState then SaveState() end
            pcall(refreshAll)
            return
        end
        local r = nextReq(card)
        if r and not r.ready then
            L("not ready " .. card .. ": " .. (r.diff and ("needs " .. r.diff .. " completions") or ("needs " .. tostring(r.short))))
            verifying[card] = nil
            return
        end
        local gained = upgradeChain(card)
        verifying[card] = nil
        if gained > 0 then
            settle(card, gained)
        else
            tries[card] = (tries[card] or 0) + 1
            local limit = maxTries()
            if limit > 0 and tries[card] >= limit then markStatus(card, "failed") end
        end
        if SaveState then SaveState() end
        pcall(refreshAll)
    end

    if trialRem then
        trialRem.OnClientEvent:Connect(function(action, a, b, c)
            local t = os.clock()
            lastEvtAt = t
            L("IN  " .. tostring(action) .. " " .. short(a) .. " " .. short(b) .. (c ~= nil and (" " .. short(c)) or ""))
            if action == "StartTrial" or action == "Results" then lastTrialEvt = t end
            if action == "StartTrial" then
                trialOn, battle, chalAt = true, false, 0
                unanswered = 0
                if type(b) == "string" then curDiff = b end
                updateNow()
            elseif action == "Results" then
                -- the trial is over: the card that was fighting counts as finished right now (no 8s wait)
                trialOn, battle = false, false
                if curCard then activeAt[curCard] = t - ACTIVE_FOR - 1 wasActive[curCard] = true end
                if farm then
                    farmRuns = farmRuns + 1
                    if type(a) == "table" then farmGain = farmGain + (tonumber(a.Shards) or 0) end
                    farmNextAt = t + 1.5
                    local fc = resolveFarmCard()
                    if fc then startedAt[fc] = nil end
                end
                -- refresh every card once the new completion has replicated, and again a little later
                task.delay(1.5, function() pcall(refreshAll) end)
                task.delay(5, function() pcall(refreshAll) end)
                if (hideUI or noTp) and not noVis then
                    task.delay(0.4, function()
                        local okH, H = pcall(function() return require(RS.Client.UI.StarTrialHandler) end)
                        if okH and type(H) == "table" and H.ContinueClicked then pcall(H.ContinueClicked) end
                    end)
                end
            elseif action == "StartFight" then
                battle = true
                local mine = type(a) == "table" and a.Card
                if mine then
                    curCard = mine
                    activeAt[mine] = t
                    if startedAt[mine] and gotFirst[mine] ~= startedAt[mine] then
                        gotFirst[mine] = startedAt[mine]
                        latency = t - startedAt[mine]
                    end
                end
                fightT = t
                pcall(updateNow)
            elseif action == "Attack" then
                -- Attack(slot, yourHealthLeft, enemyHealthLeft): your card at 0 or below while the enemy still stands = the trial is lost
                local php, ehp = tonumber(b), tonumber(c)
                if not farm and curCard and php and ehp and php <= 0 and ehp > 0 and not lostTrial[curCard] then
                    lostTrial[curCard] = true
                    L("DEFEATED " .. tostring(curCard) .. " (health " .. tostring(b) .. " vs enemy " .. tostring(c) .. ")")
                end
            elseif action == "EnemyDefeated" then
                battle = false
                if fightT then
                    times[#times + 1] = t - fightT
                    if #times > 15 then table.remove(times, 1) end
                    fights = fights + 1
                    fightT = nil
                end
            elseif action == "StageCleared" then
                stages = stages + 1
                battle = false
            elseif action == "EvolutionSuccess" then
                upgrades = upgrades + 1
                if type(a) == "string" then
                    tries[a] = 0
                    evoAt[a] = t
                end
                task.delay(0.5, function() pcall(refreshAll) end)
            end
            if not KNOWN[action] then lastOther = tostring(action) end
        end)
    end

    local function queue()
        local out, seen = {}, {}
        local skip = tonumber(skipInp.Text) or 0
        for _, pD in ipairs(sData) do
            local d = SData[pD.Name]
            for _, iN in ipairs(pcData[pD.Name] or {}) do
                if d.items[iN] and not seen[iN] then
                    seen[iN] = true
                    local i = infoOf(iN)
                    local limit = maxTries()
                    local stuck = limit > 0 and (tries[iN] or 0) >= limit
                    local blocked = false
                    if string.sub(diffInp.Text, 1, 4) ~= "Auto" then
                        local r = nextReq(iN)
                        blocked = r ~= nil and r.diff ~= nil and diffRank(r.diff) > diffRank(diffInp.Text)
                    end
                    if i and not stuck and not blocked and not failed[iN] and not done[iN] and not (skip > 0 and i.star >= skip) then out[#out + 1] = iN end
                end
            end
        end
        return out
    end

    local function pickDifficulty(card)
        if farm then return "Nightmare" end
        if string.sub(diffInp.Text, 1, 4) ~= "Auto" then return diffInp.Text end
        local r = nextReq(card)
        return (r and (r.diff or r.top)) or "Hard"
    end
    local function startTrial(card)
        if unanswered >= 3 and forceExit then
            forceExit("no answer to " .. unanswered .. " Start requests")
            farmNextAt = os.clock() + 2
        end
        unanswered = unanswered + 1
        startedAt[card] = os.clock()
        sent = sent + 1
        local diff = pickDifficulty(card)
        L("OUT AutoQueue true / Start " .. diff .. " " .. tostring(card) .. "")
        pcall(function() trialRem:FireServer("AutoQueue", true, {}) end)
        pcall(function() trialRem:FireServer("Start", diff, card) end)
        pcall(function() trialRem:FireServer("AFK", false) end)
    end

    -- The game's own StarTrialHandler module does the teleport (TeleportToStartTrial / EndTrial -> lobby pivot).
    -- It calls both through the module table, so swapping the table fields is enough, no function hooks.
    local CS = game:GetService("CollectionService")
    local handler, origFns = nil, nil
    local function getHandler()
        if handler then return handler end
        local ok, m = pcall(function() return RS.Client.UI.StarTrialHandler end)
        if ok and m then
            local ok2, t = pcall(require, m)
            if ok2 and type(t) == "table" then handler = t end
        end
        return handler
    end
    local function applyNoTp(on)
        local H = getHandler()
        if not H then L("no-teleport: StarTrialHandler module not reachable") return false end
        if on and not origFns then
            origFns = { tp = H.TeleportToStartTrial, fin = H.EndTrial }
            H.TeleportToStartTrial = function() end
            H.EndTrial = function()
                H.InTrial = false
                H.StartTime = nil
                pcall(H.ShowPlayers)
            end
            L("no-teleport: game teleport and lobby return are now disabled")
        elseif not on and origFns then
            H.TeleportToStartTrial = origFns.tp
            H.EndTrial = origFns.fin
            origFns = nil
            L("no-teleport: game teleport restored")
        end
        return true
    end
    -- Disable every visual of the trial. The game's remote handler looks each event up in the StarTrialHandler table when it fires,
    -- so swapping these fields stops the trial frame, the dark overlay, ButtonHandler.OnClick/TurnOffFrame (which closes your other
    -- windows on every start / fight / continue), the tweens and the sounds. The server still gets the one thing the game's Attack
    -- code sends: AttackDone, after the same delay the animation would have taken.
    local origVis
    local function applyNoVis(on)
        local H = getHandler()
        if not H then L("no-visuals: StarTrialHandler module not reachable") return false end
        if on and not origVis then
            origVis = { StartTrial = H.StartTrial, StartFight = H.StartFight, Attack = H.Attack, EnemyDefeated = H.EnemyDefeated, Results = H.Results, ToggleFrames = H.ToggleFrames, ShowFrame = H.ShowFrame, HidePlayers = H.HidePlayers }
            H.StartTrial = function() end
            H.StartFight = function() end
            H.EnemyDefeated = function() end
            H.Results = function() end
            H.ToggleFrames = function() end
            H.ShowFrame = function() end
            H.HidePlayers = function() end
            H.Attack = function(slot)
                local bs = tonumber(getLiveData("StarUpgrades", "BattleSpeed")) or 0
                local buff = StarCfg and StarCfg.Upgrades and StarCfg.Upgrades.BattleSpeed and tonumber(StarCfg.Upgrades.BattleSpeed.Buff) or 0
                local wait = 0.9 / (1 + bs * buff)
                task.delay(wait, function() pcall(function() trialRem:FireServer("AttackDone", slot) end) end)
            end
            L("no-visuals: trial UI, overlay, tweens and sounds are now disabled")
        elseif not on and origVis then
            for k, v in pairs(origVis) do H[k] = v end
            origVis = nil
            L("no-visuals: game visuals restored")
        end
        return true
    end
    -- The game closes your open windows through ButtonHandler.OnClick(nil, "StarTrial") / TurnOffFrame() and flashes the screen
    -- through GUIDirectoryHandler.QuickTransition. Those are shared with every other window, so they are only skipped when the call
    -- comes from the star trial code (getcallingscript), or, without that function, within 1.5s of a trial start / end.
    local gameMods, origClose = {}, nil
    local function findMod(name)
        if gameMods[name] ~= nil then return gameMods[name] or nil end
        local found
        pcall(function()
            for _, d in ipairs(RS.Client:GetDescendants()) do
                if d.Name == name and d:IsA("ModuleScript") then
                    local ok, t = pcall(require, d)
                    if ok and type(t) == "table" then found = t break end
                end
            end
        end)
        gameMods[name] = found or false
        return found
    end
    local function fromTrial()
        if not running then return false end
        if type(getcallingscript) == "function" then
            local ok, cs = pcall(getcallingscript)
            if ok and cs and cs.Name == "StarTrialHandler" then return true end
            if ok and cs then return false end
        end
        return os.clock() - lastTrialEvt < 1.5
    end
    local function applyNoClose(on)
        if on and not origClose then
            origClose = {}
            local BH, GD = findMod("ButtonHandler"), findMod("GUIDirectoryHandler")
            if BH and type(BH.OnClick) == "function" then
                local o = BH.OnClick origClose[#origClose + 1] = { BH, "OnClick", o }
                BH.OnClick = function(...) if select(2, ...) == "StarTrial" and running then return end return o(...) end
            end
            if BH and type(BH.TurnOffFrame) == "function" then
                local o = BH.TurnOffFrame origClose[#origClose + 1] = { BH, "TurnOffFrame", o }
                BH.TurnOffFrame = function(...) if fromTrial() then return end return o(...) end
            end
            if GD and type(GD.QuickTransition) == "function" then
                local o = GD.QuickTransition origClose[#origClose + 1] = { GD, "QuickTransition", o }
                GD.QuickTransition = function(...) if fromTrial() then return end return o(...) end
            end
            L("no-close: " .. #origClose .. " window-closing calls are now guarded")
        elseif not on and origClose then
            for _, e in ipairs(origClose) do e[1][e[2]] = e[3] end
            origClose = nil
            L("no-close: window-closing calls restored")
        end
    end
    -- the game's own Exit button: AFK off, auto queue off, "Exit" to the server, then clear every local trial flag
    forceExit = function(why)
        L("OUT Exit (" .. tostring(why) .. ")")
        local H = getHandler()
        if H then H.AFK = false end
        pcall(function() trialRem:FireServer("AutoQueue", false, {}) end)
        pcall(function() trialRem:FireServer("AFK", false) end)
        pcall(function() trialRem:FireServer("Exit") end)
        pcall(function() local TT = require(RS.Client.Core.TrackTargets) if TT and TT.Exit then TT.Exit() end end)
        trialOn, battle, unanswered = false, false, 0
        for k in pairs(activeAt) do activeAt[k] = nil end
        for k in pairs(startedAt) do startedAt[k] = nil end
        for k in pairs(wasActive) do wasActive[k] = nil end
        if H then
            H.InTrial, H.InBattle, H.StartTime = false, false, nil
            pcall(H.ShowPlayers)
            if not origVis then pcall(H.ContinueClicked) end -- hides a leftover trial / results frame
        end
        lastEvtAt = os.clock()
        pcall(updateNow)
        saveLog()
    end
    local function stuckSecs() return tonumber(string.match(stuckInp.Text or "", "%d+")) or 0 end
    local function nextEnemy()
        local tag = tostring(LP.UserId) .. "-StarTrialEnemy"
        local bestId, bestInst
        for _, inst in ipairs(CS:GetTagged(tag)) do
            local idx, card = inst:GetAttribute("EnemyIndex"), inst:GetAttribute("Card")
            local id
            if idx ~= nil and typeof(card) == "string" then id = tostring(idx) else id = inst.Name:match("^([^%-]+)%-(.+)$") end
            if id and (not bestId or (tonumber(id) or 99) < (tonumber(bestId) or 99)) then bestId, bestInst = id, inst end
        end
        return bestId, bestInst
    end
    local function challenge()
        local id, inst = nextEnemy()
        if not id then return end
        chalAt, chalN = os.clock(), chalN + 1
        local hop = string.find(chalInp.Text, "Hop", 1, true) ~= nil
        local ch, back = LP.Character, nil
        if hop and inst and inst:IsA("BasePart") and ch then
            pcall(function() back = ch:GetPivot() ch:PivotTo(inst.CFrame * CFrame.new(0, 0, 4)) end)
            task.wait(0.15)
        end
        L("OUT Challenge " .. id .. (hop and " (hop)" or ""))
        pcall(function() trialRem:FireServer("Challenge", id) end)
        if back then
            local t1 = os.clock()
            while not battle and os.clock() - t1 < 2 do task.wait(0.05) end
            task.wait(0.2)
            pcall(function() ch:PivotTo(back) end)
        end
    end
    local function startDriver(run)
        task.spawn(function()
            local pgui = LP:FindFirstChild("PlayerGui")
            local ui0
            while running and run == runId and mFrame:IsDescendantOf(game) do
                local now = os.clock()
                if hideUI and pgui then
                    pcall(function()
                        local g = pgui:FindFirstChild("StarTrial")
                        if g then if ui0 == nil then ui0 = g.Enabled end g.Enabled = false end
                        local b = pgui:FindFirstChild("UIBlackout")
                        if b and b:FindFirstChild("Blackout") then b.Blackout.BackgroundTransparency = 1 end
                    end)
                end
                -- the game's own flags say "in star trial" / "in battle"; other scripts read them to refuse teleports.
                -- Nothing in the trial handler needs them without AFK mode, so keep them off while teleport blocking is on.
                if noTp and handler then
                    if handler.InTrial then handler.InTrial = false end
                    if handler.InBattle then handler.InBattle = false end
                end
                -- no AFK mode: nothing walks to the enemies, so send Challenge ourselves
                if trialOn and not battle and now - chalAt >= 1.2 then challenge() end
                task.wait()
            end
            if pgui and ui0 ~= nil then pcall(function() local g = pgui:FindFirstChild("StarTrial") if g then g.Enabled = ui0 end end) end
        end)
    end

    local function setRunning(on)
        if on and not trialRem then stBtn.Text = "ERR: StarTrial Remote Missing" return end
        local was = running
        running = on and true or false
        stBtn.Text = running and "Stop Star Trials" or (farm and "Start Shard Farm" or "Start Star Trials")
        if running and updateNow then pcall(updateNow) end
        stBtn.BackgroundColor3 = running and C3(200, 40, 40) or C3(40, 200, 120)
        if not running then
            sLbl.Text = "Status: Idle"
            if updateNow then pcall(updateNow) end
            applyNoTp(false)
            applyNoVis(false)
            applyNoClose(false)
            trialOn, battle = false, false
            if was and trialRem then
                L("OUT AutoQueue false (stopped)")
                pcall(function() trialRem:FireServer("AutoQueue", false, {}) end)
                saveLog()
            end
            return
        end
        runId = runId + 1
        local run = runId
        tries, wasActive = {}, {}
        local lastSaved = 0
        startedAt, activeAt, verifying = {}, {}, {}
        if farm then farmRuns, farmGain = 0, 0 local h = readCurrencies() farmBase = h.Shards end
        L("---- run started (difficulty " .. tostring(diffInp.Text) .. ", noTp " .. tostring(noTp) .. ", hideUI " .. tostring(hideUI) .. ", " .. tostring(chalInp.Text) .. ") ----")
        applyNoTp(noTp)
        applyNoVis(noVis)
        applyNoClose(noClose)
        startDriver(run)
        task.spawn(function()
            -- cash in any trial that was already won but not upgraded yet
            if not farm then cashIn(queue()) end
            while running and run == runId and mFrame:IsDescendantOf(game) do
                local now = os.clock()
                local list = queue()
                if farm then
                    local fc = resolveFarmCard()
                    list = fc and { fc } or {}
                end
                local want = math.clamp(math.floor(tonumber(concInp.Text) or 1), 1, 5)
                local every = math.max(tonumber(everyInp.Text) or 20, 1)
                local busy, idle, live = 0, {}, {}
                for i, c in ipairs(list) do
                    local isActive = activeAt[c] and now - activeAt[c] < ACTIVE_FOR
                    local isPending = startedAt[c] and now - startedAt[c] < every
                    if isActive then wasActive[c] = true
                    elseif wasActive[c] then
                        -- the trial just ended: try the star upgrade, count it as an attempt (an EvolutionSuccess resets the count)
                        wasActive[c] = false
                        if not farm then task.spawn(verifyAfterTrial, c) end
                    end
                    if isActive then busy = busy + 1 live[#live + 1] = c
                    elseif verifying[c] or isPending then busy = busy + 1
                    else idle[#idle + 1] = { c = c, t = startedAt[c] or -1e9, i = i } end
                end
                table.sort(idle, function(x, y) if x.t ~= y.t then return x.t < y.t end return x.i < y.i end)
                for _, e in ipairs(idle) do
                    if busy >= want or (farm and now < farmNextAt) then break end
                    startTrial(e.c)
                    busy = busy + 1
                end
                pcall(updateNow, live)
                local sa = stuckSecs()
                if sa > 0 and trialOn and os.clock() - lastEvtAt > sa then
                    forceExit("no trial events for " .. sa .. "s")
                    farmNextAt = os.clock() + 2
                end
                if now - (lastSaved or 0) >= 5 then lastSaved = now saveLog() end
                local avg = 0
                for _, v in ipairs(times) do avg = avg + v end
                avg = #times > 0 and avg / #times or 0
                local nDone, nFailed = 0, 0
                for _ in pairs(done) do nDone = nDone + 1 end
                for _ in pairs(failed) do nFailed = nFailed + 1 end
                if #list == 0 then
                    sLbl.Text = string.format("Running | no eligible owned cards selected | done %d | failed %d", nDone, nFailed)
                else
                    sLbl.Text = string.format("Running | queue %d | in trial: %s | fights %d | upgrades %d | done %d | failed %d | avg fight %.2fs",
                        #list, #live > 0 and table.concat(live, ", ") or "-", fights, upgrades, nDone, nFailed, avg)
                end
                if latency then sLbl.Text = sLbl.Text .. string.format(" | start to fight %.1fs", latency) end
                if lastOther then sLbl.Text = sLbl.Text .. " | other event: " .. lastOther end
                if farm then
                    if list[1] then
                        sLbl.Text = string.format("Shard farm | %s on Nightmare | runs %d | fights %d | avg fight %.2fs", list[1], farmRuns, fights, avg)
                    else
                        sLbl.Text = "Shard farm | card '" .. tostring(farmInp.Text) .. "' not found in your cards (check the spelling)"
                    end
                end
                task.wait(0.5)
            end
        end)
    end

    local function paintSwitch(b, on, text)
        b.Text = (on and "[X] " or "[ ] ") .. text
        b.BackgroundColor3 = on and C3(40, 200, 120) or C3(50, 50, 50)
    end
    local TP_TXT, UI_TXT = "Block teleport", "Hide trial screen"
    local FARM_TXT = "Shard farm (Nightmare)"
    local function setFarm(on)
        farm = on and true or false
        paintSwitch(farmBtn, farm, FARM_TXT)
        if not running then stBtn.Text = farm and "Start Shard Farm" or "Start Star Trials" end
        if farm then local h = readCurrencies() farmBase = h.Shards farmRuns, farmGain = 0, 0 end
        pcall(updateShards)
    end
    farmBtn.MouseButton1Click:Connect(function() setFarm(not farm) if SaveConfig then SaveConfig() end end)
    farmInp.FocusLost:Connect(function() if SaveConfig then SaveConfig() end end)
    shardBtn.MouseButton1Click:Connect(function() pcall(updateShards) end)
    tpBtn.MouseButton1Click:Connect(function()
        noTp = not noTp
        paintSwitch(tpBtn, noTp, TP_TXT)
        if running then applyNoTp(noTp) end
        if SaveConfig then SaveConfig() end
    end)
    local VIS_TXT = "No trial visuals"
    visBtn.MouseButton1Click:Connect(function()
        noVis = not noVis
        paintSwitch(visBtn, noVis, VIS_TXT)
        if running then applyNoVis(noVis) end
        if SaveConfig then SaveConfig() end
    end)
    local CLOSE_TXT = "Keep my windows open"
    closeBtn.MouseButton1Click:Connect(function()
        noClose = not noClose
        paintSwitch(closeBtn, noClose, CLOSE_TXT)
        if running then applyNoClose(noClose) end
        if SaveConfig then SaveConfig() end
    end)
    uiBtn.MouseButton1Click:Connect(function()
        hideUI = not hideUI
        paintSwitch(uiBtn, hideUI, UI_TXT)
        if SaveConfig then SaveConfig() end
    end)
    stBtn.MouseButton1Click:Connect(function() setRunning(not running) if SaveState then SaveState() end end)
    exitBtn.MouseButton1Click:Connect(function()
        if running then setRunning(false) end
        forceExit("Exit button")
        if SaveState then SaveState() end
    end)
    upBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            local list = queue()
            scanLbl.Text = "Sending star upgrade for " .. #list .. " selected cards..."
            local n = cashIn(list)
            scanLbl.Text = "Star upgrade sent for " .. #list .. " cards, " .. n .. " completed"
        end)
    end)
    clearBtn.MouseButton1Click:Connect(function()
        local names = {}
        for c in pairs(failed) do names[#names + 1] = c end
        for c in pairs(done) do names[#names + 1] = c end
        for _, c in ipairs(names) do markStatus(c, nil) tries[c] = nil end
        scanLbl.Text = "Cleared " .. #names .. " marks"
        if SaveState then SaveState() end
    end)
    setRunning(false)

    -- keep stars, gray-outs and expanded packs fresh
    task.spawn(function()
        while mFrame:IsDescendantOf(game) do
            task.wait(4)
            if pFrame.Visible then pcall(scanAll) pcall(updateShards) end
        end
    end)

    StarAPI.GetConfig = function()
        return { diff = diffInp.Text, conc = concInp.Text, wait = everyInp.Text, skip = skipInp.Text, fails = giveInp.Text, noTp = noTp, hideUI = hideUI, noVis = noVis, noClose = noClose, chal = chalInp.Text, stuck = stuckInp.Text, farm = farm, farmCard = farmInp.Text, failsV = 2 }
    end
    StarAPI.LoadConfig = function(c)
        if not c then return end
        if c.diff then diffInp.Text = tostring(c.diff) end
        if c.conc then concInp.Text = tostring(c.conc) end
        if c.wait then everyInp.Text = tostring(c.wait) end
        if c.skip then skipInp.Text = (tostring(c.skip) == "0") and "Off" or tostring(c.skip) end
        if c.fails and c.failsV then giveInp.Text = tostring(c.fails) else giveInp.Text = "1" end
        if c.noTp ~= nil then
            noTp = c.noTp
            tpBtn.Text = (noTp and "[X] " or "[ ] ") .. "Block teleport"
            tpBtn.BackgroundColor3 = noTp and C3(40, 200, 120) or C3(50, 50, 50)
        end
        if c.hideUI ~= nil then
            hideUI = c.hideUI
            uiBtn.Text = (hideUI and "[X] " or "[ ] ") .. "Hide trial screen"
            uiBtn.BackgroundColor3 = hideUI and C3(40, 200, 120) or C3(50, 50, 50)
        end
        if c.noVis ~= nil then
            noVis = c.noVis
            visBtn.Text = (noVis and "[X] " or "[ ] ") .. "No trial visuals"
            visBtn.BackgroundColor3 = noVis and C3(40, 200, 120) or C3(50, 50, 50)
        end
        if c.noClose ~= nil then
            noClose = c.noClose
            closeBtn.Text = (noClose and "[X] " or "[ ] ") .. "Keep my windows open"
            closeBtn.BackgroundColor3 = noClose and C3(40, 200, 120) or C3(50, 50, 50)
        end
        if c.chal then chalInp.Text = tostring(c.chal) end
        if c.stuck then stuckInp.Text = tostring(c.stuck) end
        if c.farmCard and c.farmCard ~= "" then farmInp.Text = tostring(c.farmCard) end
        if c.farm ~= nil then setFarm(c.farm) end
    end
    StarAPI.GetState = function()
        local names, seen = {}, {}
        for _, d in pairs(SData) do
            for iN, on in pairs(d.items) do if on and not seen[iN] then seen[iN] = true names[#names + 1] = iN end end
        end
        table.sort(names)
        local fl, dl = {}, {}
        for c in pairs(failed) do fl[#fl + 1] = c end
        for c in pairs(done) do dl[#dl + 1] = c end
        table.sort(fl) table.sort(dl)
        return { on = running, items = names, failed = fl, done = dl, v = 2 }
    end
    -- cards remembered as failed in an earlier session
    task.spawn(function()
        task.wait(1)
        for c in pairs(FailedStore.cards) do
            local known = false
            for _, d in pairs(SData) do if d.items[c] ~= nil then known = true break end end
            if known and not failed[c] and not done[c] then markStatus(c, "failed") end
        end
    end)
    StarAPI.LoadState = function(st)
        if not st then return end
        local want = {}
        for _, iN in ipairs(st.items or {}) do want[iN] = true end
        if st.v == 2 then for _, c in ipairs(st.failed or {}) do markStatus(c, "failed") end end
        for _, c in ipairs(st.done or {}) do markStatus(c, "done") end
        for pN, d in pairs(SData) do
            for iN in pairs(d.items) do setItem(pN, iN, want[iN] == true) end
            paintPack(pN)
        end
        if st.on ~= nil and st.on ~= running then setRunning(st.on) end
    end
end
bStarTrial(starFrame, CardSortedPacks, CardPackCards)

-- ==========================================
-- 8. AUTO PACK OPENER (SNAKE GRID + TWO-PASS SNIPE)
-- ==========================================
local OpenerAPI = {}
local function bOpener(pFrame, sData)
    local lPnl, rPnl = DS.split(pFrame, 230)
    local saBtn, daBtn, pScr, sLyt = DS.tree(lPnl)

    local SData = {}
    local BundleBtnMap = {}

    local function getPackVariants(pN)
        return {
            pN .. "-Regular-Bundle",
            pN .. "-Gold-Bundle",
            pN .. "-Emerald-Bundle",
            pN .. "-Void-Bundle",
            pN .. "-Diamond-Bundle",
            pN .. "-Rainbow-Bundle",
            pN,
            pN .. "-Gold",
            pN .. "-Emerald",
            pN .. "-Void",
            pN .. "-Diamond",
            pN .. "-Rainbow"
        }
    end

    local function getOwnedPackCount(itemName)
        local packs = getLiveData("Packs")
        if type(packs) == "table" then
            return tonumber(packs[itemName]) or 0
        end
        return 0
    end

    local function uncheckBundle(bName)
        for pN, pD in pairs(SData) do
            if pD.items[bName] ~= nil then
                pD.items[bName] = false
                local btn = BundleBtnMap[bName]
                if btn then
                    local cnt = getOwnedPackCount(bName)
                    btn.Text = "   ↳ [ ] " .. bName .. (cnt > 0 and (" (" .. cnt .. ")") or "")
                    btn.TextColor3 = C3(150, 150, 150)
                end
                
                local anyLeft = false
                for _, v in pairs(pD.items) do if v then anyLeft = true break end end
                pD.isSelected = anyLeft
                pD.cBtn.Text = (anyLeft and " [X] " or " [ ] ") .. pN
                pD.cBtn.TextColor3 = anyLeft and C3(40, 200, 120) or C3(200, 200, 200)
                if SaveState then SaveState() end
                break
            end
        end
    end

    -- mutation filter for the queue (set by the dropdown below)
    local MUT_OPTS = { "All mutations", "Regular", "Gold", "Emerald", "Void", "Diamond", "Rainbow" }
    local mutFilterInp
    local function mutOf(bN)
        local base = bN:gsub("%-Bundle$", "")
        for i = 6, 2, -1 do if base:sub(-(#MUT_OPTS[i + 1] + 1)) == "-" .. MUT_OPTS[i + 1] then return MUT_OPTS[i + 1] end end
        if bN:find("%-Regular%-Bundle$") then return "Regular" end
        return "Regular"
    end
    local function passes(bN)
        local f = mutFilterInp and mutFilterInp.Text or MUT_OPTS[1]
        return f == MUT_OPTS[1] or mutOf(bN) == f
    end

    for lIdx, pD in ipairs(sData) do
        local pN = pD.Name 
        SData[pN] = { isSelected = false, items = {} }
        local variants = getPackVariants(pN)
        
        local pC, eBtn, cBtn, iF = DS.pack(pScr, lIdx, pN)
        SData[pN].cBtn = cBtn
        
        local iBtns = {} 
        for _, bN in ipairs(variants) do
            SData[pN].items[bN] = false
            local ib = DS.item(iF, "   ↳ [ ] "..bN, 10)
            BundleBtnMap[bN] = ib
            ib.MouseButton1Click:Connect(function()
                local s = not SData[pN].items[bN] 
                SData[pN].items[bN] = s
                local cnt = getOwnedPackCount(bN)
                ib.Text = "   ↳ "..(s and "[X] " or "[ ] ")..bN .. (cnt > 0 and (" (" .. cnt .. ")") or "")
                ib.TextColor3 = s and C3(40,200,120) or C3(150, 150, 150)
                if SaveState then SaveState() end
            end)
            table.insert(iBtns, {btn=ib, name=bN, update = function(s) 
                s = s and passes(bN)
                SData[pN].items[bN] = s 
                local cnt = getOwnedPackCount(bN)
                ib.Text = "   ↳ "..(s and "[X] " or "[ ] ")..bN .. (cnt > 0 and (" (" .. cnt .. ")") or "")
                ib.TextColor3 = s and C3(40,200,120) or C3(150, 150, 150) 
            end})
            table.insert(AllOpenerButtons, {btn=ib, name=bN, packName=pN, selData=SData})
        end
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

    
    local bundlesOnly = true
    local bOnlyBtn = DS.switch(rPnl, "[X] Bundles Only", 0)

    mutFilterInp = mkDropdown(rPnl, "Only this mutation (Scan / Select all)", MUT_OPTS, MUT_OPTS[1], 10)
    local opScanBtn = DS.btn(rPnl, "Scan Bag & Queue", "info", 20, 36)
    local failQ = false
    local failQBtn = DS.switch(rPnl, "[ ] Add failed star-trial cards' packs to queue", 21)
    local failQNow = DS.btn(rPnl, "Queue packs with failed cards now", "info", 22, 30)
    local failQLbl = DS.status(rPnl, "Failed-card packs: (none saved)", 23)
    local function failPackNames()
        local ps = FailedStore.packs()
        return #ps > 0 and table.concat(ps, ", ") or "(none saved)"
    end
    -- tick every owned item (matching the Bundles-Only and mutation settings) of packs that contain a failed card
    local function queueFailed()
        local ps = FailedStore.packs()
        failQLbl.Text = "Failed-card packs: " .. (#ps > 0 and table.concat(ps, ", ") or "(none saved)")
        local packsData = getLiveData("Packs") or {}
        local added = 0
        for _, pN in ipairs(ps) do
            local pD = SData[pN]
            if pD then
                for bName, on in pairs(pD.items) do
                    local owned = tonumber(packsData[bName]) or 0
                    local isBundle = string.find(bName, "%-Bundle$") ~= nil
                    if not on and owned > 0 and (not bundlesOnly or isBundle) and passes(bName) then
                        pD.items[bName] = true
                        added = added + 1
                        local b = BundleBtnMap[bName]
                        if b then b.Text = "   ↳ [X] " .. bName .. " (" .. owned .. ")" b.TextColor3 = C3(40,200,120) end
                    end
                end
                local any = false
                for _, v in pairs(pD.items) do if v then any = true break end end
                pD.isSelected = any
                pD.cBtn.Text = (any and " [X] " or " [ ] ") .. pN
                pD.cBtn.TextColor3 = any and C3(40,200,120) or C3(200,200,200)
            end
        end
        if added > 0 and SaveState then SaveState() end
        return added
    end
    failQBtn.MouseButton1Click:Connect(function()
        failQ = not failQ
        failQBtn.Text = (failQ and "[X] " or "[ ] ") .. "Add failed star-trial cards' packs to queue"
        failQBtn.BackgroundColor3 = failQ and C3(40,200,120) or C3(50,50,50)
        if failQ then queueFailed() end
        if SaveConfig then SaveConfig() end
    end)
    failQNow.MouseButton1Click:Connect(function()
        local n = queueFailed()
        failQNow.Text = "Queued " .. n .. " item(s)"
        task.delay(1.5, function() failQNow.Text = "Queue packs with failed cards now" end)
    end)
    task.spawn(function()
        while pFrame:IsDescendantOf(game) do
            failQLbl.Text = "Failed-card packs: " .. failPackNames()
            task.wait(5)
        end
    end)

    bOnlyBtn.MouseButton1Click:Connect(function()
        bundlesOnly = not bundlesOnly
        bOnlyBtn.Text = bundlesOnly and "[X] Bundles Only" or "[ ] All Packs+Bundles"
        bOnlyBtn.BackgroundColor3 = bundlesOnly and C3(40,200,120) or C3(50,50,50)
        if SaveConfig then SaveConfig() end
    end)

    opScanBtn.MouseButton1Click:Connect(function()
        opScanBtn.Text = "Scanning..."
        local packsData = getLiveData("Packs") or {}
        local count = 0
        for pN, pD in pairs(SData) do
            local anyInPack = false
            for bName, _ in pairs(pD.items) do
                local owned = tonumber(packsData[bName]) or 0
                local isBundle = string.find(bName, "%-Bundle$") ~= nil
                local shouldQueue = (owned > 0) and (not bundlesOnly or isBundle) and passes(bName)
                pD.items[bName] = shouldQueue
                if BundleBtnMap[bName] then
                    BundleBtnMap[bName].Text = "   ↳ " .. (shouldQueue and "[X] " or "[ ] ") .. bName .. (owned > 0 and (" (" .. owned .. ")") or "")
                    BundleBtnMap[bName].TextColor3 = shouldQueue and C3(40,200,120) or C3(150,150,150)
                end
                if shouldQueue then
                    anyInPack = true
                    count = count + 1
                end
            end
            pD.isSelected = anyInPack
            pD.cBtn.Text = (anyInPack and " [X] " or " [ ] ") .. pN
            pD.cBtn.TextColor3 = anyInPack and C3(40,200,120) or C3(200,200,200)
        end
        opScanBtn.Text = "Queued " .. count .. " Items!"
        if SaveState then SaveState() end
        task.delay(1.5, function() opScanBtn.Text = "Scan Bag & Queue" end)
    end)
    
    local potOptions = { "HatchTime1", "HatchTime2" }
    pcall(function()
        local cons = getLiveData("Consumables")
        if type(cons) == "table" then
            local extra = {}
            for k in pairs(cons) do if type(k) == "string" and string.find(k, "^HatchTime") and k ~= "HatchTime1" and k ~= "HatchTime2" then extra[#extra + 1] = k end end
            table.sort(extra)
            for _, k in ipairs(extra) do potOptions[#potOptions + 1] = k end
        end
    end)
    local batchOptions = {} for n = 22, 1, -1 do batchOptions[#batchOptions + 1] = tostring(n) end
    local opPotInp = mkDropdown(rPnl, "Hatch Potion", potOptions, "HatchTime2", 38)
    local opAmtInp = mkDropdown(rPnl, "Batch Size (max 22)", batchOptions, "22", 92)
    local opSpdInp = mkFullInp(rPnl, "Drop/TP Speed (ms) [Lower = Faster]", "35", 146, 28)
    local opDelInp = mkFullInp(rPnl, "Loop Delay (Seconds)", "1.5", 200, 28)

    for _, box in ipairs({opSpdInp, opDelInp}) do
        box.FocusLost:Connect(function() if SaveConfig then SaveConfig() end end)
    end
    
    local sLbl = DS.status(rPnl, "Status: Idle", 258)

    local opBtn = DS.btn(rPnl, "Start Auto-Opener", "ok", 290, 40)

    local isOpener = false
    local opCardEvt = getRemote("Card")
    local opPotEvt = getRemote("Potion")

    local function fireGuiButton(btn)
        if not btn or not btn:IsA("GuiButton") then return false end
        local fired = false
        if type(firesignal) == "function" then
            pcall(function() firesignal(btn.MouseButton1Click) fired = true end)
            pcall(function() firesignal(btn.Activated) fired = true end)
        end
        if not fired and type(getconnections) == "function" then
            for _, sig in ipairs({btn.MouseButton1Click, btn.Activated}) do
                for _, conn in ipairs(getconnections(sig)) do
                    if type(conn.Function) == "function" then
                        pcall(conn.Function)
                        fired = true
                    end
                end
            end
        end
        return fired
    end

    local function ensureBundleEquipped(targetItem, forceClear)
        if not forceClear then
            local hotbar = getLiveData("Hotbar")
            if type(hotbar) == "table" then
                for _, val in pairs(hotbar) do
                    if val == targetItem then return true end
                end
            end
        end

        local pg = LP:FindFirstChild("PlayerGui")
        local autoPlayFrame = pg and pg:FindFirstChild("AutoPlay") and pg.AutoPlay:FindFirstChild("Frame")

        if autoPlayFrame and autoPlayFrame:FindFirstChild("PacksEquipped") and autoPlayFrame.PacksEquipped:FindFirstChild("Main") then
            local eqMain = autoPlayFrame.PacksEquipped.Main
            for slotIdx = 1, 8 do
                local slotFrame = eqMain:FindFirstChild(tostring(slotIdx))
                local unequipBtn = slotFrame and slotFrame:FindFirstChild("Unequip")
                if unequipBtn and unequipBtn.Visible then
                    fireGuiButton(unequipBtn)
                end
            end
        end
        if opCardEvt then
            local hbNow = getLiveData("Hotbar")
            if type(hbNow) == "table" then
                for slotKey, eqItem in pairs(hbNow) do
                    if forceClear or eqItem ~= targetItem then
                        pcall(function() opCardEvt:FireServer("Unequip", tostring(slotKey)) end)
                        pcall(function() opCardEvt:FireServer("Unequip", tonumber(slotKey) or slotKey) end)
                        pcall(function() opCardEvt:FireServer("Unequip", eqItem) end)
                    end
                end
            end
        end
        task.wait(0.15)

        if autoPlayFrame and autoPlayFrame:FindFirstChild("PackFrame") then
            local packBtn = autoPlayFrame.PackFrame:FindFirstChild(targetItem)
            if packBtn then
                fireGuiButton(packBtn)
            end
        end
        if opCardEvt then
            pcall(function() opCardEvt:FireServer("Equip", targetItem) end)
        end
        task.wait(0.2)

        local verifyHb = getLiveData("Hotbar")
        if type(verifyHb) == "table" then
            for _, val in pairs(verifyHb) do
                if val == targetItem then return true end
            end
        end
        return false
    end

    local function setOpenerRunning(state)
        isOpener = state
        opBtn.Text = isOpener and "Stop Auto-Opener" or "Start Auto-Opener"
        opBtn.BackgroundColor3 = isOpener and C3(200,40,40) or C3(40,200,120)
        
        if not isOpener then
            sLbl.Text = "Idle"
            if SaveState then SaveState() end
            return
        end

        local function buildQ()
            local q = {}
            for _, pD in ipairs(sData) do
                local pN = pD.Name
                if SData[pN] then
                    for _, bN in ipairs(getPackVariants(pN)) do
                        if SData[pN].items[bN] then table.insert(q, {Pack=pN, Item=bN}) end
                    end
                end
            end
            return q
        end
        if failQ then queueFailed() end
        local aQ = buildQ()
        if #aQ == 0 then isOpener = false sLbl.Text = "ERR: NO BUNDLES QUEUED" opBtn.Text, opBtn.BackgroundColor3 = "Start Auto-Opener", C3(40,200,120) if SaveState then SaveState() end return end

        local cIdx = 1
        if SaveState then SaveState() end
        
        task.spawn(function()
            while isOpener and mFrame:IsDescendantOf(game) do
                local cT = aQ[cIdx]
                if not cT and failQ then
                    -- queue done: pick up packs of cards that failed in the meantime
                    queueFailed()
                    aQ = buildQ()
                    cIdx = 1
                    cT = aQ[cIdx]
                end
                if not cT then
                    isOpener = false
                    sLbl.Text = "Finished Queue!"
                    opBtn.Text, opBtn.BackgroundColor3 = "Start Auto-Opener", C3(40,200,120)
                    if SaveState then SaveState() end
                    break
                end

                local ownedBefore = getOwnedPackCount(cT.Item)
                if ownedBefore <= 0 then
                    uncheckBundle(cT.Item)
                    cIdx = cIdx + 1
                    sLbl.Text = cT.Item .. " (0 owned) -> Next"
                    task.wait(0.1)
                    continue
                end

                sLbl.Text = "Equipping: " .. cT.Item .. " (" .. ownedBefore .. ")"
                ensureBundleEquipped(cT.Item, false)

                local potName = stripTags(opPotInp.Text)
                local maxBatch = tonumber(opAmtInp.Text) or 22
                local amt = math.min(maxBatch, ownedBefore)
                local spdMs = tonumber(opSpdInp.Text) or 35
                local spdSec = math.max(0.015, spdMs / 1000)
                
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then task.wait(1) continue end
                
                local baseCFrame = hrp.CFrame
                local gridCenterCF = baseCFrame * CFrame.new(0, 0, -40)
                local columns, spacing = 8, 9
                local totalRows = math.ceil(amt / columns)
                local dropLocations = {}

                sLbl.Text = "Dropping " .. amt .. "x " .. cT.Item
                for i = 1, amt do
                    if not isOpener then break end
                    if getOwnedPackCount(cT.Item) <= 0 then break end
                    local row = math.floor((i - 1) / columns)
                    local colInRow = (i - 1) % columns
                    local col = (row % 2 == 0) and colInRow or (columns - 1 - colInRow)
                    local offsetX = (col - (columns - 1) / 2) * spacing
                    local offsetZ = (row - (totalRows - 1) / 2) * spacing
                    
                    local dropCF = gridCenterCF * CFrame.new(offsetX, 0, offsetZ)
                    table.insert(dropLocations, dropCF)
                    
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.CFrame = dropCF
                    task.wait(spdSec)
                    if opCardEvt then pcall(function() opCardEvt:FireServer("Place", cT.Item) end) end
                    task.wait(spdSec)
                end
                
                if not isOpener then hrp.CFrame = baseCFrame break end
                
                local function getGridPrompts()
                    local list = {}
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") and obj.Enabled then
                            local part = obj.Parent
                            if part and part:IsA("Model") then part = part.PrimaryPart or part:FindFirstChildWhichIsA("BasePart") end
                            if part and part:IsA("Attachment") then part = part.Parent end
                            local pPos = part and part:IsA("BasePart") and part.Position
                            if pPos then
                                local rel = gridCenterCF:PointToObjectSpace(pPos)
                                if math.abs(rel.X) <= 42 and math.abs(rel.Z) <= 24 then
                                    table.insert(list, {prompt = obj, pos = pPos, relX = rel.X, relZ = rel.Z})
                                end
                            end
                        end
                    end
                    table.sort(list, function(a, b)
                        if math.abs(a.relZ - b.relZ) > 3 then return a.relZ < b.relZ end
                        return a.relX < b.relX
                    end)
                    return list
                end

                task.wait(0.25)
                local validPrompts = getGridPrompts()
                if #validPrompts == 0 then
                    local ownedAfter = getOwnedPackCount(cT.Item)
                    if ownedAfter <= 0 then
                        uncheckBundle(cT.Item)
                        cIdx = cIdx + 1
                        sLbl.Text = cT.Item .. " Depleted!"
                    else
                        sLbl.Text = "Hotbar rejected Place! Force-clearing..."
                        ensureBundleEquipped(cT.Item, true)
                    end
                    hrp.CFrame = baseCFrame
                    task.wait(0.5)
                    continue
                end

                if potName ~= "" and opPotEvt then
                    sLbl.Text = "Applying Potions..."
                    for _ = 1, 7 do
                        pcall(function() opPotEvt:FireServer("Apply10", potName) end)
                        task.wait(0.04)
                    end
                    task.wait(0.2)
                end
                
                sLbl.Text = "Opening " .. #validPrompts .. " Packs..."
                if fireproximityprompt then
                    for _, entry in ipairs(validPrompts) do
                        if not isOpener then break end
                        if entry.prompt and entry.prompt.Parent then
                            pcall(function()
                                entry.prompt.HoldDuration = 0
                                entry.prompt.RequiresLineOfSight = false
                            end)
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.CFrame = CFrame.new(entry.pos + Vector3.new(0, 2.5, 0))
                            task.wait(math.max(0.03, spdSec * 0.7))
                            pcall(fireproximityprompt, entry.prompt)
                        end
                    end
                    task.wait(0.2)
                    local stragglers = getGridPrompts()
                    if #stragglers > 0 and isOpener then
                        sLbl.Text = "Cleaning up " .. #stragglers .. " stragglers..."
                        for _, entry in ipairs(stragglers) do
                            if not isOpener then break end
                            if entry.prompt and entry.prompt.Parent then
                                hrp.AssemblyLinearVelocity = Vector3.zero
                                hrp.CFrame = CFrame.new(entry.pos + Vector3.new(0, 2.5, 0))
                                task.wait(math.max(0.04, spdSec))
                                pcall(fireproximityprompt, entry.prompt)
                            end
                        end
                    end
                    task.wait(0.25)
                else
                    for _, cf in ipairs(dropLocations) do
                        if not isOpener then break end
                        hrp.CFrame = cf
                        task.wait(spdSec)
                        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                        task.wait(1.2)
                        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    end
                end
                
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.CFrame = baseCFrame
                if getOwnedPackCount(cT.Item) <= 0 then
                    uncheckBundle(cT.Item)
                    cIdx = cIdx + 1
                end
                local loopDel = tonumber(opDelInp.Text) or 1.5
                sLbl.Text = "Waiting " .. loopDel .. "s..."
                task.wait(loopDel)
            end
        end)
    end
    opBtn.MouseButton1Click:Connect(function() setOpenerRunning(not isOpener) if SaveState then SaveState() end end)

    OpenerAPI.GetConfig = function() return {potion = opPotInp.Text, amt = opAmtInp.Text, spd = opSpdInp.Text, delay = opDelInp.Text, bundlesOnly = bundlesOnly, mutFilter = mutFilterInp.Text, failQ = failQ} end
    OpenerAPI.LoadConfig = function(cfg)
        if type(cfg) ~= "table" then return end
        if cfg.potion then opPotInp.Text = tostring(cfg.potion) end
        if cfg.amt then opAmtInp.Text = tostring(cfg.amt) end
        if cfg.spd then opSpdInp.Text = tostring(cfg.spd) end
        if cfg.delay then opDelInp.Text = tostring(cfg.delay) end
        for _, o in ipairs(MUT_OPTS) do if cfg.mutFilter == o then mutFilterInp.Text = o end end
        if cfg.failQ ~= nil then
            failQ = cfg.failQ == true
            failQBtn.Text = (failQ and "[X] " or "[ ] ") .. "Add failed star-trial cards' packs to queue"
            failQBtn.BackgroundColor3 = failQ and C3(40,200,120) or C3(50,50,50)
        end
        if cfg.bundlesOnly ~= nil then
            bundlesOnly = cfg.bundlesOnly == true
            bOnlyBtn.Text = bundlesOnly and "[X] Bundles Only" or "[ ] All Packs+Bundles"
        end
    end
    OpenerAPI.GetState = function()
        local checked = {}
        for _, pD in pairs(SData) do
            for bN, isS in pairs(pD.items) do if isS then table.insert(checked, bN) end end
        end
        return {isO = isOpener or Resume.pending.opener == true, items = checked}
    end
    OpenerAPI.LoadState = function(st)
        if type(st) ~= "table" then return end
        local lookup = {} for _, bN in ipairs(st.items or {}) do lookup[bN] = true end
        for pN, pD in pairs(SData) do
            local anySelected = false
            for bN, _ in pairs(pD.items) do
                local s = lookup[bN] == true
                pD.items[bN] = s
                if s then anySelected = true end
                local btn = BundleBtnMap[bN]
                if btn then
                    local cnt = getOwnedPackCount(bN)
                    btn.Text = "   ↳ " .. (s and "[X] " or "[ ] ") .. bN .. (cnt > 0 and (" (" .. cnt .. ")") or "")
                    btn.TextColor3 = s and C3(40, 200, 120) or C3(150, 150, 150)
                end
            end
            pD.isSelected = anySelected
            pD.cBtn.Text = (anySelected and " [X] " or " [ ] ") .. pN
            pD.cBtn.TextColor3 = anySelected and C3(40, 200, 120) or C3(200, 200, 200)
        end
        if st.isO and #(st.items or {}) > 0 then
            sLbl.Text = "Resuming in 2s..."
            Resume.start("opener", function() return isOpener end, function() if not isOpener then setOpenerRunning(true) end end)
        end
    end
end
bOpener(oFrame, CardSortedPacks)

-- ==========================================
-- 9. FIGURINE GRADE / TRAIT ROLLER
-- ==========================================
local FigurineAPI = {}

local function buildFigurineGrader(parent)
    local listCard, controls = DS.split(parent, 300)
    local list = DS.new("ScrollingFrame", listCard, { Size = U2(1, -12, 1, -12), Position = U2(0, 6, 0, 6), ScrollBarThickness = 3, ScrollBarImageColor3 = T.stroke, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = U2(0, 0, 0, 0) })
    local layout = DS.vlist(list, 2)
    DS.pad(list, 0, 0, 6, 0)

    local status = DS.status(controls, "Status: Idle", 0)
    local modeBtn = DS.btn(controls, "Mode: Grade", "accent", 38, 36)
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
    local delayInp = mkFullInp(controls, "Delay (ms)", "300", 198, 30)
    local selRow = DS.new("Frame", controls, { Size = U2(1, 0, 0, 34), LayoutOrder = 258 })
    local selectBtn = DS.new("TextButton", selRow, { Size = U2(0.5, -4, 1, 0), BackgroundColor3 = T.surface3, TextColor3 = T.text2, Text = "Select All", Font = F_GM, TextSize = 12 })
    local clearBtn = DS.new("TextButton", selRow, { Size = U2(0.5, -4, 1, 0), Position = U2(0.5, 4, 0, 0), BackgroundColor3 = T.surface3, TextColor3 = T.text2, Text = "Clear", Font = F_GM, TextSize = 12 })
    DS.corner(selectBtn, 8) DS.corner(clearBtn, 8)
    local runBtn = DS.btn(controls, "Start Figurine Roller", "ok", 300, 40)

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
        local b = DS.item(list, "", 11)
        b.LayoutOrder = index
        buttons[name] = b
        b.MouseButton1Click:Connect(function()
            selected[name] = not selected[name]
            paint(name)
            if SaveState then SaveState() end
        end)
    end
    refresh()

    local function setMode(newMode)
        mode = (newMode == "Trait") and "Trait" or "Grade"
        modeBtn.Text = "Mode: " .. mode
        gradeInp.Visible, traitInp.Visible = mode == "Grade", mode == "Trait"
        if SaveConfig then SaveConfig() end
    end
    modeBtn.MouseButton1Click:Connect(function()
        setMode(mode == "Grade" and "Trait" or "Grade")
    end)
    selectBtn.MouseButton1Click:Connect(function()
        for _, name in ipairs(names) do selected[name] = true end
        refresh()
        if SaveState then SaveState() end
    end)
    clearBtn.MouseButton1Click:Connect(function()
        for _, name in ipairs(names) do selected[name] = false end
        refresh()
        if SaveState then SaveState() end
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

    local function finishRun(msg)
        running, waiting = false, false
        runBtn.Text, runBtn.BackgroundColor3 = "Start Figurine Roller", C3(40, 200, 120)
        if msg then status.Text = msg end
        if SaveState then SaveState() end
    end

    local function setRunning(state)
        if not state then
            if running then
                running, runId = false, runId + 1
                finishRun("Stopped")
            end
            return
        end
        if running then return end
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
        if #queue == 0 then status.Text = "Select at least one owned figurine" return end
        running, runId = true, runId + 1
        local myRun, index = runId, 1
        runBtn.Text, runBtn.BackgroundColor3 = "Stop Figurine Roller", C3(200, 40, 40)
        if SaveState then SaveState() end
        task.spawn(function()
            while running and runId == myRun do
                local name = queue[index]
                if not name then
                    finishRun("Finished")
                    break
                end
                local ownedRecord = getLiveRecord("Figurines", name)
                if not ownedRecord then
                    status.Text = "Skipping unowned: " .. name
                    index = index + 1
                else
                    local current = currentValue(name, mode)
                    if targetMet(current) then
                        selected[name] = false
                        paint(name)
                        if SaveState then SaveState() end
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
                            selected[name] = false
                            paint(name)
                            if SaveState then SaveState() end
                            index = index + 1
                        end
                        local remaining = delaySec - (os.clock() - started)
                        if remaining > 0 then task.wait(remaining) end
                    end
                end
                refresh()
            end
        end)
    end
    runBtn.MouseButton1Click:Connect(function() setRunning(not running) end)

    task.spawn(function()
        while parent:IsDescendantOf(game) do
            refresh()
            task.wait(1)
        end
    end)

    FigurineAPI.GetConfig = function()
        return { mode = mode, grade = gradeInp.Text, trait = traitInp.Text, delay = delayInp.Text }
    end
    FigurineAPI.LoadConfig = function(c)
        if type(c) ~= "table" then return end
        if c.mode == "Grade" or c.mode == "Trait" then setMode(c.mode) end
        if c.grade and c.grade ~= "" then gradeInp.Text = tostring(c.grade) end
        if c.trait and c.trait ~= "" then traitInp.Text = tostring(c.trait) end
        if c.delay then delayInp.Text = tostring(c.delay) end
    end
    FigurineAPI.GetState = function()
        local items = {}
        for _, name in ipairs(names) do
            if selected[name] then items[#items + 1] = name end
        end
        return { isF = running or Resume.pending.fig == true, items = items }
    end
    FigurineAPI.LoadState = function(st)
        if type(st) ~= "table" then return end
        selected = {}
        local count = 0
        for _, name in ipairs(st.items or {}) do
            if buttons[name] then
                selected[name] = true
                count = count + 1
            end
        end
        refresh()
        if st.isF == true and count > 0 then
            status.Text = "Resuming in 2s..."
            Resume.start("fig", function() return running end, function() if not running then setRunning(true) end end)
        elseif running then
            setRunning(false)
        else
            Resume.cancel("fig")
        end
    end
end

buildFigurineGrader(figFrame)

-- ==========================================
-- PACK EXCHANGE (auto upgrade / downgrade of packs to one rank)
-- ==========================================
-- Packs come in ranks Regular < Gold < Emerald < Void < Diamond < Rainbow and are stored as Packs["<pack>"] (Regular) and
-- Packs["<pack>-<rank>"]. From the game's PackExchange code:
--   Downgrade : Card:FireServer("Downgrade", pack, rank [, amount])   1 pack of <rank> -> Reward packs of the rank below, costs cash
--   Upgrade   : Card:FireServer("Exchange", pack, fromRank, toRank, amount)   Requirement packs of fromRank -> 1 pack of toRank
-- The game does not tell us why a request is refused (cash, packs...), so every request is checked against the pack counts afterwards.
local ExchangeAPI = {}
local function buildExchange(parent)
    local RANKS = { "Regular", "Gold", "Emerald", "Void", "Diamond", "Rainbow" }
    local REQ = { 0, 35, 25, 20, 15, 10 }
    local REWARD = { 0, 12, 8, 6, 4, 3 }
    pcall(function()
        local px = require(RS.Modules.Config.Core.PackExchange)
        for r = 2, 6 do
            local nm = RANKS[r]
            if type(px[nm]) == "table" and tonumber(px[nm].Requirement) then REQ[r] = px[nm].Requirement end
            if type(px.Downgrade) == "table" and type(px.Downgrade[nm]) == "table" and tonumber(px.Downgrade[nm].Reward) then REWARD[r] = px.Downgrade[nm].Reward end
        end
    end)
    local CardRemote = getRemote("Card")

    local function fmt(n)
        local str, r = tostring(math.floor(tonumber(n) or 0))
        repeat str, r = str:gsub("^(-?%d+)(%d%d%d)", "%1,%2") until r == 0
        return str
    end
    local function owned(p, r)
        local v = tonumber(getLiveData("Packs", r == 1 and p or (p .. "-" .. RANKS[r])))
        return v and math.floor(v) or 0
    end
    local function rankIndex(name) for i, n in ipairs(RANKS) do if n == name then return i end end return 1 end
    local MULT = { 1, 5, 10, 25, 60, 140 }
    pcall(function()
        local m = require(RS.Modules.Config.Core.Mutations)
        for r = 2, 6 do if type(m[RANKS[r]]) == "table" and tonumber(m[RANKS[r]].PriceMultiplier) then MULT[r] = m[RANKS[r]].PriceMultiplier end end
    end)
    local CardCfg
    pcall(function() CardCfg = require(RS.Modules.Config.Core.CardConfig) end)
    local function bundleOwned(p, r)
        local v = tonumber(getLiveData("Packs", p .. "-" .. RANKS[r] .. "-Bundle"))
        return v and math.floor(v) or 0
    end
    local function rnd(x) return math.floor(x + 0.5) end
    -- the game's own cash price per unit of a step (nil if the pack config can't be read: then retries are used instead)
    local function unitCost(kind, p, r)
        local info = CardCfg and type(CardCfg.Packs) == "table" and CardCfg.Packs[p]
        local price = type(info) == "table" and tonumber(info.Price)
        if not price then return nil end
        if kind == "up" then return math.ceil(price * REQ[r + 1] * MULT[r + 1]) end
        if kind == "down" then return math.ceil(math.ceil(price * REQ[r] * MULT[r]) * math.min(tonumber(info.Chance) or 1, 0.25)) end
        local base = rnd(price * (r > 1 and MULT[r] or 1))
        if kind == "bundle" then return base end
        return math.ceil(base * 0.5)
    end
    local function cashNow() return tonumber(getLiveData("Cash")) end

    local listCard, controls = DS.split(parent, 300)
    local selected, buttons, order = {}, {}, {}
    local allBtn, noneBtn, list = DS.tree(listCard)

    local status = DS.status(controls, "Status: Idle", 1)
    local targetInp = DS.dropdown(controls, "Exchange selected packs to mutation (upgrades and downgrades as needed)", RANKS, "Regular", 2)
    local BUNDLE_OPTS = { "Leave bundles alone", "Unbundle all bundles first", "Bundle packs at target rank after", "Unbundle first, then bundle at the end" }
    local bundleInp = DS.dropdown(controls, "Bundles (5 packs = 1 bundle)", BUNDLE_OPTS, BUNDLE_OPTS[1], 3)
    local scanBtn = DS.btn(controls, "Scan Inventory", "info", 4, 32)
    local previewBtn = DS.btn(controls, "Preview plan (changes nothing)", "info", 5, 32)
    local startBtn = DS.btn(controls, "Start", "ok", 6, 38)
    local logLbl = DS.status(controls, "Tick packs, pick a mutation, then Preview or Start. Amounts are worked out from your packs and cash and sent as one request per step. Anything the game needs more of for a full upgrade is left as is and reported.", 7)

    local logLines = {}
    local function say(t)
        logLines[#logLines + 1] = t
        while #logLines > 14 do table.remove(logLines, 1) end
        logLbl.Text = table.concat(logLines, "\n")
    end

    local function summary(p)
        local parts = {}
        for r = 6, 1, -1 do
            local c = owned(p, r)
            if c > 0 then parts[#parts + 1] = fmt(c) .. " " .. RANKS[r] end
        end
        return #parts > 0 and table.concat(parts, " · ") or "none"
    end
    local function paintRow(p)
        local row = buttons[p]
        if not row then return end
        local total = 0
        for r = 1, 6 do
            local c = owned(p, r)
            total = total + c
            local txt = RANKS[r] .. "   " .. fmt(c)
            if row.labels[r].Text ~= txt then row.labels[r].Text = txt end
            row.labels[r].TextColor3 = c > 0 and C3(225, 225, 225) or C3(110, 110, 110)
        end
        local txt = " " .. (selected[p] and "[X] " or "[ ] ") .. p .. "   " .. summary(p)
        if row.check.Text ~= txt then row.check.Text = txt end
        row.check.TextColor3 = selected[p] and C3(40, 220, 130) or (total > 0 and C3(210, 210, 210) or C3(120, 120, 120))
    end
    local function selectedCount() local n = 0 for _ in pairs(selected) do n = n + 1 end return n end
    for index, pD in ipairs(CardSortedPacks) do
        local p = pD.Name
        order[#order + 1] = p
        local pC, eBtn, cBtn, iF = DS.pack(list, index, p)
        local labels = {}
        for r = 6, 1, -1 do
            labels[r] = DS.new("TextLabel", iF, { Size = U2(1, 0, 0, 20), LayoutOrder = 7 - r, Text = RANKS[r], Font = F_GM, TextSize = 12, TextColor3 = T.text3, TextXAlignment = Enum.TextXAlignment.Left })
        end
        buttons[p] = { check = cBtn, labels = labels }
        eBtn.MouseButton1Click:Connect(function()
            iF.Visible = not iF.Visible
            eBtn.Text = iF.Visible and "-" or "+"
        end)
        cBtn.MouseButton1Click:Connect(function()
            selected[p] = not selected[p] or nil
            paintRow(p)
            if SaveConfig then SaveConfig() end
        end)
    end
    allBtn.MouseButton1Click:Connect(function() for _, p in ipairs(order) do selected[p] = true paintRow(p) end if SaveConfig then SaveConfig() end end)
    noneBtn.MouseButton1Click:Connect(function() for _, p in ipairs(order) do selected[p] = nil paintRow(p) end if SaveConfig then SaveConfig() end end)
    local function refreshRows() for _, p in ipairs(order) do paintRow(p) end end
    refreshRows()

    local function selectedList()
        local out = {}
        for _, p in ipairs(order) do if selected[p] then out[#out + 1] = p end end
        return out
    end
    local function wantDown() return true end
    local function wantUp() return true end

    local function wantUnbundle() local t = bundleInp.Text return t == BUNDLE_OPTS[2] or t == BUNDLE_OPTS[4] end
    local function wantBundle() local t = bundleInp.Text return t == BUNDLE_OPTS[3] or t == BUNDLE_OPTS[4] end

    -- what a run would do for one pack, from its current counts (also used for the preview)
    local function plan(p, target)
        local c, lines = {}, {}
        for r = 1, 6 do c[r] = owned(p, r) end
        if wantUnbundle() then
            for r = 1, 6 do
                local b = bundleOwned(p, r)
                if b > 0 then
                    lines[#lines + 1] = string.format("  unbundle %s %s bundles -> %s packs", fmt(b), RANKS[r], fmt(b * 5))
                    c[r] = c[r] + b * 5
                end
            end
        end
        if wantDown() then
            for r = 6, target + 1, -1 do
                if c[r] > 0 then
                    local gain = c[r] * REWARD[r]
                    lines[#lines + 1] = string.format("  downgrade %s %s -> %s %s", fmt(c[r]), RANKS[r], fmt(gain), RANKS[r - 1])
                    c[r - 1], c[r] = c[r - 1] + gain, 0
                end
            end
        end
        if wantUp() then
            for r = 1, target - 1 do
                local n = math.floor(c[r] / REQ[r + 1])
                if n > 0 then
                    lines[#lines + 1] = string.format("  upgrade %s %s -> %s %s (uses %s)", fmt(n * REQ[r + 1]), RANKS[r], fmt(n), RANKS[r + 1], fmt(n * REQ[r + 1]))
                    c[r + 1], c[r] = c[r + 1] + n, c[r] - n * REQ[r + 1]
                end
                if c[r] > 0 then
                    lines[#lines + 1] = string.format("  left over: %s %s (needs %d for one %s)", fmt(c[r]), RANKS[r], REQ[r + 1], RANKS[r + 1])
                end
            end
        end
        lines[#lines + 1] = "  result: " .. fmt(c[target]) .. " " .. RANKS[target]
        if wantBundle() then
            local nb = math.floor(c[target] / 5)
            if nb > 0 then lines[#lines + 1] = string.format("  bundle %s %s packs -> %s bundles (%s packs left)", fmt(nb * 5), RANKS[target], fmt(nb), fmt(c[target] - nb * 5)) end
        end
        return lines
    end

    local function doScan()
        refreshRows()
        local packsOwned, total = 0, 0
        for _, p in ipairs(order) do
            local any = false
            for r = 1, 6 do local c = owned(p, r) total = total + c if c > 0 then any = true end end
            if any then packsOwned = packsOwned + 1 end
        end
        status.Text = string.format("Status: scanned - %d of %d packs in your inventory (%s packs in total)", packsOwned, #order, fmt(total))
    end
    scanBtn.MouseButton1Click:Connect(doScan)
    previewBtn.MouseButton1Click:Connect(function()
        logLines = {}
        local packs = selectedList()
        if #packs == 0 then say("Select at least one pack first.") return end
        local target = rankIndex(targetInp.Text)
        say("Preview for target " .. RANKS[target] .. " (nothing is sent):")
        for i, p in ipairs(packs) do
            if i > 6 then say("... and " .. (#packs - 6) .. " more packs") break end
            say(p)
            for _, l in ipairs(plan(p, target)) do say(l) end
        end
    end)

    -- one request at a time; the game's own reply is not visible to us, so success = the source count dropped
    local running, runId = false, 0
    local function srcCount(kind, p, r) if kind == "unbundle" then return bundleOwned(p, r) end return owned(p, r) end
    local function settle(kind, p, r, before)
        local t0 = os.clock()
        while os.clock() - t0 < 2.5 do
            task.wait(0.1)
            local now = srcCount(kind, p, r)
            if now < before then
                task.wait(0.25)
                return before - srcCount(kind, p, r)
            end
        end
        return 0
    end
    -- kinds: "down" n packs of rank r -> rank r-1 | "up" n exchanges r -> r+1 | "bundle" n bundles from rank r packs | "unbundle" n bundles of rank r
    local function runStep(kind, p, r, n, myRun)
        local done, guess = 0, n
        while done < n and running and runId == myRun do
            local amt = math.min(guess, n - done)
            local before = srcCount(kind, p, r)
            local ok = pcall(function()
                local a = tostring(amt)
                if kind == "down" then
                    if amt <= 1 then CardRemote:FireServer("Downgrade", p, RANKS[r]) else CardRemote:FireServer("Downgrade", p, RANKS[r], a) end
                elseif kind == "up" then
                    CardRemote:FireServer("Exchange", p, RANKS[r], RANKS[r + 1], a)
                elseif kind == "bundle" then
                    if amt <= 1 then CardRemote:FireServer("Bundle", p, RANKS[r]) else CardRemote:FireServer("Bundle", p, RANKS[r], a) end
                else
                    local key = p .. "-" .. RANKS[r] .. "-Bundle"
                    if amt <= 1 then CardRemote:FireServer("Unbundle", key) else CardRemote:FireServer("Unbundle", key, a) end
                end
            end)
            if not ok then return done, "send failed" end
            local used = settle(kind, p, r, before)
            if used > 0 then
                local gained = used
                if kind == "up" then gained = math.floor(used / REQ[r + 1]) elseif kind == "bundle" then gained = math.floor(used / 5) end
                if gained <= 0 then return done, "unexpected pack change" end
                done = done + gained
                guess = n - done
            elseif amt > 1 then
                guess = math.floor(amt / 2) -- an all-or-nothing request that was refused: try half
            else
                return done, "refused"
            end
            task.wait(0.3)
        end
        return done, nil
    end

    local function setRunning(on)
        running = on and CardRemote ~= nil
        runId = runId + 1
        startBtn.Text = CardRemote and (running and "Stop" or "Start") or "ERR: Card remote missing"
        startBtn.BackgroundColor3 = running and C3(200, 40, 40) or C3(40, 200, 120)
        if not running then status.Text = "Status: Idle" return end
        local myRun = runId
        task.spawn(function()
            logLines = {}
            local packs = selectedList()
            local target = rankIndex(targetInp.Text)
            if #packs == 0 then say("Select at least one pack first.") running = false end
            local stopReason
            local VERB = { down = "downgraded", up = "upgraded", bundle = "bundled", unbundle = "unbundled" }
            for _, p in ipairs(packs) do
                if not running or runId ~= myRun or stopReason then break end
                say(p)
                local function alive() return running and runId == myRun and not stopReason end
                local function step(kind, r, n)
                    local want = n
                    -- exact cash limit from the game's own price formula
                    local unit = unitCost(kind, p, r)
                    local cash = cashNow()
                    local capped = false
                    if unit and unit > 0 and cash then
                        local afford = math.floor(cash / unit)
                        if afford < n then
                            if afford <= 0 then
                                stopReason = string.format("Not enough cash for %s %s (%s each, you have %s).", kind, RANKS[r], fmt(unit), fmt(cash))
                                say("  " .. stopReason)
                                return
                            end
                            n, capped = afford, true
                        end
                    end
                    status.Text = string.format("Status: %s - %s %s (%s)", p, kind, RANKS[r], fmt(n))
                    local done, err = runStep(kind, p, r, n, myRun)
                    say(string.format("  %s %s of %s %s%s", VERB[kind], fmt(done), fmt(want), kind == "unbundle" and (RANKS[r] .. " bundles") or RANKS[r], capped and (" (cash limit, " .. fmt(unit) .. " each)") or ""))
                    if err then
                        stopReason = string.format("The game did not accept the %s of %s %s for %s (%s). Cash now: %s", kind, RANKS[r], kind == "bundle" and "packs" or "", p, err, fmt(getLiveData("Cash") or 0))
                    elseif capped then
                        stopReason = "Out of cash (spent down to the last affordable amount, cash now " .. fmt(getLiveData("Cash") or 0) .. ")."
                    end
                end
                if wantUnbundle() then
                    for r = 1, 6 do
                        if not alive() then break end
                        local b = bundleOwned(p, r)
                        if b > 0 then step("unbundle", r, b) end
                    end
                end
                if wantDown() then
                    for r = 6, target + 1, -1 do
                        if not alive() then break end
                        local c = owned(p, r)
                        if c > 0 then step("down", r, c) end
                    end
                end
                if wantUp() then
                    for r = 1, target - 1 do
                        if not alive() then break end
                        local c = owned(p, r)
                        local n = math.floor(c / REQ[r + 1])
                        if n > 0 then step("up", r, n) end
                        local left = owned(p, r)
                        if left > 0 and not stopReason then say(string.format("  left over: %s %s (needs %d for one %s)", fmt(left), RANKS[r], REQ[r + 1], RANKS[r + 1])) end
                    end
                end
                if wantBundle() and alive() then
                    local nb = math.floor(owned(p, target) / 5)
                    if nb > 0 then step("bundle", target, nb) end
                end
                refreshRows()
            end
            if runId == myRun then
                running = false
                startBtn.Text, startBtn.BackgroundColor3 = "Start", C3(40, 200, 120)
                status.Text = "Status: " .. (stopReason and "Stopped" or "Done")
                if stopReason then say("STOPPED: " .. stopReason) else say("Done.") end
            end
        end)
    end
    startBtn.MouseButton1Click:Connect(function() setRunning(not running) if SaveState then SaveState() end end)

    task.spawn(function()
        while parent:IsDescendantOf(game) do
            if parent.Visible then refreshRows() end
            task.wait(2)
        end
    end)

    ExchangeAPI.GetConfig = function()
        return { target = targetInp.Text, bundles = bundleInp.Text, packs = selectedList() }
    end
    ExchangeAPI.LoadConfig = function(c)
        if type(c) ~= "table" then return end
        if c.target and RANKS[rankIndex(c.target)] == c.target then targetInp.Text = c.target end
        for _, o in ipairs(BUNDLE_OPTS) do if c.bundles == o then bundleInp.Text = o end end
        selected = {}
        for _, p in ipairs(c.packs or {}) do if buttons[p] then selected[p] = true end end
        refreshRows()
    end
    ExchangeAPI.GetState = function() return { on = running or Resume.pending.exchange == true } end
    ExchangeAPI.LoadState = function(st)
        if type(st) ~= "table" then return end
        if st.on == true and not running and #selectedList() > 0 then
            status.Text = "Resuming in 2s..."
            Resume.start("exchange", function() return running end, function() if not running then setRunning(true) end end)
        elseif st.on == false then
            Resume.cancel("exchange")
            if running then setRunning(false) end
        end
    end
    setRunning(false)
    doScan()
end
buildExchange(exFrame)

-- ==========================================
-- AUTO COLLECT: grade tokens on the map + the Dragon Ball (uses the game's own pickup functions, sent from where you stand)
-- ==========================================
local CollectAPI = {}
local function buildCollect(parent)
    local CS = game:GetService("CollectionService")
    local card = DS.card(DS.page(parent), "Auto Collect", "Picks up map items without walking to them. It calls the game's own pickup functions from where you stand.", 1)
    local tokBtn = DS.switch(card, "[ ] Grade tokens on the map", 1)
    local ballBtn = DS.switch(card, "[ ] Dragon Ball (spawns around the map)", 2)
    local moveBtn = DS.switch(card, "[ ] If a pickup is refused, walk next to it", 3)
    local stat = DS.status(card, "Status: Off", 4)
    local on = { tok = false, ball = false, move = false }
    local st = { tokens = 0, refused = 0, balls = 0, ballRefused = 0, last = "-" }
    local mods = {}
    local function handler(name)
        if mods[name] == nil then
            local ok, m = pcall(function() return require(RS.Client.UI[name]) end)
            mods[name] = (ok and type(m) == "table") and m or false
        end
        return mods[name] or nil
    end
    local function hrp() local c = LP.Character return c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart) end
    -- walk next to a position, run fn, walk back
    local function visit(cf, fn)
        local r = hrp()
        if not r then return end
        local back = r.CFrame
        r.CFrame = cf * CFrame.new(0, 2, 0)
        task.wait(1.2)
        pcall(fn)
        task.wait(1)
        local r2 = hrp()
        if r2 then r2.CFrame = back end
    end
    local function paint(btn, label, v)
        btn.Text = (v and "[X] " or "[ ] ") .. label
        btn.BackgroundColor3 = v and C3(40, 200, 120) or C3(50, 50, 50)
    end
    local L_TOK, L_BALL, L_MOVE = "Grade tokens on the map", "Dragon Ball (spawns around the map)", "If a pickup is refused, walk next to it"
    local function flip(key, btn, label)
        on[key] = not on[key]
        paint(btn, label, on[key])
        if SaveConfig then SaveConfig() end
    end
    tokBtn.MouseButton1Click:Connect(function() flip("tok", tokBtn, L_TOK) end)
    ballBtn.MouseButton1Click:Connect(function() flip("ball", ballBtn, L_BALL) end)
    moveBtn.MouseButton1Click:Connect(function() flip("move", moveBtn, L_MOVE) end)

    local function refresh()
        local parts = {}
        parts[#parts + 1] = string.format("Tokens: %d collected, %d refused", st.tokens, st.refused)
        parts[#parts + 1] = string.format("Dragon Balls: %d collected, %d refused", st.balls, st.ballRefused)
        parts[#parts + 1] = "Last: " .. st.last
        stat.Text = "Status: " .. ((on.tok or on.ball) and "Watching" or "Off") .. "\n" .. table.concat(parts, "\n")
    end

    -- ===== grade tokens: parts tagged "<YourName>Token"; the game's CollectToken(part) sends CollectToken + part.Name =====
    local tries = setmetatable({}, { __mode = "k" })
    local function fireToken(part)
        part:SetAttribute("Collected", nil)
        local GH = handler("GradeHandler")
        if GH and type(GH.CollectToken) == "function" then
            if pcall(GH.CollectToken, part) then return end
        end
        local r = getRemote("Card")
        if r then pcall(function() r:FireServer("CollectToken", part.Name) end) end
    end
    task.spawn(function()
        while true do
            task.wait(1)
            if on.tok then
                pcall(function()
                    local list = CS:GetTagged(LP.Name .. "Token")
                    local before = tonumber(getLiveData("GradeTokens")) or 0
                    local sent, sentParts = 0, {}
                    for _, part in ipairs(list) do
                        if not on.tok then break end
                        local t = tries[part]
                        if t and t.n >= 3 and os.clock() - t.at > 60 then t = nil end
                        if part.Parent and part:GetAttribute("Collected") ~= true and (not t or t.n < 3) then
                            tries[part] = { n = (t and t.n or 0) + 1, at = os.clock() }
                            fireToken(part)
                            sent = sent + 1
                            sentParts[#sentParts + 1] = part
                            task.wait(0.15)
                        end
                    end
                    if sent > 0 then
                        task.wait(2)
                        local gain = (tonumber(getLiveData("GradeTokens")) or 0) - before
                        if gain > 0 then
                            st.tokens = st.tokens + gain
                            st.last = os.date("%H:%M:%S") .. " grade token +" .. gain
                        else
                            st.refused = st.refused + sent
                            st.last = os.date("%H:%M:%S") .. " token pickup gave nothing"
                            if on.move then
                                for i = 1, math.min(#sentParts, 3) do
                                    local part = sentParts[i]
                                    if part.Parent then visit(part.CFrame, function() fireToken(part) end) end
                                end
                                local g2 = (tonumber(getLiveData("GradeTokens")) or 0) - before
                                if g2 > 0 then st.tokens = st.tokens + g2 st.last = os.date("%H:%M:%S") .. " grade token +" .. g2 .. " (walked)" end
                            end
                        end
                    end
                end)
            end
            pcall(refresh)
        end
    end)

    -- ===== dragon ball: the game shows your ball as workspace.VFX["<name>-DB"]; the real part sits at the same spot =====
    local handled = setmetatable({}, { __mode = "k" })
    local function collectBall(model)
        local pivot = model:GetPivot().Position
        local found
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("BasePart") and not d:IsDescendantOf(workspace.VFX) and not (LP.Character and d:IsDescendantOf(LP.Character)) and (d.Position - pivot).Magnitude < 1 then
                if #CS:GetTags(d) > 0 then found = d break end
            end
        end
        local function fire()
            if found then found:SetAttribute("Collected", nil) end
            local DH = handler("DragonBallHandler")
            if found and DH and type(DH.CollectDB) == "function" and pcall(DH.CollectDB, found) then return end
            local r = getRemote("DragonBall")
            if r then pcall(function() r:FireServer("Collect") end) end
        end
        local function gone() return model.Parent == nil end
        for attempt = 1, 3 do
            fire()
            for _ = 1, 8 do task.wait(0.5) if gone() then break end end
            if gone() then break end
        end
        if not gone() and on.move then
            visit(found and found.CFrame or CFrame.new(pivot), fire)
            for _ = 1, 6 do task.wait(0.5) if gone() then break end end
        end
        if gone() then
            st.balls = st.balls + 1
            st.last = os.date("%H:%M:%S") .. " Dragon Ball collected"
        else
            st.ballRefused = st.ballRefused + 1
            st.last = os.date("%H:%M:%S") .. " Dragon Ball pickup refused"
        end
    end
    task.spawn(function()
        while true do
            task.wait(1.5)
            if on.ball then
                pcall(function()
                    local vfx = workspace:FindFirstChild("VFX")
                    if not vfx then return end
                    for _, c in ipairs(vfx:GetChildren()) do
                        if (c.Name == LP.Name .. "-DB" or c.Name == tostring(LP.UserId) .. "-DB") and not handled[c] then
                            handled[c] = true
                            task.wait(0.5)
                            collectBall(c)
                        end
                    end
                end)
            end
        end
    end)

    CollectAPI.GetConfig = function() return { tokens = on.tok, ball = on.ball, move = on.move } end
    CollectAPI.LoadConfig = function(c)
        if type(c) ~= "table" then return end
        on.tok, on.ball, on.move = c.tokens == true, c.ball == true, c.move == true
        paint(tokBtn, L_TOK, on.tok) paint(ballBtn, L_BALL, on.ball) paint(moveBtn, L_MOVE, on.move)
    end
    CollectAPI.Stats = st
    refresh()
end
buildCollect(colFrame)

-- ==========================================
-- 10. SETTINGS TAB & AUTO-SYNC ENGINE
-- ==========================================
local sPage = DS.page(sFrame)
local sPnl = DS.card(sPage, "Account", nil, 1)
local accInfoLbl = DS.new("TextLabel", sPnl, { Size = U2(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = F_GM, TextSize = 12, TextColor3 = T.text2, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, LayoutOrder = 1 })
accInfoLbl.Text = "Account: " .. LP.Name .. "  |  UserId: " .. UID .. "\nConfig: " .. ConfigFileName .. "\nState: " .. StateFileName
local prefPnl = DS.card(sPage, "Preferences", nil, 2)
local scInp = mkDropdown(prefPnl, "UI Scale (Auto sizes it for your screen / touch)", { "Auto", "0.6", "0.7", "0.8", "0.9", "1.0", "1.1", "1.2", "1.3", "1.5", "1.7", "2.0", "2.3", "2.6", "3.0" }, "Auto", 75)
scInp:GetPropertyChangedSignal("Text"):Connect(function() applyScale(scInp.Text) end)

local isAFK = true
local afkBtn = DS.switch(prefPnl, "[X] Built-In Anti-AFK", 80)

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

local dataPnl = DS.card(sPage, "Data", "Settings and queues are saved automatically per account.", 3)
local statusFileLbl = DS.label(dataPnl, "Auto-Sync Active (No manual save/load required)", 12, T.ok2, F_GM, 1)
local rstBtn = DS.btn(dataPnl, "Reset Account State & Queue", "danger", 2, 36)

local Persist = {}
function Persist.stamp() statusFileLbl.Text = "Auto-saved " .. os.date("%H:%M:%S") end

function Persist.safe(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok then return value end
    return nil
end

function Persist.readJson(path)
    if not (readfile and isfile and isfile(path)) then return nil end
    local ok, data = pcall(function() return HS:JSONDecode(readfile(path)) end)
    if ok and type(data) == "table" then return data end
    return nil
end

function Persist.dataReady()
    local ok, ready = pcall(function()
        if type(getLiveData("Cards")) == "table" then return true end
        if type(getLiveData("Figurines")) == "table" then return true end
        return false
    end)
    return ok and ready == true
end

function Persist.waitReady(timeout)
    local t0 = os.clock()
    while not Persist.dataReady() and os.clock() - t0 < timeout do task.wait(0.5) end
    return Persist.dataReady()
end

function Persist.getRaid()
    local packs = {}
    for _, name in ipairs(raidPacks) do
        if raidSelectedPacks[name] then packs[#packs + 1] = name end
    end
    return { running = raidRunning or Resume.pending.raid == true, packs = packs }
end

function Persist.loadRaid(st)
    if type(st) ~= "table" then return end
    for name in pairs(raidSelectedPacks) do raidSelectedPacks[name] = nil end
    for _, name in ipairs(st.packs or {}) do
        if raidPackButtons[name] then raidSelectedPacks[name] = true end
    end
    refreshRaidPackRows()
    if st.running and (next(raidSelectedPacks) ~= nil or raidJoinAll) and not raidRunning then
        Resume.start("raid", function() return raidRunning end, function() if not raidRunning then setRaidState(true) end end)
    elseif not st.running then
        Resume.cancel("raid")
    end
end

function Persist.buildConfig()
    return {
        userId = LP.UserId, accountName = LP.Name, uiScale = scInp.Text, afk = isAFK, fishDelay = fDelInp.Text, raidNoVis = raidNoVis, raidJoinAll = raidJoinAll,
        grader = Persist.safe(GraderAPI.GetConfig),
        tower = Persist.safe(TowerAPI.GetConfig),
        auto = Persist.safe(AutoAPI.GetConfig),
        star = Persist.safe(StarAPI.GetConfig),
        opener = Persist.safe(OpenerAPI.GetConfig),
        fig = Persist.safe(FigurineAPI.GetConfig),
        exchange = Persist.safe(ExchangeAPI.GetConfig),
        collect = Persist.safe(CollectAPI.GetConfig),
    }
end

function Persist.buildState()
    return {
        userId = LP.UserId, accountName = LP.Name,
        marketBuyAll = isMarketBuyAll,
        fish = isFish, gems = isGems, hud = isHudEnabled,
        raid = Persist.getRaid(),
        grader = Persist.safe(GraderAPI.GetState),
        tower = Persist.safe(TowerAPI.GetState),
        auto = Persist.safe(AutoAPI.GetState),
        star = Persist.safe(StarAPI.GetState),
        opener = Persist.safe(OpenerAPI.GetState),
        fig = Persist.safe(FigurineAPI.GetState),
        exchange = Persist.safe(ExchangeAPI.GetState),
    }
end

SaveConfig = function()
    if not writefile or Persist.loadingCfg then return end
    pcall(function() writefile(ConfigFileName, HS:JSONEncode(Persist.buildConfig())) end)
end

SaveState = function()
    if not writefile or not Persist.restored then return end
    pcall(function() writefile(StateFileName, HS:JSONEncode(Persist.buildState())) end)
end

function Persist.startAutosave()
    if Persist.autosaving or not writefile then return end
    Persist.autosaving = true
    task.spawn(function()
        local lastCfg, lastSt
        while mFrame:IsDescendantOf(game) do
            local okC, encC = pcall(function() return HS:JSONEncode(Persist.buildConfig()) end)
            if okC and encC ~= lastCfg then
                lastCfg = encC
                pcall(writefile, ConfigFileName, encC) pcall(Persist.stamp)
            end
            local okS, encS = pcall(function() return HS:JSONEncode(Persist.buildState()) end)
            if okS and encS ~= lastSt then
                lastSt = encS
                pcall(writefile, StateFileName, encS) pcall(Persist.stamp)
            end
            task.wait(2)
        end
    end)
end

rstBtn.MouseButton1Click:Connect(function()
    for _, l in ipairs({ "grader", "tower", "opener", "fig", "exchange", "raid" }) do Resume.cancel(l) end
    Persist.safe(GraderAPI.LoadState, {isG = false, items = {}})
    Persist.safe(TowerAPI.LoadState, {isT = false, items = {}})
    Persist.safe(OpenerAPI.LoadState, {isO = false, items = {}})
    Persist.safe(FigurineAPI.LoadState, {isF = false, items = {}})
    Persist.safe(ExchangeAPI.LoadState, {on = false})
    Persist.safe(setMarketBuyState, false)
    Persist.safe(setRaidState, false)
    Persist.safe(Persist.loadRaid, {running = false, packs = {}})
    if SaveState then SaveState() end
    statusFileLbl.Text = "Account state & queue cleared!"
    task.delay(2, function() statusFileLbl.Text = "Auto-Sync Active (No manual save/load required)" end)
end)

local function InitAccountFiles()
    local function try(label, fn)
        local ok, err = pcall(fn)
        if not ok then warn("[ACC] restore " .. label .. " failed: " .. tostring(err)) end
    end

    local cfg = Persist.readJson(ConfigFileName)
    local st = Persist.readJson(StateFileName)

    setAfkState(true)

    Persist.loadingCfg = true
    if cfg then
        try("settings", function()
            if cfg.uiScale then scInp.Text = tostring(cfg.uiScale) applyScale(scInp.Text) end
            if cfg.afk ~= nil then setAfkState(cfg.afk) end
            if cfg.fishDelay then fDelInp.Text = tostring(cfg.fishDelay) end
            if cfg.raidJoinAll ~= nil then
                raidJoinAll = cfg.raidJoinAll and true or false
                raidAllBtn.Text = (raidJoinAll and "[X] " or "[ ] ") .. "Join ALL raids (needed for manga tokens)"
                raidAllBtn.BackgroundColor3 = raidJoinAll and C3(40, 200, 120) or C3(50, 50, 50)
            end
            if cfg.raidNoVis ~= nil then
                raidNoVis = cfg.raidNoVis and true or false
                raidVisBtn.Text = (raidNoVis and "[X] " or "[ ] ") .. "No raid teleport / visuals"
                applyRaidVis(raidRunning and raidNoVis)
            end
        end)
        try("grader config", function() if cfg.grader then GraderAPI.LoadConfig(cfg.grader) end end)
        try("tower config", function() if cfg.tower then TowerAPI.LoadConfig(cfg.tower) end end)
        try("auto config", function() if cfg.auto then AutoAPI.LoadConfig(cfg.auto) end end)
        try("star config", function() if cfg.star then StarAPI.LoadConfig(cfg.star) end end)
        try("opener config", function() if cfg.opener then OpenerAPI.LoadConfig(cfg.opener) end end)
        try("figurine config", function() if cfg.fig then FigurineAPI.LoadConfig(cfg.fig) end end)
        try("exchange config", function() if cfg.exchange then ExchangeAPI.LoadConfig(cfg.exchange) end end)
        try("collect config", function() if cfg.collect then CollectAPI.LoadConfig(cfg.collect) end end)
    end

    Persist.loadingCfg = false

    if st then
        try("market", function() if st.marketBuyAll ~= nil and st.marketBuyAll ~= isMarketBuyAll then setMarketBuyState(st.marketBuyAll) end end)
        try("fish", function() if st.fish ~= nil and st.fish ~= isFish then setFishState(st.fish) end end)
        try("gems", function() if st.gems ~= nil and st.gems ~= isGems then setGemsState(st.gems) end end)
        try("hud", function() if st.hud ~= nil and st.hud ~= isHudEnabled then setHudState(st.hud) end end)
        try("auto", function() if st.auto then AutoAPI.LoadState(st.auto) end end)
    end

    task.spawn(function()
        if st then
            Persist.waitReady(25)
            try("grader", function() if st.grader then GraderAPI.LoadState(st.grader) end end)
            try("tower", function() if st.tower then TowerAPI.LoadState(st.tower) end end)
            try("opener", function() if st.opener then OpenerAPI.LoadState(st.opener) end end)
            try("figurines", function() if st.fig then FigurineAPI.LoadState(st.fig) end end)
            try("star trial", function() if st.star then StarAPI.LoadState(st.star) end end)
            try("exchange", function() if st.exchange then ExchangeAPI.LoadState(st.exchange) end end)
            try("raid", function() if st.raid then Persist.loadRaid(st.raid) end end)
            task.wait(6)
        else
            task.wait(1)
        end
        Persist.restored = true
        Persist.startAutosave()
    end)
end

InitAccountFiles()
print("ACC Master Suite (11-Tab Edition + Market BuyAll) Loaded Successfully!")
