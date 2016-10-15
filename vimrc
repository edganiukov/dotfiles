call plug#begin('~/.vim/plugged')

" Plugins
Plug 'joshdick/onedark.vim'
Plug 'itchyny/lightline.vim'
Plug 'jlanzarotta/bufexplorer'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/nerdtree'
Plug 'scrooloose/syntastic'
Plug 'kien/ctrlp.vim'
Plug 'junegunn/fzf.vim'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
Plug 'AndrewRadev/splitjoin.vim'
Plug 'SirVer/ultisnips'

Plug 'fatih/vim-go', { 'for': 'go' }
Plug 'klen/python-mode', { 'for': 'py' }
Plug 'davidhalter/jedi-vim', { 'for': 'py' }
Plug 'lervag/vimtex', { 'for': 'tex' }
Plug 'tpope/vim-markdown', { 'for': 'md' }

if has('nvim')
    Plug 'Shougo/deoplete.nvim'
    Plug 'zchee/deoplete-go', { 'do': 'make'}
else
    Plug 'Shougo/neocomplete.vim'
endif

call plug#end()

if exists('$ITERM_PROFILE')
    let &t_SI = "\<Esc>]50;CursorShape=1\x7"
    let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

" fixes for clipboard
set clipboard^=unnamed
set clipboard^=unnamedplus

syntax on
colorscheme onedark
highlight LineNr term=bold cterm=bold ctermfg=DarkGrey ctermbg=NONE

if !has('nvim')
    set nocompatible
    filetype off
    filetype plugin indent on

    set ttyfast
    set ttymouse=xterm2
    set ttyscroll=3

    set laststatus=2
    set encoding=utf-8
    set autoread
    set incsearch
    set hlsearch
    set backspace=indent,eol,start

    set mouse=a
else
    let $NVIM_TUI_ENABLE_CURSOR_SHAPE=1
endif

set noerrorbells
set novisualbell
set tm=500
set t_vb=

set expandtab
set wrap
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
set tabstop=4
set softtabstop=4
set shiftwidth=4

set completeopt=menu,menuone,noinsert,noselect

set scrolloff=4
set backspace=2
set gcr=a:blinkon0
set pumheight=15
set colorcolumn=81

if has("gui_running")
    set guifont=Consolas:h14
    set background=dark
    set go-=L
    set go-=r
    set go-=m
    set go-=T
    set vb t_vb=
endif

set cursorline
set pastetoggle=<F2>
set nopaste

" mappings
let mapleader = "\<Space>"

nnoremap <leader><space> :nohlsearch<CR>
nnoremap <leader>f :Explore<CR>:Ntree<CR>
nnoremap <leader>a :cclose<CR>
nnoremap <F10> :set list!<CR>
inoremap <F10> <Esc>:set list!<CR>a
nnoremap Y y$

" buffers switch
map <leader>n :bn!<CR>
map <leader>m :bp!<CR>

" quickfix jump
map <C-n> :cn<CR>
map <C-m> :cp<CR>

imap jj <Esc>

" window navigation
nmap <C-h> <C-w>h
nmap <C-j> <C-w>j
nmap <C-k> <C-w>k
nmap <C-l> <C-w>l

if has("nvim")
else
    noremap <C-d> :sh<CR>
endif

let g:bufferline_echo = 0

let g:netrw_altv = 1
let g:netrw_fastbrowse = 2
let g:netrw_keepdir = 0
let g:netrw_liststyle = 0
let g:netrw_retmap = 1
let g:netrw_silent = 1
let g:netrw_special_syntax = 1

highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

nnoremap <Leader>w :w<CR>

" disable arrows
inoremap <Up> <NOP>
inoremap <Down> <NOP>
inoremap <Left> <NOP>
inoremap <Right> <NOP>
noremap <Up> <NOP>
noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>

" Plugins config
" NERDTree
let NERDTreeDirArrows = 1
let NERDTreeMinimalUI = 1
let NERDTreeShowHidden = 1
let NERDTreeIgnore = ['\.DS_Store', '\.git$', '\.test$']
let g:NERDTreeWinSize = 40

map <F8> :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" syntastic
let g:syntastic_aggregate_errors = 1
let g:syntastic_enable_signs=1
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 0
let g:syntastic_go_checkers = ['golint', 'govet', "go"]

" completion
if has('nvim')
    let g:deoplete#enable_at_startup = 1
    let g:deoplete#ignore_sources = {}
    let g:deoplete#ignore_sources._ = ['buffer', 'member', 'tag', 'file', 'neosnippet']
    let g:deoplete#sources#go#sort_class = ['func', 'type', 'var', 'const']
    let g:deoplete#sources#go#align_class = 1

    " Use partial fuzzy matches like YouCompleteMe
    call deoplete#custom#set('_', 'matchers', ['matcher_fuzzy'])
    call deoplete#custom#set('_', 'converters', ['converter_remove_paren'])
    call deoplete#custom#set('_', 'disabled_syntaxes', ['Comment', 'String'])
else
    let g:neocomplete#enable_at_startup = 1
    let g:neocomplete#enable_smart_case = 1
    let g:neocomplete#sources#syntax#min_keyword_length = 3

    if !exists('g:neocomplete#sources')
        let g:neocomplete#sources = {}
    endif
    let g:neocomplete#sources._ = ['buffer', 'member', 'tag', 'file', 'dictionary']
    let g:neocomplete#sources.go = ['omni']

    " disable sorting
    call neocomplete#custom#source('_', 'sorters', [])
endif

inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<TAB>"

" ctrlp
let g:ctrlp_map = '<C-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 'ra'
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*.pyc,*.test
let g:ctrlp_custom_ignore = {
    \ 'dir':  '\v[\/]\.(git|hg|svn)$',
    \ }

let g:ctrlp_switch_buffer = 'et'

" fzf
set rtp+=/usr/local/opt/fzf

let g:fzf_action = {
    \ 'ctrl-t': 'tab split',
    \ 'ctrl-x': 'split',
    \ 'ctrl-v': 'vsplit' }

let g:fzf_layout = { 'down': '~30%' }

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

if has("nvim")
    noremap <C-l> :FZF<CR>
endif

" lightline
let g:lightline = {
    \ 'active': {
    \'left': [
        \ [ 'mode', 'paste'],
        \ [ 'fugitive', 'filename', 'modified' ],
        \ [ 'go']
        \ ],
    \ 'right': [
        \ [ 'lineinfo' ],
        \ [ 'percent' ],
        \ [ 'fileformat', 'fileencoding', 'filetype' ]
        \ ]
    \ },
    \ 'inactive': {
        \ 'left': [ [ 'go'] ],
        \ },
    \ 'component_function': {
        \ 'go': 'LightLineGo',
        \ 'fugitive': 'LightLineFugitive',
        \ },
    \ 'subseparator': { 'left': '>', 'right': '<' }
    \ }

function! LightLineFugitive()
    return exists('*fugitive#head') ? fugitive#head() : ''
endfunction

function! LightLineGo()
    return exists('*go#jobcontrol#Statusline') ? go#jobcontrol#Statusline() : ''
endfunction

" fugitive
vnoremap <leader>gb :Gblame<CR>
nnoremap <leader>gb :Gblame<CR>

" vim-go config
let g:go_disable_autoinstall = 0
let g:go_highlight_functions = 0
let g:go_highlight_methods = 0
let g:go_highlight_structs = 0
let g:go_highlight_operators = 0
let g:go_highlight_build_constraints = 1
let g:go_highlight_interfaces = 0

let g:go_auto_sameids = 1
let g:go_decls_included = "func,type"

let g:go_fmt_command = "goimports"
let g:go_fmt_fail_silently = 1
let g:go_def_mode = "guru"
let g:go_list_type = "quickfix"

let g:go_snippet_case_type = "camelcase"

au FileType go nmap <leader>r <Plug>(go-run)
au FileType go nmap <leader>b <Plug>(go-build)
au FileType go nmap <leader>t <Plug>(go-test)
au FileType go nmap <leader>e <Plug>(go-rename)
au FileType go nmap <leader>c <Plug>(go-coverage-toggle)

au FileType go nmap <leader>d <Plug>(go-def)
au FileType go nmap <Leader>ds <Plug>(go-def-split)
au FileType go nmap <Leader>dv <Plug>(go-def-vertical)
au FileType go nmap <Leader>dt <Plug>(go-def-tab)

au FileType go nmap <leader>s <Plug>(go-implements)
au FileType go nmap <leader>im <Plug>(go-imports)
au FileType go nmap <leader>gd <Plug>(go-doc)
au FileType go nmap <leader>i <Plug>(go-info)

nmap <C-g> :GoDeclsDir<cr>
imap <C-g> <esc>:<C-u>GoDeclsDir<cr>

" python
let g:pymode_rope = 0
let g:pymode_rope_completion = 0
let g:pymode_rope_complete_on_dot = 0

let g:pymode_lint = 0
let g:pymode_lint_checker = "pyflakes,pep8"
let g:pymode_lint_ignore="E501,W601,C0110"
let g:pymode_lint_write = 1

let g:pymode_virtualenv = 1

let g:pymode_breakpoint = 1
let g:pymode_breakpoint_key = '<leader>b'

let g:pymode_syntax = 1
let g:pymode_syntax_all = 1
let g:pymode_syntax_indent_errors = g:pymode_syntax_all
let g:pymode_syntax_space_errors = g:pymode_syntax_all

let g:jedi#completions_command = "<C-x><C-o>"
let g:jedi#goto_command = "<leader>d"
let g:jedi#goto_assignments_command = "<leader>g"
let g:jedi#goto_definitions_command = "<leader>f"
let g:jedi#documentation_command = "<leader>gd"
let g:jedi#usages_command = "<leader>n"
let g:jedi#rename_command = "<leader>r"
