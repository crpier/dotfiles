" Install vimplug and the plugins if not installed
let data_dir = stdpath('data').'/site'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
call plug#begin(stdpath('data').'/plugged')
" Common plugins
Plug 'airblade/vim-gitgutter'
Plug 'bkad/CamelCaseMotion'
Plug 'dag/vim-fish'
Plug 'machakann/vim-highlightedyank'
Plug 'morhetz/gruvbox'
Plug 'ojroques/vim-oscyank'
Plug 'pearofducks/ansible-vim'
Plug 'saltstack/salt-vim'
Plug 'szw/vim-maximizer', { 'on': 'MaximizerToggle' }
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'wellle/targets.vim'
" Neovim specific
Plug 'hrsh7th/nvim-compe'
Plug 'kyazdani42/nvim-tree.lua', { 'on': 'NvimTreeToggle' }
Plug 'kyazdani42/nvim-web-devicons'
Plug 'mfussenegger/nvim-dap'
Plug 'mfussenegger/nvim-dap-python'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
" TODO install ripgrep if not installed
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate' }
call plug#end()

""""""""""""""""""""""""""""""General Options""""""""""""""""""""""""""""""
"" Common settings first
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
"" Neovim specific settings last
silent call mkdir(stdpath('data').'undodir', "p", 0700)
" where to store undo data. It is guaranteed that ~/.local/share/nvim exists 
" TODO find a way to use a variable here
set undodir=~/.local/share/nvim/undodir

""""""""""""""""""""""""""""""Theme"""""""""""""""""""""""""""""""""""""""""
colorscheme gruvbox
set background=dark
" Transparent background
hi Normal guibg=NONE ctermbg=NONE
" Duration of yank highlight
let g:highlightedyank_highlight_duration = 200

""""""""""""""""""""""""""""""Plugin settings""""""""""""""""""""""""""""""
" Common plugins first
" maximizer key
nnoremap <leader>z :MaximizerToggle!<CR>
" camelcase motion key
let g:camelcasemotion_key = '\'
" if using tmux on local machine, use this to yank selection to your clipboard
vnoremap <leader>c :OSCYank<CR>
" Fugitive stuff
nnoremap <leader>gi :Git
nnoremap <leader>gb :Git blame<CR>
nnoremap <leader>gd :Gdiffsplit<CR>
nnoremap <leader>gpl :Git pull<CR>
nnoremap <leader>gps :Git push<CR>

""" Neovim specific plugins after
" Toggle file explore
nnoremap <leader>e <cmd>NvimTreeToggle<CR>

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
" telescope bindings
nnoremap <leader>f :lua require('telescope.builtin').git_files()<CR>
nnoremap <leader>mb :lua require('telescope.builtin').buffers()<CR>
nnoremap <leader>md :lua require('telescope.builtin').lsp_document_diagnostics()<CR>
nnoremap <leader>mf :lua require('telescope.builtin').find_files()<CR>
nnoremap <leader>mh :lua require('telescope.builtin').command_history()<CR>
nnoremap <leader>mj :lua require('telescope.builtin').jumplist()<CR>
nnoremap <leader>ml :lua require('telescope.builtin').lsp_document_symbols()<CR>
nnoremap <leader>mq :lua require('telescope.builtin').quickfix()<CR>
nnoremap <leader>ms :lua require('telescope.builtin').grep_string({ search = vim.fn.input("Grep For > ")})<CR>
nnoremap <leader>mw :lua require('telescope.builtin').grep_string { search = vim.fn.expand("<cword>") }<CR><CR>
nnoremap <leader>mz :lua require('telescope.builtin').current_buffer_fuzzy_find()<CR>
" compe
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
" nvim-dap
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

""""""""""""""""""""""""""""""General Remaps""""""""""""""""""""""""""""""""
""""""""" Utility maps
" easy source vimrc
nnoremap <leader><CR> :so ~/.vimrc<CR>
" Search for selected text using '//'
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>
" Insert line without entering insert mode
nnoremap go o<Esc>
nnoremap gO O<Esc>
" Clear search highlight
nnoremap <Esc> <Cmd>nohlsearch<CR>
" Yank until end of line
nnoremap Y yg_
" Center screen after search result
nnoremap n nzzzv
nnoremap N Nzzzv
" Blackhole d and D with leader
nnoremap <leader>d "_d
nnoremap <leader>D "_D
" I don't use EX mode, and I keep pressing it by mistake when I want to quit
nnoremap Q ZQ
" Copy unnamed register to p register
nnoremap cp :let @p=@""<CR>
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
"""""""" New Operators
" select text inside line without spaces
vnoremap al :<C-U>normal 0v$h<CR>
omap al :normal val<CR>
vnoremap il :<C-U>normal ^vg_<CR>
omap il :normal vil<CR>
"""""""" Toggles
" close quickfixlist easily (a toggle function would be better tho)
nnoremap <C-Q> <cmd>cclose<CR>
"""""""" Insert mode mappings
" Command mode
imap jk <Esc>:w<CR>
" Command mode and save
imap jw <Esc>:w<CR>
"""""""" Override default mappings
" Blackhole x
nnoremap x "_x
nnoremap X "_X
" Don't keep { and } on jumplist
nnoremap } :keepjumps normal! }<cr>
nnoremap { :keepjumps normal! {<cr>
xnoremap } :<C-u>keepjumps normal! gv}<cr>
xnoremap { :<C-u>keepjumps normal! gv{<cr>

""""""""""""""""""""""""""""""Autocommands""""""""""""""""""""""""""""""
" persist cursor location between sessions
autocmd BufReadPost *
  \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
  \ |   exe "normal! g`\""
  \ | endif
" Don't auto insert comments
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
"""""""""""" Filetype autocmds
" Yaml 
"" uses spaces, not tabs
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
" Python
"" I am so lazy i need abbreviation for pdb lmao
autocmd BufNewFile,BufRead *.py ab pdb import pdb; pdb.set_trace()
" This is more of a filename autocmd lol
"" Make sure Jenkinsfile have groovy syntax highlight
au BufNewFile,BufRead Jenkinsfile setf groovy
" vim-fish makes / part of a word, but that's weird
autocmd BufNewFile,BufRead *.fish set iskeyword-=/
