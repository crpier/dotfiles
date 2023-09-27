-- line numbers
vim.wo.relativenumber = true
vim.wo.number = true
-- Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true
-- always yank into clipboard
vim.o.clipboard = "unnamedplus"
-- show true colors
vim.o.termguicolors = true


-- easy exit
vim.keymap.set("n", "Q", "ZQ")
-- Don't highlight search
vim.keymap.set("n", "<Esc>", function()
  vim.cmd [[ nohlsearch ]]
end)
-- Search the selected text
vim.keymap.set("v", "//", [[y/\V<C-R>=escape(@",'/\')<CR><CR>]])
-- Motions for selecting lines
vim.keymap.set("o", "al", ":normal val<CR>")
vim.keymap.set("o", "il", ":normal vil<CR>")
-- Select in/outside the line
vim.keymap.set("v", "al", ":<C-U>normal 0v$h<CR>")
vim.keymap.set("v", "il", ":<C-U>normal ^vg_<CR>")

-- highlight on yank
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = "*",
})

