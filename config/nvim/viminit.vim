call plug#begin('~/.vim/plugged')
Plug 'morhetz/gruvbox'
Plug 'lifepillar/vim-gruvbox8'
" " improved motion
Plug 'bkad/CamelCaseMotion'
" git plugins
Plug 'szw/vim-maximizer'
" " Easy commenting
Plug 'tpope/vim-commentary'
" " Cheat Sheet
Plug 'dbeniamine/cheat.sh-vim'
" " prettier Experimental, might remove
" Plug 'sbdchd/neoformat'
" " manage surrounding characters
Plug 'tpope/vim-surround'
" Neovim plugins
Plug 'nvim-telescope/telescope.nvim', has('nvim') ? {} : { 'on': [] }
" undecided between gruvbox variants, so I keep them both
" Plug 'numirias/semshi', has('nvim') ? {'do': ':UpdateRemotePlugins' } :  {'do': ':UpdateRemotePlugins', 'on': [] }
" fuzzy finder
Plug 'nvim-lua/popup.nvim', has('nvim') ? {} : { 'on': [] }
Plug 'nvim-lua/plenary.nvim', has('nvim') ? {} : { 'on': [] }
Plug 'nvim-telescope/telescope.nvim', has('nvim') ? {} : { 'on': [] }
Plug 'nvim-telescope/telescope-fzy-native.nvim', has('nvim') ? {} : { 'on': [] }
" a fuzzy finders needs ripgrep
Plug 'jremmen/vim-ripgrep', has('nvim') ? {} : { 'on': [] }
" git plugins
Plug 'tpope/vim-fugitive', has('nvim') ? {} : { 'on': [] }
Plug 'airblade/vim-gitgutter', has('nvim') ? {} : { 'on': [] }
" Neovim lsp
Plug 'neovim/nvim-lspconfig', has('nvim') ? {} : { 'on': [] }
" Plug 'nvim-lua/completion-nvim'
Plug 'tjdevries/nlua.nvim', has('nvim') ? {} : { 'on': [] }
Plug 'tjdevries/lsp_extensions.nvim', has('nvim') ? {} : { 'on': [] }
Plug 'hrsh7th/nvim-compe', has('nvim') ? {} : { 'on': [] }
Plug 'tpope/vim-unimpaired', has('nvim') ? {} : { 'on': [] }
" Syntax highlighting
Plug 'nvim-treesitter/nvim-treesitter', has('nvim') ? {'do': ':TSUpdate' } : { 'on': [], 'do': ':TSUpdate' }
Plug 'nvim-treesitter/playground', has('nvim') ? {} : { 'on': [] }
" Debugger
Plug 'puremourning/vimspector'
" prettier Experimental, might remove
Plug 'sbdchd/neoformat', has('nvim') ? {} : { 'on': [] }
Plug 'hrsh7th/vim-vsnip', has('nvim') ? {} : { 'on': [] }
Plug 'itspriddle/vim-shellcheck', has('nvim') ? {} : { 'on': [] }
Plug 'skywind3000/asyncrun.vim', has('nvim') ? {} : { 'on': [] }
Plug 'preservim/tagbar', has('nvim') ? {} : { 'on': [] }
Plug 'mg979/vim-visual-multi', has('nvim') ? {'branch': 'master'} : {'branch': 'master', 'on': []}
Plug 'tpope/vim-sensible'
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'tpope/vim-repeat', has('nvim') ? {} : { 'on': [] }
" Plug 'itchyny/lightline.vim'
" Plug 'shinchu/lightline-gruvbox.vim'
Plug 'vim-airline/vim-airline'
call plug#end()

""""""""""""""""""""""""""""""General Options""""""""""""""""""""""""""""""
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
" if there's a vimrc in curent directory, use that
set exrc
" show current line number and relative line number for other lines
set number relativenumber
" set nohlsearch
" keep buffers open in the background even when not saved
set hidden
set noerrorbells
" when searching, if there are no uppercases, then search is case insensitive
set ignorecase
set smartcase
" keeps history over sessions
set noswapfile
set nobackup
set undodir=~/.vim/undodir
set undofile
" move cursor to search result while typing
set incsearch
" keep 4 lines above and below the cursor at all times
set scrolloff=4
" add an additional column to the left to be used by linters and other plugins
" set signcolumn=yes
" show the limit to line length
" set colorcolumn=100
" refresh the file if it was edited outside vim
set autoread
" load filetype, even when a plugin provides definitins
filetype plugin on
" default register is also clipboard
" set clipboard+=unnamedplus
" Open splits from either right or bottom (instead of left or up)
set splitbelow
set splitright
" allow using mouse
set mouse=a
" nice autocomplete
set completeopt=menuone,noinsert,noselect
set updatetime=300

""""" Set general options
let mapleader = " "

""""""""""""""""""""""""""""""Theme""""""""""""""""""""""""""""""
colorscheme gruvbox
set background=dark
" Transparent background
hi Normal guibg=NONE ctermbg=NONE

""""" Plugin settings
" Still undecided between lightline and airline
" let g:lightline = {}
" let g:lightline.colorscheme = 'jellybeans'

" Airline settings
if has('nvim') 
    call airline#parts#define_function('filetype', 'nvim_treesitter#statusline')
endif


" Airline settings
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#tagbar#enabled = 0


""""""""""""""""""""""""""""""General Remaps""""""""""""""""""""""""""""""
" I don't use EX mode + I keep pressing this by mistake
nnoremap Q <nop>
" Search for selected text using '//'
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>
" " Copy to clipboard
vnoremap  <leader>y  "+y
nnoremap  <leader>Y  "+yg_
nnoremap  <leader>y  "+y
nnoremap  <leader>yy  "+yy
" " Paste from clipboard
nnoremap <leader>p "+p
nnoremap <leader>P "+P
vnoremap <leader>p "+p
vnoremap <leader>P "+P
" easy source vimrc
nnoremap <Leader><CR> :so ~/.config/nvim/init.vim<CR>
" move lines up/down when in visual mode
" might give these up, [e and ]e from vim-unimpaired seem better
" vnoremap J :m '>+1<CR>gv=gv
" vnoremap K :m '<-2<CR>gv=gv
" select text inside line without spaces
vnoremap al :<C-U>normal 0v$h<CR>
omap al :normal val<CR>
vnoremap il :<C-U>normal ^vg_<CR>
omap il :normal vil<CR>
" use tab to select from suggestions
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ "\<C-n>"
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
nnoremap <leader>c :vsp ~/.config/nvim/init.vim<CR>
" control quickfixlist
nnoremap <leader>' :copen<CR>
nnoremap <leader>" :cclose<CR>
" control buffers
nnoremap <leader>bd :bdel<CR>

""""""""""""""""""""""""""""""Useful functions""""""""""""""""""""""""""""""
fun! EmptyRegisters()
    let regs=split('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/-"', '\zs')
    for r in regs
        call setreg(r, [])
    endfor
endfun
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

""""""""""""""""""""""""""""""Autocommands""""""""""""""""""""""""""""""
augroup highlight_yank
    autocmd!
    autocmd TextYankPost * silent! lua require'vim.highlight'.on_yank({timeout = 200})
augroup END

" persist cursor location between sessions
autocmd BufReadPost *
  \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
  \ |   exe "normal! g`\""
  \ | endif
" Edit files within Nvim's terminal without nesting sessions.
  augroup prevent_nested_edit
    autocmd VimEnter * if !empty($NVIM_LISTEN_ADDRESS) && $NVIM_LISTEN_ADDRESS !=# v:servername
            \ |let g:r=jobstart(['nc', '-U', $NVIM_LISTEN_ADDRESS],{'rpc':v:true})
            \ |let g:f=fnameescape(expand('%:p'))
            \ |noau bwipe
            \ |call rpcrequest(g:r, "nvim_command", "edit ".g:f)
            \ |call rpcrequest(g:r, "nvim_command", "call lib#SetNumberDisplay(1)")
            \ |qa
            \ |endif
  augroup END
""""""""""""""""""""""""""""""Plugin settings""""""""""""""""""""""""""""""
" CamelCaseMotion mappings
let g:camelcasemotion_key = '<leader>'
" For rg
" project root is cwd
let g:rg_derive_root='true'

nnoremap <leader>m :MaximizerToggle!<CR>

" Nerdtree mapping
" nnoremap <leader>n :NERDTreeFocus<CR>
" nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
" nnoremap <C-f> :NERDTreeFind<CR>

" Nerdtree settings
" Exit Vim if NERDTree is the only window left.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() |
            \ quit | endif
""""""""""""""""""""""""""""""Experimental Remaps"""""""""""""""""""""""""""""
" I might keep these, I might not, we'll see

imap jw <Esc>:w<CR>

" Quickly append semicolon or comma
imap ;; <Esc>A;<Esc>
imap ,, <Esc>A,<Esc>

" Navigate window splits with the arrow keys
nnoremap <Left> <C-w>h
nnoremap <Down> <C-w>j
nnoremap <Up> <C-w>k
nnoremap <Right> <C-w>l

nnoremap <S-Down> :vertical resize -10<CR>
nnoremap <S-Up> :vertical resize +10<CR>

" Newline at end of file - actually I came up with this one lol
nnoremap <leader>n Go<Esc>zz

" Clear search highlight
nnoremap <Esc> <Cmd>nohlsearch<CR>

" Yank until end of line
nnoremap Y yg_

" not really sure that this does but I'll keep it for now lol
set shortmess+=c

" Insert one char then exit nmode
nnoremap <C-s> :exec "normal i".nr2char(getchar())."\e"<CR>

" Sort selected lines alphabetically
vnoremap <Leader>s :sort<CR>

" Center screen after search result
nnoremap n nzzzv
nnoremap N Nzzzv

" Insert line
nmap <Backspace> O<Esc>
nmap <CR> o<Esc>

" Start term session
nnoremap <leader>t :vs<CR>:term<CR>i

" Move when using surroinding chars
imap "" ""<Esc>i
imap '' ''<Esc>i
imap () ()<Esc>i
imap [] []<Esc>i
imap {} {}<Esc>i

" Tab is wasted in normal mode, map it to something!
" nnoremap <Tab> ???
" nnoremap <S-Tab> ???

" Same as o and O, but escape indentation
nnoremap <Leader>o o<Esc>^Da
nnoremap <Leader>O O<Esc>^Da

" Blackhole x
nnoremap x "_x
