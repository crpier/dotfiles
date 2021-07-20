" Install vimplug if it is not installed
let data_dir = '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
" manage surrounding characters
Plug 'tpope/vim-surround'
" Sensible defaults
Plug 'tpope/vim-sensible'
" Useful shortcuts, mostly using the square brackets
Plug 'tpope/vim-unimpaired'
" Repeat commands from plugins using period (.)
Plug 'tpope/vim-repeat'
" Looks good
Plug 'morhetz/gruvbox'
" improved motion
Plug 'bkad/CamelCaseMotion'
let g:camelcasemotion_key = '\'
" Maximize one split
Plug 'szw/vim-maximizer'
" Easy commenting
nnoremap <leader>m :MaximizerToggle!<CR>
Plug 'tpope/vim-commentary'
" Add additional text objects
Plug 'wellle/targets.vim'
" Fish syntax highlighting
Plug 'dag/vim-fish'
" Show me what I yanked lol
Plug 'machakann/vim-highlightedyank'
let g:highlightedyank_highlight_duration = 200
" Remote copy, local paste
Plug 'ojroques/vim-oscyank'
vnoremap <leader>c :OSCYank<CR>
" Haha Ansible go brr
Plug 'pearofducks/ansible-vim', { 'do': './UltiSnips/generate.sh' }
" salt too (╯°□°）╯︵ ┻━┻
Plug 'saltstack/salt-vim'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
" Snippets, nice
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
" Debugger
Plug 'puremourning/vimspector'
call plug#end()

""""""""""""""""""""""""""""""General Options""""""""""""""""""""""""""""""
" The colorscheme command has to be afte the `plug` section
colorscheme gruvbox
" Honestly, gruvbox looks weird without this
set background=dark
" Transparent background, this command needs to be after the `colorscheme`
" command to work
hi Normal guibg=NONE ctermbg=NONE
let mapleader = " "
set expandtab
set smartindent
" if there's a vimrc in curent directory, use that
set exrc
" show current line number and relative line number
set number relativenumber
" keep buffers open in the background even when not saved
set hidden
" self explanatory
set noerrorbells
" when searching, if there are no uppercases, then search is case insensitive
set ignorecase
set smartcase
" move cursor to search result while typing
set incsearch
" hightl search
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
" undodirs for vim and neovim are incompatible, thus we should not use
" different editors for the same file
silent call mkdir($HOME . "/.vim/undodir", "p", 0700)
set undodir=~/.vim/undodir

""""""""""""""""""""""""""""""General Remaps""""""""""""""""""""""""""""""""
""""""""" Utility maps
" easy source vimrc
nnoremap <leader><CR> :so ~/.vimrc<CR>
" Search for selected text using '//'
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>
" Insert line without entering insert mode
nnoremap go o<Esc>
nnoremap gO O<Esc>
" Navigate window splits with the arrow keys
nnoremap <Left> <C-w>h
nnoremap <Down> <C-w>j
nnoremap <Up> <C-w>k
nnoremap <Right> <C-w>l
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
nnoremap <leader>cp :let @p=@""<CR>
"""""""" New Operators
" select text inside line without spaces
vnoremap al :<C-U>normal 0v$h<CR>
omap al :normal val<CR>
vnoremap il :<C-U>normal ^vg_<CR>
omap il :normal vil<CR>
"""""""" Toggles
" close quickfixlist easily (a toggle function would be better tho)
nnoremap <C-Q> <cmd>copen<CR>
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
