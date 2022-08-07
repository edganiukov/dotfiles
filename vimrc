vim9script

plug#begin('~/.vim/plugged')

# Plugins
# https://github.com/junegunn/vim-plug
Plug 'edganiukov/vim-colors-off'

# Basic
Plug 'jlanzarotta/bufexplorer'
Plug 'tpope/vim-commentary'
Plug 'junegunn/fzf.vim'
Plug 'preservim/tagbar'
Plug 'scrooloose/nerdtree'

Plug 'mhinz/vim-signify'
Plug 'jreybert/vimagit'
Plug 'tpope/vim-fugitive'

Plug 'edganiukov/vim-gol'
Plug 'plasticboy/vim-markdown'
Plug 'sebdah/vim-delve'

# LSP
Plug 'prabirshrestha/vim-lsp'
Plug 'lifepillar/vim-mucomplete'

plug#end()

# Standard VIM TUI Settings
set nocompatible
filetype off

filetype plugin indent on
syntax on

set t_Co=256
set t_ut=
# set termguicolors
set bg=dark

colorscheme off

# cmd autocomplete
set wildmenu
set wildoptions-=pum
set completeopt=menuone,noselect

set nospell
set hidden
set noerrorbells
set novisualbell
set modelines=0
set t_vb=
set tm=500
set mouse=a

set ignorecase
set smartcase

set nobackup
set nowb
set noswapfile

set noshowmode
set showmatch
set matchtime=2
set showcmd
set lazyredraw
set autoread

set autoindent
set smartindent

set scrolljump=1
set scrolloff=4
set backspace=2

set nofoldenable
set conceallevel=0

set number
set signcolumn=yes
set pumheight=20
set textwidth=120
set colorcolumn=121
set cursorline

set pastetoggle=<F2>
set nopaste

# copy to the system clipboard
set clipboard=unnamedplus

set listchars=tab:>\ ,nbsp:.,trail:.
set list

# Vim formatting options
set wrap
set formatoptions=qrn1j
set autoindent
set shiftwidth=4
set shiftround
set expandtab
set tabstop=4
set softtabstop=4
set nojoinspaces
set splitright
set splitbelow
set encoding=utf-8

set shortmess+=c
set laststatus=2

def g:StatusLineMode(): string
    var modes = {
        'n': 'NORMAL',
        'i': 'INSERT',
        'R': 'REPLACE',
        'v': 'VISUAL',
        'V': 'V-LINE',
        "\<C-v>": 'V-BLOCK',
        'c': 'COMMAND',
        's': 'SELECT',
        'S': 'S-LINE',
        "\<C-s>": 'S-BLOCK',
        't': 'TERMINAL'
    }
    return get(modes, mode(), '[NONE]')
enddef

set statusline=
set statusline+=%#Comment#[%n]%*
set statusline+=%#PmenuSel#\ %{g:StatusLineMode()}%{&paste?":PASTE":""}\ %*  # mode and paste indicator
set statusline+=\ %f\ %m\ %r  # filepath and modified flag

set statusline+=%=
set statusline+=%{&ff}  # file format
set statusline+=\ \|\ %{&fenc!=#""?&fenc:&enc}  # file enconding
set statusline+=\ \|\ %{&ft!=#""?&ft:"[none]"}  # file type
set statusline+=\ \|\ %p%%\ %l:%c\ %* # percentage and lineinfo

# abbreviations
cnoreabbrev W! w!
cnoreabbrev Q! q!
cnoreabbrev Wq wq
cnoreabbrev Wa wa
cnoreabbrev W w
cnoreabbrev Q q

# Non-plugin Keybindings:
# yank to the EOL
nnoremap Y y$
# delete without yanking
nnoremap <leader>d "_d
vnoremap <leader>d "_d
# replace selected text without yanking
vnoremap <leader>p "_dP"

# quotes
vnoremap <Leader>q" di""<Esc>P
vnoremap <Leader>q' di''<Esc>P
vnoremap <Leader>q` di``<Esc>P
vnoremap <Leader>q( di()<Esc>P
vnoremap <Leader>q[ di[]<Esc>P
vnoremap <Leader>q{ di{}<Esc>P
vnoremap <Leader>q< di<><Esc>P

noremap j gj
noremap k gk

# indent
nmap < <<
nmap > >>
vnoremap < <gv
vnoremap > >gv

nnoremap <F10> :set list!<CR>
inoremap <F10> <Esc>:set list!<CR>a
nnoremap <leader><space> :nohlsearch<CR>

# preview close
nnoremap <silent>qp <C-w><C-z>
# quickfix close
nnoremap <silent>qc :cclose<CR>
# quickfix switch
nnoremap qn :cn!<CR>
nnoremap qp :cp!<CR>
nnoremap <Down> :cn!<CR>
nnoremap <Up> :cp!<CR>

# buffers switch
nnoremap fn :bn!<CR>
nnoremap fp :bp!<CR>
nnoremap fd :bd<cr>

# window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

# disable arrows
# noremap <Up> <NOP>
# noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>

inoremap <Up> <NOP>
inoremap <Down> <NOP>
inoremap <Left> <NOP>
inoremap <Right> <NOP>

# insert current date
nnoremap <leader>id "=strftime("<%Y-%m-%d %a>")<CR>P
inoremap <leader>id <C-R>=strftime("<%Y-%m-%d %a>")<CR>

# semicolon in the EOL
# nnoremap ;; A;<Esc>
# inoremap ;; <C-o>A;
#
# expand opening-brace
inoremap {<CR> {<CR>}<Esc>O

# open/reload vim.rc
nnoremap <leader>ev :vsplit $MYVIMRC<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>

# Highlights
hi SignColumn ctermbg=NONE guibg=NONE
hi SpellBad cterm=undercurl ctermbg=NONE guibg=NONE

hi Todo ctermbg=NONE guibg=NONE cterm=NONE gui=NONE
hi Error ctermbg=NONE guibg=NONE cterm=NONE gui=NONE

# trailing whitespaces
match ErrorMsg '\s\+$'


# Plug 'mhinz/vim-signify'
#
g:signify_vcs_list = ['git']
g:signify_realtime = 1
g:signify_cursorhold_insert = 1
g:signify_cursorhold_normal = 1
g:signify_update_on_bufenter = 0
g:signify_update_on_focusgained = 1
g:signify_sign_show_count = 0

g:signify_sign_add = '+'
g:signify_sign_delete = '_'
g:signify_sign_delete_first_line = '‾'
g:signify_sign_change = '~'
g:signify_sign_changedelete = g:signify_sign_change

hi SignifySignAdd ctermbg=NONE guibg=NONE ctermfg=green guifg=green
hi SignifySignChange ctermbg=NONE guibg=NONE ctermfg=yellow guifg=yellow
hi SignifySignDelete ctermbg=NONE guibg=NONE ctermfg=red guifg=red


# Plug 'jreybert/vimagit'
#
g:magit_commit_title_limit = 80
nnoremap vm :Magit<CR>


# Plug 'majutsushi/tagbar'
#
nmap <F4> :TagbarToggle<CR>
g:tagbar_sort = 0


# Plug 'tpope/vim-markdown'
#
g:vim_markdown_fenced_languages = [
    'go',
    'python',
    'rust',
    'c',
    'cpp',
    'bash=sh',
    'yaml=yml',
]

g:vim_markdown_conceal = 1
g:vim_markdown_conceal_code_blocks = 1
g:vim_markdown_math = 1
g:vim_markdown_new_list_item_indent = 2

# Plug 'junegunn/fzf.vim'
#
set rtp+=/usr/local/opt/fzf
g:fzf_layout = { 'down': '~40%' }
# disable preview window
g:fzf_preview_window = ''

# match vim colorscheme
g:fzf_colors = {
    'fg':      ['fg', 'Normal'],
    'bg':      ['bg', 'Normal'],
    'hl':      ['fg', 'PreProc'],
    'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
    'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
    'hl+':     ['fg', 'Statement'],
    'info':    ['fg', 'PreProc'],
    'border':  ['fg', 'Ignore'],
    'prompt':  ['fg', 'Conditional'],
    'pointer': ['fg', 'Exception'],
    'marker':  ['fg', 'Keyword'],
    'spinner': ['fg', 'Label'],
    'header':  ['fg', 'Comment']
}

nnoremap <leader>b :Buffers<CR>
nnoremap <leader>f :Files<CR>
nnoremap <leader>h :Hist<CR>

nnoremap <leader>s :Rg<CR>
command! -bang -nargs=* Rg legacy call fzf#vim#grep(
  \ 'rg --column --line-number --no-heading --color=always
    \ --colors "path:fg:190,220,255" --colors "line:fg:128,128,128" --smart-case '.shellescape(<q-args>),
  \ 1, {'options': '--color hl:72,hl+:167 --nth 2..'}, 0)

# Plug 'scrooloose/nerdtree'
#
g:NERDTreeDirArrows = 1
g:NERDTreeMinimalUI = 1
g:NERDTreeShowHidden = 1
g:NERDTreeIgnore = [
    '\.git$',
    '\.test$',
    '\.pyc$',
]

g:NERDTreeMapActivateNode = '<Space>'
g:NERDTreeWinSize = 40

g:NERDTreeDirArrowExpandable = '+'
g:NERDTreeDirArrowCollapsible = '-'

map <F3> :NERDTreeToggle<CR>
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree')
  | quit
  | endif


# Plug 'lifepillar/vim-mucomplete'
#
g:mucomplete#enable_auto_at_startup = 1
g:mucomplete#completion_delay = 100
g:mucomplete#reopen_immediately = 1

g:mucomplete#chains = {}
g:mucomplete#chains.default = ['omni']
g:mucomplete#can_complete = {
    default: {
        omni: (t) => strlen(&l:omnifunc) > 0 && t =~# '\%(\k\|->\|::\|\.\)$',
    }
}

# mucomplete + vim-lsp
autocmd FileType go,rust,c,cpp,python setlocal omnifunc=lsp#complete
inoremap <leader>c <C-x><C-o>


# Plug 'prabirshrestha/vim-lsp'
#
# golang.org/x/tools/cmd/gopls
var gols = {
    name: 'gopls',
    cmd: (server_info) => ['gopls', 'serve'],
    root_uri: (server_info) => lsp#utils#path_to_uri(
        lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), ['go.work', 'go.mod'])
    ),
    workspace_config: {
        gopls: {
            codelenses: {generate: v:false, gc_details: v:true},
            hoverKind: 'FullDocumentation',
            linksInHover: v:false,
            experimentalWorkspaceModule: v:true,
        },
    },
    allowlist: ['go'],
    languageId: (server_info) => 'filetype',
}
au User lsp_setup call lsp#register_server(gols)

# https://github.com/rust-lang/rust-analyzer
var rls = {
    name: 'rls',
    cmd: (server_info) => ['rust-analyzer'],
    root_uri: (server_info) => lsp#utils#path_to_uri(
        lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), ['Cargo.toml'])
    ),
    initialization_options: {
        cargo: {
            loadOutDirsFromCheck: v:true,
        },
        procMacro: {
            enable: v:true,
        },
    },
    allowlist: ['rust'],
}
au User lsp_setup call lsp#register_server(rls)

# https://github.com/MaskRay/ccls
var cls = {
    name: 'ccls',
    cmd: (server_info) => ['ccls'],
    root_uri: (server_info) => lsp#utils#path_to_uri(
        lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), ['.ccls', 'compile_commands.json'])
    ),
    initialization_options: {cache: {directory: expand('~/.cache/ccls')}},
    allowlist: ['c', 'cpp'],
}
au User lsp_setup call lsp#register_server(cls)

# https://github.com/python-lsp/python-lsp-server
var pyls = {
    name: 'pylsp',
    cmd: (server_info) => ['pylsp'],
    root_uri: (server_info) => lsp#utils#path_to_uri(
        lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), ['.git'])
    ),
    workspace_config: {pyls: {
        configurationSources: ['flake8'],
    }},
    allowlist: ['python'],
}
au User lsp_setup call lsp#register_server(pyls)

g:lsp_fold_enabled = 0
g:lsp_text_edit_enabled = 0
g:lsp_insert_text_enabled = 1

g:lsp_diagnostics_enabled = 1
g:lsp_diagnostics_echo_cursor = 1
g:lsp_diagnostics_virtual_text_enabled = 0

g:lsp_diagnostics_signs_error = {'text': 'x'}
g:lsp_diagnostics_signs_warning = {'text': 'w'}
g:lsp_diagnostics_signs_information = {'text': '@'}
g:lsp_diagnostics_signs_hint = {'text': '*'}

g:lsp_document_code_action_signs_hint = {'text': '>'}

g:lsp_hover_conceal = 1
g:lsp_format_sync_timeout = 1000
g:lsp_semantic_enabled = 0

g:lsp_show_message_log_level = 'none'
g:lsp_log_file = expand('/tmp/lsp.log')

nnoremap <silent> gd :LspDefinition<CR>
nnoremap <silent> gds :sp<cr>:LspDefinition<cr>
nnoremap <silent> gdv :vsp<cr>:LspDefinition<cr>
nnoremap <silent> gtd :LspTypeDefinition<CR>
nnoremap <silent> gdc :LspDeclaration<cr>
nnoremap <silent> gi :LspImplementation<cr>
nnoremap <silent> gr :LspRename<CR>
nnoremap <silent> gf :LspDocumentFormat<CR>
nnoremap <silent> grf :LspDocumentRangeFormat<CR>
nnoremap <silent> ga :LspCodeAction<CR>
nnoremap <silent> gl :LspCodeLens<CR>
nnoremap <silent> gn :LspNextError<CR>
nnoremap <silent> gp :LspPreviousError<CR>
nnoremap <silent> gx :LspReferences<CR>
nnoremap <silent> gh :LspHover<CR>
nnoremap <silent> gs :LspWorkspaceSymbol<CR>
nnoremap <silent> gth :LspTypeHierarchy<CR>

autocmd FileType go,rust,python
    \ autocmd BufWritePre <buffer> :LspDocumentFormatSync

autocmd FileType go,rust,python
    \ autocmd BufWritePre <buffer>
    \ call execute('LspCodeActionSync source.organizeImports')


# Plug 'sebdah/vim-delve'
#
hi DlvPoint term=standout ctermbg=117 ctermfg=0 guibg=#BAD4F5 guifg=Black
g:delve_breakpoint_sign_highlight = 'DlvPoint'
g:delve_tracepoint_sign_highlight = 'DlvPoint'
g:delve_breakpoint_sign = '>>'
g:delve_tracepoint_sign = '||'

nnoremap <silent> drt :DlvTest<CR>
nnoremap <silent> drd :DlvDebug<CR>
nnoremap <silent> dtb :DlvToggleBreakpoint<CR>
nnoremap <silent> dtt :DlvToggleTracepoint<CR>


# General: filetype config
#
augroup filetypedetect
  au BufRead,BufNewFile *.conf setlocal ft=conf

  au FileType go,c,cpp setlocal noexpandtab tw=100 cc=100
  au FileType python setlocal sw=4 sts=4 ts=4 tw=100 cc=100
  au FileType vim,yaml,json setlocal sw=2 sts=2 ts=2

  au FileType rst,markdown setlocal spell tw=80 cc=80 cole=2
  au FileType mail setlocal sw=4 sts=4 ts=4 tw=72 cc=72 spell
  au FileType gitcommit setlocal spell tw=72 cc=72
augroup END
