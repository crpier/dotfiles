source ~/.config/nvim/viminit.vim
if !empty(expand(glob("~/.config/local_configs/init.local.vim")))
    source ~/.config/local_configs/init.local.vim
endif


""""""""""""""""""""""""""""""General Options""""""""""""""""""""""""""""""

""""" Set general options
let g:python3_host_prog="~/.pynvim3/bin/python"
let g:python_host_prog="~/.pynvim/bin/python"
let g:completion_matching_strategy_list = ['exact', 'substring', 'fuzzy']
let mapleader = " "

""""""""""""""""""""""""""""""Theme""""""""""""""""""""""""""""""
""""" Plugin settings

""""""""""""""""""""""""""""""General Remaps""""""""""""""""""""""""""""""
" easy source vimrc
" nnoremap <Leader><CR> :so ~/.config/nvim/init.vim<CR>
" " use tab to select from suggestions
" inoremap <silent><expr> <TAB>
"       \ pumvisible() ? "\<C-n>" :
"       \ <SID>check_back_space() ? "\<TAB>" :
"       \ "\<C-n>"
" inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
" nnoremap <leader>c :vsp ~/.config/nvim/init.vim<CR>
""""""""""""""""""""""""""""""Useful functions""""""""""""""""""""""""""""""


""""""""""""""""""""""""""""""Autocommands""""""""""""""""""""""""""""""
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
" For rg
" project root is cwd
let g:rg_derive_root='true'
let g:rg_binary="/Users/cristian.piersinaru/Tools/rg"
" Treesitter config
lua <<EOF
require'nvim-treesitter.configs'.setup {
incremental_selection = {
    enable = true,
    keymaps = {
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

-- For nvim-lsp completion
require'lspconfig'.pyright.setup{}
require'lspconfig'.tsserver.setup{}
EOF

" The least used commands have leader mappings
nnoremap gd :lua vim.lsp.buf.definition()<CR>
" Do I even use this? Maybe I should just delete it
nnoremap gs :lua vim.lsp.buf.signature_help()<CR>
nnoremap gr :lua vim.lsp.buf.references()<CR>
nnoremap gh :lua vim.lsp.buf.hover()<CR>
nnoremap ]g :lua vim.lsp.diagnostic.goto_next()<CR>
nnoremap [g :lua vim.lsp.diagnostic.goto_prev()<CR>
nnoremap <leader>rn :lua vim.lsp.buf.rename()<CR>
nnoremap <leader>ca :lua vim.lsp.buf.code_action()<CR>


" fugitive remaps
nnoremap <leader>gb :Git blame<CR>
nnoremap <leader>gd :Gdiffsplit<CR>
nnoremap <leader>gpl :Git pull<CR>
nnoremap <leader>gps :Git push<CR>

" telescope settings and remaps
lua << EOF
-- require('telescope').load_extension('gh')
local actions = require('telescope.actions')
require('telescope').setup {
  defaults = {
    file_sorter = require('telescope.sorters').get_fzy_sorter,
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
      fzy_native = {
          override_generic_sorter = true,
          override_file_sorter = true,
      }
  }
}
require('telescope').load_extension('fzy_native')
EOF

nnoremap <leader>ff :lua require('telescope.builtin').git_files()<CR>
nnoremap <leader>fi :lua require('telescope.builtin').find_files()<CR>
nnoremap <leader>bu :lua require('telescope.builtin').buffers()<CR>
nnoremap <leader>bl :lua require('telescope.builtin').current_buffer_fuzzy_find()<CR>
nnoremap <leader>st :lua require('telescope.builtin').treesitter()<CR>
nnoremap <leader>rs :lua require('telescope.builtin').grep_string({ search = vim.fn.input("Grep For > ")})<CR>
nnoremap <leader>rw :lua require('telescope.builtin').grep_string { search = vim.fn.expand("<cword>") }<CR>

" vimspector remaps
fun! GotoWindow(id)
    call win_gotoid(a:id)
    MaximizerToggle
endfun
nnoremap <leader>dd :call vimspector#Launch()<CR>
nnoremap <leader>dc :call GotoWindow(g:vimspector_session_windows.code)<CR>
nnoremap <leader>dt :call GotoWindow(g:vimspector_session_windows.tagpage)<CR>
nnoremap <leader>dv :call GotoWindow(g:vimspector_session_windows.variables)<CR>
nnoremap <leader>dw :call GotoWindow(g:vimspector_session_windows.watches)<CR>
nnoremap <leader>ds :call GotoWindow(g:vimspector_session_windows.stack_trace)<CR>
nnoremap <leader>do :call GotoWindow(g:vimspector_session_windows.output)<CR>
nnoremap <leader>de :call vimspector#Reset()<CR>
nnoremap <leader>dtcb :call vimspector#CleanLineBreakpoint()<CR>
nmap <leader>dl <Plug>VimspectorStepInto
nmap <leader>dj <Plug>VimspectorStepOver
nmap <leader>dk <Plug>VimspectorStepOut
nmap <leader>d_ <Plug>VimspectorRestart
nnoremap <leader>d<space> :call vimspector#Continue()<CR>
nmap <leader>drc <Plug>VimspectorRunToCursor
nmap <leader>dbp <Plug>VimspectorToggleBreakpoint
nmap <leader>dcbp <Plug>VimspectorToggleConditionalBreakpoint

" nvim-compe settings
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
let g:compe.source.vsnip = v:true
let g:compe.source.nvim_lsp = v:true
let g:compe.source.nvim_lua = v:true
let g:compe.source.spell = v:true
let g:compe.source.tags = v:true
let g:compe.source.snippets_nvim = v:true
let g:compe.source.treesitter = v:true
let g:compe.source.omni = v:true

inoremap <silent><expr> <C-Space> compe#complete()
" Why did I comment this?
" inoremap <silent><expr> <CR>      compe#confirm('<CR>')
inoremap <silent><expr> <C-e>     compe#close('<C-e>')
inoremap <silent><expr> <C-f>     compe#scroll({ 'delta': +4 })
inoremap <silent><expr> <C-d>     compe#scroll({ 'delta': -4 })

""""""""""""""""""""""""""""""Experimental Remaps"""""""""""""""""""""""""""""
" I might keep these, I might not, we'll see

" Start term session
nnoremap <leader>t :vs<CR>:term<CR>i
" This only makes sense because I use vi mode in shell
" tnoremap <C-\> <C-\><C-n>
tnoremap <Left> <C-\><C-n><C-w>h
tnoremap <Right> <C-\><C-n><C-w>l

" TODO think about snippets, you might like them

" TODO figure out these colors and make :Gdiffsplit more gruvbox friendly
" highlight DiffAdd ctermfg=253 ctermbg=237 guifg=#dadada guibg=#3a3a3a

nnoremap <leader>lg :FloatermNew --autoclose=2 --height=0.9 --width=0.9 --wintype=floating lazygit<CR>
nnoremap <leader>f :FloatermNew --autoclose=2 --height=0.9 --width=0.9 --wintype=floating<CR>
