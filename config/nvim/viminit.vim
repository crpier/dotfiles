call plug#begin('~/.vim/plugged')
Plug 'morhetz/gruvbox'
Plug 'lifepillar/vim-gruvbox8'
" " status bar
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
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
set nohlsearch
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
set signcolumn=yes
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

""""""""""""""""""""""""""""""Experimental Remaps"""""""""""""""""""""""""""""
" I might keep these, I might not, we'll see

