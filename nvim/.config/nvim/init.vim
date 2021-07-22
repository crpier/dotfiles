call plug#begin('~/.local/share/nvim/plugged')
" Looks good
Plug 'morhetz/gruvbox'
" improved motion
Plug 'bkad/CamelCaseMotion'
" Maximize one split
Plug 'szw/vim-maximizer', { 'on': 'MaximizerToggle' }
" Easy commenting
Plug 'tpope/vim-commentary'
" manage surrounding characters
Plug 'tpope/vim-surround'
" Sensible defaults
Plug 'tpope/vim-sensible'
" Add additional text objects
Plug 'wellle/targets.vim'
" Useful shortcuts, mostly using the square brackets
Plug 'tpope/vim-unimpaired'
" Repeat commands from plugins using period (.)
Plug 'tpope/vim-repeat'
" Fish syntax highlighting
Plug 'dag/vim-fish'
" Show me what I yanked lol
Plug 'machakann/vim-highlightedyank'
" Telescope, that'all
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-lua/popup.nvim'
" Dependency for telescope and other nvim plugins
Plug 'nvim-lua/plenary.nvim'
" Native fzf for telescope
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
" Nice icons for telescope
Plug 'kyazdani42/nvim-web-devicons'
" Tree finder
Plug 'kyazdani42/nvim-tree.lua', { 'on': 'NvimTreeToggle' }
" I don't really use these that often....maybe remove? ¯\_(ツ)_/¯
" git plugins
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-rhubarb'
" Completion plugin
Plug 'hrsh7th/nvim-compe'
" Snippets, nice
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
" Syntax highlighting using language parsing
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate' }
" language Symbols tree-viewer
Plug 'simrat39/symbols-outline.nvim'
" TODO I don't really use this that often...maybe remove it?
" Haha Ansible go brr
Plug 'pearofducks/ansible-vim', { 'do': './UltiSnips/generate.sh' }
" Go
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries'}
Plug 'saltstack/salt-vim'
Plug 'mfussenegger/nvim-dap'
Plug 'mfussenegger/nvim-dap-python'
call plug#end()

""""""""""""""""""""""""""""""General Options""""""""""""""""""""""""""""""

""""" Set general options
let mapleader = " "
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
" show current line number and relative line number
set number relativenumber
" keep buffers open in the background even when not saved
set hidden
set noerrorbells
" when searching, if there are no uppercases, then search is case insensitive
set ignorecase
set smartcase
" move cursor to search result while typing
set incsearch
set hlsearch
" keep 4 lines above and below the cursor at all times
set scrolloff=4
" show the preferred limit to line length
set colorcolumn=80
" refresh the file if it was edited outside vim
set autoread
" load filetype, even when a plugin provides definitins
filetype plugin on
" Open splits from either right or bottom (instead of left or up)
set splitbelow
set splitright
" allow using mouse
set mouse=a
" nice autocomplete
set completeopt=menuone,noinsert,noselect
set updatetime=300
" keeps history over sessions
set noswapfile
set nobackup
set undofile
" where to store undo data. It is guaranteed that ~/.local/share/nvim exists
set undodir=~/.local/share/nvim/undodir
" This is because vim-fish wants / to be part of a word, and I don't 

""""""""""""""""""""""""""""""Plugin settings""""""""""""""""""""""""""""""
" maximizer plugin
nnoremap <leader>m :MaximizerToggle!<CR>
let g:camelcasemotion_key = '\'
"""""""""""" nvimtree
nnoremap <leader>e <cmd>NvimTreeToggle<CR>

"""""""""""" Symbols-outline
lua <<EOF
local opts = {
-- whether to highlight the currently hovered symbol
highlight_hovered_item = true,
-- whether to show outline guides
show_guides = true,
}
require('symbols-outline').setup(opts)
EOF
"""""""""""" Treesitter
lua <<EOF
require'nvim-treesitter.configs'.setup {
incremental_selection = {
enable = true,
keymaps = {
  --  Keymaps for language incremental selection lol
  init_selection = "gs",
  node_incremental = "gi",
  node_decremental = "gd",
  },
},
highlight = {
enable = true,
},
  indentation = {
  enable = true,
  },
folding = {
enable = true,
},
}
EOF
"""""""""""" Fugitive
nnoremap <leader>gi :Git
nnoremap <leader>gb :Git blame<CR>
nnoremap <leader>gd :Gdiffsplit<CR>
nnoremap <leader>gpl :Git pull<CR>
nnoremap <leader>gps :Git push<CR>
""""""""""""  Telescope
lua << EOF
local actions = require('telescope.actions')
require('telescope').setup {
defaults = {
prompt_prefix = '⟩ ',
color_devicons = true,
file_previewer   = require('telescope.previewers').vim_buffer_cat.new,
grep_previewer   = require('telescope.previewers').vim_buffer_vimgrep.new,
qflist_previewer = require('telescope.previewers').vim_buffer_qflist.new,
mappings = {
i = {
["<C-q>"] = actions.send_to_qflist,
},
}
    },
  extensions = {
  --  The fzf extension allows using fzf syntax when filtering files
  fzf = {
  override_generic_sorter = true, -- override the generic sorter
  override_file_sorter = true,     -- override the file sorter
  case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
  }
}
}
require('telescope').load_extension('fzf')
EOF
"""""""""""" Telescope bindings, TODO add more bindings here brr
nnoremap <leader>ff :lua require('telescope.builtin').git_files()<CR>
nnoremap <leader>fi :lua require('telescope.builtin').find_files()<CR>
nnoremap <leader>bu :lua require('telescope.builtin').buffers()<CR>
nnoremap <leader>bl :lua require('telescope.builtin').current_buffer_fuzzy_find()<CR>
nnoremap <leader>st :lua require('telescope.builtin').treesitter()<CR>
nnoremap <leader>rs :lua require('telescope.builtin').grep_string({ search = vim.fn.input("Grep For > ")})<CR>
nnoremap <leader>rw :lua require('telescope.builtin').grep_string { search = vim.fn.expand("<cword>") }<CR>
"""""""""""" compe
let g:completion_matching_strategy_list = ['exact', 'substring', 'fuzzy']
let g:compe = {}
let g:compe.enabled = v:true
let g:compe.autocomplete = v:true
let g:compe.debug = v:false
let g:compe.min_length = 1
let g:compe.preselect = 'enable'
let g:compe.throttle_time = 80
let g:compe.source_timeout = 200
let g:compe.incomplete_delay = 400
let g:compe.max_abbr_width = 100
let g:compe.max_kind_width = 100
let g:compe.max_menu_width = 100
let g:compe.documentation = v:true
let g:compe.source = {}
let g:compe.source.path = v:true
let g:compe.source.buffer = v:true
let g:compe.source.calc = v:true
let g:compe.source.vsnip = v:false
let g:compe.source.nvim_lua = v:true
let g:compe.source.spell = v:false
let g:compe.source.tags = v:false
let g:compe.source.snippets_nvim = v:false
let g:compe.source.treesitter = v:true
let g:compe.source.omni = v:false
let g:compe.source.ultisnips = v:true
inoremap <silent><expr> <C-Space> compe#complete()
inoremap <silent><expr> <CR>      compe#confirm('<CR>')
inoremap <silent><expr> <C-e>     compe#close('<C-e>')
"""""""""""" Ultisnips bindings
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"
" If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit="vertical"
"""""""""""" nvim-dap
lua require('dap-python').setup('python')
" these are examples from the docs and I don't like them, they need to be 
" updated to be like the lunarvim defaults
nnoremap <silent> <F5> :lua require'dap'.continue()<CR>
nnoremap <silent> <F10> :lua require'dap'.step_over()<CR>
nnoremap <silent> <F11> :lua require'dap'.step_into()<CR>
nnoremap <silent> <F12> :lua require'dap'.step_out()<CR>
nnoremap <silent> <leader>b :lua require'dap'.toggle_breakpoint()<CR>
nnoremap <silent> <leader>B :lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>
nnoremap <silent> <leader>lp :lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>
nnoremap <silent> <leader>dr :lua require'dap'.repl.open()<CR>
nnoremap <silent> <leader>dl :lua require'dap'.run_last()<CR>


""""""""""""""""""""""""""""""Theme"""""""""""""""""""""""""""""""""""""""""
colorscheme gruvbox
set background=dark
" Transparent background
hi Normal guibg=NONE ctermbg=NONE
" Duration of yank highlight
let g:highlightedyank_highlight_duration = 200

""""""""""""""""""""""""""""""General Remaps""""""""""""""""""""""""""""""""
" easy source vimrc
nnoremap <leader><CR> :so ~/.config/nvim/init.vim<CR>
" I don't use EX mode, and I keep pressing it by mistake when I want to quit
nnoremap Q ZQ
" Search for selected text using '//'
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>
" Copy to clipboard
vnoremap  <leader>y  "+y
nnoremap  <leader>Y  "+yg_
nnoremap  <leader>y  "+y
nnoremap  <leader>yy  "+yy
" Paste from clipboard
nnoremap <leader>p "+p
nnoremap <leader>P "+P
vnoremap <leader>p "+p
vnoremap <leader>P "+P
" select text inside line without spaces
vnoremap al :<C-U>normal 0v$h<CR>
omap al :normal val<CR>
vnoremap il :<C-U>normal ^vg_<CR>
omap il :normal vil<CR>
" control quickfixlist
nnoremap <leader>' :copen<CR>
nnoremap <leader>" :cclose<CR>
" Insert line
nnoremap go o<Esc>
nnoremap gO O<Esc>
" Easy exit from insert mode
inoremap jk <Esc>
inoremap jw <Esc>:w<CR>
inoremap jx <Esc>:x<CR>
" Clear search highlight
nnoremap <Esc> <Cmd>nohlsearch<CR>
" Y behaves like C and D
nnoremap Y yg_
" Center screen after search result
nnoremap n nzzzv
nnoremap N Nzzzv
" Blackhole x, c and d
nnoremap x "_x
nnoremap X "_X
" Blackhole <leader>d
nnoremap <leader>d "_d
nnoremap <leader>D "_D
" Copy unnamed register to p register so you can use it later
nnoremap <leader>cp :let @p=@""<CR>
" vim-fish makes the / a keyword, but I don't like that

""""""""""""""""""""""""""""""Autocommands""""""""""""""""""""""""""""""
""" Filetype Autocommands
" Yaml should have 2 spaces
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
" vim-fish makes / part of a word, but that's weird
autocmd BufNewFile,BufRead *.fish set iskeyword-=/
" Python debugging abbreviation
autocmd BufNewFile,BufRead *.py ab pdb import pdb; pdb.set_trace()
" Ensure Jenkinsfile has groovy syntax
au BufNewFile,BufRead Jenkinsfile setf groovy

" Don't auto-comment new lines
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
" persist cursor location between sessions
autocmd BufReadPost * exe "normal! g`\""
" Highlight for a short moment after yanking
augroup highlight_yank
    autocmd!
    autocmd TextYankPost * silent! lua require'vim.highlight'.on_yank({timeout = 200})
augroup END
