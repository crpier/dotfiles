call plug#begin('~/.vim/plugged')
" improved motion
Plug 'bkad/CamelCaseMotion'
" Easy commenting
Plug 'tpope/vim-surround'
" Sensible defaults
Plug 'tpope/vim-sensible'
" Add additional text objects
Plug 'wellle/targets.vim'
" Useful shortcuts, mostly using the square brackets
Plug 'tpope/vim-unimpaired'
" Repeat commands from plugins using period (.)
Plug 'tpope/vim-repeat'
call plug#end()

""""""""""""""""""""""""""""""General Options""""""""""""""""""""""""""""""

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
" keep 4 lines above and below the cursor at all times
set scrolloff=4
" show the preferred limit to line length
set colorcolumn=80
" refresh the file if it was edited outside vim
set autoread
" Open splits from either right or bottom (instead of left or up)
set splitbelow
set splitright
" allow using mouse
set mouse=a
" nice autocomplete
set completeopt=menuone,noinsert,noselect
set updatetime=300
" keeps history over sessions

""""""""""""""""""""""""""""""Plugin settings""""""""""""""""""""""""""""""
""""""""""""""""""""""""""""""General Remaps""""""""""""""""""""""""""""""""
" TODO: does this work?
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
" Insert line
nnoremap go o<Esc>
nnoremap gO O<Esc>

""""""""""""""""""""""""""""""Experimental"""""""""""""""""""""""""""""
" I might keep these, I might not, we'll see
imap jw <Esc>:w<CR>
" Navigate window splits with the arrow keys
nnoremap <Left> <C-w>h
nnoremap <Down> <C-w>j
nnoremap <Up> <C-w>k
nnoremap <Right> <C-w>l
" Get out from terminal instantly with ctrl+arrow_key
tnoremap <C-Left> <C-\><C-n><C-w>h
tnoremap <C-Right> <C-\><C-n><C-w>l
" Exit terminal easier
tnoremap <C-\> <C-\><C-n>
" Ez vertical resize (I dont'use use horizontal splits lol)
nnoremap <S-Down> :vertical resize -10<CR>
nnoremap <S-Up> :vertical resize +10<CR>
" Clear search highlight
nnoremap <Esc> <Cmd>nohlsearch<CR>
" Yank until end of line
nnoremap Y yg_
" not really sure that this does but I'll keep it for now lol
set shortmess+=c
" Sort selected lines alphabetically
vnoremap <leader>s :sort<CR>
" On the same note, gs for sleep and gq for format are not useful to me..map them too
" Same as o and O, but escape indentation
nnoremap <leader>o o<Esc>^Da
nnoremap <leader>O O<Esc>^Da
" Blackhole x, c and d
nnoremap x "_x
nnoremap X "_X
" But allow <leader>d to record to default register
nnoremap <leader>d d
nnoremap <leader>D D
" Copy unnamed register to p register
nnoremap <leader>cp :let @p=@""<CR>
" Don't keep { and } on jumplist
nnoremap } :keepjumps normal! }<cr>
nnoremap { :keepjumps normal! {<cr>
xnoremap } :<C-u>keepjumps normal! gv}<cr>
xnoremap { :<C-u>keepjumps normal! gv{<cr>
" Don't save to jumplist when searching
" Center screen after search result
nmap n :keepjumps normal nzzzv<cr>
nmap N :keepjumps normal NNzzzv<cr>
nnoremap * :keepjumps normal! *<cr>
nnoremap # :keepjumps normal! #<cr>
