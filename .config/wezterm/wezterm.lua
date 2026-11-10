local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- Appearance
config.front_end = 'WebGpu'
--- config.check_for_updates = false
config.animation_fps = 1
config.enable_scroll_bar = true
config.window_frame = { active_titlebar_bg = '#222', inactive_titlebar_bg = '#111' }

-- Platform
local is_linux = wezterm.target_triple:find('linux') ~= nil
local is_win = wezterm.target_triple:find('windows') ~= nil
local is_mac = wezterm.target_triple:find('apple%-darwin') ~= nil

if is_win then
    config.set_environment_variables = { prompt = '$E]7;file://localhost/$P$E\\$E[32m$T$E[0m $E[35m$P$E[36m$_$G$E[0m ' }
end

-- Launch menu
config.launch_menu = {}
if is_win then
    local sys32 = (os.getenv('SystemRoot') or 'C:\\Windows') .. '\\System32\\'
    table.insert(config.launch_menu, { label = 'PowerShell', args = { sys32 .. 'WindowsPowerShell\\v1.0\\powershell.exe', '-NoLogo' } })
    for _, vsvers in ipairs(wezterm.glob('Microsoft Visual Studio/20*', 'C:/Program Files (x86)')) do
        local year = vsvers:gsub('Microsoft Visual Studio/', '')
        table.insert(config.launch_menu, {
            label = 'x64 Native Tools VS ' .. year,
            args = { sys32 .. 'cmd.exe', '/k', 'C:/Program Files (x86)/' .. vsvers .. '/BuildTools/VC/Auxiliary/Build/vcvars64.bat' },
        })
    end
end

-- Keybindings
config.use_dead_keys = false

local SUPER = is_mac and 'SUPER' or 'ALT'
local SUPER_REV = is_mac and 'SUPER|CTRL' or 'ALT|CTRL'
local WIN = is_mac and 'SUPER' or 'LEADER'
local dirs = { Left = 'h', Down = 'j', Up = 'k', Right = 'l' }

config.leader = { key = 'Space', mods = SUPER_REV, timeout_milliseconds = 1000 }
config.keys = {
    { key = 'r', mods = 'LEADER', action = act.ActivateKeyTable { name = 'resize_pane', one_shot = false } },
    { key = '\\', mods = SUPER, action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = '\\', mods = SUPER_REV, action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    { key = 'F1', mods = 'NONE', action = act.ActivateCopyMode },
    { key = 'F2', mods = 'NONE', action = act.ActivateCommandPalette },
    { key = 'F3', mods = 'NONE', action = act.ShowLauncher },
    { key = 'F11', mods = 'NONE', action = act.ToggleFullScreen },
    { key = 'f', mods = WIN, action = act.Search({ CaseInSensitiveString = '' }) },
    { key = '[', mods = WIN, action = act.ActivateTabRelative(-1) },
    { key = ']', mods = WIN, action = act.ActivateTabRelative(1) },
    { key = 'w', mods = WIN, action = act.CloseCurrentPane({ confirm = true }) },
}

-- Pane navigation: SUPER_REV + h/j/k/l
for dir, key in pairs(dirs) do
    table.insert(config.keys, { key = key, mods = SUPER_REV, action = act.ActivatePaneDirection(dir) })
end

-- Resize mode: LEADER + r
local resize = { { key = 'Escape', action = 'PopKeyTable' } }
for dir, key in pairs(dirs) do
    table.insert(resize, { key = dir .. 'Arrow', action = act.AdjustPaneSize { dir, 1 } })
    table.insert(resize, { key = key, action = act.AdjustPaneSize { dir, 1 } })
end
config.key_tables = { resize_pane = resize }

wezterm.on('update-right-status', function(window)
    local name = window:active_key_table()
    window:set_right_status(name and ('TABLE: ' .. name) or '')
end)

config.mouse_bindings = {
    { event = { Down = { streak = 1, button = 'Right' } }, mods = 'NONE', action = act.PasteFrom 'Clipboard' },
    { event = { Up = { streak = 1, button = 'Left' } }, mods = 'NONE', action = act.CompleteSelection 'ClipboardAndPrimarySelection' },
    { event = { Up = { streak = 1, button = 'Left' } }, mods = 'CTRL', action = act.OpenLinkAtMouseCursor },
    { event = { Down = { streak = 1, button = 'Left' } }, mods = 'CTRL', action = act.Nop },
    { event = { Down = { streak = 1, button = { WheelUp = 1 } } }, mods = 'CTRL', action = act.IncreaseFontSize, },
    { event = { Down = { streak = 1, button = { WheelDown = 1 } } }, mods = 'CTRL', action = act.DecreaseFontSize, },
}

wezterm.on('open-uri', function(_, _, uri)
    local scheme = uri:match('^([%a][%w+.-]*):')
    scheme = scheme and scheme:lower()
    if scheme ~= 'http' and scheme ~= 'https' then
        return false
    end
end)

return config
