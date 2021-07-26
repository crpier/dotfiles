lvim.transparent_window = true
lvim.format_on_save = false
lvim.lint_on_save = false
lvim.colorscheme = "gruvbox"
-- keymappings
lvim.leader = "space"
-- overwrite the key-mappings provided by LunarVim for any mode, or leave it empty to keep them
lvim.keys.normal_mode = {
    {'<esc>', '<cmd>nohlsearch<cr>'},
    {'N', 'Nzz'},
    {'Q', '<nop>'},
    {'[b', ':BufferPrevious<CR>'},
    {']b', ':BufferNext<CR>'},
    {'gO', 'O<esc>'},
    {'go', 'o<esc>'},
    {'n', 'nzz'},
    {'x', '"_x'},
    {'X', '"_X'},
    {'cp', '<cmd>let @p=@""<CR>'},
    {'<leader>y', '"+y'},
    {'<leader>Y', '"+yg_'},
    {'<leader>z', '<cmd>MaximizerToggle!<CR>'},
}
require("lv-utils").add_keymap_insert_mode({ silent = true }, {
    { "jw", "<esc>:w<cr>" },
    { "jq", "<esc>ZZ" },
})

lvim.builtin.dashboard.active = false
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.side = "left"
lvim.builtin.nvimtree.show_icons.git = 0
lvim.builtin.nvimtree.auto_open = false

-- if you don't want all the parsers change this to a table of the ones you want
-- lvim.treesitter.ensure_installed = "maintained"
-- lvim.treesitter.ignore_install = { "haskell" }
-- lvim.treesitter.highlight.enabled = true
lvim.builtin.treesitter.document_highlight = false

-- generic LSP settings
-- you can set a custom on_attach function that will be used for all the language servers
-- See <https://github.com/neovim/nvim-lspconfig#keybindings-and-completion>
-- lvim.lsp.on_attach_callback = function(client, bufnr)
--   local function buf_set_option(...)
--     vim.api.nvim_buf_set_option(bufnr, ...)
--   end
--   --Enable completion triggered by <c-x><c-o>
--   buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")
-- end

-- python

-- Additional Plugins
lvim.plugins = {
  {'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
  {"folke/tokyonight.nvim"},
  {'christianchiarulli/nvcode-color-schemes.vim'},
  {'bkad/CamelCaseMotion'},
  {'pearofducks/ansible-vim'},
  {'szw/vim-maximizer'},
  {'tpope/vim-commentary'},
  {'tpope/vim-fugitive'},
  {'tpope/vim-surround'},
  {'wellle/targets.vim'},
  {'tpope/vim-unimpaired'},
  {'tpope/vim-repeat'},
  {'blankname/vim-fish'},
  {'saltstack/salt-vim'},
  {'mfussenegger/nvim-dap-python'},
  {'farmergreg/vim-lastplace'},
  {'nvim-treesitter/playground'},
}

-- Autocommands (https://neovim.io/doc/user/autocmd.html)
-- lvim.autocommands = {{ "BufWinEnter", "*", "echo \"hi again\""}}

-- Additional Leader bindings for WhichKey
-- lvim.builtin.which_key.mappings.f = { "<cmd>Telescope find_files find_command=rg,--ignore,--hidden,--files,--iglob,!.git<CR>", "Find files" }
lvim.builtin.which_key.mappings.m = {
    name = "+custoM telescope",
    b = { "<cmd>Telescope buffers<cr>", "Search buffers' titles" },
    d = { "<cmd>Telescope lsp_document_diagnostics<cr>", "Search diagnostics" },
    f = { "<cmd>Telescope git_files<cr>", "Search diagnostics" },
    h = { "<cmd>Telescope command_history<cr>", "Search command history" },
    j = { "<cmd>Telescope jumplist<cr>", "Search jumplist" },
    l = { "<cmd>Telescope lsp_document_symbols<cr>", "Search symbols" },
    q = { "<cmd>Telescope quickfix<cr>", "Search Quickfix list" },
    s = {
      "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.input('Grep For > ')})<cr>",
      "Search string",
    },
    w = { "<cmd>lua require('telescope.builtin').grep_string()<cr>", "Search this word" },
    z = { "<cmd>Telescope current_buffer_fuzzy_find<cr>", "Search symbols" },
  }

vim.cmd("set nocursorline")
-- TODO fix these again
vim.api.nvim_set_keymap('o', 'al', ':normal v0o$h<CR>', {})
vim.api.nvim_set_keymap('o', 'il', ':normal v^og_<CR>', {})

lvim.builtin.dap.active = true
lvim.builtin.telescope.defaults.find_command = {"rg","--ignore","--hidden","--files","--iglob","!.git"}
lvim.builtin.telescope.extensions = {
  fzf = {
    fuzzy = true,                    -- false will only do exact matching
    override_generic_sorter = true, -- override the generic sorter
    override_file_sorter = true,     -- override the file sorter
    case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
    -- the default case_mode is "smart_case"
  }
}

lvim.builtin.telescope.on_config_done = function()
  require('telescope').load_extension('fzf')
end

lvim.lsp.document_highlight = false

lvim.lang.python.formatter.exe = "black"
lvim.lang.python.linters = "flake8"
lvim.lsp.diagnostics.virtual_text = true
lvim.lang.lua.formatter.exe = "stylua"
vim.opt.cmdheight = 1
vim.cmd("set background=dark")
vim.opt.scrolloff = 4
vim.opt.timeoutlen = 800
vim.opt.relativenumber = true
vim.opt.colorcolumn = "80"
lvim.lang.vim.lsp.active = false
