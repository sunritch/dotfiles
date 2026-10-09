local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

--- appearance
config.front_end = "WebGpu"
config.webgpu_power_preference = "LowPower"
config.animation_fps = 1
config.enable_scroll_bar = true
config.window_frame = {
    active_titlebar_bg = '#222',
    inactive_titlebar_bg = '#111',
}

config.inactive_pane_hsb = {
    saturation = 0.9,
    brightness = 0.8,
}

config.set_environment_variables = {
    -- This changes the default prompt for cmd.exe to report the
    -- current directory using OSC 7, show the current time and
    -- the current directory colored in the prompt.
    prompt = '$E]7;file://localhost/$P$E\\$E[32m$T$E[0m $E[35m$P$E[36m$_$G$E[0m ',
}

local function is_found(str, pattern)
    return string.find(str, pattern) ~= nil
end
local is_linux  = is_found(wezterm.target_triple, 'linux')
local is_mac = is_found(wezterm.target_triple, 'apple')
--- launch
local launch_menu = {}
if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
    table.insert(launch_menu, {
                     label = 'PowerShell',
                     args = { 'powershell.exe', '-NoLogo' },
    })
    for _, vsvers in
        ipairs(
            wezterm.glob('Microsoft Visual Studio/20*', 'C:/Program Files (x86)')
        )
    do
        local year = vsvers:gsub('Microsoft Visual Studio/', '')
        table.insert(launch_menu, {
                         label = 'x64 Native Tools VS ' .. year,
                         args = {
                             'cmd.exe',
                             '/k',
                             'C:/Program Files (x86)/'
                                 .. vsvers
                                 .. '/BuildTools/VC/Auxiliary/Build/vcvars64.bat',
                         },
        })
    end    
else
    table.insert(launch_menu,{label = 'Emacs',args = { 'emacs' },})
    table.insert(launch_menu,{label = 'Vi',args = { 'vi' },})
    table.insert(launch_menu,{label = 'NeoVim',args = { 'nvim' },})
end
config.launch_menu = launch_menu

--- keybindings
config.use_dead_keys = false

-- Show which key table is active in the status area
wezterm.on('update-right-status', function(window, pane)
               local name = window:active_key_table()
               if name then
                   name = 'TABLE: ' .. name
               end
               window:set_right_status(name or '')
end)

local SUPER = is_mac and 'SUPER' or 'ALT'
local SUPER_REV = is_mac and 'SUPER|CTRL' or 'ALT|CTRL'
config.leader = { key = 'Space', mods = SUPER_REV, timeout_milliseconds = 1000}
config.keys = {
    {key = 'r',mods = 'LEADER',action = act.ActivateKeyTable {
         name = 'resize_pane',
         one_shot = false,
    },},
    {key = 'a',mods = 'LEADER',action = act.ActivateKeyTable {
         name = 'activate_pane',
         one_shot = false,
         timeout_milliseconds = 1000,
    },},
    {key = '\\',mods = SUPER,action = act.SplitHorizontal { domain = 'CurrentPaneDomain' },},
    {key = '\\',mods = SUPER_REV,action = act.SplitVertical { domain = 'CurrentPaneDomain' },},
    { key = 'F1', mods = 'NONE', action = act.ActivateCopyMode },
   { key = 'F2', mods = 'NONE', action = act.ActivateCommandPalette },
   { key = 'F3', mods = 'NONE', action = act.ShowLauncher },
   { key = 'F4', mods = 'NONE', action = act.ShowLauncherArgs({ flags = 'FUZZY|TABS' }) },
   { key = 'F5', mods = 'NONE', action = act.ShowLauncherArgs({ flags = 'FUZZY|WORKSPACES' }),},
   { key = 'F11', mods = 'NONE',    action = act.ToggleFullScreen },
   { key = 'F12', mods = 'NONE',    action = act.ShowDebugOverlay },
   { key = 'f',   mods = SUPER, action = act.Search({ CaseInSensitiveString = '' }) },
   {
      key = 'u',
      mods = SUPER_REV,
      action = wezterm.action.QuickSelectArgs({
         label = 'open url',
         patterns = {
            '\\((https?://\\S+)\\)',
            '\\[(https?://\\S+)\\]',
            '\\{(https?://\\S+)\\}',
            '<(https?://\\S+)>',
            '\\bhttps?://\\S+[)/a-zA-Z0-9-]+'
         },
         action = wezterm.action_callback(function(window, pane)
            local url = window:get_selection_text_for_pane(pane)
            wezterm.log_info('opening: ' .. url)
            wezterm.open_with(url)
         end),
      }),},
   { key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo('Clipboard')},
   { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom('Clipboard')},
   { key = '[', mods = SUPER, action = act.ActivateTabRelative(-1) },
   { key = ']', mods = SUPER, action = act.ActivateTabRelative(1) },
   { key = '[', mods = SUPER_REV, action = act.MoveTabRelative(-1) },
   { key = ']', mods = SUPER_REV, action = act.MoveTabRelative(1) },
   { key = 'n', mods = SUPER, action = act.SpawnWindow },
   { key = 'w', mods = SUPER, action = act.CloseCurrentPane({ confirm = false }) },
   { key = 'k', mods = SUPER_REV, action = act.ActivatePaneDirection('Up') },
   { key = 'j', mods = SUPER_REV, action = act.ActivatePaneDirection('Down') },
   { key = 'h', mods = SUPER_REV, action = act.ActivatePaneDirection('Left') },
   { key = 'l', mods = SUPER_REV, action = act.ActivatePaneDirection('Right') },
   {
       key = 'p',
       mods = SUPER_REV,
       action = act.PaneSelect({ alphabet = '1234567890', mode = 'SwapWithActiveKeepFocus' }),
   },
}

config.key_tables = {
    -- Defines the keys that are active in our resize-pane mode.
    -- Since we're likely to want to make multiple adjustments,
    -- we made the activation one_shot=false. We therefore need
    -- to define a key assignment for getting out of this mode.
    -- 'resize_pane' here corresponds to the name="resize_pane" in
    -- the key assignments above.
    resize_pane = {
        { key = 'LeftArrow', action = act.AdjustPaneSize { 'Left', 1 } },
        { key = 'h', action = act.AdjustPaneSize { 'Left', 1 } },

        { key = 'RightArrow', action = act.AdjustPaneSize { 'Right', 1 } },
        { key = 'l', action = act.AdjustPaneSize { 'Right', 1 } },

        { key = 'UpArrow', action = act.AdjustPaneSize { 'Up', 1 } },
        { key = 'k', action = act.AdjustPaneSize { 'Up', 1 } },

        { key = 'DownArrow', action = act.AdjustPaneSize { 'Down', 1 } },
        { key = 'j', action = act.AdjustPaneSize { 'Down', 1 } },

        -- Cancel the mode by pressing escape
        { key = 'Escape', action = 'PopKeyTable' },
    },

    -- Defines the keys that are active in our activate-pane mode.
    -- 'activate_pane' here corresponds to the name="activate_pane" in
    -- the key assignments above.
    activate_pane = {
        { key = 'LeftArrow', action = act.ActivatePaneDirection 'Left' },
        { key = 'h', action = act.ActivatePaneDirection 'Left' },

        { key = 'RightArrow', action = act.ActivatePaneDirection 'Right' },
        { key = 'l', action = act.ActivatePaneDirection 'Right' },

        { key = 'UpArrow', action = act.ActivatePaneDirection 'Up' },
        { key = 'k', action = act.ActivatePaneDirection 'Up' },

        { key = 'DownArrow', action = act.ActivatePaneDirection 'Down' },
        { key = 'j', action = act.ActivatePaneDirection 'Down' },
        { key = 'Escape', action = 'PopKeyTable'},
    },
}

config.mouse_bindings = {
    {
        event = { Down = { streak = 1, button = 'Right' } },
        mods = 'NONE',
        action = act.PasteFrom 'Clipboard',
    },

    -- Change the default click behavior so that it only selects
    -- text and doesn't open hyperlinks
    {
        event = { Up = { streak = 1, button = 'Left' } },
        mods = 'NONE',
        action = act.CompleteSelection 'ClipboardAndPrimarySelection',
    },
    -- NOTE that binding only the 'Up' event can give unexpected behaviors.
    -- Read more below on the gotcha of binding an 'Up' event only.
    {
        event = { Down = { streak = 1, button = { WheelUp = 1 } } },
        mods = 'CTRL',
        action = act.IncreaseFontSize,
    },

    -- Scrolling down while holding CTRL decreases the font size
    {
        event = { Down = { streak = 1, button = { WheelDown = 1 } } },
        mods = 'CTRL',
        action = act.DecreaseFontSize,
    },
    -- Bind 'Up' event of CTRL-Click to open hyperlinks
    {
        event = { Up = { streak = 1, button = 'Left' } },
        mods = 'CTRL',
        action = act.OpenLinkAtMouseCursor,
    },
    -- Disable the 'Down' event of CTRL-Click to avoid weird program behaviors
    {
        event = { Down = { streak = 1, button = 'Left' } },
        mods = 'CTRL',
        action = act.Nop,
    },
}

--- hyperlink
local function is_shell(foreground_process_name)
    local shell_names = { 'bash', 'zsh', 'fish', 'sh', 'ksh', 'dash' }
    local process = string.match(foreground_process_name, '[^/\\]+$')
        or foreground_process_name
    for _, shell in ipairs(shell_names) do
        if process == shell then
            return true
        end
    end
    return false
end

wezterm.on('open-uri', function(window, pane, uri)
               local editor = 'vim'
               if uri:find '^file:' == 1 and not pane:is_alt_screen_active() then
                   -- We're processing an hyperlink and the uri format should be: file://[HOSTNAME]/PATH[#linenr]
                   -- Also the pane is not in an alternate screen (an editor, less, etc)
                   local url = wezterm.url.parse(uri)
                   if is_shell(pane:get_foreground_process_name()) then
                       -- A shell has been detected. Wezterm can check the file type directly
                       -- figure out what kind of file we're dealing with
                       local success, stdout, _ = wezterm.run_child_process {
                           'file',
                           '--brief',
                           '--mime-type',
                           url.file_path,
                       }
                       if success then
                           if stdout:find 'directory' then
                               pane:send_text(
                                   wezterm.shell_join_args { 'cd', url.file_path } .. '\r'
                               )
                               pane:send_text(wezterm.shell_join_args {
                                                  'ls',
                                                  '-a',
                                                  '-p',
                                                  '--group-directories-first',
                                                                      } .. '\r')
                               return false
                           end

                           if stdout:find 'text' then
                               if url.fragment then
                                   pane:send_text(wezterm.shell_join_args {
                                                      editor,
                                                      '+' .. url.fragment,
                                                      url.file_path,
                                                                          } .. '\r')
                               else
                                   pane:send_text(
                                       wezterm.shell_join_args { editor, url.file_path } .. '\r'
                                   )
                               end
                               return false
                           end
                       end
                   else
                       -- No shell detected, we're probably connected with SSH, use fallback command
                       local edit_cmd = url.fragment
                           and editor .. ' +' .. url.fragment .. ' "$_f"'
                           or editor .. ' "$_f"'
                       local cmd = '_f="'
                           .. url.file_path
                           .. '"; { test -d "$_f" && { cd "$_f" ; ls -a -p --hyperlink --group-directories-first; }; } '
                           .. '|| { test "$(file --brief --mime-type "$_f" | cut -d/ -f1 || true)" = "text" && '
                           .. edit_cmd
                           .. '; }; echo'
                       pane:send_text(cmd .. '\r')
                       return false
                   end
               end

end)
config.hyperlink_rules = {
    {regex = '\\((\\w+://\\S+)\\)',format = '$1',highlight = 1,},
    {regex = '\\[(\\w+://\\S+)\\]',format = '$1',highlight = 1,},
    {regex = '\\{(\\w+://\\S+)\\}',format = '$1',highlight = 1,},
    {regex = '<(\\w+://\\S+)>',format = '$1',highlight = 1,},
    {regex = '\\b\\w+://\\S+[)/a-zA-Z0-9-]+',format = '$0',},
    {regex = '\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b',format = 'mailto:$0',},
}
return config
