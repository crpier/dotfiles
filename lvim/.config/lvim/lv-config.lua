--[[
O is the global options object

Linters should be
filled in as strings with either
a global executable or a path to
an executable
]]
-- THESE ARE EXAMPLE CONFIGS FEEL FREE TO CHANGE TO WHATEVER YOU WANT

-- general

O.plugin.dap.active = true
O.default_options.clipboard = ""
O.lsp.document_highlight = false
O.default_options.cursorline = false
O.format_on_save = false
O.background = "dark"
O.lint_on_save = false
O.completion.autocomplete = true
O.default_options.relativenumber = true
O.colorscheme = "gruvbox"
O.transparent_window = true
O.default_options.wrap = true
O.default_options.timeoutlen = 800
-- keymappings
O.keys.leader_key = "space"
-- overwrite the key-mappings provided by LunarVim for any mode, or leave it empty to keep them
O.keys.normal_mode = {
  -- Navigate buffers
  {']b', ':bnext<CR>'},
  {'[b', ':bprevious<CR>'},
  {'n', 'nzz'},
  {'N', 'Nzz'},
  {'go', 'o<esc>'},
  {'gO', 'O<esc>'},
  {'<leader>y', '"+y'},
  {'<leader>Y', '"+yg_'},
  {'Q', '<nop>'},
  {'<esc>', '<cmd>nohlsearch<cr>'}
}
-- TODO figure out why these don't work and fix them (or PR)
-- vim.api.nvim_set_keymap('v', 'al', ':normal 0o$h', {})
-- vim.api.nvim_set_keymap('v', 'il', ':normal ^og_', {})
vim.api.nvim_set_keymap('o', 'al', ':normal v0o$h<CR>', {})
vim.api.nvim_set_keymap('o', 'il', ':normal v^og_<CR>', {})
-- if you just want to augment the existing ones then use the utility function
require("lv-utils").add_keymap_insert_mode({ silent = true }, {
{ "jw", "<esc>:w<cr>" },
{ "jq", "<esc>ZZ" },
})
-- you can also use the native vim way directly
-- vim.api.nvim_set_keymap("i", "<C-Space>", "compe#complete()", { noremap = true, silent = true, expr = true })

-- TODO: User Config for predefined plugins
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
O.plugin.dashboard.active = false
O.plugin.terminal.active = true
O.plugin.zen.active = false
O.plugin.zen.window.height = 0.90
O.plugin.nvimtree.side = "left"
O.plugin.nvimtree.show_icons.git = 0
O.plugin.nvimtree.auto_close_tree = 1

-- if you don't want all the parsers change this to a table of the ones you want
O.treesitter.ensure_installed = "maintained"
O.treesitter.ignore_install = { "haskell" }
O.treesitter.highlight.enabled = true

-- generic LSP settings
-- you can set a custom on_attach function that will be used for all the language servers
-- See <https://github.com/neovim/nvim-lspconfig#keybindings-and-completion>
-- O.lsp.on_attach_callback = function(client, bufnr)
--   local function buf_set_option(...)
--     vim.api.nvim_buf_set_option(bufnr, ...)
--   end
--   --Enable completion triggered by <c-x><c-o>
--   buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")
-- end

-- python
O.lang.python.diagnostics.virtual_text = true
O.lang.python.analysis.use_library_code_types = true
-- To change default formatter from yapf to black
O.lang.python.formatter.exe = "black"
O.lang.python.formatter.args = {"-"}
O.lang.python.isort = true
-- To change enabled linters
-- https://github.com/mfussenegger/nvim-lint#available-linters
-- O.lang.python.linters = { "flake8", "pylint", "mypy", ... }

-- go
-- To change default formatter from gofmt to goimports
O.lang.go.formatter.exe = "goimports"

-- javascript
O.lang.tsserver.linter = nil

-- rust
-- O.lang.rust.rust_tools = true
-- O.lang.rust.formatter = {
--   exe = "rustfmt",
--   args = {"--emit=stdout", "--edition=2018"},
-- }

-- scala
-- O.lang.scala.metals.active = true
-- O.lang.scala.metals.server_version = "0.10.5",

--LaTeX
-- Options: https://github.com/latex-lsp/texlab/blob/master/docs/options.md
O.lang.latex.active = true
O.lang.latex.aux_directory = "."
O.lang.latex.bibtex_formatter = "texlab"
O.lang.latex.build.args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" }
O.lang.latex.build.executable = "latexmk"
O.lang.latex.build.forward_search_after = false
O.lang.latex.build.on_save = false
O.lang.latex.chktex.on_edit = false
O.lang.latex.chktex.on_open_and_save = false
O.lang.latex.diagnostics_delay = 300
O.lang.latex.formatter_line_length = 80
O.lang.latex.forward_search.executable = "zathura"
O.lang.latex.latex_formatter = "latexindent"
O.lang.latex.latexindent.modify_line_breaks = false
-- O.lang.latex.auto_save = false
-- O.lang.latex.ignore_errors = { }

-- Additional Plugins
O.user_plugins = {
    {"folke/tokyonight.nvim"},
    {'morhetz/gruvbox'},
    {'tpope/vim-sensible'},
    {'bkad/CamelCaseMotion'},
    {'pearofducks/ansible-vim'},
    {'szw/vim-maximizer'},
    {'tpope/vim-commentary'},
    {'tpope/vim-surround'},
    {'wellle/targets.vim'},
    {'tpope/vim-unimpaired'},
    {'tpope/vim-repeat'},
    {'dag/vim-fish'},
    {'saltstack/salt-vim'}
}

-- Autocommands (https://neovim.io/doc/user/autocmd.html)
O.user_which_key = {
  m = {
    name = "+custoM telescope",
    b = { "<cmd>Telescope buffers<cr>", "Search in buffers" },
    d = { "<cmd>Telescope lsp_document_diagnostics<cr>", "Search diagnostics" },
    h = { "<cmd>Telescope command_history<cr>", "Search command history" },
    j = { "<cmd>Telescope jumplist<cr>", "Search jumplist" },
    q = { "<cmd>Telescope quickfix<cr>", "Search Quickfix list" },
    l = { "<cmd>Telescope lsp_document_symbols<cr>", "Search symbols" },
    s = { "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.input('Grep For > ')})<cr>", "Search string" },
    w = { "<cmd>lua require('telescope.builtin').grep_string()<cr>", "Search this word" },
  },
}
