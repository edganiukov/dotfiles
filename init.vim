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
Plug 'autozimu/LanguageClient-neovim', {'branch': 'next', 'do': 'bash install.sh'}
" Completion
Plug 'ncm2/ncm2'
Plug 'roxma/nvim-yarp'
Plug 'Shougo/echodoc.vim'

call plug#end()

" Standard VIM TUI Settings
"
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
set gcr=a:blinkon0

set autoread
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

set scrolljump=1
set scrolloff=4
set backspace=2
set foldenable
set conceallevel=2

set number
set signcolumn=yes
set pumheight=15
set colorcolumn=81
set cursorline

set pastetoggle=<F2>
set nopaste
" copy to the system clipboard
set clipboard=unnamedplus 
" set clipboard=unnamed
"
set list
set listchars=tab:»\ ,extends:›,precedes:‹,nbsp:·,trail:·

" Vim formatting options
set wrap
set formatoptions=qrn1
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

nnoremap <leader>w :w<CR>
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

hi ExtraWhitespace ctermbg=LightGrey
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
au FileType markdown setlocal spell sw=2 sts=2 ts=2 syntax=markdown

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
let NERDTreeIgnore=[
    \ '\.DS_Store',
    \ '\.git$',
    \ '\.test$'
    \]
let NERDTreeMapActivateNode='<Space>'
let g:NERDTreeWinSize=40

map <F3> :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif


" Plug 'jreybert/vimagit'
"
let g:magit_commit_title_limit=80

" Plug 'ncm2/ncm2'
"
autocmd BufEnter * call ncm2#enable_for_buffer()

imap <C-x><C-o> <Plug>(ncm2_manual_trigger)
inoremap <expr> <CR> (pumvisible() ? "\<C-y>\<CR>" : "\<CR>")
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Plug 'Shougo/echodoc.vim'
"
let g:echodoc#enable_at_startup=1
let g:echodoc#type='signature'

" Plug 'autozimu/LanguageClient-neovim'
"
" https://github.com/sourcegraph/go-langserver
" https://github.com/cquery-project/cquery
" https://github.com/rust-lang/rls
" https://github.com/palantir/python-language-server
" https://raw.githubusercontent.com/edganiukov/homebrew-jdt-ls/master/jdt-ls.rb
let g:LanguageClient_serverCommands={
    \ 'go': ['go-langserver', '-gocodecompletion', '-diagnostics'],
    \ 'c': ['cquery', '--init={"cacheDirectory": "/tmp/cquery"}'],
    \ 'cpp': ['cquery', '--init={"cacheDirectory": "/tmp/cquery"}'],
    \ 'rust': ['rustup', 'run', 'stable', 'rls'],
    \ 'python': ['pyls'],
    \ 'java': ['/usr/local/bin/jdt-ls',
        \ '--add-modules=ALL-SYSTEM',
        \ '--add-opens', 'java.base/java.util=ALL-UNNAMED',
        \ '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
        \ ],
    \ }

" Java: custom `.workspace` file that indicates parent directory
" of the Eclipse workspace directory.
let g:LanguageClient_rootMarkers={
    \ 'go': ['Gopkg.toml', 'go.mod'],
    \ 'cpp': ['.cquery'],
    \ 'c': ['.cquery'],
    \ 'rust': ['Cargo.toml'],
    \ 'java': ['.workspace'],
    \ }

let g:LanguageClient_selectionUI="fzf"
let g:LanguageClient_diagnosticsDisplay={
    \ 1: {
        \ "name": "Error",
        \ "texthl": "ALEError",
        \ "signText": "✗",
        \ "signTexthl": "ALEErrorSign",
        \},
    \ 2: { 
        \ "name": "Warning",
        \ "texthl": "ALEWarning",
        \ "signText": "✗",
        \ "signTexthl": "ALEWarningSign",
        \ },
    \ 3: {
        \ "name": "Information",
        \ "texthl": "ALEInfo",
        \ "signText": "➤",
        \ "signTexthl": "ALEInfoSign",
        \},
    \ 4: {
        \ "name": "Hint",
        \ "texthl": "ALEInfo",
        \ "signText": "➤",
        \ "signTexthl": "ALEInfoSign",
        \},
    \ }

let g:LanguageClient_loggingLevel='INFO'
let g:LanguageClient_loggingFile='/tmp/lsp.log'

nnoremap <silent> gd :call LanguageClient#textDocument_definition()<CR>
nnoremap <silent> gr :call LanguageClient#textDocument_rename()<CR>
nnoremap <silent> gf :call LanguageClient#textDocument_formatting()<CR>
nnoremap <silent> gtd :call LanguageClient#textDocument_typeDefinition()<CR>
nnoremap <silent> gx :call LanguageClient#textDocument_references()<CR>
nnoremap <silent> ga :call LanguageClient_workspace_applyEdit()<CR>
nnoremap <silent> gh :call LanguageClient#textDocument_hover()<CR>
nnoremap <silent> gs :call LanguageClient_textDocument_documentSymbol()<CR>
nnoremap <silent> gm :call LanguageClient_contextMenu()<CR>

" Plug 'rust-lang/rust.vim'
"
let g:rustfmt_autosave=1

au FileType rust nnoremap gt :RustTest<CR>

" Plug 'rhysd/vim-clang-format'
"
let g:clang_format#code_style='llvm'
let g:clang_format#auto_format=1


" Plug 'pearofducks/ansible-vim'
"
let g:ansible_unindent_after_newline=1
let g:ansible_name_highlight='d'
let g:ansible_extra_keywords_highlight=0

au FileType yaml setlocal sw=2 sts=2 ts=2

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
let g:go_auto_type_info = 0

let g:go_decls_included="type,func"
let g:go_fmt_command="goimports"
let g:go_def_mode="godef"
let g:go_info_mode="gocode"
let g:go_snippet_case_type="camelcase"
let g:go_addtags_transform="camelcase"

nnoremap <C-g> :GoAlternate<CR>
au FileType go nmap gb <Plug>(go-build)
au FileType go nmap gt <Plug>(go-test)
au FileType go nmap gc <Plug>(go-coverage-toggle)
au FileType go nmap gI <Plug>(go-implements)
au FileType go nmap gi <Plug>(go-info)
au FileType go nmap <silent>gd <Plug>(go-doc)
au FileType go nmap gds <Plug>(go-def-split)
au FileType go nmap gdv <Plug>(go-def-vertical)

" replaced with LSP
" au FileType go nmap gr <Plug>(go-rename)
" au FileType go nmap gd <Plug>(go-def)

au FileType go set noexpandtab

au! BufRead,BufNewFile *.toml setlocal filetype=conf
au FileType make setlocal noexpandtab
au FileType json setlocal sw=2 sts=2 ts=2
au FileType conf setlocal sw=2 sts=2 ts=2 fileformat=unix
au FileType gitcommit setlocal spell tw=80
