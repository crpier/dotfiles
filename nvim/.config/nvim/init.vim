call plug#begin('~/.local/share/nvim/plugged')
" Looks good
Plug 'morhetz/gruvbox'
" improved motion
Plug 'bkad/CamelCaseMotion'
" Maximize one split
Plug 'szw/vim-maximizer'
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
" Airline is so slow it doubles my startup time, but I haven't figured out
" how to make something light like lightline do what I want, so ¯\_(ツ)_/¯
Plug 'vim-airline/vim-airline'
" Telescope, that'all
Plug 'nvim-telescope/telescope.nvim'
" Faster sort algorithm for telescope (or so they claim)
Plug 'nvim-lua/popup.nvim'
" Dependency for telescop and other nvim plugins
Plug 'nvim-lua/plenary.nvim'
" Fzf for telescope
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
" Nice icons for telescope
Plug 'kyazdani42/nvim-web-devicons'
" Tree finder
Plug 'kyazdani42/nvim-tree.lua'
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
" Debugger
Plug 'puremourning/vimspector'
" Create terminals on demand
Plug 'voldikss/vim-floaterm'
" Haha Ansible go brr
Plug 'pearofducks/ansible-vim', { 'do': './UltiSnips/generate.sh' }
" Go
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries'}
Plug 'saltstack/salt-vim'
call plug#end()

""""""""""""""""""""""""""""""General Options""""""""""""""""""""""""""""""

""""" Set general options
let g:python3_host_prog="~/.pynvim3/bin/python"
let g:python_host_prog="~/.pynvim/bin/python"
let g:completion_matching_strategy_list = ['exact', 'substring', 'fuzzy']
let mapleader = " "
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
" if there's a vimrc in curent directory, use that
" TODO I copied this off the internet like a good boi, but do I really need it?
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
set undodir=~/.local/share/nvim/undodir

""""""""""""""""""""""""""""""Plugin settings""""""""""""""""""""""""""""""
" vim-go stuff
let g:go_code_completion_enabled = 0
let g:go_snippet_engine = "ultisnips"
let g:go_textobj_enabled = 0
let g:go_list_type = "quickfix"
" TODO is there anything bad that will happen if I disable this?
let g:go_gopls_enabled = 1
let g:go_build_tags = 'integration'
let g:go_def_mapping_enabled = 0


" maximizer plugin
nnoremap <leader>m :MaximizerToggle!<CR>
let g:camelcasemotion_key = '\'
"""" These are plugins enabled for nvim only, because they provide an IDE like
"""" exerience that regular vim doesn't much care for, and which would be
"""" difficult to replicate on a remote server like a raspberry 3 lol
"""""""""""" Nerdtree
nnoremap <leader>nt :NERDTreeToggle<CR>
nnoremap <leader>nf :NERDTreeFind<CR>
" Exit Vim if NERDTree is the only window left.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() |
    \ quit | endif
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

""""""""""""""""""""""""""""""Neovim Theme""""""""""""""""""""""""""""""
" Airline settings
call airline#parts#define_function('filetype', 'nvim_treesitter#statusline')
let g:airline#extensions#tagbar#enabled = 0
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#buffer_nr_show = 1

""""""""""""""""""""""""""""""Theme"""""""""""""""""""""""""""""""""""""""""
colorscheme gruvbox
set background=dark
" Transparent background
hi Normal guibg=NONE ctermbg=NONE
" Duration of yank highlight
let g:highlightedyank_highlight_duration = 200
let g:highlightedyank_highlight_duration = 200

let g:airline_section_x = ""
let g:airline_section_y = ""
" TODO find a way to toggle these sections
" let g:airline_section_error = ""
" let g:airline_section_warning = ""
""""""""""""""""""""""""""""""General Remaps""""""""""""""""""""""""""""""""
" easy source vimrc
nnoremap <leader><CR> :so ~/.config/nvim/init.vim<CR>
nnoremap <leader>ee :e ~/.config/nvim/init.vim<CR>
nnoremap <leader>ev :vsp ~/.config/nvim/init.vim<CR>
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
" persist cursor location between sessions
autocmd BufReadPost *
  \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
  \ |   exe "normal! g`\""
  \ | endif
" Highlight for a short moment after yanking
" augroup highlight_yank
"     autocmd!
"     autocmd TextYankPost * silent! lua require'vim.highlight'.on_yank({timeout = 200})
" augroup END
" When switching to a terminal buffer, autoenter insert mode
" autocmd BufEnter * if &buftype == 'terminal' | :startinsert | endif
" Don't auto insert comments
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
"""""""""""" Filetype autocmds
" Yaml uses spaces, no tabs
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
augroup python_abbrev
    autocmd BufNewFile,BufRead *.py ab pdb import pdb; pdb.set_trace()
augroup END

""""""""""""""""""""""""""""""Experimental"""""""""""""""""""""""""""""
" I might keep these, I might not, we'll see
" Start term session
nnoremap <leader>te :vs<CR>:term<CR>i
nnoremap <leader>lg :FloatermNew --autoclose=2 --height=0.95 --width=0.99 --wintype=floating lazygit<CR>
nnoremap <leader>fn :FloatermNew --autoclose=2 --height=0.9 --width=0.9 --wintype=floating<CR>
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
" Clear search highlight
nnoremap <Esc> <Cmd>nohlsearch<CR>
" Yank until end of line
nnoremap Y yg_
" Sort selected lines alphabetically
vnoremap <leader>s :sort<CR>
" Center screen after search result
nnoremap n nzzzv
nnoremap N Nzzzv
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
au BufNewFile,BufRead Jenkinsfile setf groovy
" vim-fish makes the / a keyword, but I don't like that
set iskeyword-='/'
