lvim.builtin.autopairs.active = false
vim.opt.clipboard = ""
lvim.transparent_window = true
lvim.format_on_save = false
lvim.colorscheme = "gruvbox"
lvim.lsp.document_highlight = false
vim.cmd("set nocursorline")
lvim.builtin.dap.active = false

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

lvim.keys.visual_mode["il"] = "^og_"
lvim.keys.visual_mode["al"] = "0o$"
vim.api.nvim_set_keymap("o", "al", ":normal val<CR>", {})
vim.api.nvim_set_keymap("o", "il", ":normal vil<CR>", {})

lvim.keys.normal_mode["<esc>"] = "<cmd>nohlsearch<cr>"
lvim.keys.normal_mode["[b"] = "<cmd>BufferLineCyclePrev<CR>"
lvim.keys.normal_mode["]b"] = "<cmd>BufferLineCycleNext<CR>"
lvim.keys.normal_mode["L"] = "L"
lvim.keys.normal_mode["H"] = "H"
lvim.keys.normal_mode["gO"] = "O<esc>"
lvim.keys.normal_mode["go"] = "o<esc>"
lvim.keys.normal_mode["x"] = '"_x'
lvim.keys.normal_mode["X"] = '"_X'
lvim.keys.normal_mode["Q"] = "ZQ"
lvim.keys.normal_mode["gz"] = "<cmd>TZFocus<CR>"

lvim.keys.insert_mode["jw"] = "<ESC>:w<CR>"
lvim.keys.insert_mode["jx"] = "<ESC>:x<CR>"

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
	p = { "<cmd>Telescope projects<cr>", "Search projects" },
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

lvim.builtin.which_key.mappings.h = {
	name = "+Harpoon commands",
	m = { ':lua require("harpoon.mark").add_file()<CR>', "Mark file" },
	q = { ':lua require("harpoon.ui").toggle_quick_menu()<CR>', "Toggle quick menu" },
	h = { ':lua require("harpoon.ui").nav_file(1)<CR>', "Go to file 1" },
	j = { ':lua require("harpoon.ui").nav_file(2)<CR>', "Go to file 2" },
	k = { ':lua require("harpoon.ui").nav_file(3)<CR>', "Go to file 3" },
	l = { ':lua require("harpoon.ui").nav_file(4)<CR>', "Go to file 4" },
	t = { ':lua require("harpoon.term").gotoTerminal(1)<CR>', "Go to file 4" },
	n = { ':lua require("harpoon.ui").nav_next()<CR>', "Go to next mark" },
	p = { ':lua require("harpoon.ui").nav_prev()<CR>', "Go to previous mark" },
}

lvim.builtin.which_key.vmappings.z = {
	name = "+Zk commands",
	c = { ":'<,'>ZkNewFromContentSelection<cr>", "Create note with selected content" },
	t = { ":'<,'>ZkNewFromTitleSelection<cr>", "Create note with selected title" },
	s = { ":'<,'>ZkMatch<cr>", "Search notes that match selection" },
}
lvim.builtin.which_key.mappings.g.d = {
	"<cmd>DiffviewOpen<CR>",
	"Git diff",
}
lvim.builtin.which_key.mappings.g.t = {
	"<cmd>DiffviewOpen HEAD~1<CR>",
	"Git diff last commit",
}
lvim.builtin.which_key.mappings.g.D = {
	":DiffviewOpen ",
	"Git diff with user input",
}
lvim.builtin.which_key.mappings.g.f = {
	"<cmd>DiffviewFileHistory<CR>",
	"Git diff on a file",
}
lvim.builtin.which_key.mappings.g.e = {
	"<cmd>DiffviewClose<CR>",
	"Exit diffview",
}
lvim.builtin.which_key.mappings.g.a = {
	"<cmd>Gitsigns stage_buffer<CR>",
	"Git add file",
}
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.dashboard.active = false
lvim.builtin.alpha.active = false
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

lvim.plugins = {
	{ "rktjmp/lush.nvim" },
	{ "crpier/gruvbox.nvim" },
	{ "bkad/CamelCaseMotion" },
	{ "pearofducks/ansible-vim" },
	{ "tpope/vim-commentary" },
	{ "tpope/vim-surround" },
	{ "wellle/targets.vim" },
	{ "tpope/vim-unimpaired" },
	{ "tpope/vim-repeat" },
	{ "blankname/vim-fish" },
	{ "saltstack/salt-vim" },
	{
		"ThePrimeagen/harpoon",
		config = function()
			require("harpoon").setup()
		end,
	},
	{
		"ethanholz/nvim-lastplace",
		config = function()
			require("nvim-lastplace").setup({ lastplace_open_folds = true })
		end,
	},
	{ "mbbill/undotree" },
	{ "nvim-telescope/telescope-symbols.nvim" },
	{ "ojroques/vim-oscyank" },
	{ "sindrets/diffview.nvim" },
	{ "Pocco81/TrueZen.nvim" },
	{
		"ggandor/leap.nvim",
		config = function()
			require("leap").set_default_keymaps()
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		config = function()
			require("nvim-treesitter.configs").setup({
				textobjects = {
					select = {
						enable = true,

						-- Automatically jump forward to textobj, similar to targets.vim
						lookahead = true,

						keymaps = {
							-- You can use the capture groups defined in textobjects.scm
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							["ac"] = "@class.outer",
							["ic"] = "@class.inner",
						},
					},
				},
			})
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		config = function()
			require("indent_blankline").setup({
				-- for example, context is off by default, use this to turn it on
				show_current_context = true,
				show_trailing_blankline_indent = false,
			})
		end,
	},
	{
		"mickael-menu/zk-nvim",
		config = function()
			require("zk").setup({ picker = "telescope" })
		end,
	},
	-- Still undecided on neoscroll
	-- {
	-- 	"karb94/neoscroll.nvim",
	-- 	config = function()
	-- 		require("neoscroll").setup()
	-- 	end,
	-- },
}
