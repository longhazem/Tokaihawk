# HawkTokai

Một file thư viện: `HawkTokai.lua` có sẵn toàn bộ Airflow UI (đã đổi tên) cộng mọi tính năng thêm vào, kể cả hai addon save và theme.

## cấu trúc

```
HawkTokai/            ← để trong thư mục workspace của executor
  HawkTokai.lua       ← toàn bộ thư viện
  Example.lua         ← demo, chỉ nạp HawkTokai.lua
  README.md
HawkTokaiFonts/       ← ValleySans cho LoadFont (không có thì UI vẫn chạy bằng font Roblox)
```

## nạp

```lua
local HawkTokai = loadstring(readfile("HawkTokai/HawkTokai.lua"))()
local Window = HawkTokai:CreateWindow({
    Name = "HawkTokai",
    ConfigurationSaving = { Enabled = true, FolderName = "HawkTokaiExample", FileName = "default" },
})
```

## tab và control (Airflow)

`Window:CreateTab`, rồi `CreateSection`, `CreateDivider`, `CreateLabel`, `CreateParagraph`, `CreateButton`, `CreateToggle`, `CreateSlider`, `CreateStepper`, `CreateProgress`, `CreateDropdown`, `CreateInput`, `CreateKeybind`, `CreateColorPicker`. xem `Example.lua`.

## thêm vào thư viện

- **hiệu ứng:** `AddTabEffects(Window)` (lớp tối và thanh accent khi đổi tab). `AddPageEffects(Window)` (halo ở 2 góc nội dung và page phóng nhẹ). `AddScrollFades(Window)` (mép scroll mờ). hai hàm sau trả về handle, `SetEnabled(on)` để bật tắt.
- **HUD:** `CreateKeybindHUD({ Corner, Visible })` và `AddFeature(tab, { Name, Flag, Key, Mode, Default, Callback })`. `CreateInfoHUD({ Corner, Watermark, Items, Visible, Custom })` có `SetCorner`, `SetVisible`, `SetItems`, `SetWatermark`, `Destroy`.
- **tìm kiếm:** `AddMenuSearch(Window)`. gõ để lọc control trên mọi tab, ctrl+f để focus.
- **bố cục:** `AddSubTabs(tab, { ... })` chia tab thành sub-tab, gọi ngay sau `CreateTab`. `AddSettingsGroup(tab, toggle)` nhóm control chỉ hiện khi toggle bật. `AddColumns(tab, count, { Gap })` chia nhiều cột. `AddToggleSection(tab, { Name, Default, Flag })` trả về toggle và nhóm.
- **danh sách:** `AddSearchableToggleList(tab, { Items, Default, Flag, Callback })` và `AddReorderableList(tab, { Items, Flag, Callback })`. cả hai có `Get`, `Set(names, skipCallback)`. list kéo thả đổi thứ tự bằng cách kéo card.
- **giao diện:** `AddWindowOpacity(Window, tab, { Default, Flag })`, `AddCursorOverride(Window)` (có `SetEnabled`), `AddBackgroundPattern(Window, { Opacity, Tile })` (nền chấm, cần `getcustomasset`).
- **autoload:** `AddAutoload(Window, tab, { Folder })` lưu một tên config và tải khi dựng cửa sổ.

## lưu và theme (có sẵn của airflow)

- `ConfigurationSaving` ở `CreateWindow`: `{ Enabled, FolderName, FileName, AutoSave }`. lưu và tải mọi element có `Flag`.
- `Window:SaveConfig(name?)`, `Window:LoadConfig(name?, skipCallbacks?)`, `Window:DeleteConfig(name)`, `Window:ListConfigs()`, `Window:SetAutoSave(on)`.
- `Tab:CreateConfigManager({ Name })`: ô tên, dropdown các config, save, load, delete và toggle autosave.
- `Tab:CreateThemePicker({ Flag = "Theme" })`: config nhớ theme. `HawkTokai:AddTheme`, `GetThemes`, `SetTheme`.
- gọi `Window:LoadConfig()` sau khi mọi element đã được tạo. `AddAutoload` tải thêm một config khi mở.

## quy tắc đồng bộ

- màu và font lấy từ theme và font đang chạy (`HawkTokai.UI.color`, `HawkTokai.UI.font`). `SetTheme` đổi cả phần mới, gồm HUD nằm ngoài window.
- control có `Flag` được lưu và tải bởi `SaveConfig` và `LoadConfig` như control của Airflow. callback và autosave chạy một lần khi người dùng đổi, không chạy lại khi load.
- empty state đếm cả element trong sub-tab và column.

## lưu ý

- element tạo trên tab gốc sau khi gọi `AddSubTabs` hoặc `AddColumns` sẽ bị ẩn. dùng các tab trả về.
- executor cần `readfile`, `writefile`, `isfile`, `loadstring`. nền chấm cần thêm `getcustomasset`.
- chưa chạy trong Roblox, mới kiểm tra cú pháp và biên dịch.
