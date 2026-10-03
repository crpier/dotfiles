-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = "auto"

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Personal dual-monitor layout: native 2560x1440 at ~180 Hz, 125% scaling.
-- Positions use logical pixels: 2560 / 1.25 = 2048.
hl.monitor({ output = "DP-2", mode = "2560x1440@180.06", position = "0x0", scale = 1.25 })
hl.monitor({ output = "DP-3", mode = "2560x1440@180.06", position = "2048x0", scale = 1.25 })

-- Workspace placement follows the numpad columns: left column on DP-2,
-- middle/right columns on DP-3. Workspace 10 remains unassigned/dynamic.
for _, workspace in ipairs({ 1, 4, 7 }) do
  hl.workspace_rule({ workspace = tostring(workspace), monitor = "DP-2" })
end
for _, workspace in ipairs({ 2, 3, 5, 6, 8, 9 }) do
  hl.workspace_rule({ workspace = tostring(workspace), monitor = "DP-3" })
end

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
