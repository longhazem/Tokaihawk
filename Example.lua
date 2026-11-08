-- load the library. tries HawkTokai/HawkTokai.lua first, then HawkTokai.lua in the workspace root
local function hawkLoad()
    local lastErr = "no candidate path worked"
    for _, path in ipairs({ "HawkTokai/HawkTokai.lua", "HawkTokai.lua" }) do
        local okRead, src = pcall(readfile, path)
        if okRead and type(src) == "string" and #src > 0 then
            local okCompile, fn, compileErr = pcall(loadstring, src, path)
            if not okCompile or type(fn) ~= "function" then
                lastErr = "compile error in " .. path .. ": " .. tostring(compileErr or fn)
            else
                local okRun, lib = pcall(fn)
                if okRun and type(lib) == "table" then return lib end
                lastErr = "run error in " .. path .. ": " .. tostring(lib)
            end
        else
            lastErr = "cannot read " .. path .. " (put the HawkTokai folder in the executor workspace)"
        end
    end
    error("[HawkTokai] " .. lastErr, 0)
end

local HawkTokai = hawkLoad()

-- our palette. added to the theme list, so it also shows in the theme picker
HawkTokai:AddTheme("HawkTokai", {
    Base = "Midnight",
    Background = Color3.fromRGB(12, 12, 14),
    Surface = Color3.fromRGB(20, 20, 24),
    Surface2 = Color3.fromRGB(27, 27, 33),
    Surface3 = Color3.fromRGB(36, 36, 44),
    Stroke = Color3.fromRGB(46, 46, 56),
    StrokeHover = Color3.fromRGB(74, 74, 88),
    Accent = Color3.fromRGB(230, 168, 86),
    AccentDark = Color3.fromRGB(40, 28, 14),
    Text = Color3.fromRGB(236, 236, 240),
    Muted = Color3.fromRGB(140, 140, 152),
    Glow = Color3.fromRGB(230, 168, 86),
})

-- font is optional. if it fails the UI still loads with the Roblox font
local okFont, fontErr = pcall(function() return HawkTokai:LoadFont({ Name = "ValleySans" }) end)
if not okFont then warn("[HawkTokai] ValleySans not loaded: " .. tostring(fontErr)) end

local Window = HawkTokai:CreateWindow({
    Name = "HawkTokai",
    LoadingSubtitle = "Example",
    Theme = "HawkTokai", -- our palette. also "Default", "Midnight", "Moss", "Ember", "Rose", "Mono", or a table
    ToggleUIKeybind = "RightControl", -- key that hides and shows the window
    -- examples: "RightShift", "RightControl", "LeftAlt", "Insert", "Home", "F1", "Backquote"
    -- Enum.KeyCode values also work: ToggleUIKeybind = Enum.KeyCode.RightShift
    ConfigurationSaving = { Enabled = true, FolderName = "HawkTokaiExample", FileName = "default" },
    Home = {
        Name = "Home",
        Stats = { "FPS", "Ping", "Executor", "Game", "Region", "Time" },
        Pages = { -- extra tabs beside the info one
            {
                Name = "Changelog",
                Icon = "scroll-text",
                Entries = {
                    { Title = "v1.3", Tag = "Latest", Changes = { "Live themes and six presets", "Lock, hide and rename any element", "Hold-mode keybinds" } },
                    { Title = "v1.2", Tag = "Sep 12", Changes = { "Added the home tab", "Smaller input boxes that grow", "Faster dropdowns" } },
                    { Title = "v1.1", Tag = "Aug 30", Changes = { "Config manager", "Stepper and progress elements" } },
                },
            },
            {
                Name = "Info",
                Icon = "info",
                Content = "HawkTokai UI example. Everything on the Elements tab just prints, so you can click around safely.",
            },
        },
    },
})

local Elements = Window:CreateTab({ Name = "Elements", Desc = "One of everything", Icon = "layout-grid" })

Elements:CreateSection("Buttons")

Elements:CreateButton({
    Name = "Example button",
    Desc = "Example description",
    Icon = "mouse-pointer-click",
    Callback = function()
        print("button")
    end,
})

Elements:CreateButton({
    Name = "Example primary button",
    Style = "Primary",
    Callback = function()
        print("primary button")
    end,
})

Elements:CreateButton({
    Name = "Example danger button",
    Style = "Danger",
    Icon = "trash-2",
    Callback = function()
        print("danger button")
    end,
})

Elements:CreateButton({
    Name = "Example locked button",
    Desc = "Locked elements ignore input until unlocked",
    Locked = true,
    LockedReason = "Premium",
})

Elements:CreateSection("Values")

local ExampleToggle = Elements:CreateToggle({
    Name = "Example toggle",
    Desc = "Example description",
    CurrentValue = false,
    Flag = "ExampleToggle",
    Callback = function(Value)
        print("toggle", Value)
    end,
})

Elements:CreateToggle({
    Name = "Lock the toggle above",
    Callback = function(Value)
        ExampleToggle:SetLocked(Value, "Locked by the switch below")
    end,
})

Elements:CreateSlider({
    Name = "Example slider",
    Desc = "Click the value to type a number",
    Range = { 0, 100 },
    Increment = 1,
    Suffix = "%",
    CurrentValue = 50,
    Flag = "ExampleSlider",
    Callback = function(Value)
        print("slider", Value)
    end,
})

Elements:CreateStepper({
    Name = "Example stepper",
    Range = { 0, 10 },
    Increment = 0.5,
    CurrentValue = 5,
    Flag = "ExampleStepper",
    Callback = function(Value)
        print("stepper", Value)
    end,
})

Elements:CreateProgress({
    Name = "Example progress",
    CurrentValue = 0.65,
})

Elements:CreateSection("Choices")

Elements:CreateDropdown({
    Name = "Example dropdown",
    Options = { "Option 1", "Option 2", "Option 3" },
    CurrentOption = "Option 1",
    Flag = "ExampleDropdown",
    Callback = function(Option)
        print("dropdown", Option)
    end,
})

Elements:CreateDropdown({
    Name = "Example multi dropdown",
    Options = { "Option 1", "Option 2", "Option 3", "Option 4" },
    MultipleOptions = true,
    CurrentOption = { "Option 1" },
    Placeholder = "Nothing picked",
    Flag = "ExampleMultiDropdown",
    Callback = function(Options)
        print("multi dropdown", table.concat(Options, ", "))
    end,
})

Elements:CreateInput({
    Name = "Example input",
    PlaceholderText = "Type here",
    MaxLength = 24,
    Flag = "ExampleInput",
    OnChanged = function(Text)
        print("typing", Text)
    end,
    Callback = function(Text, EnterPressed)
        print("input", Text, EnterPressed)
    end,
})

Elements:CreateKeybind({
    Name = "Example keybind",
    Desc = "Backspace clears it while rebinding",
    CurrentKeybind = "F",
    Flag = "ExampleKeybind",
    Callback = function(Key)
        print("keybind", Key.Name)
    end,
})

Elements:CreateKeybind({
    Name = "Example hold keybind",
    CurrentKeybind = "LeftAlt",
    Mode = "Hold",
    Flag = "ExampleHoldKeybind",
    Callback = function(Held)
        print("held", Held)
    end,
})

Elements:CreateColorPicker({
    Name = "Example color picker",
    Color = Color3.fromRGB(235, 199, 246),
    Flag = "ExampleColor",
    Callback = function(Color)
        print("color", Color)
    end,
})

Elements:CreateDivider()

Elements:CreateLabel("Example label")

Elements:CreateParagraph({
    Title = "Example paragraph",
    Content = "Longer text that wraps across several lines.",
})

local Popups = Window:CreateTab({ Name = "Popups", Desc = "Notifications and dialogs", Icon = "bell" })

for _, Type in ipairs({ "Info", "Success", "Warning", "Error" }) do
    Popups:CreateButton({
        Name = Type .. " notification",
        Callback = function()
            HawkTokai:Notify({
                Title = Type,
                Content = "Example " .. string.lower(Type) .. " notification",
                Icon = "bell",
                Type = Type,
                Duration = 3,
            })
        end,
    })
end

Popups:CreateButton({
    Name = "Example confirm",
    Callback = function()
        HawkTokai:Confirm({
            Title = "Example confirm",
            Content = "Are you sure?",
            ConfirmText = "Yes",
            CancelText = "No",
            Callback = function()
                print("confirmed")
            end,
        })
    end,
})

Popups:CreateButton({
    Name = "Example dialog",
    Callback = function()
        HawkTokai:Dialog({
            Title = "Example dialog",
            Content = "Pick one.",
            Buttons = {
                { Title = "One", Callback = function() print("one") end },
                { Title = "Two", Callback = function() print("two") end },
                { Title = "Three", Variant = "Primary", Callback = function() print("three") end },
            },
        })
    end,
})

Window:CreateTab({ Name = "Empty", Desc = "Nothing in here", Icon = "package" })

-- features: keybind HUD and one key per feature
local hud = nil

if HawkTokai.AddTabEffects then
    local okFx, errFx = pcall(function() return HawkTokai:AddTabEffects(Window) end)
    if not okFx then
        warn("[HawkTokai] tab effects failed: " .. tostring(errFx))
    end
end

-- page effects (halos at two corners and a zoom on page change) and scroll edge fades
local pageFx, fadesFx = nil, nil
do
    local okPage, resultPage = pcall(function() return HawkTokai:AddPageEffects(Window) end)
    if okPage then
        pageFx = resultPage
    else
        warn("[HawkTokai] page effects failed: " .. tostring(resultPage))
    end
    local okScroll, resultScroll = pcall(function() return HawkTokai:AddScrollFades(Window) end)
    if okScroll then
        fadesFx = resultScroll
    else
        warn("[HawkTokai] scroll fades failed: " .. tostring(resultScroll))
    end
end

if HawkTokai.CreateKeybindHUD and HawkTokai.AddFeature then
    local okFeatures, errFeatures = pcall(function()
        local Features = Window:CreateTab({ Name = "Features", Desc = "each feature has its own key", Icon = "crosshair" })
        hud = HawkTokai:CreateKeybindHUD({ Corner = "Top Right", Visible = true })

        HawkTokai:AddFeature(Features, {
            Name = "Aimbot", Flag = "feat_aimbot", Key = Enum.KeyCode.F,
            Callback = function(on) print("aimbot", on) end,
        })
        HawkTokai:AddFeature(Features, {
            Name = "ESP", Flag = "feat_esp", Key = Enum.KeyCode.G, Default = true,
            Callback = function(on) print("esp", on) end,
        })
        HawkTokai:AddFeature(Features, {
            Name = "Triggerbot", Flag = "feat_trigger", Mode = "Hold", Key = Enum.KeyCode.E,
            Callback = function(on) print("triggerbot", on) end,
        })

        Features:CreateDropdown({
            Name = "HUD corner",
            Options = { "Top Left", "Top Right", "Bottom Left", "Bottom Right" },
            CurrentOption = "Top Right",
            Flag = "hud_corner",
            Callback = function(v) hud:SetCorner(v) end,
        })
        Features:CreateToggle({
            Name = "Show keybind HUD",
            Default = true,
            Flag = "hud_visible",
            Callback = function(v) hud:SetVisible(v) end,
        })
    end)
    if not okFeatures then
        warn("[HawkTokai] features tab failed: " .. tostring(errFeatures))
    end
end

-- menu search, info HUD and background dots: all built into HawkTokai.lua

if HawkTokai.AddMenuSearch then
    pcall(function() HawkTokai:AddMenuSearch(Window) end)
end

local info = nil
if HawkTokai.CreateInfoHUD then
    local okInfo, result = pcall(function()
        return HawkTokai:CreateInfoHUD({ Corner = "Bottom Left", Watermark = "HawkTokai", Items = { "fps", "ping", "time", "player" }, Visible = true })
    end)
    if okInfo then
        info = result
    else
        warn("[HawkTokai] info hud failed: " .. tostring(result))
    end
end

local dots = nil
if HawkTokai.AddBackgroundPattern then
    local okDots, result = pcall(function()
        return HawkTokai:AddBackgroundPattern(Window, { Opacity = 0.12, Tile = 32 })
    end)
    if okDots then
        dots = result
    else
        warn("[HawkTokai] background pattern failed: " .. tostring(result))
    end
end

local Look = Window:CreateTab({ Name = "Look", Desc = "layout and look extras", Icon = "palette" })
local subs = nil
if HawkTokai.AddSubTabs then
    local okSubs, result = pcall(function()
        return HawkTokai:AddSubTabs(Look, { "General", "Advanced" })
    end)
    if okSubs then
        subs = result
    else
        warn("[HawkTokai] sub-tabs failed: " .. tostring(result))
    end
end
local general = subs and subs[1] or Look
local advanced = subs and subs[2] or Look

general:CreateToggle({
    Name = "Info HUD",
    Default = true,
    Flag = "look_info",
    Callback = function(on)
        if info then
            info:SetVisible(on)
        end
    end,
})
general:CreateToggle({
    Name = "Dot background",
    Default = true,
    Flag = "look_dots",
    Callback = function(on)
        if dots then
            dots.Visible = on
        end
    end,
})

general:CreateDropdown({
    Name = "Info corner",
    Options = { "Top Left", "Top Right", "Bottom Left", "Bottom Right" },
    CurrentOption = "Bottom Left",
    Flag = "look_corner",
    Callback = function(value)
        if info and value then
            info:SetCorner(value)
        end
    end,
})
if HawkTokai.AddSearchableToggleList then
    HawkTokai:AddSearchableToggleList(general, {
        Items = { "fps", "ping", "time", "player", "game" },
        Default = { "fps", "ping", "time", "player" },
        Flag = "look_items",
        Callback = function(names)
            if info then
                info:SetItems(names)
            end
        end,
    })
end
general:CreateToggle({
    Name = "Page effects",
    Default = true,
    Flag = "fx_page",
    Callback = function(on)
        if pageFx then
            pageFx:SetEnabled(on)
        end
    end,
})
general:CreateToggle({
    Name = "Scroll fades",
    Default = true,
    Flag = "fx_fades",
    Callback = function(on)
        if fadesFx then
            fadesFx:SetEnabled(on)
        end
    end,
})

local advancedToggle = advanced:CreateToggle({
    Name = "Show extra controls",
    Default = false,
    Flag = "look_extra",
})
local group = nil
if HawkTokai.AddSettingsGroup then
    group = HawkTokai:AddSettingsGroup(advanced, advancedToggle)
end
if group then
    group:CreateSlider({ Name = "Demo slider", Min = 0, Max = 10, Default = 5, Flag = "look_slider" })
    group:CreateLabel({ Text = "this group only shows while Show extra controls is on" })
end

-- More tab: columns, a searchable toggle list, a reorderable list, a toggle section, window opacity and the cursor override

local More = Window:CreateTab({ Name = "More", Desc = "columns, lists and sections", Icon = "menu" })
local cols = nil
if HawkTokai.AddColumns then
    local okCols, result = pcall(function()
        return HawkTokai:AddColumns(More, 2)
    end)
    if okCols then
        cols = result
    else
        warn("[HawkTokai] columns failed: " .. tostring(result))
    end
end
local left = cols and cols[1] or More
local right = cols and cols[2] or More

left:CreateSection("Searchable list")
if HawkTokai.AddSearchableToggleList then
    HawkTokai:AddSearchableToggleList(left, {
        Items = { "Enemies", "Teammates", "Self", "Objective", "Radar", "Chat" },
        Default = { "Enemies", "Radar" },
        Flag = "more_picks",
        Callback = function(names)
            print("picked", table.concat(names, ", "))
        end,
    })
end

right:CreateSection("Reorderable list")
if HawkTokai.AddReorderableList then
    HawkTokai:AddReorderableList(right, {
        Items = { "Head", "Chest", "Arms", "Legs" },
        Flag = "more_order",
        Callback = function(order)
            print("order", table.concat(order, " > "))
        end,
    })
end

if HawkTokai.AddToggleSection then
    local _, sectionGroup = HawkTokai:AddToggleSection(right, { Name = "Aim assist", Default = false, Flag = "more_aim" })
    if sectionGroup then
        sectionGroup:CreateSlider({ Name = "Strength", Min = 0, Max = 100, Default = 50, Suffix = "%", Flag = "more_strength" })
    end
end

if HawkTokai.AddWindowOpacity then
    pcall(function()
        HawkTokai:AddWindowOpacity(Window, left, { Default = 100, Flag = "more_opacity" })
    end)
end

local cursor = nil
if HawkTokai.AddCursorOverride then
    local okCursor, result = pcall(function()
        return HawkTokai:AddCursorOverride(Window)
    end)
    if okCursor then
        cursor = result
    end
end
left:CreateToggle({
    Name = "Force cursor while open",
    Default = true,
    Flag = "more_cursor",
    Callback = function(on)
        if cursor then
            cursor:SetEnabled(on)
        end
    end,
})

local Settings = Window:CreateTab({ Name = "Settings", Icon = "settings" })

Settings:CreateSection("Interface")

Settings:CreateThemePicker({ Flag = "Theme" })

Settings:CreateKeybind({
    Name = "Toggle UI",
    CurrentKeybind = "RightControl",
    OnChanged = function(Key)
        Window:SetKeybind(Key)
    end,
})

Settings:CreateConfigManager({ Name = "Configs" })

Settings:CreateButton({
    Name = "Unload",
    Icon = "power",
    Style = "Danger",
    Callback = function()
        HawkTokai:Confirm({
            Title = "Unload?",
            ConfirmText = "Unload",
            Callback = function()
                Window:Destroy()
            end,
        })
    end,
})

Window:LoadConfig()

-- autoload last, so a saved autoload config wins over the default load above
if HawkTokai.AddAutoload then
    local okAuto, errAuto = pcall(function()
        HawkTokai:AddAutoload(Window, Settings)
    end)
    if not okAuto then
        warn("[HawkTokai] autoload failed: " .. tostring(errAuto))
    end
end

