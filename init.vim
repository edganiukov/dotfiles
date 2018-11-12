call plug#begin('~/.config/nvim/plugged')

" Plugins
" https://github.com/junegunn/vim-plug
Plug 'morhetz/gruvbox'

Plug 'itchyny/lightline.vim'
Plug 'jlanzarotta/bufexplorer'
Plug 'tpope/vim-commentary'
Plug 'scrooloose/nerdtree'
Plug 'airblade/vim-gitgutter'
Plug 'jreybert/vimagit'
Plug 'jiangmiao/auto-pairs'
Plug 'w0rp/ale'
Plug 'junegunn/fzf.vim'
Plug 'junegunn/fzf', {'dir': '~/.fzf', 'do': './install --all'}
Plug 'junegunn/goyo.vim'

Plug 'mattn/calendar-vim'
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown', {'for': 'markdown'}
Plug 'lervag/vimtex', {'for': 'tex'}

Plug 'fatih/vim-go', {'for': 'go'}
Plug 'rust-lang/rust.vim', {'for': 'rust'}
Plug 'racer-rust/vim-racer', {'for': 'rust'}
Plug 'pearofducks/ansible-vim', {'for': 'ansible'}

" completion
Plug 'ncm2/ncm2'
Plug 'roxma/nvim-yarp'
Plug 'ncm2/ncm2-bufword'

Plug 'ncm2/ncm2-go', {'for': 'go'}
Plug 'ncm2/ncm2-jedi', {'for': 'python'}
Plug 'ncm2/ncm2-racer', {'for': 'rust'}

call plug#end()

" General settings
" ---
syntax on

" set termguicolors
colorscheme gruvbox
set bg=dark

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

set gcr=a:blinkon0
set list
set listchars=tab:»\ ,extends:›,precedes:‹,nbsp:·,trail:· " Unicode

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
nnoremap qq :q<CR>
inoremap jj <Esc>

" buffers switch
map <C-n> :bn!<CR>
map <C-m> :bp!<CR>

" window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

inoremap <A-h> <C-o>h
inoremap <A-j> <C-o>j
inoremap <A-k> <C-o>k
inoremap <A-l> <C-o>l

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


" Plug 'airblade/vim-gitgutter'
"
hi clear SignColumn
hi GitGutterAdd ctermfg=green
hi GitGutterChange ctermfg=yellow
hi GitGutterDelete ctermfg=red
hi GitGutterChangeDelete ctermfg=yellow

" Plug 'w0rp/ale'
"
let g:ale_set_highlights = 0
let g:ale_sign_error = '✗'
let g:ale_sign_warning = '⚠'
let g:ale_sign_column_always = 1

hi clear ALEErrorSign
hi clear ALEWarningSign
hi ALEErrorSign ctermfg=red
hi ALEWarningSign ctermfg=yellow

let g:ale_linters = {
    \ 'ansible': ['ansible-lint'],
    \ 'go': ['golint', 'govet', 'go build', 'staticcheck'],
    \ 'python': ['pylint', 'autopep8'],
    \ 'rust': ['rustc', 'rustfmt']
    \ }

let g:ale_linters_explicit = 1

hi clear SpellBad
hi SpellBad cterm=underline

" Plug 'plasticboy/vim-markdown'
"
let g:vim_markdown_folding_style_pythonic = 1
let g:vim_markdown_fenced_languages = [
    \ 'vim=vim',
    \ 'sh=sh',
    \ 'go=go',
    \ 'py=python',
    \ 'rs=rust'
    \ ]

let g:vim_markdown_new_list_item_indent = 2
let g:vim_markdown_no_extensions_in_markdown = 1

let g:tex_conceal = ""
let g:vim_markdown_math = 1

" Plug 'junegunn/fzf.vim'
" Plug 'junegunn/fzf', {'dir': '~/.fzf', 'do': './install --all'}
"
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

" Plug 'itchyny/lightline'
"
let g:bufferline_echo = 0
let g:lightline = {
    \ 'colorscheme': 'gruvbox',
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

" Plug 'scrooloose/nerdtree'
"
let NERDTreeDirArrows=1
let NERDTreeMinimalUI=1
let NERDTreeShowHidden=1
let NERDTreeIgnore=['\.DS_Store', '\.git$', '\.test$']
let g:NERDTreeWinSize=40
let NERDTreeMapActivateNode='<Space>'

map <F3> :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif


" Plug 'jreybert/vimagit'
"
let g:magit_commit_title_limit=80


" Plug 'ncm2/ncm2'
" Plug 'roxma/nvim-yarp'
" Plug 'ncm2/ncm2-bufword'
"
" enable ncm2 for all buffers
autocmd BufEnter * call ncm2#enable_for_buffer()
set shortmess+=c
" When the <Enter> key is pressed while the popup menu is visible, it only
" hides the menu. Use this mapping to close the menu and also start a new
" line.
inoremap <expr> <CR> (pumvisible() ? "\<c-y>\<cr>" : "\<CR>")
" Use <TAB> to select the popup menu:
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"


" Plug 'rust-lang/rust.vim'
" Plug 'racer-rust/vim-racer'
" Plug 'ncm2/ncm2-racer'
"
let g:rustfmt_autosave = 1
let g:racer_experimental_completer = 1

au FileType rust nmap gt :RustTest<CR>
au FileType rust nmap gd <Plug>(rust-def)
au FileType rust nmap gds <Plug>(rust-def-split)
au FileType rust nmap gdv <Plug>(rust-def-vertical)
au FileType rust nmap <leader>gd <Plug>(rust-doc)

au FileType rust set expandtab
au FileType rust set shiftwidth=4
au FileType rust set softtabstop=4
au FileType rust set tabstop=4

" Plug 'ncm2/ncm2-jedi'
"
au FileType python set expandtab
au FileType python set shiftwidth=4
au FileType python set softtabstop=4
au FileType python set tabstop=4

" Plug 'pearofducks/ansible-vim'
"
let g:ansible_unindent_after_newline = 1
let g:ansible_name_highlight = 'd'
let g:ansible_extra_keywords_highlight = 0


" Plug 'fatih/vim-go'
" Plug 'ncm2/ncm2-go'
"
let g:go_disable_autoinstall = 0

let g:go_highlight_functions = 0
let g:go_highlight_methods = 0
let g:go_highlight_structs = 0
let g:go_highlight_operators = 0
let g:go_highlight_interfaces = 0
let g:go_highlight_build_constraints = 1

let g:go_auto_sameids = 0
let g:go_decls_included = "type,func"

let g:go_fmt_command = "goimports"
let g:go_fmt_fail_silently = 1

let g:go_def_mode = "guru"
let g:go_info_mode = "guru"
let g:go_list_type = "quickfix"

let g:go_snippet_case_type = "camelcase"
let g:go_addtags_transform = "camelcase"
let g:go_gocode_unimported_packages = 1

nnoremap <C-g> :GoAlternate<CR>
au FileType go nmap gb <Plug>(go-build)
au FileType go nmap gt <Plug>(go-test)
au FileType go nmap gc <Plug>(go-coverage-toggle)

au FileType go nmap gd <Plug>(go-def)
au FileType go nmap gds <Plug>(go-def-split)
au FileType go nmap gdv <Plug>(go-def-vertical)

au FileType go nmap gr <Plug>(go-rename)
au FileType go nmap gi <Plug>(go-implements)
au FileType go nmap gf <Plug>(go-imports)
au FileType go nmap gs <Plug>(go-info)
au FileType go nmap <leader>gd <Plug>(go-doc)

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

" Lang: yaml
" ---
au FileType yaml set expandtab
au FileType yaml set shiftwidth=2
au FileType yaml set softtabstop=2
au FileType yaml set tabstop=2

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
