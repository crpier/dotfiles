local opts = { noremap = true, silent = true }

local term_opts = { silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap

--Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Normal --
-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- Insert line without entering insert mode
keymap("n", "go", "o<Esc>", opts)
keymap("n", "gO", "O<Esc>", opts)

-- Clear search highlight
keymap("n", "<Esc>", "<CMD>nohlsearch<CR>", opts)

-- Yank until end of line
keymap("n", "Y", "yg_", opts)

-- Close vim with Q
keymap("n", "Q", "ZQ", opts)

-- Don't keep { and } in jumplist
keymap("n", "{", ":keepjumps normal! {<CR>", opts)
keymap("n", "}", ":keepjumps normal! }<CR>", opts)

-- DAP
keymap("n", "<F7>", ":lua require'dap'.step_into()<CR>", opts)
keymap("n", "<F8>", ":lua require'dap'.step_over()<CR>", opts)
keymap("n", "<F9>", ":lua require'dap'.step_out()<CR>", opts)

-- Toggle the quickfixlist
vim.keymap.set("n", "<C-Q>", require"user.util".toggle_qf)

-- Insert --
-- Press jk fast to enter
keymap("i", "kj", "<ESC>", opts)
keymap("i", "jw", "<ESC>:w<CR>", opts)
keymap("i", "jx", "<ESC>:x<CR>", opts)

-- Visual --
-- Don't overwrite register on paste
keymap("v", "p", '"_dP', opts)
keymap("v", "al", ":<C-U>normal 0v$h<CR>", opts)
keymap("v", "il", ":<C-U>normal ^vg_<CR>", opts)

-- Copy to clipboard on both local machine and server
keymap("v", "<leader>y", ":OSCYank<CR>", opts)

-- Don't keep { and } in jumplist
keymap("x", "{", ":<C-U>keepjumps normal! gv{<CR>", opts)
keymap("x", "}", ":<C-U>keepjumps normal! gv}<CR>", opts)

-- Visual block --

-- Operator pending --
keymap("o", "al", ":normal val<CR>", opts)
keymap("o", "il", ":normal vil<CR>", opts)

-- Terminal --
-- Better terminal navigation
keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", term_opts)
keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", term_opts)
keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", term_opts)
keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", term_opts)

