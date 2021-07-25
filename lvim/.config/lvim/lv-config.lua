--[[
O is the global options object

Linters should be
filled in as strings with either
a global executable or a path to
an executable
]]
-- THESE ARE EXAMPLE CONFIGS FEEL FREE TO CHANGE TO WHATEVER YOU WANT

-- general

-- TODO reorder and regroup
vim.g.camelcasemotion_key = '\\'
-- lvim.plugin.dap.active = true
-- lvim.default_options.colorcolumn = "80"
-- lvim.default_options.clipboard = ""
lvim.lsp.document_highlight = false
-- lvim.default_options.cursorline = false
lvim.format_on_save = false
lvim.background = "dark"
lvim.lint_on_save = false
lvim.completion.autocomplete = true
-- lvim.default_options.relativenumber = true
lvim.colorscheme = "gruvbox"
lvim.transparent_window = true
-- lvim.default_options.wrap = true
-- lvim.default_options.timeoutlen = 800
-- keymappings
lvim.keys.leader_key = "space"
-- overwrite the key-mappings provided by LunarVim for any mode, or leave it empty to keep them
lvim.keys.normal_mode = {
  -- Navigate buffers
  -- TODO: leader mappings should go to which_key
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
-- lvim.plugin.dashboard.active = false
-- lvim.plugin.terminal.active = true
-- lvim.plugin.zen.active = false
-- lvim.plugin.zen.window.height = 0.90
-- lvim.plugin.nvimtree.side = "left"
-- lvim.plugin.nvimtree.show_icons.git = 0
-- lvim.plugin.nvimtree.auto_close_tree = 1
-- lvim.plugin.nvimtree.auto_open = false

-- if you don't want all the parsers change this to a table of the ones you want
-- lvim.treesitter.ensure_installed = "maintained"
-- lvim.treesitter.ignore_install = { "haskell" }
-- lvim.treesitter.highlight.enabled = true

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
-- lvim.lang.python.diagnostics.virtual_text = true
lvim.lang.python.analysis.use_library_code_types = true
-- To change default formatter from yapf to black
lvim.lang.python.formatter.exe = "black"
lvim.lang.python.formatter.args = {"-"}
lvim.lang.python.isort = true
-- To change enabled linters
-- https://github.com/mfussenegger/nvim-lint#available-linters
-- lvim.lang.python.linters = { "flake8", "pylint", "mypy", ... }

-- go
-- To change default formatter from gofmt to goimports
lvim.lang.go.formatter.exe = "goimports"

-- javascript
lvim.lang.tsserver.linter = nil

-- rust
-- lvim.lang.rust.rust_tools = true
-- lvim.lang.rust.formatter = {
--   exe = "rustfmt",
--   args = {"--emit=stdout", "--edition=2018"},
-- }

-- scala
-- lvim.lang.scala.metals.active = true
-- lvim.lang.scala.metals.server_version = "0.10.5",

--LaTeX
-- Options: https://github.com/latex-lsp/texlab/blob/master/docs/options.md
lvim.lang.latex.active = true
lvim.lang.latex.aux_directory = "."
lvim.lang.latex.bibtex_formatter = "texlab"
lvim.lang.latex.build.args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" }
lvim.lang.latex.build.executable = "latexmk"
lvim.lang.latex.build.forward_search_after = false
lvim.lang.latex.build.on_save = false
lvim.lang.latex.chktex.on_edit = false
lvim.lang.latex.chktex.on_open_and_save = false
lvim.lang.latex.diagnostics_delay = 300
lvim.lang.latex.formatter_line_length = 80
lvim.lang.latex.forward_search.executable = "zathura"
lvim.lang.latex.latex_formatter = "latexindent"
lvim.lang.latex.latexindent.modify_line_breaks = false
-- lvim.lang.latex.auto_save = false
-- lvim.lang.latex.ignore_errors = { }

-- Additional Plugins
lvim.user_plugins = {
  {'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
  {"folke/tokyonight.nvim"},
  {'morhetz/gruvbox'},
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
}

-- TODO there must be a way to put this inside the plugin config using packer
require('dap-python').setup('/usr/bin/python')
-- TODO the above + ask about this
require('telescope').setup {
  extensions = {
    fzf = {
      fuzzy = true,                    -- false will only do exact matching
      override_generic_sorter = true, -- override the generic sorter
      override_file_sorter = true,     -- override the file sorter
      case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
                                       -- the default case_mode is "smart_case"
    }
  }
}
-- To get fzf loaded and working with telescope, you need to call
-- load_extension, somewhere after setup function:
require('telescope').load_extension('fzf')


lvim.user_which_key = {
	f = { "<cmd>Telescope find_files find_command=rg,--ignore,--hidden,--files,--iglob,!.git<CR>", "Find files" },
	m = {
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
	},
}
