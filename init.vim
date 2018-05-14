call plug#begin('~/.vim/plugged')

" Plugins
" https://github.com/junegunn/vim-plug
Plug 'joshdick/onedark.vim'
Plug 'chriskempson/vim-tomorrow-theme'

Plug 'itchyny/lightline.vim'
Plug 'jlanzarotta/bufexplorer'
Plug 'tpope/vim-commentary'
Plug 'scrooloose/nerdtree'
Plug 'airblade/vim-gitgutter'
Plug 'jreybert/vimagit'
Plug 'jiangmiao/auto-pairs'
Plug 'w0rp/ale'
Plug 'junegunn/fzf.vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }

Plug 'jceb/vim-orgmode', { 'for': 'org' }
Plug 'vim-scripts/utl.vim', { 'for': 'org' }
Plug 'vim-scripts/speeddating.vim', { 'for': 'org' }
Plug 'mattn/calendar-vim'
Plug 'plasticboy/vim-markdown', { 'for': 'markdown' }
Plug 'lervag/vimtex', { 'for': 'tex' }

Plug 'fatih/vim-go'
Plug 'rust-lang/rust.vim'
Plug 'racer-rust/vim-racer'
Plug 'pearofducks/ansible-vim'

" completion
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-gocode.vim'
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'keremc/asyncomplete-racer.vim'

call plug#end()

" General settings
" ---
syntax on
hi LineNr term=bold cterm=bold ctermfg=DarkGrey ctermbg=NONE

colorscheme Tomorrow-Night
set background=dark

set nocompatible
filetype off
filetype plugin indent on

set ttyfast
set ttymouse=xterm2
set ttyscroll=3

set laststatus=2
set encoding=utf-8
set backspace=indent,eol,start
set mouse=a

set autoindent
set autoread

set incsearch
set hlsearch
set matchtime=2

" cursor fix
if exists('$TMUX')
    let &t_SI = "\<Esc>[5 q"
    let &t_EI = "\<Esc>[2 q""]]"
else
    let &t_SI = "\e[5 q"
    let &t_EI = "\e[2 q"
endif


set noerrorbells
set novisualbell
set tm=500
set vb t_vb=

set number
set autoread
set wildmenu

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

set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4

set wrap

set scrolloff=4
set backspace=2
set gcr=a:blinkon0
set pumheight=15
set colorcolumn=81
set list
set listchars=tab:»\ ,extends:›,precedes:‹,nbsp:·,trail:· " Unicode

set cursorline
set pastetoggle=<F2>
set nopaste

set completeopt=menu,menuone,noinsert,noselect

" mappings
nmap q: <silent>
nnoremap <Leader>w :w<CR>
nnoremap <leader><space> :nohlsearch<CR>
nnoremap <leader>a :cclose<CR>
nnoremap <F10> :set list!<CR>
nnoremap Y y$
inoremap <F10> <Esc>:set list!<CR>a

noremap j gj
noremap k gk

" buffers switch
map <leader>n :bn!<CR>
map <leader>m :bp!<CR>

" quickfix jump
map <C-n> :cn<CR>
map <C-m> :cp<CR>

imap hh <Esc>
imap jj <Esc>

" window navigation
nmap <C-h> <C-w>h
nmap <C-j> <C-w>j
nmap <C-k> <C-w>k
nmap <C-l> <C-w>l

" C-h fix
nmap <BS> <C-W>h

noremap <Up> <NOP>
noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>

" inoremap <Up> <NOP>
" inoremap <Down> <NOP>
" inoremap <Left> <NOP>
" inoremap <Right> <NOP>

" indent
nmap < <<
nmap > >>
xmap < <gV
xmap > >gV

hi ExtraWhitespace ctermbg=DarkGrey guibg=DarkGrey
match ExtraWhitespace /\s\+$/
" nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>


" Plugin: w0rp/ale
" ---
let g:ale_set_highlights = 0
let g:ale_sign_error = '>>'
let g:ale_sign_warning = '⚠'
let g:ale_sign_column_always = 1

" highlight clear ALEErrorSign
" highlight clear ALEWarningSign

let g:ale_linters = {
    \ 'go': ['golint', 'govet', 'go build', 'staticcheck'],
    \ 'javascript': ['eslint'],
    \ 'ansible': ['ansible-lint'],
    \ 'python': ['pylint', 'autopep8']
    \}

hi clear SpellBad
hi SpellBad cterm=underline

" Plugin: plasticboy/vim-markdown
" ---
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_fenced_languages = ['go=go', 'bash=sh']
let g:vim_markdown_toml_frontmatter = 1
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_new_list_item_indent = 2
let g:vim_markdown_no_extensions_in_markdown = 1"

" Plugin: junegunn/fzf
" ---
let g:fzf_layout = { 'down': '~40%' }
let g:fzf_colors = {
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
    let parts = split(a:line, ':')
    return {'filename': parts[0], 'lnum': parts[1], 'col': parts[2],
        \ 'text': join(parts[3:], ':')}
endfunction

function! s:ag_handler(lines)
    if len(a:lines) < 2 | return | endif

    let cmd = get({'ctrl-x': 'split',
               \ 'ctrl-v': 'vertical split',
               \ 'ctrl-t': 'tabe'}, a:lines[0], 'e')
    let list = map(a:lines[1:], 's:ag_to_qf(v:val)')

    let first = list[0]
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

" Plugin: lightline
" ---
let g:bufferline_echo = 0
let g:lightline = {
    \ 'active': {
    \ 'left': [
        \ [ 'mode', 'paste'],
        \ [ 'fugitive', 'filename', 'modified' ]
        \ ],
    \ 'right': [
        \ [ 'lineinfo' ],
        \ [ 'percent' ],
        \ [ 'fileformat', 'fileencoding', 'filetype' ]
        \ ]
    \ },
    \ 'component': {
        \ 'go': '%#goStatuslineColor#%{LightLineGo()}',
        \ },
    \ 'component_visible_condition': {
        \ 'go': '(exists("*go#statusline#Show") && ""!=go#statusline#Show())'
        \ },
    \ 'component_function': {
        \ 'fugitive': 'LightLineFugitive',
        \ },
    \ 'separator': { 'left': '', 'right': '' },
    \ 'subseparator': { 'left': ':', 'right': ':' },
    \ }

function! LightLineFugitive()
    return exists('*fugitive#head') ? fugitive#head() : ''
endfunction

function! LightLineGo()
    return exists('*go#statusline#Show') ? go#statusline#Show() : ''
endfunction

" Plugin: scrooloose/nerdtree
" ---
let NERDTreeDirArrows=1
let NERDTreeMinimalUI=1
let NERDTreeShowHidden=1
let NERDTreeIgnore=['\.DS_Store', '\.git$', '\.test$']
let g:NERDTreeWinSize=40
let NERDTreeMapActivateNode='<Space>'

map <F3> :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif


" Plugin: pearofducks/ansible-vim
" ---
let g:ansible_unindent_after_newline = 1
let g:ansible_name_highlight = 'd'
let g:ansible_extra_keywords_highlight = 1

" Plugin: jreybert/vimagit
" ---
let g:magit_commit_title_limit=80

" Plugin: jceb/vim-orgmode
" ---
let g:org_agenda_files = [
            \'~/work/notes/ops/todo.org',
            \'~/work/notes/sm/todo.org',
            \'~/dev/notes/todo.org',
            \]

" Plugin: prabirshrestha/asyncomplete.vim
" ---
let g:asyncomplete_remove_duplicates = 1

inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<cr>"
imap <C-Space> <Plug>(asyncomplete_force_refresh)

" Go completion
call asyncomplete#register_source(asyncomplete#sources#gocode#get_source_options({
    \ 'name': 'gocode',
    \ 'whitelist': ['go'],
    \ 'completor': function('asyncomplete#sources#gocode#completor'),
    \ }))

" Rust completetion
autocmd User asyncomplete_setup call asyncomplete#register_source(
    \ asyncomplete#sources#racer#get_source_options())

" Python
if executable('pyls')
    " pip install python-language-server
    " pip install pycodestyle
    au User lsp_setup call lsp#register_server({
        \ 'name': 'pyls',
        \ 'cmd': {server_info->['pyls']},
        \ 'whitelist': ['python'],
        \ })
endif

" Language: Golang
" ---
let g:go_disable_autoinstall = 0
let g:go_highlight_functions = 0
let g:go_highlight_methods = 0
let g:go_highlight_structs = 0
let g:go_highlight_operators = 0
let g:go_highlight_build_constraints = 1
let g:go_highlight_interfaces = 0

let g:go_auto_sameids = 1
let g:go_decls_included = "type,func"

let g:go_fmt_command = "goimports"
let g:go_fmt_fail_silently = 1

let g:go_def_mode = "guru"
let g:go_list_type = "quickfix"

let g:go_snippet_case_type = "camelcase"
let g:go_addtags_transform = "camelcase"
let g:go_gocode_unimported_packages = 1

nnoremap <C-g> :GoAlternate<CR>
au FileType go nmap <leader>r <Plug>(go-run)
au FileType go nmap <leader>b <Plug>(go-build)
au FileType go nmap <leader>t <Plug>(go-test)
au FileType go nmap <leader>e <Plug>(go-rename)
au FileType go nmap <leader>c <Plug>(go-coverage-toggle)

au FileType go nmap <leader>d <Plug>(go-def)
au FileType go nmap <Leader>ds <Plug>(go-def-split)
au FileType go nmap <Leader>dv <Plug>(go-def-vertical)

au FileType go nmap <leader>s <Plug>(go-implements)
au FileType go nmap <leader>im <Plug>(go-imports)
au FileType go nmap <leader>gd <Plug>(go-doc)
au FileType go nmap <leader>i <Plug>(go-info)

au FileType go set noexpandtab
au FileType go set shiftwidth=4
au FileType go set softtabstop=4
au FileType go set tabstop=4

" Language: Rust
" ---
let g:rustfmt_autosave = 1

" https://github.com/phildawes/racer
au FileType rust nmap <leader>d <Plug>(rust-def)
au FileType rust nmap <leader>gs <Plug>(rust-def-split)
au FileType rust nmap <leader>dv <Plug>(rust-def-vertical)
au FileType rust nmap <leader>gd <Plug>(rust-doc)

" Language: python
" ---

" Language: markdown
" ---
au FileType markdown setlocal spell
au FileType markdown set expandtab
au FileType markdown set shiftwidth=2
au FileType markdown set softtabstop=2
au FileType markdown set tabstop=2
au FileType markdown set syntax=markdown

" Language: make
" ---
au FileType make set noexpandtab
au FileType make set shiftwidth=4
au FileType make set softtabstop=4
au FileType make set tabstop=4

" Language: json
" ---
au FileType json set expandtab
au FileType json set shiftwidth=2
au FileType json set softtabstop=2
au FileType json set tabstop=2

" Language: yaml
" ---
au FileType yaml set expandtab
au FileType yaml set shiftwidth=2
au FileType yaml set softtabstop=2
au FileType yaml set tabstop=2

" Language: toml
" ---
au FileType toml set expandtab
au FileType toml set shiftwidth=2
au FileType toml set softtabstop=2
au FileType toml set tabstop=2

" Language: conf
" ---
au FileType conf set expandtab
au FileType conf set shiftwidth=2
au FileType conf set softtabstop=2
au FileType conf set tabstop=2

" Language: gitcommit
" ---
au FileType gitcommit setlocal spell
au FileType gitcommit setlocal textwidth=80

" Language: org
" ---
au FileType org setlocal spell
au FileType org setlocal textwidth=160
au FileType org set expandtab
au FileType org set shiftwidth=2
au FileType org set softtabstop=2
au FileType org set tabstop=2
