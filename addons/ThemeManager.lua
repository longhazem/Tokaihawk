--[[
    addons/ThemeManager.lua (gen3)
    LinoriaLib ThemeManager-compatible shim backed by Airflow's native
    CreateThemeManager panel + Airflow:SetTheme. BRM5.lua calls this exact
    surface already (see BRM5.lua lines ~39-46, ~5553, ~5561):

        ThemeManager.BuiltInThemes.Clean = { 0, { FontColor=..., MainColor=..., ... } }
        ThemeManager.DefaultTheme = 'Clean'
        ThemeManager:SetLibrary(Library)
        ThemeManager:SetFolder(name)
        ThemeManager:ApplyToTab(tab)

    Airflow owns the actual theme engine (presets, live cross-fade, weather,
    transparency, UI scale, density — see llms.txt "Theme" section) — this
    file only translates Linoria's hex-table theme format into a call to
    Airflow:SetTheme and swaps the panel builder for Tab:CreateThemeManager.
]]

local ThemeManager = {}
ThemeManager.BuiltInThemes = {}
ThemeManager.DefaultTheme = nil
ThemeManager._library = nil
ThemeManager._folder = nil

local function hexToColor3(hex)
    if typeof(hex) == 'Color3' then return hex end
    if type(hex) ~= 'string' then return nil end
    hex = hex:gsub('#', '')
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if not (r and g and b) then return nil end
    return Color3.fromRGB(r, g, b)
end

-- Linoria theme shape: { Order, { FontColor=hex, MainColor=hex, BackgroundColor=hex, AccentColor=hex, OutlineColor=hex } }
-- Airflow theme shape: { Background, Surface, Surface2, Surface3, Stroke, StrokeHover, Accent, AccentDark, Text, Muted, Success, Warning, Error }
local function linoriaThemeToAirflow(entry)
    local colors = entry and entry[2]
    if type(colors) ~= 'table' then return nil end
    local bg = hexToColor3(colors.BackgroundColor)
    local main = hexToColor3(colors.MainColor)
    local accent = hexToColor3(colors.AccentColor)
    local outline = hexToColor3(colors.OutlineColor)
    local text = hexToColor3(colors.FontColor)
    return {
        Background = bg,
        Surface = main,
        Surface2 = main,
        Stroke = outline,
        Accent = accent,
        Text = text,
    }
end

function ThemeManager:SetLibrary(library)
    self._library = library
end

function ThemeManager:SetFolder(name)
    -- Airflow's folder is set once via ConfigurationSaving.FolderName at
    -- CreateWindow time (tokaihawk_gen3.lua reads Library._configFolder if
    -- present before building the window). Store it here; if the window is
    -- already built, this is a no-op — set it before CreateWindow instead,
    -- or pass FolderName directly in Library:CreateWindow's info table.
    self._folder = name
end

function ThemeManager:ApplyToTab(tab)
    -- BRM5.lua hands this the TabShim returned by Window:AddTab(...), which
    -- carries ._airflowTab (see tokaihawk_gen3.lua).
    local airflowTab = tab and tab._airflowTab
    if not airflowTab then
        warn('[ThemeManager gen3] ApplyToTab: tab has no underlying Airflow tab')
        return
    end
    airflowTab:CreateThemeManager({ Side = 'Right' })

    -- Apply the chosen default theme once, translated to Airflow's format.
    local entry = self.DefaultTheme and self.BuiltInThemes[self.DefaultTheme]
    local themeTable = entry and linoriaThemeToAirflow(entry)
    if themeTable then
        local Airflow = self._library and self._library._airflow
        if Airflow then
            pcall(function() Airflow:SetTheme(themeTable) end)
        end
    end
end

-- Compat no-ops some scripts call; Airflow's own manager has no equivalent concept.
function ThemeManager:ApplyToGroupbox(groupbox)
    warn('[ThemeManager gen3] ApplyToGroupbox has no Airflow equivalent — use ApplyToTab instead')
end

return ThemeManager
