-- Change the default Omarchy look'n'feel.

-- Restore Big Picture fullscreen when returning from a game. A startup-only
-- fullscreen/suppress_event rule did not prevent Steam's post-game resize.
-- Defer until the event finishes, and only touch the focused Big Picture window
-- so a background Steam window cannot take fullscreen away from a game.
local function restore_big_picture(w)
  if not w or w.class ~= "steam" or w.title ~= "Steam Big Picture Mode" then
    return
  end

  local address = w.address
  hl.timer(function()
    local current = hl.get_window("address:" .. address)
    if current and current.mapped and current.active
        and current.class == "steam" and current.title == "Steam Big Picture Mode"
        and current.fullscreen ~= 2 then
      hl.dispatch(hl.dsp.window.fullscreen({
        window = "address:" .. address,
        action = "set",
        mode = "fullscreen",
      }))
    end
  end, { timeout = 100, type = "oneshot" })
end

hl.on("window.active", restore_big_picture)
hl.on("window.fullscreen", restore_big_picture)
hl.on("window.title", restore_big_picture)
hl.on("window.open", restore_big_picture)
restore_big_picture(hl.get_active_window())

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })

-- Opt another application in to Omarchy's standard transparency.
-- Find its class with: hyprctl clients
-- o.transparent_window("my-app")
-- o.transparent_window("my-app", "0.9 0.85") -- Custom active/inactive opacity.
