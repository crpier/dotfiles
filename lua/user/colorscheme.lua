vim.g.gruvbox_underline = false
local colorscheme = "gruvbox"
-- local colorscheme = "darkplus"

local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)

if colorscheme == "gruvbox" then
  vim.cmd "hi Normal guibg=none ctermbg=none"
  vim.g.transparent_background = true
end
if not status_ok then
  vim.notify("colorscheme " .. colorscheme .. " not found!")
  return
end
