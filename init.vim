call plug#begin('~/.config/nvim/plugged')

" Plugins
" https://github.com/junegunn/vim-plug
Plug 'morhetz/gruvbox'
Plug 'danilo-augusto/vim-afterglow'
" Basic
Plug 'itchyny/lightline.vim'
Plug 'jlanzarotta/bufexplorer'
Plug 'tpope/vim-commentary'
Plug 'scrooloose/nerdtree'
Plug 'jiangmiao/auto-pairs'
Plug 'tpope/vim-surround'
Plug 'junegunn/fzf.vim'
Plug 'mattn/calendar-vim'
" Git
Plug 'mhinz/vim-signify'
Plug 'jreybert/vimagit'
" Lang
Plug 'plasticboy/vim-markdown', {'for': 'markdown'}
Plug 'fatih/vim-go', {'for': 'go'}
Plug 'rust-lang/rust.vim', {'for': 'rust'}
Plug 'pearofducks/ansible-vim', {'for': 'ansible'}
Plug 'rhysd/vim-clang-format', {'for': ['c', 'cpp']}
" LSP
Plug 'w0rp/ale'
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'
" Completion
Plug 'ncm2/ncm2'
Plug 'roxma/nvim-yarp'
Plug 'ncm2/ncm2-vim-lsp'
Plug 'Shougo/echodoc.vim'

call plug#end()

" General settings
" ---
syntax on

set t_Co=256
set termguicolors
set bg=dark
colorscheme gruvbox

set hidden
set noerrorbells
set novisualbell
set t_vb=
set tm=500

set number
set autoread
set wildmenu
set completeopt=menu,menuone,noinsert,noselect

set ignorecase
set smartcase

set nobackup
set nowb
set noswapfile

set noshowmode
set showmatch
set showcmd
set lazyredraw

set autoindent
set smartindent

set foldenable
set conceallevel=2

set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4
set wrap

set scrolloff=4
set backspace=2

set pumheight=15
set colorcolumn=81
set cursorline

" Always draw the signcolumn.
set signcolumn=yes

set gcr=a:blinkon0
set list
set listchars=tab:»\ ,extends:›,precedes:‹,nbsp:·,trail:·

set pastetoggle=<F2>
set nopaste

" copy to the system clipboard
" set clipboard=unnamed
set clipboard=unnamedplus

" abbreviations
cnoreabbrev W! w!
cnoreabbrev Q! q!
cnoreabbrev Qall! qall!
cnoreabbrev Wq wq
cnoreabbrev Wa wa
cnoreabbrev WQ wq
cnoreabbrev W w
cnoreabbrev Q q
cnoreabbrev Qall qall

" mappings
nnoremap Y y$
noremap j gj
noremap k gk

nnoremap <F10> :set list!<CR>
inoremap <F10> <Esc>:set list!<CR>a

nnoremap <Leader>w :w<CR>
nnoremap <leader><space> :nohlsearch<CR>
nnoremap <leader>a :cclose<CR>
nnoremap <silent> qq :q<CR>
inoremap jj <Esc>

" close preview-window
nnoremap <silent> qp <C-w><C-z>

" buffers switch
nnoremap bn :bn!<CR>
nnoremap bm :bp!<CR>

" quickfix switch
map <C-n> :cp!<CR>
map <C-m> :cm!<CR>

" window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" disable arrows
noremap <Up> <NOP>
noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>

inoremap <Up> <NOP>
inoremap <Down> <NOP>
inoremap <Left> <NOP>
inoremap <Right> <NOP>

" indent
nmap < <<
nmap > >>
vnoremap < <gv
vnoremap > >gv

" delete without yanking
nnoremap <leader>d "_d
vnoremap <leader>d "_d

" replace currently selected text with default register without yanking it
vnoremap <leader>p "_dP"

hi ExtraWhitespace ctermbg=DarkGrey
match ExtraWhitespace /\s\+$/

hi clear SpellBad
hi SpellBad cterm=underline

" Plug 'mhinz/vim-signify'
"
let g:signify_vcs_list=['git']
let g:signify_realtime=1
let g:signify_cursorhold_insert=1
let g:signify_cursorhold_normal=1
let g:signify_update_on_bufenter=0
let g:signify_update_on_focusgained=1
let g:signify_sign_show_count=0

let g:signify_sign_add='+'
let g:signify_sign_delete='_'
let g:signify_sign_delete_first_line='‾'
let g:signify_sign_change='~'
let g:signify_sign_changedelete=g:signify_sign_change


" Plug 'mattn/calendar-vim'
"
nnoremap <leader>c :CalendarH<CR>

" Plug 'tpope/vim-markdown'
"
autocmd BufNewFile,BufReadPost *.md set filetype=markdown

let g:vim_markdown_fenced_languages=[
    \ 'vim',
    \ 'bash=sh',
    \ 'go',
    \ 'py=python',
    \ 'rs=rust',
    \ 'c',
    \ 'cpp',
    \ 'yaml',
    \ ]

let g:vim_markdown_folding_disabled=1
let g:vim_markdown_folding_style_pythonic=1
let g:tex_conceal=""
let g:vim_markdown_math=1
let g:vim_markdown_new_list_item_indent=2

" Plug 'junegunn/fzf.vim'
" Plug 'junegunn/fzf', {'dir': '~/.fzf', 'do': './install --all'}
"
set rtp+=/usr/local/opt/fzf

let g:fzf_layout={ 'down': '~40%' }
let g:fzf_colors={
    \ 'fg':      ['fg', 'Normal'],
    \ 'bg':      ['bg', 'Normal'],
    \ 'hl':      ['fg', 'Comment'],
    \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
    \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
    \ 'hl+':     ['fg', 'Statement'],
    \ 'info':    ['fg', 'PreProc'],
    \ 'prompt':  ['fg', 'Conditional'],
    \ 'pointer': ['fg', 'Exception'],
    \ 'marker':  ['fg', 'Keyword'],
    \ 'spinner': ['fg', 'Label'],
    \ 'header':  ['fg', 'Comment']
    \ }

" https://github.com/ggreer/the_silver_searcher
command! -nargs=* Ag call fzf#run({
    \ 'source':  printf('ag --nogroup --column --color "%s"',
    \                   escape(empty(<q-args>) ? '^(?=.)' : <q-args>, '"\')),
    \ 'sink*':    function('<sid>ag_handler'),
    \ 'options': '--ansi --expect=ctrl-t,ctrl-v,ctrl-x --delimiter : --nth 4.. '.
    \            '--multi --bind=ctrl-a:select-all,ctrl-d:deselect-all '.
    \            '--color hl:68,hl+:110',
    \ 'down':    '50%'
    \ })

function! s:ag_to_qf(line)
    let parts=split(a:line, ':')
    return {'filename': parts[0], 'lnum': parts[1], 'col': parts[2],
        \ 'text': join(parts[3:], ':')}
endfunction

function! s:ag_handler(lines)
    if len(a:lines) < 2 | return | endif

    let cmd=get({'ctrl-x': 'split',
               \ 'ctrl-v': 'vertical split',
               \ 'ctrl-t': 'tabe'}, a:lines[0], 'e')
    let list=map(a:lines[1:], 's:ag_to_qf(v:val)')

    let first=list[0]
    execute cmd escape(first.filename, ' %#\')
    execute first.lnum
    execute 'normal!' first.col.'|zz'

    if len(list) > 1
        call setqflist(list)
        copen
        wincmd p
    endif
endfunction

nnoremap <C-o> :Ag<CR>
nnoremap <C-p> :FZF<CR>

" Plug 'itchyny/lightline'
"
let g:bufferline_echo=0
let g:lightline={
    \ 'colorscheme': 'gruvbox',
    \ 'active': {
        \ 'left': [
            \ ['mode', 'paste'],
            \ ['fugitive', 'readonly', 'filename', 'modified']
        \ ],
        \ 'right': [
            \ ['lineinfo'],
            \ ['percent'],
            \ ['fileformat', 'fileencoding', 'filetype']
        \ ]
    \ },
    \ 'component_function': {
        \ 'fugitive': 'fugitive#head',
        \ },
    \ 'separator': { 'left': '', 'right': '' },
    \ 'subseparator': { 'left': ':', 'right': ':' },
    \ }


" Plug 'scrooloose/nerdtree'
"
let NERDTreeDirArrows=1
let NERDTreeMinimalUI=1
let NERDTreeShowHidden=1
let NERDTreeIgnore=['\.DS_Store', '\.git$', '\.test$']
let NERDTreeMapActivateNode='<Space>'
let g:NERDTreeWinSize=40

map <F3> :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif


" Plug 'jreybert/vimagit'
"
let g:magit_commit_title_limit=80

" Plug 'w0rp/ale'
"
let g:ale_set_highlights=0
let g:ale_sign_error='✗'
let g:ale_sign_warning='➤'

let g:ale_linters={
    \ 'ansible': ['ansible-lint'],
    \ 'go': ['go build', 'golint', 'govet', 'staticcheck'],
    \ 'python': ['pyls', 'pylint', 'autopep8'],
    \ 'rust': ['rls'],
    \ 'c': ['clang', 'cquery'],
    \ 'cpp': ['clang', 'cquery'],
    \ }

let g:ale_linters_explicit=1


" Plug 'ncm2/ncm2'
"
autocmd BufEnter * call ncm2#enable_for_buffer()

inoremap <expr> <CR> (pumvisible() ? "\<c-y>\<cr>" : "\<CR>")
" Use <TAB> to select the popup menu:
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Plug 'Shougo/echodoc.vim'
"
let g:echodoc#enable_at_startup=1
let g:echodoc#type='signature'

" Plug prabirshrestha/vim-lsp''
"
if executable('cquery')
    " https://github.com/cquery-project/cquery
    au User lsp_setup call lsp#register_server({
        \ 'name': 'cquery',
        \ 'cmd': {server_info->['cquery']},
        \ 'initialization_options': { 'cacheDirectory': '/tmp/cquery' },
        \ 'whitelist': ['c', 'cpp'],
        \ })
endif

if executable('pyls')
    " pip install python-language-server
    "https://github.com/palantir/python-language-server
    au User lsp_setup call lsp#register_server({
        \ 'name': 'pyls',
        \ 'cmd': {server_info->['pyls']},
        \ 'whitelist': ['python'],
        \ })
endif

" bingo: \ 'cmd': {server_info->['bingo', '--mode'. 'stdio', '--logfile', '/tmp/bingo.log', '--use-global-cache']},
" go-langserver: \ 'cmd': {server_info->['go-langserver', '-gocodecompletion']},
if executable('go-langserver')
    " https://github.com/sourcegraph/go-langserver
    au User lsp_setup call lsp#register_server({
        \ 'name': 'go-langserver',
        \ 'cmd': {server_info->['go-langserver', '-gocodecompletion']},
        \ 'whitelist': ['go'],
        \ })
endif

if executable('rls')
    " https://github.com/rust-lang/rls
    au User lsp_setup call lsp#register_server({
        \ 'name': 'rls',
        \ 'cmd': {server_info->['rustup', 'run', 'stable', 'rls']},
        \ 'root_uri':{server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'Cargo.toml'))},
        \ 'whitelist': ['rust'],
        \ })
endif

let g:lsp_preview_keep_focus=0
" let g:lsp_signs_enabled=1
" let g:lsp_diagnostics_echo_cursor=1
" let g:lsp_signs_error={'text': '✗'}
" let g:lsp_signs_warning={'text': '➤' }

nnoremap <silent> gd :LspDefinition<CR>
nnoremap <silent> gtd :LspTypeDefinition<CR>
nnoremap <silent> gr :LspRename<CR>
nnoremap <silent> gf :LspDocumentFormat<CR>
nnoremap <silent> ga :LspCodeAction<CR>
nnoremap <silent> gx :LspReferences<CR>
nnoremap <silent> gh :LspHover<CR>
nnoremap <silent> gs :LspDocumentSymbol<CR>


" Plug 'rust-lang/rust.vim'
"
let g:rustfmt_autosave=1

au FileType rust nnoremap gt :RustTest<CR>
au FileType rust set expandtab
au FileType rust set shiftwidth=4
au FileType rust set softtabstop=4
au FileType rust set tabstop=4

au FileType python set expandtab
au FileType python set shiftwidth=4
au FileType python set softtabstop=4
au FileType python set tabstop=4

" Plug 'rhysd/vim-clang-format'
"
let g:clang_format#code_style='llvm'
let g:clang_format#auto_format=1

au FileType c,cpp set expandtab
au FileType c,cpp set shiftwidth=4
au FileType c,cpp set softtabstop=4
au FileType c,cpp set tabstop=4


" Plug 'pearofducks/ansible-vim'
"
let g:ansible_unindent_after_newline=1
let g:ansible_name_highlight='d'
let g:ansible_extra_keywords_highlight=0

au FileType yaml set expandtab
au FileType yaml set shiftwidth=2
au FileType yaml set softtabstop=2
au FileType yaml set tabstop=2

" Plug 'fatih/vim-go'
"
let g:go_highlight_functions=0
let g:go_highlight_methods=0
let g:go_highlight_structs=0
let g:go_highlight_operators=0
let g:go_highlight_interfaces=0
let g:go_highlight_build_constraints=0

let g:go_disable_autoinstall=0
let g:go_fmt_fail_silently=1
let g:go_auto_sameids=0

let g:go_decls_included="type,func"
let g:go_fmt_command="goimports"
let g:go_def_mode="guru"
let g:go_info_mode="guru"
let g:go_snippet_case_type="camelcase"
let g:go_addtags_transform="camelcase"

nnoremap <C-g> :GoAlternate<CR>

au FileType go nmap gb <Plug>(go-build)
au FileType go nmap gt <Plug>(go-test)
au FileType go nmap gct <Plug>(go-coverage-toggle)
au FileType go nmap gI <Plug>(go-implements)
au FileType go nmap gi <Plug>(go-info)
au FileType go nmap <leader>gd <Plug>(go-doc)

" replaced with LSP
" au FileType go nmap gr <Plug>(go-rename)
" au FileType go nmap gd <Plug>(go-def)
" au FileType go nmap gds <Plug>(go-def-split)
" au FileType go nmap gdv <Plug>(go-def-vertical)

au FileType go set noexpandtab
au FileType go set shiftwidth=4
au FileType go set softtabstop=4
au FileType go set tabstop=4

" Lang: markdown
" ---
au FileType markdown setlocal spell
au FileType markdown set expandtab
au FileType markdown set shiftwidth=2
au FileType markdown set softtabstop=2
au FileType markdown set tabstop=2
au FileType markdown set syntax=markdown

" Lang: make
" ---
au FileType make set noexpandtab
au FileType make set shiftwidth=4
au FileType make set softtabstop=4
au FileType make set tabstop=4

" Lang: json
" ---
au FileType json set expandtab
au FileType json set shiftwidth=2
au FileType json set softtabstop=2
au FileType json set tabstop=2

" Lang: toml
" ---
au! BufRead,BufNewFile *.toml set filetype=conf
au FileType toml set expandtab
au FileType toml set shiftwidth=2
au FileType toml set softtabstop=2
au FileType toml set tabstop=2

" Lang: conf
" ---
au FileType conf set expandtab
au FileType conf set shiftwidth=2
au FileType conf set softtabstop=2
au FileType conf set tabstop=2

" Lang: gitcommit
" ---
au FileType gitcommit setlocal spell
au FileType gitcommit setlocal textwidth=80
