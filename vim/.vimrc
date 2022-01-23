" Install vimplug and the plugins if not installed
let data_dir = '~/.vim'
if empty(glob(data_dir.'/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
" Common plugins
Plug 'airblade/vim-gitgutter'
Plug 'bkad/CamelCaseMotion'
Plug 'dag/vim-fish'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'machakann/vim-highlightedyank'
Plug 'morhetz/gruvbox'
Plug 'ojroques/vim-oscyank'
Plug 'pearofducks/ansible-vim'
Plug 'saltstack/salt-vim'
Plug 'szw/vim-maximizer', { 'on': 'MaximizerToggle' }
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'wellle/targets.vim'
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
"" Vim specific settings last
" ensure the undodir exists
silent call mkdir($HOME . "/.vim/undodir", "p", 0700)
" where to store undo data. It is guaranteed that ~/.local/share/nvim exists
set undodir=~/.vim/undodir

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

""""""""""""""""""""""""""""""General Remaps""""""""""""""""""""""""""""""""
""""""""" Utility maps
" easy source vimrc
nnoremap <leader><CR> :so ~/.vimrc<CR>
" Search for selected text using '//'
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>
" Insert line without entering insert mode
nnoremap go o<Esc>
nnoremap gO O<Esc>
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

if !empty(glob("~/.config/local_configs/.vimrc"))
  source ~/.config/local_configs/.vimrc
endif
