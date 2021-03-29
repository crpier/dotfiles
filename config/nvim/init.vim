source ~/.config/nvim/viminit.vim
if !empty(expand(glob("~/.config/local_configs/init.local.vim")))
    source ~/.config/local_configs/init.local.vim
endif


""""""""""""""""""""""""""""""General Options""""""""""""""""""""""""""""""

""""" Set general options
let g:python3_host_prog="~/.pynvim3/bin/python"
let g:python_host_prog="~/.pynvim/bin/python"
let mapleader = " "
" use <CR> to open file in the same split

""""""""""""""""""""""""""""""Theme""""""""""""""""""""""""""""""
""""" Plugin settings
" Airline settings
call airline#parts#define_function('filetype', 'nvim_treesitter#statusline')

" Airline settings
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#tagbar#enabled = 0


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
      init_selection = "gnn",
      node_incremental = "grn",
      scope_incremental = "grc",
      node_decremental = "grm",
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

" For nvim-lsp completion
lua << EOF
require'lspconfig'.pyright.setup{}
require'lspconfig'.tsserver.setup{}
EOF
" require'lspconfig'.vimls.setup{}
" require'lspconfig'.bashls.setup{}
nnoremap gd :lua vim.lsp.buf.definition()<CR>
nnoremap gi :lua vim.lsp.buf.implementation()<CR>
nnoremap gs :lua vim.lsp.buf.signature_help()<CR>
nnoremap <leader>rn :lua vim.lsp.buf.rename()<CR>
nnoremap gr :lua vim.lsp.buf.references()<CR>
nnoremap gh :lua vim.lsp.buf.hover()<CR>
nnoremap <leader>ca :lua vim.lsp.buf.code_action()<CR>
nnoremap <leader>sd :lua vim.lsp.diagnostic.set_loclist()<CR>
nnoremap ]g :lua vim.lsp.diagnostic.goto_next()<CR>
nnoremap [g :lua vim.lsp.diagnostic.goto_prev()<CR>
let g:completion_matching_strategy_list = ['exact', 'substring', 'fuzzy']
" I don't think I'll use this, still I'll keep it, you never know
" lua << EOF
" local on_attach = require'completion'.on_attach
" require'lspconfig'.pyright.setup{ on_attach=on_attach }
" EOF

" fugitive remaps
nnoremap <leader>gc :GBranches<CR>
nnoremap <leader>ga :Git fetch --all<CR>
nnoremap <leader>grom :Git pull origin/main<CR>
nmap <leader>gh :diffget //3<CR>
nmap <leader>gu :diffget //2<CR>
nmap <leader>gs :G<CR>

" telescope settings and remaps
lua << EOF
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
        ["<C-x>"] = false,
        -- ["<C-s>"] = actions.goto_file_selection_split,
        ["<C-q>"] = actions.send_to_qflist,
      },
    }
  },
  extensions = {
      fzy_native = {
          override_generic_sorter = false,
          override_file_sorter = true,
      }
  }
}
require('telescope').load_extension('fzy_native')
EOF

" haha vscode go brrr
nnoremap <C-p> :lua require('telescope.builtin').git_files()<CR>
nnoremap <Leader>f :lua require('telescope.builtin').find_files()<CR>
nnoremap <leader>ps :lua require('telescope.builtin').grep_string({ search = vim.fn.input("Grep For > ")})<CR>
nnoremap <leader>pw :lua require('telescope.builtin').grep_string { search = vim.fn.expand("<cword>") }<CR>
nnoremap gb :lua require('telescope.builtin').buffers()<CR>
nnoremap <leader>ph :lua require('telescope.builtin').help_tags()<CR>

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
" inoremap <silent><expr> <CR>      compe#confirm('<CR>')
inoremap <silent><expr> <C-e>     compe#close('<C-e>')
inoremap <silent><expr> <C-f>     compe#scroll({ 'delta': +4 })
inoremap <silent><expr> <C-d>     compe#scroll({ 'delta': -4 })

""""""""""""""""""""""""""""""Experimental Remaps"""""""""""""""""""""""""""""
" I might keep these, I might not, we'll see
" nmap <Esc> <Esc>`^


