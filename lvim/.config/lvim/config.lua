--[[
lvim is the global options object

Linters should be
filled in as strings with either
a global executable or a path to
an executable
]]
-- THESE ARE EXAMPLE CONFIGS FEEL FREE TO CHANGE TO WHATEVER YOU WANT

-- general
lvim.builtin.bufferline.active = true
lvim.builtin.bufferline.config = {
	icons = "both",
}
vim.opt.clipboard = ""
lvim.transparent_window = true
lvim.log.level = "warn"
lvim.format_on_save = false
lvim.colorscheme = "gruvbox"
lvim.lsp.document_highlight = false
vim.cmd("set nocursorline")

lvim.builtin.dap.active = true
vim.opt.cmdheight = 1
vim.cmd("set background=dark")
vim.opt.scrolloff = 4
vim.opt.timeoutlen = 800
vim.opt.relativenumber = true
vim.opt.colorcolumn = "80"
vim.g.camelcasemotion_key = "\\"
lvim.builtin.telescope.defaults.path_display = {}

-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = "space"
-- add your own keymapping

lvim.keys.visual_mode["<leader>y"] = ":OSCYank<CR>"

lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
lvim.keys.normal_mode["<esc>"] = "<cmd>nohlsearch<cr>"
-- cancel Q key
lvim.keys.normal_mode["Q"] = "<nop>"
lvim.keys.normal_mode["[b"] = ":BufferPrevious<CR>"
lvim.keys.normal_mode["]b"] = ":BufferNext<CR>"
lvim.keys.normal_mode["gO"] = "O<esc>"
lvim.keys.normal_mode["go"] = "o<esc>"
-- blackhole x and X commands
lvim.keys.normal_mode["x"] = '"_x'
lvim.keys.normal_mode["X"] = '"_X'

lvim.keys.insert_mode.jw = "<ESC>:w<CR>"
lvim.keys.insert_mode.jx = "<ESC>:x<CR>"
-- unset lunarvim defaults
lvim.keys.insert_mode.kj = "kj"
-- unmap a default keymapping
-- lvim.keys.normal_mode["<C-Up>"] = ""
-- edit a default keymapping
-- lvim.keys.normal_mode["<C-q>"] = ":q<cr>"

-- Change Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
-- lvim.builtin.telescope.on_config_done = function()
--   local actions = require "telescope.actions"
--   -- for input mode
--   lvim.builtin.telescope.defaults.mappings.i["<C-j>"] = actions.move_selection_next
--   lvim.builtin.telescope.defaults.mappings.i["<C-k>"] = actions.move_selection_previous
--   lvim.builtin.telescope.defaults.mappings.i["<C-n>"] = actions.cycle_history_next
--   lvim.builtin.telescope.defaults.mappings.i["<C-p>"] = actions.cycle_history_prev
--   -- for normal mode
--   lvim.builtin.telescope.defaults.mappings.n["<C-j>"] = actions.move_selection_next
--   lvim.builtin.telescope.defaults.mappings.n["<C-k>"] = actions.move_selection_previous
-- end

-- Use which-key to add extra bindings with the leader-key prefix
-- lvim.builtin.which_key.mappings["P"] = { "<cmd>Telescope projects<CR>", "Projects" }
-- lvim.builtin.which_key.mappings["t"] = {
--   name = "+Trouble",
--   r = { "<cmd>Trouble lsp_references<cr>", "References" },
--   f = { "<cmd>Trouble lsp_definitions<cr>", "Definitions" },
--   d = { "<cmd>Trouble lsp_document_diagnostics<cr>", "Diagnostics" },
--   q = { "<cmd>Trouble quickfix<cr>", "QuickFix" },
--   l = { "<cmd>Trouble loclist<cr>", "LocationList" },
--   w = { "<cmd>Trouble lsp_workspace_diagnostics<cr>", "Diagnostics" },
-- }
-- Telescope commands
lvim.builtin.which_key.mappings.m = {
	name = "+custoM telescope",
	b = { "<cmd>Telescope buffers<cr>", "Search buffers' titles" },
	d = { "<cmd>Telescope lsp_document_diagnostics<cr>", "Search diagnostics" },
	f = { "<cmd>Telescope git_files<cr>", "Search diagnostics" },
	h = { "<cmd>Telescope command_history<cr>", "Search command history" },
	j = { "<cmd>Telescope jumplist<cr>", "Search jumplist" },
	l = { "<cmd>Telescope lsp_document_symbols<cr>", "Search symbols" },
	m = { "<cmd>Telescope symbols<cr>", "Search emojis (or other unicode whatev)" },
	q = { "<cmd>Telescope quickfix<cr>", "Search Quickfix list" },
	s = {
		"<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.input('Grep For > ')})<cr>",
		"Search string",
	},
	w = { "<cmd>lua require('telescope.builtin').grep_string()<cr>", "Search this word" },
	z = { "<cmd>Telescope current_buffer_fuzzy_find<cr>", "Search symbols" },
}

lvim.builtin.which_key.mappings.z = {
	name = "+Zk commands",
	d = { "<cmd>ZkNew { dir = 'daybook' }<cr>", "Creates a daybook entry" },
	n = { "<cmd>ZkNew<cr>", "Creates a new ZK note" },
	i = { "<cmd>ZkIndex<cr>", "Index the ZK notebook" },
	s = { "<cmd>ZkNotes<cr>", "Open notes in telescope" },
	b = { "<cmd>ZkBacklinks<cr>", "Search links to this note" },
	l = { "<cmd>ZkLinks<cr>", "Search links in this note" },
	t = { "<cmd>ZkTags<cr>", "Search notes by tags" },
}

lvim.builtin.which_key.vmappings.z = {
	name = "+Zk commands",
	c = { ":'<,'>ZkNewFromContentSelection<cr>", "Create note with selected content" },
	t = { ":'<,'>ZkNewFromTitleSelection<cr>", "Create note with selected title" },
	s = { ":'<,'>ZkMatch<cr>", "Search notes that match selection" },
}
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.dashboard.active = false
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.show_icons.git = 0

-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.ensure_installed = {
	"bash",
	"c",
	"javascript",
	"json",
	"lua",
	"python",
	"typescript",
	"css",
	"rust",
	"java",
	"yaml",
}

lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enabled = true

local formatters = require("lvim.lsp.null-ls.formatters")
formatters.setup({
	{ exe = "black" },
	{ exe = "stylua" },
})

local linters = require("lvim.lsp.null-ls.linters")
linters.setup({
	{ exe = "luacheck", args = { "-g" } },
})
-- Additional Plugins
-- lvim.plugins = {
--     {"folke/tokyonight.nvim"},
--     {
--       "folke/trouble.nvim",
--       cmd = "TroubleToggle",
--     },
-- }
lvim.plugins = {
	{ "rktjmp/lush.nvim" },
	{ "ellisonleao/gruvbox.nvim" },
	{ "bkad/CamelCaseMotion" },
	{ "pearofducks/ansible-vim" },
	{ "tpope/vim-commentary" },
	{ "tpope/vim-fugitive" },
	{ "tpope/vim-surround" },
	{ "wellle/targets.vim" },
	{ "tpope/vim-unimpaired" },
	{ "tpope/vim-repeat" },
	{ "blankname/vim-fish" },
	{ "saltstack/salt-vim" },
	{ "mfussenegger/nvim-dap-python" },
	{ "farmergreg/vim-lastplace" },
	{ "mbbill/undotree" },
	{ "nvim-telescope/telescope-symbols.nvim" },
	{ "ojroques/vim-oscyank" },
	{ "sindrets/diffview.nvim" },
	{
		"mickael-menu/zk-nvim",
		config = function()
			require("zk").setup({ picker = "telescope" })
		end,
	},
}

-- Autocommands (https://neovim.io/doc/user/autocmd.html)
-- lvim.autocommands.custom_groups = {
--   { "BufWinEnter", "*.lua", "setlocal ts=8 sw=8" },
-- }
