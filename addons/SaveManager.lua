--[[
    addons/SaveManager.lua (gen3)
    LinoriaLib SaveManager-compatible shim backed by Airflow's native
    CreateConfigManager + Window:LoadAutoload. BRM5.lua calls (see
    BRM5.lua lines ~5540-5633):

        SaveManager:SetLibrary(Library)
        SaveManager:IgnoreThemeSettings()
        SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
        SaveManager:SetFolder('Tokaihub/BRM5')
        SaveManager:BuildConfigSection(Tabs['UI Settings'])
        SaveManager:LoadAutoloadConfig()

    Airflow already saves every Flagged element automatically (llms.txt:
    "Every element with a `Flag` is saved by configs") and ships its own
    config browser/autoload UI via Tab:CreateConfigManager — this file is a
    thin translator, not a reimplementation.
]]

local SaveManager = {}
SaveManager._library = nil
SaveManager._folder = nil
SaveManager._ignoreIndexes = {}
SaveManager._ignoreThemeSettings = false

function SaveManager:SetLibrary(library)
    self._library = library
end

function SaveManager:SetFolder(name)
    -- Same caveat as ThemeManager:SetFolder — Airflow's FolderName is read
    -- at CreateWindow time. Stored here for Library:CreateWindow to pick up
    -- if called before the window exists; otherwise cosmetic only, since
    -- Airflow already persists by Flag regardless of folder name.
    self._folder = name
    if self._library then self._library._configFolder = name end
end

function SaveManager:IgnoreThemeSettings()
    -- Airflow stores theme under its own hidden __Theme flag already,
    -- separate from element flags — nothing to exclude manually.
    self._ignoreThemeSettings = true
end

function SaveManager:SetIgnoreIndexes(list)
    self._ignoreIndexes = list or {}
    -- Airflow has no per-flag "don't save" switch; if BRM5.lua truly needs
    -- a flag excluded, don't give that element a Flag at all (unflagged
    -- elements are never saved — see llms.txt "Every element with a Flag").
end

function SaveManager:BuildConfigSection(tab)
    local airflowTab = tab and tab._airflowTab
    if not airflowTab then
        warn('[SaveManager gen3] BuildConfigSection: tab has no underlying Airflow tab')
        return
    end
    airflowTab:CreateConfigManager({ Side = 'Left' })
end

function SaveManager:LoadAutoloadConfig()
    local window = self._library and self._library._window and self._library._window._airflowWindow
    if not window then
        warn('[SaveManager gen3] LoadAutoloadConfig: no window yet — call after Library:CreateWindow')
        return
    end
    pcall(function() window:LoadAutoload() end)
end

return SaveManager
