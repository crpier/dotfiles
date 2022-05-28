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

-- Yank until end of line
keymap("n", "Y", "yg_", opts)

-- Don't keep { and } in jumplist
keymap("n", "{", ":keepjumps normal! {<CR>", opts)
keymap("n", "}", ":keepjumps normal! }<CR>", opts)

-- Toggle the quickfixlist
vim.keymap.set("n", "<C-Q>", require"user.functions".toggle_qf)

-- ISwap
vim.keymap.set("n", "ga", "<cmd>ISwap<CR>")
vim.keymap.set("n", "gw", "<cmd>ISwapWith<CR>")

-- DAP
keymap("n", "<F7>", ":lua require'dap'.step_into()<CR>", opts)
keymap("n", "<F8>", ":lua require'dap'.step_over()<CR>", opts)
keymap("n", "<F9>", ":lua require'dap'.step_out()<CR>", opts)

keymap("n", "g/", "<cmd>tab G<CR>", opts)

-- Insert --
-- Press kj fast to exit insert mode
keymap("i", "kj", "<ESC>", opts)
keymap("i", "kw", "<ESC>:w<CR>", opts)
keymap("i", "kx", "<ESC>:x<CR>", opts)

-- Visual --
keymap("v", "al", ":<C-U>normal 0v$h<CR>", opts)
keymap("v", "il", ":<C-U>normal ^vg_<CR>", opts)

-- Paste in v mode doesn't overwrite buffer
keymap("v", "p", '"_dP', opts)

-- Don't keep { and } in jumplist
keymap("x", "{", ":<C-U>keepjumps normal! gv{<CR>", opts)
keymap("x", "}", ":<C-U>keepjumps normal! gv}<CR>", opts)


-- Operator pending --
keymap("o", "al", ":normal val<CR>", opts)
keymap("o", "il", ":normal vil<CR>", opts)


-- Terminal --
-- Better terminal navigation
keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", term_opts)
keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", term_opts)
keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", term_opts)
keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", term_opts)

-- Custom
keymap("n", "<esc>", "<cmd>nohlsearch<cr>", opts)
keymap("n", "Q", "ZQ", opts)
-- keymap("n", "<F1>", ":e ~/Notes/<cr>", opts)
-- keymap("n", "<F3>", ":e .<cr>", opts)
-- keymap("n", "<F4>", "<cmd>Telescope resume<cr>", opts)
-- keymap("n", "<F5>", "<cmd>Telescope commands<CR>", opts)
-- keymap("n", "<F7>", "<cmd>TSHighlightCapturesUnderCursor<cr>", opts)
-- keymap("n", "<F8>", "<cmd>TSPlaygroundToggle<cr>", opts)
-- keymap("n", "<F11>", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
-- keymap("n", "<F12>", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
keymap("v", "//", [[y/\V<C-R>=escape(@",'/\')<CR><CR>]], opts)
keymap("n", "<C-s>", "<cmd>:w<cr>", opts)

keymap("n", "gx", [[:silent execute '!$BROWSER ' . shellescape(expand('<cfile>'), 1)<CR>]], opts)
