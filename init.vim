call plug#begin('~/.config/nvim/plugged')

" Plugins
" https://github.com/junegunn/vim-plug
Plug 'morhetz/gruvbox'
Plug 'ajh17/Spacegray.vim'

" Basic
Plug 'itchyny/lightline.vim'
Plug 'jlanzarotta/bufexplorer'
Plug 'tpope/vim-commentary'
Plug 'scrooloose/nerdtree'
Plug 'tmsvg/pear-tree'
Plug 'junegunn/fzf.vim'
Plug 'mattn/calendar-vim'
" Git
Plug 'mhinz/vim-signify'
Plug 'jreybert/vimagit'
" Lang
Plug 'plasticboy/vim-markdown', {'for': 'markdown'}
Plug 'edganiukov/vim-go-lite', {'for': ['go', 'gomod']}
Plug 'sebdah/vim-delve', {'for': 'go'}
Plug 'rust-lang/rust.vim', {'for': 'rust'}
Plug 'pearofducks/ansible-vim', {'for': ['yaml.ansible', 'yaml', 'ansible']}
Plug 'rhysd/vim-clang-format', {'for': ['c', 'cpp']}
" LSP
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp', {'commit': 'bc7485361a9d632772514bc4a89455ef8025adb9'}
" Plug 'prabirshrestha/vim-lsp'
" Completion
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

call plug#end()

" Standard VIM TUI Settings
"
syntax on
set t_Co=256
set termguicolors
set bg=dark
colorscheme gruvbox
set encoding=UTF-8

set hidden
set noerrorbells
set novisualbell
set t_vb=
set tm=500
set gcr=a:blinkon0

set autoread
set completeopt=longest,menu,menuone,noinsert,noselect

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

set listchars=tab:→\ ,nbsp:·,trail:·
set nolist

" Vim formatting options
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

" suppress the annoying 'match x of y', 'The only match', etc.
set shortmess+=c

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

" yank to the EOL
nnoremap Y y$
" delete without yanking
nnoremap <leader>d "_d
vnoremap <leader>d "_d
" replace currently selected text with default register without yanking it
vnoremap <leader>p "_dP"

" quotes
vnoremap <Leader>q" di""<Esc>P
vnoremap <Leader>q' di''<Esc>P
vnoremap <Leader>q` di``<Esc>P
vnoremap <Leader>q( di()<Esc>P
vnoremap <Leader>q[ di[]<Esc>P
vnoremap <Leader>q{ di{}<Esc>P
vnoremap <Leader>q< di<><Esc>P

" semicolon in the EOL
nnoremap ;; A;<Esc>
inoremap ;; <C-o>A;

noremap j gj
noremap k gk

" indent
nmap < <<
nmap > >>
vnoremap < <gv
vnoremap > >gv

nnoremap <F10> :set list!<CR>
inoremap <F10> <Esc>:set list!<CR>a

nnoremap <leader>w :w<CR>
nnoremap <leader><space> :nohlsearch<CR>
inoremap jj <Esc>

" close quickfix window
nnoremap <silent>qc :cclose<CR>
" close preview window
nnoremap <silent>qp <C-w><C-z>

" buffers switch
nnoremap bn :bn!<CR>
nnoremap bm :bp!<CR>

" quickfix switch
map <C-n> :cp!<CR>
map <C-m> :cn!<CR>

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

" insert current date
:nnoremap <leader>id "=strftime("<%Y-%m-%d %a>")<CR>P
:inoremap <leader>id <C-R>=strftime("<%Y-%m-%d %a>")<CR>

" Highlights
hi clear SpellBad
hi SpellBad     cterm=undercurl
hi DiffAdd      ctermbg=none ctermfg=green guibg=none guifg=green
hi DiffChange   ctermbg=none ctermfg=yellow guibg=none guifg=yellow
hi DiffDelete   ctermbg=none ctermfg=red guibg=none guifg=red

" trailing whitespaces
match ErrorMsg '\s\+$'

" Quickly open/reload vim
nnoremap <leader>ev :vsplit $MYVIMRC<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>

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

let g:vim_markdown_folding_disabled=0
let g:vim_markdown_folding_style_pythonic=1
let g:tex_conceal=""
let g:vim_markdown_math=1
let g:vim_markdown_new_list_item_indent=2


" Plug 'junegunn/fzf.vim'
" Plug 'junegunn/fzf', {'dir': '~/.fzf', 'do': './install --all'}
"
set rtp+=/usr/local/opt/fzf
let g:fzf_layout={ 'down': '~40%' }

" https://github.com/BurntSushi/ripgrep
nnoremap <leader>s :Rg<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>f :Files<CR>


" Plug 'itchyny/lightline'
let g:bufferline_echo=0
let g:lightline={
    \ 'colorscheme': 'gruvbox',
    \ 'active': {
        \ 'left': [
            \ ['mode', 'paste'],
            \ ['readonly', 'filename', 'modified']
        \ ],
        \ 'right': [
            \ ['lineinfo'],
            \ ['percent'],
            \ ['fileformat', 'fileencoding', 'filetype']
        \ ]
    \ },
    \ 'component_function': {
        \ 'filename': 'LightlineFilename',
        \ },
    \ 'separator': { 'left': '', 'right': '' },
    \ 'subseparator': { 'left': ':', 'right': ':' },
    \ }

function! LightlineFilename()
    let root = fnamemodify(get(b:, 'git_dir'), ':h')
    let path = expand('%:p')
    if path[:len(root)-1] ==# root
        return path[len(root)+1:]
    endif
    return expand('%')
endfunction


" Plug 'scrooloose/nerdtree'
"
let NERDTreeDirArrows=1
let NERDTreeMinimalUI=1
let NERDTreeShowHidden=1
let NERDTreeIgnore=[
    \ '\.DS_Store',
    \ '\.git$',
    \ '\.test$',
    \ '\.pyc$'
    \]
let NERDTreeMapActivateNode='<Space>'
let g:NERDTreeWinSize=40

map <F3> :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" Plug 'tmsvg/pear-tree'
"
let g:pear_tree_repeatable_expand=0

" Plug 'jreybert/vimagit'
"
let g:magit_commit_title_limit=80


" Plug 'prabirshrestha/asyncomplete.vim'
"
let g:asyncomplete_auto_popup=1
let g:asyncomplete_remove_duplicates=1

imap <leader>f <Plug>(asyncomplete_force_refresh)

inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<CR>"
inoremap <expr> <TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr> <S-TAB> pumvisible() ? "\<C-p>" : "\<S-TAB>"

autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif

" Plug 'Shougo/echodoc.vim'
"
let g:echodoc#enable_at_startup=1
let g:echodoc#type='echo'

" Plug 'prabirshrestha/vim-lsp'
"
" https://github.com/sourcegraph/go-langserver:
" \ 'go-langserver', '--gocodecompletion', '--diagnostics'
" https://github.com/saibing/bingo:
" \ 'bingo', '--mode=stdio', '--format-style=goimports', '--disable-func-snippet'
" \ 'gopls', 'serve'
au User lsp_setup call lsp#register_server({
    \ 'name': 'go',
    \ 'cmd': {server_info->[
        \ 'bingo', '--mode=stdio', '--format-style=goimports', '--disable-func-snippet'
    \ ]},
    \ 'whitelist': ['go'],
    \ })

" https://github.com/palantir/python-language-server
au User lsp_setup call lsp#register_server({
    \ 'name': 'python',
    \ 'cmd': {server_info->[
        \'pyls'
        \]},
    \ 'whitelist': ['python'],
    \ })

" https://github.com/rust-lang/rls
au User lsp_setup call lsp#register_server({
    \ 'name': 'rust',
    \ 'cmd': {server_info->[
        \ 'rustup', 'run', 'stable', 'rls'
        \ ]},
    \ 'root_uri':{server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'Cargo.toml'))},
    \ 'whitelist': ['rust'],
    \ })

" https://github.com/cquery-project/cquery
au User lsp_setup call lsp#register_server({
    \ 'name': 'cpp',
    \ 'cmd': {server_info->[
        \ 'cquery'
        \ ]},
    \ 'root_uri': {server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), '.cquery'))},
    \ 'initialization_options': { 'cacheDirectory': expand('~/.cache/cquery') },
    \ 'whitelist': ['c', 'cpp'],
    \ })

let g:lsp_auto_enable=1
let g:lsp_preview_keep_focus=0
let g:lsp_diagnostics_enabled=1
let g:lsp_signs_enabled=1
let g:lsp_diagnostics_echo_cursor=1
let g:lsp_virtual_text_enabled=0
let g:lsp_highlights_enabled=1

let g:lsp_signs_error={ 'text': '✗' }
let g:lsp_signs_warning={ 'text': '✗' }
let g:lsp_signs_information={ 'text': '➤' }
let g:lsp_signs_hint={ 'text': '➤' }

nnoremap <silent> gd :LspDefinition<CR>
nnoremap <silent> gds :sp<cr>:LspDefinition<cr>
nnoremap <silent> gdv :vsp<cr>:LspDefinition<cr>
nnoremap <silent> gtd :LspTypeDefinition<CR>
nnoremap <silent> gr :LspRename<CR>
nnoremap <silent> gf :LspDocumentFormat<CR>
nnoremap <silent> grf :LspDocumentRangeFormat<CR>
nnoremap <silent> ga :LspCodeAction<CR>
nnoremap <silent> gx :LspReferences<CR>
nnoremap <silent> gh :LspHover<CR>
nnoremap <silent> gs :LspDocumentSymbol<CR>

" debug
let g:lsp_log_verbose=1
let g:lsp_log_file=expand('/tmp/lsp.log')


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


" Plug 'fatih/vim-go'
"
let g:go_disable_autoinstall=1
let g:go_fmt_fail_silently=1
let g:go_fmt_command="goimports"
let g:go_fmt_autosave=1
let g:go_addtags_transform="camelcase"

nnoremap <C-g> :GoAlternate<CR>
au FileType go nmap gb <Plug>(go-build)
au FileType go nmap gt <Plug>(go-test)
au FileType go nmap gc <Plug>(go-coverage-toggle)
au FileType go nmap <leader>gd <Plug>(go-doc)


" Plug 'sebdahvim-delve'
hi DlvPoint term=standout ctermbg=117 ctermfg=0 guibg=#BAD4F5 guifg=Black
let g:delve_breakpoint_sign_highlight='DlvPoint'
let g:delve_tracepoint_sign_highlight='DlvPoint'
let g:delve_breakpoint_sign='>>'
let g:delve_tracepoint_sign='||'

nnoremap <silent> drt :DlvTest<CR>
nnoremap <silent> drd :DlvDebug<CR>
nnoremap <silent> dtb :DlvToggleBreakpoint<CR>
nnoremap <silent> dtt :DlvToggleTracepoint<CR>

au FileType yaml setlocal sw=2 sts=2 ts=2
au FileType go setlocal noexpandtab
au FileType make setlocal noexpandtab
au FileType json setlocal sw=2 sts=2 ts=2
au FileType conf setlocal sw=2 sts=2 ts=2
au FileType gitcommit setlocal spell tw=80

au BufRead,BufNewFile *.toml setlocal ft=conf
au BufRead,BufNewFile *.yml.j2 setlocal ft=yaml
